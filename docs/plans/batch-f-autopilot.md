# Plan: Batch F — the autopilot skill, /kenspc-autopilot

Target: this repository (`kenspc` plugin), on top of v3.8.2 (`5c33c4a`).
Release: 3.9.0 — a new command and a new skill, so a minor release. This
batch makes no version bump and no tag; its CHANGELOG entry goes under a
`## 3.9.0 — unreleased` heading.

**Status: ruled.** The design was locked as F-1 to F-14 in
`docs/briefs/autopilot-method.md` (§ Locked design) by the main session and
checked against the repository, the Claude Code documentation, and three
harness probes in a headless Claude Code session on 2026-09-26. Every
question that check raised was decided by the main session within the
locked design on 2026-09-26 and is recorded in
[Design decisions](#design-decisions). This document is the complete
specification: the implementing session needs nothing beyond this file and
the repository. A locked point is written with a hyphen (F-1); a row of the
design tables without one (D1).

## Objective

1. An `autopilot` skill with `/kenspc-autopilot <path>` that runs one batch
   of this plugin's own chain from a spec or a brief to a local release
   preparation, unattended between two human gates: the rulings on a
   brief's design table, and the tag / push / release after the reports. It
   runs in an interactive main session and drives one headless `claude -p`
   session per role — S1 design (brief entry only), S2 `/kenspc-task`,
   S3 `/kenspc-task-implement`, S3b standalone `/kenspc-task-review`,
   S4 acceptance, S5 fix (on demand), S6 release preparation — through a
   driver script that ships with the skill and cross-session messaging:
   a worker asks the main session by message and waits; the main session
   subscribes to each worker's idle notice and ends its turn.
2. Two modes. `repo` (the default): the workers use the installed plugin,
   acceptance is the commands the brief names or nothing, and release
   preparation is one commit that removes the batch's plan and task
   documents. `plugin` (declared, or detected from a marketplace layout):
   the workers load the worktree's plugin with `--plugin-dir`, S4 runs a
   seed-project acceptance and files `docs/dry-runs/<batch>-acceptance.md`,
   and S6 makes the repository's release preparation.
3. Two reports at the end: a one-page user report in the conversation's
   language, and a reviewer report of fixed shape with a total-cost line.
4. A bash driver, `skills/autopilot/scripts/run.sh`, with a `--self-test`;
   a PowerShell mirror, `run.ps1`, written after the bash driver passes
   acceptance and checked with `pwsh` on macOS. Windows acceptance is a
   roadmap line.

**In scope:** F-1 to F-14 of the locked design (below); the documentation
the change requires.

**Out of scope:** any change to the eight existing skills, the eleven
agents, `shared/`, `references/`, `hooks/`, the eight existing commands,
and the repository's `scripts/`; any CONTEXT key; any new agent; agent
teams; any way of starting a worker other than `claude -p`; Windows
acceptance (a roadmap line); any edit inside a byte-identity section —
the canonical blocks (`canonical:run-dir`, `canonical:dispatch`,
`canonical:stats-line`, `canonical:verdict-shared`), the code-craft
canonical paragraphs, and the five reviewers' six shared sections.

### The locked design (F-1 to F-14)

Restated for reference from `docs/briefs/autopilot-method.md`. The rows
below refine these points; they do not reopen them. Where a lean reads a
point beyond its literal words, its row says so and why the reading stays
within the point's intent.

- **F-1 Naming and version.** Skill `autopilot`, command
  `/kenspc-autopilot <path>`, `disable-model-invocation: true`; runs in an
  interactive main session that can ask the user, started with a fixed
  `--name`, bypass permissions, and `crossSessionInbound: accept`; a new
  command, so the plugin goes to 3.9.0.
- **F-2 Two entry points**, decided by the document kind of the argument. A
  plan document (a spec) → unattended from S2 on. A brief → S1 drafts the
  spec with an M/D table of options and leanings, no rulings; the main
  session gives the table to the user, who rules; S1 finalizes and commits
  the spec; from there unattended. The brief is a generate-brief document
  plus one `## Autopilot` section (baseline commit, mode, version policy,
  budget, allowed and zero-diff files, acceptance cases, prior specs to
  read via `git show`). No new document type.
- **F-3 Two modes.** `repo` (default): sub-sessions use the installed
  plugin; acceptance = the commands the brief names, or no S4 at all, S3b
  being the last check; release preparation = what `## Autopilot` says, by
  default one commit that removes the batch's plan and task documents and
  touches no version. `plugin` (declared in `## Autopilot`, or detected
  from a marketplace layout — `.claude-plugin/marketplace.json` plus
  `plugins/<name>/.claude-plugin/plugin.json`): sub-sessions get
  `--plugin-dir <worktree plugin>`; S4 runs seed-project acceptance and
  writes `docs/dry-runs/<batch>-acceptance.md`; S6 does the repository's
  release preparation (CHANGELOG date, version bump, checklist, roadmap,
  remove plan/tasks, release commit, pre-flight).
- **F-4 Fixed topology:** S1 design (brief entry only), S2 `/kenspc-task`,
  S3 `/kenspc-task-implement`, S3b `/kenspc-task-review` standalone, S4
  acceptance, S5 fix (only for a defect the main session classified), S6
  release preparation. One role per session; never reuse a session across
  roles. Proposer ≠ ruler; implementer ≠ acceptor.
- **F-5 Mechanics.** A driver script ships with the skill
  (`skills/autopilot/scripts/run.sh`, later `run.ps1`) and is copied per
  batch to `~/Projects/_smoke/_prompts/<batch>-run.sh`; prompts are files;
  every worker starts with `--name <tag>` and
  `--settings '{"crossSessionInbound":"accept"}'`; each launch writes
  `.json`, `.err`, `.pid`, `.exit`, appends to `timeline.log`; costs go to
  `costs.txt`. Communication is cross-session messaging: the main session
  subscribes to each worker with `SendMessage` `notify_when_idle` and ends
  its turn, and the notice wakes it (a headless driver such as S4 cannot
  idle-wait, so it waits in a `sleep` loop and the notice arrives as a
  message between tool calls); a worker asks by `SendMessage` to the main
  session's name and waits in a `sleep` loop, at most 30 minutes, then
  writes the question into its final message and stops, and the main
  session falls back to `--resume`. No agent teams, no `--continue`;
  `--resume` is the fallback only. Cost of a session = its last cumulative
  `total_cost_usd`; the main session's own cost is estimated; sessions
  spawned by user-level hooks are observations, not cost. Evidence:
  `~/.claude/projects/<cwd with / as ->/<session_id>.jsonl` and its
  `subagents/`.
- **F-6 Preamble.** Every sub-session prompt opens with the common
  preamble: role, the main session's name and the ask protocol; exemplars
  to read (`git show <hash>^:docs/plans/…` of prior specs, named in
  `## Autopilot`); safety rails; locked design; out of scope; constraints.
  Self-contained — never "as batch X did".
- **F-7 Safety rails:** write only to the repository, `~/Projects/_smoke/`,
  and `$TMPDIR`; no `git push`, `git tag`, or release; no resource the
  brief does not name (databases, network services); no secrets; no
  `rm -rf` — discard by `mv` into `.trash/<name>-<timestamp>/`; deletions
  inside the repository only through `git rm`; any breach is a stop.
- **F-8 Ruling hierarchy:** locked design (immutable) > M/D rulings (the
  main session, within the lock; the user at brief entry) > CL
  clarifications during implementation (the main session; recorded in the
  spec and committed). Rulings beyond the letter of the lock are reported.
  The question channel is a `SendMessage` to the main session; the spec's
  Open Questions section says so.
- **F-9 Stop conditions and budget.** Stops: reopening a locked point; a
  forbidden section or file; guards red twice in a row; the same FAIL still
  failing after two fixes; session+run count or budget exceeded (ask); a
  rail breach; a question neither spec nor lock answers; a nested
  `claude -p` refused; the same step's session dead twice. A stop is a
  question to the user. Budget: default USD 200, set in `## Autopilot`,
  never hard-coded; the main session may stop to ask for more.
  Implementation is never narrowed; acceptance may be, with Not exercised
  recorded, and never the locked design's main path.
- **F-10 Acceptance (plugin mode):** dry-run a seed to confirm the path
  under test is reachable; one case per run; every driver reply is named in
  the record; the main session classifies each FAIL — plugin defect (S5 fix
  and re-run), behavior deviation (roadmap), observation; record sections
  fixed (Setup, Independence, Cases, Findings, Observations, Not exercised,
  Summary).
- **F-11 Two human gates only:** the spec (rulings at brief entry; a
  supplied spec counts as approved) and tag / push / release after the
  reports.
- **F-12 Two reports:** a user report (conversation language, one page)
  and a reviewer report of fixed shape, including a total-cost line.
- **F-13 `run.ps1`** mirrors `run.sh`, written after the bash driver passes
  acceptance, checked with `pwsh` on macOS (syntax plus one launch);
  Windows acceptance is a roadmap line.
- **F-14 Release 3.9.0;** CHANGELOG `## 3.9.0 — unreleased`; README,
  CLAUDE.md, checklist, manifests in sync; roadmap gains only the Windows
  line.

Where each point lands:

| Point | Steps | Rows |
|---|---|---|
| F-1 | 1.1, 1.3, 2.1, 2.2 | M11, M15, D5, D21 |
| F-2 | 1.1 | M1, M2, M3, M9, D1, D2, D14 |
| F-3 | 1.1, 1.2 | M3, M14, M16, D3, D17, D18 |
| F-4 | 1.1 | M8, M10, D15, D16 |
| F-5 | 1.1, 1.2, 3.1 | M4, M5, M6, M7, M12, D4, D5, D7, D8, D9, D10, D12, D13, D19 |
| F-6 | 1.1 | D6 |
| F-7 | 1.1, 1.2 | D4, D21 |
| F-8 | 1.1 | D13, D14, D16 |
| F-9 | 1.1 | D9, D10, D11, D12, D15, D22 |
| F-10 | 1.1 | M16, D16 |
| F-11 | 1.1 | D14, D22 |
| F-12 | 1.1 | M12, D20 |
| F-13 | 3.1 | M10, D8 |
| F-14 | 2.1–2.4; the release commit | M13, D23, D24 |

## Background

All file references are at `5c33c4a` unless a probe is named.

- **The two detectors the repository already has (F-2).**
  `generate-plan/SKILL.md` Phase 1 Step 1 recognizes a brief by its first
  line `# Requirement Brief:` or by the sections Outcome, Scope, Failure
  Modes, The Hard Part, Context; `prototype/SKILL.md` and
  `diagnose-bug/SKILL.md` point at that test by reference.
  `task-implement/SKILL.md` Phase 1 Step 1 tells a task document (entries
  with `**Status:**` markers) from a plan document (Implementation Steps by
  Phase / Step, no Status markers) and refuses a plan. No skill recognizes
  an `## Autopilot` section, and generate-brief's template (which is out of
  scope) ends with `## Discovery Notes`; its rules place `## Open Questions`
  after `## Context` and before `## Discovery Notes`.
- **The gates the workers reach.** generate-task Phase 2 ends its
  presentation with `Confirm, or adjust tasks before writing?` and has no
  cannot-ask branch (0 occurrences of the shared wording); task-implement
  Step 3 ends with `Proceed with automated implementation?` and "Wait for
  explicit confirmation", no cannot-ask branch; generate-plan's approval
  stop has one (`Plan not written: awaiting approval.`), as do
  diagnose-bug (3) and prototype (9). So S2 and S3 ask through the message
  channel at exactly those two lines, and S1 — a plain `-p` session with a
  design prompt, not `/kenspc-plan` — asks only when it needs a ruling.
  task-review Step 1 takes CUSTOM_INSTRUCTIONS "that name commits or a
  range" as the review's range, pinned by SHA, and otherwise reviews
  `<merge-base>..HEAD` with an upstream or `HEAD~1..HEAD` without one.
- **What the harness does, from the documentation (checked 2026-09-26,
  Claude Code 2.1.283).** CLI reference: `--name` "Set a display name for
  the session, shown in `/resume` and the terminal title. You can resume a
  named session with `claude --resume <name>`"; `--settings <file-or-json>`
  "Path to a settings JSON file or a JSON string"; `--output-format`
  "(only works with --print)"; `--permission-mode` for `-p` "that's
  `default` when nothing is configured"; `--max-budget-usd <amount>`
  "Maximum dollar amount to spend on API calls (only works with --print)";
  `--session-id <uuid>` "Use a specific session ID for the conversation";
  `--continue` is not used (F-5). Sessions page, "Name your sessions": the
  duplicate-name rename "doesn't check the `--name` of a background or
  `-p` session at startup", so two `-p` sessions can share a name;
  transcripts are `~/.claude/projects/<project>/<session-id>.jsonl`, and
  "the entry format is internal to Claude Code and changes between
  versions". Cross-session messaging page: "The receiving Claude reads the
  message between tool calls during an active turn"; "Claude Code binds an
  inbox socket for a `claude -p` session like an interactive one"; "To let
  a `-p` worker take messages unattended, start it with
  `crossSessionInbound` set to `accept` in its `--settings` value"; the
  default with no value "groups sessions that bypass permission prompts
  into one class" and a bypassing receiver "holds each message for your
  approval" unless the sender also bypasses; a `-p` session keeps a held
  message for `dialogExpiry` (default `5m`) and then drops it;
  `notify_when_idle` (v2.1.236) is one-shot, "Only the Claude in your main
  conversation can subscribe", and "If no notice arrives within 12 hours,
  Claude Code drops the subscription and tells Claude"; `/list-agents`'s
  first line "is this session's own name" and "This session isn't one of
  the rows" (v2.1.239); notices to `claude -p` senders need v2.1.271;
  the socket accepts an optional first line `{"type":"auth","token":…}`
  on macOS, and the page documents no message line format; limits: a
  serialized message over 1,048,576 characters is refused, a burst of
  about 30 recent sends to one session is refused, the receiver queues at
  most 50 accepted messages and drops identical repeats.
  `crossSessionInbound` precedence (settings reference): managed settings,
  then the `--settings` flag, then user settings, first value found; a
  project or local `hold` / `refuse` applies when stricter. Headless page:
  a background subagent keeps `claude -p` open until it completes, up to
  10 minutes of idle waiting (`CLAUDE_CODE_PRINT_BG_WAIT_CEILING_MS`); a
  background Bash task is terminated about five seconds after the result;
  with `--continue` or `--resume`, `total_cost_usd` "reports the
  conversation's whole total, earlier runs' spend included". Tools
  reference: a command that reaches its timeout is moved to the background
  "unless the command starts with `sleep`"; the block on a bare
  `sleep 60` ("Blocked … use Monitor with an until-loop … Do not chain
  shorter sleeps to work around this block") is the Bash tool's own
  message, seen in the main session's probe `f-probe2` and not documented
  on that page.
- **The three probes of 2026-09-26** (main session `claude-plugin-9d`,
  interactive from VS Code, bypass permissions, `crossSessionInbound`
  unset; this session `f-s1`, a `-p` child started by
  `~/Projects/_smoke/_prompts/f-run.sh` with `--name f-s1` and
  `--settings '{"crossSessionInbound":"accept"}'`):
  1. The main session's handshake (`f-main-notes.md`): `f-probe` exited in
     6 s before a subscription could be made ("No agent named 'f-probe' is
     reachable"); `f-probe2` showed `--name` with `-p` in ListAgents, the
     subscription accepted, the idle notice arriving in the main session
     after its turn ended, and the Bash block on bare `sleep 60`;
     `f-probe3` sent a message to the main session, waited in one
     `caffeinate -t 60` call, and received the reply on its first wait.
     `caffeinate -t N`, `timeout N caffeinate -w 1`, `sleep 20`, a bounded
     `until … sleep 2` loop, and `python3 time.sleep` pass the block;
     `sleep 30` is blocked. Right after `f-probe` exited, ListAgents showed
     `t-a1 [64fc96] · interactive · busy`: the remember plugin's SessionEnd
     hook (`save-session.sh` → `claude -p --model haiku --max-turns 4`), a
     user-level hook's session — observed, not counted.
  2. This session's nesting probe (`f-s1-w`, cwd
     `~/Projects/_smoke/batch-f-probe`, started with the same driver):
     `ListAgents` here named this session on its first line (`f-s1
     [a7cd41]`) and listed the main session and the worker as rows, plus
     `t-7e [74872c] · interactive · started 0s ago`, a user-level hook's
     session. A `notify_when_idle` subscription from this `-p` session's
     main conversation was accepted ("Subscribed — you will get one notice
     here when "f-s1-w" is next idle (or exits)"). The worker ran a
     grandchild `claude -p "Reply ok and stop" --name f-s1-gc
     --output-format json --permission-mode bypassPermissions` from its
     Bash tool: result `ok`, exit 0, USD 0.30, `CLAUDECODE=1` inherited
     and no refusal at four levels (main → f-s1 → f-s1-w → f-s1-gc); its
     stderr held only the "no stdin data received in 3s" warning, since
     the worker's inline command did not redirect stdin. The worker's
     message arrived here as `<cross-session-message from-name="f-s1-w"
     from-mode="bypass">` between two tool calls; this session replied;
     the worker received the reply on its second `caffeinate -t 60` call
     (its final message quotes it), exited 0, USD 0.59, 7 turns. No idle
     or exit notice reached this session between tool calls in the 26
     minutes after the worker's exit (23:10:27); the notice arrived at
     23:36, after this session's final reply had ended its turn, and
     started a new turn in the `-p` process — so a `-p` subscriber cannot
     rely on the notice, and a headless session that subscribes gets an
     extra turn after it thinks it is done, its JSON `result` then being
     that turn's last message (CL1); the interactive main session's probe
     did receive it between turns. Both transcripts are under
     `~/.claude/projects/-Users-kenspc-Projects--smoke-batch-f-probe/`
     (77 and 39 lines), and the hook wrote a `.remember/` directory into
     the probe's cwd.
  3. `claude plugin validate --strict` on a temporary copy of
     `plugins/kenspc` with `skills/autopilot/SKILL.md`,
     `skills/autopilot/scripts/run.sh`, `scripts/run.ps1`, and
     `commands/kenspc-autopilot.md` added: "Validation passed", exit 0.
     `check-no-model-names.sh` scans every file under `skills/`, so the
     scripts are in its scope. `pwsh` 7.6.6, `uuidgen`, `python3`,
     `caffeinate`, GNU `timeout`, and `jq` are on this machine.
- **The drivers and records the method came from.** `e-run.sh` (batch E)
  and `f-run.sh` (batch F, the same plus `--name <tag>` and the
  `--settings` value) start `claude -p "$(cat <prompt-file>)"` with
  `--plugin-dir`, `--permission-mode bypassPermissions`,
  `--output-format json`, stdin from `/dev/null`, in a `( trap '' HUP; … )
  &` subshell that writes `<tag>.json`, `.err`, `.exit` and appends
  `start` / `end` lines to a timeline; `f-cost.sh` upserts
  `<tag> <session_id> <total_cost_usd>` into `f-costs.txt`. The batch C, D,
  and E records (§ 1 Setup) share the rows Plugin, Claude Code, Mode,
  Session model, Installed copy (the source gate: the first `SKILL.md` read
  is under the worktree, and `plugins/cache/kenspc-claude-plugin` occurs 0
  times), Seed project, Projects, Traces, Cost, and an Independence
  paragraph; § 3 classifies each FAIL as plugin defect, behavior
  deviation, or observation. Batch numbers: sub-sessions + runs 7 + 11,
  10 + 14, 6 + 7; `--resume` 5, 9, 7 (+5 inside S4); cost USD 99, not
  reported, 132 + main session.
- **Counting sentences the new skill and command change.** CLAUDE.md:
  "all eight skills", "syncing eight files", "bump all eight together"
  (lines 103, 108, 110), "the seven other skills" (line 296); release
  checklist row 1 "Lists all 8 kenspc slash commands" (line 81); the
  README's skills table (eight rows) and Commands line; `plugin.json`'s
  description names the skills' coverage and "eleven reusable subagents"
  (unchanged); `marketplace.json`'s description lists the workflow steps.
  The plugin README's Requirements says Claude Code v2.1.0+.
- **Guards.** `check-all.sh` runs every `scripts/check-*.sh`; the release
  checklist and CLAUDE.md pin `guards run: 10` and `self-tests run: 9`;
  `scripts/` is zero diff in this batch, so both stay.
- **The roadmap** has ten items under `## Next minor (3.9.0)`; F-14 adds
  one line (Windows acceptance of `run.ps1`).

## Design decisions

Questions found while checking F-1 to F-14 against the repository, the
documentation, and the probes. Each row gives the options considered, the
lean the draft proposed with its reason, and the ruling. Every ruling was
decided by the main session within the locked design on 2026-09-26; it
binds this batch, and the implementing session applies it without
reopening it. Every ruling takes the draft's lean, with six amendments:
M5 gives the wait snippet two forms (the driver's polls `<tag>.exit`, the
worker's counts only); M10 places the two-round split at generate-task's
confirm gate, since `task-implementer` implements every incomplete task it
is given; M12 makes the main session's cost an estimate with a stated
basis rather than "not measured"; M14 words the CLAUDE.md sentence on the
evidence (auto mode's classifier, absent under bypass permissions); D9
resumes a cap-ended worker once the budget is raised; D23 corrects the
command count (eight existing commands become nine). The Implementation
Steps follow the rulings.

Five rulings read a locked point beyond its literal words, and each row
says why the reading stays within that point's intent: M10 (F-13's
ordering against F-4's fixed topology, for this batch's own run only); M12
(F-5's "estimated" as a number with a stated basis); M13 (F-14's "only the
Windows line" and the roadmap heading); D4 (the workspace path as a field
with the lock's path as its default); D9 (a per-worker `--max-budget-usd`
backstop under F-9's budget). The main session lists them in its report.

### Mismatches between the locked design and the repository or the harness (M1–M16)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| M1 | F-2 decides the entry "by the document kind of the argument". The repository has two detectors: generate-plan's brief test and task-implement's plan-or-task test. What is a spec, and what happens to a task document or an unrecognizable file? | (a) By reference: a brief is what generate-plan Phase 1 Step 1 recognizes (`# Requirement Brief:` first line, or the five sections); a spec is a file that is not a brief and has the plan shape task-implement Step 1 describes — an `## Implementation Steps` section or Phase / Step headings, and no `**Status:**` marker; a task document (Status markers) stops the run naming the plan it came from (`/kenspc-autopilot <plan path>`); anything else stops and asks which it is. In a session that cannot ask, both stops end the run with the reason. (b) A detector of the skill's own. | (a). Two skills already point at generate-plan's test by reference (prototype, diagnose-bug), and a third detector would drift from both; a task document is a spec that S2 already consumed, so running S2 on it would decompose a decomposition. | **(a)** — decided by the main session within the locked design. Two skills already point at generate-plan's brief test by reference; a task document is a spec S2 already consumed. Step 1.1. |
| M2 | F-2 puts the batch's settings in `## Autopilot`; a spec entry may have none, and a brief may lack the section. Which defaults apply, and which fields stop the run when absent? | (a) Every field has a default and none is required: `Baseline:` HEAD at start; `Mode:` detected (D3), else `repo`; `Version:` `none`; `Budget:` `USD 200`; `Caps:` (D11); `Allowed files:` and `Zero diff:` empty (no zero-diff check); `Acceptance:` `none`; `Release preparation:` `default`; `Prior specs:`, `Must read:`, `Challenge seeds:` empty. The run prints the effective settings in one fixed line before its first launch (Fixed strings). The one stop is an ambiguous mode (D3). (b) `Budget:` required, since an unattended run with a silent USD 200 default is money nobody stated. (c) `Baseline:` and `Budget:` required. | (a). F-9 names USD 200 as the default the lock chose; a required field turns every spec-entry run into a question, which F-11's "a supplied spec counts as approved" rules out; the printed settings line puts the defaults in front of the user before any session starts, and a user who wants a smaller budget writes the field. | **(a)** — decided by the main session within the locked design. F-9 chose the USD 200 default and F-11 rules out a question on a supplied spec; the printed settings line is the disclosure. Step 1.1. |
| M3 | Where `## Autopilot` sits in a brief, and how it gets there. generate-brief's template ends with `## Discovery Notes` and is out of scope; the reminder hook fires on any Write under `docs/briefs/`. | (a) The last section of the brief, after `## Discovery Notes`, written by the user (or by whoever prepares the batch); generate-brief unchanged; the plugin README's autopilot section documents the labels (D1); a spec carries the same section when S1 copies it from the brief, so a later spec-entry run has the settings. (b) Ask generate-brief to write it — out of scope. | (a). F-2 says "a generate-brief document plus one `## Autopilot` section", and the brief's own sections keep their order, which generate-plan's gap-check reads; the last position is the one no skill parses past. | **(a)** — decided by the main session within the locked design. Written by the user as the last section; generate-brief is out of scope, and no skill parses past the end. Steps 1.1, 2.2. |
| M4 | F-5's wait for the interactive main session — subscribe, end the turn, the notice wakes it — has two gaps the probes showed: a subscription to a worker that has already exited fails ("No agent named … is reachable", `f-probe`), and no notice reached a `-p` subscriber (this session, 92 s after its worker exited). The 12-hour expiry is a third. | (a) The main session subscribes right after the launch; when the subscription is refused because the worker is not reachable, it reads `<tag>.exit` — present means the worker already finished, absent with the pid gone means it died (D12); the notice is a wake signal only, and `<tag>.exit` is the completion evidence: on every wake it re-reads the state file (D19) and `<tag>.exit`, and with no `.exit` and a live pid it subscribes again and ends its turn; when the notice reports the subscription expired (12 hours), the same check runs. A headless driver never subscribes (M5). (b) Subscribe and trust the notice. | (a). The lock's mechanism holds — the main session's probe received the notice — but a notice is wording, and Plugin Design Lessons says a transition rests on an artifact; `.exit` is the artifact the driver writes, and reading it on every wake makes the lost, early, or expired notice a delay, not a wrong step. | **(a)** — decided by the main session within the locked design. The notice is the wake; `<tag>.exit` is the artifact (Plugin Design Lessons); re-read on every wake, re-subscribe while the pid lives. Step 1.1. |
| M5 | F-5's `sleep` loop for a headless driver (S4, and a headless autopilot in the acceptance): the Bash tool blocks a bare `sleep` of 30 s or more and refuses chained short sleeps; `caffeinate -t 60` passes but is macOS-only. | (a) The skill's snippet is a bounded `until` loop that polls the artifact and returns early: `n=0; until [ -f "$LOGS/$TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done` — one tool call of at most about 60 s, portable to Linux and Git Bash; the driver script wraps the worker in `caffeinate -i` when that command exists (D7), so macOS stays awake without the wait depending on it. (b) `caffeinate -t 60` per call, macOS only, as the batch F preamble does. (c) `python3 -c 'import time; time.sleep(60)'`, needing python3. | (a). It is the form the block's own message recommends ("use Monitor with an until-loop"), it ends as soon as `.exit` appears instead of waiting the full minute, and it needs nothing outside POSIX sh; the machine-awake concern moves to the driver, where a macOS-only command is a branch, not a dependency. Known behavior records that each iteration is one tool call (a 30-minute wait is about 30 calls). | **(a), in two forms** — decided by the main session within the locked design. The driver form polls `<tag>.exit` and returns early; the worker form, waiting for an answer, has nothing to poll and uses the same bounded loop with the counter only (one call of about 60 s). `caffeinate -i` in the driver when present. Known behavior: one tool call per iteration. Fixed strings; Steps 1.1, 1.2, 2.2. |
| M6 | F-5's `.exit` as the completion signal, against a driver that posts to the main session's socket when the worker ends. The messaging page documents only the socket's auth line; no message line format is documented. | (a) No driver completion message: `<tag>.exit` is the completion artifact and the notice the wake; the driver never opens the socket. (b) Reverse-engineer the line format. | (a). Undocumented is unsupported, and a driver that guesses a wire format breaks silently on a release; the lock already names `.exit`. Recorded here so the question is not reopened. | **(a)** — decided by the main session within the locked design. Undocumented is unsupported; `.exit` is the artifact. Steps 1.1, 1.2. |
| M7 | Duplicate session names: the rename on a duplicate "doesn't check the `--name` of a … `-p` session at startup", so an earlier batch's worker still running, a resumed session, or a hook's session can share a tag's name, and `SendMessage` then needs a `[ref]`. | (a) Tags are unique by construction — `<batch>-s<n>` with the batch name (D5), a resume under `<tag>-r<k>` — and before every send the main session lists agents and, when two rows carry the name, addresses the one whose start time matches the launch by its `[ref]`; a worker addresses the main session by the name in its preamble, listed once. (b) Random suffixes on every tag. | (a). A stable tag is what the timeline, the costs file, and the record name; the listing already carries the `[ref]` for the case, and a resumed session keeps its own session id under a new tag, so nothing is renamed. | **(a)** — decided by the main session within the locked design. Unique tags by construction; ListAgents before each send; `[ref]` only when two rows share the name. Step 1.1. |
| M8 | F-4's S3b is a standalone `/kenspc-task-review`; its default range without an upstream is `HEAD~1..HEAD`, one commit of a batch that made many, and with an upstream `<merge-base>..HEAD`, which reviews the batch only when the branch tracks a remote. | (a) S3b's task block names the range as custom instructions — `/kenspc-task-review review the range <baseline sha>..<HEAD sha at S3's end>` — which task-review pins as `Mode: commits` with that range. (b) Rely on the upstream. | (a). The batch's change set is `<baseline>..HEAD` by definition, whatever the branch tracks; the main session knows both SHAs. The S3 run's own review (task-implement Phase 2) reviews against the task document; S3b is the second look over the whole batch as one change set, which batch E ran by hand. | **(a)** — decided by the main session within the locked design. The batch's change set is `<baseline>..<HEAD at S3's end>` by definition; S3b names it as custom instructions. Step 1.1. |
| M9 | S1 writes the spec under `docs/plans/` with the Write tool, and the reminder hook prints the generate-plan note on every such Write; `hooks/` is zero diff. | (a) S1's task block says the note applies to plan generation and that the spec is written by design outside generate-plan; S1 ignores the note. (b) S1 writes with a shell heredoc to dodge the hook. | (a). The hook is a reminder, not a gate, and its own text says to ignore it when the skill was invoked on purpose; dodging it hides a Write from the trace the acceptance reads. | **(a)** — decided by the main session within the locked design. The hook is a reminder; dodging it hides the Write from the trace. Step 1.1. |
| M10 | F-13 has `run.ps1` "written after the bash driver passes acceptance"; F-4 fixes the topology at S1–S6 with S5 for classified defects only, and a task document is implemented whole by S3. | (a) For this batch's own run — driven by the main session by hand, not by the skill — the spec's last phase holds `run.ps1` alone (Phase 3); S2 generates the task document for Phases 1–2 (custom instructions naming them); after S4's first round passes the bash driver, a second short round runs: `/kenspc-task <spec> phase 3`, `/kenspc-task-implement`, `/kenspc-task-review` over its commits, and S4's driver check of `run.ps1`. The skill's own topology (F-4) is unchanged. (b) `run.ps1` in the same S3 run, and F-13's "after acceptance" read as "checked in the second acceptance round". (c) A `Depends on:` gate that S3 leaves BLOCKED and a later run sets back to TODO. | (a), beyond F-4's letter for this batch only and within its intent: the batch that builds the autopilot cannot yet be run by it, and the main session's own plan for this batch already names the second round (S3c); (b) writes the mirror before its model is known to work, which F-13 exists to prevent; (c) misuses a dependency gate as a scheduler. | **(a), beyond F-4's letter for this batch's own run only, which the main session drives by hand; reported** — decided by the main session within the locked design, and confirmed against the code: `task-implementer` receives only TASK_FILE and implements every incomplete task, so a batch-gate answer cannot limit S3 to the tasks before `run.ps1`; the split therefore happens at generate-task's confirm gate ("adjust tasks before writing" is a supported answer). Round 1: `/kenspc-task <spec>`; at the confirm gate the Phase 3 task is dropped, so the task document covers Phases 1–2 with its Doc-sync task. After S4's bash round passes, round 2: `/kenspc-task <spec>` again; at the confirm gate only Step 3.1 and its Doc-sync task are kept, written as a second task document under a different file name asked for at that gate (if the skill overwrites the first document, all DONE by then, that is accepted, and the release commit removes whatever exists); then `/kenspc-task-implement`, `/kenspc-task-review` over its commits, and S4's driver check. The skill's own topology (F-4) is unchanged. Implementation Steps (Phase 3); Testing Strategy. |
| M11 | The plugin README requires Claude Code v2.1.0+; the autopilot needs cross-session messaging (v2.1.224), `notify_when_idle` (v2.1.236), the own-name listing (v2.1.239), and notices to `-p` senders (v2.1.271). | (a) The autopilot's README row and the Requirements section state v2.1.271 or later for this skill; the plugin's minimum is unchanged, since every other skill runs on it. (b) Raise the plugin's minimum. | (a). One skill's requirement is that skill's; a raised plugin minimum would say the review runs need messaging, which they do not. The skill's Prerequisites check the harness at start — `ListAgents` names this session and lists a peer — and stop with the version line when it does not (D21). | **(a)** — decided by the main session within the locked design. One skill's requirement is that skill's; the start check is ListAgents naming this session. Steps 1.1, 2.2. |
| M12 | F-5 says the main session's own cost is estimated; an interactive session has no JSON result, and `/cost` output is not available to the model as data. | (a) The total-cost line reports the measured sum of the workers (each session's last cumulative `total_cost_usd`) as the total, and says the main session's cost is not measured, with its number of wakes and messages; the user reads `/cost` in that session. (b) A fixed fraction added as the estimate. (c) Ask the user to paste `/cost` at the end — a third human gate. | (a), reading "estimated" as "stated as unmeasured with its size in wakes" rather than inventing a number: a fraction has no evidence behind it, and F-11 allows two gates. | **(a), amended so that F-5's "estimated" yields a number; beyond the letter, reported** — decided by the main session within the locked design. The total-cost line reports (1) the measured sum of the workers' last cumulative `total_cost_usd`, and (2) the main session's own cost as an estimate labeled "estimated": the main session's turn count (launches + wakes + answers + the final turn) × the mean cost per turn across this batch's workers (each worker's `total_cost_usd` ÷ `num_turns` from its JSON), with the basis stated on the line; the user may replace it with `/cost`. A number with a stated basis is what "estimated" means; "not measured" alone would drop F-12's total. Step 1.1 (D20). |
| M13 | F-14: "roadmap gains only the Windows line". The roadmap's heading is `## Next minor (3.9.0)`, which is stale once 3.9.0 ships. | (a) In the release commit, the heading becomes `## Next minor (3.10.0)` and the Windows line is appended as item 11; the ten items are unchanged. (b) Heading unchanged. | (a), beyond F-14's letter and within its intent: the heading names the version planned work waits for, and "only the Windows line" is about items; a heading naming a shipped version would send the next batch's reader to the wrong release. | **(a), beyond F-14's letter and within its intent; reported** — decided by the main session within the locked design. The release procedure of every previous release retitled the heading to the next minor (the v3.7.0 and v3.8.0 diffs), so it is the repository's convention, and the "only" is about items. The release commit. |
| M14 | In `plugin` mode the workers run with `--plugin-dir <worktree plugin>` under bypass permissions and S3 edits those very files; CLAUDE.md § Development Workflow says to edit the plugin's skill and agent files in a session started without `--plugin-dir` (auto mode's classifier gave no verdict). | (a) Keep the lock: batches B–E's implementation sessions edited the plugin under `--plugin-dir` with bypass permissions, and the E lesson says a session sees its own plugin edits only in the next session, which is why S3b, S4, and S5 are separate sessions; CLAUDE.md gains one sentence that the editing rule concerns auto mode and interactive sessions, and that the autopilot's headless workers run under bypass permissions. (b) Workers without `--plugin-dir`, editing the installed copy's source — impossible, the installed copy is a cache. | (a). The rule's evidence names auto mode; four batches of headless bypass sessions are the counter-evidence. | **(a), with the CLAUDE.md sentence worded on the evidence** — decided by the main session within the locked design. The Development Workflow rule's block is auto mode's classifier inside a `--plugin-dir` session; under `--permission-mode bypassPermissions` there is no classifier, and the autopilot's headless workers run that way, with `--plugin-dir` in plugin mode; a worker sees a plugin edit only in the next session, so review, acceptance, and fix are separate sessions. Step 2.1. |
| M15 | F-1's `disable-model-invocation: true` is a command property; the skill's description owns routing, and the trigger words ("run this batch unattended", "无值守跑这批") appear in every worker preamble, which a worker reads as its prompt. | (a) The description carries the exclusions — "not when the prompt says you are a sub-session of a main session (the autopilot's own workers), not to implement one task (task-implement), not to review (task-review)" — and the preamble's first sentence is fixed (Fixed strings), so the exclusion has one shape to match; workers are `-p` sessions whose prompt is a slash command or a task block, and the acceptance has a routing case. (b) Also `disable-model-invocation: true` on the skill. | (a). (b) would remove the natural-language triggers F-1 asks the description to carry; a fixed preamble sentence is the one signal the description can name. | **(a)** — decided by the main session within the locked design. The fixed preamble first sentence is the one signal the description can name; the routing acceptance case stays. Step 1.1; Testing Strategy (case 8). |
| M16 | F-3's `repo` mode: "acceptance = the commands the brief names, or no S4 at all". Where do the results go in a repository that has no `docs/dry-runs/` convention, and what is the report when there is no S4? | (a) An S4 worker (one role per session; implementer ≠ acceptor) runs each `Acceptance:` command at the S3b HEAD in the repository, one command per Bash call, and replies with each command, its exit code, and the last 20 lines of its output; the main session classifies each nonzero exit (D16) and writes the results into the reviewer report's acceptance lines; no file is written into the repository unless `Acceptance record:` names a path. With `Acceptance: none`, no S4 session is started, and the report's acceptance line reads `none named; S3b is the last check`. (b) The main session runs the commands itself. | (a). A product repository has no place for a record the plugin invented; the report is where the user reads the run, and a path in the field lets a repository that wants a file say so; (b) puts an acceptor's work into the ruler's context. | **(a)** — decided by the main session within the locked design. No file in a product repository unless `Acceptance record:` names one; results in the reviewer report; `none named; S3b is the last check`. Step 1.1. |

### Architecture choices (D1–D24)

| # | Question | Options | Lean and why | Ruling |
|---|---|---|---|---|
| D1 | The `## Autopilot` grammar (F-2). | (a) A bullet list under the heading, one `- <Label>: <value>` per field, labels in English whatever the brief's language, in any order, unknown labels ignored with a note in the settings line: `Baseline:` a commit (SHA or `HEAD`); `Mode:` `repo` or `plugin`; `Plugin:` a plugin directory under `plugins/` (plugin mode with several plugins); `Version:` `none` or a version string; `Budget:` `USD <number>`; `Caps:` `<n> sessions, <m> resumes`; `Allowed files:` paths, one per line or comma-separated; `Zero diff:` paths for the zero-diff check; `Byte-identity exceptions:` free text; `Acceptance:` `none`, or one sub-bullet per case — a command or a case description, its PASS criterion after ` — PASS: `, and `(optional)` at the end of a case that may be cut; `Acceptance record:` a path (repo mode); `Release preparation:` `default`, `keep`, or sub-bullets of instructions; `Must read:` paths; `Challenge seeds:` sub-bullets; `Prior specs:` `<hash>^:<path>` entries for `git show`; `Workspace:` a directory (D4). (b) A YAML block. | (a). It is the brief's own list form, readable by the user who writes it, and the labels are the anchors the skill reads; a YAML block would be the "new document type" F-2 rules out. | **(a)** — decided by the main session within the locked design. Step 1.1; Fixed strings. |
| D2 | Whether the `## Autopilot` labels join a guard (`check-doc-sync-anchors.sh`'s groups). | (a) No guard: the repository's `scripts/` is zero diff in this batch, and the labels have one carrier (the autopilot skill) and one reader (the same skill), so an anchor guard would compare a file with itself; the labels are Fixed strings, and the README documents them. (b) A guard entry when a later batch touches `scripts/`. | (a). A guard exists to catch a rename in one file but not the other; with one file there is no other. Listed as a roadmap candidate in the main session's report if a second carrier ever appears. | **(a)** — decided by the main session within the locked design; `scripts/` is zero diff, and the labels have one carrier. Fixed strings. |
| D3 | Mode detection and the `--plugin-dir` value (F-3). | (a) `plugin` when the repository root holds `.claude-plugin/marketplace.json` and at least one `plugins/*/.claude-plugin/plugin.json`; `Mode:` in `## Autopilot` wins over detection either way. The plugin directory is `<root>/plugins/<name>`, `<name>` from `Plugin:` when given, else the single `plugins/*/` that holds a `plugin.json`; with several and no `Plugin:`, stop and ask; in a session that cannot ask, stop with the reason. The value passed is absolute, from `git rev-parse --show-toplevel`. (b) Detect by `plugin.json` alone. | (a). The lock names both files; a marketplace with several plugins is a release of one of them, which nobody but the user can name. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D4 | The workspace — where prompts, logs, seeds, and `.trash` live (F-5, F-7). | (a) `~/Projects/_smoke/` by default, the lock's path, with `_prompts/` (the copied driver, the preamble, the task blocks, the assembled prompts), `_logs/` (`<tag>.json/.err/.pid/.exit/.session`, `<batch>-timeline.log`, `<batch>-costs.txt`, `<batch>-state.md`, `<batch>-report.md`), seed projects `<batch>-*`, and `.trash/`; `Workspace:` in `## Autopilot` relocates the whole tree; `$TMPDIR` for anything else. (b) Under the repository's `.kenspc/`. | (a), the lock's path as the default and a field that relocates it: F-5 and F-7 name `~/Projects/_smoke/` literally, and a plugin-mode seed is a clone that cannot live inside the repository it clones; the field keeps another machine from needing that exact path. | **(a), beyond the letter; reported** — decided by the main session within the locked design: the lock's path is the default, `Workspace:` relocates it, and the rails name the workspace. Step 1.1. |
| D5 | Batch name, session tags, and the main session's name (F-1, F-5). | (a) The batch name is the argument file's base name without extension (`batch-f-autopilot`); tags are `<batch>-s1`, `-s2`, `-s3`, `-s3b`, `-s4`, `-s5`, `-s6`, a re-run of a step `-s4b`, `-s5b`, and a resume `<tag>-r<k>`; the main session's fixed name is `<batch>-main`, passed by the user at launch (`claude --name <batch>-main --permission-mode bypassPermissions --settings '{"crossSessionInbound":"accept"}'`, the line the README gives); when the session's listed name differs (the user started it otherwise), the skill uses the name `ListAgents` prints on its first line and records it. (b) Short letters (`e-s3`). | (a). The base name is unique in the repository and readable in `ps`; the main session's name must be known to every worker before it starts, and the listing's first line is the one source of truth. | **(a)** — decided by the main session within the locked design; this batch's own main session is `claude-plugin-9d`, started without a name, which is the listed-name branch. Step 1.1. |
| D6 | Prompt assembly and the six preamble parts (F-6). | (a) The skill writes `_prompts/<batch>-preamble.md` once and `_prompts/<batch>-<tag>-task.md` per launch, and the launched prompt is their concatenation, `_prompts/<batch>-<tag>.md`, in English. The parts: (1) role — the fixed first sentence `You are a headless sub-session of the batch <batch> main session <main name>, unattended.` — the main session's name, and the ask protocol with the wait snippet (M5) and the fixed question form (D13); (2) exemplars — the spec or brief path, `git show <hash>^:<path>` for each `Prior specs:` entry, the `Must read:` paths, and the repository's CLAUDE.md; (3) safety rails — F-7's text with the workspace and the repository root filled in; (4) locked design — the numbered points with one-line topics and the file section to read them in; (5) out of scope and (6) constraints — the spec's sections by name (the brief's, at brief entry), plus the repository's CLAUDE.md. Each task block is a fixed template with its variables filled: S1 (the brief entry): the draft-spec task in the shape of this batch's, with `Challenge seeds:`, the M/D table with an empty Ruling column, the pointer-label rule, and "send the compact table to <main name> and wait"; S2: `/kenspc-task <spec path>`; S3: `/kenspc-task-implement <task doc path>`; S3b: `/kenspc-task-review review the range <baseline>..<sha>`; S4: the acceptance cases with their PASS criteria, the driver line, the record path (plugin mode) or the reply shape (repo mode); S5: the classified defect, the case to make pass, and "commit the fix alone"; S6: the release preparation per mode (D17, D18). (b) One prompt file per launch with the preamble inlined by hand. | (a). One preamble file is one thing to read in the record, and the task block is the only part that varies; English because the spec, the commit messages, and the code artifacts are English by this repository's rules, and a worker copies task text into them. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D7 | `run.sh`'s interface and behavior (F-5). | (a) `run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]`; environment: `AUTOPILOT_LOGS` (default `<workspace>/_logs`), `AUTOPILOT_PLUGIN_DIR` (when set, `--plugin-dir` is passed; plugin mode), `AUTOPILOT_BUDGET_USD` (when set, `--max-budget-usd`; D9), `APPEND_SP` (`--append-system-prompt`, the cannot-ask variant), `AUTOPILOT_CLAUDE` (the executable, default `claude`). A fresh launch generates a UUID (`uuidgen`, else `python3 -c 'import uuid;print(uuid.uuid4())'`) and passes `--session-id`, writing it to `<tag>.session` before the process starts, so the transcript path and the resume id are known even when no `.json` lands; a resume passes `--resume <id>` and writes the same id. Always: `--name <tag>`, `--settings '{"crossSessionInbound":"accept"}'`, `--permission-mode bypassPermissions`, `--output-format json`, stdin from `/dev/null`, stdout to `<tag>.json`, stderr to `<tag>.err`, the subshell under `trap '' HUP` and `&`, wrapped in `caffeinate -i` when that command exists; `<tag>.pid` (the subshell), `<tag>.exit` (claude's status, written when it ends), `start` / `end` lines in `<batch>-timeline.log` (the batch name from `AUTOPILOT_BATCH`, default the tag's prefix before `-s`). `run.sh --self-test`: with `AUTOPILOT_CLAUDE` pointed at a stub the script writes under `$TMPDIR` (prints a JSON with `result`, `session_id`, and `total_cost_usd`, sleeps 1 s, exits 0), it launches the stub through the same path and checks that `.session`, `.pid`, `.json` (parseable, with `result`), `.err`, and `.exit` (reads `0`) exist and the timeline has both lines; exit 1 naming the missing one. At batch start the skill copies the shipped script to `_prompts/<batch>-run.sh` and runs the copy's `--self-test` once. (b) The `e-run.sh` interface unchanged (positional resume, no session id). | (a). The positional interface is the four batches' habit and stays; `--session-id` closes the gap F-5's fallback has when a worker dies before writing its JSON; the stub self-test proves the launch path on a machine without spending a session; the copy insulates a running batch from a plugin-mode S3 that edits `run.sh` itself. | **(a)** — decided by the main session within the locked design. Step 1.2. |
| D8 | `run.ps1`'s interface (F-13). | (a) The same positional interface and files; the prompt read with `Get-Content -Raw` from the file, never passed on a command line the caller quotes; the worker started as `Start-Process pwsh -ArgumentList @('-NoProfile','-Command', <inner>) -WindowStyle Hidden -PassThru`, where the inner command runs `claude` with the same arguments, redirects stdout and stderr to the two files, and writes `<tag>.exit` and the timeline's `end` line when it returns; `<tag>.pid` is the started process's id; the same environment variables; `--self-test` with a stub `claude.ps1` on a temporary PATH entry. Checked on macOS with `pwsh -NoProfile -Command '[System.Management.Automation.Language.Parser]::ParseFile(...)'` reporting no errors and one `--self-test` launch. (b) A `Start-Job` wrapper. | (a). `Start-Process` is the one PowerShell primitive that detaches like the bash subshell; the inner command is where `.exit` can be written after `claude` returns; the file-borne prompt is what removes every quoting problem `-p "<text>"` has on Windows. | **(a)** — decided by the main session within the locked design. Step 3.1. |
| D9 | A per-worker cost cap (F-9). | (a) Every launch passes `--max-budget-usd <remaining>`, the batch budget minus the spent sum (D10), so a runaway worker cannot spend past the batch; a session ended by its cap reports a non-`success` subtype in its JSON, which the main session treats as the step's session dead (D12) and, since the budget is now spent, stops to ask. (b) No per-session cap; the check before each launch only. | (a), beyond F-9's letter and within its intent: the budget is read from `## Autopilot`, never hard-coded, and the cap is the only mechanism that bounds a session already running; batch E's 44-minute S3 shows one session can spend a large share. | **(a), beyond F-9's letter; reported, with one addition** — decided by the main session within the locked design. A worker ended by its cap is the budget stop; after the user raises the budget it is resumed under `<tag>-r1` with the continue prompt and the new remaining cap, counted as a resume. Steps 1.1, 1.2. |
| D10 | Budget accounting (F-9). | (a) Spent = the sum over sessions of each session's last cumulative `total_cost_usd` (a resume's JSON replaces its predecessor's value, since it carries the whole total), read from the `<batch>-costs.txt` upsert the skill makes after every `.exit` (the `f-cost.sh` logic, inside the skill's Bash); projected = the largest single-session cost of this batch so far, or budget ÷ 6 before the first session; before each launch, when spent + projected > budget, stop and ask "raise the budget to how much?" with spent, projected, and the remaining steps; the answer sets the budget for the rest of the run and is recorded in the state file and the reports, not in the brief. In a session that cannot ask, stop. (b) A fixed estimate per step. | (a). Per-step dollar estimates drift with every model generation and would be hard-coded numbers in a prompt; the batch's own sessions are the only evidence in the run. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D11 | Session and resume caps (F-9). | (a) `Caps:` default `16 sessions, 8 resumes` — one and a half times the largest batch so far (D: 10 + 14 runs); exceeding either is a stop that asks for a new cap. (b) No caps, budget only. | (a). F-9 names "session+run count … exceeded (ask)" as a stop, so a count exists; the default is the largest observed batch with room, and the field overrides it. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D12 | Liveness, death, and the resume fallback (F-5, F-9). | (a) A step's session is dead when its pid is gone and `<tag>.exit` is absent 10 s later (the subshell writes `.exit` right after `claude` returns), or its JSON's subtype is not `success`; the main session then resumes it once under `<tag>-r1` with the fixed continue prompt (`Continue the task in your prompt from where you stopped; your last message was cut short.`); a second death of the same step is a stop. A live pid is never killed and never judged hung: the signals the main session reports when asked are the pid, the size of `<tag>.err`, the mtime of the transcript named by `<tag>.session`, and `git log -1 --format=%ct` in the worker's cwd. (b) A no-growth timeout that kills the worker. | (a). The E lesson is liveness by pid and growth, not by clock; a test suite or a long implementation is silent for longer than any timeout a prompt would pick, and a killed worker leaves a half-applied task. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D13 | The question protocol between a worker and the main session (F-5, F-8). | (a) A worker asks with one message whose first line is `question <tag>: <one line>` and whose body gives the context, the options, and its suggested answer, then waits as M5's snippet says, at most 30 minutes, then writes the question into its final message under `## Question for the main session` and stops; the main session answers with one message whose first line is `answer <tag>: <one line>` and whose body is the ruling, quoting nothing the worker sent; when the answer is a ruling beyond the spec it is recorded as a CL in the spec by the main session (F-8) after the step ends. Questions are answered in arrival order; at most one worker is live at a time in the fixed topology, and a message from any other session (a hook's) is recorded as an observation. Messages carry summaries and paths, never a report's text (the 1,048,576-character cap and the about-30-message burst refusal); a worker with a table to show writes it to a file and sends the path. (b) Free-form messages. | (a). One fixed first line per direction is what the transcript search and the record find, and what tells a worker's question from a hook session's message; the suggested answer is what makes the main session's ruling a one-line reply. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D14 | The brief entry's human gate (F-2, F-11). | (a) S1 sends its compact M/D table (number, one-line question, options, lean) and the draft's path; the main session prints the table to the user as received, plus the draft's path, and asks for a ruling per number, with "use your leans for the rest" as an accepted answer. A partial answer is followed by the remaining rows, asked again with their leans, until every row is ruled or the user delegates the rest; a ruling that contradicts a locked point is refused with the point named and asked again. Then the main session sends S1 one message, first line `rulings <batch>: <n> rulings`, body one `M<n>: <ruling>` / `D<n>: <ruling>` per row, ending with the fixed instruction: fill the Ruling column, set the status line to ruled, run the pointer-label grep, commit the spec alone as `docs(plans): add batch <name> spec`, reply with the hash, and stop. In a session that cannot ask, every row takes its lean, the reports say so row by row, and the rulings message says `lean adopted (the session could not ask)` per row. (b) One row per question to the user. | (a). The table is the artifact S1 produced and the user rules on it as batch E's main session did; refusing a contradiction is the lock's immutability (F-8); the delegated remainder keeps a long table from stalling a user who trusts the leans, and the cannot-ask branch is the same delegation, recorded. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D15 | S3b's verdict and the fix loop (F-4, F-9). | (a) S3b's Schema F verdict PASS: on to S4. FAIL, or PARTIAL with HIGH rows deferred: the main session classifies each HIGH and each row-3 or row-5 FAIL as a plugin defect (S5 fix from that row, `Fix issue <ID> from run <run dir>: <one line>`; then a narrowed S3b over `<S3b HEAD>..<fix HEAD>`) or accepts the deferral with a reason recorded as a CL; the second narrowed review that still FAILs is the "guards red twice in a row" stop. DEFERRED MEDIUM and LOW rows are classified once — fix in S5, or a roadmap candidate listed in the reviewer report — and recorded as a CL. (b) Every FAIL is a stop. | (a). It is what batch E's main session did across three review rounds; the fixed loop keeps the count of rounds where F-9 puts it. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D16 | Classifying an S4 FAIL, and what each class does (F-10; repo mode under M16). | (a) The main session classifies each FAIL with the batch E record's three classes: plugin defect — S5 fix, then the case re-run in a new S4 session (`-s4b`) that runs only that case; behavior deviation — a roadmap line drafted for the release commit (plugin mode) or a reviewer-report line (repo mode); observation — recorded. The same case still failing after two fixes is a stop. In repo mode the classes are the same with "implementation defect" for the first. Every classification is a CL entry in the spec, committed by the main session (`docs(plans): record clarifications settled after <step>`). (b) S4 classifies. | (a). F-10 names the classes and the ruler; the record separates evidence from judgment (Independence), and the spec's CL section is where F-8 puts rulings made during implementation. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D17 | `repo` mode's release preparation (F-3). | (a) `Release preparation: default` — one commit, `docs: remove batch <name> plan and tasks`, that `git rm`s the batch's plan and task documents and touches no version and no CHANGELOG; `keep` — no S6, the documents stay; a list of instructions — S6 runs them as its task block, after the default removal unless the list says `keep`. `Version: <string>` in repo mode is passed to S6 as an instruction to bump wherever the repository's CLAUDE.md says versions live, and is otherwise ignored with a settings-line note. (b) Also a CHANGELOG line by default. | (a). A product repository's CHANGELOG has a convention the plugin cannot know; the lock names the removal and no version as the default, and the field carries the rest. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D18 | `plugin` mode's release preparation (F-3). | (a) S6's task block: the repository's release checklist (`docs/release-checklist.md` when it exists) and CLAUDE.md's release convention govern; the steps named: the CHANGELOG's `— unreleased` heading gets today's date; the plugin manifest's version becomes `Version:`; the manifests' descriptions name the new capability; the checklist's counting rows follow; the roadmap's shipped items leave and its heading names the next minor; the batch's brief, plan, and task documents are `git rm`ed; one release commit in the repository's convention (`chore(release): v<version> - <one line>` here); the pre-flight block runs and its two count lines are in S6's reply; no tag, no push. With `Version: none` in plugin mode, S6 makes the removal commit only and the reports say the release was not prepared. (b) Hard-code this repository's procedure. | (a). Stack-agnostic in form — the checklist and CLAUDE.md are read — and this repository's procedure in substance, which is what the lock lists. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D19 | The main session's state across wakes (F-5; Plugin Design Lessons). | (a) `_logs/<batch>-state.md`, rewritten at every transition: the settings line, the current step and its tag, each session's tag, id, cost, and result, the questions answered, the stops, the CL numbers recorded, and the next action; on every wake (a notice, a message, a user reply) the skill re-reads it and `<tag>.exit` before acting; the timeline and costs files are appended as F-5 says; the reviewer report is built from the state file at the end and also written to `_logs/<batch>-report.md`. (b) Keep the state in the conversation. | (a). A wake starts a new turn whose only reliable memory is a file; a long batch compacts the conversation, and the state file is what makes the resumed turn continue from the artifact rather than from the wording. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D20 | The two reports (F-12). | (a) Both in the final message, under `## User report` and `## Reviewer report`; the user report in the conversation's language, at most one page: what the batch built, the release commit, what needs the user (tag / push / release; any stop or deferred item), and the cost. The reviewer report in English, fixed fields in this order: batch and mode; baseline → release hash (or the last commit); the spec's read command (`git show <hash>:<path>`); M / D / CL counts and the list of rulings beyond the letter; files changed and the zero-diff result; byte-identity / guards / counts (plugin mode: the pre-flight lines); acceptance, one line per case with its cost and result, or `none named; S3b is the last check`; total cost (M12); Not exercised; release-preparation state; sessions / messages / resumes / stops with reasons, one line per session with tag, id, cost, and result. (b) Files only. | (a). The final message is what the user sees at the second gate; the file copy is the record. | **(a)** — decided by the main session within the locked design; the total-cost line as M12 rules it. Step 1.1. |
| D21 | Start checks (F-1, F-7). | (a) Before anything is written: the argument file exists and is a brief or a spec (M1); the working tree is clean except the argument file when it is untracked (`git -c core.quotePath=false status --porcelain -uall`), else stop; HEAD equals `Baseline:`, else stop naming both; `ListAgents` returns this session's name on its first line, else stop with the version requirement (M11); the workspace is writable; the driver copy's `--self-test` passes; in plugin mode, the plugin directory holds a `plugin.json`. Each failing check is a stop with its reason; in a session that cannot ask, the run ends with the same message. (b) Trust the arguments. | (a). Every check is a stop the lock already lists or a condition the workers assume; an unattended run on the wrong base or a dirty tree is spent money. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D22 | The main session's cannot-ask branches (the standing constraint). | (a) Every stop and question of the skill has one, worded "In a session that cannot ask (a system reminder to work without stopping), …": start checks and settings stops end the run with the reason; the budget and cap questions end the run with the numbers; the brief-entry rulings take the leans (D14); a worker's question that the spec answers is answered from the spec, and one it does not answer ends the run with the question quoted; the final gate ends the run with the two reports and `Autopilot finished` (Fixed strings). A gate table summarizes them and repeats the outcomes without replacing the sentences. (b) Cannot-ask means stop everywhere. | (a). The skill is built for a session that can ask, and the constraint asks for the branch at every gate; taking the leans at brief entry is the only branch that acts, and it is recorded row by row. | **(a)** — decided by the main session within the locked design. Step 1.1. |
| D23 | Where the documentation lands (F-14). | (a) CLAUDE.md: Project Overview (autopilot), the directory layout (`skills/autopilot/` with `SKILL.md` and `scripts/run.sh`, `run.ps1`; `commands/kenspc-autopilot.md`), the count sentences (eight → nine skills; seven → eight other skills), a new orchestration pattern under § Subagent Review Architecture — "Sessions, not agents (autopilot)" — with the topology, the driver, the messaging protocol, and M14's sentence, and § Non-Goals (no agent teams; no driver completion message; the workspace path). Plugin README: a Skills row, a Commands row and the `/kenspc:autopilot` mention, a new section "Autopilot" (the launch line, `## Autopilot`'s labels, the workspace, the two gates, the reports, the version requirement), Known behavior items (one tool call per wait iteration; no notice to a `-p` subscriber; same-name sessions; hook sessions and hook files in seeds; the 12-hour expiry; message limits). Root README: a skills-table row and the Commands line. `plugin.json` and `marketplace.json` descriptions gain the autopilot. CHANGELOG: `## 3.9.0 — unreleased` with an intro, `### Added`, and `### Known behavior`. Release checklist: row 1 → 9 commands; a new row 11 for `/kenspc-autopilot <spec>` (repo mode, one-task seed batch), the end-to-end row becoming 12 with its references; pre-flight unchanged. (b) A smaller set. | (a). Each is a Durable documents row's own condition. | **(a), with the counts corrected against the file system** — decided by the main session within the locked design: eight existing commands (the checklist's row 1 already says 8) become nine; eight skills become nine; "the seven other skills" becomes eight. Steps 2.1–2.4. |
| D24 | The smoke row's cost note (F-14). | (a) Row 11 states its cost: one headless `repo`-mode batch on a one-task seed, about USD 10–20 at the batch E per-session figures (an implement run USD 1–6, a review USD 4–6, twice), and that `plugin` mode was exercised once, in this batch's acceptance record, and is not part of the per-release smoke. (b) Both modes every release. | (a). A plugin-mode smoke is a nested acceptance of this repository at every release, several times the cost; the checklist's other rows already accept one-time records for the expensive paths. | **(a)** — decided by the main session within the locked design. Step 2.4. |

### Standing constraints

- Rules are rationale-anchored ("Why: …" prose), not imperatives; no `MUST`
  / `NEVER` / `CRITICAL`, no inline effort or reasoning tokens, no model
  names (`bash scripts/check-no-model-names.sh` exits 0; it scans
  `skills/autopilot/scripts/` too, so the drivers pass no `--model`).
- A check written into the skill is in rubric form: what passing looks
  like, then the named ways it fails. No generic checklist items.
- No edit inside any byte-identity section, and every guard stays green:
  the canonical blocks, the code-craft canonical paragraphs, and the five
  reviewers' six shared sections are untouched — every file that holds one
  is on the zero-diff list.
- Zero diff, checked by
  `git diff --stat 5c33c4a HEAD -- plugins/kenspc/agents plugins/kenspc/shared plugins/kenspc/references plugins/kenspc/hooks plugins/kenspc/commands/kenspc-brief.md plugins/kenspc/commands/kenspc-prototype.md plugins/kenspc/commands/kenspc-plan.md plugins/kenspc/commands/kenspc-task.md plugins/kenspc/commands/kenspc-diagnose.md plugins/kenspc/commands/kenspc-task-implement.md plugins/kenspc/commands/kenspc-task-review.md plugins/kenspc/commands/kenspc-guide.md plugins/kenspc/skills/generate-brief plugins/kenspc/skills/generate-plan plugins/kenspc/skills/generate-task plugins/kenspc/skills/generate-guide plugins/kenspc/skills/diagnose-bug plugins/kenspc/skills/prototype plugins/kenspc/skills/task-implement plugins/kenspc/skills/task-review scripts docs/roadmap.md docs/dry-runs/README.md`,
  which prints nothing before the release commit (the release commit then
  changes `plugin.json` and the roadmap). The files this batch touches:
  `plugins/kenspc/skills/autopilot/SKILL.md`,
  `plugins/kenspc/skills/autopilot/scripts/run.sh`,
  `plugins/kenspc/skills/autopilot/scripts/run.ps1` (Phase 3),
  `plugins/kenspc/commands/kenspc-autopilot.md`, and the documents in
  [Documentation impact](#documentation-impact).
- No new agent (`plugin.json` says "eleven reusable subagents"), no new
  CONTEXT key, no agent teams, no way of starting a worker other than
  `claude -p`, no `--continue`.
- `effort:` frontmatter unchanged in every file (release-checklist
  pre-flight diff); the new skill has none and follows the session.
- Per-skill `version: 3.0.0` in every skill, the new one included — it
  denotes the architecture generation (CLAUDE.md).
- Every question point the skill has carries a cannot-ask branch worded
  "In a session that cannot ask (a system reminder to work without
  stopping), …" (D22); the gate table repeats the outcomes and does not
  replace the sentences.
- Plugin files state their evidence in their own words and carry no pointer
  labels — B-n, C-n, D-n, E-n, F-n, M-n, CL-n, "ruling", batch names,
  dry-run records. The criterion for every plugin file this batch adds
  (`skills/autopilot/SKILL.md`, `scripts/run.sh`, `scripts/run.ps1`,
  `commands/kenspc-autopilot.md`):
  `grep -nE 'batch [A-Z]\b|dry-run\b|\bruling\b|\b[BCDEF]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>`
  (the `dry-run\b` alternative by CL2, so the record path
  `docs/dry-runs/…` passes)
  prints nothing. It prints nothing on the eight existing skills at
  `5c33c4a` and many lines on this document, so it can fail. Two words
  the skill needs are outside the pattern by construction: the skill
  names its own report fields "M / D / CL counts" as `design rulings and
  clarifications`, and the word "batch" alone (a batch of work) is
  allowed — only `batch <capital letter>` is a pointer.
- Guards keep to bash 3.2 and are not edited in this batch (D2); `run.sh`
  keeps to bash 3.2 and POSIX tools for the same reason (macOS ships bash
  3.2), with `uuidgen` or `python3` for the UUID and `caffeinate` as an
  optional branch.
- Plugin Design Lessons apply: every transition rests on an artifact —
  `<tag>.exit`, the state file, the committed spec, the task document, the
  record — never on a notice's or a message's wording; no hook guards
  workflow state; scratch under the workspace is git-ignored, not
  tool-ignored, so seeds' probe files follow the run directory's naming
  rule.
- This spec and the acceptance record are in English; the skill's text is
  English with trigger phrases in English and Chinese; the user report
  follows the conversation's language.
- The dogfood: the task document for this batch comes from `/kenspc-task`
  on this spec, which generates the Doc-sync task from the Documentation
  impact below; it is not added by hand. Under M10, the first task
  document covers Phases 1–2 and a second, later one Phase 3.

## Fixed strings

These strings are load-bearing: the release checklist or the acceptance
greps for them, a worker or the main session parses them, or a later step
reads them. Spell them exactly as given, in every file that carries them.

| Anchor | Exact form | Carried by |
|---|---|---|
| Autopilot section | `## Autopilot`, then `- <Label>: <value>` bullets; labels `Baseline:`, `Mode:`, `Plugin:`, `Version:`, `Budget:`, `Caps:`, `Allowed files:`, `Zero diff:`, `Byte-identity exceptions:`, `Acceptance:`, `Acceptance record:`, `Release preparation:`, `Must read:`, `Challenge seeds:`, `Prior specs:`, `Workspace:`; values `repo` / `plugin`, `none`, `USD <n>`, `<n> sessions, <m> resumes`, `default` / `keep`, ` — PASS: `, `(optional)` | `autopilot/SKILL.md`, `plugins/kenspc/README.md`, briefs and specs |
| Settings line | `Autopilot settings — batch <batch>, mode <repo\|plugin>, baseline <sha>, budget USD <n>, caps <n> sessions / <m> resumes, version <v\|none>, acceptance <k> cases\|none, release preparation <default\|keep\|custom>, workspace <path>, wait <interactive\|headless>` (the last field by CL1) — in English whatever the conversation language | `autopilot/SKILL.md`, `docs/release-checklist.md` (row 11) |
| Preamble first sentence | `You are a headless sub-session of the batch <batch> main session <main name>, unattended.` | `autopilot/SKILL.md` (the preamble template and the description's exclusion) |
| Launch line | `S<n> started — <tag> pid <pid> session <session-id> — <prompt path>` | `autopilot/SKILL.md`, `docs/release-checklist.md` (row 11) |
| Return line | `S<n> returned — exit <code>, cost USD <c>, <success\|subtype> — <json path>` | the same |
| Question | first line `question <tag>: <one line>`; the worker's final-message section `## Question for the main session` | `autopilot/SKILL.md` (the preamble template) |
| Answer | first line `answer <tag>: <one line>` | `autopilot/SKILL.md` |
| Rulings | first line `rulings <batch>: <n> rulings`; per row `M<n>: <decision>` / `D<n>: <decision>` (the placeholder by CL3; the parsed part is the `M<n>: ` / `D<n>: ` prefix); `lean adopted (the session could not ask)` | `autopilot/SKILL.md` |
| Continue prompt | `Continue the task in your prompt from where you stopped; your last message was cut short.` | `autopilot/SKILL.md` |
| Stop line | `Autopilot stopped: <reason>` — the last line of the final message on any stop | `autopilot/SKILL.md`, `docs/release-checklist.md` (row 11) |
| Finish line | `Autopilot finished — <baseline sha>..<last sha>` | the same |
| Report headings | `## User report`, `## Reviewer report` | `autopilot/SKILL.md` |
| Acceptance line without S4 | `none named; S3b is the last check` | `autopilot/SKILL.md` |
| Driver files | `<tag>.json`, `<tag>.err`, `<tag>.pid`, `<tag>.exit`, `<tag>.session`; `<batch>-timeline.log` lines `start <tag> pid <pid> …` / `end   <tag> exit <status>`; `<batch>-costs.txt` lines `<tag> <session_id> <total_cost_usd>` | `scripts/run.sh`, `scripts/run.ps1`, `autopilot/SKILL.md` |
| Driver self-test | `run.sh --self-test` / `run.ps1 --self-test`, exit 0 and the line `self-test passed` | the same, `docs/release-checklist.md` (row 11) |
| Wait snippet, driver form | `n=0; until [ -f "$LOGS/$TAG.exit" ] \|\| [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done` | `autopilot/SKILL.md` (the S4 task block and any headless driver) |
| Wait snippet, worker form | `n=0; until [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done` — one call of about 60 s while waiting for an answer, nothing to poll | `autopilot/SKILL.md` (the preamble template) |
| Commit subjects | `docs(plans): add batch <name> spec` (S1); `docs: remove batch <name> plan and tasks` (repo S6 default); `docs(plans): record clarifications settled after <step>` (the main session) | `autopilot/SKILL.md` |
| Command | `/kenspc-autopilot <path to a spec or a brief>` | `commands/kenspc-autopilot.md`, READMEs, `docs/release-checklist.md` |
| Version requirement | `Claude Code v2.1.271 or later` (the autopilot skill) | `plugins/kenspc/README.md` |
| CHANGELOG heading | `## 3.9.0 — unreleased` | `plugins/kenspc/CHANGELOG.md` |
| Unchanged | `guards run: 10`, `self-tests run: 9`; every existing fixed string of the eight skills | as today |

## Implementation Steps

Phase 1 is the skill; Phase 2 documents it and follows Phase 1. Phase 3
(`run.ps1`) runs after the bash driver passes acceptance (M10) and is
decomposed and implemented in a second round: in round 1, `/kenspc-task`
on this spec drops the Phase 3 task at its confirm gate, so the first task
document covers Phases 1–2 with its Doc-sync task; after S4's bash round
passes, `/kenspc-task` runs again and keeps only Step 3.1 and its Doc-sync
task as a second task document, which `/kenspc-task-implement`,
`/kenspc-task-review` over its commits, and S4's driver check then run.

### Phase 1: The autopilot skill (F-1 to F-12)

**Step 1.1: Write `skills/autopilot/SKILL.md`**

- File: `plugins/kenspc/skills/autopilot/SKILL.md` (new). Structure and
  tone of `diagnose-bug` and `prototype`: frontmatter, an opening that names
  the phases, Trigger Phrases, Quality bar, Prerequisites, Arguments, the
  phases with Goal / Inputs / DONE when / Constraints, a gate table, Exit,
  Writing rules, Phase transitions; rules carry their Why in the skill's
  own words (M4's probe evidence as "a subscription made after the worker
  exited was refused, and a headless subscriber received the notice
  only as a new turn after its final reply";
  M5's as "the Bash tool blocks a bare sleep of thirty seconds or more").
  File references use `${CLAUDE_PLUGIN_ROOT}`.
- Frontmatter: `name: autopilot`; `version: 3.0.0`;
  `argument-hint: <path to a spec or a brief>`; no `effort:`;
  `description` in substance (wrap as the other skills do):

  > Run one batch of the kenspc chain unattended, from a spec or a brief to
  > a local release preparation (无值守跑完一批): one headless session per
  > role — task decomposition, implementation, standalone review,
  > acceptance, fix, release preparation — driven from this session with
  > a shipped driver script and cross-session messages, stopping only for
  > the rulings on a brief's design table and for the tag, push, and
  > release at the end. Use only when the user hands over a whole batch to
  > run to its release preparation. Not for implementing one task or a
  > task document (use task-implement), not for a review (use
  > task-review), not for planning (use generate-plan), and never when the
  > prompt says you are a headless sub-session of a batch's main session:
  > that prompt is one of this skill's own workers. Trigger on: "put this
  > spec on autopilot", "run this batch unattended", "take this batch to
  > release", "无值守跑这批", "这批交给你跑到发布", "自动跑完这批", or
  > invokes /kenspc-autopilot directly.
- Trigger Phrases: the positive phrases (English and Chinese, a few more of
  each); an "Avoid triggering" list — one task or a task document
  ("implement this task", "帮我实作这个 task" → task-implement); a review
  ("review 一下", "review my changes" → task-review); a plan or a brief to
  write (generate-plan, generate-brief); and any prompt that opens with the
  preamble's first sentence (Fixed strings), with the Why: the skill's own
  workers read a prompt that names an unattended batch, and a worker that
  started another autopilot would nest the batch inside itself (M15).
- Quality bar, in substance: a useful run reaches the release preparation
  with every step's evidence on disk — the spec committed, the task
  document, the commits, the run directories, the record — asks the user
  only at the two gates, and stops rather than guess on anything the lock
  or the spec does not answer; a run that narrows the implementation, or
  that approves a worker's question on the user's behalf, has failed the
  bar.
- Prerequisites: a git repository; Claude Code v2.1.271 or later with
  cross-session messaging available — `ListAgents` names this session on
  its first line (M11); an interactive session that can ask, started with
  a name, bypass permissions, and `crossSessionInbound: accept` (the launch
  line, D5); the workspace (D4).
- Arguments: PATH — a spec (a plan document) or a brief (M1). No
  arguments: ask for the path; in a session that cannot ask, stop.
- Phase 0, Settle. Goal: the settings, the workspace, and the start checks
  (D21) — the entry kind (M1), `## Autopilot` read with defaults (M2, D1),
  the mode and the plugin directory (D3), the workspace tree and the driver
  copy with its `--self-test` (D4, D7), the batch name and the main
  session's name (D5), the state file (D19). DONE when the settings line
  (Fixed strings) has been printed and the state file written. Every
  failing check is a stop with `Autopilot stopped: <reason>`; the
  cannot-ask branch of each (D22).
- Phase 1, Design (brief entry only). Goal: a ruled spec committed.
  Inputs: the brief; the preamble (D6) and the S1 task block. DONE when
  the spec's commit hash is in the state file. The flow: launch S1 (the
  launch line; subscribe; end the turn — M4); on S1's `question` message
  carrying the compact table, the human gate (D14); the `rulings` message;
  S1's reply with the hash; the state file. A supplied spec skips this
  phase (F-11).
- Phase 2, Build. Goal: the batch implemented and reviewed. S2, S3, S3b in
  order, each a launch / wait / return with the fixed lines; a worker's
  question at generate-task's confirmation or task-implement's batch gate
  is answered from the spec — the confirmation is `yes` when the task list
  matches the spec's steps, and a mismatch is a question to the user
  (never "yes" on the user's behalf); S3b's range (M8); the verdict loop
  (D15); the zero-diff check after S3b (`git diff --stat <baseline> HEAD --
  <Zero diff paths>` prints nothing, else a stop); budget and caps before
  each launch (D9, D10, D11); death and resume (D12), a worker ended by its
  cap being the budget stop and resumed under `<tag>-r1` with the new
  remaining cap once the budget is raised (D9).
- Phase 3, Accept. Goal: the acceptance run and every FAIL classified.
  Plugin mode: S4 with the record (F-10; the batch E record's sections);
  repo mode: S4 with the commands, or no S4 (M16); classification and S5
  (D16); the narrowing rule — cases marked `(optional)` may be cut when the
  budget check fails, in the order listed, with Not exercised recorded, and
  an unmarked case that cannot be run is a stop (F-9).
- Phase 4, Release preparation and reports. Goal: S6's commit and the two
  reports. S6 per mode (D17, D18); the zero-diff check again; the reports
  (D20); the state file's last transition; the final message ends with
  `Autopilot finished — <baseline>..<last sha>` and the sentence that tag,
  push, and release are the user's (F-11).
- The preamble and task-block templates (D6), the question protocol (D13),
  the two wait snippets (M5: the driver form polling `<tag>.exit`, the
  worker form counting only), and the driver's interface (D7) are written
  in the skill as fenced blocks a worker or the skill copies, each with its
  Why.
- Gate table: every question the skill asks, its cannot-ask outcome (D22).
- Writing rules: prompts, the spec, commit messages, and the reviewer
  report in English; the user report and the conversation in the user's
  language; the fixed lines in English whatever the conversation language.
- Phase transitions rest on artifacts: the settings line and state file;
  the spec's commit; each `<tag>.exit`; the task document; S3b's Schema F;
  the record or the S4 reply; S6's commit; the reports.
- Done when: the file exists with the frontmatter above and
  `version: 3.0.0`; the description carries the exclusions and both
  languages' triggers; the five phases carry Goal, Inputs, DONE when, and
  their Whys; the templates, the protocol, the wait snippet, the gate
  table, the stop conditions, the budget rule, the reports' fields, and
  the fixed strings are present; the pointer-label grep prints nothing;
  `bash scripts/check-no-model-names.sh` exits 0;
  `claude plugin validate --strict ./plugins/kenspc` passes.
- Why: the skill is the whole of F-1 to F-12; every later step either
  points at it or documents it.

**Step 1.2: Write `skills/autopilot/scripts/run.sh`**

- File: `plugins/kenspc/skills/autopilot/scripts/run.sh` (new,
  executable), per D7: the interface, the environment variables, the
  `--session-id` and `.session` file, the fixed files and timeline lines,
  stdin from `/dev/null`, the `caffeinate -i` branch, `--max-budget-usd`
  from `AUTOPILOT_BUDGET_USD`, `--plugin-dir` from `AUTOPILOT_PLUGIN_DIR`,
  `--append-system-prompt` from `APPEND_SP`, and `--self-test` with the
  stub. Bash 3.2; `set -u`; every path quoted; no `rm -r`; the stub under
  `$TMPDIR`. A header comment states the interface and the files it
  writes.
- Done when: `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`
  prints `self-test passed` and exits 0 from any directory; with the stub
  replaced by one that exits 3, the self-test exits 1 naming `.exit`;
  `bash -n` passes; the pointer-label grep and `check-no-model-names.sh`
  pass on the file.
- Why: the driver is what every worker and the acceptance record name; a
  script that ships with the skill is the same on every batch, and the
  self-test proves the launch path without a session.

**Step 1.3: Add `commands/kenspc-autopilot.md`**

- File: `plugins/kenspc/commands/kenspc-autopilot.md` (new), the shape of
  the eight existing command files: `name: kenspc-autopilot`; a one-line
  description ("Explicit entry point for the autopilot skill — run one
  batch unattended (无值守跑完一批) from a spec or a brief to a local
  release preparation."); `argument-hint: <path to a spec or a brief>`;
  `disable-model-invocation: true`; a body that reads
  `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/SKILL.md` and passes
  `$ARGUMENTS` through.
- Done when: the file matches the other commands line for line except
  name, description, argument hint, and skill path;
  `claude plugin validate --strict ./plugins/kenspc` passes.
- Why: commands are explicit entry points only; the skill's description
  owns the routing (v3.4.2).

### Phase 2: Documentation (F-14)

**Step 2.1: Repository CLAUDE.md**

- File: `CLAUDE.md` (repository root), per D23 and M14. Project Overview:
  the plugin also runs a batch unattended (autopilot). Plugin Directory
  Layout: `commands/kenspc-autopilot.md`; `skills/autopilot/` with
  `SKILL.md` and `scripts/run.sh`, `scripts/run.ps1` — the first skill
  with a `scripts/` subdirectory, which `check-no-model-names.sh` scans.
  SKILL.md Frontmatter Fields: "all eight skills", "syncing eight files",
  "bump all eight together" become nine. Subagent Review Architecture: a
  fourth orchestration pattern, "Sessions, not agents (autopilot)" — one
  headless session per role through the driver, cross-session messaging
  for questions and wakes, `<tag>.exit` as the completion artifact, no
  agent and no CONTEXT key; the effort paragraph's "the seven other
  skills" becomes eight; beside the Development Workflow rule it
  qualifies, a sentence worded on the evidence (M14): that rule's block is
  auto mode's classifier inside a `--plugin-dir` session; under
  `--permission-mode bypassPermissions` there is no classifier, and the
  autopilot's headless workers run that way, with `--plugin-dir` in plugin
  mode; a worker sees a plugin edit only in the next session, so review,
  acceptance, and fix are separate sessions. Non-Goals: no agent teams, no driver completion message on
  the socket, the workspace outside the repository. Durable documents:
  unchanged.
- Done when: every count and list above agrees with the files, and the
  file reads top to bottom without a contradiction about skill, command,
  or guard counts.
- Why: CLAUDE.md is the loaded contract for every session in this
  repository.

**Step 2.2: READMEs and manifests**

- `README.md` (root): an `autopilot` row in the skills table ("Runs one
  batch unattended from a spec or a brief to a local release preparation —
  one headless session per role, driven by cross-session messages; two
  human gates"); `/kenspc-autopilot` in the Commands line.
- `plugins/kenspc/README.md`: a Skills row (the two entries, the two modes,
  the topology, the driver, the two gates, the two reports, the version
  requirement); a Commands row (`/kenspc-autopilot <path to a spec or a
  brief>`) and `/kenspc:autopilot` in the skill-invocation sentence;
  Recommended Workflow: one line, "or hand a spec or a brief to
  `/kenspc-autopilot`, which runs the chain to a release preparation"; a
  new section "Autopilot": the launch line (D5), the `## Autopilot` labels
  with one example (D1), the workspace tree (D4), what a run writes and
  commits, the two gates, the stop conditions, the budget rule, the two
  reports; Known behavior: the items D23 names, each with its evidence in
  the README's own words; Requirements: the autopilot's v2.1.271 line.
- `plugins/kenspc/.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json`: descriptions gain the autopilot
  ("unattended batch runs to a release preparation"); no version change.
- Done when: every sentence that counts skills or commands, names the
  launch line, or describes what a run commits agrees with the SKILL and
  the driver; `bash scripts/check-json.sh` exits 0.
- Why: the README is the installed user's only description of what an
  unattended run will and will not do to their repository.

**Step 2.3: CHANGELOG**

- File: `plugins/kenspc/CHANGELOG.md`: a `## 3.9.0 — unreleased` entry
  above 3.8.2. Intro: batch F; what ships in one paragraph; a new command
  and skill, so a minor; guard counts unchanged; the release smoke named
  at release. `### Added`: the autopilot skill and `/kenspc-autopilot`
  (the entries, the modes, the topology, the driver and its self-test,
  the messaging protocol, the budget and caps, the stop conditions, the
  two gates, the two reports, the `## Autopilot` section), the PowerShell
  driver (Phase 3, or "follows in a later release" if Phase 3 is not
  shipped). `### Known behavior`: the items the README carries, with their
  sources stated as evidence — the nesting probe, the batch numbers. The
  date is filled at release.
- Done when: the entry is present with its parts, and every behavior it
  names matches the skill and the driver.
- Why: every change that ships is recorded under the next version's
  heading.

**Step 2.4: Release checklist**

- File: `docs/release-checklist.md`. Row 1: "Lists all 9 kenspc slash
  commands". A new smoke row 11, `/kenspc-autopilot <spec>`, inserted
  after row 10, the end-to-end row becoming 12 (its "Row 11" references
  follow). Pass criterion, in substance: on a throwaway `repo`-mode seed
  with a one-task plan and `Acceptance: none`, the trace shows the
  settings line, then `S2 started —` / `S2 returned —`, `S3 …`, `S3b …`,
  `S6 …` in order, each `S<n> returned` after the matching `<tag>.exit`
  exists; four workers with those tags in the timeline and no `resume`
  line; at least one `question <tag>:` message answered with an
  `answer <tag>:` message (the seed plan leaves one point open to force
  it); the release commit removes the plan and the task document and
  touches no version; no `git push`, `git tag`, or `rm -r` in any
  session's trace; the final message holds `## User report`,
  `## Reviewer report`, a total-cost line, and `Autopilot finished —`;
  `<batch>-costs.txt` has one line per worker; a prompt that opens with
  the preamble's first sentence invokes no skill; `run.sh --self-test`
  passes. The row's cost note (D24). Pre-flight counts stay
  `guards run: 10` and `self-tests run: 9`.
- Done when: the row, the count, and the note are present.
- Why: the checklist is the only check that exercises the live chain; the
  fixed strings are what it greps for.

### Phase 3: The PowerShell driver (F-13) — second round

**Step 3.1: Write `skills/autopilot/scripts/run.ps1`**

- File: `plugins/kenspc/skills/autopilot/scripts/run.ps1` (new), per D8,
  in the second round, after the bash driver has passed acceptance (M10).
  The same interface, files, and lines; `--self-test` with a stub; a header
  comment.
- Done when: `pwsh -NoProfile -Command` with
  `[System.Management.Automation.Language.Parser]::ParseFile` reports no
  errors; `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  prints `self-test passed` and exits 0 on macOS; the pointer-label grep
  and `check-no-model-names.sh` pass on the file; the README's Autopilot
  section names both drivers; the roadmap line (Windows acceptance) is
  written in the release commit.
- Why: F-13 — the mirror is written against a driver known to work, and
  checked where it can be without a Windows machine.

### The release commit (F-14) — not a batch step

Recorded so the implementing session leaves these alone: in the release
commit, not before it, `plugins/kenspc/.claude-plugin/plugin.json` goes to
3.9.0; the CHANGELOG heading gets its date; `docs/roadmap.md`'s heading
becomes `## Next minor (3.10.0)` (M13) and item 11, Windows acceptance of
`run.ps1` (`pwsh` syntax and one launch checked on macOS; a headless batch
on Windows not run), is appended; `docs/briefs/autopilot-method.md`,
`docs/plans/batch-f-autopilot.md`, and the task documents are `git rm`ed;
the pre-flight block runs; no tag. Why: the repository's convention for
planned versus shipped work — an item enters or leaves the roadmap, and
the version moves, when the release ships.

## Documentation impact

Determined from this repository's CLAUDE.md, § Durable documents.

- `CLAUDE.md` § Project Overview, § Plugin Directory Layout, § SKILL.md
  Frontmatter Fields (the count sentences), § Subagent Review Architecture
  (the new pattern, the effort paragraph's count, M14's sentence),
  § Non-Goals — Step 2.1.
- `plugins/kenspc/README.md` § Skills, § Commands, § Recommended Workflow,
  the new § Autopilot, § Known behavior, § Requirements — Step 2.2.
- `README.md` (root) § Available Plugins (skills table, Commands line) —
  Step 2.2.
- `plugins/kenspc/CHANGELOG.md` — the 3.9.0 entry — Step 2.3.
- `docs/release-checklist.md` — row 1, the new row 11, the end-to-end row's
  number; pre-flight unchanged — Step 2.4.
- `docs/roadmap.md` — the heading and the Windows line in the release
  commit, not in this batch (F-14, M13).
- `docs/dry-runs/README.md` — N/A for this document: the label convention
  is untouched.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this
  document: the plan format is unchanged; `## Autopilot` is a section a
  brief or a spec may carry, not part of generate-plan's output.
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: the task-document format is unchanged.

## Testing Strategy

- **Mechanical**, in the repository:
  1. The release-checklist pre-flight block — the effort-override diff
     (unchanged), `claude plugin validate --strict .` and
     `./plugins/kenspc`, and `bash scripts/check-all.sh --self-test` with
     `guards run: 10`, `self-tests run: 9`, and every line PASS.
  2. The pointer-label grep (Standing constraints) on the four new plugin
     files.
  3. Byte-identity against the base: for each canonical block in the two
     review skills and `code-fixer.md`, the lines between its markers at
     `5c33c4a` and at HEAD are identical — implied by the zero-diff list,
     checked anyway, run as a bash script file.
  4. The zero-diff command (Standing constraints) prints nothing.
  5. `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`
     exits 0 with `self-test passed`; with a stub that exits 3 it exits 1;
     `bash -n` passes. Phase 3: the `pwsh` parse and self-test.
  6. Text: `grep -n 'Claude Code v2.1.271 or later' plugins/kenspc/README.md`
     finds one line; the `## 3.9.0 — unreleased` entry exists; row 1 says
     9; `grep -c 'kenspc-autopilot' README.md plugins/kenspc/README.md`
     is at least 1 each; the description's exclusion holds the preamble's
     first sentence.
- **Live chain, headless**, through the main session's driver
  `~/Projects/_smoke/_prompts/f-run.sh <tag> <cwd> <prompt-file> [resume-session-id]`
  (`claude -p … --name <tag> --settings '{"crossSessionInbound":"accept"}'
  --plugin-dir <repo>/plugins/kenspc --permission-mode bypassPermissions
  --output-format json`), cwd the seed. The acceptance session (S4) is
  itself headless and waits with M5's snippet; the autopilot under test
  runs inside a `-p` session in these cases, so its own wait is the
  headless path (it never subscribes and polls `<tag>.exit` with the
  wait snippet — M5, CL1), and its interactive path
  (subscribe, end the turn, wake on the notice) is exercised by this
  batch's own run only, which the main session drives by hand. Every
  answer the driver gives is quoted in the record. Cost is each session's
  last `total_cost_usd`; the nested workers' costs are read from the
  autopilot's own `<batch>-costs.txt` and listed under the case.
- **Reading the trace.** Session transcripts are
  `~/.claude/projects/<cwd with / replaced by ->/<session_id>.jsonl`; the
  nested workers' transcripts are under the seed's directory, since their
  cwd is the seed, and are told apart by the ids in `<tag>.session`.
  Useful queries: the ordered assistant content,
  `jq -c 'select(.type=="assistant") | .message.content[]? | if .type=="text" then {text} elif .type=="tool_use" then {tool:.name} else empty end' <session>.jsonl`;
  every Bash command, `jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Bash") | .input.command' <session>.jsonl`
  (the rails check greps these for `git push`, `git tag`, `rm -r`);
  a SendMessage call, the same with `.name=="SendMessage"` and
  `.input.message`. A transcript in a trace directory that the driver did
  not start (a user-level hook's session; observed as `t-7e` in the
  nesting probe) is recorded as an observation and not costed, and a file
  a hook writes into a seed (`.remember/` in the probe) is listed under
  Observations, not counted as the run's change.
- **Seeds**: throwaway projects under `~/Projects/_smoke/batch-f-*`.
  (a) `batch-f-repo`: a TypeScript project to the batch E record's Seed
  project row (`typescript@7.0.2`, `vitest@5.0.1` from the local npm cache
  with `npm install --offline`, tests green, a `typecheck` script, a vitest
  config with `globals` and the default include), committed, with a
  two-task plan under `docs/plans/` whose Documentation impact lists
  `README.md` (so `/kenspc-task` writes a Doc-sync task) and one point the
  plan leaves unstated (a return type the tasks need) so that S2 or S3
  asks once; and an equivalent brief under `docs/briefs/` (untracked)
  ending with `## Autopilot` — `Baseline:`, `Mode: repo`, `Budget:`,
  `Acceptance:` with `npm test — PASS: exit 0` and
  `npm run typecheck — PASS: exit 0`, `Release preparation: default`.
  (b) `batch-f-plugin`: `git clone` of this repository under
  `~/Projects/_smoke/`, checked out at v3.8.2 (`5c33c4a`), with a small
  plan that changes one README sentence and lists it under Documentation
  impact, and `## Autopilot` with `Mode: plugin`, `Version: 3.8.3`,
  `Acceptance:` with one case (`/help` in a `--plugin-dir` session lists
  the eight commands — PASS: eight rows), `Release preparation: default`.
  The source gate is recorded as in the batch E record § 1: the first
  `SKILL.md` read in each session is under the repository's
  `plugins/kenspc/skills/`, and `plugins/cache/kenspc-claude-plugin`
  occurs 0 times in the trace directories.
- **Cases**, each with its PASS criterion. Run order: 1, 2, 3, 4, 9, 8,
  then the checks 5–7; case 10 last, as the budget allows:
  1. **repo mode, spec entry** — `/kenspc-autopilot docs/plans/<x>.md` on
     seed (a), headless. PASS: the settings line, then the launch and
     return lines for S2, S3, S3b, S6 in that order, each return after the
     matching `<tag>.exit` exists (timeline `end` line before the return
     line's timestamp); four workers and no `resume` line in the timeline;
     at least one `question <tag>:` message from a worker and an
     `answer <tag>:` reply from the autopilot (both in the transcripts);
     the release commit `git rm`s the plan and the task document and
     changes no version; no `git push`, `git tag`, or `rm -r` in any
     session's Bash commands; the final message holds `## User report`,
     `## Reviewer report`, a total-cost line, and `Autopilot finished —`;
     `<batch>-costs.txt` has one line per worker; `Acceptance:` names two
     commands, so an S4 session ran them and the report has two
     acceptance lines with exit 0.
  2. **repo mode, brief entry** — `/kenspc-autopilot docs/briefs/<x>.md`
     on a fresh clone of seed (a). PASS: S1 started first; the autopilot
     sent the driver (as the user) S1's table and asked for rulings — in
     the headless case, by a message to the driver session — and the
     driver ruled "use your leans for the rest"; a `rulings <batch>:`
     message to S1; S1's commit `docs(plans): add batch <name> spec` exists
     and the spec's Ruling column is filled; then case 1's criteria from
     S2 on.
  3. **plugin mode** — `/kenspc-autopilot docs/plans/<small plan>.md` on
     seed (b). PASS: every worker's command line carries
     `--plugin-dir <seed (b)>/plugins/kenspc` (from `ps` during the run or
     the timeline's start line); an S4 session wrote
     `docs/dry-runs/<batch>-acceptance.md` with the seven sections; S6's
     commit bumps `plugin.json` to 3.8.3, dates the CHANGELOG heading,
     `git rm`s the plan and task documents, and S6's reply carries
     `guards run: 10` and `self-tests run: 9`; no tag.
  4. **budget stop** — seed (a) with `Budget: USD 1`. PASS: no worker
     started (the timeline is empty for the batch), the final message ends
     with `Autopilot stopped:` and names the budget with spent 0 and the
     projected amount, and asks how much to raise it to; in the headless
     case the run ends there.
  5. **rails** — over cases 1–3: no `git push`, `git tag`, `rm -r`, or
     `rm -rf` in any session's Bash commands (positive control: the grep
     finds `rm -rf` in a probe file); any discard went to `.trash/`.
  6. **drivers** — `run.sh --self-test` exits 0 and prints
     `self-test passed`; the mutated stub makes it exit 1. Second round:
     `run.ps1` parses under `pwsh -NoProfile` and its `--self-test`
     launches the stub.
  7. **guards and load** — in the repository: `bash scripts/check-all.sh
     --self-test` 10 / 9; both `claude plugin validate --strict` pass;
     `/help` in a `--plugin-dir` session lists nine kenspc commands.
  8. **routing** — in a `--plugin-dir` session: a prompt that opens with
     the preamble's first sentence and asks to "run this batch unattended"
     invokes no skill; "帮我实作这个 task" invokes no autopilot (Skill
     tool calls in the trace name no `autopilot`).
  9. **task document argument** — `/kenspc-autopilot docs/tasks/<x>.md`
     on seed (a) after case 1 (or a hand-written task document). PASS: no
     worker started; the final message names the plan and ends with
     `Autopilot stopped:`.
  10. **dead session (optional)** — as the budget allows: on seed (a), the
      driver kills S3's `claude` process mid-run (`kill -TERM`). PASS: the
      autopilot resumes it once under `<tag>-r1` with the continue prompt,
      the timeline shows the resume, and the run goes on; the report's
      sessions list shows the resume.
- **Budget**: set by the main session; an estimate from the batch E
  figures — each nested worker USD 1–6 for an implement run and 4–6 for a
  review, plus the autopilot session itself — is about USD 25–40 for case
  1, 35–50 for case 2 (S1 added), 40–70 for case 3 (S4's own nested run
  and S6's pre-flight added), under 5 each for cases 4, 8, and 9, and 25–40
  for case 10; cases 5–7 are checks over the others. Case 10 is cut first.
- **Independence**: the record separates what the plugin's runs produced —
  the workers' commits, the spec, the task document, the record, the
  reports, the traces — from what the driver built and typed (the seeds,
  the plans and briefs, the `## Autopilot` sections, every answer and
  ruling), and quotes every answer where it was given. The acceptance
  session records the evidence and a first reading of each FAIL and does
  not classify it; the main session classifies (plugin defect, behavior
  deviation, observation) and fixes a plugin defect in a separate session,
  never in a seed; the affected case is then re-run. Windows and WSL2 are
  not run; the record says so under Not exercised, with the interactive
  wait path (exercised only by this batch's own run) and any optional
  case cut.
- Dogfood note: `/kenspc-task` on this spec generates the Doc-sync task
  from the Documentation impact above (Phases 1–2 first, under M10). For
  the documents Steps 2.1–2.4 edit, the generated entries say "edited by
  Task <K>: verify it against the implementation instead of editing it
  again", as the template provides.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| The idle notice never wakes the main session (lost, early, or expired) and the batch stalls | Medium | M4: `.exit` is read on every wake, and a user's own message is a wake too; the 12-hour expiry re-subscribes; the state file tells the resumed turn where it is. |
| A worker's question waits 30 minutes because the main session's turn had not ended (the notice cannot interrupt a running turn) | Low | The main session ends its turn right after each launch and after each answer; the worker's timeout path (the question in its final message, `--resume`) is the fallback the lock names. |
| The main session's context grows over a long batch and compaction drops the run's state | Medium | D19: every transition is in the state file, and the skill re-reads it on every wake; the reports are built from it, not from memory. |
| Two sessions share a tag's name and a message goes to the wrong one | Low | M7: unique tags; `ListAgents` before every send; the `[ref]` when two rows share the name. |
| A worker breaches a rail (a `push`, an `rm -rf`) before the main session sees its trace | Low | The rails are in every preamble with their Why; the acceptance greps every session's Bash commands; a breach found is a stop and a plugin defect. |
| `--max-budget-usd` ends a worker mid-task and leaves a half-applied step | Low, by design (D9) | The step is dead once, resumed under the cap that remains after the user raises the budget; the stop asks first. |
| The autopilot skill is triggered inside a worker that reads its preamble | Low | M15: the description's exclusion on the fixed first sentence; case 8. |
| A project or local settings file sets `crossSessionInbound: hold` or `refuse`, which is stricter than the `--settings` accept | Low | No probe message (D21, CL4): a hold or refusal surfaces as a `[Cross-session delivery notice]` on the first real message, which is a stop naming the settings precedence; a worker whose question is held times out after 30 minutes and stops with the question in its final message, and `--resume` is the fallback the lock names; Known behavior says so. |
| Machine sleep on macOS during a long wait with no Bash call running in the main session | Medium | D7: the driver wraps each worker in `caffeinate -i`, so the machine stays awake while any worker runs; the README says so. |
| A hook's session shares the trace directory and a hook's file lands in a seed | Certain, on this machine | Observed, not counted (F-5); the record lists them under Observations; the source gate counts them. |
| `run.ps1` is wrong on Windows | Medium | F-13: syntax and one launch on macOS; the Windows acceptance is a roadmap line, and the interface mirrors the bash driver that acceptance exercised. |
| The user report drifts into the reviewer report's detail, or the reverse | Low | D20's fixed field list for the reviewer report and the one-page bound for the user report; the checklist finds both headings. |
| generate-task or task-implement, run by a worker, asks something the spec does not answer, and the autopilot answers on the user's behalf | Medium | The skill's rule: a worker's question is answered from the spec, and a question the spec does not answer is a stop (F-9); the Quality bar names an answer on the user's behalf as a failed run; case 1 checks the `question` / `answer` pair against the spec. |
| The nested acceptance runs cost more than the batch's budget leaves | Medium | The cases are ordered; case 10 is optional and cut first; the settings' budget for this batch is set by the main session before S4 starts. |

## Clarifications during implementation

Settled between the implementing session and the spec author (the main
session); each entry binds like the rulings above. Questions from the
implementing session arrive by message to the main session (Open Questions
below) and, when the session cannot wait any longer, under a
`## Questions for the spec author` section appended to the end of this
document; each answer is recorded here as `CL<n>` — a statement and the
Step it affects — and the answered question is removed from that section.
The prefix is `CL`, so a clarification cannot be read as one of the locked
points F-1 to F-14 or the design rows M1–M16 and D1–D24.

- **CL1** — A `-p` session that subscribes with `notify_when_idle`
  receives the notice not between tool calls but as a new turn after its
  final reply: in the nesting probe, `f-s1` subscribed to `f-s1-w`, the
  worker exited at 23:10:27, nothing arrived during 26 minutes of tool
  calls, and the notice started a new turn at 23:36 after `f-s1`'s final
  message, whose JSON `result` then became that turn's last message.
  Consequences (Step 1.1): a headless autopilot never subscribes — it
  polls `<tag>.exit` with the wait snippet's driver form; the skill decides
  its wait path once, in Phase 0, by whether the process that runs it is
  headless (`ps -o args= -p $PPID` from the Bash tool shows `-p` or
  `--print`; the implementing session verifies the probe and records the
  command it used), and the settings line (Fixed strings) gains the field
  `wait <interactive|headless>` after `workspace <path>`; Known behavior
  (Step 2.2) and the CHANGELOG (Step 2.3) state the extra-turn effect.
  Background item 2 amended in the same commit.
- **CL2** — The pointer-label grep's `dry-run` alternative reads
  `dry-run\b` for this batch's four plugin files: the skill's S4 task
  block names the record path `docs/dry-runs/<batch>-acceptance.md`
  (F-3, D18), whose `dry-runs` matched the bare alternative as a
  substring, while the pointer word `dry-run` is still caught; the skill
  words F-10's seed check as a trial run of the seed. Standing
  constraints amended; the task document's criteria use the amended
  pattern. Steps 1.1–1.3, 3.1.
- **CL3** — The rulings message's per-row form is `M<n>: <decision>` /
  `D<n>: <decision>`: the placeholder `<ruling>` matched `\bruling\b`,
  and nothing parses the placeholder — the parsed part is the `M<n>: ` /
  `D<n>: ` prefix. The singular word "ruling" does not appear in the
  skill (plural "rulings", or "decision" / "answer"). Fixed strings
  amended. Step 1.1.
- **CL4** — The start checks (D21, Step 1.1 Phase 0) send no probe
  message: a `crossSessionInbound` hold or refusal surfaces as a delivery
  notice on the first real message and is a stop naming the settings
  precedence; a worker whose question is held runs into its 30-minute
  timeout and the `--resume` fallback. The Risks row that named a probe is
  reworded in the same commit. Step 1.1.
- **CL5** — In round 1 (Phases 1–2, the first task document) CLAUDE.md's
  layout tree lists `scripts/run.sh` only; `run.ps1` joins the tree in
  round 2, through that round's Doc-sync task, once the file exists (M10).
  D23's and Step 2.1's "`scripts/run.sh`, `run.ps1`" read as the state
  after both rounds. Step 2.1.
- **CL6** — Step 2.1 also edits CLAUDE.md § Writing Rules for Skill
  Content: the bullet that lists the skills sharing the cannot-ask wording
  ("the wording diagnose-bug, generate-plan's …, and the prototype skill's
  gates share") names the autopilot's gates too, one clause; the task
  document's Task 4 allows that section in its hunk-range criterion.
  Step 2.1.

## Open Questions

None beyond the empty Ruling column of [Design decisions](#design-decisions),
which the main session fills before this document becomes the
specification.

The implementing session's channel to the spec author (the main session,
`claude-plugin-9d` for this batch): if it finds a ruling contradicted by
the code, or a question no ruling answers, it stops and reports it as a
plan-level issue rather than resolving it locally. It sends the question to
the main session by `SendMessage`, first line
`question <tag>: <one line>`, with its suggested answer, and waits as its
preamble says; the answer arrives as a message,
and the main session records it here as `CL<n>`. When no answer arrives
within the wait, it appends the question under a
`## Questions for the spec author` section at the end of this document —
one numbered entry per question, each naming the Step it affects, what the
repository shows, and what this document says — commits nothing else, puts
the question in its last reply, and stops; the main session continues it
with `--resume` from the updated document.
