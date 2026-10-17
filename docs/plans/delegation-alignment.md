# Plan: align kenspc with the global Delegating to Subagents rule (4.9.0)

## Objective

Make the plugin's skills and agents state, where the global rule
"Delegating to Subagents" would otherwise be read against them, who runs
each check, what may run in parallel, and what evidence comes back — so a
session that loads the rule and runs a kenspc skill does what the skill
intends.

In scope: the rulings the user gave on questions 2–10 and 12–14 of the
2026-10-17 research (table under Background), and the documentation they
make stale. The release is 4.9.0.

Out of scope:

- Question 11, a machine-wide lock on full test suites for concurrent
  autopilot batches — a new feature, planned separately.
- The global rule itself: narrowed in dev-setup `463cd95` (pushed), which
  this plan builds on.
- Reusing task-implementer's last test run in place of task-implement's
  pre-review suite run. The suite run sits in the `canonical:dispatch`
  block shared with task-review, so a reuse in one skill breaks the
  byte-identity, and the saving is one test run.
- Tagging, pushing and the GitHub release: the release procedure, run after
  this plan by the user's go.

## Background

On 2026-10-17 the user added § Delegating to Subagents to the global
CLAUDE.md (dev-setup `a50b190`, narrowed in `463cd95`). Its five points,
named here by their bold titles: **Delegate in parallel**, **Only the
top-level session delegates**, **A skill's split wins**, **Run in parallel
only what shares nothing** (as narrowed: checks that write to the same
tree, database or scratch folder, and full test suites, run one after
another; read-only checks of one tree may run together), and **Ask for
evidence, not a verdict**. Subagents load the same CLAUDE.md (no kenspc
agent sets `omitClaudeMd`), so the rule reaches every plugin agent too.

A research pass (seven agents, 126 findings, 120 confirmed) found where the
rule and the plugin's text read against each other. The user ruled:

| Q | Finding | Ruling |
|---|---------|--------|
| 2 | Plugin agents report PASS rows with no command or exit code (Schema C rows 2–4, code-fixer's final run, Schema D) | Add command, exit code and log path to those rows; also to S5's and S6's replies |
| 3 | "Confirm the part you build on" could make the main session re-run the suite | Confirm by reading the reported exit codes and logs; no re-run |
| 4 | The pre-review suite run names "the orchestrator" but not that it runs in the main session's own context | State it |
| 5 | A whole task-review handed to a subagent would review all five angles in one context | task-review and task-implement run only in the top-level session |
| 6 | Five reviewers may each run a named test file needing ports or a database at once | Reviewers do not run such tests; they list them for regression-verifier. A test needs ports or a database when its own setup starts a server or host, opens a database connection, or binds a port, or the project's instruction files name it an integration test; when unsure, it counts as needing them |
| 7 | Reviewers dispatched by hand without RUN_DIR each run the full suite | Say so in each reviewer's description |
| 8 | task-document-reviewer's angle 3 could rewrite a task's test step to "delegate" | Tell it the delegation rule does not apply to task steps |
| 9 | The autopilot main session could use Agent subagents in place of worker sessions | Make "Nothing runs as an agent" a rule with its Why |
| 10 | The worker preamble does not say whether a worker may dispatch subagents | It may, foreground only; its subagents dispatch none and start no `claude -p` |
| 12 | S4's "run each case, in the order listed" names no runner and no reason | "Yourself", with the reason |
| 13 | generate-task, generate-guide and diagnose-bug read code one file at a time in the main session | Read-only sweeps may go to parallel subagents that return `file:line` |
| 14 | `CLAUDE.md` says subagents cannot spawn subagents and that the interactive Agent tool has no `run_in_background` | Measure first, then correct both |

Question 14's measurement was taken on 2026-10-17 in a Claude Code 2.1.301
Desktop session: an Agent call with `run_in_background: false` returned only
when the subagent had finished (9.1 s; its report arrived as a separate
hand-back message), and the same call with the parameter omitted returned at
once with "Async agent launched". The 2.1.301 binary removes the parameter
when its fork-mode gate is on, which its docs tie to the interactive
terminal CLI; that side is not measured. Nesting: the binary's default depth
limit is 3 (`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`), and the user measured
main → L1 → L2 → L3 with a headless probe; kenspc agents cannot nest because
none lists Agent in `tools:`.

## Technical Approach

- **Say who runs it, beside the step.** Each ruling becomes a sentence at
  the step it governs, with a `Why:` in the plugin's rationale-anchored
  style, so **A skill's split wins** has something explicit to defer to.
  No ruling is stated only in `CLAUDE.md`, which user projects do not load.
- **Evidence is a field, not prose.** Every check an agent or worker runs
  and reports gets its command, exit code, and a log path in the report's
  existing structure (a Detail cell, a reply line, a Schema D section), so
  the main session confirms a verdict by reading, not re-running (Q3).
- **Byte-identical blocks change together.** Rulings that land in the
  reviewers' shared sections, the `canonical:dispatch` block, or the
  `canonical:verdict-shared` block are written once and copied, and the
  matching guard runs after each such step.
- **A new cross-file literal gets a guard.** The heading reviewers write
  for regression-verifier to read (`## Tests left for the verifier`) joins
  `check-run-contract.sh`'s check 5, the literal-presence check that
  already holds `suite-run.md` and `schema-c-1.md`, with a self-test rename
  per carrier. Why: a rename in one of the six files would leave the
  verifier reading a heading no reviewer writes, and every other check
  would pass.
- **Edits happen in a session without `--plugin-dir`** (the repo's rule).

## Implementation Steps

Line numbers are as of `20000bf` and move as earlier steps edit a file.

### Step 1: The review skills run only in the top-level session (Q5)

- `skills/task-review/SKILL.md` § Prerequisites (line 33) and
  `skills/task-implement/SKILL.md` § Prerequisites (line 46): add one
  bullet: the skill runs in the top-level session — the one the user talks
  to, or a headless `claude -p` session — and never inside a subagent.
  Why: a subagent dispatches no subagents under the global rule, so it
  would review all five angles, fix, and verify in one context, which
  removes the independence the five reviewers exist for; and it cannot ask
  the user at the skill's gates.
- Outside every canonical block, so the two bullets may differ in wording
  where the skills differ.

Acceptance: both Prerequisites sections hold the bullet with its Why;
`bash scripts/check-canonical-dispatch.sh` and
`bash scripts/check-verdict-shared.sh` exit 0.

### Step 2: The suite run stays in the main session's own context (Q4)

- In the `canonical:dispatch` block's "Before the dispatch: one suite run"
  paragraph (task-review line 286; task-implement line 424): after "Run the
  project's test commands once", state that the orchestrating session runs
  them itself, in its own Bash, not through a subagent; add to the Why that
  the commands are known and a brief costs more than the run, and that the
  logs belong under `scratch/orchestrator/`, the orchestrating session's
  own directory.
- Same text in both copies.

Acceptance: the sentence is in both copies; `check-canonical-dispatch.sh`
and `check-run-contract.sh` exit 0.

### Step 3: Reviewers leave port- and database-bound tests to regression-verifier (Q6)

Depends on: none. Precedes Step 5 (regression-verifier's check 3 is edited
in both).

- The five reviewers' PREREQUISITES item 5 (requirements-reviewer line 121;
  the item is byte-identical in all five): after "run a named test file, or
  a mutation check under your scratch directory, one command at a time",
  add: with RUN_DIR, a test file needs ports or a database when its own
  setup starts a server or host, opens a database connection, or binds a
  port, or the project's instruction files name it an integration test;
  when unsure, it counts as needing them. Run no such file; read its result
  in `suite-run.md`'s logs instead, and list it under
  `## Tests left for the verifier` with one line per file: the path, and
  what you wanted to learn from it. Why: five reviewers run at once, and
  two runs of one integration suite at once have exhausted a machine's
  local ports, failing on connection errors that read as findings;
  regression-verifier runs after code-fixer, alone. Without RUN_DIR the
  item is unchanged.
- Each reviewer's OUTPUT FORMAT (Schema A): add the
  `## Tests left for the verifier` section after `## Issues` and before
  the closing line, written only with RUN_DIR, holding `none` when empty.
  It stays in the file (`angle-<n>.md`) and is not part of the reply.
- The five reviewers' REPORT DELIVERY (byte-identical in all five): the
  file's content, today "both tables and the closing line", also names the
  `## Tests left for the verifier` section; the reply list is unchanged.
- `agents/regression-verifier.md` INPUTS (line 83) and check 3 (line 214):
  read each `angle-<n>.md`'s `## Tests left for the verifier`; after the
  full test command, run, one at a time, each listed file the full run did
  not collect; one the full run collected is covered by it. When the runner
  gives no list of collected files, or the list command errors, the file
  is run. Row 3's Detail
  names each listed file and how it was settled (`covered by the full run`,
  or its own command and exit code). A listed file that fails makes row 3
  FAIL.
- `scripts/check-run-contract.sh` check 5: add the literal
  `## Tests left for the verifier`, required in the five reviewers and
  `regression-verifier.md`, its self-test renaming it in each in turn. The
  self-test copies seven target files today, of the reviewers only
  `requirements-reviewer.md`; it gains `edge-case-reviewer.md`,
  `quality-reviewer.md`, `bug-reviewer.md`, and `test-reviewer.md`, and its
  fixture-stale check requires the literal in all six. Why all five
  reviewers and not the existing one-reviewer pattern: the literal sits in
  OUTPUT FORMAT as well, which `check-review-agent-drift.sh` does not hold.
  The guard's header comment (the file list, the copied-file count, and
  the mutation count, "thirty-seven" today) updated to match.

Acceptance: `check-review-agent-drift.sh` and `check-run-contract.sh` exit
0; `bash scripts/check-run-contract.sh --self-test` turns red on each of the
six renames and green unmutated.

### Step 4: Reviewer descriptions warn against parallel standalone dispatch (Q7)

- The `description:` frontmatter of the five reviewers: append one
  sentence: invoked standalone (without RUN_DIR) it runs the project's full
  test suite itself, so dispatch one at a time or use /kenspc-task-review.
  Same sentence in all five.

Acceptance: `grep -lF '<the sentence>' plugins/kenspc/agents/*-reviewer.md`
lists exactly the five reviewers (the three document reviewers, which the
glob also matches, carry none);
`claude plugin validate --strict ./plugins/kenspc` exits 0.

### Step 5: Checks report their command, exit code, and log (Q2)

Depends on: Step 3.

- `agents/regression-verifier.md` Schema C (line 325): rows 2–4 carry, in
  every Result state, PASS included, the command, its exit code, and its
  log's path under `RUN_DIR/scratch/regression-verifier/` in the Detail
  cell (`<command> → exit <n>, log <path>`; several commands joined by
  `; `); a check the project gives no command for reads
  `no <build|lint> command in the project`, and row 3's SPOT-CHECK keeps
  its fallback text; the worked example table shows these forms; the
  Detail prose section stays for non-PASS rows. Why: **Ask for evidence,
  not a verdict**; a `—` cell is a verdict.
- `agents/code-fixer.md` reply list (line 525): add a line after the
  statistics line, `Final checks: <command> → exit <n>, log <path>[; …]`,
  for the final build, test, and lint run, logs under
  `RUN_DIR/scratch/code-fixer/`; not written to `schema-b.md`, whose last
  line stays the statistics line (so `check-run-contract.sh`'s recount is
  unchanged).
- `agents/task-implementer.md` Schema D (line 307): add a `## Checks run`
  section after `## Tasks`, always rendered: the last build, test, and lint
  commands the dispatch ran, each with its exit code, the task after which
  it ran, and its log path under `RUN_DIR/scratch/task-implementer/`.
  `skills/task-implement/SKILL.md` Step 5 (line 284) merges the slices'
  sections by keeping the last slice's.

Acceptance: the three examples show the forms; `check-run-contract.sh` and
`check-notes-format-sync.sh` exit 0.

### Step 6: The verdict is confirmed by reading, not re-running (Q3)

Depends on: Step 5.

- Inside the `canonical:verdict-shared` block of both skills: add a bullet:
  the verdict reads Schema C rows 2–4's exit codes as reported; the
  orchestrating session confirms a row by reading the log it names, and
  runs no build, test, or lint of its own. A row 2–4 that carries neither
  an exit code nor one of Step 5's no-command forms (the `no … command in
  the project` text, row 3's SPOT-CHECK fallback) keeps the verdict from
  PASS. Why: regression-verifier is the skill's confirmation step; a third
  full run adds load and no independence, and a row with no evidence is
  the bare verdict the global rule refuses.

Acceptance: `check-verdict-shared.sh` exits 0.

### Step 7: task-document-reviewer does not rewrite task steps to delegate (Q8)

- `agents/task-document-reviewer.md` angle 3 (line 111): after the Passing
  paragraph, add: the user-level rule on delegating to subagents governs
  the session that dispatches agents, not a task's steps; a task step that
  runs a suite or a check is not a departure from it. Why: task-implementer
  has no Agent tool, so a step rewritten to delegate cannot be carried out.

Acceptance: the sentence is in angle 3; `check-instruction-files.sh` exits
0.

### Step 8: The autopilot main session uses no Agent subagents (Q9)

- `skills/autopilot/SKILL.md` overview (line 32): turn "Nothing runs as an
  agent." into a rule with its Why: the main session dispatches no Agent
  subagent for a role, a re-check, a re-run, a review, or the evidence of a
  corrected case; its own checks (the start checks, the snapshot, the
  self-test, the extraction, the zero-diff check, the corrected-case runs)
  run in its own Bash. Why: a subagent's cost is outside the budget's
  terms, it carries no worker marker so the rails hook does not guard it,
  in plugin mode it runs the plugin text this session loaded at its start,
  and several of those checks read values only this session's Bash holds.

Acceptance: the rule and Why are at the overview; `check-no-model-names.sh`
and `check-autopilot-rails-hook.sh` exit 0.

### Step 9: The worker preamble says how a worker uses subagents (Q10)

- `skills/autopilot/SKILL.md` preamble § 3 (around line 2242, "These rails
  bind every subagent you dispatch"): add, as a rail: you are the top-level
  session of your own process and may dispatch subagents, each with
  `run_in_background: false`; a subagent you dispatch dispatches none and
  starts no `claude -p`; the line goes into every subagent prompt and every
  CUSTOM_INSTRUCTIONS with the rest of § 3. Why: a background subagent is
  stopped when a headless session exits, and its result never reaches you;
  a subagent that nests or starts its own headless session leaves the rails
  text one level behind, and a `claude -p` it starts is a session of its
  own that the rule's nesting limit does not reach (depth is computed per
  process in the 2.1.301 binary — a reading of the code, not measured).
  The worker itself keeps launching nested sessions where a task block
  tells it to (plugin-mode S4).
- Text only: the rails hook does not tell a worker's call from its
  subagent's, so it does not enforce this rail (see Risks).
- The preamble's first line ("headless sub-session") is unchanged: the
  skill's trigger description matches it.

Acceptance: the rail is in § 3; `check-autopilot-rails-hook.sh` exits 0
(it reads the preamble template).

### Step 10: S4 runs its cases itself (Q12)

- Repo-mode S4 block (line 2659): "Then run each case yourself, in the
  order listed, …", with a Why: the cases run at one HEAD in one working
  tree and may start servers or suites, so they share the tree and the
  machine's ports.

Acceptance: the block reads so; `check-autopilot-rails-hook.sh` exits 0.

### Step 11: S5 and S6 report their checks (Q2, follow-up ruling)

- S5 block (line 2798): the reply line per fixed defect adds each check
  run for it: `<command> → exit <n>`.
- Plugin-mode S6 block (line 2891): "Run the checklist's pre-flight block;
  its two count lines and each command's exit code go in your reply." and
  the reply line to match; Phase 4's description of S6 (line 1873) names
  the exit codes beside the count lines.
- New behavior, decided here: both reports quote the pre-flight's exit
  codes, and a non-zero one is named in both as a pre-flight failure. Why:
  evidence nobody reads is not confirmation (Q3); today the reports carry
  only the two count lines, which a failing command before them may leave
  unwritten.

Acceptance: both blocks, line 1873, and the two reports' templates read
so; `check-autopilot-rails-hook.sh` exits 0.

### Step 12: Read-only sweeps may go to parallel subagents (Q13)

- `skills/generate-task/SKILL.md` Phase 1 (line 85), `skills/generate-guide/SKILL.md`
  Phase 1 (line 81), `skills/diagnose-bug/SKILL.md` hypothesis verification
  (line 207) and adjacent cases (line 271): add a paragraph each: a sweep
  that only reads — the code behind several plan steps, the config across a
  project, a hypothesis checked by reading a code path, sibling code paths —
  may go to read-only subagents sent in one message, foreground, each
  returning `file:line` for what it reports and writing nothing; the main
  session reads every line a task, a guide sentence, or the diagnosis rests
  on before writing it. Probes that run code, the reproduction test's
  repeated runs, and the decomposition, the guide, and the diagnosis
  themselves stay in the main session. Why: **Delegate in parallel**, with
  the traceability these documents promise kept by reading the cited lines.

Acceptance: the three skills carry the paragraph; `check-instruction-files.sh`
and `check-doc-sync-anchors.sh` exit 0.

### Step 13: Correct the two stale platform statements (Q14)

- `CLAUDE.md` line 359: replace "Subagents cannot spawn other subagents"
  with: kenspc's agents cannot dispatch subagents, since none lists Agent
  in `tools:`; Claude Code itself nests to depth 3 by default (2.1.301,
  `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`); orchestration stays at the skill
  (main session) level.
- `CLAUDE.md` lines 411–418, `plugins/kenspc/README.md` § Known behavior
  (lines 1487–1492), `docs/release-checklist.md` lines 104–106: record the
  2026-10-17 measurement — in a 2.1.301 Desktop session the parameter is
  present, `false` holds the call until the subagent finishes, and an
  omitted parameter runs it in the background; the interactive terminal CLI
  is not measured, and the binary drops the parameter there when fork mode
  is on.

Acceptance: no durable file still states either platform fact.
`grep -rn 'cannot spawn' CLAUDE.md plugins/ docs/release-checklist.md docs/roadmap.md --exclude=CHANGELOG.md`
prints no line — run once before the edit as a positive control, where it
prints `CLAUDE.md` line 359; and
`grep -rn 'has no such parameter\|has no .run_in_background.\|takes effect only in headless' CLAUDE.md plugins/ docs/release-checklist.md --exclude=CHANGELOG.md`
prints no line — its positive control before the edit prints `CLAUDE.md`
line 417, README line 1490, and release-checklist line 105. The plan and
task documents under `docs/plans/` and `docs/tasks/`, and the historical
records under `docs/dry-runs/`, are left out: they quote the old text by
design. `check-all.sh` exits 0.

### Step 14: Doc-sync

Depends on: Steps 1–13. Brings the documents under Documentation impact in
line with Steps 1–13.

Acceptance: each listed document reads true against the steps;
`bash scripts/check-all.sh` and `bash scripts/check-all.sh --self-test`
exit 0, with `guards run:` and `self-tests run:` unchanged from `20000bf`
(no guard is added).

## Documentation impact

- `plugins/kenspc/README.md` — the reviewer section (Q6's list and Q7's
  standalone note), task-review's and task-implement's run-directory and
  report descriptions (Schema C's Detail, code-fixer's `Final checks:`
  line, Schema D's `## Checks run`), the top-level-only rule (Step 1), the
  autopilot section (Steps 8–11), the three skills' read-only sweeps (Step
  12), and § Known behavior (Step 13).
- `CLAUDE.md` — § Subagent Review Architecture (the Phase 1 and Phase 3
  bullets for Steps 3 and 5, the top-level rule for Step 1), the
  `check-run-contract.sh` entry under Repository scripts/ (Step 3's
  literal), lines 359 and 411–418 (Step 13), and § Sessions, not agents
  (Steps 8–9).
- `plugins/kenspc/CHANGELOG.md` — a 4.9.0 entry for Steps 1–13.
- `docs/release-checklist.md` — lines 104–106 (Step 13), and the smoke
  rows for task-review / task-implement where they describe what the
  report shows (Step 5).
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: Schema D is task-implementer's reply, not the task document.
- `README.md` — N/A for this document: no skill's summary row changes.

## Testing Strategy

- After each step, the guards it names (each step's Acceptance).
- Step 3's new literal is held by `check-run-contract.sh` with a self-test
  rename per carrier, so its absence in any carrier turns the guard red.
- At the end, `check-all.sh` and `check-all.sh --self-test`, plus
  `claude plugin validate --strict .` and `./plugins/kenspc`.
- Not covered by any guard: whether a session reading the new sentences
  behaves as intended. The release smoke run (a task-review on a small
  change) is where Schema C's new Detail cells and code-fixer's
  `Final checks:` line are first seen.

## Risks and Mitigations

- **Reviewers over-classify tests as port-bound**, so they read more from
  `suite-run.md` and verify less themselves. Mitigation: the files still
  run, once, in regression-verifier's check 3, and row 3 names each.
- **A longer reviewer description** changes how auto-delegation matches
  the reviewers. Mitigation: one short sentence at the end; the first
  sentence, which carries the trigger, is unchanged.
- **Wider Schema C cells** make the final report harder to scan.
  Mitigation: one `→ exit <n>, log <path>` form per command; logs carry the
  output, the cell does not.
- **Byte-identity drift** across the five reviewers and the canonical
  blocks. Mitigation: the guards in each step's Acceptance.
- **The subagent rail in Step 9 is text only.** A subagent that ignores it
  and nests or starts `claude -p` is not stopped; the rails hook still
  guards its Bash and file calls in a worker. Mitigation: the rail is
  written into every subagent prompt; enforcing it in the hook would need
  the hook to tell a subagent's call from the worker's, which this plan
  does not attempt.
- **The autopilot main session reads S6's reply into its reports.**
  Mitigation: the two count lines keep their form and the exit codes are
  added beside them; Step 11 updates Phase 4's description of S6 (line
  1873) and the two reports' templates together.

## Open Questions

- The interactive terminal CLI's Agent tool is not measured (Step 13
  records it as unmeasured). Measuring it needs a terminal session the
  user starts; nothing in this plan depends on the answer.
