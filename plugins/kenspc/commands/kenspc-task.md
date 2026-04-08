---
name: kenspc-task
description: >
  Generate fine-grained task document (任务文档/任务分解) from a plan document.
  Reads actual code to determine correct decomposition and order.
  Trigger on: "generate tasks", "break down tasks", "拆任务", "生成任务",
  "任务分解"
argument-hint: <plan-document-path> [phase] [custom instructions]
---

Invoke the **generate-task** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/generate-task/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
