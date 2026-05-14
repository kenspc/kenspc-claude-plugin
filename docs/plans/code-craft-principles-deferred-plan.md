# Plan: v3.1.x Code-Craft Principles — Deferred Follow-ups

## Objective

Close the six DEFERRED items from the v3.1.0 (Code-Craft Principles) automated
review without disturbing any of the invariants that v3.1.0 just locked in.
After this work the plugin will: (1) read more fluently in the prose surfaces
that are currently rough; (2) carry a recorded section-header convention that
explains the lone hyphenated header in writer-agent files; (3) gain deeper
drift defenses on the new byte-identity guard script and on `quality-reviewer`'s
two new bullets; and (4) standardize the dry-run report terminology that any
future task-review iteration will reuse — all while preserving the three-file
byte-identity hash on canonical principle blocks, Task 12's four-phrase
relocation grep, and the existing three-script drift-guard suite.

**In scope:**

- Single-line prose rewrite in `plugins/kenspc/shared/code-craft-principles.md`
  (item #15).
- A new short paragraph in the repository-root `CLAUDE.md` documenting the
  writer-agent header convention and the deliberate `CODE-CRAFT PRINCIPLES`
  hyphen exception (item #16).
- A new short subsection in `plugins/kenspc/skills/task-review/SKILL.md`
  defining dry-run report terminology (item #17).
- Extension of `scripts/check-code-craft-canonical.sh` with an anchor-phrase
  frequency check (item #31), plus a coordinated one-line prose addition in
  `plugins/kenspc/agents/task-implementer.md` and
  `plugins/kenspc/agents/code-fixer.md` so the anchor phrases have a survival
  surface outside the byte-identity markers.
- A new `scripts/check-quality-reviewer-bullet-structure.sh` asserting the
  three-numbered-condition shape of the two new `REVIEW CHECKLIST` bullets in
  `plugins/kenspc/agents/quality-reviewer.md` (item #33).
- A `--self-test` flag added to three drift-guard scripts that performs a
  mutation regression test (item #32):
  `scripts/check-code-craft-canonical.sh`, `scripts/check-canonical-dispatch.sh`,
  and the new `scripts/check-quality-reviewer-bullet-structure.sh`.
- Synchronization edit to `docs/release-checklist.md` listing the new checks
  in the pre-flight mechanical-check block.
- `plugins/kenspc/CHANGELOG.md` v3.1.1 entry and
  `plugins/kenspc/.claude-plugin/plugin.json` version bump.

**Out of scope:**

- Any change to the byte-identity-hashed content of the canonical principle
  blocks. The paragraphs between
  `<!-- canonical:principle:*:start/end -->` markers in any of the three files
  must not move.
- Editing the existing v3.1.0 dry-run report
  (`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md`). That document
  is preserved as a historical artifact of Task 16's analysis run; item #17's
  convention applies to *future* reports only.
- Renegotiating Task 12's four-phrase grep contract. The four literal phrases
  (`Do not modify code unrelated to the current task`,
  `Refactor code unrelated`, `Do not introduce new features or refactor`,
  `Preserve the original code's style`) must still grep to 0 matches in
  `plugins/kenspc/agents/` and ≥1 in `plugins/kenspc/shared/`.
- Extending `--self-test` to `scripts/check-review-agent-drift.sh`. That
  script predates v3.1.0 code-craft work and is not part of this brief's
  scope; tracked as an Open Question.
- Any new SKILL or agent CONTEXT-block contract change. The dispatch
  contracts described in each agent's "CONTEXT YOU WILL RECEIVE" section stay
  identical.

## Background

All six items originated from the v3.1.0 automated 5-angle review run on
2026-05-14. The reviewer reports flagged them; the code-fixer agent marked
each as DEFERRED (not "won't fix") because each required either: (a)
renegotiating a v3.1.0 trade-off the implementer and reviewers had agreed to
lock — items #15, #16, #17, or (b) defense-in-depth tooling work that was
not blocking the v3.1.0 ship — items #31, #32, #33.

The brief at `docs/briefs/code-craft-principles-deferred.md` captures the six
items with explicit per-item rationale, the cluster split, the v3.1.0
invariants this work must preserve, and the recommended judgment calls on the
prose/convention items. This plan accepts the brief's recommendations on
Cluster A's three judgment calls (the brief's reasoning is sound and there is
no evidence to re-open them) and adapts Cluster B's three implementation
sketches to the current tree's actual line numbers and file structure.

Two small drifts between the brief's references and the current tree were
detected during planning and are corrected in this plan:

- The brief refers to `shared/code-craft-principles.md:104` for the bullet
  beginning `Refactor code unrelated to the current task is out;`. After the
  `f09de92` commit added the Task-12 guard comment above the bullet block,
  that bullet now sits at line 105. The plan uses the current line.
- The brief's Failure Modes section says the `:end` marker is at line 99 and
  the start marker around line 96-98. The actual markers are at
  `shared/code-craft-principles.md:7` / `:9` (simplicity-first) and `:97` /
  `:99` (surgical-changes). The plan uses the actual markers.

This is a patch release (3.1.0 → 3.1.1). No new user-facing capability, no
breaking change, no SKILL or agent interface change for callers.

## Technical Approach

### Cluster split

The six brief items fall into two natural clusters:

| Cluster | Items | Nature |
|---------|-------|--------|
| A — Prose / convention | #15, #16, #17 | Judgment-call wording or anchor placement; mechanical propagation |
| B — Script enhancements | #31, #33, #32 | New drift-guard logic, structural assertions, mutation regression |

The clusters can be implemented in either order, but within Cluster B the
sequence is fixed: `#31 → #33 → #32`. The mutation regression (#32) depends on
the final shape of the scripts it tests, so it lands last.

### Cluster A: prose / convention decisions

#### Item #15 — grammar rewrite of the `Refactor code unrelated…` bullet

Current text at `plugins/kenspc/shared/code-craft-principles.md:105`:

> `Refactor code unrelated to the current task is out; do not refactor things that are not broken even when you would have written them differently from scratch.`

The verb phrase `Refactor code unrelated to the current task` is used as the
noun-phrase subject of `is out`, which reads as broken English. The verbatim
phrase is load-bearing for Task 12's relocation grep contract, so a rewrite
must preserve the literal substring `refactor code unrelated to the current
task` (case-insensitive matches the existing grep).

Chosen rewrite:

> `Don't refactor code unrelated to the current task — that is out of scope; do not refactor things that are not broken even when you would have written them differently from scratch.`

Why this candidate: simplest rewrite that keeps the verbatim substring inside
a fluent sentence; the em-dash separates the negative imperative from the
scope-statement; the rest of the bullet is untouched. The phrase being pinned
by Task 12 (`refactor code unrelated to the current task`) remains intact.

The edit lies on line 105, which is **outside** the surgical-changes byte-
identity marker range (markers at lines 97/99). The hash check in
`scripts/check-code-craft-canonical.sh` is unaffected.

#### Item #16 — section-header naming convention

Current state: both `plugins/kenspc/agents/task-implementer.md:82` and
`plugins/kenspc/agents/code-fixer.md:69` use `CODE-CRAFT PRINCIPLES` (with
hyphen). Every other section header in those files (`CONTEXT YOU WILL
RECEIVE`, `QUALITY RULES`, `FIXING RULES`, `AUTONOMY BOUNDARIES`,
`DONE CRITERIA`, etc.) is ALL CAPS without hyphens.

Decision: **keep** `CODE-CRAFT PRINCIPLES` (with hyphen). Rationale:

1. "Code-Craft" is a hyphenated compound adjective in standard English.
2. The hyphen visually distinguishes this section from the surrounding
   two-word ALL CAPS headers, reinforcing that it is the single section
   sourced from `shared/code-craft-principles.md` rather than agent-local
   content.
3. Default-keep minimizes blast radius. Dropping the hyphen would touch:
   `agents/task-implementer.md`, `agents/code-fixer.md`, **and** four
   acceptance-criteria locations in `docs/tasks/code-craft-principles-tasks.md`
   (lines 189, 202, 218, 238) plus a CHANGELOG entry reference (line 374).
   That is a five-line edit across three files for a cosmetic gain. Keeping
   the hyphen requires zero file edits to agent or task files.

Anchor for the decision: a new short paragraph in the repository-root
`CLAUDE.md` under the existing "Skill Development Conventions" section,
documenting the writer-agent header convention (ALL CAPS, words separated by
spaces, no hyphens) and naming `CODE-CRAFT PRINCIPLES` as the canonical
hyphenated compound-adjective exception. CLAUDE.md is loaded into every
session's context, so the convention is visible to any future agent editing
writer agents. No inline guard comment is added inside the agent files —
the CLAUDE.md anchor carries the rationale once and avoids duplicating it
in two agent files. If a future review angle finds the CLAUDE.md anchor
insufficient (tracked in Open Question 2), an inline guard comment can be
added in a follow-up plan.

#### Item #17 — dry-run report terminology going forward

The existing v3.1.0 dry-run report at
`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md` uses `PASSES`
per-condition to mean "condition is satisfied → bullet *eligible* to flag
the hunk" (e.g., line 76, `Condition 1 PASSES`) while the final-decision
`PASS` (e.g., line 86, `Decision: PASS`) means "bullet does *not* flag → code
is fine". Same word, opposite polarity, in the same paragraph.

Convention to adopt for future dry-runs:

| Surface | Old label | New label |
|---------|-----------|-----------|
| Per-condition evaluation, condition fires | `PASSES` | `CONDITION-MET` |
| Per-condition evaluation, condition does not fire | `FAILS` | `CONDITION-NOT-MET` |
| Per-hunk final decision, bullet flags the hunk | `FAIL` / `FLAG` | `FLAG` |
| Per-hunk final decision, bullet does not flag | `PASS` | `PASS` |

The change is one-way for new labels: `PASS` retains its existing meaning at
the final-decision level. The ambiguity is resolved by replacing the
per-condition polarity label, not by overloading the existing one further.

Anchor for the convention: a new short subsection
`## Output convention — dry-run reports` in
`plugins/kenspc/skills/task-review/SKILL.md`, placed after the existing
"Quality bar" paragraph. The subsection states the four labels verbatim with
the polarity definitions above, plus a one-line note that the existing
v3.1.0 dry-run is preserved as a historical artifact under the old labels.

### Cluster B: script enhancements

#### Item #31 — anchor-phrase frequency guard in `check-code-craft-canonical.sh`

Threat model: a synchronized edit that replaces both canonical principle
blocks across all three files with the same different content would still
produce matching sha256 hashes — and the script would exit 0 on a tree
where the principle labels have disappeared from the public-facing prose
outside the markers. The byte-identity check defends *content sameness*; the
new check defends *label survival*.

**Pre-requisite prose edit (current tree has labels only inside markers in
two of three files):** before adding the frequency check, edit the
applicability line in `task-implementer.md` and `code-fixer.md` so each
file mentions both labels outside the markers. Current lines (one line
below the canonical blocks):

> `task-implementer.md:92`: `This agent's applicability stance (see shared file's table): author at write time.`
> `code-fixer.md:79`: `This agent's applicability stance (see shared file's table): author at fix time. Structural improvements not in the review report are DEFERRED, not applied.`

Replace the leading clause `This agent's applicability stance (see shared
file's table)` with `This agent's applicability stance for Simplicity First
and Surgical Changes (see shared file's table)` in each file. The rest of
each line (including `code-fixer.md`'s trailing
`Structural improvements not in the review report are DEFERRED, not applied.`
sentence) stays intact. Resulting lines:

> `task-implementer.md`: `This agent's applicability stance for Simplicity First and Surgical Changes (see shared file's table): author at write time.`
> `code-fixer.md`: `This agent's applicability stance for Simplicity First and Surgical Changes (see shared file's table): author at fix time. Structural improvements not in the review report are DEFERRED, not applied.`

This gives each anchor phrase a markers-external survival surface in every
file. `shared/code-craft-principles.md` already contains both labels in
multiple markers-external locations (the `## Simplicity First` and
`## Surgical Changes` section headings, the applicability table, and the
"What This File Does NOT Define" section) and needs no prose edit.

**Frequency check, added to `scripts/check-code-craft-canonical.sh`:**

After the existing byte-identity check passes, for each of the three files:

1. Extract the file content with all bounded canonical blocks removed
   (`sed -e '/<!-- canonical:principle:simplicity-first:start -->/,/<!-- canonical:principle:simplicity-first:end -->/d' -e '/<!-- canonical:principle:surgical-changes:start -->/,/<!-- canonical:principle:surgical-changes:end -->/d' "$file"`).
2. Count occurrences of `Simplicity First` (case-insensitive, literal).
   Assert ≥ 1.
3. Count occurrences of `Surgical Changes` (case-insensitive, literal).
   Assert ≥ 1.

Failure mode messages match the style of `check-canonical-dispatch.sh`:
`MISSING anchor 'Simplicity First' in $f outside canonical blocks: found $count, expected >= 1`.

Lower bound is 1 (not exactly 1). This permits future legitimate edits to
add more mentions; it only fires on label deletion.

#### Item #33 — three-condition structure assertion on `quality-reviewer.md`

Threat model: a future edit that drops one numbered condition from either of
the two new bullets (over-engineering at
`plugins/kenspc/agents/quality-reviewer.md:69-75`, drive-by/style-drift at
`plugins/kenspc/agents/quality-reviewer.md:76-81`) would weaken the gate
from a three-condition intersection to a two-condition over-trigger,
generating false-positive flags on legitimate boundary validations or
mechanically-forced cascade changes.

**New script:** `scripts/check-quality-reviewer-bullet-structure.sh`, modeled
on the existing drift-guard pattern (`set -euo pipefail`, `SCRIPT_DIR` /
`REPO_ROOT` resolution, exit codes 0/1/2).

For each of the two bullets, the script asserts:

1. The bullet text contains the phrase `meet **all three** of the following
   conditions:` (the exact "all three" qualifier).
2. The three following lines, when stripped of leading whitespace, start
   with `1. `, `2. `, `3. ` respectively.
3. No `4. ` numbered condition exists between the bullet and the next blank
   line.

The script identifies the two bullets by anchored text matching at the
bullet's opening:

- Bullet 1 (over-engineering): line starting with `- Over-engineering`.
- Bullet 2 (drive-by): line starting with `- Drive-by refactoring and style
  drift in the diff`.

Choice of separate script (not adding to `check-code-craft-canonical.sh`):
matches the existing repo pattern of "one guard, one purpose" seen in the
existing three drift-guard scripts. Each script's name is self-describing;
its failure message points to a single concern. Bundling unrelated checks
into one script makes the failure mode log harder to read.

#### Item #32 — automated mutation regression test (`--self-test`)

Threat model: the canonical drift guards rely on subtle bash + sed +
sha256sum interactions. A future toolchain change (Git Bash version, WSL
update, sed flavour difference) could silently break the extraction logic;
the positive path can still exit 0 because comparing-nothing-to-nothing
yields equal hashes. Without an executable negative-path assertion, the
guard could be silently dead for months until a real drift event reveals
it.

**Implementation:** a `--self-test` flag added to three scripts:

- `scripts/check-code-craft-canonical.sh`
- `scripts/check-canonical-dispatch.sh`
- `scripts/check-quality-reviewer-bullet-structure.sh` (the new script from
  item #33)

When invoked with `--self-test`, the script:

1. Creates a temporary directory (`mktemp -d`).
2. Copies the target file(s) under the script's normal scope into the temp
   directory, preserving relative paths.
3. Applies a **content-based** mutation to one file: a single `sed -i`
   substitution targeting a known phrase from the protected region. Per
   script:
   - `check-code-craft-canonical.sh`: change `Write the minimum` to
     `WRITE the minimum` inside the simplicity-first block of the temp
     copy of `task-implementer.md`.
   - `check-canonical-dispatch.sh`: change `Code Review Phase` to
     `CODE Review Phase` inside the temp copy of
     `plugins/kenspc/skills/task-review/SKILL.md` (the substring lives
     inside the canonical dispatch block bounded by
     `<!-- canonical:dispatch:start -->` / `<!-- canonical:dispatch:end -->`;
     verify on the current tree before relying on it).
   - `check-quality-reviewer-bullet-structure.sh`: delete the `3. ` line
     from the over-engineering bullet in the temp copy of
     `quality-reviewer.md` (sed substitution of `^  3\. ` to `^  X. ` so
     the third numbered condition is no longer recognized).
4. Verifies the substitution actually happened (replacement count ≥ 1). If
   the substitution found nothing, the fixture is stale — emits
   `SELF-TEST FIXTURE STALE` and exits 2.
5. Re-runs the script's main logic against the temp directory (overriding
   `REPO_ROOT` to point to the temp dir).
6. Asserts the re-run exits non-zero. If it exits 0, emits
   `SELF-TEST FAILED — guard did not detect mutation` and exits 1.
7. Cleans up the temp directory.
8. Emits `OK self-test — guard correctly rejected mutation`.

Content-based mutation (not byte-offset) means the fixture survives canonical
content edits: as long as the substitution phrase still exists somewhere in
the protected region, the mutation lands. If the canonical content is
rewritten such that the substitution target disappears, the fixture-stale
exit code fires loudly rather than silently passing.

The `--self-test` mode is an in-band addition to each script — no separate
fixture file, no bats / shellspec dependency. The flag is parsed as the
first positional argument; absence of the flag preserves existing behavior
exactly.

### Mechanical-check block sync

`docs/release-checklist.md` currently lists six exit-coded pre-flight
checks (three JSON validations + three shell drift guards) at lines
12-31, plus a frontmatter-completeness `for`-loop (lines 13-16) that
emits warning lines but does not propagate a non-zero exit. The
"All six must exit 0" prose at line 33 counts only the exit-coded
checks, not the frontmatter loop. After this work the block contains:

- The frontmatter-completeness loop (unchanged, still advisory).
- Three JSON validations (unchanged).
- Three existing shell drift guards (unchanged).
- One new shell drift guard:
  `bash scripts/check-quality-reviewer-bullet-structure.sh`.
- Three new self-test invocations:
  `bash scripts/check-code-craft-canonical.sh --self-test`,
  `bash scripts/check-canonical-dispatch.sh --self-test`,
  `bash scripts/check-quality-reviewer-bullet-structure.sh --self-test`.

Total ten exit-coded checks (3 JSON + 4 drift + 3 self-test). All must
exit 0 before proceeding to the smoke checklist. The frontmatter loop
stays advisory (any `MISSING effort:` warning still requires the
implementer's attention, but is not part of the ten-count).

### Version & CHANGELOG

- `plugins/kenspc/.claude-plugin/plugin.json` `version` bumps from `3.1.0`
  to `3.1.1`. No metadata other than `version` changes.
- `plugins/kenspc/CHANGELOG.md` gains a new `## [3.1.1] - 2026-MM-DD`
  entry (date set at release time) under `### Changed` and `### Added`,
  listing each of the six brief items by id with one-line summaries
  linking to the relevant files and commits.

## Implementation Steps

Each step lands as one conventional-commit. Steps are sequential; an
implementer can pause between steps. The pre-flight check
suite must exit 0 after every step.

### Step 1: rewrite the `Refactor code unrelated…` bullet (item #15)

- File: `plugins/kenspc/shared/code-craft-principles.md`.
- Edit: replace the bullet text at line 105 with the chosen rewrite (see
  Cluster A #15 above). Leave the guard comment at line 103 unchanged.
- Acceptance:
  - `grep -F "refactor code unrelated to the current task" plugins/kenspc/shared/code-craft-principles.md`
    returns ≥ 1 match (case-insensitive, the verbatim Task-12 substring is
    preserved).
  - `grep -F "refactor code unrelated to the current task" plugins/kenspc/agents/`
    (recursive) returns 0 matches (Task-12 relocation invariant unchanged).
  - `bash scripts/check-code-craft-canonical.sh` exits 0 (the byte-identity
    blocks were not touched).
  - The new bullet text reads as a fluent English sentence (subjective
    check by the implementer).
- Commit: `fix(shared): rewrite refactor-code-unrelated bullet for grammar while preserving relocation grep phrase`.

### Step 2: record the `CODE-CRAFT PRINCIPLES` hyphen convention (item #16)

- File: repository-root `CLAUDE.md`.
- Edit: under the "Skill Development Conventions" section, add a short
  paragraph (~4 lines) stating:
  - Writer-agent section headers (e.g., `CONTEXT YOU WILL RECEIVE`,
    `QUALITY RULES`, `FIXING RULES`, `AUTONOMY BOUNDARIES`,
    `DONE CRITERIA`) follow an ALL CAPS, space-separated, no-hyphen
    convention.
  - `CODE-CRAFT PRINCIPLES` is a deliberate exception because "Code-Craft"
    is a hyphenated compound adjective in standard English. Edits to
    `task-implementer.md` and `code-fixer.md` must preserve this hyphen.
- No edits to agent files or task files.
- Acceptance:
  - `grep -F "CODE-CRAFT PRINCIPLES" plugins/kenspc/agents/task-implementer.md plugins/kenspc/agents/code-fixer.md`
    returns 1 match per file (unchanged from current state).
  - `grep -F "CODE-CRAFT PRINCIPLES" CLAUDE.md` returns ≥ 1 match (the new
    paragraph references the literal header).
  - `grep -F "hyphenated compound adjective" CLAUDE.md` returns ≥ 1 match
    (the rationale wording is anchored).
- Commit: `docs(claude-md): document writer-agent header convention and CODE-CRAFT hyphen exception`.

### Step 3: define dry-run report terminology (item #17)

- File: `plugins/kenspc/skills/task-review/SKILL.md`.
- Edit: insert a new `## Output convention — dry-run reports` subsection
  after the existing "Quality bar" paragraph (and before
  "Prerequisites"). Body specifies the four labels per the table in
  Cluster A #17 above, plus the historical-record carve-out for the
  existing v3.1.0 dry-run file.
- No edits to the existing v3.1.0 dry-run file.
- No edits to `quality-reviewer.md` (the convention is consumed by the
  orchestrator, not the reviewer agent).
- Acceptance:
  - `grep -F "CONDITION-MET" plugins/kenspc/skills/task-review/SKILL.md`
    returns ≥ 1 match.
  - `grep -F "CONDITION-NOT-MET" plugins/kenspc/skills/task-review/SKILL.md`
    returns ≥ 1 match.
  - `grep -F "Output convention — dry-run reports" plugins/kenspc/skills/task-review/SKILL.md`
    returns exactly 1 match (the new subsection heading is present).
  - The new subsection's body contains the literal tokens `FLAG` and
    `PASS` used per the polarity table in Cluster A #17 (verified by
    reading the diff; greping for `FLAG` and `PASS` alone is too noisy
    because both tokens already appear elsewhere in the file).
  - `git diff plugins/kenspc/skills/task-implement/SKILL.md` shows no
    changes (the canonical dispatch block is in both SKILLs, but the new
    subsection is task-review specific and lies outside that block).
  - `bash scripts/check-canonical-dispatch.sh` exits 0 (canonical block
    untouched).
- Commit: `docs(task-review): define dry-run report terminology (CONDITION-MET/NOT-MET and FLAG/PASS)`.

### Step 4: add anchor-phrase frequency guard (item #31, with coordinated prose edit)

- Files (coordinated edit, single commit):
  - `plugins/kenspc/agents/task-implementer.md`: applicability line below
    the canonical blocks — add `Simplicity First` and `Surgical Changes`
    by name (see Cluster B #31 prose edit above).
  - `plugins/kenspc/agents/code-fixer.md`: same edit pattern, with `fix
    time` instead of `write time`.
  - `scripts/check-code-craft-canonical.sh`: extend with the anchor-phrase
    frequency check (see Cluster B #31 frequency check above).
- Acceptance:
  - `bash scripts/check-code-craft-canonical.sh` exits 0 on the post-edit
    tree (both byte-identity and frequency checks pass).
  - Reverting either agent's prose edit alone (keeping the script change)
    causes the script to exit 1 with `MISSING anchor 'Simplicity First'
    in plugins/kenspc/agents/task-implementer.md outside canonical blocks`
    (or similar for `Surgical Changes` / `code-fixer.md`) — verify once
    locally, revert.
  - The script's existing byte-identity behavior is unchanged: deleting
    one character inside any canonical block still triggers `DRIFT
    canonical:principle:*` (verify once locally, revert).
- Commit: `feat(scripts): add anchor-phrase frequency guard to check-code-craft-canonical`.

### Step 5: add three-condition structure guard (item #33)

- File: new `scripts/check-quality-reviewer-bullet-structure.sh`.
- Implementation: see Cluster B #33 above. Make the script executable
  (`chmod +x`).
- Acceptance:
  - `bash scripts/check-quality-reviewer-bullet-structure.sh` exits 0 on
    the current `quality-reviewer.md`.
  - Locally delete the `3.` line from either bullet (in a temp branch),
    re-run; script exits 1 with a clear message naming the bullet that
    lost a condition. Revert.
  - Locally delete the `**all three**` qualifier from either bullet
    (in a temp branch), re-run; script exits 1 with a different clear
    message. Revert.
- Commit: `feat(scripts): add quality-reviewer three-condition bullet structure guard`.

### Step 6: add `--self-test` mode to three scripts (item #32)

- Files:
  - `scripts/check-code-craft-canonical.sh`: add `--self-test` flag at
    argument-parse time; on flag, run the self-test routine described in
    Cluster B #32 above.
  - `scripts/check-canonical-dispatch.sh`: same pattern.
  - `scripts/check-quality-reviewer-bullet-structure.sh`: same pattern.
- Acceptance:
  - `bash scripts/check-code-craft-canonical.sh --self-test` exits 0.
  - `bash scripts/check-canonical-dispatch.sh --self-test` exits 0.
  - `bash scripts/check-quality-reviewer-bullet-structure.sh --self-test`
    exits 0.
  - Invoking each script without `--self-test` preserves the existing
    output and exit codes exactly (no behavioral drift on the positive
    path).
  - Force the self-test to fail by temporarily breaking the script's
    main detection logic (in a throwaway branch), re-run `--self-test`,
    confirm exit code 1 with `SELF-TEST FAILED — guard did not detect
    mutation`. Revert.
- Commit: `feat(scripts): add --self-test mutation regression mode to drift-guard scripts`.

### Step 7: update the release-checklist mechanical-check block

- File: `docs/release-checklist.md`.
- Edit: extend the pre-flight code block (lines 12-31) to include the new
  drift guard and the three `--self-test` invocations (see Mechanical-check
  block sync above). Preserve the existing frontmatter-completeness
  `for`-loop unchanged. Update the prose line "All six must exit 0 (3 JSON
  validations + 3 shell drift guards)" to "All ten must exit 0 (3 JSON
  validations + 4 drift guards + 3 self-test regressions)."
- Acceptance:
  - Running every command in the new pre-flight block, sequentially, all
    exit-coded commands exit 0 on the post-Step-6 tree.
  - The block enumerates exactly the expected ten exit-coded commands;
    the prose count matches.
  - The frontmatter-completeness `for`-loop is still present and still
    advisory (emits warnings but does not affect exit status).
- Commit: `docs(release): list new drift guards and self-tests in pre-flight block`.

### Step 8: version bump and CHANGELOG entry

- Files:
  - `plugins/kenspc/.claude-plugin/plugin.json`: change `"version":
    "3.1.0"` → `"version": "3.1.1"`.
  - `plugins/kenspc/CHANGELOG.md`: prepend a new
    `## [3.1.1] - YYYY-MM-DD` entry (date set at release time) with
    `### Changed` and `### Added` sub-blocks citing each of the six
    brief items by short id (e.g., "Brief #15: grammar rewrite of the
    `Refactor code unrelated…` bullet") and the relevant commit short
    SHAs.
- Acceptance:
  - `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool >
    /dev/null` exits 0 (the bump did not break JSON).
  - `head -30 plugins/kenspc/CHANGELOG.md | grep -F "[3.1.1]"` returns
    ≥ 1 match.
  - The full pre-flight mechanical-check block from Step 7 exits 0.
- Commit: `chore(release): bump version to 3.1.1 for code-craft deferred follow-ups`.

## Testing Strategy

This plugin/skill repo has no executable application code — verification is
the pre-flight mechanical-check block from `docs/release-checklist.md`. After
the work lands, the block contains ten checks: three JSON validations, four
drift guards, three self-test regressions.

Manual verification beyond the mechanical-check block:

- **Item #15 grammar**: the implementer (or reviewer) reads the new bullet
  aloud and confirms it parses as English.
- **Item #16 anchor visibility**: open `task-implementer.md` and confirm the
  CLAUDE.md anchor paragraph is discoverable by greping for the literal
  header from CLAUDE.md.
- **Item #17 convention adoption**: spot-check the next dry-run report (if
  one is produced under this version) uses the new labels. If no dry-run
  is produced before the next release, the convention is dormant but
  documented; no further verification needed.
- **Smoke checklist**: run the full smoke checklist in
  `docs/release-checklist.md` after Step 8 (~10 minutes manual).

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Step 1 grammar rewrite accidentally drops the verbatim substring `refactor code unrelated to the current task` | Low | High (silently breaks Task-12 grep contract) | Step 1 acceptance criterion includes both a positive grep (≥1 in shared) and a negative grep (0 in agents). Pre-commit hook candidate. |
| Step 4 anchor-phrase frequency check fails on current tree because labels are markers-internal in two of three files | Medium | Medium (Step 4 would not pass acceptance) | Plan explicitly bundles a coordinated prose edit in two agent files with the script change. Discovered during plan self-challenge; remediation baked into Step 4. |
| Step 5's three-condition assertion regresses on a future legitimate expansion to four conditions | Low | Low (would force a deliberate script update, not silently break behavior) | The `3` constant is a single integer in one script; deliberate expansion is one commit. Documented as acceptable in the script comment. |
| Step 6 self-test fixture goes stale when canonical content is rewritten | Medium | Low (self-test fails loudly with `SELF-TEST FIXTURE STALE`, exit 2 — not silently passes) | Content-based mutation (not byte-offset). Fixture-stale exit code is distinct from real failure exit code, so the implementer can tell at a glance which case fired. |
| Step 6 `--self-test` mode introduces a behavior regression on the positive (no-flag) path | Low | High (silently breaks the normal pre-flight check) | Step 6 acceptance explicitly requires "Invoking each script without `--self-test` preserves the existing output and exit codes exactly". Re-run all three scripts after Step 6 in their normal mode and diff the output against pre-Step-6 expected output. |
| Step 8 version bump lands before the previous steps' commits are merged, causing a tag that includes incomplete work | Low | High (mis-tagged release) | Sequential commits, single-PR or per-step PR; the bump commit is the last and depends on every prior step's commit. Reject re-ordering at review time. |

## Open Questions

1. **Should `scripts/check-review-agent-drift.sh` also gain a `--self-test`
   mode?** The same silently-dead-guard threat model applies; the brief did
   not enumerate it because it predates the v3.1.0 code-craft work. Decision
   deferred to a follow-up planning pass.
2. **Should the `CODE-CRAFT PRINCIPLES` convention paragraph also live as a
   short guard comment inline near the header in `task-implementer.md` and
   `code-fixer.md`, mirroring the existing Task-12 guard pattern at
   `shared/code-craft-principles.md:103`?** This plan chooses the CLAUDE.md
   single-anchor approach for lower blast radius; the inline-guard variant
   adds two more files to the diff and duplicates the rationale. If a future
   review angle finds CLAUDE.md insufficient as a guard surface, the inline
   comment can be added in a follow-up.
3. **CHANGELOG +50 line-cap convention from Task 14 of the v3.1.0 plan.**
   The brief notes the +50 cap is unrealistic for v3-era entries; the v3.1.1
   entry under this plan will likely also exceed it. This plan does not
   address the convention itself (out of scope per the brief); the +50 cap
   reconciliation belongs in a future planning-conventions revision.
4. **Three pre-existing dead-anchor links in `plugins/kenspc/CHANGELOG.md`**
   (the `#acknowledgments` vs `#acknowledgements` mismatch in v3.0.0 /
   v2.0.0 / v1.5.0 entries) are pre-existing and not addressed here per
   the brief's deferred-list.

## Context

- Brief: `docs/briefs/code-craft-principles-deferred.md`.
- Originating review: v3.1.0 automated 5-angle review run on 2026-05-14.
  Review reports and accountability list in the orchestrator's session
  transcript and commits `9d20904`, `6a8c609`, `d1e3a0e`, `7e63072`,
  `1ac727d`, `f09de92`.
- v3.1.0 version-bump commit pair: `12ab26c`.
- Discovery mode for this plan: rapid-direct. The brief was authored as a
  Level 1 input with full rationale for each item; no further discovery
  rounds were needed beyond gap-checking the brief against the five
  Discovery dimensions and verifying the brief's line/file references
  against the current tree.
