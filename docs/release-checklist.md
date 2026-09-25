# Release Checklist

Manual verification steps that run before tagging any release. The
pre-flight checks below verify content; the smoke checklist verifies that
the plugin actually loads and that each entry-point reaches its first
interactive surface.

## Pre-flight: mechanical checks

Run from the repository root:

```bash
(
set -e

# Effort overrides — exactly these three files declare effort:, each xhigh;
# every other skill and agent follows the session (diff exits 1 on any drift)
diff <(grep -H '^effort:' plugins/kenspc/skills/*/SKILL.md plugins/kenspc/agents/*.md) - <<'EOF'
plugins/kenspc/skills/generate-plan/SKILL.md:effort: xhigh
plugins/kenspc/agents/code-fixer.md:effort: xhigh
plugins/kenspc/agents/task-implementer.md:effort: xhigh
EOF

# The plugin loader's own validation: the marketplace manifest (repo root),
# then the plugin manifest, skills, agents, and commands; --strict fails on
# warnings too
claude plugin validate --strict .
claude plugin validate --strict ./plugins/kenspc

# Every guard in main mode (JSON validity included, via check-json.sh), then
# every guard's mutation regression fixture. Expect "guards run: 10" after the
# main pass and "self-tests run: 9" as the last line.
bash scripts/check-all.sh --self-test
)
```

All four must pass: 1 effort-override diff + 2 `claude plugin validate
--strict` runs + 1 `check-all.sh --self-test` run = 4. The block runs in a
`( set -e … )` subshell, so pasted whole it stops at the first failure and
returns that command's exit code — without closing an interactive shell,
which a bare `set -e` would do. The `check-all.sh` run
covers every guard in main mode, JSON validity included via `check-json.sh`,
and then every self-test fixture. Its output must include `guards run: 10`
and end with `self-tests run: 9`; a different number means a guard or
fixture was added, removed, or no longer detected — find out which before
continuing. If anything fails, fix it before proceeding to the smoke
checklist.

## Docs currency (manual)

CLAUDE.md (§ Subagent Review Architecture) records why three files
override the session's effort at `xhigh` (`task-implementer`,
`code-fixer`, `generate-plan`) and carries a "last reviewed" date against
Anthropic's effort guidance. Confirm each override's rationale still holds
for the current Claude generation — drop an override whose reason no longer
applies rather than re-pinning a value — and update that date (also in
`plugin.json` and the README Effort levels section) before tagging.

## Smoke checklist (manual, ~10 minutes)

The plugin can pass every grep-based AC and still fail to load if a YAML
frontmatter break or file path typo slipped through. This checklist
exercises the actual load + first-prompt surface of every user-facing
entry point.

In a throwaway directory or a freshly cloned worktree:

```bash
claude --plugin-dir ./plugins/kenspc
```

For a headless run on Windows (`claude -p "/kenspc-task-review"`), start it
from PowerShell, or set `MSYS_NO_PATHCONV=1` in Git Bash. Otherwise MSYS
rewrites the leading `/kenspc-task-review` into a Windows path before Claude
Code sees it.

Inside the session:

| # | Check | Pass criterion |
|---|---|---|
| 1 | `/help` | Lists all 8 kenspc slash commands without error |
| 2 | `/reload-plugins` | Reload completes; no YAML/JSON parse errors in console |
| 3 | `/kenspc-brief` | Discovery starts; first user-facing prompt is a question (not a draft); when the discussion leaves a question it cannot settle, the brief's `## Open Questions` lists it with `` `open` `` or `` `needs prototype` ``, each `needs prototype` entry with `Settled by:`; otherwise the section's body is `none`; the next-step suggestion names `/kenspc-prototype` when an entry needs one |
| 4 | `/kenspc-plan` | Phase 1 begins; after the plan is written, a `plan-document-reviewer` Agent call appears, followed by the Schema E result table; the plan contains a `## Documentation impact` section (a list or `N/A — <reason>`); on a brief with a `` `needs prototype` `` entry, the first question Phase 1 asks is prototype-first or carry, before any gap-check question; "prototype first" ends the run with the `/kenspc-prototype` line and no file; "carry" puts the entry in the draft's Open Questions with `From:`, `Not prototyped:`, and `Assumed in:`; an `open` entry the gap rounds do not settle appears there with `From:` and `Assumed in:`; in a session that cannot ask, no question is asked, `Not prototyped:` reads "the session could not ask", and every `open` entry is carried without a gap round; a brief with no `## Open Questions` section gets no such question |
| 5 | `/kenspc-task <plan-path>` | Decomposition runs; a `task-document-reviewer` Agent call appears, followed by the Schema E result table; when the plan's element names documents, the task document's last task is `### Task N: Doc-sync` with `Depends on: Task 1-<N-1>`; the Schema E table has three rows |
| 6 | `/kenspc-task-implement <task-path>` | Phase 2 review dispatches even when implementation is all-DONE: five reviewer Agent calls appear, then Schema A → B → C → G; run-directory check passes (see below); Schema G contains `## Decisions needing a home`, and Next steps has one bullet per entry in it; a run with one task forced BLOCKED shows the Doc-sync task BLOCKED with `depends on Task N (BLOCKED)`, a Next steps bullet stating the listed documents were not synced, and verdict PARTIAL; when a Doc-sync task is DONE and code-fixer's statistics line reports FIXED greater than 0, Next steps has one bullet naming the listed documents to re-check against the fix commits |
| 7 | `/kenspc-task-review` | Five reviewer Agent calls appear, then the Schema A roll-up, B, C, and the Schema F final report; never logs "Code looks correct, skipping review"; run-directory check passes (see below); with no task document, the change-set check passes (see below) |
| 8 | `/kenspc-guide <project-path>` | Guide runs; a `guide-document-reviewer` Agent call appears, followed by the Schema E result table |
| 9 | `/kenspc-diagnose <observed bug>` | The trace shows the reproduction test written, run, and failing, then committed (`test: reproduce …`), before the task document is written; `docs/tasks/<name>.md` is committed (`docs: add task …`) and holds `## Diagnosis` with the nine labels in order (`**Symptom:**`, `**Reproduction:**`, `**Root cause:**`, `**Hypotheses:**`, `**Fix scope:**`, `**Adjacent cases:**`, `**Tier:**`, `**Documentation impact:**`, `**Probes:**`), `### Task 1` with `**Status:** TODO`, `### Task 2: Regression tests …` exactly when `**Adjacent cases:**` lists cases and a failing-capable test can be written (the field reads `none — <reason>` when there are none, and says why no test task follows when the reproduction is manual), and `### Task N: Doc-sync` when its Documentation impact lists documents; `/kenspc-task-implement <path>` passes its Step 1 validation on it, and `grep -nE -e '^#+ .*Phase [0-9N]' -e '^#+ .*Step [0-9N]' docs/tasks/<name>.md` prints nothing (that validation accepts a document with such a heading, and task-implementer then stops on it as ambiguous); the exit asks whether to run `/kenspc-task-implement` now or implement interactively; a run in a project with no test framework, or on a bug that needs a real device, makes no `test: reproduce` commit, its `**Reproduction:**` gives the manual steps as a numbered list with the reason no failing-capable test exists, Task 1's criteria say the steps are verified by the user after the run and recorded by the implementer as not verified, and the exit message says Task 1 cannot be verified unattended; a run on a bug whose fix changes a function's signature writes `docs/briefs/<name>.md` starting `# Requirement Brief:` and no task document; when the diagnosis probed, its files are under `.kenspc/runs/<time>-diagnose-<name>/scratch/orchestrator/<n>/` and the run-directory check's `find` probe (sub-check 1) over that `scratch/` prints nothing; when the diagnosis probed in a project that did not yet ignore `.kenspc/`, the one commit besides the two above is the one-time `.gitignore` commit, and it passes; a bug report the project cannot reproduce ends in a question, with no task document or brief, no commit besides that one-time `.gitignore` commit, and no untracked test file left by the skill — or, when the removal was denied, that file named in the question; a request to explain a stack trace invokes no skill |
| 10 | `/kenspc-prototype <brief path>` | The trace shows the frame, then the prototype written under `prototypes/<slug>/` (or the CLAUDE.md location), run, and committed alone (`chore: add prototype …`; `git show --name-only <hash>` lists only the prototype's paths, none matching the run-directory check's sub-check 1 `find` patterns and none a `.env*` or `appsettings*.json` file, and `git show <hash>` holds no connection string or key from the project's configuration files); the brief entry rewritten `` `answered` `` with `Answer:`, `Evidence:`, and `Prototype:` naming that commit; then `chore: remove prototype …` with `Question:`, `Answer:`, and `Prototype:` in its body; `git diff <HEAD before the run> HEAD` prints nothing; the brief is not committed; the final message lists every path `git status --porcelain --ignored -uall -- <location>` still shows; the exit suggests `/kenspc-plan <brief>` when no `needs prototype` entry remains, otherwise `/kenspc-prototype <brief> <n>` for the next, and invokes nothing; a question given with no brief ends with the `/kenspc-brief` suggestion and no commit; a development-database run that creates a table shows the warning before any code and leaves no such table after the run; a run that writes rows to an existing development table shows no warning and names that table in `Evidence:`; a connection named only by a production file is never used; an in-app UI run with a CLAUDE.md location shows the typecheck baseline before building and green before the add commit, and the remove commit restores every tracked file the add commit modified; a feature question that needs the app's runtime either runs from the location with no tracked app file in the add commit, or builds nothing and makes no commit, leaving the entry `` `needs prototype` `` with the reason; "直接把这个功能做出来" and "帮我跑一下这段代码" invoke no prototype skill |
| 11 | End-to-end trace verification on greenfield project (non-DungeonDescent) | All three sub-criteria hold (see row-11 detail below) |

Run-directory check for rows 6 and 7 (v3.5.1):

- Headless run (`claude -p`): every Agent call runs in the foreground — the
  five reviewer calls go out in one message, no background-task notice
  appears, and code-fixer and regression-verifier follow in the same turn.
  Interactive (TUI) run: no user input is needed between the invocation and
  the Schema F / G report. Foreground dispatch cannot be observed there:
  the interactive Agent tool (Claude Code 2.1.281) has no `run_in_background`
  parameter and runs subagents asynchronously, handing each result back.
- The final report's Fixes section prints the full path of `schema-b.md`.
- That directory holds `angle-1.md` through `angle-5.md` and `schema-b.md`.
  Every probe, copy of a project file, mutant, and runner config is under
  its `scratch/` subdirectory — the reviewers' in `scratch/angle-<n>/`,
  code-fixer's in `scratch/code-fixer/`, regression-verifier's in
  `scratch/regression-verifier/`, and the orchestrating session's in
  `scratch/orchestrator/` when it probed; nothing of that kind was created
  or deleted outside the run directory (such as in `/tmp`). Logs, listings,
  and helper scripts that an agent writes for its own verification may sit
  in Claude Code's per-session scratchpad (on macOS
  `/private/tmp/claude-501/<project>/<session-id>/scratchpad/`): the harness
  tells every subagent to use it instead of `/tmp`, it is session-scoped and
  prompt-free, and agents have put their logs there in both acceptance runs
  so far — task-implementer and code-fixer in batch A, code-fixer and
  regression-verifier in the scratch-probes run
  (`docs/dry-runs/scratch-probes-acceptance.md` § 6). List that directory
  after the run: a source file, a runner config, or a copy of a project file
  there fails this bullet — batch A's task-implementer kept `.bak` copies of
  `src/*.ts` there while it mutated the project's own files in place, which
  this bullet would have caught; a log or a shell script that only runs the
  project's own commands does not fail it. Sub-check 1 below fails on any vitest or jest default test name
  the agents wrote, whether or not a runner collects it, but only where the
  agents had tests to probe; other runners' names, such as pytest
  `test_*.py` or Go `_test.go`, pass it unseen.
  Sub-check 2 fails only where a test runner collects such files under
  `.kenspc/`. A clone of this Markdown-only repository gives the agents no
  tests to probe and has no test command to break, so neither sub-check
  can fail there. So for them, run row 6 or 7 in a TypeScript project with
  vitest and at least one test of its own, whose vitest config sets only a
  setup file or `globals` and keeps the default include, with `--plugin-dir`
  pointing at this repository's `plugins/kenspc`. The default include
  reaches into `.kenspc/`; the setup file or `globals` is what a scratch
  runner config that drops the project's config fails on, so a mutation
  check's baseline (sub-check 6) has something to prove. Then:
  1. With `<RUN_DIR>` the run's directory, `<RUN_DIR>/scratch` exists, and
     `find <RUN_DIR>/scratch \( -name '*.test.*' -o -name '*.spec.*' -o -name 'test.*' -o -name 'spec.*' -o -path '*/__tests__/*' -o -path '*/__mocks__/*' \)`
     prints nothing. `find` reports a missing path on stderr only, so empty
     output from a missing directory proves nothing: with no `scratch/`, no
     agent probed, and this sub-check was not exercised.
  2. After the run, the project's own test command passes unmodified from
     the repository root.
  3. No agent changed the project's test-runner config, linter config,
     ignore files, `tsconfig`, or package scripts: `git status --short` lists
     no such file, and no fix commit touches one. A narrowed `test` script in
     `package.json` would also turn sub-check 2 green. The one-time
     `.gitignore` commit below is the orchestrating skill's, made before
     dispatch, and does not count.
  4. regression-verifier ran each build, test, and lint command the project
     defines as the project configures it, with no path filter or exclude
     added: its Bash calls in the run's trace show the project's own
     commands (such as `npm test`), and any narrowed re-run comes after the
     unmodified one. After the test run, the trace also shows it listing
     the files the runner collects (such as `vitest list --filesOnly`) to
     compare them against `.kenspc/`. Read the trace, not Schema C: a clean
     PASS row's Detail is `—`, so the table cannot show which command ran or
     that the comparison was made.
  5. Nothing under `<RUN_DIR>` was deleted: the run's trace shows no `rm`
     or other delete of a path there, and an agent or the orchestrating
     session that started over did so in a new subdirectory of its own
     scratch directory (such as `scratch/angle-5/2/`). A rename within the
     agent's own scratch directory (`mv probe.test.ts probe.probe.ts`),
     which is how the agents fix a collectable name, is not a delete; a
     move onto a path that already exists, or out of the run directory, is.
  6. If any agent ran a mutation check — a mutant copy of the test tree
     exists under `<RUN_DIR>/scratch` — the run's trace shows, for that
     attempt, the unmutated baseline running first and passing under a
     runner config rooted at the attempt's numbered directory (vitest
     `root`, jest `rootDir`, such as `scratch/angle-5/1/`), and a
     deliberately broken control mutant failing before any mutant was
     counted as a survivor. A baseline that could not pass shows up in the
     agent's report as a mutation check not made, never as surviving
     mutants. With no mutant copy under `scratch/`, no agent ran a mutation
     check, and this sub-check was not exercised.
- From this repository, `bash scripts/check-run-contract.sh --file <that
  path>` exits 0 — the real Schema B's Per-angle Results table and
  statistics line agree with its rows.
- In a project whose `.gitignore` does not yet cover `.kenspc/` — including
  a CRLF `.gitignore` with blank lines — the run adds exactly one commit
  before dispatch, touching only `.gitignore`, and the appended line keeps
  the file's line endings; a second run adds none.

Change-set check for row 7, a run with no task document (v3.7.0):

- `RUN_DIR/change-set.md` exists and has a `Mode:` line, and every
  `File:Line` path in the Issues tables of `angle-1.md` … `angle-5.md` lies
  within its `Status | Path` table, or names a document the finding says
  the change left stale (a README the change did not update); the reports
  carry no separate file list, and any other path outside the set is a
  reviewer that derived its own scope.
- Between the invocation and the first reviewer dispatch, the trace shows no
  `git commit`, `stash`, `checkout`, `add`, or `reset` by the orchestrator
  other than the one-time `.gitignore` commit.
- On a dirty tree (`Mode: uncommitted`): HEAD is unchanged after the run
  except for that commit, `git stash list` is unchanged, every FIXED row's
  Commit in `schema-b.md` is `—`, and Next steps has the bullet naming the
  uncommitted fixes' files. With FIXED greater than 0,
  `<RUN_DIR>/scratch/code-fixer/pre-fix/index.txt` exists and names every
  file a FIXED row names, each `copied` path has its `.txt` copy beside it
  (a `.test.` or `.spec.` segment renamed `.probe.`, so sub-check 1's
  `find` probe stays clean),
  and the trace shows regression-verifier diffing those copies against the
  working files (`git diff --no-index`) instead of looking for fix commits;
  Schema C row 5 is not a FAIL that cites missing fix commits.
- On a clean tree ahead of its upstream (`Mode: commits`): `Range:` is
  `<merge base>..<HEAD>` — the upstream itself unless the branch has
  diverged from it, and on a diverged branch the table lists only files
  this branch's own commits touched — and the fix commits appear as before,
  one per FIXED row. On a clean tree with no upstream, `Range:` is `<HEAD~1>..<HEAD>`, or
  `<empty tree>..<HEAD> (root commit)` when HEAD is the repository's only
  commit.
- In a project that does not yet ignore `.kenspc/`, on a clean tree: the
  right end of `Range:` is the HEAD recorded before the invocation, not the
  one-time `.gitignore` commit, and `.gitignore` is absent from the
  `Status | Path` table. A set computed after the run-directory preparation
  would review only that commit.
- In a `git init` repository with files and no commit yet:
  `change-set.md` says `Mode: uncommitted` and
  `Base: <empty tree> (no commit yet)`, the empty tree being `4b825dc…` in a
  SHA-1 repository, and the run reaches the Schema F report.
- Custom instructions: a run whose instructions name a range writes
  `Mode: commits` with that range in `Range:`, marked as chosen by
  CUSTOM_INSTRUCTIONS, on a dirty tree too; a run whose instructions name a
  path keeps the default mode and lists only the changed files under that
  path.

Row 11 sub-criteria (each is independently mechanically auditable against
the captured trace):

- Phase 2 auto-triggers without a user prompt: grep the trace for
  `Proceeding to Phase 2` or `Proceeding to code review` and confirm it
  appears immediately after Phase 1 Step 5 (not after a user reply).
- No workflow-closure wording appears in the trace before Phase 2
  dispatch. This checklist is the canonical home of the closure-phrase
  list (moved out of the `task-implement` SKILL prompt in v3.4.2 —
  enumerating forbidden phrasings in a prompt primes the model toward
  them; the prompt now states the positive template phrasings only).
  Grep the pre-Phase-2 trace window for each of: `整段落地`, `整段交付`,
  `所有工作完成`, `workflow 收口`, `session 结束` (Chinese), and
  `Workflow complete.`, `All phases done.`,
  `All implementation is done.`, `Ready to wrap up.`, `milestone landed`
  (English). Each must return zero hits. Also scan that window manually
  for pattern-shaped equivalents a fixed grep cannot pin down
  (`Step N of M 完成`, `✓ ... 落地`).
- `Discovery Mode:` field present in the brief output, with a value in
  {`full`, `rapid-direct`, `rapid-inferred (reminder-driven)`}.

If any step fails, do not tag the release. File the failure as a bug,
fix, re-run the pre-flight + this checklist.

## Post-release

```bash
git tag -a v<version> -m "kenspc v<version>"
git push origin main --tags
```

## Rationale

This checklist exists because mechanical pre-flight checks can pass while
the plugin fails to load — for example, a missing colon in YAML
frontmatter parses cleanly as text but breaks Claude Code's plugin
loader. The smoke checklist is the cheapest gap-closer: it exercises the
actual load + first-prompt surface that no grep can verify.
