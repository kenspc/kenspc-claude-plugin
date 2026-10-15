# Plan: Batch L — autopilot field lessons (first slice of 4.6.0)

## Objective

Build into the plugin the remedies the dayaku-crm batches applied by hand,
for roadmap items 29, 30, 31, 32, 33, 35, 37, and 39 (`docs/roadmap.md`,
Next minor (4.6.0)), so that a main session no longer adds them to every
batch's prompts.

In scope: the autopilot skill's preamble, `## Autopilot` fields, S4 and S6
task blocks, budget projection, return reading, and a switch for S3b; two
new scripts under `skills/autopilot/scripts/` and a guard for them;
task-implement's slicing of a large task document; generate-plan's
`## Autopilot` section and its draft file.

Out of scope: roadmap items 34 (second fix round), 36 (heavy commands
across parallel reviewers), 38 (rails gaps), and 40 (runtime walk), which
need design decisions of their own; of item 30, the baseline dry run of
the acceptance commands (item 21); of item 39, the condition under which
S3b runs and the trial before the default changes — this plan builds the
switch alone, default `on`; any release, version bump, tag, or
push; installing the plugin. The commits stay local on `main`.

## Background / Context

Thirty-three dayaku-crm batches ran under the autopilot between 29 Sep and
14 Oct 2026 (records: `~/Projects/_smoke/_logs/<batch>-state.md` and
`-report.md`, and the memory note
`~/.claude/projects/-Users-kenspc-Projects-Diagnohab-dayaku-crm/memory/autopilot-template-additions-that-held.md`,
on the maintainer's Mac only). Their main sessions added the same text to
every batch's preamble and S4 block, passed the budget projection by
ruling, built the S6 task block by hand, and resumed a usage-limit end the
skill would not have recognized. The roadmap items carry the evidence for
each; this plan does not repeat it.

One fact found while planning, not yet on the roadmap: therapists-portal's
S3 ended on the usage limit with a JSON whose `subtype` is `success` and
whose `is_error` is `true` (result text: `You've hit your session limit ·
resets 12am (Asia/Kuala_Lumpur)`). The skill reads a return as a death only
when the subtype is not `success`, so read literally that end was a
success; the main session caught it by hand.

## Technical Approach

- **Prompt text over machinery, except where a rule failed as prose.** Most
  remedies are sentences in the templates the workers read, since the
  by-hand versions held as sentences. The two exceptions are the S4 command
  extraction and the zero-diff check: each main session wrote its own
  extractor and its own zero-diff call, and both went wrong as prose (four
  of 60 commands extracted with stray backticks; a zero-diff check that
  compared nothing twice). They become shipped bash scripts with a guard.
- **The scripts run under bash by their shebang.** The zsh traps that broke
  the by-hand versions (an unquoted variable kept as one word) do not apply
  to a `#!/bin/bash` script, and the guards already run under the bash 3.2
  macOS ships, so the scripts avoid bash 4 features.
- **Slicing by a CONTEXT key.** task-implementer gains an optional
  `TASK_LIMIT` key; task-implement dispatches slices of 12 incomplete tasks
  and merges the slices' Schema D. Why 12: one implementer ended on
  `Prompt is too long` after 22 tasks, and a slice must leave room for the
  review fixes and notes a task adds; the value is one constant in
  task-implement, stated with this reason.
- **The S3b switch hands S3b's place to S3's own review.** With
  `Standalone review: off` (repo mode only), S3's Schema G verdict enters
  the verdict loop where S3b's Schema F verdict did; S5 and the narrowed
  review are unchanged. In plugin mode the field is a settings stop, since
  a session that edited the plugin still runs the text it started with.
- **generate-plan keeps its draft in a file.** The draft lives at
  `<plans dir>/<name>.draft.md` from the first print, each print reads that
  file in full, and approval renames it. The approved text and the written
  file are then the same bytes by construction.

## Implementation Steps

Each step changes the files it names and nothing else, and ends with
`bash scripts/check-all.sh` green. The steps run in the order numbered.
Steps 1, 2, 4, 5, 6, 7, and 9 all edit `skills/autopilot/SKILL.md`, and
several share a section — steps 1 and 2 the preamble's § 6, steps 1 and 6
§ Launch, wait, return (the return) and § The state file, steps 1, 4, and
7 the reviewer report, steps 4 and 7 Phase 2's DONE line, § The zero-diff
check, Phase 3, Phase 4's zero-diff re-run, and § Phase transitions — so
each step edits the text as the earlier steps left it and keeps their
additions. Step 4 depends on step 3 (it copies the scripts step 3
creates); step 9 depends on step 2 (it names the `Run facts:` field in the
grammar it writes).

Every rule a step adds to a skill or an agent carries its Why in the
file's form, the failure stated in its own words and not cited as a
dry-run record (CLAUDE.md, Writing Rules for Skill Content).

### Step 1: Preamble additions (item 29)

Files: `plugins/kenspc/skills/autopilot/SKILL.md` (Templates § The
preamble, its Why paragraphs; § Launch, wait, return, the return; § The
state file; the reviewer report template).

- § 3 gains: a worker and its subagents write nothing under `~/.claude`,
  by a file tool or a shell command; a lesson worth keeping goes under
  `## Lessons for the main session` in the worker's final message; the
  harness's own writes there (over-long tool results under
  `~/.claude/projects/…/tool-results/`) are the harness's, not a breach.
- § 3 gains the sentence `Only § 3 holds rails.` A constraint in § 6 is not a rail; a
  departure from one is listed under `## Rail observations` and stops
  nothing. The rails a worker writes into a subagent prompt or an agent's
  `CUSTOM_INSTRUCTIONS` are § 3 as written, never narrower, so code-fixer
  may edit and commit and regression-verifier may build and run the suite.
- § 6's template line for the constraint sections says a constraint stated
  in the preamble's own words quotes the spec's sentence.
- The return reads `## Lessons for the main session` and records each
  entry under a new `worker lessons:` section of the state file, with the
  worker's tag, as it records `## Rail observations`; the reviewer report
  gains a `Worker lessons:` line built from that section, listing each by
  tag, `none` when it is empty. Why the state file: the reviewer report's
  lines are built from it, since a long batch compacts the conversation.
- Each addition gets a Why sentence in the paragraphs under the template,
  in the file's form, stating the failure in its own words (no dry-run
  citation).

Acceptance: `grep -c 'Lessons for the main session' SKILL.md` ≥ 3 (§ 3,
the return, the Why); `grep -q 'Worker lessons:'`; the state file's
template holds `worker lessons:`; the literal
`Only § 3 holds rails.` occurs in the preamble template;
`bash scripts/check-autopilot-rails-hook.sh` green (it holds the
`## Rail observations` literal in the template).

### Step 2: `Run facts:` field and suite gates (item 32)

Files: `plugins/kenspc/skills/autopilot/SKILL.md` (§ The `## Autopilot`
section table; Templates § The preamble § 6 and its notes).

- New table row: `Run facts:` — sub-bullets of free text, measured facts
  of the machine that bind every worker and are not the spec's
  constraints; default empty.
- § 6 gains a `Run facts:` line, written when the field is set and omitted
  when empty, as the Allowed files line is: the sub-bullets as written,
  then the sentence that a gate a run fact or the spec sets on a command
  (another session's go before a full suite) is asked by the worker itself
  with SendMessage, since the `kenspc:*` subagents have no message tool,
  and the go is named in the dispatch of the agent that runs the command.

Acceptance: the table holds a `Run facts:` row; § 6's template holds a
`Run facts:` line and the sentence naming that subagents have no message
tool; the note under the template says when the line is written.

### Step 3: The two scripts and their guard (item 30, scripts)

Files: new `plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh`,
new `plugins/kenspc/skills/autopilot/scripts/zero-diff.sh`, new
`scripts/check-autopilot-scripts.sh`.

- `extract-acceptance.sh <spec file> <out dir>`: reads the `## Autopilot`
  section, finds the `Acceptance:` field (a label with a parenthesized note
  included), and writes one file per sub-bullet, `<nn>` being its
  position in the field as two digits from `01`: `<nn>.cmd` holding the
  command when the text before ` — PASS: ` is one code span, `<nn>.case`
  holding that text otherwise. The command is the text between the code
  span's backtick runs as it stands, except that one space is removed from
  each end when it both begins and ends with a space and is not all spaces
  (the CommonMark rule); continuation lines are joined with one space. It
  prints `commands: <n>, cases: <m>` and exits 0; `Acceptance: none`
  writes no file, prints `commands: 0, cases: 0`, and exits 0; a section
  or field it cannot find is exit 2 with the reason on stderr.
- `zero-diff.sh <baseline> <paths file>`: reads one path per line (blank
  lines skipped), names each path absent at the baseline on stderr, runs
  `git diff --stat <baseline> HEAD --` over the paths as an array, prints
  `compared: <n> paths` before the stat, and exits 0 when the stat is
  empty, 1 when it is not, 2 on a usage error. A paths file with no path
  in it, once blank lines are skipped, is a usage error: `git diff` with
  no path after `--` compares the whole tree.
- `check-autopilot-scripts.sh` runs both against fixtures in a temp
  directory: single and double backticks, a backtick inside a
  double-backtick span, spans with and without the padding spaces, a
  label with a note, an `(optional)` case, a description case, a
  continuation line; a path with a space, a changed path, an unchanged
  path, a path absent at the baseline, an empty paths file (exit 2),
  `Acceptance: none` (`commands: 0, cases: 0`). `--self-test`
  turns it red with mutants (padding stripping removed; continuation
  joining removed; the paths read as one word) and green again on the
  originals. Bash 3.2 compatible, no recursive `rm` in cleanup beyond a
  `mktemp` trap of its own directory.

Acceptance: `bash scripts/check-autopilot-scripts.sh` exits 0;
`bash scripts/check-autopilot-scripts.sh --self-test` exits 0 and reports
each mutant red; `bash scripts/check-all.sh` prints `guards run: 13`;
`bash scripts/check-all.sh --self-test` ends with `self-tests run: 12`;
`bash scripts/check-no-model-names.sh` green.

### Step 4: S4 and the zero-diff check use the scripts (item 30, skill)

Depends on step 3. Files: `plugins/kenspc/skills/autopilot/SKILL.md`
(Phase 0 § The workspace, the driver copy; Phase 2's DONE line; Phase 3;
§ The zero-diff check; Phase 4's zero-diff re-run; Templates § The task
blocks, S4 repo mode; § The reviewer report; § Phase transitions).

- Phase 0 copies both scripts beside the driver copy, as
  `_prompts/<batch>-extract-acceptance.sh` and `_prompts/<batch>-zero-diff.sh`,
  for the reason the driver is copied — a plugin-mode S3 may edit the
  shipped scripts, and a running batch keeps the text it started with —
  and so the S4 worker runs the same copy as the main session, by the
  workspace path its block names.
- Phase 3, repo mode: before S4's first launch the main session runs the
  extraction copy on the spec as Phase 0 read the section —
  `git show <baseline>:<spec path>` in spec entry, the spec at S1's commit
  (`git show <S1 hash>:<spec path>`) in brief entry — saved to
  `_prompts/<batch>-spec.md`, into `_prompts/<batch>-s4-cmds/`, and checks
  that `commands:` equals the number of command cases it reads in the
  field.
- The S4 repo-mode block lists each case as "the command in
  `<file>`" with its PASS criterion; the worker runs the extraction copy
  itself, on `_prompts/<batch>-spec.md`, into
  `<workspace>/_prompts/<batch>-<tag>-cmds/`, shows `cmp` equal for every
  file against the main session's, and shows one `cmp` of two files that
  differ reporting the difference, so the comparison is seen able to fail;
  it then runs each with `<shell> <file>`, `<shell>` being the shell the
  main session's own Bash tool runs (`ps -p $$ -o comm=`), written into the
  block. The block tells the worker that a command it adds to inspect a
  result (reading a log, listing a directory) carries no redirect, since a
  redirect to a path outside the roots is a breach.
- A case the extraction writes as `<nn>.case` (a description, not one
  code span) is listed with its text, as today. A corrected case (Phase 3,
  A corrected case) is listed as the file `<nn>.corrected.cmd`, which the
  main session writes from the clarification's corrected form beside the
  extracted files; it stays out of the worker's `cmp` comparison, since no
  extraction from the spec produces it, and its line names the
  clarification as today.
- The reply asks, per command, for its exit code and the evidence it
  leaves (the files, logs, or clones it writes, by path) in place of the
  last twenty lines of output. Phase 3's repo-mode paragraph, which states
  the same run and reply (`one command per Bash call`, `the last twenty
  lines`), and its `Acceptance record:` sentences, which write the same
  lines to the record, change with the block.
- § The zero-diff check calls `zero-diff.sh` with the `Zero diff:` paths
  written one per line to `_prompts/<batch>-zero-diff.txt`, and checks
  that `compared:` equals the number of paths in the field.
- The script always prints its `compared:` line, so every place that reads
  the check as "printed nothing" reads its exit code instead: Phase 2's
  DONE line (`the zero-diff check has printed nothing`), § Phase
  transitions (`the empty zero-diff output`), Phase 4's re-run before S6,
  and the reviewer report's `zero diff: <nothing printed | the paths>`
  field, which reports the `compared:` count and the paths the stat names
  in place of `nothing printed`.

Acceptance: `grep -q '<batch>-extract-acceptance.sh'` and
`grep -q '<batch>-zero-diff.sh'` in SKILL.md; SKILL.md no longer holds
`one per Bash call`, `one command per Bash call`, nor `twenty lines`;
`grep -q 'corrected.cmd'` in SKILL.md; SKILL.md no longer holds `zero diff: <nothing
printed` nor `empty zero-diff output`, and Phase 2's DONE line names the
zero-diff check's exit code; `bash scripts/check-autopilot-rails-hook.sh`
green.

### Step 5: Budget projection per role (item 31)

Files: `plugins/kenspc/skills/autopilot/SKILL.md` (§ Budget and caps).
The gates table's budget row keeps its wording: it names projected
without defining it.

- Projected becomes the largest cost so far of a session of the role about
  to launch — S1, S2, S3, S3b, the narrowed reviews together, S4, S5, S6,
  each with its resumes and re-runs — or the budget divided by six before
  that role's first session. A plugin-mode S4's cost is its own session's
  plus the trial's and the cases' costs from its record, as spent counts
  them, since its own JSON holds none of its nested sessions. The hard
  cap (`--max-budget-usd` with the remaining amount) is unchanged. The Why
  states the failure: a USD 1 release preparation judged against a USD 70
  implementation session.

Acceptance: § Budget and caps no longer holds `the largest single-session
cost of this batch`; it holds `of the role about to launch`; the
`--max-budget-usd` bullet is unchanged (`git diff` from the step's start
changes no line of the bullet that opens `Every launch passes`).

### Step 6: Usage-limit end, `is_error`, and the sleep log (item 33)

Files: `plugins/kenspc/skills/autopilot/SKILL.md` (§ Launch, wait, return,
the return; § Death and resume; the state file's status words; § The stop
conditions, Stops stated at their own steps).

- A JSON with `is_error: true` is not a success, whatever its subtype.
- One whose result names a usage or session limit with a reset time is a
  usage-limit end: not a death, so it does not count toward the dead-twice
  stop; the step is resumed under its next `-r<k>` after the named reset,
  and the resume counts under `Caps:`. The main session, headless or
  interactive, does not wait through the reset by polling: when one of its
  tools can schedule a wake-up of the session, it schedules one after the
  named reset and ends its turn; otherwise it stops with
  `Autopilot stopped: usage limit, resets <time>` naming the step and the
  resume that continues it, with the sentence for a session that cannot
  ask (the run ends with that message). The turn after the reset — the
  wake-up, or the user's word — makes the resume. Why: the workers run
  under the main session's own account, so the limit that ended a worker
  can refuse the main session's turns too, and a poll is a turn.
- The state file's `sessions:` status words gain `usage-limit`, written
  for such an end in place of `dead` or the subtype.
- The new stop (a main session with no tool to schedule its wake-up) is
  stated at its own step, so § The stop conditions' "Five
  stops sit outside the numbered list" becomes six and names it, and the
  gates table's row for a stop stated at its own step covers it.
- The report the main session gives when asked about a live worker adds,
  on macOS, the last sleep and wake lines of `pmset -g log`. A live pid is
  still never killed.

Acceptance: `grep -q 'is_error'` in § Death and resume and in the return;
the phrase `usage-limit end` occurs in both; the new stop carries the
`In a session that cannot ask (a system reminder to work without
stopping)` opening; `pmset -g log` occurs once; SKILL.md no longer holds
`Five stops sit outside`; the state file template's `sessions:` line
holds `usage-limit`.

### Step 7: `Standalone review:` switch (item 39)

Files: `plugins/kenspc/skills/autopilot/SKILL.md` (the role table at the
top and its Why paragraph; § The `## Autopilot` section table; § The start
checks; Phase 2; § The verdict loop after S3b; § The zero-diff check;
Phase 3's Inputs, DONE line, repo-mode paragraph, and `Acceptance: none`
line; Phase 4's zero-diff re-run; the settings line; the reviewer report;
§ Phase transitions).

- New row: `Standalone review:` — `on` or `off`, default `on`.
- `off` in plugin mode is a settings stop naming the field.
- `off` in repo mode: Phase 2 launches no S3b; S3's Schema G verdict and
  its review's rows enter the verdict loop in S3b's place; the zero-diff
  check runs after S3; S5 and the narrowed reviews are unchanged.
- Every passage that names S3b as the step before Phase 3 names S3 for
  the `off` case: Phase 3 runs S4 at S3's HEAD (`the S3b HEAD`),
  `Acceptance: none` records `none named; S3 is the last check` (in Phase
  3 and on the reviewer report's Acceptance line), Phase 4's zero-diff
  Why (`the check that follows S3b`) names the check after S3, and § Phase
  transitions gives S3 → Phase 3 on S3's Schema G verdict and the
  zero-diff check's result.
- The role table's S3b row and the Why paragraph under it say S3b runs
  unless `Standalone review: off` in repo mode, with the reason: in repo
  mode S3's review is already five fresh subagents, and the second reason
  for separate sessions — a session that edited the plugin still runs the
  text it started with — holds only in plugin mode.
- The settings line gains `standalone review <on|off>` after `release
  preparation`; the reviewer report's `Sessions:` list carries the line
  `S3b: off (Standalone review: off)` in S3b's place when it did not run.

Acceptance: the table holds a `Standalone review:` row; § The start checks
names the plugin-mode stop; § The verdict loop names Schema G for the
`off` case; Phase 2's DONE line covers both cases; `grep -q 'S3 is the
last check'` in SKILL.md; § Phase transitions names the `off` case.

### Step 8: task-implement slices a large document (item 35)

Files: `plugins/kenspc/agents/task-implementer.md` (CONTEXT YOU WILL
RECEIVE, OBJECTIVE, DONE CRITERIA, the processing loop, Schema D);
`plugins/kenspc/skills/task-implement/SKILL.md` (Phase 1's DONE line,
Steps 2, 4, 5; Phase 2 Step 4's Schema G `## Implementation` section).

- task-implementer: optional `TASK_LIMIT` — give a final status (DONE or
  BLOCKED, a dependency block included) to at most that many incomplete
  (TODO or IN PROGRESS) tasks, in document order, then return Schema D for
  them; a task left for a later slice keeps its status. Without the key,
  every incomplete task, as today.
- task-implement: with more than 12 incomplete tasks, Step 4 dispatches
  slices with `TASK_LIMIT: 12`, one after another, re-reading the document
  between them, until no TODO or IN PROGRESS task is left or a slice
  returns with no task's status changed;
  Step 5 renders one Schema D merged from the slices' rows and prose
  sections, rows in document order, and Schema G's `## Implementation`
  carries that merged Schema D. The batch confirmation (Step 3) is
  asked once for the whole batch. Why the constant and its value are stated
  in the step.
- task-implementer's DONE CRITERIA and task-implement's Phase 1 DONE line
  read "every incomplete task" as every incomplete task within
  `TASK_LIMIT` for a slice, and Step 4's "implements all incomplete tasks"
  sentence names the slices.

Acceptance: `grep -q 'TASK_LIMIT'` in both files; task-implementer's
CONTEXT section lists it as optional; `bash scripts/check-all.sh` green
(the canonical dispatch and verdict blocks are untouched:
`check-canonical-dispatch.sh` and `check-verdict-shared.sh` green).

### Step 9: generate-plan writes `## Autopilot`; S6 follows a list's order (item 37)

Depends on step 2. Files: `plugins/kenspc/skills/generate-plan/SKILL.md`
(Phase 2 Step 1 elements); `plugins/kenspc/skills/autopilot/SKILL.md`
(Phase 4's Repo mode paragraph; Templates § The task blocks, S6 removal
block and its notes).

- generate-plan: when the user asks for the plan to run under
  `/kenspc-autopilot` or for an `## Autopilot` section, the plan's last
  section is `## Autopilot`, written to the grammar in
  `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/SKILL.md` § The `## Autopilot`
  section, read by path at run time. Before the print it checks every
  label against that table, `Budget:` as exactly `USD <n>` (a note goes in
  the label's parentheses), and every `Acceptance:` sub-bullet for
  ` — PASS: `; a failure is fixed in the draft before the print.
- autopilot S6: a `Release preparation:` list one of whose sub-bullets
  makes the removal commit (`git rm` of the spec and the task document)
  governs the order: the removal paragraph is not written, the question
  paragraph names the list's removal commit, and a `Version:` set by one of
  the list's commits is set there and nowhere else. Phase 4's Repo mode
  paragraph (`after the default removal unless the list says keep`, and
  the bump riding in the removal commit) states the same case.

Acceptance: `grep -q '## Autopilot'` in generate-plan's SKILL.md;
autopilot's S6 notes name the case of a list that makes the removal;
`bash scripts/check-instruction-files.sh` and
`bash scripts/check-doc-sync-anchors.sh` green.

### Step 10: generate-plan keeps the draft in a file (item 37)

Files: `plugins/kenspc/skills/generate-plan/SKILL.md` (Phase 2 Steps 2
and 3).

- The draft is written from its first print to `<plans dir>/<name>.draft.md`
  (the output location resolved as Step 3 resolves it, the conflict check
  included, and a `<name>.draft.md` an earlier run left counted as a file
  at the target path), and every print reads that file in full. A revision edits the
  file and prints it again. Approval renames the file to `<name>.md`; no
  other write follows. A run that ends without approval names the draft
  file in its final message as the user's to keep or delete. The
  session-that-cannot-ask branch prints the draft file and stops as today;
  its `Nothing is written` sentence becomes "nothing but the draft file is
  written", and its Why (an unapproved plan written, reviewed, and
  committed) still holds, since the draft file is neither reviewed nor
  committed.
- The Why replaces the seven-of-355-lines evidence sentence's conclusion:
  the file is the approved text by construction.

Acceptance: generate-plan's SKILL.md holds `.draft.md`; it no longer holds
`Do not write it to a file yet` nor `Nothing is written,`; the cannot-ask sentence at Step 3 is
kept (`grep -c 'In a session that cannot ask'` unchanged or higher).

## Testing Strategy

- Every step: `bash scripts/check-all.sh` green; at the end also
  `bash scripts/check-all.sh --self-test` (expected `guards run: 13`,
  `self-tests run: 12`), `claude plugin validate --strict .` and
  `claude plugin validate --strict ./plugins/kenspc`.
- Step 3's guard holds the two scripts' behavior; its self-test proves the
  guard can fail.
- No headless acceptance run in this batch: no release follows it, so the
  installed version stays 4.5.2. The first dayaku-crm batch
  run on the next installed version is the live check of steps 1, 2, 4,
  5, 6, and 7, and of step 9's S6 half when its `Release preparation:`
  list makes the removal; the release that ships this batch decides whether
  a seeded acceptance is also needed.
- Steps 8 and 10, and step 9's generate-plan half, have no live check in
  this batch beyond their acceptance greps: the next `/kenspc-plan` run
  exercises steps 9 and 10, and the first task document with more than 12
  incomplete tasks exercises step 8.

## Risks and Mitigations

- **The autopilot SKILL.md grows (2,625 lines today), and every main
  session reads it.** Mitigation: three additions replace text rather than
  add to it (the S4 repo-mode block's run and reply lines, Phase 3's
  repo-mode paragraph, the projection sentence), and each Why states the
  failure in one sentence.
- **`is_error` read as a failure changes the return for runs that ended
  that way and were read as success.** Intended; the CHANGELOG names it.
- **The draft file can be left behind.** It is untracked, and an untracked
  file is not inert here: the autopilot's clean-tree start check stops on
  it, and a commit that stages everything sweeps it in. Mitigation: a run
  without approval names it in its final message as the user's to keep or
  delete.
- **The main session shares the usage limit its worker hit.** The workers
  run under the same account as the main session, so a limit that ends a
  worker may end the main session's next turn too; a headless main session
  that waits by polling makes a model turn per poll. Mitigation (the
  user's decision on the reviewed plan's Open Question 3, 15 Oct 2026):
  step 6 never polls through the reset; the main session schedules one
  wake-up after it or stops with the reset time, so its only turn falls
  after the reset.
- **A guard literal moved by an edit.** Mitigation: the guards named in
  each step's acceptance run after it.

## Documentation impact

- `plugins/kenspc/README.md` — the autopilot section (the `Run facts:` and
  `Standalone review:` fields, the S4 extraction, the per-role projection,
  the usage-limit end), task-implement (slices of 12), generate-plan (the
  draft file, the `## Autopilot` section); Known behavior where it states
  the projection. Steps 1, 2, 4, 5, 6, 7, 8, 9, 10.
- `CLAUDE.md` — Plugin Directory Layout and File Structure (the two new
  scripts under `skills/autopilot/scripts/`); Repository scripts/ (the new
  guard, and the counts: thirteen guards, twelve with a self-test); CONTEXT
  block contract (`TASK_LIMIT`); Subagent Review Architecture § Sessions,
  not agents (autopilot) (S3b runs unless `Standalone review: off` in repo
  mode; `--resume` also continues a worker ended by the usage limit);
  Non-Goals (the autopilot paragraph's "the implementer, the reviewer, and
  the acceptor are three sessions", which holds in repo mode only while
  S3b runs). Steps 3, 6, 7, 8.
- `plugins/kenspc/CHANGELOG.md` — a `## 4.6.0 — unreleased` heading with
  Added, Changed, and Fixed entries for every step. Steps 1 to 10.
- `docs/release-checklist.md` — the pinned counts `guards run: 13` and
  `self-tests run: 12`. Step 3.
- `docs/roadmap.md` — N/A for this document: its items leave it when they
  ship, at the release, not in this batch; items 30 and 39 then leave only
  in part (Objective, Out of scope).
- `README.md` — N/A for this document: no skill's one-line summary
  changes.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this
  document: step 9's `## Autopilot` section is written only when the user
  asks for it, and the example plan is not an autopilot plan.

## Open Questions

1. Whether 12 is the right slice size; the one data point is an
   implementer that held 22 tasks of participants-api's size and failed
   after. The constant is one line to change.
2. Whether S4's commands should run under the shell the main session's Bash
   tool uses or under a shell the spec names; this plan takes the former,
   which matches how the by-hand runs worked on macOS.
