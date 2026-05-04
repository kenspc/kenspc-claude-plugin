# kenspc

A Claude Code plugin with opinionated development workflows — plan before you
code, structured task implementation, iterative multi-angle review, and project guide
generation.

## Skills

Skills activate automatically when Claude Code detects a matching task context.

| Skill | Description |
|-------|-------------|
| generate-brief | Two-phase requirement brief generation: structured discovery conversation against the shared discovery framework (five dimensions, four input clarity levels), then writes a shareable brief to `docs/briefs/`. No review phase — brief is a discovery artifact, not a verifiable spec; review happens downstream when generate-plan consumes the brief. |
| generate-plan | Three-phase plan document generation: collaborative discovery (uses shared discovery framework, detects briefs as input), drafting with self-challenge, and automated verification via review agent across four review angles (feasibility, completeness, consistency, clarity). |
| generate-task | Decomposes a plan document into fine-grained executable tasks by reading actual code. Confirms decomposition with user, then self-reviews for completeness and execution order via review agent. |
| task-implement | Automated batch task implementation from a task document. Validates input is a task document (not a plan). Confirms scope with user before starting. Each task is built, tested, committed, and marked complete. Automatically runs task-review on completion with a consolidated final report. |
| task-review | Parallel multi-angle code review (5 review agents → fix agent → regression verification). Works with a task document for requirements context, or standalone to review recent changes. Accepts custom instructions to narrow scope. |
| generate-guide | Generates comprehensive, beginner-friendly project setup and deployment guides with automated multi-dimensional post-generation review via review agent. |

## Commands

Commands provide a direct way to invoke each skill.

| Command | Usage |
|---------|-------|
| `/kenspc-brief` | `/kenspc-brief <rough idea or topic>` |
| `/kenspc-plan` | `/kenspc-plan <requirement or path> [custom instructions]` |
| `/kenspc-task` | `/kenspc-task <plan-document-path> [phase] [custom instructions]` |
| `/kenspc-task-implement` | `/kenspc-task-implement <path-to-task-file>` |
| `/kenspc-task-review` | `/kenspc-task-review [path-to-task-file] [custom instructions]` |
| `/kenspc-guide` | `/kenspc-guide <project-path> [custom instructions]` |

Skills can also be invoked via `/kenspc:generate-brief`, `/kenspc:generate-plan`,
`/kenspc:generate-task`, `/kenspc:task-implement`, `/kenspc:task-review`, and
`/kenspc:generate-guide`.

## Plugin Structure

```
plugins/kenspc/
    .claude-plugin/
    agents/               # 11 reusable subagents
    commands/
    hooks/
    references/
    shared/               # Cross-skill resources (e.g., discovery-framework.md)
    skills/
    README.md
```

## Agents

Plugin agents live in `agents/` and are dispatched by skills via the Agent tool.
They are also discoverable through `/agents` and can be `@kenspc:<name>`-mentioned
where their description marks them safe to invoke standalone.

| Agent | Type | Standalone | Description |
|---|---|---|---|
| `requirements-reviewer` | Code reviewer | Yes | Requirements completeness |
| `edge-case-reviewer` | Code reviewer | Yes | Edge cases and error handling |
| `quality-reviewer` | Code reviewer | Yes | Code quality and conventions |
| `bug-reviewer` | Code reviewer | Yes | Bug hunting (skeptical mindset) |
| `test-reviewer` | Code reviewer | Yes | Test coverage and quality |
| `code-fixer` | Worker | No | Applies fixes from review reports |
| `regression-verifier` | Verifier | No | Verifies fixes; read-only by design |
| `task-implementer` | Worker | No | Implements tasks from a task document |
| `plan-document-reviewer` | Doc reviewer | No | Reviews generated plan documents |
| `guide-document-reviewer` | Doc reviewer | No | Reviews generated guide documents |
| `task-document-reviewer` | Doc reviewer | No | Reviews generated task documents |

Agents marked "Standalone: No" are orchestration-only — their description starts
with `INTERNAL:` and their body refuses on missing CONTEXT. Invoke them through
the parent slash command instead.

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

- **Discover before plan** — Optional `/kenspc-brief` produces a requirement brief through structured discovery (five dimensions: Outcome, Failure Modes, The Hard Part, Hidden Context, Stakes). Both `generate-brief` and `generate-plan` share the same discovery framework so the brief→plan handoff is seamless
- **Plan before code** — Structured discovery and planning before any implementation begins
- **Implement then review** — Implementation and review are distinct phases; task-implement auto-triggers task-review to catch issues immediately
- **Multi-angle review** — Each review cycle examines work from multiple dimensions (requirements, edge cases, code quality, bugs, test coverage)
- **Parallel review agents** — Task review dispatches independent review agents in parallel for speed, then consolidates fixes and verifies with regression
- **Explicit decomposition** — Task decomposition is a visible, reviewable step between planning and implementation, not hidden inside the implementation agent
- **Stack-agnostic** — Skills inspect project config files rather than assuming specific frameworks
- **Beginner-friendly guides** — Generated guides explain not just what to do, but why, with error recovery tips
- **Bilingual output** — Progress messages and review summaries in English + Chinese; code and documents remain in their original language
- **Reusable agents** — Subagent prompts live as plugin agents in `agents/`, discoverable via `/agents` and reusable across skills. Standalone-safe code reviewers can be `@kenspc:<name>`-invoked directly; orchestration-only workers are gated behind their parent slash commands

## Recommended Workflow

```
Rough idea → [/kenspc-brief → docs/briefs/*.md →] /kenspc-plan → docs/plans/*.md → /kenspc-task → docs/tasks/*.md → /kenspc-task-implement → /kenspc-task-review
```

0. **Brief (optional)**: Use `/kenspc-brief` when the idea is too vague to plan directly, or when you need a shareable discovery document before planning. Skip this step if you already have a clear, structured requirement.
1. **Plan**: Use `/kenspc-plan` to create a strategic plan through collaborative discussion. If a brief was generated in step 0, pass it as the requirement: `/kenspc-plan docs/briefs/your-brief.md` — the skill detects briefs and gap-checks against the same five dimensions.
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
