#!/usr/bin/env bash
# kenspc-task-loop setup script
# Reads prompt template, replaces {{TASK_FILE}}, writes to .claude/task-loop-prompt.tmp,
# then invokes ralph-loop with the rendered prompt.

set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MODE=""
TASK_FILE=""

# Parse arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: kenspc-task-loop <implement|review> <path-to-task-file>" >&2
    echo "Example: /kenspc-task-loop implement docs/tasks/user-auth.md" >&2
    exit 1
fi

MODE="$1"
TASK_FILE="$2"

# Validate mode
if [[ "$MODE" != "implement" && "$MODE" != "review" ]]; then
    echo "Error: Mode must be 'implement' or 'review', got '$MODE'" >&2
    exit 1
fi

# Validate task file exists
if [[ ! -f "$TASK_FILE" ]]; then
    echo "Error: Task file not found: $TASK_FILE" >&2
    exit 1
fi

# Select template and settings based on mode
if [[ "$MODE" == "implement" ]]; then
    TEMPLATE="$SKILL_DIR/prompts/implement.md"
    MAX_ITERATIONS=15
    COMPLETION_PROMISE="IMPL_COMPLETE"
else
    TEMPLATE="$SKILL_DIR/prompts/review.md"
    MAX_ITERATIONS=10
    COMPLETION_PROMISE="REVIEW_COMPLETE"
fi

# Validate template exists
if [[ ! -f "$TEMPLATE" ]]; then
    echo "Error: Prompt template not found: $TEMPLATE" >&2
    exit 1
fi

# Render prompt: replace {{TASK_FILE}} placeholder with actual path
PROMPT=$(sed "s|{{TASK_FILE}}|$TASK_FILE|g" "$TEMPLATE")

# Write rendered prompt to temporary file
mkdir -p .claude
echo "$PROMPT" > .claude/task-loop-prompt.tmp

echo "✅ Mode: $MODE"
echo "📄 Task file: $TASK_FILE"
echo "🔄 Max iterations: $MAX_ITERATIONS"
echo "🎯 Completion promise: $COMPLETION_PROMISE"
echo ""
echo "Prompt written to .claude/task-loop-prompt.tmp"
echo ""
echo "Now run ralph-loop with the rendered prompt. Copy and paste:"
echo ""
echo "/ralph-loop:ralph-loop \"\$(cat .claude/task-loop-prompt.tmp)\" --max-iterations $MAX_ITERATIONS --completion-promise \"$COMPLETION_PROMISE\""
