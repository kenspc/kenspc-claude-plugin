#!/usr/bin/env python3
"""slice_findings.py - the retro skill's classifier inputs.

Usage
  python3 -I slice_findings.py <retro dir> [<previous record>]

Reads findings.tsv and runs.tsv from <retro dir>, the rows of runs runs.tsv
marks in the window only, and writes there:

  sample.tsv     only without a previous record: up to SAMPLE_ROWS rows for
                 the classifier's `derive` dispatch, drawn from every
                 in-window batch in proportion to its row count (each batch
                 at least one row while the total allows), with a fixed seed
                 so a re-run draws the same rows
  slice-<n>.tsv  every in-window row, in run order, at most SLICE_ROWS each,
                 one `classify` dispatch per slice
  kinds.tsv      only with a previous record: its `## Kinds` table, so a
                 later retro classifies against the kinds the record ranked

Each sample and slice row carries key, sources, severity, action, file,
short_label, and description.

Exit codes
  0  the files were written
  2  a usage error: the wrong arguments, an input that cannot be read, or a
     previous record with no `## Kinds` table

Standard library only; runs on Python 3.9 or newer.
"""
import importlib.util
import os
import random
import sys

# Rows per classify dispatch. Two classifications of one window in
# 120-row slices ranked mostly the same top kinds, and 120 needs half the
# dispatches that 61-row slices did.
SLICE_ROWS = 120
SAMPLE_ROWS = 200
SAMPLE_SEED = 20261021
COLUMNS = ("key", "sources", "severity", "action", "file", "short_label",
           "description")


def load_rank():
    """Load rank.py, which holds the record parser, by path (python3 -I)."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "rank.py")
    spec = importlib.util.spec_from_file_location("rank", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def write_tsv(path, columns, rows):
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\t".join(columns) + "\n")
        for row in rows:
            handle.write("\t".join(row[c] for c in columns) + "\n")


def quotas(counts, total):
    """Split `total` sample rows over batches in proportion to `counts`.

    Largest remainder, then every batch gets at least one row, taken from
    the largest share, while the total allows.
    """
    rows = sum(counts.values())
    if rows <= total:
        return dict(counts)
    exact = {b: total * n / rows for b, n in counts.items()}
    share = {b: int(v) for b, v in exact.items()}
    left = total - sum(share.values())
    for batch in sorted(exact, key=lambda b: (share[b] - exact[b], b))[:left]:
        share[batch] += 1
    for batch in sorted(counts):
        if share[batch] == 0:
            donor = max(sorted(share), key=lambda b: share[b])
            if share[donor] > 1:
                share[donor] -= 1
                share[batch] = 1
    return share


def main(argv):
    if len(argv) not in (2, 3):
        sys.stderr.write(
            "usage: slice_findings.py <retro dir> [<previous record>]\n")
        return 2
    retro = argv[1]
    record_path = argv[2] if len(argv) == 3 else None
    rank = load_rank()
    try:
        runs = {r["run"]: r for r in rank.read_tsv(
            os.path.join(retro, "runs.tsv"))}
        findings = rank.read_tsv(os.path.join(retro, "findings.tsv"))
        record = rank.read_record(record_path) if record_path else None
    except (OSError, IndexError, KeyError) as error:
        sys.stderr.write("slice_findings.py: cannot read the inputs (%s)\n"
                         % error)
        return 2
    if record is not None and not record["kinds"]:
        sys.stderr.write("slice_findings.py: %s has no `## Kinds` table\n"
                         % record_path)
        return 2
    rows = [f for f in findings
            if runs.get(f["run"], {}).get("in_window") == "true"]
    rows.sort(key=lambda r: (r["run"], int(r["row"])))

    slices = [rows[i:i + SLICE_ROWS] for i in range(0, len(rows), SLICE_ROWS)]
    for n, part in enumerate(slices, 1):
        write_tsv(os.path.join(retro, "slice-%d.tsv" % n), COLUMNS, part)

    if record is None:
        by_batch = {}
        for row in rows:
            by_batch.setdefault(runs[row["run"]]["batch"], []).append(row)
        share = quotas({b: len(r) for b, r in by_batch.items()}, SAMPLE_ROWS)
        draw = random.Random(SAMPLE_SEED)
        sample = []
        for batch in sorted(by_batch):
            sample += draw.sample(by_batch[batch], share[batch])
        sample.sort(key=lambda r: (r["run"], int(r["row"])))
        write_tsv(os.path.join(retro, "sample.tsv"), COLUMNS, sample)
        made = "sample.tsv %d rows" % len(sample)
    else:
        kinds = [{"kind": k, "definition": d} for k, d in record["kinds"]]
        write_tsv(os.path.join(retro, "kinds.tsv"), ("kind", "definition"),
                  kinds)
        made = "kinds.tsv %d kinds from the previous record" % len(kinds)
    print("%d in-window rows; %d slice files of at most %d rows; %s."
          % (len(rows), len(slices), SLICE_ROWS, made))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
