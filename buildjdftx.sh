#!/bin/bash
#SBATCH --job-name=buildjdftx
#SBATCH --output=buildjdftx.out
#SBATCH --error=buildjdftx.err
#SBATCH --time=03:00:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake --robot JDFTx-1.7.0-intel-2024a.eb
