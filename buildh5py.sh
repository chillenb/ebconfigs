#!/bin/bash
#SBATCH --job-name=buildh5py.sh
#SBATCH --output=buildh5py.out
#SBATCH --error=buildh5py.err
#SBATCH --time=01:00:00
#SBATCH --partition=day_amd
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=5G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake -f h5py-3.14.0-gimkl-2024a.eb