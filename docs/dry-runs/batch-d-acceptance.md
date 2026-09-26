# Batch D acceptance — unattended stops, answered-entry checks, and three copy guards (3.8.1, unreleased)

Acceptance record for batch D (spec: `docs/plans/batch-d-unattended-guards.md`):
release-checklist smoke rows 4, 9, and 10 for the cases the batch adds, the
spec's Testing Strategy cases 1–9 as the clarifications CL1, CL4, CL5, and
CL8 amend them, and the pre-flight block. One machine, macOS, 2026-09-26,
12:33–12:54, and two re-runs of three cases at 13:06–13:08 and
13:13–13:15. The acceptance session recorded the evidence and a first
reading of each FAIL; the main session classified them, as the batch C
record's § 3 does (§ 3). Two fixes were made after the first pass, in the
main session and never in a run's project: `d02a64f` (spec clarification
CL9, `52ccc53`), after which the three cases it affects were re-run in new
projects and still failed (§ 2.6); then `e470453` (CL10, `ff505c6`,
amending CL9), after which the same three cases were re-run again in new
projects and passed (§ 2.7).

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — the run gave
the criterion nothing to check.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `c19d60f` (plugin files last changed in `cb8c414`, skill files in `a193249`) for the first pass; `52ccc53` (F1's first fix `d02a64f`, then CL9) for the first re-run; `ff505c6` (F1's second fix `e470453`, then CL10) for the second re-run; loaded with `--plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc`; the tree was not changed during any pass (this record is the only new file) |
| Claude Code | 2.1.282 |
| Mode | Headless, one process per invocation through `~/Projects/_smoke/_prompts/d-run-acc.sh` (`claude -p "<prompt>" --plugin-dir … --permission-mode bypassPermissions --output-format json`, cwd the smoke project); a run that stopped at a question was continued with `claude -p --resume <session_id> "<answer>"` from the same directory with the same flags. Four sessions were made sessions that cannot ask, with `--append-system-prompt "Work without stopping; do not ask clarifying questions."`, passed again on the one resume among them: `d-acc-plan-cannot` (and its resume `d-acc-plan-cannot-r1`), `d-acc-proto-word-c`, `d-acc-proto-unrec-c`, `d-acc-proto-noentry-c`; and the six re-run sessions, `d-acc-proto-word-c-2`, `d-acc-proto-unrec-c-2`, `d-acc-proto-noentry-c-2`, `d-acc-proto-word-c-3`, `d-acc-proto-unrec-c-3`, `d-acc-proto-noentry-c-3` |
| Session model | Opus 5.5 (`claude-opus-5-5`, the only key in `modelUsage` of all 21 invocations' JSON) |
| Installed copy | `kenspc@kenspc-claude-plugin` is enabled; its cache holds 3.8.0. The commands load their skill by reading its `SKILL.md`, so the source gate is the path read: in all eight sessions the first `SKILL.md` read is under `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/`, and `plugins/cache/kenspc-claude-plugin` occurs 0 times in the 16 files under the eight projects' trace directories (the eight session transcripts, the reviewer subagent's transcript and meta file, six tool-result files, and one hook-spawned session's transcript, O7), and 0 times in each re-run's six (three session transcripts, three tool-result files) |
| Seed project | `~/Projects/_smoke/batch-d-seed`: an APFS clone (`cp -Rc`) of the batch C seed `batch-c-seed` at `181cc38`, the batch C record's Seed project row unchanged (TypeScript 7.0.2, vitest 5.0.1 from the local npm cache, Node 24.19.0; 4 test files, 10 tests green; `npm run typecheck` exit 0; no `CLAUDE.md`), plus six driver commits: `ab5b549` / `e65d0d9` (add / remove `prototypes/maybank-bom/`), `c5352f9` / `5fd7aa2` (`prototypes/debit-credit-sign/`), `2b9fda6` / `a05bdd6` (`prototypes/quoted-fields/`), so that every Prototype line in the briefs resolves with `git show`. The seed carries a bug its tests do not catch: `parseStatementLine("2026-13-01,Kopi,4.50")` and `("2026-02-30,…")` return the impossible date as `bookedOn` (checked with `node -e` before any run) |
| Brief | `docs/briefs/maybank-csv-import.md`, hand-written, untracked, sha256 `c23951e6…f398e`, six `## Open Questions` entries: 1 `` `needs prototype` `` with `Settled by:`; 2 `` `open` ``; 3 `` `answered` `` with `Settled by:`, `Evidence:`, and a Prototype line naming `ab5b549`, no `Answer:`; 4 `` `需要原型` ``, no `Settled by:` (CL8); 5 `` `open` `` with `Answer:`, `Evidence:`, and a Prototype line naming `c5352f9`, no `Settled by:`; 6 `` `pending` `` with `Evidence:` and a Prototype line naming `2b9fda6`, no `Answer:`, no `Settled by:` (CL5 (b)) |
| Second brief (CL1) | `docs/briefs/quoted-descriptions.md` in `batch-d-noentry` only, untracked, sha256 `669d8c59…23ea`: entry 1 `` `needs prototype` `` holding `Settled by:`, `Answer:`, `Evidence:`, and a Prototype line naming `2b9fda6` — the brief's only `needs prototype` entry; entry 2 `` `open` `` |
| sha256 positive controls | One per brief, on a copy under `$TMPDIR`: a one-character edit of line 1 (`Maybank` → `maybank`; `Quoted` → `quoted`, same length) changes the hash (`c23951e6…` → `2c061f53…`; `669d8c59…` → `e7bcd054…`), and `cmp` names the first differing byte. The brief-unchanged criteria below are the brief's `shasum -a 256` before and after the run, never `git diff` (ruling M12) |
| Projects | One clone of the seed per session, each with HEAD `a05bdd6` and only its brief untracked before its first run: `batch-d-plan`, `batch-d-gap`, `batch-d-word-i`, `batch-d-word-c`, `batch-d-ans`, `batch-d-unrec-c` (the maybank brief); `batch-d-noentry` (the CL1 brief only); `batch-d-diag` (no brief). The driver's one commit in a project after a run started is `a4c2927` in `batch-d-plan` (§ 2.1, CL4). For the re-run, three new clones of the seed: `batch-d-word-c-2` and `batch-d-unrec-c-2` (the maybank brief, sha256 `c23951e6…`), `batch-d-noentry-2` (the CL1 brief only, copied from `batch-d-noentry`, sha256 `669d8c59…`); for the second re-run, three more: `batch-d-word-c-3`, `batch-d-unrec-c-3`, `batch-d-noentry-3`, set up the same way; no earlier project was touched |
| Traces | `~/.claude/projects/-Users-kenspc-Projects--smoke-<project>/<session_id>.jsonl`, subagents under `<session_id>/subagents/`; results in `~/Projects/_smoke/_logs/d-acc-<tag>.json`, timeline in `d-timeline.log`, per-session costs in `d-acc-costs.txt` |
| Cost | 14 sessions, $13.97: the first pass 8 sessions, $10.89; the first re-run 3 sessions, $1.61; the second re-run 3 sessions, $1.47 (budget 14 sessions, $3 for each re-run, and $30 for the whole acceptance); driver session cost recorded by the main session. Each session's cost is in its heading: its last `total_cost_usd`, which on a resumed session is the running total — `d-acc-plan-cannot` reports $2.00 after its first invocation and $4.75 after the approval |

**Independence.** The acceptance driver — a headless session opened by the
main session — built the seed and both briefs, made the six prototype
commits and the one plans commit, wrote the prompts, typed every answer, and
wrote this record; it took no part in the batch's design rulings. What the
plugin's own runs produced — drafts, plans, commits, the task document,
trace — is independent of that. What the driver typed is not, and each
answer is quoted where it was given.

## 2. Cases

### 2.1 Row 4 — cannot-ask stop at the approval point, then the approval (`batch-d-plan`, `f0a207d3`, $4.75)

**Case 1, `d-acc-plan-cannot`** (reminder). Prompt:
`/kenspc-plan docs/briefs/maybank-csv-import.md`. One invocation, no
question, 553 s, $2.00.

| Criterion | Result | Evidence |
|---|---|---|
| No question; the run ends at the draft | PASS | One invocation; `result` is the draft and the note, no question |
| The last message holds the complete draft, `## Documentation impact` included | PASS | `result` holds `# Plan: Maybank CSV statement import` with Objective, Background / Context, Technical Approach, Data Model, Implementation Steps (Steps 1–6), Testing Strategy, `## Documentation impact` (two README items, `CLAUDE.md` N/A), Risks and Mitigations, Open Questions; above it, what the self-challenge changed (five items) |
| `Plan not written: awaiting approval.` and how to go on | PASS | The line, exact, after the draft; then "Approve or ask for changes in this session. For a headless run, use `claude -p --resume f0a207d3-… "<reply>"`", and re-running `/kenspc-plan` in a session that can ask |
| No Write, Edit, or Agent call; HEAD and `git status --porcelain -uall` unchanged | PASS | 14 tool calls, all `Bash`; HEAD `a05bdd6`, status `?? docs/briefs/maybank-csv-import.md` only, `docs/plans/` absent; brief sha256 unchanged (O2 on a scratchpad probe) |
| Entry 1 carried with `Not prototyped: the session could not ask` | PASS | `1. `needs prototype` — …`, `From: docs/briefs/maybank-csv-import.md, entry 1`, `Not prototyped: the session could not ask`, `Assumed in:` |
| Entry 2 with `From:` and `Assumed in:` | PASS | Entry 2 `open`, both labels, no `Not prototyped:` |
| Entry 3 (`answered`, no `Answer:`) in the `open` form, `status word answered, Answer: missing` | PASS | `3. `open` — Does the Maybank export start with a UTF-8 byte order mark …`, `From: docs/briefs/maybank-csv-import.md, entry 3, status word answered, Answer: missing`; "No step relies on the entry's Evidence … as settled" |
| Entry 4 with `status word 需要原型 not recognized` | PASS | `From: docs/briefs/maybank-csv-import.md, entry 4, status word 需要原型 not recognized` |
| Entry 5 in the `open` form | PASS | `5. `open` — …`, `From: …, entry 5`, `Assumed in:` naming the recorded answer as assumed, not settled |
| Entry 6 | PASS | `From: …, entry 6, status word pending not recognized` |

**Case 2 and CL4 / CL8, `d-acc-plan-cannot-r1`** (reminder passed again).
Before the resume the driver committed two files at the target path the
draft named, `docs/plans/maybank-csv-import.md` (sha256 `54c81e3c…2019`) and
`docs/plans/maybank-csv-import-2.md` (`b2735711…64ef`), as `a4c2927`
`docs: add earlier plans`. Driver's answer: "approved". 612 s; session total
$4.75.

| Criterion | Result | Evidence |
|---|---|---|
| The approval continues the run: plan written, reviewer dispatched, commits | PASS | `Write docs/plans/maybank-csv-import-3.md`, then `Agent kenspc:plan-document-reviewer` (subagent meta: `agentType` `kenspc:plan-document-reviewer`, `requestShape` foreground); commits `b06cca4` `docs: add plan maybank-csv-import-3` (the unedited plan) and `43327c5`, `f6e53a8`, `4ac4841`, `fb12992`, one per angle |
| Schema E table follows | PASS | Four rows, each `FIXED (n)` with its commit |
| With `<name>.md` and `<name>-2.md` in place, the plan goes to `<name>-3.md`; both existing files' sha256 unchanged; the final message names it | PASS | `git diff --stat a4c2927 HEAD`: `docs/plans/maybank-csv-import-3.md` only; both sha256 identical to the values taken before the resume; "I wrote the plan to `docs/plans/maybank-csv-import-3.md` … `maybank-csv-import.md` and `maybank-csv-import-2.md` already existed (plans you kept earlier), so I used the first free number" |
| The plan written is the printed draft | PASS (O3) | `git show b06cca4:…-3.md` against the draft in case 1's `result`: 355 lines each, 7 lines differ |
| The run did not stop again under the reminder | PASS | The resumed invocation wrote, reviewed, and committed; the brief stayed untracked and unchanged |

### 2.2 Row 4 — interactive gap round (`batch-d-gap`, `d-acc-plan-gap`, `4929d32a`, $2.14)

Prompt: `/kenspc-plan docs/briefs/maybank-csv-import.md`, no reminder.

| Invocation | Driver's answer | What the run did |
|---|---|---|
| 1 | — | The exit question on entry 1 only: "Do you want to prototype it first or carry it into the plan?", before any gap question; the entries 3–6 anomalies named in an aside as coming "in the gap round after this question" |
| 2 (`-r1`) | "Carry it into the plan." | The gap round: entries 2–6 and three gaps from the code (G1–G3), one round |
| 3 (`-r2`) | "Entry 2: carry it as open. Entry 3: the answer is: yes — the export starts with EF BB BF; the importer strips one leading BOM before splitting lines. Entry 4: answered. Entry 5: (a), keep the answer as written. Entry 6: needs prototype, carried. G1: (a). G2: I don't have the header to hand; assume Date,Description,Debit,Credit and list it as an open question. G3: hard-code maybank-01. Draft the plan; I'll review it before you write it." | The draft, stopped for approval |

| Criterion | Result | Evidence |
|---|---|---|
| The gap round quotes the `answered` entry with no `Answer:` and asks for its answer | PASS | "**Entry 3** `answered`, but it has **no `Answer:` line**, only Settled by, Evidence and Prototype `ab5b549`. What is the answer?", with a suggested wording |
| The gap round asks the unrecognized entries' status | PASS | Entry 4: "the status word **`需要原型`**, which the skill doesn't recognise … Which status should it have?"; entry 6 the same for `pending` |
| The status question also asks, for `answered`, the answer | **FAIL F2** | Neither status question asked for an answer — § 3 |
| CL8: a reply of `answered` with no answer text is not taken as settled | PASS | Draft Open Question 3: `From: docs/briefs/maybank-csv-import.md, entry 4, status word answered, Answer: missing`, `Assumed in: Steps 4 and 6 — assume yes`; the message before the draft: "The skill treats an `answered` entry with no answer as still open. So it's carried as Open Question 3 in the `open` form, marked `Answer: missing`" |
| An answer given in the gap round is settled input | PASS | Entries 3 and 5 are not in the draft's Open Questions |
| Entry 1 carried; entry 6, marked `needs prototype` and carried there, takes that form | PASS | Entries 1 and 4 of the draft: `needs prototype`, `Not prototyped: the user chose to carry it`, `From: …, entry 1` / `entry 6` |
| Stops at the approval point, nothing written | PASS | "Reply "write it" to save it as is"; HEAD `a05bdd6`, status the brief only, brief sha256 unchanged; the session's tool calls are 15 `Bash` and 3 `Write`, all three Writes under the session scratchpad (O2); no Agent call |

### 2.3 Row 10 — the prototype skill's gates

Every run in this section was one session in its own project; before each,
HEAD `a05bdd6` and only the brief untracked.

**Case 4, `需要原型`, interactive (`batch-d-word-i`, `d-acc-proto-word-i`,
`cd7d6aa1`, $0.69).** Prompt
`/kenspc-prototype docs/briefs/maybank-csv-import.md 4`. Driver's answer at
the gate: "Stop."

| Criterion | Result | Evidence |
|---|---|---|
| Before any Write or Edit, the run asks prototype-or-stop, quoting the word | PASS | One message: "## Frame: entry 4" (question; `Settled by:` "The entry doesn't have one, so I derived this. It isn't in the brief yet."; kind; location `prototypes/fingerprint-dedup/`; resources), then "**Gate: unrecognized status word.** Entry 4 starts with `` `需要原型` `` … **Should I prototype it, or stop?**"; the session's tool calls are 9 `Bash` and 7 `Read`, no Write or Edit |
| On "stop": no commit, brief sha256 unchanged; the gate came before the derived `Settled by:` | PASS | HEAD `a05bdd6`; sha256 `c23951e6…` before and after; entry 4 has no `Settled by:` (it held none) — "The `Settled by:` I derived was only in the frame message" |

**Case 5, `需要原型`, cannot-ask (`batch-d-word-c`, `d-acc-proto-word-c`,
`e88ec0e9`, $0.53).** Same prompt, with the reminder.

| Criterion | Result | Evidence |
|---|---|---|
| No question; stops; no commit; nothing written; sha256 unchanged | PASS | One invocation; 6 `Bash`, 1 `Read`; HEAD `a05bdd6`; sha256 unchanged |
| The last message names the entry and quotes the word found | PASS | "I didn't build anything for entry 4. Its status word is `需要原型`, and the skill only recognizes `open`, `needs prototype` and `answered`" |
| The frame as a message of its own | **FAIL F1** | The one text block is the final message — § 3 |

**Case 6, `open` with `Answer:` and a Prototype line, interactive
(`batch-d-ans`, `d-acc-proto-ans`, `338ddd80`, $0.77).** Prompt
`/kenspc-prototype docs/briefs/maybank-csv-import.md 5`. Driver's answer:
"No, don't prototype it again."

| Criterion | Result | Evidence |
|---|---|---|
| The prototype-again question, before any write | PASS | "## Frame: entry 5 …" (the `Settled by:` derived, "It isn't written into the brief yet"), then "## Gate: prototype it again? Entry 5 already has an `Answer:`, `Evidence:` and `Prototype: c5352f9`, even though its status word is `open`"; 10 `Bash`, 1 `Read` in the session |
| On "no": no commit, sha256 unchanged, and — the entry holding no `Settled by:` — the gate came before the derived write | PASS | HEAD `a05bdd6`; sha256 unchanged; "entry 5 is exactly as it was … I didn't write the derived `Settled by:`" |

**CL5 (b), unrecognized word holding `Prototype:` and no `Answer:`,
cannot-ask (`batch-d-unrec-c`, `d-acc-proto-unrec-c`, `2c0805de`, $0.53).**
Prompt `/kenspc-prototype docs/briefs/maybank-csv-import.md 6`, with the
reminder.

| Criterion | Result | Evidence |
|---|---|---|
| Stops at the prototype-again gate; no commit; sha256 unchanged | PASS | "entry 6's status word is `` `pending` ``, which the skill doesn't recognize. The entry also holds `Prototype: 2b9fda6` … the skill must first ask whether to prototype it again. With no way to ask, it stops and leaves the entry alone. The same gate also kept out the `Settled by:` I drafted in the frame"; 6 `Bash`, 1 `Read`; HEAD `a05bdd6`; sha256 unchanged |
| The last message names the entry and quotes the word | PASS | As quoted |
| The frame as a message of its own | **FAIL F1** | One text block, the final message — § 3 |

**CL1, no ENTRY, the only `needs prototype` entry holds `Answer:`,
cannot-ask (`batch-d-noentry`, `d-acc-proto-noentry-c`, `ed9783f4`,
$0.51).** Prompt `/kenspc-prototype docs/briefs/quoted-descriptions.md`,
with the reminder.

| Criterion | Result | Evidence |
|---|---|---|
| The entry taken with no ENTRY gets the prototype-again gate; stops; no commit; sha256 unchanged | PASS | "with no entry number given, the run took entry 1, the brief's only `needs prototype` entry. That entry already records an answer … This session couldn't ask, so the skill stopped instead of asking whether to prototype it again"; 6 `Bash`, 1 `Read`; HEAD `a05bdd6`; sha256 `669d8c59…` unchanged |
| The frame as a message of its own | **FAIL F1** | One text block, the final message — § 3 |

### 2.4 Row 9 — `/kenspc-diagnose`, interactive exit (`batch-d-diag`, `d-acc-diag`, `6581d8fd`, $0.96)

Prompt: `/kenspc-diagnose parseStatementLine accepts impossible dates.
"2026-13-01,Kopi,4.50" and "2026-02-30,Kopi,4.50" both parse without an
error and come back with bookedOn "2026-13-01" and "2026-02-30", but a line
with a date that does not exist should be rejected with "Invalid date", the
way "01/09/2026,Kopi,4.50" is.` Answers: at the task-list confirmation,
"Write it as listed."; at the exit, "I'll implement it interactively
myself."

| Criterion | Result | Evidence |
|---|---|---|
| Reproduction test written, run, failing, committed before the task document | PASS | `Write test/csv-impossible-date.test.ts`; three `npx vitest run` of it, each "expected [Function] to throw an error"; `3f57502` `test: reproduce parseStatementLine accepting impossible dates` (1 file); then `Write` / `Edit` of the task document |
| Task document committed, nine labels in order, tasks | PASS | `515de70` `docs: add task statement-line-impossible-dates`; `**Symptom:**` … `**Probes:**` in order; `### Task 1` `**Status:** TODO`; `### Task 2: Regression tests …` with `Depends on: Task 1`; no Doc-sync (Documentation impact none); the Phase/Step heading grep prints nothing (exit 1) |
| On "interactively", after a `test: reproduce` commit: the last message names that commit and gives `git revert <hash>`; no revert | PASS | "commit `3f57502` added `test/csv-impossible-date.test.ts`, and that test fails until the fix lands. Until then, `npm test` fails, and any review run in this repository will report the test run as FAIL. If you decide not to make the fix, you can remove the test with: `git revert 3f57502` … I won't revert it unless you ask." HEAD `515de70`, the task-document commit; `npx vitest run` afterwards: 2 failed (the reproduction), 10 passed |

### 2.5 Mechanical checks, repository tree `c19d60f`

| Check | Result | Evidence |
|---|---|---|
| Pre-flight block | PASS | Effort-override diff exit 0 (the three `xhigh` files); `claude plugin validate --strict .` and `./plugins/kenspc` "Validation passed" (exit 0 each); `bash scripts/check-all.sh`: 10 PASS, `guards run: 10`; `TMPDIR=$HOME/Projects/_smoke/tmp bash scripts/check-all.sh --self-test`: exit 0, 0 FAIL, 1 SKIP (`check-review-agent-drift.sh`, no fixture), ends `self-tests run: 9` |
| D-4 (a), by hand, on a clone under `$TMPDIR/d-acc-guards/repo` | PASS | `plugins/kenspc/README.md` "on the working tree" → "on the working copy": `check-run-contract.sh` exit 1, "DRIFT reviewer invariant sentence — …/plugins/kenspc/README.md does not contain it"; restored, exit 0. `CLAUDE.md`'s indented copy "its report at" → "its reports at": exit 1 naming `…/CLAUDE.md`; restored, exit 0. A whitespace-only re-wrap of the README copy (a line break and indent inserted mid-sentence): exit 0 |
| D-4 (b), same clone | PASS | `prototype/SKILL.md`'s Prototype line "removed in the next commit" → "removed in the following commit": `check-doc-sync-anchors.sh` exit 1, "MISSING label 'Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>`' in …/prototype/SKILL.md"; restored, exit 0 |
| D-4 (c), same clone | PASS | The first of the two leftovers-command literals edited (`-uall` → `-unormal`), the second left: exit 1, "COUNT leftovers command — 1 occurrence(s) in …/prototype/SKILL.md, expected 2"; restored, exit 0. A third copy appended: exit 1, "3 occurrence(s) … expected 2"; restored, exit 0. The clone is left under `$TMPDIR` |
| Pointer-label grep (Standing constraints) | PASS | 0 lines on `generate-plan/SKILL.md`, `prototype/SKILL.md`, `diagnose-bug/SKILL.md`; 166 on the spec (it can fail) |
| Zero diff, versions | PASS | `git diff --stat 0128a2f HEAD -- <the nine paths>` prints nothing; `diagnose-bug/SKILL.md`'s one hunk is at line 452 (`@@ -452 +452,7 @@`), between `## Exit` (443) and `## Writing rules for the document` (486); eight skills at `version: 3.0.0`; `plugin.json` still `3.8.0` (bumped in the release commit); `check-no-model-names.sh` exit 0 |
| Case 9, text | PASS | `grep -n 'no notion of a failure that predates the run' plugins/kenspc/README.md`: one line (361); `` grep -n 'Uncommitted `.gitignore` edits' ``: one line (340); the `## 3.8.1 — unreleased` entry's `### Known behavior` holds "**Red interval and review runs.**" (with "has no notion of a failure that predates the run") and "**Uncommitted `.gitignore` edits.**" |

### 2.6 First re-run after F1's first fix, repository tree `52ccc53`

Row 10's frame criterion as `d02a64f` words it: the frame is a message of
its own, sent before the prototype's first file is written whether or not a
gate stops the run — including when a session that cannot ask stops at a
gate on the entry it takes, named or taken with none named, where the frame
is a message before the last one and the last message does not refer to a
frame the trace lacks. The prototype SKILL's Phase 1 DONE when gains the
paragraph "In a session that cannot ask …, a gate on the entry the run takes
… stops the run in place of asking, and the frame still goes first, as a
message of its own; the stop follows it as the last message"; both entry
gates' cannot-ask branches say "stop after the frame", and their
gates-table cells "Stop after the frame; the entry unchanged". The three
runs used the first pass's prompt files and the same reminder, in parallel,
in the new projects. Each read the fixed text: the new DONE-when paragraph
("the run in place of asking") is in each session's `SKILL.md` read, and
"Stop after the frame" occurs 4 times in each trace.

| Run | Criterion | Result | Evidence |
|---|---|---|---|
| `d-acc-proto-word-c-2`, `batch-d-word-c-2`, entry 4 `需要原型` (`b72e0192`, $0.51) | No write, no commit, sha256 unchanged; the last message names the entry and quotes the word | PASS | 7 `Bash`, 1 `Read`; HEAD `a05bdd6`, status the brief only; sha256 `c23951e6…` before and after; "I stopped at entry 4 without building anything, because its status word is `需要原型`" |
| same | The frame as a message before the last one; the last message refers to no frame the trace lacks | **FAIL** | The session's assistant content is 6 `thinking` blocks (text redacted, signature only), 8 tool calls, and 1 `text` block — the final message. That message says "the derived `Settled by:` appears only in the frame above" and, in its insight block, "The frame came as its own message before any file would be written"; no earlier text block exists |
| `d-acc-proto-unrec-c-2`, `batch-d-unrec-c-2`, entry 6 `pending` + `Prototype:` (`ae0478e0`, $0.56) | No write, no commit, sha256 unchanged; the last message names the entry, the word, and the gate | PASS | 8 `Bash`, 1 `Read`; HEAD `a05bdd6`; sha256 unchanged; "entry 6's status word is `pending` … The entry also already records an earlier attempt (`Prototype: 2b9fda6`). In that case the skill has to ask you whether to prototype it again, and this session couldn't ask, so it stops" |
| same | The frame as a message before the last one; no reference to a frame the trace lacks | **FAIL** | Two text blocks: "Reading the brief's entry grammar and the earlier prototype for entry 6 so I can frame the run." (a progress line, no question, `Settled by:`, kind, location, or resources), then the final message, which says "The derived "Settled by" line above was not written into the brief" — no text block holds that line |
| `d-acc-proto-noentry-c-2`, `batch-d-noentry-2`, no ENTRY (`6f12d73a`, $0.55) | No write, no commit, sha256 unchanged; the last message names the entry | PASS | 9 `Bash`, 1 `Read`; HEAD `a05bdd6`; sha256 `669d8c59…` unchanged; "**Entry:** 1, with status word `` `needs prototype` ``" and why it stopped |
| same | The frame as a message before the last one; no reference to a frame the trace lacks | **FAIL** | One text block, the final message: "the run stopped at the frame" |

### 2.7 Second re-run after F1's second fix, repository tree `ff505c6`

Row 10's frame criterion as `e470453` words it: when a session that cannot
ask stops at a gate on the entry it takes, named or taken with none named,
the frame's message is the last one — it opens with the frame, the five
items in order (the question, `Settled by:`, the kind, the location, the
resources), then names the entry and the status word found, or says there
is none, and why the run stopped. The prototype SKILL's Phase 1 DONE when
now reads "the frame's message is the last message: it opens with the
frame, in the order above, then names the entry and the status word found,
or says there is none, and says why the run stopped"; the entry gates'
cannot-ask branches and gates-table cells say "the frame at the head of the
last message". The three runs used the first pass's prompt files and the
same reminder, in parallel, in new projects; each read the fixed text ("the
frame's message is the last message" is in each session's `SKILL.md` read).

| Run | Criterion | Result | Evidence |
|---|---|---|---|
| `d-acc-proto-word-c-3`, `batch-d-word-c-3`, entry 4 `需要原型` (`9316280f`, $0.51) | The last message opens with the frame, five items in order | PASS | `result` opens "**Frame: entry 4 of `docs/briefs/maybank-csv-import.md`**", then **Question**, **Settled by** ("derived, since the entry has none. Shown here only and **not written** to the brief"), **Kind** logic, **Location** `prototypes/fingerprint-dedup/`, **Resources** (a throwaway SQLite file, no dependency, no tracked file modified) |
| same | Then the entry, the word, and why it stopped; no reference to anything unseen | PASS | "**Why I stopped:** Entry 4's status word is `` `需要原型` `` … For an unrecognized word, the skill has to ask you whether to prototype the entry or stop. This session is set to work without asking, so the run stopped there."; "the `Settled by:` above" points at the frame in the same message. The one earlier text block is a progress line ("Checking entry 4 against the skill's gates …") |
| same | No write, no commit, sha256 unchanged | PASS | 5 `Bash`, 1 `Read`; HEAD `a05bdd6`, status the brief only; sha256 `c23951e6…` before and after |
| `d-acc-proto-unrec-c-3`, `batch-d-unrec-c-3`, entry 6 `pending` + `Prototype:` (`c7d85dfb`, $0.51) | The last message opens with the frame, five items in order | PASS | "**Frame: entry 6 of `docs/briefs/maybank-csv-import.md`**", then **Question**, **Settled by** ("I derived this because the entry has none; it is not written to the brief"), **Kind** logic, **Location** `prototypes/quoted-fields/`, **Resources** (no database, no dependency, no tracked file; a real export needed) |
| same | Then the entry, the word, the gate, and why it stopped; nothing unseen referred to | PASS | "**The run stopped here.** Entry 6's status word is `pending` … The entry also has a `Prototype:` line (`2b9fda6`), so the skill has to ask **"prototype it again?"** … This session can't ask questions, so the run stopped at that check." One earlier progress line ("… so I'm looking at the earlier attempt's commits to fill in the frame.") |
| same | No write, no commit, sha256 unchanged | PASS | 8 `Bash`, 1 `Read`; HEAD `a05bdd6`; sha256 unchanged |
| `d-acc-proto-noentry-c-3`, `batch-d-noentry-3`, no ENTRY (`92ed073b`, $0.45) | The last message opens with the frame, five items in order | PASS | The session's only text block: "**Frame**", then **Question** ("entry 1: …"), **Settled by** ("This line was already in the entry, so I didn't write one."), **Kind** logic, **Location** `prototypes/quoted-fields/`, **Resources** none |
| same | Then the entry, the word, and why it stopped; nothing unseen referred to | PASS | "**I stopped at the "prototype it again?" check.** You didn't give an entry number, so the run took entry 1, the only `needs prototype` entry in the brief. Its status word is `` `needs prototype` ``, but it already has `Answer:`, `Evidence:` and a `Prototype:` line … This session was told to work without stopping, so I couldn't ask." |
| same | No write, no commit, sha256 unchanged | PASS | 5 `Bash`, 1 `Read`; HEAD `a05bdd6`; sha256 `669d8c59…` unchanged |

## 3. Findings

**F1 — no frame message when a session that cannot ask stops at an entry
gate.** In `d-acc-proto-word-c`, `d-acc-proto-unrec-c`, and
`d-acc-proto-noentry-c` the only assistant text is the final message; no
message before it names the question, `Settled by:`, the kind, the
location, and the resources. Each final message refers to a frame the user
never saw: "the `Settled by:` I worked out in the frame was not written in"
and "The throwaway database in the frame was never used" (word-c); "The
same gate also kept out the `Settled by:` I drafted in the frame" (unrec-c);
"What I found while framing" (noentry-c). The interactive runs at the same
gates sent the frame, with the gate's question after it, in one message
(cases 4 and 6). The plugin's text: row 10, "The trace shows the frame as a
message of its own, sent before the prototype's first file is written
whether or not a gate stops the run"; Phase 1 DONE, "It is sent whether or
not a gate stops the run: a gate that asks once the question is chosen puts
its question in the same message, after the frame." Against that: the entry
gates sit in § The question, where the question is still being chosen, and
their cannot-ask branch says only "stop and leave the entry unchanged … the
last message names the entry and quotes the word found"; row 10's stop
criteria ask for the reason in the last message, which all three gave, and
none of them wrote a file. The acceptance session's first reading: a wording
gap more than a behavior slip — whether "whether or not a gate stops the
run" reaches a gate that stops before the question is settled, and a stop
that asks nothing, is not said; the outcome the gate protects (no write, no
commit, the brief's sha256 unchanged) held in all three.

Classification (main session): **plugin defect**, first fixed in `d02a64f`
(`fix(skills): send the prototype skill's frame before an entry gate stops
an unattended run` — the prototype SKILL's Phase 1 DONE when, both entry
gates' cannot-ask branches and gates-table cells, the 3.8.1 CHANGELOG, the
plugin README, and release-checklist row 10), recorded in the spec as CL9
(`52ccc53`). Why: the entry gates sit in § The question, while the question
is still being chosen, and the frame text said only that a gate asking once
the question is chosen puts its question after the frame — nothing about a
cannot-ask branch that asks nothing and stops. The entry gates this batch
added are the first to reach that gap, the runs' last messages therefore
refer to a frame the user never saw, and row 10's criterion would keep
failing in every later smoke run.

First re-run on `52ccc53` (§ 2.6): **still FAIL** in all three cases. Each run
read the fixed text and met every other criterion — no write, no commit,
the brief's sha256 unchanged, the entry and the word named — but none sent
the frame as a message before the last one, and each last message again
refers to a frame the trace lacks: "appears only in the frame above"
(word-c-2), "The derived "Settled by" line above was not written into the
brief" (unrec-c-2), "the run stopped at the frame" (noentry-c-2). The
sessions' `thinking` blocks are redacted in the transcript (signature
only), so whether the frame was composed there cannot be read; nothing the
user sees holds it. The acceptance session's first reading: the fixed text
asks for two messages at the end of a run that asks nothing — the frame,
then the stop — and in all three runs the model folded the frame into its
reasoning and sent the stop alone, then wrote about the frame as if it had
been shown. At the interactive entry gates (cases 4 and 6) the frame and
the gate's question went out together as one message, the last of that
invocation. A direction that follows that working pattern: the stop
message itself opens with the frame's five fields, then gives the stop,
rather than depending on a separate earlier message.

Second fix (main session): `e470453` (`fix(skills): open an unattended
prototype stop's last message with the frame` — the prototype SKILL's
Phase 1 DONE when, both entry gates' cannot-ask branches and gates-table
cells, the 3.8.1 CHANGELOG, the plugin README, and release-checklist row
10), recorded in the spec as CL10 (`ff505c6`, amending CL9). In a session
that cannot ask, a stop at an entry gate is now one message, the last: the
frame's five items in order, then the entry, the status word found, and
why the run stopped — the shape an interactive run gives a gate's question
after the frame. Second re-run on `ff505c6` (§ 2.7): **PASS** in all three
cases — each `result` opens with the frame's five items in order, then
names the entry and the word and why it stopped, refers to nothing the
user did not see, and the run wrote nothing, committed nothing, and left
the brief's sha256 unchanged.

**F2 — the gap round's status question did not ask for the answer.** In
`d-acc-plan-gap`'s gap round, the status questions for entry 4 (`需要原型`)
and entry 6 (`pending`) asked "Which status should it have? If it's
`needs prototype`, do you want to prototype it first or carry it?" and
nothing about an answer for `answered`. After the driver replied
"Entry 4: answered." with no text, the run carried the entry correctly and
said: "For entry 4, you picked `answered`, but my question never asked what
the answer is. … it's my miss." The plugin's text: generate-plan Phase 1
Step 1 part 2, "the question that asks an unrecognized entry's status also
asks, for `answered`, the answer — one question, one round"; spec ruling D5.
Row 4's criterion for this case — a reply of `answered` with no answer text
is not taken as settled — holds (§ 2.2), and no second round was needed
because the draft carried the entry. The acceptance session's first reading:
a behavior slip against an explicit sentence, with no effect on the plan's
content; row 4 names no criterion for the question's wording.

Classification (main session): **behavior deviation**, recorded for the
roadmap and not fixed in this batch. Why: generate-plan's sentence says
plainly that the status question also asks the answer for `answered`, and
the run admitted the omission; row 4's criterion for this case (a reply of
`answered` with no answer text is not taken as settled) holds, and the
plan's content is unaffected. The roadmap item is written by the
release-preparation session. F2 does not block the release.

## 4. Observations

**O1 — explanatory output-style blocks in every run.** Each run's messages,
the `result` a driving session reads included, carry `★ Insight` blocks from
the user-level explanatory output style (a user SessionStart hook), not from
the plugin. In case 1 the draft and the not-approved line are still in the
last message, after the block.

**O2 — probes outside the project.** Case 1 wrote a probe project under its
session scratchpad through `Bash` and could not remove it ("the command to
delete it was blocked" — the user's global deny rule on `rm -rf`); the gap
run wrote three probe files there with `Write`. Neither touched the smoke
project. The case-1 criterion "no Write, Edit, or Agent call" holds
literally (14 `Bash` calls); a reading that counts any Write, wherever it
lands, would still pass case 1 and fail nothing in case 3, whose criterion
is "no file written".

**O3 — the written plan against the printed draft.** Of 355 lines, 7
differ between case 1's draft and `b06cca4`: "you" → "the user" in Step 6's
heading, Testing Strategy, and Risks 4–5; the Documentation impact item for
`CLAUDE.md` reformatted (`**`CLAUDE.md`:** N/A for this document. The
project …` → `` `CLAUDE.md` — N/A for this document: the project … ``); and
two `﻿` escapes written as the literal U+FEFF character (the reviewer's
angle 4 turned them back into `﻿`). The final message mentions only the
pronoun change. The approved content is unchanged.

**O4 — the driver's remove commits carry no `Question:` / `Answer:`.** The
seed's `chore: remove prototype <slug>` bodies hold only `Prototype: <hash>`;
`d-acc-proto-noentry-c` noticed ("The answer isn't anywhere in git") and
said the brief is the only copy of the answer. A seed artifact, not plugin
output.

**O5 — `.remember/` in the smoke projects**, as in the batch C record (O10):
written by a user-level plugin, ignored by a global exclude.

**O6 — the costliest session.** `d-acc-plan-cannot`: $2.00 to the draft,
$2.75 more for the write and the four-angle review — $4.75 of the $10.89.

**O7 — a hook-spawned review session in the diagnosis project.** At
12:36:28, right after `d-acc-diag` wrote its reproduction test, a second
transcript appeared under `batch-d-diag`'s trace directory (`4a3da9f5`,
entrypoint `sdk-py`, model `claude-opus-4-7`, prompt "Review this change for
security vulnerabilities."): a user-level security-review hook, not the
kenspc plugin. It read the test file and reported nothing. Its cost is not
in `d-acc-diag`'s `total_cost_usd` and not in this record's total.

## 5. Not exercised

Budget (8 sessions for the first pass and 3 for each re-run, set by the
main session; every session was used):

- CL5 (b), the interactive half — the prototype-again question for an
  unrecognized word that holds `Prototype:` and no `Answer:`. The
  cannot-ask half ran (`d-acc-proto-unrec-c`); the question itself is shown
  at the same gate for an `open` entry holding `Answer:` (case 6).
- CL5 (a): a `needs prototype` entry holding `Prototype:` and no `Answer:`
  built with no prototype-again question — it builds a prototype, outside
  this budget.
- CL2 and CL7 (a "yes" to the prototype-again question followed by nothing
  built, or by a built attempt that does not settle the question; T2): they
  need an in-app or feature-prototype setup, or a real build, which this
  acceptance did not budget.
- Row 4: an `answered` entry with an `Answer:` label and nothing after it
  (CL3 — the seed had no such entry); a brief with no `## Open Questions`;
  "prototype first" (batch C covered it); a cannot-ask `/kenspc-plan` on
  free text (M8, out of scope).
- Row 9: the "run" branch, the cannot-ask exit, tier 3, a manual
  reproduction, a diagnosis that probes into a run directory (this one
  probed with `node -e` only; no `.kenspc/` was created), a bug the project
  cannot reproduce.
- Row 10: every case the batch C record lists as not exercised, and the
  gates a "yes" leads to.
- D-5 and D-6 as behavior: no review run was made during a red interval,
  and no one-time `.gitignore` commit with uncommitted `.gitignore` edits;
  both are documentation in this batch and were checked as text (§ 2.5).

Other reasons: Windows and WSL2 were not run — macOS only.

## 6. Summary

| Item | Result |
|---|---|
| Row 4: cannot-ask stop at the draft — full draft, `Plan not written: awaiting approval.`, nothing written, reviewed, or committed | PASS (O1, O2) |
| Row 4: approval by `--resume` under the reminder — written at `<name>-3.md` beside two kept plans, reviewer, commits | PASS (O3) |
| Row 4: `answered` with no `Answer:` — asked in the gap round; carried `open` with `Answer: missing` when the session cannot ask (case 1) or the reply has no answer (CL8) | PASS, and **FAIL F2** (the status question did not ask the answer) — behavior deviation, roadmap, not blocking |
| Row 10: `需要原型` — interactive gate and stop; cannot-ask stop naming the entry and the word; sha256 unchanged | PASS, and **FAIL F1** (no frame in the cannot-ask stop) — plugin defect; after `d02a64f`, `d-acc-proto-word-c-2` still **FAIL**; after `e470453`, `d-acc-proto-word-c-3` **PASS** |
| Row 10: `open` holding `Answer:` — prototype-again gate, "no", sha256 unchanged, gate before the derived write | PASS |
| Row 10: unrecognized word holding `Prototype:`, cannot-ask (CL5 (b)); no ENTRY with an answered `needs prototype` entry, cannot-ask (CL1) | PASS, and **FAIL F1** (no frame) in both; after `d02a64f`, `d-acc-proto-unrec-c-2` and `d-acc-proto-noentry-c-2` still **FAIL**; after `e470453`, `d-acc-proto-unrec-c-3` and `d-acc-proto-noentry-c-3` **PASS** |
| Row 9: interactive exit names `3f57502` and gives `git revert 3f57502` | PASS |
| Guards: `guards run: 10`, `self-tests run: 9`; D-4's three checks each fail on a mutation and pass restored; both validations | PASS |
| Text: D-5 and D-6 Known behavior, 3.8.1 CHANGELOG | PASS |

Two FAILs, both classified by the main session. F1, the prototype
skill's cannot-ask stops at an entry gate sending no frame message, is a
plugin defect: its first fix, `d02a64f` (CL9), still failed in all three
re-run cases — the fixed text was read and every other criterion held, but
the frame again stayed out of the messages while the last message referred
to it; its second fix, `e470453` (CL10), which puts the frame at the head
of the stop's last message, passed in all three. F2, the gap round's
status question not asking the answer for `answered`, is a behavior
deviation recorded for the roadmap and does not block the release. Seven
observations. The smoke projects are kept under `~/Projects/_smoke/batch-d-*`.
