# kenspc-claude-plugin

A Claude Code plugin marketplace with structured software development workflow plugins.

## Installation

```bash
# Add the marketplace (one-time setup)
/plugin marketplace add kenspc/kenspc-claude-plugin

# Install a plugin (choose scope: user, project, or local)
/plugin install kenspc@kenspc-claude-plugin
```

## Available Plugins

### [kenspc](./plugins/kenspc/)

Opinionated software development workflows — discovery brief, plan before you code, structured task implementation, iterative multi-angle code review, and project guide generation.

**Skills:**

| Skill | What it does |
|-------|-------------|
| generate-brief | Structured discovery conversation (five dimensions) producing a shareable requirement brief — no review phase |
| generate-plan | Collaborative discovery (shared framework, brief-aware) + drafting + automated 4-angle review |
| generate-task | Plan-to-task decomposition via code analysis + 2-angle review |
| task-implement | Automated batch implementation with input validation and auto-review |
| task-review | Parallel 5-agent code review (MapReduce) with fix consolidation and regression verification |
| generate-guide | Beginner-friendly project guide generation with multi-dimensional review |

**Commands:** `/kenspc-brief`, `/kenspc-plan`, `/kenspc-task`, `/kenspc-task-implement`, `/kenspc-task-review`, `/kenspc-guide`

See the [plugin README](./plugins/kenspc/README.md) for full documentation, usage examples, and design principles.

## Design Philosophy

The `kenspc` plugin is opinionated on purpose. It encodes a single end-to-end
SOP — brief → plan → task → implement → review — rather than a grab-bag of
commands, and it is written principle-first: outcome-and-rationale instructions
over step-by-step scaffolding, tuned for how current-generation models read
prompts. The v3 line was a deliberate refactor away from the aggressive
directive tokens and anti-rationalization scaffolding that once helped weaker
models but drag stronger ones down.

See [Design Principles](./plugins/kenspc/README.md#design-principles) for the
rules this follows, and
[Acknowledgements](./plugins/kenspc/README.md#acknowledgements) for the
prompt-engineering lineage behind them.

## Structure

```
.claude-plugin/
  marketplace.json        # Plugin registry
plugins/
  kenspc/                 # Plugin directory
    .claude-plugin/
      plugin.json
    agents/               # 11 reusable subagents
    skills/
    commands/
    hooks/
    references/
    shared/               # Cross-skill resources (e.g., discovery-framework.md)
    README.md
```

## Requirements

- Claude Code v2.1.0+
- No external plugin dependencies — all workflows and subagents ship with the plugin.

## Acknowledgements

See [plugin Acknowledgements](./plugins/kenspc/README.md#acknowledgements) for
attribution to thinkfirst, agent-skills, the Claude Code subagents convention,
and the prompting research that informed v3.0.

## License

MIT
