#!/usr/bin/env bash
# check-retro-scripts.sh
#
# Behavior guard for the python3 scripts the retro skill ships in
# plugins/kenspc/skills/retro/scripts/:
#
#   1. extract_findings.py  every Schema B row of a repository's review runs,
#                           joined to its angle row, into findings.tsv, with
#                           the anomalies in extract.md
#   2. map_runs.py          each run directory's batch and role, from the
#                           autopilot workspace's logs, and the window, into
#                           runs.tsv
#   3. measure_time.py      each in-window batch's role wall minutes and the
#                           S3/S3b subagent split, into time.tsv, with a
#                           coverage line in extract.md
#   4. state_notes.py       sections of each batch's state file, into
#                           notes.tsv
#   5. slice_findings.py    the classifier's inputs: sample.tsv, slice-<n>.tsv,
#                           and kinds.tsv from a previous record
#   6. rank.py              the ranked findings and time lists, the selection,
#                           and the previous record's follow-up, into rank.md
#   7. show_rows.py         chosen findings printed in full
#
# It runs each script on the fixtures under scripts/fixtures/retro/ and diffs
# each output against the expected file there. The fixture repository is
# copied into a mktemp -d directory (the fixture tree keeps its run
# directories under runs/, since .kenspc/ is git-ignored), made a git
# repository with one worktree, and the fixture's worktree runs are copied
# into that worktree. The fixtures hold an angle row whose description holds
# `\|` and one whose code span holds `||`, a schema-b row whose Action is
# `DEFERRED — ruled`, a schema-b whose stats line disagrees with its rows by
# one, a row sourced F1 and one sourced V1, columns in another order, a
# missing angle file, a Source ID with no angle row, a row with one cell too
# many, a `#` cell that is not a number, unreadable Source IDs, a table
# header that lacks columns, a schema-b with no stats line, a run directory
# with no schema-b.md, and a run id present in both the repository and the
# worktree. A second extraction runs on a copy that is not a git repository,
# where the failed worktree list must be named in extract.md.
#
# The mapping fixtures, a workspace's _logs and a transcript tree under
# claude-config/ (read through CLAUDE_CONFIG_DIR), hold a run id named in two
# sessions' jsons, only one of whose windows holds it; a run whose only
# candidate's json is empty (a worker that died before printing), but whose
# transcript names it; a run named by two
# candidates' jsons, one with no .exit (open-ended), beside a third candidate
# whose json does not name it and whose transcript, never searched, does
# (manual, an anomaly); a resume's json (role without -r<k>); a run with no
# candidate (manual); a run id with no timestamp; and windows `last 2`,
# `all`, `since <timestamp>` equal to a batch's earliest run (out), `since
# <date>` after a batch's earliest run but on a later run's date (out),
# `since <date>` on a batch's earliest run's date (in), and unreadable
# windows. `last 2` and then `all` run into one directory, whose
# extract.md must hold a single window section. The .exit files get their
# mtimes from workspace/exit-times.txt with touch -t, since git keeps none.
#
# The time fixtures hold a role with a resume after a usage-limit .json (its
# pause not counted, and a subagent span across the pause cut to the two
# session windows), a session with no .exit (its role unmeasured), two
# overlapping subagent spans of one kind (united, never summed), a
# meta.json whose transcript is gone, transcript lines that are not json or
# carry no timestamp, an S3b session with a transcript but no subagents, an
# S3b session with no transcript (split unmeasured), and a window whose
# batches are all manual (the coverage line says the time list is empty).
# The state files are one in the current shape, with a `merge danger:` line
# and its file, and one in the old free-form shape: `Note:` lines, a
# heading with its text on the same line, an entry naming no tag, and no
# `skipped gates:` or `merge danger:` line. The guard runs with TZ=UTC,
# since transcript timestamps are UTC and the timelines local time.
#
# The ranking fixture (rank/, a retro directory's inputs) holds an S3/S3b
# pair on one file and kind with the S3 row DEFERRED (merged), a same-file
# pair of different kinds and a same-file, same-kind pair whose S3 row is
# FIXED (neither merged), a kind in one batch only and `other` (not
# ranked), a kind whose batches include a manual run (marked), `new:`
# labels resolved through new-kinds.tsv to a kind and to `other` (names
# written with and without `new:`) and one it does not list, an unlabelled
# row, labels outside the window, a duplicate label, an unmeasured time row,
# and a time item in one batch. A generated three-row case pairs a DEFERRED s3
# row with an s3b row on its file and kind in another batch (kept); another,
# with no time.tsv and five kinds in two batches, passes the time list's slots
# to findings (five selected). Without a record, three findings items and two
# time items are selected and the next time item, exactly 10% below the last
# selected, is a runner-up. With record.md (the fixture record, whose lines
# the retro skill's record grammar matches and one of whose Kinds definitions
# holds `\|`, copied whole into kinds.tsv), the rejected kind whose batch
# count has not grown is skipped, so findings pass a slot to time, and the
# next time item, 10.1% below, is not a runner-up; the rejected kind whose
# count grew is marked and kept, the adopted kind and time measures print then
# and now, and the Pending and Failed sections' lines are not read; with the
# adopted time item's rows unmeasured, its now reads `not measured in this
# window`. A generated fixture of 403 rows checks the slice size at the limit
# and past it and the proportional, seeded 200-row sample, where a one-row
# batch gets a row only from the rule that every batch gets at least one. The
# record grammar's line forms the scripts read are looked up verbatim in the
# skill's SKILL.md and, filled in, matched with rank.py's patterns.
# The temp directory's path is written `<work>` before each diff.
#
# Exit code 0: every output matched its expected file.
# Exit code 1: an output differed (the diff is printed), or a self-test
#              mutant passed.
# Exit code 2: python3 is not on PATH, a script, fixture, or SKILL.md is
#              missing, or a self-test mutation did not apply (the
#              fixture is stale).
#              A missing python3 is never a pass: a guard that silently did
#              not run would read as one, as check-instruction-lint.sh treats
#              a missing pwsh.
#
# Optional flag:
#   --self-test    Copies the scripts into the temp directory, checks that
#                  the unmutated copies pass, then turns the guard red with
#                  each mutant of the copies — the unescaped-pipe split
#                  replaced with a plain split on `|`, and the span union
#                  replaced with a sum — which must fail. It
#                  also runs this guard with PATH set to an empty directory,
#                  which must exit 2.
#
# Runs under the bash 3.2 macOS ships. The only recursive rm is the EXIT
# trap's removal of the guard's own mktemp directory. Git runs with the
# global and system configuration masked, so a user's signing or hook
# setting cannot change a fixture commit.

set -euo pipefail

if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: python3 not found, so the retro scripts cannot be checked" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS="$REPO_ROOT/plugins/kenspc/skills/retro/scripts"
FIXTURES="$SCRIPT_DIR/fixtures/retro"
SKILL="$REPO_ROOT/plugins/kenspc/skills/retro/SKILL.md"
SCRIPT_NAMES="extract_findings.py map_runs.py measure_time.py state_notes.py
slice_findings.py rank.py show_rows.py"

for name in $SCRIPT_NAMES; do
    if [[ ! -f "$SCRIPTS/$name" ]]; then
        echo "ERROR: missing script $SCRIPTS/$name" >&2
        exit 2
    fi
done
for dir in repo/runs worktree-runs workspace/_logs claude-config rank expected; do
    if [[ ! -d "$FIXTURES/$dir" ]]; then
        echo "ERROR: missing fixture directory $FIXTURES/$dir" >&2
        exit 2
    fi
done
if [[ ! -f "$FIXTURES/record.md" ]]; then
    echo "ERROR: missing fixture record $FIXTURES/record.md" >&2
    exit 2
fi
if [[ ! -f "$SKILL" ]]; then
    echo "ERROR: missing skill file $SKILL" >&2
    exit 2
fi

WORK=""
cleanup() {
    if [[ -n "$WORK" ]]; then
        rm -rf "$WORK"
    fi
}
trap cleanup EXIT
# Assigned alone, so a failed mktemp stops the script under set -e instead
# of leaving WORK as the current directory for the trap to remove.
WORK="$(mktemp -d)"
WORK="$(cd "$WORK" && pwd -P)"

export HOME="$WORK/home" XDG_CONFIG_HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
# Transcript timestamps are UTC, while timelines and the .exit mtimes set
# below are local time; UTC as the local zone keeps the fixture's minutes
# the same in every zone.
export TZ=UTC

# The large slicing fixture: 403 in-window rows in batches of 400, 1, 1,
# and 1 rows, plus 5 rows of a batch outside the window. The one-row
# batches' shares of a 200-row sample are below one, so one of them gets a
# row only from the rule that every batch gets at least one. Generated,
# since 403 hand-written rows would hide what the case is about.
BIG="$WORK/big"
mkdir -p "$BIG"
python3 -I -c '
import os, sys
out = sys.argv[1]
batches = [("b1", 400, "true"), ("b2", 1, "true"), ("b3", 1, "true"),
           ("b4", 1, "true"), ("old", 5, "false")]
with open(os.path.join(out, "runs.tsv"), "w") as runs, \
        open(os.path.join(out, "findings.tsv"), "w") as findings:
    runs.write("run\tbatch\trole\ttag\tsession\tin_window\n")
    findings.write("key\trun\trow\tsources\tseverity\taction\tfile"
                   "\tshort_label\tdescription\n")
    for day, (batch, rows, inside) in enumerate(batches, 1):
        run = "202610%02d-100000-%s-tasks" % (day, batch)
        runs.write("\t".join([run, batch, "s3", batch + "-s3", "s", inside])
                   + "\n")
        for row in range(1, rows + 1):
            findings.write("\t".join(["%s#%d" % (run, row), run, str(row),
                                       "T1", "LOW", "FIXED", "src/a.ts:1",
                                       "label", "description"]) + "\n")
' "$BIG"

git_q() {
    git -c user.name=fixture -c user.email=fixture@example.invalid \
        -c commit.gpgsign=false "$@" >/dev/null 2>&1
}

# --- Fixture setup --------------------------------------------------------------

# The repository: its runs, a git repository with one commit, and a worktree
# holding the worktree runs.
REPO="$WORK/repo"
mkdir -p "$REPO/.kenspc"
cp -R "$FIXTURES/repo/runs" "$REPO/.kenspc/runs"
git_q init -q "$REPO"
git_q -C "$REPO" commit -q --allow-empty -m init
git_q -C "$REPO" worktree add -q "$WORK/wt"
mkdir -p "$WORK/wt/.kenspc"
cp -R "$FIXTURES/worktree-runs" "$WORK/wt/.kenspc/runs"

# The same runs outside any git repository.
NOGIT="$WORK/nogit"
mkdir -p "$NOGIT/.kenspc"
cp -R "$FIXTURES/repo/runs" "$NOGIT/.kenspc/runs"

# The autopilot workspace: its logs, each .exit given the mtime
# workspace/exit-times.txt lists (local time, as the timelines are), since
# git keeps no mtime. Transcripts are read from the fixture's config dir.
WS="$WORK/workspace"
cp -R "$FIXTURES/workspace" "$WS"
while read -r exit_name exit_time; do
    [[ -z "$exit_name" ]] && continue
    touch -t "$exit_time" "$WS/_logs/$exit_name"
done < "$FIXTURES/workspace/exit-times.txt"
export CLAUDE_CONFIG_DIR="$FIXTURES/claude-config"

# --- Cases -----------------------------------------------------------------------

# Diff one output file against its expected file, the temp path written
# `<work>`. Prints the diff and returns 1 on a difference.
compare() {
    local actual="$1" expected="$2" label="$3" normalized
    normalized="$actual.normalized"
    if [[ ! -f "$actual" ]]; then
        echo "FAIL  $label: $actual was not written" >&2
        return 1
    fi
    WORK_PATH="$WORK" python3 -I -c '
import os, sys
text = open(sys.argv[1], encoding="utf-8").read()
open(sys.argv[2], "w", encoding="utf-8").write(
    text.replace(os.environ["WORK_PATH"], "<work>"))
' "$actual" "$normalized"
    if ! diff -u "$expected" "$normalized" >&2; then
        echo "FAIL  $label: output differs from $expected" >&2
        return 1
    fi
    echo "OK    $label"
}

# A usage error must exit 2.
expect_usage() {
    local rc="$1" label="$2"
    if [[ "$rc" -ne 2 ]]; then
        echo "FAIL  $label: exited $rc, expected 2" >&2
        return 1
    fi
    echo "OK    $label"
}

# Run one script, which must exit 0.
run_ok() {
    local label="$1" rc
    shift
    python3 -I "$@" >/dev/null && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  $label: exited $rc" >&2
        return 1
    fi
}

# Run every case against the scripts in $1, writing under $2. Returns 1 when
# any case failed.
run_cases() {
    local scripts="$1" out="$2" fail=0 rc
    mkdir -p "$out"

    python3 -I "$scripts/extract_findings.py" "$REPO" "$out/extract" \
        && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  extract: exited $rc" >&2
        fail=1
    else
        compare "$out/extract/findings.tsv" \
            "$FIXTURES/expected/extract/findings.tsv" "extract findings.tsv" || fail=1
        compare "$out/extract/extract.md" \
            "$FIXTURES/expected/extract/extract.md" "extract extract.md" || fail=1
    fi

    python3 -I "$scripts/extract_findings.py" "$NOGIT" "$out/extract-nogit" \
        && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  extract outside git: exited $rc" >&2
        fail=1
    elif ! grep -q '^- git worktree list failed (' "$out/extract-nogit/extract.md"; then
        echo "FAIL  extract outside git: extract.md does not name the failed worktree list" >&2
        fail=1
    elif ! grep -q '^- `<work>/nogit`: 3 run directories' <(sed "s|$WORK|<work>|g" "$out/extract-nogit/extract.md"); then
        echo "FAIL  extract outside git: the repository's own runs were not read" >&2
        fail=1
    else
        echo "OK    extract outside git"
    fi

    python3 -I "$scripts/extract_findings.py" "$REPO" >/dev/null 2>&1 \
        && rc=0 || rc=$?
    expect_usage "$rc" "extract with one argument" || fail=1
    python3 -I "$scripts/extract_findings.py" "$WORK/absent" "$out/x" \
        >/dev/null 2>&1 && rc=0 || rc=$?
    expect_usage "$rc" "extract on a missing repository" || fail=1

    # map_runs.py: `last 2`, then `all` into the same directory, whose
    # extract.md must then hold one window section; each `since` form apart.
    local map="$out/map" window
    mkdir -p "$map"
    cp "$out/extract/extract.md" "$map/extract.md"
    if run_ok "map last 2" "$scripts/map_runs.py" "$REPO" "$WS" "last 2" "$map"; then
        compare "$map/runs.tsv" "$FIXTURES/expected/map/runs-last-2.tsv" \
            "map last 2 runs.tsv" || fail=1
    else
        fail=1
    fi
    if run_ok "map all" "$scripts/map_runs.py" "$REPO" "$WS" "all" "$map"; then
        compare "$map/runs.tsv" "$FIXTURES/expected/map/runs-all.tsv" \
            "map all runs.tsv" || fail=1
        compare "$map/extract.md" "$FIXTURES/expected/map/extract.md" \
            "map all extract.md" || fail=1
    else
        fail=1
    fi
    # A batch whose earliest run equals the timestamp is out of the window;
    # one whose earliest run falls on the date is in it.
    local pair name
    for pair in "since-time|since 2026-10-04T12:00:00" "since-date|since 2026-10-02"; do
        name="${pair%%|*}"
        window="${pair#*|}"
        mkdir -p "$out/map-$name"
        if run_ok "map $window" "$scripts/map_runs.py" "$REPO" "$WS" "$window" \
                "$out/map-$name"; then
            compare "$out/map-$name/runs.tsv" \
                "$FIXTURES/expected/map/runs-$name.tsv" \
                "map $window runs.tsv" || fail=1
        else
            fail=1
        fi
    done
    # `since <date>` is inclusive: bat3, whose earliest run is on that date,
    # is in the window, as with `since 2026-10-02`.
    mkdir -p "$out/map-since-batch-date"
    if run_ok "map since 2026-10-04" "$scripts/map_runs.py" "$REPO" "$WS" \
            "since 2026-10-04" "$out/map-since-batch-date"; then
        compare "$out/map-since-batch-date/runs.tsv" \
            "$FIXTURES/expected/map/runs-since-date.tsv" \
            "map since 2026-10-04 runs.tsv" || fail=1
    else
        fail=1
    fi
    for window in "last 0" "since 2026-13-01" "some"; do
        python3 -I "$scripts/map_runs.py" "$REPO" "$WS" "$window" "$out/x" \
            >/dev/null 2>&1 && rc=0 || rc=$?
        expect_usage "$rc" "map with window '$window'" || fail=1
    done
    python3 -I "$scripts/map_runs.py" "$REPO" "$WS" "all" >/dev/null 2>&1 \
        && rc=0 || rc=$?
    expect_usage "$rc" "map with three arguments" || fail=1

    # measure_time.py and state_notes.py on the `all` window, then
    # measure_time.py on `last 2`, whose batches are all manual.
    local timed="$out/time" script
    mkdir -p "$timed" "$out/time-manual"
    cp "$map/runs.tsv" "$map/extract.md" "$timed/"
    if run_ok "time all" "$scripts/measure_time.py" "$WS" "$timed/runs.tsv" "$timed"; then
        compare "$timed/time.tsv" "$FIXTURES/expected/time/time.tsv" \
            "time all time.tsv" || fail=1
        compare "$timed/extract.md" "$FIXTURES/expected/time/extract.md" \
            "time all extract.md" || fail=1
    else
        fail=1
    fi
    cp "$FIXTURES/expected/map/runs-last-2.tsv" "$out/time-manual/runs.tsv"
    if run_ok "time manual only" "$scripts/measure_time.py" "$WS" \
            "$out/time-manual/runs.tsv" "$out/time-manual"; then
        compare "$out/time-manual/time.tsv" \
            "$FIXTURES/expected/time/time-manual.tsv" "time manual only time.tsv" || fail=1
        compare "$out/time-manual/extract.md" \
            "$FIXTURES/expected/time/extract-manual.md" "time manual only extract.md" || fail=1
    else
        fail=1
    fi
    if run_ok "notes all" "$scripts/state_notes.py" "$WS" "$timed/runs.tsv" "$timed"; then
        compare "$timed/notes.tsv" "$FIXTURES/expected/time/notes.tsv" \
            "notes all notes.tsv" || fail=1
    else
        fail=1
    fi
    # slice_findings.py and rank.py on the ranking fixture, without and with
    # the fixture record; show_rows.py on two of its keys.
    local plain="$out/rank-plain" recorded="$out/rank-record"
    mkdir -p "$plain" "$recorded"
    cp "$FIXTURES/rank/"* "$plain/"
    cp "$FIXTURES/rank/"* "$recorded/"
    if run_ok "slice" "$scripts/slice_findings.py" "$plain"; then
        compare "$plain/slice-1.tsv" "$FIXTURES/expected/rank/slice-1.tsv" \
            "slice slice-1.tsv" || fail=1
        compare "$plain/sample.tsv" "$FIXTURES/expected/rank/sample.tsv" \
            "slice sample.tsv" || fail=1
    else
        fail=1
    fi
    if run_ok "slice with a record" "$scripts/slice_findings.py" "$recorded" \
            "$FIXTURES/record.md"; then
        compare "$recorded/kinds.tsv" "$FIXTURES/expected/rank/kinds.tsv" \
            "slice with a record kinds.tsv" || fail=1
        if [[ -e "$recorded/sample.tsv" ]]; then
            echo "FAIL  slice with a record: wrote sample.tsv" >&2
            fail=1
        else
            echo "OK    slice with a record writes no sample.tsv"
        fi
    else
        fail=1
    fi
    if run_ok "rank" "$scripts/rank.py" "$plain"; then
        compare "$plain/rank.md" "$FIXTURES/expected/rank/rank.md" \
            "rank rank.md" || fail=1
    else
        fail=1
    fi
    if run_ok "rank with a record" "$scripts/rank.py" "$recorded" \
            "$FIXTURES/record.md"; then
        compare "$recorded/rank.md" "$FIXTURES/expected/rank/rank-record.md" \
            "rank with a record rank.md" || fail=1
    else
        fail=1
    fi
    # The adopted time item with no measured row in this window: its "now"
    # is no number, since an unmeasured session is not zero minutes.
    local unmeasured="$out/rank-unmeasured"
    mkdir -p "$unmeasured"
    cp "$FIXTURES/rank/"* "$unmeasured/"
    awk 'BEGIN { FS = OFS = "\t" } $2 == "s2" { $4 = ""; $5 = "unmeasured" } 1' \
        "$FIXTURES/rank/time.tsv" > "$unmeasured/time.tsv"
    if run_ok "rank with an unmeasured adopted time item" "$scripts/rank.py" \
            "$unmeasured" "$FIXTURES/record.md"; then
        if grep -qxF '| time `s2` | minutes per batch | 12.0 | not measured in this window |' \
                "$unmeasured/rank.md"; then
            echo "OK    rank with an unmeasured adopted time item"
        else
            echo "FAIL  rank with an unmeasured adopted time item: its follow-up line is not 'not measured in this window'" >&2
            fail=1
        fi
    else
        fail=1
    fi
    # The S3/S3b merge holds within one batch: b2's s3b row on the file and
    # kind of b1's DEFERRED s3 row is kept, so test-gap ranks in two batches.
    local across="$out/rank-across"
    mkdir -p "$across"
    printf '%s\n' "run	batch	role	tag	session	in_window" \
        "20261001-100000-b1-tasks	b1	s3	b1-s3	s1	true" \
        "20261001-120000-changes	b1	s3b	b1-s3b	s2	true" \
        "20261002-120000-changes	b2	s3b	b2-s3b	s3	true" > "$across/runs.tsv"
    printf '%s\n' "key	run	row	sources	severity	action	file	short_label	description" \
        "20261001-100000-b1-tasks#1	20261001-100000-b1-tasks	1	T1	MEDIUM	DEFERRED	src/a.ts:1	label 1	description 1" \
        "20261002-120000-changes#1	20261002-120000-changes	1	T1	LOW	FIXED	src/a.ts:5	label 2	description 2" \
        > "$across/findings.tsv"
    printf '%s\n' "key	kind" "20261001-100000-b1-tasks#1	test-gap" \
        "20261002-120000-changes#1	test-gap" > "$across/labels-1.tsv"
    if run_ok "rank across batches" "$scripts/rank.py" "$across"; then
        if grep -qxF '| 1 | test-gap | 3 | 2 | 2 |  | yes |  |' "$across/rank.md"; then
            echo "OK    rank keeps an s3b row whose s3 twin is in another batch"
        else
            echo "FAIL  rank across batches: test-gap is not ranked with 2 rows in 2 batches" >&2
            fail=1
        fi
    else
        fail=1
    fi
    # With no time.tsv the time list is empty, so its two slots pass to the
    # findings list: five kinds in two batches give five findings items.
    local notime="$out/rank-no-time" k b
    mkdir -p "$notime"
    printf '%s\n' "run	batch	role	tag	session	in_window" \
        "20261001-100000-b1-tasks	b1	s3	b1-s3	s1	true" \
        "20261002-100000-b2-tasks	b2	s3	b2-s3	s2	true" > "$notime/runs.tsv"
    printf '%s\n' "key	run	row	sources	severity	action	file	short_label	description" \
        > "$notime/findings.tsv"
    printf '%s\n' "key	kind" > "$notime/labels-1.tsv"
    for b in 1 2; do
        for k in 1 2 3 4 5; do
            printf '%s\n' "2026100$b-100000-b$b-tasks#$k	2026100$b-100000-b$b-tasks	$k	T1	LOW	FIXED	src/k$k.ts:1	label	description" \
                >> "$notime/findings.tsv"
            printf '%s\n' "2026100$b-100000-b$b-tasks#$k	kind-$k" >> "$notime/labels-1.tsv"
        done
    done
    if run_ok "rank with no time list" "$scripts/rank.py" "$notime"; then
        if [[ "$(grep -c '^[0-9]\. findings ' "$notime/rank.md")" -eq 5 ]]; then
            echo "OK    rank with no time list selects five findings items"
        else
            echo "FAIL  rank with no time list: the time list's slots did not pass to findings" >&2
            fail=1
        fi
    else
        fail=1
    fi
    python3 -I "$scripts/show_rows.py" "$plain" '20261001-100000-b1-tasks#3' \
        '20261004-100000-changes#1' > "$out/show-rows.txt" && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  show rows: exited $rc" >&2
        fail=1
    else
        compare "$out/show-rows.txt" "$FIXTURES/expected/rank/show-rows.txt" \
            "show rows" || fail=1
    fi
    python3 -I "$scripts/show_rows.py" "$plain" 'absent#1' >/dev/null 2>&1 \
        && rc=0 || rc=$?
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  show rows of an absent key: exited $rc, expected 1" >&2
        fail=1
    else
        echo "OK    show rows of an absent key"
    fi

    # The large fixture: slices of 120, 120, 120, and 43 rows (the limit, and
    # one past it), and a 200-row sample split 197 / 1 / 1 / 1 by batch, the
    # same on a second run.
    local big="$out/big" again="$out/big-again"
    mkdir -p "$big" "$again"
    cp "$BIG/"* "$big/"
    cp "$BIG/"* "$again/"
    if run_ok "slice large" "$scripts/slice_findings.py" "$big" \
            && run_ok "slice large again" "$scripts/slice_findings.py" "$again"; then
        if python3 -I -c '
import os, sys
big, again = sys.argv[1:3]
def rows(name, where=big):
    path = os.path.join(where, name)
    if not os.path.exists(path):
        return None
    return open(path).read().splitlines()[1:]
sizes = [len(rows("slice-%d.tsv" % n)) for n in (1, 2, 3, 4)]
problems = []
if sizes != [120, 120, 120, 43] or rows("slice-5.tsv") is not None:
    problems.append("slice sizes %s" % sizes)
counts = {}
for line in rows("sample.tsv"):
    batch = line.split("	")[0].split("-")[2]
    counts[batch] = counts.get(batch, 0) + 1
if counts != {"b1": 197, "b2": 1, "b3": 1, "b4": 1}:
    problems.append("sample by batch %s" % counts)
if len(set(rows("sample.tsv"))) != 200:
    problems.append("sample rows not 200 distinct")
if rows("sample.tsv") != rows("sample.tsv", again):
    problems.append("a second run drew another sample")
if problems:
    sys.stderr.write("; ".join(problems) + "\n")
    sys.exit(1)
' "$big" "$again"; then
            echo "OK    slice large: 120, 120, 120, 43 rows; sample 197/1/1/1, seeded"
        else
            echo "FAIL  slice large" >&2
            fail=1
        fi
    else
        fail=1
    fi

    # The record grammar in SKILL.md and rank.py's parser: each line form the
    # skill lists for the scripts appears there verbatim and, filled in,
    # matches the pattern rank.py reads it with.
    if python3 -I -c '
import importlib.util, sys
skill, rank_path = sys.argv[1:3]
spec = importlib.util.spec_from_file_location("rank", rank_path)
rank = importlib.util.module_from_spec(spec)
spec.loader.exec_module(rank)
text = open(skill, encoding="utf-8").read()
forms = [
    ("Window: <YYYY-MM-DDTHH:MM:SS> to <YYYY-MM-DDTHH:MM:SS>", rank.WINDOW_LINE),
    ("- Measure: kind `<kind>` cost = <n>", rank.MEASURE_LINE),
    ("- Measure: time `<item>` minutes per batch = <n>", rank.MEASURE_LINE),
    ("- Batches: kind `<kind>` = <n>", rank.BATCHES_LINE),
    ("- Batches: time `<item>` = <n>", rank.BATCHES_LINE),
]
problems = []
for form, pattern in forms:
    if form not in text:
        problems.append("SKILL.md lacks %r" % form)
    filled = (form.replace("<YYYY-MM-DDTHH:MM:SS>", "2026-10-01T10:00:00")
              .replace("<kind>", "test-gap").replace("<item>", "s3")
              .replace("<n>", "3"))
    if not pattern.match(filled):
        problems.append("rank.py does not read %r" % filled)
if "| kind | definition |" not in text or "\n## Kinds\n" not in text:
    problems.append("SKILL.md lacks the ## Kinds table header")
if problems:
    sys.stderr.write("; ".join(problems) + "\n")
    sys.exit(1)
' "$SKILL" "$scripts/rank.py"; then
        echo "OK    record grammar: SKILL.md line forms match rank.py"
    else
        echo "FAIL  record grammar: SKILL.md and rank.py disagree" >&2
        fail=1
    fi

    printf '# A record with no Kinds table\n' > "$out/no-kinds.md"
    python3 -I "$scripts/slice_findings.py" "$recorded" "$out/no-kinds.md" \
        >/dev/null 2>&1 && rc=0 || rc=$?
    expect_usage "$rc" "slice with a record that has no Kinds table" || fail=1
    for script in slice_findings.py rank.py show_rows.py; do
        python3 -I "$scripts/$script" >/dev/null 2>&1 && rc=0 || rc=$?
        expect_usage "$rc" "$script with no argument" || fail=1
    done
    python3 -I "$scripts/rank.py" "$WORK/absent" >/dev/null 2>&1 \
        && rc=0 || rc=$?
    expect_usage "$rc" "rank on a missing directory" || fail=1

    for script in measure_time.py state_notes.py; do
        python3 -I "$scripts/$script" "$WS" "$timed/runs.tsv" >/dev/null 2>&1 \
            && rc=0 || rc=$?
        expect_usage "$rc" "$script with two arguments" || fail=1
        python3 -I "$scripts/$script" "$WS" "$WORK/absent.tsv" "$out/x" \
            >/dev/null 2>&1 && rc=0 || rc=$?
        expect_usage "$rc" "$script on a missing runs.tsv" || fail=1
    done

    return "$fail"
}

# --- Self-test -------------------------------------------------------------------

# Apply one literal replacement to a copied script; exit 2 when the literal is
# not found exactly once (the mutation no longer applies).
mutate() {
    local file="$1" old="$2" new="$3"
    if ! python3 -I -c '
import sys
path, old, new = sys.argv[1:4]
text = open(path, encoding="utf-8").read()
if text.count(old) != 1:
    sys.exit(1)
open(path, "w", encoding="utf-8").write(text.replace(old, new))
' "$file" "$old" "$new"; then
        echo "FAIL  self-test fixture stale: mutation did not apply to $(basename "$file")" >&2
        exit 2
    fi
}

# Run one mutant: fresh copies, one mutation, and the cases must fail.
run_mutant() {
    local label="$1" file="$2" old="$3" new="$4" dir rc
    dir="$WORK/mutant-$label"
    mkdir -p "$dir"
    cp "$SCRIPTS"/*.py "$dir/"
    mutate "$dir/$file" "$old" "$new"
    run_cases "$dir" "$dir/out" >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -eq 0 ]]; then
        echo "FAIL  self-test: the $label mutant passed" >&2
        return 1
    fi
    echo "OK    self-test: the $label mutant failed"
}

run_self_test() {
    local copy="$WORK/selftest" fail=0 rc
    mkdir -p "$copy" "$WORK/empty-path"
    cp "$SCRIPTS"/*.py "$copy/"
    if ! run_cases "$copy" "$copy/out" >/dev/null 2>&1; then
        echo "FAIL  self-test: the unmutated copies fail" >&2
        return 1
    fi
    echo "OK    self-test: the unmutated copies pass"

    run_mutant pipe-split extract_findings.py \
        'parts = split_unescaped(line.rstrip("\r\n"))' \
        'parts = line.rstrip("\r\n").split("|")' || fail=1
    run_mutant span-union measure_time.py \
        'minutes(union_seconds(kinds[kind]))' \
        'minutes(sum(last - first for first, last in kinds[kind]))' || fail=1

    PATH="$WORK/empty-path" "$BASH" "$SCRIPT_DIR/check-retro-scripts.sh" \
        >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 2 ]]; then
        echo "FAIL  self-test: with no python3 on PATH the guard exited $rc, expected 2" >&2
        fail=1
    else
        echo "OK    self-test: with no python3 on PATH the guard exits 2"
    fi

    if [[ "$fail" -eq 0 ]]; then
        echo "OK    self-test passed for $(basename "$0")"
    fi
    return "$fail"
}

# --- Dispatch --------------------------------------------------------------------

if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit $?
fi

run_cases "$SCRIPTS" "$WORK/out"
exit $?
