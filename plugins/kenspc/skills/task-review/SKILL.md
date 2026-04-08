---
name: task-review
description: >
  Thorough code review (代码审查/review代码) using 5 parallel review agents, a fix
  agent, and a regression verification agent. Use for ANY code review request —
  not overkill, each agent covers a different angle (bugs, edge cases, tests,
  security, conventions). Works with a task document (review against requirements)
  or standalone (review recent changes/uncommitted code).
version: 1.3.0
argument-hint: [path-to-task-file]
---

# Task Review

Parallel multi-angle code review with automated fix and regression verification.

## Trigger Phrases

Use this skill when the user says: "review my code", "code review", "review against tasks",
"review changes", "代码审查", "审查代码", "review 一下", or any request to review
implemented code for quality, correctness, and completeness.

## Common Rationalizations

| Agent says | Why it's wrong |
|---|---|
| "这个文件是 boilerplate，不需要 review" | Errors in boilerplate propagate across the entire project. FILE COVERAGE rule: every modified file must be reviewed. |
| "所有 angle 报的 issue 都是 LOW/MEDIUM，跳过 fix agent" | Fix agent processes all severities. LOW is marked as acknowledged, MEDIUM is evaluated for fix. Skipping fix agent loses deduplication and accountability tracking. |
| "Build 过了就不需要 regression agent" | Build passing does not mean fixes are correct. The regression agent verifies that fixes actually resolve the reported issues, not just that the code compiles. |
| "AI 生成的代码应该没问题" | AI code needs *more* scrutiny, not less. It's confident and plausible, even when wrong. |
| "能跑就行" | Working code that's unreadable, insecure, or architecturally wrong creates debt that compounds. |

## Red Flags

Stop and inform the user if any of these occur (thresholds are starting values — adjust based on project experience):

- 5 review angles report a combined ~15+ HIGH issues → Code quality is below what review can fix. Inform the user that partial reimplementation may be needed.
- Fix agent's DEFERRED items outnumber FIXED items → Most issues require architectural changes. Review is treating symptoms, not causes. Inform the user.
- Regression agent finds that fix commits introduced new HIGH issues → Fix agent created new problems. Inform the user that manual intervention is needed.

## Prerequisites

- A project with code to review
- Optionally, a task document for requirements context

## Arguments

$ARGUMENTS format: [PATH] [CUSTOM_INSTRUCTIONS]

- PATH (optional): first token, path to a task document. If omitted, the review covers
  recent changes (uncommitted, staged, or recently committed) without a requirements
  reference.
- CUSTOM_INSTRUCTIONS (optional): everything after the path, free-text that narrows the
  review scope or adds specific requirements (e.g., "only review src/api/", "focus on
  security and SQL injection", "只review authentication相关的代码").

If $ARGUMENTS contains no file path (first token is not a path), treat the entire
input as CUSTOM_INSTRUCTIONS.

## Execution

### Step 1: Determine review scope

If $ARGUMENTS contains a file path:
- Set REVIEW_SCOPE to "task"
- Set TASK_FILE to the provided path
- Verify the file exists; if not, ask the user for the correct path

If $ARGUMENTS is empty or contains no file path:
- Set REVIEW_SCOPE to "changes"
- Set TASK_FILE to "N/A"

### Step 2: Read the prompt templates

Read the following files from this skill's `prompts/` directory:
- `review-angle-1.md` through `review-angle-5.md` (the 5 review angle prompts)
- `fix.md` (the fix agent prompt)
- `regression.md` (the regression verification prompt)

### Step 3: Render prompts

Replace placeholders in all templates:
- `{{TASK_FILE}}` — the task file path, or "N/A"
- `{{REVIEW_SCOPE}}` — "task" or "changes"
- `{{CUSTOM_INSTRUCTIONS}}` — the user's custom instructions, or "N/A"

### Prompt variables

| Variable | Source | Values |
|----------|--------|---------|
| {{TASK_FILE}} | Step 1 | File path or "N/A" |
| {{REVIEW_SCOPE}} | Step 1 | "task" or "changes" |
| {{CUSTOM_INSTRUCTIONS}} | $ARGUMENTS | Free text or "N/A" |

### Step 4: Dispatch parallel review agents (Phase 1)

Tell the user:
"Starting parallel code review (5 angles). / 正在启动并行代码审查（5 个角度）。"

Dispatch **5 subagents in a single message** using the Agent tool, one for each
review angle. Each subagent is read-only — it analyzes code and produces a report
but does NOT modify any files.

- Agent 1: prompt from review-angle-1.md, description: "Review: requirements"
- Agent 2: prompt from review-angle-2.md, description: "Review: edge cases"
- Agent 3: prompt from review-angle-3.md, description: "Review: code quality"
- Agent 4: prompt from review-angle-4.md, description: "Review: bug hunting"
- Agent 5: prompt from review-angle-5.md, description: "Review: test coverage"

### Step 5: Dispatch fix agent (Phase 2)

Collect all 5 review reports. Then dispatch a single subagent with:
- prompt: rendered fix.md, with all 5 reports included
- description: "Fix reported issues"

The fix agent will deduplicate overlapping findings, apply fixes, and commit.
It must produce an accountability list mapping every reported issue to an action.

### Step 6: Dispatch regression agent (Phase 3)

After the fix agent returns, dispatch a single subagent with:
- prompt: rendered regression.md, with the original 5 reports AND the fix
  agent's accountability list included
- description: "Regression verification"

The regression agent verifies:
1. Every issue from the 5 reports is accounted for in the fix list
2. Fixed issues are actually fixed in the code
3. build/test/lint passes
4. Fix commits did not introduce new issues

### Step 7: Present results

When the regression agent returns, determine the verdict and present results.

#### Pass/Fail Determination

Based on the regression verification results, declare a verdict:

**PASS** — all of these are true:
  - Zero HIGH severity issues remain unresolved
  - Zero INCORRECTLY FIXED items
  - Build: PASS, Tests: PASS, Lint: PASS
  - No regressions introduced by fix commits

**FAIL** — any of these are true:
  - 1+ HIGH severity issues remain unresolved
  - 1+ INCORRECTLY FIXED items
  - Build, test, or lint fails
  - Fix commits introduced unresolved regressions

MEDIUM and LOW issues do not affect the verdict but must be listed in the report.

#### Summary

Present the full summary to the user:
- **Verdict: PASS or FAIL**
- Each review angle's findings
- All changes made with reasons
- Any unresolved issues (with severity)
- Regression verification result
- If PASS: "No further review needed. / 无需再次审查。"
- If FAIL: "Address N HIGH issues and re-run review. / 请处理 N 个 HIGH 问题后重新审查。"
