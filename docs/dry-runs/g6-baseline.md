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

## 3. Acceptance runs (v3.5.1, 2026-09-24)

The four runs of the v3.5.1 release acceptance. All four: session model Opus
5.5, effort `xhigh`, Claude Code 2.1.281.

| Run | Reported | Unique after dedup | FIXED | DEFERRED | NOT APPLICABLE | Notes |
|---|---|---|---|---|---|---|
| macOS headless, `/kenspc-task-implement` | 15 (R 2, E 5, Q 1, B 3, T 4) | 11 | 10 | 1 | 0 | 0 HIGH; both MEDIUM fixed |
| macOS headless, `/kenspc-task-review` | 8 | 6 | 3 | 3 | 0 | Unique count derived from the identities: 3 + 3 + 0 = 6, so DEDUPED 2 |
| Windows, `/kenspc-task-review` | 8 (R 0, E 2, Q 1, B 2, T 3) | 6 | 3 | 3 | 0 | The 3 DEFERRED items need tests the target project does not have |
| TUI, `/kenspc-task-review` | 8 (R 2, E 1, Q 2, B 1, T 2) | 4 | 1 | 3 | 0 | |

Compared with section 1:

| Measure | Pre-G6 | v3.5.1 acceptance runs |
|---|---|---|
| NOT APPLICABLE share | about 20% | 0 in all four runs |
| HIGH handled | 12 of 12 (100%) | 100% |

MEDIUM fix rate, LOW share, and LOW fix rate were not recorded per run, so
they are not compared here.
