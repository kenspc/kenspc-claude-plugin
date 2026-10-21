# Extraction notes

Findings: 12 rows from 6 runs (FIXED 6, DEFERRED 5, NOT APPLICABLE 1).

## Worktrees read

- `<work>/repo`: 3 run directories with a schema-b.md
- `<work>/wt`: 3 run directories with a schema-b.md

## Anomalies (extract_findings.py)

- `20261001-100000-alpha-tasks`: also in <work>/repo; the copy in <work>/wt was not read
- `20261002-090000-changes`: missing angle file angle-2.md
- `20261002-090000-changes` schema-b.md:7: Source ID Q4 has no angle row in angle-3.md
- `20261002-090000-changes`: recount mismatch: the stats line says 4 unique, FIXED 2, DEFERRED 1, NOT APPLICABLE 1; the rows give 3, FIXED 1, DEFERRED 1, NOT APPLICABLE 1
- `20261004-120000-beta-tasks` schema-b.md:5: 8 cells, its header has 7
- `20261004-120000-beta-tasks` schema-b.md:7: `#` cell is not a number ('x')
- `20261004-120000-beta-tasks` schema-b.md:8: Source ID X1 names no angle
- `20261004-120000-beta-tasks` schema-b.md:9: unreadable Source ID '—'
- `20261004-120000-beta-tasks` schema-b.md:11: table header lacks source, short_label, file:line; table skipped
- `20261004-120000-beta-tasks`: recount mismatch: the stats line says 4 unique, FIXED 2, DEFERRED 2, NOT APPLICABLE 0; the rows give 3, FIXED 1, DEFERRED 2, NOT APPLICABLE 0
- `20261005-070000-nostats-tasks`: schema-b.md does not end with a stats line
