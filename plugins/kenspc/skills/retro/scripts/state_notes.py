#!/usr/bin/env python3
"""state_notes.py - the retro skill's state-file notes.

Usage
  python3 -I state_notes.py <workspace> <runs.tsv> <out>

Copies sections of each in-window autopilot batch's state file,
<workspace>/_logs/<batch>-state.md, into <out>/notes.tsv (columns batch,
section, tag, text). They are context for drafting a proposal's cause, not
ranked.

Sections copied
  - `rail observations:`, `worker lessons:`, `questions answered:`, and
    `skipped gates:`: one row per indented entry line below the heading
    (and one for text on the heading line itself); the tag is the batch's
    role tag the entry names before its first colon, empty when it names
    none, and the text is the entry as written.
  - the `merge danger:` line, one row, with `; file <path>` added when
    <workspace>/_logs/<batch>-merge-danger.md exists.
A section the file lacks gets one row whose text is `absent`, so an older
state file's missing lines read as missing rather than as an error; a batch
with no state file gets an `absent` row for every section. Free-form lines
outside these sections are ignored.

Exit codes
  0  notes.tsv was written
  2  a usage error: the wrong arguments, or an unreadable runs.tsv

Standard library only; runs on Python 3.9 or newer.
"""
import os
import re
import sys

LIST_SECTIONS = ("rail observations", "worker lessons", "questions answered",
                 "skipped gates")
MERGE_DANGER = "merge danger"
COLUMNS = ("batch", "section", "tag", "text")


def read_tsv(path):
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    header = lines[0].split("\t")
    return [dict(zip(header, line.split("\t"))) for line in lines[1:] if line]


def entry_tag(batch, entry):
    """The batch's role tag an entry names before its first colon."""
    head = entry.split(":", 1)[0]
    match = re.search(r"(?<![\w-])(" + re.escape(batch) + r"-s[\w-]*)", head)
    return match.group(1) if match else ""


def notes_of(batch, lines, merge_file):
    """Return the notes rows of one state file's lines."""
    found = {name: [] for name in LIST_SECTIONS}
    seen = set()
    merge = None
    current = None
    for line in lines:
        if line[:1].isspace():
            entry = line.strip()
            if current is not None and entry:
                found[current].append(entry)
            continue
        current = None
        name, colon, rest = line.partition(":")
        if not colon:
            continue
        name = name.strip()
        if name in LIST_SECTIONS:
            current = name
            seen.add(name)
            if rest.strip():
                found[name].append(rest.strip())
        elif name == MERGE_DANGER:
            merge = rest.strip()
    rows = []
    for name in LIST_SECTIONS:
        if name not in seen:
            rows.append((batch, name, "", "absent"))
            continue
        for entry in found[name]:
            rows.append((batch, name, entry_tag(batch, entry), entry))
    if merge is None:
        rows.append((batch, MERGE_DANGER, "", "absent"))
    else:
        if os.path.isfile(merge_file):
            merge += "; file " + merge_file
        rows.append((batch, MERGE_DANGER, "", merge))
    return rows


def main(argv):
    if len(argv) != 4:
        sys.stderr.write("usage: state_notes.py <workspace> <runs.tsv> <out>\n")
        return 2
    workspace, runs_path, out = argv[1:4]
    try:
        runs = read_tsv(runs_path)
    except (OSError, IndexError) as error:
        sys.stderr.write("state_notes.py: cannot read %s (%s)\n"
                         % (runs_path, error))
        return 2
    logs = os.path.join(workspace, "_logs")
    batches = sorted({r["batch"] for r in runs
                      if r.get("in_window") == "true"
                      and r.get("role") != "manual"})
    rows = []
    for batch in batches:
        state = os.path.join(logs, batch + "-state.md")
        lines = []
        if os.path.isfile(state):
            with open(state, encoding="utf-8", errors="replace") as handle:
                lines = handle.read().splitlines()
        rows.extend(notes_of(batch, lines,
                             os.path.join(logs, batch + "-merge-danger.md")))
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "notes.tsv"), "w", encoding="utf-8",
              newline="\n") as handle:
        handle.write("\t".join(COLUMNS) + "\n")
        for row in rows:
            handle.write("\t".join(re.sub(r"[\t\r\n]+", " ", c) for c in row)
                         + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
