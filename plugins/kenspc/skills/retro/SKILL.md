---
name: retro
description: >
  Retrospective over a window of finished batches (回顾一批批次): measures
  where the review findings and the session time went, ranks the problems
  that recurred across batches, has each proposed change verified against
  the raw records, applies the ones the user adopts, and commits a record
  the next retro reads. Started only by hand, with /kenspc-retro.
version: 3.0.0
disable-model-invocation: true
argument-hint: "[last <n> | since <date> | all] [Workspace: <dir>]"
---

# Retro

A run looks back over a window of finished batches and does five things:
it measures where they went wrong and where they spent time, proposes at
most five changes to the project's environment, has each proposal verified
against the raw records before the user sees it, applies the proposals the
user adopts, and commits a record. The next retro starts by checking that
record.

Started only by `/kenspc-retro`. Why: a retro reads every review run in its
window and dispatches a classifier per slice of findings, which costs far
more than any question it could answer in passing, so it runs only when
asked for.

## Quality bar

A useful retro proposes only changes whose premise holds in the raw
records: a problem that recurred in at least two batches that are not one
piece of work, a cause the records show, and an expected effect no larger
than the window's numbers allow. Each adopted change is one commit the user
can revert, and the record carries the numbers the next retro checks it
against.

## Prerequisites

- The skill runs in the top-level session — the one the user talks to, or
  a headless `claude -p` session — and never inside a subagent. Why: it
  dispatches a classifier per slice and a verifier per proposal, a subagent
  may not dispatch subagents of its own — a user rule may forbid it, and
  Claude Code caps the nesting depth — and it cannot ask the user at this
  skill's questions.
- `python3` 3.9 or newer on PATH:
  `python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 9) else 1)'`
  exits 0. If it does not, stop and say so, naming the version found or
  that `python3` was not found. Why: every mechanical step is one of the
  shipped scripts, and there is no fallback that parses the review tables
  by hand — the manual retro this skill replaces went wrong exactly there.
- A git repository with review runs under `.kenspc/runs/`.

## Arguments

`$ARGUMENTS`: `[last <n> | since <YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS> | all] [Workspace: <dir>]`

- The window, optional: `last <n>` takes the n most recent batches;
  `since <date>` the batches whose earliest run is on or after that date;
  `since <timestamp>` those whose earliest run is strictly after it; `all`
  every batch. A batch is in the window when its earliest run is.
- `Workspace: <dir>`, optional: the autopilot workspace whose `_logs/`
  holds the batches' timelines, session results, and state files. Default
  `~/Projects/_smoke/`, as in the autopilot.

## Scope of reads and writes

- The main session reads only `extract.md`, `rank.md`, the proposal files,
  and rows it has a script or a one-line filter print by key: findings
  through `show_rows.py`, and a batch's `time.tsv` and `notes.tsv` rows
  printed by batch name. It never opens a review report, a run directory,
  a log, or a transcript itself. Why: a window of about a thousand
  findings does not fit in the session's context, and the verifier, not
  this session, is the one that reads the raw records.
- The skill writes nothing outside the project repository. Inside it, it
  writes only `RETRO_DIR`, the files of adopted proposals, and the record
  (plus the one-time `.gitignore` commit of Phase 0). Why: a retro's
  changes must each be a commit the user can see and revert, and a file
  written elsewhere would change the environment with no record of it.

The scripts are addressed as
`${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/<name>.py` and run with
`python3 -I`, each with its usage and output columns in its own header.

## Phase 0 — Locate

1. The root is `git rev-parse --show-toplevel`. Create `RETRO_DIR` =
   `<root>/.kenspc/retros/<YYYYMMDD-HHMMSS>/` from `date +%Y%m%d-%H%M%S`.
   Every file this run writes there follows the naming rule of the Scratch
   space bullet in the run-directory preparation of
   `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` — the block between
   `<!-- canonical:run-dir:start -->` and `<!-- canonical:run-dir:end -->` —
   read there, not copied here: no name the project's test runner collects.
2. Make sure `.kenspc/retros/` is git-ignored with the Ignore check bullet
   of the same block, read there, with the probe path
   `.kenspc/retros/probe` in place of `.kenspc/runs/probe`. Exit 0 changes
   nothing; exit 1 appends `.kenspc/` to `.gitignore` and commits it as
   that bullet prescribes; anything else stops the run as it prescribes.
   Why: a project that ignores only `.kenspc/runs/` would otherwise show
   the retro's working files in `git status`, and a later commit could
   sweep them in. `RETRO_DIR` sits beside `runs/`, not in it, so a later
   retro's extraction never reads it as a run.
3. The previous record is the newest file under `<root>/docs/retros/`:
   the one whose `Window:` line (the record grammar below) ends latest.
   `grep -H '^Window: ' <root>/docs/retros/*.md` prints each; the second
   timestamp on the line is the end, and ISO timestamps sort as text.
   Records whose ends are equal — two retros over one window — are told
   apart by file name: the later date, then the higher `-<n>` suffix, a
   name with none counting as 1. Why: `grep` lists `2026-10-21-2.md`
   before `2026-10-21.md`, and the older of the two would bring back the
   newer one's rejections and measure the wrong adopted items. No such
   file, or none with a `Window:` line, means no previous record.
4. The window spec is the argument's, or `since <the previous record's last
   run timestamp>` (the second timestamp of its `Window:` line), or, with no
   record, `last 20`. Why the timestamp and not the record's date: a batch
   that ran on the record's date, before or after that retro, would
   otherwise be counted twice or never, and `since` with a timestamp
   excludes its own moment.
5. The workspace is the argument's `Workspace:` directory, or
   `~/Projects/_smoke/`. A `Workspace:` the user named that holds no
   `_logs/` directory stops the run, naming the path. Why: the mapping
   finds no session there without an error, so every run would become a
   `manual` batch of its own, and one piece of work reviewed twice would
   meet the two-batch bar.

## Phase 1 — Extract

Run the scripts in this order, each from the root, stopping on any exit
other than 0 with its stderr:

1. `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/extract_findings.py <root> <RETRO_DIR>`
2. `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/map_runs.py <root> <workspace> "<window spec>" <RETRO_DIR>`
3. The window question, only when the arguments named no window. Read the
   window lines `map_runs.py` printed and ask one question: "The default
   window `<spec>` holds <n> batches, from <first run date> to <last run
   date>, with <t> timelines read from `<workspace>`. Run it, or name
   another window (`last <n>`, `since <date>`,
   `all`)?" A window the user names re-runs step 2 with it, and its lines
   replace the earlier ones in `extract.md`. In a session that cannot ask
   (a system reminder to work without stopping), the default window is
   used and the final message says so. Why the question comes here: the
   window counts batches, which exist only once runs are mapped.
4. A window with fewer than two batches stops here, with the counts: the
   window's batches and runs, and how many batches `all` would hold. Why:
   the bar is a problem seen in at least two batches, which such a window
   cannot meet; the run writes no record. A window whose batches the
   previous record already covered — an explicit `last 20` right after a
   `last 20` retro — is not a stop: the run goes on to its record. Why: the
   window is the user's choice, and a stop this skill does not define has
   no branch for a session that cannot ask, which would end with no record.
5. `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/measure_time.py <workspace> <RETRO_DIR>/runs.tsv <RETRO_DIR>`
6. `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/state_notes.py <workspace> <RETRO_DIR>/runs.tsv <RETRO_DIR>`
7. `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/slice_findings.py <RETRO_DIR> [<previous record>]`
   — the record path only when Phase 0 found one.

Then read `extract.md`. Every anomaly it lists goes into the record's
Window and coverage section; an anomaly is never dropped silently.

## Phase 2 — Classify

Dispatch `retro-classifier` with a CONTEXT block holding exactly its keys,
every dispatch with `run_in_background: false`. Why foreground: the next
step reads what every dispatch wrote, and a background dispatch returns
before its file exists.

1. With no previous record, one `derive` dispatch first:

   ```
   CONTEXT
   - RETRO_DIR: <RETRO_DIR>
   - MODE: derive
   - INPUT: <RETRO_DIR>/sample.tsv
   - KINDS: none
   - OUTPUT: <RETRO_DIR>/kinds.tsv
   ```

   With a previous record, `slice_findings.py` has already copied its
   Kinds table to `kinds.tsv`, and there is no `derive` dispatch. Why:
   the same kinds make this window's counts comparable with the record's.
2. Then one `classify` dispatch per `slice-<n>.tsv`, all sent in one
   message:

   ```
   CONTEXT
   - RETRO_DIR: <RETRO_DIR>
   - MODE: classify
   - INPUT: <RETRO_DIR>/slice-<n>.tsv
   - KINDS: <RETRO_DIR>/kinds.tsv
   - OUTPUT: <RETRO_DIR>/labels-<n>.tsv
   ```

   Why one per slice, in parallel: each slice is labelled against the
   kinds alone, which is what made separately classified slices rank the
   same top kinds.
3. A slice whose `labels-<n>.tsv` is missing, or whose dispatch refused, is
   dispatched once more; a second failure stops the run with the reply.

## Phase 3 — Rank and draft

1. `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/rank.py <RETRO_DIR> [<previous record>]`,
   then read `rank.md`. Its Label check names unlabelled rows and labels
   that `kinds.tsv` does not hold (a misspelled kind, a blank label); a
   count of either other than zero sends their slice back to Phase 2 step 3.
   Why the second: a misspelled kind ranks as a kind of its own and splits
   the real kind's cost.
2. Resolve the `new:` names in `rank.md`'s New kinds table into
   `<RETRO_DIR>/new-kinds.tsv` (header `name`, `kind`), then run `rank.py`
   again:
   - first merge names that different slices gave the same new kind,
     judged from their rows (`show_rows.py`);
   - a name, merged, used in at least two batches becomes a kind: write it
     as its own name and give it a one-sentence definition for the
     record's Kinds table;
   - any other name goes to `other`.
   The labels files are never edited. Why: they are the classifier's
   output, and the resolution must stay visible as a separate file the
   ranking applies.
3. For each item in `rank.md`'s Selected list, in order, draft
   `<RETRO_DIR>/proposal-<n>.md`:
   - A findings item: print its rows with
     `python3 -I ${CLAUDE_PLUGIN_ROOT}/skills/retro/scripts/show_rows.py <RETRO_DIR> <key>…`
     (the keys are in `rank.md`'s Keys section), split them by concrete
     cause, and draft only for the largest cause group that spans at least
     two batches. Why: kinds are kept coarse so the ranking is stable, and
     a coarse kind can hold two causes that no single change answers.
   - A time item needs a cause backed by record lines in at least two
     batches — for example a standalone review that found no HIGH in those
     batches, or code-fixer minutes spent on LOW rows the main session
     ruled FIX. Print its batches' rows with
     `awk -F'\t' '$1 == "<batch>"' <RETRO_DIR>/time.tsv <RETRO_DIR>/notes.tsv`.
     A role that is large only because the work was large is not a problem.
   - An item that yields no proposal passes its slot to the next unselected
     candidate in its own list in `rank.md` that the record has not
     rejected (its record column does not end `skipped`); a list that runs
     out passes it to the other list.
   - An item `rank.md` marks as including a manual run is drafted with that
     said, so verification can check whether the two batches are one piece
     of work.
4. Each `proposal-<n>.md` states:
   - where it went wrong: the record keys and counts;
   - the file and layer it changes, and why that layer;
   - what changes in the next batch;
   - how to undo it;
   - the measure the next retro reads — a kind's cost per batch or a time
     item's minutes per batch — and its current value from `rank.md`'s
     Selected line;
   - the expected effect;
   - the item, as the record names it (`kind \`<kind>\`` or
     `time \`<item>\``), with its batches out of the window's batches and
     its cost.
5. The layer. The project's instruction files are its CLAUDE.md and
   AGENTS.md files — at the root, in `.claude/`, or in a subdirectory — and
   the files a CLAUDE.md imports with `@`, whether or not Claude Code loaded
   them in this session. Where they state an order for adding a rule, that
   order decides; otherwise this default, the first that can hold the
   change:
   1. nowhere;
   2. a hook, check script, or CI;
   3. a skill;
   4. a path-scoped rule;
   5. a standards file read only at review;
   6. the always-loaded AGENTS.md / CLAUDE.md, kept to a short map.
   Why this order: a mechanical check holds without anyone remembering it,
   and every line in an always-loaded file is paid for in every session.
6. The landing place:
   1. a file of the project: applied after the user adopts it;
   2. the kenspc plugin: a brief-shaped section in the record (problem,
      evidence, proposed change, expected effect) for a separate session to
      take to `/kenspc-plan`;
   3. the user's global files: a suggestion in words in the record.
   In the kenspc repository itself (its root holds
   `plugins/kenspc/.claude-plugin/plugin.json`), plugin files are project
   files, landing place 1, and the record says so. Why: otherwise a
   maintainer's retro could change nothing.

## Phase 4 — Verify

Dispatch one `retro-verifier` per proposal, all in one message, each with
`run_in_background: false` and a CONTEXT block holding exactly its keys:

```
CONTEXT
- RETRO_DIR: <RETRO_DIR>
- PROPOSAL: <RETRO_DIR>/proposal-<n>.md
- PROJECT_PATH: <root>
- WORKSPACE: <workspace>
```

- `FAILS`: the proposal is not shown to the user. It goes into the record's
  Dropped by verification section with the verifier's breaking line.
- `ADJUSTED`: write the corrected numbers and the effect cut to its ceiling
  into the proposal file, and show it with them.
- `HOLDS`: show it as drafted.
- No `VERDICT:` line — a refusal, a dispatch error, or a reply without
  one: dispatch that verifier once more; a second reply without one counts
  as `FAILS`, with the reason `not verified` and the reply's first line.
  Why: an unverified proposal shown as drafted is what this phase exists
  to prevent.

Why before the user sees anything: in a retro done by hand, two proposals
rested on premises the records contradicted, and a proposal the user has
already weighed is harder to drop than one never shown.

## Phase 5 — Decide, apply, record

### Deciding

Put each verified proposal to the user on its own, in one question
answerable in one word: adopt, or reject with a reason — one message per
proposal, the next sent once the previous one is answered. Why: each
decision then rests on that proposal's evidence and verdict alone, while a
message holding them all invites one line that answers every proposal at
once, where the record needs each rejection's own reason. In a session that
cannot ask (a system reminder to work without stopping), every verified
proposal is recorded as `pending`, no project file changes, and only the
record is committed.

### Applying

For each adopted proposal whose landing place is a project file, in order:

1. Run `git status --porcelain -- <each file the proposal names>`. A file
   it lists — uncommitted changes, or an untracked file at a path the
   proposal would create — leaves the proposal unapplied: no file is
   touched, and it is recorded as `failed`, with the paths and their
   status lines. Why: the commit below would carry the user's own edits
   under the retro's subject, and the restore after a failed check would
   wipe them, as removing a created file would delete one the user
   already had.
2. Make the change in the files the proposal names.
3. Run every check command the project defines — the ones its instruction
   files or its config files define (a `check` or `test` script, a
   documented command; lint, build, and test alike), read there and never
   assumed from the stack — none left out because the change looks too
   small to break it. A project that defines none gets the record line
   `no check commands defined`. Why: the commit rests on these commands
   alone, and whether a change breaks a test is what running the tests
   finds out.
4. Commit, staging only the proposal's files, with the default subject
   `chore(retro): <summary>`. Its undo, `git revert <hash>`, goes into the
   record.

A failed check or a rejected commit (a hook's refusal):

- restore the proposal's files from HEAD — `git restore --staged
  --worktree -- <path>…` on the files it names that HEAD has — and remove
  each file it created;
- record the proposal as `failed`, with the failing check's or hook's
  output lines;
- ask whether to go on to the next proposal or stop. In a session that
  cannot ask (a system reminder to work without stopping), this question
  never comes: such a session changes no project file, so only the record
  commit can fail.

An adopted proposal for the kenspc plugin or the user's global files
changes no file; its section in the record is the outcome.

### The record

Write `<root>/docs/retros/<YYYY-MM-DD>.md`, dated today; when a record of
that date exists, the name gains `-<n>` (`2026-10-21-2.md`). Write it in the
grammar below, then commit it last, staging only that file, with the
default subject `docs(retro): record <date> retro`. If the commit is
rejected, show the hook's lines and ask whether to commit again once the
user has fixed what the hook names, or stop with the record uncommitted.
In a session that cannot ask (a system reminder to work without stopping),
the run stops with the hook's message and leaves the record file
uncommitted in the working tree.

Every commit subject here is a default, adapted to the repository's commit
convention: the one the repository writes down (in the project's
instruction files or its CONTRIBUTING), or, failing that, the pattern its
recent commit subjects consistently share. Why: a repository whose
convention requires a scope from a fixed list rejects `chore(retro):`.

### Rules about earlier proposals

- A rejected item is not proposed again unless its share of the window's
  batches grew and it is in at least two batches now: `rank.py` skips it
  and passes its slot on. Why: the user already weighed it on the same
  evidence. Why the share, not the count: the default window holds only the
  batches since the last record, usually fewer, so a count could almost
  never grow; and why two batches as well: in a small window one batch
  already makes a large share.
- The record's `## Rejected` section also repeats each rejected entry of
  the previous record whose item this run did not put to the user: its
  Item line, its `Batches:` line with both numbers unchanged, and its
  `Reason:` line prefixed `carried from <the previous record's file
  name>:`. Why: `rank.py` reads only the newest record, so a rejection
  left out of it would be proposed again two retros later on the same
  evidence.
- Pending and failed items are proposed again when they still pass the
  bar, and get no Follow-up line, since nothing changed.

## The record grammar

Written once, here. Sections, in this order:

```
# Retro record — <YYYY-MM-DD>

## Window and coverage

Window: <YYYY-MM-DDTHH:MM:SS> to <YYYY-MM-DDTHH:MM:SS>
- Window spec: `<spec>`; <n> batches, <n> runs.
- Coverage: <the coverage line from extract.md>
- Worktrees read: <each worktree extract.md lists, with its run directory count>.
- Anomalies: <each anomaly extract.md lists, or none>.
- Check commands: <the commands run before each adopted commit, or: no check commands defined>.

## Follow-up

| item | measure | then | now |
|---|---|---|---|
| kind `<kind>` | cost per batch | <n> | <n> |
| time `<item>` | minutes per batch | <n> | <n> |

(or: No previous record. — copied from rank.md's Follow-up section)

## Kinds

| kind | definition |
|---|---|
| <kind> | <one sentence> |

## Adopted

### A<n>: <summary>

- Item: kind `<kind>`, <n> of <m> batches, cost <n>.
- Measure: kind `<kind>` cost per batch = <n>
- Where it went wrong: <record keys and counts>
- Changes: <file>, layer <n> (<layer>): <why that layer>; landing place <1, 2, or 3>.
- Next batch: <what changes>
- Undo: `git revert <hash>`
- Commit: <hash>
- Expected effect: <the effect>; verifier <HOLDS or ADJUSTED, with what it corrected>.

## Rejected

### R<n>: <summary>

- Item: <as under Adopted>
- Batches: kind `<kind>` = <n> of <m>
- <the other proposal fields, as under Adopted, without Undo and Commit>
- Reason: <the user's reason>

## Dropped by verification

### D<n>: <summary>

- Item: <as under Adopted>
- Reason: FAILS — <path:line> <what the line shows>

## Pending

### P<n>: <summary>

- <every proposal field, as under Adopted, without Undo and Commit>

## Failed

### F<n>: <summary>

- <every proposal field, as under Adopted, without Undo and Commit>
- Failing check: <the failing check's or hook's output lines>

## Runner-ups

- <findings or time> `<item>`: cost <n>, within 10% of the last selected cost <n>.

## For the kenspc plugin

### K<n>: <summary>

- Problem: <what went wrong, with record keys and counts>
- Evidence: <the verifier's verdict and the lines it read>
- Proposed change: <the plugin file and what changes>
- Expected effect: <the effect, within its ceiling>

## For your global files

- <a suggestion in words>
```

The next retro's `rank.py` and `slice_findings.py` read these lines, so
they are written exactly in these forms, one line each, with nothing after
the value:

- `Window: <YYYY-MM-DDTHH:MM:SS> to <YYYY-MM-DDTHH:MM:SS>` — the first and
  last run timestamps of the window, from `extract.md`'s window lines;
- the `## Kinds` table, its header `| kind | definition |`;
- under `## Adopted`, one per item:
  `` - Measure: kind `<kind>` cost per batch = <n> `` or
  `` - Measure: time `<item>` minutes per batch = <n> ``;
- under `## Rejected`, one per item:
  `` - Batches: kind `<kind>` = <n> of <m> `` or
  `` - Batches: time `<item>` = <n> of <m> ``.

A time item writes ``time `<item>` `` where the template shows
``kind `<kind>` ``; its Item line reads
`` - Item: time `<item>`, <n> of <m> batches, <n> minutes. ``

The scripts tell the sections apart by their `## ` headings, so the same
line forms under Pending or Failed are not read. Why written exactly: a
line in another form is skipped without an error, and the next retro would
then repeat a rejected proposal or lose an adopted one's follow-up.

- A section with nothing in it holds the line `none`.
- `<n>` in an item heading counts from 1 within its section.
- The Kinds table holds every row of `kinds.tsv` and each kind Phase 3
  created from a `new:` name.
- The `Batches:` line carries the item's batches out of the window's
  batches (`<n> of <m>`) as `rank.md`'s Selected line prints them, or, for
  a rejection carried from the previous record, that record's two numbers;
  the next retro marks the item and skips it while its share has not grown
  or it is in fewer than two batches. A time item's batches are those it
  was measured in.
- The `Measure:` line carries the per-batch value from `rank.md`'s Selected
  line: a kind's cost per batch (its cost over all the window's batches),
  or a time item's minutes per batch (over the batches it was measured in).
  The next retro prints it as "then" beside its own "now". Why per batch:
  two retros' windows differ in size, and a whole-window cost would fall
  with the window alone.

## Stops and questions

| Stop | When | In a session that cannot ask |
|---|---|---|
| python3 missing or older than 3.9 | Prerequisites | stops with the reason |
| A named workspace with no `_logs/` | Phase 0 | stops with the path |
| The window question | Phase 1, no window argument | the default window |
| Fewer than two batches | Phase 1 | stops with the counts |
| Each proposal's decision | Phase 5 | recorded `pending`, no project file changes |
| A failed check or rejected proposal commit | Phase 5 | not reached: no project file changes |
| A rejected record commit | Phase 5 | stops with the hook's message, the record left uncommitted |

## Final message

End with: the record's path and commit (or that it is uncommitted, and
why); each adopted proposal's commit and undo; the counts of rejected,
dropped, pending, and failed proposals; the window used, and whether it was
the default; and the coverage line.
