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
| S5 | fix on demand | `Fix issue <ID> from run <run dir>: <one line>` for a defect the main session classified, `Fix <n> issues from this round: <ID>, <ID>, …` for several |
| S6 | release preparation | one commit per mode (Phase 4), after a clarification commit for each question it asked — in any order when it removes nothing |

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
directories, the record — asks the user only on a stop condition and at
the two gates, and has the main session rule every other point the spec
leaves open, each ruling recorded (Phase 2 § How the main session rules).
Phase 0's questions about the run's inputs — no path, the entry kind,
which plugin, an inbound setting the main session cannot read — are asked
before the first launch, as part of the start. It fails the bar in three
named ways: a run that narrows the implementation to fit its budget; a
run that rules itself on a point a stop condition gives the user; and a
ruling missing from the record. Why: the worker proposes and the main
session rules, so the proposer and the ruler are two sessions; every
ruling is recorded in the state file and committed as a clarification in
the spec, or, when S6 had already removed the spec, marked so in both
reports (Phase 4); and the tag, the push, and the release stay the user's, after
the reports, so a ruling is read before anything leaves the machine. A
point a stop condition gives the user, ruled in the run, is a decision
taken from the user, and a ruling the record does not hold is one the
user cannot read before the tag.

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
`ps -o args= -p $PPID`; `$CLAUDE_EFFORT` and `$CLAUDE_CODE_SESSION_ID` in
this session's Bash; `printenv CLAUDE_CODE_EFFORT_LEVEL`; the sources
that can set `crossSessionInbound` — managed, the launch line's
`--settings`, user, the project's, and the server-managed settings cache
(The start checks).

**DONE when** the state file is written, the settings line (Templates
§ The settings line, ending with the pass-through values) its first line,
and, in an interactive main session, the settings line has been printed
as a line of its own in this session's reply — there the state file,
which carries it too, does not stand in for it (Templates § The settings
line says why). In a headless main session (The wait path decides which)
the state file and the timeline are the record, and the reply need not
carry the line. Why: nothing downstream reads a headless session's reply
(Templates § The settings line).

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
| `Role settings:` | one sub-bullet per role, `- <role>: model <model>[, effort <level>]` or `- <role>: effort <level>`: `<role>` one of `S1`, `S2`, `S3`, `S3b`, `S4`, `S5`, `S6`; `<model>` one token with no whitespace and no comma, passed to `--model` as written; `<level>` one of `low`, `medium`, `high`, `xhigh`, `max` | empty — every role runs at the pass-through values |

A label written with a note, `- <Label> (<note>): <value>`, is read as
`- <Label>: <value>` when the label is known, and the note is carried with
the field: for `Acceptance:`, as the run-notes line of both S4 task blocks
(Templates § The task blocks); for any other field, named on the line
after the settings line (Templates § The settings line). An unknown label
with a note stays unknown: ignored and named, as any unknown label is.
Why: a spec wrote its acceptance field as
`Acceptance (in the order listed, …):`, and read strictly, an unknown
label would have run the batch with no acceptance; the note carried the
cases' run conditions, so it travels with the field rather than being
dropped.

`Role settings:` sets the model, the effort, or both for a role's workers
— every session launched under that role's tags, re-runs and resumes
included. A role the field does not name runs at the pass-through values
(Phase 0 § The pass-through values), and so does the part a role's entry
leaves out: a role with a model and no effort gets the pass-through effort,
one with an effort and no model the pass-through model. A pass-through value
that is `not determined` is not passed, and the worker resolves that part
from its own settings. Why the declarations live only in the spec: the
plugin ships no default table and names no model, since a model name
written into the plugin goes stale silently at the next model generation,
while a spec is written for the models of its own day.

The section is read once, in Phase 0, and the values read there govern the
whole run. A later read of a field — Phase 3's `Acceptance:` cases, Phase
4's `Release preparation:` instructions — reads the section as Phase 0 read
it: in spec entry `git show <baseline>:<spec path>`, in brief entry the
spec at S1's commit, which copies the brief's section. A worker's edit to
the section changes nothing for this run. Before S6 is launched — or
before the reports when no S6 starts — the main session compares the
section at HEAD with that copy, and a difference goes on the reviewer
report's `Settings edits` line, each field with the commit that changed
it, for the user to carry into a later run or not; the preamble's § 6
tells every worker the section is not theirs to edit. Why: the section is
the user's settings, approved with the spec, and a worker that edits it
moves the terms it is judged by — a review fix once took the acceptance
list from 17 cases to 21, and the next review to 28. With no rule for
which version governed, the main session had no answer and stopped to ask
which list S4 would run, and the run waited overnight for the reply.

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

### The pass-through values

Decided once here, recorded in the state file and the settings line: the
model and the effort this session runs at now, which a role takes where
`Role settings:` declares nothing for it.

- The effort: `$CLAUDE_EFFORT`, read in this session's Bash.
- The model: from this session's own transcript. `$CLAUDE_CODE_SESSION_ID`,
  read in this session's Bash, names the file
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/<session-id>.jsonl`, found
  by that id and never by a
  directory name derived from the repository path; its last main-loop
  assistant record — a line whose `type` is `assistant`, in that file
  itself and not in a subagent's file — carries the model in
  `message.model`, a record whose `message.model` is `<synthetic>`, or
  whose `isApiErrorMessage` is `true`, being skipped. Why skip it: Claude
  Code writes such a record into the main loop for an API error, and
  while a Bash call runs the current message's
  own records need not be in the file yet, so after a turn that ended on
  an API error the last record can be that one; `<synthetic>` names no
  model, and passed to `--model` it would keep every undeclared worker,
  and each resume of it, from starting. Why `true` and not the field's
  presence: Claude Code writes the field as `false` too.

A value that cannot be read — the variable empty, no transcript, no
assistant record, no `message.model` — is recorded as `not determined` and
is not passed: the worker resolves that part from its own settings. Why
this session's values: an undeclared role then runs as the main session
does now, the model and the effort the user chose for the run. Why by the
session id: the directory name is an encoding of the path the harness does
not document, while the id names the file. Why under
`$CLAUDE_CONFIG_DIR` when it is set: Claude Code keeps its transcripts
there then, and a lookup under `~/.claude` alone would find none — the
pass-through model `not determined` on every run, every undeclared role
at its settings' model, and every applied value (The return)
`not observed`. Why `$HOME` and not `~` in the default: a `~` there is
not expanded inside double quotes, so a quoted lookup would search a
directory named `~` and find none, with the same result. Why
`not determined` and no
stop: the transcript's fields are an undocumented internal format, read as
evidence and not as a contract, and a run that stopped on them would stop
on a format change that has nothing to do with the batch.

The model ID in the transcript carries no context-size suffix, so the
pass-through model never carries one: a session running `<model>[1m]`
passes `<model>`. A role that needs the larger context window declares
it, `- S3: model <model>[1m]`, and the model match removes a trailing
`[...]` from the requested value before it compares, so the declared
suffix reads as no mismatch. Why say so: a long role left undeclared, S3
or S3b, may then run at the standard window while its line shows a match.

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
- `Role settings:` is in its grammar: every sub-bullet names a known role,
  no role appears twice, and every part matches the table — `model` and
  one token, `effort` and one of the five levels, the model first when both
  are given. An unknown role, a role named twice, or any part outside the
  grammar is the settings stop, naming `Role settings` and the value that
  failed: `- S3: effort extreme` names `extreme`. Why: a declaration the
  run could not read would launch that role at the pass-through values,
  which are not what the user wrote, and a role named twice leaves no way
  to tell which line the user meant.
- `printenv CLAUDE_CODE_EFFORT_LEVEL`, run in this session's Bash, prints
  nothing, or no role declares an effort; a value with an effort declared
  is the settings stop, naming `CLAUDE_CODE_EFFORT_LEVEL`. Why: the
  variable takes precedence over `--effort`, and every worker inherits this
  session's environment through the driver, so each declared effort would
  be overridden with nothing on the record saying so.
- The working tree is clean except a brief given as the argument when it
  is untracked (`git -c core.quotePath=false status --porcelain -uall`).
  An untracked spec is a stop naming the commit to make first,
  `docs(plans): add batch <name> spec`. Why: an untracked brief is how
  generate-brief leaves one, and S1 commits the spec it drafts from it;
  anything else in the tree would be swept into a worker's commit under
  its message — a supplied spec included, since it skips Phase 1 and no
  step commits it, while the state file and the reviewer report name its
  hash and repo-mode S6's default `git rm` fails on an untracked path.
- In brief entry, nothing is at `docs/plans/<batch>.md`, the path S1 writes
  the spec to, at the baseline —
  `git cat-file -e <baseline>:docs/plans/<batch>.md` fails; otherwise the
  stop names the path. Why: S1 writes the spec there and commits it as an
  addition, so a plan of the same name from an earlier `/kenspc-plan` run
  would be overwritten by the draft after a paid session, while the
  clean-tree and baseline checks pass on the way.
- HEAD equals `Baseline:`; otherwise the stop names both.
- `ListAgents` names this session on its first line; otherwise the stop
  gives the version requirement.
- The command line `ps -o args= -p $PPID` prints (The wait path) carries
  `crossSessionInbound` with `accept` — the launch line's `--settings`
  argument. When it does not, the main session reads the value from the
  settings files Claude Code reads it from. An absent file, key, or source
  sets nothing. A source whose value is not one of `accept`, `hold`, and
  `refuse` — another spelling, another word, an empty string, `null` — is a
  source the main session cannot read (below). Why: what Claude Code does
  with such a value is not documented, and a value read as unset could
  leave a lower source's `accept` in force over it.
  - Managed settings: `managed-settings.json`, and the `*.json` files of a
    `managed-settings.d/` directory beside it, in
    `/Library/Application Support/ClaudeCode/` on macOS, on Linux and WSL
    at `/etc/claude?code/managed-settings.json` (and the directory beside
    it, `/etc/claude?code/managed-settings.d/`) — the pattern, run
    unquoted, stands for the Linux and WSL directory the managed-settings
    page names, and is written as a pattern because that directory's name,
    written out, reads to this plugin's model-name check as a model ID; a
    pattern that matches nothing, or a shell error for it, means the file
    is absent — and in `C:\Program Files\ClaudeCode\`
    on Windows; on macOS, the `com.anthropic.claudecode` managed
    preferences domain as a configuration profile installs it,
    `/Library/Managed Preferences/com.anthropic.claudecode.plist` and
    `/Library/Managed Preferences/<user>/com.anthropic.claudecode.plist`
    (`plutil -p <file>`, a file that does not exist setting nothing) —
    not `defaults read com.anthropic.claudecode`, which prints the user's
    own domain rather than the managed layer; on Windows, the `Settings` value
    under `HKLM\SOFTWARE\Policies\ClaudeCode` and under
    `HKCU\SOFTWARE\Policies\ClaudeCode` (`reg query <key> /v Settings`,
    from Git Bash `MSYS_NO_PATHCONV=1 reg query <key> /v Settings`, since
    Git Bash rewrites `/v` into a path and `reg` then fails on its syntax;
    a read that fails for any reason other than an absent key or value is
    a source the main session cannot read, below). Among the managed sources, the strictest value any of them sets is
    theirs.
  - The launch line's `--settings`: its inline JSON when the command line
    shows the argument as JSON, or the file at that path when it shows a
    path — the source the precedence below calls the launch line's
    `--settings`. Why the inline JSON too: a `hold` or `refuse` there fails
    the check above, and the precedence ranks it above user settings, so
    a user `accept` read without it would let the run go on under a value
    Claude Code does not apply.
  - User settings: `"${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"` —
    `$CLAUDE_CONFIG_DIR/settings.json` when the variable is set, else
    `~/.claude/settings.json`, written with `$HOME` for the reason § The
    pass-through values gives for the transcript lookup.
  - The project's `.claude/settings.json` and `.claude/settings.local.json`
    at the repository root.

  The precedence is the one § The message protocol states: the value of
  the first source that sets the key — managed settings, then the launch
  line's `--settings`, then user settings — and then a project or local
  `hold` or `refuse` applies when it is stricter on the
  `accept` < `hold` < `refuse` ladder, while a project or local value that
  is not stricter is ignored. The effective value decides:
  - `accept`: the run goes on, and the state file's `inbound:` line
    records the file and the line the value came from, or the managed
    source — a preferences file or a registry value, which has no line.
  - No source that sets the key: the run goes on under Claude Code's
    default, and the state file's `inbound:` line reads
    `the default: no source sets the key`. Why: the cross-session
    messaging page, https://code.claude.com/docs/en/cross-session-messaging
    § Control inbound messages (read 2026-10-01), says that when no value
    applies, a session that bypasses permission prompts delivers a message
    whose sender also bypasses them, and holds the rest; Prerequisites
    start the main session in bypassPermissions and the driver starts
    every worker so, so the default delivers every message of the run. A
    main session started without bypass permissions holds its workers'
    questions under the default, and that shows as the question not
    received that § The message protocol records — a worker that returns
    with a question that never arrived as a message. Why no stop: a stop
    there would stop a run the default serves.
  - `hold` or `refuse`: the stop naming the launch line and the file and
    line, the managed source, or the launch line's inline JSON, that set
    it. Why the source too: a managed value,
    and a stricter project or local one, outranks the launch line's
    `--settings`, so a relaunch with the launch line alone would change
    nothing, and the check it then passes reads no file.
  - A file that exists and cannot be read or parsed, or a source the main
    session cannot read — settings delivered from a server, which count as
    present when `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/remote-settings.json`
    exists and as absent when it does not: ask whether a settings file
    accepts inbound messages for this session; `yes` continues, recorded
    on the `inbound:` line as the user's answer, and `no` is the stop
    naming the launch line. In a session that cannot ask (a system
    reminder to work without stopping), the run ends naming the launch
    line.

  Whatever the check concludes, the stop on the first message's delivery
  notice (§ The message protocol) stays the backstop for a value the read
  missed — a source present with no local sign, or a managed source the
  platform exposes elsewhere — on the worker's side, whose inbound the
  notice reports. A missed value that holds the main session's own inbound
  shows instead as a worker that returns with its question under
  `## Question for the main session` although that question never arrived
  as a message; the run answers it by the resume and records it as a
  question not received (§ The message protocol). Why read the files:
  three batches asked the same question with the value already read from
  the user settings and no
  project or managed override found, and the user's answer was the one the
  files already gave. Why a question for an unreadable source, and not a
  guess: a value the main session cannot see may be `hold`, and a run that
  went on would learn it only at its first message. Why checked before the
  first launch: a main session that holds inbound messages never sees a
  worker's question — the worker waits its thirty minutes, stops with the
  question in its final message, and is resumed with the answer — thirty
  minutes and a resume per question, with no stop naming the cause.

  The sources and their order are the documentation's, as read on
  2026-09-30. https://code.claude.com/docs/en/settings gives the
  precedence, highest first: managed settings; the command line
  (`claude --settings`); project local (`.claude/settings.local.json`);
  shared project (`.claude/settings.json`); user
  (`~/.claude/settings.json`). It says `CLAUDE_CONFIG_DIR` keeps the
  home-directory files elsewhere, settings included, and makes
  `crossSessionInbound` an exception to managed precedence: a stricter
  value from `.claude/settings.json` or `.claude/settings.local.json`, on
  the `accept` < `hold` < `refuse` ladder, is honored over managed,
  `--settings`, and user values, and a project or local value that is not
  stricter is ignored. https://code.claude.com/docs/en/managed-settings
  names the managed sources: the file source, `managed-settings.json` with
  an optional `managed-settings.d/` directory beside it, in
  `/Library/Application Support/ClaudeCode/` on macOS, the Linux and WSL
  directory the pattern above stands for, and `C:\Program Files\ClaudeCode\`
  on Windows (the legacy `C:\ProgramData\ClaudeCode\managed-settings.json`
  is not read); MDM, the macOS `com.anthropic.claudecode` managed
  preferences domain and the Windows value `Settings` under
  `HKLM\SOFTWARE\Policies\ClaudeCode`; the user-writable
  `HKCU\SOFTWARE\Policies\ClaudeCode` value of the same name; and
  server-managed settings from the claude.ai console. It ranks them,
  highest first, server-managed, MDM, the managed files
  (`managed-settings.d/*.json` merged with `managed-settings.json`), the
  HKCU key; by default Claude Code uses the highest-ranked source that
  delivers at least one policy key and ignores the others, and
  `crossSessionInbound` is among the lock keys, for which the strictest
  value any source sets applies when the sources are merged — so taking
  the strictest managed value is never looser than what Claude Code
  applies. Of the macOS facts, the `com.anthropic.claudecode` domain is
  the managed-settings page's, while the two plist paths under
  `/Library/Managed Preferences/` are not in Claude Code's documentation:
  they are where macOS installs a configuration profile's managed
  preferences. https://code.claude.com/docs/en/server-managed-settings,
  cited for these facts alone, names the server-managed settings cache
  `~/.claude/remote-settings.json` and keeps the delivered settings in the
  configuration directory, `~/.claude` unless `CLAUDE_CONFIG_DIR` is set —
  hence the lookup `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/remote-settings.json`
  — and says a non-interactive run does not write the cache for settings
  that need approval, which is why the delivery-notice stop stays the
  backstop when the file is absent.
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
pass-through values, where the inbound `accept` came from, or that no
source sets the key (The start checks), and each question a worker
returned with that never arrived as a message (§ The message protocol), the
current step and its tag, each session's tag, id, cost, and result, each
worker's requested and applied model and effort, the
questions answered, the rail observations each worker listed, the gates
a worker skipped and their outcome, the
stops, the questions left open for a later step (The stop conditions), the
clarification numbers recorded in the spec, and the next action.
Every ruling is recorded under `questions answered:`, whoever made it — a
worker's question, a choice on a confirmation, a point the main session
raised itself (under the tag of the step it concerns), and an answer the
user gave at a stop or a gate — each line ending with who ruled,
`(main session)` or `(user)`. Why: the reviewer report's
`Main-session rulings` line and the user report's rulings list are built
from these lines, and a ruling without its ruler cannot be told from an
answer the user gave.
It is rewritten at every transition and re-read, with `<tag>.exit`, on
every wake — a notice, a message, a user reply — before the run acts. Why:
a wake starts a new turn whose only reliable memory is a file, and a long
batch compacts the conversation; the state file is what lets the resumed
turn continue from the artifact rather than from the wording.

```
Autopilot settings — …                      (the settings line)
main session: <name>   repository: <root>   baseline: <sha>   spec: <path> (<hash> once committed)
pass-through: <model|not determined>/<effort|not determined>
inbound: <accept from <the launch line | <file>:<line> | <managed preferences file or registry value> | the user's answer> | the default: no source sets the key>[; question not received: <tag>[ (<the error or notice, quoted>)][, <tag>…]]
step: <S<n>>  tag: <tag>  pid: <pid>  session: <id>  launched: <time>  head: <sha at the step's first launch>
sessions:
  <tag>  <session id>  USD <cost>  <success|subtype|dead|running>
models and efforts:
  <tag> requested <model|—>/<effort|—> (<declared|pass-through>) applied <model|not observed>/<effort|—|not observed>[ MISMATCH: <what>]
questions answered:
  <tag>: <one line> → <one line> (main session|user)
rail observations:
  <tag>: <the worker's entry, one per line | none | not read (<reason>)>
skipped gates:
  <S2|S3> <tag>: <accepted as a behavior deviation | resumed <tag>-r<k> to amend | stop: <the mismatch or choice> | recorded>
stops: <reason> (<time>)
open questions:
  <the step that needs the answer>: <the question, one line> (<time raised>)
clarifications recorded: <numbers>[; no clarification commit (the spec was already removed): <tag>: <one line>[, <tag>: <one line>…]]
next: <the next action>
```

In a `models and efforts:` line, `—` in the applied effort means the
worker's records carry no `effort` field, the mismatch
`effort not applied` when an effort was requested; in a requested part
it means no flag was passed (The return).

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
when `## Implementation Steps` is missing — a question only a spec with
that section answers, so a paid session spent before the gap shows — and writes a Doc-sync task only
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

**DONE when** S3b's verdict is PASS, or every HIGH row, every ruled row
whose action differs from its ruling, every ruled ID that no report lists,
and every row-3 or row-5 FAIL is classified, and the zero-diff check has
printed nothing.

**Constraints**: the main session commits nothing but clarification entries
in the spec, `docs(plans): record clarifications settled after <step>`; the
workers make every other commit. Each clarification entry names who ruled,
`(ruled by the main session)` or `(ruled by the user)`, wherever this skill
describes one. Before S6 is launched, the main session commits every
clarification still pending; S6 raises every question before the commit
that removes the spec, and a question it raises is answered with the text
of its clarification entry, which S6 adds to the spec and commits alone,
`docs(plans): record clarifications settled after S6`, before that commit
(Templates § The task blocks, S6). An S6 that removes nothing — a
`Release preparation:` list that says `keep` — may ask at any point and
commits each entry before it ends; an entry it left uncommitted, the main
session commits once S6 has ended (Phase 4). Why: the commits are the
workers' evidence, and a main session that edited code would be
reviewing its own work; why the ruler named: the spec is where the user
reads a ruling before the tag and the push, and an entry without its
ruler reads as the user's own decision. Why S6 commits a ruling made
while it runs: its release or removal commit
`git rm`s the spec, so a clarification the main session committed after it
would re-add the removed spec; a main-session commit while S6 is live could
sweep S6's staged changes into it, and a main-session edit of the spec then
would make S6's `git rm` of a locally modified file fail; committed by S6
before the removal, the entry stays in the spec's history, and the ruling
keeps its four records. Why the main session commits after an S6 that
removed nothing: neither reason holds then — there is no removal to
re-add the spec, and a commit of the spec's path alone once S6 has ended
sweeps in none of the changes S6 left staged.

### Launch, wait, return

Every worker is one launch, one wait, one return.

- **The launch.** Assemble `_prompts/<batch>-<tag>.md` from the preamble
  and the task block; run the driver copy with the environment it needs —
  `AUTOPILOT_LOGS=<workspace>/_logs`, `AUTOPILOT_BATCH=<batch>`,
  `AUTOPILOT_BUDGET_USD=<remaining>`, `AUTOPILOT_WORKSPACE=<workspace>`
  (below), `AUTOPILOT_MODEL` and `AUTOPILOT_EFFORT` (below), and
  `AUTOPILOT_PLUGIN_DIR` (below) — with the repository root as the
  worker's cwd; in an interactive main session, print
  `S<n> started — <tag> pid <pid> session <session-id> — <prompt path>`
  as a line of its own in this session's reply (the pid and the session id
  from the driver's `started` line, or from `<tag>.pid` and
  `<tag>.session`) — there the state file does not stand in for it
  (Templates § The settings line says why), while in a headless main
  session the state file and the timeline's `start` line are the record,
  since nothing downstream reads a headless reply; rewrite the state file,
  its step line carrying HEAD at the step's first launch — a resume,
  `<tag>-r<k>`, keeps the `head:` its step already holds. Why the first
  launch: an S5 that committed one defect's fix, died, and was resumed
  would otherwise have its narrowed review start after that commit, which
  would reach its case's re-run unreviewed, and an S3 resume that
  committed nothing more would read as an S3 that built nothing. A driver that
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

  A worker does not follow this session's model and effort: it is its own
  `claude -p` process, and without `--model` and `--effort` it resolves
  both from its own settings. So every launch sets `AUTOPILOT_MODEL` and
  `AUTOPILOT_EFFORT` explicitly, each to the role's declared value
  (`Role settings:`), else to the pass-through value (Phase 0), else, when
  that is `not determined`, to the empty string, which the driver reads as
  unset. Why the empty string rather than leaving the variable out: a
  variable of the same name already in this session's environment would
  otherwise reach the driver and pass a value nobody chose. Both values go
  on the launch line in single quotes. Why: the `<model>` token is free
  text from the spec, passed as written, and a backtick, `$`, or `;` in it
  left unquoted is read by the shell — a token in backticks, a markdown
  habit, becomes a command substitution that leaves the variable empty,
  and the worker runs at its settings' model. A re-run's tag
  takes its step's role: `-s3<letter>` (`-s3c`, `-s3d`, …) is S3b,
  `-s4<letter>` (`-s4b`, `-s4c`, …) is S4, `-s5<letter>` (`-s5b`, …) is
  S5. Why: `Role settings:` is keyed by role, and a re-run's tag names the
  step it repeats, not a role; `-s3c` is the narrowed review after a fix,
  S3b's work and not S3's implementation, so read by its prefix it would
  take the implementer's values. A resume, `<tag>-r<k>`, sets the same
  `AUTOPILOT_MODEL` and
  `AUTOPILOT_EFFORT` the tag it resumes was launched with. Why: a resume
  keeps the session's model but not its effort, so a resume launched
  without `--effort` would fall back to the settings' effort.

  Every launch sets `AUTOPILOT_PLUGIN_DIR` explicitly as well: the plugin
  directory in plugin mode, the empty string in repo mode, which the
  driver reads as unset; a resume sets the value the tag it resumes was
  launched with. Why, as for the model and the effort: a variable of the
  same name already in this session's environment would otherwise reach
  the driver. Why the repo-mode value is written out: while the variable
  was set in plugin mode alone, three repo-mode main sessions that had
  inherited it read that text two ways — one launched its workers with the
  variable empty, and they ran the installed plugin; two passed the
  inherited plugin directory on, and theirs ran the working tree's skills.

  Every launch, resumes included, also sets
  `AUTOPILOT_WORKSPACE=<workspace>`, the workspace's absolute path. Why:
  the driver builds the worker's write roots from it (The driver), which
  the plugin's rails hook reads in every worker the driver starts, and a
  marked nested main session writes its state file and prompts under the
  workspace, a write the hook would deny without that root.
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
- **The return.** In an interactive main session, print
  `S<n> returned — exit <code>, cost USD <c>, <success|subtype> — <json path>`
  from `<tag>.exit` and `<tag>.json`, as a line of its own in this
  session's reply, as the launch line is — there the state file does not
  stand in for it (Templates § The settings line says why); in a headless
  main session the state file and the timeline's `end` line are the
  record, since nothing downstream reads a headless reply. Upsert
  `<tag> <session_id> <total_cost_usd>` into `<batch>-costs.txt` — replace the line that carries the same session
  id, else append; a resume's line replaces its predecessor's, since a
  resumed session's JSON carries the whole total; rewrite the state file.
  A `<tag>.json` that is empty or not JSON — an executable that could not
  start, a worker killed before its result — gives the return line
  `cost USD unknown` and `no result` in the subtype's place, gets no costs
  line, since a `0` there would read as a free session, and counts as dead
  (Death and resume).
  Before the next step, read the JSON's `result` for
  `## Question for the main session`: a return that carries it is the
  timed-out or unsent question (The message protocol), not a finished
  step — except an S6 return after the commit that removes the spec,
  whose point Phase 4 rules from the reply with no resume. Why: a worker that waited out its thirty minutes exits like one
  that finished, and its missing artifact would otherwise be found one step later. Read
  the same `result` for `## Rail observations` too, and record each entry
  under the state file's `rail observations:` section with the worker's
  tag — `<tag>: none` when the heading is absent or empty, and
  `<tag>: not read (<reason>)` when there is no `result` to read: a
  `<tag>.json` that is empty or not JSON, or a subtype that carries no
  result. Why: a write
  under `/tmp` is not a breach (the preamble's § 3), but a write nobody
  records is one nobody can check; the section is what the reviewer
  report's `Rail observations` line is built from. Why `not read` apart
  from `none`: a worker whose final message never arrived has observed
  nothing anyone knows of, and recorded as `none` it would read as a
  worker that wrote nowhere else. An entry under `## Rail observations`
  that carries a denial whose reason contains
  `could not be read from the hook input` is stop condition 11, once the
  entry is recorded: the stop names the field — the name in parentheses in
  the reason, `tool_name`, `tool_input.command`, or `tool_input.<key>` —
  and gives the output of `claude --version`, run in this session's Bash.
  Why at the return: the worker ended on that denial, as the preamble's
  § 3 tells it to, and the next worker would meet the same one. At S2's and S3's
  return, check whether the step asked its gate (§ A worker's question at
  a gate, on a skipped gate).

  Once `<tag>.exit` is there, read the model and the effort the worker
  actually ran at. The session id in `<tag>.session` names its transcript,
  `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/<session-id>.jsonl`, the
  root the pass-through model is read under, for the reason given there
  (Phase 0 § The pass-through values); read
  only that file's main-loop assistant records — its lines whose `type` is `assistant`, and
  not a subagent's file — each one's `message.model` and `effort`,
  skipping the records the pass-through read skips: a record whose
  `message.model` is `<synthetic>`, or whose `isApiErrorMessage` is `true`.
  Why skip them: Claude Code writes such a record into the main loop for
  an API error, with no `effort` field; it is the harness's own and not a
  model's response, and counted it would mark a worker that hit one
  dropped connection — the usual way into a resume —
  `MISMATCH: model, effort not applied` although every response ran at
  the requested values. Every other
  record counts: a part with one distinct value is written as it stands,
  several distinct values are joined with `+`, and a part matches only when
  every record matches. A resume's tag reads the whole session, the earlier
  run included. Why every record: the records of one session need not
  agree — a resume keeps the model but not the effort — and a line built
  from one record would hide the part of the session that ran at another
  value, the substitution the line exists to show. Why the whole session:
  a resume keeps its session id, so its `<tag>.session` names the same
  transcript, which holds the earlier run's records beside its own.
  - The model matches when the actual model ID contains the requested
    value, compared without regard to case, once a trailing `[...]` is
    removed from the requested value.
  - The effort matches when the record's `effort` equals the requested
    value. A record with no `effort` field does not match, the applied
    effort shows `—` for it, and the mismatch is written
    `effort not applied`.
  - A part requested as `—` — its variable set to the empty string, so no
    flag was passed — is not judged.
  - A transcript that cannot be found, or that holds no main-loop assistant
    record that can be read — a session left with only skipped records
    among them — is `not observed` in both parts, and a
    `message.model` that cannot be read is `not observed` in the model
    part. `not observed` is printed as it stands: it never stops the run,
    takes no `MISMATCH:`, and is not counted as a mismatch.
  - A mismatch is recorded and marked, never a stop.

  The result is one line per worker in the state file's
  `models and efforts:` section:

  `<tag> requested <model|—>/<effort|—> (<declared|pass-through>) applied <model|not observed>/<effort|—|not observed>[ MISMATCH: <what>]`

  where `declared` marks a role `Role settings:` names — a role that
  declares one part only is `declared` too, its other requested part being
  the pass-through value that was passed — and `<what>` names each part
  that does not match, `model`, `effort`, or `effort not applied`, joined
  with `, `. `—` in the applied effort means the records carry no `effort`
  field, and in a requested part that no flag was passed. Why a sign of
  its own and not `not observed`: a record without the field was read, and
  its missing effort, where an effort was requested, is a counted
  mismatch, while `not observed` is never counted as a
  mismatch. A resume's line replaces the line of the session it resumes,
  as its costs line does. Why: the resume's line reads the whole session,
  the earlier run included, so a line kept for each run would count one
  worker, and its mismatch, twice in the reviewer report. Why read and
  never stop: the transcript's fields are an
  undocumented internal format, evidence and not a contract, so the run
  records what it could read and a reviewer judges a mismatch, while a
  stop would rest the batch on a format the harness may change.

### How the main session rules

Every point the spec leaves open is the main session's to rule: a
worker's question, a choice riding on a task-list confirmation (§ A
worker's question at a gate), a question the main session raises itself,
a review row's or an acceptance FAIL's classification (§ The verdict loop
after S3b, Phase 3's Classification), a deferred row's route, and a
corrected acceptance case (Phase 3). It answers a waiting worker at once,
in the `answer <tag>:` form (§ The message protocol). It asks the user
only on a stop condition (Templates § The stop conditions) and at the two
gates; Phase 0's questions about the run's inputs — no path, the entry
kind, which plugin, an inbound setting it cannot read — are asked before
the first launch, as part of the start. Its ruling is the same whether or
not the session can ask. Why: in three batches the user was asked 25
questions and chose the main session's own recommendation 24 times, while
each wait held a worker past its thirty minutes — 36 and 95 minutes in
one batch, two and a half hours of question rounds in another; a real
spec never settles every name and detail, so sending every open point to
the user made an open-ended third gate. Why the same ruling in a session
that cannot ask: the ruling rests on the order below, not on whether
someone is there to take it over, so a run reads the same attended or
not.

The order it rules by:

1. the spec's words;
2. the locked design;
3. the project's instruction files and the patterns in adjacent code;
4. then the option easiest to reverse and closest to the spec's scope.

A worker's suggested answer is evidence, not a default. The main session
never stops for a preference between options that all stay inside the
batch's contract: it picks by the order and records why. Why this order:
the spec and the locked design are what the user approved, the
instruction files and the adjacent code are the project's own rules, and
of what is left, the option easiest to reverse costs least when the user
reads the ruling and disagrees, while the one closest to the spec's scope
keeps a ruling from widening the batch. Why a suggested answer is not a
default: it comes from the session whose work the ruling bounds, and a
default taken from it would make the proposer the ruler. Why no stop for
a preference: a preference among options inside the contract is what the
order settles, and a stop for one is the third gate again.

A ruling may depart from a sentence of the spec — never from a locked
point, whose reopening is stop condition 1 — when evidence shows the
sentence wrong: a test, a probe, a reviewer's reproduction, a documented
tool behavior. The clarification names the evidence, and the ruling goes
on the reviewer report's `beyond the letter` list. Why: a spec sentence a
test shows false would otherwise be built as written, or sent to a user
who has taken the evidence-backed recommendation nearly every time; the
list puts every such departure in front of the user before the tag.

Every ruling is recorded: under the state file's `questions answered:`,
marked `(main session)`, and as a clarification entry in the spec that
names the main session as the ruler, committed as Phase 2's Constraints
say — except a ruling answered to S6, or ruled from its reply, that has no
clarification commit after S6 removed the spec, which is recorded as
Phase 4 says and never committed after the removal. A worker still never
rules itself: it asks the main session (the preamble's § 1), which
records every answer. Why: an answer a worker invents is recorded
nowhere, so nobody reads it before the release, while the main
session's answer is in the state file and the spec, where the user reviews it before the tag and the push.

### A worker's question at a gate

S2 asks at generate-task's confirmation (`Confirm, or adjust tasks before
writing?`) and S3 at task-implement's batch gate (`Proceed with automated
implementation?`); both arrive as `question` messages, and the main session
rules on both (§ How the main session rules). The confirmation is answered
from the spec, in one answer:

- `yes` when the task list matches the spec's steps — every step has a
  task, no task is outside the spec — and carries no choice the spec's
  words leave open;
- a step without a task: "add a task for <step>";
- a task outside the spec: "drop <task>", unless a spec step needs it,
  which the main session rules and records in a clarification entry
  naming it as the ruler;
- a choice riding on the confirmation — a type, a shape, a name, or a
  behavior the worker proposes to pin, however the worker frames it: a
  detail, a task-level concretization, not a design change — ruled by the
  main session and recorded, as a clarification entry naming the main
  session as the ruler, its ruling part of the answer.

It fails in two named ways: a mismatch answered `yes`, and a riding choice
passed without a recorded ruling. Why: the framing is the worker's, not
the spec's. Two workers have put one point the spec left unstated, the
shape of a result's entries, in two framings — one listed it among the
open details, and it went to the user; the other presented it as a
concretization with its own suggestion, and the main session confirmed it
— so a rubric that looked only at coverage let the framing decide who made
the choice. Sending every such choice to the main session, ruled and
recorded, removes the framing question as sending every one to the user
did, without a wait on the user for each.

A question the spec does not answer is ruled by the main session, the same
whether or not the session can ask. The batch gate (S3) is answered `yes`.
Why: the spec is the approved artifact, and a point it leaves open is the
main session's to rule and record; the batch gate follows once S2's task
list has passed (below).

**A skipped gate** is checked after the fact, at the step's return — the
skipped-gate post-check — not prevented. An S2 that returns without having sent its confirmation
question — no `question <tag>:` carrying the task list's confirmation
from S2's tag or its resumes, and no confirmation answer in the state
file's `questions answered:`, where a ruling the post-check itself
recorded is not one — has the confirmation's own rubric above applied
to the task document it committed: every step has a task, no task lies
outside the spec, and no choice the spec's words leave open rides on it.
A match, or rulings on its open choices that the committed document
already follows, is accepted and recorded as a behavior deviation, in the
state file's `skipped gates:` section and on the reviewer report's
`Skipped gates` line. A mismatch, or an open choice whose ruling differs
from the committed document, resumes S2 under its next `<tag>-r<k>` with a
prompt whose first line is `answer <tag>: <one line>` and whose body is
the ruling — the answer the confirmation would have got — to amend the
task document and commit it; the resume counts as a resume under
`Caps:`, and it is recorded under `skipped gates:` as
`resumed <tag>-r<k> to amend`. The post-check then runs again on the
amended document. A second failure — a mismatch, or a choice that still
differs from its ruling — is a stop stated here, outside the numbered stop
conditions, with the mismatch or the choice quoted. In a session that
cannot ask (a system reminder to work without stopping), the run ends
with it quoted. Why the resume: the committed document is on disk to
amend, and the worker that wrote it amends it; a stop on the first
mismatch sent the user a point the main session rules everywhere else.
Why a stop on the second: a worker that amended its document against the
ruling and still missed it would miss it again, and further resumes would
spend the caps on the same miss. Why checked and not prevented: an S2 at
a lowered effort has skipped the confirmation and sent no question while
the S2 workers at the pass-through effort asked, though the preamble told
every one of them to ask; the committed task document is on disk to check
with the same rubric the question would have met.

An S3 that returns without having asked task-implement's batch gate is
recorded only, in the same section and line. Why: once S2's task list has
passed — by its answered question or by the post-check — the batch
gate's answer is yes by construction.

No role gets an effort floor for its gate. Why: a floor per role would be
a plugin default, which the plugin does not ship, and it would not catch
a skip at any effort; the post-check catches it at every effort.

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
  and whose body is the decision, quoting nothing the worker sent. The main
  session sends it at once, ruled as § How the main session rules says,
  without asking the user. Why: the first line is what the transcript
  search finds, and the suggested answer is what makes the decision a
  one-line reply; why at once: the worker waits in place, and a wait past
  its thirty minutes ends it with the question and costs a resume.
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
  start, so the first real message is where a stricter setting shows. The
  notice reports the worker's inbound, so this stop is the backstop for
  the worker's side only: a main session whose own inbound is held never
  receives the worker's question, sends no answer, and so gets no notice
  (the next bullet says what the worker's return then shows).
- A worker that got no answer in thirty minutes, or whose send returned
  an error or a held or refused notice (the preamble's § 1), has put its
  question under
  `## Question for the main session` in its final message and stopped. The
  answer goes to it — to every worker but an S6 past the commit that
  removes the spec (Phase 4) — as a resume under the step's next `<tag>-r<k>`: a
  prompt whose first line is `answer <tag>: <one line>` and whose body is
  the decision, counted as a resume. When that question never arrived as a
  `question <tag>:` message from the worker, the question is answered by
  the resume all the same and recorded as not received on the state
  file's `inbound:` line (`question not received: <tag>`), and both
  reports name the causes to check — the main session's own inbound,
  under the settings precedence above, or a send that failed or was never
  made — the user report among what needs the user, the reviewer report
  on its `Follow-up candidates` line. When the worker's final message
  quotes the error or the notice its send got, the record names that
  cause in place of the list: the state file's entry reads
  `question not received: <tag> (<the error or notice, quoted>)`, and
  both reports name the quoted cause. It is not a stop. Why not a stop: the
  run goes on through the resume, and a stop would hold an unattended run
  for a cause the user can look into after it. Why recorded: each such
  question costs thirty minutes and a resume, and without the record
  nothing names where to look. Why the causes and not a hold: a held
  inbound, a send that failed, and a send never made leave the same
  return, and the record names each as a cause rather than claiming one;
  a worker that saw its send fail or be held has seen the cause, and its
  quote is what the record names.

### The verdict loop after S3b

S3b's Schema F verdict decides the next step. Passing: PASS, on to Phase 3.
FAIL, or PARTIAL with HIGH rows deferred or with a ruled row whose action
differs from its ruling (task-review's Verdict determination): each HIGH
row, each such ruled row, and each row-3 or row-5 FAIL is classified by
the main session as a plugin defect, fixed by an S5, or accepted as a
deferral with
a reason recorded as a clarification in the spec, naming who ruled. A
ruled ID that no report lists keeps the verdict from PASS the same way and
is classified as such a ruled row, its `rulings.md` entry standing for the
row it lacks: the main session names, from the entry and the reports, the
finding the ruling meant, and an S5 for it quotes the entry as its
finding, with that finding's row when one matches. Why: the S5 task block
quotes a row, and an ID with none would give an S5 nothing to fix. Each
such ruled row is classified as a HIGH row is, whatever its severity. Why: a
ruling the review did not carry out is a decision of the run's own that
the review overrode, and read as a MEDIUM or LOW row it would be
classified once and could go to a roadmap candidate unfixed. One S5 may fix several
defects classified in the same round: its task block lists each defect
with its row (The task blocks, S5), and it commits one defect per commit.
Every S5 is followed by the narrowed review — `-s3c`, the next letter for
a later one (`-s3d`) — over the range from HEAD at the S5's first launch,
the state file's `head:`, to its last commit, a wording-only fix included,
before any re-run of a case and
before the next S5. A defect the S5's reply marks `not fixed`, or lists
with no commit, still stands whatever the narrowed review says, since that
review reads only the commits the S5 made: it counts as a fix of it
(stop condition 4) and goes to the next S5. The second narrowed
review that still FAILs is the "guards red twice in a row" stop. DEFERRED
MEDIUM and LOW rows are classified once — a fix in S5, or a roadmap
candidate listed in the reviewer report — and recorded as a clarification
naming who ruled.
Why: the round count is where the stop conditions put it, and a deferral
without a recorded reason is a finding nobody owns. Why a narrowed review
after every S5, a wording-only fix included: one S5 has fixed six defects
of a round, two of them in wording only, and those two reached the next
step with no review after them; a change of any size is a change no
review has seen until the narrowed one runs.

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

**Inputs**: the `Acceptance:` field as Phase 0 read it (§ The
`## Autopilot` section); the S3b HEAD; the preamble; in plugin
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
(an implementation defect, in repo mode) → S5 fixes it — one S5 may fix
several defects classified in the same round — then the narrowed review
(`-s3<letter>`, the next letter) runs over the range from HEAD at the S5's
first launch to its last commit, a wording-only fix included, its verdict
read as The verdict loop after S3b reads S3b's, and only once it passes is
each case a fixed defect failed re-run, in a new S4 session (`-s4b`, the
next letter for a later one) that runs only that case, while a defect the
S5 left unfixed goes to the next S5, as The verdict loop after S3b says;
a behavior
deviation → a roadmap line drafted for the release commit (plugin mode) or
a reviewer-report line (repo mode); a case broken for a reason outside
the batch's work → a corrected case (below), re-run in its corrected form
in a new S4 session (`-s4b`, the next letter for a later one) that runs
only that case; an observation → recorded. The same
defect still failing after two fixes of it is a stop, counted per defect
as stop condition 4 counts. Every classification is a
clarification entry in the spec, naming who ruled, committed by the main
session as
`docs(plans): record clarifications settled after <step>`. Why: the record
separates evidence from judgment — S4 records, the main session decides —
and the spec's clarification section is where decisions made during
implementation live. Why the narrowed review before the re-run: a fix the
review has not seen is re-run as if it were verified (The verdict loop
after S3b), and so is one the review has failed. Why per defect: two counts, one per case and one per defect,
would stop the same run at different points.

S5's task block: each classified defect with its case, the check to make
pass, and one commit per defect.

**A corrected case.** The main session may rule a corrected form of an
`Acceptance:` case when it has both pieces of evidence:

1. the case as written fails, or passes vacuously, for a reason outside
   the batch's work — shown at the baseline, or a named tool behavior
   verified by running it;
2. a negative control: the corrected form passes on the unbroken clone at
   the HEAD S4 ran at, then fails on a deliberate break of what the case
   checks, with both outputs recorded. A corrected form that does not pass
   unbroken there is a control not made, not evidence.

The ruling is a clarification in the spec, naming the main session as the
ruler, carrying the case, the corrected form, and both pieces of evidence — paths or quoted output — committed as
Phase 2's Constraints say. The `## Autopilot` section stays as Phase 0
read it: a correction is a ruling, not a settings edit, and every later S4
— the first run or an `-s4b` re-run — lists the case in its corrected form
and names the clarification (Templates § The task blocks). Without both
pieces of evidence, the correction is stop condition 7 (b).

The main session gathers the evidence outside the repository's working
tree: in a clone under `$TMPDIR` or the workspace
(`git clone <repository root> <dir>`, then
`git -C <dir> checkout --detach <sha>` — the baseline for a failure shown
there, the HEAD S4 ran at for the negative control), where it first
restores the setup the case needs and a fresh clone lacks — installed
dependencies, build output, as the project's instruction files give
them — then makes the deliberate break and runs both forms of the case.
The clone is left where it is, or moved into the workspace's `.trash/`; it is never deleted with a
recursive `rm`. Why a clone: the main session commits nothing but
clarification entries (Phase 2's Constraints), and a checkout of the
baseline or a break made in the working tree would change the tree and
the index the workers and the next step read — and a break left there by
a stop would be swept into the next worker's commit.

Why both pieces of evidence: four acceptance commands have broken for
reasons outside a batch's work — a flag the package manager read instead
of the test runner, a failure word that matched an application log line,
a summary line the installed SDK does not print, so the command failed at
the commit before the batch, and a check that passed vacuously because a
clone was never restored — and each time the main session had verified a
corrected form before it asked. The first piece shows the case, not the
batch, is what failed; the negative control keeps a correction from
loosening a check until it passes, and its unbroken pass first keeps a
clone that cannot run the command at all — no dependencies installed —
from failing both runs and reading as a control. Why a ruling and not a settings edit:
the section is the user's settings, fixed at Phase 0 (§ The `## Autopilot`
section), and a clarification is where the user reads the correction
with its evidence.

**The narrowing rule.** Cases marked `(optional)` may be cut when the budget
check fails, in the order listed, with Not exercised recorded. An unmarked
case that cannot be run is a stop. Implementation is never narrowed. Why:
acceptance is the part of a batch a budget may shorten with the shortfall
on record; an implementation cut to fit a budget is a different batch.

## Phase 4: Release preparation and reports

**Goal**: S6's commit, after the clarification commit of each question S6
asked — in any order when S6 removes nothing (below) — and the two
reports.

**Inputs**: `Release preparation:`, `Version:`, the mode; the state file;
`<batch>-costs.txt`; every worker's JSON.

**DONE when** the final message carries both reports and ends with
`Autopilot finished — <baseline sha>..<last sha>`, and the reviewer report
is also at `_logs/<batch>-report.md`.

**Repo mode.** `Release preparation: default` — S6 makes one commit,
`docs: remove batch <name> plan and tasks`, that `git rm`s the batch's plan
and task documents and touches no version and no CHANGELOG; the
clarification commit of each question it asked comes before it (below).
`keep` — no S6; the documents stay. A list of instructions — S6 runs them as its task
block, after the default removal unless the list says `keep`.
`Version: <string>` in repo mode is passed to S6 as an instruction to bump
wherever the project's instruction files say versions live, and is otherwise
ignored with a note after the settings line. Why: a product repository's
CHANGELOG has a convention the plugin cannot know; the removal and no
version is the default, and the field carries the rest. The bump rides in
the removal commit, or in a commit of its own when the project's commit
convention cannot name both in one subject. Why: a repository whose
convention requires one scope from a fixed list has none that covers a
commit touching the documents and an app's version file, and a subject
naming one of them misstates the other.

**Plugin mode.** The repository's release checklist
(`docs/release-checklist.md` when it exists) and the release convention in
the project's instruction files govern S6's task block: the CHANGELOG's
`— unreleased` heading gets today's date; the plugin manifest's version
becomes `Version:`; the manifests' descriptions name the new capability;
the checklist's counting rows follow; the roadmap's shipped items leave and
its heading names the next minor; the batch's plan and task documents,
and its brief when git tracks it, are `git rm`ed — an untracked brief, the
brief-entry case since S1 commits the spec alone, is left where it is and
named in both reports as the user's to commit or discard, since `git rm` on
an untracked path fails and the rails allow no other deletion inside the
repository; one release commit in the repository's convention; the
pre-flight block runs and its two count lines are in S6's reply; no tag, no
push. With `Version: none` in plugin mode, S6 makes the removal commit
only, and the reports say the release was not prepared. Why:
stack-agnostic in form — the checklist and the project's instruction files
are read — and the repository's own procedure in substance.

The zero-diff check runs again before S6 is launched, over
`<baseline>..HEAD` as it then stands, and not after S6's commit. Why
before: S4 and S5 commit after the check that follows S3b, so their commits
need one of their own; and in plugin mode the release commit edits, by
design, paths a zero-diff list may name — a plugin repository's roadmap or
manifest — so a check run over the release commit would stop a run whose
release preparation was right.

At S6's return the main session checks that its reply lists a
clarification commit, `docs(plans): record clarifications settled after S6`
in the repository's convention, for every ruling it answered to S6; both
S6 task blocks ask for each commit's hash and subject, which is the check's
input. A listed commit counts for a ruling when `git show <hash>` touches
the spec alone and adds that ruling's entry, whatever its subject. Why the
entry and not the subject: S6 adapts the subject to the repository's
commit convention, and every clarification commit it makes carries the
same subject, so a subject names neither the commit nor the ruling it
carries. S6 raises every
question before the commit that removes the spec — its own clarification
commits may come first — and a point that arises only after that commit is
not asked: S6 leaves the work the point decides undone and names the
point and that work in its reply, and the main session rules it there,
lists the undone work among what needs the user in both reports — the
user report's list, the reviewer report's `Follow-up candidates` line —
and resumes no S6 for it. An S6 that returns after that commit with the
point under `## Question for the main session` is read the same way: it
is ruled from the reply, not answered by a resume, and it is recorded as
a question not received only when S6 quotes an error or a notice its send
got. Why undone and no resume: work done on the
point before its ruling would be S6 ruling it, and any commit that
carried the ruling now would come after the removal.
After a removal, a ruling answered to S6, or ruled from its reply, that
has no clarification commit is not a stop: its line under the reviewer
report's `Main-session rulings` says
`no clarification commit (the spec was already removed)`, and the user
report lists it among the rulings the user reviews before the tag and the
push; the state file and both reports hold it. An S6 that removes
nothing — a `Release preparation:` list that says `keep` — may ask at any
point and commits each entry before it ends; a ruling answered to it, or
ruled from its reply, that has no clarification commit when it ends, the
main session commits itself once S6 has ended, in the same subject, and
the check records that commit as the main session's: it adds the entry
unless S6 left it written in the spec, and commits the spec's path alone,
`git commit -- <spec path>`, while the spec is still at HEAD; a spec an
instruction removed makes it a ruling after a removal (above). Why before the
removal: the removal or release commit `git rm`s the spec — repo mode's
instructions run after the removal, plugin mode's pre-flight after the
release commit — so a clarification committed after it would re-add the
removed spec. Why no stop and no entry added later: the stop conditions
do not list a record gap the reports can name, and a clarification
committed after the removal would re-add the file; the reports are where
that ruling is read. Why the main session commits after an S6 that
removed nothing: with no removal nothing is re-added, and a commit of the
spec's path alone once S6 has ended carries none of S6's changes (Phase
2's Constraints). Why the spec's path alone: the index outlives S6, so a
change it staged and never committed — a commit its hook rejected — would
ride in a plain commit, while a commit given a path carries that path's
change only.

Before answering a question from S6, the main session checks that the
spec is still at HEAD and in the index, `git cat-file -e HEAD:<spec path>`
and `git ls-files --error-unmatch <spec path>`, run from the repository
root with the spec's repository-relative path, after the control
`git cat-file -e <head>:<spec path>` with the state file's `head:` has
succeeded; when either fails, the spec is gone, and the answer tells S6
to leave the work the point decides undone and put the point in its
reply, where the main session rules it. A control that fails means the
command is wrong, not the spec gone: the main session corrects the path
or the directory and checks again. At S6's return it also checks, with
`git log --reverse --name-status <head>..HEAD` from the state file's
`head:`, that each clarification commit comes before the commit that
removes the spec, and, after a removal, that the spec is absent at HEAD
(`git cat-file -e HEAD:<spec path>` fails where the same control
succeeds). Why the index and the control: a removal S6 has staged and not
yet committed leaves the spec at HEAD but not in the index, and
`git cat-file -e` fails alike for an absent path, a path not in
repository-relative form, and a directory outside the repository, so a
failure counts only beside a control that passed. A failed check is not a stop:
both reports record it with the commits it names — the user report among
what needs the user, the reviewer report on its `Follow-up candidates`
line. Why the check before an answer: an answer to a question S6 sent
after its removal would tell it to commit an entry into the spec it
removed, re-adding the file. Why the order and the absence at the return:
a clarification committed after the removal re-adds the spec after the
release commit, and a check that a commit is listed passes it. Why no
stop: as for a ruling without its clarification commit, the stop
conditions do not list a record gap the reports can name, and the user
reads both reports before the tag.

**The reports**, both in the final message:

- `## User report` — the conversation's language, at most one page: what
  the batch built, the release commit, what needs the user (tag, push,
  release; any stop or deferred item; a question not received, with the
  cause the worker quoted or the causes to check; a failed check at S6's
  return, with the commits it names; work S6 left undone for a point
  raised after the removal), and the cost. Then, under the
  heading `### Main-session rulings — review before the tag and the push`,
  the rulings of the reviewer report's `Main-session rulings` line, one
  line each in the user's language — the question, the ruling, and its
  clarification, or that it has no clarification commit because the spec
  was already removed — or `none`; the one-page limit does not count this
  list.
  Why: the user reviews every ruling from the reports before anything
  leaves the machine, and a limit that cut the list would cut the part the
  user must read.
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
  whose cases the same report lists with their costs. The
  `Models and efforts` line, `<n> workers, <k> mismatches, <j> not observed`,
  counts the workers, the mismatches, and the workers not observed from
  the state file's `models and efforts:` lines, which follow it as they
  stand; `<k>` is the number of lines that carry `MISMATCH:`, one per
  worker however many parts it names, since the count stands beside the
  number of workers and a count by part would give two runs over the same
  state file two numbers; `<j>` is the number of lines that carry
  `not observed`, one per worker in the same way, and a `not observed`
  part is never counted in `<k>`; with no mismatch the line reads
  `<n> workers, mismatches: none, <j> not observed`. Why `<j>`: a run in
  which no transcript could be read would otherwise read
  `mismatches: none`, the same as a run in which every worker was
  verified. Why: a worker's model and
  effort are chosen per role and set on every launch, so the report is
  where a reviewer sees which settings the harness applied and which it
  did not.

The reviewer report is built from the state file, not from memory, and also
written to `_logs/<batch>-report.md`; the state file records its last
transition; the final message gives the sentence that the tag, the push,
and the release are the user's, and its last line is
`Autopilot finished — <baseline sha>..<last sha>` (Exit says why). In a
session that cannot ask (a system reminder to work without stopping), the
run ends the same way: the two reports, the sentence that leaves the tag,
push, and release to the user, and the finish line last.

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
main session resumes you with the answer. When the send returns an error,
or a delivery notice says the message was held or refused, do not wait:
put the question under `## Question for the main session` at once,
quoting the error or the notice, and stop. Do not decide a question
yourself because the run is unattended: ask <main name>, which rules and
records every answer, while an answer you decide is recorded nowhere. An
answer that rules on the findings of a review you are running —
/kenspc-task-review, or the review phase of /kenspc-task-implement — goes
into that run's `RUN_DIR/rulings.md` before code-fixer is dispatched,
never into an agent's CUSTOM_INSTRUCTIONS. Messages carry summaries and paths,
never a report's text: a report or a full table goes to a file — under
<workspace>/_prompts, or in the repository when it belongs there — and the
message names its path, since a message over about a million characters
is refused and so is a burst of about thirty sends.

## 2. Read first

- The specification: <spec path>   (at brief entry: the brief, <brief path>)
- Prior specs: `git show <hash>^:<path>` for each entry of Prior specs:
- <each Must read: path>
- The project's instruction files. The project's instruction files are its
  CLAUDE.md and AGENTS.md files — at the root, in `.claude/`, or in a
  subdirectory — and the files a CLAUDE.md imports with `@`, whether or not
  Claude Code loaded them in this session.

## 3. Safety rails

Write only to the repository at <repository root>, the workspace at
<workspace>, $TMPDIR, and the harness's per-session scratchpad. A write
elsewhere under /tmp (on macOS /private/tmp) holding no secret is not a
breach: list it under a heading `## Rail observations` in your final
message and go on. Any other write outside those locations is a breach.
No recursive rm in any spelling — rm -r, rm -rf, rm -fr, rm -R — wherever
it points: discard by mv into <workspace>/.trash/<name>-<timestamp>/,
created when missing; deletions inside the repository only through
git rm. No git push, no git tag, no release. No resource the brief does
not name — no database, no network service. No secrets in any file or
message. Listing environment variables prints their names only, never
their values: `bash -c 'compgen -e'` prints the names alone, while `env`
or `printenv` cut at the `=` still prints every further line of a
multi-line value.

The rails govern what you write — your own commands and tool calls. A
program you run that removes a temporary directory it created itself (a
guard's or a test script's mktemp cleanup), or writes its own cache, is
not a breach; a recursive delete you write, in any language — rm -r,
find -delete, a Python shutil.rmtree — still is. A script or program you
write during the run and then run — a helper in scratch, $TMPDIR, or the
workspace — is your own writing: a recursive delete in it is a breach, as
if you had typed it. The code the batch implements and its tests, run as
the project runs them, stay a program you run.

A call the rails hook denied — its error contains `autopilot rails:` — is
not a breach, since it never ran: take the permitted route the denial
names, list the denial under `## Rail observations`, naming the subagent
that made the call when a subagent made it, and go on. Reaching the
effect the hook denied by another spelling — another command, another
tool, a script — other than the route the denial names is a breach. A denial whose
reason says a field of the hook input could not be read — the tool name,
a Bash command, or a file-tool target — names no route, since the hook
reads every later call the same way: it is not a breach either, but list
it under `## Rail observations` with the hook's reason quoted as printed —
the main session stops the run on its exact words — and end, whether you
or a subagent met it.

These rails bind every subagent you dispatch, and a subagent never sees
this prompt: write them into every subagent prompt you compose, and into
the CUSTOM_INSTRUCTIONS of the agent dispatches made by the skills you
run. Carry every rail observation a subagent reports — under
`## Rail observations` or on a `Rail observations` line — into your own
`## Rail observations`, naming the subagent and quoting a denial's reason
as it gave it.

Any breach is a stop: report it and end.

## 4. The locked design

<one line per numbered point: its number and topic — read them in
<file> § <section>>. The points are immutable; a question that reopens one
is refused.

## 5. Out of scope

<the spec's section by name, and its content in one paragraph>

## 6. Constraints

<the spec's constraint sections by name>, and the project's instruction files.
Commit messages: a subject this prompt gives is the default; write it in the project's commit convention — the one the repository writes down (in the project's instruction files or its CONTRIBUTING), or, failing that, the pattern its recent commit subjects consistently share.
Autopilot section: once <spec path> is committed, its `## Autopilot` section holds this run's settings, fixed for the run; leave it as it stands, and put a change it seems to need in your final message.
Allowed files: <the Allowed files: paths — the files this batch may change; a file outside them is a forbidden file>.
Byte-identity exceptions: <the Byte-identity exceptions: text — the only byte-identity sections this batch may edit>.
````

The last two lines of § 6 are written when their fields are set and
omitted when empty. Why in the preamble: it is the only text a worker
reads, so a field that reaches no preamble binds no worker and trips no
stop; the zero-diff check verifies the paths a batch must not touch, and
these two fields bound what it may. Why § 6 carries the commit line: the
task blocks give fixed subjects, and a repository whose convention
requires a scope from its own list — where `docs(plans):` is outside it —
would get worker commits its own rules reject; the preamble is the only
text every worker reads. Why the Autopilot section line: § The
`## Autopilot` section says why the run's settings are fixed at Phase 0.

Why § 1 tells a worker never to decide a question itself: the main
session records every answer it gives, in the state file and in the
spec, where the user reviews it before the tag and the push, while an
answer a worker decides is recorded nowhere, so nobody reviews it. Why
§ 1 sends a ruling on a review's findings to `RUN_DIR/rulings.md`: a
ruling written into code-fixer's and regression-verifier's
`CUSTOM_INSTRUCTIONS` broke task-review's rule that both get the
reviewers' CONTEXT unchanged, while the run directory is the one path
both already read. Why § 1 has a worker whose send failed or was held
stop at once, quoting what it saw: no answer comes to a send that failed
or was held, so the thirty-minute wait only delays the resume that
answers it, and the error or the notice is the one sign of the cause,
seen by the worker alone — without it the record can only name the
possible causes.

Why a script the worker writes and then runs is its own writing: a helper
is the agent's choice of a delete as much as a typed command is, and a
rail that stopped at the command line would be passed by writing the same
delete into a file first; the code the batch implements and its tests are
the project's, run as the project runs them, and stay a program the
worker runs, as a guard's `mktemp` cleanup does. Why reaching a denied
effect by another spelling is a breach: the hook reads spellings, not
intent, and a denied effect reached another way leaves the denial with no
effect. Why environment listings print names only: a worker printed the
machine's local messaging-socket token from an environment listing whose
redaction pattern missed it; a name tells whether a variable is set,
while a value printed stays in the transcript and the logs. Why the
method named: the obvious one, `env` cut at each line's `=`, prints the
continuation lines of a multi-line value — a key or a credential held in
one variable — as if they were names.

Why § 3 tells the worker to carry its rails into its subagents: a
worker's subagents never see the preamble, so rails left there bind the
worker alone — an implementation worker's subagent has written its
scratch files under `/tmp`, and a nested run's subagent has run `rm -rf`
on a scratch directory of its own. Why a scratch file under `/tmp` is
listed and not a stop: a scratch file holding no secret, written by a
subagent under `/tmp`, has stopped an implementation worker and a nested
acceptance run, where a list in the final message would have recorded it
and let the run go on; the recursive `rm` stays a breach wherever it
points, since what it deletes is not recorded anywhere. Why the worker
carries its subagents' observations into its own list: the main session
reads the worker's final message alone, so an observation left in a
subagent's reply would reach the state file as `<tag>: none`. Why a call
the hook denied is listed and not a stop: the denial kept it from
running, so nothing was deleted or written outside the roots, and its
reason names the route that stays inside the rails; with § 3 silent on
it, one worker would stop on the same blocked attempt that another
worked around with nothing recorded. Why a denial of a field the hook
could not read ends the worker instead: a field goes unreadable when a
Claude Code release renames it, and the hook then denies every call it
reads that way — every call for a renamed tool name, every Bash call for
a renamed command — so a worker that took the route and went on would
retry until its cap, with the renamed field recorded only as a run of
denials; ending puts it in front of the main session at once. Why the
rails govern an agent's own commands and tool calls: a guard's exit trap
that removes the directory it made with mktemp, or a tool's own cache, is
not a delete or a write the agent chose; read as one, the rails have kept review agents from
running the repository's own checks, and workers that reworded them for
code-fixer and regression-verifier alone broke task-review's rule that
those two get the reviewers' CONTEXT unchanged.

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
  paragraph; an `-s4b` re-run — after an S5 fix, or of a corrected case
  (Phase 3) — lists the one case it re-runs and gets the second record
  paragraph instead. A case the main
  session corrected (Phase 3, A corrected case) is listed in its corrected
  form, and its line gets the bracketed `in the corrected form` part,
  naming the clarification — on the first run and on an `-s4b` re-run
  alike, so a re-run of a corrected case runs the corrected form. The
  bracketed `Run notes:` line is written, on every run, when the
  `Acceptance:` field carries a note (§ The `## Autopilot` section). Why the nested
  tags and the cap are spelled out: a nested launch
  under a worker's or a resume's tag is accepted once that worker has ended
  and overwrites its `.json`, `.session`, and `.pid`, which Phase 4 reads;
  and S4's own cap bounds none of its nested sessions, so a cap they shared
  would let each case spend it once. The nested sessions take S4's
  `AUTOPILOT_MODEL` and `AUTOPILOT_EFFORT` through the environment — the
  main session set both for S4's launch, and the driver copy S4 runs reads
  them from there — so they run at the acceptance role's model and effort
  unless a case sets its own; the block says so. Why: nothing on the
  nested launch line shows the two values, so without the sentence S4
  would not know them, and a case whose criterion names a model or an
  effort would run at S4's with nobody having set them. Every nested
  launch sets `AUTOPILOT_PLUGIN_DIR` explicitly on its line, as the main
  session's launches do, and the block says so. Why: S4's environment
  holds the plugin directory from its own launch, so a case that leaves
  the variable out of its line still passes it, whatever the case meant.

````
## Task: acceptance for batch <batch>

The batch's commits are <baseline sha>..<HEAD sha>; run the acceptance at
that HEAD with the plugin at <plugin directory>. Seed projects live under
<workspace>/<batch>-<seed>/, one per run, made as the case needs.

One case per run, in the order listed[, after a trial run of a seed to
confirm the path under test is reachable]:

<n>. <case> — PASS: <criterion>[ (optional)][ — in the corrected form (<clarification>)]

[Run notes: <the Acceptance: field's note>]

Every run is a headless session started through the driver copy, with the
seed as its cwd and its prompt in a file:

    AUTOPILOT_LOGS=<workspace>/_logs AUTOPILOT_BATCH=<batch> \
    AUTOPILOT_WORKSPACE=<workspace> \
    AUTOPILOT_PLUGIN_DIR=<plugin directory> AUTOPILOT_BUDGET_USD=<cap> \
    <workspace>/_prompts/<batch>-run.sh <nested tag> <seed directory> <prompt file>

The driver copy passes --model and --effort from AUTOPILOT_MODEL and
AUTOPILOT_EFFORT, which your environment already holds from your own
launch, so every nested session runs at your model and effort unless a
case sets the two variables on its own launch line.
Every nested launch sets AUTOPILOT_PLUGIN_DIR explicitly on its line: the
plugin directory, as above, or the empty string for a run a case starts
without it. Your environment holds the plugin directory from your own
launch, so a line that leaves the variable out passes it all the same.
AUTOPILOT_WORKSPACE on the line is this batch's workspace; a case whose
nested run is an autopilot batch sets it to that batch's own workspace
instead — its Workspace:, or, when it names none, the default
~/Projects/_smoke/ as an absolute path, whatever this batch's workspace
is — since the nested main session writes its state file and prompts
there, and the rails hook denies a marked session's write outside the
workspace its line names.
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
  re-run, after an S5 fix or of a corrected case (Phase 3), which lists the
  one command it re-runs.
  A case the main session corrected (Phase 3, A corrected case) is listed
  as its corrected command, and its line gets the bracketed
  `in the corrected form` part, naming the clarification — on the first run
  and on an `-s4b` re-run alike, so a re-run of a corrected case runs the
  corrected form. The bracketed `Run notes:` line is written, on every
  run, when the `Acceptance:` field carries a note (§ The `## Autopilot`
  section). With `Acceptance: none`, no S4 starts.

````
## Task: acceptance for batch <batch>

The batch's commits are <baseline sha>..<HEAD sha>; run the acceptance at
that HEAD, in the repository. Run each of these, one per Bash call, in the
order listed:

<n>. <command> — PASS: <criterion>[ (optional)][ — in the corrected form (<clarification>)]

[Run notes: <the Acceptance: field's note>]

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
  mode); `<one line>` is the finding in one sentence. One S5 may carry
  several defects classified in the same round, one numbered entry each.
  `<heading>`, the block's first line, is its own heading: for one defect
  `Fix issue <ID> from run <run dir>: <one line>`, and for several
  `Fix <n> issues from this round: <ID>, <ID>, …`. The bracketed words are
  written when `Allowed files:` is set, as the preamble's line is. Why one
  commit per defect: each fix then reverts on its own, and the narrowed
  review and the per-defect stop count read one defect per commit.

````
<heading>

The defects, each as the reviewer or the acceptance recorded it:

<k>. <ID> — <run dir, or the case and its record>: <one line>
   The finding: <the row, or the case's lines, quoted — for a ruled ID no
   report lists, its `rulings.md` entry, with the matching row when one does>
   The case to make pass: <the check that failed, with its PASS criterion
   — a review check, a self-test, a command, an acceptance case>

Fix each defect[ inside the allowed files], run the checks the project's
instruction files name for a change of this kind, and commit each fix
alone — one commit per defect, in the repository's convention, touching
nothing its finding does not need. Reply with one line per defect: its ID,
the commit hash, and what changed — or, for a defect you did not fix, its
ID, `not fixed`, and why.
````

- **S6, the removal commit** — Phase 4: repo mode with
  `Release preparation: default` or a list of instructions, and plugin mode
  with `Version: none`. The removal paragraph is written unless the list
  says `keep`, its `and touches no version and no CHANGELOG` words when
  `Version:` is `none`; the Version line is written instead when
  `Version:` is set in repo mode, the instructions when
  `Release preparation:` is a list. With the bare `keep`, no S6 starts; a
  list that says `keep` starts S6 for its instructions alone, with no
  removal (Phase 4). The question paragraph's first bracketed ending is
  written with the removal paragraph, its second when the list says
  `keep`.

````
## Task: release preparation for batch <batch>

The batch's commits are <baseline sha>..<HEAD sha>.
A question you ask <main name> is answered with a clarification entry: add
it to the clarifications section of <spec path> and commit the spec alone,
`docs(plans): record clarifications settled after S6`[, before the removal
commit below. Raise every question before that commit; your clarification
commits may come first. A point that arises only after it is not asked:
leave the work it decides undone, and name the point and that work in
your reply; <main name> rules it there. Why: the removal
commit `git rm`s the spec, and the instructions run after it, so a
clarification committed after that commit would re-add the removed
spec][, before you end. This task removes nothing, so you may raise a
question at any point].
[Make one commit, `docs: remove batch <batch> plan and tasks`, that `git rm`s
<spec path> and <task document path>[ and touches no version and no
CHANGELOG].]
[Version <Version:>: bump it where the project's instruction files say
versions live, in the removal commit — in a commit of its own when this
task makes none, or when the project's commit convention cannot name the
removal and the bump in one subject — and change nothing else.]
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
release checklist (docs/release-checklist.md, when it exists) and the
release convention in the project's instruction files govern this task;
read both first. Raise every question before the release commit; your
clarification commits may come first. A question
you ask <main name> is answered with a
clarification entry: add it to the clarifications section of <spec path>
and commit the spec alone,
`docs(plans): record clarifications settled after S6`, before the release
commit. A point that arises only after the release commit is not asked:
leave the work it decides undone, and name the point and that work in
your reply; <main name> rules it there. Why: the release commit
`git rm`s the spec, and the pre-flight runs after it, so a clarification
committed after that commit would re-add the removed spec. Then, in one
release commit in the repository's convention:

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
No tag, no push, no release: those are the user's. Reply with each
commit's hash and subject[ and the two count lines].
````

### The driver

`${CLAUDE_PLUGIN_ROOT}/skills/autopilot/scripts/run.sh`, copied per batch
and run through the copy:

```
run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]
run.sh --self-test                          prints: self-test passed

AUTOPILOT_LOGS         the logs directory (default ~/Projects/_smoke/_logs)
AUTOPILOT_PLUGIN_DIR   when non-empty, --plugin-dir <value>   (fresh launch and resume; the empty string counts as unset)
AUTOPILOT_BUDGET_USD   when set, --max-budget-usd <value>
APPEND_SP              when set, --append-system-prompt <value>
AUTOPILOT_MODEL        when non-empty, --model <value>    (fresh launch and resume)
AUTOPILOT_EFFORT       when non-empty, --effort <value>   (fresh launch and resume)
AUTOPILOT_CLAUDE       the executable (default claude)
AUTOPILOT_BATCH        the batch name in the timeline's file name
AUTOPILOT_WORKSPACE    the workspace; when non-empty, one of the write roots below, refused unless absolute (the empty string counts as unset)

exported to every worker, fresh launch and resume, over any value the caller holds:
KENSPC_AUTOPILOT_WORKER        1
KENSPC_AUTOPILOT_WRITE_ROOTS   the roots joined by "|": the worker's repository (git rev-parse --show-toplevel in <cwd>),
                               AUTOPILOT_WORKSPACE when non-empty, $TMPDIR when set, /tmp, /private/tmp

<tag>.json  <tag>.err  <tag>.pid  <tag>.exit  <tag>.session
<batch>-timeline.log   start <tag> pid <pid> …  /  end   <tag> exit <status>
<batch>-costs.txt      <tag> <session_id> <total_cost_usd>   (written by this skill)
```

Every worker starts with `--name <tag>`,
`--settings '{"crossSessionInbound":"accept"}'`,
`--permission-mode bypassPermissions`, `--output-format json`, stdin from
`/dev/null`; a fresh launch passes `--session-id`, a resume `--resume`.
`--model` is passed when `AUTOPILOT_MODEL` is non-empty, `--effort` when
`AUTOPILOT_EFFORT` is, and `--plugin-dir` when `AUTOPILOT_PLUGIN_DIR` is,
on a fresh launch and on a resume alike; the empty string counts as unset.
The two exported variables are read by the plugin's rails hook
(`${CLAUDE_PLUGIN_ROOT}/hooks/scripts/autopilot-worker-rails.sh`, on
PreToolUse for Bash, Write, Edit, and NotebookEdit), which acts only in a
worker that carries the marker: there it denies a recursive `rm` and a
file-tool write outside the roots, in the worker's own calls and its
subagents' alike. It is a best-effort guard behind the preamble's rails
(§ 3), which still bind — it misses `find -delete`, `bash -c '…'`,
interpreter-level deletes, `git clean`, and writes through Bash. Why the
hook: the preamble is the worker's prompt, which the subagents it
dispatches never see, while a plugin's PreToolUse hook fires for a
subagent's tool call too, and its deny holds in a bypassPermissions
session.
`APPEND_SP` is listed by the driver and set by no launch of this skill:
every worker asks by message, as the preamble says, and a worker told to
work without stopping would answer its own questions, and those rulings
would be recorded nowhere — a ruling missing from the record, which the
quality bar names as a failed run. Why
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

Written once, before the first launch, in English whatever the
conversation's language, as the state file's first line, and, in an
interactive main session, printed as a line of its own in this session's
reply text, where the state file's copy does not stand in for the
printed one:

```
Autopilot settings — batch <batch>, mode <repo|plugin>, baseline <sha>, budget USD <n>, caps <n> sessions / <m> resumes, version <v|none>, acceptance <k> cases|none, release preparation <default|keep|custom>, workspace <path>, wait <interactive|headless>, roles <S2 <model>/<effort>; …|none declared>, pass-through <model|not determined>/<effort|not determined>
```

The roles list names each role `Role settings:` declares, in the field's
order, with its model and effort; the part a role's entry leaves out is
written `—` (`S3 —/low`), and an empty field is `none declared`. The
pass-through values are the ones Phase 0 determined. Why on the settings
line: the user sees before any session is paid for which role runs at
which model and effort, and which values a role gets where nothing is
declared.

A note on ignored labels, a `Version:` ignored in repo mode, a
`Zero diff:` path absent at the baseline, or the note a known label other
than `Acceptance:` carries (§ The `## Autopilot` section) follows on the
next line.

The launch and return lines (Launch, wait, return) go the same way: in an
interactive main session each is printed in the reply, on a line of its
own, when its step happens. Why the reply and not the state file alone:
the user reads the settings there before any session is paid for, and
sees each launch and return as its step happens, while the state file is
rewritten whole at every transition and keeps no history of them. The
ordered record on disk is the driver's `start` and `end` lines in
`<batch>-timeline.log`, and the release checklist reads that and the
state file, not the reply.

In a headless main session (The wait path decides which) the state file
and the timeline are the record: the settings line, the launch lines, and
the return lines are required there, not in the reply. Why: nobody reads
a headless session's reply as its steps happen, and two batches' headless
main sessions left the settings line and the return lines out of their
replies with nothing downstream missing them — the release checklist
reads the state file and the timeline.

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
4. The same defect still failing after two fixes of it — a third fix is a
   guess. Counted per defect, not per case, as Phase 3's Classification
   counts; an S5 that left the defect unfixed counts as a fix of it.
5. The session cap, the resume cap, or the budget exceeded — a question
   with the numbers.
6. A rail breach — the worker has already reported it and ended.
7. A way forward the main session cannot rule on — (a) every option
   changes the batch's contract and none stays inside it: a new
   dependency, an API contract change, a database schema or configuration
   change the spec does not name, a change to a file outside
   `Allowed files:` or on the zero-diff list; or (b) an acceptance case
   corrected without both pieces of evidence (Phase 3, A corrected case).
   When one option stays inside the contract — defer to a follow-up, leave
   as is — the main session takes it and records it, and the question is
   not asked. Reopening a locked point stays stop 1, and a ruling "leave
   the locked point as it stands and record the finding as a follow-up" is
   the main session's, not a stop. Why: the contract — the spec's scope,
   its files, and what the project depends on — is what the user approved,
   and only the user can widen it; a correction without its evidence may
   be a check loosened until it passes; and a point with a way forward
   inside the contract is one the order in § How the main session rules
   settles, so a stop for it would be a third gate.
8. A nested `claude -p` refused — the topology cannot be run here.
9. The same step's session dead twice — a third resume replays the same
   failure.
10. A settings stop before the first launch (The start checks), the two
    that concern the role settings among them: a `Role settings` entry
    outside its grammar, named with the value that failed, and
    `CLAUDE_CODE_EFFORT_LEVEL` set while a role declares an effort — a run
    that went on would launch its roles at a model or an effort nobody
    declared.
11. A worker's `## Rail observations` entry that carries a denial whose
    reason contains `could not be read from the hook input` (§ Launch,
    wait, return, the return), named with the field in the reason's
    parentheses and the output of `claude --version` — the rails hook no
    longer reads the harness's input format, so every later worker would
    end the same way.

**A question only a later step needs.** A question of condition 7's kind —
a way forward the main session cannot rule on — that the main session
raises itself — not a worker's question, which its
worker is waiting on — and whose answer no step before a later one needs
stops nothing when it arises: the main session writes it under the state
file's `open questions:` with that step, says so in its reply, and goes
on. An answer the user gives before then closes it. Before the main
session launches that step it reads `open questions:`, and a question still
open for the step is asked then, as the stop, in its form as it then
stands, since the steps between may have changed it. In a session that
cannot ask (a system reminder to work without stopping), the run likewise
goes on and ends at that step with the question quoted. Why: a question
raised while S3b ran, about which acceptance list S4 would run, stopped a
run overnight — the steps between, which needed no answer, waited with it,
and S3b's fixes then changed the list again, so the question answered in
the morning had to be asked a second time.

**Stops stated at their own steps.** Five stops sit outside the numbered
list, each stated where it happens, and end the run the same way: a
driver that refuses a launch (§ Launch, wait, return), a delivery notice
that the first message to a worker was held or refused (§ The message
protocol), an artifact absent after a return (§ Phase transitions), an
unmarked acceptance case that cannot be run (Phase 3's narrowing rule),
and the skipped-gate post-check's second failure (§ A worker's question
at a gate). Why listed
here: a reader of the stop conditions finds every stop from this section,
while each rule stays beside the step it governs.

**Outward actions.** An action that leaves the machine and that the run
does not need in order to continue — filing an issue, adding a backlog
item — is never taken and never asked mid-run: the reviewer report lists
it on its `Follow-up candidates` line for the user. Why: such an action
leaves the machine, and the user decides it after the reports, as the
tag and the push.

### The decision hierarchy

The locked design (immutable) > the design table's decisions (the main
session, within the lock; the user at brief entry) > clarifications during
implementation (the main session's, ruled as Phase 2 § How the main
session rules says; recorded in the spec and committed). A decision that
reads a locked point beyond its letter, and a ruling that departs from a
sentence of the spec on evidence, go on the reviewer report's
`beyond the letter` list. Why: the reviewer learns from the report which
decisions the user has yet to see.

### The reviewer report

```
## Reviewer report

- Batch and mode: <batch>, <repo|plugin>
- Range: <baseline sha> → <release sha, or the last commit>
- Spec: git show <hash>:<path>
- Design rulings and clarifications: <n> / <m> / <k>; beyond the letter: <list, or none>
- Main-session rulings: <n> | none
  <clarification> — <tag or step> — <question> → <ruling> — <reason> — <commits | no clarification commit (the spec was already removed)>
- Settings edits: <each field a worker changed in the `## Autopilot` section, with the commit | none>
- Files changed: <list>; zero diff: <nothing printed | the paths>[; absent at the baseline: <paths>]
- Byte-identity / guards / counts: <the pre-flight lines in plugin mode, or none: no checklist>
- Acceptance: <one line per case: case, cost, result[, in the corrected form (<clarification>)]> | none named; S3b is the last check
- Models and efforts: <n> workers, <k> mismatches|mismatches: none, <j> not observed
  <tag> requested <model|—>/<effort|—> (<declared|pass-through>) applied <model|not observed>/<effort|—|not observed>[ MISMATCH: <what>]
- Total cost: USD <workers' sum> measured + USD <trial's and acceptance cases' sum> measured from the record (plugin mode; omitted otherwise) + USD <n> estimated for the main session (<turns> turns × USD <mean per turn> from <k> workers' totals ÷ turns); /cost may replace the estimate
- Not exercised: <list, or none>
- Rail observations: <list | none>
- Skipped gates: <list | none>
- Follow-up candidates: <list | none>
- Release preparation: <commit | not prepared | kept>
- Sessions: <n>, messages: <m>, resumes: <r>, stops: <s> (<reasons>)
  <tag>  <session id>  USD <cost>  <result>
```

The `Main-session rulings` line is built from the state file's
`questions answered:` lines marked `(main session)` and the spec's
clarification entries that name the main session as the ruler, one ruling
counted once where both record it: `<n>` rulings, each on an indented line
with its clarification, the tag or step, the question, the ruling, the
reason, and the commits it produced — the clarification commit and any
commit a worker made from it, or, for a ruling answered to S6 or ruled
from its reply that has none after S6 removed the spec,
`no clarification commit (the spec was already removed)` (Phase 4) — and
`none` when the main session ruled nothing. Why: it is the list the user
reads before the tag and the push, so every ruling the run made without
the user is on it.

The lines under `Models and efforts` are the state file's as they stand;
`—` in an applied effort means the worker's records carry no `effort`
field. The `Rail observations` line lists the state file's
`rail observations:` entries other than `none`, each as `<tag>: <entry>`,
and reads `none` when there are none. The `Skipped gates` line lists the
state file's `skipped gates:` entries — the step, its tag, and the
outcome — and reads `none` when no worker skipped its gate. The
`Follow-up candidates` line lists what the run left for the user to take
outside it (§ The stop conditions, Outward actions): each outward action
it did not take — an issue to file, a backlog item — and each finding a
ruling deferred to a follow-up, with the clarification or the row it came
from, and, when the state file's `inbound:` line records a question not
received, that record with its tags and the causes to check — the main
session's own inbound under the settings precedence, or a send that
failed or was never made — or, for a tag whose worker quoted an error or
a notice, that cause (§ The message protocol), and each failed check
at S6's return, with the commits it names, and the work S6 left undone
for a point raised after the removal (Phase 4); it reads `none` when
there are none.

## The gates

Every question the skill asks is one of these gates. The last column is
what a session that cannot ask does in place of asking; the sentences
above, at each gate, are the rule, and this table repeats their outcomes.

| Gate | Asks | In a session that cannot ask |
|---|---|---|
| No arguments | The path | The run ends: `Autopilot stopped: no path given` |
| The argument is neither a brief nor a spec | Which it is | The run ends with the reason |
| Several plugins and no `Plugin:` | Which plugin | The run ends with the reason |
| A start check fails, or a settings stop — a value outside its grammar, `Role settings` included, or `CLAUDE_CODE_EFFORT_LEVEL` set while a role declares an effort | — (a stop with its reason) | The run ends with the same message |
| The launch line shows no `crossSessionInbound` accept, and a settings file that exists cannot be read or parsed, a read of a Windows policy value fails for a reason other than an absent key or value, a source sets a value other than `accept`, `hold`, or `refuse`, or the server-managed settings cache (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/remote-settings.json`) exists | Whether a settings file accepts inbound messages | The run ends naming the launch line |
| Budget: spent + projected > budget | Raise the budget to how much? | The run ends with spent, projected, and the remaining steps |
| A cap exceeded | A new cap | The run ends with the counts |
| Brief entry: S1's design table | A decision per row; "use your leans for the rest" accepted | Every row takes its lean; `lean adopted (the session could not ask)` per row; the reports say so row by row |
| A worker's question the spec answers | — (the main session answers from the spec) | The same answer |
| A worker's question the spec does not answer, a choice riding on a task-list confirmation included | — (the main session rules and records it, § How the main session rules) | The same ruling |
| S2 returned without its confirmation question, and the post-check of its task document finds a mismatch, or an open choice whose ruling differs from the document | Nothing on the first failure: S2 is resumed under `<tag>-r<k>` with the ruling, to amend, and the post-check runs again; on a second failure, a stop with the mismatch or the choice quoted | The first failure the same; on a second, the run ends with it quoted |
| Stop condition 7: (a) every option changes the batch's contract, none staying inside it; (b) an acceptance case corrected without both pieces of evidence | How to go on — (a) with the options, (b) with the case and the evidence missing | The run ends with the reason |
| A question of stop condition 7's kind — a way forward the main session cannot rule on — the main session raises that only a later step needs | Nothing until that step; then the question as it then stands | The run goes on and ends at that step with the question quoted |
| Any other stop condition, or a stop stated at its own step | How to go on | The run ends with the reason |
| The final gate | Tag, push, release | The run ends with the two reports and the finish line |

## Exit

On a finish, the final message holds `## User report` — its
`Main-session rulings` list included — `## Reviewer report`, every default a session that cannot ask took in place of a question, then
the sentence that the tag, the push, and the release are the user's, and
ends with `Autopilot finished — <baseline sha>..<last sha>` as its last
line, as the stop line is the last line on a stop. Why the last line: a
reader, and a grep over the trace, look for a run's end marker on the
final message's last line, and a sentence after it would hide it from
both. The skill tags nothing, pushes nothing, and deletes nothing outside
`git rm` in a worker's commit. Why: the second human gate is the release,
and a run that took it would have had one gate.

On a stop, the final message names the step and its tag, what is on disk
(the state file, the last session's files, the commits so far), what the
user can do — answer, raise a number, fix and re-run — and ends with
`Autopilot stopped: <reason>`. The state file holds the next action, so a
later run of the same batch reads where this one stopped.

## Writing rules

- Prompts, the spec, commit messages, and the reviewer report are in
  English. Why: the workers copy prompt text into commits and documents,
  and the repository's rules put those in English.
- A commit subject this skill gives — in a task block, a stop message, or
  the main session's clarification commit — is the default, written in the
  project's commit convention: the one the repository writes down (in the
  project's instruction files or its CONTRIBUTING), or, failing that, the
  pattern its recent commit subjects consistently share. The preamble's
  § 6 carries the rule to the workers (Templates § The preamble says why).
- The user report and the conversation are in the user's language.
- The fixed lines — the settings line, the launch and return lines, the
  question and answer first lines, the stop and finish lines, the report
  headings — are in English whatever the conversation's language. Why: the
  release checklist and the acceptance grep for them.
- No `git push`, no `git tag`, no release, in this session or any worker.

## Phase transitions

Each phase starts from the artifact the previous one produced, not from the
wording that closed it:

- Phase 0 → Phase 1 or 2: the state file written and, in an interactive
  main session, the settings line printed; in a headless main session the
  state file written is the artifact. Why: a headless main session keeps
  its record in the state file and the timeline (Templates § The settings
  line), so a transition that waited on a printed line would wait on a
  line the run is not required to print.
- Phase 1 → Phase 2: the spec's commit hash in the state file.
- Within Phase 2: each `<tag>.exit`; S2 → S3: the task document on disk,
  and, when S2 sent no confirmation question, the skipped-gate
  post-check's match recorded — after the amendment, when a mismatch
  resumed S2 to amend it;
  S3 → S3b: S3's `.exit`, the HEAD it left, and the Schema G verdict in
  its `result` other than `BLOCKED`; S3b → Phase 3: its Schema F
  verdict and the empty zero-diff output.
- Phase 3 → Phase 4: the record (plugin mode) or S4's reply (repo mode)
  with every FAIL classified, or `Acceptance: none` recorded.
- The exit: S6's commit, after the clarification commit of each question
  S6 asked, and the reports. A ruling that has no clarification commit,
  a failed check at S6's return, or, when S6 removed nothing, a
  clarification commit after S6's other commits — S6's own, or the main
  session's once S6 has ended — is not an absent artifact: it is
  recorded as Phase 4 says, and the run finishes.

An artifact absent after a return — no task document after S2, HEAD still
where S3 started, the `head:` the state file recorded at its first launch (the
batch gate not passed), a `## Verdict` of `BLOCKED` in S3's `result` (every
task blocked), no Schema F verdict after S3b
(a review over an empty range dispatches nothing) — is a stop naming it,
not a transition. Why the verdict as well as HEAD: an S3 whose every task
is blocked still moves HEAD — each BLOCKED note is committed on its own,
and task-implement makes the one-time `.gitignore` commit before it
dispatches the implementer — so HEAD alone would read it as a finished
step. Why S3's own start and not the baseline: HEAD leaves the
baseline before S3 runs — S1 commits the spec, S2's reviewer commits the
task document — so a comparison with the baseline would read an S3 that
built nothing as a finished step, review a documents-only range, pass the
acceptance with nothing to accept, and remove the plan and task documents
of a batch that implemented nothing.

Why: a phase's closing sentence has been read as the end of a whole skill
run; the next phase reads an artifact, so the artifact is what moves the
run forward, and its absence is what stops the run: a return without its
artifact is a finished session, not a finished step.
