# kenspc

A Claude Code plugin with opinionated development workflows — plan before you
code, structured task loops, iterative multi-angle review, and project guide
generation.

## Skills

Skills activate automatically when Claude Code detects a matching task context.

| Skill | Description |
|-------|-------------|
| generate-plan | Three-phase plan document generation: collaborative discovery, drafting with self-challenge, and automated ralph-loop verification across four review angles (feasibility, completeness, consistency, clarity). |
| task-loop | Iterative task implementation with multi-angle code review using ralph-loop. Separates implementation and review into independent sessions to avoid confirmation bias. |
| generate-guide | Generates comprehensive, beginner-friendly project setup and deployment guides with automated multi-dimensional post-generation review. |

## Commands

Commands provide a direct way to invoke each skill.

| Command | Usage |
|---------|-------|
| `/kenspc-plan` | `/kenspc-plan <requirement or path> [custom instructions]` |
| `/kenspc-task` | `/kenspc-task <implement\|review> <path-to-task-file>` |
| `/kenspc-guide` | `/kenspc-guide <project-path> [custom instructions]` |

Skills can also be invoked via `/kenspc:generate-plan`, `/kenspc:task-loop`, and
`/kenspc:generate-guide`.

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
- **Separation of concerns** — Implementation and review run as separate sessions
- **Multi-angle review** — Each review cycle examines work from multiple dimensions (feasibility, completeness, consistency, clarity)
- **Stack-agnostic** — Skills inspect project config files rather than assuming specific frameworks
- **Beginner-friendly guides** — Generated guides explain not just what to do, but why, with error recovery tips
- **Bilingual output** — Progress messages and review summaries in English + Chinese; code and documents remain in their original language

## Requirements

**Required:**
- Claude Code v1.0.33+
- [ralph-loop](https://github.com/anthropics/claude-plugins-official) plugin — powers the automated review loops in all three skills

**Recommended:**
- [superpowers](https://github.com/anthropics/claude-plugins-official) plugin — provides ULTRATHINK deep-reasoning used throughout the skills

## Reference Documents

The `references/` directory contains example documents to help you get started:

- `task-document-example.md` — Shows the expected task document format for `task-loop`
- `plan-document-example.md` — Shows a typical plan output from `generate-plan`

## License

MIT
