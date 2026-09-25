---
name: kenspc-prototype
description: Explicit entry point for the prototype skill — answer one open question from a brief with a throwaway prototype (原型).
argument-hint: <brief path> [entry number or question]
disable-model-invocation: true
---

Invoke the **prototype** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/prototype/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
