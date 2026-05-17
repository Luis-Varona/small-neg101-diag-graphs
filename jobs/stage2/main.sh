#!/bin/bash

sbatch --job-name="s2_con" jobs/stage2/_job.sh con
sbatch --job-name="s2_con_reg" jobs/stage2/_job.sh con_reg
sbatch --job-name="s2_con_bip" jobs/stage2/_job.sh con_bip
