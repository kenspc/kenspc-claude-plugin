#!/usr/bin/env bash
# check-merge-danger-canonical.sh
#
# Guards the `Merge danger` section's definition and placement across the
# three reports that carry it: task-review's Schema F, task-implement's
# Schema G, and the autopilot's final message. The rules for building the
# section are written once, in the block delimited by
#   <!-- canonical:merge-danger:start --> / <!-- canonical:merge-danger:end -->
# and copied into each carrier. Three checks:
#
#   1. byte-identity — the block is byte-identical in
#      plugins/kenspc/skills/task-review/SKILL.md,
#      plugins/kenspc/skills/task-implement/SKILL.md, and
#      plugins/kenspc/skills/autopilot/SKILL.md.
#   2. anchors — each of `one-way`, `two-way`, `unclear`, `Evidence:`,
#      `not found`, and `none named` appears at least once inside the block
#      of each file (literal, case-sensitive). A synchronized edit that drops
#      a label or a header value passes the byte-identity check; this check
#      catches it.
#   3. placement — read only inside the fenced templates, so a
#      `## Merge danger` line elsewhere in a file, the canonical block
#      included, neither satisfies nor fails it:
#        - the first fenced block after task-review's
#          `### Step 8: ... (Schema F)` heading and after task-implement's
#          `### Step 4: ... (Schema G)` heading each hold a `## Merge danger`
#          line after `## Verdict` and before `## Next steps`;
#        - the first fenced block after the autopilot's
#          `### The reviewer report` heading holds a `- Merge danger:` line.
#
# Exit code 0: all three checks pass.
# Exit code 1: drift detected (a block diverges, an anchor is missing, or a
#              heading or field is out of place).
# Exit code 2: missing input file, markers, template heading, or fenced
#              template; or, under --self-test, a stale fixture.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards; bash 3.2 compatible (no associative arrays, no ${var,,}).
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the three
#                  SKILL.md files into a temp workdir and runs the main
#                  check (must exit 0); then, recopying the sources after
#                  each mutation and running the check again (must exit 0):
#                  (a) one word changed inside the block of one copy, each
#                  copy in turn (must exit 1, naming byte-identity alone,
#                  and, for a task-implement or autopilot copy, that file's
#                  path); (b) the
#                  anchor `none named` replaced identically in all three
#                  copies (must exit 1, naming the anchor check alone — in
#                  one copy it would fail byte-identity first, and the
#                  anchor check would never be shown to fail); (c)
#                  `## Merge danger` moved after `## Next steps` in one
#                  Schema template, Schema F's and then Schema G's (must
#                  exit 1, naming placement alone and that schema's
#                  template); (d) the `- Merge danger:` line removed
#                  from the autopilot copy's reviewer report template (must
#                  exit 1, naming placement alone); (e) `## Merge danger`
#                  moved above `## Verdict` in the task-review copy's
#                  template (must exit 1, naming placement alone). The temp
#                  workdir is removed at the end.
#                  Exit 0 on self-test pass, 1 on unexpected results, 2 on
#                  fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

REVIEW_REL="plugins/kenspc/skills/task-review/SKILL.md"
IMPL_REL="plugins/kenspc/skills/task-implement/SKILL.md"
AUTOPILOT_REL="plugins/kenspc/skills/autopilot/SKILL.md"

START_MARKER="<!-- canonical:merge-danger:start -->"
END_MARKER="<!-- canonical:merge-danger:end -->"

# The labels each failing check prints; the self-test reads them to tell
# which check failed.
LABEL_IDENTITY="DRIFT canonical:merge-danger byte-identity"
LABEL_ANCHOR="MISSING canonical:merge-danger anchor"
LABEL_PLACEMENT="MISPLACED merge-danger placement"

# Template headings, as awk regular expressions (no backslashes, since
# awk -v would read them as escapes).
REVIEW_HEADING='^### Step 8: .*[(]Schema F[)]'
IMPL_HEADING='^### Step 4: .*[(]Schema G[)]'
AUTOPILOT_HEADING='^### The reviewer report$'

extract_block() {
    sed -n "/${START_MARKER}/,/${END_MARKER}/p" "$1"
}

# Print the lines inside the first fenced block after the first line that
# matches the heading regex; print nothing when either is absent.
extract_template() {
    awk -v h="$2" '
        state == 0 && $0 ~ h { state = 1; next }
        state == 1 && /^```/ { state = 2; next }
        state == 2 && /^```/ { exit }
        state == 2 { print }
    ' "$1"
}

# Print the line number of the first line equal to the given text, read
# from the here-string the caller passes; print nothing when absent.
line_of() {
    awk -v t="$1" '$0 == t { print NR; exit }' <<< "$2"
}

# Check one Schema template: `## Merge danger` after `## Verdict` and before
# `## Next steps`. Returns 0 placed, 1 misplaced, 2 template missing.
check_schema_placement() {
    local file="$1" heading="$2" name="$3"
    local tpl verdict merge next
    tpl=$(extract_template "$file" "$heading")
    if [[ -z "$tpl" ]]; then
        echo "ERROR: $name template (heading /$heading/ and its fenced block) not found in $file" >&2
        return 2
    fi
    verdict=$(line_of "## Verdict" "$tpl")
    merge=$(line_of "## Merge danger" "$tpl")
    next=$(line_of "## Next steps" "$tpl")
    if [[ -z "$verdict" || -z "$merge" || -z "$next" ]]; then
        echo "$LABEL_PLACEMENT — $name template in $file lacks a line: ## Verdict ${verdict:-absent}, ## Merge danger ${merge:-absent}, ## Next steps ${next:-absent}" >&2
        return 1
    fi
    if [[ "$verdict" -lt "$merge" && "$merge" -lt "$next" ]]; then
        return 0
    fi
    echo "$LABEL_PLACEMENT — $name template in $file: ## Merge danger at template line $merge is not between ## Verdict ($verdict) and ## Next steps ($next)" >&2
    return 1
}

run_main_logic() {
    local repo_root="$1"
    local review_file="$repo_root/$REVIEW_REL"
    local impl_file="$repo_root/$IMPL_REL"
    local autopilot_file="$repo_root/$AUTOPILOT_REL"

    local f block
    for f in "$review_file" "$impl_file" "$autopilot_file"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
        # Both markers, each checked: with the end marker missing, the sed
        # range would run to the end of the file and read as drift.
        if ! grep -qF -- "$START_MARKER" "$f" || ! grep -qF -- "$END_MARKER" "$f"; then
            echo "ERROR: canonical:merge-danger markers not found in $f" >&2
            return 2
        fi
    done

    # ---- Check 1: byte-identity, each carrier against task-review ----
    local identity_ok=1 ref_hash hash
    ref_hash=$(extract_block "$review_file" | sha256sum | awk '{print $1}')
    for f in "$impl_file" "$autopilot_file"; do
        hash=$(extract_block "$f" | sha256sum | awk '{print $1}')
        if [[ "$hash" != "$ref_hash" ]]; then
            identity_ok=0
            echo "$LABEL_IDENTITY — $f diverges from $review_file" >&2
            echo "      task-review sha256: $ref_hash" >&2
            echo "      this file sha256:   $hash" >&2
            diff <(extract_block "$review_file") <(extract_block "$f") >&2 || true
        fi
    done
    if [[ "$identity_ok" -eq 1 ]]; then
        echo "OK    canonical:merge-danger byte-identity — task-review, task-implement, and autopilot match"
        echo "      sha256: $ref_hash"
    else
        echo "The canonical:merge-danger block must be byte-identical in all three" >&2
        echo "skills. Apply the same edit to all three files in one commit." >&2
    fi

    # ---- Check 2: anchors inside each block ----
    local anchor_ok=1 anchor
    local anchors=("one-way" "two-way" "unclear" "Evidence:" "not found" "none named")
    for f in "$review_file" "$impl_file" "$autopilot_file"; do
        block=$(extract_block "$f")
        for anchor in "${anchors[@]}"; do
            if [[ "$block" != *"$anchor"* ]]; then
                anchor_ok=0
                echo "$LABEL_ANCHOR '$anchor' — not found inside the block of $f" >&2
            fi
        done
    done
    if [[ "$anchor_ok" -eq 1 ]]; then
        echo "OK    canonical:merge-danger anchors — all present in all three blocks"
    fi

    # ---- Check 3: placement inside the fenced templates ----
    # Each spec is "<file>|<heading regex>|<schema name>".
    local placement_ok=1 rc spec rest file heading name
    for spec in "$review_file|$REVIEW_HEADING|Schema F" "$impl_file|$IMPL_HEADING|Schema G"; do
        file="${spec%%|*}"; rest="${spec#*|}"
        heading="${rest%%|*}"
        name="${rest#*|}"
        check_schema_placement "$file" "$heading" "$name" && rc=0 || rc=$?
        if [[ "$rc" -eq 2 ]]; then
            return 2
        fi
        if [[ "$rc" -ne 0 ]]; then
            placement_ok=0
        fi
    done
    local tpl
    tpl=$(extract_template "$autopilot_file" "$AUTOPILOT_HEADING")
    if [[ -z "$tpl" ]]; then
        echo "ERROR: reviewer report template (heading /$AUTOPILOT_HEADING/ and its fenced block) not found in $autopilot_file" >&2
        return 2
    fi
    if [[ "$tpl" != "- Merge danger:"* && "$tpl" != *$'\n- Merge danger:'* ]]; then
        placement_ok=0
        echo "$LABEL_PLACEMENT — the reviewer report template in $autopilot_file holds no '- Merge danger:' line" >&2
    fi
    if [[ "$placement_ok" -eq 1 ]]; then
        echo "OK    merge-danger placement — Schema F and Schema G hold ## Merge danger between ## Verdict and ## Next steps; the reviewer report holds - Merge danger:"
    fi

    if [[ "$identity_ok" -eq 1 && "$anchor_ok" -eq 1 && "$placement_ok" -eq 1 ]]; then
        return 0
    fi
    return 1
}

# --- Self-test mode ---------------------------------------------------------

# Copy the three sources into the workdir, replacing any mutated copy.
copy_sources() {
    local rel
    for rel in "$REVIEW_REL" "$IMPL_REL" "$AUTOPILOT_REL"; do
        mkdir -p "$WORK/$(dirname "$rel")"
        cp "$REPO_ROOT/$rel" "$WORK/$rel"
    done
}

# Run the main check on the workdir; expect the given exit code, and, for a
# failure, exactly the one named label among the three, and the optional
# fourth argument's text in the output. Prints a FAIL line and returns 1 on
# any other result.
expect_result() {
    local want_rc="$1" want_label="$2" what="$3" want_text="${4:-}"
    local out rc label
    out=$( ( run_main_logic "$WORK" ) 2>&1 ) && rc=0 || rc=$?
    if [[ "$rc" -ne "$want_rc" ]]; then
        echo "FAIL  self-test $what: expected exit $want_rc, got $rc" >&2
        printf '%s\n' "$out" >&2
        return 1
    fi
    if [[ -n "$want_text" && "$out" != *"$want_text"* ]]; then
        echo "FAIL  self-test $what: output does not name $want_text" >&2
        printf '%s\n' "$out" >&2
        return 1
    fi
    for label in "$LABEL_IDENTITY" "$LABEL_ANCHOR" "$LABEL_PLACEMENT"; do
        if [[ "$label" == "$want_label" ]]; then
            if [[ "$out" != *"$label"* ]]; then
                echo "FAIL  self-test $what: output does not name the expected check ($label)" >&2
                printf '%s\n' "$out" >&2
                return 1
            fi
        elif [[ "$out" == *"$label"* ]]; then
            echo "FAIL  self-test $what: output names another check as well ($label)" >&2
            printf '%s\n' "$out" >&2
            return 1
        fi
    done
    return 0
}

# Substitute inside the canonical block of one copy only. `-i.bak` (suffix
# attached) and the `;` before `}` are the forms both GNU and BSD sed accept.
mutate_block() {
    local file="$1" from="$2" to="$3"
    sed -i.bak "/${START_MARKER}/,/${END_MARKER}/{s/${from}/${to}/g;}" "$file" && rm "$file.bak"
}

run_self_test() {
    # WORK is a global so the EXIT trap can reference it after this function
    # returns; under `set -u` a trap naming an unset local would fail.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    copy_sources
    local review_copy="$WORK/$REVIEW_REL"
    local word_from="reversible" word_to="revertible"
    local anchor_from="none named" anchor_to="nothing named"
    local f

    # Fixture-stale guards: each mutation target must be where it is mutated.
    if [[ "$(extract_block "$review_copy")" != *"$word_from"* ]]; then
        echo "FAIL  self-test fixture stale: \"$word_from\" not found inside the canonical:merge-danger block of $review_copy. Update word_from in run_self_test()." >&2
        return 2
    fi
    for f in "$review_copy" "$WORK/$IMPL_REL" "$WORK/$AUTOPILOT_REL"; do
        if [[ "$(extract_block "$f")" != *"$anchor_from"* ]]; then
            echo "FAIL  self-test fixture stale: anchor \"$anchor_from\" not found inside the canonical:merge-danger block of $f." >&2
            return 2
        fi
    done
    if [[ -z "$(line_of "## Merge danger" "$(extract_template "$review_copy" "$REVIEW_HEADING")")" ]]; then
        echo "FAIL  self-test fixture stale: no ## Merge danger line in the Schema F template of $review_copy." >&2
        return 2
    fi

    # Positive path.
    expect_result 0 "" "positive path (unmutated copies)" || return 1

    # (a) One word changed inside one copy's block, each copy in turn:
    # byte-identity alone. A carrier's own mutation must name that carrier,
    # so a carrier dropped from the comparison loop is caught.
    local want
    for f in "$review_copy" "$WORK/$IMPL_REL" "$WORK/$AUTOPILOT_REL"; do
        mutate_block "$f" "$word_from" "$word_to"
        if [[ "$(extract_block "$f")" != *"$word_to"* ]]; then
            echo "FAIL  self-test: mutation (a) did not apply inside the block of $f" >&2
            return 2
        fi
        want=""
        if [[ "$f" != "$review_copy" ]]; then
            want="$f diverges"
        fi
        expect_result 1 "$LABEL_IDENTITY" "mutation (a), one word changed in the block of $f" "$want" || return 1
        copy_sources
        expect_result 0 "" "revert after (a)" || return 1
    done

    # (b) An anchor replaced identically in all three copies: anchors alone.
    for f in "$review_copy" "$WORK/$IMPL_REL" "$WORK/$AUTOPILOT_REL"; do
        mutate_block "$f" "$anchor_from" "$anchor_to"
        if [[ "$(extract_block "$f")" == *"$anchor_from"* ]]; then
            echo "FAIL  self-test: mutation (b) left \"$anchor_from\" inside the block of $f" >&2
            return 2
        fi
    done
    expect_result 1 "$LABEL_ANCHOR" "mutation (b), anchor replaced in all three blocks" || return 1
    copy_sources
    expect_result 0 "" "revert after (b)" || return 1

    # (c) ## Merge danger moved after ## Next steps in one Schema template,
    # each in turn; the failure must name that template's schema, so a
    # template dropped from the placement loop is caught.
    local tpl moved_merge moved_next spec copy heading name
    for spec in "$review_copy|$REVIEW_HEADING|Schema F" "$WORK/$IMPL_REL|$IMPL_HEADING|Schema G"; do
        copy="${spec%%|*}"; heading="${spec#*|}"
        name="${heading#*|}"; heading="${heading%%|*}"
        awk -v h="$heading" '
            state == 0 && $0 ~ h { state = 1 }
            state == 1 && /^```/ { state = 2; print; next }
            state == 2 && /^```/ { state = 3 }
            state == 2 && $0 == "## Merge danger" { next }
            state == 2 && $0 == "## Next steps" { print; print ""; print "## Merge danger"; next }
            { print }
        ' "$copy" > "$copy.moved"
        mv "$copy.moved" "$copy"
        tpl=$(extract_template "$copy" "$heading")
        moved_merge=$(line_of "## Merge danger" "$tpl")
        moved_next=$(line_of "## Next steps" "$tpl")
        if [[ -z "$moved_merge" || -z "$moved_next" || "$moved_merge" -le "$moved_next" ]]; then
            echo "FAIL  self-test: mutation (c) did not move ## Merge danger after ## Next steps in $copy" >&2
            return 2
        fi
        expect_result 1 "$LABEL_PLACEMENT" "mutation (c), ## Merge danger after ## Next steps in $name" "$name template" || return 1
        copy_sources
        expect_result 0 "" "revert after (c)" || return 1
    done

    # (d) The reviewer report template's `- Merge danger:` field removed
    # from the autopilot copy: placement alone.
    local autopilot_copy="$WORK/$AUTOPILOT_REL"
    awk -v h="$AUTOPILOT_HEADING" '
        state == 0 && $0 ~ h { state = 1 }
        state == 1 && /^```/ { state = 2; print; next }
        state == 2 && /^```/ { state = 3 }
        state == 2 && /^- Merge danger:/ { next }
        { print }
    ' "$autopilot_copy" > "$autopilot_copy.cut"
    mv "$autopilot_copy.cut" "$autopilot_copy"
    tpl=$(extract_template "$autopilot_copy" "$AUTOPILOT_HEADING")
    if [[ -z "$tpl" || "$tpl" == "- Merge danger:"* || "$tpl" == *$'\n- Merge danger:'* ]]; then
        echo "FAIL  self-test: mutation (d) did not remove - Merge danger: from the reviewer report template of $autopilot_copy" >&2
        return 2
    fi
    expect_result 1 "$LABEL_PLACEMENT" "mutation (d), - Merge danger: removed from the reviewer report" || return 1
    copy_sources
    expect_result 0 "" "revert after (d)" || return 1

    # (e) ## Merge danger moved above ## Verdict in the Schema F template:
    # placement alone, so the "after ## Verdict" half of the order is held.
    awk -v h="$REVIEW_HEADING" '
        state == 0 && $0 ~ h { state = 1 }
        state == 1 && /^```/ { state = 2; print; next }
        state == 2 && /^```/ { state = 3 }
        state == 2 && $0 == "## Merge danger" { next }
        state == 2 && $0 == "## Verdict" { print "## Merge danger"; print ""; print; next }
        { print }
    ' "$review_copy" > "$review_copy.moved"
    mv "$review_copy.moved" "$review_copy"
    local moved_verdict
    tpl=$(extract_template "$review_copy" "$REVIEW_HEADING")
    moved_merge=$(line_of "## Merge danger" "$tpl")
    moved_verdict=$(line_of "## Verdict" "$tpl")
    if [[ -z "$moved_merge" || -z "$moved_verdict" || "$moved_merge" -ge "$moved_verdict" ]]; then
        echo "FAIL  self-test: mutation (e) did not move ## Merge danger above ## Verdict in $review_copy" >&2
        return 2
    fi
    expect_result 1 "$LABEL_PLACEMENT" "mutation (e), ## Merge danger above ## Verdict" || return 1
    copy_sources
    expect_result 0 "" "revert after (e)" || return 1

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
