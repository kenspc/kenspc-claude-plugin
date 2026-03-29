Task document: {{TASK_FILE}}

OBJECTIVE
Read the task document for full context. Implement incomplete tasks in order.

EXECUTION FLOW
1. Inspect key files in the project root to identify the tech stack, build/test/lint commands, and project conventions (prioritize CLAUDE.md). If the task document does not exist or cannot be parsed, immediately output <promise>IMPL_COMPLETE</promise> and write BLOCKED.md in the same directory explaining why.
2. Run "git log --oneline -5" to see what previous iterations did.
3. Read the task document. Find the next incomplete task based on status markers.
4. ULTRATHINK to analyze requirements, then implement the code.
5. Run build/test/lint to verify. If the project has no test framework configured, skip test verification and note this in the task document.
6. After verification passes, update the task status in the task document (use whatever status format the document already uses). Include both code changes and status update in the same git commit.

QUALITY RULES
- Follow established project conventions and patterns.
- New code must have corresponding tests (if test framework is configured).
- Do not modify code unrelated to the current task.

STUCK HANDLING
- Use git log and task document status to judge if the current task has been attempted multiple times. If the same task fails verification 3 iterations in a row, record the blocking reason under that task, mark it as BLOCKED, and skip to the next task.
- If a git conflict or environment issue prevents continuing, append the problem to the task document and output <promise>IMPL_COMPLETE</promise>.

OUTPUT LANGUAGE
All summaries and progress messages must be bilingual (English + Chinese).
When reporting progress on a task, use this format:
  Task N: [brief description] - DONE / 完成
  Task N: [brief description] - BLOCKED: [reason] / 阻塞：[原因]
When completing, output a final summary in this format:
  Summary / 总结:
  - Completed: N tasks / 已完成：N 个任务
  - Blocked: N tasks / 阻塞：N 个任务
  - [list each task with status in bilingual format]
Note: code, code comments, commit messages, and technical identifiers remain in English only.

COMPLETION
When all tasks in the task document are completed or BLOCKED, output the bilingual summary then output <promise>IMPL_COMPLETE</promise>.
