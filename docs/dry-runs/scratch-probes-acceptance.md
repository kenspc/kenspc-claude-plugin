# Scratch probes acceptance — run-directory scratch convention (roadmap items 9 and 2, v3.6.0, unreleased)

Acceptance record for roadmap items 9 and 2 (spec:
`docs/plans/roadmap-9-scratch-probes.md`): release-checklist smoke row 7
(`/kenspc-task-review`) with every item of its run-directory check, on the
target project that ruling M7 describes as amended by C12 and C17 (T1). One
run on macOS, 2026-09-25. This file records results; it fixes nothing. One
FAIL was recorded, not repaired (section 6).

Labels: **PASS** — the acceptance criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not applicable** — the criterion
does not apply to this run, with the reason; **Not exercised** — the run did
not reach the condition the criterion tests, with the reason. These are
acceptance labels, not the per-hunk `FLAG` / `PASS` vocabulary of
`docs/dry-runs/README.md`.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `23da544` (clean working tree), loaded with `claude --plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc --permission-mode acceptEdits` (the session process's command line) |
| Claude Code | 2.1.282 |
| Session model | Opus 5.5 (`claude-opus-5-5[1m]`) |
| Effort | `xhigh` (`effortLevel` in user settings) |
| Mode | Interactive TUI; every Agent call ran asynchronously and handed its result back (see O1) |
| Installed copy | `kenspc@kenspc-claude-plugin` 3.5.1 is also `enabled: true` in `~/.claude/settings.json:80` |
| Target project | `/Users/kenspc/Projects/_smoke/roadmap-9`: TypeScript 7.0.2, vitest 5.0.1, Node 24.19.0, npm 12.0.2; `README.md`; no `CLAUDE.md`; no lint or build script (`package.json` scripts: `test` = `vitest run`, `typecheck` = `tsc --noEmit`); `.gitignore` written with CRLF line endings and blank lines and no `.kenspc/` entry |
| Vitest config | `vitest.config.ts` sets only `test: { globals: true }` and keeps the default include (C17 T1). The four test files use `describe` / `it` / `expect` without importing them, so a scratch config that drops the project's config fails: `npx vitest run --globals=false` → `ReferenceError: describe is not defined`, exit 1 |
| Feature | Shopping cart: `src/money.ts`, `src/cart.ts`, `src/discount.ts`, `src/checkout.ts`, one test file each (17 tests) |
| Commits | `87d3c89` scaffold; `e7799d0` feature (the reviewed change); `93eb81c` the skill's `.gitignore` commit; `21afc19` … `6fb3db0` sixteen fix commits |
| Run | `/kenspc-task-review` standalone (`REVIEW_SCOPE: changes`, `TASK_FILE: N/A`); run directory `/Users/kenspc/Projects/_smoke/roadmap-9/.kenspc/runs/20260925-151911-changes` |
| Traces | One JSONL per subagent under `~/.claude/projects/-Users-kenspc-Projects--smoke-roadmap-9/349d6b47-4759-421d-9067-b3d3e84ccdf0/subagents/`; every Bash command, Write, and Edit below was read from them with `jq` |

**Source gate.** With the installed 3.5.1 enabled beside `--plugin-dir`,
only one copy is live. Evidence that it was the repository tree:

- The Skill tool's base directory for `task-review` was
  `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/task-review`.
- The C16 phrase `numbered subdirectory` occurs 0 times in the install
  cache's `skills/task-review/SKILL.md`, `agents/test-reviewer.md`, and
  `agents/code-fixer.md` (`~/.claude/plugins/cache/kenspc-claude-plugin/kenspc/3.5.1/`)
  and once in each repository copy (control: `RUN_DIR` occurs 9 times in
  both copies of the SKILL). The loaded SKILL text contains it.
- Behaviour only the repository copy asks for: every agent wrote into a
  numbered attempt directory, and code-fixer and regression-verifier used
  `scratch/code-fixer/1/` and `scratch/regression-verifier/1/` (3.5.1 puts
  them in `scratch/` itself).

**How the run was driven.**

- `/kenspc-task-review` is `disable-model-invocation: true`, so the session
  invoked `kenspc:task-review` through the Skill tool with no arguments.
- CUSTOM_INSTRUCTIONS carried category-1 structural facts only: "Review the
  changes in commit e7799d0 … against its parent 87d3c89; the later commit
  93eb81c only adds `.kenspc/` to .gitignore and is not part of the review.
  The project has no CLAUDE.md and no lint configuration." It named no test
  command and said nothing about scratch files.
- The skill asked no question in `changes` mode, so the requirement-owner
  role had nothing to answer.
- The same session was the skill's orchestrator and the acceptance driver.
  Criteria met by orchestrator output — the `.gitignore` commit, the Schema A
  roll-up, the Schema F rendering, the verdict, and the Next steps — show
  that the SKILL text can be followed as written; they are not independent
  of a driver that knew the expected result. Criteria met by subagent
  output — scratch naming and layout, the mutation checks, code-fixer's
  configuration abstinence, regression-verifier's commands and Schema C —
  are independent. The orchestrator ran no probe of its own; the driver's
  acceptance checks after the run wrote only to the session scratchpad
  (trace extracts and temp-directory listings), never under the project.

**Environment note.** `~/.gitconfig` sets `core.autocrlf=input`, so git
stores the committed `.gitignore` blob with LF line endings
(`git ls-files --eol .gitignore` → `i/lf    w/crlf`). The CRLF criterion was
observed on the working tree only.

## 2. Smoke row 7 — `/kenspc-task-review`

| Criterion | Result | Evidence |
|---|---|---|
| Five reviewer Agent calls, then the Schema A roll-up, B, C, and Schema F | PASS | Five calls in one message (all five traces start at 15:19:35); Schema A 7 HIGH / 22 MEDIUM / 8 LOW; code-fixer 15:24–15:34; regression-verifier 15:34–15:39; Schema F rendered after it |
| Never logs "Code looks correct, skipping review" | PASS | No such line; dispatch was unconditional |
| Run-directory check passes | FAIL | One bullet fails (section 3, F1); every other bullet and all six sub-checks pass |

Review outcome, for context. code-fixer's statistics line:
`total reported 37 (R 5, E 9, Q 5, B 7, T 11), deduplicated to 17 unique, FIXED 16, DEFERRED 1, NOT APPLICABLE 0, DEDUPED 20`.
The one DEFERRED row is MEDIUM (B5/E4/Q4, `percentOf` rounding at fractional
rates). Schema C rows 1–5 all PASS; verdict PASS. The project had no lint,
so row 4 could not fail (O6).

## 3. Run-directory check (smoke row 7)

| Bullet or sub-check | Result | Evidence |
|---|---|---|
| Headless foreground dispatch | Not applicable | TUI run |
| TUI: no user input between the invocation and Schema F | PASS | No user message from the Skill invocation (15:19) to the Schema F report (15:40); the only cross-session message arrived before the invocation |
| The Fixes section prints the full path of `schema-b.md` | PASS | `/Users/kenspc/Projects/_smoke/roadmap-9/.kenspc/runs/20260925-151911-changes/schema-b.md` |
| The directory holds `angle-1.md`–`angle-5.md` and `schema-b.md`; probes in the per-writer `scratch/` directories | PASS | Top level: `angle-1.md` … `angle-5.md`, `schema-b.md`, `scratch/`. `scratch/` holds `angle-1/` … `angle-5/`, `code-fixer/`, `regression-verifier/`; no `orchestrator/` (the orchestrator did not probe); no file directly under any `scratch/<writer>/` |
| Nothing outside the run directory (such as `/tmp`) was created or deleted for probing | **FAIL** | code-fixer and regression-verifier wrote 10 temporary files into the session scratchpad under `/private/tmp/claude-501/…/scratchpad/` (section 6, F1). The five reviewers wrote nothing outside the run directory |
| Sub-check 1 — the `find` probe over `<RUN_DIR>/scratch` prints nothing | PASS | Section 4, item 1 |
| Sub-check 2 — the project's test command passes unmodified from the root | PASS | Section 4, item 2 |
| Sub-check 3 — no runner, linter, ignore, `tsconfig`, or package-script change | PASS | Section 4, item 3 |
| Sub-check 4 — regression-verifier ran the project's own commands, then listed collected files | PASS | Trace, in order: `npm run typecheck` (15:35:44), `npm test` (15:35:54), `npx vitest list --filesOnly` (15:36:01), and after its own mutation check `npx vitest list --filesOnly` and `npm test` again (15:38:58). No narrowed re-run. No lint command exists; it checked for ESLint, Biome, and oxlint configs and packages and found none |
| Sub-check 5 — nothing under `<RUN_DIR>` deleted; starting over used a new subdirectory | PASS | Section 4, item 4 |
| Sub-check 6 — mutation checks: baseline first and passing under a config rooted at the attempt directory; a control mutant fails first | PASS | Section 5 (four agents) |
| `bash scripts/check-run-contract.sh --file <schema-b.md>` exits 0 | PASS | `OK    schema-b recount — …/schema-b.md agrees with its rows`, exit 0 |
| `.gitignore` without `.kenspc/`: exactly one commit before dispatch, touching only `.gitignore`, line endings kept | PASS (working tree) | `git check-ignore -q .kenspc/runs/probe` exit 1 → `93eb81c chore: ignore kenspc run directory`, 1 file changed, 1 insertion; `od -c` of the working-tree file ends `\r \n \r \n . k e n s p c / \r \n`; re-check exit 0. See the environment note: the stored blob is LF |
| A second run adds none | Not exercised | Single run per M7; covered by batch A round 2 (`batch-a-acceptance.md` § 5, "A second run adds none", PASS, HEAD `de8c1cb` before and after) |

## 4. Acceptance items for this batch

The six criteria of this smoke's brief; items 1–3 are the checklist's
sub-checks 1–3, item 6 is sub-check 6.

| # | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | After the run, the checklist probe over `<RUN_DIR>/scratch` prints nothing | PASS | `<RUN_DIR>/scratch` exists (791 files). `find <RUN_DIR>/scratch \( -name '*.test.*' -o -name '*.spec.*' -o -name 'test.*' -o -name 'spec.*' -o -path '*/__tests__/*' -o -path '*/__mocks__/*' \)` printed nothing, exit 0. Control: the same expression over the project's `test/` finds 4 files |
| 2 | `npm test` passes unmodified from the project root; lint and build too, if defined | PASS | 15:40:15, after the run: `npm test` → `Test Files  4 passed (4)`, `Tests  36 passed (36)`, exit 0; `npm run typecheck` exit 0; `npx vitest list --filesOnly` lists only `test/cart.test.ts`, `test/checkout.test.ts`, `test/discount.test.ts`, `test/money.test.ts`. The project defines no lint or build script |
| 3 | No agent created or modified runner configuration or ignore files | PASS | `git status --short` empty. The sixteen fix commits touch only `src/*.ts` and `test/*.test.ts`. The only configuration or ignore file changed after `e7799d0` is `.gitignore`, by `93eb81c` — the orchestrating skill's one-time commit before dispatch, which sub-check 3 excludes. code-fixer's Write/Edit targets: the four `src/` and four `test/` files, `schema-b.md`, three files in `scratch/code-fixer/1/`, and `check.sh` in the session scratchpad (F1) |
| 4 | Scratch layout in numbered attempt directories; `/2/` where an agent started over; nothing deleted | PASS | Attempts: `angle-1/1/`, `angle-2/1/` and `/2/`, `angle-3/1/`, `angle-4/1/`, `angle-5/1/` and `/2/`, `code-fixer/1/`, `regression-verifier/1/`. The two `/2/` directories are new attempts for a second probe (angle-2 `rates.probe.ts`, angle-5 `behavior.probe.ts`), not a retry after failure. Delete scan of all seven traces — every Bash command with newlines flattened, and the scripts the agents wrote and ran — for `rm`, `rmdir`, `unlink`, `mv`, `-delete`, `git clean`, `rmSync`, `unlinkSync`, `renameSync`: one hit, regression-verifier's `rv-mutate.mjs`, which copies `test/` into a mutant directory and renames each `*.test.ts` to `*.probe.ts` inside it after checking that the target does not exist (a rename onto a new path in its own scratch directory; not a delete under C14). Scan controls: a flattened `cd x\nrm -rf y` hits, `npx vitest run --reporter` does not |
| 5 | Schema C row 3 Detail quotes the project's own test command; collected passing `.kenspc/` files, if any, are named and get a Next steps deletion bullet | PASS | Row 3, verbatim: "`npm test` (`vitest run`) exited 0 with 4/4 files and 36/36 tests passing. … `vitest list --filesOnly` collected only test/cart.test.ts, test/checkout.test.ts, test/discount.test.ts and test/money.test.ts, with no `.kenspc/` paths. I checked this again after my own scratch probes were written, when 288 `*.probe.ts` files existed under `.kenspc/`." No `.kenspc/` file was collected, so the deletion bullet was **not exercised**; Next steps correctly has none |
| 6 | Where an agent ran a mutation check: an unmutated baseline rooted at that attempt directory ran first, and a control mutant failed | PASS | Four agents ran one; section 5 |

## 5. Mutation checks (sub-check 6)

Four agents ran a mutation check. Each scratch config sets `globals: true`
itself, roots at the attempt directory, and includes only renamed copies.

| Agent | Attempt directory and config | Baseline (unmutated) | Control mutant | Then |
|---|---|---|---|---|
| requirements-reviewer (angle 1) | `scratch/angle-1/1/`, `vitest.probe.config.mts` (`root` = that directory, include `suite/**/*.check.ts`, `probe/**/*.probe.ts`); tests copied as `suite/*.check.ts` | 15:21:08, `--config` of that directory: `Test Files  4 passed (4)`, `Tests  17 passed (17)`, exit 0 | `control-subtotal` (`total += 0;`) first in `mutate.sh`: "KILLED (exit 1) Tests  3 failed \| 14 passed (17)" | 5 mutants, all SURVIVED, reported as findings (see O3) |
| test-reviewer (angle 5) | `scratch/angle-5/1/`, `probe-vitest.config.mts` (`root` = that directory, include `test/**/*.probe.ts`) | 15:21:09: 4 files, 17 tests passed, exit 0 | `C1-control` (`parseAmount` + 1) and `C2-control` (`return 0` in `subtotal`) first in `mutate.mjs`: both KILLED | 19 mutants, 7 killed, 12 survived |
| code-fixer | `scratch/code-fixer/1/`, `probe.config.mts` (`root` = that directory, include `**/*.probe.ts`, each run filtered to one copy) | 15:32:10, copy `base/`: "base: status=0 files=4 passed (4) tests=36 passed (36) loadError=false"; the script exits with "mutation check not made" if the base fails | `ctl-01-subtotal-zero`: "KILLED … tests=6 failed \| 30 passed (36)" | 28 mutants, all killed, none by a load error |
| regression-verifier | `scratch/regression-verifier/1/`, `rv-probe.config.mts` (`root` = that directory, include `**/*.probe.ts`, each run `--dir <copy>`) | 15:38:07, copy `base/`: "exit=0 total=36 failed=0 files=4 outside=0 BASE OK"; the script stops if the base is not OK | `ctl-subtotal-zero`: "exit=1 total=36 failed=6 files=4 outside=0 KILLED" | 38 mutants, 1 survived (`b4g-min-negative-ok`, reported as LOW) |

The control mutants prove each run exercised the copy: if the copied tests
had imported the project's `src/`, every control would have passed. The
baselines prove the scratch configs kept `globals: true`: without it every
file fails with `describe is not defined` (section 1).

## 6. FAIL F1 — temporary files outside the run directory

**Criterion.** Run-directory check: "Any probe or temporary files are under
its `scratch/` subdirectory — … code-fixer's in `scratch/code-fixer/`,
regression-verifier's in `scratch/regression-verifier/` …; nothing outside
the run directory (such as `/tmp`) was created or deleted for probing."

**Evidence.** Files the two worker agents created in the session scratchpad
`/private/tmp/claude-501/-Users-kenspc-Projects--smoke-roadmap-9/349d6b47-4759-421d-9067-b3d3e84ccdf0/scratchpad/`
(none deleted):

| Agent | Files | How |
|---|---|---|
| code-fixer | `check.sh` (15:27:32), `vt.log`, `tsc.log` | `check.sh` written with the Write tool: "Runs the project's test suite and typecheck; prints each command's own exit status", with `LOGDIR=/tmp/claude-501/…/scratchpad`; run 16 times as the gate for every fix commit and the final check (15:27:47–15:32:27) |
| regression-verifier | `typecheck.log`, `test.log`, `list.log`, `report_ids.txt`, `b_ids.txt`, `list2.log`, `test2.log` | Shell redirection, e.g. `npm test > /private/tmp/claude-501/…/scratchpad/test.log 2>&1` |

The five reviewers never referred to a temporary directory (count of
commands and file paths matching `scratchpad`, `/tmp/`, `/private/tmp`,
`TMPDIR`, `/var/folders`, `os.tmpdir`, or `mktemp`: 0 each; code-fixer 18,
regression-verifier 5; control string hits).

**Cause, as far as the run shows.** The scratchpad path carries this
session's id and appears nowhere in the CONTEXT block the agents received
(`grep -c scratchpad` over code-fixer's first user message → 0), so it came
from the harness's own instructions to subagents, which tell them to use a
session scratchpad for temporary files instead of `/tmp`. Both agents
followed that over their `RUN_DIR` bullet for log and helper files, while
putting every probe, copy, and mutant under their own `scratch/<agent>/1/`.
The bullet's naming and reset rules held; its placement rule did not.

**Precedent.** The same behaviour occurred in batch A, and that run's check
did not see it, so F1 is not introduced by this batch. Every subagent trace
of both runs (21 of 21 in batch A, 7 of 7 here) carries an `environment`
attachment that names the session scratchpad and says "always use it for
temporary files (intermediate results, scripts, outputs that don't belong
in the project) instead of `/tmp` or other system temp directories". Batch
A's scratchpad,
`/private/tmp/claude-501/-Users-kenspc-Projects--smoke-batch-a/1310266b-f51b-4aba-8701-fd5752fe1ece/scratchpad/`,
still holds 58 entries written on 2026-09-24 between 19:07 and 20:06. Each
is attributed below to the one transcript whose tool calls name it (batch A
traces under
`~/.claude/projects/-Users-kenspc-Projects--smoke-batch-a/1310266b-f51b-4aba-8701-fd5752fe1ece/`):

| Writer in batch A | Entries |
|---|---|
| task-implementer, round 1 | `bill.ts.bak`, `split.ts.bak`, `balance.ts.bak`, `settle.ts.bak` (19:12–19:16): copies of the project's own `src/*.ts`, taken before it mutated those files in place with `sed -i` for a mutation check and restored them with `cp` |
| task-implementer, round 2 | `bill.ts.orig`, `split.ts.orig` (19:39–19:40), the same in-place pattern, with `m1.txt`–`m5.txt` holding the mutants' test output; `package.json.orig`, `package-lock.json.orig`, copies taken before the failing `npm install`; 8 test, typecheck, and install logs (`baseline-test.txt`, `t1-test.txt`, `t3-install.txt`, …) |
| code-fixer, round 1 | `check.sh` (19:27:56) and 6 logs (`test.txt`, `unscoped.txt`, `base-test.txt`, …) |
| code-fixer, round 2 | 22 logs (`base-test.log`, `t1.log`–`t10.log`, `tc1.log`–`tc10.log`, `list-before.log`, `list-after.log`, …) |
| plan-document-reviewer | `check.mjs`, written by the plan review (19:01) and written over by negative case a (20:06) |
| task-document-reviewer | `ordercheck/`, holding `order.test.js` (task review); `before.txt`, `after.txt` (negative case b) |
| the batch A driver session | `evidence.md`, `neg-b.md`, `neg-c.md`, `round1/` |

The ten reviewer runs, both regression-verifier runs, and the negative
case c task-document-reviewer named the scratchpad in no tool call. Batch
A § 5 recorded "Nothing outside the run directory created or deleted for
probing" as PASS because it listed only `/private/tmp`'s top level and
passed over `claude-501/` as Claude Code's own session directory
(`batch-a-acceptance.md:166`). This run found F1 by reading the traces.

**Impact.** No project file, no test collection, and nothing under the run
directory is affected; the files do not survive the session's temp
directory. The failure is against the letter of the run-directory check.
How to classify it (plugin defect, harness conflict, or checklist wording)
is left to the maintainer. The maintainer classified it on 2026-09-25 as
checklist wording — the release checklist is amended in a separate commit
to require probes, copies, mutants, and runner configs under
`RUN_DIR/scratch` while allowing logs and helper scripts in the harness's
per-session scratchpad.

## 7. Observations

**O1 — the Agent tool on Claude Code 2.1.282.** The checklist and CLAUDE.md
describe the interactive Agent tool as it was on 2.1.281. On 2.1.282 it
still has no `run_in_background` parameter (its parameters are
`description`, `prompt`, `subagent_type`, `model`, `isolation`), and it
still runs subagents asynchronously: every call returned "Async agent
launched successfully", and each result came back as a hand-back message
followed by a task notification. The sentence still holds on 2.1.282; it
needs re-checking whenever the version changes.

**O2 — `schema-b.md` carries a section outside its contract.** Between the
Deferred Issues prose and the statistics line, code-fixer wrote a
`## Verification` paragraph (final `npm test` and `typecheck` results, and
its mutation-check summary). code-fixer's OUTPUT FORMAT lists five parts in
order — Fixes Applied, Per-angle Results, Deferred Issues, the
scratch-pollution note when there is one, the statistics line — and no
verification section. `check-run-contract.sh --file` recounts rows only, so
it passed. The reply rendered in Schema F did not include the paragraph.

**O3 — angle 1 roots each mutant's config at the mutant directory.**
`mutate.sh` copies `src/`, `suite/`, and the config into
`scratch/angle-1/1/mutants/<name>/` and runs each mutant with that copy of
the config, whose `root` resolves to the mutant directory, a subdirectory of
the attempt. The baseline ran with the attempt-level config (`root` =
`scratch/angle-1/1/`). Both roots collect only files of this attempt, and
the surviving mutants' 17/17 passes show the per-mutant config runs the
full suite. Not a FAIL under C8 or sub-check 6; recorded because the
baseline and the mutants did not run under the same config file.

**O4 — regression-verifier copies, then renames.** `rv-mutate.mjs` copies
the project's `test/` into each mutant directory with its `*.test.ts` names
and renames them to `*.probe.ts` in the next statement. For that moment
collectable names existed under `scratch/regression-verifier/1/`; a runner
started from the project root then would have collected them. M3 asks for
the rename "as they are copied"; code-fixer did it that way (`copyFileSync`
to the `.probe.ts` name). The end state passes sub-check 1.

**O5 — a `node_modules` directory inside scratch.** code-fixer's
`probe.config.mts` sets no `cacheDir`, so vite put its cache at
`scratch/code-fixer/1/node_modules/.vite/`. The other agents set `cacheDir`
(`.cache`, `.vite-cache`). Harmless; noted because ruling M3 rejected
`node_modules` as a hiding place for copies, and this one holds only a
cache.

**O6 — the lint and build paths of C5 were not exercised.** The project
defines no lint and no build script. regression-verifier ran
`npm run typecheck` as the build equivalent (it lists no `.kenspc/` file:
`tsc --listFilesOnly` → 0 matches) and reported row 4 PASS with "This PASS
means nothing was there to fail." Whether a linter walking into `.kenspc/`
produces a loud FAIL is untested by this run.

**O7 — `$TMPDIR` gained vite caches, as in batch A.** Between 15:18:47 and
the end of the run, 148 entries appeared in `$TMPDIR`: 138 `<nanoid>/ssr/`
directories (613 sha1-named files; vite's SSR transform cache, one per
vitest process, the driver's own runs included), and 10 sockets or caches
of other processes (MCP, VS Code, and another session's remember plugin).
No probe file. `/private/tmp`'s top level did not change; F1's files are
inside Claude Code's own session directory there. Inside the project, only
vitest's and vite's own state under `node_modules/` changed:
`node_modules/.vite/vitest/<hash>/results.json` and the empty
`node_modules/.vite-temp/`, both present before the run (15:18:28, the
driver's pre-run test) and last touched by the driver's post-run
`npm test` (15:40:16).

## 8. Summary

| Item | Result |
|---|---|
| Precondition: source gate (repository tree loaded) | PASS |
| Smoke row 7: five reviewers, Schema A → B → C → F, no skip | PASS |
| Run-directory check, as a whole | FAIL (F1 only) |
| 1 Checklist `find` probe over `<RUN_DIR>/scratch` prints nothing | PASS |
| 2 `npm test` (and `typecheck`) pass unmodified from the root | PASS |
| 3 No agent changed runner, linter, ignore, `tsconfig`, or package-script configuration | PASS |
| 4 Numbered attempt directories; `/2/` for new attempts; nothing deleted | PASS |
| 5 Row 3 Detail quotes `npm test`; collected-file deletion bullet | PASS (the bullet not exercised: nothing collected) |
| 6 Mutation checks: baseline first under an attempt-rooted config, control mutant fails | PASS (four agents) |
| Sub-check 4: verifier's unmodified commands and collected-file listing | PASS |
| `check-run-contract.sh --file` | PASS |
| `.gitignore` one commit before dispatch, CRLF kept | PASS (working tree) |
| Nothing outside the run directory created for probing | FAIL (F1) |
| A second run adds none | Not exercised |
| Headless foreground dispatch | Not applicable |

The batch's falsifiable checks — the ones batch A § 8 failed (68
collectable files, a failing bare `npm test`, a config file added by
code-fixer) — all came back clean. One FAIL (F1, temporary files in the
session scratchpad) and seven observations (O1 Agent tool on 2.1.282; O2
extra `schema-b.md` section; O3 per-mutant root; O4 copy-then-rename; O5
`node_modules` cache in scratch; O6 lint and build untested; O7 `$TMPDIR`
caches).
