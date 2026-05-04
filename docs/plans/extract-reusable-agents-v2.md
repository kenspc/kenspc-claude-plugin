# Plan v2: Extract Reusable Agents from kenspc Plugin

> **Version**: v2 (supersedes v1)
> **Status**: Ready for task decomposition
> **Target plugin version**: kenspc 1.5.0 → 2.0.0
> **Last updated**: 2026-05-04

## What changed from v1

This plan was rewritten after a deep review of the original draft. Key revisions:

1. **Corrected baseline facts** — current plugin version is 1.5.0 (not 1.4.0); plugin agent unsupported frontmatter is *rejected by validation*, not silently ignored
2. **task-implement Phase 2 architecture decided** — Option B: still delegates to task-review SKILL.md, with rewritten dispatch instructions
3. **No backwards-compatibility shim** — v2.0.0 + CHANGELOG only
4. **Naming convention finalized** — kebab-case, no `kenspc-` prefix; description text gates auto-delegation; `bug-hunter` → `bug-reviewer`; document reviewers use `*-document-reviewer` pattern (e.g., `plan-document-reviewer`) for clarity in a multi-plugin world
5. **Standalone defense made into 3 layers** — description + tool allowlist + body prerequisite check
6. **Per-agent CONTEXT schemas now explicit** — heterogeneous input shapes documented per agent (replaces v1's single-format CONTEXT block)
7. **SKILL.md versions** — all bumped to 2.0.0 alongside plugin
8. **discovery-framework treatment documented** — explicit non-goal with rationale
9. **Migration ordering and commit granularity specified**
10. **Testing strategy expanded** — non-trigger tests + semantic equivalence baseline

## Objective

Refactor the kenspc Claude Code plugin to adopt the official `agents/` directory convention. Move subagent prompt templates from `skills/*/prompts/` into `plugins/kenspc/agents/` as proper agent definition files (Markdown + YAML frontmatter), making them discoverable via `/agents`, invocable standalone (where safe), and reusable across skills.

**In scope:**
- Create `plugins/kenspc/agents/` directory with 11 agent definition files
- Restructure all 11 prompt templates into agents (static system prompt + dynamic CONTEXT separation)
- Update all 5 affected SKILL.md files to dispatch agents by name
- Implement 3-layer standalone defense for orchestration-only agents
- Remove emptied `prompts/` directories
- Update CLAUDE.md, README.md, and plugin.json for v2.0.0

**Out of scope (explicit non-goals):**
- Convert `shared/discovery-framework.md` to an agent (see Non-Goals section for rationale)
- Backwards-compatibility shim for old `prompts/` paths
- Adding new skills or agents not derived from existing prompts
- Hooks changes (plugin agents do not support `hooks` frontmatter)
- Changing the bilingual output convention (English + Chinese)
- Changing workflow logic (phases, confirmation steps, reporting)

## Non-Goals (with rationale)

### Non-goal 1: Do NOT convert `discovery-framework.md` to an agent

`shared/discovery-framework.md` is consumed at three call sites:
- `generate-brief/SKILL.md` Phase 1 Step 2 — main session reads it as "structural guide for the following conversation"
- `generate-plan/SKILL.md` Phase 1 Step 3 — main session reads it as "structural guide for the following discussion"
- `generate-plan/SKILL.md` Phase 1 Step 1 — referenced from brief gap-checking logic

In all three cases, the framework is consumed by the **main session** — not delegated to a subagent. Two reasons it must stay this way:

1. **Discovery is free-form dialogue with the user, not bounded delegated work.** Subagents talk to users via AskUserQuestion (structured Q&A), which cannot express discovery's "one question at a time, build on user's words, recommend when uncertain" pattern.
2. **Phase 2 (writing the brief/plan) needs raw conversation context.** The brief template explicitly asks for things like "if multiple candidates were discussed, briefly note the rejected options" — this requires Phase 2 to remember Phase 1's actual conversation, not a digested summary. Subagent isolation would break this fidelity.

The `shared/` directory is the correct mechanism for this kind of cross-skill behavior guide — different from `agents/`, which is for delegated workers.

### Non-goal 2: No backwards-compatibility shim

The `prompts/` directory paths are plugin-internal implementation details. The probability of external code depending on these paths is effectively zero. Bumping plugin version to 2.0.0 plus a CHANGELOG entry is sufficient. A shim (keeping old prompt files as redirect stubs) would add 11 maintenance-burden files for no realistic benefit.

## Background

The plugin currently stores subagent prompts as template files inside each skill's `prompts/` subdirectory. Skills act as orchestrators: they read these files, replace `{{PLACEHOLDER}}` variables, and dispatch subagents via the Agent tool. Limitations:

1. Agents are invisible to `/agents` UI and not independently discoverable
2. Agents cannot be invoked standalone for ad-hoc use
3. Agent definitions are coupled to specific skills even when generic
4. No official frontmatter metadata — all behavior governance is embedded in prose

Claude Code supports plugin-level `agents/` directories as a first-class feature. Plugin agents appear in the `/agents` interface, can be @-mentioned (e.g., `@kenspc:bug-reviewer`), and inherit the plugin namespace automatically.

### Plugin agent constraints (verified against official docs)

- **Unsupported frontmatter fields are rejected by validation, not silently ignored**: `hooks`, `mcpServers`, and `permissionMode` cannot appear in plugin agent files. (Source: Claude Code plugins-reference, "For security reasons...")
- **Supported frontmatter fields** include: `name`, `description`, `model`, `effort`, `maxTurns`, `tools`, `disallowedTools`, `skills`, `memory`, `background`, `isolation`
- **Subagents cannot spawn other subagents**: orchestration must remain at the main session level. (Source: Claude Code agent-sdk subagents docs.)

### Key implication

The task-review skill's parallel MapReduce architecture (5 review agents → fix → regression) MUST stay orchestrated from the skill (main session). Agents cannot internally delegate to other agents.

## Technical Approach

### Static / Dynamic split

Current structure (template-based):
```
skills/task-review/prompts/review-angle-1.md
  → Contains {{TASK_FILE}}, {{REVIEW_SCOPE}}, {{CUSTOM_INSTRUCTIONS}} placeholders
  → SKILL.md reads file, substitutes placeholders, passes rendered string as Agent tool prompt
```

New structure (agent-based):
```
agents/requirements-reviewer.md
  → YAML frontmatter (name, description, tools, model)
  → Markdown body (system prompt): role, objective, checklist, output format — STATIC
  → SKILL.md dispatches agent by name; passes a CONTEXT block as Agent tool prompt — DYNAMIC
```

The split:
- **Static (agent body / system prompt)**: role definition, review checklist, output format, execution rules, fixing rules, language conventions, prerequisite check
- **Dynamic (Agent tool prompt at dispatch time)**: file paths, review scope, custom instructions, previous agent outputs (for fix/regression agents)

The model sees both system prompt and user message together — semantic content is unchanged, only the architectural boundary moves.

### Per-agent CONTEXT schema

Different agents need different inputs. Each agent's body must declare its expected CONTEXT keys explicitly. The dispatching SKILL.md must construct exactly these keys.

| Agent | Required CONTEXT keys |
|---|---|
| `requirements-reviewer` | `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS` |
| `edge-case-reviewer` | `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS` |
| `quality-reviewer` | `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS` |
| `bug-reviewer` | `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS` |
| `test-reviewer` | `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS` |
| `code-fixer` | `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`, `REVIEW_REPORTS` (5 reports inline) |
| `regression-verifier` | `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`, `REVIEW_REPORTS`, `ACCOUNTABILITY_LIST` |
| `task-implementer` | `TASK_FILE` |
| `plan-document-reviewer` | `PLAN_PATH`, `PROJECT_PATH` |
| `guide-document-reviewer` | `GUIDE_PATH`, `PROJECT_PATH` |
| `task-document-reviewer` | `TASK_DOC_PATH`, `SOURCE_PATH`, `PROJECT_PATH` |

Standard CONTEXT block format (illustrative for `requirements-reviewer`):
```
CONTEXT
- TASK_FILE: docs/tasks/auth-tasks.md
- REVIEW_SCOPE: task
- CUSTOM_INSTRUCTIONS: only review src/api/
```

For `code-fixer` and `regression-verifier`, the additional fields contain potentially long inline content:
```
CONTEXT
- TASK_FILE: ...
- REVIEW_SCOPE: ...
- CUSTOM_INSTRUCTIONS: ...

REVIEW_REPORTS

[Angle 1 full report]
---
[Angle 2 full report]
---
... (Angles 3-5)
```

Each agent body contains a **"CONTEXT YOU WILL RECEIVE"** section listing exactly its keys. This is the contract between SKILL.md and agent.

### Agent inventory (final names)

#### Code review angles (5 agents) — standalone-safe

| File | Agent name | Renamed from | Standalone-safe? |
|---|---|---|---|
| `agents/requirements-reviewer.md` | `requirements-reviewer` | review-angle-1.md | Yes |
| `agents/edge-case-reviewer.md` | `edge-case-reviewer` | review-angle-2.md | Yes |
| `agents/quality-reviewer.md` | `quality-reviewer` | review-angle-3.md | Yes |
| `agents/bug-reviewer.md` | `bug-reviewer` | review-angle-4.md (was `bug-hunter` in v1 plan) | Yes |
| `agents/test-reviewer.md` | `test-reviewer` | review-angle-5.md | Yes |

Naming pattern: `<aspect>-reviewer`. All read-only.

#### Workflow workers (3 agents) — orchestration-only

| File | Agent name | From | Standalone-safe? |
|---|---|---|---|
| `agents/code-fixer.md` | `code-fixer` | task-review/prompts/fix.md | No — requires REVIEW_REPORTS |
| `agents/regression-verifier.md` | `regression-verifier` | task-review/prompts/regression.md | No — requires REVIEW_REPORTS + ACCOUNTABILITY_LIST |
| `agents/task-implementer.md` | `task-implementer` | task-implement/prompts/implement.md | No — requires validated TASK_FILE |

#### Document reviewers (3 agents) — orchestration-only

| File | Agent name | From | Standalone-safe? |
|---|---|---|---|
| `agents/plan-document-reviewer.md` | `plan-document-reviewer` | generate-plan/prompts/review.md | No — requires PLAN_PATH from generation flow |
| `agents/guide-document-reviewer.md` | `guide-document-reviewer` | generate-guide/prompts/review.md | No — requires GUIDE_PATH from generation flow |
| `agents/task-document-reviewer.md` | `task-document-reviewer` | generate-task/prompts/review.md | No — requires TASK_DOC_PATH from generation flow |

Naming pattern: `<doc-type>-document-reviewer`. The "-document-" segment disambiguates from the 5 code-review agents and from any plan/guide/task-named agents in other plugins.

### Standalone defense — 3 layers

For orchestration-only agents, breaking the input contract via standalone invocation must be defended at three layers:

**Layer 1 — Description gates auto-delegation routing.** First sentence MUST start with `INTERNAL:` and explicitly say "Do not auto-delegate."

**Layer 2 — Tool allowlist limits blast radius.** `regression-verifier` does NOT include `Write` or `Edit` (cannot modify code by design). Other agents include only what they need.

**Layer 3 — Body prerequisite check refuses on missing CONTEXT.** First instruction in agent body validates that all required CONTEXT keys are present; if any are missing, output a refusal message and stop.

For `task-implementer` specifically, the prerequisite check must also re-implement the plan-vs-task validation that previously lived in the SKILL — see Phase 1 Step 5 below.

### Agent description templates

**Standalone-safe (5 review angles)**:
```yaml
description: >
  Reviews code from the <SPECIFIC ANGLE> perspective: <one-line scope>.
  Used by /kenspc-task-review parallel review (Angle <N>); also safe to invoke
  standalone with a project context.
```

**Orchestration-only (6 agents)**:
```yaml
description: >
  INTERNAL: Part of /kenspc-<WORKFLOW> orchestration. Requires structured
  CONTEXT input from the calling skill — standalone invocation will fail the
  prerequisite check. Do not auto-delegate.
```

Specific descriptions per agent (use these exactly):

| Agent | Description |
|---|---|
| `requirements-reviewer` | `Reviews code completeness against requirements: are all required changes implemented, are there partially implemented features, do interfaces match design. Used by /kenspc-task-review parallel review (Angle 1); also safe to invoke standalone with a project context.` |
| `edge-case-reviewer` | `Reviews code for edge cases and error handling: null/empty/boundary values, error propagation, resource cleanup, server-side validation. Used by /kenspc-task-review parallel review (Angle 2); also safe to invoke standalone with a project context.` |
| `quality-reviewer` | `Reviews code quality: project conventions, readability, maintainability, naming, and structural issues. Used by /kenspc-task-review parallel review (Angle 3); also safe to invoke standalone with a project context.` |
| `bug-reviewer` | `Reviews code with skeptical bug-hunting mindset: off-by-one errors, null references, async correctness, race conditions, query correctness, type safety. Used by /kenspc-task-review parallel review (Angle 4); also safe to invoke standalone with a project context.` |
| `test-reviewer` | `Reviews test coverage and test quality: happy/edge/error path coverage, test correctness, behavior-not-implementation testing. Used by /kenspc-task-review parallel review (Angle 5); also safe to invoke standalone with a project context.` |
| `code-fixer` | `INTERNAL: Part of /kenspc-task-review orchestration. Requires REVIEW_REPORTS structured CONTEXT input from the calling skill — standalone invocation will fail the prerequisite check. Do not auto-delegate.` |
| `regression-verifier` | `INTERNAL: Part of /kenspc-task-review orchestration. Requires REVIEW_REPORTS and ACCOUNTABILITY_LIST CONTEXT — standalone invocation will fail the prerequisite check. Do not auto-delegate.` |
| `task-implementer` | `INTERNAL: Part of /kenspc-task-implement orchestration. Requires validated task document path — standalone invocation will fail the prerequisite check. Do not auto-delegate.` |
| `plan-document-reviewer` | `INTERNAL: Part of /kenspc-plan generation orchestration. Requires PLAN_PATH from a freshly generated plan document — standalone invocation will fail the prerequisite check. Do not auto-delegate.` |
| `guide-document-reviewer` | `INTERNAL: Part of /kenspc-guide generation orchestration. Requires GUIDE_PATH from a freshly generated guide document — standalone invocation will fail the prerequisite check. Do not auto-delegate.` |
| `task-document-reviewer` | `INTERNAL: Part of /kenspc-task generation orchestration. Requires TASK_DOC_PATH and SOURCE_PATH from a freshly generated task document — standalone invocation will fail the prerequisite check. Do not auto-delegate.` |

### Tool allocation

| Agent | Tools |
|---|---|
| 5 review-angle agents | `Read, Grep, Glob, Bash` (read-only) |
| `code-fixer` | `Read, Write, Edit, Bash, Grep, Glob` |
| `regression-verifier` | `Read, Bash, Grep, Glob` (NO Write/Edit — Layer 2 defense) |
| `task-implementer` | `Read, Write, Edit, Bash, Grep, Glob` |
| `plan-document-reviewer` | `Read, Write, Edit, Bash, Grep, Glob` |
| `guide-document-reviewer` | `Read, Write, Edit, Bash, Grep, Glob` |
| `task-document-reviewer` | `Read, Write, Edit, Bash, Grep, Glob` |

`model: inherit` for all 11 agents in v2.0.0. Per-agent tuning of `effort`/`maxTurns` is a post-2.0.0 backlog item.

### Frontmatter template

```yaml
---
name: <agent-name>
description: >
  <description from table above>
tools: <comma-separated tool list>
model: inherit
---
```

Do NOT include `hooks`, `mcpServers`, or `permissionMode` — these are rejected by Claude Code validation for plugin agents.

## Implementation Steps

### Phase 1: Create agent files

Each Phase 1 step produces one git commit (or one commit per file in 1.2). Commit message format: `feat(agents): add <agent-name> agent`.

#### Step 1.1: Create `plugins/kenspc/agents/` directory

Create the directory. No content yet.

#### Step 1.2: Create the 5 review-angle agents (5 commits)

For each of the 5 review-angle prompt files (`review-angle-1.md` through `review-angle-5.md`), create a corresponding agent file in `plugins/kenspc/agents/`. Per file:

1. Add YAML frontmatter (name from inventory, description from description table, tools = `Read, Grep, Glob, Bash`, `model: inherit`)
2. Move the ROLE, OBJECTIVE, REVIEW CHECKLIST, OUTPUT FORMAT sections from the original prompt into the agent body verbatim
3. Add a "CONTEXT YOU WILL RECEIVE" section listing the 3 expected keys (`TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`)
4. Rewrite PREREQUISITES to read from the CONTEXT block instead of `{{...}}` placeholders
5. Rewrite SCOPE DETECTION to reference the CONTEXT block's `REVIEW_SCOPE` value
6. Rewrite CUSTOM INSTRUCTIONS to reference the CONTEXT block's `CUSTOM_INSTRUCTIONS` value
7. Keep FILE COVERAGE, OUTPUT FORMAT, summary line sections unchanged
8. Keep all bilingual conventions unchanged

Standalone-safe so no Layer 3 prerequisite refusal needed — but the agent body should gracefully handle a CONTEXT-less invocation (state "no CONTEXT received, will infer review scope as 'changes' from git state" and proceed).

> Correction: per L-new3 decision (require CONTEXT), agents MUST refuse without CONTEXT. Override the gracefully-handle clause: even standalone-safe agents output a usage message asking the caller to provide a CONTEXT block, and stop.

Standalone-safe agents' Layer 3 message:
```
This agent expects a CONTEXT block. Example:
  CONTEXT
  - TASK_FILE: docs/tasks/foo.md   (or "N/A")
  - REVIEW_SCOPE: task              (or "changes")
  - CUSTOM_INSTRUCTIONS: <text>     (or "N/A")

Please re-invoke with the structured CONTEXT block above.
```

#### Step 1.3: Create `code-fixer` agent (1 commit)

From `task-review/prompts/fix.md`:
1. Frontmatter: tools = `Read, Write, Edit, Bash, Grep, Glob`
2. Body: ROLE, OBJECTIVE, EXECUTION FLOW, FIXING RULES, FIXING PRIORITY, OUTPUT FORMAT verbatim
3. Add "CONTEXT YOU WILL RECEIVE" listing `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`, `REVIEW_REPORTS`
4. Layer 3 prerequisite check at body start:
   ```
   PREREQUISITE CHECK
   If REVIEW_REPORTS is missing or empty in the CONTEXT block, output:
     "code-fixer requires 5 review reports as input. This agent is part of
     the /kenspc-task-review workflow. Invoke /kenspc-task-review instead."
   Then stop without performing any work.
   ```
5. Rewrite the INPUTS section to reference the CONTEXT block

#### Step 1.4: Create `regression-verifier` agent (1 commit)

From `task-review/prompts/regression.md`:
1. Frontmatter: tools = `Read, Bash, Grep, Glob` (Layer 2: no Write/Edit by design)
2. Body: all sections verbatim
3. Add "CONTEXT YOU WILL RECEIVE" listing `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS`, `REVIEW_REPORTS`, `ACCOUNTABILITY_LIST`
4. Layer 3 prerequisite check:
   ```
   PREREQUISITE CHECK
   If REVIEW_REPORTS or ACCOUNTABILITY_LIST is missing in the CONTEXT block,
   output:
     "regression-verifier requires review reports and accountability list as
     input. This agent is part of the /kenspc-task-review workflow. Invoke
     /kenspc-task-review instead."
   Then stop without performing any work.
   ```

#### Step 1.5: Create `task-implementer` agent (1 commit)

From `task-implement/prompts/implement.md`:
1. Frontmatter: tools = `Read, Write, Edit, Bash, Grep, Glob`
2. Body: OBJECTIVE, PREREQUISITES, EXECUTION FLOW, QUALITY RULES, AUTONOMY BOUNDARIES, QUALITY CHECKLIST, STUCK HANDLING, OUTPUT LANGUAGE, COMPLETION verbatim
3. Add "CONTEXT YOU WILL RECEIVE" listing `TASK_FILE`
4. Layer 3 prerequisite check (with embedded plan-vs-task validation, mitigating original v1 H4):
   ```
   PREREQUISITE CHECK
   1. If TASK_FILE is missing from the CONTEXT block, output:
        "task-implementer requires a TASK_FILE in CONTEXT. Invoke
        /kenspc-task-implement instead of using this agent directly."
      Then stop.

   2. Read the file at TASK_FILE. Inspect its structure:
      - A task document contains entries with **Status:** markers
        (TODO, IN PROGRESS, DONE, BLOCKED).
      - A plan document contains Implementation Steps organized by Phase/Step,
        without Status markers.

   3. If the file is a plan document (Phase/Step structure, no Status markers),
      output:
        "TASK_FILE points to a plan document, not a task document. Use
        /kenspc-task to generate a task document from this plan first. /
        TASK_FILE 是计划书，不是任务文档。请先用 /kenspc-task 生成任务文档。"
      Then stop without implementing anything.

   4. If the file does not exist or cannot be parsed, mark the run as BLOCKED
      with the reason and stop.
   ```
5. Keep all autonomy boundaries (ALWAYS / STOP / NEVER) and quality rules unchanged

#### Step 1.6: Create `plan-document-reviewer` agent (1 commit)

From `generate-plan/prompts/review.md`:
1. Frontmatter: tools = `Read, Write, Edit, Bash, Grep, Glob`
2. Body: OBJECTIVE, PREREQUISITES, REVIEW ANGLES (all 4), FIXING RULES, EXECUTION FLOW, OUTPUT LANGUAGE, COMPLETION verbatim
3. Add "CONTEXT YOU WILL RECEIVE" listing `PLAN_PATH`, `PROJECT_PATH`
4. Layer 3 prerequisite check:
   ```
   PREREQUISITE CHECK
   If PLAN_PATH is missing from the CONTEXT block, output:
     "plan-document-reviewer requires PLAN_PATH in CONTEXT. This agent is
     part of the /kenspc-plan workflow. Invoke /kenspc-plan instead."
   Then stop.
   ```
5. Rewrite `{{PLAN_PATH}}` and `{{PROJECT_PATH}}` references to read from CONTEXT

#### Step 1.7: Create `guide-document-reviewer` agent (1 commit)

From `generate-guide/prompts/review.md`. Same pattern as 1.6, with `GUIDE_PATH` and `PROJECT_PATH`.

#### Step 1.8: Create `task-document-reviewer` agent (1 commit)

From `generate-task/prompts/review.md`. Same pattern as 1.6, with `TASK_DOC_PATH`, `SOURCE_PATH`, `PROJECT_PATH`. Keep the distinction between task-level fixes (apply directly) and plan-level concerns (record in Plan-Level Concerns section, do NOT modify the plan).

### Phase 2: Update SKILL.md files to dispatch agents

Each Phase 2 step is one commit. Commit message format: `refactor(<skill-name>): dispatch agents instead of reading prompts`.

#### Step 2.1: Update `task-review/SKILL.md` (1 commit)

**Bump frontmatter `version`: 1.3.0 → 2.0.0**

Changes to Execution section:

| Current step | New step |
|---|---|
| Step 2: Read the prompt templates | **REMOVE** entirely |
| Step 3: Render prompts | **REPLACE** with "Construct CONTEXT block" — build a structured string with `TASK_FILE`, `REVIEW_SCOPE`, `CUSTOM_INSTRUCTIONS` |
| Step 3 sub-table "Prompt variables" | **REMOVE** (no more variables) |
| Step 4: Dispatch parallel review agents | **REWRITE**: dispatch by agent name (`requirements-reviewer`, `edge-case-reviewer`, `quality-reviewer`, `bug-reviewer`, `test-reviewer`) in 5 parallel Agent calls, passing the CONTEXT block as the dispatch prompt |
| Step 5: Dispatch fix agent | **REWRITE**: dispatch agent `code-fixer` with CONTEXT block extended with `REVIEW_REPORTS` field containing all 5 reports |
| Step 6: Dispatch regression agent | **REWRITE**: dispatch agent `regression-verifier` with CONTEXT block extended with `REVIEW_REPORTS` and `ACCOUNTABILITY_LIST` |
| Step 7: Present results | **UNCHANGED** |

Steps NOT changed: Step 1 (Determine review scope), Trigger Phrases, Common Rationalizations, Red Flags, Prerequisites, Arguments, Pass/Fail Determination, Summary format.

#### Step 2.2: Update `task-implement/SKILL.md` (1 commit)

**Bump frontmatter `version`: 1.3.0 → 2.0.0**

**Phase 1 changes:**

| Current step | New step |
|---|---|
| Step 1: Read the prompt template | **REMOVE** |
| Step 2: Validate input document | **UNCHANGED** (still validates plan-vs-task at SKILL level — defense in depth, the agent also validates) |
| Step 3: Render the prompt | **REPLACE** with "Construct CONTEXT block" — `TASK_FILE` only |
| Step 3 sub-table "Prompt variables" | **REMOVE** |
| Step 4: Confirm with user | **UNCHANGED** |
| Step 5: Dispatch the implement agent | **REWRITE**: dispatch agent `task-implementer` with CONTEXT block |
| Step 6: Report progress | **UNCHANGED** |

**Phase 2 changes (Option B — task-implement still delegates to task-review SKILL):**

| Current step | New step |
|---|---|
| Step 1: Read the review skill | **REWRITE**: "Read `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` for its dispatch sequence (Steps 4-6 of its Execution section). **Do NOT execute task-review's Step 1 ($ARGUMENTS parsing)** — instead use the inputs constructed in this Phase 2 Step 2." |
| Step 2: Render the review prompt | **REPLACE** with "Construct CONTEXT block" — `TASK_FILE` = same task path from Phase 1, `REVIEW_SCOPE` = "task", `CUSTOM_INSTRUCTIONS` = "N/A" |
| Step 3: Dispatch the review | **REWRITE**: "Follow task-review SKILL Steps 4-6: dispatch the 5 review-angle agents in parallel, then `code-fixer`, then `regression-verifier`, using the CONTEXT block from Step 2. The verdict and reporting follow task-review SKILL Step 7." |
| Step 4: Present final report | **UNCHANGED** |

Steps NOT changed: Trigger Phrases, Common Rationalizations, Red Flags, Prerequisites, Arguments parsing.

#### Step 2.3: Update `generate-plan/SKILL.md` (1 commit)

**Bump frontmatter `version`: 1.3.0 → 2.0.0** (current version inferred — verify in implementation)

Phase 3 changes:

| Current step | New step |
|---|---|
| Step 1: Read the prompt template | **REMOVE** |
| Step 2: Render the prompt | **REPLACE** with "Construct CONTEXT block" — `PLAN_PATH`, `PROJECT_PATH` |
| Step 2 sub-table "Prompt variables" | **REMOVE** |
| Step 3: Dispatch the review agent | **REWRITE**: dispatch agent `plan-document-reviewer` with CONTEXT block |
| Step 4: Present results | **UNCHANGED** |

Phase 1 (Discover) and Phase 2 (Plan): **UNCHANGED** — still main session. The reference to `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md` stays exactly as-is.

#### Step 2.4: Update `generate-guide/SKILL.md` (1 commit)

**Bump frontmatter `version`: 1.2.0 → 2.0.0**

Phase 2 changes (same shape as 2.3):

| Current step | New step |
|---|---|
| Step 1: Read the prompt template | **REMOVE** |
| Step 2: Render the prompt | **REPLACE** with "Construct CONTEXT block" — `GUIDE_PATH`, `PROJECT_PATH` |
| Step 2 sub-table "Prompt variables" | **REMOVE** |
| Step 3: Dispatch the review agent | **REWRITE**: dispatch agent `guide-document-reviewer` |
| Step 4: Present results | **UNCHANGED** |

Phase 1 (Generate the Guide): **UNCHANGED**.

#### Step 2.5: Update `generate-task/SKILL.md` (1 commit)

**Bump frontmatter `version`: 1.0.0 → 2.0.0**

Phase 3 changes (same shape):

| Current step | New step |
|---|---|
| Step 1: Read and render the review prompt | **REPLACE** with "Construct CONTEXT block" — `TASK_DOC_PATH`, `SOURCE_PATH`, `PROJECT_PATH` |
| Step 1 sub-table "Prompt variables" | **REMOVE** |
| Step 2: Dispatch the review agent | **REWRITE**: dispatch agent `task-document-reviewer` |
| Step 3: Present results | **UNCHANGED** |

Phase 1 (Analyze) and Phase 2 (Confirm): **UNCHANGED**.

#### Step 2.6: Verify `generate-brief/SKILL.md` is untouched (no commit)

`generate-brief` has no review phase — there is no prompt file to convert. The skill's Phase 1 reference to `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md` is unchanged. No version bump necessary unless touched.

### Phase 3: Cleanup and documentation

Each step is one commit.

#### Step 3.1: Remove old prompt files (1 commit)

**Ordering invariant**: This step MUST NOT begin until ALL Phase 2 commits are merged and verified. The state where `prompts/` is deleted while any SKILL still references it must never exist on a checked-out branch.

Delete:
- `plugins/kenspc/skills/task-review/prompts/` (entire directory)
- `plugins/kenspc/skills/task-implement/prompts/` (entire directory)
- `plugins/kenspc/skills/generate-plan/prompts/` (entire directory)
- `plugins/kenspc/skills/generate-guide/prompts/` (entire directory)
- `plugins/kenspc/skills/generate-task/prompts/` (entire directory)

Commit message: `refactor: remove obsolete prompts/ directories (replaced by agents/)`.

#### Step 3.2: Update `CLAUDE.md` (1 commit)

**Update Plugin Directory Layout section.** Insert `agents/` line above `commands/`:
```
plugins/kenspc/
├── .claude-plugin/plugin.json
├── agents/                      # 11 reusable subagents (5 code reviewers + 3 doc reviewers + 3 workers)
├── commands/
├── hooks/
├── references/
├── shared/
├── skills/
...
```

**Rewrite the "Subagent Review Architecture" section.** Replace existing text with:

```markdown
### Subagent Review Architecture

Skills use plugin agents (defined in `agents/`) as workers, dispatched via the
Agent tool. Three orchestration patterns:

**No review (generate-brief):**
Brief is a discovery artifact, not a verifiable spec. Review happens downstream
when generate-plan consumes the brief. Phase 1 detection in generate-plan
recognizes briefs and gap-checks against the same five dimensions defined in
`shared/discovery-framework.md`.

**Serial review (generate-plan, generate-task, generate-guide):**
Skill dispatches a single named agent (`plan-document-reviewer`,
`task-document-reviewer`, or `guide-document-reviewer`) that reviews all
angles in order in its own context. Each angle builds on fixes from the
previous one (cascade dependency). Agent body returns a structured change log.

**Parallel MapReduce (task-review):**
- Phase 1: 5 read-only review agents dispatched in parallel
  (`requirements-reviewer`, `edge-case-reviewer`, `quality-reviewer`,
  `bug-reviewer`, `test-reviewer`) — one per angle.
- Phase 2: `code-fixer` receives all 5 reports, deduplicates, applies fixes,
  produces accountability list.
- Phase 3: `regression-verifier` cross-checks reports against accountability
  list, verifies fixes, runs build/test/lint.

No shared state files — each agent runs in its own context, eliminating
concurrency conflicts. Subagents cannot spawn other subagents; orchestration
stays at the skill (main session) level.

### CONTEXT block contract

Each agent declares its expected CONTEXT keys in its body. The dispatching
SKILL.md must construct exactly those keys. See each agent file's
"CONTEXT YOU WILL RECEIVE" section for the contract.

### Standalone safety classification

- **Standalone-safe**: 5 review-angle agents (requirements, edge-case, quality,
  bug, test) can be invoked directly. Description gates auto-delegation;
  body refuses without CONTEXT.
- **Orchestration-only**: 6 worker/document-reviewer agents (code-fixer,
  regression-verifier, task-implementer, plan-document-reviewer,
  guide-document-reviewer, task-document-reviewer) require structured
  CONTEXT input from a calling skill. Their first description sentence is
  "INTERNAL: ..." and their body has a prerequisite check that refuses on
  missing CONTEXT.

### Maintenance note

The 5 review-angle agents share PREREQUISITES, FILE COVERAGE, and CUSTOM
INSTRUCTIONS sections by convention. When modifying any of these sections in
one agent, apply the same change to the other 4. Duplication is intentional
(each agent is independently readable); silent drift between them is a bug.
```

**Update the existing "Skill Development Conventions" section** to reference `agents/` alongside `skills/`, `commands/`, etc. Remove all references to `prompts/` subdirectories.

**Add a Non-Goals subsection** linking to this v2 plan's Non-Goals, summarizing why `discovery-framework.md` stays in `shared/`.

#### Step 3.3: Update `README.md` (1 commit)

**Update directory tree** (around line 49). Insert `agents/`:
```
plugins/kenspc/
    .claude-plugin/
    agents/               # 11 reusable subagents
    commands/
    hooks/
    references/
    shared/               # Cross-skill resources (e.g., discovery-framework.md)
    skills/
    README.md
```

**Add a new top-level "Agents" section** with a table:

| Agent | Type | Standalone | Description |
|---|---|---|---|
| `requirements-reviewer` | Code reviewer | Yes | Requirements completeness |
| `edge-case-reviewer` | Code reviewer | Yes | Edge cases and error handling |
| `quality-reviewer` | Code reviewer | Yes | Code quality and conventions |
| `bug-reviewer` | Code reviewer | Yes | Bug hunting (skeptical mindset) |
| `test-reviewer` | Code reviewer | Yes | Test coverage and quality |
| `code-fixer` | Worker | No | Applies fixes from review reports |
| `regression-verifier` | Verifier | No | Verifies fixes; read-only by design |
| `task-implementer` | Worker | No | Implements tasks from a task document |
| `plan-document-reviewer` | Doc reviewer | No | Reviews generated plan documents |
| `guide-document-reviewer` | Doc reviewer | No | Reviews generated guide documents |
| `task-document-reviewer` | Doc reviewer | No | Reviews generated task documents |

**Update the "Design Principles" section** to add a bullet about agent reusability.

#### Step 3.4: Update `plugin.json` (1 commit)

Bump version: `1.5.0` → `2.0.0`.

Update description to mention agents:
```json
"description": "Structured development workflows for Claude Code. Eleven reusable subagents power requirement brief generation, plan generation, task decomposition, automated batch implementation with multi-angle review, and project guide generation."
```

#### Step 3.5: Verify command files need no changes (no commit)

Inspect each command file in `commands/`. Verified during planning:
- None reference `prompts/` paths
- All delegate to skills via `Read the skill definition at ${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md`

If implementation reveals any command does mention prompts (unlikely), update it. Otherwise no commit needed.

#### Step 3.6: Add CHANGELOG entry (1 commit)

Create or update `plugins/kenspc/CHANGELOG.md`:
```markdown
## 2.0.0 — 2026-XX-XX

### Breaking changes

- Internal `prompts/` directories removed; subagent definitions migrated to
  `agents/` directory as plugin agents. Plugin-internal change — no impact on
  user-facing skill or command interfaces.

### Added

- 11 reusable subagents in `plugins/kenspc/agents/`, discoverable via `/agents`:
  - 5 code review angle agents (standalone-safe): `requirements-reviewer`,
    `edge-case-reviewer`, `quality-reviewer`, `bug-reviewer`, `test-reviewer`
  - 3 document reviewers (orchestration-only): `plan-document-reviewer`,
    `guide-document-reviewer`, `task-document-reviewer`
  - 3 workers (orchestration-only): `code-fixer`, `regression-verifier`,
    `task-implementer`

### Changed

- All 5 affected SKILL.md files updated to dispatch agents by name with
  structured CONTEXT input (replaces template variable substitution).
- All 5 affected SKILL.md `version` fields bumped to 2.0.0 to align with
  plugin version.
```

## Migration ordering and commit strategy

**Ordering invariant**: Phase 3.1 (delete `prompts/`) must not begin until ALL Phase 2 SKILL.md commits are merged and verified. The state `prompts/ deleted but SKILL still references prompts` must never exist on the working branch.

**Commit granularity**: One commit per agent created (Phase 1: 11 commits — 1 directory + 10 agents... actually 11 because Phase 1.2 produces 5 separate commits, and 1.3-1.8 produce 6 more). One commit per SKILL.md updated (Phase 2: 5 commits). Cleanup and documentation: 5 commits (Phase 3.1-3.4, 3.6). Total: ~21 commits. Reviewable individually, revertible individually.

**Suggested branch**: `refactor/extract-reusable-agents` off main.

## Testing Strategy

### A. Happy path end-to-end (5 tests)

Run each skill end-to-end on a fixture project and confirm behavior matches v1.5.0 baseline:

1. **task-review**: Run `/kenspc-task-review` with recent uncommitted changes. Confirm:
   - 5 review agents dispatch in parallel (single Agent tool call message with 5 sub-calls)
   - Each agent returns a structured report with the same severity/file/line format
   - `code-fixer` receives all 5 reports and produces accountability list
   - `regression-verifier` produces final summary with PASS/FAIL verdict
   - Bilingual messages preserved at every stage

2. **task-implement**: Run `/kenspc-task-implement docs/tasks/fixture-tasks.md`. Confirm:
   - Plan-vs-task validation runs at SKILL level (Phase 1 Step 2)
   - User confirmation step still works (Phase 1 Step 4)
   - `task-implementer` agent's prerequisite check ALSO runs and validates plan-vs-task (defense in depth)
   - Phase 2 (review) follows task-review SKILL's dispatch sequence — does NOT re-parse $ARGUMENTS
   - Final consolidated report includes Implementation, Code Review, Build Status, Verdict

3. **generate-plan**: Run `/kenspc-plan` with a requirement. Confirm:
   - Discovery (Phase 1, main session) still allows multi-round discussion
   - Plan drafting and challenge cycle (Phase 2, main session) still work
   - After file write, `plan-document-reviewer` dispatches
   - Review summary includes per-angle PASSED/FIXED status

4. **generate-guide**: Run `/kenspc-guide ./apps/some-fixture-app`. Confirm:
   - Guide generation reads project context (main session)
   - `guide-document-reviewer` dispatches after writing
   - Review summary presented

5. **generate-task**: Run `/kenspc-task docs/plans/fixture-plan.md`. Confirm:
   - Code analysis and decomposition (main session)
   - User confirmation works
   - `task-document-reviewer` dispatches after writing
   - Plan-Level Concerns section appears if applicable

### B. Standalone safety tests (3 tests)

1. **Standalone-safe agent**: `@kenspc:bug-reviewer` with no CONTEXT.
   Expected: agent outputs the standard "expects a CONTEXT block" message and stops. No code modification, no commits.

2. **Orchestration-only agent (no CONTEXT)**: `@kenspc:code-fixer` with no input.
   Expected: agent's Layer 3 prerequisite check fires. Output: "INTERNAL... Invoke /kenspc-task-review instead." Stop.

3. **Orchestration-only agent (wrong CONTEXT)**: invoke `@kenspc:task-implementer` pointing to a plan document path.
   Expected: agent's prerequisite check Step 3 fires. Output: bilingual "TASK_FILE points to a plan document..." Stop without implementing anything.

### C. Non-trigger (auto-delegation) tests (3 tests)

In a session where a code-review skill or workflow is NOT invoked, type vague phrases and verify agents do NOT auto-fire:

1. "我看到一个 bug, 你帮我看看" → main session investigates directly. `bug-reviewer` does NOT auto-trigger.
2. "Can you review my plan?" → main session asks clarifying question (which plan? in this conversation? a file?). Does NOT auto-trigger `plan-document-reviewer`.
3. "Fix this code" → main session fixes directly via Edit/Write. Does NOT auto-trigger `code-fixer`.

These tests verify the description-gating layer (Layer 1) is doing its job.

### D. Semantic equivalence baseline (1 test)

Before starting Phase 1, capture a baseline:

1. Pick a fixture project with deterministic content (e.g., a small repo with intentional bugs).
2. Run `/kenspc-task-review` against it on v1.5.0 (current main).
3. Save the full output: 5 review reports, accountability list, regression summary, verdict.

After completing Phase 3:

1. Reset the fixture to the same starting state.
2. Run `/kenspc-task-review` again on v2.0.0.
3. Diff the two outputs. Acceptable differences:
   - Commit hashes
   - Agent run timestamps
   - Minor wording variations in non-structured parts
4. Unacceptable differences (any of these = blocker):
   - Different number of issues found per angle
   - Different severity classifications
   - Missing bilingual output
   - Different verdict (PASS vs FAIL)
   - Missing accountability entries

If a semantic difference is found, treat it as a regression. Investigate before merging.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Agent body + dispatch prompt produces different behavior than single rendered template | Low | Both forms give the model the same information. Section D semantic equivalence test catches regressions before merge. |
| Auto-delegation: orchestration-only agents fire when not wanted | Medium | 3-layer defense: description "INTERNAL:" prefix + tool allowlist + body prerequisite check. Section C non-trigger tests verify. |
| Auto-delegation: standalone-safe review agents fire on vague mentions | Medium | Description ties to specific angle and `/kenspc-task-review` workflow. Standalone fallback refuses without CONTEXT. |
| Naming collision with other plugins | Low (now lower) | `*-document-reviewer` for doc reviewers, `*-reviewer` for code review angles, role-noun for workers. All unique enough. Plugin namespace `kenspc:` provides final disambiguation. |
| Standalone invocation of orchestration-only agents misses prerequisite check | Very Low | Layer 3 hard-stops before any tool use. Validated in Section B test 2-3. |
| `task-implementer` invoked standalone with a plan document | Very Low | Plan-vs-task validation embedded in Layer 3 prerequisite check (mitigates v1 H4). |
| Future Claude Code updates change plugin agent loading | Low | Use only documented frontmatter fields. No reliance on undocumented behavior. |
| Token usage increases due to CONTEXT block format | None | CONTEXT block contains the same fields current placeholders contain. Token count unchanged. |
| Mid-migration state breaks the plugin | Low | Ordering invariant: prompts/ never deleted while SKILL references it. Phase 3.1 gated on Phase 2 completion. Each commit independently reverts cleanly. |

## Open Questions (all closed in v2)

1. **Should review agents share a common preamble?** **Resolved: accept duplication.** Each agent is self-contained for readability. CLAUDE.md adds a maintenance note (Step 3.2) requiring synchronized changes across the 5 review-angle agents.

2. **Should orchestration-only agents have a frontmatter field marking them internal?** **Resolved: use 3-layer defense, no new field needed.** Description "INTERNAL:" prefix gates auto-delegation; tool allowlist limits blast radius; body prerequisite check refuses on missing CONTEXT.

3. **task-implement Phase 2 architecture (direct dispatch vs delegate to task-review)?** **Resolved: Option B — delegate to task-review SKILL.** Keeps task-review as the single source of truth for the 7-agent code review process. task-implement Phase 2 explicitly skips task-review's $ARGUMENTS parsing and instead constructs CONTEXT directly.

4. **Backwards-compatibility shim for old `prompts/` paths?** **Resolved: no shim.** v2.0.0 + CHANGELOG only.

5. **Agent naming convention?** **Resolved: kebab-case, no `kenspc-` prefix.** Description gates auto-delegation. `bug-hunter` → `bug-reviewer` for symmetry with the other 4 *-reviewer agents. Document reviewers use `*-document-reviewer` pattern (e.g., `plan-document-reviewer`) for clarity in a multi-plugin world.

6. **SKILL.md version bump strategy?** **Resolved: all bump to 2.0.0** alongside plugin. Avoids version drift between plugin and SKILLs.

7. **Standalone fallback behavior for review agents?** **Resolved: require explicit CONTEXT.** No git-state inference. Standalone invocation without CONTEXT outputs a usage message and stops. Reduces surprise from auto-inferred scopes.

8. **Convert `discovery-framework.md` to an agent?** **Resolved: no — see Non-Goals section.** It is a behavior guide consumed by main session in 3 call sites, not delegated work.

## Reflection: planning methodology

Two methodology corrections during the v2 design (worth recording for future plan revisions):

1. **v1's draft contained statements that were not verified against current code** — the "version 1.4.0 → 2.0.0" claim, the "silently ignored" claim about plugin agent frontmatter. Lesson: every concrete claim in a plan should map to a file path, command output, or doc URL the planner has actually inspected.

2. **The decision to keep `discovery-framework.md` in `shared/` was initially justified by category reasoning ("agent vs shared") rather than by inspection of actual call sites.** Inspecting the 3 call sites strengthened the decision but also revealed nuance the abstract argument missed (Phase 2 needs raw conversation context; brief gap-check is one-shot analytical). Lesson: when deciding whether to refactor a shared resource, read every call site before reasoning about the abstraction.

These lessons inform the explicit Non-Goals section and the per-agent CONTEXT schema (which forces inspection of every prompt's actual inputs rather than assuming a single shape).
