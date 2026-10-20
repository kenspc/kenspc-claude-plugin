# Review Bar

What the five review-angle agents check, written once. Each section below holds one agent's REVIEW CHECKLIST between `canonical:review-bar:<angle>` markers, byte-identical to the copy that agent carries inline, followed by an `At write time` list for the agent that writes the code. The agents carry their copies inline so each review loads its checklist without depending on a runtime Read, as the writer agents do with the code-craft principles; `scripts/check-review-bar-canonical.sh` holds each copy to its block here and fails when an agent's REVIEW CHECKLIST holds a line outside its block, so a check added to an agent cannot miss this file. Change a checklist here and in its agent in the same commit.

`task-implementer` reads this whole file before its first task. Why: the five reviewers check the implementer's work right after it, and a gap they find costs a review row, a code-fixer edit, and a regression-verifier check, where the same test or comment written with the code costs one edit. An implementer told only to test "the error paths" still left untested branches in most reviews, because nothing told it the bar the test reviewer measures by: remove the branch, and some test must fail.

The project's instruction files are its CLAUDE.md and AGENTS.md files — at the root, in `.claude/`, or in a subdirectory — and the files a CLAUDE.md imports with `@`, whether or not Claude Code loaded them in this session.

## How the implementer reads this file

Each checklist is written for a reviewer: it names what a finished change must hold. Its `At write time` list says what to do while writing so that the review finds it held. Apply each item where the checklist places it — at a system boundary, around an external call, at a branch the task adds — and nowhere else. Why: an internal seam whose callers already validate still follows Simplicity First, and a guard added "in case" is the over-engineering Angle 3 flags. The sentences about reporting (severity, what is or is not a finding) are the reviewer's; read them only as the bar.

## Angle 1: Requirements Completeness (`requirements-reviewer`)

<!-- canonical:review-bar:requirements:start -->
A change passes this angle when every requirement (or, for REVIEW_SCOPE
"changes", every intended change) is implemented end to end: reachable from its
entry point, connected to its callers and data, and matching the interface the
task or design specifies.

Named failure modes — the gaps most easily missed when the code itself looks
complete:
- Present but unreachable: the new code exists and builds, but nothing reaches
  it — a handler with no route, a registered service nobody resolves, a setting
  nobody reads.
- Spec–implementation drift: the task document, README, API docs, or doc
  comments describe behavior the code does not have — a renamed field, a
  changed status code, a default that moved. Why: the next reader trusts the
  document over the code.
- Partial completion marked done: a task marked DONE whose acceptance criteria
  are only partly met, or a BLOCKED task whose stated blocker does not hold in
  the code.
<!-- canonical:review-bar:requirements:end -->

At write time:
- Connect each piece the task adds to the entry point that reaches it — a route, a registration, the code that reads a setting — in the same task, and check that something reaches it.
- In the files the task changes, and in the documents the task lists, update each doc comment and each line that describes behavior the task changed. A document outside the task's scope that now describes the old behavior is named under `Changes/tradeoffs:`, not edited. Why: a file outside the task's stated scope is a BLOCKED decision under AUTONOMY BOUNDARIES, and the Doc-sync task or the user settles it.

## Angle 2: Edge Cases and Error Handling (`edge-case-reviewer`)

<!-- canonical:review-bar:edge-case:start -->
A change passes this angle when every input crossing a trust or system
boundary is validated where it enters, and every external call's failure — an
error, a timeout, an empty or malformed result — leads to an outcome the caller
can observe and handle.

Named failure modes — each one looks like working code on the happy path:
- Trusting boundary input: data arriving from a system boundary — an HTTP
  request, an external API or feed, a file — used in a query, a path, a
  command, or markup without being validated or sanitized first. Why: this is
  the one place a missing check becomes an injection or traversal, which is
  why boundary validation counts as correct design rather than
  over-engineering.
- Client-only validation: a constraint enforced in the UI or client but not
  where the server accepts the input.
- Fail-open guard: a validation, authorization, or rate-limit check that lets
  the request through when the check itself errors, times out, or gets an
  unexpected value — a catch block that returns success, a missing policy
  treated as allow.
- Swallowed failure: an external call (database, HTTP, file, queue) whose error
  is caught or ignored while the caller proceeds as if it succeeded — for
  example an empty list returned on failure, indistinguishable from "no data".
- Shared-resource lifetime: a resource with several users — a singleton
  player, a connection, a subscription, a cached handle — released, unloaded,
  or disposed by one user while another still needs it, such as a screen that
  unloads a shared audio instance on unmount while another screen still plays
  through it. Why: each user's code looks correct on its own; the failure only
  appears where the two lifetimes overlap.
- Empty treated as absent: code that treats an empty string, empty collection,
  or zero as "not provided" (or the reverse) where the task, API, or data model
  distinguishes the two.
<!-- canonical:review-bar:edge-case:end -->

At write time:
- Validate input where it crosses a system boundary, and on the server too when the client already validates it.
- A guard whose own check errors, times out, or reads an unexpected value refuses.
- A failed external call reaches its caller as a failure; a page whose read fails shows that failure, not an empty or stale view.
- Where the task, the API, or the data model tells empty from absent, keep them apart — an empty string, white space alone, an empty list, a zero — and test each.

## Angle 3: Project Conventions (`quality-reviewer`)

<!-- canonical:review-bar:quality:start -->
A change passes this angle when it reads as if the project's own maintainers
wrote it: it follows the conventions written in the project's instruction
files and README and the patterns visible in adjacent code, and adds
nothing those sources do not call for.

Named failure modes — each finding cites its source (file and section, or the
location of the existing pattern); a departure you cannot cite is not a
finding:
- Written-convention departure: naming, file placement, error handling,
  logging, configuration, or import style that departs from a rule stated in
  the project's instruction files or README.
- Adjacent-pattern departure: new code that solves a problem differently from
  how the neighboring code already solves it — a second client wrapper, a
  hand-rolled retry where a shared helper exists, a new way of reading
  configuration. Why: parallel mechanisms drift apart and each fix has to be
  made twice.
- Over-engineering: flag features, abstractions, or configurability that meet **all three** of the following conditions:
  1. Not in the task document's stated requirements, AND
  2. Not mandated by project conventions documented in the project's instruction files, `README.md`, or visible patterns in adjacent code, AND
  3. Not a boundary validation required by the project's security or input-handling rules (system-boundary validations are correct design, not over-engineering).

  Why: abstractions mandated by project conventions (condition 2 fails) and validations required for system-boundary input handling (condition 3 fails) are correct design — flagging them creates noise that erodes trust in this reviewer's signal. Apply Simplicity First per `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`; the applicability table there states this agent's stance: detect, do not fix.
- Drive-by refactoring and style drift in the diff: flag changes to adjacent code that meet **all three** of the following conditions:
  1. Not required by the task, AND
  2. Not mechanically forced by the change (interface signature changes cascade to implementers; removing the last call to a function orphans imports; lint-mandated formatting changes), AND
  3. Not the task's own lines written in the documented project style (a line the task edits anyway may follow the documented style; untouched adjacent code converged to it is drive-by).

  Why: mechanically-forced cascading changes (condition 2 fails) are the task-required change itself — flagging them would force the implementer to leave the codebase in a broken state — and a line the task edits anyway, written in the documented style (condition 3 fails), is the task's own line. Untouched adjacent code brought into the documented style is a follow-up, as Surgical Changes says. Apply Surgical Changes per `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`; same detect-do-not-fix stance.
<!-- canonical:review-bar:quality:end -->

At write time:
- Before writing a client, a helper, a query key, a conversion, or a constant, look in the adjacent code for the one it already uses, and use that one.
- The CODE-CRAFT PRINCIPLES you carry inline are this angle's other write-time side: the applicability table in `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` gives the writer's stance, apply, where this checklist gives the reviewer's, detect.

## Angle 4: Bug Hunting (`bug-reviewer`)

<!-- canonical:review-bar:bug:start -->
A change passes this angle when tracing it with concrete inputs — the happy
path and each branch the change adds or alters — produces the result the task
or the surrounding code expects, and leaves state consistent for the next
caller.

Named failure modes — reasoning about one call at a time tends to miss these:
- Check-then-act across a boundary: a condition checked, then acted on after an
  await, a lock release, or outside the transaction, so a concurrent change
  invalidates the check — duplicate inserts, lost updates, double spends.
- Stale derived state: a cache, memoized value, denormalized field, or
  client-side copy that the change writes around without updating or
  invalidating.
- Late failure overwrites a settled result: an error from a later step — a
  follow-up status check, a cleanup, a telemetry call — replaces a result that
  was already established, reporting failure or the wrong state after the
  operation succeeded. Why: the success path is what gets tested; the later
  step's failure usually is not.

Not a finding:
- Compiler-enforced exhaustiveness reported as a missing default case. A switch
  over a closed union or enum whose completeness the compiler already checks —
  for example a TypeScript switch whose default branch assigns the value to
  `never` — handles every case by construction. A runtime default branch would
  hide the compile error that a future new case should raise.
<!-- canonical:review-bar:bug:end -->

At write time:
- Trace each branch you add with one concrete input before you commit.
- A check and the action it guards that sit on either side of an await, a lock release, or a transaction boundary go into one transaction, or the action checks again.
- After a write, invalidate or read again each cache, derived value, or client-side copy it changes.
- A later step's failure — a follow-up read, a cleanup, a telemetry call — does not replace a result already settled.

## Angle 5: Test Coverage (`test-reviewer`)

<!-- canonical:review-bar:test:start -->
A change passes this angle when each behavior it adds or alters — including
its error paths — has a test that would fail if that behavior broke, written
with the project's existing test framework and file conventions. When a test
is missing, name the function or path and what the test should assert.

Named failure modes — each one produces a green test run that protects
nothing:
- Tautological test: a test that passes regardless of the logic — it asserts a
  value the function returns unconditionally, asserts on the mock's own
  configured return, or has no assertion that depends on the code under test.
  Note what it should assert instead.
- Unverified interaction: the behavior under test is an outbound call — a
  charge made, a message sent, a record written through a repository — and the
  collaborator is stubbed, but the test never asserts that the call happened or
  with which arguments, so passing the wrong ID, amount, or flag still passes.
  Calls to internal helpers are implementation details and outside this mode.
- Bypassed test: an existing test still passes but no longer reaches the
  modified code, because the change moved the logic to a path the test does
  not exercise.
<!-- canonical:review-bar:test:end -->

At write time:
- Each branch, guard, and limit the task adds or alters, each rule the task document or its plan states for this task, and each behavior one of your `Decisions:` settles gets a test that fails when that piece is removed or changed; a limit is tested at the limit and one past it. The Test map in task-implementer's QUALITY CHECKLIST records which test holds each piece.
- Where the behavior is an outbound call — a charge, a message sent, a record written through a repository — assert that the call happened and with which arguments.
- When the change moves logic, check that the tests that covered it still reach its new place.
