# Batch E — Render the Review Once, Doc-sync Documents with the Fix, the Approved Plan Written Verbatim — Task Document

## Context

A review run renders its reports once, a fix that makes a synced document
wrong corrects it in its own commit, and a plan written on approval is the
approved draft. `/kenspc-task-review` and `/kenspc-task-implement`'s review
phase stop rendering the Schema A roll-up, code-fixer's reply, and Schema C
between the dispatches: each intermediate step prints one fixed progress
line, and the three appear once, in Schema F or Schema G. In a review
against a task document whose Doc-sync task is DONE, code-fixer corrects,
in the fix's own commit, each sentence of a listed document that the fix
made false, marks it in the Schema B Action cell, and reports it in one
`Doc-sync documents:` reply line; the final reports turn that line into a
Next steps bullet instead of asking the user to re-check the documents.
generate-plan writes the draft last printed in full, character for
character, and prints the whole draft again for approval after any change.
The plugin README's Known behavior says why a regression a fix brought in
fails the verdict while a deferred MEDIUM does not; the verdict rules are
unchanged. The roadmap's transcript-audit item leaves with one CHANGELOG
sentence: no such script is kept in this repository.

Related plan: `docs/plans/batch-e-review-pipeline.md`. The plan is the
complete specification. Its locked design (E-1 to E-6) and its Design
decisions (M1–M13, D1–D19) are binding rulings. Every ruling takes the
draft's lean, except that D1 has each progress line open with the name of
the agent that returned and M12 adds one attempt at the live case in the
acceptance. Four rulings read a locked point beyond its literal words — M1
(E-1's "statistics line and Schema B path" names code-fixer's whole reply),
M4 (E-2's bullet also in Schema F), M13 (E-5's reprint on the resume path),
and D17 (README sentences for E-1, E-2, and E-5) — and every task follows
the ruling. Two gaps are left out of scope by ruling and have no task here:
Schema D's double render in `/kenspc-task-implement` (M2) and
`code-fixer.md`'s absence from `check-doc-sync-anchors.sh`'s `Doc-sync`
group (M8); both are recorded under the plan's Risks. The plan's
Clarifications during implementation hold none yet.

The labels this document cites (E-n, M-n, D-n rows, "ruling") are pointers
into the plan for the implementer. None of them is copied into a plugin
file (plan § Standing constraints; the pointer-label grep below).

Each task below cites its plan Step, which is the canonical source for what
to write; where the plan gives a paragraph "in substance", that paragraph is
the text to adapt. The criteria listed here are the local DONE bar.

Fixed forms. Every task that states one of these uses it exactly as written
here (plan § Fixed strings):

- Progress line, reviewers:
  `Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`
- Progress line, code-fixer:
  `code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`
- Progress line, regression-verifier: `regression-verifier returned — CLEAN`,
  or
  `regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`
- The three progress lines are the same in both skills and stay in English
  whatever the conversation language. Each is written on one line of the
  skill file, unwrapped, so `grep -F` finds it.
- Schema B Action suffix: `FIXED — updated <path>[, <path>]`;
  `FIXED — not updated <path>: <reason>`; several joined by `; `.
- Reply line:
  `Doc-sync documents: updated <path> (row <n>, <commit>)[; …][; not updated <path> (row <n>) — <reason>]`,
  or `Doc-sync documents: none affected by the fixes`.
- Fix commit body line for a corrected document: `Updates <path> to match the fix.`
- No-document bullet: `No Doc-sync document describes behavior the fixes changed.`
- Missing-line bullet (task-implement only): `code-fixer's reply has no Doc-sync documents line`
- Verbatim write: the phrase `character for character`.
- Known behavior item title: `**Regressions and deferred issues in the verdict.**`
- E-3 disposition: the phrase ``read the transcripts with `jq` ``.
- CHANGELOG heading: `## 3.8.2 — unreleased`.
- Roll-up table header (the one Schema F's Review summary carries):
  `| Angle | HIGH | MEDIUM | LOW |`.
- Unchanged: the statistics-line template; `Plan not written: awaiting approval.`;
  `### Task N: Doc-sync`; `guards run: 10`, `self-tests run: 9`.
- Cannot-ask wording: "In a session that cannot ask (a system reminder to
  work without stopping), …".
- Dependency line: `Depends on: Task N`, a range `Task 1-<N>` (ASCII
  hyphen), or a comma-separated list.

Joined text. Several sentences are wrapped across lines, so a line-by-line
grep misses them. Where a criterion says "in the joined text", read the
file with its line breaks joined and its spaces squeezed and count
occurrences, not lines:

```bash
tr '\n' ' ' < <file> | tr -s ' ' | grep -oF '<string>' | wc -l
```

Pointer-label grep (plan § Standing constraints). For every plugin file a
task edits — `plugins/kenspc/skills/task-review/SKILL.md`,
`plugins/kenspc/skills/task-implement/SKILL.md`,
`plugins/kenspc/agents/code-fixer.md`, and
`plugins/kenspc/skills/generate-plan/SKILL.md` — this command prints
nothing:

```bash
grep -nE 'batch [A-Z]\b|dry-run|\bruling\b|\b[BCDE]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' <file>
```

It prints nothing on those four files at `6575540` and 168 lines on this
batch's plan, so it can fail. `grep -nE '\b(MUST|NEVER|CRITICAL)\b' <file>`
also prints nothing on each of them (nothing at `6575540`).

Canonical check against the base (plan § Testing Strategy, mechanical 3).
The guards compare the copies of a canonical block with each other, so an
edit made to both copies at once passes them; this compares each block with
its own text at `6575540`. Write it with the Write tool to
`$TMPDIR/batch-e-canonical-base.sh` (resolve `$TMPDIR` first; the file is
left there) and run it as `bash "$TMPDIR/batch-e-canonical-base.sh"`, never
inline under zsh. It exits 0 and prints `control: mutated block detected`,
twelve `SAME` lines, and `blocks compared: 12, result: PASS`; its control
proves that a one-character change inside a block is detected, and a block
of fewer than three lines at the base is reported `EMPTY`, so a mistyped
marker cannot pass as identical. It passes at `6575540`.

```bash
#!/bin/bash
# Compare every canonical and example block with its copy at the base commit.
# Usage: bash batch-e-canonical-base.sh   (from anywhere inside the repository)
set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
base=6575540
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

Hunk ranges. Where a criterion bounds a task's edits by headings, read the
old start line `a` of every `@@ -a,b +c,d @@` header in
`git diff -U0 -- <file>` (the working tree against HEAD, before the task's
commit), and the headings' line numbers in `git show HEAD:<file>`.

This is plugin revision work. The files are Markdown: two SKILL.md files
and one agent for the review pipeline, generate-plan's SKILL.md, the plugin
README, CLAUDE.md, the CHANGELOG, and the release checklist. The repository
has no test framework: "build / test / lint" for each task is the guard
suite. After each task, run `bash scripts/check-all.sh`, which must exit 0
with `guards run: 10` — capture its exit status on its own line, never
through a pipe (`bash scripts/check-all.sh > <file> 2>&1; rc=$?`), since a
pipe reports the last command's status, not the guard's. Tasks that edit a
skill or agent file also run `claude plugin validate --strict ./plugins/kenspc`
and the canonical check above. Task 3 also runs
`bash scripts/check-all.sh --self-test`, which must print `guards run: 10`
and end with `self-tests run: 9`.

Constraints that apply to every task (plan § Standing constraints):

- No edit inside any byte-identity section, with no exception in this batch:
  the `canonical:run-dir`, `canonical:dispatch`, `canonical:stats-line`, and
  `canonical:verdict-shared` blocks; the code-craft canonical paragraphs
  (`canonical:principle:*`); the five reviewers' six shared sections; and
  the worked example between `code-fixer.md`'s `example:schema-b` markers.
- Zero diff outside the batch's files. After every task, this prints
  nothing:
  `git diff --stat 6575540 HEAD -- plugins/kenspc/agents/requirements-reviewer.md plugins/kenspc/agents/edge-case-reviewer.md plugins/kenspc/agents/quality-reviewer.md plugins/kenspc/agents/bug-reviewer.md plugins/kenspc/agents/test-reviewer.md plugins/kenspc/agents/regression-verifier.md plugins/kenspc/agents/task-implementer.md plugins/kenspc/agents/plan-document-reviewer.md plugins/kenspc/agents/guide-document-reviewer.md plugins/kenspc/agents/task-document-reviewer.md plugins/kenspc/shared plugins/kenspc/references plugins/kenspc/hooks plugins/kenspc/commands plugins/kenspc/skills/generate-brief plugins/kenspc/skills/generate-task plugins/kenspc/skills/generate-guide plugins/kenspc/skills/diagnose-bug plugins/kenspc/skills/prototype plugins/kenspc/.claude-plugin scripts README.md docs/roadmap.md docs/dry-runs/README.md`.
  `generate-plan/SKILL.md` changes only between `### Step 3: Write to file`
  and `## Phase 3: Verify via review agent`. The files this batch touches
  are `task-review/SKILL.md` and `task-implement/SKILL.md` (outside their
  canonical blocks), `code-fixer.md` (outside its canonical and example
  blocks), `generate-plan/SKILL.md` (Phase 2 Step 3), `CLAUDE.md`,
  `plugins/kenspc/README.md`, `plugins/kenspc/CHANGELOG.md`, and
  `docs/release-checklist.md` — not the root `README.md`,
  `docs/roadmap.md`, either manifest, or anything under `scripts/`.
- No new skill, command, agent, CONTEXT key, or guard script.
- `effort:` frontmatter is unchanged in every file, and every skill keeps
  `version: 3.0.0`.
- No version bump: `version` in `plugins/kenspc/.claude-plugin/plugin.json`
  stays `3.8.1`. The CHANGELOG entry goes under `## 3.8.2 — unreleased`
  with no date. `docs/roadmap.md` is not edited: items 1, 2, 3, and 5 leave
  in the release commit (plan § The release commit). No tag, no push.
- Rules are rationale-anchored ("Why: …" prose), with no `MUST` / `NEVER` /
  `CRITICAL`, no effort or reasoning tokens, and no model names
  (`bash scripts/check-no-model-names.sh` exits 0). A check written into a
  skill or agent is in rubric form: what passing looks like, then the named
  ways it fails.
- The one question point this batch adds — the reprint after a change at
  generate-plan's approval stop (Task 5) — has a cannot-ask branch in the
  Fixed-forms wording. The review path asks nothing, and Tasks 1–4 add no
  question.
- Plugin files state their evidence in their own words and carry no pointer
  labels, batch names, or dry-run references (the pointer-label grep).
- Code, comments, commit messages, and documents are in English.
- No task runs `rm -r` or `rm -rf`. The canonical check's script and its
  temporary directories under `$TMPDIR` are left there. Anything else to be
  discarded is moved to
  `~/Projects/_smoke/.trash/<name>-<YYYYMMDD-HHMMSS>/` (created when
  missing). Nothing under `.kenspc/` is deleted.
- No task edits `docs/plans/batch-e-review-pipeline.md`. A task that finds
  a ruling contradicted by the code is marked BLOCKED with the contradiction
  named. After the run ends and Schema G is out, the orchestrating session
  (the one that ran `/kenspc-task-implement`) appends each such
  contradiction under a `## Questions for the spec author` section at the
  end of the plan (creating the section when missing) — one numbered entry
  per question, naming the Step it affects, what the repository shows, and
  what the plan says — commits nothing else, and stops; the spec author
  records the answer as `CL<n>` under the plan's
  `## Clarifications during implementation`.
- Each task is one conventional commit that stages only the files the task
  lists, together with the task's status update:
  - `fix(skills): …` for Tasks 1, 2, 4, and 5;
  - `fix(agents): …` for Task 3;
  - `docs(claude-md): …` for Task 6;
  - `docs: …` for Tasks 7 and 10;
  - `docs(release): …` for Task 8;
  - `docs(changelog): …` for Task 9.

Dependency note: Tasks 1–5 implement plan Phases 1–3. Task 1 carries no
`Depends on`. Task 2 writes the same three progress lines into the other
skill, and its criterion compares them with Task 1's character for
character, so it follows Task 1 (`Depends on: Task 1`). Task 3 carries no
`Depends on`. Task 4 renders the reply line Task 3 defines
(`Depends on: Task 3`). Task 5 is independent of the others. Tasks 1, 2,
and 4 edit `task-review/SKILL.md` and `task-implement/SKILL.md` in
different sections, and Tasks 1 and 4 each add one `CLAUDE.md` sentence;
they are ordered only by the document. Task 6 reads CLAUDE.md through after
the tasks that change what it describes (`Depends on: Task 1-4`). Tasks 7
and 8 document the behavior Tasks 1–5 build (`Depends on: Task 1-5`).
Task 9, the CHANGELOG, names every change the batch makes, the release
checklist's rows included, so it follows Task 8 (`Depends on: Task 1-8`);
the plan lists the CHANGELOG (Step 4.3) before the checklist (Step 4.4),
and the order is reversed here so the entry can describe the rows it names.
Task 10, the Doc-sync task, runs last and needs Tasks 1–9. It reconciles
the documents with what those tasks implemented and promotes their recorded
decisions.

## Tasks

### Task 1: Render the review once in task-review

**Status:** DONE

**Implementation notes:**
- Decisions: each progress line sits alone on its own line in a code span,
  unwrapped, so `grep -F` finds it and the model prints it as a unit; the
  English-only rule is stated once, in Step 4, for all three lines ("This
  line and the lines Steps 5 and 6 print"), rather than repeated in Steps 5
  and 6. Step 6 keys the two regression-verifier forms on Schema C's own
  closing CLEAN / HAS ISSUES line, so a row-3 `SPOT-CHECK` with every other
  check PASS prints the CLEAN form, as regression-verifier's OUTPUT FORMAT
  defines. The CLAUDE.md sentence went in as its own paragraph directly
  after the Parallel MapReduce list (one of the two places the task allows),
  so no existing line of CLAUDE.md changed.
- Changes/tradeoffs: the Step 4 Why says the fixed form "is what the release
  checklist finds in the trace", following the precedent in task-implement's
  Phase 1 boundary Why. The CLAUDE.md sentence names what a progress line
  carries ("the path of its report when it writes one") because
  regression-verifier's line has no path.

Plan Step 1.1 (E-1; rulings M1, M3, D1–D4, M9). In
`plugins/kenspc/skills/task-review/SKILL.md`, Steps 4, 5, 6, and 7, outside
the `canonical:stats-line` and `canonical:verdict-shared` blocks. Steps 1–3,
the delivery check after the dispatch block ("After all 5 agents return,
verify each one delivered …"), and every canonical block stay as they are.

- Step 4 (heading kept: `### Step 4: Aggregate review findings (Schema A roll-up)`),
  in substance: add the five replies' Findings tables into the Schema A
  roll-up — HIGH, MEDIUM, and LOW per angle and in total — and print only
  the line
  `Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`,
  in English whatever the conversation language. The roll-up table is
  rendered once, in the Schema F report. Why: everything the orchestrator
  prints stays in its context for the rest of the run, and the agents'
  replies are already there as their results, so a table printed between
  dispatches is paid for again when the final report prints it; the user
  following the run needs to know which agent returned, its counts, and
  where its report is, and the fixed form, opening with the agent's name,
  lets the release checklist find the line. The table template leaves
  Step 4 (it moves to Schema F, below).
- Step 5: "Render that reply verbatim; the LOW rows and their prose stay in
  the file." becomes: the Schema F report renders that reply verbatim, and
  the LOW rows and their prose stay in the file; when code-fixer returns,
  print only
  `code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`,
  the counts taken from its statistics line. The description of the reply's
  contents and the `Mode: uncommitted` paragraph stay.
- Step 6 (ruling D3): "Render its Schema C result table verbatim:", its
  example table, and the sentence "Below the table, render the Detail prose
  verbatim for each non-PASS row." are replaced, in substance: it returns
  Schema C — the five-check table, a Detail paragraph for each non-PASS row,
  and a closing CLEAN or HAS ISSUES line; the Schema F report renders it
  verbatim; when it returns, print only `regression-verifier returned — CLEAN`,
  or
  `regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`
  naming each non-PASS row. No path: regression-verifier writes no report
  file. The list "The regression agent verifies: …" stays.
- Step 7: the lead-in says Schema F is the one place the roll-up,
  code-fixer's reply, and Schema C are rendered. Review summary (ruling
  M3): the per-angle roll-up table moved from Step 4 — the header
  `| Angle | HIGH | MEDIUM | LOW |`, the five angle rows, and the
  `**Total**` row — in place of "(Schema A roll-up across 5 agents — total
  HIGH / MEDIUM / LOW counts.)". Fixes: unchanged (ruling M1). Verification:
  "(Schema C verbatim: the table and the Detail prose for each non-PASS
  row.)". The Verdict placeholder, Verdict determination, and the Next steps
  paragraph are unchanged here (Task 4 adds one bullet).

In `CLAUDE.md` § Subagent Review Architecture, after the Parallel MapReduce
list or at "the main session relays paths rather than report text" (ruling
M9), one sentence: between the dispatches the orchestrating skill prints
one progress line per step, and the Schema A roll-up, code-fixer's reply,
and Schema C are rendered once, in Schema F or G.

**Files to modify:**
- `plugins/kenspc/skills/task-review/SKILL.md`
- `CLAUDE.md`

**Acceptance criteria:**
- `awk '/^### Step 4:/,/^### Step 7:/' plugins/kenspc/skills/task-review/SKILL.md | grep -c '^|'`
  prints 0 (15 at `6575540`): Steps 4–6 carry no table template.
- `awk '/^### Step 7:/,/^#### Verdict determination/' plugins/kenspc/skills/task-review/SKILL.md | grep -cF '| Angle | HIGH | MEDIUM | LOW |'`
  prints 1 (0 at `6575540`), and `grep -cF` for the same header over the
  whole file prints 1: the template lives in Schema F's Review summary only,
  with its five angle rows and its `**Total**` row.
- Each of `grep -cF 'Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md'`,
  `grep -cF 'code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md'`,
  and
  `grep -cF 'regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]'`
  on the file prints 1, and `grep -cF 'regression-verifier returned — CLEAN'`
  prints at least 1 (each 0 at `6575540`).
- In the joined text, `Render that reply verbatim` and
  `Render its Schema C result table verbatim` occur 0 times (2 together at
  `6575540`); Steps 4, 5, and 6 each say that their table, reply, or
  Schema C is rendered in the Schema F report; Step 4 says the lines stay in
  English whatever the conversation language and carries the Why above;
  Step 7's lead-in names Schema F as the one place all three are rendered.
- Step 5 still describes the reply's contents and keeps the
  `Mode: uncommitted` paragraph; Step 6 keeps "The regression agent
  verifies:" and its four items; Schema F's Fixes placeholder is unchanged.
- Every hunk of `git diff -U0 -- plugins/kenspc/skills/task-review/SKILL.md`
  starts after the line of `### Step 4: Aggregate review findings` and
  before the line of `#### Verdict determination` (304 and 419 at
  `6575540`).
- The canonical check exits 0 with `blocks compared: 12, result: PASS`.
- CLAUDE.md's § Subagent Review Architecture holds the new sentence, and
  `git diff -- CLAUDE.md` changes no other sentence.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the skill, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 2: Render the review once in task-implement

**Status:** DONE

**Implementation notes:**
- Decisions: the three progress lines are copied from Task 1's committed
  text and placed the same way (each alone on a line in a code span, the
  CLEAN form inline); a `diff` of the whole-line forms between the two
  skills is empty. The regression-verifier sentence names Schema C's
  closing CLEAN / HAS ISSUES line in the existing parenthetical, since the
  line choice keys on it. The Why is written for this skill: the run carries
  the implementation phase first, so a table printed between dispatches is
  paid for again in a longer context, and the release checklist finds these
  lines as it finds the Phase 1 boundary lines.
- Changes/tradeoffs: Schema G's Fixes placeholder was reflowed to fit
  "rendered here only" after "verbatim"; its wording is otherwise unchanged.
  Phase 1 Step 5 (Schema D's render) is byte-identical to the base, as the
  task requires; its double render stays out of scope.

Depends on: Task 1

Plan Step 1.2 (E-1; rulings M1, M2, D1–D4). In
`plugins/kenspc/skills/task-implement/SKILL.md`, Phase 2 Step 3 and
Schema G's Code Review, Fixes, and Verification placeholders only. Phase 1
(Step 5's Schema D render included — ruling M2 leaves it), Phase 2 Steps 1
and 2, Schema G's Implementation section and Next steps, and every canonical
block stay as they are.

- Step 3, in substance: aggregate the Schema A Findings tables in the five
  replies into the roll-up and print only
  `Reviewers returned — HIGH <h>, MEDIUM <m>, LOW <l> — <RUN_DIR>/angle-1.md … angle-5.md`;
  the Schema G report's Code Review section renders the table. "Render that
  reply verbatim; the LOW rows and their prose stay in the file." becomes:
  Schema G's Fixes section renders the reply verbatim, and the LOW rows and
  their prose stay in the file; when code-fixer returns, print only
  `code-fixer returned — FIXED <f>, DEFERRED <d>, NOT APPLICABLE <n> — <RUN_DIR>/schema-b.md`.
  "Render Schema C verbatim." becomes: Schema G's Verification section
  renders it verbatim; when regression-verifier returns, print only
  `regression-verifier returned — CLEAN`, or
  `regression-verifier returned — HAS ISSUES: row <k> <result>[, row <k> <result>…]`.
  The lines stay in English whatever the conversation language. The same
  Why as Task 1's Step 4, in this skill's words.
- Schema G: "(Schema A roll-up.)" becomes "(Schema A roll-up — the per-angle
  table, HIGH / MEDIUM / LOW per angle and in total; rendered here only.)";
  the Fixes and Verification placeholders also say "rendered here only".

**Files to modify:**
- `plugins/kenspc/skills/task-implement/SKILL.md`

**Acceptance criteria:**
- The three `grep -cF` commands of Task 1's progress-line criterion print 1
  on this file and on `plugins/kenspc/skills/task-review/SKILL.md` alike,
  and `grep -cF 'regression-verifier returned — CLEAN'` prints at least 1 on
  each: the lines match Task 1's character for character.
- `awk '/^### Step 3: Aggregate and dispatch/,/^### Step 4: Render/' plugins/kenspc/skills/task-implement/SKILL.md | grep -c '^|'`
  prints 0, as at `6575540`: no template is added to Step 3.
- In the joined text, `Render that reply verbatim` and
  `Render Schema C verbatim` occur 0 times (2 together at `6575540`),
  `rendered here only` occurs 3 times (0 at `6575540`), and
  `(Schema A roll-up — the per-angle table, HIGH / MEDIUM / LOW per angle and in total; rendered here only.)`
  occurs once.
- Step 3 says that the Schema G report's Code Review section renders the
  roll-up table, its Fixes section code-fixer's reply, and its Verification
  section Schema C; says the three lines stay in English whatever the
  conversation language; carries the Why of Task 1's Step 4 in this skill's
  words; and still describes the reply's contents ("Its reply carries the
  statistics line, …") and what regression-verifier verifies ("The agent
  verifies that every issue ID is accounted for, …").
- ``grep -cF '(Schema D verbatim, including its `## Decisions needing a home` section.)'``
  on the file still prints 1, and Step 5 of Phase 1 is unchanged.
- Every hunk of `git diff -U0 -- plugins/kenspc/skills/task-implement/SKILL.md`
  starts after the line of `### Step 3: Aggregate and dispatch` and before
  the line `## Verdict` inside Schema G (365 and 420 at `6575540`).
- The canonical check exits 0 with `blocks compared: 12, result: PASS`.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the file, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 3: Have code-fixer correct the Doc-sync documents in the fix commit

**Status:** DONE

**Implementation notes:**
- Decisions: PREREQUISITES item 2 says outright that an entry leaving its
  change to another task document is still a listed document, and why no
  label is read (the heading and `**Status:**` stay English in any language,
  a label can be translated). The FIXING RULES bullet states the dirty
  document case in its own sentence — the `git status --porcelain` bullet's
  rule "applies to the document alone ... the code fix still lands and is
  not deferred for it" — because that bullet, read literally, would DEFER
  the whole fix for any dirty file it touches. The five failure modes are
  introduced as "It fails in five named ways", keeping the rubric form
  (passing, then the named failures). The `action` field spells how several
  suffixes combine: the parts after the one em-dash are joined by `; `.
- Changes/tradeoffs: the existing `action` sentence "so a reason never
  changes the bucket" became "so a reason or a document suffix never changes
  the bucket", so the leading-word rule visibly covers the new suffix. The
  reply-list item carries its Why inside the bullet, leaving the closing
  paragraph (and its "the orchestrator renders this reply verbatim in the
  final report") untouched. The suffix passed the Schema B recount on a copy
  of the worked example (`FIXED — updated README.md` exits 0;
  `UPDATED README.md — FIXED` exits 1 with `unknown action`); the example
  block itself is unchanged.

Plan Step 2.1 (E-2; rulings M5, M6, M7, D6–D11). In
`plugins/kenspc/agents/code-fixer.md`, outside the `canonical:principle:*`,
`canonical:stats-line`, and `example:schema-b` blocks. The frontmatter
(`effort: xhigh` included), PREREQUISITE CHECK, CONTEXT YOU WILL RECEIVE,
INPUTS, the uncommitted-mode bullet of FIXING RULES, and the Why "the
orchestrator renders this reply verbatim in the final report" stay as they
are (ruling M1).

- PREREQUISITES item 2, in substance: with REVIEW_SCOPE "task", read the
  task document for context, and find its Doc-sync task — the section under
  the heading `### Task N: Doc-sync`, up to the next `### ` heading. Note its
  `**Status:**` value and its documents: the path in backticks that opens
  each bullet of its document list (ruling M7 — no label is read, since a
  translated task document can carry a translated label). When the status
  is DONE, those documents are in the fix scope as FIXING RULES says;
  otherwise, and in a "changes" run, no document enters it this way.
- FIXING RULES, a new bullet directly after the uncommitted-mode bullet
  (the one opening ``When `change-set.md` says `Mode: uncommitted` ``) and
  before `- Code, code comments, and commit messages stay in English.` —
  not between the `git status --porcelain` bullet and the uncommitted-mode
  bullet, since the former closes on "the harm the next rule prevents",
  which names the uncommitted-mode bullet, and a bullet inserted between
  them would redirect that reference to the new one. In substance (rulings
  D9, D10, D11, M6): in a "task" run whose Doc-sync task is DONE, after
  each fix, read the parts of each listed document that describe the
  changed code — the sections naming the changed function, option,
  command, message, or file. A sentence, list item, or table row there
  that states the behavior the fix changed is now false: correct it, in the
  document's own language, in the fix's own commit, whose body names the
  document (`Updates <path> to match the fix.`). Change nothing else: no
  new section or paragraph, no text the fix did not make false, no
  behavior the document never described, no document outside the list; a
  listed path with no file is skipped. When the correction needs more than
  that, or the document has uncommitted changes — the dirty-file rule of
  the `git status --porcelain` bullet then applies to the document, which
  is left untouched, while the code fix still lands — record the document
  as not updated, with the reason. Passing: every statement in a listed
  document that a fix made false is corrected in that fix's commit, and the
  document is otherwise unchanged. Named failure modes: a statement the fix
  contradicts left as it was; a correction in a commit of its own; a
  sentence reworded that the fix did not make false; a section or paragraph
  added; a document outside the list touched. Why: the Doc-sync task
  described the code as it stood before the review's fixes, so a fix that
  changes documented behavior makes that document wrong at once; in the
  fix's own commit the correction travels with the change it describes,
  where a note to the user afterwards only moves the gap to the user. The
  limits keep the edit as surgical as the fix: a fix commit that rewrites a
  document hides the fix, and a sentence the fix did not make false is not
  the fix's to change.
- PER-ISSUE OUTPUT CONTRACT, the `action` field (ruling D6): a FIXED action
  that corrected a listed document names it after an em-dash,
  `FIXED — updated <path>[, <path>]`; one that left a listed document stale
  says so, `FIXED — not updated <path>: <reason>`; several are joined by
  `; `. The leading word still classifies the action.
- OUTPUT FORMAT, the reply list (ruling D8): after the statistics line (and
  after the uncommitted line, which cannot occur in a "task" run), in a
  "task" run whose Doc-sync task is DONE, one line
  `Doc-sync documents: updated <path> (row <n>, <commit>)[; …][; not updated <path> (row <n>) — <reason>]`,
  or `Doc-sync documents: none affected by the fixes` — always present in
  such a run, FIXED 0 included; not written to `schema-b.md`, whose last
  line stays the statistics line. Why: the orchestrator reads only this
  reply, which carries no LOW row, and builds Next steps from this line; a
  line that is always present tells a run that checked from one that did
  not.
- DONE CRITERIA gains: in a "task" run whose Doc-sync task is DONE, every
  FIXED row that corrected a listed document, or left one stale, says so in
  its Action cell; each correction is in that row's commit; the reply
  carries the `Doc-sync documents:` line.
- The worked example between the `example:schema-b` markers is not changed
  (ruling D7).

**Files to modify:**
- `plugins/kenspc/agents/code-fixer.md`

**Acceptance criteria:**
- `grep -cF` prints at least 1 on the file for each of:
  `Doc-sync documents: updated <path> (row <n>, <commit>)[; …][; not updated <path> (row <n>) — <reason>]`,
  `Doc-sync documents: none affected by the fixes`,
  `FIXED — updated <path>[, <path>]`,
  `FIXED — not updated <path>: <reason>`, and
  `Updates <path> to match the fix.` (each 0 at `6575540`).
- PREREQUISITES item 2 names the heading `### Task N: Doc-sync`, the
  `**Status:**` value, and the backticked path opening each bullet of the
  document list; `grep -c '\*\*Documents\*\*' plugins/kenspc/agents/code-fixer.md`
  prints 0, as at `6575540`.
- The FIXING RULES bullet sits directly after the uncommitted-mode bullet
  and before `- Code, code comments, and commit messages stay in English.`;
  the `git status --porcelain` bullet is still directly followed by the
  uncommitted-mode bullet, so its closing "the harm the next rule prevents"
  still names that bullet; the new bullet names the dirty-file rule by the
  `git status --porcelain` bullet, not by position; and it holds: the parts
  of the document to read; the correction in the document's own language
  in the fix's own commit; the five limits; the skipped missing path; the
  not-updated branch for a correction that needs more and for a document
  with uncommitted changes, where the code fix still lands; the passing
  statement; the five named failure modes; and its Why.
- The OUTPUT FORMAT reply list has the `Doc-sync documents:` item after the
  statistics line and the uncommitted line, says it is always present in
  such a run with FIXED 0 included and is not written to `schema-b.md`, and
  carries its Why; in the joined text,
  `the orchestrator renders this reply verbatim in the final report` still
  occurs once.
- DONE CRITERIA holds the new bullet.
- No hunk of `git diff -U0 -- plugins/kenspc/agents/code-fixer.md` starts
  before the line `PREREQUISITES` (97 at `6575540`), and none removes or
  changes a line of the uncommitted-mode bullet — the bullet that opens
  ``When `change-set.md` says `Mode: uncommitted` `` and ends ``source file
  to every linter and compiler that walks the run directory.`` (lines
  148–178 at `6575540`).
- The canonical check exits 0 with `blocks compared: 12, result: PASS`.
- The Action suffix passes the Schema B recount (ruling D6): copy the lines
  between the `example:schema-b` markers into two files under `$TMPDIR`; in
  one, replace row 5's Action cell `FIXED` with `FIXED — updated README.md`,
  and `bash scripts/check-run-contract.sh --file <that file>` exits 0; in the
  other, with `UPDATED README.md — FIXED`, and the same command exits 1 with
  `unknown action` (both results hold at `6575540`).
- `bash scripts/check-all.sh --self-test` prints `guards run: 10`, ends with
  `self-tests run: 9`, and exits 0; `check-run-contract.sh` and
  `check-code-craft-canonical.sh` report PASS in it.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the file, `bash scripts/check-no-model-names.sh` exits 0, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 4: Report the fixes' Doc-sync documents in Schema G and Schema F

**Status:** DONE

**Implementation notes:**
- Decisions: Schema G's bullet keys on the task document's Doc-sync task
  being DONE "in this run or before it", since code-fixer applies its rule
  to any DONE Doc-sync task and the orchestrator has read the task document
  in Phase 1; the previous sentence keyed only on a task processed DONE in
  this run. The task-review sentence carries a short Why (this skill never
  reads the Doc-sync task's status, so it keys on the line code-fixer
  writes), keeping the rule rationale-anchored; it sits before the
  `.kenspc/` bullet so that bullet's own Why stays next to it. The CLAUDE.md
  sentence closes the documentation path paragraph, after the dependency
  gate, so no existing line changed.
- Changes/tradeoffs: the Schema G text is several short sentences rather
  than one long one (the line, the none-affected form, the missing-line
  defect, then the Why), each fixed string on one line where it fits.

Depends on: Task 3

Plan Step 2.2 (E-2; rulings M4, D12, M9).

- `plugins/kenspc/skills/task-implement/SKILL.md`, Schema G's Next steps:
  the sentence "When a Doc-sync task was processed DONE in this run and
  code-fixer's statistics line reports FIXED greater than 0, one bullet
  names the Doc-sync task's listed documents to re-check against the fix
  commits — the review's fixes land after the Doc-sync task, so a document
  it synced can already describe pre-fix behavior." is replaced, in
  substance: when the task document's Doc-sync task is DONE and code-fixer's
  statistics line reports FIXED greater than 0, one bullet carries
  code-fixer's `Doc-sync documents:` line — each document the fix commits
  updated, with its row and commit, and each left not updated, with its
  reason, for the user to correct; when the line says
  `none affected by the fixes`, the bullet reads
  `No Doc-sync document describes behavior the fixes changed.`; when the
  reply has no such line, the bullet states the defect —
  `code-fixer's reply has no Doc-sync documents line` — and names the listed
  documents to check against the fix commits, without the word "re-check"
  (ruling D12). Why: the fixes land after the Doc-sync task and code-fixer
  corrects the listed documents in the fix commits; this bullet is where the
  user sees which ones changed, or that none needed to, and a missing line
  means code-fixer did not meet its contract, so the correction may not have
  run. The BLOCKED bullet sentence stays as it is.
- `plugins/kenspc/skills/task-review/SKILL.md`, the Next steps paragraph
  after Verdict determination (ruling M4): one sentence — when code-fixer's
  reply carries a `Doc-sync documents:` line and FIXED is greater than 0,
  one bullet as above, without the fallback (the orchestrator of this skill
  never learns the Doc-sync task's status, so it keys on the line).
- `CLAUDE.md` § Subagent Review Architecture, the documentation path
  paragraph (ruling M9): one sentence — when a review runs against a task
  document whose Doc-sync task is DONE, code-fixer corrects, in the fix's
  own commit, the sentences of the listed documents a fix makes false, and
  the final report names each document it changed.

**Files to modify:**
- `plugins/kenspc/skills/task-implement/SKILL.md`
- `plugins/kenspc/skills/task-review/SKILL.md`
- `CLAUDE.md`

**Acceptance criteria:**
- `grep -n 're-check' plugins/kenspc/skills/task-implement/SKILL.md` prints
  nothing (line 436 at `6575540`).
- In the joined text of `task-implement/SKILL.md`,
  `No Doc-sync document describes behavior the fixes changed.` and
  `code-fixer's reply has no Doc-sync documents line` each occur once, and
  `Doc-sync documents:` and `none affected by the fixes` each at least once;
  `When the Doc-sync task is BLOCKED, one bullet states that its listed documents were not synced, and why.`
  still occurs once.
- In the joined text of `task-review/SKILL.md`,
  `No Doc-sync document describes behavior the fixes changed.` occurs once,
  `Doc-sync documents:` at least once, and
  `code-fixer's reply has no Doc-sync documents line` 0 times.
- Every hunk of `git diff -U0 -- plugins/kenspc/skills/task-implement/SKILL.md`
  starts after the line `## Next steps` inside Schema G and before the line
  of `#### Verdict determination`; every hunk of
  `git diff -U0 -- plugins/kenspc/skills/task-review/SKILL.md` starts at or
  after the line `MEDIUM and LOW issues do not change the verdict but appear in the report.`
  (line numbers read in `git show HEAD:<file>`).
- CLAUDE.md's documentation path paragraph holds the new sentence, and
  `git diff -- CLAUDE.md` changes no other sentence.
- The canonical check exits 0 with `blocks compared: 12, result: PASS`;
  `check-canonical-dispatch.sh`, `check-verdict-shared.sh`, and
  `check-run-contract.sh` report PASS in `bash scripts/check-all.sh`, which
  exits 0 with `guards run: 10`.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on both skills, `bash scripts/check-no-model-names.sh` exits 0, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 5: Write the approved plan verbatim in generate-plan

**Status:** DONE

**Implementation notes:**
- Decisions: the paragraph sits directly under "On approval:", before
  item 1, as one paragraph with its Why, so the verbatim rule is read before
  any of the numbered steps; the language request is named among the
  changes after the last full print, pointing at item 2, and item 2 points
  back ("handled as above"), so the two cannot be read apart. The
  `Plan not written: awaiting approval.` line is spelled unwrapped, and the
  cannot-ask sentence opens with the shared wording.
- Changes/tradeoffs: none beyond the task text — item 1 and the approval
  stop's cannot-ask paragraph are untouched (the hunks against the base
  insert after line 362 and replace lines 373–376 only).

Plan Step 3.1 (E-5; rulings M10, M13, D15). In
`plugins/kenspc/skills/generate-plan/SKILL.md`, Phase 2 Step 3 only —
`effort: xhigh`, Phase 1, Phase 2 Steps 1–2, the approval stop's cannot-ask
paragraph ("In a session that cannot ask …, the run still stops here. …"),
item 1 (the output location and its existing-file branch), and Phase 3 stay
as they are.

- Under "On approval:", before item 1, in substance: the approval covers the
  draft last printed in full — every section, none elided or summarized —
  and the file is that draft, character for character: no rewording, a
  pronoun included, no reformatting, and no change to escapes or special
  characters (an escape stays the characters that spell it). A change after
  that print — one the self-challenge finds, one shown only as a revised
  section, or one the approving reply itself asks for — is made to the
  draft, which is printed again in full and approved again before anything
  is written. In a session that cannot ask (a system reminder to work
  without stopping), that print ends with `Plan not written: awaiting approval.`
  and the run stops again, and an approval given on resume writes the draft
  that run's last message printed. Why: the written plan is the approved
  plan — Phase 3's reviewer commits it unchanged before its first fix, and
  generate-task decomposes it — so an edit made after approval, however
  small, reaches the repository as approved when the user never saw it. A
  plan written after an approval has differed from the draft approved in
  the same session in seven of 355 lines: pronouns reworded, a
  Documentation impact line reformatted, and an escape written as the
  character it stands for.
- Item 2 (ruling M10): the document language is the draft's, set by Step 1's
  writing rules when it was drafted; a request for another language at
  approval is a change, handled as above. The lines "a. If the user
  specified a language, use it." and "b. Otherwise, default to English."
  go.
- Item 3: "Write the plan to the file: the approved draft, as printed."

**Files to modify:**
- `plugins/kenspc/skills/generate-plan/SKILL.md`

**Acceptance criteria:**
- `grep -c 'character for character' plugins/kenspc/skills/generate-plan/SKILL.md`
  prints at least 1 (0 at `6575540`), inside Phase 2 Step 3.
- In the joined text,
  `In a session that cannot ask (a system reminder to work without stopping)`
  occurs 5 times (4 at `6575540`), and
  `grep -cF 'Plan not written: awaiting approval.' plugins/kenspc/skills/generate-plan/SKILL.md`
  prints 2 (1 at `6575540`): the new sentence spells the line unwrapped.
- The new paragraph names, in its own words: the draft last printed in full
  as what the approval covers; no rewording (a pronoun included), no
  reformatting, and no change to an escape or special character; the three
  sources of a change after that print (the self-challenge, a revised
  section shown alone, the approving reply's own request) and the language
  request of item 2, each reprinted in full and approved again before
  anything is written; the cannot-ask branch; and the Why with its evidence
  in its own words.
- `awk '/^### Step 3: Write to file/,/^## Phase 3: Verify via review agent/' plugins/kenspc/skills/generate-plan/SKILL.md | grep -c 'default to English'`
  prints 0 (1 at `6575540`), while Step 1's writing rule
  `Default language: English (unless the user explicitly requests otherwise).`
  still occurs once in the file;
  `grep -cF 'Write the plan to the file: the approved draft, as printed.'`
  prints 1.
- Every hunk of `git diff -U0 6575540 -- plugins/kenspc/skills/generate-plan/SKILL.md`
  starts after line 340 (`### Step 3: Write to file`) and before line 380
  (`## Phase 3: Verify via review agent`), and none removes or changes a
  line of the approval stop's cannot-ask paragraph (lines 344–359) or of
  item 1 (lines 363–372).
- `grep -c '^effort: xhigh$' plugins/kenspc/skills/generate-plan/SKILL.md`
  prints 1.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the file, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 6: Read CLAUDE.md through against the rendering and Doc-sync changes

**Status:** TODO

Depends on: Task 1-4

Plan Step 4.1 (ruling M9). The two CLAUDE.md sentences were made in the
commits of Tasks 1 and 4. Read `CLAUDE.md` top to bottom against the
behavior Tasks 1–4 built — in particular § Subagent Review Architecture's
documentation path paragraph, its Parallel MapReduce list, the paragraph on
the run directory ("the main session relays paths rather than report
text"), the CONTEXT block contract, and the standalone safety
classification — and fix a sentence those two missed only when it is false
or silent about where the reports are rendered or what code-fixer does with
the Doc-sync documents. Name each such sentence in the commit message. When
none is missed, the commit holds only this task's status update and
Implementation notes, and its message says so. Guard counts are unchanged,
so § Repository scripts/ and every stated count stay as they are.

**Files to modify:**
- `CLAUDE.md` (only if the read-through finds a sentence Tasks 1 and 4
  missed)

**Acceptance criteria:**
- § Subagent Review Architecture says where the reports are rendered (one
  progress line per step between the dispatches; the roll-up, code-fixer's
  reply, and Schema C once, in Schema F or G) and what code-fixer does with
  the Doc-sync documents (corrects, in the fix's own commit, the sentences a
  fix makes false; the final report names each document changed).
- No sentence in CLAUDE.md contradicts either, read top to bottom.
- The Implementation notes list each sentence checked, and either the
  missed sentence fixed (also named in the commit message) or "none found".
- `git diff 6575540 -- CLAUDE.md` touches only § Subagent Review
  Architecture, and the reviewer invariant sentence in it is unchanged
  (`check-run-contract.sh` check 6 reports PASS in
  `bash scripts/check-all.sh`, which exits 0 with `guards run: 10`).

---

### Task 7: Document the batch in the plugin README

**Status:** TODO

Depends on: Task 1-5

Plan Step 4.2 (rulings D13, D17). In `plugins/kenspc/README.md`, four
places only:

- § Run directory, the first bullet below the tree ("The final report shows
  code-fixer's statistics line, …") (E-1): one sentence — between the
  agents the run prints one progress line per step, and the roll-up,
  code-fixer's reply, and the verification table appear once, in the final
  report.
- § Recommended Workflow, the Documentation path paragraph (E-2): its last
  sentence ("Because the review's fixes land after the Doc-sync task, a run
  where both happened ends with a Next steps bullet naming the listed
  documents to re-check against the fix commits.") is replaced, in
  substance: when the review's fixes change behavior a listed document
  describes, code-fixer corrects that document's sentence in the fix's own
  commit and changes nothing else in it; the final report names each
  document the fixes changed, one left not updated with the reason, or says
  none was affected.
- § Skills, the `generate-plan` row (E-5): one sentence — the plan written
  on approval is the draft as last printed in full, character for
  character; a change asked for at approval gets the full draft printed
  again, to approve.
- § Known behavior, a new item directly before "Red interval after a
  diagnosis" (E-4, ruling D13), in substance:
  **Regressions and deferred issues in the verdict.** The verdict is FAIL
  when the fixes "introduced unresolved regressions", whatever a
  regression's severity, while "MEDIUM and LOW issues do not change the
  verdict but appear in the report." The asymmetry is deliberate: a
  regression is damage this run did to code that worked before it, which
  the run's own changes caused and a revert of those changes undoes; a
  deferred issue was in the code before the run, is reported with its
  reason, and is yours to schedule. The verdict is not graded by severity.

**Files to modify:**
- `plugins/kenspc/README.md`

**Acceptance criteria:**
- `grep -n 'Regressions and deferred issues in the verdict' plugins/kenspc/README.md`
  finds one line, the item's title spelled
  `**Regressions and deferred issues in the verdict.**`, and it is the
  Known behavior item directly before `**Red interval after a diagnosis.**`.
- The item quotes both rule sentences: in the README's joined text,
  `introduced unresolved regressions` and
  `MEDIUM and LOW issues do not change the verdict but appear in the report.`
  each occur at least once; in the skills' joined text,
  `introduced unresolved regressions` occurs in `task-review/SKILL.md` and
  in `task-implement/SKILL.md`, and the MEDIUM and LOW sentence in
  `task-review/SKILL.md` (each once at `6575540`; the verdict rules are not
  edited). The item gives the reason for the asymmetry and says the verdict
  is not graded by severity.
- `grep -c 're-check' plugins/kenspc/README.md` prints 0 (1 at
  `6575540`), and the Documentation path paragraph's last sentence states
  the correction in the fix's own commit, nothing else changed in the
  document, and the final report naming each document changed, one left not
  updated with its reason, or none affected.
- § Run directory's first bullet holds the progress-line sentence;
  `grep -c 'character for character' plugins/kenspc/README.md` prints at
  least 1 (0 at `6575540`), in the `generate-plan` row.
- Every sentence the task adds agrees with the skill and agent text as
  committed by Tasks 1–5, and `git diff 6575540 -- plugins/kenspc/README.md`
  touches only those four places.
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`
  (`check-run-contract.sh` check 6 reads the reviewer invariant sentence in
  this file).

---

### Task 8: Add the batch's criteria to release-checklist rows 4, 6, and 7

**Status:** TODO

Depends on: Task 1-5

Plan Step 4.4 (rulings D5, D14, D19). In `docs/release-checklist.md`, rows
4, 6, and 7 of the smoke table only; no new row, and the pre-flight block
and its counts (`guards run: 10`, `self-tests run: 9`) are unchanged. In a
table row, each literal `|` is written `\|`, inside a code span too, so the
row keeps its three cells.

- Row 4 (E-5, ruling D14), appended to its criterion, in substance: the
  plan as first written — the Write call's `content` in the trace, and its
  blob in `plan-document-reviewer`'s first commit — against the draft that
  the last message before the approval printed in full. Both are normalized
  the same way and no further: CRLF is read as LF, and trailing newlines at
  the very end are dropped; a U+FEFF is a character, an escape is the
  characters that spell it, and trailing spaces on a line count. The draft
  taken from the transcript and the file differ in nothing (after the
  normalization above), character for character: the file's text occurs as
  one block of that message, the message's text outside the block holds no
  line of the plan, and a one-character edit to a copy of the file makes the
  comparison fail. A changed pronoun, a reformatted line, or an escape
  written as the character it stands for fails it. An approving reply that
  asks for a change gets the full revised draft again, with no Write in
  that invocation, and the file is then that draft.
- The E-1 criterion (ruling D5, with the progress lines' openings), written
  into rows 6 and 7: in the session's assistant content, in order, after the
  five reviewer Agent calls return, a line opening `Reviewers returned — `
  comes before the code-fixer call; after code-fixer returns, a line opening
  `code-fixer returned — ` comes before the regression-verifier call; after
  regression-verifier returns, a line opening
  `regression-verifier returned — ` comes before the final report; no text
  line begins with `\|` from the first reviewer call until the final
  report's first heading; and across all the session's assistant text, the
  roll-up header (`\| Angle \| HIGH \| MEDIUM \| LOW \|`), a line holding
  `total reported `, and the Schema C header (`\| # \| Check`) each occur
  exactly once, inside the final report.
- Row 6 (E-1, E-2): "then Schema A → B → C → G" becomes the E-1 criterion
  with Schema G as the final report. The re-check criterion ("when a
  Doc-sync task is DONE and code-fixer's statistics line reports FIXED
  greater than 0, Next steps has one bullet naming the listed documents to
  re-check against the fix commits") is replaced: when the Doc-sync task is
  DONE and a fix changes behavior a listed document describes, that fix's
  commit also changes the sentence that described it and nothing else in
  the document, its Schema B Action reads `FIXED — updated <path>`,
  code-fixer's reply carries
  `Doc-sync documents: updated <path> (row <n>, <commit>)`, and Next steps
  has one bullet naming that document and row; with FIXED greater than 0
  and no listed document affected, no fix commit touches a listed document
  and the bullet reads
  `No Doc-sync document describes behavior the fixes changed.`; the final
  report asks nobody to re-check the documents.
- Row 7 (E-1, E-2): "then the Schema A roll-up, B, C, and the Schema F final
  report" becomes the E-1 criterion with Schema F as the final report; with
  no task document, code-fixer's reply has no `Doc-sync documents:` line and
  no Action cell carries the document suffix.

**Files to modify:**
- `docs/release-checklist.md`

**Acceptance criteria:**
- `grep '^| 4 |' docs/release-checklist.md | grep -cF 'character for character'`
  prints 1 (0 at `6575540`), and row 4 names the Write call's `content`, the
  reviewer's first commit, the normalization (CRLF as LF, final trailing
  newlines dropped, U+FEFF a character, escapes as their characters,
  trailing spaces counted), the containment with the text outside the block
  holding no line of the plan, the one-character control, the three named
  failures, and the reprint when the approving reply asks for a change.
- For each of rows 6 and 7 (`grep '^| 6 |'`, `grep '^| 7 |'`),
  `grep -cF` prints 1 for `Reviewers returned — `, `code-fixer returned — `,
  `regression-verifier returned — `, `\| Angle \| HIGH \| MEDIUM \| LOW \|`,
  `total reported `, and `\| # \| Check` (each 0 at `6575540`).
- Row 6 no longer holds `Schema A → B → C → G` or
  `to re-check against the fix commits`, and holds
  `FIXED — updated <path>`,
  `Doc-sync documents: updated <path> (row <n>, <commit>)`, and
  `No Doc-sync document describes behavior the fixes changed.`.
- Row 7 no longer holds `then the Schema A roll-up, B, C, and the Schema F final report`,
  and holds `Doc-sync documents:` in its no-task-document criterion.
- `grep -E '^\| (4|6|7) \|' docs/release-checklist.md | sed 's/\\|//g' | awk -F'|' '{print NF}'`
  prints 5 on each line, as at `6575540`: no unescaped `|` splits a cell.
- `grep -cE '^\| [0-9]+ \|' docs/release-checklist.md` prints 11;
  `git diff 6575540 -- docs/release-checklist.md` touches only rows 4, 6,
  and 7; the pre-flight block and prose still say `guards run: 10` and
  `self-tests run: 9`.
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`.

---

### Task 9: Write the 3.8.2 CHANGELOG entry

**Status:** TODO

Depends on: Task 1-8

Plan Step 4.3 (E-3, E-4, E-6; ruling D16). In `plugins/kenspc/CHANGELOG.md`,
a new entry directly above `## 3.8.1 — 2026-09-26`, under the heading
`## 3.8.2 — unreleased`:

- Intro paragraph: batch E; what changes, in one paragraph; no new command,
  skill, agent, or CONTEXT key, so a patch release; guard counts unchanged
  (`guards run: 10`, `self-tests run: 9`); and E-3's one sentence: the
  roadmap's transcript-audit item leaves with no change — no such script is
  kept in this repository (`scripts/` holds only the `check-*.sh` guards)
  and since 3.6.0 the acceptance records read the transcripts with `jq`
  directly (`docs/dry-runs/scratch-probes-acceptance.md`); the release smoke
  is the batch's acceptance record, named at release (the record does not
  exist yet).
- `### Changed`:
  - the review renders once — both skills, the three progress lines,
    Schema F's Review summary holding the per-angle table — with its source:
    the roll-up and the agents' replies were printed twice in one run;
  - code-fixer's Doc-sync documents — the scope (a "task" run whose Doc-sync
    task is DONE), the limits, the Action suffix, the reply line, the report
    bullets in Schema G and F, and Schema G's fallback — replacing the 3.6.0
    re-check bullet, with its source: the batch A review's B2;
  - the plan written verbatim — the reprint on any change after the last
    full print, the language set when drafting, and the cannot-ask reprint —
    with its source: the batch D acceptance's O3;
  - release-checklist rows 4, 6, and 7; CLAUDE.md and the plugin README.
- `### Known behavior`: the verdict asymmetry — a regression a fix brought
  in fails the verdict whatever its severity, a deferred MEDIUM does not —
  behavior unchanged; the README's new item says why.
- The heading keeps `unreleased`; the date is filled at release.

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`

**Acceptance criteria:**
- `grep -n '^## 3.8.2 — unreleased$' plugins/kenspc/CHANGELOG.md` finds one
  line, and
  `awk '/^## 3.8.2 — unreleased$/,/^## 3.8.1 — 2026-09-26$/' plugins/kenspc/CHANGELOG.md | grep '^##'`
  prints, in order, the 3.8.2 heading, `### Changed`, `### Known behavior`,
  and the 3.8.1 heading, and nothing else.
- `grep -n 'read the transcripts with' plugins/kenspc/CHANGELOG.md` finds
  the E-3 sentence in the 3.8.2 entry, and in the joined text
  ``read the transcripts with `jq` `` occurs at least once.
- `### Changed` names every item listed above with its source, and spells
  each fixed form it quotes as in the Fixed forms; `### Known behavior` has
  the verdict-asymmetry bullet.
- Every behavior the entry names matches the skill and agent text as
  committed by Tasks 1–5 and the checklist rows of Task 8.
- The 3.6.0 entry is unchanged: `git diff 6575540 -- plugins/kenspc/CHANGELOG.md`
  only adds lines above `## 3.8.1 — 2026-09-26`.
- `grep '"version"' plugins/kenspc/.claude-plugin/plugin.json` still shows
  `3.8.1`.
- `bash scripts/check-all.sh` exits 0 with `guards run: 10`.

---

### Task 10: Doc-sync

**Status:** TODO

Depends on: Task 1-9

Bring the documents below in line with what Tasks 1-9 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` § Subagent Review Architecture (the documentation path
  paragraph; the Parallel MapReduce list or the run-directory paragraph) —
  where the review reports are rendered, and code-fixer's correction of the
  Doc-sync documents in the fix commits (plan Steps 1.1, 2.2, 4.1); edited
  by Tasks 1, 4, and 6: verify it against the implementation instead of
  editing it again.
- `plugins/kenspc/README.md` § Run directory (first bullet), § Recommended
  Workflow (Documentation path), § Skills (`generate-plan` row), § Known
  behavior (the new "Regressions and deferred issues in the verdict" item)
  (plan Step 4.2); edited by Task 7: verify it against the implementation
  instead of editing it again.
- `plugins/kenspc/CHANGELOG.md` — the `## 3.8.2 — unreleased` entry (plan
  Step 4.3); edited by Task 9: verify it against the implementation instead
  of editing it again.
- `docs/release-checklist.md` — rows 4, 6, and 7; pre-flight unchanged
  (plan Step 4.4); edited by Task 8: verify it against the implementation
  instead of editing it again.
- `docs/roadmap.md` — items 1, 2, 3, and 5 leave and the rest are
  renumbered (plan E-6, § The release commit); that change is made in the
  release commit, outside this task document: leave it to the release
  commit.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-9. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-9 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).

---

## Notes

- The plan's Documentation impact records four documents as unaffected:
  the root `README.md`, `docs/dry-runs/README.md`,
  `plugins/kenspc/references/plan-document-example.md`, and
  `plugins/kenspc/references/task-document-example.md`. No task edits them.
- Edit the plugin's skill and agent files in a session started without
  `--plugin-dir` (CLAUDE.md § Test the plugin locally): a `--plugin-dir`
  session treats those files as the definitions it is running, and edits to
  them have been refused there.
- After the last task, the batch's mechanical check is the release
  checklist's pre-flight block — the effort-override diff (unchanged), both
  `claude plugin validate --strict` runs, and
  `bash scripts/check-all.sh --self-test` with `guards run: 10` and
  `self-tests run: 9` — together with the zero-diff command in the
  Constraints, the pointer-label grep on the four plugin files, the
  canonical check, and the text checks of Tasks 4 and 7 (plan § Testing
  Strategy, mechanical 1–5). Acceptance of the live chain runs in a separate
  session (plan § Testing Strategy) and is filed as
  `docs/dry-runs/batch-e-acceptance.md`.
- The release commit (plan § The release commit) is not a task here: it
  moves `plugin.json` to 3.8.2, dates the CHANGELOG heading, and takes
  roadmap items 1, 2, 3, and 5 out, renumbering the rest under the unchanged
  `## Next minor (3.9.0)` heading; no tag.
