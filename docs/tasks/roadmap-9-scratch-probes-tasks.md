# Scratch Probes That No Test Runner Collects (Roadmap Items 9 and 2) — Task Document

## Context

Make the run directory's scratch space safe to leave behind. Every file an
agent writes under `RUN_DIR/scratch/` is named so the project's test runner
does not collect it. `code-fixer`, `regression-verifier`, and the
orchestrating session each get their own scratch subdirectory, and starting
over means a new subdirectory, never a delete. `regression-verifier` runs the
project's test command unmodified, so pollution that still happens fails the
run loudly. `code-fixer` never edits the project's configuration to make room
for the plugin's files.

Related plan: `docs/plans/roadmap-9-scratch-probes.md`. The plan is the
complete specification. Its Design decisions (M1–M7) and its Clarifications
during implementation (C1–C3) are binding rulings:

- C1 amends ruling M2's markers and the Fixed strings checklist probe.
- C2 extends Step 1.2 to code-fixer's OUTPUT FORMAT.
- C3 extends Step 3.4's roadmap edit.

Each task below cites its plan Step, which is the canonical source for what
to write. The criteria listed here are the local DONE bar.

Fixed forms. Every task that states one of these uses it exactly as written
here (plan Fixed strings, with C1 applied):

- Scratch layout: `RUN_DIR/scratch/angle-<n>/` (each reviewer, unchanged),
  `RUN_DIR/scratch/code-fixer/`, `RUN_DIR/scratch/regression-verifier/`,
  `RUN_DIR/scratch/orchestrator/` (the main session).
- Reset: a new subdirectory under the agent's own scratch directory (for
  example `scratch/angle-5/2/`); never a delete.
- Collection markers, vitest and jest: no `.test.` or `.spec.` segment in a
  file name, no file named `test.*` or `spec.*`, and no `__tests__`
  directory. Other runners: their configured pattern (pytest `test_*.py` /
  `*_test.py`, Go `_test.go`).
- Safe names: `probe.mts`, `probe-2.probe.ts`, and `.txt` for anything that
  need not run. Unsafe names: `probe.test.ts`, `test.ts`, and a copied
  `test/` tree that keeps its collectable names.
- Checklist probe: `find <RUN_DIR>/scratch \( -name '*.test.*' -o -name '*.spec.*' -o -name 'test.*' -o -name 'spec.*' -o -path '*/__tests__/*' \)`
  prints nothing.

This is plugin revision work. The files are Markdown: agent .md files,
SKILL.md files, the README, CLAUDE.md, the CHANGELOG, and docs. No
application code and no guard script is written (ruling M5). "Build / test /
lint" for each task is the repository's guard suite. After each file edit,
run the matching guard named in the task, then `bash scripts/check-all.sh`,
which must exit 0 with `guards run: 10`.

Constraints that apply to every task:

- The reviewer invariant sentence ("Each reviewer is read-only on the working
  tree and writes only under `RUN_DIR`: …") is not edited anywhere. It
  appears in four places:
  - the five reviewers' ROLE sections;
  - the canonical dispatch block in both review skills;
  - `plugins/kenspc/README.md` § Agents;
  - `CLAUDE.md` § Standalone safety classification.

  New rules are added after it.
- These blocks stay untouched:
  - the `canonical:dispatch`, `canonical:verdict-shared`, and
    `canonical:stats-line` blocks;
  - the code-craft canonical paragraphs, together with the
    `CODE-CRAFT PRINCIPLES` header and its guard comment;
  - the worked Schema B example between the `example:schema-b` markers.

  Inside `canonical:run-dir`, only the Scratch space bullet changes (Task 4).
- The five reviewers' shared sections stay byte-identical to each other.
- No new CONTEXT keys.
- `effort:` frontmatter and the per-skill `version: 3.0.0` are unchanged in
  every file.
- `plugin.json` and `marketplace.json` are not touched: no version bump in
  this batch. The CHANGELOG extends `## 3.6.0 — unreleased`.
- Rules are rationale-anchored ("Why: …" prose), with no `MUST` / `NEVER` /
  `CRITICAL`, no effort or reasoning tokens, and no model names
  (`check-no-model-names.sh`).
- Code, comments, commit messages, and documents are in English.
- Each task is one conventional commit that stages only the files the task
  lists, together with the task's status update:
  - `fix(agents): …` for Tasks 1–3 and `fix(skills): …` for Task 4;
  - `docs: …`, `docs(claude-md): …`, `docs(release): …`, and `docs: …` for
    Tasks 5–8;
  - `docs: …` for the Doc-sync task.

Dependency note: Tasks 1–4 (plan Phases 1–2) are independent of each other.
Tasks 5–8 (plan Phase 3) document the finished behavior and cannot start until
Tasks 1–4 are DONE (`Depends on: Task 1-4`). Task 9, the Doc-sync task, runs
last and needs Tasks 1–8. It reconciles the documents with what those tasks
implemented and promotes their recorded decisions.

## Tasks

### Task 1: Add the scratch naming, execution, and reset rule to the five reviewers' ROLE sections

**Status:** TODO

Plan Step 1.1 (rulings M1–M3, clarification C1). The new paragraph goes in
each reviewer's ROLE section:

- after the existing paragraph that begins "You write these only when the
  CONTEXT block provides RUN_DIR" and ends "keeps five parallel reviewers from
  writing the same file.";
- before the OBJECTIVE heading.

The paragraph is byte-identical in all five files. It says, in substance:

- Name every file under your scratch directory so the project's test runner
  will not collect it. For vitest and jest that means the collection markers
  in the Context's Fixed forms. For other runners, it means whatever their
  configuration collects.
- `probe.mts`, `probe-2.probe.ts`, and a `.txt` copy are safe.
  `probe.test.ts` and `test.ts` are not.
- A copied `test/` tree keeps its collectable names unless you rename the
  files as you copy them.
- A probe that has to execute runs as a plain script, or through a runner
  config kept in your scratch directory that includes only your probes.
- To start over, make a new subdirectory under your scratch directory rather
  than deleting.
- Why: the run directory is git-ignored, not tool-ignored. A runner walking
  the tree collects the probes, and the project's own test command fails. A
  fixer that then edits the project's test configuration has changed the
  user's project to make room for the plugin's files.

Write the paragraph once and copy it into the other four files.
`check-review-agent-drift.sh` extracts ROLE up to the next line made only of
capital letters and spaces. So no line of the paragraph may consist solely of
capitals and spaces.

**Files to modify:**
- `plugins/kenspc/agents/requirements-reviewer.md`
- `plugins/kenspc/agents/edge-case-reviewer.md`
- `plugins/kenspc/agents/quality-reviewer.md`
- `plugins/kenspc/agents/bug-reviewer.md`
- `plugins/kenspc/agents/test-reviewer.md`

**Acceptance criteria:**
- The paragraph is present in all five ROLE sections, directly after the
  paragraph ending "keeps five parallel reviewers from writing the same file."
  and before OBJECTIVE. It states each of the following:
  - the vitest and jest markers exactly as in the Fixed forms;
  - the other-runners clause;
  - the safe and unsafe examples, including the renamed `test/` copy;
  - both execution options;
  - reset as a new subdirectory;
  - the git-ignored-not-tool-ignored Why.
- `git diff` of each file shows only added lines. The invariant sentence and
  every existing ROLE line are unchanged.
- `bash scripts/check-review-agent-drift.sh` exits 0, and ROLE is reported
  identical across 5 reviewers.
- `bash scripts/check-no-model-names.sh` and `bash scripts/check-all.sh`
  exit 0.

---

### Task 2: Give code-fixer its own scratch directory, the scratch rule, the no-configuration-edit rule, and the scratch-pollution note

**Status:** TODO

Plan Step 1.2 (rulings M1, M3, M4, clarifications C1, C2). This task makes
three edits.

In the `RUN_DIR` bullet under CONTEXT YOU WILL RECEIVE, replace the current
sentence "Put probe files, copies, and other temporary files under
`RUN_DIR/scratch/` — … so no `rm -rf` is needed." The new text says:

- This agent's scratch directory is `RUN_DIR/scratch/code-fixer/`.
- The naming, execution, and reset rule of Task 1 applies, in this file's own
  words (this file is not a byte-identity carrier). It covers:
  - the vitest and jest markers from the Fixed forms, and other runners'
    configured patterns;
  - mutant copies of the test tree, whose files are renamed as they are
    copied and run through a runner config kept in
    `RUN_DIR/scratch/code-fixer/` whose `include` matches the renamed files
    (ruling M3, option a);
  - reset as a new subdirectory, never a delete.
- The existing point stays: the directory is git-ignored with the run
  directory and needs no cleanup.
- The no-configuration-edit rule. Never modify the project's configuration —
  test-runner config, ignore files, `tsconfig`, package scripts — to
  accommodate files the plugin wrote under the run directory. If the
  project's test command fails only because of scratch files, report it in
  the scratch-pollution note naming the files. Verify fixes with a narrowed
  command if needed. Why: a configuration change made for the plugin's own
  files is a change to the user's project that the user did not ask for, and
  it hides the pollution instead of removing it.

In OUTPUT FORMAT (clarification C2), define the scratch-pollution note:

- The sentence listing `schema-b.md`'s parts gains an optional
  scratch-pollution note. It sits after the Deferred Issues prose section
  and before the statistics line, which stays the file's last line.
- A short definition paragraph, next to the other parts' definitions, says
  when the note appears and what it contains. It appears when the project's
  test command fails only because of files under `RUN_DIR/scratch`. It holds
  those paths and the narrowed command used to verify the fixes.
- The "reply with only:" list gains the note as an optional item.

The Deferred Issues definition, the worked example between the
`example:schema-b` markers, and the `canonical:stats-line` block are
unchanged.

**Files to modify:**
- `plugins/kenspc/agents/code-fixer.md`

**Acceptance criteria:**
- The `RUN_DIR` bullet names `RUN_DIR/scratch/code-fixer/` and states:
  - the naming rule with the Fixed-forms markers;
  - the renamed-copy and scratch-local runner-config method;
  - reset as a new subdirectory;
  - the no-configuration-edit rule with its Why.
- OUTPUT FORMAT names the optional scratch-pollution note:
  - in the `schema-b.md` part list, between Deferred Issues and the
    statistics line;
  - in a definition paragraph;
  - in the reply list.

  The statistics line is still described as the file's last line.
- `git diff` shows no change between the `example:schema-b` markers or the
  `canonical:stats-line` markers.
- `bash scripts/check-run-contract.sh` and
  `bash scripts/check-run-contract.sh --self-test` exit 0.
- Build a test copy outside the repository (the session scratchpad or a
  temporary directory). Take the lines between the `example:schema-b`
  markers and insert a scratch-pollution paragraph just before the statistics
  line. `bash scripts/check-run-contract.sh --file <that copy>` exits 0.
- `bash scripts/check-code-craft-canonical.sh`,
  `bash scripts/check-no-model-names.sh`, and `bash scripts/check-all.sh`
  exit 0.

---

### Task 3: Give regression-verifier its own scratch directory and the scratch rule, and run the test command unmodified

**Status:** TODO

Plan Steps 1.2 and 1.3 (rulings M1, M3, M4, clarification C1). This task
makes two edits.

In the `RUN_DIR` bullet under CONTEXT YOU WILL RECEIVE, replace the current
sentence "Put probe files, copies, and other temporary files under
`RUN_DIR/scratch/` — … so no `rm -rf` is needed." The new text says:

- This agent's scratch directory is `RUN_DIR/scratch/regression-verifier/`.
- The same naming, execution, and reset rule as Task 2, in this file's own
  words:
  - the vitest and jest markers from the Fixed forms, and other runners'
    configured patterns;
  - mutant copies renamed as copied and run through a runner config kept in
    its scratch directory;
  - reset as a new subdirectory, never a delete.
- The existing point stays: the directory is git-ignored with the run
  directory and needs no cleanup.

In VERIFICATION CHECKS item 3, add a clause after the opening sentence "run
the project's build, test, and lint commands; record PASS or FAIL.". The
clause says:

- Run the project's test command as the project configures it
  (`package.json` scripts, CLAUDE.md, the solution or `pytest` config), with
  no path filter or exclude added.
- When the run fails only because of files under `RUN_DIR/scratch`, record
  FAIL with the offending paths in the Detail cell.
- A narrowed re-run may be added to Detail as information, but it does not
  change the Result.
- Why: the batch A acceptance run passed row 3 on `--dir test` while the
  project's own `npm test` failed. A green row that hides the plugin's
  pollution is worse than a red one.

These stay unchanged:

- the three run-state bullets (full clean, involuntarily incomplete,
  intentionally skipped);
- the paragraph that tells the last two apart;
- FALLBACK FOR NO-TEST-SUITE PROJECTS;
- Schema C.

**Files to modify:**
- `plugins/kenspc/agents/regression-verifier.md`

**Acceptance criteria:**
- The `RUN_DIR` bullet names `RUN_DIR/scratch/regression-verifier/` and
  states the naming rule with the Fixed-forms markers, the renamed-copy
  method, and reset as a new subdirectory.
- Item 3 carries the unmodified-command clause, the scratch-only-failure
  FAIL rule with the paths in Detail, and the narrowed-re-run-is-information
  rule, with its Why.
- `git diff` shows these unchanged: the three run-state bullets, the
  paragraph after them, FALLBACK FOR NO-TEST-SUITE PROJECTS, OUTPUT FORMAT,
  and the frontmatter.
- `bash scripts/check-verdict-shared.sh`,
  `bash scripts/check-no-model-names.sh`, and `bash scripts/check-all.sh`
  exit 0.

---

### Task 4: Rewrite the Scratch space bullet in the canonical run-dir block of both review skills

**Status:** TODO

Plan Step 2.1 (ruling M1, clarification C1). Inside
`<!-- canonical:run-dir:start/end -->`, rewrite the "Scratch space" bullet.
It says:

- Probe files, copies, and other temporary files go under `RUN_DIR/scratch/`:
  - each reviewer in `scratch/angle-<n>/`;
  - code-fixer in `scratch/code-fixer/`;
  - regression-verifier in `scratch/regression-verifier/`;
  - the orchestrating session itself in `scratch/orchestrator/` when it runs
    a probe of its own.
- Every file there is named so the project's test runner does not collect it:
  - vitest and jest: the markers exactly as in the Fixed forms;
  - other runners: their configured pattern.
- Starting over means a new subdirectory, never a delete.
- The existing Why stays. It reads: deleting temporary files with `rm -rf`
  can be denied by the user's permission rules, and a verifier that could not
  clean up has fallen back to judging fixes by reading code.
- Add one sentence of Why: the run directory is git-ignored, not
  tool-ignored, so a test runner walking the tree collects scratch files that
  look like tests.

Edit the block in `task-review/SKILL.md`, then copy it byte for byte into
`task-implement/SKILL.md`.

The bullet must still begin with the literal `- Scratch space:`, and that
literal must stay on exactly one line in each file. Why:
`check-run-contract.sh --self-test` mutates exactly that string and reports
the fixture as stale when it finds it on zero lines or on more than one. For
the same reason, `check-ignore -q .kenspc/runs/probe` stays unchanged, on
exactly one line in each file.

**Files to modify:**
- `plugins/kenspc/skills/task-review/SKILL.md`
- `plugins/kenspc/skills/task-implement/SKILL.md`

**Acceptance criteria:**
- The Scratch space bullet in both files names all four scratch
  directories, including `scratch/orchestrator/`. It also states:
  - the Fixed-forms markers;
  - the other-runners clause;
  - reset as a new subdirectory;
  - the kept `rm -rf` Why and the one-sentence tool-ignored Why.
- `git diff` shows no change to any other bullet or paragraph inside
  `canonical:run-dir`, and no change outside it.
- `- Scratch space:` occurs on exactly one line of each file, and so does
  `check-ignore -q .kenspc/runs/probe`.
- `bash scripts/check-run-contract.sh --self-test` exits 0.
- `bash scripts/check-canonical-dispatch.sh`,
  `bash scripts/check-verdict-shared.sh`,
  `bash scripts/check-no-model-names.sh`, and `bash scripts/check-all.sh`
  exit 0.

---

### Task 5: Update the plugin README's Run directory section

**Status:** TODO

Depends on: Task 1-4

Plan Step 3.1 (clarification C1). This task edits
`plugins/kenspc/README.md` § Run directory.

The layout tree shows `scratch/` holding one subdirectory per agent:
`angle-<n>/` per reviewer, `code-fixer/`, `regression-verifier/`, and
`orchestrator/`.

Rewrite the bullet that begins "The reviewers, `code-fixer`, and
`regression-verifier` keep probe files". It says:

- Each agent keeps its probe and temporary files in its own subdirectory of
  the run's `scratch/`, and the orchestrating session keeps its own in
  `orchestrator/` when it probes.
- Every file there is named so the project's test runner does not collect it
  (the Fixed-forms markers; other runners: their configured pattern).
- An agent that starts over makes a new subdirectory instead of deleting.
- No agent edits the project's configuration (runner config, ignore files,
  `tsconfig`, package scripts) to make room for the plugin's files.
- If scratch files still break the project's test command,
  `regression-verifier` fails the run and names them.

The invariant paragraph in § Agents ("Each reviewer is read-only on the
working tree …") is unchanged.

**Files to modify:**
- `plugins/kenspc/README.md`

**Acceptance criteria:**
- The layout tree names `code-fixer/`, `regression-verifier/`, and
  `orchestrator/` under `scratch/` alongside `angle-<n>/`.
- The probe-files bullet states:
  - the per-agent subdirectories;
  - the naming rule with the Fixed-forms markers;
  - the reset rule;
  - the no-configuration-edit rule;
  - the verifier's loud failure.
- Nothing in the section contradicts Tasks 1–4 as implemented.
- `git diff` touches only § Run directory. The § Agents invariant paragraph
  is unchanged.
- `bash scripts/check-all.sh` exits 0.

---

### Task 6: Update CLAUDE.md: the run-dir paragraph and a git-ignored-is-not-tool-ignored lesson

**Status:** TODO

Depends on: Task 1-4

Plan Step 3.2 (ruling M6, clarification C1). This task makes two edits.

In § Subagent Review Architecture, rewrite the paragraph that begins "Since
v3.5 the agents exchange reports through a per-run directory". It currently
says `code-fixer` writes "only `schema-b.md` and `scratch/`". It must name
the per-agent scratch directories: `scratch/angle-<n>/`,
`scratch/code-fixer/`, `scratch/regression-verifier/`, and
`scratch/orchestrator/` for the main session. It must also state the naming
rule (the Fixed-forms markers; other runners: their configured pattern). The
directories and the rule together go in one sentence. The paragraph's other
statements (per-agent report files, the one-time `.gitignore` commit, issue
IDs) are kept.

Under "Plugin Design Lessons (Cumulative)", add a lesson after "Hook logic
that depends on harness-private encodings goes stale silently", in the
existing lessons' form: a `###` heading, prose, and a `Background:` line. It
says, in substance:

- **Git-ignored is not tool-ignored.**
- An ignored directory inside the project is skipped by git and by nothing
  else. Test runners, linters, and compilers walk the tree by their own
  patterns, so a scratch file that looks like a test is a test.
- Name scratch files outside those patterns.
- Treat a tool that trips over them as a plugin defect, never as a reason to
  change the user's configuration.
- Background: the batch A acceptance run,
  `docs/dry-runs/batch-a-acceptance.md` § 8.

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- The run-dir paragraph names all four scratch locations and the naming rule
  in one sentence. It no longer says code-fixer writes to `scratch/` itself.
- The new lesson is the last one under "Plugin Design Lessons (Cumulative)".
  It has its heading, the substance above, and the Background line citing
  `docs/dry-runs/batch-a-acceptance.md` § 8.
- The invariant sentence under § Standalone safety classification is
  unchanged. `git diff` touches no other section.
- `bash scripts/check-all.sh` exits 0.

---

### Task 7: Update the release checklist's run-directory check

**Status:** TODO

Depends on: Task 1-4

Plan Step 3.3 (ruling M5, clarification C1). This task edits
`docs/release-checklist.md`, in the "Run-directory check for rows 6 and 7"
list.

The bullet that places code-fixer's and regression-verifier's files "in
`scratch/` itself" now names their directories:

- `scratch/code-fixer/`;
- `scratch/regression-verifier/`;
- `scratch/orchestrator/`, for the orchestrating session's files when it
  probed.

Add three sub-checks:

1. The checklist probe from the Fixed forms, with `<RUN_DIR>` the run's
   directory, prints nothing.
2. After the run, the project's own test command passes unmodified from the
   repository root.
3. The working tree gained no runner or ignore configuration from any agent:
   `git status --short` lists no such file, and no fix commit touches one.

**Files to modify:**
- `docs/release-checklist.md`

**Acceptance criteria:**
- The bullet names `scratch/code-fixer/` and `scratch/regression-verifier/`
  and no longer says "in `scratch/` itself".
- The three sub-checks are present. The first carries the checklist probe
  verbatim from the Fixed forms.
- The pre-flight lines still read `guards run: 10` and `self-tests run: 9`.
  No smoke-table row outside the run-directory check changed.
- `bash scripts/check-all.sh` exits 0.

---

### Task 8: Record the change in the 3.6.0 CHANGELOG entry and update the roadmap

**Status:** TODO

Depends on: Task 1-4

Plan Step 3.4 (ruling M1, clarification C3). This task edits two files.

In `plugins/kenspc/CHANGELOG.md`, under `## 3.6.0 — unreleased` →
`### Changed`, add entries for:

- the scratch layout: per-agent subdirectories, including `code-fixer/`,
  `regression-verifier/`, and `orchestrator/`;
- the naming and reset rule, with the Fixed-forms markers;
- the verifier's unmodified test command, with a scratch-only failure as
  row-3 FAIL naming the files;
- code-fixer's no-configuration-edit rule and the optional scratch-pollution
  note in Schema B.

The entries cite `docs/dry-runs/batch-a-acceptance.md` § 8 as the source.

In `docs/roadmap.md`:

- Remove items 2 and 9, and renumber the remaining items 1–7 with their text
  unchanged.
- Extend the release note "At release, delete …" to name four files:
  - `docs/plans/batch-a-doc-sync.md`;
  - `docs/tasks/batch-a-doc-sync-tasks.md`;
  - `docs/plans/roadmap-9-scratch-probes.md`;
  - `docs/tasks/roadmap-9-scratch-probes-tasks.md`.

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`
- `docs/roadmap.md`

**Acceptance criteria:**
- The 3.6.0 `### Changed` section carries entries for the four items above,
  citing the acceptance record. No other version's entry changed.
- `docs/roadmap.md` lists seven items numbered 1–7, whose texts are former
  items 1 and 3–8 unchanged. Neither the scratch rule (former item 2) nor the
  runner-safe probe names (former item 9) remains.
- The release note names the four files.
- The Planned batches section is unchanged.
- `bash scripts/check-all.sh` exits 0.

---

### Task 9: Doc-sync

**Status:** TODO

Depends on: Task 1-8

Bring the documents below in line with what Tasks 1-8 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` § Subagent Review Architecture (run-dir paragraph), § Plugin
  Design Lessons (Cumulative) — the per-agent scratch directories and the
  naming rule; the git-ignored-is-not-tool-ignored lesson (plan Step 3.2);
  edited by Task 6: verify it against the implementation instead of editing
  it again.
- `plugins/kenspc/README.md` § Run directory — the scratch layout, the naming
  and reset rule, no configuration edits for the plugin's files (plan
  Step 3.1); edited by Task 5: verify it against the implementation instead
  of editing it again.
- `docs/release-checklist.md` § Run-directory check for rows 6 and 7 — the
  per-agent scratch directories and the three sub-checks (plan Step 3.3);
  edited by Task 7: verify it against the implementation instead of editing
  it again.
- `plugins/kenspc/CHANGELOG.md` § 3.6.0 — Changed entries for the scratch
  layout, the naming and reset rule, the verifier's unmodified test command,
  and code-fixer's no-configuration-edit rule (plan Step 3.4); edited by
  Task 8: verify it against the implementation instead of editing it again.
- `docs/roadmap.md` — items 2 and 9 removed, the rest renumbered, the release
  note naming four files (plan Step 3.4); edited by Task 8: verify it against
  the implementation instead of editing it again.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-8. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-8 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).

---

## Notes

- The plan's Documentation impact records `README.md` (root) as
  `N/A for this document`: it does not describe the run directory. That
  record is not a document entry, so it is not in the Doc-sync list.
- The acceptance run (ruling M7) needs an interactive session with the
  updated plugin loaded through `--plugin-dir`. It runs `/kenspc-task-review`
  once in a throwaway macOS TypeScript project that has vitest and no vitest
  config. That run is not part of this task-implement run. Following the
  batch A precedent, its report is filed as
  `docs/dry-runs/scratch-probes-acceptance.md` before this task document is
  deleted at release.
- After the implement run, the orchestrating session runs the plan's
  mechanical checks (Testing Strategy):
  - `bash scripts/check-all.sh --self-test`, expecting `guards run: 10` and
    `self-tests run: 9`;
  - `claude plugin validate --strict .`;
  - `claude plugin validate --strict ./plugins/kenspc`;
  - a check that the set of files carrying an `effort:` override
    (`task-implementer`, `code-fixer`, `generate-plan`) is unchanged.
