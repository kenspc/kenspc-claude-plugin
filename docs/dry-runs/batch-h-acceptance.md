# Batch H acceptance — init-project fixes and AGENTS.md native-loading compatibility (4.1.0, unreleased)

Acceptance record for batch H (spec: `docs/plans/batch-h-init-project-4-1.md`,
§ 2.5; clarifications C1–C13): the § 2.5 cases B1–B13, each in the mode
§ 2.5 names for it. One machine, macOS with Claude Code 2.1.283,
2026-09-28; the headless runs 06:54–07:08 UTC. The plugin under test is the
repository tree `ba2b215`, HEAD before the first run and after the last;
the main session's later commit `d7949ac` (clarification C13) touched only
the spec. The four acceptors recorded the evidence and their verdicts; the
main session classified the results and the observations in C13. This
record was compiled from the acceptors' reports by a session that took no
part in implementing, reviewing, or running the acceptance.

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — the run gave
the criterion nothing to check.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree `ba2b215` (HEAD before the first run and after the last; nothing was committed to the repository while the runs went on; afterwards the main session committed `d7949ac`, clarification C13, `docs/plans/batch-h-init-project-4-1.md` only). Under test: `plugins/kenspc/skills/init-project/SKILL.md` (1051 lines) with the 12 files under its `templates/`, entered through `plugins/kenspc/commands/kenspc-init.md`; for B13, `plugins/kenspc/skills/generate-plan/SKILL.md`; for B1 and B12, the batch's text across the plugin, its README, the CHANGELOG, and the repository CLAUDE.md. `plugin.json` still reads 4.0.0; the `## 4.1.0 — unreleased` CHANGELOG entry is the batch's |
| Machine | macOS (Darwin 25.6.0), hostname `KENSPC-MBP` (`hostname -f` → `KENSPC-MBP`, no dot). Claude Code 2.1.283, git 2.55.0, node 24.19.0 / npm 12.0.2; `gh` installed and logged in as `kenspc`; `dotnet`, `python3`, `pnpm`, and `yarn` present; `go` absent. The global git config carries the identity `Sim Poh Chuan <kenspc@hotmail.com>` and no `commit.gpgsign`. The user settings set the built-in agents-md plugin's `instructionFiles` to `claude-md-and-agents-md`, not the default (environment note below) |
| Mode H | Real headless sessions, one per case run, cwd the seed under `~/Projects/_smoke/batch-h/`, started from the seed by `acceptor-h` as `nohup bash -c '… claude -p --permission-mode bypassPermissions --plugin-dir "/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc" --settings '{"pluginConfigs":{"agents-md@builtin":{"options":{"instructionFiles":"claude-md-or-agents-md"}}}}' --append-system-prompt "Work without stopping; do not ask clarifying questions." --output-format json "<prompt>" < /dev/null > _logs/h/<case>.json 2> _logs/h/<case>.err; echo $? > <case>.rc' &`, the wrapper recording start, end, and exit code; each waited on with `timeout 570 caffeinate -w <pid>` until `ps -p` showed the wrapper gone, with no background-task notification relied on. `--settings` pins the default mode `claude-md-or-agents-md` (§ 2.5: every H case unless stated); the appended system prompt makes each session one that cannot ask. Every session ran on the environment's default model, `claude-opus-5-5` by each result's `modelUsage`. Cases B2 (three runs), B3, B4, and B13 |
| Mode S | An acceptance subagent followed SKILL.md's text step by step in the seed, as the session running `/kenspc-init`, and sent each question the skill would ask — one message per message the skill would send, rendered as the AskUserQuestion call it would make (header, question, options, descriptions) where the skill would use one — to the main session by `SendMessage`; the main session answered as the user only from `accept-scripts.md`, and "跳过这一题" to anything the script did not cover. The whole conversation was in Chinese. Cases B5–B8 (`acceptor-s1`) and B9–B11 (`acceptor-s2`) |
| Mode P | Step 1.3's probes (`.kenspc/runs/batch-h/verify.md`): one headless session per layout and `instructionFiles` mode, ground truth each session's `instructions` attachment; plus one confirming probe of `acceptor-static`'s own (B1-P). Case B1 (§ 2.1) |
| Static | `acceptor-static`, read-only on the repository, against the tree at `ba2b215`; the release checklist's pre-flight block run from the repository root. Case B12 |
| Scripted answers (S) | Anything not covered below: "跳过这一题"; never "其余全部用默认". B5: the file list — "确认". B6: the `@AGENTS.md` import question — "不要加 import"; the file list — "确认". B7: the file list — "确认". B8: the `.claude/CLAUDE.md` import question — not scripted ("跳过这一题"); the file list — "确认". B9: round 1 — "预填的名称和一句话简介确认，其余跳过这一题"; the file list — "确认". B10: the file list — "跳过这一题" (the case under test). B11: round 2 — "monorepo，目前只有一个 app：web，是用 npm 的 React + TypeScript 网页前端"; scaffolding `web` — "要，用 Vite 官方的 create-vite，React + TypeScript 模板"; round 3 — "有 UI，平台是 web，选定 shadcn/ui + Tailwind"; the file list — "确认". Every case but B10 confirms the file list so that the commit path runs and its contents can be checked; every answer is Chinese because the user works in Chinese, so every S case also exercises N1 |
| Seeds | One directory per case run under `~/Projects/_smoke/batch-h/`, built fresh (each setup in § 2): H `b2-1`, `b2-2`, `b2-3`, `b3`, `b4`, `b13-agents`, and `b13-b2` (`cp -a b2-1` after B2 ended); S `b5`–`b8` (each `git init -q -b main` and one `chore: initial commit` with the configured identity, no remote) and `b9`, `b10`, `b11` (empty, no git); P `b1-import-noplugin` (moved to `.trash/` afterwards, with step 1.3's probe directories). `~/Projects/_smoke/batch-h`, `~/Projects/_smoke`, and `~/Projects` hold no CLAUDE.md, AGENTS.md, or `.claude/` and are not inside a git repository; above them only the user's `~/.claude/CLAUDE.md`, which the default mode's check does not count (`verify.md` § 1) |
| Evidence | H: per case run the prompt, the result JSON, `.err` (every one empty), `.rc` (every one 0), the start and end times, snapshots before and after (`ls -A`; sha256 of every file outside `.git`; the `.git` entries; `git rev-parse --show-toplevel`, `HEAD`, `symbolic-ref HEAD`; `git status --porcelain -uall`; `git log --format='%h %an <%ae> %s'`), the `instructions` attachment and every tool call, and each Bash command with its result, under `~/Projects/_smoke/batch-h/_logs/h/`; the transcripts under `~/.claude/projects/-Users-kenspc-Projects--smoke-batch-h-<seed>/`. S: `acceptor-s1`'s snapshots before and after each case in `~/Projects/_smoke/batch-h/_logs/s1/`; `acceptor-s2`'s snapshots, Phase 0 probes, verbatim transcripts, and B11's generator and install output in the run directory's `scratch/accept-s2/`. P and static: `acceptor-static`'s pre-flight script and output, the MUST control copy, and B1-P's JSON and debug logs in `scratch/acceptor-static/`. The reports (`accept-h.md`, `accept-s1.md`, `accept-s2.md`, `accept-static.md`), the scripts (`accept-scripts.md`), and B1's probe table (`verify.md`) live in the batch's git-ignored run directory, `.kenspc/runs/batch-h/`; none of this evidence is part of the repository |
| Cost | The headless sessions USD 8.12 (below). Step 1.3's 45 probe sessions, whose table B1 reuses, cost USD 1.31 (`verify.md` § 6) and are not included. S mode started no session of its own. The acceptors and the main session are not included |

Per-run cost — each a session's `total_cost_usd`:

| Case | Seed | Session | Turns | Cost |
|---|---|---|---|---|
| B2, run 1 | `b2-1` | `e19e3ad9` | 23 | $1.0507 |
| B2, run 2 | `b2-2` | `9b6919b6` | 22 | $1.0501 |
| B2, run 3 | `b2-3` | `18d30446` | 24 | $0.9786 |
| B3 | `b3` | `548026e6` | 21 | $0.9609 |
| B4 | `b4` | `c0e8c59f` | 20 | $0.8889 |
| B13, load probe | `b13-agents` | `fa134b07` | 1 | $0.1382 |
| B13, AGENTS.md only | `b13-agents` | `ee6d6be1` | 9 | $1.4327 |
| B13, on B2's seed | `b13-b2` | `a49aa9eb` | 8 | $1.5807 |
| B1-P, probe and control | `b1-import-noplugin` | `6a5e2bf4`, `f3029679` | — | $0.0346 |
| **Total** | | | | **$8.1154** |

The five init runs ran in parallel in separate seeds, 06:54:12–06:57:07Z;
each session is independent, one `total_cost_usd` per session, no resume.
The H sessions alone come to $8.0808.

**Environment note.** Four things on this machine bear on the H runs,
none of them the plugin under test; C13 classifies each as environment.
The remember plugin's SessionStart hook created `.remember/`, holding its
own `.gitignore` of `*`, in every seed before the skill's Phase 0 scan, so
every init run met a self-ignoring directory and had to count the seed
empty under N3, which it did every time (O1); in step 1.3 the same plugin
leaked a previous probe's answer between sessions, so the probes ran with
it disabled (§ 2.1). The security-guidance plugin's PostToolUse hook ran on
every commit command and skipped its review each time (O2). The
explanatory output style put `★ Insight` blocks into five of the final
messages; the verdicts rest on files, git state, exit codes, and
transcripts, not on the messages' wording (O3). And this host's name,
`KENSPC-MBP`, has no dot, so under B4's empty git configuration git's own
guess fails as well, and B4 cannot tell the new identity test (C10 E4:
`git config user.name` and `user.email` must both print a value) from the
old `git var` test (O19). Separately, the user's `~/.claude/settings.json`
sets `instructionFiles` to `claude-md-and-agents-md`, and that setting is
read only from user settings, `--settings`, or managed settings, never from
the project (§ 2.1, confirmed by step 1.3's P6). Every H session therefore
pins the default mode with `--settings`, as § 2.5 prescribes: without it
each session would run in the user's mode, where AGENTS.md loads beside a
CLAUDE.md, rather than the default mode § 2.5 asks for, in which a
CLAUDE.md silently stops AGENTS.md.

**Independence.** The four acceptors — `acceptor-h` (B2 three times, B3,
B4, B13), `acceptor-s1` (B5–B8), `acceptor-s2` (B9–B11), and
`acceptor-static` (B1 and B12) — took no part in implementing or reviewing
the batch. `acceptor-h` built the H seeds, launched the sessions, and read
their results; what the headless sessions wrote and committed is
independent of it. B1's result table is step 1.3's, recorded by the
verifier before implementation began; `acceptor-static` reproduced it,
checked every sentence against it, and ran one probe of its own. In S mode
the acceptor carried out the skill's text itself, so an S case shows what
the text gives when it is followed step by step by one reader, not how a
session that loaded the skill behaves; in particular every Chinese question
in B9 was worded by the acceptor, so the drift N1 guards against cannot
show there, and the user re-runs B9 in the Mac TUI (§ 5). The answers came
from the main session, from the scripts above.

## 2. Cases

### 2.1 B1 — the four modes' loading behavior (P; step 1.3's probe layouts and `b1-import-noplugin`)

B1's method is step 1.3's probes, recorded in `verify.md`: one headless
`claude -p … --model haiku --output-format json --debug-file … < /dev/null`
session per layout and mode, the mode passed through `--settings`. Ground
truth is each session's `instructions` attachment in its transcript, with
the agents-md plugin's own debug lines beside it; the model's answer
matched the attachment in every cell. The remember plugin's
`.remember/now.md` leaked a previous probe's answer into two first-pass
cells, so it was disabled for every later session and the four cells that
had carried the injection were re-run clean. `~/.claude/CLAUDE.md` (type
User) loaded in every cell except `managed-only` and is left out below.

Codewords: L1 `AGENTS.md` ORCA-3M9; L2 `CLAUDE.md` LYNX-8P2, `AGENTS.md`
HERON-5V7; L3 `CLAUDE.md` (line 1 `@AGENTS.md`) TAPIR-2K6, `AGENTS.md`
IBIS-9W4; L4 `CLAUDE.local.md` MOLE-6J3, `AGENTS.md` NEWT-1X8; L5
`.claude/CLAUDE.md` WREN-4D5, `AGENTS.md` YAK-7C2.

| Layout | `claude-md` | `claude-md-or-agents-md` (default) | `claude-md-and-agents-md` | `managed-only` |
|---|---|---|---|---|
| 1 AGENTS.md only | nothing | ORCA-3M9 — AGENTS.md (native) | ORCA-3M9 — AGENTS.md (native) | nothing, not even `~/.claude/CLAUDE.md` |
| 2 CLAUDE.md + AGENTS.md | LYNX-8P2 — CLAUDE.md | LYNX-8P2 — CLAUDE.md only | LYNX-8P2 + HERON-5V7 — both | nothing |
| 3 CLAUDE.md `@AGENTS.md` + AGENTS.md | TAPIR-2K6 + IBIS-9W4 (through the import) | TAPIR-2K6 + IBIS-9W4 (through the import) | TAPIR-2K6 + IBIS-9W4; AGENTS.md once | nothing |
| 4 CLAUDE.local.md + AGENTS.md | MOLE-6J3 — CLAUDE.local.md | MOLE-6J3 only | MOLE-6J3 + NEWT-1X8 — both | nothing |
| 5 `.claude/CLAUDE.md` + AGENTS.md | WREN-4D5 — `.claude/CLAUDE.md` | WREN-4D5 only | WREN-4D5 + YAK-7C2 — both | nothing |

Extra layouts, in the default mode unless stated:

| Layout | Files (codeword) | Loaded |
|---|---|---|
| L6 | `.claude/AGENTS.md` only (SWAN-3B6) | SWAN-3B6 (native) |
| L7 | root `CLAUDE.md` (GECKO-5N2); `pkg/AGENTS.md` (BISON-7L4); cwd `pkg/` | GECKO-5N2 only |
| L8 | `CLAUDE.md` above the git root (MOTH-4G9); `repo/AGENTS.md` (DINGO-1S3); cwd `repo/` | MOTH-4G9 only |
| L9 | `AGENTS.md` (CRANE-8Z5), `CLAUDE.md` a symlink to it; `claude-md-and-agents-md` | CRANE-8Z5 once, under the CLAUDE.md path |
| L1, plugin disabled | `"enabledPlugins":{"agents-md@builtin":false}` | nothing; no agents-md lines in the debug log |

Other step 1.3 probes the sentences rest on: P6 (a project
`.claude/settings.json` setting `instructionFiles: "claude-md"` is ignored,
with a hook as positive control); InstructionsLoaded (native L1 and L2 fire
nothing for AGENTS.md, the L3 import fires with `load_reason: include`; a
symlink was not hook-probed); the 2.1.277 floor (docs only); subagent
visibility (a general-purpose subagent sees a native AGENTS.md; Explore,
Plan, and an `omitClaudeMd` agent do not); built-in `/init` probes i7–i10.
Two in-batch probes outside the table: the implementer's import-path probe
(in `.claude/CLAUDE.md`, `@../AGENTS.md` loads the root AGENTS.md and
`@AGENTS.md` does not) and review-2's and review-3's (an own-line or
whitespace-bounded mid-line import loads; a trailing `.` or `,`, a `)`,
`(@…)`, a code span, and `admin@…` do not).

**B1-P, `acceptor-static`'s confirming probe.** SKILL.md:722 says the
import loads AGENTS.md "whatever the mode and the environment", and H3's Why
(SKILL.md:645–646) keeps the import because "before v2.1.277, or with the
built-in agents-md plugin disabled, nothing reads it"; the table has no
cell for an import with the plugin disabled. Seed `b1-import-noplugin`:
`git init -b main`; `CLAUDE.md` = `@AGENTS.md`, blank, `# Project notes`,
blank, `Codeword: KESTREL-6R1`; `AGENTS.md` = `# Project notes`, blank,
`Codeword: MARMOT-2Q8`; neither codeword in `~/.claude/CLAUDE.md` or the
run directory. Step 1.3's command form with `--max-turns 1`, the default
mode, and both the remember plugin and `agents-md@builtin` disabled in
`--settings`; the control the same with agents-md enabled; both exit 0.

| Session | agents-md lines in debug log | `instructions` attachment (ground truth) | Answer |
|---|---|---|---|
| `6a5e2bf4` probe, plugin disabled | 0 | User `~/.claude/CLAUDE.md`; Project `…/CLAUDE.md` (KESTREL-6R1); Project `…/AGENTS.md` (MARMOT-2Q8) | both codewords, both paths |
| `f3029679` control, plugin enabled | 13 (`hooks module agents-md@builtin loaded …`, `plugin.register: agents-md … admitted`) | identical file list | both codewords, both paths |

With the built-in plugin disabled, the `@AGENTS.md` import still loads
AGENTS.md; with the table's disabled-plugin row (no import, nothing loads),
the import is what keeps AGENTS.md loaded where native reading is off.

The sentences, found with `git diff 7b58a59..ba2b215` over the § 2.3 files
and a grep of the whole diff for the loading vocabulary (`load`,
`default mode`, `instructionFiles`, `2.1.27`, `InstructionsLoaded`,
`native`, …), checked one by one in `accept-static.md` § 1.3 (S1–S17,
R1–R8, M1–M3, C-1–C-12):

| Condition | Evidence | Verdict |
|---|---|---|
| init-project SKILL.md, S1–S14: the definition (130–135), a `.claude/` file (187–190), the import path (191–194), why a CLAUDE.md is written beside an AGENTS.md (236–239), H3's Why (640–648), the declined-import message (704–712), "already loads" (715–723), the gate row and Exit (977, 999–1001) | S1: loading varies by mode (L1, L2, L4, L5 rows); S2: L5 matches L2 in every column, L6 matches L1 × default; S3: the implementer's probe; S4: L1 × default → L2 × default, L3 × default, `/init` i7's follow-up; S5: L2 × default, L4 × default, P6; S6: the disabled row and B1-P, the version floor from docs, worded per C1; S7: native L1 and L2 fire nothing, the L3 import fires, the symlink half from docs, worded per C2; S9: the L2 and L5 rows, the disabled row; S10, S11: the L3 row; S12: L9, L3, `/init` i8 (`See @AGENTS.md for …` loaded AGENTS.md), the review-2 and review-3 probes; S13: the L3 row and B1-P; S14: pointers to S9, the old "(AGENTS.md not yet loaded)" gone | agrees — 13 sentences; S8 n/a (not a loading claim); S3 on a probe outside the table; S12 with the known residual R3-2 (C12); S13 in every mode that loads CLAUDE.md (O10) |
| `shared/instruction-files.md:5`, the H5 clause of task-implement and task-review, code-fixer's NOT APPLICABLE Why (S15–S17) | S15: every row's columns; the setting's sources, P6; S16: L1 × default → L2 × default, L3; S17: L2 × default and × `claude-md`, the `managed-only` column, the subagent rows | agrees (3 of 3) |
| Plugin README (R1–R8) | R1 as S1; R2 as S2 (L5, L6); R3 as S3; R4 as S9, S10; R5 as S12; R6 the L1 and L2 rows by column, the version from docs; R7 as S4; R8 `/init` i7, i9, i10, the docs (C3), L2 × default | agrees (8 of 8; R8 with O12) |
| Repository CLAUDE.md (M1–M3) | M1: L2, L7; M2: as S15 and the subagent rows; M3: as S1 | agrees (3 of 3) |
| CHANGELOG `## 4.1.0 — unreleased` (C-1–C-12) | C-1: L1 × default, the disabled row; C-3: L3; C-4: L2, L5, L4, L7, L8 × default, "silently" per `verify.md` § 3; C-5 as S7; C-6 as S16; C-7 as R8; C-8 as S9; C-9 as S5–S8 and B1-P; C-10 as S3; C-11 as S12, S13; C-12: the L2 and L3 rows, `managed-only` | agrees — 11; C-2 n/a (describes the old text); C-7 with O12; C-9 with O11; C-11 in every mode that loads CLAUDE.md (O10) |
| Every sentence § 2.3 wrote agrees with the result table | the rows above; the three claims the table does not cover (the import path from `.claude/`, punctuated imports, the import with the plugin disabled) rest on an in-batch probe or B1-P. No telemetry, provider, `/memory`, `/context`, or feature-flag claim (C1, C2) in the plugin text, its README, the CHANGELOG entry, or the lines the batch added to CLAUDE.md: the grep's only hits in the plugin are unrelated (generate-guide's third-party accounts, `run.ps1`, bug-reviewer's "telemetry call", README:980), its positive control; the CHANGELOG entry and the CLAUDE.md lines exit 1 | **PASS** |

Observations from this case: O1 (the leak in step 1.3), O10–O14.

### 2.2 B2 — empty directory, cannot ask, one-sentence argument (H ×3; `b2-1`, $1.05; `b2-2`, $1.05; `b2-3`, $0.98)

Seed: `mkdir b2-1 b2-2 b2-3`, each empty (`ls -A` printed nothing before the
run). Prompt: `/kenspc-init A habit tracker for small remote teams.` (each
transcript's `queue-operation` holds exactly this). At session start the
remember plugin created `.remember/` in each seed (O1).

Bash commands, the same shape in all three (b2-1 shown): `ls -A` and
`LC_ALL=C git rev-parse --is-inside-git-dir` / `--show-prefix` (both
`fatal: not a git repository`, rc 128); `ls -la .remember` and
`od -c .remember/.gitignore` (`*\n`); `git config user.name` /
`user.email` (both set); `LC_ALL=C git init -b main`; the templates read;
nine Writes and a `cp` of the backlog README; a checks script (line budget,
first line, template comment, Documents paths against the README, secrets
with a positive control, TBD form, `{{`, `git check-ignore --no-index -v`);
`git status --porcelain -uall` and `git check-ignore -q` per file;
`git add -- <10 paths>`, then
`git commit -q -m "docs: initialize project documentation" -- <10 paths>`;
a marker count. No `git push`, `git remote add`, `gh repo create`, or
`gh label create` in any run (`gh auth status` read once each).

Result in each seed: branch `main`, one commit `docs: initialize project
documentation` by `Sim Poh Chuan <kenspc@hotmail.com>`, the configured
identity; 10 files; `git status --porcelain -uall` empty; no remote.
Commits: `b2-1` `3457441`, `b2-2` `eec725c`, `b2-3` `af306ca`.

`docs/product.md` in each: the template is five headings with one slot
each, so every line that is neither a heading nor a marker is the run's
own.

| Run | Section | Sentence | Stated by the argument? |
|---|---|---|---|
| b2-1 | Purpose | "A habit tracker for small remote teams." | Yes — the argument verbatim |
| b2-1 | Users | "Small remote teams, to track habits." | Yes — who (small remote teams) and for what (habit tracking) are both the argument's |
| b2-2 | Users | "Small remote teams, who use it to track habits." | Yes — as above |
| b2-2 | Scope | "A habit tracker for small remote teams." | Yes — the argument verbatim |
| b2-3 | Users | "Small remote teams, who use it to track habits." | Yes — as above |
| b2-3 | Scope | "Habit tracking for small remote teams." | Yes — a restatement of the argument; no feature named |

Everything else in the three files is `TBD(init):` — the problem it
solves, the roles within a team, the features in scope, the non-goals, the
terms (b2-1 5 markers, b2-2 4, b2-3 5). No problem, feature, role,
non-goal, or term was invented. The other topic documents and the README
hold only the argument's sentence, template text, and markers (every
non-heading, non-marker line of `README.md`,
`docs/architecture/overview.md`, `docs/ui/design-system.md`,
`docs/release.md`, and `docs/deployment.md` checked in all three).

The final message (b2-1, trimmed; b2-2's and b2-3's are drawn on in the
table below and in O4, O15, and O16):

> The project is initialized: I ran `git init` on `main`, wrote 10 files
> and committed them as `3457441 docs: initialize project documentation`.
> … **Starting state:** the directory was empty and had no git. Its only
> content was `.remember/`, which ignores itself entirely, so it counts as
> empty. … That's 37 `TBD(init):` placeholders in total. The only real
> content is the one-line summary and "Small remote teams, to track
> habits.", both taken from your description. The fact check didn't have
> to turn any sentence into a placeholder.

| Condition | Evidence | Verdict |
|---|---|---|
| b2-1: `docs/product.md` makes no product claim beyond the argument | the table above: two sentences, both the argument's; 5 markers | **PASS** |
| b2-2: same | two sentences, both the argument's; 4 markers | **PASS** |
| b2-3: same | two sentences, both the argument's; 5 markers | **PASS** |
| All three: the final message lists the sentences turned into `TBD(init):` (if any) | each says none was turned ("The fact check didn't have to turn any sentence into a placeholder" / "the source check had nothing to strip" / "The source check didn't turn any sentence into a marker"). Consistent with the transcripts: each `docs/product.md` was written by one Write and never edited (the only Edit in any B2 run is b2-3's AGENTS.md version line), so no sentence was turned. The runs' checks scripts mechanize § Checks except the source check, which each did by reading | **PASS** (×3) |
| § Exit: start point, each file and what happened | all three: empty, no git, `.remember/` self-ignoring; every file created | PASS-level, no gap |
| § Exit: commits with hash and subject | all three | no gap |
| § Exit: markers counted per file | all three give per-file counts matching `git grep -c 'TBD(init):'` (b2-1 37, b2-2 36, b2-3 37). b2-3's stated total "41" disagrees with its own per-file table (sums to 37) and the tree (37) | **OBSERVATION** (b2-3 total miscounted; O16) |
| § Exit: every default a session that cannot ask took | git, name, shape, interview, scaffolding, GitHub, backlog listed in all three; push and labels as not applicable. None names "the file list: committed as presented" as a taken default (b2-1: "wrote 10 files and committed them") | **OBSERVATION** (file-list default not named; O17) |
| § Exit: what is left for the user; next step | the manual GitHub steps; `/kenspc-init` again, `/kenspc-brief` or `/kenspc-plan` | no gap |

Observations from this case: O4, O15–O17.

### 2.3 B3 — empty directory holding one self-ignoring directory (H; `b3`, $0.96)

Seed: `mkdir b3 && cd b3 && mkdir .tool && printf '*\n' > .tool/.gitignore`
(before: `ls -A` → `.tool`; `.tool/.gitignore` sha256 `cdbcae15…`). Prompt:
`/kenspc-init A shared reading list for a book club.` At session start the
remember plugin added `.remember/` too, so the run met two self-ignoring
directories. Bash 1: `ls -A` → `.remember`, `.tool`; both
`LC_ALL=C git rev-parse` probes `fatal: not a git repository`, rc 128.
Bash 2: `ls -la` and the `.gitignore` bytes of both → `*  \n`. Bash 4:
`git init -b main` → `Initialized empty Git repository in …/b3/.git/`,
rc 0; `symbolic-ref -q HEAD` → `refs/heads/main`. Then the checks, a
`git check-ignore -q` per file, and
`git add -- <10 paths> && git commit -q -m "docs: initialize project documentation" -- <10 paths>`,
rc 0. The final message (trimmed):

> `b3` is initialized: I created a git repository on `main`, wrote the
> project files, and committed them as `1cc75f4 docs: initialize project
> documentation` (author Sim Poh Chuan). All the skill's checks passed
> before the commit, and the working tree is clean. … **Starting point:**
> the folder was empty with no git. `.remember/` and `.tool/` each ignore
> their own contents, so they don't count as files and aren't in the
> repository. … Only two sentences came from your description: "A shared
> reading list for a book club." and "A book club." Nothing had to be
> turned into a marker.

| Condition | Evidence | Verdict |
|---|---|---|
| Judged the directory empty | Bash 1–2 above; the final message's start point "empty with no git", naming both directories as self-ignoring. The run went to Phase 1 (no "Files, no git" question or stop) | **PASS** |
| Ran `git init` | Bash 4: `git init -b main`, `Initialized empty Git repository …/b3/.git/`; after: `symbolic-ref HEAD` → `refs/heads/main`, `show-toplevel` → the seed | **PASS** |
| Did not stop | commit `1cc75f4 docs: initialize project documentation`, 10 files (247 insertions); `git status --porcelain -uall` empty; rc 0 | **PASS** |
| `.tool/` untouched and outside the commit | after: `.tool/.gitignore` sha256 `cdbcae15…` unchanged; `git show --stat HEAD` lists only the 10 run files; `git status --ignored` → `!! .tool/.gitignore`, `git check-ignore -v` → `.tool/.gitignore:1:*` | **PASS** (supporting) |

Observations from this case: O15, O18.

### 2.4 B4 — no git identity (H; `b4`, $0.89)

Setup: `: > ~/Projects/_smoke/batch-h/empty-gitconfig` (0 bytes);
`mkdir b4`, empty. Under
`GIT_CONFIG_GLOBAL=~/Projects/_smoke/batch-h/empty-gitconfig GIT_CONFIG_NOSYSTEM=1`,
`git config user.email` and `git config user.name` both exit 1 (rc 0
without the variables). The session started with both variables exported,
as `ps eww` of the running `claude` process confirmed; the seed never got
a repository-level identity. Prompt:
`/kenspc-init An inventory tracker for a small bakery.`

Bash (8 commands): Bash 2, the Phase 0 probes (not a git repository,
rc 128) and `git config user.name; git config user.email` → no output.
Bash 4, `git config --show-origin --get-all user.name` → rc 1, the same for
`user.email`; no `GIT_AUTHOR_*` or `GIT_COMMITTER_*` in the environment.
Bash 6, `LC_ALL=C git init -b main`; `symbolic-ref` → `refs/heads/main`;
`git config user.name` and `user.email` both rc 1. Bash 7–8, the checks
(49 + 5 = 54 lines, the first line, the template comment, 8 Documents paths
= 8 README paths, the secret scan with a 3-hit positive control, the TBD
form, `{{`, `check-ignore --no-index -v`), then
`git status --porcelain -uall` → the 10 files `??`. No `git add` and no
`git commit` anywhere. The final message (trimmed):

> Per § Confirm and commit, the run stops before the documentation commit
> because git has no identity. … # The project is set up, but nothing is
> committed. Git has no identity on this machine: `user.name` and
> `user.email` are unset in every scope. So the run wrote all the files and
> made no commit. All checks pass. … ## What's left for you 1. **Set a git
> identity**, then make the commit: `git config --global user.name "<your
> name>"` … `git add -- <10 paths>` / `git commit -m "docs: initialize
> project documentation" -- <10 paths>` …

| Condition | Evidence | Verdict |
|---|---|---|
| Stops before any commit | after: `git rev-parse HEAD` → `fatal: ambiguous argument 'HEAD'`, rc 128; `git log` → `fatal: your current branch 'main' does not have any commits yet`; no `git add` or `git commit` among the 8 Bash commands | **PASS** |
| The written files are all in the working tree | after, `git status --porcelain -uall`: `?? .gitignore`, `?? AGENTS.md`, `?? CLAUDE.md`, `?? README.md`, `?? docs/architecture/overview.md`, `?? docs/backlog/README.md`, `?? docs/deployment.md`, `?? docs/product.md`, `?? docs/release.md`, `?? docs/ui/design-system.md` (untracked, nothing staged); the sha256 of each in `b4.after.snap` | **PASS** |
| The final message says why | "Git has no identity on this machine: `user.name` and `user.email` are unset in every scope. So the run wrote all the files and made no commit." | **PASS** |
| No Bash command contains `-c user.` | the 8 Bash `command` fields extracted with `jq` (`select(.type=="assistant") … select(.type=="tool_use" and .name=="Bash") \| .input.command`, 42 lines) → `grep -n -e '-c user\.'` rc 1 (no match). Positive control on the same file: `grep -c -e '-c core\.'` → 2 (the run's `git -c core.quotePath=false status`). The transcript as a whole has 2 lines with `-c user.`: the `tool_result` of the `cat SKILL.md` and the final text block — neither a command. No Bash command set an identity either (`git config` was only read) | **PASS** |

No app was scaffolded, and the message names the missing identity among
the reasons; in a session that cannot ask nothing is scaffolded anyway, so
the identity check's place before scaffolding is Not exercised (§ 5).

Observations from this case: O7 (four scratch files left in `/tmp`), O15,
O19.

### 2.5 B5 — existing repository tracking `docs/briefs/` and `docs/plans/` files (S; `b5`)

Seed: `README.md` (3 lines: `# Notepad`, a blank line, `A small
note-taking service with a sharing feature in progress.`), `package.json`
(`name` notepad, `version` 0.3.0, `scripts.test` `node --test`),
`src/index.js`, `docs/briefs/2026-09-01-sharing.md` (4 lines),
`docs/plans/2026-09-10-sharing.md` (5 lines: a share token, a read-only view
at `/s/<token>`, links expiring after 30 days); no CLAUDE.md, AGENTS.md, or
`.gitignore`; `29717e4 chore: initial commit`. First message:
`/kenspc-init 帮我把这个 repo 初始化给 kenspc 用`. Phase 0: an existing
repository on `main`, no remote, no instruction file, no `.claude/`;
`git ls-files -- docs/briefs docs/plans docs/tasks` → the two files. The
brief and the plan were read, as Phase 0's Inputs name them; nothing from
them was used (O30).

Question 1 opened with the language line
(`本次执行的对话语言：中文（按你的讯息）。之后的每个问题和最后的总结都用中文；写进档案的内容用英文。`);
rounds 1–5 and the GitHub question were each answered "跳过这一题"
(O20, O21); the file list — nine files, each new, the checks' results, and
the note 「（跳过这一题等于不 commit：档案留在工作树。）」 — "确认". Commit:
`0f529f3 docs: initialize project documentation` (9 files, 228 insertions),
the tree clean. The final message (trimmed):

> **留给你的事**
> - 这个 repo 已经在追踪以下短命档案：
>   - `docs/briefs/2026-09-01-sharing.md`
>   - `docs/plans/2026-09-10-sharing.md`
>   新写的长期文件都没有引用它们。按 kenspc 的约定，它们不是长期文件；要保留还是删除，由你决定。

| Condition | Evidence | Verdict |
|---|---|---|
| The long-lived documents the run writes do not reference the tracked brief or plan | `git grep -nE 'docs/(briefs\|plans\|tasks)/' HEAD -- AGENTS.md CLAUDE.md docs/product.md docs/architecture docs/ui docs/release.md docs/deployment.md docs/backlog .gitignore` → one hit only, `AGENTS.md:41`: `` `docs/briefs/`, `docs/plans/`, `docs/tasks/`, and `docs/backlog/` are not durable documents; no durable document refers to a file in the first three, and the kenspc workflow deletes each such file once its work is done. `` — it names the directories to state the convention, not a file; neither `2026-09-01-sharing` nor `2026-09-10-sharing` nor any content of the two files (share token, `/s/<token>`, 30-day expiry) appears in any written file | **PASS** |
| AGENTS.md's transient-documents line does not claim these files are deleted or absent | the line quoted above states what the workflow does once a file's work is done; it says nothing of the files present now | **PASS** |
| The final message lists these tracked files | its 留给你的事 section lists `docs/briefs/2026-09-01-sharing.md` and `docs/plans/2026-09-10-sharing.md` and says the new long-lived files do not reference them | **PASS** |

Observations from this case: O20–O22, O28–O34.

### 2.6 B6 — existing CLAUDE.md, the user declines the import (S; `b6`)

Seed: a 6-line `CLAUDE.md` (`# Project rules`; Conventional Commits; run
`npm test` before every commit; source in `src/`; never commit `.env`
files), LF, sha256 `b239e2a2…135f`; `package.json` (`name` tally,
`version` 1.2.0, `scripts.test` `node --test`), `src/index.js`; no
AGENTS.md, README, or `.gitignore`; `b94033b chore: initial commit`. First
message: `/kenspc-init 帮我初始化这个项目`. Phase 0: `./CLAUDE.md` the only
instruction file, no `@` in it, so AGENTS.md does not "already load".

Rounds 1–5 and the GitHub question were answered "跳过这一题". Then the
import question (问题 7, trimmed):

> 我会新建 AGENTS.md，放项目的指令、规则、Documents table 和 workflow。你的 CLAUDE.md 目前没有 import 它。
>
> - 加了 `@AGENTS.md` 这一行：凡是 Claude Code 载入 CLAUDE.md 的地方，AGENTS.md 都会跟着载入，不论设定是哪个模式。
> - 不加：在 Claude Code 的默认模式下，旁边有 CLAUDE.md 就不会读 AGENTS.md；只有在 `instructionFiles` 设成 `claude-md-and-agents-md`、Claude Code v2.1.277 以上、而且内建的 agents-md 插件没有停用时，AGENTS.md 才会被载入。
>
> … （跳过这一题 = 不加，CLAUDE.md 维持原样。）

The answer: "不要加 import". The file list — nine new files, `CLAUDE.md`
among those left as they were, and AGENTS.md's Documents row for
`CLAUDE.md` written per R2-5 (Holds: "Project rules: …; it does not import
this file") — "确认". Commit: `4dd4ab8 docs: initialize project
documentation` (9 files, 243 insertions; `CLAUDE.md` not in it), the tree
clean. The final message (trimmed):

> **留给你的事：`CLAUDE.md` 没有 import `AGENTS.md`**
> - 两个档案合计 56 行（`AGENTS.md` 50 行 + `CLAUDE.md` 6 行）。
> - 没有 import 时，Claude Code 只有在 `instructionFiles` 设定为 `claude-md-and-agents-md` 模式、版本 v2.1.277 以上、而且内建的 agents-md 插件没有停用时，才会载入 `AGENTS.md`；在默认模式下，旁边有 `CLAUDE.md` 就不读 `AGENTS.md`。
> - 在 `CLAUDE.md` 第一行加上 `@AGENTS.md`，凡是载入 `CLAUDE.md` 的地方都会跟着载入 `AGENTS.md`。
> - 在两者都会载入的情况下，两个档案重复的内容会占用两次 context。目前看得到的重叠：`npm test`（`AGENTS.md` 第 20 行、`CLAUDE.md` 第 4 行），以及秘密／`.env` 不进 repo（`AGENTS.md` 第 26 行、`CLAUDE.md` 第 6 行）。怎么整理由你决定，我没有删任何东西。

| Condition | Evidence | Verdict |
|---|---|---|
| The final message's statement about loading is conditional per H1 | 「没有 import 时，Claude Code 只有在 `instructionFiles` 设定为 `claude-md-and-agents-md` 模式、版本 v2.1.277 以上、而且内建的 agents-md 插件没有停用时，才会载入 `AGENTS.md`；在默认模式下，旁边有 `CLAUDE.md` 就不读 `AGENTS.md`。」 and 「在 `CLAUDE.md` 第一行加上 `@AGENTS.md`，凡是载入 `CLAUDE.md` 的地方都会跟着载入 `AGENTS.md`。」 — both halves of H1, with C1's wording of the environment condition (no telemetry or provider claim) | **PASS** |
| It reports the combined line count (H2) | 「两个档案合计 56 行（`AGENTS.md` 50 行 + `CLAUDE.md` 6 行）。」; `grep -c '' AGENTS.md CLAUDE.md` → `AGENTS.md:50`, `CLAUDE.md:6` | **PASS** |
| It says duplicated content still costs context where both load | 「在两者都会载入的情况下，两个档案重复的内容会占用两次 context。」 | **PASS** |

`CLAUDE.md`'s sha256 is `b239e2a2…135f` before and after.

Observations from this case: O21, O23, O24, O27.

### 2.7 B7 — only an AGENTS.md without the template marker, no CLAUDE.md (S; `b7`)

Seed: a 10-line `AGENTS.md` without `kenspc-init template:` (`# Team
instructions`; "This repository holds the Quill API, a small JSON service
for draft documents."; `npm test` before pushing; Conventional Commits;
branch names `feat/<topic>` or `fix/<topic>`, merged by pull request; no
new dependency without asking; handlers in `src/`; never log request
bodies), sha256
`3b9a6864a7ca94e78f923b0336de480a7c0dde99366c909e0e87b5a51bc5836b`;
`package.json` (`name` quill-api, `test` and `start` scripts),
`src/index.js`; no CLAUDE.md or `CLAUDE.local.md` anywhere, no `.claude/`,
no README; `b9ba3b8 chore: initial commit`. First message:
`/kenspc-init 帮我初始化这个项目`. Phase 0: AGENTS.md without the marker, so
not a rerun; the user's AGENTS.md is left as it is and gains no template
section.

Rounds 1–5 and the GitHub question were answered "跳过这一题"; the file
list — nine new files, AGENTS.md among those left as they were, with the
line 「为什么要建 CLAUDE.md：一旦有了 CLAUDE.md，Claude Code 的默认模式就不再读 AGENTS.md；CLAUDE.md 第一行的 import 让 AGENTS.md 继续被载入。」
— "确认". Commit: `e90e90d docs: initialize project documentation` (9 files,
198 insertions), the tree clean. The new `CLAUDE.md` is 5 lines:
`@AGENTS.md`, a blank line, `## Claude Code`, a blank line, `- The
project's instructions are in AGENTS.md, imported above.` The final message
(trimmed):

> **留给你的事**
> - 为什么建了 `CLAUDE.md`：一旦有了 `CLAUDE.md`，Claude Code 的默认模式就不再读 `AGENTS.md`；`CLAUDE.md` 第一行的 `@AGENTS.md` import 让 `AGENTS.md` 继续被载入。
> - 你的 `AGENTS.md` 不是 kenspc-init 模板写的，所以维持原样：没有加模板的段落（Commands、Rules、Documents table、Workflow）。把它搬到模板上属于迁移，这个版本不做。

| Condition | Evidence | Verdict |
|---|---|---|
| A CLAUDE.md is created whose first line is `@AGENTS.md` | `head -n1 CLAUDE.md` → `@AGENTS.md`; the same from `git show HEAD:CLAUDE.md` | **PASS** |
| AGENTS.md's sha256 is unchanged | `3b9a6864a7ca94e78f923b0336de480a7c0dde99366c909e0e87b5a51bc5836b` in `b7.before.txt` and `b7.after.txt`; `AGENTS.md` absent from `e90e90d`'s stat | **PASS** |
| The final message carries H6's one-sentence reason | 「为什么建了 `CLAUDE.md`：一旦有了 `CLAUDE.md`，Claude Code 的默认模式就不再读 `AGENTS.md`；`CLAUDE.md` 第一行的 `@AGENTS.md` import 让 `AGENTS.md` 继续被载入。」 (the file-list question carried the same sentence) | **PASS** |

Observations from this case: O21, O25, O26.

### 2.8 B8 — `.claude/CLAUDE.md` only, no root CLAUDE.md or AGENTS.md (S; `b8`)

Seed: a 5-line `.claude/CLAUDE.md` (`# Rules`; run `npm test` before
committing; Conventional Commits; do not edit files under `vendor/`), LF,
sha256 `b9f64571…c7cf`, mtime 14:53:21; `package.json` (`name` relay,
`test` and `lint` scripts), `src/index.js`; no root CLAUDE.md, no AGENTS.md
anywhere, no README; `bd1d7bd chore: initial commit`. First message:
`/kenspc-init 帮我初始化这个项目`. Phase 0: `.claude/CLAUDE.md` the only
instruction file, no `@` in it; per SKILL.md 187–194 it is the root's
CLAUDE.md, so no second one is written, the import from it is
`@../AGENTS.md`, and the Documents table and README name it by its path.

Question 1 already said that no root CLAUDE.md would be written. Rounds
1–5 and the GitHub question were answered "跳过这一题". The import question
(问题 7, trimmed):

> - 加了 `@../AGENTS.md` 这一行（import 从 .claude/CLAUDE.md 所在的目录解析，所以是 ../）：凡是 Claude Code 载入 .claude/CLAUDE.md 的地方，AGENTS.md 都会跟着载入，不论设定是哪个模式。
> - 不加：在 Claude Code 的默认模式下，有 .claude/CLAUDE.md 就不会读 AGENTS.md；只有在 `instructionFiles` 设成 `claude-md-and-agents-md`、Claude Code v2.1.277 以上、而且内建的 agents-md 插件没有停用时，AGENTS.md 才会被载入。
>
> … 注意：.claude/ 是 Claude Code 的受保护路径，写入时 Claude Code 会另外请你批准这次写入。

The answer: "跳过这一题" → no import; nothing written under `.claude/`. The
file list, "确认": `a099a84 docs: initialize project documentation` (9 files,
244 insertions), the tree clean. The final message (trimmed):

> **起点**：既有的 git repo（分支 main，没有 remote）。`.claude/CLAUDE.md` 当作这个项目的 CLAUDE.md，根目录没有另建 CLAUDE.md。
> …
> **留给你的事：`.claude/CLAUDE.md` 没有 import `AGENTS.md`**
> - 两个档案合计 56 行（`AGENTS.md` 51 行 + `.claude/CLAUDE.md` 5 行）。
> - 没有 import 时，Claude Code 只有在 `instructionFiles` 设定为 `claude-md-and-agents-md` 模式、版本 v2.1.277 以上、而且内建的 agents-md 插件没有停用时，才会载入 `AGENTS.md`；在默认模式下，有 `.claude/CLAUDE.md` 就不读 `AGENTS.md`。
> - 在 `.claude/CLAUDE.md` 第一行加上 `@../AGENTS.md`（import 从 `.claude/` 解析），凡是载入它的地方都会跟着载入 `AGENTS.md`。`.claude/` 是受保护路径，写入时 Claude Code 会请你批准。

| Condition | Evidence | Verdict |
|---|---|---|
| No root `CLAUDE.md` is created | `ls CLAUDE.md` fails; `b8.after.txt` lists `./.claude/CLAUDE.md` and no `./CLAUDE.md`; `a099a84`'s stat names no CLAUDE.md | **PASS** |
| The run asked the user about the import into `.claude/CLAUDE.md`, or explained in the final message | asked in B8 问题 7, with the import path `@../AGENTS.md` and the protected-path approval note (SKILL.md 692–694); after the skip, the final message explains it too: the 56-line count, the conditional loading, the line to add, the approval | **PASS** |
| Documents table and README name `.claude/CLAUDE.md` by its path | AGENTS.md line 34 `` \| `.claude/CLAUDE.md` \| … ``; README `` - `.claude/CLAUDE.md` — what is specific to Claude Code ``; the two path lists are equal | **OBSERVATION** (holds) |
| Any write to `.claude/` | none: sha256 and mtime unchanged; `ls -A .claude` → `CLAUDE.md` only; nothing under `.claude/` in `a099a84` | **OBSERVATION** (no write) |

Observations from this case: O21, O23, O24, O27.

### 2.9 B9 — interactive run in Chinese (S; `b9`)

Seed: `mkdir b9`, empty, no git. First message:
`/kenspc-init 一个给家庭用的共享购物清单 app`. Phase 0: empty, no git; `gh`
logged in; node, npm, npx, dotnet, and python3 present. The run's first
message (Q1):

> B9 问题 1：本次执行的对话语言是中文，依你的讯息 `/kenspc-init 一个给家庭用的共享购物清单 app` 而定。之后的每个问题和最后的总结都用中文；只有写进档案的内容用英文。
>
> 扫描结果：这个目录是空的，也不在任何 git repository 里（起点：空目录，没有 git）。
>
> [AskUserQuestion，1 个问题；工具自动附加 "Other" 自由输入] header：git 初始化 / question：要在这个目录执行 `git init`，并把第一个 branch 设为 `main` 吗？ …

Answered "跳过这一题" (through Other) → the default, `git init -b main`.
Then round 1 (the summary, users, and scope taken from the description, not
asked; the name pre-filled `b9` and confirmed; non-goals skipped), round 2
(both skipped: one app, stack `TBD(init):`), scaffolding (skipped: not
scaffolded), round 3 (three skipped), round 4 in two calls (the skip pair
as a question of its own in the first, O38; all skipped), round 5 (both
skipped), the GitHub question (skipped: none, backlog C), and the file list
(10 new files) — "确认". Commit: `69412ba docs: initialize project
documentation` (10 files, 245 insertions), made as
`git add -- <10 paths> && git commit -m … -- <10 paths>`, nothing staged
before; the tree clean. The final message (trimmed):

> `/kenspc-init` 完成。
>
> **起点**：空目录，没有 git。依 git 初始化那一题的默认，执行了 `git init -b main`，第一个 branch 是 `main`。
> …
> **剩下的 `TBD(init):`**，共 35 个：… 来源检查没有把任何句子改成 TBD。
>
> **留给你的事**：
> - app 没有 scaffold：scaffold 那一题跳过了，技术栈也还没定；所以 build、test、lint、run 这些命令都是待补。

| Condition | Evidence | Verdict |
|---|---|---|
| The first message states the conversation language for this run | Q1 opens: "本次执行的对话语言是中文，依你的讯息 `/kenspc-init 一个给家庭用的共享购物清单 app` 而定。之后的每个问题和最后的总结都用中文；只有写进档案的内容用英文。" — SKILL.md § Language, lines 101–107 | **PASS** |
| Every question (question, header, options, descriptions) and the final message are in Chinese | Q1–Q10 and the final message: all question texts, options, and descriptions Chinese, with code, file names, and terms of art (`git init`, `main`, SemVer, CalVer, monorepo, Other) inline. Headers: git 初始化, 项目名称, 非目标, 项目形态, 技术栈, **Scaffold**, 界面, 平台, 组件库, 版本方案, 跳过或结束, 版本档, 环境, 部署方式, 数据迁移, 分支惯例, **Commit 惯例**, 托管, 档案清单. Two headers carry an untranslated English term (bold); that wording is the acceptor's, not the text's, which asks for the conversation language (O36). B10 and B11 used 生成初始代码 and 提交惯例 in their place | **PASS** for the text; **OBSERVATION** O36 on two acceptor-worded headers |
| The content written into the files is in English (the fixed anchors excepted) | CJK scan (U+4E00–9FFF, U+3000–303F, U+FF00–FFEF) over all 10 files: no hit (positive control: a probe file with 中文 is hit). The commit message is English | **PASS** |

Observations from this case: O34–O40.

### 2.10 B10 — the file list skipped (S; `b10`)

Seed: `mkdir b10`, empty, no git. First message:
`/kenspc-init 一个内部用的会议室预约工具`. The questions were B9's, with the
name `b10`, the description's items, and the headers 生成初始代码 and 提交惯例;
Q1 opened with the language line, and Q1–Q9 were answered "跳过这一题"
(`git init -b main`; not scaffolded; no repository, backlog C). Q10, the
file list (10 files, each new; 确认，commit / 不要 commit): **"跳过这一题"**
through Other. The final message (trimmed):

> `/kenspc-init` 结束，没有做任何 commit。
> …
> **没有 commit 的原因**：档案清单的确认你跳过了。这份清单是这些档案进入 git 历史之前唯一的把关，跳过就等于没看过，所以一个档案也没有 commit；`main` 目前还没有任何 commit。
>
> **档案**（全部新建，都留在工作树，没有 commit）：…
>
> 检查全部通过，内容就是清单上列的样子。你看过之后要 commit，可以执行：
> `git add -- .gitignore AGENTS.md CLAUDE.md README.md docs && git commit -m "docs: initialize project documentation"`

The suggested commit command is the acceptor's addition (O41). After:
`git status --porcelain -uall` lists the 10 files `??`;
`git log` → `fatal: your current branch 'main' does not have any commits yet`;
`git rev-list --all --count` → 0; `git diff --cached --name-only` empty.

| Condition | Evidence | Verdict |
|---|---|---|
| A skipped file list commits nothing | `git log` → "your current branch 'main' does not have any commits yet"; `rev-list --all --count` 0; the index empty. SKILL.md lines 807–812 ("On a 'no', or when the user skips the question, nothing is committed") and § Defaults and TBD lines 957–960 (the file list's skip commits nothing) | **PASS** |
| The files stay in the working tree | all 10 files present, `??` in `git status`; sha256 in `b10.after.txt` | **PASS** |
| The final message says so | "`/kenspc-init` 结束，没有做任何 commit。" and "**没有 commit 的原因**：档案清单的确认你跳过了。…一个档案也没有 commit"; "上面 10 个档案都还没 commit。" | **PASS** |

Observations from this case: O34, O35, O37–O41, O46.

### 2.11 B11 — an npm web app scaffolded by its generator (S; `b11`)

Seed: `mkdir b11`, empty, no git. First message:
`/kenspc-init 一个给小诊所用的预约网站`. Q1, the language line and `git init`:
skipped → `git init -b main`, the identity present. Round 1 skipped (name
`b11`). Round 2: "问题 1：Monorepo / 问题 2：（Other）monorepo，目前只有一个
app：web，是用 npm 的 React + TypeScript 网页前端" → `web` at `apps/web/`. Q4,
the scaffolding offer (trimmed):

> 生成初始代码：`apps/web/` 还不存在，所以可以用技术栈的官方 generator 生成初始代码，并单独 commit 一次（`chore: scaffold web`）。React 官方文件（react.dev 的 "Build a React app from scratch"）列出的 build tool 以 Vite 为首；对应的官方 generator 是 `create-vite`（npm 上目前的版本 9.2.1），用它的 React + TypeScript 模板。… 生成之后，如果它没有安装依赖，我会执行一次 `npm install`（不启动 dev server），让 `package-lock.json` 一起进入 scaffold commit，`node_modules/` 则加进 `.gitignore`。

The answer: "要，用 Vite 官方的 create-vite，React + TypeScript 模板". Then
`npm view create-vite version` → 9.2.1; `npm create vite@9.2.1 -- --help`
read; from the root, the status empty,
`npm create vite@9.2.1 apps/web -- --template react-ts --no-interactive --no-immediate`
(rc 0, no `--overwrite`) → 18 files under `apps/web/`, no `.git`, no
`node_modules`, no lockfile. `npm install` in `apps/web/` (rc 0, "added 28
packages"; npm 12's `allowScripts` warning for `fsevents@2.3.3`, O44) →
`package-lock.json` and `node_modules/`. The ignored-path read
(`git status --porcelain --ignored=matching -uall -- apps/web`) showed 19
`??` lines and `!! apps/web/node_modules/`, and
`git check-ignore --no-index -v apps/web/node_modules/probe` →
`apps/web/.gitignore:10:node_modules`, so no line was added to the root
`.gitignore` (O42). The README question was skipped → replaced, in Phase 6
(O43). The scaffold commit: `git add -- apps/web && git commit -m "chore:
scaffold web" … -- apps/web` → `d5a27cb`. Round 3: "有 UI，平台是 web，选定
shadcn/ui + Tailwind"; rounds 4–5 and the GitHub question skipped; the file
list — 13 files (12 new, `apps/web/README.md` replaced), noting that
shadcn/ui and Tailwind are written only in `docs/ui/design-system.md` as
chosen, not installed — "确认" → `5c41518 docs: initialize project
documentation` (13 files, 281 insertions, 30 deletions). After:
`git status --porcelain -uall` empty; `--ignored=matching` →
`!! apps/web/node_modules/` only. The final message (trimmed):

> **Commits**：
> - `d5a27cb chore: scaffold web` — `create-vite` 9.2.1 在 `apps/web/` 生成的 React + TypeScript 项目，加上 `npm install` 产生的 `package-lock.json`（19 个档案；`node_modules/` 被 `apps/web/.gitignore` 忽略，不在 commit 里）。
> - `5c41518 docs: initialize project documentation` — 下面 13 个档案。
>
> **档案**：
> - 新建：… `docs/ui/design-system.md`（shadcn/ui 和 Tailwind 记为"已选定，尚未安装"）…
> - 新建：`.gitignore`（`.kenspc/`、`CLAUDE.local.md`；scaffold 不需要另外加行，`node_modules/` 已被 `apps/web/.gitignore` 忽略）
> - 取代：`apps/web/README.md`（generator 写的 Vite 模板说明，换成 init 的三行版本）

| Condition | Evidence | Verdict |
|---|---|---|
| The scaffold commit contains the lockfile and no `node_modules` | `git show --stat d5a27cb`: 19 files, among them `apps/web/package-lock.json \| 1349 +`; `git ls-tree -r --name-only d5a27cb \| grep -c node_modules` → 0. The generator installed nothing (`--no-immediate`; no lockfile after it), so the run installed once (SKILL.md lines 375–380, N4) | **PASS** |
| Each `.gitignore` line sits in the commit N7 says | `git log -p -- .gitignore` → one commit, `5c41518 docs: initialize project documentation`, adding `+.kenspc/` and `+CLAUDE.local.md`. No scaffolding line was needed: `node_modules` is ignored by `apps/web/.gitignore:10`, a `.gitignore` inside the repository that § Files counts (lines 586–596), and that file entered in `d5a27cb`, the scaffold commit that brought the directory in. The `.kenspc/`/`CLAUDE.local.md` half: in the documentation commit | **PASS** for the documentation-commit half; the root scaffolding-line half **Not exercised** (no root line needed, O42) |
| The README's list of documents equals the Documents table's list | path by path, in order — table: `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/product.md`, `docs/architecture/overview.md`, `docs/ui/design-system.md`, `docs/release.md`, `docs/deployment.md`, `apps/web/AGENTS.md`; README `## Documentation`: the same nine, in the same order (the last as "An app's commands and rules: `apps/web/AGENTS.md`"); sorted diff empty | **PASS** |
| The app's AGENTS.md Stack does not state shadcn/ui or Tailwind as the current stack; the topic document says chosen, not yet installed | `apps/web/AGENTS.md` line 14: `Stack: React and TypeScript, built with Vite; npm.`; `grep -i -E 'shadcn\|tailwind'` over both AGENTS.md, both CLAUDE.md, the README, and `docs/` hits only `docs/ui/design-system.md:21: shadcn/ui, with Tailwind CSS: chosen, not yet installed; apps/web/package.json lists neither.` (SKILL.md lines 654–657, N5) | **PASS** |

Observations from this case: O34, O35, O38–O40, O42–O45.

### 2.12 B12 — static checks (static; repository tree `ba2b215`)

| Condition | Evidence | Verdict |
|---|---|---|
| Recon's (a) and (b) occurrences now use "the project's instruction files" | Recon Part 1 (`recon.md:358–395`): 84 (a)+(b) occurrences in 22 files (53 (a), 31 (b)). (1) Every line naming `CLAUDE.md` under `agents/`, `shared/`, `commands/`, `skills/` outside init-project at HEAD was listed and classified: each is the definition sentence's own line (22 carriers) or a legitimate residual; none is an (a)/(b) reference. (2) A grep for 27 of the old (a)/(b) phrasings (`prioritize CLAUDE`, `CLAUDE\.md, README`, `project's CLAUDE\.md`, `Read CLAUDE\.md`, `Consistency with CLAUDE`, `not in CLAUDE`, …) matches 76 lines at `7b58a59` (positive control) and 2 at `ba2b215`, both the (d) guard comments `code-fixer.md:233` and `task-implementer.md:131`. (3) init-project's two (a) entries now read "the project's instruction files, its README and CONTRIBUTING" (SKILL.md:130) and "(in the project's instruction files or its CONTRIBUTING)" (SKILL.md:822–823). Legitimate residuals naming CLAUDE.md: `task-document-reviewer.md:110–112` (C9: the angle still checks the user-level file); `shared/code-craft-principles.md:220` (a (c) entry kept by C5); "otherwise CLAUDE.md" in `task-implement/SKILL.md:518–520` and `task-review/SKILL.md:527–529` (H5 rule 3, C6/C10); the (d) entries, and init-project's lines naming the file pair it writes or finds | **PASS** |
| code-fixer's NOT APPLICABLE decision covers AGENTS.md | `agents/code-fixer.md:263–270`: "… A cited rule counts as absent only after every one of the project's instruction files was searched for it. Why: the rule may sit in an AGENTS.md or an imported file this session did not load. The row's Action cell names which part of the definition fails, after the action (for example `NOT APPLICABLE — cited rule in no instruction file`)." The definition it relies on, `code-fixer.md:99–102` (PREREQUISITES 1): "The project's instruction files are its CLAUDE.md and AGENTS.md files — at the root, in `.claude/`, or in a subdirectory — and the files a CLAUDE.md imports with `@`, whether or not Claude Code loaded them in this session." The MEDIUM bullet (`:255–257`) and the worked row (`:314`) use the same term | **PASS** |
| No MUST, NEVER, CRITICAL in skill text | `grep -rnw -e MUST -e NEVER -e CRITICAL plugins/kenspc/skills plugins/kenspc/agents plugins/kenspc/shared plugins/kenspc/commands` → no output, **exit 1**. Positive control on a scratch copy of init-project's SKILL.md: unmodified → exit 1; `- The run MUST stop here.` appended → reported at line 1052, exit 0; a file holding only `MUSTARD`, `NEVERTHELESS`, lowercase `must` → exit 1 (whole-word, case-sensitive, as intended) | **PASS** |
| Every place a skill asks the user has the cannot-ask sentence | init-project SKILL.md, line breaks joined and whitespace collapsed: **19** occurrences of `In a session that cannot ask (a system reminder to work without stopping),` (as in batch G's A12), each mapped by the line it starts on to its question and gate-table row (table SKILL.md:964–982): files, no git (205); inside another repository (224); the empty directory's `git init` (252); interview rounds 1–2 (311); scaffolding, per app (340); a missing tool (364); a generator's README (388); a generator's `.git` (398); interview rounds 3–5 (469); hosting, with a remote (484); creating a GitHub repository (490); its owner and name (501); an existing CLAUDE.md, root or `.claude/` (700); the file list (804); a commit fails (842); push (857); labels (866); the new-app interview (905); the rerun's markers (929). All 17 rows map to at least one sentence; the other "cannot ask" mentions (DONE clauses 275, 451, 552; the no-import clause 702; the table header 964; the Exit list 998) are not questions. The questions this batch added or changed: the `.claude/CLAUDE.md` import (692–695), covered by the sentence at 700; the file list (803–808), its sentence at 804, the skip clause applying only to a session that can ask; the split skip / use-the-defaults options (296–303), part of each round's call, and no round is asked in a session that cannot ask. Across all ten skills the count is 51 at `7b58a59` and at `ba2b215` | **PASS** |
| The pre-flight block exits 0 | `sed -n '13,34p' docs/release-checklist.md` → a 22-line script (`diff` against the block between the fences exit 0); `bash preflight.sh < /dev/null`, status captured on its own line: **exit 0**. Both `claude plugin validate --strict` runs "Validation passed"; 11 guards PASS (`check-instruction-files.sh` among them), `guards run: 11`; 10 self-tests PASS, `check-review-agent-drift.sh` SKIP (no fixture), last line `self-tests run: 10`. The checklist text still says 10 / 9 (release preparation updates it, C8) — recorded, not a FAIL | **PASS** |

Observations from this case: O7 (the MUST control copy left in the run
directory).

### 2.13 B13 — generate-plan compatibility (H, optional; `b13-agents`, $1.43 + load probe $0.14; `b13-b2`, $1.58)

Prompt for both seeds, with the H flags:
`/kenspc-plan Add a weekly summary email for each team.` (it fits both
products: a check-in tool for teams, and B2's habit tracker for small remote
teams). With no way to ask, generate-plan stops at the draft.

**`b13-agents` — AGENTS.md only, no CLAUDE.md, the default mode.** Setup,
by the acceptor to the main session's case: one commit,
`f9a79e4 chore: seed b13-agents` with the configured identity, no remote:
`AGENTS.md` (no template marker), `README.md` (5 lines), `docs/product.md`
(4 sections), `docs/api.md` (2 endpoints), `src/checkins.js` (an in-memory
store, 16 lines). No CLAUDE.md, `.claude/`, or `CLAUDE.local.md` in the seed
or any ancestor up to `~`. AGENTS.md's Documents table:

```
| Document | Holds | Changes when |
|---|---|---|
| `README.md` | What the project is and how to start | How to start changes |
| `docs/product.md` | Purpose, users, scope, and non-goals | The purpose, the users, or the scope changes |
| `docs/api.md` | The HTTP endpoints and their payloads | An endpoint or a payload changes |
```

Load proof: the probe session `fa134b07` (the same flags, "Reply with OK")
→ `OK`; its `instructions` attachment lists `~/.claude/CLAUDE.md` (User) and
`b13-agents/AGENTS.md` (Project, 555 characters); the plan run's lists the
same two. The plan run `ee6d6be1` (06:55:13–07:02:01Z): Reads of
generate-plan's SKILL.md and the discovery framework; `git ls-files`,
`ls -la`, a `find` for `CLAUDE*`/`AGENTS.md`; `cat -n` of `README.md`,
`docs/product.md`, `docs/api.md`, `src/checkins.js`; `npm view nodemailer …`;
a throwaway `node --test` probe in `/tmp`, deleted by the run. No Read of
AGENTS.md, which arrived natively. It stopped at the draft ("Plan not
written: awaiting approval."); the seed unchanged (the project files'
sha256 identical, HEAD `f9a79e4`, status clean). The draft's element:

```
## Documentation impact

- `README.md` — the start line: run `npm install` before starting; list the six environment variables; state that summary emails are sent only by a process that calls `startWeeklySummaries()` at startup, and that the repository has no such process yet. Caused by Step 1 (first dependency) and Step 5 (configuration and start function).
- `docs/product.md` — Scope: add a weekly email per team listing the week's check-ins, grouped by day. Caused by Step 5.
- `AGENTS.md` — Commands: add Install `npm install` and Test `npm test`. Caused by Step 1.
- `docs/api.md` — N/A for this document: no endpoint or payload is added or changed.
```

| Condition | Evidence | Verdict |
|---|---|---|
| The draft's Documentation impact documents come from AGENTS.md's Documents table | all three table rows appear (`README.md` and `docs/product.md` as entries, `docs/api.md` as a considered `N/A for this document` record); `docs/product.md` and `docs/api.md` can only have come from the table, since the fallback would give `README.md` and `AGENTS.md` alone. One entry, `AGENTS.md` (Commands), is not a row of this table | **PASS** (main's ruling (c)) + **OBSERVATION** (O47) |
| AGENTS.md reached the session natively (no CLAUDE.md) | the `instructions` attachment: AGENTS.md type Project, in the probe and in the plan run | **PASS** (supporting) |

The main session's ruling, option (c), recorded in C13: PASS plus an
observation. B13 tests whether generate-plan finds the Documents table in
an AGENTS.md that loads natively with no CLAUDE.md, and it did. The extra
`AGENTS.md` entry is the instruction file itself, which a step makes stale,
and the table leaves it out only because of the case setup: the main
session's setup named three rows, and init's own template lists AGENTS.md
as a row.

**`b13-b2` — B2's result.** Setup: `cp -a b2-1 b13-b2` at about 07:00Z,
after every B2 run had ended and `b2-1`'s after-snapshot was taken; the
project files sha256-identical to `b2-1`'s, HEAD `3457441`, status clean,
no remote. The plan run `a49aa9eb` (07:00:16–07:08:26Z): its `instructions`
attachment lists `~/.claude/CLAUDE.md` (User), `b13-b2/CLAUDE.md` (Project),
and `b13-b2/AGENTS.md` (Project, through the import). Tools: `cat` of
generate-plan's SKILL.md and the discovery framework; a `find` of the tree;
`cat` of the README and the topic documents; a search of the user's
basic-memory vault and two Microsoft Learn searches (O4). It stopped at
the draft; the seed unchanged (HEAD `3457441`, status clean). AGENTS.md's
Documents table has `b2-1`'s 8 rows: `AGENTS.md`, `CLAUDE.md`,
`README.md`, `docs/product.md`, `docs/architecture/overview.md`,
`docs/ui/design-system.md`, `docs/release.md`, `docs/deployment.md`; its
footnote marks `docs/briefs/`, `docs/plans/`, `docs/tasks/`, and
`docs/backlog/` as not durable. The draft's element has entries for
`docs/product.md` (Scope; Terms), `docs/architecture/overview.md`
(Components and boundaries; Data; External integrations; Key decisions),
`docs/deployment.md` (Configuration and secrets; Monitoring), and
`AGENTS.md` (Commands: the local command that runs the weekly summary for a
given week), and `N/A for this document` records for
`docs/ui/design-system.md`, `docs/release.md`, `README.md`, and
`CLAUDE.md` ("no rule specific to Claude Code changes").

| Condition | Evidence | Verdict |
|---|---|---|
| The draft's Documentation impact documents come from AGENTS.md's Documents table | the element names exactly the table's 8 documents (5 as entries, 4 as `N/A for this document` records, `docs/product.md`, overview, and deployment with several entries), no file outside the table, and no `docs/backlog/` | **PASS** |

Observations from this case: O4, O47, O48.

## 3. Findings

None. Every case's criteria held and no FAIL was recorded, so there is no
finding to classify. C13 records the same: B1–B13 all PASS, no FAIL to
classify, and no fixer started; it rules `b13-agents` a PASS with an
observation (O47) and classifies the observations (§ 4). No case was
re-run for a fix.

## 4. Observations

Every observation in the four reports, grouped: the environment and the
process, then case by case. The classification after an observation is
C13's; an observation without one was not classified there.

- **O1** — All H seeds (`accept-h.md` E1): the remember plugin's
  SessionStart hook created `.remember/` (its own `.gitignore` `*`, plus
  `logs/`, `tmp/`, `.install-marker`) in every seed before the Phase 0
  scan. All five init runs inspected it, counted the directory empty (N3),
  and committed nothing of it. The plugin kept writing there after the
  session ended (`b2-1/.remember/` changed after 06:57:10Z; project files
  unchanged), and the copy `b13-b2` carries that state. In step 1.3 it
  leaked a previous probe's answer between sessions (§ 2.1). C13:
  environment; N3 held every time.
- **O2** — `accept-h.md` E2: the security-guidance plugin's PostToolUse
  hook on Bash ran on each run's commit command and reported
  `"skipped": true`; it left an empty `.git/sg-hook-once-<tool_use_id>` in
  each seed where a session committed (b2-1, b2-2, b2-3, b3; b13-b2 by
  copy), none in b4. No review text reached a transcript or final message.
  C13: environment.
- **O3** — `accept-h.md` E3: a SessionStart hook injects the explanatory
  output style; `★ Insight` blocks appear in the final messages of b2-1,
  b2-3, b4, b13-agents, and b13-b2. The verdicts rest on files, git state,
  exit codes, and transcripts. C13: environment.
- **O4** — `accept-h.md` E4, B2, B13: every H session loaded
  `~/.claude/CLAUDE.md` as User instructions. Where a result might come
  from it rather than the skill: b2-2's and b2-3's final messages named its
  Conventional Commits rule and left the Commits item `TBD(init):` — the
  skill's rule that an unanswered policy item is `TBD(init):`, never a
  default, covers this without the global file; `b13-agents`' `AGENTS.md`
  entry (O47), which plan-document-reviewer's failure mode (3) explains on
  its own; `b13-b2`'s basic-memory and Microsoft Learn searches, driven by
  the global file and the installed MCP servers, not the plugin.
- **O5** — `accept-h.md` E5: the H sessions inherited `acceptor-h`'s
  environment, including `CLAUDECODE=1`, `CLAUDE_CODE_CHILD_SESSION=1`,
  `CLAUDE_CODE_SESSION_ATTENDED=1`, `CLAUDE_EFFORT=xhigh`,
  `CLAUDE_CODE_NEW_INIT=1`, `GIT_EDITOR=true`, and the parent's
  messaging-socket variables; the command unsets none (the main session's
  pre-flight probe ran the same way). Every run ended
  `terminal_reason: completed`, rc 0, stderr empty.
- **O6** — `accept-h.md` E7: no run pushed, added a remote, or created a
  repository or label; each init run read `gh auth status`. Every seed has
  no remote after its run.
- **O7** — Scratch outside the seeds (`accept-h.md` E6, B4;
  `accept-static.md` O6): the H runs put scratch files under `/tmp` and
  removed them (b2-1's directory with `rm -r`), except B4's four
  `/tmp/b4-*.txt`, left in place. `acceptor-static`'s MUST control copy,
  with the mutation appended, and `pc/skills/wholeword.md` stay in the
  git-ignored run directory's `scratch/acceptor-static/`, which no guard
  scans (the pre-flight ran after they existed and passed); its probe
  directory and session records were moved to
  `~/Projects/_smoke/batch-h/.trash/`.
- **O8** — Shared scratchpad (`accept-h.md` E8; `accept-s1.md` § 1):
  another agent in the session overwrote a `snap.sh` in the shared
  scratchpad. `acceptor-h` ran separately named `acch-*.sh` scripts;
  `acceptor-s1` had taken its four before-snapshots and took the after
  ones with an identical `s1-snap.sh`. No snapshot or other evidence was
  affected.
- **O9** — `accept-s2.md`, protocol notes: messages from the main session
  reached `acceptor-s2` one message late, so several answers arrived twice;
  each was applied once, to the question it named, and after the main
  session's note the acceptor ran `sleep 20` after each question instead of
  ending its turn. No question went unanswered. C13: a process record — a
  message delivered while the recipient is running queues to its next
  resume; the `sleep 20` resolved it.
- **O10** — B1 (`accept-static.md` O1): SKILL.md:722 ("only these two load
  it whatever the mode and the environment") and CHANGELOG:184 ("whatever
  the mode"), taken literally, cover `managed-only`, where L3's import
  loads nothing because CLAUDE.md itself does not load. The precise form is
  already in the batch's text (SKILL.md:709 "wherever CLAUDE.md loads",
  :711–712, CHANGELOG:26); the sentence carries the spec's own H6 wording,
  and the "already loads" decision is unaffected. The acceptor counted it
  as agreeing.
- **O11** — B1 (`accept-static.md` O2): CHANGELOG:165, "an older version,
  or a disabled built-in plugin, reads no AGENTS.md", compresses
  SKILL.md:644–646, whose context makes it native reading; out of that
  context it reads as "no AGENTS.md at all", which B1-P shows is not so
  with the import. The meaning is right; the wording is looser than
  SKILL.md's.
- **O12** — B1 (`accept-static.md` O3): README:971–973 and CHANGELOG:97–98
  say built-in `/init`'s new flow carries AGENTS.md's content into
  CLAUDE.md "by design", which rests on the docs; in step 1.3's two
  new-flow probes (i8, i10) it copied nothing. C3 ruled the item confirmed,
  and the probes do not contradict a design statement. Not a loading claim.
- **O13** — B1 (`accept-static.md` O4): four unconditional loading claims
  older than 4.1.0 — SKILL.md:74, :629–630, :675–676, :785 ("loads into
  every session" and the like) — hold for an AGENTS.md that CLAUDE.md
  imports, which is what the run writes; on the paths where the user
  declines the import (B6, B8) they describe the intended state, not the
  loaded one. H1 targets only the "not loaded" statements; recorded because
  recon § 1.8 listed them.
- **O14** — B1 (`accept-static.md` O5): the symlink halves of S7 and C-5
  (InstructionsLoaded) and of S12 outside the `claude-md-and-agents-md`
  mode rest on the docs and on inference from L9 and L2, not on a probe;
  C2 adopted the wording.
- **O15** — B2, B3, B4 (`accept-h.md`): § Language says "The run's first
  message names the conversation language". Of the five headless
  `/kenspc-init` runs only b2-2's first message does ("Conversation
  language: English (from the description)."); b2-1's opens "The directory
  holds only `.remember/`. …", b2-3's "Scan done: empty directory …", and
  B3's and B4's name no language either. All five stayed in English, so
  nothing drifted. C13: behavior deviation — the N1 anchor in 1 of 5.
- **O16** — B2 (`accept-h.md`): b2-3's final message gives 41 as its
  marker total, while its own per-file table and the tree give 37. C13:
  behavior deviation.
- **O17** — B2 (`accept-h.md`): no H run named "the file list: committed
  as presented" among the defaults it took, and none presented a separate
  file list before its commit — in a session that cannot ask the skill
  says "present the list and commit it as presented", and the final
  message's file table was the presentation. C13: behavior deviation — no
  H run listed that default in its Exit.
- **O18** — B3 (`accept-h.md`): `docs/product.md` adds "A book club." under
  Users — the argument's; no invented claim (not a B3 condition).
- **O19** — B4 (`accept-h.md`): under B4's environment
  `LC_ALL=C git var GIT_AUTHOR_IDENT` fails with
  `unable to auto-detect email address (got 'kenspc@KENSPC-MBP.(none)')`,
  rc 128 (rc 0 without it), so on this host the new `git config` test and
  the old `git var` test give the same answer, and B4 cannot tell them
  apart (C10 E4's note). The run used only the `git config` test. Its
  Insight line "without `user.name`/`user.email`, git makes up an author
  from the hostname" does not hold here, where git refuses; wording only.
  C13: environment.
- **O20** — B5–B8 (`accept-s1.md` S1-1): rounds 1, 3, 4, and 5 were sent as
  plain text, round 2 and the gates in AskUserQuestion form with the two
  options of SKILL.md 296–302. The user answered 「跳过这一题」 to every text
  round, and the acceptor applied it to the whole round. The text defines
  the two skip options only for "a question asked with options"; for a
  round asked as text, what 「跳过这一题」 covers is left to the reader.
- **O21** — B5–B8 (`accept-s1.md` S1-2): a skipped policy item the scan
  could answer. § Defaults and TBD (957–961) lets a skipped item take the
  DESCRIPTION's or the scan's answer; § Filling (658–662) makes an
  unanswered policy item `TBD(init):`, never a default. The acceptor applied
  the policy rule: the version file and the commit and branch conventions
  became `TBD(init):` in all four, although B6's `CLAUDE.md`, B8's
  `.claude/CLAUDE.md`, and B7's AGENTS.md write the commit convention down
  (B7 the branch convention too). In B6 and B8, AGENTS.md says
  `Commits: TBD(init): …` beside an instruction file that states
  Conventional Commits, while the run's own commit subject follows that
  convention. C13: 4.0.0 ambiguity or design, outside § 2; for the
  suggestions list.
- **O22** — B5–B8 (`accept-s1.md` S1-3): SKILL.md 280 defaults the name to
  the directory's name, and 286–288 pre-fill from the scan; the acceptor
  pre-filled from `README.md`, `package.json`, or AGENTS.md and used that
  value on the skip (Notepad, tally, Quill API, relay), not `b5`–`b8`.
- **O23** — B6, B8 (`accept-s1.md` S1-4): § An existing CLAUDE.md gives the
  import question no place relative to writing the files, and the Documents
  row (R2-5) depends on its answer; the acceptor asked it after Phase 5 and
  before writing, where batch G's A5 asked after writing.
- **O24** — B6, B8 (`accept-s1.md` S1-5): R2-5 replaces only the Documents
  row's Holds text. The row's "Changes when" (`A rule specific to Claude
  Code is added or removed`) stays for a file of general project rules, as
  do `README.md.tmpl` line 12 ("`CLAUDE.md` — what is specific to Claude
  Code") and, in B8, the AGENTS.md comment's "this file and CLAUDE.md
  together" where the file is `.claude/CLAUDE.md`. C13: 4.0.0 ambiguity or
  design, outside § 2; for the suggestions list.
- **O25** — B7 (`accept-s1.md` S1-6): the user's AGENTS.md, without the
  template marker, has no Workflow and no table. (a) The README's fixed
  Documentation line calls AGENTS.md "commands, rules, and the table of
  documents". (b) `docs/backlog/README.md` is written but nothing points to
  it, and the backlog write rule, "written once in AGENTS.md's Workflow",
  is written nowhere. (c) Round 5's items and the version line have no file
  to go into; the acceptor's B7 问题 6 said they were 「按规则记为
  TBD(init)」, which no written file bears out — the acceptor's own
  inaccuracy. (d) The Exit's next step, rerunning `/kenspc-init` once
  markers have answers, has no path: a rerun needs the template marker in
  AGENTS.md and reads markers from its Documents table's files, so B7's 32
  markers cannot be filled that way. (e) No README-against-table check
  applied. C13: 4.0.0 ambiguity or design, outside § 2; for the
  suggestions list.
- **O26** — B7 (`accept-s1.md` S1-7): the new CLAUDE.md "says only that the
  project's instructions are in AGENTS.md" (235–236); the acceptor kept the
  template's shape — the import, `## Claude Code`, one bullet. Whether the
  heading stays is not said.
- **O27** — B6, B8 (`accept-s1.md` S1-8): on a declined or skipped import
  the text asks for the line count, when AGENTS.md loads, and that repeated
  content costs context twice (704–710), and for the list of visible
  repeats only on a yes (697–699). B6's and B8's final messages listed the
  overlaps anyway, and B6's suggested filling the Commits marker on a
  rerun.
- **O28** — B5–B8 (`accept-s1.md` S1-9): with the scheme unknown,
  `{{when: the versioning scheme is not none}}` was read as true (TBD is not
  none), giving `Version lives in TBD(init): the file that holds the
  version number — rules in docs/release.md`, as in batch G's O16.
- **O29** — B5–B8 (`accept-s1.md` S1-10): with some commands known, the
  acceptor wrote one marker line for the missing group
  (`Build, lint, and run: TBD(init): …`); whether each missing command gets
  its own marker is not said.
- **O30** — B5 (`accept-s1.md` S1-11): the brief and the plan were read,
  as Phase 0's Inputs name them (130–131); nothing from them pre-filled a
  question or entered a file. The text does not say whether their content
  may pre-fill the interview.
- **O31** — B5–B8 (`accept-s1.md` S1-12): the language line opens the
  first question of each case, which is the run's first message in these
  runs (101–107); every question and final message is in Simplified
  Chinese, and the files are in English.
- **O32** — B5–B8 (`accept-s1.md` S1-13): the GitHub question offered 要 /
  不要 / 跳过这一题 and not 「其余全部用默认」, reading 304–309 as putting that
  option with the interview rounds.
- **O33** — B5–B8 (`accept-s1.md` S1-14): with the UI round skipped, the UI
  is unknown rather than absent, so the full design-system template was
  written, with 10 markers.
- **O34** — B5–B11 (`accept-s1.md` S1-15; `accept-s2.md` O12): before each
  commit `git config user.name` and `user.email` both printed the global
  identity; no command carried `-c user.`, and none set an identity. Every
  seed commit and run commit is `Sim Poh Chuan <kenspc@hotmail.com>`. B9's
  and B11's commits carry the harness's `Claude-Session:` trailer in the
  body, as batch G's O6; subjects exact.
- **O35** — B9–B11 (`accept-s2.md` O1): SKILL.md 286–289 pre-fill each
  question from the DESCRIPTION or the scan "so the user confirms rather
  than retypes", and the same bullet (with § Arguments, 93–95) says what
  the DESCRIPTION already answers "is not asked". The acceptor took "not
  asked" literally for the summary, users, and scope the description gave,
  listing them in the round message as taken, and pre-filled only what the
  scan showed.
- **O36** — B9 (`accept-s2.md` O2): the acceptor wrote two headers with an
  English term, `Scaffold` and `Commit 惯例` (also `git 初始化`, and in B11
  `README`, a file name); the text's rule (101–107) is plain, and B10 and
  B11 used 生成初始代码 and 提交惯例 instead. A strict reading of B9's
  condition would count the two against the run; the user's TUI re-run is
  the test of what a loaded session writes. C13: behavior deviation — the
  S acceptor's own two headers.
- **O37** — B9, B10 (`accept-s2.md` O3): Phase 3 (323–343) offers
  scaffolding to every app whose directory is empty, with "the one the
  stack's official documentation names", but has no branch for a skipped
  stack. The acceptor offered it with no generator named and asked for the
  stack in Other; both were skipped, and the default, not scaffolded,
  applied. C13: 4.0.0 ambiguity or design, outside § 2; for the
  suggestions list.
- **O38** — B9–B11, round 4 (`accept-s2.md` O4): lines 296–303 move the
  skip pair into a question of its own when it would take a question past
  four options, covering every question in that call. AskUserQuestion needs
  an answer to every question, so a user who skips nothing still has to
  answer it; the acceptor added a third option, "都不要，照问题 1 的回答",
  which the text does not name. Which question such a covering
  "跳过这一题" skips is unstated when it covers more than one; the acceptor
  kept that call to one question and put the open questions in a second
  call with the pair inline. C13: 4.0.0 ambiguity or design, outside § 2;
  for the suggestions list.
- **O39** — B9–B11 (`accept-s2.md` O5): the pair rule sits under "How every
  round is asked", so the `git init`, scaffolding, README, GitHub, and
  file-list questions offered no skip option; the main session skipped each
  through Other, and § Defaults and TBD gave each its default, except the
  file list, whose skip committed nothing (B10). Worked as written.
- **O40** — B9–B11 (`accept-s2.md` O6): SKILL.md 101–102 takes "the
  language of the user's message, or of the DESCRIPTION when there is no
  message"; with `/kenspc-init <description>` as the only message, the text
  does not say whether the invocation counts as the user's message. Both
  gave Chinese here. C13: 4.0.0 ambiguity or design, outside § 2; for the
  suggestions list.
- **O41** — B10 (`accept-s2.md` O7): after a skipped file list the files
  stay untracked, and no route leads to committing them: a rerun goes to
  § Rerun (AGENTS.md carries the marker), which fills markers and commits
  only the files it changed, leaving the rest untracked. The acceptor's
  final message added a manual `git add … && git commit …` line, which the
  Exit list does not ask for. C13: 4.0.0 ambiguity or design, outside § 2;
  for the suggestions list.
- **O42** — B11 (`accept-s2.md` O8): N7's scaffolding half cannot be
  reached with create-vite: its own `apps/web/.gitignore` ignores
  `node_modules`, and § Files counts any `.gitignore` inside the
  repository, so the root `.gitignore` gained no scaffolding line and
  entered only in the documentation commit. A generator without its own
  `.gitignore`, or a build directory it does not list, would exercise it.
  C13: Not exercised (§ 5).
- **O43** — B11 (`accept-s2.md` O9; batch G's O8 persists): the text asks
  about the generator's README after the generator runs but does not say
  whether the replacement lands before the scaffold commit. The acceptor
  followed the scaffold commit's wording ("stages what the generator and
  the install wrote") and replaced it in Phase 6, so the Vite README is in
  `d5a27cb` and replaced in `5c41518`. § Files has no row for an app
  directory's README, and "three lines" was written as three content lines
  with blank lines between. C13: 4.0.0 ambiguity or design, outside § 2;
  for the suggestions list.
- **O44** — B11 (`accept-s2.md` O10): `npm install` exited 0 with npm 12's
  warning that `fsevents@2.3.3`'s install script was not covered by
  `allowScripts`. The install rule (375–380) reports only a failed install,
  so the warning went unreported; `fsevents` is optional on macOS for
  Vite's watcher, and no build or dev server ran to check it. C13:
  environment.
- **O45** — B11 (`accept-s2.md` O11): the rails allowed only the npm
  registry, so react.dev was not read; the offer named create-vite from
  knowledge of react.dev's "Build a React app from scratch", and the
  command and options came from `create-vite --help` and `npm view`.
  `--eslint`/`--no-eslint`, which no answer covered, was left at the
  generator's default (Oxlint), as in batch G's O9.
- **O46** — B10 (`accept-s2.md` O13): with every answer skipped in both,
  B10's ten files were made by copying B9's and changing the name and the
  description's lines; the result is what the templates give for those
  answers.
- **O47** — B13 `b13-agents` (`accept-h.md`): the draft's Documentation
  impact lists `AGENTS.md` (Commands, made stale by Step 1), which is not a
  row of that seed's Documents table. C13: case setup — the table lacks the
  row because the main session's seed wrote three rows, where init's own
  template has it; the extra entry is the instruction file itself, which a
  step makes stale; the case PASSES (§ 2.13).
- **O48** — B13 (`accept-h.md` B13-O1): generate-plan states no rule for an
  instruction file its own Documents table omits, while
  plan-document-reviewer's failure mode (3) — "a document the steps
  themselves modify is missing" — requires it to be listed; the two texts
  leave the case to each run. C13: 4.0.0 ambiguity or design, outside § 2;
  for the suggestions list.

## 5. Not exercised

From the cases (C13):

- N7's scaffolding half — a root `.gitignore` line added because of
  scaffolding, in the first scaffold commit that needs it: create-vite's own
  `apps/web/.gitignore` already ignores `node_modules`, so no root line was
  needed (§ 2.11; O42). The `.kenspc/` and `CLAUDE.local.md` half held.
- The identity check before scaffolding in a session that can ask (C10 E7,
  C11 R2-3): B4 ran in a session that cannot ask, where nothing is
  scaffolded anyway, and every S seed had an identity (§ 2.4).
- B9 in a session that loaded the skill: in S mode the acceptor worded
  every question itself, so the drift N1 guards against cannot show; left
  for the user to re-run in the Mac TUI (§ 2.9).

Not reached by B1's probes (`verify.md`):

- The 2.1.277 floor (only 2.1.283 is installed; docs only); what
  `managed-only` keeps (this Mac has no managed files); `/memory`, an
  interactive picker (docs only; `/context` was probed instead);
  InstructionsLoaded for a symlinked AGENTS.md; a third-party provider (no
  credentials); `.claude/settings.local.json` and managed settings (docs
  only).

Not reached by these cases:

- The import's yes path: B6's script declined it and B8's skipped it, so
  no import line was written into an existing `CLAUDE.md` or
  `.claude/CLAUDE.md`, and the protected-path approval never came up.
- Creating a GitHub repository, push, and labels: every S case skipped the
  GitHub question, and no seed had a remote.
- The description's natural-language triggers: every H run invoked
  `/kenspc-init` or `/kenspc-plan` directly.

Other reasons: only macOS was run; Windows and WSL2 were not.

## 6. Summary

Repository tree `ba2b215`; macOS, Claude Code 2.1.283, 2026-09-28.

| Case | Mode | Seed, cost | Result |
|---|---|---|---|
| B1: the four modes' loading behavior | P | step 1.3's layouts; `b1-import-noplugin`, $0.03 | **PASS** (every § 2.3 sentence agrees with the table, or with an in-batch probe or B1-P) |
| B2: empty directory, cannot ask, one-sentence argument | H ×3 | `b2-1`, $1.05; `b2-2`, $1.05; `b2-3`, $0.98 | **PASS**, all three runs |
| B3: empty directory holding one self-ignoring directory | H | `b3`, $0.96 | **PASS** |
| B4: no git identity | H | `b4`, $0.89 | **PASS** |
| B5: existing repository tracking `docs/briefs/` and `docs/plans/` files | S | `b5` | **PASS** (3 of 3) |
| B6: existing CLAUDE.md, the import declined | S | `b6` | **PASS** (3 of 3) |
| B7: only an AGENTS.md without the marker, no CLAUDE.md | S | `b7` | **PASS** (3 of 3) |
| B8: `.claude/CLAUDE.md` only | S | `b8` | **PASS** (2 of 2; the two OBSERVATION checks hold) |
| B9: interactive run in Chinese | S | `b9` | **PASS** (3 of 3; O36 on two acceptor-worded headers) |
| B10: the file list skipped | S | `b10` | **PASS** (3 of 3) |
| B11: an npm web app scaffolded by its generator | S | `b11` | **PASS** (4 of 4); N7's root scaffolding-line half Not exercised |
| B12: static checks and the pre-flight | static | the repository | **PASS** (the (a)/(b) references replaced; code-fixer covers AGENTS.md; no `MUST`, `NEVER`, or `CRITICAL`; 19 of 19 cannot-ask sentences; `guards run: 11`, `self-tests run: 10`) |
| B13 (optional): generate-plan compatibility | H | `b13-agents`, $1.43 + load probe $0.14; `b13-b2`, $1.58 | **PASS**, both seeds; `b13-agents` by the main session's ruling, with O47 |

Cost: the headless sessions USD 8.12 — the eight H sessions USD 8.08 and
B1-P's two USD 0.03. Step 1.3's probes (USD 1.31) are not included; S mode
started no session. The acceptors and the main session are not included.

Every case PASS and no FAIL: thirteen cases, sixteen case runs — seven
headless (B2 three times, B3, B4, and B13 on two seeds), seven in S mode
(B5–B11), B1 in P mode, and B12 static. Not exercised within them: N7's
root scaffolding-line half (B11), the identity check before scaffolding in
a session that can ask, and B9 in a session that loaded the skill, which
the user re-runs in the Mac TUI. No finding. Forty-eight observations,
twenty-one of them classified in C13: four behavior deviations (O15, O16,
O17, O36), nine 4.0.0 ambiguities or design for the suggestions list (O21,
O24, O25, O37, O38, O40, O41, O43, O48), five environment (O1, O2, O3,
O19, O44), one case setup (O47), one Not exercised (O42), and one process
record (O9). The repository's HEAD stayed `ba2b215` through the runs, and
no case was re-run for a fix. The smoke projects are kept under
`~/Projects/_smoke/batch-h/`.
