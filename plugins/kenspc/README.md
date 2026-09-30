# kenspc

A Claude Code plugin with opinionated software development workflows — plan before you
code, structured task implementation, iterative multi-angle review, and project guide
generation.

## Skills

Skills activate automatically when Claude Code detects a matching task context.

| Skill | Description |
|-------|-------------|
| init-project | Sets a project up for the kenspc chain in one run: an empty directory (after `git init`, first branch `main`), a directory of files once you confirm it is the project, a new app inside another repository (its `AGENTS.md` and `CLAUDE.md` pair only, and its stack's plugins on your yes), or an existing repository, where it writes only what is missing. Interviews you in five skippable rounds — project; shape and stack; UI; delivery; collaboration — reading the commands from the files rather than asking; offers to scaffold each app with its stack's official generator and, with no remote, to create a private GitHub repository. Offers to turn on the Claude Code plugins the stacks need — each language's LSP plugin, and `microsoft-docs` for .NET or Azure — in the project's `.claude/settings.json`, naming any language server missing from your PATH. Writes `AGENTS.md` as the index (commands, hard rules including two safety rules, a Documents table, workflow), a `CLAUDE.md` that imports it, and topic documents under `docs/`, marking what you did not answer `TBD(init): …`; runs its checks, asks you to confirm the file list, and commits. A rerun fills only the `TBD(init):` markers you answer. See [Project setup](#project-setup). No review phase: its mechanical checks and your confirmation of the file list are the gate. |
| generate-brief | Two-phase requirement brief generation: structured discovery conversation against the shared discovery framework (five dimensions, four input clarity levels), then writes a shareable brief to `docs/briefs/`. The brief always carries an Open Questions section: each question the discussion could not settle, marked `open` or `needs prototype` (with `Settled by:`, the result that would settle it), or `none` when nothing is open; the next-step suggestion names `/kenspc-prototype` for each `needs prototype` entry before `/kenspc-plan`. No review phase — brief is a discovery artifact, not a verifiable spec; review happens downstream when generate-plan consumes the brief. |
| prototype | Answers one open question from a brief with a throwaway prototype — logic, UI, or a feature slice. Before the prototype's first file is written, sends its frame as a message of its own — the question, the result that settles it, the kind, the location, and the resources, among them any tracked file an in-app prototype modifies — then builds the smallest thing that settles it (under `prototypes/<slug>/` by default), runs it, and commits it (`chore: add prototype <slug>`); writes the answer, the evidence, and the commit hash into the brief's entry; then removes the prototype in the next commit (`chore: remove prototype <slug>`). A location conflict, a connection your development configuration does not name, a new table or column on the development database, an in-app UI prototype's location and uncommitted files, an entry that already holds an answer, named or taken when none is named (prototype it again?), and a named entry whose status word the skill does not recognize (prototype it, or stop) are each asked about; for either entry, a "stop" or a "no" leaves the brief unchanged, and a session that cannot ask stops the same way, its last message opening with the frame. When the answer is your judgment (how a UI reads), the skill shows you the prototype after the add commit and waits for your verdict; a session that cannot ask commits and removes it and leaves the entry `needs prototype`, with what to look at and how. No review phase: the prototype is discarded, and its answer is reviewed where a plan uses it. |
| generate-plan | Three-phase plan document generation: collaborative discovery (uses shared discovery framework, detects briefs as input; on a brief with a `needs prototype` Open Questions entry, first asks whether to prototype it — ending the run with a `/kenspc-prototype` line — or carry it into the plan's Open Questions), drafting with self-challenge, and automated verification via review agent across four review angles (feasibility, completeness, consistency, clarity). Every plan carries a Documentation impact section — the durable documents its steps make stale, or `N/A — <reason>` — which the completeness angle checks. In a session that cannot ask, the run stops at the draft, printed in full, with no file written, no review, and no commit, until a later reply approves it. The plan written on approval is the draft as last printed in full, character for character; a change asked for at approval gets the full draft printed again, to approve. |
| generate-task | Decomposes a plan document into fine-grained executable tasks by reading actual code, written in the plan's language. When the plan's Documentation impact names documents, appends a Doc-sync task that depends on every other task. Confirms decomposition with user, then self-reviews via review agent across three review angles (completeness including Doc-sync coverage, execution order, consistency with the project's instruction files). |
| diagnose-bug | Reproduce-first diagnosis of a bug you have observed. Reproduces it with a failing test, committed before any diagnosis, or records the manual steps when no failing-capable test can be written; finds the root cause through a hypothesis loop (three to five hypotheses, each verified, when the reproduction does not show the cause); then writes a task document for task-implement — a fix task, a regression-test task for the adjacent cases, and a Doc-sync task when durable documents are affected. A fix that needs a new dependency, an API contract change, a database schema change, or a configuration change gets a brief for `/kenspc-plan` instead. No review phase: you confirm the task list before it is written. |
| task-implement | Automated batch task implementation from a task document. Validates input is a task document (not a plan). Confirms scope with user before starting. Each task is built, tested, committed, and marked complete; a task whose `Depends on` line names a task that is not DONE is marked BLOCKED instead (dependency gate). A Doc-sync task promotes earlier tasks' decisions into the documents it lists; a decision none of them fits is reported under Decisions needing a home with a suggested destination. Automatically runs task-review on completion with a consolidated final report. A task document with no TODO or IN PROGRESS task gets the counts of its DONE and BLOCKED tasks and a `/kenspc-task-review <path>` line for reviewing the finished work, and nothing else runs. |
| task-review | Parallel multi-angle code review (5 review agents → fix agent → regression verification). Works with a task document for requirements context, or standalone to review the change set it computes once — your uncommitted changes, or the commits ahead of your upstream (see Known behavior). Accepts custom instructions to narrow scope. |
| generate-guide | Generates comprehensive, beginner-friendly project setup and deployment guides with automated multi-dimensional post-generation review via review agent. |
| autopilot | Runs one batch of the kenspc chain unattended, from a spec or a brief to a local release preparation. Two entries: a spec (a plan document) runs unattended from task decomposition on; a brief first gets a design session whose decision table you rule on, after which the spec is committed and the rest runs unattended. Two modes: `repo` (the default — the workers use the installed plugin, acceptance is the commands the brief names or nothing, and release preparation is one commit that removes the batch's plan and task documents) and `plugin` (declared, or detected from a marketplace layout — the workers load the worktree's plugin with `--plugin-dir`, acceptance runs on a seed project and files `docs/dry-runs/<batch>-acceptance.md`, and release preparation is the repository's). One headless session per role — task decomposition, implementation, standalone review, acceptance, fix on demand, release preparation, and design at brief entry — each started through the driver script that ships with the skill and talking to your session by cross-session messages. Two human gates: the decisions on a brief's design table, and the tag, push, and release after the reports; between them your session rules every point the spec leaves open, except the stop conditions, and records each ruling for you to review before the tag. Two reports at the end: a one-page user report in your language, and a reviewer report of fixed shape with a total-cost line. Needs v2.1.271 or later (see [Requirements](#requirements)). |

## Commands

Commands provide a direct way to invoke each skill. As of v3.4.2 they are
explicit entry points only (`disable-model-invocation: true`, one-line
descriptions): natural-language auto-routing belongs to the skills, whose
descriptions carry the trigger phrases — the command wrappers no longer
duplicate them as a competing routing surface.

| Command | Usage |
|---------|-------|
| `/kenspc-init` | `/kenspc-init [project description]` |
| `/kenspc-brief` | `/kenspc-brief <rough idea or topic>` |
| `/kenspc-prototype` | `/kenspc-prototype <brief path> [entry number or question]` |
| `/kenspc-plan` | `/kenspc-plan <requirement or path> [custom instructions]` |
| `/kenspc-task` | `/kenspc-task <plan-document-path> [phase] [custom instructions]` |
| `/kenspc-diagnose` | `/kenspc-diagnose <observed bug or path to a bug report>` |
| `/kenspc-task-implement` | `/kenspc-task-implement <path-to-task-file>` |
| `/kenspc-task-review` | `/kenspc-task-review [path-to-task-file] [custom instructions]` |
| `/kenspc-guide` | `/kenspc-guide <project-path> [custom instructions]` |
| `/kenspc-autopilot` | `/kenspc-autopilot <path to a spec or a brief>` |

Skills can also be invoked via `/kenspc:init-project`,
`/kenspc:generate-brief`, `/kenspc:prototype`,
`/kenspc:generate-plan`, `/kenspc:generate-task`, `/kenspc:diagnose-bug`,
`/kenspc:task-implement`, `/kenspc:task-review`, `/kenspc:generate-guide`,
and `/kenspc:autopilot`.

## Plugin Structure

```
plugins/kenspc/
    .claude-plugin/
    agents/               # 11 reusable subagents
    commands/
    hooks/
    references/
    shared/               # Cross-skill resources (discovery-framework.md, code-craft-principles.md, instruction-files.md)
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
| `task-document-reviewer` | Doc reviewer | No | Reviews generated task documents (completeness including Doc-sync coverage, execution order, consistency with the project's instruction files) |

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

The v3 architecture follows six design rules:

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

**The project's instruction files** (4.1.0) are where every skill and agent
looks for a project's conventions.
The project's instruction files are its CLAUDE.md and AGENTS.md files — at
the root, in `.claude/`, or in a subdirectory — and the files a CLAUDE.md
imports with `@`, whether or not Claude Code loaded them in this session.

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
last reviewed 2026-09-29).

Three files override the session:

| File | Effort | Why |
|---|---|---|
| `agents/task-implementer.md` | `high` | Unattended long-horizon implementation — nobody is watching to catch a run that stops short or skips verification |
| `agents/code-fixer.md` | `high` | Unattended deduplication and fix / build / test loops across all five review reports |
| `skills/generate-plan/SKILL.md` | `xhigh` | Multi-round draft/challenge; plan cost amortizes over every downstream task |

The two agents run one level above the generation's default effort
(`medium` at the 2026-09-29 review; `xhigh` through 4.2.x), and move with
it when a later generation's default does.

When a session runs at `xhigh`/`max`, set a large max-output-token budget
so the model has room to think and act across its subagents and tool calls
(this is a session/API config concern, not a plugin concern).

## Recommended Workflow

```
New project → /kenspc-init → AGENTS.md, CLAUDE.md, docs/*.md → /kenspc-brief or /kenspc-plan
Rough idea → [/kenspc-brief → docs/briefs/*.md → [/kenspc-prototype →]] /kenspc-plan → docs/plans/*.md → /kenspc-task → docs/tasks/*.md → /kenspc-task-implement → /kenspc-task-review
Observed bug → /kenspc-diagnose → docs/tasks/*.md → /kenspc-task-implement → /kenspc-task-review
                                → docs/briefs/*.md → /kenspc-plan → …   (the fix needs a plan)
```

0. **Brief (optional)**: Use `/kenspc-brief` when the idea is too vague to plan directly, or when you need a shareable discovery document before planning. Skip this step if you already have a clear, structured requirement.
1. **Plan**: Use `/kenspc-plan` to create a strategic plan through collaborative discussion. If a brief was generated in step 0, pass it as the requirement: `/kenspc-plan docs/briefs/your-brief.md` — the skill detects briefs and gap-checks against the same five dimensions.
2. **Decompose**: Use `/kenspc-task` to break the plan into fine-grained executable tasks
3. **Implement**: Use `/kenspc-task-implement` to auto-implement all tasks
4. **Review**: Runs automatically after implementation, or use `/kenspc-task-review` standalone
5. **Autopilot (optional)**: or hand a spec or a brief to `/kenspc-autopilot`, which runs the chain from step 2 — or from a design session, at brief entry — to a release preparation unattended, stopping for you only at its two human gates and on a stop condition, and ruling every other open point itself (see [Autopilot](#autopilot))

**Setup path.** In a new directory, or a repository that has no `AGENTS.md` yet, start with `/kenspc-init`: it writes the files the other skills read — the Documents table the plan's Documentation impact is determined from, the commit convention, where the version lives — and marks what you did not answer `TBD(init): …`. See [Project setup](#project-setup).

**Prototype path.** A brief's `## Open Questions` lists what the discovery conversation could not settle, one numbered entry each, starting with its status: `open` (a decision or information nobody present has), `needs prototype` (a question a small experiment settles, with `Settled by:` naming the result that would settle it), or `answered` (settled by a prototype). On a brief with a `needs prototype` entry, `/kenspc-plan` first asks whether to prototype it or carry it into the plan's Open Questions, where the plan says which of its steps assume an answer; "prototype first" ends the run with a `/kenspc-prototype <brief path> <n>` line and writes no file. An `answered` entry is settled input for `/kenspc-plan` only when it holds `Answer:` with text after the label; one without, or with nothing after the label, is asked about in the gap round, or carried into the plan as `open`. `/kenspc-prototype` builds the smallest thing that settles the question — by default under `prototypes/<slug>/` at the repository root — runs it, and commits it (`chore: add prototype <slug>`); it rewrites the entry `answered` with the answer, the evidence, and that commit's hash, then removes the prototype in the next commit (`chore: remove prototype <slug>`, with the question, the answer, and the hash in its body). Read the prototype later with `git show <hash>`. An entry number that names no entry stops the run, building nothing and leaving the brief unchanged. `/kenspc-prototype` asks before it rewrites an entry that already holds an answer, named or taken when none is named, or an entry whose status word it does not recognize. When you answer yes to prototyping an entry with an answer again, the entry is rewritten only if the new attempt settles the question; when nothing is built, or the prototype's evidence does not settle it, the entry keeps its earlier answer, evidence, and Prototype line, and the final message names the new attempt's commits, when it made any, and why the question was not settled. The brief is left uncommitted, as `/kenspc-brief` leaves it. A prototype may use your development database, recognized by name only (`appsettings.Development.json`, `.env.development`, `.env.development.local`, user-secrets, or one your project's instruction files or README name): before it adds a table or column there, the skill warns that the development database may be the wrong place and recommends a throwaway database, and it names in the evidence every existing table it wrote rows to. It adds and applies no migration.

**Documentation path.** Every plan carries a Documentation impact section: the durable documents its steps make stale — the ones your project's instruction files name (a documentation table where they have one), or README.md and the instruction files themselves when they name none — or `N/A — <reason>`. `/kenspc-task` turns that list into a last task, `Doc-sync`, which depends on every other task. `/kenspc-task-implement` runs it after them: it brings the listed documents in line with what was built and promotes decisions made during implementation into them. A decision that belongs in a durable document none of the listed ones fits appears under Decisions needing a home in the final report, with a suggested destination, for you to place. When an earlier task is BLOCKED, the Doc-sync task is BLOCKED too (`depends on Task N (BLOCKED)`), so no document describes work that was not built. A listed document that does not exist is not created: the Doc-sync task is BLOCKED with the path named, unless the entry leaves that document to another task document (a later phase may create it). The review's fixes land after the Doc-sync task, so when a fix changes behavior a listed document describes, code-fixer corrects that document's sentence in the fix's own commit and changes nothing else in it; the final report names each document the fixes changed and each one left not updated, with the reason, or says none was affected.

**Bug path.** For a bug you have observed — a wrong result, a crash, an error you can trigger — start with `/kenspc-diagnose`. It reproduces the bug with a test that fails on the current code and commits that test first (`test: reproduce <symptom>`), or records the manual steps when no failing-capable test can be written. It then finds the root cause and writes `docs/tasks/<name>.md`: a `## Diagnosis` record, a fix task that turns the reproduction test green, a regression-test task for the adjacent cases it found, and a Doc-sync task when durable documents are affected. You confirm the task list before it is written; the document is committed (`docs: add task <name>`), and the skill asks whether to run `/kenspc-task-implement` on it now or to implement it yourself. When the fix needs a decision a task cannot make — a new dependency, an API contract change, a database schema change, or a configuration change — it writes `docs/briefs/<name>.md` instead and suggests `/kenspc-plan`. A bug report it cannot reproduce ends in a question about what is missing, with no document and no commit other than the one-time `.gitignore` commit; the skill removes the test files it created for the attempt, or, if you deny the removal, names them in the question. If a commit hook rejects one of its commits — a hook that runs your test suite rejects the failing reproduction test — the skill stops and asks you rather than bypass the hook.

Small fixes can skip all skills and be implemented directly: a fix you can already name that touches one file and needs no new test. Anything more — a bug whose cause is not yet known, or a fix that needs a test — goes through `/kenspc-diagnose`.

## Project setup

`/kenspc-init [project description]` prepares a project for the chain in one
run. The description is optional; whatever it answers is not asked. Its
first message names the language the run talks in — the language you wrote
in — and every question and the final message stay in it; the files are
written in English unless you ask for another language, since coding agents
and team members who join later read them.

**Where it starts.** It scans first, then places the directory in one of
four start points, asking git before looking at what the directory holds —
an empty directory inside another repository is inside it:

| Start point | In a session that can ask | In a session that cannot ask |
|---|---|---|
| An empty directory, outside any repository (a file browser's `.DS_Store` or the like counts as empty, and so does a directory whose own `.gitignore` ignores it whole) | Asks whether to `git init` (yes by default, first branch `main`) | `git init`, first branch `main` |
| Files, but not a repository | Lists them and goes on only once you confirm this is the project | Stops, writing nothing |
| Inside another repository, empty or not | Asks: a new app of that repository — then only this directory's `AGENTS.md` and `CLAUDE.md` pair, with no `git init`, and on your yes its stack's plugins in the root's `.claude/settings.json` — or a project of its own, which it suggests moving out first | Stops, writing nothing |
| An existing repository | Writes only the files that are missing | The same |

It also stops, writing nothing, in a bare repository or inside a `.git`
directory, on a detached HEAD (where a commit would belong to no branch),
where a `.git` file points nowhere, and wherever git finds a repository it
will not read, such as one another user owns: only git's own
`not a git repository (or any …` message, read in English whatever your
locale, counts as no git.

**The interview.** Five rounds, each one message, each skippable: the
project (name, one line, users, scope, non-goals); shape and stack (one app
or a monorepo, and each app's stack); UI (platforms, component library or
design system); delivery (versioning scheme and version file,
environments, deployment method, migration policy); and collaboration
(branch and commit conventions). What the description or the scan already
answers is not asked, except the repository's shape and its hosting, which
are confirmed once. A question nothing pre-fills is asked on its own,
not inside a confirmation. "Use the defaults for everything" ends the
interview, and is offered apart from skipping one question.
Rounds 1–2 come before scaffolding and rounds 3–5 after it, so the commands
are read from the files, never asked.

**Scaffolding.** Offered per app, never done by default: whether to
scaffold it, and with which of its stack's official generators. The skill
carries no generator command of its own — it reads the generator's `--help`
or documentation before running it — and installs no missing SDK or
runtime: it names what is missing. A monorepo puts each app under
`apps/<name>/`, laid out inside as its stack expects. A README the
generator wrote is replaced with init's version after one question; a
`.git` directory it created inside the app is moved to `.trash/` at the
project root on your yes (and `.trash/` ignored), never deleted; a
`.gitignore` it replaced gets your lines back, with its own appended. Each
scaffolded app is committed alone (`chore: scaffold <app>`) before the
documentation commit, without the dependency and build directories its
tools restore, which are appended to `.gitignore` instead — in that same
commit. When the stack's package manager keeps a lockfile and the generator
installed nothing, the skill runs the install once (starting no server), so
the lockfile goes into the scaffold commit; a failed install leaves the
scaffold as it is and is reported. An app whose
`.git` you keep gets no scaffold commit, and its `AGENTS.md` pair is written
but not committed; an app directory that already holds a `.git` of its own
is treated the same way and not offered scaffolding. A generator that fails
leaves its output in place or in `.trash/`, never deleted.

**GitHub and the backlog.** With no remote, the skill offers to create a
GitHub repository — private by default, its owner asked every time — with
`gh`, setting it as `origin` without pushing; without `gh` installed and
logged in, it gives the manual steps. A remote on another host gets no
such offer. With a GitHub remote the backlog is GitHub Issues, labeled
`bug`, `enhancement`, `debt`, and `found-by-agent`; otherwise it is one file
per item under `docs/backlog/`, its format written once in
`docs/backlog/README.md`, with no status field — the commit that resolves or
drops an item deletes its file. Either way, AGENTS.md says that an
interactive session adds a backlog item only with your agreement and an
unattended run lists what it found in its report.

**The stacks' plugins.** Once the stacks are settled, the skill offers to
turn on the Claude Code plugins they need in the repository root's
`.claude/settings.json`, where a project's `true` turns a plugin on even
when your user settings turn it off: for each app's language, the LSP
plugin Anthropic's official marketplace (`claude-plugins-official`)
carries for it, and `microsoft-docs` for a .NET app or one deployed to
Azure. A monorepo gets the union; any other plugin goes on only if you add
it. The skill finds them at run time — `claude plugin list --available
--json` and the marketplace's catalog — rather than from a list of its own,
and shows each LSP plugin's language server and whether it is on your
PATH; it never installs a language server, and an LSP plugin without one
does nothing. The question is asked even after "use the defaults for
everything" and offers only the entries the file does not have yet — an
explicit `false` there is yours and stays. On your yes it runs
`claude plugin install <plugin>@<marketplace> --scope project` for each,
which adds the entry and installs the plugin on this machine; Claude Code
writes the file back in its own formatting, and a check confirms the other
keys kept their values. The file goes into the documentation commit. A
session that cannot ask enables nothing and lists the entries and the
command. See [Known behavior](#known-behavior) for a monorepo and for your
collaborators.

**What it writes.** Only files that do not exist yet — a `README*` or
`CHANGELOG*` of any name and case counts as existing:

| File | Holds |
|---|---|
| `AGENTS.md` | An opening comment with the template marker `kenspc-init template: 1`, the line budget, and the admission rule (a line belongs only when every session needs it, the code cannot tell it, and without it an agent goes wrong or a safety floor breaks); then Project, Commands, Rules (twelve at most, always including no deploying to, migrating, or reading the data of staging or production, and no secret in the repository), Documents (a `Document \| Holds \| Changes when` table of the durable documents), and Workflow (branches, commits, backlog, and `Version lives in <file> — rules in docs/release.md`) |
| `CLAUDE.md` | `@AGENTS.md` on its first line, then a `## Claude Code` section saying the kenspc conventions are in AGENTS.md |
| `README.md` | What the project is and how to start, for people, and a documentation list naming the same files as the Documents table |
| `docs/product.md` | Purpose, users, scope, non-goals, terms |
| `docs/architecture/overview.md` | Stack, components and boundaries, data, external integrations, key decisions |
| `docs/ui/design-system.md` | The design system's sections, by token name — the tokens stay in code — or a line saying there is no UI |
| `docs/release.md` | Versioning scheme, version file, when to bump, changelog, tags, who releases |
| `docs/deployment.md` | Environments, how deploys happen, where configuration and secrets live (never their values), migrations, rollback, monitoring |
| `CHANGELOG.md` | Keep a Changelog, only when you chose SemVer or CalVer |
| `docs/backlog/README.md` | The file backlog's format, when the backlog is files |
| `apps/<name>/AGENTS.md`, `apps/<name>/CLAUDE.md` | Each monorepo app's commands and rules |
| `.gitignore` | `.kenspc/` and `CLAUDE.local.md` appended when the repository's own `.gitignore` does not already ignore them — a rule in your global excludes does not reach a teammate — in the documentation commit |
| `.claude/settings.json` | The stacks' plugins, on your yes: only the `enabledPlugins` entries it lacks, added by `claude plugin install --scope project`, in the documentation commit |

The root `AGENTS.md` and `CLAUDE.md` stay within 80 lines together at init,
each app's pair within 40, and 200 lines is the long-term ceiling. Nothing
the code already says goes into AGENTS.md, and a library you chose that is
not installed yet is written as chosen in the topic document, not as part of
the stack. The files it writes state decisions in their own words and point
to no brief, plan, or task file, since the workflow deletes those once their
work is done; AGENTS.md states that convention, and the final message lists
any such files your repository already tracks. A `.claude/CLAUDE.md` or
`.claude/AGENTS.md` counts as your CLAUDE.md or AGENTS.md, no root file is
written beside it, and the Documents table and README the skill writes name
it by that path. It writes nothing under `.claude/` except the import
line an existing `.claude/CLAUDE.md` gains on your yes and the plugin
entries the root's `.claude/settings.json` gains on your yes, no guide
(AGENTS.md says guides go in `docs/guides/`, written by `/kenspc-guide`),
and no `docs/briefs/`, `docs/plans/`, or `docs/tasks/`.

**TBD markers.** An item nobody answered is `TBD(init): <what is missing>`,
mostly in the topic documents; in AGENTS.md it costs one line at most. A
policy — a versioning scheme, a deployment method, the environments — is
never chosen for you. The two safety rules are always written.

**Checks and commits.** Before committing, the skill checks what it wrote:
the line budget, the import line on CLAUDE.md's first line, AGENTS.md's
opening comment, that every path in the Documents table exists and the
README lists the same files, that every sentence in a topic document has a
source that states what it claims — your answer, the description, or a
file — or becomes a `TBD(init):` marker the final message lists, that no
line holds a value that reads as a secret, that every TBD has the
`TBD(init):` form, the `.gitignore` lines, and that `.claude/settings.json`
parses and gained only the plugin entries you confirmed; a failing check is
fixed before anything is committed, except in `.claude/settings.json`,
which then stays out of the commit instead.
The secret check also reads your own lines wherever the commit would put
them into history for the first time — a file committed whole, an edit you
had not committed: a file with a secret-looking value on a line of yours is
not changed and stays out of the commit, and the final message names it
and the line's number. It then lists every file for you to confirm,
marking a file that held uncommitted changes of yours (a session that
cannot ask leaves it out of the commit) and a path git ignores (never added
with `-f`), and commits them as `docs: initialize project documentation`,
following the commit convention your repository writes down or its history
shows; with nothing left to commit, it makes no commit, says so, and ends
there. A "no", or a skipped confirmation, commits nothing and leaves the
files in the tree. Commits use the git identity your repository already
has — `user.name` and `user.email` both set in git's configuration, checked
before scaffolding is offered; without one, the skill says so at that point
and offers no scaffolding, so you can stop it and set one first, and it
stops before the documentation commit, in any session, and says so again,
leaving the files in the tree. After the commit, it asks separately whether
to push and whether to create the missing labels. A session that cannot ask
commits after the checks, and creates no repository, enables no plugin,
pushes nothing, and creates no label — it lists the plugin entries and the
labels to create instead.

**Running it again.** In a project it set up (an `AGENTS.md` whose opening
comment carries the template marker), `/kenspc-init` changes only the
`TBD(init):` markers you answer — the marker itself, not the rest of its
line — and the plugin entries you confirm that `.claude/settings.json`
still lacks (a stack added since, or a plugin the marketplace gained), and
nothing else, `.gitignore` included (what it lacks is named, not
appended); with no marker answered and no entry added, it changes nothing
and says so. A change an answer implies beyond its marker — a `CHANGELOG.md`
for a scheme you just chose — is named for you, not made.
Upgrading files an earlier template version wrote, and moving an existing
project's long CLAUDE.md onto the template, are not in this version.

## Run directory

`/kenspc-task-review` and `/kenspc-task-implement` keep each run's reports in
a directory at the root of your repository (since v3.5.0).
`/kenspc-task-implement` prepares it after you confirm the batch and before
it dispatches task-implementer, which keeps its own probes there, and its
review reuses the same directory (since 4.3.0):

```
.kenspc/runs/<YYYYMMDD-HHMMSS>-<task-doc-name or "changes">/
    change-set.md              # the change set under review (a review without a task document)
    angle-1.md … angle-5.md    # full report from each review angle
    rulings.md                 # a ruling on the findings, when one was given before code-fixer ran
    schema-b.md                # code-fixer's full accountability list
    scratch/                   # probe and temporary files, one subdirectory per agent
        task-implementer/      # task-implementer's probes, copies, mutants, and runner configs
        angle-<n>/             # each reviewer
        code-fixer/
            pre-fix/           # an uncommitted run: each fixed file before its first edit, as .txt, plus index.txt
        regression-verifier/
        orchestrator/          # the orchestrating session, only when it probes
```

- The final report shows code-fixer's statistics line, the per-angle results,
  the HIGH and MEDIUM rows, and the scratch-pollution note when there is one,
  plus the full path of `schema-b.md`. The LOW rows and the five full reports
  stay in the directory. Between the agents the run prints only one progress
  line per step — the agent that returned, its counts or result, and the path
  of its report when it writes one — and the roll-up, code-fixer's reply, and
  the verification table appear once, in the final report.
- `rulings.md` carries a ruling on the reviewers' findings to code-fixer and
  regression-verifier. The orchestrating skill (task-review's Step 5, or
  task-implement's review) writes it before it dispatches code-fixer, from
  a ruling it already holds when it gets there — in an interactive run, a
  message from you received before that dispatch; in an autopilot worker,
  the main session's answer to the worker running the review. It adds no
  pause and asks nothing: with no ruling, no file is written and nothing
  changes. Its first line names who ruled, then one entry per ruling:
  `- <ID>[, <ID>…]: FIX — <what to do>`, `- <ID>[, <ID>…]: DEFER — <reason>`,
  or `- <ID>[, <ID>…]: NOT APPLICABLE — <reason>`. code-fixer gives a ruled
  ID the ruling's action over its severity rules — a FIX ruling's text
  bounds the fix, and a file it names is in that fix's scope — keeps the
  action's leading word, and marks the row `ruled` after the em-dash
  (`DEFERRED — ruled`), so the counts are unchanged; its reply names a
  ruled ID no report lists. IDs ruled differently are not merged into one
  row, and a FIX ruling whose fix cannot land — its build, tests, or lint
  fail, or the ruling cannot be carried out in the code as it stands — is
  DEFERRED with the reason, which regression-verifier then reports as a
  ruling not carried out. regression-verifier checks that each ruled ID
  sits in a row whose action matches its ruling, reports a ruled ID no
  report lists as a bookkeeping error, and checks a FIX-ruled fix against
  the ruling's text as well as the report. The CONTEXT block the agents
  get stays unchanged: a ruling never goes into `CUSTOM_INSTRUCTIONS`, and
  the five reviewers, which returned before it was written, do not read it.
  The final report names the file and who ruled when it exists.
- The first run in a repository that does not yet ignore `.kenspc/` appends a
  `.kenspc/` line to `.gitignore`, in the file's existing line endings, and
  commits that file on its own (`chore: ignore kenspc run directory`, adapted
  to your repository's commit convention — see Known behavior); in
  `/kenspc-task-implement` that commit comes after you confirm the batch, so
  a declined batch commits nothing. The
  check asks git about a path inside the directory, so a CRLF `.gitignore`
  with blank lines is read correctly. If a commit hook rejects the commit,
  the run stops and reports the error; it does not retry or bypass the hook.
- Each agent keeps its probe and temporary files in its own subdirectory of
  the run's `scratch/` (`task-implementer/`, `angle-<n>/` per reviewer,
  `code-fixer/`, `regression-verifier/`), and the orchestrating session keeps
  its own in `orchestrator/` when it probes. task-implementer runs a mutation
  check — a new test shown failing against a broken implementation — on
  copies there, and never edits, backs up, or restores a tracked file to
  test it: a mutation made in place and restored afterwards would leave your
  source mutated if the run stopped between the two. Every file there is named so the project's
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

## Autopilot

`/kenspc-autopilot <path to a spec or a brief>` runs one batch of the chain
unattended, one headless `claude -p` session per role: S2 `/kenspc-task`, S3
`/kenspc-task-implement`, S3b a standalone `/kenspc-task-review` over the
batch's range, S4 acceptance, S5 a fix on demand, S6 the release
preparation — and S1, a design session, at brief entry. Each is started
through a driver script while your session (the main session) waits for
it, rules on the workers' questions, and classifies what they produce; the workers use the installed plugin in `repo` mode and the
worktree's plugin (`--plugin-dir`) in `plugin` mode. One role per session,
never reused: a session that edited the plugin still runs the text it
started with, so the review, the acceptance, and a fix are each a session
of their own.

Start the main session with the name the workers will address:

```
claude --name <batch>-main --permission-mode bypassPermissions --settings '{"crossSessionInbound":"accept"}'
```

The batch name is the argument file's base name without its extension.
When the session was started otherwise, the run uses the name `ListAgents`
prints on its first line and records it. Bypass permissions and accepted
inbound messages are what let a worker's question reach the main session
without a prompt to approve it.

When the launch line carries no `crossSessionInbound` accept, the run
reads the value from the settings files Claude Code reads it from — the
managed settings (the `managed-settings.json` file and its
`managed-settings.d/` directory in the system directory for your platform,
the macOS managed preferences domain, the Windows policy registry values),
the launch line's `--settings`, its inline JSON or the file it names, your user
settings (`$CLAUDE_CONFIG_DIR/settings.json`, else
`~/.claude/settings.json`), and the project's `.claude/settings.json` and
`.claude/settings.local.json` — with the documented precedence, a stricter
project or local value winning. An effective `accept` goes on, the state
file's `inbound:` line naming the file and line, or the managed source,
it came from; `hold`, `refuse`, or no value at all stops the run, naming
the launch line — and, for `hold` or `refuse`, the file, managed source, or inline JSON
that set it. The
run asks whether a settings file accepts inbound messages only when a file
exists that it cannot read or parse, when a read of a Windows policy value
fails for a reason other than an absent key or value, when a source sets a
value other than `accept`, `hold`, or `refuse`, or when the
server-managed settings cache (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/remote-settings.json`) exists;
a session that cannot ask ends naming the launch line. The first message's
delivery notice still stops the run on a value the read missed (see Known
behavior).

**The `## Autopilot` section.** The batch's settings are the last section
of the brief (after `## Discovery Notes`) or of the spec: a bullet list of
`- <Label>: <value>` fields, in any order, labels in English whatever the
document's language. Every field has a default and none is required; the
run writes its effective settings in one line before the first launch —
into the state file, and, in an interactive main session, into its reply —
and names any label it does not know. The run reads the section once, at
the start, and keeps those values: a worker's later edit to it — a review
fix that adds acceptance cases, say — changes nothing for the run, and the
reviewer report's `Settings edits` line lists it for you to carry into a
later run or not. A known label written with a note,
`- <Label> (<note>): <value>`, reads as the label: the note of
`Acceptance (in the order listed, …):` becomes a `Run notes:` line in the
acceptance session's prompt, and any other field's note is named on the
line after the settings line; an unknown label with a note is still
ignored and named. The seventeen labels and their defaults:

- `Baseline:` a commit (a SHA, or `HEAD`) — HEAD at the start of the run
- `Mode:` `repo` or `plugin` — detected from the layout (a
  `.claude-plugin/marketplace.json` plus a `plugins/*/.claude-plugin/plugin.json`
  means `plugin`), else `repo`; the field wins over the detection
- `Plugin:` a plugin directory name under `plugins/`, for a marketplace
  with several — unset
- `Version:` `none`, or a version string — `none`
- `Budget:` `USD <n>` — `USD 200`
- `Caps:` `<n> sessions, <m> resumes` — `16 sessions, 8 resumes`
- `Allowed files:` paths, one per line or comma-separated — empty
- `Zero diff:` paths the batch promises not to touch — empty, no check
- `Byte-identity exceptions:` free text — empty
- `Acceptance:` `none`, or one sub-bullet per case: a command or a case
  description, its PASS criterion after ` — PASS: `, and `(optional)` at the
  end of a case that may be cut — `none`
- `Acceptance record:` a path the S4 results are written to (repo mode) —
  unset, nothing written into the repository
- `Release preparation:` `default`, `keep`, or sub-bullets of instructions
  — `default`
- `Must read:` paths every worker reads first — empty
- `Challenge seeds:` sub-bullets the design session argues against — empty
- `Prior specs:` `<hash>^:<path>` entries, read with `git show` — empty
- `Workspace:` a directory — `~/Projects/_smoke/`
- `Role settings:` one sub-bullet per role, `- <role>: model <model>[, effort <level>]`
  or `- <role>: effort <level>`, where `<role>` is one of `S1`, `S2`, `S3`,
  `S3b`, `S4`, `S5`, `S6`, `<model>` is one token with no whitespace and no
  comma, passed to `--model` as written, and `<level>` is one of `low`,
  `medium`, `high`, `xhigh`, `max` — empty, every role at the pass-through
  values; a role that declares only a model, or only an effort, takes the
  pass-through value for the part it leaves out

  For example, at the end of a brief:

  ```
  ## Autopilot
  - Baseline: HEAD
  - Mode: repo
  - Budget: USD 60
  - Acceptance:
    - npm test — PASS: exit 0
    - npm run typecheck — PASS: exit 0 (optional)
  - Release preparation: default
  ```

**Models and efforts.** A worker does not follow your session's model and
effort: each is its own `claude -p` process, and without `--model` and
`--effort` it resolves both from its own settings. So every launch passes
the role's values — the ones `Role settings:` declares, and, for a role
the field does not name or the part a role's entry leaves out, the
pass-through values: the model and effort your session runs at when the
run starts, the effort from `$CLAUDE_EFFORT` and the model from your
session's own transcript, looked up by its session id under
`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects` — Claude Code keeps its
transcripts under `CLAUDE_CONFIG_DIR` when that is set, and a lookup
under `~/.claude` alone would then find none, leaving every undeclared
role at its settings' model. A pass-through value that cannot be read is not
passed and is recorded as `not determined`; that part of the worker then
comes from its own settings. The plugin ships no default per role and
names no model: the declarations are the spec's. Two settings stop the
run before the first launch: a `Role settings` entry outside its grammar —
an unknown role, a role named twice, or a part that does not match, named
with the value that failed (`- S3: effort extreme` names `extreme`) — and
`CLAUDE_CODE_EFFORT_LEVEL` set in your session's environment while a role
declares an effort, since that variable takes precedence over `--effort`
and every worker inherits it.

The settings line ends with the roles and the pass-through values,
`…, wait <interactive|headless>, roles <S2 <model>/<effort>; …|none declared>, pass-through <model|not determined>/<effort|not determined>`,
a role's undeclared part written `—`. After each worker exits, the run
reads the model and effort it actually ran at from its transcript — found
by the session id in `<tag>.session` under the same root, its main-loop
records only — and
writes one line per worker into the state file:

```
<tag> requested <model|—>/<effort|—> (<declared|pass-through>) applied <model|not observed>/<effort|—|not observed>[ MISMATCH: <what>]
```

The model matches when the applied model ID contains the requested value,
compared without regard to case once a trailing `[...]` is removed from
the requested value; the effort matches when it equals the requested value,
and a record with no effort field is the mismatch `effort not applied`
when an effort was requested,
its applied effort written `—`: in the applied part `—` means the records
carry no effort field, while in a requested part it means no flag was
passed.
Every main-loop record counts except the ones Claude Code writes for an
API error — `message.model` `<synthetic>`, or `isApiErrorMessage` `true` — which
the pass-through read skips too: they are the harness's own, not a
model's response, and carry no effort field, so counted they would mark a
worker that hit one dropped connection as a mismatch. Several values are
joined with `+`, and a resume's line covers the whole session. A mismatch
is marked, never a stop; a transcript the run cannot find or read, a
session left with only those API-error records, or a model it cannot
read, is `not observed`, which takes no `MISMATCH:` and is not counted as
a mismatch. The reviewer report's `Models and efforts` line,
`<n> workers, <k> mismatches, <j> not observed`
(`<n> workers, mismatches: none, <j> not observed` when there are
none), gives the number of workers, of mismatches, and of workers not
observed, with these lines under it, so a run in which no transcript
could be read does not read like one in which every worker was verified.

**The workspace.** Everything the run keeps outside the repository lives
under `~/Projects/_smoke/` by default, or the directory `Workspace:` names:

```
<workspace>/
    _prompts/      the copied driver <batch>-run.sh, the preamble, the task blocks, the assembled prompts
    _logs/         <tag>.json  <tag>.err  <tag>.pid  <tag>.exit  <tag>.session
                   <batch>-timeline.log  <batch>-costs.txt  <batch>-state.md  <batch>-report.md
    <batch>-*      seed projects (plugin mode)
    .trash/        discarded directories, moved here as <name>-<timestamp>/ — nothing is removed with a recursive rm
```

`<tag>.exit`, written by the driver when a worker returns, is the
completion artifact: the idle notice only wakes the main session, which
then reads the file. `<batch>-state.md` is rewritten at every transition
and re-read on every wake, so a long batch continues from what is on disk.
`<batch>-costs.txt` holds one line per session with its last cumulative
`total_cost_usd`. An interactive main session also prints the settings
line and each `S<n> started —` and `S<n> returned —` line in its reply; in
a headless main session (`wait headless` on the settings line) the state
file and the timeline are the record, and nothing is required of the
reply, which nothing downstream reads — the release checklist reads the
state file and the timeline.

**The rails.** Every worker's prompt carries the same safety rails. A
worker writes only to the repository, the workspace, `$TMPDIR`, and the
harness's per-session scratchpad. A write elsewhere under `/tmp` (on
macOS `/private/tmp`) that holds no secret is not a breach: the worker
lists it under `## Rail observations` in its final message and goes on,
together with each rail observation a subagent of its reports, naming the
subagent, and the main session records it in the state file and on the
reviewer report's `Rail observations` line — `<tag>: not read (<reason>)`
for a worker that left no result to read, which `none` would misreport as
a worker that wrote nowhere else. Any other write outside those places
is a breach, and so is a recursive `rm` in any spelling, wherever it
points: a worker discards by `mv` into the workspace's
`.trash/<name>-<timestamp>/` and deletes inside the repository only
through `git rm`. No `git push`, `git tag`, or release; no resource the
brief does not name; no secrets. The rails govern what a worker or a
subagent writes — its own commands and tool calls: a program it runs that
removes a temporary directory it created itself (a guard's or a test
script's `mktemp` cleanup), or writes its own cache, is not a breach,
while a recursive delete the agent writes, in any language (`rm -r`,
`find -delete`, a Python `shutil.rmtree`), still is. A script or program
the worker writes during the run and then runs — a helper in scratch,
`$TMPDIR`, or the workspace — is its own writing, so a recursive delete in
it is a breach as if typed, while the code the batch implements and its
tests, run as the project runs them, stay a program it runs. Reaching an
effect the rails hook denied by another spelling — another command,
another tool, a script — other than the route the denial names is a
breach. A worker that lists its environment
prints variable names only, never values, with `bash -c 'compgen -e'`,
since `env` cut at the `=` still prints the further lines of a multi-line
value. A worker's subagents
never see its prompt, so the rails tell the worker to write them into
every subagent prompt it composes and into the `CUSTOM_INSTRUCTIONS` of the agent
dispatches its skills make. A dispatch that has no such key —
task-implementer's, and the three document reviewers' — carries no rails
text: for those agents the hook's two rails below are the only ones
enforced, and a write of theirs through Bash is neither denied nor listed
under `Rail observations`. Beside the text, the plugin's rails hook
enforces two of them: the driver marks each worker it starts
(`KENSPC_AUTOPILOT_WORKER=1`) and passes its write roots
(`KENSPC_AUTOPILOT_WRITE_ROOTS`: the worker's repository, the workspace,
`$TMPDIR`, `/tmp`, and `/private/tmp`, joined by `|`), and a PreToolUse
hook on Bash, Write, Edit, and NotebookEdit denies, in a marked worker
only, a Bash command that runs a recursive `rm` and a file-tool write
outside the roots — in the worker's own calls and its subagents' alike,
since a plugin hook fires for a subagent's tool call too. The deny's
reason names the rail and the permitted route. A call the hook denied is
not a breach, since it never ran: the worker takes the route the deny
names, lists the denial under `## Rail observations`, naming the subagent
that made the call, and goes on. A denial whose reason says a field of
the hook input could not be read — the tool name, a Bash command, or a
file-tool target — names no route, since the hook reads every later call
the same way: it is not a breach either, and the worker lists it with the
hook's reason quoted as printed and ends, which puts a field a Claude Code release renamed in
front of the main session at once: at that worker's return, an entry whose
denial reason contains `could not be read from the hook input` stops the
run, naming the field and the output of `claude --version`, since every
later worker would end the same way. A denial in task-implementer or a
document reviewer, whose dispatch carries no rails text, is not listed:
a worker sees only a subagent's reply, not its tool results. The hook is
a best-effort guard (see Known behavior), and the rails text still binds.

**What a run writes and commits.** In `repo` mode: the workers' commits
(the task document, the implementation, the review's fixes) and, with
`Release preparation: default`, one removal commit,
`docs: remove batch <name> plan and tasks`, that `git rm`s the batch's plan
and task documents and touches no version and no CHANGELOG (`keep` leaves
them; a list of instructions runs after the removal). In `plugin` mode: the
same, plus the acceptance record `docs/dry-runs/<batch>-acceptance.md` and
the repository's release commit — the CHANGELOG heading dated, the manifest
at `Version:`, the checklist and roadmap updated, the batch's documents
removed, the pre-flight run — with no tag and no push. At brief entry the
design session commits the spec alone, `docs(plans): add batch <name> spec`,
and the main session commits each ruling made during the run into the
spec's clarifications section, each entry naming who ruled
(`docs(plans): record clarifications settled after <step>`). Nothing is pushed, tagged, or released.

**The two gates.** The run stops for you at the decisions on a brief's
design table (a supplied spec counts as approved) and at the tag, push, and
release after the reports, and otherwise only on a stop condition. Phase
0's questions about the run's inputs — no path, the entry kind, which
plugin, an inbound setting it cannot read — are asked before the first
launch, as part of the start. Every other point the spec leaves open is
the main session's to rule: a worker's question, a choice riding on a
task-list confirmation, a question it raises itself, a review row's or an
acceptance FAIL's classification, a deferred row's route, and a corrected
acceptance case. It answers a waiting worker at once and rules the same
way whether or not it can ask you, by this order: the spec's words; the
locked design; the project's instruction files and the patterns in
adjacent code; then the option easiest to reverse and closest to the
spec's scope. A worker's suggested answer is evidence, not a default, and
the main session never stops for a preference between options that all
stay inside the batch's contract. A ruling may depart from a sentence of
the spec — never a locked point — when evidence shows the sentence wrong
(a test, a probe, a reviewer's reproduction, a documented tool behavior);
the clarification names the evidence, and the reviewer report lists the
ruling as beyond the letter. A worker never rules itself: it asks the main
session, which records every answer, while an answer a worker decided
would be recorded nowhere.

S2's task-list confirmation is answered `yes` when the list matches the
spec's steps, "add a task for <step>" for a step with no task, and "drop
<task>" for a task outside the spec unless a spec step needs it; a type,
a shape, a name, or a behavior the worker proposes to pin, however it
frames it, is ruled by the main session and recorded. A gate a worker
skips is checked afterwards, not prevented: an S2 that returns without
having sent its confirmation question has its committed task document
checked with the same rubric. A match, or rulings the document already
follows, is accepted and recorded as a behavior deviation; a mismatch, or
an open choice ruled otherwise than the document has it, resumes S2 with
the ruling to amend and commit the document, and the check runs again —
a second failure is a stop. An S3 that skipped task-implement's batch
gate is recorded only, since its answer is yes once S2's list has passed.
No role gets an effort floor: it would be a plugin default, and it would
not catch a skip at any effort. The reviewer report's `Skipped gates`
line lists each skip with its step, tag, and outcome.

A question the main session raises itself that it cannot rule on — a way
forward only you can decide, of the kind the stops below name — and that
only a later step needs does not stop the run where it arises: it is recorded as open for that
step, the steps before it go on, and it becomes the stop only when that
step is due and you have not answered it.

**A corrected acceptance case.** An `Acceptance:` case broken for a reason
outside the batch's work — a flag the package manager reads instead of
the test runner, a failure word that matches a log line, a summary line
the installed tool does not print — may be run in a corrected form the
main session rules, when it has both pieces of evidence: the case as
written fails, or passes vacuously, at the baseline or by a named tool
behavior it ran, and the corrected form passes unbroken and then fails on
a deliberate break of what the case checks. It gathers both in a clone
under `$TMPDIR` or the workspace, with the case's setup (dependencies,
build output) restored there, never in your working tree. The ruling is a clarification
carrying the case, the corrected form, and both pieces of evidence; the
`## Autopilot` section stays as the run read it, the acceptance session
runs the corrected form, and the reviewer report's acceptance line says
`in the corrected form (<clarification>)`. Without both pieces of
evidence, the correction is a stop.

**The record.** Every ruling is recorded four ways: a
`questions answered:` line in the state file ending with who ruled,
`(main session)` or `(user)`; a clarification entry in the spec that names
who ruled; the reviewer report's `Main-session rulings` line, with one
line per ruling — its clarification, the tag or step, the question, the
ruling, the reason, and the commits it produced; and a list in the user
report, one line per ruling in your language, under a heading that says
they are for you to review before the tag and the push — a list the
report's one-page limit does not count. Actions that would leave the
machine and that the run does not need in order to go on — filing an
issue, adding a backlog item — are never taken and never asked mid-run:
the reviewer report's `Follow-up candidates` line lists them, with the
findings a ruling deferred to a follow-up, for you to decide after the
reports.

**Fixes.** A defect the main session classifies — a review row after S3b,
or an acceptance FAIL — goes to an S5 fix session. One S5 may fix several
defects classified in the same round, one commit per defect. Every S5 is
followed by a narrowed review (`-s3c`, then `-s3d`, …) over the range from
HEAD at its first launch to its last commit, a wording-only fix included, before
any acceptance case is re-run. A defect an S5 leaves without a commit still
stands, whatever that review says, and goes to the next S5, counted as a
fix of it.

**Stops.** Reopening a locked design point; a forbidden section or file
touched; guards red twice in a row; the same defect still failing after
two fixes of it, counted per defect; the session cap, the resume cap, or
the budget exceeded (a question with the numbers); a safety-rail breach
(see The rails: a write outside the repository, the workspace, `$TMPDIR`,
the scratchpad, and `/tmp`; a recursive `rm` in any spelling — `rm -r`,
`rm -rf`, `rm -fr`, `rm -R`; a `git push`, `git tag`, or release; a
resource the brief does not name; a secret); a way forward the main
session cannot rule on — every option changes the batch's contract (a new
dependency, an API contract change, a database schema or configuration
change the spec does not name, a file outside `Allowed files:` or on the
zero-diff list) and none stays inside it, or an acceptance case corrected
without both pieces of evidence; a nested `claude -p` refused; the same
step's session dead twice; a settings stop before the first launch, among
them a `Role settings` entry outside its grammar and
`CLAUDE_CODE_EFFORT_LEVEL` set while a role declares an effort (see Models
and efforts); and a worker that ended on a denial whose reason says a
field of the hook input could not be read (see The rails). When one
option stays inside the contract — defer to a follow-up, leave as is — the
main session takes it and records it instead of asking, and a ruling to
leave a locked point as it stands and record the finding as a follow-up
is its own, not a stop. Five stops are stated at their own steps: a driver
that refuses a launch, a delivery notice that the first message to a
worker was held or refused, an artifact absent after a return, an unmarked
acceptance case that cannot be run, and the skipped-gate check failing a
second time. Every stop
ends the final message with `Autopilot stopped: <reason>`; the state file
holds the next action.

**Budget.** `USD 200` by default, `16 sessions, 8 resumes` as caps. Before
each launch the run checks spent (the sum of the sessions' last cumulative
costs and, in `plugin` mode, the acceptance cases' costs from the record)
plus projected (the largest session so far, or budget ÷ 6 before the
first) against the budget and asks "raise the budget to how much?" when it
would be exceeded; every worker is started with `--max-budget-usd` set to
the remaining amount, so a runaway session cannot spend past the batch. A
worker ended by its cap is resumed once you raise the budget, with the new
remaining amount as its cap: the ended session's last cumulative total is
already in spent, and the cap bounds only what the resumed session spends
from there — a probe with a resumed session showed `--max-budget-usd`
counts the invocation's own spend, not the session's earlier total. Acceptance
cases marked `(optional)` may be cut when the budget check fails;
implementation is never narrowed.

**The reports.** The final message carries `## User report` — your
language, at most one page: what the batch built, the release commit, what
needs you, the cost, then the main session's rulings for you to review
before the tag and the push, which the page limit does not count — and
`## Reviewer report` — English, fixed fields: batch and mode; baseline →
release hash; the spec's `git show` command; design rulings and
clarifications with the decisions that read the locked design beyond its
letter and the rulings that departed from a spec sentence on evidence;
main-session rulings, `<n> | none` with one line per ruling; settings edits, each field a worker changed in
the `## Autopilot` section; files changed and the zero-diff result;
byte-identity / guards / counts; acceptance, one line per case with its
cost and result, and `in the corrected form (<clarification>)` for a
corrected case; models and efforts,
`<n> workers, <k> mismatches, <j> not observed`
(`<n> workers, mismatches: none, <j> not observed` when there are
none) with one line per worker; total cost; Not exercised; rail
observations; skipped gates; follow-up candidates; release-preparation
state;
sessions / messages / resumes / stops. The total-cost line is the measured
sum of the workers' last cumulative `total_cost_usd`, plus in `plugin` mode
the acceptance cases' costs from the record (S4's nested sessions), plus
the main session's own cost as an estimate, labeled so: its turn count × the mean
cost per turn across the batch's workers, the basis stated on the line
(`/cost` in your session replaces it). The reviewer report is also written
to `_logs/<batch>-report.md`, and the final message ends with
`Autopilot finished — <baseline sha>..<last sha>`.

**The drivers.** `run.sh` (`skills/autopilot/scripts/run.sh`) ships with the
skill and is copied per batch to `_prompts/<batch>-run.sh`; it starts each
worker with `--name <tag>`, `--settings '{"crossSessionInbound":"accept"}'`,
`--permission-mode bypassPermissions`, `--output-format json`, a session id
written to `<tag>.session` before the process starts, and — when the
command exists — wrapped in `caffeinate -i`, so a macOS machine does not
sleep under a running worker while the main session waits with no Bash
call running. It passes `--model` when `AUTOPILOT_MODEL` is non-empty,
`--effort` when `AUTOPILOT_EFFORT` is, and `--plugin-dir` when
`AUTOPILOT_PLUGIN_DIR` is, on a fresh launch and on a resume alike, since
a resume keeps the model but not the effort; the empty string counts as
unset. The skill sets all three on every launch — the model and the effort
empty where no value is known, the plugin directory in `plugin` mode and
the empty string in `repo` mode — since a variable of the same name
inherited from your session would otherwise reach the driver. Every
launch also sets `AUTOPILOT_WORKSPACE` to the workspace's absolute path
(the driver refuses a relative one, which the rails hook would skip as a
root), and the driver exports
`KENSPC_AUTOPILOT_WORKER=1` and `KENSPC_AUTOPILOT_WRITE_ROOTS` to every
worker, fresh or resumed, over any value your session holds (see The
rails). S4's nested acceptance sessions take S4's model and effort
through the environment, since the driver copy S4 runs reads the same two
variables, and every nested launch sets `AUTOPILOT_PLUGIN_DIR` on its own
line. `run.sh --self-test` launches a stub through the same path
and prints `self-test passed` (it needs git, for a repository it creates
to check the write roots); the run executes the copy's self-test at
every batch start. The timeline's two lines, `start <tag> pid <pid> …` and
`end   <tag> exit <status>`, begin at column 0 with no timestamp: the launch
time is in the start line's tail, and a worker's end time is the mtime of
its `<tag>.exit`. A driver that mirrors `run.sh` keeps that shape, since the
release checklist greps for the lines as they stand.

`run.ps1`, beside `run.sh` in the same directory, is its PowerShell mirror.
It has the same interface, environment variables, files, timeline lines,
and refusals, and also
refuses a logs directory or tag holding `[`, `]`, `*`, or `?`, which
`Start-Process` cannot redirect to. It runs under PowerShell 7.3 or later
as
`pwsh -NoProfile -File <path>/run.ps1 <tag> <cwd> <prompt-file> [--resume <session-id>]`;
7.0 to 7.2 drop the double quotes inside the arguments they pass to the
worker, which would break its `--settings` JSON and its prompt.
Its `pwsh -NoProfile -File <path>/run.ps1 --self-test` launches a
`claude.ps1` stub, put first on a temporary PATH entry, through the same
path and prints `self-test passed`. On macOS and Linux it also launches a
native `#!/bin/sh` stub, as the installed `claude` is a native program, and
compares the `-p` and `--settings` values that stub receives, byte for
byte, with a prompt that holds double quotes and with the settings JSON.

It starts the worker with `Start-Process pwsh`, and the inner command
travels base64-encoded with `-EncodedCommand`, so a path that holds a space
or a single quote arrives unchanged. On Windows the window is hidden. The
prompt is read from the file with `Get-Content -Raw`, as `run.sh` reads it
with `cat`. The files it writes and its `started` line end with LF, with no
byte-order mark, on every platform, so they read as `run.sh`'s do.

The launched pwsh's own standard streams go to three more files in the
logs directory: `<tag>.launch.in`, `<tag>.launch.out`, and
`<tag>.launch.err`. Without that redirection, a caller that reads the
launch through a pipe would wait for the worker to exit instead of getting
the `started` line at once.

`run.ps1` is checked on macOS only: a parse and its self-test. There the
launched process is attached to the launching shell, with no hang-up
protection. `Start-Process` also copies the launch streams through the
driver's own process on macOS, so the two output files keep nothing
written after the driver returns; the inner command also writes its own
failure reason to `<tag>.err`, and `<tag>.exit` then reads 1. The skill
copies and runs `run.sh`, and
nothing picks a driver by platform until `run.ps1` has passed acceptance
on Windows.

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
  `/kenspc-task-review`, `/kenspc-task-implement` after you confirm the
  batch, and `/kenspc-diagnose` when it probes make that commit on their
  first run in a repository that does not yet ignore `.kenspc/`. Commit or stash your
  `.gitignore` edits first, or split that commit afterwards.
  `/kenspc-init`'s documentation commit likewise carries the whole of a
  `.gitignore` it appended to, or a CLAUDE.md it gave the import line,
  with any uncommitted edit of yours in it; its file list names each such
  file before you confirm, and a session that cannot ask leaves it out of
  the commit.
- **Regressions and deferred issues in the verdict.** The verdict is FAIL
  when the fixes "introduced unresolved regressions", whatever a
  regression's severity, while "MEDIUM and LOW issues do not change the
  verdict but appear in the report." The asymmetry is deliberate: a
  regression is damage the review's own fixes did to code that worked before
  them, which the run's own changes caused and a revert of those fixes
  undoes; a deferred MEDIUM or LOW issue was in the reviewed code before any
  fix, is reported with its reason, and is yours to schedule. On regressions
  the verdict is not graded by severity, by decision: a LOW regression fails
  the run as a HIGH one does.
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
- **Branches.** The plugin does not create branches; the one branch it
  names is the first branch of a repository `/kenspc-init` creates with
  `git init`, which is `main`. Commits follow the
  branching rules in your project's instruction files and otherwise land on the
  current branch. The plugin takes no side on branching: whether to branch is
  decided at plan time, when you approve the plan. `task-document-reviewer`
  fixes a branch step the plan did not prescribe, or that your project's
  instruction files contradict, back to the default and records a
  Plan-Level Concern;
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
  the app goes into the app. Its location comes from your project's
  instruction files or from you; the project's typecheck runs before
  building as a baseline and again
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
  is left as it was, gaining at most a `Settled by:` line), and widening
  the in-app exception to features is your decision.
- **One tool call per wait iteration.** A headless autopilot, and any
  worker waiting for an answer, waits in a bounded `until` loop of about a
  minute per Bash call (`sleep 2`, thirty times), because the Bash tool
  blocks a bare `sleep` of thirty seconds or more and refuses chained short
  sleeps; the loop is the form the tool's own message recommends. A
  thirty-minute wait is therefore about thirty tool calls. The interactive
  main session avoids them by subscribing to the worker's idle notice and
  ending its turn.
- **A headless subscriber gets the idle notice as an extra turn.** A
  `claude -p` session that subscribes to a worker with `notify_when_idle`
  does not receive the notice between its tool calls: it arrives as a new
  turn after the session's final reply, and the session's JSON `result`
  then becomes that turn's last message. So a headless autopilot never
  subscribes and polls `<tag>.exit` instead — its settings line reads
  `wait headless` — and only an interactive main session subscribes.
- **Sessions that share a name.** The rename Claude Code applies to a
  duplicate session name does not check the `--name` of a `-p` session at
  startup, so an earlier batch's worker still running, or a resumed session,
  can share a tag's name. The skill runs `ListAgents` before each send and,
  when two rows carry the name, addresses the one whose start time matches
  the launch by its `[ref]`.
- **Hook sessions and hook files in seeds.** A user-level hook that starts
  its own `claude -p` (a SessionEnd hook, for example) shares the trace
  directory with the batch's sessions and may write files into a seed
  project. The skill records such a session as an observation, counts it
  neither as cost nor as the run's change, and lists a hook's files in a
  seed under the acceptance record's Observations.
- **The twelve-hour subscription expiry.** An idle-notice subscription that
  gets no notice within twelve hours is dropped, and the notice that reports
  it is a wake like any other: the skill re-checks `<tag>.exit` and, with
  the pid still live, subscribes again. A worker that runs longer than that
  is not judged hung; a live pid is never killed.
- **Message limits.** A message over about a million characters is refused,
  a burst of about thirty sends to one session is refused, and a receiver
  queues at most fifty messages and drops identical repeats. Messages
  between the main session and the workers carry summaries and paths, never
  a report's text; a worker with a table to show writes it to a file and
  sends the path.
- **Stricter inbound settings.** `crossSessionInbound` is read from managed
  settings, then the `--settings` flag, then user settings, and a project or
  local setting of `hold` or `refuse` applies over the workers' `--settings`
  accept when it is stricter. No probe message is sent at the start, so a
  held or refused first message shows as a delivery notice on that message;
  the skill stops there, naming the precedence. The start check that reads
  the settings files cannot read settings delivered from a server: it asks
  about them only when the server-managed settings cache,
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/remote-settings.json`, exists, and
  counts them absent otherwise — a non-interactive run does not write that
  cache for settings that need approval — so the delivery notice is the
  backstop. A managed source the platform exposes somewhere the check does
  not read is caught the same way. A worker whose question is
  held runs into its thirty-minute wait and stops with the question in its
  final message, and the skill resumes it with the answer.
- **A main-session ruling can be wrong.** The autopilot's main session
  rules every point the spec leaves open, except the stop conditions,
  without asking you, and a ruling can be one you would not have made. Each
  is a committed clarification in the spec that names who ruled, a line on
  the reviewer report's `Main-session rulings`, and a line in the user
  report's list; review them before the tag and the push, since nothing
  leaves the machine before you do. A ruling that departed from a spec
  sentence is also on the reviewer report's beyond-the-letter list, with
  its evidence named in the clarification. The batch's contract — a new
  dependency, an API or schema change, a file outside `Allowed files:` —
  and the locked design stay yours: a way forward that needs either is a
  stop.
- **The first worker always passes the budget check.** Before the first
  worker the batch has no session cost to project from, so the check
  takes a sixth of the budget as the projected cost and 0 as spent; their
  sum never exceeds the budget, and the first worker always starts. Its
  `--max-budget-usd` cap is the whole budget, which bounds what it can
  spend. A budget too small for the batch therefore stops the run at the
  earliest before the second worker, never before the first — the cap ends
  a first worker that reaches it, and the check before each later launch
  catches the rest — with spent and projected on the stop and the question
  of how much to raise the budget to.
- **A headless main session's record is the state file and the
  timeline.** An interactive main session prints the settings line and
  each launch and return line in its reply. Since 4.3.0 a headless one is
  not required to: headless runs under the earlier instruction to print
  them wrote the settings line only into the state file and left return
  lines unprinted, and nothing downstream reads a headless reply. The same
  facts are on disk either way: the settings line in `<batch>-state.md`,
  and each launch and return as the driver's `start` and `end` lines in
  `<batch>-timeline.log`, each `end` line written together with
  `<tag>.exit`. The release checklist reads them there.
- **The rails hook is a best-effort guard.** In an autopilot worker — a
  session the driver marked with `KENSPC_AUTOPILOT_WORKER=1` — the hook
  denies a recursive `rm` at a command position and a Write, Edit, or
  NotebookEdit outside the write roots. A denied call is a rail
  observation, not a breach: the worker takes the route the deny's reason
  names, lists the denial, naming the subagent that made the call, and
  goes on. A denial in task-implementer or a document reviewer, whose
  dispatch carries no rails text, is not listed: a worker sees only a
  subagent's reply, not its tool results. The hook misses `find -delete` (and
  `find -exec rm`), `bash -c '…'`, a script fed to a shell on stdin
  (`bash <<EOF`), `eval`, and a `trap` body
  (`trap 'rm -rf "$d"' EXIT`), interpreter-level deletes
  (Python, Node, Perl), `git clean`, and writes through Bash (redirections,
  `cp`, `mv`, `tee`); also an `rm` reached through a variable or an alias,
  or spelled through the escapes of `$'…'` (`$'\x72m'`),
  an `rm` after a redirection written before the command name
  (`2>/dev/null rm -rf d`),
  a two-character token split by a line continuation (`&\<newline>>`, `$\<newline>'`, `$\<newline>(`, a heredoc operator or delimiter),
  other wrappers such as `timeout`, and paths that are not POSIX absolute,
  which it does not judge; and a Write or Edit whose target is itself a
  symbolic link pointing outside the roots, since it resolves only the
  links of the target's ancestors. The rails text in the worker's prompt still
  binds for all of these. The other way round, a call whose fields the
  hook cannot read from its input — the tool's name, a Bash call's
  command, or a file-tool call's target — is denied in a marked worker,
  with a reason saying so: were a Claude Code release to rename one of
  them, a worker's calls would stop loudly rather than pass unchecked: a
  renamed tool name would stop every call of every worker, and a renamed
  command every Bash call. That reason names no route and asks for the
  denial to be reported: it is not a breach, and the worker lists it with
  its reason under `## Rail observations` and ends, rather than going on
  to retry, until its cap, calls the hook denies the same way.
  A Bash call whose hook input is over 64 KB is denied unscanned, with a
  reason saying so: the scan's time grows with the square of the
  command's length, and a hook run that outlasts its 5-second timeout
  denies nothing; long content goes through the Write tool.
  The release checklist's live hook row is where such a change shows
  before a release: `check-autopilot-rails-hook.sh` replays a copy of the
  input as Claude Code 2.1.283 sent it, which a later format would not
  match. Outside a marked worker the hook reads one
  variable and exits with no output, but it starts on every Bash, Write,
  Edit, and NotebookEdit call of every session with the plugin enabled.
  Whether a worker that `run.ps1` starts on Windows can run the bash hook
  at all has not been probed.
- **A role's model reaches every subagent of its worker.** The plugin's
  agents declare `model: inherit`, which resolves to the model of the
  session that dispatches them, so inside an autopilot worker it is the
  worker's own model. A role's model, declared or passed through, is
  therefore also the model of every subagent that worker dispatches — the
  task document reviewer under S2, and the implementer, the five
  reviewers, the fixer, and the verifier under S3 and S3b.
- **Agents with their own effort keep it.** An agent whose frontmatter
  sets its own effort — `task-implementer` and `code-fixer`, at `high` —
  runs at that effort whatever the role's effort; a role's effort sets the
  worker's own, and that of the subagents without an `effort:` field.
- **Fable in a headless worker can spend usage credits without asking.**
  In `-p` mode, when a Fable request counts against usage credits, Claude
  Code charges it without a prompt. On a Max plan that happens once the
  weekly Fable share — up to 50% of the weekly usage limit, at no extra
  charge — is used up; on a plan where Fable needs usage credits, it
  happens on every request. A worker can run Fable whether a role declares
  it or passes it through, and when your session runs Fable, every role
  without a declared model runs Fable too.
- **The applied model and effort come from an undocumented format.** The
  run reads what a worker ran at from fields of its transcript that Claude
  Code does not document. A transcript it cannot find or read, or a
  model it cannot read, is recorded as `not observed`, and the run goes
  on. A record with no effort field is the counted mismatch
  `effort not applied` when an effort was requested
  instead — a model without effort support writes
  none, and so would a Claude Code release that dropped the field. A
  mismatch is marked in the state file and the reviewer report, never a
  stop.
- **A passed-through model loses its context-size suffix.** The model ID
  in a transcript carries no context-size suffix, so when your session
  runs `<model>[1m]`, a role without a declared model is launched with
  `--model <model>` and may run at the standard context window, while its
  state line shows a match. A role that needs the larger window declares
  it — `- S3: model <model>[1m]` — and the model check removes a trailing
  `[...]` from the requested value before it compares, so the suffix is
  no mismatch.
- **The model check can misjudge both ways.** The applied model matches
  when its ID contains the requested value, a comparison of text: the
  transcript records the ID that served the request, not the value the
  role declared. So a declared ID that is a prefix of the served one — a
  declared `<id>` against a served `<id>-<suffix>` — reads as a match
  although another model ran, and an alias that no served ID contains
  reads as `MISMATCH: model` whichever model it resolved to. A role that
  needs certainty declares a full model ID.
- **An existing CLAUDE.md.** `/kenspc-init` does not rewrite a CLAUDE.md
  you already have, at the root or in `.claude/`. On your yes it adds one
  line, the import (`@AGENTS.md`; `@../AGENTS.md` from `.claude/CLAUDE.md`),
  at the top and leaves the rest byte for byte, then reports the two files'
  combined line count and any content they visibly repeat, for you to
  settle. For `.claude/CLAUDE.md` the question says Claude Code will ask you
  to approve the write. On a no, in a session that cannot ask, or when the
  write is not approved, the file stays as it is, a Documents row the skill
  writes for it says what it holds and that it does not import AGENTS.md,
  and the final message gives the same line count and says
  when Claude Code loads AGENTS.md without the import: only in the
  `claude-md-and-agents-md` mode of its `instructionFiles` setting, on
  v2.1.277 or later with the built-in agents-md plugin enabled — in the
  default mode a CLAUDE.md stops it — and where both files load, what they
  repeat takes up context twice. When CLAUDE.md already has the import —
  on a line of its own, or inside a sentence outside a code span with
  whitespace or the line's start or end on each side (Claude Code imports
  neither `@AGENTS.md.` nor `(@AGENTS.md)`) — or is a
  symbolic link to AGENTS.md (or the reverse), AGENTS.md already loads:
  the skill asks nothing and leaves CLAUDE.md alone. Claude Code reading
  AGENTS.md on its own does not count, since it depends on the mode and the
  version. In a repository with an AGENTS.md and no CLAUDE.md,
  the skill still writes a CLAUDE.md that imports it, and the final message
  says why: once a CLAUDE.md exists, the default mode stops reading
  AGENTS.md on its own. The line budget is checked on
  the files the skill wrote, not on your CLAUDE.md, so the two together can
  exceed 80 lines and repeat each other — AGENTS.md may take commands and
  rules your CLAUDE.md already holds; the skill reports the count and the
  repetitions and trims neither file.
- **Generated documents are held to their sources.** An earlier version
  once put product claims its one-line description did not make into
  `docs/product.md`, and a later plan draft cited them as grounded there.
  Since 4.1.0 a check before the commit turns every topic-document sentence
  without a source that states what it claims — your answer, the
  description, or a file — into a `TBD(init):` marker naming what is
  missing, and lists each one in the final message. The check is
  the model's own reading, so read the topic documents once after
  `/kenspc-init`, before the first plan relies on them.
- **The stacks' plugins, in a monorepo and on a collaborator's machine.**
  Claude Code reads the shared `.claude/settings.json` from the directory a
  session starts in, not from the repository root, so a session started in
  `apps/<name>/` does not get the plugins `/kenspc-init` enabled at the
  root: start Claude Code at the root, where the rest of the kenspc workflow
  runs too. A committed entry turns a plugin on for a collaborator but does
  not download it, so each collaborator runs
  `claude plugin install <plugin>@<marketplace> --scope project` once —
  which, like the skill's own install, writes the file back in Claude
  Code's formatting and sets an entry's `false` to `true`. An LSP plugin
  also needs its language server on the PATH of the shell `claude` starts
  from; without it, the plugin can do nothing.
- **A skipped file list does not commit.** Skipping the file-list
  confirmation commits nothing, as a "no" does: the files stay in the
  working tree, and the final message says so. A session that cannot ask
  still commits after the checks.
- **Claude Code's built-in `/init` after `/kenspc-init`.** Do not run the
  built-in `/init` in a project `/kenspc-init` set up. It rewrites
  CLAUDE.md and carries AGENTS.md's content into it — by design with
  `CLAUDE_CODE_NEW_INIT=1`, and restated in its classic flow — and in the
  runs checked it dropped the kenspc pointer line; in a repository with
  only AGENTS.md, its classic flow wrote a CLAUDE.md without the import,
  which stops AGENTS.md from loading in the default mode. If you already
  ran it, delete what it copied from AGENTS.md, and check that the
  `@AGENTS.md` line and the kenspc pointer line are still in CLAUDE.md,
  adding back whichever is missing.
- **Commit messages follow your repository's convention.** Every commit
  the skills and agents make — task-implementer's and code-fixer's, the
  run directory's `.gitignore` commit, the document reviewers' baseline
  commits, diagnose-bug's, the prototype's, init-project's, and the
  autopilot's — is written in the convention your repository writes down
  (in the project's instruction files or its CONTRIBUTING) or, failing
  that, the pattern its recent commit subjects consistently share. The
  subjects this README names (`docs: add task <name>`,
  `docs(plans): add batch <name> spec`, …) are the defaults for a
  repository with neither, which gets conventional commits. Before 4.4.1,
  task-implementer and code-fixer always wrote conventional commits, and
  the autopilot gave its subjects as they stand, so a repository whose
  scopes are a fixed list got a `docs(plans):` subject outside it.
- **Missed-review telemetry.** The SessionEnd hook logs sessions that ran
  `/kenspc-task-implement` without a review to
  `~/.claude/kenspc/missed-reviews.log`. It finds the session's transcript
  under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects`, where Claude Code
  keeps transcripts when `CLAUDE_CONFIG_DIR` is set; the log stays under
  `~/.claude/kenspc` either way. It can log a false entry when a
  headless session runs several turns, when a session ends at a
  confirmation prompt, or when `/kenspc-task-implement` is given a task
  document with no TODO or IN PROGRESS task, which runs no review by
  design.

## Requirements

**Required:**
- Claude Code v2.1.0+ (the version line that supports the `effort:`
  frontmatter on SKILL.md and agent .md files; required for the three
  effort overrides listed under [Effort levels](#effort-levels)).
- `/kenspc-autopilot` needs `Claude Code v2.1.271 or later`: cross-session
  messaging, the idle-notice subscription (`notify_when_idle`), the own-name
  line of `ListAgents`, and notices to headless senders. The plugin's
  minimum above is unchanged — every other skill runs on it.

**Recommended:**
- `gh`, installed and logged in, for `/kenspc-init`'s GitHub step (creating
  a repository, reading and creating labels). Without it the skill gives
  the manual steps and keeps the backlog in files.
- The `claude` command on the PATH, for `/kenspc-init`'s plugin step.
  Without it the skill enables no plugin, and its final message says so.
- A session that allows a generous max-output-token budget —
  `generate-plan` runs at `xhigh`, the two unattended agents at `high`, and
  every other skill and agent at your session's effort, `xhigh` or `max`
  when you set it; the model needs room to think and act across its
  subagents and tool calls.

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
