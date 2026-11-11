#!/bin/bash
# usage: sbatch -p <gpu partition> [-A ...] run-test.sh
#SBATCH --job-name=jdftxmaster-test
#SBATCH --output=test-%x-%j.out
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --gpus=1
#SBATCH --mem=16G
module purge
module load JDFTx/1.7.0.20261108-GCC-13.3.0-CUDA-12.8.0
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
grep -q AuthenticAMD /proc/cpuinfo && export LD_PRELOAD=$HOME/.local/lib/libfakeintel.so   # MKL on AMD nodes
grep -m1 'model name' /proc/cpuinfo
nvidia-smi --query-gpu=name,compute_cap,driver_version --format=csv,noheader
cd "$SLURM_SUBMIT_DIR"
for f in internal libxc; do
  echo "=== jdftx_gpu $f ==="
  srun --mpi=pmix -n 1 -c $SLURM_CPUS_PER_TASK jdftx_gpu -c $SLURM_CPUS_PER_TASK -i water-$f.in -o out-gpu-$f-$SLURM_JOB_PARTITION-$SLURM_JOB_ID.out
  echo "exit $?"
  grep -E 'Running on GPU|Initialized LibXC|^ *F =|^ *G =|Etot|Done!' out-gpu-$f-$SLURM_JOB_PARTITION-$SLURM_JOB_ID.out | tail -6
done
