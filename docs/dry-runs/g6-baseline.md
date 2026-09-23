# G6 baseline — reviewer-layer rightsizing (v3.5.0)

Acceptance record for G6 (G6-a through G6-f, shipped in v3.5.0). This file
records numbers; it does not set thresholds. One exception: a HIGH handling
rate below 100% in an acceptance run counts as a regression, and the G6-a
output-policy wording in the five review-angle agents is the first place to
look.

Schema B does not carry the session's model or effort, so every run below
records both by hand.

## 1. Pre-G6 baseline (v3.4.x)

Nine `/kenspc-task-implement` runs, 2026-06-29 to 2026-09-08, 452 findings
across their Schema B accountability lists (figures from the G6 spec).

| Measure | Value |
|---|---|
| Session models | Opus 4.8, Fable 5, Opus 5 |
| HIGH | 37 reported, 12 after deduplication, 12 of 12 handled |
| MEDIUM fix rate | 59% |
| LOW share of all findings | 64% (289 of 452) |
| LOW fix rate | 13% |
| NOT APPLICABLE | 88 of the LOW findings judged NOT APPLICABLE by code-fixer (about 20% of all findings); rate 33% on Fable 5, 11% on Opus 5 |

## 2. Single-agent pre-check (2026-09-23, sample size 1)

A smoke comparison run before the acceptance run. It exercises one reviewer
in isolation, not the orchestrated workflow, and one sample says nothing
about rates. Kept for context only; not cited in the CHANGELOG.

| Field | Value |
|---|---|
| Command | `claude -p --plugin-dir <plugin> --agent kenspc:bug-reviewer` |
| Claude Code | 2.1.280 |
| Session model | CLI default (no `model` pinned in settings; the resolved model was not captured) |
| Effort | `xhigh` (`effortLevel` in user settings) |
| Permission mode | `acceptEdits` (so an unwanted write would have succeeded and been visible) |
| Input | A one-file JavaScript repo with two seeded defects in an uncommitted change: a loop bound changed from `<` to `<=`, and `if (code = "HALF")` |
| CONTEXT | `TASK_FILE: N/A`, `REVIEW_SCOPE: changes`, `CUSTOM_INSTRUCTIONS: N/A`; no `RUN_DIR` unless stated |

| Plugin | HIGH | MEDIUM | LOW | Total | Seeded HIGHs found | Files written |
|---|---|---|---|---|---|---|
| v3.4.3 (80eefbc) | 2 | 2 | 5 | 9 | 2 of 2 | none |
| v3.5.0 tree (660a585), no `RUN_DIR` | 2 | 0 | 0 | 2 | 2 of 2 | none |
| v3.5.0 tree (660a585), with `RUN_DIR` | 2 | 0 | 1 | 3 | 2 of 2 | `angle-4.md` only |

Without a CONTEXT block, both versions refused and printed the same usage
block in three samples each; the wording around the block varied from run to
run in both versions.

## 3. Acceptance run (to fill in)

Run `/kenspc-task-implement` or `/kenspc-task-review` on a non-trivial change
in a real project, from the repository root, in `acceptEdits` or `auto` mode.

| Field | Value |
|---|---|
| Date | |
| Project and change | |
| Command | |
| Claude Code version | |
| Session model | |
| Effort | |
| Permission mode | |
| Platform | |
| Run directory | |
| Files in the run directory | (expect `angle-1.md` … `angle-5.md`, `schema-b.md`) |
| `.gitignore` commit | (first run in the repo: one commit touching only `.gitignore`; later runs: none) |
| `bash scripts/check-run-contract.sh --file <run dir>/schema-b.md` | (exit code) |
| Schema C row 1 | (result and detail; expect no "unnamed" or "unconfirmed" rows) |

Per-angle Results (paste from `schema-b.md`):

| Angle | FIXED | DEFERRED | NOT APPLICABLE | DEDUPED | Reported |
|---|---|---|---|---|---|
| R | | | | | |
| E | | | | | |
| Q | | | | | |
| B | | | | | |
| T | | | | | |

Statistics line (paste):

```
total reported N (R n, E n, Q n, B n, T n), deduplicated to N unique, FIXED N, DEFERRED N, NOT APPLICABLE N, DEDUPED N
```

Compared with section 1:

| Measure | Pre-G6 | This run |
|---|---|---|
| HIGH handled | 12 of 12 (100%) | |
| MEDIUM fix rate | 59% | |
| LOW share of all findings | 64% | |
| LOW fix rate | 13% | |
| NOT APPLICABLE share | about 20% | |

Notes:
