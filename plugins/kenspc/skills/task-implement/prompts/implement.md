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
1. ULTRATHINK to plan the implementation approach for this task — which files
   to create/modify, which patterns to follow, which edge cases to handle.
   The task's scope and acceptance criteria are already defined; do not
   decompose into sub-tasks or redefine scope.
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

AUTONOMY BOUNDARIES

ALWAYS (do without asking):
- Follow existing project conventions (naming, structure, patterns from CLAUDE.md)
- Write tests for new functions (if test framework is configured)
- Use conventional commit format
- Handle errors on external calls (DB, API, file I/O)
- Run build/test/lint after each task

STOP (mark task as BLOCKED with the specific decision needed):
- Adding a new dependency not mentioned in the task document
- Changing an existing API contract (parameters, return type, error codes)
- Creating or modifying database schema beyond what the task specifies
- Deviating from the task document's stated approach
- Modifying files outside the task's stated scope
- Changing project configuration (tsconfig, eslint, prettier, etc.) unless the task explicitly requires it

NEVER (do not do even if it seems helpful):
- Refactor code unrelated to the current task
- Delete or rename existing public APIs
- Commit code that doesn't build

QUALITY CHECKLIST (apply to code you write for this task — not existing code)
- Edge cases: handle null, empty, and boundary values at public function entries.
- Error handling: wrap external calls (DB, API, file I/O) with proper error handling;
  do not silently swallow errors.
- Resource cleanup: close connections, handles, and streams in finally/defer/using.
- Async correctness: await all async operations; no unintended fire-and-forget.
- No magic numbers: externalize config values to constants or config files.
- Tests: cover happy path + at least one edge case + at least one error path per
  new function. Test behavior, not implementation details.
- Security: validate and sanitize user-facing inputs; no hardcoded secrets.

Before committing each task, verify your implementation against this checklist.

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

  Task N: [task name] - DONE. Commit: abc1234 / 完成
    Changes / 变更:
      - [key file created/modified]: [what was done and why]
      - [key file created/modified]: [what was done and why]
    Decisions / 设计决策: (only if non-obvious choices were made)
      - [decision]: [why this approach over alternatives]
    Notes / 注意事项: (only if post-implementation steps are needed)
      - [e.g., run migration, set environment variable, update config]

  Task N: [task name] - DONE. Commit: def5678 / 完成
    Changes / 变更:
      - ...

Tasks blocked / 阻塞任务:

  Task N: [task name] - BLOCKED / 阻塞
    Attempted / 尝试过: [what was tried]
    Root cause / 根本原因: [specific reason for the block]
    Suggestion / 建议: [how to resolve this]

If no tasks were completed, state: No tasks completed / 没有完成任何任务
---
