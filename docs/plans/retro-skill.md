# Plan: Retro skill (kenspc 4.14.0)

Source brief: `docs/briefs/retro-skill.md`.

## Objective

Add an eleventh kenspc skill, `retro`, started only by hand. A run covers a
window of finished batches and does five things:

1. measures where they went wrong and where they spent time;
2. proposes at most five changes to the project's environment;
3. has each proposal verified against the raw records before the user sees
   it;
4. applies the proposals the user approves;
5. commits a record. The next retro starts by checking that record.

**In scope:**

- the skill;
- its command;
- its shipped python3 extraction scripts;
- two new INTERNAL agents;
- a guard with a self-test fixture;
- the documentation that names skills and agents.

**Out of scope:**

- Editing kenspc plugin files or the user's global files from a retro run.
  Both are output only, except that plugin files are project files when the
  project is the kenspc repository itself (see Proposals).
- A line in the autopilot's final report about retro timing.
- Recording run-directory ids in the autopilot state file.
- Transcript-wide tool-economy analysis.

The last three are deferred by the brief.

## Background

- **The manual retro this skill replaces.** The retro of 2026-10-19/20 was
  done by hand: scripts written for one project, then a separate
  verification session. It produced kenspc 4.11.0, 4.12.0 and 4.12.1, and
  two of its premises were wrong until verified.
- **The brief** settles scope, landing places, the bar, verification order,
  the record, the trigger, and the window.
- **The prototype** settled one design question: whether findings
  classified in slices by separate subagents rank stably.
  - Brief entry 1 is `answered`. Prototype `78e797e`
    (`git show 78e797e`).
  - Two independent runs over 365 dayaku-crm findings ranked the same top
    five kinds.
  - Per kind, the rows the two runs put in it overlapped by 71–92%.
  - It also showed two limits:
    - a near-tie at the cut;
    - kinds coarser than one change.

  This plan answers both limits in the Technical Approach.

## Technical Approach

### Shape of a run

The skill has six phases. Scripts do every mechanical step; the model does
every judgement.

| Phase | Who | Output (under `RETRO_DIR`) |
|---|---|---|
| 0 Locate | main session | `retro-dir` created, previous record found, window spec fixed (the argument, or the default) |
| 1 Extract | scripts | `findings.tsv`, `runs.tsv` (with the window applied), `time.tsv`, `notes.tsv`, `extract.md` (anomalies, coverage), then `sample.tsv`, `slice-<n>.tsv`, and `kinds.tsv` when a previous record exists |
| 2 Classify | `retro-classifier` agents, parallel | `kinds.tsv` (first retro only), `labels-<n>.tsv` |
| 3 Rank and draft | script, then main session | `rank.md`, `proposal-<n>.md` |
| 4 Verify | `retro-verifier` agents, parallel | verdict per proposal, in each agent's reply |
| 5 Decide, apply, record | main session with the user | one commit per adopted project-file proposal, then the record commit |

- **Where the working files go.** `RETRO_DIR` is
  `.kenspc/retros/<YYYYMMDD-HHMMSS>/`.
  - It sits beside `.kenspc/runs/`, so it is git-ignored like the run
    directories.
  - It is deliberately not under `runs/`, so a later retro's extraction
    never reads it as a run.
  - Scratch file names follow the `canonical:run-dir` naming rule (no name
    a test runner collects).
- **What the main session reads.** Only `extract.md`, `rank.md`, the
  proposal files, and rows it asks a script to print by key. It never reads
  raw reports. Why: the brief's cost constraint, and 1005 findings would not
  fit.

### Evidence and the scripts

The scripts live in `skills/retro/scripts/`, run with `python3 -I`, and use
the standard library only. Python, because the inputs are Markdown tables
with escaped pipes and JSONL transcripts. In bash 3.2 and awk, plus a
PowerShell twin, that parsing is where the manual retro went wrong. If
`python3` is missing, the skill stops and says so; it does not fall back.
The scripts run on Python 3.9 or newer. Why: `/usr/bin/python3` on macOS is
3.9.6, so syntax added after 3.9 (`match`, `X | Y` type unions evaluated at
run time) would fail on the maintainer's own machine.

#### `extract_findings.py <repo> <out>`

- **Input:** every `.kenspc/runs/*/schema-b.md` and its `angle-<n>.md`, in
  the repository and in each worktree `git -C <repo> worktree list` names.
  Why: a worktree batch writes its run directories in the worktree, and they
  leave with it unless copied back.
- **Parsing:**
  - split on unescaped `|` only;
  - map columns from the header row, not fixed indexes;
  - strip Markdown emphasis from Severity and Action;
  - take the Action word before any `—`.
- **Recount:** every file is recounted against its stats line. A mismatch
  goes to `extract.md` as an anomaly and is never silently dropped.
- **Description:** joined through the primary Source ID to the matching
  angle row (R=1, E=2, Q=3, B=4, T=5). Sources F and V have no angle row
  and keep `short_label` as their description.
- **`rulings.md` is not parsed.** A ruling already shows in Schema B's
  Action (`— ruled`), which is all ranking needs. The verifier reads
  `rulings.md` as a raw record when a proposal's cause rests on a ruling.
- **Output columns:** key, run, row, sources, severity, action, file,
  short_label, description.

#### `map_runs.py <repo> <workspace> <window> <out>`

Maps each run directory to a batch and a role, and marks it in or out of
the window.

- **Autopilot runs:** two conditions together.
  1. The candidates are the role sessions whose wall window contains the
     run id's timestamp. A session's window runs from its timeline line
     `start <tag> pid <pid> session <id> at <time> cwd <dir> …` in
     `<workspace>/_logs/<batch>-timeline.log` to the mtime of
     `<workspace>/_logs/<tag>.exit`, open-ended when that file is missing.
  2. Among the candidates, the run id appears as a string in the session's
     `<workspace>/_logs/<tag>.json` or a resume's `<tag>-r<k>.json`. A
     candidate with no json at all (a dead worker writes none) is searched
     in its transcript instead, `<session id>.jsonl` under
     `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/`.

  One match gives the tag; the tag gives the batch and the role. Two or
  more matches are treated as no match (below), and the run is listed in
  `extract.md` as an anomaly.
  - Why this rule: nothing inside a run directory names its batch. The
    run-id suffix is not the role: two `-tasks` runs were S3b and three
    `-changes` runs were manual. A json search alone is ambiguous: on
    dayaku-crm, seven run ids appear in two or three jsons, a later role of
    the same batch (`-s3c`, `-s3b`, a resume) or a non-batch replay session.
    The window plus the json mention is how the manual retro's verification
    mapped them correctly (`followup/verify/sessions.py` in the manual
    retro's directory, ~/Projects/_smoke/_analysis/review-time-20261019/). Neither condition
    depends on the project's path, so worktree batches match too.
- **Runs with no match** are role `manual`, each its own batch keyed by run
  id. A manual re-review of an autopilot batch's code therefore counts as a
  second batch. `rank.md` marks every ranked item whose batches include a
  manual run, so drafting and verification can see when "two batches" is
  one piece of work.
- **Time window:** taken from the run id's timestamp. `<window>` is the
  spec Phase 0 fixed (`last <n>`, `since <date or timestamp>`, or `all`;
  the default window is `since` the previous record's last run timestamp);
  a batch is
  in the window when its earliest run is. `runs.tsv` carries an `in_window`
  column, and every later script reads only in-window rows. Why: `last <n>`
  counts batches, which exist only once runs are mapped, so the window
  cannot be applied before this script.

#### `measure_time.py <workspace> <runs.tsv> <out>`

- **Wall time per role session:** from the timeline's
  `start <tag> … at <time>` line to the mtime of `<tag>.exit`. Resumes
  (`<tag>-r<k>`) are summed into their role.
  - It never uses `duration_ms`. One S3 read 83 min in `duration_ms`
    against 3.5 h on the clock.
- **Inside S3 and S3b:**
  - each subagent kind's span is the union of the first-to-last transcript
    timestamps of its `subagents/*.meta.json`/`.jsonl` pairs, found under
    `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/*/<session id>/subagents/`;
  - spans are united, never summed;
  - "other" is the session's wall time minus the union of all spans.
- **Coverage:** a session whose transcripts are gone (Claude Code prunes
  old transcripts) keeps its role time. Its subagent split becomes
  `unmeasured`, counted in `extract.md`'s coverage line, never as zero.
- **Usage-limit exits:** a session that ended on a usage limit is measured
  only to its `.exit`. The resume is its own start line, so the pause
  between them is never counted.
- **No `.exit`:** a session with a start line but no `<tag>.exit` has no
  end on the clock. Its wall time is `unmeasured`, counted in `extract.md`'s
  coverage line, never estimated.

#### `state_notes.py <workspace> <runs.tsv> <out>`

Copies these sections of each batch's state file,
`<workspace>/_logs/<batch>-state.md`, into `notes.tsv` (batch, section,
tag, text):

- `rail observations:`
- `worker lessons:`
- `questions answered:`
- `skipped gates:`
- the `merge danger:` line, with its `_logs/<batch>-merge-danger.md` file
  when it exists.

These are context for drafting a cause. They are not ranked. Older state
files lack some lines and carry free-form lines; missing sections are
recorded as absent, not as an error.

#### `slice_findings.py <retro dir> [<previous record>]`

Prepares the classifier inputs from the in-window rows of `findings.tsv`.

- `sample.tsv`: up to 200 rows for the `derive` dispatch, drawn from every
  in-window batch in proportion to its row count. Written only when there is
  no previous record.
- `slice-<n>.tsv`: every in-window row, in run order, cut into slices of at
  most 120 rows.
- `kinds.tsv`: given a previous record, copied from its Kinds table.

#### `rank.py <retro dir> [<previous record>]`

- **Inputs:** the labels, `findings.tsv`, `runs.tsv`, `time.tsv`, and
  `new-kinds.tsv` when the main session has written it.
- **Mechanical de-duplication:** within one batch, an S3b row counts once
  if the same batch's S3 has a DEFERRED row with the same file (path
  without line) and the same kind. The rule merges rarely and can be
  checked by hand. It can merge two different problems that share a file
  and a kind; `rank.md` lists every merge, so the drafting step sees them.
- **Findings list:**
  - kinds present in at least two batches;
  - cost = HIGH 3 / MEDIUM 2 / LOW 1 over de-duplicated rows;
  - `other` is never ranked.
- **Time list:**
  - role sessions and S3/S3b subagent kinds present in at least two
    batches;
  - cost = total wall minutes in the window, with the share of all batch
    time beside it.
- **Selection:** at most five items across the two lists. Up to three come
  from findings and up to two from time; a list with fewer candidates
  passes its slots to the other.
  - Why 3+2: the brief caps the total at five and the user chose separate
    lists. Time items are fewer and each costs more to verify, because
    their cause is read from transcripts.
- **Runner-up:** when the next candidate in a list is within 10% of the
  last selected item's cost, `rank.md` names it as a runner-up with its
  numbers. No proposal is drafted for it.
  - Why: the prototype's ranks 4 and 5 swapped between runs at costs
    38/37 against 36/36. A near-tie at the cut is a coin toss the user
    should see rather than have hidden.
- **Also printed:** for every ranked item, the record keys that make it up.
- **Previous record:** given one, `rank.py` computes each adopted
  proposal's measure in the new window, so the follow-up check reads
  numbers, not impressions. It also marks each ranked kind the record
  rejected, with the batch count then and now, so the no-repeat rule is
  applied from numbers; a marked kind whose count has not grown is skipped
  and its slot passes on.

#### `show_rows.py <retro dir> <key>…`

Prints chosen findings in full, so the main session cites lines without
opening reports.

### Classification

- **New INTERNAL agent `retro-classifier`:**
  - `tools: Read, Write, Grep, Glob`, `model: inherit`, no `effort:`;
  - CONTEXT keys `RETRO_DIR`, `MODE` (`derive` | `classify`), `INPUT`,
    `KINDS`, `OUTPUT`. In `derive` mode `INPUT` is `sample.tsv`, `KINDS` is
    `none`, and `OUTPUT` is `kinds.tsv`; in `classify` mode `INPUT` is one
    `slice-<n>.tsv`, `KINDS` is `kinds.tsv`, and `OUTPUT` is
    `labels-<n>.tsv` (columns key, kind);
  - writes only its `OUTPUT` under `RETRO_DIR`.
- **First retro of a project** (no record under `docs/retros/`): one
  `derive` dispatch reads a stratified sample of up to 200 findings from
  the window's batches. It writes `kinds.tsv`: 15–30 kinds plus `other`,
  each with a one-sentence definition that says which kind wins where two
  could be confused.
- **Later retros:** `slice_findings.py` copies `kinds.tsv` from the
  previous record's Kinds table.
- **Classifying:**
  - findings are cut into slices of at most 120 rows and classified in
    parallel, one dispatch per slice, `run_in_background: false`;
  - a slice may label a row `new:<name>` when no kind fits;
  - the main session adds such a name to the kinds only when it was used
    in at least two batches; otherwise its rows become `other`. `rank.py`
    lists each `new:` name with its batches; the main session writes its
    decisions to `new-kinds.tsv` (name, then a kind or `other`), which
    `rank.py` applies on its next run. The labels files are never edited.
- **Why 120 rows, against the prototype's 61:** each 61-row slice cost
  about 95 k tokens, most of it fixed per-agent overhead. Larger slices
  were not tested, so Step 4 re-runs the prototype's stability check at
  120.
- **New kinds from different slices.** Slices may name the same new kind
  differently. The main session merges such names before counting batches.
- **Kinds stay coarse; specificity comes at drafting** (the user's choice).
  For a selected kind, the main session groups its rows by concrete cause.
  It drafts a proposal only for the largest cause group, and only when that
  group itself spans at least two batches. A kind whose largest group spans
  one batch yields no proposal, and `rank.md`'s next item takes the slot.
- **Time items need a cause too.** A selected time item yields a proposal
  only when drafting names a cause backed by record lines in at least two
  batches. Examples of such a cause:
  - a standalone review that found no HIGH in those batches;
  - code-fixer minutes spent on LOW rows the main session ruled FIX.

  A role that is large only because the work was large is not a problem,
  and its slot passes to the next item.

### Proposals

- **Fields.** Each `proposal-<n>.md` states:
  - where it went wrong: record keys and counts;
  - the file and layer it changes, and why that layer;
  - what changes in the next batch;
  - how to undo it;
  - the measure the next retro reads (a kind's de-duplicated cost or a
    role's minutes per batch) and its current value;
  - the expected effect.
- **Layer order.** Where the project's instruction files state an order
  for adding a rule, that order decides. Otherwise the skill's default:
  1. nowhere;
  2. a hook, check script or CI;
  3. a skill;
  4. a path-scoped rule;
  5. a standards file read only at review;
  6. the always-loaded AGENTS.md / CLAUDE.md, kept to a short map.
- **Landing places:**
  1. the project's files: applied after approval;
  2. the kenspc plugin: a brief-shaped section in the record, for a
     separate session to take to `/kenspc-plan`;
  3. the user's global files: a suggestion in words in the record.
  The skill writes nothing outside the project repository. Inside it, it
  writes only `RETRO_DIR`, the files of adopted proposals, and the record.
- **When the project is the kenspc repository itself,** plugin files are
  project files. Such proposals are landing place 1, and the record says
  so. Why: the brief left this to the plan. Treating them as project files
  is the only reading under which a maintainer's retro can change anything.

### Verification before the user sees anything

- **New INTERNAL agent `retro-verifier`:**
  - `tools: Read, Bash, Grep, Glob`, `model: inherit`, no `effort:`;
  - CONTEXT keys `RETRO_DIR`, `PROPOSAL` (the path of one
    `proposal-<n>.md`), `PROJECT_PATH`, `WORKSPACE`.
- **Dispatch:** one per proposal, in parallel, `run_in_background: false`.
- **What it does:** it did not draft the proposal. It re-reads the cited
  raw lines in the run directories and logs, not the extracted tables. It
  recounts the cited counts and tests the stated cause against the
  records.
- **The expected effect.** It cannot verify a prediction. It computes the
  effect's ceiling instead: the most the change could save, given the
  window's numbers. An expected effect above that ceiling is `ADJUSTED`
  down to it. This is the manual retro's option A case: about 50%
  expected, 3% possible.
- **What it returns:** `HOLDS`, `ADJUSTED` (with corrected numbers), or
  `FAILS` (with the record line that breaks the premise).
  - A `FAILS` proposal is not shown to the user. It goes into the record as
    dropped, with the reason.
  - An `ADJUSTED` proposal is shown with the corrected numbers.
- Why the verifier is read-only: the manual retro's two wrong premises
  (3% against an estimated ~50%; cause (b), not (a)) were caught by
  re-reading raw records. A verifier that could edit could also "fix" the
  record to fit.

### Decide, apply, record

- **Deciding:** each verified proposal is put to the user one at a time,
  answerable in one word: adopt or reject, and a reason for a rejection.
- **Applying an adopted project-file proposal:**
  - the change is made, then its own commit (default subject
    `chore(retro): <summary>`), staging only the files the proposal names;
  - its undo is `git revert <hash>`, written into the record;
  - before that commit, the project's own check commands are run, as its
    instruction files or config define them. A project that defines none
    gets the record line "no check commands defined".
- **A failed check or a rejected commit.** The proposal's changes are
  restored from `HEAD` (`git restore --staged --worktree` on the files it
  names that `HEAD` has; a file the proposal created is removed), the
  proposal is recorded as `failed` with the failing check's or
  hook's output lines, and the user is asked whether to go on to the next
  proposal or stop. In a session that cannot ask (a system reminder to work
  without stopping), no project file is changed, so only the record commit
  can fail; the run then stops with the hook's message and leaves the record
  file uncommitted in the working tree.
- **The record:** `docs/retros/<YYYY-MM-DD>.md`, committed last (default
  subject `docs(retro): record <date> retro`). When a record for that date
  already exists, the name gains `-<n>` (`2026-10-21-2.md`); the newest
  record is the one whose Window line ends latest. Commit subjects are adapted
  to the repository's convention: the one its instruction files or
  CONTRIBUTING write down, or else the pattern its recent subjects share.
  The record grammar is written once, in `skills/retro/SKILL.md`, and the
  next retro reads it from there. Sections:
  - Window and coverage (a Window line with the first and last run
    timestamps in the window);
  - Follow-up (each previous adopted item: measure then, measure now);
  - Kinds (table: kind, definition);
  - Adopted (all proposal fields, commit hash, undo);
  - Rejected (fields and the user's reason);
  - Dropped by verification (reason);
  - Pending (all proposal fields), Failed (the check's lines);
  - Runner-ups;
  - For the kenspc plugin;
  - For your global files.
- **A rejected proposal is not proposed again** unless its kind (or, for
  a time item, its role or subagent kind) now spans more batches than the
  record states.
- **In a session that cannot ask:** every verified proposal is recorded as
  `pending`. No project file changes, and only the record is committed.
- **A pending or failed proposal is proposed again** at the next retro if it
  still passes the bar, and gets no follow-up line, since nothing changed.

### Window and arguments

- **Arguments:** `/kenspc-retro [last <n> | since <YYYY-MM-DD> | all] [Workspace: <dir>]`.
- **Default window:** batches whose earliest run starts after the last run
  timestamp on the newest record's Window line, or the 20 most recent
  batches when there is no record. Why the timestamp, not the record's
  date: a batch that ran on the record's date, before or after the retro,
  would otherwise be counted twice or never.
- **The window question.** With no window argument, the skill runs
  `map_runs.py` with the default window, states the window's batch count
  and first and last dates, and asks whether to run it or name another; a
  window the user names re-runs `map_runs.py` with it. The question comes
  after `map_runs.py` because batches exist only once runs are mapped. In a
  session that cannot ask (a system reminder to work without stopping), the
  default window is used.
- **Default workspace:** `~/Projects/_smoke/`, as in the autopilot.
- **A window with fewer than two batches** stops after Phase 1, with the
  counts. The bar cannot be met.

### Skill and command frontmatter

- `skills/retro/SKILL.md` carries `disable-model-invocation: true` and
  `version: 3.0.0`.
- `commands/kenspc-retro.md` follows the existing command shape.
- This is the first skill not invoked by the model. The plugin README's
  sentence that skills activate automatically gains that exception.

## Implementation Steps

### Step 1 — Extraction scripts and their guard

- **What:** the seven scripts above, plus fixtures under
  `scripts/fixtures/retro/` in this repository (not shipped). The fixtures
  are:
  - a run directory whose angle row holds `\|`;
  - a run id named in two sessions' jsons, only one of whose windows
    contains it, and a run whose only candidate session has no json;
  - a schema-b whose Action carries `— ruled`;
  - a stats line that disagrees by one;
  - an S3/S3b duplicate pair;
  - an autopilot `_logs` with a timeline, `.exit` files, a resume and a
    usage-limit `.json`;
  - a transcript tree with two overlapping subagent spans;
  - a state file in the old free-form shape.

  `scripts/check-retro-scripts.sh` runs the scripts on the fixtures and
  compares their outputs with expected files. Its `--self-test` mutates the
  pipe split and the span union, and expects both mutants to fail. Like
  `check-instruction-lint.sh` with `pwsh`, the guard exits 2 when `python3`
  is missing, never 0.
- **Input:** the record formats above; the manual retro's
  `followup/verify/parse.py` as the reference parser. The manual retro's
  files named in this step are under
  `~/Projects/_smoke/_analysis/review-time-20261019/`, and dayaku-crm is
  `~/Projects/Diagnohab/dayaku-crm`.
- **Output:** scripts, fixtures, the guard; `check-all.sh` picks the guard
  up by glob.
- **Acceptance:**
  - `bash scripts/check-all.sh --self-test` passes, and reports guards and
    self-tests one higher than the release checklist's current 16 and 15.
  - Run on dayaku-crm, over the 96 run ids `followup/verify/runmap.tsv`
    lists (a run added since is left out of the comparison),
    `extract_findings.py` gives 1005 rows, FIXED 716 / DEFERRED 256 /
    NOT APPLICABLE 33, and no anomaly.
  - Run on dayaku-crm, `map_runs.py` agrees with
    `followup/verify/runmap.tsv` for every run:
    - the same batch;
    - the same role as runmap's role column (`s3`, `s3b`, `s3c`, `s3d`);
    - `manual` for the three runs runmap leaves unmapped (`-`).
  - Run on dayaku-crm, `measure_time.py` matches `rows.json`'s wall minutes
    within 1 minute for every batch and role `rows.json` lists.
  - `check-no-model-names.sh` passes over the scripts.

### Step 2 — The two agents

- **What:** `agents/retro-classifier.md` and `agents/retro-verifier.md`.
  Each has:
  - an INTERNAL first description sentence;
  - a PREREQUISITE CHECK that refuses a missing CONTEXT key;
  - CONTEXT YOU WILL RECEIVE listing exactly the keys above;
  - Why-prose rules.
- **Depends on:** Step 1, for the file shapes the agents read.
- **Acceptance:**
  - In a session started with `claude --plugin-dir ./plugins/kenspc` from
    this repository, each agent dispatched without `RETRO_DIR` refuses on its
    prerequisite check. Why that session: a plain session runs the installed
    plugin copy, which has no retro agents.
  - `check-no-model-names.sh` passes, since both have `model: inherit`.

### Step 3 — SKILL.md and the command

- **What:**
  - `skills/retro/SKILL.md`, with the phases above, the record grammar,
    and the cannot-ask sentence at each stop: the window question, the
    per-proposal decision, a failed commit;
  - a top-level-session bullet in its Prerequisites, as task-review and
    task-implement have. Why: the skill dispatches agents, and a subagent
    cannot;
  - scripts addressed as `${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/<name>.py`,
    the way the autopilot addresses its driver;
  - the definition sentence of `shared/instruction-files.md`, verbatim,
    wherever SKILL.md or an agent uses the term "instruction files". Why:
    `check-instruction-files.sh` fails any file under `skills/`, `agents/`,
    or `commands/` that uses the term without it, and the layer order and
    the check commands both lean on the term;
  - `commands/kenspc-retro.md`.
- **Depends on:** Steps 1–2.
- **Acceptance:**
  - every CONTEXT block the SKILL.md builds has exactly the keys its agent
    declares;
  - every stop opens with "In a session that cannot ask (a system reminder
    to work without stopping), …";
  - `claude plugin validate --strict ./plugins/kenspc` passes;
  - `bash scripts/check-all.sh` passes, `check-instruction-files.sh` and
    `check-no-model-names.sh` included.

### Step 4 — Stability re-check at the shipped slice size

- **What:** classify dayaku-crm's 20 most recent batches twice against one
  derived `kinds.tsv`, with fresh classifier dispatches at 120-row slices,
  in a `claude --plugin-dir ./plugins/kenspc` session. The skill's own run
  would derive new kinds each time, since dayaku-crm has no record, so the
  steps are run by hand:
  1. Phase 1's scripts with window `last 20`, then one `derive` dispatch.
  2. Run A: one `classify` dispatch per `slice-<n>.tsv`.
  3. Run B: the same rows shuffled with a fixed seed into a scratch copy,
     cut into 120-row slices, one fresh `classify` dispatch per slice, same
     `kinds.tsv`.
  4. The comparison: the prototype's `rank.py`
     (`git show 78e797e:prototypes/finding-classification/rank.py`), run
     from a scratch directory holding run A's labels as `labels-A-<n>.tsv`,
     run B's as `labels-B-<n>.tsv`, `window.tsv` (key, batch, severity)
     from `findings.tsv` joined to `runs.tsv`, and `manual.tsv` (key, kind)
     from the manual retro's `categories.tsv` (in
     `~/Projects/_smoke/_analysis/review-time-20261019/`, as the prototype's
     `prepare.py` built it). It prints the top-five overlap,
     each shared kind's row overlap, and PASS or FAIL.
- **Depends on:** Step 3.
- **Acceptance:** the brief's bar holds:
  - at least four of the two runs' top five findings kinds are the same;
  - each shared kind's rows overlap by at least 60%.

  On a failure, the slice size drops to 60 rows, about the prototype's
  tested 61-row slices, and the step repeats. A failure at 60 rows stops
  the plan for the user's ruling, with both runs' `rank.py` output.

### Step 5 — End-to-end acceptance on dayaku-crm

- **What:** `/kenspc-retro` in an interactive session started with
  `claude --plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc`
  in a clone of dayaku-crm whose root is `~/Projects/_smoke/retro-accept/`.
  - The clone's `.kenspc/runs` is a symlink to the real one, which is
    56 GB and too large to copy, read-only in use.
  - The workspace is the real `~/Projects/_smoke/`.
  - Before the run, the clone's dependencies are installed with the
    commands dayaku-crm's instruction files name, so the per-proposal
    checks run in the clone as they do in the real checkout.
  - The first run takes the default window, the 20 most recent batches,
    at the window question.
  - The maintainer approves one proposal and rejects one.
- **Depends on:** Step 4.
- **Acceptance:**
  - the clone has one commit per adopted proposal and a record commit;
  - the record has every section;
  - `extract.md` reports coverage;
  - no file outside the clone changed (`git status` in the real dayaku-crm
    is unchanged);
  - a second run, `/kenspc-retro last 20`, reads the record. It shows the
    adopted item's measure then and now, and does not re-propose the
    rejected item. Why `last 20`: it is the first run's window, so the
    rejected kind spans the batches the record states. A wider window such
    as `all` may show it in more batches, which the no-repeat rule allows
    to be proposed again, and the default window would hold no batch.

### Step 6 — Documentation sync

- **What:** every entry under Documentation impact.
- **Depends on:** Steps 1–5, so the documents describe what was accepted.
- **Acceptance:**
  - `bash scripts/check-all.sh --self-test` passes, including
    `check-instruction-lint.sh` with AGENTS.md at or under its 200-line
    budget;
  - `claude plugin validate --strict .` passes.

## Documentation impact

- `README.md` — skills table (add retro), commands line (add
  `/kenspc-retro`), "11 reusable subagents" → 13. Step 6, caused by
  Steps 2–3.
- `plugins/kenspc/README.md`:
  - skills, commands, and `/kenspc:<skill>` lists;
  - the sentence that skills activate automatically gains the retro
    exception;
  - "11 reusable subagents" → 13;
  - agents table and INTERNAL note;
  - a retro section covering `docs/retros/`, `.kenspc/retros/`, python3,
    and the record;
  - Run directory gains `.kenspc/retros/`;
  - Requirements gains `python3` 3.9 or newer for `/kenspc-retro`, beside
    the autopilot's own requirement line.

  Steps 2–3.
- `AGENTS.md`:
  - project overview lists retro;
  - Orchestration patterns gain "Parallel classification, then
    verification: retro";
  - "six others are orchestration-only" → eight;
  - "3.0.0 in all ten skills" → eleven (both mentions);
  - the record grammar joins the "Written once" list.

  The file is at 199 of 200 lines, so these changes merge into existing
  lines with no net growth. Steps 2–3.
- `CLAUDE.md` — N/A for this document: no Claude Code-specific rule
  changes.
- `plugins/kenspc/.claude-plugin/plugin.json` — description names retro;
  "eleven reusable subagents" → thirteen. The version moves at release,
  not in this plan. Steps 2–3.
- `.claude-plugin/marketplace.json` — top-level description gains retro.
  The plugin-entry summary is left alone, per AGENTS.md. Step 3.
- `plugins/kenspc/CHANGELOG.md` — `## 4.14.0 — unreleased`, `### Added`:
  the skill, the command, the two agents, the scripts, the guard. Steps
  1–3.
- `docs/release-checklist.md`:
  - row 1's command count 10 → 11;
  - pinned guard and self-test counts 16/15 → 17/16;
  - a new smoke row for `/kenspc-retro` before the end-to-end row, with
    later rows and every reference to their numbers renumbered. The row is
    a headless run in a session that cannot ask, `last 3`, on the Step 5
    clone. Pass: the record lists every verified proposal as `pending`,
    and no project file outside `docs/retros/` changed;
  - the effort diff is unchanged, since neither agent sets `effort:`.

  Steps 1, 3.
- `docs/roadmap.md` — two items planned: the autopilot final-report line
  on batches since the last retro, and run-directory ids in the state
  file. Both were deferred by the brief. Item 9's two mentions of smoke
  row 13 become row 14, following the checklist's renumbering. Step 6.
- `docs/dry-runs/README.md` — N/A for this document: the label convention
  does not change.
- `plugins/kenspc/references/plan-document-example.md`,
  `task-document-example.md` — N/A for these documents: neither format
  changes.

## Testing Strategy

- **Mechanical parts:**
  - `check-retro-scripts.sh` checks them on fixtures built from the
    failure cases the manual retro hit;
  - its mutation self-test proves the comparisons can fail.
- **Against real data:** Step 1's acceptance reproduces the manual retro's
  verified numbers, so a parser that drifts shows up as a count that no
  longer matches.
- **Judgement parts:**
  - Step 4 re-runs the prototype's falsifiable stability check;
  - Step 5 checks the end-to-end behaviour, including the follow-up read
    and the no-repeat rule.

## Risks and Mitigations

- **Transcripts pruned by Claude Code** make subagent time unmeasurable
  for older batches. Role time from `_logs` remains. The coverage line in
  `extract.md` and the record says how many sessions were unmeasured, so a
  smaller time share is not read as an improvement.
- **The record grammar drifts** between the writing and reading sides. It
  is written once in SKILL.md, and the scripts parse only the Window line,
  the Kinds table, the adopted items' measure lines, and the rejected
  items' kind and batch count. Step 5's second run is the check.
- **Run directories of a removed worktree are gone.** A worktree batch
  writes its run directories in the worktree, and `extract_findings.py`
  reads only the worktrees that still exist. dayaku-crm's worktree runs
  survive because they sit in the main checkout's `.kenspc/runs/`, every
  directory with the same mtime of 2026-10-20 11:04 (a reading: they were
  copied back then). Elsewhere such batches are missing from the findings;
  `extract.md` and the record's Window and coverage section list the
  worktrees read, so the gap is stated rather than hidden.
- **A project without autopilot batches** gets findings only. The time
  list is empty, its two slots pass to findings, and `extract.md` says so.
- **Windows without python3.** The skill stops with the reason.
- **Coarse kinds hide two causes under one label.** Drafting splits by
  cause and needs that cause in two batches.
- **De-duplication merges two distinct problems.** `rank.md` lists every
  merge.
- **A manual re-review inflates the batch count.** `rank.md` marks items
  whose batches include a manual run, and the verifier checks whether the
  two batches are one piece of work.
- **Per-proposal checks are slow on a large project.** Each adopted
  project-file proposal runs the project's checks before its commit. That
  is the price of one revertable commit per proposal; there are at most
  five.

## Open Questions

1. `open` — Do the scripts run unchanged under python3 on native Windows
   and on WSL2? Steps 1–5 are verified on macOS only.
   - Assumed in: Step 1 assumes `pathlib` handling makes the scripts
     portable, and the transcript root follows
     `${CLAUDE_CONFIG_DIR:-$HOME/.claude}` on every platform.

The brief's only open question, entry 1, is `answered`
(`docs/briefs/retro-skill.md`, entry 1; prototype `78e797e`). This plan
relies on its answer in Classification and in Step 4.
