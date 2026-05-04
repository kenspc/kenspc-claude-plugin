---
name: kenspc-brief
description: >
  Run a structured discovery conversation around a rough idea and produce a
  requirement brief (需求摘要). Use when the idea is too vague to plan
  directly, or when you need a shareable document before planning.
  Trigger on: "help me think through this", "brief this idea", "I have a
  rough idea", "我想理清楚思路", "先讨论一下", "写个需求摘要"
argument-hint: <rough idea or topic>
---

Invoke the **generate-brief** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
