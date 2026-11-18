#!/bin/bash
#SBATCH --job-name=buildscipydeps
#SBATCH --output=buildscipydeps.out
#SBATCH --error=buildscipydeps.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f SciPydepends-gimkl-2024a.eb