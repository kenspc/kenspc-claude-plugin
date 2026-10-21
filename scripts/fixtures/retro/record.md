# Retro record — 2026-09-30

## Window and coverage

Window: 2026-09-01T10:00:00 to 2026-09-28T16:30:00
- Window spec: `last 20`; 20 batches, 41 runs.
- Coverage: 20 batches with a timeline, 104 role sessions read, 0 with an unmeasured subagent split, 0 with no .exit.
- Worktrees read: `/fixture/repo` (41 run directories).
- Check commands: `bash scripts/check-all.sh`.

## Follow-up

No previous record.

## Kinds

| kind | definition |
|---|---|
| test-gap | No test fails when a branch, guard, or limit the change adds is removed; wins over doc-drift when a test claims the behavior. |
| doc-drift | A document or comment describes behavior the code does not have. |
| stale-check | A check script still passes after the behavior it guards changed. |
| one-batch | A problem that only one batch could have. |
| other | No kind fits. |

## Adopted

### A1: Require a failing-capable test for each new branch

- Item: kind `test-gap`, 3 batches, cost 15.
- Measure: kind `test-gap` cost = 15
- Where it went wrong: `20260910-100000-a-tasks#3`, `20260915-100000-b-tasks#1`; 7 rows in 3 batches.
- Changes: `AGENTS.md` § Tests, layer 6, since no check can see a missing test.
- Next batch: the implementer writes the test with the branch.
- Undo: `git revert 1111111`
- Commit: 1111111
- Expected effect: the kind's cost falls by up to 6, its ceiling in this window.

### A2: Start S2 from the plan's step list

- Item: time `s2`, 2 batches, 24.0 minutes.
- Measure: time `s2` minutes per batch = 12.0
- Where it went wrong: S2 re-read the brief in both batches.
- Changes: `docs/autopilot-notes.md`, layer 5.
- Next batch: S2 reads the plan only.
- Undo: `git revert 2222222`
- Commit: 2222222
- Expected effect: about 2 minutes per batch.

## Rejected

### R1: Lint every Markdown link

- Item: kind `doc-drift`, 2 batches, cost 4.
- Batches: kind `doc-drift` = 2
- Reason: the links are checked at release.

### R2: Re-run each check script after its target changes

- Item: kind `stale-check`, 1 batch, cost 2.
- Batches: kind `stale-check` = 1
- Reason: one batch is not a pattern yet.

## Dropped by verification

### D1: Split code-fixer's dispatches

- Reason: FAILS — `20260912-100000-c-tasks/schema-b.md:9` shows the rows were fixed in one dispatch.

## Pending

### P1: Name the test file in each task

- Item: kind `test-gap`, 3 batches, cost 15.
- Measure: kind `test-gap` cost = 99
- Batches: kind `test-gap` = 1

## Failed

### F1: Add a pre-commit link check

- Item: kind `doc-drift`, 2 batches, cost 4.
- Batches: kind `doc-drift` = 9
- Failing check: `bash scripts/check-all.sh` exited 1: `FAIL scripts/check-json.sh`.

## Runner-ups

- findings `one-batch`: cost 3, within 10% of the last selected cost 3.

## For the kenspc plugin

none

## For your global files

none
