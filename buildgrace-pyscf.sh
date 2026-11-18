#!/bin/bash
# Grace: libxc 7.1.2 + localpyscf (chillenb/pyscf devstc worktree at ~/src/pyscf-devstc).
# Submit from this directory: sbatch buildgrace-pyscf.sh
#SBATCH --job-name=buildgrace-pyscf
#SBATCH --output=buildgrace-pyscf.out
#SBATCH --error=buildgrace-pyscf.err
#SBATCH --time=04:00:00
#SBATCH --partition=pi_zhu
#SBATCH --nodes=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
set -e
module purge
module load EasyBuild/5.4.0
eb --optarch=-march=cascadelake --robot --robot-paths=$PWD: libxc-7.1.2-GCC-13.3.0.eb

module purge
module load PyscfDeps/1.0-gimkl-2024a libxc/7.1.2-GCC-13.3.0 CMake/3.29.3-GCCcore-13.3.0 Ninja/1.13.0-GCCcore-13.3.0
cd ${PYSCF_SRC:-$HOME/src/pyscf-devstc}/pyscf/lib
# Same options as Bouchet (build_bouchet.sh), but a fixed cascadelake target instead of -march=native.
cmake -B build -S . -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_FLAGS="-march=cascadelake" -DCMAKE_CXX_FLAGS="-march=cascadelake" \
  -DENABLE_VECTOR_MATH=ON -DFORCE_INTEL_OPENMP=ON \
  -DENABLE_LIBXC=ON -DBUILD_LIBXC=OFF -DENABLE_XCFUN=OFF -DBUILD_XCFUN=OFF \
  -DUSE_QCINT=ON -DENABLE_MKL=ON -DENABLE_FFTW=OFF -DBLA_VENDOR=Intel10_64_dyn -DENABLE_IPO=OFF
cmake --build build -j $SLURM_CPUS_PER_TASK
