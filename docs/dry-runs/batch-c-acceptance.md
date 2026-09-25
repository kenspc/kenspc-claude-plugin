# Batch C acceptance — Open Questions in briefs, the generate-plan exit, /kenspc-prototype (3.8.0, unreleased)

Acceptance record for batch C (spec: `docs/plans/batch-c-prototypes.md`):
release-checklist smoke rows 3, 4, and 10, the spec's Testing Strategy
cases the budget allowed, the collection counter-case for the ruling that
keeps prototypes out of the project's gates, and the pre-flight block. One
machine, macOS, 2026-09-26, 00:16–01:26, and a re-run of two cases at
01:39–01:48. The acceptance session recorded the evidence and a first
reading of each FAIL; the main session classified them, as the batch B
record's § 4 does (§ 3). One fix was made after the first pass, in the
spec-author session and never in a run's project: `2798c6f` (spec
clarification CL12, `b945e45`), after which the two cases it affects were
re-run in new projects (§ 2.6).

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — the run gave
the criterion nothing to check.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `4eb14b0` (plugin files last changed in `f49e4f2`) for the first pass; `b945e45` (F2's fix `2798c6f`, then CL12) for the re-run; loaded with `--plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc`; the tree was not changed during either pass |
| Claude Code | 2.1.282 |
| Mode | Headless, one process per run through `~/Projects/_smoke/_prompts/run-acc.sh` (`claude -p "<prompt>" --plugin-dir … --permission-mode bypassPermissions --output-format json`, cwd the smoke project); a run that stopped at a question was continued with `claude -p --resume <session_id> "<answer>"` from the same directory with the same flags. One run was made a session that cannot ask, with `--append-system-prompt "Work without stopping; do not ask clarifying questions."`: `c-acc-plan-cannot` |
| Session model | Opus 5.5 (`claude-opus-5-5`, the only key in every run's `modelUsage`) |
| Installed copy | `kenspc@kenspc-claude-plugin` 3.7.0 is also enabled and has no prototype skill. The commands load their skill by reading its `SKILL.md` (no Skill-tool call, so no base-directory line), so the source gate is the path read: in all eleven transcripts the first `SKILL.md` read is under `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/`, and `plugins/cache/kenspc-claude-plugin` occurs 0 times |
| Seed project | `~/Projects/_smoke/batch-c-seed` at `181cc38`: TypeScript 7.0.2 and vitest 5.0.1 installed with `npm install --offline` from the local npm cache, Node 24.19.0; `vitest.config.ts` with only `globals: true`; `tsconfig.json` with `include: ["**/*"]` and no `allowJs`; scripts `test`, `typecheck` (`tsc --noEmit`), `render` (prints a route's HTML), `db:init`; `README.md` documenting pages, scripts, and both databases; no `CLAUDE.md`; `.gitignore` = `node_modules/`, `*.db` (no `prototypes/`); committed `.env.development` (`DATABASE_PATH=./dev.db`) and `.env.production` (`DATABASE_URL=postgres://prod.example.invalid/app`); ignored `dev.db` from `npm run db:init` (table `expenses`, 3 rows, sha256 `379cc27f…c652`); `src/routes.ts` registers the pages, whose nav and layout come from the app; 4 test files, 10 tests green, typecheck green. Positive control: a `.ts` file with a type error under `prototypes/` makes `tsc --noEmit` exit 1 |
| Projects | `batch-c` (brief and the two plan-exit runs), `batch-c-proto` (seed copy and the brief snapshot: prototype runs 4.1, 4.2, 4.4, the plan-after run; the driver committed `CLAUDE.md` naming `spikes/<slug>/` as `7601a16` between 4.1 and 4.2), `batch-c-ui` (seed copy, driver commit `3424511` adding a `CLAUDE.md` that names the in-app location `src/pages/prototypes/<slug>/` registered in `src/routes.ts`, and the brief snapshot: runs 4.3 and 4.5). For the re-run, two new seed copies with every brief entry unanswered: `batch-c-proto2` (driver commit `fbf0448`, the `spikes/<slug>/` CLAUDE.md) and `batch-c-ui2` (driver commit `48d40d1`, the in-app CLAUDE.md); the first-pass projects were not touched |
| Brief snapshot | The brief `c-acc-brief` wrote, `docs/briefs/maybank-csv-import.md` (sha256 `cf637ae2…160f`), copied untracked into `batch-c-proto`, `batch-c-ui`, `batch-c-proto2`, and `batch-c-ui2` before their first runs |
| Traces | `~/.claude/projects/-Users-kenspc-Projects--smoke-<project>/<session_id>.jsonl`, subagents under `<session_id>/subagents/`; results in `~/Projects/_smoke/_logs/<tag>.json`, timeline in `c-timeline.log` |
| Cost | 11 sessions, $17.07: the first pass 9 sessions, $14.24 (budget 9 and $16), the re-run 2 sessions, $2.83 (budget 2 and $5); each session's cost is in its heading. Every figure is the session's last `total_cost_usd`, because on a resumed run that value is the session's running total, not the invocation's: `c-acc-plan-exit-r1` reports `modelUsage.outputTokens` 3010 = 2666 (first invocation) + 344 (its own `usage`) |

**Independence.** The acceptance driver — a headless session opened by the
main session — built the seed, wrote the prompts, typed every answer, and
wrote this record; it took no part in the batch's design rulings. What the
plugin's own runs produced — briefs, plans, commits, brief write-backs,
trace — is independent of that. What the driver typed is not, and each
answer is quoted where it was given, as are the driver's four `CLAUDE.md`
commits and the questions given as text.

## 2. Cases

### 2.1 Row 3 — `/kenspc-brief`, `batch-c` (`c-acc-brief`, `a9f3b2f4`, $0.93)

Prompt (driver): a Maybank CSV import for the app, with the outcome, scope,
two failure modes, two unknowns "I would rather measure than debate" (50,000
rows under 2 s with `node:sqlite`; duplicate detection in a new fingerprint
table with `UNIQUE` and `INSERT OR IGNORE`), and "which bank comes next is
my partner's call". Answer to the one gap question: "Option 1: identical
lines on the same day are separate purchases and both are kept; the
fingerprint is account + date + description + amount + occurrence number.
That covers it — write the brief."

| Criterion | Result | Evidence |
|---|---|---|
| First user-facing prompt is a question, not a draft | PASS | `rapid-direct`; the first reply ended "Question 1: what counts as 'the same line'?" with options and a recommendation |
| `## Open Questions` lists what discussion could not settle; each `needs prototype` entry has `Settled by:` | PASS | Between `## Context` and `## Discovery Notes`: 1 and 2 `` `needs prototype` `` (import speed; fingerprint dedup), each with `Settled by:` naming measurable results; 3–6 `` `open` ``; `Discovery Mode: rapid-direct`; brief untracked (O1, O2) |
| Next step names `/kenspc-prototype` first | PASS | `/kenspc-prototype docs/briefs/maybank-csv-import.md 1` and `… 2`, then `/kenspc-plan …`, "If you skip the prototypes, /kenspc-plan will stop and ask about both"; nothing invoked |
| Hook text, live | PASS | The brief's Write drew the reminder naming "prototype (/kenspc-prototype), which records a prototype's answer in an existing brief's Open Questions" (O9) |

### 2.2 Row 4 — `/kenspc-plan <brief>`

| Run | Criterion | Result | Evidence |
|---|---|---|---|
| `c-acc-plan-exit`, `batch-c` (`26f34762`, $0.38) | The first question is prototype-first or carry, before any gap-check question | PASS | Listed entries 1 and 2 and asked "prototype first, or carry into the plan?", recommending both first; no gap question before it |
| same | "Prototype first" ends the run with the `/kenspc-prototype` lines and no file | PASS | Answer: "Prototype both first." → two lines `/kenspc-prototype docs/briefs/maybank-csv-import.md 1` / `… 2`, "I haven't written a plan or any file"; brief sha256 and HEAD unchanged; no Skill call |
| `c-acc-plan-cannot`, `batch-c`, cannot-ask (`e5aaa72a`, $4.17) | No question; `needs prototype` entries carried with `Not prototyped: the session could not ask`; every `open` entry carried without a gap round | PASS | One invocation, no question; the plan's Open Questions: entries 1–2 with `From: docs/briefs/maybank-csv-import.md, entry <n>`, `Not prototyped: the session could not ask`, `Assumed in:`; entries 3–6 with `From:` and `Assumed in:` only; "Entries 3–6 (`open`) are carried straight in" |
| same | The plan is written only on approval | **FAIL F1** | Written without approval, reviewed, and committed four times — § 3 |
| same | Reviewer call, Schema E table, `## Documentation impact` | PASS | Reached only because of F1: `Agent kenspc:plan-document-reviewer`, a four-angle result table, the section present |
| `c-acc-plan-after`, `batch-c-proto`, after entries 1, 2, 7 were answered (`48973f23`, $1.69) | No exit question when no `needs prototype` entry remains; `open` entries go into the gap round | PASS | The first reply was the gap round: entries 4, 3, 5 asked about, 6 carried as not affecting the plan. Answer: "1. No real export to hand — carry Open Question 4 as open. 2. Agreed: reject the whole file and list every malformed line. 3. Leave import_batches out. 4. Right, dev.db holds no hand-typed expenses, so Open Question 5 does not affect this plan; your three recommendations are fine. Draft the plan; I'll review it before you write it." |
| same | An `open` entry the gap round does not settle is carried with `From:` and `Assumed in:`; answered entries are settled input and cited by hash | PASS | Draft Open Questions: entry 4 and entry 6, each `From: …, entry <n>` and `Assumed in:`; entries 3 and 5, settled in the round, not carried. The draft cites `e1f4e19` (3 lines), `89cc6be` (4), `062b257` (2); `## Documentation impact` present; it stopped for approval with no Write, no Agent call, and no commit |

### 2.3 Row 10 — `/kenspc-prototype`

**4.1 Default location, logic question, `batch-c-proto` entry 1
(`c-acc-proto-default`, `1d9bf065`, $1.44).** Prompt
`/kenspc-prototype docs/briefs/maybank-csv-import.md 1`; answer at the gate:
"1 — use the throwaway database."

| Criterion | Result | Evidence |
|---|---|---|
| The trace shows the frame; snapshots before writing | PASS | Frame table (question, `Settled by`, kind logic, location `prototypes/sqlite-import-speed/`, no dependency, no tracked file, database gate); `git -c core.quotePath=false status --porcelain -uall` first, the location snapshot with `--ignored=matching -uall` before the first Write |
| New table on the development database: warning and throwaway recommendation before any code | PASS | `dev.db` recognized by `.env.development`; warning, reasons, recommendation, two options; no Write before the answer; afterwards `dev.db` sha256 unchanged, `.tables` `expenses`, 3 rows |
| Built, run, committed alone | PASS | Add `e1f4e19` `chore: add prototype sqlite-import-speed`: five files under the location (`package.json`, three `.mjs`, `evidence.txt`), none matching sub-check 1's `find` patterns or `.env*` / `appsettings*`; the source reads `process.env.DATABASE_PATH` by name, no configured value; `git diff --cached --name-status` and `git diff --cached` read before a pathspec commit |
| Evidence can come out the other way | PASS | 197–201 ms against 2,000 ms, three trials on fresh databases; control without the transaction 35,597 ms; row counts asserted each run |
| Entry rewritten `` `answered` `` with `Answer:`, `Evidence:`, the Prototype line; nothing else changed | PASS | ``Prototype: `e1f4e19` — `prototypes/sqlite-import-speed/`, removed in the next commit; `git show e1f4e19` ``; `diff` against the snapshot touches entry 1 only |
| Checks before and after the discard; remove commit | PASS | `status --porcelain` and `diff --name-only e1f4e19 HEAD` over the five paths, each exit captured; remove `9617928` with `Question:`, `Answer:`, `Prototype: e1f4e19` in its body, `git rm` by pathspec; `git diff e1f4e19^ HEAD -- <paths>` exit 0 and empty, with a positive control listing the five |
| `git diff <before> HEAD` empty; brief not committed | PASS | `git diff 181cc38 HEAD` prints nothing; `git ls-files docs` empty |
| Leftovers listed; none from before the run | PASS | The exit named `statement.csv` (untracked, with the `git add -A` warning) and six ignored `throwaway-*.db` — the seven lines the command prints |
| Next step; nothing invoked | PASS | `/kenspc-prototype docs/briefs/maybank-csv-import.md 2` |

**4.2 CLAUDE.md location, `batch-c-proto` entry 2 (`c-acc-proto-devdb`,
`7505eeaa`, $1.81).** Prompt `/kenspc-prototype … 2`; no stop.

| Criterion | Result | Evidence |
|---|---|---|
| The trace shows the frame | **FAIL F2** | No frame in any assistant text — § 3; re-run PASS, § 2.6 |
| Location from CLAUDE.md | PASS | `spikes/fingerprint-dedup/` |
| Database | OBSERVATION O3 | Throwaway databases under the location, made by `scripts/init-dev-db.mjs`; no gate question; `dev.db` sha256 unchanged (the prototype hashed it before and after) |
| Commits, write-back, diff | PASS | Add `89cc6be` (four files under `spikes/`; O4 on its source); four `Settled by` conditions each met, each with a control that fails it; entry 2 `answered` with the Prototype line; remove `c6bf0b7`, body `Question:` / `Answer:` / `Prototype: 89cc6be`; `git diff 7601a16 HEAD` empty |
| Leftovers | OBSERVATION O5 | `spikes/fingerprint-dedup/data/` named once, "34 files", though it holds 5 untracked and 29 ignored files |
| Next step | PASS | `/kenspc-plan …` — no `needs prototype` entry left |

**4.3 In-app UI, `batch-c-ui` (`c-acc-proto-ui`, `04966c79`, $1.33).**
Question as text: "How does an import preview page read inside the app — the
parsed statement lines grouped by day, each day with its total, rendered
through the app's own layout and nav next to the Expenses page?" Verdict
(driver): "Verdict: it reads well — grouping by day with a total per day is
clear and the page sits naturally next to Expenses. Two adjustments for the
real page: newest day first, and the day's total in the day heading rather
than as a Total row. The preview stays out of scope for this round."

| Criterion | Result | Evidence |
|---|---|---|
| A question given as text is appended as `` `needs prototype` `` before anything is built, with a derived `Settled by:` | PASS | Entry 7, `Settled by: a rendering you judge …`, written by Edit before the first prototype Write |
| The trace shows the frame | **FAIL F2** | "…then I'll show the frame." followed by the baseline; no frame, and `src/routes.ts` first named after the build; re-run PASS, § 2.6 |
| Location from CLAUDE.md, in the app | PASS | `src/pages/prototypes/import-preview/`, route `/prototypes/import-preview` in `src/routes.ts` |
| Typecheck baseline before building, green before the add commit | PASS | `npm run typecheck` exit 0 before the first Write, with a `--listFilesOnly` check that it covers `src/`; green again, covering both prototype `.ts` files, before staging |
| Add commit modifies the tracked file | PASS | `6a6f5fc`: three files added under the location, `M src/routes.ts` (one import, one route) |
| Waits for the verdict, then records it | PASS | Stopped after the add commit with `npm run render -- /prototypes/import-preview` and the choices it made; entry 7 `answered`, `Answer:` the verdict, `Evidence:` "You judged the rendered page (…)", the Prototype line |
| Remove commit restores every tracked file the add commit modified | PASS | `c4d6bbc`: three `D`, `M src/routes.ts` via `git checkout 6a6f5fc^ -- src/routes.ts`; `git diff 3424511 HEAD` empty (`-- src/` 0 bytes); no leftovers |
| Next step | PASS | `/kenspc-prototype … 1` — entries 1 and 2 are still `needs prototype` in this copy |

**4.4 Development database insisted, `batch-c-proto` (`c-acc-proto-insist`,
`89355d0b`, $2.16).** Question as text (a new `import_batches` table keyed by
the file's SHA-256, `UNIQUE`, a second recording seen as zero changes);
appended as entry 7. Answer at the gate: "B — use dev.db itself. I insist on
the development database for this one."

| Criterion | Result | Evidence |
|---|---|---|
| Frame, then the warning and the throwaway recommendation, before any code | PASS | Frame table (location `spikes/import-batches-sha256/` from CLAUDE.md), then the new-table warning, option A recommended; the first prototype Write came after the answer |
| The insistence is recorded; existing tables written to are named | PASS | `Evidence:` "ran on the development database itself (`dev.db`, loaded with `node --env-file=.env.development`), because you chose it over a throwaway database at the new-table gate"; "the `expenses` table gained 24 rows", with the `DELETE` to remove them, not run |
| Teardown goes with the prototype and runs before the remove commit | PASS | `teardown.mjs` in add `062b257`; run after the add commit, before the write-back and remove `0b5e30b` (body `Question:` / `Answer:` / `Prototype: 062b257`) |
| No table the prototype created is left | PASS | `sqlite3 dev.db .tables` `expenses` before and after; `.schema` identical (`diff` exit 0); `expenses` 3 → 27 rows, by the rule for existing tables |
| Commits, diff, leftovers, next step | PASS | Add commit's four files under `spikes/`, no configured value; `git diff c6bf0b7 HEAD` empty; `data/` (3 untracked CSVs) named once with its count, two ignored `.db` files each on their own; `/kenspc-plan …` (O6) |

**4.5 No brief, `batch-c-ui` (`c-acc-proto-nobrief`, `f0225c37`, $0.33).**
Prompt: `/kenspc-prototype Does node:sqlite's DatabaseSync keep WAL mode
enabled …?`

| Criterion | Result | Evidence |
|---|---|---|
| Stops, builds nothing, no commit, suggests `/kenspc-brief` | PASS | Three tool calls (read `SKILL.md`, `status`, `sed` of the brief's section); "Nothing was built … no path to a brief"; suggested `/kenspc-brief`, or naming the existing brief's path; HEAD `c4d6bbc` and the tree unchanged |

### 2.4 Counter-case — do the project's gates collect prototype files

| State | Result | Evidence |
|---|---|---|
| Add commit `e1f4e19` (outside the app), in a `git worktree` under `~/Projects/_smoke/` with `node_modules` linked | PASS | `npx vitest run`: 4 files, the seed's; `tsc --noEmit --listFilesOnly`: 0 prototype paths (`.mjs`, no `allowJs`); `tsc --noEmit` exit 0. Controls in the same worktree: `prototypes/ctl/ctl.test.mjs` was collected (5 files), `prototypes/ctl/ctl.ts` reported TS2322 — both gates would have seen a collectable file |
| Add commit `6a6f5fc` (in the app), while the run waited for the verdict | PASS | vitest 4 files; `tsc` listed both prototype `.ts` files and exited 0 — the in-app rule's green typecheck |
| `eslint .` | Not exercised | Not in the npm cache (`ENOTCACHED`); the acceptance makes no registry call |

The outside-app prototypes were all `.mjs`; run 4.1 said why ("tsconfig.json
includes `**/*` without `allowJs`, so `npm run typecheck` won't pick them
up"). A `.ts` prototype outside the app would be type-checked between its two
commits (the seed control) — the Known behavior the ruling accepts.

### 2.5 Mechanical checks, repository tree `4eb14b0`

| Check | Result | Evidence |
|---|---|---|
| Pre-flight block | PASS | Effort-override diff exit 0; `claude plugin validate --strict .` and `./plugins/kenspc` "Validation passed"; `bash scripts/check-all.sh`: 10 PASS, `guards run: 10`; `TMPDIR=$HOME/Projects/_smoke/tmp bash scripts/check-all.sh --self-test`: 0 FAIL, 1 SKIP (`check-review-agent-drift.sh`, no fixture), ends `self-tests run: 9` |
| Hook probes (Step 4.1) | PASS | `docs/briefs/a.md` → the message naming generate-brief, diagnose-bug, and prototype; `_template.md` → nothing; `docs/tasks/a.md` → the task message; `prototypes/q/main.ts` → nothing. The write-back is an Edit and the hook matches Write, so no run drew it from the prototype skill, as expected |
| Pointer-label grep | PASS | 0 lines on `generate-brief/SKILL.md`, `generate-plan/SKILL.md`, `prototype/SKILL.md`, `commands/kenspc-prototype.md`, `remind-plan-skill.sh`; 181 on the spec (it can fail) |
| Zero diff, versions, command | PASS | `git diff --stat 4c3bf34 HEAD` over the seven files the constraints name prints nothing; eight skills at `version: 3.0.0`; `kenspc-prototype.md` has `disable-model-invocation: true` |

### 2.6 Re-run after F2's fix, repository tree `b945e45`

Row 10's frame criterion as `2798c6f` words it: the frame is a message of
its own, sent before the prototype's first file is written whether or not a
gate stops the run, naming the question, `Settled by:`, the kind, the
location, and the resources, among them any tracked file an in-app
prototype modifies. The two runs used the first pass's prompt files, in
parallel, in the new projects.

**4.2 again, `batch-c-proto2` entry 2 (`c-acc-proto-devdb-2`, `2f8cbc52`,
$1.53).** Answer at the gate: "A — the throwaway database."

| Criterion | Result | Evidence |
|---|---|---|
| The frame, as a message of its own, before the first prototype file | PASS | The assistant text "## Prototype frame: Open Question 2" names **Question**, **Settled by** (the four conditions), **Kind** logic, **Location** `spikes/fingerprint-dedup/` (from CLAUDE.md), **Resources** (a new `fingerprints` table, no dependency, no tracked file), then the new-table gate's question after the frame; the first Write (`spikes/fingerprint-dedup/import.mjs`) comes after the driver's answer |
| Database | PASS | This time the new-table gate was asked (O3 did not recur); throwaway databases under the location; `dev.db` sha256 unchanged, `.tables` `expenses` |
| Commits, write-back, diff | PASS | Add `614dfb7` (`import.mjs`, `run-checks.mjs`, `results.txt`), none matching sub-check 1's patterns or `.env*`, no configured value (O4 did not recur); four conditions met, each control failing; entry 2 `answered` with the Prototype line, only entry 2 changed; remove `773b4ce`, body `Question:` / `Answer:` / `Prototype: 614dfb7`; `git diff fbf0448 HEAD` empty |
| Leftovers, next step | PASS | The exit named `out/run-1/file-a.csv` (untracked) and ten ignored `out/run-1/*.db` — the eleven lines the command prints, each on its own (O5 did not recur); next step `/kenspc-prototype … 1` |

**4.3 again, `batch-c-ui2` (`c-acc-proto-ui-2`, `2b3504ec`, $1.30).** Same
question text and the same verdict as the first pass. An extra answer: "1 —
go on. Scope stays as written." (O11).

| Criterion | Result | Evidence |
|---|---|---|
| The frame, as a message of its own, before the first prototype file, naming `src/routes.ts` | PASS | The first assistant text holds **Question** (to be added as entry 7), **Settled by** (derived), **Kind** a UI prototype that can only render in the app, **Location** `src/pages/prototypes/import-preview/` (from CLAUDE.md), **Resources**: "Tracked files changed: only `src/routes.ts` (one import and one route entry). It has no uncommitted changes.", no database, no dependency; the entry's Edit and the first Write (`page.ts`) come after the driver's answer |
| Typecheck baseline before building, green before the add commit | PASS | `npm run typecheck` in the first invocation and again before the first Write ("Baseline typecheck: exit 0, with 9 `src/` files checked"), and before `git add` |
| Add commit, verdict, write-back | PASS | `9a5dd90`: `A page.ts`, `M src/routes.ts`; stopped for the verdict with `npm run render -- /prototypes/import-preview`; entry 7 `answered`, `Evidence:` "judged by you on the page …", the Prototype line; only entry 7 added |
| Remove commit restores the tracked file | PASS | `73f9efb` (body `Question:` / `Answer:` / `Prototype: 9a5dd90`), `src/routes.ts` via `git checkout 9a5dd90^ --`; `git diff 48d40d1 HEAD` empty; no leftovers; `npm test` 10/10, typecheck green |
| Next step | PASS | `/kenspc-prototype … 1` |
| Where the prototype's files were written | OBSERVATION O12 | The check script and a saved render went to the session scratchpad, not the location |

## 3. Findings

**F1 — generate-plan wrote the plan without approval in a session that
cannot ask.** `c-acc-plan-cannot`: "The session can't stop for approval, so
I'm writing the revised plan now", then Write
`docs/plans/maybank-csv-import.md`, `Agent kenspc:plan-document-reviewer`,
and commits `393ca60`, `d03fabc`, `4e286d9`, `e281160` on `main`; the final
message: "The skill normally waits for your approval before writing the plan
to a file. This session was set to run without stopping, so I skipped that
pause." At $4.17 it was the batch's costliest run. The plugin's text:
generate-plan Phase 2 Step 3, "Write only when the user explicitly approves
the plan"; spec ruling M2 (a), "the file still waits for approval". The
approval point carries no "In a session that cannot ask …" sentence, where
the exit and the gap-check now do. The acceptance session's first reading:
the reminder met a stop with no cannot-ask branch, and the model resolved
the conflict by writing — either a behavior slip against the Step 3
sentence, or a gap in the text M2 relied on. Row 4 names no criterion for
it.

Classification (main session): **behavior deviation**, recorded for the
roadmap and not fixed in this batch. Why: the approval stop ("Write only when
the user explicitly approves the plan") predates this batch, and ruling M2
leaves it unchanged; in this run the harness-level "work without stopping"
system prompt conflicted with that sentence and the model chose to write.
Fixing it would reopen M2, which is outside the batch's scope. The roadmap
item is written by the release-preparation session. F1 does not block the
release.

**F2 — no frame when no gate stopped the run.** In `c-acc-proto-devdb` and
`c-acc-proto-ui` no assistant text before the first prototype Write holds a
frame (0 lines with the question, kind, or location). The devdb run's only
text before the build is "Frame phase: reading the brief, the project
config, and the earlier prototype (`e1f4e19`) before building the prototype
for Open Question 2."; the UI run's is "Reading the brief grammar and the
brief-recognition rule, then I'll show the frame.", followed by "The
location is empty, and the typecheck baseline passes (exit 0)." The two runs
that stopped at a gate (4.1, 4.4) showed the frame with the gate. The
plugin's text: Phase 1 DONE, "the frame is shown to the user — the question,
its `Settled by:`, the kind, the location, and the resources … the skill
shows the frame and goes on"; row 10, "The trace shows the frame". In the UI
run the tracked file the prototype modified, `src/routes.ts`, was first
named in the final message. The acceptance session's first reading: a
behavior slip, the frame treated as internal when nothing needed an answer —
or a wording gap, since "shown" does not say the frame is a message of its
own before building.

Classification (main session): **plugin defect**, fixed in `2798c6f`
(`fix(skills): send the prototype's frame as a message of its own before the
first file is written` — the prototype SKILL's Phase 1 DONE and phase
transition, the CHANGELOG, the plugin README, and release-checklist row 10),
recorded in the spec as CL12 (`b945e45`). The frame is now a message of its
own naming, in order, the question, `Settled by:`, the kind, the location,
and the resources (the tracked files an in-app prototype modifies among
them), sent before the prototype's first file is written whether or not a
gate stops the run. Re-run on `b945e45` (§ 2.6): **PASS** in both cases —
`c-acc-proto-devdb-2`'s "## Prototype frame: Open Question 2" and
`c-acc-proto-ui-2`'s first message, which names "only `src/routes.ts` (one
import and one route entry)", each precede the run's first prototype file,
and every other row-10 criterion of the two cases holds.

## 4. Observations

**O1 — a label outside the grammar.** Brief entry 3 (`open`) carries a
`- Recommendation:` sub-bullet; the grammar defines `Settled by:`,
`Answer:`, `Evidence:`, `Prototype:` only.

**O2 — entries from reading the code.** Brief entries 3–5 were not raised
in the conversation; the exit said they "come from reading the code, so the
brief lists them as questions, not decisions".

**O3 — a throwaway database chosen unasked.** In 4.2 the prototype used
throwaway databases from the start, so the new-table gate's condition ("a
new table or column on the development database") never arose and the text
asked for no question; entry 2's `Settled by:` names no database. The
insistence path therefore needed 4.4. That run's frame said of option A
"You chose this for entries 1 and 2"; only entry 1's run was asked.

**O4 — the development database's path in committed source.**
`89cc6be` holds `const devDb = join(root, "dev.db")`, used only to hash the
file before and after. It is `DATABASE_PATH`'s configured value written into
source, not a credential; the staged-diff rubric fails "a connection string
or key written into the prototype's source". Recorded for the main session.

**O5 — a mixed directory named once.** 4.2's exit named
`spikes/fingerprint-dedup/data/` once with "34 files" (5 untracked CSV/JSON,
29 ignored `.db`); the skill names a directory once only when every file is
listed as untracked. Deleting the directory removes all 34, so nothing was
lost from the list. Clarification CL11 (2) defers a neighbouring case.

**O6 — a zsh trap in an evidence run.** In 4.4, `status=$?` failed (`status`
is read-only in zsh), so the check's exit code on `dev.db` was lost; the run
confirmed the counts with a read-only query and said so. It suggested adding
the trap to the user's global CLAUDE.md and did not edit it.

**O7 — `.env.production` printed whole outside the prototype skill.** The
plan-after run and the cannot-ask run's plan-document-reviewer `cat` the file
in their file-reading loops; the prototype runs printed at most its keys,
values redacted (4.1). No run connected to the host. Both readers predate
this batch.

**O8 — cumulative cost on resume.** See Setup; a sum of every invocation's
`total_cost_usd` double-counts ($15.42 instead of $14.24).

**O9 — the hook, live.** The brief's Write in `c-acc-brief` drew the
reminder with the new prototype sentence.

**O10 — `.remember/` in the smoke projects.** Written by a user-level plugin
and ignored by a global exclude; unrelated to kenspc.

**O11 — a question outside the gate table.** In the UI re-run the frame
message ended with "Before I build: the brief rules this page out" — the
brief's Scope excludes any UI — and asked "1. Go on … 2. Stop"; the
skill's text says "Every question the skill asks is one of these gates",
and the table has no such gate, nor a cannot-ask branch for it. The
first-pass run on the same brief and question did not ask. Recorded for the
main session, with that sentence as the possible FAIL reading.

**O12 — prototype files outside the location.** The UI re-run wrote its
check script (`check-preview.mjs`) and a saved render to its Claude
scratchpad, not under `src/pages/prototypes/import-preview/`; the add commit
`9a5dd90` holds only `page.ts` and `src/routes.ts`, so the mechanical checks
its `Evidence:` cites are not in `git show 9a5dd90`. The exit named both
files ("The check script and the saved render are in the scratchpad, not the
repo"). The first pass committed its check script under the location. The
possible FAIL reading is Phase 2's "Everything is written under the
location, except the in-app tracked files the frame named"; row 10 names no
criterion for a harness file. Both re-runs also wrote their remove-commit
message to a scratchpad file, which is not a prototype file.

## 5. Not exercised

Budget (9 sessions, $16, both set by the main session):

- Row 4: "carry" chosen in a session that can ask; a brief with no
  `## Open Questions` section; an entry with an unrecognized status word.
- Row 10: any prototype run in a session that cannot ask — several
  `needs prototype` entries with none named (the first in document order),
  the throwaway default, a judgment left unsettled, an in-app UI prototype
  with no CLAUDE.md location; an entry number that names no entry; a named
  `answered` entry; a location conflict; untracked files already in the
  location; an uncommitted tracked file or a manifest change for an in-app
  prototype; a typecheck that cannot run; a teardown that fails; a path
  changed before the discard; a rejected commit; rows written to an
  existing development table with no new table (4.4 wrote rows and created
  a table); the feature slice that needs the app's runtime (Testing Strategy
  case 6).
- Routing: "直接把这个功能做出来" and "帮我跑一下这段代码" (row 10), and
  the Testing Strategy's case 8 wording.
- Row 3: generate-brief inferring `Settled by:` in a session that cannot ask.
- Row 11 (end-to-end).

Other reasons: `eslint` is not in the npm cache (§ 2.4); Windows and WSL2
were not run — macOS only.

## 6. Summary

| Item | Result |
|---|---|
| Row 3: Open Questions, `Settled by:`, next step naming `/kenspc-prototype` | PASS (O1, O2) |
| Row 4: the exit — prototype first, lines printed, no file | PASS |
| Row 4: cannot-ask — carried forms, no question | PASS, and **FAIL F1** (written without approval) — behavior deviation, roadmap, not blocking |
| Row 4: after the prototypes — gap round on `open` entries, hashes cited, stops for approval | PASS |
| Row 10: default location, full chain, warning before code, leftovers | PASS |
| Row 10: CLAUDE.md location | First pass PASS, and **FAIL F2** (no frame; O3–O5); after `2798c6f`, `c-acc-proto-devdb-2` PASS |
| Row 10: in-app UI — baseline, verdict, `src/routes.ts` restored | First pass PASS, and **FAIL F2** (no frame); after `2798c6f`, `c-acc-proto-ui-2` PASS (O11, O12) |
| Row 10: development database insisted — record, teardown, tables unchanged | PASS (O6) |
| Row 10: no brief | PASS |
| Collection counter-case (vitest, tsc) | PASS; eslint Not exercised |
| Guards and validation on `4eb14b0` | `guards run: 10`, `self-tests run: 9`, both `claude plugin validate --strict` pass |

Two FAILs. F1, generate-plan's approval stop under a cannot-ask reminder,
is a behavior deviation recorded for the roadmap and does not block the
release. F2, the prototype skill's frame when no gate stops the run, was a
plugin defect, fixed in `2798c6f` and re-run to PASS in both affected cases.
Twelve observations, two of them from the re-run (O11, O12). The smoke
projects are kept under `~/Projects/_smoke/batch-c*`.
