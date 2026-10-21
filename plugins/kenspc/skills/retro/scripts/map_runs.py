#!/usr/bin/env python3
"""map_runs.py - the retro skill's run-to-batch mapping and window.

Usage
  python3 -I map_runs.py <repo> <workspace> <window> <out>

  <window>  one argument: `last <n>`, `since <YYYY-MM-DD>`,
            `since <YYYY-MM-DDTHH:MM:SS>`, or `all`

Maps each run directory extract_findings.py reads to an autopilot batch and
role, and marks it in or out of the window. Writes <out>/runs.tsv (columns
run, batch, role, tag, session, in_window) and appends its window and its
anomalies to <out>/extract.md, replacing what an earlier run of this script
appended there.

Mapping, for each run
  1. Candidates: the role sessions whose wall window holds the run id's
     timestamp. A session's window runs from its timeline line
     `start <tag> pid <pid> session <id> at <YYYY-MM-DD HH:MM:SS> cwd ...`
     in <workspace>/_logs/<batch>-timeline.log to the mtime of
     <workspace>/_logs/<tag>.exit, open-ended without that file. Times are
     naive local time, as the run id's is.
  2. Confirmation: the run id appears as a string in the candidate's
     <tag>.json or a resume's <tag>-r<k>.json; a candidate with no json at
     all is searched in its transcript, <session id>.jsonl under
     ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/.
  One confirmed candidate gives the tag: the batch is the tag without its
  last `-s...` part, and the role is that part without `-r<k>`. No confirmed
  candidate, or two or more, makes the run role `manual` with its run id as
  its batch; two or more are also an anomaly.

Why both conditions: nothing in a run directory names its batch, the run-id
suffix is not the role, and a json search alone is ambiguous, since a later
role of the same batch or a replay session can name an earlier run id.

Window
  A batch is in the window when its earliest run is. `last <n>` takes the n
  batches whose earliest runs are latest. `since <timestamp>` takes batches
  whose earliest run is strictly after it, so a timestamp copied from a
  retro record never counts that record's last batch again; `since <date>`
  takes batches whose earliest run is on or after that date.

Exit codes
  0  runs.tsv was written
  2  a usage error: the wrong arguments, an unreadable window, or <repo> is
     not a directory

Standard library only; runs on Python 3.9 or newer.
"""
import datetime
import glob
import importlib.util
import os
import re
import sys

RUN_TIME = re.compile(r"(\d{8}-\d{6})")
START_LINE = re.compile(
    r"start (\S+) pid \S+ session (\S+) at "
    r"(\d{4}-\d\d-\d\d \d\d:\d\d:\d\d) cwd ")
ROLE_TAG = re.compile(r"^(.+)-(s[^-]*)(?:-r\d+)?$")
SECTION = "## Window (map_runs.py)"
COLUMNS = ("run", "batch", "role", "tag", "session", "in_window")


def load_extract_findings():
    """Load extract_findings.py from beside this file, by path.

    python3 -I leaves the script's own directory off sys.path, so a plain
    import would not find it.
    """
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "extract_findings.py")
    spec = importlib.util.spec_from_file_location("extract_findings", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def parse_window(text):
    """Return (kind, value) for a window spec, or None when unreadable."""
    words = text.split()
    if words == ["all"]:
        return ("all", None)
    if len(words) == 2 and words[0] == "last" and words[1].isdigit() \
            and int(words[1]) > 0:
        return ("last", int(words[1]))
    if len(words) == 2 and words[0] == "since":
        for kind, layout in (("since-time", "%Y-%m-%dT%H:%M:%S"),
                             ("since-date", "%Y-%m-%d")):
            try:
                return (kind, datetime.datetime.strptime(words[1], layout))
            except ValueError:
                continue
    return None


def run_time(run):
    match = RUN_TIME.match(run)
    if match is None:
        return None
    try:
        return datetime.datetime.strptime(match.group(1), "%Y%m%d-%H%M%S")
    except ValueError:
        return None


def read_text(path):
    with open(path, encoding="utf-8", errors="replace") as handle:
        return handle.read()


def sessions(logs):
    """Return every role session the workspace's timelines start."""
    found = []
    for timeline in sorted(glob.glob(os.path.join(logs, "*-timeline.log"))):
        for line in read_text(timeline).splitlines():
            match = START_LINE.match(line)
            if match is None:
                continue
            tag, session, start = match.groups()
            exit_file = os.path.join(logs, tag + ".exit")
            end = None
            if os.path.exists(exit_file):
                end = datetime.datetime.fromtimestamp(
                    os.path.getmtime(exit_file))
            found.append({
                "tag": tag, "session": session, "end": end,
                "start": datetime.datetime.strptime(start, "%Y-%m-%d %H:%M:%S"),
            })
    return found


def names_run(candidate, run, logs, transcripts):
    """True when the candidate's json, or its transcript, names the run."""
    jsons = [os.path.join(logs, candidate["tag"] + ".json")]
    jsons += glob.glob(os.path.join(glob.escape(logs),
                                    glob.escape(candidate["tag"]) + "-r[0-9]*.json"))
    jsons = [j for j in jsons if os.path.isfile(j)]
    if jsons:
        return any(run in read_text(j) for j in jsons)
    pattern = os.path.join(glob.escape(transcripts), "*",
                           glob.escape(candidate["session"]) + ".jsonl")
    return any(run in read_text(t) for t in glob.glob(pattern))


def batch_and_role(tag):
    match = ROLE_TAG.match(tag)
    if match is None:
        return tag, tag
    return match.group(1), match.group(2)


def in_window(window, earliest_by_batch):
    """Return the set of batches the window holds."""
    kind, value = window
    if kind == "all":
        return set(earliest_by_batch)
    if kind == "since-time":
        return {b for b, t in earliest_by_batch.items() if t > value}
    if kind == "since-date":
        return {b for b, t in earliest_by_batch.items()
                if t.date() >= value.date()}
    latest = sorted(earliest_by_batch.items(), key=lambda bt: (bt[1], bt[0]),
                    reverse=True)
    return {b for b, _ in latest[:value]}


def write_extract(out, window_text, rows, chosen, times, anomalies, timelines):
    path = os.path.join(out, "extract.md")
    text = read_text(path) if os.path.isfile(path) else ""
    cut = text.find("\n" + SECTION)
    if cut != -1:
        text = text[:cut + 1]
    in_rows = [r for r in rows if r["batch"] in chosen]
    stamps = sorted(times[r["run"]] for r in in_rows)
    lines = [SECTION, "",
             "Window `%s`: %d batches, %d runs, %d timelines read."
             % (window_text, len(chosen), len(in_rows), timelines)]
    if stamps:
        lines.append("First run %s, last run %s."
                     % (stamps[0].strftime("%Y-%m-%dT%H:%M:%S"),
                        stamps[-1].strftime("%Y-%m-%dT%H:%M:%S")))
    lines += ["", "## Anomalies (map_runs.py)", ""]
    lines += ["- " + a for a in anomalies] if anomalies else ["none"]
    if text and not text.endswith("\n\n"):
        text += "\n" if text.endswith("\n") else "\n\n"
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text + "\n".join(lines) + "\n")
    return lines[2:4] if stamps else lines[2:3]


def main(argv):
    if len(argv) != 5:
        sys.stderr.write(
            "usage: map_runs.py <repo> <workspace> <window> <out>\n")
        return 2
    repo, workspace, window_text, out = argv[1:5]
    window = parse_window(window_text)
    if window is None:
        sys.stderr.write("map_runs.py: unreadable window %r; expected"
                         " `last <n>`, `since <YYYY-MM-DD>`,"
                         " `since <YYYY-MM-DDTHH:MM:SS>`, or `all`\n"
                         % window_text)
        return 2
    if not os.path.isdir(repo):
        sys.stderr.write("map_runs.py: not a directory: %s\n" % repo)
        return 2
    os.makedirs(out, exist_ok=True)
    logs = os.path.join(workspace, "_logs")
    transcripts = os.path.join(
        os.environ.get("CLAUDE_CONFIG_DIR")
        or os.path.join(os.path.expanduser("~"), ".claude"), "projects")
    anomalies = []
    runs, _ = load_extract_findings().run_dirs(repo, [])
    known = sessions(logs)
    timelines = len(glob.glob(os.path.join(logs, "*-timeline.log")))

    rows = []
    times = {}
    for run, _ in runs:
        stamp = run_time(run)
        if stamp is None:
            anomalies.append("`%s`: the run id holds no timestamp; it is in"
                             " no window" % run)
            continue
        times[run] = stamp
        candidates = [s for s in known if s["start"] <= stamp
                      and (s["end"] is None or stamp <= s["end"])]
        hits = [s for s in candidates
                if names_run(s, run, logs, transcripts)]
        if len(hits) == 1:
            batch, role = batch_and_role(hits[0]["tag"])
            rows.append({"run": run, "batch": batch, "role": role,
                         "tag": hits[0]["tag"],
                         "session": hits[0]["session"]})
            continue
        if len(hits) > 1:
            anomalies.append("`%s`: named by %d candidate sessions (%s); mapped"
                             " as manual" % (run, len(hits),
                                             ", ".join(h["tag"] for h in hits)))
        rows.append({"run": run, "batch": run, "role": "manual", "tag": "",
                     "session": ""})

    rows.sort(key=lambda r: r["run"])
    earliest = {}
    for row in rows:
        stamp = times[row["run"]]
        if row["batch"] not in earliest or stamp < earliest[row["batch"]]:
            earliest[row["batch"]] = stamp
    chosen = in_window(window, earliest)

    with open(os.path.join(out, "runs.tsv"), "w", encoding="utf-8",
              newline="\n") as handle:
        handle.write("\t".join(COLUMNS) + "\n")
        for row in rows:
            row["in_window"] = "true" if row["batch"] in chosen else "false"
            handle.write("\t".join(row[c] for c in COLUMNS) + "\n")
    for line in write_extract(out, window_text, rows, chosen, times,
                              anomalies, timelines):
        print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
