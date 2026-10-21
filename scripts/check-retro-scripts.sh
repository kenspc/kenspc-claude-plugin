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
# candidate has no json, but whose transcript names it; a run named by two
# candidates' jsons, one with no .exit (open-ended), beside a third candidate
# whose json does not name it and whose transcript, never searched, does
# (manual, an anomaly); a resume's json (role without -r<k>); a run with no
# candidate (manual); a run id with no timestamp; and windows `last 2`,
# `all`, `since <timestamp>` equal to a batch's earliest run (out), `since
# <date>` after a batch's earliest run but on a later run's date (out), and
# unreadable windows. `last 2` and then `all` run into one directory, whose
# extract.md must hold a single window section. The .exit files get their
# mtimes from workspace/exit-times.txt with touch -t, since git keeps none.
# The temp directory's path is written `<work>` before each diff.
#
# Exit code 0: every output matched its expected file.
# Exit code 1: an output differed (the diff is printed), or a self-test
#              mutant passed.
# Exit code 2: python3 is not on PATH, a script or fixture is missing, or a
#              self-test mutation did not apply (the fixture is stale).
#              A missing python3 is never a pass: a guard that silently did
#              not run would read as one, as check-instruction-lint.sh treats
#              a missing pwsh.
#
# Optional flag:
#   --self-test    Copies the scripts into the temp directory, checks that
#                  the unmutated copies pass, then turns the guard red with
#                  each mutant of the copies — the unescaped-pipe split
#                  replaced with a plain split on `|` — which must fail. It
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
SCRIPT_NAMES="extract_findings.py map_runs.py"

for name in $SCRIPT_NAMES; do
    if [[ ! -f "$SCRIPTS/$name" ]]; then
        echo "ERROR: missing script $SCRIPTS/$name" >&2
        exit 2
    fi
done
for dir in repo/runs worktree-runs workspace/_logs claude-config expected; do
    if [[ ! -d "$FIXTURES/$dir" ]]; then
        echo "ERROR: missing fixture directory $FIXTURES/$dir" >&2
        exit 2
    fi
done

WORK=""
cleanup() {
    if [[ -n "$WORK" ]]; then
        rm -rf "$WORK"
    fi
}
trap cleanup EXIT
WORK="$(cd "$(mktemp -d)" && pwd -P)"

export HOME="$WORK/home" XDG_CONFIG_HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"

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
    for window in "last 0" "since 2026-13-01" "some"; do
        python3 -I "$scripts/map_runs.py" "$REPO" "$WS" "$window" "$out/x" \
            >/dev/null 2>&1 && rc=0 || rc=$?
        expect_usage "$rc" "map with window '$window'" || fail=1
    done
    python3 -I "$scripts/map_runs.py" "$REPO" "$WS" "all" >/dev/null 2>&1 \
        && rc=0 || rc=$?
    expect_usage "$rc" "map with three arguments" || fail=1

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
