#!/bin/bash
#SBATCH --account=def-mbetti
#SBATCH --output=logs/%x-%j.out
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=10:00

mkdir -p logs

cat data/stage1/splits/${1}_${2}_r*m${3}.g6 > data/stage1/${1}_${2}.g6
rm data/stage1/splits/${1}_${2}_r*m${3}.g6
rmdir data/stage1/splits
