# Requirement Brief: Deferred Maintenance Backlog (v3.1.0 Review Tail)

## Outcome

Track the three deliberately-deferred items from the v3.1.0 (Code-Craft
Principles) automated 5-angle review (run 2026-05-14) in their own document —
each with verified current state, the rationale it was punted for, and the
condition that makes it worth acting on — so they are not silently lost, and so
each can be picked up independently when its trigger fires. Success: a future
maintainer opens one document and immediately knows what is outstanding, why it
was deferred, and what condition (if any) gates it.

These three are NOT new work surfaced now; they were triaged as DEFERRED during
the v3.1.0 review (the six items that review fixed are all DONE). This brief
captures only the deferred tail, with each item's origin recorded inline below.

## Scope

**In scope:**

1. **`.gitattributes` LF enforcement on `.md` / `.sh` files.** Add a
   `.gitattributes` at the repo root normalizing line endings for text files
   (at minimum `*.md` and `*.sh`) so cross-platform contributors (the repo is
   developed on Windows / Git Bash and WSL2 Ubuntu) cannot introduce CRLF/LF
   churn — most importantly in the `scripts/check-*.sh` guards, which are
   byte-identity / hash sensitive.
   - **Origin:** v3.1.0 review angle 2 #6, classified NOT APPLICABLE by the
     code-fixer at the time because it is infrastructure-scope, not code-level.
   - **Verified current state (2026-06-29):** no `.gitattributes` exists at the
     repo root.
   - **Trigger / gating condition:** act only if cross-platform line-ending
     drift is actually observed in practice. Until then this is speculative
     infrastructure and adding it pre-emptively risks churn (a normalization
     commit touching many files) for a problem not yet seen.

2. **Three pre-existing dead-anchor links in `plugins/kenspc/CHANGELOG.md`.**
   The links target `README.md#acknowledgments` (misspelled — missing an `e`),
   while the real section anchor in `plugins/kenspc/README.md` is
   `#acknowledgements`. Rename the anchor in the three link occurrences only.
   - **Origin:** v3.1.0 review angle 4 #5. Pre-existing — NOT introduced by
     v3.1.0.
   - **Verified current state (2026-06-29):** present at `CHANGELOG.md` lines
     648, 700, 756, inside the v3.0.0 / v2.0.0 / v1.5.0 historical entries.
   - **Nature:** pure mechanical fix — change `#acknowledgments` →
     `#acknowledgements` in three link targets. The surrounding historical
     CHANGELOG prose is not rewritten.

3. **CHANGELOG line-count upper-bound recalibration.** The v3.1.0 task
   document's Task 14 subtraction-audit applied a `+50` net-line cap to
   `CHANGELOG.md`; both v3.0.3 and v3.1.0 entries exceeded it, and the breach
   was accepted as intentional. Recalibrate the cap (or the audit's treatment
   of CHANGELOG specifically) to a realistic figure for v3-era entries, so the
   subtraction audit stops producing a known-false breach while still catching
   genuine bloat.
   - **Origin:** v3.1.0 Task 14 finding; documented as intentional at the time.
   - **Nature:** a plan/task-template / planning-conventions concern, not a code
     concern. It changes how future task documents set the per-file bound, not
     any plugin behavior.

**Out of scope:**

- Re-opening or re-doing any of the six items the v3.1.0 review already fixed
  (#15, #16, #17, #31, #32, #33) — all DONE.
- Any change to a v3.1.0-locked invariant: the 3-file byte-identity hash on the
  canonical principle blocks, Task 12's four-phrase relocation grep, the
  5-reviewer-agent drift guard, and the canonical-dispatch / verdict-shared
  byte-identity between `task-review` and `task-implement` SKILLs.
- Rewriting the historical content of any CHANGELOG entry (item 2 touches only
  the broken anchor text, not the prose).

**Deferred (within this brief):**

- Nothing further is punted. All three items above are themselves the deferred
  work; the only sequencing note is that item 1 is conditional (acts on
  observed drift) while items 2 and 3 are unconditional but low-priority.

## Failure Modes

- **Item 1 done speculatively.** Adding `.gitattributes` with no observed drift
  is the speculative-feature trap the plugin's own Simplicity First principle
  warns against, and the normalization commit could itself churn line endings
  across many files. The fix is "wrong" if it lands before its trigger.
- **Item 1 normalizes too aggressively or breaks a guard.** A `.gitattributes`
  that forces CRLF, or that re-normalizes the `scripts/check-*.sh` files in a
  way that flips a byte-identity hash, would break the mechanical-check suite —
  the exact cross-platform stability it was meant to protect.
- **Item 2 fixed by editing the heading instead of the links.** Renaming the
  README's `## Acknowledgements` heading (or its slug) to match the broken link
  would "fix" the three CHANGELOG links by breaking every other correct
  reference to that section. The correct direction is link → heading, not
  heading → link. Also wrong if it touches more than the three identified
  anchors or rewrites historical entry prose.
- **Item 3 throws away the audit signal.** Removing the cap entirely (rather
  than recalibrating it) loses the subtraction-audit's ability to catch genuine
  CHANGELOG bloat. Equally wrong: retroactively re-litigating v3.0.3 / v3.1.0's
  already-accepted overages instead of just fixing the bound going forward.

## The Hard Part

These three items are heterogeneous and individually small; the judgment is
mostly about **when / whether**, not **how**. The hard part is resisting the
urge to batch them into one plan when they have three different natural homes:

- **Item 2** is a two-minute mechanical doc fix with no dependencies and no
  trigger condition — it can be done directly whenever convenient (it does not
  really need a plan at all, just a `docs:` commit). Preferred approach: do it
  on its own when someone is next in the CHANGELOG, or as the trivial first step
  of any future housekeeping pass.
- **Item 1** is conditional infrastructure — it should wait for its trigger
  (observed line-ending drift). Preferred approach: leave it parked; do not plan
  it until the trigger fires. If it does fire, it is a small standalone
  infrastructure change.
- **Item 3** is a planning-conventions revision that touches the task-document
  template's subtraction-audit guidance, not the plugin. Preferred approach:
  fold it into the next time the task/plan templates or `docs/release-checklist`
  conventions are revisited, rather than as a one-off.

So the recommended downstream handling is **not** a single plan for all three.
Item 2 can skip planning entirely; items 1 and 3 wait for their respective
triggers and may each warrant their own small plan if and when they activate.
This brief exists to keep all three visible until then.

## Constraints

- **All v3.1.0 invariants stay intact.** The pre-flight mechanical-check suite
  (`docs/release-checklist.md`) must continue to exit 0 on any post-work tree.
- **Repo content is markdown / shell / JSON only.** No application code.
  "build / test / lint" verification = the pre-flight mechanical-check suite.
- **Conventional commits.** `docs:` for the CHANGELOG anchor fix and any
  convention text; infrastructure for `.gitattributes` if/when it lands.
- **Cross-platform (item 1).** Any `.gitattributes` must behave correctly on
  Git Bash (Windows) and WSL2 Ubuntu and must not break the hash-sensitive
  `scripts/check-*.sh` guards.
- **No retroactive churn (item 3).** Do not reopen v3.1.0's accepted CHANGELOG
  overage; recalibrate the bound for future entries only.

## Context

- All three items originated from the v3.1.0 (Code-Craft Principles) automated
  5-angle review run on 2026-05-14, where they were triaged as DEFERRED.
- The code-fixer chose DEFERRED (not "won't fix") for each: item 1 because it is
  infrastructure-scope and not blocking ship; item 2 because it is a pre-existing
  historical-doc issue suited to a cleanup pass; item 3 because it is a
  planning-conventions change, not a code change.
- Current state re-verified on 2026-06-29 (the date this brief was split out):
  `.gitattributes` absent; misspelled anchors live at `CHANGELOG.md` lines 648 /
  700 / 756; the `+50` cap remains in the v3.1.0 task document's Task 14 and was
  exceeded by both v3.0.3 and v3.1.0.

## Discovery Notes

Discovery Mode: rapid-direct

Input clarity was Level 1: the three items were fully scoped with documented
rationale and explicit deferral causes when they were triaged during the v3.1.0
review, so no new discovery conversation was needed — this is a
capture-for-later split-out, not a fresh ideation. The current state of each
item was re-verified against the working tree before writing
(`.gitattributes` absence, the three CHANGELOG anchor line numbers, all task
statuses DONE).

Key framing decisions captured during the split-out:

- **One brief, three different downstream homes.** The user asked for a single
  independent brief, but the items deliberately do not collapse into one plan:
  item 2 is a plan-free mechanical fix, item 1 is trigger-gated infrastructure,
  item 3 is a conventions revision. The brief records this so a future
  `/kenspc-plan` run is not misled into treating them as one work-stream.
- **Item 1 stays conditional.** As triaged in the v3.1.0 review: act only on
  observed cross-platform line-ending drift; adding it pre-emptively is the
  speculative-work failure mode.
- **Item 2 is the only immediately-actionable one.** It has no trigger and no
  dependency; it was kept in this brief (rather than just fixed on the spot)
  only to keep the deferred tail in one tracked place per the user's request.
