#!/usr/bin/env bash
# check-doc-sync-anchors.sh
#
# Anchor guard for the planning chain: presence for five anchors across
# eleven files, and one exact count. Two paths run through it. The
# documentation path: a plan's Documentation impact element becomes the task
# document's Doc-sync task, whose promotion step reports what it could not
# place under Decisions needing a home. The open-question path: a brief's
# Open Questions entry marked `needs prototype` is what generate-plan stops
# on and what the prototype skill settles, and the Prototype line the skill
# writes into an answered entry is copied from generate-brief's grammar.
# Five load-bearing anchors carry those paths across eleven files, and every
# file in an anchor's group must keep it:
#
#   `Documentation impact`      (the plan element)
#       plugins/kenspc/skills/generate-plan/SKILL.md
#       plugins/kenspc/references/plan-document-example.md
#       plugins/kenspc/agents/plan-document-reviewer.md
#       plugins/kenspc/skills/generate-task/SKILL.md
#       plugins/kenspc/skills/diagnose-bug/SKILL.md
#       plugins/kenspc/agents/task-document-reviewer.md
#   `Doc-sync`                  (the task heading `### Task N: Doc-sync`)
#       plugins/kenspc/skills/generate-task/SKILL.md
#       plugins/kenspc/skills/diagnose-bug/SKILL.md
#       plugins/kenspc/references/task-document-example.md
#       plugins/kenspc/agents/task-document-reviewer.md
#       plugins/kenspc/agents/task-implementer.md
#   `Decisions needing a home`  (the Schema D / Schema G section)
#       plugins/kenspc/agents/task-implementer.md
#       plugins/kenspc/skills/task-implement/SKILL.md
#   `needs prototype`           (the Open Questions status word)
#       plugins/kenspc/skills/generate-brief/SKILL.md
#       plugins/kenspc/skills/generate-plan/SKILL.md
#       plugins/kenspc/skills/prototype/SKILL.md
#   the Prototype line          (an answered entry's line naming the commit)
#       Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>`
#       plugins/kenspc/skills/generate-brief/SKILL.md
#       plugins/kenspc/skills/prototype/SKILL.md
#
# One file writes an anchor, another checks it, a third renders or greps it.
# If a future edit renames an anchor in one file but not the others, the
# planning chain breaks silently — a plan element nobody reads, a Doc-sync
# task nobody recognizes, a section nobody renders, an open question nobody
# stops on, a Prototype line the brief's grammar no longer describes — while
# every other check still passes. A byte-identity guard is wrong here (the
# prose around each anchor differs by design), so this guard asserts that
# each label substring is present at least once in every file of its group.
# The Prototype line's label is the whole line, so its presence in both
# files is the byte-identity the line needs; text added before or after it
# in one file is not seen, and changes neither what a reader copies nor the
# hash an entry names.
#
# The exact count: the prototype skill's leftovers command,
#   git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>
# occurs exactly twice in plugins/kenspc/skills/prototype/SKILL.md, counted
# by occurrence (not by line). The skill runs it once when the location is
# chosen, as a snapshot, and again at the Exit, whose leftovers list leaves
# out the paths the snapshot listed; the two lists are compared path by
# path, so the two copies must be the same command. Presence alone cannot
# see one copy changed while the other stays, and a third copy would enter
# without anyone checking that it matches.
#
# README.md and CLAUDE.md are deliberately outside the guard: the reviewer
# invariant sentence there is checked by check-run-contract.sh (check 6),
# and the rest of their prose by no guard.
#
# Exit code 0: every label present in every file of its group, and the
#              leftovers command occurs exactly twice.
# Exit code 1: at least one label missing from at least one file (drift),
#              each missing label and file named; or the leftovers command
#              occurs any number of times other than two, the count named.
# Exit code 2: missing input file, or self-test fixture stale.
#
# Modeled on check-notes-format-sync.sh (anchor presence, not byte-identity);
# same set -euo pipefail discipline and same SCRIPT_DIR / REPO_ROOT
# derivation.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the eleven
#                  target files into a temp workdir, confirms `Doc-sync` is
#                  present in the copied task example, the Prototype line in
#                  the copied prototype skill, and the leftovers command
#                  twice in it (exit 2 if not), and runs the main check
#                  (must exit 0). Then four mutations, each restored by
#                  recopying before the next, must each exit 1: `Doc-sync`
#                  renamed to `Docsync` in the copied task example;
#                  "`<location>`, removed in the next commit" changed to
#                  "`<location>`, removed in a later commit" in the prototype
#                  skill's Prototype line; the first of the two leftovers
#                  commands alone with `--ignored=matching` changed to
#                  `--ignored`; and a third copy of the leftovers command
#                  appended to the skill. Then the main check runs on the
#                  reverted copy (must exit 0). Opt-in: invocation with no
#                  arguments behaves unchanged. Exit 0 on self-test pass, 1
#                  on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Anchor groups, one entry per (label, file) pair:
# "<label>|<path relative to the repo root>". Labels contain spaces but no
# `|`, so the first `|` splits each entry. The Prototype line's entries are
# single-quoted because the line holds backticks.
ANCHOR_CHECKS=(
    "Documentation impact|plugins/kenspc/skills/generate-plan/SKILL.md"
    "Documentation impact|plugins/kenspc/references/plan-document-example.md"
    "Documentation impact|plugins/kenspc/agents/plan-document-reviewer.md"
    "Documentation impact|plugins/kenspc/skills/generate-task/SKILL.md"
    "Documentation impact|plugins/kenspc/skills/diagnose-bug/SKILL.md"
    "Documentation impact|plugins/kenspc/agents/task-document-reviewer.md"
    "Doc-sync|plugins/kenspc/skills/generate-task/SKILL.md"
    "Doc-sync|plugins/kenspc/skills/diagnose-bug/SKILL.md"
    "Doc-sync|plugins/kenspc/references/task-document-example.md"
    "Doc-sync|plugins/kenspc/agents/task-document-reviewer.md"
    "Doc-sync|plugins/kenspc/agents/task-implementer.md"
    "Decisions needing a home|plugins/kenspc/agents/task-implementer.md"
    "Decisions needing a home|plugins/kenspc/skills/task-implement/SKILL.md"
    "needs prototype|plugins/kenspc/skills/generate-brief/SKILL.md"
    "needs prototype|plugins/kenspc/skills/generate-plan/SKILL.md"
    "needs prototype|plugins/kenspc/skills/prototype/SKILL.md"
    'Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>`|plugins/kenspc/skills/generate-brief/SKILL.md'
    'Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>`|plugins/kenspc/skills/prototype/SKILL.md'
)

# The exact-count check: this literal occurs exactly LEFTOVERS_WANT times in
# LEFTOVERS_REL (a file already in ANCHOR_CHECKS, so the self-test copies it).
LEFTOVERS_LITERAL='git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>'
LEFTOVERS_REL='plugins/kenspc/skills/prototype/SKILL.md'
LEFTOVERS_WANT=2

# Print the number of occurrences of a literal string in a file, counting
# every occurrence on a line, not lines.
count_occurrences() {
    local file="$1" literal="$2"
    awk -v s="$literal" '
        { r = $0; while ((i = index(r, s)) > 0) { n++; r = substr(r, i + length(s)) } }
        END { print n + 0 }
    ' "$file"
}

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
        echo "The planning-chain anchors (Documentation impact, Doc-sync," >&2
        echo "Decisions needing a home, needs prototype, and the Prototype line) must" >&2
        echo "stay spelled the same in every file that writes, checks, or renders them." >&2
        echo "Restore the missing label, or change it in every file of its group and in" >&2
        echo "this guard together." >&2
    fi

    local count_bad=0 found
    found=$(count_occurrences "$repo_root/$LEFTOVERS_REL" "$LEFTOVERS_LITERAL")
    if [[ "$found" -ne "$LEFTOVERS_WANT" ]]; then
        count_bad=1
        echo "COUNT leftovers command — $found occurrence(s) in $repo_root/$LEFTOVERS_REL, expected $LEFTOVERS_WANT:" >&2
        echo "  $LEFTOVERS_LITERAL" >&2
        echo "The prototype skill runs it once when the location is chosen, as a snapshot," >&2
        echo "and again at the Exit, whose leftovers list leaves out the paths the snapshot" >&2
        echo "listed; the two lists are compared path by path, so the two copies must be" >&2
        echo "the same command. Restore it, or change both copies and this guard together." >&2
    fi

    if [[ "$drift_found" -ne 0 || "$count_bad" -ne 0 ]]; then
        return 1
    fi

    echo "OK    doc-sync-anchors — all five anchors present in every file of their groups"
    echo "OK    leftovers command — exactly $LEFTOVERS_WANT occurrences in $LEFTOVERS_REL"
    return 0
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. Copies the eleven target files into a temp
# workdir, runs the main check (expect 0), then four mutations, each
# restored by recopying (expect 1 each): `Doc-sync` renamed to `Docsync` in
# the task example (the label is then absent from that file); the prototype
# skill's Prototype line changed to "removed in a later commit"; the first
# leftovers command alone given `--ignored` for `--ignored=matching` (the
# count drops to one); and a third leftovers command appended (the count
# rises to three). Finally the reverted copy (expect 0). The presence check
# is presence-only by design, so renaming only the example's
# `### Task 6: Doc-sync` heading is not caught while its closing note still
# says `Doc-sync`.

# Replace the first occurrence of a literal string in a file.
replace_literal() {
    local file="$1" old="$2" new="$3"
    awk -v old="$old" -v new="$new" '
        !done && (i = index($0, old)) {
            $0 = substr($0, 1, i - 1) new substr($0, i + length(old)); done = 1
        }
        { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

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
    local proto_file="$WORK/$LEFTOVERS_REL"
    local proto_line_old='`<location>`, removed in the next commit'
    local proto_line_new='`<location>`, removed in a later commit'
    local leftovers_mutated='git -c core.quotePath=false status --porcelain --ignored -uall -- <location>'
    local prototype_line hits found

    # The Prototype line's label, read from its ANCHOR_CHECKS entry.
    for entry in "${ANCHOR_CHECKS[@]}"; do
        if [[ "${entry#*|}" == "$LEFTOVERS_REL" && "$entry" == Prototype:* ]]; then
            prototype_line="${entry%%|*}"
        fi
    done

    # Fixture-stale guards: each mutation target must be present in its file
    # for the negative path to be meaningful.
    if ! grep -qF -- "$mutation_target" "$target_file"; then
        echo "FAIL  self-test fixture stale: mutation target \"$mutation_target\" not found in $target_file. Update the mutation target in run_self_test()." >&2
        return 2
    fi
    if [[ -z "${prototype_line:-}" ]] || ! grep -qF -- "$prototype_line" "$proto_file"; then
        echo "FAIL  self-test fixture stale: the Prototype line is not in $proto_file" >&2
        return 2
    fi
    hits=$(grep -cF -- "$proto_line_old" "$proto_file" || true)
    if [[ "$hits" -ne 1 ]]; then
        echo "FAIL  self-test fixture stale: \"$proto_line_old\" found on $hits lines of $proto_file, expected 1" >&2
        return 2
    fi
    found=$(count_occurrences "$proto_file" "$LEFTOVERS_LITERAL")
    if [[ "$found" -ne 2 ]]; then
        echo "FAIL  self-test fixture stale: the leftovers command occurs $found times in $proto_file, expected 2" >&2
        return 2
    fi

    # Positive path: main check on the unmodified copy must exit 0.
    local rc
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test positive path: expected exit 0 on unmutated copy, got $rc" >&2
        return 1
    fi

    # Mutation 1: rename the label everywhere in the example file so the
    # `Doc-sync` substring is absent from that file. `-i.bak` (suffix
    # attached) is the in-place form both GNU and BSD sed accept; bare `-i`
    # fails on BSD sed (macOS).
    sed -i.bak "s|${mutation_target}|${mutation_replacement}|g" "$target_file" && rm "$target_file.bak"
    if grep -qF -- "$mutation_target" "$target_file"; then
        echo "FAIL  self-test: mutation did not apply (target label still present in $target_file)" >&2
        return 2
    fi
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    cp "$REPO_ROOT/$target_rel" "$target_file"
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path (Doc-sync renamed): expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Mutation 2: the prototype skill's copy of the Prototype line changed.
    replace_literal "$proto_file" "$proto_line_old" "$proto_line_new"
    if grep -qF -- "$prototype_line" "$proto_file"; then
        echo "FAIL  self-test: Prototype line mutation did not apply in $proto_file" >&2
        return 2
    fi
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    cp "$REPO_ROOT/$LEFTOVERS_REL" "$proto_file"
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path (Prototype line changed): expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Mutation 3: the first leftovers command alone changed; the count
    # drops to one. `--ignored=matching` is on two lines, so the literal
    # replacement of the whole command touches the first only.
    replace_literal "$proto_file" "$LEFTOVERS_LITERAL" "$leftovers_mutated"
    found=$(count_occurrences "$proto_file" "$LEFTOVERS_LITERAL")
    if [[ "$found" -ne 1 ]]; then
        echo "FAIL  self-test: leftovers mutation left $found occurrences in $proto_file, expected 1" >&2
        return 2
    fi
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    cp "$REPO_ROOT/$LEFTOVERS_REL" "$proto_file"
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path (one leftovers command changed): expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Mutation 4: a third copy of the leftovers command appended.
    printf '%s\n' "$LEFTOVERS_LITERAL" >> "$proto_file"
    found=$(count_occurrences "$proto_file" "$LEFTOVERS_LITERAL")
    if [[ "$found" -ne 3 ]]; then
        echo "FAIL  self-test: leftovers append left $found occurrences in $proto_file, expected 3" >&2
        return 2
    fi
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    cp "$REPO_ROOT/$LEFTOVERS_REL" "$proto_file"
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path (third leftovers command): expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Revert check: the recopied files hold their targets again.
    if ! grep -qF -- "$mutation_target" "$target_file" \
        || ! grep -qF -- "$prototype_line" "$proto_file"; then
        echo "FAIL  self-test: revert did not restore the mutation targets" >&2
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
