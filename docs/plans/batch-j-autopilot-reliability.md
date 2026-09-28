# Batch J — autopilot reliability (4.3.0)

## Objective

Make an unattended autopilot batch finish on its own evidence. The rails a
worker obeys reach the subagents it dispatches — in text always, and
mechanically where Claude Code allows it; task-implementer stops testing
on the user's source; a gate a worker skips is caught whatever its effort;
and the driver's plugin directory, a headless main session's records, and
the fix loop are each stated so that no run reads them two ways.

## Background

- **Rails do not reach subagents** (roadmap: "A worker's rails do not reach
  the subagents it dispatches"). The rails live in the preamble's § 3, which
  a worker's subagents never see. In batch I
  (`docs/dry-runs/batch-i-acceptance.md`, Observations), S3's
  task-implementer subagent wrote four scratch files to `/tmp` and S3
  stopped on it; in nested case 3, regression-verifier wrote
  `/tmp/rv-npm-test.txt` and the nested run stopped; in nested case 6, a
  subagent ran `rm -rf` on its own `/tmp` scratch directory twice. The
  user's batch-I ruling — a scratch file under `/tmp` holding no secret is
  an observation — lived only in that batch's prompts; the shipped § 3 is
  unchanged.
- **task-implementer has no scratch convention** (roadmap: "Scratch
  convention follow-ups", its task-implementer paragraph). The
  `canonical:run-dir` block gives the reviewers, code-fixer, and
  regression-verifier `RUN_DIR/scratch/<writer>/`; task-implementer runs
  before the run directory exists, and in batch A it ran mutation checks on
  the project's own `src/` in place (`sed -i`, backups in the scratchpad,
  `cp` to restore). The maintainer ruled on 2026-09-25
  (`docs/dry-runs/scratch-probes-acceptance.md` § 6) that logs and helper
  scripts may go to the harness's per-session scratchpad, while probes,
  copies, mutants, and runner configs belong under `RUN_DIR/scratch`.
- **A lowered effort skipped a gate** (roadmap: "A worker at a lowered
  effort skipping a skill's gate"; batch I F3): an S2 declared `low` skipped
  generate-task's confirmation and sent no question; the S2 workers at the
  pass-through effort asked.
- **An inherited `AUTOPILOT_PLUGIN_DIR`** (roadmap: "A repo-mode autopilot
  leaves an inherited `AUTOPILOT_PLUGIN_DIR` to its driver"; batch I F2):
  three nested repo-mode main sessions read the skill two ways.
- **Headless printed lines** (roadmap: "Autopilot's printed lines in a
  headless main session"; batch I F1, batch F F1): headless main sessions
  wrote the settings line and the `S<n> returned —` lines only to their
  state files; the release checklist already reads the state file and the
  timeline.
- **The fix loop in batch I**: one S5 fixed six defects, and two
  wording-only fixes had no narrowed review after them. The S5 template
  covers one classified defect, its case, and its own commit.

## Locked design

Immutable for this batch.

- **J-L1 — the plugin directory on every launch.** Every launch sets
  `AUTOPILOT_PLUGIN_DIR` explicitly: the plugin directory in plugin mode,
  the empty string in repo mode — the rule `AUTOPILOT_MODEL` and
  `AUTOPILOT_EFFORT` already follow, for the same reason. `run.sh` and
  `run.ps1` pass `--plugin-dir` only for a non-empty value. A nested launch
  that S4 makes follows the same rule.
- **J-L2 — task-implementer's scratch.** task-implement prepares its run
  directory as the `canonical:run-dir` block prescribes before it
  dispatches task-implementer, passes `RUN_DIR` in that dispatch, and
  reuses the same directory in Phase 2. task-implementer writes every
  probe, copy, mutant, and runner config under
  `RUN_DIR/scratch/task-implementer/`, under the block's naming and
  numbered-attempt rules. A mutation check runs on copies there, under the
  three-step rule stated in `agents/regression-verifier.md`'s RUN_DIR
  bullet (referenced, not copied). task-implementer never edits, backs up,
  or restores a tracked file to test it; its implementation edits are the
  only writes it makes to tracked files.
- **J-L3 — the rails text (preamble § 3).**
  - A worker may write to the repository, the workspace, `$TMPDIR`, and the
    harness's per-session scratchpad.
  - A write elsewhere under `/tmp` (on macOS `/private/tmp`) holding no
    secret is not a breach: the worker lists it under
    `## Rail observations` in its final message and goes on, and the main
    session carries the list into the reviewer report on a new line
    `Rail observations: <list | none>`.
  - Any other write outside those locations is a breach. A recursive `rm`
    in any spelling stays a breach wherever it points.
  - § 3 tells the worker that its rails bind every subagent it dispatches:
    it writes them into every subagent prompt it composes, and into the
    `CUSTOM_INSTRUCTIONS` of the agent dispatches made by the skills it
    runs.
- **J-L4 — a mechanical rail, conditional.** Step 1.1's probes decide it,
  on the Claude Code version installed at the run:
  - J-P1: a plugin's PreToolUse hook fires for a tool call a subagent
    makes, in a `claude -p --permission-mode bypassPermissions` session;
  - J-P2: the hook's deny stops that call;
  - J-P3: the hook's process sees environment variables the driver set on
    the worker.
  - All three hold → the hook is built (Phase 4). Any one fails → no hook;
    J-L3 is the whole rail, and the roadmap gains an item naming the failed
    probe and its evidence.
  - J-P4, recorded only: whether a worker that `run.ps1` starts on Windows
    can run a bash hook. Not probed in this batch; when the hook is built,
    the roadmap records the gap.
  - The hook, when built: registered in `plugins/kenspc/hooks/hooks.json`
    on PreToolUse for Bash and for every file-writing tool (at least Write,
    Edit, NotebookEdit); inert — exit 0, no output — unless
    `KENSPC_AUTOPILOT_WORKER` is `1`. Otherwise it denies (a) a Bash command
    that runs `rm` with a recursive flag, and (b) a file-tool write whose
    resolved target lies outside `KENSPC_AUTOPILOT_WRITE_ROOTS`. The roots
    are the worker's repository, the workspace, `$TMPDIR`, `/tmp`, and
    `/private/tmp`, so the hook never denies what J-L3 records as an
    observation. The deny reason names the rail and the permitted route
    (`mv` into the workspace's `.trash/`, or a write under the repository,
    the workspace, or scratch). It is a best-effort guard: its known misses
    are documented, and the J-L3 text still binds.
  - `run.sh` and `run.ps1` export the two variables to every worker, fresh
    and resumed. When the hook is built, the skill passes the workspace to
    the driver as `AUTOPILOT_WORKSPACE` on every launch.
- **J-L5 — a skipped gate is checked, not prevented.**
  - An S2 that returns without having sent its confirmation question: the
    main session applies the confirmation's own rubric — the task list
    matches the spec's steps and carries no choice the spec leaves open —
    to the committed task document. A match is accepted and recorded as a
    behavior deviation in the state file and the reviewer report. No
    match, or a choice left open, is a stop of the unanswered-question
    kind; in a session that cannot ask, the run ends with it.
  - An S3 that returns without having asked the batch gate: recorded only,
    since after S2 passed, the gate's answer is yes by construction.
  - No effort floor for gate-carrying roles.
- **J-L6 — headless records.** In a headless main session the state file
  and the timeline are the record. The requirement to print the settings
  line and the launch and return lines in the reply applies to an
  interactive main session only.
- **J-L7 — the fix loop.** One S5 may fix several defects classified in the
  same round: its task block lists each defect with its case, and it
  commits one defect per commit. Every S5 is followed by the narrowed
  review (`-s3<letter>`), a wording-only fix included, before any re-run of
  a case. Stop condition 4 counts per defect.
- **J-L8 — no plugin default.** Nothing in this batch adds a per-role
  default or names a model in a plugin file (4.2.0's rule;
  `check-no-model-names.sh`).

## Design decisions

Status: ruled

| Question | Ruling | Rejected, and why |
|---|---|---|
| J-D1 Where task-implementer's temporary files go | J-L2 | `$TMPDIR/kenspc-<run-id>/` splits a run's evidence across two places; a text-only ban on `/tmp` gives it nowhere to write |
| J-D2 What the rails allow | J-L3 | Strict (every `/tmp` write a stop) stopped batch I on harmless scratch; all of `/tmp` allowed loses the record |
| J-D3 A mechanical rail | J-L4, conditional on the probes | An unconditional hook: no evidence yet that a hook reaches subagents or that its deny holds in bypass mode |
| J-D4 A skipped gate | J-L5 | An effort floor per gate role is a plugin default, against J-L8, and would not catch a skip at any effort |
| J-D5 Headless printed lines | J-L6 | Keep requiring them: two batches missed them, and nothing downstream reads the reply |
| J-D6 The fix loop | J-L7 | One defect per S5 only: batching fixes is reasonable; the missing review was the defect |
| J-D7 The plugin directory in repo mode | J-L1 | Leaving it to inheritance: read two ways in batch I |

## Implementation Steps

### Phase 1: Probes

#### Step 1.1: Probe the hook mechanics

In a throwaway plugin directory under
`<workspace>/batch-j-autopilot-reliability-probes/`, register a
PreToolUse hook that appends its stdin JSON and the value of a test
variable to a log, and denies any call whose target contains `deny-me`.
Start `claude -p --plugin-dir <probe plugin> --permission-mode
bypassPermissions --max-budget-usd 2` with the test variable set, and have
it dispatch a general-purpose subagent that (a) runs
`touch <probe dir>/deny-me-bash`, (b) writes `<probe dir>/deny-me-write`
with the Write tool, and (c) writes `<probe dir>/allowed.txt` with the
Write tool. Evidence:
- J-P1: the log shows the subagent's calls;
- J-P2: the two `deny-me` files are absent while `allowed.txt` exists;
- J-P3: the log carries the test variable's value.

Save the live `tool_input` JSON of each tool the hook would match; Phase
4's fixtures are built from it (CLAUDE.md, "Hook logic that depends on
harness-private encodings goes stale silently"). No `rm` in any probe.
Probe spend: at most USD 10 in all.

DONE: `probes.md` in that directory states each probe's result, with the
log lines and file checks that show it, and the decision J-L4 gives; the
step's report names the file and the decision.

### Phase 2: The driver

#### Step 2.1: `AUTOPILOT_PLUGIN_DIR` on every launch (J-L1)

`run.sh` and `run.ps1` treat the empty string as unset. Both self-tests
cover unset, empty, and set, on a fresh launch and on a resume.

DONE: `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`
and `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
each print `self-test passed`.

#### Step 2.2: The worker variables (J-L4; only when the hook is built)

Both drivers export `KENSPC_AUTOPILOT_WORKER=1` and
`KENSPC_AUTOPILOT_WRITE_ROOTS` to every worker, fresh and resumed. The
roots are built from the worker's repository (`git rev-parse
--show-toplevel` in its cwd), `AUTOPILOT_WORKSPACE`, `$TMPDIR`, `/tmp`,
and `/private/tmp`. The self-tests assert both on the stub's environment.

DONE: both self-tests pass.

### Phase 3: task-implementer's scratch

#### Step 3.1: The run directory before the first dispatch (J-L2)

task-implement prepares `RUN_DIR` before it dispatches task-implementer
and passes it in the dispatch; Phase 2 uses the same directory. When the
`canonical:run-dir` block changes, it changes identically in
`task-review/SKILL.md`.

DONE: the byte-identity guard and `check-run-contract.sh` pass; nothing in
task-implement or task-implementer asks for, or allows, a write under
`/tmp`.

#### Step 3.2: task-implementer (J-L2)

`agents/task-implementer.md` gains the scratch convention, and the
mutation rule by reference.

DONE: `check-code-craft-canonical.sh` and `check-no-model-names.sh` pass;
the agent names `RUN_DIR/scratch/task-implementer/` and the file that
holds the three-step rule.

### Phase 4: The hook (only when Step 1.1 decided to build it)

#### Step 4.1: The hook script

`plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh`, registered in
`hooks.json`, whose description is updated. Its behavior is J-L4's.
- A recursive `rm` is denied at a command position — at the start of the
  command, or after `;`, `&&`, `||`, `|`, `$(`, a backtick, `xargs`,
  `sudo`, `command`, or `env` — in every flag spelling: `-r`, `-R`,
  `--recursive`, any bundle holding `r` or `R`, and flags split across
  words; with or without a path prefix (`/bin/rm`).
- Not denied: `rm` without a recursive flag, and the text `rm -r…` inside
  a quoted argument of another command (`grep -c 'rm -rf' f`,
  `git commit -m "… rm -rf …"`, `echo "rm -r"`).
- A write target is resolved against the tool's cwd, with `..` collapsed
  and symlinked roots resolved (`/tmp` → `/private/tmp`, `$TMPDIR` →
  `/private/var/…`), before the root check.

DONE: the script is inert without the marker, and it runs under macOS
bash 3.2.

#### Step 4.2: Its guard

`scripts/check-autopilot-rails-hook.sh` feeds the hook fixtures built from
Step 1.1's live JSON and asserts each decision. The fixtures:
- each `rm` spelling above, denied;
- each quoted mention, allowed;
- `rm file` and `rm -f file`, allowed;
- a write inside each root, allowed;
- a write outside, denied;
- a relative path and a `..` escape, resolved;
- a symlinked root;
- every denied fixture, again without the marker: no effect.

`--self-test` mutates the hook — the `rm` detection removed, the root
check removed, the marker check removed — and each mutant must turn its
fixture red.

DONE: `bash scripts/check-all.sh` and `bash scripts/check-all.sh --self-test`
exit 0 and count the new guard.

### Phase 5: The autopilot skill

#### Step 5.1: `plugins/kenspc/skills/autopilot/SKILL.md`

- The launch bullet: J-L1, plus `AUTOPILOT_WORKSPACE` when the hook is
  built.
- The preamble's § 3: J-L3.
- The return: J-L5's gate check; the gates table and the stop conditions
  follow it.
- The settings line and the launch and return lines: J-L6.
- Phase 3's S5 and its task block: J-L7; stop condition 4 counted per
  defect.
- The reviewer report template: the `Rail observations:` line.
- The driver section: the new variables, when the hook is built.

DONE: every J-L point has its text in SKILL.md; `check-all.sh` passes.

### Phase 6: Documentation

#### Step 6.1: The durable documents

As Documentation impact lists. The CHANGELOG entry is headed
`## 4.3.0 — unreleased`.

DONE: the release checklist's pre-flight block exits 0; the Constraints'
pointer grep prints nothing.

## Documentation impact

- `plugins/kenspc/README.md`:
  - the Autopilot section: the rails as J-L3, the driver variables, the
    gate check, the headless records, the fix loop, and
    `Rail observations`;
  - Known behavior: with the hook built, its misses — `find -delete`,
    `bash -c '…'`, interpreter-level deletes, `git clean`, and writes
    through Bash; without it, that the rails reach subagents by text alone;
  - the run-directory section: task-implementer's scratch.
- `CLAUDE.md`: the run-dir paragraph (task-implementer's scratch); the
  hooks' runtime behaviour (a fourth hook, when built); the guard and
  self-test counts.
- `plugins/kenspc/CHANGELOG.md`: `## 4.3.0 — unreleased`.
- `docs/release-checklist.md`: the counts; a smoke line for the hook, when
  built.
- `docs/roadmap.md`:
  - remove the items on the headless printed lines, the lowered-effort
    gate skip, the inherited `AUTOPILOT_PLUGIN_DIR`, and the rails that do
    not reach subagents;
  - remove the task-implementer paragraph of the scratch follow-ups item;
  - add the hook's failed probe (no hook built), or the Windows bash gap
    (hook built).
- `README.md` (root): only if a skill's summary changes; otherwise
  untouched.

## Testing Strategy

The guards and self-tests (J-A8), the two driver self-tests, and the
plugin-mode acceptance in `## Autopilot` (J-A1 to J-A7), recorded in the
acceptance record.

## Risks and Mitigations

- **The hook denies legitimate work.** Quoted mentions are fixtures that
  must pass; a denial names the permitted route; the hook acts only in
  marked workers.
- **The hook stops working silently after a Claude Code update.** Its
  fixtures come from live JSON, and the release checklist gains a smoke
  line for it (CLAUDE.md's hook lesson).
- **Every Bash call in every session now starts the hook.** The inert path
  reads one variable and exits.
- **Copies for mutation checks in large projects.** The rule copies what
  the check needs, as the review agents already do.
- **This batch's own workers run the installed 4.2.0 preamble.** The
  Constraints' rulings for this run cover the gap.

## Open Questions

None open. A question during implementation goes to the main session by
message.

## Out of scope

- The model check's two misreadings and the paths 4.2.0's acceptance did
  not reach (roadmap: "Autopilot model and effort follow-ups").
- `run.ps1` acceptance on Windows, and J-P4.
- init-project.
- Rails in sessions that are not autopilot workers.
- Waiting out a subscription usage limit.

## Constraints

- **Language.** Every file this batch writes is English.
- **Rulings for this run (the user's).** This batch's workers run the
  installed plugin's preamble, whose § 3 predates J-L3. For this run:
  1. A scratch file that a worker or its subagent writes under `/tmp` or
     `/private/tmp` (the harness scratchpad included), holding no secret,
     is an observation, not a breach. The worker lists it and goes on.
  2. A recursive `rm` that a worker's subagent runs on a directory it
     created under `/tmp`, `/private/tmp`, or `$TMPDIR`, holding no
     repository or workspace path, is an observation, not a breach.
  3. The nested sessions that J-A4 and J-A5 start are test subjects: the
     writes and the denied `rm` they attempt are the cases, not S4's
     breaches. S4 removes J-A4's control file with a non-recursive `rm`.

  The main session applies the same rulings: a worker that ends citing
  only (1) or (2) as its breach is recorded as an observation and resumed
  with the ruling, as batch I's case 3 was.
- **Delegated choices.** The spec pins the names it states: the hook
  script, its guard, `KENSPC_AUTOPILOT_WORKER`,
  `KENSPC_AUTOPILOT_WRITE_ROOTS`, `AUTOPILOT_WORKSPACE`,
  `scratch/task-implementer/`, the probes directory, and the
  `Rail observations` line. Everything else of that kind is the
  implementer's: helper and variable names inside scripts, the separator
  in the roots variable, the hook's internal structure, the deny wording
  within J-L4, the fixture layout, the seed content, the split into tasks
  and commits within the steps, and the documentation wording within
  Documentation impact. A worker's proposal on any of these is answered
  "yes, as proposed"; none of them is a question for the user.
- **Pointer rule.** The spec's labels (`J-L<n>`, `J-D<n>`, `J-P<n>`,
  `J-A<n>`) are pointers for the implementer and appear in no shipped file.
  `git grep -nE 'J-[LDPA][0-9]' -- plugins scripts CLAUDE.md README.md docs/release-checklist.md docs/roadmap.md`
  prints nothing at the baseline and at the release commit; the same
  pattern over this spec prints many lines. The acceptance record may use
  the labels.
- **No model name** in any plugin file (`check-no-model-names.sh`).

## Clarifications during implementation

## Autopilot

- Mode: plugin
- Version: 4.3.0
- Budget: USD 600
- Caps: 30 sessions, 12 resumes
- Must read: CLAUDE.md, plugins/kenspc/skills/autopilot/SKILL.md, plugins/kenspc/skills/autopilot/scripts/run.sh, plugins/kenspc/skills/task-implement/SKILL.md, plugins/kenspc/agents/task-implementer.md, plugins/kenspc/hooks/hooks.json, docs/dry-runs/batch-i-acceptance.md, docs/roadmap.md
- Prior specs: e26f91b^:docs/plans/batch-i-autopilot-model-effort.md, 2375556^:docs/plans/batch-f-autopilot.md
- Allowed files: plugins/kenspc/skills/autopilot/, plugins/kenspc/skills/task-implement/SKILL.md, plugins/kenspc/skills/task-review/SKILL.md, plugins/kenspc/agents/task-implementer.md, plugins/kenspc/hooks/, plugins/kenspc/commands/kenspc-autopilot.md, scripts/, plugins/kenspc/README.md, README.md, CLAUDE.md, plugins/kenspc/CHANGELOG.md, plugins/kenspc/.claude-plugin/plugin.json, .claude-plugin/marketplace.json, docs/release-checklist.md, docs/roadmap.md, docs/dry-runs/, docs/plans/batch-j-autopilot-reliability.md, docs/tasks/, .gitignore
- Zero diff: plugins/kenspc/skills/generate-brief/, plugins/kenspc/skills/generate-plan/, plugins/kenspc/skills/generate-task/, plugins/kenspc/skills/generate-guide/, plugins/kenspc/skills/diagnose-bug/, plugins/kenspc/skills/prototype/, plugins/kenspc/skills/init-project/, plugins/kenspc/shared/, plugins/kenspc/references/, plugins/kenspc-personal/, plugins/kenspc/agents/code-fixer.md, plugins/kenspc/agents/regression-verifier.md, plugins/kenspc/agents/requirements-reviewer.md, plugins/kenspc/agents/edge-case-reviewer.md, plugins/kenspc/agents/quality-reviewer.md, plugins/kenspc/agents/bug-reviewer.md, plugins/kenspc/agents/test-reviewer.md, plugins/kenspc/agents/plan-document-reviewer.md, plugins/kenspc/agents/task-document-reviewer.md, plugins/kenspc/agents/guide-document-reviewer.md
- Byte-identity exceptions: the canonical:run-dir block, changed identically in plugins/kenspc/skills/task-implement/SKILL.md and plugins/kenspc/skills/task-review/SKILL.md
- Acceptance:
  - J-A1 (task-implementer's scratch): on a seed, a nested headless `/kenspc-task-implement <task document>` with the worktree's plugin (`--plugin-dir`), whose task document requires each new test to be shown failing against a broken implementation — PASS: `RUN_DIR` exists before task-implementer's first tool call and appears in its dispatch; every probe, copy, mutant, and runner config it writes is under `RUN_DIR/scratch/task-implementer/`; apart from its implementation edits, its transcript holds no command or tool call that backs up, mutates, or restores a tracked file (no `sed -i` on, `cp` over, or `.bak`/`.orig` copy of one); its mutation check shows the unmutated copy passing and a control mutant failing; `git status --porcelain` is empty after the run
  - J-A2 (the probes): Step 1.1's `probes.md` and log — PASS: each of the three probes has a log line or file check as its evidence, and the spec's clarification on the hook matches them (built only when all three hold)
  - J-A3 (the hook's guard; only when the hook was built, otherwise recorded Not exercised): `bash scripts/check-autopilot-rails-hook.sh` and the same with `--self-test` — PASS: both exit 0, and the fixtures cover every case Step 4.2 lists
  - J-A4 (the hook live; only when the hook was built, otherwise recorded Not exercised): on a throwaway seed, a session started through the worktree's `run.sh` copy with a plain probe prompt, in which a general-purpose subagent (1) runs `rm -rf <seed>/doomed`, a directory made for the case, (2) uses the Write tool on `$HOME/kenspc-rail-probe-<timestamp>.txt`, and (3) runs `grep -c 'rm -rf' <a seed file>`; control: a session with the same plugin directory and `KENSPC_AUTOPILOT_WORKER` unset, whose subagent does (2) alone under another file name — PASS: in the marked session the subagent's transcript shows (1) and (2) denied with the hook's reason, `<seed>/doomed` still exists, the probe file does not, and (3) ran; in the control the file exists, and S4 then removes it with a non-recursive `rm`
  - J-A5 (the rails text live): a session started through the worktree's `run.sh` copy, with the worktree skill's preamble filled for a throwaway seed and batch, and a task block that writes a short note into its session scratchpad and one into `/tmp/kenspc-rail-a5-<timestamp>.txt`, neither holding a secret, then replies — PASS: exit 0 and subtype `success`; the final message lists the `/tmp` write under `## Rail observations` and reports no breach; the scratchpad write is not reported as a breach
  - J-A6 (the gate check; shares J-A7's run): the nested spec's `Role settings:` declares `- S2: effort low` — PASS: when S2 sent no confirmation question, the nested state file and final message record the skipped gate and the post-check's outcome (accepted as a behavior deviation, or the stop it calls for); when S2 asked, recorded Not exercised (optional)
  - J-A7 (the plugin directory in repo mode): a repo-mode nested autopilot — a headless main session started with `--plugin-dir` to the worktree's plugin and with `AUTOPILOT_PLUGIN_DIR` set in its environment — on a one-task seed whose `## Autopilot` sets a budget that stops the run before S3 — PASS: every nested worker's `.err` shows no `--plugin-dir`, and the nested timeline shows the workers it started
  - J-A8 (guards and text): `bash scripts/check-all.sh`, `bash scripts/check-all.sh --self-test`, `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`, `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`, the Constraints' pointer grep, and a reading of `plugins/kenspc/skills/autopilot/SKILL.md` for J-L1, J-L3, J-L5, J-L6, and J-L7 — PASS: every command exits 0 and the grep prints nothing; the counts in CLAUDE.md and the release checklist equal `check-all.sh`'s; each point has its text, quoted with its line number in the record
- Release preparation: default