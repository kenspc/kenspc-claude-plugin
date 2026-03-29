# kenspc

A Claude Code plugin with opinionated development workflows — plan before you
code, structured task loops, iterative multi-angle review, and project guide
generation.

## Skills

| Skill | Command | Description |
|-------|---------|-------------|
| generate-plan | `/kenspc:generate-plan` | Three-phase plan document generation: collaborative discovery, ULTRATHINK-enhanced drafting with self-challenge, and automated ralph-loop verification across four review angles (feasibility, completeness, consistency, clarity). |
| task-loop | `/kenspc:task-loop` | Iterative task implementation with multi-angle code review using ralph-loop. Separates implementation and review into independent sessions to avoid confirmation bias. |
| generate-guide | `/kenspc:generate-guide` | Generates comprehensive project setup and deployment guides with ULTRATHINK-enhanced writing and multi-dimensional post-generation review. |

## Installation

### Local development
```bash
claude --plugin-dir /path/to/kenspc-claude-plugin
```

Use `/reload-plugins` to pick up changes without restarting.

### From marketplace
```bash
/plugin marketplace add kenspc/kenspc-claude-plugin
/plugin install kenspc@kenspc-claude-plugin
```

## Design Principles

- **Plan before code** — Structured discovery and planning before any implementation begins
- **Separation of concerns** — Implementation and review run as separate sessions
- **Multi-angle review** — Each review cycle examines work from multiple dimensions (feasibility, completeness, consistency, clarity)
- **Stack-agnostic** — Skills inspect project root files rather than assuming specific frameworks
- **ULTRATHINK at every stage** — Applied at both generation and review steps for thorough analysis
- **Bilingual output** — Progress messages and review summaries in English + Chinese; code and documents remain in their original language

## Requirements

- Claude Code v2.0.12+
- [ralph-loop](https://github.com/anthropics/claude-plugins-official) plugin (required by generate-plan and task-loop)

## License

MIT
