---
name: generate-guide
description: >
  Generate a comprehensive project setup and deployment guide for any project or sub-project,
  then automatically self-review the guide against the actual codebase using ralph-loop.
  Use when the user asks to "generate guide", "write setup doc", "write guide", "项目指南",
  "写文档指引", "setup instructions", or any request to create documentation for how to
  configure, install, run, test, or deploy a project locally or in the cloud.
  Requires the ralph-loop plugin to be installed for the self-review phase.
argument-hint: <project-path> [custom instructions]
---

# Generate Project Guide

Create a comprehensive, beginner-friendly guide for a project or sub-project, then
self-review it for accuracy. Two phases: generate, then review via ralph-loop.

## Prerequisites

- The ralph-loop plugin must be installed
- A project with actual code to document

## Arguments

$ARGUMENTS format: PROJECT_PATH [CUSTOM_INSTRUCTIONS]

- PROJECT_PATH: first token, relative or absolute path to the target project/sub-project
  (e.g., /apps/mobile, apps/api, . for current directory)
- CUSTOM_INSTRUCTIONS: everything after the path, optional free-text that supplements
  the standard guide sections (e.g., "include AxaiPay webhook testing" or "focus on EAS build")

If no arguments are provided, ask the user which project path to target.

## Phase 1: Generate the Guide

Before writing anything, complete ALL of these steps.

### Step 1: Read Project Context

- Read the project's CLAUDE.md (if it exists) for environment info, conventions, and
  deployment targets.
- Read the root-level CLAUDE.md (if different) for global conventions.
- Read README.md, package.json, *.csproj, docker-compose.yml, .env.example,
  app.json, eas.json, or any other config files that reveal the tech stack and setup
  requirements.

### Step 2: Scan Project Structure

- Run a directory listing to understand the folder layout.
- Identify the tech stack, frameworks, external services, and tooling.

### Step 3: Determine Output Location and Filename

Follow this priority order:
1. If CLAUDE.md specifies a documentation location or naming convention, follow it.
2. If an existing guide file is found (e.g., GUIDE.md, SETUP.md, docs/setup.md), ask
   the user whether to overwrite or create a new file.
3. If neither, ask the user where to save and what to name the file.

### Step 4: Determine Document Language

- If the user specified a language, use it.
- Otherwise, default to English.

### Step 5: Identify Gaps

If any of the following are unclear after scanning the project, ask the user before proceeding:
- Target deployment environment (e.g., Azure App Service, Vercel, EAS, etc.)
- Required accounts or credentials that aren't referenced in config files
- Database setup steps that aren't scripted

### Step 6: Write the Guide

ULTRATHINK before writing. Synthesize everything gathered from Steps 1-5: the project
structure, tech stack, config files, CLAUDE.md conventions, and custom instructions. Plan
which sections apply, the correct ordering of setup steps (dependencies between steps matter),
and identify any project-specific nuances that a generic template would miss.

Then generate the following sections. Skip sections that don't apply to this project type, but
add a brief note explaining why they are skipped.

Section 1 - Project Overview:
- What this project does (one paragraph)
- Tech stack summary (framework, language, database, key libraries)
- Project structure overview (key folders and their purposes)

Section 2 - Prerequisites:
- Required software and exact versions (runtime, SDK, CLI tools, package managers)
- Required accounts or access (cloud services, API keys, third-party services)
- Required IDE extensions (if applicable)
- OS-specific notes (Windows / macOS / Linux differences, if any)

Section 3 - Local Development Setup:
- Step-by-step from fresh clone to running locally
- Environment variables setup with each variable explained and where to get its value
- Database setup (create, migrate, seed with exact commands)
- How to verify the setup is working (expected output or success indicators)

Section 4 - Development Workflow:
- How to run the project locally (dev server, watch mode, etc.)
- How to run tests (unit, integration, e2e, whatever exists)
- How to debug (IDE config, breakpoints, logs)
- Key commands cheat sheet (build, test, lint, format, etc.)
- Common development scenarios and troubleshooting tips

Section 5 - Build and Release (if applicable):
- Build commands and output
- For mobile apps: include platform-specific build steps (e.g., EAS Build, Xcode, Android Studio)
- For web apps: production build and preview steps
- Versioning or release process (if defined in project)

Section 6 - Deployment:
- Target environment and infrastructure (as found in CLAUDE.md or project config)
- Deployment steps (manual or CI/CD pipeline)
- Environment-specific configuration (staging vs production)
- Post-deployment verification steps
- Rollback procedure (if documented)

Section 7 - Troubleshooting and FAQ:
- Common issues encountered during development (based on project config and dependencies)
- Platform-specific gotchas
- Links to relevant documentation

### Writing Rules

- Audience: A developer who is new to THIS project. Assume they are competent but have
  never seen this codebase before. Explain project-specific decisions, not general
  programming concepts.
- All commands must specify the working directory.
- Include expected output or success indicators for each step.
- Use relative paths from the project root.
- Every config value, secret, or environment variable must explain where to obtain it.
- Do not invent steps. Every instruction must be grounded in what actually exists in the
  project. If something is missing (e.g., no seed script), note it as a gap.
- Code blocks must specify the language (bash, json, etc.).
- Custom instructions from $ARGUMENTS should be woven into the relevant sections,
  not appended as a separate section.

## Phase 2: Self-Review via ralph-loop

After the guide is written and saved, automatically launch a review cycle using ralph-loop.
Do not wait for user instruction.

### Step 1: Read the prompt template

Read the file prompts/review.md from this skill's directory.

### Step 2: Render the prompt

Replace all occurrences of these placeholders in the template:
- {{GUIDE_PATH}} with the actual path of the guide file that was just written
- {{PROJECT_PATH}} with the target project path from $1

### Step 3: Write the ralph-loop state file

Create the directory .claude/ if it does not exist. Then write the file
.claude/ralph-loop.local.md with the following structure:

```
---
active: true
iteration: 0
max_iterations: 8
completion_promise: GUIDE_REVIEW_COMPLETE
---
(rendered prompt content here)
```

The YAML frontmatter goes between the --- markers. The rendered prompt goes after the
closing --- with no blank line.

### Step 4: Confirm and begin

Tell the user:
"Guide written. Starting self-review now."

Then immediately begin working on the review prompt (read the guide, start verifying
against the project). When you attempt to exit after completing a unit of work, the
ralph-loop stop hook will intercept and re-feed the prompt automatically.

### After Review Completes

Inform the user:
- Which review angles passed cleanly
- What was fixed during review (summarize the git commits)
- Any known gaps that could not be resolved

### Cancellation

The user can cancel the review with: /ralph-loop:cancel-ralph
