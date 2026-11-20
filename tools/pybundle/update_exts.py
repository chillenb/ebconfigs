#!/usr/bin/env python3
"""Update the exts_list of a PythonBundle/PythonPackage easyconfig to the latest PyPI releases.

usage: update_exts.py IN.eb OUT.eb [--pin name==ver,...] [--pin-file FILE] [--skip name,...]

For every extension: look up the latest release on PyPI (or the --pin'ed version), pick the same
kind of file the entry currently uses (sdist .tar.gz, or a py3-none-any wheel if the entry's
'sources' mentions a wheel), and rewrite the version and the SHA256 checksum.

'sources' handling: EasyBuild's default for extensions is '%(name)s-%(version)s.tar.gz' and it
retries with '-' replaced by '_'. An explicit 'sources' entry is only written when that default
would not match the file on PyPI; existing constants (SOURCELOWER_TAR_GZ, SOURCE_PY3_WHL, ...)
are kept as long as they still expand to the right filename.

Entries written as (name, version, {...}) update the top-level 'version = ...' line.
Other per-extension options and comments are left untouched. IN and OUT may be the same file.
Prints a table of old -> new versions.
"""
import argparse
import ast
import concurrent.futures as cf
import json
import re
import urllib.request

CONSTANTS = {
    'SOURCE_TAR_GZ': '{name}-{v}.tar.gz',
    'SOURCELOWER_TAR_GZ': '{lower}-{v}.tar.gz',
    'SOURCE_PY3_WHL': '{name}-{v}-py3-none-any.whl',
    'SOURCELOWER_PY3_WHL': '{lower}-{v}-py3-none-any.whl',
    'SOURCE_PY2_PY3_WHL': '{name}-{v}-py2.py3-none-any.whl',
    'SOURCE_PY2_PY3_WHL_LOWER': '{lower}-{v}-py2.py3-none-any.whl',
}


def pypi(name, version=None):
    url = f"https://pypi.org/pypi/{name}/json" if version is None else f"https://pypi.org/pypi/{name}/{version}/json"
    with urllib.request.urlopen(url, timeout=30) as r:
        return json.load(r)


def pick_file(meta, want_wheel):
    files = [u for u in meta['urls'] if not u.get('yanked')]
    if want_wheel:
        whl = [u for u in files if u['packagetype'] == 'bdist_wheel' and u['filename'].endswith('-none-any.whl')]
        return whl[0] if whl else None
    sd = [u for u in files if u['packagetype'] == 'sdist' and u['filename'].endswith('.tar.gz')]
    return sd[0] if sd else None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('infile')
    ap.add_argument('outfile')
    ap.add_argument('--pin', default='', help='comma-separated name==version to use instead of latest')
    ap.add_argument('--pin-file', help='file with one name==version per line (# comments allowed)')
    ap.add_argument('--skip', default='', help='comma-separated extension names to leave unchanged')
    args = ap.parse_args()

    pins = dict(p.split('==') for p in args.pin.split(',') if p)
    if args.pin_file:
        for line in open(args.pin_file):
            line = line.split('#')[0].strip()
            if line:
                n, v = line.split('==')
                pins[n.strip()] = v.strip()
    skip = set(s for s in args.skip.split(',') if s)

    text = open(args.infile).read()
    lines = text.split('\n')
    tree = ast.parse(text)
    top = {n.targets[0].id: n.value.value for n in tree.body if isinstance(n, ast.Assign)
           and isinstance(n.targets[0], ast.Name) and isinstance(n.value, ast.Constant)}
    exts = next(n.value for n in tree.body if isinstance(n, ast.Assign)
                and isinstance(n.targets[0], ast.Name) and n.targets[0].id == 'exts_list')

    entries = []
    for el in exts.elts:
        if not isinstance(el, ast.Tuple):
            continue
        k, v = el.elts[0], el.elts[1]
        name = top['name'] if isinstance(k, ast.Name) and k.id == 'name' else k.value
        ver = top['version'] if isinstance(v, ast.Name) and v.id == 'version' else v.value
        opts = el.elts[2] if len(el.elts) > 2 else None
        keys = {kk.value: vv for kk, vv in zip(opts.keys, opts.values)} if opts is not None else {}
        srcseg = ast.get_source_segment(text, keys['sources']) if 'sources' in keys else ''
        entries.append(dict(name=name, ver=ver, el=el, keys=keys, srcseg=srcseg,
                            want_wheel='WHL' in srcseg or '.whl' in srcseg, ver_is_var=isinstance(v, ast.Name)))

    def fetch(e):
        try:
            if e['name'] in skip:
                return e, None, 'skipped'
            meta = pypi(e['name'], pins.get(e['name']))
            if e['name'] not in pins:  # the project JSON only lists files of the latest release
                meta = pypi(e['name'], meta['info']['version'])
            f = pick_file(meta, e['want_wheel'])
            if f is None:
                kind = 'wheel' if e['want_wheel'] else 'sdist'
                return e, None, f"no matching {kind} for {meta['info']['version']}"
            return e, (meta['info']['version'], f, meta['info'].get('requires_python')), None
        except Exception as ex:  # noqa: BLE001
            return e, None, f'error: {ex}'

    with cf.ThreadPoolExecutor(16) as ex:
        results = list(ex.map(fetch, entries))

    edits = []  # (first_line, last_line, replacement_lines); insertion when first == last + 1
    report = []
    for e, res, err in results:
        el, name, keys = e['el'], e['name'], e['keys']
        if res is None:
            report.append((name, e['ver'], e['ver'], err))
            continue
        new_ver, f, reqpy = res
        fn, sha = f['filename'], f['digests']['sha256']
        ind = ' ' * (el.col_offset + 4)

        fn_tmpl = fn.replace(new_ver, '%(version)s', 1)
        defaults = {f'{name}-{new_ver}.tar.gz', f"{name.replace('-', '_')}-{new_ver}.tar.gz"}
        keep_existing = False
        if e['srcseg']:
            m = re.fullmatch(r'\[\s*([A-Z0-9_]+)\s*\]', e['srcseg'].strip())
            if m and m.group(1) in CONSTANTS:
                expanded = CONSTANTS[m.group(1)].format(name=name, lower=name.lower(), v=new_ver)
                keep_existing = expanded == fn
        if keep_existing:
            new_sources = None
        elif e['want_wheel'] or fn not in defaults:
            new_sources = f"['{fn_tmpl}']"
        else:
            new_sources = None

        if e['ver_is_var']:
            vl = next(i for i, ln in enumerate(lines) if ln.startswith('version = '))
            lines[vl] = f"version = '{new_ver}'"
        else:
            hl = el.lineno - 1
            lines[hl] = lines[hl].replace(f"'{e['ver']}'", f"'{new_ver}'", 1)

        if 'checksums' in keys:
            v = keys['checksums']
            edits.append((v.lineno - 1, v.end_lineno - 1, [f"{ind}'checksums': ['{sha}'],"]))
        else:
            report.append((name, e['ver'], new_ver, 'WARNING: entry has no checksums key'))
        if 'sources' in keys and not keep_existing:
            v = keys['sources']
            m = re.search(r'(\s+#.*)$', lines[v.end_lineno - 1])
            comment = m.group(1) if m else ''
            edits.append((v.lineno - 1, v.end_lineno - 1, [f"{ind}'sources': {new_sources},{comment}"] if new_sources else []))
        elif 'sources' not in keys and new_sources and 'checksums' in keys:
            t = keys['checksums'].end_lineno - 1
            edits.append((t + 1, t, [f"{ind}'sources': {new_sources},"]))

        status = 'updated' if new_ver != e['ver'] else ''
        if reqpy:
            status += f'  (requires_python {reqpy})'
        report.append((name, e['ver'], new_ver, status))

    for s, t, new in sorted(edits, key=lambda x: (x[0], x[1]), reverse=True):
        lines[s:t + 1] = new
    out = '\n'.join(lines)
    ast.parse(out)  # never write a broken easyconfig
    open(args.outfile, 'w').write(out)

    w = max(len(r[0]) for r in report)
    for r in report:
        print(f"{r[0]:<{w}}  {r[1]:>12} -> {r[2]:<12} {r[3]}")
    print(f"\n{sum(1 for r in report if r[1] != r[2])} of {len(report)} extensions changed")


if __name__ == '__main__':
    main()
