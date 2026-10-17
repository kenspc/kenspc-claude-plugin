#!/usr/bin/env bash
# check-review-agent-drift.sh
#
# Verifies that the 5 review-angle agents share byte-identical CONTEXT YOU
# WILL RECEIVE, ROLE, PREREQUISITES, CUSTOM INSTRUCTIONS, FILE COVERAGE, and
# REPORT DELIVERY sections. Project CLAUDE.md flags drift between these
# sections as a bug; this script is the mechanical guard. ROLE, CONTEXT YOU
# WILL RECEIVE, and REPORT DELIVERY joined in v3.5.0: they carry the RUN_DIR
# contract and the reviewers' one permitted write. It also checks that each
# reviewer's frontmatter holds the standalone warning sentence (4.9.0),
# which the shared sections do not cover: a reviewer that dropped it would
# again invite five standalone dispatches at once, each running the full
# suite.
#
# Exit code 0: all shared sections byte-identical across all 5 files, and
#              the standalone warning in each one's frontmatter.
# Exit code 1: drift detected. The first diverging section is printed via
#              diff; a reviewer without the warning is named.
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

SECTIONS=("CONTEXT YOU WILL RECEIVE" "ROLE" "PREREQUISITES" "CUSTOM INSTRUCTIONS" "FILE COVERAGE" "REPORT DELIVERY")

STANDALONE_WARNING="Invoked standalone (without RUN_DIR) it runs the project's full test suite itself, so dispatch one at a time or use /kenspc-task-review."

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

# The standalone warning, in the frontmatter between the first two `---`
# lines.
for f in "${FILES[@]}"; do
    frontmatter=$(awk 'NR == 1 && $0 == "---" { fm = 1; next } fm && $0 == "---" { exit } fm' "$f")
    if [[ "$frontmatter" != *"$STANDALONE_WARNING"* ]]; then
        drift_found=1
        echo "DRIFT standalone warning — not in the frontmatter of $f" >&2
    fi
done
if [[ "$drift_found" -eq 0 ]]; then
    echo "OK    standalone warning — in the frontmatter of all 5 reviewers"
fi

if [[ "$drift_found" -ne 0 ]]; then
    echo "" >&2
    echo "Drift detected. The 5 review-angle agents must keep their shared" >&2
    echo "sections (${SECTIONS[*]}) byte-identical (per project CLAUDE.md" >&2
    echo "maintenance note). Apply the same edit to all 5 files." >&2
    exit 1
fi

echo ""
echo "All ${#SECTIONS[@]} shared sections are byte-identical across the 5 review-angle agents."
