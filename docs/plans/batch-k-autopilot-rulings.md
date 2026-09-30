# Batch K — autopilot rulings (4.5.0)

## Objective

Let an autopilot batch run from its spec to its release preparation
without waiting on the user between its two gates. The main session rules
every point the spec leaves open, except a short list that stays the
user's — the stop conditions — and records each ruling where the user
reviews it before the tag and the push. A ruling on a review's findings
reaches code-fixer and regression-verifier through the run directory,
never through `CUSTOM_INSTRUCTIONS`. Phase 0 stops asking the two
questions every recent batch asked. Four small rails items and two small
fixes from the roadmap ride along.

## Background

- **The questions.** Three repo-mode batches in a product repository
  (2026-09-29 and 2026-09-30, main sessions in the Claude Code VS Code
  extension, installed plugin 4.4.0 and 4.4.1) asked the user 25
  questions. The user chose the main session's own recommended option 24
  times; the 25th was a preference about the wait mode. By kind:
  - Phase 0, the launch line carries no `crossSessionInbound` accept: 3,
    identical each time. The main session had already read
    `~/.claude/settings.json` (`"crossSessionInbound": "accept"`) and found
    no project or managed override; the rule made it ask anyway.
  - Phase 0, the spec wrote its acceptance field as
    `Acceptance (in the order listed, …):`: 2. Read strictly, an unknown
    label is ignored, which would have run the batch with no acceptance.
  - S2's confirmation carried two choices the spec left open
    (`[AllowAnonymous]` on a health controller, an exported client's
    name): 2.
  - An acceptance command broken for a reason outside the batch's work: 4
    — pnpm reading a flag meant for the test runner; a `Failed` grep
    matching an application log line; a per-assembly summary line the
    installed .NET SDK does not print, so the command failed at the
    pre-batch commit; a check that passed vacuously because the clone was
    never restored. Each time the main session verified a corrected form
    (the green log passing, failing variants failing) before asking.
  - How to handle review findings: 8 — a spec sentence shown false by two
    reviewers, a missing connection rule, which test gaps to fill, a
    deferral forced by a locked point, one comment line.
  - Trivia: 2 — a CHANGELOG date, which note a sentence goes in.
  - Which acceptance list S4 runs after a worker edited it: 2, settled by
    4.4.1 (the section is fixed at Phase 0).
  - Only the user could answer: 2 — whether another session was working
    in the same repository, and the wait-mode preference.
- **What the waits cost.** In one batch S2 waited 36 minutes and S3 95
  minutes for the user; both passed the worker's thirty-minute wait, ended
  with the question, and were resumed. In another, six rounds of questions
  kept the user at the session for two and a half hours. In the third, one
  question held the run overnight (fixed in 4.4.1).
- **Why the skill asked.** Three rules send every point the spec's words
  do not settle to the user: the Quality bar names "a run that approves a
  worker's question on the user's behalf" as a failure; the confirmation
  rubric sends a type, shape, name, or behavior a worker proposes to pin
  to the user unless the spec's words rule out every other option; and
  stop condition 7 stops on "a question neither the spec nor the locked
  design answers". They contradict the skill's own description (it stops
  "only for the rulings on a brief's design table and for the tag, push,
  and release") and its decision hierarchy ("clarifications during
  implementation (the main session; recorded in the spec and
  committed)"). A real spec never settles every name and detail, so in
  practice the three rules make an open-ended third gate.
- **Why the rubric was written that way.** In batch F's acceptance, one
  unstated point went to the user in one run and was confirmed by the
  main session in another, depending only on how the worker framed it.
  Sending every such choice to the user removed the framing question;
  sending every such choice to the main session removes it the same way.
- **Why the release gate is enough.** The proposer and the ruler are
  already different sessions (the worker proposes, the main session
  rules). Every ruling is committed as a clarification in the spec. The
  tag, the push, and the release stay the user's, after the reports, so a
  ruling is seen before anything leaves the machine — not "at the
  release", after it.
- **Rulings into a running review.** A worker running task-implement or
  task-review asked the main session how to rule on its reviewers'
  findings before code-fixer ran. The answer had no route to code-fixer:
  one narrowed review wrote the ruling into the `CUSTOM_INSTRUCTIONS` of
  code-fixer and regression-verifier, breaking task-review's rule that
  both get the reviewers' CONTEXT unchanged. With the main session ruling
  more points, this route is needed more often.
- **Roadmap and follow-ups this batch takes.** Item 20 (task-implement has
  no branch for a document with no incomplete task); item 17's telemetry
  bullet (the SessionEnd hook reads transcripts only under
  `$HOME/.claude/projects`, while the autopilot's lookups honour
  `CLAUDE_CONFIG_DIR`); two parts of item 21 (a worker's end on an
  unreadable-field denial as a main-session stop of its own; no guard ties
  the `## Rail observations` heading across the hook, the preamble, and
  the return). Three rails items from the maintainer's review of 4.3.0: a
  script an agent writes and then runs is its own writing; reaching a
  denied effect by another spelling is a breach; a worker that lists its
  environment prints names only — batch J's acceptance worker printed the
  machine's local messaging-socket token from an `env` listing whose
  redaction pattern missed it.

## Locked design

Immutable for this batch.

- **K-L1 — the main session rules.** Every point the spec leaves open is
  the main session's to rule: a worker's question, a choice riding on a
  task-list confirmation, a question the main session raises itself, a
  review row's or an acceptance FAIL's classification (already its own),
  a deferred row's route, a corrected acceptance case. It answers a
  waiting worker at once, in the `answer <tag>:` form. It asks the user
  only on a stop condition (K-L2) and at the two gates. Its ruling is the
  same whether or not the session can ask. The Quality bar's named failure
  "a run that approves a worker's question on the user's behalf" is
  replaced by two: a run that rules itself on a point a stop condition
  gives the user, and a ruling missing from the record (K-L7). A worker
  still never rules itself: it asks the main session, since the main
  session records every answer and an answer a worker invents is recorded
  nowhere.
- **K-L2 — the stop conditions are the user's list.** Stop conditions 1–6
  and 8–10 stay as they stand. Stop condition 7 becomes: a way forward
  the main session cannot rule on — (a) every option changes the batch's
  contract, and none stays inside it: a new dependency, an API contract
  change, a database schema or configuration change the spec does not
  name, a change to a file outside `Allowed files:` or on the zero-diff
  list; or (b) an acceptance case corrected without both pieces of
  K-L5's evidence. When one option stays inside the contract — defer to a
  follow-up, leave as is — the main session takes it and records it; the
  question is not asked. Reopening a locked point stays stop 1, and a
  ruling "leave the locked point as it stands and record the finding as a
  follow-up" is the main session's, not a stop. A new stop condition 11
  (K-L12). "A question only a later step needs" keeps its text and
  applies to stop 7's narrowed kind. Outward actions a run does not need
  in order to continue — filing an issue, a backlog item — are never
  taken and never asked mid-run: the reviewer report lists them as
  follow-up candidates for the user.
- **K-L3 — how the main session rules.** In this order: the spec's words;
  the locked design; the project's instruction files and the patterns in
  adjacent code; then the option that is easiest to reverse and closest
  to the spec's scope. A worker's suggested answer is evidence, not a
  default. The main session never stops for a preference between options
  that all stay inside the contract; it picks by this order and records
  why.
- **K-L4 — departing from the spec's letter.** A ruling may depart from
  a sentence of the spec (not a locked point) when evidence shows the
  sentence wrong — a test, a probe, a reviewer's reproduction, a
  documented tool behavior — and the clarification names the evidence.
  Every such ruling goes on the reviewer report's existing
  `beyond the letter` list.
- **K-L5 — a corrected acceptance case.** The main session may rule a
  corrected form of an `Acceptance:` case when it has both: (1) evidence
  that the case as written fails, or passes vacuously, for a reason
  outside the batch's work — shown at the baseline, or a named tool
  behavior verified by running it; and (2) a negative control — the
  corrected form fails on a deliberate break of what the case checks, and
  the output is recorded. The ruling is a clarification carrying the
  case, the corrected form, and both pieces of evidence (paths or quoted
  output). S4's task block runs the corrected form and names the
  clarification; the reviewer report's acceptance line says
  `in the corrected form (<clarification>)`. The `## Autopilot` section
  stays as Phase 0 read it: a correction is a ruling, not a settings
  edit. Without both pieces of evidence it is stop 7 (b).
- **K-L6 — S2's confirmation and the post-check.** The confirmation is
  answered `yes` when the task list matches the spec's steps. A step
  without a task is answered "add a task for <step>"; a task outside the
  spec is answered "drop <task>", unless a spec step needs it, which the
  main session rules and records. A choice riding on the confirmation is
  ruled by the main session and recorded, however the worker frames it.
  The skipped-gate post-check keeps its trigger and its rubric; a
  mismatch or an open choice whose ruling differs from the committed task
  document resumes S2 under `<tag>-r<k>` with the ruling as the answer, to
  amend and commit the document, and the post-check runs again on it; a
  second failure is a stop. A match, or rulings the document already
  follows, is accepted and recorded as today.
- **K-L7 — the record.** Every ruling is recorded four ways:
  - the state file's `questions answered:` line gains who ruled:
    `<tag>: <one line> → <one line> (main session|user)`;
  - its clarification entry in the spec names who ruled;
  - the reviewer report gains a line after
    `Design rulings and clarifications`:
    `- Main-session rulings: <n> | none`, followed by one indented line per
    ruling — its clarification, the tag or step, the question, the
    ruling, the reason, and the commits it produced;
  - the user report lists the same rulings, one line each in the user's
    language, under a heading that says they are for the user to review
    before the tag and the push. The user report's one-page limit does not
    count this list.
- **K-L8 — rulings into a running review.** A ruling on a review's
  findings, given after the reviewers returned and before code-fixer is
  dispatched — the user's reply in an interactive run, or an autopilot
  main session's answer to the worker running the review — is written by
  the orchestrating skill to `RUN_DIR/rulings.md` before the code-fixer
  dispatch. The CONTEXT block passes unchanged; a ruling never goes into
  `CUSTOM_INSTRUCTIONS`. Absent file, nothing changes. The file: a first
  line naming who ruled, then one entry per ruling:
  `- <ID>[, <ID>…]: FIX — <what to do>`, `DEFER — <reason>`, or
  `NOT APPLICABLE — <reason>`.
  - code-fixer reads `RUN_DIR/rulings.md` when it exists. A ruled ID takes
    the ruling's action over FIXING PRIORITY; a FIX ruling's text bounds
    the fix, and a file it names is in that fix's scope. The row's Action
    cell keeps its leading word and carries `ruled` after the em-dash, so
    the statistics recount is unchanged. An ID a ruling names that no
    report lists is named in code-fixer's reply.
  - regression-verifier reads it when it exists. Row 1: each ruled ID sits
    in a row whose action's leading word matches its ruling (FIX → FIXED,
    DEFER → DEFERRED, NOT APPLICABLE → NOT APPLICABLE), and a ruled ID no
    report lists is a bookkeeping error. Row 2: a FIX-ruled row is checked
    against the ruling's text as well as the report.
  - task-review (Step 5) and task-implement (Phase 2 Step 3) say when the
    file is written, by whom, and that the CONTEXT stays unchanged. The
    five reviewers do not read it and stay unchanged. The canonical blocks
    stay byte-identical and unchanged.
  - The autopilot preamble tells a worker to put an answer that rules on
    its review's findings into that run's `RUN_DIR/rulings.md`, never into
    an agent's `CUSTOM_INSTRUCTIONS`.
  - `check-run-contract.sh` check 5 requires the literal `rulings.md` in
    `task-review/SKILL.md`, `task-implement/SKILL.md`, `code-fixer.md`, and
    `regression-verifier.md`, and its self-test turns red when any one of
    them drops it.
- **K-L9 — Phase 0: inbound from the settings files.** When the launch
  line carries no `crossSessionInbound` accept, the main session reads the
  value from the settings files Claude Code reads it from — managed
  settings, user settings (`$CLAUDE_CONFIG_DIR/settings.json`, else
  `~/.claude/settings.json`), the project's `.claude/settings.json` and
  `.claude/settings.local.json` — with the precedence § The message
  protocol already states. An absent file sets nothing. Effective value
  `accept`: the run goes on, and the state file records the file and line
  the value came from. `hold` or `refuse`: the stop naming the launch
  line. A file that exists and cannot be read or parsed, or a source the
  main session cannot read (settings delivered from a server): the
  question as today, and in a session that cannot ask, the run ends
  naming the launch line. The managed-settings path per platform is taken
  from Claude Code's settings documentation at implementation time and
  cited in the Why. The delivery-notice stop stays the backstop.
- **K-L10 — Phase 0: a label with a note.** In the `## Autopilot` section,
  `- <Label> (<note>):` is read as `- <Label>:` for a known label. The
  note is carried with the field: for `Acceptance:`, as a run-notes line
  in both S4 task blocks; for any other field, named on the line after the
  settings line. An unknown label with a note stays unknown.
- **K-L11 — the preamble.** § 1: the sentence "Do not approve anything
  on the user's behalf …" becomes a rule against deciding a question
  yourself, with the reason in K-L1; the rulings-file sentence of K-L8.
  § 3, three additions:
  - a script or program the agent writes during the run and then runs —
    a helper in scratch, `$TMPDIR`, or the workspace — is its own writing,
    and a recursive delete in it is a breach as if typed; code the batch
    implements and its tests, run as the project runs them, stay a
    program the agent runs;
  - reaching an effect the rails hook denied by another spelling — another
    command, another tool, a script — is a breach;
  - listing environment variables prints names only, never values.
  The existing sentence that a program's own `mktemp` cleanup or cache is
  not a breach stays, read with the first addition.
- **K-L12 — stop condition 11.** At a worker's return, a
  `## Rail observations` entry that carries a denial whose reason says a
  field of the hook input could not be read is stop 11, naming the field
  and the output of `claude --version` in the main session's Bash. Why:
  the hook no longer reads the harness's input format, so every later
  worker would end the same way. The hook's reason text is the one it
  prints today; the hook is not edited.
- **K-L13 — the heading guard.** `check-autopilot-rails-hook.sh`'s main
  mode also checks that the literal `## Rail observations` occurs in the
  hook's unreadable-field reason, in the preamble template of the
  autopilot `SKILL.md`, and in its § Launch, wait, return; and that the
  phrase the hook uses for an unreadable field and the phrase stop 11
  matches on are the same literal in the hook and in `SKILL.md`. Its
  self-test turns red when any carrier drops its literal.
- **K-L14 — task-implement with no incomplete task.** In Phase 1 Step 3,
  a task document with no TODO or IN PROGRESS task: the reply gives the
  counts of DONE and BLOCKED tasks, asks nothing, prepares no run
  directory, dispatches nothing, runs no review, renders no Schema G, and
  names `/kenspc-task-review <path>` for a review of the finished work.
- **K-L15 — the telemetry root.** `session-end-telemetry.sh` looks for
  transcripts under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects`. Its
  log stays at `$HOME/.claude/kenspc/missed-reviews.log`.
- **K-L16 — unchanged.** No model name and no per-role default in any
  plugin file. The drivers (`run.sh`, `run.ps1`), the rails hook script,
  `hooks.json`, and the five reviewers are not edited. Brief entry's
  design table stays the user's gate, unchanged.

## Design decisions

Status: ruled

| Question | Ruling | Rejected, and why |
|---|---|---|
| K-D1 Who rules the points the spec leaves open | K-L1, K-L2 | A `## Autopilot` field choosing main session or user per spec: one more setting, and 24 of 25 answers show which way it would be set; fixing only the Phase 0 questions: leaves every mid-run interruption |
| K-D2 Which points stay the user's | K-L2 | Also stopping for a departure from the spec's letter: one to three more questions per batch, each answered with the main session's evidence-backed recommendation |
| K-D3 A ruling on review findings | K-L8 | Rulings in `CUSTOM_INSTRUCTIONS`: breaks the unchanged-CONTEXT rule; rulings only in the verdict loop after the step: every one costs an S5 and a narrowed review |
| K-D4 The acceptance label with run notes | K-L10 | A stricter error: the note carried the case's run conditions, and dropping the field ran no acceptance |
| K-D5 Line-continuation spellings in the rails hook | Out of scope | Every review round of the hook's scanner in 4.3.0 found a new edge case; bundled here it would bound this batch by the scanner |
| K-D6 How this change is accepted | In use, by the next product batch | A seeded acceptance now: USD 20–40 for two cases the next real batch exercises anyway |

## Implementation Steps

### Phase 1: The autopilot skill

#### Step 1.1: The rulings (`plugins/kenspc/skills/autopilot/SKILL.md`)

K-L1 to K-L7 in the Quality bar, § A worker's question at a gate (the
confirmation and the skipped-gate post-check), a new subsection stating
how the main session rules (K-L3, K-L4), Phase 3 (K-L5), the stop
conditions, § A question only a later step needs, the decision hierarchy,
the state file template, the reviewer report template and its prose, the
user report (Phase 4), and the gates table. Every point where the skill
still asks keeps the opening "In a session that cannot ask (a system
reminder to work without stopping), …" sentence (CLAUDE.md's Writing
Rules).

DONE: each of K-L1 to K-L7 has its text; no sentence left in `SKILL.md`
sends a point outside the stop conditions to the user; the gates table
agrees with the prose.

#### Step 1.2: Phase 0

K-L9 in § The start checks and the state file; K-L10 in § The
`## Autopilot` section and both S4 task blocks.

DONE: both points have their text; the two spec labels quoted in the
Background read as `Acceptance:` under the new rule.

#### Step 1.3: The preamble and stop 11

K-L11 in the preamble's § 1 and § 3, with their Why paragraphs below the
template; K-L8's preamble sentence; K-L12 in § Launch, wait, return and
the stop conditions.

DONE: each point has its text; the preamble stays self-contained (no
"as an earlier batch did").

### Phase 2: The review path

#### Step 2.1: Where `rulings.md` is written

K-L8 in `task-review/SKILL.md` Step 5 and `task-implement/SKILL.md` Phase 2
Step 3, outside the canonical blocks, and a mention in each final report
(Schema F, Schema G) when the file exists.

DONE: `bash scripts/check-canonical-dispatch.sh`,
`bash scripts/check-verdict-shared.sh`, and
`bash scripts/check-run-contract.sh` exit 0.

#### Step 2.2: code-fixer and regression-verifier

K-L8 in `agents/code-fixer.md` (INPUTS, FIXING PRIORITY or FIXING RULES,
the Action cell) and `agents/regression-verifier.md` (INPUTS, checks 1
and 2). The worked Schema B example in `code-fixer.md` still recounts.

DONE: `bash scripts/check-run-contract.sh` and
`bash scripts/check-code-craft-canonical.sh` exit 0.

#### Step 2.3: The guard

K-L8's check 5 in `scripts/check-run-contract.sh`, with its header comment
and its self-test.

DONE: `bash scripts/check-run-contract.sh --self-test` exits 0, and a
mutation that drops `rulings.md` from any one carrier turns it red.

### Phase 3: Small fixes

#### Step 3.1: The heading guard

K-L13 in `scripts/check-autopilot-rails-hook.sh` main mode, header, and
self-test.

DONE: the guard and its `--self-test` exit 0; each carrier's mutation
turns the self-test red.

#### Step 3.2: task-implement with no incomplete task

K-L14 in `task-implement/SKILL.md` Phase 1 Step 3.

DONE: the branch has its text and its Why.

#### Step 3.3: The telemetry root

K-L15 in `hooks/scripts/session-end-telemetry.sh` and its header comment.

DONE: a probe with `CLAUDE_CONFIG_DIR` set to a directory under
`$TMPDIR` that holds a transcript matching the hook's implement pattern
writes one record, and with the variable unset the hook looks under
`$HOME/.claude/projects` as before; the probe's commands and output go in
the task's notes. The probe writes the log under a `HOME` pointed at
`$TMPDIR`, never the user's real log.

### Phase 4: Documentation

#### Step 4.1: The durable documents

As Documentation impact lists. The CHANGELOG entry is headed
`## 4.5.0 — unreleased`.

DONE: `bash scripts/check-all.sh` and
`bash scripts/check-all.sh --self-test` exit 0 with `guards run: 12` and
`self-tests run: 11`; the Constraints' pointer grep prints nothing.

## Documentation impact

- `plugins/kenspc/README.md`: the Autopilot section — the two gates and
  the main session's rulings (K-L1 to K-L7), stops (7 narrowed, 11 new),
  Phase 0 (K-L9, K-L10), the rails additions (K-L11); the run-directory
  section — `rulings.md` (K-L8); task-implement's behavior with no
  incomplete task (K-L14); Known behavior — a main-session ruling can be
  wrong and is reviewed from the reports before the tag and the push, and
  K-L9 cannot read settings delivered from a server.
- `CLAUDE.md`: the CONTEXT block contract section — `rulings.md` beside
  `change-set.md`; the descriptions of `check-run-contract.sh` (check 5)
  and `check-autopilot-rails-hook.sh` (the new main-mode check and its
  self-test mutants); the hooks paragraph if it names the telemetry root.
- `plugins/kenspc/CHANGELOG.md`: `## 4.5.0 — unreleased`.
- `docs/release-checklist.md`: row 11's sentence "the answer taken from
  the spec and none given on the user's behalf" follows K-L1 and K-L7; the
  counts stay `guards run: 12` and `self-tests run: 11`.
- `docs/roadmap.md`:
  - remove item 20, and item 17's telemetry bullet;
  - from item 21, remove the unreadable-field stop (keep the caveat
    wording on denials inside agents without rails text) and the heading
    bullet; add to its line-continuation bullet the alternative of joining
    backslash-newline before the scan, as bash does;
  - add two items: acceptance commands a plan writes are never dry-run at
    the baseline (the four broken commands of the Background); a narrowed
    review's own code-fixer can make an incomplete fix that fails that
    review and costs another S5 and narrowed review.
- `README.md` (root): unchanged unless a skill's summary changes; "two
  human gates" still holds.

## Testing Strategy

The guards and their self-tests (Phase 4's DONE), the telemetry probe
(Step 3.3), and S3b's review of the batch's range, which reads each K-L
point against the text. No seeded acceptance (K-D6): the change is
accepted in use by the next product-repository batch, whose reviewer
report shows the `Main-session rulings` line and how many questions
reached the user.

## Risks and Mitigations

- **A main-session ruling is wrong.** Each one is a committed
  clarification and a reviewer-report line the user reads before the tag
  and the push; the contract and the lock stay the user's (K-L2).
- **K-L3 read as licence to widen the scope.** A way forward that only
  exists outside the contract is stop 7 (a); the order in K-L3 ends on
  the option closest to the spec's scope.
- **An acceptance check loosened to pass.** K-L5 needs a negative
  control, and a correction without it stops.
- **K-L9 misreads a setting.** The first message's delivery notice still
  stops the run; a source it cannot read is asked about.
- **This batch runs the installed 4.4.1 skill**, whose rules predate
  K-L1. The Constraints' rulings for this run cover the gap.
- **Rulings in a review a user runs by hand.** The file is written only
  when a ruling exists; a plain review writes none and nothing changes.

## Open Questions

None open. A question during implementation goes to the main session by
message.

## Out of scope

- The rails hook's line-continuation spellings (K-D5), its awk failure
  reasons, and the caveat wording on denials inside agents without rails
  text (roadmap item 21).
- `run.ps1` on Windows and the Windows rails hook (items 11, 18).
- The model check's misreadings and the unexercised paths of item 17.
- A dry-run of a plan's acceptance commands at the baseline, and a
  narrowed review's incomplete fix (new roadmap items, Documentation
  impact).
- The telemetry log's location.
- The skill's description frontmatter.
- Brief entry's design table.

## Constraints

- **Language.** Every file this batch writes is English.
- **Rulings for this run (the user's).** This batch runs the installed
  4.4.1 autopilot, whose rules predate K-L1. For this run:
  1. Every point this spec leaves open — a worker's question, a choice
     riding on a task-list confirmation, a review row's or deferred row's
     classification, a corrected check — is the main session's to rule,
     applying K-L3 and K-L4 now. This delegation is this spec's answer to
     every such point. The main session records each ruling as a
     clarification marked `(ruled by the main session)` and lists them in
     both reports.
  2. Only these go to the user: reopening a locked point; a way forward
     that exists only by changing a Zero diff path or a file outside
     Allowed files; the budget or a cap; and the installed skill's other
     stop conditions except the unanswered-question one.
  3. S3b's DEFERRED LOW rows go to roadmap candidates listed in the
     reviewer report, not to an S5, unless the fix is one line in an
     allowed file; a DEFERRED MEDIUM or HIGH row goes to an S5.
- **Delegated choices.** The spec pins the names it states:
  `rulings.md`, its three actions, `Main-session rulings`, stop condition
  11, the `ruled` marker in the Action cell, and the batch's labels.
  Everything else of that kind is the implementer's: the wording within
  each K-L point, where a new subsection sits, the entry grammar of
  `rulings.md` beyond K-L8, the guards' internal structure and fixture
  layout, the split into tasks and commits within the steps, and the
  documentation wording within Documentation impact. A worker's proposal
  on any of these is answered "yes, as proposed".
- **Writing rules.** CLAUDE.md's Writing Rules for Skill Content: every
  rule carries its Why as prose; evidence is stated in its own words, not
  cited as a dry-run record or a product repository's name; every point
  where a skill still asks opens its no-ask branch with "In a session that
  cannot ask (a system reminder to work without stopping), …".
- **Pointer rule.** The spec's labels (`K-L<n>`, `K-D<n>`, `K-C<n>`) are
  pointers for the implementer and appear in no shipped file.
  `git grep -nE 'K-[LDC][0-9]' -- plugins scripts CLAUDE.md README.md docs/release-checklist.md docs/roadmap.md`
  prints nothing at the baseline and at the release commit; the same
  pattern over this spec prints many lines.
- **No model name** in any plugin file (`check-no-model-names.sh`).

## Clarifications during implementation

Numbered K-C<n>: pointers like the spec's other labels, written into no
shipped file. Each names who ruled.

Settled after S2 (all ruled by the main session under Constraints,
"Rulings for this run", 1):

- **K-C1** (S2's confirmation, ruled by the main session). The second
  failure of the skipped-gate post-check is a stop stated at the post-check,
  outside the numbered list, with the cannot-ask sentence; the gates table's
  post-check row says so. Why: K-L2 fixes the numbered list's text, and the
  skill already states unnumbered stops at their own steps.
- **K-C2** (S2's confirmation, ruled by the main session). Phase 0's
  questions about the run's inputs — no path, the entry kind, which plugin,
  an inbound source the main session cannot read — stay as they stand, and
  where `SKILL.md` says the main session asks the user only on a stop
  condition and at the two gates, it also says these are asked before the
  first launch as part of the start. Step 1.1's DONE is checked against
  points raised once the run has started.
- **K-C3** (S2's confirmation, ruled by the main session). K-L9's managed
  settings facts are carried in the task document as read on 2026-09-30
  from https://code.claude.com/docs/en/settings and
  https://code.claude.com/docs/en/managed-settings, only what the pages
  state; S3 uses no network. The main session re-read the managed-settings
  page and confirmed the system directories, the macOS managed preferences
  domain, the HKLM and HKCU keys, and `crossSessionInbound` among the lock
  keys.
- **K-C4** (S2's confirmation, ruled by the main session; delegated names
  under Constraints, "Delegated choices"). The subsection "How the main
  session rules" in Phase 2 before § A worker's question at a gate; the
  reviewer-report line `- Follow-up candidates: <list | none>`; the shared
  literal `could not be read from the hook input`, the hook's own text.
- **K-C5** (Phase 0, ruled by the main session). The spec was untracked at
  the start, which the installed 4.4.1 start checks make a stop naming the
  commit to make first. The main session made that commit itself,
  `8db589b docs(plans): add batch k autopilot-rulings spec`, and went on;
  the baseline is that commit. Why: the stop's remedy is one mechanical
  commit the skill names, the tree held nothing else, and the run was
  handed over unattended.
- **K-C6** (Phase 0, ruled by the main session, applying K-L9 before it
  ships). The launch line carried no `crossSessionInbound`; the user
  settings file sets `"crossSessionInbound": "accept"` (line 109), the
  project sets none (`.claude/settings.local.json` only, without the key),
  and no managed source exists (`/Library/Application Support/ClaudeCode/`
  absent, no `com.anthropic.claudecode` defaults domain, no server-managed
  cache file). The run went on without the question; the first message's
  delivery notice stayed the backstop, and none came.
- **K-C7** (S2's review, ruled by the main session). The Linux and WSL
  managed-settings directory, written literally, fails
  `check-no-model-names.sh`, which is on the Zero diff list; Task 6's
  runnable pattern form with a sentence naming the documented directory is
  accepted. Follow-up candidate for the user: add that directory to the
  guard's exceptions in a later batch, so the path can be cited as written.
- **K-C8** (S2's review, ruled by the main session). K-L9's "a source the
  main session cannot read (settings delivered from a server)" counts as
  present when the server-managed settings cache exists:
  https://code.claude.com/docs/en/server-managed-settings (read
  2026-09-30) names it `~/.claude/remote-settings.json` and says the
  delivered settings are kept in the configuration directory, `~/.claude`
  unless `CLAUDE_CONFIG_DIR` is set — so the lookup is
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/remote-settings.json`. That file
  present: the question as K-L9 says. Absent: the source counts as absent,
  and the delivery-notice stop stays the backstop — the same page says a
  non-interactive run does not write the cache for settings that need
  approval, which is why the backstop stays. Task 6 may cite this third
  page for these facts only. Why: the task document's criterion requires a
  condition the main session can check, and this file is the one local sign
  the documentation names.
- **K-C9** (S2's review, ruled by the main session). K-L8's "the user's
  reply in an interactive run" adds no pause and no question: the
  orchestrating skill writes `RUN_DIR/rulings.md` from a ruling it holds
  when it reaches the code-fixer dispatch — in an interactive run, a
  message from the user received before that dispatch — and the text
  promises no pause for one. Follow-up candidate for the user: whether an
  interactive task-review should offer a pause to rule on findings before
  code-fixer runs, which would be a new gate.

Settled after S3 (all ruled by the main session under Constraints,
"Rulings for this run", 1 and 3; S3's own review ran in its task-implement
Phase 2, run directory `.kenspc/runs/20260930-234108-batch-k-autopilot-rulings-tasks/`,
verdict PASS, 20 fixed, 5 deferred, 2 not applicable):

- **K-C10** (S3's review, `799b144`, ruled by the main session). The
  corrected acceptance case now passes on the unbroken clone before it
  fails on the break. Accepted as a refinement within K-L5, not a
  reopening: a failure on the break is a negative control only when the
  unbroken form passed first, the plugin's three-step mutation rule. It
  reads K-L5 beyond its letter and goes on the reviewer report's
  `beyond the letter` list.
- **K-C11** (S3's review, row E3/B5, DEFERRED MEDIUM, ruled by the main
  session; to the S5 after S3b, per ruling 3). The delivery notice covers a
  hold on the worker's side only. No new stop: `SKILL.md` says the
  delivery-notice stop stays the backstop for the worker's side, and that a
  hold on the main session's own inbound shows as a worker that returns
  with `## Question for the main session` although no `question <tag>:`
  message from it arrived; the main session answers it by the resume as
  today, records the sign, and names the settings precedence in both
  reports. The README's "caught the same way" and the CHANGELOG follow.
  Why no stop: the run can go on through the resume, and K-L2 keeps the
  numbered list; a stop would hold an unattended run for a setting the
  user can fix after it.
- **K-C12** (S3's review, row 12's Doc-sync gap, ruled by the main
  session; to the S5 after S3b as a one-line fix in an allowed file). The
  4.5.0 CHANGELOG's Phase 0 inbound entry names the file a launch line's
  `--settings` names among the sources read.
- **K-C13** (S3's review note on `d9dd607`, ruled by the main session; to
  the S5 after S3b as a one-sentence fix). The macOS managed preferences
  are read from `/Library/Managed Preferences/…` plist files, where macOS
  installs a configuration profile's managed preferences; Claude Code's
  managed-settings page names only the `com.anthropic.claudecode` domain.
  The Why says which fact comes from which source. It reads K-L9 ("the
  managed-settings path per platform is taken from Claude Code's settings
  documentation") beyond its letter and goes on `beyond the letter`.
- **K-C14** (found by the main session reading S3's Phase 0 text; to the
  S5 after S3b). S3 made "no source that sets the key" a stop naming the
  launch line, with the Why that no source is then known to accept inbound
  messages. The documentation says otherwise:
  https://code.claude.com/docs/en/cross-session-messaging § Control inbound
  messages (read 2026-10-01): when no value applies, a session that
  bypasses permission prompts delivers a message whose sender also
  bypasses, and holds the rest. Prerequisites start the main session in
  bypassPermissions and the driver starts every worker so, so with no
  source setting the key the run goes on, the state file's inbound record
  reading the default; a main session not in that mode is caught by
  K-C11's sign. Why: a stop there would stop a run the default serves,
  the waste this batch removes.
- **K-C15** (S3's review, rows E6, E7, E8, T4, DEFERRED LOW, ruled by the
  main session under ruling 3). Follow-up candidates for the user, listed
  in the reviewer report and not fixed: a ruling that arrives after the
  code-fixer dispatch (E6, tied to K-C9's pause question); a `rulings.md`
  entry outside its grammar (E7); a task status outside the four words
  (E8, needs `task-implementer.md`, on the Zero diff list); a guard for the
  telemetry hook's transcript root (T4, a new guard outside Allowed files).
  None is a one-line fix in an allowed file. R8's and B3's NOT APPLICABLE
  stand as code-fixer gave them.

Settled after S3b (all ruled by the main session under Constraints,
"Rulings for this run", 1 and 3; S3b's run directory
`.kenspc/runs/20261001-005751-changes/`, verdict PASS, no HIGH, 14 fixed
`44243f8..032d139`, 7 deferred; the zero-diff check printed nothing). One
S5 carries K-C11 to K-C14 and K-C16 to K-C19, then the narrowed review:

- **K-C16** (S3b row 4, R1, DEFERRED MEDIUM, ruled by the main session; to
  the S5). A ruling made while S6 runs: before S6 is launched the main
  session commits every pending clarification, as it does after each step;
  a question S6 raises is answered with the clarification entry's text,
  and S6 adds that entry to the spec and commits the spec alone, in the
  repository's convention for a clarification commit, before its release
  commit — so the release commit's `git rm` removes a committed spec and
  the entry stays in history, the four-way record of K-L7 kept. `SKILL.md`
  says so where Phase 2's Constraints name the main session's commits and
  in the S6 task blocks. Why not the other routes: a main-session commit
  while S6 is live could sweep S6's staged changes into it, and a record
  kept only in the state file and the reports drops one of K-L7's four.
- **K-C17** (S3b row 5, E2/B1, DEFERRED MEDIUM, ruled by the main session;
  to the S5). A ruled row whose action differs from its ruling keeps the
  verdict from PASS: PARTIAL in task-review's and task-implement's verdict
  bullets, outside every canonical block — except a FIX ruling code-fixer
  DEFERRED with the reason that its fix could not land, which stays a
  deferral. The autopilot's § The verdict loop after S3b classifies each
  such row as it classifies a HIGH row. The canonical blocks stay
  byte-identical and unchanged (K-L8).
- **K-C18** (S3b row 6, Q1, DEFERRED MEDIUM, ruled by the main session; to
  the S5). The `rulings.md` entry grammar gets one guarded form: each
  carrier that states it wraps it in `canonical:rulings-grammar` markers,
  and `check-run-contract.sh` holds the marked regions byte-identical, with
  a self-test mutation per carrier; a carrier may instead point at
  task-review's Step 5 by path and hold no copy (the implementer's choice,
  under "Delegated choices"). CLAUDE.md's Maintenance note and Repository
  scripts/ entry follow. The guard counts stay `guards run: 12` and
  `self-tests run: 11`: the check lives inside an existing guard.
- **K-C19** (S3b's regression-verifier, row 5's two observations, LOW,
  ruled by the main session; to the S5 as one-line fixes in an allowed
  file). The 4.5.0 CHANGELOG's preamble bullet carries the exception for
  the route a denial names; its Phase 0 inbound bullet names the launch
  line's `--settings` (inline JSON or a file) among the sources — the same
  line as K-C12, one fix.
- **K-C20** (S3b rows 18-21, E3, E6, T2, B7, DEFERRED LOW, ruled by the
  main session under ruling 3). Follow-up candidates for the user, listed
  in the reviewer report and not fixed: S3's batch gate answered without
  comparing the list to the ruled one (E3); a ruled ID with an unruled
  duplicate (E6, pairs with K-C15's E7); smoke rows that do not exercise
  the rulings path (T2); stop 11 naming the main session's
  `claude --version` rather than the workers' executable (B7, whose
  wording the locked design fixes). None is a one-line fix in an allowed
  file.

Settled after S5 and its narrowed review (all ruled by the main session
under Constraints, "Rulings for this run", 1 and 3; S5 fixed its eight
defects in `e79fe17..c7bf00b`; the narrowed review's run directory
`.kenspc/runs/20261001-014941-changes/`, verdict PASS, no HIGH, 4 LOW
fixed `a51e4ea..874899b`, 4 MEDIUM and 5 LOW deferred). A second S5 carries
K-C21 to K-C23, then a second narrowed review:

- **K-C21** (narrowed review row 1, R1/E3/B1, DEFERRED MEDIUM, ruled by the
  main session; to the second S5 — the second fix of K-C16's defect). S6
  raises every question before its first commit, so the clarification it
  commits lands before the removal or release commit in either mode; the
  main session checks that S6's reply lists a clarification commit for
  every ruling it answered to S6. The three places that still call S6's
  work a single commit (the role table, Phase 4's Goal, the exit
  transition) name the clarification commit too. Why this route: it keeps
  K-C16's order and K-L7's four records, while making the removal S6's
  last commit in both modes would change the documented order of S6's
  commits in Phase 4, both S6 blocks, and the README.
- **K-C22** (narrowed review row 2, E1, DEFERRED MEDIUM, ruled by the main
  session; to the second S5). A ruled ID that no report lists keeps the
  verdict from PASS, as a ruled row whose action differs does (K-C17):
  both are a ruling not carried out. The premise holds: task-review's PASS
  conditions do not include regression-verifier's row 1, so the
  bookkeeping error it records there leaves PASS standing. The clause goes
  beside K-C17's in both skills' verdict bullets, outside every canonical
  block, and the autopilot's verdict loop classifies it as a ruled row.
- **K-C23** (narrowed review row 3, E2, DEFERRED MEDIUM, ruled by the main
  session; to the second S5 — the second fix of K-C11's defect). The sign
  a worker's missing question gives does not over-claim: the record reads
  that the question was not received, and names the causes to check — the
  main session's own inbound under the settings precedence, or a send
  that failed or was never made — rather than recording a hold. No
  transcript read is added. Why: the reviewer's route would read an
  undocumented transcript format for a send the record only needs to name
  as a possible cause.
- **K-C24** (narrowed review row 4, E4, DEFERRED MEDIUM, ruled by the main
  session: not a defect, no change). K-C14 stands. The reviewer's route
  would read `--permission-mode bypassPermissions` from the launch line;
  this run's own main session disproves it: a background session whose
  parent command line (`claude bg-spare …`) shows no permission flag while
  it runs in bypassPermissions, so the check would have stopped a run the
  default served. A main session not in that mode stays caught by the
  sign K-C23 words.
- **K-C25** (narrowed review rows 9-13, E5, E6, T2, T3, T4, DEFERRED LOW,
  ruled by the main session under ruling 3). Follow-up candidates for the
  user, listed in the reviewer report and not fixed: the unreadable-source
  question's `no` mapped to a stop the default may serve (E5); the
  could-not-land exception resting on code-fixer's own reason (E6); the
  README's copy of the rulings grammar outside the new byte-identity check
  (T2); no smoke assertion on the state file's inbound line (T3); no guard
  or smoke row for the ruled-verdict rule and S6's clarification commit
  (T4, with K-C20's T2). None is a one-line fix in an allowed file.

Settled during the second S5 (ruled by the main session under
Constraints, "Rulings for this run", 1, on the second S5's question):

- **K-C26** (the second S5's question on K-C21, ruled by the main
  session). A point that arises only after S6's first commit is not asked:
  S6 puts it in its reply and the main session rules it there. A ruling
  answered to S6, or ruled from its reply, with no clarification commit is
  not a stop: its `Main-session rulings` line says
  `no clarification commit (the spec was already removed)`, and the user
  report lists it among what the user reviews before the tag and the push;
  the reports do not ask the user to add a spec entry, since a
  clarification committed after the release commit would re-add the
  removed file. Why: K-L2 lists no stop for a record gap, and the reports
  can name it; leaving the outcome unstated was the defect.

Settled after the second narrowed review (all ruled by the main session
under Constraints, "Rulings for this run", 1 and 3; the second S5 fixed its
three defects in `b032844..5e21fbe`; the review's run directory
`.kenspc/runs/20261001-022648-changes/`, verdict PASS, no HIGH, 6 fixed
`53e74ba..8bf3859` and verified CLEAN, 4 MEDIUM and 2 LOW deferred). Stop
condition 4 is not reached: the earlier fixes of the S6 route and of the
missing-question sign were verified CLEAN, and rows 5 to 8 are new findings
on the text those fixes added, not the same defect still failing. A third
S5 carries K-C27 to K-C31, each the smallest wording that closes its row,
then a third narrowed review; a finding there that the S6 route or the sign
still fails is judged against stop 4.

- **K-C27** (row 5, R1/E1/B4/E6, DEFERRED MEDIUM; to the third S5). The
  cutoff is the commit that removes the spec, not S6's first commit: S6
  raises every question before that commit, its own clarification commit
  allowed first. When S6 removes nothing (a `Release preparation:` list
  that says `keep`), S6 may ask at any point and commits the entry before
  it ends. The marker `no clarification commit (the spec was already
  removed)` is written only when a removal happened. This reads K-C21
  beyond its letter, on the reviewers' evidence, and goes on
  `beyond the letter`.
- **K-C28** (row 6, E2/B3/T1/R4, DEFERRED MEDIUM; to the third S5). Before
  answering a question from S6 the main session checks whether the spec is
  still at HEAD (`git cat-file -e HEAD:<spec path>`); when it is gone, the
  answer tells S6 to put the point in its reply. At S6's return the main
  session also checks, with `git log --reverse <head>..HEAD`, that each
  clarification commit comes before the commit that removes the spec, and
  after a removal that the spec is absent at HEAD. A failed check is
  recorded in both reports with the commits it names; it is not a stop.
- **K-C29** (row 7, E3/B5, DEFERRED MEDIUM; to the third S5). A point that
  arises after the removal: S6 leaves the work the point decides undone
  and names it in its reply; the main session rules it, marks it as K-C26
  says, and lists the undone work among what needs the user in both
  reports. No resume of S6 for it.
- **K-C30** (row 8, E4, DEFERRED MEDIUM; to the third S5). Preamble § 1: a
  send that returns an error, or a delivery notice saying the message was
  held or refused, puts the question under
  `## Question for the main session` at once, quoting the error or the
  notice, and the worker stops; the main session then records the cause
  the worker named in place of the list of causes K-C23 gives. The rails
  guard is rerun, since the preamble is one of its carriers.
- **K-C31** (regression-verifier's three LOW observations; to the third S5
  as one-line fixes in an allowed file). The Quality bar's Why no longer
  says every ruling is committed as a clarification without S6's
  exception; the S5 task block's finding placeholder names the
  `rulings.md` entry for a ruled ID no report lists; the sentence in Phase
  4 that sits between "S6 makes one commit" and the removal commit's
  subject is reworded so neither subject reads as the other's.
- **K-C32** (rows 11 and 12, T2 and T3, DEFERRED LOW; under ruling 3).
  Follow-up candidates for the user: a guard for the rule that a ruled ID
  no report lists holds the verdict from PASS, and one for S6's question
  cutoff — both with the earlier guard candidates (K-C20's T2, K-C25's T4).

Settled during the third S5 (ruled by the main session under Constraints,
"Rulings for this run", 1, on the third S5's question):

- **K-C33** (the third S5's question on K-C27, ruled by the main session).
  In a run where S6 removes nothing, a ruling S6 was answered that has no
  clarification commit when S6 ends is committed by the main session once
  S6 has ended, in the repository's convention for a clarification commit,
  and the return check notes the main session made it. Why: with no
  removal nothing is re-added, and with S6 ended no staged change can be
  swept in — K-C16's two reasons against a main-session commit do not
  apply — while K-L7's four records stay whole.
- **K-C34** (the same question on K-C28 and K-C29, ruled by the main
  session). A failed check at S6's return and the work S6 left undone go
  on the reviewer report's `Follow-up candidates` line and in the user
  report among what needs the user, following K-C23's precedent; no
  template field is added.

Settled after the third narrowed review (all ruled by the main session
under Constraints, "Rulings for this run", 1 and 3; the third S5 fixed its
five defects in `355dbfb..5c01fbb`; the review's run directory
`.kenspc/runs/20261001-030201-changes/`, verdict PASS, no HIGH, 9 fixed
`8844d8d..3a38ede` and verified CLEAN, 1 MEDIUM and 1 LOW deferred). Stop
condition 4 is not reached: the review found no earlier fix still failing,
and its rows were new findings on the third S5's text. A fourth S5 carries
K-C35 and K-C36, then a fourth narrowed review.

- **K-C35** (row 6, E4, DEFERRED MEDIUM; to the fourth S5). K-C34's "no
  template field is added" covers the reports, not the state file. The
  reviewer report is built from the state file, so the state file template
  gains one line for S6's return — the failed checks with the commits they
  name, and the work S6 left undone for a point raised after the removal,
  or `none` — and the `Follow-up candidates` line names it among its
  sources.
- **K-C36** (regression-verifier's observation on `5ec0a73` and
  `902a4e7`, LOW, one clause in an allowed file; to the fourth S5). The
  gate on the main session's keep-path clarification commit runs the same
  HEAD-and-index check, with its control, that the main session runs
  before answering S6, so a staged but uncommitted removal of the spec is
  never committed under the clarification subject.
- **K-C37** (row 11, T1, DEFERRED LOW, and the two partial-fix notes on
  rows 3 and 9; under ruling 3). Follow-up candidates for the user: a
  guard for the `## Question for the main session` literal (with K-C20,
  K-C25, and K-C32's guard candidates); a quoted cause holding `,` or `)`
  on the `inbound:` line, which nothing parses; the spec check running when
  the main session answers rather than when S6 acts, which matters only
  for an S6 that breaks "wait in place". None is a one-line fix.

Settled after the fourth narrowed review (all ruled by the main session
under Constraints, "Rulings for this run", 1 and 3; the fourth S5 fixed
K-C35 and K-C36 in `e8305ce..d5c8ac9`; the review's run directory
`.kenspc/runs/20261001-032819-changes/`, verdict PARTIAL — no HIGH, 5 fixed
`b61d1e8..4f0efb6`, row 5 FAIL on a suspected regression, 2 MEDIUM and
1 LOW deferred). Stop condition 4 is not reached: the keep-path gate
(K-C33, first fixed by K-C36) gets its second fix here, and the row-5
regression is new. A fifth S5 carries K-C38 and K-C39, then a fifth
narrowed review; a finding there that the keep-path gate or the spec's
index check still fails is stop 4.

- **K-C38** (row 5 FAIL, regression-verifier on `3ecfb9d`, suspected,
  low confidence; classified as a plugin defect and sent to the fifth S5).
  The spec's index check passes `':/<spec path>'`, an argument Git Bash's
  path conversion may rewrite on Windows, where it cannot be verified from
  this machine. The check is written without a `:/` argument instead —
  `git -C <repository root> ls-files --error-unmatch -- <spec path>` —
  everywhere it is stated, with its control. Why: the rewrite question
  disappears rather than being answered, and the form is plain git on
  every platform.
- **K-C39** (rows 3 and 4, E2/B1 and E3, DEFERRED MEDIUM; to the fifth
  S5). Before the main session writes a keep-path entry, after S6 has
  ended, `git -C <repository root> status --porcelain -- <spec path>`
  must print nothing. Anything printed — a removal S6 staged and did not
  commit, or an edit it left — means no commit: the ruling's line carries
  `no clarification commit (S6 left the spec changed)`, the `S6 return:`
  line names the leftover, and both reports list it among what needs the
  user. Why: one status check covers both states the review found, and
  the main session commits none of S6's changes.
- **K-C40** (row 8, T1, DEFERRED LOW; under ruling 3). Follow-up
  candidate: a guard for the `S6 return:` literal, with the earlier guard
  candidates.

## Autopilot

- Mode: plugin
- Version: 4.5.0
- Budget: USD 200
- Must read: CLAUDE.md, plugins/kenspc/skills/autopilot/SKILL.md, plugins/kenspc/skills/task-review/SKILL.md, plugins/kenspc/skills/task-implement/SKILL.md, plugins/kenspc/agents/code-fixer.md, plugins/kenspc/agents/regression-verifier.md, plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh, docs/roadmap.md
- Prior specs: e2a34d1^:docs/plans/batch-j-autopilot-reliability.md, 2375556^:docs/plans/batch-f-autopilot.md
- Allowed files: plugins/kenspc/skills/autopilot/SKILL.md, plugins/kenspc/skills/task-review/SKILL.md, plugins/kenspc/skills/task-implement/SKILL.md, plugins/kenspc/agents/code-fixer.md, plugins/kenspc/agents/regression-verifier.md, plugins/kenspc/hooks/scripts/session-end-telemetry.sh, scripts/check-run-contract.sh, scripts/check-autopilot-rails-hook.sh, plugins/kenspc/README.md, README.md, CLAUDE.md, plugins/kenspc/CHANGELOG.md, plugins/kenspc/.claude-plugin/plugin.json, .claude-plugin/marketplace.json, docs/release-checklist.md, docs/roadmap.md, docs/plans/batch-k-autopilot-rulings.md, docs/tasks/
- Zero diff: plugins/kenspc/skills/autopilot/scripts/, plugins/kenspc/hooks/hooks.json, plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh, plugins/kenspc/hooks/scripts/remind-plan-skill.sh, plugins/kenspc/commands/, plugins/kenspc/shared/, plugins/kenspc/references/, plugins/kenspc/skills/generate-brief/, plugins/kenspc/skills/generate-plan/, plugins/kenspc/skills/generate-task/, plugins/kenspc/skills/generate-guide/, plugins/kenspc/skills/diagnose-bug/, plugins/kenspc/skills/prototype/, plugins/kenspc/skills/init-project/, plugins/kenspc/agents/task-implementer.md, plugins/kenspc/agents/requirements-reviewer.md, plugins/kenspc/agents/edge-case-reviewer.md, plugins/kenspc/agents/quality-reviewer.md, plugins/kenspc/agents/bug-reviewer.md, plugins/kenspc/agents/test-reviewer.md, plugins/kenspc/agents/plan-document-reviewer.md, plugins/kenspc/agents/task-document-reviewer.md, plugins/kenspc/agents/guide-document-reviewer.md, scripts/check-all.sh, scripts/check-canonical-dispatch.sh, scripts/check-verdict-shared.sh, scripts/check-review-agent-drift.sh, scripts/check-code-craft-canonical.sh, scripts/check-instruction-files.sh, scripts/check-no-model-names.sh, scripts/check-doc-sync-anchors.sh, scripts/check-json.sh, scripts/check-notes-format-sync.sh, scripts/check-quality-reviewer-bullet-structure.sh
- Acceptance: none
