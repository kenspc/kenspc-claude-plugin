#!/usr/bin/env bash
# PreToolUse hook for Write tool.
# Soft reminder to use generate-plan skill when creating plan/task documents.
# Exit 0 + message = allow the write but show reminder to Claude.

set -euo pipefail

# Read tool input from stdin
input=$(cat)

# Extract file_path from JSON (simple pattern match, no jq dependency)
file_path=$(echo "$input" | grep -oP '"file_path"\s*:\s*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"//')

# Skip if we couldn't extract a path
[ -z "$file_path" ] && exit 0

# Check if path matches plan/task document directories
case "$file_path" in
  */docs/tasks/*.md|*/docs/plans/*.md)
    # Exclude template files and non-plan files
    case "$file_path" in
      *_template*|*template_*|*README*) exit 0 ;;
    esac
    cat <<'MSG'
NOTE: You are writing a plan/task document directly. These should normally be
generated using the generate-plan skill (invoke via Skill tool or /kenspc-plan)
which includes collaborative discussion, self-challenge, and automated review.
If you have already invoked the skill, ignore this message.
MSG
    exit 0
    ;;
esac

exit 0
