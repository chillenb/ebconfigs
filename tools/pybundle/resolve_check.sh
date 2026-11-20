#!/bin/bash
# Ask pip's resolver whether a set of pinned versions is consistent, without installing anything.
#
# usage: resolve_check.sh PINS.txt [PYTHON_MODULE]
#   PINS.txt       name==version lines, e.g. from collect_pins.py
#   PYTHON_MODULE  module providing the target Python (e.g. Python/3.14.2-GCCcore-16.2.0);
#                  omit if the right python3 is already on PATH
#
# Prints either the first conflict pip finds (fix it, regenerate the pins, run again), or
# "RESOLVED OK" plus any packages pip had to pull in that are not pinned, i.e. new requirements
# that need to be added to the bundle, together with the packages that require them.
# Optional extras are not followed, matching what `pip check` enforces.
set -euo pipefail
pins=$(realpath "$1")
[ $# -ge 2 ] && module load "$2"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
python3 -m venv "$work/venv"
"$work/venv/bin/pip" install -q packaging >/dev/null 2>&1

if ! "$work/venv/bin/pip" install --dry-run --ignore-installed --report "$work/report.json" \
        -r "$pins" > "$work/resolve.log" 2>&1; then
    grep -A12 'conflict is caused' "$work/resolve.log" || tail -20 "$work/resolve.log"
    exit 1
fi

"$work/venv/bin/python" - "$pins" "$work/report.json" <<'EOF'
import json, re, sys
from packaging.requirements import Requirement
norm = lambda n: re.sub(r'[-_.]+', '-', n).lower()
pins = {norm(l.split('==')[0]) for l in open(sys.argv[1]) if '==' in l}
rep = json.load(open(sys.argv[2]))['install']
extra = {norm(i['metadata']['name']): i['metadata']['version'] for i in rep if norm(i['metadata']['name']) not in pins}
print('RESOLVED OK.')
if not extra:
    print('No packages pulled in beyond the pins.')
    sys.exit(0)
print('Packages pulled in that are not pinned (add them, or confirm they are only optional extras):')
for i in rep:
    m = i['metadata']
    for r in m.get('requires_dist') or []:
        req = Requirement(r)
        if norm(req.name) in extra:
            how = 'required' if not req.marker or req.marker.evaluate({'extra': ''}) else f'via marker: {req.marker}'
            print(f"  {req.name} {extra[norm(req.name)]:<10} <- {m['name']} {m['version']} ({how})")
EOF
