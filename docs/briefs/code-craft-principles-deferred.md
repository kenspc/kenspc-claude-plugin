# Requirement Brief: v3.1.x Code-Craft Principles — Deferred Follow-ups

## Outcome

Close the six DEFERRED items from the v3.1.0 (Code-Craft Principles) automated
review without disturbing any of the invariants that v3.1.0 just locked in.
Concretely, after this work the plugin should: (1) read more fluently in the
prose surfaces that are currently rough; (2) carry a harmonized section-header
convention in writer-agent files; (3) gain deeper drift defenses on the new
byte-identity guard script; and (4) standardize the dry-run report terminology
that any future task-review iteration will reuse — all while preserving the
3-file byte-identity hash on canonical principle blocks, Task 12's 4-phrase
relocation grep, and the 3-script drift-guard suite.

## Scope

**In scope:**

1. **(#15) Grammar rewrite of `shared/code-craft-principles.md:104` bullet.**
   Replace `Refactor code unrelated to the current task is out; ...` with a
   fluent sentence (current preferred candidate:
   `Don't refactor code unrelated to the current task — that is out of scope; ...`).
   Constraint: the literal substring `refactor code unrelated to the current task`
   must remain present after the rewrite, since Task 12's relocation grep
   contract still applies.
   **Why now:** The current bullet uses the verb phrase `Refactor code
   unrelated to the current task` as a noun-phrase subject of `is out`, which
   reads as broken English (verb-as-subject). The verbatim phrase is load-
   bearing for Task 12's 4-phrase relocation grep, so during v3.1.0 the
   implementer pinned the wording rather than risk silently breaking the
   grep contract — and the code-fixer added a guard comment (`f09de92`) to
   prevent a well-meaning future contributor from "fixing" the grammar in
   a way that drops the literal substring. The deferred fix is the rewrite
   that keeps the substring inside a fluent sentence.

2. **(#16) Section-header naming convention decision: `CODE-CRAFT PRINCIPLES`
   vs `CODE CRAFT PRINCIPLES`.** Pick one. The existing convention in writer
   agents is ALL CAPS with no hyphens (`CONTEXT YOU WILL RECEIVE`,
   `QUALITY RULES`, `FIXING RULES`, `AUTONOMY BOUNDARIES`, `DONE CRITERIA`).
   Whatever wins is applied to both `agents/task-implementer.md` and
   `agents/code-fixer.md` AND propagated into the Task 6/7 acceptance criteria
   in `docs/tasks/code-craft-principles-tasks.md` in the same commit.
   **Why now:** Inside both `task-implementer.md` and `code-fixer.md`, every
   pre-existing section header is ALL CAPS without hyphens. The new
   `CODE-CRAFT PRINCIPLES` header (added by Task 6/7) is the only header
   with a hyphen — a visible inconsistency in the same file. Quality-reviewer
   flagged this as MEDIUM during the v3.1.0 review because future readers
   infer the writer-agent header convention by glancing at surrounding
   headers; drift here makes the structural rule less self-evident. The
   reason this was deferred is that changing the header in v3.1.0 would
   have put the agent files out of step with the task document's already-
   ratified acceptance criteria (which spell the section name verbatim).

3. **(#17) Dry-run report terminology going forward.** Future task-review
   iterations that produce dry-run reports adopt unambiguous labels:
   `CONDITION-MET` / `CONDITION-NOT-MET` for per-condition evaluation, and
   `FLAG` / `PASS` for the final per-hunk decision. This is a convention
   decision (likely documented in `task-review` SKILL.md and/or the
   `quality-reviewer` agent body), not a rewrite of any existing dry-run.
   **Why now:** In `docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md`
   the word `PASSES` is used per-condition to mean "condition is satisfied
   → bullet *eligible* to flag the hunk", while the final-decision `PASS`
   means "bullet does *not* flag → code is fine". Same word, opposite
   polarity, in the same paragraph (lines 76, 82). A future auditor
   walking the report can easily read `Condition 1 PASSES` as "Condition 1
   is fine" instead of "Condition 1 fires". Establishing the new convention
   prevents the next dry-run from inheriting the same trap; the existing
   v3.1.0 report stays untouched as a historical record of Task 16's
   analysis.

4. **(#31) Anchor-phrase frequency guard in `scripts/check-code-craft-canonical.sh`.**
   Add a check (modeled on `check-canonical-dispatch.sh`'s existing
   frequency-block check) asserting that each of the three target files
   contains ≥1 occurrence of `Simplicity First` and ≥1 of `Surgical Changes`
   outside the byte-identity hash range.
   **Why now:** The byte-identity hash defends the *paragraph content
   between markers*. It does not defend the *principle label* itself.
   A synchronized edit that replaces both canonical blocks across all
   three files with the same different content would still produce
   matching sha256 hashes — and the script would happily exit 0 on a
   tree where the SSoT label has disappeared from the public-facing
   prose. The anchor-phrase frequency check closes this gap: hash defends
   content sameness; frequency defends label survival.

5. **(#32) Automated mutation regression test for the new byte-identity
   guard.** Convert Task 15 Step 6's manual one-shot mutation test into an
   executable fixture (bats-style, shellspec-style, or a small `--self-test`
   flag — author's choice). Runs from the release-checklist mechanical-check
   block alongside the existing six checks.
   **Why now:** Task 15 Step 6 deliberately mutated one character in one
   canonical block, ran the script, confirmed exit non-zero, then reverted.
   The mutation test is recorded only in prose (the task document and
   CHANGELOG entry); the script itself has no negative-path assertion.
   If a future bash / sed / sha256sum / Git Bash compatibility change
   silently breaks `extract_block`'s `/start/,/end/p` extraction (or any
   other piece of the comparison logic), the positive path can still exit
   0 — comparing nothing to nothing also yields equal — and the guard
   would be silently dead for months until a real drift event reveals it.
   The same gap exists for `check-canonical-dispatch.sh`, so the fixture
   should ideally cover both.

6. **(#33) Structural assertion on `quality-reviewer.md`'s two new
   REVIEW CHECKLIST bullets.** Grep-based check that each of the two new
   bullets (over-engineering, drive-by/style-drift) continues to enumerate
   exactly three numbered conditions. May live in the same script as #31
   or as a sibling check.
   **Why now:** The over-engineering and drive-by bullets each rely on
   their three numbered conditions to form a coherent gate — flag only
   when *all three* exclusion conditions hold. A future edit that drops
   one condition (most likely the boundary-validation carve-out, since
   it's the longest and most easily skimmed) would weaken the gate to a
   two-condition over-trigger, generating false-positive flags on
   legitimate boundary validations and eroding reviewer trust. Nothing
   in the repo currently asserts the three-condition structure; the
   only protection is the task document's Task 8 acceptance criteria,
   which catches the breakage at v3.1.0 freeze time but not in any
   later edit. The new structural assertion makes the invariant
   continuously enforced.

**Out of scope:**

- Any change to the byte-identity-hashed content of the canonical principle
  blocks. The Simplicity First and Surgical Changes paragraphs between the
  `<!-- canonical:principle:*:start/end -->` markers are byte-identity locked
  across three files and must not move.
- Rewriting the existing v3.1.0 dry-run report
  (`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md`). That document
  is a historical artifact of Task 16's analysis run and is preserved as-is.
  Item #17 only governs *future* reports.
- Renegotiation of Task 12's four-phrase grep contract. The four literal
  phrases must still grep to 0 matches in `plugins/kenspc/agents/` and ≥1
  in the shared file. Item #15 explicitly preserves the relevant substring.

**Deferred:**

- `.gitattributes` LF enforcement on `.md` / `.sh` files
  (review angle 2 #6, classified NOT APPLICABLE by the code-fixer because
  infrastructure-scope, not code-level). Worth a separate brief if cross-
  platform line-ending drift is observed in practice.
- Three pre-existing dead-anchor links in `CHANGELOG.md` (`#acknowledgments`
  vs `#acknowledgements`) in v3.0.0 / v2.0.0 / v1.5.0 entries
  (review angle 4 #5). Pre-existing, not introduced by v3.1.0; fix in a
  historical-cleanup pass.
- CHANGELOG line-count upper bound recalibration (Task 14's `+50` cap is
  unrealistic for v3-era entries; v3.0.3 and v3.1.0 both exceed it). This
  is a plan/task-template concern, not a code concern — likely belongs in
  a future planning-conventions revision.

## Failure Modes

- **Hash drift introduced.** Any change to the canonical principle paragraphs
  between markers in any of the three files makes `check-code-craft-canonical.sh`
  exit non-zero. Item #15's bullet rewrite sits *outside* the markers (line 104,
  after the `:end` marker at line 99), so it must not touch lines 6-8 or
  96-98 of `shared/code-craft-principles.md`.
- **Relocation grep contract broken.** If item #15's rewrite drops the literal
  substring `refactor code unrelated to the current task`, Task 12's grep
  guard regresses silently. The 4-phrase grep must still produce: 0 matches
  in `agents/`, ≥1 in `shared/code-craft-principles.md`, for each of the
  four pinned phrases.
- **Header decision creates spec/code asymmetry.** If item #16 changes the
  header in agent files without updating the Task 6/7 acceptance criteria
  in `docs/tasks/code-craft-principles-tasks.md`, the task document becomes
  stale. Both must move in the same commit.
- **Script enhancement causes false positives.** Items #31, #32, #33 each
  add new failure modes to the drift-guard suite. If the new checks are
  over-strict (e.g., requiring exactly 1 anchor-phrase occurrence instead of
  ≥1), legitimate edits would be blocked. The acceptance bar for each new
  check is: passes on the current tree, fails on a deliberate violation,
  ignores cosmetic edits unrelated to the invariant.
- **Item #17 documented but not adopted.** Writing the new terminology
  convention into a SKILL or agent body, then producing a future dry-run
  that uses the old `PASS/FAILS` polarity, defeats the purpose. The
  convention needs an enforcement surface (a SKILL.md rule, or a
  `task-review` checklist line).
- **Scope creep into v3.1.0 trade-offs.** This brief explicitly inherits two
  v3.1.0 trade-offs the implementer documented and the reviewers
  acknowledged: (1) CHANGELOG.md net delta +108 vs the Task 14 +50 bound
  is intentional, and (2) the Surgical Changes checklist's four verbatim
  phrases are pinned by Task 12's grep contract. A plan that re-opens
  either of these is out of scope and should be rejected at planning time.

## The Hard Part

The six items split into two natural clusters with different "hard parts":

**Cluster A — Prose / convention decisions (#15, #16, #17).** Each requires
a *judgment call* on wording or naming, then mechanical propagation. The
hard part is making the judgment call without re-opening the v3.1.0 trade-
offs that motivated the deferral. Recommended approach:

- **#15**: pick the candidate `Don't refactor code unrelated to the current
  task — that is out of scope; ...`. This is the simplest rewrite that
  preserves the literal substring and reads fluently. Skip the bikeshed
  on alternative phrasings unless this specific candidate has a concrete
  problem.
- **#16**: lean toward `CODE-CRAFT PRINCIPLES` (keep the hyphen) on the
  grounds that "Code-Craft" is a legitimate hyphenated compound adjective
  in English, AND the hyphen visually distinguishes this section from the
  surrounding two-word ALL-CAPS headers, AND changing it forces a synchronized
  edit across the task document. The cost of keeping the current state is
  one minor inconsistency; the cost of changing is touching three files.
  Defaulting to "keep" minimizes blast radius.
- **#17**: write the convention into the `task-review` SKILL.md's output
  guidance and/or the `quality-reviewer` agent's "when producing a dry-run
  report" section. The hard part is finding the right anchor — likely a
  short paragraph in `task-review/SKILL.md` near the existing CONTEXT-block
  contract.

**Cluster B — Script enhancements (#31, #32, #33).** Each adds a guard.
The hard part is sequencing them so each addition can be tested against a
deliberate counter-example. Recommended approach:

- Implement #31 (anchor-phrase frequency) and #33 (three-condition gate
  structure) first — both are stateless greps and easy to test.
- Implement #32 (mutation regression test) last, because it depends on the
  drift-guard scripts existing in their final shape so the fixture can
  exercise all the failure modes including #31 and #33.
- Decision pending: do #31 and #33 live in one script or two? One script
  is denser; two scripts keep each guard's purpose clear. Lean toward
  *two scripts* to keep the "one guard, one purpose" pattern that the
  existing `check-canonical-dispatch.sh` and `check-review-agent-drift.sh`
  follow.

## Constraints

- **All v3.1.0 invariants stay intact.** Byte-identity hash on canonical
  principle blocks (`scripts/check-code-craft-canonical.sh`), Task 12's
  four-phrase relocation grep, 5-agent reviewer drift guard
  (`scripts/check-review-agent-drift.sh`), canonical-dispatch byte-identity
  between `task-review/SKILL.md` and `task-implement/SKILL.md`
  (`scripts/check-canonical-dispatch.sh`). The pre-flight mechanical-check
  suite must continue to exit 0 on the post-work tree.
- **Conventional commits, per task.** `fix:` for grammar / convention /
  bug-class items, `feat:` for new script behavior, `docs:` for terminology
  conventions written into SKILL or agent bodies.
- **No SKILL or agent interface changes for callers.** CONTEXT block contracts
  and Schema A-G output contracts stay unchanged.
- **Stack-agnostic shell scripts.** Any new check script must run on both
  Git Bash (Windows) and WSL2 Ubuntu, matching the existing scripts.
- **No new external dependencies.** The existing toolchain (`bash`, `sed`,
  `grep`, `sha256sum`, `python -m json.tool`) covers all six items.
- **No reopening of v3.1.0 locked trade-offs.** CHANGELOG +108 / +50 bound
  and Task 12's 4-phrase grep contract are both load-bearing for v3.1.0
  and must not be renegotiated in this work.

## Context

- All six items originated from the v3.1.0 (Code-Craft Principles) automated
  5-angle review run on 2026-05-14. The full review reports, accountability
  list, and rationale for each Action (FIXED / DEFERRED / NOT APPLICABLE /
  DEDUPED) are in the orchestrator's session transcript and the commits
  `9d20904`, `6a8c609`, `d1e3a0e`, `7e63072`, `1ac727d`, `f09de92`.
- The code-fixer agent chose DEFERRED (not "won't fix") for these six
  specifically because each one requires either: (a) renegotiation of a
  v3.1.0 contract that the reviewers and the implementer agreed to lock
  (items #15, #16, #17), or (b) defense-in-depth tooling work that isn't
  blocking ship (items #31, #32, #33). The v3.1.0 release passed all
  pre-flight mechanical checks and was verified PASS by the regression-
  verifier.
- The v3.1.0 commit pair (CHANGELOG + `plugin.json` version bump) is
  `12ab26c`. The version on disk is `3.1.0`. This brief targets a future
  v3.1.x release; the exact version is a planning decision.
- This plugin/skill revision repo contains only markdown, shell scripts,
  and JSON. "build / test / lint" verification means the pre-flight
  mechanical-check suite from `docs/release-checklist.md` (3 JSON
  validations + 3 shell drift guards as of Task 15). No application code
  is in scope for any item here.

## Discovery Notes

Discovery Mode: rapid-direct

This brief was produced without invoking `/kenspc-brief` formally. Discovery
effectively happened in the prior conversation turn, where the user asked
"why?" for each of the six DEFERRED items and received rationale for each.
The user then requested this brief as a single capture for downstream
planning via `/kenspc-plan`. Input clarity was Level 1 (six fully-scoped
items with documented rationale and explicit deferral causes); no
inference was needed.

Key trade-offs surfaced during the prior Q&A:

- **#15 vs Task 12's grep contract**: the four pinned phrases in the
  Surgical Changes checklist are intentional, not duplication mistakes.
  Any rewrite must preserve the literal substring; the simplest
  candidate is `Don't refactor code unrelated to the current task — that
  is out of scope; ...`.
- **#16's blast radius**: changing the section header touches at minimum
  three files (two agent files + the task document's Tasks 6/7 acceptance
  criteria). Default-keep is the lower-risk option.
- **#17's enforcement surface**: writing the convention into prose without
  a checklist anchor or a SKILL.md rule risks the convention drifting
  immediately. The terminology change needs a host.
- **#31 / #32 / #33 sequencing**: #32's mutation test depends on the
  drift-guard suite being in its final shape, so #31 and #33 land first.
- **One brief covers six items by user request.** The items split
  naturally into two clusters (prose/convention vs script enhancements);
  the downstream plan may choose to schedule the clusters separately
  while still being one plan document. If the resulting plan feels too
  broad, the brief can be split before re-running `/kenspc-plan`.

Suggested next step: `/kenspc-plan docs/briefs/code-craft-principles-deferred.md`.
