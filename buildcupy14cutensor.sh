#!/bin/bash
#SBATCH --job-name=buildcupy14ct
#SBATCH --output=buildcupy14cutensor.out
#SBATCH --error=buildcupy14cutensor.err
#SBATCH --time=02:00:00
#SBATCH --partition=devel
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G

module purge
module load EasyBuild
eb --optarch=-march=cascadelake --skip-test-step CuPy-14.2.0-gimkl-2024a-CUDA-12.8.0-cuTENSOR-2.8.1.eb
