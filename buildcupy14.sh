#!/bin/bash
#SBATCH --job-name=buildcupy14
#SBATCH --output=buildcupy14.out
#SBATCH --error=buildcupy14.err
#SBATCH --time=02:00:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake Cython-3.2.9-GCCcore-13.3.0.eb && \
eb --optarch=-march=cascadelake --skip-test-step CuPy-14.2.0-gimkl-2024a-CUDA-12.8.0.eb
