# Batch L — autopilot field lessons — Task Document

## Context

Build into the kenspc plugin the remedies the dayaku-crm autopilot batches
applied by hand (roadmap items 29, 30, 31, 32, 33, 35, 37, and 39). Every
task implements the bullets of one plan step, or a named part of one, and
the plan's text for that step is the specification: read the step in full
before starting the task.

Related plan: `docs/plans/batch-l-autopilot-field-lessons.md`

Rules for every task, from the plan's Implementation Steps:
- Each rule a task adds to a skill or an agent carries its Why in the
  file's form, the failure stated in its own words and not cited as a
  dry-run record (CLAUDE.md, Writing Rules for Skill Content).
- Tasks 1, 2, 6, 7, 8, 9, 10, and 14 all edit
  `plugins/kenspc/skills/autopilot/SKILL.md`, several in a shared section;
  each edits the text as the earlier tasks left it and keeps their
  additions.
- Every task ends with `bash scripts/check-all.sh` green.
- A criterion that a file holds, or no longer holds, a phrase is checked on
  the file with its line breaks joined, e.g.
  `tr '\n' ' ' < FILE | tr -s ' ' | grep -cF '<phrase>'`, not with a line
  grep: these files wrap prose at about 75 columns, so a phrase split
  across two lines is invisible to a line grep, and a "no longer holds"
  check would pass with the phrase still there (the autopilot's
  `the largest single-session cost of this batch` is split that way today).
- Commits stay local on `main`; no push, no tag, no version bump.

Dependency note: Task 5 depends on Tasks 3 and 4; Task 6 on Tasks 3 and 4
(its Phase 0 copies both scripts); Task 7
on Tasks 4 and 6; Task 10 on Task 7; Task 12 on Task 11; Task 13 on Task 2;
Task 15 on Task 13; Task 16 on Tasks 1-15.

## Tasks

### Task 1: Preamble additions

**Status:** DONE

**Implementation notes:**
- Decisions: a worker whose final message has no
  `## Lessons for the main session` heading adds nothing to the state
  file's `worker lessons:` section (no `<tag>: none` entry, unlike
  `rail observations:`), and the reviewer report's `Worker lessons:` line
  reads `none` when the section is empty — a missing lesson carries no
  safety meaning, so the `none` / `not read` distinction the rail
  observations need was not copied. The § 6 quoting rule went into the
  constraint line's placeholder itself, since that placeholder is what the
  main session fills. The Why sentences were grouped in one new paragraph
  after the § 3 Why paragraphs, plus one sentence on the § 6 notes
  paragraph.
- Changes/tradeoffs: the `~/.claude` paragraph also names "a memory note
  included, whatever your harness suggests", since the harness's own
  memory instruction is what led a worker there; otherwise as specified.

Implement plan Step 1 in `plugins/kenspc/skills/autopilot/SKILL.md`
(Templates § The preamble and its Why paragraphs; § Launch, wait, return,
the return; § The state file; the reviewer report template):
- § 3: a worker and its subagents write nothing under `~/.claude`, by a
  file tool or a shell command; a lesson worth keeping goes under
  `## Lessons for the main session` in the worker's final message; the
  harness's own writes there (over-long tool results under
  `~/.claude/projects/…/tool-results/`) are the harness's, not a breach.
- § 3: the sentence `Only § 3 holds rails.`, then: a constraint in § 6 is
  not a rail, and a departure from one is listed under
  `## Rail observations` and stops nothing; the rails a worker writes into
  a subagent prompt or an agent's `CUSTOM_INSTRUCTIONS` are § 3 as
  written, never narrower, so code-fixer may edit and commit and
  regression-verifier may build and run the suite.
- § 6's template line for the constraint sections: a constraint stated in
  the preamble's own words quotes the spec's sentence.
- The return reads `## Lessons for the main session` and records each
  entry with the worker's tag under a new `worker lessons:` section of the
  state file; the reviewer report gains a `Worker lessons:` line built
  from that section, `none` when empty.

**Acceptance criteria:**
- `grep -c 'Lessons for the main session' plugins/kenspc/skills/autopilot/SKILL.md`
  prints 3 or more.
- SKILL.md holds `Worker lessons:`, the state file template holds
  `worker lessons:`, and the preamble template holds `Only § 3 holds rails.`
- Each addition has a Why sentence under the template.
- `bash scripts/check-autopilot-rails-hook.sh` exits 0.

---

### Task 2: `Run facts:` field and suite gates

**Status:** DONE

**Implementation notes:**
- Decisions: the `Run facts:` line in § 6 is three template lines — a
  heading sentence, the sub-bullets as written, and the gate sentence —
  since the field's value is a list and the other § 6 field lines are
  single lines. The note under the template now names the three optional
  lines (Allowed files, Byte-identity exceptions, Run facts) instead of
  "the last two lines", which would have become wrong.
- Changes/tradeoffs: the table row's value cell gives two examples (one
  heavy suite at a time, a shared `$TMPDIR`) from the roadmap item, so a
  writer of the field can tell a run fact from a constraint. The gate
  sentence sits in the Run facts line as the plan says, so a gate the spec
  alone sets reaches the worker only when `Run facts:` is set — accepted
  as the plan states it.

Implement plan Step 2 in `plugins/kenspc/skills/autopilot/SKILL.md`
(§ The `## Autopilot` section table; Templates § The preamble § 6 and the
notes under it): a `Run facts:` row (sub-bullets of free text, measured
facts of the machine that bind every worker and are not the spec's
constraints; default empty); a `Run facts:` line in § 6, written when the
field is set and omitted when empty, holding the sub-bullets as written
and the sentence that a gate a run fact or the spec sets on a command
(another session's go before a full suite) is asked by the worker itself
with SendMessage, since the `kenspc:*` subagents have no message tool, and
that the go is named in the dispatch of the agent that runs the command.

**Acceptance criteria:**
- The `## Autopilot` table holds a `Run facts:` row with its default.
- § 6's template holds a `Run facts:` line and the sentence that the
  subagents have no message tool.
- The note under the template says the line is written when the field is
  set and omitted when empty.

---

### Task 3: `extract-acceptance.sh`

**Status:** DONE

**Implementation notes:**
- Decisions: the parsing is one awk program (the macOS awk, no gawk
  extension) behind a bash wrapper that checks the arguments, since awk
  walks the code span's backtick runs character by character more simply
  than bash 3.2 does. A code span closes at the first later run of exactly
  the opening run's length (CommonMark); the text is one span only when
  that run ends the text. Sub-bullets are the lines at the first
  sub-bullet's indentation; deeper-indented lines, bullets included, are
  continuation lines, so a nested list does not split a case. Each file
  ends in a newline. A field whose value is neither `none` nor a list of
  sub-bullets (text on the label line, or an empty field) is exit 2 too —
  read as zero cases, a field the parser failed to read would pass as one
  with nothing to run.
- Changes/tradeoffs: beyond the spec, exit 2 also covers an unreadable
  spec file and an out dir that cannot be created; a CRLF spec is read
  with the `\r` stripped; only the first `## Autopilot` section is read.
  The out dir is created before the parse, so a failed run may leave it
  empty (no file is written in it). Files from an earlier run in the same
  out dir are overwritten, not removed — the main session and S4 extract
  into fresh directories. Verified by a probe on a scratch spec
  (single/double backticks, a backtick inside a double-backtick span, a
  continuation line, a description case, a field note, `none`, no section,
  no field); the guard that holds this behavior is Task 5's.

Create `plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh`
(`#!/bin/bash`, executable, bash 3.2 compatible, no model name) as plan
Step 3's first bullet specifies: `extract-acceptance.sh <spec file> <out
dir>` reads the `## Autopilot` section, finds the `Acceptance:` field (a
label with a parenthesized note included), and writes one file per
sub-bullet, `<nn>` its position as two digits from `01`: `<nn>.cmd` with
the command when the text before ` — PASS: ` is one code span, `<nn>.case`
with that text otherwise. The command is the text between the code span's
backtick runs as it stands, except that one space is removed from each end
when it both begins and ends with a space and is not all spaces;
continuation lines are joined with one space. It prints
`commands: <n>, cases: <m>` and exits 0; `Acceptance: none` writes no
file, prints `commands: 0, cases: 0`, exits 0; a missing section or field
is exit 2 with the reason on stderr. A header comment states the usage,
the exit codes, and why the script exists (each main session's own
extractor went wrong on backtick delimiting).

**Acceptance criteria:**
- On a spec whose field holds `` `echo a` — PASS: exit 0 ``,
  ``` `` printf '`x`' `` — PASS: exit 0 ```, and `run it by hand — PASS:
  ok`, the script writes `01.cmd` = `echo a`, `02.cmd` = ``printf '`x`'``,
  `03.case`, and prints `commands: 2, cases: 1`.
- A spec with no `## Autopilot` section exits 2.
- `bash scripts/check-no-model-names.sh` exits 0.

---

### Task 4: `zero-diff.sh`

**Status:** DONE

**Implementation notes:**
- Decisions: the script changes to the repository's top level before it
  runs git, so `git cat-file -e <baseline>:<path>` and the `git diff`
  pathspecs read every path from the same root whatever directory it is
  run from; the paths file is read before that, relative to the caller's
  directory. A line holding only whitespace counts as blank, and a
  trailing `\r` is stripped, so a CRLF paths file works.
- Changes/tradeoffs: beyond the spec, exit 2 also covers an unreadable
  paths file, a cwd outside a git repository, a baseline that is not a
  commit, and a failing `git diff`, so a git error never reads as an empty
  stat. Verified by a probe in a scratch repository (an unchanged path and
  a path with a space: `compared: 2 paths`, exit 0; after a commit to the
  spaced path: exit 1 with the stat naming it; an empty and a blank-only
  paths file: exit 2; a path absent at the baseline named on stderr); the
  guard that holds this behavior is Task 5's.

Create `plugins/kenspc/skills/autopilot/scripts/zero-diff.sh`
(`#!/bin/bash`, executable, bash 3.2 compatible) as plan Step 3's second
bullet specifies: `zero-diff.sh <baseline> <paths file>` reads one path
per line (blank lines skipped), names each path absent at the baseline on
stderr, runs `git diff --stat <baseline> HEAD --` over the paths as an
array, prints `compared: <n> paths` before the stat, and exits 0 when the
stat is empty, 1 when it is not, 2 on a usage error; a paths file with no
path once blank lines are skipped is a usage error. A header comment
states the usage, the exit codes, and why (a zero-diff check whose paths
arrived as one word compared nothing).

**Acceptance criteria:**
- In a scratch repository, a paths file naming an unchanged path and a
  path with a space prints `compared: 2 paths` and exits 0; after a commit
  changing one listed path it exits 1 and the stat names it.
- An empty paths file exits 2.
- `bash scripts/check-no-model-names.sh` exits 0.

---

### Task 5: `check-autopilot-scripts.sh` guard

**Status:** TODO

Depends on: Task 3, 4

Create `scripts/check-autopilot-scripts.sh` as plan Step 3's third bullet
specifies: it runs both scripts against fixtures in a `mktemp -d`
directory removed by its own trap — single and double backticks, a
backtick inside a double-backtick span, spans with and without the padding
spaces, a label with a note, an `(optional)` case, a description case, a
continuation line, `Acceptance: none`; a path with a space, a changed
path, an unchanged path, a path absent at the baseline, an empty paths
file — and asserts each outcome. Its dispatch matches the literal
`--self-test` argument (so `check-all.sh --self-test` runs it) and turns
the guard red with three mutants of copies of the scripts — padding
stripping removed, continuation joining removed, the paths read as one
word — and green on the originals. Bash 3.2 compatible; no recursive `rm`
other than the trap's removal of its own `mktemp` directory.

**Acceptance criteria:**
- `bash scripts/check-autopilot-scripts.sh` exits 0.
- `bash scripts/check-autopilot-scripts.sh --self-test` exits 0 and reports
  each of the three mutants red.
- `bash scripts/check-all.sh` prints `guards run: 13`;
  `bash scripts/check-all.sh --self-test` ends with `self-tests run: 12`.

---

### Task 6: S4 runs the extracted commands

**Status:** TODO

Depends on: Task 3, 4

Implement the S4 part of plan Step 4 in
`plugins/kenspc/skills/autopilot/SKILL.md` (Phase 0 § The workspace, the
driver copy; Phase 3; Templates § The task blocks, S4 repo mode): Phase 0
copies both scripts beside the driver copy as
`_prompts/<batch>-extract-acceptance.sh` and `_prompts/<batch>-zero-diff.sh`;
Phase 3 (repo mode) extracts the commands from the spec as Phase 0 read
the section, saved to `_prompts/<batch>-spec.md`, into
`_prompts/<batch>-s4-cmds/`, and checks that the printed `commands:` count
equals the number of command cases it reads in the field; the S4
repo-mode block lists "the command in `<file>`" per case, has the worker
re-extract into `<workspace>/_prompts/<batch>-<tag>-cmds/`, `cmp` every
file against the main session's plus one `cmp` of two differing files,
run each with `<shell> <file>` (`<shell>` the shell the main session's own
Bash tool runs, `ps -p $$ -o comm=`, written into the block), and add no
redirect to an inspection command; a `.case` is listed with its text; a corrected case is the file
`<nn>.corrected.cmd`, kept out of the `cmp`; the reply gives each
command's exit code and the evidence it leaves, by path. Phase 3's
repo-mode paragraph and its `Acceptance record:` sentences change with the
block. All as the plan's Step 4 bullets state them.

**Acceptance criteria:**
- SKILL.md holds `<batch>-extract-acceptance.sh`, `<batch>-zero-diff.sh`,
  and `corrected.cmd`.
- SKILL.md holds neither `one per Bash call`, `one command per Bash call`,
  nor `twenty lines`.
- `bash scripts/check-autopilot-rails-hook.sh` exits 0.

---

### Task 7: The zero-diff check uses the script

**Status:** TODO

Depends on: Task 4, 6

Implement the zero-diff part of plan Step 4 in
`plugins/kenspc/skills/autopilot/SKILL.md`: § The zero-diff check calls
`_prompts/<batch>-zero-diff.sh` with the `Zero diff:` paths written one
per line to `_prompts/<batch>-zero-diff.txt` and checks that `compared:`
equals the number of paths in the field; every place that reads the check
as "printed nothing" reads its exit code instead — Phase 2's DONE line,
§ Phase transitions, Phase 4's re-run before S6, and the reviewer report's
`zero diff:` field, which reports the `compared:` count and the paths the
stat names.

**Acceptance criteria:**
- SKILL.md holds neither `zero diff: <nothing printed` nor
  `empty zero-diff output`.
- Phase 2's DONE line names the zero-diff check's exit code.
- § The zero-diff check names `<batch>-zero-diff.txt` and the `compared:`
  comparison.

---

### Task 8: Budget projection per role

**Status:** TODO

Implement plan Step 5 in `plugins/kenspc/skills/autopilot/SKILL.md`
(§ Budget and caps): projected is the largest cost so far of a session of
the role about to launch — S1, S2, S3, S3b, the narrowed reviews together,
S4, S5, S6, each with its resumes and re-runs — or the budget divided by
six before that role's first session; a plugin-mode S4's cost includes its
nested sessions' costs from its record. The hard cap is unchanged, and the
gates table's budget row keeps its wording. The Why states the failure in
its own words (a USD 1 release preparation judged against a USD 70
implementation session).

**Acceptance criteria:**
- § Budget and caps no longer holds
  `the largest single-session cost of this batch` and holds
  `of the role about to launch`, both checked with line breaks joined: the
  first phrase spans two lines before this task, so a line grep finds it
  absent already and the check could not fail.
- `git diff` from the task's start changes no line of the bullet that
  opens `Every launch passes`.

---

### Task 9: `is_error`, the usage-limit end, and the sleep log

**Status:** TODO

Implement plan Step 6 in `plugins/kenspc/skills/autopilot/SKILL.md`
(§ Launch, wait, return, the return; § Death and resume; § The state
file's status words; § The stop conditions, Stops stated at their own
steps; the gates table's row for stops stated at their own step): a JSON
with `is_error: true` is not a success, whatever its subtype; one whose
result names a usage or session limit with a reset time is a usage-limit
end — not a death, so it does not count toward the dead-twice stop;
resumed under the next `-r<k>` after the reset, counted under `Caps:`; the
main session, headless or interactive, never polls through the reset: it
schedules one wake-up after the reset when one of its tools can, and
otherwise stops with `Autopilot stopped: usage limit, resets <time>`
naming the step and its resume, with the cannot-ask sentence; the turn
after the reset (the wake-up, or the user's word) makes the resume; the
Why: the workers run under the main session's own account, so the limit
that ended a worker can refuse the main session's turns too, and a poll is
a turn; the status word `usage-limit`;
"Five stops sit outside the numbered list" becomes six and names the new
stop; the live-worker report adds, on macOS, the last sleep and wake lines
of `pmset -g log`, and a live pid is still never killed.

**Acceptance criteria:**
- `is_error` and `usage-limit end` occur in § Death and resume and in the
  return.
- The new stop's text opens its branch with
  `In a session that cannot ask (a system reminder to work without stopping)`.
- `pmset -g log` occurs exactly once; SKILL.md no longer holds
  `Five stops sit outside`; the state file template's `sessions:` line
  holds `usage-limit`.

---

### Task 10: `Standalone review:` switch

**Status:** TODO

Depends on: Task 7

Implement plan Step 7 in `plugins/kenspc/skills/autopilot/SKILL.md`, every
section the step names: the `Standalone review:` row (`on` or `off`,
default `on`); `off` in plugin mode is a settings stop naming the field;
`off` in repo mode launches no S3b, S3's Schema G verdict and its
review's rows enter the verdict loop in S3b's place, the zero-diff check
runs after S3, S5 and the narrowed reviews unchanged; every passage that
names S3b as the step before Phase 3 names S3 for the `off` case
(`none named; S3 is the last check` among them); the role table's S3b row
and its Why give the reason; the settings line gains
`standalone review <on|off>` after `release preparation`; the reviewer
report's `Sessions:` list carries `S3b: off (Standalone review: off)` when
S3b did not run.

**Acceptance criteria:**
- The `## Autopilot` table holds a `Standalone review:` row.
- § The start checks names the plugin-mode stop; § The verdict loop after
  S3b names Schema G for the `off` case; Phase 2's DONE line covers both
  cases; § Phase transitions names the `off` case.
- SKILL.md holds `S3 is the last check` and `standalone review <on|off>`.

---

### Task 11: task-implementer's optional `TASK_LIMIT`

**Status:** TODO

Implement the agent part of plan Step 8 in
`plugins/kenspc/agents/task-implementer.md` (CONTEXT YOU WILL RECEIVE,
OBJECTIVE, DONE CRITERIA, the processing loop, Schema D): an optional
`TASK_LIMIT` key — give a final status (DONE or BLOCKED, a dependency
block included) to at most that many TODO or IN PROGRESS tasks, in
document order, then return Schema D for them; a task left for a later
slice keeps its status; without the key, every incomplete task as today.
The agent's prerequisite check accepts the key's absence.

**Acceptance criteria:**
- CONTEXT YOU WILL RECEIVE lists `TASK_LIMIT` as optional, with its
  meaning.
- DONE CRITERIA reads the incomplete tasks as those within `TASK_LIMIT`
  when the key is given.
- `bash scripts/check-all.sh` exits 0 (`check-code-craft-canonical.sh` and
  `check-notes-format-sync.sh` among them).

---

### Task 12: task-implement dispatches slices of 12

**Status:** TODO

Depends on: Task 11

Implement the skill part of plan Step 8 in
`plugins/kenspc/skills/task-implement/SKILL.md` (Phase 1's DONE line,
Steps 2, 4, 5; Phase 2 Step 4's Schema G `## Implementation`): with more
than 12 incomplete tasks, Step 4 dispatches slices with `TASK_LIMIT: 12`,
one after another, re-reading the document between them, until no TODO or
IN PROGRESS task is left or a slice returns with no task's status changed;
Step 5 renders one Schema D merged from the slices (rows in document
order, prose sections joined), and Schema G's `## Implementation` carries
it; the batch confirmation is asked once; the constant 12 and its reason
(an implementer ended on `Prompt is too long` after 22 tasks) are stated
in the step; Phase 1's DONE line reads "every incomplete task" as every
incomplete task within `TASK_LIMIT` for a slice; Step 2's CONTEXT block
shows the `TASK_LIMIT` key a slice's dispatch adds; and Step 4's sentence
"The subagent implements all incomplete tasks within its own context"
names the slices. Step 5's fixed lines `Implementation phase complete.` and
`Proceeding to code review.` stay as written.

**Acceptance criteria:**
- The SKILL.md holds `TASK_LIMIT: 12` and the stop condition for the
  slices.
- Phase 1's DONE line names the `TASK_LIMIT` reading for a slice, Step 2's
  CONTEXT block holds a `TASK_LIMIT` line, and Step 4's
  `implements all incomplete tasks` sentence names the slices.
- `bash scripts/check-canonical-dispatch.sh`,
  `bash scripts/check-verdict-shared.sh`, and
  `bash scripts/check-run-contract.sh` exit 0.
- `Implementation phase complete.` and `Proceeding to code review.` occur
  as before.

---

### Task 13: generate-plan writes and checks `## Autopilot`

**Status:** TODO

Depends on: Task 2

Implement the generate-plan part of plan Step 9 in
`plugins/kenspc/skills/generate-plan/SKILL.md` (Phase 2 Step 1 elements):
when the user asks for the plan to run under `/kenspc-autopilot` or for an
`## Autopilot` section, the plan's last section is `## Autopilot`, written
to the grammar in `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/SKILL.md` § The
`## Autopilot` section, read by path at run time; before the print it
checks every label against that table, `Budget:` as exactly `USD <n>` (a
note goes in the label's parentheses), and every `Acceptance:` sub-bullet
for ` — PASS: `, fixing a failure in the draft before the print.

**Acceptance criteria:**
- generate-plan's SKILL.md holds `## Autopilot` and the path of the
  autopilot skill's grammar.
- It names the three checks made before the print.
- `bash scripts/check-instruction-files.sh` exits 0.

---

### Task 14: S6 follows a Release preparation list that makes the removal

**Status:** TODO

Implement the autopilot part of plan Step 9 in
`plugins/kenspc/skills/autopilot/SKILL.md` (Phase 4's Repo mode paragraph;
Templates § The task blocks, the S6 removal block and its notes): a
`Release preparation:` list one of whose sub-bullets makes the removal
commit (`git rm` of the spec and the task document) governs the order —
the removal paragraph is not written, the question paragraph names the
list's removal commit, and a `Version:` set by one of the list's commits
is set there and nowhere else; Phase 4's Repo mode paragraph states the
same case.

**Acceptance criteria:**
- The S6 notes name the case of a list that makes the removal and what is
  written then.
- Phase 4's Repo mode paragraph names the same case.
- `bash scripts/check-doc-sync-anchors.sh` exits 0.

---

### Task 15: generate-plan keeps the draft in a file

**Status:** TODO

Depends on: Task 13

Implement plan Step 10 in `plugins/kenspc/skills/generate-plan/SKILL.md`
(Phase 2 Steps 2 and 3): the draft is written from its first print to
`<plans dir>/<name>.draft.md` (location resolved as Step 3 resolves it,
the conflict check included, a leftover `<name>.draft.md` counted as a
file at the target path); every print reads that file in full; a
revision edits the file and prints it again; approval renames it to
`<name>.md` and no other write follows; a run that ends without approval
names the draft file as the user's to keep or delete; the cannot-ask
branch prints the draft file and stops, its `Nothing is written` sentence
becoming "nothing but the draft file is written"; the Why's conclusion
becomes that the file is the approved text by construction.

**Acceptance criteria:**
- The SKILL.md holds `.draft.md`.
- It holds neither `Do not write it to a file yet` nor `Nothing is written,`.
- The count of `In a session that cannot ask`, with line breaks joined, is
  not lower than before the task (5 when this document was written; a line
  grep counts 3, since two occurrences are split across lines).
- End-of-batch checks (the plan's Testing Strategy), run here because this
  is the last implementation task: `bash scripts/check-all.sh --self-test`
  prints `guards run: 13` and ends with `self-tests run: 12`;
  `claude plugin validate --strict .` and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 16: Doc-sync

**Status:** TODO

Depends on: Task 1-15

Bring the documents below in line with what Tasks 1-15 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § the autopilot section, task-implement,
  generate-plan, Known behavior — the `Run facts:` and `Standalone review:`
  fields, the S4 extraction, the per-role projection, the usage-limit end;
  slices of 12; the draft file and the `## Autopilot` section; Known
  behavior where it states the projection (Steps 1, 2, 4, 5, 6, 7, 8, 9,
  10).
- `CLAUDE.md` § Plugin Directory Layout, File Structure, Repository
  scripts/, CONTEXT block contract, Sessions, not agents (autopilot),
  Non-Goals — the two new scripts under `skills/autopilot/scripts/`; the
  new guard and the counts (thirteen guards, twelve with a self-test);
  `TASK_LIMIT`; S3b runs unless `Standalone review: off` in repo mode, and
  `--resume` also continues a worker ended by the usage limit; the
  autopilot Non-Goals line on three sessions, which holds in repo mode only
  while S3b runs (Steps 3, 6, 7, 8).
- `plugins/kenspc/CHANGELOG.md` — a `## 4.6.0 — unreleased` heading with
  Added, Changed, and Fixed entries for every step; Step 6's entry names
  that a return with `is_error: true` and subtype `success`, read as a
  success before, is no longer one (the plan's Risks) (Steps 1 to 10).
- `docs/release-checklist.md` — the pinned counts `guards run: 13` and
  `self-tests run: 12` (Step 3).

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-15. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-15 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
