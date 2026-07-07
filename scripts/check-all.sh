#!/usr/bin/env bash
# check-all.sh
#
# Wrapper that runs every guard script in scripts/ (check-*.sh, excluding
# itself) in main mode and reports PASS/FAIL per script. Single entry
# point for pre-commit and pre-flight runs, so adding a new guard script
# never requires updating command lists in CLAUDE.md or the release
# checklist — new check-*.sh files are picked up automatically.
#
# Does NOT run the guards' --self-test fixtures; those stay explicit in
# the release checklist (they are slower and only needed before tagging).
#
# Exit code 0: every guard passed.
# Exit code 1: at least one guard failed (its output is printed).
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation
# as the other guards.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

fail=0
for guard in scripts/check-*.sh; do
  [ "$(basename "$guard")" = "check-all.sh" ] && continue
  if output=$(bash "$guard" 2>&1); then
    echo "PASS $guard"
  else
    echo "FAIL $guard"
    printf '%s\n' "$output"
    fail=1
  fi
done

exit "$fail"
