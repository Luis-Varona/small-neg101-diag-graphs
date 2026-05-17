# Copyright 2026 Luis M. B. Varona
#
# Licensed under the MIT license <LICENSE or
# http://opensource.org/licenses/MIT>. This file may not be copied, modified, or
# distributed except according to those terms.

include("utils.jl")
using .Utils

using ArgParse
using Base.Threads

function main()
    source, dest = parse_cli_args()
    graph6_iter = eachline(source)

    num_threads = nthreads()
    work_queue = Channel{Tuple{Int,String}}(num_threads)

    @spawn begin
        foreach(elem -> put!(work_queue, elem), enumerate(graph6_iter))
        close(work_queue)
    end

    results_disagg = map(_ -> Tuple{Int,Any}[], 1:num_threads)

    @sync for i in 1:num_threads
        @spawn begin
            thread_results = results_disagg[i]

            for (j, graph6) in work_queue
                res = graph6_to_full_result(graph6)

                if !isnothing(res)
                    push!(thread_results, (j, res))
                end
            end
        end
    end

    results = sort!(vcat(results_disagg...))

    write_arrow(map(r -> r[2], results), dest)

    return nothing
end

function parse_cli_args()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "--source"
        required = true
        arg_type = String
        "--dest"
        required = true
        arg_type = String
    end

    args = parse_args(s)
    source = args["source"]
    dest = args["dest"]

    if !isfile(source)
        throw(ArgumentError("Source file does not exist: '$source'"))
    end

    if ispath(dest)
        throw(ArgumentError("Destination already exists: '$dest'"))
    end

    if !endswith(dest, ".arrow")
        throw(ArgumentError("Destination file must have an '.arrow' extension: '$dest'"))
    end

    mkpath(dirname(dest))

    return source, dest
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
