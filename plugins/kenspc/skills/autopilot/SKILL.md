---
name: autopilot
description: >
  Run one batch of the kenspc chain unattended, from a spec or a brief to
  a local release preparation (无值守跑完一批): one headless session per
  role — task decomposition, implementation, standalone review,
  acceptance, fix, release preparation — driven from this session with a
  shipped driver script and cross-session messages, stopping only for the
  rulings on a brief's design table and for the tag, push, and release at
  the end. Use only when the user hands over a whole batch to run to its
  release preparation. Not for implementing one task or a task document
  (use task-implement), not for a review (use task-review), not for
  planning (use generate-plan), and never for a prompt that opens with
  "You are a headless sub-session of the batch <batch> main session <main name>, unattended."
  — that prompt is one of this skill's own workers. Trigger on: "put this
  spec on autopilot", "run this batch unattended", "take this batch to
  release", "无值守跑这批", "这批交给你跑到发布", "自动跑完这批", or
  invokes /kenspc-autopilot directly.
version: 3.0.0
argument-hint: <path to a spec or a brief>
---

# Autopilot

Run one batch of the kenspc chain unattended, from a spec or a brief to a
local release preparation, between two human gates: the decisions on a
brief's design table, and the tag, push, and release after the reports.
Five phases: Settle, Design (brief entry only), Build, Accept, Release
preparation and reports. The run happens in this session — the main
session — which starts one headless `claude -p` session per role through
the driver that ships with the skill, waits for it, answers the questions
it sends, and rules on what it produces. Nothing runs as an agent. No
review phase of the skill's own: the batch's standalone review is one of
the sessions, and the two reports at the end are what the user reviews.

| Tag | Role | What the session runs |
|---|---|---|
| S1 | design (brief entry only) | a design prompt: drafts the spec with its decision table, sends the table, finalizes and commits the spec after the decisions |
| S2 | task decomposition | `/kenspc-task <spec path>` |
| S3 | implementation | `/kenspc-task-implement <task document path>` |
| S3b | standalone review | `/kenspc-task-review review the range <baseline sha>..<HEAD sha at S3's end>` |
| S4 | acceptance | plugin mode: a seed-project acceptance with a record; repo mode: the `Acceptance:` commands |
| S5 | fix on demand | `Fix issue <ID> from run <run dir>: <one line>` for a defect the main session classified |
| S6 | release preparation | one commit per mode (Phase 4) |

One role per session, and a session is never reused across roles: the
session that proposes is not the one that decides, and the one that
implements is not the one that accepts. Why: a session that reviews its own
work reads its own intent into the code, and a session that edited the
plugin still runs the text it started with — skills and agents load at
session start, so a plugin edit is visible only to the next session.

## Trigger Phrases

Use this skill when the user hands over **a whole batch to run unattended to
its release preparation**, using phrases like: "put this spec on autopilot",
"run this batch unattended", "take this batch to release", "run the whole
batch and prepare the release", "drive this spec to its release commit",
"无值守跑这批", "这批交给你跑到发布", "自动跑完这批", "把这份 spec 无人值守跑完",
"这批跑到 release 准备为止", or invokes `/kenspc-autopilot` directly.

Avoid triggering this skill when the user:

- Asks for one task or a task document to be implemented ("implement this
  task", "run the task document", "帮我实作这个 task") — use task-implement.
- Asks for a review ("review 一下", "review my changes") — use task-review.
- Asks for a plan or a brief to be written ("plan this", "write a brief",
  "写个 plan") — use generate-plan, or generate-brief when the idea is still
  rough.
- Sends any prompt that opens with the sentence
  `You are a headless sub-session of the batch <batch> main session <main name>, unattended.`
  — that prompt is one of this skill's own workers, whatever else it says.
  Why: the skill's own workers read a prompt that names an unattended batch
  and carries this skill's trigger words, and a worker that started another
  autopilot would nest the batch inside itself.

## Quality bar

A useful run reaches the release preparation with every step's evidence on
disk — the spec committed, the task document, the commits, the run
directories, the record — asks the user only at the two gates, and stops
rather than guess on anything the locked design or the spec does not
answer. It fails the bar in two named ways: a run that narrows the
implementation to fit its budget, and a run that approves a worker's
question on the user's behalf. Why: an unattended run is trusted for what
it did not decide alone; an answer it invented is the one failure nobody
sees until the release.

## Prerequisites

- A project in a git repository. Why: every step's evidence is a commit, a
  file in the tree, or a range between two SHAs.
- `Claude Code v2.1.271 or later`, with cross-session messaging. Passing:
  `ListAgents` names this session on its first line. It fails when the
  first line is not this session's name, and the run stops with the version
  line. Why: the workers ask by message and the main session subscribes to
  their idle notices; the own-name line and the notices to headless senders
  are what that version added.
- An interactive session that can ask, started with a name, bypass
  permissions, and inbound messages accepted — the launch line:
  `claude --name <batch>-main --permission-mode bypassPermissions --settings '{"crossSessionInbound":"accept"}'`.
  Why: a worker addresses this session by name; a session that holds
  inbound messages for approval never sees a worker's question, and a
  headless worker drops a held message after a few minutes.
- The workspace, `~/Projects/_smoke/` by default (Phase 0), writable.

## Arguments

$ARGUMENTS format: PATH

- PATH: a spec (a plan document) or a brief, as Phase 0 tells them apart.

No arguments: ask for the path. In a session that cannot ask (a system
reminder to work without stopping), stop; the final message ends with
`Autopilot stopped: no path given`.

## Phase 0: Settle

**Goal**: the settings, the workspace, and the start checks — everything
the first launch needs, checked before any session is paid for.

**Inputs**: the argument file; the repository (`git rev-parse --show-toplevel`,
HEAD, `git -c core.quotePath=false status --porcelain -uall`); `ListAgents`;
the driver at `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/scripts/run.sh`;
`ps -o args= -p $PPID`.

**DONE when** the settings line (Templates § The settings line, ending
`wait <interactive|headless>`) has been printed and the state file written.

**Constraints**: this phase writes only under the workspace and `$TMPDIR` —
the driver copy, its self-test files, the state file — and nothing into the
repository. Why: every failing check is a stop, and a stop before the first
launch leaves the repository as the run found it.

### The entry kind

- A brief is what `${CLAUDE_PLUGIN_ROOT}/skills/generate-plan/SKILL.md`
  Phase 1 Step 1 recognizes; read that test there.
- A spec is a file that is not a brief and has the plan shape
  `${CLAUDE_PLUGIN_ROOT}/skills/task-implement/SKILL.md` Phase 1 Step 1
  describes: an `## Implementation Steps` section or Phase / Step headings,
  and no `**Status:**` marker.
- A task document — entries with `**Status:**` markers — stops the run,
  naming the plan it came from: `/kenspc-autopilot <plan path>`. Why: a task
  document is a spec that task decomposition already consumed; running S2
  on it would decompose a decomposition.
- Anything else stops and asks which it is. In a session that cannot ask (a
  system reminder to work without stopping), the run ends with the reason.

The skill has no detector of its own. Why: two skills already point at
generate-plan's brief test by reference, and a third detector would drift
from both.

### The `## Autopilot` section

The batch's settings are read from a section headed `## Autopilot` — the
last section of a brief, after `## Discovery Notes`, written by whoever
prepares the batch; a spec carries the same section when S1 copies it from
the brief or the user writes it there. It is a bullet list of
`- <Label>: <value>` fields under the heading, labels in English whatever
the document's language, in any order. Every field has a default and none
is required; an unknown label is ignored and named on the line after the
settings line; a known label whose value is outside its grammar is the
settings stop (The start checks). Why no required field: the default budget was chosen when
the method was fixed, a supplied spec counts as approved, and a required
field would turn every spec-entry run into a question; the printed
settings line puts the defaults in front of the user before any session
starts, and a user who wants a smaller budget writes the field.

| Label | Value | Default |
|---|---|---|
| `Baseline:` | a commit: a SHA, or `HEAD` | HEAD at the start of the run |
| `Mode:` | `repo` or `plugin` | detected (below), else `repo` |
| `Plugin:` | a plugin directory name under `plugins/` (plugin mode, several plugins) | unset |
| `Version:` | `none`, or a version string | `none` |
| `Budget:` | `USD <n>` | `USD 200` |
| `Caps:` | `<n> sessions, <m> resumes` | `16 sessions, 8 resumes` |
| `Allowed files:` | paths, one per line or comma-separated | empty |
| `Zero diff:` | paths for the zero-diff check | empty — no zero-diff check |
| `Byte-identity exceptions:` | free text | empty |
| `Acceptance:` | `none`, or one sub-bullet per case: a command or a case description, its PASS criterion after ` — PASS: `, and `(optional)` at the end of a case that may be cut | `none` |
| `Acceptance record:` | a path (repo mode) the S4 results are written to | unset |
| `Release preparation:` | `default`, `keep`, or sub-bullets of instructions | `default` |
| `Must read:` | paths every worker reads first | empty |
| `Challenge seeds:` | sub-bullets S1 argues against | empty |
| `Prior specs:` | `<hash>^:<path>` entries, read with `git show` | empty |
| `Workspace:` | a directory | `~/Projects/_smoke/` |

### The mode and the plugin directory

The mode is `plugin` when the repository root holds
`.claude-plugin/marketplace.json` and at least one
`plugins/*/.claude-plugin/plugin.json`, else `repo`; `Mode:` wins over the
detection either way. In plugin mode the plugin directory is
`<root>/plugins/<name>`: `<name>` from `Plugin:` when given, else the single
`plugins/*/` that holds a `plugin.json`. Several plugins and no `Plugin:`
is a question: which one. In a session that cannot ask (a system reminder
to work without stopping), the run ends with the reason. The value is
passed absolute, from `git rev-parse --show-toplevel`. Why: the layout
names both files, and a marketplace with several plugins is a release of
one of them, which nobody but the user can name.

### The workspace

The workspace is `~/Projects/_smoke/` by default; `Workspace:` relocates
the whole tree; `$TMPDIR` is for anything else.

```
<workspace>/
  _prompts/     the copied driver <batch>-run.sh, <batch>-preamble.md,
                <batch>-<tag>-task.md, and the assembled <batch>-<tag>.md
  _logs/        <tag>.json  <tag>.err  <tag>.pid  <tag>.exit  <tag>.session
                <batch>-timeline.log  <batch>-costs.txt
                <batch>-state.md  <batch>-report.md
  <batch>-*     seed projects (plugin mode)
  .trash/       discarded directories, moved here as <name>-<timestamp>/
```

Why outside the repository: a plugin-mode seed is a clone that cannot live
inside the repository it clones, and the workers' logs are not the
repository's to track.

The driver is copied from `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/scripts/run.sh`
to `_prompts/<batch>-run.sh`, and the copy's `--self-test` is run once,
with `AUTOPILOT_CLAUDE` empty on that command
(`AUTOPILOT_CLAUDE= bash _prompts/<batch>-run.sh --self-test`). Why the
copy: a plugin-mode S3 may edit the shipped driver itself, and a running
batch keeps launching with the text it started with. Why the variable
empty: the self-test launches whatever the variable names, and a value
exported for the workers — a `claude` outside `PATH` — would stand in for
the stub: paid sessions at every start, then a stop on the flag check,
since the real executable echoes nothing to stderr.

### The batch name, the tags, and the main session's name

- The batch name is the argument file's base name without its extension.
- Tags: `<batch>-s1`, `-s2`, `-s3`, `-s3b`, `-s4`, `-s5`, `-s6`; a re-run
  of a step `-s4b`, `-s5b`, a further one the next letter (`-s4c`), and
  the narrowed review after a fix `-s3c`, a re-run of S3b; a resume
  `<tag>-r<k>`, where `<k>` counts that step's resumes from 1 whatever
  their reason — an answer, a death, a raised cap — so a step resumed for
  its answer and then dead is resumed under `-r2`, that being its first
  death. Why unique by construction: the timeline, the costs file, and the
  record name a stable tag, a resumed session keeps its own session id
  under a new tag, and a tag used twice would have the driver refuse the
  launch while the earlier worker runs and overwrite its `.json`,
  `.session`, and `.pid` once it has ended.
- The main session's name is `<batch>-main`, the name the launch line gives
  it. When the listed name differs — the session was started otherwise —
  the run uses the name `ListAgents` prints on its first line and records it
  in the state file. Why: every worker addresses the main session by that
  name before it starts, and the listing's first line is the one source.

### The wait path

Decided once here and recorded in the settings line. `ps -o args= -p $PPID`
from the Bash tool prints the command line of the process that runs this
session; when one of its arguments is `-p` or `--print` — a whole argument,
`ps -o args= -p $PPID | tr ' ' '\n' | grep -qxE -- '-p|--print'`, since
`--permission-mode` and `--plugin-dir` hold `-p` as a substring, and a
substring test would read a session started as Prerequisites says as
headless — the session is headless. A
headless run never subscribes: it polls `<tag>.exit` with the driver form of
the wait snippet, one tool call of about a minute per iteration. An
interactive run subscribes to each worker with `notify_when_idle` and ends
its turn. Why: a headless session that subscribed received the notice not
between its tool calls but as a new turn after its final reply, its JSON
result then being that turn's last message — a headless run that rested on
the notice would end before its worker did.

### The start checks

Passing: every line below holds. It fails on the first that does not, and
the failure is a stop whose final message ends with
`Autopilot stopped: <reason>`. In a session that cannot ask (a system
reminder to work without stopping), the run ends with the same message.

- The argument file exists and is a brief or a spec.
- Every `## Autopilot` value is in its grammar (the table above); a value
  outside it — `Budget: 60` without `USD`, `Caps: 10`, `Mode: Plugin` — is
  the settings stop, naming the field and the value. Why a stop and not
  the default: the field is one the user wrote, and a run that read it as
  absent would spend the default budget the user meant to lower.
- The working tree is clean except a brief given as the argument when it
  is untracked (`git -c core.quotePath=false status --porcelain -uall`).
  An untracked spec is a stop naming the commit to make first,
  `docs(plans): add batch <name> spec`. Why: an untracked brief is how
  generate-brief leaves one, and S1 commits the spec it drafts from it;
  anything else in the tree would be swept into a worker's commit under
  its message — a supplied spec included, since it skips Phase 1 and no
  step commits it, while the state file and the reviewer report name its
  hash and repo-mode S6's default `git rm` fails on an untracked path.
- HEAD equals `Baseline:`; otherwise the stop names both.
- `ListAgents` names this session on its first line; otherwise the stop
  gives the version requirement.
- The command line `ps -o args= -p $PPID` prints (The wait path) carries
  `crossSessionInbound` with `accept` — the launch line's `--settings`
  argument. When it does not, ask whether a settings file accepts inbound
  messages for this session: `yes` continues, `no` is a stop naming the
  launch line. In a session that cannot ask (a system reminder to work
  without stopping), the run ends naming the launch line. Why a question
  and not a stop: managed or user settings can set the value where the
  command line does not show it. Why checked before the first launch: a
  main session that holds inbound messages never sees a worker's question
  — the worker waits its thirty minutes, stops with the question in its
  final message, and is resumed with the answer — thirty minutes and a
  resume per question, with no stop naming the cause.
- The workspace is writable.
- An existing `_logs/<batch>-state.md` names this repository on its
  `repository:` line; one that names another is a stop naming both. Why:
  the workspace is shared by every repository on the machine, and two plan
  files with one base name would share the state file, the tags, the
  logs, and the prompts — the run's memory — while `Workspace:` keeps them
  apart once the stop has named the clash.
- Every `Must read:` path exists, and every `Prior specs:` entry resolves
  (`git cat-file -e <hash>^:<path>`); otherwise the stop names the path or
  the entry. Why: both are written into every worker's preamble, and a
  typo there is found by the first paid worker, which then asks or goes
  on without the material.
- The driver copy's `--self-test` prints `self-test passed` and exits 0.
- In plugin mode, the plugin directory holds a `plugin.json`.

Why before anything is written: an unattended run on the wrong base or a
dirty tree is spent money, and every check is a condition a worker assumes.

### The state file

`_logs/<batch>-state.md` holds the settings line, the repository root, the
current step and its tag, each session's tag, id, cost, and result, the
questions answered, the
stops, the clarification numbers recorded in the spec, and the next action.
It is rewritten at every transition and re-read, with `<tag>.exit`, on
every wake — a notice, a message, a user reply — before the run acts. Why:
a wake starts a new turn whose only reliable memory is a file, and a long
batch compacts the conversation; the state file is what lets the resumed
turn continue from the artifact rather than from the wording.

```
Autopilot settings — …                      (the settings line)
main session: <name>   repository: <root>   baseline: <sha>   spec: <path> (<hash> once committed)
step: <S<n>>  tag: <tag>  pid: <pid>  session: <id>  launched: <time>  head: <sha at the launch>
sessions:
  <tag>  <session id>  USD <cost>  <success|subtype|dead|running>
questions answered:
  <tag>: <one line> → <one line>
stops: <reason> (<time>)
clarifications recorded: <numbers>
next: <the next action>
```

## Phase 1: Design (brief entry only)

**Goal**: a spec with every design decision made, committed.

**Inputs**: the brief; the preamble and the S1 task block (Templates).

**DONE when** the spec's commit hash is in the state file. A supplied spec
skips this phase: it counts as approved.

The flow:

1. Launch S1 as Phase 2 launches every worker: the driver copy, the launch
   line, the wait.
2. S1 drafts the spec — the shape of a decided spec with an empty decision
   column, a design table of numbered questions with options and a lean per
   row — and sends one `question` message carrying the compact table
   (number, one-line question, options, lean) and the draft's path.
3. Print the table to the user as received, with the draft's path, and ask
   for a decision per number; "use your leans for the rest" is an accepted
   answer. A partial answer is followed by the remaining rows asked again
   with their leans, until every row is decided or the rest delegated. A
   decision that contradicts a locked point is refused with the point
   named and asked again. Why: the table is the artifact S1 produced and
   the user decides on it as it stands; the locked design is immutable, so
   a contradiction is not a decision the run can carry; the delegated
   remainder keeps a long table from stalling a user who trusts the leans.
4. Send S1 one message — first line `rulings <batch>: <n> rulings`, then
   one row per decision, `M<n>: <decision>` for the mismatches table and
   `D<n>: <decision>` for the architecture table, ending with the fixed
   instruction: fill the `Ruling` column, set the status line to ruled,
   run the pointer-label grep, commit the spec alone as
   `docs(plans): add batch <name> spec`, reply with the hash, and stop.
   When S1 has stopped on the timeout (The message protocol), the same text
   is the body of the resume prompt, under its `answer <tag>:` first line.
5. Record the hash S1 replies with in the state file.

S1's task block carries: the draft-spec task — the shape of a decided spec
with an empty decision column, the design table's options and leanings,
`Challenge seeds:` to argue against, the rule that the spec's numbered
labels are pointers for the implementer and never appear in the files the
batch produces, with the grep that checks it, and "send the compact table
to <main name> and wait" — and the note that the reminder printed on a
write under `docs/plans/` concerns plan generation and is to be ignored,
since the spec is written by design outside that skill. Why not dodge the
reminder: it is a note, not a gate, and a write made through a shell to
avoid it would hide the write from the trace the acceptance reads.

The shape of a decided spec, which the block spells out since a brief-entry
batch with `Prior specs:` empty has no earlier spec to copy: the plan
document `${CLAUDE_PLUGIN_ROOT}/references/plan-document-example.md` shows
— `## Objective`, `## Background`, `## Implementation Steps` with Phase /
Step headings, `## Documentation impact` (the durable documents the steps
make stale, or `N/A — <reason>`), `## Testing Strategy`, `## Risks and
Mitigations`, `## Open Questions` — plus the sections this batch reads: the
locked design as numbered points, the design table, out of scope,
constraints, a `## Clarifications during implementation` section left
empty, and `## Autopilot` copied from the brief. Why these: the entry kind
is judged by the plan shape; task decomposition asks for a correct path
when `## Implementation Steps` is missing — a question the spec cannot
answer, so a stop after a paid session — and writes a Doc-sync task only
from a Documentation impact section; the preamble reads the locked design,
out of scope, and constraints by section; and the main session commits its
clarifications into the spec.

In a session that cannot ask (a system reminder to work without stopping),
every row takes its lean, the rulings message says
`lean adopted (the session could not ask)` per row, and both reports say so
row by row. Why: taking the leans is the same delegation a user gives with
"use your leans for the rest", and the record of it is what makes the run
reviewable.

## Phase 2: Build

**Goal**: the batch implemented and reviewed — S2, S3, S3b in order.

**Inputs**: the spec (committed); the preamble; the driver copy; the state
file.

**DONE when** S3b's verdict is PASS, or every HIGH and every row-3 or row-5
FAIL is classified, and the zero-diff check has printed nothing.

**Constraints**: the main session commits nothing but clarification entries
in the spec, `docs(plans): record clarifications settled after <step>`; the
workers make every other commit. Why: the commits are the workers' evidence,
and a main session that edited code would be reviewing its own work.

### Launch, wait, return

Every worker is one launch, one wait, one return.

- **The launch.** Assemble `_prompts/<batch>-<tag>.md` from the preamble
  and the task block; run the driver copy with the environment it needs —
  `AUTOPILOT_LOGS=<workspace>/_logs`, `AUTOPILOT_BATCH=<batch>`,
  `AUTOPILOT_BUDGET_USD=<remaining>`, and `AUTOPILOT_PLUGIN_DIR=<plugin
  directory>` in plugin mode — with the repository root as the worker's
  cwd; print `S<n> started — <tag> pid <pid> session <session-id> — <prompt path>`
  (the pid and the session id from the driver's `started` line, or from
  `<tag>.pid` and `<tag>.session`); rewrite the state file, its step line
  carrying HEAD at the launch. A driver that
  exits non-zero has started nothing: its message on stderr is the stop's
  reason — or, when it names an earlier worker under the tag still
  running, that worker is the one to wait for, by its `<tag>.exit`, once
  `ps -o args= -p <pid>` has shown the driver copy's own command line
  with the tag (`<batch>-run.sh <tag> …`); a pid whose command line is
  another program's is a leftover from a reboot, so the run removes
  `_logs/<tag>.pid` and launches again — and
  reading `<tag>.pid` and `<tag>.session` applies only once the `started`
  line has been printed. Why: the two files can hold an earlier launch's
  values or none, so a run that read them after a refused launch would
  wait on a worker that does not exist, or resume beside one that does;
  and a pid the driver did not start writes no `.exit`, so a run that
  waited for it would wait until the user intervened.
- **The wait, interactive.** Subscribe to the worker with `SendMessage`
  `notify_when_idle` right after the launch and end the turn. On every wake
  re-read the state file and `<tag>.exit`. With no `.exit` and a live pid,
  subscribe again and end the turn. A refused subscription means the worker
  is not listed, so read `.exit`: present, the worker finished; absent
  with the pid gone, it died; absent with the pid live, the worker is still
  starting — the driver returns as soon as it has forked, and the worker
  is listed only once `claude` has booted, seconds later — so wait one
  driver-form iteration of the wait snippet and subscribe again, for as
  long as the pid lives. A notice that reports the subscription expired
  (twelve hours) runs the same check. The notice is the wake and `.exit`
  the evidence. Why: a subscription made after the worker exited was
  refused, a notice can be lost, early, or expired, and a transition that
  rests on the notice's wording rests on nothing on disk; reading the
  artifact on every wake turns each of those into a delay, and the retry
  keeps a worker that is still booting from being read as dead and
  resumed beside itself.
- **The wait, headless.** Never subscribe. Poll with the driver form of the
  wait snippet, one tool call of about a minute per iteration, until
  `<tag>.exit` exists or the pid is gone.
- **The return.** Print
  `S<n> returned — exit <code>, cost USD <c>, <success|subtype> — <json path>`
  from `<tag>.exit` and `<tag>.json`; upsert `<tag> <session_id> <total_cost_usd>`
  into `<batch>-costs.txt` — replace the line that carries the same session
  id, else append; a resume's line replaces its predecessor's, since a
  resumed session's JSON carries the whole total; rewrite the state file.
  A `<tag>.json` that is empty or not JSON — an executable that could not
  start, a worker killed before its result — gives the return line
  `cost USD unknown` and `no result` in the subtype's place, gets no costs
  line, since a `0` there would read as a free session, and counts as dead
  (Death and resume).
  Before the next step, read the JSON's `result` for
  `## Question for the main session`: a return that carries it is the
  timed-out question (The message protocol), not a finished step. Why: a
  worker that waited out its thirty minutes exits like one that finished,
  and its missing artifact would otherwise be found one step later.

### A worker's question at a gate

S2 asks at generate-task's confirmation (`Confirm, or adjust tasks before
writing?`) and S3 at task-implement's batch gate (`Proceed with automated
implementation?`); both arrive as `question` messages. The confirmation is
answered from the spec: `yes` when the task list matches the spec's steps —
every step has a task, no task is outside the spec — and a mismatch is a
question to the user, never `yes` on the user's behalf. A question the spec
does not answer is a stop, with the question quoted. In a session that
cannot ask (a system reminder to work without stopping), a question the
spec answers is answered from the spec, and one it does not answer ends the
run with the question quoted. Why: the spec is the approved artifact, and
an answer beyond it is a decision the user has not made.

### The message protocol

- Before every send, `ListAgents`; when two rows carry the name, address
  the row whose start time matches the launch by its `[ref]`. Why: the
  duplicate-name rename does not check a headless session's name at
  startup, so an earlier batch's worker or a resumed session can share a
  tag's name.
- A worker's question is one message whose first line is
  `question <tag>: <one line>` and whose body gives the context, the
  options, and its suggested answer.
- The answer is one message whose first line is `answer <tag>: <one line>`
  and whose body is the decision, quoting nothing the worker sent. Why: the
  first line is what the transcript search finds, and the suggested answer
  is what makes the decision a one-line reply.
- Questions are answered in arrival order; one worker is live at a time in
  this topology. A message from any other session — a user-level hook's —
  is recorded as an observation in the state file and not answered.
- Messages carry summaries and paths, never a report's text. Why: a message
  over about a million characters is refused, about thirty sends in a burst
  to one session are refused, a receiver queues fifty and drops identical
  repeats; a worker with a table to show writes it to a file and sends the
  path.
- A delivery notice reporting that the first message to a worker was held
  or refused is a stop naming the settings precedence: managed settings,
  then the `--settings` flag, then user settings; a project or local `hold`
  or `refuse` applies when stricter. Why: no probe message is sent at the
  start, so the first real message is where a stricter setting shows.
- A worker that got no answer in thirty minutes has put its question under
  `## Question for the main session` in its final message and stopped. The
  answer goes to it as a resume under the step's next `<tag>-r<k>`: a
  prompt whose first line is `answer <tag>: <one line>` and whose body is
  the decision, counted as a resume.

### The verdict loop after S3b

S3b's Schema F verdict decides the next step. Passing: PASS, on to Phase 3.
FAIL, or PARTIAL with HIGH rows deferred: each HIGH row and each row-3 or
row-5 FAIL is classified by the main session as a plugin defect — S5 from
that row, task block `Fix issue <ID> from run <run dir>: <one line>`, then a
narrowed review, `-s3c`, over `<S3b HEAD>..<fix HEAD>` — or accepted as a
deferral with
a reason recorded as a clarification in the spec. The second narrowed
review that still FAILs is the "guards red twice in a row" stop. DEFERRED
MEDIUM and LOW rows are classified once — a fix in S5, or a roadmap
candidate listed in the reviewer report — and recorded as a clarification.
Why: the round count is where the stop conditions put it, and a deferral
without a recorded reason is a finding nobody owns.

### The zero-diff check

After S3b, `git diff --stat <baseline> HEAD -- <Zero diff paths>` prints
nothing; anything printed is a stop naming the paths. With `Zero diff:`
empty there is no check. Before the first launch, each path is resolved
against the baseline, `git cat-file -e <baseline>:<path>`; a path absent
there is named on the line after the settings line and in the report's
zero-diff field. Why the check: the paths a batch promised not to touch
are the one promise a review does not verify. Why the resolution, as a
note and not a stop: `git diff` prints nothing for a path that matches
nothing, so a typo or a path renamed since the section was written would
pass as unchanged with nothing compared; and a path absent at the baseline
can be a guard against its creation, which the check still catches, since
a file created since the baseline is a diff.

### Budget and caps

Before each launch:

- Spent = the sum over sessions of each session's last cumulative
  `total_cost_usd`, from `<batch>-costs.txt`, plus, once S4 has returned
  in plugin mode, the trial run's and the acceptance cases' costs from the
  record — the nested
  sessions S4 launched are in no worker's JSON and on no costs line. A
  case whose record line carries no parseable cost — S4 died mid-record,
  or its resume wrote none — counts as `unknown`, named on the report's
  acceptance line and its total-cost line, and adds nothing to spent, as
  an unreadable JSON does (The return); a `0` there would read as a free
  case.
  Projected = the largest
  single-session cost of this batch so far, or the budget divided by six
  before the first session. When spent + projected > budget, stop and ask
  "raise the budget to how much?" with spent, projected, and the remaining
  steps; the answer sets the budget for the rest of the run and is recorded
  in the state file and the reports, not in the brief. In a session that
  cannot ask (a system reminder to work without stopping), the run ends with
  those numbers. Why: per-step estimates drift with every model generation
  and would be numbers hard-coded in a prompt; the batch's own sessions are
  the only evidence in the run.
- Every launch passes `--max-budget-usd` with the remaining amount — the
  budget minus spent — through `AUTOPILOT_BUDGET_USD`. A resume passes the
  same remaining amount, computed the same way: the ended session's last
  cumulative `total_cost_usd` is already on its costs line and so already
  in spent, and nothing is added back for it, since the cap bounds only
  what the resumed invocation spends from here — a probe with a resumed
  session showed the flag counts the invocation's own spend and not the
  session's earlier total. When the resumed session returns, its JSON's
  cumulative `total_cost_usd` replaces the session's line in
  `<batch>-costs.txt` (The return), so spent counts the session once. Why:
  the check before a launch bounds nothing already running, and one
  session has spent a large share of a batch before; a resume cap raised
  by the earlier total would let the session spend past the batch by that
  much.
- `Caps:` (`16 sessions, 8 resumes` by default) exceeded is a stop that asks
  for a new cap. In a session that cannot ask (a system reminder to work
  without stopping), the run ends with the counts. Why: the session cap is
  one and a half times the largest batch run so far, and the field
  overrides both counts.

### Death and resume

A step's session is dead when its pid is gone and `<tag>.exit` is absent
ten seconds later, or when its JSON is empty, not JSON, or of a subtype
other than `success`. It is
resumed once, under the step's next `<tag>-r<k>`, with the continue prompt
`Continue the task in your prompt from where you stopped; your last message was cut short.`;
a second death of the same step is a stop. A live pid is never killed and
never judged hung: when asked, the main session reports the pid, the size
of `<tag>.err`, the mtime of the transcript named by `<tag>.session`, and
`git log -1 --format=%ct` in the worker's cwd. Why: a test suite or a long
implementation is silent for longer than any timeout a prompt would pick,
and a killed worker leaves a half-applied task.

A worker ended by its cap — a JSON subtype other than `success` that
names the budget — is the budget stop, and counts as the step's first
death too: its resume after the raise is the one resume the death rule
allows, and a later death of the resumed session is the "dead twice"
stop. After the user raises the
budget it is resumed under the step's next `<tag>-r<k>` with the continue
prompt and the new remaining amount as its cap — the raised budget minus
spent, in which the ended session's last cumulative total already counts
— counted as a resume. Every resume, whatever ended the session, passes
the batch's remaining amount this way and never that amount plus the
session's earlier total (Budget and caps). Why: the cap is the only bound
on a session already running, and the step it ended is the one to
continue.

## Phase 3: Accept

**Goal**: the acceptance run, and every FAIL classified.

**Inputs**: the `Acceptance:` field; the S3b HEAD; the preamble; in plugin
mode the plugin directory and the workspace for seeds.

**DONE when** every case has a result in the state file and every FAIL a
class, or `Acceptance: none` has been recorded as
`none named; S3b is the last check`.

**Plugin mode.** S4 runs a seed-project acceptance: a trial run of a seed
first, to confirm the path under test is reachable, then one case per run,
every driver reply named in the record; the record is
`docs/dry-runs/<batch>-acceptance.md` with the fixed sections Setup,
Independence, Cases, Findings, Observations, Not exercised, Summary. S4's
task block carries the cases with their PASS criteria, the driver line —
under the nested tags `<tag>-trial` for the trial run and `<tag>-case<n>`
for case n, `<tag>` being S4's own, since a nested launch under a worker's
or a resume's tag is accepted once that worker has ended and overwrites
its `.json`, `.session`, and `.pid`, which Phase 4 reads; with the
batch's remaining amount as `AUTOPILOT_BUDGET_USD` for the first
nested launch, lowered by each finished nested session's cost — the
trial's included — before the next, since
S4's own cap bounds none of them and a cap the cases shared would let each
case spend it once — and the record path; each
case's line in the record carries its cost, the sum of its nested sessions'
last cumulative `total_cost_usd`, and the trial run's line under Setup its
own; S4 is itself headless and waits for its
nested sessions with the driver form of the wait snippet. Why the trial
run: a seed that cannot reach the step under test hides that step behind
its own failure.

**Repo mode.** An S4 worker runs each `Acceptance:` command at the S3b HEAD
in the repository, one command per Bash call, and replies with each
command, its exit code, and the last twenty lines of its output; the
results go into the reviewer report's acceptance lines. No file is written
into the repository unless `Acceptance record:` names a path; then S4's
task block also tells it to write the same lines — each command, its exit
code, the last twenty lines — to that path and commit the file alone,
`docs: add batch <name> acceptance record`, and an `-s4b` re-run rewrites
its case's lines there in a commit of its own,
`docs: update batch <name> acceptance record`. With
`Acceptance: none`, no S4 session starts and the report's acceptance line
reads `none named; S3b is the last check`. Why: a product repository has no
place for a record the plugin invented, and the report is where the user
reads the run; where the user names a path, S4 is the session that ran the
commands, a worker may write into the repository, and a file left
uncommitted would be swept into a later commit under its message.

**Classification.** The main session classifies each FAIL: a plugin defect
(an implementation defect, in repo mode) → S5 fixes it, then the case is
re-run in a new S4 session `-s4b` that runs only that case; a behavior
deviation → a roadmap line drafted for the release commit (plugin mode) or
a reviewer-report line (repo mode); an observation → recorded. The same
case still failing after two fixes is a stop. Every classification is a
clarification entry in the spec, committed by the main session as
`docs(plans): record clarifications settled after <step>`. Why: the record
separates evidence from judgment — S4 records, the main session decides —
and the spec's clarification section is where decisions made during
implementation live.

S5's task block: the classified defect, the case to make pass, and "commit
the fix alone".

**The narrowing rule.** Cases marked `(optional)` may be cut when the budget
check fails, in the order listed, with Not exercised recorded. An unmarked
case that cannot be run is a stop. Implementation is never narrowed. Why:
acceptance is the part of a batch a budget may shorten with the shortfall
on record; an implementation cut to fit a budget is a different batch.

## Phase 4: Release preparation and reports

**Goal**: S6's commit and the two reports.

**Inputs**: `Release preparation:`, `Version:`, the mode; the state file;
`<batch>-costs.txt`; every worker's JSON.

**DONE when** the final message carries both reports and ends with
`Autopilot finished — <baseline sha>..<last sha>`, and the reviewer report
is also at `_logs/<batch>-report.md`.

**Repo mode.** `Release preparation: default` — S6 makes one commit,
`docs: remove batch <name> plan and tasks`, that `git rm`s the batch's plan
and task documents and touches no version and no CHANGELOG. `keep` — no S6;
the documents stay. A list of instructions — S6 runs them as its task
block, after the default removal unless the list says `keep`.
`Version: <string>` in repo mode is passed to S6 as an instruction to bump
wherever the repository's CLAUDE.md says versions live, and is otherwise
ignored with a note after the settings line. Why: a product repository's
CHANGELOG has a convention the plugin cannot know; the removal and no
version is the default, and the field carries the rest.

**Plugin mode.** The repository's release checklist
(`docs/release-checklist.md` when it exists) and CLAUDE.md's release
convention govern S6's task block: the CHANGELOG's `— unreleased` heading
gets today's date; the plugin manifest's version becomes `Version:`; the
manifests' descriptions name the new capability; the checklist's counting
rows follow; the roadmap's shipped items leave and its heading names the
next minor; the batch's plan and task documents, and its brief when git
tracks it, are `git rm`ed — an untracked brief, the brief-entry case since
S1 commits the spec alone, is left where it is and named in both reports as
the user's to commit or discard, since `git rm` on an untracked path fails
and the rails allow no other deletion inside the repository; one release
commit in the repository's convention; the pre-flight block runs
and its two count lines are in S6's reply; no tag, no push. With
`Version: none` in plugin mode, S6 makes the removal commit only, and the
reports say the release was not prepared. Why: stack-agnostic in form — the
checklist and CLAUDE.md are read — and the repository's own procedure in
substance.

The zero-diff check runs again before S6 is launched, over
`<baseline>..HEAD` as it then stands, and not after S6's commit. Why
before: S4 and S5 commit after the check that follows S3b, so their commits
need one of their own; and in plugin mode the release commit edits, by
design, paths a zero-diff list may name — a plugin repository's roadmap or
manifest — so a check run over the release commit would stop a run whose
release preparation was right.

**The reports**, both in the final message:

- `## User report` — the conversation's language, at most one page: what
  the batch built, the release commit, what needs the user (tag, push,
  release; any stop or deferred item), and the cost.
- `## Reviewer report` — English, the fixed fields in this order (Templates
  § The reviewer report). The total-cost line reports the measured sum of
  the workers' last cumulative `total_cost_usd`, plus, in plugin mode, the
  trial run's and the acceptance cases' costs from the record as a second
  measured term (the
  nested sessions S4 launched), plus the main session's own cost as an
  estimate labeled "estimated": its turn count (launches + wakes + answers
  + the final turn) × the mean cost per turn across this batch's workers
  (each worker's `total_cost_usd` ÷ `num_turns` from its JSON), with the
  basis stated on the line; `/cost` in this session may replace it. Why:
  an interactive session has no JSON result, so its cost is a number with
  a stated basis or nothing, and a total without it would be short by one
  session — and without the record's costs, short by the whole acceptance
  whose cases the same report lists with their costs.

The reviewer report is built from the state file, not from memory, and also
written to `_logs/<batch>-report.md`; the state file records its last
transition; the final message ends with
`Autopilot finished — <baseline sha>..<last sha>` and the sentence that the
tag, the push, and the release are the user's. In a session that cannot
ask (a system reminder to work without stopping), the run ends the same
way: the two reports and the finish line, with the tag, push, and release
left to the user.

## Templates

Each block below is copied as it stands, with its placeholders filled.

### The preamble

Written once per batch to `_prompts/<batch>-preamble.md`, in English,
whatever the conversation's language. Why English: the spec, the commit
messages, and the code artifacts are English by the repository's rules, and
a worker copies task text into them. Why self-contained: a worker has no
earlier batch to look at, so "as an earlier batch did" names nothing it can
read.

````
You are a headless sub-session of the batch <batch> main session <main name>, unattended.

## 1. Role and the ask protocol

Your role: <role>. The main session, `<main name>`, started you through a
driver and is waiting for you; it decides every question you send and
records the answer. When you need a decision or more material, or a skill
you run reaches a point where it would ask the user (the confirmation in
/kenspc-task, the batch gate in /kenspc-task-implement, the approval in
/kenspc-plan), send `<main name>` one message with SendMessage whose first
line is

    question <tag>: <one line>

and whose body gives the context, the options, and your suggested answer.
Then wait in place, one Bash call per iteration:

    n=0; until [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done

for at most thirty calls, about thirty minutes. The answer arrives as a
message from another session between two of your tool calls; its first
line is `answer <tag>: <one line>`. Continue as it says. When no answer
has arrived after thirty calls, put the question under a section
`## Question for the main session` in your final message and stop; the
main session resumes you with the answer. Do not approve anything on the
user's behalf because the run is unattended: an answer you invent is the
one failure this batch cannot detect. Messages carry summaries and paths,
never a report's text: a report or a full table goes to a file — under
<workspace>/_prompts, or in the repository when it belongs there — and the
message names its path, since a message over about a million characters
is refused and so is a burst of about thirty sends.

## 2. Read first

- The specification: <spec path>   (at brief entry: the brief, <brief path>)
- Prior specs: `git show <hash>^:<path>` for each entry of Prior specs:
- <each Must read: path>
- The repository's CLAUDE.md

## 3. Safety rails

Write only to the repository at <repository root>, the workspace at
<workspace>, and $TMPDIR. No git push, no git tag, no release. No resource
the brief does not name — no database, no network service. No secrets in
any file or message. No recursive rm in any spelling — rm -r, rm -rf,
rm -fr, rm -R: discard by mv into
<workspace>/.trash/<name>-<timestamp>/, created when missing; deletions
inside the repository only through git rm. Any breach is a stop: report it
and end.

## 4. The locked design

<one line per numbered point: its number and topic — read them in
<file> § <section>>. The points are immutable; a question that reopens one
is refused.

## 5. Out of scope

<the spec's section by name, and its content in one paragraph>

## 6. Constraints

<the spec's constraint sections by name>, and the repository's CLAUDE.md.
Allowed files: <the Allowed files: paths — the files this batch may change; a file outside them is a forbidden file>.
Byte-identity exceptions: <the Byte-identity exceptions: text — the only byte-identity sections this batch may edit>.
````

The last two lines of § 6 are written when their fields are set and
omitted when empty. Why in the preamble: it is the only text a worker
reads, so a field that reaches no preamble binds no worker and trips no
stop; the zero-diff check verifies the paths a batch must not touch, and
these two fields bound what it may.

### The task blocks

`_prompts/<batch>-<tag>-task.md` per launch; the launched prompt
`_prompts/<batch>-<tag>.md` is the preamble followed by the task block. Each
block below is copied as it stands, its placeholders filled the way the
preamble's are; text in `[square brackets]` — a line, or words inside one —
is written when the field it names is set and omitted when the field is
empty; a bracket the bullet above a block ties to a launch instead — the
first S4 run, or its `-s4b` re-run — is written for that launch alone; the
brackets of an indented command line, the wait snippet's `[ -f … ]`, are
the shell's and are copied as they stand. Why one fixed
template per role: the task block is the only part of
a prompt that varies between launches, so a template keeps the variation to
the placeholders, and a reader of the record who knows the template reads a
launched prompt by its filled values alone.

- **S1** — the brief entry only (Phase 1). `<brief path>` is the argument;
  `<spec path>` is where S1 writes the spec, `docs/plans/<batch>.md`; the
  seeds are the brief's `Challenge seeds:` sub-bullets, the bracketed lines
  omitted when the field is empty. The block spells out the shape of a
  decided spec, since with `Prior specs:` empty the worker has no earlier
  spec to copy; the decisions arrive later as the `rulings` message, not in
  this block.

````
## Task: draft the specification for batch <batch>

Read the brief at <brief path> and write the specification at <spec path>
with the Write tool — a decided spec whose Ruling column is still empty.
The reminder printed on a write under docs/plans/ concerns plan generation
and does not apply here: the spec is written by design outside that skill,
so read the note and go on.

The shape, section by section:

- `## Objective`, `## Background`, `## Implementation Steps` with Phase /
  Step headings, `## Documentation impact` (the durable documents the steps
  make stale, or `N/A — <reason>`), `## Testing Strategy`, `## Risks and
  Mitigations`, `## Open Questions` — the sections of a plan document. The
  Open Questions section says that a question during implementation goes
  to <main name> by message.
- `## Locked design`: the brief's numbered points, copied as they stand.
  They are immutable; the spec reopens none of them.
- `## Design decisions`, opening with the status line `Status: draft`, then
  two tables with the columns Question, Options (each with its
  consequence), Lean, Ruling — the last empty. `### Mismatches between the
  locked design and the repository`: one row per point the repository or
  the harness cannot carry as written, numbered M<n>. `### Architecture
  choices`: one row per choice the locked design leaves open, numbered
  D<n>. A lean is your recommendation in one sentence, with its reason.
- `## Out of scope` and `## Constraints`: the brief's, carried over and
  made precise for this repository. Constraints also carries the pointer
  rule: the spec's numbered labels — the points' numbers, M<n>, D<n>, the
  clarification numbers — are pointers for the implementer and appear in
  no file the batch produces, checked by a grep you write into the
  section, whose pattern matches those label forms and which prints
  nothing over the files the batch may change, at the baseline, and many
  lines over the spec itself, so it can fail.
- `## Clarifications during implementation`: present and empty.
- `## Autopilot`: copied from the brief as it stands.

[Before you send the draft, argue against it with each of these seeds and
change what does not survive:
<one line per Challenge seeds: sub-bullet>]

When the draft is written, send <main name> one message whose first line is

    question <tag>: <n> decisions needed on <spec path>

and whose body is the compact table — number, one-line question, options,
lean — and the draft's path. Then wait as § 1 says. The answer is a message
whose first line is `rulings <batch>: <n> rulings`, one row per decision
(`M<n>: <decision>`, `D<n>: <decision>`), ending with what to do next: fill
the Ruling column, set the status line to ruled, run the grep the
Constraints section gives, commit the spec alone as
`docs(plans): add batch <batch> spec`, reply with the hash, and stop. When
you stopped after thirty calls and were resumed, the same rows and the same
instruction come in the prompt that resumed you, under its first line
`answer <tag>: <one line>`.
````

- S2: `/kenspc-task <spec path>`.
- S3: `/kenspc-task-implement <task document path>`.
- S3b: `/kenspc-task-review review the range <baseline sha>..<HEAD sha at S3's end>`.
  Why the range: the batch's change set is that range by definition,
  whatever the branch tracks, and task-review pins a range named in its
  instructions.
- **S4, plugin mode** — Phase 3, when `Acceptance:` names cases and the
  mode is `plugin`. The cases and their PASS criteria are the field's
  sub-bullets, `(optional)` carried over; `<HEAD sha>` is HEAD at the
  launch, the state file's `head:`; `<tag>` is S4's own tag; `<remaining>`
  is the budget left at S4's launch; `<nested tag>`, `<seed directory>`,
  `<prompt file>`, and `<cap>` are S4's to fill per nested launch and stay
  as they are in the launched prompt. The first run lists every case and
  gets the bracketed trial-run words and the first bracketed record
  paragraph; an `-s4b` re-run after an S5 fix (Phase 3) lists the one case
  it re-runs and gets the second record paragraph instead. Why the nested
  tags and the cap are spelled out: a nested launch
  under a worker's or a resume's tag is accepted once that worker has ended
  and overwrites its `.json`, `.session`, and `.pid`, which Phase 4 reads;
  and S4's own cap bounds none of its nested sessions, so a cap they shared
  would let each case spend it once.

````
## Task: acceptance for batch <batch>

The batch's commits are <baseline sha>..<HEAD sha>; run the acceptance at
that HEAD with the plugin at <plugin directory>. Seed projects live under
<workspace>/<batch>-<seed>/, one per run, made as the case needs.

One case per run, in the order listed[, after a trial run of a seed to
confirm the path under test is reachable]:

<n>. <case> — PASS: <criterion>[ (optional)]

Every run is a headless session started through the driver copy, with the
seed as its cwd and its prompt in a file:

    AUTOPILOT_LOGS=<workspace>/_logs AUTOPILOT_BATCH=<batch> \
    AUTOPILOT_PLUGIN_DIR=<plugin directory> AUTOPILOT_BUDGET_USD=<cap> \
    <workspace>/_prompts/<batch>-run.sh <nested tag> <seed directory> <prompt file>

The nested tag is <tag>-case<n> for case n[, and <tag>-trial for the trial
run] — a tag no other session has used. The cap is <remaining> for the first
nested launch and, for each later one, <remaining> less the costs of every
nested session finished so far, the trial's included. Wait for each nested
session with

    n=0; until [ -f "$LOGS/$TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done

one Bash call per iteration, LOGS being <workspace>/_logs and TAG the
nested tag, until <nested tag>.exit exists; the session's cost is
total_cost_usd in <nested tag>.json. A driver copy that exits non-zero has
started nothing, so no wait follows; a nested pid, in <nested tag>.pid,
gone with no <nested tag>.exit ten seconds later is a dead session. Either
ends that run — the trial or the case — as a FAIL whose reason, the
driver's stderr message or the death, goes in the record and in your
reply.

[Write the record to docs/dry-runs/<batch>-acceptance.md with these
sections in this order: Setup, Independence, Cases, Findings, Observations,
Not exercised, Summary. Every driver reply is named in it under the case it
belongs to; each case's line carries PASS or FAIL against its criterion and
its cost, the sum of its nested sessions' last cumulative total_cost_usd,
and the trial run's line under Setup its cost the same way.
Commit the record alone, `docs: add batch <batch> acceptance record`; the
repository changes in no other way.]
[Rewrite case <n>'s lines in the record at docs/dry-runs/<batch>-acceptance.md
from this run — the driver replies named under it, PASS or FAIL against its
criterion, its cost, the sum of its nested sessions' last cumulative
total_cost_usd — leaving the other cases' lines as they are, and commit the
record alone, `docs: update batch <batch> acceptance record`; the
repository changes in no other way.]
Reply with the record's path and one line per case — its number, PASS or
FAIL, its cost.
````

- **S4, repo mode** — Phase 3, when `Acceptance:` names commands and the
  mode is `repo`; `<HEAD sha>` is HEAD at the launch, the state file's
  `head:`. The bracketed paragraphs are written when `Acceptance record:`
  names a path — the first on the first run, the second on an `-s4b`
  re-run after an S5 fix (Phase 3), which lists the one command it re-runs.
  With `Acceptance: none`, no S4 starts.

````
## Task: acceptance for batch <batch>

The batch's commits are <baseline sha>..<HEAD sha>; run the acceptance at
that HEAD, in the repository. Run each of these, one per Bash call, in the
order listed:

<n>. <command> — PASS: <criterion>[ (optional)]

Reply with, for each command: the command, its exit code, and the last
twenty lines of its output.
[Write the same lines to <Acceptance record: path> and commit that file
alone, `docs: add batch <batch> acceptance record`; the repository changes
in no other way.]
[Replace command <n>'s lines in <Acceptance record: path> with the same
lines from this run, leaving the others as they are, and commit that file
alone, `docs: update batch <batch> acceptance record`; the repository
changes in no other way.]
````

- **S5** — a fix, launched from a classified defect: a Schema F row after
  S3b (Phase 2), or an acceptance FAIL (Phase 3). `<ID>` and `<run dir>`
  name the finding — the row's issue ID and the review's run directory, or
  the case's number and the record's path (plugin mode) or S4's reply (repo
  mode); `<one line>` is the finding in one sentence. The first line is the
  block's own heading, as the verdict loop names it; the bracketed words
  are written when `Allowed files:` is set, as the preamble's line is.

````
Fix issue <ID> from run <run dir>: <one line>

The finding, as the reviewer or the acceptance recorded it:
<the row, or the case's lines, quoted>

The case to make pass: <the check that failed, with its PASS criterion — a
review check, a self-test, a command, an acceptance case>.

Make the fix[ inside the allowed files], run the checks the repository's
CLAUDE.md names for a change of this kind, and commit the fix alone — one
commit in the repository's convention, touching nothing the finding does
not need. Reply with the commit hash and one line on what changed.
````

- **S6, the removal commit** — Phase 4: repo mode with
  `Release preparation: default` or a list of instructions, and plugin mode
  with `Version: none`. The removal paragraph is written unless the list
  says `keep`, its `and touches no version and no CHANGELOG` words when
  `Version:` is `none`; the Version line is written instead when
  `Version:` is set in repo mode, the instructions when
  `Release preparation:` is a list. With the bare `keep`, no S6 starts; a
  list that says `keep` starts S6 for its instructions alone, with no
  removal (Phase 4).

````
## Task: release preparation for batch <batch>

The batch's commits are <baseline sha>..<HEAD sha>.
[Make one commit, `docs: remove batch <batch> plan and tasks`, that `git rm`s
<spec path> and <task document path>[ and touches no version and no
CHANGELOG].]
[Version <Version:>: bump it where the repository's CLAUDE.md says versions
live, in the removal commit — in a commit of its own when this task makes
none — and change nothing else.]
[Then carry out these instructions, each committed in the repository's
convention:
<the Release preparation: sub-bullets>]
Reply with each commit's hash and subject.
````

- **S6, the release commit** — Phase 4, plugin mode with a `Version:`. The
  bracketed brief words are written when git tracks the brief; an untracked
  brief is left where it is and named in the reports as the user's to
  commit or discard. The bracketed roadmap lines are written when Phase 3
  classified a FAIL as a behavior deviation and drafted a line for it; the
  bracketed checklist items when `docs/release-checklist.md` exists —
  without it, the reviewer report's counts field reads `none: no checklist`.

````
## Task: release preparation for batch <batch>, version <Version:>

The batch's commits are <baseline sha>..<HEAD sha>. The repository's
release checklist (docs/release-checklist.md, when it exists) and its
CLAUDE.md's release convention govern this task; read both first. Then, in
one release commit in the repository's convention:

- the CHANGELOG's `— unreleased` heading gets today's date;
- the plugin manifest's version becomes <Version:>;
- the manifests' descriptions name the new capability;
[- the checklist's counting rows follow what the guards now print;]
- the roadmap's shipped items leave it, and its heading names the next
  minor[, and these lines, one per behavior deviation the acceptance found,
  are added to it:
  <the roadmap lines drafted in Phase 3>];
- `git rm` <spec path> and <task document path>[ and the brief
  <brief path>].

[Run the checklist's pre-flight block; its two count lines go in your reply.]
No tag, no push, no release: those are the user's. Reply with the commit
hash[ and the two count lines].
````

### The driver

`${CLAUDE_PLUGIN_ROOT}/skills/autopilot/scripts/run.sh`, copied per batch
and run through the copy:

```
run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]
run.sh --self-test                          prints: self-test passed

AUTOPILOT_LOGS         the logs directory (default ~/Projects/_smoke/_logs)
AUTOPILOT_PLUGIN_DIR   when set, --plugin-dir <value>   (plugin mode)
AUTOPILOT_BUDGET_USD   when set, --max-budget-usd <value>
APPEND_SP              when set, --append-system-prompt <value>
AUTOPILOT_CLAUDE       the executable (default claude)
AUTOPILOT_BATCH        the batch name in the timeline's file name

<tag>.json  <tag>.err  <tag>.pid  <tag>.exit  <tag>.session
<batch>-timeline.log   start <tag> pid <pid> …  /  end   <tag> exit <status>
<batch>-costs.txt      <tag> <session_id> <total_cost_usd>   (written by this skill)
```

Every worker starts with `--name <tag>`,
`--settings '{"crossSessionInbound":"accept"}'`,
`--permission-mode bypassPermissions`, `--output-format json`, stdin from
`/dev/null`; a fresh launch passes `--session-id`, a resume `--resume`.
`APPEND_SP` is listed by the driver and set by no launch of this skill:
every worker asks by message, as the preamble says, and a worker told to
work without stopping would answer its own questions, which the quality
bar names as the failed run. Why
the session id is written before the start: the transcript path and the
resume id are known even when the worker dies before its JSON lands. Why
`<tag>.exit` and no completion message: `.exit` is written by the driver
when the worker returns, and the messaging socket documents no line format
a driver could post.

### The wait snippets

The driver form, for a headless run and for S4 waiting on its nested
sessions — it returns as soon as `<tag>.exit` appears:

```
n=0; until [ -f "$LOGS/$TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
```

The worker form, for a worker waiting for an answer — nothing to poll, the
counter only:

```
n=0; until [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
```

Why this form: the Bash tool blocks a bare sleep of thirty seconds or more
and refuses chained short sleeps; a bounded `until` loop is the form its own
message recommends and needs nothing outside POSIX sh. Each iteration is
one tool call of about a minute, so a thirty-minute wait is about thirty
calls.

### The settings line

Printed once, before the first launch, in English whatever the
conversation's language:

```
Autopilot settings — batch <batch>, mode <repo|plugin>, baseline <sha>, budget USD <n>, caps <n> sessions / <m> resumes, version <v|none>, acceptance <k> cases|none, release preparation <default|keep|custom>, workspace <path>, wait <interactive|headless>
```

A note on ignored labels, a `Version:` ignored in repo mode, or a
`Zero diff:` path absent at the baseline follows on the next line.

### The stop conditions

Each stop ends the turn with `Autopilot stopped: <reason>` as the last line
of the final message; a stop is a question to the user about how to go on.
In a session that cannot ask (a system reminder to work without stopping),
the run ends with that message.

1. Reopening a locked point — the points are immutable.
2. A forbidden section or file touched — the promise a review does not
   verify.
3. Guards red twice in a row — the second narrowed review that still
   fails.
4. The same FAIL still failing after two fixes — a third fix is a guess.
5. The session cap, the resume cap, or the budget exceeded — a question
   with the numbers.
6. A rail breach — the worker has already reported it and ended.
7. A question neither the spec nor the locked design answers — an answer
   would be the main session's own.
8. A nested `claude -p` refused — the topology cannot be run here.
9. The same step's session dead twice — a third resume replays the same
   failure.

### The decision hierarchy

The locked design (immutable) > the design table's decisions (the main
session, within the lock; the user at brief entry) > clarifications during
implementation (the main session; recorded in the spec and committed).
A decision that reads a locked point beyond its letter is reported in the
reviewer report. Why: the reviewer learns from the report which decisions
the user has yet to see.

### The reviewer report

```
## Reviewer report

- Batch and mode: <batch>, <repo|plugin>
- Range: <baseline sha> → <release sha, or the last commit>
- Spec: git show <hash>:<path>
- Design rulings and clarifications: <n> / <m> / <k>; beyond the letter: <list, or none>
- Files changed: <list>; zero diff: <nothing printed | the paths>[; absent at the baseline: <paths>]
- Byte-identity / guards / counts: <the pre-flight lines in plugin mode, or none: no checklist>
- Acceptance: <one line per case: case, cost, result> | none named; S3b is the last check
- Total cost: USD <workers' sum> measured + USD <trial's and acceptance cases' sum> measured from the record (plugin mode; omitted otherwise) + USD <n> estimated for the main session (<turns> turns × USD <mean per turn> from <k> workers' totals ÷ turns); /cost may replace the estimate
- Not exercised: <list, or none>
- Release preparation: <commit | not prepared | kept>
- Sessions: <n>, messages: <m>, resumes: <r>, stops: <s> (<reasons>)
  <tag>  <session id>  USD <cost>  <result>
```

## The gates

Every question the skill asks is one of these gates. The last column is
what a session that cannot ask does in place of asking; the sentences
above, at each gate, are the rule, and this table repeats their outcomes.

| Gate | Asks | In a session that cannot ask |
|---|---|---|
| No arguments | The path | The run ends: `Autopilot stopped: no path given` |
| The argument is neither a brief nor a spec | Which it is | The run ends with the reason |
| Several plugins and no `Plugin:` | Which plugin | The run ends with the reason |
| A start check fails, or a settings stop | — (a stop with its reason) | The run ends with the same message |
| The launch line shows no `crossSessionInbound` accept | Whether a settings file accepts inbound messages | The run ends naming the launch line |
| Budget: spent + projected > budget | Raise the budget to how much? | The run ends with spent, projected, and the remaining steps |
| A cap exceeded | A new cap | The run ends with the counts |
| Brief entry: S1's design table | A decision per row; "use your leans for the rest" accepted | Every row takes its lean; `lean adopted (the session could not ask)` per row; the reports say so row by row |
| A worker's question the spec answers | — (answered from the spec) | Answered from the spec |
| A worker's question the spec does not answer | The question, quoted | The run ends with the question quoted |
| Any other stop condition | How to go on | The run ends with the reason |
| The final gate | Tag, push, release | The run ends with the two reports and the finish line |

## Exit

On a finish, the final message holds `## User report`, `## Reviewer report`,
every default a session that cannot ask took in place of a question, and
ends with `Autopilot finished — <baseline sha>..<last sha>` followed by the
sentence that the tag, the push, and the release are the user's. The skill
tags nothing, pushes nothing, and deletes nothing outside `git rm` in a
worker's commit. Why: the second human gate is the release, and a run that
took it would have had one gate.

On a stop, the final message names the step and its tag, what is on disk
(the state file, the last session's files, the commits so far), what the
user can do — answer, raise a number, fix and re-run — and ends with
`Autopilot stopped: <reason>`. The state file holds the next action, so a
later run of the same batch reads where this one stopped.

## Writing rules

- Prompts, the spec, commit messages, and the reviewer report are in
  English. Why: the workers copy prompt text into commits and documents,
  and the repository's rules put those in English.
- The user report and the conversation are in the user's language.
- The fixed lines — the settings line, the launch and return lines, the
  question and answer first lines, the stop and finish lines, the report
  headings — are in English whatever the conversation's language. Why: the
  release checklist and the acceptance grep for them.
- No `git push`, no `git tag`, no release, in this session or any worker.

## Phase transitions

Each phase starts from the artifact the previous one produced, not from the
wording that closed it:

- Phase 0 → Phase 1 or 2: the settings line printed and the state file
  written.
- Phase 1 → Phase 2: the spec's commit hash in the state file.
- Within Phase 2: each `<tag>.exit`; S2 → S3: the task document on disk;
  S3 → S3b: S3's `.exit` and the HEAD it left; S3b → Phase 3: its Schema F
  verdict and the empty zero-diff output.
- Phase 3 → Phase 4: the record (plugin mode) or S4's reply (repo mode)
  with every FAIL classified, or `Acceptance: none` recorded.
- The exit: S6's commit and the reports.

An artifact absent after a return — no task document after S2, HEAD still
where S3 started, the `head:` the state file recorded at its launch (every
task blocked, or the batch gate not passed), no Schema F verdict after S3b
(a review over an empty range dispatches nothing) — is a stop naming it,
not a transition. Why S3's own start and not the baseline: HEAD leaves the
baseline before S3 runs — S1 commits the spec, S2's reviewer commits the
task document — so a comparison with the baseline would read an S3 that
built nothing as a finished step, review a documents-only range, pass the
acceptance with nothing to accept, and remove the plan and task documents
of a batch that implemented nothing.

Why: a phase's closing sentence has been read as the end of a whole skill
run; the next phase reads an artifact, so the artifact is what moves the
run forward, and its absence is what stops the run: a return without its
artifact is a finished session, not a finished step.
