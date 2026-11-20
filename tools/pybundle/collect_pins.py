#!/usr/bin/env python3
"""Collect name==version pins for every Python package a bundle and its dependency tree install.

usage: collect_pins.py BUNDLE.eb [DEP.eb ...] [--robot] [-o pins.txt]

Sources of pins:
  * the exts_list of BUNDLE.eb (these always win: they are what you are testing)
  * the exts_list of every DEP.eb that installs Python packages, plus the module itself if its easyblock is PythonPackage
    or CargoPythonPackage
With --robot, the dependency easyconfigs are taken from `eb --dry-run --robot BUNDLE.eb`
(EasyBuild must be loaded). When two dependency modules ship the same package, the highest
version is kept, as the newer copy is normally the one that wins on the module search path.

Output: one name==version per line (default pins.txt), for resolve_check.sh.
"""
import argparse
import ast
import os
import re
import subprocess

from packaging.version import Version


def norm(n):
    return re.sub(r'[-_.]+', '-', n).lower()


PY_EASYBLOCKS = {'PythonPackage', 'PythonBundle', 'CargoPythonPackage', 'CargoPythonBundle'}


def installs_python(top):
    """True if the easyconfig's extensions/module are Python packages (not Perl, R, ... extensions)."""
    return (top.get('easyblock') in PY_EASYBLOCKS or top.get('name') == 'Python'
            or top.get('exts_defaultclass') == 'PythonPackage')


def read_ec(path):
    tree = ast.parse(open(path).read())
    top = {n.targets[0].id: n.value.value for n in tree.body if isinstance(n, ast.Assign)
           and isinstance(n.targets[0], ast.Name) and isinstance(n.value, ast.Constant)}
    exts = []
    for n in tree.body:
        if isinstance(n, ast.Assign) and isinstance(n.targets[0], ast.Name) and n.targets[0].id == 'exts_list':
            for el in n.value.elts:
                if not isinstance(el, ast.Tuple) or len(el.elts) < 2:
                    continue
                k, v = el.elts[0], el.elts[1]
                if isinstance(k, ast.Name) and k.id == 'name':
                    k = ast.Constant(top.get('name'))
                if isinstance(v, ast.Name) and v.id == 'version':
                    v = ast.Constant(top.get('version'))
                if isinstance(k, ast.Constant) and isinstance(v, ast.Constant):
                    exts.append((k.value, v.value))
    return top, exts


def robot_easyconfigs(bundle):
    # EasyBuild wraps the listing to the terminal width (splitting long paths); make it wide enough
    env = dict(os.environ, COLUMNS='100000')
    out = subprocess.run(['eb', '--dry-run', '--robot', '--detect-loaded-modules=ignore', bundle], env=env,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, check=True).stdout
    return re.findall(r'^\s*\*\s+\[.\]\s+(\S+\.eb)\s+\(module', out, re.M)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('bundle')
    ap.add_argument('deps', nargs='*')
    ap.add_argument('--robot', action='store_true', help='find dependency easyconfigs with eb --dry-run --robot')
    ap.add_argument('-o', '--output', default='pins.txt')
    args = ap.parse_args()

    deps = list(args.deps)
    if args.robot:
        deps += [p for p in robot_easyconfigs(args.bundle) if not p.endswith('/' + args.bundle.rsplit('/', 1)[-1])]

    pins = {}  # norm name -> (name, version, source)
    _, bex = read_ec(args.bundle)
    for n, v in bex:
        pins[norm(n)] = (n, v, 'bundle')
    for path in deps:
        top, exts = read_ec(path)
        if not installs_python(top):
            continue
        items = list(exts)
        if top.get('easyblock') in ('PythonPackage', 'CargoPythonPackage'):
            items.append((top['name'], top['version']))
        for n, v in items:
            old = pins.get(norm(n))
            try:
                newer = old is not None and old[2] != 'bundle' and Version(v) > Version(old[1])
            except Exception:  # noqa: BLE001  (non-PEP 440 version)
                newer = False
            if old is None or newer:
                pins[norm(n)] = (n, v, top.get('name', path))

    with open(args.output, 'w') as f:
        for _, (n, v, _src) in sorted(pins.items()):
            f.write(f'{n}=={v}\n')
    print(f'{len(pins)} pins from {1 + len(deps)} easyconfigs written to {args.output}')


if __name__ == '__main__':
    main()
