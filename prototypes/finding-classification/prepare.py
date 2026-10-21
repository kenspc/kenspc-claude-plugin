"""Split the manual retro's findings into a derivation sample and a classification window.

Usage: python3 -I prepare.py <analysis dir> <out dir>
Reads <analysis dir>/findings.tsv, categories.tsv and followup/verify/runmap.tsv.
Writes, under <out dir>: sample.tsv (older batches, for deriving kinds),
window.tsv (the 20 most recent batches), manual.tsv (the manual kind of each
window row), and slices/A-*.tsv (chronological) and slices/B-*.tsv (shuffled).
"""
import csv
import os
import random
import sys

WINDOW = 20
SLICES = 6
SAMPLE = 200

src, out = sys.argv[1], sys.argv[2]
csv.field_size_limit(10**7)


def read(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f, delimiter="\t"))


def write(path, rows, cols):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="") as f:
        w = csv.writer(f, delimiter="\t", lineterminator="\n")
        w.writerow(cols)
        for r in rows:
            w.writerow([r[c].replace("\t", " ").replace("\n", " ") for c in cols])


runmap = {r["run"]: r for r in read(os.path.join(src, "followup/verify/runmap.tsv"))}
findings = read(os.path.join(src, "findings.tsv"))
kinds = {r["key"]: r["kind"] for r in read(os.path.join(src, "categories.tsv"))}

first_run = {}
for run in sorted(runmap):
    first_run.setdefault(runmap[run]["batch"], run)
order = sorted(first_run, key=first_run.get)
window_batches = set(order[-WINDOW:])

for r in findings:
    r["key"] = f"{r['run']}#{r['row']}"
    r["batch"] = runmap[r["run"]]["batch"]

window = [r for r in findings if r["batch"] in window_batches]
older = [r for r in findings if r["batch"] not in window_batches]

rng = random.Random(7)
by_batch = {}
for r in older:
    by_batch.setdefault(r["batch"], []).append(r)
per = SAMPLE // len(by_batch) + 1
sample = []
for b in sorted(by_batch):
    rows = by_batch[b]
    sample.extend(rng.sample(rows, min(per, len(rows))))
sample = sample[:SAMPLE]

cols = ["key", "severity", "file", "short_label", "description"]
write(os.path.join(out, "sample.tsv"), sample, cols)
write(os.path.join(out, "window.tsv"), window, ["key", "batch"] + cols[1:])
write(os.path.join(out, "manual.tsv"),
      [{"key": r["key"], "kind": kinds[r["key"]]} for r in window], ["key", "kind"])

chrono = sorted(window, key=lambda r: (r["run"], int(r["row"])))
shuffled = chrono[:]
random.Random(42).shuffle(shuffled)
size = -(-len(window) // SLICES)
for name, rows in (("A", chrono), ("B", shuffled)):
    for i in range(SLICES):
        write(os.path.join(out, "slices", f"{name}-{i + 1}.tsv"),
              rows[i * size:(i + 1) * size], cols)

print(f"batches {len(order)}, window {len(window_batches)} batches / {len(window)} rows, "
      f"older {len(older)} rows, sample {len(sample)}, slice size {size}")
