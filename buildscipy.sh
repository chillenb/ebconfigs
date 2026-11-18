#!/bin/bash
#SBATCH --job-name=buildscipy
#SBATCH --output=buildscipy.out
#SBATCH --error=buildscipy.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=12G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f --skip-test-step SciPy-1.17.1-gimkl-2024a.eb