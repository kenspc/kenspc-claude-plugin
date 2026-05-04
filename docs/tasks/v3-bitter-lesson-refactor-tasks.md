# kenspc Plugin v3.0 Bitter Lesson Refactor — Task Document

## Context

Decomposition of [docs/plans/v3-bitter-lesson-refactor.md](../plans/v3-bitter-lesson-refactor.md)
into 13 fine-grained, independently verifiable tasks. Tasks map 1:1 to the
plan's commit sequence (C0 audit → C12 final version bump). Execute tasks in
order — each task's commit (where applicable) must independently pass the
relevant subset of acceptance criteria, and the final task (Task 13) must
pass all 11.

Related plan: [v3-bitter-lesson-refactor.md](../plans/v3-bitter-lesson-refactor.md)

> Tasks marked with "Depends on" assume prior tasks have been completed.
> Execute tasks in order.

## Tasks

### Task 1: Audit reference docs and marketplace.json (C0)

**Status:** DONE

**Audit findings:**
- `plan-document-example.md`: CLEAN — no bilingual output, no aggressive
  tokens, no Common Rationalizations table, no fake numerical Red Flags,
  no v2 dispatch architecture phrasing.
- `task-document-example.md`: CLEAN — same as above.
- `.claude-plugin/marketplace.json`: no embedded version field; no action
  needed (no fold-in to Task 13).
- Decision: no commit produced; Task 12 scope unchanged; Task 13 scope
  unchanged.

Review-only audit step before any commits. Confirm
[plugins/kenspc/references/plan-document-example.md](../../plugins/kenspc/references/plan-document-example.md)
and
[plugins/kenspc/references/task-document-example.md](../../plugins/kenspc/references/task-document-example.md)
need no narrative changes, and confirm the root
[.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json)
does not require a separate version bump beyond what Task 13 will already do.

For each reference doc, run the C0 checklist and reject (fold into Task 12) if
any of these are present:

- Bilingual output (English + Chinese mixed in the same line)
- Literal `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` tokens
- Numbered EXECUTION FLOW sections
- "Common Rationalizations" tables
- Numerical Red Flags (`~15+`, `more than half`, etc.)
- Phrasing that depends on v2 dispatch architecture (e.g., template-variable
  substitution language)

For `marketplace.json`, check whether it embeds a version field that duplicates
`plugin.json`. If so, fold the bump into Task 13 alongside the `plugin.json`
bump; otherwise no action.

Files: review-only —
[plugins/kenspc/references/plan-document-example.md](../../plugins/kenspc/references/plan-document-example.md),
[plugins/kenspc/references/task-document-example.md](../../plugins/kenspc/references/task-document-example.md),
[.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json).
No commit unless findings need to roll into Task 12.

**Acceptance criteria:**
- Both reference files reviewed against the C0 checklist; clean-vs-dirty
  decision recorded in the task notes below.
- `marketplace.json` reviewed for an embedded version field; decision recorded.
- If clean: no commit produced; proceed to Task 2.
- If dirty: each finding recorded with the file path and the rule it violates;
  Task 12's DONE criteria expanded to include the reference-doc edits, and
  Task 13's scope expanded to include `marketplace.json` if applicable.

---

### Task 2: Update plugin.json description and init CHANGELOG (C1)

**Status:** DONE

**Depends on:** Task 1

Update marketing/metadata description and prepend a v3.0 stub to the existing
CHANGELOG. Modify
[plugins/kenspc/.claude-plugin/plugin.json](../../plugins/kenspc/.claude-plugin/plugin.json)
and
[plugins/kenspc/CHANGELOG.md](../../plugins/kenspc/CHANGELOG.md).

Replace the `description` field in `plugin.json` with the v3 target text from
the plan's § Plugin Metadata Description section (mentions Opus 4.7
xhigh/max alignment and the six design rules). Leave `version` at `2.0.0` —
the version flip is deferred to Task 13.

In `CHANGELOG.md`, prepend a new `## 3.0.0 (unreleased)` section above the
existing `## 2.0.0` section with a bullet list stub of breaking changes (the
list grows in Task 13 as remaining commits land). Preserve the existing
`## 2.0.0` section unchanged.

Files: modify
[plugins/kenspc/.claude-plugin/plugin.json](../../plugins/kenspc/.claude-plugin/plugin.json),
[plugins/kenspc/CHANGELOG.md](../../plugins/kenspc/CHANGELOG.md).

**Acceptance criteria:**
- `plugin.json` `description` field exactly matches the v3 target text (no
  bilingual claim; references Opus 4.7 and the 6 design rules).
- `plugin.json` `version` field still reads `"2.0.0"` after this commit.
- `CHANGELOG.md` has `## 3.0.0 (unreleased)` as the first version heading,
  followed by a bullet stub, followed by the unchanged `## 2.0.0` section.
- `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool`
  exits successfully.
- One commit produced using the plan's commit message format
  (`docs(v3): ...` or `feat(v3): ...`).

---

### Task 3: Clean up shared/discovery-framework.md (C2)

**Status:** TODO

**Depends on:** Task 2

Apply Rule 5 (language) and Rule 6 (bilingual scope check) to
[plugins/kenspc/shared/discovery-framework.md](../../plugins/kenspc/shared/discovery-framework.md).
Examples in the "How to ask" column stay (Q4 decision).

Replace or remove all uppercase `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK`
tokens. Lowercase `ultrathink` is allowed only inside a fenced code block or
blockquote attribution that quotes Anthropic docs verbatim — check each
occurrence by case before keeping. Specifically rephrase the
"Step 1: Assess Input Clarity (ULTRATHINK)" heading and the narrative
"ULTRATHINK to determine ..." prose to effort-implicit language: the calling
skill's `effort:` setting controls reasoning depth.

Preserve the "How to ask" column's Chinese phrasings verbatim (Q4 decision).
The framework's five dimensions, four input clarity levels, conversation
rules, and exit conditions stay intact — diff should be dominated by
language token swaps, not structural rewrites.

Files: modify
[plugins/kenspc/shared/discovery-framework.md](../../plugins/kenspc/shared/discovery-framework.md).

**Acceptance criteria:**
- `grep -nE 'ULTRATHINK|CRITICAL:|^MUST |NEVER ' plugins/kenspc/shared/discovery-framework.md`
  returns zero matches.
- `grep -n '如果交付出来你不满意' plugins/kenspc/shared/discovery-framework.md`
  still returns the Failure Modes example (Chinese phrasings preserved).
- The five dimensions table, the four input clarity levels, the conversation
  rules section, and the exit conditions section are still present after
  the edit (no structural removals).
- `git diff --stat` shows only `plugins/kenspc/shared/discovery-framework.md`
  changed.
- One commit produced (e.g., `refactor(v3): clean discovery-framework`).

---

### Task 4: Refactor 3 simpler SKILL.md — brief / generate-task / generate-guide (C3)

**Status:** TODO

**Depends on:** Task 3

Apply Rules 2/3/4/5/6 plus add `effort:` and bump `version:` to `3.0.0` in
the three skills with the simplest dispatch profiles:
[plugins/kenspc/skills/generate-brief/SKILL.md](../../plugins/kenspc/skills/generate-brief/SKILL.md)
(`effort: xhigh`),
[plugins/kenspc/skills/generate-task/SKILL.md](../../plugins/kenspc/skills/generate-task/SKILL.md)
(`effort: xhigh`),
[plugins/kenspc/skills/generate-guide/SKILL.md](../../plugins/kenspc/skills/generate-guide/SKILL.md)
(`effort: high`).

For each file: add `effort:` to frontmatter at the value from § Effort
Allocation; set `version: 3.0.0`; remove the "Common Rationalizations" table;
rewrite "Red Flags" qualitatively or remove it; convert EXECUTION FLOW /
numbered Phase Steps into Goal + Inputs + DONE + Constraints (Rule 3); clean
all `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` tokens (Rule 5); reduce all
bilingual output strings to English only (Rule 6); rewrite command-style
business rules as rationale-anchored "Why:" framing (Rule 2).

`generate-guide` adds Dispatch Status Tables (Point 1 single-row + Point 3
Schema E) for the `guide-document-reviewer` dispatch.

`generate-task` adds Dispatch Status Tables (Point 1 single-row + Point 3
Schema E) for the `task-document-reviewer` dispatch.

`generate-brief` adds **no** dispatch tables — it has no review phase. It
must not gain a review phase (per project CLAUDE.md and § Objective).

Files: modify
[plugins/kenspc/skills/generate-brief/SKILL.md](../../plugins/kenspc/skills/generate-brief/SKILL.md),
[plugins/kenspc/skills/generate-task/SKILL.md](../../plugins/kenspc/skills/generate-task/SKILL.md),
[plugins/kenspc/skills/generate-guide/SKILL.md](../../plugins/kenspc/skills/generate-guide/SKILL.md).

**Acceptance criteria:**
- All 3 files contain `^effort:` in their frontmatter at the assigned value
  (`xhigh`, `xhigh`, `high` respectively).
- All 3 files have `version: 3.0.0` in frontmatter.
- `grep -n "Common Rationalizations" <each file>` returns zero matches.
- `grep -nE 'ULTRATHINK|CRITICAL:|^MUST |NEVER ' <each file>` returns zero
  matches.
- `grep -nE '/ 中|/ 华|中 /|华 /' <each file>` returns zero matches.
- `generate-guide/SKILL.md` and `generate-task/SKILL.md` each contain a
  "Planned Dispatch" or "Dispatch Status" table with at least one row marked
  `pending`.
- `generate-brief/SKILL.md` contains no dispatch table and no review-phase
  section (review surface unchanged from current behavior).
- One commit produced touching exactly these 3 files.

---

### Task 5: Refactor generate-plan SKILL.md (C4)

**Status:** TODO

**Depends on:** Task 4

Apply all rules from Task 4 plus add `effort: max` plus add Dispatch Status
Tables for the `plan-document-reviewer` dispatch in
[plugins/kenspc/skills/generate-plan/SKILL.md](../../plugins/kenspc/skills/generate-plan/SKILL.md).
Reframe Phase 2's self-challenge step as a goal, not a numbered step list.

Add a Risk-3 acknowledgement bullet under the v3.0 CHANGELOG entry's "Notes"
subsection (the bullet is added here in
[plugins/kenspc/CHANGELOG.md](../../plugins/kenspc/CHANGELOG.md); the entry
itself is finalized in Task 13). Example wording: "generate-plan ships at
effort: max; if drafts bloat under real workloads, downgrade to xhigh in
3.0.1."

Phase 2 self-challenge reframed: instead of numbered substeps, it has a Goal
("expose the weakest assumption in the draft"), DONE criteria ("draft
accepted by user OR revised draft addresses every challenge"), and
Constraints ("no fix without rationale").

Phase 3 Dispatch Status Tables: Point 1 single-row "pending" before dispatch;
Point 3 Schema E (review angles + status + changes + commit).

Phase 1's brief-detection logic (recognizing files authored by `generate-brief`
and gap-checking against the five discovery-framework dimensions) is preserved
verbatim. Rule 3 applies to step prescriptions, not to functional logic — the
brief-detection branch and the gap-check exit criteria stay; only the
surrounding prose framing changes.

Files: modify
[plugins/kenspc/skills/generate-plan/SKILL.md](../../plugins/kenspc/skills/generate-plan/SKILL.md),
[plugins/kenspc/CHANGELOG.md](../../plugins/kenspc/CHANGELOG.md).

**Acceptance criteria:**
- `effort: max` is present in frontmatter; `version: 3.0.0` is set.
- All Task 4 cleanup criteria (no Common Rationalizations, no aggressive
  tokens, no bilingual strings, EXECUTION FLOW converted) hold for this file.
- Phase 2 self-challenge has explicit Goal, DONE, Constraints subsections;
  no numbered substep list remains in that phase.
- Phase 3 contains a Planned Dispatch table (1 row, `pending`) and a Schema E
  result table.
- Phase 1's brief-detection branch is still present (search for `Detect Brief`
  or equivalent heading) and its gap-check exit criteria are unchanged.
- `CHANGELOG.md`'s `## 3.0.0 (unreleased)` section now contains a Notes
  subsection with the Risk-3 acknowledgement bullet.
- One commit produced touching `generate-plan/SKILL.md` and `CHANGELOG.md`.

---

### Task 6: Refactor task-review SKILL.md with unconditional dispatch (C5)

**Status:** TODO

**Depends on:** Task 5

Apply all Task 4 cleanup rules plus add `effort: xhigh` plus add Dispatch
Status Tables (5 angles) plus rewrite the Step 3 dispatch instruction to the
rationale-anchored unconditional form in
[plugins/kenspc/skills/task-review/SKILL.md](../../plugins/kenspc/skills/task-review/SKILL.md).

The Step 3 dispatch language must be exactly the § Canonical Unconditional
Dispatch Paragraph from the plan, pasted byte-for-byte (do not paraphrase).
The pasted block is the prose paragraph beginning with the heading
"## Code Review Phase (unconditional)" and ending with "...not to pre-filter
findings." It uses plain rationale prose — no `MUST` / `NEVER` introduced.
Save the canonical paragraph verbatim because Task 7 will paste the same
bytes into `task-implement/SKILL.md` and Task 13's AC7 diff requires
byte-identity.

No narrative "Then follow Steps X-Y" form for review dispatch may remain in
this file.

Dispatch Status Tables: Point 1 (5-row pending) before the parallel review
agents run; Point 3 Schema A (HIGH/MED/LOW per angle) → Schema B (code-fixer
accountability) → Schema C (regression verification) → Schema F (final
consolidated report).

Files: modify
[plugins/kenspc/skills/task-review/SKILL.md](../../plugins/kenspc/skills/task-review/SKILL.md).

**Acceptance criteria:**
- `effort: xhigh` is present in frontmatter; `version: 3.0.0` is set.
- All Task 4 cleanup criteria hold for this file.
- `grep -n 'Code Review Phase (unconditional)' plugins/kenspc/skills/task-review/SKILL.md`
  returns one match.
- `grep -n 'unconditional' plugins/kenspc/skills/task-review/SKILL.md`
  returns at least one match.
- `grep -nE 'Then follow .* Step' plugins/kenspc/skills/task-review/SKILL.md`
  returns zero matches.
- `grep -nE '^MUST |NEVER ' plugins/kenspc/skills/task-review/SKILL.md`
  returns zero matches (Rule 5 holds for the new content too).
- A 5-row Planned Dispatch table with `pending` rows for the 5 review
  angles is present.
- Schema A, B, C, F result-table sections are present in Step 6 / final
  report area.
- One commit produced touching only this file.

---

### Task 7: Refactor task-implement SKILL.md with unconditional dispatch (C6)

**Status:** TODO

**Depends on:** Task 6

Same shape as Task 6 but for the auto-triggered review at the end of
task-implement Phase 2, in
[plugins/kenspc/skills/task-implement/SKILL.md](../../plugins/kenspc/skills/task-implement/SKILL.md).

Phase 2 dispatch instruction uses the same canonical unconditional language
as Task 6 — paste the byte-identical paragraph captured in Task 6 (do not
re-author from the plan). Future edits stay aligned through this byte
identity.

Dispatch Status Tables present (Planned + Result). Final consolidated report
uses Schema G (Implementation D + Review A + Fixes B + Verification C +
Verdict + Next Steps). All-blocked path documented: if every task in
Schema D is BLOCKED, omit Code Review / Fixes / Verification sections; verdict
= BLOCKED.

After saving, run the AC7 diff to verify byte-identity with task-review:

```bash
diff <(grep -A 20 'Code Review Phase (unconditional)' plugins/kenspc/skills/task-review/SKILL.md | head -25) \
     <(grep -A 20 'Code Review Phase (unconditional)' plugins/kenspc/skills/task-implement/SKILL.md | head -25)
```

If the diff is non-empty, fix the drift before this commit lands.

Files: modify
[plugins/kenspc/skills/task-implement/SKILL.md](../../plugins/kenspc/skills/task-implement/SKILL.md).

**Acceptance criteria:**
- `effort: xhigh` is present in frontmatter; `version: 3.0.0` is set.
- All Task 4 cleanup criteria hold for this file.
- `grep -n 'unconditional' plugins/kenspc/skills/task-implement/SKILL.md`
  returns at least one match.
- `grep -nE 'Then follow .* Step' plugins/kenspc/skills/task-implement/SKILL.md`
  returns zero matches.
- The diff command above (Canonical paragraph block in task-review vs
  task-implement) returns empty (zero exit code).
- Dispatch Status Tables (Planned + Result) are present.
- Schema G final report section is present and explicitly documents the
  all-blocked omission path (verdict = BLOCKED, sections omitted).
- One commit produced touching only this file.

---

### Task 8: Refactor 5 review-angle agents — atomic (C7)

**Status:** TODO

**Depends on:** Task 7

Apply Rules 5/6 plus add `effort: xhigh` plus replace the existing summary
template with Schema A plus adopt the Anthropic code-review-harness coverage
prompt in **all 5** review-angle agents in **one atomic commit**:
[plugins/kenspc/agents/requirements-reviewer.md](../../plugins/kenspc/agents/requirements-reviewer.md),
[plugins/kenspc/agents/edge-case-reviewer.md](../../plugins/kenspc/agents/edge-case-reviewer.md),
[plugins/kenspc/agents/quality-reviewer.md](../../plugins/kenspc/agents/quality-reviewer.md),
[plugins/kenspc/agents/bug-reviewer.md](../../plugins/kenspc/agents/bug-reviewer.md),
[plugins/kenspc/agents/test-reviewer.md](../../plugins/kenspc/agents/test-reviewer.md).

This commit must change all 5 agents together. Splitting into 5 commits
creates drift windows; project CLAUDE.md treats drift between these 5 as a
bug.

For each agent: preserve every existing frontmatter field (`name`,
`description`, `tools`, `model`); do not reorder or rename them; insert
`effort: xhigh` after `model:` to keep the diff minimal.

All 5 agents share identical PREREQUISITES, FILE COVERAGE, and CUSTOM
INSTRUCTIONS sections (per project CLAUDE.md maintenance note). Apply the
same edits to all 5 simultaneously.

Each agent's COMPLETION summary template matches Schema A: returns
HIGH/MEDIUM/LOW counts plus a per-issue list with file:line, severity,
confidence, and a one-line description. Each agent's CUSTOM INSTRUCTIONS
section includes coverage-mode language derived from Anthropic's code-review
prompt: "Report every issue you find, including ones you are uncertain about
or consider low-severity. Do not filter for importance or confidence at this
stage — the code-fixer and regression-verifier handle filtering. Your goal
here is coverage."

Files: modify
[plugins/kenspc/agents/requirements-reviewer.md](../../plugins/kenspc/agents/requirements-reviewer.md),
[plugins/kenspc/agents/edge-case-reviewer.md](../../plugins/kenspc/agents/edge-case-reviewer.md),
[plugins/kenspc/agents/quality-reviewer.md](../../plugins/kenspc/agents/quality-reviewer.md),
[plugins/kenspc/agents/bug-reviewer.md](../../plugins/kenspc/agents/bug-reviewer.md),
[plugins/kenspc/agents/test-reviewer.md](../../plugins/kenspc/agents/test-reviewer.md).

**Acceptance criteria:**
- `for f in plugins/kenspc/agents/{requirements,edge-case,quality,bug,test}-reviewer.md; do grep -q '^effort: xhigh' "$f" || echo "MISS: $f"; done`
  reports no misses.
- All 5 frontmatter blocks preserve `name`, `description`, `tools`, `model`
  with `effort:` appended after `model:` (no reordering).
- All 5 files share identical PREREQUISITES, FILE COVERAGE, and CUSTOM
  INSTRUCTIONS section bodies (verify by inspection or `diff` of those
  blocks).
- Each agent's COMPLETION section produces a Schema A table (HIGH/MEDIUM/LOW
  count table + per-issue table with file:line / severity / confidence /
  description columns).
- Each agent's CUSTOM INSTRUCTIONS contains the literal phrase "Your goal
  here is coverage" (or equivalent coverage-mode wording).
- `grep -nE 'ULTRATHINK|CRITICAL:|^MUST |NEVER ' <each file>` returns zero
  matches.
- `grep -nE '/ 中|/ 华|中 /|华 /' <each file>` returns zero matches.
- One single commit touches exactly these 5 files.

---

### Task 9: Refactor 3 worker agents — code-fixer / regression-verifier / task-implementer (C8)

**Status:** TODO

**Depends on:** Task 8

Apply Rules 5/6 plus add `effort:` plus adopt Schemas B/C/D summary
templates. Add the `short_label` output contract to `code-fixer` (Q5
resolution).

For [plugins/kenspc/agents/code-fixer.md](../../plugins/kenspc/agents/code-fixer.md):
set `effort: xhigh`; the per-issue output contract requires `short_label`
(≤ 60 chars) alongside existing detail fields; summary uses Schema B
(table + DEFERRED prose).

For [plugins/kenspc/agents/regression-verifier.md](../../plugins/kenspc/agents/regression-verifier.md):
set `effort: high`; summary uses Schema C (verification table with
PASS/FAIL); detail prose for non-PASS rows.

For [plugins/kenspc/agents/task-implementer.md](../../plugins/kenspc/agents/task-implementer.md):
set `effort: xhigh`; summary uses Schema D (per-task table + BLOCKED /
Decisions / Post-implementation prose).

Apply Rules 5/6 in all 3 files: clean aggressive tokens; strip bilingual
output. Preserve every existing frontmatter field; insert `effort:` after
`model:`.

Files: modify
[plugins/kenspc/agents/code-fixer.md](../../plugins/kenspc/agents/code-fixer.md),
[plugins/kenspc/agents/regression-verifier.md](../../plugins/kenspc/agents/regression-verifier.md),
[plugins/kenspc/agents/task-implementer.md](../../plugins/kenspc/agents/task-implementer.md).

**Acceptance criteria:**
- `code-fixer.md` frontmatter contains `effort: xhigh`; the agent body
  defines `short_label` as a required per-issue field with a
  ≤ 60-character constraint, and `grep -n 'short_label'
  plugins/kenspc/agents/code-fixer.md` returns at least one match.
- `code-fixer.md` COMPLETION matches Schema B (Fixes Applied table with
  `# / short_label / Severity / File:Line / Action / Commit` columns plus
  Deferred Issues prose section).
- `regression-verifier.md` frontmatter contains `effort: high`; COMPLETION
  matches Schema C (Verification table with `# / Check / Result / Detail`
  columns plus per-non-PASS detail prose).
- `task-implementer.md` frontmatter contains `effort: xhigh`; COMPLETION
  matches Schema D (per-task table plus BLOCKED / Decisions /
  Post-implementation prose sections).
- Frontmatter ordering preserved in all 3 files; `effort:` appears after
  `model:`.
- `grep -nE 'ULTRATHINK|CRITICAL:|^MUST |NEVER ' <each file>` returns zero
  matches.
- `grep -nE '/ 中|/ 华|中 /|华 /' <each file>` returns zero matches.
- One commit produced touching these 3 files.

---

### Task 10: Refactor 3 doc-reviewer agents — plan / guide / task (C9)

**Status:** TODO

**Depends on:** Task 9

Apply Rules 5/6 plus add `effort: high` plus adopt Schema E summary template
in:
[plugins/kenspc/agents/plan-document-reviewer.md](../../plugins/kenspc/agents/plan-document-reviewer.md),
[plugins/kenspc/agents/guide-document-reviewer.md](../../plugins/kenspc/agents/guide-document-reviewer.md),
[plugins/kenspc/agents/task-document-reviewer.md](../../plugins/kenspc/agents/task-document-reviewer.md).

`task-document-reviewer` adds a clearly-labeled "## Plan-Level Concerns"
prose section beneath the Schema E table for upstream-plan issues that
don't belong in the task doc itself.

Preserve every existing frontmatter field in all 3 files; insert `effort:`
after `model:`.

Files: modify
[plugins/kenspc/agents/plan-document-reviewer.md](../../plugins/kenspc/agents/plan-document-reviewer.md),
[plugins/kenspc/agents/guide-document-reviewer.md](../../plugins/kenspc/agents/guide-document-reviewer.md),
[plugins/kenspc/agents/task-document-reviewer.md](../../plugins/kenspc/agents/task-document-reviewer.md).

**Acceptance criteria:**
- All 3 files contain `^effort: high` in frontmatter.
- All 3 files' COMPLETION sections match Schema E (Review table with
  `Angle / Status / Changes / Commit` columns plus per-row Changes prose).
- `task-document-reviewer.md` contains a `## Plan-Level Concerns` heading
  beneath the Schema E table.
- Frontmatter ordering preserved in all 3 files; `effort:` appears after
  `model:`.
- `grep -nE 'ULTRATHINK|CRITICAL:|^MUST |NEVER ' <each file>` returns zero
  matches.
- `grep -nE '/ 中|/ 华|中 /|华 /' <each file>` returns zero matches.
- One commit produced touching these 3 files.

---

### Task 11: Update commands and hooks (C10)

**Status:** TODO

**Depends on:** Task 10

Apply Rules 5/6 to the thin command files and the two hook scripts. These
edits are minimal — the command files are short shells that delegate to
SKILL.md.

Files:
[plugins/kenspc/commands/kenspc-brief.md](../../plugins/kenspc/commands/kenspc-brief.md),
[plugins/kenspc/commands/kenspc-plan.md](../../plugins/kenspc/commands/kenspc-plan.md),
[plugins/kenspc/commands/kenspc-task.md](../../plugins/kenspc/commands/kenspc-task.md),
[plugins/kenspc/commands/kenspc-task-implement.md](../../plugins/kenspc/commands/kenspc-task-implement.md),
[plugins/kenspc/commands/kenspc-task-review.md](../../plugins/kenspc/commands/kenspc-task-review.md),
[plugins/kenspc/commands/kenspc-guide.md](../../plugins/kenspc/commands/kenspc-guide.md),
[plugins/kenspc/hooks/scripts/check-deps.sh](../../plugins/kenspc/hooks/scripts/check-deps.sh),
[plugins/kenspc/hooks/scripts/remind-plan-skill.sh](../../plugins/kenspc/hooks/scripts/remind-plan-skill.sh).

For each command `.md`: remove any `MUST`/`NEVER`/`CRITICAL`/`ULTRATHINK`
tokens; strip bilingual output if present.

For `check-deps.sh`: review user-facing message strings (currently empty
warnings); if any are added during this refactor, make them English-only and
rationale-anchored.

For `remind-plan-skill.sh`: rewrite the four `MSG` heredoc reminder strings
to remove any aggressive tokens and convert to English-only rationale-anchored
phrasing.

**Acceptance criteria:**
- `grep -rnE 'ULTRATHINK|CRITICAL:|^MUST |NEVER ' plugins/kenspc/commands plugins/kenspc/hooks`
  returns zero matches.
- `grep -rnE '/ 中|/ 华|中 /|华 /' plugins/kenspc/commands plugins/kenspc/hooks`
  returns zero matches.
- `cat plugins/kenspc/hooks/hooks.json | python -m json.tool` exits
  successfully.
- The four reminder messages in `remind-plan-skill.sh` are English-only
  and reference the corresponding skill by name with a one-line rationale.
- One commit produced touching these 8 files.

---

### Task 12: Update README.md and project CLAUDE.md (C11)

**Status:** TODO

**Depends on:** Task 11

Surface the v3 design in user-facing documentation. This task must land
**before** Task 13's version bump so the README never describes v2 behavior
on a v3 plugin.

For [plugins/kenspc/README.md](../../plugins/kenspc/README.md):

- Skills table descriptions reflect v3 behavior (no "ULTRATHINK" references;
  remove bilingual claims).
- Design Principles section: replace the existing list with a distillation
  of the 6 rules (Workflow SOP / Why-not-Command / DONE-criteria /
  No-anti-rationalization / Plain-language / English-only output) and
  reference the v3 plan document
  ([docs/plans/v3-bitter-lesson-refactor.md](../plans/v3-bitter-lesson-refactor.md))
  as the authoritative spec.
- "Bilingual output" bullet removed from Design Principles.
- "ULTRATHINK" reference under "Recommended" requirements removed or
  rephrased (effort-based reasoning is now the mechanism).
- Add a brief "Effort levels" subsection pointing users to the `effort:`
  frontmatter and the relevant Anthropic skill / subagent docs. The
  Requirements section's minimum Claude Code version line must be a
  concrete version (e.g., "Claude Code v1.0.42+"); placeholder text like
  "v1.0.X+" is rejected. The implementer looks up the exact Claude Code
  version that introduced the `effort:` frontmatter from Claude Code release
  notes / Anthropic skill docs before writing this line.

For [CLAUDE.md](../../CLAUDE.md) (project root):

- "Writing Rules for Skill Content" section: remove the bilingual bullet,
  remove the "Use ULTRATHINK before major analysis" bullet, add a "Use
  rationale-anchored business rules (Rule 2)" bullet and an "Output in
  English only" bullet.
- "Subagent Review Architecture" section: confirm still accurate; add a
  note that all SKILLs and agents now declare `effort:`.

If Task 1's audit found reference-doc issues, fold those edits into this
commit (per Task 1's contingent expansion of Task 12's scope).

Files: modify
[plugins/kenspc/README.md](../../plugins/kenspc/README.md),
[CLAUDE.md](../../CLAUDE.md), plus any reference docs from Task 1.

**Acceptance criteria:**
- `grep -nE 'ULTRATHINK' plugins/kenspc/README.md` returns zero matches.
- `grep -n 'Bilingual output' plugins/kenspc/README.md` returns zero matches.
- README contains an "Effort levels" subsection that mentions the `effort:`
  frontmatter and links to or names the Anthropic skill / subagent docs.
- README's Requirements section names a concrete Claude Code minimum version
  (matches `Claude Code v[0-9]+\.[0-9]+\.[0-9]+\+`); no `v1.0.X+` placeholder
  remains.
- README Design Principles section enumerates the 6 rules (Workflow SOP /
  Why-not-Command / DONE-criteria / No-anti-rationalization /
  Plain-language / English-only output) and references the v3 plan path.
- `! grep -E '^- Bilingual output' CLAUDE.md` succeeds.
- `! grep -E '^- Use ULTRATHINK' CLAUDE.md` succeeds.
- CLAUDE.md "Writing Rules for Skill Content" contains a Rule 2
  rationale-anchored bullet and an "Output in English only" bullet.
- CLAUDE.md "Subagent Review Architecture" contains a note that SKILLs and
  agents now declare `effort:`.
- If Task 1 found reference-doc issues, those reference docs are also
  modified in this commit (verify against Task 1's recorded findings).
- One commit produced.

---

### Task 13: Bump plugin version and finalize CHANGELOG (C12)

**Status:** TODO

**Depends on:** Task 12

Final commit. Flip the version marker to 3.0.0 and finalize the v3.0
CHANGELOG entry with the complete breaking-change list.

For [plugins/kenspc/.claude-plugin/plugin.json](../../plugins/kenspc/.claude-plugin/plugin.json):
change `version` to `"3.0.0"`. If Task 1 flagged a duplicate version field
in [.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json),
update that file in the same commit.

For [plugins/kenspc/CHANGELOG.md](../../plugins/kenspc/CHANGELOG.md):
remove "(unreleased)" from the `## 3.0.0` heading; fill in the release date;
expand the bullet list to cover all breaking changes from C1 through C11:

- Removed: anti-rationalization tables, bilingual output, fake numerical
  Red Flags, `ULTRATHINK` directives, aggressive `MUST`/`NEVER`/`CRITICAL`
  language.
- Added: `effort:` frontmatter on every SKILL/agent; Dispatch Status
  Tables; tabulated final reports per Schemas A–G; unconditional review
  dispatch.
- Changed: EXECUTION FLOW → DONE-criteria; Business Rules rewritten as
  WHY-not-COMMAND.

After staging, run all 11 acceptance criteria from the plan's § Acceptance
Criteria section. Every one must pass before the commit lands.

Files: modify
[plugins/kenspc/.claude-plugin/plugin.json](../../plugins/kenspc/.claude-plugin/plugin.json),
[plugins/kenspc/CHANGELOG.md](../../plugins/kenspc/CHANGELOG.md), plus
[.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json) if
Task 1 flagged it.

**Acceptance criteria:**
- `grep -q '"version": "3.0.0"' plugins/kenspc/.claude-plugin/plugin.json`
  succeeds.
- `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool` and
  `cat plugins/kenspc/hooks/hooks.json | python -m json.tool` both succeed
  (AC11).
- `CHANGELOG.md` `## 3.0.0` heading no longer contains "(unreleased)" and
  has a YYYY-MM-DD release date filled in.
- CHANGELOG `## 3.0.0` contains Removed / Added / Changed sections covering
  the bullets listed above.
- All 11 acceptance criteria from the plan's § Acceptance Criteria section
  pass when run from the repo root: AC1 (frontmatter completeness — all
  SKILL.md and agent .md have `effort:`), AC2 (plugin version + description +
  CHANGELOG), AC3 (no Common Rationalizations), AC4 (no fake numerical
  thresholds), AC5 (no aggressive language), AC6 (no bilingual output —
  excluding `discovery-framework.md` and CHANGELOG), AC7 (unconditional
  dispatch verified — both files contain `unconditional`, no
  "Then follow Steps" pattern, canonical paragraph diff is empty), AC8
  (Dispatch Status Tables present in all 5 dispatching skills), AC9
  (tabulated final reports per schema; manual review plus
  `grep -q 'short_label' plugins/kenspc/agents/code-fixer.md`), AC10 (README
  + CLAUDE.md accurate), AC11 (JSON sanity).
- If Task 1 flagged `marketplace.json`: it is updated in this commit.
- One commit produced (e.g., `chore(v3): bump version to 3.0.0`).

---

## Notes

- Each commit (Tasks 2–13) must independently pass the relevant subset of
  the plan's AC1–AC11 acceptance criteria; Task 13 must pass all 11 (per
  the plan's § Implementation Sequence).
- Tasks 6 and 7 share a canonical paragraph that must be byte-identical
  between `task-review/SKILL.md` and `task-implement/SKILL.md`. The diff
  command in Task 7's body is the in-task verification; AC7 reruns it
  post-merge in Task 13.
- Task 8 must remain atomic — splitting the 5-agent change into multiple
  commits creates drift windows that the project CLAUDE.md treats as a bug.
- Rollback: per the plan's § Rollback section, soft rollback = revert
  Task 13 only. Tasks 2–12 are scoped to be functionally consistent on
  their own (the plugin still self-identifies as v2 because the version
  flip is deferred to Task 13).
