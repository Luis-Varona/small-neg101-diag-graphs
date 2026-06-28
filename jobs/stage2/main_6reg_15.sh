#!/bin/bash

sbatch --job-name="s2_6reg_15" \
    --account=def-mbetti --output=logs/%x-%j.out --mem=1G --time=10:00 \
    --wrap='module load julia/1.12.5 && export PATH="$HOME/tools/nauty2_9_3:$PATH" && export OPENBLAS_NUM_THREADS=1 && mkdir -p logs && julia --project=. src/stage2_6reg_15.jl --source data/6reg_15/survivors.g6 --dest data/6reg_15/results.arrow'
