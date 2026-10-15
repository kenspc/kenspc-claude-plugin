# Plan: Batch M — autopilot field lessons (second slice, 4.7.0)

## Objective

Settle the design choices the roadmap left open for the second slice of
the dayaku-crm autopilot lessons, and build them into the plugin. The
roadmap items (`docs/roadmap.md`, Next minor (4.7.0)), named by subject:

- "A second fix round, and when a ruling reaches code-fixer", with the two
  items it says one plan should settle beside it: "A narrowed review's own
  code-fixer can make an incomplete fix that fails that same review", and
  the grammar gaps of "`rulings.md` follow-ups" (an entry outside the
  grammar, a ruled ID whose duplicate carries no ruling, one ID ruled two
  ways);
- "Heavy commands across parallel reviewers";
- "Rails gaps and benign breaches met in the dayaku-crm batches";
- "S3b on a condition in repo mode" — the condition and the trial (the
  switch shipped in 4.6.0);
- "A runtime walk, which a batch can turn off";
- "A task S3 leaves BLOCKED, when its review is otherwise clean".

In scope: task-review and task-implement (the second fix round, the shared
suite run, the tree check around the reviewers), code-fixer and
regression-verifier (the second round, the `F` and `V` IDs, the rulings
grammar), the five review-angle agents (the shared suite run), the
autopilot skill (preamble, verdict loop, S3b `auto`, BLOCKED tasks, benign
breaches, the walk session S4w and its start check), the autopilot driver
scripts only where the probe in Step 1 shows a walk worker needs a flag,
the rails hook and its guard, the guards that hold the changed canonical
blocks, and the durable documents.

Out of scope: of "`rulings.md` follow-ups", whether an interactive
task-review pauses for the user to rule before code-fixer runs, the
could-not-land exception, and the README's copy of the grammar outside the
byte-identity check — they stay on the roadmap; changing the default of
`Standalone review:` (it stays `on` until the trial below has run); the
rails-hook misses this plan does not name (`tee`, `cp`, `mv`, writes by an
interpreter, line continuations); a walk of any environment but the local
machine; any release, version bump, tag, or push; installing the plugin.
The commits stay local on `main`.

Four outcomes would make this batch wrong, whatever its tests say
(the maintainer's failure criteria, 15 Oct 2026): unattended runs stop
more often than before; a batch costs clearly more than before; the rails
hook denies work it should allow, or its scan slows past its timeout; an
interactive `/kenspc-task-review` gains pauses or questions. Each step's
design and the Risks section are written against them.

## Background / Context

Thirty-three dayaku-crm batches ran under the autopilot between 29 Sep and
14 Oct 2026 (records: `~/Projects/_smoke/_logs/<batch>-state.md` and
`-report.md`, on the maintainer's Mac only; the open-items note in the
maintainer's long-term memory). 4.6.0 shipped the remedies that needed no
new design. The six items here each listed an Open choice; the maintainer
ruled every one on 15 Oct 2026 in the planning discussion, and the
Technical Approach records the rulings with their reasons. The roadmap
items carry the evidence; this plan does not repeat it beyond what a
decision rests on.

## Technical Approach

### A second fix round (rulings, review skills, autopilot)

- **Triggered by a ruling, at most one per review.** A review — task-review,
  the review phase of task-implement, and so a narrowed review — runs a
  second code-fixer pass only when the orchestrator holds a ruling given
  after code-fixer's first dispatch: in an interactive run, a message from
  the user received after that dispatch; in an autopilot worker, the main
  session's answer. It never runs on regression-verifier's result alone,
  and a review runs at most one second round. What is left after it goes
  to the verdict as today, and in the autopilot to S5. Why one: an
  unbounded in-review loop would bypass the stop conditions that count
  fixes per defect (participants-portal ran three rounds on one finding in
  its implementation review and four in its standalone review); why a
  ruling: a second pass with no ruling would only repeat code-fixer's own
  choices.
- **Mechanics, as attendance-api ran them by hand.** In every review, as
  soon as regression-verifier's first reply returns, the orchestrator saves
  it to `RUN_DIR/schema-c-1.md`, ruling or not. When it then holds a ruling
  given after code-fixer's first dispatch, it appends a section
  `## Round 2` to `RUN_DIR/rulings.md` (creating the file, first line
  naming who ruled, when there was no first-round ruling), and dispatches
  code-fixer and regression-verifier again — fresh dispatches, not resumed
  agents, with the CONTEXT block unchanged. code-fixer reads the round-2
  section, updates its rows of `schema-b.md` in place, keeps every row,
  and adds rows for the round's `F` and `V` IDs. Why fresh: a resumed
  subagent ran in the background in portal-service-locations, and a
  headless worker had to wait on it by hand. Why saved in every review: a
  worker's question names `schema-c-1.md` before any ruling exists (below),
  and the `V` IDs a ruling names are read from it; the save is one file
  write and asks nothing.
- **One text for both skills.** The second-round step is a new canonical
  block, `<!-- canonical:second-round:start/end -->`, byte-identical in
  `task-review/SKILL.md` and `task-implement/SKILL.md`, held by a new check
  in `check-run-contract.sh` with a self-test mutant, as the run-dir and
  rulings-grammar blocks are held.
- **When a ruling reaches code-fixer.** The autopilot preamble's § 1 states
  what held from participant-import on: a worker asks for a ruling on a
  review's findings only once the last reviewer has returned, and a ruling
  that arrives after code-fixer's dispatch is the second round's. After
  regression-verifier returns HAS ISSUES, or with a verdict other than
  PASS, the worker sends the main session one question naming
  `schema-b.md` and `schema-c-1.md` by path; the main session rules a
  second round with its entries, or none.
- **Rulings grammar.** A FIX entry may defer part of a finding:
  `- <ID>[, <ID>…]: FIX — <what to do>; DEFER rest — <reason>`. The row's
  action stays FIXED, regression-verifier checks the fix against the FIX
  text, and code-fixer writes the deferred part into the row's Deferred
  Issues prose. An entry that names a group of IDs covers every clause of
  every row it names, one sentence per clause. An entry outside the
  grammar — an unknown action word, no ID, no first line naming who ruled,
  one ID in two entries of the same round (the entries before
  `## Round 2`, or those after it) — is not carried out: code-fixer names it in its
  reply, regression-verifier's row 1 names it, and the verdict is at most
  PARTIAL, as for a ruled ID no report lists. An ID ruled in round 1 and
  again under `## Round 2` is not two entries: the round-2 entry replaces
  the round-1 entry for that ID, and regression-verifier's check 1 judges
  its row against the round-2 entry. A ruled ID's duplicate that
  carries no ruling is merged into the ruled row and takes its ruling.
  Why the tail rather than a second entry: one ID keeps one entry and one
  action, so the recount and regression-verifier's check 1 stay as they
  are.
- **`F` and `V` IDs.** A defect code-fixer finds that no reviewer reported
  is recorded as a row with Source `F<n>`, DEFERRED with the reason that
  no report lists it — code-fixer does not fix outside the reports — and a
  regression regression-verifier finds is named `V<n>` in its Schema C
  Detail. A ruling may name either, and a second round fixes it.
  regression-verifier's ID-set comparison takes an `F` row as
  code-fixer's own and a `V` row as listed by `schema-c-1.md`, not as an ID
  no report lists. The
  statistics-line template becomes
  `total reported N (R n, E n, Q n, B n, T n, F n, V n), deduplicated to N unique, FIXED N, DEFERRED N, NOT APPLICABLE N, DEDUPED N`.
  Why: user-guide's code-fixer found a defect no reviewer had, and
  participants-portal's verifier a regression; with no row, the main
  session's ruling on each read as a ruled ID no report lists.
- **Narrowed reviews keep fixing.** A narrowed review is a task-review, so
  the second round applies to it; an incomplete fix it makes can be
  finished by a ruled second round rather than by another S5 and another
  narrowed review. What it still fails goes to S5, bounded by stop
  condition 3.
- **S3b reads the implementation review's rulings through the main
  session.** S3b's task block names S3's `rulings.md` path(s). Before
  ruling on S3b's findings, the main session compares them with those
  entries, and a finding an earlier DEFER or NOT APPLICABLE entry covered
  is ruled the same, citing the entry. task-review itself is unchanged.
  Why not in task-review: the two reviews' IDs differ, and whether two
  findings are the same is a judgment the main session already makes.

### Heavy commands across parallel reviewers

- **One suite run, shared.** Before the five reviewers are dispatched, the
  orchestrator runs the project's test command once — the commands the
  project's instruction files give for the parts the change set touches,
  found as regression-verifier finds them — and writes
  `RUN_DIR/suite-run.md`: each command, its exit code, its duration, and
  the path of its log under `RUN_DIR/scratch/orchestrator/`. With
  `RUN_DIR`, a reviewer never runs the project's full test command; it
  reads `suite-run.md`, and may run named test files and its own scratch
  mutation checks, one command at a time. Without `RUN_DIR` (standalone),
  a reviewer runs as before. code-fixer and regression-verifier run after
  the reviewers, one at a time, and are unchanged. Why: five full suites at
  once exhausted the Mac's local ports in participants-api, and the
  connection errors read like findings.
- **A tree check around the reviewers.** After the shared suite run and
  before the dispatch, the orchestrator records
  `git status --porcelain=v1 -uall` and a hash of `git diff HEAD --binary`,
  and records them again after the five return. A tracked file whose
  status or content changed stops the review before code-fixer, naming the
  files; nothing is restored automatically. A new untracked file stops
  nothing: the final report names it. Why the suite run comes first: a
  suite that writes into the tree would otherwise read as a reviewer's
  change. Why only tracked files stop it: a test a reviewer runs may leave
  an output file, which costs the user nothing to see in the report, while
  a changed tracked file is the user's code. In a session that cannot ask,
  the run ends with the files named; in an autopilot worker, the point goes
  to the main session as a question. Why no automatic restore: in an
  `uncommitted` review the working tree holds the user's own changes, and
  five parallel reviewers leave no way to tell which wrote what. Why a
  stop: a reviewer's `vitest list --json <files>` overwrote a tracked test
  file (the flag took the next word as its output file), and code-fixer
  would have fixed the tree as it found it. The check stops nothing when
  the tree is unchanged, so an interactive review gains no question in the
  ordinary case.
- Both rules sit in the canonical dispatch block, so
  `check-canonical-dispatch.sh` holds them identical in the two skills, and
  the reviewers' rule sits in the sections the five agents share, held by
  `check-review-agent-drift.sh`. code-fixer making mutants in place on
  tracked files (portal-fixes, reschedule-pages) stays an observation: its
  rule already puts a mutant on a copy.

### Rails: Bash writes, GitHub, benign breaches

- **The hook judges redirection targets.** In a marked worker, a Bash
  redirection — `>`, `>>`, `>|`, `&>`, `&>>`, and the same with a leading
  file-descriptor number — whose target, read after expanding a leading
  `~`, `$HOME`, `${HOME}`, `$TMPDIR`, or `${TMPDIR}` and collapsing `.` and
  `..` as written, lies outside every write root is denied, with the
  route the file-tool denial names. A target that holds any other
  expansion, a command substitution, or a glob is not judged; `/dev/null`,
  `/dev/stdout`, `/dev/stderr`, `/dev/tty`, and `/dev/fd/<n>` are allowed;
  a duplication such as `2>&1` is not a target; a `>` inside quotes or a
  heredoc body is not a redirection. Why redirections only: both writes
  met in the batches were redirections (`> "$TMPDIR/../nothing"` in
  scheduling-board, a `>>` to `MEMORY.md` under `~/.claude` in
  portal-shell-tenants); `tee`, `cp`, and `mv` stay among the header's
  misses, since their argument forms (`-t`, several sources) would grow the
  scanner and its fixtures for writes no batch made.
- **The hook denies GitHub and remote git.** At a command position, `gh`
  is denied — `command -v gh`, `type gh`, and `which gh`, which do not run
  it, are allowed — and so is `git` — its global options (`-C <path>`,
  `-c <name>=<value>`, `--git-dir=…`, `--work-tree=…`, `--no-pager`)
  skipped — with the subcommand `fetch`, `pull`, `push`, `ls-remote`, or
  `remote update`, or `clone` whose source is a URL (it holds `://`, or is
  `<user>@<host>:<path>`). The reason's route: ask the main session, which
  gets anything the work needs from GitHub. Preamble § 3 gains the same
  sentence. Why a denial: a denial is not a breach, so the run goes on,
  and the hook reaches a subagent that never saw the preamble — an
  implementer subagent's read-only `gh issue view` stopped
  account-invitation as a breach. A `git clone` of a local path is
  allowed, since acceptance evidence is gathered in local clones.
- **Benign breaches ruled by the main session.** A worker still reports a
  breach and ends (preamble § 3 is unchanged on this). The main session
  may rule the breach benign when all hold: no secret was written or sent;
  it is not a recursive `rm`, a push, a tag, or a release; and it changed
  no state outside the write roots, or the only change is a file holding
  no secret, which the main session moves into the workspace's `.trash/`.
  Then it records the breach under the state file's new `breaches ruled:`
  section and resumes the worker under `<tag>-r<k>` with
  `answer <tag>: breach ruled benign — <one line>`, counted as a resume.
  The reviewer report gains a `Breaches ruled benign:` line and the user
  report lists each, so the user reads them before the tag. Any other
  breach stays stop condition 6. The roadmap's cases fall as follows: a
  reviewer's probe towards a reserved test name that sent nothing off the
  machine, `docker exec pg18 true`, and the `$TMPDIR/..` file are benign;
  the `MEMORY.md` append changed state under `~/.claude` and goes to the
  user (and the redirection check now denies it before it runs).

### S3b on a condition in repo mode

- **A third value, `auto`.** `Standalone review:` takes `on`, `off`, or
  `auto`; `off` and `auto` are repo mode only, and either in plugin mode is
  a settings stop. With `auto`, after S3 returns, S3b runs when S3's
  Schema G verdict is FAIL, or PARTIAL for a reason other than BLOCKED
  tasks alone, or S3's review left a HIGH or MEDIUM row DEFERRED;
  otherwise S3's verdict enters the verdict loop as with `off`. Why from
  S3's own review: the condition is read from an artifact S3 already
  produced, so the main session judges nothing; the one HIGH S3b found
  that the implementation review missed (participants-portal) came from a
  batch whose S3 review had deferred four findings, which the condition
  catches. A batch the user judges risky — security, a data migration,
  concurrency — is written `on`. Why BLOCKED tasks alone do not trigger
  it: they are classified on their own (below), and a review of a batch
  with a task not built adds nothing about that task.
- **The default stays `on`.** The reviewer report gains
  `Standalone review: <value> — ran (<trigger>)` or
  `— not run (<reason>)`, so the trial reads from the reports.
- **The trial** (written into the roadmap item, which stays open): the
  maintainer writes `Standalone review: auto` in the next five repo-mode
  dayaku-crm batches; the follow-up issues filed after each batch's
  release are compared by count and by severity with the batches before
  4.7.0; S3b returns to `on` if HIGH or MEDIUM follow-ups rise. The
  default changes, if at all, in a later release.

### A task S3 leaves BLOCKED

- At S3's return the main session reads every task's status from the
  committed task document, whatever the switch. Each BLOCKED task is
  classified as a HIGH row is: an S5 that implements it — its task block
  quoting the task and its BLOCKED note — or a deferral recorded as a
  clarification naming who ruled. A block that needs a change outside the
  batch's contract (a new dependency, an API contract, a schema change the
  spec does not name) is stop condition 7 (a), as any such option is. Both
  reports name each BLOCKED task and its classification. Written once, in
  § The verdict loop after S3b, so it covers `on`, `off`, and `auto`.
  Why: a batch with a BLOCKED task could reach acceptance and release
  preparation without the task being named, since S3b's Schema F ignores
  task statuses and S3's PARTIAL had no branch.

### The runtime walk (S4w)

- **A session after S4, in repo mode.** A new role, S4w (tag `-s4w`, a
  re-run `-s4wb`, the next letter for a later one), runs once S4's FAILs
  are classified and their re-runs have passed, or after the
  `Acceptance: none` record — so it walks the code the batch will release.
  `Role settings:` accepts `S4w`. The tag rules read `-s4w` and
  `-s4w<letter>` as S4w ahead of the rule that reads `-s4<letter>` as an S4
  re-run, and S4's own re-run letters skip `w`. Why: `-s4w` has the form
  `-s4<letter>`, so read by today's rule a walk would take S4's role
  settings, and S4's re-run after `-s4v` would take the walk's tag.
- **The field `Walk:`.** `on` (the default in repo mode): S4w picks the
  flows a user of the app takes that the batch changed, from the spec's
  steps, and lists the flows it chose in its reply. `off`: no S4w. Or
  sub-bullets, each a flow and what must be seen, which S4w walks as
  written. In plugin mode the default is `off`, and `on` or sub-bullets is
  a settings stop, since the plugin has no app to walk. With `on` and no
  user interface in the batch, S4w replies `nothing to walk: <reason>`,
  which is not a failure.
- **The browser tool, Claude in Chrome first.** S4w uses Claude in Chrome
  when it is usable — Chrome running, the extension connected to the same
  Claude account as the worker — and otherwise the Playwright MCP (the
  maintainer's ruling, 15 Oct 2026). With neither usable, the run stops.
  The main session checks before the first launch, among the start checks,
  so a machine with neither stops before any session is paid for, and the
  user fixes a tool or writes `Walk: off`; S4w checks again at its own
  start, and with neither usable then it ends with
  `walk tool unavailable`, which is a stop stated at its own step. Whether
  a headless `claude -p` worker can use Claude in Chrome at all, and how
  each tool's availability is checked, is Step 1's probe; when a headless
  worker cannot use Claude in Chrome, the order is Playwright alone and
  the plan's text says so.
- **What S4w must respect.** It walks the local machine only — local URLs,
  never a staging or production environment. In Claude in Chrome it opens
  tabs of its own and never reads, uses, or closes the user's other tabs.
  It starts the app as the project's instruction files and the spec say,
  and the S4w task block names the local resources that start needs (its
  database, its dev servers) as resources the run names, which preamble
  § 3 requires. Data follows the project's instruction files' rule; with
  none, synthetic data only. A test account's password is read at run time
  from the file the project keeps it in, inside the page or script, and
  never appears in a tool call's input or a message. Before it starts a
  server it checks the ports it needs; a port held by a process it did
  not start goes to the main session as a question, and the main session
  rules wait — re-check every 10 minutes, at most 60 minutes — or skip,
  recorded `not walked: port <n> in use`; neither is a stop. It stops only
  the processes it started, found by their listener
  (`lsof -ti tcp:<port> -sTCP:LISTEN`). An app it cannot start is
  `not walked: <reason>`, recorded, not a stop.
- **Its record and its failures.** Screenshots and `walk.md` (per flow: the
  steps, what was seen, PASS or FAIL, the screenshot paths) go under
  `<workspace>/_logs/<batch>-walk/`. A FAIL is classified as Phase 3
  classifies an acceptance FAIL: a defect → S5 → the narrowed review →
  an `-s4wb` re-run of the failed flows only; a behavior deviation → a
  reviewer-report line; an observation → recorded; counted per defect, as
  stop condition 4 counts. Both reports gain a `Walk:` line.
- **Budget.** The projection includes S4w; when the budget check fails,
  the walk may be cut as an `(optional)` acceptance case is, recorded
  `walk: cut by budget`.

## Implementation Steps

Each step changes the files it names and nothing else, and ends with
`bash scripts/check-all.sh` green. The steps run in the order numbered.
Step 7 depends on Step 1 (its tool order and checks come from the probe)
and on Step 6 (it edits the Phase 3 and verdict-loop text Step 6 leaves).
Step 8, the walk acceptance, depends on Step 7. Step 9, the Doc-sync step,
comes last, after every step that changes what the documents describe —
the place generate-task gives a Doc-sync task and task-document-reviewer
checks it holds.
Steps 2, 3, 5, 6, and 7 edit `skills/autopilot/SKILL.md`, and Step 2 and
Step 3 both edit `task-review/SKILL.md` and `task-implement/SKILL.md`, so
each step edits the text as the earlier steps left it and keeps their
additions.

Every rule a step adds to a skill, an agent, or the hook carries its Why in
the file's form, the failure stated in its own words, not cited as a
dry-run record (CLAUDE.md, Writing Rules for Skill Content). A stop a step
adds to a skill opens its no-ask branch with "In a session that cannot ask
(a system reminder to work without stopping), …".

### Step 1: Probe the browser tools in a headless worker

Input: the maintainer's Mac, Chrome with the Claude in Chrome extension,
the Playwright MCP as configured in the user's settings. Output:
`docs/dry-runs/batch-m-walk-probe.md`, committed alone
(`docs: add batch m walk probe record`).

Launch headless sessions through a copy of `run.sh` (so they run as a
worker runs: `bypassPermissions`, the marker set) on a throwaway seed
under `~/Projects/_smoke/`, a static page served on `127.0.0.1`.
`run.sh` passes a fixed flag set and no caller-supplied flag, so a launch
with `--chrome` uses a second probe copy with the flag added to its
`args=(…)` line; the shipped `run.sh` is not edited in this step. Record
for each tool:

1. whether its tools are present in the worker session, and with which
   flags (`--chrome` or none);
2. a navigation to the seed's page and a screenshot written under the
   workspace;
3. a check command the main session can run before the first launch that
   says usable or not usable, shown both ways: usable as set up, and not
   usable with the tool made unavailable (Chrome quit, or the MCP server
   left out of the worker's configuration), with both outputs recorded;
4. the cost of each launch.

Acceptance: the record holds the four items for both tools, each check
shown returning both answers; the total cost is at most USD 5. When a
headless worker cannot use Claude in Chrome, the record says so with the
error, and Step 7 writes Playwright alone. When a headless worker can use
neither tool, the record says so with both errors, and Steps 7 and 8 do not
start until the maintainer has ruled on the record: the walk as designed
has no tool. Steps 2 to 6 do not depend on the probe and go on.

### Step 2: The second fix round and the rulings grammar

Files: `skills/task-review/SKILL.md` (Step 5; a new step after Step 6
for the second round, which makes the Schema F step Step 8, the skill's
own references to it following; that step and its Verdict
determination), `skills/task-implement/SKILL.md`
(Phase 2 Step 3, Step 4), `agents/code-fixer.md`,
`agents/regression-verifier.md`, `skills/autopilot/SKILL.md` (preamble § 1
and its Why; § The verdict loop after S3b; the S3b task block),
`scripts/check-run-contract.sh`.

- The rulings grammar block (`canonical:rulings-grammar`) gains the DEFER
  tail on FIX, in its four carriers. task-review's Step 5 states, beside
  the block: an entry naming a group covers every clause of every named
  row, one sentence per clause; an entry outside the grammar (unknown
  action word, no ID, no first line naming who ruled, one ID in two
  entries of the same round) is not carried out, named in code-fixer's
  reply and regression-verifier's row 1, and keeps the verdict from PASS;
  a round-2 entry for an ID ruled in round 1 replaces that entry and is
  not a second entry; a ruled ID's unruled duplicate is merged into the
  ruled row and takes its ruling. code-fixer and regression-verifier state
  their side of each.
- code-fixer records a defect no report lists as a row with Source
  `F<n>`, DEFERRED, `no report lists it` as the reason; regression-verifier
  names a regression it finds `V<n>` in its Schema C Detail. The
  `canonical:stats-line` template gains `F n, V n` in its three carriers;
  code-fixer's worked Schema B example gains one `F` row so the recount
  covers it.
- The new `canonical:second-round` block, byte-identical in the two
  skills: in every review, as soon as regression-verifier's first reply
  returns, the orchestrator saves it to `RUN_DIR/schema-c-1.md`; when it
  then holds a ruling given after code-fixer's first dispatch, it appends
  `## Round 2` with the round's entries to
  `RUN_DIR/rulings.md` (creating the file with its first line when there
  is none), dispatches code-fixer and then regression-verifier afresh with
  the CONTEXT block unchanged, prints
  `code-fixer returned (round 2) — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`
  and `regression-verifier returned (round 2) — …` in the forms of the
  first-round lines, and reads the verdict from the second round; at most
  one second round per review; no ruling held, no second round and no
  question. The final report (Schema F, Schema G) renders the second
  round's replies and names `schema-c-1.md`.
- code-fixer reads a `## Round 2` section when it exists: it carries out
  only that section's entries, updates its rows in place, and keeps every
  row; for each `V` ID a round-2 entry names, it adds a row whose Source is
  that ID, taking the regression's file, line, and description from the
  Detail of `schema-c-1.md`, which it reads for that purpose.
  regression-verifier checks the second round's rows against that
  section, takes an `F` row as code-fixer's own and a `V` row as listed by
  `schema-c-1.md`.
- Autopilot preamble § 1: a worker asks for a ruling on a review's
  findings only once the last reviewer has returned; a ruling that arrives
  after code-fixer's dispatch is the second round's; after
  regression-verifier returns HAS ISSUES or a verdict other than PASS, the
  worker sends one question naming `schema-b.md` and `schema-c-1.md`. The
  verdict loop says a narrowed review's verdict is read after its second
  round when one ran, and that the main session rules S3b's findings
  against S3's `rulings.md`, citing an entry it follows; the S3b task block
  names S3's `rulings.md` path(s).
- `check-run-contract.sh`: check 7's reference grammar includes the tail;
  the recount counts `F` and `V` Source IDs; a new check holds the
  `canonical:second-round` block byte-identical in the two skills, its
  self-test rewording the block in each in turn; check 5 names
  `schema-c-1.md` in both skills, `code-fixer.md`, and
  `regression-verifier.md`.

Acceptance: `bash scripts/check-all.sh` and
`bash scripts/check-all.sh --self-test` green, with the new check's mutants
turning it red; `check-run-contract.sh --file` on a hand-written
`schema-b.md` holding an `F` row and a DEFER-tail FIX row recounts green;
`grep -c 'Round 2'` is at least 1 in each of the two skills, `code-fixer.md`,
and `regression-verifier.md`.

### Step 3: The shared suite run and the tree check

Files: `skills/task-review/SKILL.md` and `skills/task-implement/SKILL.md`
(the canonical dispatch block, and the Next steps of Schema F and
Schema G), the five review-angle agents (one shared section),
`scripts/check-run-contract.sh` (check 5).

- The canonical dispatch block gains, before the dispatch: run the
  project's test commands once and write `RUN_DIR/suite-run.md` (command,
  exit code, duration, log path under `RUN_DIR/scratch/orchestrator/`);
  record the tree state (`git status --porcelain=v1 -uall`, a hash of
  `git diff HEAD --binary`) under `RUN_DIR/scratch/orchestrator/`, after
  the suite run. It gains, after the agent list, the comparison, made once
  all five have returned — a re-dispatched reviewer included — and before
  code-fixer is dispatched: a changed tracked file stops the review naming
  the files, and no restore. The stop asks the user one question — go on
  to code-fixer with the tree as the user then leaves it, or end the
  review here; in a session that cannot ask, the run ends with the files
  named; in an autopilot worker, the question goes to the main session
  (preamble § 1). A new untracked file stops nothing. Why inside the block: `check-canonical-dispatch.sh` then
  holds both halves of the check identical in the two skills. Outside the
  block, each skill's final report (Schema F, Schema G) names a new
  untracked file in its Next steps.
- The five reviewers' PREREQUISITES section, which
  `check-review-agent-drift.sh` holds identical and whose item 1 already
  names the build and test commands, gains a new item: with `RUN_DIR`, read `suite-run.md`, never
  run the project's full test command, run named test files and scratch
  mutation checks one command at a time; without it, as before.
- Check 5 names `suite-run.md` in both skills and
  `requirements-reviewer.md` (the drift guard carries it to the other
  four).

Acceptance: guards green, self-tests green;
`check-canonical-dispatch.sh` and `check-review-agent-drift.sh` pass with
the new text, and each exits 1 when run in a scratch clone of the
repository under `$TMPDIR` in which the new text is deleted from one
carrier (`task-implement/SKILL.md` for the first, `bug-reviewer.md` for
the second); the clone is left in `$TMPDIR`, never removed with a
recursive `rm`.

### Step 4: The rails hook — redirections, GitHub, remote git

Files: `hooks/scripts/autopilot-worker-rails.sh` (scanner and header),
`scripts/check-autopilot-rails-hook.sh` (fixtures, self-test mutants),
`skills/autopilot/SKILL.md` (preamble § 3 and its Why).

- Redirection targets judged as the Technical Approach states, by the same
  root check the file tools get, the denial naming the same route.
- `gh`, and `git` with a remote subcommand or a URL clone, denied at a
  command position, the reason naming the route "ask the main session".
- Fixtures: denied — `> "$TMPDIR/../x"`, `>> ~/.claude/x`, `2> /etc/x`,
  `&> ../outside` from the repository root, `gh issue view 1`,
  `git -C . fetch`, `git push`, `git clone https://example.test/r.git d`,
  `git clone git@example.test:r.git d`; allowed — `> /dev/null`, `2>&1`,
  `> "$TMPDIR/x"`, `> out.txt` in the repository, `> "$OTHER/x"`
  (unjudged), `echo 'a > /etc/x'`, a heredoc body holding `> /etc/x`,
  `git clone /local/repo d`, `git status`, `grep gh f`, `command -v gh`,
  `which gh`; a timed fixture of
  a command holding 8000 redirections to a relative target in the
  repository (`>a `, about 24 KB, so the command stays under the 64 KB
  cap and is scanned rather than denied unscanned) and then `> /etc/x`,
  denied in under 2.5 seconds as the existing timed fixtures are; every
  denied fixture again without the marker. Two new self-test mutants: the
  redirection check removed, the `gh` check removed.
- Preamble § 3 names GitHub and remote git and the route; the header's
  misses list keeps `tee`, `cp`, `mv`, and interpreter writes, and drops
  redirections.

Acceptance: guards and self-tests green, each new mutant turning
`check-autopilot-rails-hook.sh` red; every timed fixture under 2.5
seconds.

### Step 5: Benign breaches ruled by the main session

Files: `skills/autopilot/SKILL.md` (a new subsection
`### A breach the main session rules benign`, placed after § How the main
session rules, whose rulings it extends; § The state file; stop
condition 6; the reviewer report and the user report; § The gates).

- The three conditions, the `.trash/` move, the record under
  `breaches ruled:`, the resume with `answer <tag>: breach ruled benign —
  <one line>` counted as a resume, the `Breaches ruled benign:` report
  line, and stop condition 6 narrowed to a breach the main session cannot
  rule benign.
- Whether the ruling is also a clarification entry, as the maintainer
  rules Open Question 3, stated in the new subsection.

Acceptance: guards green; `grep -q 'breaches ruled:'` and
`grep -q 'Breaches ruled benign:'` in `SKILL.md`; stop condition 6 names
the three conditions.

### Step 6: S3b `auto` and BLOCKED tasks

Files: `skills/autopilot/SKILL.md` (§ The `## Autopilot` section's table;
§ The start checks' `Standalone review: off` bullet, which becomes the
settings stop for `off` or `auto` in plugin mode; the role table at the
top and the paragraph after it; Phase 2's goal and DONE line; § The
verdict loop after S3b; § The zero-diff check; Phase 3's inputs, DONE
line, and Repo mode paragraph; Phase 4's zero-diff paragraph; § Phase
transitions; the S5 task block; the reviewer report's Acceptance and
`Sessions:` lines and the user report; the settings line).

- `auto` as stated, with its trigger read from S3's Schema G; the
  `Standalone review:` report line; the `none named; S3 is the last check`
  line used whenever S3b did not run.
- Every sentence that ties S3b's absence to `Standalone review: off` —
  the places listed under Files, found with
  `grep -n 'Standalone review' skills/autopilot/SKILL.md` — reads instead
  "when S3b does not run (`off`, or `auto` not triggered)"; the `Sessions:`
  line `S3b: off (Standalone review: off)` names the value and, for
  `auto`, that it was not triggered.
- BLOCKED tasks read from the committed task document at S3's return and
  classified in the verdict loop; the S5 task block's form for a task;
  both reports name each BLOCKED task.

Acceptance: guards green; the table's `Standalone review:` row reads
`on`, `off`, or `auto`; every sentence of `SKILL.md` that holds
`Standalone review: off` names `auto` too (checked by reading each line
`grep -n 'Standalone review: off'` prints, in its sentence); § Phase
transitions names `auto`; the verdict loop
names BLOCKED tasks; a read of § Phase transitions with `auto` and a
PASS-and-nothing-deferred S3 reaches Phase 3 without S3b, and with a
deferred MEDIUM reaches S3b (checked by reading, recorded in the step's
commit body).

### Step 7: The runtime walk (S4w)

Files: `skills/autopilot/SKILL.md` (the role table at the top: an S4w
row; the `## Autopilot` table: `Walk:` and `Role settings:`; § The
workspace: `_logs/<batch>-walk/` in the tree; § The batch name, the tags,
and the main session's name: `-s4w` and its re-runs, S4's re-run letters
skipping `w`; § Launch, wait, return: the re-run tag's role, `-s4w` and
`-s4w<letter>` read as S4w before `-s4<letter>`; § The start checks; § The
state file: the walk's record; Phase 3; Templates § The task blocks: an
S4w block, and the S5 block naming a walk FAIL among its sources; § The
stop conditions' list of stops stated at their own steps; § The gates;
§ Budget and caps; the reviewer and user reports; § Phase transitions),
and `skills/autopilot/scripts/run.sh` and `run.ps1` only when Step 1's
record shows the walk worker needs a flag. Then each driver passes the
flag only for an S4w launch and its resumes, as the environment variable
the skill sets says, and each driver's `--self-test` gains a launch with
the variable set, asserting the flag is passed, and one without it,
asserting it is not; `run.sh --self-test` and
`pwsh -NoProfile -File run.ps1 --self-test` stay green.

- Every rule in the Technical Approach's walk section, with the tool order
  and the check commands taken from Step 1's record.
- § Phase transitions: Phase 3 → Phase 4 waits on S4w's reply with every
  FAIL classified, or the walk's `off`, `nothing to walk`, `not walked`,
  or `cut by budget` record.
- The stops stated at their own steps become seven, the walk tool's
  absence at S4w's start among them.
- The `Acceptance: none` record, `none named; S3b is the last check` (S3
  when S3b did not run), is no longer true once a walk follows it: when
  S4w walked, the reviewer report's Acceptance line reads
  `none named; S3b is the last review, the walk follows` (S3 likewise);
  with `Walk: off`, or a walk recorded `nothing to walk`, `not walked`, or
  `cut by budget`, it stays as it is. The state file's record, written
  before S4w starts, is unchanged.

Acceptance: guards green; `check-no-model-names.sh` green; the table holds
`Walk:` with its three forms and `S4w` in `Role settings:`; § Launch,
wait, return reads `-s4w` and `-s4wb` as S4w and `-s4b` as S4; § The start
checks holds the tool check; the task block holds the local-only, own-tabs,
password, port, and listener rules.

### Step 8: Walk acceptance on a seed

Run the walk headless on a throwaway repo-mode seed under
`~/Projects/_smoke/` (a small web app on `127.0.0.1` with one page, a
one-task spec that changes that page, `Acceptance: none`,
`Standalone review: off`), with this checkout's plugin
(`--plugin-dir`) in the main session. In repo mode the workers run the
installed plugin (4.6.0; installing is out of scope), so S2 and S3 run the
old skills and the old rails hook; S4w's behavior comes from the preamble
and the task block the main session writes from this checkout, and from
the driver copy it takes from this checkout, which is what the cases
judge. Record in `docs/dry-runs/batch-m-walk-acceptance.md`
(Setup, Cases, Findings, Observations, Not exercised, Summary), committed
alone (`docs: add batch m walk acceptance record`). Cases:

1. `Walk: on` — S4w lists the flow it chose, `walk.md` and screenshots
   under the workspace, a PASS, the servers it started stopped and the
   port free after, no non-local URL in its trace, both reports' `Walk:`
   lines.
2. `Walk: off` — no S4w launched; the reports say `off`.
3. Neither tool usable (made so as Step 1's record shows) — the run stops
   before the first launch with the start check's reason.
4. A port held by another process before S4w starts — S4w's question and
   the main session's ruling recorded.

Acceptance: the four cases PASS as written, with their costs recorded;
total at most USD 40. The other changes are accepted in use, in the next
dayaku-crm batches, as 4.5.0 was.

### Step 9: Documentation (Doc-sync)

Files: the documents in Documentation impact.

Acceptance: each listed document says what the steps built; the
release-checklist's pinned guard and self-test counts match
`bash scripts/check-all.sh --self-test` (unchanged at 13 and 12, since no
step adds a guard file); `claude plugin validate --strict .` and
`claude plugin validate --strict ./plugins/kenspc` pass.

## Testing Strategy

- Every guard in main mode and with `--self-test`
  (`bash scripts/check-all.sh`, `bash scripts/check-all.sh --self-test`),
  with the new mutants in `check-run-contract.sh` and
  `check-autopilot-rails-hook.sh` shown turning their guard red.
- `claude plugin validate --strict` on the marketplace and the plugin.
- The hook's timed fixtures under half its timeout, under the CPU limit the
  guard already sets.
- Step 1's probe and Step 8's seed acceptance for the walk, the one new
  session type.
- In use: the second round, `auto`, BLOCKED classification, and benign
  breaches in the next dayaku-crm batches; their reports' new lines
  (`Standalone review:`, `Breaches ruled benign:`, `Walk:`) are where the
  maintainer reads them.

## Risks and Mitigations

- **Runs stop more often.** New stops: the walk tool check before the first
  launch, the walk tool's absence at S4w's start, the tree check in a
  review. Mitigation: the first stops before any session is paid for and
  names `Walk: off` as the way on; the second needs both tools unusable;
  the third fires only when a reviewer changed the tree. Against them, the
  benign-breach ruling and the GitHub denial remove two stops the batches
  met, and a port conflict or an app that will not start is a record, not
  a stop.
- **A batch costs more.** The walk adds a session and a second round adds
  a code-fixer and a verifier. Mitigation: the second round runs only on a
  ruling and at most once; the walk can be turned off, and a failed budget
  check before S4w cuts it as an `(optional)` acceptance case is cut; the shared suite run replaces up to five full suites with
  one; `auto` saves S3b's cost (USD 26.5 a batch on average) in every
  batch it does not trigger. The trial's reports carry each session's cost.
- **The hook denies work it should allow, or slows.** Mitigation: only
  literal targets after the named expansions are judged; the allowed
  fixtures cover `/dev/null`, `2>&1`, quoted and heredoc `>`, unjudged
  expansions, a local clone, and `gh` as a mere word; a timed fixture
  bounds the scan.
- **Interactive task-review grows heavier.** Mitigation: no new question —
  the second round needs a ruling the user already sent, and the tree
  check is silent on an unchanged tree. The shared suite run adds one
  serial suite before the reviewers, where five ran in parallel before.
- **Claude in Chrome acts in the user's real browser.** It holds the user's
  signed-in sessions, including staging. Mitigation: local URLs only, tabs
  of its own, the user's other tabs untouched, no sign-in with a real
  account; Playwright as the fallback.
- **The walk acceptance's USD 40 cap may not hold.** Cases 1, 2, and 4 of
  Step 8 each run a whole repo-mode batch (S2, S3 with its review, S6, and
  S4w in cases 1 and 4); release-checklist row 11 puts one such batch on a
  one-task seed at USD 10–20 with S3b, so three without it can approach
  the cap before the walk's own cost. Mitigation: none in the plan beyond
  the recorded costs; the maintainer may raise the cap, or let case 2 rest
  on row 11's next smoke run, whose seed writes `Walk: off` and so
  exercises the same path.
- **A headless worker may not reach Claude in Chrome.** Step 1 settles it
  before Step 7 is written; if it cannot, the walk uses Playwright alone.
- **Default-on walk changes existing specs.** A repo-mode spec with no
  `Walk:` field now walks, and on a machine with neither tool it stops at
  the start. Mitigation: the CHANGELOG and the plugin README state it, and
  release-checklist row 11's seed spec writes `Walk: off`.

## Documentation impact

- `plugins/kenspc/README.md` — § Skills: the autopilot row (the walk
  session among the roles, and S3b skipped by `off` or an untriggered
  `auto`); § Autopilot: the S4w role and `Walk:`, the `auto` value,
  BLOCKED classification, benign breaches, the second round in a worker's
  review, and the count of stops stated at their own steps (seven);
  § Run directory: `suite-run.md`, `schema-c-1.md`, the `## Round 2`
  section of `rulings.md`, and its copy of the entry grammar (the DEFER
  tail on FIX, and what happens to an entry outside the grammar); the
  task-review description: the second round, the shared suite run, the
  tree check; § Agents: code-fixer's `F` rows and regression-verifier's
  `V` IDs; § Known behavior: the hook's redirection, `gh`, and remote-git
  denials and its remaining misses, the Claude in Chrome and Playwright
  order; and, only when Step 7 adds a driver flag, the driver's
  description of its environment. Steps 2–7.
- `CLAUDE.md` — the hook paragraph (redirections, GitHub, remote git), the
  autopilot sessions paragraph (S4w; `auto`), § Subagent Review
  Architecture's Parallel MapReduce paragraphs (the shared suite run and
  the tree check around Phase 1, the second round after Phase 3, and the
  run-directory files the orchestrator now writes), § Maintenance note
  (the `canonical:second-round` block), § CONTEXT block contract (the
  files `suite-run.md`, `schema-c-1.md`, the round-2 section, the `F` and
  `V` IDs, and the `rulings.md` paragraph's copy of the entry forms, which
  gains the DEFER tail), § Non-Goals (the autopilot paragraph's "the three
  sessions hold whenever S3b runs", which now covers `auto`, and the walk
  session as a further role), § Repository scripts/ (the new checks in
  `check-run-contract.sh` and the new fixtures and mutants in
  `check-autopilot-rails-hook.sh`). Steps 2–7.
- `plugins/kenspc/CHANGELOG.md` — a `## 4.7.0 — unreleased` heading, as
  4.6.0's entry stood until its release commit, with an entry for every
  step, the default-on walk and its start check named as a change to
  existing specs.
- `docs/release-checklist.md` — row 11's seed spec gains `Walk: off`; row
  14 gains a redirection outside the roots and a `gh` call, each denied
  live. Steps 4 and 7.
- `docs/roadmap.md` — "S3b on a condition in repo mode" is rewritten as
  the trial (five batches with `auto`, the comparison, the rule for
  returning to `on`), which is planned work and stays. Step 6. The items
  this batch settles — the other five of the six, the item on a narrowed
  review's own code-fixer, and three points of "`rulings.md` follow-ups"
  (which keeps the interactive pause, the could-not-land exception, and
  the README copy) — leave at the release, not in this batch: the file's
  own rule is that an item leaves when it ships, any release is out of
  scope here, and 4.6.0's items left in its release commit.
- `README.md` — N/A for this document: the autopilot row's summary ("one
  headless session per role … two human gates") still holds, and so do the
  task-review and task-implement rows.
- `docs/dry-runs/README.md` — N/A for this document: the label convention
  is unchanged.
- `plugins/kenspc/references/plan-document-example.md`,
  `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: the plan and task formats are unchanged.

## Open Questions

1. Whether a headless `claude -p` worker can drive Claude in Chrome, and
   with which flag. Step 1 settles it; Step 7 assumes Chrome first when it
   can and writes Playwright alone when it cannot.
2. Whether `auto` becomes the default. The trial of five batches decides
   it, in a later release.
3. Whether a benign-breach ruling is also a clarification entry in the
   spec. The autopilot skill's § How the main session rules records every
   ruling under `questions answered:` and as a clarification entry naming
   the main session, which lands on the reviewer report's
   `Main-session rulings` line; the Technical Approach records a benign
   breach under `breaches ruled:` and on the `Breaches ruled benign:` line
   only. Two readings fit: the breach ruling rules no point of the spec, so
   the new section and line are its whole record; or it is a ruling like
   any other and gets both records. Step 5 states which, in § How the main
   session rules, so the two sections do not contradict each other. The
   reviewer has not chosen: the maintainer rules it before Step 5.
