# Batch A — Doc-sync Task, Decision Promotion, CLAUDE.md Consistency — Task Document

## Context

Implement batch A of the kenspc plugin on top of v3.5.1: plans gain a
Documentation impact element, `generate-task` appends a Doc-sync task from it,
`task-implementer` gains a dependency gate and decision-promotion rules and
reports `## Decisions needing a home`, and `task-document-reviewer` gains
Doc-sync coverage in Angle 1 and a third angle, Consistency with CLAUDE.md.
One new anchor-presence guard protects the new fixed strings.

Related plan: `docs/plans/batch-a-doc-sync.md`. The plan is the complete
specification: its Design decisions (M1–M9, D1–D6) are binding rulings, and
its Fixed strings table gives the exact spelling of every load-bearing anchor
(`## Documentation impact`, `N/A — <reason>`, `### Task N: Doc-sync`,
`Depends on: Task 1-<N-1>` with an ASCII hyphen, `## Decisions needing a home`,
`depends on Task N (<status>)`). Each task below cites its plan Step, which is
the canonical source for what to write; the criteria listed here are the local
DONE bar.

This is plugin revision work: the files are Markdown (SKILL.md, agent .md,
references, README, CLAUDE.md, CHANGELOG, docs) and one shell script. No
application code is written. "Build / test / lint" for each task is the
repository's guard suite: after each file edit run the matching guard named in
the task, then `bash scripts/check-all.sh`, which must exit 0 (`guards run: 9`
until Task 11 adds the tenth guard, `guards run: 10` from then on).

Constraints that apply to every task:

- No edit inside any byte-identity section: the `canonical:run-dir`,
  `canonical:dispatch`, `canonical:stats-line`, and `canonical:verdict-shared`
  blocks, the five reviewers' shared sections, and the code-craft canonical
  paragraphs with the `CODE-CRAFT PRINCIPLES` header and its guard comment.
  `check-canonical-dispatch.sh`, `check-verdict-shared.sh`,
  `check-run-contract.sh`, `check-code-craft-canonical.sh`,
  `check-review-agent-drift.sh`, `check-quality-reviewer-bullet-structure.sh`,
  and `check-notes-format-sync.sh` stay green without modification.
- `effort:` frontmatter and the per-skill `version: 3.0.0` are unchanged in
  every file; `plugin.json` and `marketplace.json` are not touched (no version
  bump in this batch).
- New checks are written in rubric form: one sentence stating what passing
  looks like, then named failure modes. Rules are rationale-anchored ("Why: …"
  prose); no `MUST` / `NEVER` / `CRITICAL`, no inline effort tokens, no model
  names (`check-no-model-names.sh`).
- No new CONTEXT keys.
- Code, comments, commit messages, and documents are in English. Each task is
  one conventional commit (`feat(skills): …`, `feat(agents): …`,
  `docs(references): …`, and so on, matching the repository's history) that
  stages only the files the task lists, together with the task's status
  update.

Dependency note: Tasks 1–10 (plan Phases 1–4) are independent of each other
except where a task says otherwise — Tasks 5 and 6 need the Doc-sync template
from Task 4, and Task 8 renders the Schema D section Task 7 defines. Task 11
(the guard) cannot start until Tasks 1–10 are DONE: its anchors must exist and
the plan states Phase 5 needs Phases 1–4. Tasks 12–15 (plan Phase 6) document
the finished behaviour and cannot start until the tasks they describe are DONE
(Task 13 needs Tasks 1–10; Tasks 12, 14, and 15 also need Task 11, whose guard
name and counts they record). Task 16, the Doc-sync task, runs last and needs
Tasks 1–15: it reconciles the documents with what those tasks implemented and
promotes their recorded decisions.

## Tasks

### Task 1: Add the Documentation impact element to generate-plan

**Status:** DONE

**Implementation notes:**
- Decisions: the M2 determination basis is written once, inside the
  Documentation impact bullet in Phase 2 Step 1; the Phase 1 Step 2 bullet
  points to it instead of repeating it, so the two cannot drift. The Why for
  the always-present exception follows the "include only what applies"
  sentence as a separate `Why:` sentence rather than inside the parenthesis,
  matching the skill's rationale-anchored prose.
- Changes/tradeoffs: the bullet also names the section heading form
  (`## Documentation impact`) and places `N/A — <reason>` as the section's
  body. The task text only asked for the element, but the plan's Fixed strings
  table makes that heading load-bearing for plan documents (the release
  checklist greps for it and generate-task reads it), and generate-plan is the
  file that produces plan documents.

Plan Step 1.1 (rulings M1, M2). In Phase 2 Step 1's element list, add
`**Documentation impact**` directly after the Implementation Steps bullet as
the one element that is always present: it lists the durable documents the
plan's steps make stale — per document the path, the section where known,
what must change, and the step that causes it — or the single line
`N/A — <reason>`. State the determination basis: the durable documents the
project's CLAUDE.md names — a documentation table where one exists, otherwise
the documents it names in prose; when it names none, README.md and CLAUDE.md
themselves. In Phase 1 Step 2 (read project context), note those documents as
input for the element. Amend the "(include only what applies)" sentence so it
excludes this element, with the Why: the task-document reviewer's Doc-sync
check reads the element, and an absent element is indistinguishable from a
forgotten one.

**Files to modify:**
- `plugins/kenspc/skills/generate-plan/SKILL.md`

**Acceptance criteria:**
- The Phase 2 Step 1 list contains a `**Documentation impact**` bullet with the
  per-document fields (path, section, what changes, causing step), the
  `N/A — <reason>` form spelled with an em dash, and the M2 determination basis.
- The "include only what applies" sentence names Documentation impact as the
  exception and carries the Why above.
- Phase 1 Step 2 names the CLAUDE.md-listed documents as input for the element.
- `git diff` shows no change to any other element's wording or to the
  frontmatter (`effort: xhigh`, `version: 3.0.0`).
- `bash scripts/check-all.sh` exits 0.

---

### Task 2: Show Documentation impact in the plan example

**Status:** DONE

**Implementation notes:**
- Decisions: two entries, the two the task names (README § API for Steps
  2.1–2.3, `docs/architecture.md` for Step 1.2), rather than a third invented
  one; each entry also names a section, showing the "section where known"
  field generate-plan asks for.
- Changes/tradeoffs: a one-line lead-in states the determination basis (the
  example project's CLAUDE.md documentation table), mirroring the M2 rule so a
  reader copying the example sees where the list comes from. The example has
  no CLAUDE.md of its own, so that table is implied, not shown.

Plan Step 1.2. Add a `## Documentation impact` section between the last
Implementation Step (Step 3.2) and `## Testing Strategy`, with two or three
entries that fit the notification example — for instance the README's API
section for the Phase 2 endpoints (Steps 2.1–2.3) and an architecture document
for the Socket.IO + Redis adapter (Step 1.2). Each entry names the path, what
changes, and the causing step.

**Files to modify:**
- `plugins/kenspc/references/plan-document-example.md`

**Acceptance criteria:**
- `grep -n '^## ' plugins/kenspc/references/plan-document-example.md` lists
  `## Documentation impact` exactly once, after `## Implementation Steps` and
  immediately before `## Testing Strategy`.
- The section has two or three entries; each names a path, what changes, and a
  step number that exists in the example.
- No other line of the file changed.
- `bash scripts/check-all.sh` exits 0.

---

### Task 3: Check Documentation impact in plan-document-reviewer Angle 2

**Status:** DONE

**Implementation notes:**
- Decisions: the four failure modes keep the plan's wording verbatim, so the
  "exactly these four" bar is checkable against Step 1.3 line by line. The
  bullet names the M2 fallback (README.md and CLAUDE.md when CLAUDE.md names
  no durable document) so the reviewer judges "missing" and "padding" on the
  same basis generate-plan used to write the element.
- Changes/tradeoffs: the bullet closes with a one-sentence Why (generate-task
  builds the Doc-sync task from this element), per the rationale-anchored
  rule; it is not a failure mode.

Plan Step 1.3. Add one rubric bullet to Angle 2 Completeness. Passing
statement: Documentation impact names every durable document whose content the
plan's steps make stale, and nothing else, or states N/A with a reason the
steps do not contradict. Named failure modes: (1) the element is absent;
(2) N/A without a reason, or with a reason the steps contradict (a step edits
README while the element says N/A); (3) a document the steps themselves modify
is missing; (4) a listed document that no step changes anything it describes
(padding). State that these are objective issues under the existing FIXING
RULES: the reviewer derives the list from the steps and the documents
CLAUDE.md names, fixes the plan, and commits; when it cannot determine an
entry it records the gap under Open Questions and marks it NOTED, per STUCK
HANDLING.

**Files to modify:**
- `plugins/kenspc/agents/plan-document-reviewer.md`

**Acceptance criteria:**
- Angle 2 contains the new bullet: one passing sentence followed by exactly the
  four numbered failure modes above, plus the fix / Open Questions handling.
- The Angle 2 heading, its five existing bullets, the other angles, FIXING
  RULES, and STUCK HANDLING are unchanged in `git diff`.
- The description still starts with `INTERNAL:`; frontmatter unchanged.
- `bash scripts/check-all.sh` exits 0.

---

### Task 4: Generate the Doc-sync task in generate-task

**Status:** DONE

**Implementation notes:**
- Decisions: the M3 statement, the fixed-heading rule (D1), the C1 overlap
  rule, and the template sit in a new `### Doc-sync Task` subsection of
  Phase 1, next to the sizing table, so Phase 1 DONE and Phase 2 DONE point
  to one place. The C1 rule reads "verifies instead of editing it again" as
  "does not redo the planned edit": the Doc-sync task still corrects a
  statement the implementation contradicts and writes promoted decisions into
  that document, since otherwise its first acceptance criterion and its
  promotion instruction could not be met for such a document. The dependency
  rule names the three `Depends on` forms (single, ASCII-hyphen range,
  comma-separated list) so the producer and `task-implementer`'s gate
  (Task 7) read the same syntax.
- Changes/tradeoffs: the dependency rule carries a Why that cites
  `task-implementer`'s gate, which Task 7 adds in this batch. The template's
  third criterion adds "(this task document's status update aside)", since
  the implementer's status update always touches the task document. The
  presentation-format Doc-sync line keeps a `Criteria:` line like every other
  task. Phase 1 DONE's sizing bullet gained a pointer to the exemption, so the
  DONE bar does not contradict the exemption.

Plan Step 2.1 (rulings M3, M4, D1, D2). Phase 1 Inputs gain the plan's
Documentation impact element. Phase 1 DONE gains the three cases: the element
names documents → the last task is `### Task N: Doc-sync` with
`Depends on: Task 1-<N-1>`; the element is `N/A — <reason>` → no Doc-sync
task; the plan has no element at all → no Doc-sync task, and the reviewer
reports the gap. State M3: every task document, phase-specific ones included,
gets the Doc-sync task carrying the full document list, and its acceptance
criterion is scoped to what the tasks in that document changed. Rename the
"Cross-phase dependency rule" so `Depends on` covers any hard ordering
dependency within or across phases, keeping the cross-phase analysis guidance;
Phase 2 DONE's "Cross-phase dependency note" becomes the "Dependency note".
Exempt the Doc-sync task from the sizing table, with the Why (one task by
design, sized by its documents; a long list is a plan-level signal, not a
reason to split). Add the Doc-sync line to the Phase 2 presentation format and
the task to the Phase 2 DONE list. Add the Doc-sync body template from Step
2.1: `**Status:** TODO`, `Depends on: Task 1-<N-1>`, the document list with
per-document change, the promotion instruction, and the three acceptance
criteria. The template also states the rule from the plan's Clarifications
(Q1 / C1): for a document an earlier task in the same document already edits,
the entry says so, and the Doc-sync task verifies that document against the
implementation instead of editing it again.

**Files to modify:**
- `plugins/kenspc/skills/generate-task/SKILL.md`

**Acceptance criteria:**
- Phase 1 Inputs name the Documentation impact element; Phase 1 DONE states
  the three cases above.
- The M3 statement and the sizing exemption with its Why are present.
- The dependency rule no longer restricts `Depends on` to cross-phase
  dependencies, the cross-phase analysis guidance is kept, and
  `grep -n 'Cross-phase dependency note' plugins/kenspc/skills/generate-task/SKILL.md`
  returns nothing while `Dependency note` is present.
- The presentation format contains
  `N. Task N: Doc-sync — M documents, depends on Task 1-<N-1>`, and the Phase 2
  DONE list names the Doc-sync task among the items the written document
  includes.
- The template contains, in substance, the Step 2.1 promotion instruction
  (read the `Decisions:` sub-bullets of Tasks 1-<N-1>; write a decision a
  future reader would look for in a listed document into it, in that document's
  language and structure; list a decision that belongs in a durable document
  but fits none under `## Decisions needing a home` in the run report with a
  suggested destination, writing it nowhere; leave a local decision where it
  is; create or modify no document outside the list) and the three Step 2.1
  acceptance criteria.
- The template states that a document an earlier task already edits is marked
  as such in its entry and verified against the implementation, not edited
  again.
- Fixed strings spelled exactly as in the plan's table: `### Task N: Doc-sync`,
  `Depends on: Task 1-<N-1>` (ASCII hyphen), `Documentation impact`,
  `N/A — <reason>`, `## Decisions needing a home`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 5: Show the Doc-sync task in the task example

**Status:** DONE

**Implementation notes:**
- Decisions: the origin note is a new block quote under Task 6 rather than a
  sentence in Task 1's existing block quote, so Tasks 1–5 stay byte-unchanged
  and the note sits next to the task it explains. Task 6's text is the
  generate-task template filled in (Tasks 1-5, two documents), so the example
  and the skill that produces it cannot disagree on wording.
- Changes/tradeoffs: the entries cite plan step numbers of the example's
  hypothetical `docs/plans/auth-plan.md`, which the example never shows. Task
  6's acceptance criteria drop trailing periods to match the example's other
  criteria. The existing Task 1 note still says "Tasks 3–5 (TODO)"; it stays
  accurate without naming Task 6, and editing it was outside this task's
  "otherwise unchanged" bar.

Depends on: Task 4

Plan Step 2.2. After Task 5 and before `## Notes`, append
`### Task 6: Doc-sync` with `**Status:** TODO`, `Depends on: Task 1-5`, a
two-document list that fits the example (for instance the README's
authentication section and an API document), the promotion instruction, and
the acceptance criteria, worded from the Task 4 template. Add one sentence to
the existing block-quote note, or a new short note: Task 6 is what
`generate-task` appends when the plan's Documentation impact is not N/A. Add a
one-line Dependency note to the example's `## Context` section, written to
the rule in `generate-task` Phase 2 DONE (Task 4), so the example matches the
skill that produces it.

**Files to modify:**
- `plugins/kenspc/references/task-document-example.md`

**Acceptance criteria:**
- `### Task 6: Doc-sync` is the last `### Task` heading and sits before
  `## Notes`; the line `Depends on: Task 1-5` is under it.
- Task 6 has no `**Implementation notes:**` block.
- The note explaining where Task 6 comes from is present, and `## Context`
  carries a Dependency note.
- Tasks 1–5 and the Notes section are otherwise unchanged in `git diff`.
- `bash scripts/check-notes-format-sync.sh` and `bash scripts/check-all.sh`
  exit 0.

---

### Task 6: Check Doc-sync coverage in task-document-reviewer Angle 1

**Status:** DONE

**Implementation notes:**
- Decisions: the passing statement names the fixed heading
  (`### Task N: Doc-sync`) so the reviewer recognises the task by the D1
  anchor, not by wording. The Angle 2 bullet uses the Q3 wording verbatim,
  "Depends on" unquoted as the ruling gives it.
- Changes/tradeoffs: the passing statement's "when the element says N/A
  there is none" has no matching failure mode (a Doc-sync task present under
  an N/A element), because the spec fixes exactly four modes; a reviewer
  would still catch it against the passing statement. The bullet ends with
  a Why sentence, which is not a failure mode.

Depends on: Task 4

Plan Step 2.3 (ruling D5). Add one rubric bullet to Angle 1 Completeness.
Passing statement: when the plan's Documentation impact names documents, the
task document ends with a Doc-sync task whose `Depends on` covers every other
task and whose document list matches the element; when the element says N/A
there is none. Named failure modes: (1) the element names documents but no
Doc-sync task exists; (2) the Doc-sync task is not last, or its dependency
range omits a task; (3) its document list differs from the element; (4) the
plan has no Documentation impact element at all — a plan-level issue, recorded
under Plan-Level Concerns, not fixed in the task document. Modes 1–3 are
task-level: fix in the task document (generate the task from the
`generate-task` Doc-sync template, referenced with a `${CLAUDE_PLUGIN_ROOT}`
path; move it; complete the range; align the list) and commit. Also, per
ruling M4 as the plan's Clarifications (Q3) record, reword Angle 2's "For cross-phase
tasks: are dependency annotations present and accurate?" to:
"For tasks with a Depends on line: is every hard dependency annotated, and is
each annotation accurate?" — wording only, no mention of cross-phase.

**Files to modify:**
- `plugins/kenspc/agents/task-document-reviewer.md`

**Acceptance criteria:**
- Angle 1 contains the new bullet: one passing sentence, exactly the four
  numbered failure modes above, the task-level fixes for modes 1–3, and the
  plan-level classification of mode 4.
- The Angle 2 bullet reads as reworded above and
  `grep -n 'cross-phase' plugins/kenspc/agents/task-document-reviewer.md`
  returns nothing.
- Angle 1's other bullets and the rest of Angle 2 are unchanged in `git diff`;
  the description still starts with `INTERNAL:`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 7: Add the dependency gate, decision promotion, and Decisions needing a home to task-implementer

**Status:** DONE

**Implementation notes:**
- Decisions: the new section is named `DECISION PROMOTION` and sits after
  CODE ARTIFACTS LANGUAGE, next to the other language rule and just before
  the Schema D section that reads its outcomes. The gate emits one
  `depends on Task N (<status>)` reason per unmet dependency, so a range with
  two blocked tasks names both. The gate treats a task BLOCKED in an earlier
  run the same as one blocked in this run: the status on disk is what counts.
- Changes/tradeoffs: the Schema D example bullet sits on its own line in
  backticks rather than wrapping inside an inline code span. The section's
  Why also says it is the one Schema D prose section never skipped, so a
  reader sees the deliberate departure from the skip-when-empty rule (D4).
  The DECISION PROMOTION Why for "no question, no file, no unlisted
  document" cites the unattended run and the existing stated-scope boundary;
  AUTONOMY BOUNDARIES itself is unchanged.

Plan Step 3.1 (rulings M5, D2, D3, D4). Three additions, each with its Why:

1. Dependency gate, in PROCESSING APPROACH before the per-task planning
   bullet: before implementing a task, read its `Depends on` line (a single
   task `Task 1`, a range `Task 1-5` meaning Tasks 1 through 5, or a list);
   if any named task is not DONE — BLOCKED in this run or earlier, or later in
   the document and not yet processed — mark this task BLOCKED with the reason
   `depends on Task N (<status>)`, persist the `- Blocked:` line and commit it
   as STUCK HANDLING prescribes, and continue with the next task. Why: a
   task's `Depends on` is a hard dependency; implementing on top of a blocked
   one produces work that cannot be verified, and a Doc-sync task that runs
   would document behaviour that does not exist.
2. A new section in the writer-agent header style (ALL CAPS, no hyphen, for
   example `DECISION PROMOTION`): when a task instructs the promotion of
   earlier decisions, each decision has one of three outcomes — promoted,
   needs a home, local — with the D3 criterion (local is the default; promote
   only what a future reader would look for in a durable document: a
   convention others must follow, a constraint, a rejected alternative that
   will be proposed again); write in the target document's own language and
   structure; ask no question; create no file; modify no document the task
   does not list. Record the outcomes in that task's `**Implementation notes:**`
   block — under `Decisions:` what was promoted where and what needs a home
   with its suggested destination, under `Changes/tradeoffs:` as usual — with
   no new sub-bullet label.
3. Schema D: add `## Decisions needing a home` after `## Decisions made`, one
   bullet per entry (task ID, the decision, a suggested destination: a
   document path, with a section where one fits). Source: the Doc-sync task's
   notes block when one was processed DONE in this run; otherwise the DONE
   tasks' `Decisions:` sub-bullets, classified at roll-up by the D3 criterion
   into local or needs a home — a run without a Doc-sync task has no promoted
   outcome and writes nothing. Always rendered, `none` when empty, with the
   Why: in an unattended run this section is the only evidence the promotion
   step ran. Update the roll-up intro so its count of prose sections matches,
   and add to DONE CRITERIA that the Schema D summary carries the section.

**Files to modify:**
- `plugins/kenspc/agents/task-implementer.md`

**Acceptance criteria:**
- PROCESSING APPROACH has the gate bullet before the planning bullet, with the
  reason string `depends on Task N (<status>)` spelled exactly and its Why.
- The new ALL-CAPS section states the three outcomes with the D3 criterion,
  the target-language rule, no questions, no new files, no unlisted document,
  and the recording rule without a new label.
- Schema D has `## Decisions needing a home` directly after
  `## Decisions made`, with the source rule, always-rendered / `none` rule, and
  Why; the roll-up intro's section count and DONE CRITERIA are updated.
- `## Decisions made`, AUTONOMY BOUNDARIES, CODE ARTIFACTS LANGUAGE, the
  `CODE-CRAFT PRINCIPLES` header, its guard comment, and both canonical
  paragraphs are unchanged in `git diff`; `effort: xhigh` unchanged.
- The file contains both `Doc-sync` and `Decisions needing a home`.
- `bash scripts/check-code-craft-canonical.sh`,
  `bash scripts/check-notes-format-sync.sh`, and `bash scripts/check-all.sh`
  exit 0.

---

### Task 8: Render Decisions needing a home in task-implement

**Status:** DONE

**Implementation notes:**
- Decisions: the Schema G Implementation placeholder now reads "Schema D
  verbatim, including its `## Decisions needing a home` section", so the
  orchestrator sees the section is expected there without a second copy of
  its rules. The two new Next steps rules extend the existing prose sentence
  inside the Schema G block rather than adding a separate list, matching how
  the DEFERRED bullets are already described.
- Changes/tradeoffs: the Phase 1 Step 5 paragraph was rewrapped after the
  insertion; every changed line stays inside Phase 1 Step 5 or Phase 2
  Step 4, and the Verdict determination bullets are untouched.

Depends on: Task 7

Plan Step 3.2. Edit only Phase 1 Step 5 and Phase 2 Step 4. Phase 1 Step 5:
the prose sections rendered below the Schema D table add Decisions needing a
home. Phase 2 Step 4, Schema G: the Implementation section is still Schema D
verbatim, so the section appears there; Next steps gains one bullet per
Decisions needing a home entry (decision and suggested destination), and, when
the Doc-sync task is BLOCKED, one bullet stating that the listed documents were
not synced and why. Verdict determination is unchanged.

**Files to modify:**
- `plugins/kenspc/skills/task-implement/SKILL.md`

**Acceptance criteria:**
- Phase 1 Step 5 names Decisions needing a home among the rendered prose
  sections.
- Schema G's Next steps description includes the per-entry bullet and the
  BLOCKED-Doc-sync bullet; the file contains `Decisions needing a home`.
- `git diff` touches no line outside Phase 1 Step 5 and Phase 2 Step 4, and no
  line of the Verdict determination bullets.
- `bash scripts/check-canonical-dispatch.sh`,
  `bash scripts/check-verdict-shared.sh`, `bash scripts/check-run-contract.sh`,
  and `bash scripts/check-all.sh` exit 0.

---

### Task 9: Add Angle 3, Consistency with CLAUDE.md, to task-document-reviewer

**Status:** DONE

**Implementation notes:**
- Decisions: the angle-count sentence now matches plan-document-reviewer's
  form ("Review all three angles in order (each angle builds on fixes from
  the previous one)"). Angle 3's passing statement notes that project- and
  user-level CLAUDE.md files are both loaded into the session, so the
  reviewer does not go looking for `~/.claude/CLAUDE.md` itself (the plan's
  standing constraint). The dual case is a third ISSUE CLASSIFICATION entry
  in the existing arrow style; PROCESSING APPROACH needed no change because
  it already routes each issue by its classification.
- Changes/tradeoffs: the agent's example table gained a PASSED row 3; the
  generate-task Phase 3 Step 2 table lost its PASSED row 4 and keeps rows
  1–3 as they were. The agent's OBJECTIVE ("complete, correctly ordered, and
  actionable") was left as is, since the task scoped no edit to it.

Plan Step 4.1 (rulings M6, M7). Add Angle 3, "Consistency with CLAUDE.md",
after Execution Order. Passing statement: every task can be executed as
written without departing from a rule in a loaded CLAUDE.md (project or user
level), and no task text the implementer will carry into a code artifact or a
durable document is in a language other than that artifact's own. A
preference no loaded CLAUDE.md states is not a finding — this sentence bounds
the passing statement and is not a fourth failure mode (plan Clarifications,
C3). Named failure modes: (1) written-rule departure — fix the task to follow the rule;
(2) language carry-over, anchored to `task-implementer`'s CODE ARTIFACTS
LANGUAGE rule and to the target document's language — fix by rewriting those
fragments; (3) undecided git workflow step (a branch, pull-request, rebase, or
tag step the plan did not prescribe, or that a loaded CLAUDE.md contradicts) —
fix the task back to the default (no branch, commits on the current branch) and
record a Plan-Level Concern naming both sources; a step the plan prescribes and
no CLAUDE.md contradicts is not a finding. ISSUE CLASSIFICATION gains the dual
case (a plan-level cause with a task-level symptom is fixed in the task
document and also recorded as a Plan-Level Concern) with its Why. "Review both
angles in order …" becomes three angles, and the OUTPUT FORMAT example table
shows three rows. Per the plan's Clarifications (Q5), the Schema E example table
in `generate-task` Phase 3 Step 2 (the table the orchestrator renders from)
also becomes three rows; the four-row tables in `generate-plan` and
`generate-guide` stay, since their reviewers have four angles.

**Files to modify:**
- `plugins/kenspc/agents/task-document-reviewer.md`
- `plugins/kenspc/skills/generate-task/SKILL.md`

**Acceptance criteria:**
- Angle 3 exists after Angle 2 in rubric form with exactly the three failure
  modes above, including the "not a finding" exception in mode 3.
- Angle 3 carries, outside the three numbered modes, the sentence that a
  preference no loaded CLAUDE.md states is not a finding.
- ISSUE CLASSIFICATION states the dual case with its Why (task-implement runs
  unattended and cannot ask; the fix keeps the run inside the written rules,
  the concern hands the decision back to the user).
- `grep -n 'both angles' plugins/kenspc/agents/task-document-reviewer.md`
  returns nothing; the agent's example table and the `generate-task` Phase 3
  Step 2 table each have exactly three data rows.
- PROCESSING APPROACH, STUCK HANDLING, and the description (`INTERNAL: …`) are
  unchanged in `git diff`; `generate-plan` and `generate-guide` are not
  touched.
- `bash scripts/check-all.sh` exits 0.

---

### Task 10: Add the document-language rule to generate-task

**Status:** DONE

**Implementation notes:**
- Decisions: the rule is a `**Document language**` paragraph in Phase 2,
  right after Output path resolution, in the same bold-label style as the
  other Phase 2 write-time rules. It names the artifact kinds that fall under
  CODE ARTIFACTS LANGUAGE (commit messages, code comments, identifiers) but
  not the language that rule prescribes, so the skill states no default
  language of its own.
- Changes/tradeoffs: none. `task-document-reviewer.md` was not touched, per
  C2.

Plan Step 4.2 (ruling M6; plan Clarifications, C2). In Phase 2, add a
document-language rule: the task document is written in the plan document's
language unless the user explicitly requests otherwise (the same exception
generate-plan's language rule has); text that the
implementer will carry into code artifacts follows `task-implementer`'s CODE
ARTIFACTS LANGUAGE rule. No default language of the plugin's own. Why: the
implementer copies task text into commits, comments, and documents; and the
rule gives `task-document-reviewer` Angle 3 (written in Task 9, whose language
failure mode checks task text against the same CODE ARTIFACTS LANGUAGE rule and
the target document's language) a plugin-side anchor without the plugin
imposing a language. Angle 3 as Task 9 writes it needs no reference back to
this rule, so `task-document-reviewer.md` is not edited here.

**Files to modify:**
- `plugins/kenspc/skills/generate-task/SKILL.md`

**Acceptance criteria:**
- Phase 2 contains the rule, including the "unless the user explicitly
  requests otherwise" exception, with its Why, and names no default language.
- No other part of the file, and no other file, changed in this commit.
- `bash scripts/check-all.sh` exits 0.

---

### Task 11: Add the check-doc-sync-anchors.sh guard

**Status:** TODO

Depends on: Task 1-10

Plan Step 5.1 (ruling M8). Create an anchor-presence guard modeled on
`scripts/check-notes-format-sync.sh`: header comment stating what it guards
and why, `set -euo pipefail`, the same SCRIPT_DIR / REPO_ROOT derivation,
`run_main_logic "$repo_root"` returning 0/1/2, and a dispatch that matches the
literal `"--self-test"`. Three anchor groups, each a label and the files that
must all contain it:

- `Documentation impact`: `plugins/kenspc/skills/generate-plan/SKILL.md`,
  `plugins/kenspc/references/plan-document-example.md`,
  `plugins/kenspc/agents/plan-document-reviewer.md`,
  `plugins/kenspc/skills/generate-task/SKILL.md`,
  `plugins/kenspc/agents/task-document-reviewer.md`.
- `Doc-sync`: `plugins/kenspc/skills/generate-task/SKILL.md`,
  `plugins/kenspc/references/task-document-example.md`,
  `plugins/kenspc/agents/task-document-reviewer.md`,
  `plugins/kenspc/agents/task-implementer.md`.
- `Decisions needing a home`: `plugins/kenspc/agents/task-implementer.md`,
  `plugins/kenspc/skills/task-implement/SKILL.md`.

Exit 0 when every label is in every file of its group; exit 1 naming each
missing label and file; exit 2 on a missing input file or a stale fixture.
Self-test: copy the eight files into a `mktemp -d` workdir, confirm `Doc-sync`
is present in the copied task example (fixture-stale check, exit 2 if not),
expect 0, rename `Doc-sync` to `Docsync` there with `sed -i.bak … && rm …bak`,
expect 1, revert by recopying, expect 0. README and CLAUDE.md stay outside the
guard.

**Files to create:**
- `scripts/check-doc-sync-anchors.sh` (mode 100644, like the other guards)

**Acceptance criteria:**
- `bash scripts/check-doc-sync-anchors.sh` exits 0 and
  `bash scripts/check-doc-sync-anchors.sh --self-test` exits 0.
- Falsifiability by hand: replacing `Documentation impact` with another string
  in one guarded file makes the guard exit 1 and name that file; restoring the
  file with `git checkout -- <file>` returns exit 0, and `git status` shows no
  leftover change to that file.
- `bash scripts/check-all.sh --self-test` prints `guards run: 10`, ends with
  `self-tests run: 9`, and every line is PASS (the existing SKIP for
  `check-review-agent-drift.sh` aside).
- The header comment states what the script guards and why (a rename of an
  anchor in one file breaks the documentation chain silently), and documents
  the three groups, the exit codes, and the `--self-test` fixture in the style
  of the other guards.

---

### Task 12: Update the repository CLAUDE.md

**Status:** TODO

Depends on: Task 1-11

Plan Step 6.1 (ruling M2). Add a "Durable documents" subsection with a table
under or beside "Workflow artifacts under docs/", listing at least
`README.md`, `plugins/kenspc/README.md`, `CLAUDE.md`,
`plugins/kenspc/CHANGELOG.md`, `docs/release-checklist.md`, `docs/roadmap.md`,
`docs/dry-runs/README.md`, `plugins/kenspc/references/plan-document-example.md`,
and `plugins/kenspc/references/task-document-example.md`, each with what it
holds and when it changes; keep the existing prose about transient artifacts.
In "Subagent Review Architecture", the serial review paragraph states that the
task-document reviewer reviews three angles (Completeness including Doc-sync
coverage, Execution Order, Consistency with CLAUDE.md) and that the plan
reviewer checks Documentation impact; add a short paragraph on the
documentation path (element → Doc-sync task → promotion → Decisions needing a
home) and the dependency gate. In "Repository scripts/", add
`check-doc-sync-anchors.sh` in the list's style, and change "Eight of the
guards … also accept a `--self-test` flag" to nine, naming the new script in
the parenthesized list.

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- The Durable documents table lists the nine documents above, and
  `test -f` succeeds for every path in it.
- The serial review paragraph, the documentation-path paragraph, and the
  dependency gate are present.
- `grep -n 'Eight of the guards' CLAUDE.md` returns nothing; "Nine of the
  guards" names `check-doc-sync-anchors.sh`; the scripts list has a
  `check-doc-sync-anchors.sh` bullet.
- No statement in the file contradicts three task-reviewer angles, ten guards,
  or nine self-tests.
- `bash scripts/check-all.sh` exits 0.

---

### Task 13: Update the READMEs

**Status:** TODO

Depends on: Task 1-10

Plan Step 6.2. Root `README.md`: the generate-task row's "2-angle review"
becomes "3-angle review". `plugins/kenspc/README.md`: the Skills table rows
for generate-plan (Documentation impact), generate-task (Doc-sync task; three
review angles), and task-implement (dependency gate; decision promotion;
Decisions needing a home); the Agents table row for `task-document-reviewer`;
a short "Documentation path" paragraph under Recommended Workflow; and the
"Branches" item under Known behavior extended with ruling M7 in one or two
sentences (the plugin takes no side; whether to branch is decided at plan
time; reviewers fix an unprescribed or contradicted branch step back to the
default and record a Plan-Level Concern; `task-implementer` follows the task
document and asks nothing).

**Files to modify:**
- `README.md`
- `plugins/kenspc/README.md`

**Acceptance criteria:**
- `grep -n '2-angle' README.md` returns nothing and the generate-task row says
  "3-angle review".
- The three Skills rows, the Agents row, the Documentation path paragraph, and
  the extended Branches item are present in `plugins/kenspc/README.md`.
- Every sentence in both files that states an angle count or describes
  generate-plan, generate-task, or task-implement agrees with the SKILL and
  agent files as changed by Tasks 1–10.
- `bash scripts/check-all.sh` exits 0.

---

### Task 14: Add the 3.6.0 CHANGELOG entry and update the roadmap

**Status:** TODO

Depends on: Task 1-11

Plan Step 6.3 (ruling M9). `plugins/kenspc/CHANGELOG.md`: a
`## 3.6.0 — unreleased` entry above `## 3.5.1 — 2026-09-24` with Added
(Documentation impact; Doc-sync task; Decisions needing a home; Angle 3,
Consistency with CLAUDE.md; `check-doc-sync-anchors.sh`), Changed (the
dependency gate — a behaviour change for every task with a `Depends on` line;
`Depends on` semantics; task-document language; task-document reviewer angle
count 2 → 3; guard counts 10 / 9), and the M7 stance on branches. The date is
filled at release. `docs/roadmap.md`: remove batch A from "Planned batches".

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`
- `docs/roadmap.md`

**Acceptance criteria:**
- `grep -n '^## 3.6.0 — unreleased$' plugins/kenspc/CHANGELOG.md` matches, and
  that heading is the first `## ` version heading, above 3.5.1.
- The entry has Added and Changed subsections with every item listed above,
  and states the M7 stance.
- `docs/roadmap.md` no longer lists batch A; B and C remain, in that order;
  the "Next minor (3.6.0)" list is unchanged.
- `git diff` does not touch `plugin.json` or `marketplace.json`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 15: Update the release checklist

**Status:** TODO

Depends on: Task 1-11

Plan Step 6.4. Pre-flight: both mentions of the expected counts become
`guards run: 10` and `self-tests run: 9`. Smoke rows: row 4 adds "the plan
contains a `## Documentation impact` section (a list or `N/A — <reason>`)";
row 5 adds "when the plan's element names documents, the task document's last
task is `### Task N: Doc-sync` with `Depends on: Task 1-<N-1>`"; row 6 adds
"Schema G contains `## Decisions needing a home`, and a run with one task
forced BLOCKED shows the Doc-sync task BLOCKED with
`depends on Task N (BLOCKED)`".

**Files to modify:**
- `docs/release-checklist.md`

**Acceptance criteria:**
- `grep -c 'guards run: 10' docs/release-checklist.md` and
  `grep -c 'self-tests run: 9' docs/release-checklist.md` each return 2;
  `guards run: 9` and `self-tests run: 8` no longer appear.
- Rows 4, 5, and 6 carry the additions above with the fixed strings spelled
  exactly.
- The full pre-flight block from the checklist passes: the effort-override
  diff, `claude plugin validate --strict .`,
  `claude plugin validate --strict ./plugins/kenspc`, and
  `bash scripts/check-all.sh --self-test` with `guards run: 10` and
  `self-tests run: 9`.

---

### Task 16: Doc-sync

**Status:** TODO

Depends on: Task 1-15

Written by hand from the plan's Step 2.1 template (plan Testing Strategy,
dogfood note). The plan's Documentation impact names the documents below. The
edits it plans for them are made by Tasks 2, 5, and 12–15; this task brings
each document in line with what Tasks 1–15 actually implemented, as recorded
in their `**Implementation notes:**` blocks, and promotes their decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` — § Subagent Review Architecture, § Repository scripts/, the new
  Durable documents table (plan Step 6.1, Task 12).
- `plugins/kenspc/README.md` — § Skills, § Agents, § Recommended Workflow,
  § Known behavior (plan Step 6.2, Task 13).
- `README.md` — § Available Plugins, the generate-task row (plan Step 6.2,
  Task 13).
- `plugins/kenspc/CHANGELOG.md` — the 3.6.0 entry (plan Step 6.3, Task 14).
- `docs/roadmap.md` — batch A removed (plan Step 6.3, Task 14).
- `docs/release-checklist.md` — guard counts, smoke rows 4–6 (plan Step 6.4,
  Task 15).
- `plugins/kenspc/references/plan-document-example.md` — the Documentation
  impact section (plan Step 1.2, Task 2).
- `plugins/kenspc/references/task-document-example.md` — the Doc-sync task and
  its note (plan Step 2.2, Task 5).

**Promotion:** read the `Decisions:` sub-bullets in the Implementation notes of
Tasks 1-15. Write each decision that a future reader would look for in one of
the listed documents into that document, in the document's own language and
structure. List a decision that belongs in a durable document but fits none of
the listed ones under `## Decisions needing a home` in the run report with a
suggested destination, and write it nowhere. Leave a decision that only
explains a local code choice where it is. Create or modify no document outside
the list.

**Acceptance criteria:**
- Each listed document describes the behaviour Tasks 1-15 implemented, so that
  a reader of that document alone learns it: no statement in it contradicts
  the SKILL, agent, or script files as changed by Tasks 1-11, or a deviation
  recorded under `Changes/tradeoffs:` in Tasks 1-15.
- Every promoted decision appears in the document named for it, in that
  document's language.
- `git show --stat` of this task's commit lists no file other than the listed
  documents and this task document.
- `bash scripts/check-all.sh` exits 0.

---

## Notes

- The plan's Testing Strategy also calls for a live-chain run in a throwaway
  project and negative cases for the reviewers. Those need an interactive
  session with the updated plugin loaded and are not part of this batch run;
  they belong to the 3.6.0 release smoke test.
- This document was produced by the pre-batch `generate-task`, which does not
  yet append a Doc-sync task; as the plan's Testing Strategy asks, Task 16 was
  added by hand from the Step 2.1 template, which makes it the template's first
  manual test.
- Observation for the batch record (no action for any task): the pre-batch
  `task-document-reviewer` drafted Task 16 on its own during the review, after
  reading the plan's dogfood note, and committed it inside an Angle 1 review
  commit. The draft was checked against the Step 2.1 template, kept unchanged,
  and moved into a separate commit. It is early evidence for ruling D2: template
  text that reaches an artifact already steers an agent's behaviour.
