# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin marketplace containing structured development workflow plugins. The primary plugin (`kenspc`) provides skills for plan-before-code workflows, iterative task implementation with multi-angle review, and project guide generation.

## Marketplace Structure

- Root `.claude-plugin/marketplace.json` — plugin registry pointing to plugin directories
- Each plugin lives in `plugins/<name>/` with its own `.claude-plugin/plugin.json`, `README.md`, `LICENSE`, and component directories (`skills/`, `commands/`, `hooks/`, `references/`)

### Plugin Directory Layout

```
plugins/kenspc/
├── .claude-plugin/plugin.json   # Plugin metadata (name, version, author)
├── commands/                    # Slash commands (/kenspc-plan, etc.)
├── hooks/
│   ├── hooks.json               # Hook event configuration
│   └── scripts/                 # Hook scripts (use ${CLAUDE_PLUGIN_ROOT})
├── references/                  # Example documents for user onboarding
├── skills/
│   └── <skill-name>/
│       ├── SKILL.md             # Skill definition
│       └── prompts/             # Prompt templates
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

### Ralph-loop Integration (when applicable)

Not all skills use ralph-loop — it is optional. When a skill does integrate with ralph-loop:
- State file: `.claude/ralph-loop.local.md` with YAML frontmatter (`active`, `iteration`, `max_iterations`, `completion_promise`)
- Progress tracking: `.claude/<skill-name>-progress.tmp` (e.g., `plan-review-progress.tmp`, `task-review-progress.tmp`, `guide-review-progress.tmp`)
- Completion promises use `SCREAMING_SNAKE_CASE` (e.g., `PLAN_REVIEW_COMPLETE`)
- **State files (`.claude/ralph-loop.local.md`, `.claude/*.tmp`) must be deleted after use** — never leave stale state files behind after a skill finishes or errors out

### Writing Rules for Skill Content

- Bilingual output: progress messages and summaries in English + Chinese (华语); code stays in its original language
- Use ULTRATHINK before major analysis or generation steps
- Multi-angle review: 4–6 review angles per review cycle
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
