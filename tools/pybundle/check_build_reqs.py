#!/usr/bin/env python3
"""Check that every extension of a bundle can actually be built without build isolation.

usage: check_build_reqs.py BUNDLE.eb PINS.txt 'SOURCES_GLOB'

EasyBuild installs extensions with `pip install --no-build-isolation`, so pip neither installs
nor checks the [build-system] requires of each package: a missing or too-old build backend or
plugin only shows up as a failure in the middle of the build. This reads pyproject.toml (and
hatch_build.py) from each downloaded sdist, without unpacking or running anything, and reports:

  * build requirements that no module/extension provides
  * build requirements whose available version does not satisfy the specifier
  * build requirements provided by the bundle itself but installed *after* the package
  * hatch build hooks that need a plugin, and hatch_build.py scripts importing an unavailable module

Download the sources first, e.g. `eb BUNDLE.eb --fetch`; SOURCES_GLOB is then something like
'/path/to/sources/p/Python-bundle-PyPI/extensions/*.tar.gz' (quote it).
Not every finding is fatal: optional setuptools plugins (e.g. coherent.licensed) and loose
upper caps often work in practice. Check the log of a previous build when in doubt.
"""
import ast
import collections
import glob
import re
import sys
import tarfile
import tomllib

from packaging.requirements import Requirement

BUILTIN_HATCH_HOOKS = {'custom', 'version', 'vcs'}  # vcs comes from hatch-vcs, checked as a requirement


def norm(n):
    return re.sub(r'[-_.]+', '-', n).lower()


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    bundle, pinfile, src_glob = sys.argv[1:4]
    have = {}
    for line in open(pinfile):
        if '==' in line:
            n, v = line.strip().split('==')
            have[norm(n)] = v
    have.setdefault('pip', '0'), have.setdefault('setuptools', '0'), have.setdefault('wheel', '0')
    order = [norm(m) for m in re.findall(r"^\s+\('([^']+)', '[^']+'", open(bundle).read(), re.M)]
    pos = {n: i for i, n in enumerate(order)}

    backends = collections.Counter()
    problems = collections.defaultdict(list)
    files = sorted(glob.glob(src_glob))
    if not files:
        sys.exit(f'no files match {src_glob}')
    for f in files:
        base = f.rsplit('/', 1)[1]
        pkg = norm(re.sub(r'-\d.*', '', base))
        with tarfile.open(f) as t:
            members = {m.name.split('/', 1)[1]: m for m in t.getmembers() if m.name.count('/') == 1}
            if 'pyproject.toml' not in members:
                backends['(setup.py only)'] += 1
                continue
            d = tomllib.load(t.extractfile(members['pyproject.toml']))
            hatch_build = t.extractfile(members['hatch_build.py']).read().decode() if 'hatch_build.py' in members else None
        bs = d.get('build-system', {})
        backends[bs.get('build-backend', '(default setuptools)')] += 1

        for r in bs.get('requires', []):
            req = Requirement(r)
            if req.marker and not req.marker.evaluate({'extra': ''}):
                continue
            n = norm(req.name)
            v = have.get(n)
            if v is None:
                problems[f'build requirement not available: {n}'].append(base)
                continue
            if v != '0' and not req.specifier.contains(v, prereleases=True):
                problems[f'needs {req}, have {v}'].append(base)
            if n in pos and pkg in pos and pos[n] > pos[pkg]:
                problems[f'{n} is installed later in the bundle'].append(base)

        hooks = d.get('tool', {}).get('hatch', {}).get('build', {}).get('hooks', {})
        for h in hooks:
            if h not in BUILTIN_HATCH_HOOKS:
                problems[f'hatch build hook "{h}" needs its plugin'].append(base)
        if hatch_build:
            for node in ast.walk(ast.parse(hatch_build)):
                mods = []
                if isinstance(node, ast.Import):
                    mods = [a.name for a in node.names]
                elif isinstance(node, ast.ImportFrom) and node.module:
                    mods = [node.module]
                for m in mods:
                    root = m.split('.')[0]
                    if root in sys.stdlib_module_names or root == 'hatchling':
                        continue
                    if norm(root) not in have:
                        problems[f'hatch_build.py imports {m}'].append(base)

    print('build backends:', ', '.join(f'{k}: {v}' for k, v in backends.most_common()))
    if not problems:
        print('no problems found')
    for msg, fs in sorted(problems.items()):
        print(f'{msg}\n    {", ".join(fs)}')


if __name__ == '__main__':
    main()
