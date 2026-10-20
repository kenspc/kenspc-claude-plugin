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
- **The orchestrator's final report dropped log paths that its sources carry.** This is outside
  this plan's scope.
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
