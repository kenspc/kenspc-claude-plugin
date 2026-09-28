#!/usr/bin/env bash
# check-instruction-files.sh
#
# Guards the plugin-wide definition of "the project's instruction files".
# The definition is written once, in plugins/kenspc/shared/instruction-files.md
# (the reference), and every other file that uses the term carries the same
# sentence, so each agent and skill has it at dispatch time without depending
# on a runtime Read — the reason the writer agents inline the code-craft
# principles (check-code-craft-canonical.sh).
#
# The check:
#
#   - The sentence is taken from the reference: the lines from the first that
#     begins (after indentation) with "The project's instruction files are"
#     through the first line that ends in a period, whitespace-normalized
#     (every run of spaces, tabs, CR, and LF becomes one space).
#   - Carriers are found, not listed: every file under
#     plugins/kenspc/{skills,agents,commands,shared}/ other than the reference
#     whose whitespace-normalized text contains "instruction files"
#     (case-insensitive; the setting name `instructionFiles` has no space and
#     does not match), plus plugins/kenspc/README.md, which defines the term
#     for users. A file that starts using the term without the definition
#     fails, so there is no carrier list to keep current.
#   - Each carrier's whitespace-normalized text contains the sentence, so a
#     copy may wrap or sit in a list item differently from the reference, and
#     a changed word fails.
#
# Exit code 0: every carrier contains the sentence.
# Exit code 1: a carrier lacks it (each is named).
# Exit code 2: missing input, no sentence found in the reference (it moved or
#              was reworded), no carrier found under the scanned directories,
#              or self-test fixture stale.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards; bash 3.2 compatible (no associative arrays, no ${var,,}).
# Self-test mutations use awk rewrites rather than `sed -i`, whose in-place
# syntax differs between GNU and BSD sed.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the scanned
#                  directories and the plugin README into a temp workdir and
#                  checks seven paths: the unmodified copy (must exit 0); one
#                  word changed in requirements-reviewer.md's copy (must exit
#                  1); that copy re-wrapped across a line break (must exit 0);
#                  the term used in commands/kenspc-init.md without the
#                  sentence (must exit 1); the README's copy removed (must
#                  exit 1); the reference's opening words reworded (must exit
#                  2); and the reverted copy (must exit 0). Opt-in: invocation
#                  with no arguments behaves unchanged. Exit 0 on self-test
#                  pass, 1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SCANNED_DIRS=(skills agents commands shared)
REFERENCE_REL="plugins/kenspc/shared/instruction-files.md"
README_REL="plugins/kenspc/README.md"
SENTENCE_START="The project's instruction files are"
TERM_PATTERN="instruction files"

# Print a file whitespace-normalized: every run of spaces, tabs, CR, and LF
# becomes one space, and leading and trailing space is dropped.
normalize_ws() {
    awk '
        { buf = buf " " $0 }
        END {
            gsub(/[ \t\r]+/, " ", buf)
            sub(/^ /, "", buf); sub(/ $/, "", buf)
            printf "%s", buf
        }' "$1"
}

# Print the definition sentence from the reference — the lines from the
# first that begins (after indentation) with SENTENCE_START through the first
# line that ends in a period — whitespace-normalized. Prints nothing when no
# line begins that way.
extract_sentence() {
    awk -v start="$SENTENCE_START" '
        { sub(/\r$/, ""); line = $0; sub(/^[ \t]+/, "", line) }
        !found && index(line, start) == 1 { found = 1 }
        found {
            buf = buf " " $0
            if ($0 ~ /\.[ \t]*$/) exit
        }
        END {
            gsub(/[ \t]+/, " ", buf)
            sub(/^ /, "", buf); sub(/ $/, "", buf)
            printf "%s", buf
        }' "$1"
}

# Run the check against a given repo root. Uses local variables so the
# function can be called multiple times with different REPO_ROOTs during
# --self-test. Returns 0/1/2 via `return` (no `exit`).
run_main_logic() {
    local repo_root="$1"
    local reference="$repo_root/$REFERENCE_REL"
    local readme="$repo_root/$README_REL"
    local dirs=() name f

    for name in "${SCANNED_DIRS[@]}"; do
        dirs+=("$repo_root/plugins/kenspc/$name")
    done
    for f in "${dirs[@]}"; do
        if [[ ! -d "$f" ]]; then
            echo "ERROR: missing directory $f" >&2
            return 2
        fi
    done
    for f in "$reference" "$readme"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
    done

    local sentence
    sentence=$(extract_sentence "$reference")
    if [[ -z "$sentence" ]]; then
        echo "ERROR: no line beginning '$SENTENCE_START' in $reference; the definition moved or was reworded" >&2
        return 2
    fi

    local carriers=() text lower
    while IFS= read -r f; do
        [[ "$f" == "$reference" ]] && continue
        text=$(normalize_ws "$f")
        lower=$(printf '%s' "$text" | tr '[:upper:]' '[:lower:]')
        if [[ "$lower" == *"$TERM_PATTERN"* ]]; then
            carriers+=("$f")
        fi
    done < <(find "${dirs[@]}" -type f | LC_ALL=C sort)

    if [[ "${#carriers[@]}" -eq 0 ]]; then
        echo "ERROR: no file under plugins/kenspc/{skills,agents,commands,shared}/ uses the term '$TERM_PATTERN'; the discovery found nothing to check" >&2
        return 2
    fi
    carriers+=("$readme")

    local missing=0
    for f in "${carriers[@]}"; do
        text=$(normalize_ws "$f")
        if [[ "$text" != *"$sentence"* ]]; then
            echo "DRIFT instruction-files definition — ${f#"$repo_root"/} does not contain it" >&2
            missing=1
        fi
    done
    if [[ "$missing" -ne 0 ]]; then
        echo "" >&2
        echo "Every file that uses \"the project's instruction files\" carries the definition" >&2
        echo "sentence from $REFERENCE_REL, compared whitespace-normalized:" >&2
        echo "  $sentence" >&2
        echo "Bring each file named above back to it, or reword the reference and every" >&2
        echo "copy together." >&2
        return 1
    fi

    echo "OK    instruction-files — ${#carriers[@]} carriers hold the definition from $REFERENCE_REL"
    return 0
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. The exit-1 mutations prove a changed word, a
# new carrier without the sentence, and a removed copy each fail; the exit-0
# re-wrap proves the comparison ignores line breaks; the exit-2 mutation
# proves a moved reference is reported rather than read as an empty sentence
# every file trivially contains.
run_self_test() {
    # WORK is global (not local) so the EXIT trap can reference it safely
    # after this function returns. Under `set -u`, an EXIT trap that refers
    # to an unset local triggers an "unbound variable" error at fire time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    mkdir -p "$WORK/plugins/kenspc"
    local name
    for name in "${SCANNED_DIRS[@]}"; do
        cp -R "$REPO_ROOT/plugins/kenspc/$name" "$WORK/plugins/kenspc/$name"
    done
    cp "$REPO_ROOT/$README_REL" "$WORK/$README_REL"

    local reviewer_rel="plugins/kenspc/agents/requirements-reviewer.md"
    local command_rel="plugins/kenspc/commands/kenspc-init.md"
    local word_literal="Claude Code loaded them"

    # Fixture-stale guards: each mutation needs its literal on one line.
    if ! grep -qF -- "$word_literal" "$WORK/$reviewer_rel"; then
        echo "FAIL  self-test fixture stale: \"$word_literal\" not on one line in $reviewer_rel. Update run_self_test()." >&2
        return 2
    fi
    if ! grep -qF -- "$SENTENCE_START" "$WORK/$README_REL"; then
        echo "FAIL  self-test fixture stale: \"$SENTENCE_START\" not on one line in $README_REL. Update run_self_test()." >&2
        return 2
    fi
    if ! grep -qF -- "$SENTENCE_START" "$WORK/$REFERENCE_REL"; then
        echo "FAIL  self-test fixture stale: \"$SENTENCE_START\" not found in $REFERENCE_REL. Update run_self_test()." >&2
        return 2
    fi
    if grep -qiF -- "$TERM_PATTERN" "$WORK/$command_rel"; then
        echo "FAIL  self-test fixture stale: $command_rel already uses the term. Pick another command in run_self_test()." >&2
        return 2
    fi

    local rc

    # expect <expected-rc> <label> <rel-path>: run the check on the workdir
    # and compare its exit code; then restore the mutated file.
    expect() {
        ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
        cp "$REPO_ROOT/$3" "$WORK/$3"
        if [[ "$rc" -ne "$1" ]]; then
            echo "FAIL  self-test $2 path: expected exit $1, got $rc" >&2
            return 1
        fi
    }

    # rewrite <rel-path> <from> <to>: replace the first line-local occurrence
    # of <from> with <to> (awk; <to> may hold "\n").
    rewrite() {
        awk -v from="$2" -v to="$3" '
            !done && (i = index($0, from)) {
                $0 = substr($0, 1, i - 1) to substr($0, i + length(from))
                done = 1
            }
            { print }' "$REPO_ROOT/$1" > "$WORK/$1"
    }

    expect 0 "positive" "$reviewer_rel" || return 1

    rewrite "$reviewer_rel" "$word_literal" "Claude Code read them"
    expect 1 "changed-word" "$reviewer_rel" || return 1

    rewrite "$reviewer_rel" "$word_literal" "Claude Code\n  loaded them"
    expect 0 "re-wrapped copy" "$reviewer_rel" || return 1

    printf '%s\n' "It reads the project's instruction files first." >> "$WORK/$command_rel"
    expect 1 "new carrier without the sentence" "$command_rel" || return 1

    awk -v start="$SENTENCE_START" '
        !gone && index($0, start) { skipping = 1 }
        skipping { if ($0 ~ /this session\./) { skipping = 0; gone = 1 }; next }
        { print }' "$REPO_ROOT/$README_REL" > "$WORK/$README_REL"
    expect 1 "README copy removed" "$README_REL" || return 1

    rewrite "$REFERENCE_REL" "$SENTENCE_START" "The project's instruction documents are"
    expect 2 "reference moved" "$REFERENCE_REL" || return 1

    expect 0 "restoration" "$reviewer_rel" || return 1

    echo "OK    self-test passed for $(basename "$0")"
    return 0
}

# --- Dispatch ---------------------------------------------------------------

if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit $?
fi

run_main_logic "$REPO_ROOT"
exit $?
