---
name: generate-plan
description: >
  Generate a comprehensive plan document (计划书/計劃書) from requirements,
  backlog items, or specs. Adapts to project-specific templates. Includes
  collaborative discussion, self-challenge, and automated verification via
  review agent. Three phases: Discover, Plan, Verify.
  Trigger on: "write a plan", "generate plan", "写计划书", "编写计划",
  "帮我规划", "计划一下", or writing plan files to docs/plans/.
version: 3.0.0
effort: max
argument-hint: <requirement or path-to-requirements-file> [custom instructions]
---

# Generate Plan

Create a comprehensive plan document through collaborative discussion, iterative
self-challenge, and automated verification. Three phases: Discover, Plan, Verify.

## Trigger Phrases

Use this skill when the user explicitly asks to **create a plan document**,
using phrases like: "generate plan", "write a plan", "implementation plan",
"plan this", "help me plan", "draft a plan", "project plan", "technical plan",
"architecture plan", "let's plan", "I need a plan for", "before we start
coding", "写计划书", "编写计划", "计画书", "规划", "计划一下", "帮我规划",
"帮我写计划", or invokes `/kenspc-plan` directly.

Avoid triggering this skill when the user:
- Asks to break down a plan into tasks or decompose tasks (use generate-task
  instead).
- Asks casually about approach (e.g., "what's the best way to...",
  "我想想怎么做", "how should we approach this?") — just discuss directly.
- Wants a quick opinion on architecture or design choices.
- Is already in the middle of implementation and asks about next steps.

## Quality bar

A useful plan has a clear, bounded objective; states the technical approach
with rationale rather than asserting choices; gives every Implementation Step
a concrete acceptance criterion (no vague language like "as appropriate", "if
needed", "properly"); and surfaces unresolved questions instead of papering
over them. The Phase 2 self-challenge exists because an unchallenged plan is
wishful thinking — drafts should be revised, not just written.

## Prerequisites

- If verifying against a project, the project should have actual code or
  config files.

## Arguments

$ARGUMENTS format: REQUIREMENT [CUSTOM_INSTRUCTIONS]

- REQUIREMENT: free-text description of what needs to be planned, OR a file
  path to a requirements document (e.g., `./docs/requirements.md`, `PRD.md`).
- CUSTOM_INSTRUCTIONS: optional additional constraints or preferences.

If no arguments are provided, ask the user what they want to plan.

If the first token looks like a file path (starts with `./` or `/` or ends
with `.md` / `.txt`), read that file and use its contents as the initial
requirement.

## Phase 1: Discover

**Goal**: understand what the user wants to build, reach consensus on scope
and approach, and surface the dimensions a plan needs before drafting starts.

**Inputs**: REQUIREMENT (free-text or file path); the project's CLAUDE.md,
README, and config files when running inside a project; the discovery
framework at `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md`.

**DONE when** **either** holds:

- The user explicitly signals readiness ("OK", "let's write the plan",
  "可以了", "go ahead", "enough discussion").
- Outcome, Failure Modes, and The Hard Part are sufficiently clear AND no
  remaining dimension has an obvious gap. In this case, proactively suggest
  drafting and let the user continue if they want more discussion.

### Step 1: Detect brief document (if input is a file path)

If the requirement was loaded from a file path, determine whether the file is
a Discovery brief produced by the generate-brief skill:

- The file starts with `# Requirement Brief:`, OR
- The file contains the structured sections Outcome, Scope, Failure Modes,
  The Hard Part, Context.

If it is a brief:
- Gap-check the brief against the five dimensions in the discovery framework
  (loaded in Step 3).
- If gaps exist, ask only about the gaps (one to two rounds maximum), then
  proceed to Phase 2.
- If no gaps, tell the user the brief covers all key dimensions and proceed
  directly to Phase 2 — Step 4 is skipped.

If it is not a brief, continue with the normal Discovery flow.

### Step 2: Read project context (if in a project directory)

Before asking questions, silently gather context:
- Read CLAUDE.md (project and root level) for conventions, tech stack,
  constraints.
- Read README.md, package.json, *.csproj, docker-compose.yml, .env.example,
  app.json, eas.json, or any config files that reveal the stack.
- Scan the project structure (directory listing).
- Note the tech stack, existing patterns, and constraints.

If not in a project directory, skip this step entirely.

### Step 3: Read the discovery framework

Read the discovery framework at
`${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md` and use it as the
structural guide for the discussion. The framework defines the five
dimensions to check, the four input clarity levels, conversation rules, and
exit conditions.

### Step 4: Engage in discussion

This phase is principle-driven, not step-driven. Follow the discovery
framework loaded in Step 3:

- Use the framework's five dimensions (Outcome, Failure Modes, The Hard
  Part, Hidden Context, Stakes) as the internal checklist for what to ask.
  The framework's `How to ask` column shows representative phrasings.
- Provide suggestions, alternatives, and trade-offs for the user to consider
  — when the user is uncertain, recommend rather than just laying out
  options.
- Avoid asking too many questions at once. Two to four per round is the
  upper bound; one at a time is preferred for heavy questions (per framework
  Step 3).
- Avoid making assumptions on technical decisions — ask when unsure.
- Do not attempt to write or outline the plan yet — this phase is pure
  discussion.
- Adapt the depth and direction of questions based on the type of plan
  (implementation, architecture, migration, evaluation, etc.).
- Match Discovery depth to input clarity per the framework's four levels:
  Level 1 → 1-2 rounds, Level 2 → 3-5 rounds, Level 3 → no limit, Level 4
  → trigger decomposition (see below).

**Level 4 handling — too broad scope**: if the requirement spans multiple
independent systems (e.g., "rebuild the entire backend" covering multiple
services, schemas, and infrastructure), do not attempt a single plan. Stop
the discussion, suggest decomposition, help identify natural module
boundaries, then ask which module the user wants to plan first. Why: a
single plan that spans independent modules cannot satisfy DONE criteria for
any of them.

## Phase 2: Plan

**Goal**: draft the plan, expose its weakest assumptions through self-
challenge, revise until the user approves, then write to file.

**Inputs**: Phase 1 outputs (requirements, discussion outcomes, project
context if any, constraints).

**DONE when**:
- The user explicitly approves the plan (e.g., "write it", "save it",
  "looks good, write it out", "写出来", "OK output it").
- The plan is written to the resolved output path.

### Step 1: Draft

Synthesize everything from Phase 1 — the requirements, discussion outcomes,
project context (if any), and constraints. Then generate a plan document.

The plan format is flexible and must adapt to the type of plan. Always
consider whether these elements are relevant (include only what applies):

- **Objective** — what this plan aims to achieve, and explicit scope
  boundaries.
- **Background / Context** — why this plan exists, what problem it solves.
- **Technical Approach** — architecture, tech stack choices, key design
  decisions with rationale.
- **Implementation Steps** — ordered phases or steps, with dependencies
  between them clearly stated. Each step should have:
  - what to do (concrete, not vague),
  - expected input and output,
  - acceptance criteria (how to know the step is done).
- **Data Model / API Design** — if applicable.
- **Testing Strategy** — if applicable.
- **Deployment Strategy** — if applicable.
- **Risks and Mitigations** — known risks with concrete mitigation plans.
- **Open Questions** — anything unresolved that needs future decision.

#### Writing rules for the plan

- Default language: English (unless the user explicitly requests otherwise).
- Be specific and actionable. Every step must be concrete enough for a
  developer (or Claude Code) to execute without guessing intent.
- Avoid vague language: do not use "as appropriate", "if needed", "consider
  doing", "optionally", or "as necessary" without specifying the condition.
  If something is conditional, state the exact condition.
- Include rationale for significant decisions — the "why" matters as much as
  the "what".
- If the plan references specific libraries, tools, or versions, be explicit.
- Do not invent requirements the user did not ask for.

### Step 2: Self-challenge the draft

**Goal**: expose the weakest assumption in the draft so revisions are
grounded, not cosmetic.

**DONE when** the draft is accepted by the user OR the revised draft
addresses every challenge raised so far.

**Constraints**:
- No fix without rationale. Each revision states what changed and why,
  including which assumption it now reflects.
- Critique genuinely. Look for logical gaps, unstated assumptions, ordering
  mistakes, missing edge cases. Question whether each technical choice is
  the best option or just the first one that came to mind. Check whether the
  plan is actually executable as written. Propose specific improvements, not
  vague concerns.
- Present the draft in conversation. Do not write it to a file yet.

This draft-challenge cycle may repeat multiple times. Revise the plan based
on each round of feedback and self-critique.

### Step 3: Write to file

Write only when the user explicitly approves the plan. On approval:

1. Determine the output location:
   a. If CLAUDE.md specifies a documentation or plans directory, use it.
   b. Otherwise, use `docs/plans/` (create if it does not exist).
   c. If a file already exists at the target path, ask the user whether to
      overwrite or create a new file.
2. Determine the document language:
   a. If the user specified a language, use it.
   b. Otherwise, default to English.
3. Write the plan to the file.

After writing, proceed to Phase 3.

## Phase 3: Verify via review agent

**Goal**: run the plan document through `plan-document-reviewer` and present
the consolidated review summary.

**Inputs**: path of the plan file just written; project root path (or "N/A"
if not in a project).

Skip this phase entirely if the plan was not written to a file (discussion-
only mode).

### Step 1: Render Planned Dispatch table

Before invoking the review agent, render this table so the user sees the
planned dispatch:

| # | Agent | Status |
|---|-------|--------|
| 1 | plan-document-reviewer | pending |

### Step 2: Construct CONTEXT block and dispatch

Build the structured CONTEXT block:

```
CONTEXT
- PLAN_PATH: <actual path of the plan file that was just written>
- PROJECT_PATH: <project root path, or "N/A" if not in a project>
```

Tell the user: "Plan written to [path]. Dispatching review agent now."

Then dispatch a subagent using the Agent tool:
- Agent name: `plan-document-reviewer`
- description: "Review plan document"
- prompt: the CONTEXT block above

The subagent executes the entire review (all four angles, in order) within
its own context and returns the summary. No state file is written by the
orchestrator.

### Step 3: Render the result table (Schema E) and present the summary

When the subagent returns, render the result table verbatim from the agent's
output — Schema E:

| Angle | Status     | Changes       | Commit  |
|-------|------------|---------------|---------|
| 1     | PASSED     | —             | —       |
| 2     | FIXED (n)  | section X, Y  | def5678 |
| 3     | NOTED      | open question | ghi9012 |
| 4     | PASSED     | —             | —       |

Below the table, present:
- The Changes prose (per FIXED / NOTED row: what changed, why, commit hash).
- Any unresolved issues that could not be fixed.
- Any concerns noted in Open Questions.
