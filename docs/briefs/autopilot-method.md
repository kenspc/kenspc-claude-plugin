# Batch F input — the autopilot method (batches C–E, 2026-09-26)

This is the method the `autopilot` skill turns into a skill. "Invariant"
sections become the skill's text; "per batch" becomes the input the skill
reads from the brief's `## Autopilot` section or the spec.

## Locked design (F-1 … F-14)

- F-1 Skill `autopilot`, command `/kenspc-autopilot <path>`,
  `disable-model-invocation: true`; runs in an interactive main session
  that can ask the user, started with a fixed `--name`, bypass
  permissions, and `crossSessionInbound: accept`; a new command, so the
  plugin goes to 3.9.0.
- F-2 Two entry points, decided by the document kind of the argument. A
  plan document (a spec) → unattended from S2 on. A brief → S1 drafts the
  spec with an M/D table of options and leanings, no rulings; the main
  session gives the table to the user, who rules; S1 finalizes and commits
  the spec; from there unattended. The brief is a generate-brief document
  plus one `## Autopilot` section (baseline commit, mode, version policy,
  budget, allowed and zero-diff files, acceptance cases, prior specs to
  read via `git show`). No new document type.
- F-3 Two modes. `repo` (default): sub-sessions use the installed plugin;
  acceptance = the commands the brief names, or no S4 at all, S3b being
  the last check; release preparation = what `## Autopilot` says, by
  default one commit that removes the batch's plan and task documents and
  touches no version. `plugin` (declared in `## Autopilot`, or detected
  from a marketplace layout — `.claude-plugin/marketplace.json` plus
  `plugins/<name>/.claude-plugin/plugin.json`): sub-sessions get
  `--plugin-dir <worktree plugin>`; S4 runs seed-project acceptance and
  writes `docs/dry-runs/<batch>-acceptance.md`; S6 does the repository's
  release preparation (CHANGELOG date, version bump, checklist, roadmap,
  remove plan/tasks, release commit, pre-flight).
- F-4 Fixed topology: S1 design (brief entry only), S2 `/kenspc-task`,
  S3 `/kenspc-task-implement`, S3b `/kenspc-task-review` standalone,
  S4 acceptance, S5 fix (only for a defect the main session classified),
  S6 release preparation. One role per session; never reuse a session
  across roles. Proposer ≠ ruler; implementer ≠ acceptor.
- F-5 Mechanics. A driver script ships with the skill
  (`skills/autopilot/scripts/run.sh`, later `run.ps1`) and is copied per
  batch to `~/Projects/_smoke/_prompts/<batch>-run.sh`; prompts are files;
  every worker starts with `--name <tag>` and
  `--settings '{"crossSessionInbound":"accept"}'`; each launch writes
  `.json`, `.err`, `.pid`, `.exit`, appends to `timeline.log`; costs go to
  `costs.txt`. Communication is cross-session messaging: the main session
  subscribes to each worker with `SendMessage` `notify_when_idle` and ends
  its turn, and the notice wakes it (a headless driver such as S4 cannot
  idle-wait, so it waits in a `sleep` loop and the notice arrives as a
  message between tool calls); a worker asks by `SendMessage` to the main
  session's name and waits in a `sleep` loop, at most 30 minutes, then
  writes the question into its final message and stops, and the main
  session falls back to `--resume`. No agent teams, no `--continue`;
  `--resume` is the fallback only. Cost of a session = its last cumulative
  `total_cost_usd`; the main session's own cost is estimated; sessions
  spawned by user-level hooks are observations, not cost. Evidence:
  `~/.claude/projects/<cwd with / as ->/<session_id>.jsonl` and its
  `subagents/`.
- F-6 Every sub-session prompt opens with the common preamble: role, the
  main session's name and the ask protocol; exemplars to read (`git show
  <hash>^:docs/plans/…` of prior specs, named in `## Autopilot`); safety
  rails; locked design; out of scope; constraints. Self-contained — never
  "as batch X did".
- F-7 Safety rails: write only to the repository, `~/Projects/_smoke/`,
  and `$TMPDIR`; no `git push`, `git tag`, or release; no resource the
  brief does not name (databases, network services); no secrets; no
  `rm -rf` — discard by `mv` into `.trash/<name>-<timestamp>/`; deletions
  inside the repository only through `git rm`; any breach is a stop.
- F-8 Ruling hierarchy: locked design (immutable) > M/D rulings (the main
  session, within the lock; the user at brief entry) > CL clarifications
  during implementation (the main session; recorded in the spec and
  committed). Rulings beyond the letter of the lock are reported. The
  question channel is a `SendMessage` to the main session; the spec's
  Open Questions section says so.
- F-9 Stop conditions (below); a stop is a question to the user. Budget:
  default USD 200, set in `## Autopilot`, never hard-coded; the main
  session may stop to ask for more. Implementation is never narrowed;
  acceptance may be, with Not exercised recorded, and never the locked
  design's main path.
- F-10 Acceptance (plugin mode): dry-run a seed to confirm the path under
  test is reachable; one case per run; every driver reply is named in the
  record; the main session classifies each FAIL — plugin defect (S5 fix
  and re-run), behavior deviation (roadmap), observation; record sections
  fixed (Setup, Independence, Cases, Findings, Observations, Not
  exercised, Summary).
- F-11 Two human gates only: the spec (rulings at brief entry; a supplied
  spec counts as approved) and tag / push / release after the reports.
- F-12 Two reports: a user report (conversation language, one page) and a
  reviewer report of fixed shape, including a total-cost line.
- F-13 `run.ps1` mirrors `run.sh`, written after the bash driver passes
  acceptance, checked with `pwsh` on macOS (syntax plus one launch);
  Windows acceptance is a roadmap line.
- F-14 Release 3.9.0; CHANGELOG `## 3.9.0 — unreleased`; README,
  CLAUDE.md, checklist, manifests in sync; roadmap gains only the Windows
  line.

## Invariant — the skeleton

| Module | Content |
|---|---|
| Topology | S1 (brief entry) → main session rules → S1 finalizes → S2 → S3 → S3b → S4 → S5 (on demand) → S6 → two reports |
| Launch | `claude -p "$(cat <prompt-file>)" --name <tag> --settings '{"crossSessionInbound":"accept"}' [--plugin-dir <worktree plugin>] --permission-mode bypassPermissions --output-format json`, cwd per role |
| Waiting | interactive main session: subscribe with `notify_when_idle`, end the turn, the notice wakes it; headless driver: `sleep` loop, the notice arrives between tool calls; dead = pid gone AND no growth |
| Asking | worker → `SendMessage` to the main session's name → `sleep` loop up to 30 min → answer arrives as a message; on timeout, stop with the question in the final message; main session then uses `--resume` |
| Costs | last cumulative `total_cost_usd` per session; check "spent + projected" before each new session |
| Preamble | six fixed parts (see F-6) |
| Rails | see F-7 |
| Rulings | locked > M/D > CL; beyond-the-letter reported |
| Stops | reopening a locked point; a forbidden section or file; guards red twice in a row; the same FAIL still failing after two fixes; session+run count or budget exceeded (ask); a rail breach; a question neither spec nor lock answers; a nested `claude -p` refused; the same step's session dead twice |
| Acceptance | see F-10 |
| Human gates | see F-11 |
| Reports | user report; reviewer report: baseline → release hash, spec read command, M/D/CL counts and beyond-the-letter list, changed and zero-diff files, byte-identity / guards / counts, acceptance one line per case with cost, total cost, Not exercised, release-prep state, sessions / messages / resumes / stops with reasons |

## Per batch — what the brief's `## Autopilot` (or the spec) supplies

Baseline commit; the locked design with a Why per item; out of scope;
allowed files and zero-diff list; byte-identity exceptions, if any;
version policy; S1's must-read files and challenge seeds; acceptance cases
with PASS criteria; budget and count caps; hashes of prior specs to read.

## Lessons that became rules

| Batch | Event | Rule |
|---|---|---|
| C | preamble lacked the exemplar commands | exemplars' `git show` lines in the preamble |
| C | a sub-session wrote under `/tmp`, outside the rails | `$TMPDIR` is an allowed location |
| C | costs summed across resumes (cumulative values) | take the last value per session |
| C | the cap was a hard stop; the main session asked and the user raised it | the cap is a question, not a wall; narrow acceptance first, never implementation |
| D | no waiting protocol → foreground wait, user interrupt | idle notices for an interactive main session; `sleep` loops for headless drivers |
| D | SendMessage probes failed — a bypass receiver held messages from a non-bypass sender, and a `-p` receiver dropped held messages after five minutes | every worker and the main session run with `crossSessionInbound: accept`; messaging replaces polling and `--resume` |
| D | a user-level hook spawned sessions in seed projects | observed, not counted |
| D | total cost missing from the report | a total-cost line |
| E | a 44-minute S3 exceeded a fixed poll window | liveness by pid and growth, not by clock |
| E | a seed BLOCKED a task and hid the path under test | dry-run seeds first; swap a seed that cannot reach the step |
| E | budget narrowing dropped a main path | never narrow the locked design's main path |
| E | S3 edited an agent it later used; the old text ran | skills and agents load at session start — a batch that edits the plugin sees its change only in the next session |
| E | seven `--resume` calls replayed whole contexts | a worker asks by message and waits; `--resume` only when it has already exited |

## Numbers

| | C | D | E |
|---|---|---|---|
| sub-sessions + runs | 7 + 11 | 10 + 14 | 6 + 7 |
| `--resume` | 5 | 9 | 7 (+5 inside S4) |
| main-session stops | 0 | 0 | 0 |
| human interventions | 3 | 1 | 0 |
| cost (USD) | 99 | not reported | 132 + main session |
