Plan document: {{PLAN_PATH}}
Project path: {{PROJECT_PATH}}

OBJECTIVE
Review the generated plan to ensure it is feasible, complete, consistent, and clear
enough to be directly executed. Fix any issues found directly in the plan document.
Track every change you make so you can report them at the end.

PREREQUISITES
1. Read the plan document in full.
2. If {{PROJECT_PATH}} is not "N/A":
   - Read CLAUDE.md for project conventions, tech stack, and constraints.
   - Scan the project structure and key config files (package.json, *.csproj,
     docker-compose.yml, .env.example, etc.).

REVIEW ANGLES
Review all four angles in order (each angle builds on fixes from the previous one):

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

EXECUTION FLOW
For each angle, in order from 1 to 4:
1. ULTRATHINK to thoroughly review the current angle.
2. No issues found → record the angle as passed.
3. Objective issue found → fix it directly in the plan document. Record what you
   changed and why (one line per change).
4. Subjective concern found → add it to the Risks or Open Questions section.
   Record what you noted and why.
5. After all fixes for this angle, re-read affected sections to verify correctness.
6. Proceed to the next angle (which will see the fixes you just made).

OUTPUT LANGUAGE
All summaries must be bilingual (English + Chinese).
The plan document itself remains in whatever language it was written in.

COMPLETION
When all four angles have been reviewed, output a final summary in this format:

---
Plan Review Summary / 计划书审查总结

Angles: [list each angle with PASSED or FIXED or NOTED status]
  Angle 1: Feasibility & Execution Order - PASSED / 通过
  Angle 2: Completeness - FIXED 2 issues / 修复了 2 个问题
  ...

Changes made / 修改内容:
(List every change. Each entry must state WHAT was changed and WHY.)
  - [Angle N] Changed X → Y. Reason: ... / 原因：...
  - [Angle N] Added section Z. Reason: ... / 原因：...
  - [Angle N] Noted concern about W in Open Questions. Reason: ... / 原因：...

If no changes were made, state: No changes needed / 无需修改
---

If a problem cannot be resolved after 3 attempts within the same angle, record the
issue in the plan's Open Questions section as a known gap, note it in the summary,
and continue with other angles.
