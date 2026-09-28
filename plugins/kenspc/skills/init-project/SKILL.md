---
name: init-project
description: >
  Initialize a project for the kenspc workflow (初始化项目): scan the
  directory, interview the user in skippable rounds, optionally scaffold
  each app with its stack's official generator, and write AGENTS.md as the
  index, a CLAUDE.md that imports it, and the long-lived topic documents,
  marking what nobody answered TBD(init). Use for an empty directory, a
  directory about to become a project, or an existing repository that
  lacks these files. Not for questions about Claude Code's built-in /init
  or about what "init" means (answer directly), and not for a setup or
  deployment guide (use generate-guide). Trigger on: "initialize this
  project", "bootstrap a new project", "set up AGENTS.md and the project
  docs", "set up this repo for kenspc", "初始化项目", "建立项目文件",
  "帮我初始化这个项目", "新项目开个头", or invokes /kenspc-init directly.
version: 3.0.0
argument-hint: "[project description]"
---

# Init Project

Prepare a project for the kenspc workflow in one run — an empty directory,
a directory of files about to become a project, or an existing repository.
The run writes `AGENTS.md` as the index, a `CLAUDE.md` that imports it and
holds what is specific to Claude Code, and a set of long-lived topic
documents, from what the user answers in an interview and what a scan of
the directory shows. A user who answers nothing still gets every file, with
`TBD(init): <what is missing>` where an answer belongs. The files are sized
for a small team on a mid-sized project.

Eight phases: 0 Scan, 1 Git, 2 Interview (rounds 1–2), 3 Scaffold,
4 Interview (rounds 3–5), 5 GitHub and backlog, 6 Write, check, and commit,
7 Push and labels. No review phase — the files hold the user's answers and
`TBD(init):` markers, not a spec a reviewer could check them against; the
gate is the skill's own mechanical checks before the commit (§ Checks) and
the user's confirmation of the file list.

Why this order:
- Scaffolding comes before any document is written, so the commands in
  AGENTS.md are read from files that exist rather than asked or guessed.
- The GitHub step comes before the documents, because the backlog
  convention they record depends on whether a GitHub remote exists.
- The push comes last, so the first push carries the complete repository.

## Trigger Phrases

Use this skill when the user asks to **set up a project for the kenspc
workflow**, using phrases like: "initialize this project", "bootstrap a new
project", "set up AGENTS.md and the project docs", "set up this repo for
kenspc", "start a new project here", "初始化项目", "建立项目文件",
"帮我初始化这个项目", "新项目开个头", "把这个 repo 设置好给 kenspc 用",
or invokes `/kenspc-init` directly.

Avoid triggering this skill when the user:

- Asks about Claude Code's built-in `/init`, or what "init" means ("what
  does /init do", "init 是什么意思", "what does git init do") — answer
  directly, no skill needed.
- Asks for a setup, onboarding, or deployment guide — use generate-guide.
- Asks to plan a feature in a project that is already set up — use
  generate-plan, or generate-brief when the idea is still rough.
- Asks to split or reorganize an existing long CLAUDE.md, or to upgrade
  files an earlier template version wrote — this version does neither; say
  so and do nothing.

Why: the skill runs `git init`, can run generators and create a GitHub
repository, and commits, so a false trigger costs more than a missed one.

## Quality bar

A useful result has every file the run owes; each line in it is something
the user said, something a file in the directory shows, or a
`TBD(init):` marker naming what is missing; and its AGENTS.md holds only
what passes its admission rule, short enough to load in every session. It
fails the bar in three named ways: a policy the skill chose for the user
(a versioning scheme, a deployment method) written as if the team had
decided it; an AGENTS.md padded with what the code already says (a
directory tree, a dependency list); and a file of the user's overwritten.

## Prerequisites

- `git` on the PATH. Without it the run stops before writing anything and
  says so. Why: every start point is recognized through git, and the files
  are committed.
- Optional: `gh`, installed and logged in, for the GitHub step (Phase 5),
  and a stack's own tools, for scaffolding that stack (Phase 3). The skill
  installs neither.

## Arguments

$ARGUMENTS format: [DESCRIPTION]

- DESCRIPTION: optional free text about the project. Whatever it answers —
  a name, a one-line summary, the users, the stack, a policy — is not asked
  again.

With no arguments the interview asks as usual; it is not a stop.

## Language

- The interview is in the user's language.
- The files the run writes are in English, unless the user asks for another
  language. Why: they are read by coding agents and by team members who join
  later, and English is the language both are most likely to share. This
  default is for these files only: the plugin sets no default language for
  task documents, which generate-task still writes in its plan's language.
- The anchors stay exactly as written in any language: the `@AGENTS.md`
  line, the `kenspc-init template: 1` marker, the `TBD(init):` marker, the
  Documents table's header row, and the Workflow's `Version lives in` line.
  Why: a rerun and the checks find them by their exact text, and other
  kenspc skills read the Documents table by its columns.

## Phase 0: Scan and start point

**Goal**: the start point, and what the directory already tells.

**Inputs**: the directory's listing, hidden entries included;
`git rev-parse --is-inside-git-dir`, `git rev-parse --show-prefix`, and in a
repository `git symbolic-ref -q HEAD`; the stack's configuration files,
whatever the stack (a manifest or build file such as a `package.json`, a
`*.csproj` or `*.sln`, a `pyproject.toml`, a `go.mod`); the git remotes;
whether `gh` is installed and `gh auth status` succeeds; whether each
stack's own tools are on the PATH (for example `dotnet`, `node`); in a
repository, the project's instruction files, its README and CONTRIBUTING,
and the subjects of its recent commits; the DESCRIPTION. The project's
instruction files are its CLAUDE.md and AGENTS.md files — at the root, in
`.claude/`, or in a subdirectory — and the files a CLAUDE.md imports with
`@`, whether or not Claude Code loaded them in this session. In a
repository, note what
`git -c core.quotePath=false status --porcelain -uall` lists before writing
anything, so the run can tell its own files from the user's and knows which
tracked files already carry uncommitted changes. The `git rev-parse` probes,
and every other git command whose message the run reads, run under
`LC_ALL=C`. Why: git translates its messages, and the start points below
are told apart by git's English wording, so a translated one would stop a
run that should go on.

**DONE when** the directory is placed in exactly one start point below and
the run goes on, or the run has stopped with nothing written. Why nothing
is written before the start point is settled: a stop at this phase is the
skill declining to touch a directory it cannot vouch for, and a file left
behind would contradict that.

| Start point | How it is recognized | Where it goes |
|---|---|---|
| Empty, no git | `git rev-parse --is-inside-git-dir` fails with `not a git repository (or any …`, and the directory is empty | Phase 1 asks about `git init` |
| Files, no git | `git rev-parse --is-inside-git-dir` fails with `not a git repository (or any …`, and the directory is not empty | The question below, then Phase 1 |
| Inside another repository | `--is-inside-git-dir` prints `false`, and `git rev-parse --show-prefix` prints a path — whether or not the directory is empty | The question below |
| Existing repository | `--is-inside-git-dir` prints `false`, and `--show-prefix` prints nothing | Only the missing files are written (Phase 6) |

Git is settled before emptiness, from what git prints rather than by
comparing paths. Why: an empty directory inside another repository is still
inside it, and a `git init` there makes the nested repository the question
below exists to prevent; and one directory can read differently in git's
output and the shell's (a drive letter on Windows, a symbolic link).

Three cases stop the run in either session, writing nothing, with the reason
in the last message:
- `git rev-parse` fails with any other message (read under `LC_ALL=C`, as
  Inputs says), which the last message quotes: git found a repository
  and will not read it — another user owns it (`dubious ownership`), its
  configuration refuses a bare repository — or a `.git` file points
  nowhere. Why: the directory is inside a repository all the same, and a
  `git init` there makes the nested repository the question below exists
  to prevent.
- `--is-inside-git-dir` prints `true`: a bare repository, or a directory
  inside `.git`, where `--show-prefix` prints nothing as it does at a top
  level. Why: files written there land in git's own data.
- A detached HEAD in a repository, this one or the one above:
  `git symbolic-ref -q HEAD` fails. Why: a commit made there belongs to no
  branch, and the next checkout leaves it behind.

Empty means `ls -A` lists nothing but, at most, a file browser's metadata
(`.DS_Store`, `Thumbs.db`, `desktop.ini`), which no commit of the run
stages. Why: a folder a file browser has opened gains such a file, and
nothing in it needs the protection a stop gives.

A `.claude/CLAUDE.md` or `.claude/AGENTS.md` is its directory's CLAUDE.md
or AGENTS.md when that directory has none, and no second one is written
beside it. Why: Claude Code reads it as it reads the one beside it, and a
second file would split the instructions. The import line is `@` and
AGENTS.md's path from the CLAUDE.md — `@AGENTS.md` side by side,
`@../AGENTS.md` from `.claude/CLAUDE.md`, `@.claude/AGENTS.md` to one in
`.claude/` — since Claude Code resolves an import from the importing file's
directory.

An AGENTS.md whose opening HTML comment holds `kenspc-init template:` makes
the run a rerun at the existing-repository start point, and at a new app
once the question below gets that answer: the run goes to § Rerun, and
Phases 1–7 do not apply. At the other start points the marker changes
nothing, and a stop still stops. Why: a rerun writes too, and a stop
protects a directory whatever it holds.

**Files, no git.** List the entries found and ask whether this directory is
the project, saying that on yes the run will `git init` here with `main` as
the first branch. In a session that cannot ask (a system reminder to work
without stopping), stop and write nothing: the last message lists the
entries and says the run stopped because it could not confirm that this is
the project directory. Why: a directory of files could be a home folder or
a downloads folder, and a `git init` there puts them in a repository nobody
chose. On yes, the run goes on as for an empty directory, the answer
standing as Phase 1's answer; a yes that declines the `git init` goes on
without git, as a no in Phase 1 does. The files that were already here are
not staged by any commit the run makes, except one the run changed — a
`.gitignore` it appended to, a CLAUDE.md it gave the import line — which is
committed whole and marked on the file list as there before the run. Why:
the new repository has no earlier version of that file for the run's lines
to go on top of.

**Inside another repository.** Ask whether this directory is a new app of
the repository above it, or a project of its own. A new app gets only this
directory's AGENTS.md and CLAUDE.md pair (§ A new app in another
repository), and no `git init`. For a project of its own, suggest moving
the directory out of that repository and running `/kenspc-init` there, and
stop with nothing written. In a session that cannot ask (a system reminder
to work without stopping), stop and write nothing: the last message names
the repository above and says the run stopped because it could not ask
which of the two this directory is. Why: a `git init` inside another
repository makes a nested repository, which the outer one then records as
an embedded repository or lists as untracked files, and which is hard to
take apart later.

**Existing repository.** The run writes only what is missing (Phase 6).
An AGENTS.md without the template marker is the user's: it is left as it
is, it gains none of the template's sections, and the final message says
so; a CLAUDE.md the run writes beside it says only that the project's
instructions are in AGENTS.md, since that file holds no kenspc conventions,
and the final message says why it was written: once a CLAUDE.md exists,
Claude Code's default mode stops reading AGENTS.md, which the import line
keeps loaded. Why: moving an existing project's instructions onto the
template is a migration, which this version does not do.

## Phase 1: Git

**Goal**: a git repository at the project root, when the user wants one.

**DONE when** `git rev-parse --show-prefix` prints nothing here and the
first branch is `main`, or the user declined and the run goes on without
git. Nothing happens here for an existing repository or a new app in
another repository.

For an empty directory, ask whether to `git init` here, with `main` as the
first branch; the default is yes. In a session that cannot ask (a system
reminder to work without stopping), run it. Why the default is yes: every
later phase — the scaffold commits, the documentation commit, the GitHub
step — needs a repository, and an empty directory holds nothing a
repository could harm.

The first branch is set to `main` explicitly — `git init -b main`, or
`git symbolic-ref HEAD refs/heads/main` right after a `git init` whose git
lacks `-b` — rather than left to git's default. Why: that default depends on
the git version and the user's configuration, and the branch name ends up
in the first push and in what the documents say.

A no: the run goes on without git. It writes the files, makes no commit,
skips the GitHub step and Phase 7, uses the file backlog (C), and the
final message says so.

## Phase 2: Interview, rounds 1–2

**Goal**: what the project is, its shape, and its stacks.

**Inputs**: the DESCRIPTION; what Phase 0 found.

**DONE when** rounds 1 and 2 were asked and answered or skipped — in a
session that cannot ask, filled from the DESCRIPTION and the scan and
otherwise left to their defaults — and the app list is settled: one app or
several, each with its name and, where known, its stack.

- Round 1 — Project: the name, a one-line summary, the users, the scope,
  and the non-goals. The name defaults to the directory's name.
- Round 2 — Shape and stack: one app or a monorepo, which apps, and each
  app's stack.

How every round is asked, here and in Phase 4:

- One round per message: the round's questions together, each pre-filled
  with what the DESCRIPTION or the scan shows, so the user confirms rather
  than retypes. What they already answer is not asked. The repository's
  shape (one app or a monorepo) and its hosting are asked once all the
  same, even when the scan suggests them — the shape here, the hosting in
  Phase 5. Why: a monorepo with one app so far reads to a scan as a single
  app, and a remote can be a mirror; both decide where files go and which
  backlog is used, and a wrong guess is costly to move later.
- Any round can be skipped; a skipped question takes its default
  (§ Defaults and TBD).
- "Use the defaults for everything", in any wording or language, ends the
  interview: the rounds not yet asked are skipped. The questions outside
  the interview — scaffolding, the GitHub repository, the file list, push,
  labels — are still asked. Why: each is its own decision about writing
  outside the documents or over the network, which a wish to stop
  answering questions does not make.

In a session that cannot ask (a system reminder to work without stopping),
no round is asked: every answer comes from the DESCRIPTION and the scan, the
shape is what the scan shows (one app when nothing shows more), and every
other item takes its default.

## Phase 3: Scaffold (optional)

**Goal**: each app the user chose to scaffold, generated by its stack's
official generator and committed.

**Inputs**: the app list from Phase 2; the tools Phase 0 found.

**DONE when** every app whose directory does not exist yet, or holds
nothing but what Phase 0 counts as empty (and `.git`, for a single app at
the repository root), was offered scaffolding, and each app the user chose
has its scaffold commit — or the reason it has none is recorded for the
final message. An app that already has files is not offered scaffolding.
Why `.git` does not count at the root: a single app's directory is the
repository root, which holds `.git` from Phase 1 on. An app directory
elsewhere that holds a `.git` of its own is a nested repository, treated as
one whose generator's `.git` stays (below): it is not offered scaffolding,
and its pair stays out of every commit (§ Confirm and commit).

Ask, for each such app, whether to scaffold it and with which generator —
the one the stack's official documentation names, offered and never
assumed. In a session that cannot ask (a system reminder to work without
stopping), no app is scaffolded. Why: a generator writes many files and
picks versions and defaults, which is the user's decision; a project with
no scaffolding still gets every document, its commands `TBD(init):`.

- **No generator command in this skill.** Before running a generator, read
  its `--help` or its official documentation for the current command, its
  options, its version, and how to run it without interactive prompts, and
  choose the options from the user's answers — never one that overwrites or
  empties a directory. Why: generators change their commands, options, and
  versions between releases, for the same reason the plugin names no model:
  a command copied into a skill goes stale without an error. Why not those
  options: a single app's generator runs in the repository root, which
  already holds `.git`, and they would take files the generator did not
  write.
- **A generator that fails** leaves its output where it is, or it moves to
  `.trash/` the way a generator's `.git` does below; nothing is deleted, the
  app gets no scaffold commit, and the final message reports the error.
  Why: a partial output is the evidence of what went wrong, and a delete
  cannot be undone.
- **A missing tool.** When a tool the generator needs (an SDK, a runtime)
  is not on the PATH, that app is not scaffolded: say what is missing and
  where its official installer is, install nothing, and ask whether to go
  on without scaffolding that app or to wait while the user installs it,
  looking for the tool again after the wait. In a session that cannot ask
  (a system reminder to work without stopping), this question does not come
  up, since no app is scaffolded. Why: an SDK installed by the skill changes
  the user's machine beyond the project, and which version to install is
  the user's to choose.
- **Layout.** A monorepo puts each app under `apps/<name>/`, laid out inside
  as its stack expects — for .NET, for example, the projects under
  `apps/<name>/src/`. A single app follows its stack's convention at the
  repository root. Why: `apps/<name>/` gives every app one predictable place
  for its AGENTS.md pair, and inside it the stack's tools find the layout
  they expect.

After each generator run, three things it may have left are checked:

- **A README it wrote.** Ask once, for all of them, whether to replace each
  README a generator wrote in this run with init's version: at the root,
  the README of Phase 6; in an app's directory, three lines — the app's
  name as the title, what the app is, and that its commands and rules are in
  its AGENTS.md. In a session that cannot ask (a system reminder to work
  without stopping), replace them. Why: such a file is this run's own
  output, so replacing it loses nothing of the user's, and a generator's
  README describes its template, not the project. It is the one existing
  file the run replaces.
- **A `.git` directory it created** inside the app's directory. Ask whether
  to move it out. On yes, move it to `.trash/<app>-git/` at the project root
  (with the next free `-<n>` suffix when that exists) and make sure
  `.trash/` is in `.gitignore`; nothing is deleted. Why a move, not a
  delete: the directory may hold the generator's own first commit or hooks,
  and a move can be undone. In a session that cannot ask (a system reminder
  to work without stopping), leave it in place and say so in the final
  message; a no leaves it the same way. An app whose `.git` stays gets no
  scaffold commit, and its AGENTS.md and CLAUDE.md, written in Phase 6,
  stay out of every commit (§ Confirm and commit); the final message names
  them as written and not committed. Why: git records that directory as an
  embedded repository, not as its files, and refuses a pathspec inside it,
  which would fail the whole commit.
- **A `.gitignore` it replaced.** Before running a generator in a directory
  that already has a `.gitignore`, note the file's content; afterwards, the
  noted lines stand as they were, in order, and the generator's lines they
  lack are appended. Why: the existing lines are the user's, and a generator
  that writes its own file drops them without a word.

**The scaffold commits.** Each scaffolded app is committed alone, before
the documentation commit: `chore: scaffold <app>`, adapted to the
repository's commit convention (Phase 6). It stages what the generator
wrote, as the status before and after its run shows — the app's directory,
or for a single app at the root the paths the generator created, and any
path it wrote outside them, which the file list names — passed to
`git commit` as a pathspec. When the status shows nothing the generator
wrote, the app gets no scaffold commit, as § Confirm and commit says of an
empty pathspec, and the final message says so. Why one commit per app,
ahead of the documents: the generator's output is not the run's own
writing, and a diff of it alone is readable; the documents then describe
files already in history. Why the pathspec: it keeps anything the user had
staged out of the commit. Before staging, the app's status is read with
ignored paths included
(`git status --porcelain --ignored=matching -uall -- <app>`, without the
path for a single app at the root) for a directory the stack's tools
restore or build — a package install directory, a compiler's output — and
each one `.gitignore` does not already ignore (probed as § Files says) is
appended to the root `.gitignore` (only appended) and named on the file
list. Why: such a directory is regenerated on every machine, can carry this
machine's paths, and buries the readable diff; plain status hides one that
the user's own excludes already cover, and a teammate's clone does not
ignore it. A commit that fails stops the run as § Confirm and commit
describes. Without git (a no in Phase 1), the apps are scaffolded and
nothing is committed.

## Phase 4: Rescan, interview rounds 3–5

**Goal**: the commands, read from the files, and what the project delivers
and how the team works.

**Inputs**: the directory after Phase 3, rescanned; the answers so far.

**DONE when** each app's commands are read, and rounds 3–5 were asked and
answered or skipped — in a session that cannot ask, filled from the
DESCRIPTION and the scan and otherwise left to their defaults.

**Commands** — build, test, lint, run, and the like, for each app — are
read from the configuration files: a manifest's scripts, and the commands
the stack's own tooling defines for the project files present. They are not
asked. A command no file shows is `TBD(init):`. Why: a command read from a
file is the one that runs; a remembered one may differ.

- Round 3 — UI: whether there is a UI, on which platforms, and with which
  component library or design system (and its token file, where one
  exists).
- Round 4 — Delivery: the versioning scheme (SemVer, CalVer, or none) and
  the file that holds the version number; the environments; the deployment
  method; the migration policy.
- Round 5 — Collaboration: the branch and commit conventions. In an
  existing repository, pre-filled from what Phase 0 found.

The rounds are asked as Phase 2 describes. In a session that cannot ask (a
system reminder to work without stopping), rounds 3–5 are not asked either:
their items come from the DESCRIPTION and the scan, or take their defaults.

## Phase 5: GitHub and backlog

**Goal**: the hosting settled, and the backlog convention chosen.

**Inputs**: the git remotes; whether `gh` is installed and logged in.

**DONE when** the hosting is confirmed, a GitHub repository exists with its
remote set when the user asked for one, and the backlog is A or C. Skipped
without git: the backlog is then C.

**Hosting.** With a remote, confirm what it says about the hosting — GitHub,
or another host such as Azure DevOps. In a session that cannot ask (a
system reminder to work without stopping), the remote is taken as it reads.
With no remote, the hosting question is the one below.

**Creating a GitHub repository** — only when there is no remote at all.
Ask whether to create one; it is private unless the user says otherwise.
In a session that cannot ask (a system reminder to work without stopping),
no repository is created and nothing is pushed. On yes:

- With `gh` installed and logged in, ask for the owner every time — the
  account `gh` is logged in to, or one of its organizations, both read with
  `gh api` and offered — and for the name, defaulting to the project's
  name. Creating the repository and setting it as the remote `origin` is
  one step, `gh repo create`, its options read from
  `gh repo create --help`; nothing is pushed here. Why the owner is asked
  every time: one person creates both personal and organization
  repositories, and one created under the wrong owner has to be
  transferred or deleted. In a session that cannot ask (a system reminder
  to work without stopping), this question does not come up, since no
  repository is created.
- With `gh` missing or not logged in, give the manual steps instead —
  create the repository on GitHub, then `git remote add origin <url>`, and
  push when ready — and the backlog is C. Why C, though a GitHub remote may
  come soon: the backlog convention is written now, from the remote that
  exists now; moving a backlog from files to GitHub Issues is left to a
  later version.

A remote that is not on GitHub gets no proposal of a GitHub repository.
Why: the project already has a host, and a second one would split it.

**The backlog.**

- **A — GitHub Issues**, when a GitHub remote exists (there before the run,
  or just created): a remote whose URL's host is `github.com`
  (`https://github.com/…` or `git@github.com:…`). Labels: `bug` and
  `enhancement`, which GitHub creates by default, and `debt` and
  `found-by-agent`, created in Phase 7.
- **C — one file per item**, in every other case (no remote, or a remote on
  another host): `docs/backlog/YYYY-MM-DD-<slug>.md`, in the format
  `backlog-README.md.tmpl` gives — a frontmatter of type, who found it,
  when, and the source, and no status field. The format is written once,
  in the project's `docs/backlog/README.md`, which AGENTS.md's Workflow
  points to and which keeps the directory tracked while it holds no item.
  It is its own format, not the Backlog.md tool's. Why no status field: an
  item's file existing is its status, and the commit that deletes it — on
  resolving it, or on dropping it with the reason in the message — is the
  record of how it ended; a status field would be one more thing to keep
  in step with that.

Why A with a GitHub remote and C otherwise: issues sit beside the code and
the pull requests where the host offers them; elsewhere, files in the
repository are readable by every agent without a tool or a login.

Both A and C carry one write rule, written once in AGENTS.md's Workflow: in
an interactive session a new backlog item is created only with the user's
agreement, and an unattended run lists what it found in its report
instead. Why: an item nobody agreed to is noise in a list the team reads,
and an unattended run has nobody to agree.

## Phase 6: Write, check, confirm, commit

**Goal**: every file the run owes, written, checked, confirmed, and
committed.

**Inputs**: everything the earlier phases gathered; the templates in
`${CLAUDE_PLUGIN_ROOT}/skills/init-project/templates/`.

**DONE when** the files in § Files are written; every check in § Checks
passes on them; the user confirmed the file list — in a session that cannot
ask, it was presented and committed as presented; and the documentation
commit exists. Or the run ended without git, at a "no" to the file list,
at a failing commit, or with no file left to commit, and the final message
says which.

### Files

| File | Template | Written |
|---|---|---|
| `AGENTS.md` | `AGENTS.md.tmpl` | Always |
| `CLAUDE.md` | `CLAUDE.md.tmpl` | Always; an existing one, see § An existing CLAUDE.md |
| `README.md` | `README.md.tmpl` | Always, and in place of a README a generator wrote in this run (Phase 3) |
| `docs/product.md` | `product.md.tmpl` | Always |
| `docs/architecture/overview.md` | `architecture-overview.md.tmpl` | Always |
| `docs/ui/design-system.md` | `design-system.md.tmpl` | Always; with no UI, its title and the line saying so, and nothing else |
| `docs/release.md` | `release.md.tmpl` | Always |
| `docs/deployment.md` | `deployment.md.tmpl` | Always |
| `CHANGELOG.md` | `CHANGELOG.md.tmpl` | Only when a versioning scheme was chosen — SemVer or CalVer, not none and not TBD |
| `docs/backlog/README.md` | `backlog-README.md.tmpl` | When the backlog is C |
| `apps/<name>/AGENTS.md` and `apps/<name>/CLAUDE.md` | `app-AGENTS.md.tmpl`, `app-CLAUDE.md.tmpl` | For each app of a monorepo |
| `.gitignore` | — | Always: `.kenspc/` and `CLAUDE.local.md` appended, and `.trash/` and the restore and build directories when Phase 3 used or found them, each only when `.gitignore` does not already ignore it |

"Always" means wherever no such file exists: nothing that exists is
overwritten or edited, except a README a generator wrote in this run, the
lines appended to `.gitignore` (in its own line endings, after a final
newline it lacks), and the one line an existing CLAUDE.md gains on a yes.
Why: an existing file is the user's, and the run cannot tell which of its
lines were deliberate. A `README*` or `CHANGELOG*` of any name and case
(`readme.md`, `README.rst`, `Changelog`) counts as that file, and the
Documents table names it as it is. `docs/architecture/` is a folder so that
the overview can later be split into `<topic>.md` files beside it without a
rename.

`.gitignore` already ignores an entry when `git check-ignore --no-index -q`
exits 0 on a path under it (`.kenspc/runs/probe`, `CLAUDE.local.md`,
`.trash/probe`; none need exist) and `git check-ignore --no-index -v` names
a `.gitignore` inside the repository as the source (a path from the top
level, such as `.gitignore` or `apps/<name>/.gitignore`; a global excludes
file prints as an absolute path, whatever its name, and does not count);
without git, when a line of it, `\r` stripped, is the entry. Why: git's
matching reads a CRLF file and an equivalent pattern (`/.kenspc/`) as
meant; `--no-index` tests the patterns for a file already tracked too,
which git otherwise never reports as ignored; and a rule in the user's
global excludes does not reach a teammate.

Nothing else is written:
- `docs/briefs/`, `docs/plans/`, and `docs/tasks/` — the skills that write
  them create them when they need them.
- No guide: generate-guide writes guides, and AGENTS.md says they go in
  `docs/guides/`. That line is not a Documents row until a guide exists.
- Nothing under any `.claude/` directory, except the import line an
  existing `.claude/CLAUDE.md` gains on the user's yes (§ An existing
  CLAUDE.md). Why: Claude Code treats it as a protected path, and a write
  there fails in an unattended session.
- No CONTRIBUTING and no roadmap file. Why: how to work on the project is
  AGENTS.md's Workflow, which a CONTRIBUTING file would repeat, and a
  roadmap holds plans the interview does not ask about.

None of these file names matches the plugin's reminder hook — a path under
`docs/plans/`, `docs/briefs/`, `docs/tasks/`, `docs/guides/`, or
`docs/guide/`, or a name ending in `GUIDE.md`, `SETUP.md`, or
`ONBOARDING.md` — so writing them sets off no reminder to use another
skill. A file this list gains keeps to that.

### Filling the templates

- Each `{{…}}` slot is replaced by what the interview or the scan gave; the
  slot's text says what belongs there. In a topic document or a README, a
  slot nothing filled becomes `TBD(init): <what the slot asks for, in a
  few words>`; a slot that stands for table rows and has none gives one
  `TBD(init):` line in place of the whole table, and a known row's unknown
  cell reads `TBD(init): <the column>`. Why: the topic documents are where
  a later answer is filled in, and the marker says what it is waiting for.
- In an AGENTS.md or a CLAUDE.md, a slot nothing filled becomes one
  `TBD(init):` in its line, except a slot for rules the user gave, which is
  left out; a section left with no line is dropped with its heading. No
  placeholder paragraph is written. Why: AGENTS.md loads into every
  session, so an unknown costs one line there at most.
- Every slot sits at the end of its line or alone in a table cell, so a
  marker runs from `TBD(init):` to the end of its line or its cell. The one
  exception is the Workflow's version line, whose marker ends at the ` — `
  before `rules in docs/release.md`, so the line keeps its fixed form. Why:
  a rerun replaces the marker and nothing else, and the text around it on
  the line is fixed text or another answer.
- A line ending in `{{when: <condition>}}` is written, without the tag and
  the space before it, when the condition holds, and left out when it does
  not.
- The HTML comment at the top of each AGENTS.md, and each CLAUDE.md's
  import line and its line saying where the instructions are, are copied
  as they are. Why the CLAUDE.md lines, when Claude Code can read AGENTS.md
  itself: in its default mode the CLAUDE.md this run writes stops that
  reading, as a teammate's private `CLAUDE.local.md` does; no project
  setting can change the mode; before v2.1.277, or with the built-in
  agents-md plugin disabled, nothing reads it; only an imported AGENTS.md
  fires the InstructionsLoaded hook; and a Read of CLAUDE.md shows the
  import as one line, which the other line explains.
- Policy items — the versioning scheme, the file that holds the version,
  the environments, the deployment method, the migration policy, the branch
  and commit conventions — that nobody answered are `TBD(init):`, never a
  default. Why: a policy the skill picked reads as a decision the team
  made, and nobody reopens a decision that looks made.
- A versioning scheme of none is written out as a sentence, for example
  `No versioning — deployed from main, identified by commit SHA.`, and the
  sections that follow from a version number say there is none. When a
  platform is iOS or Android, the mobile app's version and build number are
  never none: the release document says so, and where nothing was
  answered for them, they are `TBD(init):`. Why: an app store takes no
  submission without both.
- The two safety rules are always in the root AGENTS.md's Rules, their
  wording adjusted to the project, such as its environment names: no
  deploying to, migrating, or reading the data of staging or production,
  and no secret in the repository. Why: a deploy, a migration, or a read of
  shared data does damage no revert of the code undoes, and history keeps a
  committed secret. The Rules hold twelve at most, since AGENTS.md loads
  into every session; each further rule passes the admission rule in the
  file's comment, and one that does not goes to the topic document it
  concerns or to an app's AGENTS.md.
- No secret value goes into any file — no key, token, password, or
  connection string, even one the user types into an answer. The
  deployment document names where each secret lives (a vault's name, a
  secret's name), never its value, and a remote's URL is written without the
  user part an `https://` URL may carry (`https://<token>@github.com/…`
  becomes `https://github.com/…`). Why: history keeps every committed line,
  so a committed secret is permanent.
- AGENTS.md holds nothing the code already says: no directory tree, no
  dependency list. Why: those go stale in the file while staying right in
  the code, and every session pays for them.

### An existing CLAUDE.md

Ask whether to add one line, the import line (Phase 0), at its top,
leaving everything else as it is; for a `.claude/CLAUDE.md`, say that
Claude Code will ask to approve the write, since `.claude/` is a protected
path. On yes, write that line, in the file's own line ending, followed by
the original content unchanged: `tail -n +2` of the file then matches the
original byte for byte. Then report the line count of AGENTS.md and
CLAUDE.md together, and any content the two visibly repeat (the same rule
or command in both), for the user to settle; the run removes nothing from
either. In a session that cannot ask (a system reminder to work without
stopping), leave the file as it is. Without the import, the final message
gives the same line count and says when Claude Code loads AGENTS.md anyway
— only in the `claude-md-and-agents-md` mode of its `instructionFiles`
setting, on v2.1.277 or later with the built-in agents-md plugin enabled,
since in the default mode a CLAUDE.md stops it — that the import line would
load it wherever CLAUDE.md loads, and that where both load, content the two
repeat takes up context twice. Why: CLAUDE.md is the user's, and a model
has been following it as written; the import is the one change that loads
AGENTS.md in every mode that loads CLAUDE.md, and it changes nothing else.

AGENTS.md already loads when the two are one file — one a symbolic link to
the other, which `[ <AGENTS.md> -ef <CLAUDE.md> ]` tells — or when a line of
CLAUDE.md, `\r` stripped, is the import line: then nothing is asked,
CLAUDE.md is not written, and the final message says AGENTS.md already
loads. Claude Code reading AGENTS.md itself does not count. Why: only these
two load it whatever the mode and the environment; a write through the
link lands in the user's AGENTS.md, which would then import itself, and a
second import loads nothing new.

### Checks

Run before the commit, whether or not a commit follows, on what this run
wrote: the files it created, the lines it added to a file already there,
and the markers a rerun replaced. The secret check alone also reads the
user's lines the commit would add to history: all of a file history does
not hold yet, and the lines a tracked file has that its last commit lacks.
Why: history keeps a committed secret whoever wrote it. Lines are compared
with any `\r` stripped and counted per file (`grep -c ''`). Why: a CRLF
file, or one without a final newline, otherwise reads as failing or one
line short.

- The line budget, on the files of each pair the run created: the root
  pair at most 80 lines (AGENTS.md alone beside a CLAUDE.md already there),
  each app's pair at most 40. A rerun holds instead the 200-line ceiling
  that the comment states, or a count no higher than before it.
- Each CLAUDE.md the run created or gave the import has the import line
  (Phase 0) as its first line.
- Each AGENTS.md the run created opens with the HTML comment holding
  `kenspc-init template: 1` and the admission rule's three conditions.
- Every path in the first column of a Documents table the run wrote exists
  (for an `apps/*/AGENTS.md` row, each app's).
- No line the run wrote, and no line of the user's the commit would add,
  holds a value that reads as a secret: a private key block
  (`-----BEGIN … PRIVATE KEY-----`); a token with a known prefix
  followed by its body (`gh[pousr]_`, `github_pat_`, `glpat-`,
  `xox[abposr]-`, `xapp-`, `sk-`, `sk_live_`, `rk_live_`, `npm_`, `AKIA`,
  `AIza`); a JSON web token (`eyJ…`, three dot-separated parts); a
  connection string or URL carrying `Password=`, `Pwd=`, `AccountKey=`,
  `SharedAccessKey=`, or `sig=`, or a user part
  (`https://<user>:<password>@…`, `https://<token>@…`); a key, token,
  secret, or password label followed by a long opaque value. A secret's
  name or its store's name is not a value.
- Every `TBD` the run wrote is `TBD(init): <text>` — a search for `TBD` finds
  no other form — and no `{{` of a template slot is left.
- Except after a rerun or at a new app, which append nothing to it,
  `.gitignore` ignores `.kenspc/` and `CLAUDE.local.md`, probed as § Files
  says.

A check that fails on what the run wrote is fixed, and every check runs
again; a result that fails one is not committed. A root AGENTS.md over its
budget moves a rule to the topic document it concerns, or folds the per-app
rows of its Documents table into one `apps/*/AGENTS.md` row; the run writes
no path-scoped rule, since those live under `.claude/`. A secret-looking
value on a line of the user's is not changed: that file stays out of the
commit, marked so on the file list, and the final message names the file
and the line's number — not the value, which a message would only copy
further; the other files are committed. Why: no reviewer reads these
files, and each check guards a way they fail without an error — an
AGENTS.md too long to load in every session, a CLAUDE.md that no longer
imports it, a table naming a file that is not there, a marker a rerun
cannot find, a secret that history keeps; and a line the user wrote is not
the run's to change.

### Confirm and commit

**The file list.** List every file written or changed, marked created,
appended to, or given the import line. Mark as well each file that held
uncommitted changes of the user's before the run (Phase 0's status), since
a commit takes the file whole; each path git ignores (`git check-ignore -q`
exits 0) as written, ignored, and not committed — never added with
`git add -f`; each file inside a directory below the top level that holds a
`.git` of its own, such as an app's pair beside a kept `.git`, as written
and not committed, in a rerun too, since git refuses a path inside a nested
repository and the whole commit would fail (Phase 3); and each file
§ Checks keeps out of the commit.
Ask the user to confirm or adjust; apply adjustments, run the checks again,
and list again. In a session that cannot ask (a system reminder to work
without stopping), present the list and commit it as presented, leaving
out each file that held uncommitted changes, which the final message names.
On a "no", nothing is committed; the files stay in the tree, and the final
message says so. Why: no reviewer runs on these files, so the user's look
at the list is the gate before they enter history; the user's unfinished
work goes in only on that look, and an ignored path is one the user chose
to keep out.

**The commit.** `docs: initialize project documentation`, staging exactly
the listed files not marked to stay out, passed to `git commit` as a
pathspec. When no file is left to commit — the run wrote nothing, or all
it wrote stays out — no commit is made, and the final message says why; no
commit this run makes, a scaffold commit or a rerun's included, runs
`git commit` with an empty pathspec. Why: with no path,
`git commit` commits whatever the user had staged, under the run's
subject. An existing repository's commit convention shapes this subject
and the scaffold ones: the one it writes down (in the project's
instruction files or its CONTRIBUTING), or, failing that, the pattern its
recent commit subjects consistently share.
Why: the history keeps one style, and the subjects given here are the
default for a repository that has none.

**A commit that fails** — a commit hook rejects it, or git refuses the
pathspec — stops the run: report the error and ask the user how to go on.
Do not retry, and do not bypass the hook with `--no-verify`. In a session
that cannot ask (a system reminder to work without stopping), stop and
report. Why: the hook encodes the project's rules, and a bypass the user did
not choose changes how their repository is guarded. The report names the
paths still staged and gives `git reset -q -- <those paths>`, which
unstages them and leaves the files in place.

## Phase 7: Push and labels (optional)

**Goal**: the push and the labels, each done only on its own yes.

**DONE when** each question below was asked and acted on, or does not
apply. Nothing here runs without git or without a remote.

**Push.** With a remote, ask whether to push the current branch now,
setting its upstream. In a session that cannot ask (a system reminder to
work without stopping), nothing is pushed. Why last: the first push then
carries the complete repository — scaffolds and documents together.

**Labels**, for backlog A. First read the repository's labels
(`gh label list`). Ask whether to create whichever of `debt` and
`found-by-agent` is missing; no other label is created, since these four
are the ones AGENTS.md's backlog line names. When `bug` or
`enhancement` is missing — an organization can replace GitHub's default
labels — say so, and leave it to the user. In a session that cannot ask (a
system reminder to work without stopping), no label is created, and the
final message lists the labels to create. Why read first: a label that
already exists makes the create fail, or adds a near-duplicate under
another case. When the labels cannot be read — `gh` missing or not logged
in, or a repository it cannot reach — nothing is created, and the final
message lists `debt` and `found-by-agent` the same way.

## A new app in another repository

**Goal**: this directory's AGENTS.md and CLAUDE.md pair, and nothing
outside it.

**Inputs**: Phase 0's scan; the outer repository's root AGENTS.md, if any;
the DESCRIPTION.

**DONE when** the pair is written, its checks pass, the user confirmed the
file list, and the commit exists — or the run ended at a "no" to the list,
at a failing commit, or with no file to commit (both files already here,
with the import present or declined, or all it wrote staying out), and the
final message says which.

When Phase 0's question gets "a new app", the run writes only this
directory's pair: `AGENTS.md` from `app-AGENTS.md.tmpl` and `CLAUDE.md` from
`app-CLAUDE.md.tmpl`, together at most 40 lines. What is already here
follows the rules of an existing repository: nothing is overwritten
(§ Files), an AGENTS.md without the template marker is left as Phase 0
says, and a CLAUDE.md goes through § An existing CLAUDE.md. The lines that
point to the root's conventions are written only when the outer
repository's root AGENTS.md carries the template marker. Why: elsewhere
there are no such conventions to point to. No `git init`, no scaffolding,
no GitHub step, no topic document, no backlog, and no change to the outer
repository's `.gitignore`: the final message names which of `.kenspc/` and
`CLAUDE.local.md` it lacks (probed from its top level as § Files says), for
the user to add. Why: the outer repository is the user's project as it
stands, and this run was started for one directory in it.

The interview asks only what the pair holds: the app's name and one-line
summary, its stack, and rules for this app only; its commands are read
from its files, as Phase 4 reads them. In a session that cannot ask (a
system reminder to work without stopping), the run never reaches this
interview: it stopped at Phase 0's question. The checks that apply to the
pair run (budget, first line, template comment, secrets, TBD form); then
the file list, its confirmation, and the commit, as Phase 6 describes,
under the outer repository's commit convention.

## Rerun

**Goal**: the `TBD(init):` markers the user answers filled in, and nothing
else changed.

**Inputs**: every `TBD(init):` marker in the files the run owns — the
AGENTS.md that carries the template marker, the documents its Documents
table names, and each app's pair — and the DESCRIPTION.

**DONE when** either holds:
- No marker exists, or none got an answer: nothing is changed, and the
  final message says so, with how many markers remain and in which files.
- Every marker that got an answer is replaced by it, and the run's diff
  changes no line that did not hold a marker.

Ask about the markers grouped by file, in the interview's manner: one group
per message, each skippable, a finding of a new scan offered as a suggested
answer and used only when the user accepts it. In a session that cannot
ask (a system reminder to work without stopping), only the DESCRIPTION
answers markers; when it answers none, nothing changes, and the final
message says how many markers remain and in which files.

- An answer replaces its marker only — from `TBD(init):` to the end of its
  line or its table cell, or on the Workflow's version line to the ` — `
  before `rules in docs/release.md` — and the text around it stays as it is.
  In an AGENTS.md or a CLAUDE.md the answer fits on that line; in a topic
  document a marker alone on its line may give way to more lines — a table
  in place of one marker line.
- A consequence that would change more than a marker — a CHANGELOG.md for a
  versioning scheme just chosen, a new Documents row — is not made; the
  final message names it for the user. Why: a rerun promises that only the
  markers change, so the user can rerun without reviewing every file again.
- The checks run on what the rerun changed (§ Checks), and the final
  message names what `.gitignore` lacks, since a rerun appends nothing to
  it; then the file list, its confirmation, and the commit, as Phase 6
  describes, with the subject `docs: fill in answered TBD(init) markers`,
  adapted to the repository's commit convention.
- No other file is written, and there is no scaffolding, GitHub step,
  push, or label. Moving an existing project onto the template, and
  bringing files an earlier template version wrote up to a later one, are
  not in this version; the `kenspc-init template: 1` marker is kept for
  that later upgrade.

## Defaults and TBD

A question skipped in a session that can ask, and every question in a
session that cannot, takes the default in the table below; an interview
item takes its answer from the DESCRIPTION or the scan when they give one,
and is otherwise `TBD(init):`. Every question the skill asks is one of
these gates.

| Gate | Asks | In a session that cannot ask |
|---|---|---|
| Files, no git | Is this the project directory, with `git init` here? | Stop; nothing is written |
| Inside another repository | A new app of that repository, or a project of its own? | Stop; nothing is written |
| New-app interview | The app's name, summary, stack, and rules | Not reached; the run stopped at Phase 0 |
| Empty directory | `git init`, first branch `main`? | `git init`, first branch `main` |
| Interview rounds 1–5 | Each round's questions | Not asked; the DESCRIPTION and the scan, then `TBD(init):` |
| Scaffolding, per app | Scaffold it, and with which generator? | Not scaffolded |
| A missing tool | Go on without scaffolding the app, or wait | Does not arise |
| A generator's README | Replace it with init's version? | Replaced |
| A generator's `.git` | Move it to `.trash/`? | Left in place, named in the final message; no scaffold commit for that app |
| Hosting, with a remote | Is this the project's host? | The remote as it reads |
| No remote | Create a GitHub repository, its owner, its name | None created |
| An existing CLAUDE.md, at the root or in `.claude/` | Add the import line at its top? (Not asked when AGENTS.md already loads) | Left as it is; the final message says when AGENTS.md loads without the import, with the two files' line count |
| The file list | Confirm or adjust | Committed as presented, less each file that held uncommitted changes |
| A commit fails | How to go on | Stop and report |
| Push | Push now? | Nothing pushed |
| Labels, backlog A | Create the missing `debt` and `found-by-agent`? | None created; listed in the final message |
| Rerun | An answer for each marker | Only the DESCRIPTION's answers; none, no change |

The backlog takes no question: A with a GitHub remote, C otherwise. The two
safety rules are always written, and the documentation commit is made
unless the user says no at the file list or no file is left to commit.

## Exit

The final message gives:

- the start point, and each file with what happened to it — created,
  appended to, given the import line, or left as it was;
- the commits, each with its hash and subject, or why none was made;
- the `TBD(init):` markers left, counted per file;
- every default a session that cannot ask took in place of a question;
- what is left for the user, whichever applies: an existing CLAUDE.md
  without the import (the line count, and when AGENTS.md loads without it,
  as § An existing CLAUDE.md says); a CLAUDE.md written beside the user's
  AGENTS.md, and why (Phase 0); an existing AGENTS.md left without the
  template's sections; a generator's `.git` left in place, or a
  generator that failed and where its output is; an app not scaffolded, and
  why; the manual GitHub steps; the labels to create; the lines
  `.gitignore` lacks after a rerun, or in a new app's outer repository; the
  files written and not committed — an app's pair beside a kept `.git`, an
  ignored path, a file that held uncommitted changes, a file with a
  secret-looking value on a line of the user's (with the line's number),
  every file after a "no"; the files that were in a directory without git
  before the run, which no commit carried; and, after a rerun, a
  consequence of an answer that was not made.

Next step: `/kenspc-init` again once some `TBD(init):` markers have
answers, and `/kenspc-brief` or `/kenspc-plan` for the first piece of work.
The skill invokes neither. Why: the user decides when to start planning.

## Writing rules

- Match the user's language in the conversation; the files are in English
  unless the user asked otherwise (§ Language).
- Commit messages are in English.
- No branch, pull-request, rebase, or tag step: apart from naming the first
  branch of a new repository `main`, the commits land on the current
  branch. Why: a git step nobody asked for is a decision the user did not
  make.

## Phase transitions

Each phase starts from the artifact the previous one produced, not from the
wording that closed it:

- Phase 0 → Phase 1: the start point. A stop at Phase 0 has written nothing;
  a rerun goes to § Rerun, and a new app to § A new app in another
  repository.
- Phase 1 → Phase 2: `git rev-parse --show-prefix` printing nothing here, or
  the user's no.
- Phase 2 → Phase 3: the app list.
- Phase 3 → Phase 4: each scaffold commit's hash, or the recorded reason an
  app has none.
- Phase 4 → Phase 5: the commands and the answers of rounds 3–5.
- Phase 5 → Phase 6: the remote, and the backlog, A or C.
- Phase 6 → Phase 7: the documentation commit's hash.
- The exit: the pushed branch and the labels, or the answers that declined
  them.

Why: a phase's closing sentence has been read as the end of a whole skill
run; the next phase reads an artifact, so the artifact is what moves the run
forward.
