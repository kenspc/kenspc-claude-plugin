#!/usr/bin/env python3
"""measure_time.py - the retro skill's time measurement.

Usage
  python3 -I measure_time.py <workspace> <runs.tsv> <out>

Measures every role session of each autopilot batch runs.tsv marks in the
window: every session with a `start` line in
<workspace>/_logs/<batch>-timeline.log, roles that wrote no run directory
included. Writes <out>/time.tsv (columns batch, role, kind, minutes, status)
and appends a coverage line to <out>/extract.md.

Rows
  - kind `wall`: a role's wall minutes, from each session's timeline
    `start <tag> ... at <time>` to the mtime of <tag>.exit, its resumes
    (<tag>-r<k>, each its own start line) summed into the role. A session
    that ended on a usage limit is measured to its .exit only, so the pause
    before its resume is never counted. A role with a session that has no
    .exit has status `unmeasured` and no minutes: it has no end on the
    clock, and an estimate would read as a measurement.
  - inside the s3 and s3b roles, one row per subagent kind (the
    `agentType` of each <session id>/subagents/*.meta.json under
    ${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/): the union of the spans
    from each subagent transcript's first to its last `timestamp`, never
    their sum, since parallel subagents overlap. Each span is cut to the
    role's session windows first, so a subagent that resumed with its
    session after a usage-limit pause does not count the pause either. Kind
    `other` is the role's wall minutes minus the union of all its spans. A role whose session has
    no transcript left (Claude Code prunes old ones) gets one `other` row,
    status `unmeasured`, and keeps its `wall` row.

`duration_ms` is never used: it counts API time, not the clock, and one S3
read 83 minutes there against 3.5 hours on the clock.

Exit codes
  0  time.tsv was written
  2  a usage error: the wrong arguments, or an unreadable runs.tsv

Standard library only; runs on Python 3.9 or newer.
"""
import datetime
import glob
import importlib.util
import json
import os
import sys

SPLIT_ROLES = ("s3", "s3b")
COLUMNS = ("batch", "role", "kind", "minutes", "status")
SECONDS_PER_MINUTE = 60.0


def load_map_runs():
    """Load map_runs.py from beside this file, by path (python3 -I)."""
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "map_runs.py")
    spec = importlib.util.spec_from_file_location("map_runs", path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def read_tsv(path):
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    header = lines[0].split("\t")
    return [dict(zip(header, line.split("\t"))) for line in lines[1:] if line]


def union_seconds(spans):
    """Total length of the union of (start, end) spans, in seconds."""
    total, end = 0.0, None
    for first, last in sorted(spans):
        if end is None or first > end:
            total += last - first
            end = last
        elif last > end:
            total += last - end
            end = last
    return total


def stamp_seconds(text):
    return datetime.datetime.fromisoformat(
        text.replace("Z", "+00:00")).timestamp()


def transcript_span(path):
    """Return (first, last) transcript timestamps in seconds, or None."""
    first = last = None
    with open(path, encoding="utf-8", errors="replace") as handle:
        for line in handle:
            try:
                stamp = json.loads(line).get("timestamp")
            except (ValueError, AttributeError):
                continue
            if not isinstance(stamp, str):
                continue
            try:
                seconds = stamp_seconds(stamp)
            except ValueError:
                continue
            first = seconds if first is None else first
            last = seconds
    return None if first is None else (first, last)


def subagent_spans(projects, session):
    """Return {kind: [spans]} for a session, or None with no transcript."""
    root = os.path.join(glob.escape(projects), "*")
    sid = glob.escape(session)
    if not (glob.glob(os.path.join(root, sid + ".jsonl"))
            or glob.glob(os.path.join(root, sid, ""))):
        return None
    spans = {}
    for meta in sorted(glob.glob(os.path.join(root, sid, "subagents",
                                              "*.meta.json"))):
        transcript = meta[:-len(".meta.json")] + ".jsonl"
        if not os.path.isfile(transcript):
            continue
        try:
            with open(meta, encoding="utf-8") as handle:
                kind = json.load(handle).get("agentType") or "unknown"
        except (ValueError, AttributeError):
            kind = "unknown"
        span = transcript_span(transcript)
        if span is not None:
            spans.setdefault(kind, []).append(span)
    return spans


def clip(spans, windows):
    """Cut each span to the session windows; return the pieces inside."""
    pieces = []
    for first, last in spans:
        for start, end in windows:
            low, high = max(first, start), min(last, end)
            if low < high:
                pieces.append((low, high))
    return pieces


def minutes(seconds):
    return "%.1f" % (seconds / SECONDS_PER_MINUTE)


def main(argv):
    if len(argv) != 4:
        sys.stderr.write("usage: measure_time.py <workspace> <runs.tsv> <out>\n")
        return 2
    workspace, runs_path, out = argv[1:4]
    try:
        runs = read_tsv(runs_path)
    except (OSError, IndexError) as error:
        sys.stderr.write("measure_time.py: cannot read %s (%s)\n"
                         % (runs_path, error))
        return 2
    map_runs = load_map_runs()
    logs = os.path.join(workspace, "_logs")
    projects = os.path.join(
        os.environ.get("CLAUDE_CONFIG_DIR")
        or os.path.join(os.path.expanduser("~"), ".claude"), "projects")
    batches = sorted({r["batch"] for r in runs
                      if r.get("in_window") == "true"
                      and r.get("role") != "manual"})

    rows = []
    read = no_exit = split_unmeasured = 0
    timelines = 0
    for batch in batches:
        timeline = os.path.join(logs, batch + "-timeline.log")
        if not os.path.isfile(timeline):
            continue
        timelines += 1
        roles = {}
        for line in map_runs.read_text(timeline).splitlines():
            match = map_runs.START_LINE.match(line)
            if match is None:
                continue
            tag, session, start = match.groups()
            role = map_runs.batch_and_role(tag)[1]
            roles.setdefault(role, []).append((
                tag, session,
                datetime.datetime.strptime(start, "%Y-%m-%d %H:%M:%S")))
        for role in sorted(roles):
            sessions = roles[role]
            read += len(sessions)
            wall = 0.0
            measured = True
            windows = []
            for tag, _, start in sessions:
                exit_file = os.path.join(logs, tag + ".exit")
                if not os.path.exists(exit_file):
                    measured = False
                    no_exit += 1
                    windows.append((start.timestamp(), float("inf")))
                    continue
                end = os.path.getmtime(exit_file)
                windows.append((start.timestamp(), end))
                wall += end - start.timestamp()
            rows.append((batch, role, "wall",
                         minutes(wall) if measured else "",
                         "measured" if measured else "unmeasured"))
            if role not in SPLIT_ROLES:
                continue
            kinds = {}
            pruned = False
            for session in sorted({s for _, s, _ in sessions}):
                spans = subagent_spans(projects, session)
                if spans is None:
                    pruned = True
                    break
                for kind, found in spans.items():
                    kinds.setdefault(kind, []).extend(clip(found, windows))
            if pruned:
                split_unmeasured += len(sessions)
                rows.append((batch, role, "other", "", "unmeasured"))
                continue
            for kind in sorted(kinds):
                rows.append((batch, role, kind,
                             minutes(union_seconds(kinds[kind])), "measured"))
            if measured:
                every = [s for found in kinds.values() for s in found]
                rows.append((batch, role, "other",
                             minutes(wall - union_seconds(every)), "measured"))
            else:
                rows.append((batch, role, "other", "", "unmeasured"))

    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "time.tsv"), "w", encoding="utf-8",
              newline="\n") as handle:
        handle.write("\t".join(COLUMNS) + "\n")
        for row in rows:
            handle.write("\t".join(row) + "\n")

    if timelines == 0:
        line = ("Coverage (measure_time.py): no in-window batch has a timeline"
                " (no autopilot batches), so the time list is empty.")
    else:
        line = ("Coverage (measure_time.py): %d batches with a timeline, %d"
                " role sessions read, %d with an unmeasured subagent split,"
                " %d with no .exit." % (timelines, read, split_unmeasured,
                                        no_exit))
    with open(os.path.join(out, "extract.md"), "a", encoding="utf-8",
              newline="\n") as handle:
        handle.write("\n" + line + "\n")
    print(line)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
