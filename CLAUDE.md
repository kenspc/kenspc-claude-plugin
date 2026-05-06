# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin marketplace containing structured development workflow plugins. The primary plugin (`kenspc`) provides skills for plan-before-code workflows, requirement brief generation, plan-to-task decomposition, task implementation with automatic code review, and project guide generation. Review phases use plugin agents (defined in `agents/`) — serial review agents for plan/guide/task documents, parallel MapReduce review agents for code. The brief skill has no review phase (it produces a discovery artifact, not a verifiable spec).

## Marketplace Structure

- Root `.claude-plugin/marketplace.json` — plugin registry pointing to plugin directories
- Each plugin lives in `plugins/<name>/` with its own `.claude-plugin/plugin.json`, `README.md`, `LICENSE`, and component directories (`agents/`, `skills/`, `commands/`, `hooks/`, `references/`, `shared/`)
- The `description` field in `.claude-plugin/marketplace.json` is the registry-list summary (one short sentence). The `description` field in `plugins/<name>/.claude-plugin/plugin.json` is the full plugin metadata loaded after the user selects the plugin. The two are deliberately layered — the marketplace summary is typically the first sentence of the full description. Do not sync them blindly.

### Plugin Directory Layout

```
plugins/kenspc/
├── .claude-plugin/plugin.json   # Plugin metadata (name, version, author)
├── agents/                      # 11 reusable subagents (5 code reviewers + 3 doc reviewers + 3 workers)
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
│   │   └── SKILL.md
│   ├── generate-task/
│   │   └── SKILL.md
│   ├── generate-guide/
│   │   └── SKILL.md
│   ├── task-implement/
│   │   └── SKILL.md
│   └── task-review/
│       └── SKILL.md
├── README.md
└── LICENSE
```

## Skill Development Conventions

### File Structure

Each skill lives in `skills/<skill-name>/` with:
- `SKILL.md` — skill definition with YAML frontmatter (`name`, `description`, `version`, `argument-hint`) followed by structured phases/modes

Each plugin agent lives in `agents/<agent-name>.md` with YAML frontmatter (`name`, `description`, `tools`, `model`) followed by the agent's static system prompt. SKILLs dispatch agents by name through the Agent tool, passing a structured CONTEXT block as the dispatch prompt.

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

### Subagent Review Architecture

Skills use plugin agents (defined in `agents/`) as workers, dispatched via the
Agent tool. Three orchestration patterns:

**No review (generate-brief):**
Brief is a discovery artifact, not a verifiable spec. Review happens downstream
when generate-plan consumes the brief. Phase 1 detection in generate-plan
recognizes briefs and gap-checks against the same five dimensions defined in
`shared/discovery-framework.md`.

**Serial review (generate-plan, generate-task, generate-guide):**
Skill dispatches a single named agent (`plan-document-reviewer`,
`task-document-reviewer`, or `guide-document-reviewer`) that reviews all
angles in order in its own context. Each angle builds on fixes from the
previous one (cascade dependency). Agent body returns a structured change log.

**Parallel MapReduce (task-review):**
- Phase 1: 5 read-only review agents dispatched in parallel
  (`requirements-reviewer`, `edge-case-reviewer`, `quality-reviewer`,
  `bug-reviewer`, `test-reviewer`) — one per angle.
- Phase 2: `code-fixer` receives all 5 reports, deduplicates, applies fixes,
  produces accountability list.
- Phase 3: `regression-verifier` cross-checks reports against accountability
  list, verifies fixes, runs build/test/lint.

No shared state files — each agent runs in its own context, eliminating
concurrency conflicts. Subagents cannot spawn other subagents; orchestration
stays at the skill (main session) level.

As of v3.0, every SKILL.md and every agent .md declares an `effort:`
frontmatter value (`low` / `medium` / `high` / `xhigh` / `max`). Reasoning
depth is configured per skill and per agent via this field, not via inline
directive tokens. See `docs/plans/v3-bitter-lesson-refactor.md` § Effort
Allocation for the per-skill and per-agent rationale.

#### CONTEXT block contract

Each agent declares its expected CONTEXT keys in its body. The dispatching
SKILL.md must construct exactly those keys. See each agent file's
"CONTEXT YOU WILL RECEIVE" section for the contract.

#### Standalone safety classification

- **Standalone-safe**: 5 review-angle agents (requirements, edge-case, quality,
  bug, test) can be invoked directly. Description gates auto-delegation;
  body refuses without CONTEXT.
- **Orchestration-only**: 6 worker/document-reviewer agents (code-fixer,
  regression-verifier, task-implementer, plan-document-reviewer,
  guide-document-reviewer, task-document-reviewer) require structured
  CONTEXT input from a calling skill. Their first description sentence is
  "INTERNAL: ..." and their body has a prerequisite check that refuses on
  missing CONTEXT.

#### Maintenance note

The 5 review-angle agents share PREREQUISITES, FILE COVERAGE, and CUSTOM
INSTRUCTIONS sections by convention. When modifying any of these sections in
one agent, apply the same change to the other 4. Duplication is intentional
(each agent is independently readable); silent drift between them is a bug.
Run `bash scripts/check-review-agent-drift.sh` after editing any reviewer
agent — it hashes each shared section across the 5 files and fails on
non-identity. The same script is part of plan AC9.

The canonical `## Code Review Phase (unconditional)` block in
`task-review/SKILL.md` and `task-implement/SKILL.md` is bounded by
`<!-- canonical:dispatch:start -->` / `<!-- canonical:dispatch:end -->`
markers and must remain byte-identical between the two files. Run
`bash scripts/check-canonical-dispatch.sh` after editing either skill —
it sha256-hashes the bounded block in both files and fails on drift.
This script is the AC7 implementation.

### Non-Goals

`shared/discovery-framework.md` stays in `shared/` and is NOT converted into a plugin agent. It is consumed by the main session at three call sites (generate-brief Phase 1, generate-plan Phase 1) as a structural guide for free-form discovery dialogue with the user — not as bounded delegated work. Subagent isolation would also break Phase 2's need for raw conversation context. See the v2 plan's Non-Goals section (`docs/plans/extract-reusable-agents-v2.md`) for the authoritative rationale.

### Writing Rules for Skill Content

- Use rationale-anchored business rules (Rule 2): frame each rule as "Why: ..." prose rather than command-style imperatives, so the model follows the intent of the rule, not just its letter
- Reasoning depth is controlled by the `effort:` frontmatter on each SKILL.md and agent .md, not by inline directive tokens
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
# JSON sanity (all three: plugin metadata, hooks config, marketplace registry)
cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null
cat plugins/kenspc/hooks/hooks.json | python -m json.tool > /dev/null
cat .claude-plugin/marketplace.json | python -m json.tool > /dev/null

# Verify all SKILL.md files have required frontmatter
grep -l "^name:" plugins/kenspc/skills/*/SKILL.md

# Cross-agent invariants
bash scripts/check-review-agent-drift.sh
bash scripts/check-canonical-dispatch.sh
```

### Repository scripts/

Project-level shell scripts live in `scripts/` at the repo root:

- `check-review-agent-drift.sh` — guards the byte-identity invariant
  across the 5 review-angle agents (PREREQUISITES, FILE COVERAGE, CUSTOM
  INSTRUCTIONS). Implements plan AC9.
- `check-canonical-dispatch.sh` — guards the byte-identity invariant on
  the `## Code Review Phase (unconditional)` canonical block between
  `task-review/SKILL.md` and `task-implement/SKILL.md`. Implements plan AC7.

Run before tagging any release; both should also be considered as
pre-commit hook candidates when their target files change.

### Release procedure

See [docs/release-checklist.md](docs/release-checklist.md) for the manual
smoke-test checklist that exercises plugin load + every entry-point's
first interactive surface. Mechanical AC1–AC11 alone cannot catch YAML
parse breaks, missing path references, or other load-time failures —
the smoke checklist is the gap-closer.
