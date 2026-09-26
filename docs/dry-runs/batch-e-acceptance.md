# Batch E acceptance — the review rendered once, Doc-sync documents with the fix, the approved plan written verbatim (3.8.2, unreleased)

Acceptance record for batch E (spec: `docs/plans/batch-e-review-pipeline.md`):
the spec's Testing Strategy cases 1–8 as clarifications CL1–CL15 amend them,
the extra T1 run that CL7 asks for, and the pre-flight block. One machine,
macOS, 2026-09-26, 17:13–17:49. The acceptance session recorded the evidence
and a first reading of each FAIL and did not classify them; the main session
classified them in spec clarification CL16 (`14b8bda`), as the batch D
record's § 3 does (§ 3): one behavior deviation and three observations, no
plugin defect, and no case re-run.

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — the run gave
the criterion nothing to check.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `a94fdb3` (HEAD before the first run and after the last; no commit landed while the runs went on), loaded with `--plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc`. After the last run the main session committed `14b8bda` (spec clarifications CL16–CL17, `docs/plans/batch-e-review-pipeline.md` only; no plugin file), and this record is the only other change |
| Claude Code | 2.1.282 |
| Mode | Headless, one process per invocation through `~/Projects/_smoke/_prompts/e-run.sh <tag> <cwd> <prompt-file> [resume-session-id]` (`claude -p … --plugin-dir … --permission-mode bypassPermissions --output-format json`, cwd the smoke project), waited on with `e-wait.sh`. Prompts are files under `~/Projects/_smoke/_prompts/e-acc-*.txt`. One session was made a session that cannot ask, with `APPEND_SP="Work without stopping; do not ask clarifying questions."`, passed again on its one resume: `e-acc-plan-c` (and `e-acc-plan-c-r1`) |
| Session model | Opus 5.5 (`claude-opus-5-5`) |
| Installed copy | `kenspc@kenspc-claude-plugin` is installed (`~/.claude/plugins/cache/kenspc-claude-plugin` exists — the positive control). In all seven sessions the first `SKILL.md` read is under `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/` (`task-review`, `task-implement`, or `generate-plan`), and `plugins/cache/kenspc-claude-plugin` occurs in 0 of the 85 files under the seven projects' trace directories (19, 15, 3, 23, 4, 3, 18 files) |
| Seed project | `~/Projects/_smoke/batch-e-seed` ("timesheet-lite"), built fresh to the batch D record's Seed project row: `typescript@7.0.2` and `vitest@5.0.1` from the local npm cache with `npm install --offline` (the batch D seed's `package-lock.json`, `tsconfig.json`, and `vitest.config.ts`, which sets `globals: true` and keeps the default include), Node 24.19.0, `npm test` (8 tests) and `npm run typecheck` exit 0, no `CLAUDE.md`, `.gitignore` holding `node_modules/` only. History: `211f348` seed (package files, README intro and Scripts), `bc7fb1a` the task document `docs/tasks/timesheet-durations.md` (Tasks 1–3 TODO, `### Task 4: Doc-sync` written from generate-task's template, `Depends on: Task 1-3`, one entry: `` `README.md` § Duration parsing `` … "edited by Task 1: verify it against the implementation instead of editing it again"), then one commit per task, each carrying its code, its tests, and its status flip to DONE with an `**Implementation notes:**` block: `6090dbe` Task 1 (`parseDuration`, and the README section), `4c5e760` Task 2 (`formatDuration`), `d66eb9c` Task 3 (`totalMinutes`). Task 4 stays TODO |
| Planted defect (D18 seed) | Task 1's criterion: "An empty string, or one of spaces only, throws a `RangeError`". The code's pattern `^(?:(\d+)h)?(?:(\d+)m)?$` matches an empty string, so `parseDuration("")` returns 0 (checked with `node` before any run); no test covers it. The README states the defective behavior on a line of its own: "An empty string parses to 0." |
| Second variant (case 3) | `~/Projects/_smoke/batch-e-seed-b`, same history shape (`1569065`, `6b785e2`, `9e56dc9`), task document byte-identical: Task 1 correct (`parseDuration("")` throws `RangeError`; README line "An empty string, or one of spaces only, throws a `RangeError`."); Task 2 defective — `formatDuration(120)` returns `"2h 0m"` where the criterion says `"2h"`, untested. The README describes `parseDuration` only |
| Third variant (case 7) | `~/Projects/_smoke/batch-e-seed-c`: `605051a` (`parseDuration` throws `RangeError`; `src/entries.ts` `invalidLines`, whose private `isValidEntry` relies on that throw inside a try/catch, no test; `totalMinutes`), then `40abc62` "feat(duration): return null for text that is not a duration" — declares `number | null` and the null contract, updates `totalMinutes` to skip `null`, drops the timesheet throw test, and still throws. No task document, no README section. Probe on a copy under `/tmp` before any run: the natural fix (`return null`, the duration test updated) keeps vitest and `tsc` green, and `invalidLines(["2026-09-01,soon","2026-09-02,1h"])` goes from `["2026-09-01,soon"]` to `[]` |
| Brief (cases 4, 5) | `docs/briefs/weekly-totals.md`, hand-written, untracked, sha256 `e5245e9d…a127`, `## Open Questions` body `none` |
| Projects | APFS clones (`cp -Rc`): `batch-e-case1` (the D18 seed plus driver commits `f963ad2` — Task 4 marked DONE with an Implementation notes block saying the README already describes `parseDuration`, no edit — and `2825b97` "feat(duration): accept a days unit", whose code computes `days * 24`, so `1d` is 24, while its README line and commit body say 1440); `batch-e-t1` (the D18 seed plus the same `f963ad2`); `batch-e-impl` (the D18 seed); `batch-e-impl-b` (the second variant); `batch-e-e4` (the third variant); `batch-e-plan`, `batch-e-plan-c` (the D18 seed plus the untracked brief). The seeds themselves were not run in |
| Traces | `~/.claude/projects/-Users-kenspc-Projects--smoke-batch-e-<project>/<session_id>.jsonl`, subagents under `<session_id>/subagents/`; results in `~/Projects/_smoke/_logs/e-acc-<tag>.json`, timeline in `e-timeline.log`, per-session costs in `e-acc-costs.txt` |
| Cost | 7 sessions (the cap), $26.31: `e-acc-review` $4.15, `e-acc-impl` $0.86, `e-acc-impl-b` $5.45, `e-acc-plan` $2.64, `e-acc-plan-c` $2.87, `e-acc-e4` $4.10, `e-acc-t1` $6.23 — each a session's last `total_cost_usd`, which on a resumed session is its running total. The driver session, $7.86 (its `total_cost_usd`, reported by the main session). Total $34.17, within the $36 budget |

**Independence.** The acceptance driver — a headless session opened by the
main session — built the three seeds, the planted defects, the README
sentences, the task document and its Implementation notes, the two driver
commits (`f963ad2`, `2825b97`), and the brief; wrote the prompts; typed every
answer; and wrote this record. It took no part in the batch's design
rulings. What the plugin's runs produced — reviews, `schema-b.md` files, fix
commits, the plans, the traces — is independent of that. What the driver
typed is not, and each answer is quoted where it was given.

## 2. Cases

### 2.1 Case 1 — rows 6 / 7, standalone review, E-2 out of scope (`batch-e-case1`, `e-acc-review`, `0fd3ec35`, $4.15)

Prompt `/kenspc-task-review`; no question asked. `change-set.md` exists:
`Mode: commits`, `Range: f963ad2…..2825b97… (HEAD~1)`, files `README.md`,
`src/duration.ts`, `test/duration.test.ts`. Dispatch order: the five
reviewers, then `kenspc:code-fixer`, then `kenspc:regression-verifier`.

- Progress lines: **FAIL (F1).** After the five reviewers the only text
  before the code-fixer dispatch is "All five replies came back with a
  Findings table, a report path and a closing line. Next I'll confirm the
  report files are on disk and look at the stray file quality-reviewer
  mentioned." — no `Reviewers returned —` line; the phrase occurs in the
  transcript only inside the loaded skill text. The other two lines are
  there, each after its agent and before the next step, but wrapped in
  backticks: `` `code-fixer returned — FIXED 4, DEFERRED 1, NOT APPLICABLE 0 — /Users/kenspc/Projects/_smoke/batch-e-case1/.kenspc/runs/20260926-171409-changes/schema-b.md` ``
  and `` `regression-verifier returned — CLEAN` `` (O2).
- No text line beginning with `|` from the first reviewer call to the final
  report's first heading (`## Review summary`): 0 lines. **PASS**
- Across the session's assistant text the roll-up header
  (`| Angle | HIGH | MEDIUM | LOW |`), a line holding `total reported `, and
  the Schema C header (`| # | Check …`) each occur once, inside Schema F.
  **PASS**
- code-fixer's reply (its subagent transcript's last text) has no
  `Doc-sync documents:` line; no Action cell in `schema-b.md` carries
  `— updated` or `— not updated`. **PASS**
- Fix commits `da825ea` (`src/duration.ts`), `8730cce`, `e867977`
  (`test/duration.test.ts`), `60add21` (`src/duration.ts`,
  `test/duration.test.ts`); `3e82082` is the `.gitignore` commit. None touches
  `README.md`. **PASS**
- `check-run-contract.sh --file` on the run's `schema-b.md`: exit 0. Verdict
  PASS (the days bug fixed in `da825ea`). Row 4, E3 "empty input parses to 0;
  docs conflict" (MEDIUM), was DEFERRED, and README.md was left as it was —
  the out-of-scope behavior the case exists to show (O5).

### 2.2 Case 2 — rows 5 / 6, `/kenspc-task-implement` on the D18 seed (`batch-e-impl`, `e-acc-impl`, `91ea4347`, $0.86)

First invocation: "Found 1 incomplete task to auto-implement: 1. Task 4:
Doc-sync … Proceed with automated implementation?" Driver's answer
(`e-acc-impl-r1`): **"yes"**.

The implementer marked Task 4 **BLOCKED** in `dd5a23f` (task document only)
and the run ended "All tasks blocked. Skipping code review." with verdict
BLOCKED. Its reason, from the final report: "the pattern in
`src/duration.ts` matches an empty string, so blank input returns 0. The
README line Task 1 added says the same. Both contradict Task 1's spec …
there was no correct move inside Task 4's scope: Keeping the README line
would present a bug as intended behavior. Rewriting it to 'throws' would
describe behavior the code doesn't have. Fixing the code is outside Task
4's scope." It offers two ways to unblock (set Task 1 back to TODO, or
change Task 1's criterion) and lists one entry under
`### Decisions needing a home`.

- Task 4 `**Status:** DONE` after the run: **FAIL (F2)** — BLOCKED.
- Every later criterion (the Schema B row's `FIXED — updated README.md`, the
  fix commit's README hunk and body, the reply line, Schema G's bullet, E-1
  with Schema G): nothing to check — no review ran. E-2's code-fixer path
  was exercised by T1 (§ 2.7) instead; E-1 in `/kenspc-task-implement` by
  case 3.

### 2.3 Case 3 — counter-example (`batch-e-impl-b`, `e-acc-impl-b`, `b9a0fe85`, $5.45)

Same first question; driver's answer (`e-acc-impl-b-r1`): **"yes"**. Task 4
DONE in `c05d1c4` (task document only). Review run
`20260926-171703-timesheet-durations`.

- Progress lines, each after its agent and before the next step:
  `Reviewers returned — HIGH 5, MEDIUM 7, LOW 6 — …/angle-1.md … angle-5.md`,
  `code-fixer returned — FIXED 6, DEFERRED 2, NOT APPLICABLE 1 — …/schema-b.md`,
  `regression-verifier returned — CLEAN`. **PASS**
- No `|` line between the first reviewer call and Schema G's first heading
  after the last dispatch; roll-up header, `total reported `, and Schema C
  header once each, inside Schema G; `re-check` 0 times. **PASS**
- FIXED 6 > 0; the FIXED commits `99f9fa6`, `325bd16` (`src/duration.ts`,
  tests), `7973c02`, `ae84cc1`, `0ad29db`, `818b1f2` (tests only) — none
  touches `README.md`. **PASS**
- code-fixer's reply: `Doc-sync documents: none affected by the fixes`,
  also rendered in Schema G's `## Fixes`. Next steps holds
  `- No Doc-sync document describes behavior the fixes changed.` **PASS**
- `README.md` sha256 `4808187a…` at the seed, after `c05d1c4`, and at the end
  of the run. **PASS**
- Recount on the run's `schema-b.md`: exit 0. Verdict PASS (the planted
  `formatDuration` defect fixed in `99f9fa6`).

### 2.4 Case 4 — row 4, interactive approval (`batch-e-plan`, `e-acc-plan`, `6f9737e9`, $2.64)

First invocation: the gap-check asked two questions (Q1 the return shape,
recommending `{ week: string; minutes: number }[]`; Q2 what a malformed line
is, noting Task 1's empty-string criterion against the code). Driver's
answer (`e-acc-plan-r1`): **"Q1: yes, the { week: string; minutes: number }[]
array. Q2: as you recommend — a bad date throws a RangeError naming the
date, and the duration is handled exactly as totalMinutes handles it, empty
counting as 0. Leave the Task 1 difference out of scope."** The second
invocation ended at the approval stop with the full draft and no write to
the project; its last line: "To approve, reply with approval (e.g. "write
it") and I'll save this exact draft to `docs/plans/weekly-totals.md` …".
Driver's answer (`e-acc-plan-r2`): **"Write it."**

- How the plan was written: during drafting the session wrote the draft to
  its own scratchpad (`…/scratchpad/weekly-totals-plan-draft.md`, a Write
  then an Edit); on approval it ran
  `mkdir -p docs/plans && cp …/scratchpad/weekly-totals-plan-draft.md docs/plans/weekly-totals.md`.
  The trace has no Write call to `docs/plans/`. **FAIL (F4)** by the letter
  of the criterion, whose first half compares "the Write call's `content`".
- The blob of the first commit of the plan, `357e6f9` "docs: add plan
  weekly-totals" (then `a5c9a88`, `987933c` by the reviewer), 9,871
  characters after normalization, occurs as one block of the approval-stop
  `result`. Outside it: before, the self-challenge insight block ending
  "## Draft plan (after self-challenge)" and a fence line of four
  backticks and `markdown` (729 characters); after, the closing fence, "## What the
  self-challenge found and changed", "## One decision for you" (README left
  N/A), and the approval line (1,959 characters). No heading line of the
  plan lies outside the block. Positive control: the blob with `Weekly` →
  `weekly` is not contained. **PASS**

### 2.5 Case 5 — row 4, cannot-ask, then `--resume "approved"` (`batch-e-plan-c`, `e-acc-plan-c`, `2d944637`, $2.87)

`APPEND_SP` on both invocations. The first invocation ($1.35) ended with the
full draft and the line `Plan not written: awaiting approval.`, HEAD
`d66eb9c` and `git status --porcelain -uall` (only the untracked brief)
unchanged, no Edit and no Agent call — but two Write calls, both into the
session's harness scratchpad:
`/private/tmp/claude-501/-Users-kenspc-Projects--smoke-batch-e-plan-c/2d944637-…/scratchpad/check.ts`
and `…/scratchpad/tz.ts` (probes of the ISO-week arithmetic).
**FAIL (F3)** by the letter of "no Write"; the project was not written.

Driver's answer (`e-acc-plan-c-r1`, reminder passed again): **"approved"**.
The resumed invocation wrote `docs/plans/weekly-totals.md` with one Write
call, dispatched `kenspc:plan-document-reviewer`, and committed `f6f70f2`
"docs: add plan weekly-totals", then `4b3b186`, `efe334d`, `ea18ad0`,
`62f4cd4`.

- The Write call's `content` and the blob at `f6f70f2` are identical (10,750
  characters) and occur as one block of the first invocation's `result`.
  Outside it: before, the not-written notice, Discovery, the six
  self-challenge items, the insight block, and a `---` rule (2,833
  characters); after, a `---` rule, `Plan not written: awaiting approval.`,
  "How to continue", and "Found while planning, not changed" (949
  characters). No plan heading outside the block. Positive control fails as
  it should. **PASS**

### 2.6 Case 7 — E-4 live (`batch-e-e4`, `e-acc-e4`, `1d54ff14`, $4.10)

Prompt `/kenspc-task-review`; `Mode: commits`, `Range: 605051a….40abc62… (HEAD~1)`.
All five reviewers reported the planted defect, and all five also reported
`isValidEntry`'s reliance on the throw (row 2: "isValidEntry not updated
for null contract", `src/entries.ts:13`). code-fixer: FIXED 0, DEFERRED 4
(all HIGH). Its Deferred paragraph for row 1: "the coherent fix spans files
outside the change-set boundary, and the choice between the two coherent
designs needs a user decision"; its combined fix was tried in
`scratch/code-fixer/1/full`: "7/7 tests pass and `tsc` exits 0". No fix
landed, so no regression arose. Verdict PARTIAL ("All 4 HIGH issues are
deferred with that rationale, which is why this is PARTIAL rather than
FAIL" — the PARTIAL rule's own example). **Not exercised** (M12).

The run's progress lines: `Reviewers returned — HIGH 7, MEDIUM 10, LOW 0 — …`
and `code-fixer returned — FIXED 0, DEFERRED 4, NOT APPLICABLE 0 — …` are
there; after the regression-verifier dispatch the next text is Schema F's
`## Review summary` — no `regression-verifier returned —` line, although
the verifier's reply carries a result ("**Overall: CLEAN.** The fix stage
accounted for every issue and broke nothing."). Case 7's criteria do not
include E-1; recorded under F1 as further evidence. Tables: 0 between
dispatches, each once in Schema F.

### 2.7 T1 — `/kenspc-task-review <task doc>`, REVIEW_SCOPE `task`, Doc-sync DONE (`batch-e-t1`, `e-acc-t1`, `d17767f8`, $6.23)

Task 4 was made DONE by the driver (`f963ad2`, § 1). Prompt
`/kenspc-task-review docs/tasks/timesheet-durations.md`; no question asked.
Run `20260926-173114-timesheet-durations`.

- Progress lines: `Reviewers returned — HIGH 6, MEDIUM 11, LOW 6 — …/angle-1.md … angle-5.md`,
  `code-fixer returned — FIXED 9, DEFERRED 2, NOT APPLICABLE 0 — …/schema-b.md`,
  `regression-verifier returned — CLEAN`, each after its agent. No `|` line
  between dispatches; roll-up header, `total reported `, Schema C header once
  each, inside Schema F. **PASS**
- code-fixer's reply:
  `Doc-sync documents: updated README.md (row 1, 5ada069); updated README.md (row 3, 5ada069)`
  — both parts in CL12's `updated <path> (row <n>, <commit>)` form. **PASS**
- `schema-b.md`: row 1 (R1, E1, Q1, B1, T1 — "empty or blank duration parses
  to 0", HIGH, `src/duration.ts:1`) and row 3 (R2, E2, Q2, B3 — "README says
  an empty string parses to 0", MEDIUM, `README.md:16`) have Action
  `FIXED — updated README.md`, commit `5ada069`; rows 2, 4, and 5 are FIXED
  in the same commit (O4). **PASS**
- `5ada069` "fix(duration): reject an empty or blank duration" touches
  `README.md`, `src/duration.ts`, `test/duration.test.ts`,
  `test/timesheet.test.ts`; its body holds "Updates README.md to match the
  fix."; its README hunk changes one line and adds no heading:

  ```
  -An empty string parses to 0.
  +An empty string, or one of spaces only, throws a `RangeError`.
  ```

  The other fix commits (`953598f`, `2c686f9`, `409ec2a`, `be275fa`) do not
  touch `README.md`. **PASS**
- Schema F's Next steps:
  `- **Doc-sync documents:** updated README.md (row 1, 5ada069); updated README.md (row 3, 5ada069)`
  — a bullet written from the reply line; `code-fixer's reply has no Doc-sync
  documents line` does not occur. **PASS**
- Recount on the run's `schema-b.md`: exit 0. Verdict PASS.

### 2.8 Case 8 — mechanical, repository tree `a94fdb3`

- Effort-override diff: exit 0. `claude plugin validate --strict .` and
  `./plugins/kenspc`: both "✔ Validation passed". `bash scripts/check-all.sh
  --self-test`: exit 0, `guards run: 10`, `self-tests run: 9`, 19 PASS lines,
  no FAIL. **PASS**
- Pointer-label grep on `task-review/SKILL.md`, `task-implement/SKILL.md`,
  `code-fixer.md`, `generate-plan/SKILL.md`: 0 lines each (positive control:
  175 lines on the batch D spec). **PASS**
- Byte-identity against `6575540`, run as a bash script file: the
  `canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`, and
  `canonical:verdict-shared` blocks in both SKILLs (56, 32, 1, 14 lines) and
  `canonical:principle:simplicity-first`, `canonical:principle:surgical-changes`,
  `canonical:stats-line`, and `example:schema-b` in `code-fixer.md` (1, 1, 1,
  25 lines) are identical; a one-character mutation of a block compares
  different. **PASS**
- Zero-diff set: `git diff --stat 6575540 HEAD -- …` prints nothing.
  `generate-plan/SKILL.md`'s hunks lie at new-side lines 363–381 and
  392–395, inside Step 3 (lines 340–398). **PASS**
- Text: `Regressions and deferred issues in the verdict` on one line of
  `plugins/kenspc/README.md` (352); the item quotes both
  `introduced unresolved regressions` and `MEDIUM and LOW issues do not
  change the verdict but appear in the report.`; the first occurs in both
  skills and the second in `task-review/SKILL.md` (files read with line
  breaks joined); `re-check` 0 times in `task-implement/SKILL.md` (positive
  control: line 436 at `6575540`); the `## 3.8.2 — unreleased` entry holds
  ``read the transcripts with `jq` `` and its Known behavior bullet;
  `grep -n 'read the transcripts with' plugins/kenspc/CHANGELOG.md` finds
  line 30. **PASS**
- Recount on every real `schema-b.md` of the acceptance (cases 1, 3, 7, T1):
  exit 0 each.

## 3. Findings

Each finding keeps the acceptance session's evidence and first reading,
followed by its classification — plugin defect, behavior deviation, or
observation — classified by the main session in CL16 (`14b8bda`). No
finding is a plugin defect, no plugin file changes, and no case is re-run.

**F1 — a progress line is missing in two of four review runs.** Case 1
printed no `Reviewers returned —` line: the session wrote "All five replies
came back with a Findings table, a report path and a closing line. Next
I'll confirm the report files are on disk …" and dispatched code-fixer.
Case 7 printed no `regression-verifier returned —` line, neither the CLEAN
form nor `regression-verifier returned — no result line`, although the
verifier's reply held "**Overall: CLEAN.**"; its final report followed the
dispatch directly. Tally across the four review runs (cases 1, 3, 7, T1):
the reviewers line 3 of 4, the code-fixer line 4 of 4, the verifier line 3
of 4. Every other E-1 criterion held in all four: no table between
dispatches, each table once in the final report. The plugin's text:
task-review Step 4, "Here, print only this line, with the totals and the
run directory filled in", and the release checklist's rows 6 and 7 find
the lines in the trace. First reading: behavior deviation — the steps
carry the lines and the same skill printed them in the other runs; case 1's
miss came in the turn where the session checked the report files on disk,
case 7's in the turn that rendered the final report.

*Classification — **behavior deviation**, classified by the main session
(CL16).* Across the four review runs 10 of 12 progress lines were printed.
The steps carry each line where it is printed, and the same text printed it
in the other runs; E-1's substance — no table between dispatches, each
table once in the final report — held in all four runs. Recorded on the
roadmap in the release commit; the follow-up to weigh is tying each line to
the next dispatch (printed in the message that makes it), so its absence
cannot pass unnoticed by the next step.

**F2 — case 2's Doc-sync task BLOCKED, so the review never ran.** The
seed followed D18: the README states the defective behavior ("An empty
string parses to 0.") and Task 1's criterion contradicts it. The
implementer compared the README with Task 1's criterion, found no move
inside Task 4's scope, marked Task 4 BLOCKED, and skipped the review (§
2.2). T1's final report names the same mechanism from the other side: "the
README described the bug as intended …, and Task 4's Doc-sync compared the
README with the code, not with the task". First reading: an observation on
the seed rather than a plugin defect — the implementer's BLOCKED follows
its own rules, and D18's premise (the README states the defect first) is
exactly what a Doc-sync task that reads the task criteria refuses to
verify. E-2's code-fixer rule was exercised live by T1 (§ 2.7). What stays
unexercised is task-implement's Schema G bullet in its `updated` form and
row 6's `/kenspc-task-implement` path with a README correction.

*Classification — **observation (seed)**, classified by the main session
(CL16).* D18's premise, a README that states the defect first, is what
task-implementer's Doc-sync refuses to confirm against the task's
criterion, and the BLOCKED follows its own rules. code-fixer's rule was
exercised live by T1, with Schema F's bullet in its `updated` form; Schema
G's bullet in its `updated` form, on row 6's `/kenspc-task-implement` path,
is recorded as not exercised (§ 5), since a re-run with a new seed does not
fit the batch's budget; Schema G's `none` form was exercised by case 3.
Case 2 is not re-run.

**F3 — case 5's first invocation made two Write calls.** Both are probes
into the session's harness scratchpad (`/private/tmp/claude-501/…/scratchpad/check.ts`,
`tz.ts`); the project's HEAD and status were unchanged, and there was no
Edit and no Agent call. Release-checklist row 4: "the trace shows no Write,
no Agent call, and no commit". First reading: observation — the criterion's
wording does not tell a scratch probe from a write of the plan; the
behavior it guards (nothing written before approval) held.

*Classification — **observation**, classified by the main session (CL16):
row 4's wording.* Nothing reached the project before approval, which is
what the criterion guards. The release-preparation session brings row 4 in
line: before approval, no Write or Edit into the project, no Agent call,
and no commit — a probe written outside the project is not a write of the
plan.

**F4 — case 4 wrote the plan with `cp`, not a Write call.** The session
kept its draft in a scratchpad file, printed it for approval, and on "Write
it." copied that file to `docs/plans/weekly-totals.md`; the first commit's
blob equals the printed draft (§ 2.4). Row 4 and D14 compare "the Write
call's `content`" and the blob, so the first half has nothing to compare.
First reading: observation — the verbatim property E-5 asks for holds on
the committed file; the criterion assumes the one way of writing the
cannot-ask run used.

*Classification — **observation**, classified by the main session (CL16):
row 4's and D14's wording.* The first committed blob equals the printed
draft character for character, which is what E-5 asks. The
release-preparation session brings row 4 in line: after approval, the plan
as first written — the Write call's `content` when it was written with
Write, and in every case its blob in `plan-document-reviewer`'s first
commit — equals the draft last printed in full, under the normalization row
4 states. This record leaves the checklist unchanged.

## 4. Observations

- **O1** — A user-level hook, not the driver, started headless sessions
  (entrypoint `sdk-py`, first message "Review this change for security
  vulnerabilities.") on commits: 4 in `batch-e-seed`'s trace directory
  (the driver's seed commits), 4 in `batch-e-case1`, 6 in `batch-e-impl-b`,
  5 in `batch-e-t1`. They are not costed, and the source-gate count includes
  their files (0 cache hits).
- **O2** — Case 1's code-fixer and regression-verifier progress lines were
  wrapped in backticks, as inline code; the text inside matches the fixed
  form. The other runs printed them bare.
- **O3** — T1's driver session transcript carries the entrypoint
  `claude-vscode`, while the hook sessions carry `sdk-py`.
- **O4** — In T1, rows 1–5 were fixed in one commit, `5ada069`, and
  `README.md` was corrected under both row 1 (the planted defect) and row 3
  (a reviewer's own README finding, `README.md:16`); the reply lists both
  parts with the same commit. Case 2's spec note ("If a reviewer reports the
  README's drift as a finding of its own and the README changes under that
  row instead, the record says so") applies here, to T1.
- **O5** — In case 1 (`changes` scope, a DONE Doc-sync task in the tree), the
  edge-case reviewer reported the empty-string conflict (E3, MEDIUM,
  "README.md:16 says `""` parses to 0, but the Task 1 criterion … says it
  should throw"); code-fixer DEFERRED it and touched no document.
- **O6** — Case 3's code-fixer also made `parseDuration` reject a duration too
  large to count exactly (`325bd16`) and reported no listed document
  affected; Schema G's Next steps notes that § Duration parsing does not
  mention the limit — no text was added, as E-2's limits require.
- **O7** — Every child session ran in the user's explanatory output style
  (`★ Insight` blocks in its messages); the draft messages of cases 4 and 5
  carry one outside the plan block.
- **O8** — Case 7's verdict PARTIAL with four HIGH rows deferred follows
  task-review's PARTIAL rule ("HIGH issues are deferred with explicit
  rationale and the user must decide whether to accept").

## 5. Not exercised

Budget (7 sessions, the cap set by the main session; every session was used):

- Case 6 (a change asked for at approval) — cut first, by the main
  session's order, to stay within 7 runs.
- Case 7's E-4 criterion (verdict FAIL naming a regression) — code-fixer
  deferred the fix and named the `invalidLines` breakage itself (§ 2.6),
  so no regression arose (M12). E-4's text checks passed (§ 2.8).
- Schema G's Doc-sync bullet in its `updated` form, on row 6's
  `/kenspc-task-implement` path (F2, CL16): case 2's Doc-sync task was
  BLOCKED, so its `FIXED — updated` row, fix-commit README hunk, and Schema G
  bullet had nothing to check, and a re-run with a new seed does not fit the
  batch's budget. The code-fixer side ran in T1, with Schema F's bullet in
  its `updated` form; Schema G's `none` form ran in case 3.
- CL4's two failure-path lines (`code-fixer returned — no statistics line`,
  `regression-verifier returned — no result line`) and the missing-line
  bullet: no reply lacked its closing line. (Case 7's verifier reply had a
  result and still got no line — F1.)
- T2, the "not updated" branch (a listed document with uncommitted changes,
  or a correction that needs a new section); T3, the section boundary and a
  document outside the list; T7, a translated `**Documents**` label.
- Rows 6 and 7's HAS ISSUES form: every regression-verifier run was CLEAN.

Other reasons: Windows and WSL2 were not run — macOS only.

## 6. Summary

| Item | Result |
|---|---|
Repository tree `a94fdb3`, macOS only.

| Case | Session | Result |
|---|---|---|
| 1: rows 6 / 7, standalone review — tables once in Schema F, none between dispatches; no `Doc-sync documents:` line, no Action suffix, README untouched | `e-acc-review`, `0fd3ec35`, $4.15 | PASS, and **FAIL F1** (no `Reviewers returned —` line) — behavior deviation, roadmap |
| 2: `/kenspc-task-implement`, Doc-sync DONE and the README corrected in the fix commit | `e-acc-impl`, `91ea4347`, $0.86 | **FAIL F2** (Task 4 BLOCKED; review skipped) — observation on the seed; Schema G's `updated` form not exercised; not re-run |
| 3: counter-example — README untouched, `none affected` reply, the no-document bullet, E-1 with Schema G | `e-acc-impl-b`, `b9a0fe85`, $5.45 | PASS |
| 4: row 4 interactive — the committed plan equals the approved draft | `e-acc-plan`, `6f9737e9`, $2.64 | PASS on the blob, and **FAIL F4** (no Write call to compare) — observation, row 4 and D14 wording |
| 5: row 4 cannot-ask — stop at the draft, then `approved` writes it verbatim | `e-acc-plan-c`, `2d944637`, $2.87 | PASS on the comparison, and **FAIL F3** (two scratchpad Writes before approval) — observation, row 4 wording |
| 6: a change asked for at approval | — | Not exercised (run cap) |
| 7: E-4 live | `e-acc-e4`, `1d54ff14`, $4.10 | Not exercised (code-fixer deferred); text checks PASS; F1's second miss |
| T1: REVIEW_SCOPE `task`, Doc-sync DONE — reply line, Action suffix, README corrected in the fix commit, Schema F bullet, E-1 | `e-acc-t1`, `d17767f8`, $6.23 | PASS |
| 8: pre-flight (10 / 9 guards), both validations, byte-identity, zero diff, text, E-3 in the CHANGELOG | — | PASS |

Cost: the seven run sessions $26.31, the driver session $7.86, total $34.17
within the $36 budget.

Four FAILs, all classified by the main session in CL16 (`14b8bda`). F1, a
progress line not printed in two of four review runs (10 of 12 printed), is
a behavior deviation recorded on the roadmap in the release commit; E-1's
substance held in all four runs. F2, case 2's Doc-sync task BLOCKED by a
seed whose README stated the defect first, is an observation on the seed;
T1 carries E-2's live evidence, and Schema G's `updated` form is not
exercised. F3 and F4 are observations on row 4's wording, where nothing
reached the project before approval and E-5's verbatim property held; the
release-preparation session rewords row 4. No plugin defect, no plugin file
changed, and no case re-run. The smoke projects are kept under
`~/Projects/_smoke/batch-e-*`.
