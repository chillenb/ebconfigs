# Moving from CPU JDFTx to the GPU module on Bouchet

**Module:** `JDFTx/1.7.0.20261108-GCC-13.3.0-CUDA-12.8.0`. This is JDFTx master at commit `bea9f45` (2026-11-08), built with CUDA 12.8, CUDA-aware OpenMPI 5.0.3, Intel MKL, GSL, and a CUDA-enabled LibXC 7.1.2.
**Replaces:** `JDFTx/1.7.0-intel-2024a`, which is CPU-only and uses Intel MPI.
**Easyconfig:** `/nfs/roberts/project/pi_tz324/shared/software/ebconfigs/JDFTx-1.7.0.20261108-GCC-13.3.0-CUDA-12.8.0.eb`

## TL;DR

```bash
#!/bin/bash
#SBATCH --partition=priority_gpu
#SBATCH -A prio_tz324
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=6
#SBATCH --gpus=h200:1
#SBATCH --mem=64G
#SBATCH --time=02:00:00

module purge
module use /nfs/roberts/project/pi_tz324/shared/software/ebmodulefiles/all
module load JDFTx/1.7.0.20261108-GCC-13.3.0-CUDA-12.8.0
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

cd "$SLURM_SUBMIT_DIR"
srun --mpi=pmix -n 1 -c "$SLURM_CPUS_PER_TASK" \
    jdftx_gpu -c "$SLURM_CPUS_PER_TASK" -i in.jdftx -o out
```

Input files do not need to change. The same `in.jdftx` gives the same energy as the CPU build.

## What changes compared with the CPU run.sh

| | CPU (`1.7.0-intel-2024a`) | GPU (`1.7.0.20261108-…-CUDA-12.8.0`) |
|---|---|---|
| Executable | `jdftx` | `jdftx_gpu` (also `phonon_gpu`, `wannier_gpu`) |
| Partition | `priority` (CPU nodes) | `priority_gpu` with `--gpus=h200:1` (or h100/b200) |
| Ranks × threads | e.g. 12 × 3 | **1 × 6 per GPU** (see benchmarks) |
| MPI launch | `srun --mpi=pmi2` + `I_MPI_PMI_LIBRARY=…libpmi2.so` | `srun --mpi=pmix` (OpenMPI). Drop `I_MPI_PMI_LIBRARY`. |
| `LD_PRELOAD=libfakeintel.so` | needed for MKL speed on the AMD CPU nodes | not needed; the H200 nodes are Intel Xeon and the GPU does the heavy work |
| Host memory | large (e.g. 96G) | small: the data lives on the GPU. Slurm MaxRSS was 1.4 GB for top_CO_ads and 2.3 GB for hollow_complex, so 32–64G is plenty. |

## Rules and gotchas

1. **Use one MPI rank per GPU.** With one H200, one rank × 6 threads was about 2× faster per SCF cycle than 2, 3, or 6 ranks sharing the GPU. A single rank already keeps the GPU about 93% busy, and extra ranks only take turns on it (there is no MPS) while each adds its own GPU memory. For several GPUs, use `-n <nGPUs>` with `--gpus=h200:<nGPUs>`. This has not been benchmarked yet. JDFTx divides k-points across ranks, so choose a rank count that divides the number of reduced k-points.
2. **GPU memory limits which GPUs you can use.** hollow_complex (Cu slab + 2 CO, 130 bands, 36 k-points, 84×84×630 grid, 180 Ha cutoff) needs about **57 GB** of GPU memory. That fits on H100 (80 GB), H200 (141 GB), and B200, but **not** on L40S/A40/A5000/RTX 5000 Ada (24–48 GB). Small systems such as top_CO_ads need about 10 GB. Check peak usage with `nvidia-smi` if unsure.
3. **Every executable in this module needs a GPU, including the CPU `jdftx` and dry runs (`jdftx -n`).** The CUDA LibXC allocates GPU memory when JDFTx starts up, so on a node without a GPU even `jdftx -h` aborts with `no CUDA-capable device is detected`. For CPU-only work (or dry runs on CPU nodes), keep using `JDFTx/1.7.0-intel-2024a`, or `JDFTx/1.7.0-GCC-13.3.0-CUDA-12.8.0`, whose CPU `jdftx` works on CPU-only nodes.
4. **LibXC functionals run on the GPU** in this module. Built-in functionals (`gga-PBE`, etc.) and LibXC ones (`gga-x-pbe gga-c-pbe`) gave the same energies to about 1e-13 Ha and nearly the same speed. Prefer the built-in functional when one exists.
5. **GPU architectures compiled in:** sm_86 (A40/A5000), sm_89 (L40S/RTX 5000 Ada), sm_90 (H100/H200), sm_100 (B200), sm_120 (RTX Pro 6000), plus compute_86 PTX. **Only the H200 has actually been tested.**
6. Check that the run actually used the GPU. The output should contain `gpuInit: Found compatible cuda device 0 'NVIDIA H200'` and `Run totals: 1 processes, 6 threads, 1 GPUs`.
7. The header says `JDFTx 1.7.0` because master hasn't bumped the version number. The module name's `.20261108` marks it as the master snapshot.

## Benchmarks (one H200, 6 cores, built-in PBE, 2026-11-11)

Inputs are from `/nfs/roberts/pi/pi_tz324/cgh42/solvation_work/sautet-repro/jdftx/pbe/e180_k14_q19/`. CPU numbers are from the existing `out` files, which ran on 12 ranks × 3 threads (36 cores) with `JDFTx/1.7.0-intel-2024a`.

| System | CPU (36 cores) | GPU (1 × H200) | Speedup | Energy difference |
|---|---|---|---|---|
| top_CO_ads (20 e⁻, 16 bands) | 330.8 s | 30.6 s | 10.8× | 5e-10 Ha |
| hollow_complex (210 e⁻, 130 bands) | 53.4 min | 5 min 21 s | 10.0× | 2e-10 Ha |

hollow_complex rank scan (same total of 6 cores):

| ranks × threads | s / SCF cycle | setup + LCAO | peak GPU memory |
|---|---|---|---|
| **1 × 6** | **7.7** | 96 s | 57 GB |
| 2 × 3 | 14.9 | 117 s | 68 GB |
| 3 × 2 | 14.8 | 113 s | 88 GB |
| 6 × 1 | 15.3 | 117 s | 121 GB |

Benchmark script and logs: `ebconfigs/jdftxgpu-test/bench/` (`bench.sh` records wall time, GPU utilization, and peak GPU memory).

## Converting a batch of CPU runs

The CPU `run.sh` loops over directories on one node. For the GPU, run one directory per GPU job, or loop over directories sequentially in a single 1-GPU job (each directory runs in seconds to minutes):

```bash
for d in "$@"; do
    (cd "$d" && srun --mpi=pmix -n 1 -c "$SLURM_CPUS_PER_TASK" \
        jdftx_gpu -c "$SLURM_CPUS_PER_TASK" -i in.jdftx -o out)
    echo "$(date +%T) $d finished with status $?"
done
```

Don't send several runs to the same GPU at once. They will slow each other down, just like extra ranks did.
