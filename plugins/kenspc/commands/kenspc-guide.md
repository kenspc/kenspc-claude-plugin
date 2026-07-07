---
name: kenspc-guide
description: Explicit entry point for the generate-guide skill — generate a project setup and deployment guide (项目指南) with self-review.
argument-hint: <project-path> [custom instructions]
disable-model-invocation: true
---

Invoke the **generate-guide** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/generate-guide/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
