#!/bin/bash
#SBATCH --job-name=buildpybind11
#SBATCH --output=buildpybind11.out
#SBATCH --error=buildpybind11.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=20G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f pybind11-3.0.0-GCC-13.3.0.eb