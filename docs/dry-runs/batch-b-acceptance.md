# Batch B acceptance — diagnose-bug, /kenspc-diagnose, REVIEW_SCOPE=changes (v3.7.0, unreleased)

Acceptance record for batch B (spec: `docs/plans/batch-b-diagnose-bug.md`):
release-checklist smoke row 9 (`/kenspc-diagnose`, every case the row
names), row 7 with the change-set check (four repository states), and the
spec's Testing Strategy items that no row covers (`/kenspc-plan` on the
produced brief). One machine, macOS, 2026-09-25, 19:21–19:53. This file
records results. Two fixes were made during acceptance, in the spec-author
session and never in a run's project; each is named with its commit and
the row that was re-run afterwards.

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — the run gave
the criterion nothing to check.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `6bbfc45` for the first wave; `20b6a8d` for the dirty-tree re-run (F1's fix); loaded with `--plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc` |
| Claude Code | 2.1.282 |
| Mode | Headless, `claude -p "<prompt>" --plugin-dir … --permission-mode bypassPermissions --output-format json`, one process per run, launched in the background from the spec-author session (Sim's authorization, 19:00); a run that stopped at a question was continued with `claude -p --continue "<answer>"` in the same project |
| Session model | Opus 5.5 (`claude-opus-5-5` in every run's `modelUsage`; the routing check also used Haiku 4.5 for a subtask) |
| Installed copy | `kenspc@kenspc-claude-plugin` 3.6.0 is also enabled; the source gate is the Skill tool's base directory in each trace, which was the repository tree |
| Seed project | `~/Projects/_smoke/batch-b-seed` at `23fae4f`: TypeScript 7.0.2, vitest 5.0.1, Node 24.19.0, `vitest.config.ts` with only `globals: true`, `README.md` documenting the API, no `CLAUDE.md`, `.gitignore` written with CRLF and a blank line and no `.kenspc/` entry; `src/{money,discount,tax,receipt}.ts`, four test files, 10 tests green |
| Seeded bugs | `parseAmount` truncates a float product (`"1.15"` → 114 cents); `formatCents` prints `$` whatever the receipt's currency (a fix that respects the contract exists, so tier 3 has to be chosen); a refund feature with three defects, used as the change under review in the row-7 projects |
| Projects | `batch-b` (row 9 chain), `batch-b-nofw` (plain JavaScript, no test framework), `batch-b-route` (routing check), `batch-b-rev-dirty` and `-dirty2` (uncommitted refund feature), `batch-b-rev-upstream` (bare origin, two commits ahead), `batch-b-rev-root` (one root commit), `batch-b-rev-unborn` (files, no commit) |
| Traces | One JSONL per run under `~/.claude/projects/-Users-kenspc-Projects--smoke-<project>/`, subagents under `<session>/subagents/`; run results in `~/Projects/_smoke/_logs/<tag>.json` |
| Cost | 16 runs, $44.97 in total (each run's cost is in its row below) |

**Independence.** The spec author designed, ruled on, and drove this
acceptance, and wrote this record. What the plugin's own headless runs
produced — commits, documents, run directories, agent reports, verdicts —
is independent of that; what the driver typed as answers to the skills'
questions (the task-list confirmation, the batch gate, "run", option B) is
not, and each such answer is named where it was given.

## 2. Row 9 — `/kenspc-diagnose`

### 2.1 Tier-2 chain, `batch-b` (four runs: $0.69, $0.98, $1.12, $6.11)

Prompt: the symptom only — `buildReceipt([{ label: "Kopi", amount: "1.15",
qty: 1 }], { currency: "MYR" })` returns total 114 and `"$1.14"`, expected
115; `"12.30"` is fine.

| Criterion | Result | Evidence |
|---|---|---|
| Reproduction test written, run, and failing before the task document; committed alone | PASS | `test/receipt-cent-short.test.ts`, run 3× (`expected 114 to be 115` each time), committed `f5382e9 test: reproduce receipt total one cent short for 1.15` staging that file only; the first `git status` read used `-c core.quotePath=false … -uall` |
| Root cause, hypotheses, tier | PASS | `src/money.ts:12` (`Math.trunc(parseFloat*100)`); Hypotheses "none — visible on reproduction", with `percentOff` and `applyTax` ruled out by inline `node -e` probes (no files, no run directory); Tier 2, Fix scope `src/money.ts` |
| Task-list confirmation, then the document committed alone | PASS | The run stopped at the confirmation (a session that can ask); continued with "Confirmed as proposed"; `docs/tasks/receipt-total-cent-short.md` committed `863d85c docs: add task receipt-total-cent-short`; tree clean |
| Document shape | PASS | `## Diagnosis` with the nine labels in order; `### Task 1` and `### Task 2: Regression tests …` (`Depends on: Task 1`) since Adjacent cases lists cases; `**Documentation impact:** N/A — <reason>`, so no Doc-sync task; `**Probes:** none`; 0 `Phase`/`Step` headings |
| Exit asks run-or-interactive | PASS | The run ended on "Do you want me to run `/kenspc-task-implement …` now, or would you rather implement it interactively?" after noting `src/money.ts` had no uncommitted changes |
| "Run" invokes task-implement through the Skill tool; Step 1 accepts the document | PASS | Continued with "Run … now."; trace shows `Skill kenspc:task-implement`, then its validation grep (2 TODO, no Phase/Step headings) and the Step 3 batch gate |
| Unattended implementation and review | PASS | Continued with "Proceed."; Task 1 DONE `54acb50`, Task 2 DONE `c939b0b`; `## Decisions needing a home` none; Phase 2 ran in `.kenspc/runs/20260925-193113-receipt-total-cent-short` (`.gitignore` commit `436d709` first), one fix commit `9cdefdc`, one DEFERRED; Schema C 1–5 PASS (16/16 tests, no `.kenspc/` files collected); verdict PASS |
| After the run | PASS | Reproduction test passes (2/2); `npm test` 16/16 from the root; `find` probe over the run's `scratch/` 0 hits; tree clean |

### 2.2 Manual reproduction, `batch-b-nofw` (two runs: $0.59, $0.74)

| Criterion | Result | Evidence |
|---|---|---|
| No test framework → manual steps, no `test: reproduce` commit | PASS | `**Reproduction:**` a numbered list (`node tip.js 20 15` → `total: 23.0`, 3 of 3 runs) with the reason; HEAD unchanged until the document |
| Root cause, tier, documentation impact, probes | PASS | `tip.js:8` `toFixed(1)`; Hypotheses none; Tier 2; `Documentation impact: N/A — <reason>`; Probes none, `.gitignore` untouched |
| Document committed alone; shape | PASS | `03c34d8 docs: add task total-one-decimal`; nine labels in order; 0 Phase/Step headings |
| Task 1's criteria say the steps are verified by the user and recorded as not verified; the exit says Task 1 cannot be verified unattended | PASS | Both in the document and in the exit message, which then asked run-or-interactive (left there) |
| `### Task 2` exactly when Adjacent cases lists cases | OBSERVATION O1 | Two adjacent cases listed, no Task 2, the record saying "no test framework, so these cases are covered by the manual reproduction steps" — see § 5 |

### 2.3 Tier 3, `batch-b` (two runs: $1.10, $1.52)

Prompt: EUR receipts print `$`; the currency option is ignored.

| Criterion | Result | Evidence |
|---|---|---|
| Reproduction first | PASS | `test/receipt-currency-symbol-ignored.test.ts`, 3 of 3 failing, committed alone `f1e7284` |
| Tier decided from the fix, not the symptom | PASS | The skill found a fix that keeps `formatCents`'s signature (a new `formatMoney` export), judged it Tier 2, and asked which of A (tier 2) or B (a signature change, tier 3) to take. Continued choosing B explicitly, with an unknown currency to throw |
| Tier 3 writes a brief and no task document | PASS | `docs/briefs/receipt-currency-symbol-ignored.md`, first line `# Requirement Brief: …`; sections Outcome, Scope, Failure Modes, The Hard Part (Tier 3 stated, option A recorded as rejected), Constraints, Context (reproduction path and commit), Discovery Notes; no `Discovery Mode:` line; left untracked; `docs/tasks/` gained nothing; the exit suggested `/kenspc-plan docs/briefs/…` and did not invoke it |
| `/kenspc-plan <brief>` detects a brief (Testing Strategy; $0.89) | PASS | generate-plan reported the brief "covers all five discovery dimensions", skipped discussion, drafted the plan in conversation citing the brief and `f1e7284`, and stopped for approval; no file written |

### 2.4 Not reproduced, `batch-b` ($0.57)

Prompt: `percentOff(1000, 15)` returns 149 (the code returns 150).

| Criterion | Result | Evidence |
|---|---|---|
| Ends in a question; no task document or brief; no commit; no untracked test file left by the skill | PASS | The existing test was run (3/3 pass), then a probe with a control assertion under `.kenspc/runs/20260925-194809-diagnose-discount-one-cent-low-15-percent/scratch/orchestrator/1/probe-percent-off.ts` (the D4 layout, a runner-safe name; `.kenspc/` was already ignored); the run stopped listing every attempt and asking where 149 was seen. HEAD unchanged; the only untracked path is the earlier brief. The removal branch of C2 was not needed — the probe never entered the test tree |

### 2.5 Routing, `batch-b-route` ($0.24)

| Criterion | Result | Evidence |
|---|---|---|
| "What does this stack trace mean?" invokes no skill | PASS | 4 turns, 3 Bash calls (read sources, `git status`, `npx vitest run`), no Skill or Agent call; the reply explained the TypeError and noted the trace does not match the committed code; tree clean |

## 3. Row 7 — change-set check

Every run: `/kenspc-task-review` with no arguments; five reviewer Agent
calls, then Schema A → B → C → F; the orchestrator's git before dispatch was
read-only (`git -c core.quotePath=false status --porcelain -uall`,
`rev-parse`, `rev-list`, `merge-base`) plus the one-time `.gitignore`
commit (CRLF line kept); every `File:Line` in the five Issues tables lay
within the set except one stale-README finding (O2); `check-run-contract.sh
--file` was not run on these Schema Bs (the recount was reported by each
run's regression-verifier row 1 instead).

| State | Result | Evidence |
|---|---|---|
| Dirty tree, `batch-b-rev-dirty` (tree `6bbfc45`, 13 min, $5.37) | PASS, and **FAIL F1** on sub-check 1 | `Mode: uncommitted`, `Base: 23fae4f` (the pre-invocation HEAD), 3 paths (`M`, `??`, `??`). After the run HEAD moved only by `2ecab19 chore: ignore kenspc run directory`, `git stash list` empty, the user's three paths still uncommitted with the fixes in place; 24 → 9 unique, FIXED 6 all `—`; Schema C 1–5 PASS (row 5: "code-fixer committed nothing"); verdict PASS; Next steps names the uncommitted files; `npm test` 15/15 afterwards; pre-fix record `index.txt` (`copied src/refund.ts`, `copied test/refund.test.ts`) read by the verifier with `git diff --no-index`. The `find` probe hit `scratch/code-fixer/pre-fix/test/refund.test.ts.txt` — F1, § 4 |
| Dirty tree re-run, `batch-b-rev-dirty2` (tree `20b6a8d`, 15 min, $5.62) | PASS | Same criteria all PASS; pre-fix copies `src/refund.ts.txt`, `src/receipt.ts.txt`, `test/refund.probe.ts.txt`; `find` probe 0 hits; 16 → 12 unique, FIXED 9 all `—`; verdict PASS; `npm test` 21/21 |
| Clean tree two commits ahead of `origin/main`, `batch-b-rev-upstream` (18 min, $6.02) | PASS | `Mode: commits`, `Range: 23fae4f…..2a5dc7c… (upstream)` — the merge base, which is the upstream itself, to the pre-invocation HEAD; the `.gitignore` commit `ce579a1` outside the range; 28 → 11 unique, FIXED 9 each with its own commit, NOT APPLICABLE 1 with its reason; Schema C 1–5 PASS; verdict PASS; `find` probe 0; `npm test` 17/17; tree clean |
| One root commit, no upstream, `.kenspc/` not yet ignored, `batch-b-rev-root` (24 min, $6.99) | PASS, and **FAIL F2** on sub-check 1 | `Range: 4b825dc… (empty tree)..3055ddb… (root commit)`; the `.gitignore` commit `765d686` came after and is outside the range (`.gitignore` is in the table because the root commit adds the file); 45 → 22 unique, FIXED 16 each with a hash; Schema C 1–5 PASS; verdict PARTIAL (a HIGH deferred with a reason: the seeded currency contract); `npm test` 18/18. The `find` probe hit `scratch/regression-verifier/1/test.out` — F2, § 4 |
| `git init`, files, no commit, `batch-b-rev-unborn` (tree `6bbfc45`, 18 min, $6.41) | PASS | `Mode: uncommitted`, `Base: 4b825dc… (no commit yet)`, 17 paths; the run reached Schema F; the only commit is `2028a39` (`.gitignore`), which became the root commit while the pinned base stayed the empty tree (Schema C row 5 says so); 40 → 25 unique, FIXED 21 all `—`; Schema C 1–5 PASS; verdict PARTIAL (the same deferred HIGH). `find` probe 5 hits, all `.test.ts.txt` pre-fix copies — F1 on the pre-fix tree, covered by the dirty re-run, not re-run itself |

Not exercised: a diverged upstream (the merge base differing from the
upstream), custom instructions naming a range or a path, a shallow clone,
`git merge-base` finding no ancestor.

## 4. Findings

**F1 — pre-fix copies kept the `.test.` segment.** Classification: plugin
defect in clarification C10's design, fixed during acceptance. code-fixer's
pre-fix copy `test/refund.test.ts.txt` matches the checklist's name probe
(`*.test.*`) and the scratch naming rule, although vitest collects no
`.txt` file. Fix `20b6a8d`: a `.test.` or `.spec.` segment is renamed
`.probe.` before `.txt` is appended, in `code-fixer.md`,
`regression-verifier.md`, the CHANGELOG, the checklist, and spec
clarification C11. Re-run on a fresh copy: 0 hits (§ 3).

**F2 — regression-verifier named a log `test.out`.** Classification
(provisional, spec author): a behavior slip against a rule the agent's
RUN_DIR bullet already states (`no file named test.* or spec.*`), not a
batch B change and not a rule gap; vitest collected nothing from
`.kenspc/`. Recorded under the roadmap's scratch follow-ups (`e13e5a3`);
no fix in this batch. Sim to confirm the classification.

## 5. Observations

**O1 — no Task 2 with a manual reproduction.** In `batch-b-nofw` the record
listed two adjacent cases and wrote no Task 2, saying the cases are covered
by the manual steps since there is no test framework. A sensible reading
the rule had not stated; `26873f5` adds it to the SKILL and the checklist
(spec C12).

**O2 — the angle reports carry no file list.** The row-7 criterion written
in Task 13 compared "FILE COVERAGE lists" in the five reports; Schema A has
no such list, and a stale-README finding legitimately sits outside the set.
Reworded in `20b6a8d` and `cecde18` to compare the Issues tables'
`File:Line` paths, allowing a stale-document finding.

## 6. Summary

| Item | Result |
|---|---|
| Row 9: tier-2 chain (reproduction commit, document, exit, Skill-tool hand-over, implementation, review) | PASS |
| Row 9: manual reproduction path | PASS (O1) |
| Row 9: tier-3 brief, and `/kenspc-plan` detecting it | PASS |
| Row 9: not reproduced | PASS |
| Row 9: routing | PASS |
| Row 7: dirty tree | PASS after F1's fix (run 1 FAIL on sub-check 1, re-run PASS) |
| Row 7: upstream, root commit, unborn branch | PASS (root: F2 on sub-check 1; unborn: F1 on the pre-fix tree) |
| Guards and validation on the final tree | `guards run: 10`, `self-tests run: 9`, both `claude plugin validate --strict` pass |

Two FAILs, both on the checklist's name probe: F1 fixed and re-verified,
F2 a behavior slip recorded for follow-up. Two observations, both folded
into the tree before release.
