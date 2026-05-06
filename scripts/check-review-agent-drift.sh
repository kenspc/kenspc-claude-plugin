#!/usr/bin/env bash
# check-review-agent-drift.sh
#
# Verifies that the 5 review-angle agents share byte-identical PREREQUISITES,
# FILE COVERAGE, and CUSTOM INSTRUCTIONS sections. Project CLAUDE.md flags
# drift between these sections as a bug; this script is the mechanical guard.
#
# Exit code 0: all 3 sections byte-identical across all 5 files.
# Exit code 1: drift detected. The first diverging section is printed via diff.
#
# Run from the repository root (or any directory — paths are resolved relative
# to this script's location).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

AGENTS_DIR="$REPO_ROOT/plugins/kenspc/agents"
FILES=(
    "$AGENTS_DIR/requirements-reviewer.md"
    "$AGENTS_DIR/edge-case-reviewer.md"
    "$AGENTS_DIR/quality-reviewer.md"
    "$AGENTS_DIR/bug-reviewer.md"
    "$AGENTS_DIR/test-reviewer.md"
)

SECTIONS=("PREREQUISITES" "FILE COVERAGE" "CUSTOM INSTRUCTIONS")

# Extract a named section from a reviewer agent file.
# A section starts at a line whose entire content equals the section name
# (uppercase) and ends just before the next ALL-CAPS heading line (with
# optional " (...)" suffix) or at EOF. Heading lines themselves are excluded
# so the comparison is content-only.
extract_section() {
    local file="$1"
    local section="$2"
    awk -v sect="$section" '
        $0 == sect          { in_sect = 1; next }
        in_sect && /^[A-Z][A-Z ]+[A-Z]( \(.*\))?$/ { exit }
        in_sect
    ' "$file"
}

drift_found=0

for sect in "${SECTIONS[@]}"; do
    declare -a hashes=()
    declare -a hash_to_file=()

    for f in "${FILES[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            exit 2
        fi
        block=$(extract_section "$f" "$sect")
        if [[ -z "$block" ]]; then
            echo "ERROR: section '$sect' is empty in $f" >&2
            exit 2
        fi
        hash=$(printf '%s' "$block" | sha256sum | awk '{print $1}')
        hashes+=("$hash")
        hash_to_file+=("$hash:$f")
    done

    unique_hashes=$(printf '%s\n' "${hashes[@]}" | sort -u)
    unique_count=$(echo "$unique_hashes" | wc -l)

    if [[ "$unique_count" -eq 1 ]]; then
        echo "OK    $sect — identical across 5 reviewers"
    else
        drift_found=1
        echo "DRIFT $sect — $unique_count distinct hashes across 5 reviewers" >&2
        # Show which file(s) diverge by picking the most common hash as the
        # "majority" and diffing each minority file against the first majority
        # file.
        majority_hash=$(printf '%s\n' "${hashes[@]}" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
        majority_file=""
        for entry in "${hash_to_file[@]}"; do
            if [[ "$entry" == "$majority_hash:"* ]]; then
                majority_file="${entry#*:}"
                break
            fi
        done
        echo "      majority: $majority_file" >&2
        for entry in "${hash_to_file[@]}"; do
            entry_hash="${entry%%:*}"
            entry_file="${entry#*:}"
            if [[ "$entry_hash" != "$majority_hash" ]]; then
                echo "      diff vs $entry_file:" >&2
                diff <(extract_section "$majority_file" "$sect") \
                     <(extract_section "$entry_file" "$sect") >&2 || true
            fi
        done
    fi
done

if [[ "$drift_found" -ne 0 ]]; then
    echo "" >&2
    echo "Drift detected. The 5 review-angle agents must keep PREREQUISITES," >&2
    echo "FILE COVERAGE, and CUSTOM INSTRUCTIONS byte-identical (per project" >&2
    echo "CLAUDE.md maintenance note). Apply the same edit to all 5 files." >&2
    exit 1
fi

echo ""
echo "All 3 shared sections are byte-identical across the 5 review-angle agents."
