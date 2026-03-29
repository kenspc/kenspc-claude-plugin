---
name: generate-plan
description: >
  Generate a comprehensive plan document through collaborative discussion,
  self-challenge, and automated ralph-loop verification. Three phases:
  Discover, Plan, Verify.
version: 1.0.0
argument-hint: <requirement or path-to-requirements-file> [custom instructions]
---

# Generate Plan

Create a comprehensive plan document through collaborative discussion, iterative
self-challenge, and automated verification. Three phases: Discover, Plan, Verify.

## Trigger Phrases

Use this skill when the user says: "generate plan", "write a plan", "implementation plan",
"plan this", "help me plan", "draft a plan", "project plan", "technical plan",
"architecture plan", "let's plan", "I need a plan for", "before we start coding",
"写计划书", "规划", "计划一下", "帮我规划", or any request to plan, design, or
strategize before implementation.

## Prerequisites

- The ralph-loop plugin must be installed for Phase 3 (Verify)
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
   b. If a `docs/plans/` directory exists, use it
   c. Otherwise, ask the user where to save and what to name the file
2. If a file already exists at the target path, ask the user whether to overwrite
   or create a new file
3. Determine document language:
   a. If the user specified a language, use it
   b. Otherwise, default to English
4. Write the plan to the file

After writing, proceed to Phase 3.

## Phase 3: Verify via ralph-loop

Automatically launch a review cycle after the plan is written. Do not wait for
user instruction.

Skip this phase entirely if:
- The ralph-loop plugin is not installed
- The plan was not written to a file (discussion-only mode)

### Step 1: Read the prompt template

Read the file prompts/review.md from this skill's directory.

### Step 2: Render the prompt

Replace all placeholders in the template:
- {{PLAN_PATH}} — the actual path of the plan file that was just written
- {{PROJECT_PATH}} — the project root path, or "N/A" if not in a project

### Step 3: Write the ralph-loop state file

Create the directory .claude/ if it does not exist. Then write the file
.claude/ralph-loop.local.md with the following structure:

```
---
active: true
iteration: 0
max_iterations: 6
completion_promise: PLAN_REVIEW_COMPLETE
---
(rendered prompt content here)
```

The YAML frontmatter goes between the --- markers. The rendered prompt goes after the
closing --- with no blank line.

### Step 4: Confirm and begin

Tell the user:
"Plan written to [path]. Starting automated review now."

Then immediately begin working on the review prompt. When you attempt to exit after
completing a unit of work, the ralph-loop stop hook will intercept and re-feed the
prompt automatically.

### After Review Completes

Inform the user:
- Which review angles passed cleanly
- What was fixed during review (summarize changes)
- Any issues recorded as open questions or known gaps

### Cancellation

The user can cancel the review with: /ralph-loop:cancel-ralph
