# Plan: v3.1.x Code-Craft Principles — Deferred Follow-ups

## Objective

Close the six DEFERRED items from the v3.1.0 (Code-Craft Principles) automated
5-angle review (`docs/briefs/code-craft-principles-deferred.md`) without
disturbing any v3.1.0-locked invariant. After this plan ships:

1. The Surgical Changes checklist bullet at
   `plugins/kenspc/shared/code-craft-principles.md:105` reads as fluent English
   while still containing the verbatim substring required by Task 12's
   4-phrase relocation grep contract.
2. The writer-agent section header `CODE-CRAFT PRINCIPLES` (with hyphen) is
   documented as a deliberate exception to the ALL-CAPS-no-hyphens convention
   used by the surrounding writer-agent headers, so future readers do not
   "normalize" it.
3. The unambiguous dry-run report labels `CONDITION-MET` /
   `CONDITION-NOT-MET` (per-condition) and `FLAG` / `PASS` (per-hunk decision)
   are written into `task-review/SKILL.md` as the standing output convention
   that all future dry-run reports follow.
4. Three additional drift-guard defenses are mechanically enforced in
   `scripts/`:
   - Anchor-phrase frequency check on the three canonical-principle files
     (defends label survival when the byte-identity hash defends only content
     sameness).
   - Structural assertion on `quality-reviewer.md`'s two new REVIEW
     CHECKLIST bullets (each must enumerate exactly three numbered
     conditions, gated by an `all three` qualifier).
   - Executable mutation regression fixture (`--self-test` flag) that proves
     the canonical-drift guards detect a deliberate one-byte mutation —
     converting Task 15 Step 6's manual mutation test into a permanent
     negative-path assertion.

All v3.1.0 invariants — 3-file byte-identity hash on the canonical principle
blocks, Task 12's 4-phrase relocation grep contract, the 5-reviewer-agent
drift guard, and the `task-review` ↔ `task-implement` canonical dispatch
byte-identity — remain intact. The pre-flight mechanical-check suite from
`docs/release-checklist.md` continues to exit 0 on the post-work tree (and
grows from 6 checks to 10 checks).

Target release: v3.1.1 (patch). No new SKILL or agent interfaces, no
CONTEXT block schema changes, no new external dependencies.

## Background

The v3.1.0 release (commits `9d20904`, `6a8c609`, `d1e3a0e`, `7e63072`,
`1ac727d`, `f09de92`, and the version commit `12ab26c`) introduced the
`Simplicity First` and `Surgical Changes` code-craft principles as a shared
file (`plugins/kenspc/shared/code-craft-principles.md`) plus byte-identical
inlined copies in the two writer agents (`task-implementer.md`,
`code-fixer.md`). The release also added two new REVIEW CHECKLIST bullets
to `quality-reviewer.md` (over-engineering, drive-by/style-drift), each
gated by three numbered conditions with an "all three" qualifier.

The v3.1.0 automated 5-angle review (run on 2026-05-14) produced an
accountability list with six DEFERRED items. Each was deferred for one of
two reasons:

- **Renegotiates a v3.1.0-locked contract**: items #15 (grammar rewrite of
  a bullet whose verb-phrase wording is pinned by Task 12's grep contract),
  #16 (writer-agent section header convention), #17 (dry-run report
  terminology). Fixing in v3.1.0 would have either broken a contract or
  desynchronized the agent files from the already-ratified task document.
- **Defense-in-depth tooling that did not block ship**: items #31
  (anchor-phrase frequency guard), #32 (mutation regression fixture), #33
  (three-condition structural assertion). The v3.1.0 review classified
  these as additional defenses against future drift, not as blockers.

This plan addresses all six items, plus the two natural support tasks
(release-checklist sync and version/CHANGELOG bump) that the brief did not
enumerate as items but that any release-quality change pulls in.

## Scope

**In scope** — eight ordered work items, one commit per item:

| # | Brief item | Type | Files touched | Commit prefix |
|---|------------|------|---------------|---------------|
| 1 | #15 grammar rewrite | Prose | `shared/code-craft-principles.md` (line 105) | `fix(shared)` |
| 2 | #16 convention decision | Doc | root `CLAUDE.md` + 1 guard comment per writer agent (2 files) | `docs` |
| 3 | #17 dry-run terminology | Doc | `skills/task-review/SKILL.md` | `docs(task-review)` |
| 4 | #31 anchor-phrase frequency | Script | `scripts/check-code-craft-canonical.sh` (extend) | `feat(scripts)` |
| 5 | #33 three-condition structural assertion | Script | new `scripts/check-quality-reviewer-bullet-structure.sh` | `feat(scripts)` |
| 6 | #32 mutation self-test | Script | `--self-test` flag added to 3 scripts | `feat(scripts)` |
| 7 | release-checklist sync | Doc | `docs/release-checklist.md` mechanical-check block | `docs(release)` |
| 8 | version + CHANGELOG | Release | `plugin.json` → 3.1.1, `CHANGELOG.md` v3.1.1 entry | `chore(release)` |

**Out of scope** (inherited from the brief — do not re-open):

- Any change to content **between** the `<!-- canonical:principle:*:start -->`
  / `<!-- canonical:principle:*:end -->` markers in the three principle
  files. The byte-identity hash defends this; v3.1.0 ratified it.
- Rewriting the existing v3.1.0 dry-run report
  (`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md`). It is a
  historical artifact of Task 16's analysis and is preserved as-is. Item #17
  governs only *future* reports.
- Renegotiation of Task 12's four-phrase grep contract. The four literal
  substrings (`Do not modify code unrelated to the current task`,
  `refactor code unrelated to the current task`,
  `Do not introduce new features or refactor`,
  `Preserve the original code's style`) must still grep to 0 matches in
  `plugins/kenspc/agents/` and ≥1 in
  `plugins/kenspc/shared/code-craft-principles.md`.
- CHANGELOG line-count upper-bound recalibration (Task 14's `+50` cap).
  Belongs to a future planning-conventions revision, not here.
- `.gitattributes` LF enforcement and the three pre-existing
  `#acknowledgments` dead anchors in CHANGELOG (review angle 4 #5).
  Pre-existing, not introduced by v3.1.0; separate cleanup pass.
- Adding `--self-test` to `check-review-agent-drift.sh`. That script is
  pre-v3.1.0; covering it is a clean follow-up but stretches this plan's
  scope. Listed in Open Questions.

## Technical Approach

The eight steps split into two natural clusters:

- **Cluster A — Prose / convention decisions (Steps 1–3):** each requires
  one judgment call followed by a mechanical edit. Hard part: making the
  judgment without re-opening a v3.1.0 trade-off.
- **Cluster B — Drift-guard script enhancements (Steps 4–6):** each adds a
  new mechanical check. Hard part: sequencing so each script's `--self-test`
  fixture can be authored against the final shape of the script's main
  logic.

Steps 7 and 8 are pure release-hygiene tasks that follow standard kenspc
release conventions.

### Decision A1: Grammar rewrite candidate (#15)

The bullet at `shared/code-craft-principles.md:105` currently reads:

> `Refactor code unrelated to the current task is out; do not refactor`
> `things that are not broken even when you would have written them`
> `differently from scratch.`

This uses the verb-phrase `Refactor code unrelated to the current task` as
a noun-phrase subject of `is out`, which reads as broken English.

**Chosen rewrite** (verbatim — implementer copies this):

> `Don't refactor code unrelated to the current task — that is out of`
> `scope; do not refactor things that are not broken even when you would`
> `have written them differently from scratch.`

Why this candidate:

- Preserves the literal substring `refactor code unrelated to the current task`
  required by Task 12's grep contract (the substring appears verbatim, just
  preceded by `Don't ` and followed by ` — that is`).
- Reads as a fluent sentence: imperative verb (`Don't refactor`),
  em-dash-separated qualifier, semicolon-joined second clause.
- Em-dash matches the punctuation style already used in the surrounding
  Surgical Changes paragraph (e.g., `Surgical Changes. Touch only what the
  task requires. Why: ...`).
- Touches line 105 only. The byte-identity markers for `surgical-changes`
  are at lines 97/99, so this edit is **outside** the hash-protected range.
  `bash scripts/check-code-craft-canonical.sh` continues to exit 0 after
  the edit.

Alternative candidates considered and rejected:

- `Refactoring code unrelated to the current task is out of scope; ...`
  — would change the substring from `refactor` (imperative) to
  `Refactoring` (gerund). **Drops the grep-required substring**.
- Leave as-is and accept the awkward grammar. The f09de92 guard comment
  already pins the substring, so the current bullet is *safe*, just *ugly*.
  Rejected because the brief explicitly classified this as a deferred fix,
  not a "won't fix".

### Decision A2: Writer-agent section header convention (#16)

Current state on disk: both `task-implementer.md:82` and `code-fixer.md:69`
have `CODE-CRAFT PRINCIPLES` (with hyphen). All other section headers in
those two files (e.g., `CONTEXT YOU WILL RECEIVE`, `QUALITY RULES`,
`FIXING RULES`, `AUTONOMY BOUNDARIES`, `DONE CRITERIA`) are ALL CAPS,
space-separated, no hyphens.

**Chosen resolution: keep the hyphen.** The header stays
`CODE-CRAFT PRINCIPLES` in both agent files; the task document's Task 6/7
acceptance criteria (which already use this spelling — see
`docs/tasks/code-craft-principles-tasks.md:189,202,218,238`) stay
unchanged. Net file changes from this decision: zero header edits.

This satisfies brief item #16's "propagate the winning header to Task 6/7
acceptance criteria in the same commit" clause trivially: keeping the
hyphen requires zero edits to the task document (its acceptance criteria
already spell `CODE-CRAFT PRINCIPLES` with the hyphen), so propagation is
already complete. Had the decision gone the other way (remove hyphen),
Step 2 would also have edited Tasks 6/7 acceptance criteria in
`docs/tasks/code-craft-principles-tasks.md`.

Why keep the hyphen:

- "Code-Craft" is a legitimate hyphenated compound adjective in English.
  The hyphen is semantically correct, not stylistic noise.
- Default-keep minimizes blast radius. Removing the hyphen would require
  synchronized edits across **four** surfaces (two agent files + task
  document's Tasks 6/7 acceptance criteria + any guard/grep that targets
  the literal header).
- The hyphen visually distinguishes this section from surrounding two-word
  ALL-CAPS headers, which is useful — the new section is the only one
  defining principles rather than rules/boundaries.

To prevent a future contributor from "normalizing" the hyphen away
silently, this plan adds **two co-located, identically-worded markers**:

- **Anchor 1 (authoritative)**: a new short subsection in repo-root
  `CLAUDE.md`, inside the existing "Skill Development Conventions" block,
  documenting that:
  - Writer-agent section headers are ALL CAPS, space-separated, no hyphens
    **except** for hyphenated compound adjectives.
  - `CODE-CRAFT PRINCIPLES` is the canonical and currently sole example of
    the compound-adjective exception.
- **Anchor 2 (drift-prevention)**: a one-line guard HTML comment placed
  immediately above the `CODE-CRAFT PRINCIPLES` header in each writer
  agent file (`task-implementer.md:82`, `code-fixer.md:69`). The comment
  mirrors the existing Task 12 guard pattern at
  `shared/code-craft-principles.md:103`. Suggested wording:
  > `<!-- guard: the hyphen in "CODE-CRAFT PRINCIPLES" is intentional — it`
  > `marks a compound-adjective exception to the ALL-CAPS-no-hyphens`
  > `writer-agent header convention documented in repo-root CLAUDE.md.`
  > `Do not normalize without updating the CLAUDE.md convention paragraph`
  > `in the same commit. -->`

The CLAUDE.md anchor states the convention; the inline guard prevents a
future edit that does not first read CLAUDE.md from silently regressing.
Three small additions across three files, no header changes.

### Decision A3: Dry-run report terminology (#17)

The existing v3.1.0 dry-run report
(`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md`) uses
`PASSES` per-condition to mean "condition is satisfied → bullet *eligible*
to flag the hunk" (line 76) and `PASS` per-hunk to mean "bullet does *not*
flag → code is fine" (line 86). Same word root, opposite polarity, in the
same paragraph.

**Standing convention written into `task-review/SKILL.md`:**

| Decision level | Label vocabulary | Polarity |
|----------------|------------------|----------|
| Per-condition  | `CONDITION-MET` / `CONDITION-NOT-MET` | `MET` = the condition is true (the bullet's qualifier holds). |
| Per-hunk final | `FLAG` / `PASS` | `FLAG` = the bullet reports the hunk; `PASS` = the bullet does not report the hunk (code is fine). |

The two vocabularies cannot collide: `MET` / `NOT-MET` only appears at
per-condition level, `FLAG` / `PASS` only at per-hunk level. A reader
seeing `CONDITION-MET` knows it is a condition evaluation; a reader seeing
`FLAG` knows it is the final decision.

**Anchor location**: a new short subsection
`## Output convention — dry-run reports` in `task-review/SKILL.md`, placed
after the "Quality bar" section and before "Prerequisites" (logical
grouping: skill-level output conventions live near skill-level quality
expectations). The convention paragraph defines the four labels verbatim
in a table and explicitly cites the v3.1.0 historical artifact as an
example of the *prior* ambiguous convention (so future readers
understand the convention's motivation).

The existing v3.1.0 dry-run report is **not** rewritten. It is preserved
as a historical artifact per the brief's out-of-scope clause.

### Decision B1: #31 anchor-phrase frequency semantics (refinement of brief)

The brief specifies (#31): "each of the three target files contains ≥1
occurrence of `Simplicity First` and ≥1 of `Surgical Changes` **outside
the byte-identity hash range**."

Discovery against the current tree:

| File | `Simplicity First` outside markers | `Surgical Changes` outside markers |
|------|------------------------------------|------------------------------------|
| `shared/code-craft-principles.md` | 3× (lines 3, 5, 11) | 3× (lines 3, 95, 101) |
| `task-implementer.md` | **0×** | **0×** |
| `code-fixer.md` | **0×** | **0×** |

The brief's "outside the hash range" qualifier does not match the
agent-file reality: in both writer agents, the principle labels appear
**only inside the canonical marker block**, nowhere else. Two ways to
honour the brief's stated invariant:

- **Path A — content addition**: edit both writer-agent files to add an
  outside-marker mention of each label (e.g., a sentence near the section
  header: `This agent's stance on Simplicity First and Surgical Changes
  is defined inline below...`). Adds two lines per agent file. Increases
  the surface area protected, but requires content edits the brief did
  not request.
- **Path B — semantic refinement**: relax the brief's "outside markers"
  qualifier to "anywhere in file". The frequency check counts occurrences
  in the entire file (both inside and outside markers), requiring ≥1 each.
  This still defends the failure mode the brief named — a synchronized
  edit that replaces all three canonical blocks with content not
  mentioning `Simplicity First` would drop the count to 0 (since the
  label only appears inside the block in the agent files anyway).

**Chosen: Path B.** Justification:

- Catches the exact failure mode the brief named ("synchronized edit
  replaces both canonical blocks with the same different content") in all
  three files, no content addition needed.
- Simpler implementation: no need to subtract a marker-bounded region
  from the count.
- The "outside markers" wording in the brief reads as an over-correction
  to avoid double-counting; double-counting is not a concern when the
  predicate is `≥1`, not equality.
- Honours the brief's spirit ("hash defends content sameness; frequency
  defends label survival") with strictly weaker syntactic constraint and
  strictly equal semantic strength.

This refinement is called out at the top of the implementing commit
(`feat(scripts): add anchor-phrase frequency guard to
check-code-craft-canonical`) so reviewers do not mistake it for brief-
drift.

### Decision B2: #33 placement — separate script vs. extend existing (one-guard-one-purpose)

The brief is explicit: "May live in the same script as #31 or as a
sibling check" and "Lean toward *two scripts* to keep the 'one guard,
one purpose' pattern that the existing `check-canonical-dispatch.sh` and
`check-review-agent-drift.sh` follow."

**Chosen: separate script.** New file:
`scripts/check-quality-reviewer-bullet-structure.sh`.

Why:

- `check-code-craft-canonical.sh` operates on the three principle files
  (shared + 2 writer agents). #33's invariant is on
  `quality-reviewer.md`. Different files, different conceptual scope.
- A single script that mixes "byte-identity of principle paragraphs in
  3 files" with "three-condition structure of two bullets in 1 file"
  fails the "one guard, one purpose" pattern that the repo otherwise
  follows.
- Adds one entry to release-checklist (acceptable cost).

### Decision B3: #32 self-test mode scope and implementation

Choice space the brief left open: "bats-style, shellspec-style, or a
small `--self-test` flag — author's choice".

**Chosen: `--self-test` flag** on each guard script.

Why:

- Zero new external dependencies. Honours the brief's "no new external
  dependencies" constraint.
- Cross-platform: bash is the only required runtime. Both Git Bash
  (Windows) and WSL2 Ubuntu run the same fixture.
- Co-located: the fixture lives in the same file as the logic it
  validates. A change to the script's logic forces a co-located change
  to the fixture. Two-file fixtures (bats spec + script) are easier to
  desynchronize.

**Self-test scope: three scripts.**

- `check-code-craft-canonical.sh --self-test` — primary target per brief.
- `check-canonical-dispatch.sh --self-test` — brief noted the same gap
  exists here ("the fixture should ideally cover both").
- `check-quality-reviewer-bullet-structure.sh --self-test` — added in
  Step 5; no cost to author its negative-path assertion in the same
  commit.

`check-review-agent-drift.sh --self-test` is **not** in scope. That
script predates v3.1.0 and adding `--self-test` to it is unrelated to
the code-craft work this plan closes. Listed in Open Questions.

**Self-test fixture mechanics** (uniform across all three scripts):

1. Create a temp directory (`mktemp -d`).
2. Copy every input file the script reads into the temp directory,
   preserving relative paths under a synthetic repo root.
3. **Positive path**: run the script's main logic with `REPO_ROOT`
   overridden to the temp directory. Assert exit code 0.
4. **Negative path**: apply a content-based mutation (`sed -i` with a
   target string drawn from the canonical content) inside one guarded
   region of one file. Run the script again. Assert exit code 1.
5. **Restoration path**: revert the mutation. Run the script again.
   Assert exit code 0 (confirms the mutation was the only failure
   trigger).
6. Clean up the temp directory.
7. Print `OK    self-test passed for <script-name>` on success or
   `FAIL  self-test failed at <step>` on any unexpected exit code.

Mutation targets use **content-based substitution** (e.g.,
`sed -i 's/Write the minimum/WRITE the minimum/'`) rather than byte
offsets, so the fixture survives content edits to the canonical blocks
as long as the substitution target phrase persists. If the canonical
block is rewritten such that the target phrase disappears (`sed`
substitution count = 0), the self-test fails with a distinct
"fixture-stale" error message instructing the maintainer to update
the mutation target.

### Implementation ordering

Cluster A items (Steps 1–3) are independent of each other and of
Cluster B. They could land in any order. Recommended order: Step 1 →
Step 2 → Step 3 (smallest-blast-radius first, simplest verifier first).

Cluster B items (Steps 4–6) are sequenced for self-test fixture
authoring:

- Step 4 lands first: extends `check-code-craft-canonical.sh` with the
  anchor-phrase frequency block. The script's main logic reaches its
  final shape here.
- Step 5 lands second: introduces a brand-new script
  `check-quality-reviewer-bullet-structure.sh`. The script's main
  logic reaches its final shape here.
- Step 6 lands last: adds `--self-test` to all three guard scripts in
  scope. Fixture mutation targets reference the *post-Step-5* shape of
  `check-quality-reviewer-bullet-structure.sh` and the *post-Step-4*
  shape of `check-code-craft-canonical.sh`.

Steps 7 and 8 land at the tail: release-checklist sync after all script
changes are in tree, version bump and CHANGELOG once the rest of the
plan is committed.

## Implementation Steps

Each step is one focused commit. Acceptance is testable from the
repo root.

### Step 1 — #15 grammar rewrite

**Files**:
- `plugins/kenspc/shared/code-craft-principles.md` (line 105 only).

**Action**: replace the existing line 105

> `- Refactor code unrelated to the current task is out; do not refactor things that are not broken even when you would have written them differently from scratch.`

with

> `- Don't refactor code unrelated to the current task — that is out of scope; do not refactor things that are not broken even when you would have written them differently from scratch.`

**Acceptance**:

1. `grep -F "refactor code unrelated to the current task" plugins/kenspc/shared/code-craft-principles.md`
   returns **≥ 1** match (the substring survives; Task 12's grep contract
   holds).
2. `grep -F "refactor code unrelated to the current task" plugins/kenspc/agents/`
   returns **0** matches (Task 12's relocation contract still holds).
3. `bash scripts/check-code-craft-canonical.sh` exits **0** (edit was
   outside the byte-identity range).
4. `bash scripts/check-canonical-dispatch.sh` and
   `bash scripts/check-review-agent-drift.sh` exit **0** (unrelated
   invariants unaffected).

**Commit**: `fix(shared): rewrite refactor-code-unrelated bullet for grammar while preserving Task 12 relocation grep substring`

### Step 2 — #16 convention decision (CLAUDE.md anchor + agent guards)

**Files**:
- repo-root `CLAUDE.md` — add a short subsection inside the existing
  "Skill Development Conventions" block.
- `plugins/kenspc/agents/task-implementer.md` — add a one-line HTML
  guard comment immediately above the `CODE-CRAFT PRINCIPLES` header
  (line 82).
- `plugins/kenspc/agents/code-fixer.md` — same, above line 69.

**Action**:

In CLAUDE.md, append a new subsection under "Skill Development
Conventions" titled "Writer-agent section header convention", with body:

> Writer-agent section headers (the section names inside
> `plugins/kenspc/agents/task-implementer.md` and
> `plugins/kenspc/agents/code-fixer.md`) follow ALL CAPS,
> space-separated, no hyphens — for example, `CONTEXT YOU WILL RECEIVE`,
> `QUALITY RULES`, `FIXING RULES`, `AUTONOMY BOUNDARIES`,
> `DONE CRITERIA`.
>
> The single deliberate exception is `CODE-CRAFT PRINCIPLES`, where the
> hyphen marks the compound adjective "code-craft" (the principle name
> in English). Future writer-agent headers may use a hyphen only when
> the underlying compound is a hyphenated adjective in English; bare
> two-word noun phrases stay space-separated.
>
> Each writer-agent file carries a one-line HTML guard comment
> immediately above the `CODE-CRAFT PRINCIPLES` header that names this
> convention so a contributor editing only the agent file does not
> silently normalize the hyphen away.

In each writer-agent file, insert immediately above the section header
line:

> `<!-- guard: the hyphen in "CODE-CRAFT PRINCIPLES" is intentional — it marks a compound-adjective exception to the ALL-CAPS-no-hyphens writer-agent header convention documented in repo-root CLAUDE.md. Do not normalize without updating the CLAUDE.md convention paragraph in the same commit. -->`

**Acceptance**:

1. `grep -F "CODE-CRAFT PRINCIPLES" plugins/kenspc/agents/task-implementer.md plugins/kenspc/agents/code-fixer.md`
   returns **2** matches (one per file, header unchanged).
2. `grep -F "compound-adjective exception" plugins/kenspc/agents/task-implementer.md plugins/kenspc/agents/code-fixer.md`
   returns **2** matches (guard comments inserted).
3. `grep -F "compound-adjective exception" CLAUDE.md` returns **≥ 1**
   match (CLAUDE.md anchor present).
4. `bash scripts/check-review-agent-drift.sh` exits **0**. This script's
   scope is the **5 reviewer agents** (requirements-, edge-case-,
   quality-, bug-, test-reviewer.md); it does **not** scan
   `task-implementer.md` or `code-fixer.md`, so guard-comment insertions
   in the two writer agents cannot affect its result. The check is
   listed here only to confirm the unrelated invariant is unaffected by
   this commit.
5. `bash scripts/check-code-craft-canonical.sh` exits **0** (canonical
   block hashes unchanged — the guard comment sits outside the marker
   range).
6. `bash scripts/check-canonical-dispatch.sh` exits **0**.

**Commit**: `docs(convention): record CODE-CRAFT-PRINCIPLES hyphen exception in CLAUDE.md and inline guards`

### Step 3 — #17 dry-run report terminology convention

**Files**:
- `plugins/kenspc/skills/task-review/SKILL.md` — insert a new short
  subsection `## Output convention — dry-run reports` after the
  "Quality bar" section and before "Prerequisites".

**Action**: insert (verbatim wording — implementer copies and adapts
only the example reference if needed):

```markdown
## Output convention — dry-run reports

When this skill produces a dry-run report (a per-hunk evaluation of
how each reviewer-agent bullet *would* decide, without actually
modifying files), the report uses two non-overlapping label vocabularies
so a reader scanning the report cannot misread polarity:

| Decision level | Labels | Meaning |
|----------------|--------|---------|
| Per-condition  | `CONDITION-MET` / `CONDITION-NOT-MET` | `CONDITION-MET` = the bullet's qualifier is true (the condition fires; the bullet remains a candidate to flag the hunk). |
| Per-hunk final | `FLAG` / `PASS` | `FLAG` = the bullet reports the hunk. `PASS` = the bullet does **not** report the hunk (code is fine for this bullet's angle). |

The two vocabularies cannot collide because `MET` / `NOT-MET` only
appears at per-condition level and `FLAG` / `PASS` only at per-hunk
level.

Reason: the v3.1.0 dry-run report at
`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md` used the
single word `PASS` for both polarities (`Condition 1 PASSES` meaning
"condition fires" and `Decision: PASS` meaning "code is fine"),
which is easy to misread in the same paragraph. That report is
preserved as a historical artifact; future reports use the labels
above.
```

**Acceptance**:

1. `grep -F "CONDITION-MET" plugins/kenspc/skills/task-review/SKILL.md`
   returns **≥ 1** match.
2. `grep -F "CONDITION-NOT-MET" plugins/kenspc/skills/task-review/SKILL.md`
   returns **≥ 1** match.
3. `grep -nE "^\| Per-hunk final" plugins/kenspc/skills/task-review/SKILL.md`
   returns **1** match (the convention table row).
4. `bash scripts/check-canonical-dispatch.sh` exits **0** (the new
   subsection is inserted **outside** the `<!-- canonical:dispatch:start
   -->` / `<!-- canonical:dispatch:end -->` block in
   `task-review/SKILL.md`; placement at "after Quality bar, before
   Prerequisites" puts it before the dispatch block).
5. `bash scripts/check-review-agent-drift.sh` and
   `bash scripts/check-code-craft-canonical.sh` exit **0**.

**Commit**: `docs(task-review): define dry-run report terminology (CONDITION-MET/NOT-MET, FLAG/PASS)`

### Step 4 — #31 anchor-phrase frequency guard

**Files**:
- `scripts/check-code-craft-canonical.sh` (extend).

**Action**: after the existing byte-identity check completes, append a
new check block modeled on `check-canonical-dispatch.sh:96-117`. The
block:

1. Defines an `ANCHORS` array: `("Simplicity First|1" "Surgical Changes|1")`.
2. Iterates over the three files (`SHARED_FILE`, `IMPLEMENTER_FILE`,
   `FIXER_FILE`) and counts each anchor phrase **anywhere in the file**
   using `grep -F -i -o` piped to `wc -l`, with the same `|| true`
   pipefail-safe pattern from `check-canonical-dispatch.sh:55`.
3. Fails with a distinct error message identifying the file and the
   missing anchor if any count is below its minimum.
4. Reports `OK    code-craft anchor phrases — all minimum counts met in
   all three files` on success.
5. Sets `drift_found=1` on failure (sharing the existing exit-code
   variable) so the script's exit code is unchanged in semantics: 0 if
   both checks pass, 1 if either fails.

**Semantic refinement note in the commit body** (verbatim — explicit
acknowledgement that this departs from the brief's "outside markers"
wording, refining to "anywhere in file"; see Decision B1 above for
rationale).

**Acceptance**:

1. `bash scripts/check-code-craft-canonical.sh` on the current tree
   exits **0** and the output includes both `OK    canonical:principle
   ... byte-identity` lines AND a new `OK    code-craft anchor
   phrases ...` line.
2. **Deliberate counter-example test (run during PR review, not in
   tree)**:
   - Temporarily replace `**Simplicity First.**` with
     `**Minimalism.**` inside the canonical-principle block of all
     three files (single text-replacement that keeps content equal so
     byte-identity still passes).
   - Run `bash scripts/check-code-craft-canonical.sh`. Expect exit
     code **1**, with output naming the three files and the missing
     `Simplicity First` anchor.
   - Revert the mutation.
3. `bash scripts/check-canonical-dispatch.sh` and
   `bash scripts/check-review-agent-drift.sh` exit **0** (unaffected).

**Commit**: `feat(scripts): add anchor-phrase frequency guard to check-code-craft-canonical (refines brief #31's "outside markers" to "anywhere in file")`

### Step 5 — #33 three-condition structural assertion

**Files**:
- new `scripts/check-quality-reviewer-bullet-structure.sh`.

**Action**: create the script. Top-level structure:

```bash
#!/usr/bin/env bash
# check-quality-reviewer-bullet-structure.sh
#
# Asserts that the two new REVIEW CHECKLIST bullets in
# plugins/kenspc/agents/quality-reviewer.md (over-engineering;
# drive-by/style-drift) each enumerate exactly three numbered
# conditions, gated by an "all three" qualifier. ...

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

QR_FILE="$REPO_ROOT/plugins/kenspc/agents/quality-reviewer.md"

# Each entry: "anchor regex|expected condition count|qualifier regex"
BULLETS=(
    "Over-engineering and abstractions|3|\\*\\*all three\\*\\* of the following"
    "Drive-by refactoring and style drift|3|\\*\\*all three\\*\\* of the following"
)
```

Implementation:

1. For each `BULLETS` entry, locate the bullet's first line via
   `grep -nE`, capturing the line number.
2. Slice the file from the bullet line to the next blank line followed
   by a non-list line (the bullet's body).
3. Inside that slice, count occurrences matching `^\s*[0-9]+\.` — must
   equal the expected count.
4. Inside that slice, verify the qualifier regex matches ≥ 1 time.
5. Exit 0 if both bullets pass; exit 1 with named failures otherwise;
   exit 2 if the bullet anchor is not found (structural error).

**Acceptance**:

1. `bash scripts/check-quality-reviewer-bullet-structure.sh` on the
   current tree exits **0**.
2. **Deliberate counter-example test**:
   - Temporarily delete one of the three numbered conditions under
     the over-engineering bullet (e.g., remove `3. Not a boundary
     validation ...`).
   - Run the script. Expect exit code **1**, output naming the bullet
     and the count mismatch (`expected 3, found 2`).
   - Revert.
3. Script is executable (`chmod +x` applied).
4. Script header docstring matches the format/discipline of
   `check-code-craft-canonical.sh` (set -euo pipefail; exit-code
   semantics documented at top; `$REPO_ROOT` derivation pattern).

**Commit**: `feat(scripts): add three-condition structural guard for quality-reviewer.md REVIEW CHECKLIST bullets`

### Step 6 — #32 mutation regression self-test

**Files**:
- `scripts/check-code-craft-canonical.sh` (extend).
- `scripts/check-canonical-dispatch.sh` (extend).
- `scripts/check-quality-reviewer-bullet-structure.sh` (extend).

**Action**: add a `--self-test` flag to each script. Top-level dispatch:

```bash
if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit $?
fi
```

`run_self_test` (uniform shape, per-script mutation target):

1. `WORK=$(mktemp -d)`; `trap 'rm -rf "$WORK"' EXIT`.
2. Copy every file the script reads to `$WORK`, preserving the relative
   path structure under a synthetic repo root.
3. Override `REPO_ROOT="$WORK"` (or pass an env var) and rerun the
   script's main logic. Capture exit code; assert it is **0**.
4. Apply a content-based mutation to one file in `$WORK`. Mutation
   target per script:
   - `check-code-craft-canonical.sh`: change
     `**Simplicity First.**` → `**Simplicity 1st.**` in
     `$WORK/plugins/kenspc/shared/code-craft-principles.md` (mutation
     drops both the canonical-block byte-identity AND the anchor-phrase
     frequency check — exercises both guard paths).
   - `check-canonical-dispatch.sh`: change `unconditional` → `notrequired`
     (a wholly different word) once inside the canonical-dispatch block of
     `$WORK/.../task-review/SKILL.md`. The mutation drops both invariants:
     byte-identity diverges (only one of the two SKILL.md copies is
     edited), and the anchor-phrase count for `unconditional` drops to 0
     in the mutated file (the script's `grep -F -i` matches the literal
     phrase case-insensitively — substituting `Unconditional` would NOT
     drop the anchor count because the check is case-insensitive; only a
     wholly different substring guarantees both guard paths fire).
   - `check-quality-reviewer-bullet-structure.sh`: change
     `3. Not a boundary validation` → `3. Not a boundary validation\n4. Extra`
     (turns the three-condition bullet into four).
5. Rerun the script's main logic. Assert exit code **1**.
6. Revert the mutation in `$WORK`. Rerun. Assert exit code **0**.
7. On success: `echo "OK    self-test passed for $(basename "$0")"`,
   exit 0. On any unexpected exit code: print a `FAIL  self-test ...`
   message and exit 1.

**Fixture-stale handling**: if the `sed` substitution count is 0
(mutation target phrase missing from the canonical content), the
self-test exits 2 with message:
> `FAIL  self-test fixture stale: mutation target "<phrase>" not`
> `found in <file>. Update the mutation target in run_self_test().`

**Acceptance**:

1. `bash scripts/check-code-craft-canonical.sh --self-test` exits **0**.
2. `bash scripts/check-canonical-dispatch.sh --self-test` exits **0**.
3. `bash scripts/check-quality-reviewer-bullet-structure.sh --self-test`
   exits **0**.
4. Each `--self-test` produces a single line of output naming the
   script and `passed`.
5. `bash scripts/check-code-craft-canonical.sh` (no flag) still exits
   **0** — the `--self-test` branch is opt-in, not implicit.
6. Each script's positive-path main logic (no flag) still exits **0**
   on the current tree.

**Commit**: `feat(scripts): add --self-test mutation regression mode to three canonical drift guards`

### Step 7 — release-checklist sync

**Files**:
- `docs/release-checklist.md` (mechanical-check block, lines 10–34).

**Action**: extend the mechanical-check `bash` block to add four
commands:

```bash
# Quality-reviewer bullet structure (3-condition gate on two new bullets)
bash scripts/check-quality-reviewer-bullet-structure.sh

# Mutation regression fixtures (self-test on the three canonical drift guards)
bash scripts/check-code-craft-canonical.sh --self-test
bash scripts/check-canonical-dispatch.sh --self-test
bash scripts/check-quality-reviewer-bullet-structure.sh --self-test
```

Update the trailing sentence from `All six must exit 0 (3 JSON
validations + 3 shell drift guards).` to `All ten must exit 0 (3 JSON
validations + 3 main-mode shell drift guards + 1 structural guard + 3
mutation regression self-tests). If any fail, fix before proceeding to
the smoke checklist.`

**Acceptance**:

1. Running the full mechanical-check block from
   `docs/release-checklist.md:10` exits **0** end-to-end on the post-
   work tree.
2. Removing any one of the four new commands and rerunning still
   exits 0 (independence — each new command stands alone).
3. The "All ten must exit 0" sentence matches the count in the block
   (verify by `grep -cE "^bash scripts/|^cat .*python -m json.tool"`
   inside the bash fence).

**Commit**: `docs(release): list new drift guards and self-tests in pre-flight mechanical-check block`

### Step 8 — version bump + CHANGELOG entry

**Files**:
- `plugins/kenspc/.claude-plugin/plugin.json` (version field).
- `CHANGELOG.md` (new v3.1.1 entry).

**Action**:

1. Bump `version` in `plugin.json` from `3.1.0` to `3.1.1`.
2. Add a `## [3.1.1] — 2026-MM-DD` section at the top of `CHANGELOG.md`
   (after the v3.1.0 entry), with `### Changed`, `### Added`, `### Fixed`
   subsections summarizing the 6 brief items + 2 support tasks. Each
   bullet cites the brief item number and the commit hash.

**Why patch (3.1.1), not minor (3.2.0)**:

- No new SKILL or agent interface. No new CONTEXT keys. No new commands.
- New script behavior (#31, #33, #32) is defense-in-depth tooling — not
  a user-facing capability. The plugin's behavior as observed by the
  Claude harness is unchanged.
- v3.1.0 used `minor` for a substantive feature addition (new shared
  file, new agent behavior surface, new script). v3.1.x deferred follow-
  ups have no equivalent surface change; `patch` is consistent.

**Acceptance**:

1. `grep -F '"version": "3.1.1"' plugins/kenspc/.claude-plugin/plugin.json`
   returns 1 match.
2. `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null`
   exits 0 (JSON still valid).
3. `CHANGELOG.md` has a `[3.1.1]` entry with `### Changed`, `### Added`,
   `### Fixed` subsections and at least one bullet per brief item
   (#15, #16, #17, #31, #32, #33).
4. The CHANGELOG entry is internally consistent: every commit hash it
   references resolves via `git log`.

**Commit**: `chore(release): bump version to 3.1.1 for code-craft principles deferred follow-ups`

## Testing Strategy

The plan introduces no new application code — every change is markdown,
shell scripts, or JSON. Three testing surfaces:

1. **Per-step acceptance tests**: each Step section above has an
   `Acceptance` subsection with concrete `bash`/`grep` one-liners. These
   are run by the implementer and by the v3.1.1 task-review pass.

2. **Pre-flight mechanical-check suite** (`docs/release-checklist.md`):
   Steps 4, 5, 6, 7 each grow the suite. After Step 7 lands, running the
   block from a clean checkout must exit 0 end-to-end.

3. **Smoke checklist** (`docs/release-checklist.md` rows 1–9): no
   user-facing surface changes in this plan, so smoke checklist behavior
   is unchanged. Re-run it once before tagging v3.1.1 as a final
   integration verification.

**Counter-example tests** (deliberate violations to confirm guards
fail correctly): the brief explicitly calls for these as the
acceptance bar for each new check ("passes on the current tree,
fails on a deliberate violation"). Each script's `--self-test` mode
automates this. Additionally, Steps 4 and 5 acceptance criteria
include manual deliberate-mutation tests that the reviewer reruns
during the v3.1.1 task-review.

## Risks and Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|------------|--------|------------|
| R1 | Step 1's rewrite drops the substring `refactor code unrelated to the current task` (Task 12 grep contract regression). | Low | High (silent invariant break). | Step 1 acceptance test 1 + 2 explicitly grep for the substring's presence in `shared/` and absence in `agents/`. |
| R2 | Step 1's rewrite accidentally edits content **inside** the byte-identity markers (lines 97/99 of `shared/code-craft-principles.md`), making `check-code-craft-canonical.sh` fail. | Low | High (CI red). | Step 1 acceptance test 3 + R3 mitigation. The implementer must only modify line 105, leaving lines 95–99 byte-identical. |
| R3 | Step 2's guard comments accidentally land inside the canonical block (above the start marker instead of above the section header), breaking byte-identity. | Low | High. | The guard comment must sit on the line immediately above the `CODE-CRAFT PRINCIPLES` header, which is itself two lines above the `<!-- canonical:principle:simplicity-first:start -->` marker. Step 2 acceptance test 5 catches a regression. |
| R4 | Step 3's new subsection lands inside the `<!-- canonical:dispatch:start -->` / `<!-- canonical:dispatch:end -->` block in `task-review/SKILL.md`, breaking byte-identity with `task-implement/SKILL.md`. | Low | High. | Placement is "after Quality bar, before Prerequisites", which is upstream of the dispatch block. Step 3 acceptance test 4 verifies. |
| R5 | Step 4's anchor-phrase check counts case-insensitively and matches an unrelated paragraph that says "simplicity first" lowercase. | Low | Medium. | Anchors are matched as full literal phrases via `grep -F -i`, exactly mirroring the `check-canonical-dispatch.sh` pattern. Anchors `Simplicity First` and `Surgical Changes` are distinctive enough that a false positive would only come from intentional documentation, which is what we want to count. |
| R6 | Step 5's regex for the three-condition gate is brittle to whitespace or list-style edits. | Medium | Medium. | Use `grep -nE '^[[:space:]]*[0-9]+\.'` rather than a tight character class, and slice by blank-line boundary rather than fixed offset. Step 5 acceptance includes a deliberate counter-example test exercising the failure path. |
| R7 | Step 6's self-test `mktemp -d` + path-rewriting interacts poorly with Git Bash on Windows (path style differences). | Medium | Medium | Use `mktemp -d` plus relative-path traversal from `$WORK` as the synthetic `REPO_ROOT`; avoid `cd` into `/tmp`-style absolutes. Test on both Git Bash and WSL2 before Step 7 closes. |
| R8 | Step 6's content-based mutation target phrase is later edited out of the canonical block, silently breaking the self-test. | Medium | High (silent guard rot — the same failure mode #32 is designed to prevent). | The self-test detects `sed` substitution count = 0 and exits with a `FAIL  self-test fixture stale` message. This explicitly surfaces the staleness instead of allowing a silent green. |
| R9 | Brief item count drift: brief says 6 items, plan ships 8 commits (adds release-checklist sync + version bump). | Low | Low (paperwork only). | Plan Scope table clearly labels Steps 7 and 8 as "support" tasks not in the brief; v3.1.1 CHANGELOG names them explicitly so the audit trail is consistent. |
| R10 | Step 8 chose `patch` semver, but external consumers expect `minor` for new tooling behavior. | Low | Low (no external consumers yet; this is an internal plugin marketplace). | Rationale documented in Step 8. If a future external consumer asks, the v3.1.1 entry text clarifies what changed. |
| R11 | A subsequent edit (post-v3.1.1) adds a fourth condition to one of the over-engineering / drive-by bullets, silently failing #33. | Medium | Low (the check fires correctly — the question is whether the edit was intended). | Acceptable failure mode. A genuine fourth-condition addition is a deliberate edit; updating the `BULLETS` array constant in `check-quality-reviewer-bullet-structure.sh` is a one-line edit in the same commit. |
| R12 | Step 2's CLAUDE.md edit increases the file size, potentially nudging the auto-loaded context allowance for the orchestrator. | Low | Low | The added subsection is ~10 lines. CLAUDE.md auto-loading already imports the full file; a 10-line addition is well within budget. |

## Open Questions

1. **`check-review-agent-drift.sh --self-test`**: should this pre-v3.1.0
   script also receive a `--self-test` mode for consistency? Brief did
   not request it. Recommendation: **defer to v3.1.2 or v3.2.0**, as a
   separate "drift-guard self-test parity" cleanup. Tracking note can be
   added at the bottom of CHANGELOG v3.1.1's "Deferred" or in a new
   `docs/briefs/` entry.
2. **Step 8 version choice (3.1.1 vs 3.2.0)**: the plan picks `3.1.1`
   (patch) per the rationale above. If maintainer policy prefers semver
   `minor` for any new script-public behavior, bump to `3.2.0` and
   re-title the plan. No structural changes to the plan body needed —
   only the version number, the CHANGELOG section heading, and the
   commit message in Step 8.
3. **Self-test parallelism**: each `--self-test` does file copies and
   sed mutations sequentially. With three scripts in the mechanical-
   check block, total wall-clock time on a cold filesystem is ~5
   seconds. If this becomes annoying, a future optimization could
   parallelize the three invocations behind a single `--self-test-all`
   wrapper. Not addressed in this plan.

## Constraints (recap, inherited from brief)

- All v3.1.0 invariants stay intact: byte-identity hash on the canonical
  principle blocks, Task 12's four-phrase relocation grep contract,
  5-agent reviewer drift guard, canonical-dispatch byte-identity. The
  pre-flight mechanical-check suite continues to exit 0 on the post-
  work tree.
- Conventional commits, per task: `fix:` for the grammar bullet, `docs`
  for convention/terminology items, `feat(scripts):` for new script
  behavior, `chore(release):` for the version bump.
- No SKILL or agent interface changes for callers. CONTEXT block
  contracts and Schema A–G output contracts stay unchanged.
- Stack-agnostic shell scripts. Each new check script and each
  `--self-test` mode runs on both Git Bash (Windows) and WSL2 Ubuntu.
- No new external dependencies. The existing toolchain (`bash`, `sed`,
  `grep`, `sha256sum`, `python -m json.tool`, `mktemp`) covers all
  eight items.
- No reopening of v3.1.0 locked trade-offs: CHANGELOG `+108` / `+50`
  bound and Task 12's 4-phrase grep contract.

## Context

- Brief: `docs/briefs/code-craft-principles-deferred.md` (committed in
  `8296382`).
- v3.1.0 release commit pair: `12ab26c` (CHANGELOG + plugin.json
  version bump).
- v3.1.0 review-cycle commits referenced in the brief: `9d20904`,
  `6a8c609`, `d1e3a0e`, `7e63072`, `1ac727d`, `f09de92`.
- v3.1.0 dry-run report (preserved, do not edit):
  `docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md`.
- Existing v3.1.0 plan (do not overwrite — separate document):
  `docs/plans/code-craft-principles-plan.md`.
- Existing v3.1.0 task document (Tasks 6/7 acceptance criteria already
  spell `CODE-CRAFT PRINCIPLES` with hyphen; no edit needed under this
  plan's "keep hyphen" decision):
  `docs/tasks/code-craft-principles-tasks.md`.
- Suggested next step after this plan ships:
  `/kenspc-task docs/plans/code-craft-principles-deferred-plan.md` to
  decompose into the eight implementation tasks.
