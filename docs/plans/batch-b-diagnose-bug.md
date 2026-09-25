# Plan: Batch B — diagnose-bug skill, /kenspc-diagnose, REVIEW_SCOPE=changes

Target: this repository (`kenspc` plugin), on top of v3.6.0 (`a1ec087`).
Release: 3.7.0 — a new command is a command-surface change. This batch makes
no version bump and no tag; its CHANGELOG entry goes under a
`## 3.7.0 — unreleased` heading.

This document is the complete specification. The design was locked in the
KENSPC Workbench and checked against the repository in a Claude Code session
on 2026-09-25; every ruling it depends on is recorded in
[Design decisions](#design-decisions) so the implementing session needs
nothing beyond this file and the repository.

## Objective

1. A `diagnose-bug` skill with `/kenspc-diagnose` for a bug the user has
   observed: reproduce it with a test that fails on the current code (or
   record the manual steps and why no failing-capable test exists), find the
   root cause — through a hypothesis loop when it is not obvious — and write
   `docs/tasks/<name>.md` for `/kenspc-task-implement`: a fix task, a
   regression-test task for the adjacent cases the diagnosis found, and a
   Doc-sync task when durable documents are affected. When the fix needs a
   decision `task-implementer` would stop on — a new dependency, an API
   contract change, a database schema change, a project configuration
   change — the skill writes a brief for `/kenspc-plan` instead.
2. `REVIEW_SCOPE=changes` defined: the orchestrating skill computes the
   change set once, read-only, records it as `RUN_DIR/change-set.md`, and
   the five reviewers, code-fixer, and regression-verifier work from that
   file. When the change set is uncommitted, code-fixer applies its fixes
   and commits nothing.

**In scope:** B-1 to B-9 of the locked design (below); the reminder hook's
messages for `docs/tasks/` and `docs/briefs/`; two guard extensions with no
change to the guard or self-test counts; the documentation the change
requires.

**Out of scope:** batch C (prototypes) and anything only it needs; roadmap
items 1 and 3–9; any new agent; any new CONTEXT key; any edit inside a
byte-identity section other than the B-8 edits to the five reviewers'
CONTEXT YOU WILL RECEIVE, PREREQUISITES, and FILE COVERAGE sections
(identical in all five); the canonical blocks in the two review skills;
behavior changes to `generate-task`, `task-implement`, `task-implementer`,
or `task-document-reviewer`; any question to the user during
`/kenspc-task-implement`, which stays unattended.

### The locked design (B-1 to B-9)

Restated for reference. The rulings below refine these points; they do not
reopen them.

- **B-1 Naming.** Skill `diagnose-bug`, command `/kenspc-diagnose`,
  `disable-model-invocation: true`, the shape of the six existing commands.
- **B-2 Three tiers**, stated in the description and the body. Tier 1: a fix
  that touches one file and needs no new regression test is made directly,
  not through the skill (the line README's "Small fixes can skip all skills"
  and task-implement's "single specific task: just do it directly" already
  draw). Tier 2: everything else goes through the skill. Tier 3: a fix that
  touches an API contract, a database schema, a new dependency, or project
  configuration escalates to a brief; no task document is written. The four
  categories are `task-implementer`'s AUTONOMY BOUNDARIES stop conditions,
  minus the two that are relative to a task document; cited in prose, not
  byte-locked.
- **B-3 Reproduction cannot be skipped; test first.** When no failing-capable
  test can be written (hardware, a real device, BLE), the manual reproduction
  steps and the reason are recorded, in the shape of `task-implementer`'s
  QUALITY CHECKLIST design-concern note and `regression-verifier`'s
  SPOT-CHECK — no new concept.
- **B-4 Hypothesis loop.** Skipped when the reproduction shows the root
  cause; otherwise three to five hypotheses listed at once, each with its
  verification method, verified in turn, converging on one root cause.
- **B-5 Output** `docs/tasks/<name>.md` that `/kenspc-task-implement`
  accepts (its Phase 1 Step 1 validation: `### Task N` entries with
  `**Status:**`): a diagnosis record (symptom, reproduction or manual steps,
  root cause, the hypotheses tried, the tier) plus the tasks — fix,
  regression tests, Doc-sync. Doc-sync follows batch A: affected durable
  documents determined by the project's CLAUDE.md (table, then prose, then
  README.md and CLAUDE.md); when there are any, `### Task N: Doc-sync` with
  `Depends on: Task 1-<N-1>` from generate-task's template; otherwise
  `N/A — <reason>` and no task.
- **B-6 Exit.** Hand over to `/kenspc-task-implement` by default;
  interactive implementation stays available (the user says they will do it
  themselves or step by step: no dispatch, the task document is still
  written).
- **B-7 Triggers** in English and Chinese. The description blocks casual
  "what does this error mean", "what is this stack trace", and "check this
  code for bugs" (the last belongs to task-review): the skill triggers only
  when the user wants an observed bug fixed. Tier 1 is blocked in the
  description too.
- **B-8** The roadmap "Next minor" item defining `REVIEW_SCOPE=changes` is
  part of this batch: the orchestrator computes one change set and the five
  reviewers review the same set; a standalone review no longer commits the
  user's uncommitted work.
- **B-9 Release.** 3.7.0; CHANGELOG under `## 3.7.0 — unreleased`; the
  version is bumped at release, not in this batch; no tag here.

## Background

`docs/roadmap.md` lists batch B as the next planned batch and, under "Next
minor", the item that defines `REVIEW_SCOPE=changes`. Three observations
from real runs shape the rulings:

- **The change set is computed five times.** With no task document, each
  reviewer runs its own `git status`, `git diff`, and `git log` and reviews a
  slightly different set (README, Known behavior). The scratch-probes
  acceptance run had to pin the set through CUSTOM_INSTRUCTIONS.
- **An uncommitted change under review was committed by the run.** In the
  v3.5.1 acceptance's Windows run — observation 2 of the W-F4 acceptance
  report, which stayed in that acceptance session and is not filed under
  `docs/dry-runs/`; reconstructed from the run's transcript on 2026-09-25 —
  `code-fixer` committed the reviewed, uncommitted `Program.cs` unchanged as
  `5b4f1d4` "to give its fix commits a base", then made three fix commits on
  top of it. The orchestrator committed only `.gitignore` (the one-time
  run-directory commit). In its trace `code-fixer` said the skill did not say
  how fix commits should handle a reviewed change that is still uncommitted,
  and that it found no guidance in the README or CHANGELOG. The roadmap
  item's wording ("a standalone review stops committing the user's
  uncommitted changes first") reads as an orchestrator behavior; it was
  `code-fixer`'s own workaround for a silent contract. This batch writes the
  contract (D7).
- **The implementer has no probe convention.** In batch A,
  `task-implementer` ran its mutation checks on the project's own `src/`
  files in place (`docs/dry-runs/batch-a-acceptance.md` § 8; roadmap item 9,
  last paragraph). A diagnosis runs before any run directory exists and
  needs a place for its probes that is neither the project's source tree nor
  a third copy of the run-directory block (D4).

## Design decisions

Rulings made by the maintainer on 2026-09-25. Each one is binding for this
batch; the implementing session applies them, it does not reopen them. The
numbering follows the design session's ruling table; D3 there was folded
into M6, so the D series runs D1, D2, D4–D7.

### Mismatches between the locked design and the repository (M1–M19)

| # | Question | Ruling | Consequence |
|---|---|---|---|
| M1 | `task-implementer`'s AUTONOMY BOUNDARIES are written relative to a task document ("not mentioned in the task document", "beyond what the task specifies", "unless the task explicitly requires it"); a diagnosis has no task. | The four tier-3 categories are reworded without the task qualifiers — a new dependency; a change to an existing API contract (parameters, return type, error codes); a database schema change; a project configuration change (tsconfig, eslint, prettier, and the like) — with a Why naming their source. | Step 1.1 |
| M2 | task-implement validates a task document by its `**Status:**` markers; `task-implementer`'s PREREQUISITE CHECK 5 marks a document that has both Status markers and a Phase/Step structure as ambiguous and BLOCKED. A diagnosis record written as "Step 1 / Step 2" or split into phases would trip it. | The record is one `## Diagnosis` section with fixed bold labels (see Fixed strings); manual reproduction steps are an ordinary numbered list; no `Phase N` or `Step N` heading appears anywhere in the document. | Step 1.1 |
| M3 | generate-task's Doc-sync template is plan-anchored ("the plan's Documentation impact", "<causing plan step>"), and B-5 says the affected documents are determined from CLAUDE.md but not where that determination is written down. | The diagnosis record carries a `Documentation impact` element in the plan's two forms — a list, or `N/A — <reason>` — determined by generate-plan's rule (the project CLAUDE.md's documentation table, otherwise the documents it names in prose, otherwise README.md and CLAUDE.md). The Doc-sync task is written from generate-task's template by reference, with two substitutions: "the plan's Documentation impact" reads "the diagnosis's Documentation impact", and the causing entry is a task, not a plan step. No second copy of the template. | Steps 1.1, 3.1 |
| M4 | With the reproduction test written before Task 1, a separate regression-test task has no content unless defined; `task-implementer` already requires tests for the code a fix task writes. | Task 1 (Fix) makes the root-cause fix and turns the reproduction test green. Task 2 (Regression tests, `Depends on: Task 1`) writes one failing-capable test per adjacent case the record lists — boundaries and sibling code paths the root cause implicates. When the record lists no adjacent case, Task 2 is omitted and the record says so. Doc-sync is `Depends on: Task 1-<N-1>`, or `Depends on: Task 1` when Task 1 is the only other task. | Step 1.1 |
| M5 | Batch A's task document is committed as a baseline by `task-document-reviewer` (v3.5.1, M-F5); with no reviewer here (D2) an untracked task document would be swept whole into Task 1's commit. | The skill commits the task document itself before the exit: `docs: add task <name>`, adapted to the project's commit conventions, staging only that file. | Step 1.1 |
| M6 | `hooks/scripts/remind-plan-skill.sh` names only generate-task for `docs/tasks/*.md` and only generate-brief for `docs/briefs/*.md`; diagnose-bug writes both directories. | Both messages are reworded in this batch to name every skill that writes there today — tasks: generate-task from a plan, or diagnose-bug from a diagnosis; briefs: generate-brief, or diagnose-bug when a diagnosed fix needs planning. Batch C adds `prototype` when it lands. | Step 1.3 |
| M7 | task-review defines "changes" as "recent changes (uncommitted, staged, or recently committed)", and each reviewer derives the set itself. | Defined in D7. | Steps 2.1–2.4 |
| M8 | The roadmap says a standalone review "stops committing the user's uncommitted changes first"; no live file instructs any commit. | Source confirmed (Background): `code-fixer`, not the orchestrator, made a baseline commit of the reviewed uncommitted file because the contract was silent. The rule therefore lands in `code-fixer` (D7 iv), the orchestrator's read-only rule is stated as well (D7 iii), and the CHANGELOG's source line records what happened. The roadmap item leaves the file when this batch ships. | Steps 2.1, 2.3, 4.3 |
| M9 | The reviewers' FILE COVERAGE section lists files "from git diff, git status, or the task document"; with a change-set file that sentence reopens the drift B-8 closes, but the standing constraint allowed B-8 only PREREQUISITES and CONTEXT YOU WILL RECEIVE. | The permission is extended to FILE COVERAGE for one clause: "from `RUN_DIR/change-set.md` when it exists, otherwise …". Identical in all five; `check-review-agent-drift.sh` stays green. | Step 2.2 |
| M10 | `code-fixer` and `regression-verifier` have no "changes" branch in PREREQUISITES; `regression-verifier`'s check 5 ("No regressions in non-fix files") needs the set's boundary. | Both read `RUN_DIR/change-set.md` when REVIEW_SCOPE is "changes", and their PREREQUISITE CHECK also stops when that file is missing in that mode. | Steps 2.3, 2.4 |
| M11 | Counting and describing sentences: CLAUDE.md says "six skills" in three places and "the other five skills" once; release-checklist row 1 says "6"; `plugin.json` says eleven subagents "drive brief generation, plan generation, …", and diagnosis uses no agent. | The counts become seven and six. `plugin.json` says what the skills cover — brief generation, plan generation, task decomposition, bug diagnosis, batch implementation, multi-angle review — and that eleven reusable subagents do the review, fix, verification, and implementation work. `marketplace.json`'s description gains bug diagnosis. | Steps 4.1, 4.2, 4.4 |
| M12 | A fix task for a bug that can only be reproduced manually cannot be verified by `task-implementer`'s build / test / lint; a DONE would be `requirements-reviewer`'s "partial completion marked done". | Task 1's acceptance criteria then read: build and lint pass; the manual reproduction steps no longer show the symptom — verified by the user after the run; the implementer records that criterion as not verified in the task's `**Implementation notes:**` block, the QUALITY CHECKLIST's design-concern form. The exit message says Task 1 cannot be verified unattended. The default exit is unchanged. | Step 1.1 |
| M13 | File name: generate-task derives `{base}-tasks.md` from the plan's name; B-5 says `docs/tasks/<name>.md`. | `docs/tasks/<name>.md`, `<name>` a kebab-case slug of the symptom; no suffix, no prefix. When the file exists, ask: overwrite, create alongside, or cancel (generate-brief's conflict check). The same `<name>` names the tier-3 brief and the diagnosis run directory's suffix. | Step 1.1 |
| M14 | B-6 hands the task document to `/kenspc-task-implement` by default; every existing hand-off only suggests the next command (generate-brief: "do not auto-trigger generate-plan"), and task-implement's description asks for an explicit request. | The exit asks one question: run `/kenspc-task-implement <path>` now, or implement interactively. On "run", the skill invokes the task-implement skill through the Skill tool with the path; task-implement's Step 3 batch gate then confirms once more — its own contract, unchanged. On "interactively", the skill stops and the document stands. In a session that cannot ask (a reminder to work without stopping), the skill writes the document, suggests the command, and stops. | Step 1.1 |
| M15 | Tier 1 cannot be judged before the fix scope is known, yet B-2 keeps tier 1 out of the skill; inside the skill a reproduction test always exists, so "needs no new test" cannot hold there. | Tier 1 is a trigger-time judgment only: the user can already name the fix, or the request is evidently a one-file change with no test to add — the skill is not invoked (task-implement's "single specific task: just do it directly" is the precedent). After diagnosis the record's tier is 2 or 3. The description carries the three exclusions: explaining an error or stack trace, finding bugs in code, a one-file fix the user can name. | Step 1.1 |
| M16 | B-3 does not say what happens when the bug cannot be reproduced. | The skill stops and asks the user for what is missing, listing what it tried; it writes no file and commits nothing. | Step 1.1 |
| M17 | Guards: diagnose-bug writes `### Task N: Doc-sync` and `Documentation impact`, so it belongs in `check-doc-sync-anchors.sh`'s groups; the B-8 file name `change-set.md` appears in eight files, three of them outside any guard. | `check-doc-sync-anchors.sh` gains the skill in both groups; its counts are unchanged, since the fixture mutates the task example. `check-run-contract.sh` gains check 5: the literal `change-set.md` is present in `task-review/SKILL.md`, `code-fixer.md`, `regression-verifier.md`, and `requirements-reviewer.md` (the drift guard carries it to the other four reviewers), with a self-test mutation. `guards run: 10` and `self-tests run: 9` stay. | Steps 3.1, 3.2 |
| M18 | README's "Small fixes can skip all skills and be implemented directly" states no criterion. | It states tier 1's; Recommended Workflow gains the diagnosis entry path. | Step 4.2 |
| M19 | The run-directory block's one-time `.gitignore` commit moves HEAD; a change set of "commits ahead of upstream" computed afterwards would include it. | The change set is computed before the run-directory preparation and pinned by SHA; paths under `.kenspc/` are excluded. (An uncommitted user edit to `.gitignore` is swept into that chore commit today — 3.5.x behavior, outside this batch.) | Step 2.1 |

### Architecture choices (D1, D2, D4–D7)

| # | Choice | Ruling | Why |
|---|---|---|---|
| D1 | Where the reproduction test lives before the fix. | The skill writes it during its Reproduce phase, in the project's test tree under the project's framework and file conventions (a collectable name — it is a test), runs it to show the failure, and commits it alone: `test: reproduce <symptom>`, adapted to the project's commit conventions. Task 1 turns it green. The branch is red between the two commits. | Artifacts, not wording: a working-tree file is lost to a stash, a checkout, or another change in progress; a commit is what `task-implementer`'s `git log` sees. A red test is the true state of the code until the fix lands, and stays true when Task 1 is BLOCKED. The red interval is documented under Known behavior. |
| D2 | Whether the task document goes through `task-document-reviewer`. | No. The user's confirmation of the task list is the human gate; task-implement's Step 3 batch gate follows. The reviewer's Angle 3 checks the skill would lose — language carry-over, undecided git steps — become the skill's own writing rules. | The reviewer requires SOURCE_PATH to be a plan and cross-references its Implementation Steps; there is no plan. generate-brief is the precedent for a discovery-shaped artifact with no review phase; the document is at most three tasks long and the user is present throughout. Cost: no automated vague-language check; the Quality bar and the confirmation carry it. |
| D4 | Where diagnosis probes go. | When a hypothesis needs a probe, a copy, or a mutant, the skill prepares a run directory as the run-directory preparation in `skills/task-review/SKILL.md` (the `canonical:run-dir` block) prescribes, by reference: the run-id's suffix is `diagnose-<name>` in place of a task document's name, and the skill writes only under `RUN_DIR/scratch/orchestrator/<n>/`, under that block's naming and numbered-attempt rules; the record names the directory. The diagnosis modifies no tracked file; the reproduction test is the only project file it creates. A "does this change remove the symptom" experiment runs on a copy under scratch, and a mutant used as evidence follows the block's three-step mutation rule. | No third copy of the block — `task-document-reviewer` already points at generate-task's template the same way; no new directory tree and no second ignore logic; the diagnosing session is the orchestrator, so `scratch/orchestrator/` is its slot. The harness's session scratchpad was rejected for probes: the release checklist fails copies of project files there, and its path is harness-private. |
| D5 | Tier 3: what is written, and where. | A brief at `docs/briefs/<name>.md` (a CLAUDE.md-specified location first), starting `# Requirement Brief:` — generate-plan's detection anchor — in generate-brief's template: Outcome (the corrected behavior), Scope, Failure Modes (the symptom and the adjacent cases), The Hard Part (the root cause, the category that escalated it, the fix directions considered), Constraints, Context (the reproduction, the hypotheses and their outcomes, the reproduction test's path and commit), Discovery Notes (produced by diagnose-bug from a diagnosis; no discovery conversation; no `Discovery Mode:` field). The skill suggests `/kenspc-plan <path>` and does not invoke it. No task document. The brief is not committed, as generate-brief's is not. | "Brief or plan" resolves to "brief, then `/kenspc-plan`": a contract or schema change is a decision generate-plan's discovery exists to make; the skill has the evidence, not the mandate. The reproduction test is already committed (D1), so the plan inherits it. `Discovery Mode:` is the contract of generate-brief's Phase 1 modes, which this skill does not run; release-checklist row 9 greps it in `/kenspc-brief` output only. |
| D6 | Task-document language. | The language of the diagnosis conversation, unless the user asks otherwise (generate-brief's rule). Anchors stay as written whatever the language: the `**Status:**` line and its value, `Depends on:`, `### Task N: Doc-sync`, and the `## Diagnosis` labels. Text the implementer will carry into code artifacts — commit-message text, identifiers, test names — is English in the task text. The tier-3 brief follows the same rule. | There is no plan to inherit from, and the conversation is the source. With no Angle 3 review (D2), the skill's own writing rule keeps code-artifact text in English. |
| D7 | `REVIEW_SCOPE=changes`. | (i) **Change set.** `uncommitted` when `git status --porcelain` lists any path (ignored paths never appear; paths under `.kenspc/` are dropped): the set is those paths — staged, unstaged, and untracked — against HEAD's SHA. `commits` when the tree is clean: `<upstream>..<HEAD>` when an upstream exists and the range has commits, otherwise `<HEAD~1>..<HEAD>`. CUSTOM_INSTRUCTIONS naming commits, a range, or paths override. Every ref is pinned by SHA, and the set is computed before the run-directory preparation (M19). (ii) **Form.** `RUN_DIR/change-set.md`, a fixed file and no new CONTEXT key: Mode, Base or Range, the diff command, and a Status / Path table — not the diff text. The five reviewers, `code-fixer`, and `regression-verifier` read it when RUN_DIR is given and REVIEW_SCOPE is "changes"; a standalone reviewer without RUN_DIR keeps deriving its scope from git. (iii) **Read-only computation.** The orchestrator computes the set with read-only git commands: no commit, stash, checkout, add, reset, or any other change to the working tree, the index, or refs. (iv) **Uncommitted mode.** `code-fixer` applies every fix to the working tree and commits nothing — no baseline commit of the user's change, no fix commit, no stash; FIXED rows carry `—` in Commit; its reply and the final report say the fixes are uncommitted and name the files; `regression-verifier`'s check 4 reads the working-tree diff of the files the FIXED rows name. In `commits` mode and in REVIEW_SCOPE "task", one commit per fix as today. | One file written once is the same set for all seven agents, and RUN_DIR already replaced two keys for the same reason. The read-only rule and the no-commit rule answer the Windows observation at its source: the change under review is the user's uncommitted work, and a commit made to give the fixes a base — or a per-file `git add` that carries the user's hunks — decides for the user what is committed and under which message. The cost is the per-fix commit granularity in that mode; Schema B still records every fix by row, and the user commits after reading the diff. |

### Standing constraints

- Every new check is written in rubric form: one sentence stating what
  passing looks like, then named failure modes. No generic checklist items.
- Rules are rationale-anchored ("Why: …" prose), not imperatives; no `MUST`
  / `NEVER` / `CRITICAL`, no inline effort or reasoning tokens, no model
  names (`check-no-model-names.sh` scans `skills/`, `agents/`, `commands/`,
  and `shared/`, so the new skill and command are covered).
- No edit inside any byte-identity section except the B-8 edits to the five
  reviewers' CONTEXT YOU WILL RECEIVE, PREREQUISITES, and FILE COVERAGE
  sections, which are byte-identical across all five. The canonical blocks
  (`canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`,
  `canonical:verdict-shared`), the code-craft canonical paragraphs, and the
  reviewers' other shared sections are untouched. Every guard stays green:
  `check-canonical-dispatch.sh`, `check-verdict-shared.sh`,
  `check-code-craft-canonical.sh`, `check-quality-reviewer-bullet-structure.sh`,
  `check-notes-format-sync.sh`, `check-review-agent-drift.sh`,
  `check-doc-sync-anchors.sh`, `check-no-model-names.sh`, `check-json.sh`,
  and `check-run-contract.sh` (the last two extended by Phase 3).
- No new agent (`plugin.json` says "Eleven reusable subagents"): the
  diagnosis runs in the main session, which keeps the conversation with the
  user and the probes in one context.
- No new CONTEXT key. `change-set.md` is a fixed file under RUN_DIR, the
  form RUN_DIR itself took in v3.5.
- The run-directory preparation is written once, in the `canonical:run-dir`
  block of the two review skills; diagnose-bug references it and carries no
  copy.
- `effort:` frontmatter is unchanged in every file (release-checklist
  pre-flight diff); the new skill has none and follows the session.
- Per-skill `version: 3.0.0` in every skill, the new one included — it
  denotes the architecture generation (CLAUDE.md).
- Plugin Design Lessons apply: phase transitions rest on artifacts (a
  committed test, a filled record, a committed task document), and no hook
  guards workflow state.
- The dogfood: the task document for this batch comes from `/kenspc-task`
  on this spec, which now generates the Doc-sync task itself from the
  Documentation impact below. It is not added by hand.

## Fixed strings

These strings are load-bearing: guards assert their presence, the release
checklist greps for them, and agents parse them. Spell them exactly as
given, in every file that carries them.

| Anchor | Exact form | Carried by |
|---|---|---|
| Doc-sync task heading | `### Task N: Doc-sync` (N = the last task number) | `diagnose-bug/SKILL.md` (by reference to generate-task's template), diagnosis task documents |
| Dependency line | `Depends on: Task 1-<N-1>` (ASCII hyphen); `Depends on: Task 1` for a single prior task | diagnosis task documents |
| Documentation impact | `Documentation impact` in SKILL prose; the record label `**Documentation impact:**` whose body is a list or the single line `N/A — <reason>` | `diagnose-bug/SKILL.md`, diagnosis task documents |
| Diagnosis record | `## Diagnosis`, with the labels `**Symptom:**`, `**Reproduction:**`, `**Root cause:**`, `**Hypotheses:**`, `**Fix scope:**`, `**Adjacent cases:**`, `**Tier:**`, `**Documentation impact:**`, `**Probes:**`, in that order | `diagnose-bug/SKILL.md`, diagnosis task documents |
| Tier line | `**Tier:** 2 — <files in Fix scope; no contract, schema, dependency, or configuration change>` in a task document; tier 3 is stated in the brief's The Hard Part | diagnosis task documents, tier-3 briefs |
| Brief header | `# Requirement Brief:` as the first line | tier-3 briefs |
| Change-set file | `RUN_DIR/change-set.md`; `Mode: uncommitted` or `Mode: commits`; `Base:` (uncommitted) or `Range:` (commits); `Diff:`; a `Status \| Path` table | `task-review/SKILL.md`, the 5 reviewers, `code-fixer.md`, `regression-verifier.md`, `check-run-contract.sh` |
| Diagnosis run-id | `<YYYYMMDD-HHMMSS>-diagnose-<name>` under `.kenspc/runs/` | `diagnose-bug/SKILL.md`, README |
| Commit subjects | `test: reproduce <symptom>`; `docs: add task <name>` (both adapted to the project's commit conventions) | `diagnose-bug/SKILL.md` |
| Uncommitted FIXED row | Commit cell `—` | `code-fixer.md`, `regression-verifier.md` |

## Implementation Steps

Phases 1 and 2 are independent of each other. Phase 3 needs both (the
anchors and the file name it guards must exist). Phase 4 comes last.

### Phase 1: The diagnose-bug skill (B-1 to B-7)

**Step 1.1: Write `skills/diagnose-bug/SKILL.md`**

- File: `plugins/kenspc/skills/diagnose-bug/SKILL.md` (new). Structure and
  tone of the existing skills: frontmatter, Trigger Phrases, Quality bar,
  Prerequisites, Arguments, then phases with Goal / Inputs / DONE when /
  Constraints; rules carry their Why. File references use
  `${CLAUDE_PLUGIN_ROOT}`.
- Frontmatter: `name: diagnose-bug`; `version: 3.0.0`;
  `argument-hint: <observed bug, or path to a bug report>`; no `effort:`;
  `description` in substance (wrap as the other skills do):

  > Reproduce and diagnose a bug the user has observed (修 bug / 排查 bug),
  > then write a task document for /kenspc-task-implement — or a brief for
  > /kenspc-plan when the fix touches an API contract, a database schema, a
  > new dependency, or project configuration. Use only when the user asks to
  > fix a specific bug they have observed: a wrong result, a crash, an error
  > they can trigger. Not for explaining an error message or a stack trace
  > (answer directly), not for finding bugs in code (use task-review), and
  > not for a fix the user can already name that touches one file and needs
  > no new test (just make it). Trigger on: "fix this bug", "this crashes
  > when", "why does this return the wrong", "帮我修这个 bug",
  > "这个 bug 怎么修", "排查一下为什么", "诊断一下这个问题", or invokes
  > /kenspc-diagnose directly.
- Trigger Phrases section: the positive phrases above (English and Chinese,
  with a few more of each); an "Avoid triggering" list with the three
  exclusions from the description, plus a feature request phrased as a bug
  ("it should also …" — generate-plan or generate-brief), and the tier-1
  line with its reason: a fix the user can name that touches one file and
  needs no new test is made directly, as task-implement's single-task rule
  already says (ruling M15).
- Quality bar, in substance: a useful diagnosis reproduces the bug before
  explaining it, names one root cause with the evidence that rules the
  alternatives out, and leaves a task document (or a brief) an implementer
  can act on without diagnosing again. A fix proposed without a reproduction
  is a guess.
- Arguments: `BUG` — free text describing what was observed and how it was
  triggered, or a file path (an issue export, a log, a bug report) that the
  skill reads. With no arguments, ask what was observed and how to trigger
  it.
- Phase 1, Reproduce. Goal: a test that fails on the current code for the
  reason the bug describes, or the manual reproduction steps and the reason
  no failing-capable test exists. Inputs: BUG; the project's CLAUDE.md,
  README, and config files (read silently first — they name the test
  framework and its file conventions); the code. DONE when the test is
  written in the project's test tree under the project's framework and
  naming conventions (a collectable name — it is a test), has been run and
  failed for that reason, with the failure summarized for the record, and
  has been committed alone as `test: reproduce <symptom>` adapted to the
  project's commit conventions, staging only that file (ruling D1); or, when
  no failing-capable test can be written — hardware, a real device, BLE, no
  test framework configured — the record holds the manual steps and the
  reason, in the shape of `task-implementer`'s QUALITY CHECKLIST
  design-concern note (B-3). Why: the test is the artifact the next phase
  and Task 1 rest on. With no test framework configured, a plain reproduction
  script under the diagnosis run directory's scratch (ruling D4) may support
  the manual steps; it is evidence, not the test. When the bug cannot be
  reproduced after trying what BUG describes, stop and ask the user for what
  is missing, listing what was tried; write no file and commit nothing
  (ruling M16). Constraint: this phase modifies no tracked file; the
  reproduction test is the only project file it creates.
- Phase 2, Diagnose. Goal: one root cause with the evidence, the fix scope,
  the adjacent cases, the tier, and the documentation impact. DONE when the
  record fields Root cause, Hypotheses, Fix scope, Adjacent cases, Tier, and
  Documentation impact can be filled. Hypothesis loop (B-4): when the
  reproduction shows the root cause directly, Hypotheses records "none — the
  root cause was visible on reproduction"; otherwise list three to five
  hypotheses at once, each with how it will be verified (a probe, a log line,
  a bisect, reading a code path), verify each in turn, record each outcome
  with its evidence, and converge on one; when none survives and no new
  hypothesis is grounded in evidence, stop and ask the user. Probes: when a
  hypothesis needs a probe, a copy, or a mutant, prepare a run directory as
  the run-directory preparation in
  `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` prescribes — the block
  between `<!-- canonical:run-dir:start -->` and `<!-- canonical:run-dir:end -->`,
  its RUN_DIR, Scratch space, and Ignore check bullets — with the run-id's
  suffix `diagnose-<name>` in place of a task document's name; the diagnosing
  session is the orchestrator, so everything it writes goes under
  `RUN_DIR/scratch/orchestrator/<n>/` under that block's naming and
  numbered-attempt rules (ruling D4). The diagnosis modifies no tracked file;
  a "does this change remove the symptom" experiment runs on a copy under
  scratch, and a mutant used as evidence follows the block's three-step
  mutation rule. Why: batch A's implementer mutated the project's own source
  in place, and a run that stops between the mutation and the restore leaves
  the user's code mutated. Tier (B-2, ruling M1): tier 3 when the fix
  requires any of — a new dependency; a change to an existing API contract
  (parameters, return type, error codes); a database schema change; a
  project configuration change (tsconfig, eslint, prettier, and the like);
  otherwise tier 2. Why: these are the decisions `task-implementer` stops on
  (its AUTONOMY BOUNDARIES), so a task document carrying one would be
  BLOCKED in an unattended run; deciding them is plan work. Fix scope: the
  files the fix touches — the evidence for tier 2 and Task 1's boundary.
  Adjacent cases: boundaries and sibling code paths the root cause
  implicates, each a candidate regression test; an empty list is stated.
  Documentation impact (ruling M3): the durable documents the fix makes
  stale, determined as generate-plan determines its element — the project
  CLAUDE.md's documentation table where one exists, otherwise the documents
  it names in prose, otherwise README.md and CLAUDE.md — as a list (path,
  section where known, what changes) or `N/A — <reason>`.
- Phase 3, Produce. Two outcomes by tier.
  - Tier 2: a task document at `docs/tasks/<name>.md`, a CLAUDE.md-specified
    task-document location taking precedence; `<name>` is a kebab-case slug
    of the symptom; an existing file is a question — overwrite, create
    alongside, or cancel (ruling M13). Language per ruling D6. Content, in
    order: a title; a Dependency note (as generate-task writes one when any
    task has `Depends on`); `## Diagnosis` with the labels from Fixed strings
    — `**Reproduction:**` names the test's path and commit and summarizes the
    failure, or gives the manual steps as a numbered list and the reason no
    failing-capable test exists; `**Probes:**` names the diagnosis run
    directory, or `none` — with no `Phase N` or `Step N` heading anywhere
    (ruling M2); then `## Tasks`. `### Task 1: Fix <root cause>`,
    `**Status:** TODO`: the root cause, the reproduction test's path, the
    files in Fix scope; acceptance criteria: the reproduction test passes,
    the project's full test suite and its build and lint pass, no file
    outside Fix scope is modified (the task document's status update aside).
    For a manual reproduction, ruling M12's form instead. `### Task 2:
    Regression tests for <adjacent cases>`, `Depends on: Task 1`: one test
    per listed adjacent case, in the project's framework and conventions,
    each able to fail if the behavior it covers broke (the falsifiability
    rule `task-implementer` already applies); omitted when Adjacent cases is
    empty, which the record then says (ruling M4). `### Task N: Doc-sync`
    when Documentation impact lists documents: written from the Doc-sync Task
    template in `${CLAUDE_PLUGIN_ROOT}/skills/generate-task/SKILL.md` with two
    substitutions — "the plan's Documentation impact" reads "the diagnosis's
    Documentation impact", and each entry's cause is the task that makes the
    change (`Task 1`) — with `Depends on: Task 1-<N-1>`, or `Depends on:
    Task 1` when Task 1 is the only other task (ruling M3). Confirm before
    writing: present the task list as generate-task's Phase 2 does (task,
    files, one-line criteria; the Doc-sync task like any other) and apply
    adjustments; the record is written as diagnosed, and the user may correct
    a fact in it. After writing, commit the document alone: `docs: add task
    <name>`, adapted to the project's commit conventions, staging only that
    file (ruling M5). Why: `task-implementer` commits each task's status into
    this file, and without a baseline its first commit would carry the whole
    document.
  - Tier 3: a brief per ruling D5 at `docs/briefs/<name>.md`, starting
    `# Requirement Brief:`, in generate-brief's template with the mapping D5
    gives; the reproduction test's path and commit in Context; no
    `Discovery Mode:` field; no task document; not committed. Tell the user
    the path and suggest `/kenspc-plan <path>`; do not invoke it.
- Exit (ruling M14), tier 2 only: ask whether to run
  `/kenspc-task-implement <path>` now or implement interactively. On "run",
  invoke the task-implement skill through the Skill tool with the path
  (its Step 3 batch gate confirms once more; that gate is its own). On
  "interactively", stop; the document stands. When the session cannot ask
  (a reminder to work without stopping), write the document, print the
  suggestion, and stop. For a manual reproduction, the exit message says
  Task 1 cannot be verified unattended.
- Writing rules for the document (ruling D6): the conversation's language
  unless the user asks otherwise; anchors as written; commit-message text,
  identifiers, and test names in English; concrete acceptance criteria (no
  "as appropriate", "if needed", "properly"); no branch, pull-request,
  rebase, or tag step unless the user asked for one — the default is commits
  on the current branch (README, Known behavior). Why: no reviewer runs on
  this document (ruling D2), so the checks `task-document-reviewer`'s Angle 3
  would make are made here.
- Phase transitions rest on artifacts: Phase 1 → 2 on the committed test
  (its hash) or the recorded manual steps; Phase 2 → 3 on the filled record;
  the exit on the committed task document or the written brief.
- Done when: the file exists with the frontmatter above and `version:
  3.0.0`; the description carries the three exclusions and the Chinese and
  English triggers; the three phases carry Goal, Inputs, DONE when, and their
  Whys; the tier categories, the reproduction rule, the hypothesis loop, the
  probe rule by reference to the `canonical:run-dir` block, the record
  labels, the two Doc-sync substitutions, the commit subjects, the exit
  question, and the writing rules are all present; `bash scripts/check-no-model-names.sh`
  exits 0; `claude plugin validate --strict ./plugins/kenspc` passes.
- Why: the skill is the whole of B-1 to B-7; every later step either points
  at it or documents it.

**Step 1.2: Add `commands/kenspc-diagnose.md`**

- File: `plugins/kenspc/commands/kenspc-diagnose.md` (new), the shape of the
  six existing command files: `name: kenspc-diagnose`; a one-line
  description ("Explicit entry point for the diagnose-bug skill — reproduce
  and diagnose an observed bug (修 bug) into a task document or a brief.");
  `argument-hint: <observed bug, or path to a bug report>`;
  `disable-model-invocation: true`; a body that reads
  `${CLAUDE_PLUGIN_ROOT}/skills/diagnose-bug/SKILL.md` and passes
  `$ARGUMENTS` through.
- Done when: the file matches the other commands line for line except name,
  description, argument hint, and skill path; `claude plugin validate
  --strict ./plugins/kenspc` passes.
- Why: commands are explicit entry points only; the skill's description
  owns the routing (v3.4.2).

**Step 1.3: Reword the reminder hook's task and brief messages**

- File: `plugins/kenspc/hooks/scripts/remind-plan-skill.sh`, the
  `*/docs/tasks/*.md` and `*/docs/briefs/*.md` branches only (ruling M6).
- Tasks message, in substance: a task document is normally written by a
  kenspc skill — generate-task (Skill tool or `/kenspc-task`) from a plan,
  which reads actual code for correct decomposition and self-reviews via
  review agent, or diagnose-bug (`/kenspc-diagnose`) from a diagnosed bug;
  if one of them has already been invoked, ignore this message.
- Briefs message, in substance: generate-brief (Skill tool or
  `/kenspc-brief`), which runs a structured discovery conversation against
  the shared discovery framework, or diagnose-bug (`/kenspc-diagnose`) when a
  diagnosed fix needs planning; same closing sentence.
- The plan and guide branches, the template exclusions, and the path
  normalization are unchanged.
- Done when: `printf '{"file_path":"/x/docs/tasks/a.md"}' | bash
  plugins/kenspc/hooks/scripts/remind-plan-skill.sh` prints the new tasks
  message naming both skills, the same for `/x/docs/briefs/a.md` and the
  brief message, `/x/docs/tasks/_template.md` prints nothing, and
  `/x/docs/plans/a.md` prints the unchanged plan message.
- Why: a reminder that names the wrong skill is a wrong instruction; both
  branches change now so batch C only adds to them.

### Phase 2: REVIEW_SCOPE=changes (B-8)

**Step 2.1: Define the change set in `task-review`**

- File: `plugins/kenspc/skills/task-review/SKILL.md`. Every canonical block
  stays byte-identical to `task-implement`'s.
- Arguments: replace "the review covers recent changes (uncommitted,
  staged, or recently committed) without a requirements reference" with a
  pointer to the change set Step 1 defines.
- Step 1, in the `REVIEW_SCOPE = "changes"` branch, before the run-directory
  block, a "Determine the change set" rule (ruling D7 i, iii; M19):
  - Read-only: `git status --porcelain`, `git diff --name-status`,
    `git rev-parse`, `git rev-list`, `git log`. No commit, stash, checkout,
    add, reset, or any other change to the working tree, the index, or refs.
    Why, in the skill's own words: a review run once committed the user's
    uncommitted change as a baseline for its fixes because nothing said what
    to do with it; the change set is the user's work, and the run reads it.
  - `Mode: uncommitted` when `git status --porcelain` lists any path — the
    set is every listed path (staged, unstaged, untracked; paths under
    `.kenspc/` dropped; ignored paths never appear), the base is HEAD's SHA,
    and the diff command is `git diff <sha> -- <paths>` with untracked files
    read whole.
  - `Mode: commits` when the tree is clean — the range is
    `<upstream sha>..<HEAD sha>` when `@{upstream}` resolves and the range
    has commits, otherwise `<HEAD~1 sha>..<HEAD sha>`; the set is
    `git diff --name-status <range>`; the diff command is
    `git diff <a>..<b> -- <paths>`.
  - CUSTOM_INSTRUCTIONS that name commits, a range, or paths override the
    default (mode `commits` with that range, or the named paths).
  - Compute and pin the SHAs before the run-directory preparation, so its
    one-time `.gitignore` commit is never part of the set.
  - Tell the user, in one line, what is under review: the mode and the base
    or range, with the file count.
- After the run-directory block: write `RUN_DIR/change-set.md` — the first
  file in the directory — in this shape (Fixed strings): a `# Change set`
  heading; `Mode: uncommitted` or `Mode: commits`; `Base: <sha>` or
  `Range: <sha>..<sha> (<how it was chosen>)`; `Diff: <command>`; a table
  with `Status` and `Path` columns, status as git prints it (`M`, `A`, `D`,
  `R`, `??`), paths relative to the repository root. Only in "changes" mode;
  a "task" run writes no such file. Why: the five reviewers, code-fixer, and
  regression-verifier read the set from that path; RUN_DIR is the one value
  the orchestrator already passes, so no key is added.
- Step 2: the CONTEXT keys are unchanged; one sentence notes that in
  "changes" mode RUN_DIR holds `change-set.md`.
- Step 5 (code-fixer): in `Mode: uncommitted` code-fixer applies fixes
  without committing and its FIXED rows show `—` in Commit (ruling D7 iv).
- Step 7 Schema F, Next steps: when the change set was uncommitted, one
  bullet says the fixes are in the working tree, uncommitted, naming the
  files, for the user to review and commit. In the PASS / FAIL bullets
  outside the `canonical:verdict-shared` markers, "fix commits" reads "the
  fixes (fix commits, or the uncommitted fixes of an `uncommitted` run)".
- Done when: the change-set rule, the file shape, the Step 5 note, and the
  Next steps bullet are present; `bash scripts/check-canonical-dispatch.sh`,
  `check-verdict-shared.sh`, and `check-run-contract.sh` exit 0.
- Why: one set, computed once and read-only, is what B-8 asks for; the
  file is the artifact the seven agents share.

**Step 2.2: Read the change set in the five reviewers**

- Files: `plugins/kenspc/agents/requirements-reviewer.md`,
  `edge-case-reviewer.md`, `quality-reviewer.md`, `bug-reviewer.md`,
  `test-reviewer.md`. Three shared sections change, identically in all five
  (ruling M9); no other section changes.
- CONTEXT YOU WILL RECEIVE, RUN_DIR bullet: add that with REVIEW_SCOPE
  "changes" it also holds `change-set.md`, the change set the orchestrator
  computed; see PREREQUISITES.
- PREREQUISITES step 3, in substance: if REVIEW_SCOPE is "changes" — with
  RUN_DIR, read `RUN_DIR/change-set.md`; its mode, base or range, files, and
  diff command define the change set; review those files and nothing else,
  and run its diff command for their content. Without RUN_DIR (standalone),
  run `git status`, `git diff`, `git diff --cached`, and
  `git log --oneline -10` as before. Why: five reviewers that each derive
  the set from git have reviewed five slightly different sets; one file
  written once is the same set for all.
- FILE COVERAGE: "list all files that were added or modified (from
  `RUN_DIR/change-set.md` when it exists, otherwise from git diff, git
  status, or the task document)".
- Done when: `bash scripts/check-review-agent-drift.sh` reports every shared
  section identical across the five; the OBJECTIVE, REVIEW CHECKLIST, and
  OUTPUT FORMAT sections are byte-identical to before.
- Why: the drift guard is the mechanical proof that the five still agree.

**Step 2.3: `code-fixer` reads the change set and commits nothing in uncommitted mode**

- File: `plugins/kenspc/agents/code-fixer.md`. The `canonical:stats-line`
  block and the `example:schema-b` block stay byte-identical (the example is
  a committed-mode example and keeps its hashes).
- PREREQUISITE CHECK: also stop, with the same message form, when
  REVIEW_SCOPE is "changes" and `RUN_DIR/change-set.md` is missing
  (ruling M10).
- CONTEXT YOU WILL RECEIVE, RUN_DIR bullet: in "changes" mode it also holds
  `change-set.md`.
- PREREQUISITES: 3. If REVIEW_SCOPE is "changes": read
  `RUN_DIR/change-set.md`; its files are the change under review and the
  boundary of the fixes; its Mode decides how fixes land.
- FIXING RULES (ruling D7 iv): each fix is a separate, focused commit when
  the change set is committed — `Mode: commits`, or REVIEW_SCOPE "task".
  When `change-set.md` says `Mode: uncommitted`, apply every fix to the
  working tree and commit nothing: no baseline commit of the user's change,
  no fix commit, no stash. A FIXED row's Commit cell is then `—`. Why, in
  the agent's own words: the change under review is the user's uncommitted
  work; a run has committed it as a baseline to give its fixes a base, and a
  per-file `git add` would carry the user's hunks into a fix commit — either
  way the run decides for the user what is committed and under which
  message. The user reads the working tree and commits.
- DONE CRITERIA and PER-ISSUE OUTPUT CONTRACT: a FIXED row references a
  real commit hash, or `—` in an uncommitted run. The final build / test /
  lint run after the last fix is unchanged.
- Reply: in an uncommitted run, one line saying the fixes are uncommitted
  and naming the files, after the statistics line.
- Done when: the six edits are present with the Why;
  `bash scripts/check-run-contract.sh` and `check-code-craft-canonical.sh`
  exit 0; the CODE-CRAFT PRINCIPLES header and its guard comment are
  untouched.
- Why: this is where the Windows observation is answered; the orchestrator
  never committed, the fixer did.

**Step 2.4: `regression-verifier` reads the change set and verifies uncommitted fixes**

- File: `plugins/kenspc/agents/regression-verifier.md`.
- PREREQUISITE CHECK: also stop when REVIEW_SCOPE is "changes" and
  `RUN_DIR/change-set.md` is missing (ruling M10).
- CONTEXT YOU WILL RECEIVE and INPUTS: `change-set.md` in "changes" mode.
- PREREQUISITES: 3. If REVIEW_SCOPE is "changes": read
  `RUN_DIR/change-set.md` for the set's boundary.
- VERIFICATION CHECKS item 4: review fix commits with `git log` and
  `git show` — or, when `change-set.md` says `Mode: uncommitted` and
  code-fixer committed nothing, the working-tree diff of the files the FIXED
  rows name (`git diff <base> -- <files>`, the base from `change-set.md`);
  the user's own hunks in those files were the change under review and are
  not regressions. The four sub-checks are unchanged.
- Done when: the edits are present; the Schema C table and the SPOT-CHECK
  fallback are unchanged; `bash scripts/check-run-contract.sh` exits 0.
- Why: without this, check 4 has nothing to read in an uncommitted run and
  a FAIL there would be a false one.

### Phase 3: Guards

**Step 3.1: Add the skill to `check-doc-sync-anchors.sh`'s groups**

- File: `scripts/check-doc-sync-anchors.sh`. Two entries in
  `ANCHOR_CHECKS`: `"Documentation impact|plugins/kenspc/skills/diagnose-bug/SKILL.md"`
  and `"Doc-sync|plugins/kenspc/skills/diagnose-bug/SKILL.md"`. The header
  comment's file lists and its "eight files" count follow (nine). The
  self-test copies from the array and needs no change.
- Done when: `bash scripts/check-doc-sync-anchors.sh` and its `--self-test`
  exit 0; by hand, removing every `Doc-sync` from a copy of the new SKILL
  makes the main check exit 1 naming that file, and the copy is discarded.
- Why: the skill writes both anchors; the guard's own header says every file
  that writes, checks, or renders them belongs in its group.

**Step 3.2: Guard the `change-set.md` name in `check-run-contract.sh`**

- File: `scripts/check-run-contract.sh`. A fifth check: the literal
  `change-set.md` occurs at least once in `plugins/kenspc/skills/task-review/SKILL.md`,
  `plugins/kenspc/agents/code-fixer.md`,
  `plugins/kenspc/agents/regression-verifier.md`, and
  `plugins/kenspc/agents/requirements-reviewer.md` (`check-review-agent-drift.sh`
  carries the reviewers' shared sections to the other four); exit 1 naming
  each file where it is missing; exit 2 on a missing file. Header comment:
  "Four checks" becomes five, with one paragraph for the new one. `--file
  PATH` still runs check 4 only.
- Self-test: a fixture-stale guard that the literal is present in each of
  the four files; one mutation that removes every occurrence of the literal
  from `task-review/SKILL.md` (a replace-all helper, since `replace_literal`
  replaces the first occurrence only, and the name occurs more than once
  there) must exit 1; the revert must exit 0. The header's mutation list
  gains the entry.
- Done when: `bash scripts/check-all.sh --self-test` prints
  `guards run: 10` and ends with `self-tests run: 9`, every line PASS.
- Why: the file name is the one string the orchestrator and seven agents
  have to agree on, and three of its carriers had no guard.

### Phase 4: Documentation

**Step 4.1: Repository CLAUDE.md**

- File: `CLAUDE.md` (repository root).
- Project Overview: the plugin also provides bug diagnosis; "The brief skill
  has no review phase" becomes the brief and diagnose-bug skills. Plugin
  Directory Layout: `commands/kenspc-diagnose.md` and
  `skills/diagnose-bug/SKILL.md`; the hooks paragraph says the reminder's
  task and brief messages name the skills that write those directories.
- SKILL.md Frontmatter Fields: "all six skills", "syncing six files", "bump
  all six together" become seven.
- Subagent Review Architecture: the orchestration patterns gain diagnose-bug
  under "No review" — no plan to compare against; the user confirms the task
  list and task-implement's batch gate follows (ruling D2) — and a short
  "Diagnosis path" paragraph: reproduction test committed first, the
  `## Diagnosis` record, the fix / regression / Doc-sync tasks, the tier-3
  brief, the probe directory by reference to `canonical:run-dir` with the
  `diagnose-<name>` suffix (ruling D4). The effort paragraph's "the other
  five skills" becomes six. The run-directory paragraph gains
  `change-set.md`.
- CONTEXT block contract: a paragraph on `change-set.md` (v3.7): with
  REVIEW_SCOPE "changes" the orchestrating skill writes the change set it
  computed — mode, pinned base or range, diff command, file list — to
  `RUN_DIR/change-set.md` before dispatch; the five reviewers, code-fixer,
  and regression-verifier read it there; no key was added, for the reason
  RUN_DIR replaced REVIEW_REPORTS and ACCOUNTABILITY_LIST; without RUN_DIR a
  standalone reviewer derives the set from git itself; in `uncommitted` mode
  code-fixer commits nothing.
- Standalone safety classification: the reviewers' standalone sentence gains
  "and derive the change set from git themselves".
- Repository scripts/: `check-doc-sync-anchors.sh`'s group lists gain the
  skill; `check-run-contract.sh`'s description gains check 5.
- Non-Goals: the run-directory preparation is written once; diagnose-bug
  references it and carries no copy.
- The Durable documents table is unchanged.
- Done when: every count and list above agrees with the files, and the file
  reads top to bottom without a contradiction about skill, command, or
  guard counts.
- Why: CLAUDE.md is the loaded contract for every session in this
  repository.

**Step 4.2: READMEs and manifests**

- `README.md` (root): a `diagnose-bug` row in the skills table
  ("Reproduce-first bug diagnosis with a hypothesis loop, producing a task
  document for task-implement or a brief for planning — no review phase");
  `/kenspc-diagnose` in the Commands line.
- `plugins/kenspc/README.md`: a Skills row for diagnose-bug (reproduce with a
  failing test or record manual steps; hypothesis loop; task document with
  fix, regression tests, Doc-sync; brief for tier 3; no review phase, the
  user confirms the task list); a Commands row
  (`/kenspc-diagnose <observed bug or path to a bug report>`) and
  `/kenspc:diagnose-bug` in the skill-invocation sentence; Recommended
  Workflow: a second entry path — an observed bug → `/kenspc-diagnose` →
  `docs/tasks/*.md` → `/kenspc-task-implement`, or → `docs/briefs/*.md` →
  `/kenspc-plan` — and "Small fixes can skip all skills" restated with the
  tier-1 criterion (ruling M18); Run directory: a diagnosis's probes live in
  `.kenspc/runs/<time>-diagnose-<name>/scratch/orchestrator/`, and a
  standalone review's directory holds `change-set.md`; Known behavior: the
  "Review scope without a task document" item is replaced by the change-set
  definition (modes, defaults, CUSTOM_INSTRUCTIONS override, read-only
  computation) and the uncommitted-mode behavior (fixes applied, nothing
  committed, `—` in Schema B, the Next steps bullet), plus a new item for
  the red interval: after `/kenspc-diagnose` the reproduction test is
  committed and fails until the fix task lands (ruling D1).
- `plugins/kenspc/.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json`: descriptions per ruling M11; no version
  change.
- Done when: every sentence that counts skills or commands, describes the
  review scope, or names the run directory's files agrees with the SKILL,
  agent, and hook files; `bash scripts/check-json.sh` exits 0.
- Why: the README is the installed user's only description of the skill
  and of what a standalone review will and will not commit.

**Step 4.3: CHANGELOG and roadmap**

- `plugins/kenspc/CHANGELOG.md`: a `## 3.7.0 — unreleased` entry above
  3.6.0. Added: the diagnose-bug skill and `/kenspc-diagnose` (tiers,
  reproduction-first, hypothesis loop, the record, the tasks, the brief exit,
  the probe directory, the commits it makes); `change-set.md`; the hook
  messages; the two guard extensions (counts unchanged). Changed:
  `REVIEW_SCOPE=changes` defined (modes, defaults, override, read-only
  computation) — with the source stated: the v3.5.1 acceptance's Windows
  run, observation 2, where code-fixer committed the reviewed uncommitted
  file as a baseline (`5b4f1d4`) because nothing said how to handle an
  uncommitted change, recorded in that acceptance session and not under
  `docs/dry-runs/`; code-fixer's uncommitted mode; regression-verifier's
  check 4; the reviewers' three shared sections. Known behavior: the red
  interval after a diagnosis; fixes left uncommitted in an uncommitted run.
  The date is filled at release.
- `docs/roadmap.md`: remove the "Next minor" item that defines
  `REVIEW_SCOPE=changes` and renumber the rest; remove batch B from
  "Planned batches" (C remains). The item's misattribution of the Windows
  observation needs no correction there: the item leaves the file, and the
  CHANGELOG line above records what happened.
- Done when: both edits are present; the roadmap still lists C.
- Why: the repository's convention for planned versus shipped work.

**Step 4.4: Release checklist**

- File: `docs/release-checklist.md`.
- Row 1: "Lists all 7 kenspc slash commands".
- A new smoke row for `/kenspc-diagnose <observed bug>`, inserted after row
  8 as row 9, the end-to-end row becoming 10 (its two "Row 9" references
  follow). Pass criterion: the trace shows the reproduction test written,
  run, and failing, then committed (`test: reproduce …`), before the task
  document is written; `docs/tasks/<name>.md` is committed
  (`docs: add task …`) and holds `## Diagnosis` with the nine labels in
  order, `### Task 1` with `**Status:** TODO`, and `### Task N: Doc-sync`
  when its Documentation impact lists documents; `/kenspc-task-implement
  <path>` passes its Step 1 validation on it; the exit asks run-or-interactive;
  a run on a bug whose fix changes a function's signature writes
  `docs/briefs/<name>.md` starting `# Requirement Brief:` and no task
  document; when the diagnosis probed, its files are under
  `.kenspc/runs/<time>-diagnose-<name>/scratch/orchestrator/<n>/` and the
  checklist's `find` probe over that `scratch/` prints nothing; a request to
  explain a stack trace invokes no skill.
- Row 7 additions, for a run with no task document: `RUN_DIR/change-set.md`
  exists with `Mode:`; the FILE COVERAGE lists in `angle-1.md` …
  `angle-5.md` name the same files as it; between the invocation and the
  first reviewer dispatch the trace shows no `git commit`, `stash`,
  `checkout`, `add`, or `reset` by the orchestrator other than the one-time
  `.gitignore` commit; on a dirty tree, HEAD is unchanged after the run
  except for that commit, `git stash list` is unchanged, every FIXED row's
  Commit is `—`, and Next steps has the uncommitted-fixes bullet; on a clean
  tree ahead of its upstream, `Range:` is `<upstream>..<HEAD>` and the fix
  commits appear as before.
- Pre-flight counts stay `guards run: 10` and `self-tests run: 9`.
- Done when: the row, the additions, and the count are present.
- Why: the checklist is the only check that exercises the live chain; the
  fixed strings are what it greps for.

## Documentation impact

Determined from this repository's CLAUDE.md, § Durable documents.

- `CLAUDE.md` § Project Overview, § Plugin Directory Layout, § Skill
  Development Conventions (skill count, hooks paragraph), § Subagent Review
  Architecture (orchestration patterns, effort paragraph, CONTEXT block
  contract, standalone classification), § Non-Goals, § Repository scripts/
  — Step 4.1.
- `plugins/kenspc/README.md` § Skills, § Commands, § Recommended Workflow,
  § Run directory, § Known behavior — Step 4.2.
- `README.md` § Available Plugins (skills table, Commands line) — Step 4.2.
- `plugins/kenspc/CHANGELOG.md` — 3.7.0 entry — Step 4.3.
- `docs/roadmap.md` — the `REVIEW_SCOPE=changes` item and batch B removed —
  Step 4.3.
- `docs/release-checklist.md` — row 1, the new `/kenspc-diagnose` row, row 7
  additions — Step 4.4.
- `docs/dry-runs/README.md` — N/A for this document: the label convention is
  untouched.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this
  document: the plan format is unchanged.
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: the task-document format `generate-task` writes and
  `task-implementer` reads is unchanged; the `## Diagnosis` section is
  diagnose-bug's addition and is specified in the skill.

## Testing Strategy

- Mechanical: the release-checklist pre-flight block — the effort-override
  diff (unchanged), `claude plugin validate --strict .` and
  `./plugins/kenspc`, and `bash scripts/check-all.sh --self-test` with
  `guards run: 10` and `self-tests run: 9`.
- Guard falsifiability: check 5's self-test negative path in
  `check-run-contract.sh`; `check-doc-sync-anchors.sh`'s own self-test, plus
  the by-hand removal in Step 3.1.
- Hook: the four `printf … | bash remind-plan-skill.sh` probes in Step 1.3.
- Live chain, in a throwaway TypeScript project with vitest and tests of its
  own (the release checklist's target requirements), loaded with
  `--plugin-dir`: seed a bug; run `/kenspc-diagnose` and check the row-9
  criteria in Step 4.4; then `/kenspc-task-implement` on the document:
  Task 1 turns the reproduction test green, Task 2 adds the adjacent-case
  tests (or the record says there were none), Doc-sync runs when README was
  listed. Tier 3: seed a bug whose fix changes a function's signature; the
  brief is written, no task document, and `/kenspc-plan <brief>` detects it
  as a brief. Not reproduced: a bug report the project cannot reproduce ends
  in a question with no file and no commit. Routing: "what does this stack
  trace mean" in the same session invokes no skill.
- `REVIEW_SCOPE=changes`, standalone `/kenspc-task-review`: (a) a dirty tree
  — `change-set.md` says `Mode: uncommitted`, the five FILE COVERAGE lists
  match it, HEAD moves only by the `.gitignore` commit, `git stash list` is
  unchanged, Schema B's FIXED rows show `—`, Next steps carries the
  uncommitted-fixes bullet, and `check-run-contract.sh --file` on the
  `schema-b.md` exits 0; (b) a clean tree ahead of its upstream — `Mode:
  commits`, `Range:` is the upstream range, one fix commit per FIXED row;
  (c) a clean tree with no upstream — `Range:` is `HEAD~1..HEAD`; (d) the
  orchestrator's trace between invocation and first dispatch shows only
  read-only git commands and the one-time `.gitignore` commit.
- Acceptance is run in a separate session and filed under `docs/dry-runs/`
  (batch A's precedent); a FAIL is recorded, not repaired, and the spec
  author classifies observations.
- Dogfood note: `/kenspc-task` on this spec generates the Doc-sync task from
  the Documentation impact above — the first real run of batch A's template
  in this repository. It is not added by hand. For the documents Steps 4.1–4.4
  edit, the generated entries say "edited by Task <K>: verify it against the
  implementation instead of editing it again", as the template provides.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| The skill triggers on "explain this error" or "review this for bugs" | Medium | The three exclusions in the description and the Trigger Phrases list; the row-9 routing check. |
| The reproduction test stays red on the branch until the fix lands, and a CI that gates on the suite is red in between | Certain, by design (D1) | Known behavior and the CHANGELOG say so; Task 1 is first in document order, and the interactive exit lets the user fix at once. |
| A manual-reproduction Task 1 is marked DONE unverified in an unattended run | Medium | Ruling M12: the acceptance criterion names the user's verification, the implementer records it as not verified, and the exit message says so. |
| The reference to the `canonical:run-dir` block drifts if the block's marker name or its run-id rule changes | Low | The reference names the block by its marker; `check-run-contract.sh` keeps the two copies identical; the row-9 probe criterion checks the directory's name and location. |
| In uncommitted mode the user forgets to commit the fixes | Medium | The Next steps bullet names the files; Schema B records every fix by row. |
| The `HEAD~1..HEAD` fallback reviews one commit when the user meant several | Medium | Step 1 prints the mode and range before dispatch; CUSTOM_INSTRUCTIONS names a range; an upstream branch gives the full range. |
| A dirty tree hides commits the user wanted reviewed | Low | CUSTOM_INSTRUCTIONS override; the printed mode line makes the choice visible. |
| The task document's acceptance criteria are vague with no reviewer pass | Medium | The Quality bar, the writing rules in Step 1.1, and the user's confirmation before writing; task-implement's batch gate is a second look. |
| Five reviewers still list different files | Low | PREREQUISITES and FILE COVERAGE both point at `change-set.md`; row 7 compares the five lists. |

## Clarifications during implementation (2026-09-25)

Settled between the implementing session and the spec author; each entry
binds like the rulings above. Questions from the implementing session arrive
under a `## Questions for the spec author` section appended to the end of
this document (see Open Questions); each answer is recorded here as `C<n>` —
a statement and the Step it affects — and the answered question is removed
from that section.

- C1 — Step 1.1, ruling D4: the one-time `.gitignore` commit is the single
  exception to "the diagnosis modifies no tracked file". When the probe rule
  prepares the run directory in a project that does not yet ignore
  `.kenspc/`, the Ignore check's exit-1 branch appends `.kenspc/` to
  `.gitignore` and commits that file alone, as the block prescribes. The
  SKILL states the exception beside the no-tracked-file rule, worded as the
  review skills' criterion words it ("other than the one-time `.gitignore`
  commit"), and Step 4.4's row 9 accepts that commit when the diagnosis
  probed. Why: the block's own reason holds here — the change is one-time
  and visible in history, and the pathspec keeps everything else out of it.
  Steps 1.1, 4.4.
- C2 — Step 1.1, ruling M16: option (a). When the bug is not reproduced and
  the skill stops to ask, it first removes the reproduction-test files it
  created in this run — files git reports as untracked (`??`) that did not
  exist when the skill started; never a tracked file, never anything under
  `.kenspc/` — and the question lists each attempt: the path, what the test
  exercised, and what happened. If the removal is denied, the question names
  the files as left in place for the user to remove. "Writes no file and
  commits nothing" describes the end state. Why: a test that did not
  reproduce the bug is not a test; left in the test tree under a collectable
  name it passes silently in the user's own suite and asserts that the bug
  is absent — the suite pollution the scratch convention exists to prevent,
  one level closer to the user's code. The plugin's "deletes nothing itself"
  stance concerns run directories and the user's files; the skill's own
  uncommitted draft, never handed to the user, is neither, and a diagnosis
  session is interactive, so a permission prompt for the removal costs
  nothing. The Testing Strategy's not-reproduced case reads: a question, no
  task document or brief, no commit, and no untracked test file left by the
  skill — or, when removal was denied, that file named in the question.
  Step 1.1; Testing Strategy.
- C3 — Step 2.1, ruling D7 (i): when a commit the defaults name does not
  exist, git's empty tree (`git hash-object -t tree /dev/null`,
  `4b825dc642cb6eb9a060e54bf8d69288fbee4904`) stands in for it.
  `Mode: commits` with no upstream and HEAD the root commit:
  `Range: <empty tree>..<HEAD sha> (root commit)`. `Mode: uncommitted` on an
  unborn branch (no commit yet; `git rev-parse --verify HEAD` fails):
  `Base: <empty tree> (no commit yet)`. The file's shape, the diff commands
  (`git diff <empty tree>..<sha>`, `git diff <empty tree> -- <paths>`), and
  regression-verifier's `git diff <base> -- <files>` are unchanged; the
  run-directory preparation's `.gitignore` commit may then create the root
  commit, and the pinned base stays the empty tree. The SKILL states the
  substitution where it states the defaults. Why: a fresh project with one
  commit, or none, is the acceptance run's normal starting state and has to
  be reviewable without CUSTOM_INSTRUCTIONS. Step 2.1; the "no upstream"
  case of Step 4.4's row 7 and of the Testing Strategy covers the
  root-commit form.
- C4 — Steps 2.1, 2.3, 2.4, ruling D7 (iv): every commit instruction in
  the three files follows the mode rule. In `code-fixer`, the OBJECTIVE
  sentence ("deduplicate, apply fixes, commit, and produce …") and the
  PROCESSING APPROACH sentence ("committed with a focused
  conventional-commit message") defer to the FIXING RULES mode rule, and
  Task 6 carries the criterion that no commit instruction outside FIXING
  RULES is unconditional — as `task-document-reviewer` wrote it. The two
  "fix commits did not introduce new issues" lines — `regression-verifier`'s
  OBJECTIVE and task-review Step 6's verification list — read as Step 2.1's
  PASS / FAIL bullets do: "the fixes (fix commits, or the uncommitted fixes
  of an `uncommitted` run)", made in Task 7 and Task 4, which already edit
  those files. The `canonical:run-dir` sentence about fix commits going
  through the same repository stays: in an uncommitted run it is vacuous,
  not wrong, and the block is byte-locked. Step 2.3's Done when now counts
  six edits, not four. Why: the agent whose silent contract produced the
  baseline commit is the one that must not carry two answers in one
  prompt. Steps 2.1, 2.3, 2.4.
- C5 — Step 1.1 and Steps 2.1–2.4: a plugin prompt file states its evidence
  in its own words and carries no ruling label. The probe rule's Why in the
  SKILL reads in own-words form — an implementing agent has run its
  mutation checks on the project's own source in place, editing with
  `sed -i` and restoring with `cp`, so a run that stops in between leaves
  the user's source mutated — as `task-document-reviewer` rewrote Task 1;
  CLAUDE.md § Writing Rules for Skill Content already requires the form.
  The labels this plan uses as pointers — B-n, M-n, D-n, C-n, "ruling",
  batch names, dry-run records — stay out of the new SKILL and out of every
  agent or SKILL file Tasks 4–7 edit; the CHANGELOG cites the records
  instead. Tasks 1 and 4–7 carry the criterion that
  `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\((B-[0-9]|[MDC][0-9]+)\b'`
  prints nothing on the files they edit (it prints nothing on those files
  today and hits this plan, so it can fail). Why: skills and agents run as
  prompts in the user's project, where this repository's rulings and
  records mean nothing. Steps 1.1, 2.1–2.4.
- C6 — Step 1.1, ruling M4: Task 1's boundary admits test files. "No file
  outside Fix scope is modified" was too strict — `task-implementer` writes
  tests for each new function and stops on a file outside a task's stated
  scope, so a fix task with no room for tests would be BLOCKED. Task 1's
  criterion reads: no file outside Fix scope is modified other than test
  files (tests for the code the fix adds, in new files or beside the
  reproduction test) and the task document's status update; the reproduction
  test's existing assertions are unchanged. The manual-reproduction form
  carries the same allowance. Source: the batch's own review, fix commit
  `fdc52d8`; accepted as written. Step 1.1.
- C7 — Step 2.1, ruling D7 (i): the commits-mode range starts at the merge
  base. `<upstream sha>..<HEAD sha>` reads `<merge-base sha>..<HEAD sha>`,
  the merge base of `@{upstream}` and HEAD — the upstream itself unless the
  branch has diverged — because `git diff a..b` compares two trees and on a
  diverged branch would list the upstream's own new files with their changes
  reversed. The release checklist's row-7 criterion reads
  `<merge base>..<HEAD>`. Refinements from the same review, accepted as
  written: the uncommitted set is read with `-uall` and
  `core.quotePath=false`, a rename listed under its new path; CUSTOM
  INSTRUCTIONS that name a range replace the default while named paths
  narrow it; an empty set stops the run before any dispatch; in a shallow
  clone a missing `HEAD~1` stops the run and asks for a range instead of
  taking the empty tree. Source: fix commits `e8e7f56`, `3f79b90`,
  `84a6ff7`, `89b5faa`. Steps 2.1, 4.4.
- C8 — Steps 1.1, 2.3, 2.4: further review fixes accepted as written, each
  a behavior the CHANGELOG entry names. `code-fixer`, in a committed run
  (`Mode: commits` or REVIEW_SCOPE "task"), checks each file a fix will
  touch with `git status --porcelain` and DEFERs the fix when the file
  carries uncommitted changes, so a fix commit never sweeps the user's hunks
  in — a change for `/kenspc-task-review <task document>` on a dirty tree
  too (`7d7b900`); in an uncommitted run it runs no `git checkout`,
  `restore`, `reset`, `clean`, or `add`, and keeps a scratch copy of each
  file before its first edit for undoing a fix (`b8ef194`);
  `regression-verifier` fails row 5 on any commit made in an uncommitted run
  other than the one-time `.gitignore` commit (`2af8bd9`) and reads
  untracked fix files whole (`68bfc28`); the reviewers stop when a
  changes-mode run has no `change-set.md` (`d1ab27d`). `diagnose-bug` runs
  the reproduction test more than once and records an intermittent bug's
  observed rate, with Task 1 then requiring a stated number of consecutive
  passes (`c0112ed`); stops on a rejected commit rather than bypassing the
  hook, since a hook that runs the suite rejects the red reproduction commit
  by design (`02914c9`); names the reproduction commit and offers
  `git revert` when a run ends without a document (`d94893a`); warns at the
  exit when Fix scope holds uncommitted changes (`4182a79`); and in a
  session that cannot ask creates the task document alongside on a name
  conflict (`33bce6b`) and reaches tier-2 DONE (`65b07ef`). Why one entry:
  none of them reopens a ruling; they are recorded so the README and
  CHANGELOG re-check after the review (Schema G's re-check bullet) has a
  list to work from. Steps 1.1, 2.3, 2.4, 4.2, 4.3.
- C9 — Steps 1.1, 4.1: two departures from this plan's literal wording,
  accepted. The probe rule's "the block's three-step mutation rule" named a
  rule the `canonical:run-dir` block does not hold; the SKILL points at the
  rule where it lives, the RUN_DIR bullet of `regression-verifier.md`, and
  CLAUDE.md § Non-Goals records that moving or changing that rule updates
  the SKILL's pointer in the same commit. "The other six skills" reads "the
  six other skills", since the task's own acceptance grep for `six skills`
  would match the plan's wording. Steps 1.1, 4.1.
- C10 — Steps 2.1, 2.3, 2.4, ruling D7 (iv): the pre-fix record. In an
  uncommitted run, `code-fixer` keeps the copy it already makes before a
  file's first edit at a fixed place, `RUN_DIR/scratch/code-fixer/pre-fix/`,
  written once per run and never overwritten: each touched file's original
  content at `pre-fix/<path relative to the repository root>.txt`, the
  `.txt` appended so no runner, linter, or compiler collects it, and an
  index at `pre-fix/index.txt` with one line per touched path — `copied`,
  `created` (the fix created the file; it has no copy), or `deleted` (the
  fix removed it; its copy is kept). `pre-fix/` sits beside the numbered
  attempt directories and is not one: a second attempt records a file only
  if no entry for it exists, so the copy is always the state before any
  edit. `regression-verifier`'s check 4 in that mode reads the index and
  nothing else: for a `copied` path the fixes are the difference between
  the copy and the working file (`git diff --no-index <copy> <file>`), for a
  `created` path the whole file, for a `deleted` path the copy; a path the
  index does not name is the user's, whatever `git status` says; an index
  entry whose copy is missing, or a FIXED row naming a path the index does
  not, is a bookkeeping error reported in row 5's Detail. This closes the
  deferred row 7 (B5, E4, B4) and regression N1 — check 4 no longer infers
  fix output from `git status`, so a user's dirty file outside a
  CUSTOM_INSTRUCTIONS-narrowed set, or a build output, is never attributed
  to the fixes — and N4, since the copies carry `.txt`. Two more rulings
  from the same review: when `git merge-base <upstream> <HEAD>` prints
  nothing (unrelated histories, or a shallow clone whose history does not
  reach the upstream), task-review stops and asks for a range, as the
  shallow-clone clause does, instead of letting the empty tree stand in
  (N2); and every `git status --porcelain -uall` read in
  `regression-verifier.md` and `diagnose-bug/SKILL.md` carries
  `-c core.quotePath=false`, as task-review's does (N3). The literal
  `pre-fix/index.txt` joins `check-run-contract.sh`'s check 5 for
  `code-fixer.md` and `regression-verifier.md`; guard and self-test counts
  stay 10 and 9. The release checklist's row-7 change-set check gains the
  record: in an uncommitted run with FIXED greater than 0, `pre-fix/index.txt`
  exists, names every file a FIXED row names, and the trace shows the
  verifier diffing against the copies. Why under scratch and not a
  top-level run file: they are copies of project files, which the
  run-directory check requires under `scratch/`, and `.txt` keeps them out
  of every tool that walks the tree. Steps 2.1, 2.3, 2.4, 3.2, 4.2–4.4.

## Open Questions

None. The rulings in [Design decisions](#design-decisions) close every
question raised during design. If the implementing session finds one of them
contradicted by the code, stop and report it as a plan-level issue rather
than resolving it locally: append the question under a
`## Questions for the spec author` section at the end of this document,
commit nothing else, and wait; the spec author answers under Clarifications
during implementation and the session continues from the updated document.
