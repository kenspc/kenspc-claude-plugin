Guide document: {{GUIDE_PATH}}
Project path: {{PROJECT_PATH}}

OBJECTIVE
Review the generated guide against the actual project to ensure it is accurate, complete,
executable, and consistent. Fix any issues found directly in the guide document.

PREREQUISITES (execute each iteration as needed)
1. Inspect key files in the project root to identify the tech stack, build/test/lint commands,
   and project conventions (prioritize CLAUDE.md).
2. If .claude/guide-review-progress.tmp does not exist, create it with this content:
   - [ ] 1. Accuracy
   - [ ] 2. Completeness
   - [ ] 3. Executability
   - [ ] 4. Consistency
3. Read the guide document in full.
4. Scan the project structure and key config files.

REVIEW ANGLES
Read the progress file and pick the next incomplete angle:

1. Accuracy
   - Verify every command in the guide actually works by checking it against package.json
     scripts, *.csproj targets, Makefile, or equivalent.
   - Verify every file path mentioned in the guide exists in the project.
   - Verify environment variable names match what the code actually reads (check .env.example,
     appsettings.json, app.config, or source code).
   - Verify version numbers match what is pinned in package.json, global.json, or Dockerfile.
   - Verify database commands match the actual ORM or migration tool used.

2. Completeness
   - Cross-reference guide sections against the project's actual dependencies. Are there
     services or tools the project requires that the guide does not mention?
   - Check for missing prerequisites (e.g., project uses Redis but guide does not mention it).
   - Check for missing environment variables (compare guide's list against all env vars read
     in code).
   - Check if build/test/lint commands are all documented.
   - For mobile projects: check if platform-specific setup (Xcode, Android SDK, EAS) is covered.
   - For cloud deployment: check if all infrastructure resources are documented.

3. Executability
   - Trace through the guide from top to bottom as a new developer would.
   - Are steps in the correct order? (e.g., database must be running before migrations)
   - Does each step specify the working directory?
   - Does each step show expected output or success indicator?
   - Are there implicit assumptions that a new developer would not know?
   - Check that no step depends on something that has not been set up in a prior step.

4. Consistency
   - Compare guide content against CLAUDE.md. Are there contradictions in tech stack
     descriptions, environment names, deployment targets, or conventions?
   - Compare guide content against README.md. Do they tell conflicting stories?
   - Check internal consistency within the guide itself (e.g., prerequisites section says
     Node 20 but a later command assumes Node 22).

EXECUTION FLOW PER ITERATION
1. Read the progress file to determine the current angle.
2. Run "git log --oneline -5" to see what previous review iterations fixed.
3. ULTRATHINK to thoroughly review the current angle.
4. No issues found: mark the angle as passed in the progress file, then continue to the
   next angle if iterations remain.
5. Issue found: fix it directly in the guide document and git commit the fix.
6. After fixing, re-read the changed sections to confirm the fix is correct.
7. Actively look for blind spots that previous iterations may have missed.

OUTPUT LANGUAGE
All summaries and progress messages must be bilingual (English + Chinese).
When reporting on a review angle, use this format:
  Angle N: [name] - PASSED (no issues) / 通过（无问题）
  Angle N: [name] - FIXED [count] issues / 修复了 [count] 个问题
When completing, output a final summary in this format:
  Guide Review Summary / 指南审查总结:
  - Angles passed: N/4 / 通过角度：N/4
  - Issues fixed: N / 修复问题：N
  - Issues unresolved: N / 未解决问题：N
  - [list each angle with result in bilingual format]
Note: the guide document itself remains in whatever language it was written in.

COMPLETION
When all items in the progress file are marked as passed:
1. Delete .claude/guide-review-progress.tmp
2. Output the bilingual summary then output <promise>GUIDE_REVIEW_COMPLETE</promise>

If a problem cannot be fixed after 3 attempts (judge by git log), record the issue in the
guide's Troubleshooting section as a known gap, skip it, and continue with other angles.
If a git conflict or environment issue prevents continuing, delete
.claude/guide-review-progress.tmp and output <promise>GUIDE_REVIEW_COMPLETE</promise>.
