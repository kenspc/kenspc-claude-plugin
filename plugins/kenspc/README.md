# kenspc

A Claude Code plugin with opinionated software development workflows — plan before you
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
    shared/               # Cross-skill resources (discovery-framework.md, code-craft-principles.md)
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

v3 follows five design rules:

- **Workflow SOP** — The brief → plan → task → implement → review chain stays.
  Each skill's phase structure is preserved; v3 changed how each phase is
  executed, not what the phases are.
- **Why-not-Command business rules** — Business rules are framed as rationale
  ("Each task = one commit because the review unit is a task, not a session"),
  not as command-style imperatives. Context and motivation help Claude follow
  the intent, not just the letter, of each rule.
- **DONE-criteria over step-by-step flow** — Skills and agents declare a
  single-sentence Goal, the required Inputs, verifiable DONE criteria, and
  Constraints. The model decides the order. Numbered EXECUTION FLOW prose
  is removed.
- **No anti-rationalization scaffolding** — The anti-rationalization tables
  (`Common-Rationalizations`-style tables that listed laziness scripts) and
  fake numerical Red Flags (`~15+`, `~8 rounds`, `more than half`) are
  removed; listing specific laziness scripts inside the prompt primes the
  model toward those scripts.
- **Plain language over aggressive tokens** — Uppercase imperatives like
  `MUST` and `NEVER`, `CRITICAL` labels, and the deep-reasoning trigger token
  used in earlier versions are all removed. Reasoning depth is now controlled
  by the `effort:` frontmatter; "use" / "avoid" / "do not" replace `MUST` /
  `NEVER`; stop-and-report prose replaces `STOP immediately`.

Cross-cutting properties from earlier versions are preserved:

- **Multi-angle parallel review** — The 5 review-angle agents
  (requirements / edge-case / quality / bug / test) dispatch in parallel,
  feed `code-fixer`, then `regression-verifier`.
- **Reusable agents** — Plugin agents live in `agents/`, discoverable via
  `/agents`. Standalone-safe code reviewers can be
  `@kenspc:<name>`-invoked directly; orchestration-only workers are gated
  behind their parent slash commands.
- **Stack-agnostic skill behavior** — Skills inspect project config files
  rather than assuming specific frameworks. (Documentation examples in
  `shared/` may use specific languages — currently C# and TypeScript — to
  maximize teaching density; this does not constrain which projects the
  skills work with.)

### Effort levels

Every SKILL.md and agent .md declares an `effort:` frontmatter value
(`low` / `medium` / `high` / `xhigh` / `max`) per the
[Claude Code skills frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
and [subagent frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields).
Discovery, planning, decomposition, implementation, and review all run at
`xhigh` or `max`, matching Anthropic's recommendation for Claude Opus 4.7
coding and agentic workloads. When running at `xhigh`/`max`, set a large
max-output-token budget so the model has room to think and act across its
subagents and tool calls (this is a session/API config concern, not a
plugin concern).

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
- Claude Code v2.1.0+ (the version line that supports the `effort:`
  frontmatter on SKILL.md and agent .md files; required because v3 declares
  `effort:` on every skill and agent).

**Recommended:**
- A session that allows a generous max-output-token budget — when skills run
  at `xhigh`/`max` effort, the model needs room to think and act across its
  subagents and tool calls (Anthropic guidance for Claude Opus 4.7).

## Reference Documents

The `references/` directory contains example documents to help you get started:

- `task-document-example.md` — Shows the expected task document format for `task-implement`
- `plan-document-example.md` — Shows a typical plan output from `generate-plan`

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history.

## Acknowledgements

The anti-rationalization tables, red flags, and autonomy boundaries in this plugin
are inspired by [agent-skills](https://github.com/addyosmani/agent-skills) by
[Addy Osmani](https://github.com/addyosmani), licensed under MIT.

The Simplicity First and Surgical Changes principles in
`shared/code-craft-principles.md` are derived from Andrej Karpathy's
[October 2025 X post](https://x.com/karpathy/status/2015883857489522876) on
common LLM coding pitfalls, by way of the
[`andrej-karpathy-skills`](https://github.com/doggy8088/andrej-karpathy-skills)
`AGENTS.md` compilation by [doggy8088](https://github.com/doggy8088) (forked from
[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)).
kenspc adopts two of the four principles; example code is original and
stack-specific to the maintainer's primary stacks.

In the same spirit, v3.2.0 extends the review harness with two further checks
of kenspc's own — falsifiability (a test that cannot fail is not a test) and
fail-loud on incomplete test runs (never report a clean pass you did not fully
verify). These are kenspc additions applied to the review agents, not part of
Karpathy's four principles. v3.4.0 extends the falsifiability rule to the
write side as well: `task-implementer` requires each test it authors to be
able to fail, closing the authoring/review loop.

The five-dimension discovery framework (`shared/discovery-framework.md`) — used by
both `generate-brief` and `generate-plan` Phase 1 — is adapted from the structured
thinking dimensions in [thinkfirst](https://github.com/garychen-ai/thinkfirst) by
[Gary Chen](https://github.com/garychen-ai). Reduced from seven dimensions to five
to fit the plan-before-code workflow: `Components` is handled downstream by
`generate-task`, and `Success Criteria` by `generate-plan` Phase 2 acceptance
criteria.

The `agents/` directory structure (introduced in v2.0) follows the
[Claude Code subagents convention](https://code.claude.com/docs/en/sub-agents) —
agent files declared with standard frontmatter, discoverable through `/agents`,
and `@kenspc:<name>`-mentionable for the standalone-safe ones.

The v3.0 refactor was motivated by Gary Chen's April 2026 video
["Mythos 要來了，你的舊提示詞正在拖垮新模型？"](https://www.youtube.com/watch?v=MdZWB8eC83Q),
which applied Sutton's [2019 Bitter Lesson essay](http://www.incompleteideas.net/IncIdeas/BitterLesson.html)
to prompt and harness design with a sharper framing than Anthropic's Claude Opus 4.7
prompting best practices and OpenAI's GPT-5.5 prompting guide: outdated scaffolding
does not just become irrelevant — it actively drags down newer models.

The technical principles applied here come from:

- Anthropic, [Prompting best practices for Claude Opus 4.7](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- Anthropic, [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (Sep 2025)
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) (Mar 2026)
- OpenAI, GPT-5.5 prompting guide — referenced in the migration notes for outcome-first prompting and the principle of avoiding step-by-step process guidance unless the exact path matters.

## License

MIT
