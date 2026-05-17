#!/bin/bash

for n in $(seq 1 11); do
    sbatch --job-name="s1_con_${n}" jobs/stage1/_job_single.sh con "$n"
done

ARRAY_ID=$(sbatch --parsable --array=0-99 --job-name="s1_con_12" jobs/stage1/_job_split.sh con 12 100)
sbatch --dependency=afterok:${ARRAY_ID} --job-name="merge_con_12" jobs/stage1/_job_merge.sh con 12 100

for n in $(seq 1 14); do
    sbatch --job-name="s1_con_reg_${n}" jobs/stage1/_job_single.sh con_reg "$n"
done

for n in $(seq 2 2 16); do
    sbatch --job-name="s1_con_bip_reg_${n}" jobs/stage1/_job_single.sh con_bip_reg "$n"
done
