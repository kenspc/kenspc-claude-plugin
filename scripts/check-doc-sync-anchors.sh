#!/usr/bin/env bash
# check-doc-sync-anchors.sh
#
# Anchor-presence guard for the documentation path: a plan's Documentation
# impact element becomes the task document's Doc-sync task, whose promotion
# step reports what it could not place under Decisions needing a home. Three
# load-bearing anchors carry that path across eight files, and every file in
# an anchor's group must keep it:
#
#   `Documentation impact`      (the plan element)
#       plugins/kenspc/skills/generate-plan/SKILL.md
#       plugins/kenspc/references/plan-document-example.md
#       plugins/kenspc/agents/plan-document-reviewer.md
#       plugins/kenspc/skills/generate-task/SKILL.md
#       plugins/kenspc/agents/task-document-reviewer.md
#   `Doc-sync`                  (the task heading `### Task N: Doc-sync`)
#       plugins/kenspc/skills/generate-task/SKILL.md
#       plugins/kenspc/references/task-document-example.md
#       plugins/kenspc/agents/task-document-reviewer.md
#       plugins/kenspc/agents/task-implementer.md
#   `Decisions needing a home`  (the Schema D / Schema G section)
#       plugins/kenspc/agents/task-implementer.md
#       plugins/kenspc/skills/task-implement/SKILL.md
#
# One file writes an anchor, another checks it, a third renders or greps it.
# If a future edit renames an anchor in one file but not the others, the
# documentation chain breaks silently — a plan element nobody reads, a
# Doc-sync task nobody recognizes, a section nobody renders — while every
# other check still passes. A byte-identity guard is wrong here (the prose
# around each anchor differs by design), so this guard asserts only that each
# label substring is present at least once in every file of its group.
# README.md and CLAUDE.md are deliberately outside the guard: prose
# invariants there are tracked as a separate roadmap item.
#
# Exit code 0: every label present in every file of its group.
# Exit code 1: at least one label missing from at least one file (drift);
#              each missing label and file is named.
# Exit code 2: missing input file, or self-test fixture stale.
#
# Modeled on check-notes-format-sync.sh (anchor presence, not byte-identity);
# same set -euo pipefail discipline and same SCRIPT_DIR / REPO_ROOT
# derivation.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the eight
#                  target files into a temp workdir, confirms `Doc-sync` is
#                  present in the copied task example (exit 2 if not), runs
#                  the main check (must exit 0), renames `Doc-sync` to
#                  `Docsync` in the copied task example (must exit 1), then
#                  reverts by recopying (must exit 0). Opt-in: invocation
#                  with no arguments behaves unchanged. Exit 0 on self-test
#                  pass, 1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Anchor groups, one entry per (label, file) pair:
# "<label>|<path relative to the repo root>". Labels contain spaces but no
# `|`, so the first `|` splits each entry.
ANCHOR_CHECKS=(
    "Documentation impact|plugins/kenspc/skills/generate-plan/SKILL.md"
    "Documentation impact|plugins/kenspc/references/plan-document-example.md"
    "Documentation impact|plugins/kenspc/agents/plan-document-reviewer.md"
    "Documentation impact|plugins/kenspc/skills/generate-task/SKILL.md"
    "Documentation impact|plugins/kenspc/agents/task-document-reviewer.md"
    "Doc-sync|plugins/kenspc/skills/generate-task/SKILL.md"
    "Doc-sync|plugins/kenspc/references/task-document-example.md"
    "Doc-sync|plugins/kenspc/agents/task-document-reviewer.md"
    "Doc-sync|plugins/kenspc/agents/task-implementer.md"
    "Decisions needing a home|plugins/kenspc/agents/task-implementer.md"
    "Decisions needing a home|plugins/kenspc/skills/task-implement/SKILL.md"
)

# Run the main check against a given repo root. Uses local variables so the
# function can be called multiple times with different REPO_ROOTs during
# --self-test. Returns 0/1/2 via `return` (no `exit`).
run_main_logic() {
    local repo_root="$1"
    local entry label file

    for entry in "${ANCHOR_CHECKS[@]}"; do
        file="$repo_root/${entry#*|}"
        if [[ ! -f "$file" ]]; then
            echo "ERROR: missing file $file" >&2
            return 2
        fi
    done

    local drift_found=0
    for entry in "${ANCHOR_CHECKS[@]}"; do
        label="${entry%%|*}"
        file="$repo_root/${entry#*|}"
        # grep -F literal, -q quiet. Under pipefail a no-match (exit 1)
        # must not collapse the script, so branch explicitly.
        if grep -qF -- "$label" "$file"; then
            :
        else
            drift_found=1
            echo "MISSING label '$label' in $file" >&2
        fi
    done

    if [[ "$drift_found" -ne 0 ]]; then
        echo "" >&2
        echo "The documentation-path anchors (Documentation impact, Doc-sync," >&2
        echo "Decisions needing a home) must stay spelled the same in every file" >&2
        echo "that writes, checks, or renders them. Restore the missing label, or" >&2
        echo "rename it in every file of its group and in this guard together." >&2
        return 1
    fi

    echo "OK    doc-sync-anchors — all three anchors present in every file of their groups"
    return 0
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. Copies the eight target files into a temp
# workdir, runs the main check (expect 0), renames `Doc-sync` to `Docsync` in
# the task example (expect 1 — the label is then absent from that file),
# reverts (expect 0). The fixture proves that a file with no `Doc-sync` left
# in it is caught. The check is presence-only by design, so renaming only the
# example's `### Task 6: Doc-sync` heading is not caught while its closing
# note still says `Doc-sync`.
run_self_test() {
    # WORK is global (not local) so the EXIT trap can reference it safely
    # after this function returns. Under `set -u`, an EXIT trap that refers
    # to an unset local triggers an "unbound variable" error at fire time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    local entry rel
    for entry in "${ANCHOR_CHECKS[@]}"; do
        rel="${entry#*|}"
        if [[ ! -f "$REPO_ROOT/$rel" ]]; then
            echo "FAIL  self-test: missing source file $REPO_ROOT/$rel" >&2
            return 2
        fi
        mkdir -p "$(dirname "$WORK/$rel")"
        cp "$REPO_ROOT/$rel" "$WORK/$rel"
    done

    local mutation_target='Doc-sync'
    local mutation_replacement='Docsync'
    local target_rel='plugins/kenspc/references/task-document-example.md'
    local target_file="$WORK/$target_rel"

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
    # `Doc-sync` substring is absent from that file. `-i.bak` (suffix
    # attached) is the in-place form both GNU and BSD sed accept; bare `-i`
    # fails on BSD sed (macOS).
    sed -i.bak "s|${mutation_target}|${mutation_replacement}|g" "$target_file" && rm "$target_file.bak"
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
    cp "$REPO_ROOT/$target_rel" "$target_file"
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
