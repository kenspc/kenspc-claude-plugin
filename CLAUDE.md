# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Claude Code plugin marketplace containing structured software development workflow plugins. The primary plugin (`kenspc`) provides skills for plan-before-code workflows, requirement brief generation, answering a brief's open questions with throwaway prototypes, plan-to-task decomposition, bug diagnosis, task implementation with automatic code review, and project guide generation. Review phases use plugin agents (defined in `agents/`) — serial review agents for plan/guide/task documents, parallel MapReduce review agents for code. The brief, diagnose-bug, and prototype skills have no review phase (the brief is a discovery artifact, not a verifiable spec; a diagnosis has no plan to review its task document against, so the user confirms the task list instead; a prototype is discarded, and its answer is reviewed where a plan uses it).

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
│   ├── kenspc-brief.md
│   ├── kenspc-plan.md
│   ├── kenspc-task.md
│   ├── kenspc-guide.md
│   ├── kenspc-diagnose.md
│   ├── kenspc-prototype.md
│   ├── kenspc-task-implement.md
│   └── kenspc-task-review.md
├── hooks/
│   ├── hooks.json               # Hook event configuration
│   └── scripts/                 # Hook scripts (use ${CLAUDE_PLUGIN_ROOT})
├── references/                  # Example documents for user onboarding
├── shared/                      # Cross-skill resources (referenced via ${CLAUDE_PLUGIN_ROOT}/shared/)
│   ├── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan
│   └── code-craft-principles.md # Code-craft principles shared by task-implementer, code-fixer, quality-reviewer
├── skills/
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
│   └── task-review/
│       └── SKILL.md
├── README.md
└── LICENSE
```

## Skill Development Conventions

### File Structure

Each skill lives in `skills/<skill-name>/` with:
- `SKILL.md` — skill definition with YAML frontmatter (`name`, `description`, `version`, `argument-hint`) followed by structured phases/modes

Each plugin agent lives in `agents/<agent-name>.md` with YAML frontmatter (`name`, `description`, `tools`, `model`) followed by the agent's static system prompt. SKILLs dispatch agents by name through the Agent tool, passing a structured CONTEXT block as the dispatch prompt.

Commands live in `commands/` as `.md` files with YAML frontmatter (`name`, `description`, `argument-hint`, `disable-model-invocation: true`). Commands are explicit entry points only: since Claude Code merged commands and skills, both descriptions load into context and compete for natural-language auto-routing — the skill's description owns the trigger phrases, so each command keeps a one-line description and opts out of model invocation (v3.4.2).

Hooks are defined in `hooks/hooks.json` with scripts in `hooks/scripts/`.
Two hooks are registered: `PreToolUse` on `Write` → `remind-plan-skill.sh`
(plan-skill reminder — note it fires on every Write call, not only
plugin-related ones; its task and brief messages name every skill that
writes those directories: generate-task or diagnose-bug for `docs/tasks/`,
generate-brief, diagnose-bug, or prototype (which records an answer in an
existing brief) for `docs/briefs/`), and `SessionEnd` →
`session-end-telemetry.sh`
(post-hoc telemetry; background in Plugin Design Lessons). A former
`SessionStart` → `check-deps.sh` hook was removed in v3.4.2: its
ralph-loop dependency check was gutted by the v2 subagent refactor and
the empty husk had been running as a no-op since.

References live in `references/` as example documents (task format, plan format) to help users get started.

Shared resources live in `shared/` as cross-skill files (prompt frameworks, templates) referenced via `${CLAUDE_PLUGIN_ROOT}/shared/<file>.md`. Two entries today: `discovery-framework.md`, loaded by both `generate-plan` Phase 1 and `generate-brief` Phase 1 to provide a single source of truth for the discovery conversation pattern (five dimensions, four input clarity levels, exit conditions); and `code-craft-principles.md`, referenced by three agents (`task-implementer`, `code-fixer`, `quality-reviewer`) — it defines the Simplicity First and Surgical Changes principles with stack-specific C# / TypeScript diff examples, and explicitly does NOT define Goal-Driven Execution (covered by DONE-criteria in every SKILL), Think Before Coding for ad-hoc interactions (belongs in user-level or project-level CLAUDE.md), per-language style guides (delegated to project CLAUDE.md), or agent dispatch order / CONTEXT contracts (defined in the dispatching SKILL.md and each agent's header).

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

The per-skill `version` field is uniformly `3.0.0` across all eight skills and
denotes the v3 architecture generation, not a per-skill change counter. It is
deliberately decoupled from the plugin version in
`plugins/kenspc/.claude-plugin/plugin.json`, which is the authoritative version
and the only one bumped each release. It was set during the v3.0.0 rewrite and
is intentionally left unchanged on subsequent releases — syncing eight files
every release is churn that has historically drifted anyway. Bump it only on a
future architecture-generation change (a v4 rewrite), and bump all eight together
so the uniformity holds.

### Subagent Review Architecture

Skills use plugin agents (defined in `agents/`) as workers, dispatched via the
Agent tool. Three orchestration patterns:

**No review (generate-brief, diagnose-bug, prototype):**
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
with CLAUDE.md angle) — are the skill's own writing rules.

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
`Answer:` makes it settled, not the status word alone — and a plan that
relies on it cites the hash. A prototype runs outside the app; the one
in-app exception is a UI prototype that can only render inside the app,
located by the project's CLAUDE.md or by the user, with the typecheck green
against its baseline.

**Serial review (generate-plan, generate-task, generate-guide):**
Skill dispatches a single named agent (`plan-document-reviewer`,
`task-document-reviewer`, or `guide-document-reviewer`) that reviews all
angles in order in its own context. Each angle builds on fixes from the
previous one (cascade dependency). Agent body returns a structured change log.
`plan-document-reviewer` and `guide-document-reviewer` review four angles;
`task-document-reviewer` reviews three — Completeness (including Doc-sync
coverage), Execution Order, and Consistency with CLAUDE.md. The plan
reviewer's Completeness angle checks the plan's Documentation impact element.
Consistency with CLAUDE.md relies on subagents loading the project- and
user-level CLAUDE.md files themselves (`omitClaudeMd` false or absent loads
the user, project, and local CLAUDE.md files; source: the Claude Code
sub-agents reference, https://code.claude.com/docs/en/sub-agents, checked
2026-09-24); the
reviewer does not read `~/.claude/CLAUDE.md`, so an agent that opts out of
that loading loses the user-level rules the angle checks against.

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

**Parallel MapReduce (task-review):**
- Phase 1: 5 review agents, read-only on the working tree, dispatched in parallel
  (`requirements-reviewer`, `edge-case-reviewer`, `quality-reviewer`,
  `bug-reviewer`, `test-reviewer`) — one per angle. Angle 3
  (`quality-reviewer`) covers project conventions and existing patterns
  — rules written in CLAUDE.md / README and patterns in adjacent code —
  since v3.5; the file name is kept so the canonical dispatch block stays
  unchanged.
- Phase 2: `code-fixer` reads all 5 reports from the run directory,
  deduplicates, applies fixes, and writes the accountability list (Schema B)
  back to it.
- Phase 3: `regression-verifier` cross-checks the reports' issue IDs against
  the accountability list, verifies fixes, runs build/test/lint.

Since v3.5 the agents exchange reports through a per-run directory,
`<repo root>/.kenspc/runs/<run-id>/`, passed as the `RUN_DIR` CONTEXT key.
The orchestrating skill prepares it and, when `.kenspc/` is not yet
git-ignored, makes a one-time `.gitignore` commit. In a review without a
task document it then writes `change-set.md` (v3.7), the change set every
agent reads (see CONTEXT block contract). Each reviewer writes only
its own `angle-<n>.md`, and `code-fixer` only `schema-b.md`. Probe and
temporary files go in one scratch subdirectory per writer —
`scratch/angle-<n>/` for each reviewer, `scratch/code-fixer/`,
`scratch/regression-verifier/`, and `scratch/orchestrator/` for the main
session — and are named so the project's test runner does not collect them
(vitest and jest with their default patterns: no `.test.` or `.spec.`
segment in a file name, no file named `test.*` or `spec.*`, no `__tests__`
directory, and no `__mocks__` directory; a project-configured pattern or
another runner: what that configuration actually collects; any jest
project: still no `__mocks__` directory; a file that already carries a
collectable name is renamed, not deleted). So parallel writers never share
a file, and the main session relays paths rather than report text. Issue IDs (`R` / `E` / `Q` / `B` / `T` plus a sequence number)
and code-fixer's Source column let `regression-verifier` settle completeness
by comparing ID sets. Subagents cannot spawn other subagents; orchestration
stays at the skill (main session) level.

Every Agent dispatch in the skills sets `run_in_background: false`
(v3.5.1): each skill reads the agent's result in the same turn, while a
background call returns at once and is stopped when a headless session
exits. Foreground calls sent in one message still run in parallel, which is
how the five reviewers are dispatched. The parameter exists in headless
(`claude -p`) and SDK sessions; the interactive Agent tool (Claude Code
2.1.281) has no such parameter and runs subagents asynchronously, handing
each result back within the same turn.

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
against the Claude 5 generation 2026-09-26 — at each release, confirm
the override rationale below still holds (see the release checklist).

The `effort:` frontmatter in each file is authoritative — this prose
records the rationale, not a second copy of the values. Three files
override the session, each at `xhigh`:

- `task-implementer` — unattended long-horizon implementation. Nobody is
  watching to catch a run that stops short of the batch or skips a
  verification step, so the thoroughness has to come from the agent.
- `code-fixer` — also unattended: deduplication across five reports and
  a fix / build / test loop per finding, with no user checkpoint before
  regression-verifier runs.
- `generate-plan` — multi-round draft/challenge across project context;
  plan cost amortizes over downstream tasks (`max` through v3.4.x).

Everything else — the 5 review-angle agents, `regression-verifier`, the
3 document reviewers, and the seven other skills — runs at the session's
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
their inputs from it. It replaces the earlier `REVIEW_REPORTS` and
`ACCOUNTABILITY_LIST` keys: the file names inside the run directory are
fixed, so one path is the only value the orchestrator has to get right.

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

Three more byte-identity invariants bind `task-review/SKILL.md` and
`task-implement/SKILL.md`: the canonical `## Code Review Phase
(unconditional)` block (bounded by `<!-- canonical:dispatch:start/end -->`
markers), the shared verdict-determination bullets (bounded by
`<!-- canonical:verdict-shared:start/end -->` markers), and the run-directory
preparation (bounded by `<!-- canonical:run-dir:start/end -->` markers). The
Schema B statistics-line template (`<!-- canonical:stats-line:start/end -->`)
is byte-identical across those two SKILLs and `code-fixer.md`.

After editing any reviewer agent, `code-fixer.md`, or either of those two
SKILLs, run the matching guard script — `check-review-agent-drift.sh`,
`check-canonical-dispatch.sh`, `check-verdict-shared.sh`, or
`check-run-contract.sh`. After editing the reviewer invariant sentence in
the plugin README or this file, or the reviewers' ROLE, run
`check-run-contract.sh`: its check 6 holds those copies to the ROLE
sentence. What each
guard checks is documented once, in "Repository scripts/" below.

### Non-Goals

`shared/discovery-framework.md` stays in `shared/` and is NOT converted into a plugin agent. It is consumed by the main session at two call sites (generate-brief Phase 1, generate-plan Phase 1) as a structural guide for free-form discovery dialogue with the user — not as bounded delegated work. Subagent isolation would break the discovery phase's need for raw conversation context (the orchestrator must keep the full transcript to draft the brief or plan in Phase 2).

The run-directory preparation is written once, in the `canonical:run-dir` block of `task-review/SKILL.md` and `task-implement/SKILL.md`. `diagnose-bug` also prepares a run directory for its probes, and references that block — naming its markers, with the `diagnose-<name>` run-id suffix — rather than carrying a third copy; it points at generate-task's Doc-sync Task template the same way. A copy would have to be kept byte-identical by a guard, and a reference cannot drift. The block holds no mutation rule, so for a mutant used as evidence the skill points at the three-step mutation rule where it is written, the RUN_DIR bullet of `regression-verifier.md` (the reviewers and `code-fixer` carry the same rule). A change to that rule, or a move of it, updates the pointer in `diagnose-bug/SKILL.md` in the same commit.

The prototype skill references the same block the same way: its prototype's file names follow the naming rule of the block's Scratch space bullet, pointed at by the block's markers, and the skill carries no copy. A move of that rule updates the pointer in `prototype/SKILL.md` in the same commit.

The Open Questions entry grammar — the status words, the labels and their order, the answered and unsettled forms — is written once, in generate-brief's Writing rules for the brief, and generate-plan and the prototype skill point at it by path. The one piece the prototype skill repeats is the Prototype line (``Prototype: `<short hash>` — `<location>`, removed in the next commit; `git show <short hash>` ``), byte-identical to generate-brief's, so a change to that line in `generate-brief/SKILL.md` updates `prototype/SKILL.md` in the same commit. `check-doc-sync-anchors.sh` guards only the `needs prototype` status word across the three files, not this line.

### Writing Rules for Skill Content

- Use rationale-anchored business rules (Rule 2): frame each rule as "Why: ..." prose rather than command-style imperatives, so the model follows the intent of the rule, not just its letter
- Reasoning depth follows the session's effort level, with `effort:` frontmatter overrides only where a file needs more (currently three), not inline directive tokens
- Review summaries must list every change with the reason (what changed and why)
- Stack-agnostic: read project config files to detect tech stack, never assume a specific framework
- No plugin default language for task documents: `generate-task` writes the task document in the plan document's language unless the user asks otherwise, and only text carried into code artifacts follows `task-implementer`'s CODE ARTIFACTS LANGUAGE rule. A default of the plugin's own was ruled out when the rule was added (v3.6.0); the implementer copies task text into commits and documents, so the document's language is the user's choice, made with the plan
- Evidence in a skill's or agent's Why is stated in its own words (what failed, and on which command), not cited as a dry-run record: skills and agents run as prompts in the user's project, where this repository's `docs/` does not exist, so the CHANGELOG entry cites the record instead (v3.6.0: regression-verifier's unmodified build, test, and lint rule)
- Where a skill stops to ask the user, it states in prose, at that question, what a session that cannot ask does instead, opening with "In a session that cannot ask (a system reminder to work without stopping), …" — the wording diagnose-bug, generate-plan's Open Questions exit, gap-check, approval stop, and existing-file question, generate-brief's question about what would settle a `needs prototype` entry, and the prototype skill's gates share (generate-brief's Discovery Mode Detection is the older form of the same branch). A table that summarizes a skill's gates may repeat the outcomes but does not replace the sentence, since a table cell cannot open one. Why: one wording is one signal to test for, and a grep over the file with its line breaks joined finds every branch

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
  PREREQUISITES, CUSTOM INSTRUCTIONS, FILE COVERAGE, REPORT DELIVERY).
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
- `check-doc-sync-anchors.sh` — guards that the four planning-chain
  anchors stay present in every file that writes, checks, or renders them.
  Three carry the documentation path: `Documentation impact`
  (`generate-plan/SKILL.md`, `references/plan-document-example.md`,
  `plan-document-reviewer.md`, `generate-task/SKILL.md`,
  `diagnose-bug/SKILL.md`, `task-document-reviewer.md`), `Doc-sync`
  (`generate-task/SKILL.md`, `diagnose-bug/SKILL.md`,
  `references/task-document-example.md`, `task-document-reviewer.md`,
  `task-implementer.md`), and `Decisions needing a home`
  (`task-implementer.md`, `task-implement/SKILL.md`). One carries the
  open-question path: `needs prototype` (`generate-brief/SKILL.md`,
  `generate-plan/SKILL.md`, `prototype/SKILL.md`). An anchor-presence
  guard like `check-notes-format-sync.sh`: a rename in one file breaks the
  chain silently while every other check passes. README.md and CLAUDE.md
  are deliberately outside it.
- `check-no-model-names.sh` — guards that no file under `skills/`,
  `agents/`, `commands/`, or `shared/` names or pins a specific Claude
  model. Three rules: frontmatter `model:` values must be `inherit`; no
  model family name as a whole word (case-insensitive); no `claude-`
  model-ID prefix (case-insensitive). The plugin's own `.claude-plugin`
  directory name is stripped before the ID rule is tested, so a line
  carrying both is still reported. Skills and agents follow the session's
  model and effort; a model name in a prompt pins it to one generation.
  CHANGELOG and `docs/` are out of scope.
- `check-run-contract.sh` — guards the run-directory contract: the
  `canonical:run-dir` block is byte-identical in the two SKILLs; its
  `git check-ignore` probe answers correctly against a CRLF `.gitignore`
  holding a blank line (the v3.5.0 Windows failure), with global git config
  masked; the
  `canonical:stats-line` template is byte-identical in the two SKILLs and
  `code-fixer.md`, and the worked Schema B example in `code-fixer.md`
  recounts — its Per-angle Results table and statistics line agree with its
  rows (primary Source ID counts under the row's action, the rest as
  DEDUPED; actions classified by leading word, so `NOT APPLICABLE — <reason>`
  counts as NOT APPLICABLE); and the literal `change-set.md` is named in
  `task-review/SKILL.md`, `code-fixer.md`, `regression-verifier.md`, and
  `requirements-reviewer.md`, and the pre-fix record's `pre-fix/index.txt`
  in `code-fixer.md` and `regression-verifier.md` (check 5;
  `check-review-agent-drift.sh` carries the first name to the other four
  reviewers); and the reviewer invariant sentence, extracted at run time
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

Nine of the guards (`check-canonical-dispatch.sh`,
`check-verdict-shared.sh`, `check-code-craft-canonical.sh`,
`check-quality-reviewer-bullet-structure.sh`,
`check-notes-format-sync.sh`, `check-doc-sync-anchors.sh`,
`check-no-model-names.sh`, `check-run-contract.sh`, `check-json.sh`) also
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
array so the fixture cannot drift from the groups it tests.

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
