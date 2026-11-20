# pybundle: updating a Python-bundle-PyPI (or any PythonBundle) to current PyPI releases

Helper scripts used to make `Python-bundle-PyPI-2026.11-GCCcore-16.2.0.eb` (in the `chillenb` branch
of `chillenb/easybuild-easyconfigs`) from the 2026.04 one. They find version conflicts and build
problems *before* a multi-hour EasyBuild run instead of in the middle of it.

| Script | What it does |
|---|---|
| `update_exts.py IN.eb OUT.eb [--pin-file F]` | Sets every extension to its latest PyPI release (or a pinned one), with new SHA256s. Adds a `'sources'` entry only where EasyBuild's default filename would not match; keeps `SOURCELOWER_TAR_GZ` and similar constants when they still fit. |
| `add_ext.py FILE.eb NEW BEFORE` | Inserts a placeholder extension `NEW` before `BEFORE`; rerun `update_exts.py` to fill it in. |
| `collect_pins.py BUNDLE.eb --robot` | Writes `pins.txt`: every Python package the bundle and its whole dependency tree install (needs `eb` and `packaging`). |
| `resolve_check.sh pins.txt PYTHON_MODULE` | Runs pip's resolver on the pins (dry run, nothing installed). Prints the first conflict, or the unpinned packages pip had to pull in and who requires them. |
| `check_build_reqs.py BUNDLE.eb pins.txt 'SOURCES_GLOB'` | Reads each sdist's `pyproject.toml`/`hatch_build.py` without unpacking: missing or too-old build backends, wrong install order, hatch build-hook plugins. |
| `held-2026.11-GCCcore-16.2.0.txt` | Versions held back in 2026.11 and why; start the next update with `--pin-file` on it and re-check each cap. |

Run the Python scripts with an interpreter that has `packaging` (e.g. with the bundle module loaded;
`resolve_check.sh` makes its own venv). Python 3.11+ is needed for `tomllib`.

## Workflow

```bash
cd /opt/easybuild/easyconfigs-chillenb/easybuild/easyconfigs/p/Python-bundle-PyPI
T=/path/to/ebconfigs/tools/pybundle
NEW=Python-bundle-PyPI-YYYY.MM-GCCcore-X.Y.Z.eb

# 1. start from the previous bundle; edit version/toolchain/dependency versions in the header
cp Python-bundle-PyPI-<previous>.eb $NEW
python $T/update_exts.py $NEW $NEW --pin-file $T/held-<previous>.txt

# 2. loop until the resolver is happy
python $T/collect_pins.py $NEW --robot -o /tmp/pins.txt
$T/resolve_check.sh /tmp/pins.txt Python/<version>
#    conflict with a *dependency module* (e.g. poetry caps cachecontrol<0.15):
#        check whether the module's latest release lifts the cap; else pin the bundle package
#    new required package pulled in:  python $T/add_ext.py $NEW <pkg> <first-user>; rerun update_exts.py
#    package newer than the one in the Python module needed (typing_extensions, packaging):
#        add it to the bundle (or to the dependency module that needs it, if that module is also used on its own)

# 3. download sources, then check that everything can be built without build isolation
eb $NEW --fetch
python $T/check_build_reqs.py $NEW /tmp/pins.txt "$EASYBUILD_PREFIX/sources/p/Python-bundle-PyPI/extensions/*.tar.gz"

# 4. build
eb $NEW --robot
```

## Lessons from 2026.11

- **pip does not check build requirements** with `--no-build-isolation`, so a too-old build tool only
  fails at build time (pytest 9.2 needed `setuptools-scm>=10.1`; the Python module had 9.2.2).
  Step 3 catches this. Fix by adding the newer tool at the *start* of `exts_list`.
- **Don't blindly upgrade build backends**: `flit_core` 4 would have broken eleven packages that cap
  `flit_core<4`; more-itertools asks for `>=4` but builds fine with 3.12.
- **python-sbom hatch hooks** (filelock, platformdirs, python-discovery, virtualenv): either delete
  them from `pyproject.toml` (`'preinstallopts': "sed -i '/python-sbom/d' pyproject.toml && "`) or,
  where `hatch_build.py` imports `python_sbom`, force its no-op fallback branch
  (`sed -i 's/^if sys.version_info >= (3, 11):/if False:/' hatch_build.py`).
- Findings that turned out harmless: `coherent.licensed` (optional setuptools plugin of the jaraco
  family), `uv-dynamic-versioning` (intervaltree, unchanged since 2026.04), and extras-only packages
  in the resolver output (httpx, zstandard via poetry's `pbs-installer[download,install]`).
- `.gitignore` in easybuild-easyconfigs ignores `build/`: commit `b/build/build-*.eb` with `git add -f`.
