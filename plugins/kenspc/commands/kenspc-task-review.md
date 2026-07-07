---
name: kenspc-task-review
description: Explicit entry point for the task-review skill — multi-angle code review (代码审查) with fix and regression verification.
argument-hint: "[path-to-task-file] [custom instructions]"
disable-model-invocation: true
---

Invoke the **task-review** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
