---
name: generate-brief
description: >
  Structured discovery conversation that produces a requirement brief
  (需求摘要). Use when the idea is too vague to plan directly, when you need
  to think through an idea before committing, or when you need a shareable
  document before planning. Not for creating plans — use generate-plan instead.
  Trigger on: "help me think through this", "brief this idea", "I have a rough
  idea", "我想理清楚思路", "先讨论一下", "写个需求摘要", "帮我想想",
  "brain dump", or invokes /kenspc-brief directly.
version: 3.0.0
effort: xhigh
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

Avoid triggering this skill when the user:

- Asks to create a plan → use generate-plan instead.
- Asks to break down tasks → use generate-task instead.
- Asks casually "how should we approach this?" / "我想想怎么做" — just discuss
  directly without invoking a skill.
- Gives clear, structured requirements (acceptance criteria, scope already
  defined) → use generate-plan directly; a brief would be redundant.
- Asks for a quick opinion on architecture or design choices.

## Quality bar

A useful brief surfaces the user's true goal, the failure modes they would
not articulate without prompting, and the hard part where most judgment is
needed. A transcription of what the user said is not a brief.

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

**Goal**: understand the user's true need through structured conversation.

**Inputs**: ROUGH_IDEA from $ARGUMENTS, optional project context (CLAUDE.md,
config files), the discovery framework at
`${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md`.

**DONE when** either:
- The user explicitly signals readiness ("OK", "够了", "let's write the brief",
  "可以了", "go ahead", "write it"); or
- Outcome, Failure Modes, and The Hard Part are sufficiently clear and no
  remaining dimension has an obvious gap. Proactively suggest moving forward,
  but the user can always continue.

**Constraints**:
- No drafts, outlines, or templates during Discovery — drafts anchor the
  conversation prematurely.
- Read project context (CLAUDE.md, README.md, config files, directory listing)
  silently before asking questions when in a project directory.
- Read `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md` and use its five
  dimensions, four input clarity levels, conversation rules, and exit
  conditions as the structural guide.
- Match the user's language (Chinese → Chinese, English → English).
- One question at a time, especially for heavy questions; build on what the
  user said.
- When the user is uncertain, recommend an option with brief pros/cons rather
  than just laying choices out.
- Apply the framework's Level 4 handling for too-broad scope: stop, suggest
  decomposition, ask which module to brief first.

## Phase 2: Produce Brief

**Goal**: write the requirement brief at the right path with the right
structure, then point the user to the next step.

**Inputs**: Discovery transcript and decisions from Phase 1; project's
documentation conventions (CLAUDE.md or `docs/briefs/` default).

**DONE when**:
- The brief is saved at the chosen path and reflects what was actually
  discussed (no invented dimensions).
- The user is told the path and shown the next-step suggestion
  (`/kenspc-plan [path]`).

**Output path resolution** (priority order):
1. CLAUDE.md-specified brief or documentation directory.
2. `docs/briefs/` (create if missing).
3. Ask the user where to save and what to name the file.

**Filename**: kebab-case derived from the brief's title. Examples:
"users miss assignments" → `assignment-notifications.md`,
"new pricing tier for SMB" → `smb-pricing-tier.md`. The `-brief` suffix is
optional; drop it unless the directory contains other document types that
could collide.

**Conflict check**: if a file already exists at the target path, ask the
user: overwrite, create alongside (with a suffix), or cancel.

### Brief template

Skip sections that genuinely don't apply, but add a brief note explaining
why (e.g., "Hidden Context: none — open-source project, no organizational
factors").

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

### Writing rules for the brief

- **Why**: the brief is the input to downstream planning. Specificity now
  prevents the plan from solving the wrong problem.
- Default language: match the user's language during Discovery.
- Be specific and concrete. "Improve performance" is not an Outcome; "API
  p95 under 200ms during checkout" is.
- Do not invent dimensions not actually discussed. If Stakes was inferred
  rather than asked, write what was inferred (e.g., "Inferred from context:
  internal tool, low blast radius if delayed").
- Do not include implementation steps or task lists — those belong in plans
  and task documents.
- Code blocks must specify the language.

## Phase 3: Suggest Next Step

After writing the brief, tell the user:

- The path the brief was saved to.
- The next-step suggestion: "To create a plan from this brief: `/kenspc-plan [path]`".

**Constraint**: do not auto-trigger generate-plan. The user decides whether
to plan now, share the brief for discussion first, or set it aside — the
brief is a discovery artifact, not a planning trigger.
