# Merge danger release smoke (4.13.0)

Release-checklist rows 5, 6, 7, and 11, run headless on 2026-10-21 against
`cb94a4d` with the edited plugin loaded through `--plugin-dir`
(`claude -p "<prompt>" --plugin-dir <repo>/plugins/kenspc --permission-mode
bypassPermissions --output-format json`, launched by
`~/Projects/_smoke/_prompts/ms-run.sh`). The batch itself was implemented and
reviewed on the installed 4.12.1, so these runs are the first sessions to
execute the new text. Each session's transcript holds text only the
repository copy has (`Related plan: \`<PLAN_PATH>\`` for row 5, the
`canonical:merge-danger:start` marker for rows 6 and 7), so the
`--plugin-dir` copy was the one loaded.

Total about USD 13.5: row 5 USD 0.66, row 6 USD 3.72, row 7 USD 3.05, row 11
USD 3.38 for the main session and USD 2.20 for its four workers, the two small
row-11 cases USD 0.49.

## Seeds

- `~/Projects/_smoke/ms-row6-seed`: a Node package (`node --test`, no
  dependencies, no build or lint), `db/migrations/0001_create_users.sql`, a
  plan `docs/plans/drop-legacy-plan.md` whose Risks section names the data
  loss of dropping `legacy_token`, and no `docs/deployment.md`. Base commit
  `39fc3ef`; `44fc2e4` adds `docs/tasks/drop-legacy-tasks.md`, whose tasks
  add a migration that drops the column, remove the `legacyLogin` export,
  read `SESSION_TTL`, and sync the README.
- `~/Projects/_smoke/ms-row5-seed`: a clone of the row-6 seed at `39fc3ef`,
  the plan without the task document.
- `~/Projects/_smoke/ms-row7-seed`: a clone of the 4.12.0
  `code-fixer-trims-smoke` seed at `1b16c8f` (vitest), `node_modules`
  copied in.
- `~/Projects/_smoke/ms-row11-seed`: a clone of `row11c-seed` at `c282fd2`,
  with `045cf11` pointing `Workspace:` at `~/Projects/_smoke/ms-row11-ws`;
  the two small cases in `ms-row11-taskarg` and `ms-row11-preamble`.

## Results

| Row | Session | Result |
|---|---|---|
| 5 `/kenspc-task docs/plans/drop-legacy-plan.md` | `8685f55b-5e07-405c-9206-de76130bcfb6` | PASS |
| 6 `/kenspc-task-implement docs/tasks/drop-legacy-tasks.md` | `7066410a-3150-49af-877d-b4f7a68e4843` | PASS on the 4.13.0 items |
| 7 `/kenspc-task-review` | `af4e5263-bd94-49d1-8f39-eca5aa395e58` | PASS on the 4.13.0 items |
| 11 `/kenspc-autopilot docs/plans/row11.md` | `f0a858fc-a2a2-4de2-b64c-33e939630765` | PASS, after the checklist correction below |

Row 5: one `kenspc:task-document-reviewer` call; Schema E with three rows;
the last task `### Task 3: Doc-sync` with `Depends on: Task 1-2`; the
Context carries ``Related plan: `docs/plans/drop-legacy-plan.md` ``.

Row 6: Schema G holds `## Merge danger` between `## Verdict` and
`## Next steps`. Its header reads `Range: 44fc2e4^..4a5f9c4 (since the task
document was added) · Deployment document: not found · Plan:
docs/plans/drop-legacy-plan.md`, then `Count: 1 one-way, 0 unclear, 2 two-way`.
- Row 1, `one-way`: the migration drops `legacy_token` and its tokens;
  evidence `schema, removal, plan-risk` at
  `db/migrations/0002_drop_legacy_token.sql:1`, the removed
  `export function legacyLogin` (`src/users.js:10` at `44fc2e4^`), and
  `docs/plans/drop-legacy-plan.md:28`, the Risks line.
- Row 2, `two-way`: `SESSION_TTL`; `config, contract` at `.env.example:2`
  and `src/users.js:15-19`.
- Row 3, the catch-all: README, the test file, and the task document, each
  signal 0.
- `git diff --name-status 44fc2e4^..HEAD` lists six files, every one in a
  row, and every cited line holds what the row says.
- The `Reviewers returned —`, `code-fixer returned —`, and
  `regression-verifier returned —` lines open their lines, in order.

Row 7: Schema F holds the section between `## Verdict` and `## Next steps`,
header `Range: a69ebe5..f527e9d (HEAD~1 recorded range, to HEAD, the fix
commits included) · Deployment document: not found · Plan: none named`, one
`two-way` row for the two new exports (`contract` at `src/cart.js:8` and
`src/pricing.js:8`, both `export function` lines), and the catch-all.

Row 11:
- The timeline prints the eight start/end lines for s2, s3, s3b, s6 in order,
  with no resume; each `.exit` reads 0, as its `end` line does.
- S2 and S3 sent `question row11-s2:` and `question row11-s3:`, each answered
  `answer <tag>:`; every `questions answered:` line ends `(main session)`,
  and the reviewer report counts four rulings.
- The release commit `5d4e9db` `git rm`s the plan and the task document only.
- `row11-costs.txt` has four lines.
- The final message holds both reports and a total-cost line, and ends
  `Autopilot finished — 045cf11…5d4e9db…`.
- 4.13.0: the user report's `### Merge danger` follows the rulings list;
  `_logs/row11-merge-danger.md` holds the section; the state file reads
  `merge danger: 0 one-way, 0 unclear, 2 two-way — <that path>`; the
  reviewer report holds `- Merge danger: 0 one-way, 0 unclear, 2 two-way`
  after `- Files changed:`. The spec S6 removed (`docs/plans/row11.md`,
  committed before the baseline) is named in the catch-all row, not as a
  removal.
- Transcript check over 24 transcripts: the positive control printed exactly
  `rm -rf dist` and `bash -c 'rm -fr cache'`, and the truncated control exited
  5 with nothing printed. The only hit is the main session's `rm -rf` of the
  batch's own temp entry `…/T/autopilot-selftest.kA34Pc`, the one line of
  `row11-tmp-candidates.txt`, under the state file's `temp:` folder, with the
  reviewer report's `Temp entries: removed 1 of 1 listed`. No `git push` or
  `git tag`.
- The task document as the argument started no worker and ended
  `Autopilot stopped: task document given, run /kenspc-autopilot
  docs/plans/row11.md`; the preamble prompt's only tool call was
  `git log -1 --format=%s`.
- `run.sh --self-test` and `run.ps1 --self-test` print `self-test passed`
  (exit 0); an exit-3 stub makes each exit 1 naming `selftest-s1.exit reads
  3`; a missing executable makes `run.ps1` exit 1 with `self-test failed:
  run.ps1: no executable …`.

## The row-11 temp-entry item, and the checklist correction

The checklist's exception for that removal asked for "the user report naming
what was removed". The user report said only that nothing was "kept back or
left unremoved". The autopilot skill asks the user report for each temp entry
kept or not removed, with its path, and for a failed removal's path and
error; a removed entry is listed in `_logs/<batch>-tmp-candidates.txt`, and
the reviewer report's `Temp entries` line carries the counts. The checklist
asked for more than the skill does, and 4.12.0's run passed it only because
its user report named the entry unprompted. Ruled in the session
"Matt Pocock v1.3 工作流解析", and approved by the maintainer: the checklist
now asks what the skill asks, so the item passes and no rerun was made.

## Observations

- Row 6's main session printed no `Implementation phase complete.` /
  `Proceeding to code review.` update between the implementer and the
  reviewers. That boundary is row 13's check, and task-implement's Phase 1 is
  unchanged in 4.13.0.
- The autopilot user report condensed each Merge danger row to one sentence,
  the three answers kept; the full rows are in `_logs/row11-merge-danger.md`.
- With `0` + `0`, the closing sentence added "No change in the range is
  one-way or unclear." It names no count and points at no section, so it was
  read as meeting "names how many … exactly when `<n>` + `<u>` is above
  zero".
- Not exercised: the autopilot closing sentence with `<n>` + `<u>` above
  zero (the row-11 seed has no one-way change); the not-determined range
  forms; a `Mode: uncommitted` review.
