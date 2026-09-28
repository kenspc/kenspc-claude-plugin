# Batch J — autopilot reliability (4.3.0) — Task Document

## Context

Tasks decomposed from `docs/plans/batch-j-autopilot-reliability.md` (the
spec). The batch makes an unattended autopilot batch finish on its own
evidence: the rails a worker obeys reach the subagents it dispatches — in
text always, and through a PreToolUse hook when the probes show Claude Code
allows it; task-implementer keeps its probes, copies, and mutants in the run
directory instead of the user's source; a gate a worker skips is caught
after the fact; and the plugin directory on every launch, a headless main
session's records, and the fix loop are each stated one way.

Related plan: `docs/plans/batch-j-autopilot-reliability.md`. The spec's
labels — J-L1 to J-L8 (Locked design, immutable), J-D1 to J-D7 (Design
decisions), J-P1 to J-P4 (probes), J-A1 to J-A8 (acceptance) — are pointers
in this document only and appear in no shipped file.

Constraints for every task:

- **Files.** Only the spec's `Allowed files:`; a file outside them is a
  forbidden file. The spec's `Zero diff:` paths stay untouched — among them
  `skills/diagnose-bug/`, `skills/prototype/`, `shared/`, `references/`,
  and every agent other than `task-implementer.md`.
- **Byte-identity.** The only byte-identity section this batch may edit is
  the `canonical:run-dir` block, changed identically in
  `skills/task-implement/SKILL.md` and `skills/task-review/SKILL.md`
  (Task 4). The canonical dispatch, verdict-shared, stats-line, and
  code-craft principle blocks, and the five reviewers' shared sections, stay
  as they are.
- **Language.** Everything written is English.
- **No model name** in any plugin file (`check-no-model-names.sh`); test
  values are placeholders.
- **Pointer rule.** After each task,
  `git diff -U0 <HEAD before the task> -- <the task's files> | grep -E '^\+.*J-[LDPA][0-9]'`
  prints nothing. Positive control, run first:
  `grep -cE 'J-[LDPA][0-9]' docs/plans/batch-j-autopilot-reliability.md`
  prints a number greater than 0.
- **Searches that must come back empty** each get a positive control — the
  same pattern run where it must hit — before the empty result counts.
- **Why prose.** Every new rule in a skill, agent, or script carries its
  Why, with evidence stated in its own words (what failed, on which
  command), never cited as a dry-run record.
- **Cannot-ask branch.** A new point where the autopilot skill stops to ask
  states, at that point, what a session that cannot ask does, opening with
  "In a session that cannot ask (a system reminder to work without
  stopping), …".
- **Fixed lines** (report fields, state-file sections, stop and finish
  lines) stay in English.
- **The hook decision.** Task 1 writes
  `<workspace>/batch-j-autopilot-reliability-probes/probes.md`, whose last
  line is the decision: `Decision: build the hook` or
  `Decision: no hook — <probe(s)> did not hold`. `<workspace>` is the
  workspace the preamble's § 3 names (the spec's `## Autopilot` sets no
  `Workspace:`, so `~/Projects/_smoke/`). A task or document entry marked
  **(hook built only)** is carried out only when that line reads
  `Decision: build the hook`. Otherwise the task changes no file, is marked
  DONE with the Implementation note `Not built: <the decision line>`, and
  commits this task document alone. Why DONE and not BLOCKED: a task whose
  `Depends on` names a task that is not DONE is blocked, so a BLOCKED
  conditional task would block the Doc-sync task, which must still run and
  record the no-hook outcome.
- **This run's own scratch.** This batch's implementer runs the plugin text
  from before the batch, which gives it no run directory. Every probe,
  copy, mutant, and scratch config it makes for these tasks goes under
  `$TMPDIR` or the workspace — never a `/tmp` path named directly — and a
  mutation check runs on a copy: no tracked file is edited, backed up, or
  restored to test it. No recursive `rm` in any spelling; starting over
  uses a new directory. A write that lands under `/tmp` anyway is listed in
  the task's Implementation notes.
- **Checks after each task.** `bash scripts/check-all.sh`, its exit status
  read on its own line, not through a pipe; a task that touches a driver
  also runs that driver's `--self-test`, and a task that touches `run.ps1`
  also its parse check:
  `pwsh -NoProfile -Command '$e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile("plugins/kenspc/skills/autopilot/scripts/run.ps1", [ref]$null, [ref]$e); if ($e.Count) { $e; exit 1 }'`.
- **Commit scope.** Each task's commit changes only the files the task
  names, plus this task document's status and notes.

Dependency note: Task 3 depends on Task 1; Task 5 on Task 4; Task 6 on
Tasks 1 and 3; Task 7 on Tasks 1, 3, and 6; Task 8 on Task 2; Task 9 on Tasks
1, 3, and 6; Task 14 (Doc-sync) on Tasks 1-13. Tasks 3, 6, 7, and 9 are
**(hook built only)**.

Coverage: Step 1.1 → Task 1; Step 2.1 → Task 2; Step 2.2 → Task 3;
Step 3.1 → Task 4; Step 3.2 → Task 5; Step 4.1 → Task 6; Step 4.2 →
Task 7; Step 5.1 → Tasks 8-13 (J-L1 Task 8, J-L4 Task 9, J-L3 Task 10,
J-L5 Task 11, J-L6 Task 12, J-L7 Task 13); Step 6.1 → Task 14.

## Tasks

### Task 1: Probe the hook mechanics

**Status:** DONE

**Implementation notes:**
- Decisions: probes.md is
  `/Users/kenspc/Projects/_smoke/batch-j-autopilot-reliability-probes/probes.md`;
  its decision line reads `Decision: build the hook` — all three probes held
  on Claude Code 2.1.283 in one probe session (run1). Deny form: exit status
  2 with the reason on stderr (chosen over the JSON `permissionDecision`
  output because a bash 3.2 script without `jq` then needs no JSON escaping
  of the reason); the denied subagent call's tool result reads
  `PreToolUse:Bash hook error: [...]: DENIED by probe hook: ...`, is_error
  true. The live JSON carries `agent_id` and `agent_type` on a subagent's
  call, and the file path fields are `tool_input.file_path` for Write and
  Edit and `tool_input.notebook_path` for NotebookEdit; saved as
  `json/Bash.json`, `json/Write.json`, `json/Edit.json`,
  `json/NotebookEdit.json` in the probes directory. Test variable
  `KENSPC_RAIL_PROBE_VAR`.
- Changes/tradeoffs: the probe hook denies on `deny-me` anywhere in its
  stdin JSON rather than in `tool_input` alone (no other field of the live
  JSON held it). The subagent was told to Read before Edit and NotebookEdit
  so the tools' read-first validation could not keep the hook from firing.
  Probe cost: USD 0.3777874 in one session (sum 0.3777874). No `rm` was run.
  A hook-script bug (a `printf` format starting with `--`) was found and
  fixed on a `$TMPDIR` copy before the probe session ran. Writes under
  `/tmp`: none by this task's commands; the probe session's own harness
  created `/private/tmp/claude-501/-Users-kenspc-Projects--smoke-batch-j-autopilot-reliability-probes`.

Spec Step 1.1 (J-L4). Writes only under
`<workspace>/batch-j-autopilot-reliability-probes/` (the probes directory);
no repository file changes except this task document.

- In the probes directory, a throwaway plugin: `.claude-plugin/plugin.json`,
  `hooks/hooks.json`, and a hook script. The hooks.json registers the
  script on PreToolUse with a matcher covering Bash, Write, Edit, and
  NotebookEdit — the tools the built hook will match — and quotes the
  plugin root in the command (`bash "${CLAUDE_PLUGIN_ROOT}/…"`). The script
  appends its stdin JSON and the value of a test variable (a name and a
  random value of the implementer's choosing) to a log in the probes
  directory, and denies any call whose tool input contains `deny-me`. The
  deny uses one form — exit status 2 with the reason on stderr, or the JSON
  `permissionDecision: "deny"` output — and probes.md names it. Task 6's
  hook uses the form this probe verifies.
- One probe session:
  `claude -p --plugin-dir <probe plugin> --permission-mode bypassPermissions --max-budget-usd 2 --output-format json`,
  with the test variable set in its environment and the probes directory as
  its cwd. Its prompt tells the main loop to make no tool call except one
  Agent call, with `run_in_background: false`, that dispatches a
  general-purpose subagent — why foreground: a background call returns at
  once and a headless session's exit stops it (CLAUDE.md, Subagent Review
  Architecture), so the subagent's calls would be missing for a reason that
  has nothing to do with hooks. The subagent: (a) runs
  `touch <probes dir>/deny-me-bash` with Bash; (b) writes
  `<probes dir>/deny-me-write` with the Write tool; (c) writes
  `<probes dir>/allowed.txt` with the Write tool; (d) edits `allowed.txt`
  with the Edit tool; (e) writes a minimal notebook with the Write tool and
  changes a cell of it with the NotebookEdit tool; then replies. (d) and (e)
  exist so that the live `tool_input` JSON of every tool the hook will
  match is saved, as the step requires. Running the probe session itself in
  the foreground within one Bash call, or in the background with the
  bounded wait loop, is the implementer's choice.
- Save the live stdin JSON of each matched tool from the log, one file per
  tool (for example `json/Bash.json`, `json/Write.json`, `json/Edit.json`,
  `json/NotebookEdit.json`). Tasks 6 and 7 build their inputs from them.
- Evidence, each quoted in probes.md:
  - J-P1 — the log holds the subagent's calls, each identified as the
    subagent's by a field of its JSON (an agent id or agent type) or, where
    the JSON carries none, by the probe session's main-loop transcript
    holding no such call.
  - J-P2 — `deny-me-bash` and `deny-me-write` are absent, `allowed.txt`
    exists, and the log shows both `deny-me` calls reached the hook.
  - J-P3 — the log carries the test variable's value in a subagent's call.
- A probe that cannot be shown to hold — the session refused or died, the
  budget ran out, the evidence missing — does not hold, and probes.md says
  why. The decision line is `Decision: build the hook` only when all three
  hold; otherwise `Decision: no hook — <probe(s)> did not hold`.
- probes.md holds: `claude --version`; one section per probe with its
  result and the log lines and file checks (`ls -l` or `test -e` output)
  that show it; the deny form; each probe session's `total_cost_usd` and
  their sum; the saved JSON files; the decision line last. Why the costs:
  the probe sessions are in no worker's JSON, so the main session adds them
  to spent from this file.
- At most USD 10 across all probe sessions, each capped at USD 2. No `rm`
  in any probe, and nothing in the probes directory is deleted; a rerun
  writes new files beside the old ones.

**Acceptance criteria:**
- probes.md exists and holds the Claude Code version; a section for each of
  J-P1, J-P2, and J-P3, each with at least one quoted log line or file-check
  output as its evidence; the deny form; the cost of each probe session and
  a sum of at most 10; and, as its last line, one of the two decision forms.
- The decision matches the results: `build the hook` if and only if all
  three probes hold.
- One saved JSON file per tool the probe session called, each parsed by
  `python3 -c 'import json,sys; json.load(open(sys.argv[1]))' <file>` with
  exit 0.
- `test -e` on `deny-me-bash`, `deny-me-write`, and `allowed.txt` now gives
  the results probes.md records.
- The task's Implementation notes name probes.md's path and quote its
  decision line.
- `git status --porcelain` after the commit is empty, and the commit changes
  only this task document.
- No Bash command in the task runs `rm`.

---

### Task 2: The drivers treat an empty `AUTOPILOT_PLUGIN_DIR` as unset, self-tested

**Status:** DONE

**Implementation notes:**
- Decisions: the four new cases use the same tags in both drivers, unused
  by either before — `selftest-s13` (fresh, empty), `selftest-s14` (fresh,
  set), `selftest-s1-r2` (resume, unset), `selftest-s1-r3` (resume, empty);
  the existing `selftest-s1` (fresh, unset) and `selftest-s1-r1` (resume,
  set) complete the six, and `selftest-s1-r1` gained its `--name <tag>`
  check before the flag checks so all six read their own `--name` first.
  The resumes go through each driver's command line, as `-r1` does. The
  launch code (`[ -n "${AUTOPILOT_PLUGIN_DIR:-}" ]`,
  `[string]::IsNullOrEmpty`) is unchanged.
- Changes/tradeoffs: mutation runs on `$TMPDIR` copies
  (`batch-j-t2-mutation-1/` for run.sh, `batch-j-t2-mutation-2/` for
  run.ps1): run.sh with `${AUTOPILOT_PLUGIN_DIR+x}` in place of
  `${AUTOPILOT_PLUGIN_DIR:-}` exited 1 with `self-test failed: …/selftest-s13.err
  shows --plugin-dir on a launch with AUTOPILOT_PLUGIN_DIR set to the empty
  string`, the unmodified copy passed (exit 0); run.ps1 with
  `$null -ne $env:AUTOPILOT_PLUGIN_DIR` in place of the
  `IsNullOrEmpty` test exited 1 with the same `selftest-s13` message, the
  unmodified copy passed (exit 0). pwsh 7.6.6 on this machine keeps a
  variable assigned the empty string (a child process sees `X=`), so the
  empty case is exercised there; run.ps1's comment keeps the existing note
  that an older pwsh that removes it makes the case the unset one again.
  Writes under `/tmp`: none.

Spec Step 2.1 (J-L1). Files: `plugins/kenspc/skills/autopilot/scripts/run.sh`,
`plugins/kenspc/skills/autopilot/scripts/run.ps1`.

- Both drivers already pass `--plugin-dir` only for a non-empty value
  (`[ -n "${AUTOPILOT_PLUGIN_DIR:-}" ]`; `[string]::IsNullOrEmpty`); that
  stays. Each header's Environment line for the variable says it is passed
  when non-empty and that the empty string counts as unset, worded as the
  `AUTOPILOT_MODEL` and `AUTOPILOT_EFFORT` lines are.
- Each self-test covers unset, empty, and set, on a fresh launch and on a
  resume through the command line — six cases. Today each covers unset on
  a fresh launch and set on a resume; the other four are new launches under
  tags neither self-test uses yet. Each case reads the launch's own
  `--name <tag>` in `.err` first, then asserts `--plugin-dir <value>` there
  when set and no `--plugin-dir` when unset or empty.
- The comment above `self_test()` in run.sh, and the one above
  `Invoke-SelfTest` in run.ps1, that lists the failures in order gains the
  new items.

**Acceptance criteria:**
- `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test` and
  `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  each print `self-test passed` and exit 0; run.ps1's parse check exits 0.
- Each self-test's stub `.err` shows, for the six cases: `--plugin-dir <value>`
  on the fresh and the resumed launch with the variable set; no
  `--plugin-dir` on either with it unset or the empty string.
- The checks can fail, shown on copies under `$TMPDIR`: in each driver,
  replacing the non-empty test with a test of whether the variable is set
  makes the self-test exit 1 naming an empty-string launch; the unmodified
  copy passes. The Implementation notes record both runs per driver.
- Both headers say the empty string counts as unset for
  `AUTOPILOT_PLUGIN_DIR`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 3: The drivers export the worker variables (hook built only)

**Status:** DONE

**Implementation notes:**
- Decisions: the roots separator is `|`, stated in both headers — no
  Windows path holds it, while `:` is in every drive letter (run.ps1 is
  written for Windows) and `;` may be in a file name. The roots are
  written as given, unresolved and in the order repository, workspace,
  `$TMPDIR`, `/tmp`, `/private/tmp` (for example
  `/var/folders/…/T/|/tmp|/private/tmp` — `$TMPDIR` keeps its trailing
  slash); resolving symlinks and trailing slashes is the hook's job. The
  repository entry comes from `git -C <cwd> rev-parse --show-toplevel`
  (git's own resolved path); no git, or a cwd outside a repository, adds no
  entry. `$TMPDIR` counts only when non-empty, as `AUTOPILOT_WORKSPACE`
  does. run.sh exports the two variables inside the worker's subshell;
  run.ps1 sets them in the inner script, just before the worker's call,
  through a new `__ROOTS__` literal.
- Changes/tradeoffs: the self-tests export `KENSPC_AUTOPILOT_WORKER=0` into
  their own environment for every launch and assert the marker `1` and the
  roots on four new or extended launches: `selftest-s15` (fresh, workspace
  set), `selftest-s16` (fresh, workspace empty, cwd a `git init`
  repository under the self-test directory: roots hold its top level),
  `selftest-s1-r1` (resume, workspace added), `selftest-s1-r4` (resume,
  workspace empty); an empty workspace must leave neither that path nor an
  empty entry (`||`). The built-in passing and failing stubs of both
  drivers write the two variables. The self-tests now need git (for the
  `git init`). Mutation runs on `$TMPDIR` copies (`batch-j-t3-mutation-1/`
  run.sh, `batch-j-t3-mutation-2/` run.ps1): with the marker's export
  removed each exited 1 with `…/selftest-s15.err does not show the marker
  KENSPC_AUTOPILOT_WORKER=1`; with the workspace entry removed each exited
  1 with `the roots in …/selftest-s15.err, KENSPC_AUTOPILOT_WRITE_ROOTS=…,
  do not hold …/workspace`; the unmodified copies passed (exit 0). Writes
  under `/tmp`: none.

Depends on: Task 1

Spec Step 2.2 (J-L4). Files: `plugins/kenspc/skills/autopilot/scripts/run.sh`,
`plugins/kenspc/skills/autopilot/scripts/run.ps1`.

- Both drivers set `KENSPC_AUTOPILOT_WORKER=1` and
  `KENSPC_AUTOPILOT_WRITE_ROOTS` in every worker's environment, on a fresh
  launch and on a resume, overwriting any value the caller's environment
  holds.
- The roots: the worker's repository (`git rev-parse --show-toplevel` run
  in the worker's cwd; no entry when that fails), `AUTOPILOT_WORKSPACE`
  when non-empty (the empty string counts as unset, as for the driver's
  other variables; no entry then), `$TMPDIR` when set, `/tmp`, and
  `/private/tmp`. The separator is the implementer's choice, stated in both
  headers; Task 6's hook reads the same separator.
- Each header lists `AUTOPILOT_WORKSPACE` in its Environment section and
  says what the driver exports, the roots, the separator, and why: the
  plugin's rails hook reads the two variables and acts only in a worker
  that carries the marker.
- The self-tests: the built-in stubs also write the two variables to
  stderr, and each header's description of a caller's own stub says so.
  Asserted on a fresh launch and on a resume: the marker reads `1` even
  when the caller's environment holds `KENSPC_AUTOPILOT_WORKER=0`; the roots
  hold the `AUTOPILOT_WORKSPACE` value when it is set and no workspace entry
  when it is the empty string; they hold `$TMPDIR`, `/tmp`, and
  `/private/tmp`; and one launch whose cwd is a git repository the
  self-test creates under its temporary directory (`git init`) holds that
  repository's top level.

**Acceptance criteria:**
- When probes.md decides no hook: the task is DONE per the hook-decision
  constraint, and neither driver changed.
- Otherwise: both self-tests print `self-test passed` and exit 0; run.ps1's
  parse check exits 0.
- The stub's `.err` shows the marker `1` and the roots described above on
  the fresh and the resumed launch.
- The checks can fail, shown on copies under `$TMPDIR`: removing the
  marker's export makes each self-test exit 1 naming the marker; removing
  the workspace entry makes it exit 1 naming the roots; the unmodified copy
  passes. The Implementation notes record the runs.
- The separator in both headers is the same.
- `bash scripts/check-all.sh` exits 0.

---

### Task 4: task-implement prepares the run directory before task-implementer

**Status:** DONE

**Implementation notes:**
- Decisions: the block moved into Phase 1 Step 4, retitled "Prepare the
  run directory and dispatch the implementer", rather than into a new step,
  so no step is renumbered (the all-BLOCKED path's "Phase 2 Step 4" and the
  "Step 3" batch-gate references stay valid). Step 4 states both Whys: after
  the confirmation, so a declined batch makes no `.gitignore` commit; and
  `mkdir -p <RUN_DIR>/scratch/task-implementer` before the dispatch,
  because the block leaves the directory to the first report written, while
  task-implementer's first write there may be a shell command such as `cp`,
  which does not create a missing directory. Phase 2 Step 1 is now
  "Construct the review CONTEXT block" and reuses Phase 1's `RUN_DIR`, with
  the Why that a second preparation would split one run's evidence across
  two directories. Phase 1's DONE list gained the prepared-and-created run
  directory.
- Changes/tradeoffs: inside the block only the opening sentence (the
  preparation comes before the first agent the run dispatches —
  task-implementer in `/kenspc-task-implement`, the review agents in
  `/kenspc-task-review` — and task-implementer keeps its probes, copies, and
  mutants there) and the Scratch space bullet's writer list
  (`scratch/task-implementer/`) changed; the bytes were copied into
  task-review/SKILL.md by script. The block's "need not exist — the first
  report written creates it" stays, true for task-review; task-implement's
  explicit creation lives outside the block. `check-run-contract.sh
  --self-test` still passes (its run-dir mutation targets `- Scratch space:`,
  kept). Writes under `/tmp`: none.

Spec Step 3.1 (J-L2). Files: `plugins/kenspc/skills/task-implement/SKILL.md`,
`plugins/kenspc/skills/task-review/SKILL.md`.

- task-implement: the run-directory preparation — the `canonical:run-dir`
  block — moves from Phase 2 Step 1 into Phase 1, after the batch
  confirmation (Step 3) and before the dispatch (Step 4), so a declined
  batch makes no `.gitignore` commit. Phase 1 creates the directory before
  the dispatch (for example `mkdir -p <RUN_DIR>/scratch/task-implementer`),
  so that it exists before task-implementer's first tool call — the block
  itself says the directory need not exist. Step 2's CONTEXT block gains
  `- RUN_DIR: <absolute run directory>`, and Step 4 passes it.
- Phase 2 Step 1 reuses the RUN_DIR prepared in Phase 1 — no second
  run-id, no second preparation — and its review CONTEXT keeps `RUN_DIR`.
  The all-BLOCKED path is unchanged.
- The block changes only where task-implement's new use makes it wrong or
  incomplete: its opening sentence covers a preparation before the first
  agent the run dispatches, not only before the review agents; and the
  Scratch space bullet names task-implementer's `scratch/task-implementer/`
  beside the other writers. The same bytes go into task-review/SKILL.md.
  The bullet labels `RUN_DIR:`, `Scratch space:`, and `Ignore check:`, the
  Scratch space bullet's naming and numbered-attempt rules, and the Ignore
  check's `check-ignore -q` command stay as they are. Why: diagnose-bug and
  prototype, which this batch may not touch, point at those bullets and
  that rule by name, and `check-run-contract.sh` runs that command.
- Nothing in task-implement asks for, or allows, a write under `/tmp`.

**Acceptance criteria:**
- `bash scripts/check-run-contract.sh`, `bash scripts/check-canonical-dispatch.sh`,
  and `bash scripts/check-verdict-shared.sh` each exit 0.
- `git diff <HEAD before the task> -- plugins/kenspc/skills/task-review/SKILL.md`
  changes only lines between the `canonical:run-dir` markers.
- In task-implement/SKILL.md, the line of `<!-- canonical:run-dir:start -->`
  comes before the line of the dispatch's ``Agent name: `task-implementer` ``;
  the Step 2 CONTEXT block holds `TASK_FILE` and `RUN_DIR`; Phase 1 says the
  directory is created before the dispatch.
- Phase 2 Step 1 names the RUN_DIR from Phase 1 and holds no run-id rule of
  its own.
- The block still holds `- RUN_DIR:`, `- Scratch space:`, `- Ignore check:`,
  and `check-ignore -q`, and its Scratch space bullet names
  `scratch/task-implementer/`.
- `grep -n '/tmp' plugins/kenspc/skills/task-implement/SKILL.md` prints no
  line that asks for or allows a write there (positive control: the same
  grep over `docs/release-checklist.md` prints lines).
- `bash scripts/check-all.sh` exits 0.

---

### Task 5: task-implementer's scratch convention

**Status:** DONE

**Implementation notes:**
- Decisions: the new section is `SCRATCH SPACE`, placed after QUALITY
  CHECKLIST (whose failing-capable test rule the mutation check serves) and
  before STUCK HANDLING. It references the Scratch space bullet by the
  block's two markers and the file path, and the three-step rule by the
  RUN_DIR bullet of `${CLAUDE_PLUGIN_ROOT}/agents/regression-verifier.md`,
  without restating either. The missing-`RUN_DIR` refusal is folded into
  PREREQUISITE CHECK item 1 with one message naming both keys, so the
  numbering of items 2-6 stays; the frontmatter description names the
  RUN_DIR requirement too.
- Changes/tradeoffs: the section names the concrete forms J-A1 checks
  (`sed -i` on, `cp` over, `.bak`/`.orig` copy of a tracked file). It says
  nothing of scratch space goes into a system temporary directory, with the
  Why that such a probe has stopped an unattended run whose rails allow no
  write there; it does not mention the harness scratchpad, since the task
  forbids allowing any write under `/tmp` and the scratchpad lies there.
  Writes under `/tmp`: none.

Depends on: Task 4

Spec Step 3.2 (J-L2). File: `plugins/kenspc/agents/task-implementer.md`.

- CONTEXT YOU WILL RECEIVE: two keys, `TASK_FILE` and `RUN_DIR` — the
  absolute path of the run directory task-implement prepared.
- PREREQUISITE CHECK: a CONTEXT without `RUN_DIR` is refused the way a
  missing `TASK_FILE` is, pointing at `/kenspc-task-implement`.
- A section of its own (an ALL-CAPS header with no hyphen, per the
  writer-agent header convention) states:
  - every probe, copy, mutant, and runner config the agent writes goes
    under `RUN_DIR/scratch/task-implementer/`, in one numbered subdirectory
    per attempt from the first, under the naming and numbered-attempt rules
    of the Scratch space bullet of the `canonical:run-dir` block in
    `${CLAUDE_PLUGIN_ROOT}/skills/task-implement/SKILL.md` — referenced by
    the block's markers, not copied; starting over takes the next number,
    never a delete;
  - a mutation check runs on copies there, under the three-step rule of the
    RUN_DIR bullet in `${CLAUDE_PLUGIN_ROOT}/agents/regression-verifier.md`
    — referenced, not copied; a copy holds what the check needs, not the
    whole project, as the review agents' copies do (the spec's Risks:
    copies for mutation checks in large projects);
  - the agent never edits, backs up, or restores a tracked file to test it;
    its implementation edits are the only writes it makes to tracked files.
    Why, in its own words: a mutation made in place on the user's source
    and restored afterwards leaves the source mutated when the run stops
    between the two.
- The CODE-CRAFT PRINCIPLES blocks and their guard comment stay as they are.
- Nothing in the file asks for, or allows, a write under `/tmp`.

**Acceptance criteria:**
- The file names `RUN_DIR/scratch/task-implementer/` and
  `agents/regression-verifier.md`.
- Its CONTEXT section lists exactly `TASK_FILE` and `RUN_DIR`, the keys
  task-implement's Step 2 CONTEXT block holds after Task 4.
- It states that no tracked file is edited, backed up, or restored to test
  it.
- The new section header matches `^[A-Z ]+$`.
- `grep -n '/tmp' plugins/kenspc/agents/task-implementer.md` prints no line
  that asks for or allows a write there (positive control as in Task 4).
- `bash scripts/check-code-craft-canonical.sh`,
  `bash scripts/check-no-model-names.sh`, `bash scripts/check-instruction-files.sh`,
  and `bash scripts/check-all.sh` each exit 0.

---

### Task 6: The rails hook (hook built only)

**Status:** DONE

**Implementation notes:**
- Decisions: deny form exit 2 with the reason on stderr (Task 1's verified
  form). The JSON is read by a small awk string extractor (first
  `"key":"…"` member, escapes decoded; a quote inside a JSON string is
  always escaped, so a key cannot match inside a value), and the `rm` rule
  by an awk shell tokenizer: quotes, backslashes, comments, separators
  (`;` `&&` `||` `|` `&` newline `(`), `$( )` and backtick substitutions
  (the enclosing command's words are set aside and restored), redirections
  (`2>&1`, `&>`, `>|` are not separators), and heredoc bodies, which are
  skipped — so the usual `git commit -m "$(cat <<'EOF' … EOF)"` message
  mentioning `rm -rf` is allowed. Beyond the listed wrappers (sudo,
  command, env, xargs, their options and option arguments skipped), shell
  keywords (`if then else elif do while until ! {`) and `exec`, `nohup`,
  `time` also pass the command position on, at no extra mechanism.
  `--rec` and other prefixes of `--recursive` count, as GNU rm accepts
  them; `--` ends the flag scan. Paths are resolved component by component
  (a `cd … && pwd -P` fork only for a symlinked directory); a target that
  is not POSIX absolute after the join with `cwd` (a Windows drive-letter
  path) is not judged, so a Windows worker is not denied every write; a
  file-tool target missing from the input is denied. The route text names
  both `.trash/<name>-<timestamp>/` and the repository / workspace /
  scratch, so every deny's reason contains `.trash`.
- Changes/tradeoffs: the inert path exits without reading stdin. A second
  probe session (`inert-probe/` in the probes directory, USD 0.6565836,
  added to probes.md's cost section, sum now USD 1.034371) showed Claude
  Code 2.1.283 tolerating a hook that exits without reading a 120108-byte
  input: exit 0, `subtype` success, no hook error in the transcript. Checked
  with a scratch runner (`$TMPDIR/batch-j-t6-hooktest/run_cases.py`, 105
  cases from the live JSON under `/bin/bash` 3.2.57, all as expected:
  without the marker a recursive-`rm` and an outside write give exit 0 and
  no output; with the marker they are denied, `grep -c 'rm -rf' f` and a
  write inside the repository are allowed). Timing: 0.13 s for a 1 MB
  Write input with the marker, 0.002 s inert. The header's known misses
  add `find -exec rm`, `eval`, rm through a variable or alias, other
  wrappers, an unquoted heredoc's substitutions, and non-POSIX paths to the
  five required. File mode 644, like the two existing hook scripts (run
  through `bash`). Writes under `/tmp`: none by this task's commands.

Depends on: Task 1, Task 3

Spec Step 4.1 (J-L4). Files: `plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh`
(new), `plugins/kenspc/hooks/hooks.json`.

- Registration: a PreToolUse entry whose matcher covers Bash and every
  file-writing tool — at least Write, Edit, and NotebookEdit — running
  `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/autopilot-worker-rails.sh"`,
  the plugin root quoted as in the two existing entries, with a timeout
  like theirs. The existing entries stay as they are; the file's
  `description` names the new hook.
- Inert — exit 0, no output — unless `KENSPC_AUTOPILOT_WORKER` is exactly
  `1`; the marker is read before anything else, since every Bash call in
  every session starts the hook.
- With the marker, it denies:
  - (a) a Bash command that runs `rm` with a recursive flag, at a command
    position — the start of the command, a line start in a multi-line
    command, or after `;`, `&&`, `||`, `|`, `$(`, a backtick, `xargs`,
    `sudo`, `command`, or `env` — in every flag spelling: `-r`, `-R`,
    `--recursive`, any bundle holding `r` or `R`, and flags split across
    words; with or without a path prefix (`/bin/rm`);
  - (b) a Write, Edit, or NotebookEdit whose target (the path field Task 1's
    live JSON shows for that tool) lies outside every root in
    `KENSPC_AUTOPILOT_WRITE_ROOTS`, read with Task 3's separator. The target
    is resolved against the JSON's `cwd` when relative, with `..` collapsed
    and the symlinks of its existing ancestors resolved; the roots are
    resolved the same way (`/tmp` → `/private/tmp`, `$TMPDIR` →
    `/private/var/…`). A target is inside a root only by whole path
    components: `<root>-other/f` is outside `<root>`. With the marker set
    and no roots, every file-tool write is outside them.
- Not denied: `rm` without a recursive flag; the text `rm -r…` inside a
  quoted argument of another command (`grep -c 'rm -rf' f`,
  `git commit -m "… rm -rf …"`, `echo "rm -r"`); any other tool.
- The deny uses the form Task 1's J-P2 probe verified. Its reason names the
  rail — no recursive `rm`, or a write outside the rails' roots — and the
  permitted route: `mv` into the workspace's `.trash/<name>-<timestamp>/`,
  or a write under the repository, the workspace, or scratch.
- The header comment states the purpose, the marker and the roots, the
  deny form, and the known misses — `find -delete`, `bash -c '…'`,
  interpreter-level deletes, `git clean`, and writes through Bash — as a
  best-effort guard behind the rails text, which still binds. Bash 3.2 (no
  associative arrays, no bash 4 expansions) and POSIX tools only, as
  `remind-plan-skill.sh` (no `jq`).

**Acceptance criteria:**
- When probes.md decides no hook: the task is DONE per the hook-decision
  constraint, and nothing under `plugins/kenspc/hooks/` changed.
- Otherwise: `bash scripts/check-json.sh` and
  `claude plugin validate --strict ./plugins/kenspc` exit 0; the hooks.json
  diff adds the new entry and changes the description, and nothing else.
- Run with `/bin/bash` (3.2.57 on this machine) and fed inputs built from
  Task 1's saved JSON: without the marker, a recursive-`rm` input and an
  outside-write input each give exit 0 with empty stdout and stderr; with
  the marker and roots set, the recursive-`rm` input and the outside-write
  input are denied, and a quoted-mention input and a write inside the
  repository are allowed — each decision read the way the deny form
  defines it. (The full fixture set is Task 7's.)
- A deny's reason contains `.trash`.
- The header lists the five misses.
- `bash scripts/check-all.sh` exits 0.

---

### Task 7: The hook's guard (hook built only)

**Status:** DONE

**Implementation notes:**
- Decisions: fixtures are one bash call each (`fx` / `fx_deny`), with the
  input built as compact JSON carrying the live input's keys and nesting
  (`session_id` … `effort.level` … `tool_input` … `tool_use_id`; the path
  in `tool_input.file_path`, or `tool_input.notebook_path` for
  NotebookEdit); denied fixtures are recorded in indexed arrays and
  replayed without the marker and with the marker `0`. The repository and
  workspace roots are paths under `/kenspc-rails-fixture` (which does not
  exist), so they resolve lexically and alike on every machine; `$TMPDIR`
  is the guard's own (the temp directory's parent when unset). Decisions
  are read as the deny form defines them (deny: exit 2, empty stdout, a
  reason on stderr — which must also contain `.trash`; allow / inert: exit
  0, empty stdout; inert also empty stderr). The input goes to the hook
  through a file, not a pipe, since the inert hook exits without reading
  it. JSON escaping is character by character in awk, not `gsub`, whose
  replacement backslash handling differs between awks. Temporary files are
  removed one by one with `rm -f` and `rmdir` — no recursive rm.
- Changes/tradeoffs: fixture labels by kind — rm spellings (denied): `-r`,
  `-R`, `--recursive`, bundles `-rf` `-fr` `-Rf` `-vfr`, split `-f -r`,
  path prefix `/bin/rm`; rm positions (denied): line start, after `;`,
  `&&`, `||`, `|`, `$(`, backtick, `xargs`, `sudo`, `command`, `env`;
  quoted mentions (allowed): `grep -c 'rm -rf'`, `git commit -m "… rm -rf
  …"`, `echo "rm -r"`, plus a heredoc commit message; rm without a
  recursive flag (allowed): `rm file`, `rm -f file`; for each of Write,
  Edit, NotebookEdit: inside the repository, the workspace, `$TMPDIR`,
  `/tmp`, `/private/tmp` (allowed), outside every root (denied), relative
  inside (allowed), relative `..` escape (denied), sibling sharing a root's
  prefix (denied); symlinked roots: `/tmp/…` against the driver's roots,
  a guard-made link as the only root with the target under its real
  directory, the reverse, and a sibling of the link's target (denied); no
  roots with the marker set (denied); every one of the 31 denied fixtures
  again with the marker unset and `0` (inert). Self-test output: mutant
  `rm-detection removed` turned 20 red, first `rm spelling -r`;
  `root-check removed` 11, first `Write outside every root`;
  `marker-check removed` 62, first `rm spelling -r (marker unset)`.
  `check-all.sh` prints `guards run: 12` and `--self-test` `self-tests
  run: 11`, both exit 0; the guard passes under `bash` and `/bin/bash`.
  Running `check-all.sh --self-test` (and `check-run-contract.sh
  --self-test` in Task 4) runs the other guards' EXIT traps, which
  `rm -rf` their own `mktemp -d` directories under `$TMPDIR` — a rail
  observation under the run's ruling 2. Writes under `/tmp`: none.

Depends on: Task 1, Task 3, Task 6

Spec Step 4.2 (J-L4). File: `scripts/check-autopilot-rails-hook.sh` (new).

- A guard like the others: a header stating what it checks and its exit
  codes (0 pass, 1 a decision differs, 2 a missing file or a stale
  fixture); `set -euo pipefail`; the other guards' SCRIPT_DIR / REPO_ROOT
  derivation; bash 3.2 (no `declare -A`); mutations by literal awk
  replacement, not `sed -i`. It runs the hook under `/bin/bash` when that
  exists, else `bash`.
- Fixtures carry the field names and nesting of Task 1's saved live JSON,
  copied into the guard; the guard reads nothing under the workspace. Each
  fixture gives the input, the environment (marker, roots — joined with
  Task 3's separator, in the form the driver writes them — and cwd), and
  the expected decision. They cover:
  - each `rm` spelling and position Task 6 lists, denied;
  - each quoted mention (`grep -c 'rm -rf' f`, `git commit -m "… rm -rf …"`,
    `echo "rm -r"`), allowed;
  - `rm file` and `rm -f file`, allowed;
  - a write inside each root — the repository, the workspace, `$TMPDIR`,
    `/tmp`, `/private/tmp` — allowed, for Write, Edit, and NotebookEdit;
  - a write outside every root, denied;
  - a relative path resolved against `cwd`, allowed inside and denied when
    a `..` escapes;
  - a symlinked root (`/tmp/…` against a root list that names it and its
    target as the driver writes them);
  - a sibling that shares a root's prefix (`<root>-other/f`), denied;
  - every denied fixture again without the marker, and with the marker `0`:
    exit 0, no output.
- `--self-test` in a temporary directory: the unmutated hook copy passes
  every fixture; three mutants — the `rm` detection removed, the root check
  removed, the marker check removed — each turn at least one fixture red,
  named in the output; the restored copy passes again. A mutation whose
  target text is not found is exit 2 (stale fixture), never a pass.
- `check-all.sh` picks the guard up without a change of its own.

**Acceptance criteria:**
- When probes.md decides no hook: the task is DONE per the hook-decision
  constraint, and no file under `scripts/` changed.
- Otherwise: `bash scripts/check-autopilot-rails-hook.sh` and
  `bash scripts/check-autopilot-rails-hook.sh --self-test` each exit 0, and
  so do both under `/bin/bash`.
- `bash scripts/check-all.sh` prints `guards run: 12`, and
  `bash scripts/check-all.sh --self-test` ends with `self-tests run: 11`,
  both exiting 0.
- The self-test's output names each of the three mutants with a fixture it
  turned red.
- Every fixture kind above is present; the Implementation notes list the
  fixture labels by kind.
- `grep -nE 'declare -A|mapfile|readarray' scripts/check-autopilot-rails-hook.sh`
  prints nothing (positive control: the same grep over a scratch file under
  `$TMPDIR` holding `declare -A x` prints a line).

---

### Task 8: SKILL.md — the plugin directory on every launch

**Status:** DONE

**Implementation notes:**
- Decisions: the launch bullet's environment list now names
  `AUTOPILOT_PLUGIN_DIR` with "(below)", and a paragraph of its own after
  the model-and-effort paragraph gives the rule (plugin directory in plugin
  mode, the empty string in repo mode, a resume as its tag) and two Whys:
  the inherited-variable reason the model and effort give, and the
  evidence in its own words (three repo-mode main sessions that inherited
  the variable read the plugin-mode-only text two ways — one launched with
  it empty and its workers ran the installed plugin, two passed the
  inherited directory on and theirs ran the working tree's skills). The S4
  task block tells S4 that every nested launch sets the variable on its
  line — the plugin directory, or the empty string for a run a case starts
  without it — since S4's own environment holds the plugin directory; the
  S4 bullet carries the Why.
- Changes/tradeoffs: the driver section's variable line now reads "when
  non-empty, --plugin-dir <value> (fresh launch and resume; the empty
  string counts as unset)", and its prose names `--plugin-dir` beside
  `--model` and `--effort`. The joined-lines check finds the former
  "`AUTOPILOT_PLUGIN_DIR=<plugin directory>` in plugin mode" in the old
  file (positive control) and nowhere in the new one.

Depends on: Task 2

Spec Step 5.1, J-L1. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- The launch bullet (Launch, wait, return): every launch sets
  `AUTOPILOT_PLUGIN_DIR` explicitly — the plugin directory in plugin mode,
  the empty string in repo mode — a resume as the tag it resumes; with the
  Why the model and effort variables give: a variable already in the main
  session's environment would otherwise reach the driver, and inherited,
  the earlier text was read two ways.
- The S4 plugin-mode task block: every nested launch sets
  `AUTOPILOT_PLUGIN_DIR` explicitly on its line, as the main session's
  launches do; its driver line keeps `AUTOPILOT_PLUGIN_DIR=<plugin directory>`.
- The driver section: `AUTOPILOT_PLUGIN_DIR` passes `--plugin-dir` when
  non-empty, the empty string counting as unset, matching run.sh's header
  after Task 2.

**Acceptance criteria:**
- The launch bullet names both modes' values for `AUTOPILOT_PLUGIN_DIR`, the
  empty string for repo mode among them, and the Why.
- The S4 block says every nested launch sets the variable explicitly.
- The driver section's `AUTOPILOT_PLUGIN_DIR` line says non-empty and that
  the empty string counts as unset.
- No sentence in SKILL.md still sets the variable for plugin mode alone
  (the launch bullet's former "`AUTOPILOT_PLUGIN_DIR=<plugin directory>` in
  plugin mode" is gone), read at every line
  `grep -n AUTOPILOT_PLUGIN_DIR plugins/kenspc/skills/autopilot/SKILL.md`
  prints together with the line its sentence continues on — the former
  phrase itself wraps between `<plugin` and `directory>`, so a grep for it
  finds nothing even before the task.
- `bash scripts/check-all.sh` exits 0.

---

### Task 9: SKILL.md — the workspace and the worker variables (hook built only)

**Status:** DONE

**Implementation notes:**
- Decisions: the launch bullet's environment list gains
  `AUTOPILOT_WORKSPACE=<workspace>`, with its rule and Why in a paragraph
  after the plugin-directory one (every launch, resumes included, the
  absolute path; the driver builds the write roots from it, and a marked
  nested main session writes its state file and prompts under the
  workspace). The S4 nested driver line carries `AUTOPILOT_WORKSPACE`
  on a line of its own. The driver section's variable block lists
  `AUTOPILOT_WORKSPACE` and the two exported variables in run.sh's terms,
  and its prose names the rails hook by path, its event and tools, the
  marker-only action, its two denials, its standing behind § 3, the five
  misses, and the Why (the preamble never reaches a worker's subagents; a
  plugin PreToolUse hook fires for their calls, and its deny holds in
  bypassPermissions).
- Changes/tradeoffs: none beyond the task.

Depends on: Task 1, Task 3, Task 6

Spec Step 5.1, J-L4. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- The launch bullet: every launch, resumes included, also sets
  `AUTOPILOT_WORKSPACE=<workspace>`, absolute. The S4 task block's nested
  driver line carries it too. Why: the driver builds the worker's write
  roots from it, and a marked nested main session writes its state file and
  prompts under the workspace.
- The driver section: lists `AUTOPILOT_WORKSPACE`, the two variables the
  driver exports to every worker — `KENSPC_AUTOPILOT_WORKER=1` and
  `KENSPC_AUTOPILOT_WRITE_ROOTS` with its roots — and that the plugin's
  rails hook reads them: in a marked worker it denies a recursive `rm` and
  a file-tool write outside the roots, a best-effort guard behind the
  preamble's rails, which still bind.

**Acceptance criteria:**
- When probes.md decides no hook: the task is DONE per the hook-decision
  constraint, and SKILL.md did not change.
- Otherwise: `grep -n AUTOPILOT_WORKSPACE` over SKILL.md hits the launch
  bullet, the S4 block, and the driver section; the driver section names
  `KENSPC_AUTOPILOT_WORKER` and `KENSPC_AUTOPILOT_WRITE_ROOTS`, and its
  variables match run.sh's header.
- `bash scripts/check-all.sh` exits 0.

---

### Task 10: SKILL.md — the rails text and the rail observations

**Status:** DONE

**Implementation notes:**
- Decisions: § 3 is rewritten as three paragraphs: the write locations
  (repository, workspace, `$TMPDIR`, the harness's per-session scratchpad),
  the `/tmp` observation, the breach rule with the recursive-`rm` rule and
  its `.trash` / `git rm` routes, and the kept rails (no push, tag, or
  release; no unnamed resource; no secrets); then the subagent paragraph
  (every subagent prompt composed, and `CUSTOM_INSTRUCTIONS` of the skills'
  agent dispatches); then "Any breach is a stop" on its own. The Why sits
  under the template, in its own words: a worker's subagents never see the
  preamble (an implementation worker's subagent wrote scratch files under
  `/tmp`, a nested run's subagent ran `rm -rf` on its own scratch
  directory), and a harmless `/tmp` scratch file has stopped an
  implementation worker and a nested acceptance run that a list would have
  recorded; the recursive `rm` stays a breach because what it deletes is
  recorded nowhere.
- Changes/tradeoffs: The return reads `## Rail observations` beside the
  timed-out-question check and records each entry, or `<tag>: none`, in a
  new state-file section `rail observations:`; the state file's
  description names it; the reviewer report gains
  `- Rail observations: <list | none>` after `Not exercised`, with a
  sentence saying it lists the section's non-`none` entries.

Spec Step 5.1, J-L3. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- The preamble template's § 3 states:
  - a worker may write to the repository, the workspace, `$TMPDIR`, and the
    harness's per-session scratchpad;
  - a write elsewhere under `/tmp` (on macOS `/private/tmp`) holding no
    secret is not a breach: the worker lists it under `## Rail observations`
    in its final message and goes on;
  - any other write outside those locations is a breach, and a recursive
    `rm` in any spelling stays a breach wherever it points;
  - the rails bind every subagent the worker dispatches: it writes them
    into every subagent prompt it composes, and into the
    `CUSTOM_INSTRUCTIONS` of the agent dispatches made by the skills it
    runs;
  - the rails § 3 already holds, kept: no push, tag, or release; no
    resource the brief does not name; no secrets; discard by `mv` into
    `.trash/`; deletions inside the repository only through `git rm`; a
    breach is a stop.
  With the Why beside the template: a worker's subagents never see the
  preamble, and a harmless scratch file under `/tmp` has stopped runs that
  a list would have recorded.
- The return: the main session reads the worker's result for
  `## Rail observations` and records each entry in the state file.
- The state file template gains a rail observations section, and the
  reviewer report template the line `- Rail observations: <list | none>`,
  built from it.

**Acceptance criteria:**
- The preamble template's § 3 holds `scratchpad`, `/private/tmp`,
  `## Rail observations`, `recursive`, `subagent`, and
  `CUSTOM_INSTRUCTIONS`, and still holds `git rm` and `.trash`.
- The reviewer report template holds `- Rail observations: <list | none>`;
  the state file template has the section; The return names
  `## Rail observations`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 11: SKILL.md — the check of a skipped gate

**Status:** DONE

**Implementation notes:**
- Decisions: the check is named "the skipped-gate post-check" and lives in
  § A worker's question at a gate, as a paragraph after the gate rubric it
  reuses; The return points at it for S2 and S3. "Sent no confirmation
  question" is read from the evidence the main session already keeps: no
  `question <tag>:` from S2's tag or its resumes, none in the state file's
  `questions answered:`. The Why for checking rather than preventing is the
  batch's own evidence in its words (a lowered-effort S2 skipped the
  confirmation though the preamble told it to ask, while pass-through S2s
  asked); the no-floor Why is that a floor is a plugin default and would
  not catch a skip at any effort. S3's skipped batch gate is recorded only,
  with the by-construction Why.
- Changes/tradeoffs: stop condition 7 names the post-check's mismatch or
  open choice; the gates table gains its row (asks the mismatch or the
  choice, quoted; cannot-ask: the run ends with it quoted); the state file
  gains `skipped gates:` (`<S2|S3> <tag>: <accepted as a behavior deviation
  | stop: … | recorded>`) and the reviewer report `- Skipped gates: <list |
  none>` with a sentence on how it is built. § Phase transitions' S2 → S3
  entry also names the post-check's match — an artifact-based transition
  like the others, beyond the task's letter.

Spec Step 5.1, J-L5. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- An S2 that returns without having sent its confirmation question — no
  `question <tag>:` carrying the task list's confirmation from S2's tag or
  its resumes: the main session applies the confirmation's own rubric
  (§ A worker's question at a gate: the task list matches the spec's steps
  and carries no choice the spec leaves open) to the committed task
  document. A match is accepted and recorded as a behavior deviation in the
  state file and the reviewer report. No match, or a choice left open, is
  a stop of stop condition 7's kind, with the mismatch or the choice
  quoted; in a session that cannot ask, the run ends with it.
- An S3 that returns without having asked the batch gate: recorded only.
  Why: once S2 has passed, the gate's answer is yes by construction.
- No effort floor for gate-carrying roles, with the Why: a floor per role
  would be a plugin default, and it would not catch a skip at any effort.
- The gates table gains the row for the post-check, and stop condition 7
  names it.
- The state file template gains a skipped-gates section, and the reviewer
  report template the line `- Skipped gates: <list | none>`, each entry
  naming the step, its tag, and the outcome.

**Acceptance criteria:**
- The return, or § A worker's question at a gate, states the post-check,
  its two outcomes, and the cannot-ask sentence opening
  "In a session that cannot ask (a system reminder to work without stopping),".
- S3's skipped batch gate is recorded only, with its Why; the no-floor Why
  is stated.
- The gates table has the post-check row; stop condition 7 names it.
- The reviewer report template holds `- Skipped gates: <list | none>`, and
  the state file template the section.
- `bash scripts/check-all.sh` exits 0.

---

### Task 12: SKILL.md — a headless main session's records

**Status:** DONE

**Implementation notes:**
- Decisions: the full rule and Why live in § The settings line, in a new
  paragraph after the launch-and-return-lines one (in a headless main
  session, as The wait path decides, the state file and the timeline are
  the record; nobody reads a headless reply as its steps happen, and two
  batches' headless main sessions left the settings and return lines out
  of their replies with nothing downstream missing them — the release
  checklist reads the state file and the timeline). Phase 0's DONE, the
  launch bullet, and the return bullet each state the interactive-only
  requirement and the headless record (the timeline's `start` / `end`
  line for the launch and return) with a short Why pointing there; the
  settings line is now "written" as the state file's first line and
  "printed" in an interactive session. § Phase transitions' Phase 0 entry
  names the state file as a headless session's artifact, with its Why.
- Changes/tradeoffs: the positive control (the perl program over
  `a002d69`'s file) printed passages from all five places; after the task,
  every printed passage that requires a line in the reply limits it to an
  interactive main session.

Spec Step 5.1, J-L6. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- Phase 0's DONE, the launch bullet, the return bullet, and § The settings
  line: the settings line and the launch and return lines are printed in
  the reply by an interactive main session; in a headless main session
  (The wait path decides which) the state file and the timeline are the
  record. Why: two batches' headless main sessions left those lines out of
  their replies, and nothing downstream reads the reply — the release
  checklist reads the state file and the timeline.
- § Phase transitions, whose Phase 0 entry reads "the settings line printed
  and the state file written": the printed line is an interactive main
  session's condition; in a headless main session the transition rests on
  the state file written. Why: otherwise a headless run that follows the
  four places above would miss the artifact this entry names.

**Acceptance criteria:**
- Every passage that requires printing the settings line or a launch or
  return line in the reply limits it to an interactive main session. The
  passages are found with the file's line breaks joined, since several of
  these sentences wrap across two lines and a line-by-line grep misses
  them:
  `perl -0777 -ne 's/\s+/ /g; while (/does not stand in|(?:this session.s|the|its) reply|settings line printed/g) { my $s = $-[0]; print substr($_, $s < 120 ? 0 : $s - 120, 200), "\n" }' plugins/kenspc/skills/autopilot/SKILL.md`
  — each printed passage that requires a line in the reply says the
  requirement is an interactive main session's. Positive control, run
  first: the same program over the file before the task
  (`git show <HEAD before the task>:plugins/kenspc/skills/autopilot/SKILL.md | perl -0777 -ne '<the same program>'`)
  prints passages from all five places — Phase 0's DONE, the launch bullet,
  the return bullet, § The settings line, and § Phase transitions.
- The four places above state that in a headless main session the state
  file and the timeline are the record, with the Why; § Phase transitions'
  Phase 0 entry names the state file as a headless main session's
  artifact.
- `bash scripts/check-all.sh` exits 0.

---

### Task 13: SKILL.md — the fix loop

**Status:** TODO

Spec Step 5.1, J-L7. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- The verdict loop after S3b and Phase 3's Classification: one S5 may fix
  several defects classified in the same round; every S5 is followed by the
  narrowed review (`-s3<letter>`, the next letter), over the range from HEAD
  at the S5's launch to its last commit, a wording-only fix included,
  before any re-run of a case.
- The S5 task block lists each defect with its case — its ID and run
  directory or case and record, its one line, the check to make pass — and
  asks for one commit per defect.
- Stop condition 4 counts per defect: the same defect still failing after
  two fixes of it. Phase 3's Classification states the same count — its
  sentence "The same case still failing after two fixes is a stop" counts
  per defect, as stop condition 4 does. Why: two counts, one per case and
  one per defect, would stop the same run at different points.

**Acceptance criteria:**
- The verdict loop and Phase 3's Classification both say an S5 is followed
  by the narrowed review before any case re-run, a wording-only fix
  included, and that one S5 may fix several defects of one round.
- The S5 task block lists each defect with its case and asks for one commit
  per defect.
- Stop condition 4 counts per defect, and so does Classification's
  two-fixes stop; no sentence in SKILL.md still counts the two fixes per
  case or per FAIL. Each such sentence is read in the output of
  `perl -0777 -ne 's/\s+/ /g; print "$&\n" while /[^.]{0,80}two fixes[^.]{0,40}/g' plugins/kenspc/skills/autopilot/SKILL.md`,
  which joins the file's line breaks (Classification's sentence wraps).
  Positive control, run first: the same program over the file before the
  task (`git show <HEAD before the task>:<path> | perl -0777 -ne '<the same program>'`)
  prints both "The same case still failing after two fixes is a stop" and
  "The same FAIL still failing after two fixes".
- `bash scripts/check-all.sh` exits 0.

---

### Task 14: Doc-sync

**Status:** TODO

Depends on: Task 1-13

Bring the documents below in line with what Tasks 1-13 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § Autopilot — the rails as the preamble now
  states them, with the `Rail observations` report line; the driver
  variables (`AUTOPILOT_PLUGIN_DIR` set on every launch, the empty string
  in repo mode; with the hook built, `AUTOPILOT_WORKSPACE` and the two
  exported variables); the skipped-gate check with the `Skipped gates`
  line; the headless records; the fix loop, and the Stops paragraph's
  stop 4 counted per defect (Steps 2.1, 2.2, 5.1).
- `plugins/kenspc/README.md` § Known behavior — with the hook built, its
  misses: `find -delete`, `bash -c '…'`, interpreter-level deletes,
  `git clean`, and writes through Bash; without it, that the rails reach
  subagents by text alone; and the entry on a headless run leaving the
  settings and return lines in the state file, restated as the headless
  records rule (Steps 4.1, 5.1).
- `plugins/kenspc/README.md` § Run directory — task-implementer's scratch:
  `task-implementer/` in the tree and in the bullet listing each agent's
  subdirectory, and the preparation made before task-implementer's
  dispatch in `/kenspc-task-implement` (Steps 3.1, 3.2).
- `CLAUDE.md` — the run-dir paragraph (§ Subagent Review Architecture: the
  scratch subdirectory per writer gains `scratch/task-implementer/`; § CONTEXT
  block contract: `RUN_DIR` required for task-implementer too); the hooks'
  runtime behaviour (the hooks paragraph under § Skill Development
  Conventions: the rails hook, when built — its event, matcher, marker,
  and inert path — and the paragraph's "Two hooks are registered" becomes
  three; two hooks are registered today, so the rails hook is the third,
  whatever count the spec gives); the guard and self-test counts
  (§ Repository scripts/: the new guard's bullet and its place among the
  guards with a `--self-test`, when built) (Steps 3.1, 3.2, 4.1, 4.2).
- `plugins/kenspc/CHANGELOG.md` — a `## 4.3.0 — unreleased` entry above
  4.2.0: what the batch changed, the probe results and the hook decision,
  and the guard counts (Steps 1.1-5.1).
- `docs/release-checklist.md` — the counts, wherever the checklist pins
  them, as `check-all.sh` prints them; with the hook built, a smoke line
  for it; and the run-directory check's list of scratch subdirectories
  gains task-implementer's, for row 6 (Steps 3.2, 4.1, 4.2).
- `docs/roadmap.md` — remove the items on the headless printed lines, the
  lowered-effort gate skip, the inherited `AUTOPILOT_PLUGIN_DIR`, and the
  rails that do not reach subagents, and the task-implementer paragraph of
  the scratch convention follow-ups item, renumbering the rest; add, with
  no hook, an item naming the failed probe and its evidence from probes.md,
  or, with the hook built, an item for the Windows bash gap — whether a
  worker `run.ps1` starts on Windows can run a bash hook, not probed in this
  batch (Steps 1.1, 5.1).
- `README.md` (root) — changed only if a skill's summary row changes;
  otherwise untouched (Step 5.1).

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-13. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-13 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
- The release checklist's pre-flight block exits 0, and the counts in
  CLAUDE.md and the release checklist equal the `guards run:` and
  `self-tests run:` lines `bash scripts/check-all.sh --self-test` prints.
- `git grep -nE 'J-[LDPA][0-9]' -- plugins scripts CLAUDE.md README.md docs/release-checklist.md docs/roadmap.md`
  prints nothing (positive control: the same pattern over the spec prints
  lines).
