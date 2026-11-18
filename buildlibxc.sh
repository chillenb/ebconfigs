#!/bin/bash
#SBATCH --job-name=buildlibxc
#SBATCH --output=buildlibxc.out
#SBATCH --error=buildlibxc.err
#SBATCH --time=04:00:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake --robot libxc-7.1.2-GCC-13.3.0.eb
