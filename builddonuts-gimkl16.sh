#!/bin/bash
# donuts (AlmaLinux 10, i5-9500, no Slurm): run directly with `bash builddonuts-gimkl16.sh` from this directory,
# as a member of the `easybuild` group. Prefix/optarch/EULA settings come from /etc/profile.d/z01_easybuild.sh.
# impi here has no UCX dependency: donuts has no InfiniBand (shm + bundled libfabric only).
set -euo pipefail
cd "$(dirname "$0")"

module purge
module load EasyBuild/5.4.2
umask 002
eb --robot --robot-paths="$PWD:/opt/easybuild/easyconfigs-chillenb/easybuild/easyconfigs" \
   gimkl-16.2.0.eb 2>&1 | tee builddonuts-gimkl16.out
