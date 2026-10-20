# Plan: cut code-fixer's check overhead (T1, T2, T3, T4a)

## Objective

Cut the time code-fixer spends on checks — mutation checks, whole-suite runs, Acceptance
sweeps, and the waits on them — while each rule behind them keeps the failure it prevents
caught. Four changes, from the analysis in
`~/Projects/_smoke/_analysis/review-time-20261019/followup/fixer-trims/README.md`:

- **T1** — mutation checks: one per finding that reports a surviving mutant, on the reviewer's
  rig; what a ruling asks for; at most three of code-fixer's own per run; no re-sweep.
- **T2** — the autopilot main session's rulings stop asking code-fixer for batch-wide
  Acceptance or mutation sweeps that S4 and regression-verifier already run.
- **T3** — per-fix checks narrowed to the code the fix touched; the whole suite once, after the
  last fix.
- **T4a** — the final whole run stays; a command it repeats on the same tree is not run again.

Out of scope:
- T5 (a shorter Schema B) — left out by the maintainer's decision, 2026-10-20.
- code-fixer still fixes LOW findings, and the Standalone review default (cea1910) is unchanged.
  Both were decided elsewhere.
- regression-verifier, the five reviewers, task-review, task-implement, and the Schema B
  format are unchanged.
- Which of CUSTOM_INSTRUCTIONS and `rulings.md` wins when they conflict on a check is not
  decided here (Open Questions 1).

## Background

The analysis covered 99 code-fixer dispatches in dayaku-crm batches, 2026-09-29 to 2026-10-19.
They took 31.6 h of wall time, about 21% of those batches' 151.5 h. Time was charged by
purpose: each tool call's duration plus the model gap before it, 28.2 h in all.
- Checks of one kind or another took about 45–50% of code-fixer's time: mutation checks 15.5%,
  build / test / lint 13.1%, waiting loops on background checks 8.8%, Acceptance re-runs 3.1%,
  and check rigs 4%. The 46 dispatches from 2026-10-12 show the same shape.
- Reading the reports took 1%, and the fixes themselves (edits) about 9%.
- No waiting loop waited for dayaku-crm's planning-session go. They waited for background
  mutation or Acceptance sweeps; one ran to its 580 s cap.

Where the checks came from:
- **Mutation checks.**
  - 30 of the 68 `rulings.md` files asked for them.
  - In 3 of the 8 hand-read dispatches, code-fixer re-ran the test reviewer's mutants, or made
    up its own, with no ruling asking.
  - code-fixer.md says how to run a mutation check (the RUN_DIR paragraph), but not when, and
    sets no cap. task-implementer caps its own at three per task.
- **Acceptance sweeps.**
  - 41 of the 68 rulings named Acceptance commands, some all 33 of them ("at the final HEAD all
    33 Acceptance commands pass").
  - The batches' locked designs said every Acceptance command passes again afterwards, and the
    main session rules by the locked design.
  - S4 then runs every case anyway.
- **Per-fix whole suites.**
  - code-fixer.md says "Run build/test/lint after each fix", with no breadth and no Why.
  - Some runs wrapped lint, the type check and the whole suite into a script that they ran
    before every commit: 16 whole suites in one round of 18 commits.
  - The RUN_DIR paragraph's sentence on narrowing reads as "never narrow". It is about
    `.kenspc/` pollution only.
- **Final run.** The final whole build / test / lint is kept, since it is the only check of how
  the fixes interact before regression-verifier. Two samples repeated it on the same tree,
  about 5 minutes in one dispatch:
  - a related-tests run followed by the whole suite;
  - a verify script followed by Acceptance commands 1–3, which run the same suite.

The estimated savings are readings and overlap: T1 2–3 h, T2 1.5–2.5 h and T3 1–1.5 h of 28 h;
T4a is small.

## Technical Approach

All four are prompt edits, rationale-anchored (AGENTS.md Rule 2: each rule carries its Why).
No guard script reads the paragraphs changed.
- `check-run-contract.sh` reads code-fixer.md's file names, the stats line and the Schema B
  example.
- `check-code-craft-canonical.sh` reads the CODE-CRAFT block.
- Neither block is touched.

**T1 — why "the finding's mutant, on the reviewer's rig".**
- A test reviewer's finding of this kind is itself a measured mutant, and the reviewer keeps its
  rig under `RUN_DIR/scratch/angle-<n>/`: the mutant script and a `diff-<m>.txt` per mutant in
  the recent runs.
- Killing that mutant with the new test is the proof the fix needs.
- The fixer reuses the mutant's definition (its diff or script), not the reviewer's copy of the
  tree. That copy predates the fix, so it would test the old code.
- The check runs in the fixer's own numbered attempt directory, because the RUN_DIR paragraph
  gives each agent and attempt its own runner root.
- The three steps (unmutated pass, control mutant, then the mutant) still apply to every check
  made.
- Rejected: no own checks at all. It saves most, but leaves a test the fixer wrote and doubts
  with no proof but regression-verifier's optional check 4.
- Rejected: no cap. That is today's behavior.
- The cap of three per run matches task-implementer's per-task cap (maintainer's choice,
  2026-10-20).
- A test left unchecked under the cap says so in its row, `not mutation-checked`, as
  task-implementer's Test map says `(unchecked)`.

**T2 — why in the main session, not in code-fixer.**
- code-fixer carries out a FIX ruling's text as written ("A FIX ruling's text bounds the fix").
  A sweep the ruling asks for is therefore binding, and code-fixer.md cannot cut it without
  breaking that rule.
- The cut belongs where the ruling is written: autopilot SKILL § How the main session rules.
- What protects the batch is unchanged:
  - S4's first run, in Phase 3, runs every `Acceptance:` case after Phase 2's last fix, on the
    S3b HEAD (or S3's when S3b does not run).
  - regression-verifier runs the whole build, test and lint right after code-fixer.
- A locked point that every Acceptance command passes after the fixes is met by S4's run, so a
  ruling that leaves the sweep to S4 does not depart from it.
- The rule covers only the reviews S4's first run follows: S3's review, S3b, and the narrowed
  reviews of Phase 2. A narrowed review in Phase 3 (after an S5 that fixed an acceptance FAIL)
  is followed by an `-s4b` run of the failed case alone (autopilot SKILL § Phase 3,
  Classification), so no full sweep follows its code-fixer, and its rulings keep today's
  behavior (Open Questions 3).
- Exception: with `Acceptance: none` there is no S4 run, and the ruling may ask for what the
  spec names.

**T3 — why "the code the fix touched".**
- A broken fix found at once is withdrawn alone; found later, it is tangled with the fixes on
  top of it. That is the rule's purpose, and the touched code's tests serve it at a fraction of
  a whole suite's cost.
- Interaction breakage shows only in a whole run, which T4a keeps after the last fix.
- The narrowing is defined without naming a framework (AGENTS.md: stack-agnostic): the build or
  type check, lint on the changed files, and the test files that exercise the changed code — the
  tests the fix added or changed, and the test files that import or call the changed module.
- The RUN_DIR sentence that warns against narrowing (`--dir test` drops tests kept beside the
  source) is reworded to bind the final run, which is the run code-fixer reports as its
  verification.

**T4a — why keep the final whole run.**
- The orchestrator's `suite-run.md` ran before the fixes and cannot stand in for it.
- Leaving it to regression-verifier alone (option T4b) would turn an interaction break into
  HAS ISSUES and a second round, which costs more than the run saved.
- What goes is the same commands run twice on the same tree. A second run there can only give
  the same answer.

## Implementation Steps

Each step edits files only; nothing is committed until the maintainer asks (global and project
rules). The edits are made in a session started without `--plugin-dir` (CLAUDE.md).

### Step 0 — Confirm the base

- Do: run `git -C <repo> status --short`, then for each file below
  `git -C <repo> log -1 --format=%h -- <file>`.
- Input: the repository at `3d2a696`, or at a later commit whose commits since `3d2a696` touch
  only this plan (`git -C <repo> diff --name-only 3d2a696 HEAD` lists only
  `docs/plans/code-fixer-trims.md`).
- Output: the status and four hashes.
- Acceptance:
  - the tree is clean (the plan is committed by its review);
  - the hashes are the ones at planning time:
    - `plugins/kenspc/shared/code-craft-principles.md` `0051d0e`
    - `plugins/kenspc/agents/code-fixer.md` `bb42780`
    - `plugins/kenspc/skills/autopilot/SKILL.md` `cea1910`
    - `plugins/kenspc/README.md` `b73233b`
  - A different hash means another session changed the file: stop, read its diff, and revise
    the affected step before Step 1.

### Step 1 — code-fixer.md: per-fix and final checks (T3, T4a)

- Do:
  1. Replace the last PROCESSING APPROACH bullet ("Run build/test/lint after each fix to catch
     breakage early; run it once more after all fixes to catch interaction issues.") with two
     bullets:
     - **After each fix:** the project's build or type check, its lint on the files the fix
       changed, and the test files that exercise the changed code — the tests the fix added or
       changed, and the test files that import or call the changed module. No whole suite after
       a single fix. When the project's test runner cannot run selected files, its whole test
       command runs instead; when its linter takes no file arguments, its whole lint command
       does. Why: a broken fix found at once is withdrawn alone, while one
       found later is tangled with the fixes made on top of it, and the touched code's tests
       find it at a fraction of a whole suite's cost; one run wrapped lint, the type check and
       the whole suite into a script it ran before each of its 18 commits.
     - **After the last fix:** the project's build, test and lint commands once, whole, as the
       project configures them — the run the `Final checks:` line reports. A command that run
       repeats on the same tree is not run again before or after it: a related-tests run just
       before it, or an Acceptance command that runs the same suite. Why: interaction breakage
       between fixes shows only in the whole run, and a second run of the same commands on the
       same tree can only give the same answer.
  2. In the RUN_DIR paragraph, change "verify your fixes with a narrowed command if you need to,
     narrowed only to leave out `.kenspc/`" so that it governs the final whole run. The `.kenspc/`
     exclusion stays the only narrowing allowed there; the per-fix checks are narrowed as
     PROCESSING APPROACH says. Keep its Why. Its `--dir test` sentence then reads as a reason
     about the final run.
  3. In DONE CRITERIA, change "A final build / test / lint run was performed after the last fix"
     to name a whole run as the project configures it, with the `.kenspc/` exclusion as the only
     narrowing.
  4. In OUTPUT FORMAT's Scratch-pollution note paragraph, change "the narrowed command you used
     to verify your fixes" to name the final whole run's `.kenspc/`-excluding command. Why: once
     per-fix checks are narrowed by design, "the narrowed command" no longer says which one the
     note lists.
- Input: code-fixer.md at Step 0's commit.
- Output: the edited file.
- Acceptance:
  - `grep -c 'after each fix to catch breakage early' plugins/kenspc/agents/code-fixer.md`
    prints 0, after printing 1 before the edit;
  - `grep -c 'the narrowed command you used' plugins/kenspc/agents/code-fixer.md` prints 0,
    after printing 1 before the edit;
  - the new bullets each carry a `Why:`;
  - `bash scripts/check-all.sh` exits 0.

### Step 2 — code-fixer.md: mutation checks (T1)

- Do:
  1. Add a PROCESSING APPROACH bullet, after the per-fix bullet of Step 1:
     - A fix for a finding that reports a surviving mutant is proved by running that mutant
       against the new or changed test. Take the mutant's definition from the reporting
       reviewer's rig under `RUN_DIR/scratch/angle-<n>/` — its diff or the script that applies
       it — and apply it to a copy of the tree at the fix's commit, in your current attempt
       directory, under the RUN_DIR paragraph's three steps. Do not run the reviewer's own copy
       of the tree: it predates the fix. When the rig keeps no usable definition, write the
       mutant from the finding's description; it is still the finding's own check, not one of
       the three below.
     - A mutation check a ruling asks for is run as the ruling says.
     - Beyond these, where you are unsure a test you wrote fails when the fixed code breaks,
       prove it with a mutation check, at most three per run. A further unsure test's row
       carries `not mutation-checked` after the em-dash.
     - A mutant already run in this run is not run again unless the code it mutates changed
       after that run.
     - Whether "run" here spans a second fix round is Open Questions 4; the bullet states the
       maintainer's answer.
     - Why:
       - the reviewer measured the finding's mutant, so killing it is the proof the fix needs,
         and its rig is already built;
       - one run swept 33 mutants again at the end, each already killed during the fixes,
         which took four minutes of whole-suite runs;
       - the cap is task-implementer's, which keeps the checks from exhausting the run.
  2. In the PER-ISSUE OUTPUT CONTRACT `action` field, add the form
     `FIXED — not mutation-checked`, joined with other parts by `; ` as the existing forms are.
     State that counts still classify by the leading word.
- Input: code-fixer.md after Step 1.
- Output: the edited file.
- Acceptance:
  - `grep -c 'at most three per run' plugins/kenspc/agents/code-fixer.md` prints 1;
  - `grep -c 'not mutation-checked' plugins/kenspc/agents/code-fixer.md` prints at least 2 (the
    bullet and the contract);
  - the Schema B example between the `example:schema-b` markers is unchanged
    (`git diff -U0` shows no hunk there);
  - `bash scripts/check-all.sh` exits 0.

### Step 3 — autopilot SKILL.md: rulings on a review's findings (T2)

- Do: in § How the main session rules, after the paragraph on departing from a spec sentence,
  add a paragraph headed **A ruling on a review's findings.** Its content:
  - A FIX entry in `rulings.md` names the change and, at most, the checks of the code it
    touches: the Acceptance commands, or the reviewer's mutants, whose files the fix edits.
  - When the `Acceptance:` field names cases, a ruling in a review that S4's first run follows —
    S3's review, S3b, or a narrowed review of Phase 2 — does not ask code-fixer to run every
    Acceptance command again, or every mutant. S4 runs every case after Phase 2's last fix, and
    regression-verifier runs the whole build, test and lint after code-fixer.
  - A spec sentence or locked point that every Acceptance command passes after the fixes is met
    by S4's run.
  - A narrowed review in Phase 3 is followed only by an `-s4b` run of the failed case, so its
    rulings are not bound by this paragraph.
  - With `Acceptance: none` there is no S4 run, and a ruling may ask for the commands the spec
    names.
  - Why: in one product's batches, 41 of 68 rulings asked code-fixer to re-run Acceptance
    commands, up to all 33 of them, and 30 asked for mutation re-runs. The sweeps ran one at a
    time after the last commit, made up most of code-fixer's waiting, and repeated what S4 and
    regression-verifier ran next.
- Input: autopilot SKILL.md at Step 0's commit.
- Output: the edited file.
- Acceptance:
  - the paragraph sits inside § How the main session rules;
  - it names S4 and regression-verifier, and the Phase 3 narrowed review it leaves out;
  - it carries a `Why:`;
  - `git -C <repo> diff -U0 -- plugins/kenspc/skills/autopilot/SKILL.md` shows one hunk, inside
    § How the main session rules (the file carries no rulings grammar block, so
    `check-run-contract.sh` does not read it);
  - `bash scripts/check-all.sh` exits 0.

### Step 4 — Documentation

- Do: the edits listed under Documentation impact.
- Input: Steps 1–3 done.
- Output: the edited documents.
- Acceptance:
  - each listed document's change is present;
  - the CHANGELOG entry lists every change with its reason (AGENTS.md: review summaries list
    every change and why) and cites the analysis directory as its evidence.

### Step 5 — Mechanical checks

- Do: run
  - `bash scripts/check-all.sh --self-test`
  - `claude plugin validate --strict .`
  - `claude plugin validate --strict ./plugins/kenspc`
- Input: Steps 1–4.
- Output: each command's exit code and its summary lines.
- Acceptance: all three exit 0.

### Step 6 — Smoke: one task-review run on a seed

- Do:
  1. Make a seed under `~/Projects/_smoke/code-fixer-trims-smoke/`: a git repository holding a
     small Node project with vitest and two source files, whose `package.json` gives `build`,
     `test` (`vitest run`) and `lint` scripts, each exiting 0. Commit it as the base commit.
  2. Commit, as one commit on top of the base, a change that adds:
     - a function with a branch its new test does not hold, so the test reviewer finds a
       surviving mutant;
     - a second defect in the other file, a plain bug.
     With the tree clean, task-review's default range is then `HEAD~1..HEAD`, this commit.
  3. Run `/kenspc-task-review` on that change from a headless session in the seed:
     `claude -p "/kenspc-task-review" --plugin-dir <repo>/plugins/kenspc --permission-mode
     bypassPermissions --output-format json`, so the edited agents run and the JSON carries the
     session id and `total_cost_usd`. A session without `--plugin-dir` runs the installed
     4.11.0 copy; a headless session in the default permission mode has its Bash and Edit calls
     denied, since nobody can approve them.
  4. Read code-fixer's transcript and the run directory.
- Expected cost: USD 3–5, by the 4.11.0 row-6 smoke runs.
- Input: the edited plugin.
- Output: a record at `docs/dry-runs/code-fixer-trims-smoke.md`, with the run directory path,
  the cost, and each check below as observed.
- Acceptance, each checked from the transcript or run directory; a check that cannot be judged
  is recorded as such, not as a pass:
  1. The mutant fix's check reuses the reviewer's mutant: the mutant's diff or script, read from
     `scratch/angle-5/`, is applied to a copy of the tree at the fix's commit under
     `scratch/code-fixer/<n>/`. The unmutated pass, the control and the mutant runs are logged
     there.
  2. code-fixer ran at most three mutation checks of its own beyond the named mutant.
  3. Each per-fix test command names test files; no whole-suite test command runs before the
     last fix commit.
  4. One whole build, test and lint run follows the last fix commit. A second one is allowed
     only after a fix was withdrawn because the first one failed.
  5. The reply carries the `Final checks:` line naming those commands.
  6. regression-verifier returns CLEAN.
  - If the test reviewer reports no surviving mutant, check 1 cannot be judged. Then change the
    seed so that it does and run again, at most once more, before recording.
  - A check that fails is recorded as FAIL with the transcript or run-directory evidence, and
    the plan stops there: the record goes to the maintainer, who decides whether Steps 1–3 are
    revised and Steps 5–6 run again.

Dependencies: Step 0 first. Steps 1 and 2 edit one file, so they run one after the other.
Step 3 is independent of Steps 1–2. Step 4 needs 1–3. Step 5 needs 4. Step 6 needs 5.

## Documentation impact

- `plugins/kenspc/README.md`, the run-directory bullet that describes code-fixer's
  `Final checks:` line (it begins "code-fixer's reply carries, after its other lines and before
  the Per-angle Results table"). Add that:
  - the final line reports one whole run after the last fix;
  - per-fix checks cover the touched code;
  - a mutant a reviewer reported is proved on the reviewer's rig, with at most three of
    code-fixer's own checks per run and `not mutation-checked` on a row past the cap.
  - Steps 1–2.
- `plugins/kenspc/README.md`, the Autopilot section's paragraph on rulings in a review (it
  begins "A worker running a review — S3's review phase, S3b, or a narrowed review —"). Add
  that the main session's rulings in S3's review, S3b, and Phase 2's narrowed reviews leave
  batch-wide Acceptance and mutation sweeps to S4 and regression-verifier, while a Phase 3
  narrowed review's rulings are unchanged. Step 3. (The Run directory section's `rulings.md`
  bullet describes the file for every orchestrator, not the autopilot's rulings, so Step 3
  leaves it true.)
- `plugins/kenspc/CHANGELOG.md`: a `## 4.12.0` entry — Changed: T1, T2, T3, T4a, each with its
  reason and the analysis it rests on. Steps 1–3.
- `docs/roadmap.md`: a new item after 33, "Whether the code-fixer trims (4.12.0) cut its time".
  - Baseline: the 46 dispatches from 2026-10-12, as in `classify-since-1012.out` and
    `../fixer/aggregate.out`.
  - The scripts: `fixer-trims/classify_calls.py` with its date argument.
  - What to compare, and the guardrails: section 5 of the analysis README.
  - When: after 30 code-fixer dispatches on 4.12.0 or later.
  - Steps 1–3.
- `README.md` — N/A for this document: no skill summary or review-angle count changes.
- `AGENTS.md` — N/A for this document: no convention, orchestration pattern or guard changes.
- `CLAUDE.md` — N/A for this document: no Claude Code-specific rule changes.
- `docs/release-checklist.md` — N/A for this document: no guard or self-test count changes, and
  the smoke for this change is Step 6's own run, not a new checklist row.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this document: the plan format
  is unchanged.
- `plugins/kenspc/references/task-document-example.md` — N/A for this document: the task format
  is unchanged.
- `docs/dry-runs/README.md` — N/A for this document: the report convention is unchanged.

## Testing Strategy

- **Guards:** `check-all.sh --self-test` proves the edits did not break a guarded block. No
  guard reads the changed paragraphs, so the guards cannot show the new behavior.
- **Behavior:** Step 6 shows T1, T3 and T4a on one seed.
- **T2:** it acts in the autopilot main session and is seen in the next dayaku-crm batch's
  `rulings.md`. The roadmap item's read-back covers it: rulings that name every Acceptance
  command, or mutants of files the fix does not edit, should fall from 41 and 30 of 68.

## Risks and Mitigations

1. **A narrowed per-fix check misses a break in an untouched caller.**
   - Mitigation: the final whole run catches it before regression-verifier, and code-fixer then
     withdraws the fix (current rule).
   - Seen as a final run that fails after per-fix runs passed. The roadmap read-back counts it.
2. **"Test files that import or call the changed module" is read loosely**, as just the one new
   test.
   - Mitigation: the bullet names both kinds.
   - Step 6's check 3 shows what the model ran.
3. **A ruling written before 4.12.0 still asks for a sweep.** The rule applies to new rulings
   only; the old ones are history. No mitigation is needed.
4. **The read-back mixes in 4.11.0's review bar**, which lowers the number of findings, and so
   code-fixer's time, on its own.
   - Mitigation: compare per fixed row and per mutant-reporting row, not per dispatch alone.
   - Compare S3 dispatches with S3 dispatches, since `auto` skips S3b in about half the batches.
5. **The reviewer's mutant definition cannot be reused** (no diff kept, or a script tied to
   the reviewer's copy).
   - Mitigation: then code-fixer writes the mutant itself from the finding's description, under
     the same three steps, as today.
   - This counts as the finding's own check, not one of the three. Step 2's bullet says so.

## Open Questions

1. When `CUSTOM_INSTRUCTIONS` forbid a check that `rulings.md` asks for, which wins?
   - Seen once: the reschedule-api run, where the instructions said "Do not run mutation
     commands" and the ruling asked for them. code-fixer followed the ruling.
   - code-fixer.md states the ruling's precedence over FIXING PRIORITY, not over
     CUSTOM_INSTRUCTIONS.
   - Left for a separate decision.
2. Whether regression-verifier's check 4 should read the `not mutation-checked` suffix as where
   to look first. Not part of this plan; the verifier reads the action's leading word, which the
   suffix does not change.
3. Whether a narrowed review in Phase 3 should also leave Acceptance sweeps out of its rulings.
   - Its code-fixer is followed by an `-s4b` run of the failed case alone, not by a full S4
     run, so T2's reason (S4 runs every case after the last fix) does not hold there.
   - This plan leaves those rulings as they are today. Leaving the sweep out there too would
     need a full S4 re-run after the Phase 3 fix, or an accepted gap; that is a separate
     decision.
4. Whether T1's "at most three per run" and "a mutant already run in this run" span a review's
   second fix round.
   - A second round is a new code-fixer dispatch on the same `RUN_DIR` (INPUTS, `## Round 2`),
     and code-fixer.md uses "run" for the review run as a whole and for one dispatch alike.
   - Counting per review run would have the round-2 dispatch read round 1's attempt
     directories to count; counting per dispatch gives a second round its own three.
   - Step 2's bullet has to say which before it is written; the maintainer decides.
