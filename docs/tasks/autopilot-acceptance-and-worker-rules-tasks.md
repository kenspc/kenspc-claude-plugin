# Autopilot acceptance commands and worker rules (4.15.0) — Task Document

## Context

Ship items 42, 46, 48, and 49 of `docs/roadmap.md` § Field suggestions (not
yet scheduled) as plugin version 4.15.0: an extractor field argument and a
span-led report, a Phase 0 question about span-led `Acceptance:` entries,
description cases in S4, a `Release checks:` field run by S6, writing rules
for checks, `!` exclusions in `Zero diff:`, the driver passing the prompt on
stdin, the rails hook following a literal `cd`, and four worker rules in the
preamble and S4w. The plan's § Decisions settled in Discover (six points)
and § Technical Approach are binding on every task below.

Related plan: `docs/plans/autopilot-acceptance-and-worker-rules.md`

Dependency note: Tasks 2 and 4 depend on Task 1 (the extractor's field
argument and `span-led:` line); Task 5 depends on Task 4; Task 6 depends on
Task 1 for sequencing only — both edit `scripts/check-autopilot-scripts.sh`'s
header and its self-test mutant count, so Task 6 counts from what Task 1
left (main session ruling, 30 Oct 2026); Task 10 (Doc-sync) depends on
Tasks 1-9. Tasks 2, 3, 4, 5, 6, 7, and 9 all edit
`plugins/kenspc/skills/autopilot/SKILL.md`; each edits only the sections it
names.

Acceptance cases A1–A5 of the plan's `## Autopilot` section run at S4, not
in these tasks. Each task's acceptance criteria are checks the implementer
can run or read, and name the acceptance case that holds the task later.

## Tasks

### Task 1: Extractor field argument and span-led line

**Status:** DONE

**Implementation notes:**
- Decisions: the field name is checked before the out dir is made, so a bad field (like a wrong argument count) writes no directory at all, not just no file. The label regex is built once in `BEGIN` from the field name (`"^- " field "( \\(.*\\))?:"`), so both fields share one match and one note form. A span-led case is one whose text before ` — PASS: ` opens with a backtick, an unclosed span included (it is a `.case` that opens with a backtick run); the list is comma-and-space separated, `span-led: 02, 04`.
- Changes/tradeoffs: the task says every existing fixture's second line is `span-led: none`; the spans fixture's two cases both open with a backtick run (`` `npm test` passes, then … `` and an unclosed `` `echo x ``), so that fixture expects `span-led: 01, 02`, which also holds the list form with two entries. `Acceptance: none` (and `Release checks: none`) prints `span-led: none` too, so every exit-0 run prints two lines. Added beyond the spec: `Release checks` asked of a spec without that field (exit 2, reason names the field) and a four-argument call (exit 2, no out dir); an explicit `Acceptance` third argument is run beside the default.
- Test map:
  - field argument selects the field (extract-acceptance.sh:74, :146, :169) → scripts/check-autopilot-scripts.sh::"extract: both-fields fixture [Release checks]" and self-test mutant "field argument ignored"
  - default field is Acceptance, explicit Acceptance the same (extract-acceptance.sh:74) → scripts/check-autopilot-scripts.sh::"extract: both-fields fixture [no field]" / "[Acceptance]"
  - note form on the selected label (extract-acceptance.sh:146) → scripts/check-autopilot-scripts.sh::"extract: both-fields fixture [Release checks]" (its label carries a note)
  - bad field refused before any write (extract-acceptance.sh:75) → scripts/check-autopilot-scripts.sh::"extract: field Bogus" (mutation-checked)
  - more than three arguments refused (extract-acceptance.sh:68) → scripts/check-autopilot-scripts.sh::"extract: four arguments" (mutation-checked)
  - stderr reason names the field read (extract-acceptance.sh:196, :199) → scripts/check-autopilot-scripts.sh::"extract: Release checks absent" (mutation-checked; :199's wording has no Release-checks fixture, the inline/empty-field fixtures hold only its exit 2)
  - span-led line lists span-led cases (extract-acceptance.sh:214, :218) → scripts/check-autopilot-scripts.sh::"extract: span-led fixture", "extract: spans fixture" and self-test mutant "span-led test dropped"
  - prose-then-span is not span-led (extract-acceptance.sh:214) → scripts/check-autopilot-scripts.sh::"extract: prose fixture"
  - `none` field prints the second line (extract-acceptance.sh:197) → scripts/check-autopilot-scripts.sh::"extract: none fixture"
  - second line held in every existing fixture (check-autopilot-scripts.sh expect_lines) → the seven converted assertions; `grep -c '== "commands: [0-9]*, cases: [0-9]*" ]]'` prints 0 (7 at HEAD before the task)

Plan Step 1. Files: `plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh`,
`scripts/check-autopilot-scripts.sh`.

In `extract-acceptance.sh`:
- Accept an optional third argument, `<field>`: `Acceptance` (the default,
  today's behaviour) or `Release checks`; any other value, or more than
  three arguments, is exit 2 with the reason on stderr. The usage line
  becomes `extract-acceptance.sh <spec file> <out dir> [<field>]`.
- The label match takes the selected field's name, the note form included
  (`- Release checks (<note>):` as `- Acceptance (<note>):` today).
- After the unchanged first line `commands: <n>, cases: <m>`, print a second
  line: `span-led: none`, or `span-led: <nn>, <nn>, …` naming each
  `<nn>.case` whose text (before ` — PASS: `) opens with a backtick run.
  Exit codes are unchanged: a span-led entry is reported, not refused.
- The stderr reasons that name `Acceptance:` today name the field read.
- The header's Usage and "Output and exit codes" sections describe the
  argument and the second line, with the reason for a second line rather
  than a new exit code (an exit other than 0 is a stop at every caller,
  and a span-led entry is a question, not a malformed field).

In `check-autopilot-scripts.sh`, add fixtures and assertions:
- a spec with both an `Acceptance:` and a `Release checks:` field, each
  extracted alone (with no third argument, and with `Release checks`), each
  run writing only its own field's files;
- a span-led entry, `` `dotnet build` from the root — PASS: x ``, written as
  a `.case` and named on the `span-led:` line;
- an entry that opens with prose and holds a code span later, a `.case` not
  named on the `span-led:` line (`span-led: none` when it is the only one);
- a bad field name, exit 2, no file written.

The existing extractor assertions that compare the whole stdout with the
counts line (`[[ "$stdout" == "commands: <n>, cases: <m>" ]]`, seven of
them today) compare the first line with the counts and the second line with
`span-led: none`, so the new line is held in every existing fixture too.

Add two self-test mutants of the extractor copy: the field argument ignored
(always `Acceptance`), and the span-led test dropped (the line always
`none`). Update the guard's header: the fixture list, and the mutant count
and list in the `--self-test` paragraph (eleven becomes thirteen).

**Acceptance criteria:**
- `bash scripts/check-autopilot-scripts.sh` exits 0.
- `bash scripts/check-autopilot-scripts.sh --self-test` exits 0, and its
  output shows each of the two new mutants turning the guard red.
- Run by hand on a spec whose `Acceptance:` holds one command and then the
  span-led entry above, in that order, the extractor prints
  `commands: 1, cases: 1` on its first line and `span-led: 02` on its
  second.
- `grep -c '== "commands: [0-9]*, cases: [0-9]*" ]]' scripts/check-autopilot-scripts.sh`
  prints 0: no assertion still compares the whole stdout with the counts
  line alone (before the change it prints 7, the positive control).
- `bash plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh <spec> <dir> Bogus`
  exits 2 and writes no file.
- `bash scripts/check-all.sh` exits 0.

---

### Task 2: Phase 0 asks about span-led entries

**Status:** DONE

**Implementation notes:**
- Decisions: the span-led question is its own start-check bullet right after the trial-extraction bullet ("The same trial's second output line"), so it inherits that bullet's modes (repo mode; spec entry at Phase 0, brief entry before S2) without restating them; Phase 1 step 6 gains one clause so the brief-entry trial asks the same question before S2. The "run as description cases" answer is recorded under S4's tag, following the state file's rule that a ruling the main session raises is recorded "under the tag of the step it concerns". The new stop is listed first in "Stops stated at their own steps", since Phase 0 is the earliest step.
- Changes/tradeoffs: beyond the spec, the cannot-ask sentence says the state file's `stops:` line records the stop, since acceptance case A2 checks the state file for it. The task's last bullet (a span-led `Release checks:` entry is the settings stop) is written by Task 4 with the `Release checks:` extraction, since that field does not exist before Task 4; nothing in Task 2's text refers to it.
- Test map:
  - span-led question, two answers, state record, cannot-ask stop (SKILL.md:751) → none: skill prose, held later by acceptance case A2 (plan § Testing Strategy); `bash scripts/check-all.sh` exits 0
  - brief-entry trial asks the same question (SKILL.md:884) → none: skill prose, held by the reviewers' reading
  - stop count eight and the list entry (SKILL.md:3523) → none: `grep -c 'Eight stops sit outside the numbered'` prints 1 (the task's criterion), no guard holds the count

Depends on: Task 1

Plan Step 2. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- In Phase 0 § The start checks, the `Acceptance:` trial extraction (repo
  mode and spec entry; in brief entry, before S2 per Phase 1 step 6) reads
  the `span-led:` line as well as the counts. A non-empty list is a
  question to the user before any worker launches: the entries quoted, and
  two answers — stop to fix the spec (nothing is spent), or run them as
  description cases, which the state file records under
  `questions answered:`, ending `(user)`, and S4's block lists as
  description cases.
- At that question, a sentence opening exactly "In a session that cannot
  ask (a system reminder to work without stopping), …" says the run stops
  before the first launch, naming the entries and the words after each
  span, with the reason: the words after a span may say where or how the
  command runs, and the skill does not guess them.
- Templates § The stop conditions, "Stops stated at their own steps": the
  count goes from seven to eight, and the list names the span-led stop
  with its section.
- A span-led entry under `Release checks:` is not handled here: it is a
  `.case`, and so the settings stop Task 4 adds.

**Acceptance criteria:**
- The start checks name the `span-led:` line, the question, its two
  answers, the state-file record for the second answer, and the
  cannot-ask stop in the wording above.
- `grep -c 'Eight stops sit outside the numbered' plugins/kenspc/skills/autopilot/SKILL.md`
  prints 1, and the paragraph's list names the span-led stop.
- `bash scripts/check-all.sh` exits 0.
- Held later by acceptance case A2.

---

### Task 3: S4 runs a description case

**Status:** DONE

**Implementation notes:**
- Decisions: the reply rule for a `.case` is a sentence added to the block's existing reply paragraph ("Reply with the cmp lines, …") rather than to the run paragraph, so the run paragraph says how each kind runs and the reply paragraph what each kind's lines hold.
- Changes/tradeoffs: the task places "the S4 bullet below the block"; in the skill each step's bullet sits above its block, so the sentence went into the `**S4, repo mode**` bullet that introduces the block (after its description of how a `<nn>.case` is listed).
- Test map:
  - `<shell> <file>` limited to `.cmd`/`.corrected.cmd`, `.case` run as described in this session (SKILL.md:3040) → none: skill prose, held later by acceptance case A3
  - a `.case`'s reply lines (SKILL.md:3066) → none: skill prose, held later by acceptance case A3
  - the S4 bullet's rule and reason (SKILL.md:2990) → none: skill prose, held by the reviewers' reading

Plan Step 3. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- In the repo-mode S4 task block (`## Task: acceptance for batch <batch>`,
  the paragraph that opens "Then run each case yourself"), state that
  `<shell> <file>` is the form for a `<nn>.cmd` or `<nn>.corrected.cmd`; a
  `<nn>.case` is run as its text describes, in this session, and the reply
  names each command run for it with its exit code, and PASS or FAIL
  judged against its criterion.
- The S4 bullet below the block says the same in one sentence, with the
  reason: two batches stopped to ask how to run a description case, since
  the block said to run every case as `<shell> <file>`.

**Acceptance criteria:**
- The S4 block's run paragraph limits `<shell> <file>` to `.cmd` and
  `.corrected.cmd` files and states how a `.case` is run and what its reply
  lines hold.
- The bullet below the block states the rule and its reason.
- `bash scripts/check-all.sh` exits 0.
- Held later by acceptance case A3.

---

### Task 4: `Release checks:` field, extraction, S6 run, and report

**Status:** DONE

**Implementation notes:**
- Decisions: the S6 release-check paragraph copies the repo-mode S4 block's re-extraction wording (`ls` of both directories, `cmp` of each file, one `cmp` shown able to fail, run nothing on a mismatch), so the two re-checks read alike; the repo-mode S6 copy carries the S4 block's suite-slot bracket inside it, the plugin-mode copy none. The checks' results are kept on a new state-file line, `release checks:`, since the user report is built after a wake and the state file is the turn's only reliable memory. A failed release check counts a re-extraction that did not match (which ran nothing) as well as an exit other than 0. A span-led entry under `Release checks:` needs no question of its own: it is a `.case`, so it is the settings stop, and the start check says the `span-led:` question is not asked for this field (the sentence Task 2 left to this task).
- Changes/tradeoffs: beyond the spec: Phase 1 step 6 names the `Release checks:` extraction for brief entry in either mode; Phase 0's Constraints line names `<batch>-release-cmds/`; the trial-extraction start check and Phase 3's repo-mode check now say they read the counts "on its first line", so every `commands:` parse names the first line; the Phase 4 paragraph adds a reason for extracting rather than retyping the checks. A non-zero extractor exit at the Phase 0 release extraction is the stop naming the script's reason, as for the `Acceptance:` trial.
- Test map:
  - label table row and default (SKILL.md:232) → none: skill prose, held by the reviewers' reading
  - Phase 0 extraction, both modes, `.case` settings stop, no extraction for absent/`none` (SKILL.md:774) → none: skill prose, held later by acceptance case A3 (its release check); the extractor's field argument itself is held by Task 1's fixtures
  - S6 re-check paragraph, both blocks (SKILL.md:3293, :3361) and their bullets (SKILL.md:3262, :3325) → none: skill prose, held later by acceptance case A3; `grep -c 'release-recheck'` prints 4
  - Phase 4 report line, FAIL placement, no S5 (SKILL.md:2079, :2428) and state line (SKILL.md:858) → none: skill prose, held later by acceptance case A3 ("the user report lists the release check with its exit code")

Depends on: Task 1

Plan Step 4. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- § The `## Autopilot` section, label table: a `Release checks:` row —
  `none`, or one sub-bullet per check in `Acceptance:`'s grammar, each one
  code span; default `none`.
- Phase 0 § The start checks: when the section holds a `Release checks:`
  field other than `none`, in both modes (in brief entry before S2, as the
  `Acceptance:` trial runs), the main session saves the spec to
  `<workspace>/_prompts/<batch>-spec.md` — in plugin mode too — and runs
  the extractor with `Release checks` as the third argument into
  `<workspace>/_prompts/<batch>-release-cmds/`. A field that yields any
  `.case` is the settings stop (a release check is a command; a
  description is a value outside the field's grammar). An absent field, or
  `none`, runs no extraction, with the reason (the extractor exits 2 when
  the spec has no such field, and an absent field is the default).
- § The workspace: the `(repo mode)` note on `<batch>-spec.md` no longer
  covers that file when `Release checks:` names checks, and the layout
  lists `<batch>-release-cmds/` and `<batch>-<tag>-release-recheck/`.
- Both S6 blocks (`## Task: release preparation for batch <batch>`, repo
  mode and plugin mode) gain a paragraph, written only when the field names
  checks: after the last commit, extract the checks again with the same
  extractor copy into `<workspace>/_prompts/<batch>-<tag>-release-recheck/`,
  show `ls` of both directories and `cmp` of each file against
  `<batch>-release-cmds/` as S4 does (with the one `cmp` shown able to
  fail), run each as `<shell> <file>` from the repository root at that
  commit — `<shell>` filled in as the repo-mode S4 block fills it, and, in
  repo mode only, through the suite-slot wrapper when `Suite limit:` lists
  its prefix — and reply with each check's file and exit code; a failing
  check is reported, not fixed.
- Phase 4: the user report lists each release check with its exit code; a
  FAIL is named in the report's first lines, and the main session launches
  no S5 for it, with the reason (the checks test the release commits, and
  what to do about a failed one before the tag is the user's call).

**Acceptance criteria:**
- The label table has the `Release checks:` row with its default.
- The start checks state the extraction, both modes, the `.case` settings
  stop, and the no-extraction rule for an absent field or `none`, each
  with its reason.
- Both S6 blocks hold the re-check paragraph, conditional on the field
  naming checks; `grep -c 'release-recheck' plugins/kenspc/skills/autopilot/SKILL.md`
  counts at least 2.
- Phase 4 states the report line, the FAIL placement, and no S5, with the
  reason.
- Every place in the skill that parses the extractor's output
  (`grep -n 'commands:' plugins/kenspc/skills/autopilot/SKILL.md`) still
  reads the counts from the first line.
- `bash scripts/check-all.sh` exits 0.
- Held later by acceptance case A3, including its release check.

---

### Task 5: Writing rules for checks

**Status:** DONE

**Implementation notes:**
- Decisions: the "Writing a check" paragraph is a bold lead-in with three bullets, each ending in its `Why:`, placed directly after the label table and before the note-label paragraph. generate-plan's fourth item is a clause of the existing sentence; the sentence's closing `Why:` was left as it stands, since it gives the reason for the whole pre-print check.
- Changes/tradeoffs: the first rule's reason names both consequences in this batch's design (S4 runs a description as its text describes; `Release checks:` refuses one) and the start checks' question, so the rule points at the behavior Tasks 2–4 added.
- Test map:
  - three writing rules with reasons (autopilot SKILL.md:243) → none: skill prose, held by the reviewers' reading (plan Step 5's acceptance)
  - generate-plan's four checks naming both fields and the span-to-PASS check (generate-plan SKILL.md:301) → none: skill prose; `grep -n 'check four things'` finds it

Depends on: Task 4

Plan Step 5. Files: `plugins/kenspc/skills/autopilot/SKILL.md`,
`plugins/kenspc/skills/generate-plan/SKILL.md`.

- In the autopilot skill, after the label table in § The `## Autopilot`
  section, a short paragraph headed "Writing a check" stating three rules,
  each with its reason:
  - an `Acceptance:` or `Release checks:` command is one code span alone
    before ` — PASS: ` (words after the span make it a description);
  - a check over the lines the batch added, or one proving a name is gone,
    excludes the spec's and the task document's paths — `docs/plans/` and
    `docs/tasks/` where the chain writes them — since both sit in the tree
    until S6 removes them;
  - a check finds a commit by its subject, never by its position
    (`HEAD~2`, "the last five commits"), since S6 and later fixes add
    commits.
- In generate-plan's Autopilot element, the pre-print check
  (`plugins/kenspc/skills/generate-plan/SKILL.md`, "check three things"):
  the third item covers `Release checks:` sub-bullets as well as
  `Acceptance:` ones; a fourth item — a sub-bullet of either field whose
  text opens with a code span has nothing between the span and
  ` — PASS: `; the count in the sentence becomes "check four things". The
  rules stay in the autopilot skill's section; generate-plan does not copy
  the "Writing a check" paragraph (the plan's "writing rules live with the
  grammar" principle).

**Acceptance criteria:**
- The "Writing a check" paragraph sits after the label table and names the
  three rules, each with its reason.
- `grep -n 'check four things' plugins/kenspc/skills/generate-plan/SKILL.md`
  finds the sentence, and its items name both `Acceptance:` and
  `Release checks:` and the span-to-PASS check.
- `bash scripts/check-all.sh` exits 0.

---

### Task 6: `Zero diff:` exclusions

**Status:** DONE

**Implementation notes:**
- Decisions: a bare `!` (an exclusion with no path) is refused, exit 2, as boundary input the task left open — with no path it would be `:(exclude,literal)` of nothing. The pathspecs are built into a second array, `specs`, beside `paths`, so the absent-at-the-baseline loop still reads the paths as written and strips the `!` itself; the self-test's "paths read as one word" mutant now targets `"${specs[@]}"`. The fixture repository gains `dir/keep.txt` and `dir/skip.txt` (skip changed after the baseline), and the exclusion fixtures list the directory as `dir/`, with the trailing slash the real `Zero diff:` fields use. The "literal magic dropped" mutant drops it from both forms (`:(literal)` and the `literal` of `:(exclude,literal)`).
- Changes/tradeoffs: beyond the spec: a fixture for an exclusion absent at the baseline (named on stderr without its `!`, and an existing exclusion named nowhere) and one for a bare `!`; the skill's § The zero-diff check gains a Why for the exclusion form; the Phase transitions line (S3b → Phase 3) and the reviewer report's `zero diff:` field, both outside the places the task names, now read both counts, so every `compared:` reading the criterion greps names both or points at § The zero-diff check. The guard's mutant count is fifteen, counting from Task 1's thirteen.
- Test map:
  - `!` path becomes `:(exclude,literal)` (zero-diff.sh:89) → scripts/check-autopilot-scripts.sh::"zero-diff: excluded changed file" and self-test mutant "exclusion dropped"
  - plain path becomes `:(literal)` (zero-diff.sh:94), exclusion literal too → scripts/check-autopilot-scripts.sh::"zero-diff: glob-character path", "zero-diff: bracketed exclusion" and self-test mutant "literal magic dropped"
  - non-excluded sibling still compared (zero-diff.sh:121) → scripts/check-autopilot-scripts.sh::"zero-diff: changed sibling of an exclusion"
  - exclusions only refused (zero-diff.sh:99) → scripts/check-autopilot-scripts.sh::"zero-diff: exclusions only" (mutation-checked)
  - bare `!` refused (zero-diff.sh:85) → scripts/check-autopilot-scripts.sh::"zero-diff: a bare !" (mutation-checked)
  - absent check strips the `!` (zero-diff.sh:114) → scripts/check-autopilot-scripts.sh::"zero-diff: the absent exclusion is not named as nope.txt", "zero-diff: excluded changed file wrote to stderr" (mutation-checked)
  - count line `compared: <n> paths, <m> excluded` (zero-diff.sh:120) → every zero-diff count assertion of scripts/check-autopilot-scripts.sh; `grep -n 'compared: [0-9<n>]* paths"'` finds none (7 lines at the commit before the task)
  - skill: label row, both counts, exclusion resolution (SKILL.md:227, :1655, :1672, and the `compared:` lines at :980, :2118, :3888) → none: skill prose, held by the reviewers' reading

Depends on: Task 1

Plan Step 6 and § The zero-diff exclusion form. Files:
`plugins/kenspc/skills/autopilot/scripts/zero-diff.sh`,
`scripts/check-autopilot-scripts.sh`,
`plugins/kenspc/skills/autopilot/SKILL.md`. The dependency on Task 1 is
sequencing only: both edit the guard's header and its mutant count.

In `zero-diff.sh`:
- A path written with a leading `!` is an exclusion. Drop
  `--literal-pathspecs`; pass each path as `:(literal)<path>` and each
  exclusion as `:(exclude,literal)<path>`, so a bracket is still no glob.
- A paths file of exclusions only is refused, exit 2, with the reason (a
  `git diff` with only exclusions compares everything else).
- The count line becomes `compared: <n> paths, <m> excluded` (`<n>` the
  paths without `!`, `<m>` those with it).
- The absent-at-the-baseline check resolves an exclusion by its path with
  the `!` removed.
- The header: Usage (the `!` form, and that a path whose own name begins
  with `!` cannot be listed), the output line, exit 2's new case, and the
  minimum git for pathspec magic (1.9).

In `check-autopilot-scripts.sh`, fixtures: an excluded file inside a listed
directory changed (exit 0); a non-excluded sibling changed (exit 1); a
bracketed path still read literally with the new form; a paths file of
exclusions only (exit 2). Two self-test mutants of the zero-diff copy: the
exclusion dropped (the `!` path compared as a plain path), and the literal
magic dropped. The existing zero-diff assertions on the count line
(`compared: 2 paths`, `compared: 1 paths`) expect the new form
(`compared: 2 paths, 0 excluded`). Update the header's fixture list and
mutant count and list (thirteen becomes fifteen, counting from Task 1).

In the autopilot skill: the label table's `Zero diff:` row describes the
`!` form; Phase 2 § The zero-diff check holds `<n>` to the field's paths
without `!` and `<m>` to its `!` paths, a difference in either being the
stop it is today; the Phase 4 re-run before S6 and Phase 2's opening DONE
line read the count the same way; the start checks' absent-at-the-baseline
check resolves an exclusion by its path without the `!`.

**Acceptance criteria:**
- `bash scripts/check-autopilot-scripts.sh` exits 0.
- `bash scripts/check-autopilot-scripts.sh --self-test` exits 0, and its
  output shows each of the two new mutants turning the guard red.
- `grep -n 'compared: [0-9<n>]* paths"' scripts/check-autopilot-scripts.sh`
  finds no assertion on the old count form (before the change it finds the
  existing ones, the positive control).
- Each line `grep -n 'compared:' plugins/kenspc/skills/autopilot/SKILL.md`
  finds that reads the count either names both counts (`<n>` paths and
  `<m>` excluded) or reads it "as § The zero-diff check reads them", and
  § The zero-diff check names both.
- `bash scripts/check-all.sh` exits 0.

---

### Task 7: The driver passes the prompt on stdin

**Status:** TODO

Plan Step 7 and § The driver and stdin. Files:
`plugins/kenspc/skills/autopilot/scripts/run.sh`,
`plugins/kenspc/skills/autopilot/scripts/run.ps1`,
`plugins/kenspc/skills/autopilot/SKILL.md`.

- `run.sh`: run `"$exe" -p --session-id "$session" … < "$prompt_file"` and,
  on a resume, `"$exe" -p --resume "$session" … < "$prompt_file"`, with no
  prompt argument; no longer read the file into a variable
  (`prompt=$(cat …)` goes). Resolve `<prompt-file>` to an absolute path
  before the `cd "$dir"`, since the file is now opened after it. Keep the
  refusals of a missing file and of an empty or whitespace-only file. The
  header's `<prompt-file>` ("read from this file with cat") and launch
  ("stdin from /dev/null") lines say the prompt arrives on stdin.
- `run.ps1`: the same through its process start's standard input — the
  prompt file, not an empty file, still never a terminal; the inner
  script no longer reads the prompt into `$prompt` or passes it in
  `$argv`. The prompt path is already resolved by `Resolve-FullPath`; keep
  it absolute. The header's `<prompt-file>` line and "an empty stdin" line
  say the prompt arrives on stdin.
- Each driver's `--self-test` gains a case whose stub records its stdin and
  its argv: the prompt arrives on stdin byte for byte (a prompt holding a
  `"`, a backtick, a non-ASCII character, and a trailing newline), and no
  argument holds it, on a launch and on a resume, the launch given the
  prompt file by a relative path. The existing `run.ps1` case that compares
  the `-p` value with a trailing-newline-stripped prompt is replaced by
  this one; its header paragraph follows.
- The autopilot skill's § The driver ("stdin from `/dev/null`") says the
  prompt arrives on stdin, with the reason (the prompt no longer shows in
  `ps` or `pgrep -f`, which matched workers in four batches).

**Acceptance criteria:**
- `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test` prints
  `self-test passed` and exits 0.
- `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  prints `self-test passed` and exits 0.
- `grep -n '"\$prompt"' plugins/kenspc/skills/autopilot/scripts/run.sh`
  finds no command line; as a positive control, the same grep run before
  the change (or on `git show <the commit before this task>:plugins/kenspc/skills/autopilot/scripts/run.sh`,
  the commit named by its subject) finds the two `cmd=(…)` lines.
- `grep -n '/dev/null' plugins/kenspc/skills/autopilot/SKILL.md` no longer
  names it as the worker's stdin in § The driver.
- `bash scripts/check-all.sh` exits 0.
- Held later by acceptance cases A4 and A5.

---

### Task 8: The rails hook follows a literal `cd`

**Status:** TODO

Plan Step 8 and § The rails hook and `cd`. Files:
`plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh`,
`scripts/check-autopilot-rails-hook.sh`.

In the hook:
- Track a per-command working directory while scanning simple commands. A
  simple command `cd <word>` whose word is one literal path — no `$`,
  backtick, glob character, or `~` — joined to what follows by `&&` or `;`
  at the top level (not inside `( )`, not before a `|`) sets the
  directory, resolved against the current one, for the redirections after
  it, a subshell after it included. An absolute word sets it even when the
  current directory is unknown.
- A `cd` the hook cannot read as a literal — no word, `cd -`, a word that
  opens with `-`, more than one word — or one joined by `||`, leaves the
  directory unknown; a later relative target is then not judged, as
  today's relative target with no absolute cwd.
- Redirection targets of check (d) resolve against the tracked directory;
  every other check is unchanged.
- The header: check (d)'s text says the target resolves against the
  tracked directory; the known-miss line for `cd` is replaced by the forms
  still missed (`cd` inside a subshell or a pipeline, `pushd`, a `cd` whose
  target is not a literal, a `cd` joined by `||`).

In the guard, fixtures as simulated tool-input JSON whose cwd is
`<root>/sub` (`<root>` the fixture repository root):
- `cd <root>/sub/x && echo a > ../../y.log` allowed;
- `cd x; echo a > ../../y.log` allowed;
- `cd / && echo a > y.log` denied;
- `(cd /; echo a) > y.log` allowed;
- `cd / | cat > y.log` allowed;
- `cd "$D" && echo a > ../../y.log`, `cd / || echo a > ../../y.log`,
  `cd - && echo a > ../../y.log`, and `cd && echo a > ../../y.log` allowed.

One self-test mutant: the `cd` tracking removed (every target read from the
input's cwd), which must turn the first three fixtures and the last group
red. Update the guard's header: the fixture list, and the hook-copy
mutants in the `--self-test` paragraph (nine becomes ten, the new one
named in the list). The guard's heading check also reads a copy of the
autopilot SKILL.md; this task does not edit that file.

**Acceptance criteria:**
- `bash scripts/check-autopilot-rails-hook.sh` exits 0.
- `bash scripts/check-autopilot-rails-hook.sh --self-test` exits 0, and its
  output shows the tracking-removed mutant turning the guard red.
- The hook's header holds no known-miss line for `cd <literal> && … >
  <relative>`, and lists the four forms still missed.
- `bash scripts/check-all.sh` exits 0.
- Held later by acceptance case A5.

---

### Task 9: Worker rules in the preamble and S4w

**Status:** TODO

Plan Step 9. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- Preamble § 1: the question's first line is `question <tag>: …` with
  `<tag>` filled in as the worker's own tag (`<batch>-s3`, not a topic
  label), at the same time and in the same way as `<role>` — when
  `_prompts/<batch>-<tag>.md` is assembled at the launch (§ Launch, wait,
  return) — and § 1 says the tag is that literal value. § Launch, wait,
  return names `<tag>` among the values it fills in.
- § The message protocol: the answer's first line repeats the tag of the
  question's first line as written, whatever it is.
- Preamble § 3, after "No resource the brief does not name": one sentence
  — a package the project's lockfile or the spec already names, or a tool
  or a browser build the work needs, that the machine does not hold, is
  asked for, and `<main name>` fetches it and answers with a local path;
  this is a route, not a new rail. A package neither names is a new
  dependency, which stays stop condition 7 (a). Phase 2 § How the main
  session rules gains the answer: fetch it, check it against the
  registry's integrity hash where the registry publishes one, place it in
  the workspace, and answer with its path.
- Preamble § 3, at "write them into every subagent prompt": a summary with
  a path to the full text does not meet the rule, with the reason — a
  subagent may never read the file, and the rails hook holds only part of
  the rails.
- S4w block (`## Task: runtime walk for batch <batch>`), Screenshots rule:
  each screenshot is given a file name that begins `<batch>-walk-`, and
  each is moved by its exact name, never by a glob, since the Playwright
  MCP's output directory is shared by every session on the machine.

**Acceptance criteria:**
- Each of the four rules (question tag and its echo, network route with
  the main session's answer, summary-with-path, screenshot names) is
  present at the place named above with its reason.
- `bash scripts/check-all.sh` exits 0.

---

### Task 10: Doc-sync

**Status:** TODO

Depends on: Task 1-9

Bring the documents below in line with what Tasks 1-9 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § the autopilot section (the `## Autopilot`
  labels, S4, S6, the walk) and § Known behavior (the rails hook's misses)
  — `Release checks:`, the span-led question, description cases in S4, the
  `!` form of `Zero diff:`, the prompt on stdin, the network route, the
  question-tag echo, batch-unique screenshot names, and the hook's `cd`
  handling (Steps 2–9) — including the README's descriptions of the two
  scripts' output, which today say they print `commands: <n>, cases: <m>`
  and `compared: <n> paths`, and gain the `span-led:` line and the
  `<m> excluded` count (Steps 1 and 6); and the skills table's generate-plan row, which
  names the pre-print checks — `Release checks:` and the span-to-PASS check
  (Step 5).
- `plugins/kenspc/CHANGELOG.md` § a new `## 4.15.0 — unreleased` entry above
  `## 4.14.1` — Added (`Release checks:`, the `!` exclusion, the span-led
  question), Changed (S4's description cases, the stdin prompt, the
  preamble's sentences, generate-plan's pre-print check), Fixed (the hook's
  `cd`) (every step).
- `docs/roadmap.md` § item 11 — the "keeps the empty stdin" wording becomes
  the prompt file on stdin (Step 7). Removing items 42, 46, 48, and 49,
  renumbering the remaining field suggestions, and the references that
  follow the numbers (the section intro's "Items 49–51 are workarounds",
  item 47's "they are items 50 and 51") happen at release, in S6's
  release commit: leave them to that commit.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-9. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-9 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
- `bash scripts/check-all.sh --self-test` exits 0, its output includes
  `guards run: 17` and ends with `self-tests run: 16`, the counts
  `docs/release-checklist.md` states (plan Step 10).
