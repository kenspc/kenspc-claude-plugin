# Roadmap

Planned work for the kenspc plugin. An item leaves this file when it ships;
the CHANGELOG records it from then on. The remaining items are renumbered
when one leaves, so text outside this file names an item by its subject, not
its number.

## Next minor (3.8.0)

1. Render Schema A / B / C once, in the final Schema G report, instead of
   again between dispatches in Step 3 (Mac O1).
2. Verdict asymmetry: a LOW regression brought in by a fix commit fails the
   run, while a DEFERRED MEDIUM does not. Whether to grade the verdict by
   severity is the maintainer's call (Mac O6).
3. Transcript audit scripts read `subagents/agent-<id>.jsonl`: from Claude
   Code 2.1.281 the tool_result no longer carries the report text (Mac O7).
4. Whether to merge bug-reviewer and edge-case-reviewer: decide once 3.5.x
   has three or more runs with angle-labelled data (left open in G6-b).
5. The reviewer invariant sentence appears in four places, but only two are
   guarded (the reviewers' ROLE sections, the canonical dispatch block).
   Add a whitespace-normalized exact-match check for README and CLAUDE.md to
   `check-run-contract.sh`.
6. Documents synced by a Doc-sync task can go stale when a review fix
   changes the behavior they describe: code-fixer's fixes land after the
   Doc-sync task. Today Schema G's Next steps asks the user to re-check them
   (batch A review, B2). Two directions for an agent to take it over:
   code-fixer brings a listed document into scope when a fix changes the
   behavior it describes, or regression-verifier gains a check that the
   listed documents still match the code after the fix commits. Not
   shipped with 3.6.0; decide at the next release.
7. Linters and build tools still walk into `.kenspc/`. ESLint's flat config
   ignores only `node_modules` and `.git` by default; the ESLint
   configuration migration guide: "In flat config, dotfiles (e.g.
   `.dotfile.js`) are no longer ignored by default." A runner-safe probe such
   as `probe.mts` can therefore still fail `eslint .`, and no name keeps a
   source probe out of a linter's pattern. Today `regression-verifier` runs
   build and lint unmodified and names the scratch files in the FAIL;
   keeping them out of those tools is open. A prototype's files under
   `prototypes/` are in the same position between its add and remove
   commits, and a gate that walks the repository reaches them there.
8. Scratch convention follow-ups. The standalone review of the last
   scratch-probe commits (`f42bd21`, `99574bb`, `979688e`) found no HIGH
   issue and, under that plan's stop rule, deferred 14 findings, 9 MEDIUM
   and 5 LOW, with no further round. The rows and each one's suggested
   follow-up are in `.kenspc/runs/20260924-231237-changes/schema-b.md`
   (git-ignored; only in the maintainer's macOS checkout). MEDIUM:
   - a control mutant that keeps passing has no stated outcome, and which
     module it must break is not stated;
   - a mutation check reported as not made has no place in Schema A or B,
     and regression-verifier's "not mutation-checked" none in Schema C;
   - when the test row is FAIL, the Next steps delete bullet cannot tell
     which collected `.kenspc/` files passed;
   - a reviewer re-dispatched into the same run reuses scratch attempt
     `1/`;
   - the release target's tests need not depend on its setup file or
     `globals`, so the baseline sub-check can pass vacuously;
   - no release sub-check tests the numbered-attempt layout;
   - CLAUDE.md's `--plugin-dir` editing rule has no CHANGELOG line.
   LOW: CLAUDE.md's run-dir paragraph omits the numbered attempts and the
   rename condition; smoke rows 6 and 7 omit the delete bullet; the baseline
   sub-check is silent on a retried baseline; the CHANGELOG's "check 4" can
   read as Schema C row 4; the worker agents' runner config sits outside
   the attempt directory.
   From the acceptance run (`docs/dry-runs/scratch-probes-acceptance.md`
   § 7):
   - O2: `schema-b.md` carried a `## Verification` section between the
     Deferred Issues prose and the statistics line, which code-fixer's
     OUTPUT FORMAT does not list; the recount guard passes it, and the
     Schema F rendering dropped it;
   - O3: angle 1 rooted each mutant's runner config at the mutant's
     subdirectory while its baseline ran under the attempt-level config, so
     the baseline and the mutants did not run under the same config file;
   - O4: regression-verifier copied the `test/` tree with its collectable
     names and renamed them in the next statement, against ruling M3's "as
     they are copied"; code-fixer renamed as it copied;
   - O5: a scratch runner config without `cacheDir` leaves vite's cache at
     `scratch/<agent>/1/node_modules/.vite/`;
   - O6: the lint and build paths of the unmodified-command rule are
     untested by any acceptance run — the target project had neither
     script, so the build row was a PASS that could not fail.
   From the same report's § 6 precedent table: task-implementer has no
   scratch convention at all — it runs before the run directory exists —
   and in batch A it ran its mutation checks on the project's own `src/`
   files in place (`sed -i`, `.bak` copies in the session scratchpad, `cp`
   to restore), so a run that stops between the mutation and the restore
   leaves the user's source mutated.
   From the batch B acceptance (`docs/dry-runs/batch-b-acceptance.md`,
   F2): regression-verifier named a log `test.out` under its scratch
   attempt, which the release checklist's name probe flags although vitest
   collected nothing; the RUN_DIR bullet already forbids `test.*`, so this
   is a behavior slip to watch, not a rule gap.
9. Smoke candidates for the prototype chain. The batch C review (T2–T7)
   proposed six release-checklist cases that the one-time acceptance
   covers but no smoke row does. Each costs a headless run at every
   release, so whether any joins its row is the maintainer's call:
   - Row 10: a session that cannot ask — with no entry named on a brief
     holding two `needs prototype` entries, the run takes the first and
     names it; a table-creating run uses a throwaway database, names it,
     and leaves the development database file unchanged.
   - Row 10: the judgment point — the run waits after the add commit, says
     how to see the prototype, and `Evidence:` says the user judged it; a
     session that cannot ask leaves the entry `needs prototype` with
     `Evidence:` naming what to look at, and the remove commit's body
     carries `Not settled:`.
   - Row 10: a failed commit, on a seed project whose pre-commit hook exits
     1 — no retry and no `--no-verify`, no add commit, the staged paths and
     `git reset -q --` named; a rejected remove commit names the add commit
     and says the removal is staged.
   - Row 10: a question given as text for a brief with no
     `## Open Questions` — the section created after `## Context`, the
     entry `needs prototype` with `Settled by:`, nothing else in the brief
     changed.
   - Row 3: a Chinese run whose `## Open Questions` heading, status words,
     and labels stay in English; row 4 on that brief then asks the exit
     question.
   - Row 4: a brief with an `answered` entry, whose short hash the plan
     cites where it relies on it, and a brief whose section body is `none`,
     which gets no exit question.

## Planned batches

In this order. A design session — in the KENSPC Workbench or in Claude Code — provides each batch's spec when work starts.

- **C — prototypes.** Briefs gain Open Questions; generate-plan gets an exit
  for an unresolved `needs prototype`; a `prototype` skill and
  `/kenspc-prototype`.
