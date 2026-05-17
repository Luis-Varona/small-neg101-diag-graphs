# Copyright 2026 Luis M. B. Varona
#
# Licensed under the MIT license <LICENSE or
# http://opensource.org/licenses/MIT>. This file may not be copied, modified, or
# distributed except according to those terms.

module Utils

export geng_connected,
    geng_connected_kreg,
    geng_connected_regular,
    geng_connected_bipartite,
    genbg_connected_kreg,
    genbg_connected_regular,
    filter_geng_to_laplacian_integral,
    canonize_graph6_strings,
    graph6_to_full_result,
    write_arrow

using Base.Threads
using LinearAlgebra: eigvals!
using Graphs
using Graphs.Experimental: has_induced_subgraphisomorph
using GraphIO.Graph6: _g6StringToGraph, _graphToG6String
using SDiagonalizability: s_bandwidth
using Arrow

const P4 = path_graph(4)

function is_laplacian_integral!(L::Matrix{Float64})
    return all(eigval -> isapprox(eigval, round(eigval); atol=1e-8, rtol=1e-5), eigvals!(L))
end

function write_graph6_to_laplacian!(L::Matrix{Float64}, bits::BitVector, g6::String)
    n = Int(g6[1]) - 63
    max_size = div(n * (n - 1), 2)

    bits .= false
    idx_bit = 0

    for c in g6[2:end]
        val = Int(c) - 63
        bit_pos = 6

        while (idx_bit < max_size && bit_pos > 0)
            @inbounds bits[idx_bit += 1] = (val >> (bit_pos -= 1)) & 1 == 1
        end
    end

    L .= 0
    idx_edge = 0

    @inbounds for j in 2:n, i in 1:(j - 1)
        if bits[idx_edge += 1]
            L[i, i] += 1
            L[j, j] += 1
            L[i, j] -= 1
            L[j, i] -= 1
        end
    end

    return L
end

function geng_connected(
    n::Int; res::Union{Int,Nothing}=nothing, mod::Union{Int,Nothing}=nothing
)
    cmd = if isnothing(res)
        `geng $n -q -c`
    else
        `geng $n -q -c $res/$mod`
    end
    io = open(cmd)
    return Iterators.Stateful(eachline(io)), io
end

function geng_connected_kreg(
    n::Int, k::Int; res::Union{Int,Nothing}=nothing, mod::Union{Int,Nothing}=nothing
)
    cmd = if isnothing(res)
        `geng $n -q -c -d$k -D$k`
    else
        `geng $n -q -c -d$k -D$k $res/$mod`
    end
    io = open(cmd)
    return Iterators.Stateful(eachline(io)), io
end

function geng_connected_regular(
    n::Int; res::Union{Int,Nothing}=nothing, mod::Union{Int,Nothing}=nothing
)
    if n <= 2
        k_min = n - 1
    else
        k_min = 2
    end
    step = (n % 2) + 1
    k_vals = k_min:step:(n - 1)

    cmds = if isnothing(res)
        map(k -> `geng $n -q -c -d$k -D$k`, k_vals)
    else
        map(k -> `geng $n -q -c -d$k -D$k $res/$mod`, k_vals)
    end

    ios = open.(cmds)
    lines = Iterators.flatten(eachline.(ios))

    return Iterators.Stateful(lines), ios
end

function geng_connected_bipartite(
    n::Int; res::Union{Int,Nothing}=nothing, mod::Union{Int,Nothing}=nothing
)
    cmd = if isnothing(res)
        `geng $n -q -c -b`
    else
        `geng $n -q -c -b $res/$mod`
    end
    io = open(cmd)
    return Iterators.Stateful(eachline(io)), io
end

function genbg_connected_kreg(
    n::Int, k::Int; res::Union{Int,Nothing}=nothing, mod::Union{Int,Nothing}=nothing
)
    half = div(n, 2)
    cmd = if isnothing(res)
        `genbg -cq -d$k:$k -D$k:$k $half $half`
    else
        `genbg -cq -d$k:$k -D$k:$k $half $half $res/$mod`
    end
    io = open(cmd)
    return Iterators.Stateful(eachline(io)), io
end

function genbg_connected_regular(
    n::Int; res::Union{Int,Nothing}=nothing, mod::Union{Int,Nothing}=nothing
)
    half = div(n, 2)
    if half == 1
        k_min = 1
    else
        k_min = 2
    end
    k_vals = k_min:1:half

    cmds = if isnothing(res)
        map(k -> `genbg -cq -d$k:$k -D$k:$k $half $half`, k_vals)
    else
        map(k -> `genbg -cq -d$k:$k -D$k:$k $half $half $res/$mod`, k_vals)
    end

    ios = open.(cmds)
    lines = Iterators.flatten(eachline.(ios))

    return Iterators.Stateful(lines), ios
end

function filter_geng_to_laplacian_integral(
    geng::Tuple{Iterators.Stateful,Any}, chunk_size::Int, n::Int
)
    L_bufs = map(_ -> Matrix{Float64}(undef, n, n), 1:nthreads())
    bits_bufs = map(_ -> BitVector(undef, div(n * (n - 1), 2)), 1:nthreads())

    iter, io = geng
    results = String[]
    results_lock = ReentrantLock()
    res = iterate(iter)

    while !isnothing(res)
        chunk = String[]
        chunk_length = 0

        while (!isnothing(res) && chunk_length < chunk_size)
            g6, state = res
            push!(chunk, g6)
            res = iterate(iter, state)
            chunk_length += 1
        end

        num_threads = nthreads()
        chunk_results = map(_ -> String[], 1:num_threads)

        @threads for i in 1:num_threads
            L = L_bufs[i]
            bits = bits_bufs[i]
            thread_results = chunk_results[i]

            start = div((i - 1) * chunk_length, num_threads) + 1
            stop = div(i * chunk_length, num_threads)

            @inbounds for j in start:stop
                g6 = chunk[j]

                if is_laplacian_integral!(write_graph6_to_laplacian!(L, bits, g6))
                    push!(thread_results, g6)
                end
            end
        end

        lock(results_lock)

        try
            foreach(
                subchunk_results -> append!(results, subchunk_results),
                Iterators.filter(!isempty, chunk_results),
            )
        finally
            unlock(results_lock)
        end
    end

    if io isa AbstractVector
        close.(io)
    else
        close(io)
    end

    return results
end

function canonize_graph6_strings(g6_strings::Vector{String})
    return unique(
        readlines(pipeline(IOBuffer(join(g6_strings, "\n") * "\n"), `labelg -q -g`))
    )
end

function is_cograph(g::SimpleGraph)
    n = nv(g)

    if n < 4
        return true
    end

    if density(g) > 0.5
        h = complement(g)
    else
        h = g
    end
    ccs = connected_components(h)
    result = true
    i = 1

    while (result && i <= length(ccs))
        cc = ccs[i]

        if length(cc) >= 4
            sub, _ = induced_subgraph(h, cc)
            if density(sub) > 0.5
                check = complement(sub)
            else
                check = sub
            end

            if has_induced_subgraphisomorph(check, P4)
                result = false
            end
        end

        i += 1
    end

    return result
end

function is_regular(g::SimpleGraph)
    n = nv(g)

    if n == 0
        return true
    end

    d = degree(g, 1)

    return all(v -> degree(g, v) == d, 2:n)
end

function is_prime(n::Int)
    if n < 2
        return false
    end

    if n < 4
        return true
    end

    if n % 2 == 0
        return false
    end

    d = 3

    while d * d <= n
        if n % d == 0
            return false
        end

        d += 2
    end

    return true
end

edge_idx(d::Dict{Tuple{Int,Int},Int}, u::Int, v::Int) = d[minmax(u, v)]

function add_aux_edge!(aux::SimpleGraph, a::Int, b::Int)
    if a != b
        add_edge!(aux, a, b)
    end

    return nothing
end

function add_path!(aux::SimpleGraph, path::Vector{Int})
    for i in 1:(length(path) - 1)
        add_aux_edge!(aux, path[i], path[i + 1])
    end

    return nothing
end

function prime_graph_factors(g::SimpleGraph)
    n = nv(g)

    if n < 4 || is_prime(n)
        return [g]
    end

    if !is_connected(g)
        return nothing
    end

    m = ne(g)
    edge_list = collect(edges(g))
    etoi = Dict{Tuple{Int,Int},Int}()

    for (i, e) in enumerate(edge_list)
        etoi[(src(e), dst(e))] = i
    end

    dist = Matrix{Int}(undef, n, n)

    for u in 1:n
        dist[u, :] = gdistances(g, u)
    end

    aux = SimpleGraph(m)

    for u in 1:n
        u_nbrs = Set(neighbors(g, u))

        for v in 1:n
            if u == v || dist[u, v] > 2
                continue
            end

            isect = [x for x in neighbors(g, v) if x in u_nbrs]

            if isempty(isect)
                continue
            end

            if dist[u, v] == 1
                path = Int[]

                for x in isect
                    push!(path, edge_idx(etoi, u, x))
                    push!(path, edge_idx(etoi, v, x))
                end

                add_path!(aux, path)
            elseif length(isect) == 1
                x = isect[1]
                add_aux_edge!(aux, edge_idx(etoi, u, x), edge_idx(etoi, v, x))
            elseif length(isect) == 2
                x, y = isect
                add_aux_edge!(aux, edge_idx(etoi, u, x), edge_idx(etoi, v, y))
                add_aux_edge!(aux, edge_idx(etoi, v, x), edge_idx(etoi, u, y))
            else
                path = Int[]

                for x in isect
                    push!(path, edge_idx(etoi, u, x))
                end

                for x in isect
                    push!(path, edge_idx(etoi, v, x))
                end

                add_path!(aux, path)
            end
        end
    end

    for i in 1:m
        ei = edge_list[i]
        u1, v1 = src(ei), dst(ei)

        for j in (i + 1):m
            ej = edge_list[j]
            u2, v2 = src(ej), dst(ej)

            if dist[u1, u2] + dist[v1, v2] != dist[u1, v2] + dist[v1, u2]
                add_aux_edge!(aux, i, j)
            end
        end
    end

    components = connected_components(aux)
    factors = SimpleGraph[]

    for component in components
        comp_edges = [edge_list[i] for i in component]
        factor_full = SimpleGraph(n)

        for e in comp_edges
            add_edge!(factor_full, src(e), dst(e))
        end

        v = src(comp_edges[1])

        for cc in connected_components(factor_full)
            if v in cc
                factor, _ = induced_subgraph(factor_full, cc)
                push!(factors, factor)
                break
            end
        end
    end

    return factors
end

function safe_prime_factors_g6(g::SimpleGraph)
    factors = prime_graph_factors(g)

    if isnothing(factors)
        return missing
    end

    g6_strings = [replace(_graphToG6String(f), ">>graph6<<" => "") for f in factors]

    return canonize_graph6_strings(g6_strings)
end

function graph6_to_full_result(graph6::String)
    g = _g6StringToGraph(graph6)
    res = s_bandwidth(g, (-1, 0, 1))
    bandwidth = res.s_bandwidth

    if !isfinite(bandwidth)
        return nothing
    end

    eigvals_raw = res.s_diagonalization.values
    eigbasis_mat = res.s_diagonalization.vectors
    eigbasis = [Vector{Int}(eigbasis_mat[:, i]) for i in 1:size(eigbasis_mat, 2)]

    return (;
        num_vertices=nv(g),
        graph6=graph6,
        band_01neg=Int(bandwidth),
        eigvals=Vector{Int}(eigvals_raw),
        eigbasis_01neg=eigbasis,
        num_edges=ne(g),
        density=density(g),
        avg_degree=2 * ne(g) / nv(g),
        is_connected=is_connected(g),
        is_regular=is_regular(g),
        is_bipartite=is_bipartite(g),
        is_cograph=is_cograph(g),
        prime_factors=safe_prime_factors_g6(g),
        compl_prime_factors=safe_prime_factors_g6(complement(g)),
    )
end

function write_arrow(results::Vector, dest::String)
    if isempty(results)
        schema = (;
            num_vertices=Int[],
            graph6=String[],
            band_01neg=Int[],
            eigvals=Vector{Int}[],
            eigbasis_01neg=Vector{Vector{Int}}[],
            num_edges=Int[],
            density=Float64[],
            avg_degree=Float64[],
            is_connected=Bool[],
            is_regular=Bool[],
            is_bipartite=Bool[],
            is_cograph=Bool[],
            prime_factors=Union{Missing,Vector{String}}[],
            compl_prime_factors=Union{Missing,Vector{String}}[],
        )
        Arrow.write(dest, schema)
    else
        table = (; (k => [r[k] for r in results] for k in keys(results[1]))...)
        Arrow.write(dest, table)
    end

    return nothing
end

end
