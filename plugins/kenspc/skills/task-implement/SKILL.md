---
name: task-implement
description: >
  Iteratively implement incomplete tasks from a task document. Each task is built,
  tested, committed, and marked complete. Automatically runs task-review after
  implementation finishes.
version: 1.0.0
argument-hint: <path-to-task-file>
---

# Task Implement

Automated task implementation via subagent, followed by automatic code review.

## Trigger Phrases

Use this skill when the user says: "implement tasks", "auto-implement", "run task loop",
"实现任务", "自动实现", "帮我实现", "逐个实现", or any request to iteratively implement
tasks based on a task/feature document.

## Prerequisites

- A task document with clearly defined tasks and status markers

## Arguments

$ARGUMENTS format: PATH

- PATH: the path to the task document (e.g., docs/tasks/user-auth.md)

If the user omits the path, ask them to provide it.

## Phase 1: Implement via subagent

### Step 1: Read the prompt template

Read the file `prompts/implement.md` from this skill's directory.

### Step 2: Render the prompt

Replace all occurrences of `{{TASK_FILE}}` in the template with the actual task file
path from $ARGUMENTS.

### Step 3: Dispatch the implement agent

Tell the user:
"Starting task implementation. Dispatching implement agent now. / 开始实现任务。正在启动实现代理。"

Then dispatch a subagent using the Agent tool:
- prompt: the rendered implement prompt from Step 2
- description: "Implement tasks from document"

Do NOT write any state file. The subagent will implement all incomplete tasks within
its own context and return a summary.

### Step 4: Present implementation results

When the subagent returns, present its summary to the user:
- Which tasks were completed
- Which tasks were blocked (and why)
- Git commits made

## Phase 2: Automatic code review

After Phase 1, check the implementation results:
- If **at least one task was successfully implemented**, proceed to review.
- If **all tasks were BLOCKED** (no code was produced), skip review and inform the user.

### Step 1: Read the review skill

Read the file `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` for reference, then
read `${CLAUDE_PLUGIN_ROOT}/skills/task-review/prompts/review.md`.

### Step 2: Render the review prompt

Replace `{{TASK_FILE}}` with the same task file path. Set `{{REVIEW_SCOPE}}` to "task".

### Step 3: Dispatch the review

Tell the user:
"Implementation complete. Starting automatic code review. / 实现完成。正在启动自动代码审查。"

Then follow the review dispatch process as defined in the task-review skill
(parallel review subagents → fix subagent → regression subagent).

### Step 4: Present review results

When review completes, present the full review summary to the user.
