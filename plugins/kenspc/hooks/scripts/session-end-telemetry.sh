#!/usr/bin/env bash
# SessionEnd telemetry hook for kenspc plugin.
#
# Purpose: post-hoc telemetry only. Records when a session invoked
# `/kenspc-task-implement` but did not subsequently invoke
# `/kenspc-task-review`. Output is a single JSON Lines record appended
# to ${HOME}/.claude/kenspc/missed-reviews.log.
#
# Design boundary (per project CLAUDE.md "Plugin Design Lessons"):
# hooks are for post-hoc telemetry, not workflow state-machine
# guarding. This script never blocks session exit, never prints to
# stdout / stderr, and tolerates every error path silently.
#
# Detection mechanism (v3.0.3 pre-implementation env probe outcome):
#   - Question 1 — slash-command history source: scanning
#     ${HOME}/.claude/projects/<encoded-project>/<session>.jsonl
#     (probe option (c); option (a) had no transcript-path env
#     variable available in Windows Git Bash).
#   - Question 2 — session ID source: ${CLAUDE_CODE_SESSION_ID}
#     environment variable (stable UUID observed during probe).
#     If unset, telemetry degrades to coarse-grained mode and the
#     session_id field is recorded as "unknown".

set -euo pipefail

LOG_DIR="${HOME}/.claude/kenspc"
LOG_FILE="${LOG_DIR}/missed-reviews.log"
PROJECTS_DIR="${HOME}/.claude/projects"

# Best-effort session ID. Empty / unset is fine — recorded as "unknown".
session_id="${CLAUDE_CODE_SESSION_ID:-unknown}"

# Locate this session's transcript jsonl. If we cannot find one, we
# cannot decide whether review was skipped — silently exit.
transcript=""
if [[ -d "$PROJECTS_DIR" && "$session_id" != "unknown" ]]; then
    # Scan all project subdirectories for a file matching the session ID.
    # The path encoding scheme (project dir name) is opaque from a hook's
    # perspective, so we glob rather than reconstruct it.
    found=$(find "$PROJECTS_DIR" -maxdepth 2 -type f -name "${session_id}.jsonl" 2>/dev/null | head -1 || true)
    if [[ -n "$found" && -r "$found" ]]; then
        transcript="$found"
    fi
fi

if [[ -z "$transcript" ]]; then
    exit 0
fi

# Detect whether /kenspc-task-implement was invoked and whether
# /kenspc-task-review was invoked. The transcript records command
# invocations as text in user / assistant entries; a literal substring
# match is sufficient for telemetry purposes.
implement_seen=0
review_seen=0
if grep -q -F -- "/kenspc-task-implement" "$transcript" 2>/dev/null; then
    implement_seen=1
fi
if grep -q -F -- "/kenspc-task-review" "$transcript" 2>/dev/null; then
    review_seen=1
fi

if [[ "$implement_seen" -ne 1 || "$review_seen" -eq 1 ]]; then
    # Either implement was never invoked, or review followed it. Nothing
    # to record.
    exit 0
fi

# Append a JSON Lines record. Use ISO-8601 with timezone offset.
timestamp=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null || echo "unknown")
# Normalize "+0800" -> "+08:00" for readability (best-effort; not load-bearing).
case "$timestamp" in
    *[+-]????) timestamp="${timestamp:0:${#timestamp}-2}:${timestamp: -2}" ;;
esac

mkdir -p "$LOG_DIR" 2>/dev/null || exit 0

printf '{"timestamp": "%s", "session_id": "%s", "reason": "task-implement without task-review"}\n' \
    "$timestamp" "$session_id" >> "$LOG_FILE" 2>/dev/null || true

exit 0
