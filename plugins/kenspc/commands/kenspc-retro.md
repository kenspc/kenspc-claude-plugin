---
name: kenspc-retro
description: Explicit entry point for the retro skill — look back over a window of finished batches (回顾一批批次), rank the problems that recurred, and propose verified changes.
argument-hint: "[last <n> | since <date> | all] [Workspace: <dir>]"
disable-model-invocation: true
---

Invoke the **retro** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/retro/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
