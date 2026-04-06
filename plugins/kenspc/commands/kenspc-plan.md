---
name: kenspc-plan
description: >
  Generate a comprehensive plan or task document (计划书/計劃書/计画书/任务分解) from
  requirements, backlog items, or specs. Adapts to project-specific templates.
  Includes discussion, self-challenge, and automated review.
  Trigger on: "write a plan", "task breakdown", "写计划书", "编写计划", "帮我规划"
argument-hint: <requirement or path-to-requirements-file> [custom instructions]
---

Invoke the **generate-plan** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/generate-plan/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
