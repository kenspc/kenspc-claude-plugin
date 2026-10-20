# Merge Danger Section — Task Document

## Context

Add a `Merge danger` section to the three reports the user reads before
letting a batch out — task-implement's Schema G, task-review's Schema F, and
the autopilot's final message — built from one canonical block,
`canonical:merge-danger`, held byte-identical by a new guard. generate-task
starts writing a `Related plan:` line so the review skills can read the
plan's Risks. The plan's Technical Approach, "The definition" in particular,
is the specification of the block's content; each task below names the parts
it implements.

Related plan: `docs/plans/merge-danger-plan.md`

Dependency note: Tasks 2 and 3 depend on Task 1 (the block is written once,
then copied); Task 5 depends on Tasks 1-3; Task 6 (Doc-sync) depends on
Tasks 1-5. Task 4 is independent.

Every task edits files under `plugins/` or `scripts/`, so each runs
`bash scripts/check-all.sh` before its commit (AGENTS.md § Checks). Rules
are written as rationale-anchored prose, each with its "Why: ..." (AGENTS.md
§ Editing skill and agent content).

## Tasks

### Task 1: task-review — the canonical block, Schema F, and the range rules

**Status:** DONE

**Implementation notes:**
- Decisions:
  - The block carries the plan's rendered example (below its rules, headed
    "A rendered section, below its heading:") without the heading line.
    Why: the nested row shape is hard to hold from prose alone, and the
    heading level differs by carrier (`##` in Schema F and G, `###` in the
    autopilot's User report).
  - The block names "the carrier" once as "the skill that carries this
    block" and lets the carrier override the Reading commands "for a range
    that ends at the working tree". Why: task-review's `Mode: uncommitted`
    reads the file list from `git status --porcelain -uall`, which the
    block's `git diff --name-status <range>` cannot express, and the block
    must stay skill-neutral.
  - The `Count:` line counts rows, the catch-all among the `two-way` ones,
    and the catch-all is written even over zero files. Why: the plan's
    example counts it (2 two-way with one ordinary two-way row), and a
    missing last row would read as one never checked.
  - Header layout follows the plan's example: Range, Deployment document,
    and Plan on one line separated by ` · `, `Count:` on its own line.
  - The range-and-plan rules sit outside the block, just above it, in a
    `**The `## Merge danger` range and plan.**` paragraph; the uncommitted
    header reads `Range: <Base sha> to the working tree (uncommitted, the
    fixes included)`, a form the plan left open.
  - The "task" run's `<how chosen>` reads `since the task document was
    added`, the plan example's wording.
- Changes/tradeoffs:
  - Each rule got its own Why, including two the plan states without one
    (the one-step definition, the empty-range line); the instruction-files
    definition sentence is not repeated inside the block, since each
    carrier already holds it.
  - The empty-range line follows the report's language (the fixed-English
    list is the heading, the labels, and the signal names only).
- Test map: none (no behavior added or altered) — the change is skill
  prose; its byte-identity, anchors, and placement are held by Task 5's
  `scripts/check-merge-danger-canonical.sh`, and `bash scripts/check-all.sh`
  exits 0.

File: `plugins/kenspc/skills/task-review/SKILL.md`.

1. Write the `canonical:merge-danger` block, delimited by
   `<!-- canonical:merge-danger:start -->` and
   `<!-- canonical:merge-danger:end -->`, in Step 8, between the paragraph
   after the Schema F template ("Render every section above in full…") and
   `#### Verdict determination`. It holds every rule of the plan's
   "The definition", each with its Why, worded skill-neutrally (it names
   "the run's range" and "the plan the carrier names", never task-review's
   own terms), since Tasks 2 and 3 copy it unchanged:
   - Inputs: the run's range, named by the carrier outside the block; the
     deployment document — the one the project's instruction files name,
     otherwise `docs/deployment.md` — whose `## Migrations` and
     `## Rollback` sections answer the undo question and whose named paths
     are signals; the plan's section whose heading begins `## Risks`.
   - The eight signals with their fixed English names — `schema`,
     `removal`, `contract`, `config`, `dependency`, `outside-write`,
     `deploy-doc`, `plan-risk` — what each is read from and matches, and
     which are path signals and which content signals.
   - Reading: `git diff --name-status <range>`, then
     `git diff -U0 <range> -- <path>` file by file; a file whose diff was not
     read, for any reason, goes in an `unclear` row, never a `two-way`.
   - Labels: `two-way` (one `git revert`, or a discard of an uncommitted
     change, plus the project's usual release restores the prior state, no
     data lost, nobody outside the team needing to act), `one-way`,
     `unclear` (the row names the missing evidence).
   - Rows: one per change that matched a signal, not one per file — a
     change spanning several files is one row listing them all (the plan's
     Noise risk); the label and the change in plain words; the three
     answers in the report's language (what users see or do, undo in one
     step and why, who a failure reaches — this machine only, the team, the
     product's users, or people and systems outside it); one short
     technical line; `Evidence:` with signal names and each `file:line`. A
     signal-matched row without a `file:line` is not written; an `unclear`
     row for unread files or an undetermined range names the files or the
     cause instead.
   - Catch-all: the last row, `two-way`, the file count, the range, and each
     signal's count over its files, path signals then content signals.
   - Header: `Range: <range> (<how chosen>)`,
     `Deployment document: <path | not found>`,
     `Plan: <path | <path> (not found) | none named>`,
     `Count: <n> one-way, <u> unclear, <m> two-way`.
   - Fixed in English whatever the report's language: the heading
     `Merge danger`, the three labels, the signal names; everything else
     follows the report's language.
   - Empty range: the one line `none — the range holds no change`.
   - Not a gate: the section changes no verdict and asks nothing.
2. Add `## Merge danger` to the Schema F template between `## Verdict` and
   `## Next steps`, with a parenthetical pointing at the block.
3. Outside the block, task-review's range and plan rules (plan, "Each
   carrier"):
   - "task" run: `<the oldest commit that added TASK_FILE>..HEAD` at render
     time, found with
     `git log --diff-filter=A --reverse --format=%H -- <TASK_FILE> | head -n 1`;
     no such commit → header `Range: not determined — no commit added the
     task document` and one `unclear` row; the plan is the task document's
     `Related plan:` path (repository-relative), `none named` without the
     line, `<path> (not found)` when the path is absent at HEAD.
   - "changes" run, `Mode: commits`: from the first SHA of
     `change-set.md`'s `Range:` to HEAD at render time, the header's
     `<how chosen>` naming the recorded range and
     `to HEAD, the fix commits included`.
   - "changes" run, `Mode: uncommitted`: `Base:` against the working tree;
     the file list from `git -c core.quotePath=false status --porcelain -uall`
     with `.kenspc/` paths dropped; tracked files read with
     `git diff -U0 <Base> -- <path>`, untracked files whole.
   - Paths named in CUSTOM_INSTRUCTIONS do not narrow the section; a
     "changes" run's plan is `none named`.

**Acceptance criteria:**
- The block exists once in the file, between its two markers, between the
  "Render every section above in full…" paragraph and
  `#### Verdict determination`.
- The block contains all eight signal names, the Reading rule, the three
  labels with the one-step definition, the row, catch-all, header, and
  empty-range formats, the fixed-English rule, and the not-a-gate rule, each
  rule with a Why.
- The row rule states one row per change, with a change spanning several
  files listing them all in that one row.
- The block names no task-review-specific term (`REVIEW_SCOPE`,
  `change-set.md`, `Schema F`, `TASK_FILE`), so it reads true in all three
  carriers.
- In the Schema F template, `## Merge danger` sits after `## Verdict` and
  before `## Next steps`.
- The range rules outside the block cover a "task" run (with and without a
  commit that added the document), `Mode: commits` to HEAD, and
  `Mode: uncommitted` with untracked files.
- `bash scripts/check-all.sh` exits 0.

---

### Task 2: task-implement — the copied block, Schema G, and the range rule

**Status:** DONE

**Implementation notes:**
- Decisions:
  - The block was copied mechanically (extracted from task-review by its
    markers and spliced in with awk) rather than retyped, and checked with
    `diff` of the two extractions, which prints nothing.
  - The range-and-plan paragraph sits above the block, as in task-review,
    and adds a Why for rendering under BLOCKED: the commits earlier runs
    made still leave with the document.
- Changes/tradeoffs:
  - The Verdict determination's BLOCKED bullet now says Merge danger is
    still rendered, since it described the sections a BLOCKED report keeps.
  - The block's first paragraph had one over-long line left by Task 1's
    last wording edit; it is re-wrapped in both carriers in this commit
    (task-review's copy is touched for that only), so the copies stay
    byte-identical.
- Test map: none (no behavior added or altered) — skill prose; the block's
  byte-identity with task-review and the Schema G placement are held by
  Task 5's `scripts/check-merge-danger-canonical.sh`.

Depends on: Task 1

File: `plugins/kenspc/skills/task-implement/SKILL.md`.

1. Copy Task 1's block, markers included, byte for byte into Step 4,
   between the paragraph after the Schema G template ("Render every section
   above in full…") and `#### Verdict determination`.
2. Add `## Merge danger` to the Schema G template between `## Verdict` and
   `## Next steps`, and state that it is rendered when the verdict is
   BLOCKED too (where Code Review, Fixes, and Verification are omitted).
3. Outside the block, the range and plan rule, worded as task-review's
   "task" run rule from Task 1: `<the oldest commit that added
   TASK_FILE>..HEAD` at render time, the not-determined case, and the plan
   from the `Related plan:` line with its `none named` and `(not found)`
   forms.

**Acceptance criteria:**
- `diff` of the block extracted from this file and from
  `plugins/kenspc/skills/task-review/SKILL.md` (markers to markers) prints
  nothing.
- In the Schema G template, `## Merge danger` sits after `## Verdict` and
  before `## Next steps`, and the text says it is rendered under a BLOCKED
  verdict.
- The range rule names the oldest commit that added TASK_FILE and the
  not-determined case.
- `bash scripts/check-all.sh` exits 0.

---

### Task 3: autopilot — the copied block and its three places

**Status:** DONE

**Implementation notes:**
- Decisions:
  - The section is written in the User report's language (the
    conversation's), since the `_logs` file is what the User report's
    `### Merge danger` subsection renders; the reviewer report carries only
    the English count field.
  - The autopilot's header `<how chosen>` reads
    `the batch, baseline to last commit`, and an empty range records zero
    counts on the state-file line, so the reviewer field always has three
    numbers — two forms the plan left open.
  - The final-gate row of the gates table carries the count in its Asks
    column, worded "no question", since the gate asks nothing and the
    cannot-ask column already ends the run with the two reports.
- Changes/tradeoffs:
  - § Exit's first sentence also names the User report's `Merge danger`
    subsection beside its rulings list, since it lists what the final
    message holds.
  - The reviewer-report prose gains a short paragraph after the
    `Main-session rulings` paragraph, with a Why, rather than a clause in
    an existing paragraph.
  - The carrier's `**Merge danger.**` paragraph is followed by the block,
    whose own first paragraph also opens `**Merge danger.**`; left as is,
    since the block must stay byte-identical and the task names the
    carrier paragraph's label.
- Test map: none (no behavior added or altered) — skill prose; the block's
  byte-identity and the reviewer-report template's `- Merge danger:` line
  are held by Task 5's `scripts/check-merge-danger-canonical.sh`.

Depends on: Task 1

File: `plugins/kenspc/skills/autopilot/SKILL.md`.

1. In Phase 4, between "The batch's temp entries" and "The reports", add a
   `**Merge danger.**` paragraph followed by Task 1's block, copied byte for
   byte. The paragraph says: once the temp entries are removed and before
   the reports, the main session builds the section over
   `<baseline sha>..<last sha>`, with the spec as the plan read by
   `git show <hash>:<path>` (the reviewer report's Spec line) and the
   deployment document read at the last sha; it writes the section to
   `<workspace>/_logs/<batch>-merge-danger.md` and the state-file line
   `merge danger: <n> one-way, <u> unclear, <m> two-way — <that path>`;
   both reports are built from these, with the Why (a compacted
   conversation; the file is what survives). It also states that the
   batch's own documents S6's removal or release commit `git rm`s — a spec
   committed before the baseline, a tracked brief — match no signal and are
   named in the catch-all row, with the Why from the plan.
2. Phase 4's **Inputs** and **DONE when** name the file and the state-file
   line.
3. § The state file: add the `merge danger:` line to the template and to the
   prose list of what the file holds.
4. Phase 4, The reports: the User report gains a `### Merge danger`
   subsection after the `### Main-session rulings` list, outside the
   one-page limit as that list is, with the Why (it is what the user reads
   before the tag).
5. § The reviewer report: the template gains
   `- Merge danger: <n> one-way, <u> unclear, <m> two-way` after
   `- Files changed:`, and the prose below the template says the field is
   read from the state file's `merge danger:` line.
6. The closing sentence that leaves the tag, push, and release to the user —
   in Phase 4's last paragraph and in § Exit's finish paragraph — adds, when
   `<n>` + `<u>` is above zero, how many changes cannot be undone or are
   unclear and that the `Merge danger` section lists them; the gates table's
   final-gate row says the same. It stays a statement, not a question.

**Acceptance criteria:**
- `diff` of the block extracted from this file and from
  `plugins/kenspc/skills/task-review/SKILL.md` prints nothing.
- The `**Merge danger.**` paragraph sits between "The batch's temp entries"
  and "The reports", and names the range, the spec via `git show`, the
  `_logs` file, the state-file line, and the catch-all rule for the batch's
  removed documents.
- Phase 4's **Inputs** and **DONE when** name
  `_logs/<batch>-merge-danger.md` and the state file's `merge danger:`
  line.
- The state-file template and its prose list hold the `merge danger:` line;
  the reviewer report template holds `- Merge danger:` after
  `- Files changed:`, and the prose below the template says the field is
  read from the state file's `merge danger:` line.
- The User report's `### Merge danger` subsection follows the
  `### Main-session rulings` list, and the text says the one-page limit
  does not count it.
- The closing sentence's count appears in Phase 4's last paragraph, § Exit,
  and the gates table, each conditioned on `<n>` + `<u>` above zero; no new
  question or gate is added.
- `bash scripts/check-all.sh` exits 0.

---

### Task 4: generate-task — the `Related plan:` line

**Status:** DONE

**Implementation notes:**
- Decisions:
  - The DONE bullet says the path is written relative to the repository
    root "whatever form the argument took". Why: PLAN_PATH may arrive
    absolute, and the review skills read the line as a repository-relative
    path at HEAD.
- Changes/tradeoffs:
  - The Document language paragraph's Why now names all three readers in
    order (task-implementer, the review skills, task-document-reviewer),
    re-wrapping its sentence.
- Test map: none (no behavior added or altered) — skill prose; no guard
  holds the `Related plan:` line (the plan names none), and smoke row 5
  checks it at release.

File: `plugins/kenspc/skills/generate-task/SKILL.md`.

1. Phase 2's **DONE when** list gains a bullet: the task document opens
   with a `## Context` section that carries
   ``Related plan: `<PLAN_PATH>` ``, the path repository-relative, with a
   Why naming its reader — the review skills' `Merge danger` section reads
   the plan's Risks from it, and a task document does not otherwise name its
   plan.
2. Phase 2's **Document language** paragraph adds `Related plan:` to the
   anchors that stay exactly as written, whatever the document's language,
   with the reason: the review skills find the line by that label.

**Acceptance criteria:**
- Phase 2's DONE list names the line and its form matches
  `plugins/kenspc/references/task-document-example.md:15`
  (``Related plan: `docs/plans/auth-plan.md` ``).
- The Document language paragraph lists `Related plan:` among the parsed
  anchors.
- `bash scripts/check-all.sh` exits 0.

---

### Task 5: The guard `check-merge-danger-canonical.sh`

**Status:** DONE

**Implementation notes:**
- Decisions:
  - Byte-identity compares each carrier against task-review's block (the
    copy Task 1 wrote first), printing a diff per diverging file.
  - The placement check finds each template as the first fenced block
    after its heading, matched as `### Step 8: ... (Schema F)`,
    `### Step 4: ... (Schema G)`, and `### The reviewer report`; the
    Schema G regex names the schema because task-implement has two
    `### Step 4:` headings. A missing heading or fence is exit 2, like
    missing markers.
  - Each failing check prints its own label (`DRIFT … byte-identity`,
    `MISSING … anchor`, `MISPLACED … placement`), and the self-test
    asserts that a mutation's run names its check and no other — the
    plan's "the anchor check alone" made mechanical.
  - The self-test's temp workdir follows the other guards' form
    (`mktemp -d` with an EXIT trap that removes it), as the task asks.
- Changes/tradeoffs:
  - A fourth self-test mutation, (d), removes the autopilot reviewer
    report's `- Merge danger:` line; the task's three mutations left that
    branch with no test that fails when it is removed. `check-all.sh`
    still counts one self-test per guard, so the pinned counts (16 / 15)
    are unchanged.
  - The file is mode 100644, as the other guards are; `check-all.sh` runs
    each with `bash`.
  - Known gap: mutation (a) changes the task-review copy and (c) the
    Schema F template, so a regression that dropped task-implement or the
    autopilot from one of the loops alone would not be caught by the
    self-test; the task fixes "one copy" per mutation.
- Test map:
  - byte-identity check (scripts/check-merge-danger-canonical.sh:147) →
    scripts/check-merge-danger-canonical.sh::--self-test mutation (a)
  - anchor check (scripts/check-merge-danger-canonical.sh:168) →
    scripts/check-merge-danger-canonical.sh::--self-test mutation (b)
    (mutation-checked)
  - Schema F/G order check (scripts/check-merge-danger-canonical.sh:121) →
    scripts/check-merge-danger-canonical.sh::--self-test mutation (c)
    (mutation-checked)
  - reviewer report `- Merge danger:` check
    (scripts/check-merge-danger-canonical.sh:207) →
    scripts/check-merge-danger-canonical.sh::--self-test mutation (d)
    (mutation-checked)
  - missing file, markers, or template → exit 2
    (scripts/check-merge-danger-canonical.sh:137, :142, :111, :202) →
    none: no fixture removes an input; the control mutant of the mutation
    check (a nonexistent REVIEW_REL) showed exit 2 by hand
  - bash 3.2: `/bin/bash scripts/check-merge-danger-canonical.sh
    --self-test` exits 0; `bash scripts/check-all.sh --self-test` prints
    `guards run: 16` and `self-tests run: 15`

Depends on: Task 1-3

File: `scripts/check-merge-danger-canonical.sh` (new).

Write the guard as the plan's "Guard" section specifies, in the form of the
existing guards (`check-canonical-dispatch.sh`, `check-verdict-shared.sh`):
a header stating what it checks and its exit codes (0 pass, 1 drift, 2
missing input or markers, or a stale fixture), `set -euo pipefail`, the
`SCRIPT_DIR` / `REPO_ROOT` derivation, bash 3.2-safe (no associative
arrays; any escaping in awk done character by character, AGENTS.md § Guard
scripts).

1. Byte-identity of the `canonical:merge-danger` block across the three
   SKILL.md files.
2. Anchors inside the block, each at least once: `one-way`, `two-way`,
   `unclear`, `Evidence:`, `not found`, `none named`.
3. Placement, read only inside the fenced templates: Schema G (task-implement
   Step 4) and Schema F (task-review Step 8) each hold `## Merge danger`
   after `## Verdict` and before `## Next steps`; the autopilot's
   § The reviewer report template holds a `- Merge danger:` line.
4. `--self-test`: copy the three files to a temp workdir; the unmutated
   copies pass; then, reverting each before the next, (a) one word changed
   inside the block of one copy fails byte-identity, (b) an anchor replaced
   identically in all three copies fails the anchor check, (c)
   `## Merge danger` moved after `## Next steps` in one copy fails
   placement. The temp workdir is removed at the end.

**Acceptance criteria:**
- `bash scripts/check-merge-danger-canonical.sh` exits 0 on the repository.
- `bash scripts/check-merge-danger-canonical.sh --self-test` exits 0, and
  each of its three mutations makes the main check exit 1 (its output names
  which check failed).
- `bash scripts/check-all.sh --self-test` prints `guards run: 16` and ends
  with `self-tests run: 15`.
- The script runs under macOS's `/bin/bash` (3.2):
  `/bin/bash scripts/check-merge-danger-canonical.sh --self-test` exits 0.

---

### Task 6: Doc-sync

**Status:** DONE

**Implementation notes:**
- Decisions:
  - Task 2: Merge danger is rendered under every verdict, BLOCKED
    included — promoted into `plugins/kenspc/README.md` § Skills, the
    task-implement row.
  - Task 3: the closing sentence's count is a statement, not a question
    (the final-gate row's "no question") — promoted into
    `plugins/kenspc/README.md` § Autopilot, "The reports".
  - Task 3: the section follows the report's language, the heading,
    labels, and signal names excepted — promoted into
    `plugins/kenspc/README.md` § Recommended Workflow, the
    `**Merge danger.**` paragraph.
  - Task 4: the `Related plan:` path is written relative to the repository
    root whatever form the argument took — promoted into
    `plugins/kenspc/README.md` § Skills, the generate-task row, and
    `docs/release-checklist.md` smoke row 5.
  - Task 5: each self-test mutation must fail its own check alone, and a
    fourth mutation covers the reviewer-report field — promoted into
    `plugins/kenspc/CHANGELOG.md` 4.13.0, the guard's entry.
  - Local, not promoted: Task 1's rendered example, "carrier" wording,
    catch-all counting and zero-file row, header layout, uncommitted header
    form, and `<how chosen>` wording; Task 2's mechanical copy; Task 3's
    `<how chosen>` wording and zero counts for an empty range; Task 5's
    reference copy, heading regexes, temp-workdir form, file mode, and its
    known self-test gap.
  - Needs a home: none.
- Changes/tradeoffs:
  - AGENTS.md: the § Agents bullet on the shared canonical blocks now names
    five blocks and the autopilot's copy of `merge-danger` with its guard,
    merged there rather than a new § Skills bullet; the lint reads 199/200
    lines.
  - README § Skills: the autopilot row ("Two reports at the end: …") is
    not on the task's list and was not edited; § Autopilot carries the
    change instead.
  - Release checklist rows 6 and 7 name the eight signals and say the
    check is by signal name and `file:line`, not the `Evidence:` label;
    row 11 adds the `_logs` file, the state-file line, and the closing
    sentence's condition.
- Test map: none (no behavior added or altered)

Depends on: Task 1-5

Bring the documents below in line with what Tasks 1-5 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § Skills table — the task-implement and
  task-review rows name the Merge danger section; the generate-task row
  names the `Related plan:` line (plan steps 1, 2, 4).
- `plugins/kenspc/README.md` § Autopilot, "The reports" paragraph — the User
  report's `### Merge danger` subsection outside the page limit, the
  reviewer report's `Merge danger` field, and the closing sentence's count
  (plan step 3).
- `plugins/kenspc/README.md` § Recommended Workflow — a `**Merge danger.**`
  paragraph beside the Setup, Prototype, Documentation, and Bug path
  paragraphs: the three questions, the labels and the one-step definition,
  the signals, the deployment document, the `Related plan:` line, and that
  it is not a gate (plan steps 1–4).
- `AGENTS.md` § Editing skill and agent content › Skills — a bullet for the
  `canonical:merge-danger` block: three carriers, the guard that holds them,
  and that a change applies to all three in one commit, in at most three
  lines or merged into an existing bullet; § Agents' sentence that
  task-review and task-implement "share four byte-identical canonical
  blocks" stops being true once both carry a fifth, and names
  `canonical:merge-danger` as shared with the autopilot as well — the
  natural place to merge the bullet (plan steps 1–3, 5). The file stands at
  197 of the 200 lines its budget line allows, and
  `scripts/check-instruction-lint.sh` fails above it.
- `plugins/kenspc/CHANGELOG.md` — a `## 4.13.0 — unreleased` entry for the
  section, the `Related plan:` line, and the guard (all plan steps).
- `docs/release-checklist.md` § Pre-flight — `guards run: 16`,
  `self-tests run: 15` (plan step 5); § Smoke checklist rows 5, 6, 7, and
  11 — row 5 sees the `Related plan:` line; rows 6 and 7 see
  `## Merge danger` between `## Verdict` and `## Next steps`, each
  non-catch-all row with an evidence line naming at least one signal by its
  fixed English name and a `file:line` — not the label `Evidence:`, which
  follows the report's language, so the check holds in a smoke run in any
  language; row 11 sees the User report
  subsection, the reviewer report field, and
  `_logs/<batch>-merge-danger.md` (plan steps 1–5).

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-5. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-5 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
- `bash scripts/check-instruction-lint.sh` exits 0, and
  `bash scripts/check-all.sh --self-test` exits 0 printing the counts
  `docs/release-checklist.md` now pins.
