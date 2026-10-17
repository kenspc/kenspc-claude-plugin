# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin marketplace containing structured software development workflow plugins. The primary plugin (`kenspc`) provides skills for project initialization, plan-before-code workflows, requirement brief generation, answering a brief's open questions with throwaway prototypes, plan-to-task decomposition, bug diagnosis, task implementation with automatic code review, and project guide generation. The plugin also runs one batch of its own chain unattended (the autopilot skill), from a spec or a brief to a local release preparation, through headless sessions rather than agents. Review phases use plugin agents (defined in `agents/`) — serial review agents for plan/guide/task documents, parallel MapReduce review agents for code. The brief, diagnose-bug, prototype, and init-project skills have no review phase (the brief is a discovery artifact, not a verifiable spec; a diagnosis has no plan to review its task document against, so the user confirms the task list instead; a prototype is discarded, and its answer is reviewed where a plan uses it; init-project's files hold the user's answers and `TBD(init):` markers, so its own mechanical checks and the user's confirmation of the file list are its gate).

## Marketplace Structure

- Root `.claude-plugin/marketplace.json` — plugin registry pointing to plugin directories
- Each plugin lives in `plugins/<name>/` with its own `.claude-plugin/plugin.json`, `README.md`, `LICENSE`, and component directories (`agents/`, `skills/`, `commands/`, `hooks/`, `references/`, `shared/`)
- The `description` field of each entry in `.claude-plugin/marketplace.json`'s `plugins` list is the registry-list summary (one short sentence). The `description` field in `plugins/<name>/.claude-plugin/plugin.json` is the full plugin metadata loaded after the user selects the plugin. The two are deliberately layered — the marketplace summary is typically the first sentence of the full description. Do not sync them blindly. The marketplace manifest also has its own top-level `description`, describing the marketplace as a whole (added in v3.5.1; `claude plugin validate --strict` warns without it).

### Plugin Directory Layout

```
plugins/kenspc/
├── .claude-plugin/plugin.json   # Plugin metadata (name, version, author)
├── agents/                      # 11 reusable subagents (5 code reviewers + 3 doc reviewers + 3 workers)
├── commands/                    # Slash commands
│   ├── kenspc-init.md
│   ├── kenspc-brief.md
│   ├── kenspc-plan.md
│   ├── kenspc-task.md
│   ├── kenspc-guide.md
│   ├── kenspc-diagnose.md
│   ├── kenspc-prototype.md
│   ├── kenspc-task-implement.md
│   ├── kenspc-task-review.md
│   └── kenspc-autopilot.md
├── hooks/
│   ├── hooks.json               # Hook event configuration
│   └── scripts/                 # Hook scripts (use ${CLAUDE_PLUGIN_ROOT})
├── references/                  # Example documents for user onboarding
├── shared/                      # Cross-skill resources (referenced via ${CLAUDE_PLUGIN_ROOT}/shared/)
│   ├── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan
│   ├── code-craft-principles.md # Code-craft principles shared by task-implementer, code-fixer, quality-reviewer
│   └── instruction-files.md     # The definition of "the project's instruction files", copied into every file that uses the term
├── skills/
│   ├── init-project/
│   │   ├── SKILL.md             # No review phase — its mechanical checks and the user's confirmation of the file list are the gate
│   │   └── templates/           # The files it writes, as *.tmpl (never named CLAUDE.md or AGENTS.md); check-no-model-names.sh scans them
│   ├── generate-brief/
│   │   └── SKILL.md             # No review phase — brief is a discovery artifact
│   ├── generate-plan/
│   │   └── SKILL.md
│   ├── generate-task/
│   │   └── SKILL.md
│   ├── generate-guide/
│   │   └── SKILL.md
│   ├── diagnose-bug/
│   │   └── SKILL.md             # No review phase — the user confirms the task list
│   ├── prototype/
│   │   └── SKILL.md             # No review phase — the prototype is discarded; the plan that uses its answer is reviewed
│   ├── task-implement/
│   │   └── SKILL.md
│   ├── task-review/
│   │   └── SKILL.md
│   └── autopilot/
│       ├── SKILL.md
│       └── scripts/
│           ├── run.sh           # Bash driver for the autopilot's headless sessions; the first scripts/ under a skill, and check-no-model-names.sh scans it
│           ├── run.ps1          # PowerShell mirror of run.sh (pwsh 7.3 or later), checked on macOS only — a parse and its --self-test; the skill copies and runs run.sh
│           ├── extract-acceptance.sh  # Writes each Acceptance: case of a spec's ## Autopilot section to <nn>.cmd or <nn>.case; copied per batch, run by the main session and S4
│           ├── zero-diff.sh     # The zero-diff check: git diff --stat over a paths file, one argument per path, with a compared: count; copied per batch
│           ├── temp-candidates.sh  # Read-only: snapshots the temp folder before a batch, and at its end lists the batch's own new entries with their evidence; copied per batch
│           └── suite-slots.sh   # The suite-slot wrapper: runs a listed suite only while fewer than N run on the machine, through a lock in /tmp/kenspc-suite-slots; copied per batch
├── README.md
└── LICENSE
```

## Skill Development Conventions

### File Structure

Each skill lives in `skills/<skill-name>/` with:
- `SKILL.md` — skill definition with YAML frontmatter (`name`, `description`, `version`, `argument-hint`) followed by structured phases/modes
- `scripts/` (optional) — executable scripts the skill ships and runs by path (`${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/scripts/<file>`); today only the autopilot's: its two drivers, `run.sh` and its PowerShell mirror `run.ps1`, and its four helper scripts, `extract-acceptance.sh` and `zero-diff.sh` (4.6.0), `temp-candidates.sh` (4.8.0), and `suite-slots.sh` (4.10.0), which `check-autopilot-scripts.sh` holds; `check-no-model-names.sh` scans all six with the rest of `skills/`
- `templates/` (optional) — files the skill reads by path and fills in (`${CLAUDE_PLUGIN_ROOT}/skills/<skill-name>/templates/<file>`); today only init-project's, one `.tmpl` file per document it writes. A template is never named `CLAUDE.md` or `AGENTS.md`, since a session working in this repository would load a `CLAUDE.md` as a memory file, and an `AGENTS.md` too wherever Claude Code reads AGENTS.md itself (its `claude-md-and-agents-md` mode), and `check-no-model-names.sh` scans templates with the rest of `skills/`

Each plugin agent lives in `agents/<agent-name>.md` with YAML frontmatter (`name`, `description`, `tools`, `model`) followed by the agent's static system prompt. SKILLs dispatch agents by name through the Agent tool, passing a structured CONTEXT block as the dispatch prompt; the one other dispatch is the read-only sweep of generate-task, generate-guide, and diagnose-bug (4.9.0), unnamed subagents given a free-text prompt that write nothing and return `file:line`.

Commands live in `commands/` as `.md` files with YAML frontmatter (`name`, `description`, `argument-hint`, `disable-model-invocation: true`). Commands are explicit entry points only: since Claude Code merged commands and skills, both descriptions load into context and compete for natural-language auto-routing — the skill's description owns the trigger phrases, so each command keeps a one-line description and opts out of model invocation (v3.4.2).

Hooks are defined in `hooks/hooks.json` with scripts in `hooks/scripts/`.
Three hooks are registered: `PreToolUse` on `Write` → `remind-plan-skill.sh`
(plan-skill reminder — note it fires on every Write call, not only
plugin-related ones; its task and brief messages name every skill that
writes those directories: generate-task or diagnose-bug for `docs/tasks/`,
generate-brief, diagnose-bug, or prototype (which records an answer in an
existing brief) for `docs/briefs/`); `PreToolUse` on
`Bash|Write|Edit|NotebookEdit` → `autopilot-worker-rails.sh` (the
autopilot worker rails, 4.3.0 — an environment constraint in the sense
of the Plugin Design Lessons, not a workflow guard); and `SessionEnd` →
`session-end-telemetry.sh`
(post-hoc telemetry; background in Plugin Design Lessons). The rails hook
starts on every matched call of every session with the plugin enabled and
is inert there — exit 0, no output, stdin unread — unless
`KENSPC_AUTOPILOT_WORKER` is exactly `1`, the marker the autopilot driver
(`run.sh`, `run.ps1`) exports to every worker with
`KENSPC_AUTOPILOT_WRITE_ROOTS` (the worker's repository, the workspace,
`$TMPDIR`, `/tmp`, `/private/tmp`, joined by `|` — no Windows path holds
it, while `:` is in every drive letter and `;` may be in a file name), and,
since 4.10.0, the batch's `Suite limit:` as `KENSPC_AUTOPILOT_SUITE_LIMIT`,
`KENSPC_AUTOPILOT_SUITE_COMMANDS` (the prefixes joined by `|`),
`KENSPC_AUTOPILOT_SUITE_WRAPPER` (the wrapper copy's absolute path), and
`KENSPC_AUTOPILOT_SUITE_LOG` (`<logs>/<batch>-suite-slots.log`), each the
empty string without the field and overwriting the caller's value; the
wrapper reads the limit and the log, the hook the commands and the
wrapper, and a subagent inherits all four from its worker. In a
marked worker it
denies, with exit 2 and the reason on stderr, a Bash command that runs a
recursive `rm` at a command position, a Write, Edit, or NotebookEdit
whose resolved target lies outside every root, a Bash redirection (`>`,
`>>`, `>|`, `&>`, `&>>`, with or without a file-descriptor number) whose
target — read after a leading `~`, `$HOME`, or `$TMPDIR` is expanded and
`.` and `..` are collapsed — lies outside every root by the same root
check (4.7.0), `gh` and remote git (`git fetch`, `pull`, `push`,
`ls-remote`, `remote update`, a `clone` of a URL) at a command position,
its reason routing the worker to ask the main session (4.7.0), a listed
suite command at a command position run without the suite-slot wrapper
(check (f), 4.10.0: with `KENSPC_AUTOPILOT_SUITE_COMMANDS` non-empty, the
base name of a prefix's first word against the command word's base name
and its later words as written, whole word by whole word, a prefix's
leading assignments and wrappers skipped as a command's are, its reason
giving the route
`bash <KENSPC_AUTOPILOT_SUITE_WRAPPER> run -- <the command>`, run again on
exit 75 with a `suite-slots: busy` line), and a Bash
input over 64 KB unscanned, since a scan that outlasts the hook's 5-second timeout
denies nothing; a call whose tool name, Bash command, or file-tool target
it cannot read from its input is denied too, so a renamed field stops the
calls loudly, with a reason that names no route, since a retry is read
the same way — in the worker's own calls
and its subagents' alike, since a plugin's PreToolUse hook fires for a
subagent's call too and its deny holds in bypassPermissions (probed on
Claude Code 2.1.283). It is a best-effort guard behind the preamble's
rails text; its header lists what it misses, and
`check-autopilot-rails-hook.sh` holds its decisions. A former
`SessionStart` → `check-deps.sh` hook was removed in v3.4.2: its
ralph-loop dependency check was gutted by the v2 subagent refactor and
the empty husk had been running as a no-op since.

References live in `references/` as example documents (task format, plan format) to help users get started.

Shared resources live in `shared/` as cross-skill files (prompt frameworks, templates) referenced via `${CLAUDE_PLUGIN_ROOT}/shared/<file>.md`. Three entries today: `discovery-framework.md`, loaded by both `generate-plan` Phase 1 and `generate-brief` Phase 1 to provide a single source of truth for the discovery conversation pattern (five dimensions, four input clarity levels, exit conditions); `code-craft-principles.md`, referenced by three agents (`task-implementer`, `code-fixer`, `quality-reviewer`) — it defines the Simplicity First and Surgical Changes principles with stack-specific C# / TypeScript diff examples, and explicitly does NOT define Goal-Driven Execution (covered by DONE-criteria in every SKILL), Think Before Coding for ad-hoc interactions (belongs in user-level or project-level CLAUDE.md), per-language style guides (delegated to the project's instruction files), or agent dispatch order / CONTEXT contracts (defined in the dispatching SKILL.md and each agent's header); and `instruction-files.md` (4.1.0), the one place the plugin defines "the project's instruction files" — a project's CLAUDE.md and AGENTS.md files, at the root, in `.claude/`, or in a subdirectory, and the files a CLAUDE.md imports, whether or not Claude Code loaded them — with its Why. No skill or agent reads it at run time: each file that uses the term carries the definition sentence, and `check-instruction-files.sh` holds every copy to this one.

### Portable Paths

All file references in hooks and commands must use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths.

### Writer-agent section header convention

Writer-agent files (`task-implementer.md`, `code-fixer.md`) use ALL-CAPS section headers with no hyphens (e.g., `OBJECTIVE`, `PREREQUISITES`, `QUALITY RULES`, `FIXING PRIORITY`). The single canonical compound-adjective exception is `CODE-CRAFT PRINCIPLES`, where the hyphen joins "code" and "craft" into a single adjective modifying "principles" — removing it would change the meaning, not just the punctuation. Each occurrence of `CODE-CRAFT PRINCIPLES` in a writer-agent body is paired with an HTML guard comment on the line immediately above the header, naming the compound-adjective exception and pointing back to this paragraph. The co-location ensures that a future editor who would otherwise normalize away the hyphen sees the rationale next to the header before they edit, and so any future normalization edit must update this CLAUDE.md paragraph in the same commit.

### SKILL.md Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Skill identifier (kebab-case) |
| `description` | Yes | When to activate (1-2 sentences, concise) |
| `version` | Yes | Semver (e.g., `1.0.0`) |
| `argument-hint` | Recommended | Shown in UI as placeholder (e.g., `<project-path>`) |

The per-skill `version` field is uniformly `3.0.0` across all ten skills and
denotes the v3 architecture generation, not a per-skill change counter. It is
deliberately decoupled from the plugin version in
`plugins/kenspc/.claude-plugin/plugin.json`, which is the authoritative version
and the only one bumped each release. It was set during the v3.0.0 rewrite and
is intentionally left unchanged on subsequent releases — syncing ten files
every release is churn that has historically drifted anyway. Bump it only on a
future architecture-generation change (a v4 rewrite), and bump all ten together
so the uniformity holds. Plugin 4.0.0 was the maintainer's version choice, not
an architecture rewrite, so the per-skill field stays `3.0.0`.

### Subagent Review Architecture

Skills use plugin agents (defined in `agents/`) as workers, dispatched via the
Agent tool — except the autopilot, whose workers are headless sessions (the
fourth pattern below); the read-only sweeps of generate-task,
generate-guide, and diagnose-bug (4.9.0) are unnamed subagents that return
`file:line` and review nothing. Four orchestration patterns:

**No review (generate-brief, diagnose-bug, prototype, init-project):**
Brief is a discovery artifact, not a verifiable spec. Review happens downstream
when generate-plan consumes the brief. Phase 1 detection in generate-plan
recognizes briefs and gap-checks against the same five dimensions defined in
`shared/discovery-framework.md`.

The prototype skill's prototype is discarded in the run that built it, so
there is nothing left for a reviewer to hold; its answer is reviewed where a
plan uses it — generate-plan reads the answered entry, and
`plan-document-reviewer` reviews the plan that cites it.

diagnose-bug's task document has no plan to compare against —
`task-document-reviewer` requires a plan and cross-references its
Implementation Steps — so the user's confirmation of the task list is its
gate, and task-implement's batch gate follows. The checks the reviewer
would make — vague acceptance criteria (its Completeness angle), language
carried into code artifacts and a git step nobody decided (its Consistency
with the project's instruction files angle) — are the skill's own writing
rules.

The diagnosis path runs from an observed bug to the same implementation run.
`diagnose-bug` reproduces the bug first: a test in the project's test tree
that fails for the reported reason, committed alone
(`test: reproduce <symptom>`) before any diagnosis — or, when no
failing-capable test can be written, the manual steps and the reason. The
diagnosis lands in the task document's `## Diagnosis` record (nine fixed
labels, `**Symptom:**` through `**Probes:**`), followed by a fix task, a
regression-test task for the adjacent cases the diagnosis found (omitted
when there are none), and a `### Task N: Doc-sync` task written from
generate-task's template when the diagnosis's Documentation impact lists
documents; the document is committed alone (`docs: add task <name>`). A fix
that needs a new dependency, an API contract change, a database schema
change, or a configuration change — the stop conditions in
`task-implementer`'s AUTONOMY BOUNDARIES — is tier 3: a brief for
`/kenspc-plan` instead, and no task document. Probes, copies, and mutants go
in a run directory prepared as the `canonical:run-dir` block prescribes, by
reference, with the run-id suffix `diagnose-<name>`, under
`scratch/orchestrator/<n>/`.

The prototype path runs from a brief's open question to the plan. A brief's
`## Open Questions` entry marked `needs prototype`, with the `Settled by:`
result that would answer it, stops generate-plan's Phase 1 before any
gap-check question: the user sends it to prototyping — the run ends with a
`/kenspc-prototype <brief path> <n>` line and writes nothing — or carries it
into the plan's Open Questions (`From:`, `Not prototyped:`, `Assumed in:`);
a session that cannot ask carries it. `/kenspc-prototype` builds the
smallest thing that settles the question, commits it
(`chore: add prototype <slug>`, under `prototypes/<slug>/` by default),
rewrites the entry `answered` with `Answer:`, `Evidence:`, and a
`Prototype:` line naming that commit, and removes the prototype in the next
commit (`chore: remove prototype <slug>`); the brief is not committed. The
next generate-plan run reads the answered entry as settled input — its
`Answer:`, with text after the label, makes it settled, not the status word
alone — and a plan that
relies on it cites the hash. A prototype runs outside the app; the one
in-app exception is a UI prototype that can only render inside the app,
located by the project's instruction files or by the user, with the
typecheck green against its baseline.

init-project writes a project's AGENTS.md, CLAUDE.md, and topic documents
from the user's answers and a scan of the directory, with
`TBD(init): <what is missing>` where nothing answered; there is no spec a
reviewer could check those files against. Its gate is its own mechanical
checks before the commit — the line budget, the import line on CLAUDE.md's
first line, AGENTS.md's template marker and admission-rule comment, the
Documents table's paths and the README's list of the same files, a source
for every topic-document sentence (or a `TBD(init):` marker in its place),
no secret-looking value, the `TBD(init):` form, and the `.gitignore` lines
— and the user's confirmation of the file list, which a skip does not give
(4.1.0). On the user's yes it also turns on the stacks' Claude Code plugins
in the root's `.claude/settings.json`, through `claude plugin install
--scope project` for the entries the file lacks, found at run time rather
than from a table in the skill; a further check holds that file to valid
JSON that gained only the confirmed `enabledPlugins` keys (4.4.0).

**Serial review (generate-plan, generate-task, generate-guide):**
Skill dispatches a single named agent (`plan-document-reviewer`,
`task-document-reviewer`, or `guide-document-reviewer`) that reviews all
angles in order in its own context. Each angle builds on fixes from the
previous one (cascade dependency). Agent body returns a structured change log.
`plan-document-reviewer` and `guide-document-reviewer` review four angles;
`task-document-reviewer` reviews three — Completeness (including Doc-sync
coverage), Execution Order, and Consistency with the project's
instruction files. The plan reviewer's Completeness angle checks the plan's
Documentation impact element. The reviewer reads the project's instruction
files itself (its PREREQUISITES), since whether Claude Code loaded an
AGENTS.md depends on a setting it cannot see; for the user-level rules the
angle also checks against, it relies on the subagent loading
`~/.claude/CLAUDE.md` (`omitClaudeMd` false or absent loads the user,
project, and local CLAUDE.md files; source: the Claude Code sub-agents
reference, https://code.claude.com/docs/en/sub-agents, checked 2026-09-24).
The reviewer does not read `~/.claude/CLAUDE.md`, so an agent that opts out
of that loading loses the user-level rules the angle checks against.

The documentation path runs from the plan to the implementation run. Every
plan carries a Documentation impact element — the durable documents its steps
make stale, or `N/A — <reason>` — which `plan-document-reviewer` checks.
`generate-task` turns an element that names documents into a last task,
`### Task N: Doc-sync` with `Depends on: Task 1-<N-1>`, and
`task-document-reviewer` checks that the task is there, is last, and lists the
same documents. `task-implementer` runs it like any other task: it brings the
listed documents in line with what the earlier tasks built and promotes their
recorded decisions into them. A decision that belongs in a durable document
none of the listed ones fits is reported under `## Decisions needing a home`
in Schema D, and task-implement's Schema G turns each entry into a Next steps
bullet. In a run without a Doc-sync task, the roll-up classifies the DONE
tasks' decisions itself and writes no document. The section is always
rendered, `none` when empty, unlike Schema D's skip-when-empty sections: in an
unattended run it is the only evidence that the promotion step ran. The
dependency gate holds the chain together: `task-implementer` marks a task
BLOCKED with `depends on Task N (<status>)` when its `Depends on` line names
a task that is not DONE, so a Doc-sync task never documents behavior a
blocked task did not build. The gate applies to every task with a
`Depends on` line, not only the Doc-sync task.
When a review runs against a task document whose Doc-sync task is DONE,
`code-fixer` corrects, in the fix's own commit, the sentences of the listed
documents a fix makes false, and the final report names each document it
changed.

**Parallel MapReduce (task-review):**
- Phase 1: 5 review agents, read-only on the working tree, dispatched in parallel
  (`requirements-reviewer`, `edge-case-reviewer`, `quality-reviewer`,
  `bug-reviewer`, `test-reviewer`) — one per angle. Angle 3
  (`quality-reviewer`) covers project conventions and existing patterns
  — rules written in the project's instruction files / README and
  patterns in adjacent code —
  since v3.5; the file name is kept so the canonical dispatch block stays
  unchanged. Around Phase 1 (4.7.0, in the canonical dispatch block): before
  the dispatch the orchestrator runs the project's test commands once —
  those the project's instruction files give for the parts the change set
  touches, found as `regression-verifier` finds them — itself, in its own
  Bash and not through a subagent (4.9.0: the commands are known, so a
  brief costs more than the run, and the logs belong under
  `scratch/orchestrator/`), and writes
  `suite-run.md`, which each reviewer reads instead of running the full
  suite (five full suites at once exhausted a machine's local ports, and
  the connection errors read like findings). A reviewer given `RUN_DIR`
  also runs no test file that needs ports or a database — its own setup
  starts a server or host, opens a database connection, or binds a port,
  or the project's instruction files name it an integration test, and a
  file it is unsure of counts — but reads its result in the suite logs and
  lists it under `## Tests left for the verifier` in `angle-<n>.md`, the
  path and what it wanted to learn, or `none` (4.9.0), since such a file
  run by several reviewers at once contends for the same ports and
  database. Invoked standalone, without `RUN_DIR`, a reviewer runs the full
  suite itself, and its description says to dispatch standalone reviewers
  one at a time or use `/kenspc-task-review` (4.9.0). Then the orchestrator records the tree
  state (`HEAD` and its branch, `git status --porcelain=v1 -uall`, a hash
  of `git diff HEAD --binary`, and each listed path's `git hash-object`,
  untracked ones included), and records it again once all five have
  returned. A changed `HEAD` or branch, or a changed file listed before
  the review, stops the review before Phase 2, naming the files,
  with no restore and one question (go on with the tree as the user leaves
  it, or end); a new untracked file stops nothing and is named in the
  final report, so an unchanged tree asks nothing.
- Phase 2: `code-fixer` reads all 5 reports from the run directory,
  deduplicates, applies fixes, and writes the accountability list (Schema B)
  back to it. A defect it finds that no report lists is recorded, not
  fixed, as an `F<n>` row, DEFERRED (4.7.0). Its reply carries a
  `Final checks:` line — each final build, test, and lint command with its
  exit code and log, or `Final checks: none run (no fix applied)` — that
  is not written to `schema-b.md`, whose last line stays the statistics
  line the recount reads (4.9.0).
- Phase 3: `regression-verifier` cross-checks the reports' issue IDs against
  the accountability list, verifies fixes, runs build/test/lint, and names
  each regression it finds `V<n>` (4.7.0). After the full test command it
  runs, one at a time, each file a reviewer listed under
  `## Tests left for the verifier` that the full run did not collect —
  alone, after code-fixer, one the project's configuration excludes from
  its default test command through the command the project gives for it,
  or settled as intentionally skipped when it gives none — and row 3 names
  how each was settled (4.9.0).
  Schema C rows 2–4 carry `<command> → exit <n>, log <path>` in the Detail
  cell in every state, PASS included, the path relative to `RUN_DIR`, or a
  no-command form (`no build command in the project`, row 3's SPOT-CHECK
  fallback), since a `—` cell could be confirmed only by running the check
  again (4.9.0). The verdict reads those exit codes as reported (the
  `canonical:verdict-shared` block): the orchestrator confirms a row by
  reading the log it names and runs no build, test, or lint of its own,
  and a row 2–4 with neither an exit code nor a no-command form keeps the
  verdict from PASS.
- After Phase 3, a second round (4.7.0, the `canonical:second-round`
  block): the orchestrator saves regression-verifier's first reply to
  `schema-c-1.md` in every review, and when it holds a ruling given after
  code-fixer's first dispatch — a user message in an interactive run, the
  main session's answer in an autopilot worker — appends it under
  `## Round 2` in `rulings.md` and dispatches `code-fixer` and
  `regression-verifier` again, afresh, with the CONTEXT block unchanged;
  the verdict is read from that round. At most one per review, since an
  unbounded loop would bypass the autopilot's per-defect stop counts; with
  no ruling held, no second round and no question.

task-review and task-implement run only in the top-level session — the one
the user talks to, or a headless `claude -p` session — never inside a
subagent (4.9.0, each skill's Prerequisites, outside the canonical blocks,
so the two bullets differ where the skills do): a subagent may not dispatch
subagents of its own — a user rule may forbid it, and Claude Code caps the
nesting depth — so it would review all five angles, fix, and verify in one
context, losing the reviewers' independence, and it cannot ask the user at
the skill's gates.

Between the dispatches the orchestrating skill prints one fixed progress
line per step — which agent returned, its counts or result, and the path of
its report when it writes one — and the Schema A roll-up, code-fixer's
reply, and Schema C are rendered once, in the final report (Schema F in
`task-review`, Schema G in `task-implement`).

Since v3.5 the agents exchange reports through a per-run directory,
`<repo root>/.kenspc/runs/<run-id>/`, passed as the `RUN_DIR` CONTEXT key.
The orchestrating skill prepares it and, when `.kenspc/` is not yet
git-ignored, makes a one-time `.gitignore` commit — task-implement after
its batch confirmation and before it dispatches task-implementer, reusing
the same directory for its review (4.3.0). In a review without a
task document it then writes `change-set.md` (v3.7), the change set every
agent reads (see CONTEXT block contract). Each reviewer writes only
its own `angle-<n>.md`, and `code-fixer` only `schema-b.md`; the
orchestrating skill writes `suite-run.md` before the reviewers' dispatch,
`rulings.md` when it holds a ruling, and `schema-c-1.md` when
regression-verifier first returns (4.7.0), with the suite logs and the
tree state under `scratch/orchestrator/`. Probe and
temporary files go in one scratch subdirectory per writer —
`scratch/task-implementer/`, `scratch/angle-<n>/` for each reviewer,
`scratch/code-fixer/`, `scratch/regression-verifier/`, and
`scratch/orchestrator/` for the main session — and are named so the project's test runner does not collect them
(vitest and jest with their default patterns: no `.test.` or `.spec.`
segment in a file name, no file named `test.*` or `spec.*`, no `__tests__`
directory, and no `__mocks__` directory; a project-configured pattern or
another runner: what that configuration actually collects; any jest
project: still no `__mocks__` directory; a file that already carries a
collectable name is renamed, not deleted). So parallel writers never share
a file, and the main session relays paths rather than report text. Issue IDs (`R` / `E` / `Q` / `B` / `T` plus a sequence number)
and code-fixer's Source column let `regression-verifier` settle completeness
by comparing ID sets; code-fixer's own `F` rows and the `V` regressions
are left out of that comparison (4.7.0), an `F` row being code-fixer's
own and a `V` row listed by `schema-c-1.md`. kenspc's agents cannot
dispatch subagents, since none lists Agent in `tools:`; Claude Code itself
nests subagents to depth 3 by default (2.1.301,
`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`); orchestration stays at the skill
(main session) level.

**Sessions, not agents (autopilot):**
The autopilot skill runs one batch of this plugin's own chain unattended
through one headless `claude -p` session per role — S1 design (brief entry
only), S2 task decomposition (`/kenspc-task`), S3 implementation
(`/kenspc-task-implement`), S3b standalone review (`/kenspc-task-review`
over the batch's range; it runs unless `Standalone review: off` in repo
mode, 4.6.0, where S3's Schema G verdict and its review's rows take its
place in the verdict loop, or `auto`, 4.7.0, which the main session reads
from S3's Schema G — S3b runs on a FAIL, a PARTIAL for a reason other
than BLOCKED tasks alone, or a HIGH or MEDIUM row S3's review left
DEFERRED), S4 acceptance, S4w runtime walk (repo mode unless `Walk: off`,
4.7.0: the batch's user-facing flows walked in a browser through the
Playwright MCP, on the local machine, after S4), S5 fix on demand, S6
release preparation — each started through the driver script that ships with the
skill (`skills/autopilot/scripts/run.sh`) and is copied per batch, with
`--name <tag>` and `crossSessionInbound: accept`. Questions and answers
travel as cross-session messages (`question <tag>:` / `answer <tag>:`);
the worker's idle notice is the main session's wake, and `<tag>.exit`,
written by the driver when the worker returns, is the completion artifact
— a transition never rests on a notice's wording. The main session
re-reads its state file (`_logs/<batch>-state.md` under the workspace) on
every wake, and `--resume` only continues a worker that has ended — dead,
ended by its cap, ended by the usage limit (resumed after the reset, not
counted as a death; 4.6.0), stopped on a question it got no answer to within
thirty minutes or whose send returned an error or a held or refused
notice, an S2 whose committed task document the skipped-gate
post-check sends back to amend, or a worker that ended on a rail breach
the main session rules benign (no secret written or sent; no recursive
`rm`, push, tag, or release; no state changed outside the write roots but
a file the breach created holding no secret, moved into `.trash/`; 4.7.0) — never a live one; no agent, no CONTEXT key, no agent
teams. A finished batch removes its own entries from the temp folder
(4.8.0): the main session snapshots the folder before the driver's
self-test, and after the release preparation removes, path by path, each
new entry `temp-candidates.sh` lists as the batch's by evidence — the
self-test's directory, a prefix the acceptance commands write under
`$TMPDIR`, or a clone of the repository or a seed — since two tracks share
the folder and the workers' rails forbid a recursive `rm`; a stopped run
removes nothing. Batches on one machine share one suite-slot lock
(4.10.0, repo mode only): with the `## Autopilot` field `Suite limit:` set
— N, and the command prefixes as sub-bullets — every listed command, in a
worker, its subagents, S4's cases, and the main session's corrected-case
runs, runs through the copied `suite-slots.sh`, which takes a slot under a
`mkdir` mutex in `/tmp/kenspc-suite-slots` only while fewer than the
caller's own N holders are live, and the rails hook denies a listed
command run without it. A busy wrapper (exit 75) is run again, never
bypassed; after 30 minutes of busy returns the worker asks the main
session, which answers `wait on` while every holder is younger than 60
minutes and stops on stop condition 12 once one is not, since the holder
may be another batch's. Why: more than about two runs of one integration
suite at once exhausted a machine's local ports, and a batch's
`Run facts:` bound only that batch. The field in plugin mode is a settings
stop, since plugin-mode S4 runs its cases as nested sessions the wrapper
cannot take. The roles are sessions rather than
agents because a session that edited the plugin still runs the text it
started with, so the review, the acceptance, and a fix each need a session
of their own; the workers run the installed plugin, or in plugin mode the
worktree's copy with `--plugin-dir`. Each worker is its own process and
resolves its model and effort from its own settings, not from the main
session, so the skill passes each role's values — declared in the spec's
`Role settings:`, or the main session's own passed through — as run.sh's
`AUTOPILOT_MODEL` and `AUTOPILOT_EFFORT`, which the driver turns into
`--model` and `--effort` on a fresh launch and on a resume alike (a resume
keeps the model but not the effort).

The main session dispatches no Agent subagent — not for a role, a
re-check, a re-run, a review, or the evidence of a corrected case — and
runs its own checks (the start checks, the temp-folder snapshot, the
driver's self-test, the extraction, the zero-diff check, the corrected-case
runs) in its own Bash (4.9.0, the skill's overview): a subagent's cost is
outside the budget's terms, which sum the sessions' costs; it carries no
worker marker, so the rails hook does not guard its calls; in plugin mode
it runs the plugin text the main session loaded at its start; and several
of those checks read values only the main session's Bash holds. A worker,
by contrast, is the top-level session of its own process and may dispatch
subagents, each with `run_in_background: false`, while a subagent it
dispatches dispatches none and starts no `claude -p` (4.9.0, the preamble's
§ 3). The rail has its own form for a subagent's prompt, where the rest
of § 3 goes verbatim: there it reads "you are a subagent of an
autopilot worker — dispatch no subagent and start no `claude -p`". It is
text only: the rails hook does not tell a worker's call from its
subagent's, so `autopilot-worker-rails.sh` does not enforce it. The worker
itself still launches the nested sessions its task block names
(plugin-mode S4).

Every Agent dispatch in the skills sets `run_in_background: false`
(v3.5.1): each skill reads the agent's result in the same turn, while a
background call returns at once and is stopped when a headless session
exits. Foreground calls sent in one message still run in parallel, which is
how the five reviewers are dispatched. The parameter exists in headless
(`claude -p`) and SDK sessions, and in a Claude Code 2.1.301 Desktop
session, measured on 2026-10-17: there a call with
`run_in_background: false` returned only when the subagent had finished,
and the same call with the parameter omitted returned at once and ran the
subagent in the background. The interactive terminal CLI is not measured:
the 2.1.301 binary drops the parameter when its fork-mode gate is on, which
its docs tie to that CLI (a reading of the binary), and there subagents
ran asynchronously, each result handed back within the same turn (observed
on 2.1.281).

As of v3.5, effort follows the session by default: a SKILL.md or agent
.md without an `effort:` field inherits the session's effort level (per
the Claude Code skills and subagents frontmatter references). Reasoning
depth is set this way, not via inline directive tokens. Anthropic's
guidance is to start from each model's default effort and raise it only
where the work under-executes or is hard for the user to validate; the
default is re-tuned with each model generation, so the plugin does not
pin per-generation values (sources: "Choosing a Claude model and effort
level in Claude Code", claude.com blog, 2026-07-07; "Choosing the right
effort level in Claude Code", Claude Academy). Guidance last reviewed
against the Claude 5 generation 2026-09-29 — at each release, confirm
the override rationale below still holds (see the release checklist).

The `effort:` frontmatter in each file is authoritative — this prose
records the rationale, not a second copy of the values. Two files
override the session:

- `task-implementer` (`high`) — unattended long-horizon implementation.
  Nobody is watching to catch a run that stops short of the batch or
  skips a verification step, so the thoroughness has to come from the
  agent.
- `code-fixer` (`high`) — also unattended: deduplication across five
  reports and a fix / build / test loop per finding, with no user
  checkpoint before regression-verifier runs.

The two agents sit one level above the generation's default effort,
`medium` at the maintainer's 2026-09-29 review: their unattended work
needs more than the default, and one level is the margin the maintainer
chose (4.3.0; `xhigh` through 4.2.x). A generation whose default moves is
the review's cue to move them with it. `generate-plan` ran at `xhigh`
through 4.5.1 (`max` through v3.4.x), on the reasoning that a plan's cost
amortizes over every task built from it; 4.5.2 dropped the override so the
skill follows the session like the other nine, since the override acted
only in a session set below `xhigh`, and the depth of a plan is the
session setting's to decide.

Everything else — the 5 review-angle agents, `regression-verifier`, the
3 document reviewers, and all ten skills — runs at the session's
effort. When a session runs at `xhigh`/`max`, set a large
max-output-token budget so the model has room to think and act across
subagents and tool calls (this is a session/API-config concern, not a
plugin concern).

#### CONTEXT block contract

Each agent declares its expected CONTEXT keys in its body. The dispatching
SKILL.md must construct exactly those keys. See each agent file's
"CONTEXT YOU WILL RECEIVE" section for the contract.

`RUN_DIR` (v3.5) is optional for the 5 review-angle agents — without it they
reply inline and write nothing, which keeps standalone invocation working as
before — and required for `code-fixer` and `regression-verifier`, which read
their inputs from it, and (4.3.0) for `task-implementer`, which writes its
probes, copies, mutants, and runner configs under
`RUN_DIR/scratch/task-implementer/` and runs a mutation check on copies
there, never on a tracked file. It replaces the earlier `REVIEW_REPORTS` and
`ACCOUNTABILITY_LIST` keys: the file names inside the run directory are
fixed, so one path is the only value the orchestrator has to get right.

`TASK_LIMIT` (4.6.0) is an optional key of `task-implementer`: a positive
integer that caps how many TODO or IN PROGRESS tasks, in document order,
one dispatch gives a final status (a dependency block included); a task
left for a later slice keeps its status, a value that is not a positive
integer is a BLOCKED run, and without the key every incomplete task is
processed. `task-implement` adds `TASK_LIMIT: 12` to the dispatch when a
document has more than 12 incomplete tasks, dispatching slices one after
another in the same run directory until no TODO or IN PROGRESS task is
left or a slice changes no task's status, and merges the slices' Schema D.
Why 12: one implementer ended on `Prompt is too long` after 22 tasks of a
33-task document and returned no summary.

`change-set.md` (v3.7) follows the same reasoning. With REVIEW_SCOPE
"changes", the orchestrating skill computes the change set once, with
read-only git commands — its mode (`uncommitted` or `commits`), a base or
range pinned by SHA before the run-directory preparation, the diff command,
and the file list — and writes it to `RUN_DIR/change-set.md` before
dispatch. The five reviewers, `code-fixer`, and `regression-verifier` read
it there. No key was added, for the reason `RUN_DIR` replaced
`REVIEW_REPORTS` and `ACCOUNTABILITY_LIST`: a fixed file name inside the one
path the orchestrator passes leaves it nothing more to get right. Without
`RUN_DIR`, a standalone reviewer derives the set from git itself. In
`uncommitted` mode `code-fixer` commits nothing — no baseline commit, no fix
commit, no stash, and no checkout, restore, reset, clean, or add — and its
FIXED rows carry `—` in Commit. It records each file's state before its
first edit under `RUN_DIR/scratch/code-fixer/pre-fix/` — a `.txt` copy per
file and an `index.txt` naming every file the fixes touched — and
`regression-verifier` reads the fixes from that record, not from the
working-tree diff, so the user's own hunks in the same file are never read
as fix output.

`rulings.md` (4.5.0) follows it. When the orchestrating skill holds a
ruling on the reviewers' findings as it reaches the code-fixer dispatch —
a message from the user received before that dispatch in an interactive
run, or an autopilot main session's answer to the worker running the
review — task-review (Step 5) or task-implement (Phase 2 Step 3) writes it
to `RUN_DIR/rulings.md` before the dispatch: a first line naming who
ruled, then one `- <ID>[, <ID>…]: FIX — <what to do>`,
`FIX — <what to do>; DEFER rest — <reason>` (4.7.0: the row stays FIXED,
the FIX text bounds the check, and the deferred part goes into the row's
Deferred Issues prose, so one ID keeps one entry and one action),
`DEFER — <reason>`, or `NOT APPLICABLE — <reason>` entry per ruling. The
step adds no pause and no question, and with no ruling no file is
written. task-review's Step 5 alone states the rules around the grammar
(4.7.0) — an entry naming a group covers every clause of every row it
names; an entry outside the grammar (an unknown action word, no ID, a
first line naming nobody, one ID in two entries of one round) is not
carried out, its IDs falling back to code-fixer's own rules, is named on
code-fixer's `Rulings outside the grammar:` reply line and in
regression-verifier's row 1, and keeps the verdict from PASS; a ruled
ID's unruled duplicate takes its ruling — and task-implement points at
that step rather than carrying a second copy of the prose. `code-fixer` gives a ruled ID the ruling's action over FIXING
PRIORITY (a FIX ruling's text bounds the fix, and a file it names is in
its scope) and marks the row `ruled` after the em-dash, keeping the
leading word so the statistics recount is unchanged; `regression-verifier`
checks each ruled row's action against its ruling (VERIFICATION CHECKS
item 1) and a FIX-ruled fix against the ruling's text (item 2). No key was added, and a ruling
never goes into `CUSTOM_INSTRUCTIONS`: the CONTEXT block passes to both
agents unchanged, the rule a narrowed review broke when it wrote a ruling
there. The five reviewers do not read the file.

`suite-run.md` and `schema-c-1.md` (4.7.0) follow it, with no key added.
The orchestrator writes `RUN_DIR/suite-run.md` before the five reviewers'
dispatch — each test command, its exit code, its duration, and its log's
path under `scratch/orchestrator/`, or one line saying the project gives
no test command — and a reviewer given `RUN_DIR` reads it and never runs
the project's full test command (its PREREQUISITES item 5, held identical
in the five by `check-review-agent-drift.sh`); one given `RUN_DIR` without
the file says so in its report and still runs no full suite. The
orchestrator saves regression-verifier's first reply to
`RUN_DIR/schema-c-1.md` in every review, and a second round's entries go
under a `## Round 2` heading in `rulings.md`, a round-2 entry for an ID
ruled in round 1 replacing that entry. `code-fixer` then carries out only
the round-2 entries, updates `schema-b.md` in place keeping every row, and
adds a row for each `V` ID a round-2 entry names, taken from
`schema-c-1.md`'s Detail; a `V` ID that file does not name is a ruled ID
that no report lists. Schema B's Source IDs gain two letters: `F<n>`,
code-fixer's row for a defect no report lists (DEFERRED,
`no report lists it`, unless a ruling names it), and `V<n>`, a regression
`regression-verifier` names in its Schema C Detail, numbered on from the
highest `V` ID in `schema-c-1.md` in a second round so two rounds never
reuse one. The statistics line counts both,
`total reported N (R n, E n, Q n, B n, T n, F n, V n), …`, and the
Per-angle Results table carries all seven rows, zeros included, a fixed
shape the recount can hold. Why `F` and `V`: a ruling on a defect no
reviewer reported, or on a regression, had no row to land on and read as
a ruled ID that no report lists.

#### Standalone safety classification

- **Standalone-safe**: 5 review-angle agents (requirements, edge-case, quality,
  bug, test) can be invoked directly. Description gates auto-delegation;
  body refuses without CONTEXT.
  Each reviewer is read-only on the working tree and writes only under
  `RUN_DIR`: its report at `RUN_DIR/angle-<n>.md`, and probe and temporary
  files under `RUN_DIR/scratch/angle-<n>/`.
  Without `RUN_DIR` (standalone) they write no file and derive the change
  set from git themselves.
- **Orchestration-only**: 6 worker/document-reviewer agents (code-fixer,
  regression-verifier, task-implementer, plan-document-reviewer,
  guide-document-reviewer, task-document-reviewer) require structured
  CONTEXT input from a calling skill. Their first description sentence is
  "INTERNAL: ..." and their body has a prerequisite check that refuses on
  missing CONTEXT.

#### Maintenance note

The 5 review-angle agents share CONTEXT YOU WILL RECEIVE, ROLE,
PREREQUISITES, CUSTOM INSTRUCTIONS, FILE COVERAGE, and REPORT DELIVERY
sections by convention. When modifying any of these sections in
one agent, apply the same change to the other 4. Duplication is intentional
(each agent is independently readable); silent drift between them is a bug.

Four more byte-identity invariants bind `task-review/SKILL.md` and
`task-implement/SKILL.md`: the canonical `## Code Review Phase
(unconditional)` block (bounded by `<!-- canonical:dispatch:start/end -->`
markers), which since 4.7.0 also holds the shared suite run and the tree
check, the shared verdict-determination bullets (bounded by
`<!-- canonical:verdict-shared:start/end -->` markers), the run-directory
preparation (bounded by `<!-- canonical:run-dir:start/end -->` markers),
and the second fix round (bounded by
`<!-- canonical:second-round:start/end -->` markers, 4.7.0; task-review's
Step 7 and task-implement's Phase 2 Step 3), whose text is skill-neutral —
"this skill", "the final report" — so one copy reads true in both. The
Schema B statistics-line template (`<!-- canonical:stats-line:start/end -->`)
is byte-identical across those two SKILLs and `code-fixer.md`, and the
`rulings.md` entry grammar (`<!-- canonical:rulings-grammar:start/end -->`)
across those two SKILLs, `code-fixer.md`, and `regression-verifier.md` —
task-review's Step 5 defines it, and a carrier that stops stating it
points at that step by path and holds no copy, while
`check-run-contract.sh`'s check 7 and its self-test drop that carrier in
the same commit.

After editing any reviewer agent, `code-fixer.md`, `regression-verifier.md`,
or either of those two SKILLs, run the matching guard script — `check-review-agent-drift.sh`,
`check-canonical-dispatch.sh`, `check-verdict-shared.sh`, or
`check-run-contract.sh`. After editing the reviewer invariant sentence in
the plugin README or this file, or the reviewers' ROLE, run
`check-run-contract.sh`. After editing the Prototype line (in
`generate-brief/SKILL.md` or `prototype/SKILL.md`) or the prototype
skill's leftovers command, run
`check-doc-sync-anchors.sh`. After editing a file that uses "the project's
instruction files", or `shared/instruction-files.md`, run
`check-instruction-files.sh`. After editing
`hooks/scripts/autopilot-worker-rails.sh`, or the autopilot `SKILL.md`'s
preamble template, § Launch, wait, return, or stop conditions, run
`check-autopilot-rails-hook.sh`. After editing
`skills/autopilot/scripts/extract-acceptance.sh`, `zero-diff.sh`,
`temp-candidates.sh`, or `suite-slots.sh`, run `check-autopilot-scripts.sh`. What each
guard checks is documented once, in "Repository scripts/" below.

### Non-Goals

`shared/discovery-framework.md` stays in `shared/` and is NOT converted into a plugin agent. It is consumed by the main session at two call sites (generate-brief Phase 1, generate-plan Phase 1) as a structural guide for free-form discovery dialogue with the user — not as bounded delegated work. Subagent isolation would break the discovery phase's need for raw conversation context (the orchestrator must keep the full transcript to draft the brief or plan in Phase 2).

The run-directory preparation is written once, in the `canonical:run-dir` block of `task-review/SKILL.md` and `task-implement/SKILL.md`. `diagnose-bug` also prepares a run directory for its probes, and references that block — naming its markers, with the `diagnose-<name>` run-id suffix — rather than carrying a third copy; it points at generate-task's Doc-sync Task template the same way. A copy would have to be kept byte-identical by a guard, and a reference cannot drift. The block holds no mutation rule, so for a mutant used as evidence the skill points at the three-step mutation rule where it is written, the RUN_DIR bullet of `regression-verifier.md` (the reviewers and `code-fixer` carry the same rule). A change to that rule, or a move of it, updates the pointer in `diagnose-bug/SKILL.md` in the same commit, and the one in `agents/task-implementer.md`, whose SCRATCH SPACE section points at the same rule.

The prototype skill references the same block the same way: its prototype's file names follow the naming rule of the block's Scratch space bullet, pointed at by the block's markers, and the skill carries no copy. A move of that rule updates the pointer in `prototype/SKILL.md` in the same commit, and the one in `agents/task-implementer.md`, which points at the same bullet's naming and numbered-attempt rules.

The Open Questions entry grammar — the status words, the labels and their order, the answered and unsettled forms — is written once, in generate-brief's Writing rules for the brief, and generate-plan and the prototype skill point at it by path. The one piece the prototype skill repeats is the Prototype line (``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` ``), byte-identical to generate-brief's, so a change to that line in `generate-brief/SKILL.md` updates `prototype/SKILL.md` in the same commit. `check-doc-sync-anchors.sh` holds this line in both files, beside the `needs prototype` status word across the three.

The `## Autopilot` section grammar — the labels, their values, and the note form — is written once, in the autopilot skill's § The `## Autopilot` section, and generate-plan reads it there by path at run time (4.6.0) rather than carrying a copy, so a plan's section and the autopilot's reading of it cannot drift. A rename or move of that heading updates the pointer in `generate-plan/SKILL.md` in the same commit.

The autopilot skill uses no agent teams: one role per headless session, and a session is never reused across roles. A session that reviews its own work reads its own intent into the code, and a session that edited the plugin still runs the text it started with — skills and agents load at session start — so the implementer, the reviewer, and the acceptor are three sessions, and a fix is a fourth. In repo mode with `Standalone review: off` (4.6.0), or `auto` (4.7.0) when S3's own review does not trigger S3b, the reviewer session does not run and S3's own review — five fresh subagents — stands in for it; the three sessions hold whenever S3b runs, and always in plugin mode, where `off` and `auto` are each a settings stop. The runtime walk (4.7.0) is a further role with a session of its own, S4w, after the acceptor, for the same reason: it walks what the batch will release, not what a session that wrote or accepted it meant.

The autopilot's driver posts no completion message on the cross-session messaging socket. The socket documents only its auth line, and its message line format is undocumented; a driver that guessed the format would break silently on a release. `<tag>.exit`, written by the driver when the worker returns, is the completion artifact, and the idle notice is only the wake that tells the main session to read it.

The autopilot's workspace lives outside the repository — `~/Projects/_smoke/` by default, relocated by the `Workspace:` field of a brief's or spec's `## Autopilot` section — not under `.kenspc/`. A plugin-mode seed is a clone that cannot live inside the repository it clones, and the workers' logs and prompts are not the repository's to track.

### Writing Rules for Skill Content

- Use rationale-anchored business rules (Rule 2): frame each rule as "Why: ..." prose rather than command-style imperatives, so the model follows the intent of the rule, not just its letter
- Reasoning depth follows the session's effort level, with `effort:` frontmatter overrides only where a file needs more (currently two), not inline directive tokens
- Review summaries must list every change with the reason (what changed and why)
- Stack-agnostic: read project config files to detect tech stack, never assume a specific framework
- No plugin default language for task documents: `generate-task` writes the task document in the plan document's language unless the user asks otherwise, and only text carried into code artifacts follows `task-implementer`'s CODE ARTIFACTS LANGUAGE rule. A default of the plugin's own was ruled out when the rule was added (v3.6.0); the implementer copies task text into commits and documents, so the document's language is the user's choice, made with the plan. init-project's generated project files are a separate default, not an exception to this rule: English unless the user asks otherwise, with the reason written in the skill (they are read by agents and by team members who join later), while its conversation runs in the language its first message names — the user's (4.1.0)
- A commit subject a skill or agent gives is a default, adapted to the repository's commit convention, and the file that gives it says where that convention is found: the one the repository writes down (in the project's instruction files or its CONTRIBUTING), or, failing that, the pattern its recent commit subjects consistently share — init-project's lookup, applied everywhere in 4.4.1. A subject a worker or subagent commits under is adapted where that worker reads it (the autopilot's preamble § 6), since its prompt is all it reads. Why: a repository whose convention requires a scope from a fixed list rejects a subject such as `docs(plans):`, and task-implementer's unconditional "Use conventional commit format." overrode the convention in every repository that had one
- Evidence in a skill's or agent's Why is stated in its own words (what failed, and on which command), not cited as a dry-run record: skills and agents run as prompts in the user's project, where this repository's `docs/` does not exist, so the CHANGELOG entry cites the record instead (v3.6.0: regression-verifier's unmodified build, test, and lint rule)
- Where a skill stops to ask the user, it states in prose, at that question, what a session that cannot ask does instead, opening with "In a session that cannot ask (a system reminder to work without stopping), …" — the wording diagnose-bug, generate-plan's Open Questions exit, gap-check, approval stop, and existing-file question, generate-brief's question about what would settle a `needs prototype` entry, the prototype skill's gates, the autopilot skill's gates, and the init-project skill's gates and interview rounds share (generate-brief's Discovery Mode Detection is the older form of the same branch). A table that summarizes a skill's gates may repeat the outcomes but does not replace the sentence, since a table cell cannot open one. Why: one wording is one signal to test for, and a grep over the file with its line breaks joined finds every branch

## Development Workflow

### Test the plugin locally
```bash
claude --plugin-dir ./plugins/kenspc
```

Use `/reload-plugins` inside a session to pick up changes without restarting.

Edit the plugin's agent and skill files in a session started without
`--plugin-dir`, and keep `--plugin-dir` sessions for acceptance and smoke
runs. Why: a `--plugin-dir` session treats those files as the definitions it
is running. In the roadmap 9 batch (2026-09-24), auto mode's classifier gave
no verdict on every Edit to `plugins/kenspc/agents/*.md` and
`plugins/kenspc/skills/*/SKILL.md` in such a session and judged rewriting
them through Bash as a workaround, while documentation files were edited
normally; the same edits went through in a session without `--plugin-dir`.
That block is auto mode's classifier inside a `--plugin-dir` session; under
`--permission-mode bypassPermissions` there is no classifier, and the
autopilot's headless workers run that way — with `--plugin-dir` in plugin
mode — so a worker edits the plugin's files as it edits any other. A worker
sees a plugin edit only in the next session, which is why the autopilot's
review, acceptance, and fix are separate sessions.

### Validate plugin structure
```bash
# The plugin loader's own validation (marketplace manifest; plugin manifest,
# skills, agents, commands)
claude plugin validate --strict .
claude plugin validate --strict ./plugins/kenspc

# Verify all SKILL.md files have required frontmatter
grep -l "^name:" plugins/kenspc/skills/*/SKILL.md

# Every scripts/check-*.sh guard — cross-agent invariants and JSON validity;
# --self-test also runs every guard's mutation regression fixture
bash scripts/check-all.sh
bash scripts/check-all.sh --self-test
```

### Repository scripts/

Project-level shell scripts live in `scripts/` at the repo root:

- `check-all.sh` — wrapper that runs every other `check-*.sh` guard in
  main mode, reports PASS/FAIL per script, and prints `guards run: N`. The
  single entry point for pre-commit and pre-flight runs; new guard scripts
  are picked up automatically, no command list to update. With
  `--self-test` it then runs every guard's mutation fixture (see below) and
  ends with a `self-tests run: N` line. The release checklist pins both
  numbers.
- `check-review-agent-drift.sh` — guards the byte-identity invariant
  across the 5 review-angle agents (CONTEXT YOU WILL RECEIVE, ROLE,
  PREREQUISITES, CUSTOM INSTRUCTIONS, FILE COVERAGE, REPORT DELIVERY), and
  (4.9.0) that each one's frontmatter holds the standalone warning
  sentence, naming a reviewer without it.
- `check-canonical-dispatch.sh` — guards the byte-identity invariant on
  the `## Code Review Phase (unconditional)` canonical block between
  `task-review/SKILL.md` and `task-implement/SKILL.md`.
- `check-verdict-shared.sh` — guards the byte-identity invariant on the
  shared verdict-determination block (the `SPOT-CHECK` neutral note plus
  the involuntary-incomplete and intentional-skip clauses that map
  regression-verifier's row-3 Schema C states to a verdict) between
  `task-review/SKILL.md` and `task-implement/SKILL.md`. The surrounding
  PASS / FAIL / PARTIAL / BLOCKED bullets differ between the two skills by
  design and stay outside the markers.
- `check-code-craft-canonical.sh` — guards the byte-identity invariant
  on the canonical Simplicity First and Surgical Changes principle
  paragraphs across `shared/code-craft-principles.md` (authoritative)
  and the two writer agents (`task-implementer.md`, `code-fixer.md`)
  that inline them.
- `check-quality-reviewer-bullet-structure.sh` — guards the structural
  invariant on the two REVIEW CHECKLIST bullets in `quality-reviewer.md`
  (Over-engineering, Drive-by refactoring): each must enumerate exactly
  three numbered conditions gated by an `**all three**` qualifier.
- `check-notes-format-sync.sh` — guards that the per-task Implementation
  notes block's two sub-bullet labels (`Decisions:`, `Changes/tradeoffs:`)
  stay present in both the live agent (`task-implementer.md`, which
  prescribes the format) and the demonstrated example
  (`references/task-document-example.md`, which users copy from). An
  anchor-presence guard, not byte-identity — the surrounding prose differs
  by design (the agent describes the format, the example shows a filled-in
  instance); it catches a rename of either label in one file but not the
  other.
- `check-doc-sync-anchors.sh` — guards that the five planning-chain
  anchors, and the `## Checks run` heading (`task-implementer.md`,
  `task-implement/SKILL.md`; 4.9.0), stay present in every file that
  writes, checks, or renders them.
  Three carry the documentation path: `Documentation impact`
  (`generate-plan/SKILL.md`, `references/plan-document-example.md`,
  `plan-document-reviewer.md`, `generate-task/SKILL.md`,
  `diagnose-bug/SKILL.md`, `task-document-reviewer.md`), `Doc-sync`
  (`generate-task/SKILL.md`, `diagnose-bug/SKILL.md`,
  `references/task-document-example.md`, `task-document-reviewer.md`,
  `task-implementer.md`), and `Decisions needing a home`
  (`task-implementer.md`, `task-implement/SKILL.md`). Two carry the
  open-question path: `needs prototype` (`generate-brief/SKILL.md`,
  `generate-plan/SKILL.md`, `prototype/SKILL.md`), and the Prototype line,
  its whole literal the label, in `generate-brief/SKILL.md` and
  `prototype/SKILL.md`. An anchor-presence guard like
  `check-notes-format-sync.sh`: a rename in one file breaks the chain
  silently while every other check passes. It also holds one exact count:
  the prototype skill's leftovers command
  (`git -c core.quotePath=false status --porcelain --ignored=matching -uall -- <location>`)
  occurs exactly twice in `prototype/SKILL.md`, counted by occurrence —
  the start snapshot and the Exit compare their two lists path by path, so
  presence alone would miss one copy changed while the other stays.
  README.md and CLAUDE.md are deliberately outside it.
- `check-no-model-names.sh` — guards that no file under `skills/`,
  `agents/`, `commands/`, or `shared/` names or pins a specific Claude
  model. Three rules: frontmatter `model:` values must be `inherit`; no
  model family name as a whole word (case-insensitive); no `claude-`
  model-ID prefix (case-insensitive). The plugin's own `.claude-plugin`
  directory name, the official plugin marketplace's name
  (`claude-plugins-official`), and the three values of Claude Code's
  `instructionFiles` setting (`claude-md`, `claude-md-or-agents-md`,
  `claude-md-and-agents-md`), which init-project names verbatim, are
  stripped before the ID rule is tested, so a line carrying one of them
  and a real model ID is still reported. Skills and agents follow the
  session's model and effort; a model name in a prompt pins it to one
  generation. CHANGELOG and `docs/` are out of scope. The Claude in Chrome
  MCP server's identifier (`claude-in-chrome`, as in its tool names) holds
  `claude-` and a letter, which the ID rule reports, so the autopilot skill
  names that tool in prose only (4.7.0) — no exclusion was added to the
  guard, and an identifier spelled around the rule would defeat it.
- `check-run-contract.sh` — guards the run-directory contract: the
  `canonical:run-dir` block is byte-identical in the two SKILLs; its
  `git check-ignore` probe answers correctly against a CRLF `.gitignore`
  holding a blank line (the v3.5.0 Windows failure), with global git config
  masked; the
  `canonical:stats-line` template is byte-identical in the two SKILLs and
  `code-fixer.md`; the `canonical:rulings-grammar` block, the four
  `rulings.md` entry forms (FIX, FIX with the `; DEFER rest — <reason>`
  tail, DEFER, and NOT APPLICABLE, 4.7.0), is byte-identical in the two
  SKILLs, `code-fixer.md`, and `regression-verifier.md`, task-review's copy
  the reference, its self-test rewording the DEFER entry in each of the
  four in turn (check 7; the tail sits second in the block so that entry
  still occurs on one line of each carrier, and the tail is held by the
  byte-identity alone); the `canonical:second-round` block (4.7.0) is
  byte-identical in task-review's Step 7, the reference, and
  task-implement's Phase 2 Step 3, its self-test rewording the one-round
  limit sentence (`A review runs at most one second round:`) in each in
  turn (check 8); and the worked Schema B example in `code-fixer.md`
  recounts — its Per-angle Results table and statistics line agree with its
  rows (primary Source ID counts under the row's action, the rest as
  DEDUPED; actions classified by leading word, so `NOT APPLICABLE — <reason>`
  counts as NOT APPLICABLE; Source IDs `[REQBTFV]<n>`, code-fixer's `F`
  rows and the `V` regressions counted with the five angles, and the
  Per-angle Results table required to carry all seven rows, 4.7.0; the
  example holds one `F` row, and the self-test adds a `V1` row that must
  recount green); and the literal `change-set.md` is named in
  `task-review/SKILL.md`, `code-fixer.md`, `regression-verifier.md`, and
  `requirements-reviewer.md`, the pre-fix record's `pre-fix/index.txt`
  in `code-fixer.md` and `regression-verifier.md`, and the rulings file's
  `rulings.md` in `task-review/SKILL.md`, `task-implement/SKILL.md`,
  `code-fixer.md`, and `regression-verifier.md`, each file that does not
  name it reported, its self-test renaming it in each of the four in turn
  — and, since 4.7.0, `schema-c-1.md` in the same four and `suite-run.md`
  in the two SKILLs and `requirements-reviewer.md`, each renamed in turn
  by the self-test (check 5;
  `check-review-agent-drift.sh` carries the first and the last name to the
  other four reviewers); and, since 4.9.0, the heading
  `## Tests left for the verifier` in all five reviewers, which write it,
  and `regression-verifier.md`, which reads it, each renamed in turn by the
  self-test, every occurrence — all five reviewers rather than one, since
  the heading also sits in each reviewer's OUTPUT FORMAT, which
  `check-review-agent-drift.sh` does not hold, so the self-test copies
  eleven target files, the heading also required in each reviewer as a
  line of its own; and, since 4.9.0, Schema C's no-command forms,
  `no build command in the project` and `no lint command in the project`,
  whitespace-normalized in `regression-verifier.md`, which writes them,
  and the two SKILLs, whose verdict-shared bullet quotes them, each
  reworded in each carrier by the self-test (check 5); and the reviewer invariant sentence, extracted at run time
  from the ROLE section of `requirements-reviewer.md` and compared
  whitespace-normalized, is contained in its three copies — the plugin
  README, this file, and `task-review/SKILL.md`'s dispatch block (check 6;
  `check-canonical-dispatch.sh` carries the last to `task-implement`, and
  `check-review-agent-drift.sh` the reference to the other four
  reviewers). `--file PATH` runs the recount against a real `schema-b.md`
  from a run directory.
- `check-json.sh` — guards that `plugin.json`, `hooks.json`, and
  `marketplace.json` parse. It picks the interpreter itself — `python3`,
  `python`, `py`, then `node`, each probed by running it, which skips the
  Windows Store `python3` alias — so the same command works on macOS,
  Windows, and WSL2.
- `check-instruction-files.sh` — guards the definition of "the project's
  instruction files" (4.1.0). It takes the sentence from
  `shared/instruction-files.md` (from the line beginning
  `The project's instruction files are` through the first line ending in a
  period) and requires it, whitespace-normalized, in every carrier: each
  file under `skills/`, `agents/`, `commands/`, or `shared/` whose text
  names "instruction files" (case-insensitive; the setting name
  `instructionFiles` does not match), and the plugin README. Carriers are
  found rather than listed, so a file that starts using the term without
  the definition fails. The copies are inlined rather than referenced by
  path for the reason the writer agents inline the code-craft principles:
  every dispatch needs the definition, and its operative part — whether or
  not Claude Code loaded the files — is what an agent that skipped a
  runtime Read would get wrong.
- `check-autopilot-rails-hook.sh` — guards the autopilot worker rails
  hook (4.3.0) by feeding `hooks/scripts/autopilot-worker-rails.sh`
  fixtures and asserting each decision (deny: exit 2, empty stdout, a
  reason on stderr opening `autopilot rails:`, the text the autopilot
  preamble tells a worker to know a denial by, and naming `.trash` — or,
  for a field the hook cannot read, saying no permitted route applies and
  asking for the denial to be listed under `## Rail observations` before
  the worker ends, with no `.trash`; or, the `deny-ask` expectation for a
  `gh` or remote-git call (4.7.0), naming the main session, with neither
  `.trash` nor the no-route text; or, the `deny-suite` expectation for a
  listed suite command (4.10.0), naming the fixture wrapper path, with
  neither `.trash` nor the no-route text; allow and inert: exit 0, no
  stdout).
  The fixtures carry the field names and nesting of the live hook input
  Claude Code 2.1.283 sent for Bash, Write, Edit, and NotebookEdit calls,
  copied into the guard, since a hook that parses a harness-owned format
  goes stale silently (Plugin Design Lessons): every recursive-`rm`
  spelling and command position the hook lists (`$'…'` and `$"…"` words,
  backslash escapes, substitutions inside double quotes, and substitutions
  among the `rm`'s own words among them),
  quoted mentions and a comment, `rm` without a recursive flag and the
  other work it must not deny (`rm --force`, `rm -- -r`, a `<<-` body), an
  `rm` after a heredoc whose delimiter line comes and after a `<<` whose
  delimiter line never does, a Bash input over the length cap and one
  under it, a command of 12000 `$( )` substitutions under the cap and then
  `rm -rf`, a command word of 64000 characters with no slash and then
  `rm -rf`, one word of 32000 `<|` pairs and then `rm -rf`, and (4.7.0)
  8000 redirections `>a ` to a relative target in the repository and then
  `> /etc/x`, 999 distinct targets in distinct directories under `/tmp`
  and then `> /etc/x`, and 6000 distinct targets, over the hook's cap of
  1000, each of
  which must be denied in under 2.5 seconds, half the hook's
  timeout (timed, the hook under a CPU limit of that timeout, so a slow
  scan costs the guard seconds), a write inside each root for each file
  tool, outside every root, relative and `..`-escaping paths, symlinked
  roots and a `..` after
  a link collapsed as written, `~`, `~/`, and leading-space targets, a
  Windows drive-letter path left unjudged, a sibling sharing a root's
  prefix, no roots and root entries that are not absolute, an unreadable
  tool name, command, or path field, redirections (4.7.0) — denied:
  `> "$TMPDIR/../x"`, `>> ~/.claude/x`, `2> /etc/x`, and `&> ../outside`
  from the repository root, `> $HOME/.claude/x`, `>> ${HOME}/.claude/x`,
  `> ${TMPDIR}/../x`, `>| /etc/x`, `&>> /etc/x`, a glued `2>/etc/x`, a
  target after quoted text in the same
  word (`"hi">>~/.claude/x`, `'done'>/etc/x`), a single-quoted
  `> '/etc/x'`, `>& /etc/x`, `1>&/etc/x`, and `>> ~<user>/.claude/x` for
  the hook's user; allowed: `> /dev/null`, `> /dev/stderr`, `> /dev/fd/3`,
  `2>&1`, `>&2`, `> "$TMPDIR/x"`, `> out.txt` and a double-quoted
  `> "~/x"` in the repository, `> "$OTHER/x"` (not
  judged), a single-quoted `> 'out.txt'`, a `>` inside single quotes,
  and a `>` in a heredoc body, with
  the hook's `$TMPDIR` set to a fixture path the redirection fixtures'
  roots hold, so `$TMPDIR/..` lies outside every root on any machine, and
  its `$USER` to a fixture name —
  `gh` and remote git (4.7.0) — denied: `gh issue view 1`,
  `sudo gh issue view 1`, `git -C . fetch`, `git push`, `git pull`,
  `git ls-remote origin`, `git remote update`, `git -c x.y=z push`,
  `git --no-pager fetch`, `git --git-dir=.git fetch`, `git -P push`,
  `git --git-dir .git fetch`, `git --no-optional-locks fetch`, and a
  `git clone` of an https URL (also after `--depth 1`) or of a
  `user@host:path` or `host:path` source; allowed: a `git clone` of a
  local path,
  `git status`, `git --git-dir .git status`, `type gh`, `grep gh f`,
  `command -v gh`, and `which gh` —
  check (f) (4.10.0), with `decide()` exporting
  `KENSPC_AUTOPILOT_SUITE_COMMANDS` and `KENSPC_AUTOPILOT_SUITE_WRAPPER`
  per fixture, empty for every other fixture, and here
  `'dotnet test|pnpm test'` and a fixture wrapper path — denied:
  `dotnet test`, `dotnet test --filter X`, `cd a && dotnet test`,
  `sudo dotnet test`, `time pnpm test`, `echo x; pnpm test`,
  `$(dotnet test)`, and `/usr/local/share/dotnet/dotnet test`; allowed:
  `bash /w/suite-slots.sh run -- dotnet test`, `echo "dotnet test"`,
  `grep 'dotnet test' f`, `dotnet build`, `dotnet testx`, `pnpm install`,
  and a `dotnet test` in a heredoc body; inert: `dotnet test` with the
  commands variable empty and with the marker unset; and with
  `'./gradlew test|scripts/test.sh|CI=1 pnpm e2e|sudo -u ci make check'`
  listed — denied: `./gradlew test`, `gradlew test`, `./scripts/test.sh`,
  `CI=1 pnpm e2e`, `pnpm e2e`, and `make check`; allowed: `./gradlew build`
  — and every
  denied fixture again
  without the marker and with the marker `0`, each with the suite
  variables it was denied with. Main mode also checks that
  `hooks.json` registers the hook under PreToolUse with a matcher naming
  all four tools, since the fixtures run the script directly; and (4.5.0)
  that the literal `## Rail observations` occurs in the hook's
  unreadable-field reason (its `REASON_UNREADABLE=` assignment), in the
  preamble template of `skills/autopilot/SKILL.md` (the fenced block under
  `### The preamble`), and in that skill's `### Launch, wait, return`, and
  that the phrase `could not be read from the hook input` occurs in the
  hook — each unreadable-field fixture asserting it in the reason the hook
  printed — and in `SKILL.md`'s § Launch, wait, return and § The stop
  conditions, where the main session and stop condition 11 match on it — each
  missing literal reported per carrier (exit 1), a missing `SKILL.md`,
  assignment, template, or section exit 2. The hook
  runs under `/bin/bash` when it exists. Its self-test turns nine mutants red — the
  `rm` detection, the root check, and the marker check removed, the
  constant-time push removed (every word collected so far copied on each
  `$(`, which only the timed `$( )` fixture catches), and the
  last-character check removed (the whole word matched against `[<>]$` on
  each `|` or `&`, which any fixture may catch: the quoted and escaped `<`
  or `>` fixtures do, and the timed `<|` fixture only by a margin too thin
  to require), and the phrase reworded in the Bash command's
  unreadable-field reason alone (which only that fixture's reason
  assertion catches, the heading check staying green on the same copy),
  the redirection check removed (any fixture may catch it), and the `gh`
  check removed (the `gh issue view` fixture, which must be the first
  red), both 4.7.0, and the suite check (f) removed (the `dotnet test`
  fixture, which must be the first red; 4.10.0)
  — then runs the heading check on a copy of `SKILL.md` beside
  the hook copy and turns it red with six more mutants, each named with
  its carrier: the heading dropped from the hook's reason, the preamble
  template, and § Launch, wait, return, and the phrase dropped from the
  hook, § Launch, wait, return, and § The stop conditions (every
  occurrence in the carrier's region); a
  mutation that replaces nothing is exit 2 — and cleans up without a
  recursive `rm`.
- `check-autopilot-scripts.sh` — guards the autopilot's four helper
  scripts, `skills/autopilot/scripts/extract-acceptance.sh` and
  `zero-diff.sh` (4.6.0), `temp-candidates.sh` (4.8.0), and
  `suite-slots.sh` (4.10.0), by running them against fixtures built in its own
  `mktemp -d` directory, removed by its EXIT trap (the only recursive
  `rm`), with git's global and system configuration masked: for the
  extractor, single and double backticks, a backtick inside a
  double-backtick span, spans with and without the padding spaces, a label
  with a note, an `(optional)` case, a description case, a continuation
  line, `Acceptance: none`, no section, no field, inline text on the label
  line, an empty field, a code span that does not end the text, an unclosed
  one, a deeper-indented bullet, a second `## Autopilot` section, a CRLF
  spec, fenced code blocks before and inside the section (backtick and
  tilde fences, a longer fence around a shorter one, a column-0 `# `
  comment and `## ` line inside them, a backtick line whose info string
  holds a backtick, a column-0 fence inside the field, an unclosed fence;
  4.8.1), the wrong arguments, and an unreadable spec, each file's content
  and the printed counts asserted; for the zero-diff script, a path with a
  space, a changed path, an unchanged path, a path absent at the baseline,
  paths with a space before or after them, a path holding glob characters,
  a paths file with CRLF line ends, a long changed path named in full, an
  empty paths file, one of whitespace-only lines, a baseline that is not a
  commit, a last line without a newline, and a run from a subdirectory, each
  exit code and the `compared:` line asserted; for the temp-folder script,
  `--snapshot` over a hidden entry, a name with a space, and a symlink, and
  a sweep over a fixture temp folder whose before list holds a prefixed
  entry and a repository clone made before the batch, which must not be
  listed, while the self-test's directory, entries named by each of the
  three `$TMPDIR` spellings in the cmds dir (a `.corrected.cmd` included),
  and clones of the repository — of `.`, the entry itself, one made
  through a symlink — and of a seed must be, and another repository's
  clone, another track's prefix, a symlink, and a prefix only a `.case`
  file names must be left; the same sweep with no cmds dir; and seven usage
  errors, the listing and the `candidates:` line asserted; for the
  suite-slot wrapper, under `/bin/bash`, each fixture with a lock
  directory of its own under the work directory
  (`KENSPC_SUITE_SLOTS_DIR`), and the caller's suite variables unset
  first: two wrapped `sleep 3` holders at limit 2, one's holder file
  checked against the layout the wrapper's header fixes, and a third run with
  `--wait 1` busy (exit 75, the busy line naming both holders), then with
  `--wait 10` acquiring once a holder ends while no sample every 0.2
  seconds shows three holder files; limit 3 entering beside two live
  holders and limit 2 busy beside them; a wrapped `exit 3` returning 3 and
  leaving no holder file; a holder with a dead wrapper pid and a command
  pid alive under another start time, reclaimed; a holder whose command
  pid is a live `sleep`, kept; an ownerless mutex backdated with
  `touch -t`, reclaimed; a nested call beside a live holder at limit 1,
  run at once; the limit read from `KENSPC_AUTOPILOT_SUITE_LIMIT` alone,
  entering with no holder and busy beside one, with `--limit` taking
  precedence over it; a mutex whose owner pid is dead or runs under
  another start time, reclaimed, and one whose owner runs with its
  recorded start, kept; SIGTERM, SIGINT, or SIGHUP to a wrapped run,
  its holder file and its child gone; and usage errors (no `--`, no
  limit, limit `0` or `00`, limit `x`, a regular file as the lock
  directory, a `ps` that prints no start time), beside limit `01` read as
  1 — every background process waited
  for or killed by its pid, and again by the EXIT trap. Its self-test
  copies the four scripts and turns the guard red with eleven mutants written
  to separate files with `sed` — the padding stripping removed, the
  continuation joining removed, the fence tracking removed (4.8.1), the
  paths passed to `git diff` as one
  word, the before-list filter removed, the origin comparison removed, the
  symlink exclusion removed, and, for the wrapper (4.10.0), the count check
  made always true, the stale-holder reclaim removed, the release on exit
  removed, and the nesting check removed, the wrapper's four running the
  wrapper's fixtures alone — then green on the unmutated copies; a
  mutant that changes nothing is exit 2. Why the scripts have a guard:
  the first two each replaced a step every main session wrote by hand and
  got wrong — a stray backtick at each end of extracted commands, and a
  zero-diff check whose paths arrived as one zsh word and compared
  nothing — the extractor then read a column-0 `# ` comment inside a
  fenced script as the section's end, and the third decides what a recursive `rm` removes, where a
  rule that drifts toward listing too much fails silently; the fourth is
  the only bound on how many heavy suites the batches on a machine run at
  once, so a slot it gives away, a stale holder it keeps, a holder file it
  leaves, or a nested call it holds back fails silently too.

Twelve of the guards (`check-canonical-dispatch.sh`,
`check-verdict-shared.sh`, `check-code-craft-canonical.sh`,
`check-quality-reviewer-bullet-structure.sh`,
`check-notes-format-sync.sh`, `check-doc-sync-anchors.sh`,
`check-no-model-names.sh`, `check-run-contract.sh`, `check-json.sh`,
`check-instruction-files.sh`, `check-autopilot-rails-hook.sh`,
`check-autopilot-scripts.sh`) also
accept a `--self-test` flag
that runs
a mutation regression fixture in a temp workdir (positive path, negative
path on a deliberate mutation, restoration path on revert).
`bash scripts/check-all.sh --self-test` runs them all after the main-mode
pass: a guard implements a fixture when its dispatch matches the literal
`--self-test` argument, guards without one are listed as skipped, and the
closing `self-tests run: N` count makes a fixture that stops being detected
visible. Before v3.5.0 the self-tests ran only as separate release-checklist
commands, which is how five of them went unrun on macOS (BSD `sed -i`)
without anyone noticing.

Guards run under the bash 3.2 that macOS ships as well as under newer bash,
so they avoid bash 4 features such as associative arrays (`declare -A`):
`check-doc-sync-anchors.sh` keeps its anchor groups in one flat `label|path`
array for that reason, and its self-test copies its files from that same
array so the fixture cannot drift from the groups it tests. For the same
portability, a guard that escapes text in awk does it character by
character, not through `gsub`: POSIX reads two backslashes in a `gsub`
replacement as one, while the awk macOS ships writes both
(`check-autopilot-rails-hook.sh` builds its JSON fixtures this way).

Run `bash scripts/check-all.sh --self-test` before tagging any release.
Plain `bash scripts/check-all.sh` (main mode only) is the natural pre-commit
hook candidate when guard-target files change.

### Workflow artifacts under docs/

This repo dogfoods the plugin's own chain on itself: briefs land in
`docs/briefs/`, plan documents in `docs/plans/`, task documents in
`docs/tasks/`, and manual dry-run transcripts in `docs/dry-runs/`.
These artifacts are transient by convention — completed plan/task
documents are routinely deleted once shipped, so an empty directory or a
missing document referenced by an old commit message is normal, not a
gap. Three documents there are permanent: `docs/release-checklist.md`;
`docs/roadmap.md` (planned work — an item leaves it when it ships, and the
CHANGELOG records it from then on); and
`docs/dry-runs/README.md` (the dry-run label-vocabulary convention,
relocated out of `task-review/SKILL.md` in v3.4.2 because it governs
repo-internal QA artifacts, not plugin behavior).

### Durable documents

These are the repository's durable documents: the list a plan's
Documentation impact element is determined from, and the documents a
Doc-sync task keeps current. Transient artifacts under `docs/` (above) are
not on it.

| Document | Holds | Changes when |
|---|---|---|
| `README.md` | Marketplace overview: installation, the plugin list, one summary row per skill | A skill's summary changes (a new capability, a review-angle count), or a plugin is added |
| `plugins/kenspc/README.md` | The plugin's user documentation: skills, commands, agents, design principles, recommended workflow, run directory, known behavior | Any user-visible behavior of a skill, agent, command, or hook changes |
| `CLAUDE.md` | The maintainer contract for this repository: layout, conventions, review architecture, guard scripts, design lessons | A convention, an orchestration pattern, a guard, or a guard count changes |
| `plugins/kenspc/CHANGELOG.md` | Per-release record of what was added, changed, fixed, or removed | Every change that ships, under the next version's heading |
| `docs/release-checklist.md` | Pre-flight mechanical checks and the smoke checklist run before tagging | A guard or self-test count changes, or an entry point gains behavior the smoke test should exercise |
| `docs/roadmap.md` | Planned work not yet shipped | An item is planned, or ships (it then leaves the file) |
| `docs/dry-runs/README.md` | The dry-run report label-vocabulary convention | The dry-run report convention changes |
| `plugins/kenspc/references/plan-document-example.md` | An example plan document, the reference for `generate-plan`'s output | The plan format `generate-plan` produces changes |
| `plugins/kenspc/references/task-document-example.md` | An example task document users copy, including the Implementation notes block and the Doc-sync task | The task-document format `generate-task` writes or `task-implementer` reads changes. Its Task 6 is `generate-task`'s Doc-sync Task template filled in, so a change to that template changes Task 6 in the same commit |

### Release procedure

See [docs/release-checklist.md](docs/release-checklist.md) for the manual
smoke-test checklist that exercises plugin load + every entry-point's
first interactive surface. The pre-flight mechanical checks alone cannot
catch YAML parse breaks, missing path references, or other load-time
failures — the smoke checklist is the gap-closer.

## Plugin Design Lessons (Cumulative)

### Phase transitions rely on artifacts, not wording
Closure phrases ("complete", "landed", "wrapped up") are decorations.
The model treats Phase N+1 as triggered only when Phase N has produced
the artifact Phase N+1 reads as input. Anchor cross-phase contracts via
artifacts (files written, fields filled, dispatch CONTEXT blocks) — not
via closure-style natural language alone.
Background: v3.0.2 task-implement Phase 1 → Phase 2 sometimes failed to
auto-trigger because Phase 1 closure phrasing read as "session over" to
the orchestrator.

### Hooks are for environment constraints and post-hoc telemetry, not workflow state-machine guarding
Hooks fire on harness events (SessionStart, SessionEnd, Stop, etc.) and
do not observe SKILL-internal Phase state. Using a hook to enforce
"task-implement should be followed by task-review" leads to false-positive
blocking (Stop hook fires on legitimate Phase 1 → Phase 2 transitions
within a single SKILL run). Use hooks for:
- Environment setup / teardown
- Cross-session telemetry (post-hoc analysis)
- External system notifications
Avoid using hooks for SKILL-internal workflow guarantees.
Background: an early v3.0.3 design considered a Stop hook to force
task-review dispatch; rebatched into a SessionEnd telemetry log after
recognizing the misjudgement.

### Hook logic that depends on harness-private encodings goes stale silently
Hook scripts that parse harness-owned formats — the Write tool's path
separator convention, the transcript's slash-command encoding, the shell
expansion of the hook command string — have no stability contract. The
v3.0.3 probe results were correct when taken and wrong by v3.4.2: every
shipped hook was inert (backslash paths never matched forward-slash
globs; transcript patterns matched an encoding that does not occur;
unquoted `${CLAUDE_PLUGIN_ROOT}` split on the space in the plugin path).
Verify any such hook against live data — simulated tool-input JSON for
PreToolUse, real transcripts under `~/.claude/projects/` for
transcript-scanning hooks — and rely on the release smoke test, not
pre-flight greps, to catch this class: all four defects passed every
mechanical check.
Background: v3.4.2 hooks repair (2026-07-08); details in that CHANGELOG
entry.

### Git-ignored is not tool-ignored
An ignored directory inside the project is skipped by git and by nothing
else. Test runners, linters, and compilers walk the tree by their own
patterns, so a scratch file that looks like a test is a test. Name scratch
files outside those patterns, and treat a tool that trips over them as a
plugin defect, never as a reason to change the user's configuration.
Background: the batch A acceptance run,
`docs/dry-runs/batch-a-acceptance.md` § 8 — 68 probe files named
`*.test.ts` under the run's scratch directory made a bare `npm test` fail,
and code-fixer answered by adding a `vitest.config.ts` that excludes
`.kenspc/**` to the user's project.
