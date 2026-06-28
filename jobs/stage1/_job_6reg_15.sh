#!/bin/bash
#SBATCH --account=def-mbetti
#SBATCH --output=logs/%x-%j-%a.out
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=01:30:00

mkdir -p logs

module load julia/1.12.5
export PATH="$HOME/tools/nauty2_9_3:$PATH"
export OPENBLAS_NUM_THREADS=1

julia --project=. src/stage1_6reg_15.jl --dest "data/6reg_15/splits/r${SLURM_ARRAY_TASK_ID}m${1}.g6" --res "$SLURM_ARRAY_TASK_ID" --mod "$1"
