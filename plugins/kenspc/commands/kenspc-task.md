---
name: kenspc-task
description: Explicit entry point for the generate-task skill — decompose a plan document into a fine-grained task document (任务分解).
argument-hint: <plan-document-path> [phase] [custom instructions]
disable-model-invocation: true
---

Invoke the **generate-task** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/generate-task/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
