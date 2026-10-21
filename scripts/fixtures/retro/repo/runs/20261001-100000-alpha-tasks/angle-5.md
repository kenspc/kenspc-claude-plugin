# Angle 5: Test Coverage

## Findings

| Severity | Count |
|----------|-------|
| HIGH     | 0     |
| MEDIUM   | 1     |
| LOW      | 0     |

## Issues

| # | Severity | Confidence | File:Line | One-line description |
|---|----------|------------|-----------|----------------------|
| T1 | MEDIUM | high | src/parse.ts:12 | No test splits a row whose cell holds a \| b outside code or `a \| b` inside it, so a split on every pipe passes. |
