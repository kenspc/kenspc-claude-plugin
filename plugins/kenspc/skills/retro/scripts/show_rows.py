#!/usr/bin/env python3
"""show_rows.py - print chosen findings in full.

Usage
  python3 -I show_rows.py <retro dir> <key>...

Prints each named finding's full row from <retro dir>/findings.tsv, one
`column: value` line per column, so the main session cites a finding's lines
without opening the review reports.

Exit codes
  0  every key was found and printed
  1  a key is not in findings.tsv (it is named on stderr; the found ones
     are still printed)
  2  a usage error: no key, or findings.tsv cannot be read

Standard library only; runs on Python 3.9 or newer.
"""
import os
import sys


def main(argv):
    if len(argv) < 3:
        sys.stderr.write("usage: show_rows.py <retro dir> <key>...\n")
        return 2
    path = os.path.join(argv[1], "findings.tsv")
    try:
        with open(path, encoding="utf-8") as handle:
            lines = handle.read().splitlines()
        header = lines[0].split("\t")
    except (OSError, IndexError) as error:
        sys.stderr.write("show_rows.py: cannot read %s (%s)\n" % (path, error))
        return 2
    rows = {}
    for line in lines[1:]:
        cells = line.split("\t")
        rows[cells[0]] = cells
    missing = 0
    for key in argv[2:]:
        cells = rows.get(key)
        if cells is None:
            sys.stderr.write("show_rows.py: no finding %s\n" % key)
            missing += 1
            continue
        print("## %s" % key)
        for name, value in zip(header, cells):
            print("%s: %s" % (name, value))
        print()
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
