# Finding-classification stability

Window rows: 365.
Run A: {'missing': 0, 'unknown keys': 0, 'duplicates': 0}; kinds used 25; rows `other` 15; new kinds 1: new:unbounded-read.
Run B: {'missing': 0, 'unknown keys': 0, 'duplicates': 0}; kinds used 24; rows `other` 15; new kinds 0: none.

### A: top 8 under the bar

| rank | kind | cost | rows | batches |
|---|---|---|---|---|
| 1 | untested-rule | 92 | 60 | 17 |
| 2 | pattern-departure | 44 | 39 | 14 |
| 3 | doc-claim-untrue | 40 | 30 | 14 |
| 4 | untested-failure-path | 38 | 24 | 13 |
| 5 | stale-client-state | 37 | 25 | 7 |
| 6 | unasserted-output | 32 | 26 | 8 |
| 7 | untested-concurrency-guard | 30 | 20 | 10 |
| 8 | concurrency-race | 22 | 12 | 5 |

### B: top 8 under the bar

| rank | kind | cost | rows | batches |
|---|---|---|---|---|
| 1 | untested-rule | 89 | 59 | 17 |
| 2 | pattern-departure | 42 | 38 | 14 |
| 3 | doc-claim-untrue | 41 | 32 | 14 |
| 4 | stale-client-state | 36 | 24 | 7 |
| 5 | untested-failure-path | 36 | 24 | 13 |
| 6 | unasserted-output | 33 | 26 | 10 |
| 7 | untested-concurrency-guard | 31 | 20 | 10 |
| 8 | concurrency-race | 22 | 12 | 5 |

### manual: top 8 under the bar

| rank | kind | cost | rows | batches |
|---|---|---|---|---|
| 1 | test-portal-other | 44 | 30 | 9 |
| 2 | test-api-other | 33 | 20 | 7 |
| 3 | test-portal-failure-state | 30 | 21 | 8 |
| 4 | doc-decision-record-stale | 29 | 22 | 12 |
| 5 | test-portal-presentation | 27 | 22 | 6 |
| 6 | portal-query-state | 27 | 19 | 8 |
| 7 | test-weak-or-flaky | 19 | 16 | 10 |
| 8 | test-portal-cache-reread | 19 | 12 | 7 |

## Verdict

- Top five shared by A and B: 5 of 5 (settled by: at least 4).
- Row overlap for untested-rule: 52/67 = 78% (settled by: at least 60%).
- Row overlap for pattern-departure: 37/40 = 92% (settled by: at least 60%).
- Row overlap for doc-claim-untrue: 29/33 = 88% (settled by: at least 60%).
- Row overlap for untested-failure-path: 20/28 = 71% (settled by: at least 60%).
- Row overlap for stale-client-state: 23/26 = 88% (settled by: at least 60%).
- Result: PASS.
- Reading only, per-row agreement A vs B: 324/365 = 89%.

## Reading only: where each top-five kind's rows sit in the manual classification

- A untested-rule (60 rows): test-portal-other 17, test-api-other 14
- A pattern-departure (39 rows): pattern-deviation 14, code-style-mechanical 10
- A doc-claim-untrue (30 rows): doc-decision-record-stale 19, doc-other-stale 8
- A untested-failure-path (24 rows): test-portal-failure-state 14, test-api-refusal-path 5
- A stale-client-state (25 rows): portal-query-state 17, portal-late-answer 4
- B untested-rule (59 rows): test-portal-other 21, test-api-other 14
- B pattern-departure (38 rows): pattern-deviation 14, code-style-mechanical 10
- B doc-claim-untrue (32 rows): doc-decision-record-stale 19, doc-other-stale 9
- B stale-client-state (24 rows): portal-query-state 16, portal-late-answer 4
- B untested-failure-path (24 rows): test-portal-failure-state 16, test-api-refusal-path 6
