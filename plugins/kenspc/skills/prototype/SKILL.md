---
name: prototype
description: >
  Answer one open question from a requirement brief with a throwaway
  prototype (原型) — logic, UI, or a feature slice — then record the
  answer, the evidence, and the prototype's commit in the brief and remove
  the prototype in the next commit. Use when a brief's Open Questions entry
  is marked needs prototype, or the user asks to settle a question by
  building something before planning. Not for building a feature to keep
  (use generate-plan or generate-task), not for running or trying out a
  snippet (just run it), and not for fixing a bug (use diagnose-bug).
  Trigger on: "prototype this", "spike this question", "build a quick
  prototype to find out", "做个原型", "先做个原型验证一下",
  "写个原型试试", "用原型回答这个问题", or invokes /kenspc-prototype
  directly.
version: 3.0.0
argument-hint: <brief path> [entry number or question]
---

# Prototype

Answer one open question from a requirement brief by building the smallest
thing that settles it, then write the answer into the brief and remove the
prototype. Three phases: Frame, Build and run, Record and discard. No review
phase — the prototype is discarded, and its answer is reviewed where a plan
uses it.

The prototype is committed on the current branch like any other change and
removed in the next commit, so history keeps it: the brief's entry records
the commit, and whoever implements the real thing reads the prototype with
`git show <hash>`. There is no option to keep it.

## Trigger Phrases

Use this skill when the user asks to **settle a question by building
something before planning**, using phrases like: "prototype this", "spike
this question", "build a quick prototype to find out", "try it out before we
plan", "answer the open question in the brief", "做个原型",
"先做个原型验证一下", "写个原型试试", "用原型回答这个问题",
"原型验证一下这个问题", or invokes `/kenspc-prototype` directly.

Avoid triggering this skill when the user:

- Asks for a feature to keep ("just build it", "直接做这个功能", a demo for
  a client) — use generate-plan or generate-task, or work directly for a
  small change.
- Asks to run or try out a snippet ("帮我试一下这段代码", "run this and see
  what it prints") — just run it, no skill needed.
- Reports a bug ("this crashes when") — use diagnose-bug instead.
- Asks a question discussion can settle ("which library is better?") —
  discuss it directly, or use generate-brief when the idea is still rough.

Why: the skill commits twice and may use a development database, so a false
trigger costs more than a missed one.

## Quality bar

A useful prototype is the smallest thing that settles its question, and its
evidence could have come out the other way: it is measured against the
entry's `Settled by:` result, or it carries a control that fails when the
claim is false. It fails the bar in two named ways: a prototype that only
shows its happy path settles nothing, and one that grows past its question
is feature work.

## Prerequisites

- A project in a git repository. Why: the skill commits the prototype and
  its removal, and the brief records the commit that holds the prototype.
- A requirement brief (its first line `# Requirement Brief:`). Why: the
  answer is written where generate-plan reads it, and a brief written only
  to hold one question would reach generate-plan with every discovery
  dimension a gap — more than its one-to-two-round gap-check is for.

## Arguments

$ARGUMENTS format: BRIEF [ENTRY]

- BRIEF: the path to a requirement brief. When the first token looks like a
  file path (starts with `./` or `/`, or ends with `.md`), it is BRIEF and
  the rest is ENTRY; otherwise the whole input is a question with no brief.
- ENTRY: optional — a number in the brief's `## Open Questions`, or a
  question's text.

A question with no brief path — or a path that names no file, or a file that
is not a requirement brief: stop, build nothing, say which, and suggest
`/kenspc-brief` to write a brief that holds the question.

No arguments: ask for the brief and the question. In a session that cannot
ask (a system reminder to work without stopping), stop; nothing is built.

## Phase 1: Frame

**Goal**: one question, the result that settles it, the kind (logic, UI,
feature), the location, and the resources — with every gate below passed.

**Inputs**: the brief; the project's CLAUDE.md, README, and config files,
read silently first — they name the stack, the commit conventions, a
prototype location, and the development database. Before writing anything,
note what `git -c core.quotePath=false status --porcelain -uall` lists, so
the run can tell its own files from the user's and knows which tracked files
have uncommitted changes.

**DONE when** the frame is shown to the user — the question, its
`Settled by:`, the kind, the location, and the resources (a database, a
dependency, the tracked files an in-app prototype modifies) — and no gate is
open. There is no general confirmation: the skill shows the frame and goes
on. Why: each risky choice has its own gate with its own question, and a
blanket confirmation adds a stop to the path that needs none.

**Constraints**: this phase writes nothing but the brief entry appended for
a question given as text. Why: until the frame is settled, nothing the run
might build has a location or a question to answer.

### The question

- The question is the entry ENTRY names, by its number or its text. With no
  ENTRY, it is the brief's only `` `needs prototype` `` entry; with several,
  ask which. In a session that cannot ask (a system reminder to work
  without stopping), take the first in document order and name it in the
  final message. With none, ask for the question, as with no arguments. In
  a session that cannot ask (a system reminder to work without stopping),
  stop; nothing is built.
- A named `` `answered` `` entry: ask whether to prototype it again. In a
  session that cannot ask (a system reminder to work without stopping),
  stop; nothing is built. Why: the entry already holds an answer and the
  commit behind it, and replacing them is the user's decision.
- A named `` `open` `` entry is prototyped like any other. Why: naming it is
  the user's decision that an experiment can settle it.
- A question given as text that the brief lacks is appended to its
  `## Open Questions` as a `` `needs prototype` `` entry before anything is
  built — replacing a body of `none`, and creating the section when the
  brief has none, after `## Context` and before `## Discovery Notes`, where
  the brief template places it. Why: the answer needs an entry to be written
  into, and generate-plan reads entries, not prose.
- An entry with no `Settled by:` gets one derived from the question, shown
  in the frame and written with the entry in Phase 3. Why: the evidence is
  measured against a result named before the prototype runs, which cannot
  be bent to fit what the run showed.

The entry grammar — the status words, the labels, and their order — is
written once, in the Writing rules for the brief in
`${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md`. Read it there.

### Kind and location

- The location is `prototypes/<slug>/` at the repository root
  (`git rev-parse --show-toplevel`), `<slug>` a short kebab-case name for
  the question, unless the project's CLAUDE.md names another. An existing
  `prototypes/<slug>/` holding only leftovers of an earlier run — files git
  does not track — is not a conflict: the next free `<slug>-<n>/` is used.
  Why: after a first prototype, `prototypes/` exists in every repository
  that used the skill, and asking whenever it exists would ask on every
  later run.
- A location conflict is asked about: `prototypes/` already holds tracked
  files that are not prototypes, or CLAUDE.md's location does not fit the
  kind (an outside-the-app location for a UI prototype that can only render
  in the app — the in-app rule below then decides). In a session that
  cannot ask (a system reminder to work without stopping), take the default
  location and name it in the final message.
- A logic or UI prototype that runs on its own goes to the location.
- A UI prototype that can only render inside the app is the one in-app
  kind: its location comes from CLAUDE.md, or is asked. In a session that
  cannot ask (a system reminder to work without stopping), with no
  CLAUDE.md location, nothing is built and the entry stays unsettled with
  the reason. Why: no default location inside someone's app is defensible,
  and a guessed one is an edit to the user's source tree nobody chose.
- A feature prototype that needs the app's runtime runs outside the app,
  from the location, importing the app's modules, when that lets it run.
  Otherwise it is not built, in either kind of session: the entry stays
  `` `needs prototype` `` with the reason in `Evidence:`, and the exit says
  that widening the in-app exception to features is the user's decision.
  Why: the in-app exception exists for what can only render inside the
  app, and anything that can run elsewhere keeps its files out of the
  user's source tree.

### An in-app UI prototype

A tracked file the prototype must modify that has uncommitted changes (the
status noted at the start shows them), and any change to the project's
manifest, are asked about: go on, commit first, or stop. In a session that
cannot ask (a system reminder to work without stopping), nothing is built,
and the entry stays unsettled with the reason. Why: the add commit would
carry the user's uncommitted changes in that file and the remove commit
would take them out of the tree, and a manifest change alters what the
project builds.

### Database

- The development database is recognized by name only: a development-named
  configuration file (`appsettings.Development.json`, `.env.development`,
  `.env.development.local`), the project's user-secrets, or a development
  database the project's CLAUDE.md or README names. Any other connection is
  asked about: may it be used. In a session that cannot ask (a system
  reminder to work without stopping), it is not used. Production resources
  are never touched. Why: an unsuffixed `.env` or `appsettings.json` can
  point at production, and a name is the one signal the skill can check.
- A new table or column on the development database gets the warning — the
  development database may be the wrong place for it — and the
  recommendation of a throwaway database, before any code is written; the
  user decides. In a session that cannot ask (a system reminder to work
  without stopping), a throwaway database is used and named in the final
  message. A user who insists on the development database is recorded in
  `Evidence:`, and a teardown script that drops what the prototype created
  goes with the prototype. Why: other work runs against the development
  database, and a schema change left there changes what it runs against.
- Rows written to existing development tables get no warning and no
  teardown; `Evidence:` names each such table. Why: the development
  database is there to be used, and the named tables tell the user which
  development data changed.
- No migration file is added and none is applied, with any migration tool.
  Why: the project's migration history belongs to the product, and a
  prototype's migration would stay in it after the prototype is gone.
- Credentials and connection strings are read by name at run time —
  configuration keys, environment variables, or a secret store — and never
  printed, and no file holding a value read from configuration (a `.env`, a
  copied `appsettings.*.json`) is committed. Why: history keeps every
  prototype, so a committed secret is permanent.

### Dependencies

Outside the app, a dependency goes into the prototype's own manifest under
the location, never into the project's. For a UI prototype in the app, a
dependency the app has to load is a manifest change and is asked about, as
above. Why: the library under evaluation is often the question itself, and
installed where only the prototype sees it, it changes nothing the project
builds.

### The gates

Every question the skill asks is one of these gates. The frame's gates come
in this phase; the judgment and commit gates come later. The last column is
what a session that cannot ask does in place of asking.

| Gate | Asks | In a session that cannot ask |
|---|---|---|
| No arguments | Which brief and which question | Stop; nothing is built |
| No brief | — | Stop; suggest `/kenspc-brief`; nothing is built |
| Several `needs prototype` entries, none named | Which one | The first in document order, named in the final message |
| The named entry is `answered` | Prototype it again? | Stop |
| A location conflict | Where | The default location, named in the final message |
| A UI prototype that can only render in the app, and CLAUDE.md names no location | Where in the app | Nothing is built; the entry stays unsettled with the reason |
| A UI prototype in the app: a tracked file with uncommitted changes, or the project's manifest | Go on, commit first, or stop | Nothing is built; the entry stays unsettled with the reason |
| A feature prototype that needs the app's runtime and cannot run outside it | — | Nothing is built, in either kind of session; the entry stays unsettled with the reason, and the exit says widening the exception is the user's decision |
| A connection the development configuration does not name | May it be used | It is not used |
| A new table or column on the development database | The warning and the throwaway recommendation; the user decides | The throwaway database, named in the final message |
| The answer is the user's judgment | Look at the prototype and give a verdict | Unsettled; `Evidence:` says what to look at and how |
| A commit fails | How to go on | Stop and report |

## Phase 2: Build and run

**Goal**: the prototype, run, its evidence gathered, and committed.

**Inputs**: the frame shown in Phase 1.

**DONE when** the add commit exists and the evidence either settles the
question against `Settled by:` or shows why it cannot be settled here; for a
UI prototype in the app, the typecheck is green against its baseline. The
add commit is `chore: add prototype <slug>`, adapted to the project's commit
conventions, made after the run that produced the evidence. It stages only
the prototype's own paths — its source, its manifest and lockfile, evidence
files the answer cites, and for a UI prototype in the app the tracked files
the frame named; never installed dependencies or build output — and passes
them to `git commit` as a pathspec. Why after the run: the commit's hash has
to name what produced the evidence. Why the pathspec: it keeps anything the
user has staged out of the commit.

**Constraints**:
- Everything is written under the location, except the in-app tracked
  files the frame named; the prototype's database file, build output, and
  installed dependencies stay under the location too. Why: the remove
  commit and the exit's leftovers list cover the location, and a file
  written elsewhere would outlive the discard unnoticed.
- File names follow the naming rule of the Scratch space bullet in the
  run-directory preparation of
  `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` — the block between
  `<!-- canonical:run-dir:start -->` and `<!-- canonical:run-dir:end -->` —
  read there, not copied here: no name the project's test runner collects.
  A prototype that uses the runner as its harness runs it with a config of
  its own under the location. Why: the prototype is committed where the
  project's gates can walk, and a collectable name there is a test the user
  did not write.
- None of the project's build, test, or lint commands runs on the
  prototype, and the project's configuration is not edited to exclude it.
  For a UI prototype in the app, only the project's typecheck runs,
  unmodified: once before building, as a baseline, and again before the add
  commit, green — or, when the baseline was already red, with no error the
  baseline lacked. Why: the prototype is not held to the project's gate, a
  configuration change made for the plugin's own files is the user's
  decision, and a run cannot turn green a typecheck that was red before it.
- Before the add commit, read the staged file list and the staged diff.
  Passing: no staged file holds a value read from configuration. It fails
  on a `.env` file, a copied `appsettings.*.json`, or a connection string or
  key written into the prototype's source; such a file or line is taken out
  before the commit. Why: history keeps every prototype, so the look at the
  diff the skill staged itself is the last point a secret can be kept out.
- A commit that fails — a commit hook rejects it, or git refuses the
  pathspec — stops the run: report the error and ask the user how to go on.
  Do not retry, and do not bypass the hook with `--no-verify`. In a session
  that cannot ask (a system reminder to work without stopping), stop and
  report. Why: the hook encodes the project's rules, and a bypass the user
  did not choose changes how their repository is guarded. When the add
  commit is the one that failed, the prototype's paths are still staged,
  and a plain `git commit` would carry them: the report names those paths,
  gives the evidence the run gathered, and gives
  `git reset -q -- <those paths>`, which unstages them and leaves the files
  in place. Why: a prototype swept into the user's next commit lands under
  their message, and no remove commit ever follows it.

### The judgment point

When the answer is the user's judgment — how a UI feels, whether a flow
reads right — after the add commit the skill says how to see the prototype
(a command, a route) and waits. The user's verdict is the Answer, and
`Evidence:` says it was judged by the user and on what. In a session that
cannot ask (a system reminder to work without stopping), the prototype is
committed and discarded, the entry stays `` `needs prototype` `` with
`Evidence:` naming what to look at and how, and the exit says so. Why: a
judgment the agent makes for the user is a guess recorded as an answer, and
before the discard is the only time the user can see the prototype running
without restoring it from history.

## Phase 3: Record and discard

**Goal**: the answer in the brief and the prototype out of the tree.

**Inputs**: the add commit's hash and the evidence from Phase 2; the entry
grammar in the Writing rules for the brief in
`${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md`.

**DONE when**:
- The entry is rewritten per that grammar — `` `answered` `` with
  `Answer:`, `Evidence:`, and the Prototype line, or, unsettled,
  `` `needs prototype` `` with `Evidence:` and `Prototype:` — and nothing
  else in the brief changed. The Prototype line names the add commit and the
  location:
  ``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` ``.
  Why: the rest of the brief is the user's discovery record.
- At the judgment point, the user's verdict came first.
- The teardown ran, when there was one, and the tables it created are gone.
- The remove commit exists — `chore: remove prototype <slug>`, adapted to
  the project's commit conventions, its body carrying `Question:`,
  `Answer:` or `Not settled:`, and `Prototype: <hash>` — as one commit:
  `git rm` for the paths the add commit added, and for the paths it
  modified their content in the add commit's parent
  (`git checkout <add commit>^ -- <path>`), every path passed to
  `git commit` as a pathspec.
- `git diff <add commit>^ HEAD -- <every path the add commit touched>`
  prints nothing.
- The brief is not committed.

Why the discard comes in the same run: each commit the prototype spends in
HEAD is one whose gates can see it, and restoring a modified file is exact
only while nothing else has touched it. Why the brief stays uncommitted:
generate-brief and diagnose-bug leave their briefs uncommitted too, and the
remove commit's body keeps the answer and the hash in history.

**When nothing was built** — a gate ended in "nothing is built": no commit
is made; the entry stays `` `needs prototype` `` and gains `Evidence:` with
the reason, and no `Prototype:`.

## Exit

The final message gives:

- the answer, or why the question is unsettled — for a feature prototype
  that was not built, that widening the in-app exception to features is the
  user's decision; for a judgment the session could not ask for, what to
  look at and how;
- the add and remove commits, and `git show <hash>` to read the prototype;
- every path that `git status --porcelain --ignored -uall -- <location>`
  still lists — ignored and untracked alike — for the user to remove;
- every default a session that cannot ask took in place of a question.

Next step: `/kenspc-plan <brief>` when no `` `needs prototype` `` entry
remains in the brief, otherwise `/kenspc-prototype <brief> <n>` for the
next. The skill invokes nothing and deletes nothing. Why: the user decides
when to plan, and a recursive delete is what users' permission rules deny.

**Ending with the prototype still in the tree.** When the run stops after
the add commit and before the remove commit — a rejected remove commit, the
user stopping at the judgment point — the last message names the add
commit, says the prototype is still in the tree, and gives the commands that
would remove it: `git rm -- <each path the add commit added>`, and for an
in-app prototype `git checkout <add commit>^ -- <each path it modified>`,
then the remove commit. The skill does not run them unasked. Why: like
diagnose-bug's "Ending without a document", the branch carries something
the user did not plan to keep.

## Writing rules

- The conversation is in the conversation's language.
- The brief entry is in the brief's language, with its status words and
  labels exactly as written. Why: generate-plan finds an unresolved entry by
  its status word, and a translated one breaks the chain without an error.
- Commit messages and identifiers are in English.
- No branch, pull-request, rebase, or tag step: the commits land on the
  current branch. Why: the prototype is committed like any other change,
  and a git step nobody asked for is a decision the user did not make.

## Phase transitions

Each phase starts from the artifact the previous one produced, not from the
wording that closed it:

- Phase 1 → Phase 2: the shown frame. A gate that ended in "nothing is
  built" goes straight to the entry's rewrite in Phase 3, with no commit.
- Phase 2 → Phase 3: the add commit's hash.
- The exit: the rewritten entry and the remove commit.

Why: a phase's closing sentence has been read as the end of a whole skill
run; the next phase reads an artifact, so the artifact is what moves the run
forward.
