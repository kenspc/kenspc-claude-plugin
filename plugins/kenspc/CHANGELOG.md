# Changelog

> **Note on v1.x entries:** Entries for v1.0.0 through v1.5.0 were
> backfilled from git history on 2026-05-11. The original releases shipped
> without CHANGELOG documentation — the project was a single-maintainer
> dogfooding effort during the v1.x line, with version bumps recorded only
> in `plugin.json` and commit messages. The backfilled entries reconstruct
> Added/Changed/Removed scope from commit messages and `git diff`; for the
> authoritative source, see git log between commits `871c7e3` (initial,
> 2026-03-29) and `7328cec` (v1.5.0 docs, 2026-05-04).

## 3.0.3 — 2026-05-11 — Phase Transition Anchors & Emergent Behavior Formalization

Patch release based on the first end-to-end DungeonDescent dogfooding
trace (pixel-font-pass). Nine prompt-engineering refinements + meta-
lessons captured in CLAUDE.md. All edits are prompt-text refinements;
no new SKILLs, agents, or components.

### Phase 1 transitions (P0)
- task-implement Phase 1 Step 3 hardened as batch-confirmation gate
- task-implement Phase 1 Step 5+ disables cross-Phase closure wording
  (with explicit allowlist for Phase-internal progress phrases)

### Emergent behavior formalization (P1)
- generate-brief Phase 1 system-reminder conflict detection + Discovery
  Mode artifact field (full / rapid-direct / rapid-inferred)
- task-implement / task-review CUSTOM_INSTRUCTIONS dynamic construction
  formalized as conditional fold with N/A default

### Coverage gaps (P2)
- regression-verifier fallback for projects without test suite
  (spot-check mode); Schema C row 3 ("Tests pass") gains SPOT-CHECK as
  a documented third Result value alongside PASS / FAIL
- generate-task suggests /kenspc-plan re-run when reviewer reports
  non-empty Plan-Level Concerns

### Long-term value (P3)
- SessionEnd telemetry hook for missed-review tracking (zero
  user-visible disruption; JSON Lines log at
  `~/.claude/kenspc/missed-reviews.log`)
- check-canonical-dispatch.sh upgraded to byte-identity + anchor phrase
  frequency dual check
- CLAUDE.md adds two design lessons: Phase transitions via artifacts;
  hook scope boundaries

### Meta-lessons (informing this patch)
- Stop hook misjudgement: rebatched to SessionEnd telemetry after
  recognizing hooks cannot observe SKILL-internal Phase state
- Author warning: prompt changes are not code changes — verification
  must be runtime trace inspection, not build/test pass

### Known asymmetry (deferred to v3.0.4+)
- generate-plan does NOT mirror generate-brief's Discovery Mode
  Detection — generate-plan input is typically more structured;
  reminder pressure has not been observed in plan generation traces

## 3.0.2 — 2026-05-06

Over-constraint cleanup. Removes two v3.0.0-introduced constraints that
violated v3's own bitter-lesson philosophy: forced English runtime output
and the static `Status` column on Planned Dispatch tables. No new
features; no SKILL interface or agent name changes; no CONTEXT block
schema changes.

### Removed

- Forced English runtime output. Removed from 4 agents
  (`plan-document-reviewer`, `guide-document-reviewer`,
  `task-document-reviewer`, `task-implementer`), the project root
  `CLAUDE.md` "Writing Rules for Skill Content" section, the plugin
  `README.md` Design Principles section, and the `plugin.json`
  description string's sixth design rule. v3 master plan AC6
  ("No bilingual output") is retired with a placeholder section that
  cites the retirement decision; AC numbering preserved so AC7–AC11
  references stay valid. `code-fixer.md`'s code-artifacts English
  constraint and `task-implementer.md`'s renamed CODE ARTIFACTS LANGUAGE
  block are intentionally kept (they scope to code artifacts only).

### Changed

- Planned Dispatch table header: `Status` → `Role` across 5 dispatching
  SKILL.md (6 tables total — `task-implement` has 2). Each row's `Role`
  cell is a one-line agent purpose string (≤ 60 chars) drawn from the D3
  mapping in the v3.0.2 plan. v3 master plan AC8 reversed: now asserts
  the Planned Dispatch window has NO Status column / pending marker.
- Plugin description rewritten from "six design rules ... and English-only
  output" to "five design rules" (drops the sixth rule).
- v3 master plan AC10 README review checklist updated: "6 rules" → "5
  rules"; "Bilingual claim removed" → "English-only output feature claim
  removed". CLAUDE.md review checklist drops the now-stale "Output in
  English only bullet present" assertion.
- `docs/release-checklist.md` row 3 (`/kenspc-brief` smoke) Pass
  criterion changed from "first user-facing prompt is English-only" to
  "first user-facing prompt is a question (not a draft)" — covers the
  brief's no-draft-during-discovery invariant without enforcing language.

### Rationale

The v3.0.0 plan's Non-Goals item 7 already recorded the underlying root:
"Live updating dispatch tables — Claude Code's TUI already handles this".
v3.0.0 nonetheless shipped tables with hard-coded `pending` cells that
the orchestrator could not edit after dispatch — the table always lied.
The TUI bottom bar is the real live state. The forced-English output
rule was the same antipattern in another dimension: using SKILL/agent
text to constrain a runtime decision that session/global/project
CLAUDE.md context already controls.

This is a correction of v3.0.0 execution drift, not a reversal of
direction. The bitter lesson is "guards should enforce things that are
actually enforceable", not "fewer guards".

### Note

- Result tables (Schemas A/D/E/G — rendered after dispatch) keep their
  `Status` columns. Those reflect real outcomes the orchestrator computes
  before rendering, so they are correct.
- `.claude-plugin/marketplace.json` is unchanged (audited clean — its
  description is a one-sentence registry summary that never carried the
  English-only claim).

## 3.0.1 — 2026-05-05

Post-review hardening pass. The v3.0 implementation passed all 11 plan
ACs and shipped clean, but the post-implementation multi-angle code review
surfaced verification-surface weaknesses (mostly in the AC commands
themselves) that were worth closing before users encountered them. No
behavioral change to skills or agents — the user-facing surface is
identical to 3.0.0.

### Added

- `scripts/check-review-agent-drift.sh` — guards the byte-identity
  invariant across the 5 review-angle agents (PREREQUISITES, FILE
  COVERAGE, CUSTOM INSTRUCTIONS sections must stay identical). Project
  CLAUDE.md flagged drift as a bug; this script is the mechanical guard.
  Now part of plan AC9.
- `scripts/check-canonical-dispatch.sh` — guards the byte-identity
  invariant on the `## Code Review Phase (unconditional)` block between
  `task-review/SKILL.md` and `task-implement/SKILL.md`. Replaces the v3.0
  AC7 `grep -A 20 ... | head -25` pipeline, which coupled verification to
  the canonical block's line count. The new approach extracts everything
  between explicit `<!-- canonical:dispatch:start -->` /
  `<!-- canonical:dispatch:end -->` markers and sha256-hashes it.
- HTML comment markers (`<!-- canonical:dispatch:start -->` /
  `<!-- canonical:dispatch:end -->`) around the canonical dispatch block
  in both `task-review/SKILL.md` and `task-implement/SKILL.md`. The
  markers are inert to the LLM (they are HTML comments) but make the
  byte-identity contract explicit.
- `docs/release-checklist.md` — manual smoke checklist that exercises
  plugin load + first interactive surface of every entry point. Closes
  the gap that v3.0's mechanical AC1–AC11 left open: a YAML frontmatter
  break passes every grep but breaks plugin loading.
- Project `CLAUDE.md` documents the marketplace.json / plugin.json
  description-layering convention (registry summary vs full metadata —
  not meant to be byte-synced) and the new `scripts/` directory.

### Changed

- Plan AC5 (no aggressive language) tightened from `^MUST | NEVER `
  column-anchored regex to `grep -rnwE` word-boundary match. Catches
  inline (`you MUST do X`), indented (`- MUST`), end-of-line, and
  punctuation-followed forms that the v3.0 pattern missed.
- Plan AC6 (no bilingual output) tightened from `/ 中|/ 华|中 /|华 /`
  (only catches `中`/`华`) to a Latin/CJK-with-spaced-slash pattern that
  catches any CJK character bilingual label, while still letting
  unspaced compound terms like `(代码审查/review代码)` through. Reviewer
  must spot-check for paragraph-level translations and other variants.
- Plan AC7 replaced with `bash scripts/check-canonical-dispatch.sh`. No
  more magic-number window.
- Plan AC8 (Dispatch Status Tables) tightened to require `pending` to
  appear inside an actual markdown table row (line starting with `|`) so
  a stray `pending` in prose cannot satisfy the check.
- Plan AC9 grew two cheap text-level sanity checks: drift script call
  and a `! grep -qiE '## Review|Review Phase|review-phase'
  generate-brief/SKILL.md` (brief must remain review-phase-free).
- Plan AC11 (JSON sanity) extended to also validate
  `.claude-plugin/marketplace.json` (the registry root).
- Plugin version bumped to 3.0.1 in `plugin.json`.

### Notes

- Post-review surfaced ~32 unique findings; this release addresses the
  ones that survive deep analysis as genuine forward-looking improvements
  (drift invariant guard, canonical block markers, smoke checklist,
  AC pattern hardening). Findings reclassified as reviewer
  misdiagnoses or cosmetic doc nits are not addressed — see the analysis
  recorded in the session that produced this release for the per-finding
  disposition.
## 3.0.0 — 2026-05-04

Breaking refactor aligning the plugin with Claude Opus 4.7 at xhigh/max
effort. v3 follows six design rules: workflow SOP stays, business rules
framed as why-not-command, DONE-criteria over step-by-step flow, no
anti-rationalization scaffolding, plain language over aggressive directive
tokens, and English-only output. (The English-only rule was retired in
v3.0.2 — see that release's entry above.)

*Note: The Rationale and Acknowledgements sections below were added
2026-05-11 to document design provenance omitted from the original release
notes. The Removed/Added/Changed/Notes content is unchanged from
2026-05-04. Earlier mention of `generate-brief` in the headline was a
backfill error — `generate-brief` was introduced in v1.5.0, not v3.0.0;
see the v1.5.0 entry below.*

### Rationale

The kenspc plugin was originally designed against Sonnet 4.5 and Opus 4.5.
Many of its components — anti-rationalization tables, hardcoded numerical
thresholds, step-by-step EXECUTION FLOW sections, aggressive directive
tokens (CRITICAL/MUST/NEVER/ULTRATHINK), and bilingual output — exist to
compensate for failure modes those older models exhibited.

Opus 4.7 changes that calculus. Per Anthropic's prompting guidance, the
4.6/4.7 generation interprets prompts more literally, over-respects
aggressive language, follows literal "don't nitpick" style instructions
faithfully enough to suppress findings, and benefits from outcome-first
prompts rather than prescriptive procedures. Scaffolding built for weaker
models begins to actively harm stronger ones — the model spends effort
honoring constraints that no longer encode real limits.

v3.0 is a one-shot refactor that retires these compensations. It is a
breaking refactor (no migration period) because the plugin is single-
maintainer and the v2.0 surface area was small enough to refactor in one
pass.

### Removed

- Anti-rationalization tables (the `Common-Rationalizations`-style tables
  that listed laziness scripts) in every SKILL.md and agent .md.
- Bilingual output forcing in skill execution messages, final summaries,
  status labels, agent COMPLETION templates, command files, and hook
  scripts. The discovery framework's "How to ask" examples remain as the
  deliberate exception (illustrative phrasings for the Discovery
  conversation).
- Fake numerical Red Flags (`~15+`, `~8 rounds`, `more than half`); rewritten
  qualitatively or removed.
- `ULTRATHINK` directives; reasoning depth is now controlled by the
  `effort:` frontmatter on each SKILL.md and agent .md.
- Aggressive language tokens: uppercase `MUST`, `NEVER`, `CRITICAL`, and
  `STOP immediately` are gone. "use" / "avoid" / "do not" replace MUST/NEVER;
  stop-and-report prose replaces STOP-immediately.

### Added

- `effort:` frontmatter on every SKILL.md and every agent .md (`xhigh` /
  `max` for coding-adjacent work, `high` for read-only or document review;
  see CLAUDE.md § Subagent Review Architecture for the per-skill and
  per-agent rationale).
- Dispatch Status Tables (Planned Dispatch + result table) at every
  dispatching skill: `generate-plan`, `generate-task`, `generate-guide`,
  `task-implement`, `task-review`.
- Tabulated final reports per Schemas A–G:
  - Schema A — review-angle agents (HIGH/MEDIUM/LOW counts + per-issue
    table with file:line / severity / confidence / description columns).
  - Schema B — `code-fixer` accountability table (with required `short_label`
    ≤ 60 chars per issue) plus Deferred Issues prose.
  - Schema C — `regression-verifier` (verification check table + non-PASS
    detail prose).
  - Schema D — `task-implementer` (per-task table + Blocked / Decisions /
    Post-implementation prose).
  - Schema E — doc-reviewer agents (Angle × Status × Changes × Commit
    table); `task-document-reviewer` adds a Plan-Level Concerns section.
  - Schema F — `task-review` final consolidated report (Schema A roll-up +
    B + C + Verdict + Next Steps).
  - Schema G — `task-implement` final consolidated report (Schema D + A
    roll-up + B + C + Verdict + Next Steps; supports a BLOCKED verdict
    that omits Code Review / Fixes / Verification when every task is
    BLOCKED).
- Unconditional review dispatch in `task-review` and `task-implement`. The
  canonical paragraph is byte-identical between the two skills, so the
  rationale stays aligned across edits. The orchestrator no longer
  "decides" whether a review is needed — it dispatches and aggregates.
- Anthropic code-review-harness coverage prompt in all 5 review-angle
  agents: "Report every issue you find … Your goal here is coverage."
  Filtering happens downstream in `code-fixer` and `regression-verifier`.

### Changed

- EXECUTION FLOW prose rewritten as Goal + Inputs + DONE criteria +
  Constraints. The model decides the order; structure self-contained but
  not step-heavy.
- Business Rules rewritten as rationale-anchored "Why: …" framing instead
  of `MUST` / `NEVER` commands. Context and motivation help Claude follow
  the intent of each rule, not just its letter.
- Phase 2 self-challenge in `generate-plan` reframed as a single Goal with
  DONE criteria and Constraints (no numbered substep list).
- All SKILL.md `version:` fields bumped to 3.0.0 to align with plugin
  version.
- README Design Principles section now distills the six v3 design rules.
  Requirements section names a concrete Claude Code minimum (v2.1.0+).
  Effort levels subsection points to Anthropic's skill / subagent
  frontmatter docs.
- Project CLAUDE.md "Writing Rules for Skill Content" replaces the
  bilingual and ULTRATHINK bullets with a Rule 2 rationale-anchored
  bullet, an English-only output bullet, and a reasoning-by-effort note.

### Notes

- generate-plan ships at `effort: max`; if drafts bloat under real
  workloads, downgrade to `xhigh` in a future patch.

### Acknowledgements

The Bitter Lesson framing that motivated this refactor came from external
community analysis of Claude Opus 4.x prompting practices. Technical
principles draw from Anthropic's Opus 4.7 prompting best practices,
Anthropic's essays on context engineering and harness design, and OpenAI's
GPT-5.5 prompting guide. (For thinkfirst attribution — relevant to the
discovery framework introduced in v1.5.0, not v3.0.0 — see the v1.5.0
entry below.) For full attribution with links, see the [plugin README
Acknowledgments section](README.md#acknowledgments).

## 2.0.0 — 2026-05-04

### Breaking changes

- Internal `prompts/` directories removed; subagent definitions migrated to
  `agents/` directory as plugin agents. Plugin-internal change — no impact on
  user-facing skill or command interfaces.

### Added

- 11 reusable subagents in `plugins/kenspc/agents/`, discoverable via `/agents`:
  - 5 code review angle agents (standalone-safe): `requirements-reviewer`,
    `edge-case-reviewer`, `quality-reviewer`, `bug-reviewer`, `test-reviewer`
  - 3 document reviewers (orchestration-only): `plan-document-reviewer`,
    `guide-document-reviewer`, `task-document-reviewer`
  - 3 workers (orchestration-only): `code-fixer`, `regression-verifier`,
    `task-implementer`

### Changed

- All 5 affected SKILL.md files updated to dispatch agents by name with
  structured CONTEXT input (replaces template variable substitution).
- All 5 affected SKILL.md `version` fields bumped to 2.0.0 to align with
  plugin version.

## 1.5.0 — 2026-05-04

Adds requirement brief generation and extracts discovery logic into a
shared framework. Brief becomes a new entry point upstream of plan, for
ideas too vague to plan directly.

### Rationale

generate-plan's Phase 1 Discover previously relied on Claude's own judgment
to guide the discovery conversation, with no structural anchor for which
dimensions to explore. This worked for clear requirements (Level 1-2) but
produced inconsistent results for vague inputs (Level 3) — the quality of
discovery questions varied across sessions depending on context window state.

The shared discovery framework (`shared/discovery-framework.md`) extracts
discovery logic into a single source of truth with five structured
dimensions (Outcome, Failure Modes, The Hard Part, Hidden Context, Stakes),
four input clarity levels, and explicit exit conditions. generate-plan
Phase 1 now references it inline; generate-brief provides a standalone
entry point for users who need to think through an idea before committing
to a plan.

The five-dimension approach is adapted from Gary Chen's thinkfirst skill,
which uses seven dimensions for general-purpose prompt crafting. Two
dimensions were dropped (Components → handled by generate-task; Success
Criteria → handled by generate-plan Phase 2 acceptance criteria) to avoid
overlap with existing pipeline stages.

### Added

- `generate-brief` skill (`skills/generate-brief/SKILL.md`) — structured
  discovery conversation that produces a shareable requirement brief
  (`docs/briefs/`). Two-phase (Discover, Produce Brief), no review phase.
- `/kenspc-brief` command for invoking generate-brief directly.
- `shared/discovery-framework.md` — five-dimension discovery framework,
  shared by `generate-brief` Phase 1 and `generate-plan` Phase 1. Single
  source of truth for the discovery conversation pattern.

### Changed

- generate-plan Phase 1 (Discover) now references
  `shared/discovery-framework.md` inline instead of carrying its own
  inline discovery logic.
- `plugin.json` description updated to lead with "Requirement brief
  generation through structured discovery".
- Plugin README, root CLAUDE.md, and root README updated to document the
  brief skill, the `/kenspc-brief` command, the `shared/` directory, and
  the optional brief→plan workflow extension.

### Acknowledgements

The five-dimension discovery framework is adapted from
[thinkfirst](https://github.com/garychen-ai/thinkfirst) by
[Gary Chen](https://github.com/garychen-ai), reduced from seven dimensions
to five. See [plugin README Acknowledgments](README.md#acknowledgments)
for full attribution.

## 1.4.0 — 2026-04-08

Adds `generate-task` skill (plan→task decomposition) and hardens existing
skills with anti-rationalization scaffolding tuned for the Sonnet 4.5 /
Opus 4.5 models the plugin was being developed against. (Most of the
scaffolding additions were removed in v3.0.0 once the plugin moved to
Opus 4.7 — see v3.0.0 Rationale.)

### Added

- `generate-task` skill (`skills/generate-task/SKILL.md`) with review
  prompt and `/kenspc-task` command — decomposes a plan document into
  fine-grained executable tasks.
- Anti-rationalization tables (Common-Rationalizations) added to:
  `task-implement`, `task-review`, `generate-plan`, `generate-guide`.
- Red flags (numerical thresholds and warning signals) added to the same
  four skills.
- Prompt variable tables added to `task-implement`, `task-review`, and
  `generate-guide`.
- Input validation and autonomy boundaries added to `task-implement`.
- Discovery principle, output convention, and trigger cleanup added to
  `generate-plan`.

### Changed

- `plugin.json` description updated to lead with "Plan generation, task
  decomposition, automated batch implementation with multi-angle review,
  and project guide generation".
- `task-implement`: project config change moved to STOP boundary; task
  filename convention clarified.
- Reminder hook extended to cover `generate-task` (`docs/tasks/` path).

### Fixed

- `task-implement`: stale step reference corrected.

## 1.3.0 — 2026-04-08

Reduces review iteration rounds by tightening implementation quality at
the source.

### Changed

- `task-implement`: implementation quality bar raised to align with
  `task-review` standards. Goal: fewer review rounds needed because
  implementation output passes more checks on first pass.

## 1.2.0 — 2026-04-06

Refines skill discoverability (descriptions and trigger keywords) and
adds a PreToolUse hook reminder.

### Added

- `generate-plan`: bilingual trigger keywords (Chinese + English
  invocation phrases) to broaden trigger coverage.
- PreToolUse hook reminder to clarify when each skill should engage.

### Changed

- Skill descriptions enriched across all skills to reduce "might apply"
  skips (cases where Claude would be unsure whether to activate the skill).
- Skill capability scope statements clarified.

## 1.1.0 — 2026-04-04

Tightens skill triggers, adds user confirmation gate before batch task
implementation, and enriches summaries.

### Added

- "Do NOT trigger" negative conditions on all skills, to prevent
  accidental activation during interactive development.
- `task-implement`: user confirmation step before dispatching batch
  implementation.
- `task-implement`: enriched implementation summary with
  Changes / Decisions / Notes per task, and Attempted / Root cause /
  Suggestion for blocked tasks.
- `task-implement`: consolidated final report.
- `task-implement`: `{{CUSTOM_INSTRUCTIONS}}` placeholder handling.
- `task-review`: enriched DEFERRED format with Why / Risk / Approach.
- `task-review`: enriched regression HAS ISSUES with per-problem
  Impact / Severity / Suggested action.
- `generate-plan`: git commit step in review agent execution flow +
  summary; Unresolved issues section.
- `generate-guide`: structured Unresolved gaps format in review summary.

### Removed

- Catch-all trigger phrases across all skills.

### Fixed

- `task-implement`: all-blocked logic gap.
- `task-implement`: broken `review.md` reference.

## 1.0.0 — 2026-03-29

Initial release. Plugin marketplace with three skills:
`generate-plan`, `task-implement`, `generate-guide`.

### Initial scope

- Three skills, each with `SKILL.md` and a per-skill `prompts/` directory:
  - `generate-plan` — strategic plan document generation with review
    prompt
  - `task-implement` — task implementation with implementation and review
    prompts (originally named `task-loop`; renamed within v1.0.0 — see
    In-version changes below)
  - `generate-guide` — project setup/deployment guide with review prompt
- Marketplace structure: `.claude-plugin/marketplace.json` (root) →
  `plugins/kenspc/` (plugin directory)
- Hooks for skill activation reminders
- References directory with task and plan example documents
- Slash commands for each skill

### In-version changes (same-day iterations within v1.0.0)

- `task-loop` skill renamed to `task-implement` as part of replacing the
  ralph-loop scripting model with a subagent-dispatched architecture
  (commit `2f2e732`). The `scripts/setup.sh` from the original `task-loop`
  was retired in this refactor.
- Repo restructured from flat layout to marketplace + nested plugin
  layout (commit `d02c080`).
- `owner` field added to `marketplace.json` (commit `fca7309`) — required
  by the marketplace registry.
