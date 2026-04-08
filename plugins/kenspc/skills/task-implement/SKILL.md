---
name: task-implement
description: >
  Automated batch implementation: auto-implements ALL incomplete tasks from a task
  document without user interaction, then runs automated code review. Only use when
  the user explicitly requests automated/batch task implementation.
version: 1.3.0
argument-hint: <path-to-task-file>
---

# Task Implement

Automated task implementation via subagent, followed by automatic code review.

## Trigger Phrases

Use this skill **only** when the user explicitly requests automated batch implementation,
using phrases like: "implement tasks", "auto-implement", "run task loop", "实现任务",
"自动实现", "帮我自动实现", "逐个实现", or invokes `/kenspc-task-implement` directly.

**Do NOT trigger this skill** when the user:
- Wants to develop interactively (e.g., "继续开发", "let me work on", "帮我看看",
  "有问题请问我", "let's build", "我想做...")
- References a task document for context only, without asking for automated implementation
- Asks questions about tasks, priorities, or what to implement next
- Asks you to implement a single specific task (just do it directly, no skill needed)

The key distinction: this skill is for **unattended, automated batch** implementation of
ALL incomplete tasks. If the user wants a conversation, wants to drive development
themselves, or only wants one specific task done, do NOT invoke this skill.

## Common Rationalizations

| Agent says | Why it's wrong |
|---|---|
| "这个 task 很简单不需要测试" | Simple functions are most easily broken during refactoring. At least one happy path test. |
| "这个 task 依赖前一个 task，先实现前一个的功能再回来补" | Execute tasks in document order. If a dependency is not met, mark the task as BLOCKED. Do not jump between tasks. |
| "顺便修一下旁边的代码" | NEVER boundary: do not modify code outside the task's scope. Record as a backlog item if needed. |
| "测试框架没配好，跳过测试" | Mark the task as BLOCKED. Do not silently skip testing. |
| "最后再一起测试" | Bugs compound. A bug in Task 1 makes Tasks 2-5 wrong. Verify each task individually. |
| "一次实现多个 task 比较快" | It *feels* faster until something breaks and you can't isolate which task caused it. One task at a time. |

## Red Flags

Stop and inform the user if any of these occur (thresholds are starting values — adjust based on project experience):

- More than half of the tasks end up BLOCKED → Likely a systemic issue with the task document, not individual tasks. Stop implementing remaining tasks and inform the user that the task document may need revision.
- The same task fails build verification 3 times (existing stuck handling triggers), then the NEXT task also fails → Check whether the first task's implementation caused a cascading failure. Inform the user.
- Implementing a task requires modifying more than ~5 files outside the task's stated scope → STOP. The task's scope definition is wrong. Mark as BLOCKED.

## Prerequisites

- A task document with clearly defined tasks and status markers

## Arguments

$ARGUMENTS format: PATH

- PATH: the path to the task document (e.g., docs/tasks/user-auth.md)

If the user omits the path, ask them to provide it.

## Phase 1: Implement via subagent

### Step 1: Read the prompt template

Read the file `prompts/implement.md` from this skill's directory.

### Step 2: Validate input document

Read the file at the provided path. Check whether it is a task document or a plan document:

- **Task document**: contains individual entries with `**Status:**` markers (TODO, IN PROGRESS, DONE, BLOCKED)
- **Plan document**: contains Implementation Steps organized by Phase/Step, without Status markers

If the file appears to be a plan document (has Phase/Step structure but no Status markers):
Tell the user:
"This appears to be a plan document, not a task document. Use /kenspc-task to generate
a task document from this plan first. /
这看起来是计划书而非任务文档。请先使用 /kenspc-task 从计划书生成任务文档。"
Do NOT proceed with implementation.

If validation passes, retain the parsed task list for use in Step 4 (Confirm with user).

### Step 3: Render the prompt

Replace all occurrences of `{{TASK_FILE}}` in the template with the actual task file
path from $ARGUMENTS.

### Step 4: Confirm with user

Read the task document and identify all incomplete tasks. Present them to the user:

"Found N incomplete tasks to auto-implement: / 发现 N 个未完成任务将自动实现：
1. Task X: [brief name]
2. Task Y: [brief name]
...
Proceed with automated implementation? / 是否开始自动实现？"

Wait for explicit confirmation before proceeding. If the user declines or wants to
adjust scope, follow their instructions instead.

### Step 5: Dispatch the implement agent

Tell the user:
"Starting task implementation. Dispatching implement agent now. / 开始实现任务。正在启动实现代理。"

Then dispatch a subagent using the Agent tool:
- prompt: the rendered implement prompt from Step 2
- description: "Implement tasks from document"

Do NOT write any state file. The subagent will implement all incomplete tasks within
its own context and return a summary.

### Step 6: Report progress

When the subagent returns, present a brief progress update (not the full details):

"Implementation phase complete. / 实现阶段完成。
- Completed: N tasks (Task X, Task Y, ...) / 已完成：N 个任务
- Blocked: N tasks (Task Z: [brief reason], ...) / 阻塞：N 个任务
Proceeding to code review. / 继续进行代码审查。"

If all tasks were blocked, replace the last line with:
"All tasks blocked. Skipping code review. / 所有任务阻塞，跳过代码审查。"

Full implementation details will be included in the final report (Phase 2 Step 4).

## Phase 2: Automatic code review

After Phase 1, check the implementation results:
- If **at least one task was successfully implemented**, proceed to review (Steps 1-4).
- If **all tasks were BLOCKED** (no code was produced), skip review and go directly
  to Step 4 to present a simplified final report (omit Code Review and Build Status
  sections, keep Implementation and Next Steps).

### Step 1: Read the review skill

Read the file `${CLAUDE_PLUGIN_ROOT}/skills/task-review/SKILL.md` and follow its
instructions for reading prompt templates and dispatching agents.

### Step 2: Render the review prompt

Replace `{{TASK_FILE}}` with the same task file path. Set `{{REVIEW_SCOPE}}` to "task".
Set `{{CUSTOM_INSTRUCTIONS}}` to "N/A" (unless the user provided specific review instructions).

### Step 3: Dispatch the review

Tell the user:
"Implementation complete. Starting automatic code review. / 实现完成。正在启动自动代码审查。"

Then follow the review dispatch process as defined in the task-review skill
(parallel review subagents → fix subagent → regression subagent).

### Step 4: Present final report

When all phases complete, present a consolidated final report to the user:

```
## Final Report / 最终报告

### Implementation / 实现结果
[From implement agent — per-task details including key changes, files, decisions]

### Code Review / 代码审查
- Issues found across 5 angles: N total (N HIGH, N MEDIUM, N LOW)
- Issues fixed: N (list commits)
- Issues not applicable: N

### Unresolved Items / 待处理事项
[All DEFERRED and BLOCKED items with full detail — why, risk, suggested approach]

### Build Status / 构建状态
- Build: PASS/FAIL
- Tests: PASS/FAIL
- Lint: PASS/FAIL

### Review Verdict / 审查判定
PASS or FAIL (based on task-review verdict criteria)
If PASS: "No further review needed. / 无需再次审查。"
If FAIL: "Address N HIGH issues and re-run review. / 请处理 N 个 HIGH 问题后重新审查。"

### Next Steps / 后续步骤
[Concrete list of what the user should do next — manual steps, deferred items to plan, etc.]
```

Every DEFERRED and BLOCKED item must have enough detail for the user to understand and
act on without reading the raw review reports or commit history.
