#!/usr/bin/env bash
# check-all.sh
#
# Wrapper that runs every guard script in scripts/ (check-*.sh, excluding
# itself) in main mode, reports PASS/FAIL per script, and ends the pass
# with a `guards run: N` line. Single entry point for pre-commit and
# pre-flight runs, so adding a new guard script never requires updating
# command lists in CLAUDE.md — new check-*.sh files are picked up
# automatically. The release checklist pins the expected N, so a guard
# that disappears or stops matching the glob changes a visible number.
#
# Optional flag:
#   --self-test    After the main-mode pass, also run the --self-test
#                  mutation fixture of every guard that implements one (a
#                  guard implements it when its dispatch matches the literal
#                  "--self-test" argument), then print how many ran. Guards
#                  without a fixture are listed as skipped rather than passed,
#                  so a fixture that disappears shows up as a changed count.
#                  The release checklist runs this form before tagging.
#
# Exit code 0: every guard passed (and, with --self-test, every fixture).
# Exit code 1: at least one guard or fixture failed (its output is printed).
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation
# as the other guards.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

run_self_tests=0
if [[ "${1:-}" == "--self-test" ]]; then
    run_self_tests=1
fi

fail=0
guards=0
for guard in scripts/check-*.sh; do
  [ "$(basename "$guard")" = "check-all.sh" ] && continue
  guards=$((guards + 1))
  if output=$(bash "$guard" 2>&1); then
    echo "PASS $guard"
  else
    echo "FAIL $guard"
    printf '%s\n' "$output"
    fail=1
  fi
done
echo "guards run: $guards"

if [[ "$run_self_tests" -eq 1 ]]; then
  ran=0
  for guard in scripts/check-*.sh; do
    [ "$(basename "$guard")" = "check-all.sh" ] && continue
    if ! grep -qE '"--self-test"|--self-test\)' "$guard"; then
      echo "SKIP self-test $guard (no fixture)"
      continue
    fi
    ran=$((ran + 1))
    if output=$(bash "$guard" --self-test 2>&1); then
      echo "PASS self-test $guard"
    else
      echo "FAIL self-test $guard"
      printf '%s\n' "$output"
      fail=1
    fi
  done
  echo "self-tests run: $ran"
fi

exit "$fail"
