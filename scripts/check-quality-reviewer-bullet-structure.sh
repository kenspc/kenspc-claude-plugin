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
# Exit code 2: structural error (bullet anchor not found, file missing).
#
# Modeled on check-code-craft-canonical.sh; same set -euo pipefail
# discipline and same SCRIPT_DIR / REPO_ROOT derivation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

QUALITY_REVIEWER_FILE="$REPO_ROOT/plugins/kenspc/agents/quality-reviewer.md"

# Each BULLETS entry is "anchor_regex|expected_condition_count|qualifier_regex".
# - anchor_regex   : ERE that uniquely matches the first line of the bullet.
# - expected_count : integer; the number of `N.` numbered items inside the
#                    bullet body that must be present.
# - qualifier_regex: ERE that must match at least once inside the bullet
#                    body (the "**all three**" gate).
BULLETS=(
    "^- Over-engineering:|3|\\*\\*all three\\*\\*"
    "^- Drive-by refactoring and style drift|3|\\*\\*all three\\*\\*"
)

if [[ ! -f "$QUALITY_REVIEWER_FILE" ]]; then
    echo "ERROR: missing file $QUALITY_REVIEWER_FILE" >&2
    exit 2
fi

# Slice the bullet body: from the anchor line, inclusive, up to (but not
# including) the next blank line. awk handles this cleanly without sed
# arithmetic. Output is empty if anchor not found.
slice_bullet() {
    local file="$1"
    local anchor_regex="$2"
    awk -v re="$anchor_regex" '
        $0 ~ re { collecting = 1 }
        collecting && /^$/ { exit }
        collecting { print }
    ' "$file"
}

failure_found=0

for spec in "${BULLETS[@]}"; do
    anchor="${spec%%|*}"
    rest="${spec#*|}"
    expected="${rest%%|*}"
    qualifier="${rest#*|}"

    # Locate the first line via grep -nE; absence is a structural error.
    line_no=$(grep -nE -- "$anchor" "$QUALITY_REVIEWER_FILE" | head -1 | cut -d: -f1 || true)
    if [[ -z "$line_no" ]]; then
        echo "ERROR: bullet anchor not found in $QUALITY_REVIEWER_FILE" >&2
        echo "       anchor regex: $anchor" >&2
        exit 2
    fi

    body=$(slice_bullet "$QUALITY_REVIEWER_FILE" "$anchor")
    if [[ -z "$body" ]]; then
        echo "ERROR: bullet body empty in $QUALITY_REVIEWER_FILE (anchor matched but slice yielded no lines)" >&2
        echo "       anchor regex: $anchor" >&2
        exit 2
    fi

    # Count numbered conditions inside the slice. grep returns 1 on no
    # match under pipefail; tolerate via `|| true` and let the comparison
    # surface the failure with context.
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
    exit 1
fi

echo "OK    quality-reviewer.md REVIEW CHECKLIST bullet structure — both bullets have 3 conditions gated by **all three**"
exit 0
