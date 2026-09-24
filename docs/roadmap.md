# Roadmap

Planned work for the kenspc plugin. An item leaves this file when it ships;
the CHANGELOG records it from then on.

## Next minor (3.6.0)

At release, delete `docs/plans/batch-a-doc-sync.md`,
`docs/tasks/batch-a-doc-sync-tasks.md`,
`docs/plans/roadmap-9-scratch-probes.md`, and
`docs/tasks/roadmap-9-scratch-probes-tasks.md`; batch A and the scratch-probe
work (former items 2 and 9) have shipped.

1. Render Schema A / B / C once, in the final Schema G report, instead of
   again between dispatches in Step 3 (Mac O1).
2. Define `REVIEW_SCOPE=changes`: the orchestrator computes the change set
   once for all five reviewers (M-F3), and a standalone review stops
   committing the user's uncommitted changes first (Windows observation 2).
3. Verdict asymmetry: a LOW regression brought in by a fix commit fails the
   run, while a DEFERRED MEDIUM does not. Whether to grade the verdict by
   severity is the maintainer's call (Mac O6).
4. Transcript audit scripts read `subagents/agent-<id>.jsonl`: from Claude
   Code 2.1.281 the tool_result no longer carries the report text (Mac O7).
5. Whether to merge bug-reviewer and edge-case-reviewer: decide once 3.5.x
   has three or more runs with angle-labelled data (left open in G6-b).
6. The reviewer invariant sentence appears in four places, but only two are
   guarded (the reviewers' ROLE sections, the canonical dispatch block).
   Add a whitespace-normalized exact-match check for README and CLAUDE.md to
   `check-run-contract.sh`.
7. Documents synced by a Doc-sync task can go stale when a review fix
   changes the behavior they describe: code-fixer's fixes land after the
   Doc-sync task. Today Schema G's Next steps asks the user to re-check them
   (batch A review, B2). Two directions for an agent to take it over:
   code-fixer brings a listed document into scope when a fix changes the
   behavior it describes, or regression-verifier gains a check that the
   listed documents still match the code after the fix commits. Decide at
   release whether this ships with 3.6.0.
8. Linters and build tools still walk into `.kenspc/`. ESLint's flat config
   ignores only `node_modules` and `.git` by default; the ESLint
   configuration migration guide: "In flat config, dotfiles (e.g.
   `.dotfile.js`) are no longer ignored by default." A runner-safe probe such
   as `probe.mts` can therefore still fail `eslint .`, and no name keeps a
   source probe out of a linter's pattern. Today `regression-verifier` runs
   build and lint unmodified and names the scratch files in the FAIL;
   keeping them out of those tools is open.

## Planned batches

In this order. A design session — in the KENSPC Workbench or in Claude Code — provides each batch's spec when work starts.

- **B — `diagnose-bug` skill and `/kenspc-diagnose`.** Reproduce, diagnose,
  then write `docs/tasks/{name}.md` for task-implement by default; a fix that
  touches a contract, a schema, a new dependency, or config escalates to a
  brief or a plan instead.
- **C — prototypes.** Briefs gain Open Questions; generate-plan gets an exit
  for an unresolved `needs prototype`; a `prototype` skill and
  `/kenspc-prototype`.
