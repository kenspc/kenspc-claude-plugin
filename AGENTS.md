# AGENTS.md

Maintainer instructions for this repository. CLAUDE.md imports this file and
adds only what is specific to Claude Code.

## Project overview

A Claude Code plugin marketplace. Its primary plugin, `kenspc`
(`plugins/kenspc/`), provides skills for project initialization, briefs,
plans, prototypes, task decomposition, bug diagnosis, guides, and task
implementation with automatic code review; its autopilot skill runs one batch
of that chain unattended through headless sessions. Each SKILL.md and agent
file is the authority for its own behavior, and the plugin README documents
it for users.

The `description` of each entry in `.claude-plugin/marketplace.json`'s
`plugins` list is the registry-list summary (one short sentence); the
`description` in `plugins/<name>/.claude-plugin/plugin.json` is the full
plugin metadata loaded after the user selects the plugin. The two are layered
on purpose — the summary is typically the full description's first sentence —
so do not sync them blindly. The marketplace manifest also has its own
top-level `description`, which `claude plugin validate --strict` warns
without.

## Orchestration patterns

- No review: generate-brief, diagnose-bug, prototype, and init-project; each
  SKILL.md says why.
- Serial review: generate-plan, generate-task, and generate-guide dispatch one
  document-reviewer agent that reviews its angles in order.
- Parallel MapReduce: task-review, and task-implement's review — five
  review-angle agents, then `code-fixer`, then `regression-verifier`,
  exchanging reports through `.kenspc/runs/<run-id>/`.
- Sessions, not agents: the autopilot runs one headless `claude -p` session
  per role.

The five review-angle agents are standalone-safe; the six others are
orchestration-only, their first description sentence `INTERNAL: ...`.
Each reviewer is read-only on the working tree and writes only under
`RUN_DIR`: its report at `RUN_DIR/angle-<n>.md`, and probe and temporary
files under `RUN_DIR/scratch/angle-<n>/`.

## Editing skill and agent content

These apply to files under `plugins/kenspc/skills/`, `agents/`, `shared/`,
and `commands/`.

- Use rationale-anchored business rules (Rule 2): frame each rule as
  "Why: ..." prose rather than command-style imperatives, so the model
  follows the intent of the rule, not just its letter.
- Review summaries must list every change with the reason (what changed and
  why).
- Stack-agnostic: read project config files to detect the tech stack, never
  assume a specific framework.
- No plugin default language for task documents: `generate-task` writes the
  task document in the plan document's language unless the user asks
  otherwise, and only text carried into code artifacts follows
  `task-implementer`'s CODE ARTIFACTS LANGUAGE rule. Why: the implementer
  copies task text into commits and documents, so the document's language is
  the user's choice, made with the plan. init-project's generated project
  files are a separate default, not an exception to this rule: English unless
  the user asks otherwise, with the reason written in the skill (they are read
  by agents and by team members who join later), while its conversation runs
  in the language its first message names — the user's.
- A commit subject a skill or agent gives is a default, adapted to the
  repository's commit convention, and the file that gives it says where that
  convention is found: the one the repository writes down (in the project's
  instruction files or its CONTRIBUTING), or, failing that, the pattern its
  recent commit subjects consistently share. A subject a worker or subagent
  commits under is adapted where that worker reads it (the autopilot's
  preamble § 6), since its prompt is all it reads. Why: a repository whose
  convention requires a scope from a fixed list rejects a subject such as
  `docs(plans):`.
- Evidence in a skill's or agent's Why is stated in its own words (what
  failed, and on which command), not cited as a dry-run record. Why: skills
  and agents run as prompts in the user's project, where this repository's
  `docs/` does not exist, so the CHANGELOG entry cites the record instead.
- Where a skill stops to ask the user, it states in prose, at that question,
  what a session that cannot ask does instead, opening with "In a session that
  cannot ask (a system reminder to work without stopping), …".
  generate-brief's Discovery Mode Detection is the older form of the same
  branch. A table that summarizes a skill's gates may repeat the outcomes but
  does not replace the sentence, since a table cell cannot open one. Why: one
  wording is one signal to test for, and a grep over the file with its line
  breaks joined finds every branch.
- All file references in hooks and commands use `${CLAUDE_PLUGIN_ROOT}`;
  never hardcode an absolute path.
- A command keeps a one-line description and sets
  `disable-model-invocation: true`. Why: command and skill descriptions both
  load into context and compete for auto-routing; the skill's description
  owns the trigger phrases.

### Skills

- A file under `skills/<name>/templates/` is never named `CLAUDE.md` or
  `AGENTS.md`. Why: a session working in this repository would load a
  `CLAUDE.md` as a memory file, and an `AGENTS.md` too wherever Claude Code
  reads AGENTS.md itself.
- The per-skill `version` stays `3.0.0` in all ten skills; bump it only on an
  architecture-generation rewrite, all ten together. The plugin version in
  `plugin.json` is the one bumped each release.
<!-- The field denotes the v3 architecture generation, not a change counter.
Syncing ten files every release is churn that had drifted anyway. Plugin
4.0.0 was a version choice, not a rewrite, so the field stayed 3.0.0. -->
- A dispatching SKILL.md constructs exactly the CONTEXT keys the agent
  declares in its "CONTEXT YOU WILL RECEIVE" section.
- The top-level-session bullet of task-review and task-implement sits in each
  skill's Prerequisites, outside the canonical blocks, so the two bullets
  differ where the skills do.
- `shared/discovery-framework.md` stays a shared file and is not converted
  into an agent. Why: the discovery dialogue needs the raw conversation, and
  the main session keeps the full transcript to draft the brief or plan.
- Written once and referenced, never copied: the run-directory preparation
  (task-review's and task-implement's `canonical:run-dir` block, which
  diagnose-bug and prototype reference by its markers), the Open Questions
  entry grammar (generate-brief's Writing rules), and the `## Autopilot`
  section grammar (the autopilot skill, read by generate-plan by path). A
  move or rename of one of these updates every pointer to it in the same
  commit — including those in `agents/task-implementer.md` and the mutation
  rule's pointer in `diagnose-bug/SKILL.md`. The one repeated piece, the
  Prototype line, stays byte-identical in `generate-brief/SKILL.md` and
  `prototype/SKILL.md`.
- Name scratch files outside the patterns test runners, linters, and
  compilers collect; a tool that trips over them is a plugin defect, never a
  reason to change the user's configuration.
<!-- Git-ignored is not tool-ignored. Batch A acceptance: 68 probe files
named *.test.ts under the run's scratch directory made a bare npm test fail,
and code-fixer answered by adding a vitest.config.ts that excluded .kenspc/**
to the user's project. -->

### Autopilot

- No agent teams: one role per headless session, never reused across roles.
  Why: a session that reviews its own work reads its own intent into the
  code, and a session that edited the plugin still runs the text it started
  with.
- The driver posts no completion message on the cross-session socket;
  `<tag>.exit` is the completion artifact. Why: the socket's message format
  is undocumented, and a guessed one would break silently on a release.
- The workspace lives outside the repository (`~/Projects/_smoke/` unless
  `Workspace:` relocates it), not under `.kenspc/`. Why: a plugin-mode seed
  is a clone, which cannot live inside the repository it clones.

### Agents

- Writer agents (`task-implementer.md`, `code-fixer.md`) use ALL-CAPS section
  headers without hyphens. `CODE-CRAFT PRINCIPLES` keeps its hyphen as a
  compound adjective and carries an HTML guard comment on the line above;
  normalizing it updates this paragraph in the same commit. code-fixer's
  `PER-ISSUE OUTPUT CONTRACT` predates the convention and has no guard
  comment.
- The `effort:` frontmatter is authoritative; the plugin README's Effort
  levels section records the rationale.
- task-document-reviewer relies on the subagent loading `~/.claude/CLAUDE.md`
  for the user-level rules its Consistency angle checks, and does not read
  that file itself.
<!-- omitClaudeMd false or absent loads the user, project, and local CLAUDE.md
files: https://code.claude.com/docs/en/sub-agents, checked 2026-09-24. -->
- The five review-angle agents share CONTEXT YOU WILL RECEIVE, ROLE,
  PREREQUISITES, CUSTOM INSTRUCTIONS, FILE COVERAGE, and REPORT DELIVERY.
  Apply a change to all five; drift between them is a bug.
- task-review and task-implement share four byte-identical canonical blocks
  (`canonical:dispatch`, `verdict-shared`, `run-dir`, `second-round`); the
  second-round text is skill-neutral so one copy reads true in both. A
  carrier that stops stating the `canonical:rulings-grammar` block points at
  task-review's Step 5 by path and holds no copy, and `check-run-contract.sh`'s
  check 7 and its self-test drop that carrier in the same commit.

### Hooks

- Hooks are for environment constraints and post-hoc telemetry, not for
  guarding a skill's workflow: they fire on harness events and cannot see a
  skill's phase. The autopilot worker rails hook is an environment
  constraint.
- A hook that parses a harness-owned format (tool-input JSON, transcript
  encoding, the hook command's shell expansion) is verified against live data
  — simulated tool-input JSON, or real transcripts under `~/.claude/projects/`
  — and by the release smoke test, since no mechanical check catches it.
<!-- v3.0.3 considered a Stop hook to force task-review; it blocked legitimate
phase transitions and became SessionEnd telemetry. By v3.4.2 every shipped
hook was inert: backslash paths, a transcript encoding that does not occur,
and an unquoted ${CLAUDE_PLUGIN_ROOT} split on a space. All four defects
passed every mechanical check. -->

### Guard scripts

Guards run under the bash 3.2 that macOS ships as well as newer bash, so they
avoid bash 4 features such as `declare -A`. A guard that escapes text in awk
does it character by character, not through `gsub`: POSIX reads two
backslashes in a `gsub` replacement as one, while the awk macOS ships writes
both.

## Checks

Run `bash scripts/check-all.sh` before committing a change under `plugins/`
or `scripts/`. Each `scripts/check-*.sh` states in its header what it checks;
`check-all.sh` runs them all, and `--self-test` also runs each guard's
mutation fixture. Before tagging a release:

```bash
claude plugin validate --strict .
claude plugin validate --strict ./plugins/kenspc
bash scripts/check-all.sh --self-test
```

## Workflow artifacts under docs/

This repo dogfoods the plugin's chain: briefs land in `docs/briefs/`, plans
in `docs/plans/`, task documents in `docs/tasks/`, and dry-run transcripts in
`docs/dry-runs/`. These are transient — completed plans and task documents
are deleted once shipped, so an empty directory or a missing document named
by an old commit is normal. Three documents are permanent:
`docs/release-checklist.md`, `docs/roadmap.md` (an item leaves it when it
ships), and `docs/dry-runs/README.md`.

## Durable documents

The list a plan's Documentation impact element is determined from, and the
documents a Doc-sync task keeps current.

| Document | Holds | Changes when |
|---|---|---|
| `README.md` | Marketplace overview: installation, the plugin list, one summary row per skill | A skill's summary changes (a new capability, a review-angle count), or a plugin is added |
| `plugins/kenspc/README.md` | The plugin's user documentation: skills, commands, agents, design principles, recommended workflow, run directory, known behavior | Any user-visible behavior of a skill, agent, command, or hook changes |
| `AGENTS.md` | The maintainer contract for this repository: orchestration overview, editing rules, checks, durable documents | A convention, an orchestration pattern, or a guard changes |
| `CLAUDE.md` | The `@AGENTS.md` import and the rules specific to Claude Code sessions | A Claude Code-specific rule changes |
| `plugins/kenspc/CHANGELOG.md` | Per-release record of what was added, changed, fixed, or removed | Every change that ships, under the next version's heading |
| `docs/release-checklist.md` | Pre-flight mechanical checks and the smoke checklist run before tagging | A guard or self-test count changes, or an entry point gains behavior the smoke test should exercise |
| `docs/roadmap.md` | Planned work not yet shipped | An item is planned, or ships (it then leaves the file) |
| `docs/dry-runs/README.md` | The dry-run report label-vocabulary convention | The dry-run report convention changes |
| `plugins/kenspc/references/plan-document-example.md` | An example plan document, the reference for `generate-plan`'s output | The plan format `generate-plan` produces changes |
| `plugins/kenspc/references/task-document-example.md` | An example task document users copy, including the Implementation notes block and the Doc-sync task | The task-document format `generate-task` writes or `task-implementer` reads changes. Its Task 6 is `generate-task`'s Doc-sync Task template filled in, so a change to that template changes Task 6 in the same commit |

## Release procedure

Follow `docs/release-checklist.md`: the pre-flight checks, then the smoke
checklist, which catches load-time failures the mechanical checks cannot.
