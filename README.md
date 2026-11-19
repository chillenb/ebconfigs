# ebconfigs

EasyBuild easyconfigs and build scripts for the pi_tz324 shared software stack on Bouchet.

- Install prefix: `/nfs/roberts/project/pi_tz324/shared/software`
  (modules in `ebmodulefiles/all`; set in `~/.config/easybuild/config.cfg`)
- Source cache: `~/.local/easybuild/sources`

## Layout

The directory is kept flat on purpose: the build scripts call `eb <file>.eb` with relative
paths and some pass `--robot-paths=<this dir>:`, so moving files into subdirectories would
break them.

- `*.eb`, `*.patch` — easyconfigs and patches
- `build<name>.sh` — one sbatch script per build; run with `sbatch build<name>.sh` from this
  directory. Slurm logs go to `build<name>.out/.err` (ignored by git).
- `jdftxgpu-test/` — JDFTx GPU tests, benchmarks and the CPU -> GPU migration note.

## donuts

Some easyconfigs here target `donuts` (AlmaLinux 10 mini-server, no Slurm) instead of Bouchet:

- Install prefix: `/opt/easybuild` (shared via the `easybuild` group; settings in `/etc/profile.d/z01_easybuild.sh`)
- Upstream easyconfigs: `/opt/easybuild/easyconfigs-chillenb` (clone of `chillenb/easybuild-easyconfigs`)
- `builddonuts-<name>.sh` scripts are plain bash, run with `bash builddonuts-<name>.sh`.
- `gimkl-16.2.0` (GCC 16.2.0 + impi 2021.17.2 + imkl 2025.3.1): impi has **no UCX** (donuts has no
  InfiniBand), so don't reuse it on Bouchet as-is.

## Rules

- Build on `devel` (at most 4 cores) or on a priority partition with `-A prio_tz324`; never on `day`.
- Do not rebuild an installed module in place (`eb --rebuild` / `-f` delete the install directory
  while jobs may be using it). Give the new build a different version or versionsuffix instead.
- Commit easyconfigs, patches and build scripts; never commit build logs.
