---
name: kenspc-task-review
description: >
  Thorough code review (代码审查/review代码) using 5 parallel review agents, fix
  agent, and regression verification. Use for ANY code review request. Works
  standalone or with a task document for requirements context
argument-hint: [path-to-task-file] [custom instructions]
---

Invoke the **task-review** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
