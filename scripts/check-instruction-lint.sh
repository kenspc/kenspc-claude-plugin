#!/usr/bin/env bash
# check-instruction-lint.sh
#
# Runs .claude/tests/instruction-lint.ps1 on AGENTS.md, so check-all.sh holds
# the instruction file to its budget, free of all-caps emphasis, and naming
# only repo paths that exist. The lint is a copy of the one in the
# kenspc-dev-setup repository (.claude/tests/instruction-lint.ps1 there),
# kept unchanged so a newer copy can replace it as a whole; its own header
# says what it checks. The budget numbers live in AGENTS.md's
# `<!-- budget: lines=N words=N -->` line, not here.
#
# The lint is PowerShell 7 while every other guard is bash, so this wrapper
# finds pwsh first. On macOS pwsh is a .NET global tool that cannot start
# without DOTNET_ROOT, so ~/.dotnet is exported when the variable is unset
# and that directory exists. A pwsh that cannot be found is exit 2, never a
# pass: a lint that silently did not run would read as one.
#
# Exit code 0: AGENTS.md passes (the lint's warnings are allowed).
# Exit code 1: a lint check failed (the lint's output is printed).
# Exit code 2: pwsh or the lint is missing, the lint could not check the
#              file (its exit 3: the file or its budget line is missing), or
#              the self-test fixture is stale.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards.
#
# Optional flag:
#   --self-test    Runs the lint's own -SelfTest, then runs this wrapper's
#                  lint step on two of the lint's fixtures: good.md must
#                  return 0 and over-lines.md 1, so a wrapper that dropped
#                  the lint's exit code turns red. Exit 0 on self-test pass,
#                  1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LINT="$REPO_ROOT/.claude/tests/instruction-lint.ps1"
FIXTURES="$REPO_ROOT/.claude/tests/instruction-lint"
TARGET="AGENTS.md"

if [[ -z "${DOTNET_ROOT:-}" && -d "$HOME/.dotnet" ]]; then
    export DOTNET_ROOT="$HOME/.dotnet"
fi

# Return 0 when pwsh and the lint are both present, else print why and 2.
require_lint() {
    if ! command -v pwsh >/dev/null 2>&1; then
        echo "ERROR: pwsh not found, so the instruction lint cannot run" >&2
        return 2
    fi
    if [[ ! -f "$LINT" ]]; then
        echo "ERROR: missing file $LINT" >&2
        return 2
    fi
}

# Lint one file; map the lint's exit codes to this guard's (3 becomes 2).
run_lint() {
    local file="$1" output rc
    output=$(pwsh -NoProfile -File "$LINT" -Path "$file" 2>&1) && rc=0 || rc=$?
    case "$rc" in
        0)
            printf '%s\n' "$output" | grep -E '^[[:space:]]+(PASS|WARN)' | sed 's/^ */OK    /' || true
            return 0
            ;;
        1)
            printf '%s\n' "$output" >&2
            return 1
            ;;
        *)
            printf '%s\n' "$output" >&2
            return 2
            ;;
    esac
}

run_main_logic() {
    require_lint || return $?
    run_lint "$TARGET"
}

# --- Self-test mode ---------------------------------------------------------

run_self_test() {
    require_lint || return $?
    local rc fixture expected
    pwsh -NoProfile -File "$LINT" -SelfTest >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test: the lint's own -SelfTest exited $rc" >&2
        return 1
    fi
    for fixture in good.md:0 over-lines.md:1; do
        expected="${fixture##*:}"
        fixture="$FIXTURES/${fixture%%:*}"
        if [[ ! -f "$fixture" ]]; then
            echo "FAIL  self-test fixture stale: missing $fixture" >&2
            return 2
        fi
        ( run_lint "$fixture" ) >/dev/null 2>&1 && rc=0 || rc=$?
        if [[ "$rc" -ne "$expected" ]]; then
            echo "FAIL  self-test: $(basename "$fixture") returned $rc, expected $expected" >&2
            return 1
        fi
    done
    echo "OK    self-test passed for $(basename "$0")"
    return 0
}

# --- Dispatch ---------------------------------------------------------------

if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit $?
fi

run_main_logic
exit $?
