#!/bin/bash
#SBATCH --job-name=buildcuda135
#SBATCH --output=buildcuda135.out
#SBATCH --error=buildcuda135.err
#SBATCH --time=04:00:00
#SBATCH --partition=priority
#SBATCH --account=prio_tz324
#SBATCH --nodes=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=48G
set -e
module purge
module load EasyBuild
export TMPDIR=/tmp/$USER-$SLURM_JOB_ID; mkdir -p $TMPDIR
OPT="--optarch=-march=cascadelake"

# CUDA 13.5.0: NVIDIA publishes only md5 for the runfile; verify it, then record sha256 in the easyconfig
if grep -q 'checksums = \[None\]' CUDA-13.5.0.eb; then
  eb --fetch --accept-eula-for=CUDA CUDA-13.5.0.eb
  RUN=$(find ~/.local/easybuild/sources -name cuda_13.5.0_linux.run | head -1)
  echo "6c1f56882ef5804043b15ff09e75d630  $RUN" | md5sum -c -
  SHA=$(sha256sum "$RUN" | cut -d' ' -f1)
  sed -i "s/checksums = \[None\]/checksums = ['$SHA']/" CUDA-13.5.0.eb
fi
eb $OPT --accept-eula-for=CUDA CUDA-13.5.0.eb
eb $OPT cuTENSOR-2.8.1.0-CUDA-13.5.0.eb
eb $OPT cuSPARSELt-0.10.0.12-CUDA-13.5.0.eb
eb $OPT NCCL-2.32.6-GCCcore-13.3.0-CUDA-13.5.0.eb
eb $OPT --skip-test-step CuPy-14.2.0-gimkl-2024a-CUDA-13.5.0.eb
rm -rf $TMPDIR
