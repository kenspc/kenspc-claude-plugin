# code-fixer trims smoke (plan `docs/plans/code-fixer-trims.md`, Step 6)

Two headless `/kenspc-task-review` runs, 2026-10-20, on throwaway seeds, with the edited agents
loaded through `--plugin-dir` (`claude -p "/kenspc-task-review…" --plugin-dir
<repo>/plugins/kenspc --permission-mode bypassPermissions --output-format json`). The working tree
held Steps 1–4 uncommitted on top of `12dc06b`.

## Setup

- Seed: a Node project with vitest 3.2.4 and two source files, `src/pricing.js` and
  `src/cart.js`. Its `package.json` gives `build` (every source file parses), `test`
  (`vitest run`), and `lint` (no `var` or `console.log`, on the files given or all of `src/`).
  The README states two rules: a VIP discount is 10% of an order total of 100 or more, and the
  average price of an empty cart is 0.
- Base commit `a69ebe5`, then one change commit `1b16c8f`, which adds:
  - `discountFor`, whose one new test holds only `(200, "VIP")`, so its threshold and code
    check have surviving mutants;
  - `averagePrice`, which returns `NaN` for an empty cart.
- Run 1: `~/Projects/_smoke/code-fixer-trims-smoke/`, the prompt `/kenspc-task-review` alone.
  - Run directory `.kenspc/runs/20261020-153524-changes/`.
  - Session `01c1bcfa-cf75-4765-a3e7-ff61b80e85ef`, USD 2.67, 5.7 min.
- Run 2: `~/Projects/_smoke/code-fixer-trims-smoke-2/`, a clone reset to `1b16c8f` with its
  remote removed, the prompt `/kenspc-task-review Test reviewer: confirm each surviving mutant
  you report with a mutation check under your scratch directory, keeping each mutant's
  definition there (its diff or the script that applies it).`
  - Run directory `.kenspc/runs/20261020-154227-changes/`.
  - Session `f13aba3d-d1c5-4db2-89ec-1a139a459797`, USD 3.91, 7.9 min.
- Transcripts: `~/.claude/projects/-Users-kenspc-Projects--smoke-code-fixer-trims-smoke{,-2}/<session>/subagents/`.
  code-fixer is `agent-ac97c21685a8b95bb` (run 1) and `agent-a310d89bebff21e82` (run 2).

Why a second run: in run 1 the test reviewer ran no mutation check. Its report says "No mutation
check was executed; the findings below are from reading". `scratch/angle-5/` therefore held no
definition to reuse, and check 1 could not be judged. The plan allows one more run with a changed
input. The custom instruction to the test reviewer is that change; the seed is the same.

## Checks

| # | Check | Run 1 | Run 2 |
|---|---|---|---|
| 1 | The mutant fix's check reuses the reviewer's mutant, applied to a copy at the fix's commit under `scratch/code-fixer/<n>/`, with the unmutated, control and mutant runs logged there | Not judged: no rig in `scratch/angle-5/`. code-fixer took the fallback and wrote the mutants from T2's and T3's descriptions | PASS |
| 2 | At most three mutation checks of code-fixer's own beyond the named mutants | PASS: 0 | PASS: 0 |
| 3 | Per-fix test commands name test files; no whole-suite test run before the last fix commit | PASS | PASS |
| 4 | One whole build, test and lint run after the last fix commit | PASS | PASS |
| 5 | The reply carries the `Final checks:` line naming those commands | PASS | PASS |
| 6 | regression-verifier returns CLEAN | PASS | PASS |

Evidence, run 2:

1. **Check 1.**
   - `scratch/code-fixer/1/mk-variants.mjs` builds each check's variants from
     `git show <commit>:<file>` at the fix's own commit: `750c07f`, `32e4ff7` and `d57b508`.
   - Its mutant edits are those of the reviewers' rigs, string for string:
     - `m1` `>= 100`→`> 100`, `>= 100`→`>= 0`, the VIP check dropped, and `m4`/`m5` are
       angle-5's `apply-mutants.mjs`;
     - `m2-no-min` is in angle-1's, angle-2's and angle-3's rigs;
     - row 2's `m4-empty-avg` is angle-1's, which the script marks "adapted to the guarded
       code".
   - Each check logs `<check>-base` (exit 0), `<check>-control` (exit 1) and one log per mutant
     (exit 1).
   - Before writing the script, code-fixer read every reviewer's rig (+0.65, +0.70 in its
     transcript).
2. **Check 2.** Every mutant run is a reviewer's. None is code-fixer's own, and no row reads
   `not mutation-checked`.
3. **Check 3.**
   - The per-fix commands are `npx vitest run test/cart.test.js` or `test/pricing.test.js`,
     `node scripts/lint.mjs <changed file>`, and `npm run build`.
   - Fix commits ran from +1.18 to +3.09; the first `npm test` is at +3.18.
4. **Check 4.** One `npm run build`, `npm test` and `npm run lint` at +3.18, logged to
   `scratch/code-fixer/final-{build,test,lint}.log`.
5. **Check 5.** `Final checks: npm run build → exit 0, log scratch/code-fixer/final-build.log;
   npm test → exit 0, log scratch/code-fixer/final-test.log; npm run lint → exit 0, log
   scratch/code-fixer/final-lint.log`.
6. **Check 6.** `schema-c-1.md` reads CLEAN, rows 1–5 PASS.

Run 1 matched on checks 2–6 the same way: per-fix `npx vitest run <file>`, one final run at
+2.78, and the same `Final checks:` form.

## Observations

- **Run 1's mutation checks ran at HEAD, not at each fix's commit.** code-fixer ran them once,
  after the last fix, at HEAD. No later fix touched the mutated lines, so the result stands. But
  it is the "copy at the fix's commit" wording followed loosely. Run 2 followed it.
- **regression-verifier mutation-checked the new tests again in both runs:** 5 mutants in run 1
  and 8 in run 2, on top of code-fixer's. This is Open Question 2 of the plan. The roadmap
  item's read-back would show whether this repeat is worth cutting.
- **The orchestrator's final report dropped log paths that its sources carry.** Fixed in
  task-review's SKILL.md before the release, and checked by the row 7 rerun below.
  - Run 1's report shows `Final checks:` without its log paths, while code-fixer's reply
    carries them.
  - Run 2's report shows Schema C's row 3 as `npm test → exit 0; 10/10 passed…`, while
    `schema-c-1.md` row 3 reads `npm test → exit 0, log
    scratch/regression-verifier/1/npm-test.log; …`.
  - Task-review renders both verbatim by its rules, so this is a rendering deviation of the
    orchestrating session. Release-checklist row 7 checks code-fixer's reply and Schema C's
    rows, both of which hold the paths.
- Each run took 3.2–3.6 minutes of code-fixer's time for 4–5 fixed rows. There were no waits
  and no background runs.

## Release smoke, row 7 rerun (4.12.0)

Runs 1 and 2 failed release-checklist row 7 on the orchestrator's own output, which this plan did
not touch:
- both printed the `code-fixer returned —` and `regression-verifier returned —` lines inside
  backticks, so the lines did not open with the agent's name;
- run 2 printed no `Reviewers returned —` line at all;
- both final reports dropped log paths (run 1 from `Final checks:`, run 2 from Schema C's row 3).

4.11.0 had fixed the same in task-implement only. The maintainer chose to port that fix into
`skills/task-review/SKILL.md` for 4.12.0 (the progress lines are plain text, printed as soon as
their agent returns; the final report renders code-fixer's reply and Schema C in full) and to
rerun row 7.

- Run 3: `~/Projects/_smoke/code-fixer-trims-smoke-3/`, a clone reset to `1b16c8f`, its remote
  removed, the prompt `/kenspc-task-review` alone.
  - Run directory `.kenspc/runs/20261020-162335-changes/`.
  - Session `ddf356c3-2320-41f5-99bc-43a2630629f8`, USD 3.21, 7.8 min.
- Checked by a script over the main transcript and the run directory. The same script run on
  runs 1 and 2 reports their failures (backticked lines, missing logs), so its checks can fail.

| Row 7 item | Run 3 |
|---|---|
| Five reviewer Agent calls, all foreground | PASS |
| `Reviewers returned —`, `code-fixer returned —`, `regression-verifier returned —` lines, each opening its line, in order between the dispatches | PASS |
| Their counts and paths: HIGH 5 / MEDIUM 8 / LOW 1 = the roll-up Total = each report's Findings table summed; FIXED 5 / DEFERRED 0 / NA 0 = the statistics line; `— CLEAN` = Schema C | PASS |
| No line opening `\|` before Schema F; the roll-up header, `total reported `, and the Schema C header each once, inside Schema F | PASS |
| Schema C rows 2–4 each name `<command> → exit <n>, log <path>`, and each log exists under the run directory | PASS |
| code-fixer's `Final checks:` line, with existing logs, before its Per-angle Results table; `schema-b.md` ends with the statistics line | PASS |
| No `Doc-sync documents:` line and no document suffix (no task document) | PASS |
| Run directory sub-checks 1–5: no collectable test name under `scratch/` (the same `find` lists the seed's own `test/*.test.js`); the project's `npm test` passes, 10/10; the fix commits touch only `src/cart.js` and two test files; regression-verifier ran `npm test` as configured and listed the collected files; no delete in any transcript | PASS |
| Sub-check 6: mutation baseline and control | PASS, see below |
| `check-run-contract.sh --file schema-b.md` exits 0 (a copy with one count changed exits 1) | PASS |
| Change-set check: `Mode: commits`; every `File:Line` in the five reports is in the set; no orchestrator `git commit`, `stash`, `checkout`, `add` or `reset` before the first dispatch | PASS |
| The session scratchpad holds no source file, runner config, or copy | PASS (empty) |

Sub-check 6, ruled by the maintainer (2026-10-20):
- code-fixer and regression-verifier each ran the unmutated baseline and the control as runs of
  their own before their mutants.
- The test reviewer ran its baseline, control and five mutants in one vitest run. The baseline
  passed and the control failed, and its report counts the survivors after stating both.
- The checklist asks for the baseline "running first". test-reviewer.md makes the baseline and
  the control a gate on counting, not on run order, and that gate held. The maintainer counted
  it as passed. The wording gap is recorded in the roadmap.

## Release smoke, row 11 (4.12.0)

4.12.0 changes `skills/autopilot/SKILL.md` (§ How the main session rules), so row 11 ran in full,
as for 4.11.0. Setup:
- Seed `~/Projects/_smoke/row11c-seed`, a clone of the 4.11.0 row-11 seed reset to its first
  commit `c282fd2`, its remote removed.
- One commit `33e0853` points the plan's `Workspace:` at a fresh `~/Projects/_smoke/row11c-ws`.
- The plan is `Acceptance: none`, `Standalone review: on`, `Walk: off`, with S2, S3, S3b and S6
  at sonnet/low. Its version wording is left open on purpose, to force a question.
- Launched as `claude -p "/kenspc-autopilot docs/plans/row11.md" --plugin-dir <repo>/plugins/kenspc
  --permission-mode bypassPermissions --output-format json`.

Cost and time:
- Main session `0159abed-27ec-496e-a207-c72de92475dc`: USD 3.66, 20.4 min.
- Workers, from `row11-costs.txt`: USD 2.44.
- The two small cases: USD 0.63.

| Row 11 item | Result |
|---|---|
| State file holds the `Autopilot settings —` line with `wait headless` | PASS |
| `awk '{print $1, $2}'` over the timeline prints the eight start/end lines for s2, s3, s3b, s6 in order; no resume line | PASS |
| Each `<tag>.exit` exists and holds its `end` line's status (0, four times) | PASS |
| A `question <tag>:` answered with `answer <tag>:`: S2 asked the version wording and was answered `Version 1.1`; S3 and S3b also asked (the batch gate, the review finding T1) and were answered | PASS |
| Every `questions answered:` line ends `(main session)`, and the reviewer report's `Main-session rulings` lists the five rulings | PASS |
| The release commit `9c1087d` `git rm`s `docs/plans/row11.md` and `docs/tasks/row11-tasks.md` and touches no version | PASS |
| Transcript check, below | PASS |
| The final message holds `## User report`, `## Reviewer report` and a total-cost line, and ends `Autopilot finished — 33e0853…9c1087d…` | PASS |
| `row11-costs.txt` has one line per worker (4) | PASS |
| A task document as the argument (`row11c-taskarg`, `/kenspc-autopilot docs/tasks/row11-tasks.md`, USD 0.43): no driver launch in its transcript; it ends `Autopilot stopped: the argument is a task document — run /kenspc-autopilot docs/plans/row11.md` | PASS |
| A prompt opening with the preamble's first sentence (`row11c-preamble`, USD 0.20): its only tool call is `git log -1 --format=%s`; no skill is invoked | PASS |
| `run.sh --self-test` prints `self-test passed`, exit 0; with `AUTOPILOT_CLAUDE` at a stub that prints the result JSON, sleeps 1 s and exits 3, it exits 1 naming `selftest-s1.exit reads 3` | PASS |
| `run.ps1 --self-test` (with `DOTNET_ROOT=$HOME/.dotnet`) prints `self-test passed`, exit 0; the `.ps1` exit-3 stub makes it exit 1 naming `.exit`; a missing executable makes it exit 1 with `self-test failed: run.ps1: no executable …` | PASS |

Transcript check:
- The checklist's `jq` query ran over 22 transcripts: the main session, the four workers, and
  their subagents.
- Its positive control printed exactly `rm -rf dist` and `bash -c 'rm -fr cache'`, and exited
  non-zero (5) with a truncated line appended.
- Every transcript exited 0 and printed nothing, except one line in the main session. That line
  is the `rm -rf` of the batch's own temp entry, `…/T/autopilot-selftest.Jp5UMf`.
- The removal meets the checklist's exception:
  - the path is the one line of `row11-tmp-candidates.txt`;
  - it begins with the state file's `temp:` folder;
  - the reviewer report says `Temp entries: removed 1 of 1 listed`;
  - the user report says the self-test's temp folder was removed.
- No `git push` and no `git tag` in any transcript.

The red cases' own self-test directories (`autopilot-selftest.tYWOtr`,
`autopilot-selftest-dyfmioudcvw`), left by the failing runs, were removed afterwards.
