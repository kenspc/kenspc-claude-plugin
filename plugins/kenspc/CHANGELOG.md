# Changelog

> **Note on v1.x entries:** Entries for v1.0.0 through v1.5.0 were
> backfilled from git history on 2026-05-11. The original releases shipped
> without CHANGELOG documentation — the project was a single-maintainer
> dogfooding effort during the v1.x line, with version bumps recorded only
> in `plugin.json` and commit messages. The backfilled entries reconstruct
> Added/Changed/Removed scope from commit messages and `git diff`; for the
> authoritative source, see git log between commits `871c7e3` (initial,
> 2026-03-29) and `7328cec` (v1.5.0 docs, 2026-05-04).

## 3.8.1 — unreleased

Batch D. Three stops an unattended run got wrong get a defined answer:
generate-plan's approval stop, in a session that cannot ask, ends at the
draft printed in full, with nothing written, reviewed, or committed, until
a later reply approves it; generate-plan takes an `answered` brief entry as
settled input only when it holds `Answer:`, and asks about or carries one
without; and the prototype skill asks before it touches a named entry
whose status word it does not recognize or that already holds an answer,
stopping with the brief unchanged in a session that cannot ask.
diagnose-bug's interactive exit names the reproduction commit and
`git revert <hash>`. Three copied strings gain a guard — the reviewer
invariant sentence's README, CLAUDE.md, and task-review copies, the
Prototype line in generate-brief and the prototype skill, and the
prototype skill's two leftovers commands — inside two existing guards, so
the guard counts are unchanged (`guards run: 10`, `self-tests run: 9`).
Known behavior gains what a red reproduction test does to later review
runs and what the one-time `.gitignore` commit takes with it. No new
command, skill, agent, or CONTEXT key, so a patch release. Release smoke:
the batch's acceptance record, named in the release commit.

### Changed

- **generate-plan, approval stop.** Phase 2 Step 3's approval stop gains a
  branch for a session that cannot ask: the run still stops there, and its
  last message holds the complete draft after self-challenge — every
  section, none elided or summarized — then the line
  `Plan not written: awaiting approval.`, in English in any conversation
  language, and how to go on: reply approving the draft or asking for
  changes (a headless run resumes with
  `claude -p --resume <session id> "<reply>"`), or run `/kenspc-plan` again
  in a session that can ask. No file is written, `plan-document-reviewer` is
  not dispatched, and nothing is committed; a later reply that approves the
  draft is the approval, and the step then runs as written. Source: the
  batch C acceptance (`docs/dry-runs/batch-c-acceptance.md`, F1), where a
  run under a reminder to work without stopping wrote, reviewed, and
  committed an unapproved plan. The 3.8.0 entry's "a session that cannot
  ask still writes the plan only on approval" described the skill's text,
  which that run did not follow; the stop had no cannot-ask branch. The
  existing-file question on the approved path gains one too: in a session
  that cannot ask, the plan is created alongside as `<name>-2.md` and named
  in the final message, not overwritten.
- **generate-plan, answered entries.** An `answered` brief entry is settled
  input only when it holds `Answer:` — not by its status word alone, and not
  by a `Prototype:` line alone; a plan relying on one cites its prototype
  hash, or the entry itself (`<brief path>, entry <n>`) when it has no
  Prototype line. One without `Answer:` — as the brief has it, or as the
  user marks an unrecognized entry in the gap round — is a gap: the gap
  round quotes it and asks for its answer, in the same question that asks an
  unrecognized entry's status, so the one-to-two-round limit holds. An entry
  the rounds leave without an answer, and every such entry in a session
  that cannot ask, is carried into the plan's Open Questions in the `open`
  form with `From: <brief path>, entry <n>, status word answered, Answer: missing`.
- **prototype.** A named entry whose status word the skill does not
  recognize — hand-edited, translated, or missing — and that holds neither
  `Answer:` nor `Prototype:` is asked about before anything is written,
  quoting the word found: prototype it, or stop. A session that cannot ask
  stops with the entry unchanged. The `answered` gate (prototype it again?)
  now also takes any named entry that holds `Answer:`, whatever its status
  word, and an unrecognized one that holds `Prototype:`; a
  `needs prototype` entry with `Prototype:` and no `Answer:`, the form an
  unsettled attempt leaves, is still prototyped again. Both gates come
  before Phase 1 writes to the brief — the entry appended for a question
  given as text, or a derived `Settled by:` — since the brief is not
  committed and a write there cannot be undone.
- **diagnose-bug.** On "interactively" at the exit, when Phase 1 committed a
  reproduction test, the last message names that commit, says its test
  fails — and every review run in the repository reports the test run
  FAIL — until the fix lands, and gives `git revert <hash>` for backing it
  out if the fix is not made; the skill does not revert it unasked. Before,
  only "Ending without a document" named the commit.
- **Guards.** `check-run-contract.sh` gains check 6: the reviewer invariant
  sentence, extracted at run time from `requirements-reviewer.md`'s ROLE
  and compared whitespace-normalized, must be contained in the plugin
  README, CLAUDE.md, and task-review's canonical dispatch block. Before,
  `check-review-agent-drift.sh` held the five ROLE sections and
  `check-canonical-dispatch.sh` the two dispatch blocks, but nothing tied
  one family to the other or held the README and CLAUDE.md copies. Its
  self-test copies the README and CLAUDE.md too and gains five mutations
  that must exit 1 (one word changed in each copy and in the reference, and
  one on the README copy's last line, so an extraction that stops short of
  the sentence's period is caught), one whitespace-only change that must
  exit 0, and one rewording of the reference's opening words that must
  exit 2. Its header now states the
  number of must-exit-1 mutations the self-test runs, nineteen; it said
  eleven where the script ran fourteen. `check-doc-sync-anchors.sh` gains a
  fifth anchor group, the Prototype line in generate-brief and the prototype
  skill, and one exact-count check: the prototype skill's leftovers command
  (`git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`)
  occurs exactly twice, counted by occurrence, since the start snapshot and
  the Exit compare their two lists path by path. Its self-test gains three
  mutations that must exit 1 (the Prototype line changed, one leftovers
  command changed, a third appended). Guard counts are unchanged.
- **Release checklist.** Row 4 gains the cannot-ask stop at the draft (the
  complete draft and `Plan not written: awaiting approval.`; no Write, no
  Agent call, no commit), the resumed approval that writes, reviews, and
  commits, and an `answered` entry with no `Answer:` (asked about in the gap
  round; carried with `status word answered, Answer: missing` in a session
  that cannot ask). Row 9 gains the interactive exit's commit and
  `git revert <hash>`, with no revert made. Row 10 gains both gates, asked
  before anything is written, and their cannot-ask stop with no commit and
  the brief's sha256 unchanged. No new row; pre-flight counts unchanged.
- CLAUDE.md's cannot-ask list gains generate-plan's approval stop and
  existing-file question; its prototype path paragraph names `Answer:` as
  what makes an answered entry settled input; its guard descriptions,
  Non-Goals, and Maintenance note follow the two guards' new checks. The
  plugin README's `generate-plan` row gains the cannot-ask stop at the
  draft, its `prototype` row the two new questions and their cannot-ask
  outcome, and its Prototype path paragraph the `Answer:` rule and the
  status-word question.

### Known behavior

- **Red interval and review runs.** While diagnose-bug's reproduction test
  is red, every review run in the repository — `/kenspc-task-review`, and
  the review phase of a `/kenspc-task-implement` run in which the fix task
  did not land — records the test run FAIL and the verdict FAIL:
  regression-verifier runs the project's commands as configured, with no
  filter added, and has no notion of a failure that predates the run. A
  mutation check whose copy runs the reproduction test cannot make its
  unmutated copy pass first, so it is reported as not made. Behavior
  unchanged; the plugin README's "Red interval after a diagnosis" now says
  so.
- **Uncommitted `.gitignore` edits.** The one-time commit that adds
  `.kenspc/` to `.gitignore` stages and commits the whole file, so an edit
  to `.gitignore` not yet committed, staged or not, goes into
  `chore: ignore kenspc run directory`. Behavior unchanged; the plugin
  README's Known behavior now says so.

## 3.8.0 — 2026-09-26

Batch C. A brief records what its discussion could not settle in a
`## Open Questions` section, marking an entry a small experiment would
settle `needs prototype` with the result that would settle it. A
`prototype` skill and its `/kenspc-prototype` command answer one such
question with a throwaway prototype — logic, UI, or a feature slice —
committed alone and removed in the next commit, its answer, evidence, and
commit hash written into the brief; it has no review phase, stops only at
its gates, and gives each gate that asks a branch for a session that cannot
ask. generate-plan stops on a `needs prototype` entry to ask whether to
prototype it first or carry it into the plan, and takes `open` entries into
its gap-check; a plan that relies on an answered entry cites its hash. The
reminder hook names the new skill beside the other brief writers. Known
behavior covers what surrounds a prototype: the project's gates between its
two commits, the files left on disk, and its place in history. A new
command, so a minor release. No new agent, no CONTEXT key changes, and the
guard counts are unchanged. Release smoke: the batch's acceptance run,
`docs/dry-runs/batch-c-acceptance.md`, headless on macOS — smoke row 3;
row 4's exit, its cannot-ask case, and a run after the prototypes; row 10
with the default location, a CLAUDE.md location, an in-app UI prototype,
the development database insisted on, and a question with no brief; the
counter-case on whether the project's vitest and tsc collect prototype
files (eslint not exercised); and the pre-flight block. Of its two
findings, the prototype skill's frame, not shown when no gate stopped the
run, was fixed before this release and its two cases re-run to PASS on the
released skill text; generate-plan writing the plan without approval in a
session that cannot ask, a behavior deviation at a stop this release did
not change, is recorded in the roadmap. No separate smoke run was made for
the other rows.

### Added

- **Open Questions in briefs.** generate-brief's template gains an
  always-present `## Open Questions` section between `## Context` and
  `## Discovery Notes`, its body `none` when nothing is open. Each numbered
  entry starts with its status word in backticks — `open` (a question
  neither discussion nor a small experiment settles), `needs prototype` (one
  a small experiment settles), or `answered` (written only by the prototype
  skill) — then ` — ` and the question. A `needs prototype` entry carries
  `Settled by:`, the result that answers it, named before any prototype
  runs so the evidence is measured against it and cannot be bent to fit.
  An answered entry keeps the question and `Settled by:` and adds
  `Answer:`, `Evidence:` (what was run, what it showed, and the case that
  could have shown the opposite), and
  ``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` ``;
  an attempt that did not settle the question keeps `needs prototype` and
  adds `Evidence:`, with `Prototype:` when a prototype was committed. The
  `## Open Questions` heading, the status words, and the labels stay in
  English whatever the brief's language. The grammar is written once, in
  generate-brief's writing rules, and generate-plan and the prototype
  skill point at it. The status is not a `**Status:**` line, which marks a
  task document.
- **`prototype` skill and `/kenspc-prototype`.** Answers one question from a
  brief — a `needs prototype` entry named by number, the brief's only one,
  or a question given as text and appended to the brief first — with a
  throwaway prototype: logic, UI, or a feature slice. Three phases (Frame,
  Build and run, Record and discard) and no review phase: the prototype is
  discarded, and its answer is reviewed where a plan uses it. The command
  carries `disable-model-invocation: true`; the skill routes by its
  description, which names what it is not for (a feature to keep, running a
  snippet, fixing a bug). A question with no brief — or a path that names
  no file, or a file that is not a brief — stops with a `/kenspc-brief`
  suggestion and builds nothing; an entry number that names no entry stops
  with the brief unchanged.
  - **The gates.** No general confirmation: before the prototype's first
    file is written, the skill sends its frame (the question,
    `Settled by:`, the kind, the location, and the resources, among them
    the tracked files an in-app prototype modifies) as a message of its
    own, with a gate's question after it when one asks, and goes on,
    stopping only at a gate — no arguments; several
    `needs prototype` entries, none named; a named `answered` entry; a
    location conflict; an in-app UI prototype with no CLAUDE.md location,
    or with a dirty tracked file or a manifest change; a feature prototype
    that cannot run outside the app; a connection the development
    configuration does not name; a new table or column on the development
    database; an answer that is the user's judgment; a failed commit. Each
    gate that asks has a branch for a session that cannot ask — a stop, the
    first entry in document order, the default location, a connection left
    unused, a throwaway database, nothing built with the entry left
    unsettled and the reason in `Evidence:`, or, for an answer that is the
    user's judgment, the prototype committed and removed with the entry
    left unsettled and `Evidence:` saying what to look at and how — and
    every default so taken is named in the final message.
  - **The two commits.** `chore: add prototype <slug>`, made after the run
    that produced the evidence, staging only the prototype's own paths by
    pathspec; the brief entry rewritten; then `chore: remove prototype
    <slug>`, its body carrying `Question:`, `Answer:` or `Not settled:`,
    and `Prototype: <hash>` — `git rm` for the paths the add commit added
    and the parent's content for the ones it modified, checked by
    `git diff <add commit>^ HEAD` over those paths printing nothing. Both
    subjects follow the project's commit conventions. The brief is not
    committed. A failed commit stops the run with no retry and no
    `--no-verify`; a rejected add commit leaves the prototype's paths
    staged, and the report names them with `git reset -q --`, which
    unstages them. A run that stops between the two commits — a rejected
    remove commit, whose removal is left staged; a teardown that fails or
    leaves a table it created; a path that changed after the add commit —
    names the add commit and gives the commands that would remove it,
    without running them. A path that changed after the add commit is left
    out of those commands and named, so its edit can be saved before the
    prototype is taken out of it by hand — a path the add commit added
    deleted, one it modified restored to its content in the add commit's
    parent.
  - **Where it lives.** `prototypes/<slug>/` at the repository root unless
    the project's CLAUDE.md names another location; its file names follow
    the naming rule of the `canonical:run-dir` block's Scratch space bullet,
    by reference. None of the project's build, test, or lint commands runs
    on the prototype, and no configuration is edited to exclude it.
    Dependencies go into the prototype's own manifest.
  - **The in-app exception, UI only.** A UI prototype that can only render
    inside the app goes into it, at a location from CLAUDE.md or the user;
    the project's typecheck runs before building as a baseline — one that
    cannot run is no baseline, and nothing is built — and is green against
    it before the add commit, and the remove commit restores every tracked
    file the add commit modified. Going on with a tracked file that holds
    uncommitted changes carries them into the add commit, and after the
    remove commit they live only there; the final message names each such
    file with `git show <add commit>:<path>`. A feature prototype that
    needs the app's runtime runs from its location, importing the app's
    modules, or is not built, its entry left `needs prototype` with the
    reason; widening the exception to features is the user's decision.
  - **The development database.** Recognized by name only — a
    development-named configuration file (`appsettings.Development.json`,
    `.env.development`, `.env.development.local`), the project's
    user-secrets, or one the project's CLAUDE.md or README names; any other
    connection is asked about, and production resources are never touched.
    A new table or column gets a warning that the development database may
    be the wrong place, and a throwaway-database recommendation, before any
    code; a user who insists is recorded in `Evidence:`, and a teardown
    drops what the prototype created. Rows written to existing tables get
    no warning and no teardown, and `Evidence:` names each such table. No
    migration is added or applied, with any tool. Credentials and
    connection strings are read by name at run time and never committed;
    the staged diff is read for one before the add commit, and a file kept
    out for holding one stays on disk, marked in the leftovers list.
  - **What is left on disk.** The final message lists what
    `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`
    still shows — installed dependencies, build output, a local database
    file, ignored and untracked alike, non-ASCII names unescaped — for the
    user to remove: an ignored directory such as `node_modules/` as one
    line, a directory holding only untracked files the run left named once
    with its file count, and the paths the location already held when the
    run chose it left out. The skill deletes nothing.
- **generate-plan's exit.** On a brief with a `needs prototype` entry,
  Phase 1 asks before any gap-check question whether to prototype each such
  entry first — ending the run with one `/kenspc-prototype <brief path> <n>`
  line per entry, invoking nothing and writing no file — or carry it into
  the plan. A session that cannot ask carries every such entry with
  `Not prototyped: the session could not ask`.
- **Guard group, counts unchanged** (`guards run: 10`,
  `self-tests run: 9`). `check-doc-sync-anchors.sh` adds a
  `needs prototype` group — `generate-brief/SKILL.md`,
  `generate-plan/SKILL.md`, `prototype/SKILL.md` — and now describes four
  planning-chain anchors across eleven files, on the documentation path and
  the open-question path.

### Changed

- **generate-brief.** The template gains Open Questions and the writing
  rules its grammar (above). Phase 1 notes a question the conversation
  cannot settle for Open Questions instead of arguing it further, and marks
  one an experiment would settle `needs prototype`, asking the user what
  would settle it (inferred and tagged, as `rapid-inferred
  (reminder-driven)` tags its fields, in a session that cannot ask,
  whatever the Discovery Mode). The next-step suggestion lists
  `/kenspc-prototype <path> <n>` for each `needs prototype` entry before
  `/kenspc-plan`, and the skill invokes neither.
- **generate-plan.** Phase 1 Step 1 reads a brief in three parts: the exit
  (above); the gap-check, where each `open` entry is a gap for the same
  one-to-two rounds and one they do not settle is carried into the plan (a
  session that cannot ask carries every `open` entry with no gap round), and
  an entry whose status word is none of the three — hand-edited,
  translated, or missing — is a gap too, named as unrecognized and asked
  about (one then marked `needs prototype` gets the exit question), or
  carried in the `open` form with the word in `From:` by a session that
  cannot ask; and `answered` entries, settled input that a plan relying on
  one cites by its prototype hash. A brief with no `## Open Questions`
  section, or with `none`, has nothing to stop on. The plan's Open Questions
  element gains the carried form — the status word kept,
  `From: <brief path>, entry <n>`, `Not prototyped:` on a `needs prototype`
  entry, and `Assumed in:` naming the steps that assume an answer — whose
  status word and labels stay in English in a plan in another language.
  The approval gate is unchanged: a session that cannot ask still writes
  the plan only on approval.
- **Reminder hook.** `remind-plan-skill.sh`'s brief message names
  prototype (`/kenspc-prototype`), which records a prototype's answer in an
  existing brief, beside generate-brief and diagnose-bug. The hook still
  matches the Write tool only, so the prototype's edit of a brief does not
  reach it.
- **Release checklist.** Smoke row 1 counts eight commands. Row 3 checks
  the brief's `## Open Questions` (`open` or `needs prototype` entries,
  `Settled by:` on each `needs prototype` entry, `none` otherwise) and the
  `/kenspc-prototype` suggestion; row 4 checks generate-plan's exit
  question before any gap-check question, both answers, the carried form,
  `open` entries the gap rounds do not settle, the cannot-ask branch, and
  no question for a brief without the section. A new row 10 exercises
  `/kenspc-prototype`: the frame, the add commit holding only the
  prototype's paths, the answered entry, the remove commit and its body,
  `git diff <HEAD before the run> HEAD` printing nothing, the uncommitted
  brief, the leftovers list, the exit suggestion, what a run that stops
  says, a question with no brief, the development-database cases, the
  in-app UI case, the feature-slice case, and two requests that invoke no
  prototype skill. The end-to-end row becomes row 11. Pre-flight counts are
  unchanged.
- CLAUDE.md and both READMEs describe the prototype skill and the
  prototype path, and count eight skills and commands; the plugin and
  marketplace manifest descriptions gain prototyping. CLAUDE.md's writing
  rules for skill content gain the cannot-ask wording, and its Non-Goals
  record that the Open Questions grammar is written once, in
  generate-brief, with the prototype skill's one byte-identical copy of the
  Prototype line.

### Known behavior

- **Gates between the two commits.** Between the add and the remove commit,
  a typecheck, linter, or root-level project file that walks the repository
  reaches the prototype, and a pre-commit hook that runs one can reject the
  add commit, which stops the run. HEAD after a run that makes its remove
  commit holds no prototype; a run that stops between the two commits
  leaves it in HEAD, and its last message names the add commit and the
  commands that would remove it. The roadmap item on linters and build
  tools that walk into `.kenspc/` now names `prototypes/` too.
- **Leftovers after a prototype.** Files git does not track under the
  prototype's location — installed dependencies, build output, a local
  database file — stay after the remove commit, and the final message
  names them.
- **History keeps every prototype.** The remove commit takes the prototype
  out of the tree, not out of history: `git show <hash>` reads it, and
  anything it committed stays there. The hash resolves while the add commit
  is reachable; after a rebase that replays or drops it, or a squash merge,
  it resolves only in the clone that made it, until gc. The answer's text
  survives in the brief; the remove commit's body survives only while that
  commit is reachable, and a squash merge keeps it only when the squashed
  message keeps the body.

## 3.7.0 — 2026-09-25

Batch B. A `diagnose-bug` skill and its `/kenspc-diagnose` command take an
observed bug from reproduction to a task document for
`/kenspc-task-implement`, or to a brief for `/kenspc-plan` when the fix
needs a decision a task cannot make. `REVIEW_SCOPE=changes` is defined:
task-review computes the change set once, read-only, and every agent reads
it from the run directory; in an uncommitted run code-fixer commits
nothing and keeps a pre-fix record that regression-verifier judges the
fixes against. A new command, so a minor release. No CONTEXT key changes.
Release smoke: the batch's acceptance run,
`docs/dry-runs/batch-b-acceptance.md` — smoke row 9 in every case it names
and row 7 with the change-set check in four repository states, run
headless on macOS; its two findings on the checklist's name probe are
recorded there, one fixed and re-run before this tag and one a behavior
slip recorded in the roadmap. The batch's own task document was decomposed
and implemented by `/kenspc-task` and `/kenspc-task-implement` in this
repository, the first Doc-sync task generated from a plan's Documentation
impact; no separate smoke run was made for rows 1–6 and 8.

### Added

- **`diagnose-bug` skill and `/kenspc-diagnose`.** For a bug the user has
  observed — a wrong result, a crash, an error they can trigger. Three
  tiers: tier 1, a fix the user can already name that touches one file and
  needs no new test, is made directly and never reaches the skill (its
  description excludes it, along with explaining an error message or a
  stack trace and finding bugs in code); tier 2 gets a task document; tier 3
  — a fix that needs a new dependency, a change to an existing API
  contract, a database schema change, or a project configuration change,
  the stop conditions in task-implementer's AUTONOMY BOUNDARIES — gets a
  brief instead.
  - **Reproduction first.** A test in the project's test tree, run more
    than once and seen to fail for the reported reason, committed alone as
    `test: reproduce <symptom>` before any diagnosis; an intermittent
    failure is recorded with its observed rate, and the fix task then asks
    for a run of consecutive passes sized to it. Or, when no
    failing-capable test can be written (hardware, a real device, no test
    framework), the manual steps and the reason. A bug the skill cannot
    reproduce ends in a question listing each attempt (path, what it
    exercised, what happened); before asking, the skill removes the
    reproduction-test files it wrote in this run that are still untracked
    (`??`) — never a tracked file, a file the user added meanwhile, or
    anything under `.kenspc/` — or, when the removal is denied, names them
    in the question. It leaves no task document or brief and makes no
    commit besides the one-time `.gitignore` commit.
  - **Hypothesis loop.** `none — the root cause was visible on
    reproduction`, or three to five hypotheses listed at once, each with
    its verification method, verified in turn and recorded with the
    evidence; the skill stops and asks when none survives.
  - **The record and the tasks.** `docs/tasks/<name>.md` (`<name>` a slug of
    the symptom) holds a `## Diagnosis` section with nine fixed labels —
    `**Symptom:**`, `**Reproduction:**`, `**Root cause:**`,
    `**Hypotheses:**`, `**Fix scope:**`, `**Adjacent cases:**`, `**Tier:**`,
    `**Documentation impact:**`, `**Probes:**` — and no `Phase N` or
    `Step N` heading, then a fix task (the reproduction test passes, the
    full suite, build, and lint pass, nothing outside Fix scope changes but
    tests for the code the fix adds, and the reproduction test's assertions
    stay as they are; a manual reproduction's criterion is left for the
    user to verify and recorded as not verified), a regression-test task
    for the adjacent cases (omitted when there are none), and a
    `### Task N: Doc-sync` task written from generate-task's template by
    reference when the diagnosis's Documentation impact lists documents.
    The user confirms the task list before it is written; there is no
    review phase. The document is committed alone (`docs: add task <name>`),
    and the skill asks whether to run `/kenspc-task-implement` on it now or
    implement interactively, first warning when Fix scope holds a file with
    the user's uncommitted changes; a session that cannot ask prints the
    suggestion and stops, and writes beside an existing document rather
    than overwrite it.
  - **The brief exit.** Tier 3 writes `docs/briefs/<name>.md`, starting
    `# Requirement Brief:`, in generate-brief's template with no
    `Discovery Mode:` field; it is not committed, and the skill suggests
    `/kenspc-plan <path>` without invoking it.
  - **Probe directory.** A probe, copy, or mutant goes in
    `.kenspc/runs/<YYYYMMDD-HHMMSS>-diagnose-<name>/scratch/orchestrator/<n>/`,
    a run directory prepared as the `canonical:run-dir` block prescribes,
    by reference, with no third copy of the block. A "does this change
    remove the symptom" experiment runs on a copy under scratch, and a
    mutant used as evidence follows the three-step mutation rule the review
    agents carry (unmutated copy passes, control mutant fails, then mutants
    count). The diagnosis modifies no tracked file.
  - **The commits it makes:** the reproduction test, the task document,
    and — when it prepared a run directory in a project that did not yet
    ignore `.kenspc/` — the one-time `.gitignore` commit, the single
    exception to "modifies no tracked file". A commit that fails — a hook
    that runs the suite rejects the red test — stops the run and asks the
    user, with no retry and no `--no-verify`. A run that ends after the
    reproduction commit without a document names that commit and offers
    `git revert`.
- **`change-set.md`.** A fixed file under `RUN_DIR`, written by task-review
  in a review without a task document before any agent is dispatched:
  `# Change set`, `Mode: uncommitted` or `Mode: commits`, `Base:` or
  `Range:`, the `Diff:` command, and a `Status | Path` table. The five
  reviewers, code-fixer, and regression-verifier read it there; no CONTEXT
  key was added, for the reason `RUN_DIR` replaced `REVIEW_REPORTS` and
  `ACCOUNTABILITY_LIST`.
- **Reminder hook messages.** `remind-plan-skill.sh`'s messages for
  `docs/tasks/` and `docs/briefs/` name diagnose-bug (`/kenspc-diagnose`)
  beside generate-task and generate-brief.
- **Guard extensions, counts unchanged** (`guards run: 10`,
  `self-tests run: 9`). `check-doc-sync-anchors.sh` adds
  `diagnose-bug/SKILL.md` to its `Documentation impact` and `Doc-sync`
  groups (nine files). `check-run-contract.sh` gains check 5: the literal
  `change-set.md` is named in `task-review/SKILL.md`, `code-fixer.md`,
  `regression-verifier.md`, and `requirements-reviewer.md` (the drift guard
  carries it to the other four reviewers), and the pre-fix record's
  `pre-fix/index.txt` in `code-fixer.md` and `regression-verifier.md`, with
  self-test mutations that rename every occurrence of each name in each of
  its carriers in turn.

### Changed

- **`REVIEW_SCOPE=changes` defined.** task-review computes the change set
  once, with read-only git commands only — no commit, stash, checkout, add,
  or reset — and pins every SHA before the run-directory preparation, so
  its one-time `.gitignore` commit is never part of the set. `uncommitted`
  when `git status --porcelain` lists any path outside `.kenspc/` (staged,
  unstaged, and untracked, against HEAD; read with `-uall` and unquoted
  paths, a rename under its new path); `commits` when the tree is clean
  (the commits ahead of the upstream, diffed from their merge base with it,
  when an upstream exists and the range has commits, otherwise
  `<HEAD~1>..<HEAD>`). When a commit these defaults name does not exist,
  git's empty tree stands in for it: `Range: <empty tree>..<HEAD>
  (root commit)`, or `Base: <empty tree> (no commit yet)` on an unborn
  branch; in a shallow clone, or when `git merge-base` finds no common
  ancestor with the upstream, the run asks for a range instead.
  CUSTOM_INSTRUCTIONS naming commits or a range replace the default, named
  paths narrow it, and a set that comes out empty stops the run before any
  dispatch; one line tells the user the mode, the base or range, and the
  file count. Before, each reviewer worked out its own set from git. Source:
  the v3.5.1 acceptance's Windows run, observation 2, where code-fixer
  committed the reviewed, uncommitted `Program.cs` unchanged as `5b4f1d4` to
  give its three fix commits a base, because nothing said how to handle an
  uncommitted change; the orchestrator itself committed only `.gitignore`.
  Recorded in that acceptance session, not under `docs/dry-runs/`.
- **code-fixer's uncommitted mode.** When `change-set.md` says
  `Mode: uncommitted`, code-fixer applies every fix to the working tree and
  commits nothing — no baseline commit of the user's change, no fix commit,
  no stash — and runs no checkout, restore, reset, clean, or add, which
  would erase or restage the user's uncommitted change. Before a file's
  first edit it records the file under
  `RUN_DIR/scratch/code-fixer/pre-fix/` — a `.txt` copy of its content
  (`pre-fix/<path>.txt`, a `.test.` or `.spec.` segment of the name renamed
  `.probe.`, so the copy clears a runner's pattern and the release
  checklist's name probe alike) and a line in `pre-fix/index.txt` (`copied`,
  `created`, or `deleted <path>`), written once per run — so a fix that
  breaks the build is edited back or restored from its copy, and
  regression-verifier can tell the fixes from the user's hunks.
  FIXED rows carry `—` in Commit, and its reply names the uncommitted
  files. In `Mode: commits` and with a task document, each fix is still its
  own commit, and a fix to a file that already carries uncommitted changes
  the run did not make is deferred rather than committed with them. Its
  PREREQUISITE CHECK also stops when a changes-mode run has no
  `change-set.md`, and names the missing files; its OBJECTIVE and
  PROCESSING APPROACH defer to the FIXING RULES mode rule. task-review's
  Next steps gains a bullet naming the uncommitted files for the user to
  review and commit, when there are any, and its verification list and
  PASS / FAIL bullets read "the fixes (fix commits, or the uncommitted
  fixes of an `uncommitted` run)".
- **regression-verifier's check 4.** In an uncommitted run it reads
  code-fixer's pre-fix record instead of fix commits: for each file
  `pre-fix/index.txt` names, the fixes are the difference between the
  `.txt` copy and the working file (a created file whole, a deleted file's
  copy), and a path the index does not name is the user's — so a dirty
  file outside a narrowed set or a build output is never read as fix
  output, and a regression a fix made inside a user hunk cannot hide in
  the user's diff. A commit code-fixer made in such a run
  fails row 5. It reads `change-set.md` for the set's boundary and stops
  when a changes-mode run has none.
- **The reviewers' three shared sections.** CONTEXT YOU WILL RECEIVE,
  PREREQUISITES, and FILE COVERAGE, byte-identical in all five: with
  `RUN_DIR`, a changes-mode reviewer reviews the files `change-set.md`
  lists and runs its diff command, and stops when that file is missing
  rather than derive the set itself; standalone, without `RUN_DIR`, it
  runs `git status`, `git diff`, `git diff --cached`, and `git log` as
  before.
- **Release checklist.** Smoke row 1 counts seven commands. A new row 9
  exercises `/kenspc-diagnose`: the reproduction test written, run,
  failing, and committed before the task document; the committed task
  document with the nine `## Diagnosis` labels in order, `### Task 1` at
  `**Status:** TODO`, a regression-test task exactly when adjacent cases
  are listed, and a Doc-sync task when documents are affected;
  task-implement's Step 1 validation passing on it, with no `Phase N` or
  `Step N` heading; the exit question; the manual-reproduction path; a
  signature-changing fix producing a brief and no task document; the probe
  directory and its `find` probe; the one-time `.gitignore` commit as the
  only other commit; the not-reproduced stop; and a stack-trace question
  invoking no skill. The end-to-end row becomes row 10. Row 7 gains a
  change-set check for a run with no task document: `change-set.md` with
  `Mode:`, the five FILE COVERAGE lists matching it, no commit, stash,
  checkout, add, or reset by the orchestrator besides the `.gitignore`
  commit, the expected `Base:` / `Range:`, Commit cells, and Next steps
  bullet per mode, regression-verifier's uncommitted branch, the range
  pinned before the `.gitignore` commit, an unborn branch, and the
  custom-instructions override. Pre-flight counts are unchanged.
- CLAUDE.md and both READMEs describe the diagnosis path, seven skills and
  commands, and `change-set.md`; the plugin and marketplace manifest
  descriptions gain bug diagnosis (`plugin.json` says what the skills cover
  and what the eleven subagents do).

### Known behavior

- **Red interval after a diagnosis.** The reproduction test is committed
  before the fix exists, so it fails — and a CI that gates on the suite is
  red — until the fix task lands.
- **Fixes left uncommitted.** In an uncommitted review run, the fixes stay
  in the working tree for the user to review and commit; the final
  report's Next steps names the files.

## 3.6.0 — 2026-09-25

Two batches. Batch A: a documentation path from the plan to the
implementation run. Plans state which durable documents they make stale,
the task document ends with a Doc-sync task that brings those documents up
to date, and decisions made during implementation are promoted into them or
reported for the user to place. The task-document reviewer gains a third
angle, Consistency with CLAUDE.md. Roadmap items 9 and 2: the run
directory's scratch space is safe to leave behind — every probe carries a
name the project's test runner does not collect, each writer has its own
numbered attempt directory, regression-verifier runs the project's build,
test, and lint commands unmodified, and code-fixer changes no project
configuration for the plugin's files. No CONTEXT key changes and no
command-surface changes. Release smoke: the two acceptance runs,
`docs/dry-runs/batch-a-acceptance.md` (rows 4–6) and
`docs/dry-runs/scratch-probes-acceptance.md` (row 7 with the run-directory
check); no separate smoke run was made for this tag.

### Added

- **Documentation impact.** The one plan element generate-plan always
  writes (`## Documentation impact`): the durable documents the plan's steps
  make stale — per document the path, the section where known, what must
  change, and the causing step — or the single line `N/A — <reason>`. A
  document that was considered and is unaffected can be recorded among the
  entries as `<path> — N/A for this document: <reason>`, which is not a list
  entry and never mixes with the whole-body form (defined after acceptance
  observation O1). The durable documents are the ones the project's CLAUDE.md names (a
  documentation table where one exists, otherwise the documents it names in
  prose), or README.md and CLAUDE.md when it names none.
  `plan-document-reviewer`'s Completeness angle checks the element: absent;
  N/A without a reason, or with one the steps contradict; a document the
  steps modify is missing; a listed document no step changes. The plan
  example shows the section.
- **Doc-sync task.** When the plan's element names documents, generate-task
  ends every task document, phase-specific ones included, with
  `### Task N: Doc-sync` and `Depends on: Task 1-<N-1>`, written from a fixed
  template that lists the documents and carries the promotion instruction in
  the task's own text. For a document an earlier task already edits, the
  Doc-sync task verifies it against the implementation instead of redoing
  the planned edit, while still correcting a statement the implementation
  contradicts and writing promoted decisions into it. The task is exempt
  from the sizing table. A listed document that does not exist on disk
  blocks the task, with the path named, instead of being created; an entry
  that leaves its document to another task document is exempt, since a later
  phase may create that document. `task-document-reviewer`'s Completeness angle checks
  that it exists, is last, covers every other task, and lists the element's
  documents; a plan without the element is a Plan-Level Concern. The task
  example shows it as Task 6.
- **Decisions needing a home.** task-implementer's DECISION PROMOTION rules
  give each earlier decision a Doc-sync task reads one of three outcomes:
  promoted (written into a listed document, in that document's language),
  needs a home (no listed document fits; reported with a suggested
  destination and written nowhere), or local, the default. Schema D gains an
  always-rendered `## Decisions needing a home` section (`none` when empty),
  and task-implement's Schema G turns each entry into a Next steps bullet,
  plus one bullet when the Doc-sync task is BLOCKED, and one naming the
  listed documents to re-check against the fix commits when a Doc-sync task
  was DONE and code-fixer's statistics line reports FIXED greater than 0 —
  the review's fixes land after the Doc-sync task. In a run without a
  Doc-sync task, the roll-up classifies the DONE tasks' decisions itself and
  writes no document.
- **Angle 3, Consistency with CLAUDE.md,** in `task-document-reviewer`:
  written-rule departures, task text carried into a code artifact or a
  document in a language other than that artifact's own, and undecided git
  workflow steps. A plan-level cause with a task-level symptom is fixed in
  the task document and also recorded as a Plan-Level Concern.
- `scripts/check-doc-sync-anchors.sh` with `--self-test`:
  `Documentation impact`, `Doc-sync`, and `Decisions needing a home` stay
  present in the eight files that write, check, or render them.
- `docs/dry-runs/batch-a-acceptance.md`: the batch A acceptance run on
  macOS — smoke rows 4–6 with their batch A additions, a forced-BLOCKED
  round, and the three reviewer negative cases.
- `docs/dry-runs/scratch-probes-acceptance.md`: the scratch-probes
  acceptance run on macOS — smoke row 7 with every item of the run-directory
  check, in a vitest project whose config sets only `globals: true`. The
  three checks batch A § 8 failed came back clean: no collectable name among
  791 scratch files, a bare `npm test` passing after the run, no
  configuration file added by any agent. One FAIL, F1 — logs and a helper
  script in the session scratchpad — classified as checklist wording (see
  Changed).

### Changed

- **Dependency gate.** task-implementer reads each task's `Depends on` line
  and marks the task BLOCKED with `depends on Task N (<status>)` when a named
  task is not DONE — BLOCKED in this run or an earlier one, not yet
  processed, or absent from the task document (status `not found`). This
  changes behavior for every task with a `Depends on` line, not only the
  Doc-sync task: a task that used to be attempted after a blocked dependency
  is now blocked. A later run skips a task already marked BLOCKED, so the
  gate's unblock step tells the user to set the task back to TODO once the
  dependency is DONE, correcting the `Depends on` line first for
  `not found`.
- **`Depends on` semantics.** The annotation covers any hard ordering
  dependency, within or across phases (a single task, an ASCII-hyphen range
  such as `Task 1-5`, or a comma-separated list), not only cross-phase ones.
  It names tasks in the same task document only, since the gate looks task
  numbers up in the document it runs; a phase-specific task document treats
  earlier phases' work as existing code, and its Dependency note names the
  earlier phases' task documents it assumes are implemented.
  The note at the top of a task document is now the "Dependency note", and
  `task-document-reviewer`'s Execution Order angle checks every task with a
  `Depends on` line.
- **Task-document language.** generate-task writes the task document in the
  plan document's language unless the user asks otherwise; text carried into
  code artifacts follows task-implementer's CODE ARTIFACTS LANGUAGE rule. The
  plugin sets no default language of its own.
- **Task-document reviewer angles: 2 → 3.** generate-task's review table
  shows three rows.
- **Guard counts:** `guards run: 10`, `self-tests run: 9`. The release
  checklist's pre-flight expects them, and smoke rows 4–6 check the
  `## Documentation impact` section, the last `### Task N: Doc-sync` task
  and a three-row Schema E table, and `## Decisions needing a home` with
  its Next steps bullets, together with a forced-BLOCKED run (not-synced
  bullet, verdict PARTIAL) and the re-check bullet after review fixes.
- CLAUDE.md gains a Durable documents table, the list this repository's own
  plans determine their Documentation impact from, and describes the
  documentation path and the dependency gate.
- **Scratch layout: one subdirectory per writer.** Probe and temporary files
  under `RUN_DIR/scratch/` go in `angle-<n>/` per reviewer (unchanged),
  `code-fixer/`, `regression-verifier/`, and `orchestrator/` for the
  orchestrating session when it runs a probe of its own. code-fixer and
  regression-verifier used to write to `scratch/` itself. The
  `canonical:run-dir` Scratch space bullet in both review skills, the two
  worker agents' `RUN_DIR` bullets, the README's Run directory section, and
  CLAUDE.md name the four locations. Source:
  `docs/dry-runs/batch-a-acceptance.md` § 8, where the two workers made up
  their own `scratch/fixer/` and `scratch/verifier/` directories.
- **Runner-safe scratch names; starting over means a new subdirectory.**
  Every file under the run's scratch directory is named so the project's
  test runner does not collect it: for vitest and jest with their default
  patterns, no `.test.` or `.spec.` segment in a file name, no file named
  `test.*` or `spec.*` (jest's default `testMatch` collects both), no
  `__tests__` directory, and no `__mocks__` directory (jest's haste map
  crawls `.kenspc/` and reports a copied `__mocks__` file as a duplicate
  manual mock; such a copy also risks standing in for the user's own mock);
  where the project configures its own pattern, or for any other runner,
  whatever that configuration actually collects (pytest `test_*.py` /
  `*_test.py`, Go `_test.go`). A jest project keeps the `__mocks__` rule
  whatever its `testMatch`: the haste map registers `__mocks__` files under
  `roots` regardless. `probe.mts`, `probe-2.probe.ts`, and `.txt`
  for anything that need not run are safe. A probe that has to execute runs
  as a plain script or through a runner config kept in the agent's scratch
  directory; a mutant copy of the test tree renames its test files as they
  are copied (`split.test.ts` becomes `split.probe.ts`). Every attempt lives
  in a numbered subdirectory of the agent's scratch directory from the first
  (`scratch/angle-5/1/`), and an agent that starts over takes the next
  number (`scratch/angle-5/2/`), never a delete. A scratch runner config is
  rooted at the current attempt's numbered directory (vitest `root`, jest
  `rootDir`), so it collects only that attempt's files. A mutation check
  goes in three steps: the unmutated copy passes under that config, or the
  check is reported as not made, with the reason, never as surviving
  mutants (regression-verifier's check 4 records the test as "not
  mutation-checked" and does not flag it); a deliberately broken control
  mutant fails, which proves the run exercises the copy rather than the
  original; only then do failing mutants count as killed and passing ones as
  survivors. When every mutant fails on an import or setup error, every
  mutant looks killed, and when the tests still import the original, every
  mutant looks like a survivor. A file that already carries a collectable
  name is renamed onto a path that does not exist yet; renaming over an
  existing file is a delete. The
  rule is in the five reviewers' ROLE section (byte-identical, so
  `check-review-agent-drift.sh` guards it), the two worker agents' `RUN_DIR`
  bullets, and the `canonical:run-dir` block. The release checklist's
  run-directory check gains a `find` probe for collectable names, an
  unmodified test run from the repository root, a check that no agent
  changed test-runner config, linter config, ignore files, `tsconfig`, or
  package scripts,
  and trace checks that regression-verifier ran the project's commands
  unmodified and compared the runner's collected files against `.kenspc/`,
  that nothing under the run directory was deleted, and, when an agent ran a
  mutation check, that its unmutated baseline passed first under a config
  rooted at the attempt's directory and a control mutant failed. The checks
  run in a vitest project whose vitest config sets only a setup file or
  `globals` and keeps the default include: the first two can fail there,
  and a scratch config that drops the setup fails the baseline. CLAUDE.md
  records the lesson: git-ignored is not tool-ignored.
  Source:
  `docs/dry-runs/batch-a-acceptance.md` § 8, where 68 probe files named
  `*.test.ts`, single probes and whole copies of the `test/` tree, were
  collected by vitest's default include and made a bare `npm test` fail.
- **regression-verifier runs build, test, and lint unmodified.**
  VERIFICATION CHECKS item 3 runs each command as the project configures it
  (`package.json` scripts, CLAUDE.md, the solution or `pytest` config), with
  no path filter or exclude added. When files under `.kenspc/`, this run's
  scratch or an earlier run's, make a command fail, alone or alongside
  failures in the project's own files, that command's row is FAIL with those
  files named in the Detail cell; a re-run narrowed only to leave out
  `.kenspc/` may be added to Detail as information but does not change the
  Result. When the runner collected files under `.kenspc/`, the test row's
  Detail names them, whether the run passed or failed, and a passing run
  stays PASS; they are found by comparing the runner's list of collected
  files (`vitest list --filesOnly`, `jest --listTests`) against `.kenspc/`;
  for a runner without such a list, or when the list command errors, Detail
  says the check was not made, and the Result stays what the test run set.
  Beyond about ten such files, Detail names the directories that hold them,
  each with a file count. When the collected files passed, the final
  report's Next steps (task-review's Next steps rules, task-implement's
  Schema G) carries one bullet naming them and asking the user to delete
  them: runs are never deleted and the plugin deletes nothing itself, so a
  passing probe stays in the user's own test run. Build and lint are included
  because those tools walk the run directory too: ESLint's flat config
  ignores only `node_modules` and `.git` by default. Keeping scratch files
  out of them is still open (`docs/roadmap.md`). Source:
  `docs/dry-runs/batch-a-acceptance.md` § 8, where regression-verifier
  passed the test row on a narrowed `npx vitest run --dir test` while the
  project's own `npm test` failed.
- **code-fixer changes no project configuration for the plugin's files,
  and reports scratch pollution.** code-fixer does not modify test-runner
  config, linter config, ignore files, `tsconfig`, or package scripts to
  accommodate files the plugin wrote under `.kenspc/`. When the project's
  build, test, or lint command fails only because of files under `.kenspc/`,
  this run's scratch or an earlier run's, `schema-b.md` carries an optional
  scratch-pollution note after the Deferred Issues prose and before the
  statistics line, which stays the file's last line. The note names those
  files (beyond about ten, the directories that hold them, each with a file
  count) and the command used to verify the fixes, narrowed only to leave
  out `.kenspc/`: a filter such as `--dir test` would also drop tests kept
  beside the source.
  code-fixer's reply carries the note, the `## Fixes` section of the Schema F
  and Schema G final reports renders it, and regression-verifier reads it as
  part of `schema-b.md`. Source:
  `docs/dry-runs/batch-a-acceptance.md` § 8, where code-fixer "fixed" the
  collision by adding a `vitest.config.ts` that excludes `.kenspc/**` to the
  user's project.
- **Run-directory check: logs may sit in the session scratchpad.** The
  release checklist's bullet that placed every probe or temporary file
  under the run directory now names what has to be there — probes, copies
  of project files, mutants, runner configs — and lets the logs, listings,
  and helper scripts an agent writes for its own verification sit in Claude
  Code's per-session scratchpad, which the harness tells every subagent to
  use instead of `/tmp`. The agents' `RUN_DIR` rule is unchanged: the plugin
  still asks for temporary files under `RUN_DIR/scratch/`; the check fails
  only on files a runner, linter, or build could pick up, or that copy
  project files outside the run's record. Source:
  `docs/dry-runs/scratch-probes-acceptance.md` § 6, where code-fixer and
  regression-verifier put ten log and helper files in the scratchpad and
  every probe, copy, and mutant under `scratch/<agent>/1/`; batch A's
  task-implementer and code-fixer had done the same, unseen by a check that
  listed only `/private/tmp`'s top level.

### Upgrading from 3.5.x

Run directories that 3.5.x left under `.kenspc/runs/` can hold probe files
with collectable names, such as `probe.test.ts` or whole copies of a `test/`
tree. The unmodified build, test, and lint runs now report them, so remove
those run directories after upgrading. The plugin deletes nothing itself.

### Branching stance

The plugin takes no side on branching. The default is unchanged: no branch,
commits on the current branch. Whether to branch is decided at plan time,
when the user approves the plan. `task-document-reviewer` fixes a branch,
pull-request, rebase, or tag step the plan did not prescribe, or that a
loaded CLAUDE.md contradicts, back to the default and records a Plan-Level
Concern naming both sources; `task-implementer` follows the task document as
written and asks nothing.

## 3.5.1 — 2026-09-24

Fixes from the v3.5.0 release smoke test (macOS headless; Windows TUI and
headless). v3.5.0 was not tagged, so this is the first tagged release of the
G6 reviewer-layer changes. No CONTEXT key changes and no command-surface
changes.

### Fixed

- **Ignore check misread CRLF `.gitignore` files (Windows).** A blank line in
  a CRLF `.gitignore` parses as an empty pattern, and
  `git check-ignore -q .kenspc/` then reported the directory as ignored when
  nothing ignored it, so the one-time `.gitignore` commit was skipped. The
  `canonical:run-dir` block now asks about a probe path under the directory,
  `.kenspc/runs/probe`, which only a real `.kenspc/` rule matches, and the
  appended line keeps the file's existing line endings.
- **Background dispatch.** The skills never said whether an Agent call runs
  in the foreground, and the model's choice varied from run to run. A
  background call returns at once, so the next step ran without the result,
  and a headless session stopped the agent when it exited. Every dispatch —
  task-implementer, the five reviewers, code-fixer, regression-verifier, and
  the three document reviewers — now sets `run_in_background: false`. The
  five reviewers still go out in one message and run in parallel. The
  parameter exists in headless (`claude -p`) and SDK sessions, which is
  where the failure occurred; the interactive Agent tool (Claude Code
  2.1.281) has no such parameter and runs subagents asynchronously, handing
  each result back within the same turn.
- **Transition lines translated.** `Implementation phase complete.` and
  `Proceeding to code review.` were rendered in the conversation language,
  which broke the release checklist's grep for the Phase 1 → Phase 2
  boundary. Both now stay in English; the lines between them follow the
  conversation language.
- The canonical dispatch block said "the CONTEXT block from Step 2", which
  holds only in task-review. It now says "constructed above" (identical in
  both skills; the block hash changes).
- **Document reviewers and untracked documents.** When the plan, task, or
  guide document was not yet tracked, its first review commit contained the
  whole document, hiding what the review changed. `plan-document-reviewer`,
  `task-document-reviewer`, and `guide-document-reviewer` now commit an
  untracked document unchanged first (`docs: add <type> <name>`, adapted to
  the project's commit conventions), then commit each angle's fixes.
- `claude plugin validate --strict` failed on the marketplace manifest's
  missing top-level `description`; it now has one.

### Changed

- **Planned Dispatch tables retired** from all six dispatch points
  (task-implement Phase 1 and Phase 2, task-review, generate-plan,
  generate-task, generate-guide). The tables were decorative — Agent calls
  are visible in the TUI anyway — and whether they appeared depended on the
  model: the July runs and Opus 5 rendered them, Opus 5.5 did not, headless
  or TUI. A one-line notice stays before each dispatch; task-review and
  task-implement Phase 2 gain "Dispatching 5 review agents now." Release
  checklist rows 4–8 now pass on the Agent call followed by the result
  schema.
- **Scratch space.** Probe files, copies, and other temporary files go under
  `RUN_DIR/scratch/`, which is ignored with the run directory and needs no
  cleanup: each reviewer in its own `scratch/angle-<n>/` (so five parallel
  reviewers never write the same file), code-fixer and regression-verifier
  in `scratch/` itself. In the smoke test reviewers on both platforms left
  probe files in `/tmp`, and a verifier's `rm -rf` was denied by the user's
  permission rules, so it fell back to judging fixes by reading code. The
  reviewer invariant now reads, identically in the reviewers' ROLE, the
  canonical dispatch block, the README, and CLAUDE.md: "Each reviewer is
  read-only on the working tree and writes only under `RUN_DIR`: its report
  at `RUN_DIR/angle-<n>.md`, and probe and temporary files under
  `RUN_DIR/scratch/angle-<n>/`." Standalone reviewers, without `RUN_DIR`,
  still write no file.
- Release checklist pre-flight adds `claude plugin validate --strict` for the
  repository (marketplace manifest) and for `plugins/kenspc` (plugin
  manifest, skills, agents, commands): four checks. Guard counts are
  unchanged (`guards run: 9`, `self-tests run: 8`). The run-directory check
  for rows 6 and 7 adds foreground dispatch, `scratch/`, and the CRLF
  `.gitignore` case.
- `check-run-contract.sh` runs the run-dir block's ignore probe against a
  CRLF `.gitignore` holding a blank line, with and without a `.kenspc/`
  rule, with global and system git config masked. Its self-test reverts the
  probe to `.kenspc/` in both skills to reproduce the Windows case.

### Known behavior

Documented in the README; not changed in this release:

- With `REVIEW_SCOPE=changes`, each reviewer works out the change set on its
  own, so the five angles can review slightly different sets. Planned for
  the next minor release: the orchestrator computes the set once and passes
  it to all five.
- In interactive sessions, subagents run asynchronously and hand their
  results back; `run_in_background: false` takes effect only in headless and
  SDK sessions.
- The plugin does not create branches; commits follow the project's
  CLAUDE.md and otherwise land on the current branch.
- The SessionEnd telemetry hook can log a false missed-review entry when a
  headless session runs several turns, or when a session exits at a
  confirmation prompt.

## 3.5.0 — 2026-09-23

> Not tagged: the release smoke test failed on macOS and Windows.
> Superseded by 3.5.1, which lists the fixes.

Reviewer-layer rightsizing (G6). The five review angles now report against a
severity-calibrated policy and a rubric of named failure modes instead of a
coverage-maximizing checklist; review reports travel between agents through a
per-run directory instead of through the main session's context; every
finding carries an angle-prefixed ID that code-fixer and regression-verifier
account for mechanically; and effort follows the session except in three
files. Minor bump: the command surface is unchanged, and a standalone
`@kenspc:<reviewer>` invocation keeps its output shape. CONTEXT contract
change: `RUN_DIR` is added — optional for the 5 review-angle agents, required
for `code-fixer` and `regression-verifier` — and `REVIEW_REPORTS` /
`ACCOUNTABILITY_LIST` are retired.

### Rationale

Nine `/kenspc-task-implement` runs (2026-06-29 to 2026-09-08, on Opus 4.8,
Fable 5, and Opus 5) produced 452 findings across their Schema B
accountability lists:

- HIGH: 37 reported, 12 after deduplication, all 12 handled.
- MEDIUM: 59% fixed.
- LOW: 289 findings — 64% of the total — with a 13% fix rate; code-fixer
  judged 88 of them NOT APPLICABLE. The NOT APPLICABLE rate was 33% on
  Fable 5 and 11% on Opus 5.

The volume traced back to the reviewers' shared instruction to report every
issue "including ones you are uncertain about … Your goal here is coverage",
with filtering left to the fixer. It also cost the main session: rendering
every report verbatim grew one run's context to 414k tokens and forced
another to compact, and when the orchestrator relayed the reports to the
verifier through its prompt it abbreviated the list, which produced a false
FAIL.

Anthropic's guidance for the Claude 5 generation points the same way:
replace rules with judgement, stop over-constraining skills, and start from
the model's default effort — re-tuned at each generation — raising it only
where work under-executes:

- Thariq Shihipar, [The new rules of context engineering for Claude 5 generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models), claude.com blog, 2026-07-24
- Lydia Hallie, [Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code), claude.com blog, 2026-07-07
- Lance Martin, [Agent Harness Design: 3 Patterns for Harnessing Claude's Intelligence](https://claude.com/blog/harnessing-claudes-intelligence), claude.com blog, 2026-04-02
- Claude Academy, [Choosing the right effort level in Claude Code](https://academy.claude.com/tutorials/choosing-the-right-effort-level-in-claude-code)

v3.0 recorded that "don't nitpick"-style wording makes models suppress real
findings, so the new policy keeps an explicit counterweight: uncertainty
lowers a finding's Confidence instead of dropping a HIGH or MEDIUM candidate.
A HIGH handling rate below 100% in the acceptance baseline
(`docs/dry-runs/g6-baseline.md`) counts as a regression of that wording.

Unchanged by design: fresh-context independent review, unconditional
dispatch of all five angles, regression-verifier's re-verification of fixes,
the Schema A–G section structure, `shared/code-craft-principles.md`, and
`shared/discovery-framework.md`. Merging the bug and edge-case angles is
deferred until the new rubrics have run.

### Removed

- The five reviewers' shared output paragraph ("Report every issue you find
  … Your goal here is coverage") (G6-a).
- `code-fixer`'s "LOW: do not fix" rule (G6-a).
- Generic REVIEW CHECKLIST items — checks the model performs without being
  told (G6-c):
  - requirements: orphaned files or dead code from incomplete work. The
    other three questions became named failure modes or the passing
    statement.
  - edge-case: boundary values (min/max, zero, negative, overflow) and
    concurrency (bug's check-then-act covers the case that matters). The
    generic null/empty, malicious-input, and resource-cleanup questions are
    each replaced by a narrower named mode: empty treated as absent,
    trusting boundary input, shared-resource lifetime.
  - quality: naming conventions, project structure, DRY, SOLID, magic
    numbers and hardcoded values, code complexity, import organization.
    These are in scope now only where CLAUDE.md, README, or adjacent code
    states them.
  - bug: off-by-one, null/undefined references, missing async/await,
    resource leaks, database query correctness and N+1, implicit type
    coercion, and generic state management. Happy-path and error-path
    tracing became the passing statement.
  - test: "are core logic functions tested", edge-case coverage
    (null/empty/boundary), integration tests for critical paths, and the
    stand-alone behavior-not-implementation question. Error-path coverage,
    naming the missing tests, and following the project's test framework
    are folded into the passing statement.
- `effort:` frontmatter from 14 files: the `generate-brief`,
  `generate-task`, `generate-guide`, `task-implement`, and `task-review`
  skills; the 5 review-angle agents; `regression-verifier`; and the 3
  document reviewers (G6-e).
- The CONTEXT keys `REVIEW_REPORTS` and `ACCOUNTABILITY_LIST` (G6-d).
- `DEDUPED` as a Schema B row action — it is now a count (G6-f).
- Pinned model-version wording ("aligned with Opus 4.8" and similar) in
  `plugin.json`, README, and CLAUDE.md (G6-e). Historical CHANGELOG entries
  and the document titles cited in the README Acknowledgements are left as
  they are.
- The release checklist's "every file declares effort" loop, which printed
  a warning but always exited 0.

### Changed

- **Output policy (G6-a).** The 5 review-angle agents share a
  severity-calibrated policy, byte-identical and drift-guarded. HIGH needs
  a concrete failure path — wrong result, data loss, crash, or security
  exposure — and the input or state that triggers it. MEDIUM needs a stated
  consequence, or a departure from a written convention in CLAUDE.md,
  README, or adjacent code. LOW is reported only when it is small, fixable
  alongside the change, and anchored to a written convention or a specific
  defect. A style preference with no written convention behind it is not a
  finding and is not listed as an observation either.
- **code-fixer triage (G6-a).** Triage uses the same definitions. LOW
  follows MEDIUM's rule — fix if localized and low-risk, otherwise defer.
  A NOT APPLICABLE row carries its reason in the Action cell
  (`NOT APPLICABLE — <reason>`, naming the part of the definition that
  fails); a DEFERRED paragraph names its constraint.
- **Angle 3 (G6-b).** `quality-reviewer` now reviews project conventions and
  existing patterns: rules written in CLAUDE.md or README and patterns
  visible in adjacent code. The file and dispatch name are unchanged, and so
  are the two triple-condition bullets (Over-engineering, Drive-by
  refactoring). Its description, OBJECTIVE, and closing line ("Angle 3:
  Project Conventions"), both Planned Dispatch tables, the task-review
  Quality bar, the README agents table, and CLAUDE.md follow the new scope.
- **Rubric checklists (G6-c).** Each REVIEW CHECKLIST is now a one-sentence
  passing statement plus named failure modes; bullets per angle went from
  4/7/9/9/9 to 3/6/4/4/3 (bug's four include one "not a finding"). Modes
  taken from run evidence: tautological test; unverified interaction (a
  stubbed collaborator whose call arguments are never asserted); fail-open
  guard; spec–implementation drift; shared-resource lifetime and late
  failure overwriting a settled result (the two HIGH clusters of the
  2026-09-08 run); and compiler-enforced exhaustiveness reported as a
  missing default case, listed as not a finding. Trusting boundary input is
  kept without run evidence because it is a security boundary. bug and
  edge-case do not list the same mode. The frontmatter descriptions of the
  requirements, edge-case, bug, and test reviewers match their new rubrics.
- **Run directory (G6-d).** `task-review` (Step 1) and `task-implement`
  (Phase 2 Step 1) prepare `<repo root>/.kenspc/runs/<YYYYMMDD-HHMMSS>-<slug>`
  (slug: the task document's name, or `changes`) as an absolute,
  forward-slashed path and pass it as `RUN_DIR`. If
  `git check-ignore -q .kenspc/` exits 1 (the trailing slash matters for a
  directory that does not exist yet), `.kenspc/` is appended to `.gitignore`
  and committed on its own with a pathspec commit. The message follows the
  project's commit conventions, and a hook rejection stops the run — no
  retry, no `--no-verify`. This procedure is a byte-identical
  `canonical:run-dir` block in both skills. Each reviewer, read-only on the
  working tree, writes only `RUN_DIR/angle-<n>.md` and replies with its
  Findings table, the path, and its closing line; without `RUN_DIR` it
  replies inline and writes nothing. `code-fixer` reads the reports from the
  directory and writes `schema-b.md`; `regression-verifier` reads both.
  Runs accumulate; there is no automatic cleanup.
- **Final report (G6-d).** The Fixes section of Schema F and Schema G is
  code-fixer's reply: statistics line, Per-angle Results table, HIGH and
  MEDIUM rows with their Deferred Issues paragraphs, and the full path of
  `schema-b.md`, where the LOW rows and prose remain. Next steps list each
  HIGH or MEDIUM DEFERRED issue; LOW deferrals get one bullet with their
  count and the path. The Schema A roll-up, Schema C, and the Verdict
  section are unchanged.
- **Accountability contract (G6-f).** Reviewer issue IDs carry the angle's
  letter (`R`, `E`, `Q`, `B`, `T`) and a sequence number. Schema B has one
  row per unique issue with a Source column listing every ID it accounts
  for, primary first; the other IDs count as DEDUPED. A Per-angle Results
  table and a fixed statistics line follow: `total reported N (R n, E n,
  Q n, B n, T n), deduplicated to N unique, FIXED N, DEFERRED N,
  NOT APPLICABLE N, DEDUPED N`. regression-verifier's row 1 compares the
  reports' ID set with the Source IDs and checks total = FIXED + DEFERRED +
  NOT APPLICABLE + DEDUPED and unique = FIXED + DEFERRED + NOT APPLICABLE.
- **Effort (G6-e).** `generate-plan` goes from `max` to `xhigh`;
  `task-implementer` and `code-fixer` stay at `xhigh`. Every other skill and
  agent inherits the session's effort. CLAUDE.md and the README Effort
  levels section give the reason for each override, and the release
  checklist's Docs currency step now re-checks those reasons instead of
  re-pinning values.
- The canonical dispatch block's "Each subagent is read-only … does not
  modify any files" now reads "read-only with respect to the working tree
  and writes only its own report under `RUN_DIR`" (identical in both
  skills; the block's hash changes on purpose).
- `check-review-agent-drift.sh` also guards the reviewers' ROLE, CONTEXT
  YOU WILL RECEIVE, and REPORT DELIVERY sections (3 → 6), which carry the
  `RUN_DIR` contract and the one permitted write.
- Release checklist: pre-flight is now two commands in a `( set -e … )`
  block, so a pasted block stops at the first failure: the effort-override
  diff and `bash scripts/check-all.sh --self-test`, which must report
  `guards run: 9` and `self-tests run: 8`. The three hand-run
  `python -m json.tool` lines are gone (see `check-json.sh`). Smoke rows 6
  and 7 add a run-directory check, including `check-run-contract.sh --file`
  on the real `schema-b.md`.
- README and `plugin.json`: a sixth design rule (rubrics and named failure
  modes over generic checklists), the rewritten Effort levels section, a
  new Run directory section (location, accumulation, the one-time
  `.gitignore` commit, and permission modes — an unattended
  `/kenspc-task-implement` needs `acceptEdits` or `auto`, started from the
  repository root), and the standalone reviewer note (angle-prefixed IDs
  are the one format difference from v3.4.3).

### Added

- `scripts/check-no-model-names.sh` with `--self-test`: nothing under
  `skills/`, `agents/`, `commands/`, or `shared/` names or pins a Claude
  model, and every frontmatter `model:` value is `inherit` (G6-e).
- `scripts/check-run-contract.sh` with `--self-test` and `--file PATH`: the
  `canonical:run-dir` and `canonical:stats-line` blocks stay byte-identical,
  and the worked Schema B example in `code-fixer.md` — or a real
  `schema-b.md` given with `--file` — recounts to its own Per-angle Results
  table and statistics line (G6-d/f).
- `scripts/check-json.sh` with `--self-test`: `plugin.json`, `hooks.json`,
  and `marketplace.json` parse, using the first interpreter that actually
  runs (`python3`, `python`, `py`, then `node`).
- `check-all.sh` prints `guards run: N` after the main-mode pass; with
  `--self-test` it then runs every guard's mutation fixture and prints
  `self-tests run: N`.
- `docs/dry-runs/g6-baseline.md`: the pre-G6 baseline, a single-agent
  pre-check, and a template for the acceptance run.

### Fixed

- The five guard self-tests that existed before this release
  (`check-canonical-dispatch.sh`, `check-verdict-shared.sh`,
  `check-code-craft-canonical.sh`,
  `check-quality-reviewer-bullet-structure.sh`,
  `check-notes-format-sync.sh`) exited 1 on macOS. They used GNU-only bare
  `sed -i`, and two used `{s/…/…/}`, which BSD sed rejects without a `;`.
  They now use `sed -i.bak … && rm …bak`. The failures went unnoticed
  because the self-tests ran only as separate release-checklist commands;
  `check-all.sh --self-test` now runs them together.
- The JSON checks in the release checklist and CLAUDE.md called `python`,
  which exits 127 on a macOS install that has only `python3`.
  `check-json.sh` replaces them.

## 3.4.3 — 2026-07-23

Docs patch: the root `README.md` Requirements section no longer
recommends the external superpowers plugin. Since the v3 rewrite, kenspc
has no functional dependency on it — all orchestration ships with the
plugin's own agents — and superpowers' aggressive-dispatcher style runs
counter to the v3 design philosophy (plain language over aggressive
tokens, no anti-rationalization scaffolding). No skill, agent, hook, or
CONTEXT block change.

### Changed

- Root `README.md` Requirements: replaced the stale
  `Recommended: superpowers` line with a neutral self-containedness
  statement ("No external plugin dependencies — all workflows and
  subagents ship with the plugin"). The recommendation dated from the
  pre-v3 era, when the skills themselves used the deep-reasoning trigger
  token and the pairing was deliberate; v3 removed that token, leaving
  the recommendation stale and misleading.

## 3.4.2 — 2026-07-08

Bug-fix and cleanup patch driven by a full external-style review of the
plugin (hooks, skills, commands, agents). Headline: the hooks subsystem
was found entirely inert — one hook never fired on Windows, one had
never logged a record, one was an empty husk — and is now repaired or
removed. No CONTEXT block schema change; no agent contract change.

### Rationale

All three hook defects share one root cause: hook detection logic that
depends on harness-private encodings (the Write tool's path separator
convention, the transcript's slash-command encoding) with no contract
guaranteeing those encodings stay stable. The v3.0.3 probe results had
silently gone stale. Each fix was verified against live data (simulated
tool input for the path hook; real session transcripts for the
telemetry patterns). Separately, two routing/scaffolding cleanups align
the plugin with its own v3 design rules: command wrappers no longer
duplicate the skills' trigger-phrase surface, and the closure-phrase
disablelist moved from the prompt to the smoke-test side.

### Fixed

- `remind-plan-skill.sh`: Windows backslash paths (`C:\\...` in the
  tool-input JSON) never matched the forward-slash directory globs, so
  the hook never fired on Windows. Path separators are now normalized
  before matching. The `grep -oP` extraction (GNU-only; aborts the hook
  under `pipefail` on macOS BSD grep) is replaced with POSIX `sed`. The
  `*GUIDE.md` glob no longer false-positives on names like
  `STYLEGUIDE.md` (word-boundary variants `*/GUIDE.md`, `*-GUIDE.md`,
  `*_GUIDE.md`).
- `session-end-telemetry.sh`: the detection patterns expected
  `"content":"/kenspc-task-implement`, but real transcripts encode user
  slash commands as
  `"content":"<command-message>kenspc:kenspc-task-implement</command-message>…`
  — the telemetry had never logged a record since it shipped in v3.0.3.
  Patterns now match the real encoding (namespace prefix tolerated).
  Review evidence now also accepts the in-skill Phase 2 dispatch of the
  review-angle agents (`"subagent_type":"(kenspc:)?requirements-reviewer"`):
  the normal task-implement flow reviews via agent dispatch, not a
  slash command, so the old semantics would have logged every healthy
  run as a missed review. Verified against three historical
  task-implement transcripts (all now correctly classified).
- Frontmatter: `argument-hint: [path-to-task-file] ...` values in the
  task-review command and SKILL are now quoted — unquoted leading `[`
  parses as a YAML flow sequence (the two-sequence command form is not
  even valid strict YAML); Claude Code's parser tolerated it, but this
  was exactly the latent parse-break class the release checklist warns
  about.
- `hooks.json`: the `${CLAUDE_PLUGIN_ROOT}` expansions in both hook
  commands are now quoted. With an unquoted expansion, any plugin root
  containing a space (e.g. a `--plugin-dir` dev checkout under
  `C:\Projects\KENSPC\Claude Plugin`) split the argument and both hooks
  failed with "No such file or directory" before their scripts ever
  ran. Caught by the v3.4.2 smoke test.

### Removed

- `check-deps.sh` SessionStart hook (script + registration): its
  ralph-loop dependency check was gutted by the v2.0 subagent refactor
  and the empty husk had run as a no-op at every session start since.
  Re-add a real dependency check if one is ever needed; the v1-era
  logic remains in git history.

### Changed

- Commands: all six command wrappers now declare
  `disable-model-invocation: true` and a one-line description. Claude
  Code merged commands and skills, so both descriptions load into
  context and compete for natural-language auto-routing; the skill
  keeps the trigger-phrase surface, the command becomes a pure explicit
  entry point (per the documented `disable-model-invocation` mechanism).
- `task-implement` Closure Wording Boundary: the forbidden-phrase
  enumeration moved out of the SKILL prompt into the release-checklist
  smoke test (now the canonical home of the phrase list). Enumerating
  forbidden phrasings in a prompt primes the model toward them — the
  same reasoning as the v3.0 no-anti-rationalization rule; the prompt
  keeps the positive template-only contract.
- `task-review` SKILL: the dry-run label-vocabulary convention
  relocated to `docs/dry-runs/README.md` — it governs repo-internal QA
  artifacts, not plugin behavior, and was costing context on every
  invocation.
- `generate-brief`: the former Phase 3 (next-step suggestion) folded
  into Phase 2, matching the skill's stated two-phase structure.
- `generate-task`: the Phase 1 DONE criterion admits XS sizing
  (previously "S or M", contradicting the sizing table that targets
  XS/S/M).
- Document reviewers (`plan-document-reviewer`, `task-document-reviewer`,
  `guide-document-reviewer`): commits now stage only the document under
  review, so unrelated working-tree changes cannot be swept into a
  review commit.

## 3.4.1 — 2026-07-07

Infra/docs patch: a single entry point for the guard scripts, a currency
pass on the effort-guidance citation (Opus 4.7 → 4.8), and a structural
cleanup of the repo-root CLAUDE.md. No skill, agent, or hook content
changes; no CONTEXT block schema change.

### Rationale

The guard scripts had grown to six, each individually invoked in two
places (CLAUDE.md's "Validate plugin structure" block and the release
checklist pre-flight) — adding a seventh guard meant editing command
lists in multiple files, exactly the silent-drift class the guards
themselves exist to prevent. A wrapper that globs `scripts/check-*.sh`
removes those sync points: new guards are picked up with zero doc edits.
Separately, the effort-ladder rationale in CLAUDE.md cited "Anthropic's
Opus 4.7 recommendation" undated — a generation-pinned claim that reads
as stale as frontier models advance. The citation is now dated and
re-verified at each release via a new checklist item; verified
2026-07-07 that Opus 4.8 guidance keeps `xhigh` as the recommendation
for coding/agentic work, so the plugin metadata and README now cite 4.8.

### Added

- `scripts/check-all.sh` — wrapper that runs every other `check-*.sh`
  guard in main mode, reports PASS/FAIL per script, prints the failing
  guard's output, and exits 1 on any failure. Glob-based and
  self-excluding, so future guard scripts are picked up automatically.
  Deliberately does not run the `--self-test` fixtures — those stay
  explicit in the release checklist (slower; only needed before
  tagging).
- `docs/release-checklist.md` "Docs currency (manual)" section — before
  tagging, confirm the CLAUDE.md effort-guidance citation still matches
  the current frontier Claude generation and update its "last verified"
  date.

### Changed

- `docs/release-checklist.md` pre-flight: the six individual guard
  invocations collapse into one `bash scripts/check-all.sh`; the
  "must exit 0" count drops from fourteen to nine (3 JSON validations +
  `check-all.sh` + 5 mutation regression self-tests).
- `.claude-plugin/plugin.json` description: "aligned with Opus 4.7" →
  "aligned with Opus 4.8" (the underlying recommendation is unchanged —
  see Rationale).
- `README.md`: the two current-state effort-guidance references updated
  from Opus 4.7 to 4.8. The Design Philosophy citations keep 4.7 by
  design — they record the v3.0 refactor's historical provenance.
- `CLAUDE.md` (repo root): guard-script mechanics now documented once
  (in "Repository scripts/") with the Maintenance note deduplicated to
  the invariants themselves; the two effort tables replaced by
  default-plus-exceptions prose with the per-file `effort:` frontmatter
  declared authoritative; the three hooks' runtime behaviour and the
  transient `docs/` workflow-artifact convention documented; the
  effort-guidance citation dated and generation-aware; the "## Git"
  section removed (the maintainer's global conventions apply).

## 3.4.0 — 2026-07-07

Two write-side strengthenings of the code-craft rules, both behavioural.
Surgical Changes gains a cosmetic-vs-structural split: the style-preservation
checklist bullet now says what to do when the surrounding style is mixed
(follow the language's standard conventions), and a new bullet covers
genuinely contradicting structural patterns (follow one, state why, flag the
other for cleanup — never blend a hybrid). Separately, the falsifiability
check introduced review-side in v3.2.0 now also applies at authoring time:
`task-implementer` requires each test it writes to be able to fail, and
treats "no failing-capable test can be written" as a design concern to
record, not a gap to paper over with a tautological test. Minor bump because
both add new writer-agent behaviour; no CONTEXT block schema change, no
review-side change, and the `<!-- canonical:principle:* -->` blocks are
untouched — all edits sit outside the byte-identity hash ranges.

### Rationale

Two gaps surfaced when auditing the code-craft rules against their upstream
sibling formulation (the maintainer's global code principles, refined
2026-06-29). First, the Surgical Changes checklist told the writer agents to
preserve the original code's style but assumed that style is consistent; in a
mixed-style file the rule gave no answer, and in a codebase with two
genuinely contradicting structural patterns (competing error-handling models,
data-access approaches, state-management styles) the agents had no rule
against producing a hybrid that inherits the failure modes of both. Second,
v3.2.0 deliberately scoped falsifiability to the review harness ("applied
here to the review harness rather than to authored code"); that left a
review→fix round-trip as the only defence against tautological tests the
implementer itself writes. Requiring falsifiability at write time closes the
loop and mirrors the Apply/Detect symmetry the other two principles already
have. The reviewer side deliberately gets no matching "hybrid blending"
detect bullet: migration-in-progress codebases legitimately contain both
patterns, and exclusion conditions tight enough to avoid false positives
could not be written — prevention at write time is the better-placed control.

### Changed

- `shared/code-craft-principles.md`: the Surgical Changes checklist bullet
  "Preserve the original code's style and structure" gains a mixed-style
  fallback (follow the language's standard conventions when no documented
  project convention resolves the inconsistency), and a new checklist bullet
  covers contradicting structural patterns (follow one — prefer the more
  recent or better-tested — state the choice and reason, flag the other for
  follow-up cleanup; never blend a hybrid). Both edits are outside the
  canonical principle blocks, so the two writer agents' inlined copies are
  unaffected.
- `agents/task-implementer.md`: a stance paragraph under CODE-CRAFT
  PRINCIPLES maps the no-hybrid rule to this agent's persistence mechanism
  (record the pattern choice under the task's `Decisions:` sub-bullet, flag
  the losing pattern in `## Post-implementation notes`); the QUALITY
  CHECKLIST Tests bullet now requires each authored test to be able to fail
  and routes "no failing-capable test exists" into the task's
  `**Implementation notes:**` block as a design concern.

## 3.3.0 — 2026-06-29

The implementer now checkpoints each task's rationale into the task document
as that task completes, instead of holding it in context until the end-of-run
Schema D render. An `**Implementation notes:**` block is written directly under
each task's `**Status:**` line in the same per-task commit that already carries
the code and the status flip, so a mid-run stall (the context ceiling reached
while `autoCompactEnabled: false` waits for a manual `/compact`) can no longer
lose the reasoning behind work already committed. Schema D's three prose
sections become roll-ups assembled by reading those persisted blocks back from
disk. Minor bump because this adds new implementer behaviour; no CONTEXT block
schema change, no SKILL or agent interface change for callers, and no
review-side change.

### Rationale

A task's `**Status:**` marker and a BLOCKED task's blocking reason were already
written back per task and survived a stall, but a DONE task's
decisions/changes/tradeoffs were not — they lived in agent context as run-level
flat lists in `## Decisions made` / `## Post-implementation notes`, first
written only at the final Schema D render. A stall before that render lost the
rationale behind already-committed work. The fix widens an existing precedent
rather than introducing a new mechanism: the same per-task write that persists
Status now also persists the rationale, and the end-of-run Schema D is
re-sourced from disk rather than from context. Because the agent writes each
block and moves on, by end-of-run the rationale no longer lives in context to be
recalled — reading the document is the natural source, which is what makes the
roll-up faithful after a partial run.

### Added

- `agents/task-implementer.md`: PROCESSING APPROACH now writes an
  `**Implementation notes:**` block (DONE: `Decisions:` + `Changes/tradeoffs:`
  sub-bullets) under the task's `**Status:**` line in the same per-task commit,
  and runs a stall-recovery pre-pass that backfills a missing block from git
  history for any task already DONE/BLOCKED on a re-run; DONE CRITERIA adds the
  per-task persistence requirement (DONE in the code+status commit; BLOCKED in
  its own task-document-only commit so it is not swept into the next task's
  commit) and read-from-disk Schema D assembly (a fresh Read of the task
  document at roll-up time, not recall from context).
- `references/task-document-example.md`: an `**Implementation notes:**` block on
  the one DONE example task plus a clarifier that the block is written by
  `task-implement` at completion time, not pre-written when authoring.

### Changed

- `agents/task-implementer.md`: both STUCK HANDLING paths (3-strikes BLOCKED and
  git-conflict/environment) re-point the blocking reason to a `- Blocked:` line in
  the same `**Implementation notes:**` block (one convention, one location),
  committed on its own staging only the task document; Schema D's
  `## Blocked tasks (prose)` / `## Decisions made` / `## Post-implementation notes`
  are reframed as task-ID-prefixed roll-ups of the per-task blocks, assembled by
  re-reading the task document at roll-up time, closed by a single
  source-of-truth pointer line. The `## Tasks` table and the
  `<!-- canonical:principle:* -->` blocks are unchanged.
- `skills/task-implement/SKILL.md`: Phase 1 Step 5 notes the rendered prose are
  roll-ups of the per-task persisted notes (still rendered verbatim from the
  agent's output). The `version:` field stays at `3.0.0` per the project's
  SKILL-version convention. Edits stay outside the canonical-dispatch and
  verdict-shared markers.

No CONTEXT block schema change and no review-side change: `task-review` and the
five reviewer agents are untouched, and `requirements-reviewer` already reads the
whole task document, so the per-task blocks are in its read path for free.

## 3.2.0 — 2026-06-29

Two review-quality strengthenings, both behavioural. The test-reviewer
gains a falsifiability check (would each test fail if the logic it covers
were wrong), and the regression-verifier no longer lets the "Tests pass"
check hide an incomplete run: an involuntarily incomplete run (a crash, a
timeout, or tests that should have run but did not) is recorded as FAIL,
while intentional documented skips stay PASS but must be itemised in the
Detail cell. Minor bump because both add new review behaviour; no CONTEXT
block schema changes, no SKILL or agent interface changes for callers, and
the no-test-suite `SPOT-CHECK` behaviour is unchanged.

### Rationale

Two failure modes let a review look thorough while verifying less than it
claims. First, a test can pass no matter what the code does — asserting a
value the function returns unconditionally, for example — so it survives any
regression and protects nothing; the test-reviewer had no prompt to catch
these. Second, the regression-verifier recorded the "Tests pass" row as PASS
whenever the test command came back clean, even if the run had aborted
partway or silently skipped tests, so an incomplete run could resolve to a
clean PASS verdict and overstate what was verified. The fix splits the two
cases an exit code blurs together: an involuntarily incomplete run (a crash,
a timeout, or tests that should have run but did not) is now a FAIL, while
intentional documented skips stay PASS but must be itemised in the Detail
cell so the PASS is never silent about reduced coverage.

Both strengthenings extend the same Karpathy-derived code-craft lineage
already credited in the README Acknowledgements (Karpathy's October 2025 X
post on LLM coding pitfalls, by way of the `andrej-karpathy-skills`
compilation). The plugin previously adopted two of those four principles —
Simplicity First and Surgical Changes; falsifiability ("a test that cannot
fail is not a test") and fail-loud ("never report success you did not
verify") are extensions in the same spirit, applied here to the review
harness rather than to authored code.

### Added

- `agents/test-reviewer.md`: new REVIEW CHECKLIST bullet asking whether each
  test would fail if the business logic it covers were wrong, flagging
  tautological tests that pass regardless of the logic and noting what they
  should assert instead. Inserted directly after the existing
  behaviour-not-implementation bullet. REVIEW CHECKLIST is angle-specific and
  is not one of the drift-guarded shared sections (PREREQUISITES / FILE
  COVERAGE / CUSTOM INSTRUCTIONS), so the other four reviewer agents are
  untouched.

### Changed

- `agents/regression-verifier.md`: VERIFICATION CHECKS item 3 now weighs how
  completely the test run executed instead of trusting a clean exit code. A
  full run with every test passing is `PASS`; an involuntarily incomplete run
  — crashed, timed out, errored, or tests that should have run did not — is
  `FAIL`, with the cause and the failed / unexecuted count in the Detail cell;
  a run whose only gap is intentional documented skips (`Skip=` / `.skip` /
  `[Ignore]` / env-or-trait gate) stays `PASS` but must list the skipped tests
  and their reasons in Detail. The Schema C note documents both as distinct
  from the no-test-suite `SPOT-CHECK`; `SPOT-CHECK` behaviour is unchanged.
- `skills/task-review/SKILL.md` and `skills/task-implement/SKILL.md`: each
  Verdict determination section gains the same two clauses — an involuntarily
  incomplete test run is row-3 `FAIL` and forces a FAIL verdict; an
  intentional-skip run stays row-3 `PASS` and may still reach a PASS verdict,
  but the Verdict paragraph must note "N tests skipped by design" so the PASS
  is never silent about reduced coverage. Applied to both skills because both
  dispatch regression-verifier and consume its Schema C output through their
  own verdict sections. The clauses sit in the verdict sections, outside the
  byte-identity-guarded canonical dispatch block.
- `plugins/kenspc/.claude-plugin/plugin.json`: version `3.1.2` → `3.2.0`.

## 3.1.2 — 2026-06-27

Metadata-only patch. Scopes the plugin's user-facing description lead to
"software development" so the registry summary and full metadata read
unambiguously as a software-development plugin, disambiguating it from a
forthcoming non-development personal plugin in the same marketplace. No
SKILL, agent, command, or hook behaviour changes; no CONTEXT block schema
changes; no rename.

### Changed

- `.claude-plugin/marketplace.json`: registry summary lead reworded
  "Structured development workflows for Claude Code" → "Structured
  software development workflows for Claude Code".
- `plugins/kenspc/.claude-plugin/plugin.json`: full-description lead
  clause reworded the same way ("Structured software development
  workflows for Claude Code, ..."); everything after the lead clause is
  unchanged, preserving the marketplace-summary / full-metadata layering.
- `plugins/kenspc/README.md`, root `README.md`, and root `CLAUDE.md`:
  lead sentences that described the plugin as "development workflow(s)"
  now read "software development workflow(s)".

## 3.1.1 — 2026-05-14

Patch release closing the six DEFERRED items from the v3.1.0 5-angle
review plus two natural release-support tasks. No new SKILL or agent interface; no
CONTEXT block schema changes; no user-facing capability additions. New
script behaviour is defense-in-depth tooling on top of the v3.1.0
canonical-block byte-identity invariant.

### Changed

- `shared/code-craft-principles.md`: rewrite the awkward
  "Refactor code unrelated to the current task is out;" bullet under
  Surgical Changes into a grammatical sentence ("Don't refactor code
  unrelated to the current task — that is out of scope; ...") while
  preserving the verbatim substring `refactor code unrelated to the
  current task` that Task 12's relocation grep contract pins. Brief
  item #15. Commit `582d119`.
- `CLAUDE.md` (repo root): new "Writer-agent section header convention"
  subsection inside "Skill Development Conventions" records the canonical
  compound-adjective exception (`CODE-CRAFT PRINCIPLES`) to the
  ALL-CAPS-no-hyphens writer-agent header convention. Brief item #16.
  Commit `d13ab61`.

### Added

- `agents/task-implementer.md` and `agents/code-fixer.md`: one-line HTML
  guard comments immediately above each `CODE-CRAFT PRINCIPLES` header
  pinning the hyphen as a compound-adjective exception and pointing back
  to the CLAUDE.md convention paragraph. Co-location ensures a future
  editor sees the rationale next to the header before normalizing it
  away. Brief item #16. Commit `d13ab61`.
- `skills/task-review/SKILL.md`: new subsection
  `## Output convention — dry-run reports` after the Quality bar
  section, defining the non-overlapping label vocabularies for future
  dry-run reports (`CONDITION-MET` / `CONDITION-NOT-MET` at
  per-condition level, `FLAG` / `PASS` at per-hunk level). The existing
  v3.1.0 dry-run report at
  `docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md` is preserved
  as a historical artifact. Brief item #17. Commit `bc196bd`.
- `scripts/check-code-craft-canonical.sh`: anchor-phrase frequency
  guard appended after the byte-identity check, asserting that the
  load-bearing labels `Simplicity First` and `Surgical Changes` each
  remain present at least once in the shared file and in the two
  writer-agent files. Refines the brief's "outside the byte-identity
  hash range" scope to "anywhere in file" because the agent files
  contain the anchor labels only inside the canonical block. Brief
  item #31. Commit `19a69db`.
- `scripts/check-quality-reviewer-bullet-structure.sh`: new structural
  guard asserting that the two REVIEW CHECKLIST bullets added by v3.1.0
  to `quality-reviewer.md` ("Over-engineering ...", "Drive-by
  refactoring and style drift ...") each enumerate exactly three
  numbered conditions gated by the `**all three**` qualifier. Separate
  script per the one-guard-one-purpose pattern. Brief item #33. Commit
  `c0b0d13`.
- `--self-test` mutation regression mode on the three canonical drift
  guards (`check-code-craft-canonical.sh`, `check-canonical-dispatch.sh`,
  `check-quality-reviewer-bullet-structure.sh`). Each `--self-test`
  invocation copies the script's input files into a temp workdir, runs
  the main check (expect 0), applies a content-based mutation (expect
  1), reverts (expect 0). Cross-platform (Git Bash on Windows + WSL2
  Ubuntu). Opt-in flag; no-argument behaviour unchanged. Brief item #32.
  Commit `25c770b`.
- `docs/release-checklist.md` "Pre-flight: mechanical checks" extended
  to invoke the new structural guard plus all three `--self-test`
  modes; "must exit 0" count bumped from six to ten. Commit `09c818b`.

### Fixed

- Grammar of the Surgical Changes bullet that listed scope-creep examples.
  See "Changed" above; cross-listed here because brief item #15 was filed
  as a grammar bug. Brief item #15. Commit `582d119`.

## 3.1.0 — 2026-05-14

Adds Simplicity First and Surgical Changes code-craft principles as a new
shared resource referenced by `task-implementer`, `code-fixer`, and
`quality-reviewer`. Relocates scope-creep guards from agent bodies to a
single source of truth. No breaking changes; no CONTEXT block schema
changes; no SKILL or agent interface changes for callers.

### Rationale

The plugin had no Simplicity guidance anywhere — `task-implementer`'s
QUALITY CHECKLIST was oriented at correctness (edge cases, error
handling, async correctness), not at minimalism. Surgical guidance
existed but was scattered in three places inside `task-implementer.md`
(QUALITY RULES, AUTONOMY BOUNDARIES "Do not do even if it seems helpful",
STOP-and-BLOCKED triggers) plus `code-fixer.md`'s FIXING RULES, with no
single source of truth. Future drift between the four copies was likely.

A research conversation analyzed `doggy8088/andrej-karpathy-skills` (the
65-line `AGENTS.md` + 522-line `EXAMPLES.md` distilling Karpathy's four
LLM-coding pitfalls). Two of those four principles fill the gap:
Simplicity First and Surgical Changes. The other two were intentionally
not adopted — Goal-Driven Execution is already covered by kenspc's
DONE-criteria pattern across every SKILL, and Think Before Coding for
ad-hoc interactions belongs at the user-level or project-level CLAUDE.md
layer (a plugin has no reliable always-on mechanism, and adding one
would violate kenspc's own "avoid triggering this skill when..."
design rule).

The implementation follows v3's design rules. Principles are framed as
rationale ("Why: ...") rather than command-style imperatives
(Why-not-Command, Rule 2). The new shared file is a single source of
truth for principle definitions (SSoT, mirroring the
`discovery-framework.md` pattern). The two writer agents
(`task-implementer`, `code-fixer`) inline byte-identical copies of the
canonical principle paragraphs in their system prompts so the rule is
loaded into every dispatch without depending on a runtime Read; the
shared file remains the authoritative source for the longer content
(checklists, worked examples, applicability table). Byte-identity is
enforced by a new check script modeled on
`check-canonical-dispatch.sh`.

### Added

- `shared/code-craft-principles.md` — defines Simplicity First and
  Surgical Changes with rationale-form principle paragraphs, 4–6
  bullet practical checklists, and four worked diff examples
  (`❌ / ✅` pairs in C# and TypeScript covering over-abstraction,
  speculative-feature traps, drive-by refactoring, and style drift).
  Canonical principle paragraphs are bounded by
  `<!-- canonical:principle:<key>:start -->` /
  `<!-- canonical:principle:<key>:end -->` markers and mirrored
  byte-identical into the two writer agents. Includes a
  per-agent applicability table (Apply / Detect) and a closing
  "What This File Does NOT Define" section.
- `quality-reviewer`: two new REVIEW CHECKLIST bullets
  (over-engineering; drive-by refactoring / style drift), each gated
  by three explicit exclusion conditions to prevent false positives on
  project-convention abstractions, mechanically-forced cascades, and
  canonical-style convergence.
- `scripts/check-code-craft-canonical.sh` — new repo-level check
  script that sha256-hashes the canonical principle blocks in the
  shared file and in the two writer agents and fails on any
  byte-divergence. Modeled on the existing `check-canonical-dispatch.sh`
  invariant.

### Changed

- `agents/task-implementer.md`: 2 scope-creep bullets removed (one from
  `QUALITY RULES`, one from `AUTONOMY BOUNDARIES` → "Do not do even if it
  seems helpful"); new `CODE-CRAFT PRINCIPLES` section inserted between
  `QUALITY RULES` and `AUTONOMY BOUNDARIES` containing both canonical
  principle blocks with markers, the author-at-write-time applicability
  line, and the examples reference using
  `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`.
- `agents/code-fixer.md`: 2 surgical bullets removed from `FIXING RULES`;
  new `CODE-CRAFT PRINCIPLES` section inserted between `FIXING RULES`
  and `FIXING PRIORITY` containing both canonical principle blocks with
  markers, the author-at-fix-time applicability line naming the
  DEFERRED disposition, and the examples reference.
- `README.md`: "Stack-agnostic" reworded as "Stack-agnostic skill
  behavior" with a clarifying clause about documentary examples being
  stack-specific; new Acknowledgements paragraph crediting Karpathy /
  doggy8088 / forrestchang inserted between the agent-skills paragraph
  and the thinkfirst paragraph.
- `CLAUDE.md` (root): Plugin Directory Layout tree under `shared/`
  extended from one to two entries; the `shared/` paragraph extended
  to cover the new file's consumers and explicit non-scope.
  `Repository scripts/` section and `Validate plugin structure` block
  extended to list the new check script.
- `docs/release-checklist.md` "Pre-flight: mechanical checks" updated
  to invoke the new check script; "must exit 0" count bumped from
  five to six and "shell drift guards" from 2 to 3.

### Acknowledgements

Karpathy's October 2025 X post on LLM coding pitfalls is the source of
the two adopted principles; see the plugin README Acknowledgements for
the full lineage chain (Karpathy → forrestchang → doggy8088 → kenspc).

### Out of scope (deferred / not adopted)

- Karpathy Principle 1 "Think Before Coding" for ad-hoc non-workflow
  interactions — intentionally not in the plugin (plugin has no
  reliable always-on mechanism; belongs in user / project CLAUDE.md).
- Karpathy Principle 4 "Goal-Driven Execution" — already covered by
  kenspc's DONE-criteria pattern across all SKILLs.

## 3.0.3 — 2026-05-11 — Phase Transition Anchors & Emergent Behavior Formalization

Patch release based on the first end-to-end DungeonDescent dogfooding
trace (pixel-font-pass). Nine prompt-engineering refinements + meta-
lessons captured in CLAUDE.md. All edits are prompt-text refinements;
no new SKILLs, agents, or components.

### Phase 1 transitions (P0)
- task-implement Phase 1 Step 3 hardened as batch-confirmation gate
- task-implement Phase 1 Step 5+ disables cross-Phase closure wording
  (with explicit allowlist for Phase-internal progress phrases)

### Emergent behavior formalization (P1)
- generate-brief Phase 1 system-reminder conflict detection + Discovery
  Mode artifact field (full / rapid-direct / rapid-inferred)
- task-implement / task-review CUSTOM_INSTRUCTIONS dynamic construction
  formalized as conditional fold with N/A default

### Coverage gaps (P2)
- regression-verifier fallback for projects without test suite
  (spot-check mode); Schema C row 3 ("Tests pass") gains SPOT-CHECK as
  a documented third Result value alongside PASS / FAIL
- generate-task suggests /kenspc-plan re-run when reviewer reports
  non-empty Plan-Level Concerns

### Long-term value (P3)
- SessionEnd telemetry hook for missed-review tracking (zero
  user-visible disruption; JSON Lines log at
  `~/.claude/kenspc/missed-reviews.log`)
- check-canonical-dispatch.sh upgraded to byte-identity + anchor phrase
  frequency dual check
- CLAUDE.md adds two design lessons: Phase transitions via artifacts;
  hook scope boundaries

### Meta-lessons (informing this patch)
- Stop hook misjudgement: rebatched to SessionEnd telemetry after
  recognizing hooks cannot observe SKILL-internal Phase state
- Author warning: prompt changes are not code changes — verification
  must be runtime trace inspection, not build/test pass

### Known asymmetry (deferred to v3.0.4+)
- generate-plan does NOT mirror generate-brief's Discovery Mode
  Detection — generate-plan input is typically more structured;
  reminder pressure has not been observed in plan generation traces

## 3.0.2 — 2026-05-06

Over-constraint cleanup. Removes two v3.0.0-introduced constraints that
violated v3's own bitter-lesson philosophy: forced English runtime output
and the static `Status` column on Planned Dispatch tables. No new
features; no SKILL interface or agent name changes; no CONTEXT block
schema changes.

### Removed

- Forced English runtime output. Removed from 4 agents
  (`plan-document-reviewer`, `guide-document-reviewer`,
  `task-document-reviewer`, `task-implementer`), the project root
  `CLAUDE.md` "Writing Rules for Skill Content" section, the plugin
  `README.md` Design Principles section, and the `plugin.json`
  description string's sixth design rule. v3 master plan AC6
  ("No bilingual output") is retired with a placeholder section that
  cites the retirement decision; AC numbering preserved so AC7–AC11
  references stay valid. `code-fixer.md`'s code-artifacts English
  constraint and `task-implementer.md`'s renamed CODE ARTIFACTS LANGUAGE
  block are intentionally kept (they scope to code artifacts only).

### Changed

- Planned Dispatch table header: `Status` → `Role` across 5 dispatching
  SKILL.md (6 tables total — `task-implement` has 2). Each row's `Role`
  cell is a one-line agent purpose string (≤ 60 chars) drawn from the D3
  mapping in the v3.0.2 plan. v3 master plan AC8 reversed: now asserts
  the Planned Dispatch window has NO Status column / pending marker.
- Plugin description rewritten from "six design rules ... and English-only
  output" to "five design rules" (drops the sixth rule).
- v3 master plan AC10 README review checklist updated: "6 rules" → "5
  rules"; "Bilingual claim removed" → "English-only output feature claim
  removed". CLAUDE.md review checklist drops the now-stale "Output in
  English only bullet present" assertion.
- `docs/release-checklist.md` row 3 (`/kenspc-brief` smoke) Pass
  criterion changed from "first user-facing prompt is English-only" to
  "first user-facing prompt is a question (not a draft)" — covers the
  brief's no-draft-during-discovery invariant without enforcing language.

### Rationale

The v3.0.0 plan's Non-Goals item 7 already recorded the underlying root:
"Live updating dispatch tables — Claude Code's TUI already handles this".
v3.0.0 nonetheless shipped tables with hard-coded `pending` cells that
the orchestrator could not edit after dispatch — the table always lied.
The TUI bottom bar is the real live state. The forced-English output
rule was the same antipattern in another dimension: using SKILL/agent
text to constrain a runtime decision that session/global/project
CLAUDE.md context already controls.

This is a correction of v3.0.0 execution drift, not a reversal of
direction. The bitter lesson is "guards should enforce things that are
actually enforceable", not "fewer guards".

### Note

- Result tables (Schemas A/D/E/G — rendered after dispatch) keep their
  `Status` columns. Those reflect real outcomes the orchestrator computes
  before rendering, so they are correct.
- `.claude-plugin/marketplace.json` is unchanged (audited clean — its
  description is a one-sentence registry summary that never carried the
  English-only claim).

## 3.0.1 — 2026-05-05

Post-review hardening pass. The v3.0 implementation passed all 11 plan
ACs and shipped clean, but the post-implementation multi-angle code review
surfaced verification-surface weaknesses (mostly in the AC commands
themselves) that were worth closing before users encountered them. No
behavioral change to skills or agents — the user-facing surface is
identical to 3.0.0.

### Added

- `scripts/check-review-agent-drift.sh` — guards the byte-identity
  invariant across the 5 review-angle agents (PREREQUISITES, FILE
  COVERAGE, CUSTOM INSTRUCTIONS sections must stay identical). Project
  CLAUDE.md flagged drift as a bug; this script is the mechanical guard.
  Now part of plan AC9.
- `scripts/check-canonical-dispatch.sh` — guards the byte-identity
  invariant on the `## Code Review Phase (unconditional)` block between
  `task-review/SKILL.md` and `task-implement/SKILL.md`. Replaces the v3.0
  AC7 `grep -A 20 ... | head -25` pipeline, which coupled verification to
  the canonical block's line count. The new approach extracts everything
  between explicit `<!-- canonical:dispatch:start -->` /
  `<!-- canonical:dispatch:end -->` markers and sha256-hashes it.
- HTML comment markers (`<!-- canonical:dispatch:start -->` /
  `<!-- canonical:dispatch:end -->`) around the canonical dispatch block
  in both `task-review/SKILL.md` and `task-implement/SKILL.md`. The
  markers are inert to the LLM (they are HTML comments) but make the
  byte-identity contract explicit.
- `docs/release-checklist.md` — manual smoke checklist that exercises
  plugin load + first interactive surface of every entry point. Closes
  the gap that v3.0's mechanical AC1–AC11 left open: a YAML frontmatter
  break passes every grep but breaks plugin loading.
- Project `CLAUDE.md` documents the marketplace.json / plugin.json
  description-layering convention (registry summary vs full metadata —
  not meant to be byte-synced) and the new `scripts/` directory.

### Changed

- Plan AC5 (no aggressive language) tightened from `^MUST | NEVER `
  column-anchored regex to `grep -rnwE` word-boundary match. Catches
  inline (`you MUST do X`), indented (`- MUST`), end-of-line, and
  punctuation-followed forms that the v3.0 pattern missed.
- Plan AC6 (no bilingual output) tightened from `/ 中|/ 华|中 /|华 /`
  (only catches `中`/`华`) to a Latin/CJK-with-spaced-slash pattern that
  catches any CJK character bilingual label, while still letting
  unspaced compound terms like `(代码审查/review代码)` through. Reviewer
  must spot-check for paragraph-level translations and other variants.
- Plan AC7 replaced with `bash scripts/check-canonical-dispatch.sh`. No
  more magic-number window.
- Plan AC8 (Dispatch Status Tables) tightened to require `pending` to
  appear inside an actual markdown table row (line starting with `|`) so
  a stray `pending` in prose cannot satisfy the check.
- Plan AC9 grew two cheap text-level sanity checks: drift script call
  and a `! grep -qiE '## Review|Review Phase|review-phase'
  generate-brief/SKILL.md` (brief must remain review-phase-free).
- Plan AC11 (JSON sanity) extended to also validate
  `.claude-plugin/marketplace.json` (the registry root).
- Plugin version bumped to 3.0.1 in `plugin.json`.

### Notes

- Post-review surfaced ~32 unique findings; this release addresses the
  ones that survive deep analysis as genuine forward-looking improvements
  (drift invariant guard, canonical block markers, smoke checklist,
  AC pattern hardening). Findings reclassified as reviewer
  misdiagnoses or cosmetic doc nits are not addressed — see the analysis
  recorded in the session that produced this release for the per-finding
  disposition.
## 3.0.0 — 2026-05-04

Breaking refactor aligning the plugin with Claude Opus 4.7 at xhigh/max
effort. v3 follows six design rules: workflow SOP stays, business rules
framed as why-not-command, DONE-criteria over step-by-step flow, no
anti-rationalization scaffolding, plain language over aggressive directive
tokens, and English-only output. (The English-only rule was retired in
v3.0.2 — see that release's entry above.)

*Note: The Rationale and Acknowledgements sections below were added
2026-05-11 to document design provenance omitted from the original release
notes. The Removed/Added/Changed/Notes content is unchanged from
2026-05-04. Earlier mention of `generate-brief` in the headline was a
backfill error — `generate-brief` was introduced in v1.5.0, not v3.0.0;
see the v1.5.0 entry below.*

### Rationale

The kenspc plugin was originally designed against Sonnet 4.5 and Opus 4.5.
Many of its components — anti-rationalization tables, hardcoded numerical
thresholds, step-by-step EXECUTION FLOW sections, aggressive directive
tokens (CRITICAL/MUST/NEVER/ULTRATHINK), and bilingual output — exist to
compensate for failure modes those older models exhibited.

Opus 4.7 changes that calculus. Per Anthropic's prompting guidance, the
4.6/4.7 generation interprets prompts more literally, over-respects
aggressive language, follows literal "don't nitpick" style instructions
faithfully enough to suppress findings, and benefits from outcome-first
prompts rather than prescriptive procedures. Scaffolding built for weaker
models begins to actively harm stronger ones — the model spends effort
honoring constraints that no longer encode real limits.

v3.0 is a one-shot refactor that retires these compensations. It is a
breaking refactor (no migration period) because the plugin is single-
maintainer and the v2.0 surface area was small enough to refactor in one
pass.

### Removed

- Anti-rationalization tables (the `Common-Rationalizations`-style tables
  that listed laziness scripts) in every SKILL.md and agent .md.
- Bilingual output forcing in skill execution messages, final summaries,
  status labels, agent COMPLETION templates, command files, and hook
  scripts. The discovery framework's "How to ask" examples remain as the
  deliberate exception (illustrative phrasings for the Discovery
  conversation).
- Fake numerical Red Flags (`~15+`, `~8 rounds`, `more than half`); rewritten
  qualitatively or removed.
- `ULTRATHINK` directives; reasoning depth is now controlled by the
  `effort:` frontmatter on each SKILL.md and agent .md.
- Aggressive language tokens: uppercase `MUST`, `NEVER`, `CRITICAL`, and
  `STOP immediately` are gone. "use" / "avoid" / "do not" replace MUST/NEVER;
  stop-and-report prose replaces STOP-immediately.

### Added

- `effort:` frontmatter on every SKILL.md and every agent .md (`xhigh` /
  `max` for coding-adjacent work, `high` for read-only or document review;
  see CLAUDE.md § Subagent Review Architecture for the per-skill and
  per-agent rationale).
- Dispatch Status Tables (Planned Dispatch + result table) at every
  dispatching skill: `generate-plan`, `generate-task`, `generate-guide`,
  `task-implement`, `task-review`.
- Tabulated final reports per Schemas A–G:
  - Schema A — review-angle agents (HIGH/MEDIUM/LOW counts + per-issue
    table with file:line / severity / confidence / description columns).
  - Schema B — `code-fixer` accountability table (with required `short_label`
    ≤ 60 chars per issue) plus Deferred Issues prose.
  - Schema C — `regression-verifier` (verification check table + non-PASS
    detail prose).
  - Schema D — `task-implementer` (per-task table + Blocked / Decisions /
    Post-implementation prose).
  - Schema E — doc-reviewer agents (Angle × Status × Changes × Commit
    table); `task-document-reviewer` adds a Plan-Level Concerns section.
  - Schema F — `task-review` final consolidated report (Schema A roll-up +
    B + C + Verdict + Next Steps).
  - Schema G — `task-implement` final consolidated report (Schema D + A
    roll-up + B + C + Verdict + Next Steps; supports a BLOCKED verdict
    that omits Code Review / Fixes / Verification when every task is
    BLOCKED).
- Unconditional review dispatch in `task-review` and `task-implement`. The
  canonical paragraph is byte-identical between the two skills, so the
  rationale stays aligned across edits. The orchestrator no longer
  "decides" whether a review is needed — it dispatches and aggregates.
- Anthropic code-review-harness coverage prompt in all 5 review-angle
  agents: "Report every issue you find … Your goal here is coverage."
  Filtering happens downstream in `code-fixer` and `regression-verifier`.

### Changed

- EXECUTION FLOW prose rewritten as Goal + Inputs + DONE criteria +
  Constraints. The model decides the order; structure self-contained but
  not step-heavy.
- Business Rules rewritten as rationale-anchored "Why: …" framing instead
  of `MUST` / `NEVER` commands. Context and motivation help Claude follow
  the intent of each rule, not just its letter.
- Phase 2 self-challenge in `generate-plan` reframed as a single Goal with
  DONE criteria and Constraints (no numbered substep list).
- All SKILL.md `version:` fields bumped to 3.0.0 to align with plugin
  version.
- README Design Principles section now distills the six v3 design rules.
  Requirements section names a concrete Claude Code minimum (v2.1.0+).
  Effort levels subsection points to Anthropic's skill / subagent
  frontmatter docs.
- Project CLAUDE.md "Writing Rules for Skill Content" replaces the
  bilingual and ULTRATHINK bullets with a Rule 2 rationale-anchored
  bullet, an English-only output bullet, and a reasoning-by-effort note.

### Notes

- generate-plan ships at `effort: max`; if drafts bloat under real
  workloads, downgrade to `xhigh` in a future patch.

### Acknowledgements

The Bitter Lesson framing that motivated this refactor came from external
community analysis of Claude Opus 4.x prompting practices. Technical
principles draw from Anthropic's Opus 4.7 prompting best practices,
Anthropic's essays on context engineering and harness design, and OpenAI's
GPT-5.5 prompting guide. (For thinkfirst attribution — relevant to the
discovery framework introduced in v1.5.0, not v3.0.0 — see the v1.5.0
entry below.) For full attribution with links, see the [plugin README
Acknowledgments section](README.md#acknowledgements).

## 2.0.0 — 2026-05-04

Refactor: extract subagent definitions from per-skill `prompts/`
directories into a top-level `agents/` directory, adopting the Claude
Code subagents convention introduced in Claude Code v2.1.

*Note: The Rationale and Acknowledgements sections below were added
2026-05-11 to document design provenance omitted from the original release
notes. The Breaking changes / Added / Changed content is unchanged from
2026-05-04.*

### Rationale

Claude Code v2.1+ treats plugin `agents/` as a first-class directory:
agent files get standard frontmatter (name, description, tools, model),
appear in the `/agents` interface, and can be @-mentioned directly. The
previous `prompts/` convention was invisible to Claude Code — agents were
locked inside skills and could only be reached through their parent slash
command. Adopting the official convention makes independently useful
agents (the 5 code reviewers, the 3 document reviewers) directly
accessible without losing orchestrated workflows.

### Breaking changes

- Internal `prompts/` directories removed; subagent definitions migrated to
  `agents/` directory as plugin agents. Plugin-internal change — no impact on
  user-facing skill or command interfaces.

### Added

- 11 reusable subagents in `plugins/kenspc/agents/`, discoverable via `/agents`:
  - 5 code review angle agents (standalone-safe): `requirements-reviewer`,
    `edge-case-reviewer`, `quality-reviewer`, `bug-reviewer`, `test-reviewer`
  - 3 document reviewers (orchestration-only): `plan-document-reviewer`,
    `guide-document-reviewer`, `task-document-reviewer`
  - 3 workers (orchestration-only): `code-fixer`, `regression-verifier`,
    `task-implementer`

### Changed

- All 5 affected SKILL.md files updated to dispatch agents by name with
  structured CONTEXT input (replaces template variable substitution).
- All 5 affected SKILL.md `version` fields bumped to 2.0.0 to align with
  plugin version.

### Acknowledgements

The `agents/` directory structure follows the [Claude Code subagents
convention](https://code.claude.com/docs/en/sub-agents). For full
attribution with links, see the [plugin README Acknowledgments
section](README.md#acknowledgements).

## 1.5.0 — 2026-05-04

Adds requirement brief generation and extracts discovery logic into a
shared framework. Brief becomes a new entry point upstream of plan, for
ideas too vague to plan directly.

### Rationale

generate-plan's Phase 1 Discover previously relied on Claude's own judgment
to guide the discovery conversation, with no structural anchor for which
dimensions to explore. This worked for clear requirements (Level 1-2) but
produced inconsistent results for vague inputs (Level 3) — the quality of
discovery questions varied across sessions depending on context window state.

The shared discovery framework (`shared/discovery-framework.md`) extracts
discovery logic into a single source of truth with five structured
dimensions (Outcome, Failure Modes, The Hard Part, Hidden Context, Stakes),
four input clarity levels, and explicit exit conditions. generate-plan
Phase 1 now references it inline; generate-brief provides a standalone
entry point for users who need to think through an idea before committing
to a plan.

The five-dimension approach is adapted from Gary Chen's thinkfirst skill,
which uses seven dimensions for general-purpose prompt crafting. Two
dimensions were dropped (Components → handled by generate-task; Success
Criteria → handled by generate-plan Phase 2 acceptance criteria) to avoid
overlap with existing pipeline stages.

### Added

- `generate-brief` skill (`skills/generate-brief/SKILL.md`) — structured
  discovery conversation that produces a shareable requirement brief
  (`docs/briefs/`). Two-phase (Discover, Produce Brief), no review phase.
- `/kenspc-brief` command for invoking generate-brief directly.
- `shared/discovery-framework.md` — five-dimension discovery framework,
  shared by `generate-brief` Phase 1 and `generate-plan` Phase 1. Single
  source of truth for the discovery conversation pattern.

### Changed

- generate-plan Phase 1 (Discover) now references
  `shared/discovery-framework.md` inline instead of carrying its own
  inline discovery logic.
- `plugin.json` description updated to lead with "Requirement brief
  generation through structured discovery".
- Plugin README, root CLAUDE.md, and root README updated to document the
  brief skill, the `/kenspc-brief` command, the `shared/` directory, and
  the optional brief→plan workflow extension.

### Acknowledgements

The five-dimension discovery framework is adapted from
[thinkfirst](https://github.com/garychen-ai/thinkfirst) by
[Gary Chen](https://github.com/garychen-ai), reduced from seven dimensions
to five. See [plugin README Acknowledgments](README.md#acknowledgements)
for full attribution.

## 1.4.0 — 2026-04-08

Adds `generate-task` skill (plan→task decomposition) and hardens existing
skills with anti-rationalization scaffolding tuned for the Sonnet 4.5 /
Opus 4.5 models the plugin was being developed against. (Most of the
scaffolding additions were removed in v3.0.0 once the plugin moved to
Opus 4.7 — see v3.0.0 Rationale.)

### Added

- `generate-task` skill (`skills/generate-task/SKILL.md`) with review
  prompt and `/kenspc-task` command — decomposes a plan document into
  fine-grained executable tasks.
- Anti-rationalization tables (Common-Rationalizations) added to:
  `task-implement`, `task-review`, `generate-plan`, `generate-guide`.
- Red flags (numerical thresholds and warning signals) added to the same
  four skills.
- Prompt variable tables added to `task-implement`, `task-review`, and
  `generate-guide`.
- Input validation and autonomy boundaries added to `task-implement`.
- Discovery principle, output convention, and trigger cleanup added to
  `generate-plan`.

### Changed

- `plugin.json` description updated to lead with "Plan generation, task
  decomposition, automated batch implementation with multi-angle review,
  and project guide generation".
- `task-implement`: project config change moved to STOP boundary; task
  filename convention clarified.
- Reminder hook extended to cover `generate-task` (`docs/tasks/` path).

### Fixed

- `task-implement`: stale step reference corrected.

## 1.3.0 — 2026-04-08

Reduces review iteration rounds by tightening implementation quality at
the source.

### Changed

- `task-implement`: implementation quality bar raised to align with
  `task-review` standards. Goal: fewer review rounds needed because
  implementation output passes more checks on first pass.

## 1.2.0 — 2026-04-06

Refines skill discoverability (descriptions and trigger keywords) and
adds a PreToolUse hook reminder.

### Added

- `generate-plan`: bilingual trigger keywords (Chinese + English
  invocation phrases) to broaden trigger coverage.
- PreToolUse hook reminder to clarify when each skill should engage.

### Changed

- Skill descriptions enriched across all skills to reduce "might apply"
  skips (cases where Claude would be unsure whether to activate the skill).
- Skill capability scope statements clarified.

## 1.1.0 — 2026-04-04

Tightens skill triggers, adds user confirmation gate before batch task
implementation, and enriches summaries.

### Added

- "Do NOT trigger" negative conditions on all skills, to prevent
  accidental activation during interactive development.
- `task-implement`: user confirmation step before dispatching batch
  implementation.
- `task-implement`: enriched implementation summary with
  Changes / Decisions / Notes per task, and Attempted / Root cause /
  Suggestion for blocked tasks.
- `task-implement`: consolidated final report.
- `task-implement`: `{{CUSTOM_INSTRUCTIONS}}` placeholder handling.
- `task-review`: enriched DEFERRED format with Why / Risk / Approach.
- `task-review`: enriched regression HAS ISSUES with per-problem
  Impact / Severity / Suggested action.
- `generate-plan`: git commit step in review agent execution flow +
  summary; Unresolved issues section.
- `generate-guide`: structured Unresolved gaps format in review summary.

### Removed

- Catch-all trigger phrases across all skills.

### Fixed

- `task-implement`: all-blocked logic gap.
- `task-implement`: broken `review.md` reference.

## 1.0.0 — 2026-03-29

Initial release. Plugin marketplace with three skills:
`generate-plan`, `task-implement`, `generate-guide`.

### Initial scope

- Three skills, each with `SKILL.md` and a per-skill `prompts/` directory:
  - `generate-plan` — strategic plan document generation with review
    prompt
  - `task-implement` — task implementation with implementation and review
    prompts (originally named `task-loop`; renamed within v1.0.0 — see
    In-version changes below)
  - `generate-guide` — project setup/deployment guide with review prompt
- Marketplace structure: `.claude-plugin/marketplace.json` (root) →
  `plugins/kenspc/` (plugin directory)
- Hooks for skill activation reminders
- References directory with task and plan example documents
- Slash commands for each skill

### In-version changes (same-day iterations within v1.0.0)

- `task-loop` skill renamed to `task-implement` as part of replacing the
  ralph-loop scripting model with a subagent-dispatched architecture
  (commit `2f2e732`). The `scripts/setup.sh` from the original `task-loop`
  was retired in this refactor.
- Repo restructured from flat layout to marketplace + nested plugin
  layout (commit `d02c080`).
- `owner` field added to `marketplace.json` (commit `fca7309`) — required
  by the marketplace registry.
