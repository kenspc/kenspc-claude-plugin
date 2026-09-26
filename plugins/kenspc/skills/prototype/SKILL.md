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
- A requirement brief, recognized as generate-plan recognizes one — the
  test in Phase 1 Step 1 of
  `${CLAUDE_PLUGIN_ROOT}/skills/generate-plan/SKILL.md`. Why: the answer is
  written where generate-plan reads it, a file generate-plan read as a
  brief is where its exit sends the user, and a brief written only to hold
  one question would reach generate-plan with every discovery dimension a
  gap — more than its one-to-two-round gap-check is for.

## Arguments

$ARGUMENTS format: BRIEF [ENTRY]

- BRIEF: the path to a requirement brief. When the first token looks like a
  file path (starts with `./` or `/`, or ends with `.md` or `.txt`, as
  generate-plan decides), it is BRIEF and the rest is ENTRY; otherwise the
  whole input is a question with no brief.
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

**DONE when** the frame has gone to the user as a message of its own, sent
before the prototype's first file is written, and no gate is open. The frame
names, in this order, the question, its `Settled by:`, the kind, the
location, and the resources (a database, a dependency, the tracked files an
in-app prototype modifies). It is sent whether or not a gate stops the run: a
gate that asks once the question is chosen puts its question in the same
message, after the frame. The frame is not a confirmation, and there is no
general one: once it is sent, the skill goes on. Why a message of its own:
with no gate to stop the run, a frame that is only to be shown gets folded
into the work of building, and no message names where the prototype will
write or which tracked files it will change before the writing starts; the
frame is the one place the user sees them before anything is built. Why no
confirmation: each risky choice has its own gate with its own question, and
a blanket confirmation adds a stop to the path that needs none.

In a session that cannot ask (a system reminder to work without stopping),
a gate on the entry the run takes — named, or taken with no ENTRY — stops
the run in place of asking, and the frame still goes first, as a message of
its own; the stop follows it as the last message, which names the entry and
the status word found, or says there is none, and says why the run stopped.
Nothing is written to the brief and nothing is committed: a `Settled by:`
derived for the entry is shown in the frame as in any frame, and not
written, since the gate comes before that write. A stop before any entry is
known — no arguments, no brief, an entry number that names no entry, no
`` `needs prototype` `` entry to take — has no question to frame and sends
none. Why: the frame is the one place the user sees the question, the
location, and the resources before anything happens, and a stop that asks
nothing has no question for the frame to come before; sent without it, the
last message refers to a frame the user was never shown.

**Constraints**: this phase writes nothing but the brief entry appended for
a question given as text and a `Settled by:` derived for an entry that
lacks one. Why: until the frame is settled, nothing the run might build has
a location or a question to answer. The gates on the entry the run takes,
named or not, come before either of those writes. Why: a stop after a write has changed the
brief it stopped to protect, and the brief is not committed, so no git
command restores it.

### The question

- The question is the entry ENTRY names, by its number or its text. With no
  ENTRY, it is the brief's only `` `needs prototype` `` entry; with several,
  ask which. In a session that cannot ask (a system reminder to work
  without stopping), take the first in document order and name it in the
  final message. With none, ask for the question, as with no arguments. In
  a session that cannot ask (a system reminder to work without stopping),
  stop; nothing is built.
- An ENTRY that is a bare number is an entry number, never question text.
  One that names no entry — past the last, or in a brief whose section is
  `none` or missing — stops the run: say so, list the brief's entries, and
  leave the brief unchanged. Why: a number appended as a question would add
  an entry nobody asked for, and taking another entry would answer a
  question the user did not name.
- An entry the run takes — named by ENTRY, or taken with no ENTRY as above
  — that is `` `answered` ``, or that holds `Answer:` whatever its status
  word: ask whether to prototype it again. In a session that cannot ask (a
  system reminder to work without stopping), stop after the frame, as
  Phase 1's DONE when says, and leave the entry unchanged: the rewrite in
  Phase 3 for a run in which nothing was built does not apply to it. Why:
  the entry already holds an answer, and the
  commit behind it when it has a Prototype line; Phase 3 would replace them
  whatever the status word says, and replacing them is the user's decision.
  An entry taken without being named is the one the user looked at least,
  so its answer is the easiest to lose unasked. On "yes", an entry that
  held `Answer:` when the run began is rewritten only when the new attempt
  settles the question. Every other ending — nothing built, a built
  prototype whose evidence does not settle it, a verdict the user does not
  give — leaves its `Answer:`, `Evidence:`, and Prototype line as they
  were, and the final message names the new attempt's commits, when it
  made any, and why the question was not settled. The one change such an
  entry can carry out of the run is the `Settled by:` derived for it below
  when it had none. Why: a "yes" consents to replacing the answer with a
  new answer, and an unsettled attempt yields evidence, not an answer; the
  brief has no committed copy to restore the old one from. A `Prototype:`
  line with no `Answer:` under `` `needs prototype` `` is the form an
  unsettled attempt leaves, and such an entry is prototyped again like any
  other.
- A named entry whose status word is none of `` `open` ``,
  `` `needs prototype` ``, and `` `answered` `` — hand-edited, translated,
  or missing: one that holds `Answer:` or `Prototype:` takes the question
  above; otherwise ask, quoting the word found (or saying there is none),
  whether to prototype it or stop. A "stop" here, or a "no" to the question
  above, ends the run with the entry unchanged: the rewrite in Phase 3 for a
  run in which nothing was built does not apply to it. In a session that
  cannot ask (a system reminder to work without stopping), stop after the
  frame and leave the entry unchanged, as above; the last message names
  the entry and quotes the word found, or says there is none, since the
  word is what stopped the run. On "prototype it", the entry is prototyped
  as a named `` `open` `` entry is, and Phase 3 writes a status word the
  grammar knows. Why: the
  skill tells an answered entry from an unsettled one by its status word,
  so an entry whose word it cannot read may hold an answer that Phase 3
  would replace; the brief is not committed, so the
  earlier answer would then survive only in an earlier remove commit's body.
- A named `` `open` `` entry is prototyped like any other. Why: naming it is
  the user's decision that an experiment can settle it.
- A question given as text that the brief lacks is appended to its
  `## Open Questions` as a `` `needs prototype` `` entry before anything is
  built — replacing a body of `none`, and creating the section when the
  brief has none, after `## Context` and before `## Discovery Notes`, where
  the brief template places it. Why: the answer needs an entry to be written
  into, and generate-plan reads entries, not prose.
- An entry with no `Settled by:` gets one derived from the question, shown
  in the frame and written into the entry before anything is built — with
  the entry, for a question appended as text. Why: the evidence is
  measured against a result named before the prototype runs, which cannot
  be bent to fit what the run showed, and a brief's `` `needs prototype` ``
  entry carries `Settled by:` even when the run stops before Phase 3.

The entry grammar — the status words, the labels, and their order — is
written once, in the Writing rules for the brief in
`${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md`. Read it there.

### Kind and location

- The location is `prototypes/<slug>/` at the repository root
  (`git rev-parse --show-toplevel`), `<slug>` a short kebab-case name for
  the question, unless the project's CLAUDE.md names another. An existing
  `prototypes/<slug>/` holding only leftovers of an earlier run — files git
  does not track — is not a conflict: the next free `<slug>-<n>/` is used.
  One holding the tracked files of an earlier prototype that was never
  removed — a run that ended between its two commits — is not written into
  either: the next free `<slug>-<n>/` is used, and the final message names
  that earlier prototype as still in the tree. Why: after a first
  prototype, `prototypes/` exists in every repository that used the skill,
  and asking whenever it exists would ask on every later run; and a run
  that wrote into an earlier prototype's files would restore them in its
  own remove commit, leaving that prototype in HEAD unnamed.
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
  `` `needs prototype` `` with the reason in `Evidence:` (an entry that held
  `Answer:` when the run began is left as it was, gaining at most a derived
  `Settled by:`, as § The question says), and the exit says that widening
  the in-app exception to features is the user's decision.
  Why: the in-app exception exists for what can only render inside the
  app, and anything that can run elsewhere keeps its files out of the
  user's source tree.
- Once the location is chosen, and before anything is written there, note
  what
  `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`
  lists; the exit leaves those paths out of its leftovers list.

### An in-app UI prototype

A tracked file the prototype must modify that has uncommitted changes (the
status noted at the start shows them), and any change to the project's
manifest, are asked about: go on, commit first, or stop. The question says
what going on does to such a file: the add commit carries its uncommitted
changes, mixed with the prototype's, and the remove commit takes both out
of the tree, so those changes then live only in the add commit. When the
user goes on, the final message names each such file and
`git show <add commit>:<path>` to read it. In a session that cannot ask (a
system reminder to work without stopping), nothing is built, and the entry
stays unsettled with the reason. Why: the add commit would carry the user's
uncommitted changes in that file and the remove commit would take them out
of the tree, and a manifest change alters what the project builds.

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
| The entry the run takes, named or taken with none named, is `answered`, holds `Answer:`, or has an unrecognized status word and holds `Prototype:` | Prototype it again? | Stop after the frame; the entry unchanged |
| The named entry's status word is not recognized, and it holds neither `Answer:` nor `Prototype:` | Prototype it, or stop | Stop after the frame; the entry unchanged |
| A location conflict | Where | The default location, named in the final message |
| A UI prototype that can only render in the app, and CLAUDE.md names no location | Where in the app | Nothing is built; the entry stays unsettled with the reason |
| A UI prototype in the app: a tracked file with uncommitted changes, or the project's manifest | Go on, commit first, or stop | Nothing is built; the entry stays unsettled with the reason |
| A feature prototype that needs the app's runtime and cannot run outside it | — | Nothing is built, in either kind of session; the entry stays unsettled with the reason (one that held `Answer:` is left as it was, gaining at most a derived `Settled by:`, as § The question says), and the exit says widening the exception is the user's decision |
| A connection the development configuration does not name | May it be used | It is not used |
| A new table or column on the development database | The warning and the throwaway recommendation; the user decides | The throwaway database, named in the final message |
| The answer is the user's judgment | Look at the prototype and give a verdict | Unsettled; `Evidence:` says what to look at and how |
| A commit fails | How to go on | Stop and report |

## Phase 2: Build and run

**Goal**: the prototype, run, its evidence gathered, and committed.

**Inputs**: the frame message Phase 1 sent.

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
  A red baseline is a typecheck that ran and reported errors. One that did
  not run — the command is missing, the dependencies are not installed, the
  tool stopped before checking — is no baseline: nothing is built, and the
  entry stays unsettled with the reason (an entry that held `Answer:` when
  the run began is left as it was, gaining at most a derived
  `Settled by:`, as § The question says). Why: a check that
  cannot run fails the same way after the build, so comparing the two would
  pass any edit.
- Before the add commit, read the staged file list and the staged diff.
  Passing: no staged file holds a value read from configuration. It fails
  on a `.env` file, a copied `appsettings.*.json`, or a connection string or
  key written into the prototype's source; such a file is unstaged, and
  such a line is deleted from its file, not only left out of the staged
  diff, before the commit. A file taken out stays on disk under the
  location, so the exit's leftovers list marks it as holding a
  configuration value. Why: history keeps every prototype, so the look at
  the diff the skill staged itself is the last point a secret can be kept
  out; a file left behind unmarked looks like any other leftover until a
  later `git add -A` commits it; and a line only left unstaged stays in
  the working file, where the check before the discard reads it as an edit
  made after the add commit and the user is told to save or commit it.
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
  Why: the rest of the brief is the user's discovery record. The unsettled
  rewrite has one exception: an entry that held `Answer:` when the run
  began, and that this run did not settle, is left as it was — status
  word, `Answer:`, `Evidence:`, and Prototype line — gaining at most the
  `Settled by:` Phase 1 derived for it, and the final message names this
  run's commits and why the question was not settled, as § The question
  says.
- At the judgment point, the user's verdict came first.
- The teardown ran, when there was one, and the tables it created are gone.
  A teardown that fails, or leaves a table or column the prototype created,
  stops the run before the remove commit: the last message gives the error
  and names what is still there, and the run ends with the prototype still
  in the tree (see the Exit), its teardown script with it. Why: a schema
  change left on the development database changes what other work runs
  against, and the script is the record of what to drop.
- Before the discard touches a path,
  `git -c core.quotePath=false status --porcelain -- <every path the add commit touched>`
  and
  `git -c core.quotePath=false diff --name-only <add commit> HEAD -- <every path the add commit touched>`
  each exit 0 and print nothing. A path either lists changed after the add
  commit — an edit made while the run waited for a verdict, committed or
  not — and the run stops before the discard, naming that path, and ends
  with the prototype still in the tree (see the Exit). A nonzero exit is an
  error, not an empty list, and stops the run the same way. Why:
  `git checkout` overwrites an uncommitted edit without a word, and that
  edit has no copy anywhere else; an edit committed after the add commit
  shows in no status, and the remove commit would revert it under the
  prototype's message while the check after it still passes.
- The remove commit exists — `chore: remove prototype <slug>`, adapted to
  the project's commit conventions, its body carrying `Question:`,
  `Answer:` or `Not settled:`, and `Prototype: <hash>` — as one commit:
  `git rm` for the paths the add commit added, and for the paths it
  modified their content in the add commit's parent
  (`git checkout <add commit>^ -- <path>`), every path passed to
  `git commit` as a pathspec.
- `git diff <add commit>^ HEAD -- <every path the add commit touched>`
  exits 0 and prints nothing. It fails on a nonzero exit, whose empty
  output is an error and not an empty diff. When the add commit is the
  repository's first commit, it has no parent and that command cannot
  succeed; `git ls-tree -r HEAD -- <every path the add commit touched>`
  printing nothing is the check instead.
- The brief is not committed.

Why the discard comes in the same run: each commit the prototype spends in
HEAD is one whose gates can see it, and restoring a modified file is exact
only while nothing else has touched it. Why the brief stays uncommitted:
generate-brief and diagnose-bug leave their briefs uncommitted too, and the
remove commit's body keeps the answer and the hash in history.

**When nothing was built** — a gate ended in "nothing is built": no commit
is made; the entry stays `` `needs prototype` `` and gains `Evidence:` with
the reason, and no `Prototype:`. An entry that held `Answer:` when the run
began — one a "yes" to the prototype-again question sent on — is the
exception: it is left as it was — status word, `Answer:`, `Evidence:`,
and Prototype line — gaining at most the `Settled by:` Phase 1 derived
for it, and the final message gives the reason nothing was built, as
§ The question says.

**An entry an earlier attempt left unsettled** already carries `Evidence:`,
and `Prototype:` when that attempt committed one. This run's rewrite
replaces them rather than adding a second of either, and its `Evidence:`
names the earlier attempt's commit when there was one. Why: the grammar
gives each label once, in order, and the earlier prototype stays readable
through the commit the new `Evidence:` names.

## Exit

The final message gives:

- the answer, or why the question is unsettled — for a feature prototype
  that was not built, that widening the in-app exception to features is the
  user's decision; for a judgment the session could not ask for, what to
  look at and how;
- the add and remove commits, and `git show <hash>` to read the prototype;
- what
  `git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`
  still lists — ignored and untracked alike, a non-ASCII name as it is and
  not octal-escaped — for the user to remove, less the paths it listed when
  the location was chosen. A directory that matches an ignore pattern
  (`node_modules/`, `bin/`, `obj/`) comes back as one line. A directory of
  which every file is listed as untracked, none of them on that earlier
  list, and for which `git ls-files -- <directory>` prints nothing, is
  named once — the outermost such directory — with its file count; a file
  marked as holding a configuration value is still named on its own.
  Why: an in-app location is a directory of the user's app, and a file of
  theirs already there is not the prototype's to name for removal; the
  list never shows a tracked file, so only `git ls-files` tells a directory
  of new files from one that also holds the app's; and a list that runs to
  thousands of lines after a dependency install is cut short or goes
  unread, so it no longer names what is left;
- every default a session that cannot ask took in place of a question.

Next step: `/kenspc-plan <brief>` when no `` `needs prototype` `` entry
remains in the brief, otherwise `/kenspc-prototype <brief> <n>` for the
next. The next is an entry other than the one this run left unsettled; when
that entry is the only one remaining, the suggestion is
`/kenspc-plan <brief>`, whose exit asks whether to prototype it again or
carry it into the plan. The skill invokes nothing and deletes nothing. Why:
the user decides when to plan, a re-run suggested for the entry this run
could not settle would most often end the same way, and a recursive delete
is what users' permission rules deny.

**Ending with the prototype still in the tree.** When the run stops after
the add commit and before the remove commit — a rejected remove commit, the
user stopping at the judgment point, a teardown that failed, a path that
changed before the discard — the last message names the add commit, says
the prototype is still in the tree, and gives the commands that would
remove it: `git rm -- <each path the add commit added>`, and for an in-app
prototype `git checkout <add commit>^ -- <each path it modified>`, then the
remove commit. After a teardown that failed, the message says to finish the
teardown first: `git rm` takes its script, the record of what to drop, out
of the tree. When the check before the discard stopped the run, the paths
it listed are left out of those commands and named apart, as holding an
edit made after the add commit, and the message tells the user to save or
commit that edit, then take the prototype out of each such path by hand:
delete a path the add commit added, and bring a path it modified back to
its content in the add commit's parent (`git show <add commit>^:<path>`),
re-applying the edit when it is to stay. Why: on such a path `git rm`
refuses a local modification or deletes a committed edit, and
`git checkout` overwrites the edit without a word, so a command given for
it would fail or destroy the edit the check stopped for; and a path the add
commit modified is a file of the app, which deleting would remove. When
the remove commit is the one rejected, those commands have already run and
the removal is staged: the message says so, says a plain `git commit`
would carry the removal under another message, and gives the `git commit`
command the skill ran, which finishes the removal once the rejection is
dealt with. The skill does not run them unasked. Why: like diagnose-bug's
"Ending without a document", the branch carries something the user did not
plan to keep.

## Writing rules

- Match the user's language in the conversation.
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

- Phase 1 → Phase 2: the frame message, sent before any prototype file is
  written. A gate that ended in "nothing is built" goes straight to the
  entry's rewrite in Phase 3, with no commit.
- Phase 2 → Phase 3: the add commit's hash.
- The exit: the rewritten entry and the remove commit.

Why: a phase's closing sentence has been read as the end of a whole skill
run; the next phase reads an artifact, so the artifact is what moves the run
forward.
