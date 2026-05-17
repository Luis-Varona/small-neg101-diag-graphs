#!/bin/bash
#SBATCH --account=def-mbetti
#SBATCH --output=logs/%x-%j.out
#SBATCH --cpus-per-task=12
#SBATCH --mem=4G
#SBATCH --time=01:00:00

mkdir -p logs

module load julia/1.12.5
export PATH="$HOME/tools/nauty2_9_3:$PATH"
export JULIA_NUM_THREADS=8
export OPENBLAS_NUM_THREADS=1

CATEGORY="$1"

if [ "$CATEGORY" = "con" ]; then
    GLOB="data/stage1/con_[0-9]*.g6"
elif [ "$CATEGORY" = "con_reg" ]; then
    GLOB="data/stage1/con_reg_*.g6"
elif [ "$CATEGORY" = "con_bip" ]; then
    GLOB="data/stage1/con_bip_reg_*.g6"
else
    echo "Unknown category: $CATEGORY" >&2
    exit 1
fi

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT
cat $GLOB > "$TMPFILE"

julia --project=. src/stage2.jl --source "$TMPFILE" --dest "data/stage2/${CATEGORY}.arrow"
