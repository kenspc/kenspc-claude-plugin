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
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the two
#                  target SKILL.md files into a temp workdir, runs the
#                  main check (must exit 0), mutates a load-bearing
#                  anchor inside the canonical block (must exit 1), then
#                  reverts (must exit 0). Opt-in: invocation with no
#                  arguments behaves unchanged. Exit 0 on self-test pass,
#                  1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Run the dual check against a given repo root. Uses local variables so
# the function can be called multiple times with different REPO_ROOTs
# during --self-test. Returns 0/1/2 via `return` (no `exit`) so a caller
# (the self-test) can branch on the result.
run_main_logic() {
    local repo_root="$1"
    local review_file="$repo_root/plugins/kenspc/skills/task-review/SKILL.md"
    local impl_file="$repo_root/plugins/kenspc/skills/task-implement/SKILL.md"

    # Anchor phrases: "phrase|min_count" pairs. The phrase is matched
    # case-insensitively as a literal (grep -F -i) inside the canonical
    # block of each SKILL.
    local anchors=(
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

    local f block
    for f in "$review_file" "$impl_file"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
        block=$(extract_block "$f")
        if [[ -z "$block" ]]; then
            echo "ERROR: canonical:dispatch markers not found in $f" >&2
            return 2
        fi
    done

    # ---- Check 1: byte-identity ----
    local review_hash impl_hash
    review_hash=$(extract_block "$review_file" | sha256sum | awk '{print $1}')
    impl_hash=$(extract_block "$impl_file" | sha256sum | awk '{print $1}')

    local byte_identity_ok=1
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
        diff <(extract_block "$review_file") <(extract_block "$impl_file") >&2 || true
        echo "" >&2
        echo "The canonical dispatch block must be byte-identical between the two" >&2
        echo "skills. Apply the same edit to both files." >&2
    fi

    # ---- Check 2: anchor phrase frequency ----
    local anchor_ok=1
    local spec phrase min count
    for spec in "${anchors[@]}"; do
        phrase="${spec%|*}"
        min="${spec##*|}"
        for f in "$review_file" "$impl_file"; do
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
        return 0
    fi
    return 1
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. Copies the two target SKILL.md files into
# a temp workdir, runs the main check (expect 0), mutates the anchor
# "unconditional" inside the canonical:dispatch block of the task-review
# file (expect 1), reverts (expect 0). The mutation replaces the word
# "unconditional" with "notrequired" — a wholly different word, not a
# case variation, so the case-insensitive anchor grep also drops to 0
# in the mutated file. Mutating only one of the two files also breaks
# the byte-identity check.
run_self_test() {
    # WORK is set as a global (not local) so the EXIT trap can reference
    # it safely after this function returns. Under `set -u`, an EXIT trap
    # that refers to an unset local variable would trigger "unbound
    # variable" at trap-firing time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    # Replicate the relative paths the main logic expects.
    mkdir -p "$WORK/plugins/kenspc/skills/task-review" "$WORK/plugins/kenspc/skills/task-implement"
    cp "$REPO_ROOT/plugins/kenspc/skills/task-review/SKILL.md" "$WORK/plugins/kenspc/skills/task-review/SKILL.md"
    cp "$REPO_ROOT/plugins/kenspc/skills/task-implement/SKILL.md" "$WORK/plugins/kenspc/skills/task-implement/SKILL.md"

    local target_file="$WORK/plugins/kenspc/skills/task-review/SKILL.md"
    local mutation_target="unconditional"
    local mutation_replacement="notrequired"

    # Fixture-stale guard: the target phrase must appear inside the
    # canonical:dispatch block of the target file for the negative path
    # to be meaningful.
    local block_target
    block_target=$(sed -n '/<!-- canonical:dispatch:start -->/,/<!-- canonical:dispatch:end -->/p' "$target_file")
    if ! printf '%s\n' "$block_target" | grep -qF -- "$mutation_target"; then
        echo "FAIL  self-test fixture stale: mutation target \"$mutation_target\" not found inside canonical:dispatch block of $target_file. Update the mutation target in run_self_test()." >&2
        return 2
    fi

    # Positive path: main check on the unmodified copy must exit 0.
    local rc
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test positive path: expected exit 0 on unmutated copy, got $rc" >&2
        return 1
    fi

    # Apply mutation only inside the canonical:dispatch block of the
    # target file. Using sed's address range limits the substitution to
    # that block so we don't accidentally touch later occurrences of the
    # word in unrelated prose.
    sed -i "/<!-- canonical:dispatch:start -->/,/<!-- canonical:dispatch:end -->/{s/${mutation_target}/${mutation_replacement}/}" "$target_file"
    if ! grep -qE "${mutation_replacement}" "$target_file"; then
        echo "FAIL  self-test: mutation did not apply in $target_file" >&2
        return 2
    fi

    # Negative path: main check on the mutated copy must exit 1.
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path: expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Revert the mutation by recopying the source.
    cp "$REPO_ROOT/plugins/kenspc/skills/task-review/SKILL.md" "$target_file"

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
