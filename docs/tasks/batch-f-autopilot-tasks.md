# Batch F — The Autopilot Skill, /kenspc-autopilot — Task Document

## Context

An `autopilot` skill and its `/kenspc-autopilot <path>` command run one batch
of this plugin's own chain unattended, from a spec or a brief to a local
release preparation, between two human gates: the rulings on a brief's
design table, and the tag / push / release after the reports. The skill runs
in an interactive main session and drives one headless `claude -p` session
per role — S1 design (brief entry only), S2 `/kenspc-task`, S3
`/kenspc-task-implement`, S3b standalone `/kenspc-task-review`, S4
acceptance, S5 fix on demand, S6 release preparation — through a driver
script that ships with the skill (`skills/autopilot/scripts/run.sh`) and
cross-session messaging: a worker asks the main session by message and
waits; the main session subscribes to each worker's idle notice and ends its
turn, and reads `<tag>.exit` on every wake. Two modes: `repo` (the default —
the workers use the installed plugin, acceptance is the commands the brief
names or nothing, and release preparation is one commit that removes the
batch's plan and task documents) and `plugin` (declared, or detected from a
marketplace layout — the workers load the worktree's plugin with
`--plugin-dir`, S4 runs a seed-project acceptance and files
`docs/dry-runs/<batch>-acceptance.md`, and S6 makes the repository's release
preparation). Two reports end the run: a one-page user report in the
conversation's language and a reviewer report of fixed shape with a
total-cost line. The release is 3.9.0; this batch makes no version bump and
no tag.

Related plan: `docs/plans/batch-f-autopilot.md` (read at `b868598`). The
plan is the complete specification. Its locked design (F-1 to F-14, restated
from `docs/briefs/autopilot-method.md` § Locked design) and its Design
decisions (M1–M16, D1–D24) are binding rulings. Every ruling takes the
draft's lean, with six amendments: M5 gives the wait snippet two forms (the
driver's polls `<tag>.exit`, the worker's counts only); M10 places the
two-round split at generate-task's confirm gate; M12 makes the main
session's cost an estimate with a stated basis; M14 words the CLAUDE.md
sentence on the evidence (auto mode's classifier, absent under bypass
permissions); D9 resumes a cap-ended worker once the budget is raised; D23
corrects the command count (eight existing commands become nine). Five
rulings read a locked point beyond its literal words — M10 (F-13's ordering
against F-4's fixed topology, for this batch's own run only), M12 (F-5's
"estimated" as a number with a stated basis), M13 (F-14's "only the Windows
line" and the roadmap heading), D4 (the workspace as a field with the lock's
path as its default), D9 (a per-worker `--max-budget-usd` backstop under
F-9's budget) — and every task follows the ruling. Three clarifications
settled during implementation bind the same way (plan § Clarifications
during implementation):

- CL1: a `-p` session that subscribes with `notify_when_idle` receives the
  notice as a new turn after its final reply, not between tool calls. A
  headless autopilot never subscribes — it polls `<tag>.exit` with the wait
  snippet's driver form; the skill decides its wait path once, in Phase 0,
  by whether the process that runs it is headless; the settings line ends
  with `wait <interactive|headless>`; the README's Known behavior and the
  CHANGELOG state the extra-turn effect (Tasks 2, 5, 8).
- CL2: the pointer-label grep's `dry-run` alternative reads `dry-run\b` for
  this batch's plugin files, so `docs/dry-runs/<batch>-acceptance.md` passes
  and the pointer word `dry-run` is still caught; the skill words the seed
  check as a trial run of the seed (every task's criteria; Task 2).
- CL3: the rulings message's per-row form is `M<n>: <decision>` /
  `D<n>: <decision>`; the parsed part is the `M<n>: ` / `D<n>: ` prefix;
  the singular word "ruling" does not appear in the skill — plural
  "rulings", or "decision" / "answer" (Task 2).

Under M10 this document covers plan Phases 1 and 2 only — the skill, the
bash driver, the command, and the documentation. Plan Phase 3 (Step 3.1,
`run.ps1`) was left out at the confirm gate by the plan's own rule and goes
to a second task document after the bash driver has passed acceptance.
Nothing here depends on it; the documents that will one day name both
drivers (the plugin README's Autopilot section, CLAUDE.md's layout tree, the
CHANGELOG's driver line) say in this round that the PowerShell mirror
follows, and the second document's Doc-sync task brings them up to date.

The labels this document cites (F-n, M-n, D-n rows, CL-n, "ruling") are
pointers into the plan for the implementer. None of them is copied into a
plugin file (plan § Standing constraints; the pointer-label grep below).

Each task below cites its plan Step, which is the canonical source for what
to write; where the plan gives a paragraph "in substance", that paragraph is
the text to adapt. The criteria listed here are the local DONE bar.

Fixed forms. Every task that states one of these uses it exactly as written
here (plan § Fixed strings, with CL1 and CL3). Each is written on one line of
the file that carries it, unwrapped, so `grep -F` finds it:

- `## Autopilot` section: `- <Label>: <value>` bullets under the heading;
  the sixteen labels `Baseline:`, `Mode:`, `Plugin:`, `Version:`,
  `Budget:`, `Caps:`, `Allowed files:`, `Zero diff:`,
  `Byte-identity exceptions:`, `Acceptance:`, `Acceptance record:`,
  `Release preparation:`, `Must read:`, `Challenge seeds:`,
  `Prior specs:`, `Workspace:`; the values `repo` / `plugin`, `none`,
  `USD <n>`, `<n> sessions, <m> resumes`, `default` / `keep`, ` — PASS: `,
  `(optional)`.
- Settings line:
  `Autopilot settings — batch <batch>, mode <repo|plugin>, baseline <sha>, budget USD <n>, caps <n> sessions / <m> resumes, version <v|none>, acceptance <k> cases|none, release preparation <default|keep|custom>, workspace <path>, wait <interactive|headless>`
  — in English whatever the conversation language.
- Preamble first sentence:
  `You are a headless sub-session of the batch <batch> main session <main name>, unattended.`
- Launch line: `S<n> started — <tag> pid <pid> session <session-id> — <prompt path>`
- Return line: `S<n> returned — exit <code>, cost USD <c>, <success|subtype> — <json path>`
- Question: first line `question <tag>: <one line>`; the worker's
  final-message section `## Question for the main session`.
- Answer: first line `answer <tag>: <one line>`.
- Rulings: first line `rulings <batch>: <n> rulings`; per row
  `M<n>: <decision>` / `D<n>: <decision>`;
  `lean adopted (the session could not ask)`.
- Continue prompt:
  `Continue the task in your prompt from where you stopped; your last message was cut short.`
- Stop line: `Autopilot stopped: <reason>` — the last line of the final
  message on any stop.
- Finish line: `Autopilot finished — <baseline sha>..<last sha>`
- Report headings: `## User report`, `## Reviewer report`.
- Acceptance line without S4: `none named; S3b is the last check`
- Driver files: `<tag>.json`, `<tag>.err`, `<tag>.pid`, `<tag>.exit`,
  `<tag>.session`; `<batch>-timeline.log` lines `start <tag> pid <pid> …` /
  `end   <tag> exit <status>` (three spaces after `end`);
  `<batch>-costs.txt` lines `<tag> <session_id> <total_cost_usd>`.
- Driver self-test: `run.sh --self-test`, exit 0 and the line
  `self-test passed`.
- Wait snippet, driver form:
  `n=0; until [ -f "$LOGS/$TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done`
- Wait snippet, worker form:
  `n=0; until [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done`
- Commit subjects: `docs(plans): add batch <name> spec` (S1);
  `docs: remove batch <name> plan and tasks` (repo S6 default);
  `docs(plans): record clarifications settled after <step>` (the main
  session).
- Driver interface line: `run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]`
- Main-session launch line:
  `claude --name <batch>-main --permission-mode bypassPermissions --settings '{"crossSessionInbound":"accept"}'`
- Worker settings flag: `--settings '{"crossSessionInbound":"accept"}'`
- Command: `/kenspc-autopilot <path to a spec or a brief>`
- Version requirement: `Claude Code v2.1.271 or later`
- CHANGELOG heading: `## 3.9.0 — unreleased`
- Cannot-ask wording: "In a session that cannot ask (a system reminder to
  work without stopping), …".
- Dependency line: `Depends on: Task N`, a range `Task 1-<N>` (ASCII
  hyphen), or a comma-separated list.
- Unchanged: `guards run: 10`, `self-tests run: 9`; every existing fixed
  string of the eight skills.

Joined text. Several sentences are wrapped across lines, so a line-by-line
grep misses them. Where a criterion says "in the joined text", read the
file with its line breaks joined and its spaces squeezed and count
occurrences, not lines:

```bash
tr '\n' ' ' < <file> | tr -s ' ' | grep -oF '<string>' | wc -l
```

Pointer-label grep (plan § Standing constraints, with CL2). For every plugin
file a task creates — `plugins/kenspc/skills/autopilot/SKILL.md`,
`plugins/kenspc/skills/autopilot/scripts/run.sh`, and
`plugins/kenspc/commands/kenspc-autopilot.md` — this command prints nothing:

```bash
grep -nE 'batch [A-Z]\b|dry-run\b|\bruling\b|\b[BCDEF]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>
```

It prints nothing on the eight existing skills at `5c33c4a` and many lines
on this batch's plan, so it can fail; `dry-runs` (the record directory)
passes it and `dry-run` does not. `grep -nwE 'MUST|NEVER|CRITICAL' <file>`
also prints nothing on each of them (nothing on the eight existing skills at
`5c33c4a`). Two words the skill needs pass the pattern by construction: the
word "batch" alone, and the plural "rulings" (the report fields are named
`design rulings and clarifications`).

Canonical check against the base (plan § Testing Strategy, mechanical 3).
The guards compare the copies of a canonical block with each other, so an
edit made to both copies at once passes them; this compares each block with
its own text at `5c33c4a`. No task edits a file that holds one, so the
check is a control over the zero-diff command, run anyway. Write it with the
Write tool to `$TMPDIR/batch-f-canonical-base.sh` (resolve `$TMPDIR` first;
the file is left there) and run it as
`bash "$TMPDIR/batch-f-canonical-base.sh"`, never inline under zsh. It exits
0 and prints `control: mutated block detected`, twelve `SAME` lines, and
`blocks compared: 12, result: PASS`; its control proves that a one-character
change inside a block is detected, and a block of fewer than three lines at
the base is reported `EMPTY`, so a mistyped marker cannot pass as identical.
It passes at `5c33c4a`.

```bash
#!/bin/bash
# Compare every canonical and example block with its copy at the base commit.
# Usage: bash batch-f-canonical-base.sh   (from anywhere inside the repository)
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
base=5c33c4a
tmp=$(mktemp -d "${TMPDIR:-/tmp}/canonical-base.XXXXXX") || exit 2

extract() { # <file> <marker name>
  awk -v s="<!-- $2:start -->" -v e="<!-- $2:end -->" \
    '$0==s{p=1} p{print} $0==e{p=0}' "$1"
}

# Positive control: a one-character change inside a block must be detected.
git show "$base:plugins/kenspc/skills/task-review/SKILL.md" > "$tmp/control-base"
sed 's/Code Review Phase (unconditional)/Code Review Phase (unconditionaL)/' \
  "$tmp/control-base" > "$tmp/control-mut"
extract "$tmp/control-base" canonical:dispatch > "$tmp/cb"
extract "$tmp/control-mut" canonical:dispatch > "$tmp/cm"
if cmp -s "$tmp/cb" "$tmp/cm"; then
  echo "CONTROL FAILED: a mutated block compared equal"
  exit 2
fi
echo "control: mutated block detected"

fail=0
for pair in \
  "plugins/kenspc/skills/task-review/SKILL.md canonical:run-dir" \
  "plugins/kenspc/skills/task-review/SKILL.md canonical:dispatch" \
  "plugins/kenspc/skills/task-review/SKILL.md canonical:stats-line" \
  "plugins/kenspc/skills/task-review/SKILL.md canonical:verdict-shared" \
  "plugins/kenspc/skills/task-implement/SKILL.md canonical:run-dir" \
  "plugins/kenspc/skills/task-implement/SKILL.md canonical:dispatch" \
  "plugins/kenspc/skills/task-implement/SKILL.md canonical:stats-line" \
  "plugins/kenspc/skills/task-implement/SKILL.md canonical:verdict-shared" \
  "plugins/kenspc/agents/code-fixer.md canonical:principle:simplicity-first" \
  "plugins/kenspc/agents/code-fixer.md canonical:principle:surgical-changes" \
  "plugins/kenspc/agents/code-fixer.md canonical:stats-line" \
  "plugins/kenspc/agents/code-fixer.md example:schema-b"; do
  set -- $pair
  f=$1; m=$2
  git show "$base:$f" > "$tmp/base-file"
  extract "$tmp/base-file" "$m" > "$tmp/b"
  extract "$f" "$m" > "$tmp/h"
  n=$(wc -l < "$tmp/b" | tr -d ' ')
  if [ "$n" -lt 3 ]; then
    echo "EMPTY  $f $m (base block has $n lines)"; fail=1; continue
  fi
  if cmp -s "$tmp/b" "$tmp/h"; then
    echo "SAME   $f $m ($n lines)"
  else
    echo "DIFF   $f $m"; diff "$tmp/b" "$tmp/h" | head -20; fail=1
  fi
done
echo "blocks compared: 12, result: $([ $fail -eq 0 ] && echo PASS || echo FAIL)"
exit $fail
```

Hunk ranges. Where a criterion bounds a task's edits by sections, read the
old start line `a` of every `@@ -a,b +c,d @@` header in
`git diff -U0 5c33c4a -- <file>` and the headings' line numbers in
`git show 5c33c4a:<file>`; a hunk belongs to the section whose heading is
the last one at or before `a`.

This is plugin revision work. The files are Markdown (a new SKILL.md, a new
command, the plugin README, the root README, CLAUDE.md, the CHANGELOG, the
release checklist), one bash script, and two JSON manifests. The repository
has no test framework: "build / test / lint" for each task is the guard
suite. After each task, run `bash scripts/check-all.sh`, which must exit 0
with `guards run: 10` — capture its exit status on its own line, never
through a pipe (`bash scripts/check-all.sh > <file> 2>&1; rc=$?`), since a
pipe reports the last command's status, not the guard's. Tasks that create
or edit a file under `plugins/kenspc/` also run
`claude plugin validate --strict ./plugins/kenspc`, and a task that edits a
manifest also `claude plugin validate --strict .`. Tasks 1 and 2 also run
the driver's self-test. Task 8 also runs
`bash scripts/check-all.sh --self-test`, which must print `guards run: 10`
and end with `self-tests run: 9`.

Constraints that apply to every task (plan § Standing constraints):

- No edit inside any byte-identity section, and no edit to any file that
  holds one: the `canonical:run-dir`, `canonical:dispatch`,
  `canonical:stats-line`, and `canonical:verdict-shared` blocks; the
  code-craft canonical paragraphs (`canonical:principle:*`); the five
  reviewers' six shared sections; and the worked example between
  `code-fixer.md`'s `example:schema-b` markers. Every file that holds one
  is on the zero-diff list.
- Zero diff outside the batch's files. After every task, this prints
  nothing:
  `git diff --stat 5c33c4a HEAD -- plugins/kenspc/agents plugins/kenspc/shared plugins/kenspc/references plugins/kenspc/hooks plugins/kenspc/commands/kenspc-brief.md plugins/kenspc/commands/kenspc-prototype.md plugins/kenspc/commands/kenspc-plan.md plugins/kenspc/commands/kenspc-task.md plugins/kenspc/commands/kenspc-diagnose.md plugins/kenspc/commands/kenspc-task-implement.md plugins/kenspc/commands/kenspc-task-review.md plugins/kenspc/commands/kenspc-guide.md plugins/kenspc/skills/generate-brief plugins/kenspc/skills/generate-plan plugins/kenspc/skills/generate-task plugins/kenspc/skills/generate-guide plugins/kenspc/skills/diagnose-bug plugins/kenspc/skills/prototype plugins/kenspc/skills/task-implement plugins/kenspc/skills/task-review scripts docs/roadmap.md docs/dry-runs/README.md`.
  The files this batch touches are the three new plugin files
  (`plugins/kenspc/skills/autopilot/SKILL.md`,
  `plugins/kenspc/skills/autopilot/scripts/run.sh`,
  `plugins/kenspc/commands/kenspc-autopilot.md`), `CLAUDE.md`,
  `plugins/kenspc/README.md`, `README.md`,
  `plugins/kenspc/.claude-plugin/plugin.json` and
  `.claude-plugin/marketplace.json` (description strings only),
  `plugins/kenspc/CHANGELOG.md`, and `docs/release-checklist.md` — not
  `docs/roadmap.md`, not `docs/dry-runs/README.md`, not anything under
  `scripts/`, `agents/`, `shared/`, `references/`, or `hooks/`, and none
  of the eight existing skills or commands.
- No new agent (`plugin.json` keeps "eleven reusable subagents"), no new
  CONTEXT key, no agent teams, no way of starting a worker other than
  `claude -p`, no `--continue`, and no guard script added or edited
  (`scripts/` is zero diff, so `guards run: 10` and `self-tests run: 9`
  stay).
- `effort:` frontmatter is unchanged in every file; the new skill has none
  and follows the session. Every skill keeps `version: 3.0.0`, the new one
  included.
- No version bump: `version` in `plugins/kenspc/.claude-plugin/plugin.json`
  stays `3.8.2`. The CHANGELOG entry goes under `## 3.9.0 — unreleased`
  with no date. `docs/roadmap.md` is not edited: its heading and the Windows
  line are the release commit's (plan § The release commit). No tag, no
  push.
- Rules are rationale-anchored ("Why: …" prose), with no `MUST` / `NEVER` /
  `CRITICAL`, no effort or reasoning tokens, and no model names
  (`bash scripts/check-no-model-names.sh` exits 0; it scans
  `skills/autopilot/scripts/` too, so the driver passes no `--model`, and
  the skill names no model family — not even for the hook's session it
  describes as an observation). A check written into the skill is in rubric
  form: what passing looks like, then the named ways it fails.
- Every question point the skill has carries a cannot-ask branch in the
  Fixed-forms wording; the gate table repeats the outcomes and does not
  replace the sentences.
- Plugin files state their evidence in their own words and carry no pointer
  labels, batch names, or dry-run references (the pointer-label grep); the
  singular word "ruling" is not used in the skill (CL3).
- Code, comments, commit messages, and documents are in English; the
  skill's trigger phrases are in English and Chinese; the fixed lines are in
  English whatever the conversation language.
- No task runs `rm -r` or `rm -rf`. The canonical check's script, the
  driver self-test's directories, and every other temporary file under
  `$TMPDIR` are left there. Anything else to be discarded is moved to
  `~/Projects/_smoke/.trash/<name>-<YYYYMMDD-HHMMSS>/` (created when
  missing). Nothing under `.kenspc/` is deleted. The driver's self-test
  writes only under `$TMPDIR`.
- Plugin Design Lessons apply: every transition rests on an artifact —
  `<tag>.exit`, the state file, the committed spec, the task document, the
  record — never on a notice's or a message's wording; no hook guards
  workflow state.
- No task edits `docs/plans/batch-f-autopilot.md`. A task that finds a
  ruling contradicted by the code is marked BLOCKED with the contradiction
  named. After the run ends and Schema G is out, the orchestrating session
  (the one that ran `/kenspc-task-implement`) sends each such contradiction
  to the main session as its prompt says — a message whose first line is
  `question <tag>: <one line>`, with its suggested answer, then waits as
  the prompt says — and, when no answer arrives within the wait, appends it
  under a `## Questions for the spec author` section at the end of the plan
  (creating the section when missing) — one numbered entry per question,
  naming the Step it affects, what the repository shows, and what the plan
  says — commits nothing else, puts the question in its last reply, and
  stops; the spec author records the answer as `CL<n>` under the plan's
  `## Clarifications during implementation`.
- Each task is one conventional commit that stages only the files the task
  lists, together with the task's status update:
  - `feat(skills): …` for Tasks 1 and 2;
  - `feat(commands): …` for Task 3;
  - `docs(claude-md): …` for Task 4;
  - `docs: …` for Tasks 5, 6, and 9;
  - `docs(release): …` for Task 7;
  - `docs(changelog): …` for Task 8.

Dependency note: Task 1 (the driver) carries no `Depends on`. Task 2 (the
skill) quotes the driver's interface line from the shipped script's header
and names its self-test line, so it follows Task 1 (`Depends on: Task 1`).
Task 3 (the command) names the skill's path (`Depends on: Task 2`). Tasks
4–7 document the skill, the driver, and the command
(`Depends on: Task 1-3`); they edit different files and are ordered only by
the document. Task 8, the CHANGELOG, names every change the batch makes, the
README sections and the checklist row included, so it follows Task 7
(`Depends on: Task 1-7`); the plan lists the CHANGELOG (Step 2.3) before the
checklist (Step 2.4), and the order is reversed here so the entry can
describe the row it names. Task 9, the Doc-sync task, runs last and needs
Tasks 1–8. It reconciles the documents with what those tasks implemented and
promotes their recorded decisions. Plan Phase 3 has no task here (M10): a
second task document covers Step 3.1 after the bash driver passes
acceptance, and its `run.ps1` mirrors the `run.sh` Task 1 writes.

## Tasks

### Task 1: Write the bash driver run.sh

**Status:** TODO

Plan Step 1.2 (F-5, F-7; rulings D7, D9, M5, M6). Create
`plugins/kenspc/skills/autopilot/scripts/run.sh`, executable, for the bash
3.2 that macOS ships: `#!/bin/bash`, `set -u`, no bash 4 feature (no
`declare -A`, `mapfile`, `readarray`, or `${var,,}`), every path quoted, no
`rm -r`, POSIX tools plus `uuidgen` or `python3` for the UUID and
`caffeinate` as an optional branch. A header comment states the interface,
the environment variables, and the files it writes.

- Interface: `run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]`
  and `run.sh --self-test`. Environment: `AUTOPILOT_LOGS` (the logs
  directory; default `$HOME/Projects/_smoke/_logs`, the lock's workspace);
  `AUTOPILOT_PLUGIN_DIR` (when set, `--plugin-dir <value>` is passed —
  plugin mode); `AUTOPILOT_BUDGET_USD` (when set, `--max-budget-usd <value>`);
  `APPEND_SP` (when set, `--append-system-prompt <value>` — the cannot-ask
  variant); `AUTOPILOT_CLAUDE` (the executable; default `claude`);
  `AUTOPILOT_BATCH` (the batch name in the timeline's file name; default
  the tag's prefix before `-s`).
- A fresh launch generates a UUID (`uuidgen`, else
  `python3 -c 'import uuid;print(uuid.uuid4())'`), writes it to
  `<tag>.session` before the process starts, and passes
  `--session-id <uuid>`; a resume passes `--resume <session-id>` and writes
  that id to `<tag>.session`. Why: the transcript path and the resume id
  are then known even when the worker dies before its JSON lands.
- Always: `claude -p "$(cat <prompt-file>)"` — the prompt read from the
  file, never typed on the driver's command line — with `--name <tag>`,
  `--settings '{"crossSessionInbound":"accept"}'`,
  `--permission-mode bypassPermissions`, `--output-format json`; stdin
  from `/dev/null`; stdout to `<tag>.json`, stderr to `<tag>.err`; the
  claude process in a `( trap '' HUP; … ) &` subshell, wrapped in
  `caffeinate -i` when `command -v caffeinate` finds it; `<tag>.pid` holds
  the subshell's pid, written at launch; `<tag>.exit` holds claude's exit
  status, written by the subshell right after claude returns;
  `<batch>-timeline.log` gets `start <tag> pid <pid> …` at launch and
  `end   <tag> exit <status>` when it ends (Fixed forms). No `--model`, no
  `--continue`. The driver writes no costs line: the skill upserts
  `<batch>-costs.txt` after each `.exit`, and the header names that file as
  the skill's.
- `--self-test`: the script writes a stub executable under a fresh
  directory under `$TMPDIR` — it echoes its arguments to stderr, prints a
  JSON object with `result`, `session_id`, and `total_cost_usd` to stdout,
  sleeps one second, and exits 0 — and uses it as the executable unless the
  caller has already set `AUTOPILOT_CLAUDE`, in which case that value is the
  stub (this is how the mutated-stub check below is run); the self-test's
  logs directory is always a fresh directory under `$TMPDIR`, whatever
  `AUTOPILOT_LOGS` says, so a self-test writes nothing under the workspace;
  it writes a prompt file there, launches the stub through the same launch
  path as a real run, waits for `<tag>.exit` with the wait snippet's driver
  form, and checks that `<tag>.session`, `<tag>.pid`, `<tag>.json`
  (parseable — `python3` when present, else a `grep` for the `"result"`
  key — and holding `result`), `<tag>.err`, and `<tag>.exit` (reading `0`)
  exist and that the timeline holds the `start` and `end` lines. On success
  it prints `self-test passed` and exits 0, naming its logs directory;
  otherwise it exits 1 naming the first missing or wrong item. Why: the
  self-test proves the launch path on a machine without spending a session,
  and the skill runs the copied driver's self-test at every batch start; a
  caller-supplied stub is what lets the failure path be exercised.

**Files to create:**
- `plugins/kenspc/skills/autopilot/scripts/run.sh`

**Acceptance criteria:**
- `test -x plugins/kenspc/skills/autopilot/scripts/run.sh` exits 0;
  `head -1` of the file prints `#!/bin/bash`; `bash -n` on it exits 0;
  `grep -c '^set -u' plugins/kenspc/skills/autopilot/scripts/run.sh`
  prints 1.
- From the repository root and again from `$TMPDIR`:
  `bash <absolute path>/run.sh --self-test > "$TMPDIR/selftest.out" 2>&1; rc=$?`
  gives `rc` 0, and the output holds the line `self-test passed`.
- With `AUTOPILOT_CLAUDE` pointed at an executable under `$TMPDIR` that
  prints the same JSON object as the built-in stub and exits 3, the same
  command gives `rc` 1 and the output names `.exit` (a stub that printed
  nothing would fail the earlier `<tag>.json` check first, and the item
  named would be `.json`).
- After a passing self-test, the logs directory it names is under `$TMPDIR`
  and holds `<tag>.session`, `<tag>.pid`, `<tag>.json`, `<tag>.err`,
  `<tag>.exit` reading `0`, and a `<batch>-timeline.log` with one line
  matching `^start <tag> pid [0-9]+` and one matching
  `^end   <tag> exit 0$`; `<tag>.err` (the stub's echoed arguments) shows
  `--name <tag>`, `--settings {"crossSessionInbound":"accept"}`,
  `--permission-mode bypassPermissions`, `--output-format json`, and
  `--session-id` followed by the id that `<tag>.session` holds.
- `grep -cF -- '<string>' plugins/kenspc/skills/autopilot/scripts/run.sh`
  prints at least 1 for each of `--session-id`, `--resume`, `--name`,
  `--settings '{"crossSessionInbound":"accept"}'`,
  `--permission-mode bypassPermissions`, `--output-format json`,
  `--max-budget-usd`, `--plugin-dir`, `--append-system-prompt`,
  `/dev/null`, `trap '' HUP`, `caffeinate -i`, `command -v caffeinate`,
  `AUTOPILOT_LOGS`, `AUTOPILOT_PLUGIN_DIR`, `AUTOPILOT_BUDGET_USD`,
  `APPEND_SP`, `AUTOPILOT_CLAUDE`, `AUTOPILOT_BATCH`, and
  `self-test passed`.
- `grep -cE -- '--model|--continue|rm -r|declare -A|mapfile|readarray' plugins/kenspc/skills/autopilot/scripts/run.sh`
  prints 0.
- The header comment names the interface line
  `run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]`, the
  `--self-test` form, the six environment variables, the five files, the
  two timeline lines, and `<batch>-costs.txt` as written by the skill.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the file, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 2: Write the autopilot skill

**Status:** TODO

Depends on: Task 1

Plan Step 1.1 (F-1 to F-12; rulings M1–M9, M11, M12, M15, M16, D1, D3–D7,
D9–D22; clarifications CL1–CL3). Create
`plugins/kenspc/skills/autopilot/SKILL.md` in the structure and tone of
`diagnose-bug` and `prototype`: frontmatter, an opening that names the
phases, Trigger Phrases, Quality bar, Prerequisites, Arguments, the phases
with Goal / Inputs / DONE when / Constraints, a gate table, Exit, Writing
rules, Phase transitions; every rule carrying its Why in the skill's own
words — its evidence stated as what happened, never as a probe number, a
batch name, or a table row: "a subscription made after the worker exited
was refused, and a headless subscriber received the notice only as a new
turn after its final reply"; "the Bash tool blocks a bare sleep of thirty
seconds or more". File references use `${CLAUDE_PLUGIN_ROOT}`; the driver
is `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/scripts/run.sh`.

The file carries, in substance as plan Step 1.1 gives it:

- Frontmatter: `name: autopilot`; the `description` from plan Step 1.1,
  wrapped as the other skills wrap theirs (`description: >`) — the two
  entries, the six roles, the driver and the messages, the two gates, the
  "use only when the user hands over a whole batch" sentence, the four
  exclusions (one task or a task document → task-implement; a review →
  task-review; planning → generate-plan; a prompt that opens with the
  preamble's first sentence, quoted in the description so the exclusion
  has one shape to match — `You are a headless sub-session of the batch
  <batch> main session <main name>, unattended.` (Fixed forms) — one of
  this skill's own workers), and the triggers "put this spec on
  autopilot", "run this batch unattended", "take this batch to release",
  "无值守跑这批",
  "这批交给你跑到发布", "自动跑完这批", and `/kenspc-autopilot`;
  `version: 3.0.0`; `argument-hint: <path to a spec or a brief>`; no
  `effort:`.
- Trigger Phrases: the positive phrases, a few more in each language; an
  "Avoid triggering" list — one task or a task document ("implement this
  task", "帮我实作这个 task" → task-implement); a review ("review 一下",
  "review my changes" → task-review); a plan or a brief to write
  (generate-plan, generate-brief); and any prompt that opens with the
  preamble's first sentence, quoted whole (Fixed forms), with the Why: the
  skill's own workers read a prompt that names an unattended batch, and a
  worker that started another autopilot would nest the batch inside itself.
- Quality bar: a useful run reaches the release preparation with every
  step's evidence on disk — the spec committed, the task document, the
  commits, the run directories, the record — asks the user only at the two
  gates, and stops rather than guess on anything the lock or the spec does
  not answer; a run that narrows the implementation, or that approves a
  worker's question on the user's behalf, has failed the bar.
- Prerequisites: a git repository; `Claude Code v2.1.271 or later` with
  cross-session messaging — `ListAgents` names this session on its first
  line, and a session it does not stops with the version line; an
  interactive session that can ask, started with a name, bypass
  permissions, and `crossSessionInbound: accept` — the launch line
  `claude --name <batch>-main --permission-mode bypassPermissions --settings '{"crossSessionInbound":"accept"}'`;
  the workspace, `~/Projects/_smoke/` by default.
- Arguments: PATH — a spec (a plan document) or a brief. With no argument,
  ask for the path; the cannot-ask branch stops.
- Phase 0, Settle. Goal: the settings, the workspace, and the start checks.
  The entry kind by reference — a brief is what
  `${CLAUDE_PLUGIN_ROOT}/skills/generate-plan/SKILL.md` Phase 1 Step 1
  recognizes; a spec is a file that is not a brief and has the plan shape
  `${CLAUDE_PLUGIN_ROOT}/skills/task-implement/SKILL.md` Phase 1 Step 1
  describes (an `## Implementation Steps` section or Phase / Step
  headings, no `**Status:**` marker); a task document (Status markers)
  stops the run naming the plan it came from, as
  `/kenspc-autopilot <plan path>`; anything else stops and asks which it
  is — no detector of the skill's own. `## Autopilot` read as a bullet
  list of `- <Label>: <value>` fields in any order, every field defaulted
  and none required: `Baseline:` HEAD at start; `Mode:` detected, else
  `repo`; `Version:` `none`; `Budget:` `USD 200`; `Caps:`
  `16 sessions, 8 resumes`; `Allowed files:` and `Zero diff:` empty (no
  zero-diff check); `Acceptance:` `none`; `Release preparation:`
  `default`; `Prior specs:`, `Must read:`, `Challenge seeds:` empty;
  `Acceptance record:` unset; `Workspace:` the default; `Plugin:` unset;
  unknown labels ignored with a note in the settings line; the grammar of
  each value (`Acceptance:` sub-bullets — a command or a case description,
  its PASS criterion after ` — PASS: `, `(optional)` on a case that may be
  cut; `Release preparation:` `default`, `keep`, or sub-bullets;
  `Prior specs:` `<hash>^:<path>` entries for `git show`). The mode:
  `plugin` when the repository root holds `.claude-plugin/marketplace.json`
  and at least one `plugins/*/.claude-plugin/plugin.json`, `Mode:` winning
  over detection; the plugin directory `<root>/plugins/<name>` from
  `Plugin:`, else the single `plugins/*/` holding a `plugin.json`, several
  without `Plugin:` being a question; the value passed absolute, from
  `git rev-parse --show-toplevel`. The workspace tree — `_prompts/` (the
  copied driver, the preamble, the task blocks, the assembled prompts),
  `_logs/` (`<tag>.json/.err/.pid/.exit/.session`, `<batch>-timeline.log`,
  `<batch>-costs.txt`, `<batch>-state.md`, `<batch>-report.md`), seed
  projects `<batch>-*`, `.trash/`; `Workspace:` relocates the whole tree;
  `$TMPDIR` for anything else. The driver copied to
  `_prompts/<batch>-run.sh` and the copy's `--self-test` run once. The
  batch name = the argument file's base name without extension; tags
  `<batch>-s1` … `-s6`, a re-run `-s4b` / `-s5b`, a resume `<tag>-r<k>`;
  the main session's name `<batch>-main`, or, when the listed name differs,
  the name `ListAgents` prints on its first line, recorded. The wait path,
  decided once here: `ps -o args= -p $PPID` from the Bash tool shows `-p`
  or `--print` for a headless session, and the run then never subscribes
  and polls `<tag>.exit` with the driver-form snippet; an interactive
  session subscribes and ends its turn (CL1). The implementing task
  verifies that probe in the session it runs in and records the command it
  used and what it printed in its Implementation notes. The start checks:
  the argument file exists and is a brief or a spec; the working tree is
  clean except the argument file when it is untracked
  (`git -c core.quotePath=false status --porcelain -uall`); HEAD equals
  `Baseline:`; `ListAgents` names this session on its first line; the
  workspace is writable; the driver copy's `--self-test` passes; in plugin
  mode the plugin directory holds a `plugin.json`. The state file
  `_logs/<batch>-state.md`: the settings line, the current step and its
  tag, each session's tag, id, cost, and result, the questions answered,
  the stops, the clarification numbers recorded, and the next action;
  rewritten at every transition; re-read with `<tag>.exit` on every wake
  (a notice, a message, a user reply) before acting, since a wake starts a
  new turn whose only reliable memory is a file. DONE when the settings
  line (Fixed forms, ending `wait <interactive|headless>`) has been printed
  and the state file written. Every failing check is a stop whose final
  message ends with `Autopilot stopped: <reason>`; the cannot-ask branch
  of each ends the run with the same message.
- Phase 1, Design (brief entry only). Goal: a ruled spec committed. Inputs:
  the brief; the preamble and the S1 task block. The flow: launch S1
  (the launch line; the wait); on S1's `question` message carrying the
  compact table (number, one-line question, options, lean) and the
  draft's path, print the table to the user as received with the path and
  ask for a decision per number, "use your leans for the rest" accepted;
  a partial answer is followed by the remaining rows asked again with
  their leans until every row is decided or the rest delegated; a decision
  that contradicts a locked point is refused with the point named and
  asked again; then one message to S1 — first line
  `rulings <batch>: <n> rulings`, one `M<n>: <decision>` /
  `D<n>: <decision>` per row, ending with the fixed instruction: fill the
  Ruling column, set the status line to ruled, run the pointer-label
  grep, commit the spec alone as `docs(plans): add batch <name> spec`,
  reply with the hash, and stop. S1's task block: the draft-spec task
  (the shape of a ruled spec with an empty Ruling column, the design
  table's options and leanings, `Challenge seeds:`, the pointer-label
  rule, "send the compact table to <main name> and wait"), and that the
  reminder printed on a write under `docs/plans/` concerns plan generation
  and is to be ignored, since the spec is written by design outside that
  skill. DONE when the spec's commit hash is in the state file. A supplied
  spec skips this phase. In a session that cannot ask, every row takes its
  lean, the rulings message says `lean adopted (the session could not ask)`
  per row, and the reports say so row by row.
- Phase 2, Build. Goal: the batch implemented and reviewed. S2
  (`/kenspc-task <spec path>`), S3 (`/kenspc-task-implement <task doc path>`),
  S3b (`/kenspc-task-review review the range <baseline>..<HEAD at S3's end>`,
  which that skill pins as its range) in order, each a launch / wait /
  return: the launch through the driver copy, the `S<n> started —` line;
  the wait — interactive: subscribe to the worker with `notify_when_idle`
  right after the launch and end the turn; on every wake re-read the state
  file and `<tag>.exit`; with no `.exit` and a live pid, subscribe again
  and end the turn; a refused subscription means the worker is not
  reachable, so read `.exit` (present: finished; absent with the pid gone:
  dead); a notice that reports the subscription expired runs the same
  check; the notice is the wake and `.exit` the evidence; headless: never
  subscribe, poll with the driver-form snippet, one tool call of about a
  minute per iteration; the return — the `S<n> returned —` line, the costs
  upsert (`<tag> <session_id> <total_cost_usd>` into `<batch>-costs.txt`,
  a resume's JSON replacing its predecessor's value since it carries the
  whole total). A worker's question at generate-task's confirmation or
  task-implement's batch gate is answered from the spec — `yes` when the
  task list matches the spec's steps, and a mismatch is a question to the
  user, never `yes` on the user's behalf; a question the spec does not
  answer is a stop. The message protocol: before every send, `ListAgents`,
  and when two rows carry the name, the `[ref]` of the row whose start
  time matches the launch; a worker's question has the first line
  `question <tag>: <one line>` and a body with the context, the options,
  and its suggested answer; the answer's first line is
  `answer <tag>: <one line>` and its body the decision, quoting nothing
  the worker sent; questions answered in arrival order, one worker live at
  a time; a message from any other session (a hook's) recorded as an
  observation; messages carry summaries and paths, never a report's text
  (about a million characters per message, about thirty sends in a burst,
  fifty queued, identical repeats dropped); a worker with a table to show
  writes it to a file and sends the path; a delivery notice reporting that
  the first message to a worker was held or refused is a stop naming the
  settings precedence (managed settings, then `--settings`, then user
  settings; a project or local `hold` / `refuse` applies when stricter).
  The verdict loop after S3b: PASS → on to acceptance; FAIL, or PARTIAL
  with HIGH rows deferred → each HIGH and each row-3 or row-5 FAIL is
  classified as a plugin defect (S5 from that row, task block
  `Fix issue <ID> from run <run dir>: <one line>`, then a narrowed S3b
  over `<S3b HEAD>..<fix HEAD>`) or accepted as a deferral with a reason
  recorded as a clarification; the second narrowed review that still
  FAILs is the "guards red twice in a row" stop; DEFERRED MEDIUM and LOW
  rows classified once — fix in S5, or a roadmap candidate in the reviewer
  report. The zero-diff check after S3b:
  `git diff --stat <baseline> HEAD -- <Zero diff paths>` prints nothing,
  else a stop. Budget and caps before each launch: spent = the sum over
  sessions of each session's last cumulative `total_cost_usd`; projected =
  the largest single-session cost so far, or budget ÷ 6 before the first
  session; when spent + projected > budget, stop and ask "raise the budget
  to how much?" with spent, projected, and the remaining steps — the
  answer sets the budget for the rest of the run and is recorded in the
  state file and the reports, not in the brief; every launch passes
  `--max-budget-usd <remaining>` (the budget minus spent); `Caps:`
  (default `16 sessions, 8 resumes`) exceeded is a stop that asks for a
  new cap. Death and resume: a step's session is dead when its pid is gone
  and `<tag>.exit` is absent ten seconds later, or its JSON's subtype is
  not `success`; it is resumed once under `<tag>-r1` with the continue
  prompt (Fixed forms); a second death of the same step is a stop; a live
  pid is never killed and never judged hung — when asked, the main session
  reports the pid, the size of `<tag>.err`, the mtime of the transcript
  named by `<tag>.session`, and `git log -1 --format=%ct` in the worker's
  cwd; a worker ended by its cap is the budget stop, and after the user
  raises the budget it is resumed under `<tag>-r1` with the continue prompt
  and the new remaining cap, counted as a resume.
- Phase 3, Accept. Goal: the acceptance run and every FAIL classified.
  Plugin mode: S4 with a trial run of a seed first, to confirm the path
  under test is reachable (CL2's wording), one case per run, every driver
  reply named in the record, and the record
  `docs/dry-runs/<batch>-acceptance.md` with the fixed sections Setup,
  Independence, Cases, Findings, Observations, Not exercised, Summary.
  Repo mode: an S4 worker runs each `Acceptance:` command at the S3b HEAD
  in the repository, one command per Bash call, and replies with each
  command, its exit code, and the last twenty lines of its output; the
  results go into the reviewer report's acceptance lines; no file is
  written into the repository unless `Acceptance record:` names a path;
  with `Acceptance: none`, no S4 session starts and the report's acceptance
  line reads `none named; S3b is the last check`. The main session
  classifies each FAIL: plugin defect (implementation defect in repo mode)
  → S5 fix, then the case re-run in a new S4 session `-s4b` that runs only
  that case; behavior deviation → a roadmap line drafted for the release
  commit (plugin mode) or a reviewer-report line (repo mode); observation
  → recorded; the same case still failing after two fixes is a stop; every
  classification is a clarification entry in the spec, committed by the
  main session as `docs(plans): record clarifications settled after <step>`.
  S5's task block: the classified defect, the case to make pass, and
  "commit the fix alone". The narrowing rule: cases marked `(optional)` may
  be cut when the budget check fails, in the order listed, with Not
  exercised recorded; an unmarked case that cannot be run is a stop;
  implementation is never narrowed.
- Phase 4, Release preparation and reports. Goal: S6's commit and the two
  reports. Repo mode: `Release preparation: default` — one commit,
  `docs: remove batch <name> plan and tasks`, that `git rm`s the batch's
  plan and task documents and touches no version and no CHANGELOG; `keep`
  — no S6; a list of instructions — S6 runs them as its task block, after
  the default removal unless the list says `keep`; `Version: <string>` in
  repo mode is passed to S6 as an instruction to bump wherever the
  repository's CLAUDE.md says versions live, else ignored with a
  settings-line note. Plugin mode: the repository's release checklist
  (`docs/release-checklist.md` when it exists) and CLAUDE.md's release
  convention govern — the CHANGELOG's `— unreleased` heading gets today's
  date, the plugin manifest's version becomes `Version:`, the manifests'
  descriptions name the new capability, the checklist's counting rows
  follow, the roadmap's shipped items leave and its heading names the next
  minor, the batch's brief, plan, and task documents are `git rm`ed, one
  release commit in the repository's convention, the pre-flight block runs
  with its two count lines in S6's reply; no tag, no push; with
  `Version: none` in plugin mode, S6 makes the removal commit only and the
  reports say the release was not prepared. The zero-diff check again. The
  reports, both in the final message: `## User report` — the conversation's
  language, at most one page: what the batch built, the release commit,
  what needs the user (tag / push / release; any stop or deferred item),
  the cost; `## Reviewer report` — English, fixed fields in this order:
  batch and mode; baseline → release hash (or the last commit); the spec's
  read command (`git show <hash>:<path>`); design rulings and
  clarifications — their counts and the list of decisions beyond the
  letter; files changed and the zero-diff result; byte-identity / guards /
  counts (plugin mode: the pre-flight lines); acceptance, one line per case
  with its cost and result, or `none named; S3b is the last check`; total
  cost — the measured sum of the workers' last cumulative `total_cost_usd`
  plus the main session's own cost as an estimate labeled "estimated": its
  turn count (launches + wakes + answers + the final turn) × the mean cost
  per turn across this batch's workers (each worker's `total_cost_usd` ÷
  `num_turns` from its JSON), the basis stated on the line, `/cost` may
  replace it; Not exercised; release-preparation state; sessions /
  messages / resumes / stops with reasons, one line per session with tag,
  id, cost, and result. The reviewer report is built from the state file
  and also written to `_logs/<batch>-report.md`; the state file's last
  transition; the final message ends with
  `Autopilot finished — <baseline sha>..<last sha>` and the sentence that
  tag, push, and release are the user's.
- The templates, as fenced blocks a worker or the skill copies, each with
  its Why: the preamble — written once to `_prompts/<batch>-preamble.md`,
  in English, its six parts: (1) role — the fixed first sentence
  `You are a headless sub-session of the batch <batch> main session <main name>, unattended.`,
  the main session's name, and the ask protocol with the worker-form wait
  snippet, the thirty-minute limit, and the question form (on timeout the
  question goes under `## Question for the main session` in the final
  message and the worker stops); (2) exemplars — the spec or brief path,
  `git show <hash>^:<path>` for each `Prior specs:` entry, the `Must read:`
  paths, and the repository's CLAUDE.md; (3) the safety rails with the
  workspace and the repository root filled in — write only to the
  repository, the workspace, and `$TMPDIR`; no `git push`, `git tag`, or
  release; no resource the brief does not name; no secrets; no `rm -rf` —
  discard by `mv` into `.trash/<name>-<timestamp>/`; deletions inside the
  repository only through `git rm`; any breach is a stop; (4) the locked
  design's numbered points with one-line topics and the file section to
  read them in; (5) out of scope and (6) constraints — the spec's sections
  by name (the brief's, at brief entry) plus the repository's CLAUDE.md;
  self-contained, never "as an earlier batch did". The task blocks
  `_prompts/<batch>-<tag>-task.md` per launch (S1–S6 as above), the
  launched prompt `_prompts/<batch>-<tag>.md` their concatenation. The
  driver's interface: the interface line of Task 1's header, the six
  environment variables, the five files, the timeline and costs lines, the
  self-test line `self-test passed`. Both wait snippets (Fixed forms): the
  driver form polling `<tag>.exit`, the worker form counting only, with
  the Why (the Bash tool blocks a bare sleep of thirty seconds or more and
  refuses chained short sleeps; a bounded `until` loop is the form its own
  message recommends and needs nothing outside POSIX sh; each iteration is
  one tool call). The settings line. The stop conditions, each with its
  reason: reopening a locked point; a forbidden section or file; guards red
  twice in a row; the same FAIL still failing after two fixes; the session
  or resume cap or the budget exceeded (a question); a rail breach; a
  question neither spec nor lock answers; a nested `claude -p` refused;
  the same step's session dead twice. The decision hierarchy: the locked
  design (immutable) > the design table's decisions (the main session,
  within the lock; the user at brief entry) > clarifications during
  implementation (the main session; recorded in the spec and committed);
  decisions beyond the letter of the lock are reported.
- Gate table: every question the skill asks and its cannot-ask outcome —
  start checks and settings stops end the run with the reason; the budget
  and cap questions end it with the numbers; the brief-entry decisions take
  the leans; a worker's question the spec answers is answered from the
  spec, one it does not answer ends the run with the question quoted; the
  final gate ends the run with the two reports and the finish line — each
  gate also carrying the sentence in the Fixed-forms wording where it is
  asked.
- Writing rules: prompts, the spec, commit messages, and the reviewer
  report in English; the user report and the conversation in the user's
  language; the fixed lines in English whatever the conversation language.
- Exit: the final message's shape on a finish and on a stop.
- Phase transitions rest on artifacts: the settings line and state file;
  the spec's commit; each `<tag>.exit`; the task document; S3b's Schema F;
  the record or the S4 reply; S6's commit; the reports.

The skill contains no copy of generate-plan's brief test, of
task-implement's plan-or-task test, or of the driver: it points at the two
skills by path and quotes the driver's interface from Task 1's header.

**Files to create:**
- `plugins/kenspc/skills/autopilot/SKILL.md`

**Acceptance criteria:**
- `grep -c` on the file prints 1 for each of `^name: autopilot$`,
  `^version: 3.0.0$`, and `^argument-hint: <path to a spec or a brief>$`,
  and 0 for `^effort:`.
- In the joined text of the frontmatter (the lines between the first two
  `---` lines), each of `You are a headless sub-session of the batch`,
  "put this spec on autopilot", "run this batch unattended", "take this
  batch to release", "无值守跑这批", "这批交给你跑到发布", "自动跑完这批",
  `/kenspc-autopilot`, `task-implement`, `task-review`, and `generate-plan`
  occurs at least once.
- The file has Trigger Phrases (with the "Avoid triggering" list holding the
  whole preamble sentence), Quality bar, Prerequisites, Arguments, Phases
  0–4 each with Goal, Inputs, DONE when, and their Whys, a gate table, Exit,
  Writing rules, and Phase transitions.
- `grep -cF '<string>' plugins/kenspc/skills/autopilot/SKILL.md` prints at
  least 1 for each Fixed form the skill carries, written unwrapped: the
  settings line (the whole line, ending `wait <interactive|headless>`); the
  preamble first sentence (at least 2 — the Avoid-triggering list and the
  preamble template); the launch line; the return line;
  `question <tag>: <one line>`; `## Question for the main session`;
  `answer <tag>: <one line>`; `rulings <batch>: <n> rulings`;
  `M<n>: <decision>`; `D<n>: <decision>`;
  `lean adopted (the session could not ask)`; the continue prompt;
  `Autopilot stopped: <reason>`;
  `Autopilot finished — <baseline sha>..<last sha>`; `## User report`;
  `## Reviewer report`; `none named; S3b is the last check`; both wait
  snippets; `docs(plans): add batch <name> spec`;
  `docs: remove batch <name> plan and tasks`;
  `docs(plans): record clarifications settled after <step>`;
  `run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]`;
  `self-test passed`; the main-session launch line; the worker settings
  flag; `Fix issue <ID> from run <run dir>: <one line>`;
  `<batch>-costs.txt`; `<batch>-timeline.log`; `<batch>-state.md`;
  `<batch>-report.md`; `docs/dry-runs/<batch>-acceptance.md`;
  `Claude Code v2.1.271 or later`; `ps -o args= -p $PPID`;
  `notify_when_idle`; `--max-budget-usd`; `16 sessions, 8 resumes`;
  `USD 200`; and `## Autopilot` together with each of its sixteen labels.
- `grep -c 'skills/generate-plan/SKILL.md' plugins/kenspc/skills/autopilot/SKILL.md`
  and `grep -c 'skills/task-implement/SKILL.md' …` each print at least 1
  (the entry-kind tests by path), and
  `grep -c 'skills/autopilot/scripts/run.sh' …` prints at least 1.
- The driver block's interface line equals the interface line of
  `run.sh`'s header comment (`grep -F 'run.sh <tag> <cwd> <prompt-file>'`
  on both files prints the same line, comment marker aside), and the block
  names the six environment variables of Task 1.
- In the joined text,
  `In a session that cannot ask (a system reminder to work without stopping)`
  occurs at least 6 times — once at each gate the gate table lists (the
  no-argument case, the start checks and settings stops, the budget and cap
  questions, the brief-entry decisions, a worker's question, the final
  gate) — and every row of the gate table names its cannot-ask outcome.
- The Quality bar names an answer on the user's behalf as a failed run;
  Phase 2 says the confirmation is `yes` only when the task list matches
  the spec's steps and a mismatch is a question to the user; Phase 0 says
  a headless session never subscribes and polls `<tag>.exit`; the
  Implementation notes record the wait-path probe's command and its output
  in the session the task ran in.
- The seven fixed record sections (Setup, Independence, Cases, Findings,
  Observations, Not exercised, Summary) and the nine stop conditions are
  each named.
- `grep -cwE 'ruling' plugins/kenspc/skills/autopilot/SKILL.md` prints 0
  (CL3), and `grep -cE 'dry-run\b' …` prints 0 (CL2 — `dry-runs` passes).
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the file, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`,
  `claude plugin validate --strict ./plugins/kenspc` passes, and
  `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test` still
  prints `self-test passed` and exits 0.

---

### Task 3: Add the /kenspc-autopilot command

**Status:** TODO

Depends on: Task 2

Plan Step 1.3 (F-1; ruling M15). Create
`plugins/kenspc/commands/kenspc-autopilot.md` in the shape of the eight
existing command files (for example `commands/kenspc-diagnose.md`):
`name: kenspc-autopilot`; the one-line description
"Explicit entry point for the autopilot skill — run one batch unattended
(无值守跑完一批) from a spec or a brief to a local release preparation.";
`argument-hint: <path to a spec or a brief>`;
`disable-model-invocation: true`; a body that invokes the **autopilot**
skill, reads `${CLAUDE_PLUGIN_ROOT}/skills/autopilot/SKILL.md`, and passes
`$ARGUMENTS` through. Why: commands are explicit entry points only; the
skill's description owns the routing.

**Files to create:**
- `plugins/kenspc/commands/kenspc-autopilot.md`

**Acceptance criteria:**
- `diff plugins/kenspc/commands/kenspc-diagnose.md plugins/kenspc/commands/kenspc-autopilot.md`
  shows differences only in the `name`, `description`, and `argument-hint`
  lines and in the two body lines that name the skill and its path.
- The description is the one line given above, and
  `disable-model-invocation: true` is present.
- `ls plugins/kenspc/commands/*.md | wc -l` prints 9.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the file, `claude plugin validate --strict ./plugins/kenspc`,
  `bash scripts/check-no-model-names.sh`, and `bash scripts/check-all.sh`
  exit 0.

---

### Task 4: Update the repository CLAUDE.md

**Status:** TODO

Depends on: Task 1-3

Plan Step 2.1 (F-14; rulings D23, M14; CL6). In `CLAUDE.md`, seven places:

- § Project Overview: one sentence in the first paragraph — the plugin
  also runs one batch of its own chain unattended (the autopilot skill),
  from a spec or a brief to a local release preparation, through headless
  sessions rather than agents.
- § Plugin Directory Layout, the tree: `kenspc-autopilot.md` under
  `commands/`; `autopilot/` under `skills/` with `SKILL.md` and
  `scripts/run.sh` — the first skill with a `scripts/` subdirectory, which
  `check-no-model-names.sh` scans (a comment on the tree line or a
  sentence after it); the PowerShell mirror is not listed until it exists.
- § SKILL.md Frontmatter Fields: "all eight skills", "syncing eight files",
  and "bump all eight together" become nine.
- § Subagent Review Architecture: a fourth orchestration pattern after the
  Parallel MapReduce paragraphs and before "#### CONTEXT block contract",
  opening `**Sessions, not agents (autopilot):**` — one headless
  `claude -p` session per role (S1 design at brief entry, S2 task
  decomposition, S3 implementation, S3b standalone review, S4 acceptance,
  S5 fix on demand, S6 release preparation), started through the driver
  script that ships with the skill and is copied per batch, each with
  `--name <tag>` and `crossSessionInbound: accept`; questions and answers
  by cross-session messages (`question <tag>:` / `answer <tag>:`), the
  idle notice as the main session's wake and `<tag>.exit` as the completion
  artifact (a transition never rests on a notice's wording), the state
  file re-read on every wake; `--resume` only for a worker that has died;
  no agent, no CONTEXT key, no agent teams. The effort paragraph's "the
  seven other skills" becomes "the eight other skills".
- § Development Workflow, beside the rule that begins "Edit the plugin's
  agent and skill files in a session started without `--plugin-dir`": a
  sentence worded on the evidence — that rule's block is auto mode's
  classifier inside a `--plugin-dir` session; under
  `--permission-mode bypassPermissions` there is no classifier, and the
  autopilot's headless workers run that way, with `--plugin-dir` in plugin
  mode; a worker sees a plugin edit only in the next session, so review,
  acceptance, and fix are separate sessions.
- § Non-Goals: three paragraphs — no agent teams (one role per session,
  a session never reused across roles); no driver completion message on
  the messaging socket — its line format is undocumented, and `<tag>.exit`
  is the completion artifact; the workspace lives outside the repository
  (`~/Projects/_smoke/` by default, relocated by `Workspace:`) — a
  plugin-mode seed is a clone that cannot live inside the repository it
  clones.
- § Writing Rules for Skill Content, the bullet that lists the skills
  sharing the cannot-ask wording ("the wording diagnose-bug,
  generate-plan's … and the prototype skill's gates share"): one clause
  adds the autopilot skill's gates to that list (CL6).

§ Durable documents, § Repository scripts/, and every stated guard count
are unchanged.

**Files to modify:**
- `CLAUDE.md`

**Acceptance criteria:**
- `grep -c 'all eight skills\|syncing eight files\|bump all eight together' CLAUDE.md`
  prints 0 (3 at `5c33c4a`), and each of `all nine skills`,
  `syncing nine files`, and `bump all nine together` occurs once.
- `grep -c 'seven other skills' CLAUDE.md` prints 0 (1 at `5c33c4a`), and
  `eight other skills` occurs once.
- `grep -cF 'Sessions, not agents (autopilot)' CLAUDE.md` prints 1, and the
  paragraph names the six roles, the driver, `--name`,
  `crossSessionInbound`, `question <tag>:`, `answer <tag>:`,
  `<tag>.exit`, the state file, `--resume`, and "no agent, no CONTEXT key,
  no agent teams".
- The layout tree lists `kenspc-autopilot.md` and `autopilot/` with
  `SKILL.md` and `scripts/run.sh` and does not list `run.ps1`
  (`grep -c 'run.ps1' CLAUDE.md` prints 0).
- The Development Workflow paragraph holds a sentence with
  `bypassPermissions` and "no classifier"; the first paragraph of the file
  names the autopilot; Non-Goals names agent teams, the socket, and the
  workspace.
- Every hunk of `git diff -U0 5c33c4a -- CLAUDE.md` lies in § Project
  Overview, § Plugin Directory Layout, § SKILL.md Frontmatter Fields,
  § Subagent Review Architecture before "#### CONTEXT block contract" (the
  new pattern and the effort paragraph's count; nothing from that heading
  to § Non-Goals changes), § Development Workflow, or § Non-Goals (hunk
  ranges), or the one bullet of § Writing Rules for Skill Content that
  lists the skills sharing the cannot-ask wording, which after the edit
  contains `autopilot` (`grep -c 'the wording diagnose-bug' CLAUDE.md`
  prints 1 and that line, with its line breaks joined, contains
  `autopilot`), and the reviewer invariant sentence is
  unchanged (`check-run-contract.sh` check 6 reports PASS in
  `bash scripts/check-all.sh`, which exits 0 with `guards run: 10`).
- The file reads top to bottom without a contradiction about skill,
  command, or guard counts.

---

### Task 5: Document the autopilot in the plugin README

**Status:** TODO

Depends on: Task 1-3

Plan Step 2.2 (rulings D23, M5, M7, M11, D1, D4, D5, D10, D11, D13, D20;
clarification CL1). In `plugins/kenspc/README.md`, six places:

- § Skills: an `autopilot` row after `generate-guide` — the two entries
  (a spec runs unattended from task decomposition; a brief first gets a
  design session whose table the user rules on), the two modes, the
  topology (one headless session per role: task decomposition,
  implementation, standalone review, acceptance, fix on demand, release
  preparation), the driver script and cross-session messages, the two
  human gates, the two reports, and the version requirement — stated in
  the row as `v2.1.271 or later` with a pointer to § Requirements, not as
  the fixed string, so that `Claude Code v2.1.271 or later` appears in the
  file once, in § Requirements (the line the plan's text check greps for).
- § Commands: a row `` `/kenspc-autopilot` `` |
  `` `/kenspc-autopilot <path to a spec or a brief>` `` after the
  `/kenspc-guide` row, and `/kenspc:autopilot` in the skill-invocation
  sentence (nine forms).
- § Recommended Workflow: after item 4, one line — or hand a spec or a
  brief to `/kenspc-autopilot`, which runs the chain to a release
  preparation.
- A new section `## Autopilot` between § Run directory and § Known
  behavior: the main-session launch line (Fixed forms) and that the run
  uses the name `ListAgents` prints when the session was started
  otherwise; the `## Autopilot` section's sixteen labels with one example
  section as a fenced block and the defaults; the workspace tree
  (`_prompts/`, `_logs/` with `<tag>.json/.err/.pid/.exit/.session`,
  `<batch>-timeline.log`, `<batch>-costs.txt`, `<batch>-state.md`,
  `<batch>-report.md`; seeds `<batch>-*`; `.trash/`; `Workspace:`); what a
  run writes and commits per mode (repo: the workers' commits and the
  removal commit `docs: remove batch <name> plan and tasks`; plugin: the
  same plus the acceptance record and the release commit; at brief entry
  the spec commit `docs(plans): add batch <name> spec`; the main session's
  clarification commits); the two gates; the stop conditions; the budget
  rule (`USD 200` default, `16 sessions, 8 resumes`, `--max-budget-usd`
  per worker, the ask); the two reports with the total-cost line's basis;
  the drivers — `run.sh` ships with the skill and is copied per batch, its
  `--self-test` line, and the PowerShell mirror `run.ps1` follows.
- § Known behavior, seven new items directly before
  `**Missed-review telemetry.**`, each with its evidence in the README's
  own words: one tool call per wait iteration (a thirty-minute wait is
  about thirty calls; the Bash tool blocks a bare sleep of thirty seconds
  or more); a headless session that subscribes gets the idle notice not
  between its tool calls but as an extra turn after its final reply, its
  JSON `result` then being that turn's last message — so a headless
  autopilot never subscribes and polls `<tag>.exit` (CL1); sessions that
  share a name (the duplicate-name rename does not check a `-p` session's
  `--name`; `ListAgents` before each send, the `[ref]` when two rows share
  the name); hook sessions and hook files in seeds (a user-level hook's
  session shares the trace directory and may write into a seed; observed
  and listed, not counted as cost or as the run's change); the twelve-hour
  subscription expiry (the notice reports it; the skill re-checks
  `<tag>.exit` and subscribes again); message limits (about a million
  characters per message, about thirty sends in a burst, fifty queued,
  identical repeats dropped — messages carry summaries and paths, never a
  report's text); stricter inbound settings (a project or local
  `crossSessionInbound` of `hold` or `refuse` applies over the workers'
  `--settings` accept; a held or refused first message is a stop naming the
  precedence). Machine sleep is covered in § Autopilot's driver paragraph
  (`caffeinate -i` when present).
- § Requirements: under **Required**, a second bullet — `/kenspc-autopilot`
  needs `Claude Code v2.1.271 or later` (cross-session messaging, the
  idle-notice subscription, the own-name listing, and notices to headless
  senders); the plugin's `v2.1.0+` minimum is unchanged, since every other
  skill runs on it.

**Files to modify:**
- `plugins/kenspc/README.md`

**Acceptance criteria:**
- `grep -n 'Claude Code v2.1.271 or later' plugins/kenspc/README.md` finds
  exactly one line, in § Requirements, and `grep -c 'Claude Code v2.1.0+'`
  still prints 1.
- `awk '/^## Skills/,/^## Commands/' plugins/kenspc/README.md | grep -c '^| [a-z]'`
  prints 9 (8 at `5c33c4a`);
  `awk '/^## Commands/,/^## Plugin Structure/' plugins/kenspc/README.md | grep -c '^| `/kenspc-'`
  prints 9 (8);
  `awk '/^## Commands/,/^## Plugin Structure/' plugins/kenspc/README.md | grep -o '/kenspc:[a-z-]*' | sort -u | wc -l`
  prints 9 (8).
- `grep -c '^## Autopilot$' plugins/kenspc/README.md` prints 1, the
  section sits between `## Run directory` and `## Known behavior`, and
  `grep -cF '<string>'` on the file prints at least 1 for the main-session
  launch line, each of the sixteen labels, `~/Projects/_smoke/`, `.trash/`,
  `<tag>.exit`, `<batch>-costs.txt`, `<batch>-state.md`,
  `docs: remove batch <name> plan and tasks`,
  `docs(plans): add batch <name> spec`, `USD 200`, `16 sessions, 8 resumes`,
  `--max-budget-usd`, `## User report`, `## Reviewer report`,
  `Autopilot stopped:`, `Autopilot finished —`, `run.sh`, `run.ps1`,
  `self-test passed`, and `caffeinate -i`.
- `awk '/^## Known behavior/,/^## Requirements/' plugins/kenspc/README.md | grep -c '^- \*\*'`
  prints 20 (13 at `5c33c4a`), the seven new items sit directly before
  `**Missed-review telemetry.**`, and their joined text holds "extra turn",
  `notify_when_idle` or "idle notice", `[ref]`, "twelve hours" or "12
  hours", "hook", "hold", and "refuse".
- The Recommended Workflow holds one line naming `/kenspc-autopilot`
  outside the diagram, and the Skills row names both entries, both modes,
  the six roles, the two gates, and the two reports.
- Every hunk of `git diff -U0 5c33c4a -- plugins/kenspc/README.md` lies in
  § Skills, § Commands, § Recommended Workflow, between § Run directory and
  § Known behavior (the new section), § Known behavior, or § Requirements
  (hunk ranges).
- Every sentence the task adds agrees with the skill and driver text as
  committed by Tasks 1–3.
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`
  (`check-run-contract.sh` check 6 reads the reviewer invariant sentence in
  this file).

---

### Task 6: Update the root README and the two manifests

**Status:** TODO

Depends on: Task 1-3

Plan Step 2.2 (rulings D23, M15).

- `README.md` (root): an `autopilot` row at the end of the skills table —
  "Runs one batch unattended from a spec or a brief to a local release
  preparation — one headless session per role, driven by cross-session
  messages; two human gates"; `/kenspc-autopilot` appended to the
  **Commands:** line.
- `plugins/kenspc/.claude-plugin/plugin.json`: the description's skills
  sentence gains "unattended batch runs to a release preparation";
  "eleven reusable subagents" and every other sentence unchanged;
  `version` stays `3.8.2`.
- `.claude-plugin/marketplace.json`: the top-level description gains the
  autopilot ("… multi-angle code review, and unattended batch runs to a
  release preparation"); the plugin entry's summary is unchanged.

**Files to modify:**
- `README.md`
- `plugins/kenspc/.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

**Acceptance criteria:**
- `awk '/^\*\*Skills:\*\*/,/^\*\*Commands:\*\*/' README.md | grep -c '^| [a-z]'`
  prints 9 (8 at `5c33c4a`), and
  `grep '^\*\*Commands:\*\*' README.md | grep -o '/kenspc-[a-z-]*' | wc -l`
  prints 9 (8), the last being `/kenspc-autopilot`.
- `grep -c 'unattended batch runs to a release preparation' plugins/kenspc/.claude-plugin/plugin.json`
  and `grep -c 'unattended batch runs to a release preparation' .claude-plugin/marketplace.json`
  each print 1 (the phrase the two descriptions gain);
  `grep '"version"' plugins/kenspc/.claude-plugin/plugin.json` still shows
  `3.8.2`; `grep -c 'eleven reusable subagents' plugins/kenspc/.claude-plugin/plugin.json`
  prints 1; `git diff 5c33c4a -- plugins/kenspc/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
  changes only the two top-level description strings.
- `bash scripts/check-json.sh`, `bash scripts/check-all.sh`,
  `claude plugin validate --strict .`, and
  `claude plugin validate --strict ./plugins/kenspc` exit 0.

---

### Task 7: Add the autopilot smoke row to the release checklist

**Status:** TODO

Depends on: Task 1-3

Plan Step 2.4 (F-14; rulings D23, D24; clarification CL1). In
`docs/release-checklist.md`, the smoke table only; the pre-flight block and
its counts (`guards run: 10`, `self-tests run: 9`) are unchanged. In a table
row, each literal `|` is written `\|`, inside a code span too, so the row
keeps its three cells.

- Row 1: "Lists all 9 kenspc slash commands without error".
- A new row 11, `/kenspc-autopilot <spec>`, inserted after row 10; the
  end-to-end row becomes 12, and its cell's "(see row-11 detail below)"
  and the heading "Row 11 sub-criteria" become row-12 / Row 12. Row 11's
  pass criterion, in substance: on a throwaway `repo`-mode seed with a
  one-task plan and `Acceptance: none`, run headless, the trace shows the
  settings line (`Autopilot settings —`, ending `wait headless`), then
  `S2 started —` / `S2 returned —`, `S3 …`, `S3b …`, `S6 …` in that order,
  each `S<n> returned` after the matching `<tag>.exit` exists (the
  timeline's `end` line before the return line's timestamp); four workers
  with those tags in the timeline and no resume line; at least one
  `question <tag>:` message from a worker answered with an `answer <tag>:`
  message (the seed plan leaves one point open to force it), the answer
  taken from the spec; the release commit `git rm`s the plan and the task
  document and touches no version; no `git push`, `git tag`, or `rm -r` in
  any session's Bash commands; the final message holds `## User report`,
  `## Reviewer report`, a total-cost line, and `Autopilot finished —`;
  `<batch>-costs.txt` has one line per worker; a task document given as
  the argument starts no worker and ends with `Autopilot stopped:` naming
  the plan; a prompt that opens with the preamble's first sentence invokes
  no skill; `run.sh --self-test` prints `self-test passed`. The row's
  cost note: one headless `repo`-mode batch on a one-task seed costs about
  USD 10–20 at the batch E per-session figures (an implement run USD 1–6,
  a review USD 4–6, twice); `plugin` mode was exercised once, in this
  batch's acceptance record, and is not part of the per-release smoke.

**Files to modify:**
- `docs/release-checklist.md`

**Acceptance criteria:**
- `grep '^| 1 |' docs/release-checklist.md | grep -c 'Lists all 9 kenspc slash commands'`
  prints 1 (0 at `5c33c4a`).
- `grep -cE '^\| [0-9]+ \|' docs/release-checklist.md` prints 12 (11 at
  `5c33c4a`); row 11 is `/kenspc-autopilot <spec>` and row 12 is the
  end-to-end row.
- `grep '^| 11 |' docs/release-checklist.md | grep -cF '<string>'` prints
  1 for each of `Autopilot settings —`, `wait headless`, `S2 started —`,
  `S2 returned —`, `<tag>.exit`, `question <tag>:`, `answer <tag>:`,
  `## User report`, `## Reviewer report`, `Autopilot finished —`,
  `Autopilot stopped:`, `<batch>-costs.txt`, `self-test passed`,
  `git push`, and `rm -r`, and the row holds the cost note with "USD 10–20"
  and names `plugin` mode as exercised once and not part of the smoke.
- `grep -c 'row-12 detail' docs/release-checklist.md` and
  `grep -c 'Row 12 sub-criteria' docs/release-checklist.md` each print 1,
  and `grep -nE '[Rr]ow[- ]11' docs/release-checklist.md` finds only
  references that mean the new autopilot row.
- `grep -E '^\| (1|11|12) \|' docs/release-checklist.md | sed 's/\\|//g' | awk -F'|' '{print NF}'`
  prints 5 on each line: no unescaped `|` splits a cell.
- `git diff 5c33c4a -- docs/release-checklist.md` touches only rows 1,
  11, and 12 and the two row-12 references; the pre-flight block and its
  prose still say `guards run: 10` and `self-tests run: 9`.
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`.

---

### Task 8: Write the 3.9.0 CHANGELOG entry

**Status:** TODO

Depends on: Task 1-7

Plan Step 2.3 (F-14; clarification CL1). In `plugins/kenspc/CHANGELOG.md`,
a new entry directly above `## 3.8.2 — 2026-09-26`, under the heading
`## 3.9.0 — unreleased`:

- Intro paragraph: batch F; what ships, in one paragraph — the autopilot
  skill and `/kenspc-autopilot`, the two entries, the two modes, one
  headless session per role through a shipped driver and cross-session
  messages, the two gates, the two reports; a new command and skill, so a
  minor release; no new agent or CONTEXT key; guard counts unchanged
  (`guards run: 10`, `self-tests run: 9`); the release smoke named at
  release (the acceptance record does not exist yet).
- `### Added`: the autopilot skill and `/kenspc-autopilot` — the entries
  (a spec unattended from S2; a brief through a design session and the
  user's rulings on its table), the modes and how `plugin` is detected,
  the topology S1–S6 with one role per session, the driver `run.sh` (its
  interface, the files it writes, `--session-id`, `--max-budget-usd`,
  `caffeinate -i`, the `--self-test`), the messaging protocol
  (`question <tag>:` / `answer <tag>:`, the idle-notice wake, `<tag>.exit`
  as the completion artifact, the thirty-minute wait and the `--resume`
  fallback), the budget and caps (`USD 200`, `16 sessions, 8 resumes`,
  the ask), the stop conditions, the two gates, the two reports with the
  total-cost line's basis, the `## Autopilot` section and its labels; the
  new Known behavior items; CLAUDE.md's fourth orchestration pattern; the
  README sections; release-checklist row 11 and the command count; the
  PowerShell driver `run.ps1` follows, written after the bash driver passes
  acceptance and checked with `pwsh` on macOS.
- `### Known behavior`: the items the README carries, with their sources
  stated as evidence in the entry's own words — a headless session that
  subscribed received the idle notice as an extra turn after its final
  reply, twenty-six minutes after its worker exited, and its JSON `result`
  became that turn's last message (CL1); the Bash tool's block on a bare
  sleep of thirty seconds or more; the duplicate-name rename not checking
  a `-p` session; hook sessions in the trace directory and hook files in
  seeds; the twelve-hour expiry; the message limits; the earlier batches'
  numbers (sessions and runs 7 + 11, 10 + 14, 6 + 7; resumes 5, 9, 7) as
  the reason for the caps' default.
- The heading keeps `unreleased`; the date is filled at release.

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`

**Acceptance criteria:**
- `grep -n '^## 3.9.0 — unreleased$' plugins/kenspc/CHANGELOG.md` finds one
  line, and
  `awk '/^## 3.9.0 — unreleased$/,/^## 3.8.2 — 2026-09-26$/' plugins/kenspc/CHANGELOG.md | grep '^##'`
  prints, in order, the 3.9.0 heading, `### Added`, `### Known behavior`,
  and the 3.8.2 heading, and nothing else.
- The entry's joined text holds `/kenspc-autopilot`, `run.sh`,
  `--self-test`, `run.ps1`, `crossSessionInbound`, `question <tag>:`,
  `answer <tag>:`, `<tag>.exit`, `## Autopilot`, `USD 200`,
  `16 sessions, 8 resumes`, `## User report`, `## Reviewer report`,
  `guards run: 10`, `self-tests run: 9`, and "extra turn".
- Every behavior the entry names matches the skill and driver text as
  committed by Tasks 1–3, the README sections of Tasks 5 and 6, and the
  checklist row of Task 7.
- `git diff 5c33c4a -- plugins/kenspc/CHANGELOG.md` only adds lines above
  `## 3.8.2 — 2026-09-26`.
- `grep '"version"' plugins/kenspc/.claude-plugin/plugin.json` still shows
  `3.8.2`.
- `bash scripts/check-all.sh --self-test` prints `guards run: 10`, ends
  with `self-tests run: 9`, and exits 0.

---

### Task 9: Doc-sync

**Status:** TODO

Depends on: Task 1-8

Bring the documents below in line with what Tasks 1-8 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` § Project Overview, § Plugin Directory Layout, § SKILL.md
  Frontmatter Fields (the count sentences), § Subagent Review Architecture
  (the new pattern, the effort paragraph's count, the bypass-permissions
  sentence), § Non-Goals — the autopilot skill, its driver, and its
  command (plan Step 2.1); edited by Task 4: verify it against the
  implementation instead of editing it again.
- `plugins/kenspc/README.md` § Skills, § Commands, § Recommended Workflow,
  the new § Autopilot, § Known behavior, § Requirements — what an
  unattended run does, writes, commits, and asks (plan Step 2.2); edited by
  Task 5: verify it against the implementation instead of editing it again.
- `README.md` § Available Plugins (skills table, Commands line) — the
  autopilot row and command (plan Step 2.2); edited by Task 6: verify it
  against the implementation instead of editing it again.
- `plugins/kenspc/CHANGELOG.md` — the `## 3.9.0 — unreleased` entry (plan
  Step 2.3); edited by Task 8: verify it against the implementation instead
  of editing it again.
- `docs/release-checklist.md` — row 1, the new row 11, the end-to-end row's
  number; pre-flight unchanged (plan Step 2.4); edited by Task 7: verify it
  against the implementation instead of editing it again.
- `docs/roadmap.md` — the heading becomes `## Next minor (3.10.0)` and the
  Windows-acceptance line is appended (plan § The release commit); that
  change is made in the release commit, outside this task document: leave
  it to the release commit.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-8. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-8 implemented, so
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
- On editing plugin files: the repository's CLAUDE.md says to edit the
  plugin's skill and agent files in a session started without
  `--plugin-dir`, because auto mode's classifier inside a `--plugin-dir`
  session gave no verdict on such edits. A headless session under
  `--permission-mode bypassPermissions` has no classifier, and four earlier
  batches' implementation sessions edited the plugin under `--plugin-dir`
  that way; Task 4 adds that sentence to CLAUDE.md. A session sees a
  plugin edit only in its next session, which is why the batch's review,
  acceptance, and fix run as separate sessions.
- The wait-path probe (Task 2): `ps -o args= -p $PPID` from the Bash tool
  is expected to print the claude process's command line — with `-p` or
  `--print` in a headless session and without in an interactive one. The
  implementing session can verify only the half it runs in; the
  acceptance verifies the other.
- After the last task, the batch's mechanical check is the release
  checklist's pre-flight block — the effort-override diff (unchanged), both
  `claude plugin validate --strict` runs, and
  `bash scripts/check-all.sh --self-test` with `guards run: 10` and
  `self-tests run: 9` — together with the zero-diff command in the
  Constraints, the pointer-label grep on the three plugin files, the
  canonical check, the driver self-test with its mutated stub, and the text
  checks of Tasks 4–8 (plan § Testing Strategy, mechanical 1–6, minus the
  `pwsh` half of 5). Acceptance of the live chain runs in a separate
  session (plan § Testing Strategy) and is filed as
  `docs/dry-runs/batch-f-acceptance.md`.
- The second round (plan Phase 3, M10): after the bash driver passes
  acceptance, `/kenspc-task` runs on the spec again and keeps only Step 3.1
  and its Doc-sync task as a second task document under a different file
  name; its `run.ps1` mirrors Task 1's `run.sh` (the same interface and
  files, `Start-Process pwsh` for the detached worker, the prompt read with
  `Get-Content -Raw`, a stub `claude.ps1` for `--self-test`), and its
  Doc-sync task brings the plugin README's Autopilot section, CLAUDE.md's
  layout tree, and the CHANGELOG's driver line up to date.
- The release commit (plan § The release commit) is not a task here: it
  moves `plugin.json` to 3.9.0, dates the CHANGELOG heading, retitles the
  roadmap's heading to `## Next minor (3.10.0)` and appends item 11
  (Windows acceptance of `run.ps1`), and `git rm`s
  `docs/briefs/autopilot-method.md`, `docs/plans/batch-f-autopilot.md`, and
  the task documents; no tag.
