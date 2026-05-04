---
name: task-implement
description: >
  Automated batch implementation: auto-implements ALL incomplete tasks from a task
  document without user interaction, then runs automated code review. Only use when
  the user explicitly requests automated/batch task implementation.
version: 3.0.0
effort: xhigh
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
the user:

```
Found N incomplete tasks to auto-implement:
1. Task X: [brief name]
2. Task Y: [brief name]
...
Proceed with automated implementation?
```

Wait for explicit confirmation before proceeding. If the user declines or
wants to adjust scope, follow their instructions instead.

### Step 4: Render Planned Dispatch table and dispatch the implementer

Render this Planned Dispatch table:

| # | Agent | Status |
|---|-------|--------|
| 1 | task-implementer | pending |

Tell the user: "Starting task implementation. Dispatching implement agent
now."

Then dispatch a subagent using the Agent tool:
- Agent name: `task-implementer`
- description: "Implement tasks from document"
- prompt: the CONTEXT block from Step 2

The subagent implements all incomplete tasks within its own context and
returns a Schema D summary. No state file is written by the orchestrator.

### Step 5: Render Schema D and brief progress update

Render the implementer's Schema D table verbatim:

| # | Task ID | Status   | Files Touched | Commit  |
|---|---------|----------|---------------|---------|
| 1 | T-001   | DONE     | a.ts, b.ts    | abc1234 |
| 2 | T-002   | BLOCKED  | —             | —       |

Below the table, render the BLOCKED prose, Decisions made, and Post-
implementation notes verbatim from the agent's output.

Then present a brief progress update to the user:

```
Implementation phase complete.
- Completed: N tasks (Task X, Task Y, ...)
- Blocked: N tasks (Task Z: [brief reason], ...)
Proceeding to code review.
```

If every task in the Schema D table is BLOCKED, replace the last line with
"All tasks blocked. Skipping code review." and skip directly to Phase 2
Step 4 (final report) — Code Review / Fixes / Verification sections are
omitted; verdict = BLOCKED.

Full implementation details appear in the final report (Phase 2 Step 4).

## Phase 2: Automatic code review

After Phase 1, check the implementation results:
- If at least one task was successfully implemented, proceed to the
  unconditional code review (Steps 1-4).
- If every task in Schema D is BLOCKED, skip to Step 4 to render a Schema
  G consolidated report with verdict = BLOCKED and Code Review / Fixes /
  Verification sections omitted.

### Step 1: Construct review CONTEXT block

Build the CONTEXT block:
- `TASK_FILE` = the same task document path from Phase 1.
- `REVIEW_SCOPE` = "task".
- `CUSTOM_INSTRUCTIONS` = "N/A" unless the user provided specific review
  instructions.

```
CONTEXT
- TASK_FILE: <task path from Phase 1>
- REVIEW_SCOPE: task
- CUSTOM_INSTRUCTIONS: N/A
```

### Step 2: Render Planned Dispatch table

Render this 5-row Planned Dispatch table so the user sees the planned
dispatch:

| # | Agent | Status |
|---|-------|--------|
| 1 | requirements-reviewer | pending |
| 2 | edge-case-reviewer | pending |
| 3 | quality-reviewer | pending |
| 4 | bug-reviewer | pending |
| 5 | test-reviewer | pending |

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
each review angle. Each subagent is read-only — it analyzes code and
produces a report but does not modify any files. Pass the CONTEXT block
from Step 2 as the dispatch prompt for every agent.

- Agent name: `requirements-reviewer`, description: "Review: requirements"
- Agent name: `edge-case-reviewer`, description: "Review: edge cases"
- Agent name: `quality-reviewer`, description: "Review: code quality"
- Agent name: `bug-reviewer`, description: "Review: bug hunting"
- Agent name: `test-reviewer`, description: "Review: test coverage"

After all 5 agents return, verify each one produced a complete report. If
any agent returned an error, an empty response, or an obviously incomplete
report, re-dispatch the failed agent(s) with the same CONTEXT block. If
the re-dispatch also fails, stop and inform the user which angles are
missing.

### Step 3: Aggregate and dispatch fix + regression agents

Aggregate the 5 review reports into a Schema A roll-up table (HIGH /
MEDIUM / LOW per angle and total).

Dispatch `code-fixer` with the CONTEXT block extended by `REVIEW_REPORTS`
(all 5 reports inline, separated by `---` lines). The fix agent
deduplicates findings, applies fixes, commits, and returns Schema B
(`# / short_label / Severity / File:Line / Action / Commit` table plus
Deferred Issues prose). Render Schema B verbatim.

Then dispatch `regression-verifier` with the CONTEXT block extended by
`REVIEW_REPORTS` and `ACCOUNTABILITY_LIST`. The agent verifies that every
issue is accounted for, that fixes are real, and that build / test / lint
pass. It returns Schema C (`# / Check / Result / Detail` table plus per-
non-PASS detail prose). Render Schema C verbatim.

### Step 4: Render the consolidated final report (Schema G)

Render the final consolidated report using Schema G:

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

#### Verdict determination

- **PASS** — every task DONE; zero HIGH unresolved; build / tests / lint
  PASS; no regressions introduced by fix commits.
- **FAIL** — at least one HIGH unresolved; or one or more INCORRECTLY
  FIXED items; or build / test / lint failure; or fix commits introduced
  unresolved regressions.
- **PARTIAL** — neither PASS nor FAIL applies cleanly; for example, HIGH
  issues are deferred with explicit rationale and the user must decide.
- **BLOCKED** — every task in Schema D is BLOCKED; Code Review / Fixes /
  Verification sections are omitted from the report.

The Next steps bullets must give the user enough detail to act on every
DEFERRED, BLOCKED, or unresolved item without reading the raw review
reports or commit history.
