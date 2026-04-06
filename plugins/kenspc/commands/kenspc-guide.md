---
name: kenspc-guide
description: >
  Generate a beginner-friendly project setup and deployment guide (项目指南/部署文档/
  新人文档) with automated self-review. Trigger on: "write a guide", "setup doc",
  "写文档", "项目指南", "部署文档"
argument-hint: <project-path> [custom instructions]
---

Invoke the **generate-guide** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/generate-guide/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
