# kenspc

A Claude Code plugin with opinionated development workflows — plan before you
code, structured task implementation, iterative multi-angle review, and project guide
generation.

## Skills

Skills activate automatically when Claude Code detects a matching task context.

| Skill | Description |
|-------|-------------|
| generate-plan | Three-phase plan document generation: collaborative discovery, drafting with self-challenge, and automated verification via review agent across four review angles (feasibility, completeness, consistency, clarity). |
| generate-task | Decomposes a plan document into fine-grained executable tasks by reading actual code. Confirms decomposition with user, then self-reviews for completeness and execution order via review agent. |
| task-implement | Automated batch task implementation from a task document. Validates input is a task document (not a plan). Confirms scope with user before starting. Each task is built, tested, committed, and marked complete. Automatically runs task-review on completion with a consolidated final report. |
| task-review | Parallel multi-angle code review (5 review agents → fix agent → regression verification). Works with a task document for requirements context, or standalone to review recent changes. Accepts custom instructions to narrow scope. |
| generate-guide | Generates comprehensive, beginner-friendly project setup and deployment guides with automated multi-dimensional post-generation review via review agent. |

## Commands

Commands provide a direct way to invoke each skill.

| Command | Usage |
|---------|-------|
| `/kenspc-plan` | `/kenspc-plan <requirement or path> [custom instructions]` |
| `/kenspc-task` | `/kenspc-task <plan-document-path> [phase] [custom instructions]` |
| `/kenspc-task-implement` | `/kenspc-task-implement <path-to-task-file>` |
| `/kenspc-task-review` | `/kenspc-task-review [path-to-task-file] [custom instructions]` |
| `/kenspc-guide` | `/kenspc-guide <project-path> [custom instructions]` |

Skills can also be invoked via `/kenspc:generate-plan`, `/kenspc:generate-task`,
`/kenspc:task-implement`, `/kenspc:task-review`, and `/kenspc:generate-guide`.

## Installation

### From GitHub marketplace

Add this repository as a marketplace source, then install the plugin:

```bash
# Add the marketplace (one-time setup)
/plugin marketplace add kenspc/kenspc-claude-plugin

# Install the plugin (choose scope: user, project, or local)
/plugin install kenspc@kenspc-claude-plugin
```

### Local development

For plugin development or testing local changes:

```bash
claude --plugin-dir /path/to/kenspc-claude-plugin/plugins/kenspc
```

Use `/reload-plugins` to pick up changes without restarting.

### Managing the plugin

```bash
# Disable without uninstalling
/plugin disable kenspc@kenspc-claude-plugin

# Re-enable
/plugin enable kenspc@kenspc-claude-plugin

# Update to latest version
/plugin update kenspc@kenspc-claude-plugin

# Uninstall
/plugin uninstall kenspc@kenspc-claude-plugin
```

## Design Principles

- **Plan before code** — Structured discovery and planning before any implementation begins
- **Implement then review** — Implementation and review are distinct phases; task-implement auto-triggers task-review to catch issues immediately
- **Multi-angle review** — Each review cycle examines work from multiple dimensions (requirements, edge cases, code quality, bugs, test coverage)
- **Parallel review agents** — Task review dispatches independent review agents in parallel for speed, then consolidates fixes and verifies with regression
- **Explicit decomposition** — Task decomposition is a visible, reviewable step between planning and implementation, not hidden inside the implementation agent
- **Stack-agnostic** — Skills inspect project config files rather than assuming specific frameworks
- **Beginner-friendly guides** — Generated guides explain not just what to do, but why, with error recovery tips
- **Bilingual output** — Progress messages and review summaries in English + Chinese; code and documents remain in their original language

## Recommended Workflow

```
Backlog → /kenspc-plan → docs/plans/*.md → /kenspc-task → docs/tasks/*.md → /kenspc-task-implement → /kenspc-task-review
```

1. **Plan**: Use `/kenspc-plan` to create a strategic plan through collaborative discussion
2. **Decompose**: Use `/kenspc-task` to break the plan into fine-grained executable tasks
3. **Implement**: Use `/kenspc-task-implement` to auto-implement all tasks
4. **Review**: Runs automatically after implementation, or use `/kenspc-task-review` standalone

Small fixes can skip all skills and be implemented directly.

## Requirements

**Required:**
- Claude Code v1.0.33+

**Recommended:**
- [superpowers](https://github.com/anthropics/claude-plugins-official) plugin — provides ULTRATHINK deep-reasoning used throughout the skills

## Reference Documents

The `references/` directory contains example documents to help you get started:

- `task-document-example.md` — Shows the expected task document format for `task-implement`
- `plan-document-example.md` — Shows a typical plan output from `generate-plan`

## Acknowledgments

The anti-rationalization tables, red flags, and autonomy boundaries in this plugin
are inspired by [agent-skills](https://github.com/addyosmani/agent-skills) by
[Addy Osmani](https://github.com/addyosmani), licensed under MIT.

## License

MIT
