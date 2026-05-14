#!/usr/bin/env bash
# check-code-craft-canonical.sh
#
# Byte-identity check on the canonical code-craft principle paragraphs
# (Simplicity First, Surgical Changes) across three files:
#
#   1. plugins/kenspc/shared/code-craft-principles.md   (authoritative)
#   2. plugins/kenspc/agents/task-implementer.md         (inlined copy)
#   3. plugins/kenspc/agents/code-fixer.md               (inlined copy)
#
# For each of the two principle keys (simplicity-first, surgical-changes),
# the bounded block between
#   <!-- canonical:principle:<key>:start -->
# and
#   <!-- canonical:principle:<key>:end -->
# must be sha256-identical across all three files. The two writer agents
# inline the principle paragraphs so the rule is loaded into every dispatch
# without depending on a runtime Read; this script is the mechanical guard
# that prevents drift between the inlined copies and the authoritative
# source.
#
# Exit code 0: both keys' three-way hashes are identical across all three
#              files.
# Exit code 1: drift detected (at least one key's hashes do not agree).
# Exit code 2: missing input file or markers not found.
#
# Modeled on check-canonical-dispatch.sh; same set -euo pipefail discipline
# and same sed -n extraction technique.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SHARED_FILE="$REPO_ROOT/plugins/kenspc/shared/code-craft-principles.md"
IMPLEMENTER_FILE="$REPO_ROOT/plugins/kenspc/agents/task-implementer.md"
FIXER_FILE="$REPO_ROOT/plugins/kenspc/agents/code-fixer.md"

FILES=("$SHARED_FILE" "$IMPLEMENTER_FILE" "$FIXER_FILE")
KEYS=("simplicity-first" "surgical-changes")

extract_block() {
    local file="$1"
    local key="$2"
    sed -n "/<!-- canonical:principle:${key}:start -->/,/<!-- canonical:principle:${key}:end -->/p" "$file"
}

# Pre-flight: every file must exist; every key's marker pair must be present
# in every file.
for f in "${FILES[@]}"; do
    if [[ ! -f "$f" ]]; then
        echo "ERROR: missing file $f" >&2
        exit 2
    fi
done

for key in "${KEYS[@]}"; do
    start_marker="<!-- canonical:principle:${key}:start -->"
    end_marker="<!-- canonical:principle:${key}:end -->"
    for f in "${FILES[@]}"; do
        # Exactly one start-marker line and one end-marker line per file. A
        # missing end marker would cause sed to swallow content from start to
        # EOF; a duplicated marker pair would let sed concatenate two blocks
        # and a corrupted state could pass the byte-identity check below if
        # all three files were similarly corrupted.
        start_count=$(grep -c -F "$start_marker" "$f" || true)
        end_count=$(grep -c -F "$end_marker" "$f" || true)
        if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
            echo "ERROR: canonical:principle:${key} markers malformed in $f" >&2
            echo "       expected exactly 1 start and 1 end marker; found ${start_count} start and ${end_count} end" >&2
            exit 2
        fi
        # Non-empty content between markers (strip the two marker lines and
        # require at least one remaining non-empty line).
        block_body=$(extract_block "$f" "$key" | sed -e "1d" -e "\$d")
        if [[ -z "${block_body// }" ]]; then
            echo "ERROR: canonical:principle:${key} block in $f has no content between markers" >&2
            exit 2
        fi
    done
done

drift_found=0

for key in "${KEYS[@]}"; do
    shared_hash=$(extract_block "$SHARED_FILE" "$key" | sha256sum | awk '{print $1}')
    implementer_hash=$(extract_block "$IMPLEMENTER_FILE" "$key" | sha256sum | awk '{print $1}')
    fixer_hash=$(extract_block "$FIXER_FILE" "$key" | sha256sum | awk '{print $1}')

    if [[ "$shared_hash" == "$implementer_hash" && "$shared_hash" == "$fixer_hash" ]]; then
        echo "OK    canonical:principle:${key} byte-identity — shared, task-implementer, code-fixer all match"
        echo "      sha256: $shared_hash"
    else
        drift_found=1
        echo "DRIFT canonical:principle:${key} — files disagree" >&2
        echo "      shared/code-craft-principles.md sha256: $shared_hash" >&2
        echo "      agents/task-implementer.md sha256:      $implementer_hash" >&2
        echo "      agents/code-fixer.md sha256:            $fixer_hash" >&2

        # Identify the outlier(s): pick the file whose hash disagrees with
        # the authoritative shared file, and diff each outlier against it.
        if [[ "$implementer_hash" != "$shared_hash" ]]; then
            echo "" >&2
            echo "Outlier: agents/task-implementer.md (diff vs shared file):" >&2
            diff <(extract_block "$SHARED_FILE" "$key") \
                 <(extract_block "$IMPLEMENTER_FILE" "$key") >&2 || true
        fi
        if [[ "$fixer_hash" != "$shared_hash" ]]; then
            echo "" >&2
            echo "Outlier: agents/code-fixer.md (diff vs shared file):" >&2
            diff <(extract_block "$SHARED_FILE" "$key") \
                 <(extract_block "$FIXER_FILE" "$key") >&2 || true
        fi
        if [[ "$implementer_hash" == "$fixer_hash" && "$implementer_hash" != "$shared_hash" ]]; then
            echo "" >&2
            echo "Note: both inlined copies agree but disagree with the shared file." >&2
            echo "      The shared file is authoritative; re-sync from there or, if" >&2
            echo "      the principle text was intentionally updated, propagate the" >&2
            echo "      edit to the shared file first." >&2
        fi
    fi
done

if [[ "$drift_found" -ne 0 ]]; then
    echo "" >&2
    echo "Drift detected. The canonical principle paragraphs must be byte-identical" >&2
    echo "between shared/code-craft-principles.md (authoritative) and the two writer" >&2
    echo "agents that inline them. Apply the same edit to all three files." >&2
    exit 1
fi

# ---- Check 2: anchor phrase frequency ----
#
# Brief item #31 named "outside the byte-identity hash range" — but the two
# writer-agent files contain the anchor labels only inside the canonical
# block. Counting "outside" the block in those files would always return 0
# and produce a vacuous check. The refined scope is "anywhere in file": the
# failure mode the brief targeted (a synchronized edit that replaces the
# canonical block in all three files with content that drops the anchor)
# is still caught — the byte-identity check passes after such an edit, but
# the new "Simplicity First" / "Surgical Changes" anchor must remain
# present somewhere in each file for the check to pass.
ANCHORS=(
    "Simplicity First|1"
    "Surgical Changes|1"
)

count_phrase_in_file() {
    # Count occurrences of a literal phrase (case-insensitive) in a file.
    # grep returns 1 on no match, which under `set -o pipefail` would
    # collapse the pipeline; tolerate that explicitly so a 0 count is
    # reported as "0" instead of failing the script.
    local phrase="$1"
    local file="$2"
    local n
    n=$(grep -F -i -o -- "$phrase" "$file" || true)
    if [[ -z "$n" ]]; then
        echo 0
    else
        printf '%s\n' "$n" | wc -l | tr -d ' '
    fi
}

anchor_ok=1
for spec in "${ANCHORS[@]}"; do
    phrase="${spec%|*}"
    min="${spec##*|}"
    for f in "${FILES[@]}"; do
        count=$(count_phrase_in_file "$phrase" "$f")
        if [[ "$count" -lt "$min" ]]; then
            anchor_ok=0
            drift_found=1
            echo "MISSING anchor '$phrase' in $f: found $count, expected >= $min" >&2
        fi
    done
done

if [[ "$anchor_ok" -eq 1 ]]; then
    echo "OK    code-craft anchor phrases — all minimum counts met in all three files"
else
    echo "" >&2
    echo "One or more anchor phrases dropped below their minimum count in one of" >&2
    echo "the three code-craft files. Restore the phrasing in the affected file(s)." >&2
fi

if [[ "$drift_found" -ne 0 ]]; then
    exit 1
fi

exit 0
