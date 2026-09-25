# Batch B — diagnose-bug Skill, /kenspc-diagnose, REVIEW_SCOPE=changes — Task Document

## Context

Two independent pieces of work, then their guards and documentation. First, a
`diagnose-bug` skill and its `/kenspc-diagnose` command: reproduce an observed
bug with a failing test (or record the manual steps), find the root cause
through a hypothesis loop, and write a task document for
`/kenspc-task-implement` — or a brief for `/kenspc-plan` when the fix needs a
contract, schema, dependency, or configuration decision. Second,
`REVIEW_SCOPE=changes` defined: `task-review` computes the change set once,
read-only, writes it to `RUN_DIR/change-set.md`, and the five reviewers,
`code-fixer`, and `regression-verifier` read it there; in an uncommitted run
`code-fixer` applies its fixes and commits nothing.

Related plan: `docs/plans/batch-b-diagnose-bug.md`. The plan is the complete
specification. Its Design decisions (M1–M19; D1, D2, D4–D7) and its
Clarifications during implementation (C1–C5) are binding rulings:

- C1 makes the run-directory preparation's one-time `.gitignore` commit the
  single exception to "the diagnosis modifies no tracked file" (Tasks 1
  and 13).
- C2 settles the not-reproduced stop: the skill first removes the
  reproduction-test files it created in this run, then asks (Task 1).
- C3 substitutes git's empty tree for a commit the change-set defaults name
  that does not exist — a root commit or an unborn branch (Task 4).
- C4 has every commit instruction in task-review, code-fixer, and
  regression-verifier follow the mode rule: code-fixer's OBJECTIVE and
  PROCESSING APPROACH defer to FIXING RULES (Task 6), and the two "fix
  commits did not introduce new issues" lines read "the fixes (fix commits,
  or the uncommitted fixes of an `uncommitted` run)" (Tasks 4 and 7).
- C5 keeps run names and ruling labels out of the plugin's prompt files:
  every Why states its evidence in its own words, and the new SKILL and the
  files Tasks 4–7 edit carry no B-n, M-n, D-n, or C-n label, no "ruling", no
  batch name, and no dry-run record (Tasks 1 and 4–7).

The labels this document cites (B-n, M-n, D-n, C-n, "ruling") are pointers
into the plan for the implementer. Per C5, none of them is copied into a
skill, agent, or command file.

Each task below cites its plan Step, which is the canonical source for what
to write. The criteria listed here are the local DONE bar.

Fixed forms. Every task that states one of these uses it exactly as written
here (plan § Fixed strings):

- Doc-sync heading: `### Task N: Doc-sync` (N the last task number).
- Dependency line: `Depends on: Task 1-<N-1>` (ASCII hyphen); `Depends on:
  Task 1` for a single prior task.
- Documentation impact: `Documentation impact` in SKILL prose; the record
  label `**Documentation impact:**`, whose body is a list or the single line
  `N/A — <reason>`.
- Diagnosis record: `## Diagnosis`, with the labels `**Symptom:**`,
  `**Reproduction:**`, `**Root cause:**`, `**Hypotheses:**`,
  `**Fix scope:**`, `**Adjacent cases:**`, `**Tier:**`,
  `**Documentation impact:**`, `**Probes:**`, in that order.
- Tier line: `**Tier:** 2 — <files in Fix scope; no contract, schema,
  dependency, or configuration change>` in a task document; tier 3 is stated
  in the brief's The Hard Part.
- Brief header: `# Requirement Brief:` as the first line.
- Change-set file: `RUN_DIR/change-set.md`; `Mode: uncommitted` or
  `Mode: commits`; `Base:` (uncommitted) or `Range:` (commits); `Diff:`; a
  `Status | Path` table.
- Diagnosis run-id: `<YYYYMMDD-HHMMSS>-diagnose-<name>` under
  `.kenspc/runs/`.
- Commit subjects written by the skill: `test: reproduce <symptom>`;
  `docs: add task <name>` (both adapted to the project's commit
  conventions).
- Uncommitted FIXED row: Commit cell `—`.

This is plugin revision work. The files are Markdown (SKILL.md, agent .md,
command .md, README, CLAUDE.md, CHANGELOG, docs), one hook script, and two
guard scripts. The repository has no test framework: "build / test / lint"
for each task is the guard suite. After each task, run the guard the task
names, then `bash scripts/check-all.sh`, which must exit 0 with
`guards run: 10`. Tasks that touch the plugin's skills, commands, agents, or
manifests also run `claude plugin validate --strict ./plugins/kenspc` (and
`claude plugin validate --strict .` for the marketplace manifest).

Constraints that apply to every task (plan § Standing constraints):

- These blocks stay untouched, in every file that carries them:
  - `canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`, and
    `canonical:verdict-shared`;
  - the code-craft canonical paragraphs, together with the
    `CODE-CRAFT PRINCIPLES` header and its guard comment;
  - the worked Schema B example between the `example:schema-b` markers.
- The five reviewers' shared sections stay byte-identical to each other.
  Only CONTEXT YOU WILL RECEIVE, PREREQUISITES, and FILE COVERAGE change
  (Task 5); ROLE, CUSTOM INSTRUCTIONS, and REPORT DELIVERY do not.
- No new agent and no new CONTEXT key. `change-set.md` is a fixed file under
  RUN_DIR.
- `effort:` frontmatter is unchanged in every file; the new skill has none.
  Every skill keeps `version: 3.0.0`, the new one included.
- No version bump: `version` in `plugins/kenspc/.claude-plugin/plugin.json`
  stays `3.6.0`. The CHANGELOG entry goes under `## 3.7.0 — unreleased`. No
  tag, no push.
- Rules are rationale-anchored ("Why: …" prose), with no `MUST` / `NEVER` /
  `CRITICAL`, no effort or reasoning tokens, and no model names
  (`check-no-model-names.sh` scans `skills/`, `agents/`, `commands/`, and
  `shared/`).
- Code, comments, commit messages, and documents are in English.
- Nothing under `.kenspc/` is deleted. No task edits
  `docs/plans/batch-b-diagnose-bug.md`.
- Each task is one conventional commit that stages only the files the task
  lists, together with the task's status update:
  - `feat(skills): …` for Task 1, `feat(commands): …` for Task 2,
    `fix(hooks): …` for Task 3;
  - `feat(skills): …` for Task 4, `feat(agents): …` for Tasks 5–7;
  - `feat(scripts): …` for Tasks 8–9;
  - `docs(claude-md): …` for Task 10, `docs: …` for Task 11,
    `docs(changelog): …` for Task 12 (it also edits the roadmap),
    `docs(release): …` for Task 13;
  - `docs: …` for the Doc-sync task.

Dependency note: Tasks 1 and 4 (plan Phases 1 and 2) are independent of each
other. Tasks 2, 3, and 8 depend on Task 1, which creates the skill they name
or guard. Tasks 5 and 6 depend on Task 4, which defines `change-set.md`;
Task 7 also depends on Task 6, whose uncommitted mode it verifies. Task 9
guards the file name across Tasks 4–7 (`Depends on: Task 4-7`). Tasks 10, 12,
and 13 document the finished behavior and guards (`Depends on: Task 1-9`);
Task 11 documents no guard (`Depends on: Task 1-7`). Task 14, the Doc-sync
task, runs last and needs Tasks 1–13. It reconciles the documents with what
those tasks implemented and promotes their recorded decisions.

## Tasks

### Task 1: Write the diagnose-bug skill

**Status:** TODO

Plan Step 1.1 (locked design B-1 to B-7; rulings M1–M5, M12–M16, D1, D2,
D4–D6; clarifications C1, C2, C5). Create
`plugins/kenspc/skills/diagnose-bug/SKILL.md` in the structure and tone of
the existing skills — frontmatter, Trigger Phrases, Quality bar,
Prerequisites, Arguments, then phases with Goal / Inputs / DONE when /
Constraints — every rule carrying its Why. File references use
`${CLAUDE_PLUGIN_ROOT}`. `skills/generate-brief/SKILL.md` is the closest
model (no review phase, a discovery-shaped artifact).

The file carries, in substance as plan Step 1.1 gives it:

- Frontmatter: `name: diagnose-bug`; the `description` from plan Step 1.1,
  wrapped as the other skills wrap theirs (`description: >`); `version:
  3.0.0`; `argument-hint: <observed bug, or path to a bug report>`; no
  `effort:`.
- Trigger Phrases: the description's English and Chinese phrases plus a few
  more of each; an "Avoid triggering" list with the three exclusions
  (explaining an error message or stack trace — answer directly; finding
  bugs in code — task-review; a one-file fix the user can name that needs no
  new test — just make it), a feature request phrased as a bug ("it should
  also …" — generate-plan or generate-brief), and the tier-1 line with its
  reason (task-implement's single-task rule; ruling M15).
- Quality bar: reproduce before explaining; one root cause with the evidence
  that rules the alternatives out; a task document or brief an implementer
  can act on without diagnosing again; a fix proposed without a reproduction
  is a guess.
- Prerequisites: an observed bug, and a project in a git repository (the
  skill commits the reproduction test and the task document).
- Arguments: `BUG` — free text (what was observed, how it was triggered) or a
  file path the skill reads; with no arguments, ask what was observed and how
  to trigger it.
- Phase 1, Reproduce: Goal, Inputs (BUG; CLAUDE.md, README, and config files
  read silently first; the code), DONE when (the test written in the
  project's test tree under its framework and naming conventions, run, failed
  for the reason the bug describes, failure summarized for the record, and
  committed alone as `test: reproduce <symptom>` staging only that file —
  ruling D1; or the manual steps and the reason no failing-capable test
  exists, in the shape of `task-implementer`'s QUALITY CHECKLIST
  design-concern note — B-3), the Why (the test is the artifact Phase 2 and
  Task 1 rest on), the no-test-framework case (a plain reproduction script
  under the diagnosis run directory's scratch may support the manual steps;
  it is evidence, not the test), the not-reproduced stop (ruling M16 with
  C2: first remove the reproduction-test files the skill created in this
  run — files git reports as untracked (`??`) that did not exist when the
  skill started; never a tracked file, never anything under `.kenspc/` —
  then ask the user for what is missing, listing each attempt: the path,
  what the test exercised, and what happened; if the removal is denied, the
  question names the files as left in place for the user to remove; the end
  state is no task document or brief, no commit, and no untracked test file
  left by the skill; C2's Why: a test that did not reproduce the bug passes
  silently in the user's suite and asserts that the bug is absent), and the
  Constraint (the phase modifies no tracked file — other than C1's one-time
  `.gitignore` commit when it prepares the run directory for a reproduction
  script; the reproduction test is the only project file it creates).
- Phase 2, Diagnose: Goal; DONE when the record fields Root cause,
  Hypotheses, Fix scope, Adjacent cases, Tier, and Documentation impact can
  be filled; the hypothesis loop (B-4: "none — the root cause was visible on
  reproduction", or three to five hypotheses listed at once, each with its
  verification method, verified in turn, outcomes recorded with evidence,
  converging on one; stop and ask when none survives and no new hypothesis is
  grounded in evidence); the probe rule (ruling D4) by reference to the
  run-directory preparation in `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md`
  — the block between `<!-- canonical:run-dir:start -->` and
  `<!-- canonical:run-dir:end -->`, its RUN_DIR, Scratch space, and Ignore
  check bullets — with the run-id suffix `diagnose-<name>`, writing only under
  `RUN_DIR/scratch/orchestrator/<n>/` under that block's naming and
  numbered-attempt rules, a "does this change remove the symptom" experiment
  on a copy under scratch, a mutant used as evidence following the block's
  three-step mutation rule; the rule that the diagnosis modifies no tracked
  file, with C1's exception stated beside it in the review skills' wording —
  "other than the one-time `.gitignore` commit" the Ignore check makes in a
  project that does not yet ignore `.kenspc/` — and C1's Why (the change is
  one-time and visible in history, and the pathspec keeps everything else
  out of it); and the probe Why, stated in the skill's own words — what
  failed, and on which command — rather than by the run it was seen in
  (CLAUDE.md § Writing Rules for Skill Content), for example: an
  implementing agent has run its mutation checks on the project's own
  source files in place, editing them with `sed -i` and restoring them with
  `cp`, and a run that stops between the mutation and the restore leaves
  the user's code mutated; the tier rule (ruling M1:
  tier 3 when the fix requires a new dependency, a change to an existing API
  contract — parameters, return type, error codes —, a database schema
  change, or a project configuration change — tsconfig, eslint, prettier, and
  the like; otherwise tier 2; the Why naming `task-implementer`'s AUTONOMY
  BOUNDARIES as the source); Fix scope; Adjacent cases (an empty list is
  stated); Documentation impact determined as generate-plan determines its
  element (ruling M3).
- Phase 3, Produce — tier 2: the task document at `docs/tasks/<name>.md` (a
  CLAUDE.md-specified location first; `<name>` a kebab-case slug of the
  symptom; an existing file is a question — overwrite, create alongside, or
  cancel; ruling M13); language per ruling D6; content in order — title,
  Dependency note, `## Diagnosis` with the nine labels (Fixed forms),
  `## Tasks`; no `Phase N` or `Step N` heading anywhere (ruling M2); Task 1
  (Fix) with its acceptance criteria, or ruling M12's form for a manual
  reproduction; Task 2 (Regression tests, `Depends on: Task 1`), omitted when
  Adjacent cases is empty (ruling M4); `### Task N: Doc-sync` when
  Documentation impact lists documents, written from the Doc-sync Task
  template in `${CLAUDE_PLUGIN_ROOT}/skills/generate-task/SKILL.md` by
  reference, with the two substitutions ("the plan's Documentation impact"
  reads "the diagnosis's Documentation impact"; each entry's cause is the
  task that makes the change) and `Depends on: Task 1-<N-1>` or
  `Depends on: Task 1` (ruling M3) — no second copy of the template; the
  confirmation before writing (the task list as generate-task's Phase 2
  presents it); the commit after writing (`docs: add task <name>`, staging
  only that file; ruling M5, with its Why).
- Phase 3, Produce — tier 3: the brief per ruling D5 at `docs/briefs/<name>.md`,
  first line `# Requirement Brief:`, generate-brief's template with D5's
  section mapping, the reproduction test's path and commit in Context, no
  `Discovery Mode:` field, no task document, not committed; tell the user the
  path and suggest `/kenspc-plan <path>` without invoking it.
- Exit (ruling M14), tier 2 only: one question — run
  `/kenspc-task-implement <path>` now, or implement interactively; on "run",
  invoke the task-implement skill through the Skill tool with the path; on
  "interactively", stop with the document in place; a session that cannot ask
  writes the document, prints the suggestion, and stops; for a manual
  reproduction the exit message says Task 1 cannot be verified unattended.
- Writing rules for the document (ruling D6): the conversation's language
  unless the user asks otherwise; anchors as written (`**Status:**` and its
  value, `Depends on:`, `### Task N: Doc-sync`, the `## Diagnosis` labels);
  commit-message text, identifiers, and test names in English; concrete
  acceptance criteria (no "as appropriate", "if needed", "properly"); no
  branch, pull-request, rebase, or tag step unless the user asked for one;
  the Why (no reviewer runs on this document — ruling D2).
- Phase transitions rest on artifacts: Phase 1 → 2 on the committed test (its
  hash) or the recorded manual steps; Phase 2 → 3 on the filled record; the
  exit on the committed task document or the written brief.

The skill contains no copy of the run-directory preparation or of the
Doc-sync template: it points at both.

**Files to create:**
- `plugins/kenspc/skills/diagnose-bug/SKILL.md`

**Acceptance criteria:**
- The frontmatter has `name: diagnose-bug`, `version: 3.0.0`, and
  `argument-hint: <observed bug, or path to a bug report>`, and no `effort:`
  line. The description names the three exclusions (an error message or
  stack trace, finding bugs in code, a one-file fix the user can name) and
  carries the English and Chinese triggers of plan Step 1.1, including
  "帮我修这个 bug" and `/kenspc-diagnose`.
- The file has Trigger Phrases (with the "Avoid triggering" list), Quality
  bar, Prerequisites, and Arguments sections, and Phases 1–3 each with Goal,
  Inputs, DONE when, and their Whys, followed by the exit and the writing
  rules.
- The nine record labels appear in the order the Fixed forms give, and the
  file states the tier-2 `**Tier:**` line form.
- Phases 1 and 2 state the three rules plan Step 1.1's Done when names. The
  reproduction rule: a test written in the project's test tree, run, and
  seen to fail before diagnosis starts, or the manual steps and the reason
  no failing-capable test exists. The hypothesis loop: the skip line
  `none — the root cause was visible on reproduction`; otherwise three to
  five hypotheses listed at once, each with its verification method; a stop
  to ask the user when none survives. The tier rule: the four tier-3
  categories — a new dependency, a change to an existing API contract
  (parameters, return type, error codes), a database schema change, a
  project configuration change — with a Why naming `task-implementer`'s
  AUTONOMY BOUNDARIES.
- The tier-2 output rules state: the path `docs/tasks/<name>.md`, `<name>` a
  kebab-case slug of the symptom, and the overwrite / create alongside /
  cancel question for an existing file (ruling M13); no `Phase N` or
  `Step N` heading in the written document (ruling M2); Task 1's acceptance
  criteria — the reproduction test passes, the project's full test suite and
  its build and lint pass, no file outside Fix scope is modified — or, for a
  manual reproduction, ruling M12's form (the user verifies the manual steps
  after the run, and the implementer records that criterion as not
  verified); Task 2 omitted when Adjacent cases is empty (ruling M4); and the
  task-list confirmation before writing.
- `canonical:run-dir` is referenced by its markers and the run-id suffix
  `diagnose-<name>` and the directory `RUN_DIR/scratch/orchestrator/<n>/`
  are named; `grep -c 'check-ignore' plugins/kenspc/skills/diagnose-bug/SKILL.md`
  prints `0` (no copy of the block).
- The Doc-sync template is referenced by path with its two substitutions;
  `### Task N: Doc-sync`, `Depends on: Task 1-<N-1>`, and
  `Documentation impact` each appear; the Doc-sync template's "Promotion:"
  paragraph is not copied into the file.
- Both commit subjects (`test: reproduce <symptom>`, `docs: add task <name>`),
  the tier-3 brief rules (`# Requirement Brief:`, no `Discovery Mode:`
  field, not committed, `/kenspc-plan` suggested and not invoked), and the
  exit question with its two other branches (a session that cannot ask
  writes the document, prints the suggestion, and stops; for a manual
  reproduction the exit message says Task 1 cannot be verified unattended)
  are present.
- C1: the phrase "other than the one-time `.gitignore` commit" appears
  beside the no-tracked-file rule. C2: the not-reproduced stop removes only
  untracked (`??`) reproduction-test files the skill created in this run —
  never a tracked file, never anything under `.kenspc/` — lists each
  attempt (path, what it exercised, result), and names the files when the
  removal is denied.
- `grep -nwE 'MUST|NEVER|CRITICAL' plugins/kenspc/skills/diagnose-bug/SKILL.md`
  prints nothing.
- C5: `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\((B-[0-9]|[MDC][0-9]+)\b' plugins/kenspc/skills/diagnose-bug/SKILL.md`
  prints nothing: every Why states its evidence in its own words, not by
  the run or record it comes from, and no ruling label is carried over from
  the plan.
- `bash scripts/check-no-model-names.sh`, `bash scripts/check-all.sh`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 2: Add the /kenspc-diagnose command

**Status:** TODO

Depends on: Task 1

Plan Step 1.2 (B-1). Create `plugins/kenspc/commands/kenspc-diagnose.md` in
the shape of the six existing command files (for example
`commands/kenspc-brief.md`): `name: kenspc-diagnose`; the one-line
description "Explicit entry point for the diagnose-bug skill — reproduce and
diagnose an observed bug (修 bug) into a task document or a brief.";
`argument-hint: <observed bug, or path to a bug report>`;
`disable-model-invocation: true`; a body that invokes the **diagnose-bug**
skill, reads `${CLAUDE_PLUGIN_ROOT}/skills/diagnose-bug/SKILL.md`, and passes
`$ARGUMENTS` through.

**Files to create:**
- `plugins/kenspc/commands/kenspc-diagnose.md`

**Acceptance criteria:**
- `diff plugins/kenspc/commands/kenspc-brief.md plugins/kenspc/commands/kenspc-diagnose.md`
  shows differences only in the `name`, `description`, and `argument-hint`
  lines and in the two body lines that name the skill and its path.
- The description is the one line given above, and
  `disable-model-invocation: true` is present.
- `claude plugin validate --strict ./plugins/kenspc`,
  `bash scripts/check-no-model-names.sh`, and `bash scripts/check-all.sh`
  exit 0.

---

### Task 3: Reword the reminder hook's task and brief messages

**Status:** TODO

Depends on: Task 1

Plan Step 1.3 (ruling M6). In `plugins/kenspc/hooks/scripts/remind-plan-skill.sh`,
change only the message text of the `*/docs/tasks/*.md` and
`*/docs/briefs/*.md` branches:

- Tasks, in substance: a task document is normally written by a kenspc
  skill — generate-task (Skill tool or `/kenspc-task`) from a plan, which
  reads actual code for correct decomposition and self-reviews via review
  agent, or diagnose-bug (`/kenspc-diagnose`) from a diagnosed bug; if one of
  them has already been invoked, ignore this message.
- Briefs, in substance: generate-brief (Skill tool or `/kenspc-brief`), which
  runs a structured discovery conversation against the shared discovery
  framework, or diagnose-bug (`/kenspc-diagnose`) when a diagnosed fix needs
  planning; the same closing sentence.

The plan and guide branches, the template exclusions, the path
normalization, and the file-path extraction stay as they are.

**Files to modify:**
- `plugins/kenspc/hooks/scripts/remind-plan-skill.sh`

**Acceptance criteria:**
- `printf '{"file_path":"/x/docs/tasks/a.md"}' | bash plugins/kenspc/hooks/scripts/remind-plan-skill.sh`
  prints the new tasks message, which names both generate-task and
  diagnose-bug (with `/kenspc-task` and `/kenspc-diagnose`).
- The same probe with `/x/docs/briefs/a.md` prints the new brief message,
  which names both generate-brief and diagnose-bug (with `/kenspc-brief` and
  `/kenspc-diagnose`).
- The probe with `/x/docs/tasks/_template.md` prints nothing and exits 0.
- The probe with `/x/docs/plans/a.md` prints the plan message byte-identical
  to its output before this task.
- `git diff` of the script shows changes only inside the two heredoc
  messages.
- `bash scripts/check-all.sh` exits 0.

---

### Task 4: Define the change set in task-review

**Status:** TODO

Plan Step 2.1 (B-8; rulings M7, M8, M19, D7 (i)–(iv); clarifications C3,
C4, C5).
In `plugins/kenspc/skills/task-review/SKILL.md`, every canonical block stays
byte-identical to `task-implement`'s; `task-implement/SKILL.md` is not
edited. The edits:

- Arguments: the PATH bullet's "the review covers recent changes
  (uncommitted, staged, or recently committed) without a requirements
  reference" becomes a pointer to the change set Step 1 defines.
- Step 1, in the `REVIEW_SCOPE = "changes"` branch, after "Set TASK_FILE to
  "N/A"." and before `<!-- canonical:run-dir:start -->`: a "Determine the
  change set" rule —
  - read-only: `git status --porcelain`, `git diff --name-status`,
    `git rev-parse`, `git rev-list`, `git log`; no commit, stash, checkout,
    add, reset, or any other change to the working tree, the index, or refs;
    Why, in the skill's own words: a review run once committed the user's
    uncommitted change as a baseline for its fixes because nothing said what
    to do with it; the change set is the user's work, and the run reads it;
  - `Mode: uncommitted` when `git status --porcelain` lists any path once
    paths under `.kenspc/` are dropped (ignored paths never appear): the set
    is every listed path — staged, unstaged, untracked — the base is HEAD's
    SHA, and the diff command is `git diff <sha> -- <paths>` with untracked
    files read whole;
  - `Mode: commits` when the tree is clean: the range is
    `<upstream sha>..<HEAD sha>` when `@{upstream}` resolves and the range has
    commits, otherwise `<HEAD~1 sha>..<HEAD sha>`; the set is
    `git diff --name-status <range>`; the diff command is
    `git diff <a>..<b> -- <paths>`;
  - C3, stated with the defaults: when a commit the defaults name does not
    exist, git's empty tree (`git hash-object -t tree /dev/null`,
    `4b825dc642cb6eb9a060e54bf8d69288fbee4904`) stands in for it —
    `Range: <empty tree>..<HEAD sha> (root commit)` in `Mode: commits` with
    no upstream and HEAD the root commit, and
    `Base: <empty tree> (no commit yet)` in `Mode: uncommitted` on an unborn
    branch (`git rev-parse --verify HEAD` fails); the diff commands keep
    their form (`git diff <empty tree>..<sha>`, `git diff <empty tree> --
    <paths>`), and the pinned base stays the empty tree even when the
    run-directory preparation's `.gitignore` commit then creates the root
    commit;
  - CUSTOM_INSTRUCTIONS naming commits, a range, or paths override the
    default (mode `commits` with that range, or the named paths);
  - every SHA computed and pinned before the run-directory preparation, so
    its one-time `.gitignore` commit is never part of the set (ruling M19);
  - one line to the user: the mode and the base or range, with the file
    count.
- After `<!-- canonical:run-dir:end -->`, still in Step 1: write
  `RUN_DIR/change-set.md` — the first file in the directory — only in
  "changes" mode (a "task" run writes none), in this shape: a `# Change set`
  heading; `Mode: uncommitted` or `Mode: commits`; `Base: <sha>` or
  `Range: <sha>..<sha> (<how it was chosen>)`; `Diff: <command>`; a table
  with `Status` and `Path` columns, status as git prints it (`M`, `A`, `D`,
  `R`, `??`), paths relative to the repository root. Why: the five reviewers,
  code-fixer, and regression-verifier read the set from that path; RUN_DIR is
  the one value the orchestrator already passes, so no key is added.
- Step 2: the CONTEXT keys are unchanged; one sentence notes that in
  "changes" mode RUN_DIR holds `change-set.md`.
- Step 5: in `Mode: uncommitted`, code-fixer applies fixes without committing
  and its FIXED rows show `—` in Commit (ruling D7 (iv)).
- Step 6 (C4): the verification list's "fix commits did not introduce new
  issues" reads "the fixes (fix commits, or the uncommitted fixes of an
  `uncommitted` run) did not introduce new issues". The `canonical:run-dir`
  sentence about fix commits going through the same repository stays as it
  is.
- Step 7: in the Next steps guidance, when the change set was uncommitted,
  one bullet says the fixes are in the working tree, uncommitted, naming the
  files, for the user to review and commit. In the PASS and FAIL bullets
  outside the `canonical:verdict-shared` markers, "fix commits" reads "the
  fixes (fix commits, or the uncommitted fixes of an `uncommitted` run)".

The new text adds no second line containing `- Scratch space:` or
`check-ignore -q .kenspc/runs/probe` to this file:
`check-run-contract.sh`'s self-test requires each on exactly one line.

**Files to modify:**
- `plugins/kenspc/skills/task-review/SKILL.md`

**Acceptance criteria:**
- The change-set rule sits in the "changes" branch before the
  `canonical:run-dir` start marker, and names the read-only command list,
  the forbidden operations with the Why, both modes with their defaults,
  C3's empty-tree substitution (both forms, with the empty tree's SHA or the
  command that prints it), the CUSTOM_INSTRUCTIONS override, the
  pin-before-preparation rule, and the one-line notice.
- The `change-set.md` paragraph sits after the `canonical:run-dir` end marker
  and states the file's shape with `# Change set`, `Mode: uncommitted` /
  `Mode: commits`, `Base:` / `Range:`, `Diff:`, and a `Status | Path` table.
- The Arguments pointer, the Step 2 sentence, the Step 5 note, the Step 6
  wording (C4), the Step 7 Next steps bullet, and the PASS / FAIL wording are
  present; outside the canonical blocks, no line of the file names fix
  commits without the uncommitted-run alternative.
- C5: `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\((B-[0-9]|[MDC][0-9]+)\b' plugins/kenspc/skills/task-review/SKILL.md`
  prints nothing.
- `git diff plugins/kenspc/skills/task-review/SKILL.md` shows no change
  between any pair of canonical markers.
- `grep -c -- '- Scratch space:' plugins/kenspc/skills/task-review/SKILL.md`
  and `grep -c 'check-ignore -q .kenspc/runs/probe' plugins/kenspc/skills/task-review/SKILL.md`
  each print `1`.
- `bash scripts/check-canonical-dispatch.sh`,
  `bash scripts/check-verdict-shared.sh`, `bash scripts/check-run-contract.sh`,
  `bash scripts/check-run-contract.sh --self-test`, and
  `bash scripts/check-all.sh` exit 0; `claude plugin validate --strict
  ./plugins/kenspc` passes.

---

### Task 5: Read the change set in the five reviewers

**Status:** TODO

Depends on: Task 4

Plan Step 2.2 (ruling M9; clarification C5). The same three edits, byte-identical, in each of
the five reviewers; no other section changes:

- CONTEXT YOU WILL RECEIVE, the RUN_DIR bullet: add that with REVIEW_SCOPE
  "changes" it also holds `change-set.md`, the change set the orchestrator
  computed; see PREREQUISITES.
- PREREQUISITES step 3, in substance: if REVIEW_SCOPE is "changes" — with
  RUN_DIR, read `RUN_DIR/change-set.md`; its mode, base or range, files, and
  diff command define the change set; review those files and nothing else,
  and run its diff command for their content. Without RUN_DIR (standalone),
  run `git status`, `git diff`, `git diff --cached`, and
  `git log --oneline -10` as before. Why: five reviewers that each derive the
  set from git have reviewed five slightly different sets; one file written
  once is the same set for all.
- FILE COVERAGE: "list all files that were added or modified (from
  `RUN_DIR/change-set.md` when it exists, otherwise from git diff, git status,
  or the task document)".

Write the edits once and copy them into the other four files.
`check-review-agent-drift.sh` ends a section at the next line made only of
capital letters and spaces, so no new line may consist solely of capitals
and spaces.

**Files to modify:**
- `plugins/kenspc/agents/requirements-reviewer.md`
- `plugins/kenspc/agents/edge-case-reviewer.md`
- `plugins/kenspc/agents/quality-reviewer.md`
- `plugins/kenspc/agents/bug-reviewer.md`
- `plugins/kenspc/agents/test-reviewer.md`

**Acceptance criteria:**
- `change-set.md` appears in the CONTEXT YOU WILL RECEIVE, PREREQUISITES, and
  FILE COVERAGE sections of all five files, and the standalone fallback
  (the four git commands without RUN_DIR) is kept in PREREQUISITES.
- `git diff` of each file shows changes only inside those three sections;
  PREREQUISITE CHECK, ROLE, OBJECTIVE, CUSTOM INSTRUCTIONS, REVIEW CHECKLIST,
  OUTPUT FORMAT, and REPORT DELIVERY are unchanged.
- `bash scripts/check-review-agent-drift.sh` exits 0 and reports all six
  shared sections identical across the 5 reviewers.
- C5: `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\((B-[0-9]|[MDC][0-9]+)\b' plugins/kenspc/agents/*-reviewer.md`
  prints nothing.
- `bash scripts/check-no-model-names.sh`, `bash scripts/check-all.sh`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 6: Make code-fixer read the change set and commit nothing in an uncommitted run

**Status:** TODO

Depends on: Task 4

Plan Step 2.3 (rulings M8, M10, D7 (iv); clarifications C4, C5). In
`plugins/kenspc/agents/code-fixer.md` — six edits, as C4 counts them, plus
C4's OBJECTIVE and PROCESSING APPROACH edit:

- PREREQUISITE CHECK: also stop, with the same message form, when
  REVIEW_SCOPE is "changes" and `RUN_DIR/change-set.md` is missing.
- CONTEXT YOU WILL RECEIVE, the RUN_DIR bullet: in "changes" mode it also
  holds `change-set.md`.
- PREREQUISITES: a step 3 — if REVIEW_SCOPE is "changes", read
  `RUN_DIR/change-set.md`; its files are the change under review and the
  boundary of the fixes; its Mode decides how fixes land.
- FIXING RULES: each fix is a separate, focused commit when the change set
  is committed (`Mode: commits`, or REVIEW_SCOPE "task"). When
  `change-set.md` says `Mode: uncommitted`, every fix is applied to the
  working tree and nothing is committed — no baseline commit of the user's
  change, no fix commit, no stash — and a FIXED row's Commit cell is `—`.
  Why, in the agent's own words: the change under review is the user's
  uncommitted work; a run has committed it as a baseline to give its fixes a
  base, and a per-file `git add` would carry the user's hunks into a fix
  commit — either way the run decides for the user what is committed and
  under which message; the user reads the working tree and commits.
- DONE CRITERIA and PER-ISSUE OUTPUT CONTRACT: a FIXED row references a real
  commit hash, or `—` in an uncommitted run. The final build / test / lint
  run after the last fix is unchanged.
- The reply: in an uncommitted run, one line after the statistics line
  saying the fixes are uncommitted and naming the files.
- OBJECTIVE and PROCESSING APPROACH: their instructions to commit —
  OBJECTIVE's "apply fixes, commit", PROCESSING APPROACH's "committed with a
  focused conventional-commit message" — defer to the FIXING RULES mode rule
  (for example "commit as FIXING RULES prescribes"), so no sentence in the
  file tells the agent to commit in an uncommitted run. C4 adds this edit:
  it keeps the edits above from being contradicted inside the same file,
  since ruling D7 (iv) has code-fixer commit nothing in that mode.

The `canonical:stats-line` block and the `example:schema-b` block stay
byte-identical (the example is a committed-mode example and keeps its
hashes); the `CODE-CRAFT PRINCIPLES` header and its guard comment are
untouched.

**Files to modify:**
- `plugins/kenspc/agents/code-fixer.md`

**Acceptance criteria:**
- The PREREQUISITE CHECK stop condition, the CONTEXT note, PREREQUISITES
  step 3, the FIXING RULES uncommitted-mode rule with its Why, the DONE
  CRITERIA / PER-ISSUE OUTPUT CONTRACT `—` wording, and the reply line are
  present, each naming `change-set.md` or `Mode: uncommitted` where the plan
  step does.
- The rule names all three forbidden actions in an uncommitted run: a
  baseline commit, a fix commit, a stash.
- Outside FIXING RULES, no sentence in `code-fixer.md` instructs a commit
  unconditionally: in `grep -n commit plugins/kenspc/agents/code-fixer.md`,
  the OBJECTIVE and PROCESSING APPROACH lines that tell the agent to commit
  defer to the FIXING RULES mode rule.
- `git diff plugins/kenspc/agents/code-fixer.md` shows no change between the
  `canonical:stats-line`, `example:schema-b`, or `canonical:principle:*`
  markers, and none to the `CODE-CRAFT PRINCIPLES` header or its guard
  comment.
- C5: `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\((B-[0-9]|[MDC][0-9]+)\b' plugins/kenspc/agents/code-fixer.md`
  prints nothing.
- `bash scripts/check-run-contract.sh`, `bash scripts/check-run-contract.sh --self-test`,
  `bash scripts/check-code-craft-canonical.sh`, `bash scripts/check-all.sh`,
  and `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 7: Make regression-verifier read the change set and verify uncommitted fixes

**Status:** TODO

Depends on: Task 4, Task 6

Plan Step 2.4 (rulings M10, D7 (iv); clarifications C4, C5). In
`plugins/kenspc/agents/regression-verifier.md`:

- OBJECTIVE (C4): "Check that fix commits did not introduce new issues"
  reads "Check that the fixes (fix commits, or the uncommitted fixes of an
  `uncommitted` run) did not introduce new issues".
- PREREQUISITE CHECK: also stop when REVIEW_SCOPE is "changes" and
  `RUN_DIR/change-set.md` is missing.
- CONTEXT YOU WILL RECEIVE and INPUTS: `change-set.md` in "changes" mode.
- PREREQUISITES: a step 3 — if REVIEW_SCOPE is "changes", read
  `RUN_DIR/change-set.md` for the set's boundary.
- VERIFICATION CHECKS item 4: fix commits reviewed with `git log` and
  `git show` — or, when `change-set.md` says `Mode: uncommitted` and
  code-fixer committed nothing, the working-tree diff of the files the FIXED
  rows name (`git diff <base> -- <files>`, the base from `change-set.md`);
  the user's own hunks in those files were the change under review and are
  not regressions. The four sub-checks are unchanged. Why: without this,
  check 4 has nothing to read in an uncommitted run, and a FAIL there would
  be a false one.

**Files to modify:**
- `plugins/kenspc/agents/regression-verifier.md`

**Acceptance criteria:**
- The OBJECTIVE wording (C4), the PREREQUISITE CHECK stop condition, the
  CONTEXT and INPUTS entries, PREREQUISITES step 3, and the item-4
  uncommitted branch (with `git diff <base> -- <files>` and the user's-hunks
  sentence) are present.
- C5: `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\((B-[0-9]|[MDC][0-9]+)\b' plugins/kenspc/agents/regression-verifier.md`
  prints nothing.
- `git diff` of the file shows the four item-4 sub-check bullets, the
  Schema C table, and FALLBACK FOR NO-TEST-SUITE PROJECTS unchanged.
- `bash scripts/check-run-contract.sh`, `bash scripts/check-all.sh`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 8: Add the diagnose-bug skill to check-doc-sync-anchors.sh's groups

**Status:** TODO

Depends on: Task 1

Plan Step 3.1 (ruling M17). In `scripts/check-doc-sync-anchors.sh`, add two
entries to `ANCHOR_CHECKS`:
`"Documentation impact|plugins/kenspc/skills/diagnose-bug/SKILL.md"` and
`"Doc-sync|plugins/kenspc/skills/diagnose-bug/SKILL.md"`. The header
comment's per-anchor file lists gain the skill, and every "eight files"
count in the comments becomes nine. The self-test copies its files from the
array and needs no code change; its mutation target stays the task example.

**Files to modify:**
- `scripts/check-doc-sync-anchors.sh`

**Acceptance criteria:**
- `bash scripts/check-doc-sync-anchors.sh` and
  `bash scripts/check-doc-sync-anchors.sh --self-test` exit 0.
- `grep -n 'eight' scripts/check-doc-sync-anchors.sh` prints nothing, and
  the header lists `plugins/kenspc/skills/diagnose-bug/SKILL.md` under both
  `Documentation impact` and `Doc-sync`.
- Falsifiability, by hand: in a temporary copy of `scripts/` and `plugins/`
  (`mktemp -d`), replacing every `Doc-sync` in the copied
  `plugins/kenspc/skills/diagnose-bug/SKILL.md` makes the copied guard exit 1
  with a `MISSING label 'Doc-sync'` line naming that file; the copy is then
  discarded. The command and its output are recorded in the task's
  Implementation notes.
- `bash scripts/check-all.sh --self-test` prints `guards run: 10` and ends
  with `self-tests run: 9`, every line PASS.

---

### Task 9: Guard the change-set.md name in check-run-contract.sh

**Status:** TODO

Depends on: Task 4-7

Plan Step 3.2 (ruling M17). In `scripts/check-run-contract.sh`:

- Check 5: the literal `change-set.md` occurs at least once in
  `plugins/kenspc/skills/task-review/SKILL.md`,
  `plugins/kenspc/agents/code-fixer.md`,
  `plugins/kenspc/agents/regression-verifier.md`, and
  `plugins/kenspc/agents/requirements-reviewer.md`
  (`check-review-agent-drift.sh` carries the reviewers' shared sections to
  the other four); exit 1 naming each file where it is missing; exit 2 on a
  missing file. The two new files join the missing-file check.
- `--file PATH` still runs check 4 only.
- Header comment: "Four checks" becomes five, with one paragraph for check 5.
- Self-test: the two new files are copied into the workdir with the other
  three; a fixture-stale guard that the literal is present in each of the
  four files; one mutation that removes every occurrence of the literal from
  the copied `task-review/SKILL.md` — through a replace-all helper, since
  `replace_literal` replaces the first occurrence only and the name occurs
  more than once there — must exit 1; the revert must exit 0. The header's
  mutation list gains the entry.

**Files to modify:**
- `scripts/check-run-contract.sh`

**Acceptance criteria:**
- `bash scripts/check-run-contract.sh` prints an `OK` line for check 5 and
  exits 0.
- `bash scripts/check-run-contract.sh --self-test` exits 0, and its fixture
  applies the check-5 mutation (removing the literal from the copied
  task-review SKILL makes the main check exit 1).
- `bash scripts/check-run-contract.sh --file <a Schema B file>` runs the
  recount only: on a copy of the worked example extracted to a temporary
  file it prints only the recount `OK` line.
- The script runs under the bash 3.2 that macOS ships:
  `/bin/bash scripts/check-run-contract.sh` and
  `/bin/bash scripts/check-run-contract.sh --self-test` exit 0 on macOS
  (`/bin/bash --version` reports 3.2), and
  `grep -nE '^[^#]*(declare -A|sed -i)' scripts/check-run-contract.sh`
  prints nothing (the header comment that names `sed -i` does not match).
- `bash scripts/check-all.sh --self-test` prints `guards run: 10` and ends
  with `self-tests run: 9`, every line PASS.

---

### Task 10: Update the repository CLAUDE.md

**Status:** TODO

Depends on: Task 1-9

Plan Step 4.1 (rulings D2, D4, D7, M11). In `CLAUDE.md` at the repository
root:

- Project Overview: the plugin also provides bug diagnosis; "The brief skill
  has no review phase" becomes the brief and diagnose-bug skills.
- Plugin Directory Layout: `commands/kenspc-diagnose.md` and
  `skills/diagnose-bug/SKILL.md` in the tree; the hooks paragraph says the
  reminder's task and brief messages name the skills that write those
  directories.
- SKILL.md Frontmatter Fields: "all six skills", "syncing six files", and
  "bump all six together" become seven.
- Subagent Review Architecture: diagnose-bug joins the "No review" pattern
  (no plan to compare against; the user confirms the task list and
  task-implement's batch gate follows — ruling D2); a short "Diagnosis path"
  paragraph (reproduction test committed first, the `## Diagnosis` record,
  the fix / regression / Doc-sync tasks, the tier-3 brief, the probe
  directory by reference to `canonical:run-dir` with the `diagnose-<name>`
  suffix — ruling D4); the effort paragraph's "the other five skills"
  becomes six; the run-directory paragraph gains `change-set.md`.
- CONTEXT block contract: a paragraph on `change-set.md` (v3.7) — with
  REVIEW_SCOPE "changes" the orchestrating skill writes the change set it
  computed (mode, pinned base or range, diff command, file list) to
  `RUN_DIR/change-set.md` before dispatch; the five reviewers, code-fixer,
  and regression-verifier read it there; no key was added, for the reason
  RUN_DIR replaced REVIEW_REPORTS and ACCOUNTABILITY_LIST; without RUN_DIR a
  standalone reviewer derives the set from git itself; in `uncommitted` mode
  code-fixer commits nothing.
- Standalone safety classification: the reviewers' standalone sentence gains
  "and derive the change set from git themselves".
- Repository scripts/: `check-doc-sync-anchors.sh`'s group lists gain the
  skill; `check-run-contract.sh`'s description gains check 5.
- Non-Goals: the run-directory preparation is written once; diagnose-bug
  references it and carries no copy.
- The Durable documents table is unchanged.

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- `grep -nE '\bsix skills|syncing six|bump all six|other five skills' CLAUDE.md`
  prints nothing, and the seven / six forms are present in those sentences.
- The layout tree lists `kenspc-diagnose.md` and `diagnose-bug/SKILL.md`;
  the "No review" pattern names diagnose-bug; the "Diagnosis path",
  `change-set.md` CONTEXT-contract, standalone-sentence, scripts/, and
  Non-Goals edits are present.
- Every count and list in the file agrees with the repository:
  `ls plugins/kenspc/skills` shows seven skill directories,
  `ls plugins/kenspc/commands` seven commands, `ls plugins/kenspc/agents`
  eleven agents, and the guard counts stay `guards run: 10` /
  `self-tests run: 9`.
- `git diff CLAUDE.md` shows the Durable documents table unchanged.
- `bash scripts/check-all.sh` exits 0.

---

### Task 11: Update the READMEs and the manifests

**Status:** TODO

Depends on: Task 1-7

Plan Step 4.2 (rulings M11, M18, D1, D7; clarification C3).

- `README.md` (root): a `diagnose-bug` row in the skills table
  ("Reproduce-first bug diagnosis with a hypothesis loop, producing a task
  document for task-implement or a brief for planning — no review phase");
  `/kenspc-diagnose` in the Commands line.
- `plugins/kenspc/README.md`:
  - Skills: a diagnose-bug row (reproduce with a failing test or record
    manual steps; hypothesis loop; task document with fix, regression tests,
    Doc-sync; brief for tier 3; no review phase, the user confirms the task
    list);
  - Commands: a `/kenspc-diagnose` row
    (`/kenspc-diagnose <observed bug or path to a bug report>`), and
    `/kenspc:diagnose-bug` in the skill-invocation sentence;
  - Recommended Workflow: a second entry path — an observed bug →
    `/kenspc-diagnose` → `docs/tasks/*.md` → `/kenspc-task-implement`, or →
    `docs/briefs/*.md` → `/kenspc-plan` — and "Small fixes can skip all
    skills" restated with the tier-1 criterion (ruling M18);
  - Run directory: a diagnosis's probes live in
    `.kenspc/runs/<time>-diagnose-<name>/scratch/orchestrator/`, and a
    standalone review's directory holds `change-set.md`;
  - Known behavior: the "Review scope without a task document" item is
    replaced by the change-set definition (modes, defaults with C3's
    empty-tree substitution, CUSTOM_INSTRUCTIONS override, read-only
    computation) and the
    uncommitted-mode behavior (fixes applied, nothing committed, `—` in
    Schema B, the Next steps bullet); a new item for the red interval —
    after `/kenspc-diagnose` the reproduction test is committed and fails
    until the fix task lands (ruling D1).
- `plugins/kenspc/.claude-plugin/plugin.json`: the description says what the
  skills cover — brief generation, plan generation, task decomposition, bug
  diagnosis, batch implementation, multi-angle review — and that eleven
  reusable subagents do the review, fix, verification, and implementation
  work (ruling M11). `version` stays `3.6.0`.
- `.claude-plugin/marketplace.json`: the top-level description gains bug
  diagnosis. The plugin entry's summary is unchanged.

**Files to modify:**
- `README.md`
- `plugins/kenspc/README.md`
- `plugins/kenspc/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

**Acceptance criteria:**
- Both READMEs list diagnose-bug and `/kenspc-diagnose`; the plugin README's
  skill-invocation sentence lists seven `/kenspc:` forms.
- The plugin README no longer says the five reviewers each work out the
  change set on their own or that "a later minor release" will change it;
  its Known behavior describes both modes, the defaults, the override, the
  read-only computation, the uncommitted-mode behavior, and the red
  interval; its Run directory section names `change-set.md` and the
  `diagnose-<name>` probe directory.
- Every sentence in the four files that counts skills or commands, describes
  the review scope, or names the run directory's files agrees with the
  SKILL, agent, and hook files.
- `plugin.json` still has `"version": "3.6.0"`, and `git diff` of the two
  manifests changes only description strings.
- `bash scripts/check-json.sh`, `bash scripts/check-all.sh`,
  `claude plugin validate --strict .`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 12: Add the 3.7.0 CHANGELOG entry and update the roadmap

**Status:** TODO

Depends on: Task 1-9

Plan Step 4.3 (rulings M8, B-9; clarifications C1–C3).

- `plugins/kenspc/CHANGELOG.md`: a `## 3.7.0 — unreleased` entry above
  `## 3.6.0 — 2026-09-25`, in the 3.6.0 entry's style. Added: the
  diagnose-bug skill and `/kenspc-diagnose` (tiers, reproduction first,
  hypothesis loop, the record, the tasks, the brief exit, the probe
  directory, the commits it makes — the one-time `.gitignore` commit
  included (C1) — and the not-reproduced stop, which removes the skill's own
  untracked test files before asking (C2)); `change-set.md`; the hook messages; the
  two guard extensions (counts unchanged). Changed: `REVIEW_SCOPE=changes`
  defined (modes, defaults with C3's empty-tree substitution, override,
  read-only computation) with the source
  stated — the v3.5.1 acceptance's Windows run, observation 2, where
  code-fixer committed the reviewed uncommitted file as a baseline
  (`5b4f1d4`) because nothing said how to handle an uncommitted change,
  recorded in that acceptance session and not under `docs/dry-runs/`;
  code-fixer's uncommitted mode; regression-verifier's check 4; the
  reviewers' three shared sections. Known behavior: the red interval after a
  diagnosis; fixes left uncommitted in an uncommitted run. No date: it is
  filled at release.
- `docs/roadmap.md`: remove the "Next minor" item that defines
  `REVIEW_SCOPE=changes` (today item 2) and renumber the rest; remove batch B
  from "Planned batches", keeping C.

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`
- `docs/roadmap.md`

**Acceptance criteria:**
- The CHANGELOG's first version heading is `## 3.7.0 — unreleased`, and the
  entry carries the Added, Changed, and Known behavior content above,
  including `5b4f1d4` and the observation-2 source line.
- `grep -n 'REVIEW_SCOPE=changes' docs/roadmap.md` prints nothing; the Next
  minor items are numbered consecutively from 1; "Planned batches" lists C
  and not B.
- `bash scripts/check-all.sh` exits 0.

---

### Task 13: Update the release checklist

**Status:** TODO

Depends on: Task 1-9

Plan Step 4.4 (rulings M14, M16, D1, D4, D5, D7; clarifications C1, C2). In
`docs/release-checklist.md`:

- Row 1: "Lists all 7 kenspc slash commands".
- A new smoke row 9 for `/kenspc-diagnose <observed bug>`, inserted after
  row 8; the end-to-end row becomes row 10, and its two "Row 9" / "row-9"
  references follow. Pass criterion, per plan Step 4.4: the trace shows the
  reproduction test written, run, and failing, then committed
  (`test: reproduce …`), before the task document is written;
  `docs/tasks/<name>.md` is committed (`docs: add task …`) and holds
  `## Diagnosis` with the nine labels in order, `### Task 1` with
  `**Status:** TODO`, and `### Task N: Doc-sync` when its Documentation
  impact lists documents; `/kenspc-task-implement <path>` passes its Step 1
  validation on it; the exit asks run-or-interactive; a run on a bug whose
  fix changes a function's signature writes `docs/briefs/<name>.md` starting
  `# Requirement Brief:` and no task document; when the diagnosis probed, its
  files are under `.kenspc/runs/<time>-diagnose-<name>/scratch/orchestrator/<n>/`
  and the checklist's `find` probe over that `scratch/` prints nothing; a
  request to explain a stack trace invokes no skill. Per C1, when the
  diagnosis probed in a project that did not yet ignore `.kenspc/`, the one
  commit besides the two above is the one-time `.gitignore` commit, and row
  9 accepts it. Per C2, a bug report the project cannot reproduce ends in a
  question, with no task document or brief, no commit, and no untracked test
  file left by the skill — or, when the removal was denied, that file named
  in the question.
- Row 7 additions for a run with no task document, per plan Step 4.4:
  `RUN_DIR/change-set.md` exists with `Mode:`; the FILE COVERAGE lists in
  `angle-1.md` … `angle-5.md` name the same files as it; between the
  invocation and the first reviewer dispatch the trace shows no `git commit`,
  `stash`, `checkout`, `add`, or `reset` by the orchestrator other than the
  one-time `.gitignore` commit; on a dirty tree, HEAD is unchanged after the
  run except for that commit, `git stash list` is unchanged, every FIXED
  row's Commit is `—`, and Next steps has the uncommitted-fixes bullet; on a
  clean tree ahead of its upstream, `Range:` is `<upstream>..<HEAD>` and the
  fix commits appear as before.
- The pre-flight counts stay `guards run: 10` and `self-tests run: 9`.

**Files to modify:**
- `docs/release-checklist.md`

**Acceptance criteria:**
- Row 1 says 7 commands; the smoke table has rows 1–10 in order, row 9 is
  `/kenspc-diagnose`, and row 10 is the end-to-end row.
- `grep -nE '[Rr]ow[- ]9' docs/release-checklist.md` finds only references
  that mean the new diagnose row; the end-to-end sub-criteria heading and the
  table cell say row 10.
- Row 9's pass criterion and row 7's additions carry every item listed
  above.
- The pre-flight block and its prose still say `guards run: 10` and
  `self-tests run: 9`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 14: Doc-sync

**Status:** TODO

Depends on: Task 1-13

Bring the documents below in line with what Tasks 1-13 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` § Project Overview, § Plugin Directory Layout, § Skill
  Development Conventions (skill count, hooks paragraph), § Subagent Review
  Architecture (orchestration patterns, effort paragraph, CONTEXT block
  contract, standalone classification), § Non-Goals, § Repository scripts/ —
  the diagnose-bug skill and command, the seven-skill counts, the diagnosis
  path, `change-set.md`, and the two guard extensions (plan Step 4.1);
  edited by Task 10: verify it against the implementation instead of editing
  it again.
- `plugins/kenspc/README.md` § Skills, § Commands, § Recommended Workflow,
  § Run directory, § Known behavior — the diagnose-bug row and command, the
  diagnosis entry path and tier-1 criterion, the diagnosis probe directory
  and `change-set.md`, the change-set definition, uncommitted mode, and the
  red interval (plan Step 4.2); edited by Task 11: verify it against the
  implementation instead of editing it again.
- `README.md` § Available Plugins (skills table, Commands line) — the
  diagnose-bug row and `/kenspc-diagnose` (plan Step 4.2); edited by
  Task 11: verify it against the implementation instead of editing it again.
- `plugins/kenspc/CHANGELOG.md` — the `## 3.7.0 — unreleased` entry (plan
  Step 4.3); edited by Task 12: verify it against the implementation instead
  of editing it again.
- `docs/roadmap.md` — the `REVIEW_SCOPE=changes` item and batch B removed
  (plan Step 4.3); edited by Task 12: verify it against the implementation
  instead of editing it again.
- `docs/release-checklist.md` — row 1, the new `/kenspc-diagnose` row, the
  row 7 additions (plan Step 4.4); edited by Task 13: verify it against the
  implementation instead of editing it again.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-13. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-13 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).

---

## Notes

- The plan's Documentation impact records three documents as unaffected:
  `docs/dry-runs/README.md`, `plugins/kenspc/references/plan-document-example.md`,
  and `plugins/kenspc/references/task-document-example.md`. No task edits
  them.
- After the last task, the release checklist's pre-flight block (effort
  diff, both `claude plugin validate --strict` runs, and
  `bash scripts/check-all.sh --self-test` with `guards run: 10` and
  `self-tests run: 9`) is the batch's mechanical check. Acceptance of the
  live chain runs in a separate session (plan § Testing Strategy).
