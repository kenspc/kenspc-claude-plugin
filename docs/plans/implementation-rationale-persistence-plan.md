# Plan: Persist implementation-period rationale per task (stall-safe)

## Objective

Make the implementer's per-task **decisions / changes / tradeoffs** durable on
disk incrementally — inside the existing task document — so a mid-run stall (the
context ceiling reached while `autoCompactEnabled: false` waits for a manual
`/compact`) cannot lose the rationale behind work that was already committed. The
end-of-run Schema D summary becomes a roll-up assembled from what is already on
disk, rather than content first written at the final render.

**In scope:**

- `plugins/kenspc/agents/task-implementer.md` — the core behavioural change
  (PROCESSING APPROACH, DONE CRITERIA, STUCK HANDLING, OUTPUT FORMAT / Schema D).
- `plugins/kenspc/skills/task-implement/SKILL.md` — minimal Schema D-wording sync
  in Phase 1 Step 5 (no `version:` bump — see Resolved Decisions).
- `plugins/kenspc/references/task-document-example.md` — show the new per-task
  block location/format on the one DONE task, plus a one-line clarifier.
- `plugins/kenspc/.claude-plugin/plugin.json` — version bump.
- `plugins/kenspc/CHANGELOG.md` — new release entry.

**Out of scope:**

- No new file format; no separate notes file (e.g. `implementation-notes.md`);
  no HTML. The task document stays the single artifact for this content.
- No change to `task-review` or any of the 5 reviewer agents — criterion 5 is
  satisfied for free by `requirements-reviewer`'s existing whole-document read
  path. No new review wiring, CONTEXT keys, or review input channel.
- No change to `generate-task` — a freshly authored task is `Status: TODO` and
  has no implementation rationale yet; the block is written by `task-implement`
  at completion time, not at authoring time.
- No Schema D *shape* redesign beyond making its prose sections a roll-up.
- No change to per-task commit granularity.
- No edits to byte-identity-locked sections: the canonical dispatch block in
  `task-implement` / `task-review`; the shared verdict block; the code-craft
  canonical principle blocks in `task-implementer.md`; the 5 reviewer agents'
  shared sections.

## Background

The brief's instruction to "read the live files, do not trust this description"
surfaced a discrepancy worth recording, because it narrows the change:

- **Already stall-safe today.** The task's `**Status:**` marker (TODO → DONE /
  BLOCKED) is written back into the task document per task and committed in the
  same per-task commit as the code (PROCESSING APPROACH; DONE CRITERIA). A
  BLOCKED task's blocking reason is already recorded under that task in the
  document (STUCK HANDLING). Both survive a stall.
- **The actual gap.** A DONE task's decisions / changes / tradeoffs are *not*
  persisted per task. In `task-implementer.md`'s OUTPUT FORMAT, `## Decisions
  made` and `## Post-implementation notes` are **run-level flat bullet lists**,
  collected in agent context and first written at the end-of-run Schema D
  render. A stall before that render loses the reasoning behind already-committed
  work.

The chosen strategy is locked (Option C): checkpoint per-task rationale into the
existing task document's per-task entry as each task completes, and turn the
end-of-run Schema D into a roll-up of what is already on disk. Because the change
extends a precedent that already exists for Status and BLOCKED reason, it does
not introduce a new mechanism — it widens an existing write to cover DONE-task
rationale and re-sources the final summary from disk.

This is a minor feature addition: new implementer behaviour, no CONTEXT block
schema change, no SKILL or agent interface change for callers, no review-side
change.

## Technical Approach

The three locked design decisions (the brief's three open questions, resolved
with the owner):

| # | Question | Decision |
|---|----------|----------|
| D1 | Placement / format of per-task rationale | An `**Implementation notes:**` block directly under each task's `**Status:**` line. |
| D2 | Commit model | Fold the block into the task's existing per-task commit. |
| D3 | How Schema D references the persisted rationale | Keep the shape; the prose sections become read-from-disk roll-ups with a source-of-truth pointer. |

### D1 — Per-task block placement and format

Directly under the task entry's `**Status:**` line, an `**Implementation
notes:**` block. The label mirrors the document's existing `**Status:**` /
`**Acceptance criteria:**` bold-label convention and is distinct from the
document-level `## Notes` heading. One block convention serves both terminal
states:

DONE:

```
**Status:** DONE

**Implementation notes:**
- Decisions: <non-trivial choices and their rationale; "none" if trivial>
- Changes/tradeoffs: <deviations from or elaborations beyond the task spec, and
  any tradeoffs accepted; "none" if nothing notable>
```

BLOCKED:

```
**Status:** BLOCKED

**Implementation notes:**
- Blocked: <what was attempted / root cause / what the user must do to unblock>
```

The sub-bullets are the illustrative shape, not a mandated checklist — the block
records the decisions/changes/tradeoffs (or blocking reason) for the task, framed
as outcomes. "Changes/tradeoffs" is *not* a file list: the touched-files
enumeration stays in the Schema D `## Tasks` table and in git, so the block does
not duplicate it.

Trade-off accepted (owner's choice): placing the block under the Status line puts
post-implementation output ahead of the task's description / acceptance criteria
in reading order. The bold `**Implementation notes:**` label demarcates output
from spec, and `requirements-reviewer` reads the whole entry, so this does not
break the review read path; it keeps status and its rationale colocated for a
quick "what / why" scan during stall recovery.

### D2 — Commit model

The block is written into the task document in the **same Edit and the same
per-task commit** that already carries the code change and the Status flip. No
new commit; no change to commit granularity.

The load-bearing stall-safety guarantee is that the block is **Edited to disk
before the next task starts** — a context-ceiling stall pauses the agent without
resetting the working tree, so the on-disk content survives whether or not it has
been committed. Folding the block into the existing per-task commit additionally
keeps the git trail and the on-disk trail in sync for DONE tasks. A BLOCKED task,
which produces no code commit today (its Schema D `Commit` cell is `—`), writes
its block to disk before proceeding; that on-disk write is what satisfies
criterion 2, and the `Commit` cell stays `—`.

### D3 — Schema D as a roll-up

Schema D keeps its existing shape (the `## Tasks` table is unchanged). Its three
prose sections — `## Blocked tasks (prose)`, `## Decisions made`, `##
Post-implementation notes` — are **assembled by reading the per-task
`**Implementation notes:**` blocks back from the task document** after all tasks
are processed, not recalled from context. Each rolled-up entry is prefixed by its
task ID, and a one-line pointer names the task document as the source of truth:

```
## Decisions made
(rolled up from the per-task Implementation notes in <task-doc path>)
- T-002: bcrypt cost 12 per team convention
- T-004: chose middleware over per-route guard for reuse

## Post-implementation notes
- T-002: extracted a shared hashPassword helper for reuse by the login task
- Source of truth: per-task Implementation notes under each task entry in
  <task-doc path>.
```

Because the agent writes each block to disk and moves on, by end-of-run the
rationale no longer lives in context to be "dumped" — reading the document is the
natural source, which is what makes the roll-up faithful after a partial run.
Schema D is an ephemeral render (a returned message, also embedded into the
Phase 2 Schema G report), never a persisted file, so inlining the rolled-up text
there is a *view* over the single persisted source, not a second source of truth.

## Implementation Steps

Steps 1–4 edit one file (`task-implementer.md`) and are the core change; Step 5
depends on the Schema D framing fixed in Step 4; Step 6 depends on the D1 format;
Steps 7–8 are release mechanics and verification.

**Step 1 — `task-implementer.md` PROCESSING APPROACH.**
Extend the per-task loop step that updates Status: after verification passes,
write the `**Implementation notes:**` block under the task's Status line, and
include it in the same commit as the code and the status update. Frame the why
(durable on disk before the next task, so a stall cannot lose committed work's
rationale).
*Acceptance:* the per-task step names the block, its location (under the Status
line), and "same commit"; no `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` and no
step-heavy execution list is introduced.

**Step 2 — `task-implementer.md` DONE CRITERIA.**
Add that every processed task has its `**Implementation notes:**` block persisted
in the document before the next task starts (DONE: in the code+status commit;
BLOCKED: written to disk), and that the Schema D prose sections are assembled
from those persisted blocks rather than from context.
*Acceptance:* DONE CRITERIA mention per-task persistence and read-from-disk
assembly.

**Step 3 — `task-implementer.md` STUCK HANDLING.**
Re-point the existing "record the blocking reason under that task in the task
document" to the same `**Implementation notes:** → - Blocked:` block and
location, so blocked and done tasks share one convention and one location.
*Acceptance:* STUCK HANDLING references the shared block; no second/parallel
notes location is created.

**Step 4 — `task-implementer.md` OUTPUT FORMAT (Schema D).**
Reframe `## Blocked tasks (prose)`, `## Decisions made`, and `##
Post-implementation notes` as roll-ups assembled by reading the per-task blocks
(task-ID-prefixed), and add the source-of-truth pointer line. Leave the `##
Tasks` table and the code-craft canonical principle blocks
(`<!-- canonical:principle:* -->`) untouched.
*Acceptance:* the three sections state they are assembled from the per-task
Implementation notes in the task document; `bash scripts/check-code-craft-canonical.sh`
still exits 0.

**Step 5 — `task-implement/SKILL.md` (minimal).**
In Phase 1 Step 5, add one clause noting that the rendered Decisions /
Post-implementation / Blocked prose are roll-ups of the per-task notes now
persisted in the task document (still rendered verbatim from the agent's output).
Leave the `version:` field at `3.0.0` (owner's resolved decision — see Resolved
Decisions; the project CLAUDE.md keeps all six SKILL `version:` fields uniform at
`3.0.0`). All edits stay outside the
`<!-- canonical:dispatch:start -->` / `<!-- canonical:dispatch:end -->` markers
and outside the shared verdict block.
*Acceptance:* `bash scripts/check-canonical-dispatch.sh` and
`bash scripts/check-verdict-shared.sh` still exit 0; the `version:` field is
unchanged at `3.0.0`.

**Step 6 — `references/task-document-example.md`.**
Add an `**Implementation notes:**` block under Task 1's `**Status:** DONE` line
demonstrating the location and format, and add a one-line clarifier that the
block is written by `task-implement` at completion time (so users authoring a
task document do not think they must pre-write it). The IN PROGRESS / TODO tasks
get no block.
*Acceptance:* the example shows the block on the DONE task only and includes the
clarifier.

**Step 7 — `plugin.json` + `CHANGELOG.md`.**
Bump `plugin.json` `version 3.2.0 → 3.3.0`. Add a `## 3.3.0 — 2026-06-29`
CHANGELOG entry (Rationale / Added / Changed) recording: per-task rationale now
checkpointed into the task document as each task completes; Schema D reframed as a
roll-up; example doc updated; explicitly note no CONTEXT-schema change and no
review-side change.
*Acceptance:* `plugin.json` parses as valid JSON; the dated changelog entry is
present.

**Step 8 — Verification.**
Run the mechanical guards and constraint greps (see Verification Strategy).
*Acceptance:* all guard scripts exit 0; greps confirm the constraints.

## Verification Strategy

Prompt-text changes verify structurally and mechanically, not via build/test —
the repo's own lesson is that prompt changes are not code changes and must be
checked by inspection, with the final proof being a runtime trace. Mapping to the
five success criteria:

- **C1 / C2 (incremental durability, survives a stall after task N):** Steps 1–3
  make "write the block to disk before the next task starts" unambiguous in
  PROCESSING APPROACH, DONE CRITERIA, and STUCK HANDLING.
- **C3 (Schema D assembled from disk):** Step 4 states read-from-disk assembly,
  reinforced by the mechanism (nothing left in context to regenerate from).
- **C4 (no new notes file):** `grep -ri "implementation-notes" plugins/` returns
  no new file artifact; all content lives in the task document.
- **C5 (`task-review` picks it up free):** `task-review` and the 5 reviewer
  agents are untouched; `requirements-reviewer` already reads the whole task
  document, so the per-task blocks are in its read path.

Mechanical guards (must all exit 0), confirming no locked section drifted:

```
bash scripts/check-review-agent-drift.sh
bash scripts/check-canonical-dispatch.sh
bash scripts/check-verdict-shared.sh
bash scripts/check-code-craft-canonical.sh
bash scripts/check-quality-reviewer-bullet-structure.sh
cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null
```

Aggressive-language check on the edited files (no new directive tokens
introduced): `grep -rnwE 'MUST|NEVER|CRITICAL|ULTRATHINK'` over the touched
agent/skill files returns nothing new.

Final proof (owner, post-merge): a dogfood `/kenspc-task-implement` run,
inspecting the task document mid-flight to confirm each completed task's
`**Implementation notes:**` block appears on disk before the next task begins,
and that the end-of-run Schema D matches the persisted blocks.

## Risks and Mitigations

- **The agent shortcuts Schema D from context instead of disk.** Primary
  mitigation is the mechanism itself: writing each block per task and moving on
  means the rationale is no longer held in context at end-of-run, so reading the
  document is the natural path. Step 4's wording states it explicitly as backup.
- **Under-Status placement interleaves output into the spec.** The
  `**Implementation notes:**` label demarcates output from spec; the reviewer
  reads the whole entry. Accepted trade-off (owner's choice) for status/rationale
  colocation.
- **Example template misread as an author-time field.** Step 6's one-line
  clarifier states the block is written at completion by `task-implement`.
- **Touching a locked section by accident.** All four guard scripts plus the
  verdict-shared guard are run in Step 8; edits are scoped to sections outside
  every canonical marker.

## Resolved Decisions

- **SKILL `version:` field stays at `3.0.0` (resolved with the owner — Option A).**
  The brief's guardrail said to bump every touched SKILL.md `version:` "to match",
  which would have jumped `task-implement/SKILL.md` to `3.3.0` while the other
  five stayed at `3.0.0`. That contradicts the project CLAUDE.md ("SKILL.md
  Frontmatter Fields") invariant that all six SKILL `version:` fields stay uniform
  at `3.0.0`, deliberately decoupled from the plugin version, bumped only on a v4
  architecture rewrite (all six together). The brief's `(v3.x convention)` aside
  shows it meant to follow the convention, not override it — and the documented
  convention, matched by the 3.1.x / 3.2.0 release practice, is "bump only
  `plugin.json`". Decision: follow CLAUDE.md. `task-implement/SKILL.md` stays at
  `3.0.0`; the release is tracked by `plugin.json` (`3.2.0 → 3.3.0`) and the
  CHANGELOG entry; CLAUDE.md is not edited.

## Post-merge (owner)

Run `/plugin marketplace update` so Claude Code picks up the new version (it
caches plugins by version). Not attempted as part of this work.
