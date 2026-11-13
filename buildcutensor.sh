#!/bin/bash
#SBATCH --job-name=buildcutensor
#SBATCH --output=buildcutensor.out
#SBATCH --error=buildcutensor.err
#SBATCH --time=01:00:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G

module purge
module load EasyBuild
eb cuTENSOR-2.8.1.0-CUDA-12.8.0.eb
