#!/bin/bash
#SBATCH --job-name=buildjdftxgpu
#SBATCH --output=buildjdftxgpu.out
#SBATCH --error=buildjdftxgpu.err
#SBATCH --time=04:00:00
#SBATCH --partition=priority
#SBATCH --account=prio_tz324
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake JDFTx-1.7.0-GCC-13.3.0-CUDA-12.8.0.eb
