# Roadmap

Planned work for the kenspc plugin. An item leaves this file when it ships;
the CHANGELOG records it from then on.

## Next minor (3.6.0)

1. Render Schema A / B / C once, in the final Schema G report, instead of
   again between dispatches in Step 3 (Mac O1).
2. The scratch rule binds the orchestrator too; a "reset" creates a new
   subdirectory instead of running `rm -rf`; code-fixer and
   regression-verifier each get `scratch/<agent>/` (Mac O3, O4; TUI 3).
3. Define `REVIEW_SCOPE=changes`: the orchestrator computes the change set
   once for all five reviewers (M-F3), and a standalone review stops
   committing the user's uncommitted changes first (Windows observation 2).
4. Verdict asymmetry: a LOW regression brought in by a fix commit fails the
   run, while a DEFERRED MEDIUM does not. Whether to grade the verdict by
   severity is the maintainer's call (Mac O6).
5. Transcript audit scripts read `subagents/agent-<id>.jsonl`: from Claude
   Code 2.1.281 the tool_result no longer carries the report text (Mac O7).
6. Whether to merge bug-reviewer and edge-case-reviewer: decide once 3.5.x
   has three or more runs with angle-labelled data (left open in G6-b).
7. The reviewer invariant sentence appears in four places, but only two are
   guarded (the reviewers' ROLE sections, the canonical dispatch block).
   Add a whitespace-normalized exact-match check for README and CLAUDE.md to
   `check-run-contract.sh`.

## Planned batches

In this order. The Workbench provides each batch's spec when work starts.

- **A — doc-sync task.** Plans gain a Documentation impact element;
  generate-task opens a doc-sync task from it; decisions that surface during
  implementation are promoted through that task; task-document-reviewer
  checks consistency with CLAUDE.md.
- **B — `diagnose-bug` skill and `/kenspc-diagnose`.** Reproduce, diagnose,
  then write `docs/tasks/{name}.md` for task-implement by default; a fix that
  touches a contract, a schema, a new dependency, or config escalates to a
  brief or a plan instead.
- **C — prototypes.** Briefs gain Open Questions; generate-plan gets an exit
  for an unresolved `needs prototype`; a `prototype` skill and
  `/kenspc-prototype`.
