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
#              files, AND the anchor-phrase frequency check passes.
# Exit code 1: drift detected (at least one key's hashes do not agree, or
#              an anchor phrase is missing from a file).
# Exit code 2: missing input file or markers not found.
#
# Modeled on check-canonical-dispatch.sh; same set -euo pipefail discipline
# and same sed -n extraction technique.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the three
#                  target files into a temp workdir, runs the main check
#                  (must exit 0), mutates one canonical region (must exit
#                  1), then reverts (must exit 0). Opt-in: invocation with
#                  no arguments behaves unchanged. Exit 0 on self-test
#                  pass, 1 on unexpected exit codes, 2 on fixture-stale
#                  (mutation target not present in the canonical content).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Run the main check against a given repo root. Uses local variables so
# the function can be called multiple times with different REPO_ROOTs
# during --self-test. Returns 0/1/2 via `return` (no `exit`) so a caller
# (the self-test) can branch on the result.
run_main_logic() {
    local repo_root="$1"
    local shared_file="$repo_root/plugins/kenspc/shared/code-craft-principles.md"
    local implementer_file="$repo_root/plugins/kenspc/agents/task-implementer.md"
    local fixer_file="$repo_root/plugins/kenspc/agents/code-fixer.md"

    local files=("$shared_file" "$implementer_file" "$fixer_file")
    local keys=("simplicity-first" "surgical-changes")

    extract_block() {
        local file="$1"
        local key="$2"
        sed -n "/<!-- canonical:principle:${key}:start -->/,/<!-- canonical:principle:${key}:end -->/p" "$file"
    }

    # Pre-flight: every file must exist; every key's marker pair must be
    # present in every file.
    local f
    for f in "${files[@]}"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
    done

    local key start_marker end_marker start_count end_count block_body
    for key in "${keys[@]}"; do
        start_marker="<!-- canonical:principle:${key}:start -->"
        end_marker="<!-- canonical:principle:${key}:end -->"
        for f in "${files[@]}"; do
            # Exactly one start-marker line and one end-marker line per file.
            # A missing end marker would cause sed to swallow content from
            # start to EOF; a duplicated marker pair would let sed concatenate
            # two blocks and a corrupted state could pass the byte-identity
            # check below if all three files were similarly corrupted.
            start_count=$(grep -c -F "$start_marker" "$f" || true)
            end_count=$(grep -c -F "$end_marker" "$f" || true)
            if [[ "$start_count" -ne 1 || "$end_count" -ne 1 ]]; then
                echo "ERROR: canonical:principle:${key} markers malformed in $f" >&2
                echo "       expected exactly 1 start and 1 end marker; found ${start_count} start and ${end_count} end" >&2
                return 2
            fi
            # Non-empty content between markers (strip the two marker lines
            # and require at least one remaining non-empty line).
            block_body=$(extract_block "$f" "$key" | sed -e "1d" -e "\$d")
            if [[ -z "${block_body// }" ]]; then
                echo "ERROR: canonical:principle:${key} block in $f has no content between markers" >&2
                return 2
            fi
        done
    done

    local drift_found=0
    local shared_hash implementer_hash fixer_hash
    for key in "${keys[@]}"; do
        shared_hash=$(extract_block "$shared_file" "$key" | sha256sum | awk '{print $1}')
        implementer_hash=$(extract_block "$implementer_file" "$key" | sha256sum | awk '{print $1}')
        fixer_hash=$(extract_block "$fixer_file" "$key" | sha256sum | awk '{print $1}')

        if [[ "$shared_hash" == "$implementer_hash" && "$shared_hash" == "$fixer_hash" ]]; then
            echo "OK    canonical:principle:${key} byte-identity — shared, task-implementer, code-fixer all match"
            echo "      sha256: $shared_hash"
        else
            drift_found=1
            echo "DRIFT canonical:principle:${key} — files disagree" >&2
            echo "      shared/code-craft-principles.md sha256: $shared_hash" >&2
            echo "      agents/task-implementer.md sha256:      $implementer_hash" >&2
            echo "      agents/code-fixer.md sha256:            $fixer_hash" >&2

            # Identify the outlier(s): pick the file whose hash disagrees
            # with the authoritative shared file, and diff each outlier
            # against it.
            if [[ "$implementer_hash" != "$shared_hash" ]]; then
                echo "" >&2
                echo "Outlier: agents/task-implementer.md (diff vs shared file):" >&2
                diff <(extract_block "$shared_file" "$key") \
                     <(extract_block "$implementer_file" "$key") >&2 || true
            fi
            if [[ "$fixer_hash" != "$shared_hash" ]]; then
                echo "" >&2
                echo "Outlier: agents/code-fixer.md (diff vs shared file):" >&2
                diff <(extract_block "$shared_file" "$key") \
                     <(extract_block "$fixer_file" "$key") >&2 || true
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
        # Continue to Check 2 anyway so a single run reports both failure modes
        # (byte-identity AND anchor-phrase frequency) when both apply. The final
        # exit code is still 1 — see `drift_found` accumulation below.
    fi

    # ---- Check 2: anchor phrase frequency ----
    #
    # Brief item #31 named "outside the byte-identity hash range" — but the
    # two writer-agent files contain the anchor labels only inside the
    # canonical block. Counting "outside" the block in those files would
    # always return 0 and produce a vacuous check. The refined scope is
    # "anywhere in file": the failure mode the brief targeted (a
    # synchronized edit that replaces the canonical block in all three
    # files with content that drops the anchor) is still caught — the
    # byte-identity check passes after such an edit, but the new
    # "Simplicity First" / "Surgical Changes" anchor must remain present
    # somewhere in each file for the check to pass.
    local anchors=(
        "Simplicity First|1"
        "Surgical Changes|1"
    )

    count_phrase_in_file() {
        # Count occurrences of a literal phrase (case-insensitive) in a
        # file. grep returns 1 on no match, which under `set -o pipefail`
        # would collapse the pipeline; tolerate that explicitly so a 0
        # count is reported as "0" instead of failing the script.
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

    local anchor_ok=1
    local spec phrase min count
    for spec in "${anchors[@]}"; do
        phrase="${spec%|*}"
        min="${spec##*|}"
        for f in "${files[@]}"; do
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
        return 1
    fi

    return 0
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. Copies the three target files into a
# temp workdir, runs the main check (expect 0), mutates one canonical
# region (expect 1), reverts (expect 0). The mutation rewrites every
# occurrence of the bare phrase `Simplicity First` to `Simplicity 1st`
# in the shared file (4 occurrences in the current tree: H2 header,
# description paragraph, the bolded sentence inside the canonical block,
# and the trailing checklist sentence). This breaks BOTH
#   (a) the byte-identity check (the canonical block in the shared file
#       diverges from the inlined copies in the two writer agents), and
#   (b) the anchor-phrase frequency check (the "Simplicity First" anchor
#       count in the shared file drops from 4 to 0 — below the minimum
#       of 1).
# Hitting all occurrences (not just the bolded one) is what exercises
# Check 2; mutating only `**Simplicity First.**` would leave 3 anchor
# matches behind and Check 2 would silently still pass.
run_self_test() {
    # WORK is set as a global (not local) so the EXIT trap can reference it
    # safely after this function returns. Under `set -u`, an EXIT trap that
    # refers to an unset local variable triggers an "unbound variable"
    # error at trap-firing time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    # Replicate the relative paths the main logic expects.
    mkdir -p "$WORK/plugins/kenspc/shared" "$WORK/plugins/kenspc/agents"
    cp "$REPO_ROOT/plugins/kenspc/shared/code-craft-principles.md" "$WORK/plugins/kenspc/shared/code-craft-principles.md"
    cp "$REPO_ROOT/plugins/kenspc/agents/task-implementer.md" "$WORK/plugins/kenspc/agents/task-implementer.md"
    cp "$REPO_ROOT/plugins/kenspc/agents/code-fixer.md" "$WORK/plugins/kenspc/agents/code-fixer.md"

    local mutation_target='Simplicity First'
    local mutation_replacement='Simplicity 1st'
    local target_file="$WORK/plugins/kenspc/shared/code-craft-principles.md"

    # Fixture-stale guard: if the mutation target phrase is not present in
    # the canonical content, the self-test cannot meaningfully assert the
    # negative path. Exit 2 with a clear message naming the maintenance
    # action.
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

    # Apply mutation to every occurrence of the bare phrase in the shared
    # file. Replacing all occurrences (not just the bolded one inside the
    # canonical block) is what drives the anchor count to 0 and exercises
    # Check 2 alongside the byte-identity divergence in Check 1.
    sed -i "s|${mutation_target}|${mutation_replacement}|g" "$target_file"
    if grep -qF -- "$mutation_target" "$target_file"; then
        echo "FAIL  self-test: mutation did not apply (target phrase still present in $target_file)" >&2
        return 2
    fi

    # Negative path: main check on the mutated copy must exit 1.
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path: expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Revert the mutation by recopying the source.
    cp "$REPO_ROOT/plugins/kenspc/shared/code-craft-principles.md" "$target_file"
    if ! grep -qF -- "$mutation_target" "$target_file"; then
        echo "FAIL  self-test: revert did not restore the target phrase in $target_file" >&2
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
