# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin marketplace containing structured development workflow plugins. The primary plugin (`kenspc`) provides skills for plan-before-code workflows, requirement brief generation, plan-to-task decomposition, task implementation with automatic code review, and project guide generation. Review phases use subagent architecture — serial review agents for plan/guide/task documents, parallel MapReduce review agents for code. The brief skill has no review phase (it produces a discovery artifact, not a verifiable spec).

## Marketplace Structure

- Root `.claude-plugin/marketplace.json` — plugin registry pointing to plugin directories
- Each plugin lives in `plugins/<name>/` with its own `.claude-plugin/plugin.json`, `README.md`, `LICENSE`, and component directories (`skills/`, `commands/`, `hooks/`, `references/`, `shared/`)

### Plugin Directory Layout

```
plugins/kenspc/
├── .claude-plugin/plugin.json   # Plugin metadata (name, version, author)
├── commands/                    # Slash commands
│   ├── kenspc-brief.md
│   ├── kenspc-plan.md
│   ├── kenspc-task.md
│   ├── kenspc-guide.md
│   ├── kenspc-task-implement.md
│   └── kenspc-task-review.md
├── hooks/
│   ├── hooks.json               # Hook event configuration
│   └── scripts/                 # Hook scripts (use ${CLAUDE_PLUGIN_ROOT})
├── references/                  # Example documents for user onboarding
├── shared/                      # Cross-skill resources (referenced via ${CLAUDE_PLUGIN_ROOT}/shared/)
│   └── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan
├── skills/
│   ├── generate-brief/
│   │   └── SKILL.md             # No review phase — brief is a discovery artifact
│   ├── generate-plan/
│   │   ├── SKILL.md
│   │   └── prompts/review.md
│   ├── generate-task/
│   │   ├── SKILL.md
│   │   └── prompts/review.md
│   ├── generate-guide/
│   │   ├── SKILL.md
│   │   └── prompts/review.md
│   ├── task-implement/
│   │   ├── SKILL.md
│   │   └── prompts/implement.md
│   └── task-review/
│       ├── SKILL.md
│       └── prompts/
│           ├── review-angle-{1..5}.md   # 5 parallel review agent prompts
│           ├── fix.md                   # Fix agent prompt
│           └── regression.md            # Regression verification prompt
├── README.md
└── LICENSE
```

## Skill Development Conventions

### File Structure

Each skill lives in `skills/<skill-name>/` with:
- `SKILL.md` — skill definition with YAML frontmatter (`name`, `description`, `version`, `argument-hint`) followed by structured phases/modes
- `prompts/` — prompt templates (optional)

Commands live in `commands/` as `.md` files with YAML frontmatter (`name`, `description`, `argument-hint`).

Hooks are defined in `hooks/hooks.json` with scripts in `hooks/scripts/`.

References live in `references/` as example documents (task format, plan format) to help users get started.

Shared resources live in `shared/` as cross-skill files (prompt frameworks, templates) referenced via `${CLAUDE_PLUGIN_ROOT}/shared/<file>.md`. The current entry is `discovery-framework.md`, loaded by both `generate-plan` Phase 1 and `generate-brief` Phase 1 to provide a single source of truth for the discovery conversation pattern (five dimensions, four input clarity levels, exit conditions).

### Portable Paths

All file references in hooks and commands must use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths.

### SKILL.md Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (kebab-case) |
| `description` | Yes | When to activate (1-2 sentences, concise) |
| `version` | Yes | Semver (e.g., `1.0.0`) |
| `argument-hint` | Recommended | Shown in UI as placeholder (e.g., `<project-path>`) |

### Prompt Templates

- Use `{{VARIABLE_NAME}}` placeholders (SCREAMING_SNAKE_CASE)
- Store in the skill's `prompts/` subdirectory

### Subagent Review Architecture

Skills use subagents (the Agent tool) for automated review. Two models exist:

**No review (generate-brief):**
- Brief is a discovery artifact, not a verifiable spec — review happens downstream when `generate-plan` consumes the brief
- Phase 1 detection in `generate-plan` recognises briefs and gap-checks against the same five dimensions

**Serial review (generate-plan, generate-task, generate-guide):**
- Single subagent reviews all angles in order (each angle builds on fixes from the previous one)
- Suited for document review where angles have cascade dependencies
- Subagent returns a structured change log (what changed, why)

**Parallel MapReduce review (task-review):**
- Phase 1: 5 read-only review subagents dispatched in parallel (one per angle)
- Phase 2: Fix subagent receives all 5 reports, deduplicates, applies fixes, produces accountability list
- Phase 3: Regression subagent cross-checks reports against accountability list, verifies fixes, runs build/test/lint
- Suited for code review where angles are orthogonal (edge cases, bugs, test coverage, etc.)

No shared state files — each subagent runs in its own context, eliminating concurrency conflicts.

### Writing Rules for Skill Content

- Bilingual output: progress messages and summaries in English + Chinese (华语); code stays in its original language
- Use ULTRATHINK before major analysis or generation steps
- Review summaries must list every change with the reason (what changed and why)
- Stack-agnostic: read project config files to detect tech stack, never assume a specific framework

## Git

Conventional commits: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`

## Development Workflow

### Test the plugin locally
```bash
claude --plugin-dir ./plugins/kenspc
```

Use `/reload-plugins` inside a session to pick up changes without restarting.

### Validate plugin structure
```bash
# Check plugin.json is valid
cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool

# Check hooks.json is valid
cat plugins/kenspc/hooks/hooks.json | python -m json.tool

# Verify all SKILL.md files have required frontmatter
grep -l "^name:" plugins/kenspc/skills/*/SKILL.md
```
