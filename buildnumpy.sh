#!/bin/bash
#SBATCH --job-name=buildnumpy
#SBATCH --output=buildnumpy.out
#SBATCH --error=buildnumpy.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=12G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f --skip-test-step NumPy-2.4.4-gimkl-2024a.eb