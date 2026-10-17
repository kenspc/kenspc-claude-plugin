# Delegation alignment (4.9.0) — Task Document

## Context

Align the kenspc plugin's skills and agents with the global "Delegating to
Subagents" rule (dev-setup `463cd95`): say who runs each check, what may run
in parallel, and what evidence comes back. Each task carries out one or two
Implementation Steps of the plan; the plan's step text is the specification
for the wording, and its line numbers are as of `20000bf`.

Related plan: `docs/plans/delegation-alignment.md`

Edit the plugin's files in a session started without `--plugin-dir` (this
repository's CLAUDE.md § Test the plugin locally).

Dependency note: Task 4 depends on Task 3; Task 6 depends on Task 3; Task 7
depends on Task 6; Task 10 depends on Task 9; Task 13 depends on Tasks 1–12
(`Depends on: Task 1-12`) and runs after them.

## Tasks

### Task 1: Review skills run only in the top-level session

**Status:** TODO

Plan Step 1. In `plugins/kenspc/skills/task-review/SKILL.md` § Prerequisites
(line 33) and `plugins/kenspc/skills/task-implement/SKILL.md` § Prerequisites
(line 46), add one bullet each: the skill runs in the top-level session — the
one the user talks to, or a headless `claude -p` session — and never inside a
subagent, with the plan's Why stated in the skill's own words (a subagent may
not dispatch subagents of its own — a user rule may forbid it, and Claude Code
caps the nesting depth — so it would review all five angles, fix, and verify in
one context, losing the reviewers' independence; and it cannot ask the user at
the skill's gates). The bullets sit outside every canonical block.

Files: `plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`.

**Acceptance criteria:**
- Both Prerequisites sections hold the bullet and its `Why:`, and the bullet
  does not cite the global rule by its title.
- `bash scripts/check-canonical-dispatch.sh` and
  `bash scripts/check-verdict-shared.sh` exit 0.

---

### Task 2: The pre-review suite run stays in the orchestrating session's own Bash

**Status:** TODO

Plan Step 2. In the `canonical:dispatch` block's "Before the dispatch: one
suite run" paragraph (task-review line 286; task-implement line 424), after
"Run the project's test commands once", state that the orchestrating session
runs them itself, in its own Bash, not through a subagent; add to the
paragraph's Why that the commands are known, a brief costs more than the run,
and the logs belong under `scratch/orchestrator/`, the orchestrating session's
own directory. Make the edit byte-identical in both copies.

Files: `plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`.

**Acceptance criteria:**
- The sentence and the added Why are in both copies of the block.
- `bash scripts/check-canonical-dispatch.sh` and
  `bash scripts/check-run-contract.sh` exit 0.

---

### Task 3: Reviewers leave port- and database-bound tests to regression-verifier

**Status:** TODO

Plan Step 3, agent text (the guard is Task 4). In the five reviewers
(`requirements-reviewer.md`, `edge-case-reviewer.md`, `quality-reviewer.md`,
`bug-reviewer.md`, `test-reviewer.md` under `plugins/kenspc/agents/`):

- PREREQUISITES item 5 (byte-identical in all five): after "run a named test
  file, or a mutation check under your scratch directory, one command at a
  time", add the plan's rule — with RUN_DIR, a test file needs ports or a
  database when its own setup starts a server or host, opens a database
  connection, or binds a port, or the project's instruction files name it an
  integration test; when unsure, it counts as needing them; run no such file,
  read its result in `suite-run.md`'s logs, and list it under
  `## Tests left for the verifier`, one line per file with the path and what
  you wanted to learn from it — and the plan's Why (five full suites run at
  once have exhausted a machine's local ports; such a file run by several
  reviewers at once contends for the same ports and database;
  regression-verifier runs after code-fixer, alone). Without RUN_DIR the item
  is unchanged.
- OUTPUT FORMAT (Schema A): add the `## Tests left for the verifier` section
  after `## Issues` and before the closing line, written only with RUN_DIR,
  holding `none` when empty; it is in `angle-<n>.md`, not in the reply.
- REPORT DELIVERY (byte-identical in all five): the file's content, today
  "both tables and the closing line", also names that section; the reply list
  is unchanged.

In `plugins/kenspc/agents/regression-verifier.md` INPUTS (line 83) and
VERIFICATION CHECKS item 3 (line 214): read each `angle-<n>.md`'s
`## Tests left for the verifier`; after the full test command, run, one at a
time, each listed file the full run did not collect (a file the full run
collected is covered by it; when the runner gives no list of collected files,
or the list command errors, the file is run); row 3's Detail names each listed
file and how it was settled (`covered by the full run`, or its own command and
exit code); a listed file that fails makes row 3 FAIL.

Files: the five reviewer files and `plugins/kenspc/agents/regression-verifier.md`
(six; the reviewers' shared sections must change together).

**Acceptance criteria:**
- `grep -c '## Tests left for the verifier'` is at least 2 in each of the five
  reviewers (PREREQUISITES and Schema A) and at least 1 in
  `regression-verifier.md`.
- `bash scripts/check-review-agent-drift.sh` and
  `bash scripts/check-run-contract.sh` exit 0.

---

### Task 4: check-run-contract.sh holds the new literal

**Status:** TODO

Depends on: Task 3

Plan Step 3, guard. In `scripts/check-run-contract.sh` check 5, add the literal
`## Tests left for the verifier`, required in the five reviewers and
`regression-verifier.md`, each file that lacks it reported. Its self-test
renames the literal in each of the six in turn: the self-test copies seven
target files today, of the reviewers only `requirements-reviewer.md`, so it
gains `edge-case-reviewer.md`, `quality-reviewer.md`, `bug-reviewer.md`, and
`test-reviewer.md`, and its fixture-stale check requires the literal in all
six. Update the guard's header comment (the file list, the copied-file count,
and the mutation count, "thirty-seven" today) to match.

Files: `scripts/check-run-contract.sh`.

**Acceptance criteria:**
- `bash scripts/check-run-contract.sh` exits 0.
- `bash scripts/check-run-contract.sh --self-test` exits 0, its output showing
  each of the six renames turning the guard red and the unmutated copy green.
- Renaming the literal by hand in one reviewer of a scratch copy makes main
  mode exit non-zero, naming that file.

---

### Task 5: Reviewer descriptions warn against parallel standalone dispatch

**Status:** TODO

Plan Step 4. Append one sentence to the `description:` frontmatter of each of
the five reviewers: invoked standalone (without RUN_DIR) it runs the project's
full test suite itself, so dispatch one at a time or use /kenspc-task-review.
The same sentence in all five, on the description's single line (each is one
line under `>` today), so a fixed-string grep finds it. The first sentence,
which carries the trigger, is unchanged.

Files: the five reviewer files under `plugins/kenspc/agents/`.

**Acceptance criteria:**
- `grep -lF '<the sentence>' plugins/kenspc/agents/*-reviewer.md` lists
  exactly the five reviewers.
- `claude plugin validate --strict ./plugins/kenspc` exits 0.

---

### Task 6: Checks report their command, exit code, and log

**Status:** TODO

Depends on: Task 3

Plan Step 5.

- `plugins/kenspc/agents/regression-verifier.md` Schema C (line 325): rows 2–4
  carry, in every Result state, PASS included, `<command> → exit <n>, log <path>`
  in the Detail cell (several commands joined by `; `), logs under
  `RUN_DIR/scratch/regression-verifier/`; a check the project gives no command
  for reads `no <build|lint> command in the project`; row 3's SPOT-CHECK keeps
  its fallback text; what the Detail already carries (skipped tests, collected
  `.kenspc/` paths, Task 3's listed files) follows the evidence after `; `; the
  worked example shows these forms; the Detail prose stays for non-PASS rows.
  Why, in the agent's words: a `—` cell says a check passed without saying
  which command ran or where its output is.
- `plugins/kenspc/agents/code-fixer.md` reply list (line 525): add the
  always-present line `Final checks: <command> → exit <n>, log <path>[; …]`
  (logs under `RUN_DIR/scratch/code-fixer/`), or
  `Final checks: none run (no fix applied)`, after the statistics line and
  every conditional line the list places after it, before the Per-angle
  Results table; not written to `schema-b.md`.
- `plugins/kenspc/agents/task-implementer.md` Schema D (line 307): add a
  `## Checks run` section after `## Post-implementation notes`, always
  rendered — the last build, test, and lint commands the dispatch ran, each
  with its exit code, the task after which it ran, and its log path under
  `RUN_DIR/scratch/task-implementer/`, or `none run`; add it to DONE CRITERIA
  (line 86) beside the `## Decisions needing a home` bullet.
- `plugins/kenspc/skills/task-implement/SKILL.md` Step 5 (line 284): render
  `## Checks run` verbatim after the Post-implementation notes; after slices,
  keep the last slice's section (an exception to the merge rule, since the
  last slice's checks ran on the code every slice built).

Files: `plugins/kenspc/agents/regression-verifier.md`,
`plugins/kenspc/agents/code-fixer.md`, `plugins/kenspc/agents/task-implementer.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`.

**Acceptance criteria:**
- regression-verifier's worked Schema C table shows rows 2–4 in the
  `→ exit <n>, log <path>` form and one no-command form.
- code-fixer's reply list states the `Final checks:` line in both forms.
- Schema D's format shows `## Checks run` with one example line, and
  task-implement Step 5 renders it.
- `bash scripts/check-run-contract.sh` and
  `bash scripts/check-notes-format-sync.sh` exit 0.

---

### Task 7: The verdict is confirmed by reading, not re-running

**Status:** TODO

Depends on: Task 6

Plan Step 6. Inside the `canonical:verdict-shared` block of
`plugins/kenspc/skills/task-review/SKILL.md` and
`plugins/kenspc/skills/task-implement/SKILL.md`, add one bullet, byte-identical
in both: the verdict reads Schema C rows 2–4's exit codes as reported; the
orchestrating session confirms a row by reading the log it names and runs no
build, test, or lint of its own; a row 2–4 that carries neither an exit code
nor one of Task 6's no-command forms (the `no … command in the project` text,
row 3's SPOT-CHECK fallback) keeps the verdict from PASS — PARTIAL, unless a
FAIL condition holds. Why: regression-verifier is the skill's confirmation
step; a third full run adds load and no independence, and a row with no
evidence is a verdict nobody can check without re-running it.

Files: `plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`.

**Acceptance criteria:**
- The bullet is inside the markers in both files.
- `bash scripts/check-verdict-shared.sh` exits 0.

---

### Task 8: task-document-reviewer does not rewrite task steps to delegate

**Status:** TODO

Plan Step 7. In `plugins/kenspc/agents/task-document-reviewer.md` angle 3
(line 111), after the Passing paragraph, add: a user-level or project rule on
delegating work to subagents governs the session that dispatches agents, not a
task's steps; a task step that runs a suite or a check is not a departure from
it. Why: task-implementer has no Agent tool, so a step rewritten to delegate
cannot be carried out.

Files: `plugins/kenspc/agents/task-document-reviewer.md`.

**Acceptance criteria:**
- The sentence and its Why are in angle 3.
- `bash scripts/check-instruction-files.sh` exits 0.

---

### Task 9: Autopilot subagent rules — the main session uses none, workers foreground only

**Status:** TODO

Plan Steps 8 and 9, in `plugins/kenspc/skills/autopilot/SKILL.md`:

- Overview (line 32): turn "Nothing runs as an agent." into a rule with its
  Why — the main session dispatches no Agent subagent for a role, a re-check, a
  re-run, a review, or the evidence of a corrected case, and its own checks
  (the start checks, the snapshot, the self-test, the extraction, the zero-diff
  check, the corrected-case runs) run in its own Bash; Why: a subagent's cost is
  outside the budget's terms, it carries no worker marker so the rails hook
  does not guard it, in plugin mode it runs the plugin text this session loaded
  at its start, and several of those checks read values only this session's
  Bash holds.
- Preamble § 3 (around line 2242, "These rails bind every subagent you
  dispatch"): add the rail — you are the top-level session of your own process
  and may dispatch subagents, each with `run_in_background: false`; a subagent
  you dispatch dispatches none and starts no `claude -p`; it goes into every
  subagent prompt and every CUSTOM_INSTRUCTIONS with the rest of § 3 — with the
  plan's Why (a background subagent is stopped when a headless session exits; a
  subagent that nests or starts its own headless session leaves the rails text
  one level behind, and a `claude -p` it starts is a session of its own that
  the nesting limit does not reach — a reading of the 2.1.301 code, not
  measured). The worker keeps launching nested sessions where a task block
  tells it to (plugin-mode S4). The preamble's first line ("headless
  sub-session") is unchanged.

Files: `plugins/kenspc/skills/autopilot/SKILL.md`.

**Acceptance criteria:**
- The overview holds the rule with its Why; § 3 holds the rail with its Why;
  the preamble's first line is unchanged.
- `bash scripts/check-no-model-names.sh` and
  `bash scripts/check-autopilot-rails-hook.sh` exit 0.

---

### Task 10: Autopilot worker blocks — S4 runs its cases itself, S5 and S6 report their checks

**Status:** TODO

Depends on: Task 9

Plan Steps 10 and 11, in `plugins/kenspc/skills/autopilot/SKILL.md`:

- Repo-mode S4 block (line 2659): "Then run each case yourself, in the order
  listed, …", with the Why: the cases run at one HEAD in one working tree and
  may start servers or suites, so they share the tree and the machine's ports.
- S5 block (line 2798): the reply line per fixed defect adds each check run
  for it, `<command> → exit <n>` (no log path).
- Plugin-mode S6 block (line 2891): "Run the checklist's pre-flight block; its
  two count lines and each command's exit code go in your reply.", and the
  reply line to match; Phase 4's description of S6 (line 1873) names the exit
  codes beside the count lines.
- The two reports: the reviewer report's `- Byte-identity / guards / counts:`
  field (line 3144) carries each pre-flight command's exit code beside the
  count lines; the user report's "what needs the user" list (line 2060, "a
  failed check at S6's return") names a non-zero pre-flight exit code as a
  pre-flight failure. Why: evidence nobody reads is not confirmation, and the
  two count lines alone may be missing when a command before them failed.

Files: `plugins/kenspc/skills/autopilot/SKILL.md`.

**Acceptance criteria:**
- The S4, S5, and S6 blocks, line 1873's description, the reviewer report's
  field, and the user report's list read as above.
- `bash scripts/check-autopilot-rails-hook.sh` exits 0.

---

### Task 11: Read-only sweeps may go to parallel subagents

**Status:** TODO

Plan Step 12. Add one paragraph each to `plugins/kenspc/skills/generate-task/SKILL.md`
Phase 1 (line 85), `plugins/kenspc/skills/generate-guide/SKILL.md` Phase 1
(line 81), and `plugins/kenspc/skills/diagnose-bug/SKILL.md` at hypothesis
verification (line 207) and at adjacent cases (line 271): a sweep that only
reads — the code behind several plan steps, the config across a project, a
hypothesis checked by reading a code path, sibling code paths — may go to
read-only subagents sent in one message, every call with
`run_in_background: false`, each told in its prompt to write nothing and to
return `file:line` for what it reports; the main session reads every line a
task, a guide sentence, or the diagnosis rests on before writing it. Probes
that run code, the reproduction test's repeated runs, and the decomposition,
the guide, and the diagnosis themselves stay in the main session. Why, in the
skill's words: independent read-only sweeps finish sooner side by side and
leave the main session's context for the document; the traceability the
document promises is kept by reading the cited lines.

Files: the three SKILL.md files above.

**Acceptance criteria:**
- `grep -c 'file:line'` prints at least 1 for `generate-task/SKILL.md` and
  `generate-guide/SKILL.md`, and at least 2 for `diagnose-bug/SKILL.md`.
- `bash scripts/check-instruction-files.sh` and
  `bash scripts/check-doc-sync-anchors.sh` exit 0.

---

### Task 12: Correct the two stale platform statements

**Status:** TODO

Plan Step 13.

- `CLAUDE.md` line 359: replace "Subagents cannot spawn other subagents" with:
  kenspc's agents cannot dispatch subagents, since none lists Agent in
  `tools:`; Claude Code itself nests to depth 3 by default (2.1.301,
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`); orchestration stays at the skill
  (main session) level.
- `CLAUDE.md` lines 411–418, `plugins/kenspc/README.md` § Known behavior
  (lines 1487–1492), and `docs/release-checklist.md` lines 104–106: record the
  2026-10-17 measurement — in a 2.1.301 Desktop session the parameter is
  present, `false` holds the call until the subagent finishes, and an omitted
  parameter runs it in the background; the interactive terminal CLI is not
  measured, and the binary drops the parameter there when fork mode is on.

Before editing, run both greps below as positive controls and keep their
output for the Implementation notes.

Files: `CLAUDE.md`, `plugins/kenspc/README.md`, `docs/release-checklist.md`.

**Acceptance criteria:**
- Before the edit,
  `grep -rn 'cannot spawn' CLAUDE.md plugins/ docs/release-checklist.md docs/roadmap.md --exclude=CHANGELOG.md`
  prints `CLAUDE.md` line 359; after it, it prints no line.
- Before the edit,
  `grep -rn 'has no such parameter\|has no .run_in_background.\|takes effect only in headless' CLAUDE.md plugins/ docs/release-checklist.md --exclude=CHANGELOG.md`
  prints `CLAUDE.md` line 417, README line 1490, and release-checklist line
  105; after it, it prints no line.
- `bash scripts/check-all.sh` exits 0.

---

### Task 13: Doc-sync

**Status:** TODO

Depends on: Task 1-12

Bring the documents below in line with what Tasks 1-12 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § Agents, the reviewer paragraph — the
  `## Tests left for the verifier` list and the standalone note (Steps 3, 4);
  task-review's and task-implement's run-directory and report descriptions —
  Schema C's Detail form, code-fixer's `Final checks:` line, Schema D's
  `## Checks run` (Step 5); the top-level-only rule (Step 1); the autopilot
  section (Steps 8–11); the three skills' read-only sweeps (Step 12); § Known
  behavior (Step 13); the § Known behavior lines are edited by Task 12: verify
  them against the implementation instead of editing them again.
- `CLAUDE.md` § Subagent Review Architecture — the Phase 1 and Phase 3 bullets
  (Steps 3, 5) and the top-level rule (Step 1); the `check-run-contract.sh`
  entry under Repository scripts/ — the new literal and its carriers (Step 3);
  § Sessions, not agents (Steps 8–9); lines 359 and 411–418 (Step 13) are
  edited by Task 12: verify them against the implementation instead of editing
  them again.
- `plugins/kenspc/CHANGELOG.md` — a `## 4.9.0 — unreleased` entry for Steps
  1–13 (the release procedure dates it).
- `docs/release-checklist.md` — the run-directory check's sub-check 4 (lines
  161–169), whose "a clean PASS row's Detail is `—`, so the table cannot show
  which command ran" Step 5 makes false; smoke rows 6 and 7, which gain the
  Schema C Detail form and code-fixer's `Final checks:` line, row 6 also
  Schema D's `## Checks run` (Step 5); lines 104–106 (Step 13) are edited by
  Task 12: verify them against the implementation instead of editing them
  again.
- `docs/roadmap.md` — a new item at the end of the list: a machine-wide limit
  on full test suites run at once across concurrent autopilot batches, the
  batches' own `Run facts:` gates bounding only each batch (Q11, planned
  separately; ruled onto the roadmap by the user on 2026-10-17).

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-12. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-12 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
- `grep -c` of `## Tests left for the verifier`, `Final checks:`, and
  `## Checks run` is at least 1 each in `plugins/kenspc/README.md`, and of
  `## Tests left for the verifier` at least 1 in `CLAUDE.md`;
  `plugins/kenspc/CHANGELOG.md` holds `## 4.9.0 — unreleased`;
  `grep -n 'Detail is .—., so the table cannot show' docs/release-checklist.md`
  prints nothing; `grep -ci 'machine-wide' docs/roadmap.md` is at least 1.
- `bash scripts/check-all.sh` and `bash scripts/check-all.sh --self-test`
  exit 0, with `guards run:` and `self-tests run:` unchanged from `20000bf`.
