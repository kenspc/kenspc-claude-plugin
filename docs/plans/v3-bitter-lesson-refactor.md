# Plan: kenspc Plugin v3.0 — Bitter Lesson Refactor

## Objective

Refactor the `kenspc` plugin (currently v2.0.0) into v3.0.0 so its skills and
agents align with the way Claude Opus 4.7 at `xhigh`/`max` effort actually
behaves. The current plugin was written against Opus 4.5/4.6 and now contains
compensations that hurt 4.7: anti-rationalization tables, hardcoded numerical
red flags, step-by-step EXECUTION FLOW, aggressive `MUST`/`NEVER`/`CRITICAL`/
`ULTRATHINK` tokens, and bilingual output that conflicts with session/project
language settings.

This is a **single, breaking refactor**. No deprecation period, no migration
shim. `plugin.json` bumps 2.0.0 → 3.0.0, every SKILL.md `version:` bumps to
3.0.0, and every change ships in one release.

### In scope

- Add `effort:` frontmatter to every `SKILL.md` and every agent `.md`
- Apply the 6 design rules (below) across **all** skill, agent, command, hook,
  and shared files
- Replace narrative dispatch instructions with rationale-anchored unconditional
  dispatch language in `task-review` and `task-implement`
- Add Dispatch Status Tables (planned + results) to every dispatch site
- Tabulate every agent final-summary section using the 7 result schemas
  (A–G) defined in § Result Schemas (A–G) below
- Update `plugin.json` description, `README.md` Skills table and Design
  Principles section, project `CLAUDE.md` Writing Rules section, and create
  `plugins/kenspc/CHANGELOG.md` with a v3.0 entry

### Out of scope (Non-Goals)

- Merging review-angle agents (5 → 2-3 consolidation deferred)
- Redesigning brief → plan → task → implement → review chain
- Splitting/renaming skills, agents, files, or directories
- Changing dispatch architecture or CONTEXT block schemas
- Introducing new skills/agents
- Changing the `kenspc/...` namespace
- "Live updating" dispatch tables (Claude Code's TUI already handles this)
- Restructuring `shared/discovery-framework.md` beyond Rule 5 / Rule 6 cleanup

## Background

Three published Anthropic principles drive this refactor:

1. **Bitter lesson for harnesses** (Harness Design article): "every component
   in a harness encodes an assumption about what the model can't do on its
   own ... worth stress testing ... can quickly go stale as models improve."
   The author's own example was stripping the sprint-decomposition layer when
   moving from Opus 4.5 to 4.6, because the new model planned coherently
   without it. v3.0 is the same operation against this plugin's anti-laziness
   scaffolding.

2. **Less prescription, more autonomy** (Effective Context Engineering):
   "smarter models require less prescriptive engineering, allowing agents to
   operate with more autonomy." Numbered EXECUTION FLOWs and "Common
   Rationalizations" tables push 4.7 toward over-respecting the script.

3. **Literal instruction following at higher effort** (Opus 4.7 prompting
   best-practices): "Claude Opus 4.7 interprets prompts more literally and
   explicitly than Claude Opus 4.6, particularly at lower effort levels."
   `MUST`/`NEVER`/`CRITICAL`/`ULTRATHINK` are now over-respected; rationale
   ("Why:" / "Add context to improve performance") works better than
   imperatives.

A specific production bug also forced the issue: in long sessions where the
orchestrator just watched task-implement run, it sometimes skipped the
auto-triggered task-review dispatch — reasoning that since it had seen the
implementation, review felt redundant. Anthropic's Harness Design article
documents this exact failure mode: "agents tend to respond by confidently
praising the work" they just produced. The fix is to make dispatch
unconditional with stated rationale, not narrative ("Then follow Steps 3-5").

## Design Principles (the 6 rules)

Every change in this refactor must satisfy all 6 rules. These are the
acceptance test for any single edit.

### Rule 1 — Workflow SOP stays
The brief → plan → task → implement → review chain stays. Each skill's phase
structure stays (Discover → Plan → Verify, etc.). v3.0 changes HOW each phase
is executed, not WHAT the phases are.

### Rule 2 — Business Rules stay, rewritten as WHY not COMMAND
Replace command-style framing ("MUST commit per task") with rationale framing
("Each task = one commit because the review unit is a task, not a session").
Anthropic 4.7 doc: "Providing context or motivation behind your instructions
... can help Claude better understand your goals."

### Rule 3 — EXECUTION FLOW becomes DONE criteria
Numbered step-by-step EXECUTION FLOW sections are removed. Each becomes:
- **Goal**: one sentence
- **Inputs**: what's required to start
- **DONE criteria**: verifiable conditions for completion
- **Constraints / Business Rules**: what cannot be violated

The model decides the order. Applies to subagent .md files as well (they need
self-contained structure, but self-contained ≠ step-heavy).

### Rule 4 — Anti-rationalization tables are deleted
Every "Common Rationalizations" table is deleted. Per Anthropic 4.7 doc:
"Replace blanket defaults with more targeted instructions ... Remove
over-prompting." Listing specific laziness scripts inside the prompt primes
the model toward those scripts. Replace with at most a one-line quality bar.

"Red Flags" sections lose fake numerical thresholds (`~15+`, `~8 rounds`,
`more than half`). Either rewrite qualitatively ("when blocked tasks dominate
the run") or remove.

### Rule 5 — Aggressive language is downgraded

| Old | New |
|---|---|
| `ULTRATHINK` | Remove entirely. Adaptive thinking + `effort:` controls depth. |
| `MUST` (uppercase) | "Use" / "is required" |
| `NEVER` (uppercase) | "Avoid" / "Do not" / state Business Rule with reason |
| `CRITICAL` | Remove the label; state the rule plainly |
| `STOP immediately` | "Stop and report ..." with reason |
| `CRITICAL: You MUST ...` | Plain instruction, e.g. "Use this tool when ..." |

### Rule 6 — Bilingual output is removed
All bilingual output (English + Chinese, e.g. "Implementation complete /
实现完成") is removed throughout the plugin. Output is English only. The
display language is already controlled by session, global CLAUDE.md, and
project CLAUDE.md — forcing bilingual at the skill level conflicts with those
controls.

Applies to: progress messages, final summaries, status labels, section
headers, agent .md COMPLETION templates, command files, hook scripts.

**Exception (resolved per Open Question 4 below)**: bilingual *examples* in
`shared/discovery-framework.md`'s "How to ask" column stay — those are
illustrative phrasings showing the model how to phrase questions in the
user's language, not output forcings.

## Effort Allocation

`effort:` is a real YAML frontmatter field on both SKILL.md
([reference](https://code.claude.com/docs/en/skills#frontmatter-reference))
and agent .md
([reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)).
Valid values: `low`, `medium`, `high`, `xhigh`, `max`. Inherits from session
when omitted; overrides per-skill/per-agent while active.

Anthropic's Opus 4.7 default recommendation: "Start with the new `xhigh`
effort level for coding and agentic use cases, and use a minimum of `high`
effort for most intelligence-sensitive use cases."

### SKILL.md effort

| Skill | effort | Rationale |
|---|---|---|
| `generate-brief` | `xhigh` | Discovery + drafting; coding-adjacent |
| `generate-plan` | `max` | Multi-round draft/challenge across project context. Plan cost amortizes over downstream tasks. **See Risk 3** — must be validated post-merge |
| `generate-task` | `xhigh` | Code-reading decomposition |
| `task-implement` | `xhigh` | Long-horizon coding |
| `task-review` | `xhigh` | Code review harness — Anthropic's recommended floor |
| `generate-guide` | `high` | Section-by-section documentation generation |

### Agent .md effort

| Agent | effort | Rationale |
|---|---|---|
| `requirements-reviewer` | `xhigh` | Coverage-mode bug-finding |
| `edge-case-reviewer` | `xhigh` | Coverage-mode bug-finding |
| `quality-reviewer` | `xhigh` | Coverage-mode bug-finding |
| `bug-reviewer` | `xhigh` | Coverage-mode bug-finding |
| `test-reviewer` | `xhigh` | Coverage-mode bug-finding |
| `code-fixer` | `xhigh` | Cross-report deduplication and fix application |
| `regression-verifier` | `high` | Read-only verification; lower depth acceptable |
| `task-implementer` | `xhigh` | Long-horizon coding |
| `plan-document-reviewer` | `high` | Document review against criteria |
| `guide-document-reviewer` | `high` | Document review against criteria |
| `task-document-reviewer` | `high` | Document review against criteria |

Anthropic guidance to apply when these run at `xhigh`/`max`: "set a large
max output token budget so the model has room to think and act across its
subagents and tool calls." Operationally this is a session/API-config concern
(not a plugin concern), but include a note in `README.md` Requirements
section.

**Note on author-vs-reviewer asymmetry**: `generate-plan` runs at `max`
while `plan-document-reviewer` runs at `high`. This is intentional —
authoring needs deep multi-round draft/challenge thinking; document review
against fixed criteria is closer to checklist verification and runs
acceptably at `high` (parallel to the read-only `regression-verifier`
rationale). The same logic applies to the `generate-task` /
`task-document-reviewer` pair (`xhigh` author / `high` reviewer) and the
`generate-guide` / `guide-document-reviewer` pair (`high` author /
`high` reviewer — symmetric here because guide generation is closer to
mechanical templating than open-ended planning).

## Decisions on Open Questions

This refactor faces 5 open questions raised during planning. Resolutions
and rationale:

### Q1 — Should every `SKILL.md` `version:` be bumped to 3.0.0?

**Decision: yes, every SKILL.md bumps to 3.0.0.**

Rationale: SKILL.md `version:` is the per-skill semver. v2 enforced
SKILL.md = plugin.json (per the v2.0.0 CHANGELOG: "All 5 affected SKILL.md
`version` fields bumped to 2.0.0 to align with plugin version"). v3
continues that policy — `head -1 SKILL.md`-style inspection should reveal
v3 behavior without cross-referencing plugin.json. Agent .md files do
**not** have a `version:` field per the subagent frontmatter reference,
so they're left alone.

### Q2 — Phase numbering inside skills: stay or rename to goal-named?

**Decision: keep Phase numbering ("Phase 1: Discover", "Phase 2: Plan", ...).**

Rationale: Phase numbering is part of the user-facing SOP (Rule 1 says SOP
stays). It shows up in user-facing progress messages ("Phase 2 starting / ...")
and lets inline guidance refer to "Phase 2 Step X" precisely. Goal names
(e.g. "Discovery") would still imply order but lose the count, and inline
cross-references would degrade. The refactor is HOW each phase executes, not
the phase structure.

### Q3 — Deduplicate the agent "PREREQUISITE CHECK" preamble?

**Decision: stay per-agent. Do not deduplicate.**

Rationale: Project CLAUDE.md explicitly states: "Duplication is intentional
(each agent is independently readable); silent drift between them is a bug."
This is a deliberate v2 architecture choice. The "Out of scope"
list above ("Changing dispatch architecture or CONTEXT block schemas")
covers this. The
maintenance note already establishes drift detection as a code-review
concern.

### Q4 — Bilingual examples in `shared/discovery-framework.md`: keep or strip?

**Decision: keep.**

Rationale: The "How to ask" column (e.g. "如果交付出来你不满意，最可能是因为
什么？") shows the *model* how to phrase Discovery questions in the user's
language. It's illustrative framework content, not output. Rule 6 targets
output forcings (skill execution messages, summaries) — not framework
examples. The discovery framework's intent is to support the user's
language whatever it is, and stripping the Chinese examples would silently
bias the model toward English-only Discovery for Chinese-speaking users.

### Q5 — Schema B "Issue (short)" column: orchestrator generates or `code-fixer` provides?

**Decision: `code-fixer` provides both `short_label` and full description.**

Rationale: `code-fixer` already has full context on
each issue when processing the 5 review reports — generating a one-phrase
label there is cheaper and more accurate than re-summarizing in the
orchestrator. The orchestrator just renders the table. This shapes the
`code-fixer` agent body's output contract: each issue entry must include
`short_label` (≤ 60 chars) alongside the existing detail fields.

## Plugin Metadata Description (target text)

The current `plugin.json` description reads:

> "Structured development workflows for Claude Code. Eleven reusable subagents
> power requirement brief generation, plan generation, task decomposition,
> automated batch implementation with multi-angle review, and project guide
> generation."

Replace with v3 target text:

> "Structured development workflows for Claude Code, aligned with Opus 4.7
> at xhigh/max effort. Eleven reusable subagents drive brief generation,
> plan generation, task decomposition, automated batch implementation, and
> multi-angle parallel review. v3 follows six design rules: workflow SOP
> stays, business rules framed as why-not-command, DONE-criteria over
> step-by-step flow, no anti-rationalization scaffolding, plain language
> over MUST/NEVER/CRITICAL/ULTRATHINK, and English-only output."

## Dispatch Status Tables (schema)

Every dispatching skill renders two tables at its dispatch site.

**Point 1 — Planned Dispatch Table** (rendered before agents run):

| # | Agent | Status |
|---|-------|--------|
| 1 | <agent-name> | pending |
| ... | ... | pending |

**Point 3 — Result Table** (rendered after agents return; one of Schemas A–G
applies; see § Result Schemas).

The status column starts at `pending` and moves to `done` / `failed`. The
TUI handles live updates; the skill writes the table once before dispatch
and once after with final results — no manual mid-run mutation.

For single-agent dispatches (serial review skills: generate-plan,
generate-task, generate-guide), Point 1 is a single-row table.

For 5-agent parallel dispatch (task-review Phase 1), Point 1 is a 5-row
table.

## Canonical Unconditional Dispatch Paragraph

This paragraph is written once and pasted byte-for-byte into both
`task-review/SKILL.md` and `task-implement/SKILL.md`. Future edits stay
aligned by the C6 verification diff.

```
## Code Review Phase (unconditional)

Dispatch all 5 review-angle agents. This is a workflow contract, not a
judgment call — the orchestrator does not decide whether a review is
"needed". The reason: agents are unreliable evaluators of work they just
produced (Anthropic, Harness Design, 2026), so the review exists precisely
because self-evaluation is biased toward confirming the work just done.

Dispatch even when:
- The implementation just completed and the orchestrator saw all the code
- Tests passed during implementation
- The code looks correct

The orchestrator's job in this phase is to dispatch and aggregate — not to
pre-filter findings.
```

## Result Schemas (A–G)

Every agent's COMPLETION/final-report section uses one of these schemas.
Schemas were chosen so the orchestrator can render them as tables without
re-parsing prose.

### Schema A — Review-angle agent (5 agents: requirements / edge-case / quality / bug / test)

```
## Findings

| Severity | Count |
|----------|-------|
| HIGH     | <n>   |
| MEDIUM   | <n>   |
| LOW      | <n>   |

## Issues

| # | Severity | Confidence | File:Line | One-line description |
|---|----------|------------|-----------|----------------------|
| 1 | HIGH     | high       | path:42   | <description>        |
| 2 | MEDIUM   | medium     | path:99   | <description>        |
```

Coverage rule (per Anthropic code-review-harness pattern): report every
issue, including uncertain or low-severity ones. Filtering happens
downstream in `code-fixer` and `regression-verifier`.

### Schema B — code-fixer accountability

```
## Fixes Applied

| # | short_label              | Severity | File:Line | Action  | Commit  |
|---|--------------------------|----------|-----------|---------|---------|
| 1 | <≤60 char label>         | HIGH     | path:42   | FIXED   | abc1234 |
| 2 | <≤60 char label>         | MEDIUM   | path:99   | DEFERRED| —       |

## Deferred Issues (prose)

For each DEFERRED row, one short paragraph: which issue, why deferred,
suggested follow-up.
```

`short_label` is supplied by `code-fixer` (see Q5). The orchestrator
renders this table verbatim.

### Schema C — regression-verifier

```
## Verification

| # | Check                       | Result | Detail                      |
|---|-----------------------------|--------|-----------------------------|
| 1 | All accountability rows fixed | PASS   | —                         |
| 2 | Build succeeds              | PASS   | —                           |
| 3 | Tests pass                  | FAIL   | 2 failures (see below)      |
| 4 | Lint passes                 | PASS   | —                           |
| 5 | No regressions in non-fix files | PASS | —                         |

## Detail

For each non-PASS row, one short paragraph describing what failed and
where.
```

### Schema D — task-implementer

```
## Tasks

| # | Task ID | Status   | Files Touched | Commit  |
|---|---------|----------|---------------|---------|
| 1 | T-001   | DONE     | a.ts, b.ts    | abc1234 |
| 2 | T-002   | BLOCKED  | —             | —       |

## Blocked tasks (prose)

For each BLOCKED row: which task, why blocked, what the user needs to
unblock.

## Decisions made

Bulleted list of non-trivial implementation decisions taken during the
run (e.g., chose library X over Y because ...).

## Post-implementation notes

Anything the reviewer should know (e.g., "T-003 introduced a new
dependency; document this in package.json review").
```

### Schema E — doc-reviewer (plan / guide / task)

```
## Review

| Angle | Status     | Changes       | Commit  |
|-------|------------|---------------|---------|
| 1     | PASSED     | —             | —       |
| 2     | FIXED (2)  | section X, Y  | def5678 |
| 3     | NOTED      | open question | ghi9012 |
| 4     | PASSED     | —             | —       |

## Changes (prose)

For each FIXED / NOTED row: what changed, why, commit hash.
```

`task-document-reviewer` adds an additional **Plan-Level Concerns**
prose section beneath the table for upstream-plan issues that don't
belong inside the task doc itself.

### Schema F — task-review final consolidated report

```
## Review summary

(Schema A roll-up across 5 agents — total HIGH / MEDIUM / LOW counts.)

## Fixes

(Schema B verbatim.)

## Verification

(Schema C verbatim.)

## Verdict

PASS / FAIL / PARTIAL — one paragraph rationale.

## Next steps

Bulleted list of follow-ups (deferred issues, regression failures,
reviewer recommendations).
```

### Schema G — task-implement final consolidated report

```
## Implementation

(Schema D verbatim.)

## Code Review

(Schema A roll-up.)

## Fixes

(Schema B verbatim.)

## Verification

(Schema C verbatim.)

## Verdict

PASS / FAIL / PARTIAL / BLOCKED — one paragraph rationale.
BLOCKED applies when every task in Schema D is BLOCKED; in that case the
Code Review / Fixes / Verification sections are omitted.

## Next steps

Bulleted list (failed verifications, deferred issues, blocked task
unblocks).
```

## What NOT to Do (Non-Goals reference)

The In-scope and Out-of-scope lists at the top of this document are the
authoritative Non-Goals list. Wherever a commit description below says
"see § What NOT to Do" or "§ Non-Goals", refer back to the **Out of
scope** list under § Objective.

## File Change Matrix

32 files change in total. Grouped by commit (see § Implementation Sequence).

| # | Path | Change type | Touches | Commit |
|---|------|-------------|---------|--------|
| 1 | `plugins/kenspc/.claude-plugin/plugin.json` | metadata | description; version 2.0.0 → 3.0.0 (deferred to final commit) | C1 (description), C12 (version) |
| 2 | `plugins/kenspc/CHANGELOG.md` | edit (file already exists at v2.0.0; prepend new section) | v3.0 entry | C1 (init), C12 (finalize) |
| 3 | `plugins/kenspc/shared/discovery-framework.md` | edit | Rule 5 (lang), Rule 6 (bilingual scope check); examples stay (Q4) | C2 |
| 4 | `plugins/kenspc/skills/generate-brief/SKILL.md` | edit | + `effort: xhigh`, version 3.0.0, Rules 2/3/4/5/6 | C3 |
| 5 | `plugins/kenspc/skills/generate-task/SKILL.md` | edit | + `effort: xhigh`, version 3.0.0, Rules 2/3/4/5/6 | C3 |
| 6 | `plugins/kenspc/skills/generate-guide/SKILL.md` | edit | + `effort: high`, version 3.0.0, Rules 2/3/4/5/6, Dispatch Status Tables | C3 |
| 7 | `plugins/kenspc/skills/generate-plan/SKILL.md` | edit | + `effort: max`, version 3.0.0, Rules 2/3/4/5/6, Dispatch Status Tables, self-challenge phase reframed | C4 |
| 8 | `plugins/kenspc/skills/task-review/SKILL.md` | edit | + `effort: xhigh`, version 3.0.0, Rules 2/3/4/5/6, Dispatch Status Tables (5 angles), **unconditional dispatch fix at Step 3** | C5 |
| 9 | `plugins/kenspc/skills/task-implement/SKILL.md` | edit | + `effort: xhigh`, version 3.0.0, Rules 2/3/4/5/6, Dispatch Status Tables, **unconditional dispatch fix at Phase 2** | C6 |
| 10 | `plugins/kenspc/agents/requirements-reviewer.md` | edit | + `effort: xhigh`, Rules 5/6, Schema A summary template, code-review harness coverage prompt | C7 |
| 11 | `plugins/kenspc/agents/edge-case-reviewer.md` | edit | (same as #10) | C7 |
| 12 | `plugins/kenspc/agents/quality-reviewer.md` | edit | (same as #10) | C7 |
| 13 | `plugins/kenspc/agents/bug-reviewer.md` | edit | (same as #10) | C7 |
| 14 | `plugins/kenspc/agents/test-reviewer.md` | edit | (same as #10) | C7 |
| 15 | `plugins/kenspc/agents/code-fixer.md` | edit | + `effort: xhigh`, Rules 5/6, Schema B summary, `short_label` output contract per Q5 | C8 |
| 16 | `plugins/kenspc/agents/regression-verifier.md` | edit | + `effort: high`, Rules 5/6, Schema C summary | C8 |
| 17 | `plugins/kenspc/agents/task-implementer.md` | edit | + `effort: xhigh`, Rules 5/6, Schema D summary | C8 |
| 18 | `plugins/kenspc/agents/plan-document-reviewer.md` | edit | + `effort: high`, Rules 5/6, Schema E summary | C9 |
| 19 | `plugins/kenspc/agents/guide-document-reviewer.md` | edit | + `effort: high`, Rules 5/6, Schema E summary | C9 |
| 20 | `plugins/kenspc/agents/task-document-reviewer.md` | edit | + `effort: high`, Rules 5/6, Schema E summary + Plan-Level Concerns section | C9 |
| 21 | `plugins/kenspc/commands/kenspc-brief.md` | edit | Rule 5 | C10 |
| 22 | `plugins/kenspc/commands/kenspc-plan.md` | edit | Rule 5 | C10 |
| 23 | `plugins/kenspc/commands/kenspc-task.md` | edit | Rule 5 | C10 |
| 24 | `plugins/kenspc/commands/kenspc-task-implement.md` | edit | Rule 5 | C10 |
| 25 | `plugins/kenspc/commands/kenspc-task-review.md` | edit | Rule 5 | C10 |
| 26 | `plugins/kenspc/commands/kenspc-guide.md` | edit | Rule 5 | C10 |
| 27 | `plugins/kenspc/hooks/scripts/check-deps.sh` | edit | Rule 5/6 if any user-facing strings; minimal | C10 |
| 28 | `plugins/kenspc/hooks/scripts/remind-plan-skill.sh` | edit | Rule 5/6 on reminder messages | C10 |
| 29 | `plugins/kenspc/references/plan-document-example.md` | review-only | confirm no narrative changes needed | C0 (audit, no commit) |
| 30 | `plugins/kenspc/references/task-document-example.md` | review-only | confirm no narrative changes needed | C0 (audit, no commit) |
| 31 | `plugins/kenspc/README.md` | edit | Skills table descriptions, Design Principles section (replace bilingual line, replace ULTRATHINK reference, add 6-rules summary) | C11 |
| 32 | `CLAUDE.md` (project root) | edit | Writing Rules section: remove bilingual mandate, remove ULTRATHINK directive, update Subagent Review Architecture if anything changed | C11 |

## Implementation Sequence

12 commits total, plus an audit pre-step. Each commit must independently
pass the relevant subset of acceptance criteria; the final commit (C12) must
pass all 11.

Commit message format: `feat(v3): ...`, `refactor(v3): ...`, `fix(v3): ...`,
`docs(v3): ...`. Final version-bump uses `chore(v3): bump version to 3.0.0`.

### C0 — Audit (no commit)

**Goal**: confirm reference documents (#29, #30) need no narrative changes,
and confirm the root `.claude-plugin/marketplace.json` does not require
a version bump beyond what C12 will already do.

**Inputs**: existing `plugins/kenspc/references/*.md`; root
`.claude-plugin/marketplace.json`.

**Audit checklist for each reference doc** (reject if any are present;
fold into C11 if found):
- Bilingual output (English + Chinese mixed in the same line)
- Literal `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` tokens
- Numbered EXECUTION FLOW sections
- "Common Rationalizations" tables
- Numerical Red Flags (`~15+`, `more than half`, etc.)
- Phrasing that depends on v2 dispatch architecture (e.g.,
  template-variable substitution language)

**DONE when**:
- Both reference files reviewed against the checklist. If clean
  (expected case): no commit; proceed to C1.
- If changes are needed: fold them into C11 (the README + project
  CLAUDE.md commit). C11's DONE-when criteria expand at that point to
  include the reference-doc edits — the implementer must add them
  explicitly.
- `marketplace.json` reviewed: if it embeds a version field that
  duplicates `plugin.json`, fold its bump into C12 alongside the
  plugin.json bump; otherwise no action.

### C1 — Foundation: plugin.json description, CHANGELOG init

**Goal**: update marketing/metadata description; prepend a v3.0 stub to
the existing CHANGELOG (CHANGELOG.md already exists at v2.0.0 — preserve
the v2.0.0 section; new section goes at the top).

**Inputs**: § Plugin Metadata Description (target text) above, existing
`plugin.json`, existing `plugins/kenspc/CHANGELOG.md` (already exists at
v2.0.0 — prepend, do not overwrite).

**DONE when**:
- `plugin.json` `description` field is rewritten to reflect v3 (no
  bilingual claim; mention 6 design rules and Opus 4.7 alignment). `version:`
  stays 2.0.0 in this commit (defer to C12).
- `plugins/kenspc/CHANGELOG.md` has a new `## 3.0.0 (unreleased)` section
  prepended above the existing `## 2.0.0` section, with a bullet list of
  breaking changes (this list grows in C12 as remaining commits land).
  The existing `## 2.0.0` section is preserved unchanged.
- `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool`
  succeeds.

**Constraint**: do **not** bump `version:` in plugin.json yet — leaving it
at 2.0.0 through C2-C11 means a partial-merge state still self-identifies as
v2. Only C12 flips the marker.

### C2 — Shared: discovery-framework.md cleanup

**Goal**: apply Rule 5 (language) and Rule 6 (bilingual scope check) to the
shared framework. Examples in the "How to ask" column stay (Q4 decision).

**Inputs**: `shared/discovery-framework.md`, Rule 5 mapping table.

**DONE when**:
- All uppercase `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` tokens are
  replaced or removed. Lowercase `ultrathink` (e.g., a verbatim quote
  from Anthropic docs) is allowed only inside a fenced code block or a
  blockquote attribution; check each occurrence by case before keeping.
- The "ULTRATHINK to determine ..." narrative in the `discovery-framework.md`
  Step 1 prose (search for the literal "ULTRATHINK" token) is rephrased
  to effort-implicit language — the calling skill's `effort:` setting
  controls reasoning depth.
- "How to ask" Chinese phrasings preserved (Q4).
- `git diff` shows changes only inside `shared/discovery-framework.md`
  (one-file commit) and the diff is dominated by language token swaps,
  not structural rewrites: framework dimensions, exit conditions, and
  input-clarity levels remain intact.

### C3 — 3 simpler SKILL.md (brief, generate-task, generate-guide)

**Goal**: apply Rules 2/3/4/5/6 + add `effort:` + bump version 3.0.0 to the
three skills with the simplest dispatch profiles.

**Inputs**: per-skill SKILL.md current contents; § Effort Allocation
table above; Rules 2/3/4/5/6.

**DONE when** (per file):
- `effort:` added to frontmatter at allocation table value.
- `version: 3.0.0` set.
- "Common Rationalizations" table removed.
- "Red Flags" rewritten qualitatively or removed.
- EXECUTION FLOW / Phase Steps converted to Goal + Inputs + DONE +
  Constraints structure (Rule 3).
- All `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` tokens cleaned.
- All bilingual output strings reduced to English.
- `generate-guide` adds Dispatch Status Tables (Point 1 + Point 3) for
  the `guide-document-reviewer` dispatch.
- `generate-task` adds Dispatch Status Tables (Point 1 + Point 3) for
  the `task-document-reviewer` dispatch (Schema E result table).
- `generate-brief` adds **no** dispatch tables — it has no review phase.

**Constraint**: `generate-brief` must not gain a review phase. The
project CLAUDE.md and § Objective above are explicit: a brief is a
discovery artifact, not a verifiable spec.

### C4 — generate-plan SKILL.md

**Goal**: apply all rules + add `effort: max` + Dispatch Status Tables for
`plan-document-reviewer`. Reframe self-challenge phase as a goal, not a
step list.

**Inputs**: existing `generate-plan/SKILL.md`; § Effort Allocation; § Dispatch
Status Tables (schema); Schema E for `plan-document-reviewer` results.

**DONE when**:
- All criteria from C3 applied to this file.
- `effort: max` set. A one-sentence Risk-3 acknowledgement is added under
  the v3.0 CHANGELOG entry's "Notes" subsection (added at C4; will be
  finalized at C12), e.g., "generate-plan ships at effort: max; if
  drafts bloat under real workloads, downgrade to xhigh in 3.0.1."
- Phase 2 self-challenge step reframed: instead of numbered substeps, it
  has a Goal ("expose the weakest assumption in the draft"), DONE
  criteria ("draft accepted by user OR revised draft addresses every
  challenge"), and Constraints ("no fix without rationale").
- Phase 3 Dispatch Status Tables: Point 1 single-row "pending" before
  dispatch; Point 3 Schema E (review angles + status + changes + commit).

**Constraint**: Phase 1's brief-detection logic (recognising files
authored by `generate-brief` and gap-checking them against the five
discovery-framework dimensions) is preserved verbatim. Rule 3
("EXECUTION FLOW becomes DONE criteria") applies to step prescriptions,
not to functional logic. The brief-detection branch and the gap-check
exit criteria stay; only the surrounding prose framing changes.

### C5 — task-review SKILL.md (unconditional dispatch fix)

**Goal**: apply all rules + Dispatch Status Tables + **rewrite Step 3
dispatch instruction** to the rationale-anchored unconditional form.

**Inputs**: existing `task-review/SKILL.md`; § Canonical Unconditional
Dispatch Paragraph; Schemas A / B / C / F (§ Result Schemas).

**DONE when**:
- All criteria from C3 applied.
- Step 3 dispatch language is exactly § Canonical Unconditional Dispatch
  Paragraph above (paste byte-for-byte; do not paraphrase).

- No narrative "Then follow Steps X-Y" form remains in this file.
- Dispatch Status Tables: Point 1 (5-row pending); Point 3 Schema A
  (HIGH/MED/LOW per angle) → Schema B (code-fixer accountability) →
  Schema C (regression verification) → Schema F (final consolidated
  report).

**Constraint**: do **not** add `MUST` / `NEVER` to the unconditional
dispatch language. It must be plain rationale-anchored prose. Rule 5
applies even to the new content this commit introduces.

### C6 — task-implement SKILL.md (unconditional dispatch fix)

**Goal**: same as C5 but for the auto-triggered review at the end of
task-implement Phase 2.

**Inputs**: existing `task-implement/SKILL.md`, Schemas D + G.

**DONE when**:
- All criteria from C3 applied.
- Phase 2 dispatch instruction uses the same unconditional language as
  C5.
- Dispatch Status Tables present.
- Final consolidated report uses Schema G (Implementation D + Review A +
  Fixes B + Verification C + Verdict + Next Steps).
- All-blocked path documented: if every task is BLOCKED, omit Code Review
  / Fixes / Verification sections; verdict = BLOCKED.

**Constraint**: the dispatch language in C5 and C6 must be **textually
consistent**. They reference the same Anthropic principle and use the
same rationale phrasing. Implementer should write the language once and
paste into both files (same canonical paragraph), so future edits stay
aligned. Verification step at end of C6:

```bash
diff <(grep -A 20 'Code Review Phase (unconditional)' plugins/kenspc/skills/task-review/SKILL.md | head -25) \
     <(grep -A 20 'Code Review Phase (unconditional)' plugins/kenspc/skills/task-implement/SKILL.md | head -25)
```

If the diff is non-empty, the dispatch paragraphs have drifted — fix
before proceeding to C7. AC7 reruns this same diff post-merge.

### C7 — 5 review-angle agents (single commit)

**Goal**: apply Rules 5/6 + add `effort: xhigh` + replace summary with
Schema A + adopt the Anthropic code-review-harness coverage prompt to all
5 review-angle agents in one atomic change.

**Inputs**: 5 existing agent .md files; Schema A (§ Result Schemas).

**DONE when**:
- All 5 files have `effort: xhigh`.
- All 5 share the same updated PREREQUISITES, FILE COVERAGE, and CUSTOM
  INSTRUCTIONS sections (per project CLAUDE.md maintenance note).
- COMPLETION summary template in each agent matches Schema A: returns
  HIGH/MEDIUM/LOW counts plus a per-issue list with file:line, severity,
  confidence, and a one-line description.
- Each agent's CUSTOM INSTRUCTIONS includes coverage-mode language
  derived from Anthropic's code-review prompt: "Report every issue you
  find, including ones you are uncertain about or consider low-severity.
  Do not filter for importance or confidence at this stage — the
  code-fixer and regression-verifier handle filtering. Your goal here is
  coverage."
- All bilingual output stripped from COMPLETION sections.
- No `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` remain.

**Constraint**: this commit must change all 5 agents together. Splitting
into 5 commits creates drift windows; project CLAUDE.md treats drift
between these 5 as a bug.

**Frontmatter preservation**: when adding `effort:`, preserve every
existing frontmatter field (`name`, `description`, `tools`, `model`).
Do not reorder or rename them. `effort:` goes after `model:` to keep
the diff minimal. This rule applies to C7, C8, and C9.

### C8 — 3 worker agents (code-fixer, regression-verifier, task-implementer)

**Goal**: apply Rules 5/6 + add `effort:` + adopt Schemas B/C/D summary
templates. Add `short_label` output contract to `code-fixer` (Q5
resolution).

**Inputs**: 3 agent .md files, Schemas B/C/D, Q5 decision.

**DONE when**:
- `code-fixer.md` — `effort: xhigh`; per-issue output contract requires
  `short_label` (≤ 60 chars); summary uses Schema B (table + DEFERRED
  prose).
- `regression-verifier.md` — `effort: high`; summary uses Schema C
  (verification table with PASS/FAIL); detail prose for non-PASS rows.
- `task-implementer.md` — `effort: xhigh`; summary uses Schema D
  (per-task table + BLOCKED / Decisions / Post-implementation prose).
- All Rules 5/6 applied; bilingual stripped.

### C9 — 3 doc-reviewer agents (plan / guide / task)

**Goal**: apply Rules 5/6 + add `effort: high` + adopt Schema E summary
template. `task-document-reviewer` adds the "Plan-Level Concerns" prose
section.

**Inputs**: 3 agent .md files, Schema E.

**DONE when**:
- All 3 files: `effort: high`, Rules 5/6 applied, Schema E summary
  (angles × status × changes × commit).
- `task-document-reviewer` includes a clearly-labeled "Plan-Level
  Concerns" prose section beneath the table for upstream-plan issues
  that don't belong in the task doc itself.

### C10 — Commands + hooks

**Goal**: apply Rule 5/6 to the thin command files and the two hook
scripts. These are minimal.

**Inputs**: 6 command .md files, 2 .sh files.

**DONE when**:
- 6 command files have any `MUST`/`NEVER`/`CRITICAL`/`ULTRATHINK`
  removed; bilingual stripped if present.
- `check-deps.sh` reviewed; user-facing message strings (if any) made
  English-only and rationale-anchored.
- `remind-plan-skill.sh` reminder messages: Rule 5/6 applied.
- `cat plugins/kenspc/hooks/hooks.json | python -m json.tool` still
  succeeds.

### C11 — README.md + project CLAUDE.md

**Goal**: surface the v3 design in user-facing documentation. This must
land **before** C12's version bump so the README never describes v2
behavior on a v3 plugin.

**Inputs**: existing `plugins/kenspc/README.md`, project `CLAUDE.md`,
acceptance criterion AC10 below.

**DONE when**:
- `plugins/kenspc/README.md`:
  - Skills table descriptions reflect v3 behavior (no "ULTRATHINK"
    references; remove bilingual claims).
  - Design Principles section: replace the existing list with a
    distillation of the 6 rules (Workflow SOP / Why-not-Command /
    DONE-criteria / No-anti-rationalization / Plain-language /
    English-only output) and reference the v3 plan document as the
    authoritative spec.
  - "Bilingual output" bullet removed from Design Principles.
  - "ULTRATHINK" reference under "Recommended" requirements removed
    or rephrased (effort-based reasoning is now the mechanism).
  - Add a brief "Effort levels" subsection pointing users to the
    `effort:` frontmatter and Anthropic docs.
- Project `CLAUDE.md`:
  - "Writing Rules for Skill Content" section: remove the bilingual
    bullet, remove the "Use ULTRATHINK before major analysis" bullet,
    add "Use rationale-anchored business rules (Rule 2)" and "Output
    in English only" bullets.
  - "Subagent Review Architecture" section: confirm still accurate;
    add a note that all SKILLs and agents now declare `effort:`.

### C12 — Final: plugin.json version bump + CHANGELOG finalize

**Goal**: flip the version marker to 3.0.0 and finalize the v3.0
CHANGELOG entry with the complete breaking-change list.

**Inputs**: all prior commits; the full AC1–AC11 list under § Acceptance
Criteria below.

**DONE when**:
- `plugins/kenspc/.claude-plugin/plugin.json` `version` is `"3.0.0"`.
- `plugins/kenspc/CHANGELOG.md` `## 3.0.0` heading is no longer
  "unreleased"; date is filled in; bullets cover:
  - Removed: anti-rationalization tables, bilingual output, fake
    numerical Red Flags, `ULTRATHINK` directives, aggressive
    `MUST`/`NEVER`/`CRITICAL` language
  - Added: `effort:` frontmatter on every SKILL/agent; Dispatch
    Status Tables; tabulated final reports; unconditional review
    dispatch
  - Changed: EXECUTION FLOW → DONE-criteria; Business Rules
    rewritten as WHY-not-COMMAND
- All 11 acceptance criteria from § Acceptance Criteria pass.

**Constraint**: this is the last commit. Once merged, downstream users
who pull the plugin see v3 behavior immediately — there is no
deprecation overlap.

## Acceptance Criteria

The refactor is complete when **all 11 criteria pass**. Each is runnable
from the repo root.

### AC1 — Frontmatter completeness

```bash
# All SKILL.md and agent .md files have effort: in frontmatter.
for f in plugins/kenspc/skills/*/SKILL.md plugins/kenspc/agents/*.md; do
  grep -q '^effort:' "$f" || echo "MISSING effort: $f"
done | tee /tmp/ac1.log
test ! -s /tmp/ac1.log
```

### AC2 — Plugin version and description

```bash
# plugin.json at 3.0.0
grep -q '"version": "3.0.0"' plugins/kenspc/.claude-plugin/plugin.json
# plugin.json description reflects v3 (mentions "Opus 4.7" and "design rules")
grep -q 'Opus 4.7' plugins/kenspc/.claude-plugin/plugin.json
grep -q 'design rules' plugins/kenspc/.claude-plugin/plugin.json
# CHANGELOG has 3.0.0 entry, 2.0.0 entry preserved
grep -q '^## 3.0.0' plugins/kenspc/CHANGELOG.md
grep -q '^## 2.0.0' plugins/kenspc/CHANGELOG.md
```

### AC3 — No anti-rationalization tables

```bash
# Zero matches in plugins/.
grep -rn "Common Rationalizations" plugins/ | wc -l
# Expected: 0
```

### AC4 — No fake numerical thresholds

```bash
# Pattern matches "more than ~?N" or "~N+" inside SKILL.md and agent .md.
grep -rnE 'more than ~?[0-9]+|~[0-9]+\+|~[0-9]+ (rounds|tasks|issues|HIGH|MEDIUM|LOW)' plugins/kenspc/skills plugins/kenspc/agents | wc -l
# Expected: 0
```

The grep is approximate — manual review of the "Red Flags" sections
across all skills and agents is the source of truth. The grep catches the
common patterns (`~15+`, `~8 rounds`, `more than half`) but a determined
implementer could re-introduce a fake threshold in unreviewed prose
("dozens of issues", "many rounds"). Reviewer must spot-check.

CHANGELOG / README mentions of removed thresholds are allowed and excluded
by the path scope.

### AC5 — No aggressive language

```bash
# Word-boundary match catches inline, indented, end-of-line, and
# punctuation-followed forms that the v3.0 column-anchored pattern missed.
grep -rnwE 'ULTRATHINK|CRITICAL|MUST|NEVER' plugins/kenspc/skills plugins/kenspc/agents | wc -l
# Expected: 0
```

(CHANGELOG / migration notes describing what was removed may use them.
The path scope already excludes them.)

### AC6 — Removed in v3.0.2

Retired by v3.0.2 plan design decision D1
([docs/plans/v3.0.2-over-constraint-cleanup.md](v3.0.2-over-constraint-cleanup.md)).
v3.0.0 forced English-only runtime output via SKILL/agent text; v3.0.2
reversed that policy because runtime display language is properly decided
by session/global/project CLAUDE.md context, not by skill content. AC
numbering is preserved (AC7–AC11 references stay valid).

### AC7 — Unconditional dispatch fix verified

```bash
# Both files contain the rationale-anchored unconditional language.
grep -q 'unconditional' plugins/kenspc/skills/task-review/SKILL.md
grep -q 'unconditional' plugins/kenspc/skills/task-implement/SKILL.md
# Neither file uses the narrative "Then follow Steps" pattern for review dispatch.
! grep -E 'Then follow .* Step' plugins/kenspc/skills/task-review/SKILL.md
! grep -E 'Then follow .* Step' plugins/kenspc/skills/task-implement/SKILL.md
# The canonical block is byte-identical between the two files. Bounded by
# explicit HTML comment markers so drift inside or outside any line window
# is caught.
bash scripts/check-canonical-dispatch.sh
# Expected: exit 0 with "OK    canonical:dispatch — ..." line.
```

The marker-based check supersedes the v3.0 `grep -A 20 ... | head -25`
pipeline, which coupled the verification window to the canonical block's
line count. The new approach extracts everything between
`<!-- canonical:dispatch:start -->` and `<!-- canonical:dispatch:end -->`,
hashes it, and compares — no magic numbers, no assumptions about block
length. If a future legitimate edit changes the canonical block, the
markers stay in place; only the contents inside them need to be edited
identically in both files.

### AC8 — Planned Dispatch tables have no Status column

Reversed by v3.0.2 plan design decision D2
([docs/plans/v3.0.2-over-constraint-cleanup.md](v3.0.2-over-constraint-cleanup.md)).
Planned Dispatch tables retain their visibility role but no longer carry
a Status column with hard-coded "pending" markers (the static markdown
cannot reflect live state — the TUI handles that channel).

```bash
# Every dispatching skill has a Planned Dispatch list/table that names all
# agents it will dispatch, but does NOT have a Status column or "pending"
# marker masquerading as live state.
for f in \
  plugins/kenspc/skills/generate-plan/SKILL.md \
  plugins/kenspc/skills/generate-guide/SKILL.md \
  plugins/kenspc/skills/generate-task/SKILL.md \
  plugins/kenspc/skills/task-review/SKILL.md \
  plugins/kenspc/skills/task-implement/SKILL.md ; do
  grep -qiE 'Planned Dispatch|即将派发' "$f" || { echo "MISSING list: $f"; continue; }
  # No Status column header in the Planned Dispatch table window.
  # (Result tables in Schema A/E still have Status columns; those live in
  #  separate sections — bounded by the awk window cutoff.)
  awk 'BEGIN{p=0} /Planned Dispatch|即将派发/{p=1; print; next} p && /^### Step|^## |^---$/{p=0} p' "$f" \
    | grep -qE '\| *Status *\|' \
    && echo "STATUS COLUMN STILL PRESENT in Planned Dispatch: $f"
done | tee /tmp/ac8.log
test ! -s /tmp/ac8.log
```

### AC9 — Tabulated final reports per schema

Manual review per agent. Confirm:
- 5 review-angle agents — Schema A (HIGH/MED/LOW per angle)
- `code-fixer` — Schema B (accountability table + DEFERRED prose);
  output contract requires `short_label` (≤ 60 chars) per issue (Q5)
- `regression-verifier` — Schema C (verification checks table)
- `task-implementer` — Schema D (per-task table + BLOCKED prose)
- 3 doc-reviewer agents — Schema E (angles × status × changes × commit);
  `task-document-reviewer` adds Plan-Level Concerns prose

```bash
# Cheap text-level sanity that supports the manual review:
grep -q 'short_label' plugins/kenspc/agents/code-fixer.md
# Shared-section invariance across the 5 review-angle agents (project
# CLAUDE.md treats drift between PREREQUISITES, FILE COVERAGE, and CUSTOM
# INSTRUCTIONS as a bug; this script is the mechanical guard).
bash scripts/check-review-agent-drift.sh
# Brief skill must remain review-phase-free (generate-brief produces a
# discovery artifact, not a verifiable spec).
! grep -qiE '## Review|Review Phase|review-phase' plugins/kenspc/skills/generate-brief/SKILL.md
```

### AC10 — README and project CLAUDE.md accurate

Manual review of `plugins/kenspc/README.md`:
- Skills table descriptions reflect v3
- Design Principles section reflects the 5 rules
- English-only output feature claim removed; ULTRATHINK reference removed
- Effort-levels subsection added

Manual review of project root `CLAUDE.md`:
- "Writing Rules for Skill Content" no longer asserts bilingual output
- "Writing Rules for Skill Content" no longer instructs ULTRATHINK
- "Use rationale-anchored business rules (Rule 2)" bullet present

```bash
# Cheap text-level sanity that supports the manual review:
! grep -E '^- Bilingual output' CLAUDE.md
! grep -E '^- Use ULTRATHINK' CLAUDE.md
```

### AC11 — JSON sanity

```bash
cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null
cat plugins/kenspc/hooks/hooks.json | python -m json.tool > /dev/null
cat .claude-plugin/marketplace.json | python -m json.tool > /dev/null
```

## Validation Steps (post-merge)

1. **Local install**: `claude --plugin-dir ./plugins/kenspc` and
   `/reload-plugins`. Confirm all 6 commands list and load.
2. **Smoke test each skill** in a throwaway project:
   - `/kenspc-brief` — confirm Discovery starts; the first user-facing
     prompt is a question (not a draft brief). Per v3.0.2 the
     English-only assertion is retired — language follows session/global
     CLAUDE.md context.
   - `/kenspc-plan <some requirement>` — confirm Phase 1 begins; check
     the Phase 3 dispatch table appears before the agent runs.
   - `/kenspc-task <plan-path>` — confirm decomposition runs; review
     dispatch table appears.
   - `/kenspc-task-implement <task-path>` — confirm Phase 2 review
     dispatches **even if the implementer reports all-DONE** (the bug
     this refactor fixes). Inspect: planned dispatch table appears,
     followed by Schema A → B → C → G report.
   - `/kenspc-task-review` — confirm dispatch table for 5 angles, Schema
     F final report, and that "Code looks correct, skipping review"
     never appears.
   - `/kenspc-guide <project-path>` — confirm guide-document-reviewer
     dispatch table.
3. **Effort verification**: confirm each skill activates at its declared
   effort. Mechanism depends on what the Claude Code TUI exposes at the
   time of release:
   - If the TUI shows per-skill effort (e.g., a status indicator after
     skill activation): inspect each of the 6 skills.
   - Otherwise: read each `SKILL.md` directly (`grep -E '^effort:'
     plugins/kenspc/skills/*/SKILL.md`) and confirm declared values
     match the § Effort Allocation table. The runtime activation is
     guaranteed by the frontmatter being correct.
   `/agents` lists agents (not skills); use it to confirm agent-level
   effort fields if the TUI surfaces them, with the same fallback to
   `grep -E '^effort:' plugins/kenspc/agents/*.md`.
4. **Regression check**: pick one task document from a prior session and
   re-run `/kenspc-task-implement`. Confirm the report shape matches
   Schema G and not the old bullet-list format.

## Rollback

This is a single-shot breaking refactor. If post-merge smoke testing
fails or production reports critical regressions, rollback path:

1. **Soft rollback (preferred)**: revert C12 only. The plugin still self-
   identifies as v2.0.0 (since C12 is the version flip), so users on
   `/plugin update` see no change. The intermediate commits (C1–C11) are
   already merged, but each was scoped to be functionally consistent —
   the v2 surface continues to work, just with v3-style internals.
2. **Hard rollback**: `git revert` C1 through C12 in reverse order on a
   `revert/v3.0` branch, merge back. Use this only if soft rollback
   leaves user-visible breakage.
3. **Targeted patch**: if a single skill or agent regresses (e.g.,
   Risk 3 — `effort: max` on `generate-plan` overthinks), ship a 3.0.1
   patch that downgrades the offending `effort:` value or restores a
   specific deleted scaffolding line. Do **not** restore an entire
   anti-rationalization table; per Anthropic 4.7 guidance the table
   itself is the failure mode.

Each commit C1–C11 is independently green against its scope (see each
commit's DONE-when criteria); C12 is the only commit whose revert is
sufficient to hide v3 from end users.

## Risks and Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| 1 | Removing anti-rationalization tables removes a useful guardrail and the model does drift toward laziness | Low | Medium | Per Anthropic 4.7 doc, "tune anti-laziness prompting ... dial back that guidance" — the tables now produce the failure mode they tried to prevent. If laziness re-emerges in production, add a single qualitative quality-bar line, not a table |
| 2 | Removing bilingual output frustrates Chinese-speaking users who relied on bilingual status messages | Low | Low | Global CLAUDE.md says "Conversation language: match mine" — session-level language control already produces the right output. The bilingual mandate at skill level was redundant and conflicting. CHANGELOG explicitly notes this |
| 3 | `effort: max` on `generate-plan` causes overthinking, bloated drafts, or unnecessary self-challenge rounds | Medium | Medium | Per Anthropic 4.7 doc: "max ... may show diminishing returns ... can also sometimes be prone to overthinking." Validate post-merge by running `/kenspc-plan` against 3 different requirement complexities (small, medium, large). If drafts bloat, downgrade to `xhigh` in a 3.0.1 patch |
| 4 | The 5 review-angle agents drift apart because their shared sections must be kept identical by hand | Medium | Medium | Project CLAUDE.md already names this as a bug class. Mitigations: (a) C7 lands all 5 in one commit; (b) any future change to shared sections requires a 5-file diff in the same PR; (c) consider adding a CI grep that diffs the shared sections (out of scope for v3, candidate for v3.1) |
| 5 | The unconditional-dispatch fix re-triggers reviews that the user explicitly skipped via custom instructions | Low | Low | Custom instructions still flow through CONTEXT — the unconditional rule applies to the orchestrator's *decision to dispatch*, not to the agents' decision on what to report. If a user says "skip the review", the orchestrator still dispatches but the agents return "no findings, user skipped." This is more transparent than silently skipping |
| 6 | Reference docs (`plan-document-example.md`, `task-document-example.md`) become inconsistent with v3 skill output schemas | Low | Low | C0 audit step catches this; if mismatch found, fold into C11 |
| 7 | Project `CLAUDE.md` "Writing Rules for Skill Content" section still asserts bilingual + ULTRATHINK after merge, contradicting the plugin behavior | Medium | Low | C11 explicitly updates project CLAUDE.md; AC10 includes manual review |
| 8 | `effort:` field is rejected by older Claude Code versions, breaking plugin loading | Low | High | Anthropic skill docs list `effort:` as supported. **Action item for C11**: before writing the README Requirements line, the implementer looks up the exact Claude Code version that introduced the `effort:` frontmatter (Claude Code release notes / Anthropic skill docs) and writes the concrete minimum (e.g., "Claude Code v1.0.42+") — placeholder text like "v1.0.X+" is rejected by AC10 review |

## Open Questions

None remaining. All 5 open questions raised during planning are resolved
in § Decisions on Open Questions above.

## References (authoritative — read by implementer before each commit)

1. Anthropic — Prompting best practices for Claude Opus 4.7
   https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
2. Anthropic — Effective context engineering for AI agents
   https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
3. Anthropic — Harness design for long-running application development
   https://www.anthropic.com/engineering/harness-design-long-running-apps
4. Claude Code docs — Skills frontmatter reference
   https://code.claude.com/docs/en/skills#frontmatter-reference
5. Claude Code docs — Subagent frontmatter reference
   https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields
