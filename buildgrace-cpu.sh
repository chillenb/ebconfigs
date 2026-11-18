#!/bin/bash
# Grace: CPU modules to match Bouchet. Submit from this directory: sbatch buildgrace-cpu.sh
# -march=cascadelake as on Bouchet (Grace Skylake nodes are private and not used).
#SBATCH --job-name=buildgrace-cpu
#SBATCH --output=buildgrace-cpu.out
#SBATCH --error=buildgrace-cpu.err
#SBATCH --time=12:00:00
#SBATCH --partition=pi_zhu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
set -e
module purge
module load EasyBuild/5.4.0
OPT="--optarch=-march=cascadelake --robot --robot-paths=$PWD:"
eb $OPT Cython-3.2.9-GCCcore-13.3.0.eb
eb $OPT --accept-eula-for=Intel-oneAPI intel-2026.2.0.eb
eb $OPT HDF5-2.2.0-iimpi-2026.2.0.eb
eb $OPT JDFTx-1.7.0-intel-2024a.eb
