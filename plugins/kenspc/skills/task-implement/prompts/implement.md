Task document: {{TASK_FILE}}

OBJECTIVE
Read the task document for full context. Implement incomplete tasks in order.
Track every task you complete so you can report them at the end.

PREREQUISITES
1. Inspect key files in the project root to identify the tech stack, build/test/lint
   commands, and project conventions (prioritize CLAUDE.md).
2. If the task document does not exist or cannot be parsed, return a summary stating
   BLOCKED with the reason.
3. Read the task document. Identify all incomplete tasks.
4. Run "git log --oneline -10" to understand what has already been implemented.

EXECUTION FLOW
For each incomplete task, in order:
1. ULTRATHINK to analyze requirements, then implement the code.
2. Run build/test/lint to verify. If the project has no test framework configured,
   skip test verification and note this in the task document.
3. After verification passes, update the task status in the task document (use whatever
   status format the document already uses). Include both code changes and status update
   in the same git commit.
4. Record what you implemented and the commit hash.
5. Proceed to the next incomplete task.

QUALITY RULES
- Follow established project conventions and patterns.
- New code must have corresponding tests (if test framework is configured).
- Do not modify code unrelated to the current task.

STUCK HANDLING
- If the same task fails verification 3 times in a row, record the blocking reason
  under that task in the task document, mark it as BLOCKED, and skip to the next task.
- If a git conflict or environment issue prevents continuing, append the problem to
  the task document and stop.

OUTPUT LANGUAGE
All summaries and progress messages must be bilingual (English + Chinese).
Code, code comments, commit messages, and technical identifiers remain in English only.

COMPLETION
When all tasks in the task document are completed or BLOCKED, output a final summary:

---
Implementation Summary / 实现总结

Tasks completed / 已完成任务:
  - Task N: [brief description] - DONE. Commit: abc1234 / 完成
  - Task N: [brief description] - DONE. Commit: def5678 / 完成

Tasks blocked / 阻塞任务:
  - Task N: [brief description] - BLOCKED: [reason] / 阻塞：[原因]

If no tasks were completed, state: No tasks completed / 没有完成任何任务
---
