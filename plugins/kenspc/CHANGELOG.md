# Changelog

## 3.0.0 (unreleased)

Breaking refactor aligning the plugin with Claude Opus 4.7 at xhigh/max
effort. Details fill in across the v3 commit sequence; this stub will be
finalized when the version bump lands.

- Removed: anti-rationalization tables, bilingual output forcing, fake
  numerical Red Flags, `ULTRATHINK` directives, aggressive
  `MUST`/`NEVER`/`CRITICAL` language.
- Added: `effort:` frontmatter on every SKILL and agent; Dispatch Status
  Tables at every dispatch site; tabulated final reports per Schemas A–G;
  unconditional review dispatch in `task-review` and `task-implement`.
- Changed: EXECUTION FLOW prose rewritten as Goal + Inputs + DONE criteria
  + Constraints; Business Rules rewritten as rationale-anchored "Why:"
  framing instead of `MUST`/`NEVER` commands.

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
