#!/usr/bin/env bash
# Check that recommended dependencies are available.
# Runs as a SessionStart hook — stdout goes to the transcript.

set -euo pipefail

warnings=""

# Check ralph-loop plugin (required for all skills)
ralph_found=false
if [ -d "${HOME}/.claude/plugins/cache" ]; then
  for dir in "${HOME}/.claude/plugins/cache"/*/; do
    if [ -d "${dir}" ] && ls "${dir}" 2>/dev/null | grep -qi "ralph-loop" 2>/dev/null; then
      ralph_found=true
      break
    fi
  done
  # Also check nested plugin directories
  if [ "$ralph_found" = false ]; then
    if find "${HOME}/.claude/plugins/cache" -maxdepth 4 -name "plugin.json" -exec grep -l "ralph-loop" {} + 2>/dev/null | head -1 | grep -q .; then
      ralph_found=true
    fi
  fi
fi

if [ "$ralph_found" = false ]; then
  warnings="${warnings}[kenspc] ralph-loop plugin not detected. Skills that use automated review (generate-plan, task-loop, generate-guide) require it. Install ralph-loop first for full functionality.\n"
fi

# Check for stale state files from previous sessions
if [ -f ".claude/ralph-loop.local.md" ]; then
  warnings="${warnings}[kenspc] Stale state file detected: .claude/ralph-loop.local.md — this may be left over from a crashed session. Delete it if you are not mid-review.\n"
fi

for tmp_file in .claude/*-progress.tmp; do
  if [ -f "$tmp_file" ]; then
    warnings="${warnings}[kenspc] Stale progress file detected: ${tmp_file} — delete it if you are not mid-review.\n"
  fi
done

if [ -n "$warnings" ]; then
  printf "%b" "$warnings"
fi
