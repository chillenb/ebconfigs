#!/bin/bash
# Grace: SLATE + CoQui (intel/2026.2.0). Submit from this directory: sbatch buildgrace-coqui.sh
# Pre-fetch sources first (needs internet; run under timeout on a login node):
#   timeout 1200 eb --fetch --robot-paths=$PWD: SLATE-2025.05.28-intel-2026.2.0.eb CoQui-0.4.0-intel-2026.2.0.eb
#SBATCH --job-name=buildgrace-coqui
#SBATCH --output=buildgrace-coqui.out
#SBATCH --error=buildgrace-coqui.err
#SBATCH --time=12:00:00
#SBATCH --partition=pi_zhu
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=96G
set -e
module purge
module load EasyBuild/5.4.0
# ctest runs mpiexec -n 4 inside this 1-task allocation: start ranks locally, not via srun
export I_MPI_HYDRA_BOOTSTRAP=fork
OPT="--optarch=-march=cascadelake --robot --robot-paths=$PWD:"
eb $OPT SLATE-2025.05.28-intel-2026.2.0.eb
# build dir + logs on scratch so failures can be inspected
D=/vast/palmer/scratch/zhu/cgh42/coqui-build
eb $OPT --buildpath=$D/ebbuild --tmpdir=$D/ebtmp CoQui-0.4.0-intel-2026.2.0.eb
