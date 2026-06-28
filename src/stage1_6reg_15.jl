# Copyright 2026 Luis M. B. Varona
#
# Licensed under the MIT license <LICENSE or
# http://opensource.org/licenses/MIT>. This file may not be copied, modified, or
# distributed except according to those terms.

include("utils.jl")
using .Utils

using ArgParse
using GraphIO.Graph6: _g6StringToGraph
using SDiagonalizability: is_s_diagonalizable

function main()
    dest, chunk_size, res, mod = parse_cli_args()

    cmd = if isnothing(res)
        `geng 15 -q -d6 -D6`
    else
        `geng 15 -q -d6 -D6 $res/$mod`
    end

    io = open(cmd)
    geng = (Iterators.Stateful(eachline(io)), io)

    li_survivors = filter_geng_to_laplacian_integral(geng, chunk_size, 15)

    if !isempty(li_survivors)
        li_survivors = canonize_graph6_strings(li_survivors)
    end

    open(dest, "w") do file
        for g6 in li_survivors
            g = _g6StringToGraph(g6)

            if is_s_diagonalizable(g, (-1, 0, 1)).has_s_diagonalization
                println(file, g6)
            end
        end

        return nothing
    end

    return nothing
end

function parse_cli_args()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--dest"
        required = true
        arg_type = String
        "--chunk-size"
        arg_type = Int
        default = 2000
        "--res"
        arg_type = Int
        default = nothing
        "--mod"
        arg_type = Int
        default = nothing
    end

    args = parse_args(s)
    dest = args["dest"]
    chunk_size = args["chunk-size"]
    res = args["res"]
    mod = args["mod"]

    if ispath(dest)
        throw(ArgumentError("Destination already exists: '$dest'"))
    end

    mkpath(dirname(dest))

    if chunk_size < 1
        throw(ArgumentError("Chunk size must be a positive integer, got $chunk_size"))
    end

    if isnothing(res) != isnothing(mod)
        throw(ArgumentError("--res and --mod must be specified together"))
    end

    return dest, chunk_size, res, mod
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
