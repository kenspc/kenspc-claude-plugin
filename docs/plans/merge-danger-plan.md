# Merge Danger Section — Plan

## Objective

Add a `Merge danger` section to the three reports the user reads before
letting a batch out: task-implement's final report (Schema G), task-review's
final report (Schema F), and the autopilot's final message. The section tells
the user, in plain words, which changes cannot be undone and how far a
failure would reach, and every claim in it names the file and line it rests
on.

In scope:

- One canonical block, `canonical:merge-danger`, byte-identical in
  `skills/task-implement/SKILL.md`, `skills/task-review/SKILL.md`, and
  `skills/autopilot/SKILL.md`, defining how the section is built.
- Each carrier's own placement, range, and plan source, outside the block.
- generate-task writing a `Related plan:` line into every task document, so
  the two review skills can read the plan's Risks.
- A guard script holding the block identical and its placement fixed.
- The durable documents this changes.

Out of scope:

- Any new gate. The section is information; it changes no verdict, adds no
  question, and leaves the autopilot's `Standalone review: auto` trigger as
  it is.
- Branches, worktrees, and merges. The section is shaped so a later change
  that introduces them can add a row for the merge itself (Technical
  Approach, "Room to grow"); nothing is written for them now.
- A new agent. The orchestrating session writes the section.
- Changes to `/kenspc-init`'s templates.

## Background

Matt Pocock's `pr` skill (github.com/mattpocock/skills,
`skills/engineering/pr/SKILL.md`, v1.3) asks every pull request for a Merge
Danger section: whether the change is a one-way or a two-way door — Bezos's
distinction, in his 2015 shareholder letter, between irreversible and
reversible decisions — and its blast radius. It is a format reference only;
nothing enforces it. A 2026-10-17 blog post rewrote it as three consequence
questions for a reviewer who cannot read code: does what users see or do
change; if it breaks, can it be undone in one step; who does a failure reach.
The user's global instructions already ask, when summarising a set of
changes, what each changes in practice.

kenspc opens no branches, so its decision points are not a PR merge but the
autopilot's final stop and the final reports of `/kenspc-task-implement` and
`/kenspc-task-review`. Risk is judged earlier and then lost:

- generate-plan's `Risks and Mitigations` element
  (`skills/generate-plan/SKILL.md:270`), written only when it applies;
- task-implementer's AUTONOMY BOUNDARIES (`agents/task-implementer.md:204`),
  which stop on a new dependency, an API contract change, a schema change,
  or a configuration change;
- the autopilot's note that a batch the user judges risky — security, a data
  migration, concurrency — is written `Standalone review: on`
  (`skills/autopilot/SKILL.md:1502`).

No final report says which of the batch's changes are one-way doors.

Facts verified against the current files on 2026-10-20 that shape the design:

- Schema G is task-implement's Step 4 (`skills/task-implement/SKILL.md:711`);
  Schema F is task-review's Step 8 (`skills/task-review/SKILL.md:631`). Both
  end `## Verdict`, then `## Next steps`.
- The autopilot asks no release question. Its final message holds
  `## User report` (the conversation's language, at most one page, the
  main-session rulings list not counted), `## Reviewer report` (English,
  fixed fields), and a sentence that the tag, the push, and the release are
  the user's (Phase 4, The reports; Exit).
- A task document does not name its plan: `generate-task` writes no such
  line, although `references/task-document-example.md:15` carries
  `Related plan: \`docs/plans/auth-plan.md\``.
- `/kenspc-init` writes `docs/deployment.md` with `## Migrations` and
  `## Rollback` sections (`skills/init-project/templates/deployment.md.tmpl`).
- task-review records its range in `RUN_DIR/change-set.md` for a "changes"
  run only; a "task" run has no recorded range. code-fixer already finds a
  task document's batch by the oldest commit that added it
  (`agents/code-fixer.md:202`).

## Technical Approach

### Decisions settled in discovery

1. **One canonical block, three carriers.** The block holds the rules for
   building the section; the guard holds the rule text identical, not the
   rendered output. The rendered section follows its report's language:
   Schema G and Schema F follow the conversation, the autopilot's copy sits
   in the User report. Fixed in English in every language: the heading
   `Merge danger`, the labels `one-way`, `two-way`, `unclear`, and the
   signal names; everything else — the header's field names, the three
   questions, `Evidence:` — follows the report's language. Why: a fixed
   heading and fixed labels are what a grep, a guard, and the
   reviewer-report count can find.
2. **The orchestrating session writes it**, before the final report, with no
   new agent. Why: the work is a `git diff --name-status`, a read of the
   signal-matched files, and a read of two documents; a dispatch costs more
   than it does.
3. **One row per change that matches a signal; one catch-all `two-way` row
   for the rest.** The catch-all's evidence is the list of signals checked,
   the range, and each signal's count of zero — never "low risk".
4. **The project's own one-way doors come from its deployment document**: the
   one the project's instruction files name, otherwise `docs/deployment.md`.
   Its `## Migrations` and `## Rollback` sections answer "can it be undone in
   one step", and every path it names is a signal. No new file, no template
   change. Without a deployment document, the built-in signals alone, and the
   section's header says `Deployment document: not found`.
5. **Placement in Schema G and Schema F**: after `## Verdict`, before
   `## Next steps`.
6. **The autopilot carries it in three places**: a `### Merge danger`
   subsection of the User report over `<baseline sha>..<last sha>`, outside
   the one-page limit as the rulings list is; a reviewer-report field
   `Merge danger: <n> one-way, <u> unclear, <m> two-way`; and, when `<n>` or
   `<u>` is above zero, the closing sentence that leaves the tag, push, and
   release to the user also says how many changes cannot be undone and
   points at the section.
7. **A third label, `unclear`**, for a change whose evidence does not settle
   it; the row names the missing evidence, and the counts and the closing
   sentence count it with `one-way`. Why: without it, a model that lacks the
   evidence guesses `two-way`.
8. **generate-task writes `Related plan: \`<PLAN_PATH>\``** in each task
   document's Context, the path repository-relative. The review skills read
   the plan from that line; a task document without it gets
   `Plan: none named` in the header, with no guess from file names. A named
   plan that does not exist at HEAD — a shipped plan is deleted — gets
   `Plan: <path> (not found)`, and `plan-risk` has no input. The line stays
   `Related plan:` in English whatever the task document's language, as the
   other parsed anchors do.

### The definition (the canonical block's content)

The block states, each rule with its Why:

- **Inputs.** The run's range (each carrier names it outside the block); the
  deployment document (decision 4); the plan's `Risks` section — the plan the
  carrier names, its section whose heading begins `## Risks` — or none.
- **Signals**, each with a fixed English name, checked over the whole range:

  | Signal | Read from | Matches |
  |---|---|---|
  | `schema` | `git diff --name-status` and the files | a path the deployment document's Migrations section names, a path with a `migration` or `schema` segment, or a changed file holding DDL |
  | `removal` | `--name-status` and removed lines | a path with status `D` or `R`; a removed line that declared a public symbol, a field, a column, or a route |
  | `contract` | the changed files | a file that defines what another program calls or reads: routes and handlers, OpenAPI, GraphQL, or protobuf schemas, a package's exported entry point, a CLI's flags, a webhook or message format |
  | `config` | `--name-status` | configuration, an environment example, a CI workflow, a container or infrastructure file |
  | `dependency` | `--name-status` | a package manifest or lock file |
  | `outside-write` | added lines | code that writes data outside the repository: a database, a queue, an external API, a file outside the working tree, a message or email sent |
  | `deploy-doc` | the deployment document | a path or rule the document names that the range touches |
  | `plan-risk` | the plan's Risks | a risk whose subject a changed file touches |

  The block says which signals are matched on paths (`schema`'s path part,
  `removal`'s statuses, `config`, `dependency`, `deploy-doc`) and which on
  content the session reads (`contract`, `outside-write`, `plan-risk`, the
  content parts of `schema` and `removal`), and the catch-all row keeps
  that split visible. Why: a path match can be checked by re-running it; a
  content judgement can only be checked by reading the evidence, so the
  reader needs to know which is which.
- **Reading.** `git diff --name-status <range>` first, then
  `git diff -U0 <range>` for the added and removed lines only. A range too
  large to read in full gets an `unclear` row naming the files not read,
  never a `two-way` for them. Why: the orchestrating session has a context
  to protect, and a file nobody read cannot be called reversible.
- **Labels.** `two-way`: one `git revert` of the change's commits (or a
  discard of an uncommitted change), followed by the project's usual
  release, restores the state before the change, with no data lost and
  nobody outside the team needing to act. `one-way`: it does not. `unclear`:
  the evidence read does not settle it; the row names what would.
- **Rows.** One per change that matched a signal. A change may span several
  files; its row lists them all. Each row: the label; the change in plain
  words; three answers in the report's language — what users see or do
  differently, whether it can be undone in one step and why, who a failure
  reaches (this machine only, the team, the product's users, or people and
  systems outside it); one short technical line; and `Evidence:` with the
  signal name and each `file:line` it rests on. A row without a `file:line`
  is not written. Why: a door named without evidence cannot be checked, and
  the user decides from this section alone.
- **Catch-all.** The last row, `two-way`, covers every changed file no
  signal matched: the file count, the range, and each signal with its count.
- **Header.** `Range: <range> (<how chosen>)`,
  `Deployment document: <path | not found>`,
  `Plan: <path | <path> (not found) | none named>`,
  then `Count: <n> one-way, <u> unclear, <m> two-way`.
- **Empty range.** The section is one line: `none — the range holds no
  change`.
- **Not a gate.** The section changes no verdict and asks nothing. Why: the
  reports already gate on correctness; this section informs the decision to
  let the batch out, which stays the user's.

Rendered, a section reads:

```
## Merge danger

Range: 3f2a1c0..9b7e4d2 (since the task document was added) · Deployment document: docs/deployment.md · Plan: docs/plans/auth-plan.md
Count: 1 one-way, 1 unclear, 2 two-way

1. `one-way` — the users table loses its legacy_token column
   - What users see or do: nothing changes for them
   - Undo in one step: no — the migration drops the column and its data; docs/deployment.md § Rollback restores code only
   - Who a failure reaches: every user who still signs in with a legacy token
   - Detail: migration 0042 drops users.legacy_token
   - Evidence: schema, removal — db/migrations/0042_drop_legacy_token.sql:3, docs/deployment.md:41
2. `unclear` — the session cookie's lifetime moves to configuration
   - …
   - Missing evidence: whether production sets SESSION_TTL; .env.example:12 does not say
   - Evidence: config — src/config.ts:18, .env.example:12
3. `two-way` — the login form's error text
   - …
   - Evidence: contract — src/routes/auth.ts:40
4. `two-way` — every other change (7 files): no signal matched in 3f2a1c0..9b7e4d2 — paths: schema 0, removal 0, config 0, dependency 0, deploy-doc 0; content: contract 0, outside-write 0, plan-risk 0
```

### Each carrier, outside the block

- **task-implement and task-review's "task" run** share one rule: the range
  is `<the oldest commit that added TASK_FILE>..HEAD` at the time the report
  is rendered, the commit found as code-fixer finds it
  (`git log --diff-filter=A --reverse --format=%H -- <TASK_FILE> | head -n 1`).
  A task document no commit added gets the header
  `Range: not determined — no commit added the task document` and one
  `unclear` row saying so. The plan is the task document's `Related plan:`
  path. Why the document's whole history, not this run's commits: a task
  document implemented across several runs leaves as a whole, and
  `/kenspc-task`'s reviewer and `/kenspc-diagnose` both commit the document
  before any implementation, so the rule finds the batch's start without a
  new pin. With every task BLOCKED, task-implement still renders the
  section.
- **task-review's "changes" run** uses `RUN_DIR/change-set.md`'s `Range:`
  or, for `Mode: uncommitted`, its `Base:` against the working tree — the
  fixes included, since they are part of what leaves. In an uncommitted run,
  `git diff --name-status <Base>` lists no untracked file, so the file list
  is `git -c core.quotePath=false status --porcelain -uall` with paths under
  `.kenspc/` dropped, as Step 1 reads it; tracked files are read with
  `git diff -U0 <Base> -- <path>` and untracked files whole. The plan is
  `none named`.
- **autopilot.** In Phase 4, after the temp-entry removal and before the
  reports, the main session builds the section over
  `<baseline sha>..<last sha>`, with the spec as the plan
  (`git show <hash>:<path>`, the reviewer report's Spec line, since S6 may
  have removed it) and the deployment document read at the last sha. It
  writes the section to `_logs/<batch>-merge-danger.md` and a state-file
  line `merge danger: <n> one-way, <u> unclear, <m> two-way — <that path>`;
  both reports are built from these, as the reviewer report is built from
  the state file. Why: the reports are written after a long batch whose
  conversation may have been compacted; the file is what survives. The
  batch's own documents that S6's removal or release commit `git rm`s — a
  spec committed before the baseline, a tracked brief — show as `D` in the
  range; they match no signal and are counted in the catch-all row, which
  names them. Why: every spec-entry batch removes its spec by design, and a
  `removal` row for it would sit in every report; the task documents S2
  added and S6 removed leave no trace in the range.

### Room to grow

A row's subject is "a change in the range". A later change that introduces
branches or worktrees adds the merge as one more row, or a header line
naming the merged branch, without changing the labels, the questions, or the
evidence rule. Nothing is written for it now.

### Guard

`scripts/check-merge-danger-canonical.sh`, bash 3.2-safe like the other
guards:

1. Byte-identity of the `canonical:merge-danger` block across the three
   SKILL.md files.
2. Anchors inside the block, each at least once: `one-way`, `two-way`,
   `unclear`, `Evidence:`, `not found`, `none named`.
3. Placement: in task-implement's Schema G and task-review's Schema F
   templates, a `## Merge danger` line after `## Verdict` and before
   `## Next steps`; in the autopilot's reviewer-report template, a
   `- Merge danger:` field.
4. `--self-test`: copy the three files to a temp workdir, pass; change one
   word inside the block of one copy (must fail: byte-identity); replace an
   anchor inside the block identically in all three copies (must fail: the
   anchor check alone, since the copies still match); move
   `## Merge danger` after `## Next steps` in one copy (must fail:
   placement); revert each mutation before the next (must pass). Why the
   anchor mutation in all three copies: in one copy it fails byte-identity
   first, and the anchor check would never be shown to fail.

`check-all.sh` picks it up by its name; the release checklist's counts move
from `guards run: 15` / `self-tests run: 14` to `16` / `15`.

## Implementation Steps

1. **Write the block and Schema F (task-review).** Add the
   `canonical:merge-danger` block to `skills/task-review/SKILL.md` Step 8,
   holding every rule under "The definition", each with its Why; add
   `## Merge danger` to the Schema F template between `## Verdict` and
   `## Next steps`; add, outside the block, task-review's range and plan
   rules for both kinds of run.
   - Input: this plan's Technical Approach.
   - Output: the edited SKILL.md.
   - Acceptance: the block holds all eight signal names, the Reading rule,
     the three labels, the one-step definition, the row and catch-all formats, the header, the
     empty-range line, and the not-a-gate rule; Schema F lists the heading
     between `## Verdict` and `## Next steps`; the range rule covers
     "changes" (both modes) and "task" runs, including a task document no
     commit added.
2. **Schema G (task-implement).** Copy the block byte for byte into
   `skills/task-implement/SKILL.md` Step 4; add the heading to Schema G at
   the same place; add the task-run range and plan rule outside the block,
   worded as task-review's "task" run rule. Depends on step 1.
   - Acceptance: `diff` of the two blocks is empty; the range rule names the
     oldest commit that added TASK_FILE and the not-determined case; the
     all-BLOCKED case is stated.
3. **The autopilot.** Copy the block into `skills/autopilot/SKILL.md`
   Phase 4; add the build step (range, spec via `git show`, the
   `_logs/<batch>-merge-danger.md` file, the state-file line and its entry
   in § The state file's template and its prose list of what the file
   holds; Phase 4's **Inputs** and **DONE when** name the file and the
   line; the exclusion of the batch's own removed documents); the User report's
   `### Merge danger` subsection, outside the one-page limit; the reviewer
   report's `- Merge danger:` field in § The reviewer report; the closing
   sentence's count in Phase 4, Exit, and the gates table's final-gate row.
   Depends on step 1.
   - Acceptance: the block is identical to step 1's; the closing sentence
     names the count only when `one-way` plus `unclear` is above zero; the
     reviewer report states the field is read from the state-file line.
4. **generate-task's `Related plan:` line.** In
   `skills/generate-task/SKILL.md` Phase 2, the task document's Context
   carries `Related plan: \`<PLAN_PATH>\``, the path repository-relative,
   with a Why naming the reader (the review skills' Merge danger section);
   Phase 2's **Document language** paragraph adds `Related plan:` to the
   anchors that stay exactly as written. Independent of steps 1–3.
   - Acceptance: Phase 2's DONE list names the line; its form matches
     `references/task-document-example.md:15`; the Document language
     paragraph lists it among the parsed anchors.
5. **The guard.** Write `scripts/check-merge-danger-canonical.sh` as under
   "Guard". Depends on steps 1–3.
   - Acceptance: `bash scripts/check-merge-danger-canonical.sh` exits 0;
     `--self-test` exits 0 and its three mutations each fail the main check;
     `bash scripts/check-all.sh --self-test` prints `guards run: 16` and
     ends `self-tests run: 15`.
6. **Doc-sync.** The documents under Documentation impact. Depends on
   steps 1–5.

## Documentation impact

- `plugins/kenspc/README.md` § Skills table — the task-implement and
  task-review rows name the Merge danger section; the generate-task row
  names the `Related plan:` line (steps 1, 2, 4).
- `plugins/kenspc/README.md` § Autopilot, "The reports" paragraph — the User
  report's `### Merge danger` subsection outside the page limit, the
  reviewer report's `Merge danger` field, and the closing sentence's count
  (step 3).
- `plugins/kenspc/README.md` § Recommended Workflow — a `**Merge danger.**`
  paragraph beside the existing Setup, Prototype, Documentation, and Bug path
  paragraphs: the three questions, the labels and the one-step definition,
  the signals, the deployment document, the `Related plan:` line, and that
  it is not a gate (steps 1–4).
- `AGENTS.md` § Editing skill and agent content › Skills — a bullet for the
  `canonical:merge-danger` block: three carriers, the guard that holds them,
  and that a change applies to all three in one commit (steps 1–3, 5). The
  file stands at 197 of the 200 lines its `<!-- budget: lines=200 words=2400 -->`
  line allows, and `scripts/check-instruction-lint.sh` fails above it, so
  the bullet takes at most three lines, or is merged into an existing
  bullet.
- `plugins/kenspc/CHANGELOG.md` — a `## 4.13.0 — unreleased` entry for the
  section, the `Related plan:` line, and the guard (all steps).
- `docs/release-checklist.md` § Pre-flight — `guards run: 16`,
  `self-tests run: 15` (step 5); § Smoke checklist rows 5, 6, 7, and 11 —
  row 5 sees the `Related plan:` line; rows 6 and 7 see `## Merge danger`
  between `## Verdict` and `## Next steps`, each non-catch-all row with an
  `Evidence:` line; row 11 sees the User report subsection, the reviewer
  report field, and `_logs/<batch>-merge-danger.md` (steps 1–5).
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: it already carries `Related plan:` in the form step 4 writes.
- `README.md` — N/A for this document: its one-line skill summaries do not
  list report sections.
- `docs/roadmap.md` — N/A for this document: no item covers this work.

## Testing Strategy

- The guard and its self-test (step 5), and `bash scripts/check-all.sh
  --self-test` before every commit under `plugins/` or `scripts/`.
- Smoke rows 6 and 7 on a throwaway seed whose batch adds a migration file
  that drops a column, adds a dependency, and edits a README: the section
  shows a `one-way` or `unclear` row with `schema` and `removal` evidence, a
  row with `dependency` evidence, and a catch-all row whose counts are zero.
  The same seed with a README-only change: the catch-all row alone, every
  count zero. Without `docs/deployment.md`, the header reads
  `Deployment document: not found`.
- Smoke row 11 on a `repo`-mode seed: the three autopilot places, and the
  closing sentence's count present exactly when `one-way` plus `unclear` is
  above zero.

## Risks and Mitigations

- **A catch-all written without looking.** The session could write zeros it
  never checked. Mitigation: path signals are re-runnable, and the
  catch-all separates them from content signals, so a reader can check the
  first kind with one command and knows the second kind rests on reading.
- **Noise.** A batch that touches many configuration files fills the
  section. Mitigation: one row per change, not per file; a change spanning
  files lists them in one row's Evidence.
- **Context cost on large diffs.** Reading every added line for
  `outside-write` costs the orchestrating session context. Mitigation: the
  block's Reading rule — `--name-status` first, then `-U0`, and an
  `unclear` row for files not read, never a guessed `two-way`.
- **The autopilot's one-page User report grows.** Mitigation: the
  subsection is outside the limit, as the rulings list is, because it is
  what the user reads before the tag.
- **Drift between three carriers.** Mitigation: the guard (step 5), and the
  AGENTS.md bullet that a change applies to all three in one commit.

## Open Questions

None.
