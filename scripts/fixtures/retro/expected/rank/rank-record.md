# Ranking

Window: 2026-10-01T10:00:00 to 2026-10-04T10:00:00; 4 batches, 1 of them a manual run.

## Label check

- in-window rows: 17
- labelled: 16
- unlabelled: 1 (`20261003-100000-b3-tasks#4`)
- labels outside kinds.tsv: 0 (none)
- labels outside the window: 2
- duplicate labels: 1
- unknown severity: 0

## New kinds

| label | batches | resolved to |
|---|---|---|
| new:lock-leak | b3 | unresolved |
| new:port-race | b1 | test-gap |
| new:typo-fix | b1 | other |

## De-duplication merges

- `20261001-100000-b1-tasks#1` (s3, DEFERRED) absorbs `20261001-120000-changes#1` (s3b): kind test-gap, file src/a.ts

## Selected

1. findings `test-gap`: cost 11, 3 of 4 batches, 2.75 cost per batch
2. findings `stale-check`: cost 3, 2 of 4 batches, 0.75 cost per batch, includes a manual run; rejected: batches 1 of 20 then (5%), 2 of 4 now (50%)
3. time `s3`: cost 200.0, 2 of 4 batches, 100.0 minutes per batch
4. time `s3/kenspc:task-implementer`: cost 100.0, 2 of 4 batches, 50.0 minutes per batch
5. time `s3/kenspc:code-fixer`: cost 90.0, 2 of 4 batches, 45.0 minutes per batch

## Runner-ups

none

## Findings list

| rank | kind | cost | rows | batches | manual | selected | record |
|---|---|---|---|---|---|---|---|
| 1 | test-gap | 11 | 5 | 3 |  | yes |  |
| 2 | doc-drift | 4 | 3 | 2 |  |  | rejected: batches 1 of 2 then (50%), 2 of 4 now (50%); skipped |
| 3 | stale-check | 3 | 2 | 2 | yes | yes | rejected: batches 1 of 20 then (5%), 2 of 4 now (50%) |

## Time list

| rank | item | minutes | share | batches | selected | record |
|---|---|---|---|---|---|---|
| 1 | s3 | 200.0 | 60% | 2 | yes |  |
| 2 | s3/kenspc:task-implementer | 100.0 | 30% | 2 | yes |  |
| 3 | s3/kenspc:code-fixer | 90.0 | 27% | 2 | yes |  |
| 4 | s3b | 80.9 | 24% | 2 |  |  |
| 5 | s2 | 20.0 | 6% | 2 |  |  |
| 6 | s3/other | 10.0 | 3% | 2 |  |  |

## Follow-up

Previous record `record.md`, window 2026-09-01T10:00:00 to 2026-09-28T16:30:00.

| item | measure | then | now |
|---|---|---|---|
| kind `test-gap` | cost per batch | 0.75 | 2.75 |
| time `s2` | minutes per batch | 12.0 | 10.0 |

## Keys

- kind `test-gap`: 20261001-100000-b1-tasks#1 20261001-100000-b1-tasks#3 20261002-100000-b2-tasks#1 20261002-120000-changes#1 20261003-100000-b3-tasks#1
- kind `doc-drift`: 20261001-100000-b1-tasks#2 20261001-120000-changes#2 20261002-100000-b2-tasks#2
- kind `stale-check`: 20261002-120000-changes#2 20261004-100000-changes#1
- time `s3`: b1 b2
- time `s3/kenspc:task-implementer`: b1 b2
- time `s3/kenspc:code-fixer`: b1 b2
- time `s3b`: b1 b2
- time `s2`: b1 b2
- time `s3/other`: b1 b2
