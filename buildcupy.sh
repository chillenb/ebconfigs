#!/bin/bash
#SBATCH --job-name=buildcupy
#SBATCH --output=buildcupy.out
#SBATCH --error=buildcupy.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f --skip-test-step CuPy-13.6.0-gimkl-2024a-CUDA-12.8.0.eb