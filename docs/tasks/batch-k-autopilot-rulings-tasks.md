# Batch K — autopilot rulings (4.5.0) — Task Document

## Context

Tasks decomposed from `docs/plans/batch-k-autopilot-rulings.md` (the spec).
The batch lets an autopilot batch run from its spec to its release
preparation without waiting on the user between its two gates: the main
session rules every point the spec leaves open, except the stop
conditions, and records each ruling where the user reviews it before the
tag and the push. A ruling on a review's findings reaches code-fixer and
regression-verifier through `RUN_DIR/rulings.md`, never through
`CUSTOM_INSTRUCTIONS`. Phase 0 stops asking the two questions every recent
batch asked. Two rails items, a guard that ties the `## Rail observations`
heading across its carriers, task-implement's branch for a document with no
incomplete task, and the telemetry hook's transcript root ride along.

Related plan: `docs/plans/batch-k-autopilot-rulings.md`. The spec's labels
— K-L1 to K-L16 (Locked design, immutable), K-D1 to K-D6 (Design
decisions), K-C<n> (clarifications) — are pointers in this document only
and appear in no shipped file.

Rulings at this document's confirmation (the main session, recorded in the
spec as K-C1 to K-C4):

- **K-C1.** The second failure of the skipped-gate post-check is a stop
  stated at the post-check, outside the numbered stop list, with the
  cannot-ask sentence; the gates table's post-check row says so (Task 2,
  Task 5).
- **K-C2.** Phase 0's questions about the run's inputs — no path, the entry
  kind, which plugin, an inbound source the main session cannot read — stay
  as they stand, and where SKILL.md says the main session asks the user
  only on a stop condition and at the two gates, it also says these are
  asked before the first launch as part of the start (Task 1, Task 5).
  Step 1.1's "no sentence sends a point outside the stop conditions to the
  user" is checked against points raised once the run has started.
- **K-C3.** Task 6 carries only what the two settings pages state, with
  both URLs and the date 2026-09-30. Server-delivered settings stay the
  locked design's "a source the main session cannot read" case, which
  asks. No local cache path for them and no claim about what a
  non-interactive run writes. No network use in S3.
- **K-C4.** Delegated names: the subsection `### How the main session
  rules`, in Phase 2 directly before `### A worker's question at a gate`;
  the reviewer-report line `- Follow-up candidates: <list | none>`; the
  shared unreadable-field literal `could not be read from the hook input`
  (the hook's own text).

Constraints for every task:

- **Files.** Only the spec's `Allowed files:`; a file outside them is a
  forbidden file. The spec's `Zero diff:` paths stay untouched — among them
  the drivers (`skills/autopilot/scripts/`), `hooks/hooks.json`, the rails
  hook script, `commands/`, `shared/`, `references/`, every agent other
  than `code-fixer.md` and `regression-verifier.md`, and every guard other
  than `check-run-contract.sh` and `check-autopilot-rails-hook.sh`.
  `plugin.json` and `marketplace.json` are left to the release preparation.
- **Byte-identity.** The canonical dispatch, verdict-shared, run-dir, and
  stats-line blocks stay byte-identical and unchanged, as do the code-craft
  principle blocks; new text goes outside every `canonical:` marker pair.
- **Language.** Everything written is English.
- **No model name** in any plugin file (`check-no-model-names.sh`).
- **Pointer rule.** After each task,
  `git diff -U0 <HEAD before the task> -- <the task's files other than this task document> | grep -E '^\+.*K-[LDC][0-9]'`
  prints nothing. Positive control, run first:
  `grep -cE 'K-[LDC][0-9]' docs/plans/batch-k-autopilot-rulings.md`
  prints a number greater than 0.
- **Searches that must come back empty** each get a positive control — the
  same pattern run where it must hit — before the empty result counts.
- **Why prose.** Every new rule in a skill, agent, or script carries its
  Why, with evidence stated in its own words (what failed, on which
  command), never cited as a dry-run record or by a product repository's
  name.
- **Cannot-ask branch.** Every point where the autopilot skill still asks
  states, at that point, what a session that cannot ask does, opening with
  "In a session that cannot ask (a system reminder to work without
  stopping), …".
- **Fixed lines** (report fields, state-file sections, stop and finish
  lines, the question and answer first lines) stay in English.
- **This run's own scratch.** This batch's implementer runs the plugin text
  from before the batch, whose task-implement gives it a run directory:
  every probe, copy, mutant, and scratch config goes under
  `RUN_DIR/scratch/task-implementer/` as its SCRATCH SPACE section says,
  or under `$TMPDIR` where a task says so (Task 14). No tracked file is
  edited, backed up, or restored to test it. No recursive `rm` in any
  spelling; starting over uses a new directory. A write that lands under
  `/tmp` anyway is listed in the task's Implementation notes.
- **Checks after each task.** `bash scripts/check-all.sh`, its exit status
  read on its own line, not through a pipe; a task that touches a guard
  also runs that guard's `--self-test` and `bash scripts/check-all.sh --self-test`.
- **Commit scope.** Each task's commit changes only the files the task
  names, plus this task document's status and notes, with a subject in the
  repository's commit convention (its recent subjects: a conventional type
  with a scope, such as `fix(autopilot):` or `docs(plans):`).

Dependency note: Task 2 depends on Task 1 (it points at the subsection
Task 1 writes); Task 4 on Tasks 1-3 (it edits the clarification entries
they describe); Task 5 on Tasks 1-4; Task 11 on Tasks 9 and 10; Task 12 on
Task 8; Task 15 (Doc-sync) on Tasks 1-14. Tasks 1-8 all edit
`plugins/kenspc/skills/autopilot/SKILL.md`, and Tasks 9 and 13 both edit
`plugins/kenspc/skills/task-implement/SKILL.md`; they run in document order.

Coverage: Step 1.1 → Tasks 1-5 (K-L1, K-L3, K-L4 Task 1; K-L6 Task 2; K-L5
Task 3; K-L7 Task 4; K-L2 and the gates table Task 5); Step 1.2 → Task 6
(K-L9, K-L10); Step 1.3 → Task 7 (K-L11, K-L8's preamble sentence) and
Task 8 (K-L12); Step 2.1 → Task 9; Step 2.2 → Task 10; Step 2.3 → Task 11;
Step 3.1 → Task 12 (K-L13); Step 3.2 → Task 13 (K-L14); Step 3.3 → Task 14
(K-L15); Step 4.1 → Task 15. K-L16 binds every task.

The batch's baseline is `8db589b`, the spec's commit.

## Tasks

### Task 1: SKILL.md — who rules, and how

**Status:** TODO

Spec Step 1.1 — K-L1, K-L3, K-L4; K-C2, K-C4. File:
`plugins/kenspc/skills/autopilot/SKILL.md`.

- **Quality bar.** The run asks the user only on a stop condition and at
  the two gates, and the main session rules every other point the spec
  leaves open; Phase 0's questions about the run's inputs (no path, the
  entry kind, which plugin, an inbound source it cannot read) are asked
  before the first launch as part of the start (K-C2). The named failure
  "a run that approves a worker's question on the user's behalf" is
  replaced by two: a run that rules itself on a point a stop condition
  gives the user, and a ruling missing from the record. "A run that narrows
  the implementation to fit its budget" stays. The Why is rewritten to
  match: the worker proposes and the main session rules, two sessions;
  every ruling is recorded and committed; the tag, the push, and the
  release stay the user's, after the reports, so a ruling is read before
  anything leaves the machine.
- **`### How the main session rules`**, a new subsection in Phase 2
  directly before `### A worker's question at a gate` (K-C4), stating:
  - what the main session rules: a worker's question, a choice riding on a
    task-list confirmation, a question it raises itself, a review row's or
    an acceptance FAIL's classification, a deferred row's route, a
    corrected acceptance case (Task 3 writes that rule);
  - it answers a waiting worker at once, in the `answer <tag>:` form;
  - it asks the user only on a stop condition and at the two gates, and its
    ruling is the same whether or not the session can ask;
  - the order it rules by: the spec's words; the locked design; the
    project's instruction files and the patterns in adjacent code; then the
    option easiest to reverse and closest to the spec's scope. A worker's
    suggested answer is evidence, not a default. It never stops for a
    preference between options that all stay inside the batch's contract:
    it picks by the order and records why;
  - a ruling may depart from a sentence of the spec — never a locked point —
    when evidence shows the sentence wrong: a test, a probe, a reviewer's
    reproduction, a documented tool behavior. The clarification names the
    evidence, and the ruling goes on the reviewer report's
    `beyond the letter` list;
  - a worker still never rules itself: it asks the main session, which
    records every answer, while an answer a worker invents is recorded
    nowhere;
  - each point with its Why, the evidence in the skill's own words: in three
    batches the user was asked 25 questions and chose the main session's own
    recommendation 24 times, while each wait held a worker past its thirty
    minutes (36 and 95 minutes in one batch, two and a half hours of
    question rounds in another); a real spec never settles every name and
    detail, so sending every open point to the user made an open-ended third
    gate.
- **§ The message protocol**, the answer bullet: the main session answers
  at once.
- **§ The decision hierarchy**: clarifications during implementation are
  the main session's, by § How the main session rules, recorded in the spec
  and committed; a ruling that departs from a spec sentence on evidence is
  reported on the `beyond the letter` list, beside a decision that reads a
  locked point beyond its letter.
- **§ The driver**, the `APPEND_SP` sentence: its reason names the failure
  as the Quality bar now does (a worker told to work without stopping would
  answer its own questions, and those rulings would be recorded nowhere),
  not the removed one.

**Acceptance criteria:**
- `grep -n "approves a worker's" plugins/kenspc/skills/autopilot/SKILL.md`
  prints nothing (positive control:
  `git show 8db589b:plugins/kenspc/skills/autopilot/SKILL.md | grep -c "approves a worker's"`
  prints 1 or more; the phrase wraps after `worker's` there), and the
  Quality bar names the three failures above.
- The Quality bar, or the new subsection, says Phase 0's input questions
  are asked before the first launch as part of the start.
- `### How the main session rules` sits directly before
  `### A worker's question at a gate` and states each bullet above with its
  Why.
- The message protocol's answer bullet, the decision hierarchy, and the
  `APPEND_SP` sentence agree with the subsection.
- `bash scripts/check-all.sh` exits 0.

---

### Task 2: SKILL.md — S2's confirmation and the skipped-gate post-check

**Status:** TODO

Depends on: Task 1

Spec Step 1.1 — K-L6; K-C1. File:
`plugins/kenspc/skills/autopilot/SKILL.md`.

- **§ A worker's question at a gate, the confirmation.** The answer is
  `yes` when the task list matches the spec's steps; a step without a task
  is answered "add a task for <step>"; a task outside the spec is answered
  "drop <task>", unless a spec step needs it, which the main session rules
  and records; a choice riding on the confirmation — a type, a shape, a
  name, or a behavior the worker proposes to pin, however the worker frames
  it — is ruled by the main session (§ How the main session rules) and
  recorded. The rubric's two named failures are restated for this: a
  mismatch answered `yes`, and a riding choice passed without a recorded
  ruling. The Why keeps the framing evidence (one unstated point went to
  the user in one run and was confirmed by the main session in another,
  depending only on how the worker framed it) and states the new
  conclusion: sending every such choice to the main session removes the
  framing question as sending every one to the user did.
- The paragraph "A question the spec does not answer is a stop, …" and its
  cannot-ask sentence go: a question the spec does not answer is ruled by
  the main session, the same whether or not the session can ask. The batch
  gate (S3) is still answered `yes`.
- **The skipped-gate post-check** keeps its trigger and its rubric. A
  match, or rulings the committed task document already follows, is
  accepted and recorded as a behavior deviation, as today. A mismatch, or an
  open choice whose ruling differs from the committed document, resumes S2
  under its next `<tag>-r<k>` with a prompt whose first line is
  `answer <tag>: <one line>` and whose body is the ruling, to amend the task
  document and commit it; the post-check then runs again on the amended
  document. A second failure is a stop stated here, outside the numbered
  list (K-C1), with the mismatch or the choice quoted, followed by "In a
  session that cannot ask (a system reminder to work without stopping), the
  run ends with it quoted." The resume counts as a resume under `Caps:`.
  Why: the committed document is on disk to amend, and the worker that
  wrote it amends it; a stop on the first mismatch sent the user a point
  the main session rules everywhere else.
- **State file template**: the `skipped gates:` entry form gains the resume
  outcome (the wording is the implementer's, for example
  `resumed <tag>-r<k> to amend`).
- **§ Phase transitions**, S2 → S3: the post-check's match recorded, after
  the amendment when there was one.
- Stop condition 7's present mention of the post-check is left to Task 5,
  which rewrites stop 7.

**Acceptance criteria:**
- § A worker's question at a gate states the four answers above, and no
  sentence in it sends a mismatch or a riding choice to the user.
- The post-check states the accepted outcomes, the resume under
  `<tag>-r<k>` with the ruling as the answer, the second run of the
  post-check, and the second failure as a stop with the cannot-ask sentence
  opening "In a session that cannot ask (a system reminder to work without
  stopping),".
- The state file template and the S2 → S3 transition agree with it.
- `bash scripts/check-all.sh` exits 0.

---

### Task 3: SKILL.md — a corrected acceptance case

**Status:** TODO

Spec Step 1.1 — K-L5. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- **Phase 3**, a paragraph on corrected cases: the main session may rule a
  corrected form of an `Acceptance:` case when it has both (1) evidence that
  the case as written fails, or passes vacuously, for a reason outside the
  batch's work — shown at the baseline, or a named tool behavior verified by
  running it — and (2) a negative control: the corrected form fails on a
  deliberate break of what the case checks, with the output recorded. The
  ruling is a clarification carrying the case, the corrected form, and both
  pieces of evidence (paths or quoted output). The `## Autopilot` section
  stays as Phase 0 read it: a correction is a ruling, not a settings edit.
  Without both pieces of evidence, the correction is stop 7 (b) (Task 5
  writes stop 7). The text says where the main session gathers the
  evidence so that the repository's working tree is not changed by it
  (Phase 2's Constraints: the main session commits nothing but clarification
  entries). Why, in the skill's own words: four acceptance commands broke
  for reasons outside the batch's work — a flag the package manager read
  instead of the test runner, a failure word that matched an application
  log line, a summary line the installed SDK does not print so the command
  failed at the pre-batch commit, a check that passed vacuously because a
  clone was never restored — and each time the main session had verified a
  corrected form before it asked; the negative control keeps a correction
  from loosening a check until it passes.
- **Both S4 task blocks** (plugin mode and repo mode): a corrected case is
  listed in its corrected form, naming its clarification — a bracketed part
  of the case line, written for a corrected case — and the bullet above
  each block says when it is written. An `-s4b` re-run of a corrected case
  runs the corrected form.
- **Reviewer report template**, the `- Acceptance:` line: a corrected case
  reads `in the corrected form (<clarification>)`.

**Acceptance criteria:**
- Phase 3 states both pieces of evidence, the clarification's contents, the
  unchanged `## Autopilot` section, stop 7 (b) without both, and where the
  evidence is gathered — a place that leaves the repository's working tree
  and index unchanged, the negative control's deliberate break included —
  with the Why.
- Both S4 task blocks carry the corrected-form part and the bullets above
  them say when it is written.
- The reviewer report template's `- Acceptance:` line holds
  `in the corrected form (<clarification>)`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 4: SKILL.md — the record

**Status:** TODO

Depends on: Task 1-3

Spec Step 1.1 — K-L7. File: `plugins/kenspc/skills/autopilot/SKILL.md`.

- **State file template**: `questions answered:` lines read
  `<tag>: <one line> → <one line> (main session|user)`, and the prose says
  every ruling is recorded there, whoever made it.
- **Clarification entries** name who ruled, wherever the skill describes
  one: Phase 2's Constraints, the verdict loop after S3b, Phase 3's
  Classification, and the entries Tasks 1-3 describe (§ How the main session
  rules, the confirmation's rulings, a corrected case).
- **Reviewer report template**: after the
  `- Design rulings and clarifications:` line, the line
  `- Main-session rulings: <n> | none`, followed by one indented line per
  ruling — its clarification, the tag or step, the question, the ruling,
  the reason, and the commits it produced. The prose below the template
  says what it is built from (the state file's `questions answered:` lines
  marked `(main session)` and the clarifications).
- **Phase 4 § The reports**, the `## User report` bullet: the same rulings,
  one line each in the user's language, under a heading that says they are
  for the user to review before the tag and the push; the one-page limit
  does not count this list. Why: the user reviews every ruling from the
  reports before anything leaves the machine, and a limit that cut the list
  would cut the part the user must read.
- **Exit**, the finish paragraph, agrees with the user report.

**Acceptance criteria:**
- The state file template holds `(main session|user)` on the
  `questions answered:` line.
- The reviewer report template holds `- Main-session rulings: <n> | none`
  directly after the `Design rulings and clarifications` line, with the
  indented line form, and the prose says how it is built.
- Every place the skill describes a clarification entry says it names who
  ruled.
- The user report bullet states the list, its heading's purpose, and that
  the one-page limit does not count it.
- `bash scripts/check-all.sh` exits 0.

---

### Task 5: SKILL.md — the stop conditions and the gates table

**Status:** TODO

Depends on: Task 1-4

Spec Step 1.1 — K-L2; K-C1, K-C2, K-C4. File:
`plugins/kenspc/skills/autopilot/SKILL.md`.

- **Stop condition 7** becomes: a way forward the main session cannot rule
  on — (a) every option changes the batch's contract and none stays inside
  it: a new dependency, an API contract change, a database schema or
  configuration change the spec does not name, a change to a file outside
  `Allowed files:` or on the zero-diff list; or (b) an acceptance case
  corrected without both pieces of evidence (Phase 3). When one option stays
  inside the contract — defer to a follow-up, leave as is — the main session
  takes it and records it, and the question is not asked. Reopening a locked
  point stays stop 1, and a ruling "leave the locked point as it stands and
  record the finding as a follow-up" is the main session's, not a stop.
  With its Why.
- Stop conditions 1-6 and 8-10 keep their text. Stop 11 is Task 8's.
- **§ A question only a later step needs** keeps its text and applies to
  stop 7's narrowed kind; change at most the words that tie it to that
  kind.
- **Outward actions** a run does not need in order to continue — filing an
  issue, a backlog item — are never taken and never asked mid-run: the
  reviewer report lists them as follow-up candidates for the user, on a new
  template line `- Follow-up candidates: <list | none>` (K-C4), with prose
  saying what goes on it. Why: such an action leaves the machine, and the
  user decides it after the reports, as the tag and the push.
- **Stops stated at their own steps** stay: a driver that refuses a launch,
  an artifact absent after a return, an unmarked acceptance case that cannot
  be run, and the second post-check failure (K-C1).
- **The gates table** agrees with the prose of Tasks 1-5: the two rows for a
  worker's question become the main session's ruling (asks nothing; the
  same in a session that cannot ask); the post-check row resumes S2 to amend
  the document, and its second failure is a stop with it quoted (K-C1);
  stop 7's (a) and (b) have their outcome; the later-step row reads stop 7's
  narrowed kind; Phase 0's input questions stay (K-C2). The sentence
  "Every question the skill asks is one of these gates" stays true.

**Acceptance criteria:**
- Stop 7 reads as above, with its Why; the lines of stops 1-6 and 8-10 are
  identical to their lines at `8db589b`
  (`git show 8db589b:plugins/kenspc/skills/autopilot/SKILL.md`).
- Every hit of
  `grep -niE 'question to the user|asks? the user|goes to the user' plugins/kenspc/skills/autopilot/SKILL.md`
  is a stop condition, the stop list's opening sentence, a stop stated at
  its own step, a Phase 0 input question, the brief entry's design table,
  the final gate, the Quality bar's or the new subsection's statement of
  when the user is asked, or the preamble's § 1 sentence about the points
  where a skill the worker runs would ask the user (positive control: the
  same grep over the file at `8db589b` hits `is a question to the user`).
  The grep matches within a line only, so the sentences around each hit
  are read too.
- The reviewer report template holds `- Follow-up candidates: <list | none>`.
- Each row of the gates table matches the sentence at its gate, and every
  gate that still asks carries the cannot-ask sentence at that gate.
- `bash scripts/check-all.sh` exits 0.

---

### Task 6: SKILL.md — Phase 0: inbound from the settings files, and a label with a note

**Status:** TODO

Spec Step 1.2 — K-L9, K-L10; K-C3. File:
`plugins/kenspc/skills/autopilot/SKILL.md`.

- **§ The start checks, the inbound bullet.** When the launch line carries
  no `crossSessionInbound` accept, the main session reads the value from
  the settings files Claude Code reads it from — managed settings, user
  settings (`$CLAUDE_CONFIG_DIR/settings.json`, else
  `~/.claude/settings.json`, written with `$HOME` in a lookup for the reason
  § The pass-through values gives), the project's `.claude/settings.json`
  and `.claude/settings.local.json` — with the precedence § The message
  protocol already states. An absent file sets nothing. Effective value
  `accept`: the run goes on, and the state file records the file and line
  the value came from. `hold` or `refuse`: the stop naming the launch line.
  A file that exists and cannot be read or parsed, or a source the main
  session cannot read (settings delivered from a server): the question as
  today, followed by "In a session that cannot ask (a system reminder to
  work without stopping), the run ends naming the launch line." The text
  says when the main session treats a source it cannot read as present,
  from what the two pages below state; the stop on the first message's
  delivery notice (§ The message protocol) stays the backstop. Why: three
  batches asked the same question with the value already read from the user
  settings and no project or managed override found.
- **The Why cites the two pages and the date, carrying only what they
  state (K-C3).** As read on 2026-09-30:
  - https://code.claude.com/docs/en/settings — precedence, highest first:
    managed settings; the command line (`claude --settings`); project local
    (`.claude/settings.local.json`); shared project (`.claude/settings.json`);
    user (`~/.claude/settings.json`). `CLAUDE_CONFIG_DIR` keeps the
    home-directory files elsewhere, settings included. `crossSessionInbound`
    is an exception to managed precedence: a stricter value from
    `.claude/settings.json` or `.claude/settings.local.json`, on the
    `accept` < `hold` < `refuse` ladder, is honored over managed,
    `--settings`, and user values, and a project or local value that is not
    stricter is ignored.
  - https://code.claude.com/docs/en/managed-settings — the file source:
    `managed-settings.json`, with an optional `managed-settings.d/`
    directory beside it, in `/Library/Application Support/ClaudeCode/` on
    macOS, `/etc/claude-code/` on Linux and WSL, and
    `C:\Program Files\ClaudeCode\` on Windows (the legacy
    `C:\ProgramData\ClaudeCode\managed-settings.json` is not read); MDM: the
    macOS `com.anthropic.claudecode` managed preferences domain, and the
    Windows value `Settings` under `HKLM\SOFTWARE\Policies\ClaudeCode`; the
    user-writable `HKCU\SOFTWARE\Policies\ClaudeCode` value of the same name;
    server-managed settings from the claude.ai console. The sources in
    order, highest first: server-managed, MDM (the macOS plist or the HKLM
    key), the managed files (`managed-settings.d/*.json` merged with
    `managed-settings.json`), the HKCU key. By default Claude Code uses the
    highest-ranked source that delivers at least one policy key and ignores
    the others; `crossSessionInbound` is among the lock keys, for which the
    strictest value any source sets applies when the sources are merged.
  No local cache path for server-managed settings, and no claim about what
  a non-interactive run writes.
- **State file template**: a field for where the inbound value came from
  (the name is the implementer's), and Phase 0's **Inputs** gains the
  settings files.
- **The gates table's inbound row**: asked only when a file cannot be read
  or parsed or a source cannot be read; the cannot-ask outcome unchanged.
- **§ The `## Autopilot` section (K-L10).** `- <Label> (<note>):` is read as
  `- <Label>:` for a known label. The note is carried with the field: for
  `Acceptance:`, as a run-notes line in both S4 task blocks (a bracketed
  line written when the field carries a note); for any other field, named
  on the line after the settings line (§ The settings line's note line).
  An unknown label with a note stays unknown: ignored and named, as today.
  Why: a spec wrote its acceptance field as
  `Acceptance (in the order listed, …):`, and read strictly, an unknown
  label would have run the batch with no acceptance; the note carried the
  cases' run conditions.

**Acceptance criteria:**
- The inbound bullet states the files, the precedence, the absent-file
  rule, the three outcomes, the state file's record, the question with the
  cannot-ask sentence opening "In a session that cannot ask (a system
  reminder to work without stopping),", and the backstop.
- Read by the bullet, the case three batches asked about — `accept` in the
  user settings file, and no project, local, or managed-settings file that
  sets the key — goes on without the question, the state file recording the
  user settings file and line; a source the main session cannot read raises
  the question only on a condition the bullet states and the main session
  can check.
- Its Why names both URLs and `2026-09-30` and states nothing the two pages
  above do not state.
- Read by the new rule, `- Acceptance (in the order listed, …):` is the
  `Acceptance:` field with the note `in the order listed, …`, and both S4
  task blocks carry the note line; an unknown label with a note is still
  ignored and named.
- The gates table's inbound row, the state file template, and Phase 0's
  Inputs agree with the bullet.
- `bash scripts/check-all.sh` exits 0.

---

### Task 7: SKILL.md — the preamble

**Status:** TODO

Spec Step 1.3 — K-L11, K-L8's preamble sentence. File:
`plugins/kenspc/skills/autopilot/SKILL.md`.

- **The preamble template's § 1.** The sentence "Do not approve anything on
  the user's behalf because the run is unattended: …" becomes a rule
  against deciding a question yourself: the worker asks the main session,
  which rules and records every answer, since an answer the worker decides
  is recorded nowhere. And the rulings-file sentence: an answer that rules
  on the findings of a review the worker is running (task-review, or
  task-implement's review phase) goes into that run's `RUN_DIR/rulings.md`
  before code-fixer is dispatched, never into an agent's
  `CUSTOM_INSTRUCTIONS`.
- **The preamble template's § 3**, three additions:
  - a script or program the worker writes during the run and then runs — a
    helper in scratch, `$TMPDIR`, or the workspace — is its own writing, and
    a recursive delete in it is a breach as if typed; code the batch
    implements and its tests, run as the project runs them, stay a program
    the worker runs;
  - reaching an effect the rails hook denied by another spelling — another
    command, another tool, a script — is a breach;
  - listing environment variables prints names only, never values.
  The existing sentence that a program's own `mktemp` cleanup or cache is
  not a breach stays, and reads with the first addition.
- **Why paragraphs below the template**, one for § 1's two sentences and one
  per § 3 addition, the evidence in the skill's own words: a ruling written
  into code-fixer's and regression-verifier's `CUSTOM_INSTRUCTIONS` broke
  task-review's rule that both get the reviewers' CONTEXT unchanged; a
  worker printed the machine's local messaging-socket token from an
  environment listing whose redaction pattern missed it; a helper script is
  the agent's choice of a delete as much as a typed command is; a denied
  effect reached another way leaves the denial with no effect.
- The preamble stays self-contained: nothing in the template refers to an
  earlier batch.

**Acceptance criteria:**
- `grep -n 'Do not approve anything' plugins/kenspc/skills/autopilot/SKILL.md`
  prints nothing (positive control: the same grep over
  `git show 8db589b:plugins/kenspc/skills/autopilot/SKILL.md` hits once),
  and the template's § 1 holds the rule against deciding a question
  yourself and a sentence naming `RUN_DIR/rulings.md` and
  `CUSTOM_INSTRUCTIONS`.
- The template's § 3 holds the three additions and still holds the
  `mktemp` sentence, `git rm`, `.trash`, and `## Rail observations`.
- The template (the fenced block under `### The preamble`) holds no
  `earlier batch` (positive control:
  `grep -c 'earlier batch' plugins/kenspc/skills/autopilot/SKILL.md` prints
  1 or more, from the sentence above the template).
- The Why paragraphs below the template cover § 1's two sentences and each
  addition.
- `bash scripts/check-all.sh` exits 0.

---

### Task 8: SKILL.md — stop condition 11

**Status:** TODO

Spec Step 1.3 — K-L12; K-C4. File:
`plugins/kenspc/skills/autopilot/SKILL.md`.

- **§ Launch, wait, return, the return.** At a worker's return, a
  `## Rail observations` entry that carries a denial whose reason contains
  `could not be read from the hook input` is stop 11, naming the field —
  the name in parentheses in the reason (`tool_name`, `tool_input.command`,
  `tool_input.<key>`) — and the output of `claude --version` run in the main
  session's Bash. The entry is still recorded under the state file's
  `rail observations:`.
- **The stop conditions** gain `11.` with its Why: the hook no longer reads
  the harness's input format, so every later worker would end the same way.
  The stop list's opening paragraph already carries the cannot-ask sentence.
- The hook's reason text is the one it prints today; the hook is not edited
  (Zero diff).

**Acceptance criteria:**
- `grep -c 'could not be read from the hook input' plugins/kenspc/skills/autopilot/SKILL.md`
  prints 1 or more, and the same grep over
  `plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh` prints 3 (the
  literal is the hook's own).
- The stop list runs 1-11, stop 11 as above with its Why; § Launch, wait,
  return states the check at the return.
- `git diff 8db589b -- plugins/kenspc/hooks/hooks.json plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh`
  prints nothing (Task 14's edit of the telemetry hook, in the same
  directory, is outside this check).
- `bash scripts/check-all.sh` exits 0.

---

### Task 9: task-review and task-implement write `RUN_DIR/rulings.md`

**Status:** TODO

Spec Step 2.1 — K-L8. Files: `plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`.

- **task-review Step 5**, before the code-fixer dispatch and outside every
  `canonical:` block: a ruling on the reviewers' findings given after they
  returned and before code-fixer is dispatched — the user's reply in an
  interactive run, or an autopilot main session's answer to the worker
  running the review — is written by the orchestrating skill to
  `RUN_DIR/rulings.md` before the dispatch. The file: a first line naming
  who ruled, then one entry per ruling:
  `- <ID>[, <ID>…]: FIX — <what to do>`, `- <ID>[, <ID>…]: DEFER — <reason>`,
  or `- <ID>[, <ID>…]: NOT APPLICABLE — <reason>` (any grammar beyond this
  is the implementer's). The CONTEXT block passes unchanged, and a ruling
  never goes into `CUSTOM_INSTRUCTIONS`. No ruling, no file, and nothing
  changes. The five reviewers do not read it. Why: a narrowed review once
  wrote a ruling into the `CUSTOM_INSTRUCTIONS` of code-fixer and
  regression-verifier, breaking the rule that both get the reviewers'
  CONTEXT unchanged; the run directory is the one path the orchestrator
  already passes, so no key is added.
- **task-implement Phase 2 Step 3**, before its code-fixer dispatch and
  outside every `canonical:` block: the same, stated in full or pointing at
  task-review's statement, naming `rulings.md` either way.
- **Schema F** (task-review Step 7) and **Schema G** (task-implement
  Phase 2 Step 4): when `RUN_DIR/rulings.md` exists, the report names the
  file and who ruled.

**Acceptance criteria:**
- `bash scripts/check-canonical-dispatch.sh`,
  `bash scripts/check-verdict-shared.sh`, and
  `bash scripts/check-run-contract.sh` exit 0.
- Each file names `rulings.md` and says when it is written, by whom, that
  the CONTEXT stays unchanged, and that a ruling never goes into
  `CUSTOM_INSTRUCTIONS`; task-review states the entry grammar and the
  absent-file rule; Schema F and Schema G mention the file when it exists.
- `bash scripts/check-all.sh` exits 0.

---

### Task 10: code-fixer and regression-verifier read `rulings.md`

**Status:** TODO

Spec Step 2.2 — K-L8. Files: `plugins/kenspc/agents/code-fixer.md`,
`plugins/kenspc/agents/regression-verifier.md`.

- **code-fixer**:
  - INPUTS (and the RUN_DIR bullet where it lists the directory's files):
    `RUN_DIR/rulings.md` when it exists, its first line naming who ruled,
    then one entry per ruling in the grammar of Task 9.
  - FIXING PRIORITY or FIXING RULES: a ruled ID takes the ruling's action
    over FIXING PRIORITY; a FIX ruling's text bounds the fix, and a file it
    names is in that fix's scope; a DEFER or NOT APPLICABLE ruling's reason
    is the row's reason, and a DEFERRED row still gets its Deferred Issues
    paragraph.
  - PER-ISSUE OUTPUT CONTRACT, the action field: a ruled row's Action cell
    keeps its leading word and carries `ruled` after the em-dash, joined to
    any other suffix by `; ` as today, so the statistics recount is
    unchanged.
  - The reply: an ID a ruling names that no report lists is named in it.
  - The PREREQUISITE CHECK is unchanged (the file is optional); the
    stats-line and code-craft blocks are unchanged.
- **regression-verifier**:
  - INPUTS: `rulings.md` when it exists.
  - VERIFICATION CHECKS item 1: each ruled ID sits in a row whose action's
    leading word matches its ruling (FIX → FIXED, DEFER → DEFERRED,
    NOT APPLICABLE → NOT APPLICABLE), and a ruled ID no report lists is a
    bookkeeping error, reported in row 1 with the IDs.
  - Item 2: a FIX-ruled row is checked against the ruling's text as well as
    the report.
- Each rule with its Why. The worked Schema B example still recounts; if a
  ruled row is added to it, its Per-angle Results table and statistics line
  change to match.

**Acceptance criteria:**
- `bash scripts/check-run-contract.sh` and
  `bash scripts/check-code-craft-canonical.sh` exit 0.
- code-fixer states the input, the precedence over FIXING PRIORITY, the FIX
  bound and its file scope, the `ruled` marker after the em-dash with the
  leading word kept, and the reply line for an unlisted ruled ID.
- regression-verifier states the input and the item 1 and item 2 rules.
- Both files name `rulings.md`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 11: `check-run-contract.sh` check 5 names `rulings.md`

**Status:** TODO

Depends on: Task 9, Task 10

Spec Step 2.3 — K-L8. File: `scripts/check-run-contract.sh`.

- Check 5 also requires the literal `rulings.md` in
  `skills/task-review/SKILL.md`, `skills/task-implement/SKILL.md`,
  `agents/code-fixer.md`, and `agents/regression-verifier.md`, each file
  that does not name it reported (exit 1).
- The header comment: check 5's paragraph (who writes the file and who
  reads it), the exit-code 1 line, and the `--self-test` paragraph with the
  new mutation count.
- The self-test: the fixture-stale guard confirms each of the four copies
  names `rulings.md` (exit 2 if not); one mutation per carrier removes every
  occurrence through the replace-all helper and must exit 1; the restoration
  path still exits 0.
- bash 3.2, no associative arrays, no `sed -i`, as the guard already does.

**Acceptance criteria:**
- `bash scripts/check-run-contract.sh` exits 0.
- `bash scripts/check-run-contract.sh --self-test` exits 0, and its four new
  mutations each exit 1 inside it, one per carrier.
- `bash scripts/check-all.sh --self-test` exits 0 and ends with
  `self-tests run: 11`.

---

### Task 12: `check-autopilot-rails-hook.sh` — the heading guard

**Status:** TODO

Depends on: Task 8

Spec Step 3.1 — K-L13; K-C4. File: `scripts/check-autopilot-rails-hook.sh`.

- **Main mode**, beside the registration check: the literal
  `## Rail observations` occurs in the hook's unreadable-field reason (the
  `REASON_UNREADABLE=` assignment in
  `hooks/scripts/autopilot-worker-rails.sh`), in the preamble template of
  `skills/autopilot/SKILL.md` (the fenced block under `### The preamble`),
  and in its § Launch, wait, return (from `### Launch, wait, return` to the
  next `### ` heading); and the phrase `could not be read from the hook input`
  occurs in the hook and in `skills/autopilot/SKILL.md`. A missing literal
  is reported per carrier (exit 1); a missing SKILL.md, or a section or block
  the guard cannot find, is exit 2.
- **The header comment** describes the new check and its mutants.
- **The self-test** copies SKILL.md beside its copy of the hook and adds one
  mutant per carrier — the heading dropped from each of its three carriers,
  the phrase dropped from the hook and from SKILL.md — each of which must
  turn the new check red, named in the output; a mutation whose target is
  not found is exit 2; the restored copies pass again. The existing five
  mutants and every fixture stay. Temporary files are removed one by one,
  never with a recursive `rm`.

**Acceptance criteria:**
- `bash scripts/check-autopilot-rails-hook.sh` exits 0.
- `bash scripts/check-autopilot-rails-hook.sh --self-test` exits 0, and its
  output names one red result per new mutant, five in all, each naming its
  carrier.
- `git diff 8db589b -- plugins/kenspc/hooks/hooks.json plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh`
  prints nothing (Task 14's edit of the telemetry hook, in the same
  directory, is outside this check).
- `bash scripts/check-all.sh --self-test` exits 0 with `guards run: 12`
  and `self-tests run: 11`.

---

### Task 13: task-implement — a document with no incomplete task

**Status:** TODO

Spec Step 3.2 — K-L14. File: `plugins/kenspc/skills/task-implement/SKILL.md`.

- **Phase 1 Step 3**: a task document with no TODO or IN PROGRESS task — the
  reply gives the counts of DONE and BLOCKED tasks, asks nothing, prepares
  no run directory, dispatches nothing, runs no review, renders no Schema G,
  and names `/kenspc-task-review <path>` for a review of the finished work;
  the run ends there. Why, in the skill's own words: a session given a
  document whose every task was DONE stopped before its batch gate and
  prepared no run directory, which nothing in the skill said to do; a gate
  with nothing to implement asks a question whose answer changes nothing,
  and a review of finished work is task-review's.
- Phase 1's DONE list and Phase 2's opening cases agree with the branch.
- Every text change sits outside the `canonical:` blocks.

**Acceptance criteria:**
- Phase 1 Step 3 states the branch with each of the seven points above and
  its Why.
- Phase 1's DONE list and Phase 2's opening cases do not contradict the
  branch.
- `bash scripts/check-all.sh` exits 0.

---

### Task 14: the telemetry hook's transcript root

**Status:** TODO

Spec Step 3.3 — K-L15. File:
`plugins/kenspc/hooks/scripts/session-end-telemetry.sh`.

- The hook looks for the session's transcript under
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects`; its log stays at
  `$HOME/.claude/kenspc/missed-reviews.log`. The header comment names the
  root and why: Claude Code keeps its transcripts under `CLAUDE_CONFIG_DIR`
  when it is set, so a lookup under `$HOME/.claude` alone finds none and the
  hook records nothing. It still never blocks and never prints.
- **The probe**, in a new directory under `$TMPDIR` per attempt, with `HOME`
  pointed at a directory there and `CLAUDE_CODE_SESSION_ID` a made-up id,
  the hook run with `bash`:
  1. `CLAUDE_CONFIG_DIR` set to a directory under the probe directory that
     holds `projects/<any>/<id>.jsonl` with a line matching the hook's
     implement pattern and none matching a review: the log under the probe's
     `HOME` holds one record;
  2. `CLAUDE_CONFIG_DIR` unset, the transcript under
     `<probe HOME>/.claude/projects/<any>/<id>.jsonl`: one record, as before;
  3. negative control: `CLAUDE_CONFIG_DIR` set while the transcript lies
     only under `<probe HOME>/.claude/projects`: no record;
  4. the hook as it stood at `8db589b`
     (`git show 8db589b:plugins/kenspc/hooks/scripts/session-end-telemetry.sh`,
     saved under the probe directory) on case 1: no record, so the probe
     can fail.
  The user's real `HOME` and log are never written.

**Acceptance criteria:**
- `bash -n plugins/kenspc/hooks/scripts/session-end-telemetry.sh` exits 0.
- The four probe cases give the results above; their commands and output are
  in this task's Implementation notes.
- The log path is unchanged: the diff changes no line that sets `LOG_DIR` or
  `LOG_FILE`.
- `bash scripts/check-all.sh` exits 0.

---

### Task 15: Doc-sync

**Status:** TODO

Depends on: Task 1-14

Bring the documents below in line with what Tasks 1-14 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § Autopilot — the two gates and the main
  session's rulings: who rules and how, S2's confirmation and the post-check
  that resumes S2, a corrected acceptance case, and the record (the state
  file's `questions answered:` line, the clarifications, the reviewer
  report's `Main-session rulings` and `Follow-up candidates` lines, the user
  report's rulings list); the stops, 7 narrowed and 11 new; Phase 0's
  inbound read from the settings files and a label with a note; the rails
  additions (Steps 1.1, 1.2, 1.3).
- `plugins/kenspc/README.md` § Run directory — `rulings.md`: who writes it
  and when, its entries, how code-fixer and regression-verifier read it, and
  that the CONTEXT stays unchanged (Steps 2.1, 2.2).
- `plugins/kenspc/README.md`, where it describes `/kenspc-task-implement` —
  its behavior with no incomplete task (Step 3.2).
- `plugins/kenspc/README.md` § Known behavior — a main-session ruling can be
  wrong, and the user reviews each one from the reports before the tag and
  the push; the inbound check cannot read settings delivered from a server
  (Steps 1.1, 1.2).
- `CLAUDE.md` § Subagent Review Architecture, the CONTEXT block contract —
  `rulings.md` beside `change-set.md`: written by the orchestrating skill
  before code-fixer's dispatch when a ruling exists, read by code-fixer and
  regression-verifier, no key added, never `CUSTOM_INSTRUCTIONS`
  (Steps 2.1, 2.2).
- `CLAUDE.md` § Repository scripts/ — `check-run-contract.sh`'s check 5
  names `rulings.md` in its four carriers (Step 2.3), and
  `check-autopilot-rails-hook.sh`'s new main-mode check and its self-test
  mutants (Step 3.1); the hooks paragraph under § Skill Development
  Conventions only if it names the telemetry root, which at `8db589b` it
  does not (Step 3.3).
- `plugins/kenspc/CHANGELOG.md` — a `## 4.5.0 — unreleased` entry above
  4.4.1: what the batch changed, and the guard counts, unchanged at
  `guards run: 12` and `self-tests run: 11` (Steps 1.1-3.3).
- `docs/release-checklist.md` row 11 — its sentence "the answer taken from
  the spec and none given on the user's behalf" follows the main session's
  rulings and the record (the answer given by the main session and recorded
  with who ruled); the counts stay `guards run: 12` and
  `self-tests run: 11` (Step 1.1).
- `docs/roadmap.md` — remove item 20 (task-implement's missing branch) and
  item 17's telemetry bullet; from item 21 remove the unreadable-field stop
  (keep its caveat wording on denials inside agents without rails text) and
  the heading bullet, and add to its line-continuation bullet the
  alternative of joining backslash-newline before the scan, as bash does;
  add two items: acceptance commands a plan writes are never dry-run at the
  baseline (the four broken commands of the spec's Background), and a
  narrowed review's own code-fixer can make an incomplete fix that fails
  that review and costs another S5 and narrowed review; renumber the rest
  (Steps 1.3, 3.1, 3.2, 3.3).
- `README.md` (root) — unchanged unless a skill's summary row changes;
  "two human gates" still holds (Step 1.1).

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-14. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-14 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
- `bash scripts/check-all.sh` and `bash scripts/check-all.sh --self-test`
  exit 0 with `guards run: 12` and `self-tests run: 11`, and the counts in
  CLAUDE.md and the release checklist equal those lines.
- `git grep -nE 'K-[LDC][0-9]' -- plugins scripts CLAUDE.md README.md docs/release-checklist.md docs/roadmap.md`
  prints nothing (positive control: the same pattern over
  `docs/plans/batch-k-autopilot-rulings.md` prints lines).
