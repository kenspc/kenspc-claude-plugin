---
name: diagnose-bug
description: >
  Reproduce and diagnose a bug the user has observed (修 bug / 排查 bug),
  then write a task document for /kenspc-task-implement — or a brief for
  /kenspc-plan when the fix touches an API contract, a database schema, a
  new dependency, or project configuration. Use only when the user asks to
  fix a specific bug they have observed: a wrong result, a crash, an error
  they can trigger. Not for explaining an error message or a stack trace
  (answer directly), not for finding bugs in code (use task-review), and
  not for a fix the user can already name that touches one file and needs
  no new test (just make it). Trigger on: "fix this bug", "this crashes
  when", "why does this return the wrong", "帮我修这个 bug",
  "这个 bug 怎么修", "排查一下为什么", "诊断一下这个问题", or invokes
  /kenspc-diagnose directly.
version: 3.0.0
argument-hint: <observed bug, or path to a bug report>
---

# Diagnose Bug

Reproduce a bug the user has observed, find its root cause, and write the
work that fixes it. Three phases: Reproduce, Diagnose, Produce. No review
phase — the user confirms the task list before it is written, and
task-implement's batch gate confirms it again before anything runs.

Three tiers decide where a bug goes:

- **Tier 1** — a fix the user can name that touches one file and needs no
  new test. It is made directly; this skill is not invoked (see Trigger
  Phrases).
- **Tier 2** — every other fix the implementer can make on its own. The
  skill writes a task document for `/kenspc-task-implement`: a fix task, a
  regression-test task for the adjacent cases the diagnosis found, and a
  Doc-sync task when durable documents are affected.
- **Tier 3** — a fix that needs a new dependency, a change to an existing
  API contract, a database schema change, or a project configuration
  change. The skill writes a brief for `/kenspc-plan` instead, and no task
  document.

## Trigger Phrases

Use this skill when the user asks to **fix a specific bug they have
observed** — a wrong result, a crash, an error they can trigger — using
phrases like: "fix this bug", "this crashes when", "why does this return the
wrong", "this used to work and now it fails", "it throws when I", "find out
why this breaks", "帮我修这个 bug", "这个 bug 怎么修", "排查一下为什么",
"诊断一下这个问题", "这里出错了，帮我查一下", "为什么结果不对",
or invokes `/kenspc-diagnose` directly.

Avoid triggering this skill when the user:

- Asks what an error message or a stack trace means ("what does this error
  mean", "what is this stack trace", "这个报错是什么意思") — answer
  directly, no skill needed.
- Asks to find bugs in code ("check this code for bugs", "review this for
  bugs") — use task-review instead.
- Names a fix that touches one file and needs no new test ("the null check
  on line 40 is missing", "change the timeout to 30 seconds") — just make
  it. This is tier 1, and task-implement's rule for a single specific task
  already says the same: just do it directly, no skill needed.
- Asks for new behavior phrased as a bug ("it should also export to CSV",
  "it doesn't support dark mode") — use generate-plan, or generate-brief
  when the idea is still rough.

Tier 1 is judged here, at trigger time, and nowhere else. Why: inside the
skill a reproduction test always exists, so "needs no new test" can no
longer hold, and the fix scope that would show a one-file fix is only known
after the diagnosis. After a diagnosis, the tier is 2 or 3.

## Quality bar

A useful diagnosis reproduces the bug before explaining it, names one root
cause with the evidence that rules the alternatives out, and leaves a task
document — or a brief — that an implementer can act on without diagnosing
again. A fix proposed without a reproduction is a guess.

## Prerequisites

- An observed bug: what happened, and how it was triggered.
- A project in a git repository. Why: the skill commits the reproduction
  test and the task document, and `/kenspc-task-implement` reads what was
  built from git history.

## Arguments

$ARGUMENTS format: BUG

- BUG: free text describing what was observed and how it was triggered, or
  a file path (an issue export, a log, a bug report) that the skill reads.
  When the first token looks like a file path (starts with `./` or `/`, or
  ends with `.md`, `.txt`, or `.log`), read that file and use its contents
  as the bug report.

If no arguments are provided, ask the user what they observed and how to
trigger it.

## Phase 1: Reproduce

**Goal**: a test that fails on the current code for the reason the bug
describes — or, when no failing-capable test can be written, the manual
reproduction steps and the reason.

**Inputs**: BUG; the project's CLAUDE.md, README, and config files, read
silently first — they name the test framework, its file conventions, and the
commit conventions; the code the bug runs through. Before writing anything,
note the untracked files `git status --porcelain -uall` lists (`??`) — with
`-uall`, each file rather than its directory — so the files this run
creates can be told apart from the user's.

**DONE when** either holds:

- A reproduction test is written in the project's test tree, under the
  project's test framework and naming conventions — a name the runner
  collects, since it is a test and not a probe; it has been run and failed
  for the reason the bug describes, not on a setup or import error; its
  failure is summarized for the record; and it is committed alone as
  `test: reproduce <symptom>`, adapted to the project's commit conventions,
  staging only that file and passing its path to `git commit` as a pathspec
  so nothing else the user has staged joins it.
- No failing-capable test can be written — the bug needs hardware, a real
  device, or a Bluetooth peripheral, or the project has no test framework
  configured — and the record holds the manual reproduction steps as a
  numbered list and the reason no failing-capable test exists, in the shape
  of the design-concern note `task-implementer`'s QUALITY CHECKLIST asks for
  when it cannot write a test that can fail.

Why the test comes first, and why it is committed: the test is the artifact
Phase 2 and the fix task rest on. A file left in the working tree is lost to
a stash, a checkout, or another change in progress; a commit is what the
implementer's `git log` sees. The branch is red from this commit until the
fix task lands, which is the true state of the code, and it stays true when
the fix task is BLOCKED.

**A commit that fails.** When this commit, or the task document's commit in
Phase 3, fails — a commit hook rejects it, or git refuses a pathspec commit
during an unfinished merge — stop, report the error, and ask the user how to
go on. Do not retry, and do not bypass the hook with `--no-verify`. A hook
that runs the test suite rejects the reproduction commit every time, since
the test fails by design, and then rejects the task document's commit while
that test is in the tree; committing past such a hook is the user's
decision, and the run continues from the commit once the user has made it.
Why: the hook encodes the project's rules, and a bypass the user did not
choose changes how their repository is guarded.

With no test framework configured, a plain reproduction script under the
diagnosis run directory's scratch (Phase 2, Probes) may support the manual
steps. It is evidence, not the test.

**Not reproduced.** When the bug does not reproduce after trying what BUG
describes, stop and ask the user for what is missing. First remove the
reproduction-test files this run wrote — each path the skill itself created
as a test, and only while `git status --porcelain -uall -- <path>` still
reports it untracked (`??`) and the list noted at the start does not hold
it — and nothing else: never a tracked file, never a file the user added
during the session, never anything under `.kenspc/`. Why only the paths the
skill wrote: an untracked file has no copy in git, so removing one the user
saved while the diagnosis ran would lose it for good. Then ask, listing each
attempt: the test's path, what it exercised, and what happened. If the
removal is denied, the question names those files as left in place for the
user to remove. The run ends with no task document or brief, no commit other
than the one-time `.gitignore` commit when a reproduction script prepared
the run directory (Constraints below), and no untracked test file left by
the skill. Why: a test that did not reproduce
the bug is not a test; left in the test tree under a collectable name, it
passes silently in the user's own suite and asserts that the bug is absent.

**Constraints**:
- This phase modifies no tracked file —
  other than the one-time `.gitignore` commit, when it prepares the run
  directory for a reproduction script in a project that does not yet ignore
  `.kenspc/` (Phase 2, Probes).
  The reproduction test is the only project file it creates. Why: the
  diagnosis reads the user's code; any other change would belong to neither
  the fix nor the user's own work in progress.
- Match the user's language in the conversation.

## Phase 2: Diagnose

**Goal**: one root cause with the evidence, the fix scope, the adjacent
cases, the tier, and the documentation impact.

**Inputs**: the reproduction from Phase 1 (the test's path, commit, and
failure summary, or the manual steps); the code; the project's CLAUDE.md for
the durable documents.

**DONE when** the record fields Root cause, Hypotheses, Fix scope, Adjacent
cases, Tier, and Documentation impact can be filled.

### Hypothesis loop

When the reproduction shows the root cause directly, Hypotheses records
`none — the root cause was visible on reproduction`. Otherwise, list three to
five hypotheses at once, each with how it will be verified — a probe, a log
line, a bisect, reading a code path. Verify each in turn, record each outcome
with its evidence (confirmed, or ruled out and by what), and converge on one
root cause. When none survives and no new hypothesis is grounded in evidence,
stop and ask the user — for a log, an environment detail, another
reproduction — rather than guessing. Why: listing the hypotheses before
testing any keeps the first plausible one from ending the search, and the
recorded outcomes are the evidence that rules the alternatives out.

### Probes

When a hypothesis needs a probe, a copy, or a mutant, prepare a run
directory as the run-directory preparation in
`${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` prescribes — the block
between `<!-- canonical:run-dir:start -->` and
`<!-- canonical:run-dir:end -->`, its RUN_DIR, Scratch space, and Ignore
check bullets — with one change: the run-id's suffix is `diagnose-<name>` in
place of a task document's name, `<name>` being the slug Phase 3 gives the
task document. The directory is then
`.kenspc/runs/<YYYYMMDD-HHMMSS>-diagnose-<name>/`. The diagnosing session is
the orchestrator, so everything it writes goes under
`RUN_DIR/scratch/orchestrator/<n>/`, under that block's naming and
numbered-attempt rules. The record's Probes field names the directory.

- The diagnosis modifies no tracked file,
  other than the one-time `.gitignore` commit the Ignore check makes in a
  project that does not yet ignore `.kenspc/`. Why the exception holds: the
  change is one-time and visible in history, and the pathspec keeps
  everything else out of it.
- A "does this change remove the symptom" experiment runs on a copy under
  scratch, never on the project's own files.
- A mutant used as evidence follows the three-step mutation rule the review
  agents apply in their scratch space (the RUN_DIR bullet of
  `${CLAUDE_PLUGIN_ROOT}/agents/regression-verifier.md`): the unmutated copy
  passes first, a deliberately broken control mutant fails next, and only
  then does a failing mutant count as evidence.

Why: an implementing agent has run its mutation checks on the project's own
source files in place, editing them with `sed -i` and restoring them with
`cp`, and a run that stops between the mutation and the restore leaves the
user's code mutated. Keeping every probe, copy, and mutant under scratch
leaves nothing to restore.

### Tier

Tier 3 when the fix requires any of:

- a new dependency;
- a change to an existing API contract (parameters, return type, error
  codes);
- a database schema change;
- a project configuration change (tsconfig, eslint, prettier, and the like).

Otherwise tier 2. Why: these are the decisions `task-implementer` stops on —
its AUTONOMY BOUNDARIES mark a task BLOCKED on each — so a task document
carrying one would be BLOCKED in an unattended run. Deciding them is plan
work, which generate-plan's discovery exists for.

### Fix scope, adjacent cases, documentation impact

- **Fix scope**: the files the fix touches — the evidence for tier 2 and the
  boundary of the fix task.
- **Adjacent cases**: boundaries and sibling code paths the root cause
  implicates, each a candidate regression test. An empty list is stated as
  `none — <reason>`, not left out.
- **Documentation impact**: the durable documents the fix makes stale,
  determined as generate-plan determines its Documentation impact element —
  the project CLAUDE.md's documentation table where one exists, otherwise
  the documents it names in prose, otherwise README.md and CLAUDE.md. It is
  a list (path, section where known, what changes) or the single line
  `N/A — <reason>`.

## Phase 3: Produce

**Goal**: the artifact the next step runs on — for tier 2 a committed task
document, for tier 3 a brief.

**Inputs**: the filled record from Phase 2; the project's CLAUDE.md
(document locations, commit conventions); the Doc-sync Task template in
`${CLAUDE_PLUGIN_ROOT}/skills/generate-task/SKILL.md`; the brief template in
`${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md`.

**DONE when**:
- Tier 2: the user has confirmed the task list, and the task document is
  written and committed alone.
- Tier 3: the brief is written, and the user has been told its path and the
  `/kenspc-plan <path>` suggestion.

### Tier 2: the task document

**Output path** (priority order):
1. A CLAUDE.md-specified task-document location.
2. `docs/tasks/<name>.md` (create the directory if missing).

`<name>` is a kebab-case slug of the symptom, with no suffix or prefix —
"export crashes on an empty cart" becomes `export-crash-empty-cart`. The
same `<name>` names the tier-3 brief and the run directory's
`diagnose-<name>` suffix.

**Conflict check**: if a file already exists at the target path, ask the
user: overwrite, create alongside (with a suffix), or cancel.

**Content**, in this order:

1. A title: `# <Symptom> — Task Document`.
2. A Dependency note, as generate-task writes one when any task has a
   `Depends on` line.
3. The record:

   ```markdown
   ## Diagnosis

   **Symptom:** <what was observed, and how it is triggered>

   **Reproduction:** <the test's path, its commit, and a one-sentence
   summary of the failure — or the manual steps as a numbered list and the
   reason no failing-capable test exists>

   **Root cause:** <the cause, with file and line, and the evidence>

   **Hypotheses:** <none — the root cause was visible on reproduction; or
   each hypothesis, how it was verified, and its outcome with the evidence>

   **Fix scope:** <the files the fix touches>

   **Adjacent cases:** <each boundary or sibling code path, or none — <reason>>

   **Tier:** 2 — <files in Fix scope; no contract, schema, dependency, or configuration change>

   **Documentation impact:** <a list: path § section — what changes (Task N); or N/A — <reason>>

   **Probes:** <the diagnosis run directory, or none>
   ```

4. `## Tasks`, holding the tasks below.

No `Phase N` or `Step N` heading appears anywhere in the document, and
manual reproduction steps are an ordinary numbered list. Why: task-implement
accepts a task document by its `**Status:**` markers, and `task-implementer`
marks a document that carries both Status markers and a Phase/Step structure
as ambiguous and stops.

**Task 1 — the fix.** `### Task 1: Fix <root cause>` with
`**Status:** TODO`: the root cause, the reproduction test's path, and the
files in Fix scope. Acceptance criteria:
- the reproduction test passes;
- the project's full test suite, its build, and its lint pass;
- no file outside Fix scope is modified (the task document's status update
  aside).

For a manual reproduction, the criteria read instead: the build and lint
pass; the manual reproduction steps in `## Diagnosis` no longer show the
symptom — verified by the user after the run, and recorded by the
implementer as not verified in the task's `**Implementation notes:**`
block; no file outside Fix scope is modified. Why: `task-implementer` cannot
run manual steps, and a DONE that claimed them would be partial completion
marked done.

**Task 2 — regression tests.** `### Task 2: Regression tests for <adjacent
cases>` with `**Status:** TODO` and `Depends on: Task 1`: one test per
adjacent case the record lists, in the project's test framework and
conventions, each able to fail if the behavior it covers broke. Omit this
task when Adjacent cases is empty; the record then says so. Why: the
reproduction test already covers the symptom, and `task-implementer` already
writes tests for the code a fix adds, so this task has content only when the
diagnosis found cases beyond the symptom.

**Doc-sync task.** When Documentation impact lists documents, the last task
is `### Task N: Doc-sync`, written from the Doc-sync Task template in
`${CLAUDE_PLUGIN_ROOT}/skills/generate-task/SKILL.md` with two
substitutions: "the plan's Documentation impact" reads "the diagnosis's
Documentation impact", and each entry's cause is the task that makes the
change (`Task 1`) in place of a plan step. Its dependency line is
`Depends on: Task 1-<N-1>`, or `Depends on: Task 1` when Task 1 is the only
other task. When Documentation impact is `N/A — <reason>`, there is no
Doc-sync task. Why: the template carries its instructions in the task's own
text, so one copy serves every skill that writes the task; a second copy
here would drift from it.

**Confirm before writing.** Present the record's root cause and tier, then
the task list as generate-task's Phase 2 presents it — each task with its
file count and a one-sentence criteria summary, the Doc-sync task like any
other — and ask the user to confirm or adjust. Apply adjustments and present
the list again. The record is written as diagnosed; the user may correct a
fact in it. In a session that cannot ask (a system reminder to work without
stopping), present the list and write it as presented. Why: no reviewer
runs on this document, so the user's confirmation is its gate.

**Commit after writing.** Commit the document alone:
`docs: add task <name>`, adapted to the project's commit conventions,
staging only that file and passing its path as a pathspec. A commit that
fails stops the run as Phase 1 describes. Why: `task-implementer` commits
each task's status into this file, and without a baseline commit its first
commit would carry the whole document.

### Tier 3: the brief

Write a brief at `docs/briefs/<name>.md` — a CLAUDE.md-specified brief
location takes precedence — with the same conflict check. Its first line is
`# Requirement Brief: <title>`, the line generate-plan recognizes a brief by.
Use the brief template in `${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md`
with this mapping:

- **Outcome** — the corrected behavior.
- **Scope** — the fix, and what it leaves alone.
- **Failure Modes** — the symptom and the adjacent cases.
- **The Hard Part** — the root cause, the tier-3 category that escalated it
  (the tier is stated here), and the fix directions considered.
- **Constraints** — what the project's code and configuration fix in place.
- **Context** — the reproduction (the test's path and commit, or the manual
  steps), the hypotheses and their outcomes, and the probe directory.
- **Discovery Notes** — produced by diagnose-bug from a diagnosis, with no
  discovery conversation. No `Discovery Mode:` field. Why: that field is the
  contract of generate-brief's discovery modes, which this skill does not
  run.

Write no task document, and do not commit the brief, as generate-brief does
not commit its own. Tell the user the path and suggest
`/kenspc-plan <path>`; do not invoke it. Why: a contract, schema, dependency,
or configuration change is a decision generate-plan's discovery exists to
make — the diagnosis has the evidence, not the mandate — and the reproduction
test is already committed, so the plan inherits it.

## Exit

Tier 2 only. Ask one question: run `/kenspc-task-implement <path>` now, or
implement interactively.

- On "run": invoke the task-implement skill through the Skill tool with the
  path as its argument. Its own batch gate confirms once more; that gate is
  task-implement's, not this skill's.
- On "interactively": stop. The task document stands, committed, for the
  user to work from.
- In a session that cannot ask (a system reminder to work without
  stopping): the document is written; print the suggestion
  `/kenspc-task-implement <path>` and stop.

For a manual reproduction, the exit message says Task 1 cannot be verified
unattended: the implementer records the manual-steps criterion as not
verified, and the user runs the steps after the run.

Why a question rather than a suggestion: the handover is the default path,
and task-implement runs only on an explicit request, which the answer
"run" is.

## Writing rules for the document

These apply to the task document and to the brief.

- Language: the language of the diagnosis conversation, unless the user
  asks otherwise.
- Anchors stay exactly as written, whatever the document's language: the
  `**Status:**` line and its value, the `Depends on:` line,
  `### Task N: Doc-sync`, and the `## Diagnosis` heading with its nine
  labels. Why: `task-implementer` reads a task's state and dependencies from
  the first two, and a translated anchor breaks the chain without an error.
- Text the implementer will carry into code artifacts — commit-message text,
  identifiers, test names — is in English.
- Acceptance criteria are concrete: no "as appropriate", "if needed", or
  "properly".
- No branch, pull-request, rebase, or tag step unless the user asked for
  one; the default is commits on the current branch.

Why: no reviewer runs on this document, so the checks
`task-document-reviewer` would make — vague criteria, language carried into
code artifacts, a git step nobody decided — are made here, while writing.

## Phase transitions

Each phase starts from the artifact the previous one produced, not from the
wording that closed it:

- Phase 1 → Phase 2: the committed reproduction test (its commit hash), or
  the recorded manual steps.
- Phase 2 → Phase 3: the filled record.
- The exit: the committed task document, or the written brief.

Why: a phase's closing sentence has been read as the end of a whole skill
run; the next phase reads an artifact, so the artifact is what moves the run
forward.
