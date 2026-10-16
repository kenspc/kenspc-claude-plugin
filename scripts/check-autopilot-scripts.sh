#!/usr/bin/env bash
# check-autopilot-scripts.sh
#
# Behavior guard for the three helper scripts the autopilot skill ships
# beside its driver:
#
#   1. plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh
#        writes each `Acceptance:` case of a spec's `## Autopilot` section to
#        <nn>.cmd (one code span) or <nn>.case (a description)
#   2. plugins/kenspc/skills/autopilot/scripts/zero-diff.sh
#        compares a list of paths between a baseline and HEAD
#   3. plugins/kenspc/skills/autopilot/scripts/temp-candidates.sh
#        snapshots a temp folder, and lists the batch's own new entries in it
#
# The first two replaced steps every main session used to write by hand, and
# both went wrong that way: commands extracted with a stray backtick at each
# end, and a zero-diff check whose paths arrived as one word and compared
# nothing. The third decides what the main session removes with a recursive
# rm, so a rule that drifts toward listing too much must turn the guard red:
# its fixtures hold entries made before the batch, another repository's
# clone, another track's prefix, and a symlink, none of which may be listed.
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
# the field, an unclosed fence), the wrong arguments, an unreadable spec; a path
# with a space, a changed path, an unchanged path, a path absent at the
# baseline, paths with a space before or after them, a path holding glob
# characters, a paths file with CRLF line ends, a long changed path, an empty
# paths file, one of whitespace-only lines, a baseline that is not a commit, a
# last line without a newline, a run from a subdirectory; a temp folder and its
# before list, a cmds dir, the repository, another repository, and a seed for
# the sweep — and asserts each outcome.
#
# Exit code 0: every assertion held.
# Exit code 1: at least one assertion failed (each is printed on stderr).
# Exit code 2: a script under test is missing, or a self-test mutation did not
#              apply (the fixture is stale).
#
# Optional flag:
#   --self-test    Copies the three scripts into the temp directory and turns
#                  the guard red with seven mutants of the copies — the padding
#                  stripping removed from the extractor, its continuation
#                  joining removed, its fence tracking removed, zero-diff.sh's
#                  paths passed to git diff
#                  as one word, and temp-candidates.sh's before-list filter,
#                  origin comparison, and symlink exclusion each removed —
#                  each of which must make the guard exit 1, then green again
#                  on the unmutated copies.
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

for f in "$EXTRACT_SRC" "$ZERO_SRC" "$TEMP_SRC"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing script $f" >&2
        exit 2
    fi
done

WORK=$(mktemp -d)
trap 'rm -rf "${WORK:-}"' EXIT

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
git -C "$REPO" add -A
git -C "$REPO" commit -q -m baseline
BASE=$(git -C "$REPO" rev-parse HEAD)
printf 'b2\n' >> "$REPO/with space.txt"
printf 'y2\n' >> "$REPO/xy.txt"
printf 'l2\n' >> "$REPO/$LONG"
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

# run_checks <extract script> <zero-diff script> <temp-candidates script>
# Sets $failures to the number of assertions that failed.
run_checks() {
    local ex=$1 zd=$2 tc=$3 out rc listing
    failures=0
    runs=$((runs + 1))

    # The cases fixture.
    out="$WORK/out-$runs-cases"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-cases.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: cases fixture exited $rc, expected 0 ($(cat "$WORK/err"))"
    [[ "$stdout" == "commands: 7, cases: 1" ]] || fail "extract: cases fixture printed [$stdout], expected [commands: 7, cases: 1]"
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
    [[ "$stdout" == "commands: 0, cases: 2" ]] || fail "extract: spans fixture printed [$stdout], expected [commands: 0, cases: 2]"
    expect_content "$out/01.case" '`npm test` passes, then `npm run lint`'
    expect_content "$out/02.case" '`echo x'

    # A deeper-indented bullet is a continuation of its case, and a second
    # ## Autopilot section's field is not read.
    out="$WORK/out-$runs-more"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-more.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: more fixture exited $rc, expected 0"
    [[ "$stdout" == "commands: 1, cases: 1" ]] || fail "extract: more fixture printed [$stdout], expected [commands: 1, cases: 1]"
    listing=$(cd "$out" 2>/dev/null && ls | tr '\n' ' ') || listing="(no out dir)"
    [[ "$listing" == "01.case 02.cmd " ]] || fail "extract: more fixture wrote [$listing]"
    expect_content "$out/02.cmd" 'echo z'

    # Fenced code blocks before and inside the section: the field after
    # them is read, and nothing inside them is.
    out="$WORK/out-$runs-fenced"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-fenced.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: fenced fixture exited $rc, expected 0 ($(cat "$WORK/err"))"
    [[ "$stdout" == "commands: 1, cases: 1" ]] || fail "extract: fenced fixture printed [$stdout], expected [commands: 1, cases: 1]"
    expect_content "$out/01.cmd" 'echo fenced'
    expect_content "$out/02.case" 'run it by hand'

    # A column-0 fence inside the field ends it.
    out="$WORK/out-$runs-fence-ends"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-fence-ends.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: fence-ends fixture exited $rc, expected 0"
    [[ "$stdout" == "commands: 1, cases: 0" ]] || fail "extract: fence-ends fixture printed [$stdout], expected [commands: 1, cases: 0]"
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
    [[ "$stdout" == "commands: 1, cases: 0" ]] || fail "extract: CRLF fixture printed [$stdout]"
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
    [[ "$stdout" == "commands: 0, cases: 0" ]] || fail "extract: none fixture printed [$stdout]"
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
    [[ "$stdout" == "compared: 2 paths" ]] || fail "zero-diff: unchanged paths printed [$stdout]"

    # zero-diff: a changed path whose name holds a space, beside an unchanged
    # one, with a blank line between them.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-changed.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: changed path exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths" ]] \
        || fail "zero-diff: changed path's first line is not [compared: 2 paths]"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: the stat does not name the changed path"

    # zero-diff: a path with a space before it, as a split on a comma leaves
    # it, and one with a space after it are trimmed and compared.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-padded.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: padded paths exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths" ]] \
        || fail "zero-diff: padded paths' first line is not [compared: 2 paths]"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: the stat does not name the padded changed path"
    [[ ! -s "$WORK/err" ]] || fail "zero-diff: padded paths wrote to stderr: $(cat "$WORK/err")"

    # zero-diff: a paths file with CRLF line ends compares the paths without
    # the carriage return, so the changed path is found.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-crlf.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 1 ]] || fail "zero-diff: CRLF paths exited $rc, expected 1"
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths" ]] \
        || fail "zero-diff: CRLF paths' first line is not [compared: 2 paths]"
    printf '%s\n' "$stdout" | grep -qF 'with space.txt' || fail "zero-diff: the stat does not name the changed path of the CRLF list"

    # zero-diff: an unchanged path holding glob characters is read literally,
    # so the changed xy.txt it would match as a glob is not compared.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-glob.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: glob-character path exited $rc, expected 0"
    [[ "$stdout" == "compared: 1 paths" ]] || fail "zero-diff: glob-character path printed [$stdout]"

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
    [[ "$stdout" == "compared: 2 paths" ]] || fail "zero-diff: absent path printed [$stdout]"

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
    [[ "$(printf '%s\n' "$stdout" | head -n 1)" == "compared: 2 paths" ]] \
        || fail "zero-diff: no final newline, from a subdirectory: first line is not [compared: 2 paths]"
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
    local ex="$WORK/extract-acceptance.sh" zd="$WORK/zero-diff.sh" tc="$WORK/temp-candidates.sh"
    local m_ex="$WORK/extract-mutant.sh" m_zd="$WORK/zero-diff-mutant.sh" m_tc="$WORK/temp-candidates-mutant.sh"
    cp "$EXTRACT_SRC" "$ex"
    cp "$ZERO_SRC" "$zd"
    cp "$TEMP_SRC" "$tc"

    run_checks "$ex" "$zd" "$tc" 2>/dev/null
    if [[ "$failures" -ne 0 ]]; then
        echo "FAIL  self-test positive path: $failures assertions failed on the unmutated copies" >&2
        return 1
    fi

    local bad=0 name
    # Mutant 1: the padding stripping removed.
    name="padding stripping removed"
    mutate "$ex" "$m_ex" '/inner = substr(inner, 2, length(inner) - 2)/d' "$name"
    run_checks "$m_ex" "$zd" "$tc" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 2: the continuation joining removed.
    name="continuation joining removed"
    mutate "$ex" "$m_ex" '/if (have) cur = cur " " line/d' "$name"
    run_checks "$m_ex" "$zd" "$tc" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 3: fenced code blocks no longer skipped.
    name="fence tracking removed"
    mutate "$ex" "$m_ex" 's/^    infence = 1; ofch = fch; oflen = flen; fenceline = NR$/    ofch = fch; oflen = flen; fenceline = NR/' "$name"
    run_checks "$m_ex" "$zd" "$tc" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 4: the paths passed to git diff as one word.
    name="paths read as one word"
    mutate "$zd" "$m_zd" 's/HEAD -- "\${paths\[@\]}"/HEAD -- "${paths[*]}"/' "$name"
    run_checks "$ex" "$m_zd" "$tc" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 5: the before list no longer filters, so entries older than the
    # batch are listed.
    name="before-list filter removed"
    mutate "$tc" "$m_tc" 's/if grep -qxF -- "\$name" "\$before"; then/if false; then/' "$name"
    run_checks "$ex" "$zd" "$m_tc" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 6: any clone counts, whatever its origin.
    name="origin comparison removed"
    mutate "$tc" "$m_tc" 's/if \[ "\$p" = "\$r" \]; then/if :; then/' "$name"
    run_checks "$ex" "$zd" "$m_tc" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 7: a symbolic link is judged by what it points to.
    name="symlink exclusion removed"
    mutate "$tc" "$m_tc" 's/if \[ ! -L "\$e" \] && \[ -O "\$e" \]; then/if [ -O "$e" ]; then/' "$name"
    run_checks "$ex" "$zd" "$m_tc" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Restoration path: green again on the unmutated copies.
    run_checks "$ex" "$zd" "$tc" 2>/dev/null
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

run_checks "$EXTRACT_SRC" "$ZERO_SRC" "$TEMP_SRC"
if [[ "$failures" -ne 0 ]]; then
    echo "autopilot-scripts — $failures assertions failed" >&2
    exit 1
fi
echo "OK    autopilot-scripts — extract-acceptance.sh, zero-diff.sh, and temp-candidates.sh behave as their fixtures expect"
exit 0
