#!/usr/bin/env bash
# SessionEnd telemetry hook for kenspc plugin.
#
# Purpose: post-hoc telemetry only. Records when a session invoked
# `/kenspc-task-implement` but no review evidence exists — neither a
# `/kenspc-task-review` invocation nor the in-skill Phase 2 dispatch of
# the review-angle agents (the normal path: task-implement runs review
# internally, so agent dispatch, not a slash command, is the usual
# evidence). Output is a single JSON Lines record appended
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
#     If unset, telemetry degrades to coarse-grained mode: the transcript
#     cannot be located so the hook silently exits without writing a
#     record. When a record IS written, the session_id field is omitted
#     from the JSON Lines payload rather than carrying the literal
#     string "unknown" (avoids consumer-side confusion between unset
#     and a real UUID).

set -euo pipefail

LOG_DIR="${HOME}/.claude/kenspc"
LOG_FILE="${LOG_DIR}/missed-reviews.log"
PROJECTS_DIR="${HOME}/.claude/projects"

# Best-effort session ID. Empty / unset is tolerated.
session_id="${CLAUDE_CODE_SESSION_ID:-}"

# Locate this session's transcript jsonl. If we cannot find one, we
# cannot decide whether review was skipped — silently exit.
transcript=""
if [[ -d "$PROJECTS_DIR" && -n "$session_id" ]]; then
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
# /kenspc-task-review was invoked. The transcript is JSON Lines; each
# line is a record. A user-typed slash command is encoded as a "user"
# record whose content value starts with a <command-message> tag
# (verified 2026-07-08 against live transcripts):
#   "content":"<command-message>kenspc:kenspc-task-implement</command-message>\n<command-name>/kenspc:kenspc-task-implement</command-name>"
# The plugin namespace prefix (`kenspc:`) is present when the command
# is invoked through the installed plugin; the pattern tolerates its
# absence for bare invocations. Anchoring on the unescaped
# `"content":"<command-message>` prefix keeps file contents quoted in
# assistant messages (which the transcript stores with escaped quotes)
# from matching.
# Review evidence is either form: an explicit /kenspc-task-review
# invocation, or the Agent-tool dispatch of the review-angle agents
# (requirements-reviewer is always part of the 5-agent dispatch, so one
# agent suffices as the marker). Without the second form, every healthy
# task-implement run — whose Phase 2 reviews via agent dispatch, not a
# slash command — would be logged as a missed review.
implement_seen=0
review_seen=0
implement_pattern='"content":"<command-message>(kenspc:)?kenspc-task-implement'
review_pattern='"content":"<command-message>(kenspc:)?kenspc-task-review'
review_dispatch_pattern='"subagent_type":"(kenspc:)?requirements-reviewer"'
if grep -q -E -- "$implement_pattern" "$transcript" 2>/dev/null; then
    implement_seen=1
fi
if grep -q -E -- "$review_pattern" "$transcript" 2>/dev/null \
    || grep -q -E -- "$review_dispatch_pattern" "$transcript" 2>/dev/null; then
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

# Build the JSON Lines record. Omit session_id when unset rather than
# writing the literal "unknown" — consumer side can then cleanly
# distinguish "no session id available" from a real UUID.
if [[ -n "$session_id" ]]; then
    printf '{"timestamp": "%s", "session_id": "%s", "reason": "task-implement without task-review"}\n' \
        "$timestamp" "$session_id" >> "$LOG_FILE" 2>/dev/null || true
else
    printf '{"timestamp": "%s", "reason": "task-implement without task-review"}\n' \
        "$timestamp" >> "$LOG_FILE" 2>/dev/null || true
fi

exit 0
