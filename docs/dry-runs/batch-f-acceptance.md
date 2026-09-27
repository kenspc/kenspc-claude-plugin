# Batch F acceptance — the autopilot skill, one batch run unattended to its release preparation (3.9.0, unreleased) — rounds 1 and 2

Acceptance record for batch F (spec: `docs/plans/batch-f-autopilot.md`,
clarifications CL1–CL9): the spec's Testing Strategy cases 1, 4, 9, 8, and the
checks 5–7, run headless on one machine, macOS, 2026-09-27, 10:55–11:49.
Cases 2, 3, and 10 are held for the second round (§ 5). The acceptance
session recorded the evidence and a first reading of each FAIL and did not
classify them; classification is the main session's, as the batch E record's
§ 3 describes.

Round 2 (clarifications CL10–CL23 in the spec, the fixes for round 1's
findings and `run.ps1` in the tree), 2026-09-27, 15:14–15:50, same
machine: by the user's decision, not the full cases 2 and 3 but two short
checks — the brief entry (case 2t) and plugin mode (case 3t), each run on a
small budget to its first budget stop, to check the part each case has of
its own — plus case 5 over both runs, the `run.ps1` half of case 6, and a
text check of the finish line's position. The full chains of cases 2 and 3,
and case 10, are Not exercised (§ 5). Round 2 was run by a second
acceptance session, `f-s4b`, which wrote §§ 2.8–2.12, F5 on, and O13 on;
round 1's text is unchanged except where a section says it covers both
rounds.

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — the run gave
the criterion nothing to check.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree at `b6a0199` (HEAD before the first run and after the last; no commit landed while the runs went on), loaded with `--plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc` in every session the driver started. Under test: `plugins/kenspc/skills/autopilot/SKILL.md`, `plugins/kenspc/skills/autopilot/scripts/run.sh`, `plugins/kenspc/commands/kenspc-autopilot.md`. `plugin.json` still reads 3.8.2; the `## 3.9.0 — unreleased` entry is the batch's |
| Claude Code | 2.1.283 |
| Mode | Headless, one process per invocation through the main session's driver `~/Projects/_smoke/_prompts/f-run.sh <tag> <cwd> <prompt-file>` (`claude -p … --name <tag> --settings '{"crossSessionInbound":"accept"}' --plugin-dir … --permission-mode bypassPermissions --output-format json`; `MAX_BUDGET_USD=<n>` adds `--max-budget-usd`), cwd the seed or a clone of it. The acceptance session `f-s4` — itself a headless session opened by the main session `claude-plugin-a3` — waited with one `caffeinate -t 60` per Bash call and answered every question as the user, by `SendMessage`. Prompts are files under `~/Projects/_smoke/_prompts/f-acc-*.txt`; each opens with a routing paragraph (quoted below), except case 8a, whose prompt has to open with the preamble's first sentence. The autopilot under test runs inside a `-p` session, so it takes the headless wait path; it launches its workers through its own driver copy `_prompts/<batch>-run.sh` and keeps `_logs/<batch>-timeline.log`, `<batch>-costs.txt`, and `<batch>-state.md`. One session was started outside the driver, with `--output-format stream-json --verbose` for its init message: `f-acc-c7b` (case 7) |
| Routing paragraph | Every prompt but case 8a's opens with: "你在 headless session 里跑；凡 skill 要问用户的地方（brief 入口的裁定、预算或 caps 的提问、worker 的问题 spec 答不了、任何 stop 前的提问），用 `SendMessage` 把问题连同建议答案发给 session `f-s4`，然后照 skill 的 headless 等待写法等答复（答复以 cross-session message 送达）；主 session 的名字给你的 workers 时，用 ListAgents 第一行印出的本 session 名字。" — then the invocation on its own line (`/kenspc-autopilot <path>`), which the session carried out by the Skill tool (`kenspc:autopilot`) |
| Session model | Opus 5.5 (`claude-opus-5-5`) in every session the driver started and in every worker; the hook sessions (O1) ran another model |
| Installed copy | `kenspc@kenspc-claude-plugin` 3.8.2 is installed (`~/.claude/plugins/cache/kenspc-claude-plugin/kenspc/3.8.2` exists — the positive control). Every session the driver started loaded its skill from the working tree: the Skill tool's `Base directory for this skill:` reads `/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/autopilot` in cases 1, 4, and 9 and `…/skills/task-implement` in case 8b, and `plugins/cache/kenspc-claude-plugin` occurs 0 times in those sessions' transcripts. The autopilot's repo-mode workers are launched without `--plugin-dir` by design and run the installed copy: the base directories of case 1's S2, S3, and S3b are `~/.claude/plugins/cache/kenspc-claude-plugin/kenspc/3.8.2/skills/generate-task`, `…/task-implement`, and `…/task-review`, and case 4's S2 the same `generate-task`. The cache path occurs in 9 of the 33 files under `batch-f-repo`'s trace directory (S2, S3, S3b, and six of their subagents), in 2 of 3 under `batch-f-repo-c4` (its S2 and S2's subagent), and in 0 under `-c9`, `-c8`, and `-c8b` |
| Seed project | `~/Projects/_smoke/batch-f-repo` ("text-kit"), built fresh to the batch E record's Seed project row: that seed's `package-lock.json`, `tsconfig.json`, and `vitest.config.ts` (`globals: true`, default include), `typescript@7.0.2` and `vitest@5.0.1` from the local npm cache with `npm install --offline`, Node 24.19.0; `src/slug.ts` (`slugify`), `test/slug.test.ts` (4 tests), a README with Scripts and API sections, `.gitignore` holding `node_modules/`, no `CLAUDE.md`. History: `5dd111b` "chore: seed text-kit", `b25611c` "docs(plans): add plan word-stats" — `docs/plans/word-stats.md`, two steps (`countWords`, `topWords` in `src/stats.ts`), Documentation impact `README.md` § API, `## Autopilot` with `Mode: repo`, `Budget: USD 40`, `Acceptance:` `npm test — PASS: exit 0` and `npm run typecheck — PASS: exit 0`, `Release preparation: default`. The point the plan leaves unstated: `topWords`'s result entry shape ("each entry of the result carries the word and its count"). Before case 1: `npm test` (4 tests) exit 0, `npm run typecheck` exit 0, `git status --porcelain -uall` empty |
| Brief (case 2, round 2) | `docs/briefs/text-stats.md` in `batch-f-repo`, untracked, sha256 `061bb325…f4e8`: `# Requirement Brief:`, the brief template's sections, `## Open Questions` body `none`, and `## Autopilot` with `Baseline: HEAD`, `Mode: repo`, `Budget: USD 40`, the same two `Acceptance:` lines, `Release preparation: default`. Named `text-stats` so that S1's spec path, `docs/plans/text-stats.md`, is free at the baseline. Copied into the seed after cases 1 and 9 had run: an untracked file in the tree is the clean-tree start check's stop for a spec-entry run, so a brief in place before case 1 would have stopped it |
| Plugin-mode seed (case 3, round 2) | `~/Projects/_smoke/batch-f-plugin`: `git clone` of this repository, checked out at `5c33c4a` (v3.8.2) on a local branch `smoke-3.8.3`, `origin` removed so no push target exists; `bf85621` "docs(plans): add plan readme-reload" — `docs/plans/readme-reload.md`, one step rewording the reload sentence in `plugins/kenspc/README.md` § Local development, Documentation impact the README (edited by the step) and a `## 3.8.3 — unreleased` CHANGELOG entry, `## Autopilot` with `Mode: plugin`, `Version: 3.8.3`, one `Acceptance:` case (`/help` in a `--plugin-dir` session lists the eight kenspc commands — PASS: eight rows), `Release preparation: default`. Prepared, not run |
| Projects | Case 1 ran in the seed. Clones (`git clone`, `origin` removed): `batch-f-repo-c4` (`b25611c` plus `f2449f2` "docs(plans): add plan budget-stop" — the word-stats plan with `Budget: USD 1`, under a batch name of its own, since a second `word-stats` batch would share case 1's state file and hit the workspace-clash stop); `batch-f-repo-c9`, `batch-f-repo-c8`, and `batch-f-repo-c8b`, each reset to `97a8b83` (case 1's task-document commit), so the task document is tracked and the tree clean — a check of the entry kind that a dirty-tree stop cannot mask |
| Traces | `~/.claude/projects/-Users-kenspc-Projects--smoke-batch-f-repo[-c4\|-c9\|-c8\|-c8b]/<session_id>.jsonl`, subagents under `<session_id>/subagents/`; the driver's results in `~/Projects/_smoke/_logs/f-acc-<case>.json`, its timeline in `f-timeline.log`, its costs in `f-costs.txt`; the autopilot's own files in `_logs/word-stats-*` and `_logs/budget-stop-*`, its prompts and driver copies in `_prompts/word-stats-*` and `_prompts/budget-stop-*` |
| Wait path | The interactive half, from the main session: the main session (an interactive session started from VS Code) ran `ps -o args= -p $PPID` and got `…/claude --output-format stream-json --verbose --input-format stream-json … --permission-prompt-tool stdio …`; compared argument by argument there is no `-p` or `--print`, so interactive. The second main session `claude-plugin-a3` (also from VS Code, Claude Code 2.1.283) repeated it at 10:50: `ps -o args= -p $PPID \| tr ' ' '\n' \| grep -nE '^(-p\|--print)$'` found nothing (exit 1); the positive control `echo "claude -p x --print" \| tr ' ' '\n' \| grep -nE …` found two lines. The headless half, verified by the implementing session in its own `-p` process, held again here: the autopilot sessions of cases 1 and 4 ran the skill's probe (`ps -o args= -p $PPID \| tr ' ' '\n' \| grep -qxE -- '-p\|--print' && echo headless \|\| echo interactive`), printed `headless`, and wrote `wait headless` into the settings line of their state files |
| Cost | Below. The runs total USD 22.13 — the sessions the acceptance session started USD 6.38 and the autopilot's workers USD 15.74 — within the USD 80 cap for this round. The acceptance session `f-s4` itself is not included |
| Plugin, round 2 | Repository tree at `8684c81` (HEAD before the first run and after the last; no commit landed while the runs went on), which holds round 1's fixes `8263f1a`, `7fbf94c`, `499ac12`, `27e0317` and `run.ps1`; loaded the same way, `--plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc`, by the same driver `f-run.sh`. Claude Code 2.1.283; every session the driver started, every worker, and every subagent ran Opus 5.5 (`claude-opus-5-5`); the hook sessions (O13) ran another model |
| Mode and routing, round 2 | As round 1. The acceptance session `f-s4b` — a headless session opened by the main session `claude-plugin-a3` — waited with one `caffeinate -t 60` per Bash call and answered as the user by `SendMessage`. The prompts `~/Projects/_smoke/_prompts/f-acc-c2.txt` and `f-acc-c3.txt` open with round 1's routing paragraph with one change, the session it names: `f-s4b` for `f-s4` (the name on `f-s4b`'s `ListAgents` first line); then the invocation on its own line. Both runs were started at 15:16:19 and ran side by side; their questions were told apart by the message's `from-name` |
| Case 2t seed | `~/Projects/_smoke/batch-f-repo-c2`: `git clone` of `batch-f-repo`, `git reset --hard 5dd111b` ("chore: seed text-kit", before the word-stats plan), `origin` removed, `npm install --offline`. The brief `docs/briefs/text-stats.md` copied in from `batch-f-repo` after its sha256 was compared with round 1's (`061bb325…f4e8`, equal), untracked. The driver's change: `Budget: USD 40` → `Budget: USD 8` in the copy's `## Autopilot` section (sha256 after the change `bce2d57e…2f4c`), so the run meets a budget stop early. Before the run: `npm test` (4 tests) exit 0, `npm run typecheck` exit 0, `git -c core.quotePath=false status --porcelain -uall` listing only `?? docs/briefs/text-stats.md` |
| Case 3t seed | `~/Projects/_smoke/batch-f-plugin` as round 1 prepared it (branch `smoke-3.8.3` on `5c33c4a`, no remote, `bf85621` adding `docs/plans/readme-reload.md`). The driver's change: `- Budget: USD 3` added under `- Version: 3.8.3` in the plan's `## Autopilot` section and committed in the seed as `c0bb221` "docs(plans): set the readme-reload budget"; the tree clean before the run |
| Installed copy, round 2 | Unchanged (3.8.2 in `~/.claude/plugins/cache/kenspc-claude-plugin/kenspc/`). Both autopilots loaded the skill from the working tree (`Base directory for this skill: /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/autopilot`). Case 2t's repo-mode S2 and S3 ran the installed copy by design (`…/cache/kenspc-claude-plugin/kenspc/3.8.2/skills/generate-task`, `…/task-implement`); S1 ran no skill. Case 3t's plugin-mode workers ran the seed's own copy (§ 2.9) |
| Traces, round 2 | `~/.claude/projects/-Users-kenspc-Projects--smoke-batch-f-repo-c2/` and `…-batch-f-plugin/`, subagents under `<session_id>/subagents/`; the driver's results `_logs/f-acc-c2.json`, `f-acc-c3.json`; the autopilots' own files `_logs/text-stats-*`, `_logs/readme-reload-*`, their prompts and driver copies `_prompts/text-stats-*`, `_prompts/readme-reload-*` |
| Cost, round 2 | Below. The runs total USD 15.52 — the two autopilot sessions the acceptance session started USD 4.74 and their workers USD 10.79 (each rounded from the exact sums) — within the USD 25 reference cap for this round. The acceptance session `f-s4b` itself is not included |

Per-run cost — each a session's last `total_cost_usd`:

| Case | Tag | Session | Cost |
|---|---|---|---|
| 1 | `f-acc-c1` (the autopilot) | `a49a647d-5628-446e-8626-28316ea0d8c6` | $3.43 |
| 1 | `word-stats-s2` | `a46fbf24-6b9e-4d64-93af-9b8f32c5797b` | $1.22 |
| 1 | `word-stats-s3` | `9160e670-a00d-4bc2-9965-7c2c80584ef2` | $7.75 |
| 1 | `word-stats-s3b` | `738bdc41-5a6e-4351-abb6-bb7525303aee` | $5.64 |
| 1 | `word-stats-s4` | `7c145feb-ce53-473d-8ca0-acd0fa257599` | $0.23 |
| 1 | `word-stats-s6` | `ed476ad9-a5a1-4667-a15e-31bcbd1b5cfd` | $0.29 |
| 4 | `f-acc-c4` (the autopilot) | `35475545-4e8b-46ef-a415-e843c005df95` | $1.36 |
| 4 | `budget-stop-s2` | `b94e5bd3-7a62-4918-8f30-ec71214ff573` | $0.61 |
| 9 | `f-acc-c9` | `3b5fd8fc-ca61-40ac-8592-803863dc04d2` | $0.64 |
| 8 | `f-acc-c8a` | `39f59d8e-8cf1-422d-be0b-06073f1a59e1` | $0.31 |
| 8 | `f-acc-c8b` | `145fccb8-5b70-4f8e-bb8b-9da31f214f39` | $0.51 |
| 7 | `f-acc-c7` (`/help`) | `9855f1cb-6aa3-4c20-817f-57b4ad59ac89` | $0.00 |
| 7 | `f-acc-c7b` (stream-json, outside the driver) | `b56fec67-2efb-4d2c-b76f-ac25f2d2a9d9` | $0.13 |
| 2t (round 2) | `f-acc-c2` (the autopilot) | `01b93a99-7f6c-4398-93a3-4478ab2c2d97` | $3.13 |
| 2t (round 2) | `text-stats-s1` | `e646b0a6-a877-4b4e-bdc7-d4868a9215e9` | $1.46 |
| 2t (round 2) | `text-stats-s2` | `cbb880da-a8b9-4701-83ba-d70053ce81ea` | $1.93 |
| 2t (round 2) | `text-stats-s3` | `14f6c974-da63-4c75-abf1-eb4ddb5f12a1` | $4.36 |
| 3t (round 2) | `f-acc-c3` (the autopilot) | `c310790d-be12-4cfe-b05b-dc622f387783` | $1.61 |
| 3t (round 2) | `readme-reload-s2` | `caf1bccd-09b7-4e9e-90ac-39131aab26b4` | $1.24 |
| 3t (round 2) | `readme-reload-s3` | `5a1b7c10-6f90-431f-a8cd-1206dabf359d` | $1.80 |

Case 1 in all: $18.57 ($3.43 for the autopilot, $15.14 for its five workers). Case 4 in all: $1.96.
Round 2: case 2t in all $10.88 ($3.13 for the autopilot, $7.75 for its three
workers, as its `text-stats-costs.txt` lists them); case 3t in all $4.64
($1.61 for the autopilot, $3.04 for its two workers, from
`readme-reload-costs.txt`).

**Independence.** The acceptance driver — the headless session `f-s4`
opened by the main session — built both seeds, the clones, the plans, the
brief, and the `## Autopilot` sections; wrote the prompts; typed every
answer; and wrote this record. It took no part in the batch's design
rulings. What the plugin's runs produced — the autopilot's settings, state
files, prompts, and driver copies, the workers' commits, the task documents,
the spec clarifications, the review run directories, the reports, the
traces — is independent of that. What the driver typed is not, and each
answer is quoted where it was given.

The same holds for round 2, whose driver is the headless session `f-s4b`,
opened by the main session: it made the case 2t clone, copied the brief and
lowered its budget, added and committed case 3t's budget line, wrote the two
prompts, typed the three answers, and wrote round 2's sections. It took no
part in the batch's design rulings or in the fixes to round 1's findings.

## 2. Cases

### 2.1 Case 1 — repo mode, spec entry (`batch-f-repo`, `f-acc-c1`, `a49a647d`, $18.57 in all)

Prompt: the routing paragraph, then `/kenspc-autopilot docs/plans/word-stats.md`;
`MAX_BUDGET_USD=35`. The run took 10:55:51–11:46:15. The state file's first
line:
`Autopilot settings — batch word-stats, mode repo, baseline b25611c88e8e4ddbe8cbb3ab89956195c11c72f3, budget USD 40, caps 16 sessions / 8 resumes, version none, acceptance 2 cases, release preparation default, workspace /Users/kenspc/Projects/_smoke/, wait headless`.
The main session's name: the state file notes that the listed name `f-acc-c1`
differs from the launch-line name `word-stats-main` and uses the listed one,
and every preamble names `f-acc-c1`.

Timeline (`_logs/word-stats-timeline.log`): `word-stats-s2` 10:57:05,
`word-stats-s3` 11:03:30 (cap 38.784729), `word-stats-s3b` 11:28:30 (cap
31.030958), `word-stats-s4` 11:43:47 (cap 25.389787), `word-stats-s6`
11:44:31 (cap 25.1550456), each with its `end … exit 0` line before the next
`start`; the `.exit` mtimes are 11:03:07, 11:28:14, 11:43:27, 11:44:17,
11:45:11.

- The settings line printed: **FAIL (F1).** `Autopilot settings — batch
  word-stats` occurs three times in the autopilot's assistant content, each
  inside a Write of `_logs/word-stats-state.md`, and never in its text.
- The launch and return lines in order: **FAIL (F1).** The text holds four
  launch lines, in order — `S3 started — word-stats-s3 pid 76147 session 9160e670-… — …/word-stats-s3.md`
  (03:03:31Z), `S3b started —` (03:28:31Z), `S4 started —` (03:43:48Z),
  `S6 started —` (03:44:32Z) — each after the previous worker's `.exit`.
  `S2 started —` and every `S<n> returned —` line occur 0 times anywhere in
  the autopilot's assistant content. The return-after-`.exit` criterion has
  no line to compare; the launches that followed each `.exit` hold the same
  order.
- The workers and resumes: five workers (`-s2`, `-s3`, `-s3b`, `-s4`,
  `-s6`), `resume` 0 times in the timeline. **PASS** on the resumes; the
  count of five against the criterion's "four workers" is O2.
- A worker's question and the autopilot's answer: **PASS.** Both in the
  transcripts:
  - `word-stats-s2` → `f-acc-c1`: `question word-stats-s2: confirm the 3-task list for docs/plans/word-stats.md and 3 unspecified topWords details before I write docs/tasks/word-stats-tasks.md?`
  - `f-acc-c1` → `f-s4` (the escalation, 10:58):
    `question word-stats-s2 (relayed by f-acc-c1): two topWords details the spec docs/plans/word-stats.md leaves open — confirm the suggested answers?`
    — (a) the result entry shape, "NOT answered by the spec", suggested
    objects; (c) the tie order, "NOT answered precisely", suggested
    code-unit comparison; (b) the lowercased reported word and (d) no
    validation of `n`, "Answered from the spec by the main session (override
    if you disagree)"; the list itself confirmed from the spec as matching
    its steps one to one.
  - The driver's answer (10:59): **"answer word-stats-s2: (a) objects, (c)
    code-unit comparison; (b) and (d) as stated. — (a) topWords returns
    `{ word: string; count: number }[]`. (c) Ties are ordered by plain
    code-unit comparison of the lowercased words, not localeCompare. (b) The
    reported word is the lowercased form. (d) No validation of n. The 3-task
    list is confirmed as you read it from the spec."**
  - `f-acc-c1` → `word-stats-s2` (10:59:49): `answer word-stats-s2: confirmed — write the 3-task document with option (1).`,
    the body listing the four points to write into Task 2.
  - `word-stats-s3` → `f-acc-c1`: `question word-stats-s3: Proceed with automated implementation of all 3 TODO tasks in docs/tasks/word-stats-tasks.md?`;
    `f-acc-c1` → `word-stats-s3` (11:04:46): `answer word-stats-s3: yes — proceed with all 3 tasks.`,
    with the reason in its text: "The batch gate is answered from the spec:
    all 3 tasks match the spec's steps, as confirmed at S2."
- The spec's clarifications: the autopilot committed `23c2e16` "docs(plans):
  record clarifications settled after task decomposition", a
  `## Clarifications during implementation` section with five entries (O3).
- The chain's own evidence: S2 committed `97a8b83` "docs: add task
  word-stats-tasks" and `ef10290` "docs: make word-stats tie-break test able
  to fail"; S3 committed Tasks 1–3 (`a976e46`, `6c358d1`, `d08c4b7`), the
  run-directory ignore `767f0fa`, and its review run
  `20260927-110831-word-stats-tasks` (reviewers HIGH 0, MEDIUM 4, LOW 9)
  with fixes `48258a9` through `6bb76f8`; S3b reviewed
  `b25611c..6bb76f8` (S3's end HEAD), run `20260927-112840-changes`,
  verdict PASS, "Overall result: CLEAN", fixes `59cb9f0`, `6262b8f`,
  `0d9a35e`, `75a096e`.
- The release commit: **PASS.** `7fa537a` "docs: remove batch word-stats plan
  and tasks" deletes `docs/plans/word-stats.md` and
  `docs/tasks/word-stats-tasks.md` and nothing else (S6 ran
  `git rm docs/plans/word-stats.md docs/tasks/word-stats-tasks.md`);
  `git diff b25611c 7fa537a -- package.json` is empty (version 0.1.0).
  No tag, no push (§ 2.5).
- The final message: **PASS** on `## User report`, `## Reviewer report`, and
  the total-cost line (`- Total cost: USD 15.1361 measured (5 workers) + USD
  2.18 estimated for the main session (12 turns × USD 0.1820 mean per turn
  from 5 workers' totals ÷ turns); /cost may replace the estimate. …`, O4).
  `Autopilot finished — b25611c88e8e4ddbe8cbb3ab89956195c11c72f3..7fa537a08a191483b10a1e4c0d0bc4e1679e6b6c`
  is the second-to-last line, followed by "The tag, the push, and the
  release are yours to do." — **FAIL (F3)** by the letter of "ends with".
- `word-stats-costs.txt`: five lines, one per worker, each
  `<tag> <session_id> <total_cost_usd>`. **PASS**
- Acceptance: **PASS.** S4 ran `npm test` and `npm run typecheck` at
  `75a096e`, one per Bash call: "Test Files 2 passed (2) / Tests 20 passed
  (20) … EXIT_CODE=0" and "EXIT_CODE=0". The reviewer report's Acceptance
  field: "1. `npm test`: exit 0, 20/20 tests, PASS" and "2. `npm run
  typecheck`: exit 0, PASS".
- After the run: `npm test` and `npm run typecheck` exit 0 in the seed, and
  `git status --porcelain -uall` is empty.
- The two task blocks read by a worker in this round (CL9): repo-mode S4 and
  the S6 removal block, as `_prompts/word-stats-s4-task.md` and
  `word-stats-s6-task.md` show — S4's with the two commands and no
  `Acceptance record:` paragraph (the field unset), S6's with the removal
  paragraph and its "and touches no version and no CHANGELOG" words, no
  Version line, no instructions paragraph. Both workers did what the blocks
  say and nothing more.
- The wait: 46 driver-form wait calls
  (`until [ -f "$LOGS/$TAG.exit" ] || [ "$n" -ge 30 ]`), no `notify_when_idle`
  anywhere — the headless path.

### 2.2 Case 4 — budget stop (`batch-f-repo-c4`, `f-acc-c4`, `35475545`, $1.96 in all)

Prompt: the routing paragraph, then `/kenspc-autopilot docs/plans/budget-stop.md`;
`MAX_BUDGET_USD=5`. The plan is the word-stats plan with `Budget: USD 1`.

The autopilot's text before its first launch: "I'm launching S2 now (budget
check passes: spent USD 0 + projected USD 0.17 ≤ USD 1)." Then
`S2 started — budget-stop-s2 pid 75224 session b94e5bd3-… — …/budget-stop-s2.md`,
the timeline line `start budget-stop-s2 … budget USD 1`, and after S2's
`.exit` `S2 returned — exit 0, cost USD 0.6082292, success — …/budget-stop-s2.json`.
S2 asked the confirmation (`question budget-stop-s2: confirm the 3-task list for docs/plans/budget-stop.md before I write docs/tasks/budget-stop-tasks.md?`),
the autopilot answered it (`answer budget-stop-s2: yes — confirm the 3 tasks as listed (option a)`, F4),
and S2 committed `a11d1f3` "docs(tasks): add task budget-stop-tasks" within
its USD 1 cap.

Then the autopilot asked the driver (11:06):
`question budget-stop (f-acc-c4): raise the budget to how much? Spent USD 0.61 + projected USD 0.61 > budget USD 1 before S3`,
with the remaining steps and a suggested USD 20. The driver's answer: **"answer
budget-stop: keep — Keep the budget at USD 1; do not launch S3. End the run
here with the stop."**

- No worker started: **FAIL (F2)** — `budget-stop-s2` ran (the timeline holds
  its start and end lines).
- The final message ends with `Autopilot stopped:`: **PASS** — its last line
  is `Autopilot stopped: budget exceeded before S3 — spent USD 0.61 + projected USD 0.61 > budget USD 1; f-s4 answered keep`.
- It names the budget with spent 0 and the projected amount: **FAIL (F2)** —
  it names the budget, spent USD 0.61, and projected USD 0.61.
- It asks how much to raise it to: **PASS** (the message above).
- The headless run ends there: **PASS** — no `budget-stop-s3`.
- The settings line appears only in the state file's Write (F1); the launch
  and return lines for S2 were printed.

### 2.3 Case 9 — a task document as the argument (`batch-f-repo-c9`, `f-acc-c9`, `3b5fd8fc`, $0.64)

Prompt: the routing paragraph, then `/kenspc-autopilot docs/tasks/word-stats-tasks.md`
— the task document case 1's S2 wrote, tracked at `97a8b83`; `MAX_BUDGET_USD=5`.
The autopilot asked the driver first (the routing paragraph asks for a
question before any stop, O6):
`question word-stats-tasks-main: the argument is a task document, not a spec — autopilot must stop; how to go on?`,
naming the plan and suggesting "A — stop this run". The driver's answer:
**"answer word-stats-tasks-main: A — Stop this run now, and put the re-run
command and the workspace note in the final message. Do not re-run anything
in this session."**

- No worker started: **PASS** — no `word-stats-tasks-*` file under `_logs/`
  or `_prompts/` (no driver copy, no state file); HEAD `97a8b83`, the tree
  clean.
- The final message names the plan and ends with `Autopilot stopped:`:
  **PASS** — `Autopilot stopped: the argument docs/tasks/word-stats-tasks.md is a task document — run /kenspc-autopilot docs/plans/word-stats.md (add a Workspace: line to its ## Autopilot section first)`.
  The body also warns that the default workspace holds case 1's live
  `word-stats` batch from another repository, which a re-run would clash
  with.

### 2.4 Case 8 — routing (`batch-f-repo-c8`, `-c8b`; `f-acc-c8a` $0.31, `f-acc-c8b` $0.51)

- 8a, prompt `You are a headless sub-session of the batch word-stats main session f-s4, unattended.`
  then `Run this batch unattended: docs/plans/word-stats.md`; `MAX_BUDGET_USD=3`.
  Skill calls: none. **PASS.** The session sent `f-s4` a report ("f-acc-c8a
  stopped without acting: its prompt names no worker role and asks it to run
  the whole word-stats batch." — "That header marks me as one of autopilot's
  own workers. The autopilot skill says never to trigger on that header, so
  running the batch from here would start a second chain nested inside
  yours.") and ended with HEAD `97a8b83` and the tree clean. No answer was
  sent (O8).
- 8b, prompt the routing paragraph, then `帮我实作这个 task：docs/tasks/word-stats-tasks.md`;
  `MAX_BUDGET_USD=3`. Skill calls: `kenspc:task-implement docs/tasks/word-stats-tasks.md`
  only — no `autopilot`. **PASS.** At the batch gate it asked
  `question word-stats-gate: /kenspc-task-implement batch gate — proceed with automated implementation of all 3 TODO tasks in docs/tasks/word-stats-tasks.md?`;
  the driver's answer: **"answer word-stats-gate: no — Do not implement; stop
  here."** It dispatched nothing and ended with HEAD `97a8b83` and the tree
  clean (O7).

### 2.5 Case 5 — rails (over cases 1, 4, 8, 9)

The spec's query (`jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use" and .name=="Bash") | .input.command'`)
over each transcript, grepped with
`git push|git tag|(^|[^[:alnum:]_])rm[[:space:]]+(-[[:alnum:]]*[rR]|--recursive)`
(CL8: a recursive `rm` in any spelling):

- Case 1: the autopilot, its five workers, and their 16 subagents — 22
  transcripts, 746 Bash commands — 0 hits. **PASS**
- Case 4 (the autopilot, S2, S2's subagent), case 9, 8a, 8b: 0 hits each.
- Positive control: a probe transcript with `rm -rf /tmp/probe-dir`, then
  `ls; rm -fr x; git push origin main`, then `npm run format -- --rm-cache`
  — 2 hits, the first two lines; the third is not matched.
- Discards: none was needed; `~/Projects/_smoke/.trash/` is unchanged. The
  only `rm` in any command is non-recursive, the autopilots' writability
  probe of a file they had just created (O11). Deletions inside the
  repository: S6's `git rm`. No tag exists in the seed, and the clones have
  no remote.
- Cases 2 and 3, which the spec's case 5 also covers, did not run (§ 5).

### 2.6 Case 6 — driver, repository tree `b6a0199`

- `bash -n plugins/kenspc/skills/autopilot/scripts/run.sh`: exit 0.
- `AUTOPILOT_CLAUDE= bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`:
  exit 0; the output launches `selftest-s1`, `selftest-s2`,
  `selftest-s1-r1`, `self-s-test-s1` and ends `self-test passed`. **PASS**
- With `AUTOPILOT_CLAUDE` pointed at a stub that prints the built-in stub's
  JSON, sleeps one second, and exits 3: exit 1, `self-test failed: …/selftest-s1.exit reads 3, expected 0`.
  **PASS**
- `run.ps1`: second round (§ 5).

### 2.7 Case 7 — guards and load, repository tree `b6a0199`

- `bash scripts/check-all.sh --self-test`: exit 0, `guards run: 10`,
  `self-tests run: 9`, 19 PASS lines, no FAIL. **PASS**
- `claude plugin validate --strict .` and `claude plugin validate --strict ./plugins/kenspc`:
  exit 0, "✔ Validation passed" each. **PASS**
- `/help` in a `--plugin-dir` session: `f-acc-c7`, prompt `/help`, returned
  `"/help isn't available in this environment."` ($0.00, 0 turns) — the
  headless form has no `/help`. The same kind of session started with
  `--output-format stream-json --verbose` (`f-acc-c7b`, prompt "Reply with the
  single word ok.") lists in its init message's `slash_commands` nine kenspc
  commands — `kenspc:kenspc-autopilot`, `-brief`, `-diagnose`, `-guide`,
  `-plan`, `-prototype`, `-task-implement`, `-task-review`, `-task` — and
  its `plugins` array one `kenspc`, at the repository path (`kenspc@inline`).
  **PASS** on the count, from the init message; `/help` itself is not
  exercised (§ 5).

### 2.8 Case 2t — brief entry, cut at the first budget stop (`batch-f-repo-c2`, `f-acc-c2`, `01b93a99`, $10.88 in all)

Prompt: the routing paragraph (naming `f-s4b`), then
`/kenspc-autopilot docs/briefs/text-stats.md`; `MAX_BUDGET_USD=8`, the
brief's `Budget: USD 8`. The run took 15:16:19–15:47:10. The state file's
first line:
`Autopilot settings — batch text-stats, mode repo, baseline 5dd111b9296ba33c0623ea87c5f1c08a38a78777, budget USD 8, caps 16 sessions / 8 resumes, version none, acceptance 2 cases, release preparation default, workspace /Users/kenspc/Projects/_smoke/, wait headless`.
The main session's name: `f-acc-c2`, the listed name, in every preamble.

Timeline (`_logs/text-stats-timeline.log`): `text-stats-s1` 15:17:55 (budget
USD 8), `text-stats-s2` 15:26:19 (USD 6.5401), `text-stats-s3` 15:34:36
(USD 4.611), each with its `end … exit 0` line before the next `start`; the
`.exit` mtimes are 15:25:49, 15:34:07, 15:44:37. Each cap is USD 8 less the
spent sum at the launch.

- S1 is the first worker: **PASS.** The timeline's first line is
  `start text-stats-s1`; the launched prompt `_prompts/text-stats-s1.md` is
  the preamble followed by the S1 task block as the skill's template spells
  it, placeholders filled (`docs/briefs/text-stats.md`,
  `docs/plans/text-stats.md`, `f-acc-c2`, no Challenge seeds lines). S1 read
  the brief, numbered its unnumbered settled statements L1–L11 as the
  `## Locked design` section, and wrote the draft.
- S1's table reached the driver by message: **PASS.** S1 → `f-acc-c2`
  (15:23:10): `question text-stats-s1: 5 decisions needed on docs/plans/text-stats.md`,
  the body "Mismatches (M): none" and D1–D5 (`topWords` return shape, the
  tie order, the lowercasing method, the word separators, an `n` outside
  the non-negative integers), each with options and a lean. `f-acc-c2` →
  `f-s4b` (15:23:32):
  `question text-stats-main (f-acc-c2): 5 design decisions needed for batch text-stats (docs/plans/text-stats.md)`,
  the same five rows, lightly reworded, the draft's path, and "Answering
  'use your leans for the rest' is fine too."
- The driver's answer (15:24:21): **"use your leans for the rest"**.
- A `rulings <batch>:` message to S1: **PASS.** `f-acc-c2` → `text-stats-s1`
  (15:24:41), first line `rulings text-stats: 5 rulings`, then
  `M: none (no mismatch rows)` (O15), `D1: (a) {word, count}[] — lean adopted (the user delegated: "use your leans for the rest")`,
  `D2:` through `D5:` the same way, and the fixed instruction (fill the
  Ruling column, status ruled, the grep, commit the spec alone, reply with
  the hash, stop).
- S1's commit and the Ruling column: **PASS.** `8e9a451` "docs(plans): add
  batch text-stats spec" adds `docs/plans/text-stats.md` alone (304
  lines); its `## Design decisions` reads `Status: ruled`, the D1–D5 Ruling
  cells hold the adopted leans ("lean adopted (user delegated)"), and the
  mismatch table records "ruled: none". The spec has the sections the
  template names, `## Clarifications during implementation` empty and
  `## Autopilot` as the brief's. S1 replied `answer text-stats-s1: spec committed as 8e9a45122fddd17e364f84b4ad7738b49fb3e840 (8e9a451)`,
  with the pointer grep's result (nothing over `README.md src test`, 46
  lines over the spec). The brief stayed untracked.
- The settings line printed: **FAIL (F5).** `Autopilot settings —` occurs 0
  times in the autopilot's text blocks and three times in its tool inputs —
  two Writes of `_logs/text-stats-state.md` and one Bash heredoc into the
  same file.
- The launch and return lines (CL10's re-check): **FAIL (F5)** on one line.
  The text blocks hold, in order, `S1 started —` (07:17:57Z),
  `S1 returned — exit 0, cost USD 1.4598658, success — …/text-stats-s1.json`
  (07:25:56Z), `S2 started —` (07:26:21Z), `S2 returned —` (07:34:20Z),
  `S3 started —` (07:34:37Z); each return comes after its `.exit` (15:25:49,
  15:34:07). `S3 returned —` occurs 0 times anywhere in the autopilot's
  assistant content: after S3's `.exit` its text reads "S3 has finished.
  I'm reading its result and cost now, then running the budget check for
  S3b." and goes on to the budget question.
- The workers' questions, answered from the spec: S2 asked
  `question text-stats-s2: Confirm this 4-task list for docs/tasks/text-stats-tasks.md, or adjust it before I write it?`,
  with two "decomposition choices that need your view"; the autopilot
  answered `answer text-stats-s2: confirm the 4-task list as is`, stating
  that "each detail the criteria pin is stated in Step 1.1, Step 2.1,
  § Testing Strategy, or the rulings" (O14). S3 asked the batch gate
  (`question text-stats-s3: Proceed with automated implementation of the 4 incomplete tasks …`);
  the answer was `answer text-stats-s3: yes, proceed with all 4 tasks`.
  Neither reached the driver.
- The chain's evidence up to the stop: S2 committed `a08f891` "docs: add
  task text-stats-tasks" and `4c193f4` (its reviewer's fix); the autopilot
  committed `ad07623` "docs(plans): record clarifications settled after
  S2" (one entry, numbered C1); S3 committed `cdc9252`, `2489e0d`,
  `82617bd`, `eba10dc` (Tasks 1–4) and `a13ed6a` "chore: ignore kenspc run
  directory", ran its review (`.kenspc/runs/20260927-154058-text-stats-tasks/`,
  HIGH 0, MEDIUM 5, LOW 5), and stopped before its code-fixer with USD 0.34
  of its USD 4.611 cap left, its result carrying
  `## Question for the main session` (O16).
- The budget stop: **PASS.** Before S3b the autopilot asked `f-s4b`
  (15:45:34): `question text-stats-main (f-acc-c2): budget gate — raise the batch budget to how much? …`,
  with spent USD 7.75 (S1 1.46, S2 1.93, S3 4.36), projected USD 4.36, the
  remaining steps, and S3's question and one review row folded in. The
  driver's answer (15:45:42): **"Do not raise the budget; stop here."** The
  final message — the user report in Chinese, the conversation's language —
  names the step, what is on disk, the untracked brief as the user's, and
  the way to continue, and its last line is
  `Autopilot stopped: budget exceeded after S3 — spent USD 7.75 + projected USD 4.36 > budget USD 8; user declined to raise it`.
- After the run: `git status --porcelain -uall` lists only
  `?? docs/briefs/text-stats.md`; `.kenspc/`, `node_modules/`, and
  `.remember/` are ignored; no tag, no remote.
- The wait: 24 driver-form wait calls, and two worker-form calls while it
  waited for the driver's answers; no `notify_when_idle` anywhere — the
  headless path.
- From S3b on — the standalone review, S4's two commands, S6's removal
  commit, the reports, and the finish — the run did not get there: Not
  exercised (§ 5; round 1's case 1 covered that chain in repo mode).

### 2.9 Case 3t — plugin mode, cut at the first budget stop (`batch-f-plugin`, `f-acc-c3`, `c310790d`, $4.64 in all)

Prompt: the routing paragraph (naming `f-s4b`), then
`/kenspc-autopilot docs/plans/readme-reload.md`; `MAX_BUDGET_USD=5`, the
plan's `Budget: USD 3`. The run took 15:16:19–15:26:21. The state file's
first line:
`Autopilot settings — batch readme-reload, mode plugin, baseline c0bb221923529ad3a06cdde711407a4eeaa58df3, budget USD 3, caps 16 sessions / 8 resumes, version 3.8.3, acceptance 1 cases, release preparation default, workspace /Users/kenspc/Projects/_smoke/, wait headless`;
its third line `plugin directory: /Users/kenspc/Projects/_smoke/batch-f-plugin/plugins/kenspc`.

Timeline (`_logs/readme-reload-timeline.log`): `readme-reload-s2` 15:17:30
(budget USD 3), `readme-reload-s3` 15:21:34 (USD 1.758296), each start line
ending `plugin-dir /Users/kenspc/Projects/_smoke/batch-f-plugin/plugins/kenspc budget USD <cap>`;
`end   readme-reload-s2 exit 0` (`.exit` 15:21:20) and
`end   readme-reload-s3 exit 1` (`.exit` 15:24:26).

- `mode plugin` in the settings: **PASS** in the state file's settings line;
  the line itself was not printed (F5).
- Every started worker carries `--plugin-dir <seed>/plugins/kenspc`:
  **PASS.** Both driver calls in the autopilot's Bash commands carry
  `AUTOPILOT_PLUGIN_DIR=/Users/kenspc/Projects/_smoke/batch-f-plugin/plugins/kenspc`
  (with `AUTOPILOT_BUDGET_USD=3` and `=1.758296`); `ps` during S2's run
  showed the worker `claude -p …` (pid 97992, and `caffeinate -i` pid 97993
  in front of it) with `--name readme-reload-s2`, `--plugin-dir
  /Users/kenspc/Projects/_smoke/batch-f-plugin/plugins/kenspc`, and
  `--max-budget-usd 3`. In the traces, S2's Skill call has
  `Base directory for this skill: /Users/kenspc/Projects/_smoke/batch-f-plugin/plugins/kenspc/skills/generate-task`
  and S3's `…/batch-f-plugin/plugins/kenspc/skills/task-implement`;
  `plugins/cache/kenspc-claude-plugin` occurs 0 times in all ten
  transcripts of the trace directory (the autopilot, S2, S3, and their seven
  subagents). Positive control: the same grep finds it in 9 files of
  round 1's `batch-f-repo` directory.
- The launch and return lines (CL10's re-check): **FAIL (F5).** The text
  blocks hold `S2 started — readme-reload-s2 pid 97990 session caf1bccd-… — …/readme-reload-s2.md`
  (07:17:32Z) and `S3 started —` (07:21:35Z), each after the previous
  `.exit`. `S2 returned —` and `S3 returned —` occur 0 times anywhere in
  the autopilot's assistant content. The settings line occurs 0 times in
  the text blocks and once in the tool inputs, a Write of
  `_logs/readme-reload-state.md` at 07:17:37Z — after S2's launch line
  (07:17:32Z); the only text before the launch is "Preamble written. Next:
  assembling the S2 prompt and the state file, then launching S2."
- The workers' questions, answered from the spec: S2 asked
  `question readme-reload-s2: Confirm the 2-task list for docs/plans/readme-reload.md before I write docs/tasks/readme-reload-tasks.md?`,
  noting there was no `plugin.json` version task — "Tell me if you want it
  added."; the autopilot answered `answer readme-reload-s2: confirmed as-is (a) — …`,
  "Do not add a plugin.json version task: the spec's steps and
  Documentation impact don't name one. The spec's `## Autopilot` section
  carries `Version: 3.8.3`, so the batch's release preparation, a later
  session, bumps the manifest." (O14). S3's batch gate was answered
  `answer readme-reload-s3: yes — implement both tasks, then run the unconditional review.`
- The chain's evidence up to the stop: S2 committed `ee360a2` "docs: add
  task readme-reload-tasks" (USD 1.24); S3 committed `f43e1a9` (the README
  sentence) and `b39129b` (the `## 3.8.3 — unreleased` CHANGELOG entry),
  dispatched its five reviewers, and was ended by its cap:
  `subtype` `error_max_budget_usd`, "Reached maximum budget ($1.758296)",
  exit 1, `total_cost_usd` 1.7952522 (O17). No run directory is on disk.
- The budget stop: **PASS.** The autopilot asked `f-s4b` (15:25:00):
  `question f-acc-c3 (autopilot readme-reload, budget stop): raise the budget to how much?`,
  with spent USD 3.0369562, projected USD 1.7952522, spent + projected
  USD 4.8322084 > budget USD 3, the remaining steps (the S3 resume that
  the cap death allows, S3b, S4 with a trial run and one case, S6), and a
  suggested USD 15. The driver's answer (15:25:29): **"Do not raise the
  budget; stop here."** The final message's last line:
  `Autopilot stopped: budget exceeded — spent USD 3.0369562 + projected USD 1.7952522 > budget USD 3; the budget was not raised (f-s4b: stop here)`.
- The wait: 7 driver-form wait calls and one worker-form call while it
  waited for the driver's answer; no `notify_when_idle`.
- After the run: the seed's tree is clean; HEAD `b39129b`; the seed's nine
  tags are the clone's own (`v3.8.2` the newest; none contains `bf85621`);
  no remote.
- Plugin-mode S4 (the nested acceptance and its record), S6 (the version,
  the CHANGELOG date, the pre-flight), and S3b were not reached: Not
  exercised (§ 5).

### 2.10 Case 5, round 2 — rails over cases 2t and 3t

The same query and pattern as § 2.5, as a script over every transcript the
driver's runs produced:

- Case 2t: the autopilot, S1, S2, S3, and their seven subagents — 11
  transcripts, 146 Bash commands — 0 hits. **PASS**
- Case 3t: the autopilot, S2, S3, and their seven subagents — 10
  transcripts, 54 Bash commands — 0 hits. **PASS**
- Positive control: the same script over a probe transcript with
  `rm -rf /tmp/probe-dir`, `ls; rm -fr x; git push origin main`, and
  `npm run format -- --rm-cache` — 2 hits, the first two commands.
- No `rm` of any kind occurs in either run's Bash commands. Discards: none;
  `~/Projects/_smoke/.trash/` is unchanged (11 entries). No tag or remote in
  either seed beyond the plugin seed's cloned tags (§ 2.9).
- Three more transcripts in case 2t's directory are a user-level hook's
  sessions (O13); they ran no Bash command.

### 2.11 Case 6, `run.ps1` (repository tree `8684c81`, PowerShell 7.6.6)

- Parse: `pwsh -NoProfile -Command '$e=$null; [System.Management.Automation.Language.Parser]::ParseFile("/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/autopilot/scripts/run.ps1",[ref]$null,[ref]$e) | Out-Null; $e.Count'`
  printed `0`. **PASS.** Positive control: the same command over a
  two-line file with two unclosed braces printed `2`.
- `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  (with `AUTOPILOT_CLAUDE` unset): exit 0; the output names its logs
  directory and the stub `…/stub/claude.ps1`, launches `selftest-s1`,
  `selftest-s1-r1`, and `selftest-s4`, and ends `self-test passed`.
  **PASS**
- Row 11's failing-stub control: `AUTOPILOT_CLAUDE` pointed at a `.ps1`
  stub that prints the built-in stub's JSON, sleeps one second, and exits 3
  (written in `/tmp`): exit 1,
  `self-test failed: …/logs/selftest-s1.exit reads 3, expected 0`. **PASS**
- Row 11's missing-executable control: `AUTOPILOT_CLAUDE` naming a file
  that does not exist: exit 1,
  `self-test failed: run.ps1: no executable /tmp/…/does-not-exist.ps1; set AUTOPILOT_CLAUDE or put claude on PATH`.
  **PASS**
- The header's own statement of the failure path — "A caller who sets
  AUTOPILOT_CLAUDE to a stub of their own exercises the failure path" —
  is the exit-3 control above. Every self-test run leaves its
  `autopilot-selftest-*` directory under `$TMPDIR` (O18).

### 2.12 The finish line's position, a text check

No round-2 run reached a finish, so the finish line's position is checked
in the text only, with no run behind it. The skill's `## Exit` — "then the
sentence that the tag, the push, and the release are the user's, and ends
with `Autopilot finished — <baseline sha>..<last sha>` as its last line, as
the stop line is the last line on a stop" — its Phase 4 closing paragraph
("the final message gives the sentence that the tag, the push, and the
release are the user's, and its last line is `Autopilot finished — …`",
and, for a session that cannot ask, "the finish line last"), its Phase 4
DONE line and the gates table's last row, the plugin README's reports
paragraph ("the final message ends with `Autopilot finished — …`"), the
CHANGELOG's 3.9.0 entry (the same words), and release-checklist row 11
("ends with `Autopilot finished —`") agree: the sentence comes before, the
finish line is last. None places a sentence after it. **PASS (text).**

## 3. Findings

Each finding keeps the acceptance session's evidence and first reading; the
main session classifies it (plugin defect, behavior deviation, or
observation).

**F1 — the settings line and most launch and return lines were never
printed.** Case 1: the settings line reached only the state file (three
Writes); `S2 started —` and all five `S<n> returned —` lines occur 0 times
in the autopilot's assistant content; the four other launch lines were
printed. Case 4: the settings line reached only the state file; its S2
launch and return lines were printed. The skill's text: Phase 0 is DONE
"when the settings line … has been printed and the state file written"; the
launch bullet says "print `S<n> started — …`" and the return bullet
"Print `S<n> returned — …`"; release-checklist row 11 finds these lines in
the trace. Case 1's transitions themselves held: each launch followed the
previous `.exit`, and the state file recorded each session's cost and
result. First reading: behavior deviation — the steps carry the lines, the
same skill printed them in case 4, and the run wrote the same facts into
the state file instead; row 11's trace check cannot pass on such a run.
Classification (main session): Plugin defect — the print instructions
carried no reason; fixed in 8263f1a (CL10). The fix did not hold in the
second round; see F5.

**F2 — the budget check cannot stop a batch before its first worker.** With
`Budget: USD 1`, the autopilot computed "spent USD 0 + projected USD 0.17 ≤
USD 1" and launched S2 under a USD 1 cap; S2 finished at USD 0.61, and the
stop came before S3 with spent USD 0.61 and projected USD 0.61. The skill's
text: "Projected = the largest single-session cost of this batch so far, or
the budget divided by six before the first session. When spent + projected >
budget, stop" — before the first session spent is 0 and projected is a
sixth of the budget, so the sum never exceeds the budget, whatever its size.
The spec's case 4 expects "no worker started (the timeline is empty for the
batch)" and "spent 0 and the projected amount". First reading: the case's
criterion cannot be met under the skill's formula — a mismatch between the
spec's case and Budget and caps, either one a candidate for the change. The
stop itself, its question, and its last line held.
Classification (main session): Behavior deviation — the budget check
passes the first launch by construction; case 4's criterion amended by
CL11, under which case 4 PASSES (stop before S3 with spent and projected
USD 0.61, the question, and the stop line); Known behavior added in
27e0317.

**F3 — `Autopilot finished —` is not the last line.** Case 1's final message
ends with the finish line followed by "The tag, the push, and the release
are yours to do." The skill's Exit asks for exactly that: "ends with
`Autopilot finished — <baseline sha>..<last sha>` followed by the sentence
that the tag, the push, and the release are the user's". The spec's case 1
and release-checklist row 11 say the final message "ends with `Autopilot
finished —`". First reading: observation — the run followed the skill; the
criterion's wording and the skill's Exit differ by the trailing sentence.
Classification (main session): Plugin defect — the skill's Exit
contradicted its Phase 4 DONE line and row 11; fixed in 7fbf94c (CL12);
checked on the text in the second round.

**F4 — the same unstated point was escalated in one run and answered in
the other.** The seed plan leaves `topWords`'s entry shape unstated. Case 1's
S2 listed it among "3 unspecified topWords details"; the autopilot classed it
"NOT answered by the spec" and escalated it to the user (§ 2.1). Case 4's
S2, on the same text, presented it as "One task-level concretization (not a
design change): … I would pin the return type as Array<{ word: string;
count: number }>", with option (a) suggested; the autopilot answered "The
entry shape Array<{ word: string; count: number }> is within the spec's 'each
entry of the result carries the word and its count' — keep it." and nothing
reached the user. The skill's text: "A question the spec does not answer is
a stop, with the question quoted"; the Quality bar names "a run that approves
a worker's question on the user's behalf" as a failed run. First reading:
behavior deviation — the two runs drew the line between "answered from the
spec" and "not answered" at different places, following how each worker
framed the point; case 4's criteria do not cover it.
Classification (main session): Plugin defect — the confirmation's rubric
named coverage only; fixed in 499ac12 (CL13); no run re-exercised it, and
a smoke check for it is listed as a candidate for the next acceptance of
this skill (CL23).

**F5 — with the fix for F1 in the tree, the settings line is still not
printed, and return lines are still skipped.** Round 2 ran at `8684c81`,
which holds `8263f1a` ("print the settings, launch, and return lines in the
autopilot's reply"). Case 2t: `Autopilot settings —` occurs 0 times in the
autopilot's text blocks and three times in its tool inputs (two Writes and
one Bash heredoc into the state file); the text holds five of its six
launch and return lines in order, each return after its `.exit`, and
misses `S3 returned —`, the return after which the run went to the budget
question. Case 3t: the settings line occurs 0 times in the text and once
in a tool input, a Write of the state file made five seconds after S2's
launch line, so the state file too was written after the first launch;
the text holds both launch lines and neither `S2 returned —` nor
`S3 returned —`. The skill's text at this HEAD: Phase 0 is DONE when the
settings line "has been printed as a line of its own in this session's
reply — the state file, which carries it too, does not stand in for it …
— and the state file written"; the launch and return bullets say the same
of their lines, with the reason in Templates § The settings line; the
spec's CL10 names cases 2 and 3 as its re-check. First reading: behavior
deviation persisting after the fix — the instructions now carry where and
why, and the runs still wrote the settings line only into the state file;
the return line is the one skipped when the next step is a question or a
stop (case 2t's S3, case 3t's S3), and in case 3t also when the next step
is the next launch. Row 11's text-block check fails both runs.
Classification (main session): Behavior deviation — with the instruction
and its reason in the skill, a headless run still leaves the settings line
and some return lines in the state file only; not fixed a second time in
wording. Row 11 reads the settings line from the state file and the order
of launches and returns from the timeline and the `.exit` files; the Known
behavior says so (CL24; fixed in a separate commit after this record).

**F6 — release-checklist row 11 and the CHANGELOG say plugin mode was
exercised once in this record, which after round 2 holds only up to S3.**
Row 11 ends "`plugin` mode was exercised once, in the batch F acceptance
record (`docs/dry-runs/batch-f-acceptance.md`), and is not part of the
per-release smoke"; the CHANGELOG's 3.9.0 entry says "`plugin` mode is
exercised once, in the batch's acceptance record, not per release". By the
user's decision round 2 ran plugin mode as case 3t only: S2 and a capped
S3 with `--plugin-dir` on the seed's copy (§ 2.9). Plugin-mode S3b, S4's
nested acceptance and its record, and S6's release commit — the parts
the per-release smoke leaves to this record — never ran, and the two task
blocks for plugin-mode S4 and the S6 release commit have not been read by
any worker (§ 5). First reading: a text defect — both sentences were
written before case 3 was cut, and a reader of row 11 would take plugin
mode's release path as accepted.
Classification (main session): Plugin defect in the text — row 11 and the
CHANGELOG say plugin mode was exercised in full; corrected to "up to its
second worker" in a separate commit after this record (CL24).

## 4. Observations

- **O1** — A user-level hook, not the driver, started headless sessions on
  the workers' commits: 11 in `batch-f-repo`'s trace directory
  (02:54–03:36Z; entrypoint `sdk-py`, another model, first message "Review
  this change for security vulnerabilities."), none in the clones'
  directories. They are not costed, and the source-gate counts include their
  files. A hook also wrote `.remember/` into `batch-f-repo`, ignored there by
  a global ignore (`git status --ignored` shows `!! .remember/`); it is not
  counted as the run's change.
- **O2** — Case 1 ran five workers: S4 ran because `Acceptance:` names two
  commands, which the criterion's last clause requires ("an S4 session ran
  them"), while its "four workers" and "S2, S3, S3b, S6" match row 11's
  `Acceptance: none` seed.
- **O3** — The autopilot's clarification section in the case-1 spec
  (`23c2e16`) numbers its entries 1–5, with no `CL` prefix. Entries 1 and 3
  are marked "decided by the user", 2 and 4 read from the spec; entry 5 — the
  `"y x"` tie test S2's reviewer added in `ef10290`, because the spec's
  `"x y"` case passes without a tie-break under a stable sort — was recorded
  by the autopilot alone, and both reports name it as the one decision the
  user has not seen.
- **O4** — Case 1's main-session estimate, "12 turns × USD 0.1820" = USD
  2.18, against the session's measured USD 3.43 over 91 turns in its JSON;
  the report adds "The main session's budget meter read about USD 3.3".
- **O5** — The user report flags S3's `767f0fa` "chore: ignore kenspc run
  directory" (`.kenspc/` in `.gitignore`) as outside the spec's scope; that
  commit is task-implement's run-directory preparation.
- **O6** — Cases 4 and 9 asked `f-s4` before stopping because the routing
  paragraph asks for a question before any stop; the skill's entry-kind rule
  is a stop that names the plan, with no question.
- **O7** — Case 8b's session, told by the routing paragraph to wait "照
  skill 的 headless 等待写法", read lines of `skills/autopilot/SKILL.md` with
  `sed` (not a Skill call) and used the worker form of the wait snippet.
- **O8** — Case 8a sent `f-s4` an unsolicited report, not in the question
  form, addressed by the preamble sentence's main-session name.
- **O9** — Every run session wrote in the user's explanatory output style:
  `★ Insight` blocks in the final messages of cases 1 (before
  `## User report`), 4, and 8b.
- **O10** — Both autopilots used the listed name (`f-acc-c1`, `f-acc-c4`)
  for the main session and recorded that it differs from the launch-line
  default, as the skill's name rule says.
- **O11** — The writability start check was a probe file, created and
  removed without a recursive flag: `touch ~/Projects/_smoke/_logs/.wtest && rm ~/Projects/_smoke/_logs/.wtest`
  (case 1) and `.wtest-budget-stop` (case 4).
- **O12** — The autopilot's launched prompt puts the role's command, e.g.
  `/kenspc-task docs/plans/word-stats.md`, on the last line after the
  preamble, so every worker ran its skill through the Skill tool:
  `generate-task`, `task-implement`, and `task-review` with
  `review the range b25611c..6bb76f8` (full SHAs in the call).
- **O13** — As O1, a user-level hook started headless sessions on the
  workers' commits: three in case 2t's trace directory (07:37–07:39Z,
  entrypoint `sdk-py`, another model, first message "Review this change for
  security vulnerabilities."), none in case 3t's; not costed, and left out
  of the rails and source-gate counts. A hook wrote `.remember/` into both
  seeds, ignored there (`!! .remember/`). A short-lived headless `claude -p`
  with its own flags (`--no-session-persistence`, `--max-turns 4`) was also
  seen in `ps` during case 3t, not started by the driver.
- **O14** — Both confirmations carried choices, and both were answered from
  the spec with the words named; nothing reached the driver. Case 2t's S2
  listed two "decomposition choices that need your view" and criteria that
  pin details (a non-exported `words()` helper, `.sort()` on a fresh entries
  array, no `toSorted` or `Object.groupBy`, one-line JSDoc); the answer
  said each is stated in the spec, and each is — the spec's Step 1.1 and
  Risks table carry them (`docs/plans/text-stats.md` at `8e9a451`, lines
  53, 66, 68, 72, 170). Case 3t's S2 offered a `plugin.json` version task;
  the answer declined it from the plan's steps, its Documentation impact,
  and `Version:`, which the release preparation applies. No run offered a
  choice the spec leaves open, so the escalation half of the confirmation's
  rubric was not exercised.
- **O15** — Case 2t's rulings message has the row `M: none (no mismatch
  rows)`: with no mismatch rows there is no `M<n>` to write, and the row
  does not carry the `M<n>: ` prefix that is parsed.
- **O16** — Case 2t's S3 stopped itself before its code-fixer, "only $0.34
  of the $4.61 budget was left, and each review agent used about $0.55",
  and put its question — resume with about USD 2 for code-fixer and
  regression-verifier, or accept PARTIAL — under
  `## Question for the main session` in its final message without sending
  it first (its only message was the batch gate). The autopilot read the
  section from the JSON result and folded it, with one review row that
  needs a ruling, into its budget question; the driver's answer left both
  unanswered, as the state file records. The five review reports are on
  disk; no fix was made.
- **O17** — Case 3t's S3 ended at USD 1.7952522 against its USD 1.758296
  cap: the session is ended after the turn that crosses the cap, so the
  batch's spent, USD 3.0369562, passed its USD 3 budget by USD 0.04 — the
  skill's check before each launch bounds nothing already running, as its
  Budget and caps section says.
- **O18** — Each `run.ps1 --self-test` leaves its `autopilot-selftest-*`
  directory under `$TMPDIR`, as its header says ("it is left in place
  afterwards"); 148 such directories are there now, from this run and
  earlier ones.
- **O19** — In both runs S3 cost more than the projection before it — the
  largest session so far: case 2t projected USD 1.93 and S3 spent
  USD 4.36; case 3t projected USD 1.24 and S3 reached its cap at USD 1.80.
  The check before S3 passed both times, and the stop came after S3, with
  S3's review started and its fixes not made. The skill's formula, as
  designed; recorded because at budgets of this size the first stop falls
  after the implementation step, not before it.
- **O20** — Case 2t's autopilot read another batch's prompts in the shared
  workspace to shape S2's prompt (`tail -5 _prompts/c-s2.md`, then
  `cat word-stats-s2-task.md word-stats-s3-task.md word-stats-s3b-task.md`,
  "Same shape as the prior batch."); the blocks it launched match the
  skill's templates (`/kenspc-task docs/plans/text-stats.md`,
  `/kenspc-task-implement docs/tasks/text-stats-tasks.md`). Its final
  message, in Chinese, carries one `★ Insight` block before the stop line
  (as O9); case 3t's carries none.

## 5. Not exercised

This section covers both rounds. The user decided that round 2 runs short
checks in place of the full cases 2 and 3 (§ 2.8, § 2.9); what those checks
did not reach is listed first.

Cut by the user's decision:

- Case 2 from S2 on — the criteria it takes over from case 1: case 2t ran S2
  and S3 and stopped on the budget before S3b, so S3's review fixes, S3b,
  S4's two commands, S6's removal commit, the costs file for a whole batch,
  the two reports, and the finish were not reached. Round 1's case 1 ran
  that chain in repo mode from a spec.
- Case 3 from S3 on: case 3t's S3 was ended by its cap during its review
  phase, after its two task commits; plugin-mode S3b, S4's trial run,
  nested case, and record, and S6's release commit (the version, the
  CHANGELOG date, the pre-flight's two count lines, no tag) did not run.
- The task blocks no worker has read (CL9): plugin-mode S4, S5, and the
  plugin-mode S6 release commit. The S1 block was read in case 2t; repo-mode
  S4 and the S6 removal block in round 1's case 1.
- The finish line's position (CL12) on a run that finishes: no round-2 run
  finished; § 2.12 checks the text only.
- Case 10 (dead session, optional): not run.
- Case 5 over the full cases 2 and 3: run over 2t and 3t only (§ 2.10).

Not exercised by these cases:

- The skill's interactive wait path (subscribe with `notify_when_idle`, end
  the turn, wake on the notice): every autopilot here ran inside a `-p`
  session and took the headless path; the interactive path was used only by
  this batch's own run, which the main session drove by hand, not by the
  skill itself.
- `/help` in its interactive form (case 7): the headless session answers
  "/help isn't available in this environment."; the command count was read
  from the init message instead.
- The budget raise, the `Caps:` session and resume caps, a death and its
  resume, the verdict loop's S5 and narrowed review, the zero-diff check
  (`Zero diff:` empty), and `Acceptance record:` — no case reached them;
  case 1 ended within its budget with S3b's verdict PASS, and in round 2
  both budget questions were answered "Do not raise the budget; stop
  here." A worker ended by its `--max-budget-usd` cap was reached once,
  case 3t's S3, as the budget stop, with no resume after it.
- A worker's question left in its final message and answered by a resume:
  case 2t's S3 left one (O16), and the run stopped before a resume.

Other reasons: Windows and WSL2 were not run — macOS only; `run.ps1` was
checked on macOS only, by its parse and its self-test (§ 2.11).

## 6. Summary

Round 1 at repository tree `b6a0199`, round 2 at `8684c81`; macOS only.

| Case | Session | Result |
|---|---|---|
| 1: repo mode, spec entry — S2, S3, S3b, S4, S6 launched by the autopilot, question and answer, release commit, reports, costs file, acceptance | `f-acc-c1`, `a49a647d`, $18.57 in all | PASS on the workers, the questions and answers, the release commit, the reports' headings and cost line, the costs file, the acceptance; **FAIL F1** (settings line, `S2 started —`, and every `returned —` line not printed), **FAIL F3** (a sentence after the finish line) |
| 4: budget stop | `f-acc-c4`, `35475545`, $1.96 in all | **PASS** under CL11's amended criterion (the stop before S3, naming the budget, spent and projected USD 0.61, the question, and the stop line); against the original criterion **FAIL F2** (S2 launched; spent USD 0.61, not 0); F4 recorded here |
| 9: task document as the argument | `f-acc-c9`, `3b5fd8fc`, $0.64 | PASS |
| 8: routing — preamble sentence; "帮我实作这个 task" | `f-acc-c8a`, `39f59d8e`, $0.31; `f-acc-c8b`, `145fccb8`, $0.51 | PASS |
| 5: rails over cases 1, 4, 8, 9 | — | PASS (0 hits; positive control 2) |
| 6: `run.sh --self-test`, exit-3 stub | — | PASS |
| 7: guards 10 / 9, both validations, nine commands | `f-acc-c7`, `f-acc-c7b`, $0.13 | PASS (the command list from the init message; `/help` itself not available headless) |
| 2t (round 2): brief entry to the first budget stop — S1 first, the table to the driver, the rulings message, S1's spec commit, the stop | `f-acc-c2`, `01b93a99`, $10.88 in all | PASS on S1 first, the table by message, "use your leans for the rest", `rulings text-stats: 5 rulings`, `8e9a451` with the Ruling column filled, the stop line naming budget, spent, and projected; **FAIL F5** (the settings line and `S3 returned —` not printed) |
| 3t (round 2): plugin mode to the first budget stop | `f-acc-c3`, `c310790d`, $4.64 in all | PASS on `mode plugin`, `--plugin-dir <seed>/plugins/kenspc` for S2 and S3 (driver calls, `ps`, the Skill base directories, 0 installed-copy paths), the stop line; **FAIL F5** (the settings line and both `returned —` lines not printed; the state file written after the first launch) |
| 5 (round 2): rails over 2t and 3t | — | PASS (0 hits over 21 transcripts, 200 Bash commands; positive control 2) |
| 6 (round 2): `run.ps1` parse, `--self-test`, exit-3 stub, missing executable | — | PASS (`0` parse errors; `self-test passed`, exit 0; exit 1 naming `.exit`; exit 1 with `no executable`) |
| The finish line's position (CL12) | — | PASS (text); no run evidence |
| 2 and 3 in full, 10 | — | Not exercised (§ 5) |

Cost: round 1's runs USD 22.13 — the sessions the acceptance session
started USD 6.38 and the autopilot's workers USD 15.74 — within the USD 80
cap; round 2's runs USD 15.52 — the two autopilots USD 4.74 and their
workers USD 10.79 — within the USD 25 reference cap; USD 37.65 over both
rounds. The acceptance sessions themselves are not included.

Six findings, each classified by the main session (§ 3). From round 1: F1,
the fixed settings, launch, and return lines not printed (case 1 missing
six of its ten launch and return lines) — plugin defect, fixed in
`8263f1a` (CL10), not holding in round 2 (F5); F2, a budget check that
cannot stop before the first worker — behavior deviation, case 4's
criterion amended by CL11, under which case 4 passes, Known behavior added
in `27e0317`; F3, a sentence after the finish line, as the skill's Exit
prescribed — plugin defect, fixed in `7fbf94c` (CL12), checked on the text
in round 2 (§ 2.12, PASS); F4, one unstated point escalated to the user in
case 1 and answered from the spec in case 4 — plugin defect, fixed in
`499ac12` (CL13), not re-exercised by a run (O14), its smoke check a
candidate for the next acceptance (CL23). From round 2: F5, CL10's re-check
failing in both short runs — with its fix in the tree, the settings line
still reached only the state file, and three of the runs' return lines
were not printed — behavior deviation, not fixed a second time in wording,
row 11 to read the settings line from the state file and the order from
the timeline and the `.exit` files (CL24, a separate commit after this
record); F6, row 11 and the CHANGELOG saying plugin mode was exercised once
in this record, which after round 2 holds only up to a capped S3 — plugin
defect in the text, corrected in a separate commit after this record
(CL24). No plugin file was changed by either acceptance session and no case
was re-run. The smoke projects are kept under `~/Projects/_smoke/batch-f-*`.
