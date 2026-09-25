# Batch C — Open Questions in Briefs, the generate-plan Exit, the prototype Skill and /kenspc-prototype — Task Document

## Context

Three connected changes along the planning chain, then their hook, guard,
and documentation. First, a brief gains a `## Open Questions` section whose
numbered entries each start with a status word — `` `open` ``,
`` `needs prototype` ``, or `` `answered` `` — and a `needs prototype` entry
names the result that would settle it (`Settled by:`). Second, generate-plan
stops on an unresolved `needs prototype` entry in a brief and asks whether
to prototype first or carry the question into the plan's Open Questions
element; a session that cannot ask carries it and says so. Third, a
`prototype` skill and its `/kenspc-prototype` command answer one such
question with a throwaway prototype: the skill frames the question, builds
the smallest thing that settles it, commits it
(`chore: add prototype <slug>`), writes the answer, the evidence, and the
commit hash into the brief, and removes the prototype in the next commit
(`chore: remove prototype <slug>`).

Related plan: `docs/plans/batch-c-prototypes.md`. The plan is the complete
specification. Its locked design (C-1 to C-8) and its Design decisions
(M1–M13, D1–D20) are binding rulings; three rulings depart from the draft's
lean — M8 (the in-app exception stays UI-only), M11 (the roadmap's heading
and "Planned batches" section are left to the release commit), and D8 in
part (row writes to existing development tables get no warning and no
teardown, only a mention in `Evidence:`) — and every task follows the
ruling, not the lean. Its Clarifications during implementation hold none
yet.

The labels this document cites (C-n, M-n, D-n, "ruling") are pointers into
the plan for the implementer. None of them is copied into a skill, command,
or hook file (plan § Standing constraints; the pointer-label grep below).

Each task below cites its plan Step, which is the canonical source for what
to write. The criteria listed here are the local DONE bar.

Fixed forms. Every task that states one of these uses it exactly as written
here (plan § Fixed strings):

- Section heading: `## Open Questions`.
- Status words: `` `open` ``, `` `needs prototype` ``, `` `answered` `` — in
  backticks, first on the entry's line, followed by ` — ` and the question.
  Plans carry `open` and `needs prototype` only.
- Entry labels: `Settled by:`, `Answer:`, `Evidence:`, `Prototype:` as
  sub-bullets, in that order.
- Prototype line:
  ``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` ``.
- Carried-entry labels: `From:`, `Not prototyped:` (on `needs prototype`
  entries only), `Assumed in:`.
- Empty section: the body `none`.
- Default location: `prototypes/<slug>/` at the repository root.
- Commit subjects written by the skill: `chore: add prototype <slug>`;
  `chore: remove prototype <slug>` (both adapted to the project's commit
  conventions).
- Remove-commit body: `Question:`, `Answer:` or `Not settled:`,
  `Prototype: <hash>`.
- Command and skill: `/kenspc-prototype`, skill `prototype`,
  `/kenspc:prototype`.
- Cannot-ask wording: "In a session that cannot ask (a system reminder to
  work without stopping), …", as `diagnose-bug/SKILL.md` words it.
- Doc-sync heading: `### Task N: Doc-sync` (N the last task number).
- Dependency line: `Depends on: Task 1-<N-1>` (ASCII hyphen); `Depends on:
  Task 1` for a single prior task.

Pointer-label grep (plan § Standing constraints). For every plugin file a
task writes or edits — `generate-brief/SKILL.md`, `generate-plan/SKILL.md`,
`prototype/SKILL.md`, `commands/kenspc-prototype.md`, and
`remind-plan-skill.sh` — this command prints nothing:

```bash
grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\b[BC]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>
```

It prints nothing on those existing files today and 112 lines on the batch B
spec (`git show 4c3bf34^:docs/plans/batch-b-diagnose-bug.md`), so it can
fail.

This is plugin revision work. The files are Markdown (SKILL.md, command
.md, README, CLAUDE.md, CHANGELOG, docs), one hook script, one guard script,
and two JSON manifests. The repository has no test framework: "build / test
/ lint" for each task is the guard suite. After each task, run the guard the
task names, then `bash scripts/check-all.sh`, which must exit 0 with
`guards run: 10`. Tasks that touch the plugin's skills, commands, or
manifests also run `claude plugin validate --strict ./plugins/kenspc` (and
`claude plugin validate --strict .` for the marketplace manifest).

Constraints that apply to every task (plan § Standing constraints):

- No edit inside any byte-identity section, with no exception in this batch:
  the `canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`, and
  `canonical:verdict-shared` blocks; the code-craft canonical paragraphs
  with the `CODE-CRAFT PRINCIPLES` header and its guard comment; the worked
  Schema B example; and the five reviewers' six shared sections.
- Zero diff in `plugins/kenspc/skills/task-implement/SKILL.md`,
  `plugins/kenspc/agents/task-implementer.md`,
  `plugins/kenspc/skills/generate-task/SKILL.md`,
  `plugins/kenspc/skills/task-review/SKILL.md`,
  `plugins/kenspc/skills/diagnose-bug/SKILL.md`,
  `plugins/kenspc/agents/plan-document-reviewer.md`,
  `plugins/kenspc/agents/task-document-reviewer.md`, and
  `plugins/kenspc/shared/discovery-framework.md`. The files this batch
  touches are generate-brief, generate-plan, the new skill and command, the
  hook, the guard, the two manifests' description strings (plan Step 5.2),
  and the documents in the plan's Documentation impact.
- No new agent and no new CONTEXT key. No brief example under `references/`.
- `effort:` frontmatter is unchanged in every file; the new skill has none.
  Every skill keeps `version: 3.0.0`, the new one included.
- No version bump: `version` in `plugins/kenspc/.claude-plugin/plugin.json`
  stays `3.7.0`, and the "last reviewed" date in its description is left as
  it is (both change in the release commit). The CHANGELOG entry goes under
  `## 3.8.0 — unreleased`. No tag, no push.
- Rules are rationale-anchored ("Why: …" prose), with no `MUST` / `NEVER` /
  `CRITICAL`, no effort or reasoning tokens, and no model names
  (`check-no-model-names.sh` scans `skills/`, `agents/`, `commands/`, and
  `shared/`). A check written into a skill is in rubric form: what passing
  looks like, then the named ways it fails.
- Every question point this batch adds has a cannot-ask branch in the
  Fixed-forms wording.
- Code, comments, commit messages, and documents are in English.
- Nothing under `.kenspc/` is deleted. No task runs `rm -r` or `rm -rf`: a
  scratch copy made by hand (Task 6's falsifiability check) goes under
  `~/Projects/_smoke/`, and is discarded by moving it to
  `~/Projects/_smoke/.trash/<name>-<YYYYMMDD-HHMMSS>/` (created when
  missing).
- Every guard self-test run — `bash scripts/check-all.sh --self-test` or a
  single guard's `--self-test` — is preceded by
  `mkdir -p ~/Projects/_smoke/tmp` and prefixed with
  `TMPDIR=$HOME/Projects/_smoke/tmp`, so the fixtures' `mktemp -d`
  directories land under `~/Projects/_smoke/`. Main mode (no
  `--self-test`) needs neither.
- No task edits `docs/plans/batch-c-prototypes.md`. A task that finds a
  ruling contradicted by the code is marked BLOCKED with the contradiction
  named. After the run ends and Schema G is out, the orchestrating session
  (the one that ran `/kenspc-task-implement`) appends each such
  contradiction under a `## Questions for the spec author` section at the
  end of the plan (creating the section when missing), commits nothing
  else, and stops; the spec author records the answer as `CL<n>` under the
  plan's `## Clarifications during implementation`.
- Each task is one conventional commit that stages only the files the task
  lists, together with the task's status update:
  - `feat(skills): …` for Tasks 1–3, `feat(commands): …` for Task 4,
    `fix(hooks): …` for Task 5;
  - `feat(scripts): …` for Task 6;
  - `docs(claude-md): …` for Task 7, `docs: …` for Task 8,
    `docs(changelog): …` for Task 9 (it also edits the roadmap),
    `docs(release): …` for Task 10;
  - `docs: …` for the Doc-sync task.

Dependency note: Task 1 (plan Phase 1) writes the Open Questions grammar
that Tasks 2 and 3 point at, so both depend on it; Tasks 2 and 3 (plan
Phases 2 and 3) are independent of each other. Task 4 adds the command for
the skill Task 3 writes. Task 5's message names the skill and the command
(`Depends on: Task 3-4`). Task 6 guards the `needs prototype` anchor in the
three files Tasks 1–3 write (`Depends on: Task 1-3`). Tasks 7 and 9
document the finished skills, hook, and guard (`Depends on: Task 1-6`);
Tasks 8 and 10 document the skills and the command only — neither the
READMEs nor the release checklist describe the hook message or the anchor
guard, and the guard counts do not change (`Depends on: Task 1-4`).
Task 11, the Doc-sync task, runs last and needs Tasks 1–10. It reconciles
the documents with what those tasks implemented and promotes their recorded
decisions.

## Tasks

### Task 1: Add Open Questions to generate-brief

**Status:** DONE

**Implementation notes:**
- Decisions: wrote `/kenspc-prototype <path> <n>` with angle brackets, as
  the task and acceptance criteria spell it, beside the section's existing
  `/kenspc-plan [path]`, and defined both placeholders in the sentence
  rather than changing the existing `[path]` form (a surgical edit). Added a
  short Why to the Phase 1 Constraints bullet and to the `needs prototype` /
  `open` rule, which the task lists without one, to keep every rule
  rationale-anchored; the anchors rule also restates the entry shape
  (status word in backticks, ` — `, then the question; labels as
  sub-bullets in order) so the grammar other skills point at is complete in
  the writing rules, not only in the template placeholder.
- Changes/tradeoffs: the Phase 2 DONE-when bullet now names the
  `/kenspc-prototype` lines before `/kenspc-plan` and points at the
  Next-step suggestion section, so the two agree. Verified: pointer-label
  grep and `MUST|NEVER|CRITICAL` grep print nothing (positive control: 112
  lines on the batch B spec); `needs prototype` count 10; the Prototype line
  matches the Fixed form byte for byte; diff hunks stay outside the
  frontmatter, Trigger Phrases, Discovery Mode Detection, output path
  resolution, and conflict check; `check-no-model-names.sh`,
  `check-all.sh` (`guards run: 10`), and `claude plugin validate --strict
  ./plugins/kenspc` exit 0.

Plan Step 1.1 (C-1; rulings D1, D2, D15, D16, M3, M13). In
`plugins/kenspc/skills/generate-brief/SKILL.md` — the frontmatter, Trigger
Phrases, Discovery Mode Detection, output path resolution, and conflict
check stay as they are:

- Brief template: a `## Open Questions` section after `## Context` and
  before `## Discovery Notes` (Discovery Notes stays last, with its
  `Discovery Mode:` field), holding the placeholder the plan gives in
  substance — numbered entries, `none` when nothing is open, the
  `` `open` `` form (a question neither discussion nor a small experiment
  settles) and the `` `needs prototype` `` form (a question a small
  experiment settles faster or more reliably than more discussion) with its
  `Settled by:` sub-bullet (the result that answers it).
- The template's lead-in ("Skip sections that genuinely don't apply …")
  excludes Open Questions, which is always present.
- Writing rules for the brief, added:
  - Open Questions is always present; its body is `none` when nothing is
    open. Why: a reader — and generate-plan — can then tell "nothing open"
    from "not considered".
  - The three status words and the four labels stay exactly as written, in
    English, whatever the brief's language. Why: generate-plan finds an
    unresolved entry by its status word, and the prototype skill rewrites
    that word when it settles the question; a translated word breaks the
    chain without an error.
  - `needs prototype` only for a question an experiment settles; a decision
    that belongs to a person is `open`.
  - Every `needs prototype` entry has `Settled by:`, naming a result, not
    the steps to build the prototype. Why: the prototype's evidence is
    measured against it, and written before the prototype runs it cannot be
    bent to fit the result.
  - generate-brief writes only `open` and `needs prototype`. The answered
    form the `/kenspc-prototype` skill writes — the question and
    `Settled by:` kept, then `Answer:`, `Evidence:` (what was run, what it
    showed, and the case that could have shown the opposite), and the
    Prototype line exactly as the Fixed forms give it — is shown as a
    Markdown block. An attempt that did not settle the question keeps
    `` `needs prototype` `` and adds `Evidence:` — with `Prototype:` when a
    prototype was committed — and no `Answer:`.
- Phase 1 Constraints, one bullet: a question the conversation cannot
  settle is noted for Open Questions and not argued further; one an
  experiment would settle is marked `needs prototype`, with what would
  settle it asked of the user — or, in `rapid-inferred (reminder-driven)`
  mode, inferred and tagged as that mode tags every inferred field.
- Next-step suggestion: when the brief has a `needs prototype` entry, the
  suggestion names `/kenspc-prototype <path> <n>` for each such entry first
  and says `/kenspc-plan` will ask about them otherwise. The constraint
  keeps generate-plan un-triggered and adds that the skill does not invoke
  the prototype skill either. Phase 2's DONE-when bullet on the next-step
  suggestion agrees with this section.

**Files to modify:**
- `plugins/kenspc/skills/generate-brief/SKILL.md`

**Acceptance criteria:**
- Inside the template's code block, `## Open Questions` appears after
  `## Context` and before `## Discovery Notes`, with the `open` and
  `needs prototype` entry forms, the `Settled by:` sub-bullet, and `none`
  for an empty section.
- The writing rules carry the always-present rule, the anchors-as-written
  rule naming the three status words and the four labels, the
  `needs prototype` / `open` distinction, the `Settled by:` rule, the
  answered form with the Prototype line byte-identical to the Fixed forms,
  and the unsettled form — each rule with a Why where the list above gives
  one.
- The Phase 1 Constraints bullet and the next-step suggestion (with
  `/kenspc-prototype <path> <n>` and the no-auto-trigger constraint covering
  both skills) are present, and no sentence in the file tells the writer to
  skip Open Questions.
- `git diff` of the file shows the frontmatter, Trigger Phrases, Discovery
  Mode Detection, output path resolution, and conflict check unchanged.
- `grep -c 'needs prototype' plugins/kenspc/skills/generate-brief/SKILL.md`
  prints a number of at least 1.
- The pointer-label grep and
  `grep -nwE 'MUST|NEVER|CRITICAL' plugins/kenspc/skills/generate-brief/SKILL.md`
  print nothing.
- `bash scripts/check-no-model-names.sh`, `bash scripts/check-all.sh`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 2: Add the Open Questions exit to generate-plan

**Status:** DONE

**Implementation notes:**
- Decisions: kept the existing gap-check bullets verbatim, re-indented as
  sub-bullets of part 2, so the five-dimension gap-check and its
  one-to-two-round limit read unchanged; the `open`-entry rule sits in the
  part's lead-in and its cannot-ask branch after the bullets, so the branch
  covers both the gaps-exist and no-gaps paths. The writing-rules Why for
  the carried entry's anchors names what reads them (a later
  `/kenspc-prototype` run finds the entry by its status word; `From:` names
  the brief it writes to), since the task gave the rule without a Why.
- Changes/tradeoffs: the carried-form Why is written as a plain `Why:`
  after the Markdown block rather than "Why `Assumed in:`:". Verified: the
  joined-line cannot-ask count is 2 (0 on HEAD before the edit, so the
  check can fail); pointer-label and `MUST|NEVER|CRITICAL` greps print
  nothing; `needs prototype` count 4; diff hunks are only the brief branch,
  the Open Questions element, and the writing rules (`effort: xhigh`,
  Phase 2 Step 3, and Phase 3 untouched); `check-no-model-names.sh`,
  `check-all.sh` (`guards run: 10`), and `claude plugin validate --strict
  ./plugins/kenspc` exit 0.

Depends on: Task 1

Plan Step 2.1 (C-2; rulings D3, D4, D11, M2, M3, M4). In
`plugins/kenspc/skills/generate-plan/SKILL.md` — `effort: xhigh`, the
brief-detection rule, the five-dimension gap-check itself, Phase 2 Step 3's
approval gate, and Phase 3 stay as they are:

- Phase 1 Step 1, "If it is a brief", becomes three parts in this order:
  1. **Open questions to prototype.** Read the brief's `## Open Questions`,
     pointing at the grammar in
     `${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md` (Writing rules
     for the brief) rather than restating it. When an entry's status is
     `` `needs prototype` ``, stop before any gap-check question and ask one
     question listing each such entry: prototype it first, or carry it into
     the plan. An entry the user sends to prototyping ends the run with one
     line per entry, `/kenspc-prototype <brief path> <n>`; the skill invokes
     nothing and writes no file. Carried entries go into the plan's Open
     Questions element in the carried form. In a session that cannot ask (a
     system reminder to work without stopping), every such entry is carried
     with `Not prototyped: the session could not ask`. Why: a prototype
     changes the brief the gap-check reads, and a plan built on a question
     an experiment could settle builds on a guess unless it says so. A brief
     with no `## Open Questions` section, or with the body `none`, has
     nothing to stop on.
  2. **Gap-check**, as today, plus the brief's `` `open` `` entries: each is
     a gap for the same one-to-two rounds; one the rounds do not settle is
     carried in the carried form without `Not prototyped:`. In a session
     that cannot ask (a system reminder to work without stopping), no
     `open` entry enters the gap rounds: each is carried straight in, in
     the same form (`From:` and `Assumed in:`, no `Not prototyped:`). Why:
     an `open` entry is an explicit gap the brief recorded, and a plan that
     drops it loses the question without a trace.
  3. **Answered entries** are settled input; a plan that relies on one
     cites its prototype hash where it does. Why: the brief is a discovery
     artifact and may be deleted; the hash in the plan keeps the evidence
     reachable.
- Phase 2 Step 1, the Open Questions element: an entry carried from a brief
  takes the carried form the plan gives — a `` `needs prototype` `` entry
  with `From: <brief path>, entry <n>`,
  `Not prototyped: <the user chose to carry it | the session could not ask>`,
  and `Assumed in: <the steps that assume an answer, and what they assume>`;
  an `` `open` `` entry with `From:` and `Assumed in:` only — shown as a
  Markdown block, with the Why: carrying a question is safe only when the
  plan says which of its steps rest on an assumed answer.
- Writing rules for the plan: a carried entry's status word and labels stay
  as written in a plan in another language, as the `## Documentation impact`
  heading does.

**Files to modify:**
- `plugins/kenspc/skills/generate-plan/SKILL.md`

**Acceptance criteria:**
- Phase 1 Step 1's brief branch has the three parts in the order above; the
  exit question comes before any gap-check question; the stop-and-suggest
  line `/kenspc-prototype <brief path> <n>` is present, with "invokes
  nothing and writes no file".
- `tr '\n' ' ' < plugins/kenspc/skills/generate-plan/SKILL.md | tr -s ' ' | grep -o 'In a session that cannot ask (a system reminder to work without stopping)' | wc -l`
  prints at least 2 (the exit and the `open` entries; the line breaks are
  joined first because wrapped prose splits the phrase), and the exit's
  branch carries `Not prototyped: the session could not ask`.
- The no-section / `none` case, the answered-entries rule, the carried form
  for both statuses with its Why, and the language rule are present.
- `git diff` of the file touches only Phase 1 Step 1's brief branch, the
  Open Questions element in Phase 2 Step 1, and the writing rules for the
  plan; the `effort: xhigh` line, Phase 2 Step 3, and Phase 3 are unchanged.
- `grep -c 'needs prototype' plugins/kenspc/skills/generate-plan/SKILL.md`
  prints a number of at least 1.
- The pointer-label grep and
  `grep -nwE 'MUST|NEVER|CRITICAL' plugins/kenspc/skills/generate-plan/SKILL.md`
  print nothing.
- `bash scripts/check-no-model-names.sh`, `bash scripts/check-all.sh`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 3: Write the prototype skill

**Status:** DONE

**Implementation notes:**
- Decisions: each gate that asks states its cannot-ask branch in prose with
  the full "In a session that cannot ask (a system reminder to work without
  stopping)" phrase (11 occurrences once line breaks are joined), and the
  gate table repeats the outcomes as a summary, because a table cell cannot
  carry the phrase as a sentence opening. The entry grammar and the
  run-dir naming rule are pointed at by path and markers; the only piece of
  the grammar written into the skill is the Prototype line, which the
  acceptance criteria require byte-identical. The discard's restore step is
  spelled `git checkout <add commit>^ -- <path>` (stages and writes the
  parent's content in one command, available in every git version) rather
  than `git restore --source`.
- Changes/tradeoffs: elaborations beyond the task text, each closing a case
  the task leaves undefined: (1) Arguments say how BRIEF is told from
  question text (first token looks like a path: starts with `./` or `/`,
  or ends with `.md`, as diagnose-bug decides), and a path that names no
  file or a file that is not a brief takes the no-brief stop; (2) a brief
  with no `needs prototype` entry and no ENTRY asks for the question, as
  with no arguments, with its own cannot-ask stop; (3) a question appended
  to a brief replaces a body of `none` and a missing section is created
  after `## Context`, where the template places it; (4) Phase 1 carries a
  one-line Constraints (it writes nothing but that appended entry); (5) the
  staged-diff read is written in rubric form (passing, then the named
  failures: a `.env`, a copied `appsettings.*.json`, an inlined connection
  string or key); (6) the still-in-the-tree ending names concrete commands
  (`git rm -- <paths added>`, `git checkout <add commit>^ -- <paths
  modified>`). Several Whys the task does not give were added so every rule
  is rationale-anchored. Verified: pointer-label and `MUST|NEVER|CRITICAL`
  greps print nothing; `__tests__|__mocks__|check-ignore` count 0 (4 on
  `task-review/SKILL.md`, so the grep can hit); `needs prototype` count 9;
  the Prototype line matches byte for byte; `check-no-model-names.sh`,
  `check-all.sh` (`guards run: 10`), and `claude plugin validate --strict
  ./plugins/kenspc` exit 0 — and the validator, run on a scratch copy with
  the new skill's frontmatter broken, fails with a YAML parse error, so its
  pass here is meaningful.

Depends on: Task 1

Plan Step 3.1 (C-3 to C-6; rulings M1, M3, M6, M7, M8, M9, M10, D2, D5–D10,
D12, D16–D20). Create `plugins/kenspc/skills/prototype/SKILL.md` in the
structure and tone of `plugins/kenspc/skills/diagnose-bug/SKILL.md` —
frontmatter, Trigger Phrases, Quality bar, Prerequisites, Arguments, three
phases with Goal / Inputs / DONE when / Constraints, an Exit, writing rules,
Phase transitions — every rule carrying its Why, in the skill's own words.
File references use `${CLAUDE_PLUGIN_ROOT}`.

The file carries, in substance as plan Step 3.1 gives it:

- Frontmatter: `name: prototype`; the `description` from plan Step 3.1,
  wrapped as the other skills wrap theirs (`description: >`); `version:
  3.0.0`; `argument-hint: <brief path> [entry number or question]`; no
  `effort:`; no `disable-model-invocation` (the command carries it; the
  skill routes by its description).
- A short overview under the title: three phases — Frame, Build and run,
  Record and discard — and no review phase, since the prototype is
  discarded and its answer is reviewed where a plan uses it.
- Trigger Phrases: the positive phrases of ruling D12, English and Chinese,
  and `/kenspc-prototype`; an "Avoid triggering" list with the four blocks,
  each with where it goes — a feature to keep ("just build it",
  "直接做这个功能", a demo for a client) → generate-plan or generate-task, or
  direct work for a small change; running or trying out a snippet
  ("帮我试一下这段代码", "run this and see what it prints") → just run it;
  a bug ("this crashes when") → diagnose-bug; a question discussion can
  settle ("which library is better?") → discuss, or generate-brief. Why: the
  skill commits twice and may use a development database, so a false
  trigger costs more than a missed one.
- Quality bar (D16): the smallest thing that settles the question, with
  evidence that could have come out the other way — measured against the
  entry's `Settled by:` result, or carrying a control that fails when the
  claim is false; a happy-path-only prototype settles nothing, and one that
  grows past its question is feature work.
- Prerequisites: a git repository, since the skill commits the prototype
  and its removal; a brief (D5).
- Arguments: `BRIEF` and an optional `ENTRY` — a number in the brief's Open
  Questions, or a question's text. A question with no brief path: stop,
  build nothing, and suggest `/kenspc-brief`. No arguments: ask for the
  brief and the question; in a session that cannot ask, stop.
- Phase 1, Frame. Goal: one question, the result that settles it, the kind
  (logic, UI, feature), the location, and the resources — every gate below
  passed. Inputs: the brief; the project's CLAUDE.md, README, and config
  files, read silently first;
  `git -c core.quotePath=false status --porcelain -uall`, noted at the
  start. Rules:
  - Question selection (D18): by number or text; none named → the only
    `needs prototype` entry, or, with several, ask which (cannot ask: the
    first in document order, named in the final message); a named
    `answered` entry → ask whether to prototype it again (cannot ask:
    stop); a named `open` entry is prototyped like any other.
  - A question given as text for a brief that lacks it — or lacks the
    section — is appended as a `` `needs prototype` `` entry, the section
    created when missing, before anything is built (M3). An entry with no
    `Settled by:` gets one derived from the question, shown in the frame.
  - Kind and location (D20, M8, D9): `prototypes/<slug>/` at the repository
    root (`git rev-parse --show-toplevel`) unless the project's CLAUDE.md
    names another; a conflict — `prototypes/` holds tracked files that are
    not prototypes, or CLAUDE.md's location does not fit the kind — is
    asked about (cannot ask: the default, named in the final message); an
    existing `prototypes/<slug>/` holding only leftovers is not a conflict,
    and the next free `<slug>-<n>/` is used. A logic or UI prototype that
    runs on its own goes to the location. A UI prototype that can only
    render inside the app is the one in-app kind: its location comes from
    CLAUDE.md or is asked (cannot ask, with no CLAUDE.md location: nothing
    is built, the entry stays unsettled with the reason). A feature
    prototype that needs the app's runtime runs outside the app, importing
    the app's modules, when that lets it run; otherwise it is not built, in
    either kind of session, the entry stays `` `needs prototype` `` with the
    reason in `Evidence:`, and the exit says that widening the in-app
    exception to features is the user's decision. Why: the in-app exception
    exists for what can only render inside the app, and anything that can
    run elsewhere keeps its files out of the user's source tree.
  - In-app UI (D9): a tracked file the prototype must modify that has
    uncommitted changes, and any change to the project's manifest, are
    asked about — go on, commit first, or stop (cannot ask: nothing is
    built, the entry stays unsettled with the reason).
  - Database (D8, M9): the development database is recognized by name only
    — a development-named configuration file (`appsettings.Development.json`,
    `.env.development`, `.env.development.local`), the project's
    user-secrets, or a development database the project's CLAUDE.md or
    README names; any other connection is asked about (cannot ask: not
    used); production resources are never touched. A new table or column
    on the development database gets the warning — the development database
    may be the wrong place — and the throwaway-database recommendation
    before any code; the user decides (cannot ask: a throwaway database,
    named in the final message); a user who insists is recorded in
    `Evidence:`, and a teardown script goes with the prototype. Rows
    written to existing development tables get no warning and no teardown;
    `Evidence:` names each such table. No migration file is added and none
    is applied, with any migration tool. Credentials and connection strings
    are read by name at run time — configuration keys, environment
    variables, or a secret store — never printed, and no file holding a
    value read from configuration (a `.env`, a copied `appsettings.*.json`)
    is committed. Why: history keeps every prototype, so a committed secret
    is permanent.
  - Dependencies (D19): outside the app, into the prototype's own manifest
    under the location, never the project's; for a UI prototype in the
    app, a dependency the app has to load is a manifest change and is asked
    about.
  - DONE when the frame is shown — question, `Settled by:`, kind, location,
    resources — and no gate is open. No general confirmation (D17).
- The gates: every row of the gate table in plan Step 3.1 — no arguments,
  no brief, several `needs prototype` entries none named, a named
  `answered` entry, a location conflict, an in-app UI prototype with no
  CLAUDE.md location, an in-app UI prototype with a dirty tracked file or a
  manifest change, a feature prototype that cannot run outside the app, a
  connection the development configuration does not name, a new table or
  column on the development database, a judgment answer, a failed commit —
  with its cannot-ask outcome as the table gives it. Each gate that asks
  states its cannot-ask branch in the Fixed-forms wording.
- Phase 2, Build and run. Goal: the prototype, run, its evidence gathered,
  committed. Inputs: the frame shown in Phase 1. DONE when the add commit
  exists —
  `chore: add prototype <slug>` adapted to the project's commit
  conventions, made after the run that produced the evidence, staging only
  the prototype's own paths (its source, its manifest and lockfile,
  evidence files the answer cites, and for a UI prototype in the app the
  tracked files the frame named; never installed dependencies or build
  output), passed to `git commit` as a pathspec — and the evidence either
  settles the question against `Settled by:` or shows why it cannot be
  settled here; for a UI prototype in the app, the typecheck is green
  against its baseline. Constraints:
  - Everything is written under the location, except the in-app tracked
    files the frame named; the prototype's database file, build output,
    and installed dependencies stay under the location too.
  - File names follow the naming rule of the Scratch space bullet in the
    run-directory preparation of
    `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` — the block between
    `<!-- canonical:run-dir:start -->` and `<!-- canonical:run-dir:end -->`
    — by reference, with no copy; a prototype that uses the runner as its
    harness runs it with a config of its own under the location. Why: the
    prototype is committed where the project's gates can walk, and a
    collectable name there is a test the user did not write.
  - None of the project's build, test, or lint commands runs on the
    prototype, and the project's configuration is not edited to exclude
    it; for a UI prototype in the app, only the project's typecheck runs,
    unmodified: once before building as a baseline, and before the add
    commit, green — or, when the baseline was already red, with no error
    the baseline lacked. Why: the prototype is not held to the project's
    gate, and a configuration change made for the plugin's own files is the
    user's decision.
  - Before the add commit, the staged file list and diff are read for a
    file holding a value read from configuration.
  - A commit that fails stops the run: report the error and ask how to go
    on, with no retry and no `--no-verify`; in a session that cannot ask,
    stop and report.
- The judgment point (D10): when the answer is the user's judgment, after
  the add commit the skill says how to see the prototype (a command, a
  route) and waits; the verdict is the Answer, and `Evidence:` says it was
  judged by the user and on what. In a session that cannot ask, the
  prototype is committed and discarded, the entry stays
  `` `needs prototype` `` with `Evidence:` naming what to look at and how,
  and the exit says so.
- Phase 3, Record and discard. Goal: the answer in the brief and the
  prototype out of the tree. Inputs: the add commit's hash and the evidence
  from Phase 2. DONE when:
  - the entry is rewritten per the grammar in generate-brief's writing
    rules, pointed at, not copied — `` `answered` `` with `Answer:`,
    `Evidence:`, and the Prototype line, or, unsettled,
    `` `needs prototype` `` with `Evidence:` and `Prototype:` — and nothing
    else in the brief changed (Why: the rest of the brief is the user's
    discovery record);
  - at the judgment point the user's verdict came first;
  - the teardown ran, when there was one, and the tables it created are
    gone;
  - the remove commit exists — `chore: remove prototype <slug>`, its body
    carrying `Question:`, `Answer:` or `Not settled:`, and
    `Prototype: <hash>` — as one commit: `git rm` for the paths the add
    commit added, their content in the add commit's parent for the paths
    it modified, paths passed as a pathspec;
  - `git diff <add commit>^ HEAD -- <every path the add commit touched>`
    prints nothing;
  - the brief is not committed.
- When nothing was built: no commit; the entry stays `` `needs prototype` ``
  and gains `Evidence:` with the reason and no `Prototype:`.
- Exit: the final message gives the answer (or why it is unsettled), the
  add and remove commits, `git show <hash>`, every path that
  `git status --porcelain --ignored -uall -- <location>` still lists —
  ignored and untracked alike — for the user to remove, and every default a
  session that cannot ask took. Next step: `/kenspc-plan <brief>` when no
  `` `needs prototype` `` entry remains, otherwise
  `/kenspc-prototype <brief> <n>` for the next. The skill invokes nothing
  and deletes nothing. Why: the user decides when to plan, and a recursive
  delete is what users' permission rules deny.
- Ending with the prototype still in the tree: when the run stops after the
  add commit and before the remove commit, the last message names the add
  commit, says the prototype is still in the tree, and gives the `git rm`
  (and restore) command that would remove it; the skill does not run it
  unasked. Why: like diagnose-bug's "Ending without a document", the
  branch carries something the user did not plan to keep.
- Writing rules: the conversation's language; the brief entry in the
  brief's language with its anchors as written; commit messages and
  identifiers in English; no branch, pull-request, rebase, or tag step —
  the commits land on the current branch.
- Phase transitions rest on artifacts: Phase 1 → 2 on the shown frame;
  Phase 2 → 3 on the add commit's hash; the exit on the rewritten entry and
  the remove commit.

**Files to create:**
- `plugins/kenspc/skills/prototype/SKILL.md`

**Acceptance criteria:**
- The frontmatter has `name: prototype`, `version: 3.0.0`, and
  `argument-hint: <brief path> [entry number or question]`, and no
  `effort:` or `disable-model-invocation` line. The description names the
  three blocks (a feature to keep, running a snippet, fixing a bug) and
  carries the English and Chinese triggers of plan Step 3.1, including
  "做个原型" and `/kenspc-prototype`.
- The file has Trigger Phrases (with the four-block "Avoid triggering"
  list), Quality bar, Prerequisites, and Arguments sections, and Phases 1–3
  each with Goal, Inputs, DONE when, and their Whys, followed by the Exit,
  the still-in-the-tree ending, the writing rules, and Phase transitions.
- Every gate row listed above is present with its outcome, and every gate
  that asks has a cannot-ask branch beginning "In a session that cannot ask
  (a system reminder to work without stopping)".
- The in-app exception names UI prototypes only, and the feature-prototype
  rule (outside the app when importing lets it run; otherwise not built,
  `Evidence:` with the reason, widening the user's decision) is present.
- The entry grammar is pointed at by path
  (`${CLAUDE_PLUGIN_ROOT}/skills/generate-brief/SKILL.md`); the Prototype
  line appears byte-identical to the Fixed forms.
- The naming rule is referenced by the `canonical:run-dir` marker names in
  `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md`, not copied:
  `grep -cE '__tests__|__mocks__|check-ignore' plugins/kenspc/skills/prototype/SKILL.md`
  prints `0`.
- Both commit subjects, the remove-commit body labels, the pathspec rule,
  the no-retry / no-`--no-verify` rule, the discard end-state rule, the
  `git diff <add commit>^ HEAD` check, the leftovers list with
  `git status --porcelain --ignored -uall -- <location>`, the
  development-database rules (development by name; the warning before any
  code; the teardown; the throwaway database; no migration with any tool;
  existing tables named in `Evidence:`), the credentials rule, and the
  dependency rule are present.
- `grep -c 'needs prototype' plugins/kenspc/skills/prototype/SKILL.md`
  prints a number of at least 1.
- The pointer-label grep and
  `grep -nwE 'MUST|NEVER|CRITICAL' plugins/kenspc/skills/prototype/SKILL.md`
  print nothing.
- `bash scripts/check-no-model-names.sh`, `bash scripts/check-all.sh`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 4: Add the /kenspc-prototype command

**Status:** DONE

**Implementation notes:**
- Decisions: generated the file from `kenspc-diagnose.md` with anchored
  line substitutions rather than writing it by hand, so every unchanged
  line (frontmatter delimiters, `disable-model-invocation: true`, the body's
  sentence wrap) is byte-identical to the template command.
- Changes/tradeoffs: none — implemented exactly as specified. Verified:
  `diff kenspc-diagnose.md kenspc-prototype.md` differs only in lines 2-4
  (name, description, argument-hint) and lines 8 and 10 (the skill name and
  its path); the pointer-label grep prints nothing; `claude plugin validate
  --strict ./plugins/kenspc`, `check-no-model-names.sh`, and `check-all.sh`
  (`guards run: 10`) exit 0.

Depends on: Task 3

Plan Step 3.2 (C-3; ruling M1). Create
`plugins/kenspc/commands/kenspc-prototype.md` in the shape of
`commands/kenspc-diagnose.md`: `name: kenspc-prototype`; the one-line
description "Explicit entry point for the prototype skill — answer one open
question from a brief with a throwaway prototype (原型).";
`argument-hint: <brief path> [entry number or question]`;
`disable-model-invocation: true`; a body that invokes the **prototype**
skill, reads `${CLAUDE_PLUGIN_ROOT}/skills/prototype/SKILL.md`, and passes
`$ARGUMENTS` through.

**Files to create:**
- `plugins/kenspc/commands/kenspc-prototype.md`

**Acceptance criteria:**
- `diff plugins/kenspc/commands/kenspc-diagnose.md plugins/kenspc/commands/kenspc-prototype.md`
  shows differences only in the `name`, `description`, and `argument-hint`
  lines and in the two body lines that name the skill and its path.
- The description is the one line given above, and
  `disable-model-invocation: true` is present.
- The pointer-label grep prints nothing on the file.
- `claude plugin validate --strict ./plugins/kenspc`,
  `bash scripts/check-no-model-names.sh`, and `bash scripts/check-all.sh`
  exit 0.

---

### Task 5: Name prototype in the reminder hook's brief message

**Status:** DONE

**Implementation notes:**
- Decisions: the message's opening verb changes from "generated by" to
  "written by", following the task's "a brief is normally written by a
  kenspc skill", since the prototype skill edits an existing brief rather
  than generating one; the three writers are separated by semicolons
  because each carries its own clause.
- Changes/tradeoffs: none beyond the message text. Verified: the brief
  probe prints the new message naming generate-brief (`/kenspc-brief`),
  diagnose-bug (`/kenspc-diagnose`), and prototype (`/kenspc-prototype`);
  the `_template.md` and `/x/prototypes/q/main.ts` probes print nothing and
  exit 0; the task probe's output is byte-identical (`cmp` exit 0) to the
  output of the script at HEAD before the edit; `git diff` hunks sit on
  lines 42-47, inside the brief branch's heredoc; the pointer-label grep
  prints nothing; `check-all.sh` (`guards run: 10`) exits 0.

Depends on: Task 3-4

Plan Step 4.1 (C-7; ruling M5). In
`plugins/kenspc/hooks/scripts/remind-plan-skill.sh`, change only the message
text of the `*/docs/briefs/*.md` branch. In substance: a brief is normally
written by a kenspc skill — generate-brief (Skill tool or `/kenspc-brief`),
which runs a structured discovery conversation; diagnose-bug
(`/kenspc-diagnose`) when a diagnosed fix needs planning; or prototype
(`/kenspc-prototype`), which records a prototype's answer in an existing
brief's Open Questions. If one of them has already been invoked, ignore this
message.

The plan, task, and guide branches, the template exclusions, the path
normalization, and the file-path extraction stay as they are. `hooks.json`
is not changed: the hook matches the Write tool only.

**Files to modify:**
- `plugins/kenspc/hooks/scripts/remind-plan-skill.sh`

**Acceptance criteria:**
- `printf '{"file_path":"/x/docs/briefs/a.md"}' | bash plugins/kenspc/hooks/scripts/remind-plan-skill.sh`
  prints the new brief message, which names generate-brief, diagnose-bug,
  and prototype (with `/kenspc-brief`, `/kenspc-diagnose`, and
  `/kenspc-prototype`).
- The same probe with `/x/docs/briefs/_template.md` and with
  `/x/prototypes/q/main.ts` prints nothing and exits 0.
- The probe with `/x/docs/tasks/a.md` prints the task message
  byte-identical to the output of the script before this task
  (`git show HEAD:plugins/kenspc/hooks/scripts/remind-plan-skill.sh`).
- `git diff` of the script shows changes only inside the brief branch's
  heredoc message.
- The pointer-label grep prints nothing on the script.
- `bash scripts/check-all.sh` exits 0.

---

### Task 6: Guard the needs prototype anchor in check-doc-sync-anchors.sh

**Status:** DONE

**Implementation notes:**
- Decisions: the header now opens on "the planning chain's anchors" and
  names both paths in prose (the documentation path as before; the
  open-question path: a `needs prototype` entry generate-plan stops on and
  the prototype skill settles), and the "breaks silently" paragraph gains
  "an open question nobody stops on", so the rationale covers the new
  group; the drift message says "planning-chain anchors" and lists four.
  The file name and the self-test's mutation target (`Doc-sync` in the
  task example) are unchanged.
- Changes/tradeoffs: none beyond the task. Falsifiability, by hand:
  `mkdir -p ~/Projects/_smoke/batch-c-task6-falsify && cp -R scripts
  plugins` into it; `sed 's/needs prototype/needs-proto/g'` on the copied
  `plugins/kenspc/skills/prototype/SKILL.md` (9 occurrences before, 0
  after); `bash scripts/check-doc-sync-anchors.sh` in the copy exited 1
  and printed `MISSING label 'needs prototype' in
  /Users/kenspc/Projects/_smoke/batch-c-task6-falsify/plugins/kenspc/skills/prototype/SKILL.md`,
  then the drift message "The planning-chain anchors (Documentation
  impact, Doc-sync, / Decisions needing a home, needs prototype) must stay
  spelled the same …"; the copy was moved to
  `~/Projects/_smoke/.trash/batch-c-task6-falsify-20260925-224234/`.
  Verified: main mode prints "all four anchors" and `--self-test` passes,
  both under `/bin/bash` 3.2.57; `grep -niw 'nine'` and `grep -ni 'three
  anchors'` print nothing (they printed four lines at HEAD); no
  `declare -A` and no bare `sed -i` (the existing `sed -i.bak` stays);
  `TMPDIR=$HOME/Projects/_smoke/tmp bash scripts/check-all.sh --self-test`
  prints `guards run: 10` and `self-tests run: 9`, every guard PASS and
  every fixture PASS except the pre-existing `SKIP` for
  `check-review-agent-drift.sh`, which has no fixture.

Depends on: Task 1-3

Plan Step 4.2 (ruling D13). In `scripts/check-doc-sync-anchors.sh`:

- Add three entries to `ANCHOR_CHECKS`:
  `"needs prototype|plugins/kenspc/skills/generate-brief/SKILL.md"`,
  `"needs prototype|plugins/kenspc/skills/generate-plan/SKILL.md"`, and
  `"needs prototype|plugins/kenspc/skills/prototype/SKILL.md"`.
- The header comment names the planning chain's anchors — the
  documentation path and the open-question path — as four anchors across
  eleven files, with the new group listed; the drift message names the
  fourth anchor; the success line says "all four anchors".
- The self-test copies its files from the array and needs no code change;
  its mutation target stays `Doc-sync` in the task example, and the
  self-test comments' file count follows (eleven).

`## Open Questions` is not guarded: generate-plan already carries the phrase
for its own element. No new guard script, so the counts stay
`guards run: 10` and `self-tests run: 9`.

**Files to modify:**
- `scripts/check-doc-sync-anchors.sh`

**Acceptance criteria:**
- `bash scripts/check-doc-sync-anchors.sh` and
  `TMPDIR=$HOME/Projects/_smoke/tmp bash scripts/check-doc-sync-anchors.sh --self-test`
  exit 0, and the success line says "all four anchors".
- `grep -niw 'nine' scripts/check-doc-sync-anchors.sh` and
  `grep -ni 'three anchors' scripts/check-doc-sync-anchors.sh` print
  nothing (today they print the header's, the flag description's, the
  self-test comment's, and the success line's stale counts); the header
  says four anchors across eleven files and lists the three files under
  `needs prototype`.
- Falsifiability, by hand: in a copy of `scripts/` and `plugins/` made under
  `~/Projects/_smoke/`, replacing every `needs prototype` in the copied
  `plugins/kenspc/skills/prototype/SKILL.md` makes the copied guard exit 1
  with a `MISSING label 'needs prototype'` line naming that file, and the
  drift message that follows lists `needs prototype` among the anchors; the
  copy is then moved to
  `~/Projects/_smoke/.trash/<name>-<YYYYMMDD-HHMMSS>/`. The command and its
  output are recorded in the task's Implementation notes.
- The script runs under macOS's bash 3.2 (no `declare -A`, no
  bash-4-only syntax) and uses no bare `sed -i`.
- `TMPDIR=$HOME/Projects/_smoke/tmp bash scripts/check-all.sh --self-test`
  prints `guards run: 10` and ends with `self-tests run: 9`, every line
  PASS.

---

### Task 7: Update the repository CLAUDE.md

**Status:** DONE

**Implementation notes:**
- Decisions: under "No review", the prototype's reason is its own short
  paragraph after the brief paragraph (discarded in the run that built
  it; the answer is reviewed where generate-plan reads it and
  `plan-document-reviewer` reviews the plan that cites it), and the
  "prototype path" paragraph follows the diagnosis path paragraph, the
  pattern's existing path description. The guard description is
  restructured as "four planning-chain anchors", three on the
  documentation path and one on the open-question path, so the removed
  phrase "three documentation-path" does not survive in another form. The
  Non-Goals pointer is a new paragraph after diagnose-bug's, mirroring its
  "a move of that rule updates the pointer … in the same commit" sentence.
- Changes/tradeoffs: the Project Overview's first sentence lists the new
  capability as "answering a brief's open questions with throwaway
  prototypes", placed after requirement brief generation. The Durable
  documents table is untouched. Verified: the stale-count grep and
  `grep -n 'three documentation-path'` print nothing; the eight / seven
  forms are present; `ls` shows 8 skills, 8 commands, 11 agents, matching
  the tree and the "11 reusable subagents" line; the "Nine of the guards"
  self-test sentence is unchanged and still true (`self-tests run: 9`);
  `git diff CLAUDE.md` has no table-row change; `check-all.sh`
  (`guards run: 10`) exits 0.

Depends on: Task 1-6

Plan Step 5.1 (rulings D11, M6, M12). In `CLAUDE.md` at the repository
root:

- Project Overview: the plugin also answers a brief's open questions with
  throwaway prototypes; the no-review sentence names the brief,
  diagnose-bug, and prototype skills, with the prototype's reason — it is
  discarded, and its answer is reviewed where a plan uses it.
- Plugin Directory Layout: `commands/kenspc-prototype.md` and
  `skills/prototype/SKILL.md` ("No review phase — the prototype is
  discarded; the plan that uses its answer is reviewed") in the tree; the
  hooks paragraph says the brief message names generate-brief,
  diagnose-bug, and prototype.
- SKILL.md Frontmatter Fields: "all seven skills", "syncing seven files",
  and "bump all seven" become eight.
- Subagent Review Architecture: the "No review" pattern gains the prototype
  skill; a short "prototype path" paragraph — an Open Questions entry
  marked `needs prototype` → generate-plan's exit → `/kenspc-prototype` →
  the add commit, the answered entry, the remove commit → the plan cites
  the hash; the in-app exception covers UI prototypes that can only render
  in the app. The effort paragraph's "the six other skills" becomes seven.
- Repository scripts/: `check-doc-sync-anchors.sh`'s description gains the
  `needs prototype` group (generate-brief, generate-plan, prototype) and
  the open-question path.
- Non-Goals: the prototype skill points at the Scratch space naming rule in
  the `canonical:run-dir` block and carries no copy; a move of that rule
  updates the pointer in `prototype/SKILL.md` in the same commit.
- The Durable documents table is unchanged: a brief is not a durable
  document.

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- `grep -nE 'all seven skills|syncing seven|bump all seven|six other skills' CLAUDE.md`
  prints nothing, and the eight / seven forms are present in those
  sentences.
- The layout tree lists `kenspc-prototype.md` and `prototype/SKILL.md`; the
  Project Overview, hooks paragraph, "No review" pattern, "prototype path"
  paragraph, scripts/ description, and Non-Goals edits are present.
- `grep -n 'three documentation-path' CLAUDE.md` prints nothing, and the
  `check-doc-sync-anchors.sh` description names four anchors, with
  `needs prototype` in generate-brief, generate-plan, and prototype.
- Every count and list in the file agrees with the repository:
  `ls plugins/kenspc/skills` shows eight skill directories,
  `ls plugins/kenspc/commands` eight commands, `ls plugins/kenspc/agents`
  eleven agents, and the guard counts stay `guards run: 10` /
  `self-tests run: 9`.
- `git diff CLAUDE.md` shows the Durable documents table unchanged.
- `bash scripts/check-all.sh` exits 0.

---

### Task 8: Update the READMEs and the manifests

**Status:** DONE

**Implementation notes:**
- Decisions: `prototype` is placed right after `generate-brief` in both
  skills tables, `/kenspc-prototype` right after `/kenspc-brief` in the
  root Commands line and the plugin Commands table, and `/kenspc:prototype`
  second in the skill-invocation sentence — the chain order brief →
  prototype → plan, which the workflow diagram also shows. The "Prototype
  path" paragraph sits right after the numbered workflow steps, before the
  Documentation path, since the prototype falls between the brief and the
  plan. The four Known behavior items go before "Missed-review telemetry",
  after the existing workflow items.
- Changes/tradeoffs: the plugin README's generate-brief row also names the
  next-step suggestion's `/kenspc-prototype` lines, and the prototype row
  names which choices are asked about (a location conflict, a database it
  would change, an in-app UI prototype); the Gates item names concrete
  gates (a root-reaching `tsconfig.json` include, ESLint's flat config, a
  root SDK-style `.csproj`) and says file names follow the run directory's
  naming rule. The one-line plugin blurbs at the top of both READMEs
  ("discovery brief, plan before you code, …") were not in the task and
  are unchanged; they already omitted bug diagnosis. Verified: both
  READMEs list `prototype` and `/kenspc-prototype`; eight unique
  `/kenspc:` forms in the plugin README; no skill or command count
  sentence disagrees (grep for six/seven/eight/nine/7/8 finds only
  unrelated numbers); `plugin.json` keeps `"version": "3.7.0"` and
  "last reviewed 2026-09-25", and the two manifests' diffs change only the
  description strings; `check-json.sh`, `check-all.sh` (`guards run: 10`),
  and both `claude plugin validate --strict` runs exit 0.

Depends on: Task 1-4

Plan Step 5.2 (rulings M6, M8, M10, M12, D8).

- `README.md` (root): a `prototype` row in the skills table ("Answers one
  open question from a brief with a throwaway prototype — committed, its
  answer and hash recorded in the brief, then removed — no review phase");
  `/kenspc-prototype` in the Commands line.
- `plugins/kenspc/README.md`:
  - Skills: a `prototype` row; the generate-brief row mentions Open
    Questions; the generate-plan row mentions the exit;
  - Commands: a `/kenspc-prototype` row
    (`/kenspc-prototype <brief path> [entry number or question]`), and
    `/kenspc:prototype` in the skill-invocation sentence;
  - Recommended Workflow: `[/kenspc-prototype →]` between the brief and the
    plan in the diagram, and a "Prototype path" paragraph — the entry
    grammar in one sentence, generate-plan's question, the two commits,
    `git show`, the default location `prototypes/<slug>/`, the brief left
    uncommitted, and the development-database rule (a warning before a new
    table or column, and existing tables written to named in the
    evidence);
  - Known behavior, four items: **Prototypes live in history** (committed,
    then removed in the next commit; anything committed stays in history,
    so the skill reads credentials by name and commits none); **Gates
    between the two commits** (in that window a typecheck, linter, or
    root-level project file that walks the repository reaches the
    prototype, a pre-commit hook that runs one can reject the add commit
    and the skill stops, and HEAD after the run holds no prototype);
    **Leftovers after a prototype** (dependencies, build output, and other
    files git does not track — ignored or untracked — stay under the
    location and are named in the final message; the skill deletes
    nothing); **In-app UI prototypes** (only a UI prototype that can only
    render inside the app goes into the app; its location comes from
    CLAUDE.md or the user; the typecheck green against its baseline; the
    remove commit restores the tracked files it changed; a feature
    prototype that needs the app's runtime and cannot run outside it is not
    built, and widening the exception is the user's decision).
- `plugins/kenspc/.claude-plugin/plugin.json`: the description's skill list
  adds prototyping after brief generation. `version` stays `3.7.0`, and the
  description's "last reviewed 2026-09-25" date is unchanged.
- `.claude-plugin/marketplace.json`: the top-level description adds
  "prototypes" after "discovery brief". The plugin entry's summary is
  unchanged.

**Files to modify:**
- `README.md`
- `plugins/kenspc/README.md`
- `plugins/kenspc/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

**Acceptance criteria:**
- Both READMEs list `prototype` and `/kenspc-prototype`; the plugin README's
  skill-invocation sentence lists eight `/kenspc:` forms, including
  `/kenspc:prototype`.
- The plugin README's diagram, "Prototype path" paragraph, and the four
  Known behavior items carry every point listed above, under the bolded
  item names given.
- Every sentence in the four files that counts skills or commands, or
  describes a brief's sections, agrees with the SKILL and command files.
- `plugin.json` still has `"version": "3.7.0"` and
  `last reviewed 2026-09-25` in its description, and `git diff` of the two
  manifests changes only description strings.
- `bash scripts/check-json.sh`, `bash scripts/check-all.sh`,
  `claude plugin validate --strict .`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 9: Add the 3.8.0 CHANGELOG entry and roadmap item 7's sentence

**Status:** DONE

**Implementation notes:**
- Decisions: the entry's intro follows 3.7.0's shape ("Batch C." then a
  summary, the minor-release reason, and "No new agent and no CONTEXT key
  changes") but carries no release-smoke sentence, which the release
  commit adds with the date. The CHANGELOG names the roadmap item by its
  subject ("linters and build tools that walk into `.kenspc/`"), not its
  number, as the roadmap's own header asks of text outside it. A closing
  Changed bullet covers CLAUDE.md, both READMEs, and the manifests (Tasks 7
  and 8, both DONE), as 3.7.0's entry does; the release checklist is not
  mentioned here because Task 10 had not run when this entry was written —
  the Doc-sync task reconciles it.
- Changes/tradeoffs: the Added section splits the prototype skill into
  sub-bullets (the gates, the two commits, where it lives, the in-app
  exception, the development database, what is left on disk), mirroring
  3.7.0's diagnose-bug sub-bullets; Known behavior uses the README's item
  names for the gates and the leftovers. Verified: the CHANGELOG's first
  version heading is `## 3.8.0 — unreleased`; `git diff docs/roadmap.md`
  shows only the added sentence at the end of item 7 (the `## Next minor
  (3.8.0)` heading and `## Planned batches`, batch C's line included,
  untouched); `plugin.json` still has `"version": "3.7.0"`;
  `check-all.sh` (`guards run: 10`) exits 0.

Depends on: Task 1-6

Plan Step 5.3 (C-8; ruling M11).

- `plugins/kenspc/CHANGELOG.md`: a `## 3.8.0 — unreleased` entry above
  `## 3.7.0 — 2026-09-25`, in the 3.7.0 entry's style. Added: Open
  Questions in briefs (the grammar, `Settled by:`); the prototype skill and
  `/kenspc-prototype` (the gates, the two commits, the write-back, the
  development-database rule, the in-app exception for UI prototypes, what
  is left on disk); generate-plan's exit; the guard group (counts
  unchanged). Changed: generate-brief's template, writing rules, and
  next-step suggestion; generate-plan's Phase 1 Step 1 (the exit, `open`
  entries in the gap-check, answered entries cited by hash) and its Open
  Questions element (the carried form); the hook's brief message. Known
  behavior: the gates between the two commits; leftovers; history keeps
  every prototype. No date: it is filled at release.
- `docs/roadmap.md`: item 7 gains one sentence — a prototype's files under
  `prototypes/` are in the same position between its add and remove
  commits, and a gate that walks the repository reaches them there. The
  `## Next minor (3.8.0)` heading, batch C's line under "Planned batches",
  and that section are left to the release commit.

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`
- `docs/roadmap.md`

**Acceptance criteria:**
- The CHANGELOG's first version heading is `## 3.8.0 — unreleased`, and the
  entry carries the Added, Changed, and Known behavior content above.
- `git diff docs/roadmap.md` shows only the added sentence inside item 7;
  the `## Next minor (3.8.0)` heading and the `## Planned batches` section,
  batch C's line included, are unchanged.
- `plugins/kenspc/.claude-plugin/plugin.json` still has
  `"version": "3.7.0"`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 10: Update the release checklist

**Status:** DONE

**Implementation notes:**
- Decisions: the row 3 and row 4 additions are appended to the existing
  pass criteria after a semicolon, keeping each row's existing text
  first; row 10's criterion is written in the order plan Step 5.4 lists
  its items, so the row can be read against the plan item by item. Status
  words that the brief carries in backticks are written as
  `` `open` `` / `` `needs prototype` `` / `` `answered` `` where the task
  shows them that way, and as plain code elsewhere.
- Changes/tradeoffs: none beyond the task. Verified: row 1 says 8
  commands; the smoke table runs 1–11 with row 10 `/kenspc-prototype
  <brief path>` and row 11 the end-to-end row;
  `grep -nE '[Rr]ow[- ]1[01]'` finds only "row-11 detail" and "Row 11
  sub-criteria" (at HEAD it found the row-10 forms, so the grep can hit);
  the pre-flight block and its prose still say `guards run: 10` and
  `self-tests run: 9`; `check-all.sh` (`guards run: 10`) exits 0.

Depends on: Task 1-4

Plan Step 5.4 (ruling D14). In `docs/release-checklist.md`:

- Row 1: "Lists all 8 kenspc slash commands".
- Row 3 addition: when the discussion leaves a question it cannot settle,
  the brief's `## Open Questions` lists it with `` `open` `` or
  `` `needs prototype` ``, each `needs prototype` entry with `Settled by:`;
  otherwise the section's body is `none`; the next-step suggestion names
  `/kenspc-prototype` when an entry needs one.
- Row 4 addition, per plan Step 5.4: on a brief with a
  `` `needs prototype` `` entry, the first question Phase 1 asks is
  prototype-first or carry, before any gap-check question; "prototype
  first" ends the run with the `/kenspc-prototype` line and no file;
  "carry" puts the entry in the draft's Open Questions with `From:`,
  `Not prototyped:`, and `Assumed in:`; an `open` entry the gap rounds do
  not settle appears there with `From:` and `Assumed in:`; in a session
  that cannot ask, no question is asked, `Not prototyped:` reads "the
  session could not ask", and every `open` entry is carried without a gap
  round; a brief with no `## Open Questions` section gets no such question.
- A new smoke row 10, `/kenspc-prototype <brief path>`, inserted after row
  9; the end-to-end row becomes row 11, and its "row-10 detail" and
  "Row 10 sub-criteria" references follow. Its pass criterion carries every
  item plan Step 5.4 lists: the frame; the prototype under
  `prototypes/<slug>/` (or the CLAUDE.md location), run, and committed alone
  (`chore: add prototype …`; `git show --name-only <hash>` lists only the
  prototype's paths, none matching the run-directory check's sub-check 1
  `find` patterns); the entry rewritten `` `answered` `` with `Answer:`,
  `Evidence:`, and `Prototype:` naming that commit; `chore: remove
  prototype …` with `Question:`, `Answer:`, and `Prototype:` in its body;
  `git diff <HEAD before the run> HEAD` prints nothing; the brief not
  committed; the leftovers list; the `/kenspc-plan <brief>` suggestion with
  nothing invoked; a question with no brief ending with the `/kenspc-brief`
  suggestion and no commit; the development-database cases (the warning
  before any code and no table left after a table-creating run; no warning
  and the table named in `Evidence:` for rows written to an existing table;
  a connection named only by a production file never used); the in-app UI
  case (typecheck baseline before building, green before the add commit,
  every modified tracked file restored by the remove commit); the
  feature-slice case (runs from the location with no tracked app file in
  the add commit, or builds nothing, makes no commit, and leaves the entry
  `` `needs prototype` `` with the reason); and "直接把这个功能做出来" and
  "帮我跑一下这段代码" invoking no prototype skill.
- The pre-flight counts stay `guards run: 10` and `self-tests run: 9`.

**Files to modify:**
- `docs/release-checklist.md`

**Acceptance criteria:**
- Row 1 says 8 commands; the smoke table has rows 1–11 in order, row 10 is
  `/kenspc-prototype`, and row 11 is the end-to-end row.
- `grep -nE '[Rr]ow[- ]1[01]' docs/release-checklist.md` finds only
  references whose number matches the row they mean: the end-to-end detail
  pointer and sub-criteria heading say row 11.
- Row 10's pass criterion and the row 3 and row 4 additions carry every
  item listed above.
- The pre-flight block and its prose still say `guards run: 10` and
  `self-tests run: 9`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 11: Doc-sync

**Status:** DONE

**Implementation notes:**
- Decisions: promotion of Tasks 1-10's decisions —
  - Promoted, T3: every question a skill asks carries its cannot-ask
    branch in prose at that question, in the fixed wording, and a gate
    table only summarizes — into `CLAUDE.md` § Writing Rules for Skill
    Content, as a convention for future skills and gates.
  - Promoted, T1 and T3: the Open Questions grammar is written once, in
    generate-brief's writing rules, and pointed at by generate-plan and the
    prototype skill; the prototype skill's one copy is the byte-identical
    Prototype line, so a change to it updates both files in one commit, and
    the anchor guard does not cover it — into `CLAUDE.md` § Non-Goals,
    beside the run-dir pointer paragraph.
  - Local: T1's placeholder spelling and added Whys; T2's layout of the
    brief branch; T3's `git checkout <add commit>^ --` restore spelling;
    T4's generation from `kenspc-diagnose.md`; T5's "written by" verb; T6's
    header wording; T7's and T8's placements; T9's intro without a smoke
    sentence (the release commit adds it, as 3.7.0's did); T10's append
    order and backtick forms.
  - Needs a home: none.
- Changes/tradeoffs: verification found four places where a listed
  document did not match what Tasks 1-10 built, each corrected in that
  document: (1) `plugins/kenspc/CHANGELOG.md` did not describe the release
  checklist (Task 9 ran before Task 10) — a Release checklist bullet is
  added under Changed, and the documentation bullet names the two CLAUDE.md
  promotions; its gates bullet listed only some cannot-ask outcomes and now
  names each kind (a stop, the first entry, the default location, a
  connection left unused, a throwaway database, nothing built);
  (2) `plugins/kenspc/README.md`'s prototype row said "a database it would
  change" is asked about, but rows written to existing development tables
  are not — it now names an unnamed connection and a new table or column,
  and the in-app location and uncommitted files; (3) the README's
  development-database name list gains `.env.development.local`, which the
  skill names; (4) `docs/release-checklist.md` row 10 said the exit
  suggests `/kenspc-plan <brief>` unconditionally, but the skill suggests
  it only when no `needs prototype` entry remains, otherwise
  `/kenspc-prototype <brief> <n>` — a smoke brief seeded with two
  `needs prototype` entries would have failed the row on correct behavior.
  `README.md` and `docs/roadmap.md` matched and are unchanged. Files
  touched: the four above; no file outside the listed documents.
  `check-all.sh` (`guards run: 10`) exits 0.

Depends on: Task 1-10

Bring the documents below in line with what Tasks 1-10 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` § Project Overview, § Plugin Directory Layout, § Skill
  Development Conventions (skill count, hooks paragraph), § Subagent Review
  Architecture (orchestration patterns, effort paragraph), § Repository
  scripts/, § Non-Goals — the prototype skill and command, the eight-skill
  counts, the prototype path, the hook's brief message, the guard group,
  and the naming-rule pointer (plan Step 5.1); edited by Task 7: verify it
  against the implementation instead of editing it again.
- `plugins/kenspc/README.md` § Skills, § Commands, § Recommended Workflow,
  § Known behavior — the prototype row and command, the generate-brief and
  generate-plan rows, the prototype path, and the four Known behavior items
  (plan Step 5.2); edited by Task 8: verify it against the implementation
  instead of editing it again.
- `README.md` § Available Plugins (skills table, Commands line) — the
  prototype row and `/kenspc-prototype` (plan Step 5.2); edited by Task 8:
  verify it against the implementation instead of editing it again.
- `plugins/kenspc/CHANGELOG.md` — the `## 3.8.0 — unreleased` entry (plan
  Step 5.3); edited by Task 9: verify it against the implementation instead
  of editing it again.
- `docs/roadmap.md` — item 7's sentence (plan Step 5.3); edited by Task 9:
  verify it against the implementation instead of editing it again. The
  heading, batch C's line under "Planned batches", and that section change
  in the release commit, not in this batch.
- `docs/release-checklist.md` — row 1, the row 3 and row 4 additions, the
  new `/kenspc-prototype` row 10, and the end-to-end row renumbered 11 (plan
  Step 5.4); edited by Task 10: verify it against the implementation
  instead of editing it again.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-10. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-10 implemented, so
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
- Edit the plugin's skill and command files in a session started without
  `--plugin-dir` (CLAUDE.md § Test the plugin locally): a `--plugin-dir`
  session treats those files as the definitions it is running, and edits to
  them have been refused there.
- After the last task, the release checklist's pre-flight block (effort
  diff, both `claude plugin validate --strict` runs, and
  `bash scripts/check-all.sh --self-test` with `guards run: 10` and
  `self-tests run: 9`, run with the `TMPDIR` prefix of the Constraints) is
  the batch's mechanical check. Acceptance of the
  live chain runs in a separate session (plan § Testing Strategy).
