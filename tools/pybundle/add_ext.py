#!/usr/bin/env python3
"""Insert a placeholder extension into an easyconfig's exts_list, before an existing one.

usage: add_ext.py FILE.eb NEW_NAME BEFORE_NAME

The entry is written as ('NEW_NAME', '0', {'checksums': ['placeholder']}); run update_exts.py
afterwards to fill in the latest version and its checksum.
"""
import re
import sys


def main():
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    f, new, before = sys.argv[1:4]
    lines = open(f).read().split('\n')
    try:
        idx = next(i for i, ln in enumerate(lines) if re.match(rf"\s+\('{re.escape(before)}',", ln))
    except StopIteration:
        sys.exit(f"extension '{before}' not found in {f}")
    ind = re.match(r'(\s+)', lines[idx]).group(1)
    lines[idx:idx] = [f"{ind}('{new}', '0', {{", f"{ind}    'checksums': ['placeholder'],", f"{ind}}}),"]
    open(f, 'w').write('\n'.join(lines))
    print(f"inserted {new} before {before}")


if __name__ == '__main__':
    main()
