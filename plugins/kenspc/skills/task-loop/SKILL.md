---
name: task-loop
description: >
  Iteratively implement tasks from a task document or run multi-angle code review
  against implemented code, powered by ralph-loop. Covers the implement-and-review
  cycle for any task/feature document.
version: 1.0.0
argument-hint: <implement|review> <path-to-task-file>
---

# Task Loop

Automated implementation and review using ralph-loop.

## Trigger Phrases

Use this skill when the user says: "implement tasks", "auto-implement", "run task loop",
"review my code against tasks", "ralph implement", "ralph review", "实现任务",
"自动实现", "代码审查", "任务循环", "帮我实现", "逐个实现", or any request to
iteratively implement or review code based on a task/feature document.

## Prerequisites

- The ralph-loop plugin must be installed (check with `/ralph-loop:help`)
- A task document with clearly defined tasks and status markers

If ralph-loop is not installed, inform the user:
"This skill requires the ralph-loop plugin. Install it first, then retry."
Do not proceed without ralph-loop.

## Usage

```
/kenspc-task-loop implement docs/tasks/user-auth.md
/kenspc-task-loop review docs/tasks/user-auth.md
```

## Argument Parsing

$ARGUMENTS format: MODE PATH

- MODE: first word, either "implement" or "review"
- PATH: remaining text, the path to the task document

If the user omits mode or path, ask them to provide both.

## Execution — How to run this skill

IMPORTANT: Do NOT pass the prompt as an inline string to ralph-loop. The prompt templates contain characters that break shell parsing. Instead, write the ralph-loop state file directly.

Follow these steps exactly:

### Step 1: Read the prompt template

Based on MODE from $ARGUMENTS:
- "implement" — read the file `prompts/implement.md` from this skill's directory
- "review" — read the file `prompts/review.md` from this skill's directory

### Step 2: Render the prompt

Replace all occurrences of the literal string `{{TASK_FILE}}` in the template with the actual task file path from $ARGUMENTS.

### Step 3: Write the ralph-loop state file

Create the directory `.claude/` if it does not exist. Then write the file `.claude/ralph-loop.local.md` with the following structure:

For implement mode:
```
---
active: true
iteration: 0
max_iterations: 15
completion_promise: IMPL_COMPLETE
---
(rendered prompt content here)
```

For review mode:
```
---
active: true
iteration: 0
max_iterations: 10
completion_promise: REVIEW_COMPLETE
---
(rendered prompt content here)
```

The YAML frontmatter goes between the --- markers. The rendered prompt goes after the closing --- with no blank line.

### Step 4: Confirm and begin

After writing the state file, tell the user:

For implement:
"Task loop initialized in implement mode. Starting now."

For review:
"Task loop initialized in review mode. Starting now."

Then immediately begin working on the prompt (read the task document, start implementing or reviewing). When you attempt to exit after completing a unit of work, the ralph-loop stop hook will intercept and re-feed the prompt automatically.

### Cancellation

The user can cancel with: /ralph-loop:cancel-ralph

## Modes Summary

### implement
Iteratively implements incomplete tasks from the task document. Each task is built, tested, committed, and marked complete.

Settings: max_iterations 15, completion_promise IMPL_COMPLETE

### review
Multi-angle code review with progress tracking via .claude/task-review-progress.tmp. Covers 5 review angles plus a final regression pass. Progress file is deleted upon completion.

Settings: max_iterations 10, completion_promise REVIEW_COMPLETE
