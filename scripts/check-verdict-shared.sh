#!/usr/bin/env bash
# check-verdict-shared.sh
#
# Byte-identity guard on the shared verdict-determination block in
# task-review/SKILL.md and task-implement/SKILL.md. Both skills dispatch
# regression-verifier and map its row-3 Schema C states to a verdict through
# their own "Verdict determination" sections. The bullets that describe that
# mapping — the `SPOT-CHECK` neutral note plus the involuntary-incomplete and
# intentional-skip clauses — are duplicated in both files and must stay
# identical. The surrounding PASS / FAIL / PARTIAL / BLOCKED bullets differ
# between the two skills by design and are left outside the block.
#
# The block is delimited by HTML comment markers
#   <!-- canonical:verdict-shared:start --> / <!-- canonical:verdict-shared:end -->
# and must be byte-identical between the two files.
#
# Exit code 0: block byte-identical.
# Exit code 1: drift detected (byte-identity diff).
# Exit code 2: missing input file / markers.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the two target
#                  SKILL.md files into a temp workdir, runs the main check
#                  (must exit 0), mutates a load-bearing phrase inside the
#                  shared block of the task-review copy (must exit 1 — the two
#                  blocks now diverge), then reverts (must exit 0). Opt-in:
#                  invocation with no arguments behaves unchanged. Exit 0 on
#                  self-test pass, 1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Run the byte-identity check against a given repo root. Uses local variables
# so the function can be called multiple times with different REPO_ROOTs during
# --self-test. Returns 0/1/2 via `return` (no `exit`) so the self-test caller
# can branch on the result.
run_main_logic() {
    local repo_root="$1"
    local review_file="$repo_root/plugins/kenspc/skills/task-review/SKILL.md"
    local impl_file="$repo_root/plugins/kenspc/skills/task-implement/SKILL.md"

    extract_block() {
        local file="$1"
        sed -n '/<!-- canonical:verdict-shared:start -->/,/<!-- canonical:verdict-shared:end -->/p' "$file"
    }

    local f block
    for f in "$review_file" "$impl_file"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
        block=$(extract_block "$f")
        if [[ -z "$block" ]]; then
            echo "ERROR: canonical:verdict-shared markers not found in $f" >&2
            return 2
        fi
    done

    local review_hash impl_hash
    review_hash=$(extract_block "$review_file" | sha256sum | awk '{print $1}')
    impl_hash=$(extract_block "$impl_file" | sha256sum | awk '{print $1}')

    if [[ "$review_hash" == "$impl_hash" ]]; then
        echo "OK    canonical:verdict-shared byte-identity — task-review and task-implement match"
        echo "      sha256: $review_hash"
        return 0
    fi

    echo "DRIFT canonical:verdict-shared byte-identity — task-review and task-implement diverge" >&2
    echo "      task-review.md sha256:    $review_hash" >&2
    echo "      task-implement.md sha256: $impl_hash" >&2
    echo "" >&2
    echo "Diff (task-review.md vs task-implement.md):" >&2
    diff <(extract_block "$review_file") <(extract_block "$impl_file") >&2 || true
    echo "" >&2
    echo "The shared verdict block must be byte-identical between the two skills." >&2
    echo "Apply the same edit to both files, or move file-specific wording outside" >&2
    echo "the canonical:verdict-shared markers." >&2
    return 1
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. Copies the two target SKILL.md files into a temp
# workdir, runs the main check (expect 0), mutates the load-bearing phrase
# "skipped by design" inside the canonical:verdict-shared block of the
# task-review copy (expect 1 — mutating one copy breaks byte-identity), reverts
# (expect 0).
run_self_test() {
    # WORK is set as a global (not local) so the EXIT trap can reference it
    # safely after this function returns; under `set -u` an EXIT trap that
    # refers to an unset local would trigger "unbound variable" at trap time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    mkdir -p "$WORK/plugins/kenspc/skills/task-review" "$WORK/plugins/kenspc/skills/task-implement"
    cp "$REPO_ROOT/plugins/kenspc/skills/task-review/SKILL.md" "$WORK/plugins/kenspc/skills/task-review/SKILL.md"
    cp "$REPO_ROOT/plugins/kenspc/skills/task-implement/SKILL.md" "$WORK/plugins/kenspc/skills/task-implement/SKILL.md"

    local target_file="$WORK/plugins/kenspc/skills/task-review/SKILL.md"
    local mutation_target="skipped by design"
    local mutation_replacement="skipped on purpose"

    # Fixture-stale guard: the target phrase must appear inside the
    # canonical:verdict-shared block of the target file for the negative path
    # to be meaningful.
    local block_target
    block_target=$(sed -n '/<!-- canonical:verdict-shared:start -->/,/<!-- canonical:verdict-shared:end -->/p' "$target_file")
    if ! printf '%s\n' "$block_target" | grep -qF -- "$mutation_target"; then
        echo "FAIL  self-test fixture stale: mutation target \"$mutation_target\" not found inside canonical:verdict-shared block of $target_file. Update the mutation target in run_self_test()." >&2
        return 2
    fi

    # Positive path: main check on the unmodified copies must exit 0.
    local rc
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test positive path: expected exit 0 on unmutated copy, got $rc" >&2
        return 1
    fi

    # Apply mutation only inside the canonical:verdict-shared block of the
    # task-review copy. sed's address range limits the substitution to that
    # block so we do not touch occurrences elsewhere in the file.
    sed -i "/<!-- canonical:verdict-shared:start -->/,/<!-- canonical:verdict-shared:end -->/{s/${mutation_target}/${mutation_replacement}/}" "$target_file"
    if ! sed -n '/<!-- canonical:verdict-shared:start -->/,/<!-- canonical:verdict-shared:end -->/p' "$target_file" \
        | grep -qF -- "${mutation_replacement}"; then
        echo "FAIL  self-test: mutation did not apply inside canonical:verdict-shared block of $target_file" >&2
        return 2
    fi

    # Negative path: main check on the mutated copy must exit 1 (blocks diverge).
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
