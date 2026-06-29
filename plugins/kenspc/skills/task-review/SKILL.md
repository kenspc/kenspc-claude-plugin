---
name: task-review
description: >
  Thorough code review (代码审查/review代码) using 5 parallel review agents, a fix
  agent, and a regression verification agent. Use for ANY code review request —
  not overkill, each agent covers a different angle (bugs, edge cases, tests,
  security, conventions). Works with a task document (review against requirements)
  or standalone (review recent changes/uncommitted code).
version: 3.0.0
effort: xhigh
argument-hint: [path-to-task-file]
---

# Task Review

Parallel multi-angle code review with automated fix and regression
verification.

## Trigger Phrases

Use this skill when the user says: "review my code", "code review", "review
against tasks", "review changes", "代码审查", "审查代码", "review 一下", or
any request to review implemented code for quality, correctness, and
completeness.

## Quality bar

A useful review surfaces every real issue across five independent angles
(requirements, edge cases, quality, bugs, tests), applies the fixes that
should be applied, defers the rest with rationale, and verifies that the
resulting code still builds, tests, and lints. Each modified file is
covered; no file is silently skipped because it "looks routine".

## Output convention — dry-run reports

When this skill produces a dry-run report (a per-hunk evaluation of
how each reviewer-agent bullet *would* decide, without actually
modifying files), the report uses two non-overlapping label vocabularies
so a reader scanning the report cannot misread polarity:

| Decision level | Labels | Meaning |
|----------------|--------|---------|
| Per-condition  | `CONDITION-MET` / `CONDITION-NOT-MET` | `CONDITION-MET` = the bullet's qualifier is true (the condition fires; the bullet remains a candidate to flag the hunk). |
| Per-hunk final | `FLAG` / `PASS` | `FLAG` = the bullet reports the hunk. `PASS` = the bullet does **not** report the hunk (code is fine for this bullet's angle). |

The two vocabularies cannot collide because `MET` / `NOT-MET` only
appears at per-condition level and `FLAG` / `PASS` only at per-hunk
level.

Reason: the v3.1.0 dry-run report at
`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md` used the
single word `PASS` for both polarities (`Condition 1 PASSES` meaning
"condition fires" and `Decision: PASS` meaning "code is fine"),
which is easy to misread in the same paragraph. That report is
preserved as a historical artifact; future reports use the labels
above.

## Prerequisites

- A project with code to review.
- Optionally, a task document for requirements context.

## Arguments

$ARGUMENTS format: [PATH] [CUSTOM_INSTRUCTIONS]

- PATH (optional): first token, path to a task document. If omitted, the
  review covers recent changes (uncommitted, staged, or recently committed)
  without a requirements reference.
- CUSTOM_INSTRUCTIONS (optional): everything after the path, free-text that
  narrows the review scope or adds specific requirements (e.g., "only review
  src/api/", "focus on security and SQL injection").

If $ARGUMENTS contains no file path (first token is not a path), treat the
entire input as CUSTOM_INSTRUCTIONS.

## Execution

### Step 1: Determine review scope

If $ARGUMENTS contains a file path:
- Set REVIEW_SCOPE to "task".
- Set TASK_FILE to the provided path.
- Verify the file exists; if not, ask the user for the correct path.

If $ARGUMENTS is empty or contains no file path:
- Set REVIEW_SCOPE to "changes".
- Set TASK_FILE to "N/A".

### Step 2: Construct CONTEXT block

Build a structured CONTEXT block that will be passed to every dispatched
agent:

```
CONTEXT
- TASK_FILE: <task file path or "N/A">
- REVIEW_SCOPE: <"task" or "changes">
- CUSTOM_INSTRUCTIONS: <user's custom instructions or "N/A">
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

### Step 3: Render Planned Dispatch table and dispatch parallel review agents

Render this 5-row Planned Dispatch table so the user sees the planned
dispatch:

| # | Agent | Role |
|---|-------|------|
| 1 | requirements-reviewer | Reviews completeness against requirements |
| 2 | edge-case-reviewer | Reviews edge cases and failure modes |
| 3 | quality-reviewer | Reviews code quality and maintainability |
| 4 | bug-reviewer | Reviews for bugs and correctness defects |
| 5 | test-reviewer | Reviews test coverage and quality |

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
each review angle. Each subagent is read-only — it analyzes code and
produces a report but does not modify any files. Pass the CONTEXT block
from Step 2 as the dispatch prompt for every agent.

- Agent name: `requirements-reviewer`, description: "Review: requirements"
- Agent name: `edge-case-reviewer`, description: "Review: edge cases"
- Agent name: `quality-reviewer`, description: "Review: code quality"
- Agent name: `bug-reviewer`, description: "Review: bug hunting"
- Agent name: `test-reviewer`, description: "Review: test coverage"
<!-- canonical:dispatch:end -->

After all 5 agents return, verify each one produced a complete report. If
any agent returned an error, an empty response, or an obviously incomplete
report (e.g., only a header with no findings or no closing summary), do not
proceed to Step 4. Re-dispatch the failed agent(s) with the same CONTEXT
block. If the re-dispatch also fails, stop and inform the user which angles
are missing — proceeding to fix with fewer than 5 reports loses coverage
silently.

### Step 4: Aggregate review findings (Schema A roll-up)

Render the consolidated review findings table by aggregating Schema A
output from all 5 review-angle agents:

| Angle | HIGH | MEDIUM | LOW |
|-------|------|--------|-----|
| requirements | <n> | <n> | <n> |
| edge-case    | <n> | <n> | <n> |
| quality      | <n> | <n> | <n> |
| bug          | <n> | <n> | <n> |
| test         | <n> | <n> | <n> |
| **Total**    | <n> | <n> | <n> |

### Step 5: Dispatch fix agent

Collect all 5 review reports. Then dispatch a single subagent:
- Agent name: `code-fixer`
- description: "Fix reported issues"
- prompt: extend the CONTEXT block from Step 2 with a `REVIEW_REPORTS` field
  containing all 5 reports inline, e.g.:

```
CONTEXT
- TASK_FILE: <...>
- REVIEW_SCOPE: <...>
- CUSTOM_INSTRUCTIONS: <...>

REVIEW_REPORTS

[Angle 1 full report]
---
[Angle 2 full report]
---
[Angle 3 full report]
---
[Angle 4 full report]
---
[Angle 5 full report]
```

The fix agent deduplicates overlapping findings, applies fixes, and commits.
It produces an accountability list mapping every reported issue to an
action. Render its Schema B result table verbatim:

| # | short_label | Severity | File:Line | Action | Commit |
|---|-------------|----------|-----------|--------|--------|
| 1 | <≤60 char>  | HIGH     | path:42   | FIXED  | abc1234 |
| 2 | <≤60 char>  | MEDIUM   | path:99   | DEFERRED | — |

Below the table, render the Deferred Issues prose verbatim from the agent's
output.

### Step 6: Dispatch regression agent

After the fix agent returns, dispatch a single subagent:
- Agent name: `regression-verifier`
- description: "Regression verification"
- prompt: extend the CONTEXT block with both the original 5 review reports
  (`REVIEW_REPORTS`) and the fix agent's accountability list
  (`ACCOUNTABILITY_LIST`).

The regression agent verifies:
- every issue from the 5 reports is accounted for in the fix list,
- fixed issues are actually fixed in the code,
- build / test / lint passes,
- fix commits did not introduce new issues.

Render its Schema C result table verbatim:

| # | Check                            | Result | Detail                  |
|---|----------------------------------|--------|-------------------------|
| 1 | All accountability rows fixed    | PASS   | —                       |
| 2 | Build succeeds                   | PASS   | —                       |
| 3 | Tests pass                       | FAIL   | 2 failures (see below)  |
| 4 | Lint passes                      | PASS   | —                       |
| 5 | No regressions in non-fix files  | PASS   | —                       |

Below the table, render the Detail prose verbatim for each non-PASS row.

### Step 7: Final consolidated report (Schema F)

Render the final consolidated report using Schema F:

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

#### Verdict determination

Based on the regression verification results, declare a verdict:

- **PASS** when all of: zero HIGH severity issues remain unresolved; zero
  INCORRECTLY FIXED items; build / tests / lint all PASS or `SPOT-CHECK`
  on row 3 (no-test-suite fallback); no regressions introduced by fix
  commits.
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
- **FAIL** when any of: one or more HIGH severity issues remain unresolved;
  one or more INCORRECTLY FIXED items; build / test / lint fails; fix
  commits introduced unresolved regressions.
- **PARTIAL** when neither PASS nor FAIL applies cleanly — for example,
  HIGH issues are deferred with explicit rationale and the user must decide
  whether to accept.

MEDIUM and LOW issues do not change the verdict but appear in the report.

The Next steps bullets call out: deferred issues, regression failures,
reviewer recommendations the user should act on, and whether re-running
the review is suggested.
