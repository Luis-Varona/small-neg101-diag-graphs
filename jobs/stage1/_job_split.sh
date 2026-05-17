#!/bin/bash
#SBATCH --account=def-mbetti
#SBATCH --output=logs/%x-%j-%a.out
#SBATCH --cpus-per-task=24
#SBATCH --mem=2G
#SBATCH --time=18:00:00

mkdir -p logs

module load julia/1.12.5
export PATH="$HOME/tools/nauty2_9_3:$PATH"
export JULIA_NUM_THREADS=16
export OPENBLAS_NUM_THREADS=1

julia --project=. src/stage1.jl --category "$1" --order "$2" --dest "data/stage1/splits/${1}_${2}_r${SLURM_ARRAY_TASK_ID}m${3}.g6" --chunk-size 2000 --res "$SLURM_ARRAY_TASK_ID" --mod "$3"
