# Code-Craft Principles — Task Document

## Context

Add a single new shared resource — `plugins/kenspc/shared/code-craft-principles.md` —
that defines two code-craft principles (Simplicity First, Surgical Changes)
with worked C# / TypeScript examples. Relocate matching scope-creep
constraints from three agents (`task-implementer`, `code-fixer`,
`quality-reviewer`) into this single source of truth. Update repo-root
`CLAUDE.md`, plugin `README.md`, `CHANGELOG.md`, `plugin.json`, and add a
new byte-identity check script.

This is plugin/skill revision work — files touched are markdown (agent .md,
SKILL.md, shared/*.md, CLAUDE.md, README.md, CHANGELOG.md), shell scripts
(`scripts/check-*.sh`), and JSON (`plugin.json`). No application code is
written. "Build / test / lint" verification for each task is the project's
pre-flight mechanical-check suite (JSON sanity + drift guards), per
`docs/release-checklist.md`. After Task 15 lands the suite expands by one
script.

Related plan: `docs/plans/code-craft-principles-plan.md`

Plan ↔ Task mapping: each task maps to exactly one plan Implementation
Step (1.1 → Task 1, 1.2 → Task 2, ..., 4.5 → Task 16). Each task's
description cites the plan Step as the canonical source for what to do;
the criteria listed below are the local DONE bar.

Cross-phase dependency note: Tasks 6 and 7 (agent inlining) cannot start
until Tasks 2 and 3 are DONE — the byte-identity guarantee requires the
canonical source content to exist first. Task 15's byte-identity check
script depends on all four of Tasks 2, 3, 6, 7 being DONE before it can
return 0.

## Tasks

### Task 1: Create `shared/code-craft-principles.md` skeleton

**Status:** DONE

Plan Step 1.1. Create the new file with section skeleton: top-level
header `# Code-Craft Principles`, a one-paragraph Goal, two principle
section headers (`## Simplicity First`, `## Surgical Changes`), one
`## How Each Agent Applies These` section, and one
`## What This File Does NOT Define` section. Each subsection body is a
single `TODO` placeholder line. The two principle headings must read
exactly `## Simplicity First` and `## Surgical Changes` (case and
spacing) so GitHub auto-slug produces the anchors `#simplicity-first`
and `#surgical-changes` that Task 13 will verify.

**Files to create:**
- `plugins/kenspc/shared/code-craft-principles.md`

**Acceptance criteria:**
- File exists at exactly the path above.
- Five section headers present in this order: `# Code-Craft Principles`, `## Simplicity First`, `## Surgical Changes`, `## How Each Agent Applies These`, `## What This File Does NOT Define`.
- Each `##` subsection body is a single `TODO` placeholder line (no content yet).
- Principle headings spelled exactly `## Simplicity First` and `## Surgical Changes`.
- Single conventional commit touching only this file.

---

### Task 2: Write Simplicity First principle and two examples

**Status:** DONE

Depends on: Task 1

Plan Step 1.2. Replace the Simplicity First section's TODO with:

1. One rationale-form principle paragraph (the word "Why" appears in or near the statement).
2. A checklist of 4–6 bullets translating the principle to concrete decisions (e.g., "don't add error handling for impossible scenarios", "don't add flexibility or configurability that wasn't requested", "if 200 lines was written but 50 lines would do, rewrite").
3. Two `❌ / ✅` diff examples — one in C#, one in TypeScript — each ≤ 25 lines per side. The C# example demonstrates over-abstraction (e.g., a service that needs one method, written with a strategy pattern). The TypeScript example demonstrates a speculative-feature trap (e.g., an endpoint with `option1` / `option2` / `option3` flags that were never requested).

The one-paragraph principle statement must be bounded by HTML-comment markers exactly as:

```
<!-- canonical:principle:simplicity-first:start -->
**Simplicity First.** ... (the rationale-form paragraph) ...
<!-- canonical:principle:simplicity-first:end -->
```

Only the principle paragraph sits between these markers (no blank lines outside the paragraph itself, no checklist content, no examples).

**Files to modify:**
- `plugins/kenspc/shared/code-craft-principles.md`

**Acceptance criteria:**
- Rationale-form paragraph present with "Why" inside or adjacent.
- Paragraph wrapped exactly by the `canonical:principle:simplicity-first:start` / `:end` markers.
- 4–6 checklist bullets follow the markered block.
- Two diff examples present, one labeled C#, one labeled TypeScript; each side ≤ 25 lines.
- No example code uses Python, Java, Rust, Go, or any language outside C# / TypeScript scope.

---

### Task 3: Write Surgical Changes principle and two examples

**Status:** DONE

Depends on: Task 1

Plan Step 1.3. Replace the Surgical Changes section's TODO with:

1. One rationale-form principle paragraph.
2. A checklist of 4–6 bullets (e.g., "don't 'improve' adjacent code, comments, or formatting", "don't refactor things that aren't broken", "match existing style even when you'd write it differently", "remove imports/variables that your changes orphaned, but don't remove pre-existing dead code").
3. Two `❌ / ✅` diff examples — one in C#, one in TypeScript — covering drive-by refactoring and style drift respectively. Each side ≤ 25 lines.

The principle paragraph must be bounded by:

```
<!-- canonical:principle:surgical-changes:start -->
**Surgical Changes.** ... (the rationale-form paragraph) ...
<!-- canonical:principle:surgical-changes:end -->
```

Same content rules as Task 2's marker block (paragraph only between the markers).

**Files to modify:**
- `plugins/kenspc/shared/code-craft-principles.md`

**Acceptance criteria:**
- Same shape as Task 2 (rationale-form paragraph wrapped in `surgical-changes` markers; 4–6 checklist bullets; two C# / TypeScript diff examples ≤ 25 lines per side).
- Examples illustrate drive-by refactoring and style drift specifically — not over-abstraction (that's Task 2's territory).

---

### Task 4: Write "How Each Agent Applies These" applicability table

**Status:** DONE

Depends on: Tasks 2, 3

Plan Step 1.4. Replace the applicability-section TODO with a table mapping
each consumer agent to its operational stance for each principle:

| Agent | Role | Simplicity | Surgical |
|-------|------|-----------|----------|
| `task-implementer` | Author at write time | Apply: ... | Apply: ... |
| `code-fixer` | Author at fix time | Apply: ... | Apply: ... |
| `quality-reviewer` | Reviewer | Detect: ... | Detect: ... |

Each cell contains a concrete one-line operational statement, not a
generic re-statement of the principle. The author-vs-reviewer distinction
(Apply vs Detect) must be explicit in the cell text.

**Files to modify:**
- `plugins/kenspc/shared/code-craft-principles.md`

**Acceptance criteria:**
- Table present with the exact header row and three data rows above.
- `task-implementer` and `code-fixer` cells begin with "Apply:"; `quality-reviewer` cells begin with "Detect:".
- Each cell is a one-line operational statement specific to the agent's role (e.g., `code-fixer` Simplicity cell mentions DEFERRED structural changes).

---

### Task 5: Write "What This File Does NOT Define" section

**Status:** DONE

Depends on: Task 1

Plan Step 1.5. Replace the section's TODO with four bulleted omissions,
each with a one-line rationale:

- Goal-Driven Execution (covered by DONE-criteria in every SKILL).
- Think Before Coding for ad-hoc interactions (out of scope — belongs in user-level or project-level CLAUDE.md).
- Per-language style guides (delegated to project CLAUDE.md and existing project conventions, which agents read in their PREREQUISITES step).
- Agent dispatch order and CONTEXT block contracts (defined in the dispatching SKILL.md and each agent's header).

**Files to modify:**
- `plugins/kenspc/shared/code-craft-principles.md`

**Acceptance criteria:**
- Section present after the applicability table.
- Four omissions listed with one-line rationale each (not just a bullet name).

---

### Task 6: Update `agents/task-implementer.md` — inline principles, remove scope-creep duplicates

**Status:** DONE

Depends on: Tasks 2, 3

Plan Step 2.1. Make these edits to `plugins/kenspc/agents/task-implementer.md`:

1. In `QUALITY RULES`, remove the bullet `- Do not modify code unrelated to the current task.` (currently at the bottom of QUALITY RULES).
2. In `AUTONOMY BOUNDARIES` → "Do not do even if it seems helpful", remove the bullet `- Refactor code unrelated to the current task.` Keep the BLOCKED-trigger items and the other "Do not do" bullets intact.
3. Insert a new section titled `CODE-CRAFT PRINCIPLES` immediately AFTER `QUALITY RULES` and BEFORE `AUTONOMY BOUNDARIES`. The section body has three parts in this exact order:
   - Both canonical principle blocks copied from `shared/code-craft-principles.md` byte-identical, including the surrounding `<!-- canonical:principle:simplicity-first:start --> ... :end -->` and `<!-- canonical:principle:surgical-changes:start --> ... :end -->` markers.
   - One applicability line: "This agent's applicability stance (see shared file's table): author at write time."
   - One reference line: "For worked C# / TypeScript diff examples and edge cases, see `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`."

Keep `STOP and mark task as BLOCKED` triggers, the `QUALITY CHECKLIST`,
and all other sections untouched.

**Files to modify:**
- `plugins/kenspc/agents/task-implementer.md`

**Acceptance criteria:**
- Exactly 2 bullets removed (one from `QUALITY RULES`, one from `AUTONOMY BOUNDARIES` → "Do not do even if it seems helpful").
- New `CODE-CRAFT PRINCIPLES` section sits between `QUALITY RULES` and `AUTONOMY BOUNDARIES`.
- Both canonical principle blocks (with start/end markers) present and contain text byte-identical to the matching blocks in `shared/code-craft-principles.md` (Task 15's script verifies this).
- Reference line uses `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` (no hardcoded paths, no `~/`).
- All other sections (`PREREQUISITE CHECK`, `OBJECTIVE`, `PREREQUISITES`, `DONE CRITERIA`, `PROCESSING APPROACH`, `AUTONOMY BOUNDARIES` BLOCKED-triggers, `QUALITY CHECKLIST`, `STUCK HANDLING`, `CODE ARTIFACTS LANGUAGE`, `OUTPUT FORMAT (Schema D)`) intact.

---

### Task 7: Update `agents/code-fixer.md` — inline principles, remove duplicate surgical bullets

**Status:** DONE

Depends on: Tasks 2, 3

Plan Step 2.2. Make these edits to `plugins/kenspc/agents/code-fixer.md`:

1. In `FIXING RULES`, remove `- Preserve the original code's style and structure.` and `- Do not introduce new features or refactor code beyond what the issue requires.`
2. Insert a new section titled `CODE-CRAFT PRINCIPLES` after `FIXING RULES` and before `FIXING PRIORITY`. The body has three parts:
   - Both canonical principle blocks copied byte-identical from `shared/code-craft-principles.md` (with surrounding marker pairs).
   - One applicability line: "This agent's applicability stance (see shared file's table): author at fix time. Structural improvements not in the review report are DEFERRED, not applied."
   - One reference line: "For worked C# / TypeScript diff examples and edge cases, see `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`."

The canonical blocks here must be the same bytes as those in
`task-implementer.md` and the shared file — Task 15's script hashes
all three locations and fails on any mismatch.

Keep all other `FIXING RULES` bullets ("Follow established project
conventions and patterns", "Each fix is a separate, focused git commit
with a clear message", "Code, code comments, and commit messages stay in
English") untouched. Keep `FIXING PRIORITY`, `PER-ISSUE OUTPUT CONTRACT`,
and `OUTPUT FORMAT (Schema B)` fully untouched.

**Files to modify:**
- `plugins/kenspc/agents/code-fixer.md`

**Acceptance criteria:**
- Exactly 2 bullets removed from `FIXING RULES` (the surgical ones).
- New `CODE-CRAFT PRINCIPLES` section sits between `FIXING RULES` and `FIXING PRIORITY`.
- Both canonical principle blocks present with markers; bytes identical to the matching blocks in the shared file and `task-implementer.md`.
- `FIXING PRIORITY` HIGH/MEDIUM/LOW decision matrix intact.
- `PER-ISSUE OUTPUT CONTRACT` (with the `short_label` ≤ 60 chars requirement) intact.
- Schema B output contract intact.

---

### Task 8: Update `agents/quality-reviewer.md` — add over-engineering and drive-by review bullets

**Status:** DONE

Depends on: Task 1

Plan Step 2.3. In `REVIEW CHECKLIST`, KEEP the existing "Code complexity"
bullet (it catches a different failure mode — readability). Insert two
new multi-line bullets immediately after it.

**Bullet 1: Over-engineering.** Flag features, abstractions, or
configurability that meet **all three** of the following conditions:

1. Not in the task document's stated requirements, AND
2. Not mandated by project conventions documented in `CLAUDE.md`, `README.md`, or visible patterns in adjacent code, AND
3. Not a boundary validation required by the project's security or input-handling rules.

The bullet includes a "Why:" line: "abstractions or validations that meet
condition (2) or (3) are correct design — flagging them creates noise
that erodes trust in this reviewer's signal." Cite
`${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` for the underlying
Simplicity principle and the applicability table's "detect, do not fix"
stance.

**Bullet 2: Drive-by refactoring and style drift in the diff.** Flag
changes to adjacent code that meet **all three** of the following
conditions:

1. Not required by the task, AND
2. Not mechanically forced by the change (interface signature changes cascade to implementers; removing the last call to a function orphans imports; lint-mandated formatting changes), AND
3. Not convergence to the canonical project style (a "drift" toward documented style is correct, not drive-by).

The bullet includes a "Why:" line: "cascading task-driven changes are the
change itself, not drive-by — flagging them would force the implementer
to leave the codebase in a broken state." Cite the same shared file for
the Surgical Changes principle.

Do NOT inline the canonical principle paragraphs in this file. The
reviewer's working tool is the detection bullets above, which reference
but do not duplicate the principle definitions. Task 15's byte-identity
script therefore does not include this file. The other 4 reviewer agents
(`requirements-reviewer`, `edge-case-reviewer`, `bug-reviewer`,
`test-reviewer`) are NOT modified — Task 12 verifies the existing 5-agent
drift guard still passes.

**Files to modify:**
- `plugins/kenspc/agents/quality-reviewer.md`

**Acceptance criteria:**
- Existing "Code complexity" bullet preserved unchanged.
- Two new multi-line bullets added immediately after it.
- Each new bullet enumerates all three exclusion conditions in numbered form.
- Each new bullet includes a "Why:" line and a `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` reference.
- No other reviewer agent file is modified.
- `bash scripts/check-review-agent-drift.sh` exits 0 (shared PREREQUISITES / FILE COVERAGE / CUSTOM INSTRUCTIONS sections across the 5 review-angle agents stay byte-identical).
- `quality-reviewer`'s `effort: xhigh` and Schema A output contract are unchanged.

---

### Task 9: Update repo-root `CLAUDE.md` — extend Plugin Directory Layout and shared/ paragraph

**Status:** DONE

Depends on: Task 1

Plan Step 3.1. Make these edits to `CLAUDE.md` (repo root):

1. In `### Plugin Directory Layout` ASCII tree, the current `shared/` block has one entry:
   `│   └── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan`
   Replace it with two lines preserving the existing tree-drawing characters:
   ```
   │   ├── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan
   │   └── code-craft-principles.md # Code-craft principles shared by task-implementer, code-fixer, quality-reviewer
   ```
2. In the `shared/` paragraph (around line 66) — currently `The current entry is discovery-framework.md, loaded by both generate-plan Phase 1 and generate-brief Phase 1 ...` — extend or add a second sentence describing `code-craft-principles.md`: which 3 agents reference it, what it defines (Simplicity + Surgical with stack-specific C# / TS examples), and what it explicitly does NOT define (Goal-Driven Execution; Think Before Coding for ad-hoc interactions; per-language style guides; dispatch order / CONTEXT contracts).

No other CLAUDE.md section is modified in this task. (Repository scripts/
and Validate plugin structure blocks are touched in Task 15.)

**Files to modify:**
- `CLAUDE.md` (repo root)

**Acceptance criteria:**
- ASCII tree under `shared/` has exactly two file entries, with the first using `├──` and the second using `└──` (correct tree-drawing characters).
- `shared/` paragraph names both files and mentions consumer skills (`generate-brief`, `generate-plan`) for the discovery framework and consumer agents (`task-implementer`, `code-fixer`, `quality-reviewer`) for the new file.
- No other section of `CLAUDE.md` is touched in this task's commit.

---

### Task 10: Update `plugins/kenspc/README.md` — clarify Stack-agnostic and add Acknowledgements paragraph

**Status:** DONE

Depends on: Task 1

Plan Step 3.2. Make these edits to `plugins/kenspc/README.md`:

1. Find the bullet `- **Stack-agnostic** — Skills inspect project config files rather than assuming specific frameworks.` (currently line 150). Reword to:
   `- **Stack-agnostic skill behavior** — Skills inspect project config files rather than assuming specific frameworks. (Documentation examples in shared/ may use specific languages — currently C# and TypeScript — to maximize teaching density; this does not constrain which projects the skills work with.)`
2. In `## Acknowledgements`, insert a new paragraph between the existing `agent-skills` paragraph (currently lines 205-207) and the `thinkfirst` paragraph (currently lines 210-215). The new paragraph credits Karpathy's October 2025 X post on LLM coding pitfalls, names the doggy8088 derivation chain (forked from forrestchang), notes that only 2 of 4 principles were adopted, and notes that example code is original and stack-specific to the maintainer's primary stacks. Links to use: `https://x.com/karpathy/status/2015883857489522876`, `https://github.com/doggy8088/andrej-karpathy-skills`, `https://github.com/forrestchang/andrej-karpathy-skills`, `https://github.com/doggy8088`.

The Acknowledgements section uses paragraph format throughout. The new
entry MUST be a paragraph, NOT a bulleted/numbered list item.

**Files to modify:**
- `plugins/kenspc/README.md`

**Acceptance criteria:**
- Stack-agnostic bullet reworded as "Stack-agnostic skill behavior" with the documentary-examples clarification clause.
- New Acknowledgements paragraph inserted between the `agent-skills` paragraph and the `thinkfirst` paragraph.
- New paragraph cites Karpathy, doggy8088, forrestchang with the URLs above.
- New paragraph notes "two of the four principles" and "example code is original and stack-specific".
- New paragraph is formatted as a paragraph (matches surrounding paragraph format), not a list item.

---

### Task 11: Add v3.1.0 CHANGELOG entry and bump `plugin.json` version (atomic commit)

**Status:** DONE

Depends on: Tasks 1–10

Plan Step 3.3. Make these atomic edits in a single commit:

1. Add a new top entry in `plugins/kenspc/CHANGELOG.md` above the existing `## 3.0.3` entry. Title: `## 3.1.0 — 2026-05-14`. Required subsections:
   - Opening summary (one short paragraph: "Adds Simplicity First and Surgical Changes ... No breaking changes; no CONTEXT block schema changes; no SKILL or agent interface changes for callers.")
   - `### Rationale` (3–4 paragraphs: the gap (no Simplicity guard; Surgical scattered in 3 places); why Karpathy's 4 principles narrowed to 2 (Goal-Driven already covered; Think Before Coding belongs outside the plugin); how this aligns with v3 design rules (Why-not-Command; principle-driven; SSoT))
   - `### Added` (new shared file with canonical-marker scheme; two new `quality-reviewer` checklist bullets with three-condition gates; new `scripts/check-code-craft-canonical.sh`)
   - `### Changed` (`task-implementer` 2 bullets relocated + new CODE-CRAFT PRINCIPLES section; `code-fixer` 2 bullets relocated + new CODE-CRAFT PRINCIPLES section; README Stack-agnostic rewording + new Acknowledgements paragraph; root CLAUDE.md tree + Repository scripts/ + Validate plugin structure extended)
   - `### Acknowledgements` (Karpathy's October 2025 X post; pointer to README for full lineage chain)
   - `### Out of scope (deferred / not adopted)` (Karpathy Principle 1 "Think Before Coding" — belongs in user/project CLAUDE.md; Karpathy Principle 4 "Goal-Driven Execution" — already covered by DONE-criteria)

2. Bump `plugins/kenspc/.claude-plugin/plugin.json` `"version"` from `"3.0.3"` to `"3.1.0"`.

Constraints:
- Do NOT modify the `plugin.json` description string (the v3.1.0 change does not affect the marketplace summary or full plugin description).
- Do NOT touch any agent .md `version:` field (audit confirms no agent file currently carries one).
- Do NOT touch any SKILL.md `version:` field (per current convention, SKILL.md files stayed at 3.0.0 through the v3.0.1 / 3.0.2 / 3.0.3 patch releases).
- The CHANGELOG entry and the `plugin.json` bump must land in the same commit (atomic v3.1.0 commit pair).

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`
- `plugins/kenspc/.claude-plugin/plugin.json`

**Acceptance criteria:**
- CHANGELOG entry present with all six subsections above.
- `plugin.json` shows `"version": "3.1.0"`.
- `grep -rn "^version:" plugins/kenspc/agents/` returns empty.
- `grep -rn "^version:" plugins/kenspc/skills/` shows all SKILL.md files unchanged from v3.0.3 state.
- Both file changes land in a single conventional-commit.

---

### Task 12: Cross-file consistency check (relocation grep + applicability table audit)

**Status:** TODO

Depends on: Tasks 6, 7, 8

Plan Step 4.1. Run these verifications:

1. Grep for relocated phrases. Each must return 0 matches under `plugins/kenspc/agents/` and ≥ 1 match under `plugins/kenspc/shared/code-craft-principles.md`:
   - "Do not modify code unrelated to the current task"
   - "Refactor code unrelated"
   - "Do not introduce new features or refactor"
   - "Preserve the original code's style"
2. Grep for `code-craft-principles.md` under `plugins/kenspc/agents/`. Must match exactly three agent files: `task-implementer.md`, `code-fixer.md`, `quality-reviewer.md`.
3. Open the applicability table from Task 4 in the shared file. Walk each row and confirm the cell text matches the actual operational stance described in the corresponding agent body.
4. Run `bash scripts/check-review-agent-drift.sh` and confirm it exits 0 (the 5 review-angle agents' shared sections still byte-identical after Task 8's edits to `quality-reviewer`).

This task does not need to produce a commit if all checks pass. If a
defect is found, fix and commit under this task.

**Files to modify:** None (verification-only) unless a defect surfaces.

**Acceptance criteria:**
- Four phrase greps all return 0 in agents and ≥ 1 in the shared file.
- `code-craft-principles.md` reference grep returns exactly the three expected agents.
- All three applicability-table rows match agent bodies.
- `check-review-agent-drift.sh` exits 0.
- If any check fails, the defect is recorded under this task and a fix commit is attached.

---

### Task 13: Portable-path and anchor-slug check

**Status:** TODO

Depends on: Tasks 6, 7, 8

Plan Step 4.2. Run these verifications:

1. Grep every modified agent file for `code-craft-principles.md` references. Every match must use the prefix `${CLAUDE_PLUGIN_ROOT}/shared/`. No hardcoded `~/`, absolute Windows paths, or absolute POSIX paths.
2. Confirm the shared file's two principle headings read exactly `## Simplicity First` and `## Surgical Changes`. Under GitHub's auto-slug rules (heading lowercased, spaces → hyphens, most punctuation stripped), these produce `#simplicity-first` and `#surgical-changes`. Any deviation breaks the anchor links referenced from agent files.

This task does not need to produce a commit if all checks pass.

**Files to modify:** None (verification-only) unless a defect surfaces.

**Acceptance criteria:**
- All references to the shared file in agent .md files use the `${CLAUDE_PLUGIN_ROOT}` prefix.
- No hardcoded absolute paths found.
- The two principle headings in the shared file read exactly `## Simplicity First` and `## Surgical Changes`.

---

### Task 14: Subtraction audit (per-file line-count check against expected bounds)

**Status:** TODO

Depends on: Tasks 1–11

Plan Step 4.3. Count net lines added in each modified file (excluding the
new `shared/code-craft-principles.md`, which is intentionally a net
addition). Compare against the per-file upper bounds from the plan:

| File | Expected upper bound (net additions) |
|------|-------------------------------------|
| `plugins/kenspc/agents/task-implementer.md` | +18 |
| `plugins/kenspc/agents/code-fixer.md` | +18 |
| `plugins/kenspc/agents/quality-reviewer.md` | +32 |
| `plugins/kenspc/README.md` | +14 |
| `CLAUDE.md` (root) | +10 |
| `plugins/kenspc/CHANGELOG.md` | +50 |
| `plugins/kenspc/.claude-plugin/plugin.json` | 0 |

If any file exceeds its upper bound, review against the plan's diagnostic
list:
- (a) examples accidentally inlined alongside the principle paragraph;
- (b) scope-creep bullets not actually removed from their original location and remaining duplicated;
- (c) applicability or reference text exceeding one short line each.

This task does not need to produce a commit if all checks pass.

**Files to modify:** None (verification-only) unless a defect surfaces.

**Acceptance criteria:**
- Each file's net delta is at or below its expected upper bound.
- If a bound is exceeded, the diagnostic finding (a / b / c) is recorded under this task and a fix commit is attached.

---

### Task 15: Create `check-code-craft-canonical.sh` and wire it into CLAUDE.md + release-checklist

**Status:** TODO

Depends on: Tasks 2, 3, 6, 7

Plan Step 4.4. Make these edits in a single commit:

1. Create `scripts/check-code-craft-canonical.sh` modeled on `scripts/check-canonical-dispatch.sh`. The new script:
   - For each of the two principle keys (`simplicity-first`, `surgical-changes`):
     - Extracts content between `<!-- canonical:principle:<key>:start -->` and `<!-- canonical:principle:<key>:end -->` from three files: `plugins/kenspc/shared/code-craft-principles.md` (authoritative), `plugins/kenspc/agents/task-implementer.md`, `plugins/kenspc/agents/code-fixer.md`.
     - sha256-hashes each extracted block.
     - Fails with a clear error message identifying the outlier file if any of the three hashes for that key differ.
   - Returns 0 if both keys' three-way hashes are identical across all three files.
   - Returns 2 if any input file is missing or the markers are not found (matching the convention of `check-canonical-dispatch.sh`).
   - Uses the same `set -euo pipefail` discipline and the same extraction technique (sed -n between markers) as `check-canonical-dispatch.sh`.
2. Update repo-root `CLAUDE.md` `### Repository scripts/` section: add a bullet for `check-code-craft-canonical.sh` alongside the existing entries, with the same "guards the byte-identity invariant" framing.
3. Update repo-root `CLAUDE.md` `### Validate plugin structure` block (under `## Development Workflow`): add `bash scripts/check-code-craft-canonical.sh` to the "Cross-agent invariants" list.
4. Update `docs/release-checklist.md` "Pre-flight: mechanical checks" code block to include `bash scripts/check-code-craft-canonical.sh` in the run-from-root list, AND update the prose line "All five must exit 0 (3 JSON validations + 2 shell drift guards)" to "All six must exit 0 (3 JSON validations + 3 shell drift guards)".
5. Run `bash scripts/check-code-craft-canonical.sh` and confirm exit 0 against the freshly committed agent and shared-file edits.
6. Deliberate test mutation: change one character in one canonical block in `agents/task-implementer.md`. Run the script. Confirm it exits non-zero with a clear "files differ" message and identifies the outlier. Revert the mutation before committing.

The script must be executable on both Windows (Git Bash) and WSL2 Ubuntu.

**Files to create:**
- `scripts/check-code-craft-canonical.sh`

**Files to modify:**
- `CLAUDE.md` (repo root)
- `docs/release-checklist.md`

**Acceptance criteria:**
- Script exists at `scripts/check-code-craft-canonical.sh`.
- Script returns 0 on the current working tree.
- Deliberate one-character mutation in one canonical block in one file causes the script to exit non-zero with a clear message identifying the outlier; mutation reverted before commit.
- Root `CLAUDE.md` `### Repository scripts/` section lists the new script with the "guards the byte-identity invariant" framing.
- Root `CLAUDE.md` `### Validate plugin structure` block includes `bash scripts/check-code-craft-canonical.sh` in the Cross-agent invariants list.
- `docs/release-checklist.md` "Pre-flight: mechanical checks" block invokes the new script.
- `docs/release-checklist.md` "must exit 0" count is updated from "five" / "2 shell drift guards" to "six" / "3 shell drift guards".

---

### Task 16: Pre-ship dry-run for `quality-reviewer` new bullets against a known-good past PR

**Status:** TODO

Depends on: Task 8

Plan Step 4.5. Select one recently-merged PR or commit from this repository
that:

- contains at least one of: mechanically-forced cascade (e.g., an interface signature change with implementer updates), boundary validation, or project-convention-mandated abstraction (e.g., a new agent file following the established 11-agent structure);
- was reviewed and merged without raising over-engineering or drive-by-refactoring concerns (known-good baseline).

Plan-suggested candidates: v2.0-era plan/task refactors, v3.0-era agent
split, recent CLAUDE.md restructuring that involved cascading edits.

Perform a dry-run paper review of the selected diff against ONLY the two
new `quality-reviewer` checklist bullets written in Task 8
(over-engineering, drive-by/style-drift). Do not run the full
task-review skill — this is purely a sanity check on the two new bullets'
three-condition gates. For each suspicious diff hunk, walk through the
three exclusion conditions for that bullet and record whether the bullet
would FLAG or PASS.

Tabulate the result in a short dry-run report:

- The PR or commit selected (hash + title).
- Each diff hunk walked, with the three-condition gate evaluation per bullet.
- The FLAG/PASS decision per hunk.
- A one-line ship/no-ship conclusion.

Decision rules:
- If both bullets correctly PASS all known-good hunks → "ship as-is".
- If either bullet would FLAG one or more known-good hunks → "tighten Task 8 wording before ship", with a concrete tightening proposal naming which exclusion condition failed.

The dry-run report's destination is author's choice: either a new short
markdown file under `docs/` (committed) or attached to the release-checklist
run as comments/notes.

**Files to create:** None directly required (the dry-run report may be
committed as a doc file or attached externally).

**Acceptance criteria:**
- Dry-run report exists (committed under `docs/` or otherwise persisted alongside the release process).
- At least 3 hunks walked through both new bullets.
- Each walked hunk has a FLAG/PASS decision with the three-condition gate evaluation.
- Report ends with either "ship as-is" or "tighten Task 8 wording before ship" plus a concrete tightening proposal.
- If "tighten", the proposal is applied back to Task 8 and Task 16 is re-run.

---

## Notes

- All edits target plugin files (markdown, shell scripts, JSON). No application code is written under this task document.
- "Build / test / lint" verification per task = the pre-flight mechanical-check suite from `docs/release-checklist.md` (JSON sanity + drift guards). After Task 15 lands, the suite expands by one script.
- Commit rhythm:
  - Tasks 1–10 produce one commit each, scoped to a single file (except Task 7 which adds the largest new section to `code-fixer.md`).
  - Task 11 is one atomic commit pairing `CHANGELOG.md` and `plugin.json`.
  - Tasks 12, 13, 14 produce a commit only if a defect surfaces (verification-only otherwise).
  - Task 15 produces a commit (new script + two file edits).
  - Task 16's deliverable is a dry-run report — committing it is optional per the task's "author's choice" clause.
- Byte-identity dependency chain: Tasks 6, 7 inline canonical blocks from Tasks 2, 3 → Task 15's script verifies the three-way byte-identity → Task 12 cross-checks the relocation (no residual phrases in agents). The plan phases Task 11 (v3.1.0 commit pair, Phase 3) before Tasks 12–15 (Phase 4 validation), so the CHANGELOG entry documents the full release scope (including the new check script Task 15 will add) and the three guards (Tasks 12, 13, 15) must all pass before the release is tagged — even though they execute after the version-bump commit lands.
