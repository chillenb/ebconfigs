#!/bin/bash
#SBATCH --job-name=buildhdf5
#SBATCH --output=buildhdf5.out
#SBATCH --error=buildhdf5.err
#SBATCH --time=03:00:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G

module purge
module load EasyBuild/5.4.0
eb --optarch=-march=cascadelake --robot --robot-paths=/nfs/roberts/project/pi_tz324/shared/software/ebconfigs: HDF5-2.2.0-iimpi-2026.2.0.eb
