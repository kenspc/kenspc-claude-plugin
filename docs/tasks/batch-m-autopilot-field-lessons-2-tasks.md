# Batch M — autopilot field lessons (second slice) — Task Document

## Context

Build into the kenspc plugin the second slice of the dayaku-crm autopilot
lessons: the second fix round and the rulings grammar, the shared suite run
and the tree check around parallel reviewers, the rails hook's redirection
and GitHub checks, benign breaches, `Standalone review: auto`, BLOCKED
tasks, and the runtime walk (S4w). Every task implements the bullets of
one plan step, or a named part of one, and the plan's text — its Technical
Approach section for the design and its Implementation Steps for the
files — is the specification: read the step and the Technical Approach
subsection it names in full before starting the task.

Related plan: `docs/plans/batch-m-autopilot-field-lessons-2.md`

Rules for every task, from the plan's Implementation Steps:
- Each rule a task adds to a skill, an agent, or the hook carries its Why
  in the file's form, the failure stated in its own words and not cited as
  a dry-run record (CLAUDE.md, Writing Rules for Skill Content).
- A stop a task adds to a skill opens its no-ask branch with "In a session
  that cannot ask (a system reminder to work without stopping), …".
- Tasks 5, 8, 9, 10, 11, 12, and 13 edit
  `plugins/kenspc/skills/autopilot/SKILL.md` (Task 14 too, when it adds a
  driver flag), and Tasks 2, 3, 4, and 6
  edit `skills/task-review/SKILL.md` and `skills/task-implement/SKILL.md`;
  each task edits the text as the earlier tasks left it and keeps their
  additions.
- Every task ends with `bash scripts/check-all.sh` green; a task that
  changes a guard also ends with `bash scripts/check-all.sh --self-test`
  green.
- A criterion that a file holds, or no longer holds, a phrase is checked on
  the file with its line breaks joined, e.g.
  `tr '\n' ' ' < FILE | tr -s ' ' | grep -cF '<phrase>'`, not with a line
  grep: these files wrap prose at about 75 columns, so a phrase split
  across two lines is invisible to a line grep.
- Tasks 1 and 15 launch headless `claude -p` sessions that cost money:
  Task 1 at most USD 5 in all, Task 15 at most USD 40 in all; a task that
  would pass its cap stops and is marked BLOCKED with the spend so far.
  Neither task quits, restarts, signs out of, or reconfigures the user's
  Chrome or its extension, nor uses or closes the user's own tabs: a
  "tool not usable" state is made in the worker's own launch (no
  `--chrome` flag, or an MCP configuration that leaves the server out,
  e.g. `--strict-mcp-config` with a configuration file that omits it).
- Tasks 1 and 15 use the user's Chrome, and the user asked to be told
  before Chrome is used (16 Oct 2026). The main session runs them itself,
  telling the user first and waiting for the go-ahead. An unattended
  implementer that reaches either while it is TODO marks it BLOCKED with
  `needs the user's Chrome; the main session runs it after telling the
  user`, and makes no launch.
- Commits stay local on `main`; no push, no tag, no version bump, no
  plugin install.

Dependency note: Task 3 depends on Task 2; Task 4 on Tasks 2 and 3; Task 5
on Task 4; Task 8 on Task 7; Task 11 on Task 10; Task 12 on Tasks 1 and
10; Task 13 on Tasks 11 and 12; Task 14 on Tasks 1, 12, and 13 (it sets
its variable in the S4w launch Task 13 writes); Task 15 on Tasks 12-14;
Task 16 on Tasks 1-15.

Run order for the two main-session tasks: Task 1 runs before the
implementer is dispatched, so Tasks 12-14 find it DONE rather than
BLOCKED by the dependency gate; Task 15 runs once Tasks 12-14 are DONE,
and Task 16 after it, since its `Depends on` names Task 15.

## Tasks

### Task 1: Probe the browser tools in a headless worker

**Status:** DONE

**Implementation notes:**
- Decisions: run by the main session after the user confirmed Chrome was
  ready (16 Oct 2026). A headless `claude -p --chrome` worker could not
  reach Claude in Chrome ("Browser extension is not connected") while the
  desktop session saw the browser connected under the same account; the
  cause is not determined (record, Conclusion). So Tasks 12 and 13 write
  the Playwright MCP alone, with the start check
  `claude mcp list 2>&1 | grep -E '^playwright: .* - ✔ Connected$'`
  (exit 0 usable, exit 1 not), and Task 14 needs no driver flag. The
  Playwright MCP writes screenshots only under its output directory and the
  session's working directory, so a walk worker copies them into the
  workspace. Record: `docs/dry-runs/batch-m-walk-probe.md` (bbf3239).
- Changes/tradeoffs: a second Chrome launch (`batchm-probe-ch2`) called the
  tab-context tool even after the empty browser list, to rule out a probe
  that stopped too early; the "not usable" Playwright answer of the check
  command was shown with `CLAUDE_CONFIG_DIR` pointed at an empty directory,
  and the worker-side negative with `--strict-mcp-config`. Four launches,
  USD 1.1622 in all.

Implement plan Step 1. Output: `docs/dry-runs/batch-m-walk-probe.md`,
committed alone (`docs: add batch m walk probe record`).

On a throwaway seed under `~/Projects/_smoke/` (a static HTML page served
on `127.0.0.1`), launch headless sessions through a copy of
`plugins/kenspc/skills/autopilot/scripts/run.sh` placed in the workspace,
so they run as a worker runs (`bypassPermissions`, the marker set).
`run.sh` passes a fixed flag set, so a launch with `--chrome` uses a
second probe copy with the flag added to its `args=(…)` line; the shipped
`run.sh` is not edited. Record for each tool — Claude in Chrome and the
Playwright MCP:

1. whether its tools are present in the worker session, and with which
   flags (`--chrome` or none);
2. a navigation to the seed's page and a screenshot written under the
   workspace;
3. a check command the main session can run before the first launch that
   says usable or not usable, shown both ways — usable as set up, and not
   usable with the tool made unavailable in the worker's own launch (see
   Context) — with both outputs recorded;
4. the cost of each launch (the last cumulative `total_cost_usd` of each
   session).

**Acceptance criteria:**
- The record holds the four items for both tools, each check command shown
  returning both answers, with its output.
- The total cost recorded is at most USD 5.
- When a headless worker cannot use Claude in Chrome, the record says so
  with the error, and states that Task 12 and Task 13 write Playwright
  alone.
- When a headless worker can use neither tool, the record says so with
  both errors and this task is marked BLOCKED (`neither tool usable in a
  headless worker; the maintainer rules on the record`), so Tasks 12-15
  do not start; Tasks 2-11 do not depend on it.
- The shipped `run.sh` and `run.ps1` are unchanged (`git diff --quiet --
  plugins/kenspc/skills/autopilot/scripts/` exits 0 after the commit).

---

### Task 2: Rulings grammar — DEFER tail, outside-grammar entries, duplicates, clauses

**Status:** DONE

**Implementation notes:**
- Decisions: the tail form sits second in the grammar block, right after
  the plain FIX form, so check 7's self-test literal (the DEFER entry)
  still occurs on one line of each carrier. An entry outside the grammar
  is not carried out as a whole — both entries naming one duplicated ID,
  and every entry of a file whose first line names nobody — and its IDs
  fall back to code-fixer's own rules; code-fixer names it in a new reply
  line, `Rulings outside the grammar: <entry> (<what is wrong>)…`, beside
  the existing `Ruled IDs in no report:` line, and regression-verifier
  fails row 1 for it whether or not code-fixer named it. task-implement
  points at task-review's Step 5 for the tail, group, outside-grammar, and
  duplicate rules rather than carrying a second copy of the prose.
- Changes/tradeoffs: check 7 gained no new logic — the tail is held by the
  byte-identity comparison, and only its header now names the four forms;
  removing the tail from all four carriers at once would still pass. The
  round-2 replacement rule (a round-2 entry replaces round 1's for the same
  ID) is left to Task 4, which adds the `## Round 2` section.

Implement plan Step 2, its first bullet (Technical Approach § A second fix
round, the "Rulings grammar" bullet). Files:
`plugins/kenspc/skills/task-review/SKILL.md` (Step 5),
`plugins/kenspc/skills/task-implement/SKILL.md` (its rulings-grammar
carrier in Phase 2 Step 3, and Phase 2 Step 4's Verdict determination),
`plugins/kenspc/agents/code-fixer.md`,
`plugins/kenspc/agents/regression-verifier.md`,
`scripts/check-run-contract.sh` (check 7).

- The `canonical:rulings-grammar` block gains the form
  `- <ID>[, <ID>…]: FIX — <what to do>; DEFER rest — <reason>` in its four
  carriers, byte-identical. The row's action stays FIXED,
  regression-verifier checks the fix against the FIX text, and code-fixer
  writes the deferred part into the row's Deferred Issues prose.
- task-review's Step 5 states beside the block: an entry naming a group
  covers every clause of every named row, one sentence per clause; an
  entry outside the grammar (an unknown action word, no ID, no first line
  naming who ruled, one ID in two entries of the same round — the entries
  before `## Round 2`, or those after it; Task 4 adds that section) is not
  carried out, is named in code-fixer's reply and in regression-verifier's
  row 1, and keeps the verdict from PASS (at most PARTIAL, as for a ruled
  ID no report lists); a ruled ID's duplicate that carries no ruling is
  merged into the ruled row and takes its ruling. code-fixer and
  regression-verifier each state their side of these rules.
- The Verdict determination of both skills — task-review's and
  task-implement's (Phase 2 Step 4) — gains the outside-grammar entry
  beside the existing "ruled ID that no report lists" bullet, and its
  PASS bullet's conditions name it beside that ID.
- `check-run-contract.sh` check 7: the reference grammar includes the
  tail; its self-test still rewords an entry in each of the four carriers
  in turn.

**Acceptance criteria:**
- `check-run-contract.sh` passes; its self-test turns red on each
  carrier's mutant and green on the restored copies.
- `tr '\n' ' ' < F | tr -s ' ' | grep -cF 'DEFER rest —'` is at least 1
  for each of the four carriers.
- `code-fixer.md` and `regression-verifier.md` each state the outcome of
  an entry outside the grammar and of an unruled duplicate of a ruled ID.
- The Verdict determination of `task-review/SKILL.md` and of
  `task-implement/SKILL.md` each name an entry outside the grammar as
  keeping the verdict from PASS (joined-line read of each section).

---

### Task 3: `F` and `V` IDs and the statistics line

**Status:** DONE

**Implementation notes:**
- Decisions: the Per-angle Results table carries an `F` and a `V` row
  always, zeros included, and check 4 requires all seven rows — a fixed
  shape the recount can hold, rather than rows that appear only when
  non-zero. regression-verifier leaves `F` IDs out of its ID-set
  comparison (they are in no report by definition) and names each
  regression `V<n>` in the Detail paragraph that reports it. The example's
  `F1` row is MEDIUM, `DEFERRED — no report lists it`.
- Changes/tradeoffs: the self-test's literal mutations that quote the
  example's statistics line (`FIXED 3, DEFERRED 2`, `total reported 7 (R 1,`,
  `deduplicated to 6 unique`) moved with the new counts. The `--file`
  acceptance check ran on a hand-written schema-b under this run's scratch
  directory rather than `$TMPDIR`, since the implementer writes nothing to
  a system temporary directory: green on the file, exit 1 with
  `statistics F: line says 2, rows give 1` on its copy with the `F` count
  raised by one.

Depends on: Task 2

Implement plan Step 2, its second bullet (Technical Approach § A second
fix round, the "`F` and `V` IDs" bullet). Files:
`plugins/kenspc/agents/code-fixer.md`,
`plugins/kenspc/agents/regression-verifier.md`,
`plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md` (the
`canonical:stats-line` carriers), `scripts/check-run-contract.sh`
(checks 2 and 4).

- code-fixer records a defect no report lists as a row with Source
  `F<n>`, action DEFERRED, reason `no report lists it`; it does not fix
  outside the reports.
- regression-verifier names a regression it finds `V<n>` in its Schema C
  Detail; its ID-set comparison (VERIFICATION CHECKS item 1) takes an `F`
  row as code-fixer's own, not as an ID no report lists.
- The `canonical:stats-line` template becomes
  `total reported N (R n, E n, Q n, B n, T n, F n, V n), deduplicated to N unique, FIXED N, DEFERRED N, NOT APPLICABLE N, DEDUPED N`
  in its three carriers.
- code-fixer's worked Schema B example (`example:schema-b`) gains one `F`
  row; its Per-angle Results table and statistics line agree with its
  rows.
- `check-run-contract.sh` check 4's recount counts `F` and `V` Source IDs
  and accepts the new statistics-line shape.

**Acceptance criteria:**
- `check-run-contract.sh` passes, and its self-test is green.
- `bash scripts/check-run-contract.sh --file <f>` on a hand-written
  `schema-b.md` under `$TMPDIR` holding an `F` row and a FIX row with a
  DEFER tail recounts green, and turns red when that file's `F` count in
  the statistics line is changed by one.
- The three stats-line carriers are byte-identical (check 2).

---

### Task 4: The second fix round

**Status:** DONE

**Implementation notes:**
- Decisions: the block's text is skill-neutral ("this skill", "the final
  report", "the grammar the first round's entries follow") so one copy
  reads true in both skills; in task-implement it sits after the
  no-statistics/no-result paragraph of Phase 2 Step 3, so the existing
  "The lines above stay in English" paragraph covers the round-2 lines
  too. The final reports name `schema-c-1.md` only when a second round
  ran (`First-round Schema C: <RUN_DIR>/schema-c-1.md` under
  Verification), since without one the rendered Schema C is that file. A
  `V` ID a round-2 entry names that `schema-c-1.md` does not name is
  treated as a ruled ID that no report lists, by code-fixer and
  regression-verifier alike; regression-verifier numbers its second-round
  regressions on from the highest `V` ID in `schema-c-1.md`, so two
  rounds never reuse one `V` ID. Check 8's self-test rewords the
  one-round limit sentence (`A review runs at most one second round:`).
- Changes/tradeoffs: beyond the spec, task-review's Step 5 and
  task-implement's Step 3 each gained one clause saying a ruling given
  after code-fixer's dispatch is the second round's, so the first-round
  rule no longer reads as the only place a ruling lands; task-review's
  Step 4 sentence about the fixed English lines now names Step 7's lines.
  Step 6's "the run goes on to Step 7" was left as it is, since Step 7 is
  now the step that follows it. The self-test grew from 27 to 33
  exit-1 mutations.

Depends on: Task 2, Task 3

Implement plan Step 2, its third and fourth bullets and its
`check-run-contract.sh` bullet (Technical Approach § A second fix round,
"Triggered by a ruling", "Mechanics", "One text for both skills").
Files: `plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`,
`plugins/kenspc/agents/code-fixer.md`,
`plugins/kenspc/agents/regression-verifier.md`,
`scripts/check-run-contract.sh`.

- A new block `<!-- canonical:second-round:start -->` …
  `<!-- canonical:second-round:end -->`, byte-identical in the two skills:
  in every review, as soon as regression-verifier's first reply returns,
  the orchestrator saves it to `RUN_DIR/schema-c-1.md`; when it then holds
  a ruling given after code-fixer's first dispatch (interactive: a message
  from the user received after that dispatch; an autopilot worker: the
  main session's answer), it appends `## Round 2` with the round's entries
  to `RUN_DIR/rulings.md` (creating the file with its first line naming
  who ruled when there is none), dispatches code-fixer and then
  regression-verifier afresh (`run_in_background: false`) with the CONTEXT
  block unchanged, prints
  `code-fixer returned (round 2) — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`
  and `regression-verifier returned (round 2) — …` in the forms of the
  first-round lines (their no-statistics-line and no-result-line forms
  included), and reads the verdict from the second round. At most one
  second round per review; with no ruling held, no second round and no
  question. A round-2 entry for an ID ruled in round 1 replaces that
  entry.
- In task-review the block is a new step after Step 6, so the Schema F
  step becomes Step 8 and the skill's own references to it follow; in
  task-implement it sits in Phase 2 Step 3 after the regression dispatch.
  The final reports (Schema F, Schema G) render the second round's replies
  when one ran and name `schema-c-1.md`.
- code-fixer reads a `## Round 2` section when it exists: it carries out
  only that section's entries, updates its rows of `schema-b.md` in place,
  and keeps every row; for each `V` ID a round-2 entry names, it adds a
  row whose Source is that ID, taking the regression's file, line, and
  description from the Detail of `schema-c-1.md`.
- regression-verifier checks the second round's rows against that
  section, and takes a `V` row as listed by `schema-c-1.md`.
- `check-run-contract.sh`: a new check holds the `canonical:second-round`
  block byte-identical in the two skills, its self-test rewording the
  block in each in turn; check 5 names `schema-c-1.md` in both skills,
  `code-fixer.md`, and `regression-verifier.md`, its self-test renaming it
  in each in turn. The header's list of checks names the new one.

**Acceptance criteria:**
- `bash scripts/check-all.sh` and `bash scripts/check-all.sh --self-test`
  green; the new check's mutants turn it red, and so does each
  `schema-c-1.md` rename.
- `tr '\n' ' ' < F | tr -s ' ' | grep -cF 'Round 2'` is at least 1 for
  each of the two skills, `code-fixer.md`, and `regression-verifier.md`.
- task-review's step numbers run 1-8 with no duplicate, and every
  reference to the Schema F step in the file names Step 8.
- The block states "at most one second round" and "no ruling held, no
  second round and no question" (joined-line grep, one each).

---

### Task 5: The autopilot side of the second round, and S3b reading S3's rulings

**Status:** DONE

**Implementation notes:**
- Decisions: the S3b task block became a fenced block like the other
  roles': the command line, then a line naming S3's `rulings.md` path(s)
  marked "not part of the command above", which the worker names in its
  question. Why: task-review reads everything after its path as
  CUSTOM_INSTRUCTIONS for the reviewers, and the comparison with S3's
  rulings is the main session's, so the paths must not reach the
  reviewers. The paths are the `rulings.md` of the run directory whose
  `schema-b.md` S3's Schema G names, plus any S3 resume's, or `none`.
- Changes/tradeoffs: the verdict-loop paragraph also states the
  "narrowed reviews keep fixing" point (an incomplete fix a narrowed
  review's own code-fixer made is finished by its ruled second round,
  what it still fails goes to S5 under stop condition 3), which the plan's
  Technical Approach gives and the task's bullets left implicit. The
  preamble's Why paragraph gained the reasons for asking only after the
  last reviewer, for a late ruling landing in the second round, and for
  the one question after a result short of PASS.

Depends on: Task 4

Implement plan Step 2, its "Autopilot preamble § 1" bullet (Technical
Approach § A second fix round, "When a ruling reaches code-fixer",
"Narrowed reviews keep fixing", "S3b reads the implementation review's
rulings"). File: `plugins/kenspc/skills/autopilot/SKILL.md` (preamble § 1
and its Why; § The verdict loop after S3b; the S3b task block).

- Preamble § 1: a worker asks for a ruling on a review's findings only
  once the last reviewer has returned; a ruling that arrives after
  code-fixer's dispatch is the second round's; after regression-verifier
  returns HAS ISSUES or a verdict other than PASS, the worker sends the
  main session one question naming `schema-b.md` and `schema-c-1.md` by
  path.
- § The verdict loop after S3b: a narrowed review's verdict is read after
  its second round when one ran; the main session rules S3b's findings
  against S3's `rulings.md`, a finding an earlier DEFER or NOT APPLICABLE
  entry covered ruled the same, citing the entry.
- The S3b task block names S3's `rulings.md` path(s).

**Acceptance criteria:**
- Joined-line greps find `schema-c-1.md` in preamble § 1 and the phrase
  `second round` in § The verdict loop after S3b.
- The S3b task block holds a `rulings.md` path placeholder.
- `bash scripts/check-all.sh` green.

---

### Task 6: The shared suite run and the tree check around the reviewers

**Status:** DONE

**Implementation notes:**
- Decisions: the tree state records, beside `git status --porcelain=v1
  -uall` and the hash of `git diff HEAD --binary`, the content hash of
  each tracked path the status lists (`git hash-object -- <path>`). Why:
  a file already changed before the review keeps its status line when a
  reviewer changes it again, and the diff's hash alone could say that
  something changed but not name the file, which the stop must do. The
  suite logs and tree-state files go in `scratch/orchestrator/1/`
  (`suite-<k>.log`), named outside any runner's collection pattern;
  `suite-run.md` with no test command says so on one line. In an
  autopilot worker the block says the question goes to the main session
  "as every question there does", since the canonical block is shared
  with interactive task-review and cannot cite the preamble by section.
  A reviewer given RUN_DIR without `suite-run.md` says so in its report
  and still runs no full suite.
- Changes/tradeoffs: check 5 gained a `suite-run.md` loop over task-review,
  task-implement, and requirements-reviewer, and the self-test a rename
  of it in each of the three in turn (33 → 36 exit-1 mutations); the
  header describes it beside check 8's file-name note rather than in
  check 5's own paragraph. The scratch-clone acceptance check ran in a
  clone under this run's scratch directory (`scratch/task-implementer/2/clone`)
  rather than `$TMPDIR`, since the implementer writes nothing to a system
  temporary directory: with the new dispatch text deleted from
  task-implement, `check-canonical-dispatch.sh` exited 1; with item 5
  deleted from bug-reviewer, `check-review-agent-drift.sh` exited 1; both
  exited 0 on the unmutated clone. The clone is left in place.

Implement plan Step 3 (Technical Approach § Heavy commands across parallel
reviewers). Files: `plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`, the five review-angle
agents (`requirements-reviewer.md`, `edge-case-reviewer.md`,
`quality-reviewer.md`, `bug-reviewer.md`, `test-reviewer.md`), and
`scripts/check-run-contract.sh` (check 5) — eight files, the five agents
receiving one identical edit.

- The canonical dispatch block gains, before the dispatch: run the
  project's test commands once — the commands the project's instruction
  files give for the parts the change set touches, found as
  regression-verifier finds them — and write `RUN_DIR/suite-run.md`
  (each command, exit code, duration, log path under
  `RUN_DIR/scratch/orchestrator/`); then record the tree state
  (`git status --porcelain=v1 -uall` and a hash of
  `git diff HEAD --binary`) under `RUN_DIR/scratch/orchestrator/`. After
  the agent list, the comparison, made once all five have returned — a
  re-dispatched reviewer included — and before code-fixer is dispatched:
  a changed tracked file stops the review naming the files, with no
  restore; the stop asks one question — go on to code-fixer with the tree
  as the user then leaves it, or end the review here; in a session that
  cannot ask, the run ends with the files named; in an autopilot worker,
  the question goes to the main session (preamble § 1). A new untracked
  file stops nothing. Each rule carries its Why from the plan.
- Schema F's and Schema G's Next steps name a new untracked file the
  comparison found.
- The five reviewers' PREREQUISITES section gains one new item, identical
  in all five: with `RUN_DIR`, read `RUN_DIR/suite-run.md`, never run the
  project's full test command, run named test files and scratch mutation
  checks one command at a time; without `RUN_DIR`, as before.
- Check 5 names `suite-run.md` in both skills and
  `requirements-reviewer.md`.

**Acceptance criteria:**
- `bash scripts/check-all.sh` and `--self-test` green.
- In a scratch clone of the repository under `$TMPDIR`, deleting the new
  text from `task-implement/SKILL.md` makes `check-canonical-dispatch.sh`
  exit 1, and deleting the new item from `bug-reviewer.md` makes
  `check-review-agent-drift.sh` exit 1; the clone is left in `$TMPDIR`,
  never removed with a recursive `rm`.
- The dispatch block's no-ask sentence opens with "In a session that
  cannot ask (a system reminder to work without stopping), …".
- The dispatch block states that an unchanged tree — and a tree whose only
  change is a new untracked file — stops nothing and asks no question
  (joined-line read), so an interactive review gains no question in the
  ordinary case.

---

### Task 7: The rails hook judges redirection targets

**Status:** DONE

**Implementation notes:**
- Decisions: the scanner keeps an unquoted `>` in its word as the byte
  `\002`, so a `>` that was quoted, escaped, or in a heredoc body is never
  an operator, and the existing rm check is unchanged (it reads no `>`).
  Each word carries two flags, single-quoted text (target not judged) and
  double-quoted text (no `~` expansion, as in bash). The awk scan expands
  the leading `~`/`$HOME`/`${HOME}`/`$TMPDIR`/`${TMPDIR}` from the hook's
  environment, joins the JSON cwd, collapses `.`/`..`, dedupes, and
  prints the targets after the rm line; the shell then resolves each with
  the same `resolve()` and a new `in_roots()` the file-tool check now
  shares, so the redirection and file-tool checks are one root check. The
  shell splits the target list by parameter expansion rather than reading
  a heredoc, since bash 3.2 writes a heredoc to a temporary file and a
  failure there would judge no target. A `>&` is a duplication or a target
  not judged. The guard sets the hook's `$TMPDIR` to a fixture path for
  every fixture and lists it among the redirection fixtures' roots, so
  `$TMPDIR/..` lies outside every root on any machine (where TMPDIR sits
  under /tmp, the real one's parent would be a root).
- Changes/tradeoffs: the header's misses list now says "writes through
  Bash other than a redirection (cp, mv, tee, an interpreter's own
  writes)" and adds a relative target after a `cd` in the same command
  (read against the input's cwd); it also records a known false deny: a
  `>` inside `[[ ]]` or `(( ))` is judged as a redirection. The deny
  reason for a redirection is its own sentence ("this Bash call redirects
  output outside the rails' write roots") with the file tools' route; the
  self-test's new seventh mutant replaces that deny and turned 5 fixtures
  red. The timed fixture measured 0.112 s. `fx_timed` gained optional
  reason and roots arguments. Not in this task's files: the autopilot
  skill's § The driver still says the hook "misses … writes through Bash";
  Task 8 edits only preamble § 3 there, so that sentence is left for the
  Doc-sync pass or a follow-up.

Implement plan Step 4, its redirection part (Technical Approach § Rails,
"The hook judges redirection targets"). Files:
`plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh` (scanner and
header), `scripts/check-autopilot-rails-hook.sh` (fixtures, a self-test
mutant).

- In a marked worker, a Bash redirection — `>`, `>>`, `>|`, `&>`, `&>>`,
  and the same with a leading file-descriptor number — whose target, after
  expanding a leading `~`, `$HOME`, `${HOME}`, `$TMPDIR`, or `${TMPDIR}`
  and collapsing `.` and `..` as written (relative targets against the
  input's cwd), lies outside every write root is denied by the same root
  check the file tools get, the reason naming the same route. A target
  holding any other expansion, a command substitution, or a glob is not
  judged; `/dev/null`, `/dev/stdout`, `/dev/stderr`, `/dev/tty`, and
  `/dev/fd/<n>` are allowed; a duplication such as `2>&1` is not a
  target; a `>` inside quotes or a heredoc body is not a redirection.
- The header's description gains the redirection rule, and its misses
  list keeps `tee`, `cp`, `mv`, and interpreter writes and drops
  redirections.
- Fixtures, in the live hook-input format the guard already copies:
  denied — `> "$TMPDIR/../x"`, `>> ~/.claude/x`, `2> /etc/x`,
  `&> ../outside` from the repository root; allowed — `> /dev/null`,
  `2>&1`, `> "$TMPDIR/x"`, `> out.txt` in the repository, `> "$OTHER/x"`,
  `echo 'a > /etc/x'`, a heredoc body holding `> /etc/x`; a timed fixture:
  8000 redirections `>a ` (about 24 KB, under the 64 KB cap) then
  `> /etc/x`, denied in under 2.5 seconds under the guard's CPU limit;
  every denied fixture again without the marker and with the marker `0`
  (inert). A new self-test mutant removes the redirection check.

**Acceptance criteria:**
- `check-autopilot-rails-hook.sh` passes; its self-test passes, the new
  mutant turning it red.
- The timed fixture's measured time is under 2.5 seconds.
- `bash scripts/check-all.sh` and `--self-test` green.

---

### Task 8: The rails hook denies `gh` and remote git; preamble § 3

**Status:** DONE

**Implementation notes:**
- Decisions: the gh and git checks sit in the scanner's existing `check()`
  at the command word the wrapper skipping leaves (so `sudo gh …` and
  `xargs gh …` are read too), and mark their result with the byte `\003`
  so the shell tells a remote call from a recursive rm and denies it with
  its own route, `REASON_ASK` ("ask the main session by a question
  message … this denial is not a breach, so list it under
  ## Rail observations and go on"). `command -v`/`-V` ends the check for
  that command, since it names a command without running it; `type` and
  `which` pass because their command word is not gh. A clone's source is
  the first word after `clone` that is not an option or the argument of
  a clone option that takes one (`-b`, `-o`, `-c`, `-u`, `-j`, `--depth`,
  `--branch`, …). The guard gained a `deny-ask` expectation (the reason
  names the main session, and neither `.trash` nor the no-route text).
- Changes/tradeoffs: beyond the listed forms, `git remote update` and a
  clone with options before its URL are denied too (probed). A clone of
  `file://…` is denied, since it holds `://`, as the spec's URL rule reads.
  The self-test's eighth mutant disables the gh check and must turn the
  "gh issue view" fixture red first. Preamble § 3's new sentence names
  "No GitHub and no remote git", the commands, and the route; its Why sits
  with the other § 3 reasons after the template.

Depends on: Task 7

Implement plan Step 4, its GitHub and remote-git part and its preamble
bullet (Technical Approach § Rails, "The hook denies GitHub and remote
git"). Files: `plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh`
(scanner and header), `scripts/check-autopilot-rails-hook.sh`,
`plugins/kenspc/skills/autopilot/SKILL.md` (preamble § 3 and its Why).

- At a command position, `gh` is denied; `command -v gh`, `type gh`, and
  `which gh` are allowed. `git` — its global options `-C <path>`,
  `-c <name>=<value>`, `--git-dir=…`, `--work-tree=…`, `--no-pager`
  skipped — is denied with the subcommand `fetch`, `pull`, `push`,
  `ls-remote`, or `remote update`, or `clone` whose source is a URL (it
  holds `://`, or is `<user>@<host>:<path>`); a `git clone` of a local
  path is allowed. The reason's route: ask the main session, which gets
  anything the work needs from GitHub.
- The header's list of what the hook denies with the marker set gains the
  `gh` and remote-git denials and their allowed forms.
- Fixtures: denied — `gh issue view 1`, `git -C . fetch`, `git push`,
  `git clone https://example.test/r.git d`,
  `git clone git@example.test:r.git d`; allowed — `git clone /local/repo d`,
  `git status`, `grep gh f`, `command -v gh`, `which gh`; every denied
  fixture again without the marker and with the marker `0` (inert). A new
  self-test mutant removes the `gh` check.
- Preamble § 3 names GitHub and remote git and the route, with its Why
  (a denial is not a breach; the hook reaches a subagent that never saw
  the preamble).

**Acceptance criteria:**
- `check-autopilot-rails-hook.sh` passes; its self-test passes, the new
  mutant turning it red.
- Joined-line grep finds `ask the main session` in the hook's reason and
  `remote git` in preamble § 3.
- `bash scripts/check-all.sh` and `--self-test` green.

---

### Task 9: Benign breaches ruled by the main session

**Status:** TODO

Implement plan Step 5 (Technical Approach § Rails, "Benign breaches ruled
by the main session"). File: `plugins/kenspc/skills/autopilot/SKILL.md`
(a new subsection `### A breach the main session rules benign`, placed
after § How the main session rules; § The state file; stop condition 6;
the reviewer report and the user report; § The gates).

- The three conditions (no secret written or sent; not a recursive `rm`,
  a push, a tag, or a release; no state changed outside the write roots,
  or only a file holding no secret, which the main session moves into the
  workspace's `.trash/`); the record under a new state-file section
  `breaches ruled:`; the resume under `<tag>-r<k>` with
  `answer <tag>: breach ruled benign — <one line>`, counted as a resume;
  the reviewer report's `Breaches ruled benign:` line and the user
  report's list; stop condition 6 narrowed to a breach the main session
  cannot rule benign.
- The subsection states that a benign-breach ruling is also recorded as
  every other ruling is — under `questions answered:`, marked
  `(main session)`, and as a clarification entry in the spec naming the
  main session as the ruler — in addition to `breaches ruled:` and the
  report line.
- § The gates' table reflects the narrowed stop condition 6.

**Acceptance criteria:**
- `grep -q 'breaches ruled:'` and `grep -q 'Breaches ruled benign:'` on
  `SKILL.md` succeed.
- Stop condition 6 names the three conditions (joined-line read).
- The new subsection names the clarification entry and
  `questions answered:` as records of a benign-breach ruling.
- `bash scripts/check-all.sh` green.

---

### Task 10: `Standalone review: auto`

**Status:** TODO

Implement plan Step 6, its `auto` part (Technical Approach § S3b on a
condition in repo mode). File: `plugins/kenspc/skills/autopilot/SKILL.md`
(§ The `## Autopilot` section's table; § The start checks' `Standalone
review: off` bullet; the role table at the top and the paragraph after
it; Phase 2's goal and DONE line; § The verdict loop after S3b; § The
zero-diff check; Phase 3's inputs, DONE line, and Repo mode paragraph;
Phase 4's zero-diff paragraph; § Phase transitions; the S5 task block's
"a row of S3's review with `Standalone review: off`" source; the reviewer
report's Acceptance and `Sessions:` lines and the user report; the
settings line).

- `Standalone review:` takes `on`, `off`, or `auto`; `off` and `auto` are
  repo mode only, either in plugin mode a settings stop. With `auto`,
  after S3 returns, S3b runs when S3's Schema G verdict is FAIL, or
  PARTIAL for a reason other than BLOCKED tasks alone, or S3's review left
  a HIGH or MEDIUM row DEFERRED; otherwise S3's verdict enters the verdict
  loop as with `off`. The default stays `on`.
- Every sentence that ties S3b's absence to `Standalone review: off`
  (find them with `grep -n 'Standalone review' SKILL.md`) reads instead
  "when S3b does not run (`off`, or `auto` not triggered)"; the
  `Sessions:` line names the value and, for `auto`, that it was not
  triggered; the `none named; S3 is the last check` line is used whenever
  S3b did not run.
- The reviewer report gains `Standalone review: <value> — ran (<trigger>)`
  or `— not run (<reason>)`.

**Acceptance criteria:**
- The table's `Standalone review:` row reads `on`, `off`, or `auto`.
- Every line `grep -n 'Standalone review: off'` prints names `auto` in
  its sentence (checked by reading each, listed in the commit body).
- § Phase transitions names `auto`; reading it with `auto` and a
  PASS-and-nothing-deferred S3 reaches Phase 3 without S3b, and with a
  deferred MEDIUM reaches S3b (recorded in the commit body).
- `bash scripts/check-all.sh` green.

---

### Task 11: BLOCKED tasks classified in the verdict loop

**Status:** TODO

Depends on: Task 10

Implement plan Step 6, its BLOCKED part (Technical Approach § A task S3
leaves BLOCKED). File: `plugins/kenspc/skills/autopilot/SKILL.md`
(§ The verdict loop after S3b; the S5 task block; the reviewer and user
reports).

- At S3's return the main session reads every task's status from the
  committed task document, whatever the switch. Each BLOCKED task is
  classified as a HIGH row is: an S5 that implements it — its task block
  quoting the task and its BLOCKED note — or a deferral recorded as a
  clarification naming who ruled; a block needing a change outside the
  batch's contract is stop condition 7 (a). Written once, in § The verdict
  loop after S3b, covering `on`, `off`, and `auto`.
- The S5 task block gains the form for a BLOCKED task.
- Both reports name each BLOCKED task and its classification.

**Acceptance criteria:**
- § The verdict loop after S3b names BLOCKED tasks and both
  classifications (joined-line read).
- The S5 task block holds the BLOCKED-task form.
- The reviewer report template and the user report each name BLOCKED
  tasks.
- `bash scripts/check-all.sh` green.

---

### Task 12: Walk settings, tags, and the start check

**Status:** TODO

Depends on: Task 1, Task 10

Implement plan Step 7, its settings part (Technical Approach § The
runtime walk, "A session after S4", "The field `Walk:`", "The browser
tool"). File: `plugins/kenspc/skills/autopilot/SKILL.md` (the role table
at the top: an S4w row; the `## Autopilot` table: `Walk:` and `Role
settings:`; § The workspace: `_logs/<batch>-walk/`; § The batch name, the
tags, and the main session's name: `-s4w` and its re-runs, S4's re-run
letters skipping `w`; § Launch, wait, return: `-s4w` and `-s4w<letter>`
read as S4w before `-s4<letter>`; § The start checks; § The state file:
the walk's record).

- `Walk:` takes `on` (the default in repo mode), `off`, or sub-bullets of
  flows with what must be seen; in plugin mode the default is `off`, and
  `on` or sub-bullets is a settings stop. `Role settings:` accepts `S4w`.
- The start check: when `Walk:` is not `off` in repo mode, the main
  session checks Claude in Chrome first, then the Playwright MCP, with the
  check commands Task 1's record gives (Playwright alone when the record
  shows a headless worker cannot use Claude in Chrome); neither usable is
  a stop before the first launch naming both outputs and `Walk: off` as
  the way on, with the no-ask sentence.
- The skill names the tool "Claude in Chrome" in prose. Its MCP
  identifier (`claude-in-chrome`, as in `mcp__claude-in-chrome__*` tool
  names) holds `claude-` followed by a letter, which
  `check-no-model-names.sh` rule 3 reports as a model ID in any file under
  `skills/`. When a check command from Task 1's record, or a rule of
  Task 13's S4w block, cannot be written without that identifier, mark the
  task BLOCKED (`the walk check needs the claude-in-chrome identifier,
  which check-no-model-names.sh rejects; an exclusion is outside the
  plan's files`) and quote the command, rather than adding an exclusion to
  the guard or spelling the identifier around the rule.

**Acceptance criteria:**
- The table holds `Walk:` with its three forms and `S4w` in
  `Role settings:`.
- § Launch, wait, return reads `-s4w` and `-s4wb` as S4w and `-s4b` as S4
  (joined-line read, quoted in the commit body).
- § The start checks holds the tool check with the commands from Task 1's
  record.
- `check-no-model-names.sh` and `bash scripts/check-all.sh` green.

---

### Task 13: The walk session's flow

**Status:** TODO

Depends on: Task 11, Task 12

Implement plan Step 7, its flow part (Technical Approach § The runtime
walk, "What S4w must respect", "Its record and its failures", "Budget").
File: `plugins/kenspc/skills/autopilot/SKILL.md` (Phase 3; Templates
§ The task blocks: an S4w block, and the S5 block naming a walk FAIL
among its sources; § The stop conditions' list of stops stated at their
own steps; § The gates; § Budget and caps; the reviewer and user reports;
§ Phase transitions).

- S4w runs once S4's FAILs are classified and their re-runs have passed,
  or after the `Acceptance: none` record.
- The S4w task block: local URLs only, never staging or production; in
  Claude in Chrome, tabs of its own, the user's other tabs never read,
  used, or closed; the app started as the project's instruction files and
  the spec say, its local resources named as the run's resources; data by
  the project's rule, else synthetic only; a test account's password read
  at run time inside the page or script, never in a tool call's input or a
  message; ports checked before a server starts, a port held by another
  process a question to the main session (wait — re-check every 10
  minutes, at most 60 — or skip, `not walked: port <n> in use`); only the
  processes it started stopped, by their listener
  (`lsof -ti tcp:<port> -sTCP:LISTEN`); an app it cannot start
  `not walked: <reason>`; `nothing to walk: <reason>` when the batch has no
  user interface; with `on`, the flows it chose listed; screenshots and
  `walk.md` under `<workspace>/_logs/<batch>-walk/`; the tool check again
  at its start, neither usable ending it with `walk tool unavailable`.
- A walk FAIL classified as Phase 3 classifies an acceptance FAIL: a
  defect → S5 → the narrowed review → an `-s4wb` re-run of the failed
  flows; a behavior deviation → a reviewer-report line; an observation →
  recorded; counted per defect.
- The stops stated at their own steps become seven, `walk tool
  unavailable` among them; § The gates lists it.
- Budget: the projection includes S4w; a failed budget check before S4w
  cuts it as an `(optional)` case is cut, recorded `walk: cut by budget`.
- § Phase transitions: Phase 3 → Phase 4 waits on S4w's reply with every
  FAIL classified, or the `off`, `nothing to walk`, `not walked`, or
  `cut by budget` record.
- Both reports gain a `Walk:` line; with `Acceptance: none` and a walk
  that walked, the reviewer report's Acceptance line reads
  `none named; S3b is the last review, the walk follows` (S3 likewise);
  otherwise it stays as it is. The state file's `Acceptance: none` record,
  written before S4w starts, is unchanged.

**Acceptance criteria:**
- The S4w task block holds the local-only, own-tabs, password, port, and
  listener rules (joined-line reads), and names the browser tool as
  Task 12 does, so `check-no-model-names.sh` stays green.
- The stops-at-their-own-steps paragraph says seven and names the walk
  tool's absence.
- § Phase transitions names the walk's records.
- `bash scripts/check-all.sh` green.

---

### Task 14: The driver flag for S4w, when one is needed

**Status:** TODO

Depends on: Task 1, Task 12, Task 13

Implement plan Step 7's driver part. Files, only when a flag is needed:
`plugins/kenspc/skills/autopilot/scripts/run.sh`,
`plugins/kenspc/skills/autopilot/scripts/run.ps1`, and
`plugins/kenspc/skills/autopilot/SKILL.md` (the S4w launch that sets the
variable).

When Task 1's record shows a headless worker needs no extra flag for the
tool order Task 12 wrote, change no file and mark this task DONE with the
note `no driver flag needed`, citing the record's line. Otherwise: each
driver passes the flag only for an S4w launch and its resumes, as an
environment variable the skill sets says; `SKILL.md`'s S4w launch sets
that variable; each driver's `--self-test` gains a launch with the
variable set, asserting the flag is passed, and one without it, asserting
it is not.

**Acceptance criteria:**
- No flag needed: `git diff --quiet -- plugins/kenspc/skills/autopilot/scripts/`
  exits 0 and the note cites Task 1's record.
- Flag needed: `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`
  and `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  pass, each with the two new launches; `bash scripts/check-all.sh` green.

---

### Task 15: Walk acceptance on a seed

**Status:** TODO

Depends on: Task 12-14

Implement plan Step 8. Output: `docs/dry-runs/batch-m-walk-acceptance.md`
(Setup, Cases, Findings, Observations, Not exercised, Summary), committed
alone (`docs: add batch m walk acceptance record`).

Run headless on a throwaway repo-mode seed under `~/Projects/_smoke/` (a
small web app on `127.0.0.1` with one page, a one-task spec that changes
that page, `Acceptance: none`, `Standalone review: off`), with this
checkout's plugin (`--plugin-dir`) in the main session. The workers run
the installed plugin (4.6.0); S4w's behavior comes from the preamble, the
task block, and the driver copy the main session takes from this
checkout. Cases:

1. `Walk: on` — S4w lists the flow it chose, `walk.md` and screenshots
   under the workspace, a PASS, the servers it started stopped and the
   port free after, no non-local URL in its trace, both reports' `Walk:`
   lines.
2. `Walk: off` — no S4w launched; the reports say `off`.
3. Neither tool usable (made so in the worker's own launch, as Task 1's
   record shows) — the run stops before the first launch with the start
   check's reason.
4. A port held by another process before S4w starts — S4w's question and
   the main session's ruling recorded.

**Acceptance criteria:**
- The record holds the four cases, each with its cost, and each case
  PASSes as written above; a case that FAILs is recorded with what was
  seen, and the task is marked BLOCKED naming the failed case.
- The total cost is at most USD 40; a case that would pass the cap is
  recorded under Not exercised with the spend so far, and the task is
  marked BLOCKED with the spend so far (Context).
- The seed and its workspace stay under `~/Projects/_smoke/`; nothing is
  deleted with a recursive `rm`.

---

### Task 16: Doc-sync

**Status:** TODO

Depends on: Task 1-15

Bring the documents below in line with what Tasks 1-15 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § Skills — the autopilot row: the walk session
  among the roles, and S3b skipped by `off` or an untriggered `auto`
  (Steps 6, 7).
- `plugins/kenspc/README.md` § Autopilot — the S4w role and `Walk:`, the
  `auto` value, BLOCKED classification, benign breaches, the second round
  in a worker's review, and the count of stops stated at their own steps
  (seven) (Steps 2, 5, 6, 7).
- `plugins/kenspc/README.md` § Run directory — `suite-run.md`,
  `schema-c-1.md`, the `## Round 2` section of `rulings.md`, and its copy
  of the entry grammar (the DEFER tail on FIX, and what happens to an entry
  outside the grammar) (Steps 2, 3).
- `plugins/kenspc/README.md` — the task-review description (the second
  round, the shared suite run, the tree check); § Agents (code-fixer's `F`
  rows and regression-verifier's `V` IDs); § Known behavior (the hook's
  redirection, `gh`, and remote-git denials and its remaining misses, the
  Claude in Chrome and Playwright order); and, only when Task 14 added a
  driver flag, the driver's description of its environment (Steps 2-4, 7).
- `CLAUDE.md` — the hook paragraph (redirections, GitHub, remote git); the
  autopilot sessions paragraph (S4w; `auto`); § Subagent Review
  Architecture's Parallel MapReduce paragraphs (the shared suite run and
  the tree check around Phase 1, the second round after Phase 3, the
  run-directory files the orchestrator now writes); § Maintenance note
  (the `canonical:second-round` block); § CONTEXT block contract (the files
  `suite-run.md`, `schema-c-1.md`, the round-2 section, the `F` and `V`
  IDs, and the `rulings.md` paragraph's copy of the entry forms, which
  gains the DEFER tail); § Non-Goals (the autopilot paragraph's "the three
  sessions hold whenever S3b runs", which now covers `auto`, and the walk
  session as a further role); § Repository scripts/ (the new checks in
  `check-run-contract.sh` and the new fixtures and mutants in
  `check-autopilot-rails-hook.sh`) (Steps 2-7).
- `plugins/kenspc/CHANGELOG.md` — a `## 4.7.0 — unreleased` heading with an
  entry for every step, the default-on walk and its start check named as a
  change to existing specs (Steps 1-8).
- `docs/release-checklist.md` — row 11's seed spec gains `Walk: off`; row
  14 gains a redirection outside the roots and a `gh` call, each denied
  live (Steps 4, 7).
- `docs/roadmap.md` — "S3b on a condition in repo mode" rewritten as the
  trial (five repo-mode batches with `auto`, follow-up issues compared by
  count and severity with the batches before 4.7.0, S3b back to `on` if
  HIGH or MEDIUM follow-ups rise); the items this batch settles stay until
  the release removes them (Step 6).

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-15. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-15 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
- `bash scripts/check-all.sh --self-test` prints `guards run: 13` and ends
  with `self-tests run: 12`, matching the release checklist's pinned
  counts; `claude plugin validate --strict .` and
  `claude plugin validate --strict ./plugins/kenspc` pass.
