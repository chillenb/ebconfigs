#!/bin/bash
# sbatch -p priority_gpu -A prio_tz324 -n NR -c NT --export=ALL,XC=internal|libxc,NR=NR,NT=NT[,MOD=...,TAG=...] bench.sh  (NR*NT = 6)
#SBATCH --job-name=jdftx-bench
#SBATCH --output=bench-%j.log
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --gpus=h200:1
#SBATCH --mem=256G
module purge
module load ${MOD:-JDFTx/1.7.0.20261108-GCC-13.3.0-CUDA-12.8.0}
NR=${NR:-1}; NT=${NT:-6}; XC=${XC:-internal}
export OMP_NUM_THREADS=$NT
cd "$SLURM_SUBMIT_DIR"
OUT=out-${SYS:+$SYS-}${XC}-r${NR}t${NT}${TAG:+-$TAG}-$SLURM_JOB_ID
nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
( while sleep 5; do nvidia-smi --query-gpu=utilization.gpu,memory.used --format=csv,noheader,nounits; done ) > $OUT.gpumon &
MON=$!
/usr/bin/time -v srun --mpi=pmix -n $NR -c $NT jdftx_gpu -c $NT -i in-${SYS:+$SYS-}$XC.jdftx -o $OUT 2> $OUT.time
echo "exit $?"; kill $MON
grep -E 'Run totals|Etot =|Duration' $OUT
grep -E 'Maximum resident' $OUT.time
awk -F, '{u+=$1; if($2>m)m=$2; n++} END {printf "GPU util avg %.0f%%, peak mem %d MiB\n", u/n, m}' $OUT.gpumon
