# Batch D — Unattended Stops, Answered-Entry Checks, and Three Copy Guards — Task Document

## Context

Three stops an unattended run gets wrong get a defined answer, three copied
strings get a guard, and the documentation follows. generate-plan's
approval stop gains a branch for a session that cannot ask — the run ends
at the draft, printed in full, with nothing written, reviewed, or
committed, and a later reply that approves the draft continues it — and the
existing-file question on its approved path gains one too. generate-plan
takes an `` `answered` `` brief entry as settled input only when it holds
`Answer:`; one without is asked about in the gap round or carried into the
plan as `open`. The prototype skill asks before it touches a named entry
whose status word it does not recognize, and gives an entry that already
holds `Answer:` the prototype-again gate. diagnose-bug's interactive exit
names the reproduction commit and `git revert <hash>`.
`check-run-contract.sh` gains check 6 (the reviewer invariant sentence in
the plugin README, CLAUDE.md, and task-review's dispatch block, held against
the reviewers' ROLE), and `check-doc-sync-anchors.sh` gains the Prototype
line group and an exact count of the prototype skill's leftovers command.
Known behavior gains what a red reproduction test does to later review
runs, and what the one-time `.gitignore` commit takes with it.

Related plan: `docs/plans/batch-d-unattended-guards.md`. The plan is the
complete specification. Its locked design (D-1 to D-7) and its Design
decisions (M1–M13, D1–D16) are binding rulings; no ruling departs from the
draft's lean. Five rulings read a locked point beyond its literal words —
M1 (the `answered` gate for any named entry that holds `Answer:`), M4 (the
existing-file question's branch), M11 (README sentences for D-1 and D-2),
D9 (check 6 also reads task-review's dispatch copy), and D13 (the review-run
half-sentence in diagnose-bug's exit) — and every task follows the ruling.
Its Clarifications during implementation hold none yet.

The labels this document cites (D-n, M-n, D-n rows, "ruling") are pointers
into the plan for the implementer. None of them is copied into a skill file
(plan § Standing constraints; the pointer-label grep below).

Each task below cites its plan Step, which is the canonical source for what
to write; where the plan gives a paragraph "in substance", that paragraph is
the text to adapt. The criteria listed here are the local DONE bar.

Fixed forms. Every task that states one of these uses it exactly as written
here (plan § Fixed strings):

- Not-approved line: `Plan not written: awaiting approval.` — in English
  whatever the conversation language.
- Carried `answered` entry:
  `From: <brief path>, entry <n>, status word answered, Answer: missing`.
- Carried unrecognized entry (unchanged):
  `From: <brief path>, entry <n>, status word <the word, or none> not recognized`.
- Reviewer invariant sentence, compared whitespace-normalized, its reference
  the ROLE section of `plugins/kenspc/agents/requirements-reviewer.md`:
  `` Each reviewer is read-only on the working tree and writes only under `RUN_DIR`: its report at `RUN_DIR/angle-<n>.md`, and probe and temporary files under `RUN_DIR/scratch/angle-<n>/`. ``
- Prototype line:
  ``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` ``.
- Leftovers command, exactly twice in `prototype/SKILL.md`:
  `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`.
- Known behavior item title: ``**Uncommitted `.gitignore` edits.**``.
- Red-interval phrase: `no notion of a failure that predates the run`.
- CHANGELOG heading: `## 3.8.1 — unreleased`.
- Guard counts (unchanged): `guards run: 10`, `self-tests run: 9`.
- Cannot-ask wording: "In a session that cannot ask (a system reminder to
  work without stopping), …", as `diagnose-bug/SKILL.md` words it.
- Doc-sync heading: `### Task N: Doc-sync` (N the last task number).
- Dependency line: `Depends on: Task N`, a range `Task 1-<N>` (ASCII
  hyphen), or a comma-separated list.

Pointer-label grep (plan § Standing constraints). For every plugin file a
task edits — `plugins/kenspc/skills/generate-plan/SKILL.md`,
`plugins/kenspc/skills/prototype/SKILL.md`, and
`plugins/kenspc/skills/diagnose-bug/SKILL.md` — this command prints nothing:

```bash
grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\b[BCD]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>
```

It prints nothing on those three files at `0128a2f` and 184 lines on the
batch C spec (`git show 0128a2f^:docs/plans/batch-c-prototypes.md`), so it
can fail.

This is plugin revision work. The files are Markdown (three SKILL.md files,
the plugin README, CLAUDE.md, the CHANGELOG, the release checklist) and two
guard scripts. The repository has no test framework: "build / test / lint"
for each task is the guard suite. After each task, run the guard the task
names, then `bash scripts/check-all.sh`, which must exit 0 with
`guards run: 10` — capture its exit status on its own line, never through a
pipe (`bash scripts/check-all.sh > <file> 2>&1; rc=$?`), since a pipe
reports the last command's status, not the guard's. Tasks that edit a skill
file also run `claude plugin validate --strict ./plugins/kenspc`. Tasks 5
and 6 also run `bash scripts/check-all.sh --self-test`, which must print
`guards run: 10` and end with `self-tests run: 9`.

Constraints that apply to every task (plan § Standing constraints):

- No edit inside any byte-identity section, with no exception in this batch:
  the `canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`, and
  `canonical:verdict-shared` blocks; the code-craft canonical paragraphs;
  and the five reviewers' six shared sections. Task 5's check reads the
  reviewers' ROLE and task-review's dispatch block and edits neither.
- Zero diff outside the batch's files. After every task, this prints
  nothing:
  `git diff --stat 0128a2f HEAD -- plugins/kenspc/agents plugins/kenspc/shared plugins/kenspc/references plugins/kenspc/hooks plugins/kenspc/commands plugins/kenspc/skills/task-implement plugins/kenspc/skills/task-review plugins/kenspc/skills/generate-task plugins/kenspc/skills/generate-brief`.
  `diagnose-bug/SKILL.md` changes only between `## Exit` and
  `## Writing rules for the document`. The files this batch touches are
  `generate-plan/SKILL.md`, `prototype/SKILL.md`, `diagnose-bug/SKILL.md`
  (its Exit), `scripts/check-run-contract.sh`,
  `scripts/check-doc-sync-anchors.sh`, `CLAUDE.md`,
  `plugins/kenspc/README.md`, `plugins/kenspc/CHANGELOG.md`, and
  `docs/release-checklist.md` — not the root `README.md`,
  `docs/roadmap.md`, either manifest, or `scripts/check-all.sh`.
- No new skill, command, agent, CONTEXT key, or guard script.
- `effort:` frontmatter is unchanged in every file, and every skill keeps
  `version: 3.0.0`.
- No version bump: `version` in `plugins/kenspc/.claude-plugin/plugin.json`
  stays `3.8.0`. The CHANGELOG entry goes under `## 3.8.1 — unreleased`
  with no date. `docs/roadmap.md` is not edited: its six items leave in the
  release commit (plan § The release commit). No tag, no push.
- Rules are rationale-anchored ("Why: …" prose), with no `MUST` / `NEVER` /
  `CRITICAL`, no effort or reasoning tokens, and no model names
  (`bash scripts/check-no-model-names.sh` exits 0). A check written into a
  skill is in rubric form: what passing looks like, then the named ways it
  fails.
- Every question point this batch adds or reaches has a cannot-ask branch in
  the Fixed-forms wording: generate-plan's approval stop and its
  existing-file question, the gap round's question about an `answered`
  entry with no `Answer:`, and the prototype skill's new gate.
- Guards run under the bash 3.2 macOS ships (`/bin/bash`): no associative
  arrays (`declare -A`) or other bash-4-only syntax; new mutations use a
  literal awk replacement, not `sed -i`; the `set -euo pipefail` and
  `SCRIPT_DIR` / `REPO_ROOT` pattern stays.
- Code, comments, commit messages, and documents are in English.
- No task runs `rm -r` or `rm -rf`; the one exception is the guards' own EXIT
  traps, which remove the `mktemp -d` directories their self-tests create.
  A copy of the repository tree made by hand for a falsifiability check
  (Tasks 5 and 6) goes under `$TMPDIR` and is left there (plan § Testing
  Strategy). Anything else to be discarded is moved to
  `~/Projects/_smoke/.trash/<name>-<YYYYMMDD-HHMMSS>/` (created when
  missing). Nothing under `.kenspc/` is deleted.
- No task edits `docs/plans/batch-d-unattended-guards.md`. A task that finds
  a ruling contradicted by the code is marked BLOCKED with the contradiction
  named. After the run ends and Schema G is out, the orchestrating session
  (the one that ran `/kenspc-task-implement`) appends each such
  contradiction under a `## Questions for the spec author` section at the
  end of the plan (creating the section when missing) — one numbered entry
  per question, naming the Step it affects, what the repository shows, and
  what the plan says — commits nothing else, and stops; the spec author
  records the answer as `CL<n>` under the plan's
  `## Clarifications during implementation`.
- Each task is one conventional commit that stages only the files the task
  lists, together with the task's status update:
  - `fix(skills): …` for Tasks 1–4;
  - `feat(scripts): …` for Tasks 5 and 6;
  - `docs(claude-md): …` for Task 7;
  - `docs: …` for Tasks 8 and 11;
  - `docs(release): …` for Task 9;
  - `docs(changelog): …` for Task 10.

Dependency note: Tasks 1–4 (plan Phases 1–3) are independent of one
another; Tasks 1 and 2 both edit `generate-plan/SKILL.md` and `CLAUDE.md`,
in different sections, and are ordered only by the document. Task 5
(check 6) reads no sentence an earlier task changes, so it carries no
`Depends on`. Task 6 checks the prototype skill's final text
(`Depends on: Task 3`). Task 7 reads CLAUDE.md through after the four tasks
that edit it (`Depends on: Task 1, Task 2, Task 5, Task 6`). Tasks 8 and 9
document the behavior Tasks 1–4 build (`Depends on: Task 1-4`). Task 10,
the CHANGELOG, names every change the batch makes, the release checklist's
rows included, so it follows Task 9 (`Depends on: Task 1-9`); the plan lists
the CHANGELOG (Step 5.3) before the checklist (Step 5.4), and the order is
reversed here so the entry can describe the rows it names. Task 11, the
Doc-sync task, runs last and needs Tasks 1–10. It reconciles the documents
with what those tasks implemented and promotes their recorded decisions.

## Tasks

### Task 1: Add the cannot-ask branch to generate-plan's approval stop and existing-file question

**Status:** TODO

Plan Step 1.1 (D-1; rulings D1, D2, D3, M4, M10). In
`plugins/kenspc/skills/generate-plan/SKILL.md`, Phase 2 Step 3 only —
`effort: xhigh`, Phase 1, Phase 2 Steps 1–2, and Phase 3 stay as they are:

- After "Write only when the user explicitly approves the plan.", the
  paragraph plan Step 1.1 gives in substance: in a session that cannot ask
  (a system reminder to work without stopping), the run still stops here.
  Its last message holds the complete draft — every section of the draft
  after self-challenge, none elided or summarized — then the line
  `Plan not written: awaiting approval.`, and says how to go on: reply in
  this session approving the draft or asking for changes (a headless run
  resumes it with `claude -p --resume <session id> "<reply>"`), or run
  `/kenspc-plan` again in a session that can ask. Nothing is written,
  `plan-document-reviewer` is not dispatched, and nothing is committed. A
  later reply that approves the draft is the approval — in a headless run,
  the reply of the session that resumes this one — and the step then runs as
  written. Its Why: the written plan is the approved plan (Phase 3's
  reviewer commits it and generate-task decomposes it as agreed), so a run
  that writes it without approval makes the user's decision; under a
  reminder to work without stopping, with no branch at this stop, an
  unapproved plan has been written, reviewed, and committed on the current
  branch; the line stays in English so a driving session can test for it.
  The self-challenge (Step 2) still runs, since it asks the user nothing
  (ruling D3), which "the draft after self-challenge" already says.
- Item 1.c ("If a file already exists at the target path, ask the user
  whether to overwrite or create a new file") gains: in a session that
  cannot ask (a system reminder to work without stopping), create the file
  alongside with a numeric suffix (`<name>-2.md`) and say so in the final
  message. Why: an overwrite nobody chose can destroy a plan the user kept.

In `CLAUDE.md` § Writing Rules for Skill Content, the cannot-ask bullet:
the list of question points that share the wording ("the wording
diagnose-bug, generate-plan's Open Questions exit and gap-check,
generate-brief's question about what would settle a `needs prototype`
entry, and the prototype skill's gates share") gains generate-plan's
approval stop and its existing-file question.

**Files to modify:**
- `plugins/kenspc/skills/generate-plan/SKILL.md`
- `CLAUDE.md`

**Acceptance criteria:**
- Both new sentences open with "In a session that cannot ask (a system
  reminder to work without stopping)" and carry a Why. With the file's line
  breaks joined,
  `tr '\n' ' ' < plugins/kenspc/skills/generate-plan/SKILL.md | tr -s ' ' | grep -oF 'In a session that cannot ask (a system reminder to work without stopping)' | wc -l`
  prints 4 (2 at `0128a2f`).
- `grep -cF 'Plan not written: awaiting approval.' plugins/kenspc/skills/generate-plan/SKILL.md`
  prints 1, and the paragraph says the line stays in English.
- The approval paragraph names, in its own words: the complete draft
  (every section, none elided or summarized) before the line; both ways to
  go on, with `claude -p --resume <session id> "<reply>"` spelled out;
  the three things that do not happen (no file written, no
  `plan-document-reviewer` dispatch, no commit); and a later approving
  reply as the approval, after which the step runs as written.
- Item 1.c's branch names `<name>-2.md` and says the final message names
  the file.
- `git diff HEAD~1 -- plugins/kenspc/skills/generate-plan/SKILL.md` on this
  task's commit shows hunks only between `### Step 3: Write to file` and
  `## Phase 3: Verify via review agent`; `effort: xhigh` is unchanged.
- CLAUDE.md's cannot-ask bullet names generate-plan's approval stop and its
  existing-file question, and no other CLAUDE.md sentence changes in this
  commit.
- The pointer-label grep prints nothing on the skill,
  `grep -nE '\b(MUST|NEVER|CRITICAL)\b'` prints nothing on it (nothing at
  `0128a2f`), `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 2: Count an answered brief entry as settled only when it holds Answer:

**Status:** TODO

Plan Step 1.2 (D-2; rulings M5, M6, D4, D5, M10). In
`plugins/kenspc/skills/generate-plan/SKILL.md`, Phase 1 Step 1 parts 2 and
3 and Phase 2 Step 1's Open Questions element. Part 1 ("Open questions to
prototype", the exit) is unchanged: it still reads only the status word
`` `needs prototype` ``.

- Part 2, the gap list (rulings M5, D5), in substance: an `` `answered` ``
  entry that holds no `Answer:` — as the brief has it, or as the user marks
  an entry in the gap round — is a gap too: the gap round quotes it and asks
  for its answer, and the question that asks an unrecognized entry's status
  also asks, for `answered`, the answer — one question, one round, so the
  one-to-two-round limit is unchanged. The answer the user gives is settled
  input, as any gap-round answer is; an entry the rounds leave without one
  is carried in the `open` form. Why: a status word is one token that a hand
  edit, a translation, or a gap-round answer can set; an entry with no
  answer gives a plan nothing to rest on, and taking it as settled lets the
  plan assume an answer without saying so.
- Part 2's cannot-ask paragraph ("In a session that cannot ask …, no `open`
  entry enters the gap rounds …") gains: an `answered` entry with no
  `Answer:` is carried the same way, in the `open` form, its `From:` ending
  `status word answered, Answer: missing` (ruling D4).
- Part 3 (ruling M6): an `` `answered` `` entry that holds `Answer:` is
  settled input — `Answer:` makes it so, not the status word alone and not a
  `Prototype:` line alone. A plan that relies on one cites its prototype hash
  where the entry has a Prototype line, otherwise the entry itself
  (`<brief path>, entry <n>`). The Why keeps its reason (the brief may be
  deleted; the citation in the plan keeps the evidence reachable).
- Open Questions element: beside the unrecognized-word form, the line
  `From: <brief path>, entry <n>, status word answered, Answer: missing`
  for an `answered` entry carried without an answer, in the `open` form.

In `CLAUDE.md` § Subagent Review Architecture, the prototype path
paragraph: "The next generate-plan run reads the answered entry as settled
input" names `Answer:` as what makes it settled.

**Files to modify:**
- `plugins/kenspc/skills/generate-plan/SKILL.md`
- `CLAUDE.md`

**Acceptance criteria:**
- Part 2 lists the `answered`-without-`Answer:` gap — as the brief has it
  and as the user marks it in the gap round — with the one question that
  asks the status and, for `answered`, the answer, and its Why; part 2's
  cannot-ask paragraph carries such an entry in the `open` form with
  `status word answered, Answer: missing`.
- Part 3 names `Answer:` as the test (not the status word alone, not a
  `Prototype:` line alone) and the entry citation `<brief path>, entry <n>`
  for an entry with no Prototype line.
- `grep -cF 'From: <brief path>, entry <n>, status word answered, Answer: missing' plugins/kenspc/skills/generate-plan/SKILL.md`
  prints at least 1: the element's line is spelled exactly and not wrapped,
  as the unrecognized-word form beside it is not.
- `git diff HEAD~1 -- plugins/kenspc/skills/generate-plan/SKILL.md` on this
  task's commit changes no line of part 1 (from `1. **Open questions to
  prototype.**` up to `2. **Gap-check.**`) and no line of Phase 2 Step 3,
  and its hunks lie within Phase 1 Step 1 and Phase 2 Step 1's Open
  Questions element.
- CLAUDE.md's prototype path paragraph names `Answer:` as what makes an
  answered entry settled input, and no other CLAUDE.md sentence changes in
  this commit.
- The pointer-label grep and `grep -nE '\b(MUST|NEVER|CRITICAL)\b'` print
  nothing on the skill, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 3: Gate the prototype skill on an entry it cannot read or that already holds an answer

**Status:** TODO

Plan Step 2.1 (D-3; rulings M1, D6, D7), with the README and CHANGELOG
items D-3 ties to the same commit (plan Steps 5.2 and 5.3). In
`plugins/kenspc/skills/prototype/SKILL.md`, § The question, § The gates,
and Phase 1's Constraints only:

- § The question, the `answered` bullet (ruling M1), in substance: a named
  entry that is `` `answered` ``, or that holds `Answer:` whatever its
  status word: ask whether to prototype it again. The cannot-ask branch and
  its "the rewrite in Phase 3 for a run in which nothing was built does not
  apply to it" stay. Added: a `Prototype:` line with no `Answer:` under
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
  either write this phase makes (the entry appended for a question given as
  text, and a derived `Settled by:`) (ruling D7).
- § The gates: the `answered` row becomes "The named entry is `answered`,
  holds `Answer:`, or has an unrecognized status word and holds
  `Prototype:`" | "Prototype it again?" | "Stop; the entry unchanged". A new
  row: "The named entry's status word is not recognized, and it holds
  neither `Answer:` nor `Prototype:`" | "Prototype it, or stop" | "Stop; the
  entry unchanged".

In the same commit (D-3 ties the gates table, the README's gate list, and
the CHANGELOG together):

- `plugins/kenspc/README.md` § Skills, the `prototype` row: its list of what
  the skill asks about ("A location conflict, a connection your development
  configuration does not name, a new table or column on the development
  database, and an in-app UI prototype's location and uncommitted files are
  each asked about.") gains a named entry that already holds an answer and
  one whose status word the skill does not recognize, with what a session
  that cannot ask does: it stops, and the brief is unchanged.
- `plugins/kenspc/README.md` § Recommended Workflow, the Prototype path
  paragraph: `/kenspc-prototype` asks before it rewrites an entry whose
  status word it does not recognize. This is the second clause of plan
  Step 5.2's Prototype path item; Task 8 adds the first.
- `plugins/kenspc/CHANGELOG.md`: a `## 3.8.1 — unreleased` heading above
  `## 3.8.0 — 2026-09-26`, holding a `### Changed` section with one bullet:
  the prototype skill's gate for a named entry whose status word it cannot
  read (prototype it, or stop; a session that cannot ask stops with the
  entry unchanged), and the `answered` gate for any named entry that holds
  `Answer:`. Task 10 writes the intro and the rest of the entry around it.

**Files to modify:**
- `plugins/kenspc/skills/prototype/SKILL.md`
- `plugins/kenspc/README.md`
- `plugins/kenspc/CHANGELOG.md`

**Acceptance criteria:**
- Both bullets carry their cannot-ask branch in the Fixed-forms wording and
  their Why. With the file's line breaks joined,
  `tr '\n' ' ' < plugins/kenspc/skills/prototype/SKILL.md | tr -s ' ' | grep -oF 'In a session that cannot ask (a system reminder to work without stopping)' | wc -l`
  prints 12 (11 at `0128a2f`).
- The `answered` bullet covers an entry that holds `Answer:` whatever its
  status word, and says that `needs prototype` with `Prototype:` and no
  `Answer:` is prototyped again.
- The gates table has the widened `answered` row and the new row, each with
  "Stop; the entry unchanged" in its cannot-ask column.
- Phase 1's Constraints say the gates on the named entry come before both
  writes the phase makes.
- `git diff HEAD~1 -- plugins/kenspc/skills/prototype/SKILL.md` on this
  task's commit shows hunks only in Phase 1's Constraints paragraph,
  § The question, and § The gates.
- The two copied strings are untouched (Task 6 turns these into guard
  checks):
  `grep -cF 'Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>`' plugins/kenspc/skills/prototype/SKILL.md`
  prints 1, and
  `awk -v s='git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>' '{ r = $0; while ((i = index(r, s)) > 0) { n++; r = substr(r, i + length(s)) } } END { print n + 0 }' plugins/kenspc/skills/prototype/SKILL.md`
  prints 2.
- The README's `prototype` row names both new questions and the cannot-ask
  outcome; its Prototype path paragraph has the unrecognized-word clause;
  the CHANGELOG has `## 3.8.1 — unreleased` directly above
  `## 3.8.0 — 2026-09-26` with the one `### Changed` bullet; all three files
  are in this task's commit.
- The pointer-label grep and `grep -nE '\b(MUST|NEVER|CRITICAL)\b'` print
  nothing on the skill, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 4: Name the reproduction commit when diagnose-bug's user implements interactively

**Status:** TODO

Plan Step 3.1 (D-5; rulings D13, M7). In
`plugins/kenspc/skills/diagnose-bug/SKILL.md`, the "interactively" bullet of
§ Exit only. "Ending without a document", the "run" and cannot-ask bullets,
and tier 3 are unchanged (ruling M7).

- The bullet, in substance (ruling D13): on "interactively", stop; the task
  document stands, committed, for the user to work from. When Phase 1
  committed a reproduction test, the last message names that commit, says
  its test fails — and every review run in the repository reports the test
  run FAIL — until the fix lands, and gives `git revert <hash>` for backing
  the test out if the fix is not made; the skill does not revert it unasked.
  Why: the fix is now the user's to make, and until it lands the branch
  carries a failing test that nothing scheduled will turn green.

**Files to modify:**
- `plugins/kenspc/skills/diagnose-bug/SKILL.md`

**Acceptance criteria:**
- The bullet carries the condition (Phase 1 committed a reproduction test —
  a manual reproduction commits none), the commit named, the review-run
  consequence, `git revert <hash>`, that the skill does not revert it
  unasked, and a Why.
- `git diff 0128a2f -- plugins/kenspc/skills/diagnose-bug/SKILL.md` shows
  hunks only between `## Exit` and `## Writing rules for the document`, and
  within them only the "interactively" bullet; the "Ending without a
  document" paragraph is byte-identical to `0128a2f`.
- The pointer-label grep and `grep -nE '\b(MUST|NEVER|CRITICAL)\b'` print
  nothing on the skill, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 5: Add check 6 to check-run-contract.sh for the reviewer invariant sentence

**Status:** TODO

Plan Step 4.1 (D-4(a); rulings M3, M13, D8, D9, D10, M10). In
`scripts/check-run-contract.sh`:

- Main mode, after check 5: extract the reference from
  `plugins/kenspc/agents/requirements-reviewer.md` — the lines from the one
  that begins `Each reviewer is read-only on the working tree` through the
  first line that ends in a period — and normalize it: every run of spaces,
  tabs, CR, and LF becomes one space, and leading and trailing space is
  dropped. Each of `plugins/kenspc/README.md`, `CLAUDE.md`, and
  `plugins/kenspc/skills/task-review/SKILL.md`, normalized the same way,
  must contain it (a substring match). No start line in the reference file
  is exit 2 (the reference moved); a copy file that does not contain it is
  exit 1, naming the file and saying the copies follow the reviewers' ROLE
  sentence; a missing file is exit 2, as for the other checks. The OK line
  names the three copies. `--file PATH` still runs check 4 only.
- Header: "Five checks" becomes six, with a paragraph for check 6 — the
  four places the sentence lives (the five reviewers' ROLE, the canonical
  dispatch block of task-review and task-implement, the plugin README, and
  CLAUDE.md), the two families the other guards hold
  (`check-review-agent-drift.sh` the five ROLE sections,
  `check-canonical-dispatch.sh` the two dispatch blocks) while nothing tied
  one family to the other, and why the reference is extracted rather than
  copied into the guard (a literal in the guard would be one more copy to
  keep in step; with an extracted reference, rewording the ROLE sentence
  fails every copy not yet updated). The exit-1 and exit-2 lines gain their
  cases. The self-test paragraph names the two more files it copies and the
  new mutations, and states the number of mutations that must exit 1 as the
  script runs them, check 6's included (ruling M13): eighteen — the fourteen
  it runs at `0128a2f`, where the header says "eleven", plus check 6's four.
- Self-test: copies `plugins/kenspc/README.md` and `CLAUDE.md` too (seven
  files). A fixture-stale guard: the start line occurs once in the copied
  reference. Mutations, each a literal awk replacement on exactly one line
  (the existing `replace_literal` helper and its one-line rule), each
  restored after:
  - `writes only under` → `writes only below` in the README's copy, in
    CLAUDE.md's, in task-review's, and in the reference itself — each must
    exit 1;
  - `read-only on the working tree` → `read-only  on the working tree` (two
    spaces) in the README's copy — must exit 0 (whitespace-only).

  Then the reverted copy must exit 0. At `0128a2f` each of those literals
  occurs on exactly one line of its target file.

In `CLAUDE.md` in the same commit (ruling M10): § Repository scripts/'s
description of `check-run-contract.sh` gains check 6, and the Maintenance
note says that editing the reviewer invariant sentence in the plugin README
or CLAUDE.md, or the reviewers' ROLE, runs `check-run-contract.sh`.

**Files to modify:**
- `scripts/check-run-contract.sh`
- `CLAUDE.md`

**Acceptance criteria:**
- `bash scripts/check-run-contract.sh` exits 0 and prints the check-6 OK
  line naming the three copies; `bash scripts/check-run-contract.sh --self-test`
  exits 0.
- The `--file PATH` branch runs no check 6: it returns before check 1, as
  today.
- `grep -nE 'Five checks|eleven' scripts/check-run-contract.sh` prints
  nothing (two lines at `0128a2f`); the header says six checks, and the
  mutation count it states equals the number of must-exit-1 mutations the
  self-test runs (eighteen).
- Falsifiability, by hand: copy the repository's `scripts/`, `plugins/`,
  and `CLAUDE.md` under `$TMPDIR`; in the copy, change one word of the
  README's sentence — the copied guard exits 1 with a line naming
  `plugins/kenspc/README.md`; restore it — it exits 0. The commands and
  their output are recorded in the task's Implementation notes, and the
  copy is left under `$TMPDIR`.
- `/bin/bash scripts/check-run-contract.sh` and
  `/bin/bash scripts/check-run-contract.sh --self-test` exit 0 (macOS's bash
  3.2); `grep -n 'declare -A' scripts/check-run-contract.sh` prints nothing;
  the new mutations use no `sed -i`.
- CLAUDE.md's `check-run-contract.sh` description names check 6 and its
  three copies, and the Maintenance note names `check-run-contract.sh` for
  the README and CLAUDE.md copies and the reviewers' ROLE.
- The zero-diff command in the Constraints prints nothing (check 6 reads the
  agents and task-review, edits neither).
- `bash scripts/check-all.sh --self-test` prints `guards run: 10` and ends
  with `self-tests run: 9`, every guard and fixture PASS except the
  pre-existing `SKIP` for `check-review-agent-drift.sh`, which has no
  fixture.

---

### Task 6: Guard the Prototype line and the leftovers command's count in check-doc-sync-anchors.sh

**Status:** TODO

Depends on: Task 3

Plan Step 4.2 (D-4(b), D-4(c); rulings M9, M10, D8, D11, D12). In
`scripts/check-doc-sync-anchors.sh`:

- `ANCHOR_CHECKS` gains two single-quoted entries — single quotes because
  the literal holds backticks — the Prototype line's full literal with
  `plugins/kenspc/skills/generate-brief/SKILL.md` and with
  `plugins/kenspc/skills/prototype/SKILL.md`. The literal holds no `|`, so
  the first `|` still splits each entry.
- One exact-count check: the literal
  `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`
  occurs exactly 2 times in `plugins/kenspc/skills/prototype/SKILL.md`,
  counted by occurrence (an awk `index` loop), not by line. Any other count
  is exit 1, printing the count found and why the two copies must agree:
  the start snapshot and the Exit compare their two lists path by path.
- Header: an anchor guard for the planning chain — presence for five
  anchors across eleven files, and one exact count; the new group listed
  under the open-question path; the count check described; the sentence
  about README.md and CLAUDE.md says the reviewer invariant sentence there
  is checked by `check-run-contract.sh` (check 6), and the rest of their
  prose by no guard. The drift message names the fifth anchor; the success
  line says "all five anchors"; a second OK line reports the count.
- Self-test: the copied files stay eleven (both new entries name files
  already copied). Fixture-stale guards: the Prototype line present in the
  copied `prototype/SKILL.md`; the leftovers literal occurring twice in it.
  Mutations, each restored after:
  - the existing `Doc-sync` rename in the task example (exit 1);
  - `` `<location>`, removed in the next commit`` → `` `<location>`, removed in a later commit``
    in `prototype/SKILL.md` (exit 1);
  - the first occurrence alone of the leftovers literal, with
    `--ignored=matching` → `--ignored` (exit 1; `--ignored=matching` is on
    two lines of the file, so the replacement touches the first only);
  - a third copy of the literal appended to the file (exit 1).

  Then the reverted copy must exit 0. The new mutations use a literal awk
  replacement; the existing `sed -i.bak` stays. The header's self-test
  paragraph names the new mutations.

In `CLAUDE.md` in the same commit (ruling M10):

- § Repository scripts/'s description of `check-doc-sync-anchors.sh` says
  five anchors, two on the open-question path (`needs prototype`; the
  Prototype line in generate-brief and prototype), and the exact-count check
  on the leftovers command; its "README.md and CLAUDE.md are deliberately
  outside it" stays, true for this guard.
- § Non-Goals' "`check-doc-sync-anchors.sh` guards only the
  `needs prototype` status word across the three files, not this line"
  becomes a sentence saying the guard holds the line in both files; the rule
  that a change to the line updates both files in the same commit stays.
- The Maintenance note says that editing the Prototype line or the
  leftovers command runs `check-doc-sync-anchors.sh`.

**Files to modify:**
- `scripts/check-doc-sync-anchors.sh`
- `CLAUDE.md`

**Acceptance criteria:**
- `bash scripts/check-doc-sync-anchors.sh` exits 0 and prints both OK lines
  (the "all five anchors" line and the count line);
  `bash scripts/check-doc-sync-anchors.sh --self-test` exits 0.
- `grep -niE 'all four anchors|separate roadmap item' scripts/check-doc-sync-anchors.sh`
  prints nothing (two lines at `0128a2f`); the header states five anchors
  across eleven files and one exact count, and lists the Prototype line
  group under the open-question path.
- Falsifiability, by hand, on a copy of the repository's `scripts/` and
  `plugins/` under `$TMPDIR`: editing the Prototype line in the copied
  `prototype/SKILL.md` makes the copied guard exit 1 with a line naming that
  file; editing one of the two leftovers commands makes it exit 1 reporting
  the count 1; each restored makes it exit 0. The commands and their output
  are recorded in the task's Implementation notes, and the copy is left
  under `$TMPDIR`.
- `/bin/bash scripts/check-doc-sync-anchors.sh` and
  `/bin/bash scripts/check-doc-sync-anchors.sh --self-test` exit 0 (macOS's
  bash 3.2); `grep -n 'declare -A' scripts/check-doc-sync-anchors.sh`
  prints nothing; the new mutations use no `sed -i`.
- ``grep -n 'guards only the `needs prototype` status word' CLAUDE.md``
  prints nothing (one line at `0128a2f`); CLAUDE.md's guard description
  names five anchors and the exact count, and the Maintenance note names
  `check-doc-sync-anchors.sh` for the Prototype line and the leftovers
  command.
- `bash scripts/check-all.sh --self-test` prints `guards run: 10` and ends
  with `self-tests run: 9`, every guard and fixture PASS except the
  pre-existing `SKIP` for `check-review-agent-drift.sh`.

---

### Task 7: Read the repository CLAUDE.md through against the batch

**Status:** TODO

Depends on: Task 1, Task 2, Task 5, Task 6

Plan Step 5.1 (rulings M10, D8). Tasks 1, 2, 5, and 6 made CLAUDE.md's four
edits in their own commits, so no commit left it contradicting the files
beside it. This task reads `CLAUDE.md` top to bottom against those files and
makes no further edit unless the read-through finds a sentence the four
missed; such a sentence is fixed here and named in the commit message. Guard
counts are unchanged (ruling D8), so § Repository scripts/' "Nine of the
guards" paragraph and every stated count stay as they are. When the
read-through finds nothing, the commit holds only this task's status update
and Implementation notes.

**Files to modify:**
- `CLAUDE.md` (only when the read-through finds a sentence the four edits
  missed)

**Acceptance criteria:**
- Every guard description in § Repository scripts/ agrees with its
  script's header: `check-run-contract.sh` six checks, check 6 with its
  three copies; `check-doc-sync-anchors.sh` five anchors across eleven files
  and one exact count.
- The cannot-ask bullet in § Writing Rules for Skill Content names every
  question point that has the branch: diagnose-bug's, generate-plan's Open
  Questions exit, gap-check, approval stop, and existing-file question,
  generate-brief's question about what would settle a `needs prototype`
  entry, and the prototype skill's gates.
- The prototype path paragraph names `Answer:` as what makes an answered
  entry settled input; § Non-Goals says `check-doc-sync-anchors.sh` holds
  the Prototype line in both files; the Maintenance note names
  `check-run-contract.sh` and `check-doc-sync-anchors.sh` for the copies
  they now hold.
- `git diff 0128a2f -- CLAUDE.md` changes no guard count and leaves the
  "Nine of the guards" paragraph as it is; the file reads top to bottom
  without a contradiction about guard or anchor counts.
- The Implementation notes list each sentence checked, and either the
  missed sentence fixed (also named in the commit message) or "none found".
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`.

---

### Task 8: Document the batch's behavior in the plugin README

**Status:** TODO

Depends on: Task 1-4

Plan Step 5.2 (D-5, D-6; rulings M2, M11, D14). In
`plugins/kenspc/README.md`:

- § Skills, the `generate-plan` row: one sentence — in a session that
  cannot ask, the run stops at the draft, printed in full, with no file
  written, no review, and no commit, until a later reply approves it.
- § Recommended Workflow, the Prototype path paragraph: an `answered` entry
  is settled input for `/kenspc-plan` only when it holds `Answer:`, and one
  without is asked about in the gap round or carried into the plan as
  `open`. Task 3's clause on unrecognized status words stays.
- § Known behavior, "Red interval after a diagnosis": its last sentence
  says the skill names the commit and gives `git revert` when you implement
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
  make its unmutated copy pass first, so it is reported as not made (ruling
  M2: conditional, since the copy's test selection is the agent's). Land the
  fix, or revert the reproduction commit, before a review whose verdict you
  need.
- § Known behavior, a new item directly after "Uncommitted fixes" (ruling
  D14), in substance: ``**Uncommitted `.gitignore` edits.**`` The one-time
  commit that adds `.kenspc/` to `.gitignore` (see Run directory) stages and
  commits the whole file as it stands in your working tree, so an edit to
  `.gitignore` you had not committed — staged or not — goes into
  `chore: ignore kenspc run directory` with the `.kenspc/` line.
  `/kenspc-task-review`, `/kenspc-task-implement`'s review phase, and
  `/kenspc-diagnose` when it probes make that commit on their first run in a
  repository that does not yet ignore `.kenspc/`. Commit or stash your
  `.gitignore` edits first, or split that commit afterwards.
- The `prototype` row (Task 3's edit) is not edited again.

**Files to modify:**
- `plugins/kenspc/README.md`

**Acceptance criteria:**
- `grep -c 'no notion of a failure that predates the run' plugins/kenspc/README.md`
  prints 1, and ``grep -c 'Uncommitted `.gitignore` edits' plugins/kenspc/README.md``
  prints 1 (both 0 at `0128a2f`).
- The new item is the next Known behavior item after "Uncommitted fixes"
  and comes before "Red interval after a diagnosis"; it names the three
  entry points that make the one-time commit and the subject
  `chore: ignore kenspc run directory`.
- The red-interval paragraph's mutation sentence is conditional on the
  copy running the reproduction test, not the unconditional form; its last
  sentence names the interactive exit beside "ends without a document".
- The `generate-plan` row's sentence and the Prototype path paragraph's
  `Answer:` clause are present, and Task 3's clause is still there.
- Every sentence about the three changed behaviors agrees with the skill
  text Tasks 1–4 wrote (generate-plan Phase 2 Step 3 and Phase 1 Step 1
  parts 2–3, prototype § The question, diagnose-bug § Exit).
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`.

---

### Task 9: Add the batch's cases to release-checklist rows 4, 9, and 10

**Status:** TODO

Depends on: Task 1-4

Plan Step 5.4 (ruling D16). In `docs/release-checklist.md`, additions to
three rows — no new row, no renumbering, and the pre-flight counts stay
`guards run: 10` and `self-tests run: 9`:

- Row 4 (`/kenspc-plan`): in a session that cannot ask, the run stops at the
  draft — its last message holds the complete draft and the line
  `Plan not written: awaiting approval.`, and the trace shows no Write, no
  Agent call, and no commit (HEAD and `git status --porcelain` unchanged);
  resuming it with a reply that approves the draft writes the plan,
  dispatches `plan-document-reviewer`, and commits; a brief entry marked
  `` `answered` `` with no `Answer:` is quoted and asked about in the gap
  round, and in a session that cannot ask it appears in the draft's Open
  Questions in the `open` form with
  `From: <brief path>, entry <n>, status word answered, Answer: missing`.
- Row 9 (`/kenspc-diagnose`): on "interactively", after a
  `test: reproduce` commit, the last message names that commit and gives
  `git revert <hash>`, and no revert is made.
- Row 10 (`/kenspc-prototype`): a named entry whose status word is not
  recognized is asked about before anything is written — prototype it, or
  stop — and a named entry that holds `Answer:` gets the prototype-again
  question; in a session that cannot ask, either stops with no commit and
  the brief's sha256 unchanged.

**Files to modify:**
- `docs/release-checklist.md`

**Acceptance criteria:**
- `grep -c 'Plan not written: awaiting approval.' docs/release-checklist.md`
  prints 1 and
  `grep -cF 'From: <brief path>, entry <n>, status word answered, Answer: missing' docs/release-checklist.md`
  prints 1, both in row 4 (both 0 at `0128a2f`).
- Row 9 has the interactive-exit addition, and row 10 both gate additions,
  with "brief unchanged" judged by the brief's sha256, not by `git diff`
  (the brief is untracked, so `git diff` prints nothing whatever a run did
  to it).
- `grep -cE '^\| [0-9]+ \|' docs/release-checklist.md` prints 11, as at
  `0128a2f`; `git diff 0128a2f -- docs/release-checklist.md` touches only
  rows 4, 9, and 10, and the pre-flight block and prose still say
  `guards run: 10` and `self-tests run: 9`.
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`.

---

### Task 10: Write the 3.8.1 CHANGELOG entry

**Status:** TODO

Depends on: Task 1-9

Plan Step 5.3 (D-5, D-6, D-7; rulings D15, M13). In
`plugins/kenspc/CHANGELOG.md`, under the `## 3.8.1 — unreleased` heading
Task 3 created, keeping Task 3's `### Changed` bullet:

- Intro paragraph: batch D; what changes, in one paragraph; no new command,
  skill, agent, or CONTEXT key, so a patch release; guard counts unchanged;
  the release smoke is the batch's acceptance record, which the release
  commit names (the record does not exist yet).
- `### Changed`, beside Task 3's bullet:
  - generate-plan's approval stop in a session that cannot ask: the draft
    printed in full, `Plan not written: awaiting approval.`, no file, no
    review, no commit, and approval by a later reply — with its source: the
    batch C acceptance's F1, where such a run wrote, reviewed, and committed
    an unapproved plan, while the 3.8.0 sentence "a session that cannot ask
    still writes the plan only on approval" described the text, which that
    run did not follow;
  - the existing-file question's cannot-ask branch (`<name>-2.md`);
  - `answered` entries settled only with `Answer:`, the gap-round question,
    and the carried `From:` form;
  - diagnose-bug's interactive exit;
  - the two guards' new checks (check 6; the Prototype line group; the
    leftovers count), counts unchanged, and `check-run-contract.sh`'s header
    now stating the number of self-test mutations it runs (it said eleven
    where it ran fourteen);
  - release-checklist rows 4, 9, and 10; CLAUDE.md and the plugin README.
- `### Known behavior`: the red interval's effect on review runs and on
  mutation checks; the one-time `.gitignore` commit takes the whole file,
  behavior unchanged.
- The heading keeps `unreleased`; the date is filled at release.

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`

**Acceptance criteria:**
- The entry, directly above `## 3.8.0 — 2026-09-26`, holds the intro,
  `### Changed`, and `### Known behavior`, in that order, under the heading
  `## 3.8.1 — unreleased`; Task 3's bullet is still in `### Changed`.
- `### Changed` spells `Plan not written: awaiting approval.` exactly,
  names every item listed above, and records the stale header count
  (eleven where the script ran fourteen).
- `### Known behavior` has both bullets.
- Every behavior the entry names matches the skill and script text as
  committed by Tasks 1–6 and the checklist rows of Task 9.
- `grep '"version"' plugins/kenspc/.claude-plugin/plugin.json` still shows
  `3.8.0`.
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`.

---

### Task 11: Doc-sync

**Status:** TODO

Depends on: Task 1-10

Bring the documents below in line with what Tasks 1-10 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` § Writing Rules for Skill Content (the cannot-ask list),
  § Subagent Review Architecture (the prototype path paragraph; the
  Maintenance note), § Repository scripts/ (`check-run-contract.sh`,
  `check-doc-sync-anchors.sh`), § Non-Goals (the Prototype line sentence) —
  the new cannot-ask points, `Answer:` as what settles an answered entry,
  check 6, the five anchors and the exact count (plan Steps 1.1, 1.2, 4.1,
  4.2, 5.1); edited by Tasks 1, 2, 5, and 6 and read through by Task 7:
  verify it against the implementation instead of editing it again.
- `plugins/kenspc/README.md` § Skills (the `generate-plan` and `prototype`
  rows), § Recommended Workflow (the Prototype path paragraph), § Known
  behavior ("Red interval after a diagnosis"; the new "Uncommitted
  `.gitignore` edits" item) (plan Steps 2.1, 5.2); edited by Tasks 3 and 8:
  verify it against the implementation instead of editing it again.
- `plugins/kenspc/CHANGELOG.md` — the `## 3.8.1 — unreleased` entry (plan
  Steps 2.1, 5.3); edited by Tasks 3 and 10: verify it against the
  implementation instead of editing it again.
- `docs/release-checklist.md` — rows 4, 9, and 10; pre-flight unchanged
  (plan Step 5.4); edited by Task 9: verify it against the implementation
  instead of editing it again.
- `docs/roadmap.md` — items 5, 10, 11, 13, 14, and 15 leave and the rest are
  renumbered (plan D-7); that change is made in the release commit, outside
  this task document: leave it to the release commit.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-10. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-10 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).

---

## Notes

- The plan's Documentation impact records four documents as unaffected:
  the root `README.md`, `docs/dry-runs/README.md`,
  `plugins/kenspc/references/plan-document-example.md`, and
  `plugins/kenspc/references/task-document-example.md`. No task edits them.
- Edit the plugin's skill files in a session started without `--plugin-dir`
  (CLAUDE.md § Test the plugin locally): a `--plugin-dir` session treats
  those files as the definitions it is running, and edits to them have been
  refused there.
- After the last task, the batch's mechanical check is the release
  checklist's pre-flight block — the effort-override diff (unchanged), both
  `claude plugin validate --strict` runs, and
  `bash scripts/check-all.sh --self-test` with `guards run: 10` and
  `self-tests run: 9` — together with the zero-diff command in the
  Constraints and the pointer-label grep on the three skill files.
  Acceptance of the live chain runs in a separate session (plan § Testing
  Strategy) and is filed as `docs/dry-runs/batch-d-acceptance.md`.
- The release commit (plan § The release commit) is not a task here: it
  moves `plugin.json` to 3.8.1, dates the CHANGELOG heading, and takes the
  six roadmap items out; no tag.
