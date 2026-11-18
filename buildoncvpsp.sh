#!/bin/bash
#SBATCH --job-name=buildoncvpsp
#SBATCH --output=buildoncvpsp.out
#SBATCH --error=buildoncvpsp.err
#SBATCH --time=01:00:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

module purge
module load EasyBuild
eb --rebuild --optarch=-march=cascadelake ONCVPSP-4.0.1.20260514-gfbf-2024a.eb
