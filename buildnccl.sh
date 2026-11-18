#!/bin/bash
#SBATCH --job-name=buildnccl
#SBATCH --output=buildnccl.out
#SBATCH --error=buildnccl.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f NCCL-2.26.2-GCCcore-13.3.0-CUDA-12.8.0.eb
