#!/usr/bin/env bash
# check-run-contract.sh
#
# Guards the run-directory contract that task-review and task-implement share
# with code-fixer (v3.5.0). Five checks:
#
#   1. The run-directory preparation block (bounded by
#      `<!-- canonical:run-dir:start/end -->`) is byte-identical in
#      skills/task-review/SKILL.md and skills/task-implement/SKILL.md.
#   2. The Schema B statistics-line template (bounded by
#      `<!-- canonical:stats-line:start/end -->`) is byte-identical in
#      agents/code-fixer.md and both SKILLs. The orchestrators render the
#      line code-fixer writes, so the three must agree on its vocabulary.
#   3. The ignore probe in the run-dir block answers correctly: the path in
#      its `check-ignore -q <path>` command is run against two throwaway
#      repositories whose `.gitignore` uses CRLF line endings and holds a
#      blank line — without a `.kenspc/` rule it must exit 1, with one it
#      must exit 0. A blank CRLF line parses as an empty pattern that makes
#      git report the bare directory `.kenspc/` as ignored (seen on Windows
#      in the v3.5.0 smoke test); a path under the directory is immune.
#      Global and system git config are masked so a user-level ignore rule
#      cannot change the answer.
#   4. The worked Schema B example in agents/code-fixer.md (bounded by
#      `<!-- example:schema-b:start/end -->`) recounts: counting the Fixes
#      Applied rows reproduces its Per-angle Results table and its statistics
#      line, and the statistics line has the template's shape. The model
#      imitates this example, so an example that miscounts teaches miscounting.
#   5. The change-set file name: the literal `change-set.md` occurs at least
#      once in skills/task-review/SKILL.md, which writes the file, and in
#      agents/code-fixer.md, agents/regression-verifier.md, and
#      agents/requirements-reviewer.md, which read it; check-review-agent-drift.sh
#      carries the reviewers' shared sections to the other four reviewers. The
#      orchestrator and seven agents meet at this one name, so a rename in one
#      carrier breaks the exchange while every other check still passes. Each
#      file that does not name it is reported. The pre-fix record's index,
#      `pre-fix/index.txt`, is checked the same way in agents/code-fixer.md,
#      which writes it in an uncommitted run, and agents/regression-verifier.md,
#      which reads it.
#
# Check 4's recount rules (the same ones code-fixer and regression-verifier
# follow):
# each Source ID is `[REQBT]<number>` and appears in one row only; the first
# ID in a row is its primary and counts under the row's action, the others
# count as DEDUPED; an action is classified by its leading word (FIXED,
# DEFERRED, NOT APPLICABLE), so `NOT APPLICABLE — <reason>` counts as NOT
# APPLICABLE. Table cells are split on `|`, so a cell must not contain one.
#
# Exit code 0: all checks pass.
# Exit code 1: a block diverges, the ignore probe answers wrongly, the
#              recount disagrees, or a file does not name change-set.md.
# Exit code 2: missing file, missing or repeated markers, no git, no ignore
#              command in the run-dir block, or self-test fixture stale.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards. Mutations use a literal awk replacement rather than
# `sed -i`, whose in-place syntax differs between GNU and BSD sed.
#
# Optional flags:
#   --file PATH    Run only check 4, against a real schema-b.md (for example
#                  one under .kenspc/runs/<run-id>/ after a review run).
#   --self-test    Run the mutation regression fixture. Copies the five
#                  target files into a temp workdir, confirms `change-set.md`
#                  is present in the four files check 5 reads and
#                  `pre-fix/index.txt` in its two (exit 2 if not), and runs
#                  the main check on
#                  the unmodified copy (must exit 0 — the example carries a
#                  `NOT APPLICABLE — <reason>` row, so this also proves
#                  prefix classification), then on eleven mutations that must
#                  each exit 1: stats-line template changed in one SKILL,
#                  run-dir block changed in one SKILL, the ignore probe
#                  reverted to `.kenspc/` in both SKILLs (the Windows CRLF
#                  case, which only check 3 can catch), five recount
#                  mutations that each leave exactly one rule to catch them
#                  (an example row's action, one Per-angle Results cell, one
#                  statistics-line number, the statistics-line wording, and
#                  an ID repeated across rows with the counts adjusted to
#                  match), the change-set file name removed from each
#                  of the four copied files check 5 reads, one file at a
#                  time (every occurrence, through a replace-all helper,
#                  since it occurs on several lines), and the pre-fix index
#                  name removed from each of its two carriers in turn, then
#                  on the reverted copy (must exit 0). Exit 0 on self-test
#                  pass, 1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

FIXER_REL="plugins/kenspc/agents/code-fixer.md"
REVIEW_REL="plugins/kenspc/skills/task-review/SKILL.md"
IMPLEMENT_REL="plugins/kenspc/skills/task-implement/SKILL.md"
VERIFIER_REL="plugins/kenspc/agents/regression-verifier.md"
REVIEWER_REL="plugins/kenspc/agents/requirements-reviewer.md"
CHANGE_SET_NAME="change-set.md"
PRE_FIX_INDEX="pre-fix/index.txt"

# Print the lines strictly between the start and end markers of <name>.
# Returns 2 unless the file has exactly one start and one end marker.
extract_block() {
    local file="$1" name="$2"
    local start="<!-- ${name}:start -->" end="<!-- ${name}:end -->"
    local n_start n_end
    n_start=$(grep -cxF -- "$start" "$file" || true)
    n_end=$(grep -cxF -- "$end" "$file" || true)
    if [[ "$n_start" -ne 1 || "$n_end" -ne 1 ]]; then
        echo "ERROR: expected one '$name' marker pair in $file, found $n_start start / $n_end end" >&2
        return 2
    fi
    awk -v s="$start" -v e="$end" '
        { sub(/\r$/, "") }
        $0 == e { exit }
        in_block { print }
        $0 == s { in_block = 1 }
    ' "$file"
}

# Compare one named block across files; the first file is the reference.
compare_block() {
    local name="$1"; shift
    local ref_file="$1" ref_block block f rc
    ref_block=$(extract_block "$ref_file" "$name") || return $?
    for f in "${@:2}"; do
        block=$(extract_block "$f" "$name") || return $?
        if [[ "$block" != "$ref_block" ]]; then
            echo "DRIFT $name — $f differs from $ref_file:" >&2
            diff <(printf '%s\n' "$ref_block") <(printf '%s\n' "$block") >&2 || true
            return 1
        fi
    done
    return 0
}

# Turn the stats-line template into its shape: backticks dropped, each N / n
# count placeholder replaced by `#`.
template_shape() {
    local template="$1"
    printf '%s\n' "$template" | awk '
        {
            gsub(/`/, "")
            out = ""
            n = split($0, tok, " ")
            for (i = 1; i <= n; i++) {
                t = tok[i]
                if (t ~ /^[Nn][,)]*$/) t = "#" substr(t, 2)
                out = out (i > 1 ? " " : "") t
            }
            print out
        }'
}

# Check 4: recount a Schema B document against its own tables and stats line.
recount_schema_b() {
    local file="$1" shape="$2"
    awk -v shape="$shape" '
        function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
        function err(msg) { print "RECOUNT " msg > "/dev/stderr"; bad = 1 }
        { sub(/\r$/, "") }
        /^## / { section = $0; next }
        section == "## Fixes Applied" && /^\|/ {
            if ($0 ~ /^\|[ \t]*-/) next
            split($0, c, "|")
            src = trim(c[3]); act = trim(c[7])
            if (src == "Source") next
            rows++
            if (act ~ /^FIXED/) b = "F"
            else if (act ~ /^DEFERRED/) b = "D"
            else if (act ~ /^NOT APPLICABLE/) b = "N"
            else { err("row " rows ": unknown action \"" act "\""); next }
            k = split(src, ids, ",")
            for (j = 1; j <= k; j++) {
                id = trim(ids[j])
                if (id !~ /^[REQBT][0-9]+$/) { err("row " rows ": invalid ID \"" id "\""); continue }
                if (id in seen) { err("ID " id " appears in more than one row"); continue }
                seen[id] = 1
                a = substr(id, 1, 1)
                bucket = (j == 1) ? b : "X"
                cnt[a, bucket]++; tot[bucket]++; rep[a]++; total++
            }
            next
        }
        section == "## Per-angle Results" && /^\|/ {
            if ($0 ~ /^\|[ \t]*-/) next
            split($0, c, "|")
            a = trim(c[2])
            if (a == "Angle") next
            tbl[a, "F"] = trim(c[3]); tbl[a, "D"] = trim(c[4]); tbl[a, "N"] = trim(c[5])
            tbl[a, "X"] = trim(c[6]); tbl[a, "R"] = trim(c[7]); has_row[a] = 1
            next
        }
        { line = $0; gsub(/`/, "", line) }
        line ~ /^total reported / { stats = line }
        END {
            split("R E Q B T", angles, " ")
            split("F D N X", buckets, " ")
            for (i = 1; i <= 5; i++) {
                a = angles[i]
                if (!(a in has_row)) { err("Per-angle Results has no row for " a); continue }
                for (j = 1; j <= 4; j++) {
                    x = buckets[j]
                    if (tbl[a, x] + 0 != cnt[a, x] + 0)
                        err("Per-angle " a "/" x ": table says " tbl[a, x] ", rows give " cnt[a, x] + 0)
                }
                if (tbl[a, "R"] + 0 != rep[a] + 0)
                    err("Per-angle " a "/Reported: table says " tbl[a, "R"] ", rows give " rep[a] + 0)
            }
            if (stats == "") { err("no statistics line"); exit 1 }
            s = stats; m = 0
            while (match(s, /[0-9]+/)) {
                num[++m] = substr(s, RSTART, RLENGTH) + 0
                s = substr(s, 1, RSTART - 1) "#" substr(s, RSTART + RLENGTH)
            }
            if (s != shape) { err("statistics line does not match the template shape: " stats); exit 1 }
            want[1] = total + 0
            for (i = 1; i <= 5; i++) want[i + 1] = rep[angles[i]] + 0
            want[7] = rows + 0
            want[8] = tot["F"] + 0; want[9] = tot["D"] + 0; want[10] = tot["N"] + 0; want[11] = tot["X"] + 0
            split("total R E Q B T unique FIXED DEFERRED NOT_APPLICABLE DEDUPED", label, " ")
            for (i = 1; i <= 11; i++)
                if (num[i] != want[i]) err("statistics " label[i] ": line says " num[i] ", rows give " want[i])
            exit bad
        }
    ' "$file"
}

# Print the path argument of the first `check-ignore -q <path>` command in
# the given block text (the path ends at the closing backtick).
probe_path() {
    printf '%s\n' "$1" | awk '
        {
            i = index($0, "check-ignore -q ")
            if (!i) next
            s = substr($0, i + length("check-ignore -q "))
            j = index(s, "`")
            if (j) s = substr(s, 1, j - 1)
            print s
            exit
        }'
}

# Check 3: run the probe against a CRLF .gitignore with a blank line, once
# without and once with a `.kenspc/` rule. Returns 0/1/2.
probe_behaves() {
    local probe="$1" tmp rc_without rc_with
    if ! command -v git >/dev/null 2>&1; then
        echo "ERROR: git not found; the ignore-probe check needs it" >&2
        return 2
    fi
    tmp=$(mktemp -d)
    mkdir -p "$tmp/without-rule" "$tmp/with-rule"
    printf 'node_modules/\r\n\r\ndist/\r\n' > "$tmp/without-rule/.gitignore"
    printf 'node_modules/\r\n\r\n.kenspc/\r\n' > "$tmp/with-rule/.gitignore"
    # HOME / XDG_CONFIG_HOME point at the empty temp dir and system config is
    # skipped, so no global excludes file takes part in the answer.
    (
        export HOME="$tmp" XDG_CONFIG_HOME="$tmp" GIT_CONFIG_NOSYSTEM=1
        git -C "$tmp/without-rule" init -q
        git -C "$tmp/with-rule" init -q
    ) || { rm -rf "$tmp"; echo "ERROR: git init failed in $tmp" >&2; return 2; }
    HOME="$tmp" XDG_CONFIG_HOME="$tmp" GIT_CONFIG_NOSYSTEM=1 \
        git -C "$tmp/without-rule" check-ignore -q "$probe" && rc_without=0 || rc_without=$?
    HOME="$tmp" XDG_CONFIG_HOME="$tmp" GIT_CONFIG_NOSYSTEM=1 \
        git -C "$tmp/with-rule" check-ignore -q "$probe" && rc_with=0 || rc_with=$?
    rm -rf "$tmp"
    if [[ "$rc_without" -ne 1 || "$rc_with" -ne 0 ]]; then
        echo "PROBE '$probe': exit $rc_without without a .kenspc/ rule (want 1), exit $rc_with with one (want 0), in a CRLF .gitignore holding a blank line" >&2
        return 1
    fi
    return 0
}

# Run all checks (or only check 4 on an external file) against a repo root.
# Returns 0/1/2 via `return` (no `exit`).
run_main_logic() {
    local repo_root="$1" external="${2:-}"
    local fixer="$repo_root/$FIXER_REL"
    local review="$repo_root/$REVIEW_REL"
    local implement="$repo_root/$IMPLEMENT_REL"
    local verifier="$repo_root/$VERIFIER_REL"
    local reviewer="$repo_root/$REVIEWER_REL"
    local f rc template shape

    for f in "$fixer" "$review" "$implement" "$verifier" "$reviewer"; do
        if [[ ! -f "$f" ]]; then
            echo "ERROR: missing file $f" >&2
            return 2
        fi
    done

    template=$(extract_block "$fixer" "canonical:stats-line") || return $?
    shape=$(template_shape "$template")

    if [[ -n "$external" ]]; then
        if [[ ! -f "$external" ]]; then
            echo "ERROR: missing file $external" >&2
            return 2
        fi
        recount_schema_b "$external" "$shape" && rc=0 || rc=$?
        [[ "$rc" -eq 0 ]] && echo "OK    schema-b recount — $external agrees with its rows"
        return "$rc"
    fi

    compare_block "canonical:run-dir" "$review" "$implement" && rc=0 || rc=$?
    [[ "$rc" -ne 0 ]] && return "$rc"
    echo "OK    canonical:run-dir — identical in task-review and task-implement"

    local run_dir_block probe
    run_dir_block=$(extract_block "$review" "canonical:run-dir") || return $?
    probe=$(probe_path "$run_dir_block")
    if [[ -z "$probe" ]]; then
        echo "ERROR: no 'check-ignore -q <path>' command in the canonical:run-dir block" >&2
        return 2
    fi
    probe_behaves "$probe" && rc=0 || rc=$?
    [[ "$rc" -ne 0 ]] && return "$rc"
    echo "OK    ignore probe — '$probe' answers correctly with a CRLF .gitignore holding a blank line"

    compare_block "canonical:stats-line" "$fixer" "$review" "$implement" && rc=0 || rc=$?
    [[ "$rc" -ne 0 ]] && return "$rc"
    echo "OK    canonical:stats-line — identical in code-fixer, task-review, task-implement"

    local example_file
    example_file=$(mktemp)
    extract_block "$fixer" "example:schema-b" > "$example_file" && rc=0 || rc=$?
    if [[ "$rc" -eq 0 ]]; then
        recount_schema_b "$example_file" "$shape" && rc=0 || rc=$?
    fi
    rm -f "$example_file"
    [[ "$rc" -ne 0 ]] && return "$rc"
    echo "OK    example:schema-b — rows, Per-angle Results, and statistics line agree"

    local missing=0
    for f in "$review" "$fixer" "$verifier" "$reviewer"; do
        if ! grep -qF -- "$CHANGE_SET_NAME" "$f"; then
            echo "MISSING '$CHANGE_SET_NAME' in $f" >&2
            missing=1
        fi
    done
    for f in "$fixer" "$verifier"; do
        if ! grep -qF -- "$PRE_FIX_INDEX" "$f"; then
            echo "MISSING '$PRE_FIX_INDEX' in $f" >&2
            missing=1
        fi
    done
    if [[ "$missing" -ne 0 ]]; then
        echo "The orchestrator writes the change set to RUN_DIR/$CHANGE_SET_NAME, the agents" >&2
        echo "read it there, and code-fixer writes the pre-fix record's $PRE_FIX_INDEX for" >&2
        echo "regression-verifier. Restore the name, or rename it in every carrier and in" >&2
        echo "this guard together." >&2
        return 1
    fi
    echo "OK    $CHANGE_SET_NAME — named in task-review, code-fixer, regression-verifier, requirements-reviewer"
    echo "OK    $PRE_FIX_INDEX — named in code-fixer, regression-verifier"
    return 0
}

# --- Self-test mode ---------------------------------------------------------

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

# Replace every occurrence of a literal string in a file.
replace_all_literal() {
    local file="$1" old="$2" new="$3"
    awk -v old="$old" -v new="$new" '
        {
            out = ""; rest = $0
            while ((i = index(rest, old)) > 0) {
                out = out substr(rest, 1, i - 1) new
                rest = substr(rest, i + length(old))
            }
            print out rest
        }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

run_self_test() {
    # WORK is global (not local) so the EXIT trap can reference it safely
    # after this function returns. Under `set -u`, an EXIT trap that refers
    # to an unset local triggers an "unbound variable" error at fire time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    local rel
    for rel in "$FIXER_REL" "$REVIEW_REL" "$IMPLEMENT_REL" "$VERIFIER_REL" "$REVIEWER_REL"; do
        mkdir -p "$WORK/$(dirname "$rel")"
        cp "$REPO_ROOT/$rel" "$WORK/$rel"
    done

    local rc

    # Fixture-stale guard: the example must carry a NOT APPLICABLE row with a
    # reason, or the positive path would not prove prefix classification.
    # Each mutation also checks its own target below.
    # The leading `| ` matches a table cell only, not the same words in prose.
    if ! grep -qF -- "| NOT APPLICABLE — " "$WORK/$FIXER_REL"; then
        echo "FAIL  self-test fixture stale: no '| NOT APPLICABLE — <reason>' row in $FIXER_REL" >&2
        return 2
    fi

    # Fixture-stale guard for check 5: every file it reads must name the
    # change-set file, or the positive path would already fail there.
    for rel in "$REVIEW_REL" "$FIXER_REL" "$VERIFIER_REL" "$REVIEWER_REL"; do
        if ! grep -qF -- "$CHANGE_SET_NAME" "$WORK/$rel"; then
            echo "FAIL  self-test fixture stale: '$CHANGE_SET_NAME' not found in $rel" >&2
            return 2
        fi
    done
    for rel in "$FIXER_REL" "$VERIFIER_REL"; do
        if ! grep -qF -- "$PRE_FIX_INDEX" "$WORK/$rel"; then
            echo "FAIL  self-test fixture stale: '$PRE_FIX_INDEX' not found in $rel" >&2
            return 2
        fi
    done

    # mutate_and_expect <label> <file> <old> <new> [<old> <new> ...]: apply
    # one or more literal replacements to one file, expect the main check to
    # exit 1, then restore the file. A multi-pair mutation keeps the counts
    # consistent so that exactly one rule is left to catch it.
    mutate_and_expect() {
        local label="$1" target="$2" old new hits
        shift 2
        while [[ $# -ge 2 ]]; do
            old="$1" new="$2"
            shift 2
            # The literal must occur on exactly one line, or the mutation
            # could land where the check does not read and prove nothing.
            hits=$(grep -cF -- "$old" "$WORK/$target" || true)
            if [[ "$hits" -ne 1 ]]; then
                echo "FAIL  self-test fixture stale: \"$old\" found on $hits lines of $target, expected 1 ($label)" >&2
                return 2
            fi
            replace_literal "$WORK/$target" "$old" "$new"
        done
        ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
        cp "$REPO_ROOT/$target" "$WORK/$target"
        if [[ "$rc" -ne 1 ]]; then
            echo "FAIL  self-test $label mutation: expected exit 1, got $rc" >&2
            return 1
        fi
    }

    # mutate_files_and_expect <label> <old> <new> <file>...: apply the same
    # literal replacement to several files, expect exit 1, restore them.
    mutate_files_and_expect() {
        local label="$1" old="$2" new="$3" target hits
        shift 3
        for target in "$@"; do
            hits=$(grep -cF -- "$old" "$WORK/$target" || true)
            if [[ "$hits" -ne 1 ]]; then
                echo "FAIL  self-test fixture stale: \"$old\" found on $hits lines of $target, expected 1 ($label)" >&2
                return 2
            fi
            replace_literal "$WORK/$target" "$old" "$new"
        done
        ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
        for target in "$@"; do
            cp "$REPO_ROOT/$target" "$WORK/$target"
        done
        if [[ "$rc" -ne 1 ]]; then
            echo "FAIL  self-test $label mutation: expected exit 1, got $rc" >&2
            return 1
        fi
    }

    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test positive path: expected exit 0 on unmutated copy, got $rc" >&2
        return 1
    fi

    # Block drift: one SKILL's copy of a canonical block changes.
    mutate_and_expect "stats-line template" "$IMPLEMENT_REL" \
        "NOT APPLICABLE N, DEDUPED N" "NOT APPLICABLE N, MERGED N" || return $?
    mutate_and_expect "run-dir block" "$REVIEW_REL" \
        "- Scratch space:" "- Scratch area:" || return $?
    # The Windows case: the probe reverted to the bare directory in both
    # SKILLs, so the blocks stay identical and only the probe check can
    # catch it. If a future git stops parsing a blank CRLF line as an empty
    # pattern, this mutation passes and the self-test reports it.
    mutate_files_and_expect "probe reverted to .kenspc/" \
        "check-ignore -q .kenspc/runs/probe" "check-ignore -q .kenspc/" \
        "$REVIEW_REL" "$IMPLEMENT_REL" || return $?
    # Recount: each mutation below breaks exactly one recount rule.
    mutate_and_expect "example row action" "$FIXER_REL" \
        "| NOT APPLICABLE — cited rule not in CLAUDE.md |" "| DEFERRED |" || return $?
    mutate_and_expect "per-angle cell" "$FIXER_REL" \
        "| Q     | 0     | 0        | 1              |" "| Q     | 0     | 1        | 0              |" || return $?
    mutate_and_expect "example statistics number" "$FIXER_REL" \
        "FIXED 3, DEFERRED 1" "FIXED 2, DEFERRED 1" || return $?
    mutate_and_expect "example statistics wording" "$FIXER_REL" \
        "deduplicated to 5 unique" "deduplicated to 5 distinct" || return $?
    # R1 repeated as a non-primary ID, with the table and statistics line
    # updated to match, so only the one-row-per-ID rule can catch it.
    mutate_and_expect "repeated example ID" "$FIXER_REL" \
        "| T1     |" "| T1, R1 |" \
        "| R     | 0     | 1        | 0              | 0       | 1        |" \
        "| R     | 0     | 1        | 0              | 1       | 2        |" \
        "total reported 6 (R 1," "total reported 7 (R 2," \
        "NOT APPLICABLE 1, DEDUPED 1" "NOT APPLICABLE 1, DEDUPED 2" || return $?
    # Check 5: the change-set file renamed in one carrier at a time, every
    # occurrence, so only the name check can catch it. Each of the four
    # files check 5 reads is mutated in turn, so a carrier dropped from its
    # loop is caught too. The name occurs on several lines in a carrier,
    # which mutate_and_expect's one-line rule refuses.
    for rel in "$REVIEW_REL" "$FIXER_REL" "$VERIFIER_REL" "$REVIEWER_REL"; do
        replace_all_literal "$WORK/$rel" "$CHANGE_SET_NAME" "change-list.md"
        if grep -qF -- "$CHANGE_SET_NAME" "$WORK/$rel"; then
            echo "FAIL  self-test: change-set mutation did not apply ('$CHANGE_SET_NAME' still in $rel)" >&2
            return 2
        fi
        ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
        cp "$REPO_ROOT/$rel" "$WORK/$rel"
        if [[ "$rc" -ne 1 ]]; then
            echo "FAIL  self-test change-set name mutation in $rel: expected exit 1, got $rc" >&2
            return 1
        fi
    done
    # The pre-fix index name, renamed in each of its two carriers in turn.
    for rel in "$FIXER_REL" "$VERIFIER_REL"; do
        replace_all_literal "$WORK/$rel" "$PRE_FIX_INDEX" "pre-fix/list.txt"
        if grep -qF -- "$PRE_FIX_INDEX" "$WORK/$rel"; then
            echo "FAIL  self-test: pre-fix index mutation did not apply ('$PRE_FIX_INDEX' still in $rel)" >&2
            return 2
        fi
        ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
        cp "$REPO_ROOT/$rel" "$WORK/$rel"
        if [[ "$rc" -ne 1 ]]; then
            echo "FAIL  self-test pre-fix index mutation in $rel: expected exit 1, got $rc" >&2
            return 1
        fi
    done

    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test restoration path: expected exit 0 after revert, got $rc" >&2
        return 1
    fi

    echo "OK    self-test passed for $(basename "$0")"
    return 0
}

# --- Dispatch ---------------------------------------------------------------

case "${1:-}" in
    --self-test)
        run_self_test
        exit $?
        ;;
    --file)
        if [[ -z "${2:-}" ]]; then
            echo "usage: $(basename "$0") [--self-test | --file PATH]" >&2
            exit 2
        fi
        run_main_logic "$REPO_ROOT" "$2"
        exit $?
        ;;
esac

run_main_logic "$REPO_ROOT"
exit $?
