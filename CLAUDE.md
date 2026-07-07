# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin marketplace containing structured software development workflow plugins. The primary plugin (`kenspc`) provides skills for plan-before-code workflows, requirement brief generation, plan-to-task decomposition, task implementation with automatic code review, and project guide generation. Review phases use plugin agents (defined in `agents/`) — serial review agents for plan/guide/task documents, parallel MapReduce review agents for code. The brief skill has no review phase (it produces a discovery artifact, not a verifiable spec).

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
│   ├── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan
│   └── code-craft-principles.md # Code-craft principles shared by task-implementer, code-fixer, quality-reviewer
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
Three hooks are registered: `SessionStart` → `check-deps.sh` (dependency
check), `PreToolUse` on `Write` → `remind-plan-skill.sh` (plan-skill
reminder — note it fires on every Write call, not only plugin-related
ones), and `SessionEnd` → `session-end-telemetry.sh` (post-hoc telemetry;
background in Plugin Design Lessons).

References live in `references/` as example documents (task format, plan format) to help users get started.

Shared resources live in `shared/` as cross-skill files (prompt frameworks, templates) referenced via `${CLAUDE_PLUGIN_ROOT}/shared/<file>.md`. Two entries today: `discovery-framework.md`, loaded by both `generate-plan` Phase 1 and `generate-brief` Phase 1 to provide a single source of truth for the discovery conversation pattern (five dimensions, four input clarity levels, exit conditions); and `code-craft-principles.md`, referenced by three agents (`task-implementer`, `code-fixer`, `quality-reviewer`) — it defines the Simplicity First and Surgical Changes principles with stack-specific C# / TypeScript diff examples, and explicitly does NOT define Goal-Driven Execution (covered by DONE-criteria in every SKILL), Think Before Coding for ad-hoc interactions (belongs in user-level or project-level CLAUDE.md), per-language style guides (delegated to project CLAUDE.md), or agent dispatch order / CONTEXT contracts (defined in the dispatching SKILL.md and each agent's header).

### Portable Paths

All file references in hooks and commands must use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths.

### Writer-agent section header convention

Writer-agent files (`task-implementer.md`, `code-fixer.md`) use ALL-CAPS section headers with no hyphens (e.g., `OBJECTIVE`, `PREREQUISITES`, `QUALITY RULES`, `FIXING PRIORITY`). The single canonical compound-adjective exception is `CODE-CRAFT PRINCIPLES`, where the hyphen joins "code" and "craft" into a single adjective modifying "principles" — removing it would change the meaning, not just the punctuation. Each occurrence of `CODE-CRAFT PRINCIPLES` in a writer-agent body is paired with an HTML guard comment on the line immediately above the header, naming the compound-adjective exception and pointing back to this paragraph. The co-location ensures that a future editor who would otherwise normalize away the hyphen sees the rationale next to the header before they edit, and so any future normalization edit must update this CLAUDE.md paragraph in the same commit.

### SKILL.md Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (kebab-case) |
| `description` | Yes | When to activate (1-2 sentences, concise) |
| `version` | Yes | Semver (e.g., `1.0.0`) |
| `argument-hint` | Recommended | Shown in UI as placeholder (e.g., `<project-path>`) |

The per-skill `version` field is uniformly `3.0.0` across all six skills and
denotes the v3 architecture generation, not a per-skill change counter. It is
deliberately decoupled from the plugin version in
`plugins/kenspc/.claude-plugin/plugin.json`, which is the authoritative version
and the only one bumped each release. It was set during the v3.0.0 rewrite and
is intentionally left unchanged on subsequent releases — syncing six files
every release is churn that has historically drifted anyway. Bump it only on a
future architecture-generation change (a v4 rewrite), and bump all six together
so the uniformity holds.

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
directive tokens. The effort ladder follows Anthropic's guidance for
frontier Claude models: `xhigh` for coding/agentic work and a minimum of
`high` for intelligence-sensitive work (source: Opus 4.8 prompting
guidance, unchanged from the Opus 4.7 guidance adopted at the v3.0
rewrite; last verified against the current frontier generation
2026-07-07 — re-verify at each release, see the release checklist). When running at `xhigh`/`max`, set a large
max-output-token budget so the model has room to think and act across
subagents and tool calls (this is a session/API-config concern, not a
plugin concern).

The `effort:` frontmatter in each file is authoritative — this prose
records the rationale, not a second copy of the values. The default is
`xhigh` across skills and agents: coverage-mode bug-finding (the 5
review-angle agents), long-horizon coding (`task-implement` /
`task-implementer`), cross-report deduplication (`code-fixer`), discovery
plus drafting (`generate-brief`), code-reading decomposition
(`generate-task`), and the recommended floor for the `task-review`
harness. The exceptions:

- `generate-plan` runs at `max` — multi-round draft/challenge across
  project context; plan cost amortizes over downstream tasks.
- The 3 document reviewers (`plan-document-reviewer`,
  `task-document-reviewer`, `guide-document-reviewer`) run at `high` —
  review against fixed criteria is closer to checklist verification than
  open-ended authoring.
- `regression-verifier` runs at `high` — read-only verification; lower
  depth acceptable.
- `generate-guide` runs at `high` — section-by-section documentation
  generation, closer to mechanical templating than open-ended planning.

Author-vs-reviewer asymmetry is intentional: `generate-plan` (`max`) vs
`plan-document-reviewer` (`high`), and `generate-task` (`xhigh`) vs
`task-document-reviewer` (`high`) — authoring needs deep multi-round
thinking; document review against fixed criteria does not. The
`generate-guide` / `guide-document-reviewer` pair is symmetric at `high`.

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

Two more byte-identity invariants bind `task-review/SKILL.md` and
`task-implement/SKILL.md`: the canonical `## Code Review Phase
(unconditional)` block (bounded by `<!-- canonical:dispatch:start/end -->`
markers) and the shared verdict-determination bullets (bounded by
`<!-- canonical:verdict-shared:start/end -->` markers).

After editing any reviewer agent or either of those two SKILLs, run the
matching guard script — `check-review-agent-drift.sh`,
`check-canonical-dispatch.sh`, or `check-verdict-shared.sh`. What each
guard checks is documented once, in "Repository scripts/" below.

### Non-Goals

`shared/discovery-framework.md` stays in `shared/` and is NOT converted into a plugin agent. It is consumed by the main session at two call sites (generate-brief Phase 1, generate-plan Phase 1) as a structural guide for free-form discovery dialogue with the user — not as bounded delegated work. Subagent isolation would break the discovery phase's need for raw conversation context (the orchestrator must keep the full transcript to draft the brief or plan in Phase 2).

### Writing Rules for Skill Content

- Use rationale-anchored business rules (Rule 2): frame each rule as "Why: ..." prose rather than command-style imperatives, so the model follows the intent of the rule, not just its letter
- Reasoning depth is controlled by the `effort:` frontmatter on each SKILL.md and agent .md, not by inline directive tokens
- Review summaries must list every change with the reason (what changed and why)
- Stack-agnostic: read project config files to detect tech stack, never assume a specific framework

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

# Cross-agent invariants (runs every scripts/check-*.sh guard)
bash scripts/check-all.sh
```

### Repository scripts/

Project-level shell scripts live in `scripts/` at the repo root:

- `check-all.sh` — wrapper that runs every other `check-*.sh` guard in
  main mode and reports PASS/FAIL per script. The single entry point for
  pre-commit and pre-flight runs; new guard scripts are picked up
  automatically, no command list to update.
- `check-review-agent-drift.sh` — guards the byte-identity invariant
  across the 5 review-angle agents (PREREQUISITES, FILE COVERAGE, CUSTOM
  INSTRUCTIONS).
- `check-canonical-dispatch.sh` — guards the byte-identity invariant on
  the `## Code Review Phase (unconditional)` canonical block between
  `task-review/SKILL.md` and `task-implement/SKILL.md`.
- `check-verdict-shared.sh` — guards the byte-identity invariant on the
  shared verdict-determination block (the `SPOT-CHECK` neutral note plus
  the involuntary-incomplete and intentional-skip clauses that map
  regression-verifier's row-3 Schema C states to a verdict) between
  `task-review/SKILL.md` and `task-implement/SKILL.md`. The surrounding
  PASS / FAIL / PARTIAL / BLOCKED bullets differ between the two skills by
  design and stay outside the markers.
- `check-code-craft-canonical.sh` — guards the byte-identity invariant
  on the canonical Simplicity First and Surgical Changes principle
  paragraphs across `shared/code-craft-principles.md` (authoritative)
  and the two writer agents (`task-implementer.md`, `code-fixer.md`)
  that inline them.
- `check-quality-reviewer-bullet-structure.sh` — guards the structural
  invariant on the two REVIEW CHECKLIST bullets in `quality-reviewer.md`
  (Over-engineering, Drive-by refactoring): each must enumerate exactly
  three numbered conditions gated by an `**all three**` qualifier.
- `check-notes-format-sync.sh` — guards that the per-task Implementation
  notes block's two sub-bullet labels (`Decisions:`, `Changes/tradeoffs:`)
  stay present in both the live agent (`task-implementer.md`, which
  prescribes the format) and the demonstrated example
  (`references/task-document-example.md`, which users copy from). An
  anchor-presence guard, not byte-identity — the surrounding prose differs
  by design (the agent describes the format, the example shows a filled-in
  instance); it catches a rename of either label in one file but not the
  other.

Five of the guards (`check-canonical-dispatch.sh`,
`check-verdict-shared.sh`, `check-code-craft-canonical.sh`,
`check-quality-reviewer-bullet-structure.sh`,
`check-notes-format-sync.sh`) also accept a `--self-test` flag that runs
a mutation regression fixture in a temp workdir (positive path, negative
path on a deliberate mutation, restoration path on revert). `check-all.sh`
does not run the self-tests — they stay explicit in the release-checklist
mechanical-check block.

Run `bash scripts/check-all.sh` before tagging any release; it is also
the natural pre-commit hook candidate when guard-target files change.

### Workflow artifacts under docs/

This repo dogfoods the plugin's own chain on itself: briefs land in
`docs/briefs/`, plan documents in `docs/plans/`, task documents in
`docs/tasks/`, and manual dry-run transcripts in `docs/dry-runs/`.
These artifacts are transient by convention — completed plan/task
documents are routinely deleted once shipped, so an empty directory or a
missing document referenced by an old commit message is normal, not a
gap. `docs/release-checklist.md` is the one permanent document there.

### Release procedure

See [docs/release-checklist.md](docs/release-checklist.md) for the manual
smoke-test checklist that exercises plugin load + every entry-point's
first interactive surface. The pre-flight mechanical checks alone cannot
catch YAML parse breaks, missing path references, or other load-time
failures — the smoke checklist is the gap-closer.

## Plugin Design Lessons (Cumulative)

### Phase transitions rely on artifacts, not wording
Closure phrases ("complete", "landed", "wrapped up") are decorations.
The model treats Phase N+1 as triggered only when Phase N has produced
the artifact Phase N+1 reads as input. Anchor cross-phase contracts via
artifacts (files written, fields filled, dispatch CONTEXT blocks) — not
via closure-style natural language alone.
Background: v3.0.2 task-implement Phase 1 → Phase 2 sometimes failed to
auto-trigger because Phase 1 closure phrasing read as "session over" to
the orchestrator.

### Hooks are for environment constraints and post-hoc telemetry, not workflow state-machine guarding
Hooks fire on harness events (SessionStart, SessionEnd, Stop, etc.) and
do not observe SKILL-internal Phase state. Using a hook to enforce
"task-implement should be followed by task-review" leads to false-positive
blocking (Stop hook fires on legitimate Phase 1 → Phase 2 transitions
within a single SKILL run). Use hooks for:
- Environment setup / teardown
- Cross-session telemetry (post-hoc analysis)
- External system notifications
Avoid using hooks for SKILL-internal workflow guarantees.
Background: an early v3.0.3 design considered a Stop hook to force
task-review dispatch; rebatched into a SessionEnd telemetry log after
recognizing the misjudgement.
