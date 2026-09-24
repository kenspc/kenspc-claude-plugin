# Plan: Scratch probes that no test runner collects (roadmap items 9 and 2)

Target: this repository (`kenspc` plugin), on top of main after batch A
(`90febd8` or later). Ships with 3.6.0; roadmap item 9 is required before
tagging, and item 2 is folded in because both edit the same sentences. No
version bump in this batch; the CHANGELOG entry extends `## 3.6.0 — unreleased`.

This document is the complete specification. The rulings it depends on are
in [Design decisions](#design-decisions); the implementing session applies
them and does not reopen them.

## Objective

Make the run directory's scratch space safe to leave behind:

1. Every file an agent writes under `RUN_DIR/scratch/` is named so the
   project's test runner does not collect it, including copies of test files.
2. `code-fixer`, `regression-verifier`, and the orchestrating session each
   have their own scratch subdirectory, and "starting over" means a new
   subdirectory, never a delete.
3. Pollution that still happens is loud: `regression-verifier` runs the
   project's test command unmodified and fails the run when scratch files
   break it; `code-fixer` never edits the project's configuration to make
   room for the plugin's files.

**In scope:** the scratch rule in the five reviewers' ROLE section, the two
worker agents' RUN_DIR bullets, `regression-verifier`'s test check, the
`canonical:run-dir` Scratch bullet in both review skills, the README,
CLAUDE.md (run-dir paragraph and one new Plugin Design Lesson), the release
checklist's run-directory check, the CHANGELOG, and the roadmap.

**Out of scope:** the reviewer invariant sentence (four places; roadmap
item 7 covers guarding it) — it stays byte-identical everywhere; the
canonical dispatch block, which carries only that sentence; a new guard
script (ruling M5); moving scratch outside the project; any other roadmap
item; batches B and C.

## Background

The batch A acceptance run (`docs/dry-runs/batch-a-acceptance.md` § 8)
showed the 3.5.1 scratch convention failing on a plain TypeScript project:

- 68 probe files named `*.test.ts` under `RUN_DIR/scratch/` — single probes
  and whole copies of the `test/` tree used for mutation checks — were
  collected by vitest's default `**/*.{test,spec}.?(c|m)[jt]s?(x)`, so a
  bare `npm test` failed while the project's own tests passed.
- `regression-verifier` reported row 3 as PASS by narrowing the command to
  `npx vitest run --dir test`, which hid the pollution behind a green row.
- In the second round `code-fixer` "fixed" it by adding a `vitest.config.ts`
  to the user's project that excludes `.kenspc/**` — the plugin changing the
  user's project to accommodate its own files.
- Five agents each worked around the collision differently (`*.mts`,
  `*.probe.ts`, `probe.check.ts` beside a private config, or not at all).

`.gitignore` keeps the run directory out of git. Nothing keeps it out of the
tools that walk the tree by their own patterns.

## Design decisions

Rulings made by the maintainer on 2026-09-24.

| # | Question | Ruling |
|---|---|---|
| M1 | Roadmap item 2 (orchestrator bound by the scratch rule; reset = new subdirectory; `scratch/<agent>/` for code-fixer and regression-verifier) edits the same sentences as item 9. | Fold item 2 into this batch: one pass through the byte-identity guards. Both items leave the roadmap when this ships. |
| M2 | "Use an extension no runner collects, such as `.txt`" cannot hold for a probe that executes. | The rule is about the runner's collection pattern, not an extension: a scratch path must not carry the project runner's test markers. vitest and jest: no `.test.` or `.spec.` segment in the file name and no `__tests__` directory (jest's default `testMatch` also collects `**/__tests__/**`). Other runners: read the project's config (pytest `test_*.py` / `*_test.py`, Go `_test.go`). Safe examples: `probe.mts`, `probe-2.probe.ts`, `.txt` for anything that need not run. |
| M3 | Copies of the whole `test/` tree (mutation checks by test-reviewer, mutants by code-fixer and regression-verifier). | Option (a): rename test files as they are copied so the copy carries no collectable name, and run them through a runner config kept in the agent's scratch directory whose `include` matches the renamed files. Rejected: (b) src-only copies driven by runner `root`/`alias` tricks (runner-specific); (c) hiding copies under a `node_modules` directory (JavaScript-only, misleading name). |
| M4 | The verifier narrowed the test command and reported PASS; the fixer edited project config. | `regression-verifier` runs the project's configured test command unmodified; a failure caused only by files under `RUN_DIR/scratch` is row-3 FAIL naming the files — pollution must be loud. `code-fixer` never edits the project's configuration (runner config, ignore files, tsconfig, package scripts) to accommodate files the plugin wrote; it may verify its own fixes with a narrowed command but says so in its reply. |
| M5 | A new guard? | No. The two byte-identical carriers are already guarded (`check-review-agent-drift.sh`, `check-run-contract.sh`); the code-fixer and regression-verifier sentences are not cross-file anchors. The falsifiable check is the release checklist's run-directory check (Step 5.3). |
| M6 | CLAUDE.md lesson. | Add a Plugin Design Lesson: git-ignored is not tool-ignored. |
| M7 | Acceptance. | One macOS run of `/kenspc-task-review` on a vitest project (Testing Strategy). No Windows run, no negative cases. |

### Standing constraints

- Rationale-anchored prose ("Why: …"); no imperatives in capitals, no
  effort or reasoning tokens, no model names (`check-no-model-names.sh`).
- The five reviewers' ROLE sections stay byte-identical to each other; the
  `canonical:run-dir` block stays byte-identical between the two skills and
  keeps the phrase `.kenspc/runs/probe` that `check-run-contract.sh`'s
  self-test targets. The canonical dispatch, verdict-shared, stats-line, and
  code-craft blocks are untouched.
- The reviewer invariant sentence ("Each reviewer is read-only on the
  working tree and writes only under `RUN_DIR`: …") is not edited anywhere;
  the new rule is added after it.
- No new CONTEXT keys; `effort:` frontmatter unchanged; per-skill
  `version: 3.0.0` unchanged.

## Fixed strings

| Item | Exact form |
|---|---|
| Scratch layout | `RUN_DIR/scratch/angle-<n>/` (each reviewer, unchanged), `RUN_DIR/scratch/code-fixer/`, `RUN_DIR/scratch/regression-verifier/`, `RUN_DIR/scratch/orchestrator/` (the main session) |
| Reset | a new subdirectory under the agent's own scratch directory (for example `scratch/angle-5/2/`); never a delete |
| Collection markers, vitest and jest | no `.test.` or `.spec.` segment in a file name; no `__tests__` directory |
| Checklist probe | `find <RUN_DIR>/scratch \( -name '*.test.*' -o -name '*.spec.*' -o -path '*/__tests__/*' \)` prints nothing |

## Implementation Steps

### Phase 1: The rule where the files are written

**Step 1.1: Reviewers' ROLE section (five files, identical)**

- Files: `plugins/kenspc/agents/{requirements,edge-case,quality,bug,test}-reviewer.md`,
  ROLE section, after the existing "Why: code-fixer is the single agent …"
  paragraph. The invariant sentence and that paragraph are unchanged.
- Add one paragraph, in substance: name every file under your scratch
  directory so the project's test runner will not collect it — for vitest
  and jest no `.test.` or `.spec.` in the name and no `__tests__` directory,
  for other runners whatever their configuration collects. `probe.mts`,
  `probe-2.probe.ts`, and a `.txt` copy are safe; `probe.test.ts` is not,
  and a copied `test/` tree keeps its collectable names unless you rename
  them as you copy. A probe that has to execute runs as a plain script, or
  through a runner config kept in your scratch directory that includes only
  your probes. To start over, make a new subdirectory under your scratch
  directory rather than deleting. Why: the run directory is git-ignored,
  not tool-ignored; a runner walking the tree collects the probes, the
  project's own test command fails, and a fixer that then edits the
  project's test configuration has changed the user's project to make room
  for the plugin's files.
- Done when: the paragraph is byte-identical in all five files and
  `bash scripts/check-review-agent-drift.sh` exits 0.
- Why: the reviewers write most of the probes, and their ROLE section is the
  guarded, shared place for the write rules.

**Step 1.2: code-fixer and regression-verifier RUN_DIR bullets**

- Files: `plugins/kenspc/agents/code-fixer.md` and
  `plugins/kenspc/agents/regression-verifier.md`, the `RUN_DIR` bullet under
  CONTEXT YOU WILL RECEIVE.
- Each agent's scratch directory becomes `RUN_DIR/scratch/code-fixer/` and
  `RUN_DIR/scratch/regression-verifier/` respectively (ruling M1). The bullet
  carries the same naming, execution, and reset rule as Step 1.1, in its own
  words (these two files are not byte-identity carriers).
- `code-fixer` additionally: never modify the project's configuration —
  test-runner config, ignore files, `tsconfig`, package scripts — to
  accommodate files the plugin wrote under the run directory; if the
  project's test command fails only because of scratch files, say so in the
  reply and in `schema-b.md`'s prose, naming the files, and verify fixes with
  a narrowed command if needed. Why: a configuration change made for the
  plugin's own files is a change to the user's project that the user did not
  ask for, and it hides the pollution instead of removing it.
- Done when: both bullets state the new directory, the rule, and (for
  code-fixer) the no-configuration-edit rule with its Why;
  `bash scripts/check-run-contract.sh` still exits 0 (the worked Schema B
  example is untouched).
- Why: these two agents copy whole test trees for mutants; they need the
  rule as much as the reviewers do.

**Step 1.3: regression-verifier's test check**

- File: `plugins/kenspc/agents/regression-verifier.md`, VERIFICATION CHECKS
  item 3.
- Add: run the project's test command as the project configures it
  (`package.json` scripts, CLAUDE.md, the solution or `pytest` config) with
  no path filter or exclude added. When the run fails only because of files
  under `RUN_DIR/scratch`, record FAIL with the offending paths in the
  Detail cell; a narrowed re-run may be added to Detail as information but
  does not change the Result. Why: the batch A acceptance run passed row 3
  on `--dir test` while the project's own `npm test` failed; a green row
  that hides the plugin's pollution is worse than a red one.
- Done when: the clause is present with its Why, the three existing run
  states (full clean, involuntarily incomplete, intentionally skipped) are
  unchanged, and `bash scripts/check-verdict-shared.sh` exits 0 (the
  verdict-shared block references item 3 but is not edited).
- Why: the verifier is the run's last honest reporter; this turns the
  gotcha into a loud failure until the naming rule makes it impossible.

### Phase 2: The rule at the orchestrator

**Step 2.1: `canonical:run-dir` Scratch bullet (two files, identical)**

- Files: `plugins/kenspc/skills/task-review/SKILL.md` and
  `plugins/kenspc/skills/task-implement/SKILL.md`, the "Scratch space"
  bullet inside `<!-- canonical:run-dir:start/end -->`.
- Rewrite the bullet: probe files, copies, and other temporary files go
  under `RUN_DIR/scratch/` — each reviewer in `scratch/angle-<n>/`,
  code-fixer in `scratch/code-fixer/`, regression-verifier in
  `scratch/regression-verifier/`, and the orchestrating session itself in
  `scratch/orchestrator/` when it runs a probe of its own. Every file there
  is named so the project's test runner does not collect it (vitest and
  jest: no `.test.` or `.spec.` segment, no `__tests__` directory; other
  runners: their configured pattern), and starting over means a new
  subdirectory, never a delete. Keep the existing Why about `rm -rf` and
  add the tool-ignored Why in one sentence.
- Done when: the block is byte-identical in both skills, still contains
  `.kenspc/runs/probe`, and `bash scripts/check-run-contract.sh --self-test`
  exits 0.
- Why: the block is the orchestrator's statement of the convention; the
  agents' sections and this bullet must tell the same story.

### Phase 3: Documentation

**Step 3.1: Plugin README**

- File: `plugins/kenspc/README.md`, Run directory section: the layout tree
  gains `code-fixer/`, `regression-verifier/`, and `orchestrator/` under
  `scratch/`; the probe-files bullet states the naming rule, the reset
  rule, and that no agent edits the project's configuration for the
  plugin's files; the invariant paragraph above the Installation section is
  unchanged.
- Done when: the section agrees with Steps 1.1–2.1.

**Step 3.2: CLAUDE.md**

- File: `CLAUDE.md`. The "Since v3.5 the agents exchange reports …"
  paragraph names the per-agent scratch directories and the naming rule in
  one sentence. Under "Plugin Design Lessons (Cumulative)", add a lesson,
  in substance: **git-ignored is not tool-ignored.** An ignored directory
  inside the project is skipped by git and by nothing else; test runners,
  linters, and compilers walk the tree by their own patterns, so a scratch
  file that looks like a test is a test. Name scratch files outside those
  patterns, and treat a tool that trips over them as a plugin defect, never
  as a reason to change the user's configuration. Background: the batch A
  acceptance run, `docs/dry-runs/batch-a-acceptance.md` § 8.
- Done when: both edits are present; the reviewer invariant sentence in
  CLAUDE.md is unchanged.

**Step 3.3: Release checklist**

- File: `docs/release-checklist.md`, the run-directory check for rows 6
  and 7. The bullet that places code-fixer's and regression-verifier's
  files "in `scratch/` itself" now names `scratch/code-fixer/` and
  `scratch/regression-verifier/`. Add three sub-checks: the checklist
  probe from [Fixed strings](#fixed-strings) prints nothing; after the run,
  the project's own test command passes unmodified from the repository
  root; the working tree gained no runner or ignore configuration from any
  agent (`git status --short` empty of such files, and no fix commit
  touches one).
- Done when: the three sub-checks are present and the counts
  `guards run: 10` / `self-tests run: 9` are unchanged.

**Step 3.4: CHANGELOG and roadmap**

- `plugins/kenspc/CHANGELOG.md`, `## 3.6.0 — unreleased`: Changed entries
  for the scratch layout, the naming and reset rule, the verifier's
  unmodified test command, and code-fixer's no-configuration-edit rule,
  citing the acceptance run as the source.
- `docs/roadmap.md`: remove items 2 and 9; renumber the rest.
- Done when: both edits are present and the roadmap still lists items 1,
  3–8 (renumbered) and the batches.

## Documentation impact

- `CLAUDE.md` § Subagent Review Architecture (run-dir paragraph), § Plugin
  Design Lessons — Step 3.2.
- `plugins/kenspc/README.md` § Run directory — Step 3.1.
- `docs/release-checklist.md` run-directory check — Step 3.3.
- `plugins/kenspc/CHANGELOG.md` 3.6.0 entry — Step 3.4.
- `docs/roadmap.md` — Step 3.4.
- `README.md` (root) — N/A for this document: it does not describe the run
  directory.

## Testing Strategy

- Mechanical: `bash scripts/check-all.sh --self-test` with `guards run: 10`
  and `self-tests run: 9`; `claude plugin validate --strict .` and
  `./plugins/kenspc`; the effort-override diff unchanged.
- Acceptance (ruling M7), macOS, in a throwaway TypeScript project with
  vitest and no vitest config, loaded with `--plugin-dir`: run
  `/kenspc-task-review` once. Pass when: the checklist probe over
  `RUN_DIR/scratch` prints nothing; `npm test` from the project root passes
  unmodified after the run; no agent added a runner or ignore configuration;
  `RUN_DIR/scratch` holds `code-fixer/` and `regression-verifier/`
  subdirectories (and `orchestrator/` only if the session probed); the
  Schema C row-3 Detail quotes the project's own test command. If any agent
  started over, a new subdirectory exists and nothing was deleted. The
  report is filed as `docs/dry-runs/scratch-probes-acceptance.md`.
- Falsifiability of the rule: the acceptance run before this batch
  (`batch-a-acceptance.md` § 8) is the failing case — 68 collectable files,
  a failing bare `npm test`, a config file added by code-fixer. The same
  three checks must now come back clean.

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| An agent still writes a collectable name | Medium | The verifier's unmodified test run fails the run and names the files (Step 1.3); the checklist probe catches it at release. |
| Renamed test copies break the mutation checks | Low | The scratch-local runner config includes the renamed pattern (`**/*.probe.ts`); relative imports from a copied test file do not depend on its own name. |
| A runner whose pattern the rule does not list | Medium | The rule says "read the project's configuration"; the two named runners are examples, not the list. |
| The verifier's unmodified run fails for reasons unrelated to scratch | Existing | Unchanged: any test failure is row-3 FAIL already; the new clause only forbids narrowing the command to make a failure disappear. |

## Open Questions

None.
