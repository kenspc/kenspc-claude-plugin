# Plan: Batch E — render the review once, Doc-sync documents with the fix, the approved plan written verbatim

Target: this repository (`kenspc` plugin), on top of v3.8.1 (`6575540`).
Release: 3.8.2 — no new command, skill, agent, or CONTEXT key, so a patch
release. This batch makes no version bump and no tag; its CHANGELOG entry
goes under a `## 3.8.2 — unreleased` heading.

**Status: ruled.** The design was locked as E-1 to E-6 (restated below) by
the main session and checked against the repository in a headless Claude
Code session on 2026-09-26. Every question that check raised was decided by
the main session within the locked design on 2026-09-26 and is recorded in
[Design decisions](#design-decisions). This document is the complete
specification: the implementing session needs nothing beyond this file and
the repository. A locked point is written with a hyphen (E-1); a row of the
architecture table without one (D1).

## Objective

1. A review run renders its reports once. Between the dispatches the
   orchestrator prints one progress line per step; the Schema A roll-up,
   code-fixer's reply, and Schema C appear only in the final report
   (Schema F in `/kenspc-task-review`, Schema G in `/kenspc-task-implement`).
2. The documents a Doc-sync task synced follow the review's fixes. In a
   review against a task document whose Doc-sync task is DONE, a fix that
   changes behavior one of the listed documents describes corrects that
   document's sentence in the fix's own commit, and the final report says
   which documents the fixes changed, instead of asking the user to re-check
   them.
3. A plan written on approval is the approved draft, character for
   character; a change after the last full print is printed in full and
   approved again.
4. Known behavior says why a regression a fix brought in fails the verdict
   while a deferred MEDIUM does not; the verdict rule itself is unchanged.
5. The roadmap's transcript-audit item leaves with a reason: no such script
   is in the repository.

**In scope:** E-1 to E-6 of the locked design (below); the documentation the
change requires.

**Out of scope:** roadmap items 4, 6, 7, 8, 9, 10, and 11 (numbered as at
`6575540`); any new skill, command, agent, or CONTEXT key; any edit inside a
byte-identity section — the canonical blocks (`canonical:run-dir`,
`canonical:dispatch`, `canonical:stats-line`, `canonical:verdict-shared`),
the code-craft canonical paragraphs (`canonical:principle:*`), and the five
reviewers' six shared sections; any diff to the five reviewers,
`regression-verifier`, `task-implementer`, the three document reviewers,
`shared/`, `references/`, `hooks/`, `commands/`, or the `generate-brief`,
`generate-task`, `generate-guide`, `diagnose-bug`, and `prototype` skills;
any diff to `generate-plan/SKILL.md` outside Phase 2 Step 3; any change to
the verdict rules (E-4 documents them); any change to `scripts/` unless the
Schema B recount guard needs one (under the rulings it does not — see D6).

### The locked design (E-1 to E-6)

Restated for reference. The rulings below refine these points; they do not
reopen them. Where a ruling reads a point beyond its literal words, its row
says so and why the reading stays within the point's intent.

- **E-1 Render the intermediate reports once** (roadmap item 1, Mac O1).
  Today `task-review/SKILL.md` renders the Schema A roll-up in Step 4,
  code-fixer's reply in Step 5, and Schema C in Step 6, and Step 7's
  Schema F renders them all again; `task-implement/SKILL.md` does the same
  in Phase 2 Steps 1–3 and Step 4's Schema G. Change: each intermediate step
  prints one progress line (which agent returned, a count or result, the
  report file's path); the Schema A roll-up, code-fixer's statistics line
  and Schema B path, and Schema C are rendered only in Schema F / Schema G.
  The `canonical:dispatch`, `canonical:stats-line`, and
  `canonical:verdict-shared` blocks are untouched. Why: the same tables
  appear twice in one long run, and both copies stay in the orchestrator's
  context. The release checklist's criteria for the intermediate renders
  change with it.
- **E-2 Doc-sync documents travel with the fix** (roadmap item 5, direction
  (a)). When REVIEW_SCOPE is `task` and the task document holds a Doc-sync
  task whose Status is DONE, code-fixer brings the documents that task lists
  into its fix scope: when a FIXED issue changes behavior one of those
  documents describes, the same fix commit changes that document's
  corresponding sentence. Limits: only documents the Doc-sync task names;
  only the sentences that fix affects; no new section, nothing else changed;
  the Schema B row says which document it changed. Not applicable when
  REVIEW_SCOPE is `changes` (no task document). regression-verifier has zero
  diff. Schema G's bullet "re-check the Doc-sync documents" becomes a list of
  the documents the fix commits actually changed (with FIXED greater than 0
  and no document changed, the bullet says none was affected). code-fixer's
  byte-identity sections (`canonical:principle:*`, `canonical:stats-line`)
  are untouched; if the Schema B row gains an annotation,
  `check-run-contract.sh`'s recount must still pass. Why: the point of
  Doc-sync is that documents travel with the commit; asking the user to
  re-check afterwards only moves batch A's gap.
- **E-3 Roadmap item 3** (transcript audit scripts). Look for the scripts in
  `scripts/` and `docs/`. If found, make them read the report text from the
  assistant messages of `<session_id>.jsonl` and `subagents/` instead of
  tool_result (from Claude Code 2.1.281 the tool_result no longer carries
  it); if not — the main session found only `check-*` in `scripts/`, and
  nothing in `docs/` — the item leaves on the grounds that since 3.6.0 the
  acceptance records read transcripts with `jq` directly and no script is
  kept in the repository, with one CHANGELOG sentence.
- **E-4 The verdict asymmetry stays** (roadmap item 2). A regression brought
  in by a fix commit fails the verdict whatever its severity; a DEFERRED
  MEDIUM does not. `plugins/kenspc/README.md` Known behavior gains one item
  saying why: a regression is this run breaking the code, not a leftover
  issue. The verdict rule is not changed and `canonical:verdict-shared` is
  untouched.
- **E-5 Write the approved draft verbatim** (the batch D acceptance, O3).
  generate-plan Phase 2 Step 3, "On approval", gains: the file written is the
  draft last printed, character for character — no pronoun changed, no
  reformatting, no escape changed; a change means printing the full draft
  again and getting approval again; in a session that cannot ask, an
  approval by `--resume` writes verbatim too. Release-checklist row 4's
  criterion gains "the draft (taken from the transcript) and the file diff
  empty". Why: the written plan is the approved plan; polishing it after
  approval makes it a different one.
- **E-6 Release.** No new command, so 3.8.2, a patch; the CHANGELOG entry
  under `## 3.8.2 — unreleased`; roadmap items 1, 2, 3, and 5 leave in the
  release commit, which renumbers the rest and keeps the heading
  `## Next minor (3.9.0)`; the version is bumped in the release commit only;
  no tag.

Where each point lands:

| Point | Steps | Rulings |
|---|---|---|
| E-1 | 1.1, 1.2, 4.1, 4.2, 4.3, 4.4 | M1, M2, M3, M9, D1, D2, D3, D4, D5, D17, D19 |
| E-2 | 2.1, 2.2, 4.1, 4.2, 4.3, 4.4 | M4, M5, M6, M7, M8, M9, D6, D7, D8, D9, D10, D11, D12, D17, D18, D19 |
| E-3 | 4.3; the release commit | M11, D16 |
| E-4 | 4.2, 4.3 | M12, D13 |
| E-5 | 3.1, 4.2, 4.3, 4.4 | M9, M10, M13, D14, D15, D17, D19 |
| E-6 | 4.3; the release commit | D16 |

## Background

All line numbers are at `6575540`.

- **The double render (E-1).** `task-review/SKILL.md` Step 4 (lines
  304–316) renders the per-angle roll-up table; Step 5 (lines 341–344)
  renders code-fixer's reply "verbatim"; Step 6 (lines 375–385) renders
  Schema C and its Detail prose "verbatim". Step 7's Schema F (lines
  391–417) renders all three again: its Review summary placeholder reads
  "Schema A roll-up across 5 agents — total HIGH / MEDIUM / LOW counts", its
  Fixes section "code-fixer's reply verbatim", its Verification section
  "Schema C verbatim". `task-implement/SKILL.md` Phase 2 Step 3 (lines
  365–394) aggregates the roll-up, renders code-fixer's reply "verbatim",
  and renders Schema C "verbatim"; Step 4's Schema G (lines 400–444) holds
  the same three sections. The agents' replies are already in the
  orchestrator's context as their results. code-fixer's reply carries the
  statistics line, the uncommitted-fixes line when there is one, the
  Per-angle Results table, the HIGH and MEDIUM rows with their Deferred
  Issues paragraphs, the scratch-pollution note, and the path of
  `schema-b.md` (`code-fixer.md` lines 310–322, whose Why says "the
  orchestrator renders this reply verbatim in the final report").
  regression-verifier has no Write tool: Schema C exists only in its reply,
  which ends with a one-line CLEAN or HAS ISSUES.
  `task-implement/SKILL.md` Phase 1 Step 5 (lines 150–185) also renders
  Schema D verbatim, and Schema G's Implementation section renders it again.
  No guard anchors any rendering sentence (`check-canonical-dispatch.sh`
  reads only the dispatch block). Release-checklist row 6 reads "five
  reviewer Agent calls appear, then Schema A → B → C → G", row 7 "then the
  Schema A roll-up, B, C, and the Schema F final report".
- **The re-check bullet (E-2).** Schema G's Next steps (lines 434–438): "When
  a Doc-sync task was processed DONE in this run and code-fixer's statistics
  line reports FIXED greater than 0, one bullet names the Doc-sync task's
  listed documents to re-check against the fix commits — the review's fixes
  land after the Doc-sync task, so a document it synced can already describe
  pre-fix behavior." The plugin README's Documentation path paragraph ends
  on the same bullet, release-checklist row 6 checks it, and the 3.6.0
  CHANGELOG records it. Schema F has no such bullet.
- **What code-fixer reads today.** PREREQUISITES item 2: with REVIEW_SCOPE
  "task", "read the task document … for context". Its fixes are committed one
  per fix (FIXING RULES); before each fix in a committed run it runs
  `git status --porcelain -- <each file the fix will touch>` and DEFERs a fix
  whose file has uncommitted changes the run did not make. Its reply shows
  only HIGH and MEDIUM rows; LOW rows stay in `schema-b.md`. The
  `PER-ISSUE OUTPUT CONTRACT`'s `action` field already allows a reason after
  an em-dash for NOT APPLICABLE, and "Counts classify an action by its
  leading word".
- **The recount guard.** `check-run-contract.sh` check 4 splits each Fixes
  Applied row on `|`, reads Source from cell 3 and Action from cell 7, and
  classifies the action by `^FIXED`, `^DEFERRED`, or `^NOT APPLICABLE`. On a
  copy of the worked example with row 5's action changed to
  `FIXED — updated README.md` (under the session scratchpad),
  `check-run-contract.sh --file` exits 0; with the action
  `UPDATED README.md — FIXED` it exits 1 ("unknown action"). The self-test's
  recount mutations are literal replacements on the example's row 3 action,
  row 4 Source, the Q and R Per-angle rows, and the statistics line.
- **The Doc-sync task as code-fixer would read it.** generate-task writes it
  from a template (`generate-task/SKILL.md` lines 153–190): the heading
  `### Task N: Doc-sync`, `**Status:**`, `Depends on: Task 1-<N-1>`, then a
  `**Documents** (…)` label over one bullet per document, each opening with
  the path in backticks — `` - `<path>` § <section> — <what must change>
  (<causing plan step>) `` — some marked "edited by Task <K>: verify it …"
  or "that step is outside this task document: leave this change to the task
  document that covers it". generate-task keeps three anchors in English in
  any document language: the `**Status:**` line, the `Depends on:` line, and
  the heading (lines 251–256); the `**Documents**` label is not among them.
  task-implementer records each task's Status in the document, so a DONE
  Doc-sync task reads `**Status:** DONE`. `check-doc-sync-anchors.sh`'s
  `Doc-sync` group holds the label in `generate-task/SKILL.md`,
  `diagnose-bug/SKILL.md`, the task example, `task-document-reviewer.md`,
  and `task-implementer.md`; `code-fixer.md` is not in it.
- **regression-verifier under E-2.** Check 2 reads the code at each FIXED
  row's File:Line; check 4 reviews the fix commits' files for a new null
  path, a broken contract, a test that does not test the fix, and a
  swallowed error or removed validation. A document in a fix commit meets
  none of those; nothing in the review pipeline checks the document edit
  itself. A task-scope run has no `change-set.md` and no pre-fix record, so
  E-2 does not meet the uncommitted-run branch of check 4.
- **Where the verdict rules stand (E-4).** `task-review/SKILL.md`: FAIL when
  "the fixes (fix commits, or the uncommitted fixes of an `uncommitted` run)
  introduced unresolved regressions" (lines 443–446), and "MEDIUM and LOW
  issues do not change the verdict but appear in the report." (line 451).
  `task-implement/SKILL.md`: FAIL when "fix commits introduced unresolved
  regressions" (lines 467–469); it has no MEDIUM/LOW sentence, and its PASS
  rule ("zero HIGH unresolved") leaves a deferred MEDIUM out. Neither rule
  grades a regression by severity. The README's only verdict text is in
  "Red interval after a diagnosis". code-fixer runs build, test, and lint
  after each fix; a fix that breaks a test is caught there or, if it
  survives, is a row-3 test FAIL, which "forces a FAIL verdict" through the
  build / test / lint clause rather than the regression clause.
- **The written plan against the approved draft (E-5).** In the batch D
  acceptance (`docs/dry-runs/batch-d-acceptance.md`, O3), a cannot-ask plan
  run was approved on resume and wrote `…-3.md`; against the draft its last
  message had printed, 7 of 355 lines differed: "you" → "the user" in four
  places, a Documentation impact line reformatted, and two `﻿` escapes
  written as the literal U+FEFF character. The final message mentioned only
  the pronouns. Step 3 today (lines 340–378): the approval stop, its
  cannot-ask branch (the draft printed in full, `Plan not written: awaiting
  approval.`, a later approving reply is the approval "and this step then
  runs as written"), then "On approval:" — item 1 the location (with the
  existing-file branch), item 2 "Determine the document language: a. If the
  user specified a language, use it. b. Otherwise, default to English.",
  item 3 "Write the plan to the file." Step 1's writing rules already set
  the draft's language ("Default language: English (unless the user
  explicitly requests otherwise)"), and Step 2's self-challenge rounds may
  show revisions without reprinting the whole draft. `plan-document-reviewer`
  commits an untracked plan unchanged before its first fix commit, so the
  file as written survives in history.
- **Transcript audit scripts (E-3).** `git ls-files` lists no script
  outside `scripts/check-*.sh` except the two hook scripts
  (`remind-plan-skill.sh`, `session-end-telemetry.sh`);
  `git log --all --diff-filter=A --name-only` shows no file ever added whose
  name holds `audit`, `transcript`, or `trace` (the same command finds
  `check-run-contract.sh`, so it can find a file). `docs/` holds only the
  release checklist, the roadmap, and the dry-run records. Since 3.6.0 the
  records read the transcripts themselves: `scratch-probes-acceptance.md`
  (3.6.0), "every Bash command, Write, and Edit below was read from them with
  `jq`", over the subagent JSONL files; the batch D record's Traces row names
  `<session_id>.jsonl` and `<session_id>/subagents/`.
- **Guards.** `check-all.sh` runs every `scripts/check-*.sh`; the release
  checklist and CLAUDE.md pin `guards run: 10` and `self-tests run: 9`.

## Design decisions

Questions found while checking E-1 to E-6 against the repository. Each row
gives the options considered, the lean the draft proposed with its reason,
and the ruling. Every ruling was decided by the main session within the
locked design on 2026-09-26; it binds this batch, and the implementing
session applies it without reopening it. Every ruling takes the draft's
lean, with two changes: D1 revises the three progress lines so that each
opens with the name of the agent that returned, and M12 adds that the
acceptance attempts the live case once. D12 and D14 fix wording the lean
left open (the fallback bullet as a defect signal; release-checklist row 4's
phrasing). The Implementation Steps follow the rulings.

Four rulings read a locked point beyond its literal words, and each row
says why the reading stays within that point's intent: M1 reads E-1's
"statistics line and Schema B path" as naming code-fixer's whole reply by
its two anchors; M4 extends E-2's Schema G bullet to Schema F; M13 applies
E-5's reprint rule on the resume path; D17 adds README sentences for E-1,
E-2, and E-5, where the lock names the README only for E-4. M2 and M8 leave
two gaps out of scope: they are recorded under
[Risks](#risks-and-mitigations), and the main session lists them as new
roadmap entries in its report; this batch changes no roadmap item beyond
the four E-6 names. M12's row carries a spec note on how its text check
reads the two skills, which differ at `6575540`.

### Mismatches between the locked design and the repository (M1–M13)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| M1 | E-1 names "code-fixer's statistics line and Schema B path" as what the final report renders; Schema F and G today render code-fixer's whole reply (statistics line, Per-angle Results, HIGH and MEDIUM rows with their Deferred Issues paragraphs, scratch-pollution note, path), and Next steps' per-issue bullets are written from it. | (a) The whole reply, rendered once, in Schema F / G — the reply contract in `code-fixer.md` unchanged. (b) Only the statistics line, the path, and the one-line notes (uncommitted fixes, scratch pollution, Doc-sync documents); the rows and paragraphs stay in `schema-b.md`. | (a), reading E-1's words as naming code-fixer's output by its two anchors. E-1's point is "once", not a smaller final report; (b) changes the final report's content, moves the HIGH and MEDIUM detail a path away where Next steps is told to give "enough detail to act … without reading the review reports", and makes code-fixer's Why ("renders this reply verbatim in the final report") false. | **(a)**, reading E-1's "statistics line and Schema B path" as naming code-fixer's output by its two anchors — decided by the main session within the locked design. E-1's point is rendering once, not a smaller final report; code-fixer's reply contract and Next steps' "enough detail to act" both rest on the whole reply. Steps 1.1, 1.2. |
| M2 | `task-implement/SKILL.md` Phase 1 Step 5 renders Schema D verbatim and Schema G's Implementation section renders it again — the same double render E-1 removes, but E-1 and roadmap item 1 name Schema A, B, and C. | (a) Out of scope; recorded under Risks as a roadmap candidate. (b) In scope: Step 5 prints only its progress update and Schema D renders once, in Schema G. | (a). Step 5 is the Phase 1 → Phase 2 boundary, whose transition failed to trigger in 3.0.2 and which row 11 checks by its two fixed lines; changing what that boundary prints needs its own acceptance, and the lock does not name it. | **(a)** — decided by the main session within the locked design. Schema D is not among the reports E-1 names, and the Phase 1 → Phase 2 boundary has failed before; changing what it prints needs an acceptance of its own. Recorded under Risks; the main session lists it as a new roadmap entry in its report. Risks. |
| M3 | Schema F's Review summary placeholder reads "total HIGH / MEDIUM / LOW counts", while the per-angle table is Step 4's. With Step 4 printing a progress line only, the per-angle breakdown would appear nowhere. | (a) Step 4's table template moves into Schema F's Review summary, which renders the per-angle roll-up (Schema G's Code Review likewise). (b) Schema F keeps totals only. | (a). E-1 says the roll-up is rendered only in Schema F / G, not dropped; the per-angle counts are what tell the user which angle found what. | **(a)** — decided by the main session within the locked design. E-1 says the roll-up is rendered only in Schema F / G, not that it is removed; the per-angle counts need a place to land. Steps 1.1, 1.2. |
| M4 | E-2 names Schema G's bullet. `/kenspc-task-review` with a task document (REVIEW_SCOPE `task`) dispatches the same code-fixer, which then applies E-2 too; Schema F has no Doc-sync bullet. | (a) Schema F unchanged; code-fixer's Doc-sync line appears in its Fixes section only. (b) Schema F's Next steps gains the same bullet whenever code-fixer's reply carries the line and FIXED is greater than 0. (c) A Schema F bullet only for a document left not updated. | (b), beyond E-2's words and within its intent: one rule in both reports, and a document left not updated is an action for the user whichever entry point ran the review. Schema F cannot carry task-implement's fallback (the orchestrator of `/kenspc-task-review` never learns the Doc-sync task's status), so it keys on the line. | **(b)**, beyond E-2's literal words and within its intent — decided by the main session within the locked design. `/kenspc-task-review` with a task document runs the same code-fixer, so the same rule shows its result to the user in both reports; Schema F keys on the line, without task-implement's fallback. Step 2.2. |
| M5 | E-2 puts the note in the Schema B row, but code-fixer's reply shows only HIGH and MEDIUM rows; a LOW fix that corrected a document never reaches the orchestrator, which builds Next steps from the reply alone. | (a) One reply line after the statistics line, `Doc-sync documents: …`, always present in a run where the rule applies (`none affected by the fixes` when empty). (b) The orchestrator reads `schema-b.md`. (c) The orchestrator lists the fix commits' files with git. | (a). It follows the uncommitted-fixes line's precedent; (b) and (c) bring report text back into the orchestrator, which the run directory was built to avoid. Always present, like `## Decisions needing a home`, so a run that checked is told from one that did not. | **(a)** — decided by the main session within the locked design. The reply carries only HIGH and MEDIUM rows, so a document a LOW fix changed reaches the orchestrator only through a line that is always present; (b) and (c) bring report text back into the orchestrator. Step 2.1. |
| M6 | code-fixer's committed-run rule DEFERs a fix whose file has uncommitted changes the run did not make. A listed document is a file the fix touches. | (a) The rule applies to the code the fix changes; a listed document with uncommitted changes is left untouched and reported `not updated` with that reason, and the code fix still lands. (b) The rule as written: the whole fix is DEFERRED. | (a). The fix's value does not depend on the document, and deferring a HIGH fix for a dirty README trades a defect for a stale sentence; the report names the document for the user. The rule's reason — never sweep the user's hunks into a fix commit — still holds, since the document is not touched. | **(a)** — decided by the main session within the locked design. A code fix is not deferred for one dirty document: the document is left untouched and reported `not updated`, and the dirty-file rule's reason — no user hunk swept into a fix commit — still holds. Step 2.1. |
| M7 | How code-fixer finds the Doc-sync task's documents. The heading, `**Status:**`, and `Depends on:` stay in English in any task document; the `**Documents**` label does not, so a task document in Chinese can carry a translated label. | (a) The section under `### Task N: Doc-sync`, up to the next `### ` heading; its documents are the paths in backticks that open the bullets of its document list; no label is read. (b) The list under the `**Documents**` label. | (a). It reads only anchors generate-task keeps fixed and the one shape its template gives every entry; (b) breaks on a translated label without an error. | **(a)** — decided by the main session within the locked design. code-fixer reads only the anchors generate-task fixes — the heading, `**Status:**`, and the backticked path that opens each bullet (every bullet of the template opens with `` `<path>` ``, checked by the main session) — never a label a translation can change. Step 2.1. |
| M8 | `check-doc-sync-anchors.sh` holds the `Doc-sync` label in every file that writes or reads it; code-fixer will read it, but this batch may change `scripts/` only for the recount guard. | (a) Out of scope; recorded under Risks as a roadmap candidate. (b) Add `code-fixer.md` to the `Doc-sync` group: one array entry, counts unchanged, CLAUDE.md's description of that guard updated in the same commit. | (a), as the constraint on `scripts/` reads. (b) costs one entry and no count change, if the main session widens the constraint. | **(a)** — decided by the main session within the locked design. The constraint lets this batch change `scripts/` only for the recount guard. Recorded under Risks; the main session lists it as a new roadmap entry in its report. Risks. |
| M9 | Sentences E-1, E-2, and E-5 make false or incomplete: release-checklist rows 4, 6, and 7; row 6's re-check criterion; the plugin README's Documentation path sentence on the re-check bullet; CLAUDE.md's documentation path paragraph (silent on code-fixer) and its Parallel MapReduce list (silent on where the reports are rendered). | Mechanical update with the change. | Mechanical; no alternative considered. The 3.6.0 CHANGELOG's description of the re-check bullet is history and stays. | **Mechanical update**, each sentence in the same commit as the change that makes it false — decided by the main session within the locked design; no alternative. Steps 1.1, 2.2, 4.2, 4.4. |
| M10 | Step 3's item 2 decides the document language at write time ("If the user specified a language, use it. Otherwise, default to English."). Under E-5 the file is the draft verbatim, so the write cannot translate. | (a) Item 2 names the draft's language, which Step 1's writing rules set when drafting; a request for another language at approval is a change: the draft is translated, printed in full, and approved again. (b) Item 2 unchanged. | (a). (b) leaves a sentence that reads as licence to transform the draft on write — O3's pronoun change is the same kind of edit. Step 1 already fixes the draft's language, so (a) changes no outcome for a draft already in the requested language. | **(a)** — decided by the main session within the locked design. Deciding the language at write time contradicts a verbatim write; Step 1's writing rules already set the language when the draft is written, and (a) changes no outcome for a draft already in that language. Step 3.1. |
| M11 | The main session's acceptance brief expects E-3's disposition to be found by grep in the CHANGELOG and the roadmap, but E-6 removes roadmap items only in the release commit, after the acceptance. | (a) The acceptance greps the CHANGELOG sentence; the roadmap's removal is checked with the release commit. (b) The roadmap item leaves in the batch. | (a). E-6 fixes the timing, and a roadmap without the item before the release would describe work as shipped that is not. | **(a)** — decided by the main session within the locked design. E-6 locks the roadmap's change into the release commit; the acceptance greps the CHANGELOG, and the roadmap's removal is checked with the release commit. Testing Strategy. |
| M12 | E-4's planned live case — a fix that makes another test fail — is caught by code-fixer's own build / test / lint run after each fix, and one that survives is a row-3 test FAIL, a FAIL through the build / test / lint clause rather than the regression clause. A regression only regression-verifier's check 4 finds (an untested caller broken by a changed contract) cannot be planted deterministically. | (a) E-4's acceptance is the text: the Known behavior item found by grep, its two quoted sentences present in the skills; the live case is best-effort and recorded as not exercised when code-fixer catches its own regression. (b) The live case is required. | (a). The verdict rule is unchanged, so the live case tests 3.8.1 behavior; the change is documentation. | **(a)**, with one addition — decided by the main session within the locked design. The acceptance still attempts the live case once, on a seed built so that code-fixer's own test run does not catch the regression. If the regression survives to regression-verifier, the criterion is verdict FAIL with the Verdict paragraph naming it; if code-fixer catches and withdraws it, the case is recorded as not exercised, with the evidence, and is not a FAIL. The text check — the Known behavior item found by grep, and the two rule sentences present in the skills — must pass. Spec note: at `6575540` the MEDIUM and LOW sentence is in `task-review/SKILL.md` only, and `task-implement/SKILL.md` reaches the same outcome through its PASS rule ("zero HIGH unresolved"); adding the sentence there would edit its verdict rules, which E-4 rules out, so the check reads the regression clause in both skills and that sentence in task-review (mechanical 5). Testing Strategy (case 7, mechanical 5). |
| M13 | E-5 asks for a reprint when anything changes. D-1's paragraph tells a cannot-ask run to say "reply … approving the draft or asking for changes", but says what happens only on approval. | (a) Step 3 gains: in a session that cannot ask, a reply that asks for a change gets the revised draft printed in full, the `Plan not written: awaiting approval.` line again, and a stop; nothing is written. D-1's paragraph is not edited. (b) Leave it to the approval sentence. | (a), beyond E-5's words and within its intent: E-5's "print the full draft again and get approval again" is the same rule met on the resumed path, where the reminder still holds. | **(a)**, beyond E-5's literal words and within its intent — decided by the main session within the locked design. It is E-5's own rule — a change is printed in full and approved again — met on the resume path; D-1's paragraph is not edited. Step 3.1. |

### Architecture choices (D1–D19)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| D1 | The form of E-1's progress lines. | (a) Three fixed English lines with the numbers filled in, the same in both skills, whatever the conversation language: `Reviews returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`; `Fixes returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`; `Verification returned — CLEAN` or `Verification returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`. (b) Free wording, one line each. | (a). One fixed form per step is one thing the release checklist can find, as task-implement's Phase 1 boundary lines are; the forms share no string with the tables they replace, so "each table exactly once" stays countable. | **(a), revised** — decided by the main session within the locked design. E-1 asks for which agent returned, so each line's subject is the agent's name: `Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`; `code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`; `regression-verifier returned — CLEAN`, or `regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`. Otherwise as (a): the same in both skills, in English whatever the conversation language. Fixed strings, Steps 1.1 and 1.2, rows 6 and 7, and D5 follow. |
| D2 | What each line carries (E-1: which agent, a count or result, the report path). | (a) As in D1: the roll-up's totals and the run directory's report paths; code-fixer's FIXED / DEFERRED / NOT APPLICABLE from its statistics line and `schema-b.md`; regression-verifier's closing CLEAN or HAS ISSUES with each non-PASS row — no path, since it writes no file. (b) Also each angle's counts. | (a). Per-angle counts are the table E-1 moves to the final report. regression-verifier has no Write tool, so no path exists for it. | **(a)** — decided by the main session within the locked design. The per-angle counts are the table E-1 moves to the final report; regression-verifier has no Write tool and no report file, so its line names no path. Steps 1.1, 1.2. |
| D3 | Where the table templates in the steps go. | (a) Step 4's roll-up template moves into Schema F's Review summary; Step 6's example Schema C table is removed (regression-verifier's OUTPUT FORMAT defines Schema C) and the step describes what comes back in words. task-implement's Step 3 has no template. (b) Keep both templates in the steps, reworded as "returns". | (a). A table under "Render …" is what the model renders; the template belongs where the table is rendered. | **(a)** — decided by the main session within the locked design. A table under "Render …" is a table that gets rendered; the template goes where it is rendered, and Schema C's shape is defined by regression-verifier's OUTPUT FORMAT. Step 1.1. |
| D4 | Keeping the two skills' progress wording in step, outside any canonical block. | (a) The same three fixed lines in both, listed in Fixed strings, unguarded; release-checklist rows 6 and 7 each check their skill's lines. (b) A new canonical block with a guard. | (a). A new canonical block needs a guard, and `scripts/` is out of scope; the steps around the lines differ between the skills by design. | **(a)** — decided by the main session within the locked design. A new canonical block needs a guard, and `scripts/` is out of scope; rows 6 and 7 each check their own skill. Steps 1.1, 1.2, 4.4. |
| D5 | Rows 6 and 7's criterion for "no table between, each once in the end" (E-1). | (a) In the session's assistant content, in order: after the five reviewer Agent calls return, `Reviews returned —` before the code-fixer call; `Fixes returned —` before the regression-verifier call; `Verification returned —` before the final report; no text line beginning with `\|` from the first reviewer call until the final report's first heading; across all the session's assistant text, the roll-up header (`\| Angle \| HIGH \| MEDIUM \| LOW \|`), a line holding `total reported `, and the Schema C header (`\| # \| Check`) each occur exactly once. (b) "The intermediate steps render no table", judged by reading. | (a). Each part is a `jq` query on the transcript and each can fail; a reading cannot. | **(a)** — decided by the main session within the locked design. Each part is a `jq` query on the transcript that can fail; it is written with D1's revised line openings. Step 4.4; Testing Strategy. |
| D6 | How the Schema B row names the document (E-2). | (a) A suffix to the Action cell after an em-dash: `FIXED — updated <path>[, <path>]`, `FIXED — not updated <path>: <reason>`, several joined by `; `. (b) A new column. (c) A note under the table. | (a). The recount and regression-verifier classify an action by its leading word, so the counts do not move (checked: the recount passes the suffix and rejects a row that does not begin with FIXED); the NOT APPLICABLE reason is the precedent; no column is added to every Schema B in every run. `scripts/` needs no change. | **(a)** — decided by the main session within the locked design. The recount classifies an action by its leading word; the suffix was checked to pass and a counter-example to fail; no column is added to every Schema B. Step 2.1. |
| D7 | Whether the worked Schema B example shows the suffix. | (a) No: the rule is stated in the `action` field and the reply list, and the example between the `example:schema-b` markers is unchanged. (b) Row 5 of the example gains `FIXED — updated README.md`. | (a). The example is imitated in every run, and the suffix applies in one scope only; the self-test's literal mutations anchor rows 3 and 4 and would stay valid under (b), but (a) keeps the recounted block out of this batch. | **(a)** — decided by the main session within the locked design. The example block is imitated in every run and the suffix applies in one scope only; the recounted block stays unchanged. Step 2.1. |
| D8 | The reply line's fixed form (M5). | (a) `Doc-sync documents: updated <path> (row <n>, <commit>)[; …][; not updated <path> (row <n>) — <reason>]`, or `Doc-sync documents: none affected by the fixes`; present in every `task` run whose Doc-sync task is DONE, FIXED 0 included; in the reply only, not in `schema-b.md`, whose last line stays the statistics line. (b) Present only when FIXED is greater than 0. | (a). Always present in scope, so its absence means the rule did not run; the file's layout, which the recount reads, is unchanged. | **(a)** — decided by the main session within the locked design. Always present in scope, so its absence is itself evidence; the layout of `schema-b.md`, which the recount reads, is unchanged. Step 2.1. |
| D9 | What counts as "a sentence the fix affects", and who decides (E-2). | (a) code-fixer, after each fix, reads the parts of each listed document that describe the changed code — the sections naming the changed function, option, command, message, or file; a sentence, list item, or table row there that states the behavior the fix changed is false now, and is corrected in the document's own language. Behavior the document never described is not added; a correction that needs a new section or paragraph, or more than the false statements, leaves the document `not updated` with the reason. (b) Also extend a sentence to mention behavior the fix added. | (a). E-2's limits: the sentences the fix affects, no new content. A sentence the fix makes incomplete but not false stays, since extending it is new content. | **(a)** — decided by the main session within the locked design. It is E-2's limit: only a statement a fix made false is changed, nothing new is added, and a correction that cannot be made within that is reported `not updated`. Step 2.1. |
| D10 | The fix commit's message when it carries a document. | (a) The fix's own conventional subject; the body names each corrected document (`Updates <path> to match the fix.`). (b) No change to the message. | (a). `git log` then shows why a fix commit touches a document without opening it; the subject stays the fix's. | **(a)** — decided by the main session within the locked design. `git log` then shows why a fix commit touches a document; the subject stays the fix's. Step 2.1. |
| D11 | Which listed paths count, and a listed path that does not exist. | (a) Every path the Doc-sync task's list names, including an entry that leaves its planned change to another task document; a path with no file is skipped (the Doc-sync task was DONE, so a missing file is one another task document creates). (b) Only entries without the "outside this task document" note. | (a). What makes a sentence stale is the fix, not which phase planned the entry; skipping a missing file creates nothing, which the Doc-sync task's own rule forbids. | **(a)** — decided by the main session within the locked design. What makes a sentence stale is the fix, not which phase planned the entry; a listed path with no file is skipped, not created. Step 2.1. |
| D12 | Schema G's bullet (and Schema F's under M4). | (a) task-implement: when the task document's Doc-sync task is DONE and FIXED is greater than 0, one bullet carries code-fixer's `Doc-sync documents:` line — each document updated, with its row and commit, and each left not updated, with its reason, for the user to correct; when the line says none, the bullet is `No Doc-sync document describes behavior the fixes changed.`; when the reply has no such line, the bullet says code-fixer reported nothing on the Doc-sync documents and names the listed documents to check against the fix commits. task-review: the same bullet when the reply carries the line and FIXED is greater than 0, without the fallback. (b) No fallback in either. | (a). A missing line is the evidence that the rule did not run; the fallback keeps the old safety net for exactly that case, without the word "re-check" that the acceptance tests for. | **(a)**, with the fallback worded as a defect signal — decided by the main session within the locked design. A missing line is evidence that code-fixer's contract was not met, so the fallback bullet states `code-fixer's reply has no Doc-sync documents line` and names the listed documents to check against the fix commits, without the word "re-check"; task-review has no fallback. Step 2.2. |
| D13 | E-4's Known behavior item: title, place, content. | (a) Title `**Regressions and deferred issues in the verdict.**`, placed before "Red interval after a diagnosis", which is a case of it; it quotes task-review's two sentences (the FAIL clause on regressions introduced by the fixes, and "MEDIUM and LOW issues do not change the verdict but appear in the report.") and says why: a regression is damage this run did to code that worked before it, which only this run can be blamed for and undo, whatever its severity; a deferred issue was in the code before the run, is reported with its reason, and is the user's to schedule. It says the verdict is not graded by severity by decision. (b) A sentence in "Red interval after a diagnosis". | (a). E-4 asks for an item; quoting the rule rather than restating it keeps one source of truth. | **(a)** — decided by the main session within the locked design. E-4 asks for one Known behavior item; quoting rather than restating keeps the rule in one place. Step 4.2. |
| D14 | How the acceptance compares the written plan with the approved draft (E-5). | (a) The draft is the `result` of the invocation that ended at the approval stop (the same as the transcript's last assistant text for that invocation). The file is the Write call's `content` in the transcript and the blob of `plan-document-reviewer`'s first commit of the plan; both are compared. Normalization, on both sides: CRLF read as LF, trailing newlines at the very end dropped; nothing else — a U+FEFF anywhere is a character, an escape is the characters that spell it (`jq -r` undoes only JSON's own escaping), and trailing spaces on a line count. PASS: the file's text occurs as one contiguous block in the draft message; the record quotes the message's text before and after that block, and neither holds a heading line of the plan. Positive control: a one-character edit to a copy of the file makes the check fail. (b) Extract the draft between its `# ` title and the not-approved line, then `diff`. | (a). The message around the draft varies (a self-challenge summary, an explanatory block, the not-approved line or the approval question), so a fixed extraction rule fails on wording the skill does not fix; containment plus a quoted remainder catches a dropped or edited line and shows what was left out. | **(a)** — decided by the main session within the locked design. The text around the draft is not fixed, so an extraction by fixed start and end lines would fail on wording the skill does not govern; containment, the quoted text outside the block, and a positive control amount to "the draft and the file diff empty" and can fail. Release-checklist row 4 words it as "the draft taken from the transcript and the file differ in nothing (after the normalization above)", keeping E-5's "diff empty". Step 4.4; Testing Strategy. |
| D15 | What a change after the last full print does (E-5). | (a) Any change — found by self-challenge, shown only as a revised section, asked for by the approving reply itself, or a language request — is made to the draft, which is printed in full and approved again before anything is written; the approval covers the draft last printed in full. (b) An approving reply that names its own edit exactly ("rename X to Y, then write it") is applied and written, the final message saying so. | (a), E-5's own words. (b) saves a round for a user-dictated edit but reopens the gap O3 showed — a write that differs from every printed draft. | **(a)** — decided by the main session within the locked design; E-5's own words. Step 3.1. |
| D16 | Where E-3's sentence goes and the entry's sections (E-6). | (a) An intro paragraph (what changes; no new command, skill, agent, or CONTEXT key, so a patch; guard counts unchanged; the transcript-audit item leaving, with its reason, as one sentence), `### Changed`, and `### Known behavior` (E-4). (b) E-3 as a Changed bullet. | (a). E-3 changes no shipped file; Changed lists behavior, as batch D's entry did. | **(a)** — decided by the main session within the locked design. E-3 changes no shipped file, so it is one intro sentence; Changed lists behavior only. Step 4.3. |
| D17 | README sentences beyond E-4's item (the Durable documents table: the plugin README changes with any user-visible behavior). | (a) One sentence each: § Run directory's first bullet (E-1: between the agents the run prints one progress line per step, and the tables appear once, in the final report); § Recommended Workflow, Documentation path, its last sentence replaced (E-2); § Skills, `generate-plan` row (E-5: the plan written is the approved draft as printed; a change gets the full draft again). (b) The README only where the lock names it. | (a), README sentences beyond the lock's list, in a file on this batch's list. Each is one clause of what a skill now does, and the Documentation path sentence becomes false without it. | **(a)**, README sentences beyond the lock's list and within its intent — decided by the main session within the locked design. The plugin README is on the allowed list, the Durable documents table has it change with any user-visible behavior, and the Documentation path sentence is false without its change. Step 4.2. |
| D18 | The acceptance seed for E-2 (Testing Strategy cases 2 and 3). | (a) Tasks 1–3 DONE and committed in the seed, one of them with a planted defect that contradicts its own acceptance criterion; `README.md` committed with a sentence that states the defective behavior; the Doc-sync task TODO, listing `README.md` § that section. `/kenspc-task-implement` runs only the Doc-sync task (which finds the README matching the code), then the review. (b) All tasks TODO, the implementer writing the defect. | (a). A Doc-sync task describes the code as built, so the README must state the pre-fix behavior for a fix to make it false; with (b) whether the defect is written, and documented, is the implementer's choice. | **(a)** — decided by the main session within the locked design. A Doc-sync task describes the code as built, so the README has to state the defective behavior first for a fix to make it false; (b) leaves the defect to the implementer's choice. Testing Strategy. |
| D19 | Where the release checklist's criteria go. | (a) Additions to rows 4 (E-5), 6 (E-1, E-2), and 7 (E-1, and E-2 not applying); row 6's re-check criterion replaced; no new row; pre-flight counts unchanged. (b) A new row. | (a). Each criterion belongs to the entry point its row exercises. | **(a)** — decided by the main session within the locked design. Each criterion belongs to the row of the entry point it exercises; the counts are unchanged. Step 4.4. |

### Standing constraints

- Rules are rationale-anchored ("Why: …" prose), not imperatives; no `MUST`
  / `NEVER` / `CRITICAL`, no inline effort or reasoning tokens, no model
  names (`bash scripts/check-no-model-names.sh` exits 0).
- A check written into a skill or agent is in rubric form: what passing
  looks like, then the named ways it fails. No generic checklist items.
- No edit inside any byte-identity section: the canonical blocks, the
  code-craft canonical paragraphs, and the five reviewers' six shared
  sections are untouched, and every guard stays green. The worked example
  between `code-fixer.md`'s `example:schema-b` markers is also unchanged
  (D7).
- Zero diff, checked by
  `git diff --stat 6575540 HEAD -- plugins/kenspc/agents/requirements-reviewer.md plugins/kenspc/agents/edge-case-reviewer.md plugins/kenspc/agents/quality-reviewer.md plugins/kenspc/agents/bug-reviewer.md plugins/kenspc/agents/test-reviewer.md plugins/kenspc/agents/regression-verifier.md plugins/kenspc/agents/task-implementer.md plugins/kenspc/agents/plan-document-reviewer.md plugins/kenspc/agents/guide-document-reviewer.md plugins/kenspc/agents/task-document-reviewer.md plugins/kenspc/shared plugins/kenspc/references plugins/kenspc/hooks plugins/kenspc/commands plugins/kenspc/skills/generate-brief plugins/kenspc/skills/generate-task plugins/kenspc/skills/generate-guide plugins/kenspc/skills/diagnose-bug plugins/kenspc/skills/prototype plugins/kenspc/.claude-plugin scripts README.md docs/roadmap.md docs/dry-runs/README.md`,
  which prints nothing before the release commit (the release commit then
  changes `plugin.json` and the roadmap). `generate-plan/SKILL.md` changes
  only between `### Step 3: Write to file` and `## Phase 3: Verify via review
  agent`. The files this batch touches: `task-review/SKILL.md` and
  `task-implement/SKILL.md` (outside their canonical blocks),
  `code-fixer.md` (outside its canonical and example blocks),
  `generate-plan/SKILL.md` (Phase 2 Step 3), and the documents in
  [Documentation impact](#documentation-impact).
- No new skill, command, agent, or CONTEXT key.
- `effort:` frontmatter unchanged in every file (release-checklist
  pre-flight diff); `version: 3.0.0` unchanged in all eight skills.
- Every question point this batch adds or reaches has a cannot-ask branch
  worded "In a session that cannot ask (a system reminder to work without
  stopping), …": the reprint after a change at the approval stop (M13). The
  review path asks nothing, and E-1 and E-2 add no question.
- Plugin files state their evidence in their own words and carry no pointer
  labels — B-n, C-n, D-n, E-n, M-n, CL-n, "ruling", batch names, dry-run
  records. The criterion for every plugin file this batch edits
  (`task-review/SKILL.md`, `task-implement/SKILL.md`, `code-fixer.md`,
  `generate-plan/SKILL.md`):
  `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\b[BCDE]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>`
  prints nothing. It prints nothing on those four files at `6575540` and
  175 lines on the batch D spec, so it can fail.
- Guards keep to bash 3.2 and are not edited in this batch (rulings D6,
  M8).
- Plugin Design Lessons apply: phase transitions rest on artifacts (the
  final report is built from the agents' replies and the run directory, not
  from what the orchestrator printed between dispatches; a missing
  `Doc-sync documents:` line is evidence, not silence), and no hook guards
  workflow state.
- This spec and the acceptance record are in English.
- The dogfood: the task document for this batch comes from `/kenspc-task` on
  this spec, which generates the Doc-sync task from the Documentation impact
  below; it is not added by hand.

## Fixed strings

These strings are load-bearing: the release checklist or the acceptance
greps for them, or a later step reads them. Spell them exactly as given, in
every file that carries them.

| Anchor | Exact form | Carried by |
|---|---|---|
| Progress line, reviewers | `Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md` — in English whatever the conversation language | `task-review/SKILL.md`, `task-implement/SKILL.md`, `docs/release-checklist.md` (rows 6, 7) |
| Progress line, code-fixer | `code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md` | the same |
| Progress line, regression-verifier | `regression-verifier returned — CLEAN`, or `regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]` | the same |
| Progress line, code-fixer reply without its statistics line (CL4) | `code-fixer returned — no statistics line` | `task-review/SKILL.md`, `task-implement/SKILL.md` |
| Progress line, regression-verifier reply without its result line (CL4) | `regression-verifier returned — no result line` | the same |
| Schema B Action suffix | `FIXED — updated <path>[, <path>]`; `FIXED — not updated <path>: <reason>`; several joined by `; ` | `code-fixer.md`, `docs/release-checklist.md` (row 6) |
| Reply line | `Doc-sync documents: updated <path> (row <n>, <commit>)[; …][; not updated <path> (row <n>) — <reason>]`, or `Doc-sync documents: none affected by the fixes` | `code-fixer.md`, `task-implement/SKILL.md`, `task-review/SKILL.md`, `docs/release-checklist.md` (rows 6, 7) |
| No-document bullet | `No Doc-sync document describes behavior the fixes changed.` | `task-implement/SKILL.md`, `task-review/SKILL.md`, `docs/release-checklist.md` (row 6) |
| Missing-line bullet | `code-fixer's reply has no Doc-sync documents line` | `task-implement/SKILL.md` |
| Verbatim write | the phrase `character for character` | `generate-plan/SKILL.md` (Phase 2 Step 3), `docs/release-checklist.md` (row 4) |
| Known behavior item (E-4) | `**Regressions and deferred issues in the verdict.**` | `plugins/kenspc/README.md` |
| E-3 disposition | the phrase ``read the transcripts with `jq` `` | `plugins/kenspc/CHANGELOG.md` (3.8.2) |
| CHANGELOG heading | `## 3.8.2 — unreleased` | `plugins/kenspc/CHANGELOG.md` |
| Unchanged | the statistics-line template; `Plan not written: awaiting approval.`; `### Task N: Doc-sync`; `guards run: 10`, `self-tests run: 9` | as today |

## Implementation Steps

Phases 1, 2, and 3 are independent of one another, except that Step 2.2
follows Step 2.1 (it renders the line 2.1 defines) and Steps 1.2 and 2.2
edit different sections of `task-implement/SKILL.md`. Phase 4 comes last.

### Phase 1: Render the review once (E-1)

**Step 1.1: `task-review/SKILL.md`, Steps 4–7**

- File: `plugins/kenspc/skills/task-review/SKILL.md`, Steps 4, 5, 6, and 7
  outside the `canonical:stats-line` and `canonical:verdict-shared` blocks
  (rulings M1, M3, D1–D4). Steps 1–3, the delivery check after the dispatch
  block, and every canonical block are unchanged.
- Step 4 (heading "Aggregate review findings"), in substance: add the five
  replies' Findings tables into the Schema A roll-up — HIGH, MEDIUM, and LOW
  per angle and in total — and print only the line
  `Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`,
  in English whatever the conversation language. The roll-up table is
  rendered once, in the Schema F report. Why: everything the orchestrator
  prints stays in its context for the rest of the run, and the agents'
  replies are already there as their results, so a table printed between
  dispatches is paid for again when the final report prints it; the user
  following the run needs to know which agent returned, its counts, and
  where its report is, and the fixed form, opening with the agent's name,
  lets the release checklist find the line.
- Step 5: "Render that reply verbatim; the LOW rows and their prose stay in
  the file." becomes: the Schema F report renders that reply verbatim, and
  the LOW rows and their prose stay in the file; when code-fixer returns,
  print only `code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`,
  the counts taken from its statistics line. The description of the reply's
  contents and the uncommitted paragraph stay.
- Step 6: "Render its Schema C result table verbatim:" and its example table
  and the Detail sentence are replaced (D3), in substance: it returns
  Schema C — the five-check table, a Detail paragraph for each non-PASS row,
  and a closing CLEAN or HAS ISSUES line; the Schema F report renders it
  verbatim; when it returns, print only
  `regression-verifier returned — CLEAN`, or
  `regression-verifier returned — HAS ISSUES: row <k> <result>, …` naming
  each non-PASS row. The list of what it verifies stays.
- Step 7: the lead-in says Schema F is the one place the roll-up,
  code-fixer's reply, and Schema C are rendered. Review summary: the
  per-angle roll-up table, moved from Step 4 (M3). Fixes: unchanged (M1).
  Verification: "Schema C verbatim: the table and the Detail prose for each
  non-PASS row." Verdict determination and the Next steps paragraph are
  unchanged here (Step 2.2 adds one bullet).
- Same commit (M9): CLAUDE.md § Subagent Review Architecture, after the
  Parallel MapReduce list or at "the main session relays paths rather than
  report text" — one sentence: between the dispatches the orchestrating
  skill prints one progress line per step, and the Schema A roll-up,
  code-fixer's reply, and Schema C are rendered once, in Schema F or G.
- Done when: Steps 4–6 print only their lines and carry no table template;
  Schema F's Review summary holds the per-angle template; the three lines are
  spelled as in Fixed strings; the four canonical blocks are byte-identical
  to `6575540` (Testing Strategy, mechanical 3); the pointer-label grep
  prints nothing on the file; `bash scripts/check-all.sh` passes.
- Why: E-1 — the same tables appeared twice in one run.

**Step 1.2: `task-implement/SKILL.md`, Phase 2 Steps 3–4**

- File: `plugins/kenspc/skills/task-implement/SKILL.md`, Phase 2 Step 3 and
  Schema G's Code Review, Fixes, and Verification placeholders (rulings M1,
  M2, D1–D4). Phase 1 (Step 5's Schema D render included, M2), Steps 1–2,
  and every canonical block are unchanged.
- Step 3, in substance: aggregate the roll-up and print only
  `Reviewers returned — …`; the Schema G report's Code Review section
  renders the table. "Render that reply verbatim" becomes: Schema G's Fixes
  section renders the reply verbatim; when code-fixer returns, print only
  `code-fixer returned — …`. "Render Schema C verbatim." becomes: Schema G's
  Verification section renders it verbatim; when regression-verifier
  returns, print only `regression-verifier returned — …`. The lines are
  spelled in full as in Fixed strings, the same as in Step 1.1. The same Why
  as Step 1.1, in this skill's words.
- Schema G: "(Schema A roll-up.)" becomes "(Schema A roll-up — the per-angle
  table, HIGH / MEDIUM / LOW per angle and in total; rendered here only.)";
  the Fixes and Verification placeholders say "rendered here only".
- Done when: as Step 1.1, for this file; the three lines match Step 1.1's
  character for character.
- Why: E-1, the same in the unattended entry point.

### Phase 2: Doc-sync documents travel with the fix (E-2)

**Step 2.1: `code-fixer.md`**

- File: `plugins/kenspc/agents/code-fixer.md`, outside the
  `canonical:principle:*`, `canonical:stats-line`, and `example:schema-b`
  blocks (rulings M5, M6, M7, D6–D11). The frontmatter, PREREQUISITE CHECK,
  CONTEXT YOU WILL RECEIVE, and the uncommitted-run rules are unchanged.
- PREREQUISITES item 2, in substance: with REVIEW_SCOPE "task", read the
  task document for context, and find its Doc-sync task — the section under
  the heading `### Task N: Doc-sync`, up to the next `### ` heading. Note its
  `**Status:**` value and its documents: the path in backticks that opens
  each bullet of its document list (M7). When the status is DONE, those
  documents are in the fix scope as FIXING RULES says; otherwise, and in a
  "changes" run, no document enters it this way.
- FIXING RULES, a new bullet, in substance (D9, D10, D11, M6): in a "task"
  run whose Doc-sync task is DONE, after each fix, read the parts of each
  listed document that describe the changed code — the sections naming the
  changed function, option, command, message, or file. A sentence, list
  item, or table row there that states the behavior the fix changed is now
  false: correct it, in the document's own language, in the fix's own
  commit, whose body names the document (`Updates <path> to match the
  fix.`). Change nothing else: no new section or paragraph, no text the fix
  did not make false, no behavior the document never described, no document
  outside the list; a listed path with no file is skipped. When the
  correction needs more than that, or the document has uncommitted changes —
  the previous rule then applies to the document, which is left untouched,
  while the code fix still lands — record the document as not updated, with
  the reason. Passing: every statement in a listed document that a fix made
  false is corrected in that fix's commit, and the document is otherwise
  unchanged. Named failure modes: a statement the fix contradicts left as
  it was; a correction in a commit of its own; a sentence reworded that the
  fix did not make false; a section or paragraph added; a document outside
  the list touched. Why: the Doc-sync task described the code as it stood
  before the review's fixes, so a fix that changes documented behavior makes
  that document wrong at once; in the fix's own commit the correction
  travels with the change it describes, where a note to the user afterwards
  only moves the gap to the user. The limits keep the edit as surgical as
  the fix: a fix commit that rewrites a document hides the fix, and a
  sentence the fix did not make false is not the fix's to change.
- PER-ISSUE OUTPUT CONTRACT, `action`: a FIXED action that corrected a
  listed document names it after an em-dash, `FIXED — updated <path>`; one
  that left a listed document stale says so,
  `FIXED — not updated <path>: <reason>`; several are joined by `; `. The
  leading word still classifies the action (D6).
- OUTPUT FORMAT, the reply list: after the statistics line (and after the
  uncommitted line, which cannot occur in a "task" run), in a "task" run
  whose Doc-sync task is DONE, one line
  `Doc-sync documents: updated <path> (row <n>, <commit>)[; …][; not updated <path> (row <n>) — <reason>]`,
  or `Doc-sync documents: none affected by the fixes` — always present in
  such a run, FIXED 0 included; not written to `schema-b.md`, whose last line
  stays the statistics line (D8). Why: the orchestrator reads only this
  reply, which carries no LOW row, and builds Next steps from this line; a
  line that is always present tells a run that checked from one that did
  not.
- DONE CRITERIA gains: in a "task" run whose Doc-sync task is DONE, every
  FIXED row that corrected a listed document, or left one stale, says so in
  its Action cell; each correction is in that row's commit; the reply
  carries the `Doc-sync documents:` line.
- Done when: the four edits are present with their Whys, spelled as in
  Fixed strings; `bash scripts/check-run-contract.sh`,
  `check-code-craft-canonical.sh`, and `check-all.sh --self-test` pass
  unchanged; the canonical and example blocks are byte-identical to
  `6575540`; the pointer-label grep prints nothing on the file.
- Why: E-2 — code-fixer is the agent whose commits make the documents stale,
  and the only one that knows which behavior each fix changed.

**Step 2.2: The final reports' Doc-sync bullet**

- Files: `plugins/kenspc/skills/task-implement/SKILL.md`, Schema G's Next
  steps; `plugins/kenspc/skills/task-review/SKILL.md`, the Next steps
  paragraph after Verdict determination (rulings M4, D12). Depends on Step
  2.1.
- task-implement: the re-check sentence (lines 434–438) is replaced, in
  substance: when the task document's Doc-sync task is DONE and code-fixer's
  statistics line reports FIXED greater than 0, one bullet carries
  code-fixer's `Doc-sync documents:` line — each document the fix commits
  updated, with its row and commit, and each left not updated, with its
  reason, for the user to correct; when the line says
  `none affected by the fixes`, the bullet reads
  `No Doc-sync document describes behavior the fixes changed.`; when the
  reply has no such line, the bullet states the defect —
  `code-fixer's reply has no Doc-sync documents line` — and names the listed
  documents to check against the fix commits, without the word "re-check"
  (ruling D12). Why: the fixes land after the Doc-sync task and code-fixer
  corrects the listed documents in the fix commits; this bullet is where the
  user sees which ones changed, or that none needed to, and a missing line
  means code-fixer did not meet its contract, so the correction may not have
  run. The BLOCKED bullet is unchanged.
- task-review: one sentence in the Next steps paragraph — when code-fixer's
  reply carries a `Doc-sync documents:` line and FIXED is greater than 0, one
  bullet as above, without the fallback.
- Same commit (M9): CLAUDE.md § Subagent Review Architecture, the
  documentation path paragraph — one sentence: when a review runs against a
  task document whose Doc-sync task is DONE, code-fixer corrects, in the
  fix's own commit, the sentences of the listed documents a fix makes false,
  and the final report names each document it changed.
- Done when: `grep -n 're-check' plugins/kenspc/skills/task-implement/SKILL.md`
  prints nothing; both bullets use the Fixed strings; the pointer-label grep
  prints nothing on either file; `check-canonical-dispatch.sh`,
  `check-verdict-shared.sh`, and `check-run-contract.sh` pass.
- Why: E-2 — the bullet reports what was done instead of handing the work
  back.

### Phase 3: The approved plan written verbatim (E-5)

**Step 3.1: generate-plan Phase 2 Step 3, "On approval"**

- File: `plugins/kenspc/skills/generate-plan/SKILL.md`, Phase 2 Step 3 only
  (rulings M10, M13, D15). `effort: xhigh`, Phase 1, Steps 1–2, the approval
  stop's cannot-ask paragraph, item 1, and Phase 3 are unchanged.
- Under "On approval:", before item 1, in substance: the approval covers the
  draft last printed in full — every section, none elided or summarized —
  and the file is that draft, character for character: no rewording, a
  pronoun included, no reformatting, and no change to escapes or special
  characters (an escape stays the characters that spell it). A change after
  that print — one the self-challenge finds, one shown only as a revised
  section, or one the approving reply itself asks for — is made to the
  draft, which is printed again in full and approved again before anything
  is written. In a session that cannot ask (a system reminder to work
  without stopping), that print ends with `Plan not written: awaiting
  approval.` and the run stops again, and an approval given on resume
  writes the draft that run's last message printed. Why: the written plan
  is the approved plan — Phase 3's reviewer commits it unchanged before its
  first fix, and generate-task decomposes it — so an edit made after
  approval, however small, reaches the repository as approved when the user
  never saw it. A plan written after an approval has differed from the draft
  approved in the same session in seven of 355 lines: pronouns reworded, a
  Documentation impact line reformatted, and an escape written as the
  character it stands for.
- Item 2 (M10): the document language is the draft's, set by Step 1's
  writing rules when it was drafted; a request for another language at
  approval is a change, handled as above.
- Item 3: "Write the plan to the file: the approved draft, as printed."
- Done when: the sentences are present with their Why, the phrase
  `character for character` as in Fixed strings, the cannot-ask sentence
  opening with the shared wording; `git diff -U0 6575540 -- plugins/kenspc/skills/generate-plan/SKILL.md`
  shows hunks only between `### Step 3: Write to file` and
  `## Phase 3: Verify via review agent`; the pointer-label grep prints
  nothing on the file; `check-no-model-names.sh` exits 0.
- Why: E-5 — the approved draft and the written plan differed.

### Phase 4: Documentation

**Step 4.1: Repository CLAUDE.md**

- File: `CLAUDE.md` (repository root) (M9). The two sentences are made in
  the commits of Steps 1.1 and 2.2. This step makes no further edit unless
  the read-through finds a sentence those two missed; such a sentence is
  fixed here and named in the commit message. Guard counts are unchanged.
- Done when: § Subagent Review Architecture says where the reports are
  rendered and what code-fixer does with the Doc-sync documents, and the file
  reads top to bottom without a contradiction about either.
- Why: CLAUDE.md is the loaded contract for every session in this
  repository.

**Step 4.2: The plugin README**

- File: `plugins/kenspc/README.md` (rulings D13, D17).
- § Run directory, first bullet (E-1): between the agents the run prints one
  progress line per step, and the roll-up, code-fixer's reply, and the
  verification table appear once, in the final report.
- § Recommended Workflow, Documentation path, the last sentence replaced
  (E-2), in substance: when the review's fixes change behavior a listed
  document describes, code-fixer corrects that document's sentence in the
  fix's own commit and changes nothing else in it; the final report names
  each document the fixes changed, one left not updated with the reason, or
  says none was affected.
- § Skills, `generate-plan` row (E-5): the plan written on approval is the
  draft as last printed in full, character for character; a change asked for
  at approval gets the full draft printed again, to approve.
- § Known behavior, a new item before "Red interval after a diagnosis"
  (E-4, D13), in substance:
  **Regressions and deferred issues in the verdict.**
  The verdict is FAIL when the fixes "introduced unresolved
  regressions", whatever a regression's severity, while "MEDIUM and LOW
  issues do not change the verdict but appear in the report." The asymmetry
  is deliberate: a regression is damage this run did to code that worked
  before it, which the run's own changes caused and a revert of those
  changes undoes; a deferred issue was in the code before the run, is
  reported with its reason, and is yours to schedule. The verdict is not
  graded by severity.
- Done when: the four sentences or items are present, the item's title as in
  Fixed strings, and every sentence about the changed behavior agrees with
  the skill and agent text.
- Why: the README is the installed user's only description of what these
  runs do.

**Step 4.3: CHANGELOG**

- File: `plugins/kenspc/CHANGELOG.md` (ruling D16): a
  `## 3.8.2 — unreleased` entry above 3.8.1.
  - Intro: batch E; what changes, in one paragraph; no new command, skill,
    agent, or CONTEXT key, so a patch; guard counts unchanged; E-3's one
    sentence: the roadmap's
    transcript-audit item leaves with no change — no such script is kept in
    this repository (`scripts/` holds only the `check-*.sh` guards) and since
    3.6.0 the acceptance records read the transcripts with `jq` directly
    (`docs/dry-runs/scratch-probes-acceptance.md`); the release smoke is the
    batch's acceptance record, named at release.
  - Changed: the review renders once (both skills; the three progress lines;
    Schema F's Review summary holds the per-angle table), with its source,
    the roll-up and replies printed twice in one run; code-fixer's Doc-sync
    documents (the scope, the limits, the Action suffix, the reply line, the
    report bullets in Schema G and F, the fallback), replacing the 3.6.0
    re-check bullet, with its source, the batch A review's B2; the plan
    written verbatim (the reprint on any change, the language, the
    cannot-ask reprint), with its source, the batch D acceptance's O3;
    release-checklist rows 4, 6, and 7; CLAUDE.md and the plugin README.
  - Known behavior (E-4): the verdict asymmetry, behavior unchanged; the
    README's new item says why.
  - The date is filled at release.
- Done when: the entry is present with the three parts; the E-3 sentence
  holds the phrase in Fixed strings; and every behavior the entry names
  matches the skill and agent text.
- Why: every change that ships is recorded under the next version's heading.

**Step 4.4: Release checklist**

- File: `docs/release-checklist.md` (ruling D19). Pre-flight counts stay
  `guards run: 10` and `self-tests run: 9`.
- Row 4 addition (E-5, ruling D14): the plan as first written — the Write
  call's `content` in the trace, and its blob in `plan-document-reviewer`'s
  first commit — against the draft that the last message before the
  approval printed in full. Both are normalized the same way and no further:
  CRLF is read as LF, and trailing newlines at the very end are dropped; a
  U+FEFF is a character, an escape is the characters that spell it, and
  trailing spaces on a line count. The draft taken from the transcript and
  the file differ in nothing (after the normalization above): the file's
  text occurs as one block of that message, the message's text outside the
  block holds no line of the plan, and a one-character edit to a copy of the
  file makes the comparison fail. A changed pronoun, a reformatted line, or
  an escape written as the character it stands for fails it. An approving
  reply that asks for a change gets the full revised draft again, with no
  Write in that invocation, and the file is then that draft.
- The E-1 criterion, written into rows 6 and 7 (ruling D5, with D1's line
  openings): in the session's assistant content, in order, after the five
  reviewer Agent calls return, a line opening `Reviewers returned — ` comes
  before the code-fixer call; after code-fixer returns, a line opening
  `code-fixer returned — ` comes before the regression-verifier call; after
  regression-verifier returns, a line opening
  `regression-verifier returned — ` comes before the final report; no text
  line begins with `|` from the first reviewer call until the final report's
  first heading; and across all the session's assistant text, the roll-up
  header (`| Angle | HIGH | MEDIUM | LOW |`), a line holding
  `total reported `, and the Schema C header (`| # | Check`) each occur
  exactly once, inside the final report.
- Row 6 (E-1, E-2): "then Schema A → B → C → G" becomes the E-1 criterion
  with Schema G as the final report; the re-check criterion is replaced: when the Doc-sync task
  is DONE and a fix changes behavior a listed document describes, that fix's
  commit also changes the sentence that described it and nothing else in the
  document, its Schema B Action reads `FIXED — updated <path>`, code-fixer's
  reply carries `Doc-sync documents: updated <path> (row <n>, <commit>)`, and
  Next steps has one bullet naming that document and row; with FIXED greater
  than 0 and no listed document affected, no fix commit touches a listed
  document and the bullet reads
  `No Doc-sync document describes behavior the fixes changed.`; the final
  report asks nobody to re-check the documents.
- Row 7 (E-1, E-2): "then the Schema A roll-up, B, C, and the Schema F final
  report" becomes the E-1 criterion with Schema F as the final report; with
  no task document,
  code-fixer's reply has no `Doc-sync documents:` line and no Action cell
  carries the document suffix.
- Done when: the additions are present and the pre-flight counts are
  unchanged.
- Why: the checklist is the only check that exercises the live chain; the
  fixed strings are what it greps for.

### The release commit (E-6) — not a batch step

Recorded so the implementing session leaves these alone: in the release
commit, not before it, `plugins/kenspc/.claude-plugin/plugin.json` goes to
3.8.2; the CHANGELOG heading gets its date; roadmap items 1, 2, 3, and 5
leave `docs/roadmap.md`, and the rest are renumbered in order with their
text unchanged (4 → 1, 6 → 2, 7 → 3, 8 → 4, 9 → 5, 10 → 6, 11 → 7); the
heading stays `## Next minor (3.9.0)`; no tag. Why: the repository's
convention for planned versus shipped work — an item leaves the roadmap, and
the version moves, when the release ships.

## Documentation impact

Determined from this repository's CLAUDE.md, § Durable documents.

- `CLAUDE.md` § Subagent Review Architecture (the documentation path
  paragraph; the Parallel MapReduce list or the run-directory paragraph) —
  made in the commits of Steps 1.1 and 2.2 (M9), checked by Step 4.1.
- `plugins/kenspc/README.md` § Run directory (first bullet), § Recommended
  Workflow (Documentation path), § Skills (`generate-plan` row), § Known
  behavior (the new "Regressions and deferred issues in the verdict" item)
  — Step 4.2.
- `plugins/kenspc/CHANGELOG.md` — the 3.8.2 entry — Step 4.3.
- `docs/release-checklist.md` — rows 4, 6, and 7; pre-flight unchanged —
  Step 4.4.
- `docs/roadmap.md` — items 1, 2, 3, and 5 leave and the rest are
  renumbered in the release commit, not in this batch (E-6).
- `README.md` (root) — N/A for this document: no skill's summary row changes
  and no plugin is added.
- `docs/dry-runs/README.md` — N/A for this document: the label convention is
  untouched.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this
  document: the plan format is unchanged.
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: the task-document format is unchanged; code-fixer reads the
  Doc-sync task as generate-task writes it.

## Testing Strategy

- **Mechanical**, in the repository:
  1. The release-checklist pre-flight block — the effort-override diff
     (unchanged), `claude plugin validate --strict .` and `./plugins/kenspc`,
     and `bash scripts/check-all.sh --self-test` with `guards run: 10`,
     `self-tests run: 9`, and every line PASS.
  2. The pointer-label grep (Standing constraints) on the four plugin files.
  3. Byte-identity against the base: for each block — `canonical:run-dir`,
     `canonical:dispatch`, `canonical:stats-line`, `canonical:verdict-shared`
     in both SKILLs; `canonical:principle:simplicity-first`,
     `canonical:principle:surgical-changes`, `canonical:stats-line`, and
     `example:schema-b` in `code-fixer.md` — the lines between its start and
     end markers at `6575540` (`git show 6575540:<file>`) and at HEAD are
     identical (`diff` exits 0). The guards compare copies with each other,
     so an edit made to both copies at once passes them; this compares each
     with the base. Run it as a bash script file, not inline under zsh.
  4. The zero-diff command (Standing constraints) prints nothing; the
     generate-plan hunks lie within Phase 2 Step 3.
  5. Text: `grep -n 'Regressions and deferred issues in the verdict'
     plugins/kenspc/README.md` finds one line; the 3.8.2 entry holds
     ``read the transcripts with `jq` `` and its Known behavior bullet;
     `grep -n 're-check' plugins/kenspc/skills/task-implement/SKILL.md`
     prints nothing (positive control: the same grep at `6575540` finds
     line 436). E-4's rule sentences (ruling M12, must pass), each file read
     with its line breaks joined and its spaces squeezed
     (`tr '\n' ' ' < <file> | tr -s ' '`), because the regression clause is
     wrapped across lines in both skills and a line-by-line grep finds it in
     neither: `introduced unresolved regressions` occurs in
     `task-review/SKILL.md` and in `task-implement/SKILL.md`, and
     `MEDIUM and LOW issues do not change the verdict but appear in the report.`
     in `task-review/SKILL.md`; the README item quotes both. At `6575540`
     the second sentence is in task-review only — task-implement reaches the
     same outcome through its PASS rule — and E-4 leaves the verdict rules
     unchanged, so the check does not ask for it in task-implement (the spec
     note in M12's row).
- **Live chain, headless**, one process per invocation through
  `~/Projects/_smoke/_prompts/e-run.sh <tag> <cwd> <prompt-file> [resume-session-id]`
  (`claude -p … --plugin-dir <repo>/plugins/kenspc --permission-mode
  bypassPermissions --output-format json`), cwd the smoke project. A run
  that stops at a question is continued with the script's resume argument;
  every answer the driver gives is quoted in the record where it was given.
  A session that cannot ask is made with `APPEND_SP` (`--append-system-prompt
  "Work without stopping; do not ask clarifying questions."`), passed again
  on each resume of that session, and the record names every run that used
  it. Cost is each session's last `total_cost_usd`.
- **Reading the trace.** Session transcripts are
  `~/.claude/projects/<cwd with / replaced by ->/<session_id>.jsonl`, with
  subagents under `<session_id>/subagents/` (each `agent-<id>.jsonl` beside a
  meta file naming its `agentType`). From Claude Code 2.1.281 an Agent
  call's tool_result does not carry the agent's report, so an agent's reply
  is the last assistant text of its own subagent transcript. Useful queries:
  the ordered assistant content,
  `jq -c 'select(.type=="assistant") | .message.content[]? | if .type=="text" then {text} elif .type=="tool_use" then {tool:.name, agent:(.input.subagent_type // null)} else empty end' <session>.jsonl`;
  a subagent's reply,
  `jq -rs '[.[] | select(.type=="assistant") | .message.content[]? | select(.type=="text") | .text] | last' <agent>.jsonl`;
  a Write call's content,
  `jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Write") | .input.content' <session>.jsonl`.
  A transcript in a trace directory that the driver did not start (a
  user-level hook's session) is recorded as an observation and not costed.
- **Seed**: throwaway projects under `~/Projects/_smoke/batch-e-*`, a
  TypeScript project to the batch D record's Seed project row
  (`docs/dry-runs/batch-d-acceptance.md` § 1): `typescript@7.0.2` and
  `vitest@5.0.1` from the local npm cache with `npm install --offline`,
  tests of its own green, a `typecheck` script, no call to the npm registry,
  and a vitest config that sets a setup file or `globals` and keeps the
  default include (the run-directory check's condition). Added for this
  batch (D18):
  - `README.md` with a section describing one function's behavior, one
    sentence of which states a behavior the code has and its task's
    acceptance criterion contradicts (for example "An empty string parses to
    0." where Task 1's criterion says an empty string throws `RangeError`).
  - `docs/tasks/<name>.md`: Tasks 1–3 `**Status:** DONE`, each with an
    `**Implementation notes:**` block and its commit in the seed's history,
    Task 1 carrying that planted defect; `### Task 4: Doc-sync`,
    `**Status:** TODO`, `Depends on: Task 1-3`, written from generate-task's
    template and listing `README.md` § that section.
  - A second variant for case 3 whose planted defect is in behavior the
    README does not describe (for example an internal message text).
  - A third variant for case 7 (ruling M12): a last commit carrying a
    defect whose natural fix changes the contract of a function (for
    example returning `null` where it threw) that another module calls with
    no test covering that call.
  - For cases 4 and 5, a short brief under `docs/briefs/` whose
    `## Open Questions` body is `none`, left untracked, so the plan runs reach
    the approval stop without an exit question (a free-text `/kenspc-plan`
    in a session that cannot ask meets Phase 1's discussion, which has no
    cannot-ask branch).
  The source gate is recorded as in the batch D record § 1: the first
  `SKILL.md` read in each session is under the repository's
  `plugins/kenspc/skills/`, and `plugins/cache/kenspc-claude-plugin` occurs
  0 times in the trace directories.
- **Cases**, each with its PASS criterion:
  1. Rows 6 / 7, E-1 and E-2 out of scope — `/kenspc-task-review` with no
     task document, on a seed variant whose last commit carries a defect
     (`Mode: commits`) and whose tree also holds a task document with a DONE
     Doc-sync task listing `README.md` (so a rule applied outside its scope
     would show). PASS: `change-set.md` exists; the five reviewer Agent calls,
     then `kenspc:code-fixer`, then `kenspc:regression-verifier`; the three
     progress lines, each after its agent's return and before the next
     dispatch (or before the final report), spelled as in Fixed strings; no
     text line beginning with `|` from the first reviewer call to the final
     report's first heading; across the session's assistant text, the
     roll-up header, a line holding `total reported `, and the Schema C
     header each occur exactly once, inside Schema F; code-fixer's reply
     (its subagent transcript) has no `Doc-sync documents:` line; no Action
     cell in `schema-b.md` carries `— updated` or `— not updated`; no fix
     commit touches `README.md` unless its own row's File:Line names it.
  2. Rows 5 / 6, E-1 and E-2 — `/kenspc-task-implement docs/tasks/<name>.md`
     on the D18 seed; the batch confirmation answered "yes" by resume. PASS:
     the task document's Task 4 reads `**Status:** DONE` after the run; the
     Schema B row whose Source holds the planted defect's ID has an Action
     beginning `FIXED — updated README.md` and a commit `H`;
     `git show --name-only --format= H` lists the source file and
     `README.md`; `git show H -- README.md` changes only the line or lines
     stating the pre-fix behavior (the record quotes the hunk) and adds no
     line beginning with `#`; `H`'s body names `README.md`; no other fix
     commit touches `README.md` unless its own row says so; code-fixer's
     reply carries `Doc-sync documents: updated README.md (row <n>, H)`;
     Schema G's Next steps has one bullet naming `README.md` with that row;
     the final report holds no `re-check`; E-1's criteria from case 1 hold
     with Schema G;
     `bash scripts/check-run-contract.sh --file <RUN_DIR>/schema-b.md` exits
     0 from the repository. If a reviewer reports the README's drift as a
     finding of its own and the README changes under that row instead, the
     record says so (a first reading, for the main session).
  3. Counter-example — the same on the second variant. PASS: FIXED is
     greater than 0; no fix commit touches `README.md` (`git show
     --name-only` of each FIXED row's commit); the reply carries
     `Doc-sync documents: none affected by the fixes`; Next steps has the
     bullet `No Doc-sync document describes behavior the fixes changed.`;
     `README.md`'s sha256 after the Doc-sync task's commit equals its sha256
     at the end of the run.
  4. Row 4, E-5 interactive — `/kenspc-plan docs/briefs/<brief>.md`, no
     reminder; the driver answers the discussion, then approves with
     "Write it." PASS: under D14's rule, the Write call's `content` and the
     blob of the reviewer's first commit of the plan each equal the draft in
     the `result` of the invocation that ended at the approval stop; the
     record quotes the text of that message outside the matched block;
     positive control: a one-character edit to a copy of the file makes the
     comparison fail. The reviewer's later commits may change the file;
     only the first commit is compared.
  5. Row 4, E-5 cannot-ask — the same with the reminder, then
     `--resume <session id> "approved"`, the reminder passed again. PASS:
     the first invocation ends with the draft and `Plan not written: awaiting
     approval.` and no Write, Edit, or Agent call (the 3.8.1 criteria); the
     resumed invocation writes the plan, and the comparison of case 4 holds
     against the first invocation's `result`.
  6. Row 4, a change asked for at approval (E-5, D15) — optional, as the
     budget allows: on case 4's pattern, the approving reply also asks for
     one edit ("Approved, but rename Step 2 to 'Parse rows'."). PASS: that
     invocation makes no Write, Edit, or Agent call, and its `result` holds
     the complete revised draft with the edit; after "Write it.", the
     comparison of case 4 holds against that revised draft.
  7. E-4, live — attempted once (ruling M12): `/kenspc-task-review` with no
     task document on the third seed variant, built so that code-fixer's own
     build / test / lint run does not catch the regression — the planted
     defect's natural fix changes a function's contract that a caller with
     no test relies on. PASS when the regression survives to
     regression-verifier: the verdict is FAIL, and the Verdict paragraph
     names the regression (Schema C's row 5, or the row that caught it).
     When code-fixer catches and withdraws its own regression, or none
     arises, the case is recorded as not exercised, with the evidence (the
     fix row, its commit or its DEFERRED paragraph, and code-fixer's test
     run), and is not a FAIL. The text check in mechanical 5 must pass
     either way.
  8. Mechanical 1–5 above, and `grep -n 'read the transcripts with'
     plugins/kenspc/CHANGELOG.md` finds the E-3 sentence (M11: the roadmap's
     removal is checked with the release commit).
- **Budget**: set by the main session; an estimate is six required
  sessions (cases 1–5 and case 7's attempt) at about $21–26 — cases 2, 3,
  and 7 run the full review, 2 and 3 the implementer too, and cases 4 and 5
  the plan reviewer — and one optional (case 6) at about $3 more.
- **Independence**: the acceptance record separates what the plugin's runs
  produced — reports, commits, the plan, the trace — from what the driver
  built and typed (the seeds, the planted defects, the README sentences, the
  briefs, every answer), and quotes every answer where it was given.
- The acceptance runs in a separate session and is filed under
  `docs/dry-runs/` as `batch-e-acceptance.md`, with the labels PASS / FAIL /
  OBSERVATION / Not exercised and the sections of the batch D record (Setup,
  Cases, Findings, Observations, Not exercised, Summary). The acceptance
  session records the evidence and a first reading of each FAIL and does
  not classify it; the main session classifies — plugin defect, behavior
  deviation, or observation, as the batch D record's § 3 does — and fixes a
  plugin defect in a separate session, never in a run's project; the
  affected case is then re-run. Windows and WSL2 are not run; the record
  says so under Not exercised, with the "not updated" branch (a listed
  document with uncommitted changes, or a correction that needs a new
  section) unless a seed exercises it.
- Dogfood note: `/kenspc-task` on this spec generates the Doc-sync task from
  the Documentation impact above. For the documents Steps 4.1–4.4 edit, the
  generated entries say "edited by Task <K>: verify it against the
  implementation instead of editing it again", as the template provides.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| The orchestrator still prints a table between dispatches, from habit or from a reply it reads | Medium | The steps carry no template (D3) and name the one line to print; rows 6 and 7 count the tables (D5). |
| The two skills' progress lines drift apart | Low | Fixed strings; rows 6 and 7 each check their skill's lines; no guard, since `scripts/` is out of scope (D4). |
| A reply drops out of the orchestrator's context (compaction) before the final report | Low | The roll-up is recomputable from `angle-<n>.md` and code-fixer's full Schema B is in `schema-b.md`; Schema C returns just before the report. |
| code-fixer rewrites more of a document than the fix made false | Medium | The limits and named failure modes in its rule; the Action suffix and the report bullet name every document it touched; the acceptance quotes the hunk. Nothing in the pipeline checks the document edit (regression-verifier has zero diff) — accepted, and a candidate for a later check. |
| code-fixer misses a sentence a fix made false, and reports `none affected` | Medium | The rule says where to read; the bullet is a claim the user can check against the named commit; case 2. |
| A reviewer reports the README's drift as its own finding, so the README changes in a commit of its own | Medium, in the seed | Recorded by the acceptance for the main session; the behavior is still correct when that row's own Action carries the suffix. |
| `### Task N: Doc-sync` renamed in generate-task, and code-fixer no longer finds the task | Low | Ruling M8 leaves the anchor guard as it is; the main session lists "add `code-fixer.md` to the `Doc-sync` group of `check-doc-sync-anchors.sh`" as a new roadmap entry in its report. The fallback bullet (D12) states the missing line and names the documents meanwhile. |
| Schema D still renders twice in `/kenspc-task-implement` (Phase 1 Step 5 and Schema G) | Certain | Out of scope (ruling M2); the main session lists it as a new roadmap entry in its report, with an acceptance of the Phase 1 → Phase 2 boundary as its condition. |
| The model regenerates the plan on write and drifts from the draft anyway | Medium | The rule names the kinds of drift seen, with its evidence; row 4's comparison (D14); the reviewer's first commit keeps the written file for comparison. |
| An approval that asks for a small change costs one more round | Certain, by design | The approval covers what the user saw (D15). |
| The comparison fails on text the harness changed rather than the model (line endings, a final newline) | Low | D14's normalization reads CRLF as LF and drops the final newlines; the record shows the differing lines, so a harness change is told from a model change. |
| E-4's live case cannot be forced | Medium | Ruling M12: the case is attempted once on a seed built to get past code-fixer's own test run; a regression code-fixer catches and withdraws is recorded as not exercised with the evidence; the text check must pass. |
| The E-4 text check reads a wrapped sentence line by line and finds nothing | Medium | Mechanical 5 joins each file's lines and squeezes spaces first; a line-by-line grep for the regression clause finds 0 in both skills at `6575540`. |

## Clarifications during implementation

Settled between the implementing session and the spec author (the main
session); each entry binds like the rulings above. Questions from the
implementing session arrive under a `## Questions for the spec author`
section appended to the end of this document (see Open Questions); each
answer is recorded here as `CL<n>` — a statement and the Step it affects —
and the answered question is removed from that section. The prefix is `CL`,
so a clarification cannot be read as one of the locked points E-1 to E-6 or
the architecture rows D1 to D19.

Rulings of 2026-09-26, after the `/kenspc-task` run over this document
(task document `547f41a`, review fix `e054aba`). CL1 and CL2 answer the two
plan-level concerns that run raised; neither changes a behavior. Both
decided by the main session within the locked design.

- CL1 — Step 2.1, FIXING RULES: the new Doc-sync bullet goes after the
  uncommitted-mode bullet, not between it and the `git status --porcelain`
  bullet, and it names the dirty-file rule by that name ("the
  `git status --porcelain` bullet") instead of "the previous rule". The
  `git status --porcelain` bullet and the uncommitted-mode bullet stay
  adjacent and unedited. Why: the `git status --porcelain` bullet ends with
  "the harm the next rule prevents", which points at the uncommitted-mode
  bullet by position; a bullet inserted between them would silently change
  what that phrase points at, and a reference by name survives any later
  insertion. Task 3 of the task document already reads this way.
- CL2 — Steps 1.1, 2.1, and 4.4: where a Step's text gives a shorter form
  of a string listed under [Fixed strings](#fixed-strings), the table's
  form governs. The three places: Step 1.1's
  `HAS ISSUES: row <k> <result>, …` is the table's
  `regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`;
  Step 2.1's `FIXED — updated <path>` is the table's
  `FIXED — updated <path>[, <path>]`; and release-checklist row 4 (Step
  4.4) carries the phrase `character for character`, as the table's Verbatim
  write row requires. Why: the table is the one place a string is spelled
  in full, and the task document already follows it; a Step's shorthand
  copied on its own would drop the optional parts the acceptance tests for.

Rulings of 2026-09-26, after the `/kenspc-task-implement` run over
`docs/tasks/batch-e-review-pipeline-tasks.md` (implementation
`254352d..2eab1ba`, review fixes `03e8b46..9ea9dfa`, regression-verifier
HAS ISSUES with row 5 FAIL at LOW, verdict FAIL). CL3–CL9 answer the seven
questions that run raised in `6669bca`, in their order. All decided by the
main session within the locked design; none reopens E-1 to E-6. CL4 adds two
fixed strings for a failure path the rulings did not name, within D1 and
D4's reason. That run's code-fixer carried no `Doc-sync documents:` line
although Task 10 was DONE, and neither its Action cells nor its commit
bodies show the new rule: it appears to have run the definition loaded when
the session started, so the rule of Step 2.1 is first exercised live by the
standalone re-review and the acceptance, not by that run.

- CL3 — Steps 2.1 and 4.3 (question 1): (a) yes — one `docs(changelog):`
  commit adds to the 3.8.2 entry what the five fix commits changed and the
  entry does not record: row 6's check of the fix commit's
  `Updates <path> to match the fix.` body line (`3fb055e`); row 6's
  forced-BLOCKED check that code-fixer leaves an unsynced Doc-sync task's
  documents alone (`851c287`); row 4's cannot-ask reprint after a requested
  change (`9ea9dfa`); and the two code-fixer rules of CL6 (`04a2397`,
  `63f48d7`); plus CL4's two lines. (b) D9 stands as written. Adding a
  record of a change to a changelog is new content, which E-2's limits (only
  the sentences the fix affects; no new section; nothing else changed) keep
  out of a fix commit; a statement the fix made incomplete but not false is
  the maintainer's to extend. A regression-verifier FAIL on such a document
  is the verdict rule working as E-4 keeps it, not a defect of the rule.
- CL4 — Steps 1.1, 1.2, and 2.2 (question 2): the missing-closing-line
  lines get a fixed form, the same in both skills and in English whatever
  the conversation language: `code-fixer returned — no statistics line` and
  `regression-verifier returned — no result line`. Each replaces the free
  wording that `a57347e` and `f7dbf5c` added; the Whys stay. The run goes
  on to the next step as it did before this batch, and the verdict follows
  the existing Verdict determination on what came back — no new verdict
  rule. In `task-implement/SKILL.md`, when code-fixer's reply has no
  statistics line and the Doc-sync task is DONE, the Doc-sync bullet is
  written as for FIXED greater than 0: from the `Doc-sync documents:` line
  when the reply carries one, otherwise in the missing-line form
  (`code-fixer's reply has no Doc-sync documents line`). Fixed strings gains
  the two lines, carried by both skills; release-checklist rows 6 and 7 add
  no case for them (the smoke exercises the normal path; the failure path
  is recorded as not exercised). Why: D1 and D4's reason — one fixed form
  per step is one thing a driving session can find — holds for the failure
  form too, and a missing statistics line must not silence the one bullet
  that exists to report a Doc-sync step that may not have run.
- CL5 — Step 2.1 (question 3): the Doc-sync section ends at the next `### `
  or `## ` heading, as `ac2d7f8` wrote it; M7's no-label lookup is
  unchanged. Why: the Doc-sync task is the last task, and a `## Notes`
  section follows it in `references/task-document-example.md` and in this
  batch's task document, so a `### `-only boundary would read the notes as
  part of the list. Task 3's text in the task document is history and stays.
- CL6 — Step 2.1 (question 4): both rules stand, within D9 and M6's intent:
  a withdrawn fix takes its document correction back with it (`04a2397`),
  and a document correction does not count toward the fix size that DEFERs
  a MEDIUM or LOW fix spanning more than one file (`63f48d7`). Why: E-2 puts
  the correction in the fix's own commit, so a correction left behind by a
  withdrawn fix describes a fix that did not land; and counting the listed
  document would make every documented fix a multi-file fix and DEFER it,
  which defeats E-2.
- CL7 — Step 4.4 (question 5): none of the three joins the release
  checklist in this batch; each costs a seeded headless run at every
  release, which is the maintainer's call. All three are listed as roadmap
  candidates in the main session's report and, as the maintainer decides,
  in the release commit. The acceptance exercises T1 once — a
  `/kenspc-task-review <task-path>` run on a fresh copy of the Doc-sync seed,
  checking Schema F's bullet (M4) — since M4 has no other live evidence; T2
  (a listed document with uncommitted changes) and T7 (a translated
  `**Documents**` label) are recorded under Not exercised.
- CL8 — Steps 2.1 and 2.2 (question 6): the gap is accepted; no new reply
  form. Why: generate-task's template opens every Doc-sync entry with a
  backticked path, and task-document-reviewer checks the Doc-sync task
  against it, so an entry without one is a hand edit outside the chain;
  another fixed string for it widens every report's surface in a patch. It
  is listed as a roadmap candidate in the main session's report.
- CL9 — Step 4.2 (question 7): the three departures stand — "damage the
  review's own fixes did", "a deferred MEDIUM or LOW issue", and "On
  regressions the verdict is not graded by severity". Why: in
  `/kenspc-task-implement` the run itself wrote the reviewed code, so "this
  run" would count the implementation as damage; and a deferred HIGH does
  change the verdict, so an unqualified "deferred issue" and an unqualified
  "not graded by severity" would each be false. The 3.8.2 CHANGELOG's Known
  behavior bullet follows the README.

## Open Questions

None. The rulings in [Design decisions](#design-decisions) close every
question raised during design.

The implementing session's channel to the spec author (the main session):
if it finds a ruling contradicted by the code, or a question no ruling
answers, it stops and reports it as a plan-level issue rather than resolving
it locally. It appends the question under a
`## Questions for the spec author` section at the end of this document —
one numbered entry per question, each naming the Step it affects, what the
repository shows, and what this document says — commits nothing else, and
waits; in a headless run it also puts the questions in its last reply and
stops, and the main session continues it with `--resume`. The spec author
answers each under
[Clarifications during implementation](#clarifications-during-implementation)
as `CL<n>` — a statement and the Step it affects — and removes the answered
question from that section; the session continues from the updated
document.
