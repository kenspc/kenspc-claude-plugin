"""Rank kinds under the retro bar for runs A and B, and compare their top five.

Usage: python3 -I rank.py <data dir> > result.md
Reads <data dir>/window.tsv, manual.tsv, and labels-A-*.tsv / labels-B-*.tsv
(columns key, kind). Bar: a kind counts when it appears in at least two
batches; cost is the severity-weighted row count (HIGH 3, MEDIUM 2, LOW 1);
`other` is never ranked. Prints Markdown with kind names and counts only.
"""
import csv
import glob
import os
import sys
from collections import defaultdict

WEIGHT = {"HIGH": 3, "MEDIUM": 2, "LOW": 1}
TOP = 5
csv.field_size_limit(10**7)
data = sys.argv[1]


def read(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


window = {r["key"]: r for r in read(os.path.join(data, "window.tsv"))}


def labels(prefix):
    out, dupes = {}, 0
    for path in sorted(glob.glob(os.path.join(data, f"labels-{prefix}-*.tsv"))):
        for r in read(path):
            key, kind = r["key"].strip(), r["kind"].strip().lower()
            if key in out:
                dupes += 1
            out[key] = kind
    missing = [k for k in window if k not in out]
    unknown = [k for k in out if k not in window]
    return out, {"missing": len(missing), "unknown keys": len(unknown), "duplicates": dupes}


def rank(lab):
    batches, cost, rows = defaultdict(set), defaultdict(int), defaultdict(int)
    for key, kind in lab.items():
        if key not in window:
            continue
        r = window[key]
        batches[kind].add(r["batch"])
        cost[kind] += WEIGHT[r["severity"]]
        rows[kind] += 1
    table = [(k, cost[k], rows[k], len(batches[k])) for k in cost
             if k != "other" and len(batches[k]) >= 2]
    table.sort(key=lambda t: (-t[1], -t[2], t[0]))
    return table


def show(name, table, n=8):
    print(f"\n### {name}: top {n} under the bar\n")
    print("| rank | kind | cost | rows | batches |")
    print("|---|---|---|---|---|")
    for i, (k, c, r, b) in enumerate(table[:n], 1):
        print(f"| {i} | {k} | {c} | {r} | {b} |")


runs = {p: labels(p) for p in ("A", "B")}
manual = {r["key"]: r["kind"] for r in read(os.path.join(data, "manual.tsv"))}
tables = {p: rank(runs[p][0]) for p in runs}
tables["manual"] = rank(manual)
tops = {p: [t[0] for t in tables[p][:TOP]] for p in tables}

print("# Finding-classification stability\n")
print(f"Window rows: {len(window)}.")
for p in ("A", "B"):
    lab, check = runs[p]
    kinds = {k for k in lab.values()}
    new = sorted(k for k in kinds if k.startswith("new:"))
    other = sum(1 for k in lab.values() if k == "other")
    print(f"Run {p}: {check}; kinds used {len(kinds)}; rows `other` {other}; new kinds {len(new)}: {', '.join(new) or 'none'}.")

for p in ("A", "B", "manual"):
    show(p, tables[p])

shared = [k for k in tops["A"] if k in tops["B"]]
same = len(shared)
both = [k for k in window if k in runs["A"][0] and k in runs["B"][0]]
agree = sum(1 for k in both if runs["A"][0][k] == runs["B"][0][k])
print("\n## Verdict\n")
print(f"- Top five shared by A and B: {same} of {TOP} (settled by: at least 4).")
overlaps = {}
for kind in shared:
    a = {k for k, v in runs["A"][0].items() if v == kind}
    b = {k for k, v in runs["B"][0].items() if v == kind}
    overlaps[kind] = len(a & b) / len(a | b)
    print(f"- Row overlap for {kind}: {len(a & b)}/{len(a | b)} = {overlaps[kind]:.0%} (settled by: at least 60%).")
ok = same >= 4 and all(v >= 0.6 for v in overlaps.values())
print(f"- Result: {'PASS' if ok else 'FAIL'}.")
print(f"- Reading only, per-row agreement A vs B: {agree}/{len(both)} = {agree / len(both):.0%}.")
print("\n## Reading only: where each top-five kind's rows sit in the manual classification\n")
for p in ("A", "B"):
    for kind in tops[p]:
        keys = [k for k, v in runs[p][0].items() if v == kind and k in manual]
        counts = defaultdict(int)
        for k in keys:
            counts[manual[k]] += 1
        best = sorted(counts.items(), key=lambda t: -t[1])[:2]
        print(f"- {p} {kind} ({len(keys)} rows): " + ", ".join(f"{m} {n}" for m, n in best))
