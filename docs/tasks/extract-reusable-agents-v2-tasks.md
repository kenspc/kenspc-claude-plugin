# Extract Reusable Agents v2 — Task Document

> Tasks marked with "Depends on" assume prior tasks have been completed.
> Execute tasks in order.

## Context

Refactor the kenspc Claude Code plugin to adopt the official `agents/` directory
convention. Move 11 subagent prompt templates from `skills/*/prompts/` into
`plugins/kenspc/agents/` as proper agent definition files (Markdown + YAML
frontmatter), making them discoverable via `/agents`, invocable standalone (where
safe), and reusable across skills.

Plugin version: `1.5.0` → `2.0.0`. SKILL.md versions all bumped to `2.0.0`.

Related plan: `docs/plans/extract-reusable-agents-v2.md`

Decisions made during decomposition (recorded in Plan-Level Concerns at bottom):
- **Q1**: Phase 1 Step 1.1 (separate empty-directory commit) merged into Task 1
  because Git cannot commit empty directories.
- **Q2**: Testing Strategy reduced to fixture-free Tests B (standalone safety) and
  C (non-trigger / auto-delegation), exposed as Tasks 22-23. Tests A and D
  (require fixture project) deferred to manual post-implementation verification.
- **Q3**: Cross-phase `Depends on` annotations included explicitly.

## Tasks

### Task 1: Create requirements-reviewer agent + agents/ directory

**Status:** DONE

Create the new agent file `plugins/kenspc/agents/requirements-reviewer.md` (this
task also creates the `plugins/kenspc/agents/` directory as a side effect). Source
content is `plugins/kenspc/skills/task-review/prompts/review-angle-1.md`.

Structure:
1. YAML frontmatter:
   - `name: requirements-reviewer`
   - `description:` exactly the standalone-safe description text from plan section
     "Specific descriptions per agent" for `requirements-reviewer`
   - `tools: Read, Grep, Glob, Bash`
   - `model: inherit`
   - Do NOT include `hooks`, `mcpServers`, or `permissionMode` (rejected by plugin
     agent validation).
2. Body (markdown):
   - Move the ROLE, OBJECTIVE, REVIEW CHECKLIST, FILE COVERAGE, OUTPUT FORMAT
     and one-line summary sections verbatim from the source prompt.
   - Add a "CONTEXT YOU WILL RECEIVE" section listing exactly 3 keys:
     `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`.
   - Rewrite PREREQUISITES, SCOPE DETECTION, and CUSTOM INSTRUCTIONS to read
     values from the CONTEXT block instead of `{{...}}` placeholders.
   - Add the standalone fallback message at the start of the body (per plan
     "Standalone-safe agents' Layer 3 message"): if no CONTEXT block is provided,
     output the usage example (TASK_FILE / REVIEW_SCOPE / CUSTOM_INSTRUCTIONS
     example block) and stop without performing any work.
   - Preserve all bilingual conventions present in the source.

**Acceptance criteria:**
- File `plugins/kenspc/agents/requirements-reviewer.md` exists.
- Directory `plugins/kenspc/agents/` exists in the working tree.
- YAML frontmatter parses (e.g., `python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]).read().split('---')[1])" plugins/kenspc/agents/requirements-reviewer.md` succeeds).
- Frontmatter contains keys `name`, `description`, `tools`, `model`; does NOT
  contain `hooks`, `mcpServers`, or `permissionMode`.
- `tools` value is exactly `Read, Grep, Glob, Bash`.
- Body contains a "CONTEXT YOU WILL RECEIVE" section listing exactly the three
  keys `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`.
- `grep -F "{{" plugins/kenspc/agents/requirements-reviewer.md` returns no
  matches (no remaining template placeholders).
- Body contains the standalone fallback usage block (see plan "Standalone-safe
  agents' Layer 3 message" exact text).
- Commit message follows pattern `feat(agents): add requirements-reviewer agent`.

---

### Task 2: Create edge-case-reviewer agent

**Status:** DONE

Create `plugins/kenspc/agents/edge-case-reviewer.md` from
`plugins/kenspc/skills/task-review/prompts/review-angle-2.md`. Same structure as
Task 1 with Angle 2 content (Edge Cases and Error Handling) and the
`edge-case-reviewer` description from the plan.

Note: Source angle-2 has 4 PREREQUISITES items including separate task-scope and
changes-scope handling (different from angle-1 which has only 2). Preserve this
structure naturally when rewriting to read from CONTEXT.

**Acceptance criteria:**
- File `plugins/kenspc/agents/edge-case-reviewer.md` exists with YAML frontmatter
  (`name: edge-case-reviewer`, `tools: Read, Grep, Glob, Bash`, `model: inherit`).
- Description matches the `edge-case-reviewer` row from plan's description table.
- Body has CONTEXT section listing the 3 keys.
- No `{{...}}` placeholders remain.
- Standalone fallback block present.
- Commit `feat(agents): add edge-case-reviewer agent`.

---

### Task 3: Create quality-reviewer agent

**Status:** DONE

Create `plugins/kenspc/agents/quality-reviewer.md` from
`plugins/kenspc/skills/task-review/prompts/review-angle-3.md`. Same structure as
Task 2 with Angle 3 content (Code Quality and Project Conventions) and the
`quality-reviewer` description.

**Acceptance criteria:**
- File `plugins/kenspc/agents/quality-reviewer.md` exists with valid YAML
  frontmatter (`name: quality-reviewer`, `tools: Read, Grep, Glob, Bash`,
  `model: inherit`).
- Description matches plan table for `quality-reviewer`.
- Body has CONTEXT section listing 3 keys; no `{{...}}` remain; standalone
  fallback present.
- Commit `feat(agents): add quality-reviewer agent`.

---

### Task 4: Create bug-reviewer agent

**Status:** DONE

Create `plugins/kenspc/agents/bug-reviewer.md` from
`plugins/kenspc/skills/task-review/prompts/review-angle-4.md`. Same structure with
Angle 4 content (Bug Hunting, skeptical mindset) and the `bug-reviewer`
description.

Note: agent name is `bug-reviewer` (NOT `bug-hunter` from v1 plan) per v2 plan
naming alignment with the other 4 `*-reviewer` agents.

**Acceptance criteria:**
- File `plugins/kenspc/agents/bug-reviewer.md` exists with frontmatter
  (`name: bug-reviewer`, `tools: Read, Grep, Glob, Bash`, `model: inherit`).
- Description matches plan table for `bug-reviewer`.
- Body has CONTEXT section listing 3 keys; no `{{...}}` remain; standalone
  fallback present.
- Commit `feat(agents): add bug-reviewer agent`.

---

### Task 5: Create test-reviewer agent

**Status:** DONE

Create `plugins/kenspc/agents/test-reviewer.md` from
`plugins/kenspc/skills/task-review/prompts/review-angle-5.md`. Same structure with
Angle 5 content (Test Coverage) and the `test-reviewer` description.

**Acceptance criteria:**
- File `plugins/kenspc/agents/test-reviewer.md` exists with frontmatter
  (`name: test-reviewer`, `tools: Read, Grep, Glob, Bash`, `model: inherit`).
- Description matches plan table for `test-reviewer`.
- Body has CONTEXT section listing 3 keys; no `{{...}}` remain; standalone
  fallback present.
- Commit `feat(agents): add test-reviewer agent`.

---

### Task 6: Create code-fixer agent

**Status:** DONE

Create `plugins/kenspc/agents/code-fixer.md` from
`plugins/kenspc/skills/task-review/prompts/fix.md`. This is an orchestration-only
agent with the 3-layer standalone defense.

Structure:
1. YAML frontmatter:
   - `name: code-fixer`
   - `description:` the INTERNAL description for `code-fixer` from plan table
     (must start with "INTERNAL:" and explicitly say "Do not auto-delegate")
   - `tools: Read, Write, Edit, Bash, Grep, Glob`
   - `model: inherit`
2. Body (in this order):
   - PREREQUISITE CHECK section first (Layer 3 defense): if `REVIEW_REPORTS` is
     missing or empty in the CONTEXT block, output the bilingual refusal message
     "code-fixer requires 5 review reports as input. This agent is part of the
     /kenspc-task-review workflow. Invoke /kenspc-task-review instead." and stop
     without performing any work.
   - "CONTEXT YOU WILL RECEIVE" listing 4 keys: `TASK_FILE`, `REVIEW_SCOPE`,
     `CUSTOM_INSTRUCTIONS`, `REVIEW_REPORTS`.
   - ROLE, OBJECTIVE, INPUTS (rewritten to reference CONTEXT block), PREREQUISITES,
     EXECUTION FLOW, FIXING RULES, FIXING PRIORITY, OUTPUT FORMAT verbatim from
     source.

**Acceptance criteria:**
- File `plugins/kenspc/agents/code-fixer.md` exists with frontmatter
  (`name: code-fixer`, `tools: Read, Write, Edit, Bash, Grep, Glob`,
  `model: inherit`).
- Description first sentence starts with `INTERNAL:` and ends with "Do not
  auto-delegate.".
- Body's first executable section is PREREQUISITE CHECK that refuses on missing
  `REVIEW_REPORTS`.
- CONTEXT section lists exactly 4 keys.
- `grep -F "{{" plugins/kenspc/agents/code-fixer.md` returns no matches.
- Source body sections (ROLE, OBJECTIVE, EXECUTION FLOW, FIXING RULES, FIXING
  PRIORITY, OUTPUT FORMAT) all present.
- Commit `feat(agents): add code-fixer agent`.

---

### Task 7: Create regression-verifier agent

**Status:** DONE

Create `plugins/kenspc/agents/regression-verifier.md` from
`plugins/kenspc/skills/task-review/prompts/regression.md`. Orchestration-only
with stricter Layer 2 defense.

Structure:
1. YAML frontmatter:
   - `name: regression-verifier`
   - `description:` the INTERNAL description for `regression-verifier` from plan
     table.
   - `tools: Read, Bash, Grep, Glob` (NO `Write`, NO `Edit` — Layer 2 defense
     by design; this agent must not be able to modify code).
   - `model: inherit`
2. Body:
   - PREREQUISITE CHECK first: if `REVIEW_REPORTS` or `ACCOUNTABILITY_LIST` is
     missing in the CONTEXT block, output "regression-verifier requires review
     reports and accountability list as input. This agent is part of the
     /kenspc-task-review workflow. Invoke /kenspc-task-review instead." and stop.
   - "CONTEXT YOU WILL RECEIVE" listing 5 keys: `TASK_FILE`, `REVIEW_SCOPE`,
     `CUSTOM_INSTRUCTIONS`, `REVIEW_REPORTS`, `ACCOUNTABILITY_LIST`.
   - ROLE, OBJECTIVE, INPUTS (rewritten), PREREQUISITES, EXECUTION FLOW,
     OUTPUT FORMAT verbatim from source.

**Acceptance criteria:**
- File exists with frontmatter (`name: regression-verifier`, `model: inherit`).
- `tools` field is exactly `Read, Bash, Grep, Glob` (verify by string match — no
  Write, no Edit).
- Description starts with `INTERNAL:` and ends with "Do not auto-delegate.".
- PREREQUISITE CHECK refuses on missing `REVIEW_REPORTS` OR `ACCOUNTABILITY_LIST`.
- CONTEXT section lists exactly 5 keys.
- No `{{...}}` placeholders remain.
- Commit `feat(agents): add regression-verifier agent`.

---

### Task 8: Create task-implementer agent

**Status:** DONE

Create `plugins/kenspc/agents/task-implementer.md` from
`plugins/kenspc/skills/task-implement/prompts/implement.md`. This agent embeds
the plan-vs-task validation (mitigates v1 H4 risk) inside its prerequisite check.

Structure:
1. YAML frontmatter:
   - `name: task-implementer`
   - `description:` the INTERNAL description for `task-implementer` from plan
     table.
   - `tools: Read, Write, Edit, Bash, Grep, Glob`
   - `model: inherit`
2. Body:
   - PREREQUISITE CHECK first (4 numbered steps, exactly per plan Step 1.5):
     Step 1: refuse if `TASK_FILE` missing from CONTEXT.
     Step 2: read the file at `TASK_FILE` and inspect structure (task documents
     have `**Status:**` markers; plan documents have Phase/Step structure).
     Step 3: if file is a plan document, output the bilingual refusal "TASK_FILE
     points to a plan document, not a task document. Use /kenspc-task to generate
     a task document from this plan first. / TASK_FILE 是计划书，不是任务文档。请先用
     /kenspc-task 生成任务文档。" and stop without implementing anything.
     Step 4: if file does not exist or cannot be parsed, mark BLOCKED with reason
     and stop.
   - "CONTEXT YOU WILL RECEIVE" listing 1 key: `TASK_FILE`.
   - OBJECTIVE, PREREQUISITES, EXECUTION FLOW, QUALITY RULES, AUTONOMY BOUNDARIES
     (ALWAYS / STOP / NEVER blocks unchanged), QUALITY CHECKLIST, STUCK HANDLING,
     OUTPUT LANGUAGE, COMPLETION verbatim from source.

**Acceptance criteria:**
- File exists with frontmatter (`name: task-implementer`,
  `tools: Read, Write, Edit, Bash, Grep, Glob`, `model: inherit`).
- Description starts with `INTERNAL:` and ends with "Do not auto-delegate.".
- PREREQUISITE CHECK has 4 numbered steps; Step 3 contains both the English and
  Chinese halves of the plan-vs-task refusal message (verify by string match for
  both `TASK_FILE points to a plan document` and `TASK_FILE 是计划书`).
- CONTEXT section lists exactly 1 key (`TASK_FILE`).
- AUTONOMY BOUNDARIES section contains ALWAYS, STOP, NEVER subsections unchanged
  from source.
- No `{{...}}` placeholders remain.
- Commit `feat(agents): add task-implementer agent`.

---

### Task 9: Create plan-document-reviewer agent

**Status:** DONE

Create `plugins/kenspc/agents/plan-document-reviewer.md` from
`plugins/kenspc/skills/generate-plan/prompts/review.md`.

Structure:
1. YAML frontmatter:
   - `name: plan-document-reviewer`
   - `description:` the INTERNAL description for `plan-document-reviewer` from
     plan table.
   - `tools: Read, Write, Edit, Bash, Grep, Glob`
   - `model: inherit`
2. Body:
   - PREREQUISITE CHECK first: refuse with "plan-document-reviewer requires
     PLAN_PATH in CONTEXT. This agent is part of the /kenspc-plan workflow.
     Invoke /kenspc-plan instead." if `PLAN_PATH` missing.
   - "CONTEXT YOU WILL RECEIVE" listing 2 keys: `PLAN_PATH`, `PROJECT_PATH`.
   - OBJECTIVE, PREREQUISITES (rewritten to read from CONTEXT), all 4 REVIEW
     ANGLES, FIXING RULES, EXECUTION FLOW, OUTPUT LANGUAGE, COMPLETION verbatim.
   - All `{{PLAN_PATH}}` and `{{PROJECT_PATH}}` references rewritten to read from
     CONTEXT.

**Acceptance criteria:**
- File exists with frontmatter (`name: plan-document-reviewer`, full tools list,
  `model: inherit`).
- Description starts with `INTERNAL:` and ends with "Do not auto-delegate.".
- PREREQUISITE CHECK refuses on missing `PLAN_PATH`.
- CONTEXT section lists exactly 2 keys.
- All 4 review angles (Feasibility & Execution Order, Completeness, Consistency,
  Clarity & Actionability) preserved verbatim.
- No `{{...}}` placeholders remain.
- Commit `feat(agents): add plan-document-reviewer agent`.

---

### Task 10: Create guide-document-reviewer agent

**Status:** DONE

Create `plugins/kenspc/agents/guide-document-reviewer.md` from
`plugins/kenspc/skills/generate-guide/prompts/review.md`. Same pattern as Task 9
with `GUIDE_PATH` and `PROJECT_PATH`.

**Acceptance criteria:**
- File exists with frontmatter (`name: guide-document-reviewer`, full tools list,
  `model: inherit`).
- Description starts with `INTERNAL:` and ends with "Do not auto-delegate.".
- PREREQUISITE CHECK refuses on missing `GUIDE_PATH` with the corresponding
  /kenspc-guide INTERNAL message.
- CONTEXT section lists exactly 2 keys: `GUIDE_PATH`, `PROJECT_PATH`.
- All 4 review angles (Accuracy, Completeness, Executability, Consistency)
  preserved verbatim.
- No `{{...}}` placeholders remain.
- Commit `feat(agents): add guide-document-reviewer agent`.

---

### Task 11: Create task-document-reviewer agent

**Status:** DONE

Create `plugins/kenspc/agents/task-document-reviewer.md` from
`plugins/kenspc/skills/generate-task/prompts/review.md`. Same pattern with
3 CONTEXT keys.

Structure:
1. YAML frontmatter as for Task 9 with `name: task-document-reviewer`.
2. Body:
   - PREREQUISITE CHECK refusing on missing `TASK_DOC_PATH` with the
     /kenspc-task INTERNAL message.
   - "CONTEXT YOU WILL RECEIVE" listing 3 keys: `TASK_DOC_PATH`, `SOURCE_PATH`,
     `PROJECT_PATH`.
   - OBJECTIVE, PREREQUISITES (rewritten), both REVIEW ANGLES, ISSUE
     CLASSIFICATION (preserve task-level vs plan-level distinction — plan-level
     concerns recorded in task doc, plan never modified), EXECUTION FLOW, OUTPUT
     LANGUAGE, COMPLETION verbatim.

**Acceptance criteria:**
- File exists with frontmatter (`name: task-document-reviewer`, full tools list,
  `model: inherit`).
- Description starts with `INTERNAL:` and ends with "Do not auto-delegate.".
- PREREQUISITE CHECK refuses on missing `TASK_DOC_PATH`.
- CONTEXT section lists exactly 3 keys.
- ISSUE CLASSIFICATION section preserves the rule that plan-level issues are
  added to a "Plan-Level Concerns" section in the task document (NOT in the plan).
- Both review angles (Completeness, Execution Order) preserved verbatim.
- No `{{...}}` placeholders remain.
- Commit `feat(agents): add task-document-reviewer agent`.

---

### Task 12: Update task-review/SKILL.md to dispatch agents

**Status:** DONE

**Depends on:** Task 1, Task 2, Task 3, Task 4, Task 5, Task 6, Task 7

Modify `plugins/kenspc/skills/task-review/SKILL.md` per plan Step 2.1.

Changes:
1. Bump frontmatter `version`: `1.3.0` → `2.0.0`.
2. Execution section:
   - Remove Step 2 ("Read the prompt templates") entirely.
   - Replace Step 3 with "Construct CONTEXT block" containing keys `TASK_FILE`,
     `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`.
   - Remove the "Prompt variables" sub-table.
   - Rewrite Step 4 to dispatch the 5 review-angle agents by name
     (`requirements-reviewer`, `edge-case-reviewer`, `quality-reviewer`,
     `bug-reviewer`, `test-reviewer`) in 5 parallel Agent calls in a single
     message, passing the CONTEXT block.
   - Rewrite Step 5 to dispatch agent `code-fixer` with CONTEXT block extended
     to include `REVIEW_REPORTS` (all 5 reports inline).
   - Rewrite Step 6 to dispatch agent `regression-verifier` with CONTEXT extended
     to include `REVIEW_REPORTS` and `ACCOUNTABILITY_LIST`.
3. Step 1 (Determine review scope), Step 7 (Present results), Trigger Phrases,
   Common Rationalizations, Red Flags, Prerequisites, Arguments, Pass/Fail
   Determination, Summary remain unchanged.

**Acceptance criteria:**
- `head -20 plugins/kenspc/skills/task-review/SKILL.md` shows `version: 2.0.0`.
- `grep "prompts/" plugins/kenspc/skills/task-review/SKILL.md` returns no
  matches.
- `grep "{{" plugins/kenspc/skills/task-review/SKILL.md` returns no matches.
- Each of the 7 agent names (`requirements-reviewer`, `edge-case-reviewer`,
  `quality-reviewer`, `bug-reviewer`, `test-reviewer`, `code-fixer`,
  `regression-verifier`) appears at least once.
- Step 4 instructs dispatching 5 agents in a single parallel message.
- Step 7 (Present results) text unchanged from current.
- Commit `refactor(task-review): dispatch agents instead of reading prompts`.

---

### Task 13: Update task-implement/SKILL.md to dispatch agents

**Status:** DONE

**Depends on:** Task 8, Task 12

Modify `plugins/kenspc/skills/task-implement/SKILL.md` per plan Step 2.2 (Option B).

Changes:
1. Bump frontmatter `version`: `1.3.0` → `2.0.0`.
2. Phase 1:
   - Remove Step 1 ("Read the prompt template").
   - Step 2 (Validate input document) UNCHANGED (defense-in-depth — agent also
     validates; SKILL retains its existing plan-vs-task check).
   - Replace Step 3 with "Construct CONTEXT block" containing only `TASK_FILE`.
   - Remove "Prompt variables" sub-table.
   - Step 4 (Confirm with user) UNCHANGED.
   - Rewrite Step 5 to dispatch agent `task-implementer` with CONTEXT block.
   - Step 6 (Report progress) UNCHANGED.
3. Phase 2 (Option B — still delegates to task-review SKILL):
   - Rewrite Step 1 to "Read `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md`
     for its dispatch sequence (Steps 4-6 of its Execution section). Do NOT
     execute task-review's Step 1 ($ARGUMENTS parsing) — instead use the inputs
     constructed in this Phase 2 Step 2."
   - Replace Step 2 with "Construct CONTEXT block": `TASK_FILE` = same task path
     from Phase 1, `REVIEW_SCOPE = "task"`, `CUSTOM_INSTRUCTIONS = "N/A"`.
   - Rewrite Step 3 to "Follow task-review SKILL Steps 4-6: dispatch the 5
     review-angle agents in parallel, then `code-fixer`, then
     `regression-verifier`, using the CONTEXT block from Step 2. The verdict and
     reporting follow task-review SKILL Step 7."
   - Step 4 (Present final report) UNCHANGED.

**Acceptance criteria:**
- `head -20 plugins/kenspc/skills/task-implement/SKILL.md` shows `version: 2.0.0`.
- `grep "prompts/" plugins/kenspc/skills/task-implement/SKILL.md` returns no
  matches.
- `grep "{{" plugins/kenspc/skills/task-implement/SKILL.md` returns no matches.
- Phase 1 Step 5 references the agent name `task-implementer`.
- Phase 2 Step 1 explicitly states "Do NOT execute task-review's Step 1
  ($ARGUMENTS parsing)" or equivalent skip directive.
- Phase 1 Step 2 (Validate input document) text retained unchanged.
- Commit `refactor(task-implement): dispatch agents instead of reading prompts`.

---

### Task 14: Update generate-plan/SKILL.md to dispatch agent

**Status:** DONE

**Depends on:** Task 9

Modify `plugins/kenspc/skills/generate-plan/SKILL.md` per plan Step 2.3.

Changes:
1. Bump frontmatter `version`: `1.3.0` → `2.0.0`.
2. Phase 3:
   - Remove Step 1 ("Read the prompt template").
   - Replace Step 2 with "Construct CONTEXT block" containing `PLAN_PATH`,
     `PROJECT_PATH`.
   - Remove "Prompt variables" sub-table.
   - Rewrite Step 3 to dispatch agent `plan-document-reviewer` with the CONTEXT
     block.
   - Step 4 (Present results) UNCHANGED.
3. Phase 1 (Discover) and Phase 2 (Plan) UNCHANGED — including the
   `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md` reference.

**Acceptance criteria:**
- `head -20 plugins/kenspc/skills/generate-plan/SKILL.md` shows `version: 2.0.0`.
- `grep "prompts/review" plugins/kenspc/skills/generate-plan/SKILL.md` returns
  no matches.
- `grep "{{" plugins/kenspc/skills/generate-plan/SKILL.md` returns no matches.
- Phase 3 references agent name `plan-document-reviewer`.
- Phase 1 Step 3 reference to `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md`
  retained verbatim.
- Commit `refactor(generate-plan): dispatch agents instead of reading prompts`.

---

### Task 15: Update generate-guide/SKILL.md to dispatch agent

**Status:** DONE

**Depends on:** Task 10

Modify `plugins/kenspc/skills/generate-guide/SKILL.md` per plan Step 2.4.

Changes:
1. Bump frontmatter `version`: `1.2.0` → `2.0.0`.
2. Phase 2:
   - Remove Step 1 ("Read the prompt template").
   - Replace Step 2 with "Construct CONTEXT block" containing `GUIDE_PATH`,
     `PROJECT_PATH`.
   - Remove "Prompt variables" sub-table.
   - Rewrite Step 3 to dispatch agent `guide-document-reviewer`.
   - Step 4 (Present results) UNCHANGED.
3. Phase 1 (Generate the Guide) UNCHANGED.

**Acceptance criteria:**
- `head -20 plugins/kenspc/skills/generate-guide/SKILL.md` shows `version: 2.0.0`.
- `grep "prompts/review" plugins/kenspc/skills/generate-guide/SKILL.md` returns
  no matches.
- `grep "{{" plugins/kenspc/skills/generate-guide/SKILL.md` returns no matches.
- Phase 2 references agent name `guide-document-reviewer`.
- Commit `refactor(generate-guide): dispatch agents instead of reading prompts`.

---

### Task 16: Update generate-task/SKILL.md to dispatch agent

**Status:** DONE

**Depends on:** Task 11

Modify `plugins/kenspc/skills/generate-task/SKILL.md` per plan Step 2.5.

Changes:
1. Bump frontmatter `version`: `1.0.0` → `2.0.0`.
2. Phase 3:
   - Replace Step 1 (currently "Read and render the review prompt") with
     "Construct CONTEXT block" containing `TASK_DOC_PATH`, `SOURCE_PATH`,
     `PROJECT_PATH`.
   - Remove "Prompt variables" sub-table.
   - Rewrite Step 2 to dispatch agent `task-document-reviewer`.
   - Step 3 (Present results) UNCHANGED.
3. Phase 1 (Analyze) and Phase 2 (Confirm) UNCHANGED.

**Acceptance criteria:**
- `head -20 plugins/kenspc/skills/generate-task/SKILL.md` shows `version: 2.0.0`.
- `grep "prompts/review" plugins/kenspc/skills/generate-task/SKILL.md` returns
  no matches.
- `grep "{{" plugins/kenspc/skills/generate-task/SKILL.md` returns no matches.
- Phase 3 references agent name `task-document-reviewer`.
- Commit `refactor(generate-task): dispatch agents instead of reading prompts`.

---

### Task 17: Remove obsolete prompts/ directories

**Status:** DONE

**Depends on:** Task 12, Task 13, Task 14, Task 15, Task 16

Delete the following directories (11 files total) using `git rm -r`:
- `plugins/kenspc/skills/task-review/prompts/` (7 files: 5 review-angle + fix +
  regression)
- `plugins/kenspc/skills/task-implement/prompts/` (1 file: implement.md)
- `plugins/kenspc/skills/generate-plan/prompts/` (1 file: review.md)
- `plugins/kenspc/skills/generate-guide/prompts/` (1 file: review.md)
- `plugins/kenspc/skills/generate-task/prompts/` (1 file: review.md)

**Ordering invariant:** This task MUST NOT begin until Tasks 12-16 are all
committed. The state where `prompts/` is deleted while any SKILL still references
it must never exist on a checked-out branch.

**Acceptance criteria:**
- `find plugins/kenspc/skills -type d -name prompts` returns no results.
- `git status` shows no untracked or modified prompts/ files.
- `grep -r "prompts/" plugins/kenspc/skills/` returns no matches in any SKILL.md
  file.
- Commit message exactly `refactor: remove obsolete prompts/ directories
  (replaced by agents/)`.

---

### Task 18: Update root CLAUDE.md

**Status:** TODO

Modify `CLAUDE.md` (project root) per plan Step 3.2.

Changes:
1. **Plugin Directory Layout** section: insert `agents/` line above `commands/`
   with comment `# 11 reusable subagents (5 code reviewers + 3 doc reviewers + 3
   workers)`.
2. **Subagent Review Architecture** section (currently at line 91): replace
   existing prose with the rewritten version from plan Step 3.2 covering:
   - Three orchestration patterns (No review / Serial / Parallel MapReduce)
     with named agents per pattern.
   - "CONTEXT block contract" subsection.
   - "Standalone safety classification" subsection (5 standalone-safe + 6
     orchestration-only).
   - "Maintenance note" requiring synchronized changes across the 5 review-angle
     agents.
3. **Skill Development Conventions** section: update to reference `agents/`
   alongside `skills/`/`commands/` and remove all references to `prompts/`
   subdirectories.
4. Add a **Non-Goals** subsection summarizing why `discovery-framework.md` stays
   in `shared/` (linking to v2 plan's Non-Goals section as authoritative).

**Acceptance criteria:**
- `grep -n "agents/" CLAUDE.md` shows `agents/` listed in Plugin Directory Layout.
- `grep -n "Subagent Review Architecture" CLAUDE.md` returns one match.
- The Subagent Review Architecture section contains all three pattern names
  (No review, Serial review, Parallel MapReduce).
- `grep "prompts/" CLAUDE.md` returns no matches in description prose (excluding
  the deleted-files note if any).
- Non-Goals subsection mentions `discovery-framework.md`.
- Commit `docs: update root CLAUDE.md for agents/ migration`.

---

### Task 19: Update plugins/kenspc/README.md

**Status:** TODO

Modify `plugins/kenspc/README.md` per plan Step 3.3.

Changes:
1. **Directory tree** (~line 49): insert `agents/` line with comment
   `# 11 reusable subagents`; ensure `shared/` is listed with comment
   `# Cross-skill resources (e.g., discovery-framework.md)`.
2. **New "Agents" top-level section**: insert a Markdown table with 11 rows
   (one per agent), columns: Agent | Type | Standalone | Description. Use the
   exact rows from plan Step 3.3.
3. **Design Principles section**: append a bullet about agent reusability via
   `/agents` discovery.

**Acceptance criteria:**
- `grep "agents/" plugins/kenspc/README.md` shows `agents/` in the directory tree
  block.
- The README contains an `## Agents` (or equivalent) section heading.
- The Agents table contains 11 data rows (one per agent name from plan).
- All 11 agent names from plan inventory appear in the README.
- Design Principles section contains a new bullet referencing `/agents`.
- Commit `docs: add Agents section to README and update directory tree`.

---

### Task 20: Bump plugin.json to 2.0.0

**Status:** TODO

Modify `plugins/kenspc/.claude-plugin/plugin.json`:
1. `version`: `"1.5.0"` → `"2.0.0"`.
2. `description`: replace with the v2.0.0 description from plan Step 3.4 ("Eleven
   reusable subagents power requirement brief generation, plan generation, task
   decomposition, automated batch implementation with multi-angle review, and
   project guide generation.").

**Acceptance criteria:**
- `python -c "import json; print(json.load(open('plugins/kenspc/.claude-plugin/plugin.json'))['version'])"`
  outputs `2.0.0`.
- `python -m json.tool plugins/kenspc/.claude-plugin/plugin.json` succeeds (valid
  JSON).
- Description field contains the substring "Eleven reusable subagents".
- Other top-level fields (`name`, `author`, `repository`, `license`) unchanged.
- Commit `chore: bump plugin version to 2.0.0`.

---

### Task 21: Create CHANGELOG.md

**Status:** TODO

Create the new file `plugins/kenspc/CHANGELOG.md` with the v2.0.0 entry per plan
Step 3.6 template.

Required content:
- Heading `## 2.0.0 — 2026-05-04` (today's date in ISO format).
- `### Breaking changes` subsection noting prompts/ removal as plugin-internal
  with no impact on user-facing skill or command interfaces.
- `### Added` subsection listing the 11 agents grouped as: 5 code review angle
  agents (standalone-safe), 3 document reviewers (orchestration-only), 3 workers
  (orchestration-only). Use the exact agent names from plan inventory.
- `### Changed` subsection noting the 5 SKILL.md updates with version bumps.

**Acceptance criteria:**
- File `plugins/kenspc/CHANGELOG.md` exists.
- File contains heading `## 2.0.0 — 2026-05-04`.
- All 11 agent names from plan inventory appear in the Added section.
- "5 SKILL.md files" or "5 affected SKILL.md" appears in Changed section.
- Commit `docs: add CHANGELOG entry for v2.0.0`.

---

### Task 22: Verify standalone-safety defenses (Test B)

**Status:** TODO

**Depends on:** Task 17

**Note:** This task requires manual verification in a fresh main-session.
Subagents cannot spawn other subagents, so when invoked via
`/kenspc-task-implement` this task must be marked BLOCKED with reason
"requires manual verification in fresh main-session". Run these tests manually
after the implementation phase completes.

Execute three sub-tests per plan Testing Strategy section B:

**Sub-test B.1**: Invoke `@kenspc:bug-reviewer` with no CONTEXT block.
- Expected: agent outputs the standalone fallback usage block (showing example
  CONTEXT block) and stops. No code modification.

**Sub-test B.2**: Invoke `@kenspc:code-fixer` with no input.
- Expected: Layer 3 PREREQUISITE CHECK fires. Output contains "INTERNAL...
  Invoke /kenspc-task-review instead." and the agent stops.

**Sub-test B.3**: Invoke `@kenspc:task-implementer` pointing to a plan document
path (any plan document, e.g., `docs/plans/extract-reusable-agents-v2.md`).
- Expected: PREREQUISITE CHECK Step 3 fires. Output contains the bilingual
  "TASK_FILE points to a plan document..." / "TASK_FILE 是计划书..." refusal.
  Agent stops without implementing anything.

**Acceptance criteria:**
- All three sub-tests executed in a fresh main-session and behaviors match the
  expected outcomes.
- No code modifications, no commits, no test artifacts created during the
  verification.
- Verification result recorded: pass/fail per sub-test (in chat or separate
  notes file — does not modify the codebase).

---

### Task 23: Verify non-trigger description gating (Test C)

**Status:** TODO

**Depends on:** Task 17

**Note:** Same caveat as Task 22 — manual verification only. The implementing
agent should mark this BLOCKED.

Execute three sub-tests per plan Testing Strategy section C in a fresh
main-session where no review-related skill or workflow is active:

**Sub-test C.1**: Type `我看到一个 bug, 你帮我看看`.
- Expected: main session investigates directly via Read/Grep. The
  `bug-reviewer` agent does NOT auto-trigger.

**Sub-test C.2**: Type `Can you review my plan?`.
- Expected: main session asks a clarifying question (which plan? in this
  conversation? a file?). The `plan-document-reviewer` agent does NOT
  auto-trigger.

**Sub-test C.3**: Type `Fix this code`.
- Expected: main session fixes directly via Edit/Write tools. The `code-fixer`
  agent does NOT auto-trigger.

**Acceptance criteria:**
- All three sub-tests executed in a fresh main-session and behaviors match
  expected outcomes (no auto-delegation in any of the three).
- Verification result recorded: pass/fail per sub-test (in chat or separate
  notes file — does not modify the codebase).

---

## Plan-Level Concerns

The following items were identified during decomposition. They affect
interpretation of the plan but do not modify the plan document. The user should
review them before execution begins.

1. **Phase 1 Step 1.1 implies a separate empty-directory commit, which Git
   cannot do.** Tasks resolve this by merging Step 1.1 into Task 1
   (`requirements-reviewer` creation) — the directory is created as a side
   effect of writing the first agent file. Net result: 21 commits total
   (matches plan's stated "~21 commits"). Recorded per user-confirmed Q1
   option (A).

2. **Testing Strategy section A (5 happy-path end-to-end tests) and section D
   (semantic equivalence baseline) require fixture projects.** The plan does
   not specify which fixture projects to use, and capturing the v1.5.0
   baseline (Test D) requires running `/kenspc-task-review` against a fixture
   on the current main branch BEFORE Phase 1 starts. These tests are NOT
   converted into tasks. Recommendation: after the implementation tasks
   complete, manually select a fixture project (e.g., a small repo with
   intentional bugs as suggested in plan), run the v1.5.0 baseline against an
   older checkout, run v2.0.0 against the new state, and diff per plan Test D
   acceptable / unacceptable difference criteria.

3. **Tasks 22-23 (Tests B and C) are exposed as tasks but cannot be
   auto-executed by `/kenspc-task-implement`** because the plan itself notes
   "Subagents cannot spawn other subagents" (background section, plugin agent
   constraints). When `/kenspc-task-implement` reaches these tasks the
   implementing agent should mark them BLOCKED with the reason "requires
   manual verification in fresh main-session". The user must run them
   interactively after the implementation phase completes. Decided per
   user-confirmed Q2 option (B).

4. **Phase 2 Step 2.6 ("Verify generate-brief/SKILL.md is untouched") is
   correctly a no-op.** It is not converted into a task because no other task
   modifies that file; absence of modification is implicit verification. The
   `generate-brief` skill keeps its `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md`
   reference unchanged.

5. **Phase 3 Step 3.5 ("Verify command files need no changes") is also a
   no-op.** Verified during decomposition: `grep "prompts/" plugins/kenspc/commands/`
   returns no matches across all 6 command files. No task is required.

6. **Plan refers to "rewrite SCOPE DETECTION" for all 5 review-angle agents,
   but only `review-angle-1.md` has a separate SCOPE DETECTION section.**
   Angles 2-5 fold scope handling into PREREQUISITES (items 2-3 in their
   PREREQUISITES list). When implementing Tasks 2-5, preserve this asymmetric
   structure — the goal is that each agent reads `REVIEW_SCOPE` from the
   CONTEXT block, regardless of section name. No plan modification needed.

7. **CHANGELOG.md does not currently exist.** Plan Step 3.6 wording "Create or
   update" is resolved as **create**. Task 21 creates the file from scratch.
