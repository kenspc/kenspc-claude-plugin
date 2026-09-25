---
name: kenspc-diagnose
description: Explicit entry point for the diagnose-bug skill — reproduce and diagnose an observed bug (修 bug) into a task document or a brief.
argument-hint: <observed bug, or path to a bug report>
disable-model-invocation: true
---

Invoke the **diagnose-bug** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/diagnose-bug/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
