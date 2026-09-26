# Plan: Batch D — unattended stops, answered-entry checks, and three copy guards

Target: this repository (`kenspc` plugin), on top of v3.8.0 (`0128a2f`).
Release: 3.8.1 — no new command, skill, agent, or CONTEXT key, so a patch
release. This batch makes no version bump and no tag; its CHANGELOG entry
goes under a `## 3.8.1 — unreleased` heading.

**Status: ruled.** The design was locked as D-1 to D-7 (restated below) by
the main session and checked against the repository in a headless Claude
Code session on 2026-09-26. Every question that check raised was decided by
the main session within the locked design on 2026-09-26 and is recorded in
[Design decisions](#design-decisions). This document is the complete
specification: the implementing session needs nothing beyond this file and
the repository. A locked point is written with a hyphen (D-1); a row of the
architecture table without one (D1).

## Objective

1. Three stops that an unattended run gets wrong get a defined answer:
   - generate-plan's approval stop gets a branch for a session that cannot
     ask: the run ends at the draft, printed in full, with nothing written,
     reviewed, or committed, and a later reply that approves the draft
     continues it.
   - generate-plan counts an `answered` brief entry as settled input only
     when it holds `Answer:`; one without is asked about in the gap round,
     or carried into the plan as `open`.
   - The prototype skill asks before it touches a named entry whose status
     word it does not recognize, and gives one that already holds an answer
     the gate that asks whether to prototype it again; a session that cannot
     ask stops with the brief unchanged.
2. Three copies no guard holds today are guarded: the reviewer invariant
   sentence in the plugin README and CLAUDE.md, the Prototype line that the
   prototype skill copies from generate-brief, and the prototype skill's
   leftovers command, which the skill writes twice.
3. Known behavior says what a red reproduction test does to every later
   review run, and what the one-time `.gitignore` commit takes with it;
   diagnose-bug's interactive exit names the reproduction commit and how to
   back it out.

**In scope:** D-1 to D-7 of the locked design (below); the documentation the
change requires.

**Out of scope:** roadmap items 1, 2, 3, 4, 6, 7, 8, 9, 12, and 16 (numbered
as at `0128a2f`); any new skill, command, agent, or CONTEXT key; any edit
inside a byte-identity section — the canonical blocks (`canonical:run-dir`,
`canonical:dispatch`, `canonical:stats-line`, `canonical:verdict-shared`),
the code-craft canonical paragraphs, and the five reviewers' six shared
sections, with no exception in this batch; any diff to `agents/`, `shared/`,
`references/`, `hooks/`, `commands/`, `task-implement`, `task-review`,
`generate-task`, or `generate-brief`; any diff to `diagnose-bug/SKILL.md`
outside its `## Exit` section; any change to what the one-time `.gitignore`
commit does (D-6 documents it); any change to regression-verifier or
task-implementer (D-5 documents their behavior); generate-plan's question
points other than the approval stop and the existing-file question its
approved path reaches (ruling M8).

### The locked design (D-1 to D-7)

Restated for reference. The rulings below refine these points; they do not
reopen them. Where a ruling reads a point beyond its literal words, its row
says so and why the reading stays within the point's intent.

- **D-1 generate-plan's approval stop in a session that cannot ask**
  (roadmap item 15; the batch C acceptance's F1). In a session that cannot
  ask, the complete draft is printed in the reply, with a statement that
  approval has not been given and how to continue (re-run, or `--resume`
  with the approval); no file is written, `plan-document-reviewer` is not
  dispatched, and nothing is committed. The approval can come from the
  session driving it; that reply is the approval. Why: the plan is what
  carries the approval, so writing it is approving it; Phase 1's exit and
  gap-check already use the same "In a session that cannot ask" wording.
  Release-checklist row 4 gains this case.
- **D-2 `answered` entries in the gap round** (roadmap item 14). An
  `answered` entry — as the brief has it, or as the user marks it in the
  gap round — is settled input only when it holds `Answer:`. One without is
  quoted in the gap round, which asks for the answer; in a session that
  cannot ask it is carried into the plan's Open Questions in the `open`
  form, its `From:` saying `Answer: missing`. The batch C rule that only the
  status word is read still holds; this is a validity check on `answered`,
  not a new status word.
- **D-3 An unrecognized status word in the prototype skill** (roadmap item
  13). A named entry whose status word is not `open`, `needs prototype`, or
  `answered` — hand-edited, translated, or missing — is asked about; one
  that holds `Answer:` or `Prototype:` takes the existing `answered` gate
  (prototype it again?); a session that cannot ask stops and leaves the
  entry unchanged. The gates table, the README's gate list, and the
  CHANGELOG change in the same commit.
- **D-4 Three guard checks** (roadmap items 5, 10, 11): (a) the reviewer
  invariant sentence's copies in the README and CLAUDE.md, compared
  whitespace-normalized and exactly; (b) the Prototype line in
  generate-brief's writing rules and its copy in `prototype/SKILL.md`,
  compared literally; (c) the leftovers command's literal in
  `prototype/SKILL.md` occurs exactly twice. Existing guards
  (`check-run-contract.sh`, `check-doc-sync-anchors.sh`) are preferred, so
  `guards run: 10` and `self-tests run: 9` stay; if a new script is the
  cleaner home, the counts become 11 and 10, and every place in CLAUDE.md,
  the release checklist, and `check-all.sh`'s comment that states them
  changes in the same commit. Every new check has a self-test mutation that
  can fail.
- **D-5 The red interval's knock-on effect** (a batch B review item). The
  plugin README's Known behavior item "Red interval after a diagnosis" gains
  a paragraph: while the reproduction test is red, every later review run in
  the same repository records the test row FAIL and the verdict FAIL, and
  the mutation baseline cannot run either — regression-verifier has no
  notion of a pre-existing failure, and this is not a defect of it.
  diagnose-bug's Exit, when the user chooses to implement interactively,
  also gives the `git revert <hash>` reminder that today only "Ending
  without a document" gives. regression-verifier and task-implementer have
  zero diff.
- **D-6 The `.gitignore` chore commit** (a batch B review item). The one-time
  `.gitignore` commit of the `canonical:run-dir` block commits the whole
  file, so the user's uncommitted edits to `.gitignore` go into it. Written
  into README Known behavior and one CHANGELOG sentence; the behavior is not
  changed (the block is byte-locked).
- **D-7 Release.** No new command, so 3.8.1, a patch; the CHANGELOG entry
  under `## 3.8.1 — unreleased`; roadmap items 5, 10, 11, 13, 14, and 15
  leave in the release commit, which renumbers the rest and leaves the other
  items and the heading `## Next minor (3.9.0)` as they are; the version is
  bumped in the release commit only; no tag.

Where each point lands:

| Point | Steps | Rulings |
|---|---|---|
| D-1 | 1.1, 5.1, 5.2, 5.3, 5.4 | M4, M8, M10, M11, D1, D2, D3, D16 |
| D-2 | 1.2, 5.1, 5.2, 5.3, 5.4 | M5, M6, M10, M11, D4, D5, D16 |
| D-3 | 2.1 (with its README and CHANGELOG items), 5.4 | M1, D6, D7, D16 |
| D-4 | 4.1, 4.2, 5.1, 5.3 | M3, M9, M10, M13, D8, D9, D10, D11, D12 |
| D-5 | 3.1, 5.2, 5.3, 5.4 | M2, M7, D13, D16 |
| D-6 | 5.2, 5.3 | D14 |
| D-7 | 5.3; the release commit | D15 |

## Background

- **The approval stop in a session that cannot ask.** generate-plan's Phase
  2 Step 3 reads "Write only when the user explicitly approves the plan",
  and that stop has no "In a session that cannot ask …" sentence, where
  Phase 1's exit and gap-check do. In the batch C acceptance
  (`docs/dry-runs/batch-c-acceptance.md`, F1; run `c-acc-plan-cannot`,
  $4.17, the batch's costliest), a run given
  `--append-system-prompt "Work without stopping; do not ask clarifying
  questions."` said "The session can't stop for approval, so I'm writing
  the revised plan now", wrote `docs/plans/maybank-csv-import.md`,
  dispatched `plan-document-reviewer`, and committed four times on `main`.
  The main session classified it a behavior deviation and left the stop to
  a later batch; the 3.8.0 CHANGELOG says "The approval gate is unchanged:
  a session that cannot ask still writes the plan only on approval." — a
  statement about the text, which the run did not follow. Phase 3 already
  reads "Skip this phase entirely if the plan was not written to a file";
  `plan-document-reviewer` commits an untracked plan unchanged before its
  first fix commit, then one commit per angle that fixes something.
- **The approved path's next stop.** Step 3's item 1.c asks whether to
  overwrite when a plan already exists at the target path, with no
  cannot-ask branch. diagnose-bug's conflict check has one: create alongside
  with a numeric suffix (`<name>-2.md`) and say so in the final message.
- **`answered` without `Answer:`.** generate-plan's part 3 takes every
  `` `answered` `` entry as settled input, and the gap round lets the user
  give an unrecognized entry any status, `answered` included, so an entry
  can reach the plan as settled with no `Answer:` and no hash (roadmap item
  14, from the batch C fix-round review, B4). A well-formed unsettled
  attempt is `` `needs prototype` `` with `Evidence:` and `Prototype:` and no
  `Answer:` (generate-brief's writing rules), so an `answered` entry without
  `Answer:` is malformed whichever labels it has.
- **The prototype skill's entry selection.** A named `answered` entry gets
  the question "prototype it again?", and a session that cannot ask stops;
  a named `open` entry is prototyped like any other; nothing handles an
  entry whose word is none of the three. Such an entry — an `answered` one
  whose word was translated, say — skips the `answered` gate, and Phase 3
  replaces its `Answer:`, `Evidence:`, and `Prototype:` in a brief that has
  no committed copy (roadmap item 13, from the same review, E7). The
  README's list of what the skill asks about is one sentence of the
  `prototype` row in § Skills ("A location conflict, a connection your
  development configuration does not name, … are each asked about"); it
  does not name the `answered` gate either.
- **The three copies, as they stand at `0128a2f`.** No drift today; each
  check below was run against the tree:
  - The reviewer invariant sentence, "Each reviewer is read-only on the
    working tree and writes only under `RUN_DIR`: its report at
    `RUN_DIR/angle-<n>.md`, and probe and temporary files under
    `RUN_DIR/scratch/angle-<n>/`.", is in the five reviewers' ROLE (line
    37), the canonical dispatch block of `task-review/SKILL.md` (line 282)
    and `task-implement/SKILL.md` (line 344), `plugins/kenspc/README.md`
    (lines 83–85), and `CLAUDE.md` (lines 327–329, indented in a list item).
    Whitespace-normalized, each of those files contains the ROLE sentence
    exactly once. The root `README.md` has no copy; the 3.5.1 CHANGELOG
    quotes it as history.
  - The Prototype line,
    ``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` ``,
    occurs once in `generate-brief/SKILL.md` (line 257, a sub-bullet in the
    answered-entry example) and once in `prototype/SKILL.md` (line 384,
    wrapped in double backticks); byte-identical as a literal. CLAUDE.md's
    Non-Goals quotes it and says no guard checks it.
  - The leftovers command,
    `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`,
    occurs exactly twice in `prototype/SKILL.md` (lines 205 and 449, the
    start snapshot and the Exit), counted by occurrence; the plugin README,
    the 3.8.0 CHANGELOG, and release-checklist row 10 quote it.
- **The guards.** `check-all.sh` runs every `scripts/check-*.sh` and counts
  them; its comment states no number. `check-run-contract.sh` holds five
  checks; its self-test runs fourteen mutations that must exit 1 — eight
  named ones, the change-set name in each of four files, and the pre-fix
  index in each of two — where its header says "eleven" (ruling M13);
  `check-doc-sync-anchors.sh`
  asserts that each label is present at least once in every file of its
  group, over four anchors in eleven files, and its self-test mutates one
  label. The release checklist and CLAUDE.md pin `guards run: 10` and
  `self-tests run: 9`. Guards run under the bash 3.2 macOS ships.
- **What a red reproduction test does to a review run.** diagnose-bug
  commits its reproduction test before the fix exists (the README's "Red
  interval after a diagnosis"). regression-verifier's check 3 runs the
  project's build, test, and lint commands as the project configures them,
  "with no path filter or exclude added", and records failed tests as FAIL;
  the shared verdict block says such a row-3 FAIL "forces a FAIL verdict".
  Its mutation rule, the same in the reviewers' ROLE, needs the unmutated
  copy to pass first, "for example by extending the project's config and
  replacing only its file selection"; when it cannot be made to pass, the
  check is reported as not made (regression-verifier: "not
  mutation-checked"). diagnose-bug's "Ending without a document" names the
  reproduction commit and offers `git revert <hash>`; its Exit's
  "interactively" bullet says only "stop. The task document stands".
- **The one-time `.gitignore` commit.** The `canonical:run-dir` block's
  exit-1 branch runs `git -C <root> add .gitignore` and
  `git -C <root> commit -m "<message>" -- .gitignore`: the whole working
  file is staged and committed, so any edit to `.gitignore` the user had not
  committed, staged or not, goes into `chore: ignore kenspc run directory`.
  The batch B spec's ruling M19 noted it as 3.5.x behavior outside that
  batch. The block runs in `/kenspc-task-review`, `/kenspc-task-implement`'s
  review phase, and `/kenspc-diagnose` when it probes.
- **An untracked brief.** generate-brief leaves its brief uncommitted and
  the prototype skill does not commit it, so `git diff` prints nothing for a
  brief whatever a run did to it (ruling M12).

## Design decisions

Questions found while checking D-1 to D-7 against the repository. Each row
gives the options considered, the lean the draft proposed with its reason,
and the ruling. Every ruling was decided by the main session within the
locked design on 2026-09-26; it binds this batch, and the implementing
session applies it without reopening it. No ruling departs from the draft's
lean, and the Implementation Steps follow the rulings.

Five rulings read a locked point beyond its literal words, and each row
says why the reading stays within that point's intent: M1 reads D-3 by its
reason — an earlier answer is not replaced unasked — so an entry that holds
`Answer:` takes the `answered` gate whatever its status word; M4 gives a
cannot-ask branch to the existing-file question, the next stop on D-1's own
approved path; M11 adds README sentences beyond the ones the lock names, in
a file on this batch's allowed list; D9 has check 6 read the canonical
dispatch block's copy, past D-4(a)'s README and CLAUDE.md, without editing
it; D13's half-sentence on review runs goes past D-5's words for the Exit
and agrees with D-5's README paragraph. Two more are marked for what they
are: M2 refines D-5's wording, and M13 corrects a pre-existing inaccuracy in
a file this batch edits, adding no behavior. M7 and M8 leave two gaps out of
scope: they are recorded under [Risks](#risks-and-mitigations), and the main
session lists them as roadmap candidates in its report to the user, who
decides; this batch changes no roadmap item beyond the six D-7 names.

### Mismatches between the locked design and the repository (M1–M13)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| M1 | D-3 covers a named entry whose status word is not recognized. The row-10 acceptance case the main session planned names an entry whose word is recognized — `open` — but that holds `Answer:` and `Prototype:`, and expects the `answered` gate. Under D-3's words that entry is a named `open` entry, "prototyped like any other", and Phase 3 replaces its `Answer:` and `Prototype:`: the loss roadmap item 13 describes, reached through a recognized word. | (a) Widen the `answered` gate by content: a named entry that holds `Answer:`, whatever its status word, takes it; an unrecognized word that holds `Prototype:` takes it too (D-3); `Prototype:` without `Answer:` under `needs prototype` stays the unsettled form a later attempt replaces, as today. (b) D-3 as worded; the acceptance entry's word becomes an unrecognized one. | (a), flagged as reading D-3 by its reason — an earlier answer is not replaced unasked — rather than by its trigger alone. `Answer:` is what Phase 3 would overwrite, whoever wrote it. `Prototype:` alone cannot trigger the gate under a recognized word, because an unsettled attempt legitimately leaves `needs prototype`, `Evidence:`, and `Prototype:`, and the skill re-attempts such an entry by design. It reads a label, not a new status word, so the rule that only the status word decides what is unresolved is untouched. | **(a)**, beyond D-3's literal words and within its intent — decided by the main session within the locked design. D-3 is read by its reason: an earlier answer is not replaced unasked. A named entry that holds `Answer:` takes the `answered` gate whatever its status word; an unrecognized word that holds `Prototype:` takes it too; `needs prototype` with `Prototype:` and no `Answer:` stays the unsettled form and is prototyped again as today. The acceptance case this batch plans — `open` with `Answer:` and `Prototype:` — expects that gate, and (a) agrees with it. Step 2.1; Testing Strategy case 6. |
| M2 | D-5 says the mutation baseline cannot run while the reproduction test is red. The mutation rule leaves the copy's file selection to the agent ("for example by extending the project's config and replacing only its file selection"), so a copy that leaves the reproduction test out can pass its baseline. | (a) The README states the condition: a mutation check whose copy runs the reproduction test cannot make its unmutated copy pass, so it is reported as not made. (b) The unconditional sentence. | (a). The unconditional form is false for a narrowly selected copy, and a Known behavior item that overstates reads as a promise the next run breaks. | **(a)**, refining D-5's wording — decided by the main session within the locked design. The mutation rule leaves the copy's test selection to the agent, so the baseline fails only when the copy runs the reproduction test; an unconditional sentence would be contradicted by the next run. Step 5.2. |
| M3 | D-4(a) compares the README and CLAUDE.md copies but does not say against what. The two guarded copies are guarded only within their own family: `check-review-agent-drift.sh` keeps the five ROLE sections identical and `check-canonical-dispatch.sh` the two dispatch blocks; no guard ties one family to the other. | (a) The reference is the ROLE sentence, extracted from `requirements-reviewer.md` at run time; the README and CLAUDE.md must each contain it, whitespace-normalized. (b) The README and CLAUDE.md compared with each other only. (c) The sentence held as a literal in the guard. | (a). (b) passes when both copies drift together away from the agents, and the agents are what runs; (c) adds a fifth copy to keep in step. With an extracted reference, rewording the ROLE sentence fails the guard in every copy not yet updated, which is the point. Whether the dispatch block's copy joins is D9. | **(a)** — decided by the main session within the locked design. The reference is extracted from `requirements-reviewer.md`'s ROLE at run time: the agents' text is what runs, (b) misses both copies drifting together, and (c) adds one more copy to keep in step. Step 4.1. |
| M4 | D-1 branches the approval stop, but the approved path then reaches Step 3's item 1.c — "If a file already exists at the target path, ask the user whether to overwrite or create a new file" — which has no branch. In a headless run the approval arrives by resuming a session that still carries the reminder, so this is the next stop D-1's path meets. | (a) diagnose-bug's branch: create the file alongside with a numeric suffix (`<name>-2.md`) and say so in the final message. (b) Overwrite. (c) Leave it unbranched. | (a), flagged as going past D-1's words to the stop D-1's own path leads to. diagnose-bug's conflict check is the precedent; an overwrite nobody chose can destroy a plan the user kept. | **(a)**, beyond D-1's literal words and within its intent — decided by the main session within the locked design. The existing-file question is the next stop on D-1's own approved path, and one cannot-ask sentence (`<name>-2.md`, named in the final message) opens no new surface. Step 1.1. |
| M5 | D-2's check has to be asked in the gap round (part 2 of Phase 1 Step 1), but the rule for `answered` entries sits in part 3, which comes after the gap-check. | (a) Part 2 lists an `answered` entry with no `Answer:` among its gaps, beside the unrecognized-word entries, with its cannot-ask branch; part 3 narrows to entries that hold `Answer:`. (b) Part 3 asks its own question after the gap round. | (a). One round, and the one-to-two-round limit unchanged; (b) adds a round after the gap-check has ended. | **(a)** — decided by the main session within the locked design. One gap round; the one-to-two-round limit is unchanged. Step 1.2. |
| M6 | D-2 makes `Answer:` the test for settled input; part 3 says a plan relying on an answered entry cites its prototype hash. An entry that holds `Answer:` and no `Prototype:` — an answer written by hand — is settled with no hash to cite, and an answer the user gives in the gap round has neither. | (a) Settled input either way: a plan relying on one cites the hash when the entry has a Prototype line, otherwise the entry (`<brief path>, entry <n>`); an answer given in the gap round is settled like any gap-round answer. (b) An entry with no `Prototype:` is not settled. | (a). D-2 names `Answer:` as the test; (b) adds a second test D-2 does not make and would ask again about answers the user wrote themselves. | **(a)** — decided by the main session within the locked design. D-2 makes `Answer:` the only test; (b) would add a test D-2 does not make. Step 1.2. |
| M7 | D-5 adds the `git revert` reminder to the interactive exit and leaves the other branches unchanged. Two other endings leave the same red commit unnamed: the cannot-ask exit (the `/kenspc-task-implement <path>` suggestion, then stop) and tier 3 (a brief for `/kenspc-plan`; the test stays red until a planned fix lands). | (a) As locked: the interactive exit only; the README paragraph covers every ending. (b) Also tier 3's closing message. (c) Also the cannot-ask exit. | (a). The cannot-ask exit's next step is the run that turns the test green; the tier-3 brief records the test's path and commit in Context; D-5 keeps the other branches unchanged. Both gaps are under Risks. | **(a)**, as locked — decided by the main session within the locked design. Only the interactive branch changes. The cannot-ask exit's and tier 3's gaps are recorded under Risks; the main session lists them as roadmap candidates in its report to the user, who decides whether they enter the roadmap; this batch changes no roadmap item beyond D-7's six. Step 3.1; Risks. |
| M8 | generate-plan has two more question points with no cannot-ask branch: no arguments ("ask the user what they want to plan") and Phase 1 Step 4's discussion when the input is not a brief. A cannot-ask `/kenspc-plan <free text>` meets the second before it reaches any draft. | (a) Out of scope; recorded under Risks, and a roadmap item only if the main session adds one in the release commit. (b) Out of scope and recorded as a roadmap item by this batch. (c) In scope: generate-brief's `rapid-inferred (reminder-driven)` pattern for the discussion. | (a). D-1 names the approval stop; (c) is a discovery-mode design needing rulings of its own; (b) changes the roadmap beyond the items D-7 lists. | **(a)** — decided by the main session within the locked design. Recorded under Risks; the main session raises it as a roadmap candidate in its report to the user, as for M7, and this batch changes no roadmap item beyond D-7's six. Risks. |
| M9 | D-4(c) asks for "exactly twice". `check-doc-sync-anchors.sh`, the home roadmap item 11 suggests, asserts presence only ("at least once in every file of its group"), which cannot see one of two copies changed while the other stays. | (a) Extend it with one exact-count check, counting occurrences of the literal (not lines) in `prototype/SKILL.md`; its header then says it holds anchor presence and one exact count. (b) A new guard. (c) `check-run-contract.sh`. | (a); the three homes together are D8. | **(a)** — decided by the main session within the locked design. See D8. Step 4.2. |
| M10 | Sentences D-4 and D-1 make false or incomplete: CLAUDE.md's Non-Goals, "`check-doc-sync-anchors.sh` guards only the `needs prototype` status word across the three files, not this line"; the header of `check-doc-sync-anchors.sh`, "README.md and CLAUDE.md are deliberately outside the guard: prose invariants there are tracked as a separate roadmap item"; CLAUDE.md's description of that guard ("the four planning-chain anchors", "One carries the open-question path"); the header of `check-run-contract.sh` ("Five checks"); CLAUDE.md's Maintenance note, which names the guard to run after editing each guarded file and names none for the README or CLAUDE.md; and CLAUDE.md's Writing Rules for Skill Content, which lists the question points that share the cannot-ask wording. | Mechanical update with the change. | Mechanical; no alternative considered. | **Mechanical update** — decided by the main session within the locked design, each sentence changed in the same commit as the change that makes it false. Steps 1.1, 1.2, 4.1, 4.2, 5.1. |
| M11 | The lock names the README for D-3's gate list, D-5, and D-6. D-1 and D-2 change what a user sees too — a cannot-ask plan run that ends at the draft, an answered entry asked about — and the Durable documents table says the plugin README changes with any user-visible behavior of a skill. | (a) One sentence each: D-1 in the `generate-plan` row of § Skills; D-2 in the Prototype path paragraph of § Recommended Workflow, beside a sentence for D-3. (b) Known behavior items. (c) The README only where the lock names it. | (a). Neither is a surprise to explain after the fact, which is what Known behavior is for; each is one clause of what the skill does. | **(a)**, README sentences beyond the ones the lock names, in a file on this batch's allowed list — decided by the main session within the locked design. The plugin README is the durable document for user-visible behavior; one sentence in each place, and no Known behavior item. Step 5.2. |
| M12 | The planned acceptance criterion "the brief's `git diff` is empty" cannot fail as worded: the brief is untracked (Background), so `git diff` prints nothing whatever the run did to it. | (a) Compare the brief's sha256 before and after the run, the batch C acceptance's method, with a positive control — a deliberate edit changes the hash. (b) The seed commits the brief, so `git diff` sees an edit. | (a); (b) is acceptable where a case needs the brief tracked. A check that cannot fail is indistinguishable from one that passes. | **(a)** — decided by the main session within the locked design. The brief's sha256 before and after the run, with a positive control; the planned `git diff` criterion could not fail. The Testing Strategy's cases are written this way. Testing Strategy. |
| M13 | `check-run-contract.sh`'s header says its self-test runs "eleven mutations that must each exit 1"; the script runs fourteen (eight named, the change-set name in four files, the pre-fix index in two). Step 4.1 rewrites that paragraph to add check 6's mutations. | (a) The rewritten paragraph states the count the script runs, check 6's included, and this spec's CHANGELOG line says the old number was stale. (b) Leave the number and add check 6's to it. (c) Drop the number from the header. | (a). The paragraph is being edited anyway, and a count carried forward from a stale one is wrong twice; (c) loses the one place a reader learns how many negative paths the fixture has. Flagged as a pre-existing inaccuracy found in a file this batch edits, not a new behavior. | **(a)**, an incidental correction of a pre-existing inaccuracy, not new behavior — decided by the main session within the locked design. The paragraph is edited in this batch anyway; it states the number the script runs, and the CHANGELOG says the old number was wrong. Steps 4.1, 5.3. |

### Architecture choices (D1–D16)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| D1 | The form of the draft a cannot-ask run ends with (D-1), including a long draft. | (a) The run's last message holds the complete draft — every section of the draft after self-challenge, none elided or summarized — then the not-approved line and how to go on. (b) The draft in whichever messages drafting produced, the last message holding only the note. (c) A summary, with the full draft on request. | (a). A headless driver reads the run's last message (`result` in `--output-format json`); a draft in an earlier message reaches it only through the transcript, and a summary is not the plan that would be approved. The plan written after approval is the printed draft, so the length is paid once either way. | **(a)** — decided by the main session within the locked design. A headless driver reads the run's last message. Step 1.1. |
| D2 | How the exit tells the driver that the plan was not written and how to go on (D-1). | (a) A fixed English line after the draft, `Plan not written: awaiting approval.`, then, in the conversation language: reply in this session approving the draft or asking for changes — a headless run resumes it with `claude -p --resume <session id> "<reply>"` — or run `/kenspc-plan` again in a session that can ask. (b) Free wording. | (a). One fixed line is one thing a driving session and the release checklist can test for; task-implement's transition lines stay in English for the same reason. | **(a)** — decided by the main session within the locked design. One fixed English line, which a driving session and the release checklist can both test for. Steps 1.1, 5.4. |
| D3 | Whether a cannot-ask run still runs Phase 2's self-challenge (D-1). | (a) Yes: the printed draft is the revised draft; Step 2 already keeps it in the conversation. (b) Print the first draft. | (a). The self-challenge asks the user nothing, and skipping it would make the draft an unattended run offers weaker than an interactive one. | **(a)** — decided by the main session within the locked design. The self-challenge asks the user nothing, so it runs. Step 1.1. |
| D4 | The carried form of an `answered` entry with no `Answer:` (D-2). | (a) The `open` form, with `From: <brief path>, entry <n>, status word answered, Answer: missing`, the same whether the session could not ask or the gap round left it unsettled. (b) `From: <brief path>, entry <n>, Answer: missing`. (c) A status word of its own for the carried entry. | (a). It parallels the unrecognized-word form (`status word <the word, or none> not recognized`), names what the brief said and what is missing, and holds the literal `Answer: missing` D-2 asks for; (c) is the new status word D-2 rules out. | **(a)** — decided by the main session within the locked design. `From: <brief path>, entry <n>, status word answered, Answer: missing`: parallel to the unrecognized-word form, and holding the literal `Answer: missing` D-2 asks for. Steps 1.2, 5.4. |
| D5 | The gap round's question for an entry the user marks `answered` there when it holds no `Answer:` (D-2). | (a) The question that asks an unrecognized entry's status also asks, for `answered`, the answer: one question, one round. (b) A second question once the status is given. | (a). The one-to-two-round limit is the gap-check's contract. | **(a)** — decided by the main session within the locked design. One question, one round. Step 1.2. |
| D6 | The prototype skill's question for an unrecognized word with neither `Answer:` nor `Prototype:` (D-3). | (a) Two choices, quoting the word found (or saying there is none): prototype it, or stop. (b) Four: take it as `open`, as `needs prototype`, as `answered`, or stop — generate-plan's gap-round question. | (a). In this skill a named `open` entry and a named `needs prototype` entry take the same path, and an answered one is told by its labels (M1), so (b)'s extra choices reach the same two outcomes and ask the user to classify for a distinction the run does not use. | **(a)** — decided by the main session within the locked design. Two choices, prototype it or stop: in this skill a named `open` entry and a named `needs prototype` entry take the same path, so four choices reach no further outcome. Step 2.1. |
| D7 | Where the new gate sits relative to Phase 1's two writes — the entry appended for a question given as text, and a `Settled by:` derived for an entry that lacks one — so that a stop leaves the brief unchanged (D-3). | (a) The gates on the named entry come at question selection, before either write, and the rewrite for a run in which nothing was built does not apply to them — the wording the `answered` gate already has. (b) No change. | (a). A stop after a derived `Settled by:` was written has changed the brief it stopped to protect, and the brief is untracked, so no git command restores it. | **(a)** — decided by the main session within the locked design. The gates come before both writes to the brief; the brief is uncommitted, so a write there cannot be undone. Step 2.1. |
| D8 | The homes of the three checks (D-4). | (a) Existing guards: (a) as check 6 of `check-run-contract.sh`; (b) as a fifth anchor group of `check-doc-sync-anchors.sh`; (c) as one exact-count check in `check-doc-sync-anchors.sh`. `guards run: 10` and `self-tests run: 9` stay. (b) One new guard, `check-copied-lines.sh`, for all three: counts 11 and 10, updated in CLAUDE.md (§ Repository scripts/, the paragraph that lists the guards with a fixture) and the release checklist's pre-flight comment and prose, in the same commit; `check-all.sh`'s comment states no count. (c) (a) in `check-run-contract.sh`; (b) and (c) in a new `check-prototype-copies.sh` (11 and 10). | (a). Each home is the one its roadmap item names: the invariant sentence states the run-directory contract `check-run-contract.sh` already guards, and the Prototype line and the leftovers command sit on the open-question path whose anchor `check-doc-sync-anchors.sh` already carries. D-4 prefers existing guards, and the counts the release checklist pins do not move. The cost: `check-doc-sync-anchors.sh` stops being presence-only, which its header then says. | **(a)** — decided by the main session within the locked design. Existing guards; `guards run: 10` and `self-tests run: 9` are unchanged. Steps 4.1, 4.2. |
| D9 | Whether check 6 also holds the canonical dispatch block's copy in `task-review/SKILL.md` (D-4(a)). | (a) Yes: three copies against the ROLE reference — the plugin README, CLAUDE.md, and task-review's dispatch block (`check-canonical-dispatch.sh` carries it to task-implement). (b) The README and CLAUDE.md only. | (a), flagged as going past D-4(a)'s words. The file is already one the guard reads, and with it every copy of the sentence is tied to the agents' ROLE, where today the two guarded families can drift apart while each stays identical inside. | **(a)**, beyond D-4(a)'s literal words and within its intent — decided by the main session within the locked design. The guard only reads task-review's dispatch copy, never edits it, and ties both guard families to one reference. Step 4.1. |
| D10 | How check 6 extracts and compares (D-4(a)). | (a) The reference is the lines of `requirements-reviewer.md` from the one that begins `Each reviewer is read-only on the working tree` through the first line that ends in a period, joined and normalized — every run of spaces, tabs, CR, and LF becomes one space, leading and trailing space dropped; each copy's file is normalized the same way and must contain the reference. No such line in the reference file is exit 2; a copy file without the reference is exit 1, naming the file. (b) Line-by-line comparison after trimming each line. | (a). Normalizing makes re-wrapping and CLAUDE.md's list indentation irrelevant, which is what "whitespace-normalized" asks; (b) fails on a re-wrap. The self-test proves both sides: a word changed in a copy exits 1, a whitespace-only change exits 0. | **(a)** — decided by the main session within the locked design. A substring match after normalization; the self-test tests both directions — a changed word exits 1, a whitespace-only change exits 0. Step 4.1. |
| D11 | The Prototype-line check (D-4(b)). | (a) Two `ANCHOR_CHECKS` entries whose label is the line's full literal, one for `generate-brief/SKILL.md` and one for `prototype/SKILL.md`, single-quoted in the array because the literal holds backticks. The self-test gains a mutation of the copy in `prototype/SKILL.md` that must exit 1. (b) Extract the line from each file and compare the extracts. | (a). The full literal present in both files is the byte-identity the line needs, and it is roadmap item 10's own suggestion. It does not see text added before or after the literal in one file, which changes neither what a reader copies nor the hash an entry names; (b) would have to strip two different wrappings (a list bullet, double backticks). | **(a)** — decided by the main session within the locked design. Two `ANCHOR_CHECKS` entries, the roadmap item's own suggestion. Step 4.2. |
| D12 | The leftovers-command count (D-4(c)). | (a) Count occurrences of the literal in `prototype/SKILL.md` — not lines — and require exactly 2. The self-test edits the first occurrence alone (must exit 1), appends a third copy (must exit 1), and restores (must exit 0). (b) Count lines. (c) At least two. | (a). A line count reads two copies on one line as one; "at least two" would let a third use in without anyone checking whether it has to match the others. | **(a)** — decided by the main session within the locked design. Counted by occurrence, exactly 2; one mutation edits one copy and one adds a third. Step 4.2. |
| D13 | The diagnose-bug exit sentence (D-5). | (a) On "interactively", when Phase 1 committed a reproduction test: the last message names that commit, says its test fails until the fix lands and that every review run in the repository reports the test run FAIL until then, and gives `git revert <hash>`; the skill does not revert it unasked. (b) The revert only, worded as "Ending without a document" words it. | (a). The review-run consequence is the concrete cost of the red interval D-5 documents, and the exit is the last point the skill speaks to the user; (b) is the minimal form if the main session wants the exit changed no further than D-5's words. A manual reproduction commits no test, so the sentence carries that condition. | **(a)**; the half-sentence on review runs goes beyond D-5's literal words for the Exit and agrees with D-5's README paragraph — decided by the main session within the locked design. The last message names the commit, says the review runs' test row FAILs, and gives `git revert <hash>`; the skill does not revert unasked; the sentence carries its condition, since a manual reproduction commits no test. Step 3.1. |
| D14 | Where D-6's Known behavior item goes. | (a) A new item, "Uncommitted `.gitignore` edits.", after "Uncommitted fixes", the other item about what a run commits of the user's uncommitted work. (b) A sentence at the end of "Review scope without a task document", which already mentions the one-time commit. (c) A sentence in the `.gitignore` bullet of § Run directory. | (a). D-6 names Known behavior; the item covers `/kenspc-diagnose` as well as the two review entry points, which (b)'s item is not about; (c) is outside Known behavior. | **(a)** — decided by the main session within the locked design. A new Known behavior item after "Uncommitted fixes". Step 5.2. |
| D15 | The sections of the 3.8.1 CHANGELOG entry (D-7). | (a) An intro, `### Changed`, and `### Known behavior`. (b) `### Fixed` for D-1, then Changed and Known behavior. | (a). D-1 gives a stop a branch its text never had, rather than correcting text that was wrong, and the main session's brief for this batch names Changed and Known behavior. | **(a)** — decided by the main session within the locked design. Step 5.3. |
| D16 | Where the release checklist's new criteria go. | (a) Additions to rows 4 (D-1, D-2), 9 (D-5), and 10 (D-3); no new row and no renumbering; pre-flight counts unchanged under D8 (a). (b) A new row for unattended runs. | (a). Each criterion belongs to the entry point its row exercises, and a new row moves every later reference. | **(a)** — decided by the main session within the locked design. Step 5.4. |

### Standing constraints

- Rules are rationale-anchored ("Why: …" prose), not imperatives; no `MUST`
  / `NEVER` / `CRITICAL`, no inline effort or reasoning tokens, no model
  names (`bash scripts/check-no-model-names.sh` exits 0).
- A check written into a skill is in rubric form: what passing looks like,
  then the named ways it fails. No generic checklist items.
- No edit inside any byte-identity section, with no exception in this batch:
  the canonical blocks, the code-craft canonical paragraphs, and the five
  reviewers' six shared sections are untouched, and every guard stays green.
- Zero diff in `plugins/kenspc/agents/`, `shared/`, `references/`, `hooks/`,
  and `commands/`, and in `task-implement/SKILL.md`, `task-review/SKILL.md`,
  `generate-task/SKILL.md`, and `generate-brief/SKILL.md`:
  `git diff --stat 0128a2f HEAD -- plugins/kenspc/agents plugins/kenspc/shared plugins/kenspc/references plugins/kenspc/hooks plugins/kenspc/commands plugins/kenspc/skills/task-implement plugins/kenspc/skills/task-review plugins/kenspc/skills/generate-task plugins/kenspc/skills/generate-brief`
  prints nothing. `diagnose-bug/SKILL.md` changes only between `## Exit` and
  `## Writing rules for the document`. The files this batch touches are
  `generate-plan/SKILL.md`, `prototype/SKILL.md`, `diagnose-bug/SKILL.md`
  (its Exit), the two guards, and the documents in
  [Documentation impact](#documentation-impact).
- No new skill, command, agent, or CONTEXT key.
- `effort:` frontmatter unchanged in every file (release-checklist
  pre-flight diff); `version: 3.0.0` unchanged in all eight skills.
- Every question point this batch adds or reaches — generate-plan's
  approval stop and its existing-file question (M4), the gap round's
  question about an `answered` entry with no `Answer:`, and the prototype
  skill's new gate — has a cannot-ask branch worded as diagnose-bug words
  it: "In a session that cannot ask (a system reminder to work without
  stopping), …".
- Plugin files state their evidence in their own words and carry no pointer
  labels — B-n, C-n, D-n, M-n, CL-n, "ruling", batch names, dry-run
  records. The criterion for every plugin file this batch edits
  (`generate-plan/SKILL.md`, `prototype/SKILL.md`, `diagnose-bug/SKILL.md`):
  `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\b[BCD]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>`
  prints nothing. It prints nothing on those three files at `0128a2f` and
  184 lines on the batch C spec, so it can fail.
- Guards keep to bash 3.2 (no associative arrays), use literal awk
  replacements rather than `sed -i` in new mutations, and keep the
  `set -euo pipefail` and `SCRIPT_DIR` / `REPO_ROOT` pattern.
- Plugin Design Lessons apply: phase transitions rest on artifacts (a
  cannot-ask plan run ends on the printed draft, not on a written file), and
  no hook guards workflow state.
- This spec and the acceptance record are in English.
- The dogfood: the task document for this batch comes from `/kenspc-task` on
  this spec, which generates the Doc-sync task from the Documentation impact
  below; it is not added by hand.

## Fixed strings

These strings are load-bearing: a guard asserts them, the release checklist
or the acceptance greps for them, or a driving session tests for them. Spell
them exactly as given, in every file that carries them.

| Anchor | Exact form | Carried by |
|---|---|---|
| Not-approved line | `Plan not written: awaiting approval.` — in English whatever the conversation language | `generate-plan/SKILL.md`, `plugins/kenspc/CHANGELOG.md` (3.8.1), `docs/release-checklist.md` (row 4) |
| Carried `answered` entry | `From: <brief path>, entry <n>, status word answered, Answer: missing` | `generate-plan/SKILL.md`, plans, `docs/release-checklist.md` (row 4) |
| Carried unrecognized entry (unchanged) | `From: <brief path>, entry <n>, status word <the word, or none> not recognized` | `generate-plan/SKILL.md`, plans |
| Reviewer invariant sentence | `` Each reviewer is read-only on the working tree and writes only under `RUN_DIR`: its report at `RUN_DIR/angle-<n>.md`, and probe and temporary files under `RUN_DIR/scratch/angle-<n>/`. `` — whitespace-normalized | the five reviewers' ROLE (the reference: `requirements-reviewer.md`), `task-review/SKILL.md` and `task-implement/SKILL.md` (canonical dispatch), `plugins/kenspc/README.md`, `CLAUDE.md`; read by `check-run-contract.sh` |
| Prototype line | ``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` `` | `generate-brief/SKILL.md`, `prototype/SKILL.md`, `check-doc-sync-anchors.sh` |
| Leftovers command, exactly twice | `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>` | `prototype/SKILL.md` (twice), `check-doc-sync-anchors.sh`; quoted, unguarded, by the plugin README, the 3.8.0 CHANGELOG, and release-checklist row 10 |
| Known behavior item (D-6) | ``**Uncommitted `.gitignore` edits.**`` | `plugins/kenspc/README.md` |
| Red-interval paragraph (D-5) | the phrase `no notion of a failure that predates the run` | `plugins/kenspc/README.md` |
| Guard counts (unchanged) | `guards run: 10`, `self-tests run: 9` | `docs/release-checklist.md`, `CLAUDE.md` |

## Implementation Steps

Phases 1, 2, and 3 are independent of one another. Phase 4 comes after
Phase 2, so the count check runs against the prototype skill's final text.
Phase 5 comes last.

### Phase 1: generate-plan (D-1, D-2)

**Step 1.1: The approval stop and the existing-file question in a session that cannot ask**

- File: `plugins/kenspc/skills/generate-plan/SKILL.md`, Phase 2 Step 3 only.
  `effort: xhigh`, Phase 1, Phase 2 Steps 1–2, and Phase 3 are unchanged.
- After "Write only when the user explicitly approves the plan.", in
  substance (rulings D1, D2, D3):

  > In a session that cannot ask (a system reminder to work without
  > stopping), the run still stops here. Its last message holds the complete
  > draft — every section of the draft after self-challenge, none elided or
  > summarized — then the line `Plan not written: awaiting approval.`, and
  > says how to go on: reply in this session approving the draft or asking
  > for changes (a headless run resumes it with
  > `claude -p --resume <session id> "<reply>"`), or run `/kenspc-plan`
  > again in a session that can ask. Nothing is written,
  > `plan-document-reviewer` is not dispatched, and nothing is committed. A
  > later reply that approves the draft is the approval — in a headless run,
  > the reply of the session that resumes this one — and this step then runs
  > as written. Why: the written plan is the approved plan — Phase 3's
  > reviewer commits it and generate-task decomposes it as agreed — so a run
  > that writes it without approval makes the user's decision; and under a
  > reminder to work without stopping, with no branch at this stop, an
  > unapproved plan has been written, reviewed, and committed on the current
  > branch. The line stays in English in any conversation language, so a
  > driving session can test for it.

- Item 1.c gains, in substance (ruling M4): in a session that cannot ask (a
  system reminder to work without stopping), create the file alongside with
  a numeric suffix (`<name>-2.md`) and say so in the final message. Why: an
  overwrite nobody chose can destroy a plan the user kept.
- Same commit (ruling M10): CLAUDE.md's Writing Rules for Skill Content,
  the cannot-ask bullet — its list of the question points that share the
  wording gains generate-plan's approval stop and its existing-file
  question.
- Done when: both sentences are present with their Whys, each opening with
  "In a session that cannot ask (a system reminder to work without
  stopping)"; the line is spelled as in Fixed strings; the text names all
  three things that do not happen (no file, no `plan-document-reviewer`
  dispatch, no commit) and the resumed approval; nothing outside Phase 2
  Step 3 changed in the skill in this step; CLAUDE.md's cannot-ask list is
  updated in the same commit; `bash scripts/check-no-model-names.sh` exits
  0; the pointer-label grep prints nothing on the file.
- Why: D-1 — the approval stop was the one stop on a cannot-ask plan run
  with no branch, and the run that met it wrote the plan.

**Step 1.2: `answered` entries count as settled only with `Answer:`**

- File: the same, Phase 1 Step 1 parts 2 and 3 and Phase 2 Step 1's Open
  Questions element. Part 1 (the exit) is unchanged: it still reads only the
  status word `needs prototype`.
- Part 2, the gap list (rulings M5, D5), in substance: an
  `` `answered` `` entry that holds no `Answer:` — as the brief has it, or
  as the user marks an entry in the gap round — is a gap too: the gap round
  quotes it and asks for its answer, and the question that asks an
  unrecognized entry's status also asks, for `answered`, the answer. The
  answer the user gives is settled input, as any gap-round answer is; an
  entry the rounds leave without one is carried in the `open` form. Why: a
  status word is one token that a hand edit, a translation, or a gap-round
  answer can set; an entry with no answer gives a plan nothing to rest on,
  and taking it as settled lets the plan assume an answer without saying so.
- Part 2's cannot-ask sentence gains: an `answered` entry with no `Answer:`
  is carried the same way, in the `open` form, its `From:` ending
  `status word answered, Answer: missing` (ruling D4).
- Part 3 (ruling M6): an `` `answered` `` entry that holds `Answer:` is
  settled input — `Answer:` makes it so, not the status word alone and not a
  `Prototype:` line alone. A plan that relies on one cites its prototype
  hash where it does, or, for an entry with no Prototype line, the entry
  itself (`<brief path>, entry <n>`). The Why keeps its reason (the brief
  may be deleted; the citation in the plan keeps the evidence reachable).
- Open Questions element: beside the unrecognized-word form, the line
  `From: <brief path>, entry <n>, status word answered, Answer: missing` for
  an `answered` entry carried without an answer, in the `open` form.
- Same commit (ruling M10): CLAUDE.md's Subagent Review Architecture, the
  prototype path paragraph — "The next generate-plan run reads the answered
  entry as settled input" names `Answer:` as what makes it settled.
- Done when: part 2 lists the `answered`-without-`Answer:` gap with its
  question and its cannot-ask branch; part 3 names `Answer:` as the test and
  the citation for an entry with no Prototype line; the element carries the
  new `From:` form, spelled as in Fixed strings; part 1 is unchanged
  (`git diff` of the file shows no line of part 1 changed); CLAUDE.md's
  prototype path paragraph is updated in the same commit; the pointer-label
  grep prints nothing on the file.
- Why: D-2 — `Answer:` is what makes an entry settled, and the gap round is
  where the plan's discovery asks about a gap.

### Phase 2: The prototype skill (D-3)

**Step 2.1: A gate for an entry the skill cannot read**

- File: `plugins/kenspc/skills/prototype/SKILL.md`: § The question, § The
  gates, and Phase 1's Constraints. Nothing else changes.
- § The question, the `answered` bullet (ruling M1), in substance: a named
  entry that is `` `answered` ``, or that holds `Answer:` whatever its
  status word: ask whether to prototype it again. The cannot-ask branch and
  its "the rewrite in Phase 3 for a run in which nothing was built does not
  apply to it" stay. Add: a `Prototype:` line with no `Answer:` under
  `` `needs prototype` `` is the form an unsettled attempt leaves, and such
  an entry is prototyped again like any other.
- § The question, a new bullet after it (rulings D6, D7), in substance: a
  named entry whose status word is none of `` `open` ``,
  `` `needs prototype` ``, and `` `answered` `` — hand-edited, translated,
  or missing: one that holds `Prototype:` takes the question above;
  otherwise ask, quoting the word found (or saying there is none), whether
  to prototype it or stop. In a session that cannot ask (a system reminder
  to work without stopping), stop and leave the entry unchanged, as above.
  On "prototype it", the entry is prototyped as a named `` `open` `` entry
  is, and Phase 3 writes a status word the grammar knows. Why: the skill
  tells an answered entry from an unsettled one by its status word, so an
  entry whose word it cannot read may hold an answer that Phase 3 would
  replace; the brief is not committed, so the earlier answer would then
  survive only in an earlier remove commit's body.
- Phase 1's Constraints gain: the gates on the named entry come before
  either write this phase makes (ruling D7).
- § The gates: the `answered` row becomes "The named entry is `answered`,
  holds `Answer:`, or has an unrecognized status word and holds
  `Prototype:`" — "Prototype it again?" — "Stop; the entry unchanged". A new
  row: "The named entry's status word is not recognized, and it holds
  neither `Answer:` nor `Prototype:`" — "Prototype it, or stop" — "Stop; the
  entry unchanged".
- Same commit (D-3): the README's items for this gate — the `prototype`
  row's list of what the skill asks about and the Prototype path sentence
  (Step 5.2) — and the CHANGELOG's line for it (Step 5.3) are made in this
  step's commit. Why: the lock ties the gates table, the README's gate
  list, and the CHANGELOG together, so no commit shows one without the
  others.
- Done when: both bullets carry their cannot-ask branch in diagnose-bug's
  wording and their Why; the gates table has both rows, each with its
  cannot-ask column; the Constraints sentence is present; the Prototype line
  and the leftovers command are unchanged (Step 4.2's checks pass); the
  README and CHANGELOG items for this gate are in the same commit; the
  pointer-label grep prints nothing on the file.
- Why: D-3 — the skill replaces an entry's labels in a brief with no
  committed copy, so the entry it cannot read is the one to ask about.

### Phase 3: diagnose-bug's interactive exit (D-5)

**Step 3.1: The reproduction commit named on "interactively"**

- File: `plugins/kenspc/skills/diagnose-bug/SKILL.md`, the "interactively"
  bullet of § Exit only. "Ending without a document", the "run" and
  cannot-ask bullets, and tier 3 are unchanged (ruling M7).
- The bullet, in substance (ruling D13): on "interactively", stop; the task
  document stands, committed, for the user to work from. When Phase 1
  committed a reproduction test, the last message names that commit, says
  its test fails — and every review run in the repository reports the test
  run FAIL — until the fix lands, and gives `git revert <hash>` for backing
  the test out if the fix is not made; the skill does not revert it unasked.
  Why: the fix is now the user's to make, and until it lands the branch
  carries a failing test that nothing scheduled will turn green.
- Done when: the bullet carries the condition (a committed reproduction
  test), the commit named, the review-run consequence, `git revert <hash>`,
  "does not revert it unasked", and its Why;
  `git diff 0128a2f -- plugins/kenspc/skills/diagnose-bug/SKILL.md` shows
  hunks only between `## Exit` and `## Writing rules for the document`; the
  pointer-label grep prints nothing on the file.
- Why: D-5 — the interactive exit leaves the same red commit as "Ending
  without a document", which already names it.

### Phase 4: Guards (D-4)

**Step 4.1: Check 6 in `check-run-contract.sh` — the reviewer invariant sentence**

- File: `scripts/check-run-contract.sh` (rulings M3, D8, D9, D10).
- Main mode, after check 5: extract the reference from
  `plugins/kenspc/agents/requirements-reviewer.md` — the lines from the one
  that begins `Each reviewer is read-only on the working tree` through the
  first line that ends in a period — and normalize it (every run of spaces,
  tabs, CR, and LF to one space; leading and trailing space dropped). Each
  of `plugins/kenspc/README.md`, `CLAUDE.md`, and
  `plugins/kenspc/skills/task-review/SKILL.md`, normalized the same way,
  must contain it. No start line in the reference file is exit 2 (the
  reference moved); a copy file that does not contain it is exit 1, naming
  the file and saying the copies follow the reviewers' ROLE sentence. A
  missing file is exit 2, as for the other checks. The OK line names the
  three copies. `--file PATH` still runs check 4 only.
- Header: "Five checks" becomes six, with a paragraph for check 6 (the four
  places the sentence lives, the two families the other guards hold, and why
  the reference is extracted rather than copied into the guard); the exit-1
  and exit-2 lines gain their cases; the self-test paragraph names the two
  more files it copies and the new mutations, and states the number of
  mutations that must exit 1 as the script runs them, check 6's included
  (ruling M13).
- Self-test: copies the README and CLAUDE.md too (seven files). A
  fixture-stale guard: the start line occurs once in the copied reference.
  Mutations, each by a literal replacement on exactly one line, each
  restored after: `writes only under` → `writes only below` in the README's
  copy, in CLAUDE.md's, in task-review's, and in the reference itself — each
  must exit 1; a whitespace-only change to the README's copy
  (`read-only on the working tree` → `read-only  on the working tree`, two
  spaces) must exit 0. Then the reverted copy must exit 0.
- Same commit (ruling M10): in CLAUDE.md, § Repository scripts/'s
  description of `check-run-contract.sh` gains check 6, and the Maintenance
  note says that editing the reviewer invariant sentence in the plugin
  README or CLAUDE.md, or the reviewers' ROLE, runs `check-run-contract.sh`.
- Done when: `bash scripts/check-run-contract.sh` exits 0 with the check-6
  OK line; `--self-test` exits 0; the two CLAUDE.md sentences are in the
  same commit; by hand, on a copy of the repository tree
  under `$TMPDIR`, a word changed in the README's copy of the sentence makes
  the main check exit 1 naming `plugins/kenspc/README.md`, and restoring it
  makes it exit 0; `bash scripts/check-all.sh --self-test` prints
  `guards run: 10` and ends with `self-tests run: 9`.
- Why: roadmap item 5 — the sentence is the run-directory contract as the
  README and CLAUDE.md state it, and those two copies had no guard.

**Step 4.2: The Prototype line and the leftovers count in `check-doc-sync-anchors.sh`**

- File: `scripts/check-doc-sync-anchors.sh` (rulings M9, D8, D11, D12).
- `ANCHOR_CHECKS` gains two single-quoted entries, the Prototype line's full
  literal with `plugins/kenspc/skills/generate-brief/SKILL.md` and with
  `plugins/kenspc/skills/prototype/SKILL.md`.
- One exact-count check: the literal
  `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`
  occurs exactly 2 times in `plugins/kenspc/skills/prototype/SKILL.md`,
  counted by occurrence (an awk `index` loop), not by line. Any other count
  is exit 1, with the count found and why the two copies must agree: the
  start snapshot and the Exit compare their two lists path by path.
- Header: an anchor guard for the planning chain — presence for five
  anchors across eleven files, and one exact count; the new group listed
  under the open-question path; the count check described; the sentence
  about README.md and CLAUDE.md says the reviewer invariant sentence there
  is checked by `check-run-contract.sh` (check 6), and the rest of their
  prose by no guard. The drift message names the fifth anchor; the success
  line says "all five anchors"; a second OK line reports the count.
- Self-test: the copied files are unchanged in number (eleven). Fixture-stale
  guards: the Prototype line present in the copied `prototype/SKILL.md`; the
  leftovers literal occurring twice in it. Mutations, each restored after:
  the existing `Doc-sync` rename (exit 1); `` `<location>`, removed in the
  next commit`` → `` `<location>`, removed in a later commit`` in
  `prototype/SKILL.md` (exit 1); the first occurrence alone of the leftovers
  literal with `--ignored=matching` → `--ignored` (exit 1); a third copy of
  the literal appended to the file (exit 1). Then the reverted copy must
  exit 0. The header's self-test paragraph names the new mutations.
- Same commit (ruling M10): in CLAUDE.md, § Repository scripts/'s
  description of `check-doc-sync-anchors.sh` says five anchors, two on the
  open-question path (`needs prototype`, and the Prototype line in
  generate-brief and prototype), and the exact-count check on the leftovers
  command — its "README.md and CLAUDE.md are deliberately outside it" stays
  true for that guard; § Non-Goals' "`check-doc-sync-anchors.sh` guards
  only the `needs prototype` status word across the three files, not this
  line" becomes a sentence saying the guard holds the line in both files,
  and the rule that a change to the line updates both files in the same
  commit stays; the Maintenance note says that editing the Prototype line or
  the leftovers command runs `check-doc-sync-anchors.sh`.
- Done when: `bash scripts/check-doc-sync-anchors.sh` exits 0 with both OK
  lines; `--self-test` exits 0; the CLAUDE.md sentences are in the same
  commit; by hand, on a copy of the repository tree
  under `$TMPDIR`, editing the Prototype line in `prototype/SKILL.md` makes
  the main check exit 1 naming that file, and editing one of the two
  leftovers commands makes it exit 1 with the count 1, each restored to exit
  0; `bash scripts/check-all.sh --self-test` prints `guards run: 10` and
  ends with `self-tests run: 9`.
- Why: roadmap items 10 and 11 — an edit to one copy of either string passed
  every guard.

### Phase 5: Documentation

**Step 5.1: Repository CLAUDE.md**

- File: `CLAUDE.md` (repository root) (ruling M10). Each change is made in
  the commit of the step whose change makes the old sentence false, so no
  commit leaves CLAUDE.md contradicting the files beside it:
  - Writing Rules for Skill Content, the cannot-ask bullet — with Step 1.1.
  - Subagent Review Architecture, the prototype path paragraph — with Step
    1.2.
  - Repository scripts/, `check-run-contract.sh`'s description, and the
    Maintenance note's line for it — with Step 4.1.
  - Repository scripts/, `check-doc-sync-anchors.sh`'s description,
    § Non-Goals' Prototype-line sentence, and the Maintenance note's line
    for that guard — with Step 4.2.
- This step makes no further edit unless the read-through below finds a
  sentence those four missed; such a sentence is fixed here and named in
  the commit message. Guard counts are unchanged (ruling D8), so
  § Repository scripts/' "Nine of the guards" paragraph and every stated
  count stay as they are.
- Done when: every guard description agrees with its script's header, the
  cannot-ask list names every question point that has the branch, the
  prototype path paragraph names `Answer:`, and the file reads top to bottom
  without a contradiction about guard or anchor counts.
- Why: CLAUDE.md is the loaded contract for every session in this
  repository.

**Step 5.2: The plugin README**

- File: `plugins/kenspc/README.md` (rulings M2, M11, D14).
- § Skills, `generate-plan` row: one sentence — in a session that cannot
  ask, the run stops at the draft, printed in full, with no file written, no
  review, and no commit, until a later reply approves it.
- § Skills, `prototype` row, the list of what the skill asks about: a named
  entry that already holds an answer, and one whose status word the skill
  does not recognize, join the list, with what a session that cannot ask
  does (stops, the brief unchanged) — made in Step 2.1's commit (D-3).
- § Recommended Workflow, Prototype path paragraph: an `answered` entry is
  settled input for `/kenspc-plan` only when it holds `Answer:`, and one
  without is asked about or carried as `open`; `/kenspc-prototype` asks
  before it rewrites an entry whose status word it does not recognize — the
  second clause made in Step 2.1's commit (D-3).
- § Known behavior, "Red interval after a diagnosis" (D-5): its last sentence says
  the skill names the commit and gives `git revert` when you implement
  interactively as well as when the diagnosis ends without a document; then
  a paragraph, in substance: while the reproduction test is red, every
  review run in the repository reports it — `/kenspc-task-review`, and the
  review phase of a `/kenspc-task-implement` run in which the fix task did
  not land, record the test run FAIL and the verdict FAIL. regression-verifier
  runs the project's build, test, and lint commands as the project
  configures them, with no filter or exclude added, and has no notion of a
  failure that predates the run, so the reproduction test's failure counts
  like any other; that is the red test doing its job, not a defect of the
  verifier. A mutation check whose copy runs the reproduction test cannot
  make its unmutated copy pass first, so it is reported as not made. Land
  the fix, or revert the reproduction commit, before a review whose verdict
  you need.
- § Known behavior, a new item after "Uncommitted fixes" (D-6), in substance:
  **Uncommitted `.gitignore` edits.** The one-time commit that adds
  `.kenspc/` to `.gitignore` (see Run directory) stages and commits the
  whole file as it stands in your working tree, so an edit to `.gitignore`
  you had not committed — staged or not — goes into
  `chore: ignore kenspc run directory` with the `.kenspc/` line.
  `/kenspc-task-review`, `/kenspc-task-implement`'s review phase, and
  `/kenspc-diagnose` when it probes make that commit on their first run in a
  repository that does not yet ignore `.kenspc/`. Commit or stash your
  `.gitignore` edits first, or split that commit afterwards.
- Done when: the two Skills sentences, the Prototype path sentences, the
  Red-interval paragraph with the phrase in Fixed strings, and the new item
  with its fixed title are present, and every sentence about the three
  changed behaviors agrees with the skill text.
- Why: the README is the installed user's only description of what these
  runs do and leave.

**Step 5.3: CHANGELOG**

- File: `plugins/kenspc/CHANGELOG.md` (ruling D15): a `## 3.8.1 — unreleased`
  entry above 3.8.0.
  - Intro: batch D; what changes, in one paragraph; no new command, skill,
    agent, or CONTEXT key, so a patch; guard counts unchanged; the release
    smoke is the batch's acceptance record, named at release.
  - Changed: generate-plan's approval stop in a session that cannot ask
    (the draft printed in full, `Plan not written: awaiting approval.`, no
    file, no review, no commit; approval by a later reply), with its source:
    the batch C acceptance, F1, where such a run wrote, reviewed, and
    committed an unapproved plan — and the 3.8.0 sentence "a session that
    cannot ask still writes the plan only on approval" described the text,
    which that run did not follow; the existing-file question's cannot-ask
    branch; `answered` entries settled only with `Answer:`, the gap-round
    question, and the carried `From:` form; the prototype skill's gate for
    an entry it cannot read, and the `answered` gate for an entry that holds
    `Answer:`; diagnose-bug's interactive exit; the two guards' new checks
    (check 6; the Prototype line group; the leftovers count), counts
    unchanged, and `check-run-contract.sh`'s header now stating the number
    of self-test mutations it runs (it said eleven where it ran fourteen);
    release-checklist rows 4, 9, and 10; CLAUDE.md and the plugin README.
  - Known behavior (D-5, D-6): the red interval's effect on review runs and on
    mutation checks; the one-time `.gitignore` commit takes the whole file,
    behavior unchanged.
  - The date is filled at release.
- Commit grouping (D-3): the Changed line for the prototype skill's new gate
  and the widened `answered` gate is made in Step 2.1's commit; the rest of
  the entry is made in this step.
- Done when: the entry is present with the three parts, and every behavior
  it names matches the skill and script text.
- Why: every change that ships is recorded under the next version's heading.

**Step 5.4: Release checklist**

- File: `docs/release-checklist.md` (ruling D16). Pre-flight counts stay
  `guards run: 10` and `self-tests run: 9`.
- Row 4 additions: in a session that cannot ask, the run stops at the
  draft — its last message holds the complete draft and the line
  `Plan not written: awaiting approval.`, and the trace shows no Write, no
  Agent call, and no commit (HEAD and `git status --porcelain` unchanged);
  resuming it with a reply that approves the draft writes the plan,
  dispatches `plan-document-reviewer`, and commits; a brief entry marked
  `` `answered` `` with no `Answer:` is quoted and asked about in the gap
  round, and in a session that cannot ask it appears in the draft's Open
  Questions in the `open` form with
  `From: <brief path>, entry <n>, status word answered, Answer: missing`.
- Row 9 addition: on "interactively", after a `test: reproduce` commit, the
  last message names that commit and gives `git revert <hash>`, and no
  revert is made.
- Row 10 addition: a named entry whose status word is not recognized is
  asked about before anything is written — prototype it, or stop — and a
  named entry that holds `Answer:` gets the prototype-again question; in a
  session that cannot ask, either stops with no commit and the brief's
  sha256 unchanged.
- Done when: the three additions are present and the pre-flight counts are
  unchanged.
- Why: the checklist is the only check that exercises the live chain; the
  fixed strings are what it greps for.

### The release commit (D-7) — not a batch step

Recorded so the implementing session leaves these alone: in the release
commit, not before it, `plugins/kenspc/.claude-plugin/plugin.json` goes to
3.8.1; the CHANGELOG heading gets its date; roadmap items 5, 10, 11, 13, 14,
and 15 leave `docs/roadmap.md`, the rest are renumbered in order (1–4 stay,
6 → 5, 7 → 6, 8 → 7, 9 → 8, 12 → 9, 16 → 10) with their text unchanged,
and the heading stays `## Next minor (3.9.0)`; no tag. Why: the
repository's convention for planned versus shipped work — an item leaves the
roadmap, and the version moves, when the release ships, as batch C's release
did.

## Documentation impact

Determined from this repository's CLAUDE.md, § Durable documents.

- `CLAUDE.md` § Writing Rules for Skill Content (the cannot-ask list),
  § Subagent Review Architecture (the prototype path paragraph; the
  Maintenance note), § Repository scripts/ (`check-run-contract.sh`,
  `check-doc-sync-anchors.sh`), § Non-Goals (the Prototype line sentence) —
  made in the commits of Steps 1.1, 1.2, 4.1, and 4.2 (ruling M10), checked
  by Step 5.1.
- `plugins/kenspc/README.md` § Skills (the `generate-plan` and `prototype`
  rows), § Recommended Workflow (the Prototype path paragraph), § Known
  behavior ("Red interval after a diagnosis"; the new "Uncommitted
  `.gitignore` edits" item) — Step 5.2; the `prototype` row's gate list and
  the Prototype path's gate clause in Step 2.1's commit (D-3).
- `plugins/kenspc/CHANGELOG.md` — the 3.8.1 entry — Step 5.3; the line for
  the prototype skill's gates in Step 2.1's commit (D-3).
- `docs/release-checklist.md` — rows 4, 9, and 10; pre-flight unchanged —
  Step 5.4.
- `docs/roadmap.md` — items 5, 10, 11, 13, 14, and 15 leave and the rest are
  renumbered in the release commit, not in this batch (D-7).
- `README.md` (root) — N/A for this document: no skill's summary row changes
  and no plugin is added.
- `docs/dry-runs/README.md` — N/A for this document: the label convention is
  untouched.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this
  document: its plan is not made from a brief, so the carried forms have no
  place in it.
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: the task-document format is unchanged.

## Testing Strategy

- Mechanical: the release-checklist pre-flight block — the effort-override
  diff (unchanged), `claude plugin validate --strict .` and
  `./plugins/kenspc`, and `bash scripts/check-all.sh --self-test` with
  `guards run: 10` and `self-tests run: 9`.
- Guard falsifiability: each new check's self-test mutations (Steps 4.1,
  4.2), and one mutation per check by hand on a copy of the repository tree
  under `$TMPDIR`, showing exit 1 naming the file, then exit 0 after the
  copy is restored; the copy is left under `$TMPDIR`.
- Pointer labels: the grep in Standing constraints on `generate-plan`,
  `prototype`, and `diagnose-bug`'s SKILL files.
- Zero diff: the `git diff --stat` command in Standing constraints prints
  nothing; the diagnose-bug hunks lie within its Exit.
- Live chain, headless, one process per run:
  `claude -p "<prompt>" --plugin-dir <repo>/plugins/kenspc
  --permission-mode bypassPermissions --output-format json`, from the smoke
  project's directory. A run that stops at a question is continued with
  `claude -p --resume <session_id> "<answer>"` from the same directory with
  the same other flags, the session id taken from the stopped run's JSON. A
  session that cannot ask is made with `--append-system-prompt "Work without
  stopping; do not ask clarifying questions."`, passed again on each resume
  of that session, and the record names every run that used it. A run that
  asks anyway is a finding. Cost is each session's last `total_cost_usd`,
  which on a resumed run is the session's running total.
- Seed: throwaway projects under `~/Projects/_smoke/batch-d-*`, a
  TypeScript project to the batch C acceptance's Seed project row
  (`docs/dry-runs/batch-c-acceptance.md` § 1): `typescript@7.0.2` and
  `vitest@5.0.1` installed with `npm install --offline` from the local npm
  cache, tests of its own green, a `typecheck` script; no call to the npm
  registry. For the diagnose-bug case the seed carries one bug its own tests
  do not catch. A hand-written brief, left untracked, with five
  `## Open Questions` entries: 1 `` `needs prototype` `` with `Settled by:`;
  2 `` `open` ``; 3 `` `answered` `` with `Settled by:`, `Evidence:`, and a
  Prototype line and no `Answer:`; 4 `` `需要原型` `` with `Settled by:`;
  5 `` `open` `` with `Answer:` and a Prototype line. The Prototype lines
  name a real commit the driver makes in the seed, so `git show` resolves.
  Entries 1, 2, and 4 re-check batch C's behavior in the same runs.
- The brief's unchanged state (ruling M12): because the brief is untracked,
  `git diff` cannot show an edit to it, so every "brief unchanged" criterion
  below is the brief's sha256 (`shasum -a 256`) taken before the run and
  after it. Positive control, once per seed: the driver edits a copy of the
  brief by one character and shows its hash differs from the original's.
- Cases, each with its PASS criterion:
  1. Row 4, cannot-ask, the F1 case again — `/kenspc-plan <brief>` with the
     reminder. PASS: one invocation with no question; the run's last
     message (`result`) holds a complete draft — every section, with
     `## Documentation impact` — then `Plan not written: awaiting
     approval.`; the transcript has no Write, Edit, or Agent tool call;
     `git status --porcelain -uall` and HEAD are as before the run; the
     draft's Open Questions carry entry 1 with
     `Not prototyped: the session could not ask`, entry 2 with `From:` and
     `Assumed in:`, entry 3 in the `open` form with
     `From: <brief path>, entry 3, status word answered, Answer: missing`,
     entry 4 with `status word 需要原型 not recognized`, and entry 5 in the
     `open` form.
  2. Row 4, the resumed approval — `--resume <case 1's session id>
     "approved"`, the reminder passed again. PASS: the plan written under
     `docs/plans/` from the printed draft; an Agent call to
     `plan-document-reviewer` followed by the Schema E table; the
     reviewer's commits on the branch. The driver's reply is quoted and
     recorded as the driver's answer.
  3. Row 4, interactive gap round — `/kenspc-plan <brief>` without the
     reminder; the exit question on entry 1 answered "carry". PASS: the gap
     round quotes entry 3 and asks for its answer (and asks entry 4's
     status, batch C's rule); the driver's answers are quoted; the run is
     stopped at the approval stop with no file written.
  4. Row 10, `需要原型`, interactive — `/kenspc-prototype <brief> 4`. PASS:
     before any Write or Edit, the run asks whether to prototype the entry
     or stop, quoting `需要原型`; on "stop", no commit, and the brief's
     sha256 unchanged (ruling M12).
  5. Row 10, `需要原型`, cannot-ask — the same with the reminder. PASS: no
     question; the run stops, names the entry and the word, makes no
     commit, writes nothing, and the brief's sha256 is unchanged.
  6. Row 10, `open` with `Answer:` and `Prototype:` —
     `/kenspc-prototype <brief> 5`. PASS: the prototype-again question comes
     before any write; on "no", no commit and the brief's sha256 unchanged.
  7. Row 9, diagnose-bug interactively — `/kenspc-diagnose <the seeded
     bug>`; the task list confirmed; the exit answered "interactively".
     PASS: a `test: reproduce …` commit and a `docs: add task …` commit;
     the last message names the reproduction commit's hash and gives
     `git revert <that hash>`; no revert commit; HEAD is the task-document
     commit.
  8. Guards, in the repository: `bash scripts/check-all.sh --self-test`
     prints `guards run: 10` and ends with `self-tests run: 9`, every line
     PASS; the three by-hand mutations of Guard falsifiability, each with its
     exit 1 and its exit 0 after restoring; both
     `claude plugin validate --strict` runs pass.
  9. Text: `grep -n 'no notion of a failure that predates the run'` and
     `` grep -n 'Uncommitted `.gitignore` edits' `` each find one line in
     `plugins/kenspc/README.md`, and the 3.8.1 CHANGELOG entry holds both
     Known behavior bullets.
- Budget: set by the main session; an estimate is eight headless
  sessions (cases 1–7, case 2 resuming case 1) at about $12, case 2 and the
  diagnose-bug run the costliest.
- Independence: the acceptance record separates what the plugin's own runs
  produced — drafts, plans, commits, trace — from what the driver typed, and
  quotes every answer the driver gave where it was given (the approval, the
  gap-round answers, the gate answers, the task-list confirmation, the exit
  choice).
- Acceptance runs in a separate session and is filed under `docs/dry-runs/`
  as `batch-d-acceptance.md`, with the labels PASS / FAIL / OBSERVATION /
  Not exercised. The acceptance session records the evidence and a first
  reading of each FAIL and does not classify it; the main session
  classifies — plugin defect, behavior deviation, or observation, as the
  batch C record's § 3 does — and fixes a plugin defect in a separate
  session, never in a run's project; the affected case is then re-run.
- Dogfood note: `/kenspc-task` on this spec generates the Doc-sync task from
  the Documentation impact above. For the documents Steps 5.1–5.4 edit, the
  generated entries say "edited by Task <K>: verify it against the
  implementation instead of editing it again", as the template provides.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| A cannot-ask run still writes the plan, reading the reminder as overriding the new sentence | Medium | The branch opens with the same wording the reminder is tested against in Phase 1; case 1 checks for no Write and no Agent call; a run that writes is a finding for the main session to classify. |
| A long draft is cut short or summarized in the last message | Medium | "every section, none elided or summarized" in the text; case 1 checks the draft for every section. |
| The resumed approval is read as another cannot-ask turn and the run stops again | Low | The text says a later approving reply is the approval; case 2. |
| A cannot-ask `/kenspc-plan <free text>` still stops or improvises in Phase 1 Step 4's discussion | Medium | Out of scope (M8); the main session lists it as a roadmap candidate in its report to the user, who decides. |
| The cannot-ask and tier-3 exits of diagnose-bug leave the red commit unnamed | Medium | The README paragraph covers every ending (M7); the tier-3 brief records the test's commit; the main session lists both gaps as roadmap candidates in its report to the user, who decides. |
| The widened `answered` gate asks about an entry the user meant to re-prototype | Low | It asks rather than refuses; `Prototype:` alone under `needs prototype` does not trigger it (M1). |
| Check 6's extraction breaks when the ROLE paragraph is re-wrapped so the sentence ends mid-line | Low | The end is the first line ending in a period after the start line; a re-wrap that moves the period mid-line makes the extract longer, every copy then fails, and the exit message names the reference — a loud failure, not a silent pass. |
| A guard change makes `check-all.sh` count differently | Low | D8 keeps both counts; case 8 checks them. |
| The brief's `git diff` is read as evidence that a stop left it unchanged | Medium | sha256 before and after, with a positive control (M12). |
| The Prototype-line guard misses text added around the literal in one file | Low | Accepted (D11); the literal a reader copies is what is guarded. |

## Clarifications during implementation

Settled between the implementing session and the spec author (the main
session); each entry binds like the rulings above. Questions from the
implementing session arrive under a `## Questions for the spec author`
section appended to the end of this document (see Open Questions); each
answer is recorded here as `CL<n>` — a statement and the Step it affects —
and the answered question is removed from that section. The prefix is `CL`,
so a clarification cannot be read as one of the locked points D-1 to D-7 or
the architecture rows D1 to D16.

Rulings of 2026-09-26, after the `/kenspc-task-implement` run over
`docs/tasks/batch-d-unattended-guards-tasks.md` (implementation
`3a9344c..afc3deb`, review fixes `fc4d1e0..a1f2ee8`, verdict PASS with five
DEFERRED rows). CL1–CL6 answer the six questions the implementing session
raised in `69d8082`. All decided by the main session within the locked
design. CL1 and CL2 read D-3 past its words ("an entry named by number") by
its reason — an answer already in a brief that has no committed copy is not
replaced unasked — and CL2 edits a paragraph of Phase 3 that Step 2.1 did
not open, in a file this batch may change.

- CL1 — Step 2.1, amending M1 (question 1; E1, B2): the prototype-again
  question follows whichever entry the run takes — named by ENTRY, or taken
  with no ENTRY (the brief's only `` `needs prototype` `` entry, or, in a
  session that cannot ask, the first in document order). Such an entry that
  is `` `answered` `` or holds `Answer:` gets the question, and in a session
  that cannot ask the run stops with the entry unchanged, as for a named
  one. The bullet, the gates-table row, the plugin README's `prototype` row
  and Prototype path clause, the 3.8.1 CHANGELOG line, and release-checklist
  row 10 change together in one commit; row 10 gains the case "no ENTRY, the
  brief's only `needs prototype` entry holds `Answer:`: the question is
  asked; in a session that cannot ask the run stops and the brief's sha256
  is unchanged". Why: the entry a run takes without being named is the one
  the user looked at least, and its answer is the easiest to lose unasked.
- CL2 — Step 2.1 and Phase 3's "When nothing was built" paragraph, amending
  M1 (question 2; E2): option (b). After a "yes" to the prototype-again
  question, a later gate that ends in "nothing is built" leaves the entry
  unchanged — its `Answer:`, `Evidence:`, and Prototype line stay — and the
  final message gives the reason nothing was built. The prototype-again
  bullet gains that sentence; the "When nothing was built" paragraph exempts
  an entry that held `Answer:` when the run began; the plugin README and the
  3.8.1 CHANGELOG gain one sentence; release-checklist row 10 gains the
  criterion. No acceptance case is required for it: the gates that end in
  "nothing is built" after a "yes" need an in-app or feature-prototype
  setup, and the acceptance may record it as not exercised. Why: "yes"
  consents to replacing the answer with a new result, not with the absence
  of one, and the brief has no committed copy to restore it from.
- CL3 — Step 1.2, amending the test as D-2 and M6 word it (question 3; E4):
  in generate-plan, "holds `Answer:`" means an `Answer:` label with text
  after it. A label with nothing after it counts as no `Answer:`: the entry
  is a gap in the gap round and, in a session that cannot ask, is carried in
  the `open` form with the existing
  `From: <brief path>, entry <n>, status word answered, Answer: missing`
  line. No attempt is made to recognize placeholder text. The prototype
  skill's gate is unchanged — it asks whenever the label is present, since
  asking loses nothing. The plugin README, the 3.8.1 CHANGELOG, and
  release-checklist row 4 follow where they describe generate-plan's test.
  Why: an empty label gives a plan nothing to rest on, which is D-2's
  reason; whether some text is a placeholder is a guess the skill cannot
  check.
- CL4 — Step 5.4 and Testing Strategy (question 4; T5): yes. Row 4 gains:
  with a plan already at the target path, an approval given to a session
  that cannot ask writes the plan at the first free numeric suffix
  (`<name>-2.md`), the existing file's sha256 unchanged, and the final
  message names the new file. The acceptance folds it into case 1's approval
  resume, which carries the same reminder: before the resume the driver
  places a file at `docs/plans/<the brief's file name>` and records its
  sha256; when the run's target path turns out to be another name, the
  branch is recorded as not exercised, naming the path the run chose.
- CL5 — Step 5.4 and Testing Strategy (question 5; T6): yes to both. Row 10
  gains (a) a `` `needs prototype` `` entry holding `Prototype:` and no
  `Answer:` is built with no prototype-again question, in a session that
  cannot ask too; and (b) an entry with an unrecognized status word holding
  `Prototype:` and no `Answer:` gets the prototype-again question, and in a
  session that cannot ask the run stops with the brief's sha256 unchanged.
  The seed brief gains both entries. The acceptance runs (b); (a) builds a
  prototype and runs when the acceptance budget allows, otherwise it is
  recorded as not exercised.
- CL6 — Step 1.1, M4 (question 6; B4, applied in `f8aae69`): accepted. The
  existing-file branch in a session that cannot ask takes the first numeric
  suffix no file has (`<name>-2.md`, then `<name>-3.md`, …). Why: an earlier
  cannot-ask run for the same target leaves `<name>-2.md` behind, and the
  branch exists so that no file is overwritten unasked. diagnose-bug's
  conflict branch, outside the section this batch may edit, keeps naming
  only `<name>-2.md`; the main session lists it as a roadmap candidate.

Rulings of 2026-09-26, after the standalone `/kenspc-task-review` of the
batch (range `0128a2f..738fa22`, run
`.kenspc/runs/20260926-113521-changes/`, fixes `1155550..a278985`, verdict
PASS with nine DEFERRED rows). CL7 and CL8 settle six of them; the other
three are left unchanged, as recorded after CL8. All decided by the main
session within the locked design; CL7 widens CL2 by CL2's own reason and
edits sections of `prototype/SKILL.md` beyond those Step 2.1 opened.

- CL7 — Step 2.1, § Kind and location, Phase 2's Constraints, and Phase 3,
  amending CL2 (E1, B1, E2, R2, E3): the kept-answer rule is general, not
  tied to "nothing is built". An entry that held `Answer:` when the run
  began, taken for a new attempt after a "yes" to the prototype-again
  question, is rewritten only when the new attempt settles the question.
  Every other ending — nothing built, a built prototype whose evidence does
  not settle the question, a verdict the user does not give — leaves its
  `Answer:`, `Evidence:`, and Prototype line as they were, and the final
  message names the new attempt's commits, when it made any, and why the
  question was not settled. The one change such an entry can carry out of
  that run is a `Settled by:` derived in Phase 1 for an entry that had none,
  and the sentences that say it is left as it was say so. The
  prototype-again bullet states the rule once; Phase 3's unsettled rewrite
  and its "When nothing was built" paragraph each carry the exception; the
  gate sentences an interactive run can reach after a "yes" that say an
  entry "stays `needs prototype`" or "stays unsettled" (the feature
  prototype that needs the app's runtime, the in-app typecheck with no
  baseline, and the matching gates-table row) gain a short qualifier that
  points at the rule. The plugin README (the Prototype path clause and the
  feature-prototype Known behavior item) and the 3.8.1 CHANGELOG say it in
  one sentence each; the CHANGELOG's prototype bullet also says that a stop
  on an unrecognized status word in a session that cannot ask names the
  entry and quotes the word (`1155550`). Release-checklist row 10 gains the
  criterion for a built but unsettled attempt after a "yes". Why: CL2's
  reason — a "yes" consents to replacing the answer with a new answer, and
  an unsettled attempt yields evidence, not an answer — and one rule stated
  once cannot contradict the gate sentences that describe other entries.
- CL8 — Step 5.4 and Testing Strategy (T2, T3, T4): row 10's stop and
  cannot-ask-stop criteria for the unrecognized-word gate use an entry that
  holds no `Settled by:`, so the brief's unchanged sha256 also shows the
  gate came before the derived write; the acceptance seed's
  unrecognized-word entry carries no `Settled by:`. Row 4's existing-file
  criterion has both `<name>.md` and `<name>-2.md` in place and expects
  `<name>-3.md`, both existing files' sha256 unchanged; the acceptance
  places both before case 1's approval resume. Row 4 gains: when the user
  replies `answered` to the gap round's status question for an unrecognized
  entry and gives no answer text, the entry is not taken as settled input —
  it is asked for its answer again or carried in the `open` form with the
  `Answer: missing` line; the acceptance's interactive gap-round case gives
  that reply for the unrecognized entry, or records it as not exercised.

Left unchanged from the same review: E4 — check 6 and the Prototype-line
group test containment, so a file holding a drifted copy beside an intact
one passes; D10 and D11 chose containment, every file holds one copy
today, and the main session lists "exactly one copy" as a roadmap
candidate. B2 — the interactive exit states without condition that the
reproduction test fails; D13's wording stands, an intermittent
reproduction is rare, and the main session lists the qualifier as a roadmap
candidate. B3 — an unrecognized entry the gap round marks
`needs prototype` keeps its word in the brief; both skills' behavior is
ruled, and after `1155550` the prototype skill's unattended stop names the
entry and its word.

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
