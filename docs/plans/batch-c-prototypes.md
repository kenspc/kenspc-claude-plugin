# Plan: Batch C — Open Questions in briefs, a generate-plan exit, the prototype skill and /kenspc-prototype

Target: this repository (`kenspc` plugin), on top of v3.7.0 (`4c3bf34`).
Release: 3.8.0 — a new command is a command-surface change. This batch makes
no version bump and no tag; its CHANGELOG entry goes under a
`## 3.8.0 — unreleased` heading.

**Status: ruled.** The design was locked as C-1 to C-8 (restated below) and
checked against the repository in a headless Claude Code session on
2026-09-25. Every question that check raised was decided by the main session
within the locked design on 2026-09-25 and is recorded in
[Design decisions](#design-decisions). This document is the complete
specification: the implementing session needs nothing beyond this file and
the repository.

## Objective

1. Briefs record what their discussion could not settle: a
   `## Open Questions` section whose entries each carry a status, and an
   entry marked `needs prototype` states the result that would settle it.
2. generate-plan stops on an unresolved `needs prototype` entry in a brief
   and asks whether to prototype first or carry the question into the plan;
   a session that cannot ask carries it and says so in the plan.
3. A `prototype` skill with `/kenspc-prototype` answers one such question
   with a throwaway prototype — logic, UI, or a feature slice: it builds the
   smallest thing that settles the question, commits it, writes the answer,
   the evidence, and the commit hash into the brief, and removes the
   prototype in the next commit. Whoever implements the real thing reads the
   prototype with `git show <hash>`.

**In scope:** C-1 to C-8 of the locked design (below); the reminder hook's
brief message; one new anchor group in an existing guard, with no change to
the guard or self-test counts; one sentence in roadmap item 7; the
documentation the change requires.

**Out of scope:** the roadmap's "Next minor" items other than item 7's
sentence; the roadmap's heading, batch C's line under "Planned batches", and
that emptied section, which the release commit changes (ruling M11); an
in-app exception for anything but a UI prototype (ruling M8); any new agent;
any new CONTEXT key; any edit inside a byte-identity section — the canonical
blocks (`canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`,
`canonical:verdict-shared`), the code-craft canonical paragraphs, and the
five reviewers' six shared sections, with no exception in this batch; any
diff to `task-implement`, `task-implementer`, `generate-task`,
`task-review`, `diagnose-bug`, `plan-document-reviewer`, or
`task-document-reviewer`; `shared/discovery-framework.md` (ruling D15); a
brief example under `references/`; any question to the user during
`/kenspc-task-implement`, which stays unattended.

### The locked design (C-1 to C-8)

Restated for reference. The rulings below refine these points; they do not
reopen them. Where a ruling reads a point beyond its literal words, its row
says so and why the reading stays within the point's intent.

- **C-1 Open Questions in briefs.** A brief gains an `Open Questions`
  section: questions the discussion could not answer are listed there, and
  each can be marked `needs prototype`. generate-brief's template and writing
  rules change together.
- **C-2 An exit in generate-plan.** When Phase 1 Step 1 detects a brief whose
  Open Questions hold an unresolved `needs prototype` entry, generate-plan
  stops and asks the user: run a prototype first, or carry the question into
  the plan's own Open Questions element. A session that cannot ask takes the
  second and says so in the plan.
- **C-3 The skill.** Skill `prototype`, command `/kenspc-prototype`,
  `disable-model-invocation: true`. Input: one `needs prototype` question from
  a brief, or a question the user gives directly. Output: one throwaway
  prototype, and the question's answer written back into the brief —
  conclusion, evidence, and the prototype's commit hash; the implementation
  reads it with `git show`. UI, logic, and feature prototypes are all in
  scope, all throwaway. No review phase.
- **C-4 Location.** The project's CLAUDE.md rule if it has one; otherwise
  `prototypes/<slug>/` at the repository root; a conflict is asked about (a
  session that cannot ask takes the default and says so). Prototypes are not
  part of the build / test / lint gate. The one exception is a UI prototype
  that can only render inside the app: its location is set by CLAUDE.md or
  asked, and it keeps the typecheck green.
- **C-5 Discard.** A prototype is committed on the current branch like any
  other change; discarding it is a deletion commit (`git rm`), and history
  keeps it; the brief's answer records the commit hash; there is no "keep"
  option.
- **C-6 Development database.** Usable; production resources are never
  touched; no EF migration is added to the repository; when the prototype
  needs a new table or column, the skill first warns that the development
  database may be the wrong place and suggests a throwaway database; if the
  user insists, that is recorded, and the discard also drops the schema the
  prototype created; no hardcoded secret.
- **C-7 Hook.** `remind-plan-skill.sh`'s brief message adds `prototype`
  (batch B's ruling M6: "Batch C adds `prototype` when it lands").
- **C-8 Release.** A new command, so 3.8.0; CHANGELOG under
  `## 3.8.0 — unreleased`; the version is bumped in the release commit only;
  no tag.

Where each point lands:

| Point | Steps | Rulings |
|---|---|---|
| C-1 | 1.1 | D1, D2, D15, D16, M13 |
| C-2 | 2.1 | M2, M3, M4, D3, D4, D11 |
| C-3 | 3.1, 3.2 | M1, D5, D10, D12, D16, D17, D18 |
| C-4 | 3.1 (Phase 1 location, Phase 2 constraints, the gate table) | M6, M8, D9, D20 |
| C-5 | 3.1 (Phase 3) | M7, M10, D6, D7 |
| C-6 | 3.1 (Phase 1 database, Phase 2 constraints, the gate table) | M9, D8 |
| C-7 | 4.1 | M5 |
| C-8 | 5.3 (CHANGELOG heading; no version change anywhere in this batch) | M11 |

## Background

- **Where the chain loses questions today.** generate-brief's template has no
  place for a question the discussion could not settle; it lands in The Hard
  Part or Discovery Notes as prose, or nowhere. generate-plan's Phase 1 Step 1
  detects a brief (first line `# Requirement Brief:`, or the structured
  sections) and gap-checks it against the five discovery dimensions; its
  plan has an Open Questions element ("anything unresolved that needs future
  decision"), free-form, which `plan-document-reviewer` also writes NOTED
  items into. Nothing carries a brief's unsettled question into the plan, and
  nothing settles one by experiment.
- **The shape to follow.** `diagnose-bug` is the newest skill: rules with
  their Why, phases with Goal / Inputs / DONE when, a cannot-ask branch at
  every question ("In a session that cannot ask (a system reminder to work
  without stopping), …"), commits staged by pathspec, a stop with no retry
  and no `--no-verify` when a commit fails, references instead of copies for
  anything written once elsewhere (the `canonical:run-dir` block, the
  Doc-sync Task template), and a last message that names what was left
  behind when a run ends early.
- **The gates reach the repository root.** A committed `prototypes/<slug>/`
  is inside most project gates: a `tsconfig.json` with no `include`, or with
  `**/*` (Expo's default), typechecks it; vitest's default include collects
  any `*.test.*` or `*.spec.*` file in it; ESLint's flat config lints it (it
  ignores only `node_modules` and `.git` by default — roadmap item 7); an
  SDK-style `.csproj` at the repository root compiles every `.cs` file below
  it; pytest collects `test_*.py`. A `.slnx` whose projects live in
  subdirectories does not reach it. The plugin's stance is that no skill or
  agent edits the project's configuration to make room for its files
  (README, Run directory; Plugin Design Lessons, "Git-ignored is not
  tool-ignored") — and `prototypes/` is not even git-ignored.
- **The autonomy boundaries.** The prototype runs in the main session, like
  a diagnosis; no agent is dispatched, so `task-implementer`'s AUTONOMY
  BOUNDARIES do not bind it. Its own limits come from the same categories: a
  dependency goes into the prototype's own manifest, not the project's; the
  project's configuration is not edited; a schema change follows C-6; no
  existing API contract changes. An answer that implies one of those changes
  for the real implementation is plan work — the reason diagnose-bug sends
  its tier 3 to a brief.
- **`**Status:**` is taken.** task-implement's Step 1 and `task-implementer`'s
  PREREQUISITE CHECK recognize a task document by its `**Status:**` markers,
  so an Open Questions status written as `**Status:**` would make a brief look
  like a task document (ruling D1).
- **The hook sees Write only.** `hooks.json` matches the Write tool; an edit
  to an existing brief never reaches `remind-plan-skill.sh` (ruling M5).
- **History keeps everything.** Under C-5 a prototype stays in history after
  its discard, so anything it commits — a copied connection string, a `.env`
  — is permanent (ruling M9).

## Design decisions

Questions found while checking C-1 to C-8 against the repository. Each row
gives the options considered, the lean the draft proposed with its reason,
and the ruling. Every ruling was decided by the main session within the
locked design on 2026-09-25; it binds this batch, and the implementing
session applies it without reopening it. Three rulings depart from the
draft's lean — M8, M11, and D8 (in part) — and the Implementation Steps
follow the ruling, not the lean. A ruling that reads a locked point beyond
its literal words says so and why it stays within that point's intent.

### Mismatches between the locked design and the repository (M1–M13)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| M1 | C-3 lists `disable-model-invocation: true` beside both the skill and the command. Every command carries it (v3.4.2); no skill does. A skill that carries it cannot be invoked by the model or through the Skill tool, and its description no longer routes — which the trigger phrases (D12) assume. | (a) The command carries it; the skill routes by its description — batch B's reading of the same phrase in its B-1. (b) Both carry it: the skill runs only on `/kenspc-prototype` or `/kenspc:prototype`, and D12's triggers are moot. | (a). B-1 had the same wording and shipped as (a). The prototype commits code, so its description is narrow and names what it is not for (D12); (b) stays a one-line change if acceptance shows it misroutes. | **(a)** — decided by the main session within the locked design. The command carries `disable-model-invocation: true` and the skill routes by its description: the v3.4.2 convention, and how B-1's identical sentence shipped. Steps 3.1, 3.2. |
| M2 | C-2 gives generate-plan a cannot-ask branch, and generate-plan has none: it never tests for a session that cannot ask, and Phase 2 Step 3 writes the plan only on the user's explicit approval (the batch B acceptance's `/kenspc-plan` run stopped for approval with no file written). | (a) Define cannot-ask at the exit only, in diagnose-bug's words ("a system reminder to work without stopping"); the carried entry and its note go into the draft, and the file is still written only on approval. (b) Also let a session that cannot ask write the plan without approval. | (a). C-2 asks for a note in the plan, not a new write path; (b) changes generate-plan's approval contract, which C-2 does not mention. | **(a)** — decided by the main session within the locked design. Cannot-ask is defined at the exit only; the carried entry and its note go into the draft, and the file still waits for approval — C-2 asks for a statement in the plan, not a new write path. Step 2.1. |
| M3 | Briefs with no `## Open Questions`: every brief written before this batch, and diagnose-bug's tier-3 briefs — diagnose-bug stays zero-diff, and its template mapping names seven sections, not this one. | (a) Absence means nothing is open: generate-plan's exit and gap-check find nothing there; the prototype skill appends the section when it is given a question for such a brief. (b) Absence is a gap generate-plan asks about. | (a). The exit reads entries, and a brief without the section has none; asking about a section its author could not have known adds a round to every older brief. | **(a)** — decided by the main session within the locked design. No section means no unresolved entry; the prototype skill adds the section when it is given a question for such a brief — the authors of older briefs and of diagnose-bug's briefs could not have known the section. Steps 1.1, 2.1, 3.1. |
| M4 | C-2 covers `needs prototype` entries. A brief's `open` entries — questions discussion could not settle and no experiment would — have no treatment in generate-plan, whose gap-check covers the five dimensions only. | (a) The gap-check brings each `open` entry into its rounds; one the rounds do not settle is carried into the plan's Open Questions with its source. (b) Carry every `open` entry without asking. (c) Leave it to the model. | (a). An `open` entry is an explicit gap, which is what the gap-check is for; (c) lets a plan drop a question the brief recorded. The one-to-two-round limit is unchanged. | **(a), with a cannot-ask branch** — decided by the main session within the locked design. In a session that cannot ask, no `open` entry enters the gap rounds: each is carried straight into the plan's Open Questions in the carried form, with `From:` and `Assumed in:` and no `Not prototyped:`. Why: the gap-check now asks about `open` entries, so that question point needs a cannot-ask branch like every other (Standing constraints). Step 2.1. |
| M5 | The reminder hook matches `Write` only (`hooks.json`); the prototype's write-back is an edit of an existing brief, which the hook never sees. C-7's added name matters only when a brief is written whole. | (a) Add the name as C-7 says, worded for what the skill does — it records an answer in an existing brief. (b) Also match the Edit tool. | (a). The hook is a soft reminder about who writes a brief; matching Edit would fire on every edit of every brief, most of them the user's own. | **(a)** — decided by the main session within the locked design. The name is added as C-7 says, worded as recording an answer in an existing brief; hooks do not guard workflow state (Plugin Design Lessons). Step 4.1. |
| M6 | C-4 keeps prototypes out of the build / test / lint gate, but those gates reach a committed `prototypes/<slug>/` (Background: tsconfig include, vitest's default include, ESLint's flat config, a root-level `.csproj`, pytest), and the plugin does not edit the project's configuration to exclude its own files. | (a) Keep the stance: prototype files follow the naming rule of the Scratch space bullet in the `canonical:run-dir` block, by reference; the skill runs none of the project's gates on the prototype; the prototype is in HEAD for one commit only (D6); a gate that walks into it in that window is Known behavior. (b) Require the project to exclude the location and stop when it does not. (c) The skill adds the exclusions. | (a). (c) is what the stance rules out; (b) stops every first prototype on configuration the user never needed. With the discard right after the answer (D6), HEAD after the run holds no prototype. | **(a)** — decided by the main session within the locked design. The user's configuration is not edited; names follow the Scratch space naming rule of the `canonical:run-dir` block, referenced and not copied; the project's gates are not run on the prototype; the prototype spends one commit in HEAD; the rest is Known behavior — the stance of "Git-ignored is not tool-ignored". Steps 3.1, 5.2, 5.3. |
| M7 | C-5's discard is a deletion commit (`git rm`). An in-app UI prototype (D9) usually also modifies tracked files — a route table, a navigation entry — and `git rm` does not undo a modification. | (a) Define the discard by its end state: one commit after which every path the prototype commit touched has its content in that commit's parent — `git rm` for paths it added, restored from the parent for paths it modified. (b) `git revert` of the prototype commit. (c) Forbid in-app prototypes to modify tracked files. | (a). It is exactly `git rm` wherever the prototype only added files; (b) reaches the same end state with git's own message form and a conflict if anything touched those paths in between; (c) rules out most of the prototypes C-4's exception exists for. | **(a)**, within C-5's intent — decided by the main session within the locked design. The discard is still one deletion commit and history keeps the prototype; only a tracked file the prototype modified is restored to its content in the prototype commit's parent. For a prototype that only added files — every prototype outside the app — it is literally `git rm`. Step 3.1. |
| M8 | C-4's exception is a UI prototype that can only render inside the app. A feature prototype — an end-to-end slice — can need the app's runtime for a similar reason: a route registered in the app's router, a handler resolved from its dependency-injection container. | (a) Widen the exception to any prototype that needs the app to run, UI or feature, under the same rules. (b) The exception stays UI-only; a feature prototype that needs the app is not built, and its entry stays unsettled with that reason. | (a), flagged as reading C-4 by its reason rather than its example: the rules that make the exception safe do not depend on whether the prototype renders. | **(b), departing from the lean** — decided by the main session within the locked design. C-4 names the UI prototype that can only render inside the app as the one exception; widening it to features would reopen C-4's words. A feature prototype that needs the app's runtime runs outside the app when importing the app's modules lets it; otherwise it is not built, the entry stays `` `needs prototype` `` with the reason in Evidence, and the exit says that widening the exception is the user's decision. D9, the gate table, and README's Known behavior item speak of UI prototypes only. Feature prototypes stay in scope (C-3). Steps 3.1, 5.2, 5.4. |
| M9 | Under C-5 history keeps every prototype, so a secret a prototype commits survives its discard; C-6 says only "no hardcoded secret". | (a) The prototype reads every credential and connection string by name at run time — the project's configuration keys, environment variables, or secret store — never prints one, and commits no file holding a value it read (a `.env`, a copied `appsettings.*.json`); before the add commit the skill reads the staged file list and diff for such a file. (b) No rule beyond C-6. | (a). Here a committed secret is permanent by design, and the check is one look at a diff the skill staged itself. | **(a)** — decided by the main session within the locked design: the necessary consequence of C-6's "no hardcoded secret" once history keeps everything. Step 3.1. |
| M10 | `git rm` removes tracked files only. What the prototype produced that git does not track — installed dependencies under its location, a prototype project's `bin/` and `obj/`, a local database file — stays on disk after the discard, and an ignored `obj/*.cs` still compiles into a root-level `.csproj`. | (a) The exit names every such path under the prototype's location, for the user to remove; the skill deletes nothing. (b) The skill removes them. | (a). Recursive deletes are what users' permission rules deny — the reason the run-directory block never deletes — and it would be the one irreversible step in a run that history otherwise backs. | **(a), widened** — decided by the main session within the locked design. The exit's list covers every path under the location that `git status --porcelain --ignored -uall` still lists, ignored (`!!`) and untracked (`??`) alike — a `.gitignore` that says only `/node_modules` leaves a nested `node_modules` untracked, not ignored. The skill deletes nothing, for the run-directory block's reason. Steps 3.1, 5.2. |
| M11 | `docs/roadmap.md`: the heading `## Next minor (3.8.0)` names the version C-8 gives this batch, whose release does not ship those items; batch C's line is the last under "Planned batches"; item 7 (linters walk into `.kenspc/`) holds for `prototypes/` during a prototype's two commits. | (a) This batch retitles the heading to the next minor version, removes the "Planned batches" section, and adds one sentence to item 7. (b) Leave the heading and the section to the release commit, which the release procedure already has retitle the roadmap; add item 7's sentence here. | (a). Under C-8 the heading is wrong from this batch's first commit. | **(b), departing from the lean** — decided by the main session within the locked design. The heading retitle, batch C's line, and the emptied "Planned batches" section are the release commit's, as the main session's release preparation assigns them and as earlier releases did (an item leaves the roadmap when it ships). This batch adds only item 7's sentence. Steps 5.3, and Documentation impact. |
| M12 | Counts, lists, and descriptions: release-checklist row 1 says 7 commands; CLAUDE.md says "all seven skills", "syncing seven files", "bump all seven", and "the six other skills", and its Project Overview, directory layout, hooks paragraph, "No review" orchestration pattern, and Non-Goals list the no-review skills, the brief writers, and the references to the `canonical:run-dir` block; `plugin.json` and `marketplace.json` say what the skills cover; both READMEs list skills and commands. | The counts become eight and seven; `prototype` joins each list; `plugin.json` adds prototyping after brief generation; `marketplace.json` adds "prototypes" after "discovery brief". | Mechanical; no alternative considered. | **Mechanical update** — decided by the main session within the locked design. Steps 5.1, 5.2, 5.4. |
| M13 | generate-brief's next-step suggestion names only `/kenspc-plan <path>`. | (a) When the brief has a `needs prototype` entry, the suggestion names `/kenspc-prototype <path> <n>` for each first, and says generate-plan will ask about them otherwise; the no-auto-trigger constraint stays. (b) Unchanged. | (a). The suggestion is how the user learns the next command; generate-plan's exit would raise the entry anyway, one run later. | **(a)** — decided by the main session within the locked design. `/kenspc-prototype <path> <n>` is listed first; the "do not auto-trigger" constraint stays. Step 1.1. |

### Architecture choices (D1–D20)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| D1 | The Open Questions entry: format, status words, labels, and where the grammar is written. | (a) A numbered list. Each entry starts with its status in backticks — `` `open` ``, `` `needs prototype` ``, or `` `answered` `` — then ` — ` and the question. Sub-bullets: `Settled by:` on every `needs prototype` and `answered` entry; `Answer:`, `Evidence:`, `Prototype:`, written by the prototype skill. A new brief always carries the section, with the body `none` when nothing is open. Status words and labels stay in English whatever the brief's language. The grammar is written once, in generate-brief's template and writing rules; the prototype skill points at it. (b) A `**Status:**` sub-line per entry. (c) A heading per question. (d) An unmarked entry means `open`. | (a). (b) collides with task documents (Background), so a brief passed to `/kenspc-task-implement` by mistake would pass its validation. (c) puts headings in a section read as a list and multiplies anchors. (d) makes an entry whose marker was lost in an edit look open. One grammar written once and referenced is diagnose-bug's pattern for the Doc-sync Task template. Numbering gives `/kenspc-prototype` a handle (`<brief> 2`). | **(a)** — decided by the main session within the locked design: backticked status words and sub-bullet labels; the section always present, `none` when empty; `**Status:**` is already the task document's marker. Steps 1.1, 2.1, 3.1. |
| D2 | What generate-plan reads as unresolved, and the shape an unsettled prototype leaves. | (a) Unresolved means the status word is `needs prototype`; nothing else is read. A prototype that did not settle its question — inconclusive, needing a judgment the session could not ask for (D10), or not built (M8, D9) — leaves the status `needs prototype` and adds `Evidence:`, with `Prototype:` when one was committed, and no `Answer:`. (b) A fourth status, `prototyped`. (c) Unresolved means "no `Answer:` line". | (a). One token at one position decides, and the prototype skill rewrites exactly that token when it settles a question; an unsettled question is still unresolved for planning. | **(a)** — decided by the main session within the locked design: only the status word is read; an unsettled attempt keeps `` `needs prototype` ``, adds `Evidence:` and `Prototype:`, and has no `Answer:`. A question for which nothing was built adds `Evidence:` only. Steps 1.1, 2.1, 3.1. |
| D3 | Where the exit sits in generate-plan, and what "prototype first" does. | (a) In Phase 1 Step 1, right after a brief is detected and before the gap-check. One question lists every `needs prototype` entry and takes an answer per entry. "Prototype first" ends the run with one `/kenspc-prototype <brief> <n>` line per entry so chosen and invokes nothing. (b) Same position, but "prototype first" invokes the prototype skill through the Skill tool. (c) After the gap-check. | (a). Before the gap-check, because a prototype changes the brief the gap-check reads; stop-and-suggest because each prototype is one run with two commits and the plan is re-run on the updated brief anyway. | **(a)** — decided by the main session within the locked design: before the gap-check; stop and print the commands, no nested invocation — generate-brief's "do not auto-trigger" is the nearer precedent. Step 2.1. |
| D4 | The form of a carried entry in the plan's Open Questions element. | (a) The status word kept, with sub-bullets `From: <brief path>, entry <n>`; `Not prototyped: <reason>` (on `needs prototype` entries); `Assumed in: <the steps that assume an answer, and what they assume>`. Marker and labels in English whatever the plan's language. The plan example is unchanged. (b) The question as free text with a note. | (a). The marker keeps the question findable for a later `/kenspc-prototype` run, the source path is where that run writes its answer, and `Assumed in:` makes the plan state the assumption it took. | **(a)** — decided by the main session within the locked design: the marker and source path kept, `Assumed in:` added; the plan example unchanged. Carried `open` entries (M4) take the same form without `Not prototyped:`. Step 2.1. |
| D5 | A question given directly, with no brief: where the answer goes. | (a) A brief is required. A question given as text together with a brief path is appended to that brief's Open Questions as `needs prototype` and answered there; with no brief the skill stops, builds nothing, and suggests `/kenspc-brief`. (b) The skill writes a minimal brief holding the title line and the one entry. (c) The answer lives only in the remove commit's message. | (a). A minimal brief starting `# Requirement Brief:` reaches generate-plan as a brief with every dimension a gap, and the gap-check's one-to-two-round limit is the wrong treatment for that; (c) leaves generate-plan nothing to read. | **(a)** — decided by the main session within the locked design: a brief is required; with none the skill stops and suggests `/kenspc-brief`. A minimal brief would enter the gap-check with all five dimensions missing, against its one-to-two-round limit. Step 3.1. |
| D6 | When the prototype is discarded. | (a) Immediately after the answer is written into the brief, in the same run. (b) After the plan is written. (c) When the user says so. | (a). C-5 has no keep option; each commit the prototype spends in HEAD is a commit whose gates can see it (M6), and the in-app discard is exact only while nothing else has touched those paths (M7). | **(a)** — decided by the main session within the locked design: discarded immediately after the write-back. Step 3.1. |
| D7 | Commits. | (a) `chore: add prototype <slug>` and `chore: remove prototype <slug>`, adapted to the project's commit conventions. The add commit is made after the run that produced the evidence. Each commit stages only the prototype's own paths — its source, its manifest and lockfile, evidence files the answer cites, and for a UI prototype in the app the tracked files the frame named — never installed dependencies or build output, and passes them to `git commit` as a pathspec. The remove commit's body carries `Question:`, `Answer:` (or `Not settled:`), and `Prototype: <hash>`. A commit that fails stops the run and asks, with no retry and no `--no-verify`. The brief is not committed. (b) `test:` or `feat:` as the type. (c) Commit before running. (d) Commit the brief with the remove commit. | (a). `chore` because nothing ships; after the run because the hash has to name what produced the evidence; the pathspec keeps the user's staged work out; the brief stays uncommitted as generate-brief and diagnose-bug leave theirs, and the remove commit's body keeps the answer and hash in history. | **(a)** — decided by the main session within the locked design. Step 3.1. |
| D8 | Which database connection counts as the development database, where the schema warning comes, and the cannot-ask branch. | (a) Development means named by the project's development configuration: a file named for development (`appsettings.Development.json`, `.env.development`, `.env.development.local`), the project's user-secrets, or a database the project's CLAUDE.md or README names as the development one; any other connection is asked about, and a session that cannot ask does not use it. The warning comes while framing, before any code, when the prototype needs a new table or column — or writes rows to an existing table; if the user insists, Evidence records it and a teardown runs before the remove commit; a session that cannot ask uses a throwaway database. No migration file is added or applied, for any migration tool. (b) Schema only, and EF only, as C-6 words it. (c) Any connection the project holds counts as development. | (a), flagged as extending C-6 twice: row writes to existing tables get the warning too, and "no EF migration" becomes "no migration, any tool". | **In part, departing from the lean on row writes** — decided by the main session within the locked design. Adopted: development is recognized by name only (a development-named configuration file, the project's user-secrets, a development database the project's CLAUDE.md or README names); any other connection is asked about and, in a session that cannot ask, not used; the warning comes before any code; a user who insists is recorded, with a teardown script run before the remove commit; a session that cannot ask uses a throwaway database. "No EF migration added to the repository" widens to "no migration added or applied, with any tool" — flagged, within C-6's intent, because the reason (the project's migration history belongs to the product) does not depend on the tool. Not adopted: row writes to existing tables trigger no warning and need no teardown — C-6 names a new table or column as the trigger and calls the development database usable — but Evidence names every existing table the prototype wrote to, so the user knows development data changed. The gate table's database row reads "A new table or column on the development database" only. Steps 3.1, 5.2, 5.4. |
| D9 | The in-app UI prototype (C-4's exception; UI only per M8). | (a) Location from CLAUDE.md, or asked; a session that cannot ask with no CLAUDE.md location builds nothing and leaves the entry unsettled with that reason. Before building, the project's typecheck command runs unmodified as a baseline; the add commit needs it green — or, when the baseline was already red, no error the baseline lacked. A tracked file the prototype must modify that has uncommitted changes, and any change to the project's manifest, are asked about; a session that cannot ask builds nothing. Test and lint are not run. (b) A session that cannot ask picks a location from the app's conventions. | (a). No default location inside someone's app is defensible, and a guessed one is an edit to the user's source tree nobody chose. The baseline makes "keeps the typecheck green" checkable when the project was red before the run. The uncommitted-file rule is code-fixer's lesson; a manifest change is the dependency stop in `task-implementer`'s AUTONOMY BOUNDARIES. | **(a), for UI prototypes only (M8)** — decided by the main session within the locked design. "No error the baseline lacked" when the baseline was already red is the reading of "keeps the typecheck green" — flagged, within C-4's intent, since a run cannot turn green a typecheck that was red before it. Step 3.1. |
| D10 | Answers that are the user's judgment (how a UI feels, whether a flow reads right). | (a) In a session that can ask: after the add commit the skill tells the user how to see the prototype (a command, a route) and waits; the user's verdict is the Answer, and Evidence says it was judged by the user and on what; then the write-back and the discard. In a session that cannot ask: the prototype is committed and discarded, the entry stays `needs prototype` with Evidence naming what the user has to look at and how, and the exit says so. (b) The skill judges it itself. | (a). A judgment question answered by the agent is a guess recorded as an answer; waiting before the discard is the only time the user can see the prototype running without restoring it from history. | **(a)** — decided by the main session within the locked design. Step 3.1. |
| D11 | Is the brief transient or durable, does a prototype have a Documentation impact, and how does its answer reach durable documents? | (a) The brief is transient: this repository's CLAUDE.md lists `docs/briefs/` under "Workflow artifacts under docs/" and not in its Durable documents table, and the plugin treats a brief as a discovery artifact it never commits. A prototype writes no durable document and has no Documentation impact element. Its answer reaches durable documents through the plan: generate-plan reads `answered` entries as settled input, a plan that relies on one cites the prototype's hash, and the plan's own Documentation impact covers the documents. (b) The prototype edits durable documents itself. | (a). The prototype is discarded, so there is nothing for a durable document to describe; a decision its answer implies is plan work. | **(a)** — decided by the main session within the locked design: the brief is a transient discovery artifact, the prototype has no Documentation impact, and its answer reaches durable documents through the plan, which cites the hash. Steps 2.1, 3.1. |
| D12 | Triggers, and what the description blocks. | (a) Positive: "prototype this", "spike this question", "build a quick prototype to find out", "try it out before we plan", "answer the open question in the brief", "做个原型", "先做个原型验证一下", "写个原型试试", "用原型回答这个问题", "原型验证一下这个问题". Blocked: a feature to keep ("just build it", "直接做这个功能", a demo for a client) → generate-plan or generate-task, or direct work for a small change; running or trying out a snippet ("帮我试一下这段代码", "run this and see what it prints") → just run it; a bug ("this crashes when") → diagnose-bug; a question discussion can settle ("which library is better?") → discuss, or generate-brief. The description names the first three blocks. (b) Positive triggers only. | (a). The skill commits twice and may use a development database, so a false trigger costs more than a missed one. | **(a)** — decided by the main session within the locked design. Step 3.1. |
| D13 | Guarding the new anchor. | (a) One new group in `check-doc-sync-anchors.sh`: `needs prototype` in `generate-brief/SKILL.md`, `generate-plan/SKILL.md`, and `prototype/SKILL.md`; the header broadens to the anchors the planning chain passes between skills; `guards run: 10` and `self-tests run: 9` stay. (b) A new guard script (11 / 10). (c) No guard. | (a). The status word is the one token three files must spell the same; batch B added diagnose-bug's entries the same way without touching the counts. `## Open Questions` is not guarded: generate-plan already carries the phrase for its own element. | **(a)** — decided by the main session within the locked design; counts stay `guards run: 10` and `self-tests run: 9`. Step 4.2. |
| D14 | Where the new smoke row goes. | (a) Row 10, before the end-to-end row, which becomes row 11 — batch B's precedent. (b) Row 4, after `/kenspc-brief`, renumbering rows 4–10. | (a). Only the two "row 10" references move; (b) moves every reference from row 4 on. | **(a)** — decided by the main session within the locked design: new row 10; end-to-end becomes row 11. Step 5.4. |
| D15 | Whether `shared/discovery-framework.md` changes. | (a) No. generate-brief's Phase 1 gains the rule that a question the conversation cannot settle is noted for Open Questions and not argued further. (b) The framework gains the rule, for both callers. | (a). The framework leaves output format to the calling skill, and generate-plan's discovery already has its own Open Questions element. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D16 | What counts as evidence. | (a) In the skill's Quality bar: the prototype is the smallest thing that settles the question, and the evidence states what was run, what it showed, and the case that could have come out the other way — the `Settled by:` result measured against, or a control that fails when the claim is false. (b) No rule beyond C-3's "conclusion + evidence". | (a). The falsifiability rule the plugin applies to tests, applied to evidence; `Settled by:` makes it checkable because it is written before the prototype runs. | **(a)** — decided by the main session within the locked design. Steps 1.1, 3.1. |
| D17 | Whether the skill confirms its frame before building. | (a) No general confirmation: the skill shows the frame and goes on; only the gates in Step 3.1 stop it. (b) Confirm every frame. | (a). Each risky choice has its own gate with a cannot-ask branch; a blanket confirmation adds a stop to the path that needs none. | **(a)** — decided by the main session within the locked design. Step 3.1. |
| D18 | Choosing the question. | (a) By the number or text the user gives. With none: the brief's only `needs prototype` entry; with several, ask which — a session that cannot ask takes the first in document order and says so. A named `answered` entry: ask whether to prototype it again; a session that cannot ask stops. A named `open` entry is prototyped like any other. (b) Prototype every `needs prototype` entry in one run. | (a). C-3's input is one question; one run per question keeps one prototype per pair of commits. | **(a)** — decided by the main session within the locked design. Step 3.1. |
| D19 | The prototype's own dependencies. | (a) Outside the app, a dependency is installed into the prototype's own manifest under its location, never into the project's. For a UI prototype in the app, a dependency the app has to load is a manifest change and is asked about (D9). (b) Every dependency is asked about. | (a). The library under evaluation is often the question itself; installed where only the prototype sees it, it changes nothing the project builds. | **(a)** — decided by the main session within the locked design. Step 3.1. |
| D20 | Location conflicts under C-4, and their cannot-ask branch. | (a) The location is `prototypes/<slug>/` at the repository root (`git rev-parse --show-toplevel`) unless the project's CLAUDE.md names another. A conflict is asked about: `prototypes/` already holds tracked files that are not prototypes, or CLAUDE.md's location does not fit the kind (an outside-the-app location for a UI prototype that can only render in the app — D9 then decides). A session that cannot ask takes the default and says so. An existing `prototypes/<slug>/` holding only leftovers (M10) is not a conflict: the next free `<slug>-<n>/` is used. (b) Ask whenever `prototypes/` exists. | (a). After a first prototype, `prototypes/` exists in every repository that used the skill, so (b) would ask on every later run. | **(a)** — decided by the main session within the locked design. Step 3.1. |

### Standing constraints

- Rules are rationale-anchored ("Why: …" prose), not imperatives; no `MUST`
  / `NEVER` / `CRITICAL`, no inline effort or reasoning tokens, no model
  names (`check-no-model-names.sh` scans `skills/`, `agents/`, `commands/`,
  and `shared/`, so the new skill and command are covered).
- A check written into a skill is in rubric form: what passing looks like,
  then the named ways it fails. No generic checklist items.
- No edit inside any byte-identity section, with no exception in this batch:
  the canonical blocks, the code-craft canonical paragraphs, and the five
  reviewers' shared sections are untouched, and every guard stays green
  (`check-doc-sync-anchors.sh` is extended by Step 4.2).
- No new agent (`plugin.json` says "eleven reusable subagents"): the
  prototype runs in the main session, which keeps the conversation, the
  judgment point, and the commits in one context. No new CONTEXT key.
- Zero diff in `task-implement/SKILL.md`, `task-implementer.md`,
  `generate-task/SKILL.md`, `task-review/SKILL.md`, `diagnose-bug/SKILL.md`,
  `plan-document-reviewer.md`, and `task-document-reviewer.md`; the files
  this batch touches are generate-brief, generate-plan, the new skill and
  command, the hook, the guard, and the documents in
  [Documentation impact](#documentation-impact).
- The `canonical:run-dir` block is written once; the prototype skill points
  at its Scratch space naming rule and carries no copy.
- `effort:` frontmatter unchanged in every file (release-checklist
  pre-flight diff); the new skill has none and follows the session.
- Per-skill `version: 3.0.0` in every skill, the new one included.
- Every question point this batch adds — each gate of the prototype skill,
  generate-plan's exit, and the gap-check's question about an `open` entry —
  has a cannot-ask branch, worded as diagnose-bug words it: "In a session
  that cannot ask (a system reminder to work without stopping), …".
- Plugin files state their evidence in their own words and carry no pointer
  labels — B-n, C-n, M-n, D-n, CL-n, "ruling", batch names, dry-run records.
  The criterion for every plugin file this batch writes or edits (the two
  skills, the new skill and command, the hook):
  `grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\b[BC]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>`
  prints nothing. It prints nothing on `generate-brief/SKILL.md`,
  `generate-plan/SKILL.md`, `remind-plan-skill.sh`, and
  `diagnose-bug/SKILL.md` today, and 112 lines on the batch B spec, so it
  can fail.
- Plugin Design Lessons apply: phase transitions rest on artifacts (the
  shown frame, the add commit's hash, the rewritten entry and the remove
  commit), and no hook guards workflow state.
- This spec and the acceptance record are in English.
- The dogfood: the task document for this batch comes from `/kenspc-task` on
  this spec, which generates the Doc-sync task from the Documentation impact
  below; it is not added by hand.

## Fixed strings

These strings are load-bearing: the guard asserts one of them, the release
checklist greps for them, and skills parse them. Spell them exactly as given,
in every file that carries them.

| Anchor | Exact form | Carried by |
|---|---|---|
| Section heading | `## Open Questions` | `generate-brief/SKILL.md` (template), briefs, `generate-plan/SKILL.md`, `prototype/SKILL.md` |
| Status words | `` `open` ``, `` `needs prototype` ``, `` `answered` `` — in backticks, first on the entry's line, followed by ` — ` and the question | `generate-brief/SKILL.md`, `generate-plan/SKILL.md`, `prototype/SKILL.md`, briefs, plans (carried entries: `open` and `needs prototype` only) |
| Entry labels | `Settled by:`, `Answer:`, `Evidence:`, `Prototype:` as sub-bullets, in that order | `generate-brief/SKILL.md`, `prototype/SKILL.md`, briefs |
| Prototype line | ``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` `` | `generate-brief/SKILL.md` (the answered form), `prototype/SKILL.md`, briefs |
| Carried-entry labels | `From:`, `Not prototyped:` (on `needs prototype` entries only), `Assumed in:` | `generate-plan/SKILL.md`, plans |
| Empty section | the body `none` | `generate-brief/SKILL.md`, briefs |
| Default location | `prototypes/<slug>/` at the repository root | `prototype/SKILL.md`, `plugins/kenspc/README.md` |
| Commit subjects | `chore: add prototype <slug>`; `chore: remove prototype <slug>` (both adapted to the project's commit conventions) | `prototype/SKILL.md`, `docs/release-checklist.md` (row 10) |
| Remove-commit body | `Question:`, `Answer:` or `Not settled:`, `Prototype: <hash>` | `prototype/SKILL.md`, `docs/release-checklist.md` (row 10) |
| Command and skill | `/kenspc-prototype`, skill `prototype`, `/kenspc:prototype` | `commands/kenspc-prototype.md`, `prototype/SKILL.md`, READMEs, CLAUDE.md, release checklist |

## Implementation Steps

Phase 1 comes first: Phases 2 and 3 point at the grammar it writes. Phases 2
and 3 are independent of each other. Phase 4 needs Phases 1–3 (the anchor it
guards must exist in all three files). Phase 5 comes last.

### Phase 1: Open Questions in briefs (C-1)

**Step 1.1: Template, writing rules, discovery rule, and next step in `generate-brief`**

- File: `plugins/kenspc/skills/generate-brief/SKILL.md`. The frontmatter,
  Trigger Phrases, Discovery Mode Detection, output path resolution, and
  conflict check are unchanged.
- Brief template: a `## Open Questions` section after `## Context` and
  before `## Discovery Notes` (Discovery Notes stays last, with its
  `Discovery Mode:` field), in substance:

  ```markdown
  ## Open Questions
  [Questions the discussion could not settle, numbered; `none` when nothing
  is open. Each entry starts with its status:

  1. `open` — <a question neither discussion nor a small experiment settles:
     a decision someone else makes, information nobody present has>
  2. `needs prototype` — <a question a small experiment settles faster or
     more reliably than more discussion: feasibility, performance, how a
     library or an API behaves, how a UI reads>
     - Settled by: <the result that answers it — a measurement against a
       threshold, a behavior that does or does not occur, a rendering the
       user judges>]
  ```

- Writing rules for the brief, added (rulings D1, D2, D16):
  - Open Questions is always present; its body is `none` when nothing is
    open. Why: a reader — and generate-plan — can then tell "nothing open"
    from "not considered".
  - The status words `` `open` ``, `` `needs prototype` ``, and
    `` `answered` ``, and the labels `Settled by:`, `Answer:`, `Evidence:`,
    and `Prototype:`, stay exactly as written, in English, whatever the
    brief's language. Why: generate-plan finds an unresolved entry by its
    status word, and the prototype skill rewrites that word when it settles
    the question; a translated word breaks the chain without an error.
  - `needs prototype` only for a question an experiment settles; a decision
    that belongs to a person is `open`.
  - Every `needs prototype` entry has `Settled by:`, naming a result, not
    the steps to build the prototype. Why: the prototype's evidence is
    measured against it, and written before the prototype runs it cannot be
    bent to fit the result.
  - generate-brief writes only `open` and `needs prototype`. The
    `/kenspc-prototype` skill rewrites an entry it settles, keeping the
    question and `Settled by:`:

    ```markdown
    3. `answered` — <question>
       - Settled by: <unchanged>
       - Answer: <the conclusion>
       - Evidence: <what was run, what it showed, and the case that could
         have shown the opposite>
       - Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>`
    ```

    An attempt that did not settle the question keeps
    `` `needs prototype` `` and adds `Evidence:` — with `Prototype:` when a
    prototype was committed — and no `Answer:`.
- Phase 1 Constraints, one bullet (ruling D15): a question the conversation
  cannot settle is noted for Open Questions and not argued further; one an
  experiment would settle is marked `needs prototype`, with what would
  settle it asked of the user — or, in `rapid-inferred (reminder-driven)`
  mode, inferred and tagged as that mode tags every inferred field.
- Next-step suggestion (ruling M13): when the brief has a `needs prototype`
  entry, the suggestion names `/kenspc-prototype <path> <n>` for each first
  and says `/kenspc-plan` will ask about them otherwise. The "do not
  auto-trigger generate-plan" constraint stays, and the skill does not
  invoke the prototype skill either.
- Done when: the section is in the template between Context and Discovery
  Notes with the two entry forms; the writing rules carry the answered form,
  the unsettled form, the anchor rule, and their Whys; the discovery bullet
  and the next-step suggestion are present; the pointer-label grep in
  Standing constraints prints nothing on the file.
- Why: the grammar is written once, where briefs are defined; generate-plan
  and the prototype skill point at it.

### Phase 2: The exit in generate-plan (C-2)

**Step 2.1: Read Open Questions in Phase 1 Step 1; the carried-entry form**

- File: `plugins/kenspc/skills/generate-plan/SKILL.md`. `effort: xhigh`, the
  brief-detection rule, the five-dimension gap-check itself, Phase 2's
  approval gate, and Phase 3 are unchanged.
- Phase 1 Step 1, "If it is a brief", in this order (rulings D3, M2, M3, M4,
  D11):
  1. **Open questions to prototype.** Read the brief's `## Open Questions`
     (grammar: `${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md`,
     Writing rules for the brief). When it lists an entry whose status is
     `` `needs prototype` ``, stop before any gap-check question and ask one
     question listing each such entry: prototype it first, or carry it into
     the plan. An entry the user sends to prototyping ends the run with one
     line per entry, `/kenspc-prototype <brief path> <n>`; the skill invokes
     nothing and writes no file. Carried entries go into the plan's Open
     Questions element in the carried form below. In a session that cannot
     ask (a system reminder to work without stopping), carry every such
     entry, with `Not prototyped: the session could not ask`. Why: a
     prototype changes the brief the gap-check reads, and a plan built on a
     question an experiment could settle builds on a guess unless it says
     so. A brief with no `## Open Questions` section, or with the body
     `none`, has nothing to stop on.
  2. **Gap-check**, as today, plus the brief's `` `open` `` entries: each is
     a gap for the same one-to-two rounds; one the rounds do not settle is
     carried into the plan's Open Questions in the carried form, without
     `Not prototyped:`. In a session that cannot ask, no `open` entry enters
     the gap rounds: each is carried straight in, in the same form. Why: an
     `open` entry is an explicit gap the brief recorded, and a plan that
     drops it loses the question without a trace.
  3. **Answered entries** are settled input. A plan that relies on one cites
     its prototype hash where it does. Why: the brief is a discovery
     artifact and may be deleted; the hash in the plan keeps the evidence
     reachable.
- Phase 2 Step 1, the Open Questions element: an entry carried from a brief
  takes this form (ruling D4):

  ```markdown
  1. `needs prototype` — <question>
     - From: <brief path>, entry <n>
     - Not prototyped: <the user chose to carry it | the session could not ask>
     - Assumed in: <the steps that assume an answer, and what they assume>
  2. `open` — <question>
     - From: <brief path>, entry <n>
     - Assumed in: <the steps that assume an answer, and what they assume>
  ```

  Why `Assumed in:`: carrying a question is safe only when the plan says
  which of its steps rest on an assumed answer.
- Writing rules for the plan: the carried entry's status word and its labels
  stay as written in a plan in another language, as the
  `## Documentation impact` heading does.
- Done when: the three-part order, the exit question and its cannot-ask
  branch, the `open` entries in the gap-check with their cannot-ask branch,
  the stop-and-suggest line, the carried form for both statuses with its
  Why, and the language rule are present; nothing else in the file changes;
  `bash scripts/check-no-model-names.sh` exits 0; the pointer-label grep
  prints nothing on the file.
- Why: C-2 is the only change to generate-plan, and generate-plan is the one
  skill that reads what the brief and the prototype write.

### Phase 3: The prototype skill (C-3 to C-6)

**Step 3.1: Write `skills/prototype/SKILL.md`**

- File: `plugins/kenspc/skills/prototype/SKILL.md` (new). Structure and tone
  of diagnose-bug: frontmatter, Trigger Phrases, Quality bar, Prerequisites,
  Arguments, three phases with Goal / Inputs / DONE when / Constraints, an
  Exit, writing rules, Phase transitions; every rule with its Why; file
  references through `${CLAUDE_PLUGIN_ROOT}`.
- Frontmatter: `name: prototype`; `version: 3.0.0`;
  `argument-hint: <brief path> [entry number or question]`; no `effort:`;
  no `disable-model-invocation` (ruling M1); `description`, in substance
  (wrapped as the other skills wrap it):

  > Answer one open question from a requirement brief with a throwaway
  > prototype (原型) — logic, UI, or a feature slice — then record the
  > answer, the evidence, and the prototype's commit in the brief and remove
  > the prototype in the next commit. Use when a brief's Open Questions entry
  > is marked needs prototype, or the user asks to settle a question by
  > building something before planning. Not for building a feature to keep
  > (use generate-plan or generate-task), not for running or trying out a
  > snippet (just run it), and not for fixing a bug (use diagnose-bug).
  > Trigger on: "prototype this", "spike this question", "build a quick
  > prototype to find out", "做个原型", "先做个原型验证一下",
  > "写个原型试试", "用原型回答这个问题", or invokes /kenspc-prototype
  > directly.

- Trigger Phrases: the positive phrases of ruling D12, English and Chinese;
  "Avoid triggering" lists the four blocks of D12, each with where it goes.
- Quality bar (ruling D16), in substance: a useful prototype is the smallest
  thing that settles its question, and its evidence could have come out the
  other way — it is measured against the entry's `Settled by:` result, or
  carries a control that fails when the claim is false. A prototype that
  only shows its happy path settles nothing, and one that grows past its
  question is feature work.
- Prerequisites: a git repository (C-5 commits the prototype and its
  removal); a brief (ruling D5).
- Arguments: `BRIEF` and an optional `ENTRY` — a number in the brief's Open
  Questions, or a question's text. A question with no brief path: stop,
  build nothing, and suggest `/kenspc-brief` (ruling D5). No arguments: ask
  for the brief and the question; in a session that cannot ask, stop.
- Phase 1, Frame. Goal: one question, the result that settles it, the kind
  (logic, UI, feature), the location, and the resources — every gate below
  passed. Inputs: the brief; the project's CLAUDE.md, README, and config
  files, read silently first; `git -c core.quotePath=false status
  --porcelain -uall`, noted at the start so the run can tell its own files
  from the user's and knows which tracked files have uncommitted changes.
  - Question selection per ruling D18. A question given as text for a brief
    that lacks it — or lacks the section — is appended as a
    `` `needs prototype` `` entry, with the section created when missing
    (ruling M3), before anything is built. An entry with no `Settled by:`
    gets one from the question, shown in the frame.
  - Kind and location (rulings D20, M8, D9). A logic or UI prototype that
    runs on its own goes to the location. A UI prototype that can only
    render inside the app is the one in-app kind: its location comes from
    CLAUDE.md or is asked. A feature prototype that needs the app's runtime
    runs outside the app, importing the app's modules, when that lets it
    run; otherwise it is not built, the entry stays `` `needs prototype` ``
    with the reason in `Evidence:`, and the exit says that widening the
    in-app exception to features is the user's decision. Why: the in-app
    exception exists for what can only render inside the app, and anything
    that can run elsewhere keeps its files out of the user's source tree.
  - Database per rulings D8 and M9; dependencies per ruling D19.
  - DONE when the frame is shown to the user — question, `Settled by:`,
    kind, location, resources — and no gate is open. No general
    confirmation (ruling D17).
- The gates, each with its cannot-ask branch (the Done-when checks each):

  | Gate | Asks | In a session that cannot ask |
  |---|---|---|
  | No arguments | Which brief and which question | Stop; nothing is built |
  | No brief (D5) | — | Stop; suggest `/kenspc-brief`; nothing is built |
  | Several `needs prototype` entries, none named (D18) | Which one | The first in document order, named in the final message |
  | The named entry is `answered` (D18) | Prototype it again? | Stop |
  | A location conflict (D20) | Where | The default location, named in the final message |
  | A UI prototype that can only render in the app, and CLAUDE.md names no location (D9) | Where in the app | Nothing is built; the entry stays unsettled with the reason |
  | A UI prototype in the app: a tracked file with uncommitted changes, or the project's manifest (D9) | Go on, commit first, or stop | Nothing is built; the entry stays unsettled with the reason |
  | A feature prototype that needs the app's runtime and cannot run outside it (M8) | — | Nothing is built, in either kind of session; the entry stays unsettled with the reason, and the exit says widening the exception is the user's decision |
  | A connection the development configuration does not name (D8) | May it be used | It is not used |
  | A new table or column on the development database (D8) | The warning and the throwaway recommendation; the user decides | The throwaway database, named in the final message |
  | The answer is the user's judgment (D10) | Look at the prototype and give a verdict | Unsettled; `Evidence:` says what to look at and how |
  | A commit fails (D7) | How to go on | Stop and report |

- Phase 2, Build and run. Goal: the prototype, run, its evidence gathered,
  committed. DONE when the add commit exists — `chore: add prototype <slug>`
  adapted to the project's commit conventions, its paths passed as a
  pathspec, staging only the prototype's own paths (ruling D7) — and the
  evidence either settles the question against `Settled by:` or shows why
  it cannot be settled here; for a UI prototype in the app, the project's
  typecheck is green against its baseline (ruling D9). Constraints:
  - Everything is written under the location, except, for a UI prototype in
    the app, the tracked files the frame named. The prototype's database
    file, build output, and installed dependencies stay under the location
    too (ruling M10).
  - File names follow the naming rule of the Scratch space bullet in the
    `canonical:run-dir` block of
    `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` — no name the
    project's test runner collects; a prototype that uses the runner as its
    harness runs it with a config of its own under the location. Why: the
    prototype is committed where the project's gates can walk, and a
    collectable name there is a test the user did not write (ruling M6).
  - None of the project's build, test, or lint commands is run on the
    prototype, and the project's configuration is not edited to exclude it;
    for a UI prototype in the app, only the typecheck runs, unmodified. Why:
    the prototype is not held to the project's gate, and a configuration
    change made for the plugin's own files is the user's decision.
  - Credentials by name only; the staged file list and diff are read for a
    file holding a value read from configuration before the add commit
    (ruling M9).
  - No migration file is added and none is applied, with any migration tool;
    a new table or column on the development database follows the warning
    gate, and when the user insists, a teardown script goes with the
    prototype (ruling D8). Rows written to existing development tables need
    no warning and no teardown; `Evidence:` names each such table.
  - The add commit comes after the run that produced the evidence
    (ruling D7).
- Phase 3, Record and discard. Goal: the answer in the brief and the
  prototype out of the tree. DONE when:
  - the entry is rewritten per the grammar in generate-brief's writing
    rules — `` `answered` `` with `Answer:`, `Evidence:`, and `Prototype:`,
    or, unsettled, `` `needs prototype` `` with `Evidence:` and `Prototype:`
    — and nothing else in the brief changed (Why: the rest of the brief is
    the user's discovery record);
  - at the judgment point (ruling D10) the user's verdict came first;
  - the teardown ran, when there was one, and the tables it created are
    gone;
  - the remove commit exists — `chore: remove prototype <slug>`, its body
    carrying `Question:`, `Answer:` or `Not settled:`, and
    `Prototype: <hash>` — made as ruling M7 defines: `git rm` for the paths
    the add commit added, their parent's content for the paths it modified,
    one commit, paths as a pathspec;
  - `git diff <add commit>^ HEAD -- <every path the add commit touched>`
    prints nothing;
  - the brief is not committed (ruling D7).
- When nothing was built (a gate ended in "nothing is built"): no commit is
  made; the entry stays `` `needs prototype` `` and gains `Evidence:` with
  the reason and no `Prototype:` (ruling D2).
- Exit: the final message gives the answer (or why it is unsettled), the
  add and remove commits, how to read the prototype (`git show <hash>`),
  every path under the location that
  `git status --porcelain --ignored -uall -- <location>` still lists,
  ignored and untracked alike, for the user to remove (ruling M10), and
  every default a session that cannot ask took. Next step:
  `/kenspc-plan <brief>` when no `` `needs prototype` `` entry remains,
  otherwise `/kenspc-prototype <brief> <n>` for the next; the skill invokes
  nothing and deletes nothing. Why: the same reason generate-brief does not
  trigger generate-plan — the user decides when to plan; and a recursive
  delete is what the user's permission rules deny, the run-directory
  block's reason for never deleting.
- Ending with the prototype still in the tree: when the run stops after the
  add commit and before the remove commit — a rejected commit, the user
  stopping at a gate — the last message names the add commit, says the
  prototype is still in the tree, and gives the `git rm` (and restore)
  command that would remove it; the skill does not run it unasked. Why:
  like diagnose-bug's "Ending without a document", the branch carries
  something the user did not plan to keep.
- Writing rules: the conversation's language; the brief entry in the
  brief's language with its anchors as written; commit messages and
  identifiers in English; no branch, pull-request, rebase, or tag step —
  the prototype's commits land on the current branch (C-5).
- Phase transitions rest on artifacts: Phase 1 → 2 on the shown frame;
  Phase 2 → 3 on the add commit's hash; the exit on the rewritten entry and
  the remove commit.
- Done when: the file exists with the frontmatter above and `version:
  3.0.0`; the description names the three blocks and carries English and
  Chinese triggers; the three phases carry Goal, Inputs, DONE when, and
  their Whys; every gate in the table has its cannot-ask branch in
  diagnose-bug's wording; the in-app exception names UI prototypes only,
  and the feature-prototype rule is present; the grammar is pointed at, not
  copied; the naming rule is pointed at by the `canonical:run-dir` marker
  names, not copied; the commit subjects and the remove-commit body are
  present; `bash scripts/check-no-model-names.sh` exits 0;
  `claude plugin validate --strict ./plugins/kenspc` passes; the
  pointer-label grep in Standing constraints prints nothing on the file.
- Why: the skill is the whole of C-3 to C-6; every later step points at it
  or documents it.

**Step 3.2: Add `commands/kenspc-prototype.md`**

- File: `plugins/kenspc/commands/kenspc-prototype.md` (new), the shape of
  the seven existing command files: `name: kenspc-prototype`; a one-line
  description ("Explicit entry point for the prototype skill — answer one
  open question from a brief with a throwaway prototype (原型)."),
  `argument-hint: <brief path> [entry number or question]`,
  `disable-model-invocation: true`; a body that reads
  `${CLAUDE_PLUGIN_ROOT}/skills/prototype/SKILL.md` and passes `$ARGUMENTS`
  through.
- Done when: the file matches `kenspc-diagnose.md` line for line except
  name, description, argument hint, and skill path;
  `claude plugin validate --strict ./plugins/kenspc` passes; the
  pointer-label grep prints nothing on the file.
- Why: commands are explicit entry points only; the skill's description owns
  the routing (v3.4.2).

### Phase 4: Hook and guard (C-7)

**Step 4.1: The reminder hook's brief message**

- File: `plugins/kenspc/hooks/scripts/remind-plan-skill.sh`, the
  `*/docs/briefs/*.md` branch only (ruling M5).
- Message, in substance: a brief is normally written by a kenspc skill —
  generate-brief (Skill tool or `/kenspc-brief`), which runs a structured
  discovery conversation; diagnose-bug (`/kenspc-diagnose`) when a diagnosed
  fix needs planning; or prototype (`/kenspc-prototype`), which records a
  prototype's answer in an existing brief's Open Questions. If one of them
  has already been invoked, ignore this message.
- The plan, task, and guide branches, the template exclusions, and the path
  normalization are unchanged.
- Done when: `printf '{"file_path":"/x/docs/briefs/a.md"}' | bash
  plugins/kenspc/hooks/scripts/remind-plan-skill.sh` prints the message
  naming all three skills; `/x/docs/briefs/_template.md` prints nothing;
  `/x/docs/tasks/a.md` prints the unchanged task message;
  `/x/prototypes/q/main.ts` prints nothing; the pointer-label grep prints
  nothing on the file.
- Why: C-7, as batch B's hook change anticipated.

**Step 4.2: The `needs prototype` group in `check-doc-sync-anchors.sh`**

- File: `scripts/check-doc-sync-anchors.sh` (ruling D13). Three entries in
  `ANCHOR_CHECKS`: `"needs prototype|plugins/kenspc/skills/generate-brief/SKILL.md"`,
  `"needs prototype|plugins/kenspc/skills/generate-plan/SKILL.md"`,
  `"needs prototype|plugins/kenspc/skills/prototype/SKILL.md"`. The header
  names the planning chain's anchors — the documentation path and the
  open-question path — four anchors across eleven files, with the new group
  listed; the drift message names the fourth anchor; the success line says
  "all four anchors". The self-test copies from the array, mutates
  `Doc-sync` in the task example as before, and its header's file count
  follows.
- Done when: `bash scripts/check-doc-sync-anchors.sh` and its `--self-test`
  exit 0; by hand, a copy of the repository tree with every
  `needs prototype` removed from `prototype/SKILL.md` makes the main check
  exit 1 naming that file, and the copy is discarded;
  `bash scripts/check-all.sh --self-test` prints `guards run: 10` and ends
  with `self-tests run: 9`.
- Why: three files must spell the status word the same for the chain to
  hold, and a rename in one of them fails silently.

### Phase 5: Documentation (C-8)

**Step 5.1: Repository CLAUDE.md**

- File: `CLAUDE.md` (repository root).
- Project Overview: the plugin also answers a brief's open questions with
  throwaway prototypes; the no-review sentence names the brief, diagnose-bug,
  and prototype skills, with the prototype's reason — it is discarded, and
  its answer is reviewed where a plan uses it.
- Plugin Directory Layout: `commands/kenspc-prototype.md` and
  `skills/prototype/SKILL.md` ("No review phase — the prototype is
  discarded; the plan that uses its answer is reviewed"); the hooks paragraph
  says the brief message names generate-brief, diagnose-bug, and prototype.
- SKILL.md Frontmatter Fields: "all seven skills", "syncing seven files",
  and "bump all seven" become eight.
- Subagent Review Architecture: "No review" gains the prototype skill, and a
  short "prototype path" paragraph: an Open Questions entry marked
  `needs prototype` → generate-plan's exit → `/kenspc-prototype` → the add
  commit, the answered entry, the remove commit → the plan cites the hash;
  the in-app exception covers UI prototypes that can only render in the app.
  The effort paragraph's "the six other skills" becomes seven.
- Repository scripts/: `check-doc-sync-anchors.sh`'s description gains the
  `needs prototype` group (generate-brief, generate-plan, prototype).
- Non-Goals: the prototype skill points at the Scratch space naming rule in
  the `canonical:run-dir` block and carries no copy; a move of that rule
  updates the pointer in the same commit.
- The Durable documents table is unchanged; a brief is not a durable
  document (ruling D11).
- Done when: every count and list agrees with the files, and the file reads
  top to bottom without a contradiction about skill, command, or anchor
  counts.
- Why: CLAUDE.md is the loaded contract for every session in this
  repository.

**Step 5.2: READMEs and manifests**

- `README.md` (root): a `prototype` row in the skills table ("Answers one
  open question from a brief with a throwaway prototype — committed, its
  answer and hash recorded in the brief, then removed — no review phase");
  `/kenspc-prototype` in the Commands line.
- `plugins/kenspc/README.md`: Skills row for `prototype`; the generate-brief
  row mentions Open Questions; the generate-plan row mentions the exit;
  Commands row (`/kenspc-prototype <brief path> [entry number or
  question]`) and `/kenspc:prototype` in the skill-invocation sentence;
  Recommended Workflow: `[/kenspc-prototype →]` between the brief and the
  plan in the diagram, and a "Prototype path" paragraph (the entry grammar
  in one sentence, generate-plan's question, the two commits, `git show`,
  the brief left uncommitted, the development-database rule — a warning
  before a new table or column, and existing tables written to named in
  the evidence); Known behavior, four items — **Prototypes live in
  history** (committed, then removed in the next commit; anything committed
  stays in history, so the skill reads credentials by name and commits
  none); **Gates between the two commits** (in that window a typecheck,
  linter, or root-level project file that walks the repository reaches the
  prototype, a pre-commit hook that runs one can reject the add commit and
  the skill stops, and HEAD after the run holds no prototype);
  **Leftovers after a prototype** (dependencies, build output, and other
  files git does not track — ignored or untracked — stay under the
  location and are named in the final message; the skill deletes nothing);
  **In-app UI prototypes** (only a UI prototype that can only render inside
  the app goes into the app; its location comes from CLAUDE.md or the user;
  typecheck green against its baseline; the remove commit restores the
  tracked files it changed; a feature prototype that needs the app's
  runtime and cannot run outside it is not built, and widening the
  exception is the user's decision).
- `plugins/kenspc/.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json`: descriptions per ruling M12; no version
  change.
- Done when: every sentence that counts skills or commands, or describes a
  brief's sections, agrees with the SKILL and command files;
  `bash scripts/check-json.sh` exits 0.
- Why: the README is the installed user's only description of what a
  prototype run commits, and of what it leaves.

**Step 5.3: CHANGELOG and roadmap**

- `plugins/kenspc/CHANGELOG.md`: a `## 3.8.0 — unreleased` entry above
  3.7.0. Added: Open Questions in briefs (the grammar, `Settled by:`); the
  prototype skill and `/kenspc-prototype` (the gates, the two commits, the
  write-back, the development-database rule, the in-app exception for UI
  prototypes, what is left on disk); generate-plan's exit; the guard group
  (counts unchanged). Changed: generate-brief's template, writing rules, and
  next-step suggestion; generate-plan's Phase 1 Step 1 (the exit, `open`
  entries in the gap-check, answered entries cited by hash) and its Open
  Questions element (the carried form); the hook's brief message. Known
  behavior: the gates between the two commits; leftovers; history keeps
  every prototype. The date is filled at release.
- `docs/roadmap.md` (ruling M11): item 7 gains one sentence — a prototype's
  files under `prototypes/` are in the same position between its add and
  remove commits, and a gate that walks the repository reaches them there.
  The heading, batch C's line under "Planned batches", and that emptied
  section are left to the release commit.
- Done when: the CHANGELOG entry and item 7's sentence are present; the
  roadmap's heading and its "Planned batches" section, batch C's line
  included, are unchanged.
- Why: the repository's convention for planned versus shipped work — an
  item leaves the roadmap when it ships, in the release commit.

**Step 5.4: Release checklist**

- File: `docs/release-checklist.md` (ruling D14).
- Row 1: "Lists all 8 kenspc slash commands".
- Row 3 addition: when the discussion leaves a question it cannot settle,
  the brief's `## Open Questions` lists it with `` `open` `` or
  `` `needs prototype` ``, each `needs prototype` entry with `Settled by:`;
  otherwise the section's body is `none`; the next-step suggestion names
  `/kenspc-prototype` when an entry needs one.
- Row 4 addition: on a brief with a `` `needs prototype` `` entry, the first
  question Phase 1 asks is prototype-first or carry, before any gap-check
  question; "prototype first" ends the run with the `/kenspc-prototype`
  line and no file; "carry" puts the entry in the draft's Open Questions
  with `From:`, `Not prototyped:`, and `Assumed in:`; an `open` entry the
  gap rounds do not settle appears there with `From:` and `Assumed in:`; in
  a session that cannot ask, no question is asked, `Not prototyped:` reads
  "the session could not ask", and every `open` entry is carried without a
  gap round; a brief with no `## Open Questions` section gets no such
  question.
- New row 10, `/kenspc-prototype <brief path>`; the end-to-end row becomes
  11, and "row-10 detail" and "Row 10 sub-criteria" follow. Pass criterion:
  the trace shows the frame, then the prototype written under
  `prototypes/<slug>/` (or the CLAUDE.md location), run, and committed alone
  (`chore: add prototype …`; `git show --name-only <hash>` lists only the
  prototype's paths, none matching the run-directory check's sub-check 1
  `find` patterns); the brief entry rewritten `` `answered` `` with
  `Answer:`, `Evidence:`, and `Prototype:` naming that commit; then
  `chore: remove prototype …` with `Question:`, `Answer:`, and
  `Prototype:` in its body; `git diff <HEAD before the run> HEAD` prints
  nothing; the brief is not committed; the final message lists every path
  `git status --porcelain --ignored -uall -- <location>` still shows; the
  exit suggests `/kenspc-plan <brief>` and invokes nothing; a question
  given with no brief ends with the `/kenspc-brief` suggestion and no
  commit; a development-database run that creates a table shows the
  warning before any code and leaves no such table after the run; a run
  that writes rows to an existing development table shows no warning and
  names that table in `Evidence:`; a connection named only by a production
  file is never used; an in-app UI run with a CLAUDE.md location shows the
  typecheck baseline before building and green before the add commit, and
  the remove commit restores every tracked file the add commit modified; a
  feature question that needs the app's runtime either runs from the
  location with no tracked app file in the add commit, or builds nothing
  and makes no commit, leaving the entry `` `needs prototype` `` with the
  reason; "直接把这个功能做出来" and "帮我跑一下这段代码" invoke no
  prototype skill.
- Pre-flight counts stay `guards run: 10` and `self-tests run: 9`.
- Done when: the row, the additions, the renumbering, and the counts are
  present.
- Why: the checklist is the only check that exercises the live chain; the
  fixed strings are what it greps for.

## Documentation impact

Determined from this repository's CLAUDE.md, § Durable documents.

- `CLAUDE.md` § Project Overview, § Plugin Directory Layout, § Skill
  Development Conventions (skill count, hooks paragraph), § Subagent Review
  Architecture (orchestration patterns, effort paragraph), § Repository
  scripts/, § Non-Goals — Step 5.1.
- `plugins/kenspc/README.md` § Skills, § Commands, § Recommended Workflow,
  § Known behavior — Step 5.2.
- `README.md` § Available Plugins (skills table, Commands line) — Step 5.2.
- `plugins/kenspc/CHANGELOG.md` — 3.8.0 entry — Step 5.3.
- `docs/roadmap.md` — item 7's sentence — Step 5.3. The heading, batch C's
  line under "Planned batches", and that emptied section change in the
  release commit, not in this batch (ruling M11).
- `docs/release-checklist.md` — row 1, rows 3–4 additions, new row 10, the
  end-to-end row renumbered — Step 5.4.
- `docs/dry-runs/README.md` — N/A for this document: the label convention is
  untouched.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this
  document: its plan is not made from a brief, so the carried-entry form has
  no place in it (ruling D4).
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: the task-document format is unchanged.

## Testing Strategy

- Mechanical: the release-checklist pre-flight block — the effort-override
  diff (unchanged), `claude plugin validate --strict .` and
  `./plugins/kenspc`, and `bash scripts/check-all.sh --self-test` with
  `guards run: 10` and `self-tests run: 9`.
- Guard falsifiability: `check-doc-sync-anchors.sh`'s self-test, and the
  by-hand removal in Step 4.2.
- Pointer labels: the grep in Standing constraints on every plugin file the
  batch writes or edits.
- Hook: the four `printf … | bash remind-plan-skill.sh` probes in Step 4.1.
- Live chain, headless, one process per run:
  `claude -p "<prompt>" --plugin-dir <repo>/plugins/kenspc
  --permission-mode bypassPermissions --output-format json`, in throwaway
  projects under `~/Projects/_smoke/batch-c-*`. A run that stops at a
  question is continued with `claude -p --resume <session_id> "<answer>"`,
  from the same directory and with the same other flags, the session id
  taken from the stopped run's JSON output; `--continue` picks up the most
  recent conversation in the directory, which is not reliable when one
  directory holds several runs. A session that cannot ask is produced with
  `--append-system-prompt "Work without stopping; do not ask clarifying
  questions."`, and the record names every run that used it. Whether the
  skill reads that as the signal it tests for is itself under test: a run
  that asks anyway is a finding.
- Seed: a TypeScript project with `typescript@7.0.2` and `vitest@5.0.1`,
  installed with `npm install --offline` from the local npm cache — the
  acceptance makes no call to the npm registry, a network service outside
  the batch's safety fence; the main session confirmed on 2026-09-25 that
  both install offline (exit 0) and that `eslint` is not in the cache
  (`ENOTCACHED`). So the seed has no linter, and every lint case — a
  prototype reached by `eslint .` between its two commits — is recorded as
  Not exercised, with that reason. The seed has tests of its own; a
  `tsconfig.json` whose include reaches the repository root (`**/*`); a
  `typecheck` script (`tsc --noEmit`); `.gitignore` without `prototypes/`;
  `.env.development` naming a local SQLite file inside the project
  (`DATABASE_PATH=./dev.db`, read with Node's built-in `node:sqlite`) and
  `.env.production` naming an unresolvable host
  (`postgres://prod.example.invalid/app`); a hand-written brief with one
  `open` and two `needs prototype` entries, and a copy with no
  `## Open Questions` section. The acceptance database is only ever a file
  inside the throwaway project.
- Cases:
  1. `/kenspc-brief` on an idea with a question discussion cannot settle —
     the brief carries `## Open Questions` per row 3.
  2. `/kenspc-plan <brief>` — the exit asked first; "carry" → the carried
     form in the draft, and the `open` entry brought into the gap rounds;
     "prototype first" → the `/kenspc-prototype` lines, no file; cannot-ask
     → the `needs prototype` entries carried with "the session could not
     ask" and the `open` entry carried with `From:` and `Assumed in:`, no
     question asked; the brief without the section → no exit question.
  3. `/kenspc-prototype <brief> 1`, a logic question settled by a
     measurement (for instance, whether `node:sqlite` inserts 50,000 rows
     into a local file within a stated time in one transaction, against a
     control without the transaction) — row 10's commit, write-back, and
     `git diff` criteria; after the run, `npm test` and `npm run typecheck`
     pass from the root. Run once interactive with the entry named, and once
     cannot-ask as `/kenspc-prototype <brief>` with no entry named: the
     brief has two `needs prototype` entries, so the run takes the first in
     document order and the final message says so (ruling D18).
  4. Development database: a question that needs a new table — the warning
     and the throwaway recommendation before any code; the driver insists
     on the development database → `Evidence:` records it, and
     `sqlite3 dev.db .tables` is the same before and after the run;
     cannot-ask → a throwaway file under the location, and `dev.db`'s
     sha256 is unchanged. A question answered by writing rows into an
     existing development table → no warning, and `Evidence:` names the
     table. No run uses the `.env.production` host (trace).
  5. In-app UI: a seed variant whose app registers pages in `src/routes.ts`
     and whose CLAUDE.md names the in-app prototype location; a judgment
     question about how a page reads — the typecheck baseline, the add
     commit modifying `src/routes.ts`, the wait for a verdict (the driver's
     verdict quoted), the remove commit restoring `src/routes.ts`
     (`git diff <before> HEAD -- src/` empty). Cannot-ask with no CLAUDE.md
     location → nothing built, no commit, the entry unsettled with the
     reason. An uncommitted edit to `src/routes.ts` → the question;
     cannot-ask → nothing built.
  6. Feature slice: a question whose answer needs the app's request
     pipeline — either the prototype runs from the location, importing the
     app's modules, and the add commit touches no tracked app file; or
     nothing is built, no commit is made, the entry stays
     `` `needs prototype` `` with the reason in `Evidence:`, and the exit
     says widening the exception is the user's decision. The record says
     which.
  7. A question with no brief → the `/kenspc-brief` suggestion, no commit.
  8. Routing: "直接把导出 CSV 的功能做出来" and "帮我跑一下这段代码看看输出"
     invoke no prototype skill.
- Independence: the acceptance record separates what the plugin's own runs
  produced — commits, briefs, plans, trace — from what the driver typed at
  the skills' questions; every answer the driver gave is quoted where it was
  given (the plan exit's choice, the gap-round answers, the database
  insistence, the in-app verdict, question selection).
- Acceptance runs in a separate session and is filed under `docs/dry-runs/`
  (the batch A and B precedent), with the labels PASS / FAIL / OBSERVATION /
  Not exercised. The acceptance session records the evidence and a first
  reading for each FAIL and does not classify it. The main session
  classifies — plugin defect, behavior slip, or observation, as the batch B
  record's § 4 does — and fixes a plugin defect in a separate session,
  never in a run's project; the affected case is then re-run.
- Dogfood note: `/kenspc-task` on this spec generates the Doc-sync task from
  the Documentation impact above. For the documents Steps 5.1–5.4 edit, the
  generated entries say "edited by Task <K>: verify it against the
  implementation instead of editing it again", as the template provides.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| The skill triggers on "build this feature" or "run this snippet" and commits code nobody asked for | Medium | The three blocks in the description and the Trigger Phrases list (D12); routing case 8 in acceptance, where a misroute is a finding for the main session to classify. |
| A pre-commit hook that runs lint, typecheck, or tests rejects the add commit | Medium, per project | The run stops and asks, with no `--no-verify` (D7); README Known behavior names it. |
| A gate the user runs between the two commits trips on the prototype | Low (the window is one commit, D6) | Known behavior; roadmap item 7's sentence. |
| A secret lands in history through a prototype | Low | Credentials by name only; the staged diff read before the add commit (M9); README says history keeps every prototype. |
| A production database is used because its connection sits in an unsuffixed `.env` | Low | Development by name only; anything else asked, or not used when the session cannot ask (D8). |
| Rows a prototype writes into existing development tables are left behind | Medium | By ruling D8 no warning or teardown; `Evidence:` names every such table, so the user knows which development data changed. |
| An in-app discard does not restore a modified file exactly | Low | The end-state rule (M7) and the `git diff <add commit>^ HEAD` check in Phase 3's DONE and row 10. |
| A feature question that needs the app ends unsettled, and the user expected an answer | Medium | The exit names the reason and that widening the in-app exception is the user's decision (M8); the entry stays `needs prototype`, so generate-plan asks again or carries it with `Assumed in:`. |
| The agent answers a judgment question itself | Medium | D10's unsettled form in a session that cannot ask; case 5 checks the wait for a verdict. |
| A plan carries an entry and later work treats its assumption as fact | Medium | `Assumed in:` names the steps (D4); the entry stays findable by its marker. |
| The appended system prompt is not read as the cannot-ask signal, so cannot-ask branches go untested | Medium | The record marks every cannot-ask run; a run that asks anyway is a finding for the main session to classify. |
| Leftovers under the location break a root-level `.csproj` build after the run | Low | The exit lists them, ignored and untracked (M10); README Known behavior. |
| No lint case is exercised in acceptance | Certain | `eslint` is not in the local npm cache; the record states it as Not exercised with the reason; Known behavior and roadmap item 7 cover the lint exposure. |
| A prototype file named `SETUP.md` or `*-GUIDE.md` draws the guide reminder | Low | Harmless reminder text; the naming rule keeps such names rare. |
| The pointer to the `canonical:run-dir` naming rule drifts | Low | CLAUDE.md Non-Goals records the pointer; `check-run-contract.sh` keeps the block identical in its two copies. |

## Clarifications during implementation

Settled between the implementing session and the spec author (the main
session); each entry binds like the rulings above. Questions from the
implementing session arrive under a `## Questions for the spec author`
section appended to the end of this document (see Open Questions); each
answer is recorded here as `CL<n>` — a statement and the Step it affects —
and the answered question is removed from that section. The prefix is `CL`,
not `C`, so a clarification cannot be read as one of the locked points C-1
to C-8.

None yet.

## Open Questions

None. The rulings in [Design decisions](#design-decisions) close every
question raised during design. If the implementing session finds one of them
contradicted by the code, it stops and reports it as a plan-level issue
rather than resolving it locally: it appends the question under a
`## Questions for the spec author` section at the end of this document,
commits nothing else, and waits; the spec author answers under
[Clarifications during implementation](#clarifications-during-implementation)
and the session continues from the updated document.

## Questions for the spec author

Raised by the implementing session after the `/kenspc-task-implement` run
over `docs/tasks/batch-c-prototypes-tasks.md` (implementation 2f52600..9f70db6,
review fixes up to 48e65d1). No task was BLOCKED; each question below comes
from a review finding that code-fixer deferred because fixing it would read
a ruling one way or add scope the rulings do not give. The finding IDs point
into the run directory
`.kenspc/runs/20260925-225154-batch-c-prototypes-tasks/` (`angle-<n>.md`,
`schema-b.md`).

1. **The leftovers list and `node_modules` (M10; E7, B8).** M10 has the exit
   name every path `git status --porcelain --ignored -uall -- <location>`
   still lists. With `-uall`, an ignored `node_modules/` under the location
   is listed file by file, so after an `npm install` the final message runs
   to thousands of lines. May the exit name a directory whose every file is
   listed once, with its file count (for example `prototypes/q/node_modules/
   (2,314 files)`), reading "every path" as "covers every path"? If yes, the
   skill's Exit, the README's Leftovers item, the CHANGELOG's leftovers
   bullet, and release-checklist row 10 change together in one commit.
   Steps 3.1, 5.2, 5.3, 5.4.

2. **The leftovers command's `-c core.quotePath=false` (M10; Q2).** A review
   fix (2a9a5f2) made the skill's command
   `git -c core.quotePath=false status --porcelain --ignored -uall -- <location>`
   so a non-ASCII path is listed unescaped, matching the Phase 1 status
   command. Step 3.1, the CHANGELOG, and release-checklist row 10 quote the
   form without the flag. Is the flag accepted — and if so, do the CHANGELOG
   and row 10 follow it? Steps 3.1, 5.3, 5.4.

3. **A status word that is none of the three (D1, D2; E9).** D2 has
   generate-plan read only the status word. An entry whose word was
   hand-edited or translated (for example `` `需要原型` ``) is then neither
   stopped on nor gap-checked nor carried, and the question leaves the plan
   without a trace. Options: (a) the gap rounds name such an entry as
   unreadable and ask which status it has; a session that cannot ask carries
   it as `open`, with `Assumed in:` and a note that its status word was not
   recognized; (b) no rule — the reading side stays as written. Step 2.1.

4. **The `Settled by:` question in `rapid-direct` mode (Step 1.1; B10).**
   Step 1.1 gives the Phase 1 Constraints bullet one no-ask branch, for
   `rapid-inferred (reminder-driven)`. generate-brief's `rapid-direct` mode
   asks its one or two rounds regardless of a reminder, so a clearly stated
   idea run under a work-without-stopping reminder asks what would settle a
   `needs prototype` question and waits. Should the bullet gain the standard
   cannot-ask clause (infer the result and tag it), whatever the mode?
   Step 1.1.

5. **A cited hash after a rebase or squash merge (C-5; E8).** A
   `git pull --rebase` over unpushed commits, a branch rebase, or a squash
   merge takes the add commit off every branch; the hash in the brief and
   the plan then resolves only in the clone that made it, until gc. The
   skill takes no branch, rebase, or tag step, so the only remedy is a
   caveat. Should one be added — one sentence in the README's "Prototypes
   live in history" item and in the CHANGELOG's Known behavior, and
   optionally in the skill's overview? Steps 3.1, 5.2, 5.3.

6. **Release smoke scope beyond Step 5.4 (T2–T7).** The Testing Strategy
   puts these cases in the one-time acceptance; the review asked for them in
   the release checklist, where each costs a headless run every release.
   Which, if any, join the smoke rows?
   - Row 10: a run in a session that cannot ask — no entry named on a brief
     with two `needs prototype` entries takes the first and names it; a
     table-creating run uses a throwaway database and leaves the development
     database file unchanged (T2).
   - Row 10: the judgment point — the run waits after the add commit and
     says how to see the prototype; a session that cannot ask leaves the
     entry `needs prototype` with `Evidence:` naming what to look at, and
     the remove commit's body carries `Not settled:` (T3).
   - Row 10: a failed commit, with a seed project whose pre-commit hook
     exits 1 — no retry and no `--no-verify`, no add commit, the staged
     paths and `git reset -q --` named; a rejected remove commit names the
     add commit and says the removal is staged (T4).
   - Row 10: a question given as text for a brief with no section — the
     section created after `## Context`, the entry `needs prototype` with
     `Settled by:`, and nothing else in the brief changed (T6).
   - Row 3: a Chinese run whose heading, status words, and labels stay in
     English; row 4 then run on that brief asks the exit question (T5).
   - Row 4: a brief with an `answered` entry — the plan cites its short
     hash where it relies on it — and a brief whose section body is `none`
     gets no exit question (T7).
   Step 5.4.

7. **Guarding the copied Prototype line (D13; T8).** The Prototype line is
   written in generate-brief's writing rules and copied byte-identically
   into the prototype skill; CLAUDE.md § Non-Goals records that no guard
   checks the copy. D13 adds one group, `needs prototype`, to
   `check-doc-sync-anchors.sh`. Should two more `ANCHOR_CHECKS` entries
   carry the full line as their label (generate-brief and prototype), with
   the guard's header, CLAUDE.md's guard description, and the Non-Goals
   sentence updated in the same commit? The guard counts stay 10 / 9.
   Steps 4.2, 5.1.
