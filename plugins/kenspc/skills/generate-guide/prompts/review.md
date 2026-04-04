Guide document: {{GUIDE_PATH}}
Project path: {{PROJECT_PATH}}

OBJECTIVE
Review the generated guide against the actual project to ensure it is accurate, complete,
executable, and consistent. Fix any issues found directly in the guide document.
Track every change you make so you can report them at the end.

PREREQUISITES
1. Inspect key files in the project root to identify the tech stack, build/test/lint commands,
   and project conventions (prioritize CLAUDE.md).
2. Read the guide document in full.
3. Scan the project structure and key config files.

REVIEW ANGLES
Review all four angles in order (each angle builds on fixes from the previous one):

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

EXECUTION FLOW
For each angle, in order from 1 to 4:
1. ULTRATHINK to thoroughly review the current angle.
2. No issues found → record the angle as passed.
3. Issue found → fix it directly in the guide document and git commit the fix.
   Record what you changed and why (one line per change).
4. After fixing, re-read the changed sections to confirm the fix is correct.
5. Proceed to the next angle (which will see the fixes you just made).

OUTPUT LANGUAGE
All summaries must be bilingual (English + Chinese).
The guide document itself remains in whatever language it was written in.

COMPLETION
When all four angles have been reviewed, output a final summary in this format:

---
Guide Review Summary / 指南审查总结

Angles: [list each angle with PASSED or FIXED status]
  Angle 1: Accuracy - PASSED / 通过
  Angle 2: Completeness - FIXED 3 issues / 修复了 3 个问题
  ...

Changes made / 修改内容:
(List every change. Each entry must state WHAT was changed, WHY, and the git commit.)
  - [Angle N] Changed X → Y. Reason: ... Commit: abc1234 / 原因：...
  - [Angle N] Added section Z. Reason: ... Commit: def5678 / 原因：...

Unresolved gaps / 未解决的问题:
(List any issues that could not be fixed after 3 attempts, with explanation.)
  - [Angle N] Issue description. Why unresolved: [reason] / 未解决原因：[原因]

If no changes were made, state: No changes needed / 无需修改
---

If a problem cannot be fixed after 3 attempts, record the issue in the guide's
Troubleshooting section as a known gap, note it in the summary, and continue with
other angles.
If a git conflict or environment issue prevents continuing, output the summary with
whatever angles were completed and note the blocker.
