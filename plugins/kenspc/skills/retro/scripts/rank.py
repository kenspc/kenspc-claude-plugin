#!/usr/bin/env python3
"""rank.py - the retro skill's ranking of recurring problems.

Usage
  python3 -I rank.py <retro dir> [<previous record>]

Reads, from <retro dir>: labels-<n>.tsv (key, kind), findings.tsv,
runs.tsv, time.tsv, and new-kinds.tsv (name, kind or `other`) when present.
Writes <retro dir>/rank.md.

Labels
  A `new:<name>` label resolves through new-kinds.tsv, whose name column is
  written with or without the `new:` prefix. A name it does not list stays
  its own kind, `new:<name>`; rank.md lists every `new:` name with its
  batches. The labels files are never edited.

De-duplication
  Within one batch, an s3b row counts once when the same batch's s3 has a
  DEFERRED row with the same file (the path without `:line`) and the same
  kind: the s3b row is dropped. rank.md lists every merge as a key pair,
  since the rule can merge two different problems that share a file.

Findings list: kinds in at least two batches; cost HIGH 3 / MEDIUM 2 /
LOW 1 over de-duplicated rows; `other` is never ranked.
Time list: time.tsv role rows (`s3`) and s3/s3b subagent kinds
(`s3/<kind>`) measured in at least two batches; cost the total minutes,
with the share of all measured role time beside it.

Selection: up to 3 findings items and up to 2 time items; a list with
fewer candidates passes its unused slots to the other, 5 at most. A list's
next candidate within 10% of its last selected cost is printed as a
runner-up: at the cut, a near-tie is a coin toss the user should see.
Every ranked item whose batches include a `manual` run is marked, and
every ranked item lists its record keys (time items: their batches).

With a previous record
  Each adopted item's measure is printed then (from the record) and now; a
  time item with no measured row in this window prints `not measured in
  this window` as now.
  Each ranked item the record rejected is marked with its batch count then
  and now; one whose count has not grown is skipped, and its slot passes
  on. Pending and failed items are not marked.

The record lines this script reads (the retro skill's record grammar):
  Window: <YYYY-MM-DDTHH:MM:SS> to <YYYY-MM-DDTHH:MM:SS>
  the `## Kinds` table, columns kind and definition
  under `## Adopted`:  - Measure: kind `<kind>` cost = <n>
                       - Measure: time `<item>` minutes per batch = <n>
  under `## Rejected`: - Batches: kind `<kind>` = <n>
                       - Batches: time `<item>` = <n>

Exit codes
  0  rank.md was written
  2  a usage error: the wrong arguments, or an input that cannot be read

Standard library only; runs on Python 3.9 or newer.
"""
import glob
import os
import re
import sys

WEIGHT = {"HIGH": 3, "MEDIUM": 2, "LOW": 1}
FINDINGS_SLOTS = 3
TIME_SLOTS = 2
TOTAL_SLOTS = 5
MIN_BATCHES = 2
RUNNER_UP_SHARE = 0.10
SPLIT_ROLES = ("s3", "s3b")
OTHER = "other"
NEW = "new:"

WINDOW_LINE = re.compile(
    r"^Window: (\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d) to "
    r"(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d)")
MEASURE_LINE = re.compile(
    r"^- Measure: (?:(kind) `([^`]+)` cost|(time) `([^`]+)` minutes per batch)"
    r" = (\d+(?:\.\d+)?)\s*$")
BATCHES_LINE = re.compile(r"^- Batches: (kind|time) `([^`]+)` = (\d+)\s*$")
RUN_TIME = re.compile(r"^(\d{4})(\d\d)(\d\d)-(\d\d)(\d\d)(\d\d)")


def read_tsv(path):
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    header = lines[0].split("\t")
    return [dict(zip(header, line.split("\t"))) for line in lines[1:] if line]


def table_rows(lines):
    """Return the cells of a Markdown table's body rows."""
    rows = []
    for line in lines[2:]:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)
    return rows


def read_record(path):
    """Parse the lines a retro record holds for the scripts.

    Returns a dict: window (first, last) or None; kinds [(kind,
    definition)]; measures [(type, item, value)] from `## Adopted`;
    rejected [(type, item, batches)] from `## Rejected`.
    """
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    record = {"window": None, "kinds": [], "measures": [], "rejected": []}
    section = None
    kinds_table = []
    for line in lines:
        if line.startswith("## "):
            section = line[3:].strip()
            continue
        match = WINDOW_LINE.match(line)
        if match and record["window"] is None:
            record["window"] = match.groups()
        if section == "Kinds" and line.lstrip().startswith("|"):
            kinds_table.append(line)
        elif section == "Adopted":
            match = MEASURE_LINE.match(line)
            if match:
                kind_item, time_item = match.group(2), match.group(4)
                record["measures"].append(
                    ("kind", kind_item, match.group(5)) if kind_item
                    else ("time", time_item, match.group(5)))
        elif section == "Rejected":
            match = BATCHES_LINE.match(line)
            if match:
                record["rejected"].append(
                    (match.group(1), match.group(2), int(match.group(3))))
    for cells in table_rows(kinds_table):
        if len(cells) >= 2 and cells[0]:
            record["kinds"].append((cells[0], cells[1]))
    return record


def base_path(file_cell):
    match = re.match(r"[^:\s]+", file_cell.strip())
    return match.group(0) if match else file_cell.strip()


def new_name(label):
    return label[len(NEW):] if label.startswith(NEW) else label


def iso(run):
    match = RUN_TIME.match(run)
    if match is None:
        return run
    y, mo, d, h, mi, s = match.groups()
    return "%s-%s-%sT%s:%s:%s" % (y, mo, d, h, mi, s)


def load(retro):
    """Read the retro directory's inputs into one dict."""
    runs = {r["run"]: r for r in read_tsv(os.path.join(retro, "runs.tsv"))}
    window_runs = {run for run, r in runs.items() if r["in_window"] == "true"}
    findings = [r for r in read_tsv(os.path.join(retro, "findings.tsv"))
                if r["run"] in window_runs]
    labels = {}
    duplicates = 0
    paths = glob.glob(os.path.join(glob.escape(retro), "labels-*.tsv"))
    for path in sorted(paths, key=lambda p: [int(n) if n.isdigit() else n
                                             for n in re.split(r"(\d+)", p)]):
        for row in read_tsv(path):
            key = row.get("key", "").strip()
            if key in labels:
                duplicates += 1
            labels[key] = row.get("kind", "").strip()
    resolve = {}
    new_kinds = os.path.join(retro, "new-kinds.tsv")
    if os.path.isfile(new_kinds):
        for row in read_tsv(new_kinds):
            resolve[new_name(row.get("name", "").strip())] = \
                row.get("kind", "").strip()
    time_path = os.path.join(retro, "time.tsv")
    times = read_tsv(time_path) if os.path.isfile(time_path) else []
    return {"runs": runs, "window_runs": window_runs, "findings": findings,
            "labels": labels, "duplicates": duplicates, "resolve": resolve,
            "times": [t for t in times if t["batch"] in
                      {runs[r]["batch"] for r in window_runs}]}


def classify(data):
    """Return the de-duplicated rows with kinds, the merges, and checks."""
    runs, labels, resolve = data["runs"], data["labels"], data["resolve"]
    rows = []
    new_seen = {}
    for finding in data["findings"]:
        label = labels.get(finding["key"])
        if label is None:
            continue
        kind = label
        if label.startswith(NEW):
            name = new_name(label)
            kind = resolve.get(name) or label
            new_seen.setdefault(label, set()).add(runs[finding["run"]]["batch"])
        run = runs[finding["run"]]
        rows.append(dict(finding, kind=kind, batch=run["batch"],
                         role=run["role"]))
    deferred = {}
    for row in rows:
        if row["role"] == "s3" and row["action"] == "DEFERRED":
            deferred.setdefault((row["batch"], base_path(row["file"]),
                                 row["kind"]), row["key"])
    kept, merges = [], []
    for row in rows:
        twin = deferred.get((row["batch"], base_path(row["file"]), row["kind"]))
        if row["role"] == "s3b" and twin is not None:
            merges.append((twin, row["key"], row["kind"],
                           base_path(row["file"])))
            continue
        kept.append(row)
    window_keys = {f["key"] for f in data["findings"]}
    checks = {
        "in-window rows": len(window_keys),
        "labelled": sum(1 for k in window_keys if k in labels),
        "unlabelled": sorted(k for k in window_keys if k not in labels),
        "labels outside the window": sum(1 for k in labels
                                         if k not in window_keys),
        "duplicate labels": data["duplicates"],
        "unknown severity": sum(1 for r in kept
                                if r["severity"] not in WEIGHT),
    }
    return kept, merges, new_seen, checks


def findings_list(kept, manual_batches):
    items = {}
    for row in kept:
        item = items.setdefault(row["kind"], {"cost": 0, "rows": 0,
                                              "batches": set(), "keys": []})
        item["cost"] += WEIGHT.get(row["severity"], 0)
        item["rows"] += 1
        item["batches"].add(row["batch"])
        item["keys"].append(row["key"])
    ranked = []
    for kind, item in items.items():
        if kind == OTHER or len(item["batches"]) < MIN_BATCHES:
            continue
        ranked.append(dict(item, type="kind", name=kind,
                           manual=bool(item["batches"] & manual_batches)))
    ranked.sort(key=lambda i: (-i["cost"], -i["rows"], i["name"]))
    return ranked, items


def time_items(times):
    items = {}
    for row in times:
        if row["status"] != "measured" or row["minutes"] == "":
            continue
        if row["kind"] == "wall":
            name = row["role"]
        elif row["role"] in SPLIT_ROLES:
            name = "%s/%s" % (row["role"], row["kind"])
        else:
            continue
        item = items.setdefault(name, {"cost": 0.0, "batches": set()})
        item["cost"] += float(row["minutes"])
        item["batches"].add(row["batch"])
    return items


def time_list(items, total):
    ranked = []
    for name, item in items.items():
        if len(item["batches"]) < MIN_BATCHES:
            continue
        ranked.append(dict(item, type="time", name=name, manual=False,
                           share=item["cost"] / total if total else 0.0,
                           keys=sorted(item["batches"])))
    ranked.sort(key=lambda i: (-i["cost"], i["name"]))
    return ranked


def mark_rejected(ranked, rejected):
    """Mark rejected items; return the candidates left for selection."""
    then = {(kind, item): count for kind, item, count in rejected}
    left = []
    for item in ranked:
        before = then.get((item["type"], item["name"]))
        if before is not None:
            now = len(item["batches"])
            item["record"] = "rejected: batches %d then, %d now%s" % (
                before, now, "" if now > before else "; skipped")
            if now <= before:
                continue
        left.append(item)
    return left


def select(findings, times):
    take_f = min(FINDINGS_SLOTS, len(findings))
    take_t = min(TIME_SLOTS, len(times))
    spare = TOTAL_SLOTS - take_f - take_t
    extra = min(spare, len(findings) - take_f)
    take_f += extra
    take_t += min(spare - extra, len(times) - take_t)
    return findings[:take_f], times[:take_t]


def runner_up(candidates, chosen):
    if not chosen or len(candidates) <= len(chosen):
        return None
    last, nxt = chosen[-1]["cost"], candidates[len(chosen)]["cost"]
    if round(last - nxt, 6) <= round(last * RUNNER_UP_SHARE, 6):
        return candidates[len(chosen)]
    return None


def number(value):
    return ("%d" % value) if isinstance(value, int) else ("%.1f" % value)


def render(data, kept, merges, new_seen, checks, f_ranked, t_ranked,
           f_left, t_left, chosen_f, chosen_t, follow, record_path, record):
    runs = data["runs"]
    in_runs = sorted(data["window_runs"])
    batches = {runs[r]["batch"] for r in in_runs}
    manual = {runs[r]["batch"] for r in in_runs if runs[r]["role"] == "manual"}
    out = ["# Ranking", ""]
    if in_runs:
        out.append("Window: %s to %s; %d batches, %d of them a manual run."
                   % (iso(in_runs[0]), iso(in_runs[-1]), len(batches),
                      len(manual)))
    else:
        out.append("Window: no run in the window.")
    out += ["", "## Label check", ""]
    for name, value in checks.items():
        if isinstance(value, list):
            shown = ", ".join("`%s`" % k for k in value) if value else "none"
            out.append("- %s: %d (%s)" % (name, len(value), shown))
        else:
            out.append("- %s: %d" % (name, value))
    out += ["", "## New kinds", ""]
    if new_seen:
        out += ["| label | batches | resolved to |", "|---|---|---|"]
        for label in sorted(new_seen):
            out.append("| %s | %s | %s |" % (
                label, ", ".join(sorted(new_seen[label])),
                data["resolve"].get(new_name(label)) or "unresolved"))
    else:
        out.append("none")
    out += ["", "## De-duplication merges", ""]
    out += ["- `%s` (s3, DEFERRED) absorbs `%s` (s3b): kind %s, file %s"
            % m for m in merges] or ["none"]

    selected = [("findings", i) for i in chosen_f] + \
               [("time", i) for i in chosen_t]
    out += ["", "## Selected", ""]
    for n, (kind, item) in enumerate(selected, 1):
        out.append("%d. %s `%s`: cost %s, %d batches%s%s" % (
            n, kind, item["name"], number(item["cost"]), len(item["batches"]),
            ", includes a manual run" if item["manual"] else "",
            "; " + item["record"] if item.get("record") else ""))
    if not selected:
        out.append("none")
    out += ["", "## Runner-ups", ""]
    runners = [(name, runner_up(cands, chosen), chosen)
               for name, cands, chosen in (("findings", f_left, chosen_f),
                                           ("time", t_left, chosen_t))]
    lines = ["- %s `%s`: cost %s, within 10%% of the last selected cost %s"
             % (name, item["name"], number(item["cost"]),
                number(chosen[-1]["cost"]))
             for name, item, chosen in runners if item is not None]
    out += lines or ["none"]

    chosen_names = {id(i) for _, i in selected}
    out += ["", "## Findings list", "",
            "| rank | kind | cost | rows | batches | manual | selected | record |",
            "|---|---|---|---|---|---|---|---|"]
    for n, item in enumerate(f_ranked, 1):
        out.append("| %d | %s | %d | %d | %d | %s | %s | %s |" % (
            n, item["name"], item["cost"], item["rows"], len(item["batches"]),
            "yes" if item["manual"] else "", "yes" if id(item) in chosen_names
            else "", item.get("record", "")))
    out += ["", "## Time list", "",
            "| rank | item | minutes | share | batches | selected | record |",
            "|---|---|---|---|---|---|---|"]
    for n, item in enumerate(t_ranked, 1):
        out.append("| %d | %s | %.1f | %.0f%% | %d | %s | %s |" % (
            n, item["name"], item["cost"], item["share"] * 100,
            len(item["batches"]), "yes" if id(item) in chosen_names else "",
            item.get("record", "")))
    if not t_ranked:
        out.append("")
        out.append("No time item measured in two batches.")

    out += ["", "## Follow-up", ""]
    if record_path is None:
        out.append("No previous record.")
    else:
        window = record["window"]
        out.append("Previous record `%s`, window %s." % (
            os.path.basename(record_path),
            "%s to %s" % window if window else "not found"))
        out += ["", "| item | measure | then | now |", "|---|---|---|---|"]
        out += ["| %s `%s` | %s | %s | %s |" % row for row in follow]

    out += ["", "## Keys", ""]
    for item in f_ranked + t_ranked:
        out.append("- %s `%s`: %s" % (item["type"], item["name"],
                                       " ".join(item["keys"])))
    return "\n".join(out) + "\n"


def main(argv):
    if len(argv) not in (2, 3):
        sys.stderr.write("usage: rank.py <retro dir> [<previous record>]\n")
        return 2
    retro = argv[1]
    record_path = argv[2] if len(argv) == 3 else None
    try:
        data = load(retro)
        record = read_record(record_path) if record_path else None
    except (OSError, IndexError, KeyError) as error:
        sys.stderr.write("rank.py: cannot read the inputs (%s)\n" % error)
        return 2
    kept, merges, new_seen, checks = classify(data)
    runs = data["runs"]
    manual = {runs[r]["batch"] for r in data["window_runs"]
              if runs[r]["role"] == "manual"}
    f_ranked, kinds = findings_list(kept, manual)
    t_items = time_items(data["times"])
    total = sum(float(t["minutes"]) for t in data["times"]
                if t["kind"] == "wall" and t["status"] == "measured"
                and t["minutes"] != "")
    t_ranked = time_list(t_items, total)
    f_left, t_left = f_ranked, t_ranked
    follow = []
    if record is not None:
        f_left = mark_rejected(f_ranked, [r for r in record["rejected"]
                                          if r[0] == "kind"])
        t_left = mark_rejected(t_ranked, [r for r in record["rejected"]
                                          if r[0] == "time"])
        for kind, item, then in record["measures"]:
            if kind == "kind":
                now = kinds.get(item, {}).get("cost", 0)
                follow.append((kind, item, "cost", then, "%d" % now))
            else:
                # No measured row is not zero minutes: the sessions may lack
                # .exit or their transcripts, so print no number for it.
                found = t_items.get(item)
                now = ("%.1f" % (found["cost"] / len(found["batches"]))
                       if found else "not measured in this window")
                follow.append((kind, item, "minutes per batch", then, now))
    chosen_f, chosen_t = select(f_left, t_left)
    text = render(data, kept, merges, new_seen, checks, f_ranked, t_ranked,
                  f_left, t_left, chosen_f, chosen_t, follow, record_path,
                  record)
    with open(os.path.join(retro, "rank.md"), "w", encoding="utf-8",
              newline="\n") as handle:
        handle.write(text)
    print("rank.md: %d findings and %d time items selected."
          % (len(chosen_f), len(chosen_t)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
