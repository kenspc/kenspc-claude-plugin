# Batch G acceptance — the init-project skill, a project's documents from one interview (4.0.0, unreleased)

Acceptance record for batch G (spec: `docs/plans/batch-g-init-project.md`,
section 2; clarifications C1–C14): the section 2.17 cases A1–A12, each in
the mode 2.17 names for it, and one case the main session added, A6c, to
exercise C11's version-line span. One machine, a Linux cloud container,
2026-09-27; the headless runs 16:17–16:29 UTC. The four acceptors recorded
the evidence and their verdicts; the main session classified the results
and the observations in C14 (`7a14f34`). This record was compiled from the
acceptors' reports by a session that took no part in implementing,
reviewing, or running the acceptance.

Labels: **PASS** — the criterion holds; **FAIL** — it does not;
**OBSERVATION** — recorded, not judged; **Not exercised** — the run gave
the criterion nothing to check.

## 1. Setup

| Field | Value |
|---|---|
| Plugin | Repository tree `aee4311` (HEAD before the first run and after the last; no commit landed while the runs went on; after them the main session committed `7a14f34`, clarification C14, `docs/plans/batch-g-init-project.md` only). Under test: `plugins/kenspc/skills/init-project/SKILL.md` (940 lines) with the 12 files under its `templates/`, and `plugins/kenspc/commands/kenspc-init.md`. `plugin.json` still reads 3.9.0; the `## 4.0.0 — unreleased` CHANGELOG entry is the batch's |
| Machine | Linux cloud container, running as root (uid 0). Claude Code 2.1.283, git 2.43.0, node 22.22.2 / npm 10.9.7; `dotnet` and `gh` not installed (`command not found`); the npm registry reachable (`npm view react version` → `19.3.0`). The global git config carries an identity and `commit.gpgsign=true`, so every seed commit was signed |
| Mode H | Real headless sessions, one per case, cwd the seed under `~/Projects/_smoke/batch-g/`: `IS_SANDBOX=1 claude -p --permission-mode bypassPermissions --plugin-dir <repository root>/plugins/kenspc --append-system-prompt "Work without stopping; do not ask clarifying questions." --output-format stream-json --verbose "/kenspc-init <arg>"`, started with `nohup` and stdin from an empty file (A1's first run: the environment note below). `IS_SANDBOX=1` because the container runs as root, where `bypassPermissions` refuses to start without it (C2); the appended system prompt makes each session one that cannot ask (C9). Every session loaded the plugin as `kenspc@inline` 3.9.0, with `kenspc:init-project` and `kenspc:kenspc-init` in its skill list, and ran on the environment's default model for headless sessions (read from its `init` event), not the main session's. Cases A1, A3 (H), A4 (H), A5 (H), A7, A8, and A11 (the same flags, a `/kenspc-plan …` prompt), run by `acceptor-h`, which also ran A12 |
| Mode S | An acceptance subagent followed SKILL.md's text step by step in the seed, as the session running `/kenspc-init` with no argument, and sent each of the skill's questions, one per message, to the main session by `SendMessage`; the main session answered as the user only from the case's script, and "跳过，用默认" to anything the script did not cover. Cases A2 and A10 (`acceptor-s-mono`); A3 (S), A4 (S), A5 (S), and A9 (`acceptor-s-starts`); A6a, A6b, and A6c (`acceptor-s-rerun`) |
| Scripted answers (S) | A2 and A10: round 1 — the name ClinicBook and the summary "Online appointment booking for small clinics." (the rest skipped); round 2 — a monorepo with two apps, `api` (ASP.NET Core) and `web` (React + TypeScript); hosting — no remote yet; scaffolding — both, with the suggested official generator; the missing tool — go on, do not wait; the generator's README — replace it; a nested `.git` — move it to `.trash/`; round 3 — a UI, on the web (component library skipped); round 4 — SemVer, the version in each app's project file, environments dev, staging, and production, deployment TBD (migrations skipped); round 5 — skipped; a GitHub repository — no; the file list — confirm. A3 (S): "这是项目目录". A4 (S): "新 app". A5 (S): "同意加 import". A9: create a GitHub repository. A6a: answer two markers — the deploy method ("GitHub Actions deploys on every push to main; production needs a manual approval.") and the migration policy ("Migrations run in the pipeline before the app starts; never by hand against staging or production.") — and skip the rest. Everything else in each case: "跳过，用默认" |
| Seeds | One directory per case under `~/Projects/_smoke/batch-g/`, built fresh (each setup in § 2): `a1`, `a1-clean`, `a2`, `a3-h`, `a3-s`, `a4-h`, `a4-s`, `a5-h`, `a5-s`, `a7`, `a8`, `a9`; `a11` and `a6-base`, both `cp -a a1` made right after A1's run, before any other use; `a6a`, `a6b`, `a6c`, each a `cp -a` of `a6-base`, which is unchanged afterwards (HEAD `553f4f2`, status clean, the sha256 of every tracked file identical) |
| Evidence | H: per case the stream-json transcript, `.err` (every one empty), the result, the cost, the Bash and tool lists, and a snapshot before and after the run (file list with sha256 outside `.git`, the `.git` entries, `git rev-parse --show-toplevel`, `HEAD`, `symbolic-ref`, `git status --porcelain -uall`, `git log`), under `~/Projects/_smoke/batch-g/_logs/`. S: before-and-after files beside the seeds (`a3-s.sha256.before` and `.after`, `a4-s.HEAD.before`, `a4-s.status.before`, `a5-s.CLAUDE.md.orig`, `a5-s.sha256.before`, `a6a.sha256.before` and `.after`, `a6b.*.before`, `a6c.*.before`, `a9.masked-path`, …) and each acceptor's transcript of the questions and answers. The four acceptors' reports lived in the batch's git-ignored run directory and are not part of the repository |
| Cost | The headless sessions USD 4.08 (below). S mode started no session of its own. The acceptors and the main session are not included |

Per-run cost — each a session's `total_cost_usd`:

| Case | Seed | Turns | Cost |
|---|---|---|---|
| A1 | `a1` | 35 | $0.7138 |
| A1, re-run | `a1-clean` | 33 | $0.4947 |
| A3 (H) | `a3-h` | 5 | $0.1780 |
| A4 (H) | `a4-h` | 5 | $0.1848 |
| A5 (H) | `a5-h` | 33 | $0.6585 |
| A7 | `a7` | 32 | $0.6638 |
| A8 | `a8` | 22 | $0.6592 |
| A11 | `a11` | 12 | $0.3761 |
| Two discarded probes (O36) | copies of `a11` | 1 each | $0.1493 |
| **Total** | | | **$4.0782** |

**Environment note.** In this container `/dev/null` was a regular file
holding text during the run (`/bin/bash: line 1: unalias: unsetenv: not
found`), and `claude -p` appends stdin to the prompt. A1's first run took
its stdin from `/dev/null`, so its argument arrived as the description
followed by that line: the transcript's `queue-operation` reads
`"/kenspc-init ClinicBook：…排班。\n/bin/bash: line 1: unalias: unsetenv: not found\n"`.
Every later headless run took its stdin from an empty file, and each
transcript's `queue-operation` holds the bare prompt. A1 was re-run that
way as `a1-clean` and passed the same way (§ 2.1). C14 classifies this as
an environment issue, not plugin behavior (O1).

**Independence.** The four acceptors — `acceptor-h` (H mode and A12),
`acceptor-s-mono` (A2, A10), `acceptor-s-starts` (A3 (S), A4 (S), A5 (S),
A9), and `acceptor-s-rerun` (A6a, A6b, A6c) — took no part in implementing
or reviewing the skill. `acceptor-h` built the H seeds, launched the
sessions, and read their results; what the headless sessions wrote and
committed is independent of it. In S mode the acceptor carried out the
skill's text itself, so an S case shows what the text gives when it is
followed step by step, not how a session that loaded the skill behaves;
the answers came from the main session, from the scripts above, and each
is quoted where it was given. A6b's filled markers are the acceptor's
setup, not the skill's output (§ 2.6).

## 2. Cases

### 2.1 A1 — empty directory, no git, cannot ask (H; `a1`, $0.71; re-run `a1-clean`, $0.49)

Seed: `mkdir a1`, empty, no git. Argument:
`ClinicBook：给小型诊所用的在线预约系统，病人自己挑时段，职员管理排班。`
The run took 16:17:13–16:19:59Z. Its argument carried the stray stdin line
(§ 1), so A1 was re-run as `a1-clean` (`mkdir a1-clean`, the same argument,
stdin from an empty file), 16:26:58–16:29:19Z.

The final message (A1, trimmed):

> Init run complete for **ClinicBook** … **Start point:** empty directory,
> no git → ran `git init -b main` (default, session couldn't ask). … no
> interview rounds were asked — everything came from your one-line
> description or was left `TBD(init):`. … Not written: `CHANGELOG.md` (no
> versioning scheme chosen yet) … no scaffolding … **Commit:** `553f4f2` —
> `docs: initialize project documentation` … No GitHub repository created
> … Nothing pushed … No labels created … Next step is yours: rerun
> `/kenspc-init` … or start planning with `/kenspc-brief` or `/kenspc-plan`.

Bash commands (10): the Phase 0 probe (`ls -A`,
`LC_ALL=C git rev-parse --is-inside-git-dir`, `--show-prefix`); `ls` of the
templates; `git init -b main` and reads of the identity and branch;
`mkdir -p docs/...`; `printf '.kenspc/\nCLAUDE.local.md\n' > .gitignore`;
the line count; the `{{`, TBD, and secret greps;
`git check-ignore --no-index` for both entries;
`git add <10 paths> && git commit -m "docs: initialize project documentation…"`.
No `gh`, no `git push`, no `curl`.

| Condition | Evidence | Verdict |
|---|---|---|
| `.git` exists, branch `main` | `git branch --show-current` → `main`; `symbolic-ref` → `refs/heads/main`; the only branch | **PASS** |
| Every file 2.8 calls for exists | `AGENTS.md`, `CLAUDE.md`, `README.md`, `docs/product.md`, `docs/architecture/overview.md`, `docs/ui/design-system.md`, `docs/release.md`, `docs/deployment.md`, `docs/backlog/README.md`, `.gitignore` — all ten in `git show --stat HEAD` (243 insertions). No `CHANGELOG.md`, which 2.8 calls for only with a versioning scheme: `docs/release.md` reads `TBD(init): the versioning scheme: SemVer, CalVer, or none` | **PASS** |
| 2.14: the root pair within 80 lines | `grep -c ''`: `AGENTS.md` 49 + `CLAUDE.md` 5 = 54 | **PASS** |
| 2.14: `CLAUDE.md`'s first line is `@AGENTS.md` | `od -c` of line 1: `@ A G E N T S . m d \n`; no `\r` in the file | **PASS** |
| 2.14: the marker and the admission-rule comment | `AGENTS.md` lines 1–10: `<!--`, `kenspc-init template: 1`, the line budget, `Admission rule: …` with conditions 1–3, `-->` | **PASS** |
| 2.14: every Documents path exists | 8 rows, `AGENTS.md` through `docs/deployment.md`, each `[ -e ]` true | **PASS** |
| 2.14: no secret-looking value | the acceptor's scan (a private-key block; GitHub, GitLab, Slack, npm, AWS, and Google key prefixes; a JWT; `Password=`, `Pwd=`, `AccountKey=`, `SharedAccessKey=`, `sig=`; URL userinfo; a key, token, secret, or password label with a long value): no match | **PASS** |
| 2.14: every TBD is `TBD(init): …` | 34 `TBD` occurrences, 34 of them `TBD(init): <text>`; no `{{` left | **PASS** |
| 2.14: `.gitignore` holds both lines | `git check-ignore --no-index -v` → `.gitignore:1:.kenspc/`, `.gitignore:2:CLAUDE.local.md` | **PASS** |
| Policy items are `TBD(init): …` | the versioning scheme, the version file (the `AGENTS.md` Workflow line and `docs/release.md`), the environments, the deploy method, the secrets' location, the migration policy, the branch and commit conventions | **PASS** |
| Both safety rules | `AGENTS.md` lines 24–25: no deploy, migration, or data read against staging or production; secrets stay out of the repository | **PASS** |
| Backlog C | `AGENTS.md` Workflow: `Backlog: one file per item in docs/backlog/…`; `docs/backlog/README.md` committed (frontmatter `type`, `found-by`, `created`, `source`; no status field) | **PASS** |
| No scaffolding, no GitHub action | no app files, no `chore: scaffold` commit; no `gh`, `git push`, or `curl` among the commands (`a1-clean` ran `gh auth status`, a read against a missing binary) | **PASS** |
| One commit, `docs: initialize project documentation`, the tree clean | `git rev-list --count --all` → 1, the subject exact (its body carries the environment's trailers, O6); `git status --porcelain` empty, also with `--ignored -uall` | **PASS** |
| The files in English; nothing under `.claude/` | all ten files English, the Chinese description rendered as "An online appointment booking system for small clinics: …"; no Write, Edit, or Bash target under `.claude/`, none in the tree | **PASS** |
| `a1-clean`: all of the above | branch `main`; one commit, `e4e8fab docs: initialize project documentation`; ten files; 49 + 5 = 54 lines; 35 of 35 `TBD(init):`; no secret; both ignore lines; no `CHANGELOG.md`; the tree clean | **PASS** |

Observations from this case: O2 (a product description the argument did
not give, in `a1` only), O3 (no pathspec on `git commit`), O4 (`a1-clean`'s
commit identity), O5.

### 2.2 A2 — empty directory, interactive, monorepo (S; `a2`)

Seed: `a2`, empty, no git; `/kenspc-init` with no argument. Phase 0:
`ls -A` printed nothing; both `LC_ALL=C git rev-parse` probes failed with
`fatal: not a git repository` (rc 128); `command -v gh` and
`command -v dotnet` rc 1; `node`, `npm`, and `npx` present. Start point:
empty, no git.

The questions, in order, and the answers:

- Q1, `git init` with first branch `main`: "跳过，用默认。" → `git init -b main`
  (O7).
- Q2, round 1: "1. 项目名称：ClinicBook / 2. 一句话简介：Online appointment
  booking for small clinics. / 3–5 跳过。"
- Q3, round 2: "1. Monorepo。 2. 两个 app：api 和 web。 3. api 用 ASP.NET
  Core；web 用 React + TypeScript。" Neither `apps/api` nor `apps/web`
  exists, so each is offered scaffolding.
- Q4, scaffold `api` — naming the .NET SDK's `dotnet new` and
  `apps/api/src/`: "要，用你建议的官方 generator。" `dotnet` is still
  missing, so Q5:
  > `api` 现在没办法 scaffold：这台机器的 PATH 上找不到 `dotnet`（.NET
  > SDK），`dotnet new` 需要它。我不会替你安装任何东西；官方安装程序在
  > https://dotnet.microsoft.com/download （装哪个版本由你决定）。
  > 要怎么继续？ 1. 先不 scaffold `api`，继续往下（`api` 的 commands
  > 会记成 `TBD(init):`）； 2. 等你装好 .NET SDK …

  "1，继续，不用等。"
- Q6, scaffold `web` — Vite's `create-vite` with the React + TypeScript
  template, as react.dev's "Build a React app from scratch" names it:
  "要，用你建议的官方 generator。" Before the run, `npm view create-vite
  version` → `9.2.1` and `npm create vite@latest -- --help`; then
  `npm create vite@9.2.1 apps/web -- --template react-ts --no-interactive --no-immediate`
  (rc 0), without `--overwrite`. 18 files under `apps/web/`, among them a
  32-line `README.md` ("# React + TypeScript + Vite") and a 24-line
  `.gitignore`; no `.git`, no `node_modules`.
- Q7, the generator's README (§ 2.10): "要，换掉。" Then the scaffold commit:
  `git status --porcelain --ignored=matching -uall -- apps/web` showed only
  `??` lines, `git diff --cached --name-only` nothing, and
  `git add -- apps/web && git commit -m "chore: scaffold web" -- apps/web`
  made `cdc9bbd chore: scaffold web` (18 files, 619 insertions). Phase 4
  read the commands from `apps/web/package.json` (`dev`, `build`, `lint`,
  `preview`; no `test` script, so the test command is `TBD(init):`).
- Q8, round 3: "1. 有 UI。 2. 平台是 web。 3、4 跳过，用默认。"
- Q9, round 4: "1. SemVer。 2. 版本号放在各 app 的项目档。 3. 环境：dev、
  staging、production。 4. 部署方式 TBD。 5. 跳过，用默认。"
- Q10, round 5: "跳过。"
- Q11, a GitHub repository (no remote; the question noted `gh` is missing):
  "不要。" → backlog C.
- Q12, the file list — 16 paths, each marked new or, for
  `apps/web/README.md`, replaced, with the checks' results: "确认，commit。"
  → `c359ab3 docs: initialize project documentation` (16 files, 320
  insertions, 31 deletions — the generator's README). Phase 7 did not
  apply: no remote, and backlog C has no labels.

The final message named both commits, the files, 46 remaining
`TBD(init):` markers by file, and what is left: "api 没有 scaffold（PATH
上没有 .NET SDK，你选择不等；装好后项目放在 apps/api/src/；
apps/api/AGENTS.md 的 commands 目前是 TBD）".

| Condition | Evidence | Verdict |
|---|---|---|
| The interview goes round by round, each round skippable | five rounds, one message each (Q2, Q3, Q8, Q9, Q10), each saying it can be skipped; round 5 skipped whole and written as `TBD(init):` (`AGENTS.md` lines 48–49); the items skipped in rounds 1, 3, and 4 are `TBD(init):` in `docs/product.md`, `docs/ui/design-system.md`, and `docs/deployment.md` | **PASS** |
| The layout is `apps/api/` (.NET in `apps/api/src/`) and `apps/web/` | `find -type d` → `./apps/api`, `./apps/web`; `apps/api/` holds only its pair | **PASS**; `apps/api/src/` **Not exercised** (§ 5) |
| Each app has an `AGENTS.md`/`CLAUDE.md` pair within 40 lines | `api` 19 + 6 = 25; `web` 24 + 6 = 30 | **PASS** |
| A missing tool stops and explains; nothing is installed | Q5; `command -v dotnet` rc 1 before and after; no install command run | **PASS** |
| An app with its tool uses the official generator; no hard-coded version or flag in the skill | `web`: create-vite, as react.dev names it (read through a documentation mirror, O12), run after its `--help` and `npm view`. A grep of SKILL.md and the templates for `create-vite`, `npm create`, `npx `, `dotnet new`, `--template`, `@latest`, `webapi`, `react-ts`, and version-like numbers finds only `version: 3.0.0` (the frontmatter) and the Keep a Changelog 1.1.0 and SemVer 2.0.0 URLs in `CHANGELOG.md.tmpl`, which are document-format versions; `dotnet` appears only as a PATH-probe example and `.NET` as the layout example | **PASS** |
| One `chore: scaffold <app>` commit per scaffolded app, before the documentation commit | `cdc9bbd chore: scaffold web` before `c359ab3`; `api`, not scaffolded, has none | **PASS** |
| `CHANGELOG.md` exists | 8 lines, Keep a Changelog, SemVer | **PASS** |
| Backlog C | `docs/backlog/README.md`; `AGENTS.md` line 50 `Backlog: one file per item in docs/backlog/…`; the Documents footnote names `docs/backlog/` as not durable | **PASS** |
| 2.14 on the result | root 52 + 5 = 57, within 80; the three `CLAUDE.md` files open with `@AGENTS.md`; the three `AGENTS.md` carry the marker and the admission rule, the comment byte-identical to the template's; the 11 Documents paths exist; the skill's secret patterns over all 16 written files: no hit; every TBD `TBD(init): …`, no `{{`; `.gitignore:1:.kenspc/`, `.gitignore:2:CLAUDE.local.md` | **PASS** |
| After the run | `git log --oneline`: `c359ab3`, `cdc9bbd`; `git status --porcelain` empty; HEAD `refs/heads/main`; 0 CJK lines in the tracked text; nothing under `.claude/` | **PASS** |

Observations from this case: O7–O12.

### 2.3 A3 — files, not a git repository (S `a3-s`; H `a3-h`, $0.18)

**S.** Seed: `notes.txt` (3 lines), `budget.csv` (5 lines), `photo.bin`
(1024 random bytes); no git. sha256 before: `336fdcaa…d8d1`,
`23cf6673…f349`, `b2b866ff…6642`. Phase 0: `ls -A` the three files; both
`git rev-parse` probes `not a git repository` → files, no git. The first
question:

> [A3] 这个目录还不是 git repository，里面已经有这些档案：
> - budget.csv
> - notes.txt
> - photo.bin
>
> 这个目录就是你的项目目录吗？如果是，我会在这里执行 `git init`，第一个
> branch 用 `main`，然后继续初始化（访谈、写文件、commit）。如果不是，我就
> 停下，不写任何东西。

The answer: "这是项目目录。" Then `git init -b main`. Rounds 1–5, the
GitHub question, and the file list were each answered "跳过，用默认。"; the
root app already holds files, so no scaffolding was offered. The commit,
with a pathspec of the ten paths: `a5f1452 docs: initialize project
documentation` (10 files, 242 insertions). After it `git status
--porcelain` lists `?? budget.csv`, `?? notes.txt`, `?? photo.bin` (O14).

| Condition | Evidence | Verdict |
|---|---|---|
| Lists the files and asks first | the question lists all three and names the `git init`; the only command before it was the read-only scan | **PASS** |
| Continues only after "这是项目目录" | `git init` after the answer, nothing written before it | **PASS** |
| The three files unchanged and in no commit | `diff a3-s.sha256.before a3-s.sha256.after` → no output; `git ls-files -- notes.txt budget.csv photo.bin` → empty | **PASS** |
| 2.14 on the result | 49 + 5 = 54; `@AGENTS.md` first; the comment; 8 Documents paths exist; no secret; every TBD `TBD(init): …`, no `{{`; both ignore lines | **PASS** |

**H.** Seed `a3-h`: `notes.txt` (1 line), `budget.csv` (2 rows),
`photo.bin` (1024 random bytes); no git; no argument. The run took
16:18:25–16:18:43Z. Bash: `ls -A`, `LC_ALL=C git rev-parse
--is-inside-git-dir` (not a git repository), `--show-prefix`; then
`cat notes.txt | head -50`, `cat budget.csv | head -20`, `file photo.bin`,
`ls -la photo.bin`, `which gh && gh auth status`. The final message
(trimmed):

> This directory currently holds only personal files — `notes.txt` (a
> reminder about calling the landlord), `budget.csv` (a personal budget),
> and `photo.bin` (a 1KB binary, not a project asset) — nothing that looks
> like a software project, and there's no git repository here yet. Before I
> do anything, I need to confirm: **is this directory meant to become your
> project?** … Could you confirm which it is, and if it's the project, tell
> me a bit about it (name, one-line summary, users, scope)?

| Condition | Evidence | Verdict |
|---|---|---|
| The run stops | no write, no `git init`; the session ended after two Bash calls, both reads | **PASS** |
| The names and sha256 unchanged | the snapshots before and after are identical: `budget.csv` `ce3389b4…`, `notes.txt` `e06862c8…`, `photo.bin` `ff5f660e…`; `ls -A` the same three files, no `.git` | **PASS** |
| The final message | lists the entries but ends on a question and never says the run stopped; it describes two files' contents | **OBSERVATION** (O13) |

Observations from this case: O7, O13–O17.

### 2.4 A4 — inside another repository (S `a4-s`; H `a4-h`, $0.18)

**S.** Seed: `a4-s/` with `git init -q -b main`, a `README.md`, and
`519e757 chore: add readme`; `mkdir a4-s/sub`, empty. HEAD before
`519e757`, status empty. Phase 0 from `sub/`: `ls -A` nothing;
`--is-inside-git-dir` `false`; `--show-prefix` `sub/`; `symbolic-ref -q
HEAD` `refs/heads/main` → inside another repository. The question:

> [A4] 这个目录 `sub/` 在另一个 git repository 里面：上层 repo 是
> `/root/Projects/_smoke/batch-g/a4-s`（branch `main`），这个目录是它的
> 子目录 `sub/`。请问 `sub/` 是哪一种？
> 1. 上层 repo 里的一个新 app —— 我只在 `sub/` 里建一对 `AGENTS.md` /
>    `CLAUDE.md`，不做 `git init`，也不动上层 repo 的其他东西。
> 2. 应该独立的项目 —— 建议先把这个目录搬出上层 repo，再在新位置跑
>    `/kenspc-init`；这次我就停下，不写任何东西。

The answer: "新 app。" The outer root has no templated `AGENTS.md`, so the
lines pointing at the root's conventions were left out. The new-app
interview and the file list were answered "跳过，用默认。". The commit:
`6212fcf docs: initialize project documentation`, touching `sub/AGENTS.md`
(18 lines) and `sub/CLAUDE.md` (5 lines) only. After it `ls -A a4-s` →
`.git README.md sub`, `ls -A a4-s/sub` → `AGENTS.md CLAUDE.md`, the tree
clean. The final message noted that the outer repository has no
`.gitignore`, so neither `.kenspc/` nor `CLAUDE.local.md` is ignored there,
and left that to the user.

| Condition | Evidence | Verdict |
|---|---|---|
| Asks: a new app, or a project of its own | the question above | **PASS** |
| After "新 app", only the pair in `sub/` | the commit touches exactly `sub/AGENTS.md` and `sub/CLAUDE.md`; 18 + 5 = 23 lines | **PASS** |
| No `git init` | no `sub/.git`; no documents at the outer root; no outer `.gitignore` written | **PASS** |

**H.** Seed: `a4-h/` with `git init -b main`, a `README.md`, and
`e8aeb3e Initial commit`; `mkdir sub`, empty; launched from `a4-h/sub/`,
no argument. The run took 16:18:25–16:18:47Z. Bash: `pwd; ls -A;
LC_ALL=C git rev-parse --is-inside-git-dir` (`false`), `--show-prefix`
(`sub/`), `LC_ALL=C git symbolic-ref -q HEAD`; then `git rev-parse
--show-toplevel; git remote -v; ls -A <toplevel>`. The final message
(trimmed):

> … `/root/Projects/_smoke/batch-g/a4-h/sub` is empty, but `git rev-parse
> --show-prefix` prints `sub/`, meaning it sits inside another git
> repository rooted at `/root/Projects/_smoke/batch-g/a4-h` … This session
> is running under an instruction to work without stopping … exactly the
> "session that cannot ask" case the skill defines. In that case … **stop
> and write nothing** … **Result: the run stopped. Nothing was written.**

| Condition | Evidence | Verdict |
|---|---|---|
| The run stops | the final message; no write tool call | **PASS** |
| The outer `git status --porcelain` unchanged | empty before and after, also with `--ignored -uall` | **PASS** |
| The outer HEAD unchanged | `e8aeb3e` before and after | **PASS** |
| `sub/` still empty, no `.git` | `ls -la sub` → `.` and `..` only; the snapshots identical | **PASS** |
| The message names the outer repository and the reason | names `/root/Projects/_smoke/batch-g/a4-h` and says it could not ask which of the two `sub/` is | **PASS** |

Observations from this case: O15, O18, O19.

### 2.5 A5 — existing repository with a 60-line CLAUDE.md and a README (S `a5-s`; H `a5-h`, $0.66)

**S.** Seed: `a5-s/` with `git init -q -b main`; a 60-line `CLAUDE.md`
(`grep -c ''`), LF, for a project "Ledgerline" — Commands (npm), Code style,
Testing, Safety, Git, Architecture notes, Reviews, Misc; no TBD, no
secret-looking value; a 5-line `README.md`; `0864fe0 docs: add CLAUDE.md and
README`. A copy of `CLAUDE.md`, `a5-s.CLAUDE.md.orig`, is cmp-identical to
the committed file. sha256 before: `CLAUDE.md` `14b6a038…27cf`, `README.md`
`b789e738…5a06`. Phase 0: an existing repository; no `AGENTS.md`, so not a
rerun; `CLAUDE.md` is not the same file as `AGENTS.md` and holds no
`@AGENTS.md` line.

Rounds 1–5, each pre-filled from `CLAUDE.md` and the README, and the GitHub
question were answered "跳过，用默认。" (O23). The missing files were
written first, with `CLAUDE.md` and `README.md` untouched at that point.
Then the import question:

> 还有一个问题：Claude Code 只会载入 `CLAUDE.md`，不会自己读
> `AGENTS.md`。要不要在 `CLAUDE.md` 最上面加一行 `@AGENTS.md`（import）？
> 只加这一行，原有 60 行一字不改；之后我会报告两份合计的行数，以及两份看得
> 出的重复内容，由你决定怎么整理，我不会删任何东西。

The answer: "同意加 import。" The report that followed:

> **合计行数**：`AGENTS.md` 49 行 + `CLAUDE.md` 61 行 = **110 行**。

with five duplications, each by line numbers in both files (the project
name and summary; the deploy, migration, and data safety rule; secrets out
of the repository; the branch convention; the commit convention), and one
inconsistency: `CLAUDE.md` lists npm commands, the repository has no
`package.json`, so `AGENTS.md`'s Commands is `TBD(init):`. The file list was
answered "跳过，用默认。" (O15): `99d1699 docs: initialize project
documentation` (9 files; `CLAUDE.md | 1 +`).

| Condition | Evidence | Verdict |
|---|---|---|
| `CLAUDE.md`'s first line becomes `@AGENTS.md`, the rest byte-identical | `head -n1 CLAUDE.md` → `@AGENTS.md`; `tail -n +2 CLAUDE.md \| cmp - a5-s.CLAUDE.md.orig` exit 0; the same from `git show HEAD:CLAUDE.md`; `git show HEAD -- CLAUDE.md` adds one line | **PASS** |
| `README.md`'s sha256 unchanged | `b789e738…5a06` before and after; `git diff HEAD~1 HEAD -- README.md` empty | **PASS** |
| Reports the combined line count and the duplication | 110 lines; five duplications with line numbers, and the commands inconsistency | **PASS** |

**H.** Seed: `a5-h/` with `git init -b main`; a 60-line `CLAUDE.md`
("Harbor Ledger" rules: stack, commands, style, testing, rules, git, terms;
no TBD, no secret); a 5-line `README.md`; `27303a4 chore: add project
notes`; no argument. The run took 16:19:24–16:23:04Z. Bash (12): the
Phase 0 probes under `LC_ALL=C`; status, remotes, `git log --oneline -15`,
the README, the tree; the `.gitignore` and `check-ignore --no-index`
probes; the templates; `wc -l CLAUDE.md README.md`; `mkdir -p docs/...`;
the checks; `git add <8 paths>`; `git commit -m … -- <8 paths>`. The final
message (trimmed):

> **Left untouched:** `CLAUDE.md` and `README.md` — already existed, not
> overwritten. `CLAUDE.md` does **not** yet import `AGENTS.md`. Because this
> session can't pause to ask, I left it as-is rather than adding the
> `@AGENTS.md` line myself — until you add it, Claude Code won't load
> `AGENTS.md`. Add this as the first line of `CLAUDE.md` when you're ready:
> `@AGENTS.md`

| Condition | Evidence | Verdict |
|---|---|---|
| `CLAUDE.md`'s sha256 unchanged | `8c5c721d…0c7d` before and after | **PASS** |
| `README.md`'s sha256 unchanged | `072475c3…3171` before and after | **PASS** |
| The final message says `AGENTS.md` is not yet loaded | the message above, with the line to add; true of this build: the session's `instructions` attachment holds only `a5-h/CLAUDE.md` (O35) | **PASS** |
| What was committed | one commit, `81b86c6 docs: initialize project documentation` (8 files, 255 insertions): `AGENTS.md` (60 lines; beside an existing `CLAUDE.md` the budget counts `AGENTS.md` alone), `.gitignore` with both lines, the five topic documents, `docs/backlog/README.md`; no `CHANGELOG.md` (scheme TBD). The acceptor's 2.14 re-checks hold: the marker and the comment, 8 Documents paths, 29 of 29 `TBD(init):`, no `{{`, no secret. The tree clean | **OBSERVATION** (all hold) |

Observations from this case: O20–O24.

### 2.6 A6 — rerun (S; `a6a`, `a6b`, and main's `a6c`)

Each sub-case ran on a `cp -a` copy of `a6-base`, which is A1's result
(HEAD `553f4f2`, one commit, the tree clean). Phase 0 in each: an existing
repository on `refs/heads/main`, no remote, and `kenspc-init template: 1`
at `AGENTS.md` line 2, so the run goes to § Rerun and Phases 1–7 do not
apply. The files the rerun owns are `AGENTS.md` and the eight paths of its
Documents table.

**A6a — two markers answered.** Before: 34 `TBD(init):` markers in 7 files,
one per line, and no other `TBD` form; the sha256 of every tracked file in
`a6a.sha256.before`. The questions went one group per file, seven groups,
each skippable. Groups 1–6 were answered "跳过。". Group 7,
`docs/deployment.md` (Environments :5, How deploys happen :9, Configuration
and secrets :15, Migrations :19, Rollback :23, Monitoring :27), was
answered:

> 2：GitHub Actions deploys on every push to main; production needs a manual
> approval. / 4：Migrations run in the pipeline before the app starts; never
> by hand against staging or production. / 其余跳过。

The file list — `docs/deployment.md`, two markers filled, both new lines
quoted — was answered "跳过，用默认。" (O15). The commit:
`git commit -F <msg> -- docs/deployment.md` → `e661275 docs: fill in
answered TBD(init) markers`. `git diff HEAD~1..HEAD`:

```
 docs/deployment.md | 4 ++--
@@ -6,7 +6,7 @@
 ## How deploys happen

-TBD(init): the pipeline, what triggers it, and who approves
+GitHub Actions deploys on every push to main; production needs a manual approval.
@@ -16,7 +16,7 @@
 ## Migrations

-TBD(init): the migration policy: how schema changes are written, reviewed, and applied, and to which environments
+Migrations run in the pipeline before the app starts; never by hand against staging or production.
```

| Condition | Evidence | Verdict |
|---|---|---|
| Only the two answered places change | the diff above: `docs/deployment.md` lines 9 and 19 | **PASS** |
| `git diff` touches only the lines that held the markers | both markers alone on their lines, so the span ran to the end of the line; the empty text before each is kept; 27 lines and a final newline in both versions | **PASS** |
| Every other byte unchanged; `.gitignore` untouched | `diff a6a.sha256.before a6a.sha256.after` shows only `docs/deployment.md`; the file set the same; `.gitignore` `c7ea87d5…` unchanged; `git status --porcelain --ignored -uall` empty; 32 markers remain | **PASS** |
| The version line's span stops at ` — ` (C11) | the user did not answer `AGENTS.md` line 49 | **Not exercised** here; A6c |

**A6b — no marker left.** Setup, by the acceptor: a script filled all 34
markers of a copy of `a6-base` (on the version line it stopped at
` — rules in docs/release.md`, per C11); `grep -rn 'TBD' .` then found
nothing, and the fill was committed as `b25a233 test: fill every marker`,
the tree clean. The rerun: `grep -c 'TBD(init):'` is 0 in `AGENTS.md` and
in each of the eight Documents paths, so no question group was sent, nothing
was written, and there was no file list and no commit. The final message:

> 起点：已有 repo（AGENTS.md 带 kenspc-init template: 1），本次为重跑。
> 没有任何 TBD(init): 标记——AGENTS.md 和它的 Documents 表列出的 8 份文件里都
> 是 0 个——所以这次不改任何东西，没有 commit。

| Condition | Evidence | Verdict |
|---|---|---|
| Zero changes | HEAD `b25a233` before and after; `git status --porcelain --ignored -uall` empty before and after; the sha256 of the 10 tracked files unchanged; the file set unchanged; `refs/heads/main` only, no stash | **PASS** |
| Says why | the message above | **PASS** |

**A6c — the version-line marker alone (added by the main session to
exercise C11; not in 2.17).** Before: `AGENTS.md` line 49
`- Version lives in TBD(init): the file that holds the version number — rules in docs/release.md`
(the separator U+2014 with a space on each side, LF). Group 1, `AGENTS.md`,
was answered "4：package.json / 其余跳过。"; group 2 "跳过。之后第 3 到第 7
组也全部跳过。", so groups 3–7 were not sent (O28); the file list "确认。".
The commit: `git commit -F <msg> -- AGENTS.md` → `8d13ba6 docs: fill in
answered TBD(init) markers`. The diff:

```
-- Version lives in TBD(init): the file that holds the version number — rules in docs/release.md
+- Version lives in package.json — rules in docs/release.md
```

| Condition | Evidence | Verdict |
|---|---|---|
| Line 49 becomes `- Version lives in <answer> — rules in docs/release.md`, the text from ` — ` byte-identical | the prefix `- Version lives in ` and the tail ` — rules in docs/release.md` byte-identical to HEAD~1 | **PASS** |
| No other line or file changes | `AGENTS.md` 49 lines and a final newline in both versions, only line 49 differs; the sha256 of the other 9 tracked files unchanged; `.gitignore` untouched; the tree clean; 33 markers remain | **PASS** |
| The commit holds only `AGENTS.md` | `git show --name-only HEAD` → `AGENTS.md` | **PASS** |

Observations from this case: O25–O31.

### 2.7 A7 — GitHub remote, cannot ask (H; `a7`, $0.66)

Seed: `git init -b main`, a `README.md`, `fea2093 Initial commit`, and
`git remote add origin https://github.com/example/seed.git`, not pushed; no
argument. The run took 16:19:24–16:22:32Z. Bash (11): the Phase 0 probes; a
`find` for `AGENTS.md` and `CLAUDE.md`, `git log`, `git remote -v`,
`git status`; the tree; `gh --version | head -1 && gh auth status | head -5`
(`gh` absent); the templates; the `.gitignore` read; `wc -l`; `mkdir -p`;
the checks; `git add <8 paths>`; `git commit -m … -- <8 paths>`. The final
message (trimmed):

> … `CHANGELOG.md` and `docs/backlog/README.md` — not written: no versioning
> scheme was chosen, and the backlog is GitHub Issues (remote is on
> `github.com`) … **Commit:** `e983ec9` … Nothing pushed; No GitHub labels
> created (`gh` isn't installed, so existing labels couldn't even be read)
> … **Left for you:** `debt` and `found-by-agent` labels to create on the
> GitHub repo (and confirm `bug`/`enhancement` exist); Push the commit to
> `origin` when ready …

| Condition | Evidence | Verdict |
|---|---|---|
| The backlog convention is GitHub Issues | `AGENTS.md` line 47 `Backlog: GitHub Issues, labeled bug, enhancement, debt, and found-by-agent.`; line 40 the Issues form of the not-durable sentence; no `docs/backlog/` | **PASS** |
| The labels only in the final message | `debt` and `found-by-agent` listed there; no `gh label` command | **PASS** |
| No proposal to create a repository | none in the final message or the transcript | **PASS** |
| No network write | no `gh` write, `git push`, or `curl`; the reads `gh --version` and `gh auth status` both failed on the missing binary; no `git ls-remote` or `fetch`; the remote unchanged; `git branch -vv` shows no upstream | **PASS** |
| 2.14 re-check | 49 + 5 = 54; `@AGENTS.md` first; the marker; 8 paths exist; 35 of 35 `TBD(init):`; no secret; both ignore lines; the README's sha256 unchanged; one new commit, `e983ec9 docs: initialize project documentation`; the tree clean | **OBSERVATION** (all hold) |

### 2.8 A8 — non-GitHub remote, cannot ask (H; `a8`, $0.66)

Seed: as A7, with `f721a4e Initial commit` and the remote
`https://dev.azure.com/example/seed/_git/seed`; no argument. The run took
16:19:24–16:22:47Z. The final message (trimmed):

> **Start point:** Existing repository (… remote `origin` → Azure DevOps
> `dev.azure.com/example/seed/_git/seed`) … **Commit:** `867d351 docs:
> initialize project documentation` … **Backlog:** file-based (C) — the
> remote is Azure DevOps, not GitHub, so GitHub Issues (A) doesn't apply.
> … **Defaults taken since the session couldn't ask:** no scaffolding
> offered/run, no push attempted, no GitHub repo action (a non-GitHub
> remote already exists) …

| Condition | Evidence | Verdict |
|---|---|---|
| Backlog C | `AGENTS.md` line 47 `Backlog: one file per item in docs/backlog/…`; `docs/backlog/README.md` committed | **PASS** |
| No proposal of a GitHub repository | only "no GitHub repo action (a non-GitHub remote already exists)", as the skill says | **PASS** |
| The rest | no network command (`gh --version` and `gh auth status` reads only); 54 lines; 36 of 36 `TBD(init):`; no secret; both ignore lines; the README's sha256 unchanged; the tree clean | **OBSERVATION** (all hold; O32) |

### 2.9 A9 — no remote, `gh` absent, interactive (S; `a9`)

Seed: `mkdir a9`, empty, no git. The mask: `PATH` with every entry that
holds an executable named `gh` removed (none held one, since `gh` is absent
here), saved in `a9.masked-path`; every command ran as
`env PATH="$MASKED" bash -c '…'`; under it `command -v gh` exits 1 and
`gh auth status` prints `gh: command not found` (127).

The `git init` question, rounds 1–2, the scaffolding offer (the root holds
only `.git`, O33), and rounds 3–5 were answered "跳过，用默认。" → `git init
-b main`, one app, not scaffolded. The GitHub question —
"GitHub：这个 repo 目前没有任何 remote。要建一个 GitHub repository 吗？（默认
private。）" — was answered "要，建一个 GitHub repo。" `gh` was probed again
under the mask and was missing, so there was no owner or name question —
that one needs `gh` installed and logged in — and the manual steps came
instead (trimmed):

> [A9] 这台机器上没有 `gh`（GitHub CLI）——`command -v gh` 找不到它，所以我
> 没办法替你建 repo，也不会替你安装。请照下面的步骤手动建：
> 1. 在 GitHub 上新建一个 repository（https://github.com/new）…
> 2. 建好后，在这个目录里设定 remote：`git remote add origin <repo 的 URL>` …
> 3. 准备好时再 push：`git push -u origin main`
>
> 因为现在还没有 GitHub remote，backlog 先用 C：`docs/backlog/` 一项一档
> （格式写在 `docs/backlog/README.md`）。

The file list was answered "跳过，用默认。" (O15): `e7739f2 docs:
initialize project documentation` (10 files, 242 insertions).

| Condition | Evidence | Verdict |
|---|---|---|
| Explains the manual steps to create the repository | the message above, repeated in the final message | **PASS** |
| Backlog C | `AGENTS.md` line 47 `- Backlog: one file per item in docs/backlog/; the format is in docs/backlog/README.md.`; line 40 marks `docs/backlog/` as not durable; `docs/backlog/README.md` present | **PASS** |
| The rest | 49 + 5 = 54 and every check passing, run under the masked `PATH`; `git status --porcelain` empty; no remote; branch `main` | **PASS** |

Observations from this case: O33, O34.

### 2.10 A10 — generator conflict (S, optional; A2's `web` scaffold)

Evidence from A2's run (§ 2.2). Right after the generator, before the skill
touched anything, `apps/web/.gitignore` had sha256 `fe718e7b…44e8` and
`apps/web/README.md` `fa8aac78…2517`, and copies were saved. The README
question (trimmed):

> [init-project Q7 · Scaffolding · generator 的 README] `web` 已用 Vite 的
> create-vite（9.2.1，React + TypeScript 模板）生成在 `apps/web/`；它没有做
> `git init`，也没有装依赖。它写了一份 `apps/web/README.md`（32 行，标题
> "React + TypeScript + Vite"，内容是在介绍 Vite 模板本身，不是这个项目）。
> 这是这次执行自己的产物，要换成 init 的版本吗？ … 换掉 / 保留 generator
> 的版本？（预设：换掉）

The answer: "要，换掉。"

| Condition | Evidence | Verdict |
|---|---|---|
| The generator's README is replaced after asking | the question above; the generator's README is in `cdc9bbd`, and init's 4-line version replaced it in `c359ab3` (`git log -- apps/web/README.md` shows both) | **PASS** |
| `.gitignore` is merged, not overwritten | `apps/web/.gitignore` has sha256 `fe718e7b…44e8` right after the generator, in `cdc9bbd`, and at HEAD; the root `.gitignore` did not exist and was created with its two lines | **PASS** on "not overwritten"; the merge into an existing `.gitignore` **Not exercised** (§ 5) |
| A nested `.git` from the generator is asked about and moved to `.trash/`, with `.trash/` in `.gitignore` | create-vite 9.2.1 runs no `git init`: `ls apps/web/.git` → no such file or directory, `find . -mindepth 2 -name .git` empty; no `.trash/` was created or added to `.gitignore`, as the skill says when none is used | **Not exercised** (§ 5) |

### 2.11 A11 — `/kenspc-plan` on A1's result (H, optional; `a11`, $0.38)

Seed: `a11`, `cp -a a1` made right after A1's run. Prompt:
`/kenspc-plan 病人取消预约时，系统要通知职员并释放时段。`, with the H
flags. The run took 16:20:35–16:24:33Z. Tools: the Skill call
`kenspc:generate-plan`; `find . -maxdepth 3`; Reads of
`shared/discovery-framework.md`, `docs/product.md`,
`docs/architecture/overview.md`, `docs/deployment.md`, `README.md`,
`docs/release.md`, `docs/backlog/README.md`, and
`docs/ui/design-system.md`; no Read of `AGENTS.md` or `CLAUDE.md`. It
stopped at the draft ("Plan not written: awaiting approval."), and the seed
is byte-identical before and after.

The draft's Documentation impact: `docs/architecture/overview.md` — Data;
Key decisions; `docs/product.md` — Terms; `AGENTS.md`, `CLAUDE.md`,
`README.md`, `docs/ui/design-system.md`, `docs/release.md`, and
`docs/deployment.md` — each `N/A — …`.

| Condition | Evidence | Verdict |
|---|---|---|
| The draft's Documentation impact lists files from `AGENTS.md`'s Documents table | its entries cover exactly the table's 8 rows, with no file outside the table and no `docs/backlog/`, which the table's footnote marks as not durable | **PASS** |
| How the table reached the session | through `CLAUDE.md`'s import: the transcript's `instructions` attachment lists `a11/CLAUDE.md` and `a11/AGENTS.md` (type Project) and holds the Workflow line `Version lives in …`; no Read of `AGENTS.md`, no separate file attachment | **OBSERVATION** (O35) |

Observations from this case: O2 (the plan cites a line A1 added), O35, O36.

### 2.12 A12 — static checks (repository tree `aee4311`)

| Condition | Evidence | Verdict |
|---|---|---|
| No `MUST`, `NEVER`, or `CRITICAL` in the skill's text (C8: capitals, whole word) | `grep -rnw -e MUST -e NEVER -e CRITICAL plugins/kenspc/skills/init-project` → no output, exit 1; `commands/kenspc-init.md` clean too | **PASS** |
| Every question opens with the cannot-ask sentence | with the line breaks joined, 19 occurrences of `In a session that cannot ask (a system reminder to work without stopping),`, one per question (SKILL.md lines): files, no git (183); inside another repository (202); the empty directory's `git init` (228); interview rounds 1–2 (279); scaffolding, per app (304); a missing tool (328); a generator's README (346); a generator's `.git` (356); interview rounds 3–5 (422); hosting, with a remote (437); creating a GitHub repository (443); its owner and name (454); an existing `CLAUDE.md` (632); the file list (713); a failed commit (738); push (753); labels (762); the new-app interview (801); the rerun's markers (825). Every row of the gate table (859–877) maps to one of them; the other "cannot ask" mentions — three DONE clauses (251, 404, 505) and the Exit list (891) — are not questions | **PASS** |
| The `description` has English and Chinese triggers | SKILL.md lines 3–15: "initialize this project", "bootstrap a new project", "set up AGENTS.md and the project docs", "set up this repo for kenspc"; "初始化项目", "建立项目文件", "帮我初始化这个项目", "新项目开个头"; and "Not for questions about Claude Code's built-in /init or about what "init" means (answer directly)". The command's description carries "初始化项目" | **PASS** |
| The pre-flight block exits 0 | the `( set -e … )` block of `docs/release-checklist.md`, run from the repository root: exit 0; both `claude plugin validate --strict` calls "Validation passed"; 10 guards PASS, `guards run: 10`; 9 self-tests PASS, last line `self-tests run: 9`; the repository's status unchanged | **PASS** |
| No `effort:` frontmatter (2.2) | `grep '^effort:'` in SKILL.md → none | **PASS** |

## 3. Findings

None. Every case's criteria held and no FAIL was recorded, so there is no
finding to classify. C14 (`7a14f34`) records the same: with no FAIL there
is no plugin defect to hand to a fixer, and it classifies six of the
observations (§ 4). No acceptor changed a plugin file, and no case was
re-run for a fix; A1's re-run, `a1-clean`, was for the environment (§ 1).

## 4. Observations

- **O1** — The stdin of A1's first run came from a `/dev/null` that held
  text, and the argument arrived with that line appended (§ 1). The re-run
  from an empty file gave the same result. C14: an environment issue, not
  plugin behavior.
- **O2** — A1's `docs/product.md` adds claims its argument does not make:
  "replacing phone-in scheduling", patients who "reschedule, or cancel",
  and "for a single small clinic". `a1-clean`'s does not (its Purpose is
  `TBD(init):`). A11's draft later cites "booking/rescheduling/cancelling"
  as grounded in `docs/product.md`, so the added line travelled downstream.
  The skill's Quality bar allows only what the user said, what a file
  shows, or a `TBD(init):` marker. C14: behavior deviation — the model did
  not follow the Quality bar; for Known behavior: read `docs/product.md`
  once after init.
- **O3** — A1 committed with `git add <paths> && git commit -m …`, with no
  pathspec on `git commit`, where the skill passes the paths to
  `git commit` as a pathspec. Harmless in a fresh repository with nothing
  staged; A5 (H), A7, and A8 used `git commit … -- <paths>`.
- **O4** — `a1-clean` committed with
  `git -c user.name="kenspc-init" -c user.email="noreply@anthropic.com" commit …`,
  so its author and committer read `kenspc-init`, although a global
  identity is configured; A1 used the global one. SKILL.md says nothing
  about the commit identity. C14: behavior deviation; SKILL.md has no such
  rule.
- **O5** — Both A1 runs first wrote the deployment environments as a table
  with a TBD row, then replaced it with one `TBD(init):` line, as the
  skill's rule for an unknown section says.
- **O6** — The headless sessions inherited the harness's session id and
  attribution reminder, so every commit they made carries the environment's
  attribution trailers in its body; every subject is exact. The seed
  commits, S and H, were signed through the container's global
  `commit.gpgsign=true`, with no effect on the cases.
- **O7** — "跳过，用默认" was read as skipping the current question or
  round, not as the end-of-interview phrase ("Use the defaults for
  everything, in any wording or language"): in A2 at the `git init`
  question, and in A3 (S), A5 (S), and A9 at every round. Chinese does not
  mark the plural, so the phrase can also be read as "use the defaults" in
  general; the skill gives no rule for telling a round skip from the
  end-of-interview phrase. Under the other reading rounds 2–5 would not
  have been asked, while the GitHub question and the file list still
  would.
- **O8** — A2: the skill asks about the generator's README after the
  generator runs, but does not say whether the replacement is written
  before the scaffold commit, so that the generator's README never enters
  history, or in Phase 6. The acceptor wrote it in Phase 6, following the
  scaffold commit's Why ("a diff of it alone is readable"). § Files has a
  row for the root `README.md` in place of a generator's README, and none
  for an app directory's.
- **O9** — A2: create-vite 9.2.1 has an option no answer covers,
  `--eslint`/`--no-eslint` (ESLint or Oxlint); the generator's default,
  Oxlint, was left, and `apps/web/AGENTS.md` records `npm run lint`.
  `--no-interactive` and `--no-immediate` followed from running without
  prompts, an install, or a dev server.
- **O10** — A2: Phase 0 already found `dotnet` missing, but the scaffolding
  offer for `api` (Q4) came first, naming a generator the run could not
  use, and the missing-tool explanation (Q5) only after the yes — one round
  trip more. It works as written.
- **O11** — A2: the version slot in `AGENTS.md.tmpl` reads "the file that
  holds the version number", singular; with a version per app the line
  reads "each app's project file", and `docs/release.md` lists each app.
  The template has one root `CHANGELOG.md` while each app carries its own
  SemVer version, which 2.8 allows and a team may want to settle.
- **O12** — A2: react.dev and learn.microsoft.com are blocked by the
  container's egress proxy. The official React page was read through a
  documentation mirror of the react.dev repository; the .NET template name
  (`dotnet new`, Web API) came from general knowledge and was not checked,
  and never ran, since the SDK is missing.
- **O13** — A3 (H): the final message lists the entries but frames the
  stop as a pending question ("Could you confirm which it is…?") and never
  says the run stopped, where the skill's cannot-ask branch says the run
  stopped because it could not confirm the directory. The session did not
  take the appended system prompt as its cannot-ask signal here, although
  A4 (H) did in the same setup. It also read `notes.txt` and `budget.csv`
  with `cat` and described them ("a reminder about calling the landlord",
  "a personal budget"), where the skill lists the entries; the skill's Why
  names a home or downloads folder as the case this start point guards.
  C14: behavior deviation; nothing was written, and the case still PASSES.
- **O14** — A3 (S): the three files that were there before stay untracked
  in the new repository, so the tree is not clean after the run. This is
  the skill's text (a file that was already there is staged by no commit
  unless the run changed it), and the final message names them; 2.3 and
  2.17 A3 say nothing about it.
- **O15** — A skipped file list commits: in A3 (S), A4 (S), A5 (S), A9, and
  A6a the file list was answered "跳过，用默认", and the run committed the
  list as presented. The skill reaches that through § Defaults and TBD — a
  question skipped in a session that can ask takes the default — whose
  default column is headed "In a session that cannot ask"; the Phase 6
  text itself handles confirm, adjust, and no, and calls the user's look
  at the list the gate before the files enter history. `acceptor-s-rerun`
  asked whether a skip at that gate should commit or be read as a no. C14:
  as designed — the defaults table's Commit is "do" (2.11); for Known
  behavior.
- **O16** — A3 (S): with the versioning scheme TBD, the template's
  `{{when: the versioning scheme is not none}}` was read as true (TBD is
  not "none"), giving
  `Version lives in TBD(init): the file that holds the version number — rules in docs/release.md`,
  consistent with C11's marker span.
- **O17** — A3 (S): the Documentation list in `templates/README.md.tmpl`
  names four topic documents and `AGENTS.md`, but not
  `docs/ui/design-system.md`. Not a PASS condition.
- **O18** — A4 (S): the new-app run commits the pair into the outer
  repository, so the outer HEAD moves (`519e757` → `6212fcf`), as the text
  prescribes; the HEAD-unchanged condition belongs to A4 (H). The commit
  takes the Phase 6 subject, `docs: initialize project documentation`,
  which in someone else's repository reads as if the whole project was
  initialized; the text gives no subject for a new app.
- **O19** — A4 (S): both `CLAUDE.md` templates have a slot for rules
  specific to Claude Code that the user gave, but no interview round or
  new-app question asks for such rules, so the slot is filled only when
  the user volunteers one. The text does not say whether the new-app
  interview is one message or several; the acceptor asked its four items
  in one.
- **O20** — A5: after the import, `AGENTS.md` and the existing `CLAUDE.md`
  total 110 lines in A5 (S), and the check still passes, since beside a
  `CLAUDE.md` that was already there the 80-line budget counts `AGENTS.md`
  alone; the overage shows only in the reported count, with five
  duplications. In A5 (H) `AGENTS.md` copies the seven commands and five
  rules of `CLAUDE.md` and fills the branch and commit lines from its Git
  section — the final message says so ("commands and rules pulled from
  your existing CLAUDE.md") — and the duplication report comes only on the
  import question's yes path. C14: as designed — C10 limits the 80-line
  budget to a pair the run created, and 2.12 asks for the combined count
  and the duplication to be reported for the user to sort out; for Known
  behavior.
- **O21** — A5 (S): the skill reads commands only from configuration files
  (a command no file shows is `TBD(init):`). The existing `CLAUDE.md` lists
  five npm commands, but with no `package.json` `AGENTS.md`'s Commands is
  `TBD(init):`, so `AGENTS.md` says "unknown" while the `CLAUDE.md` that
  imports it lists them; the report named the inconsistency.
- **O22** — A5 (S): the Documents row for `CLAUDE.md` in `AGENTS.md.tmpl`
  is fixed text ("The import of this file, and rules specific to Claude
  Code"; changes when "A rule specific to Claude Code is added or
  removed"), which misdescribes an existing 60-line `CLAUDE.md` of general
  project rules. The template has no variant row for that case.
- **O23** — A5 (S): the scan's findings from `CLAUDE.md` were shown as
  pre-filled answers to confirm. The environments stayed `TBD(init):`
  although `CLAUDE.md` mentions production, since environments are a
  policy item; the branch and commit conventions were taken from
  `CLAUDE.md`, as the repository's written convention. Filling
  `docs/architecture/overview.md` from `CLAUDE.md`'s Architecture notes
  copies that content into a second file, which the duplication report,
  scoped to `AGENTS.md` and `CLAUDE.md`, does not cover.
- **O24** — A5 (H): `docs/product.md` line 5 reads "…exports monthly
  statements, replacing TBD(init): what was used before this system." — a
  slot the template does not have.
- **O25** — A6: a bare `/kenspc-init` gives the skill no evidence of the
  user's language; the acceptor used Chinese, as its brief said. A real run
  would have to guess, or open in English.
- **O26** — A6: the rerun offers a new scan's findings as suggested
  answers, but the text does not say whether init's own commit subject
  counts as evidence of the team's commit convention. The acceptor offered
  no suggestion for the Commits marker; a literal reading could propose
  Conventional Commits from the run's own output.
- **O27** — A6a: the file list's marks are "created, appended to, or given
  the import line", and § Exit adds "left as it was"; none fits a file
  whose markers a rerun replaced. The acceptor wrote "填了 2 个标记".
- **O28** — A6c: at group 2 the user said to skip groups 3–7 as well, and
  they were not sent, carrying over the interview's rule that a wish to
  stop answering skips the rounds not yet asked; the file list was still
  asked. § Rerun asks "in the interview's manner" and does not state the
  carry-over itself.
- **O29** — A6c: the skill says what replaces a marker but not whether a
  path gets the backticks the other paths in `AGENTS.md` carry; the answer
  was written verbatim, `package.json`, without them. A rerun does not
  check that an answered file exists (no `package.json` exists in the
  seed). `docs/release.md` line 9, the version location, asks for the same
  fact and stays `TBD(init):`, so the two documents are out of step until
  the next rerun; the acceptor mentioned it in the file list, which no rule
  requires.
- **O30** — A6: the rerun's scope, `AGENTS.md` and its Documents table,
  leaves out `docs/backlog/README.md`, which init writes but the table does
  not list. Its template has no slot, so this has no effect today.
- **O31** — A6a: the acceptor's first question told the user 35 markers,
  11 of them in `docs/ui/design-system.md`; the real counts are 34 and 10.
  It corrected them in the sixth group's message. A tester error, not the
  skill's.
- **O32** — A8: one `cd` into the plugin's templates directory; the harness
  reset the shell's cwd to the seed ("Shell cwd was reset to …/a8"), so the
  later git commands ran in the seed.
- **O33** — A9: a single app at the root holding only `.git` is offered
  scaffolding even when the stack is unknown (round 2 skipped). The text
  says to offer the generator the stack's official documentation names,
  and has no line for a run with no stack; the acceptor asked whether to
  scaffold and with which stack and generator.
- **O34** — A9: the skill's manual steps are "create the repository on
  GitHub, then `git remote add origin <url>`, and push when ready"; the
  acceptor added "keep it empty (no README, .gitignore, or license)" and
  suggested the project's name as the repository name. In A3 (S) and A5 (S)
  the GitHub question said up front that `gh` is missing, in A9 it did not;
  the text leaves either open.
- **O35** — A11: `AGENTS.md` reached the session through `CLAUDE.md`'s
  import — the `instructions` attachment lists both files and holds
  `AGENTS.md`'s Workflow line — with no Read of it. The template's HTML
  comment (the marker and the admission rule) is not in the loaded text,
  which the acceptor reads as Claude Code stripping HTML comments from
  memory files, so the comment costs no context. In A5 (H), where `CLAUDE.md` has no import, the
  attachment holds `CLAUDE.md` only.
- **O36** — A11: two probes ($0.0747 each, copies of the seed) asked whether
  `AGENTS.md` was in context; their prompt contained the literal
  `@AGENTS.md`, which Claude Code turned into a file attachment, so their
  answers are void and were discarded. The `instructions` attachments of
  O35 are the evidence used. The copies are under
  `~/Projects/_smoke/batch-g/.trash/`.
- **O37** — The two S acceptors running at the same time shared a
  scratchpad: `acceptor-s-mono` overwrote or appended to
  `acceptor-s-starts`' check script and transcript mid-run. The latter
  moved its own to new names, re-created the script, and re-verified A3 and
  A4 (all checks pass); the seeds and results were not affected. One
  temporary file from A5 (S)'s import sits in
  `~/Projects/_smoke/batch-g/.trash/`.

## 5. Not exercised

From the cases:

- A2's `apps/api/src/`: the container has no `dotnet`, so `api` was not
  scaffolded; the missing-tool path — stop, explain, install nothing — was
  exercised instead (§ 2.2; C3, C14).
- A10's nested `.git` moved to `.trash/`, with `.trash/` in `.gitignore`:
  create-vite does not run `git init`, so there was no nested `.git`
  (§ 2.10; C14).
- A10's merge into a `.gitignore` that already exists: `apps/web/` was new
  and the root had no `.gitignore` when the generator ran; the "not
  overwritten" half held.
- A6a's version-line marker: the user answered two whole-line markers
  only. A6c exercised the C11 span through the skill and passed.
- A marker in the middle of a line: `docs/ui/design-system.md` line 3,
  whose marker ends a sentence, was answered in no rerun.
- Several generators in one run: only `web` was scaffolded, so whether the
  README question comes after each generator or once after the last was
  not exercised.

Not reached by these cases:

- The paths that need `gh` installed and logged in: the owner and name
  question, creating the repository and setting the remote, reading the
  existing labels and creating `debt` and `found-by-agent`. A9 took the
  manual-steps path and A7 listed the labels in its final message.
- Phase 7 in a session that can ask: no S case had a remote, so the push
  and labels questions were never asked.
- The description's natural-language triggers: every H run invoked
  `/kenspc-init` or `/kenspc-plan` directly; A12 checks the description on
  the text only.
- A session that loaded the skill and asked a person: the interactive half
  of every case was S mode, the text followed by a subagent.

Other reasons: macOS and Windows were not run — one Linux container only.

## 6. Summary

Repository tree `aee4311`; one Linux cloud container, 2026-09-27.

| Case | Mode | Seed, cost | Result |
|---|---|---|---|
| A1: empty directory, no git, cannot ask | H | `a1`, $0.71; re-run `a1-clean`, $0.49 | **PASS**, both runs |
| A2: empty directory, interactive, monorepo | S | `a2` | **PASS**; `apps/api/src/` Not exercised (no `dotnet`; the missing-tool stop held) |
| A3: files, not a git repository | S; H | `a3-s`; `a3-h`, $0.18 | **PASS**; **PASS** |
| A4: inside another repository | S; H | `a4-s`; `a4-h`, $0.18 | **PASS**; **PASS** |
| A5: existing repository, a 60-line `CLAUDE.md` and a README | S; H | `a5-s`; `a5-h`, $0.66 | **PASS**; **PASS** |
| A6: rerun — two markers answered; no marker left | S | `a6a`; `a6b` | **PASS** (only the two marker lines changed); **PASS** (zero changes, and said why); A6a's version line Not exercised |
| A6c (the main session's, for C11): the version-line marker alone | S | `a6c` | **PASS** |
| A7: GitHub remote, cannot ask | H | `a7`, $0.66 | **PASS** |
| A8: non-GitHub remote, cannot ask | H | `a8`, $0.66 | **PASS** |
| A9: no remote, `gh` absent, interactive | S | `a9` | **PASS** |
| A10 (optional): generator conflict | S | `a2`'s `web` | **PASS** on the README and the `.gitignore`; the nested `.git` and the merge into an existing `.gitignore` Not exercised |
| A11 (optional): `/kenspc-plan` on A1's result | H | `a11`, $0.38 | **PASS** |
| A12: static checks and the pre-flight | — | the repository | **PASS** (no `MUST`, `NEVER`, or `CRITICAL`; 19 of 19 cannot-ask sentences; both languages; `guards run: 10`, `self-tests run: 9`) |

Cost: the headless sessions USD 4.08 — the eight runs USD 3.93 and the two
discarded probes USD 0.15. S mode started no session. The acceptors and
the main session are not included.

Every case PASS and no FAIL: twelve cases, sixteen case runs (A3, A4, and
A5 in both modes, A6 as two sub-cases), seven in H mode, eight in S mode
(A10 within A2's run), and A12 static; plus the main session's A6c, also PASS. Not exercised
within them: A2's `apps/api/src/`, A10's nested `.git` and its merge into
an existing `.gitignore`, and A6a's version line, which A6c covers. No
finding. Thirty-seven observations, six of them classified in C14: three
behavior deviations (O2, O4, O13), two as designed and for Known behavior
(O15, O20), and one environment issue (O1). No plugin file was changed by
any acceptor, and no case was re-run for a fix. The smoke projects are kept
under `~/Projects/_smoke/batch-g/`.
