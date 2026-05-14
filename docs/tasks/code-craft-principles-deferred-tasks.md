# v3.1.x Code-Craft Principles — Deferred Follow-ups — Task Document

## Context

Decomposition of `docs/plans/code-craft-principles-deferred-plan.md` into 8
fine-grained tasks. Closes the six DEFERRED items from the v3.1.0 5-angle
review (`docs/briefs/code-craft-principles-deferred.md`) plus two release-
support tasks (release-checklist sync, version + CHANGELOG bump). All
v3.1.0 invariants — 3-file byte-identity hash on the canonical principle
blocks, Task 12's 4-phrase relocation grep contract, the 5-reviewer-agent
drift guard, and the `task-review` ↔ `task-implement` canonical dispatch
byte-identity — must remain intact across every task.

Related plan: `docs/plans/code-craft-principles-deferred-plan.md`

This plan has no Phase sections; tasks reference each other directly via
`Depends on: Task N` (no cross-phase annotations needed).

## Tasks

### Task 1: Rewrite #15 grammar bullet in shared/code-craft-principles.md

**Status:** DONE

Replace the existing line 105 of
`plugins/kenspc/shared/code-craft-principles.md` (the awkward verb-phrase-as-
noun-phrase bullet starting with `Refactor code unrelated to the current
task is out;`) with the plan's chosen rewrite:

> `- Don't refactor code unrelated to the current task — that is out of scope; do not refactor things that are not broken even when you would have written them differently from scratch.`

The edit must touch line 105 only. Do not modify any content between the
`<!-- canonical:principle:simplicity-first:* -->` markers (lines 7/9) or
the `<!-- canonical:principle:surgical-changes:* -->` markers (lines 97/99).
Do not modify the Task 12 guard HTML comment at line 103.

**Files:**
- `plugins/kenspc/shared/code-craft-principles.md` (line 105 only)

**Acceptance criteria:**
- `grep -F "refactor code unrelated to the current task" plugins/kenspc/shared/code-craft-principles.md` returns ≥ 1 match (Task 12 grep contract holds).
- `grep -rF "refactor code unrelated to the current task" plugins/kenspc/agents/` returns 0 matches (Task 12 relocation contract holds — substring stays absent in agent bodies).
- `bash scripts/check-code-craft-canonical.sh` exits 0 (edit was outside the byte-identity range).
- `bash scripts/check-canonical-dispatch.sh` exits 0 (unrelated invariant unaffected).
- `bash scripts/check-review-agent-drift.sh` exits 0 (unrelated invariant unaffected).

**Commit:** `fix(shared): rewrite refactor-code-unrelated bullet for grammar while preserving Task 12 relocation grep substring`

---

### Task 2: Document #16 hyphen-exception in CLAUDE.md + inline guards in both writer agents

**Status:** DONE

Decision (per plan Decision A2): **keep the hyphen** in `CODE-CRAFT
PRINCIPLES` as a deliberate compound-adjective exception to the ALL-CAPS-
no-hyphens writer-agent header convention. Two co-located anchors prevent
silent normalization:

1. In repo-root `CLAUDE.md`, append a new subsection inside the existing
   "Skill Development Conventions" block titled "Writer-agent section
   header convention" with the body specified in the plan's Step 2
   (states the convention, names `CODE-CRAFT PRINCIPLES` as the canonical
   compound-adjective exception, and explains the co-located guard
   comment).
2. In each writer-agent file, insert a one-line HTML guard comment
   immediately above the `CODE-CRAFT PRINCIPLES` header
   (`task-implementer.md:82`, `code-fixer.md:69`) with verbatim wording:
   > `<!-- guard: the hyphen in "CODE-CRAFT PRINCIPLES" is intentional — it marks a compound-adjective exception to the ALL-CAPS-no-hyphens writer-agent header convention documented in repo-root CLAUDE.md. Do not normalize without updating the CLAUDE.md convention paragraph in the same commit. -->`

The guard comment must sit on the line **immediately above** the
`CODE-CRAFT PRINCIPLES` header. The canonical-principle start markers
(`<!-- canonical:principle:simplicity-first:start -->`) appear two lines
below the section header in both agent files; the guard must not land
inside the marker range.

No edits to the existing v3.1.0 task document
(`docs/tasks/code-craft-principles-tasks.md`) — Tasks 6/7 acceptance
criteria there already spell `CODE-CRAFT PRINCIPLES` with the hyphen, so
the "propagate the winning header" clause in brief item #16 is satisfied
by zero header edits.

**Files:**
- `CLAUDE.md` (append subsection in "Skill Development Conventions")
- `plugins/kenspc/agents/task-implementer.md` (one-line guard above line 82)
- `plugins/kenspc/agents/code-fixer.md` (one-line guard above line 69)

**Acceptance criteria:**
- `grep -F "CODE-CRAFT PRINCIPLES" plugins/kenspc/agents/task-implementer.md plugins/kenspc/agents/code-fixer.md` returns 2 matches (one per file, header unchanged).
- `grep -F "compound-adjective exception" plugins/kenspc/agents/task-implementer.md plugins/kenspc/agents/code-fixer.md` returns 2 matches (guard comments inserted).
- `grep -F "compound-adjective exception" CLAUDE.md` returns ≥ 1 match.
- `bash scripts/check-code-craft-canonical.sh` exits 0 (canonical block hashes unchanged — guard comments sit outside the marker range).
- `bash scripts/check-canonical-dispatch.sh` exits 0 (unrelated invariant).
- `bash scripts/check-review-agent-drift.sh` exits 0 (scope is the 5 reviewer agents, not writer agents — unaffected by these edits).

**Commit:** `docs(convention): record CODE-CRAFT-PRINCIPLES hyphen exception in CLAUDE.md and inline guards`

---

### Task 3: Add #17 dry-run report terminology subsection to task-review/SKILL.md

**Status:** DONE

Insert a new subsection `## Output convention — dry-run reports` in
`plugins/kenspc/skills/task-review/SKILL.md` after the existing
"Quality bar" section and before "Prerequisites". The subsection defines
the standing convention for future dry-run reports:

- Per-condition labels: `CONDITION-MET` / `CONDITION-NOT-MET`
- Per-hunk final labels: `FLAG` / `PASS`

The two vocabularies do not overlap, so polarity cannot be misread. Copy
the verbatim wording (including the table and the reason paragraph citing
the historical artifact at
`docs/dry-runs/v3.1.0-quality-reviewer-bullets-dry-run.md`) from the
plan's Step 3 action block.

The new subsection must sit upstream of the
`<!-- canonical:dispatch:start -->` / `<!-- canonical:dispatch:end -->`
block. Placement at "after Quality bar, before Prerequisites" achieves
this — the dispatch block lives further down in the file. The existing
v3.1.0 dry-run report is **not** rewritten; it is preserved as a
historical artifact.

**Files:**
- `plugins/kenspc/skills/task-review/SKILL.md` (new subsection between "Quality bar" and "Prerequisites")

**Acceptance criteria:**
- `grep -F "CONDITION-MET" plugins/kenspc/skills/task-review/SKILL.md` returns ≥ 1 match.
- `grep -F "CONDITION-NOT-MET" plugins/kenspc/skills/task-review/SKILL.md` returns ≥ 1 match.
- `grep -nE "^\| Per-hunk final" plugins/kenspc/skills/task-review/SKILL.md` returns 1 match (the convention table row).
- `bash scripts/check-canonical-dispatch.sh` exits 0 (new subsection placed outside the canonical:dispatch block — byte-identity with task-implement/SKILL.md unaffected).
- `bash scripts/check-review-agent-drift.sh` exits 0.
- `bash scripts/check-code-craft-canonical.sh` exits 0.

**Commit:** `docs(task-review): define dry-run report terminology (CONDITION-MET/NOT-MET, FLAG/PASS)`

---

### Task 4: Extend check-code-craft-canonical.sh with #31 anchor-phrase frequency guard

**Status:** DONE

After the existing byte-identity check, append a second check block to
`scripts/check-code-craft-canonical.sh` that asserts the anchor phrases
`Simplicity First` and `Surgical Changes` each appear ≥ 1 time in each of
the three target files (`SHARED_FILE`, `IMPLEMENTER_FILE`, `FIXER_FILE`),
counted anywhere in the file. Model the block on
`scripts/check-canonical-dispatch.sh:96-117`:

- Define an `ANCHORS=("Simplicity First|1" "Surgical Changes|1")` array.
- Iterate the three files, using `grep -F -i -o` piped to `wc -l` with the
  `|| true` pipefail-safe pattern from `check-canonical-dispatch.sh:55`.
- On failure for any anchor, name the file and the missing anchor; set
  `drift_found=1` (sharing the existing exit-code variable).
- On full success, print `OK    code-craft anchor phrases — all minimum
  counts met in all three files`.
- Final exit code semantics unchanged: 0 if both checks pass, 1 if either
  fails.

Note the semantic refinement of brief item #31 in the commit body: the
brief said "outside the byte-identity hash range", but the agent files
contain the labels only inside the canonical block, so the check is
applied "anywhere in file". The failure mode the brief named
(synchronized edit replacing all canonical blocks with different content
that drops the anchor) is still caught.

**Files:**
- `scripts/check-code-craft-canonical.sh` (extend after existing byte-identity check)

**Acceptance criteria:**
- `bash scripts/check-code-craft-canonical.sh` on the current tree exits 0; output includes both `OK    canonical:principle:... byte-identity` lines AND a new `OK    code-craft anchor phrases ...` line.
- Deliberate-mutation counter-example (run during review, not in tree): temporarily replace `**Simplicity First.**` with `**Minimalism.**` inside the canonical-principle block of all three files (keeps byte-identity passing) — running the script then exits 1, naming the three files and the missing `Simplicity First` anchor. Revert the mutation.
- `bash scripts/check-canonical-dispatch.sh` and `bash scripts/check-review-agent-drift.sh` still exit 0.

**Commit:** `feat(scripts): add anchor-phrase frequency guard to check-code-craft-canonical (refines brief #31 "outside markers" to "anywhere in file")`

---

### Task 5: Create scripts/check-quality-reviewer-bullet-structure.sh for #33

**Status:** DONE

Create a new shell script at
`scripts/check-quality-reviewer-bullet-structure.sh` that asserts the two
new REVIEW CHECKLIST bullets in
`plugins/kenspc/agents/quality-reviewer.md`
(`Over-engineering and abstractions`, `Drive-by refactoring and style
drift`) each enumerate exactly three numbered conditions gated by an
`**all three**` qualifier. The script:

- Uses `set -euo pipefail` and the same `$SCRIPT_DIR` / `$REPO_ROOT`
  derivation pattern as `check-code-craft-canonical.sh`.
- Defines a `BULLETS` array with entries shaped as
  `"anchor regex|expected condition count|qualifier regex"`.
- For each bullet: locates the first line via `grep -nE`, slices the
  body from that line to the next blank-line boundary, counts
  `^[[:space:]]*[0-9]+\.` matches inside the slice (must equal 3),
  verifies the qualifier regex matches ≥ 1 time.
- Exit semantics: 0 if both bullets pass; 1 with named failures on
  count/qualifier mismatch; 2 if the bullet anchor is not found
  (structural error).
- Header docstring documents exit codes and motivation, matching the
  format of `check-code-craft-canonical.sh`.
- File is chmod +x.

The script must be a separate file (not folded into
`check-code-craft-canonical.sh`) per the plan's Decision B2 (one-guard-
one-purpose pattern).

**Files:**
- `scripts/check-quality-reviewer-bullet-structure.sh` (new file, +x)

**Acceptance criteria:**
- `bash scripts/check-quality-reviewer-bullet-structure.sh` on the current tree exits 0.
- Script is executable on disk (`ls -l` shows `x` for owner).
- Deliberate counter-example (run during review): delete one of the three numbered conditions under the over-engineering bullet — script exits 1, output names the bullet and `expected 3, found 2`. Revert.
- Script header docstring documents exit-code semantics at top; `set -euo pipefail` discipline preserved.

**Commit:** `feat(scripts): add three-condition structural guard for quality-reviewer.md REVIEW CHECKLIST bullets`

---

### Task 6: Add --self-test mutation regression mode to three drift-guard scripts

**Status:** DONE

Add a `--self-test` flag to each of three guard scripts:

- `scripts/check-code-craft-canonical.sh`
- `scripts/check-canonical-dispatch.sh`
- `scripts/check-quality-reviewer-bullet-structure.sh`

Each `run_self_test` function follows the uniform shape from the plan's
Step 6 action block:

1. `mktemp -d` a `$WORK` directory, `trap 'rm -rf "$WORK"' EXIT`.
2. Copy every input file the script reads into `$WORK`, preserving the
   relative path under a synthetic repo root.
3. Override `REPO_ROOT="$WORK"` and rerun the script's main logic; assert
   exit code 0 (positive path).
4. Apply a content-based `sed` mutation to one canonical region in
   `$WORK`. Per-script mutation targets:
   - `check-code-craft-canonical.sh`: `**Simplicity First.**` → `**Simplicity 1st.**` in `$WORK/plugins/kenspc/shared/code-craft-principles.md` (mutation drops both byte-identity and the new anchor-phrase frequency check from Task 4).
   - `check-canonical-dispatch.sh`: `unconditional` → `notrequired` once inside the canonical-dispatch block of `$WORK/plugins/kenspc/skills/task-review/SKILL.md`. A wholly different word (not a case variation) is required so the case-insensitive grep also drops to 0; substituting `Unconditional` would not trigger the anchor failure path.
   - `check-quality-reviewer-bullet-structure.sh`: add a fourth numbered condition (e.g., a `4. Extra` line) under one of the two bullets, turning the three-condition gate into four.
5. Rerun script main logic; assert exit code 1 (negative path).
6. Revert the mutation; rerun; assert exit code 0 (restoration path).
7. On success: `echo "OK    self-test passed for $(basename "$0")"`,
   exit 0. On unexpected exit code: `FAIL  self-test ...`, exit 1.

Fixture-stale handling: if the `sed` substitution count is 0 (target
phrase missing from the canonical content), the self-test exits 2 with
the message `FAIL  self-test fixture stale: mutation target "<phrase>"
not found in <file>. Update the mutation target in run_self_test().`.

The `--self-test` flag is opt-in: when the script is invoked with no
arguments, behavior is unchanged. Cross-platform: scripts must run
identically on Git Bash (Windows) and WSL2 Ubuntu — use
`mktemp -d` plus relative-path traversal from `$WORK`, no
`/tmp`-style absolute paths.

`scripts/check-review-agent-drift.sh` is **not** in scope for this task
(deferred to a future "drift-guard self-test parity" cleanup; see plan
Open Questions #1).

**Files:**
- `scripts/check-code-craft-canonical.sh`
- `scripts/check-canonical-dispatch.sh`
- `scripts/check-quality-reviewer-bullet-structure.sh`

**Acceptance criteria:**
- `bash scripts/check-code-craft-canonical.sh --self-test` exits 0.
- `bash scripts/check-canonical-dispatch.sh --self-test` exits 0.
- `bash scripts/check-quality-reviewer-bullet-structure.sh --self-test` exits 0.
- Each `--self-test` produces a single line of output naming the script and `passed`.
- Each script's no-flag main mode still exits 0 on the current tree (opt-in flag does not alter default behavior).
- Manual cross-platform check: at least one `--self-test` invocation runs cleanly on both Git Bash (Windows) and WSL2 Ubuntu.

**Depends on:** Task 4, Task 5

**Commit:** `feat(scripts): add --self-test mutation regression mode to three canonical drift guards`

---

### Task 7: Sync docs/release-checklist.md mechanical-check block

**Status:** DONE

Extend the pre-flight mechanical-check `bash` block in
`docs/release-checklist.md` (currently lines 10–34) to add four new
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

**Files:**
- `docs/release-checklist.md` (mechanical-check block)

**Acceptance criteria:**
- Running the full mechanical-check `bash` block end-to-end on the post-Task-6 tree exits 0.
- The trailing sentence reads `All ten must exit 0 (3 JSON validations + 3 main-mode shell drift guards + 1 structural guard + 3 mutation regression self-tests).`
- The "ten" count matches the actual command count in the block (verify by `grep -cE "^bash scripts/|^cat .*python -m json.tool"` inside the fenced block).

**Depends on:** Task 4, Task 5, Task 6

**Commit:** `docs(release): list new drift guards and self-tests in pre-flight mechanical-check block`

---

### Task 8: Bump plugin.json to 3.1.1 and add CHANGELOG v3.1.1 entry

**Status:** TODO

Two file edits:

1. In `plugins/kenspc/.claude-plugin/plugin.json`, change the `version`
   field from `"3.1.0"` to `"3.1.1"`. Do not change any other field.
2. In `plugins/kenspc/CHANGELOG.md`, prepend a new `## [3.1.1] —
   2026-MM-DD` section (substitute the actual release date) above the
   existing v3.1.0 entry. The section contains `### Changed`,
   `### Added`, and `### Fixed` subsections, with at least one bullet
   per closed brief item (#15, #16, #17, #31, #32, #33). Each bullet
   cites the brief item number and the commit short-hash from Tasks 1-7.

Rationale (per plan Step 8): patch (3.1.1) is consistent with v3.1.x
deferred follow-ups — no new SKILL or agent interface, no CONTEXT key
changes, no user-facing capability addition. New script behavior is
defense-in-depth tooling.

**Files:**
- `plugins/kenspc/.claude-plugin/plugin.json`
- `plugins/kenspc/CHANGELOG.md`

**Acceptance criteria:**
- `grep -F '"version": "3.1.1"' plugins/kenspc/.claude-plugin/plugin.json` returns 1 match.
- `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null` exits 0 (JSON still valid).
- `CHANGELOG.md` has a `[3.1.1]` entry with `### Changed`, `### Added`, and `### Fixed` subsections.
- The CHANGELOG entry contains at least one bullet citing each of brief items #15, #16, #17, #31, #32, #33.
- Every commit short-hash cited in the CHANGELOG entry resolves via `git log --oneline`.

**Depends on:** Task 1, Task 2, Task 3, Task 4, Task 5, Task 6, Task 7

**Commit:** `chore(release): bump version to 3.1.1 for code-craft principles deferred follow-ups`

---

## Notes

- All eight tasks together close brief items #15, #16, #17, #31, #32, #33 plus the two natural support tasks (release-checklist sync, version + CHANGELOG bump) that the brief did not enumerate.
- Out-of-scope per plan (do not re-open): rewriting the v3.1.0 dry-run report, renegotiating Task 12's four-phrase grep contract, CHANGELOG line-count cap (`+50`), `.gitattributes` LF enforcement, pre-existing dead anchors in CHANGELOG, adding `--self-test` to `check-review-agent-drift.sh`.
- Cross-platform: every script change (Tasks 4, 5, 6) must run on Git Bash (Windows) and WSL2 Ubuntu. Avoid `/tmp`-style absolute paths and POSIX-only utilities not present in Git Bash.
- The pre-flight mechanical-check suite from `docs/release-checklist.md` grows from 6 checks to 10 checks after Task 7 lands. The smoke checklist (rows 1–9) is unchanged.
