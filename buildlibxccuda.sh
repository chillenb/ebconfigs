#!/bin/bash
#SBATCH --job-name=buildlibxccuda
#SBATCH --output=buildlibxccuda.out
#SBATCH --error=buildlibxccuda.err
#SBATCH --time=12:00:00
#SBATCH --partition=priority
#SBATCH --account=prio_tz324
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=96G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake libxc-7.1.2-GCC-13.3.0-CUDA-12.8.0.eb
