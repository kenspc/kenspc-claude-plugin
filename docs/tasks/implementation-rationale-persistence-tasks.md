# Persist Implementation-Period Rationale Per Task — Task Document

## Context

Make the implementer's per-task **decisions / changes / tradeoffs** durable on
disk incrementally — inside the existing task document — so a mid-run stall
(context ceiling reached while `autoCompactEnabled: false` waits for a manual
`/compact`) cannot lose the rationale behind work already committed. The
end-of-run Schema D summary becomes a roll-up assembled from what is already on
disk. The strategy is locked (Option C): widen the existing per-task write that
already persists `**Status:**` to also persist an `**Implementation notes:**`
block, and re-source the final Schema D prose from disk.

This is plugin/skill revision work — files touched are markdown (agent `.md`,
`SKILL.md`, `references/*.md`, `CHANGELOG.md`) and JSON (`plugin.json`). No
application code is written. "Build / test / lint" verification for prompt-text
changes is the project's pre-flight mechanical-check suite (the five
`scripts/check-*.sh` drift/structure guards + JSON sanity), per
`docs/release-checklist.md` — not a compiler or test runner. The final proof is
a post-merge runtime trace (owner, out of scope for these tasks).

Related plan: `docs/plans/implementation-rationale-persistence-plan.md`

Plan ↔ Task mapping: Plan Steps 1–4 (all editing `task-implementer.md`, one
coherent atomic change) collapse into Task 1; Steps 5–8 map 1:1 to Tasks 2–5.
Each task's description cites its plan Step(s) as the canonical source for what
to do; the criteria below are the local DONE bar.

Dependency note: Tasks 2 and 3 cannot start until Task 1 is DONE — Step 5's
clause references the Schema D framing fixed in Step 4, and the example block
must mirror the D1 format Task 1 writes into the live agent. Task 4
(version + CHANGELOG) records the changes from Tasks 1–3. Task 5 (final
verification) is the all-green gate over every prior task.

Out of scope (per plan): no new file format, no separate notes file, no HTML;
no change to `task-review` or the 5 reviewer agents; no change to `generate-task`;
no Schema D *shape* redesign beyond making its prose sections a roll-up; no
change to per-task commit granularity; no edits to any byte-identity-locked
section (canonical dispatch block, shared verdict block, code-craft canonical
principle blocks, the 5 reviewer agents' shared sections).

## Tasks

### Task 1: Persist per-task Implementation notes block + reframe Schema D as roll-up in `task-implementer.md`

**Status:** DONE

**Implementation notes:**
- Decisions: none — followed plan Steps 1–4 verbatim; the four edited sections (PROCESSING APPROACH, DONE CRITERIA, STUCK HANDLING, OUTPUT FORMAT/Schema D) all sit outside the `<!-- canonical:principle:* -->` markers, so no locked block was touched.
- Changes/tradeoffs: framed the Schema D `## Decisions made` and `## Post-implementation notes` roll-ups to source from the `Decisions:` and `Changes/tradeoffs:` sub-bullets respectively (a natural mapping the plan implied via D3), and kept the run-level Post-implementation observations the original wording already allowed (missing test framework, new dependency, etc.) so no reviewer-facing information is lost in the reframe.

Plan Steps 1–4 (single coherent change to one file). Edit four sections of the
agent so per-task rationale is written to disk before the next task starts, and
the end-of-run Schema D prose is assembled by reading those blocks back:

1. **PROCESSING APPROACH (Step 1).** Extend the per-task step that updates
   Status: after verification passes, write an `**Implementation notes:**` block
   directly under the task's `**Status:**` line, and include it in the same
   commit as the code and the status update. Frame the why (durable on disk
   before the next task, so a stall cannot lose committed work's rationale).
   The block format (D1): for DONE tasks, sub-bullets capturing
   `Decisions:` (non-trivial choices + rationale; "none" if trivial) and
   `Changes/tradeoffs:` (deviations/elaborations beyond the task spec + accepted
   tradeoffs; "none" if nothing notable). "Changes/tradeoffs" is *not* a file
   list — the touched-files enumeration stays in the Schema D `## Tasks` table
   and git. The sub-bullets are the illustrative shape, not a mandated checklist.
2. **DONE CRITERIA (Step 2).** Add that every processed task has its
   `**Implementation notes:**` block persisted in the document before the next
   task starts (DONE: in the code+status commit; BLOCKED: written to disk), and
   that the Schema D prose sections are assembled from those persisted blocks
   rather than from context.
3. **STUCK HANDLING (Step 3).** Re-point the existing "record the blocking
   reason under that task" to the same `**Implementation notes:**` block with a
   `- Blocked:` line, so blocked and done tasks share one convention and one
   location. Do not create a second/parallel notes location.
4. **OUTPUT FORMAT / Schema D (Step 4).** Reframe `## Blocked tasks (prose)`,
   `## Decisions made`, and `## Post-implementation notes` as roll-ups assembled
   by reading the per-task blocks (each rolled-up entry task-ID-prefixed), and
   add a source-of-truth pointer line naming the task document. Leave the
   `## Tasks` table and the `<!-- canonical:principle:* -->` code-craft blocks
   untouched.

**Files to modify:**
- `plugins/kenspc/agents/task-implementer.md`

**Acceptance criteria:**
- PROCESSING APPROACH names the `**Implementation notes:**` block, its location (under the `**Status:**` line), and "same commit"; no step-heavy execution list is introduced.
- DONE CRITERIA mention per-task persistence (DONE in the code+status commit, BLOCKED written to disk before the next task) and read-from-disk Schema D assembly.
- STUCK HANDLING references the shared `**Implementation notes:** → - Blocked:` block; no second notes location exists.
- The three Schema D prose sections state they are assembled (task-ID-prefixed) from the per-task Implementation notes, with a source-of-truth pointer line; the `## Tasks` table is unchanged.
- The `<!-- canonical:principle:* -->` blocks are byte-unchanged: `bash scripts/check-code-craft-canonical.sh` exits 0.
- No new `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` tokens introduced in this file.
- Single conventional commit touching only this file.

---

### Task 2: Sync Schema D roll-up wording in `task-implement/SKILL.md` Phase 1 Step 5

**Status:** DONE

**Implementation notes:**
- Decisions: none — added the single clause to the existing "render ... verbatim from the agent's output" sentence in Phase 1 Step 5, well outside both the `<!-- canonical:dispatch:* -->` and `<!-- canonical:verdict-shared:* -->` markers.
- Changes/tradeoffs: explicitly kept "still renders verbatim from the agent's output rather than re-reading the document" so the clause does not accidentally read as instructing the orchestrator to re-source Schema D itself (that re-sourcing is the implementer agent's job, per Task 1). `version:` left at `3.0.0` per the owner's resolved decision and project CLAUDE.md.

Depends on: Task 1

Plan Step 5. In Phase 1 "Step 5: Render Schema D and brief progress update", add
one clause noting that the rendered Decisions / Post-implementation / Blocked
prose are roll-ups of the per-task notes now persisted in the task document
(still rendered verbatim from the agent's output). Leave the `version:` field at
`3.0.0` (owner's resolved decision — the project CLAUDE.md keeps all six SKILL
`version:` fields uniform at `3.0.0`; releases are tracked by `plugin.json`
only). All edits stay outside the `<!-- canonical:dispatch:start -->` /
`<!-- canonical:dispatch:end -->` markers and outside the
`<!-- canonical:verdict-shared:* -->` block.

**Files to modify:**
- `plugins/kenspc/skills/task-implement/SKILL.md`

**Acceptance criteria:**
- Phase 1 Step 5 gains one clause framing the rendered prose as roll-ups of the per-task persisted notes (still verbatim from the agent's output).
- The `version:` field is unchanged at `3.0.0`.
- `bash scripts/check-canonical-dispatch.sh` exits 0.
- `bash scripts/check-verdict-shared.sh` exits 0.
- No new `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` tokens introduced in this file.
- Single conventional commit touching only this file.

---

### Task 3: Demonstrate the Implementation notes block in `references/task-document-example.md`

**Status:** TODO

Depends on: Task 1

Plan Step 6. Add an `**Implementation notes:**` block under Task 1's
`**Status:** DONE` line demonstrating the D1 location and format (mirroring what
Task 1 writes into the live agent), and add a one-line clarifier that the block
is written by `task-implement` at completion time — so a user authoring a task
document does not think they must pre-write it. The IN PROGRESS task (Task 2) and
the TODO tasks (Tasks 3–5) get no block.

**Files to modify:**
- `plugins/kenspc/references/task-document-example.md`

**Acceptance criteria:**
- An `**Implementation notes:**` block appears under the DONE task's `**Status:**` line only; no block on the IN PROGRESS or TODO tasks.
- A one-line clarifier states the block is written by `task-implement` at completion time, not at authoring time.
- Single conventional commit touching only this file.

---

### Task 4: Version bump + CHANGELOG entry

**Status:** TODO

Depends on: Task 1, Task 2, Task 3

Plan Step 7. Bump `plugin.json` `version` `3.2.0` → `3.3.0`. Add a
`## 3.3.0 — 2026-06-29` CHANGELOG entry (Rationale / Added / Changed) recording:
per-task rationale is now checkpointed into the task document as each task
completes; Schema D reframed as a roll-up assembled from those per-task blocks;
the example doc updated; and explicitly note no CONTEXT-schema change and no
review-side change. The new entry goes above the existing `## 3.2.0 — 2026-06-29`
entry.

**Files to modify:**
- `plugins/kenspc/.claude-plugin/plugin.json`
- `plugins/kenspc/CHANGELOG.md`

**Acceptance criteria:**
- `plugin.json` `version` reads `3.3.0` and the file parses as valid JSON (`cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool` exits 0).
- A dated `## 3.3.0 — 2026-06-29` CHANGELOG entry is present with Rationale / Added / Changed sections covering the four points above, including the explicit "no CONTEXT-schema change, no review-side change" note.
- Single conventional commit touching only these two files.

---

### Task 5: Final verification — guard scripts + constraint greps

**Status:** TODO

Depends on: Task 1, Task 2, Task 3, Task 4

Plan Step 8. Run the full mechanical-guard suite and the plan's constraint greps
to confirm no locked section drifted and the out-of-scope constraints hold. This
task edits no source files (other than its own status); the acceptance criteria
are the script exit codes and grep results.

Guards to run:
```
bash scripts/check-review-agent-drift.sh
bash scripts/check-canonical-dispatch.sh
bash scripts/check-verdict-shared.sh
bash scripts/check-code-craft-canonical.sh
bash scripts/check-quality-reviewer-bullet-structure.sh
cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null
```

Constraint greps:
- `grep -ri "implementation-notes" plugins/` returns no new file artifact (C4 — all content lives in the task document, no separate notes file).
- `grep -rnwE 'MUST|NEVER|CRITICAL|ULTRATHINK'` over the touched agent/skill files (`task-implementer.md`, `task-implement/SKILL.md`) returns nothing new.

**Files to modify:**
- None (verification only).

**Acceptance criteria:**
- All five `scripts/check-*.sh` guards exit 0 and the `plugin.json` JSON parse exits 0.
- `grep -ri "implementation-notes" plugins/` shows no new notes-file artifact.
- The aggressive-language grep over the touched files surfaces no newly introduced directive tokens.
- Single conventional commit (status update only).

---

## Notes

- Verification model: prompt-text changes verify structurally and mechanically,
  not via build/test. The five success criteria (C1/C2 incremental durability,
  C3 Schema D assembled from disk, C4 no new notes file, C5 `task-review` picks
  it up free) are satisfied by Tasks 1–3 wording plus the Task 5 greps; C5 needs
  no code — `requirements-reviewer` already reads the whole task document, so the
  per-task blocks are in its read path.
- Locked-section safety: all edits are scoped outside every canonical marker.
  Task 1 leaves `<!-- canonical:principle:* -->` untouched; Task 2 stays outside
  `<!-- canonical:dispatch:* -->` and `<!-- canonical:verdict-shared:* -->`.
  Task 5 is the mechanical proof.
- Post-merge (owner, out of scope): run `/plugin marketplace update` so Claude
  Code picks up `3.3.0`; then a dogfood `/kenspc-task-implement` run inspecting
  the task document mid-flight to confirm each completed task's
  `**Implementation notes:**` block appears on disk before the next task begins.
