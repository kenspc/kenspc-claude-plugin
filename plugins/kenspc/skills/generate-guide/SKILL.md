---
name: generate-guide
description: >
  Generate a beginner-friendly project setup and deployment guide (项目指南/
  部署文档/新人文档) for a project or monorepo sub-app. Reads the actual
  codebase to produce accurate setup steps, then self-reviews against the
  code via review agent. Trigger on: "write a guide", "setup doc",
  "deployment guide", "onboarding doc", "写文档", "项目指南", "部署文档",
  "写个文档给新人看".
version: 3.0.0
effort: high
argument-hint: <project-path> [custom instructions]
---

# Generate Project Guide

Create a comprehensive, beginner-friendly guide for a project or sub-project,
then self-review it for accuracy. Two phases: generate, then review via
review agent.

## Trigger Phrases

Use this skill when the user explicitly asks to **create a guide document**,
using phrases like: "generate guide", "write setup doc", "write guide",
"setup instructions", "项目指南", "写文档指引", "写个文档", "部署指南",
or invokes `/kenspc-guide` directly.

Avoid triggering this skill when the user:
- Asks a quick question about setup or deployment (e.g., "how do I deploy
  this?", "怎么部署？") — just answer directly.
- Wants to discuss or troubleshoot a specific configuration issue.
- References documentation without asking to generate a new one.

## Quality bar

A useful guide is independently complete (does not assume an existing
README is correct), grounded in actual code (every command and path is
verified, not inferred), and audience-aware (a developer new to this
project can follow it end-to-end without external help).

## Prerequisites

- A project with actual code to document.

## Arguments

$ARGUMENTS format: PROJECT_PATH [CUSTOM_INSTRUCTIONS]

- PROJECT_PATH: first token, relative or absolute path to the target
  project/sub-project (e.g., `/apps/mobile`, `apps/api`, `.` for current
  directory).
- CUSTOM_INSTRUCTIONS: everything after the path, optional free-text that
  supplements the standard guide sections (e.g., "include AxaiPay webhook
  testing" or "focus on EAS build").

If no arguments are provided, ask the user which project path to target.

## Phase 1: Generate the Guide

**Goal**: produce an accurate, beginner-friendly guide for the target
project, grounded in actual code.

**Inputs**: PROJECT_PATH; CUSTOM_INSTRUCTIONS; project's CLAUDE.md (project
+ root), README, config files (package.json, *.csproj, docker-compose.yml,
.env.example, app.json, eas.json, etc.); directory listing.

**DONE when**:
- Output path and filename are resolved (priority: CLAUDE.md convention →
  existing guide file with overwrite-or-new prompt → ask the user).
- Document language is set (user-specified → English default).
- Any unclear setup gaps have been raised with the user (deployment target,
  required accounts/credentials not in config, unscripted database setup).
- The guide is written at the resolved path with all applicable sections
  (see template below); skipped sections include a brief reason.

**Constraints**:
- **Why grounded reading matters**: inference is not verification. Every
  command, path, environment variable, and version requirement must be
  traceable to a config file, source file, or explicit user confirmation.
- All commands must specify the working directory.
- Include expected output or success indicators for each step.
- Use relative paths from the project root.
- Every config value, secret, or environment variable must explain where
  to obtain it.
- Code blocks must specify the language (bash, json, etc.).
- Do not invent steps. If something is missing (e.g., no seed script),
  note it as a gap.
- CUSTOM_INSTRUCTIONS should be woven into relevant sections, not appended
  as a separate section.
- Audience: a developer new to this project — possibly a junior developer
  or someone unfamiliar with the tech stack. Explain what to do and why
  each step matters; define project-specific jargon on first use; when a
  step could go wrong, mention what the error looks like and how to fix it.

### Section template

Skip sections that don't apply, with a brief reason. Section ordering
should reflect actual dependencies (e.g., prerequisites before setup,
setup before workflow).

Section 1 - Project Overview:
- What this project does (one paragraph).
- Tech stack summary (framework, language, database, key libraries).
- Project structure overview (key folders and their purposes).

Section 2 - Prerequisites:
- Required software and exact versions (runtime, SDK, CLI tools, package
  managers).
- Required accounts or access (cloud services, API keys, third-party
  services).
- Required IDE extensions (if applicable).
- OS-specific notes (Windows / macOS / Linux differences, if any).

Section 3 - Local Development Setup:
- Step-by-step from fresh clone to running locally.
- Environment variables setup with each variable explained and where to
  get its value.
- Database setup (create, migrate, seed with exact commands).
- How to verify the setup is working (expected output or success
  indicators).

Section 4 - Development Workflow:
- How to run the project locally (dev server, watch mode, etc.).
- How to run tests (unit, integration, e2e, whatever exists).
- How to debug (IDE config, breakpoints, logs).
- Key commands cheat sheet (build, test, lint, format, etc.).
- Common development scenarios and troubleshooting tips.

Section 5 - Build and Release (if applicable):
- Build commands and output.
- For mobile apps: include platform-specific build steps (e.g., EAS Build,
  Xcode, Android Studio).
- For web apps: production build and preview steps.
- Versioning or release process (if defined in project).

Section 6 - Deployment:
- Target environment and infrastructure (as found in CLAUDE.md or project
  config).
- Deployment steps (manual or CI/CD pipeline).
- Environment-specific configuration (staging vs production).
- Post-deployment verification steps.
- Rollback procedure (if documented).

Section 7 - Troubleshooting and FAQ:
- Common issues encountered during development (based on project config
  and dependencies).
- Platform-specific gotchas.
- Links to relevant documentation.

## Phase 2: Self-Review via review agent

**Goal**: run the guide through `guide-document-reviewer` and present the
consolidated review summary.

**Inputs**: path of the guide just written; PROJECT_PATH.

### Step 1: Render Planned Dispatch table

Before invoking the review agent, render this table so the user sees the
planned dispatch:

| # | Agent | Status |
|---|-------|--------|
| 1 | guide-document-reviewer | pending |

### Step 2: Construct CONTEXT block and dispatch

Build the structured CONTEXT block:

```
CONTEXT
- GUIDE_PATH: <actual path of the guide file that was just written>
- PROJECT_PATH: <target project path from $ARGUMENTS>
```

Tell the user: "Guide written to [path]. Dispatching review agent now."

Then dispatch a subagent using the Agent tool:
- Agent name: `guide-document-reviewer`
- description: "Review guide document"
- prompt: the CONTEXT block above

The subagent will execute the entire review (all four angles, in order)
within its own context and return the summary. Do not write any state
file.

### Step 3: Render the result table (Schema E) and present the summary

When the subagent returns, render the result table verbatim from the
agent's output — Schema E:

| Angle | Status     | Changes       | Commit  |
|-------|------------|---------------|---------|
| 1     | PASSED     | —             | —       |
| 2     | FIXED (n)  | section X, Y  | def5678 |
| 3     | NOTED      | open question | ghi9012 |
| 4     | PASSED     | —             | —       |

Below the table, present:
- The Changes prose (per FIXED / NOTED row: what changed, why, commit hash).
- Any known gaps that could not be resolved.
