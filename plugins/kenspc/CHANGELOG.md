# Changelog

> **Note on v1.x entries:** Entries for v1.0.0 through v1.5.0 were
> backfilled from git history on 2026-05-11. The original releases shipped
> without CHANGELOG documentation — the project was a single-maintainer
> dogfooding effort during the v1.x line, with version bumps recorded only
> in `plugin.json` and commit messages. The backfilled entries reconstruct
> Added/Changed/Removed scope from commit messages and `git diff`; for the
> authoritative source, see git log between commits `871c7e3` (initial,
> 2026-03-29) and `7328cec` (v1.5.0 docs, 2026-05-04).

## 4.1.0 — unreleased

Batch H. From v2.1.277 Claude Code reads AGENTS.md on its own, through its
built-in agents-md plugin, and that left two things in the plugin wrong.
init-project said an AGENTS.md without the `@AGENTS.md` import is not
loaded. Every other skill and agent looked for a project's conventions in
CLAUDE.md alone, although a Read of that file shows only the import line,
and a repository with only AGENTS.md has no CLAUDE.md at all. The plugin
now reads "the project's instruction files": a project's CLAUDE.md and
AGENTS.md files, at the root, in `.claude/`, or in a subdirectory, and the
files a CLAUDE.md imports, whether or not Claude Code loaded them. The term
is defined once, and a new guard holds every copy of it. init-project now
describes AGENTS.md's loading as it was verified on Claude Code 2.1.283 on
2026-09-28:
- with the import, AGENTS.md loads wherever CLAUDE.md loads;
- without it, a CLAUDE.md, `.claude/CLAUDE.md`, or `CLAUDE.local.md` in the
  working directory or above silently stops the default
  `claude-md-or-agents-md` mode from reading AGENTS.md;
- only an imported AGENTS.md fires the InstructionsLoaded hook.

init-project also gets the fixes that batch G's acceptance and a later run
asked for:
- the first message names the conversation language;
- claims in the topic documents need a source;
- commits use the repository's own git identity;
- a skipped file list commits nothing;
- the lockfile, `.gitignore`, and README contents of its commits are
  settled.

Guard counts: `guards run: 11`, `self-tests run: 10`.

### Added

- **The project's instruction files.** `shared/instruction-files.md` holds
  the definition sentence and its Why, and nothing else.
  - No skill or agent reads the file at run time. Each file that uses the
    term carries the sentence once, next to its first use:
    - the eleven agents (in the five reviewers, inside the drift-guarded
      PREREQUISITES);
    - `shared/code-craft-principles.md`;
    - all ten skills;
    - the plugin README.
  - Two carriers hold their copy away from the first use:
    - task-implement and task-review hold it inside the byte-identical
      `canonical:run-dir` block;
    - autopilot holds it in the worker preamble's Read first list, the
      only text a worker reads.
  - Why a copy rather than a reference: every dispatch needs the
    definition. Its working part, "whether or not Claude Code loaded
    them", is exactly what an agent that skipped a runtime Read would get
    wrong. The writer agents inline the code-craft principles for the
    same reason.
- **`scripts/check-instruction-files.sh`.**
  - It takes the sentence from the reference file. It then requires the
    sentence, compared with whitespace normalized, in every file under
    `skills/`, `agents/`, `commands/`, or `shared/` whose text names
    "instruction files", and in the plugin README.
  - Carriers are found rather than listed, so a file that starts using
    the term without the definition fails.
  - Its self-test covers seven paths: the unmodified tree; a changed word;
    a re-wrapped copy; a new carrier without the sentence; the README's
    copy removed; the reference's opening reworded (exit 2); and the
    restoration.
  - Guard counts go from 10 to 11, and self-test counts from 9 to 10.
- **Where to record a structural fact** (task-implement, task-review). When
  CUSTOM_INSTRUCTIONS carried a project structural fact, the final
  report's Next steps names the fact and where to record it. The place is
  the first that applies:
  1. the document that a Documents table in the project's instruction
     files assigns its topic to;
  2. an instruction file with an admission-rule comment, such as the
     AGENTS.md `/kenspc-init` writes, but only when the fact passes that
     rule;
  3. the AGENTS.md a CLAUDE.md imports, with nothing copied into that
     CLAUDE.md;
  4. otherwise CLAUDE.md.

  No report section was added.
- **Known behavior: Claude Code's built-in `/init` after `/kenspc-init`.**
  Do not run it in a project `/kenspc-init` set up.
  - With `CLAUDE_CODE_NEW_INIT=1`, it merges the relevant parts of
    AGENTS.md into CLAUDE.md by design. Its classic flow restated
    AGENTS.md-only rules in CLAUDE.md.
  - Both flows dropped the kenspc pointer line.
  - In a repository with only AGENTS.md, the classic flow wrote a
    CLAUDE.md without the import.
  - The remedy: delete what it copied, and restore the `@AGENTS.md` line
    and the pointer line.

### Changed

- **The plugin reads the project's instruction files for conventions.**
  Every place that looked for conventions in CLAUDE.md, or cited CLAUDE.md
  as the source of a rule, now names the instruction files.
  - **The five reviewers:** PREREQUISITES and the MEDIUM severity
    definition.
  - **quality-reviewer:** its description, scope, and checklist.
  - **code-fixer:**
    - its conventions and MEDIUM definition;
    - a rule that a cited rule counts as absent only after every
      instruction file was searched for it;
    - its worked example row, which now reads
      `NOT APPLICABLE — cited rule in no instruction file`. The mutation
      literal in `check-run-contract.sh`'s self-test follows it.
  - **regression-verifier:** where the build, test, and lint commands are
    configured.
  - **task-implementer:** where its conventions come from.
  - **The three document reviewers:** conventions and commit conventions.
  - **task-document-reviewer:** its third angle is renamed "Consistency
    with the project's instruction files". It checks those files and the
    user-level CLAUDE.md loaded into the session.
  - **plan-document-reviewer, generate-plan, and diagnose-bug:** the
    durable-document fallback is README.md and the instruction files.
  - **generate-brief, generate-task, generate-guide, and prototype:**
    locations and conventions.
  - **autopilot:** version, release, and check conventions, and the worker
    preamble.
  - **task-implement and task-review:** the run-directory `.gitignore`
    commit's convention, and CUSTOM_INSTRUCTIONS item 1.
  - **Unchanged:** the files that name this repository's own CLAUDE.md,
    and `shared/code-craft-principles.md`'s note on where a Think Before
    Coding rule belongs.
- **`check-no-model-names.sh` accepts the `instructionFiles` values.**
  - It strips `claude-md`, `claude-md-or-agents-md`, and
    `claude-md-and-agents-md` before the model-ID rule, as it already
    strips `.claude-plugin`. init-project can therefore name the setting's
    values verbatim.
  - The self-test gains an exit-0 case for the three values and an exit-1
    case for a real model ID beside one of them.
  - The counts are unchanged.
- **init-project and AGENTS.md loading.**
  - **An existing CLAUDE.md.** The final message now reports the two
    files' combined line count on a no or in a session that cannot ask,
    not only on a yes.
    - It also says when AGENTS.md loads without the import: only in the
      `claude-md-and-agents-md` mode of the `instructionFiles` setting, on
      v2.1.277 or later, with the built-in agents-md plugin enabled.
    - And it says that, where both files load, what they repeat takes up
      context twice.
  - **The import line and the kenspc pointer line** stay in every
    CLAUDE.md the skill writes. The Why lists five reasons:
    - that CLAUDE.md, like a teammate's `CLAUDE.local.md`, stops the
      default mode from reading AGENTS.md;
    - no project setting can change the mode;
    - an older version, or a disabled built-in plugin, reads no AGENTS.md;
    - only an imported AGENTS.md fires InstructionsLoaded;
    - a Read of CLAUDE.md shows the import as one line.
  - **Files in `.claude/`.** A `.claude/CLAUDE.md` or `.claude/AGENTS.md`
    counts as the existing file, and no root file is written beside it.
    - The import line is the path from the importing file: `@AGENTS.md`
      side by side, `@../AGENTS.md` from `.claude/CLAUDE.md`, and
      `@.claude/AGENTS.md` the other way. Claude Code resolves an import
      from the importing file's directory: probed on 2.1.283, an
      `@AGENTS.md` in `.claude/CLAUDE.md` did not load the root
      AGENTS.md.
    - Adding the import to `.claude/CLAUDE.md` is asked first, since the
      write needs the user's approval. A session that cannot ask leaves
      the file alone. That line is the one exception to "nothing under
      `.claude/`".
  - **A repository with only AGENTS.md** still gets a CLAUDE.md with the
    import. The final message says why, in one sentence.
  - **"AGENTS.md already loads"** is still decided by the import or a
    symbolic link only, since only those two load it whatever the mode.
- **init-project's other fixes.**
  - **The conversation language.** The first message names it, and every
    question (an AskUserQuestion's header, options, and descriptions
    included) and the final message stay in it.
  - **Durable documents.** They state decisions in their own words and
    name no file under `docs/briefs/`, `docs/plans/`, or `docs/tasks/`.
    AGENTS.md's line on those directories states the convention only, and
    the final message lists any such files the repository already tracks.
  - **A source check.** Before the commit, every topic-document sentence
    without a source (an answer, the argument, or a file) becomes a
    `TBD(init):` marker, and the final message lists each one.
  - **The git identity.** Commits use the repository's own identity, with
    no `-c user.name` or `-c user.email`. When `git var` finds none, the
    run stops before its first commit, in either session.
  - **Empty directories.** A directory whose own `.gitignore` ignores it
    whole counts toward empty.
  - **A skipped file list** commits nothing, as a no does.
  - **The lockfile.** A scaffold whose generator installed nothing gets
    one install, so the lockfile enters the scaffold commit.
  - **A chosen library not yet installed** is written as chosen, not as
    part of the stack.
  - **The README template's documentation list** matches the Documents
    table, and a check holds it.
  - **`.gitignore` lines** that scaffolding adds go into the first
    scaffold commit that needs them. `.kenspc/` and `CLAUDE.local.md` go
    into the documentation commit.
  - **The interview.** An open question is asked on its own, and skipping
    a question and "use the defaults for everything" are separate
    options.
  - The skill grows from 940 to 1028 lines.
- **Documentation.**
  - **CLAUDE.md** describes:
    - the new shared file and guard;
    - the extended `check-no-model-names.sh`;
    - the renamed task-document angle;
    - init-project's added checks;
    - the language anchor;
    - why templates are not named AGENTS.md.
  - **The plugin README:**
    - defines the term under Design Principles;
    - updates Project setup and its Known behavior items;
    - names the instruction files wherever it named CLAUDE.md as the
      source of conventions.
  - **`references/plan-document-example.md`** determines its
    Documentation impact from the instruction files.

### Corrections to the 4.0.0 entry

- **An existing CLAUDE.md.** The 4.0.0 Known behavior item said that,
  without the import line, "Claude Code does not load the new AGENTS.md
  until that line is added". That holds only in the default mode, and in
  the `claude-md` mode. In the `claude-md-and-agents-md` mode, on v2.1.277
  or later, AGENTS.md loads beside CLAUDE.md without the import.
- **A skipped file list commits.** This no longer holds from 4.1.0: a
  skipped list commits nothing.
- **Generated documents can say more than the user gave.** This is now
  checked before the commit, and the item says so.

## 4.0.0 — 2026-09-27

Batch G. An `init-project` skill and its `/kenspc-init [project description]`
command set a project up for the kenspc chain in one run — an empty
directory, a directory of files the user confirms is the project, a new app
inside another repository, or an existing repository, where only the
missing files are written. A scan comes first, then an interview in five
skippable rounds, optional scaffolding with each stack's official
generator, and an optional GitHub repository; the run writes `AGENTS.md` as
the index, a `CLAUDE.md` that imports it, and long-lived topic documents,
marking whatever nobody answered `TBD(init): <what is missing>`, checks
them mechanically, lists them for the user to confirm, and commits. It has
no review phase and no reviewer agent, and every question it asks has a
branch for a session that cannot ask. The version number is the
maintainer's decision; the architecture generation is unchanged, so every
skill, the new one included, keeps `version: 3.0.0`. The two manifests'
descriptions name project initialization. Release-checklist row 1 counts
ten commands, a new row 12 runs `/kenspc-init` in an empty directory,
interactively and headless, and the end-to-end row becomes 13. Known
behavior records what the acceptance found around the files: a generated
document can say more than the user gave, the pair beside an existing
CLAUDE.md is not held to 80 lines, and a skipped file list commits. No new
agent and no new CONTEXT key; `scripts/` is untouched, so the guard counts
are unchanged (`guards run: 10`, `self-tests run: 9`). Release smoke: the
batch's acceptance run, `docs/dry-runs/batch-g-acceptance.md`, on one Linux
container at the tree `aee4311`; no skill, command, or template changed
after it. Its twelve cases, A1–A12 (A10 and A11 optional), ran as sixteen
case runs: seven headless — `claude -p` sessions that loaded the plugin
from the working tree, each a session that cannot ask — and eight in which a
subagent followed the skill's text step by step and sent each of its
questions to the main session, which answered from the case's script; A12
checked the skill's text and ran the pre-flight block. The main session
added A6c, a rerun that answers only the version line's marker. Every case
passed, with no FAIL and no finding. Not exercised within them: a .NET
app's `apps/api/src/` layout (the container has no `dotnet`, and the
missing-tool stop held instead), a generator's nested `.git` moved to
`.trash/` (create-vite runs no `git init`), and a generator's merge into a
`.gitignore` that already exists. Not reached: the paths that need `gh`
installed and logged in — the owner and name question, creating the
repository, reading and creating labels; the push and labels questions in
a session that can ask; the description's natural-language triggers; a
session that loaded the skill and asked a person, since every interactive
half ran as a subagent following the text; and macOS and Windows. The new
row 12's headless half, less its two trigger checks, is case A1's
criteria, which passed in two runs; its interactive half ran only as a
subagent following the text. Rows 1 and 2 were not run as such: every
headless session loaded the plugin with `kenspc:init-project` and
`kenspc:kenspc-init` in its skill list, and none counted the ten commands.
Rows 3–11 and 13 exercise skills and commands this release leaves
unchanged and were not run. Of thirty-seven observations, the batch's
clarification C14 classified six: three behavior deviations — a headless
run's `docs/product.md` stated product claims its argument did not make
(now a Known behavior item), a rerun committed under an identity it set
with `git -c` although one was configured, and a run that stopped ended on
a question and described the user's files; two as designed, now Known
behavior items; and one environment issue. No separate smoke run was made.

### Added

- **The init-project skill and `/kenspc-init`.** `skills/init-project/SKILL.md`
  and `commands/kenspc-init.md` (`disable-model-invocation: true`; the
  skill's description owns the routing, with English and Chinese trigger
  phrases, and excludes questions about Claude Code's built-in `/init` and
  about what "init" means). Eight phases in a fixed order — scan, git,
  interview rounds 1–2, scaffolding, a rescan with rounds 3–5, GitHub and
  the backlog, writing and committing, push and labels: scaffolding comes
  before the documents so the commands are read from real files, the
  GitHub step before them because the backlog convention depends on it,
  and the push last so the first push carries the complete repository.
  Effort follows the session.
  - **Start points.** An empty directory gets `git init` with `main` as the
    first branch (asked; done by default). A directory of files that is not
    a repository is listed, and the run goes on only once the user confirms
    it is the project. A directory inside another repository is asked
    about: a new app of that repository gets only its own AGENTS.md and
    CLAUDE.md pair, with no `git init`; a project of its own is advised to
    move out first. An existing repository gets only the files it lacks. A
    session that cannot ask stops, writing nothing, at the second and
    third. Git is asked before emptiness, from what `git rev-parse` prints
    rather than by comparing paths, so an empty directory inside another
    repository is the third start point; a directory holding only a file
    browser's metadata counts as empty. The run stops in either session,
    writing nothing, in a bare repository, inside a `.git` directory, on a
    detached HEAD, where a `.git` file points nowhere, or where git finds a
    repository it will not read (one another user owns, for example): only
    git's own `not a git repository (or any …` message, read in English
    whatever the locale, counts as no git.
  - **The interview.** In the user's language, five rounds — project;
    shape and stack; UI; delivery; collaboration — each skippable. What the
    argument or the scan answers is not asked, except the repository's
    shape and its hosting, which are confirmed once; "use the defaults for
    everything" ends the interview. The commands are read from
    configuration files, never asked.
  - **Scaffolding.** Offered per app and never done by default. No
    generator command, option, or version is written into the skill: the
    generator's `--help` or documentation is read before it runs. A missing
    SDK or runtime is named, not installed. A monorepo puts each app under
    `apps/<name>/`. A README the generator wrote is replaced with init's
    version after one question; a `.git` directory it created is moved to
    `.trash/` on a yes, with `.trash/` ignored and nothing deleted; a
    `.gitignore` it replaced gets the existing lines back. Each scaffolded
    app is committed alone (`chore: scaffold <app>`) before the
    documentation commit, without the dependency and build directories its
    tools restore, which are appended to `.gitignore`; an app whose `.git`
    stays gets no scaffold commit, and its AGENTS.md pair stays out of
    every commit, a rerun's too, as does that of an app directory that
    already holds a `.git` of its own, which is not offered scaffolding. No
    generator option that overwrites or empties a directory is chosen, and
    a failed generator's output is kept, in place or in `.trash/`.
  - **GitHub and the backlog.** A GitHub repository is offered only when
    there is no remote — private by default, its owner asked every time —
    and is created with its remote set in one step, nothing pushed; without
    `gh` installed and logged in, the skill gives the manual steps. A
    GitHub remote gives backlog A, GitHub Issues labeled `bug`,
    `enhancement`, `debt`, and `found-by-agent` (the last two created only
    on a yes, after the existing labels are read); anything else gives
    backlog C, one file per item under `docs/backlog/`, its format written
    once in `docs/backlog/README.md`, with no status field.
  - **The files.** `AGENTS.md` — an opening comment with the
    `kenspc-init template: 1` marker, the line budget, and the
    three-condition admission rule; then Project, Commands, Rules (twelve at
    most, always with the two safety rules: no deploying to, migrating, or
    reading the data of staging or production, and no secret in the
    repository), Documents (a `Document | Holds | Changes when` table), and
    Workflow (with `Version lives in <file> — rules in docs/release.md`).
    `CLAUDE.md` — `@AGENTS.md` on its first line, then `## Claude Code`.
    `README.md`, `docs/product.md`, `docs/architecture/overview.md`,
    `docs/ui/design-system.md`, `docs/release.md`, `docs/deployment.md`;
    `CHANGELOG.md` only for SemVer or CalVer; `docs/backlog/README.md` for
    backlog C; an AGENTS.md and CLAUDE.md pair for each monorepo app; and
    `.kenspc/` and `CLAUDE.local.md` appended to `.gitignore` where it does
    not already ignore them (a rule in the user's global excludes does not
    count). The templates ship in
    `skills/init-project/templates/` as `*.tmpl`, none named `CLAUDE.md` or
    `AGENTS.md`. The files are in English unless the user
    asks otherwise, with the reason in the skill; the plugin still sets no
    default language for task documents. The root pair the run creates
    stays within 80 lines at init (beside an existing CLAUDE.md, AGENTS.md
    alone does) and each app's pair within 40. Nothing is written under
    `.claude/`, and no guide, CONTRIBUTING, or roadmap file is written;
    AGENTS.md says guides go in `docs/guides/`, written by `/kenspc-guide`.
  - **TBD, checks, and the commit.** A policy nobody answered is
    `TBD(init): …`, never a default. Before the commit the skill checks
    what it wrote — the line budget, CLAUDE.md's first line, AGENTS.md's
    opening comment, that every path in the Documents table exists, that no
    value reads as a secret, the TBD form, and the `.gitignore` lines; a
    failing check is fixed first, and nothing that fails one is committed.
    A line that was there before the run is never changed to pass a check.
    The secret check also reads the user's own lines that the commit would
    put into history for the first time; a file with a secret-looking value
    on such a line stays out of the commit, and the final message names it.
    The file list is confirmed, then committed as
    `docs: initialize project documentation`, following an existing
    repository's written or consistent commit convention; a path git
    ignores is not committed, and a file that held uncommitted changes of
    the user's is marked on the list, and left out of the commit by a
    session that cannot ask. With no file left to commit, no commit is
    made and the run ends there. Push and labels follow the commit, each
    asked separately.
  - **Existing files and reruns.** Nothing that exists is overwritten, and
    a `README*` or `CHANGELOG*` of any name and case counts as existing. An
    existing CLAUDE.md gains only an `@AGENTS.md` first line, on a yes, the
    rest byte-identical, and the combined line count and any visible
    repetition are reported; one that already imports AGENTS.md, or is a
    symbolic link to it, is not asked about. A rerun in a project the skill
    set up changes only the `TBD(init):` markers the user answers — each
    marker ends its line or table cell (the version line's ends before
    `— rules in docs/release.md`), and an answer replaces the marker, not
    the line — and nothing when none remains or none is answered; a rerun
    appends nothing to `.gitignore`.

### Changed

- CLAUDE.md and both READMEs describe the init-project skill and its
  command, and CLAUDE.md counts ten skills. CLAUDE.md's no-review pattern
  gains init-project and what gates it; its layout tree gains the command,
  the skill, and its `templates/` directory; its file-structure conventions
  describe `templates/`; its writing rule on the cannot-ask sentence names
  init-project's gates and interview rounds; and its language rule says
  init-project's English default for the files it writes is separate from
  the task-document rule. The plugin README gains a Project setup section,
  a Setup path in Recommended Workflow, and `gh` under the recommended
  requirements; at release its Known behavior gains two items, generated
  documents that can say more than the user gave and a skipped file list
  that commits, and its existing-CLAUDE.md item says the pair beside that
  file can exceed 80 lines and repeat each other.
- The manifests. `plugin.json` is 4.0.0. The marketplace's description and
  `plugin.json`'s name project initialization (`plugin.json`: AGENTS.md,
  CLAUDE.md, and the project documents); the marketplace entry's
  one-sentence description is unchanged. The design-rules sentence in
  `plugin.json` and in the plugin README's Design Principles reads "The v3
  architecture follows six design rules", so "v3" names the architecture
  generation, not a version. CLAUDE.md's per-skill version paragraph says
  that plugin 4.0.0 was the maintainer's version choice, not an
  architecture rewrite, so the per-skill field stays `3.0.0`.
- The release checklist. Row 1 counts 10 commands. A new row 12,
  `/kenspc-init`: in an empty directory the first question offers
  `git init` with `main` as the first branch and the next is interview
  round 1; headless, as a session that cannot ask, the run asks nothing,
  and the result is on `main` with the template comment in AGENTS.md,
  `@AGENTS.md` on CLAUDE.md's first line, the pair within 80 lines, every
  Documents path present, the two safety rules, the file backlog, both
  `.gitignore` lines, the unanswered policies as `TBD(init): …` and no
  other TBD form, one `docs: initialize project documentation` commit, and
  a clean tree; "what does /init do" and "init 是什么意思" invoke no skill.
  The end-to-end row becomes 13, with its sub-criteria heading; the
  roadmap's reference to it follows.
- The roadmap. Its heading names the next minor, 4.1.0, and it gains the
  two items the spec deferred: upgrading a project with `/kenspc-init` —
  migrating a repository set up before the skill, and bringing a project
  up to a later template, which the `kenspc-init template: 1` marker is
  there for — and moving a backlog from files under `docs/backlog/` to
  GitHub Issues.

### Known behavior

- **An existing CLAUDE.md.** `/kenspc-init` adds only the `@AGENTS.md`
  line, and only on a yes; a session that cannot ask leaves the file as it
  is, so Claude Code does not load the new AGENTS.md until that line is
  added, and the final message says so.
- **Uncommitted edits in the documentation commit.** A `.gitignore` the
  skill appended to, or a CLAUDE.md it gave the import line, is committed
  whole, with any uncommitted edit of the user's in it; the file list names
  each such file before the confirmation, and a session that cannot ask
  leaves it out of the commit.
- **Branches.** The plugin still creates no branch; the one branch it names
  is the first branch of a repository `/kenspc-init` creates, `main`.
- **Generated documents can say more than the user gave.** The skill writes
  only what the user said, what a file shows, or a `TBD(init):` marker,
  and still, in one headless acceptance run, `docs/product.md` stated
  product claims its one-line argument did not make (that the product
  replaces phone-in scheduling, that patients reschedule or cancel); a
  second run on the same argument left its purpose `TBD(init):`, and a
  later plan draft cited the added line as grounded in `docs/product.md`.
  Read `docs/product.md`, and the other topic documents, once after
  `/kenspc-init`, before the first plan relies on them.
- **An existing CLAUDE.md and the 80-line budget.** Beside a CLAUDE.md that
  was already there, the budget counts AGENTS.md alone, so AGENTS.md and
  CLAUDE.md together can exceed 80 lines and repeat each other: in the
  acceptance, one case's pair came to 110 lines with five repetitions, and
  in another AGENTS.md copied the commands and rules the existing CLAUDE.md
  held. `/kenspc-init` reports the combined count and the repetitions (on
  the import question's yes) and trims neither file; which copy stays is
  the user's to settle.
- **A skipped file list commits.** "Skip, use the default" at the
  file-list confirmation commits the list as presented, less any file that
  held uncommitted changes of the user's, as a session that cannot ask
  does: a skipped question takes the default in the skill's defaults
  table, and there the commit is made. Only a "no" keeps the files out of
  history.

## 3.9.0 — 2026-09-27

Batch F. An `autopilot` skill and its `/kenspc-autopilot <path to a spec or
a brief>` command run one batch of this plugin's own chain unattended, from
a spec or a brief to a local release preparation, between two human gates:
the decisions on a brief's design table, and the tag, push, and release
after the reports. Two entries — a spec (a plan document) runs unattended
from task decomposition on; a brief first gets a design session whose
decision table the user rules on, after which the spec is committed and
the rest runs unattended — and two modes: `repo` (the default; the workers
use the installed plugin, acceptance is the commands the brief names or
nothing, and release preparation is one commit that removes the batch's
plan and task documents) and `plugin` (declared, or detected from a
marketplace layout; the workers load the worktree's plugin with
`--plugin-dir`, acceptance runs on a seed project and files
`docs/dry-runs/<batch>-acceptance.md`, and release preparation is the
repository's). One headless `claude -p` session per role — design at brief
entry, task decomposition, implementation, standalone review, acceptance,
fix on demand, release preparation — each started through a driver script
that ships with the skill and is copied per batch, and talking to the main
session by cross-session messages. Two reports end the run: a one-page
user report in the conversation's language and a reviewer report of fixed
shape with a total-cost line. Beside the bash driver `run.sh` ships
`run.ps1`, its PowerShell mirror, checked on macOS only — a parse and its
self-test; the skill still copies and runs `run.sh`. Known behavior records
what the probes and the acceptance found about the harness: the idle
notice a headless subscriber gets as an extra turn, one tool call per wait
iteration, sessions that share a name, hook sessions in seeds, the
subscription expiry, the message limits, the caps' default, the budget
check the first worker always passes, and a headless run that leaves the
settings and return lines in the state file only. Release-checklist row 1
counts nine commands, a new row 11 runs one headless `repo`-mode batch and
both drivers' self-tests, and the end-to-end row becomes 12. A new command
and a new skill, so a minor release. No new agent and no new CONTEXT key;
`scripts/` is untouched, so the guard counts are unchanged
(`guards run: 10`, `self-tests run: 9`). Release smoke: the batch's
acceptance run, `docs/dry-runs/batch-f-acceptance.md`, headless on macOS in
two rounds, at the trees `b6a0199` and `8684c81`; the one later change to a
shipped plugin file rewrites the reason in the skill's settings-line
paragraph and changes no step. Round 1 ran case 1 in full — a `repo`-mode
batch from a spec through S2, S3, S3b, S4, and S6, with a worker's question
answered, the release commit, the two reports, and the costs file; its
state file and timeline hold what row 11 reads there — which is row 11's
main path (the seed's two acceptance commands added the S4 that row 11's
`Acceptance: none` seed skips); case 9, a task document as the argument,
which starts no worker, and case 8, a prompt that opens with the workers'
first sentence, which invokes no skill — row 11's two refusals; case 5,
no `git push`, `git tag`, or recursive `rm` in any session's commands —
row 11's rails; case 6, `run.sh`'s self-test and its failing-stub control;
case 4, a budget stop; and case 7, the pre-flight block and row 1's nine
commands, read from a headless session's init message, since `/help` is
not available headless. Round 2, by the user's decision, made short checks
only: the brief entry and `plugin` mode, each run to its first budget
stop — the design session, its decision table, the rulings, and the spec
commit; the mode detection and the `--plugin-dir` passing to S2 and S3 —
and `run.ps1`'s parse, self-test, failing-stub control, and
missing-executable control, row 11's `run.ps1` clause. The full
brief-entry chain and `plugin` mode's S3b, S4, and S6 did not run, nor did
a death and its resume, a budget raise, or the interactive wait path.
Rows 3–10 and 12 exercise skills and commands this release leaves
unchanged and were not run; row 2's `/reload-plugins` was not run either,
while every session the acceptance's driver started loaded the plugin
from the working tree.
Of the six findings, three are plugin defects fixed in this release that
no run re-exercised: a sentence after the finish line (the fix checked on
the text in round 2), one unstated point escalated to the user in one run
and answered from the spec in another (now a question to the user by
rule), and row 11's and this entry's overstatement of how far `plugin`
mode ran. The budget check the first worker always passes is a behavior
deviation, now a Known behavior item. The settings, launch, and return
lines case 1 did not print were fixed in wording, and round 2 still left
the settings line and three return lines in the state file only — a
behavior deviation, so row 11 reads them from the state file and the
timeline. No separate smoke run was made.

### Added

- **The autopilot skill and `/kenspc-autopilot`.** `skills/autopilot/SKILL.md`
  and `commands/kenspc-autopilot.md` (`disable-model-invocation: true`; the
  skill's description owns the routing, and it excludes any prompt that
  opens with the workers' fixed first sentence, so a worker cannot start a
  nested autopilot). Two entries: a spec runs unattended from S2 on; a
  brief gets S1, a design session that drafts the spec with a decision
  table of numbered questions, options, and leans, sends the compact table
  to the main session, and, once the user has ruled on every row (or
  delegated the rest to the leans), fills the decisions in and commits the
  spec alone (`docs(plans): add batch <name> spec`). Two modes, `repo` and
  `plugin`; `plugin` is detected when the repository root holds
  `.claude-plugin/marketplace.json` and a `plugins/*/.claude-plugin/plugin.json`,
  and the `Mode:` field wins over the detection. The topology is fixed —
  S1 design (brief entry only), S2 `/kenspc-task`, S3
  `/kenspc-task-implement`, S3b a standalone `/kenspc-task-review` over the
  batch's range `<baseline>..<HEAD at S3's end>`, S4 acceptance, S5 a fix
  for a defect the main session classified, S6 release preparation — one
  role per session, never reused, so the implementer is not the acceptor
  and a session that edited the plugin is not the one that reviews it. A
  worker's question at a skill's gate (generate-task's confirmation,
  task-implement's batch gate) is answered from the spec: `yes` only when
  the task list matches the spec's steps and carries no choice the spec's
  words leave open; a mismatch is a question to the user, and so is a
  type, a shape, a name, or a behavior a worker proposes to pin, however
  it frames it (a detail, a task-level concretization), unless the spec's
  words rule out every other option it lists; a question the spec does not
  answer is a stop, never an answer on the user's behalf.
- **The driver `run.sh`** (`skills/autopilot/scripts/run.sh`), bash 3.2,
  copied per batch to `_prompts/<batch>-run.sh` and run through the copy.
  Interface `run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]`; the
  prompt is read from the file, never typed on a command line. Every worker
  starts with `--name <tag>`, `--settings '{"crossSessionInbound":"accept"}'`,
  `--permission-mode bypassPermissions`, `--output-format json`, stdin from
  `/dev/null`, and a `--session-id` the driver generates and writes to
  `<tag>.session` before the process starts, so the transcript path and the
  resume id are known even when the worker dies before its JSON lands.
  `AUTOPILOT_PLUGIN_DIR` adds `--plugin-dir` (plugin mode),
  `AUTOPILOT_BUDGET_USD` adds `--max-budget-usd`, `APPEND_SP` adds
  `--append-system-prompt`; `AUTOPILOT_LOGS`, `AUTOPILOT_CLAUDE`, and
  `AUTOPILOT_BATCH` set the logs directory, the executable, and the batch
  name. It writes `<tag>.json`, `<tag>.err`, `<tag>.pid`, `<tag>.exit`
  (the worker's exit status, the completion artifact), and appends
  `start <tag> pid <pid> …` / `end   <tag> exit <status>` to
  `<batch>-timeline.log`; the worker runs in a subshell under `trap '' HUP`,
  wrapped in `caffeinate -i` when that command exists, so a macOS machine
  does not sleep under a running worker. `run.sh --self-test` writes a stub
  executable under `$TMPDIR`, launches it through the same path, checks the
  five files, the two timeline lines, and the flags the stub echoes to
  `<tag>.err` — and beyond those the `started <tag> pid <pid> session <id>`
  line, a live pid, the stub's cwd, the optional flags absent with their
  variables unset and present on a resume launch made through the command
  line with them set, the refusals below, a failing stub's status reaching
  `<tag>.exit` and the timeline, the stale-`.exit` removal, and the
  batch-name default with `AUTOPILOT_BATCH` unset — and prints
  `self-test passed`; a
  caller-supplied stub (`AUTOPILOT_CLAUDE`) exercises the failure path. The
  skill runs the copy's self-test at every batch start, with that variable
  empty on the command. A launch is refused with status 2 and nothing
  started for an empty tag, a missing cwd, a missing, empty, or
  whitespace-only prompt file, an executable that cannot be found, a
  `--resume` without an id, an unknown argument, and a tag whose earlier
  worker still runs (its pid live and its `<tag>.exit` absent); a stale
  `<tag>.exit` from an earlier launch under the tag is removed before the
  worker starts. No `--model`, no `--continue`.
- **The messaging protocol.** A worker asks with one message whose first
  line is `question <tag>: <one line>` and whose body gives the context,
  the options, and its suggested answer, then waits in a bounded `until`
  loop (`sleep 2`, thirty times, one Bash call of about a minute) for at
  most thirty minutes; the main session answers with `answer <tag>: <one line>`.
  A worker that got no answer puts the question under
  `## Question for the main session` in its final message and stops, and
  the main session resumes it with the answer under the step's next
  `<tag>-r<k>`. The
  interactive main session subscribes to each worker with
  `notify_when_idle` and ends its turn; the idle notice is the wake, and
  `<tag>.exit` the completion artifact, re-read with the state file
  (`_logs/<batch>-state.md`) on every wake; a headless main session never
  subscribes and polls `<tag>.exit` instead (its settings line ends
  `wait headless`). `ListAgents` runs before every send, and the `[ref]`
  addresses a row when two share a name. `--resume` is the fallback for a
  worker that has died — its pid gone with no `<tag>.exit` ten seconds
  later, or a JSON that is empty, not JSON, or of a subtype other than
  `success` — once, under the step's next `<tag>-r<k>`, with the fixed
  continue prompt; a second death of the same step is a stop. No
  `--continue`.
- **Budget and caps.** `USD 200` by default, from the `Budget:` field,
  never hard-coded; `16 sessions, 8 resumes` from `Caps:`. Before each
  launch, spent (the sum of each session's last cumulative
  `total_cost_usd`, upserted into `<batch>-costs.txt` after every
  `<tag>.exit`, and in `plugin` mode the acceptance cases' costs from the
  record once S4 has returned) plus projected (the largest session so far,
  or budget ÷ 6 before the first) is checked against the budget; exceeding
  it asks
  "raise the budget to how much?" with the numbers, and the answer is
  recorded in the state file and the reports. Every worker is started with
  `--max-budget-usd` at the remaining amount; a worker its cap ended is
  the budget stop and is resumed once the budget is raised, with the new
  remaining amount as its cap — the ended session's last cumulative total
  is already in spent, and a probe with a resumed session showed the flag
  counts the invocation's own spend, not the session's earlier total —
  and the resumed session's JSON replaces its line in `<batch>-costs.txt`.
  Acceptance
  cases marked `(optional)` may be cut when the check fails; implementation
  is never narrowed.
- **Stops.** Reopening a locked design point; a forbidden section or file;
  guards red twice in a row; the same FAIL still failing after two fixes;
  the session cap, the resume cap, or the budget exceeded (a question); a
  safety-rail breach (the rails in every worker's preamble: write only to
  the repository, the workspace, and `$TMPDIR`; no `git push`, `git tag`,
  or release; no resource the brief does not name; no secrets; no
  recursive `rm` in any spelling — `rm -r`, `rm -rf`, `rm -fr`, `rm -R` —
  discard by `mv` into `.trash/`; deletions inside the repository only
  through `git rm`); a question neither the spec nor the locked design
  answers; a nested `claude -p` refused; the same step's session dead
  twice. Each ends the final message with `Autopilot stopped: <reason>`.
- **The two gates and the two reports.** The run stops for the user at the
  decisions on a brief's design table (a supplied spec counts as approved)
  and at the tag, push, and release after the reports; the final message
  ends with `Autopilot finished — <baseline sha>..<last sha>`. It carries
  `## User report` (the conversation's language, one page: what the batch
  built, the release commit, what needs the user, the cost) and
  `## Reviewer report` (English, fixed fields: batch and mode, baseline →
  release hash, the spec's `git show` command, design rulings and
  clarifications with the decisions beyond the letter, files changed and
  the zero-diff result, byte-identity / guards / counts, acceptance one line
  per case with its cost, total cost, Not exercised, release-preparation
  state, sessions / messages / resumes / stops). The total-cost line is the
  measured sum of the workers' last cumulative `total_cost_usd`, plus in
  `plugin` mode the acceptance cases' costs from the record (S4's nested
  sessions), plus the main session's own cost as an estimate labeled so —
  its turn count × the
  mean cost per turn across the batch's workers (`total_cost_usd` ÷
  `num_turns`), the basis on the line; `/cost` may replace it. The reviewer
  report is also written to `_logs/<batch>-report.md`.
- **The `## Autopilot` section.** The batch's settings, the last section of
  a brief (after `## Discovery Notes`) or of a spec: `- <Label>: <value>`
  bullets in any order, every field defaulted, none required — `Baseline:`,
  `Mode:`, `Plugin:`, `Version:`, `Budget:`, `Caps:`, `Allowed files:`,
  `Zero diff:`, `Byte-identity exceptions:`, `Acceptance:` (`none`, or one
  sub-bullet per case with its PASS criterion after ` — PASS: ` and
  `(optional)` on a case that may be cut), `Acceptance record:`,
  `Release preparation:` (`default`, `keep`, or instructions), `Must read:`,
  `Challenge seeds:`, `Prior specs:` (`<hash>^:<path>` for `git show`), and
  `Workspace:` (`~/Projects/_smoke/` by default, the tree of `_prompts/`,
  `_logs/`, seeds, and `.trash/`). The effective settings are printed in one
  fixed line before the first launch. In `repo` mode acceptance is the
  `Acceptance:` commands run by an S4 worker at the S3b HEAD (results in the
  reviewer report; no file in the repository unless `Acceptance record:`
  names one) or, with `none`, no S4 and the line
  `none named; S3b is the last check`; release preparation is the removal
  commit `docs: remove batch <name> plan and tasks` (`keep` leaves the
  documents; instructions run after the removal). In `plugin` mode S4 runs a
  seed-project acceptance — a trial run of the seed first, one case per run
  — and files the record with the sections Setup, Independence, Cases,
  Findings, Observations, Not exercised, Summary; S6 makes the repository's
  release preparation from its release checklist and CLAUDE.md, no tag and
  no push. Every classification of an S4 FAIL and every deferral is a
  clarification committed into the spec by the main session
  (`docs(plans): record clarifications settled after <step>`).
- **Documentation.** CLAUDE.md gains a fourth orchestration pattern,
  "Sessions, not agents (autopilot)", the layout-tree entries, a File
  Structure bullet for a skill's optional `scripts/` directory, the count
  sentences (nine skills), the bypass-permissions sentence beside the
  Development Workflow rule, three Non-Goals paragraphs (no agent teams; no
  driver completion message on the messaging socket; the workspace outside
  the repository), and the autopilot's gates in the cannot-ask wording
  bullet. The plugin README gains a Skills row, a Commands row and the
  `/kenspc:autopilot` form, a Recommended Workflow line, a new Autopilot
  section (the launch line
  `claude --name <batch>-main --permission-mode bypassPermissions --settings '{"crossSessionInbound":"accept"}'`,
  the sixteen labels with an example, the workspace, what a run writes and
  commits, the gates, the stops, the budget rule, the reports, the
  drivers), nine Known behavior items — the eight below other than the
  caps' default, with the message-limits item's stricter-inbound-settings
  half as an item of its own — and the version line
  `Claude Code v2.1.271 or later` under Requirements (the plugin's
  `v2.1.0+` minimum is unchanged: every other skill runs on it). The root
  README gains a skills-table row and `/kenspc-autopilot` on its Commands
  line; the two manifests' descriptions gain "unattended batch runs to a
  release preparation". Release-checklist row 1 counts 9 commands, and a
  new row 11, `/kenspc-autopilot <spec>`, runs one headless `repo`-mode
  batch on a one-task seed (about USD 10–20 at the batch E per-session
  figures; `plugin` mode is not run per release, and the batch's
  acceptance record ran it up to its second worker — the mode detection
  and the `--plugin-dir` passing — while its nested acceptance, the record
  that acceptance files, and its release commit have not run), and also
  requires that
  `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  prints `self-test passed` and exits 0, and that the same command with
  `AUTOPILOT_CLAUDE` pointed at a `.ps1` stub that prints the built-in
  stub's JSON, sleeps one second, and exits 3 makes the self-test exit 1
  naming `.exit`, and that with `AUTOPILOT_CLAUDE` naming a file that does
  not exist it exits 1 with `self-test failed: run.ps1: no executable`;
  the end-to-end row becomes 12.
- **The PowerShell driver `run.ps1`.** `skills/autopilot/scripts/run.ps1`,
  for PowerShell 7.3 or later (`#Requires -Version 7.3`: 7.0 to 7.2 drop
  the double quotes inside the arguments they pass to a native program, so
  the worker's `--settings` value would not arrive as JSON), is written
  after the bash driver passed acceptance. It has the same interface, files, timeline
  lines, and refusals as `run.sh` (exit 2, nothing written), and also
  refuses a logs directory or tag holding `[`, `]`, `*`, or `?`, which
  `Start-Process` cannot redirect to. It runs as
  `pwsh -NoProfile -File <path>/run.ps1 <tag> <cwd> <prompt-file> [--resume <session-id>]`.
  It keeps the stale `.exit` removal, the `started` line, the batch-name
  default, and `caffeinate -i` when present. Details:
  - The worker starts through `Start-Process pwsh`, with the inner command
    passed by `-EncodedCommand`, so a path with a space or a single quote
    arrives unchanged, and with `-WindowStyle Hidden` on Windows only
    (pwsh on macOS refuses the parameter). The inner command reads the
    prompt with `Get-Content -Raw`, gives the worker an empty stdin, and
    writes `<tag>.exit` and the `end` line when the worker returns.
  - The launched pwsh's own streams go to `<tag>.launch.in`,
    `<tag>.launch.out`, and `<tag>.launch.err`, so a caller that reads
    the launch through a pipe gets the `started` line at once.
  - The files it writes and its `started` line end with LF and carry no
    byte-order mark on every platform.
  - Its `--self-test` launches a `claude.ps1` stub put first on a
    temporary PATH entry and checks what `run.sh`'s does, adapted. It adds
    a launch whose cwd and logs directory hold a space and a single quote,
    a launch read through a command substitution that returns while a
    slow stub still runs, and, on macOS and Linux, a launch through a
    native `#!/bin/sh` stub whose `-p` and `--settings` values are
    compared byte for byte with a prompt holding double quotes and with the
    settings JSON.
  - It is checked with `pwsh` on macOS: a parse and the self-test. There
    the launched process is attached to the launching shell, and the
    launch output files keep nothing written after the driver returns;
    the inner command also writes its own failure reason to `<tag>.err`,
    with `<tag>.exit` reading 1.

  The skill still copies and runs `run.sh`. Windows acceptance of
  `run.ps1` is a roadmap line.

### Known behavior

- **A headless subscriber gets the idle notice as an extra turn.** In the
  probe that settled the wait path, a `claude -p` session subscribed to its
  worker with `notify_when_idle`; the worker exited, nothing arrived during
  twenty-six minutes of the session's tool calls, and the notice started a
  new turn after the session's final reply, twenty-six minutes after the
  worker exited, whose JSON `result` then became that turn's last message.
  So a headless autopilot never subscribes and polls `<tag>.exit`, and only
  an interactive main session — whose probe did receive the notice between
  turns — subscribes and ends its turn.
- **One tool call per wait iteration.** The Bash tool blocks a bare `sleep`
  of thirty seconds or more, with a message that recommends an `until`
  loop, and refuses chained shorter sleeps; a bounded
  `until … sleep 2` loop passes. So every wait is one Bash call of about a
  minute, a thirty-minute wait is about thirty calls, and the interactive
  main session avoids them by subscribing and ending its turn.
- **Sessions that share a name.** The rename Claude Code applies to a
  duplicate session name does not check the `--name` of a `-p` session at
  startup, so two headless sessions can share a name; the skill lists agents
  before each send and addresses the row whose start time matches the
  launch by its `[ref]` when two rows share the name.
- **Hook sessions and hook files in seeds.** In the same probe a user-level
  hook's session (a SessionEnd hook that starts its own `claude -p`)
  appeared in `ListAgents` and in the trace directory, and the hook wrote a
  directory into the probe's working directory. Such sessions are recorded
  as observations, counted neither as cost nor as the run's change, and a
  hook's files in a seed are listed under the record's Observations.
- **The twelve-hour subscription expiry.** A `notify_when_idle` subscription
  that gets no notice within twelve hours is dropped and reported; the
  report is a wake like any other, so the skill re-checks `<tag>.exit` and
  subscribes again while the pid lives. A live pid is never killed and never
  judged hung: a test suite or a long implementation is silent for longer
  than any timeout a prompt would pick.
- **Message limits.** A message over 1,048,576 characters is refused, a
  burst of about thirty sends to one session is refused, a receiver queues
  at most fifty messages and drops identical repeats, and a `-p` receiver
  drops a held message after about five minutes. Messages carry summaries
  and paths, never a report's text; every worker and the main session run
  with `crossSessionInbound: accept`, and a project or local `hold` or
  `refuse` that is stricter applies over it, so a held or refused first
  message is a stop naming the settings precedence.
- **The caps' default.** The three earlier batches ran 7 + 11, 10 + 14, and
  6 + 7 sessions and runs, with 5, 9, and 7 resumes; `16 sessions` is one
  and a half times the largest session count, and the `Caps:` field
  overrides both counts.
- **The first worker always passes the budget check.** Before any session
  spent is 0 and the projected cost is a sixth of the budget, so the check
  cannot stop a batch before its first worker, whatever the budget; that
  worker runs under a `--max-budget-usd` cap of the whole budget, which
  bounds its spend. A run with `Budget: USD 1` started its first worker
  under a USD 1 cap; the worker spent USD 0.61, and the run stopped before
  the second, with spent and projected at USD 0.61, asking how much to
  raise the budget to. A budget smaller than one worker's cost stops the
  run before the second worker too: the cap ends the first worker, and
  that is the budget stop.
- **A headless run may leave the settings and return lines in the state
  file only.** The skill prints the settings line and each launch and
  return line in its reply, each instruction with its reason. Two headless
  runs with those instructions in place printed every launch line, yet
  wrote the settings line only into the state file and left three of their
  five return lines unprinted. The same facts are on disk: the settings
  line in `_logs/<batch>-state.md`, and each launch and return as the
  driver's `start` and `end` lines in `<batch>-timeline.log`, the `end`
  line written together with `<tag>.exit`. Release-checklist row 11 reads
  them there rather than from the reply.

## 3.8.2 — 2026-09-26

Batch E. A review run renders its reports once: between the dispatches,
`/kenspc-task-review` and `/kenspc-task-implement`'s review phase print one
fixed progress line per step, and the Schema A roll-up, code-fixer's reply,
and Schema C appear once, in Schema F or Schema G. In a review against a
task document whose Doc-sync task is DONE, code-fixer corrects, in the
fix's own commit, each sentence of a listed document that the fix made
false, marks it in the Schema B Action cell, and reports it in one
`Doc-sync documents:` reply line, which the final reports turn into a Next
steps bullet instead of asking the user to re-check the documents.
generate-plan writes the draft last printed in full, character for
character, and prints the whole draft again for approval after any change.
The plugin README's Known behavior says why a regression a fix brought in
fails the verdict while a deferred MEDIUM does not; the verdict rules are
unchanged. The roadmap's transcript-audit item leaves with no change: no
such script is kept in this repository (`scripts/` holds only the
`check-*.sh` guards), and since 3.6.0 the acceptance records
read the transcripts with `jq` directly
(`docs/dry-runs/scratch-probes-acceptance.md`). Release-checklist rows 4,
6, and 7 check the three changes. No new command, skill, agent, or CONTEXT
key, and the guard counts are unchanged (`guards run: 10`,
`self-tests run: 9`), so a patch release. Release smoke: the batch's
acceptance run, `docs/dry-runs/batch-e-acceptance.md`, seven runs headless
on macOS against the skill and agent files this release ships — rows 6 and
7's progress lines and single render in four review runs, one of them a
`/kenspc-task-review` of a task document whose Doc-sync task is DONE, where
code-fixer corrected the README in the fix commit and Schema F carried the
Doc-sync bullet; a `/kenspc-task-implement` run whose fixes affected no
listed document; row 4's verbatim write, interactive and in a session that
cannot ask; and the pre-flight block. None of its four findings is a plugin
defect. Two of the twelve progress lines were not printed (F1), a behavior
deviation recorded in the roadmap; every review run still rendered the
tables once, in the final report. The other three are observations: a
seed whose README stated the defect first left one run's Doc-sync task
BLOCKED, so that run reached no review (F2), and row 4's wording failed
two runs whose behavior met its intent — a probe written into the
session's own scratchpad before approval (F3), and a plan copied into
place from the printed draft's file rather than written with Write, its
committed blob equal to the draft (F4) — so row 4 is reworded in this
release. Schema G's Doc-sync bullet in its `updated` form was not
exercised. No separate smoke run was made.

### Changed

- **Review rendered once.** `task-review/SKILL.md` Steps 4–6 and
  `task-implement/SKILL.md` Phase 2 Step 3 print one line each where they
  rendered a table or a reply, the same in both skills and in English
  whatever the conversation language:
  `Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`;
  `code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`;
  and `regression-verifier returned — CLEAN`, or
  `regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`
  (no path: regression-verifier writes no report file). A code-fixer reply
  without its statistics line, or a regression-verifier reply without its
  CLEAN or HAS ISSUES result line, prints instead
  `code-fixer returned — no statistics line` or
  `regression-verifier returned — no result line`, the same in both skills,
  the final report renders that reply verbatim, and the run goes on. In a
  `Mode: uncommitted` review, a code-fixer reply without its statistics
  line still gets Schema F's Next steps bullet on the uncommitted fixes,
  which then names code-fixer's pre-fix record
  (`scratch/code-fixer/pre-fix/index.txt` in the run directory), since the
  fixes it made before it stopped sit in the working tree beside the user's
  own change, or, when that record does not exist, says that code-fixer
  recorded no edit. The
  Schema A
  roll-up, code-fixer's reply, and Schema C are rendered once, in the final
  report: Schema F's Review summary now holds the per-angle roll-up table
  (`| Angle | HIGH | MEDIUM | LOW |`, the five angle rows, and a
  `**Total**` row) where it asked for total counts, Schema G's Code Review
  holds the same table below its placeholder, task-review's Step 6
  drops its example Schema C table (regression-verifier's OUTPUT FORMAT
  defines it), and Schema G's Code Review, Fixes, and Verification
  sections say they are rendered there only. The render change does not
  trim code-fixer's reply: the final report renders all of it. Source: the
  roll-up and the agents' replies were printed twice
  in one run, between the dispatches and again in the final report, and
  both copies stayed in the orchestrator's context.
- **code-fixer, Doc-sync documents.** With REVIEW_SCOPE "task", code-fixer
  finds the task document's `### Task N: Doc-sync` section and its
  `**Status:**`, and takes its documents — the backticked path that opens
  each bullet of its list, read by no label, since a translated task
  document can carry a translated one — into the fix scope when that status
  is DONE. After each fix it reads the parts of each listed document that
  describe the changed code and corrects each sentence, list item, or table
  row the fix made false, in the document's own language and in the fix's
  own commit, whose body says `Updates <path> to match the fix.` It changes
  nothing else: no new section or paragraph, no text the fix did not make
  false, no behavior the document never described, and no document outside
  the list; a listed path with no file is skipped. A correction that needs
  more, or a document with uncommitted changes, is left undone and reported
  not updated with its reason, while the code fix still lands. A correction
  does not count toward the fix's size, so a fix localized to one file is
  not deferred as a multi-file fix for it, and a fix withdrawn because its
  build / test / lint run failed takes its correction back with it. The
  Schema B
  Action cell names the document — `FIXED — updated <path>[, <path>]`, or
  `FIXED — not updated <path>: <reason>`, several joined by `; ` — and the
  leading word still classifies the action, so the recount guard passes
  unchanged; the worked Schema B example is unchanged. The reply carries,
  after the statistics line, one line,
  `Doc-sync documents: <part>[; <part>…]`, each part
  `updated <path> (row <n>, <commit>)` or
  `not updated <path> (row <n>) — <reason>`, in any order, so a run whose
  one affected document was left not updated can say so, or
  `Doc-sync documents: none affected by the fixes`, always present in
  such a run, FIXED 0 included, and not written to `schema-b.md`. When the
  Doc-sync task is DONE and FIXED is greater than 0, Schema G's Next steps
  carries that line as one bullet, reads
  `No Doc-sync document describes behavior the fixes changed.` when none
  was affected, and, when the reply has no such line, states
  `code-fixer's reply has no Doc-sync documents line` and names the listed
  documents to check against the fix commits; a reply without a statistics
  line gets the bullet as for FIXED greater than 0. Schema F gains the same
  bullet whenever the reply carries the line and FIXED is greater than 0,
  without that fallback: `/kenspc-task-review` never reads the Doc-sync
  task's status. This replaces the 3.6.0 Next steps bullet that named the
  listed documents to re-check against the fix commits. Source: the batch A
  review's B2 — documents a Doc-sync task synced went stale when a review
  fix changed the behavior they describe, and the report handed the check
  back to the user.
- **generate-plan, the approved plan written verbatim.** On approval, the
  file is the draft last printed in full — every section, none elided or
  summarized — character for character: no rewording, a pronoun included,
  no reformatting, and no change to an escape or special character. A
  change after that print — one the self-challenge finds, one shown only as
  a revised section, one the approving reply itself asks for, or a request
  for another language — is made to the draft, which is printed again in
  full and approved again before anything is written. In a session that
  cannot ask, that print ends with `Plan not written: awaiting approval.`
  and the run stops again, and an approval given on resume writes the draft
  that run's last message printed. The document language is the draft's,
  set by Step 1's writing rules when it was drafted; the write-time step
  "If the user specified a language, use it. Otherwise, default to English."
  is gone, and Step 3's last item reads "Write the plan to the file: the
  approved draft, as printed." Source: the batch D acceptance's O3
  (`docs/dry-runs/batch-d-acceptance.md`), where a plan approved on resume
  differed from the draft it approved in 7 of 355 lines: pronouns reworded,
  a Documentation impact line reformatted, and two escapes written as the
  character they stand for.
- **Release checklist.** Row 4 compares the plan as first written — the
  Write call's `content` in the trace when it was written with Write, and
  in every case its blob in `plan-document-reviewer`'s first commit — with
  the draft the last message before the approval printed in full,
  character for character after the same normalization on both sides (CRLF
  read as LF, trailing newlines at the very end dropped; a U+FEFF, an
  escape, and trailing spaces count), with the text outside the matched
  block holding no line of the plan and a one-character edit to a copy of
  the file failing the comparison; an approving reply that asks for a
  change gets the full revised draft again, and in a session that cannot
  ask, a resumed reply that asks for a change ends with the full revised
  draft and `Plan not written: awaiting approval.`, with no Agent call and
  no commit. Before an approval — in those two invocations, and at the
  cannot-ask stop, where row 4 counted any Write as a failure — the trace
  shows no Write or Edit into the project: a probe written outside the
  project is not a write of the plan. Rows 6 and 7 replace
  "then Schema A → B → C → G" and "then
  the Schema A roll-up, B, C, and the Schema F final report" with the three
  progress lines in order, each after its agent returns and before the next
  step and in its full form, its counts and result matching the final
  report's roll-up **Total** row (the sum of its angle rows, each equal to
  the Findings table of its `angle-<n>.md`), the statistics line, and
  Schema C, the
  `— HAS ISSUES:` form recorded as not exercised when Schema C is CLEAN, no
  text line beginning with `|` from the first reviewer call until
  the final report's first heading, and the roll-up header, a line holding
  `total reported `, and the Schema C header each exactly once, inside the
  final report. Row 6's re-check criterion becomes the fix-commit
  correction — the sentence changed and nothing else in the document, the
  commit's body holding `Updates <path> to match the fix.`, the row's
  FIXED Action naming the document in its `updated <path>[, <path>]` part,
  code-fixer's `Doc-sync documents:` line holding the part
  `updated <path> (row <n>, <commit>)` (neither need open with it: a
  `not updated` part can come first), and one Next steps bullet naming the
  document and row — and, with FIXED greater than
  0 and no document affected, no fix commit touching a listed document and
  the bullet `No Doc-sync document describes behavior the fixes changed.`;
  in a run whose Doc-sync task is DONE, no listed document that was clean
  before the run is left with an uncommitted change and no fix commit
  touches one unless that document is
  named in its own Action's `updated <path>[, <path>]` part or in its own
  row's File:Line;
  in row 6's forced-BLOCKED run, code-fixer's reply has no
  `Doc-sync documents:` line and no fix commit touches a listed document
  unless its own row's File:Line names it; row 7 checks that without a task
  document code-fixer's reply has no
  `Doc-sync documents:` line and no Action cell carries the document
  suffix. No new row; pre-flight counts unchanged.
- CLAUDE.md's Subagent Review Architecture gains two sentences: after the
  Parallel MapReduce list, the progress line per step and the one render
  in Schema F or G; and, closing the documentation path paragraph,
  code-fixer's correction of the listed documents in the fix commits. The
  plugin README's Run directory, Documentation path, and `generate-plan`
  row follow the three changes, and its Known behavior gains
  "Regressions and deferred issues in the verdict".

### Known behavior

- **Regressions and deferred issues in the verdict.** A regression the
  review's fixes brought in fails the verdict whatever its severity, while a
  deferred MEDIUM does not. Behavior unchanged — the verdict rules are not
  edited; the plugin README's new Known behavior item says why: a
  regression is damage the run's own fixes did to code that worked before
  them, which a revert of those fixes undoes, while a deferred MEDIUM or LOW
  issue was in the reviewed code before any fix and is reported with its
  reason for the user to schedule.

## 3.8.1 — 2026-09-26

Batch D. Three stops an unattended run got wrong get a defined answer:
generate-plan's approval stop, in a session that cannot ask, ends at the
draft printed in full, with nothing written, reviewed, or committed, until
a later reply approves it; generate-plan takes an `answered` brief entry as
settled input only when it holds `Answer:` with text after the label, and
asks about or carries one without; and the prototype skill asks before it
touches an entry that already holds an answer, named or not, or a named
entry whose status word it does not recognize — in a session that cannot
ask it stops with the brief unchanged, its last message opening with the
frame. diagnose-bug's interactive exit names the reproduction commit and
`git revert <hash>`. Three copied strings gain a guard — the reviewer
invariant sentence's README, CLAUDE.md, and task-review copies, the
Prototype line in generate-brief and the prototype skill, and the
prototype skill's two leftovers commands — inside two existing guards.
Known behavior gains what a red reproduction test does to later review
runs and what the one-time `.gitignore` commit takes with it, and
release-checklist rows 4, 9, and 10 gain the new cases. No new command,
skill, or agent, no CONTEXT key changes, and the guard counts are
unchanged (`guards run: 10`, `self-tests run: 9`), so a patch release.
Release smoke: the batch's acceptance run,
`docs/dry-runs/batch-d-acceptance.md`, headless on macOS — row 4's
cannot-ask stop at the draft, its approval on resume beside two existing
plans, and an `answered` entry with no `Answer:`, in the gap round and
carried; row 9's interactive exit; row 10's two entry gates, interactive
and in a session that cannot ask; and the pre-flight block. Of its two
findings, the prototype skill's frame, not sent when a session that cannot
ask stopped at an entry gate, was fixed before this release — the stop's
last message now opens with the frame — and its three cases re-run to PASS
on the released skill text; generate-plan's gap round asking an
unrecognized entry's status without asking, for `answered`, the answer in
the same question, a behavior deviation with no effect on the plan's
content, is recorded in the roadmap. No separate smoke run was made for
the other rows.

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
  that cannot ask, the plan is created alongside as `<name>-2.md` (or the
  first higher number no file has) and named in the final message, not
  overwritten.
- **generate-plan, answered entries.** An `answered` brief entry is settled
  input only when it holds `Answer:` — not by its status word alone, and not
  by a `Prototype:` line alone. The label counts only with text after it: an
  empty `Answer:` is no answer, and text after the label is taken as the
  answer, with no attempt to recognize a placeholder. A plan relying on one
  cites its prototype hash, or the entry itself (`<brief path>, entry <n>`)
  when it has no Prototype line. One without `Answer:` — as the brief has
  it, or as the user marks an unrecognized entry in the gap round — is a
  gap: the gap round quotes it and asks for its answer, in the same
  question that asks an unrecognized entry's status, so the
  one-to-two-round limit holds. An entry the rounds leave without an
  answer, and every such entry in a session that cannot ask, is carried
  into the plan's Open Questions in the `open` form with
  `From: <brief path>, entry <n>, status word answered, Answer: missing`.
- **prototype.** A named entry whose status word the skill does not
  recognize — hand-edited, translated, or missing — and that holds neither
  `Answer:` nor `Prototype:` is asked about before anything is written,
  quoting the word found: prototype it, or stop. A "stop" there, or a "no"
  to the prototype-again question below, ends the run with the entry
  unchanged, and a session that cannot ask stops the same way; stopping on
  an unrecognized word, its last message names the entry and quotes the
  word found, or says there is none, since the word is what stopped the
  run. The `answered` gate (prototype it again?) now also takes any entry
  the run takes that holds `Answer:`, whatever its status word — named, or
  taken with no entry named (the brief's only `needs prototype` entry, or
  the first in document order in a session that cannot ask) — and a named
  unrecognized one that holds `Prototype:`; a `needs prototype` entry with
  `Prototype:` and no `Answer:`, the form an unsettled attempt leaves, is
  still prototyped again. After a "yes" to that question, an entry that
  held `Answer:` when the run began is rewritten only when the new attempt
  settles the question; nothing built, a built prototype whose evidence
  does not settle it, or a verdict not given leaves its `Answer:`,
  `Evidence:`, and Prototype line in place — the one line it can gain is a
  `Settled by:` derived for it — and the final message names the new
  attempt's commits, when it made any, and why the question was not
  settled; before, Phase 3's rewrite for an unsettled run replaced them.
  Both gates come before Phase 1 writes to the brief — the entry appended
  for a question given as text, or a derived `Settled by:` — since the
  brief is not committed and a write there cannot be undone. In a session
  that cannot ask, a stop at either gate opens its last message with the
  frame, then names the entry and the word found and why the run stopped,
  as an interactive run puts the gate's question after the frame — a
  `Settled by:` derived in the frame is shown there and not written; in the
  batch D acceptance (`docs/dry-runs/batch-d-acceptance.md`, F1), such
  stops sent only the stop, which referred to a frame never sent.
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
  the sentence's period is caught), two whitespace-only changes that must
  exit 0 (a doubled space, and a line break inside the README copy's
  sentence, which a comparison line by line would report as drift), and
  one rewording of the reference's opening words that must exit 2. Its
  header now states the
  number of must-exit-1 mutations the self-test runs, nineteen; it said
  eleven where the script ran fourteen. `check-doc-sync-anchors.sh` gains a
  fifth anchor group, the Prototype line in generate-brief and the prototype
  skill, and one exact-count check: the prototype skill's leftovers command
  (`git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`)
  occurs exactly twice, counted by occurrence, since the start snapshot and
  the Exit compare their two lists path by path. Its self-test gains four
  mutations that must exit 1 (the Prototype line changed in each of its two
  files, one leftovers command changed, a third appended on the first one's
  line, where a count by line would read two). Guard counts are unchanged.
- **Release checklist.** Row 4 gains the cannot-ask stop at the draft (the
  complete draft and `Plan not written: awaiting approval.`; no Write, no
  Agent call, no commit), the resumed approval that writes, reviews, and
  commits, the existing-file branch under that approval (with `<name>.md`
  and `<name>-2.md` in place, the plan written at `<name>-3.md`, both
  files' sha256 unchanged, the new file named in the final message), an
  `answered` entry with no `Answer:` or an empty one (asked about in the
  gap round; carried with `status word answered, Answer: missing` in a
  session that cannot ask), and a gap-round reply of `answered` with no
  answer text, which is not taken as settled input. Row 9 gains the
  interactive exit's commit and `git revert <hash>`, with no revert made.
  Row 10 gains both gates, asked before anything is written, where a
  "stop" or a "no", and a cannot-ask stop, end with no commit and the
  brief's sha256 unchanged — for the unrecognized-word gate on an entry
  with no `Settled by:`, so the unchanged hash also shows the gate came
  before the derived write, and with that gate's cannot-ask stop naming
  the entry and quoting the word; the prototype-again question for an entry
  taken with no entry named that holds `Answer:`, an entry whose answer is
  kept when a "yes" to that question ends with nothing built or with a
  built prototype that does not settle it, and the two branches that turn
  on `Prototype:` with no `Answer:` — a `needs prototype` entry built with
  no question, and an unrecognized-word entry given the prototype-again
  question; its frame criterion now asks that a cannot-ask stop at either
  gate open its last message with the frame. No new row; pre-flight counts
  unchanged.
- CLAUDE.md's cannot-ask list gains generate-plan's approval stop and
  existing-file question; its prototype path paragraph names `Answer:`,
  with text after the label, as what makes an answered entry settled
  input; its guard descriptions, Non-Goals, and Maintenance note follow the
  two guards' new checks. The plugin README's `generate-plan` row gains the
  cannot-ask stop at the draft, its `prototype` row the two new questions
  and the unchanged brief a stop, a no, or a cannot-ask stop leaves, and its
  Prototype path paragraph the `Answer:` rule, both questions, and the
  answer kept when a "yes" does not settle the question, which its
  feature-prototype Known behavior item also notes.

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
