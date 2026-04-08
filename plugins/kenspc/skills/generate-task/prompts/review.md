Task document: {{TASK_DOC_PATH}}
Plan document: {{SOURCE_PATH}}
Project path: {{PROJECT_PATH}}

OBJECTIVE
Review the generated task document against the source plan and actual project to
ensure it is complete, correctly ordered, and actionable. Fix task-level issues
directly. Record plan-level issues without modifying the plan.
Track every change you make so you can report them at the end.

PREREQUISITES
1. Read the task document in full.
2. Read the source plan document in full.
3. If {{PROJECT_PATH}} is not "N/A":
   - Read CLAUDE.md for project conventions, tech stack, and constraints.
   - Scan the project structure and key config files.

REVIEW ANGLES
Review both angles in order (the second angle builds on fixes from the first).

1. Completeness
   - Cross-reference every Implementation Step in the source plan against the task
     document. Is every step covered by at least one task?
   - If a specific phase was requested: verify only that phase's steps are covered,
     but flag if tasks reference steps from other phases that are not included.
   - Does each task's acceptance criteria have a concrete, verifiable condition?
     Flag vague language: "as appropriate", "if needed", "properly", "sufficient",
     "adequate", "correctly" — these must be replaced with specific conditions.
   - Are there plan steps that were split into multiple tasks? Verify the split
     covers the full scope of the original step.
   - If the plan has a Risks section: are relevant risks reflected in task acceptance
     criteria or noted in task descriptions?

2. Execution Order
   - Are dependencies between tasks correct? Does any task assume output from a
     later task?
   - For cross-phase tasks: are dependency annotations present and accurate?
   - Is granularity roughly uniform? Flag if one task touches 10+ files while
     another touches only 1 — this suggests uneven decomposition.
   - Trace through the task list in order: could a developer execute each task
     without needing to jump ahead or back?

ISSUE CLASSIFICATION

Task-level issues (wrong order, missing criteria, uneven granularity, missing
dependency annotation):
→ Fix directly in the task document. Commit the fix.

Plan-level issues (plan step is contradictory, plan is missing a necessary step,
plan's technical approach conflicts with existing code):
→ Do NOT modify the plan document.
→ Add a "## Plan-Level Concerns" section at the end of the task document.
→ Record each concern with: what the issue is, which plan step is affected, and
  what the user should consider.
→ Commit the addition.

EXECUTION FLOW
For each angle, in order:
1. ULTRATHINK to thoroughly review the current angle.
2. No issues found → record the angle as passed.
3. Task-level issue found → fix it directly and git commit.
   Record what you changed and why.
4. Plan-level issue found → add to Plan-Level Concerns section and git commit.
   Record what you noted and why.
5. After fixing, re-read changed sections to confirm correctness.
6. Proceed to the next angle.

If a task-level issue cannot be resolved after 3 attempts, record it as unresolved,
note it in the summary, and continue with other angles.

OUTPUT LANGUAGE
All summaries must be bilingual (English + Chinese).
The task document itself remains in whatever language it was written in.

COMPLETION
When both angles have been reviewed, output a summary:

---
Task Document Review Summary / 任务文档审查总结

Angles: [list each angle with PASSED or FIXED or NOTED status]
  Angle 1: Completeness - PASSED / 通过
  Angle 2: Execution Order - FIXED 2 issues / 修复了 2 个问题

Changes made / 修改内容:
  - [Angle N] Changed X → Y. Reason: ... Commit: abc1234 / 原因：...

Plan-level concerns / 计划层面的问题:
  - [Concern description, affected plan step, recommendation]
  (If none: "No plan-level concerns found / 未发现计划层面问题")

Unresolved issues / 未解决的问题:
  - [If any issues could not be fixed after 3 attempts]

If no changes were made, state: No changes needed / 无需修改
---
