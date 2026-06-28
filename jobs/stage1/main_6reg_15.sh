#!/bin/bash

ARRAY_ID=$(sbatch --parsable --array=0-199 --job-name="s1_6reg_15" jobs/stage1/_job_6reg_15.sh 200)
sbatch --dependency=afterok:${ARRAY_ID} --job-name="merge_6reg_15" \
    --account=def-mbetti --output=logs/%x-%j.out --mem=1G --time=10:00 \
    --wrap='export PATH="$HOME/tools/nauty2_9_3:$PATH" && mkdir -p logs && cat data/6reg_15/splits/r*m200.g6 | labelg -q -g | sort -u > data/6reg_15/survivors.g6 && rm data/6reg_15/splits/r*m200.g6 && rmdir data/6reg_15/splits'
