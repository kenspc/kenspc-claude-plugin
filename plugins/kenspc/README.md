# kenspc

A Claude Code plugin with opinionated software development workflows — plan before you
code, structured task implementation, iterative multi-angle review, and project guide
generation.

## Skills

Skills activate automatically when Claude Code detects a matching task context.

| Skill | Description |
|-------|-------------|
| generate-brief | Two-phase requirement brief generation: structured discovery conversation against the shared discovery framework (five dimensions, four input clarity levels), then writes a shareable brief to `docs/briefs/`. The brief always carries an Open Questions section: each question the discussion could not settle, marked `open` or `needs prototype` (with `Settled by:`, the result that would settle it), or `none` when nothing is open; the next-step suggestion names `/kenspc-prototype` for each `needs prototype` entry before `/kenspc-plan`. No review phase — brief is a discovery artifact, not a verifiable spec; review happens downstream when generate-plan consumes the brief. |
| prototype | Answers one open question from a brief with a throwaway prototype — logic, UI, or a feature slice. Before the prototype's first file is written, sends its frame as a message of its own — the question, the result that settles it, the kind, the location, and the resources, among them any tracked file an in-app prototype modifies — then builds the smallest thing that settles it (under `prototypes/<slug>/` by default), runs it, and commits it (`chore: add prototype <slug>`); writes the answer, the evidence, and the commit hash into the brief's entry; then removes the prototype in the next commit (`chore: remove prototype <slug>`). A location conflict, a connection your development configuration does not name, a new table or column on the development database, an in-app UI prototype's location and uncommitted files, an entry that already holds an answer, named or taken when none is named (prototype it again?), and a named entry whose status word the skill does not recognize (prototype it, or stop) are each asked about; for either entry, a "stop" or a "no" leaves the brief unchanged, and a session that cannot ask stops the same way. When the answer is your judgment (how a UI reads), the skill shows you the prototype after the add commit and waits for your verdict; a session that cannot ask commits and removes it and leaves the entry `needs prototype`, with what to look at and how. No review phase: the prototype is discarded, and its answer is reviewed where a plan uses it. |
| generate-plan | Three-phase plan document generation: collaborative discovery (uses shared discovery framework, detects briefs as input; on a brief with a `needs prototype` Open Questions entry, first asks whether to prototype it — ending the run with a `/kenspc-prototype` line — or carry it into the plan's Open Questions), drafting with self-challenge, and automated verification via review agent across four review angles (feasibility, completeness, consistency, clarity). Every plan carries a Documentation impact section — the durable documents its steps make stale, or `N/A — <reason>` — which the completeness angle checks. In a session that cannot ask, the run stops at the draft, printed in full, with no file written, no review, and no commit, until a later reply approves it. |
| generate-task | Decomposes a plan document into fine-grained executable tasks by reading actual code, written in the plan's language. When the plan's Documentation impact names documents, appends a Doc-sync task that depends on every other task. Confirms decomposition with user, then self-reviews via review agent across three review angles (completeness including Doc-sync coverage, execution order, consistency with CLAUDE.md). |
| diagnose-bug | Reproduce-first diagnosis of a bug you have observed. Reproduces it with a failing test, committed before any diagnosis, or records the manual steps when no failing-capable test can be written; finds the root cause through a hypothesis loop (three to five hypotheses, each verified, when the reproduction does not show the cause); then writes a task document for task-implement — a fix task, a regression-test task for the adjacent cases, and a Doc-sync task when durable documents are affected. A fix that needs a new dependency, an API contract change, a database schema change, or a configuration change gets a brief for `/kenspc-plan` instead. No review phase: you confirm the task list before it is written. |
| task-implement | Automated batch task implementation from a task document. Validates input is a task document (not a plan). Confirms scope with user before starting. Each task is built, tested, committed, and marked complete; a task whose `Depends on` line names a task that is not DONE is marked BLOCKED instead (dependency gate). A Doc-sync task promotes earlier tasks' decisions into the documents it lists; a decision none of them fits is reported under Decisions needing a home with a suggested destination. Automatically runs task-review on completion with a consolidated final report. |
| task-review | Parallel multi-angle code review (5 review agents → fix agent → regression verification). Works with a task document for requirements context, or standalone to review the change set it computes once — your uncommitted changes, or the commits ahead of your upstream (see Known behavior). Accepts custom instructions to narrow scope. |
| generate-guide | Generates comprehensive, beginner-friendly project setup and deployment guides with automated multi-dimensional post-generation review via review agent. |

## Commands

Commands provide a direct way to invoke each skill. As of v3.4.2 they are
explicit entry points only (`disable-model-invocation: true`, one-line
descriptions): natural-language auto-routing belongs to the skills, whose
descriptions carry the trigger phrases — the command wrappers no longer
duplicate them as a competing routing surface.

| Command | Usage |
|---------|-------|
| `/kenspc-brief` | `/kenspc-brief <rough idea or topic>` |
| `/kenspc-prototype` | `/kenspc-prototype <brief path> [entry number or question]` |
| `/kenspc-plan` | `/kenspc-plan <requirement or path> [custom instructions]` |
| `/kenspc-task` | `/kenspc-task <plan-document-path> [phase] [custom instructions]` |
| `/kenspc-diagnose` | `/kenspc-diagnose <observed bug or path to a bug report>` |
| `/kenspc-task-implement` | `/kenspc-task-implement <path-to-task-file>` |
| `/kenspc-task-review` | `/kenspc-task-review [path-to-task-file] [custom instructions]` |
| `/kenspc-guide` | `/kenspc-guide <project-path> [custom instructions]` |

Skills can also be invoked via `/kenspc:generate-brief`, `/kenspc:prototype`,
`/kenspc:generate-plan`, `/kenspc:generate-task`, `/kenspc:diagnose-bug`,
`/kenspc:task-implement`, `/kenspc:task-review`, and `/kenspc:generate-guide`.

## Plugin Structure

```
plugins/kenspc/
    .claude-plugin/
    agents/               # 11 reusable subagents
    commands/
    hooks/
    references/
    shared/               # Cross-skill resources (discovery-framework.md, code-craft-principles.md)
    skills/
    README.md
```

## Agents

Plugin agents live in `agents/` and are dispatched by skills via the Agent tool.
They are also discoverable through `/agents` and can be `@kenspc:<name>`-mentioned
where their description marks them safe to invoke standalone.

| Agent | Type | Standalone | Description |
|---|---|---|---|
| `requirements-reviewer` | Code reviewer | Yes | Requirements completeness |
| `edge-case-reviewer` | Code reviewer | Yes | Edge cases and error handling |
| `quality-reviewer` | Code reviewer | Yes | Project conventions and existing patterns |
| `bug-reviewer` | Code reviewer | Yes | Bug hunting (skeptical mindset) |
| `test-reviewer` | Code reviewer | Yes | Test coverage and quality |
| `code-fixer` | Worker | No | Applies fixes from review reports |
| `regression-verifier` | Verifier | No | Verifies fixes; read-only by design |
| `task-implementer` | Worker | No | Implements tasks from a task document |
| `plan-document-reviewer` | Doc reviewer | No | Reviews generated plan documents |
| `guide-document-reviewer` | Doc reviewer | No | Reviews generated guide documents |
| `task-document-reviewer` | Doc reviewer | No | Reviews generated task documents (completeness including Doc-sync coverage, execution order, consistency with CLAUDE.md) |

Agents marked "Standalone: No" are orchestration-only — their description starts
with `INTERNAL:` and their body refuses on missing CONTEXT. Invoke them through
the parent slash command instead.

Each reviewer is read-only on the working tree and writes only under
`RUN_DIR`: its report at `RUN_DIR/angle-<n>.md`, and probe and temporary
files under `RUN_DIR/scratch/angle-<n>/`.
Invoked standalone, without a run directory, they reply inline, write
nothing, and work out the change set from git themselves. Dispatched by `/kenspc-task-review` or `/kenspc-task-implement`,
which pass `RUN_DIR`, they write only there. The Write tool they carry is for
those files; they already had Bash. Standalone output keeps the
v3.4.3 shape (Findings table, Issues table, closing line); the one format
difference is that issue IDs carry the angle's letter (`B1`, not `1`).

## Installation

### From GitHub marketplace

Add this repository as a marketplace source, then install the plugin:

```bash
# Add the marketplace (one-time setup)
/plugin marketplace add kenspc/kenspc-claude-plugin

# Install the plugin (choose scope: user, project, or local)
/plugin install kenspc@kenspc-claude-plugin
```

### Local development

For plugin development or testing local changes:

```bash
claude --plugin-dir /path/to/kenspc-claude-plugin/plugins/kenspc
```

Use `/reload-plugins` to pick up changes without restarting.

### Managing the plugin

```bash
# Disable without uninstalling
/plugin disable kenspc@kenspc-claude-plugin

# Re-enable
/plugin enable kenspc@kenspc-claude-plugin

# Update to latest version
/plugin update kenspc@kenspc-claude-plugin

# Uninstall
/plugin uninstall kenspc@kenspc-claude-plugin
```

## Design Principles

v3 follows six design rules:

- **Workflow SOP** — The brief → plan → task → implement → review chain stays.
  Each skill's phase structure is preserved; v3 changed how each phase is
  executed, not what the phases are.
- **Why-not-Command business rules** — Business rules are framed as rationale
  ("Each task = one commit because the review unit is a task, not a session"),
  not as command-style imperatives. Context and motivation help Claude follow
  the intent, not just the letter, of each rule.
- **DONE-criteria over step-by-step flow** — Skills and agents declare a
  single-sentence Goal, the required Inputs, verifiable DONE criteria, and
  Constraints. The model decides the order. Numbered EXECUTION FLOW prose
  is removed.
- **No anti-rationalization scaffolding** — The anti-rationalization tables
  (`Common-Rationalizations`-style tables that listed laziness scripts) and
  fake numerical Red Flags (`~15+`, `~8 rounds`, `more than half`) are
  removed; listing specific laziness scripts inside the prompt primes the
  model toward those scripts.
- **Plain language over aggressive tokens** — Uppercase imperatives like
  `MUST` and `NEVER`, `CRITICAL` labels, and the deep-reasoning trigger token
  used in earlier versions are all removed. Reasoning depth now follows the
  session's effort level, with `effort:` frontmatter overrides where a file
  needs more; "use" / "avoid" / "do not" replace `MUST` /
  `NEVER`; stop-and-report prose replaces `STOP immediately`.
- **Rubrics and named failure modes over generic checklists** (v3.5.0) —
  Each review angle states what passing looks like and names the failure
  modes a model tends to miss, chosen from evidence in past runs; generic
  checks the model already performs (null checks, naming, DRY) are left out.
  Findings are calibrated by severity — HIGH needs a concrete failure path,
  LOW is reported only when it can be fixed in the batch and is anchored to
  a written convention or a specific defect — and a style preference with no
  written convention behind it is not a finding.

Cross-cutting properties from earlier versions are preserved:

- **Multi-angle parallel review** — The 5 review-angle agents
  (requirements / edge-case / quality / bug / test) dispatch in parallel,
  feed `code-fixer`, then `regression-verifier`.
- **Reusable agents** — Plugin agents live in `agents/`, discoverable via
  `/agents`. Standalone-safe code reviewers can be
  `@kenspc:<name>`-invoked directly; orchestration-only workers are gated
  behind their parent slash commands.
- **Stack-agnostic skill behavior** — Skills inspect project config files
  rather than assuming specific frameworks. (Documentation examples in
  `shared/` may use specific languages — currently C# and TypeScript — to
  maximize teaching density; this does not constrain which projects the
  skills work with.)

### Effort levels

Skills and agents follow your session's effort level: a SKILL.md or agent
.md without an `effort:` field inherits it, per the
[Claude Code skills frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference)
and [subagent frontmatter reference](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields).
Anthropic's guidance for the Claude 5 generation is to start from the
model's default effort — which is re-tuned with each generation — and raise
it only where the work under-executes or is hard to validate
([Choosing a Claude model and effort level in Claude Code](https://claude.com/blog/claude-model-and-effort-level-in-claude-code);
[Choosing the right effort level in Claude Code](https://academy.claude.com/tutorials/choosing-the-right-effort-level-in-claude-code);
last reviewed 2026-09-26).

Three files override the session at `xhigh`:

| File | Why |
|---|---|
| `agents/task-implementer.md` | Unattended long-horizon implementation — nobody is watching to catch a run that stops short or skips verification |
| `agents/code-fixer.md` | Unattended deduplication and fix / build / test loops across all five review reports |
| `skills/generate-plan/SKILL.md` | Multi-round draft/challenge; plan cost amortizes over every downstream task |

When a session runs at `xhigh`/`max`, set a large max-output-token budget
so the model has room to think and act across its subagents and tool calls
(this is a session/API config concern, not a plugin concern).

## Recommended Workflow

```
Rough idea → [/kenspc-brief → docs/briefs/*.md → [/kenspc-prototype →]] /kenspc-plan → docs/plans/*.md → /kenspc-task → docs/tasks/*.md → /kenspc-task-implement → /kenspc-task-review
Observed bug → /kenspc-diagnose → docs/tasks/*.md → /kenspc-task-implement → /kenspc-task-review
                                → docs/briefs/*.md → /kenspc-plan → …   (the fix needs a plan)
```

0. **Brief (optional)**: Use `/kenspc-brief` when the idea is too vague to plan directly, or when you need a shareable discovery document before planning. Skip this step if you already have a clear, structured requirement.
1. **Plan**: Use `/kenspc-plan` to create a strategic plan through collaborative discussion. If a brief was generated in step 0, pass it as the requirement: `/kenspc-plan docs/briefs/your-brief.md` — the skill detects briefs and gap-checks against the same five dimensions.
2. **Decompose**: Use `/kenspc-task` to break the plan into fine-grained executable tasks
3. **Implement**: Use `/kenspc-task-implement` to auto-implement all tasks
4. **Review**: Runs automatically after implementation, or use `/kenspc-task-review` standalone

**Prototype path.** A brief's `## Open Questions` lists what the discovery conversation could not settle, one numbered entry each, starting with its status: `open` (a decision or information nobody present has), `needs prototype` (a question a small experiment settles, with `Settled by:` naming the result that would settle it), or `answered` (settled by a prototype). On a brief with a `needs prototype` entry, `/kenspc-plan` first asks whether to prototype it or carry it into the plan's Open Questions, where the plan says which of its steps assume an answer; "prototype first" ends the run with a `/kenspc-prototype <brief path> <n>` line and writes no file. An `answered` entry is settled input for `/kenspc-plan` only when it holds `Answer:` with text after the label; one without, or with nothing after the label, is asked about in the gap round, or carried into the plan as `open`. `/kenspc-prototype` builds the smallest thing that settles the question — by default under `prototypes/<slug>/` at the repository root — runs it, and commits it (`chore: add prototype <slug>`); it rewrites the entry `answered` with the answer, the evidence, and that commit's hash, then removes the prototype in the next commit (`chore: remove prototype <slug>`, with the question, the answer, and the hash in its body). Read the prototype later with `git show <hash>`. An entry number that names no entry stops the run, building nothing and leaving the brief unchanged. `/kenspc-prototype` asks before it rewrites an entry that already holds an answer, named or taken when none is named, or an entry whose status word it does not recognize. When you answer yes to prototyping an entry with an answer again, the entry is rewritten only if the new attempt settles the question; when nothing is built, or the prototype's evidence does not settle it, the entry keeps its earlier answer, evidence, and Prototype line, and the final message names the new attempt's commits and why the question was not settled. The brief is left uncommitted, as `/kenspc-brief` leaves it. A prototype may use your development database, recognized by name only (`appsettings.Development.json`, `.env.development`, `.env.development.local`, user-secrets, or one your CLAUDE.md or README names): before it adds a table or column there, the skill warns that the development database may be the wrong place and recommends a throwaway database, and it names in the evidence every existing table it wrote rows to. It adds and applies no migration.

**Documentation path.** Every plan carries a Documentation impact section: the durable documents its steps make stale — the ones your CLAUDE.md names (a documentation table where it has one), or README.md and CLAUDE.md when it names none — or `N/A — <reason>`. `/kenspc-task` turns that list into a last task, `Doc-sync`, which depends on every other task. `/kenspc-task-implement` runs it after them: it brings the listed documents in line with what was built and promotes decisions made during implementation into them. A decision that belongs in a durable document none of the listed ones fits appears under Decisions needing a home in the final report, with a suggested destination, for you to place. When an earlier task is BLOCKED, the Doc-sync task is BLOCKED too (`depends on Task N (BLOCKED)`), so no document describes work that was not built. A listed document that does not exist is not created: the Doc-sync task is BLOCKED with the path named, unless the entry leaves that document to another task document (a later phase may create it). Because the review's fixes land after the Doc-sync task, a run where both happened ends with a Next steps bullet naming the listed documents to re-check against the fix commits.

**Bug path.** For a bug you have observed — a wrong result, a crash, an error you can trigger — start with `/kenspc-diagnose`. It reproduces the bug with a test that fails on the current code and commits that test first (`test: reproduce <symptom>`), or records the manual steps when no failing-capable test can be written. It then finds the root cause and writes `docs/tasks/<name>.md`: a `## Diagnosis` record, a fix task that turns the reproduction test green, a regression-test task for the adjacent cases it found, and a Doc-sync task when durable documents are affected. You confirm the task list before it is written; the document is committed (`docs: add task <name>`), and the skill asks whether to run `/kenspc-task-implement` on it now or to implement it yourself. When the fix needs a decision a task cannot make — a new dependency, an API contract change, a database schema change, or a configuration change — it writes `docs/briefs/<name>.md` instead and suggests `/kenspc-plan`. A bug report it cannot reproduce ends in a question about what is missing, with no document and no commit other than the one-time `.gitignore` commit; the skill removes the test files it created for the attempt, or, if you deny the removal, names them in the question. If a commit hook rejects one of its commits — a hook that runs your test suite rejects the failing reproduction test — the skill stops and asks you rather than bypass the hook.

Small fixes can skip all skills and be implemented directly: a fix you can already name that touches one file and needs no new test. Anything more — a bug whose cause is not yet known, or a fix that needs a test — goes through `/kenspc-diagnose`.

## Run directory

`/kenspc-task-review` and `/kenspc-task-implement` (Phase 2) keep each review
run's reports in a directory at the root of your repository (since v3.5.0):

```
.kenspc/runs/<YYYYMMDD-HHMMSS>-<task-doc-name or "changes">/
    change-set.md              # the change set under review (a review without a task document)
    angle-1.md … angle-5.md    # full report from each review angle
    schema-b.md                # code-fixer's full accountability list
    scratch/                   # probe and temporary files, one subdirectory per agent
        angle-<n>/             # each reviewer
        code-fixer/
            pre-fix/           # an uncommitted run: each fixed file before its first edit, as .txt, plus index.txt
        regression-verifier/
        orchestrator/          # the orchestrating session, only when it probes
```

- The final report shows code-fixer's statistics line, the per-angle results,
  the HIGH and MEDIUM rows, and the scratch-pollution note when there is one,
  plus the full path of `schema-b.md`. The LOW rows and the five full reports
  stay in the directory.
- The first run in a repository that does not yet ignore `.kenspc/` appends a
  `.kenspc/` line to `.gitignore`, in the file's existing line endings, and
  commits that file on its own (`chore: ignore kenspc run directory`, adapted
  to the commit conventions in your CLAUDE.md). The check asks git about a
  path inside the directory, so a CRLF `.gitignore` with blank lines is read
  correctly. If a commit hook rejects the commit, the run stops and reports
  the error; it does not retry or bypass the hook.
- Each agent keeps its probe and temporary files in its own subdirectory of
  the run's `scratch/` (`angle-<n>/` per reviewer, `code-fixer/`,
  `regression-verifier/`), and the orchestrating session keeps its own in
  `orchestrator/` when it probes. Every file there is named so the project's
  test runner does not collect it: for vitest and jest with their default
  patterns, no `.test.` or `.spec.` segment in a file name, no file named
  `test.*` or `spec.*`, no `__tests__` directory, and no `__mocks__`
  directory; where the project configures its own pattern, or for any other
  runner, whatever that configuration actually collects; a jest project
  keeps the `__mocks__` rule whatever its pattern. Each attempt gets a
  numbered subdirectory from the first (`angle-5/1/`); an agent that starts
  over takes the next number instead of deleting, and renames a file that
  already carries a collectable name onto a path that does not exist yet, so
  none of them needs to delete anything. No agent edits the project's
  configuration (runner config, linter config, ignore files, `tsconfig`,
  package scripts) to make room for the plugin's files. If files under `.kenspc/`, from this run or an
  earlier one, still break the project's build, test, or lint command,
  `regression-verifier` fails that check and names them; when they are the
  only cause, code-fixer's scratch-pollution note names them too. A file
  there that the test runner collects but that passes leaves the test check
  PASS, its Detail names the file, and the final report's Next steps asks
  you to delete it.
- `/kenspc-diagnose` prepares a run directory of its own,
  `.kenspc/runs/<YYYYMMDD-HHMMSS>-diagnose-<name>/`, when a hypothesis needs
  a probe, a copy, or a mutant (with the same one-time `.gitignore` commit).
  Its probes live in `scratch/orchestrator/`, one numbered subdirectory per
  attempt, under the naming rules above; the diagnosis never edits your
  source to test a hypothesis.
- Runs accumulate: nothing is deleted automatically. Remove old run
  directories when you no longer need them. After upgrading from v3.5.x,
  remove the run directories it left: their probe files can carry
  collectable names (such as `probe.test.ts`), and the unmodified build,
  test, and lint runs now report them.
- Permissions: each reviewer writes its report with the Write tool. In the
  default permission mode every write asks for approval, so an unattended
  `/kenspc-task-implement` needs `acceptEdits` or `auto` mode. The directory
  sits at the repository root, so start the session there: when the
  session's working directory is a subdirectory, the run directory lies
  outside it and even `acceptEdits` asks.

## Known behavior

- **Review scope without a task document.** With `/kenspc-task-review` and no
  task document (`REVIEW_SCOPE=changes`), the skill works out the change set
  once, before anything else runs, using read-only git commands only — no
  commit, stash, checkout, add, or reset — writes it to `change-set.md` in
  the run directory, and prints one line with the mode, the base or range,
  and the file count. The five reviewers, code-fixer, and
  regression-verifier all work from that one set (new in v3.7.0; before, each
  reviewer worked out its own). Two modes:
  - `uncommitted` — the working tree has changes (staged, unstaged, or
    untracked; paths under `.kenspc/` and ignored paths are left out): the
    set is those files, against the current HEAD.
  - `commits` — the tree is clean: the commits between your upstream and
    HEAD when the branch has an upstream and is ahead of it, otherwise the
    last commit (`HEAD~1..HEAD`). When a commit these defaults name does not
    exist — HEAD is the root commit, or there is no commit yet — git's empty
    tree stands in for it, so a fresh repository is reviewable as it is. In
    a shallow clone, or when your branch and its upstream share no history,
    the skill asks you for a range instead.

  Name commits or a range in the custom instructions to review something
  else, or paths to narrow the set to the changed files under them; a set
  that comes out empty stops the review before any agent runs. Every commit
  is pinned by SHA before the run directory is prepared, so its one-time
  `.gitignore` commit is never part of the set.
- **Uncommitted fixes.** When the change set is `uncommitted`, code-fixer
  applies its fixes to your working tree and commits nothing — no baseline
  commit of your change, no fix commit, no stash — and runs no git command
  that resets or restages a file. It records each file's state before its
  first edit under `scratch/code-fixer/pre-fix/` in the run directory (a
  `.txt` copy and an `index.txt`), and regression-verifier judges the fixes
  against that record rather than against your diff. Schema B's FIXED rows
  show `—` in the
  Commit column, and the final report's Next steps names the changed files
  for you to review and commit. With a committed change set, or with a task
  document, each fix is still its own commit; a fix to a file that has
  uncommitted changes the run did not make is deferred instead of committed
  with them. Before v3.7.0
  nothing said how to handle an uncommitted change, and a review run has
  committed one as a base for its fix commits.
- **Uncommitted `.gitignore` edits.** The one-time commit that adds
  `.kenspc/` to `.gitignore` (see Run directory) stages and commits the
  whole file as it stands in your working tree, so an edit to `.gitignore`
  you had not committed — staged or not — goes into
  `chore: ignore kenspc run directory` with the `.kenspc/` line.
  `/kenspc-task-review`, `/kenspc-task-implement`'s review phase, and
  `/kenspc-diagnose` when it probes make that commit on their first run in
  a repository that does not yet ignore `.kenspc/`. Commit or stash your
  `.gitignore` edits first, or split that commit afterwards.
- **Red interval after a diagnosis.** `/kenspc-diagnose` commits the
  reproduction test before the fix exists, so the test fails — and a CI that
  gates on the test suite is red — until the fix task lands. That is the
  true state of the code; the fix task turns the test green, and choosing to
  implement interactively at the skill's exit lets you fix it at once. When
  you implement interactively, and when the diagnosis ends without a task
  document or brief, the skill names that commit and offers `git revert`.

  While the reproduction test is red, every review run in the repository
  reports it: `/kenspc-task-review`, and the review phase of a
  `/kenspc-task-implement` run in which the fix task did not land, record
  the test run FAIL and the verdict FAIL. regression-verifier has
  no notion of a failure that predates the run: it runs the project's
  build, test, and lint commands as the project configures them, with no
  filter or exclude added, so the reproduction test's failure counts like
  any other; that is the red test doing its job, not a defect of the
  verifier. A mutation check whose copy runs the reproduction test cannot
  make its unmutated copy pass first, so it is reported as not made. Land
  the fix, or revert the reproduction commit, before a review whose
  verdict you need.
- **Subagents in interactive sessions.** In an interactive session, Claude
  Code runs subagents asynchronously and hands each result back; the
  workflow still finishes within the same turn, with no further input. The
  skills' `run_in_background: false` takes effect only in headless
  (`claude -p`) and SDK sessions, where the Agent tool has that parameter
  (Claude Code 2.1.281).
- **Branches.** The plugin does not create branches. Commits follow the
  branching rules in your project's CLAUDE.md and otherwise land on the
  current branch. The plugin takes no side on branching: whether to branch is
  decided at plan time, when you approve the plan. `task-document-reviewer`
  fixes a branch step the plan did not prescribe, or that your CLAUDE.md
  contradicts, back to the default and records a Plan-Level Concern;
  `task-implementer` follows the task document as written and asks nothing.
- **Dependency gate.** `/kenspc-task-implement` treats a task's `Depends on`
  line — one task (`Depends on: Task 3`), an ASCII-hyphen range
  (`Depends on: Task 1-5`), or a comma-separated list — as a hard dependency.
  If a named task is not DONE, whether it was BLOCKED in this run or an
  earlier one or has not run yet, the task is marked BLOCKED with one
  `depends on Task N (<status>)` reason per such task instead of being
  attempted; a number the task document does not contain gives the status
  `not found`. `Depends on` names tasks in the same task document only: a
  task document for a later phase treats earlier phases' work as existing
  code and names the task documents it assumes in its Dependency note. A
  later run skips a task already marked BLOCKED, so once the dependency is
  DONE, set the task back to TODO yourself (for `not found`, correct the
  `Depends on` line first). New in v3.6.0: a task that used to be attempted
  after a blocked dependency is now blocked.
- **Prototypes live in history.** `/kenspc-prototype` commits each
  prototype and removes it in the next commit, so the prototype stays in
  your history — which is how `git show <hash>` reads it later. Anything a
  prototype commits stays in history too, so the skill reads credentials
  and connection strings by name at run time (configuration keys,
  environment variables, a secret store), commits no file holding a value
  it read (a `.env`, a copied `appsettings.*.json`), and reads the staged
  diff for one before the add commit. The hash resolves while the add
  commit is reachable: after a rebase that replays or drops it, or a squash
  merge, it resolves only in the clone that made it, until git's garbage
  collection removes it. The answer's text survives in the brief; the remove
  commit's body survives only while that commit is reachable, and a squash
  merge keeps it only when the squashed message keeps the body.
- **Gates between the two commits.** Between the add and the remove commit
  the prototype is in the tree, and a typecheck, linter, or root-level
  project file that walks the repository reaches it — a `tsconfig.json`
  whose include reaches the root, ESLint's flat config, an SDK-style
  `.csproj` at the root. The skill runs none of your gates on the prototype
  and edits none of your configuration to exclude it; its file names follow
  the run directory's naming rule, so your test runner does not collect
  them. A pre-commit hook that runs one of those gates can reject the add
  commit; the skill then stops and asks rather than bypass the hook, and
  names the prototype's paths still staged with `git reset -q -- <paths>`,
  which unstages them so your next commit does not carry them. HEAD after a
  run that makes its remove commit holds no prototype; a run that stops
  between the two commits — a rejected remove commit, whose removal is left
  staged; a teardown that fails or leaves a table the prototype created; a
  file the prototype touched that changed after the add commit, such as an
  edit you made while the run waited for your verdict — leaves it in HEAD,
  and its last message names the add commit and the commands that would
  remove it. A file that changed is left out of those commands and named,
  so you can save that edit before taking the prototype out of that file by
  hand — deleting a file the prototype added, restoring one it modified to
  its content before the add commit.
- **Leftovers after a prototype.** The remove commit takes out what git
  tracks. Dependencies the prototype installed, its build output, a local
  database file, and other files git does not track — ignored or untracked —
  stay under the prototype's location, and the final message names them
  for you to remove, as
  `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`
  lists them: an ignored directory such as `node_modules/` as one line, a
  directory holding only untracked files the run left as one line with its
  file count, and a file kept out of the add commit for holding a
  configuration value marked as such. Files of yours that were under the
  location before the run — an in-app location is a directory of your app —
  are left out of the list. The skill deletes nothing.
- **In-app UI prototypes.** Only a UI prototype that can only render inside
  the app goes into the app. Its location comes from your CLAUDE.md or from
  you; the project's typecheck runs before building as a baseline and again
  before the add commit, green against that baseline — a typecheck that
  cannot run (a missing command, dependencies not installed) is no
  baseline, and nothing is built; and the remove commit restores every
  tracked file the prototype changed. A tracked file the prototype must
  change that holds uncommitted edits of yours is asked about first — go
  on, commit first, or stop. Going on puts your edits into the add commit,
  mixed with the prototype's, and the remove commit takes both out of the
  tree, so your edits then live only in the add commit; the final message
  names each such file and `git show <add commit>:<path>` to read it. A
  feature prototype that needs the app's runtime runs from its own
  location, importing the app's modules, when that lets it run; otherwise
  it is not built, its entry stays `needs prototype` with the reason (an
  entry that already held an answer, which you chose to prototype again,
  keeps that answer), and widening the in-app exception to features is
  your decision.
- **Missed-review telemetry.** The SessionEnd hook logs sessions that ran
  `/kenspc-task-implement` without a review to
  `~/.claude/kenspc/missed-reviews.log`. It can log a false entry when a
  headless session runs several turns, or when a session ends at a
  confirmation prompt.

## Requirements

**Required:**
- Claude Code v2.1.0+ (the version line that supports the `effort:`
  frontmatter on SKILL.md and agent .md files; required for the three
  `xhigh` overrides listed under [Effort levels](#effort-levels)).

**Recommended:**
- A session that allows a generous max-output-token budget — the three
  overrides run at `xhigh`, and so does everything else when your session
  does; the model needs room to think and act across its subagents and tool
  calls.

## Reference Documents

The `references/` directory contains example documents to help you get started:

- `task-document-example.md` — Shows the expected task document format for `task-implement`
- `plan-document-example.md` — Shows a typical plan output from `generate-plan`

## Changelog

See [CHANGELOG.md](./CHANGELOG.md) for version history.

## Acknowledgements

The anti-rationalization tables, red flags, and autonomy boundaries in this plugin
are inspired by [agent-skills](https://github.com/addyosmani/agent-skills) by
[Addy Osmani](https://github.com/addyosmani), licensed under MIT.

The Simplicity First and Surgical Changes principles in
`shared/code-craft-principles.md` are derived from Andrej Karpathy's
[October 2025 X post](https://x.com/karpathy/status/2015883857489522876) on
common LLM coding pitfalls, by way of the
[`andrej-karpathy-skills`](https://github.com/doggy8088/andrej-karpathy-skills)
`AGENTS.md` compilation by [doggy8088](https://github.com/doggy8088) (forked from
[forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)).
kenspc adopts two of the four principles; example code is original and
stack-specific to the maintainer's primary stacks.

In the same spirit, v3.2.0 extends the review harness with two further checks
of kenspc's own — falsifiability (a test that cannot fail is not a test) and
fail-loud on incomplete test runs (never report a clean pass you did not fully
verify). These are kenspc additions applied to the review agents, not part of
Karpathy's four principles. v3.4.0 extends the falsifiability rule to the
write side as well: `task-implementer` requires each test it authors to be
able to fail, closing the authoring/review loop.

The five-dimension discovery framework (`shared/discovery-framework.md`) — used by
both `generate-brief` and `generate-plan` Phase 1 — is adapted from the structured
thinking dimensions in [thinkfirst](https://github.com/garychen-ai/thinkfirst) by
[Gary Chen](https://github.com/garychen-ai). Reduced from seven dimensions to five
to fit the plan-before-code workflow: `Components` is handled downstream by
`generate-task`, and `Success Criteria` by `generate-plan` Phase 2 acceptance
criteria.

The `agents/` directory structure (introduced in v2.0) follows the
[Claude Code subagents convention](https://code.claude.com/docs/en/sub-agents) —
agent files declared with standard frontmatter, discoverable through `/agents`,
and `@kenspc:<name>`-mentionable for the standalone-safe ones.

The v3.0 refactor was motivated by Gary Chen's April 2026 video
["Mythos 要來了，你的舊提示詞正在拖垮新模型？"](https://www.youtube.com/watch?v=MdZWB8eC83Q),
which applied Sutton's [2019 Bitter Lesson essay](http://www.incompleteideas.net/IncIdeas/BitterLesson.html)
to prompt and harness design with a sharper framing than Anthropic's Claude Opus 4.7
prompting best practices and OpenAI's GPT-5.5 prompting guide: outdated scaffolding
does not just become irrelevant — it actively drags down newer models.

The technical principles applied here come from:

- Anthropic, [Prompting best practices for Claude Opus 4.7](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- Anthropic, [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (Sep 2025)
- Anthropic, [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) (Mar 2026)
- OpenAI, GPT-5.5 prompting guide — referenced in the migration notes for outcome-first prompting and the principle of avoiding step-by-step process guidance unless the exact path matters.

## License

MIT
