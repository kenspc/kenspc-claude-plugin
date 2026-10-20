#!/usr/bin/env bash
# check-review-bar-canonical.sh
#
# Guards the review bar: the five review-angle agents' REVIEW CHECKLIST
# sections, written once in plugins/kenspc/shared/review-bar.md (the
# reference task-implementer reads before its first task) and carried inline
# by each agent. Three checks:
#
#   1. Byte identity. For each angle key (requirements, edge-case, quality,
#      bug, test), the block between
#        <!-- canonical:review-bar:<key>:start -->
#      and
#        <!-- canonical:review-bar:<key>:end -->
#      appears exactly once, with content, in both review-bar.md and
#      plugins/kenspc/agents/<key>-reviewer.md, and the two blocks are
#      identical.
#   2. Full coverage. In each agent, the block sits inside REVIEW CHECKLIST
#      (from that header line to the "OUTPUT FORMAT (Schema A)" line), and
#      every line of that section outside the block is blank. Why: a check
#      added below the end marker would reach the reviewer but never the
#      implementer, which is the gap the shared file exists to close.
#   3. Reader. plugins/kenspc/agents/task-implementer.md names the file as
#      ${CLAUDE_PLUGIN_ROOT}/shared/review-bar.md, so the implementer is
#      told to read it.
#
# Exit code 0: all three checks pass.
# Exit code 1: drift (a block differs, a line sits outside a block, or the
#              implementer no longer names the file).
# Exit code 2: missing input file, malformed markers, or self-test fixture
#              stale.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards; bash 3.2 compatible (no associative arrays). Self-test
# mutations use awk rewrites rather than `sed -i`, whose in-place syntax
# differs between GNU and BSD sed.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the seven
#                  input files into a temp workdir and checks five paths:
#                  the unmodified copy (must exit 0); one word changed in
#                  review-bar.md's test block (must exit 1); a line added to
#                  test-reviewer.md's REVIEW CHECKLIST below its end marker
#                  (must exit 1); the path removed from task-implementer.md
#                  (must exit 1); the restored copy (must exit 0). Exit 0 on
#                  self-test pass, 1 on unexpected exit codes, 2 on
#                  fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

KEYS=("requirements" "edge-case" "quality" "bug" "test")
READER_PATH='${CLAUDE_PLUGIN_ROOT}/shared/review-bar.md'

extract_block() {
    local file="$1"
    local key="$2"
    awk -v s="<!-- canonical:review-bar:${key}:start -->" \
        -v e="<!-- canonical:review-bar:${key}:end -->" '
        $0 == s { p = 1 }
        p { print }
        $0 == e { p = 0 }
    ' "$file"
}

# Prints "<markers inside the section> <non-blank lines outside the block>"
# for one agent's REVIEW CHECKLIST section.
section_report() {
    local file="$1"
    local key="$2"
    awk -v s="<!-- canonical:review-bar:${key}:start -->" \
        -v e="<!-- canonical:review-bar:${key}:end -->" '
        $0 == "REVIEW CHECKLIST" { sec = 1; next }
        $0 == "OUTPUT FORMAT (Schema A)" { sec = 0 }
        !sec { next }
        $0 == s { markers++; inblock = 1; next }
        $0 == e { markers++; inblock = 0; next }
        !inblock && $0 !~ /^[[:space:]]*$/ { stray++ }
        END { printf "%d %d\n", markers + 0, stray + 0 }
    ' "$file"
}

run_main_logic() {
    local repo_root="$1"
    local shared_file="$repo_root/plugins/kenspc/shared/review-bar.md"
    local implementer_file="$repo_root/plugins/kenspc/agents/task-implementer.md"

    local f key agent_file
    for f in "$shared_file" "$implementer_file"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
    done

    # Pre-flight: one marker pair with content per key in both files.
    local start_marker end_marker start_count end_count body
    for key in "${KEYS[@]}"; do
        agent_file="$repo_root/plugins/kenspc/agents/${key}-reviewer.md"
        if [[ ! -f "$agent_file" ]]; then
            echo "ERROR: missing file $agent_file" >&2
            return 2
        fi
        start_marker="<!-- canonical:review-bar:${key}:start -->"
        end_marker="<!-- canonical:review-bar:${key}:end -->"
        for f in "$shared_file" "$agent_file"; do
            start_count=$(grep -c -F -x -- "$start_marker" "$f" || true)
            end_count=$(grep -c -F -x -- "$end_marker" "$f" || true)
            if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
                echo "ERROR: canonical:review-bar:${key} markers malformed in $f" >&2
                echo "       expected exactly 1 start and 1 end marker line; found ${start_count} start and ${end_count} end" >&2
                return 2
            fi
            body=$(extract_block "$f" "$key" | sed -e '1d' -e '$d')
            if [[ -z "${body//[[:space:]]/}" ]]; then
                echo "ERROR: canonical:review-bar:${key} block in $f has no content between markers" >&2
                return 2
            fi
        done
    done

    local drift=0 shared_block agent_block report markers stray
    for key in "${KEYS[@]}"; do
        agent_file="$repo_root/plugins/kenspc/agents/${key}-reviewer.md"

        # Check 1: byte identity.
        shared_block=$(extract_block "$shared_file" "$key")
        agent_block=$(extract_block "$agent_file" "$key")
        if [[ "$shared_block" == "$agent_block" ]]; then
            echo "OK    ${key}: block identical in review-bar.md and ${key}-reviewer.md"
        else
            echo "FAIL  ${key}: block in review-bar.md differs from ${key}-reviewer.md" >&2
            diff <(printf '%s\n' "$shared_block") <(printf '%s\n' "$agent_block") >&2 || true
            drift=1
        fi

        # Check 2: the block covers the whole REVIEW CHECKLIST section.
        report=$(section_report "$agent_file" "$key")
        markers=${report% *}
        stray=${report#* }
        if [[ "$markers" -ne 2 ]]; then
            echo "FAIL  ${key}: ${key}-reviewer.md's REVIEW CHECKLIST holds ${markers} of its 2 marker lines" >&2
            drift=1
        elif [[ "$stray" -ne 0 ]]; then
            echo "FAIL  ${key}: ${key}-reviewer.md's REVIEW CHECKLIST holds ${stray} non-blank line(s) outside the canonical block" >&2
            drift=1
        else
            echo "OK    ${key}: REVIEW CHECKLIST is the canonical block alone"
        fi
    done

    # Check 3: the implementer names the file.
    if grep -q -F -- "$READER_PATH" "$implementer_file"; then
        echo "OK    task-implementer.md names $READER_PATH"
    else
        echo "FAIL  task-implementer.md does not name $READER_PATH" >&2
        drift=1
    fi

    if [[ "$drift" -ne 0 ]]; then
        echo "" >&2
        echo "The review bar drifted. Change each REVIEW CHECKLIST in its agent and in" >&2
        echo "plugins/kenspc/shared/review-bar.md together, keep every line of the" >&2
        echo "section inside the canonical block, and keep task-implementer.md naming" >&2
        echo "the file." >&2
        return 1
    fi
    return 0
}

# --- Self-test mode ---------------------------------------------------------

# Rewrites the first line equal to $2 in file $1 to $3 (awk, not sed -i).
replace_line() {
    local file="$1" old="$2" new="$3"
    awk -v o="$old" -v n="$new" '!done && $0 == o { print n; done = 1; next } { print }' \
        "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

expect_rc() {
    local want="$1" label="$2" rc
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne "$want" ]]; then
        echo "FAIL  self-test ${label}: expected exit ${want}, got ${rc}" >&2
        return 1
    fi
    return 0
}

restore() {
    cp "$REPO_ROOT/$1" "$WORK/$1"
}

run_self_test() {
    # WORK is global so the EXIT trap can reference it after this function
    # returns (an unset local under `set -u` would fail at trap time).
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    local rel key
    local files=("plugins/kenspc/shared/review-bar.md" "plugins/kenspc/agents/task-implementer.md")
    for key in "${KEYS[@]}"; do
        files+=("plugins/kenspc/agents/${key}-reviewer.md")
    done
    mkdir -p "$WORK/plugins/kenspc/shared" "$WORK/plugins/kenspc/agents"
    for rel in "${files[@]}"; do
        cp "$REPO_ROOT/$rel" "$WORK/$rel"
    done

    local shared_rel="plugins/kenspc/shared/review-bar.md"
    local test_rel="plugins/kenspc/agents/test-reviewer.md"
    local impl_rel="plugins/kenspc/agents/task-implementer.md"
    local word_old='- Bypassed test: an existing test still passes but no longer reaches the'
    local word_new='- Skipped test: an existing test still passes but no longer reaches the'
    local end_marker='<!-- canonical:review-bar:test:end -->'

    # Fixture-stale guards: each mutation target must be present.
    if ! grep -q -F -x -- "$word_old" "$WORK/$shared_rel"; then
        echo "FAIL  self-test fixture stale: \"$word_old\" not found in $shared_rel. Update run_self_test()." >&2
        return 2
    fi
    if ! grep -q -F -x -- "$end_marker" "$WORK/$test_rel"; then
        echo "FAIL  self-test fixture stale: \"$end_marker\" not found in $test_rel. Update run_self_test()." >&2
        return 2
    fi
    if ! grep -q -F -- "$READER_PATH" "$WORK/$impl_rel"; then
        echo "FAIL  self-test fixture stale: \"$READER_PATH\" not found in $impl_rel. Update run_self_test()." >&2
        return 2
    fi

    expect_rc 0 "positive path" || return 1

    # Check 1's negative path: a word changed in the shared block.
    replace_line "$WORK/$shared_rel" "$word_old" "$word_new"
    expect_rc 1 "changed word in review-bar.md" || return 1
    restore "$shared_rel"

    # Check 2's negative path: a checklist line below the end marker.
    awk -v m="$end_marker" '{ print } $0 == m { print "- Added check: a line the implementer would never see." }' \
        "$WORK/$test_rel" > "$WORK/$test_rel.tmp" && mv "$WORK/$test_rel.tmp" "$WORK/$test_rel"
    expect_rc 1 "line outside the block in test-reviewer.md" || return 1
    restore "$test_rel"

    # Check 3's negative path: the implementer no longer names the file.
    # index/substr, not gsub: the path holds regex metacharacters.
    awk -v p="$READER_PATH" '{
        out = ""
        while ((i = index($0, p)) > 0) {
            out = out substr($0, 1, i - 1) "the review bar"
            $0 = substr($0, i + length(p))
        }
        print out $0
    }' "$WORK/$impl_rel" > "$WORK/$impl_rel.tmp" && mv "$WORK/$impl_rel.tmp" "$WORK/$impl_rel"
    if grep -q -F -- "$READER_PATH" "$WORK/$impl_rel"; then
        echo "FAIL  self-test: path removal did not apply in $impl_rel" >&2
        return 2
    fi
    expect_rc 1 "path removed from task-implementer.md" || return 1
    restore "$impl_rel"

    expect_rc 0 "restoration path" || return 1

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
