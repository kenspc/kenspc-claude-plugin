#!/usr/bin/env bash
# check-canonical-dispatch.sh
#
# Dual check on the canonical "Code Review Phase (unconditional)" dispatch
# block in task-review/SKILL.md and task-implement/SKILL.md:
#
#   1. byte-identity — the block (delimited by HTML comment markers
#      <!-- canonical:dispatch:start --> / <!-- canonical:dispatch:end -->)
#      must be byte-identical between the two files.
#   2. anchor phrase frequency — a small set of load-bearing phrases must
#      appear at or above a minimum count inside the canonical block of
#      each file. Removing one of these phrases (e.g., dropping
#      "unconditional" from the section heading) lets the byte-identity
#      check pass after a synchronized edit while quietly eroding the
#      anchor — the frequency assertion is the guard against that.
#
# Exit code 0: both checks pass.
# Exit code 1: drift detected (byte-identity diff or missing anchor).
# Exit code 2: missing input file / markers.
#
# Anchor list and lower bounds (post-v3.0.3 P0.2 baseline grep):
#   unconditional    >= 1
#   single message   >= 1
#   5 subagents      >= 1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REVIEW_FILE="$REPO_ROOT/plugins/kenspc/skills/task-review/SKILL.md"
IMPL_FILE="$REPO_ROOT/plugins/kenspc/skills/task-implement/SKILL.md"

# Anchor phrases: "phrase|min_count" pairs. The phrase is matched
# case-insensitively as a literal (grep -F -i) inside the canonical
# block of each SKILL.
ANCHORS=(
    "unconditional|1"
    "single message|1"
    "5 subagents|1"
)

extract_block() {
    local file="$1"
    sed -n '/<!-- canonical:dispatch:start -->/,/<!-- canonical:dispatch:end -->/p' "$file"
}

count_phrase() {
    # Count occurrences of a literal phrase (case-insensitive) in stdin.
    # grep returns 1 on no match, which under `set -o pipefail` would
    # collapse the pipeline; tolerate that explicitly so a 0 count is
    # reported as "0" instead of failing the script.
    local phrase="$1"
    local n
    n=$(grep -F -i -o -- "$phrase" || true)
    if [[ -z "$n" ]]; then
        echo 0
    else
        printf '%s\n' "$n" | wc -l | tr -d ' '
    fi
}

for f in "$REVIEW_FILE" "$IMPL_FILE"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing file $f" >&2
        exit 2
    fi
    block=$(extract_block "$f")
    if [[ -z "$block" ]]; then
        echo "ERROR: canonical:dispatch markers not found in $f" >&2
        exit 2
    fi
done

# ---- Check 1: byte-identity ----
review_hash=$(extract_block "$REVIEW_FILE" | sha256sum | awk '{print $1}')
impl_hash=$(extract_block "$IMPL_FILE" | sha256sum | awk '{print $1}')

byte_identity_ok=1
if [[ "$review_hash" == "$impl_hash" ]]; then
    echo "OK    canonical:dispatch byte-identity — task-review and task-implement match"
    echo "      sha256: $review_hash"
else
    byte_identity_ok=0
    echo "DRIFT canonical:dispatch byte-identity — task-review and task-implement diverge" >&2
    echo "      task-review.md sha256:    $review_hash" >&2
    echo "      task-implement.md sha256: $impl_hash" >&2
    echo "" >&2
    echo "Diff (task-review.md vs task-implement.md):" >&2
    diff <(extract_block "$REVIEW_FILE") <(extract_block "$IMPL_FILE") >&2 || true
    echo "" >&2
    echo "The canonical dispatch block must be byte-identical between the two" >&2
    echo "skills. Apply the same edit to both files." >&2
fi

# ---- Check 2: anchor phrase frequency ----
anchor_ok=1
for spec in "${ANCHORS[@]}"; do
    phrase="${spec%|*}"
    min="${spec##*|}"
    for f in "$REVIEW_FILE" "$IMPL_FILE"; do
        count=$(extract_block "$f" | count_phrase "$phrase")
        if [[ "$count" -lt "$min" ]]; then
            anchor_ok=0
            echo "MISSING anchor '$phrase' in $f canonical block: found $count, expected >= $min" >&2
        fi
    done
done

if [[ "$anchor_ok" -eq 1 ]]; then
    echo "OK    canonical:dispatch anchor phrases — all minimum counts met in both files"
else
    echo "" >&2
    echo "One or more anchor phrases dropped below their minimum count inside" >&2
    echo "the canonical:dispatch block. Restore the phrasing in both SKILL.md" >&2
    echo "files (edits must remain byte-identical between them)." >&2
fi

if [[ "$byte_identity_ok" -eq 1 && "$anchor_ok" -eq 1 ]]; then
    exit 0
fi
exit 1
