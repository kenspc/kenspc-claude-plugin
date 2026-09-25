---
name: task-review
description: >
  Thorough code review (代码审查/review代码) using 5 parallel review agents, a fix
  agent, and a regression verification agent. Use for ANY code review request —
  not overkill, each agent covers a different angle (bugs, edge cases, tests,
  security, conventions). Works with a task document (review against requirements)
  or standalone (review recent changes/uncommitted code).
version: 3.0.0
argument-hint: "[path-to-task-file]"
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
(requirements, edge cases, project conventions, bugs, tests), applies the
fixes that should be applied, defers the rest with rationale, and verifies
that the resulting code still builds, tests, and lints. Each modified file is
covered; no file is silently skipped because it "looks routine".

## Prerequisites

- A project with code to review.
- Optionally, a task document for requirements context.

## Arguments

$ARGUMENTS format: [PATH] [CUSTOM_INSTRUCTIONS]

- PATH (optional): first token, path to a task document. If omitted, the
  review covers the change set Step 1 determines, without a requirements
  reference.
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
- Determine the change set — the files under review — before the
  run-directory preparation below, with read-only git commands only:
  `git status --porcelain`, `git diff --name-status`, `git rev-parse`,
  `git rev-list`, `git log`, `git merge-base`, and
  `git hash-object -t tree /dev/null`, which prints the empty tree's SHA and
  writes nothing. No commit, stash,
  checkout, add, reset, or any other change to the working tree, the index,
  or refs. Why: a review run once committed the user's uncommitted change as
  a baseline for its fixes, because nothing said what to do with it; the
  change set is the user's work, and the run reads it.
  - `Mode: uncommitted` when `git status --porcelain` lists any path once
    paths under `.kenspc/` are dropped (ignored paths never appear). The set
    is every listed path — staged, unstaged, and untracked — read from
    `git -c core.quotePath=false status --porcelain -uall`: a path git
    prints in double quotes is recorded without them, and a rename
    (`R  old -> new`) as its new path. The base is HEAD's SHA; the diff
    command is `git diff <sha> -- <paths>`, with untracked files read whole.
    Why the flags: by default an untracked directory is one `?? dir/` row,
    and a non-ASCII path comes octal-escaped; neither names a file a
    reviewer can open or a pathspec can match.
  - `Mode: commits` when the tree is clean. The range is
    `<merge-base sha>..<HEAD sha>` when `@{upstream}` resolves and
    `git rev-list <upstream sha>..<HEAD sha>` lists commits, the merge base
    being what `git merge-base <upstream sha> <HEAD sha>` prints — the
    upstream itself unless the branch has diverged from it; otherwise
    `<HEAD~1 sha>..<HEAD sha>`. The set is `git diff --name-status <range>`;
    the diff command is `git diff <a>..<b> -- <paths>`. Why the merge base:
    `git diff` with two dots compares two trees, so on a branch that has
    diverged from its upstream, `<upstream sha>..<HEAD sha>` would also list
    the files only the upstream's new commits touched, with their changes
    shown reversed, as if this branch had undone them.
  - When a commit these defaults name does not exist, git's empty tree
    stands in for it: the SHA `git hash-object -t tree /dev/null` prints,
    `4b825dc642cb6eb9a060e54bf8d69288fbee4904` in a SHA-1 repository. With
    no upstream and HEAD the root commit, the set is recorded as
    `Range: <empty tree>..<HEAD sha> (root commit)`; on an unborn branch,
    where `git rev-parse --verify HEAD` fails, as
    `Base: <empty tree> (no commit yet)`. The diff commands keep their form
    (`git diff <empty tree>..<sha>`, `git diff <empty tree> -- <paths>`),
    and the pinned base stays the empty tree even when the run-directory
    preparation's `.gitignore` commit then creates the root commit. Why: a
    fresh project with one commit, or none, is reviewable without
    CUSTOM_INSTRUCTIONS.
  - CUSTOM_INSTRUCTIONS that name commits or a range replace the default:
    mode `commits` with that range, pinned by SHA. Named paths narrow the
    set instead: it keeps the default's mode, base or range, and diff
    command, and only the paths under the named ones remain. Why: a path
    says what to look at, not which change it belongs to, and the mode
    decides whether code-fixer commits.
  - When the set comes out empty — named paths that hold no change, or a
    range whose diff lists no file — stop and tell the user what was found,
    and dispatch nothing. Why: five reviewers over no file each report no
    issue, and the verdict would pass a change nobody reviewed.
  - Compute and pin every SHA before the run-directory preparation, so its
    one-time `.gitignore` commit is never part of the set.
  - Tell the user, in one line, what is under review: the mode and the base
    or range, with the file count.

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

In "changes" mode, write `RUN_DIR/change-set.md` — the first file in the
directory — with the change set determined above. A "task" run writes no
such file. The shape:

```markdown
# Change set

Mode: uncommitted
Base: <sha>
Diff: git diff <sha> -- <paths>

| Status | Path |
|--------|------|
| M      | src/api/users.ts |
| ??     | src/api/roles.ts |
```

`Mode:` is `uncommitted` or `commits`. An uncommitted set carries
`Base: <sha>`; a committed one carries
`Range: <sha>..<sha> (<how it was chosen>)` in its place — upstream,
`HEAD~1`, root commit, or CUSTOM_INSTRUCTIONS. `Diff:` is the diff command
from the rule above. The
table lists every path in the set, its status as git prints it (`M`, `A`,
`D`, `R`, `??`), paths relative to the repository root, a rename under its
new path. Why: the five
reviewers, code-fixer, and regression-verifier read the set from that path;
RUN_DIR is the one value the orchestrator already passes, so no key is
added.

### Step 2: Construct CONTEXT block

Build a structured CONTEXT block that will be passed to every dispatched
agent:

```
CONTEXT
- TASK_FILE: <task file path or "N/A">
- REVIEW_SCOPE: <"task" or "changes">
- CUSTOM_INSTRUCTIONS: <user's custom instructions or "N/A">
- RUN_DIR: <absolute run directory from Step 1>
```

The keys are the same in both scopes; in "changes" mode RUN_DIR also holds
`change-set.md`, and every dispatched agent reads the change set there.

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

### Step 3: Dispatch parallel review agents

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
response, or an incomplete reply, or its report file is missing, do not
proceed to Step 4. Re-dispatch the failed agent(s) with the same CONTEXT
block. If the re-dispatch also fails, stop and inform the user which angles
are missing — proceeding to fix with fewer than 5 reports loses coverage
silently.

### Step 4: Aggregate review findings (Schema A roll-up)

Render the consolidated review findings table by aggregating the Schema A
Findings tables in the 5 replies:

| Angle | HIGH | MEDIUM | LOW |
|-------|------|--------|-----|
| requirements | <n> | <n> | <n> |
| edge-case    | <n> | <n> | <n> |
| quality      | <n> | <n> | <n> |
| bug          | <n> | <n> | <n> |
| test         | <n> | <n> | <n> |
| **Total**    | <n> | <n> | <n> |

### Step 5: Dispatch fix agent

Dispatch a single subagent:
- Agent name: `code-fixer`
- description: "Fix reported issues"
- prompt: the CONTEXT block from Step 2, unchanged — code-fixer reads the 5
  reports from RUN_DIR itself.
- run_in_background: false — the next step reads this agent's result in the
  same turn. A background call returns at once, and a headless session stops
  the agent when it exits.

The fix agent deduplicates overlapping findings, applies fixes, commits each
one — except in an `uncommitted` run, below — and
writes its full Schema B accountability list to `RUN_DIR/schema-b.md`: a
`# / Source / short_label / Severity / File:Line / Action / Commit` table in
which every issue ID appears in exactly one Source cell, a Per-angle Results
table, the Deferred Issues prose, the scratch-pollution note when there is
one, and a statistics line of this fixed form:

<!-- canonical:stats-line:start -->
`total reported N (R n, E n, Q n, B n, T n), deduplicated to N unique, FIXED N, DEFERRED N, NOT APPLICABLE N, DEDUPED N`
<!-- canonical:stats-line:end -->

Its reply carries the statistics line, the Per-angle Results table, the HIGH
and MEDIUM rows with their Deferred Issues paragraphs, the scratch-pollution
note when there is one, and the path of schema-b.md. Render that reply
verbatim; the LOW rows and their prose stay in the file.

When `change-set.md` says `Mode: uncommitted`, code-fixer applies the fixes
to the working tree without committing — no baseline commit of the user's
change, no fix commit, no stash — and its FIXED rows show `—` in the Commit
column; its reply adds one line after the statistics line saying the fixes
are uncommitted and naming the files.

### Step 6: Dispatch regression agent

After the fix agent returns, dispatch a single subagent:
- Agent name: `regression-verifier`
- description: "Regression verification"
- prompt: the CONTEXT block from Step 2, unchanged — regression-verifier
  reads the 5 reports and schema-b.md from RUN_DIR itself.
- run_in_background: false — the next step reads this agent's result in the
  same turn. A background call returns at once, and a headless session stops
  the agent when it exits.

The regression agent verifies:
- every issue ID from the 5 reports is accounted for in schema-b.md, and the
  statistics line agrees with the rows,
- fixed issues are actually fixed in the code,
- build / test / lint passes,
- the fixes (fix commits, or the uncommitted fixes of an `uncommitted` run)
  did not introduce new issues.

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

(code-fixer's reply verbatim: the statistics line, the Per-angle Results
table, the HIGH and MEDIUM rows with their Deferred Issues paragraphs, the
scratch-pollution note when there is one, and the full path of schema-b.md,
where the LOW rows and their prose remain.)

## Verification

(Schema C verbatim.)

## Verdict

PASS / FAIL / PARTIAL — one paragraph rationale.

## Next steps

Bulleted list of follow-ups (deferred issues, regression failures,
reviewer recommendations). Each HIGH or MEDIUM DEFERRED issue gets its own
bullet; LOW DEFERRED issues share one bullet with their count and the path of
schema-b.md.
```

#### Verdict determination

Based on the regression verification results, declare a verdict:

- **PASS** when all of: zero HIGH severity issues remain unresolved; zero
  INCORRECTLY FIXED items; build / tests / lint all PASS or `SPOT-CHECK`
  on row 3 (no-test-suite fallback); no regressions introduced by the fixes
  (fix commits, or the uncommitted fixes of an `uncommitted` run).
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
  one or more INCORRECTLY FIXED items; build / test / lint fails; the fixes
  (fix commits, or the uncommitted fixes of an `uncommitted` run) introduced
  unresolved regressions.
- **PARTIAL** when neither PASS nor FAIL applies cleanly — for example,
  HIGH issues are deferred with explicit rationale and the user must decide
  whether to accept.

MEDIUM and LOW issues do not change the verdict but appear in the report.

The Next steps bullets call out: deferred issues, regression failures,
reviewer recommendations the user should act on, and whether re-running
the review is suggested. When the change set was uncommitted
(`Mode: uncommitted`), one bullet says the fixes are in the working tree,
uncommitted, naming the files, for the user to review and commit; nothing
in such a run commits them. When regression-verifier's test-row Detail names
files under `.kenspc/` that the test run collected and that passed, one
bullet names them as the Detail does and asks the user to delete them.
Why: runs are never deleted and the plugin deletes nothing itself, so a
collected probe that passes stays in the user's own test run until the user
removes it.
