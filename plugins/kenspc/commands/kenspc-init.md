---
name: kenspc-init
description: Explicit entry point for the init-project skill — set a project up for the kenspc workflow (初始化项目) with AGENTS.md, CLAUDE.md, and topic documents.
argument-hint: "[project description]"
disable-model-invocation: true
---

Invoke the **init-project** skill with the provided arguments.

Read the skill definition at `${CLAUDE_PLUGIN_ROOT}/skills/init-project/SKILL.md` and follow
its instructions exactly. Pass `$ARGUMENTS` through as the skill's arguments.
