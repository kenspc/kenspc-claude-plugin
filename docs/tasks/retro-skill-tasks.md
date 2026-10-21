# Retro Skill — Task Document

## Context

Add the eleventh kenspc skill, `retro`: a hand-started run over a window of
finished batches. It extracts findings and time with shipped python3
scripts, classifies findings with parallel agents, ranks recurring
problems, verifies each proposal against the raw records, applies the ones
the user adopts, and commits a record the next retro reads.

All plugin paths below are under `plugins/kenspc/`. The scripts run with
`python3 -I` on Python 3.9 or newer and use the standard library only.

External paths these tasks read:

- `~/Projects/_smoke/_analysis/review-time-20261019/` — the manual retro.
  It holds `findings.tsv`, `categories.tsv`, `rows.json`, and
  `followup/verify/` (`runmap.tsv`, `parse.py`, `sessions.py`).
- `~/Projects/Diagnohab/dayaku-crm` — the reference project, whose
  `.kenspc/runs/` holds 96 run directories.
- `~/Projects/_smoke/_logs/` — the autopilot workspace's logs.

Related plan: `docs/plans/retro-skill.md`

Dependency note:

- Tasks 1–4 build on each other in order.
- Task 5 depends on Task 4.
- Task 6 depends on Tasks 1–5.
- Tasks 7 and 8 are acceptance runs that depend on Task 6 and Task 7
  respectively.
- Task 9 depends on Tasks 1–8.

## Tasks

### Task 1: Findings extraction script and the retro scripts guard

**Status:** TODO

Create `plugins/kenspc/skills/retro/scripts/extract_findings.py <repo> <out>`.

**Inputs:**

- every `.kenspc/runs/*/schema-b.md` and its `angle-<n>.md`, in `<repo>`;
- the same files in every worktree `git -C <repo> worktree list` names.

**Parsing:**

- Split table rows on unescaped `|` only; `\|` inside a cell stays.
- Map columns from each table's header row, never by fixed index.
- Strip Markdown emphasis (`*`, `_`, backticks) from Severity and Action.
- Take the Action word before any `—`: FIXED, DEFERRED, or
  NOT APPLICABLE.
- Join each Schema B row to the angle row of its primary Source ID:
  - the first ID in Source; letter R=1, E=2, Q=3, B=4, T=5;
  - match the angle file's `#` column;
  - sources F and V have no angle row, and the row keeps `short_label` as
    its description.
- Recount each schema-b.md against its last-line stats line
  (`total reported … FIXED n, DEFERRED n, NOT APPLICABLE n …`).

**Outputs:**

- `<out>/findings.tsv`, columns: key (`<run>#<row>`), run, row, sources,
  severity, action, file, short_label, description.
- `<out>/extract.md`, which lists every anomaly: a recount mismatch, a row
  whose cell count differs from its header, a missing angle file, a Source
  ID with no angle row. It also lists the worktrees read.
- `rulings.md` is not parsed.

Use `followup/verify/parse.py` in the manual retro's directory as the
reference parser.

**The guard, `scripts/check-retro-scripts.sh`.** It runs the retro scripts
on fixtures and diffs each output against an expected file.

- Fixtures go under `scripts/fixtures/retro/`. This task adds:
  - a run directory whose angle row holds `\|`;
  - a schema-b row whose Action is `DEFERRED — ruled`;
  - a schema-b whose stats line disagrees with its rows by one;
  - a row sourced `F1`.
- `--self-test`: copy the scripts to a `mktemp -d` directory and replace
  the unescaped-pipe split with a plain split on `|`. The guard must then
  fail on the `\|` fixture. A mutation that does not apply exits 2.
- `python3` missing from PATH: exit 2 with a message, never 0, as
  `check-instruction-lint.sh` does for `pwsh`.
- The guard is bash, written for bash 3.2, per AGENTS.md § Guard scripts.
- Its header names what it checks, like the other guards.

Files to create:

- `plugins/kenspc/skills/retro/scripts/extract_findings.py`
- `scripts/check-retro-scripts.sh`
- `scripts/fixtures/retro/` — one fixture tree with its expected outputs;
  it counts as one fixture set, not as separate deliverables.

**Acceptance criteria:**

- `bash scripts/check-retro-scripts.sh` exits 0, and
  `bash scripts/check-retro-scripts.sh --self-test` exits 0, reporting
  that the pipe-split mutant failed.
- With `PATH` set so that `python3` is not found, the guard exits 2.
- `bash scripts/check-all.sh --self-test` passes and prints
  `guards run: 17` and `self-tests run: 16`.
- `python3 -I plugins/kenspc/skills/retro/scripts/extract_findings.py ~/Projects/Diagnohab/dayaku-crm <tmp>`,
  restricted to the 96 run ids `runmap.tsv` lists, gives:
  - 1005 rows;
  - FIXED 716, DEFERRED 256, NOT APPLICABLE 33;
  - no anomaly in `extract.md`.
- `bash scripts/check-no-model-names.sh` passes.
- The script runs under `/usr/bin/python3` (3.9.6 on the maintainer's Mac).

---

### Task 2: Run-to-batch mapping script with the window

**Status:** TODO

Depends on: Task 1

Create `plugins/kenspc/skills/retro/scripts/map_runs.py <repo> <workspace> <window> <out>`.

**Mapping.** For each run directory `extract_findings.py` reads:

1. **Candidates.** The role sessions whose wall window contains the run
   id's timestamp.
   - A session's window runs from its line
     `start <tag> pid <pid> session <id> at <YYYY-MM-DD HH:MM:SS> cwd <dir> …`
     in `<workspace>/_logs/<batch>-timeline.log` to the mtime of
     `<workspace>/_logs/<tag>.exit`.
   - With no `.exit`, the window is open-ended.
   - Timeline times are naive local time.
2. **Confirmation.** Among the candidates, the run id appears as a string
   in `<workspace>/_logs/<tag>.json` or a resume's `<tag>-r<k>.json`.
   - A candidate with no json at all is searched in its transcript,
     `<session id>.jsonl` under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/`.
   - One match gives the tag. The batch is the tag minus its last `-s…`
     part; the role is that part, with `-r<k>` removed.
   - Two or more matches, or none: role `manual`, batch = run id. Two or
     more matches are also listed in `extract.md` as an anomaly.

**Window:**

- `<window>` is `last <n>`, `since <YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS>`,
  or `all`.
- A batch is in the window when its earliest run's timestamp is in it.
- `last <n>` counts batches by their earliest run.
- `since <YYYY-MM-DDTHH:MM:SS>` takes batches whose earliest run is
  strictly after the timestamp. Why: the default window passes the previous
  record's last run timestamp, and an inclusive bound would count that
  record's last batch a second time when its earliest run is that run.
- `since <YYYY-MM-DD>` takes batches whose earliest run is on or after that
  date.

**Output:** `<out>/runs.tsv`, columns: run, batch, role, tag, session,
in_window. Anomalies are appended to `<out>/extract.md`.

Add guard cases and fixtures under `scripts/fixtures/retro/`:

- a run id named in two sessions' jsons, only one of whose windows contains
  it;
- a run whose only candidate session has no json, but its transcript names
  the run;
- a run with no candidate (expected `manual`);
- a window fixture for each of `last <n>`, `since`, and `all`;
- a batch whose earliest run equals the `since` timestamp (expected out of
  the window).

Files to create or modify:

- `plugins/kenspc/skills/retro/scripts/map_runs.py`
- `scripts/check-retro-scripts.sh` (new cases)
- `scripts/fixtures/retro/` (new fixtures and expected outputs)

**Acceptance criteria:**

- `bash scripts/check-retro-scripts.sh` and its `--self-test` exit 0, with
  the new cases.
- Run on dayaku-crm with `all`, every run `runmap.tsv` lists has:
  - the same batch as runmap, and the same role as runmap's role column
    (`s3`, `s3b`, `s3c`, `s3d`);
  - for the three runs runmap leaves unmapped (`-` in its batch and role
    columns): role `manual` and the run id as its batch.
- Run on dayaku-crm with `last 20`, exactly 20 distinct batches have
  `in_window` true.
- `bash scripts/check-all.sh` passes, `check-no-model-names.sh` included.

---

### Task 3: Time measurement and state-file notes scripts

**Status:** TODO

Depends on: Task 2

#### `measure_time.py <workspace> <runs.tsv> <out>`

Writes `<out>/time.tsv`, columns: batch, role, kind, minutes, status.

- **Sessions measured:** every role session with a `start` line in the
  timeline of each batch `runs.tsv` marks in-window, including roles that
  wrote no run directory (`s2`, `s4`, `s6`).
- **Role session wall minutes** run from the timeline `start <tag> … at`
  time to the mtime of `<tag>.exit`.
  - Resumes `<tag>-r<k>` are summed into their role.
  - `duration_ms` is never used.
  - No `.exit`: status `unmeasured`, minutes empty.
  - A session that ended on a usage limit (`.json` `is_error: true`) is
    measured to its `.exit` only. Its resume is its own start line.
- **Inside S3 and S3b roles,** one row per subagent kind.
  - Find the `*.meta.json` / `.jsonl` pairs under
    `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/<session id>/subagents/`.
  - The kind is `agentType`.
  - Each subagent's span runs from its first to its last transcript
    `timestamp`.
  - A kind's minutes are the union of its spans, never their sum.
  - Kind `other` is the session's wall minutes minus the union of all
    spans.
  - A session with no transcript directory gets status `unmeasured` for
    its split; its role row keeps its minutes.
- **Coverage.** Append a line to `<out>/extract.md`: sessions measured,
  sessions with an unmeasured split, sessions with no `.exit`. When no
  in-window batch has a timeline (a project without autopilot batches), the
  line says so and that the time list is empty.

#### `state_notes.py <workspace> <runs.tsv> <out>`

Writes `<out>/notes.tsv`, columns: batch, section, tag, text.

- Source: each in-window batch's `<workspace>/_logs/<batch>-state.md`.
- Sections copied:
  - `rail observations:`
  - `worker lessons:`
  - `questions answered:`
  - `skipped gates:`
  - the `merge danger:` line, with the path of
    `<workspace>/_logs/<batch>-merge-danger.md` when that file exists.
- A section the file lacks gets one row with text `absent`. Free-form lines
  outside these sections are ignored.

#### Guard cases and fixtures under `scripts/fixtures/retro/`

- an autopilot `_logs` with a timeline, `.exit` files, a resume, a
  usage-limit `.json`, and one session with no `.exit`;
- a transcript tree with two overlapping subagent spans of one kind;
- a session with no transcript directory;
- a state file in the old free-form shape: no `merge danger:` line, extra
  `Note:` lines.

Extend `--self-test` with a second mutant: replace the span union with a
sum. The overlap fixture must then fail.

Files to create or modify:

- `plugins/kenspc/skills/retro/scripts/measure_time.py`
- `plugins/kenspc/skills/retro/scripts/state_notes.py`
- `scripts/check-retro-scripts.sh` (new cases, second mutant)
- `scripts/fixtures/retro/` (new fixtures and expected outputs)

**Acceptance criteria:**

- `bash scripts/check-retro-scripts.sh` and its `--self-test` exit 0. The
  self-test reports both mutants (pipe split, span union) as failed.
- Run on dayaku-crm with window `all`, `measure_time.py`'s role wall
  minutes match `rows.json` within 1 minute for every batch and role
  `rows.json` lists.
- `state_notes.py` on `~/Projects/_smoke/_logs/ui-alignment-1-state.md`
  writes an `absent` row for `merge danger:` and no error.
- `bash scripts/check-all.sh` passes, `check-no-model-names.sh` included.

---

### Task 4: Slicing, ranking, and row-display scripts

**Status:** TODO

Depends on: Task 1-3

#### `slice_findings.py <retro dir> [<previous record>]`

Reads `findings.tsv` and `runs.tsv` from `<retro dir>`, in-window rows
only.

- **`sample.tsv`:** only when no previous record is given. Up to 200 rows,
  drawn from every in-window batch in proportion to its row count, with a
  fixed seed.
- **`slice-<n>.tsv`:** every in-window row, in run order, at most 120 rows
  each. The size is a module constant, `SLICE_ROWS = 120`, so Task 7 can
  lower it.
- **`kinds.tsv`:** given a previous record, copied from that record's
  `## Kinds` table.

#### `rank.py <retro dir> [<previous record>]`

**Inputs:**

- `labels-<n>.tsv` (key, kind);
- `findings.tsv`, `runs.tsv`, `time.tsv`;
- `new-kinds.tsv` (name, kind or `other`) when present.

`new:` labels resolve through `new-kinds.tsv`. A `new:` name it does not
list stays as its own kind, and `rank.md` lists it with its batches.

**De-duplication:**

- Within one batch, an `s3b` row counts once when the same batch's `s3`
  has a DEFERRED row with the same file (path without `:line`) and the same
  kind.
- `rank.md` lists every merge as a key pair.

**Findings list:**

- kinds in at least two batches;
- cost = HIGH 3 / MEDIUM 2 / LOW 1 over de-duplicated rows;
- `other` never ranked.

**Time list:**

- `time.tsv` roles and S3/S3b subagent kinds in at least two batches;
- cost = total minutes;
- the share of all measured batch time shown beside it.

**Selection:**

- Up to 3 findings items and up to 2 time items.
- A list with fewer candidates passes its unused slots to the other, for
  at most 5 in all.

**Runner-up:** a list's next candidate within 10% of that list's last
selected cost is printed as a runner-up.

**Marks and keys:**

- Every ranked item whose batches include a `manual` run is marked.
- Every ranked item lists its record keys.

**With a previous record:**

- Print each adopted item's measure then (from the record) and now.
- Mark each ranked kind (or time role or kind) the record rejected, with
  its batch count then and now.
- A rejected item whose count has not grown is skipped, and its slot
  passes on.
- Pending and failed items are not marked.

**Output:** `<retro dir>/rank.md`.

#### `show_rows.py <retro dir> <key>…`

Prints each named finding's full row from `findings.tsv`.

#### The record lines the scripts parse

Fix them here in a fixture record, `scripts/fixtures/retro/record.md`.
Task 6 writes the record grammar in SKILL.md to match it exactly. The lines
are:

- the Window line, holding the first and last run timestamps;
- the `## Kinds` table (kind, definition);
- each adopted item's measure line (the measure's name and its value);
- each rejected item's kind (or time role or kind) and batch count.

Guard cases and fixtures:

- an S3/S3b duplicate pair, plus a same-file pair of different kinds that
  must not merge;
- a kind in one batch only (not ranked);
- fewer than 3 findings candidates (the slot passes to time);
- a near-tie within 10% (runner-up printed);
- a `new:` label with and without a `new-kinds.tsv` entry;
- the fixture record: an adopted measure, a rejected kind whose count has
  grown and one whose count has not.

Files to create or modify:

- `plugins/kenspc/skills/retro/scripts/slice_findings.py`
- `plugins/kenspc/skills/retro/scripts/rank.py`
- `plugins/kenspc/skills/retro/scripts/show_rows.py`
- `scripts/check-retro-scripts.sh` (new cases)
- `scripts/fixtures/retro/` (new fixtures, `record.md`, expected outputs)

**Acceptance criteria:**

- `bash scripts/check-retro-scripts.sh` and its `--self-test` exit 0, with
  each case above asserting its stated outcome.
- In a run over the fixture record, the rejected kind whose batch count
  has not grown does not appear among the selected items, and the one
  whose count has grown does.
- `bash scripts/check-all.sh` passes, `check-no-model-names.sh` included.

---

### Task 5: The classifier and verifier agents

**Status:** TODO

Depends on: Task 4

Create two INTERNAL agents, shaped like
`plugins/kenspc/agents/plan-document-reviewer.md`. Each has:

- frontmatter `name`, a `description` whose first sentence starts
  `INTERNAL:`, `tools`, `model: inherit`, and no `effort:`;
- a PREREQUISITE CHECK that refuses when any CONTEXT key is missing;
- CONTEXT YOU WILL RECEIVE listing exactly its keys;
- rules written as Why-prose (AGENTS.md § Editing skill and agent content).

#### `plugins/kenspc/agents/retro-classifier.md`

- `tools: Read, Write, Grep, Glob`.
- Keys: `RETRO_DIR`, `MODE` (`derive` | `classify`), `INPUT`, `KINDS`,
  `OUTPUT`.
- **`derive` mode** (`INPUT` `sample.tsv`, `KINDS` `none`, `OUTPUT`
  `kinds.tsv`): writes 15–30 kinds plus `other`. Each kind gets a
  one-sentence definition naming which kind wins where two could be
  confused. A kind is a recurring problem a rule, check, or document could
  prevent, never a file or module.
- **`classify` mode** (`INPUT` one `slice-<n>.tsv`, `KINDS` `kinds.tsv`,
  `OUTPUT` `labels-<n>.tsv`): writes one row per input row, columns key and
  kind. It uses `other` only when no kind fits, and `new:<name>` sparingly.
- It reads nothing but `INPUT` and `KINDS`, and writes only `OUTPUT`.
  - Why, in the agent's own words (AGENTS.md § Editing skill and agent
    content: evidence is stated, not cited as a record, since the user's
    project has neither this repository's brief nor its prototype commit):
    slices classified by separate dispatches ranked the same top kinds
    because no dispatch saw another's labels; a dispatch that read other
    slices' files would couple them and void that stability.

#### `plugins/kenspc/agents/retro-verifier.md`

- `tools: Read, Bash, Grep, Glob` (read-only).
- Keys: `RETRO_DIR`, `PROPOSAL` (the path of one `proposal-<n>.md`),
  `PROJECT_PATH`, `WORKSPACE`.
- **What it does:**
  - re-reads the cited raw lines in the run directories, `rulings.md`, and
    `<WORKSPACE>/_logs`, not the extracted tables;
  - recounts the cited counts;
  - tests the stated cause;
  - checks whether a cited "two batches" is one piece of work (a `manual`
    run re-reviewing an autopilot batch);
  - computes the expected effect's ceiling from the window's numbers.
- **What it returns:**
  - `HOLDS`;
  - `ADJUSTED`, with corrected numbers and an effect cut to its ceiling;
  - or `FAILS`, with the record line that breaks the premise.
- It writes nothing.
  - Why, in the agent's own words (same rule): in a retro done by hand, two
    proposals rested on wrong premises — an expected saving of about 50%
    that the records capped at 3%, and a stated cause the records
    contradicted — and only re-reading the raw records caught them; an
    agent that could edit could also make the records fit.

Files to create:

- `plugins/kenspc/agents/retro-classifier.md`
- `plugins/kenspc/agents/retro-verifier.md`

**Acceptance criteria:**

- From this repository, run
  `claude -p --plugin-dir ./plugins/kenspc "<prompt>"`, where the prompt
  dispatches each agent once with a CONTEXT block that lacks `RETRO_DIR`.
  Each agent's reply refuses on its prerequisite check and names the
  missing key.
  - Why `--plugin-dir`: a plain session runs the installed plugin, which
    has no retro agents.
- Any use of the term "instruction files" in either file carries the
  definition sentence of `plugins/kenspc/shared/instruction-files.md`
  verbatim.
- `bash scripts/check-all.sh` passes.

---

### Task 6: The retro SKILL.md and the /kenspc-retro command

**Status:** TODO

Depends on: Task 1-5

Create `plugins/kenspc/skills/retro/SKILL.md`, frontmatter:

- `name: retro`;
- a description that names the trigger as `/kenspc-retro` only;
- `disable-model-invocation: true`;
- `version: 3.0.0`.

**Prerequisites:**

- A top-level-session bullet, worded like task-review's. Why: the skill
  dispatches agents.
- python3 3.9 or newer, or the skill stops and says so.

**Scope of reads and writes:**

- The main session reads only `extract.md`, `rank.md`, the proposal files,
  and rows it asks `show_rows.py` to print by key; it never opens raw
  reports. Why: a window of about a thousand findings does not fit in the
  session's context.
- The skill writes nothing outside the project repository. Inside it, it
  writes only `RETRO_DIR`, the files of adopted proposals, and the record.

Then the plan's phases, in its terms (plan § Technical Approach).

**Phase 0 — Locate:**

- create `RETRO_DIR` = `.kenspc/retros/<YYYYMMDD-HHMMSS>/`; its file
  names follow the naming rule in the Scratch space bullet of the
  `canonical:run-dir` block, pointed to by its markers in
  `plugins/kenspc/skills/task-review/SKILL.md`, not copied (AGENTS.md
  § Skills: written once and referenced);
- find the newest record under `docs/retros/` (the one whose Window line
  ends latest);
- fix the window spec from the argument, or the default `since` the newest
  record's last run timestamp, else `last 20`;
- resolve the workspace: `Workspace: <dir>`, else `~/Projects/_smoke/`.

**Phase 1 — Extract:**

- run the scripts in order: `extract_findings.py`, `map_runs.py`,
  `measure_time.py`, `state_notes.py`, `slice_findings.py`;
- address each as `${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/<name>.py`;
- the window question comes after `map_runs.py`, with no window argument:
  it states the window's batch count and first and last dates and asks
  whether to run it or name another; a window the user names re-runs
  `map_runs.py` with it;
- a window with fewer than two batches stops with the counts.

**Phase 2 — Classify:**

- one `derive` dispatch when there is no record;
- one `classify` dispatch per slice, sent together;
- every dispatch with `run_in_background: false`;
- CONTEXT blocks with exactly `retro-classifier`'s keys.

**Phase 3 — Rank and draft:**

- run `rank.py`;
- resolve `new:` names into `new-kinds.tsv` and run `rank.py` again:
  first merge names that different slices gave the same new kind; a name
  used in at least two batches becomes a kind, any other goes to `other`;
  the labels files are never edited;
- for each selected item, draft `proposal-<n>.md` with these fields:
  - where it went wrong: record keys and counts;
  - the file and layer it changes, and why that layer;
  - what changes in the next batch;
  - how to undo it;
  - the measure the next retro reads (a kind's de-duplicated cost or a
    role's minutes per batch) and its current value;
  - the expected effect;
- split a kind by concrete cause and draft only for the largest cause group
  spanning at least two batches;
- a time item needs a record-backed cause in two batches;
- the layer order is the project's own rule, else the default six-layer
  order;
- the landing place is a project file (applied after approval), the kenspc
  plugin (a brief-shaped section in the record, for a separate session to
  take to `/kenspc-plan`), or the user's global files (a suggestion in
  words in the record);
- in the kenspc repository itself, plugin files are project files.

**Phase 4 — Verify:**

- one `retro-verifier` dispatch per proposal, together, with exactly its
  keys;
- `FAILS` is not shown; `ADJUSTED` is shown with corrected numbers.

**Phase 5 — Decide, apply, record:**

- **Deciding:** one question per proposal (adopt, or reject with a reason).
- **Applying:**
  - run the project's check commands, as its instruction files or config
    files define them (read, never assumed from a stack), before each
    adopted proposal's commit; a project that defines none gets the
    record line `no check commands defined`;
  - one commit per adopted project-file proposal, staging only its files;
  - default subject `chore(retro): <summary>`;
  - its undo, `git revert <hash>`, goes into the record.
- **On a failed check or a rejected commit:**
  - restore the proposal's files from HEAD
    (`git restore --staged --worktree` on the files it names that HEAD has)
    and remove any file it created;
  - record the proposal as `failed`, with the failing check's or hook's
    output lines;
  - ask whether to go on to the next proposal or stop.
- **The record:** `docs/retros/<YYYY-MM-DD>.md`, written and committed
  last, default subject `docs(retro): record <date> retro`. A second record
  on one date gets a `-<n>` suffix (`2026-10-21-2.md`).
- Commit subjects are adapted to the repository's convention. The SKILL.md
  says where that convention is found: the one its instruction files or
  CONTRIBUTING write down, or else the pattern its recent commit subjects
  consistently share (AGENTS.md § Editing skill and agent content).

**The record grammar,** written once here. Its sections:

- Window and coverage: a Window line with the first and last run
  timestamps in the window, the coverage counts from `extract.md`, and the
  worktrees read;
- Follow-up: each previous adopted item, its measure then and now;
- Kinds: a table of kind and definition;
- Adopted: all proposal fields, the commit hash, and the undo;
- Rejected: the proposal fields and the user's reason;
- Dropped by verification: the reason;
- Pending: all proposal fields;
- Failed: the proposal fields and the failing check's or hook's lines;
- Runner-ups;
- For the kenspc plugin;
- For your global files.

The lines the scripts parse match `scripts/fixtures/retro/record.md` from
Task 4 exactly.

**Rules about earlier proposals:**

- A rejected item is not proposed again unless its batch count grew.
- Pending and failed items are proposed again when they still pass the bar,
  and get no Follow-up line, since nothing changed.

**Every stop where the skill asks** opens its no-ask branch with "In a
session that cannot ask (a system reminder to work without stopping), …".
The stops:

- the window question: the default window is used;
- each proposal decision: recorded `pending`, no project file changes;
- a rejected record commit: stop with the hook's message, the record left
  uncommitted.

Wherever the SKILL.md uses the term "instruction files", it carries the
definition sentence of `plugins/kenspc/shared/instruction-files.md`
verbatim.

Create `plugins/kenspc/commands/kenspc-retro.md` in the shape of
`plugins/kenspc/commands/kenspc-brief.md`:

- a one-line description;
- `argument-hint: [last <n> | since <date> | all] [Workspace: <dir>]`;
- `disable-model-invocation: true`;
- a body that reads `${CLAUDE_PLUGIN_ROOT}/skills/retro/SKILL.md` and
  passes `$ARGUMENTS`.

Files to create:

- `plugins/kenspc/skills/retro/SKILL.md`
- `plugins/kenspc/commands/kenspc-retro.md`

**Acceptance criteria:**

- Each CONTEXT block in SKILL.md lists exactly the keys its agent's
  CONTEXT YOU WILL RECEIVE declares.
- Joining SKILL.md's lines and searching for
  "In a session that cannot ask (a system reminder to work without stopping)"
  finds one sentence at each of the three stops above.
- Every record line `rank.py` and `slice_findings.py` parse is specified in
  the grammar exactly as in `scripts/fixtures/retro/record.md`.
- `claude plugin validate --strict ./plugins/kenspc` passes.
- `bash scripts/check-all.sh` passes, including `check-instruction-files.sh`
  and `check-no-model-names.sh`.

---

### Task 7: Stability re-check at the shipped slice size

**Status:** TODO

Depends on: Task 6

Re-run the prototype's stability check (brief entry 1, prototype
`78e797e`) at 120-row slices. A task-implementer subagent cannot dispatch
agents, so drive the run from a headless top-level session:
`claude -p --plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc "<prompt>"`.
Run it in a scratch directory under `~/Projects/_smoke/retro-stability/`,
outside this repository.

The run outlasts one Bash call, which the tool caps at 10 minutes, so
start the session detached and wait on it in bounded steps:
`(nohup claude -p --output-format json … < /dev/null > <log> 2>&1 & echo $! > <pid file>)`,
then repeat `timeout 570 caffeinate -w <pid>` until `ps -p <pid>` finds no
process. Keep the log and the pid file in the scratch directory; the log's
json holds the session id and the result.

The prompt has the session do these steps:

1. Run `extract_findings.py`, `map_runs.py` (window `last 20`) and
   `slice_findings.py` on `~/Projects/Diagnohab/dayaku-crm`, with the
   outputs in the scratch directory.
2. Make one `retro-classifier` `derive` dispatch.
3. **Run A:** one `classify` dispatch per `slice-<n>.tsv`.
4. **Run B:** the same in-window rows, shuffled with a fixed seed into a
   scratch copy and cut into 120-row slices. One fresh `classify` dispatch
   per slice, same `kinds.tsv`.
5. **Compare.** Extract `rank.py` with
   `git -C /Users/kenspc/Projects/KENSPC/claude-plugin show 78e797e:prototypes/finding-classification/rank.py`.
   Run it on a directory holding:
   - run A's labels as `labels-A-<n>.tsv` and run B's as
     `labels-B-<n>.tsv`;
   - `window.tsv` (key, batch, severity), from `findings.tsv` joined to
     `runs.tsv`;
   - `manual.tsv` (key, kind), from the manual retro's `categories.tsv`.

Record the run in `docs/dry-runs/retro-stability.md`. The label
convention in `docs/dry-runs/README.md` governs per-hunk reviewer
evaluations and does not apply here: quote `rank.py`'s verdict lines as it
prints them. Include:

- the command;
- the top-five tables;
- the verdict lines;
- the per-row agreement;
- the subagent token cost.

Do not include any finding's description text, since this repository is
public. Kind names and counts only.

On FAIL:

1. Set `SLICE_ROWS = 60` in `slice_findings.py`, change every mention of
   the 120-row slice size in `plugins/kenspc/skills/retro/SKILL.md` to 60,
   and repeat once. `bash scripts/check-all.sh` passes before that change
   is committed (AGENTS.md § Checks).
2. A second FAIL stops the task as BLOCKED, with both runs' verdict lines
   in its Implementation notes, for the user's ruling.

Remove the scratch directory when the run ends.

Files to create or modify:

- `docs/dry-runs/retro-stability.md`
- `plugins/kenspc/skills/retro/scripts/slice_findings.py` and
  `plugins/kenspc/skills/retro/SKILL.md` (on a first FAIL only)

**Acceptance criteria:**

- `docs/dry-runs/retro-stability.md` shows:
  - a top-five overlap of at least 4 of 5;
  - a row overlap of at least 60% for every shared kind;
  - PASS.
- The dry-run file holds no finding description text: kind names, counts,
  and verdict lines only.
- `~/Projects/_smoke/retro-stability/` no longer exists.

---

### Task 8: End-to-end acceptance on a dayaku-crm clone

**Status:** TODO

Depends on: Task 7

**Setup:**

- Clone dayaku-crm to `~/Projects/_smoke/retro-accept/`.
- Replace the clone's `.kenspc/runs` with a symlink to
  `~/Projects/Diagnohab/dayaku-crm/.kenspc/runs`. The real one is 56 GB,
  used read-only.
- Install the clone's dependencies with the commands dayaku-crm's
  instruction files name.
- Record, before the run:
  - `git -C ~/Projects/Diagnohab/dayaku-crm status --porcelain`;
  - the clone's `git rev-parse HEAD`;
  - the number of run directories in
    `~/Projects/Diagnohab/dayaku-crm/.kenspc/runs/`.

**First run.** Drive the retro with a headless session in the clone:
`claude -p --output-format json --plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc "/kenspc-retro"`.
Answer each question the session ends a turn on with
`claude -p --output-format json --resume <session id> "<reply>"`. Start
each call detached and wait on it as Task 7 describes, with its log and pid
file in your scratch directory; each log's json gives the session id for
the next `--resume`. The replies:

- the window question: "run the default window";
- the first proposal: "adopt";
- the second proposal: "reject: acceptance-test rejection";
- any further proposal: "reject: acceptance-test rejection".

If the first run's session takes the cannot-ask branch instead of asking
(its record lists every proposal as `pending`), the scripted replies cannot
reach it. Mark this task BLOCKED, naming that plan Step 5 calls for an
interactive run in which the maintainer decides, and leave the clone in
place with its path in the `- Blocked:` line. Do the same, with the count,
when the first run puts fewer than two proposals to the user, since the
second run's follow-up check needs an adopted item and its no-repeat check
a rejected one.

**Second run:** `/kenspc-retro last 20`, driven the same way. The window
argument means no window question is asked; reject every proposal.

Record both runs in `docs/dry-runs/retro-acceptance.md`, with:

- the commands;
- the session ids;
- each question and reply;
- `git -C ~/Projects/_smoke/retro-accept log --oneline <setup HEAD>..HEAD`
  after each run; the range keeps dayaku-crm's own history, a private
  project's, out of this public repository;
- the record file's section headings;
- the cost.

Include no finding description text.

Remove the clone when the record is written. First remove the
`.kenspc/runs` symlink itself (its path with no trailing slash) and confirm
the real directory still holds the number of run directories recorded at
setup; then remove the clone.

Files to create:

- `docs/dry-runs/retro-acceptance.md`

**Acceptance criteria:**

- After the first run, the clone has one commit per adopted proposal and
  then one record commit.
- The record holds every section of the Task 6 grammar.
- After the first run, `extract.md` in the run's `RETRO_DIR` carries the
  coverage line.
- `git -C ~/Projects/Diagnohab/dayaku-crm status --porcelain` is the same
  before and after both runs.
- The second run's Follow-up section shows the adopted item's measure then
  and now.
- The second run's proposals do not include the first run's rejected
  item.
- `~/Projects/_smoke/retro-accept/` no longer exists, and
  `~/Projects/Diagnohab/dayaku-crm/.kenspc/runs/` still holds the number of
  run directories recorded at setup.

---

### Task 9: Doc-sync

**Status:** TODO

Depends on: Task 1-8

Bring the documents below in line with what Tasks 1-8 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):

- `README.md` § skills table, commands line — add retro and
  `/kenspc-retro`; "11 reusable subagents" → 13 (plan Steps 2–3).
- `plugins/kenspc/README.md` (plan Steps 2–3):
  - skills, commands, and `/kenspc:<skill>` lists;
  - the sentence that skills activate automatically gains the retro
    exception;
  - "11 reusable subagents" → 13;
  - agents table and INTERNAL note;
  - a retro section on `docs/retros/`, `.kenspc/retros/`, python3, and the
    record;
  - Run directory gains `.kenspc/retros/`;
  - Requirements gains `python3` 3.9 or newer for `/kenspc-retro`, beside
    the autopilot's own requirement line.
- `AGENTS.md` (plan Steps 2–3):
  - project overview lists retro;
  - Orchestration patterns gain "Parallel classification, then
    verification: retro";
  - "six others are orchestration-only" → eight;
  - "3.0.0 in all ten skills" → eleven (both mentions);
  - the record grammar joins the "Written once" list.

  The file is at 199 of its 200-line budget, so these merge into existing
  lines with no net growth.
- `plugins/kenspc/.claude-plugin/plugin.json` — the description names
  retro; "eleven reusable subagents" → thirteen. The version is not changed
  (plan Steps 2–3).
- `.claude-plugin/marketplace.json` — the top-level description gains
  retro. The plugin-entry summary is left alone, per AGENTS.md (plan
  Step 3).
- `plugins/kenspc/CHANGELOG.md` — `## 4.14.0 — unreleased`, `### Added`:
  the skill, the command, the two agents, the scripts, the guard (plan
  Steps 1–3).
- `docs/release-checklist.md` (plan Steps 1, 3):
  - row 1's command count 10 → 11;
  - the pinned counts `guards run: 16` / `self-tests run: 15` → 17 / 16;
  - a new smoke row for `/kenspc-retro` before the end-to-end row, with
    later rows and every reference to their numbers renumbered. The row is
    a headless run in a session that cannot ask, `last 3`, on a dayaku-crm
    clone set up as in Task 8. Pass: the record lists every verified
    proposal as `pending`, and no project file outside `docs/retros/`
    changed;
  - the effort diff is unchanged.
- `docs/roadmap.md` (plan Step 6):
  - two items planned: the autopilot final-report line on batches since
    the last retro, and run-directory ids in the state file;
  - item 9's two mentions of smoke row 13 → row 14.

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
- `bash scripts/check-all.sh --self-test` passes, including
  `check-instruction-lint.sh` with AGENTS.md within its 200-line budget.
- `claude plugin validate --strict .` passes.
