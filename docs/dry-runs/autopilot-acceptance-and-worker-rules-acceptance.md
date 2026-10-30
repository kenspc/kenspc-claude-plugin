# Acceptance: batch autopilot-acceptance-and-worker-rules (4.15.0)

S4 of batch `autopilot-acceptance-and-worker-rules`, tag
`autopilot-acceptance-and-worker-rules-s4`, run on 2026-10-30 from 15:13 to
15:38 +0800, at the batch's HEAD `3462f5b0c929ea3baf7220a8bf08a573bbd642d3`
(range `7609d398780368f5e0ab882bdd4d3e81331d8d51..3462f5b0c929ea3baf7220a8bf08a573bbd642d3`),
with the plugin at `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc`.
Claude Code's model and effort for every nested session: the pass-through
values, `claude-opus-5-5` / `medium` (as the A2 and A3 nested state files
record them).

## Setup

- Workspace: `/Users/kenspc/Projects/_smoke`. Seeds, one per case that needs
  one, each its own git repository committed clean on `main`:
  - `autopilot-acceptance-and-worker-rules-a2/` — `README.md` and
    `docs/plans/aawr-a2-spanled.md`, a one-step spec (add `hello.sh`) whose
    `## Autopilot` section is `Mode: repo`, `Budget: USD 20`,
    `Standalone review: off`, `Walk: off`, and one `Acceptance:` entry,
    `` `true` from the seed's root — PASS: exit 0 ``. Commit `e24ad9c`.
  - `autopilot-acceptance-and-worker-rules-a3/` — the same spec shape as
    `docs/plans/aawr-a3-desc.md`, with `Budget: USD 40`, `Acceptance:`
    holding one command (`` `bash hello.sh | grep -qx hello` — PASS: exit 0 ``)
    and one description case whose text holds the marker word
    `ZORVELQUILL` ("Case ZORVELQUILL: from the repository root, run the
    greeting script with bash and count its output lines; the case name is
    a label only and goes into no command — PASS: the script exits 0 and
    prints exactly one line, which reads hello"), and `Release checks:`
    holding `` `git log --format=%s | grep -q 'remove batch'` — PASS: exit 0 ``.
    Commit `465445a`.
  - `autopilot-acceptance-and-worker-rules-a5/` — `README.md` only, commit
    `42897ee`.
- Before launching, HEAD's `extract-acceptance.sh` was run on both specs
  into `$TMPDIR`: A2's `Acceptance:` gave `commands: 0, cases: 1` /
  `span-led: 01`; A3's gave `commands: 1, cases: 1` / `span-led: none`, and
  its `Release checks` field `commands: 1, cases: 0` / `span-led: none`.
  `ZORVELQUILL` appeared nowhere in the repository or `_prompts/` before
  the seed was written.
- Nested launches (trial, A2, A3) went through the batch's driver copy
  `/Users/kenspc/Projects/_smoke/_prompts/autopilot-acceptance-and-worker-rules-run.sh`
  (the installed 4.14.1 driver; it differs from HEAD's `run.sh`), with the
  task's environment line, `AUTOPILOT_PLUGIN_DIR` the plugin directory,
  `AUTOPILOT_WORKSPACE=/Users/kenspc/Projects/_smoke` (the nested batches
  name no `Workspace:`, so their workspace is the default, the same path),
  and `APPEND_SP="Work without stopping; do not ask clarifying questions."`
  on the trial, A2, and A3 lines. A5 went through HEAD's `run.sh`.
- **Trial run** (`autopilot-acceptance-and-worker-rules-s4-trial`, session
  `4344e915-a699-42cf-b721-fe8de149eaeb`, cwd the A2 seed, cap 238.11):
  the prompt had the session invoke `kenspc:autopilot` on a missing path
  and report what it received. Driver reply:
  `started autopilot-acceptance-and-worker-rules-s4-trial pid 62898 session 4344e915-a699-42cf-b721-fe8de149eaeb`.
  Exit 0, `is_error: false`. Its result quoted the base-directory line
  `Base directory for this skill: /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/autopilot`,
  answered yes to the skill text holding `Release checks:`, listed the six
  `KENSPC_AUTOPILOT_*` variable names, and ended
  `Autopilot stopped: argument file /nonexistent/aawr-probe.md does not exist`.
  The path under test — HEAD's skill, reached in a headless session through
  the driver copy — is reachable. **Cost USD 0.9467.**

## Independence

- A1 ran in this session in the repository; nothing it runs reads the
  seeds.
- Each nested run had a seed, a batch name (the spec's base name:
  `aawr-a2-spanled`, `aawr-a3-desc`), and a tag of its own; `_logs/` held
  no file of either batch name or of any `-s4-case<n>` / `-s4-trial` tag
  of this batch before the run.
- A4 is an observation of A3's nested S4 by this session, not a nested
  session of its own; its cost is inside A3's.
- The cases ran one after another in the order listed; only A1's last
  command (`run.ps1 --self-test`) overlapped the trial and A2 in time —
  the self-tests use their own temp directories and stub executables, and
  the nested sessions write under the workspace.
- The A1 logs and A4's samples are kept at
  `/Users/kenspc/Projects/_smoke/_analysis/aawr-s4/`.

## Cases

### A1 (guards) — PASS — USD 0

Run in this session at HEAD, one after another:

| Command | Exit | Count lines |
|---|---|---|
| `bash scripts/check-all.sh` | 0 | `guards run: 17` |
| `bash scripts/check-all.sh --self-test` | 0 | `guards run: 17`; last line `self-tests run: 16` |
| `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test` | 0 | last line `self-test passed` |
| `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test` | 0 | last line `self-test passed` |

`docs/release-checklist.md` (lines 31–32, 43–44) expects `guards run: 17`
and `self-tests run: 16` as the last line; both match. No driver reply
belongs to this case.

### A2 (the span-led question, a session that cannot ask) — PASS — USD 0.7963

Tag `autopilot-acceptance-and-worker-rules-s4-case2`, session
`85214bad-e992-4757-a716-341f7ab1739d`, cwd the A2 seed, cap 237.16,
prompt `/kenspc-autopilot /Users/kenspc/Projects/_smoke/autopilot-acceptance-and-worker-rules-a2/docs/plans/aawr-a2-spanled.md`.
Driver reply:
`started autopilot-acceptance-and-worker-rules-s4-case2 pid 76594 session 85214bad-e992-4757-a716-341f7ab1739d`.
Exit 0, `is_error: false`, `.err` empty.

- No worker started: `_logs/aawr-a2-spanled-timeline.log` does not exist,
  so it holds no `start` line; the only `_logs/` files of the batch are
  its state file and its temp-folder before list.
- The final message ends
  ``Autopilot stopped: span-led Acceptance: entry in a session that cannot ask — 01.case `true` from the seed's root (words after the span: "from the seed's root")``,
  naming the entry and the words after the span; its body quotes the
  entry and the trial counts `commands: 0, cases: 1`.
- The state file `_logs/aawr-a2-spanled-state.md` records it:
  ``stops: span-led Acceptance: entry in a session that cannot ask — 01.case `true` from the seed's root — PASS: exit 0 (words after the span: "from the seed's root") (2026-10-30 15:17 +0800)``,
  with `step: S0 (Phase 0, start checks)`, `sessions: none`.
- The seed is as it was: HEAD `e24ad9c`, `git status --porcelain` empty.

### A3 (a description case and a release check) — PASS — USD 8.9510

Tag `autopilot-acceptance-and-worker-rules-s4-case3`, session
`f786f174-145b-48f6-8141-478c795c770b`, cwd the A3 seed, cap 236.36,
prompt `/kenspc-autopilot /Users/kenspc/Projects/_smoke/autopilot-acceptance-and-worker-rules-a3/docs/plans/aawr-a3-desc.md`.
Driver reply:
`started autopilot-acceptance-and-worker-rules-s4-case3 pid 46596 session f786f174-145b-48f6-8141-478c795c770b`.
Exit 0, `is_error: false`, `.err` empty. The nested batch's driver copy
`_prompts/aawr-a3-desc-run.sh` is byte-identical to HEAD's `run.sh`
(`cmp`), so its four workers launched through the stdin driver.

Its timeline holds four starts, each ending `exit 0`: `aawr-a3-desc-s2`,
`-s3`, `-s4`, `-s6`. Seed history after the run, after `465445a`:
`904be77 docs(tasks): add aawr-a3-desc task document`, `6d72aeb chore: ignore kenspc run directory`, `fec90c6 feat: add hello.sh greeting script`,
`32e187e docs(tasks): complete doc-sync for hello.sh`,
`1e692f4 docs(plans): record clarifications settled after S3`,
`0dc0f46 docs: remove batch aawr-a3-desc plan and tasks`.

- **S4 ran the description case without a question.** The state file's
  `questions answered:` holds entries under `aawr-a3-desc-s2`, `-s3`
  (two), and `-s6`, none under `-s4`. S4's reply (`_logs/aawr-a3-desc-s4.json`)
  re-extracted the cases (exit 0, `commands: 1, cases: 1`), showed `cmp`
  equal for `01.cmd` and `02.case` and a differing pair (exit 1), ran
  `01.cmd` as `/bin/zsh <file>` (exit 0, PASS), and for `02.case`
  ZORVELQUILL named the commands it ran with their exit codes —
  `out=$(bash hello.sh)` exit 0, `bash hello.sh | od -c` exit 0
  (`h e l l o \n`), `bash hello.sh | wc -l` exit 0 (`1`), a control
  `printf 'hello\nhello\n' | wc -l` (`2`) — and PASS against the criterion.
- **S6 replied with the release check's file and exit 0.** S6's reply
  (`_logs/aawr-a3-desc-s6.json`): commit
  `0dc0f46f74309a3dcc893ed332c0578bcef8f9d0 docs: remove batch aawr-a3-desc plan and tasks`;
  re-extraction `"Release checks"` exit 0, `commands: 1, cases: 0`; both
  directories list `01.cmd`; `cmp` equal (exit 0) and a control against a
  copy with a line appended (`cmp: EOF on …/aawr-a3-desc-release-cmds/01.cmd`,
  exit 1); then
  `/bin/zsh /Users/kenspc/Projects/_smoke/_prompts/aawr-a3-desc-release-cmds/01.cmd`
  at `0dc0f46…`, **exit 0**.
- **The user report lists the release check with its exit code.** The
  nested main session's final message (its `## User report`) has
  "发布检查：`01.cmd`（`git log --format=%s | grep -q 'remove batch'`），exit 0",
  and `_logs/aawr-a3-desc-report.md` line 33 reads
  `- Release preparation: 0dc0f46 docs: remove batch aawr-a3-desc plan and tasks; release checks: 01.cmd → exit 0`.

Cost, each session's last cumulative `total_cost_usd`: nested main
4.3524, S2 0.6873, S3 3.2260, S4 0.3389, S6 0.3464; sum 8.9510.

### A4 (no prompt on the command line) — PASS — USD 0 (observed during A3)

A sampler of this session (`a4-sampler.sh` in this session's scratchpad)
waited for `_logs/aawr-a3-desc-s4.session`, read the S4 session id
`5a1e6b39-99a7-4db7-8929-e864fdd7fc0d` (timeline:
`start aawr-a3-desc-s4 pid 83727 … at 2026-10-30 15:33:14`), and then,
once a second until `aawr-a3-desc-s4.exit` appeared (15:33:15 to
15:34:06), took one `ps -axo args` snapshot and counted
`grep -c '[Z]ORVELQUILL'` and `grep -c '[5]a1e6b39-99a7-4db7-8929-e864fdd7fc0d'`
in it.

- 47 samples: marker count 0 in all 47.
- Positive control: session-id count 2 in 46 samples and 4 in one, never 0.
- The premise holds: S4's assembled prompt `_prompts/aawr-a3-desc-s4.md`
  holds `ZORVELQUILL` (line 190, the case as the field writes it), and the
  nested autopilot's launch prompt does not (`grep -c` 0).

No driver reply belongs to this case beyond A3's.

### A5 (the hook live) — PASS — USD 0.2225

Tag `autopilot-acceptance-and-worker-rules-s4-case5`, session
`13366730-5d3e-4a1a-bf8d-d4948d35f92d`, started through HEAD's
`plugins/kenspc/skills/autopilot/scripts/run.sh` with the task's
environment line (`AUTOPILOT_PLUGIN_DIR` the plugin directory,
`AUTOPILOT_WORKSPACE=/Users/kenspc/Projects/_smoke`, cap 227.41), cwd
`/Users/kenspc/Projects/_smoke/autopilot-acceptance-and-worker-rules-a5`.
Driver reply:
`started autopilot-acceptance-and-worker-rules-s4-case5 pid 92515 session 13366730-5d3e-4a1a-bf8d-d4948d35f92d`.
Exit 0, `is_error: false`, `.err` empty.

- `mkdir -p /Users/kenspc/Projects/_smoke/a5/x && cd /Users/kenspc/Projects/_smoke/a5/x && echo a > ../../a5.log`
  ran, not denied; `/Users/kenspc/Projects/_smoke/a5.log` held `a`.
- `cd / && echo b > a5-denied.log` was denied; the session quoted the
  error:
  `PreToolUse:Bash hook error: [bash "/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh"]: autopilot rails: this Bash call redirects output outside the rails' write roots, which is denied in an autopilot worker: a5-denied.log resolves to /a5-denied.log, outside /Users/kenspc/Projects/_smoke/autopilot-acceptance-and-worker-rules-a5|/Users/kenspc/Projects/_smoke|/var/folders/28/hztldwfs1ls4stzfgvj2qm900000gn/T/|/tmp|/private/tmp. …`
  followed by `This hook comes from the kenspc@inline plugin.`
- Neither `/a5-denied.log` nor
  `/Users/kenspc/Projects/_smoke/autopilot-acceptance-and-worker-rules-a5/a5-denied.log`
  exists (`ls`: No such file or directory).
- Which hook: the denial names the plugin directory's hook
  (`kenspc@inline`). No denial carried the installed 4.14.1 hook's path,
  and the first command, which the 4.14.1 hook reads against the seed's
  cwd, was allowed. A reading, not probed further: in this session the
  installed plugin's hook did not fire beside the `--plugin-dir` copy
  (§ Risks' last item), or fired and allowed the call; the evidence does
  not separate the two.

## Findings

None. Every case passed against its criterion.

## Observations

- **`APPEND_SP` reaches the nested batch's workers.** The A3 nested main
  session was launched with `APPEND_SP` set (the case's cannot-ask
  variant); every worker start line in `aawr-a3-desc-timeline.log` ends
  `[append-system-prompt]`, so S2–S6 ran with the cannot-ask system prompt
  too. The nested main session listed it as a follow-up candidate ("the
  skill sets it on no launch but does not clear it the way it clears
  AUTOPILOT_MODEL and the others"). Effect on A3: S2, S3, and S6 still
  asked by message (state file), so the cannot-ask prompt did not suppress
  asking; but S4's "without a question" is weaker evidence than it would
  be for a worker that could ask freely.
- **The nested main session is itself a marked worker.** It ran with
  `KENSPC_AUTOPILOT_WORKER=1` from this batch's driver, so the rails hook
  denied its Phase 4 `rm -rf` of the temp entries; it moved them to
  `/Users/kenspc/Projects/_smoke/.trash/aawr-a3-desc-tmp-20261030153540/`
  instead (report line 34). An artifact of nesting, not of the batch.
- **Nested S6 ran `mv "$TMPDIR/01.cmd.mod" /dev/null`** (failed, nothing
  changed), listed it under its rail observations, and the nested main
  session ruled it benign. It was the nested batch's worker, not this
  session's.
- **Recheck directory names double the batch prefix.** S4 extracted into
  `_prompts/aawr-a3-desc-aawr-a3-desc-s4-recheck/` and S6 into
  `_prompts/aawr-a3-desc-aawr-a3-desc-s6-release-recheck/`: the template's
  `<batch>-<tag>-…` with a tag that already begins with the batch name.
  Harmless (unique per tag), but the doubled prefix reads as a slip.
- **The nested main session under-estimated its own cost**: its user
  report gives "约 USD 1.42" for itself, while its `.json` reports
  `total_cost_usd` 4.3524. The report's worker total (USD 4.60) is correct.
- The marker word also entered the A3 spec's clarification 3, written by
  the nested main session (a ruling that names the case); that text lives
  in a file, not in any process argument, and does not touch A4's
  criterion.
- The nested A2 and A3 main sessions and their workers wrote their final
  messages in Chinese, following the user's global instructions; the
  `Autopilot stopped:` line stayed in English.
- A2's nested session left the driver self-test's directory in the temp
  folder, as the skill specifies for a stop before Phase 4.

## Not exercised

- A2's other answer (run the span-led entry as a description case), which
  needs a session that can ask.
- A `Release checks:` field that yields a `.case` (the settings stop) and a
  failing release check (the report's first lines, no S5); A3 had one
  passing command.
- Plugin-mode S6's release-check paragraph; A3 ran repo mode.
- `Zero diff:` exclusions live (the `!` form); covered only by A1's guard
  fixtures.
- `run.ps1` launching a real session (A1 runs its self-test with a stub
  only); no Windows or WSL2 run.
- S4w (screenshot names), the network-fetch route, and the question-tag
  echo under a mismatched tag; the A3 workers' questions used their own
  tags, but no answer under another tag was tried.
- The A5 hook cases beyond the two commands (subshell, pipeline, `||`,
  compound bodies), held only by A1's fixtures.

## Summary

| Case | Result | Cost (USD) |
|---|---|---|
| Trial | reachable | 0.9467 |
| A1 | PASS | 0 |
| A2 | PASS | 0.7963 |
| A3 | PASS | 8.9510 |
| A4 | PASS | 0 (within A3) |
| A5 | PASS | 0.2225 |

Total nested cost USD 10.9166 of the 238.11 cap. All five cases pass at
`3462f5b0c929ea3baf7220a8bf08a573bbd642d3`.
