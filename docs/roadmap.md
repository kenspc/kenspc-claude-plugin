# Roadmap

Planned work for the kenspc plugin. An item leaves this file when it ships;
the CHANGELOG records it from then on.

## Next minor (3.6.0)

At release, delete `docs/plans/batch-a-doc-sync.md` and
`docs/tasks/batch-a-doc-sync-tasks.md`; batch A has shipped.

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
8. Documents synced by a Doc-sync task can go stale when a review fix
   changes the behavior they describe: code-fixer's fixes land after the
   Doc-sync task. Today Schema G's Next steps asks the user to re-check them
   (batch A review, B2). Two directions for an agent to take it over:
   code-fixer brings a listed document into scope when a fix changes the
   behavior it describes, or regression-verifier gains a check that the
   listed documents still match the code after the fix commits. Decide at
   release whether this ships with 3.6.0.
9. **Required before tagging.** Probe files that the reviewers, code-fixer,
   and regression-verifier write under `RUN_DIR/scratch/` must not match the
   project test runner's collection pattern — vitest and jest collect
   `**/*.{test,spec}.*` by default. Use an extension no runner collects,
   such as `.txt`. A probe that has to execute runs as a plain script, or
   through a runner config kept in the scratch directory that includes only
   the probe (angle-2's method in the acceptance run: `--config` pointing at
   a private vitest config). A copy of the whole `test/` tree is no
   exception. Verify the filtering rules of vitest and jest when
   implementing.
   Evidence: `docs/dry-runs/batch-a-acceptance.md` § 8 — 68 probe files made
   a bare `npm test` fail, code-fixer added a `vitest.config.ts` to the
   user's project to make room for the plugin's probes, and five agents each
   worked around the collision their own way. The change edits the five
   reviewers' shared sections and the canonical blocks that state the
   scratch rule (dispatch, run-dir), so it goes through the byte-identity
   guards and is not folded into batch A.

## Planned batches

In this order. The Workbench provides each batch's spec when work starts.

- **B — `diagnose-bug` skill and `/kenspc-diagnose`.** Reproduce, diagnose,
  then write `docs/tasks/{name}.md` for task-implement by default; a fix that
  touches a contract, a schema, a new dependency, or config escalates to a
  brief or a plan instead.
- **C — prototypes.** Briefs gain Open Questions; generate-plan gets an exit
  for an unresolved `needs prototype`; a `prototype` skill and
  `/kenspc-prototype`.
