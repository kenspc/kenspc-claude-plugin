#!/usr/bin/env bash
# check-autopilot-scripts.sh
#
# Behavior guard for the four helper scripts the autopilot skill ships
# beside its driver:
#
#   1. plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh
#        writes each `Acceptance:` (or `Release checks:`) case of a spec's
#        `## Autopilot` section to <nn>.cmd (one code span) or <nn>.case (a
#        description), and names the span-led cases on a second line
#   2. plugins/kenspc/skills/autopilot/scripts/zero-diff.sh
#        compares a list of paths between a baseline and HEAD
#   3. plugins/kenspc/skills/autopilot/scripts/temp-candidates.sh
#        snapshots a temp folder, and lists the batch's own new entries in it
#   4. plugins/kenspc/skills/autopilot/scripts/suite-slots.sh
#        runs a listed test suite only while fewer than N run on the machine
#
# The first two replaced steps every main session used to write by hand, and
# both went wrong that way: commands extracted with a stray backtick at each
# end, and a zero-diff check whose paths arrived as one word and compared
# nothing. The third decides what the main session removes with a recursive
# rm, so a rule that drifts toward listing too much must turn the guard red:
# its fixtures hold entries made before the batch, another repository's
# clone, another track's prefix, and a symlink, none of which may be listed.
# The fourth is the only bound on how many heavy suites every batch on the
# machine runs at once, so a slot it gives away, a stale holder it keeps, a
# holder file it leaves, or a nested call it holds back must turn the guard
# red.
# This guard runs the scripts against fixtures built in a mktemp -d directory —
# single and double backticks, a backtick inside a double-backtick span, spans
# with and without the padding spaces, a label with a note holding
# parentheses, an `(optional)`
# case, a description case, a continuation line, `Acceptance: none`, no
# section, no field, inline text on the label line, an empty field, a code
# span that does not end the text, an unclosed code span, a deeper-indented
# bullet, a second ## Autopilot section, a CRLF spec, fenced code blocks
# before and inside the section (backtick and tilde fences, a longer fence
# around a shorter one, a column-0 `# ` comment and a `## ` line inside them,
# a backtick line whose info string holds a backtick, a column-0 fence inside
# the field, an unclosed fence), a section holding both an `Acceptance:` and
# a `Release checks:` field (each extracted alone, with no field argument,
# with `Acceptance`, and with `Release checks`), `Release checks` asked of a
# spec without that field, span-led entries beside a command, an entry that
# opens with prose and holds a code span later, a field name other than the
# two, four arguments, the wrong arguments, an unreadable spec — every
# extractor fixture's second line, `span-led:`, held as well as its counts
# line; a path
# with a space, a changed path, the same with GIT_LITERAL_PATHSPECS=1 in the
# environment, an unchanged path, a path absent at the
# baseline, paths with a space before or after them, a path holding glob
# characters, a paths file with CRLF line ends, a long changed path, an empty
# paths file, one of whitespace-only lines, a baseline that is not a commit, a
# last line without a newline, a run from a subdirectory, an excluded changed
# file inside a listed directory, a changed sibling of an exclusion, a
# bracketed exclusion beside the file it would match as a glob, an exclusion
# absent at the baseline, a paths file of exclusions only, a bare `!` — the
# count line held in its `compared: <n> paths, <m> excluded` form; a temp folder and its
# before list, a cmds dir, the repository, another repository, and a seed for
# the sweep; and, for the wrapper, under /bin/bash and with a lock directory
# of each fixture's own under the work directory (KENSPC_SUITE_SLOTS_DIR): two
# wrapped `sleep 3` holders at limit 2, started under two different time
# zones, one's holder file checked against the layout the wrapper's header
# fixes, and a third run that is busy (exit 75,
# a busy line naming both holders) and then, with --wait 10, acquires once a
# holder ends while no sample every 0.2 seconds shows three holder files,
# its acquired log line showing the wait;
# limit 3 entering beside two live holders and limit 2 busy beside them; a
# wrapped `exit 3` returning 3 and leaving no holder file; a holder whose
# wrapper pid is dead and whose command pid runs with another start time,
# reclaimed; a holder whose command pid is a live sleep, kept; a mutex with
# no owner backdated with touch -t, reclaimed; a nested call beside a live
# holder at limit 1, run at once; the limit read from
# KENSPC_AUTOPILOT_SUITE_LIMIT alone, entering with no holder and busy
# beside one, and --limit taking precedence over it; a mutex whose owner
# pid is dead or runs under another start time, reclaimed, and one whose
# owner runs with its recorded start, kept (busy, the mutex left in place); a wrapped run killed with SIGTERM, SIGINT, or SIGHUP,
# its holder file gone and its child sleep ended, each with its own exit
# code; and usage errors (no --, no limit, limit 0 or 00, limit x, a
# regular file as the lock directory, a ps that prints no start time),
# beside limit 01 read as 1 — and
# asserts each outcome. Every background process a fixture starts is
# waited for or killed by its pid before the fixture ends, and again on
# exit. The other-owner refusal has no fixture: the guard cannot chown.
#
# Exit code 0: every assertion held.
# Exit code 1: at least one assertion failed (each is printed on stderr).
# Exit code 2: a script under test is missing, or a self-test mutation did not
#              apply (the fixture is stale).
#
# Optional flag:
#   --self-test    Copies the four scripts into the temp directory and turns
#                  the guard red with fifteen mutants of the copies — the
#                  padding stripping removed from the extractor, its
#                  continuation joining removed, its fence tracking removed,
#                  its field argument ignored (always `Acceptance`), its
#                  span-led test dropped (the line always `none`),
#                  zero-diff.sh's paths passed to git diff as one word,
#                  its exclusion dropped (a `!` path compared as a plain
#                  path), its literal magic dropped,
#                  temp-candidates.sh's before-list filter, origin
#                  comparison, and symlink exclusion each removed, and
#                  suite-slots.sh's count check made always true, its
#                  stale-holder reclaim removed, its release on exit
#                  removed, and its nesting check removed — each of which
#                  must make the guard exit 1, then green again on the
#                  unmutated copies. The wrapper's four mutants run the
#                  wrapper's fixtures alone, since the other fixtures cannot
#                  see a change to it and each pass pays its sleeps again.
#
# Runs under the bash 3.2 macOS ships. The only recursive rm is the EXIT
# trap's removal of the guard's own mktemp directory. Git runs with the
# global and system configuration masked, so a user's signing or hook
# setting cannot change a fixture commit.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS="$REPO_ROOT/plugins/kenspc/skills/autopilot/scripts"
EXTRACT_SRC="$SCRIPTS/extract-acceptance.sh"
ZERO_SRC="$SCRIPTS/zero-diff.sh"
TEMP_SRC="$SCRIPTS/temp-candidates.sh"
SLOTS_SRC="$SCRIPTS/suite-slots.sh"

for f in "$EXTRACT_SRC" "$ZERO_SRC" "$TEMP_SRC" "$SLOTS_SRC"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing script $f" >&2
        exit 2
    fi
done

# The background processes the wrapper's fixtures start, each killed on
# exit in case an assertion's error ends the guard before its fixture does.
BG_PIDS=""

cleanup() {
    local p
    for p in $BG_PIDS; do
        kill "$p" 2>/dev/null || true
    done
    rm -rf "${WORK:-}"
}

WORK=$(mktemp -d)
trap cleanup EXIT

# A run of this guard inside a wrapped suite, or inside an autopilot worker,
# would otherwise hand the wrapper fixtures the caller's limit, log, or
# nesting mark.
unset KENSPC_AUTOPILOT_SUITE_LIMIT KENSPC_AUTOPILOT_SUITE_LOG KENSPC_SUITE_SLOT_HELD KENSPC_SUITE_SLOTS_DIR

export HOME="$WORK/home" XDG_CONFIG_HOME="$WORK/home" GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"

# --- Fixtures -----------------------------------------------------------------

FX="$WORK/fx"
mkdir -p "$FX"

cat > "$FX/spec-cases.md" <<'EOF'
# Fixture spec

## Implementation Steps

- Acceptance: not this field, it is outside the section

## Autopilot

- Budget: USD 10
- Acceptance (in the order listed (one at a time)):
  - `echo a` — PASS: exit 0
  - `` printf '`x`' `` — PASS: exit 0
  - ``echo b`` — PASS: exit 0
  - ` echo  c ` — PASS: exit 0
  - `` echo d`` — PASS: exit 0
  - `echo one
    two` — PASS: exit 0
  - `echo e` — PASS: exit 0 (optional)
  - run it by hand — PASS: ok
- Acceptance record: docs/x.md

## After

- Acceptance: none
EOF

printf '# Spec\n\n## Autopilot\n\n- Budget: USD 10\n- Acceptance: none\n' > "$FX/spec-none.md"

cat > "$FX/spec-more.md" <<'EOF'
## Autopilot

- Acceptance:
  - run the suite — PASS: green
    - with the cache cleared
  - `echo z` — PASS: exit 0

## Autopilot

- Acceptance:
  - `echo not-read` — PASS: exit 0
EOF

printf '## Autopilot\r\n\r\n- Acceptance:\r\n  - `echo a` — PASS: exit 0\r\n' > "$FX/spec-crlf.md"

cat > "$FX/spec-spans.md" <<'EOF'
## Autopilot

- Acceptance:
  - `npm test` passes, then `npm run lint` — PASS: exit 0
  - `echo x — PASS: ok
EOF
# Fenced code blocks: one before the section holding a `## Autopilot` line
# and a field, and three inside it — backticks with a column-0 `# ` comment,
# tildes with a `## ` line, and a four-backtick fence holding a three-
# backtick line that must not close it — none of which ends the section or
# is read as a field. A backtick line whose info string holds a backtick
# opens no fence.
cat > "$FX/spec-fenced.md" <<'EOF'
# Spec

```markdown
## Autopilot

- Acceptance:
  - `echo from-the-example` — PASS: exit 0
```

## Autopilot

- Budget: USD 10

```python
# usage: python3 -I mutate.py <file>
print("x")
```

~~~sh
## not a heading
~~~

````text
```
# still inside
````

``` not a fence `x`
- Acceptance:
  - `echo fenced` — PASS: exit 0
  - run it by hand — PASS: ok

## After

- Acceptance: none
EOF

# A fence opened in column 0 inside the field ends it, as any line there
# does; one never closed hides the field and is named in the reason.
cat > "$FX/spec-fence-ends.md" <<'EOF'
## Autopilot

- Acceptance:
  - `echo first` — PASS: exit 0
```sh
  - `echo in-fence` — PASS: exit 0
```
  - `echo after` — PASS: exit 0
EOF
printf '## Autopilot\n\n```py\n# usage\n- Acceptance:\n  - `echo x` — PASS: ok\n' > "$FX/spec-unclosed.md"
# Both fields in one section, the second with a note: each is extracted
# alone, by its own name.
cat > "$FX/spec-both.md" <<'EOF'
## Autopilot

- Acceptance:
  - `echo acc` — PASS: exit 0
- Release checks (after the last commit):
  - `echo rel1` — PASS: exit 0
  - `echo rel2` — PASS: exit 0
- Budget: USD 10
EOF
# A command, then two entries that open with a code span and hold words
# after it (span-led), and one that opens with prose and holds a span later.
cat > "$FX/spec-spanled.md" <<'EOF'
## Autopilot

- Acceptance:
  - `echo one` — PASS: exit 0
  - `dotnet build` from the root — PASS: x
  - run `npm test` from the root — PASS: green
  - ``a `b` c`` then more — PASS: y
EOF
printf '## Autopilot\n\n- Acceptance:\n  - run `npm test` from the root — PASS: green\n' > "$FX/spec-prose.md"
printf '# Spec\n\n## Implementation Steps\n\n- Acceptance: none\n' > "$FX/spec-nosection.md"
printf '# Spec\n\n## Autopilot\n\n- Budget: USD 10\n' > "$FX/spec-nofield.md"
printf '# Spec\n\n## Autopilot\n\n- Acceptance: run the suite\n- Budget: USD 10\n' > "$FX/spec-inline.md"
printf '# Spec\n\n## Autopilot\n\n- Acceptance:\n- Budget: USD 10\n' > "$FX/spec-emptyfield.md"
printf '## Autopilot\n\n- Budget: USD 10\n\n## Notes\n\n## Autopilot\n\n- Acceptance: none\n' > "$FX/spec-secondsection.md"

# A repository whose baseline holds six files; one commit after it changes
# the file whose name holds a space, xy.txt, which the glob x[y].txt would
# match, and a file whose path is longer than a default stat line shows.
REPO="$FX/repo"
git init -q "$REPO"
git -C "$REPO" config user.email guard@example.invalid
git -C "$REPO" config user.name guard
git -C "$REPO" config commit.gpgsign false
printf 'a\n' > "$REPO/a.txt"
printf 'b\n' > "$REPO/with space.txt"
printf 'c\n' > "$REPO/c.txt"
printf 'x\n' > "$REPO/x[y].txt"
printf 'y\n' > "$REPO/xy.txt"
LONG="deeply/nested/directory/structure/for/the/stat/width/a-rather-long-file-name.txt"
mkdir -p "$REPO/$(dirname "$LONG")"
printf 'l\n' > "$REPO/$LONG"
mkdir -p "$REPO/dir"
printf 'k\n' > "$REPO/dir/keep.txt"
printf 's\n' > "$REPO/dir/skip.txt"
git -C "$REPO" add -A
git -C "$REPO" commit -q -m baseline
BASE=$(git -C "$REPO" rev-parse HEAD)
printf 'b2\n' >> "$REPO/with space.txt"
printf 'y2\n' >> "$REPO/xy.txt"
printf 'l2\n' >> "$REPO/$LONG"
printf 's2\n' >> "$REPO/dir/skip.txt"
git -C "$REPO" commit -q -am change

printf 'a.txt\nc.txt\n' > "$FX/paths-unchanged.txt"
printf 'a.txt\n\nwith space.txt\n' > "$FX/paths-changed.txt"
printf 'absent.txt\na.txt\n' > "$FX/paths-absent.txt"
printf ' with space.txt\na.txt \n' > "$FX/paths-padded.txt"
printf 'x[y].txt\n' > "$FX/paths-glob.txt"
printf '%s\n' "$LONG" > "$FX/paths-long.txt"
printf 'a.txt\r\nwith space.txt\r\n' > "$FX/paths-crlf.txt"
: > "$FX/paths-empty.txt"
printf '  \n\t\n' > "$FX/paths-blank.txt"
printf 'a.txt\nwith space.txt' > "$FX/paths-nonewline.txt"
# Exclusions: the changed dir/skip.txt excluded from its listed directory;
# the unchanged sibling excluded instead; a bracketed exclusion beside the
# changed xy.txt it would match as a glob; exclusions only; a bare `!`;
# and an exclusion absent at the baseline.
printf 'dir/\n!dir/skip.txt\n' > "$FX/paths-excl.txt"
printf 'dir/\n!dir/keep.txt\n' > "$FX/paths-excl-sibling.txt"
printf 'xy.txt\n!x[y].txt\n' > "$FX/paths-excl-glob.txt"
printf '!a.txt\n!dir/skip.txt\n' > "$FX/paths-excl-only.txt"
printf 'a.txt\n!\n' > "$FX/paths-excl-bare.txt"
printf 'a.txt\n!nope.txt\n' > "$FX/paths-excl-absent.txt"

# A temp folder for temp-candidates.sh. Its before-state holds a hidden
# entry, an unrelated directory, and, made before the batch, an entry with
# the batch's prefix and a clone of the repository — neither may be listed.
# The cmds dir names three prefixes, one per spelling of the variable, and
# another track's prefix (crp-) appears in none of them.
TMPF="$FX/tmp"
mkdir -p "$TMPF/old-dir" "$TMPF/.hidden" "$TMPF/bka-OLD123" "$TMPF/tmp.OLDOLDOLD1"
git clone -q "$REPO" "$TMPF/tmp.OLDOLDOLD1/r"
CMDS="$FX/s4-cmds"
mkdir -p "$CMDS"
printf '%s\n' 'D="$(mktemp -d "${TMPDIR%/}/bka-XXXXXX")" && git clone -q . "$D/r"' > "$CMDS/01.cmd"
printf '%s\n' 'echo x > "$TMPDIR/pim-lock"' > "$CMDS/02.cmd"
printf '%s\n' 'touch "${TMPDIR}/zz-x"' > "$CMDS/03.corrected.cmd"
printf '%s\n' 'the case names ${TMPDIR%/}/nope- in a description' > "$CMDS/04.case"
OTHER="$FX/other-repo"
git init -q "$OTHER"
git -C "$OTHER" -c user.email=g@example.invalid -c user.name=g commit -q --allow-empty -m other
SEED="$FX/seed"
git init -q "$SEED"
git -C "$SEED" -c user.email=g@example.invalid -c user.name=g commit -q --allow-empty -m seed
ln -s "$REPO" "$FX/repo-link"
REPOP=$(cd "$REPO" && pwd -P)
SEEDP=$(cd "$SEED" && pwd -P)

# make_new_entries: the entries a batch makes after the snapshot — its own,
# by each piece of evidence, and three that are not its own.
make_new_entries() {
    mkdir -p "$TMPF/autopilot-selftest.AbCdEf" "$TMPF/bka-AbC123" "$TMPF/bka-with space" \
        "$TMPF/tmp.NEWNEWNEW1" "$TMPF/tmp.LINKED1234" "$TMPF/tmp.SEED123456" \
        "$TMPF/tmp.OTHER12345" "$TMPF/crp-XYZ123"
    git clone -q "$REPO" "$TMPF/bka-AbC123/r"
    printf 'log\n' > "$TMPF/bka-run.log"
    printf 'lock\n' > "$TMPF/pim-lock"
    printf 'x\n' > "$TMPF/zz-x"
    # A clone of `.`, which records <repo>/. as its origin.
    (cd "$REPO" && git clone -q . "$TMPF/tmp.NEWNEWNEW1/r")
    git clone -q "$REPO" "$TMPF/tmp.SELF123456"
    git clone -q "$FX/repo-link" "$TMPF/tmp.LINKED1234/r"
    git clone -q "$SEED" "$TMPF/tmp.SEED123456/r"
    git clone -q "$OTHER" "$TMPF/tmp.OTHER12345/r"
    ln -s "$TMPF/old-dir" "$TMPF/bka-link"
    # Named only by a .case file, which is a description, not a command.
    mkdir -p "$TMPF/nope-y"
}

# The before list, written here rather than by the script under test.
printf '%s\n' .hidden bka-OLD123 old-dir tmp.OLDOLDOLD1 > "$FX/temp-before.txt"
make_new_entries

# A folder for --snapshot: a hidden entry, a name with a space, a symlink.
SNAP="$FX/snap"
mkdir -p "$SNAP/a dir" "$SNAP/.dot"
printf 'f\n' > "$SNAP/file"
ln -s "$SNAP/file" "$SNAP/link"
printf '%s\n' '.dot' 'a dir' 'file' 'link' > "$FX/snap-expected.txt"

# The listing the sweep must print, sorted, without the count line.
{
    printf '%s\t%s\n' "$TMPF/autopilot-selftest.AbCdEf" "self-test"
    printf '%s\t%s\n' "$TMPF/bka-AbC123" "prefix bka-"
    printf '%s\t%s\n' "$TMPF/bka-run.log" "prefix bka-"
    printf '%s\t%s\n' "$TMPF/bka-with space" "prefix bka-"
    printf '%s\t%s\n' "$TMPF/pim-lock" "prefix pim-"
    printf '%s\t%s\n' "$TMPF/tmp.LINKED1234" "clone of $REPOP"
    printf '%s\t%s\n' "$TMPF/tmp.NEWNEWNEW1" "clone of $REPOP"
    printf '%s\t%s\n' "$TMPF/tmp.SEED123456" "clone of $SEEDP"
    printf '%s\t%s\n' "$TMPF/tmp.SELF123456" "clone of $REPOP"
    printf '%s\t%s\n' "$TMPF/zz-x" "prefix zz-"
} | LC_ALL=C sort > "$FX/temp-expected.txt"

# --- Checks -------------------------------------------------------------------

failures=0
runs=0

fail() {
    echo "FAIL  $*" >&2
    failures=$((failures + 1))
}

# expect_content <file> <expected text, without its final newline>
expect_content() {
    local file=$1 want=$2
    if [[ ! -f "$file" ]]; then
        fail "$(basename "$file") was not written"
        return 0
    fi
    printf '%s\n' "$want" > "$WORK/want"
    if ! cmp -s "$WORK/want" "$file"; then
        fail "$(basename "$file") holds [$(tr -d '\n' < "$file")], expected [$want]"
    fi
}

# expect_lines <what> <counts line> <span-led line>: the extractor's stdout,
# held in $stdout, is those two lines and no more.
expect_lines() {
    local what=$1 want1=$2 want2=$3 got1 got2 n
    got1=$(printf '%s\n' "$stdout" | sed -n 1p)
    got2=$(printf '%s\n' "$stdout" | sed -n 2p)
    n=$(printf '%s\n' "$stdout" | wc -l | tr -d ' ')
    [[ "$got1" == "$want1" ]] || fail "extract: $what printed [$got1] on its first line, expected [$want1]"
    [[ "$got2" == "$want2" ]] || fail "extract: $what printed [$got2] on its second line, expected [$want2]"
    [[ "$n" -eq 2 ]] || fail "extract: $what printed $n lines, expected 2"
}

# --- The wrapper's fixtures ---------------------------------------------------

# The wrapper runs under /bin/bash where it exists, the bash 3.2 macOS ships.
SLOT_BASH=bash
[[ -x /bin/bash ]] && SLOT_BASH=/bin/bash

# lstart_of <pid>: the start time as the wrapper records it, in UTC.
lstart_of() {
    LC_ALL=C TZ=UTC ps -o lstart= -p "$1" 2>/dev/null | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//'
}

# holder_count <lock dir>: the holder-* files present.
holder_count() {
    local f n=0
    for f in "$1"/holder-*; do
        [[ -f "$f" ]] && n=$((n + 1))
    done
    echo "$n"
}

# fake_holder <lock dir> <wrapper pid> <wrapper start> <command pid> <command start>
# Writes a holder file by hand, in the layout the wrapper's header fixes.
fake_holder() {
    mkdir -p "$1"
    chmod 700 "$1"
    printf 'wrapper_pid=%s\nwrapper_start=%s\ncommand_pid=%s\ncommand_start=%s\ntaken=%s\ncwd=%s\ncommand=%s\n' \
        "$2" "$3" "$4" "$5" "$(date +%s)" "$WORK" "fixture holder" > "$1/holder-$2"
}

# start_bg <command...>: runs it in the background, records its pid in
# $bg and in BG_PIDS.
start_bg() {
    "$@" &
    bg=$!
    BG_PIDS="$BG_PIDS $bg"
}

# stop_bg <pid>: kills it if it still runs, and reaps it.
stop_bg() {
    kill "$1" 2>/dev/null || true
    wait "$1" 2>/dev/null || true
}

# wait_holders <lock dir> <n>: polls up to five seconds for n holder files
# whose command fields are filled in.
wait_holders() {
    local i=0 f n
    while [[ "$i" -lt 50 ]]; do
        n=0
        for f in "$1"/holder-*; do
            [[ -f "$f" ]] && grep -q '^command_pid=[0-9]' "$f" && n=$((n + 1))
        done
        [[ "$n" -ge "$2" ]] && return 0
        sleep 0.1
        i=$((i + 1))
    done
    return 1
}

# slot_checks <suite-slots script>: the wrapper's thirteen fixtures, each with a
# lock directory and a log of its own under $WORK.
slot_checks() {
    local ss=$1 d log rc h1 h2 h3 s1 s2 cpid max n dead args f before
    local base="$WORK/slots-$runs"
    mkdir -p "$base"

    # 1. Two wrapped `sleep 3` holders at limit 2: a third run with --wait 1
    #    is busy, its stderr naming both holders. The two holders run under
    #    different time zones, so a start time read in the caller's zone
    #    would make each wrapper see the other's live holder as stale.
    d="$base/1"
    log="$base/1.log"
    start_bg env TZ=UTC0 KENSPC_SUITE_SLOTS_DIR="$d" KENSPC_AUTOPILOT_SUITE_LOG="$log" \
        "$SLOT_BASH" "$ss" run --limit 2 -- sleep 3
    h1=$bg
    start_bg env TZ=JST-9 KENSPC_SUITE_SLOTS_DIR="$d" KENSPC_AUTOPILOT_SUITE_LOG="$log" \
        "$SLOT_BASH" "$ss" run --limit 2 -- sleep 3
    h2=$bg
    wait_holders "$d" 2 || fail "suite-slots 1: the two holders never both held a slot"
    # The holder file a wrapped run writes, in the layout its header fixes:
    # the seven keys in order, its own pid and start, its child's, and a
    # numeric taken.
    f="$d/holder-$h1"
    n=$(sed 's/=.*//' "$f" 2>/dev/null | tr '\n' ' ')
    [[ "$n" == "wrapper_pid wrapper_start command_pid command_start taken cwd command " ]] \
        || fail "suite-slots 1: the holder file's keys are [$n]"
    cpid=$(sed -n 's/^command_pid=//p' "$f" 2>/dev/null)
    [[ "$(sed -n 's/^wrapper_pid=//p' "$f" 2>/dev/null)" == "$h1" ]] || fail "suite-slots 1: the holder file's wrapper_pid is not the wrapper's"
    [[ "$(sed -n 's/^wrapper_start=//p' "$f" 2>/dev/null)" == "$(lstart_of "$h1")" ]] || fail "suite-slots 1: the holder file's wrapper_start is not the wrapper's"
    [[ -n "$cpid" && "$(ps -o ppid= -p "$cpid" 2>/dev/null | tr -d ' ')" == "$h1" ]] || fail "suite-slots 1: the holder file's command_pid $cpid is not the wrapper's child"
    [[ "$(sed -n 's/^command_start=//p' "$f" 2>/dev/null)" == "$(lstart_of "$cpid")" ]] || fail "suite-slots 1: the holder file's command_start is not its child's"
    [[ "$(sed -n 's/^taken=//p' "$f" 2>/dev/null)" =~ ^[0-9]+$ ]] || fail "suite-slots 1: the holder file's taken is not an epoch second"
    [[ "$(sed -n 's/^command=//p' "$f" 2>/dev/null)" == "sleep 3" ]] || fail "suite-slots 1: the holder file's command is not sleep 3"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" KENSPC_AUTOPILOT_SUITE_LOG="$log" \
        "$SLOT_BASH" "$ss" run --limit 2 --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 75 ]] || fail "suite-slots 1: a third run at limit 2 exited $rc, expected 75"
    grep -q '^suite-slots: busy after [0-9]*s; held by:' "$WORK/slot-err" \
        || fail "suite-slots 1: no busy line on stderr [$(tr '\n' '|' < "$WORK/slot-err")]"
    n=$(grep -c '^  age [0-9][0-9]*s, cwd .*, command sleep 3$' "$WORK/slot-err" || true)
    [[ "$n" -eq 2 ]] || fail "suite-slots 1: the busy line names $n holders, expected 2"
    grep -q ' busy pid [0-9]* waited [0-9]*s holders 2 — true$' "$log" 2>/dev/null \
        || fail "suite-slots 1: the log shows no busy line with two holders"

    # 2. The same third run with --wait 10 acquires once a holder ends, and
    #    no sample, every 0.2 seconds, shows more than two holder files. Its
    #    acquired line shows the wait, at least one poll of a second, when
    #    both holders were still there as it started.
    before=$(holder_count "$d")
    start_bg env KENSPC_SUITE_SLOTS_DIR="$d" KENSPC_AUTOPILOT_SUITE_LOG="$log" \
        "$SLOT_BASH" "$ss" run --limit 2 --wait 10 -- sleep 1
    h3=$bg
    max=0
    while kill -0 "$h3" 2>/dev/null; do
        n=$(holder_count "$d")
        [[ "$n" -gt "$max" ]] && max=$n
        sleep 0.2
    done
    rc=0
    wait "$h3" 2>/dev/null || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 2: the third run with --wait 10 exited $rc, expected 0"
    [[ "$max" -le 2 ]] || fail "suite-slots 2: $max holder files were present at once, expected at most 2"
    n=$(grep -c ' acquired pid ' "$log" 2>/dev/null || true)
    [[ "$n" -eq 3 ]] || fail "suite-slots 2: the log shows $n acquired lines, expected 3"
    if [[ "$before" -eq 2 ]]; then
        grep -q " acquired pid $h3 waited [1-9][0-9]*s " "$log" 2>/dev/null \
            || fail "suite-slots 2: the third run's acquired line does not show its wait [$(grep " acquired pid $h3 " "$log" 2>/dev/null)]"
    fi
    stop_bg "$h1"
    stop_bg "$h2"

    # Two live processes stand behind hand-written holders in fixtures 3,
    # 6, and 8; a reaped pid stands for a dead one.
    start_bg sleep 30
    s1=$bg
    start_bg sleep 30
    s2=$bg
    true &
    dead=$!
    wait "$dead" 2>/dev/null || true

    # 3. Each caller's own N: with two live holders, limit 3 enters and
    #    limit 2 waits and is busy.
    d="$base/3"
    fake_holder "$d" "$s1" "$(lstart_of "$s1")" "" ""
    fake_holder "$d" "$s2" "$(lstart_of "$s2")" "" ""
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 3 --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 3: limit 3 beside two holders exited $rc, expected 0 ($(cat "$WORK/slot-err"))"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 2 --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 75 ]] || fail "suite-slots 3: limit 2 beside two holders exited $rc, expected 75"

    # 4. The command's own status, and no holder file left behind.
    d="$base/4"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 -- sh -c 'exit 3' 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 3 ]] || fail "suite-slots 4: a wrapped exit 3 exited $rc, expected 3"
    n=$(holder_count "$d")
    [[ "$n" -eq 0 ]] || fail "suite-slots 4: $n holder files are left after the command ended"

    # 5. A holder whose wrapper pid is dead and whose command pid runs with
    #    another start time is stale: reclaimed, and the run acquires.
    d="$base/5"
    log="$base/5.log"
    fake_holder "$d" "$dead" "Thu Jan 1 00:00:00 1970" "$s1" "Thu Jan 1 00:00:00 1970"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" KENSPC_AUTOPILOT_SUITE_LOG="$log" \
        "$SLOT_BASH" "$ss" run --limit 1 --wait 2 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 5: a run beside a stale holder exited $rc, expected 0"
    grep -q " reclaimed $dead pid " "$log" 2>/dev/null || fail "suite-slots 5: the log shows no reclaimed line for pid $dead"
    [[ -f "$d/reclaimed-holder-$dead" ]] || fail "suite-slots 5: the stale holder was not moved aside"

    # 6. A dead wrapper pid beside a live command pid is not stale.
    d="$base/6"
    fake_holder "$d" "$dead" "Thu Jan 1 00:00:00 1970" "$s2" "$(lstart_of "$s2")"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 75 ]] || fail "suite-slots 6: a run beside a live command pid exited $rc, expected 75"
    [[ -f "$d/holder-$dead" ]] || fail "suite-slots 6: the live holder was moved aside"

    # 7. A mutex with no owner file, older than 10 seconds, is reclaimed.
    d="$base/7"
    mkdir -p "$d/mutex"
    chmod 700 "$d"
    touch -t 202001010000 "$d/mutex"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 --wait 2 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 7: a run behind a stale mutex exited $rc, expected 0"

    # 8. A nested call runs at once beside a live holder at limit 1.
    d="$base/8"
    log="$base/8.log"
    fake_holder "$d" "$s1" "$(lstart_of "$s1")" "" ""
    rc=0
    KENSPC_SUITE_SLOT_HELD=1 KENSPC_SUITE_SLOTS_DIR="$d" KENSPC_AUTOPILOT_SUITE_LOG="$log" \
        "$SLOT_BASH" "$ss" run --limit 1 --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 8: a nested call exited $rc, expected 0"
    grep -q ' nested pid ' "$log" 2>/dev/null || fail "suite-slots 8: the log shows no nested line"

    # 11. The limit from KENSPC_AUTOPILOT_SUITE_LIMIT alone, as a worker
    #     runs the wrapper: 1 enters with no holder and is busy beside one
    #     live holder, and --limit 2 over it enters beside the same holder.
    d="$base/11"
    rc=0
    KENSPC_AUTOPILOT_SUITE_LIMIT=1 KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 11: the variable's limit alone exited $rc, expected 0 ($(cat "$WORK/slot-err"))"
    fake_holder "$d" "$s1" "$(lstart_of "$s1")" "" ""
    rc=0
    KENSPC_AUTOPILOT_SUITE_LIMIT=1 KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 75 ]] || fail "suite-slots 11: the variable's limit 1 beside one holder exited $rc, expected 75"
    rc=0
    KENSPC_AUTOPILOT_SUITE_LIMIT=1 KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 2 --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 11: --limit 2 over the variable's 1 beside one holder exited $rc, expected 0"

    # 12. A mutex whose owner pid is dead, or alive under another start
    #     time (a reused pid), is reclaimed and the run acquires; one whose
    #     owner is alive with its recorded start is kept, and the run is
    #     busy with the mutex still there and no holder readable.
    d="$base/12-dead"
    mkdir -p "$d/mutex"
    chmod 700 "$d"
    printf '%s\n%s\n' "$dead" "Thu Jan 1 00:00:00 1970" > "$d/mutex/owner"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 --wait 2 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 12: a run behind a dead owner's mutex exited $rc, expected 0"
    d="$base/12-reused"
    mkdir -p "$d/mutex"
    chmod 700 "$d"
    printf '%s\n%s\n' "$s2" "Thu Jan 1 00:00:00 1970" > "$d/mutex/owner"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 --wait 2 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 12: a run behind a reused owner pid's mutex exited $rc, expected 0"
    d="$base/12-live"
    mkdir -p "$d/mutex"
    chmod 700 "$d"
    printf '%s\n%s\n' "$s2" "$(lstart_of "$s2")" > "$d/mutex/owner"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 --wait 1 -- true 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 75 ]] || fail "suite-slots 12: a run behind a live owner's mutex exited $rc, expected 75"
    [[ -d "$d/mutex" ]] || fail "suite-slots 12: a live owner's mutex was removed"
    grep -qF '(none readable: the mutex stayed held)' "$WORK/slot-err" \
        || fail "suite-slots 12: the busy line does not say the mutex stayed held [$(tr '\n' '|' < "$WORK/slot-err")]"

    stop_bg "$s1"
    stop_bg "$s2"

    # 9. SIGTERM to the wrapper reaches its child and releases the slot.
    d="$base/9"
    start_bg env KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 -- sleep 30
    h1=$bg
    cpid=
    if wait_holders "$d" 1; then
        cpid=$(sed -n 's/^command_pid=//p' "$d"/holder-* | head -n 1)
    else
        fail "suite-slots 9: the wrapped run never held a slot"
    fi
    kill -TERM "$h1" 2>/dev/null || true
    rc=0
    wait "$h1" 2>/dev/null || rc=$?
    [[ "$rc" -eq 143 ]] || fail "suite-slots 9: the wrapper killed with SIGTERM exited $rc, expected 143"
    n=$(holder_count "$d")
    [[ "$n" -eq 0 ]] || fail "suite-slots 9: $n holder files are left after SIGTERM"
    if [[ -n "$cpid" ]] && ps -p "$cpid" >/dev/null 2>&1; then
        fail "suite-slots 9: the child sleep $cpid still runs after SIGTERM"
        kill "$cpid" 2>/dev/null || true
    fi

    # 10. Usage errors exit 2: no --, no limit, limit 0, limit x, a
    #     regular file where the lock directory goes, and a ps that prints
    #     no start time.
    d="$base/10"
    for args in "run --limit 1 true" "run -- true" "run --limit 0 -- true" "run --limit x -- true"; do
        rc=0
        # shellcheck disable=SC2086
        KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" $args >/dev/null 2>"$WORK/slot-err" || rc=$?
        [[ "$rc" -eq 2 ]] || fail "suite-slots 10: [$args] exited $rc, expected 2"
        [[ -s "$WORK/slot-err" ]] || fail "suite-slots 10: [$args] gave no reason on stderr"
    done
    # A leading zero is read as decimal, as the start check reads it.
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 01 -- true >/dev/null 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 0 ]] || fail "suite-slots 10: --limit 01 exited $rc, expected 0"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 00 -- true >/dev/null 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "suite-slots 10: --limit 00 exited $rc, expected 2"
    printf 'x\n' > "$base/10-file"
    rc=0
    KENSPC_SUITE_SLOTS_DIR="$base/10-file" "$SLOT_BASH" "$ss" run --limit 1 -- true >/dev/null 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "suite-slots 10: a regular file as the lock directory exited $rc, expected 2"
    grep -qF "$base/10-file" "$WORK/slot-err" || fail "suite-slots 10: the reason does not name the lock directory's path"
    # A ps that prints no start time leaves no holder judgeable: exit 2,
    # not a run that reclaims every live holder.
    mkdir -p "$base/10-ps"
    printf '#!/bin/sh\nexit 1\n' > "$base/10-ps/ps"
    chmod +x "$base/10-ps/ps"
    rc=0
    PATH="$base/10-ps:$PATH" KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 -- true >/dev/null 2>"$WORK/slot-err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "suite-slots 10: a ps with no lstart exited $rc, expected 2"
    grep -q 'no start time' "$WORK/slot-err" || fail "suite-slots 10: a ps with no lstart gave no reason naming the start time"

    # 13. SIGINT and SIGHUP to the wrapper reach its child too and release
    #     the slot. The wrapper starts under set -m: a background job of a
    #     non-interactive bash otherwise starts with SIGINT ignored, which it
    #     cannot trap.
    for args in "INT 130" "HUP 129"; do
        # shellcheck disable=SC2086
        set -- $args
        d="$base/13-$1"
        set -m
        start_bg env KENSPC_SUITE_SLOTS_DIR="$d" "$SLOT_BASH" "$ss" run --limit 1 -- sleep 30
        set +m
        h1=$bg
        cpid=
        if wait_holders "$d" 1; then
            cpid=$(sed -n 's/^command_pid=//p' "$d"/holder-* | head -n 1)
        else
            fail "suite-slots 13: the wrapped run for SIG$1 never held a slot"
        fi
        kill -"$1" "$h1" 2>/dev/null || true
        rc=0
        wait "$h1" 2>/dev/null || rc=$?
        [[ "$rc" -eq "$2" ]] || fail "suite-slots 13: the wrapper killed with SIG$1 exited $rc, expected $2"
        n=$(holder_count "$d")
        [[ "$n" -eq 0 ]] || fail "suite-slots 13: $n holder files are left after SIG$1"
        if [[ -n "$cpid" ]] && ps -p "$cpid" >/dev/null 2>&1; then
            fail "suite-slots 13: the child sleep $cpid still runs after SIG$1"
            kill "$cpid" 2>/dev/null || true
        fi
    done

    # Every process started above has been reaped, and its pid may now
    # belong to an unrelated process, which the EXIT trap must not signal.
    BG_PIDS=""
    return 0
}

# run_checks <extract script> <zero-diff script> <temp-candidates script>
#            <suite-slots script>
# Sets $failures to the number of assertions that failed.
run_checks() {
    local ex=$1 zd=$2 tc=$3 ss=$4 out rc listing
    failures=0
    runs=$((runs + 1))

    # The cases fixture.
    out="$WORK/out-$runs-cases"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-cases.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: cases fixture exited $rc, expected 0 ($(cat "$WORK/err"))"
    expect_lines "cases fixture" "commands: 7, cases: 1" "span-led: none"
    listing=$(cd "$out" 2>/dev/null && ls | tr '\n' ' ') || listing="(no out dir)"
    [[ "$listing" == "01.cmd 02.cmd 03.cmd 04.cmd 05.cmd 06.cmd 07.cmd 08.case " ]] \
        || fail "extract: cases fixture wrote [$listing]"
    expect_content "$out/01.cmd" 'echo a'
    expect_content "$out/02.cmd" "printf '\`x\`'"
    expect_content "$out/03.cmd" 'echo b'
    expect_content "$out/04.cmd" 'echo  c'
    expect_content "$out/05.cmd" ' echo d'
    expect_content "$out/06.cmd" 'echo one two'
    expect_content "$out/07.cmd" 'echo e'
    expect_content "$out/08.case" 'run it by hand'

    # A code span that does not end the text, and one never closed: each is
    # a case description, never a truncated command.
    out="$WORK/out-$runs-spans"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-spans.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: spans fixture exited $rc, expected 0"
    expect_lines "spans fixture" "commands: 0, cases: 2" "span-led: 01, 02"
    expect_content "$out/01.case" '`npm test` passes, then `npm run lint`'
    expect_content "$out/02.case" '`echo x'

    # Both fields in one section: with no field argument, and with
    # Acceptance, only Acceptance's case is written; with Release checks,
    # only that field's two.
    local fld
    for fld in "" Acceptance; do
        out="$WORK/out-$runs-both-acc$fld"
        rc=0
        if [[ -z "$fld" ]]; then
            stdout=$(bash "$ex" "$FX/spec-both.md" "$out" 2>"$WORK/err") || rc=$?
        else
            stdout=$(bash "$ex" "$FX/spec-both.md" "$out" "$fld" 2>"$WORK/err") || rc=$?
        fi
        [[ "$rc" -eq 0 ]] || fail "extract: both-fields fixture [${fld:-no field}] exited $rc, expected 0 ($(cat "$WORK/err"))"
        expect_lines "both-fields fixture [${fld:-no field}]" "commands: 1, cases: 0" "span-led: none"
        listing=$(cd "$out" 2>/dev/null && ls | tr '\n' ' ') || listing="(no out dir)"
        [[ "$listing" == "01.cmd " ]] || fail "extract: both-fields fixture [${fld:-no field}] wrote [$listing]"
        expect_content "$out/01.cmd" 'echo acc'
    done
    out="$WORK/out-$runs-both-rel"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-both.md" "$out" "Release checks" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: both-fields fixture [Release checks] exited $rc, expected 0 ($(cat "$WORK/err"))"
    expect_lines "both-fields fixture [Release checks]" "commands: 2, cases: 0" "span-led: none"
    listing=$(cd "$out" 2>/dev/null && ls | tr '\n' ' ') || listing="(no out dir)"
    [[ "$listing" == "01.cmd 02.cmd " ]] || fail "extract: both-fields fixture [Release checks] wrote [$listing]"
    expect_content "$out/01.cmd" 'echo rel1'
    expect_content "$out/02.cmd" 'echo rel2'

    # Release checks read from a spec that has only Acceptance: exit 2, the
    # reason naming the field read, no file written.
    out="$WORK/out-$runs-norel"
    rc=0
    bash "$ex" "$FX/spec-cases.md" "$out" "Release checks" >/dev/null 2>"$WORK/err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "extract: Release checks absent exited $rc, expected 2"
    grep -qF 'no Release checks: field' "$WORK/err" || fail "extract: Release checks absent: the reason does not name the field [$(cat "$WORK/err")]"
    listing=$(cd "$out" 2>/dev/null && ls -A | tr '\n' ' ') || listing=""
    [[ -z "$listing" ]] || fail "extract: Release checks absent wrote [$listing]"

    # Span-led entries are cases named on the second line; an entry that
    # opens with prose and holds a span later is a case not named there.
    out="$WORK/out-$runs-spanled"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-spanled.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: span-led fixture exited $rc, expected 0 ($(cat "$WORK/err"))"
    expect_lines "span-led fixture" "commands: 1, cases: 3" "span-led: 02, 04"
    expect_content "$out/02.case" '`dotnet build` from the root'
    expect_content "$out/03.case" 'run `npm test` from the root'
    out="$WORK/out-$runs-prose"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-prose.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: prose fixture exited $rc, expected 0"
    expect_lines "prose fixture" "commands: 0, cases: 1" "span-led: none"
    expect_content "$out/01.case" 'run `npm test` from the root'

    # A field name other than the two, and a fourth argument: exit 2, with
    # no out dir made and no file written.
    out="$WORK/out-$runs-bogus"
    rc=0
    bash "$ex" "$FX/spec-both.md" "$out" Bogus >/dev/null 2>"$WORK/err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "extract: field Bogus exited $rc, expected 2"
    [[ -s "$WORK/err" ]] || fail "extract: field Bogus gave no reason on stderr"
    [[ ! -e "$out" ]] || fail "extract: field Bogus wrote [$(ls -A "$out" | tr '\n' ' ')]"
    out="$WORK/out-$runs-four"
    rc=0
    bash "$ex" "$FX/spec-both.md" "$out" Acceptance extra >/dev/null 2>"$WORK/err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "extract: four arguments exited $rc, expected 2"
    [[ ! -e "$out" ]] || fail "extract: four arguments wrote [$(ls -A "$out" | tr '\n' ' ')]"

    # A deeper-indented bullet is a continuation of its case, and a second
    # ## Autopilot section's field is not read.
    out="$WORK/out-$runs-more"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-more.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: more fixture exited $rc, expected 0"
    expect_lines "more fixture" "commands: 1, cases: 1" "span-led: none"
    listing=$(cd "$out" 2>/dev/null && ls | tr '\n' ' ') || listing="(no out dir)"
    [[ "$listing" == "01.case 02.cmd " ]] || fail "extract: more fixture wrote [$listing]"
    expect_content "$out/02.cmd" 'echo z'

    # Fenced code blocks before and inside the section: the field after
    # them is read, and nothing inside them is.
    out="$WORK/out-$runs-fenced"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-fenced.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: fenced fixture exited $rc, expected 0 ($(cat "$WORK/err"))"
    expect_lines "fenced fixture" "commands: 1, cases: 1" "span-led: none"
    expect_content "$out/01.cmd" 'echo fenced'
    expect_content "$out/02.case" 'run it by hand'

    # A column-0 fence inside the field ends it.
    out="$WORK/out-$runs-fence-ends"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-fence-ends.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: fence-ends fixture exited $rc, expected 0"
    expect_lines "fence-ends fixture" "commands: 1, cases: 0" "span-led: none"
    expect_content "$out/01.cmd" 'echo first'

    # An unclosed fence: exit 2, its line named in the reason.
    rc=0
    bash "$ex" "$FX/spec-unclosed.md" "$WORK/out-$runs-unclosed" >/dev/null 2>"$WORK/err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "extract: unclosed fence exited $rc, expected 2"
    grep -qF 'opened at line 3 is never closed' "$WORK/err" || fail "extract: unclosed fence's reason does not name line 3 [$(cat "$WORK/err")]"

    # A spec with CRLF line ends: the command carries no carriage return.
    out="$WORK/out-$runs-crlf"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-crlf.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: CRLF fixture exited $rc, expected 0"
    expect_lines "CRLF fixture" "commands: 1, cases: 0" "span-led: none"
    expect_content "$out/01.cmd" 'echo a'

    # The wrong arguments, and a spec that cannot be read: exit 2.
    rc=0
    bash "$ex" "$FX/spec-none.md" >/dev/null 2>&1 || rc=$?
    [[ "$rc" -eq 2 ]] || fail "extract: one argument exited $rc, expected 2"
    rc=0
    bash "$ex" "$FX/no-such-spec.md" "$WORK/out-$runs-unreadable" >/dev/null 2>&1 || rc=$?
    [[ "$rc" -eq 2 ]] || fail "extract: an unreadable spec exited $rc, expected 2"

    # Acceptance: none.
    out="$WORK/out-$runs-none"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-none.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: none fixture exited $rc, expected 0"
    expect_lines "none fixture" "commands: 0, cases: 0" "span-led: none"
    listing=$(cd "$out" 2>/dev/null && ls -A | tr '\n' ' ') || listing="(no out dir)"
    [[ -z "$listing" ]] || fail "extract: none fixture wrote [$listing]"

    # No section, no field, inline text on the label line, an empty field,
    # and a field only in a second ## Autopilot section: exit 2 with a reason
    # on stderr, and no file written.
    local spec
    for spec in spec-nosection spec-nofield spec-inline spec-emptyfield spec-secondsection; do
        out="$WORK/out-$runs-$spec"
        rc=0
        bash "$ex" "$FX/$spec.md" "$out" >/dev/null 2>"$WORK/err" || rc=$?
        [[ "$rc" -eq 2 ]] || fail "extract: $spec exited $rc, expected 2"
        [[ -s "$WORK/err" ]] || fail "extract: $spec gave no reason on stderr"
        listing=$(cd "$out" 2>/dev/null && ls -A | tr '\n' ' ') || listing=""
        [[ -z "$listing" ]] || fail "extract: $spec wrote [$listing]"
    done

    # zero-diff: unchanged paths.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-unchanged.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: unchanged paths exited $rc, expected 0"
    [[ "$stdout" == "compared: 2 paths, 0 excluded" ]] || fail "zero-diff: unchanged paths printed [$stdout]"

    # zero-diff: a changed path whose name holds a space, beside an unchanged
    # one, with a blank line between them.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-changed.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: changed path exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths, 0 excluded" ]] \
        || fail "zero-diff: changed path's first line is not [compared: 2 paths, 0 excluded]"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: the stat does not name the changed path"

    # zero-diff: the same changed path with GIT_LITERAL_PATHSPECS=1 in the
    # environment, under which git would read :(literal)<path> as a file
    # name and print an empty stat.
    rc=0
    stdout=$(cd "$REPO" && GIT_LITERAL_PATHSPECS=1 bash "$zd" "$BASE" "$FX/paths-changed.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: changed path with GIT_LITERAL_PATHSPECS=1 exited $rc, expected 1"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: with GIT_LITERAL_PATHSPECS=1, the stat does not name the changed path"

    # zero-diff: a path with a space before it, as a split on a comma leaves
    # it, and one with a space after it are trimmed and compared.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-padded.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: padded paths exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths, 0 excluded" ]] \
        || fail "zero-diff: padded paths' first line is not [compared: 2 paths, 0 excluded]"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: the stat does not name the padded changed path"
    [[ ! -s "$WORK/err" ]] || fail "zero-diff: padded paths wrote to stderr: $(cat "$WORK/err")"

    # zero-diff: a paths file with CRLF line ends compares the paths without
    # the carriage return, so the changed path is found.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-crlf.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: CRLF paths exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths, 0 excluded" ]] \
        || fail "zero-diff: CRLF paths' first line is not [compared: 2 paths, 0 excluded]"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: the stat does not name the changed path of the CRLF list"

    # zero-diff: an unchanged path holding glob characters is read literally,
    # so the changed xy.txt it would match as a glob is not compared.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-glob.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: glob-character path exited $rc, expected 0"
    [[ "$stdout" == "compared: 1 paths, 0 excluded" ]] || fail "zero-diff: glob-character path printed [$stdout]"

    # zero-diff: an excluded file inside a listed directory changed — exit 0,
    # the exclusion counted and not named absent; the unchanged sibling
    # excluded instead — exit 1, the stat naming the changed file.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-excl.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: excluded changed file exited $rc, expected 0 [$stdout]"
    [[ "$stdout" == "compared: 1 paths, 1 excluded" ]] || fail "zero-diff: excluded changed file printed [$stdout]"
    [[ ! -s "$WORK/err" ]] || fail "zero-diff: excluded changed file wrote to stderr: $(cat "$WORK/err")"
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-excl-sibling.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: changed sibling of an exclusion exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 1 paths, 1 excluded" ]] \
        || fail "zero-diff: changed sibling of an exclusion: first line is not [compared: 1 paths, 1 excluded]"
    printf '%s\n' "$stdout" | grep -qF 'dir/skip.txt' || fail "zero-diff: the stat does not name the changed sibling"

    # zero-diff: a bracketed exclusion is read literally, so the changed
    # xy.txt it would match as a glob is still compared.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-excl-glob.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: bracketed exclusion exited $rc, expected 1"
    printf '%s\n' "$stdout" | grep -qF 'xy.txt' || fail "zero-diff: the bracketed exclusion hid xy.txt"

    # zero-diff: an exclusion absent at the baseline is named without its !.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-excl-absent.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: absent exclusion exited $rc, expected 0"
    grep -qxF 'zero-diff.sh: absent at the baseline: nope.txt' "$WORK/err" \
        || fail "zero-diff: the absent exclusion is not named as nope.txt [$(cat "$WORK/err")]"

    # zero-diff: a paths file of exclusions only, and a bare !: exit 2.
    rc=0
    (cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-excl-only.txt") >/dev/null 2>"$WORK/err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "zero-diff: exclusions only exited $rc, expected 2"
    grep -qF 'exclusions only' "$WORK/err" || fail "zero-diff: exclusions only gave no reason [$(cat "$WORK/err")]"
    rc=0
    (cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-excl-bare.txt") >/dev/null 2>"$WORK/err" || rc=$?
    [[ "$rc" -eq 2 ]] || fail "zero-diff: a bare ! exited $rc, expected 2"

    # zero-diff: a changed long path is named in full, not shortened to .../
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-long.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: long path exited $rc, expected 1"
    printf '%s\n' "$stdout" | grep -qF " $LONG " || fail "zero-diff: the stat does not name the long path in full"

    # zero-diff: a path absent at the baseline is named on stderr.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-absent.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: absent path exited $rc, expected 0"
    grep -qF 'absent.txt' "$WORK/err" || fail "zero-diff: the absent path is not named on stderr"
    [[ "$stdout" == "compared: 2 paths, 0 excluded" ]] || fail "zero-diff: absent path printed [$stdout]"

    # zero-diff: an empty paths file, one of whitespace-only lines, and a
    # baseline that is not a commit are usage errors.
    rc=0
    (cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-empty.txt") >/dev/null 2>&1 || rc=$?
    [[ "$rc" -eq 2 ]] || fail "zero-diff: empty paths file exited $rc, expected 2"
    rc=0
    (cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-blank.txt") >/dev/null 2>&1 || rc=$?
    [[ "$rc" -eq 2 ]] || fail "zero-diff: whitespace-only paths file exited $rc, expected 2"
    rc=0
    (cd "$REPO" && bash "$zd" no-such-commit "$FX/paths-unchanged.txt") >/dev/null 2>&1 || rc=$?
    [[ "$rc" -eq 2 ]] || fail "zero-diff: a baseline that is not a commit exited $rc, expected 2"

    # zero-diff: a last line without a newline is read, and a run from a
    # subdirectory reads the paths from the top level.
    rc=0
    stdout=$(cd "$REPO/deeply" && bash "$zd" "$BASE" "$FX/paths-nonewline.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: no final newline, from a subdirectory, exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths, 0 excluded" ]] \
        || fail "zero-diff: no final newline, from a subdirectory: first line is not [compared: 2 paths, 0 excluded]"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: from a subdirectory, the stat does not name the changed path"

    # temp-candidates: --snapshot records every top-level name, the hidden
    # one, the one with a space, and the symlink included.
    rc=0
    stdout=$(bash "$tc" --snapshot "$SNAP" "$WORK/snap-$runs.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "temp-candidates: --snapshot exited $rc, expected 0 ($(cat "$WORK/err"))"
    [[ "$stdout" == "entries: 4" ]] || fail "temp-candidates: --snapshot printed [$stdout], expected [entries: 4]"
    if [[ -f "$WORK/snap-$runs.txt" ]]; then
        LC_ALL=C sort "$WORK/snap-$runs.txt" > "$WORK/snap-sorted"
        LC_ALL=C sort "$FX/snap-expected.txt" > "$WORK/snap-want"
        cmp -s "$WORK/snap-want" "$WORK/snap-sorted" \
            || fail "temp-candidates: --snapshot wrote [$(tr '\n' '|' < "$WORK/snap-sorted")]"
    else
        fail "temp-candidates: --snapshot wrote no before list"
    fi

    # temp-candidates: the sweep lists exactly the batch's new entries — by
    # the self-test name, by each prefix spelling (a corrected command
    # included), and as clones of the repository (a clone of `.`, a clone
    # that is the entry itself, a clone made through a symlink) or of a
    # seed — and leaves the other repository's clone, another track's
    # prefix, a symlink, a prefix only a .case file names, and every entry
    # of the before list.
    rc=0
    stdout=$(bash "$tc" "$TMPF" "$FX/temp-before.txt" "$CMDS" "$REPO" "$SEED" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "temp-candidates: the sweep exited $rc, expected 0 ($(cat "$WORK/err"))"
    [[ "$(printf '%s\n' "$stdout" | tail -n 1)" == "candidates: 10, left: 4" ]] \
        || fail "temp-candidates: the sweep's last line is [$(printf '%s\n' "$stdout" | tail -n 1)], expected [candidates: 10, left: 4]"
    printf '%s\n' "$stdout" | sed '$d' | LC_ALL=C sort > "$WORK/temp-got"
    cmp -s "$FX/temp-expected.txt" "$WORK/temp-got" \
        || fail "temp-candidates: the sweep listed [$(tr '\t\n' ' |' < "$WORK/temp-got")]"

    # temp-candidates: with no cmds dir no prefix is read, so the prefixed
    # entries that are no clone are left, and the clones are still listed.
    rc=0
    stdout=$(bash "$tc" "$TMPF" "$FX/temp-before.txt" - "$REPO" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "temp-candidates: the sweep without a cmds dir exited $rc, expected 0"
    [[ "$(printf '%s\n' "$stdout" | tail -n 1)" == "candidates: 5, left: 9" ]] \
        || fail "temp-candidates: without a cmds dir the last line is [$(printf '%s\n' "$stdout" | tail -n 1)], expected [candidates: 5, left: 9]"

    # temp-candidates: usage errors exit 2 with a reason on stderr.
    local args
    for args in "--snapshot $TMPF" "$TMPF $FX/temp-before.txt $CMDS" "relative $FX/temp-before.txt - $REPO" \
                "/ $FX/temp-before.txt - $REPO" "$TMPF $FX/no-such-before.txt - $REPO" \
                "$TMPF $FX/temp-before.txt $FX/no-such-cmds $REPO" "$TMPF $FX/temp-before.txt - $FX/no-such-root"; do
        rc=0
        # shellcheck disable=SC2086
        bash "$tc" $args >/dev/null 2>"$WORK/err" || rc=$?
        [[ "$rc" -eq 2 ]] || fail "temp-candidates: [$args] exited $rc, expected 2"
        [[ -s "$WORK/err" ]] || fail "temp-candidates: [$args] gave no reason on stderr"
    done

    slot_checks "$ss"
    return 0
}

# run_slot_only <suite-slots script>: the wrapper's fixtures alone, for the
# wrapper's mutants. Sets $failures as run_checks does.
run_slot_only() {
    failures=0
    runs=$((runs + 1))
    slot_checks "$1"
    return 0
}

# --- Self-test ----------------------------------------------------------------

# mutate <source> <copy> <sed program> <name>: writes the mutant and exits 2
# when the program changed nothing.
mutate() {
    local src=$1 copy=$2 prog=$3 name=$4
    sed "$prog" "$src" > "$copy"
    if cmp -s "$src" "$copy"; then
        echo "FAIL  self-test fixture stale: mutant '$name' changed nothing; update its sed program" >&2
        exit 2
    fi
}

run_self_test() {
    local ex="$WORK/extract-acceptance.sh" zd="$WORK/zero-diff.sh" tc="$WORK/temp-candidates.sh" ss="$WORK/suite-slots.sh"
    local m_ex="$WORK/extract-mutant.sh" m_zd="$WORK/zero-diff-mutant.sh" m_tc="$WORK/temp-candidates-mutant.sh"
    local m_ss="$WORK/suite-slots-mutant.sh"
    cp "$EXTRACT_SRC" "$ex"
    cp "$ZERO_SRC" "$zd"
    cp "$TEMP_SRC" "$tc"
    cp "$SLOTS_SRC" "$ss"

    run_checks "$ex" "$zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -ne 0 ]]; then
        echo "FAIL  self-test positive path: $failures assertions failed on the unmutated copies" >&2
        return 1
    fi

    local bad=0 name
    # Mutant 1: the padding stripping removed.
    name="padding stripping removed"
    mutate "$ex" "$m_ex" '/inner = substr(inner, 2, length(inner) - 2)/d' "$name"
    run_checks "$m_ex" "$zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 2: the continuation joining removed.
    name="continuation joining removed"
    mutate "$ex" "$m_ex" '/if (have) cur = cur " " line/d' "$name"
    run_checks "$m_ex" "$zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 3: fenced code blocks no longer skipped.
    name="fence tracking removed"
    mutate "$ex" "$m_ex" 's/^    infence = 1; ofch = fch; oflen = flen; fenceline = NR$/    ofch = fch; oflen = flen; fenceline = NR/' "$name"
    run_checks "$m_ex" "$zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 4: the field argument ignored, so Acceptance is always read.
    name="field argument ignored"
    mutate "$ex" "$m_ex" 's/-v field="\$field"/-v field=Acceptance/' "$name"
    run_checks "$m_ex" "$zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 5: the span-led test dropped, so the second line is always none.
    name="span-led test dropped"
    mutate "$ex" "$m_ex" '/led = led (led == ""/d' "$name"
    run_checks "$m_ex" "$zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 6: the paths passed to git diff as one word.
    name="paths read as one word"
    mutate "$zd" "$m_zd" 's/HEAD -- "\${specs\[@\]}"/HEAD -- "${specs[*]}"/' "$name"
    run_checks "$ex" "$m_zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 7: the exclusion dropped, so a ! path is compared as a plain
    # path.
    name="exclusion dropped"
    mutate "$zd" "$m_zd" 's/=":(exclude,literal)/=":(literal)/' "$name"
    run_checks "$ex" "$m_zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 8: the literal magic dropped, so a bracket is a glob again.
    name="literal magic dropped"
    mutate "$zd" "$m_zd" 's/=":(exclude,literal)/=":(exclude)/; s/=":(literal)\$p"/="$p"/' "$name"
    run_checks "$ex" "$m_zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 9: the before list no longer filters, so entries older than the
    # batch are listed.
    name="before-list filter removed"
    mutate "$tc" "$m_tc" 's/if grep -qxF -- "\$name" "\$before"; then/if false; then/' "$name"
    run_checks "$ex" "$zd" "$m_tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 10: any clone counts, whatever its origin.
    name="origin comparison removed"
    mutate "$tc" "$m_tc" 's/if \[ "\$p" = "\$r" \]; then/if :; then/' "$name"
    run_checks "$ex" "$zd" "$m_tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 11: a symbolic link is judged by what it points to.
    name="symlink exclusion removed"
    mutate "$tc" "$m_tc" 's/if \[ ! -L "\$e" \] && \[ -O "\$e" \]; then/if [ -O "$e" ]; then/' "$name"
    run_checks "$ex" "$zd" "$m_tc" "$ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # The wrapper's four mutants run the wrapper's fixtures alone: the other
    # scripts' fixtures cannot see a change to the wrapper, and each full
    # pass pays the wrapper fixtures' sleeps again.

    # Mutant 12: every caller enters, whatever the count.
    name="count check always true"
    mutate "$ss" "$m_ss" 's/if \[ "\$live" -lt "\$limit" \]; then # count check/if true; then # count check/' "$name"
    run_slot_only "$m_ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 13: a stale holder is counted as live, never reclaimed.
    name="stale-holder reclaim removed"
    mutate "$ss" "$m_ss" 's/if holder_alive; then # live-holder check/if true; then # live-holder check/' "$name"
    run_slot_only "$m_ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 14: the holder file outlives the wrapper.
    name="release on exit removed"
    mutate "$ss" "$m_ss" 's/\[ "\$holder_written" -eq 1 \] && rm -f "\$holder" # release on exit/: # release on exit/' "$name"
    run_slot_only "$m_ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 15: a nested call waits for a slot like any other.
    name="nesting check removed"
    mutate "$ss" "$m_ss" 's/if \[ "\${KENSPC_SUITE_SLOT_HELD:-}" = 1 \]; then/if false; then/' "$name"
    run_slot_only "$m_ss" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Restoration path: green again on the unmutated copies.
    run_checks "$ex" "$zd" "$tc" "$ss" 2>/dev/null
    if [[ "$failures" -ne 0 ]]; then
        echo "FAIL  self-test restoration path: $failures assertions failed on the unmutated copies" >&2
        return 1
    fi

    [[ "$bad" -eq 0 ]] || return 1
    echo "OK    self-test passed for $(basename "$0")"
    return 0
}

# --- Dispatch -----------------------------------------------------------------

if [[ "${1:-}" == "--self-test" ]]; then
    rc=0
    run_self_test || rc=$?
    exit "$rc"
fi

run_checks "$EXTRACT_SRC" "$ZERO_SRC" "$TEMP_SRC" "$SLOTS_SRC"
if [[ "$failures" -ne 0 ]]; then
    echo "autopilot-scripts — $failures assertions failed" >&2
    exit 1
fi
echo "OK    autopilot-scripts — extract-acceptance.sh, zero-diff.sh, temp-candidates.sh, and suite-slots.sh behave as their fixtures expect"
exit 0
