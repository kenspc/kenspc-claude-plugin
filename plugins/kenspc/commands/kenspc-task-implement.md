---
name: kenspc-task-implement
description: >
  Automated batch implementation (自动实现任务): auto-implements ALL incomplete tasks
  from a task document, then runs automated code review. Only use when explicitly
  requested for batch/unattended implementation
argument-hint: <path-to-task-file>
---

Invoke the **task-implement** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/task-implement/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
