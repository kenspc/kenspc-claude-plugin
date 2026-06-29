#!/usr/bin/env bash
# check-notes-format-sync.sh
#
# Anchor-presence guard keeping the per-task Implementation notes block's
# sub-bullet labels in sync between two files:
#
#   1. plugins/kenspc/agents/task-implementer.md         (the live agent that
#                                                          prescribes the format)
#   2. plugins/kenspc/references/task-document-example.md (the demonstrated block
#                                                          users copy from)
#
# The DONE block shape uses two load-bearing sub-bullet labels — `Decisions:`
# and `Changes/tradeoffs:`. The agent prescribes them and the example doc
# demonstrates them; if a future edit renames one label in one file but not
# the other, the example silently drifts from what the live agent writes and a
# user copying the example would author the wrong shape. A byte-identity guard
# is wrong here (the surrounding prose differs by design — the agent describes
# the format, the example shows a filled-in instance), so this guard asserts
# only that each label substring is present at least once in BOTH files. That
# catches the rename-drift failure mode without over-constraining the prose.
#
# Exit code 0: both labels present in both files.
# Exit code 1: at least one label missing from at least one file (drift).
# Exit code 2: missing input file, or self-test fixture stale.
#
# Modeled on check-code-craft-canonical.sh Check 2 (anchor-phrase frequency);
# same set -euo pipefail discipline and same SCRIPT_DIR / REPO_ROOT derivation.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the two target
#                  files into a temp workdir, runs the main check (must exit
#                  0), renames a label in the example file (must exit 1), then
#                  reverts (must exit 0). Opt-in: invocation with no arguments
#                  behaves unchanged. Exit 0 on self-test pass, 1 on unexpected
#                  exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Run the main check against a given repo root. Uses local variables so the
# function can be called multiple times with different REPO_ROOTs during
# --self-test. Returns 0/1/2 via `return` (no `exit`).
run_main_logic() {
    local repo_root="$1"
    local agent_file="$repo_root/plugins/kenspc/agents/task-implementer.md"
    local example_file="$repo_root/plugins/kenspc/references/task-document-example.md"

    local files=("$agent_file" "$example_file")
    # Load-bearing sub-bullet labels of the DONE Implementation notes block.
    local labels=("Decisions:" "Changes/tradeoffs:")

    local f
    for f in "${files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
    done

    local drift_found=0
    local label
    for label in "${labels[@]}"; do
        for f in "${files[@]}"; do
            # grep -F literal, -q quiet. Under pipefail a no-match (exit 1)
            # must not collapse the script, so branch explicitly.
            if grep -qF -- "$label" "$f"; then
                :
            else
                drift_found=1
                echo "MISSING label '$label' in $f" >&2
            fi
        done
    done

    if [[ "$drift_found" -ne 0 ]]; then
        echo "" >&2
        echo "The per-task Implementation notes sub-bullet labels (Decisions:," >&2
        echo "Changes/tradeoffs:) must stay in sync between the live agent" >&2
        echo "(agents/task-implementer.md) and the demonstrated example" >&2
        echo "(references/task-document-example.md). Restore the missing label." >&2
        return 1
    fi

    echo "OK    notes-format-sync — both DONE-block labels present in agent and example"
    return 0
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. Copies the two target files into a temp
# workdir, runs the main check (expect 0), renames the `Decisions:` label in
# the example file (expect 1 — the label is then absent from the example),
# reverts (expect 0). Mutating the example (not the agent) models the most
# likely drift: an editor "improving" the example's wording in isolation.
run_self_test() {
    # WORK is global (not local) so the EXIT trap can reference it safely
    # after this function returns. Under `set -u`, an EXIT trap that refers
    # to an unset local triggers an "unbound variable" error at fire time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    mkdir -p "$WORK/plugins/kenspc/agents" "$WORK/plugins/kenspc/references"
    cp "$REPO_ROOT/plugins/kenspc/agents/task-implementer.md" "$WORK/plugins/kenspc/agents/task-implementer.md"
    cp "$REPO_ROOT/plugins/kenspc/references/task-document-example.md" "$WORK/plugins/kenspc/references/task-document-example.md"

    local mutation_target='Decisions:'
    local mutation_replacement='Rationale:'
    local target_file="$WORK/plugins/kenspc/references/task-document-example.md"

    # Fixture-stale guard: the mutation target must be present in the example
    # for the negative path to be meaningful.
    if ! grep -qF -- "$mutation_target" "$target_file"; then
        echo "FAIL  self-test fixture stale: mutation target \"$mutation_target\" not found in $target_file. Update the mutation target in run_self_test()." >&2
        return 2
    fi

    # Positive path: main check on the unmodified copy must exit 0.
    local rc
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test positive path: expected exit 0 on unmutated copy, got $rc" >&2
        return 1
    fi

    # Apply mutation: rename the label everywhere in the example file so the
    # `Decisions:` substring is absent from that file.
    sed -i "s|${mutation_target}|${mutation_replacement}|g" "$target_file"
    if grep -qF -- "$mutation_target" "$target_file"; then
        echo "FAIL  self-test: mutation did not apply (target label still present in $target_file)" >&2
        return 2
    fi

    # Negative path: main check on the mutated copy must exit 1.
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path: expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Revert by recopying the source.
    cp "$REPO_ROOT/plugins/kenspc/references/task-document-example.md" "$target_file"
    if ! grep -qF -- "$mutation_target" "$target_file"; then
        echo "FAIL  self-test: revert did not restore the target label in $target_file" >&2
        return 2
    fi

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
