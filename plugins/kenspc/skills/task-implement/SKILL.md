---
name: task-implement
description: >
  Automated batch implementation: auto-implements ALL incomplete tasks from a task
  document without user interaction, then runs automated code review. Only use when
  the user explicitly requests automated/batch task implementation.
version: 3.0.0
argument-hint: <path-to-task-file>
---

# Task Implement

Automated task implementation via subagent, followed by an unconditional
automatic code review.

## Trigger Phrases

Use this skill **only** when the user explicitly requests automated batch
implementation, using phrases like: "implement tasks", "auto-implement",
"run task loop", "实现任务", "自动实现", "帮我自动实现", "逐个实现", or
invokes `/kenspc-task-implement` directly.

Avoid triggering this skill when the user:
- Wants to develop interactively (e.g., "继续开发", "let me work on",
  "帮我看看", "有问题请问我", "let's build", "我想做...").
- References a task document for context only, without asking for automated
  implementation.
- Asks questions about tasks, priorities, or what to implement next.
- Asks you to implement a single specific task (just do it directly, no
  skill needed).

The key distinction: this skill is for **unattended, automated batch**
implementation of ALL incomplete tasks. If the user wants a conversation,
wants to drive development themselves, or only wants one specific task
done, do not invoke this skill.

## Quality bar

A useful run implements every incomplete task in document order, marks
unimplementable tasks as BLOCKED with a concrete reason, and produces an
unconditional code-review pass over the resulting code. Tasks are not
silently skipped; scope creep into adjacent code is rejected at the task-
implementer level. The review at the end runs even when the implementation
just completed and tests passed — Phase 2 dispatches review unconditionally.

## Prerequisites

- A task document with clearly defined tasks and status markers.

## Arguments

$ARGUMENTS format: PATH

- PATH: the path to the task document (e.g., `docs/tasks/user-auth.md`).

If the user omits the path, ask them to provide it.

## Phase 1: Implement via subagent

**Goal**: implement every incomplete task in the task document, in order,
producing per-task commits and a Schema D summary.

**Inputs**: PATH (task document path); the project's CLAUDE.md, README, and
config files; the task document itself.

**DONE when**:
- Every incomplete task has been processed (DONE or BLOCKED) by the
  implementer agent.
- The implementer agent has returned a Schema D summary.
- The user has been shown a brief progress update before Phase 2 starts.

### Step 1: Validate input document

Read the file at the provided path. Determine whether it is a task document
or a plan document:

- **Task document**: contains individual entries with `**Status:**` markers
  (TODO, IN PROGRESS, DONE, BLOCKED).
- **Plan document**: contains Implementation Steps organized by Phase /
  Step, without Status markers.

If the file appears to be a plan document (Phase / Step structure but no
Status markers), tell the user this is a plan document and that
`/kenspc-task` should generate a task document from it first. Do not
proceed with implementation.

If validation passes, retain the parsed task list for use in Step 3.

### Step 2: Construct CONTEXT block

Build a structured CONTEXT block to pass to the implementer agent:

```
CONTEXT
- TASK_FILE: <path to the task document from $ARGUMENTS>
```

### Step 3: Confirm with user

Read the task document and identify all incomplete tasks. Present them to
the user as a **batch list confirmation only**. The Step 3 surface is a
gate on the batch as a whole — do not pre-discuss any single task's
implementation approach, file targets, or method-level changes here.
That discussion belongs inside the implementer agent's per-task work,
not at the confirmation gate.

Why: Step 3 confirms scope of the batch run. Drifting into per-task
implementation detail at this point pulls the orchestrator into one task
prematurely and makes the user respond to a half-formed plan instead of
the actual question (proceed yes/no on the batch).

Allowed (positive example):

```
Found N incomplete tasks to auto-implement:
1. Task X: [brief name]
2. Task Y: [brief name]
...
Proceed with automated implementation?
```

Disallowed (negative example — do not write Step 3 output like this):

```
Found 2 incomplete tasks. For Task X I plan to modify `src/Foo.cs`
method `Bar()` to add null-check around the call to `Baz()`. For
Task Y I will refactor the `Service` class to introduce a new
interface. Proceed?
```

Wait for explicit confirmation before proceeding. If the user declines or
wants to adjust scope, follow their instructions instead.

### Step 4: Dispatch the implementer

Tell the user: "Starting task implementation. Dispatching implement agent
now."

Then dispatch a subagent using the Agent tool:
- Agent name: `task-implementer`
- description: "Implement tasks from document"
- prompt: the CONTEXT block from Step 2
- run_in_background: false — the next step reads this agent's result in the
  same turn. A background call returns at once, and a headless session stops
  the agent when it exits.

The subagent implements all incomplete tasks within its own context and
returns a Schema D summary. No state file is written by the orchestrator.

### Step 5: Render Schema D and brief progress update

Render the implementer's Schema D table verbatim:

| # | Task ID | Status   | Files Touched | Commit  |
|---|---------|----------|---------------|---------|
| 1 | T-001   | DONE     | a.ts, b.ts    | abc1234 |
| 2 | T-002   | BLOCKED  | —             | —       |

Below the table, render the BLOCKED prose, Decisions made, Decisions needing
a home, and Post-implementation notes verbatim from the agent's output. These
prose sections are roll-ups of the per-task `**Implementation notes:**` blocks
now persisted in the task document; the orchestrator still renders them
verbatim from the agent's output rather than re-reading the document.

Then present a brief progress update to the user:

```
Implementation phase complete.
- Completed: N tasks (Task X, Task Y, ...)
- Blocked: N tasks (Task Z: [brief reason], ...)
Proceeding to code review.
```

Keep the first line, `Implementation phase complete.`, and the last line,
`Proceeding to code review.`, in English exactly as written, whatever
language the conversation uses; the lines between follow the conversation
language. Why: the release checklist finds this boundary by grepping the
trace for those two lines, the same way Schema labels stay fixed.

If every task in the Schema D table is BLOCKED, replace the last line with
"All tasks blocked. Skipping code review." and skip directly to Phase 2
Step 4 (final report) — Code Review / Fixes / Verification sections are
omitted; verdict = BLOCKED.

Full implementation details appear in the final report (Phase 2 Step 4).

#### Closure Wording Boundary

Phase-internal progress is not the same as workflow-level closure.
Phase 1 → Phase 2 is a transition, not the end of the
`/kenspc-task-implement` invocation — phrasing the Phase 1 wrap-up as if
the whole workflow has finished causes the orchestrator (and the user)
to treat the run as done and skip the unconditional review.

Announce the Phase 1 wrap using these template phrasings:

- `Implementation phase complete.` — the existing Step 5 template
  phrasing above; this announces Phase 1 wrap, not the whole workflow.
- `Proceeding to Phase 2.` / `Proceeding to code review.`
- Per-task completion notes ("Task 1 done") inside the implementer
  agent's work.

Wording that reads as the entire invocation having finished belongs
after Phase 2's final report, never at the Phase 1 boundary. (The
release-checklist smoke test greps the pre-Phase-2 trace window for
closure phrasings; the canonical phrase list lives there, not here —
enumerating forbidden phrasings in a prompt primes the model toward
them.)

## Phase 2: Automatic code review

After Phase 1, check the implementation results:
- If at least one task was successfully implemented, proceed to the
  unconditional code review (Steps 1-4).
- If every task in Schema D is BLOCKED, skip to Step 4 to render a Schema
  G consolidated report with verdict = BLOCKED and Code Review / Fixes /
  Verification sections omitted.

### Step 1: Prepare the run directory and construct the review CONTEXT block

<!-- canonical:run-dir:start -->
Prepare this run's report directory before any review agent is dispatched.
The five reviewers, code-fixer, and regression-verifier exchange full reports
through it, and the orchestrator passes only its path. Why: relaying full
reports through the main session has filled its context, and a relayed copy
has lost rows on the way to the verifier.

- Run-id: the current local time from `date +%Y%m%d-%H%M%S`, a hyphen, and
  the task document's file name without its extension — or `changes` when
  TASK_FILE is "N/A". Example: `20260923-110512-user-auth`.
- RUN_DIR: `<root>/.kenspc/runs/<run-id>`, where `<root>` is the output of
  `git rev-parse --show-toplevel`. Keep it absolute and forward-slashed as git
  prints it (`C:/...` on Windows); the file tools need absolute paths. The
  directory need not exist — the first report written creates it.
- Scratch space: probe files, copies, and other temporary files go under
  `RUN_DIR/scratch/` — each reviewer in its own `scratch/angle-<n>/`,
  code-fixer in `scratch/code-fixer/`, regression-verifier in
  `scratch/regression-verifier/`, and the orchestrating session itself in
  `scratch/orchestrator/` when it runs a probe of its own. Every file there
  is named so the project's test runner does not collect it: for vitest and
  jest with their default patterns, no `.test.` or `.spec.` segment in a
  file name, no file named `test.*` or `spec.*`, no `__tests__` directory,
  and no `__mocks__` directory; where the project configures its own
  pattern, or for any other runner, whatever that configuration actually
  collects; a jest project keeps the `__mocks__` rule whatever its pattern.
  Every attempt lives in a numbered subdirectory of the writer's own
  directory from the first (`scratch/angle-5/1/`); starting over is the next
  number (`scratch/angle-5/2/`), never a delete. A file that already carries
  a collectable name is renamed onto a path that does not exist yet, which
  is not a delete; renaming over an existing file is. It is ignored along
  with the run directory and needs no cleanup.
  Why: deleting temporary files with `rm -rf` can be denied by the user's
  permission rules, and a verifier that could not clean up has fallen back
  to judging fixes by reading code. The run directory is git-ignored, not
  tool-ignored, so a test runner walking the tree collects scratch files
  that look like tests.
- Ignore check: run `git -C <root> check-ignore -q .kenspc/runs/probe`. The
  probe path need not exist; a `.kenspc/` rule matches any path under the
  directory. Asking about `.kenspc/` itself is not reliable: a blank line in
  a CRLF `.gitignore` parses as an empty pattern, and git then reports the
  directory as ignored when nothing ignores it.
  - Exit 0 — already ignored; change nothing.
  - Exit 1 — append a `.kenspc/` line to `<root>/.gitignore`, ending it the
    way the file's existing lines end (CRLF when they end in CRLF); create
    the file if needed, and add a line break first if its last line has
    none. Then run `git -C <root> add .gitignore` and
    `git -C <root> commit -m "<message>" -- .gitignore`. The message is a
    conventional commit, `chore: ignore kenspc run directory` by default;
    when the project's CLAUDE.md sets commit conventions (a scope list, a
    format), apply them. Why a separate commit: the change is one-time and
    visible in history, and the pathspec keeps anything the user has staged
    out of it.
  - Any other exit code, or a failed commit — including a commit hook's
    rejection — stop and report the error. Do not retry, and do not bypass
    the hook with `--no-verify`: the hook encodes the project's rules, and
    the fix commits later in this run go through the same repository and
    would fail the same way.
<!-- canonical:run-dir:end -->

Build the CONTEXT block:
- `TASK_FILE` = the same task document path from Phase 1.
- `REVIEW_SCOPE` = "task".
- `CUSTOM_INSTRUCTIONS` = "N/A" unless the user provided specific review
  instructions.
- `RUN_DIR` = the run directory prepared above.

```
CONTEXT
- TASK_FILE: <task path from Phase 1>
- REVIEW_SCOPE: task
- CUSTOM_INSTRUCTIONS: N/A
- RUN_DIR: <absolute run directory>
```

CUSTOM_INSTRUCTIONS construction:
- Default: "N/A".
- Override only when the session has accumulated any of the four
  context categories below; fold applicable items into 2-4 sentences:
  1. Project structural facts not yet in CLAUDE.md (e.g., no test
     project in solution, no lint config, only one .csproj under
     solution root).
  2. User-authorized session-scoped permissions (e.g., auto-commit on
     trivial fixes, auto-push to feature branch).
  3. Cross-document narrative anchors (e.g., F1 phrase from a brief
     that the agent should treat as load-bearing context).
  4. Style preferences expressed in conversation (e.g., hobby pace,
     surgical fixes only, no scope creep).
- If none of the four apply to this session, retain "N/A". The
  `only when ... applicable` and N/A-fallback wording are intentional:
  they avoid the agent inventing content to populate the field.

Note: this construction guidance covers how the dispatching SKILL fills
the CUSTOM_INSTRUCTIONS field value at dispatch time. The 5 reviewer
agents (requirements / edge-case / quality / bug / test) each have a
"CUSTOM INSTRUCTIONS" section in their body that is byte-identity
locked across all 5 — that section is not edited here.

### Step 2: Dispatch the review agents

Tell the user: "Dispatching 5 review agents now."

<!-- canonical:dispatch:start -->
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

Dispatch **5 subagents in a single message** using the Agent tool, one for
each review angle, every call with `run_in_background: false`. Foreground
calls sent in one message still run in parallel, and the next step reads all
five results in this turn; a background call returns at once, and a headless
session stops the agent when it exits.
Each reviewer is read-only on the working tree and writes only under
`RUN_DIR`: its report at `RUN_DIR/angle-<n>.md`, and probe and temporary
files under `RUN_DIR/scratch/angle-<n>/`.
Pass the CONTEXT block constructed above as the dispatch prompt for every
agent.

- Agent name: `requirements-reviewer`, description: "Review: requirements"
- Agent name: `edge-case-reviewer`, description: "Review: edge cases"
- Agent name: `quality-reviewer`, description: "Review: code quality"
- Agent name: `bug-reviewer`, description: "Review: bug hunting"
- Agent name: `test-reviewer`, description: "Review: test coverage"
<!-- canonical:dispatch:end -->

After all 5 agents return, verify each one delivered: its reply carries a
Findings table, the report path, and the closing line, and
`RUN_DIR/angle-<n>.md` exists. If any agent returned an error, an empty
response, or an incomplete reply, or its report file is missing,
re-dispatch the failed agent(s) with the same CONTEXT block. If
the re-dispatch also fails, stop and inform the user which angles are
missing.

### Step 3: Aggregate and dispatch fix + regression agents

Aggregate the Schema A Findings tables in the 5 replies into a Schema A
roll-up table (HIGH / MEDIUM / LOW per angle and total). The Schema G
report's Code Review section renders the roll-up table; here, print only
this line, with the totals and the run directory filled in:

`Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`

Dispatch `code-fixer` in the foreground (`run_in_background: false`, as
with the reviewers) with the CONTEXT block from Step 1, unchanged —
code-fixer reads the 5 reports from RUN_DIR itself. The fix agent
deduplicates findings, applies fixes, commits, and writes its full Schema B
to `RUN_DIR/schema-b.md`: a `# / Source / short_label / Severity / File:Line
/ Action / Commit` table in which every issue ID appears in exactly one
Source cell, a Per-angle Results table, the Deferred Issues prose, the
scratch-pollution note when there is one, and a statistics line of this
fixed form:

<!-- canonical:stats-line:start -->
`total reported N (R n, E n, Q n, B n, T n), deduplicated to N unique, FIXED N, DEFERRED N, NOT APPLICABLE N, DEDUPED N`
<!-- canonical:stats-line:end -->

Its reply carries the statistics line, the Per-angle Results table, the HIGH
and MEDIUM rows with their Deferred Issues paragraphs, the scratch-pollution
note when there is one, and the path of schema-b.md. Schema G's Fixes
section renders that reply verbatim, and the LOW rows and their prose stay
in the file. When code-fixer returns, print only this line, the counts
taken from its statistics line:

`code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`

Then dispatch `regression-verifier`, also in the foreground, with the same
CONTEXT block — it reads
the 5 reports and schema-b.md from RUN_DIR itself. The agent verifies that
every issue ID is accounted for, that fixes are real, and that build / test /
lint pass. It returns Schema C (`# / Check / Result / Detail` table plus per-
non-PASS detail prose, closing on a CLEAN or HAS ISSUES line). Schema G's
Verification section renders it verbatim. When it returns, print only
`regression-verifier returned — CLEAN` when its closing line is CLEAN, or,
when it is HAS ISSUES, this line naming each non-PASS row with its Result:

`regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`

The three lines stay in English, exactly as written, whatever the
conversation language. Why: this run carries the implementation phase
before the review, and everything the orchestrator prints stays in its
context until the final report, where the agents' replies already are as
their results — a table printed between dispatches is paid for a second
time when Schema G prints it. The user following the run needs to know
which agent returned, its counts, and where its report is; the fixed form,
opening with the agent's name, is what the release checklist finds in the
trace, as it finds the Phase 1 boundary lines.

### Step 4: Render the consolidated final report (Schema G)

Render the final consolidated report using Schema G:

```
## Implementation

(Schema D verbatim, including its `## Decisions needing a home` section.)

## Code Review

(Schema A roll-up — the per-angle table, HIGH / MEDIUM / LOW per angle and
in total; rendered here only.)

## Fixes

(code-fixer's reply verbatim, rendered here only: the statistics line, the
Per-angle Results table, the HIGH and MEDIUM rows with their Deferred Issues
paragraphs, the scratch-pollution note when there is one, and the full path
of schema-b.md, where the LOW rows and their prose remain.)

## Verification

(Schema C verbatim; rendered here only.)

## Verdict

PASS / FAIL / PARTIAL / BLOCKED — one paragraph rationale.
BLOCKED applies when every task in Schema D is BLOCKED; in that case the
Code Review / Fixes / Verification sections are omitted.

## Next steps

Bulleted list (failed verifications, deferred issues, blocked task
unblocks). Each HIGH or MEDIUM DEFERRED issue gets its own bullet; LOW
DEFERRED issues share one bullet with their count and the path of
schema-b.md. Each Decisions needing a home entry gets its own bullet with
the decision and its suggested destination. When the Doc-sync task is
BLOCKED, one bullet states that its listed documents were not synced, and
why. When the task document's Doc-sync task is DONE (in this run or before
it) and code-fixer's statistics line reports FIXED greater than 0, one
bullet carries code-fixer's `Doc-sync documents:` line — each document the
fix commits updated, with its row and commit, and each left not updated,
with its reason, for the user to correct. When that line says
`none affected by the fixes`, the bullet reads
`No Doc-sync document describes behavior the fixes changed.` When the
reply has no such line, the bullet states the defect,
`code-fixer's reply has no Doc-sync documents line`, and names the Doc-sync
task's listed documents to check against the fix commits. Why: the fixes
land after the Doc-sync task, and code-fixer corrects the listed documents
in the fix commits; this bullet is where the user sees which ones changed,
or that none needed to, and a missing line means code-fixer did not meet
its contract, so the correction may not have run. When
regression-verifier's test-row Detail names
files under `.kenspc/` that the test run collected and that passed, one
bullet names them as the Detail does and asks the user to delete them —
runs are never deleted and the plugin deletes nothing itself, so a collected
probe that passes stays in the user's own test run until the user removes
it.
```

#### Verdict determination

- **PASS** — every task DONE; zero HIGH unresolved; build / tests / lint
  PASS or `SPOT-CHECK` on row 3 (no-test-suite fallback); no regressions
  introduced by fix commits.
<!-- canonical:verdict-shared:start -->
- `SPOT-CHECK` from regression-verifier (no test suite available) is
  treated as neutral — it does not force FAIL; PASS may still apply
  if all other checks PASS and no HIGH issues remain. The Verdict
  paragraph should explicitly note "tests spot-checked due to no
  test suite" when this state is present.
- A test run that was involuntarily incomplete (a crash, a timeout, an error, or
  tests that should have run did not) is recorded by regression-verifier as row-3
  `FAIL` and forces a FAIL verdict like any other failed check — see that agent's
  VERIFICATION CHECKS item 3.
- When the test run passed but some tests were intentionally skipped, row 3 stays
  `PASS` and its Detail lists the skips. A PASS verdict is still allowed, but the
  Verdict paragraph must note "N tests skipped by design" so the PASS is never
  silent about the reduced coverage. Why: the user should accept skipped coverage
  knowingly, not discover it later.
<!-- canonical:verdict-shared:end -->
- **FAIL** — at least one HIGH unresolved; or one or more INCORRECTLY
  FIXED items; or build / test / lint failure; or fix commits introduced
  unresolved regressions.
- **PARTIAL** — neither PASS nor FAIL applies cleanly; for example, HIGH
  issues are deferred with explicit rationale and the user must decide.
- **BLOCKED** — every task in Schema D is BLOCKED; Code Review / Fixes /
  Verification sections are omitted from the report.

The Next steps bullets must give the user enough detail to act on every
HIGH or MEDIUM DEFERRED, BLOCKED, or unresolved item without reading the
review reports or commit history; LOW deferred items stay one path away in
schema-b.md.
