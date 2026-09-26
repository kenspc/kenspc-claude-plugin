---
name: kenspc-autopilot
description: Explicit entry point for the autopilot skill — run one batch unattended (无值守跑完一批) from a spec or a brief to a local release preparation.
argument-hint: <path to a spec or a brief>
disable-model-invocation: true
---

Invoke the **autopilot** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
