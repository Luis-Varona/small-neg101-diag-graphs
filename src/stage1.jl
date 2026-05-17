# Copyright 2026 Luis M. B. Varona
#
# Licensed under the MIT license <LICENSE or
# http://opensource.org/licenses/MIT>. This file may not be copied, modified, or
# distributed except according to those terms.

include("utils.jl")
using .Utils

using ArgParse

function main()
    category, dest, n, chunk_size, res, mod, k = parse_cli_args()

    geng = if category == "con"
        geng_connected(n; res=res, mod=mod)
    elseif category == "con_kreg"
        geng_connected_kreg(n, k; res=res, mod=mod)
    elseif category == "con_reg"
        geng_connected_regular(n; res=res, mod=mod)
    elseif category == "con_bip"
        geng_connected_bipartite(n; res=res, mod=mod)
    elseif category == "con_bip_kreg"
        genbg_connected_kreg(n, k; res=res, mod=mod)
    else
        genbg_connected_regular(n; res=res, mod=mod)
    end

    survivors = canonize_graph6_strings(
        filter_geng_to_laplacian_integral(geng, chunk_size, n)
    )

    open(dest, "w") do file
        for g6 in survivors
            println(file, g6)
        end

        return nothing
    end

    return nothing
end

function parse_cli_args()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--category"
        required = true
        arg_type = String
        "--dest"
        required = true
        arg_type = String
        "--order"
        required = true
        arg_type = Int
        "--chunk-size"
        arg_type = Int
        default = 2000
        "--res"
        arg_type = Int
        default = nothing
        "--mod"
        arg_type = Int
        default = nothing
        "--k"
        arg_type = Int
        default = nothing
    end

    args = parse_args(s)
    category = args["category"]
    dest = args["dest"]
    n = args["order"]
    chunk_size = args["chunk-size"]
    res = args["res"]
    mod = args["mod"]
    k = args["k"]

    valid_categories = (
        "con", "con_reg", "con_bip", "con_kreg", "con_bip_reg", "con_bip_kreg"
    )

    if !(category in valid_categories)
        throw(
            ArgumentError(
                "Category must be one of $(join(valid_categories, ", ")), got '$category'"
            ),
        )
    end

    if ispath(dest)
        throw(ArgumentError("Destination already exists: '$dest'"))
    end

    mkpath(dirname(dest))

    if n < 1
        throw(ArgumentError("Order must be at least 1, got $n"))
    end

    if chunk_size < 1
        throw(ArgumentError("Chunk size must be a positive integer, got $chunk_size"))
    end

    if isnothing(res) != isnothing(mod)
        throw(ArgumentError("--res and --mod must be specified together"))
    end

    if category in ("con_kreg", "con_bip_kreg")
        if isnothing(k)
            throw(ArgumentError("--k is required for category '$category'"))
        end
    elseif !isnothing(k)
        throw(ArgumentError("--k is forbidden for category '$category'"))
    end

    if category in ("con_bip_reg", "con_bip_kreg") && n % 2 != 0
        throw(ArgumentError("Order must be even for category '$category', got $n"))
    end

    if category == "con_bip_kreg" && k > div(n, 2)
        throw(
            ArgumentError(
                "k must be at most n/2 for con_bip_kreg, got k=$k, n/2=$(div(n, 2))"
            ),
        )
    end

    if category == "con_kreg" && k >= n
        throw(ArgumentError("k must be less than n for con_kreg, got k=$k, n=$n"))
    end

    return category, dest, n, chunk_size, res, mod, k
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
