#!/bin/bash
#SBATCH --job-name=buildvastpreload
#SBATCH --output=buildvastpreload.out
#SBATCH --error=buildvastpreload.err
#SBATCH --time=00:30:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

module purge
module load EasyBuild/5.3.0
eb --rebuild --optarch=-march=cascadelake vast-preload-lib-1.0.7-GCC-13.3.0.eb
