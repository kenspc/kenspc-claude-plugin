---
name: generate-brief
description: >
  Structured discovery conversation that produces a requirement brief
  (需求摘要). Use when the idea is too vague to plan directly, when you need
  to think through an idea before committing, or when you need a shareable
  document before planning. NOT for creating plans — use generate-plan instead.
  Trigger on: "help me think through this", "brief this idea", "I have a rough
  idea", "我想理清楚思路", "先讨论一下", "写个需求摘要", "帮我想想",
  "brain dump", or invokes /kenspc-brief directly.
version: 1.0.0
argument-hint: <rough idea or topic>
---

# Generate Requirement Brief

Run a structured discovery conversation around a rough idea, then produce a
shareable requirement brief. Two phases: Discover, Produce Brief. No review
phase — the brief is a discovery artifact, not a verifiable spec. Review
happens downstream when generate-plan turns the brief into a plan.

## Trigger Phrases

Use this skill when the user explicitly asks to **think through an idea** or
**produce a requirement brief**, using phrases like: "help me think through
this", "brief this idea", "I have a rough idea", "let's discuss before planning",
"brain dump", "write a requirement brief", "我想理清楚思路", "先讨论一下",
"写个需求摘要", "帮我想想", "理一理这个需求",
or invokes `/kenspc-brief` directly.

**Do NOT trigger this skill** when the user:

- Asks to create a plan → use generate-plan instead
- Asks to break down tasks → use generate-task instead
- Asks casually "how should we approach this?" / "我想想怎么做" — just discuss
  directly without invoking a skill
- Gives clear, structured requirements (acceptance criteria, scope already
  defined) → use generate-plan directly; a brief would be redundant
- Asks for a quick opinion on architecture or design choices

## Common Rationalizations

| Agent says | Why it's wrong |
|---|---|
| "想法很简单，跳过 Discovery 直接写 brief" | A brief without Discovery is just transcription. The whole value is the conversation that surfaces Failure Modes and The Hard Part. Skip Discovery and you might as well not write the brief. |
| "用户已经说了想要什么，写出来就行" | The user described a task, not the outcome. Always push one level up to the true goal before writing. The brief's Outcome section determines whether downstream planning solves the right problem. |
| "Discovery 太久了，先写一版 draft 给用户看" | Drafting during Discovery violates the framework's "do NOT produce output during Discovery" rule. Drafts anchor the conversation prematurely. Finish Discovery first. |
| "Brief 写完顺便帮用户写 plan" | This skill produces a brief and stops. Auto-triggering generate-plan removes the user's decision point. The user must explicitly invoke `/kenspc-plan` next. |
| "需求很大，写一个大 brief 涵盖全部" | A brief covering multiple independent systems is unusable for planning. Per the framework's Level 4 rule, suggest decomposition and write one brief per module. |

## Red Flags

Stop and inform the user if any of these occur (thresholds are starting values — adjust based on project experience):

- Discovery passes ~10 rounds with the user still changing the Outcome → The idea is fundamentally unsettled. Suggest the user step away and return when the goal is clearer; or offer to write a "exploration brief" listing the open questions instead of pretending to have answers.
- The user keeps asking "what would you write?" during Discovery → They want the artifact, not the conversation. Inform them that a brief without Discovery is a template; either commit to the conversation or skip directly to generate-plan with what they have.
- After Discovery, two of the five dimensions still have no answer (e.g., no clear Failure Modes AND no Hidden Context) → The brief will not be useful for planning. Ask the user whether to (a) extend Discovery, (b) write the brief with explicit "unresolved" markers, or (c) abandon and revisit later.

## Prerequisites

None. The skill works with no project context (pure idea) or with a project
directory (uses CLAUDE.md and config to inform Hidden Context).

## Arguments

$ARGUMENTS format: ROUGH_IDEA

- ROUGH_IDEA: free-text description of the idea, problem, or topic to think
  through. Can be a single sentence ("我想加个通知系统"), a paragraph, or
  even a single noun phrase ("notification system").

If no arguments are provided, ask the user what idea they want to think through.

## Phase 1: Discover

Goal: Understand the user's true need through structured conversation. No
output is written during this phase.

### Step 1: Read Project Context (if in a project directory)

Before asking questions, silently gather context:
- Read CLAUDE.md (project and root level) for conventions, tech stack, constraints
- Read README.md, package.json, *.csproj, docker-compose.yml, .env.example,
  app.json, eas.json, or any config files that reveal the stack
- Scan the project structure (directory listing)
- Note the tech stack, existing patterns, and constraints

If not in a project directory, skip this step entirely.

### Step 2: Read Discovery Framework

Read the discovery framework at `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md`
and use it as the structural guide for the following conversation. The framework
defines the five dimensions to check, the four input clarity levels, conversation
rules, and exit conditions.

### Step 3: Engage in Discovery

Follow the discovery framework. Specifically:

1. ULTRATHINK to assess input clarity (Level 1-4) before the first response
2. Use the framework's five dimensions (Outcome, Failure Modes, The Hard Part,
   Hidden Context, Stakes) as the internal checklist
3. Prefer one question at a time, especially for heavy questions
4. Build on what the user said — reference their words
5. When the user is uncertain, recommend an option with brief pros/cons rather
   than just laying choices out
6. Match the user's language (Chinese → Chinese, English → English)
7. Do NOT draft the brief during Discovery — no outlines, no templates, no
   "let me show you what I'd write"
8. Apply the framework's Level 4 handling for too-broad scope: stop, suggest
   decomposition, ask which module to brief first

### Step 4: Recognize Exit

Exit Discovery when **either** holds (per framework Step 4):

- The user explicitly signals readiness: "OK", "够了", "let's write the brief",
  "可以了", "go ahead", "write it"
- Claude judges that **Outcome, Failure Modes, and The Hard Part** are
  sufficiently clear AND no remaining dimension has an obvious gap. In this
  case, proactively suggest: "我觉得方向够清楚了，可以写 brief 了。还有什么需要讨论的吗？ /
  Direction looks clear enough. Ready to write the brief, or anything else
  to discuss?"

## Phase 2: Produce Brief

When Discovery is complete, write the requirement brief.

### Step 1: Determine Output Location

Output path priority:
1. If CLAUDE.md specifies a brief or documentation directory, use it
2. Otherwise, use `docs/briefs/` (create if it does not exist)
3. If neither applies, ask the user where to save and what to name the file

### Step 2: Determine Filename

Derive a kebab-case filename from the brief's title (the Outcome's main subject).
Examples: "users miss assignments" → `assignment-notifications.md`,
"new pricing tier for SMB" → `smb-pricing-tier.md`.

Suffix `-brief` is optional — drop it unless the directory contains other document
types that could collide.

### Step 3: Conflict Check

If a file already exists at the target path, ask the user: overwrite, create
alongside (with a suffix), or cancel.

### Step 4: Write the Brief

Use this template. Skip sections that genuinely don't apply, but add a brief
note explaining why (e.g., "Hidden Context: none — open-source project, no
organizational factors").

```markdown
# Requirement Brief: [Title]

## Outcome
[One sentence describing the true goal — not the task. What changes for users
or the team if this succeeds?]

## Scope
**In scope:** [What this work covers]
**Out of scope:** [What this work explicitly does not cover]
**Deferred:** [Things considered but pushed to a later iteration]

## Failure Modes
[What result would make the user say "no, that's wrong" even if technically
working. These become scope boundaries and risk items downstream.]

## The Hard Part
[Where the most judgment is needed + the preferred approach and why. If
multiple candidates were discussed, briefly note the rejected options and
why.]

## Constraints
[Technical (stack, performance, integrations), organizational (team capacity,
review processes), timeline (deadlines, dependencies on other work).]

## Context
[Hidden knowledge surfaced during Discovery: prior decisions, organizational
norms, historical attempts, team preferences. Skip if everything was already
in project files.]

## Discovery Notes
[Key trade-off discussions and decisions from the conversation. Bullet form is
fine. This is the audit trail of *why* the brief looks the way it does.]
```

### Writing Rules for the Brief

- Default language: match the user's language during Discovery
- Be specific and concrete. "Improve performance" is not an Outcome; "API p95
  under 200ms during checkout" is
- Do not invent dimensions not actually discussed. If Stakes was inferred
  rather than asked, write what was inferred (e.g., "Inferred from context:
  internal tool, low blast radius if delayed")
- Do not include implementation steps or task lists — those belong in plans
  and task documents
- Code blocks must specify the language

## Phase 3: Suggest Next Step

After writing the brief:

1. Tell the user:
   "Brief saved to [path]. / 需求摘要已保存到 [path]。"

2. Suggest the natural next step:
   "To create a plan from this brief: `/kenspc-plan [path]`"

3. Do NOT auto-trigger generate-plan. The user decides whether to plan now,
   share the brief for discussion first, or set it aside.
