## Fixes Applied

| # | Source | short_label | Severity | File:Line | Action | Commit |
|---|--------|-------------|----------|-----------|--------|--------|
| 1 | T1 | parser test misses the escaped pipe | **MEDIUM** | src/parse.ts:12 | **FIXED** | aaa1111 |
| 2 | R1, B2 | export skips the empty list | LOW | src/export.ts:40 | DEFERRED — ruled | — |
| 3 | F1 | fixer left a stale import | `LOW` | src/export.ts:3 | FIXED — ruled; import removed | bbb2222 |

## Per-angle Results

| Angle | Findings |
|-------|----------|
| 1 | 1 |
| 5 | 1 |

total reported 4 (R 1, E 0, Q 0, B 1, T 1, F 1, V 0), deduplicated to 3 unique, FIXED 2, DEFERRED 1, NOT APPLICABLE 0, DEDUPED 1
