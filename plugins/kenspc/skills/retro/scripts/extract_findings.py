#!/usr/bin/env python3
"""extract_findings.py - the retro skill's findings extraction.

Usage
  python3 -I extract_findings.py <repo> <out>

Reads every .kenspc/runs/*/schema-b.md and the angle-<n>.md files beside it,
in <repo> and in each worktree `git -C <repo> worktree list` names, and
writes:

  <out>/findings.tsv  one row per Schema B row; columns key (<run>#<row>),
                      run, row, sources, severity, action, file, short_label,
                      description
  <out>/extract.md    the worktrees read, and every anomaly: a stats line
                      the rows do not recount to, a row whose cell count
                      differs from its header, a missing angle file, a
                      Source ID with no angle row

Parsing
  - Table rows split on unescaped `|` only; `\\|` inside a cell stays, and
    so does a `|` inside a code span.
  - Columns come from each table's header row, never from a fixed index.
  - Severity and Action lose Markdown emphasis; Action keeps its word before
    any em dash (`DEFERRED - ruled` reads DEFERRED).
  - A row's description is the angle row of its primary Source ID: the first
    ID in Source, whose letter names the angle file (R=1, E=2, Q=3, B=4,
    T=5) and whose whole ID is that file's `#` cell. Sources F and V have no
    angle file, so the row keeps short_label as its description.
  - rulings.md is not parsed: a ruling already shows in Action.

Why python: the manual retro this replaces parsed these tables in shell, and
the escaped pipes inside cells were where it went wrong.

Exit codes
  0  the outputs were written (anomalies are reported in extract.md, not
     as a failure)
  2  a usage error: the wrong arguments, or <repo> is not a directory

Standard library only; runs on Python 3.9 or newer.
"""
import os
import re
import subprocess
import sys

ANGLE_OF_LETTER = {"R": 1, "E": 2, "Q": 3, "B": 4, "T": 5}
# code-fixer (F) and regression-verifier (V) rows have no angle file.
NO_ANGLE_LETTERS = ("F", "V")
ACTIONS = ("FIXED", "DEFERRED", "NOT APPLICABLE")
COLUMNS = ("key", "run", "row", "sources", "severity", "action", "file",
           "short_label", "description")
SCHEMA_B_COLUMNS = ("#", "source", "short_label", "severity", "file:line",
                    "action")

SEPARATOR_CELL = re.compile(r":?-+:?")
EMPHASIS = re.compile(r"[*_`]")
SOURCE_ID = re.compile(r"([A-Z])(\d+)")
STATS_COUNTS = re.compile(
    r"(\d+) unique, FIXED (\d+), DEFERRED (\d+), NOT APPLICABLE (\d+)")


def split_unescaped(text):
    """Split text on each `|` that is not escaped and not in a code span.

    A pipe inside a code span stays in its cell: review reports write code
    such as `a || b` in a description cell without escaping it, and splitting
    there would shift every later cell. A backtick run opens a code span only
    when the same run closes it later on the line, as in CommonMark.
    """
    parts, start, i = [], 0, 0
    while i < len(text):
        char = text[i]
        if char == "\\":
            i += 2
            continue
        if char == "`":
            run = len(text) - i - len(text[i:].lstrip("`"))
            close = re.compile(
                "(?<!`)" + "`" * run + "(?!`)").search(text, i + run)
            i = close.end() if close else i + run
            continue
        if char == "|":
            parts.append(text[start:i])
            start = i + 1
        i += 1
    parts.append(text[start:])
    return parts


def split_cells(line):
    """Return a table row's cells, split on unescaped pipes only."""
    parts = split_unescaped(line.rstrip("\r\n"))
    cells = [c.strip() for c in parts]
    if len(cells) >= 2 and cells[0] == "" and cells[-1] == "":
        cells = cells[1:-1]
    return cells


def is_separator(cells):
    return all(SEPARATOR_CELL.fullmatch(c) for c in cells if c)


def read_lines(path):
    with open(path, encoding="utf-8", errors="replace") as handle:
        return handle.read().splitlines()


def tables(lines):
    """Yield (header cells, [(line number, cells), ...]) for each table."""
    header = None
    body = []
    for number, line in enumerate(lines, 1):
        if not line.lstrip().startswith("|"):
            if header is not None:
                yield header, body
            header, body = None, []
            continue
        cells = split_cells(line.strip())
        if header is None:
            header = (number, cells)
            continue
        if is_separator(cells):
            continue
        body.append((number, cells))
    if header is not None:
        yield header, body


def clean(text):
    return EMPHASIS.sub("", text).strip()


def action_word(text):
    return clean(text).split("—")[0].strip().upper()


def tsv_cell(text):
    return re.sub(r"[\t\r\n]+", " ", text)


def parse_angle(path, run, anomalies):
    """Map each Issues-table `#` ID of one angle file to its description."""
    rows = {}
    name = os.path.basename(path)
    for (head_line, head), body in tables(read_lines(path)):
        low = [c.lower() for c in head]
        if "#" not in low or "severity" not in low:
            continue
        desc = next((i for i, c in enumerate(low) if "description" in c), None)
        if desc is None:
            continue
        ident = low.index("#")
        for number, cells in body:
            if len(cells) != len(head):
                anomalies.append(
                    "`%s` %s:%d: %d cells, its header has %d"
                    % (run, name, number, len(cells), len(head)))
                continue
            rows[cells[ident]] = cells[desc]
    return rows


def parse_run(run_dir, run, anomalies):
    """Return the findings rows of one run directory's schema-b.md."""
    lines = read_lines(os.path.join(run_dir, "schema-b.md"))
    angles = {}
    found = []
    for (head_line, head), body in tables(lines):
        low = [c.lower() for c in head]
        if not ("#" in low and "severity" in low and "action" in low):
            continue
        missing = [c for c in SCHEMA_B_COLUMNS if c not in low]
        if missing:
            anomalies.append(
                "`%s` schema-b.md:%d: table header lacks %s; table skipped"
                % (run, head_line, ", ".join(missing)))
            continue
        col = {name: low.index(name) for name in SCHEMA_B_COLUMNS}
        for number, cells in body:
            if len(cells) != len(head):
                anomalies.append(
                    "`%s` schema-b.md:%d: %d cells, its header has %d"
                    % (run, number, len(cells), len(head)))
                continue
            row = cells[col["#"]]
            if not row.isdigit():
                anomalies.append(
                    "`%s` schema-b.md:%d: `#` cell is not a number (%r)"
                    % (run, number, row))
                continue
            sources = cells[col["source"]]
            short_label = cells[col["short_label"]]
            description = describe(run_dir, run, sources, short_label,
                                   angles, anomalies, number)
            found.append({
                "key": "%s#%s" % (run, row),
                "run": run,
                "row": row,
                "sources": sources,
                "severity": clean(cells[col["severity"]]).upper(),
                "action": action_word(cells[col["action"]]),
                "file": cells[col["file:line"]],
                "short_label": short_label,
                "description": description,
            })
    recount(lines, run, found, anomalies)
    return found


def describe(run_dir, run, sources, short_label, angles, anomalies, number):
    """Return the description of a row through its primary Source ID."""
    primary = clean(sources.split(",")[0])
    match = SOURCE_ID.fullmatch(primary)
    if match is None:
        anomalies.append("`%s` schema-b.md:%d: unreadable Source ID %r"
                         % (run, number, primary))
        return short_label
    letter = match.group(1)
    if letter in NO_ANGLE_LETTERS:
        return short_label
    angle = ANGLE_OF_LETTER.get(letter)
    if angle is None:
        anomalies.append("`%s` schema-b.md:%d: Source ID %s names no angle"
                         % (run, number, primary))
        return short_label
    if angle not in angles:
        path = os.path.join(run_dir, "angle-%d.md" % angle)
        if os.path.isfile(path):
            angles[angle] = parse_angle(path, run, anomalies)
        else:
            anomalies.append("`%s`: missing angle file angle-%d.md"
                             % (run, angle))
            angles[angle] = None
    rows = angles[angle]
    if rows is None:
        return short_label
    if primary not in rows:
        anomalies.append(
            "`%s` schema-b.md:%d: Source ID %s has no angle row in angle-%d.md"
            % (run, number, primary, angle))
        return short_label
    return rows[primary]


def recount(lines, run, found, anomalies):
    """Compare the rows read with the stats line that ends schema-b.md."""
    last = next((l for l in reversed(lines) if l.strip()), "")
    match = STATS_COUNTS.search(last) if "total reported" in last else None
    if match is None:
        anomalies.append("`%s`: schema-b.md does not end with a stats line"
                         % run)
        return
    stated = tuple(int(n) for n in match.groups())
    counted = (len(found),) + tuple(
        sum(1 for r in found if r["action"] == a) for a in ACTIONS)
    if stated != counted:
        anomalies.append(
            "`%s`: recount mismatch: the stats line says %d unique, FIXED %d,"
            " DEFERRED %d, NOT APPLICABLE %d; the rows give %d, FIXED %d,"
            " DEFERRED %d, NOT APPLICABLE %d" % ((run,) + stated + counted))


def worktrees(repo, anomalies):
    """Return the repository's worktree paths, the repository first."""
    paths = [repo]
    try:
        done = subprocess.run(
            ["git", "-C", repo, "worktree", "list", "--porcelain"],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            universal_newlines=True, check=False)
    except OSError as error:
        anomalies.append("git worktree list could not run (%s); only the"
                         " repository itself was read" % error)
        return paths
    if done.returncode != 0:
        anomalies.append("git worktree list failed (%s); only the repository"
                         " itself was read" % done.stderr.strip())
        return paths
    seen = {os.path.realpath(repo)}
    for line in done.stdout.splitlines():
        if line.startswith("worktree "):
            path = line[len("worktree "):]
            if os.path.realpath(path) not in seen:
                seen.add(os.path.realpath(path))
                paths.append(path)
    return paths


def run_dirs(repo, anomalies):
    """Return the run directories to read and the count read per tree.

    A run directory is one with a schema-b.md under .kenspc/runs/ of the
    repository or one of its worktrees. map_runs.py maps the same list, so
    both scripts take it from here.
    """
    runs = []
    read = []
    runs_seen = {}
    for tree in worktrees(repo, anomalies):
        runs_root = os.path.join(tree, ".kenspc", "runs")
        names = sorted(os.listdir(runs_root)) if os.path.isdir(runs_root) else []
        count = 0
        for run in names:
            run_dir = os.path.join(runs_root, run)
            if not os.path.isfile(os.path.join(run_dir, "schema-b.md")):
                continue
            if run in runs_seen:
                anomalies.append("`%s`: also in %s; the copy in %s was not read"
                                 % (run, runs_seen[run], tree))
                continue
            runs_seen[run] = tree
            count += 1
            runs.append((run, run_dir))
        read.append((tree, count))
    return runs, read


def main(argv):
    if len(argv) != 3:
        sys.stderr.write("usage: extract_findings.py <repo> <out>\n")
        return 2
    repo, out = argv[1], argv[2]
    if not os.path.isdir(repo):
        sys.stderr.write("extract_findings.py: not a directory: %s\n" % repo)
        return 2
    os.makedirs(out, exist_ok=True)
    anomalies = []
    runs, read = run_dirs(repo, anomalies)
    rows = []
    for run, run_dir in runs:
        rows.extend(parse_run(run_dir, run, anomalies))
    rows.sort(key=lambda r: (r["run"], int(r["row"])))

    with open(os.path.join(out, "findings.tsv"), "w", encoding="utf-8",
              newline="\n") as handle:
        handle.write("\t".join(COLUMNS) + "\n")
        for row in rows:
            handle.write("\t".join(tsv_cell(row[c]) for c in COLUMNS) + "\n")

    counts = ", ".join("%s %d" % (a, sum(1 for r in rows if r["action"] == a))
                       for a in ACTIONS)
    lines = ["# Extraction notes", "",
             "Findings: %d rows from %d runs (%s)." % (len(rows), len(runs),
                                                       counts),
             "", "## Worktrees read", ""]
    lines += ["- `%s`: %d run directories with a schema-b.md" % (tree, count)
              for tree, count in read]
    lines += ["", "## Anomalies (extract_findings.py)", ""]
    lines += ["- " + a for a in anomalies] if anomalies else ["none"]
    with open(os.path.join(out, "extract.md"), "w", encoding="utf-8",
              newline="\n") as handle:
        handle.write("\n".join(lines) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
