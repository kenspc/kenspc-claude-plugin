#!/usr/bin/env bash
# check-quality-reviewer-bullet-structure.sh
#
# Structural guard for the two new REVIEW CHECKLIST bullets in
# plugins/kenspc/agents/quality-reviewer.md that ship with v3.1.0:
#
#   1. "Over-engineering: ..."                       -> 3 numbered conditions
#   2. "Drive-by refactoring and style drift ..."    -> 3 numbered conditions
#
# Each bullet gates its flagging behaviour on **all three** of three
# numbered conditions. A future edit that adds a fourth condition, deletes
# one of the three, or weakens the "**all three**" qualifier would silently
# change the bullet's polarity and is the failure mode this guard catches.
#
# For each bullet, the script:
#   - finds the line that starts the bullet (anchor regex),
#   - slices the body from that line to the next blank-line boundary,
#   - counts numbered list items (`^[[:space:]]*[0-9]+\.`) inside the slice,
#   - asserts the count equals the expected number (3),
#   - asserts the qualifier regex matches at least once inside the slice.
#
# Exit code 0: both bullets have exactly 3 numbered conditions gated by
#              the "**all three**" qualifier.
# Exit code 1: count mismatch or qualifier mismatch on at least one bullet.
# Exit code 2: structural error (bullet anchor not found, file missing,
#              or self-test fixture stale).
#
# Modeled on check-code-craft-canonical.sh; same set -euo pipefail
# discipline and same SCRIPT_DIR / REPO_ROOT derivation.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the
#                  quality-reviewer.md file into a temp workdir, runs the
#                  main check (must exit 0), adds a fourth numbered
#                  condition under one of the bullets (must exit 1), then
#                  reverts (must exit 0). Opt-in: invocation with no
#                  arguments behaves unchanged. Exit 0 on self-test pass,
#                  1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Run the structural check against a given repo root. Uses local
# variables so the function can be called multiple times with different
# REPO_ROOTs during --self-test. Returns 0/1/2 via `return` (no `exit`).
run_main_logic() {
    local repo_root="$1"
    local quality_reviewer_file="$repo_root/plugins/kenspc/agents/quality-reviewer.md"

    # Each BULLETS entry is "anchor_regex|expected_condition_count|qualifier_regex".
    # - anchor_regex   : ERE that uniquely matches the first line of the bullet.
    # - expected_count : integer; the number of `N.` numbered items inside the
    #                    bullet body that must be present.
    # - qualifier_regex: ERE that must match at least once inside the bullet
    #                    body (the "**all three**" gate).
    local bullets=(
        "^- Over-engineering:|3|\\*\\*all three\\*\\*"
        "^- Drive-by refactoring and style drift|3|\\*\\*all three\\*\\*"
    )

    if [[ ! -f "$quality_reviewer_file" ]]; then
        echo "ERROR: missing file $quality_reviewer_file" >&2
        return 2
    fi

    # Slice the bullet body: from the anchor line, inclusive, up to (but
    # not including) the next blank line. awk handles this cleanly
    # without sed arithmetic. Output is empty if anchor not found.
    slice_bullet() {
        local file="$1"
        local anchor_regex="$2"
        awk -v re="$anchor_regex" '
            $0 ~ re { collecting = 1 }
            collecting && /^$/ { exit }
            collecting { print }
        ' "$file"
    }

    local failure_found=0
    local spec anchor rest expected qualifier line_no body count
    for spec in "${bullets[@]}"; do
        anchor="${spec%%|*}"
        rest="${spec#*|}"
        expected="${rest%%|*}"
        qualifier="${rest#*|}"

        # Locate the first line via grep -nE; absence is a structural
        # error.
        line_no=$(grep -nE -- "$anchor" "$quality_reviewer_file" | head -1 | cut -d: -f1 || true)
        if [[ -z "$line_no" ]]; then
            echo "ERROR: bullet anchor not found in $quality_reviewer_file" >&2
            echo "       anchor regex: $anchor" >&2
            return 2
        fi

        body=$(slice_bullet "$quality_reviewer_file" "$anchor")
        if [[ -z "$body" ]]; then
            echo "ERROR: bullet body empty in $quality_reviewer_file (anchor matched but slice yielded no lines)" >&2
            echo "       anchor regex: $anchor" >&2
            return 2
        fi

        # Count numbered conditions inside the slice. grep returns 1 on
        # no match under pipefail; tolerate via `|| true` and let the
        # comparison surface the failure with context.
        count=$(printf '%s\n' "$body" | grep -cE '^[[:space:]]*[0-9]+\.' || true)
        if [[ "$count" -ne "$expected" ]]; then
            failure_found=1
            echo "FAIL  bullet (line $line_no): expected $expected numbered conditions, found $count" >&2
            echo "      anchor regex: $anchor" >&2
        fi

        # Qualifier must match at least once inside the slice body.
        if ! printf '%s\n' "$body" | grep -qE -- "$qualifier"; then
            failure_found=1
            echo "FAIL  bullet (line $line_no): qualifier regex did not match inside bullet body" >&2
            echo "      anchor regex:    $anchor" >&2
            echo "      qualifier regex: $qualifier" >&2
        fi
    done

    if [[ "$failure_found" -ne 0 ]]; then
        echo "" >&2
        echo "Structural drift detected in quality-reviewer.md REVIEW CHECKLIST." >&2
        echo "Each of the two bullets must enumerate exactly 3 numbered conditions" >&2
        echo "gated by the '**all three**' qualifier. Restore the structure or, if" >&2
        echo "the gate is intentionally changing, update the BULLETS array in" >&2
        echo "$(basename "$0") in the same commit." >&2
        return 1
    fi

    echo "OK    quality-reviewer.md REVIEW CHECKLIST bullet structure — both bullets have 3 conditions gated by **all three**"
    return 0
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. Copies the quality-reviewer.md file into
# a temp workdir, runs the main check (expect 0), inserts a fourth
# numbered condition (`4. Extra fixture line`) under the over-engineering
# bullet (expect 1, count mismatch), then reverts (expect 0).
run_self_test() {
    # WORK is set as a global (not local) so the EXIT trap can reference
    # it safely after this function returns. Under `set -u`, an EXIT trap
    # that refers to an unset local variable would trigger "unbound
    # variable" at trap-firing time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    # Replicate the relative paths the main logic expects.
    mkdir -p "$WORK/plugins/kenspc/agents"
    cp "$REPO_ROOT/plugins/kenspc/agents/quality-reviewer.md" "$WORK/plugins/kenspc/agents/quality-reviewer.md"

    local target_file="$WORK/plugins/kenspc/agents/quality-reviewer.md"
    # The fixture anchor: the line we look for to know where to insert
    # the extra condition. Inserting after the existing third condition
    # of the over-engineering bullet turns its three-condition gate into
    # four, which is the exact structural drift this guard catches.
    local fixture_anchor='^  3\. Not a boundary validation required by the project'

    # Fixture-stale guard: the insertion anchor must exist in the source.
    if ! grep -qE -- "$fixture_anchor" "$target_file"; then
        echo "FAIL  self-test fixture stale: insertion anchor \"$fixture_anchor\" not found in $target_file. Update the fixture anchor in run_self_test()." >&2
        return 2
    fi

    # Positive path: main check on the unmodified copy must exit 0.
    local rc
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test positive path: expected exit 0 on unmutated copy, got $rc" >&2
        return 1
    fi

    # Apply mutation: insert a fourth numbered condition immediately
    # after the existing third condition of the over-engineering bullet.
    # The new line uses the same two-space indentation as the existing
    # numbered conditions so it matches the `^[[:space:]]*[0-9]+\.`
    # counter in run_main_logic.
    sed -i "/${fixture_anchor}/a\\
  4. Extra fixture condition inserted by self-test." "$target_file"
    if ! grep -qE '^  4\. Extra fixture condition' "$target_file"; then
        echo "FAIL  self-test: mutation did not apply (extra condition not inserted in $target_file)" >&2
        return 2
    fi

    # Negative path: main check on the mutated copy must exit 1.
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path: expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Revert the mutation by recopying the source.
    cp "$REPO_ROOT/plugins/kenspc/agents/quality-reviewer.md" "$target_file"

    # Restoration path: main check on the reverted copy must exit 0.
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test restoration path: expected exit 0 after revert, got $rc" >&2
        return 1
    fi

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
