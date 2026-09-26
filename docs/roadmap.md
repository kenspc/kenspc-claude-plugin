# Roadmap

Planned work for the kenspc plugin. An item leaves this file when it ships;
the CHANGELOG records it from then on. The remaining items are renumbered
when one leaves, so text outside this file names an item by its subject, not
its number.

## Next minor (3.9.0)

1. Render Schema A / B / C once, in the final Schema G report, instead of
   again between dispatches in Step 3 (Mac O1).
2. Verdict asymmetry: a LOW regression brought in by a fix commit fails the
   run, while a DEFERRED MEDIUM does not. Whether to grade the verdict by
   severity is the maintainer's call (Mac O6).
3. Transcript audit scripts read `subagents/agent-<id>.jsonl`: from Claude
   Code 2.1.281 the tool_result no longer carries the report text (Mac O7).
4. Whether to merge bug-reviewer and edge-case-reviewer: decide once 3.5.x
   has three or more runs with angle-labelled data (left open in G6-b).
5. Documents synced by a Doc-sync task can go stale when a review fix
   changes the behavior they describe: code-fixer's fixes land after the
   Doc-sync task. Today Schema G's Next steps asks the user to re-check them
   (batch A review, B2). Two directions for an agent to take it over:
   code-fixer brings a listed document into scope when a fix changes the
   behavior it describes, or regression-verifier gains a check that the
   listed documents still match the code after the fix commits. Not
   shipped with 3.6.0; decide at the next release.
6. Linters and build tools still walk into `.kenspc/`. ESLint's flat config
   ignores only `node_modules` and `.git` by default; the ESLint
   configuration migration guide: "In flat config, dotfiles (e.g.
   `.dotfile.js`) are no longer ignored by default." A runner-safe probe such
   as `probe.mts` can therefore still fail `eslint .`, and no name keeps a
   source probe out of a linter's pattern. Today `regression-verifier` runs
   build and lint unmodified and names the scratch files in the FAIL;
   keeping them out of those tools is open. A prototype's files under
   `prototypes/` are in the same position between its add and remove
   commits, and a gate that walks the repository reaches them there.
7. Scratch convention follow-ups. The standalone review of the last
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
8. Smoke candidates for the prototype chain. The batch C review (T2–T7)
   proposed six release-checklist cases that the one-time acceptance
   covers but no smoke row does, and the review of its fix round proposed
   more, each marked with its ID. Each costs a headless run at every
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
   - Row 4: a brief entry whose status word is not recognized — a
     translated word such as `需要原型`, or no word — which the gap round
     quotes and asks about; with a reminder to work without stopping, the
     draft's Open Questions carries it in the `open` form, its `From:`
     ending `status word <the word> not recognized` (fix-round review, T1).
   - Row 10: a setup under which the leftovers criteria can fail — a
     prototype that installs one package into its own manifest, under an
     unanchored `node_modules` ignore pattern, and an in-app location that
     holds an untracked file of the user's before the run; `node_modules/`
     then appears as one line and the user's file not at all. Without it,
     the old `--ignored -uall` form and the new one print the same list and
     the location holds nothing before the run, so reverting the command or
     dropping the start snapshot still passes row 10 (fix-round review,
     T3).
   - Row 3: a Level 1 idea holding a question only an experiment settles,
     run with a reminder to work without stopping — the brief is written
     without asking what would settle it, and its `needs prototype`
     entry's `Settled by:` is tagged as inferred (fix-round review, T2).
9. When the prototype skill names a leftover directory once. Today a
   directory is named once, with its file count, only when every file
   under it is listed as untracked. In a project whose dependency ignore
   rule is root-anchored (`/node_modules`, the create-next-app and Create
   React App default), a prototype's own `node_modules/` is untracked, not
   ignored, and any unanchored pattern that matches inside a package
   (`dist/`, `*.log`, `*.tsbuildinfo`, `.DS_Store`) adds a `!!` line under
   it. That line blocks the collapse of `node_modules/` and of every
   directory above it, so after a dependency install the list runs to one
   line per package (fix-round review, B5/E2). The reviewer's suggested
   condition: every entry listed under the directory, untracked or
   ignored, is absent from the start-of-run list, and
   `git ls-files -- <directory>` prints nothing. The skill's Exit, the
   plugin README's leftovers item, release-checklist row 10, and a
   CHANGELOG entry change in one commit; a probe on a scratch repository
   with `/node_modules`, `dist/`, and `*.log` patterns settles the wording.
   The row and its follow-up are in
   `.kenspc/runs/20260925-234058-changes/schema-b.md` (git-ignored; only
   in the maintainer's macOS checkout). The acceptance run's O5
   (`docs/dry-runs/batch-c-acceptance.md`) already named a directory
   holding untracked and ignored files once, as that condition would.
10. Two prototype runs went outside rules the skill already states; to
    watch, not a rule gap (`docs/dry-runs/batch-c-acceptance.md`, O11 and
    O12, classified behavior deviations). One asked a question outside the
    gate table — the brief's Scope excluded any UI, and the run asked
    whether to go on or stop — where the skill says "Every question the
    skill asks is one of these gates". The other wrote its check script and
    a saved render to the session scratchpad instead of the location, so
    `git show <add commit>` does not hold the checks its `Evidence:` cites,
    where the skill says "Everything is written under the location".
11. A generate-plan gap round went outside a rule the skill already states;
    to watch, not a rule gap (`docs/dry-runs/batch-d-acceptance.md`, F2,
    classified a behavior deviation). Asking the status of two entries
    whose status words it did not recognize, the gap round asked only for
    the status, where the skill says "the question that asks an
    unrecognized entry's status also asks, for `answered`, the answer — one
    question, one round". The user replied `answered` for one of them with
    no answer text, and that entry was still carried as the rule says, into
    the plan's Open Questions in the `open` form with `Answer: missing`, so
    the plan's content was not affected.
