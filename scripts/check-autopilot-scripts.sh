#!/usr/bin/env bash
# check-autopilot-scripts.sh
#
# Behavior guard for the two helper scripts the autopilot skill ships beside
# its driver:
#
#   1. plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh
#        writes each `Acceptance:` case of a spec's `## Autopilot` section to
#        <nn>.cmd (one code span) or <nn>.case (a description)
#   2. plugins/kenspc/skills/autopilot/scripts/zero-diff.sh
#        compares a list of paths between a baseline and HEAD
#
# Both replaced steps every main session used to write by hand, and both went
# wrong that way: commands extracted with a stray backtick at each end, and a
# zero-diff check whose paths arrived as one word and compared nothing. This
# guard runs the scripts against fixtures built in a mktemp -d directory —
# single and double backticks, a backtick inside a double-backtick span, spans
# with and without the padding spaces, a label with a note, an `(optional)`
# case, a description case, a continuation line, `Acceptance: none`, no
# section, no field, inline text on the label line, an empty field; a path
# with a space, a changed path, an unchanged path, a path absent at the
# baseline, paths with a space before or after them, a path holding glob
# characters, an empty paths file — and asserts each outcome.
#
# Exit code 0: every assertion held.
# Exit code 1: at least one assertion failed (each is printed on stderr).
# Exit code 2: a script under test is missing, or a self-test mutation did not
#              apply (the fixture is stale).
#
# Optional flag:
#   --self-test    Copies both scripts into the temp directory and turns the
#                  guard red with three mutants of the copies — the padding
#                  stripping removed from the extractor, its continuation
#                  joining removed, and zero-diff.sh's paths passed to git diff
#                  as one word — each of which must make the guard exit 1,
#                  then green again on the unmutated copies.
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

for f in "$EXTRACT_SRC" "$ZERO_SRC"; do
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
- Acceptance (in the order listed, one at a time):
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
printf '# Spec\n\n## Implementation Steps\n\n- Acceptance: none\n' > "$FX/spec-nosection.md"
printf '# Spec\n\n## Autopilot\n\n- Budget: USD 10\n' > "$FX/spec-nofield.md"
printf '# Spec\n\n## Autopilot\n\n- Acceptance: run the suite\n- Budget: USD 10\n' > "$FX/spec-inline.md"
printf '# Spec\n\n## Autopilot\n\n- Acceptance:\n- Budget: USD 10\n' > "$FX/spec-emptyfield.md"

# A repository whose baseline holds five files; one commit after it changes
# the file whose name holds a space and xy.txt, which the glob x[y].txt would
# match.
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
git -C "$REPO" add -A
git -C "$REPO" commit -q -m baseline
BASE=$(git -C "$REPO" rev-parse HEAD)
printf 'b2\n' >> "$REPO/with space.txt"
printf 'y2\n' >> "$REPO/xy.txt"
git -C "$REPO" commit -q -am change

printf 'a.txt\nc.txt\n' > "$FX/paths-unchanged.txt"
printf 'a.txt\n\nwith space.txt\n' > "$FX/paths-changed.txt"
printf 'absent.txt\na.txt\n' > "$FX/paths-absent.txt"
printf ' with space.txt\na.txt \n' > "$FX/paths-padded.txt"
printf 'x[y].txt\n' > "$FX/paths-glob.txt"
: > "$FX/paths-empty.txt"

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

# run_checks <extract script> <zero-diff script>
# Sets $failures to the number of assertions that failed.
run_checks() {
    local ex=$1 zd=$2 out rc listing
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

    # Acceptance: none.
    out="$WORK/out-$runs-none"
    rc=0
    stdout=$(bash "$ex" "$FX/spec-none.md" "$out" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "extract: none fixture exited $rc, expected 0"
    [[ "$stdout" == "commands: 0, cases: 0" ]] || fail "extract: none fixture printed [$stdout]"
    listing=$(cd "$out" 2>/dev/null && ls -A | tr '\n' ' ') || listing="(no out dir)"
    [[ -z "$listing" ]] || fail "extract: none fixture wrote [$listing]"

    # No section, no field, inline text on the label line, and an empty
    # field: exit 2 with a reason on stderr, and no file written.
    local spec
    for spec in spec-nosection spec-nofield spec-inline spec-emptyfield; do
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

    # zero-diff: an unchanged path holding glob characters is read literally,
    # so the changed xy.txt it would match as a glob is not compared.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-glob.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: glob-character path exited $rc, expected 0"
    [[ "$stdout" == "compared: 1 paths" ]] || fail "zero-diff: glob-character path printed [$stdout]"

    # zero-diff: a path absent at the baseline is named on stderr.
    rc=0
    stdout=$(cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-absent.txt" 2>"$WORK/err") || rc=$?
    [[ "$rc" -eq 0 ]] || fail "zero-diff: absent path exited $rc, expected 0"
    grep -qF 'absent.txt' "$WORK/err" || fail "zero-diff: the absent path is not named on stderr"
    [[ "$stdout" == "compared: 2 paths" ]] || fail "zero-diff: absent path printed [$stdout]"

    # zero-diff: an empty paths file is a usage error.
    rc=0
    (cd "$REPO" && bash "$zd" "$BASE" "$FX/paths-empty.txt") >/dev/null 2>&1 || rc=$?
    [[ "$rc" -eq 2 ]] || fail "zero-diff: empty paths file exited $rc, expected 2"

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
    local ex="$WORK/extract-acceptance.sh" zd="$WORK/zero-diff.sh"
    local m_ex="$WORK/extract-mutant.sh" m_zd="$WORK/zero-diff-mutant.sh"
    cp "$EXTRACT_SRC" "$ex"
    cp "$ZERO_SRC" "$zd"

    run_checks "$ex" "$zd" 2>/dev/null
    if [[ "$failures" -ne 0 ]]; then
        echo "FAIL  self-test positive path: $failures assertions failed on the unmutated copies" >&2
        return 1
    fi

    local bad=0 name
    # Mutant 1: the padding stripping removed.
    name="padding stripping removed"
    mutate "$ex" "$m_ex" '/inner = substr(inner, 2, length(inner) - 2)/d' "$name"
    run_checks "$m_ex" "$zd" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 2: the continuation joining removed.
    name="continuation joining removed"
    mutate "$ex" "$m_ex" '/if (have) cur = cur " " line/d' "$name"
    run_checks "$m_ex" "$zd" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Mutant 3: the paths passed to git diff as one word.
    name="paths read as one word"
    mutate "$zd" "$m_zd" 's/HEAD -- "\${paths\[@\]}"/HEAD -- "${paths[*]}"/' "$name"
    run_checks "$ex" "$m_zd" 2>/dev/null
    if [[ "$failures" -gt 0 ]]; then echo "OK    mutant '$name': red ($failures assertions failed)"; else echo "FAIL  mutant '$name': the guard stayed green" >&2; bad=1; fi

    # Restoration path: green again on the unmutated copies.
    run_checks "$ex" "$zd" 2>/dev/null
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

run_checks "$EXTRACT_SRC" "$ZERO_SRC"
if [[ "$failures" -ne 0 ]]; then
    echo "autopilot-scripts — $failures assertions failed" >&2
    exit 1
fi
echo "OK    autopilot-scripts — extract-acceptance.sh and zero-diff.sh behave as their fixtures expect"
exit 0
