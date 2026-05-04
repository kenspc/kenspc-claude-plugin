# Changelog

## 3.0.0 — 2026-05-04

Breaking refactor aligning the plugin with Claude Opus 4.7 at xhigh/max
effort. v3 follows six design rules: workflow SOP stays, business rules
framed as why-not-command, DONE-criteria over step-by-step flow, no
anti-rationalization scaffolding, plain language over aggressive directive
tokens, and English-only output. The full plan lives at
[docs/plans/v3-bitter-lesson-refactor.md](../../docs/plans/v3-bitter-lesson-refactor.md).

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
  `max` for coding-adjacent work, `high` for read-only or document review,
  per § Effort Allocation in the v3 plan).
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
- README Design Principles section now distills the six v3 design rules
  and references the v3 plan as the authoritative spec. Requirements
  section names a concrete Claude Code minimum (v2.1.0+). Effort levels
  subsection points to Anthropic's skill / subagent frontmatter docs.
- Project CLAUDE.md "Writing Rules for Skill Content" replaces the
  bilingual and ULTRATHINK bullets with a Rule 2 rationale-anchored
  bullet, an English-only output bullet, and a reasoning-by-effort note.

### Notes

- generate-plan ships at `effort: max`; if drafts bloat under real
  workloads, downgrade to `xhigh` in 3.0.1.

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
