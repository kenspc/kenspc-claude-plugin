---
name: task-implement
description: >
  Automated batch implementation: auto-implements ALL incomplete tasks from a task
  document after one batch confirmation, then runs automated code review. Only use when
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
- The skill runs in the top-level session — the one the user talks to, or a
  headless `claude -p` session — and never inside a subagent. Why: a
  subagent may not dispatch subagents of its own — a user rule may forbid
  it, and Claude Code caps the nesting depth — so it would implement the
  tasks, then review all five angles, fix, and verify in one context,
  which removes the independence the implementer and the five reviewers
  exist for; and it cannot ask the user at this skill's gates, the batch
  confirmation among them.

## Arguments

$ARGUMENTS format: PATH

- PATH: the path to the task document (e.g., `docs/tasks/user-auth.md`).

If the user omits the path, ask them to provide it. In a session that cannot
ask (a system reminder to work without stopping), the run ends: its last
message says the task document's path is missing.

## Phase 1: Implement via subagent

**Goal**: implement every incomplete task in the task document, in order,
producing per-task commits and a Schema D summary.

**Inputs**: PATH (task document path); the project's instruction files,
README, and config files; the task document itself.

**DONE when**:
- For a task document with no TODO or IN PROGRESS task: the Step 3 reply
  has been given, and the run ends there — none of the points below
  applies.
- The run directory was prepared and created before the implementer's
  dispatch (Step 4).
- Every incomplete task has been processed (DONE or BLOCKED) by the
  implementer agent — for a slice dispatched with `TASK_LIMIT` (Step 4),
  every incomplete task within its limit, and the slices run until no
  TODO or IN PROGRESS task is left or a slice returns with no task's
  status changed.
- The implementer agent has returned a Schema D summary — every slice its
  own, merged into one in Step 5.
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
- RUN_DIR: <absolute run directory>
- TASK_LIMIT: 12
```

`RUN_DIR` is filled in Step 4, which prepares the run directory after the
batch confirmation. The `TASK_LIMIT` line is added only to a slice's
dispatch, when the document has more than 12 incomplete tasks (Step 4);
otherwise the block carries the first two keys alone.

### Step 3: Confirm with user

Read the task document and identify all incomplete tasks — those marked
TODO or IN PROGRESS.

**No incomplete task.** When the document has no TODO or IN PROGRESS task,
the reply gives the counts of its DONE and BLOCKED tasks and names
`/kenspc-task-review <path>` for a review of the finished work — and,
when a task is BLOCKED, says that a BLOCKED task runs again only once its
Status is set back to TODO, the unblock step its note gives, since a
review cannot build it — and the run ends there: it asks nothing, prepares no run directory, dispatches
nothing, runs no review, and renders no Schema G. Why: a session given a
document whose every task was DONE stopped before its batch gate and
prepared no run directory, which nothing in this skill said to do; a gate
with nothing to implement asks a question whose answer changes nothing,
and a review of work already finished is task-review's, which the user can
start with that command.

Otherwise, present the incomplete tasks to the user as a **batch list
confirmation only**. The Step 3 surface is a
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
wants to adjust scope, follow their instructions instead. In a session that
cannot ask (a system reminder to work without stopping), the run still stops
here: its last message prints the list in full, then the line
`Implementation not started: awaiting confirmation.`, and says how to go on
— run `/kenspc-task-implement <path>` again where the batch can be
confirmed. Why: the batch changes the project's code, and invoking the skill
does not confirm a list nobody has seen.

### Step 4: Prepare the run directory and dispatch the implementer

Prepare the run directory here, after the batch confirmation and before the
dispatch. Why after the confirmation: a declined batch then makes no
`.gitignore` commit. Why before the dispatch: task-implementer writes its
probes, copies, and mutants under `RUN_DIR/scratch/task-implementer/`, and
Phase 2 reuses the same directory for the review reports.

<!-- canonical:run-dir:start -->
Prepare this run's report directory before the first agent the run
dispatches — task-implementer in `/kenspc-task-implement`, the review agents
in `/kenspc-task-review`. The five reviewers, code-fixer, and
regression-verifier exchange full reports through it, task-implementer keeps
its probes, copies, and mutants in it, and the orchestrator passes only its
path. Why: relaying full reports through the main session has filled its
context, and a relayed copy has lost rows on the way to the verifier.

- Run-id: the current local time from `date +%Y%m%d-%H%M%S`, a hyphen, and
  the task document's file name without its extension — or `changes` when
  TASK_FILE is "N/A". Example: `20260923-110512-user-auth`.
- RUN_DIR: `<root>/.kenspc/runs/<run-id>`, where `<root>` is the output of
  `git rev-parse --show-toplevel`. Keep it absolute and forward-slashed as git
  prints it (`C:/...` on Windows); the file tools need absolute paths. The
  directory need not exist — the first report written creates it.
- Scratch space: probe files, copies, and other temporary files go under
  `RUN_DIR/scratch/` — each reviewer in its own `scratch/angle-<n>/`,
  task-implementer in `scratch/task-implementer/`, code-fixer in
  `scratch/code-fixer/`, regression-verifier in
  `scratch/regression-verifier/`, and the orchestrating session itself in
  `scratch/orchestrator/` — the suite logs and the tree state before the
  reviewers, and any probe of its own. Every file there
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
    `git -C <root> commit -m "<message>" -- .gitignore`. The message is
    `chore: ignore kenspc run directory`, adapted to the project's commit
    convention: the one the repository writes down (a scope list, a
    format — in the project's instruction files or its CONTRIBUTING), or,
    failing that, the pattern its recent commit subjects consistently
    share. The project's instruction files are its
    CLAUDE.md and AGENTS.md files — at the root, in `.claude/`, or in a
    subdirectory — and the files a CLAUDE.md imports with `@`, whether or
    not Claude Code loaded them in this session. Why a separate commit: the
    change is one-time and visible in history, and the pathspec keeps
    anything the user has staged out of it.
  - Any other exit code, or a failed commit — including a commit hook's
    rejection — stop and report the error. Do not retry, and do not bypass
    the hook with `--no-verify`: the hook encodes the project's rules, and
    the fix commits later in this run go through the same repository and
    would fail the same way.
<!-- canonical:run-dir:end -->

Then create the directory before the dispatch, with
`mkdir -p <RUN_DIR>/scratch/task-implementer`, so it exists before
task-implementer's first tool call, and fill `RUN_DIR` in the Step 2
CONTEXT block with it. Why: the block leaves the directory to the first
report written, which suits the review agents, but task-implementer's first
write there may be a shell command such as `cp`, which does not create a
missing directory.

Tell the user, in the conversation's language, that implementation is
starting and the implementer is being dispatched.

Then dispatch a subagent using the Agent tool:
- Agent name: `task-implementer`
- description: "Implement tasks from document"
- prompt: the CONTEXT block from Step 2, with `RUN_DIR` filled in
- run_in_background: false — the next step reads this agent's result in the
  same turn. A background call returns at once, before its result exists. A call that comes back with its agent still
  running is waited on as Phase 2's Code Review Phase says: its Schema D is
  in the completion notice.

The subagent implements all incomplete tasks within its own context and
returns a Schema D summary — a slice's subagent, the incomplete tasks
within its `TASK_LIMIT` (below). No state file is written by the
orchestrator.

**Slices.** When the document has more than 12 incomplete tasks — TODO or
IN PROGRESS, counted in Step 3 — dispatch the implementer in slices: each
dispatch carries `TASK_LIMIT: 12` in its CONTEXT block, the slices run one
after another, and the task document is read again after each slice
returns. Dispatch the next slice while a TODO or IN PROGRESS task is left;
stop when none is left, or when a slice returns with no task's status
changed, since another would meet the same tasks the same way. A task
still TODO or IN PROGRESS after that stop was never run: Step 5's update
names it, and it keeps the verdict from PASS. Why: the merged Schema D
holds only the tasks the slices gave a status, so a task left unrun would
otherwise appear nowhere and PASS would read as the whole document done.
Every slice
reuses the same RUN_DIR, and the batch confirmation (Step 3) is asked once,
for the whole batch. Why 12: one implementer that held a 33-task document
ended on `Prompt is too long` after 22 tasks and returned no summary, and
a slice must leave room for the review fixes and notes each task adds; the
value is this one constant.

### Step 5: Render Schema D and brief progress update

Render the implementer's Schema D table verbatim — after slices, one
Schema D merged from them: their rows in one table in document order, and
each prose section the slices' entries joined under one heading
(`## Decisions needing a home` reads `none` only when every slice's does;
`## Checks run` is the exception below):

| # | Task ID | Status   | Files Touched | Commit  |
|---|---------|----------|---------------|---------|
| 1 | T-001   | DONE     | a.ts, b.ts    | abc1234 |
| 2 | T-002   | BLOCKED  | —             | —       |

Below the table, render the BLOCKED prose, Decisions made, Decisions needing
a home, and Post-implementation notes verbatim from the agent's output. These
prose sections are roll-ups of the per-task `**Implementation notes:**` blocks
now persisted in the task document; the orchestrator still renders them
verbatim from the agent's output rather than re-reading the document.

After the Post-implementation notes, render the agent's `## Checks run`
section verbatim. After slices, render alone the section of the last
slice that ran a check, rather than joining the slices' entries, and
`none run` only when every slice's reads `none run`. Why: the last checks
that ran ran on the code every slice before them built, while an earlier
slice's describe code that later slices changed; a later slice that ran
none — its tasks all blocked, or none of their statuses changed — built
nothing they describe.

Then present a brief progress update to the user:

```
Implementation phase complete.
- Completed: N tasks (Task X, Task Y, ...)
- Blocked: N tasks (Task Z: [brief reason], ...)
- Not run: N tasks (Task W, ...) — only when the slices stopped with tasks left
Proceeding to code review.
```

Keep the last line, `Proceeding to code review.`, in English exactly as
written, whatever language the conversation uses; the lines before it
follow the conversation language. Why: the release checklist finds this
boundary by grepping the trace for that line, the same way Schema labels
stay fixed.

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

A run that ended at Phase 1 Step 3 on a document with no incomplete task
never reaches this phase. After Phase 1, check the implementation results:
- If at least one task was successfully implemented, proceed to the
  unconditional code review (Steps 1-4).
- If every task in Schema D is BLOCKED, skip to Step 4 to render a Schema
  G consolidated report with verdict = BLOCKED and Code Review / Fixes /
  Verification sections omitted.

### Step 1: Construct the review CONTEXT block

Reuse the run directory prepared in Phase 1 Step 4: its `RUN_DIR`, with no
second run-id and no second preparation. Why: task-implementer's scratch and
the review reports then sit in one run directory, and a second preparation
would split one run's evidence across two.

Build the CONTEXT block:
- `TASK_FILE` = the same task document path from Phase 1.
- `REVIEW_SCOPE` = "task".
- `CUSTOM_INSTRUCTIONS` = "N/A" unless the user provided specific review
  instructions.
- `RUN_DIR` = the run directory prepared in Phase 1 Step 4.

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
  1. Project structural facts not yet in the project's instruction files
     (e.g., no test project in solution, no lint config, only one .csproj
     under solution root).
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

Tell the user, in the conversation's language, that the five reviewers are
being dispatched.

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

**Before the dispatch: one suite run, then the tree state.** Run the
project's test commands once, yourself, in the orchestrating session's own
Bash and not through a subagent — the commands the project's instruction
files give for the parts the change set touches, found as
regression-verifier finds its build, test, and lint commands — one at a
time, each command's output in a log under `RUN_DIR/scratch/orchestrator/`
(`scratch/orchestrator/1/suite-<k>.log` on the first attempt). Then write
`RUN_DIR/suite-run.md`: one line per command — the command, its exit
code, its duration, and its log's path — or one line saying the project
gives no test command. A failing command is recorded, not acted on: the
reviewers read the file as evidence. Why: five reviewers each running the
full suite at once exhausted the machine's local ports, and the connection
errors read like findings; one run before the dispatch serves all five,
and each reviewer reads the file instead of running the suite (its
PREREQUISITES). Why yourself: the commands are already known, so a brief
to a subagent costs more than the run, and the logs belong under
`scratch/orchestrator/`, the orchestrating session's own directory.

Then record the tree state in `tree-before.txt`, in the directory that
holds the suite logs: the output of `git rev-parse HEAD` and
`git symbolic-ref -q HEAD` (empty on a detached HEAD), the output of
`git status --porcelain=v1 -uall`, a hash of `git diff HEAD --binary`
(`git diff HEAD --binary | git hash-object --stdin`), and the content
hash of each path the status lists, untracked ones included
(`git hash-object -- <path>`, for each path that exists). Why after the
suite run: a suite that writes into the tree would otherwise read as a
reviewer's change. Why the per-path hashes: a file already changed before
the review keeps its status line when a reviewer changes it again, and
the diff's hash alone would say that something changed but not where;
`git diff HEAD` leaves untracked files out, and an untracked file the
change set holds keeps its `??` line when a reviewer overwrites it, with
no git copy to come back from. Why HEAD: a reviewer's checkout or commit
can leave the tree clean and the diff's hash equal on another commit.

Dispatch **5 subagents in a single message** using the Agent tool, one for
each review angle, every call with `run_in_background: false`. Foreground
calls sent in one message still run in parallel, and the next step reads all
five results in this turn; a background call returns at once, before its
result exists.
A call can still come back with its agent running despite the flag, as one
Desktop session saw once. Its result is then the completion notice that
follows, not the call's reply: wait for that notice before the checks
below, and dispatch nothing meanwhile — not that agent again, and not the
next step's. In a headless session, do not end the turn to wait: wait in
place, one Bash call per iteration,
`n=0; until [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done`, until the
notice arrives after one of those calls. Why: the call's reply carries no
report, so it reads as an agent that failed, and a re-dispatch would write
the same angle beside it, or the next step would start while it still
edits; and a headless session whose turn ends while an agent runs answers
the notice in a new turn, whose result alone `--output-format json`
prints (Claude Code 2.1.302).
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

**After the five return: the tree check.** Once all five have returned —
a re-dispatched reviewer included — and before code-fixer is dispatched,
record the tree state again the same way, in `tree-after.txt` beside the
first, and compare the two. Why two names: a second record written to
the first's paths would overwrite the state it is compared with.
A changed HEAD or branch, a file the first record lists whose status
line or content hash changed, or a changed hash of
`git diff HEAD --binary`, stops the review before code-fixer,
naming the files, or the HEAD before and after; nothing is restored. The stop asks one question: go on
to code-fixer with the tree as the user then leaves it, or end the review
here. In a session that cannot ask (a system reminder to work without
stopping), the run ends with the files named. In an autopilot worker, the
question goes to the main session, as every question there does. An
unchanged tree, and a tree whose only change is a new untracked file,
stops nothing and asks no question; the final report's Next steps names a
new untracked file. Why a stop: a reviewer's command once overwrote a
tracked test file — a flag took the next word as its output file — and
code-fixer would have fixed the tree as it found it. Why no restore: in
an `uncommitted` review the tree holds the user's own changes, and with
five reviewers in parallel nothing tells which one wrote what. Why a new
untracked file does not stop it: a test a reviewer runs may leave an
output file, which costs the user nothing to see in the report, while a
file that was there before the review is the user's work.
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

A ruling on the reviewers' findings, given after they returned and before
code-fixer is dispatched — in an interactive run, a message from the user
received before that dispatch; in an autopilot worker, the main session's
answer to the worker running this review — is written by this skill to
`RUN_DIR/rulings.md` before the dispatch, from the ruling it holds when it
reaches the dispatch, in the form Step 5 of
`${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` (Rulings on the
findings) gives, and under its rules for the `; DEFER rest — <reason>`
tail, an entry naming a group, an entry outside the grammar, and a ruled
ID's unruled duplicate: a first line naming who ruled, then one entry per
ruling, each in one of these forms:

<!-- canonical:rulings-grammar:start -->
```
- <ID>[, <ID>…]: FIX — <what to do>
- <ID>[, <ID>…]: FIX — <what to do>; DEFER rest — <reason>
- <ID>[, <ID>…]: DEFER — <reason>
- <ID>[, <ID>…]: NOT APPLICABLE — <reason>
```
<!-- canonical:rulings-grammar:end -->

This step adds no pause and no question, and waits for no ruling; a
ruling given after code-fixer's dispatch is the second round's (below). The
CONTEXT block passes unchanged, and a ruling never goes into `CUSTOM_INSTRUCTIONS`; with no
ruling, no file is written and nothing changes. Why: as task-review's
Step 5 says — a ruling written into the `CUSTOM_INSTRUCTIONS` of
code-fixer and regression-verifier broke the rule that both get the
reviewers' CONTEXT unchanged, and the run directory is the path both
already read.

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
`total reported N (R n, E n, Q n, B n, T n, F n, V n), deduplicated to N unique, FIXED N, DEFERRED N, NOT APPLICABLE N, DEDUPED N`
<!-- canonical:stats-line:end -->

Its reply carries the statistics line, the `Final checks:` line, the
Per-angle Results table, the HIGH and MEDIUM rows with their Deferred
Issues paragraphs, the scratch-pollution note when there is one, and the
path of schema-b.md. Schema G's Fixes
section renders that reply verbatim, and the LOW rows and their prose stay
in the file. When code-fixer returns, print only this line, the counts
taken from its statistics line:

`code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`

Then dispatch `regression-verifier`, also in the foreground, with the same
CONTEXT block — it reads
the 5 reports and schema-b.md from RUN_DIR itself. The agent verifies that
every issue ID is accounted for, that fixes are real, and that build / test /
lint pass. It returns Schema C (`# / Check / Result / Detail` table plus per-
non-PASS detail prose and a CLEAN or HAS ISSUES result line, which HAS
ISSUES follows with the remaining problems). Schema G's Verification
section renders it verbatim. When it returns, print only
`regression-verifier returned — CLEAN` when its result line is CLEAN, or,
when it is HAS ISSUES, this line naming each non-PASS row with its Result:

`regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`

When code-fixer's reply has no statistics line, or regression-verifier's
reply no CLEAN or HAS ISSUES result line — an error, a refusal such as
regression-verifier's when schema-b.md is missing, or a reply cut short —
print instead the line for that agent,

`code-fixer returned — no statistics line`

or

`regression-verifier returned — no result line`

and Schema G's Fixes or Verification section renders that reply verbatim,
as it came back; the run goes on to the next dispatch — after
regression-verifier, the second fix round below, then Step 4. Why:
counts or a result filled in without that line are made up, and they read
as a step that finished. A reply saying the agent is still running is none
of these: wait for its completion notice, as the Code Review Phase says,
and read that.

<!-- canonical:second-round:start -->
**Second fix round.** As soon as regression-verifier's first reply
returns, save it verbatim to `RUN_DIR/schema-c-1.md`, whatever it says and
whether or not a ruling is held. Why in every review: an autopilot
worker's question names `schema-c-1.md` before any ruling exists, and the
`V` IDs a ruling names are read from it; the save is one file write and
asks nothing.

Then, when this skill holds a ruling given after code-fixer's first
dispatch — in an interactive run, a message from the user received after
that dispatch; in an autopilot worker, the main session's answer — run a
second round:

1. Append a `## Round 2` heading to `RUN_DIR/rulings.md`, followed by the
   round's entries in the grammar the first round's entries follow. When
   the file does not exist, create it first, with its first line naming
   who ruled. A round-2 entry for an ID ruled in round 1 replaces that
   entry: it is not a second entry for the ID, and the round-1 entry no
   longer applies to it.
2. Dispatch `code-fixer`, then `regression-verifier`, each afresh — new
   dispatches, not resumed agents — with `run_in_background: false` and the
   CONTEXT block unchanged; a call that comes back with its agent still
   running is waited on as the Code Review Phase says. code-fixer carries out only the `## Round 2`
   entries and updates `schema-b.md` in place; regression-verifier checks
   the round against them.
3. When each returns, print its line in the form of its first-round line,
   with `(round 2)` after the agent's name:
   `code-fixer returned (round 2) — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`
   and `regression-verifier returned (round 2) — CLEAN`, or
   `regression-verifier returned (round 2) — HAS ISSUES: row <k> <result>[, row <k> <result>…]`;
   for a reply with no statistics line or no result line,
   `code-fixer returned (round 2) — no statistics line` or
   `regression-verifier returned (round 2) — no result line`.
4. Read the verdict from the second round's replies. The final report
   renders them in place of the first round's, and names
   `<RUN_DIR>/schema-c-1.md` for the first round's Schema C.

A review runs at most one second round: a ruling that arrives after the
second round's code-fixer dispatch is not carried out in this review, and
what is left goes to the verdict. With no ruling held, no second round and
no question: the review goes on to its final report, and this step adds no
pause. Why a ruling: a second pass without one would only repeat
code-fixer's own choices. Why one: an unbounded loop inside a review would
bypass the stop conditions that count fixes per defect, and one finding has
taken three rounds in an implementation review and four in a standalone
one. Why fresh dispatches: a resumed subagent has run in the background,
and a headless worker had to wait on it by hand.
<!-- canonical:second-round:end -->

The lines above stay in English, exactly as written, whatever the
conversation language. Why: this run carries the implementation phase
before the review, and everything the orchestrator prints stays in its
context until the final report, where the agents' replies already are as
their results — a table printed between dispatches is paid for a second
time when Schema G prints it. The user following the run needs to know
which agent returned, its counts, and where its report is; the fixed form,
opening with the agent's name, is what the release checklist finds in the
trace, as it finds the Phase 1 boundary lines.

Print each of these lines as plain text, its own line, without the
backticks this file sets it in, and print it as soon as its agent — or
the five reviewers together — has returned and been checked, before any
other dispatch. Why: a run printed the code-fixer and regression-verifier
lines inside backticks, so they no longer opened with the agent's name,
and printed no `Reviewers returned` line at all before dispatching
code-fixer; the user then saw no counts until the final report.

### Step 4: Render the consolidated final report (Schema G)

Render the final consolidated report using Schema G:

```
## Implementation

(Schema D verbatim, including its `## Decisions needing a home` section —
after slices, the merged Schema D of Phase 1 Step 5.)

## Code Review

(Schema A roll-up — the per-angle table, HIGH / MEDIUM / LOW per angle and
in total; rendered here only.)

| Angle | HIGH | MEDIUM | LOW |
|-------|------|--------|-----|
| requirements | <n> | <n> | <n> |
| edge-case    | <n> | <n> | <n> |
| quality      | <n> | <n> | <n> |
| bug          | <n> | <n> | <n> |
| test         | <n> | <n> | <n> |
| **Total**    | <n> | <n> | <n> |

## Fixes

(When `RUN_DIR/rulings.md` exists, first one line naming the file and who
ruled: `Rulings: <RUN_DIR>/rulings.md — ruled by <who>`.)

(code-fixer's reply verbatim, rendered here only: the statistics line, the
`Final checks:` line, the Per-angle Results table, the HIGH and MEDIUM
rows with their Deferred Issues paragraphs, the scratch-pollution note
when there is one, and the full path
of schema-b.md, where the LOW rows and their prose remain. When a second
round ran (Step 3), its reply, which accounts for every row, in place of
the first's.)

## Verification

(Schema C verbatim; rendered here only — when a second round ran, the
second round's, then one line naming the first round's:
`First-round Schema C: <RUN_DIR>/schema-c-1.md`.)

## Verdict

PASS / FAIL / PARTIAL / BLOCKED — one paragraph rationale.
BLOCKED applies when every task in Schema D is BLOCKED; in that case the
Code Review / Fixes / Verification sections are omitted.

## Merge danger

(Built by the `canonical:merge-danger` block below, over the range and
plan this skill names above the block; rendered under every verdict,
BLOCKED included.)

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
task's listed documents to check against the fix commits. When
code-fixer ran and its reply has no statistics line, and the Doc-sync
task is DONE, the FIXED count is unknown, and the bullet is written as for
FIXED greater than 0: from the `Doc-sync documents:` line when the reply
carries one, otherwise in the missing-line form above. Why: the fixes
land after the Doc-sync task, and code-fixer corrects the listed documents
in the fix commits; this bullet is where the user sees which ones changed,
or that none needed to, and a missing line means code-fixer did not meet
its contract, so the correction may not have run — a missing statistics
line is no reason to silence the one bullet that reports it. When the
tree check after the reviewers (Step 2) found a new untracked file, one
bullet names each such file for the user to keep or remove; the plugin
deletes nothing itself. When regression-verifier's test-row Detail names
files under `.kenspc/` that the test run collected and that passed, one
bullet names them as the Detail does and asks the user to delete them —
runs are never deleted and the plugin deletes nothing itself, so a collected
probe that passes stays in the user's own test run until the user removes
it. When CUSTOM_INSTRUCTIONS carried a project structural fact (item 1 of
its construction), one bullet names the fact and where to record it, the
first of these that applies: the document that a Documents table in the
project's instruction files assigns its topic to, unless the fact fails an
admission-rule comment in that document; an instruction file with an
admission-rule comment, such as the AGENTS.md `/kenspc-init` writes — that
file when the fact passes the rule, and otherwise where the comment sends
what fails it; the AGENTS.md a CLAUDE.md imports, with nothing copied into
that CLAUDE.md; the project's AGENTS.md when it has no CLAUDE.md; otherwise
CLAUDE.md. Why: a fact recorded where the project keeps its
instructions reaches the next run without a CUSTOM_INSTRUCTIONS line, and a
CLAUDE.md created beside an AGENTS.md stops Claude Code's default mode from
reading that AGENTS.md.
```

Render every section above in full in this one message, even where Phase 1
Step 5 or a dispatch line printed part of it already: Schema D with each of
its sections under its own heading, `## Decisions needing a home` and
`## Checks run` among them, and Schema C with each Detail cell as the agent
wrote it, its command, exit code, and log path kept. A pointer such as
"listed in full above", or a shortened cell, is not a rendering. Why: the
final report is read alone. A headless run returns only the text after its
last tool call, and an autopilot worker's report is that text, so a section
left in an earlier message is missing from it; and the release checklist
reads each log a Schema C row names. A final report that pointed back at
Step 5's Schema D left out its `## Checks run`, and one that shortened the
test row's Detail dropped the log path the agent had given.

**The `## Merge danger` range and plan.** The block below builds the
section; this skill names the range and the plan it reads. The range is
`<the oldest commit that added TASK_FILE>^..HEAD`, so that commit's own
changes are in it, with HEAD read when the report is rendered, and the
commit found as code-fixer finds it:
`git log --diff-filter=A --reverse --format=%H -- <TASK_FILE> | head -n 1`.
When that commit is the root commit, git's empty tree
(`git hash-object -t tree /dev/null`) stands in for its parent. The header's `<how chosen>` reads `since the task document was added`.
When that command prints nothing, the header reads
`Range: not determined — no commit added the task document`, and the
section holds one `unclear` row saying so. The plan is the path on the task
document's `Related plan:` line, repository-relative: `none named` when the
document has no such line, and `<path> (not found)` when the path does not
exist at HEAD. With every task BLOCKED, the section is still rendered over
this range. Why the document's whole history, not this run's commits: a
task document implemented across several runs leaves as a whole, and
`/kenspc-task`'s reviewer and `/kenspc-diagnose` both commit the document
before any implementation, so its oldest adding commit marks where the
batch starts without a new pin. Why its parent: a task document written by
hand and left uncommitted is added by the first task's own commit, code
and status together, and a range that started at that commit would leave
that task's changes out. Why under BLOCKED: the commits earlier runs
made still leave with the document.

<!-- canonical:merge-danger:start -->
**Merge danger.** The `Merge danger` section tells the user, in plain
words, which changes in the run's range cannot be undone and how far a
failure would reach, and every claim in it names the file and line it rests
on. The orchestrating session builds it itself, before the final report,
with no agent dispatched; the skill that carries this block, the carrier,
names the run's range and the plan outside it. Why: the work is a file
list, a read of the matched files, and a read of two documents, and a
dispatch costs more than it does.

- **Inputs.** The run's range; the deployment document — the one the
  project's instruction files name, otherwise `docs/deployment.md` — whose
  `## Migrations` and `## Rollback` sections answer whether a change can be
  undone in one step, and every path it names is a signal; and, in the plan
  the carrier names, the section whose heading begins `## Risks`. Without a
  deployment document the built-in signals stand alone; without a plan, or
  in a plan with no such section, `plan-risk` has no input and matches
  nothing. Why: the project's own one-way doors are written in its
  deployment document, and the plan's risks were judged before the code was
  written; the final report is where both would otherwise be lost.
- **Signals.** Eight, each with a fixed English name, checked over every
  file in the range:

  | Signal | Read from | Matches |
  |---|---|---|
  | `schema` | the file list and the files | a path the deployment document's Migrations section names, a path with a `migration` or `schema` segment, or a changed file holding DDL |
  | `removal` | the file list and removed lines | a path with status `D` or `R`; a removed line that declared a public symbol, a field, a column, or a route |
  | `contract` | the changed files | a file that defines what another program calls or reads: routes and handlers, OpenAPI, GraphQL, or protobuf schemas, a package's exported entry point, a CLI's flags, a webhook or message format |
  | `config` | the file list | configuration, an environment example, a CI workflow, a container or infrastructure file |
  | `dependency` | the file list | a package manifest or lock file |
  | `outside-write` | added lines | code that writes data outside the repository: a database, a queue, an external API, a file outside the working tree, a message or email sent |
  | `deploy-doc` | the deployment document | a path or rule the document names that the range touches |
  | `plan-risk` | the plan's Risks | a risk whose subject a changed file touches |

  Path signals are matched on the file list alone: `schema`'s path part,
  `removal`'s `D` and `R` statuses, `config`, `dependency`, and
  `deploy-doc`. Content signals are matched on lines the session reads:
  `contract`, `outside-write`, `plan-risk`, and the content parts of
  `schema` (DDL) and `removal` (a removed declaration). Why: a path match
  can be checked by re-running it; a content judgement can only be checked
  by reading the evidence, so the reader needs to know which is which.
- **Reading.** First the range's file list,
  `git diff --name-status <range>`; then, file by file, only the added and
  removed lines, `git diff -U0 <range> -- <path>` — or the commands the
  carrier names for a range that ends at the working tree. A file whose
  `-U0` diff the session did not read, for any reason, stopping to protect
  its context included, is named in an `unclear` row and never counted in a
  `two-way` row. Why: the orchestrating session has a context to protect,
  and a file nobody read cannot be called reversible.
- **Labels.** `two-way`: one `git revert` of the change's commits — or a
  discard of an uncommitted change — followed by the project's usual
  release, restores the state before the change, with no data lost and
  nobody outside the team needing to act. `one-way`: it does not.
  `unclear`: the evidence read does not settle it, and the row names what
  would. Why one step: a fixed test is what lets two readers label the same
  change alike. Why `unclear`: without it, a session that lacks the
  evidence guesses `two-way`.
- **Rows.** One row per change that matched a signal, not one per file: a
  change that spans several files is one row that lists them all. Each row
  gives its label and the change in plain words, then three answers in the
  report's language — what users see or do differently; whether it can be
  undone in one step, and why; who a failure reaches: this machine only,
  the team, the product's users, or people and systems outside it — then
  one short technical line, and `Evidence:` with the signal names and each
  `file:line` the row rests on. An `unclear` row also names the missing
  evidence. A signal-matched row without a `file:line` is not written; an
  `unclear` row that has none to give — for files whose diff was not read,
  or for a range not determined — names the files or the cause in its
  place. Why one row per change: a batch that touches many configuration
  files would otherwise fill the section with rows that say one thing. Why
  the evidence: a door named without evidence cannot be checked, and the
  user decides from this section alone.
- **Catch-all.** The last row, labelled `two-way`, covers every changed
  file no signal matched: their count, the range, and each signal's count
  over those files — path signals first, then content signals — each zero,
  which is what the row asserts and what a reader re-runs to check. It
  never says "low risk". When every file matched a signal, the row is still
  written, over zero files. Why: a zero the reader can re-run is evidence,
  "low risk" is not, and the split shows which zeros one command checks and
  which rest on reading.
- **Header.** Before the rows: `Range: <range> (<how chosen>)`,
  `Deployment document: <path | not found>`,
  `Plan: <path | <path> (not found) | none named>`, then, on its own line,
  `Count: <n> one-way, <u> unclear, <m> two-way`, which counts rows, the
  catch-all among the `two-way` ones. `Plan:` reads `none named` when the
  carrier names no plan, and `<path> (not found)` when the named path does
  not exist where the carrier reads it. Why: the header says what the rows
  were read against, so a missing input shows as missing rather than as a
  change that matched nothing.
- **Language.** Fixed in English whatever the report's language: the
  heading `Merge danger`, the labels `one-way`, `two-way`, and `unclear`,
  and the eight signal names. Everything else — the header's field names,
  the three answers, `Evidence:`, the empty-range line — follows the
  report's language. Why: a fixed heading and fixed labels are what a
  search, a guard, and a count can find; the rest is written for the user.
- **Empty range.** A range that holds no change makes the section one line:
  `none — the range holds no change`. Why: a header and a catch-all over no
  file would read as a change that was checked and found safe.
- **Not a gate.** The section changes no verdict and asks nothing. Why: the
  report already gates on correctness; this section informs the decision
  to let the work out, which stays the user's.

A rendered section, below its heading:

```
Range: 3f2a1c0..9b7e4d2 (since the task document was added) · Deployment document: docs/deployment.md · Plan: docs/plans/auth-plan.md
Count: 1 one-way, 1 unclear, 2 two-way

1. `one-way` — the users table loses its legacy_token column
   - What users see or do: nothing changes for them
   - Undo in one step: no — the migration drops the column and its data; docs/deployment.md § Rollback restores code only
   - Who a failure reaches: every user who still signs in with a legacy token
   - Detail: migration 0042 drops users.legacy_token
   - Evidence: schema, removal — db/migrations/0042_drop_legacy_token.sql:3, docs/deployment.md:41
2. `unclear` — the session cookie's lifetime moves to configuration
   - …
   - Missing evidence: whether production sets SESSION_TTL; .env.example:12 does not say
   - Evidence: config — src/config.ts:18, .env.example:12
3. `two-way` — the login form's error text
   - …
   - Evidence: contract — src/routes/auth.ts:40
4. `two-way` — every other change (7 files): no signal matched in 3f2a1c0..9b7e4d2 — paths: schema 0, removal 0, config 0, dependency 0, deploy-doc 0; content: contract 0, outside-write 0, plan-risk 0
```
<!-- canonical:merge-danger:end -->

#### Verdict determination

- **PASS** — every task DONE, none left unrun by the slices (Phase 1
  Step 4); zero HIGH unresolved; build / tests / lint
  PASS or `SPOT-CHECK` on row 3 (no-test-suite fallback); no regressions
  introduced by fix commits; no ruled row whose action differs from its
  ruling, outside the exception for a fix that could not land, no ruled
  ID that no report lists, and no entry of `RUN_DIR/rulings.md` outside
  its grammar (below).
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
- The verdict reads Schema C rows 2–4's exit codes as reported: the
  orchestrating session confirms a row by reading the log its Detail names,
  and runs no build, test, or lint of its own. A row 2–4 whose Detail
  carries neither an exit code nor a no-command form (`no build command in
  the project`, `no lint command in the project`, or row 3's SPOT-CHECK
  fallback text) keeps the verdict from PASS: PARTIAL, unless a FAIL
  condition holds. So does a row whose named log is missing, or shows an
  exit code or a failure its Detail does not report, and the Verdict
  paragraph names the row and what its log shows. Why: regression-verifier
  is this skill's confirmation step, so a third full run adds load and no
  independence, and a row with no evidence is a verdict nobody can check
  without re-running it; a log that contradicts its row is the
  confirmation failing.
<!-- canonical:verdict-shared:end -->
- **FAIL** — at least one HIGH unresolved; or one or more INCORRECTLY
  FIXED items; or build / test / lint failure; or fix commits introduced
  unresolved regressions.
- **PARTIAL** — neither PASS nor FAIL applies cleanly; for example, HIGH
  issues are deferred with explicit rationale and the user must decide.
- A ruled row whose action differs from its ruling — a row
  `RUN_DIR/rulings.md` ruled FIX that is not FIXED, DEFER that is not
  DEFERRED, or NOT APPLICABLE that is not NOT APPLICABLE, as
  regression-verifier's row 1 names it — keeps the verdict from PASS:
  PARTIAL, unless a FAIL condition holds, whatever the row's severity. The
  exception is a FIX ruling code-fixer DEFERRED with the reason that its
  fix could not land — its build / test / lint run failed, or the ruling's
  text could not be carried out in the code as it stands — which stays a
  deferral, counted by its severity like any other. Why: as task-review's
  Verdict determination says — a ruling not carried out is a decision the
  run overrode, and under a PASS it would reach the reader only in a row-1
  Detail, while a fix that could not land changed nothing against the
  ruling.
- A ruled ID that no report lists — an ID `RUN_DIR/rulings.md` names that
  no reviewer's Issues table holds, which regression-verifier's row 1
  names as a bookkeeping error and code-fixer's reply names — keeps the
  verdict from PASS as a ruled row whose action differs does: PARTIAL,
  unless a FAIL condition holds. Why: as task-review's Verdict
  determination says — it is a ruling not carried out as well, and under a
  PASS it would reach the reader only in a row-1 Detail.
- An entry outside the grammar — an entry of `RUN_DIR/rulings.md` that
  task-review's Step 5 says is not carried out (an unknown action word, no
  ID, no first line naming who ruled, one ID in two entries of the same
  round), which regression-verifier's row 1 names and code-fixer's reply
  names — keeps the verdict from PASS as a ruled ID that no report lists
  does: PARTIAL, unless a FAIL condition holds. Why: as task-review's
  Verdict determination says — it is a ruling not carried out too, and
  under a PASS it would reach the reader only in a row-1 Detail.
- **BLOCKED** — every task in Schema D is BLOCKED; Code Review / Fixes /
  Verification sections are omitted from the report, and Merge danger is
  still rendered.

The Next steps bullets must give the user enough detail to act on every
HIGH or MEDIUM DEFERRED, BLOCKED, or unresolved item, and every task the
slices left unrun, without reading the
review reports or commit history; LOW deferred items stay one path away in
schema-b.md.
