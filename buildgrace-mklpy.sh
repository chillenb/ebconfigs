#!/bin/bash
# Grace: MKLpy 2026.11 (mkl-fft 2.4.0). Submit from this directory: sbatch buildgrace-mklpy.sh
#SBATCH --job-name=buildgrace-mklpy
#SBATCH --output=buildgrace-mklpy.out
#SBATCH --error=buildgrace-mklpy.err
#SBATCH --time=2:00:00
#SBATCH --partition=pi_zhu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
set -e
module purge
module load EasyBuild/5.4.0
eb --optarch=-march=cascadelake --robot --robot-paths=$PWD: MKLpy-2026.11-iimkl-2024a.eb
