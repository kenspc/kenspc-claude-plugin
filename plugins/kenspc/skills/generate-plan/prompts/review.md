Plan document: {{PLAN_PATH}}
Project path: {{PROJECT_PATH}}

OBJECTIVE
Review the generated plan to ensure it is feasible, complete, consistent, and clear
enough to be directly executed. Fix any issues found directly in the plan document.

PREREQUISITES (execute each iteration as needed)
1. Read the plan document in full.
2. If {{PROJECT_PATH}} is not "N/A":
   - Read CLAUDE.md for project conventions, tech stack, and constraints.
   - Scan the project structure and key config files (package.json, *.csproj,
     docker-compose.yml, .env.example, etc.).
3. If .claude/plan-review-progress.tmp does not exist, create it with this content:
   - [ ] 1. Feasibility & Execution Order
   - [ ] 2. Completeness
   - [ ] 3. Consistency
   - [ ] 4. Clarity & Actionability

REVIEW ANGLES
Read the progress file and pick the next incomplete angle:

1. Feasibility & Execution Order
   - Is every proposed technology, library, and tool actually available and suitable
     for the stated purpose? If specific versions are mentioned, do they exist?
   - Are the implementation steps in a correct dependency order? Does any step assume
     something that has not been set up by a prior step?
   - Are there implicit assumptions about infrastructure, services, or access that
     are not stated?
   - Is the estimated scope realistic for the stated goals?
   - If {{PROJECT_PATH}} is not "N/A": do the proposed technologies align with what
     is already installed or configured in the project?

2. Completeness
   - Does the plan address every requirement that was discussed during discovery?
   - Are there obvious scenarios, edge cases, or failure modes that the plan ignores?
   - If the plan includes API endpoints: are all CRUD operations and error responses
     covered?
   - If the plan includes data models: are relationships, constraints, and indexes
     considered?
   - Are there missing steps between the stated phases (e.g., database migration
     before seeding, build before deploy)?

3. Consistency
   - If {{PROJECT_PATH}} is not "N/A": does the plan contradict anything in CLAUDE.md,
     README.md, or existing project conventions (naming, structure, patterns)?
   - Does the plan contradict itself? (e.g., says "use PostgreSQL" in one section and
     "configure SQL Server" in another)
   - Are technology names, version numbers, and terminology used consistently throughout?
   - Do the Risks section and the Implementation Steps tell the same story?

4. Clarity & Actionability
   - Could a developer (or Claude Code) execute each step without asking clarifying
     questions? If not, what is ambiguous?
   - Does every step have a clear acceptance criteria or expected outcome?
   - Flag any vague language: "as appropriate", "if needed", "consider", "optionally",
     "as necessary", "properly", "adequate", "sufficient" — these must be replaced
     with specific conditions or concrete descriptions.
   - Are inputs and outputs of each step clearly defined?
   - Is the plan structured so that progress can be tracked (e.g., checkboxes,
     numbered phases)?

FIXING RULES
- Objective issues (factual errors, contradictions, missing steps, vague language):
  Fix directly in the plan document.
- Subjective judgments (e.g., "maybe technology X would be better than Y"):
  Do NOT change the plan's technical decisions. Instead, add the concern to the plan's
  Risks or Open Questions section. The user made those decisions during discussion.
- When fixing, preserve the plan's original structure and style.
- After fixing, re-read the changed sections to confirm the fix is correct and does
  not introduce new issues.

EXECUTION FLOW PER ITERATION
1. Read the progress file to determine the current angle.
2. ULTRATHINK to thoroughly review the current angle.
3. No issues found → mark the angle as passed in the progress file, then continue
   to the next angle if iterations remain.
4. Objective issue found → fix it directly in the plan document.
5. Subjective concern found → add it to the Risks or Open Questions section.
6. After all fixes for this angle, re-read affected sections to verify correctness.
7. Mark the angle complete in the progress file.

OUTPUT LANGUAGE
All summaries and progress messages must be bilingual (English + Chinese).
When reporting on a review angle, use this format:
  Angle N: [name] - PASSED (no issues) / 通过（无问题）
  Angle N: [name] - FIXED [count] issues / 修复了 [count] 个问题
  Angle N: [name] - NOTED [count] concerns / 记录了 [count] 个关注点
When completing, output a final summary in this format:
  Plan Review Summary / 计划书审查总结:
  - Angles passed: N/4 / 通过角度：N/4
  - Issues fixed: N / 修复问题：N
  - Concerns noted: N / 记录关注点：N
  - [list each angle with result in bilingual format]
Note: the plan document itself remains in whatever language it was written in.

COMPLETION
When all items in the progress file are marked as passed:
1. Delete .claude/plan-review-progress.tmp
2. Output the bilingual summary then output <promise>PLAN_REVIEW_COMPLETE</promise>

If a problem cannot be resolved after 3 attempts within the same angle, record the
issue in the plan's Open Questions section as a known gap, mark the angle as passed
with a note, and continue with other angles.
