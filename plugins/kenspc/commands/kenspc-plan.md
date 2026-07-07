---
name: kenspc-plan
description: Explicit entry point for the generate-plan skill — generate a plan document (计划书) with discovery, self-challenge, and review.
argument-hint: <requirement or path-to-requirements-file> [custom instructions]
disable-model-invocation: true
---

Invoke the **generate-plan** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/generate-plan/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
