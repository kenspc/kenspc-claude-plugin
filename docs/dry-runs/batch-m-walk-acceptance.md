# Batch M — walk acceptance

Task 15 of `docs/tasks/batch-m-autopilot-field-lessons-2-tasks.md` (plan
Step 8, `docs/plans/batch-m-autopilot-field-lessons-2.md`). Run on
16 Oct 2026 on the maintainer's Mac, Claude Code 2.1.300, by the main
session of the batch, after telling the user and getting the go-ahead.

## Setup

- Seeds: four throwaway git repositories under
  `~/Projects/_smoke/batch-m-accept/`, each from one template — a static
  page `site/index.html` (`h1` "Walk Seed", a status line a script sets
  to `ready`), a test command `bash scripts/check.sh`, a `CLAUDE.md`
  naming the start command
  `python3 -m http.server <port> --bind 127.0.0.1 --directory site`, and a
  one-step spec at `docs/plans/<batch>.md` (add `<p id="version">Version 1.1</p>`
  under the heading, and a check for it). Batches and ports: `walk-on`
  8811, `walk-off` 8812, `walk-port` 8813, `walk-nt2` 8814.
- Every spec's `## Autopilot`: `Acceptance: none`,
  `Standalone review: off`, `Workspace: ~/Projects/_smoke/batch-m-accept/ws`,
  `Caps: 8 sessions, 4 resumes`, `Role settings:` S2, S3, and S6 at
  `model sonnet, effort low` (to bound the cost; S4w and S5 ran at the
  pass-through values, the main session's model at `medium`); `Walk: on`,
  except `walk-off`'s `Walk: off`; `Budget: USD 7` (`walk-nt2`: USD 1).
- Each main session ran headless with this checkout's plugin:
  `claude -p "/kenspc-autopilot docs/plans/<batch>.md" --plugin-dir
  <checkout>/plugins/kenspc --name <batch>-main --permission-mode
  bypassPermissions --settings '{"crossSessionInbound":"accept"}'
  --output-format json --max-budget-usd <5, or 3 for case 3>`, cwd the
  seed. The workers ran the installed plugin (4.6.0); S4w's behavior came
  from the preamble, the task block, and the driver copy the main session
  took from this checkout.
- Cases 1, 2, and 4 ran in parallel (12:05–12:17). Case 4's port was held
  by `python3 -m http.server 8813` started from another directory before
  the run (PID 30027), stopped by the main session of this batch
  afterwards; ports 8811–8813 were free after the runs.
- Records: `~/Projects/_smoke/batch-m-accept/ws/_logs/<batch>-state.md`,
  `-report.md`, `-timeline.log`, `-costs.txt`, `<batch>-walk/walk.md`;
  each main session's final message in
  `~/Projects/_smoke/batch-m-accept/main-<batch>.json`.

## Cases

### 1. `Walk: on` — PASS

- Timeline: `walk-on-s2`, `-s3`, `-s5`, `-s3c`, `-s4w`, `-s6`, each
  `exit 0`; S4w started after the narrowed review `-s3c` and before S6.
- S4w chose one flow from the spec's Step 1 and named it in `walk.md`:
  "a visitor opens the seed page and sees its version" — seen: heading
  "Walk Seed", "Version 1.1", "ready", the version line beneath the
  heading. Result PASS.
- `walk.md` and the screenshot `walk-on-flow1-page.png` under
  `ws/_logs/walk-on-walk/`.
- Servers: it checked 8811 free, started the server (listener PID 65663),
  stopped it, showed `ps -p 65663` gone and
  `lsof -ti tcp:8811 -sTCP:LISTEN` empty; 8811 was free after the run.
- URLs: its transcript's only browser navigation is
  `http://127.0.0.1:8811/` (plus the browser's own `/favicon.ico`
  request); no non-local URL.
- Reports: reviewer report `- Walk: walked (walk-on-s4w): Flow 1 "a
  visitor opens the seed page and sees its version" PASS; …/walk.md` and
  `- Acceptance: none named; S3 is the last review, the walk follows`;
  the user report's "**Walk:** passed. In a real browser at
  `http://127.0.0.1:8811/`, …"; state file
  `walk: on — walked: walk-on-s4w, 1 flow, PASS — …/walk.md`.
- Cost: workers USD 3.6581 (S2 0.2579, S3 0.8171, S5 0.2458, S3c 1.7816,
  S4w 0.4512, S6 0.1046); main session USD 2.6780.

### 2. `Walk: off` — PASS

- Timeline: `walk-off-s2`, `-s3`, `-s6` only; no S4w launched.
- Reports: reviewer report `- Walk: off` and
  `- Acceptance: none named; S3 is the last check`; the user report says
  the spec "turns off both acceptance checks and the browser walk"; state
  file `walk: off`.
- Cost: workers USD 1.0654; main session USD 1.8455.

### 3. Neither tool usable — PASS (second attempt)

- First attempt, `walk-nt` (not counted): a `claude` test double placed
  first on `PATH` through a test `ZDOTDIR` did not reach the main
  session's Bash tool, whose shell found the real `claude`; the start
  check ran as written, saw `playwright: … - ✔ Connected`, exit 0, and
  the run went on to S2 and S3 — the skill did what its text says. The
  main session of this batch stopped that run (`walk-nt-main` and its S3)
  to bound the spend.
- Second attempt, `walk-nt2`: launched with
  `--settings '{"crossSessionInbound":"accept","env":{"CLAUDE_CONFIG_DIR":"<an empty directory>"}}'`,
  so the session stayed signed in while its Bash children read an empty
  configuration (a USD 0.1730 probe session showed `claude mcp list`
  printing `No MCP servers configured. …` that way first). The main
  session ran the start check, got that output and exit 1, and ended
  `Autopilot stopped: walk tool unavailable — \`claude mcp list\` printed
  "No MCP servers configured. …" (no \`playwright: … - ✔ Connected\`
  line); connect the Playwright MCP or set \`Walk: off\``, naming both
  ways on. No worker started: `ws/_logs` holds no `walk-nt2-*` session
  file.
- Cost: `walk-nt2` main session USD 0.4764; the probe session USD 0.1730;
  the first attempt's S2 USD 0.2931, plus its stopped S3 and main session,
  which wrote no cost — about USD 1.7 by their transcripts' token counts
  at assumed prices (an estimate, not a measurement).

### 4. A port held before S4w starts — PASS

- S4w checked 8813, found PID 30027 (`python -m http.server 8813`, PPID 1,
  started 12:03:06, not its own), and asked the main session.
- State file `questions answered:`: `walk-port-s4w: port 8813 held by PID
  30027 (not ours), wait or skip? → skip: a long-running http.server
  (PPID 1, cwd ../holder), not a session that will end (main session)`;
  recorded as clarification 4 in the spec.
- `walk.md`: `Result: not walked: port 8813 in use`, the port check's
  output, no browser tool called. Reports: reviewer report
  `- Walk: not walked: port 8813 in use; …/walk.md`; state file
  `walk: on — not walked: port 8813 in use — …`; the user report names
  the held port and the skip. The run went on to S6 and finished; no
  stop.
- Cost: workers USD 1.3919 (S4w 0.3292); main session USD 2.4801.

## Findings

- F1 (behavior, observation): `walk-on-s4w` passed a relative file name to
  `browser_take_screenshot`, which wrote it into the session's working
  directory — the repository — before S4w moved it to the walk folder;
  the tree was clean afterwards and S4w listed it under
  `## Rail observations` and `## Lessons for the main session`. The S4w
  task block says the Playwright MCP writes only under its output
  directory and the working directory, and to copy each screenshot into
  the workspace; naming an absolute path under the MCP's output directory
  would keep the file out of the repository. A follow-up candidate for
  the S4w block.
- F2 (behavior, observation): the `walk-off` main session's final message
  carries `## Reviewer report` but no `## User report` heading — its user
  report is the unheaded text before it. Outside this batch's changes.
- F3 (observation, installed 4.6.0): S3's task-implement committed a
  `.gitignore` holding `.kenspc/` in each seed, a file the specs put out
  of scope; the `walk-on` main session had it reverted by an S5 (and a
  narrowed review, USD 2.03 of that batch's cost), the `walk-off` main
  session kept it by a recorded ruling, and `walk-port` raised nothing.
  Two main sessions ruled the same departure two ways.

## Observations

- Each S4w and the start check used the Playwright MCP alone, as Task 1's
  probe settled; Claude in Chrome was not touched.
- The case 3 first attempt: `Budget: USD 1` did not stop the run before
  S2; the main session launched S2 with `--max-budget-usd 1` and S3 with
  the remaining USD 0.71.
- Main-session cost dominates these one-task batches: USD 1.85–2.68 per
  main session against USD 1.07–3.66 of workers.

## Not exercised

- A walk FAIL classified to an S5 and an `-s4wb` re-run: every walk that
  ran passed.
- The main session's `wait` ruling on a held port (case 4 was ruled
  `skip`).
- S4w's own tool check failing at its start (`walk tool unavailable`).
- The walk with flow sub-bullets in `Walk:`.

## Summary

The four cases PASS as written. Spend: USD 14.0616 measured (main
sessions 7.4799, workers 6.1154, the env probe 0.1730, the first case-3
attempt's S2 0.2931) plus about USD 1.7 estimated for the stopped first
attempt — about USD 15.8, under the USD 40 cap.
