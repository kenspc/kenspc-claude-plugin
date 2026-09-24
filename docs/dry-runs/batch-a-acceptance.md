# Batch A acceptance — documentation path, dependency gate, CLAUDE.md consistency angle (v3.6.0, unreleased)

Acceptance record for batch A (spec: `docs/plans/batch-a-doc-sync.md`): the
release-checklist smoke rows 4, 5, and 6 with their batch A additions, and
the three reviewer negative cases from the spec's Testing Strategy. One run
on macOS, 2026-09-24. This file records results; it fixes nothing. A FAIL
would have been recorded, not repaired; none occurred inside batch A's
scope.

Labels: **PASS** — the acceptance criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged. These are acceptance labels, not the
per-hunk `FLAG` / `PASS` vocabulary of `docs/dry-runs/README.md`.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `c5eedcd`, loaded with `claude --plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc --permission-mode acceptEdits` (the session process's command line) |
| Claude Code | 2.1.281 |
| Session model | Opus 5.5 (`claude-opus-5-5[1m]`) |
| Effort | `xhigh` (`effortLevel` in user settings) |
| Mode | Interactive TUI; every Agent call ran asynchronously and handed its result back |
| Installed copy | `kenspc@kenspc-claude-plugin` 3.5.1 is also `enabled: true` in `~/.claude/settings.json:80` |
| Target project | `/Users/kenspc/Projects/_smoke/batch-a`: TypeScript 7.0.2, vitest 5.0.1, Node 24.19.0; `README.md`; no `CLAUDE.md`; `.gitignore` written with CRLF line endings and blank lines and no `.kenspc/` entry; baseline commit `c24bf8c` |
| Feature | Bill splitting (bill model, equal and weighted split, balances, greedy settle-up) — five code tasks plus Doc-sync |
| Negative-case clones | `/Users/kenspc/Projects/_smoke/batch-a-neg/{a,b,c}`, each a clone of the target reset to `75bc601` (plan and task document after their reviews) |

**Source gate.** With the installed 3.5.1 enabled beside `--plugin-dir`,
only one copy is live. Evidence that it was the repository tree:

- The Skill tool's base directory for `generate-plan`, `generate-task`, and
  `task-implement` (the last also after `/reload-plugins`) was
  `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/<skill>`.
- `task-document-reviewer` returned a three-row Schema E. The 3.5.1 copy
  reads "Review both angles in order" (`agents/task-document-reviewer.md:55`
  in the install cache); the repository copy reads "Review all three
  angles in order".

**How the chain was driven.**

- The six `/kenspc-*` commands are `disable-model-invocation: true`, so the
  session invoked the skills (`kenspc:generate-plan`, `kenspc:generate-task`,
  `kenspc:task-implement`) through the Skill tool; each command file only
  points at the same SKILL.md. Batch A changed none of the command files:
  `git diff --stat v3.5.1..c5eedcd -- plugins/kenspc/commands` is empty
  (control: the same diff over `plugins/kenspc/agents` reports 3 files).
- The session played the requirement owner: it answered `/kenspc-plan`
  discovery (the requirement was Level 1, one gap-check round), approved the
  plan and the task list, and confirmed `task-implement`'s Phase 1 Step 3
  batch gate.
- The same session was the skills' orchestrator. Criteria met by
  orchestrator output — the Schema G Next steps bullets and the verdict —
  therefore show that the SKILL text can be followed as written; they are
  not independent of a driver that knew the expected result. Criteria met
  by subagent output (plan and task reviewers, `task-implementer`,
  code-fixer, regression-verifier) are independent.

**Environment note.** `~/.gitconfig` sets `core.autocrlf=input`, so git
stores every committed `.gitignore` blob with LF line endings
(`git ls-files --eol .gitignore` → `i/lf`). The CRLF `.gitignore` existed
only in the working tree, and after the round 2 reset the working tree is
LF too. The CRLF criterion of the run-directory check was observed on the
working tree only.

## 2. Precondition: checklist rows 1–2

| Row | Result | Evidence |
|---|---|---|
| 1 `/help` | PASS | Run by the user in the TUI; reported at 19:06: "/help 中的 kenspc 六个都在" (all six kenspc commands are listed) |
| 2 `/reload-plugins` | PASS | Run by the user at 19:10: `Reloaded: 11 plugins · 24 skills · 17 agents · 22 hooks · 2 plugin MCP servers · 2 plugin LSP servers`, no error |

## 3. Item 1 — `/kenspc-plan` (smoke row 4)

Plan: `docs/plans/bill-splitting.md`. Reviewer commits: `66a9ba0`
(baseline, the plan as written), `458034e`, `dd0a0a3`, `b63d7c5`, `f04fa8d`.

| Criterion | Result | Evidence |
|---|---|---|
| A `plan-document-reviewer` Agent call follows the written plan, then the Schema E table | PASS | Dispatched with `PLAN_PATH` and `PROJECT_PATH`; table below |
| The plan contains `## Documentation impact`, a list or `N/A — <reason>` | PASS | `docs/plans/bill-splitting.md:164`; a list: `README.md` § Status, § API, § Design notes, each naming its causing steps, plus the entry "`CLAUDE.md` — N/A for this document: the project has none and no step creates one." |
| Schema E has four rows | PASS | Verbatim below |

| Angle | Status | Changes | Commit |
|-------|--------|---------|--------|
| 1 | FIXED (1) | Step dependency statement; Step 3 file line | 458034e |
| 2 | FIXED (4) + NOTED (1) | Steps 1, 3, 5; Documentation impact; Risks; Open Questions | dd0a0a3 |
| 3 | FIXED (2) | Technical Approach (integer cents); Step 3 formulas | b63d7c5 |
| 4 | FIXED (6) | Technical Approach (greedy); Steps 1, 3, 4, 5; Testing Strategy | f04fa8d |

The project has no CLAUDE.md, so the element was determined from README.md
and CLAUDE.md themselves (ruling M2's fallback). Angle 2 edited the element
(`dd0a0a3`: the § Status entry now replaces the whole paragraph, the § API
entry adds the four types) and kept the `CLAUDE.md` per-entry N/A line; it
did not treat it as padding.

## 4. Item 2 — `/kenspc-task` (smoke row 5)

Task document: `docs/tasks/bill-splitting-tasks.md`. Reviewer commits:
`6ab4b16` (baseline), `75bc601`.

| Criterion | Result | Evidence |
|---|---|---|
| A `task-document-reviewer` Agent call, then the Schema E table | PASS | Dispatched with `TASK_DOC_PATH`, `SOURCE_PATH`, `PROJECT_PATH`; table below |
| The last task is `### Task N: Doc-sync` | PASS | Line 196: `### Task 6: Doc-sync` |
| `Depends on: Task 1-<N-1>` | PASS | Line 200: `Depends on: Task 1-5` |
| Dependency note at the top | PASS | Line 13 begins "Dependency note: Task 3 depends on Task 2 (`Depends on: Task 2`); Task 4 …" |
| The Doc-sync document list matches the plan's element | PASS | Three entries, `README.md` § Status, § API, § Design notes. Reviewer, Angle 1: "The Doc-sync check passes: Task 6 is last, has `Depends on: Task 1-5`, and lists the same three README sections as the plan's Documentation impact. CLAUDE.md is correctly left out because the plan marks it N/A." |
| Schema E has three rows; row 3 is Consistency with CLAUDE.md | PASS | Verbatim below; prose: "**Angle 3: Consistency with CLAUDE.md.** Passed. The project has no CLAUDE.md or CLAUDE.local.md. Nothing in the tasks conflicts with the user-level CLAUDE.md. All task text is in English, as is README.md, the document it will edit." |

| Angle | Status    | Changes                                                         | Commit  |
|-------|-----------|-----------------------------------------------------------------|---------|
| 1     | FIXED (5) | added key-order, copy and no-trim checks; added a Task 4 risk note | 75bc601 |
| 2     | PASSED    | —                                                               | —       |
| 3     | PASSED    | —                                                               | —       |

The reviewer's Plan-Level Concerns were non-empty (the plan's open question
on running-balance overflow; key-order promises the plan's acceptance
criteria do not test), so the skill printed the re-plan suggestion. The
driver, as requirement owner, did not re-run `/kenspc-plan`.

**OBSERVATION O1 — the per-entry `N/A for this document` form.** The
plugin defines two forms of the element: a document list, or a whole-body
`N/A — <reason>`. The per-entry line used here comes from the spec's own
Documentation impact (Clarification Q2) and is not defined to the plugin:

```text
$ grep -rn "N/A for this\|considered and is unaffected\|per-entry" plugins/kenspc
(no output)
$ grep -rn "N/A — <reason>" plugins/kenspc | head -3   # control
plugins/kenspc/README.md:14: …
plugins/kenspc/README.md:216: …
plugins/kenspc/CHANGELOG.md:28: …
```

`generate-task` left the entry out of the Doc-sync list by the executing
model's judgment, not by a rule in the skill, and `task-document-reviewer`
did not report the README-only list as a mismatch (failure mode 3). The
spec author ruled this an observation, not a FAIL; whether to define the
third form is a follow-up after this smoke.

## 5. Item 3 — `/kenspc-task-implement`, round 1 (smoke row 6)

Start `75bc601`. Implementation commits `a48962d`, `c67f83b`, `06e2d0d`,
`58c8e5c`, `46e496c`, `a464d48` (Doc-sync); `.gitignore` commit `951bb95`;
fix commits `319dcd7`, `86329f1`, `35f96b3`, `49bfa18`, `31fe7ad`,
`5ad1323`. Run directory
`/Users/kenspc/Projects/_smoke/batch-a/.kenspc/runs/20260924-191928-bill-splitting-tasks`.

| Criterion | Result | Evidence |
|---|---|---|
| Phase 2 dispatches after an all-DONE implementation: five reviewer calls, then Schema A → B → C → G | PASS | Schema D: six rows, all DONE. Five reviewer calls in one message; Schema A 0 HIGH / 4 MEDIUM / 4 LOW; code-fixer; regression-verifier; Schema G |
| Schema G's Implementation carries `## Decisions needing a home` | PASS | One entry: "- Task 1: every throw case gets its own full message, and no message may be contained in another, because vitest's `toThrow("...")` matches substrings — `CLAUDE.md` § Conventions (the project has no CLAUDE.md yet; not created)." The `none` form is exercised in round 2 (section 6) |
| Next steps: one bullet per needing-a-home entry | PASS | One entry, one bullet (orchestrator): "Decision needing a home: Task 1 规定每个抛错分支都有完整且互不包含的错误信息（因为 vitest 的 `toThrow("...")` 按子串匹配）。建议放到 `CLAUDE.md` § Conventions，但项目目前没有 CLAUDE.md。" |
| Doc-sync DONE and code-fixer FIXED > 0: one Next steps bullet names the listed documents to re-check against the fix commits | PASS | Statistics line: `total reported 8 (R 2, E 1, Q 1, B 1, T 3), deduplicated to 6 unique, FIXED 6, DEFERRED 0, NOT APPLICABLE 0, DEDUPED 2`. Bullet (orchestrator): "审查的修复发生在 Doc-sync（Task 6）之后，而 code-fixer 报告 FIXED 6。请对照 fix commits `319dcd7`、`86329f1`、`35f96b3`、`49bfa18`、`31fe7ad`、`5ad1323` 重新核对 Task 6 列出的文档 `README.md`（§ Status、§ API、§ Design notes）。" The re-check matters here: `319dcd7` and `31fe7ad` both edit `README.md` |
| Doc-sync writes the earlier tasks' decisions into its listed documents, and into no unlisted file | PASS | `a464d48` touches `README.md` and the task document only. Task 6's notes record three promotions — T3 "`src/bill.ts` repeats the split limits …" → § Design notes; T4 "running balances are not checked against the safe-integer range" → § Design notes; T4 "`computeBalances` expects a bill built with `addExpense` and does not re-validate it" → § API — visible at `README.md` lines 139–144, 145–147, and 100–101 as of `a464d48`. The needs-a-home decision was written nowhere; `CLAUDE.md` does not exist after the run |
| Verdict | PASS | Every task DONE, 0 HIGH, typecheck and tests pass, no regressions. Not affected by the scratch finding: regression-verifier ran the suite as `npx vitest run --dir test` (section 8) |

### Run-directory check (smoke row 6)

| Sub-check | Result | Evidence |
|---|---|---|
| Headless foreground dispatch | Not applicable | TUI run |
| TUI: no user input between the invocation and Schema G | PASS | No user message from the invocation (after 19:10) to the Schema G report. The Phase 1 Step 3 batch gate was answered by the driver |
| The Fixes section prints the full path of `schema-b.md` | PASS | `/Users/kenspc/Projects/_smoke/batch-a/.kenspc/runs/20260924-191928-bill-splitting-tasks/schema-b.md` |
| The directory holds `angle-1.md`–`angle-5.md` and `schema-b.md`; probes under `scratch/` | PASS | Top level: `angle-1.md` … `angle-5.md`, `schema-b.md`, `scratch/`. Reviewers used `scratch/angle-<n>/`; regression-verifier wrote `scratch/verifier-*.txt`. OBSERVATION: code-fixer used a subdirectory, `scratch/fixer/`, rather than `scratch/` itself |
| Nothing outside the run directory created or deleted for probing | PASS | `/private/tmp`: only `cc-socks/` (cross-session sockets) and `claude-501/` (Claude Code's own session directory) changed. `$TMPDIR` gained 49 `<nanoid>/ssr/` directories — vite's SSR transform cache, which every vitest process writes, the driver's own `npx vitest` runs included; no probe file |
| `bash scripts/check-run-contract.sh --file <schema-b.md>` exits 0 | PASS | `OK    schema-b recount — …/schema-b.md agrees with its rows`, exit 0 |
| `.gitignore` without `.kenspc/`: exactly one commit before dispatch, touching only `.gitignore`, line endings kept | PASS (working tree) | `check-ignore` exit 1 → `951bb95 chore: ignore kenspc run directory`, 1 file changed, 1 insertion; `od -c` of the working-tree file ends `.kenspc/\r\n`. See the environment note: the stored blob is LF |
| A second run adds none | PASS | Round 2: `check-ignore` exit 0, HEAD `de8c1cb` before and after |

## 6. Item 4 — `/kenspc-task-implement`, round 2 (forced BLOCKED)

Setup, agreed with the spec author: `git reset --hard 75bc601` (round 1
HEAD was `5ad1323`), cherry-pick of the `.gitignore` commit as `a7f0a27`,
and Task 3 rewritten to require `apportion` from
`@kenspc-smoke/hamilton-apportion@^4.2.0`, a package that does not exist
(`npm view` → 404; control `npm view vitest version` → 5.0.1), commit
`14f8e19`. All six tasks TODO, no Implementation notes. Run directory
`/Users/kenspc/Projects/_smoke/batch-a/.kenspc/runs/20260924-194210-bill-splitting-tasks`.

| # | Task | Status | Commit |
|---|---|---|---|
| 1 | Bill model and validation | DONE | `285f059` |
| 2 | Equal split | DONE | `54f2320` |
| 3 | Weighted split | BLOCKED | `9452bb1` |
| 4 | Balances | BLOCKED | `bbfd732` |
| 5 | Settle-up | BLOCKED | `89efb23` |
| 6 | Doc-sync | BLOCKED | `de8c1cb` |

| Criterion | Result | Evidence |
|---|---|---|
| The unimplementable task is BLOCKED | PASS | Task document line 102: "- Blocked: The required dependency cannot be installed. `npm install @kenspc-smoke/hamilton-apportion@^4.2.0` exits 1 with `E404 Not Found - GET https://registry.npmjs.org/@kenspc-smoke%2fhamilton-apportion` …" |
| The Doc-sync task is BLOCKED with `depends on Task N (BLOCKED)` | PASS | Line 225: "- Blocked: depends on Task 3 (BLOCKED), Task 4 (BLOCKED), and Task 5 (BLOCKED). … `README.md` was not modified, and no decision from Tasks 1-2 was promoted." The gate also blocked Task 4 (line 152, "- Blocked: depends on Task 3 (BLOCKED).") and Task 5 (line 189, "- Blocked: depends on Task 4 (BLOCKED).") |
| Next steps has a bullet stating the listed documents were not synced, and why | PASS | Orchestrator: "Doc-sync（Task 6）是 BLOCKED，所以它列出的文档没有同步：`README.md` § Status、§ API、§ Design notes 都未更新。原因是 depends on Task 3 (BLOCKED)、Task 4 (BLOCKED)、Task 5 (BLOCKED)；现在同步会把尚不存在的 `splitWeighted`、`computeBalances`、`settleUp` 写进 README。" |
| `## Decisions needing a home` computed from the DONE tasks | PASS | Rendered as `none`, with "Task 6 did not run, so nothing was promoted. Every Task 1-2 decision is either local to the code or fits `README.md`, which Task 6 already lists." Source: the `Decisions:` sub-bullets of Tasks 1–2 |
| No re-check bullet when the Doc-sync task was not DONE | PASS | Next steps has none (the condition requires a Doc-sync task processed DONE) |
| Nothing documented that was not built | PASS | `git diff --stat 14f8e19..de8c1cb -- README.md package.json package-lock.json` is empty |
| Verdict PARTIAL | PASS (adjusted) | **Raw verdict: FAIL.** regression-verifier row 1: "The accountability list is complete. The fix for E2 (row 3) is incomplete: flagged INCORRECTLY FIXED." — an INCORRECTLY FIXED item forces FAIL. That cause lies outside batch A. Excluding it, the BLOCKED tasks alone give PARTIAL; judged on that adjusted value by the spec author's ruling. Both values recorded |
| Run-directory: a second run adds no `.gitignore` commit; run contract | PASS | `check-ignore` exit 0, HEAD `de8c1cb` before and after; `check-run-contract.sh` → `OK    schema-b recount`, exit 0 |

Round 2 code-fixer statistics line:
`total reported 14 (R 3, E 3, Q 2, B 3, T 3), deduplicated to 10 unique, FIXED 7, DEFERRED 2, NOT APPLICABLE 1, DEDUPED 4`.

**OBSERVATION O2 — E2 regression caught.** code-fixer's `e8a6598` made
`splitEqual` charge a hole in `among` to an `undefined` key;
regression-verifier caught it ("`s[1] = "x"; splitEqual(101, s)` now gives
`[[undefined, 51], ["x", 50]]`") and failed row 1. The 3.5.1 review
harness worked as designed; not a defect.

## 7. Item 5 — reviewer negative cases

Each case was seeded and committed in its own clone, then the reviewer was
dispatched through the Agent tool with the CONTEXT keys its agent file
lists under CONTEXT YOU WILL RECEIVE. The target repository's HEAD
(`8c54204`) was unchanged after all three runs.

| Case | Seed | Reviewer and CONTEXT | Expected | Result |
|---|---|---|---|---|
| a | `9e970f9`: the Documentation impact body replaced by "N/A — the plan adds library modules only and changes no durable document."; Step 5 gains "- README: add a `settleUp` entry to `README.md` § API … and replace the § Status paragraph with one sentence saying bill splitting is implemented." | `plan-document-reviewer`; `PLAN_PATH`, `PROJECT_PATH` | Angle 2 restores the list | PASS |
| b | `d11c56e`: the `### Task 6: Doc-sync` block moved, unchanged, between Task 3 and Task 4 (43 insertions, 43 deletions) | `task-document-reviewer`; `TASK_DOC_PATH`, `SOURCE_PATH`, `PROJECT_PATH` | Angle 1 moves it back to last | PASS |
| c | `df08c1f`: Task 1 gains "Before writing any code, create a feature branch with `git checkout -b feature/bill-splitting` and commit this task's work on it."; the plan has no branch step (`grep -ci branch` → 0; control `grep -c Step` → 26) | `task-document-reviewer`; `TASK_DOC_PATH`, `SOURCE_PATH`, `PROJECT_PATH` | Angle 3 restores the default and records a Plan-Level Concern | PASS |

**Case a** — Schema E:

| Angle | Status              | Changes                                                              | Commit  |
|-------|---------------------|----------------------------------------------------------------------|---------|
| 1     | FIXED (1)           | Implementation Steps preamble                                        | f3e4890 |
| 2     | FIXED (2), NOTED (1) | Documentation impact, Step 5 README bullet, Open Questions         | bd038e6 |
| 3     | PASSED              | —                                                                    | —       |
| 4     | FIXED (5)           | Acceptance in Steps 1–5, Step 5 `settleUp` contract, Testing Strategy | b2e1ac3 |

Changes, Angle 2: "Documentation impact said "N/A — … changes no durable
document". Step 5 contradicts that because it edits README.md. … The
project has no CLAUDE.md, so I built the list from README.md and CLAUDE.md
and the steps". After `bd038e6` the element lists `README.md` § Status,
§ API, § Design notes, and "`CLAUDE.md` — N/A: the project has none and no
step creates one." The reviewer also pointed Step 5's README bullet at the
restored list.

**Case b** — Schema E:

| Angle | Status    | Changes                          | Commit  |
|-------|-----------|----------------------------------|---------|
| 1     | FIXED (1) | Doc-sync task moved to the end   | 0e54718 |
| 2     | PASSED    | —                                | —       |
| 3     | PASSED    | —                                | —       |

Changes, Angle 1: "`### Task 6: Doc-sync` sat between Task 3 and Task 4
instead of at the end (Doc-sync failure mode 2). Someone working through
the document in order would have reached it before Tasks 4 and 5, which it
depends on. I moved the whole block, unchanged, to the end, so the tasks
now run 1 through 6 in order." After `0e54718` the task document is
byte-identical to `75bc601` (`git diff --quiet 75bc601 HEAD -- docs/tasks/bill-splitting-tasks.md`).

**Case c** — Schema E:

| Angle | Status    | Changes                                   | Commit  |
|-------|-----------|-------------------------------------------|---------|
| 1     | PASSED    | —                                         | —       |
| 2     | PASSED    | —                                         | —       |
| 3     | FIXED (1) | removed the unplanned feature-branch step | 9ac987e |

Changes, Angle 3: "Task 1 told the implementer to run `git checkout -b
feature/bill-splitting` before writing any code and to commit the task's
work on that branch. That is failure mode 3, an undecided git workflow
step: The plan has no branch, pull-request, rebase or tag step. … No loaded
CLAUDE.md prescribes feature branches. I removed those two sentences, so
Task 1 now just says "Create `src/bill.ts` and `test/bill.test.ts` (plan
Step 1)." and the tasks commit on the current branch." After `9ac987e` the
task document is byte-identical to `75bc601`.

Plan-Level Concerns, verbatim:

> **Unplanned feature-branch step (plan Implementation Steps / Task 1).**
> Only the generated Task 1 had the branch step. The plan
> (`/Users/kenspc/Projects/_smoke/batch-a-neg/c/docs/plans/bill-splitting.md`,
> Implementation Steps) has none, and `~/.claude/CLAUDE.md` § Git Workflow
> only requires conventional commits and English branch names. I set the
> task back to the default of committing on the current branch (`main`).
> If you do want a feature branch, add it to the plan and regenerate or
> edit Task 1. Note that `main` currently has diverged from `origin/main`
> (1 local commit vs 2 remote), which is worth sorting out before an
> unattended run commits more to it.

A second concern repeats the plan's open question on running-balance
overflow. The concern names both sources, the plan and the loaded
CLAUDE.md, as ruling M7 requires. The `origin/main` remark reflects the
clone's origin, the target repository, which had moved on.

## 8. Finding outside batch A: reviewer scratch files collected by the test runner

Classification: a defect in the 3.5.1 scratch convention (`canonical:run-dir`
and the reviewers' scratch rule), outside batch A's scope; evidence for
roadmap item 9. Batch A's criteria above were judged without it.

**Mechanism.** The run directory lives inside the project. `.gitignore`
keeps it out of git, not out of the test runner. vitest 5.0.1 runs with no
config file in the project root (`find . -maxdepth 1 -name 'vite*.config.*'
-o -name 'vitest.workspace*'` → 0; control `package.json` → 1) and uses its
defaults (`node_modules/vitest/dist/chunks/defaults.D2ip7f-X.js:5–6`):

```js
const defaultInclude = ["**/*.{test,spec}.?(c|m)[jt]s?(x)"];
const defaultExclude = ["**/node_modules/**", "**/.git/**"];
```

Neither the run-dir block nor the reviewers' scratch rule asks for probe
names a test runner will not collect.

**Reproduction** (round 1, 19:24:33, after the five reviewers):
`npx vitest run` → `Test Files  8 failed | 40 passed (48)`,
`Tests  19 failed | 422 passed (441)`; `npx vitest run --dir test` →
`Test Files  5 passed (5)`, `Tests  54 passed (54)`.

**Probe files** — every test-named file under
`/Users/kenspc/Projects/_smoke/batch-a/.kenspc/runs/20260924-191928-bill-splitting-tasks/scratch/`
after round 1 (68 files):

- `angle-1/probe.test.ts`
- `angle-1/probe2.test.ts`
- `angle-5/M0/test/balance.test.ts`
- `angle-5/M0/test/bill.test.ts`
- `angle-5/M0/test/money.test.ts`
- `angle-5/M0/test/settle.test.ts`
- `angle-5/M0/test/split.test.ts`
- `angle-5/M1/probe.test.ts`
- `angle-5/M1/test/balance.test.ts`
- `angle-5/M1/test/bill.test.ts`
- `angle-5/M1/test/money.test.ts`
- `angle-5/M1/test/settle.test.ts`
- `angle-5/M1/test/split.test.ts`
- `angle-5/M2/probe.test.ts`
- `angle-5/M2/test/balance.test.ts`
- `angle-5/M2/test/bill.test.ts`
- `angle-5/M2/test/money.test.ts`
- `angle-5/M2/test/settle.test.ts`
- `angle-5/M2/test/split.test.ts`
- `angle-5/M3/probe.test.ts`
- `angle-5/M3/test/balance.test.ts`
- `angle-5/M3/test/bill.test.ts`
- `angle-5/M3/test/money.test.ts`
- `angle-5/M3/test/settle.test.ts`
- `angle-5/M3/test/split.test.ts`
- `angle-5/M4/probe.test.ts`
- `angle-5/M4/test/balance.test.ts`
- `angle-5/M4/test/bill.test.ts`
- `angle-5/M4/test/money.test.ts`
- `angle-5/M4/test/settle.test.ts`
- `angle-5/M4/test/split.test.ts`
- `angle-5/M5/test/balance.test.ts`
- `angle-5/M5/test/bill.test.ts`
- `angle-5/M5/test/money.test.ts`
- `angle-5/M5/test/settle.test.ts`
- `angle-5/M5/test/split.test.ts`
- `angle-5/M6/test/balance.test.ts`
- `angle-5/M6/test/bill.test.ts`
- `angle-5/M6/test/money.test.ts`
- `angle-5/M6/test/settle.test.ts`
- `angle-5/M6/test/split.test.ts`
- `angle-5/orig/probe.test.ts`
- `angle-5/probe.test.ts`
- `fixer/Q1-old/test/balance.test.ts`
- `fixer/Q1-old/test/bill.test.ts`
- `fixer/Q1-old/test/money.test.ts`
- `fixer/Q1-old/test/settle.test.ts`
- `fixer/Q1-old/test/split.test.ts`
- `fixer/T1-min/test/balance.test.ts`
- `fixer/T1-min/test/bill.test.ts`
- `fixer/T1-min/test/money.test.ts`
- `fixer/T1-min/test/settle.test.ts`
- `fixer/T1-min/test/split.test.ts`
- `fixer/T1-zero/test/balance.test.ts`
- `fixer/T1-zero/test/bill.test.ts`
- `fixer/T1-zero/test/money.test.ts`
- `fixer/T1-zero/test/settle.test.ts`
- `fixer/T1-zero/test/split.test.ts`
- `fixer/T2-one/test/balance.test.ts`
- `fixer/T2-one/test/bill.test.ts`
- `fixer/T2-one/test/money.test.ts`
- `fixer/T2-one/test/settle.test.ts`
- `fixer/T2-one/test/split.test.ts`
- `fixer/T3-isint/test/balance.test.ts`
- `fixer/T3-isint/test/bill.test.ts`
- `fixer/T3-isint/test/money.test.ts`
- `fixer/T3-isint/test/settle.test.ts`
- `fixer/T3-isint/test/split.test.ts`

**How each agent reacted.**

| Agent | Round | Noticed | Reaction (verbatim) |
|---|---|---|---|
| edge-case-reviewer | 1 | Yes, first | "running `npm test` from the project root fails right now (19 failures in 8 files). Vitest's default include also collects `*.test.ts` files under `.kenspc/runs/20260924-191928-bill-splitting-tasks/scratch/angle-5/`, the mutation copies another reviewer left there." |
| code-fixer | 1 | Yes | `schema-b.md:1`: "`npm test -- --exclude '.kenspc/**'` exit 0 (5 files, 56 tests; baseline was 54). … Unscoped `npm test` exits 1 because vitest also collects the deliberately mutated copies under this run's `scratch/` (angle-5 controls M0/M5/M6 and the fixer's mutants). All 13 failing files are under `.kenspc/`, and none is outside it." |
| regression-verifier | 1 | Yes | Row 3, Result `PASS`, Detail: "`npx vitest run --dir test` exited 0: 5 files, 56 of 56 tests passed … Note: plain `npm test` exits 1 (13 files and 24 of 721 tests fail). Every failure is a deliberately mutated copy under `RUN_DIR/scratch/` (angle-5 M0/M5/M6 and fixer/*), and no project file fails. See the notes below." Note 3: "Plain `npm test` fails in this checkout until the run's scratch copies are dealt with. … `.gitignore` does not affect vitest. Two ways to fix it: delete that scratch directory, or add `.kenspc/**` to vitest's exclude list." |
| task-implementer | 2 | Yes | "Plain `npm test` exits 1 in this folder, before and after my changes. Vitest also collects 16 failing test files from the gitignored scratch folder … I verified with `npm test -- --exclude '.kenspc/**'` instead." and "An attempt to confirm plain `npm test` in a fresh clone was refused permission." |
| test-reviewer | 2 | Yes, as finding T2 (MEDIUM) | "an unscoped `npm test`, the acceptance gate, exits 1 in this working copy. The earlier run's scratch directory still holds 16 old `*.test.ts` probe files, and vitest picks them up. So the gate fails no matter what the code does." |
| code-fixer | 2 | Yes; FIXED it in the user's project | Schema B row 1, Source cell `R1, B3, T2`: "unscoped npm test collects .kenspc probe tests \| MEDIUM \| package.json:8 \| FIXED \| a401e20" |
| regression-verifier | 2 | Yes | Row 3, Result `PASS`, Detail: "Unscoped `npm test` exits 0: 3 files, 35/35 tests (31 before the fixes plus 4 new). … `vitest list --filesOnly` shows exactly `test/bill.test.ts`, `test/money.test.ts` and `test/split.test.ts`. Without the new exclude, a config with only the default excludes would collect 78 files (75 under `.kenspc/`), so the exclude is what keeps the stale probes out." |

`a401e20 build: exclude .kenspc run scratch files from vitest collection`,
the whole diff:

```diff
--- /dev/null
+++ b/vitest.config.ts
+import { configDefaults, defineConfig } from "vitest/config";
+
+export default defineConfig({
+  test: {
+    // Review-run scratch files under .kenspc/ are not part of the suite.
+    exclude: [...configDefaults.exclude, ".kenspc/**"],
+  },
+});
```

**OBSERVATION O3 — the fix is a symptom.** To make room for the plugin's
own probes, code-fixer changed the user's project configuration: it added
a `vitest.config.ts` the project did not have.

**OBSERVATION O4 — reviewers improvise, inconsistently.** Round 1 probes
were named `*.test.ts` (angle-1, angle-5), `probe.check.ts` next to a
private `vitest.config.mjs` (angle-2), and `*.mts` (angle-4). code-fixer
copied whole `test/` trees under `scratch/fixer/<mutant>/`. In round 2, with
the earlier run's probes in view, bug-reviewer said its probes are "named
`*.mts` so vitest does not collect them"; test-reviewer said "My probe
files are named `*.probe.ts`, so `npm test` does not pick them up";
edge-case-reviewer used `probe.mts`; regression-verifier used
`probe.probe.ts`. The round 2 code-fixer and regression-verifier still
copied whole test trees: 6 test-named files under
`scratch/fixer/{t1-mut,t3-mut}/` and 24 under `scratch/verifier/mut/` in
`.kenspc/runs/20260924-194210-bill-splitting-tasks/`, harmless only
because `a401e20` now excludes `.kenspc/**`. Each agent avoids the
collision its own way, or not at all, so the rule has to be written down.

## 9. Summary

| Item | Result |
|---|---|
| Precondition: `/help`, `/reload-plugins`, source gate | PASS |
| 1 `/kenspc-plan`: Documentation impact; Schema E four rows | PASS |
| 2 `/kenspc-task`: last task Doc-sync, `Depends on: Task 1-5`, list matches, Dependency note; Schema E three rows, row 3 Consistency with CLAUDE.md | PASS |
| 3 `/kenspc-task-implement` round 1: Decisions needing a home; one bullet per entry; re-check bullet after FIXED 6; Doc-sync scope; run-directory check | PASS |
| 4 round 2: middle task BLOCKED; Doc-sync `depends on Task N (BLOCKED)`; not-synced bullet; section from DONE tasks; verdict | PASS (verdict on the adjusted value; raw verdict FAIL, from E2) |
| 5a plan reviewer, N/A contradicted by a README step | PASS |
| 5b task reviewer, Doc-sync moved to the middle | PASS |
| 5c task reviewer, unplanned feature branch | PASS |

No FAIL inside batch A's scope. One finding outside it (section 8) and
four observations (O1 per-entry N/A form; O2 E2 regression caught; O3 and
O4 on the scratch convention).
