#!/usr/bin/env bash
# check-canonical-dispatch.sh
#
# Verifies that the canonical "Code Review Phase (unconditional)" dispatch
# block is byte-identical between task-review/SKILL.md and
# task-implement/SKILL.md. The block is delimited by HTML comment markers
# <!-- canonical:dispatch:start --> and <!-- canonical:dispatch:end -->.
#
# Replaces the magic-number pipeline `grep -A 20 ... | head -25` from v3.0
# AC7. The marker-bounded approach catches drift regardless of where the
# divergence appears inside the block.
#
# Exit code 0: bytes match.
# Exit code 1: drift detected. The diff is printed to stderr.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REVIEW_FILE="$REPO_ROOT/plugins/kenspc/skills/task-review/SKILL.md"
IMPL_FILE="$REPO_ROOT/plugins/kenspc/skills/task-implement/SKILL.md"

extract_block() {
    local file="$1"
    sed -n '/<!-- canonical:dispatch:start -->/,/<!-- canonical:dispatch:end -->/p' "$file"
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

review_hash=$(extract_block "$REVIEW_FILE" | sha256sum | awk '{print $1}')
impl_hash=$(extract_block "$IMPL_FILE" | sha256sum | awk '{print $1}')

if [[ "$review_hash" == "$impl_hash" ]]; then
    echo "OK    canonical:dispatch — task-review and task-implement byte-identical"
    echo "      sha256: $review_hash"
    exit 0
fi

echo "DRIFT canonical:dispatch — task-review and task-implement diverge" >&2
echo "      task-review.md sha256:    $review_hash" >&2
echo "      task-implement.md sha256: $impl_hash" >&2
echo "" >&2
echo "Diff (task-review.md vs task-implement.md):" >&2
diff <(extract_block "$REVIEW_FILE") <(extract_block "$IMPL_FILE") >&2 || true
echo "" >&2
echo "The canonical dispatch block must be byte-identical between the two" >&2
echo "skills. Apply the same edit to both files." >&2
exit 1
