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
| 1 | `/help` | Lists all 6 kenspc slash commands without error |
| 2 | `/reload-plugins` | Reload completes; no YAML/JSON parse errors in console |
| 3 | `/kenspc-brief` | Discovery starts; first user-facing prompt is a question (not a draft) |
| 4 | `/kenspc-plan` | Phase 1 begins; after the plan is written, a `plan-document-reviewer` Agent call appears, followed by the Schema E result table; the plan contains a `## Documentation impact` section (a list or `N/A — <reason>`) |
| 5 | `/kenspc-task <plan-path>` | Decomposition runs; a `task-document-reviewer` Agent call appears, followed by the Schema E result table; when the plan's element names documents, the task document's last task is `### Task N: Doc-sync` with `Depends on: Task 1-<N-1>`; the Schema E table has three rows |
| 6 | `/kenspc-task-implement <task-path>` | Phase 2 review dispatches even when implementation is all-DONE: five reviewer Agent calls appear, then Schema A → B → C → G; run-directory check passes (see below); Schema G contains `## Decisions needing a home`, and Next steps has one bullet per entry in it; a run with one task forced BLOCKED shows the Doc-sync task BLOCKED with `depends on Task N (BLOCKED)`, a Next steps bullet stating the listed documents were not synced, and verdict PARTIAL; when a Doc-sync task is DONE and code-fixer's statistics line reports FIXED greater than 0, Next steps has one bullet naming the listed documents to re-check against the fix commits |
| 7 | `/kenspc-task-review` | Five reviewer Agent calls appear, then the Schema A roll-up, B, C, and the Schema F final report; never logs "Code looks correct, skipping review"; run-directory check passes (see below) |
| 8 | `/kenspc-guide <project-path>` | Guide runs; a `guide-document-reviewer` Agent call appears, followed by the Schema E result table |
| 9 | End-to-end trace verification on greenfield project (non-DungeonDescent) | All three sub-criteria hold (see row-9 detail below) |

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
  Any probe or temporary files are under its `scratch/` subdirectory — the
  reviewers' in `scratch/angle-<n>/`, code-fixer's in `scratch/code-fixer/`,
  regression-verifier's in `scratch/regression-verifier/`, and the
  orchestrating session's in `scratch/orchestrator/` when it probed; nothing
  outside the run directory (such as `/tmp`) was created or deleted for
  probing. Sub-checks 1 and 2 below can fail only where a test runner
  collects stray test files under `.kenspc/`, and a clone of this
  Markdown-only repository has no test command to break. So for them, run
  row 6 or 7 in a TypeScript project with vitest, no vitest config, and at
  least one test of its own (vitest's default include reaches into
  `.kenspc/`), with `--plugin-dir` pointing at this repository's
  `plugins/kenspc`. Then:
  1. With `<RUN_DIR>` the run's directory, `<RUN_DIR>/scratch` exists, and
     `find <RUN_DIR>/scratch \( -name '*.test.*' -o -name '*.spec.*' -o -name 'test.*' -o -name 'spec.*' -o -path '*/__tests__/*' \)`
     prints nothing. `find` reports a missing path on stderr only, so empty
     output from a missing directory proves nothing: with no `scratch/`, no
     agent probed, and this sub-check was not exercised.
  2. After the run, the project's own test command passes unmodified from
     the repository root.
  3. No agent changed the project's test-runner config, ignore files,
     `tsconfig`, or package scripts: `git status --short` lists no such
     file, and no fix commit touches one. A narrowed `test` script in
     `package.json` would also turn sub-check 2 green. The one-time
     `.gitignore` commit below is the orchestrating skill's, made before
     dispatch, and does not count.
  4. regression-verifier ran each build, test, and lint command the project
     defines as the project configures it, with no path filter or exclude
     added: its Bash calls in the run's trace show the project's own
     commands (such as `npm test`), and any narrowed re-run comes after the
     unmodified one. Read the trace, not Schema C: a clean PASS row's Detail
     is `—`, so the table cannot show which command ran.
  5. Nothing under `<RUN_DIR>` was deleted: the run's trace shows no `rm`
     or other delete of a path there, and an agent or the orchestrating
     session that started over did so in a new subdirectory of its own
     scratch directory (such as `scratch/angle-5/2/`).
- From this repository, `bash scripts/check-run-contract.sh --file <that
  path>` exits 0 — the real Schema B's Per-angle Results table and
  statistics line agree with its rows.
- In a project whose `.gitignore` does not yet cover `.kenspc/` — including
  a CRLF `.gitignore` with blank lines — the run adds exactly one commit
  before dispatch, touching only `.gitignore`, and the appended line keeps
  the file's line endings; a second run adds none.

Row 9 sub-criteria (each is independently mechanically auditable against
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
