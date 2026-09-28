# Batch I acceptance — the autopilot passes each worker's model and effort (4.2.0, unreleased)

Acceptance record for batch I (spec: `docs/plans/batch-i-autopilot-model-effort.md`):
the eight cases of the spec's `## Autopilot` `Acceptance:` field and its
clarifications — the seventh case listed there is case 7 here, the case the
clarifications added is case 8 — run headless on one machine, macOS,
2026-09-28, 20:47–21:45, at `2c65045a75b86e33ce51c8f223269e72a61b337b`,
the HEAD of the batch's range `ff97359d368001ba79d2b1299688c3479b2678ad..2c65045a75b86e33ce51c8f223269e72a61b337b`.
The acceptance session `batch-i-autopilot-model-effort-s4` recorded the
evidence and did not classify any result; classification is the main
session's.

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — no run gave the
criterion anything to check.

## Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `2c65045` (HEAD before the first run and after the last; no commit landed in the repository while the runs went on), loaded with `--plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc` in every session this session started through a driver. `plugin.json` still reads 4.1.0; the `## 4.2.0 — unreleased` CHANGELOG entry is the batch's. Under test: `plugins/kenspc/skills/autopilot/SKILL.md` and `plugins/kenspc/skills/autopilot/scripts/run.sh` |
| Claude Code | 2.1.283 |
| Acceptance session | `batch-i-autopilot-model-effort-s4`, session `6b0165c9-8557-4919-a65a-825e9bd95052`, headless, launched by `batch-i-main` through the Phase 0 driver copy with no model or effort flag; its 109 main-loop assistant records, read while case 3 ran, all carry `claude-opus-5-5` and `effort: xhigh`, and its Bash reads `CLAUDE_EFFORT=xhigh`, `CLAUDE_CODE_EFFORT_LEVEL` unset, `AUTOPILOT_MODEL` and `AUTOPILOT_EFFORT` unset. `~/.claude/settings.json` has `"model": "opus"` and no effort key |
| Drivers | Two copies, as a clarification in the spec rules. The Phase 0 copy `/Users/kenspc/Projects/_smoke/_prompts/batch-i-autopilot-model-effort-run.sh` (4.1.0 text: `grep -c AUTOPILOT_MODEL` gives 0) started every nested autopilot session (the trial, cases 3–6 and 8), so those sessions got no `--model` or `--effort` flag and resolved both from settings, as this session does. The HEAD copy `/Users/kenspc/Projects/_smoke/_prompts/batch-i-autopilot-model-effort-s4-head-run.sh`, written with `git show HEAD:plugins/kenspc/skills/autopilot/scripts/run.sh`, sha256 `c17c227c…011f52b`, equal to the working tree's, ran cases 1 and 2. Each nested autopilot copied its own driver from the working tree to `_prompts/<nested batch>-run.sh` |
| Launch line | `AUTOPILOT_LOGS=/Users/kenspc/Projects/_smoke/_logs AUTOPILOT_BATCH=batch-i-autopilot-model-effort AUTOPILOT_PLUGIN_DIR=/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc AUTOPILOT_BUDGET_USD=<cap> <driver> <nested tag> <seed> <prompt file>`, the cap 172.28 less every earlier nested session's cost, the nested workers' included; case 4 adds `CLAUDE_CODE_EFFORT_LEVEL=high`, case 2 `AUTOPILOT_MODEL=sonnet AUTOPILOT_EFFORT=low` |
| Prompts | Every nested autopilot's prompt is one line, `/kenspc-autopilot docs/plans/<name>.md`, in `/Users/kenspc/Projects/_smoke/_prompts/batch-i-autopilot-model-effort-s4-<case>.md`; each session expanded it to the command `kenspc:kenspc-autopilot`, whose text reads the skill at `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/autopilot/SKILL.md` — the working tree's, in all eight nested autopilot sessions, whose transcripts name the installed 4.1.0 copy's autopilot path (`~/.claude/plugins/cache/kenspc-claude-plugin/kenspc/4.1.0/skills/autopilot`) 0 times. Case 2's prompt: `Reply with the single word ok and stop.` |
| Seeds | `/Users/kenspc/Projects/_smoke/batch-i-autopilot-model-effort-base` ("text-kit"): `package.json` (`"test": "node --test"`, no dependency), `src/slug.js`, `test/slug.test.js` (3 tests), a README with a Scripts section, `.gitignore` holding `node_modules/` and `.kenspc/`, no CLAUDE.md; one commit `b20fbbc` "chore: seed text-kit"; `npm test` 3 of 3 pass, Node 24.19.0. Each run's seed is a `git clone` of it, `origin` removed, plus one commit `docs(plans): add batch <name> spec` adding `docs/plans/<name>.md`: the same one-step spec (`countWords(text)` in `src/words.js` with `node:test` cases; Documentation impact `N/A`), its `## Autopilot` with `Mode: repo`, `Acceptance: none`, `Release preparation: default`, a `Budget:` and the case's `Role settings:`. The tree is clean before every run. The spec names differ per run (`i-trial-words`, `i-case3-words`, …), so every nested batch has its own state file, tags, and logs |
| Mode | Repo mode in every nested batch. Its workers run the installed plugin unless `AUTOPILOT_PLUGIN_DIR` reaches their driver (Observations) |
| Traces | `~/.claude/projects/-Users-kenspc-Projects--smoke-batch-i-autopilot-model-effort-<seed>/<session id>.jsonl`; the driver's files `_logs/batch-i-autopilot-model-effort-s4-<run>.{json,err,pid,exit,session}` and its start and end lines in `_logs/batch-i-autopilot-model-effort-timeline.log`; each nested batch's own files `_logs/<nested batch>-{state.md,timeline.log,costs.txt}` and `_prompts/<nested batch>-*` |

### Trial run

`batch-i-autopilot-model-effort-s4-trial`, session `000b7851-65ab-4590-9cf7-827f96c239d6`, seed `batch-i-autopilot-model-effort-trial`, spec `docs/plans/i-trial-words.md` with `Budget: USD 1` and no `Role settings:`, cap 172.28, 20:47:19–20:53:38. Driver reply: `started batch-i-autopilot-model-effort-s4-trial pid 29288 session 000b7851-65ab-4590-9cf7-827f96c239d6`, exit 0; `.exit` 0, JSON subtype `success`.

The path under test is reachable: the nested autopilot read the working tree's SKILL.md, passed every start check, copied the working tree's driver to `_prompts/i-trial-words-run.sh` and ran its self-test, wrote the settings line `… wait headless, roles none declared, pass-through claude-opus-5-5/xhigh` into `_logs/i-trial-words-state.md`, and launched `i-trial-words-s2` with `AUTOPILOT_MODEL='claude-opus-5-5' AUTOPILOT_EFFORT='xhigh'` on the driver line; the running worker's own command line (`ps`) carried `--model claude-opus-5-5 --effort xhigh --max-budget-usd 1`. S2 committed its task document, and its state line reads `i-trial-words-s2 requested claude-opus-5-5/xhigh (pass-through) applied claude-opus-5-5/xhigh`. The run then ended where the spec's USD 1 budget put it, before S3: `Autopilot stopped: budget — spent USD 0.661773 + projected USD 0.661773 > budget USD 1 before S3 (remaining: S3, S3b, S6); raise the budget to how much?`

Cost: USD 2.1581374 — the nested main session USD 1.4963644 and `i-trial-words-s2` USD 0.661773 (`_logs/i-trial-words-costs.txt`).

Per-session cost — each session's last cumulative `total_cost_usd`, from the driver's `<tag>.json` for the sessions this session started and from each nested batch's `<batch>-costs.txt` for its workers:

| Run | Tag | Session | Cost (USD) |
|---|---|---|---|
| Trial | `batch-i-autopilot-model-effort-s4-trial` (nested main) | `000b7851-65ab-4590-9cf7-827f96c239d6` | 1.4963644 |
| Trial | `i-trial-words-s2` | `560e37ce-a3f5-43a6-b377-e510aef33a40` | 0.661773 |
| 1 | — (stub launches only) | — | 0.00 |
| 2 | `batch-i-autopilot-model-effort-s4-case2`, `-case2-r1` (one session) | `7c9ba739-2a59-4443-971e-4d9b09edb3e3` | 0.0958452 |
| 3 | `batch-i-autopilot-model-effort-s4-case3`, `-case3-r1` (nested main, one session) | `c6511291-ea59-41e8-858f-c94c99eeb1ba` | 3.6180216 |
| 3 | `i-case3-words-s2` | `0a728454-fd56-41c0-b259-1abbd517c9e9` | 0.2908725 |
| 3 | `i-case3-words-s3` | `271ee11b-4c41-46a7-b034-068fd0f9453c` | 3.7645712 |
| 3 | `i-case3-words-s3b` | `e7ee1f56-95b3-4c49-b3a9-9aa8d2c925b3` | 4.0248342 |
| 3 | `i-case3-words-s6` | `55dd1daf-43db-4a6f-bff7-ea13e3bc8020` | 0.0444939 |
| 4 | `batch-i-autopilot-model-effort-s4-case4` | `b550da85-e9db-4375-a636-d58e5a05572b` | 0.6332606 |
| 5 | `batch-i-autopilot-model-effort-s4-case5` | `3f2010d4-27d4-480b-bfb2-ee6e00132550` | 0.6332596 |
| 6 | `batch-i-autopilot-model-effort-s4-case6` (nested main) | `e16e03b8-7f32-452e-9a5e-7b6ffdcdc37b` | 1.8847492 |
| 6 | `i-case6-words-s2` | `cc8cda13-f3f9-4518-ae88-8666aab6e316` | 0.6384504 |
| 6 | `i-case6-words-s3` | `44d155b0-e549-4aa6-b947-baf37ead8e41` | 0.7029984 |
| 7 | — (no session) | — | 0.00 |
| 8 | `batch-i-autopilot-model-effort-s4-case8a` | `9c8e3a2c-cf79-46b7-b0b3-a5e58efb1484` | 0.6417946 |
| 8 | `batch-i-autopilot-model-effort-s4-case8b` | `302af808-6df6-4dbc-b718-48977e168cc2` | 0.6337756 |
| 8 | `batch-i-autopilot-model-effort-s4-case8c` | `fcb6d7f8-d724-4092-907e-891b0ffd9811` | 0.6107742 |

In all USD 20.3758386, the trial's included, within the USD 172.28 this session was given for its nested launches. This session's own cost is not included.

## Independence

The acceptance session built the base seed and its clones, wrote every seed spec and its `## Autopilot` section — the `S3b` effort value included, read from its own `CLAUDE_EFFORT` — wrote every prompt, the resume prompt of case 3 among them (the main session's ruling, put as the nested main's user would), asked the main session two questions and carried out its two answers, and wrote this record. It took no part in the batch's design, its implementation, or its reviews, and it answered no nested worker's question: the nested main sessions answered their workers from their seed specs. What the nested runs produced — the settings lines, the state files and their model and effort lines, the reviewer reports, the driver copies and prompts, the workers' commits, the stops and their messages, the transcripts — is independent of this session. What it typed is not, and each piece is named above where it went in.

## Cases

### Case 1 — `run.sh --self-test` on the HEAD copy — PASS, USD 0.00

Command: `cd /Users/kenspc/Projects/_smoke && AUTOPILOT_CLAUDE= bash /Users/kenspc/Projects/_smoke/_prompts/batch-i-autopilot-model-effort-s4-head-run.sh --self-test`, exit 0, last line `self-test passed`. No nested session: the self-test launches its own stub, so the case costs nothing. Driver replies, all from the self-test's stub launches: `started selftest-s1 …`, `selftest-s2`, `selftest-s3`, `selftest-s4`, `selftest-s5`, `selftest-s6`, `selftest-s1-r1` (the resume, same session id `5d632ebf-cae5-4f84-b594-f3ba1136d84c` as `selftest-s1`), `self-s-test-s1`; logs directory `$TMPDIR/autopilot-selftest.nfOqUv/logs`.

The stub's `<tag>.err` first lines, the prompt text left out:

| Launch | Variables | `<tag>.err` shows |
|---|---|---|
| `selftest-s3`, fresh | `AUTOPILOT_MODEL=selftest-model`, `AUTOPILOT_EFFORT=low` | `--session-id cf5f04af-… --name selftest-s3 … --output-format json --model selftest-model --effort low` |
| `selftest-s1-r1`, resume | `AUTOPILOT_MODEL=selftest-model`, `AUTOPILOT_EFFORT=high` (and the plugin-dir, budget, and append-system-prompt variables) | `-p --resume 5d632ebf-… --name selftest-s1-r1 … --max-budget-usd 1 --append-system-prompt x --model selftest-model --effort high` |
| `selftest-s1`, fresh | both unset | `--session-id 5d632ebf-… --name selftest-s1 --settings {"crossSessionInbound":"accept"} --permission-mode bypassPermissions --output-format json` — no `--model`, no `--effort` |
| `selftest-s4`, fresh | both the empty string | `--session-id 9302aa22-… --name selftest-s4 … --output-format json` — no `--model`, no `--effort` |
| `selftest-s5` / `selftest-s6`, fresh | one set, the other empty | `--model selftest-model` alone / `--effort low` alone |

Both variables set: the fresh launch and the resume carry both flags. Unset or empty: neither flag. The criterion holds.

### Case 2 — one real worker through the HEAD copy, then a resume — PASS, USD 0.0958452

Seed `batch-i-autopilot-model-effort-case2` (the base clone, no spec), prompt `_prompts/batch-i-autopilot-model-effort-s4-case2.md` (`Reply with the single word ok and stop.`), both launches with `AUTOPILOT_MODEL=sonnet AUTOPILOT_EFFORT=low` on the launch line and the HEAD copy as the driver.

- Fresh, cap 170.12: driver reply `started batch-i-autopilot-model-effort-s4-case2 pid 41741 session 7c9ba739-2a59-4443-971e-4d9b09edb3e3`, exit 0; `.exit` 0, subtype `success`, result `ok`, `total_cost_usd` 0.0859638.
- Resume, tag `batch-i-autopilot-model-effort-s4-case2-r1`, `--resume 7c9ba739-2a59-4443-971e-4d9b09edb3e3`, cap 170.03, the same prompt file: driver reply `started batch-i-autopilot-model-effort-s4-case2-r1 pid 42282 session 7c9ba739-2a59-4443-971e-4d9b09edb3e3`, exit 0; `.exit` 0, subtype `success`, result `ok`, `total_cost_usd` 0.0958452 (the session's cumulative total).

The transcript `~/.claude/projects/-Users-kenspc-Projects--smoke-batch-i-autopilot-model-effort-case2/7c9ba739-2a59-4443-971e-4d9b09edb3e3.jsonl` holds two main-loop assistant records, one per execution (12:54:50Z, the fresh run; 12:55:07Z, the resume), both `message.model` `claude-sonnet-5` and `effort` `low`, neither an API-error record; the session has no subagent directory. Every record is `low` and every `message.model` contains `sonnet`: the criterion holds. It can fail: this session's own records and the trial's S2 records, launched without the flags or with the pass-through values, read `claude-opus-5-5` / `xhigh`, the settings' values.

### Case 3 — nested autopilot with three role declarations — PASS, USD 11.7427934

Seed `batch-i-autopilot-model-effort-case3`, spec `docs/plans/i-case3-words.md` (`60c2879`), `Budget: USD 40`, `Acceptance: none`, and

```
- Role settings:
  - S2: model sonnet, effort low
  - S6: model haiku, effort low
  - S3b: effort xhigh
```

`xhigh` for S3b is the nested main session's effort as this session read it: `CLAUDE_EFFORT=xhigh` in this session's Bash, the nested main being launched, as this session was, without `--model` or `--effort`. The nested main's own pass-through values, on its settings line, are `claude-opus-5-5/xhigh`, and its 131 main-loop assistant records all read `claude-opus-5-5` / `xhigh`.

Two runs of one session, `c6511291-ea59-41e8-858f-c94c99eeb1ba`:

1. `batch-i-autopilot-model-effort-s4-case3`, cap 170.02, 20:55:27–21:12:09. Driver reply `started batch-i-autopilot-model-effort-s4-case3 pid 42913 session c6511291-ea59-41e8-858f-c94c99eeb1ba`, exit 0; `.exit` 0, subtype `success`. The run launched S2 and S3 and then stopped: S3's regression-verifier subagent had written `/tmp/rv-npm-test.txt` (623 bytes, `npm test` output, no secret), S3 applied its preamble's rail and ended, and the nested main's last line was `Autopilot stopped: rail breach — i-case3-words-s3's regression-verifier subagent wrote /tmp/rv-npm-test.txt outside the repository, workspace, and $TMPDIR (stop condition 6)`. This session asked `batch-i-main` (`question batch-i-autopilot-model-effort-s4: case 3's nested autopilot stopped on a /tmp rail breach before S3b — record FAIL, or resume it to finish?`) and waited one call. The answer: resume the nested main once with the user's ruling for this batch — a scratch file a worker's subagent writes under /tmp, holding no secret, is an observation, not a stop — written as the nested main's user would, the nested main writing the exception into the preambles of the workers it launches from there on; the file had been moved out of /tmp by the main session; judge the case on the finished run.
2. `batch-i-autopilot-model-effort-s4-case3-r1`, `--resume c6511291-…`, cap 163.73, prompt `_prompts/batch-i-autopilot-model-effort-s4-case3-r1.md` (the ruling, and "Continue the run from where it stopped, as your skill says."), 21:14:24–21:27:10. Driver reply `started batch-i-autopilot-model-effort-s4-case3-r1 pid 64573 session c6511291-ea59-41e8-858f-c94c99eeb1ba`, exit 0; `.exit` 0, subtype `success`. The nested main launched S3b and S6, with the exception in both preambles, and ended `Autopilot finished — 60c2879decf61d4f5cd27effae92b67d431fdebe..312b7c1a25dcacc9c02c9443e089f343f1fc8e2c`, its final message's last line.

The nested timeline `_logs/i-case3-words-timeline.log` holds four start lines, each followed by its `end … exit 0`: `i-case3-words-s2` 20:57:27, `-s3` 20:59:05, `-s3b` 21:14:54, `-s6` 21:25:27. The seed's history after the run: `bfdee5e` (task document), `122ee37` (feat), `029d390`, `8c8349f`, `987195f` (S3's review fixes), `d79e690` (S3b's fix), `312b7c1` "docs: remove batch i-case3-words plan and tasks" (S6).

Against the criterion:

- Settings line: `Autopilot settings — batch i-case3-words, mode repo, baseline 60c2879…, budget USD 40, caps 16 sessions / 8 resumes, version none, acceptance none, release preparation default, workspace /Users/kenspc/Projects/_smoke/, wait headless, roles S2 sonnet/low; S6 haiku/low; S3b —/xhigh, pass-through claude-opus-5-5/xhigh` — the three roles, `S3b —/xhigh` among them, and the pass-through values. **Holds.** (The line is in the state file only, not printed in the reply: F1.)
- The state file's `models and efforts:` holds one line per worker, four workers, four lines:
  ```
  i-case3-words-s2 requested sonnet/low (declared) applied claude-sonnet-5/low
  i-case3-words-s3 requested claude-opus-5-5/xhigh (pass-through) applied claude-opus-5-5/xhigh
  i-case3-words-s3b requested claude-opus-5-5/xhigh (declared) applied claude-opus-5-5/xhigh
  i-case3-words-s6 requested haiku/low (declared) applied claude-haiku-4-5-20251001/— MISMATCH: effort not applied
  ```
  **Holds.**
- S2 applied contains `sonnet`, effort `low`: its 14 main-loop assistant records all read `claude-sonnet-5` / `low`. **Holds.**
- S3 and S3b applied equal the nested main's `claude-opus-5-5` / `xhigh`: 33 records each, all `claude-opus-5-5` / `xhigh`. **Holds.**
- S3b's line is `(declared)`, its requested model `claude-opus-5-5` the pass-through value, no `MISMATCH`. **Holds.**
- S6's line reads `applied claude-haiku-4-5-20251001/— MISMATCH: effort not applied`, with no `not observed`: its 9 records all read `claude-haiku-4-5-20251001` and none carries an `effort` field, although the running worker's command line carried `--model haiku --effort low`. The run still reached `Autopilot finished`. **Holds.**
- The reviewer report, in the final message and at `_logs/i-case3-words-report.md`, has `- Models and efforts: 4 workers, 1 mismatches, 0 not observed`, followed by the four lines above. **Holds.**
- Every driver launch line in the nested main's transcript sets both variables — the four Bash commands that run `i-case3-words-run.sh i-case3-words-s<n>`: `s2` `AUTOPILOT_MODEL='sonnet' AUTOPILOT_EFFORT='low'`, `s3` `'claude-opus-5-5'`/`'xhigh'`, `s3b` `'claude-opus-5-5'`/`'xhigh'`, `s6` `'haiku'`/`'low'`. **Holds.**

Cost: USD 11.7427934 — the nested main USD 3.6180216 (its last cumulative total, after the resume; USD 2.2379896 at the stop), and its workers from `_logs/i-case3-words-costs.txt`: S2 0.2908725, S3 3.7645712, S3b 4.0248342, S6 0.0444939.

### Case 4 — `CLAUDE_CODE_EFFORT_LEVEL=high` with a declared effort — PASS, USD 0.6332606

Seed `batch-i-autopilot-model-effort-case4`, spec `docs/plans/i-case4-words.md` (`32d7704`), `Budget: USD 3`, `Role settings:` `- S2: effort low`. Launched with `CLAUDE_CODE_EFFORT_LEVEL=high` prefixed to the launch line, cap 158.28, 21:28:15–21:29:03. Driver reply `started batch-i-autopilot-model-effort-s4-case4 pid 82522 session b550da85-e9db-4375-a636-d58e5a05572b`, exit 0; `.exit` 0, subtype `success`.

The nested main ran `printenv CLAUDE_CODE_EFFORT_LEVEL` in its Bash and stopped in its start checks; its final message's last line is `Autopilot stopped: CLAUDE_CODE_EFFORT_LEVEL is set (high) while Role settings declares an effort (S2: effort low)`. It launched nothing: `_logs/i-case4-words-timeline.log` does not exist, no `i-case4-words-*` file is under `_prompts/` (not even the driver copy), and its state file's `sessions:` reads `none`. The positive control: the same `ls` finds case 3's `i-case3-words-timeline.log`, which holds four start lines. The criterion holds. The variable reached the nested main itself: its 15 records read `claude-opus-5-5` / `high`, and its state file's pass-through reads `claude-opus-5-5/high`.

### Case 5 — `- S3: effort extreme` — PASS, USD 0.6332596

Seed `batch-i-autopilot-model-effort-case5`, spec `docs/plans/i-case5-words.md` (`252f709`), `Budget: USD 3`, `Role settings:` `- S3: effort extreme`, cap 157.64, 21:29:28–21:30:19. Driver reply `started batch-i-autopilot-model-effort-s4-case5 pid 84069 session 3f2010d4-27d4-480b-bfb2-ee6e00132550`, exit 0; `.exit` 0, subtype `success`. Last line: ``Autopilot stopped: settings stop — Role settings: `- S3: effort extreme`, `extreme` is not one of low, medium, high, xhigh, max`` — it names `Role settings` and `extreme`. No worker started: no `i-case5-words-*` file exists under `_logs/` or `_prompts/`, and the seed's history is unchanged (`252f709` on `b20fbbc`). The criterion holds.

### Case 6 (optional) — nested autopilot with no `Role settings:` — PASS on the two workers that ran, USD 3.226198

Seed `batch-i-autopilot-model-effort-case6`, spec `docs/plans/i-case6-words.md` (`73e4819`), `Budget: USD 40`, no `Role settings:`, cap 157.01, 21:30:32–21:39:29. Driver reply `started batch-i-autopilot-model-effort-s4-case6 pid 85132 session e16e03b8-7f32-452e-9a5e-7b6ffdcdc37b`, exit 0; `.exit` 0, subtype `success`.

The run stopped after S3: S3's task-implementer subagent (`~/.claude/projects/-Users-kenspc-Projects--smoke-batch-i-autopilot-model-effort-case6/44d155b0-e549-4aa6-b947-baf37ead8e41/subagents/agent-a280b27113aa1b088.jsonl`) wrote `/tmp/case6-test.out` and `/tmp/case6-mut.uPf43Y/` — `npm test` output and a mutation-test copy of the seed, no secret — and itself ran `rm -rf /tmp/case6-mut && mkdir …` and `rm -rf /tmp/case6-mut /tmp/case6-mut.out`; the worker's own main loop ran no `rm -rf`. S3 reported the breach and ended before its review phase, and the nested main's last line was `Autopilot stopped: rail breach in S3 (i-case6-words-s3) — its implementer subagent wrote under /tmp and ran rm -rf; answer (a) end the batch or (b) resume S3 to run its review`. This session asked `batch-i-main` (`question batch-i-autopilot-model-effort-s4: case 6's nested run stopped on a rail breach that adds a subagent's rm -rf to the /tmp class — resume, judge as it stands, or record FAIL?`) and waited one call. The answer: judge case 6 on the run as it stands, no resume; the recursive rm is not brought under the /tmp ruling, and the stop is recorded as it happened.

Against the criterion, on the two workers that ran:

- Settings line (state file): `… wait headless, roles none declared, pass-through claude-opus-5-5/xhigh`. **Holds.**
- State lines:
  ```
  i-case6-words-s2 requested claude-opus-5-5/xhigh (pass-through) applied claude-opus-5-5/xhigh
  i-case6-words-s3 requested claude-opus-5-5/xhigh (pass-through) applied claude-opus-5-5/xhigh
  ```
  S2's 24 and S3's 15 main-loop assistant records all read `claude-opus-5-5` / `xhigh`, as do the nested main's 71. Both launch lines set `AUTOPILOT_MODEL='claude-opus-5-5' AUTOPILOT_EFFORT='xhigh'`. **Holds** for S2 and S3.
- S3b and S6 did not run under this case: Not exercised.

The nested timeline `_logs/i-case6-words-timeline.log` holds `i-case6-words-s2` 21:32:23 and `-s3` 21:35:20, each with its `end … exit 0`. Seed history: `fdcd0e6` (task document), `96b8cd9` (feat).

Cost: USD 3.226198 — the nested main 1.8847492, S2 0.6384504, S3 0.7029984 (`_logs/i-case6-words-costs.txt`).

### Case 7 — `bash scripts/check-all.sh --self-test` — PASS, USD 0.00

In the repository at `2c65045`, one Bash call, the status taken on its own line: exit 0. Output: eleven `PASS scripts/check-*.sh` lines, `guards run: 11`, ten `PASS self-test …` lines, `SKIP self-test scripts/check-review-agent-drift.sh (no fixture)`, and `self-tests run: 10` as the last line; no `FAIL` line. `docs/release-checklist.md` expects `guards run: 11` and `self-tests run: 10`. The tree was clean after the run. No session started.

### Case 8 — three grammar stops, one run each — PASS, USD 1.8863444

Each seed a clone with its own spec, `Budget: USD 3`, the `Role settings:` below; the tags carry a letter per run, since the three runs of one case need three tags no other session has used.

| Run | Seed / spec | `Role settings:` | Cap | Driver reply (exit 0 each) | Last line | Cost |
|---|---|---|---|---|---|---|
| unknown role | `-case8a` / `i-case8a-words.md` (`ec98214`) | `- S7: effort low` | 153.79 | `started batch-i-autopilot-model-effort-s4-case8a pid 7191 session 9c8e3a2c-cf79-46b7-b0b3-a5e58efb1484` | ``Autopilot stopped: settings: Role settings — unknown role `S7` in `- S7: effort low` (known roles: S1, S2, S3, S3b, S4, S5, S6)`` | 0.6417946 |
| role named twice | `-case8b` / `i-case8b-words.md` (`cc0d471`) | `- S3: model sonnet` and `- S3: effort low` | 153.14 | `started batch-i-autopilot-model-effort-s4-case8b pid 8160 session 302af808-6df6-4dbc-b718-48977e168cc2` | ``Autopilot stopped: settings stop — Role settings names role S3 twice (`- S3: model sonnet`, `- S3: effort low`)`` | 0.6337756 |
| effort before model | `-case8c` / `i-case8c-words.md` (`6ccbc27`) | `- S3: effort low, model sonnet` | 152.51 | `started batch-i-autopilot-model-effort-s4-case8c pid 9499 session fcb6d7f8-d724-4092-907e-891b0ffd9811` | ``Autopilot stopped: settings stop — Role settings: `effort low, model sonnet` is outside the grammar (the model comes first when both are given: `- S3: model sonnet, effort low`)`` | 0.6107742 |

The duplicate run's two lines could each be read alone and together cover both parts, so a reading that merged them would have gone on; the run stopped. Every run ended before a worker: no `i-case8*` file exists under `_logs/` or `_prompts/` (so no timeline and no start line; the same listing finds 34 `i-case3*` files), and each seed's history is its spec commit on `b20fbbc`. Each last line names `Role settings` and the value that failed. The criterion holds for all three. Times: 21:42:03–21:42:51, 21:43:00–21:43:55, 21:44:04–21:44:56.

## Findings

Evidence only; the main session classifies. None of these is a case's criterion.

- **F1 — the settings line and the return lines are not printed in the nested main sessions' replies.** The skill's Phase 0 is done when the settings line "has been printed as a line of its own in this session's reply — the state file … does not stand in for it", and The return prints `S<n> returned — exit <code>, cost USD <c>, <success|subtype> — <json path>` the same way. In the three nested runs that got past Phase 0, the text blocks of the main-loop assistant records hold `Autopilot settings —` 0 times and `S<n> returned — ` 0 times; the settings line is in each state file's first line and in the Write calls that wrote it. `S<n> started — ` lines are printed in case 3 (4 of 4 launches) and case 6 (2 of 2), not in the trial (0 of 1). The same grep finds both line forms in a two-line control. Cases 3 and 6 judge the settings line by its content, which the state file carries, so neither case fails on it. The settings-line half matches the batch F record's first finding.
- **F2 — a repo-mode launch leaves an inherited `AUTOPILOT_PLUGIN_DIR` to the driver.** The skill sets `AUTOPILOT_PLUGIN_DIR` "in plugin mode" and says nothing of repo mode, while for `AUTOPILOT_MODEL` and `AUTOPILOT_EFFORT` it sets the empty string because "a variable of the same name already in this session's environment would otherwise reach the driver". Every nested main here inherited `AUTOPILOT_PLUGIN_DIR=/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc` from the launch line, and two readings of the same text followed: the trial's main set `AUTOPILOT_PLUGIN_DIR=` (empty) on its launch line, and its S2 ran the installed copy (`Base directory for this skill: /Users/kenspc/.claude/plugins/cache/kenspc-claude-plugin/kenspc/4.1.0/skills/generate-task`); the mains of cases 3 and 6 passed the inherited value on purpose ("so the workers run the same plugin text as this session"), and their S2, S3, and S3b ran the working tree's skills. The model and effort results do not depend on it. The same inheritance brought `AUTOPILOT_BATCH` and `AUTOPILOT_BUDGET_USD`, which every launch overwrites.
- **F3 — the S2 worker declared at `sonnet`/`low` skipped generate-task's confirmation.** The preamble tells a worker to send a `question` when a skill it runs reaches the confirmation in `/kenspc-task`. Case 3's S2 (`claude-sonnet-5`, `low`, 14 records) used no SendMessage: its transcript goes from reading to the Write of the task document and the reviewer dispatch. The S2 workers of the trial and case 6, at `claude-opus-5-5`/`xhigh`, each sent one question (1 SendMessage use each), answered `yes` from the spec. Case 3's nested main recorded the skip and checked the committed list against the spec afterwards with the gate's rubric; the list matched.

## Observations

- **Scratch files and a recursive rm under /tmp, by nested workers' subagents.** Case 3: S3's regression-verifier subagent wrote `/tmp/rv-npm-test.txt` (the nested stop); S3b reported `/private/tmp/code-fixer-final.txt` (627 bytes, 21:06, `npm test` output), there before its own run, which the nested reviewer report reads as probably S3's code-fixer's. Case 6: S3's task-implementer subagent wrote `/tmp/case6-test.out` and `/tmp/case6-mut.uPf43Y/` and ran `rm -rf` twice on its own `/tmp/case6-mut` scratch. None held a secret. Both nested mains stopped as their rails' letter says. The main session moved `rv-npm-test.txt` into `/Users/kenspc/Projects/_smoke/.trash/tmp-scratch-s4-case3-20260928-211336/` and the two case 6 leftovers into `…/.trash/tmp-scratch-s4-case6-20260928-214041/`; `/tmp/code-fixer-final.txt` is still in /tmp, the main session's to move. Roadmap note: a worker's rails do not reach the subagents it dispatches, and in case 6 the subagent also ran a recursive rm on its own /tmp scratch. This session issued no recursive rm and wrote nothing outside the repository, the workspace, and `$TMPDIR`; the main session confirmed both /tmp events as observations for this session's rails.
- **Effort on a model without it.** Case 3's S6 ran with `--model haiku --effort low` on its command line; its 9 records carry `claude-haiku-4-5-20251001` and no `effort` field. The harness took the flag without an error, and the worker finished its commit.
- **The nested main sessions' own values.** Every nested main was launched by the Phase 0 driver copy with no model or effort flag and ran at the settings' `claude-opus-5-5` / `xhigh` (trial 58 records, case 3 131, case 6 71), which each determined as its pass-through values. Case 4's main ran at `high`, the value of `CLAUDE_CODE_EFFORT_LEVEL` on its launch line (15 records), and wrote `pass-through: claude-opus-5-5/high` into its state file before it stopped.
- **The state file on a Phase 0 stop.** Case 4's main wrote `_logs/i-case4-words-state.md` (first line `Autopilot settings — not printed: the run stopped at the Phase 0 start checks, before the settings line`); the mains of case 5 and case 8's three runs wrote no state file.
- **The nested mains' names.** Each nested main used its listed name, the nested tag, not `<batch>-main`, and recorded that in its state file.
- **Resume totals.** Case 2's resume and case 3's resume report the session's cumulative `total_cost_usd` (0.0958452 after 0.0859638; 3.6180216 after 2.2379896, the nested main estimating about USD 1.2 for the resumed run); only the last value is counted.
- **Tags.** Beyond `-trial` and `-case<n>`: the two resumes `-case2-r1` and `-case3-r1`, the resume suffix the skill uses, and case 8's three runs `-case8a`, `-case8b`, `-case8c`.
- **Case 3's own review loop.** S3's internal task-implement review ended FAIL on test strength (after `029d390` no test put a tab between two words); S3b fixed the related LOW in `d79e690`. The nested verdict loop went on to S6 on S3b's verdict.

## Not exercised

- Case 6's S3b and S6: the nested run stopped after S3, and the main session ruled the case judged as it stood. The pass-through model for S3b is exercised in case 3 (`declared` effort, pass-through model); S6 at the pass-through values is exercised nowhere.
- `CLAUDE_CODE_EFFORT_LEVEL` set while no role declares an effort (the run should not stop), a resume's state line replacing its predecessor's (no nested worker was resumed; case 3's resume was the nested main's), and a re-run tag's role (`-s3c`, `-s4b`, `-s5b`; no re-run happened) — the spec lists these three as not exercised.
- The skipping of API-error records, and a run with `CLAUDE_CONFIG_DIR` set — the spec lists both as not exercised.
- `not observed` and `not determined`: every transcript was found and every pass-through value determined.
- A declared model with a `[...]` suffix, and a model token that needs its single quotes.
- A resume launch with both variables empty or unset: the self-test checks the flags' absence on fresh launches only (`selftest-s1`, `selftest-s4`); case 1's criterion does not ask for it.
- The interactive wait path; the S1, S4, and S5 roles in a nested run (spec entry, `Acceptance: none`, no fix).
- `run.ps1` on Windows, and Fable: out of scope.

## Summary

| Case | Result | Cost (USD) |
|---|---|---|
| Trial | path reachable | 2.1581374 |
| 1 | PASS | 0.00 |
| 2 | PASS | 0.0958452 |
| 3 | PASS (after one resume of the nested main, on the main session's ruling) | 11.7427934 |
| 4 | PASS | 0.6332606 |
| 5 | PASS | 0.6332596 |
| 6 (optional) | PASS on S2 and S3; S3b and S6 not exercised (nested stop, the main session's ruling) | 3.226198 |
| 7 | PASS | 0.00 |
| 8 | PASS (three runs) | 1.8863444 |

Every case's criterion holds; case 6 on the two workers its run reached. The nested sessions cost USD 20.3758386 in all, the trial's included; this session's own cost is not included. The model and effort path held wherever it ran: every declared or passed-through value that the flags carry was applied, except the effort on the one model without it, which the record flags as the criterion expects. Three findings outside the criteria (F1–F3) and the /tmp observations are for the main session to classify.
