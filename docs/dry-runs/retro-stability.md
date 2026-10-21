# Retro classification stability at 120-row slices (4.14.0)

The prototype's stability check (brief entry 1, prototype `78e797e`), re-run
on 2026-10-21 at the shipped slice size, `SLICE_ROWS = 120`, against
`4fe671b`. The prototype classified 61-row slices; this run checks that
slices twice that size still rank the same top kinds.

## Command

One headless top-level session in the scratch directory
`~/Projects/_smoke/retro-stability/run1/`, launched detached:

```
claude -p "<prompt>" --output-format json \
  --plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc \
  --permission-mode acceptEdits --allowedTools=Bash
```

Session `c1653b8c-4d39-408a-9d7b-2ee7bf043adb`, 21 turns, about 5 minutes.
The installed plugin (4.13.0) has no `retro-classifier`, so the dispatches
ran the `--plugin-dir` copy. The prompt had the session:

1. run `extract_findings.py`, `map_runs.py` (window `last 20`), and
   `slice_findings.py` on `~/Projects/Diagnohab/dayaku-crm`: 20 batches, 45
   runs, 365 in-window rows, 4 slices of at most 120 rows (120, 120, 120,
   5), and a 200-row sample;
2. make one `retro-classifier` `derive` dispatch on the sample: 24 kinds;
3. run A: one `classify` dispatch per slice, in run order;
4. run B: the same 365 rows shuffled with seed 42 into 4 fresh 120-row
   slices, one fresh `classify` dispatch per slice, the same `kinds.tsv`;
5. run the prototype's `rank.py`
   (`git show 78e797e:prototypes/finding-classification/rank.py`) on run
   A's labels as `labels-A-<n>.tsv`, run B's as `labels-B-<n>.tsv`,
   `window.tsv` (key, batch, severity: `findings.tsv` joined to
   `runs.tsv`), and `manual.tsv` (key, kind from the manual retro's
   `categories.tsv`; no window row missing).

No dispatch refused or left its labels file missing. `rank.py`'s label
check: run A 0 missing, 0 unknown keys, 0 duplicates, 26 kinds used, 9 rows
`other`, new kinds `new:check-not-wired`, `new:secret-in-error-output`; run B
0 missing, 0 unknown keys, 0 duplicates, 25 kinds used, 8 rows `other`, new
kind `new:unused-code`.

## Top five under the bar

Run A:

| rank | kind | cost | rows | batches |
|---|---|---|---|---|
| 1 | untested-rule | 75 | 49 | 15 |
| 2 | untested-failure-path | 37 | 24 | 12 |
| 3 | untested-state-reset | 31 | 22 | 8 |
| 4 | untested-rendered-detail | 27 | 22 | 7 |
| 5 | unverified-record | 27 | 21 | 12 |

Run B:

| rank | kind | cost | rows | batches |
|---|---|---|---|---|
| 1 | untested-rule | 73 | 47 | 16 |
| 2 | untested-failure-path | 40 | 26 | 14 |
| 3 | untested-state-reset | 31 | 22 | 7 |
| 4 | untested-rendered-detail | 30 | 24 | 7 |
| 5 | stale-document | 27 | 22 | 13 |

Run A's sixth is `stale-document` at cost 26, and run B's seventh is
`unverified-record` at 25: the fifth place is the near-tie at the cut that
`rank.py`'s runner-up line exists for.

## Verdict, as `rank.py` printed it

- Top five shared by A and B: 4 of 5 (settled by: at least 4).
- Row overlap for untested-rule: 43/53 = 81% (settled by: at least 60%).
- Row overlap for untested-failure-path: 23/27 = 85% (settled by: at least 60%).
- Row overlap for untested-state-reset: 21/23 = 91% (settled by: at least 60%).
- Row overlap for untested-rendered-detail: 21/25 = 84% (settled by: at least 60%).
- Result: PASS.
- Reading only, per-row agreement A vs B: 333/365 = 91%.

`SLICE_ROWS` stays 120.

## Cost

USD 3.98 for the session, subagents included (the json's
`total_cost_usd`). The nine subagents used 1,336,258 tokens, summed from
their transcripts' `usage` (input 68, cache creation 418,178, cache read
859,222, output 58,790):

| dispatch | tokens |
|---|---|
| derive (200 rows) | 200,201 |
| run A slices 1–3 (120 rows each) | 162,117; 167,316; 183,975 |
| run A slice 4 (5 rows) | 54,963 |
| run B slices 1–3 (120 rows each) | 171,620; 170,989; 170,652 |
| run B slice 4 (5 rows) | 54,425 |

A 120-row slice cost 162–184 k tokens against the prototype's about 95 k
for 61 rows; the 5-row slices show the fixed part per dispatch, about 55 k.
