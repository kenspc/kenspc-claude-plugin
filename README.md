# kenspc-claude-plugin

A Claude Code plugin marketplace with structured development workflow plugins.

## Installation

```bash
# Add the marketplace (one-time setup)
/plugin marketplace add kenspc/kenspc-claude-plugin

# Install a plugin (choose scope: user, project, or local)
/plugin install kenspc@kenspc-claude-plugin
```

## Available Plugins

### [kenspc](./plugins/kenspc/)

Opinionated development workflows — plan before you code, structured task implementation, iterative multi-angle code review, and project guide generation.

**Skills:**

| Skill | What it does |
|-------|-------------|
| generate-plan | Collaborative discovery + drafting + automated 4-angle review |
| generate-task | Plan-to-task decomposition via code analysis + 2-angle review |
| task-implement | Automated batch implementation with input validation and auto-review |
| task-review | Parallel 5-agent code review (MapReduce) with fix consolidation and regression verification |
| generate-guide | Beginner-friendly project guide generation with multi-dimensional review |

**Commands:** `/kenspc-plan`, `/kenspc-task`, `/kenspc-task-implement`, `/kenspc-task-review`, `/kenspc-guide`

See the [plugin README](./plugins/kenspc/README.md) for full documentation, usage examples, and design principles.

## Structure

```
.claude-plugin/
  marketplace.json        # Plugin registry
plugins/
  kenspc/                 # Plugin directory
    .claude-plugin/
      plugin.json
    skills/
    commands/
    hooks/
    references/
    README.md
```

## Requirements

- Claude Code v1.0.33+
- Recommended: [superpowers](https://github.com/anthropics/claude-plugins-official) plugin

## License

MIT
