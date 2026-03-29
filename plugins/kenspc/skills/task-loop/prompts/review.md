Task document: {{TASK_FILE}}

OBJECTIVE
Read the task document for requirements context. Perform a multi-angle code review of the implemented code.
Small fixes: apply directly. Large structural changes spanning multiple files: record as suggestions, do not apply.

PREREQUISITES (execute each iteration as needed)
1. Inspect key files in the project root to identify the tech stack, build/test/lint commands, and project conventions (prioritize CLAUDE.md).
2. If .claude/task-review-progress.tmp does not exist, create it with this content:
   - [ ] 1. Requirements completeness
   - [ ] 2. Edge cases and error handling
   - [ ] 3. Code quality and project conventions
   - [ ] 4. Bug hunting
   - [ ] 5. Test coverage
   - [ ] 6. Final regression verification
3. Run "git log --oneline -30" to understand the full change history from implementation.
4. Read the task document to understand all task requirements.

REVIEW ANGLES
Read the progress file and pick the next incomplete angle:

1. Requirements completeness — Compare each task requirement against actual code line by line. Verify API contracts. Check whether BLOCKED tasks have valid blocking reasons.

2. Edge cases and error handling — Malicious input, null/empty values, boundary values. Concurrency and race conditions. Error handling on all external calls (DB, API, file I/O). Server-side validation completeness.

3. Code quality and project conventions — Check naming and structure against project conventions. DRY/SOLID principles. Magic numbers and hardcoded config values.

4. Bug hunting — Review with a skeptical mindset; do not assume any code is correct. Trace key happy paths and error paths step by step. Watch for off-by-one errors, null references, missing async/await, resource leaks, database query correctness, and N+1 problems.

5. Test coverage — Are core logic, edge cases, and error paths tested? Do tests verify real behavior rather than implementation details? If tests are missing, add them.

EXECUTION FLOW PER ITERATION
1. Read the progress file to determine the current angle.
2. Run "git log --oneline -5" to see what previous review iterations fixed.
3. ULTRATHINK to deeply review the current angle.
4. No issues found: mark the angle as passed in the progress file, then continue to the next angle.
5. Issue found: fix it and git commit.
6. After fixing, run build/test/lint. Only mark the angle complete after verification passes.
7. Actively look for blind spots that previous iterations may have missed.

FINAL REGRESSION VERIFICATION (after angles 1-5 all pass)
1. Run build/test/lint to confirm everything passes.
2. Review all fix commits from the review phase. Cross-check the files they touched to ensure fixes did not break logic validated in earlier angles.
3. If new issues are found, fix and re-verify.
4. When confirmed clean, mark "Final regression verification" as passed.

OUTPUT LANGUAGE
All summaries and progress messages must be bilingual (English + Chinese).
When reporting on a review angle, use this format:
  Angle N: [name] - PASSED (no issues) / 通过（无问题）
  Angle N: [name] - FIXED [count] issues / 修复了 [count] 个问题
When completing, output a final summary in this format:
  Review Summary / 审查总结:
  - Angles passed: N/6 / 通过角度：N/6
  - Issues fixed: N / 修复问题：N
  - Issues unresolved: N / 未解决问题：N
  - [list each angle with result in bilingual format]
Note: code, code comments, commit messages, and technical identifiers remain in English only.

COMPLETION
When all items in the progress file are marked as passed:
1. Delete .claude/task-review-progress.tmp
2. Output the bilingual summary then output <promise>REVIEW_COMPLETE</promise>

If a problem cannot be fixed after 3 attempts (judge by git log), record the blocking reason in the progress file, skip it, and continue with other angles.
If a git conflict or environment issue prevents continuing, delete .claude/task-review-progress.tmp and output <promise>REVIEW_COMPLETE</promise>.
