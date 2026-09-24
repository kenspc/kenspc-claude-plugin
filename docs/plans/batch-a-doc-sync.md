# Plan: Batch A — doc-sync task, decision promotion, CLAUDE.md consistency angle

Target: this repository (`kenspc` plugin), on top of v3.5.1.
Release: ships with 3.6.0 together with the roadmap's "Next minor" items; this
batch makes no version bump and no tag. Its CHANGELOG entry goes under a
`## 3.6.0 — unreleased` heading that the other items extend as they land.

This document is the complete specification. The design was settled in a
separate session; every ruling it depends on is recorded in
[Design decisions](#design-decisions) so the implementing session needs
nothing beyond this file and the repository.

## Objective

Give the plan → task → implement chain a documentation path:

1. A plan states which durable documents its change makes stale
   (**Documentation impact**).
2. The task document ends with a **Doc-sync** task that brings those
   documents up to date, after every other task.
3. Decisions that surface during implementation are promoted into those
   documents through the Doc-sync task, or reported under
   **Decisions needing a home** with a suggested destination when none of
   the listed documents fits.
4. The task-document reviewer gains a third angle, **Consistency with
   CLAUDE.md**, which the plan-document reviewer already has.

**In scope:** A-1 to A-4 above; one new guard script with a self-test; the
runtime dependency gate that makes `Depends on` mean something; the
documentation updates the change requires; a documentation table in this
repository's own CLAUDE.md so the batch can be dogfooded here.

**Out of scope:** batches B (`diagnose-bug`) and C (prototypes) and anything
that only they would need; roadmap items 1–7; any edit inside a byte-identity
section (the canonical blocks in the two review skills, the five reviewers'
shared sections, the code-craft canonical paragraphs); new CONTEXT keys; any
question to the user during `/kenspc-task-implement`, which stays unattended;
a branching policy — the plugin neither opens branches on its own nor forbids
them.

## Background

`docs/roadmap.md` lists this as the first planned batch. Today a decision made
during implementation lives only in that task's `**Implementation notes:**`
block and the Schema D roll-up; nothing carries it into README, CLAUDE.md, or
the project's own documents, so those drift from the code with every batch.

Two failures observed on real runs motivate A-4:

- A task document written in Chinese had its text carried verbatim into
  English artifacts by the implementer.
- A plan prescribed opening a branch in a project whose convention is to
  commit on the main branch; the plan reviewer let it through and the task
  document inherited the step unchallenged.

## Design decisions

Rulings made by the maintainer on 2026-09-24. Each one is binding for this
batch; the implementing session applies them, it does not reopen them.

### Mismatches between the locked design and the repository (M1–M9)

| # | Question | Ruling | Consequence |
|---|---|---|---|
| M1 | The plan element list says "include only what applies", so an omitted Documentation impact would make the downstream check vacuous. | Documentation impact is the one plan element that is always present, as a list or as `N/A — <reason>`; `plan-document-reviewer` checks it. | Steps 1.1, 1.3. |
| M2 | "The documentation table in the project's CLAUDE.md" — this repository's CLAUDE.md has no such table; other projects do (`Topic \| File`, `Task Type \| Read First`). | Both: the plugin wording is "the durable documents the project's CLAUDE.md names — a documentation table where one exists, otherwise the documents it names in prose; when it names none, README.md and CLAUDE.md themselves"; and this repository's CLAUDE.md gains a documentation table. | Steps 1.1, 6.1. |
| M3 | `generate-task` can decompose one phase; Documentation impact is plan-level. | Every task document gets a Doc-sync task carrying the full list; its acceptance criterion is scoped to what the tasks in that document changed. | Step 2.1. |
| M4 | `Depends on` is defined as a cross-phase annotation only. | `Depends on` means any hard ordering dependency, within or across phases; the note at the top of the document is the "Dependency note". Wording change only. | Step 2.1. |
| M5 | `task-implementer` never reads `Depends on`; a Doc-sync task would run after a BLOCKED task and document behaviour that does not exist. | A general dependency gate: a task whose `Depends on` names a task that is not DONE is BLOCKED with the reason `depends on Task N (<status>)`. This changes existing behaviour for every task with a `Depends on` line. | Step 3.1; CHANGELOG "Changed". |
| M6 | A Chinese task document fed English artifacts; `generate-task` has no document-language rule and the plugin does not impose one. | The task document is written in the plan document's language (inheritance, no new default). Angle 3 anchors its language failure mode to `task-implementer`'s CODE ARTIFACTS LANGUAGE rule and to the target document's own language. | Steps 4.1, 4.2. |
| M7 | A plan prescribed a branch against the project's convention. | The plugin takes no side. Default: no branch, commits on the current branch (already README "Known behavior"). Whether to branch is the user's decision, made at plan time — approving the plan is the ask. Reviewers never decide: a branch step the plan did not prescribe, or that a loaded CLAUDE.md contradicts, is fixed back to the default in the task document and recorded as a Plan-Level Concern naming both sources; `generate-task`'s existing "re-run `/kenspc-plan`" suggestion returns the decision to the user. A step the plan prescribes and no CLAUDE.md contradicts is not a finding. `task-implementer` follows the task document as written and asks nothing. | Step 4.1. |
| M8 | The design names no invariant for the new guard. | One anchor-presence guard, `scripts/check-doc-sync-anchors.sh`, with a mutation self-test, covering the three new anchors across the files that carry them. `guards run: 10`, `self-tests run: 9`. | Step 5.1. |
| M9 | Release as 3.6.0 alone or bundled? | Bundled with the roadmap's seven "Next minor" items. No version bump in this batch. | Step 6.3. |

### Architecture choices (D1–D6)

| # | Choice | Ruling | Why |
|---|---|---|---|
| D1 | How a Doc-sync task is recognised. | Fixed heading `### Task N: Doc-sync`. No `Kind:` marker line. | One place writes it, one checks it, one greps it; a rename is a detectable failure. A marker field is extensibility nobody asked for; content-based recognition relies on wording, which the Plugin Design Lessons reject. |
| D2 | Where the "promote earlier decisions" instruction lives. | In the Doc-sync task's own text, written by `generate-task` from a fixed template. `task-implementer` carries only the general rules: the three outcomes, the target document's language, no questions, no new files, the list-only fallback. | The instruction lives in the artifact, so a hand-written Doc-sync task copied from the example works too; the implementer parses no heading. |
| D3 | Outcomes per decision. | Three, not two: **promoted** (written into a listed document), **needs a home** (belongs in a durable document but none listed fits; listed with a suggested destination, written nowhere), **local** (explains a code-local choice; stays in the task document and git, neither promoted nor listed). Local is the default; a decision is promoted only when a future reader would look for it in a durable document — a convention others must follow, a constraint, a rejected alternative that will be proposed again. | Without the third outcome every code-local rationale becomes "needs a home", the same shape as the pre-G6 LOW flood. Nothing is lost: Schema D's `## Decisions made` still lists every decision. |
| D4 | Persistence and output of Decisions needing a home. | Persisted in the Doc-sync task's own `**Implementation notes:**` block under the existing `Decisions:` and `Changes/tradeoffs:` labels; no new label. Schema D gains `## Decisions needing a home`, read back from that block when a Doc-sync task was processed, otherwise computed at roll-up from the DONE tasks' `Decisions:` sub-bullets. The section is always rendered, `none` when empty. Schema G shows it inside Implementation (Schema D verbatim) and adds one Next steps bullet per entry. | No guard or example change for a label. Always rendering is a deliberate departure from the other Schema D sections' skip-when-empty rule: in an unattended run this section is the only evidence the promotion step ran, and the release checklist greps for it. |
| D5 | Where the Doc-sync coverage check sits in `task-document-reviewer`. | Angle 1 Completeness. A-4 becomes Angle 3. | Documentation impact is a plan element; "is it covered by a task" is a coverage question. |
| D6 | Form of this specification. | A standard plan document in English with Implementation Steps, each with a Why, so it can be followed by hand or decomposed with `/kenspc-task`; it carries its own Documentation impact section. | First dogfood of the format this batch introduces. |

### Standing constraints

- Every new check is written in rubric form: one sentence stating what
  passing looks like, then named failure modes. No generic checklist items
  (the v3.5 reviewer form).
- Rules are rationale-anchored ("Why: …" prose), not imperatives; no
  `MUST` / `NEVER` / `CRITICAL`, no inline effort or reasoning tokens, no
  model names (`check-no-model-names.sh`).
- No edit inside any byte-identity section. The guards that enforce this must
  stay green without modification: `check-canonical-dispatch.sh`,
  `check-verdict-shared.sh`, `check-run-contract.sh`,
  `check-code-craft-canonical.sh`, `check-review-agent-drift.sh`,
  `check-quality-reviewer-bullet-structure.sh`, `check-notes-format-sync.sh`.
- No new CONTEXT keys. `task-document-reviewer` already receives
  `SOURCE_PATH` (the plan) and `PROJECT_PATH`; `task-implementer` already
  receives `TASK_FILE`.
- `effort:` frontmatter is unchanged in every file (release-checklist
  pre-flight diff).
- Per-skill `version: 3.0.0` is unchanged (it denotes the architecture
  generation, see CLAUDE.md).
- Subagents load the user-level and project-level CLAUDE.md files
  automatically (frontmatter `omitClaudeMd` defaults to false, per the
  Claude Code sub-agents reference). A rule in any loaded CLAUDE.md counts as
  a written rule for Angle 3; the reviewer does not need to read
  `~/.claude/CLAUDE.md` itself.

## Fixed strings

These strings are load-bearing: the guard (Step 5.1) asserts their presence,
the release checklist greps for them, and the reviewers check them. Spell
them exactly as given, in every file that carries them.

| Anchor | Exact form | Carried by |
|---|---|---|
| Plan element | `## Documentation impact` heading in plan documents; `Documentation impact` in prose | `generate-plan/SKILL.md`, `references/plan-document-example.md`, `plan-document-reviewer.md`, `generate-task/SKILL.md`, `task-document-reviewer.md` |
| Not-applicable form | `N/A — <reason>` on the line under the heading (one line; the reason is mandatory) | plan documents |
| Doc-sync task heading | `### Task N: Doc-sync` (N = the last task number) | `generate-task/SKILL.md`, `references/task-document-example.md`, `task-document-reviewer.md`, `task-implementer.md` |
| Dependency range | `Depends on: Task 1-<N-1>` with an ASCII hyphen (e.g. `Depends on: Task 1-5`); a single prior task is `Depends on: Task 1` | task documents |
| Schema D / G section | `## Decisions needing a home` | `task-implementer.md`, `task-implement/SKILL.md` |
| Gate reason | `depends on Task N (<status>)` as the `- Blocked:` reason | `task-implementer.md` |

## Implementation Steps

Steps within a phase are ordered; phases 1–4 are independent of each other
except where a step names an earlier one. Phase 5 needs phases 1–4 (the
anchors must exist). Phase 6 comes last.

### Phase 1: Documentation impact (A-1)

**Step 1.1: Add the element to `generate-plan`**

- File: `plugins/kenspc/skills/generate-plan/SKILL.md`.
- Phase 2 Step 1 element list: add `**Documentation impact**` as the one
  element that is always present. It lists the durable documents the plan's
  steps make stale — for each: the path, the section where known, what must
  change, and the step that causes it — or the single line `N/A — <reason>`.
- State the determination basis (ruling M2): the durable documents the
  project's CLAUDE.md names — a documentation table where one exists,
  otherwise the documents it names in prose; when CLAUDE.md names none,
  README.md and CLAUDE.md themselves. Phase 1 Step 2 (read project context)
  notes those documents as input for the element.
- Amend the "include only what applies" sentence so it excludes this
  element, with the Why: the task-document reviewer's Doc-sync check reads
  the element, and an absent element is indistinguishable from a forgotten
  one.
- Input: current SKILL.md. Output: the amended SKILL.md.
- Done when: the element is listed with its determination basis and the
  N/A form; the always-present exception is stated with its Why; no other
  element's wording changed.
- Why: the element is the artifact every downstream step reads; anchoring
  the chain on it, not on plan prose, follows the "artifacts, not wording"
  lesson.

**Step 1.2: Show the element in the plan example**

- File: `plugins/kenspc/references/plan-document-example.md`.
- Add a `## Documentation impact` section after Implementation Steps and
  before Testing Strategy, with two or three entries that fit the example
  (for instance the README's API section for the new endpoints, an
  architecture document for the Socket.IO + Redis adapter), each naming the
  causing step.
- Done when: the section is present in the stated position and each entry
  has path, what changes, and the step.
- Why: users copy the example; the guard (Step 5.1) reads this file.

**Step 1.3: Check the element in `plan-document-reviewer`**

- File: `plugins/kenspc/agents/plan-document-reviewer.md`, Angle 2
  Completeness.
- Add one rubric bullet. Passing statement: Documentation impact names every
  durable document whose content the plan's steps make stale, and nothing
  else, or states N/A with a reason the steps do not contradict. Named
  failure modes: (1) the element is absent; (2) N/A without a reason, or with
  a reason the steps contradict (a step edits README while the element says
  N/A); (3) a document the steps themselves modify is missing; (4) a listed
  document that no step changes anything it describes (padding).
- These are objective issues under the existing FIXING RULES: the reviewer
  derives the list from the steps and the documents CLAUDE.md names, fixes
  the plan, and commits. When it cannot determine an entry it records the
  gap under Open Questions and NOTED, per STUCK HANDLING.
- Done when: the bullet exists in rubric form with exactly those four modes;
  the Angle 2 heading and other bullets are unchanged.
- Why: plan-side enforcement is cheaper than downstream repair; without it
  ruling M1 has no teeth.

### Phase 2: Doc-sync task (A-2)

**Step 2.1: Generate the Doc-sync task in `generate-task`**

- File: `plugins/kenspc/skills/generate-task/SKILL.md`.
- Phase 1 Inputs: the plan's Documentation impact element.
- Phase 1 DONE: when the element names documents, the last task is
  `### Task N: Doc-sync` with `Depends on: Task 1-<N-1>`; when it is
  `N/A — <reason>`, there is no Doc-sync task; when the plan has no
  Documentation impact element at all (a plan written before this batch, or
  by hand), no Doc-sync task is generated and the reviewer reports the gap
  (Step 2.3).
- Ruling M3: every task document gets the Doc-sync task, including
  phase-specific ones, carrying the full document list.
- Ruling M4: rename the "Cross-phase dependency rule" so `Depends on` covers
  any hard ordering dependency, within or across phases; the note at the top
  of the document becomes the "Dependency note". Keep the cross-phase
  analysis guidance itself.
- Sizing: the Doc-sync task is exempt from the file-count sizing table — it
  is one task by design, sized by the documents it lists; a long list is a
  plan-level signal (padded Documentation impact), not a reason to split.
- Phase 2 presentation shows it like any task
  (`N. Task N: Doc-sync — M documents, depends on Task 1-<N-1>`), and the
  Phase 2 DONE list includes it.
- Template the Doc-sync task's body. The generated task carries:
  - `**Status:** TODO` and `Depends on: Task 1-<N-1>`.
  - A list of the documents from Documentation impact with, per document,
    what must change (taken from the plan).
  - The promotion instruction (ruling D2), in substance: read the
    `Decisions:` sub-bullets in the Implementation notes of Tasks 1-<N-1>;
    write each decision that a future reader would look for in one of the
    listed documents into that document, in the document's own language and
    structure; list a decision that belongs in a durable document but fits
    none of the listed ones under `## Decisions needing a home` in the run
    report with a suggested destination, writing it nowhere; leave a
    decision that only explains a local code choice where it is. Create or
    modify no document outside the list.
  - Acceptance criteria, in substance: each listed document describes the
    behaviour Tasks 1-<N-1> implemented, so that a reader of that document
    alone learns it; every promoted decision appears in the named document
    in that document's language; no file outside the listed documents was
    created or modified by this task.
- Done when: all of the above is in the SKILL.md; the template's fixed
  strings match the [Fixed strings](#fixed-strings) table; a plan whose
  element says N/A yields no Doc-sync task.
- Why: the instruction lives in the task document (ruling D2), so the chain
  holds even for a hand-written task document, and the implementer needs no
  heading parser.

**Step 2.2: Show the Doc-sync task in the task example**

- File: `plugins/kenspc/references/task-document-example.md`.
- Append `### Task 6: Doc-sync` with `**Status:** TODO`,
  `Depends on: Task 1-5`, a two-document list that fits the example (for
  instance the README's authentication section and an API document), the
  promotion instruction, and the acceptance criteria from Step 2.1. No
  Implementation notes block (it is TODO).
- Add one sentence to the existing block-quote note, or a new short note:
  Task 6 is what `generate-task` appends when the plan's Documentation
  impact is not N/A.
- Done when: the task is last, its heading and dependency line match the
  fixed strings, and `bash scripts/check-notes-format-sync.sh` still exits 0.
- Why: users copy the example; the guard reads this file.

**Step 2.3: Check Doc-sync coverage in `task-document-reviewer` Angle 1**

- File: `plugins/kenspc/agents/task-document-reviewer.md`, Angle 1
  Completeness (ruling D5).
- Add one rubric bullet. Passing statement: when the plan's Documentation
  impact names documents, the task document ends with a Doc-sync task whose
  `Depends on` covers every other task and whose document list matches the
  element; when the element says N/A there is none. Named failure modes:
  (1) the element names documents but no Doc-sync task exists; (2) the
  Doc-sync task is not last, or its dependency range omits a task; (3) its
  document list differs from the element; (4) the plan has no Documentation
  impact element at all — a plan-level issue, recorded under Plan-Level
  Concerns, not fixed in the task document.
- Modes 1–3 are task-level: fix in the task document (generate the task
  from the Step 2.1 template, move it, complete the range, align the list)
  and commit.
- Done when: the bullet exists in rubric form with those four modes and the
  classification of mode 4.
- Why: the element and the task are the two ends of the documentation path;
  this check is what keeps them attached.

### Phase 3: Decision promotion and the dependency gate (A-3)

**Step 3.1: Extend `task-implementer`**

- File: `plugins/kenspc/agents/task-implementer.md`. Do not touch the two
  canonical code-craft paragraphs or the `CODE-CRAFT PRINCIPLES` header and
  its guard comment.
- Dependency gate (ruling M5), in PROCESSING APPROACH before the per-task
  planning bullet: before implementing a task, read its `Depends on` line;
  if any named task is not DONE — BLOCKED in this run, or later in the
  document and not yet processed — mark this task BLOCKED with the reason
  `depends on Task N (<status>)`, persist the `- Blocked:` line and commit it
  as STUCK HANDLING already prescribes, and continue with the next task.
  Why: a task's `Depends on` is a hard dependency by definition; implementing
  on top of a blocked one produces work that cannot be verified, and a
  Doc-sync task that runs would document behaviour that does not exist.
- Promotion rules (rulings D2, D3), as a new section in the writer-agent
  header style (ALL CAPS, no hyphen): when a task instructs the promotion of
  earlier decisions, each decision has one of three outcomes — promoted,
  needs a home, local — with the criterion from D3; write in the target
  document's own language and structure; ask no question; create no file;
  modify no document the task does not list. Record the outcomes in that
  task's `**Implementation notes:**` block: under `Decisions:`, what was
  promoted where and what needs a home with its suggested destination; under
  `Changes/tradeoffs:` as usual. No new sub-bullet label (ruling D4).
- Schema D: add `## Decisions needing a home` after `## Decisions made`. One
  bullet per entry: task ID, the decision, and a suggested destination (a
  document path, with a section where one fits). Source: the Doc-sync task's
  notes block when one was processed DONE in this run; otherwise the DONE
  tasks' `Decisions:` sub-bullets, applying the D3 criterion at roll-up.
  Always rendered; `none` when empty. State the Why: in an unattended run
  this section is the only evidence the promotion step ran.
- DONE CRITERIA: add that the Schema D summary carries the section.
- `## Decisions made` is unchanged and still lists every decision.
- Done when: the gate, the promotion section, and the Schema D section are
  present with their Whys; `bash scripts/check-code-craft-canonical.sh` and
  `bash scripts/check-notes-format-sync.sh` exit 0; the AUTONOMY BOUNDARIES
  list is unchanged (writing into an unlisted document is already "files
  outside the task's stated scope").
- Why: the implementer is the only agent that knows which decisions were
  made and which documents the task lists; the section is its report to the
  orchestrator.

**Step 3.2: Render the section in `task-implement`**

- File: `plugins/kenspc/skills/task-implement/SKILL.md`. Edit only Phase 1
  Step 5 and Phase 2 Step 4; every canonical block
  (`canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`,
  `canonical:verdict-shared`) stays byte-identical.
- Phase 1 Step 5: the list of prose sections rendered below the Schema D
  table adds Decisions needing a home.
- Phase 2 Step 4, Schema G: the Implementation section is still Schema D
  verbatim, so the section appears there; Next steps gains one bullet per
  Decisions needing a home entry (decision and suggested destination), and,
  when the Doc-sync task is BLOCKED, one bullet stating that the listed
  documents were not synced and why.
- Verdict determination is unchanged: a BLOCKED Doc-sync task already
  prevents PASS ("every task DONE") and lands on PARTIAL.
- Done when: both edits are present; `bash scripts/check-canonical-dispatch.sh`,
  `check-verdict-shared.sh`, and `check-run-contract.sh` exit 0.
- Why: the user acts from Next steps without reading the run directory; a
  decision with no home is an action item like a DEFERRED issue.

### Phase 4: Consistency with CLAUDE.md (A-4)

**Step 4.1: Add Angle 3 to `task-document-reviewer`**

- File: `plugins/kenspc/agents/task-document-reviewer.md`.
- New Angle 3, "Consistency with CLAUDE.md", after Execution Order (it
  builds on the earlier fixes). Passing statement: every task can be
  executed as written without departing from a rule in a loaded CLAUDE.md
  (project or user level), and no task text the implementer will carry into
  a code artifact or a durable document is in a language other than that
  artifact's own. Named failure modes:
  1. Written-rule departure: a task instructs a step, tool, command, commit
     form, or file placement that a loaded CLAUDE.md forbids or prescribes
     differently. Fix the task to follow the rule.
  2. Language carry-over: acceptance criteria, commit-message text,
     identifiers, comments, or document content given in a language other
     than the artifact's own — anchored to `task-implementer`'s CODE
     ARTIFACTS LANGUAGE rule (code, comments, commit messages, identifiers in
     English) and to the target document's language. Fix by rewriting those
     fragments.
  3. Undecided git workflow step (ruling M7): a branch, pull-request,
     rebase, or tag step that the plan did not prescribe, or that a loaded
     CLAUDE.md contradicts. Fix the task back to the default — no branch,
     commits on the current branch — and record a Plan-Level Concern naming
     both sources so the user decides. A step the plan prescribes and no
     CLAUDE.md contradicts is not a finding.
- ISSUE CLASSIFICATION: add the dual case — a plan-level cause with a
  task-level symptom (a plan instruction a loaded CLAUDE.md contradicts,
  carried into a task) is fixed in the task document and also recorded as a
  Plan-Level Concern. Why: `task-implement` runs unattended and cannot ask;
  the fix keeps the run inside the project's written rules, the concern
  hands the decision back to the user.
- "Review both angles in order (the second angle builds on fixes from the
  first)" becomes three angles; the Schema E example table shows three
  rows; PROCESSING APPROACH and STUCK HANDLING need no change.
- Done when: Angle 3 exists in rubric form with exactly those three modes,
  the dual classification is stated with its Why, the angle count and
  example table are updated, and the agent's description is unchanged
  (still `INTERNAL: …`).
- Why: the plan reviewer already checks CLAUDE.md consistency; the task
  document is the last artifact a human reads before an unattended run, so
  it is the last place a conflict can be caught cheaply.

**Step 4.2: Document language in `generate-task`**

- File: `plugins/kenspc/skills/generate-task/SKILL.md`, Phase 2 (ruling M6).
- Add a document-language rule: the task document is written in the plan
  document's language; text that the implementer will carry into code
  artifacts follows `task-implementer`'s CODE ARTIFACTS LANGUAGE rule. No
  default language of the plugin's own.
- Done when: the rule is present with its Why (the implementer copies task
  text into commits, comments, and documents; the reviewer's Angle 3 cites
  this rule).
- Why: gives Angle 3 a plugin-side anchor without the plugin imposing a
  language, which the maintainer's standing decision rules out.

### Phase 5: Guard

**Step 5.1: `scripts/check-doc-sync-anchors.sh`**

- Model: `scripts/check-notes-format-sync.sh` (anchor presence, not
  byte-identity; `set -euo pipefail`; `run_main_logic "$repo_root"` returning
  0/1/2; `--self-test` fixture in a temp workdir with positive, negative, and
  restoration paths; `sed -i.bak … && rm …bak` for BSD sed; the dispatch
  matches the literal `"--self-test"` so `check-all.sh` counts it).
- Three anchor groups, each a label and the files that must all contain it:
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
- Exit 0 when every label is present in every file of its group; exit 1
  naming each missing label and file; exit 2 on a missing input file or a
  stale fixture.
- Self-test mutation: rename `Doc-sync` to `Docsync` in the copied task
  example; expect 1; revert; expect 0. A fixture-stale check confirms the
  target is present before mutating.
- README and CLAUDE.md are deliberately outside the guard (roadmap item 7
  covers prose invariants there).
- Done when: `bash scripts/check-all.sh --self-test` prints
  `guards run: 10` and ends with `self-tests run: 9`, every line PASS; the
  script's header comment states what it guards and why, in the style of
  the other guards.
- Why: three anchors spread over eight files; a rename in one file breaks
  the chain silently, the same failure class the notes-format guard catches.

### Phase 6: Documentation

**Step 6.1: Repository CLAUDE.md**

- File: `CLAUDE.md` (repository root).
- Add a documentation table (ruling M2) — a "Durable documents" subsection
  under "Workflow artifacts under docs/" or beside it — listing at least:
  `README.md`, `plugins/kenspc/README.md`, `CLAUDE.md`,
  `plugins/kenspc/CHANGELOG.md`, `docs/release-checklist.md`,
  `docs/roadmap.md`, `docs/dry-runs/README.md`,
  `plugins/kenspc/references/plan-document-example.md`,
  `plugins/kenspc/references/task-document-example.md`; per row, what the
  document holds and when it changes. Keep the existing prose about
  transient artifacts.
- "Subagent Review Architecture", serial review paragraph: the
  task-document reviewer now reviews three angles (Completeness including
  Doc-sync coverage, Execution Order, Consistency with CLAUDE.md); the plan
  reviewer checks Documentation impact. Add a short paragraph on the
  documentation path (element → Doc-sync task → promotion → Decisions
  needing a home) and the dependency gate.
- "Repository scripts/": add `check-doc-sync-anchors.sh` with a description
  in the list's style; "Eight of the guards … also accept a `--self-test`
  flag" becomes nine and names the new script.
- Done when: the table exists and every listed document is real; the three
  prose updates are present; the file still reads top to bottom without a
  contradiction about angle counts or guard counts.
- Why: CLAUDE.md is the loaded contract for every session in this
  repository, and the table is what the dogfooded element reads.

**Step 6.2: READMEs**

- `README.md` (root): the generate-task row's "2-angle review" becomes
  "3-angle review".
- `plugins/kenspc/README.md`: the Skills table rows for generate-plan
  (Documentation impact), generate-task (Doc-sync task; three review
  angles), task-implement (dependency gate; decision promotion; Decisions
  needing a home); the Agents table row for `task-document-reviewer`; a
  short "Documentation path" paragraph under Recommended Workflow; the
  "Branches" item under Known behavior extended with ruling M7 in one or two
  sentences.
- Done when: every sentence that states an angle count or describes the
  three skills agrees with the SKILL and agent files.
- Why: the README is the installed user's only description of the chain.

**Step 6.3: CHANGELOG and roadmap**

- `plugins/kenspc/CHANGELOG.md`: a `## 3.6.0 — unreleased` entry above
  3.5.1 with Added (Documentation impact; Doc-sync task; Decisions needing a
  home; Angle 3; the guard), Changed (dependency gate — a behaviour change
  for every task with `Depends on`; `Depends on` semantics; task-document
  language; angle count; guard counts 10 / 9), and the M7 stance. Date is
  filled at release.
- `docs/roadmap.md`: remove batch A from "Planned batches" (an item leaves
  the file when it ships; the CHANGELOG records it from then on).
- Done when: both edits are present and the roadmap still lists B and C in
  order.
- Why: the repository's stated convention for planned versus shipped work.

**Step 6.4: Release checklist**

- `docs/release-checklist.md`: pre-flight expects `guards run: 10` and
  `self-tests run: 9` (both mentions). Smoke rows: row 4 adds "the plan
  contains a `## Documentation impact` section (a list or `N/A — <reason>`)";
  row 5 adds "when the plan's element names documents, the task document's
  last task is `### Task N: Doc-sync` with `Depends on: Task 1-<N-1>`";
  row 6 adds "Schema G contains `## Decisions needing a home`, and a run with
  one task forced BLOCKED shows the Doc-sync task BLOCKED with
  `depends on Task N (BLOCKED)`".
- Done when: the counts and the three row additions are present.
- Why: the checklist is the only check that exercises the live chain; the
  fixed strings are what it greps for.

## Documentation impact

Determined from this repository's CLAUDE.md, which names its durable
documents in prose today (Step 6.1 adds the table).

- `CLAUDE.md` § Subagent Review Architecture, § Repository scripts/, new
  Durable documents table — Step 6.1.
- `plugins/kenspc/README.md` § Skills, § Agents, § Recommended Workflow,
  § Known behavior — Step 6.2.
- `README.md` § Available Plugins (generate-task row) — Step 6.2.
- `plugins/kenspc/CHANGELOG.md` — 3.6.0 entry — Step 6.3.
- `docs/roadmap.md` — batch A removed — Step 6.3.
- `docs/release-checklist.md` — guard counts, smoke rows 4–6 — Step 6.4.
- `plugins/kenspc/references/plan-document-example.md` — Step 1.2.
- `plugins/kenspc/references/task-document-example.md` — Step 2.2.
- `docs/dry-runs/README.md` — N/A for this document: the label convention is
  untouched.

## Testing Strategy

- Mechanical: the release-checklist pre-flight block —
  the effort-override diff (unchanged), `claude plugin validate --strict .`
  and `./plugins/kenspc`, and `bash scripts/check-all.sh --self-test` with
  `guards run: 10` and `self-tests run: 9`.
- Guard falsifiability: the new guard's `--self-test` negative path is the
  proof it can fail; additionally, by hand, rename `Documentation impact` in
  one file and confirm exit 1 with that file named, then revert.
- Live chain, in a throwaway project: `/kenspc-plan` produces a plan with
  `## Documentation impact`; `/kenspc-task` on it ends with the Doc-sync
  task and the Schema E table has three rows; `/kenspc-task-implement`
  produces a Schema G whose Implementation section carries
  `## Decisions needing a home` and whose Next steps carry one bullet per
  entry. A second run with one middle task made unimplementable shows that
  task BLOCKED, the Doc-sync task BLOCKED with `depends on Task N (BLOCKED)`,
  the section populated from the DONE tasks, and verdict PARTIAL.
- Negative cases for the reviewers, on hand-edited documents: a plan whose
  element says N/A while a step edits README (plan reviewer mode 2); a task
  document with the Doc-sync task moved to the middle (task reviewer Angle 1
  mode 2); a task carrying a "create branch" step the plan does not have
  (Angle 3 mode 3 → fixed to default, Plan-Level Concern recorded).
- Dogfood note: the task document for this batch is produced by the
  pre-batch `generate-task`, which does not yet append a Doc-sync task. Add
  it by hand from the Step 2.1 template, as `Depends on: Task 1-<N-1>`; that
  is the template's first manual test.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| The plan reviewer "fixes" a missing Documentation impact by inventing entries | Medium | It derives entries only from the plan's steps and the documents CLAUDE.md names; anything it cannot determine goes to Open Questions as NOTED (Step 1.3). |
| Promotion writes low-value rationale into README | Medium | The local outcome is the default (D3); `## Decisions made` still lists everything, so nothing doc-worthy is lost if the implementer under-promotes. |
| The dependency gate blocks tasks that used to be attempted | Certain, by design | CHANGELOG "Changed" entry and README; the reason string names the blocking task, so the user sees exactly why. |
| Plans written before this batch trigger a Plan-Level Concern on every decomposition | High for old plans | One line in the reviewer output; `generate-task`'s existing re-plan suggestion is the remedy. Adding the element to an old plan is a one-line edit. |
| An anchor string appears in a guarded file for an unrelated reason and masks a rename | Low | Presence-only by design, scoped to the eight files that carry the anchors; the self-test proves the negative path. |
| Angle 3 over-reports style as "written-rule departure" | Low | The passing statement requires a rule in a loaded CLAUDE.md; the v3.5 output policy already says an unanchored preference is not a finding. |

## Clarifications during implementation (2026-09-24)

Settled between the implementing session and the spec author after the task-document review; each entry binds like the rulings above.

- Q1 / C1 — Overlap between explicit documentation steps and the Doc-sync task. Phase 6 tasks make the edits this plan prescribes; the Doc-sync task verifies each listed document against what Tasks 1..N-1 implemented and promotes their decisions. The Step 2.1 template states the general rule: for a document an earlier task in the same document already edits, the entry says so, and the Doc-sync task verifies it against the implementation instead of editing it again.
- Q2 — The Doc-sync task's document list carries the eight affected documents only. A per-entry "N/A for this document" note in Documentation impact records a document that was considered and is unaffected; it is not a list entry.
- Q3 — Ruling M4 also generalises the Angle 2 bullet "For cross-phase tasks: are dependency annotations present and accurate?" to every task with a `Depends on` line (Step 2.3, wording only).
- Q4 — The task example gains a Dependency note in its Context section, as generate-task's Phase 2 DONE requires once a task carries `Depends on` (Step 2.2).
- Q5 — generate-task's Phase 3 Step 2 Schema E example table shows three rows, matching the reviewer's three angles (Step 4.1 scope); the four-row tables in generate-plan and generate-guide stay.
- Q6 — "List-only fallback" has two meanings and no third: within a Doc-sync run, a decision that fits no listed document is listed under Decisions needing a home and written nowhere; in a run without a Doc-sync task, the roll-up classifies each DONE task's decision as local or needs a home by the D3 criterion and writes nothing — no promoted outcome exists there.
- C2 — Step 4.2's document-language rule is a generation-side rule. Angle 3 mode 2 does not cite it, because the reviewer cannot see whether the user asked for another language; its anchors stay CODE ARTIFACTS LANGUAGE and the target document's own language. The rule mirrors generate-plan's exception: the plan document's language unless the user explicitly requests otherwise. Step 4.2's Done-when reads accordingly.
- C3 — Angle 3 carries its own not-a-finding sentence: a preference no loaded CLAUDE.md states is not a finding. It bounds the passing statement and is not a fourth failure mode; "exactly three modes" holds.
- The guard task depends on every Phase 1–4 task (`Depends on: Task 1-10`): Phase 5 needs those phases complete, not merely the anchors present.

## Open Questions

None. The rulings in [Design decisions](#design-decisions) close every
question raised during design. If the implementing session finds one of them
contradicted by the code, stop and report it as a plan-level issue rather
than resolving it locally.
