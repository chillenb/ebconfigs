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

## Rules

- Build on `devel` (at most 4 cores) or on a priority partition with `-A prio_tz324`; never on `day`.
- Do not rebuild an installed module in place (`eb --rebuild` / `-f` delete the install directory
  while jobs may be using it). Give the new build a different version or versionsuffix instead.
- Commit easyconfigs, patches and build scripts; never commit build logs.
