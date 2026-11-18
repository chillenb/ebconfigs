#!/bin/bash
#SBATCH --job-name=buildmpi4py
#SBATCH --output=buildmpi4py.out
#SBATCH --error=buildmpi4py.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f mpi4py-4.1.1-gimkl-2024a.eb