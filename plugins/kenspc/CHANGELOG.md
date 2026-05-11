# Changelog

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
