#!/usr/bin/env bash
# check-json.sh
#
# Guards that the three JSON files the plugin loader reads all parse:
#
#   1. plugins/kenspc/.claude-plugin/plugin.json   (plugin metadata)
#   2. plugins/kenspc/hooks/hooks.json             (hook configuration)
#   3. .claude-plugin/marketplace.json             (marketplace registry)
#
# A JSON syntax error in any of them breaks plugin load, and grep-based
# guards cannot see it. The release checklist used to run
# `python -m json.tool` by hand, which fails on machines that only have
# `python3` (macOS) and on machines that only have `py` (Windows); this
# guard picks a working interpreter itself, so check-all.sh covers JSON on
# every platform.
#
# Interpreter order: python3, python, py (the Windows launcher), then node.
# Each candidate is run once (`-c 'import json'`, or `node -e ''`) rather
# than only looked up on PATH: Windows ships a `python3` Microsoft Store
# alias that exists on PATH but exits non-zero when Python is not installed.
#
# Exit code 0: all three files parse.
# Exit code 1: at least one file fails to parse (each failure is printed).
# Exit code 2: a file is missing, no interpreter was found, or the self-test
#              fixture is stale.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards. Paths are passed relative to the repo root, so a native
# Windows interpreter never sees an MSYS-style /c/... path.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the three
#                  files into a temp workdir, runs the main check (must exit
#                  0), appends a stray `}` to marketplace.json (must exit 1),
#                  then restores it (must exit 0). Exit 0 on self-test pass,
#                  1 on unexpected exit codes, 2 on fixture-stale.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

JSON_FILES=(
    "plugins/kenspc/.claude-plugin/plugin.json"
    "plugins/kenspc/hooks/hooks.json"
    ".claude-plugin/marketplace.json"
)

# Print the first interpreter that actually runs; return 1 if none does.
resolve_interpreter() {
    local cand
    for cand in python3 python py; do
        if command -v "$cand" >/dev/null 2>&1 && "$cand" -c 'import json' >/dev/null 2>&1; then
            echo "$cand"
            return 0
        fi
    done
    if command -v node >/dev/null 2>&1 && node -e '' >/dev/null 2>&1; then
        echo "node"
        return 0
    fi
    return 1
}

# Parse one file with the given interpreter; non-zero exit on invalid JSON.
parse_json() {
    local interp="$1" file="$2"
    if [[ "$interp" == "node" ]]; then
        node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$file"
    else
        "$interp" -m json.tool "$file" >/dev/null
    fi
}

# Run the check against a given repo root. Returns 0/1/2 via `return`.
run_main_logic() {
    local repo_root="$1" interp f bad=0 output

    if ! interp=$(resolve_interpreter); then
        echo "ERROR: no JSON-capable interpreter found (tried python3, python, py, node)" >&2
        return 2
    fi

    for f in "${JSON_FILES[@]}"; do
        if [[ ! -f "$repo_root/$f" ]]; then
            echo "ERROR: missing file $repo_root/$f" >&2
            return 2
        fi
        if ! output=$(cd "$repo_root" && parse_json "$interp" "$f" 2>&1); then
            echo "INVALID $f ($interp):" >&2
            printf '%s\n' "$output" >&2
            bad=1
        fi
    done

    if [[ "$bad" -ne 0 ]]; then
        return 1
    fi
    echo "OK    json — ${#JSON_FILES[@]} files parse (interpreter: $interp)"
    return 0
}

# --- Self-test mode ---------------------------------------------------------

run_self_test() {
    # WORK is global (not local) so the EXIT trap can reference it safely
    # after this function returns. Under `set -u`, an EXIT trap that refers
    # to an unset local triggers an "unbound variable" error at fire time.
    WORK=$(mktemp -d)
    trap 'rm -rf "${WORK:-}"' EXIT

    local f rc
    for f in "${JSON_FILES[@]}"; do
        mkdir -p "$WORK/$(dirname "$f")"
        cp "$REPO_ROOT/$f" "$WORK/$f"
    done
    local target="$WORK/.claude-plugin/marketplace.json"

    # Positive path: the unmodified copies must parse.
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test positive path: expected exit 0 on unmutated copy, got $rc" >&2
        return 1
    fi

    # Mutation: a stray closing brace after the top-level object is invalid
    # JSON for every interpreter in the list.
    printf '}\n' >> "$target"
    if cmp -s "$REPO_ROOT/.claude-plugin/marketplace.json" "$target"; then
        echo "FAIL  self-test fixture stale: mutation did not change $target" >&2
        return 2
    fi
    ( run_main_logic "$WORK" ) >/dev/null 2>&1 && rc=0 || rc=$?
    if [[ "$rc" -ne 1 ]]; then
        echo "FAIL  self-test negative path: expected exit 1 on mutated copy, got $rc" >&2
        return 1
    fi

    # Restoration path.
    cp "$REPO_ROOT/.claude-plugin/marketplace.json" "$target"
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
