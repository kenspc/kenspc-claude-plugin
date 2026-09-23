#!/usr/bin/env bash
# check-no-model-names.sh
#
# Guards that no file under plugins/kenspc/{skills,agents,commands,shared}/
# names or pins a specific Claude model. Skills and agents follow the
# session's model and effort; a model name in a prompt pins the prompt to one
# generation and goes stale silently at the next one (v3.5.0 retired the last
# such pins).
#
# Three rules, each hit reported with file:line:
#
#   1. Frontmatter `model:` values must be `inherit`. Only the frontmatter
#      block (between the opening `---` and the next `---`) is checked, so
#      prose that mentions a `model:` parameter is not a hit. This rule
#      catches aliases the name rules below cannot know about.
#   2. A model family name as a whole word, case-insensitive: opus, sonnet,
#      haiku, fable. Case-insensitive so lowercase aliases in prose
#      (`model: opus`, "dispatch with sonnet") are caught too; an ordinary
#      English use of one of these words fails loudly and is fixed by
#      rewording, which is preferred over a silent miss.
#   3. A model-ID prefix, case-insensitive: `claude-` followed by a letter or
#      digit (claude-opus-..., claude-3-...). The plugin's own `.claude-plugin`
#      directory name is stripped from each line before this rule is tested,
#      so a line that mentions both `.claude-plugin` and a real model ID is
#      still reported — the exclusion removes the directory name, not the
#      line. `${CLAUDE_PLUGIN_ROOT}` never matches (underscore, not hyphen).
#
# Trailing carriage returns are stripped first so CRLF checkouts on Windows
# parse the frontmatter delimiters the same way as LF checkouts.
#
# Exit code 0: no model names found.
# Exit code 1: at least one model name found (each hit is printed).
# Exit code 2: missing input directory, or self-test fixture stale.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards. Self-test mutations use printf / awk rewrites rather than
# `sed -i`, whose in-place syntax differs between GNU and BSD sed.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the four
#                  scanned directories into a temp workdir and checks nine
#                  paths: three that must exit 0 (unmodified copy, a
#                  `.claude-plugin`-only line, a `model:` mention in body
#                  prose), five that must exit 1 (a capitalized and a
#                  lowercase family name, a model ID sharing a line with
#                  `.claude-plugin`, frontmatter `model: opus`, frontmatter
#                  `model: fast-path`), and the reverted copy (must exit 0).
#                  Opt-in: invocation with no
#                  arguments behaves unchanged. Exit 0 on self-test pass, 1 on
#                  unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SCANNED_DIRS=(skills agents commands shared)

# Run the main check against a given repo root. Uses local variables so the
# function can be called multiple times with different REPO_ROOTs during
# --self-test. Returns 0/1/2 via `return` (no `exit`).
run_main_logic() {
    local repo_root="$1"
    local dirs=()
    local name
    for name in "${SCANNED_DIRS[@]}"; do
        dirs+=("$repo_root/plugins/kenspc/$name")
    done

    local d
    for d in "${dirs[@]}"; do
        if [[ ! -d "$d" ]]; then
            echo "ERROR: missing directory $d" >&2
            return 2
        fi
    done

    local hits
    hits=$(find "${dirs[@]}" -type f -exec awk '
        {
            line = $0
            sub(/\r$/, "", line)

            # Rule 1: frontmatter model: must be inherit.
            if (FNR == 1) {
                in_fm = (line == "---")
                if (in_fm) next
            } else if (in_fm && line == "---") {
                in_fm = 0
                next
            }
            if (in_fm && line ~ /^model:/) {
                value = line
                sub(/^model:[ \t]*/, "", value)
                sub(/[ \t]+$/, "", value)
                gsub(/["\047]/, "", value)
                if (value != "inherit")
                    print FILENAME ":" FNR ": frontmatter model is not inherit: " line
            }

            # Rules 2 and 3: family names and model-ID prefixes.
            lower = tolower(line)
            stripped = lower
            gsub(/\.claude-plugin/, "", stripped)
            if (lower ~ /(^|[^a-z])(opus|sonnet|haiku|fable)([^a-z]|$)/ ||
                stripped ~ /claude-[a-z0-9]/)
                print FILENAME ":" FNR ": " line
        }
    ' {} +)

    if [[ -n "$hits" ]]; then
        printf '%s\n' "$hits" >&2
        echo "" >&2
        echo "Model names found under skills/, agents/, commands/, or shared/." >&2
        echo "These files follow the session's model and effort: keep frontmatter" >&2
        echo "model: at inherit and describe behavior instead of naming a model" >&2
        echo "(CHANGELOG and docs/ are exempt)." >&2
        return 1
    fi

    echo "OK    no-model-names — plugin prompts name no Claude model; frontmatter model: is inherit"
    return 0
}

# --- Self-test mode ---------------------------------------------------------
#
# Mutation regression fixture. The exit-0 mutations prove the rules do not
# over-report (the `.claude-plugin` exclusion, frontmatter scoping of rule 1);
# the exit-1 mutations prove each rule fires on its own. Each rule-isolating
# mutation avoids tripping another rule: `model: fast-path` is not a family
# name, so only rule 1 can catch it (`model: opus` alone would also be caught
# by rule 2), and the same-line model ID carries no family name, so only rule
# 3 can catch it.
run_self_test() {
    # WORK is global (not local) so the EXIT trap can reference it safely
    # after this function returns. Under `set -u`, an EXIT trap that refers
    # to an unset local triggers an "unbound variable" error at fire time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    mkdir -p "$WORK/plugins/kenspc"
    local name
    for name in "${SCANNED_DIRS[@]}"; do
        cp -R "$REPO_ROOT/plugins/kenspc/$name" "$WORK/plugins/kenspc/$name"
    done

    local source_file="$REPO_ROOT/plugins/kenspc/agents/bug-reviewer.md"
    local target_file="$WORK/plugins/kenspc/agents/bug-reviewer.md"

    # Fixture-stale guard: the frontmatter mutations rewrite the target's
    # `model: inherit` line, so it must be present.
    if ! grep -qx 'model: inherit' "$target_file" 2>/dev/null; then
        echo "FAIL  self-test fixture stale: \"model: inherit\" not found in $target_file. Update the target file in run_self_test()." >&2
        return 2
    fi

    local rc

    # expect <expected-rc> <label>: run the main check on the workdir and
    # compare its exit code; then restore the target file from the source.
    expect() {
        ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
        cp "$source_file" "$target_file"
        if [[ "$rc" -ne "$1" ]]; then
            echo "FAIL  self-test $2 path: expected exit $1, got $rc" >&2
            return 1
        fi
    }

    # set_frontmatter_model <value>: rewrite the target's model: line.
    set_frontmatter_model() {
        awk -v v="$1" '$0 == "model: inherit" && !done { print "model: " v; done = 1; next } { print }' \
            "$source_file" > "$target_file"
    }

    expect 0 "positive" || return 1

    printf '%s\n' 'See .claude-plugin/plugin.json for the version.' >> "$target_file"
    expect 0 "exclusion" || return 1

    printf '%s\n' 'Pass model: fast-path to the helper.' >> "$target_file"
    expect 0 "body-prose model:" || return 1

    # Two casings: a capitalized name proves case-folding happens, a
    # lowercase one proves the pattern itself is not capitalized-only.
    printf '%s\n' 'Tuned for Opus at high effort.' >> "$target_file"
    expect 1 "capitalized family-name" || return 1

    printf '%s\n' 'Dispatch the reviewers with sonnet.' >> "$target_file"
    expect 1 "lowercase family-name" || return 1

    # The ID carries no family name, so only rule 3 can catch it.
    printf '%s\n' 'Pinned in .claude-plugin to claude-instant-1.2.' >> "$target_file"
    expect 1 "same-line model-ID" || return 1

    set_frontmatter_model opus
    expect 1 "frontmatter model: opus" || return 1

    set_frontmatter_model fast-path
    expect 1 "frontmatter model: fast-path" || return 1

    expect 0 "restoration" || return 1

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
