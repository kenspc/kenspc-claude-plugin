---
name: generate-plan
description: >
  Generate a comprehensive plan document (计划书/計劃書) from requirements,
  backlog items, or specs. Adapts to project-specific templates. Includes
  collaborative discussion, self-challenge, and automated verification via
  review agent. Three phases: Discover, Plan, Verify.
  Trigger on: "write a plan", "generate plan", "写计划书", "编写计划",
  "帮我规划", "计划一下", or writing plan files to docs/plans/.
version: 1.2.0
argument-hint: <requirement or path-to-requirements-file> [custom instructions]
---

# Generate Plan

Create a comprehensive plan document through collaborative discussion, iterative
self-challenge, and automated verification. Three phases: Discover, Plan, Verify.

## Trigger Phrases

Use this skill when the user explicitly asks to **create a plan document**, using phrases
like: "generate plan", "write a plan", "implementation plan", "plan this", "help me plan",
"draft a plan", "project plan", "technical plan", "architecture plan", "let's plan",
"I need a plan for", "before we start coding", "写计划书", "编写计划", "计画书",
"规划", "计划一下", "帮我规划", "帮我写计划",
or invokes `/kenspc-plan` directly.

**Do NOT trigger this skill** when the user:
- Asks to break down a plan into tasks or decompose tasks (use generate-task instead)
- Asks casually about approach (e.g., "what's the best way to...", "我想想怎么做",
  "how should we approach this?") — just discuss directly
- Wants a quick opinion on architecture or design choices
- Is already in the middle of implementation and asks about next steps

## Common Rationalizations

| Agent says | Why it's wrong |
|---|---|
| "需求很清楚，跳过 Discovery" | Even seemingly complete requirements need at least 2-3 clarifying questions. Plans without Discovery miss non-functional requirements and boundary conditions. |
| "Plan 太短不需要 review" | Plan length does not determine review necessity. A 10-line wrong plan causes more damage than a 100-line correct plan. Phase 3 cannot be skipped. |
| "用户说快点，跳过 self-challenge" | An unchallenged plan is wishful thinking. Phase 2's challenge step is quality assurance, not wasted time. |
| "Planning is overhead, 直接开始写代码" | Planning IS the task. Implementation without a plan is just typing. 10 minutes of planning saves hours of rework. |

## Red Flags

Stop and inform the user if any of these occur (thresholds are starting values — adjust based on project experience):

- Discovery continues beyond ~8 rounds with the user still changing core scope → Scope is fundamentally undefined. Stop and suggest the user write a brief scope statement before continuing.
- Self-challenge reveals a fundamental flaw in the core technical approach → Do not patch the plan. Return to Discovery to re-discuss the technical approach.
- Review agent reports 3+ HIGH issues in Angle 1 (Feasibility) → The plan may not be executable. Inform the user and suggest rewriting rather than patching.

## Prerequisites

- If verifying against a project, the project should have actual code or config files

## Arguments

$ARGUMENTS format: REQUIREMENT [CUSTOM_INSTRUCTIONS]

- REQUIREMENT: free-text description of what needs to be planned, OR a file path to a
  requirements document (e.g., ./docs/requirements.md, PRD.md)
- CUSTOM_INSTRUCTIONS: optional additional constraints or preferences

If no arguments are provided, ask the user what they want to plan.

If the first token looks like a file path (starts with ./ or / or ends with .md/.txt),
read that file and use its contents as the initial requirement.

## Phase 1: Discover

Goal: Understand what the user wants to build/do, reach consensus on scope and approach.

### Read Project Context (if in a project directory)

Before asking questions, silently gather context:
- Read CLAUDE.md (project and root level) for conventions, tech stack, constraints
- Read README.md, package.json, *.csproj, docker-compose.yml, .env.example,
  app.json, eas.json, or any config files that reveal the stack
- Scan the project structure (directory listing)
- Note the tech stack, existing patterns, and constraints

If not in a project directory, skip this step entirely.

### Engage in Discussion

This phase is principle-driven, not step-driven. Claude must:

1. ULTRATHINK to analyze the requirement before responding
2. Ask focused questions to clarify what is unclear — scope, constraints, priorities,
   non-functional requirements, edge cases, target audience
3. Provide suggestions, alternatives, and trade-offs for the user to consider
4. Do NOT ask too many questions at once — 2-4 per round is ideal
5. Do NOT make assumptions on technical decisions — ask when unsure
6. Do NOT attempt to write or outline the plan yet — this phase is pure discussion
7. Adapt the depth and direction of questions based on the type of plan
   (implementation, architecture, migration, evaluation, etc.)
8. Match Discovery depth to input clarity. A vague idea ("我想加个通知系统")
   needs 3-5 rounds; a structured requirement with acceptance criteria may need
   only 1 round of gap-filling. Never proceed to Phase 2 with unresolved scope
   ambiguity.

Continue this discussion until the user signals readiness to move forward
(e.g., "OK", "let's write the plan", "可以了", "enough discussion", "go ahead").

## Phase 2: Plan

Goal: Draft the plan, present it for challenge, revise until approved, then write to file.

### Step 1: Draft

ULTRATHINK to synthesize everything from Phase 1 — the requirements, discussion outcomes,
project context (if any), and constraints. Then generate a plan document.

The plan format is flexible and must adapt to the type of plan. However, always consider
whether these elements are relevant (include only what applies):

- **Objective** — What this plan aims to achieve, and explicit scope boundaries
- **Background / Context** — Why this plan exists, what problem it solves
- **Technical Approach** — Architecture, tech stack choices, key design decisions
  with rationale
- **Implementation Steps** — Ordered phases or steps, with dependencies between them
  clearly stated. Each step should have:
  - What to do (concrete, not vague)
  - Expected input and output
  - Acceptance criteria (how to know the step is done)
- **Data Model / API Design** — If applicable
- **Testing Strategy** — If applicable
- **Deployment Strategy** — If applicable
- **Risks and Mitigations** — Known risks with concrete mitigation plans
- **Open Questions** — Anything unresolved that needs future decision

### Writing Rules for the Plan

- Default language: English (unless the user explicitly requests otherwise)
- Be specific and actionable. Every step must be concrete enough for a developer
  (or Claude Code) to execute without guessing intent
- Avoid vague language: never use "as appropriate", "if needed", "consider doing",
  "optionally", or "as necessary" without specifying the condition. If something is
  conditional, state the exact condition
- Include rationale for significant decisions — the "why" matters as much as the "what"
- If the plan references specific libraries, tools, or versions, be explicit
- Do not invent requirements the user did not ask for

### Step 2: Present and Challenge

Present the draft plan in conversation. Do NOT write it to a file yet.

When the user asks to ULTRATHINK or review or challenge the plan:
- Genuinely critique the plan — do not be self-congratulatory
- Look for logical gaps, unstated assumptions, ordering mistakes, missing edge cases
- Question whether each technical choice is the best option or just the first one
  that came to mind
- Check if the plan is actually executable as written
- Propose specific improvements, not vague concerns

This draft-challenge cycle may repeat multiple times. Revise the plan based on each
round of feedback and self-critique.

### Step 3: Write to File

ONLY when the user explicitly approves the plan (e.g., "write it", "save it",
"looks good, write it out", "写出来", "OK output it"):

1. Determine output location:
   a. If CLAUDE.md specifies a documentation or plans directory, use it
   b. Otherwise, use `docs/plans/` (create if it does not exist)
   c. If a file already exists at the target path, ask the user whether to
      overwrite or create a new file
2. Determine document language:
   a. If the user specified a language, use it
   b. Otherwise, default to English
3. Write the plan to the file

After writing, proceed to Phase 3.

## Phase 3: Verify via review agent

Automatically launch a review cycle after the plan is written. Do not wait for
user instruction.

Skip this phase entirely if the plan was not written to a file (discussion-only mode).

### Step 1: Read the prompt template

Read the file prompts/review.md from this skill's directory.

### Step 2: Render the prompt

Replace all placeholders in the template:
- {{PLAN_PATH}} — the actual path of the plan file that was just written
- {{PROJECT_PATH}} — the project root path, or "N/A" if not in a project

### Prompt variables

| Variable | Source | Values |
|----------|--------|---------|
| {{PLAN_PATH}} | Phase 2 Step 3 | Path of the written plan file |
| {{PROJECT_PATH}} | Project root | Path or "N/A" |

### Step 3: Dispatch the review agent

Tell the user:
"Plan written to [path]. Dispatching review agent now. / 计划书已写入 [path]。正在启动审查代理。"

Then dispatch a subagent using the Agent tool:
- prompt: the rendered review prompt from Step 2
- description: "Review plan document"

Do NOT write any state file. The subagent will execute the entire review
(all four angles, in order) within its own context and return the summary.

### Step 4: Present results

When the subagent returns, present its summary to the user. The summary includes:
- Which review angles passed cleanly
- Every change that was made, with the reason for each change (and associated git commits)
- Any unresolved issues that could not be fixed
- Any concerns noted in Open Questions
