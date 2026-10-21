# Roadmap

Planned work for the kenspc plugin. An item leaves this file when it ships;
the CHANGELOG records it from then on. The remaining items are renumbered
when one leaves, so text outside this file names an item by its subject, not
its number.

## Next minor (4.15.0)

1. Whether to merge bug-reviewer and edge-case-reviewer: decide once 3.5.x
   has three or more runs with angle-labelled data (left open in G6-b).
2. Linters and build tools still walk into `.kenspc/`. ESLint's flat config
   ignores only `node_modules` and `.git` by default; the ESLint
   configuration migration guide: "In flat config, dotfiles (e.g.
   `.dotfile.js`) are no longer ignored by default." A runner-safe probe such
   as `probe.mts` can therefore still fail `eslint .`, and no name keeps a
   source probe out of a linter's pattern. Today `regression-verifier` runs
   build and lint unmodified and names the scratch files in the FAIL;
   keeping them out of those tools is open. A prototype's files under
   `prototypes/` are in the same position between its add and remove
   commits, and a gate that walks the repository reaches them there.
3. Scratch convention follow-ups. The standalone review of the last
   scratch-probe commits (`f42bd21`, `99574bb`, `979688e`) found no HIGH
   issue and, under that plan's stop rule, deferred 14 findings, 9 MEDIUM
   and 5 LOW, with no further round. The rows and each one's suggested
   follow-up are in `.kenspc/runs/20260924-231237-changes/schema-b.md`
   (git-ignored; only in the maintainer's macOS checkout). MEDIUM:
   - a control mutant that keeps passing has no stated outcome, and which
     module it must break is not stated;
   - a mutation check reported as not made has no place in Schema A or B,
     and regression-verifier's "not mutation-checked" none in Schema C;
   - when the test row is FAIL, the Next steps delete bullet cannot tell
     which collected `.kenspc/` files passed;
   - a reviewer re-dispatched into the same run reuses scratch attempt
     `1/`;
   - the release target's tests need not depend on its setup file or
     `globals`, so the baseline sub-check can pass vacuously;
   - no release sub-check tests the numbered-attempt layout;
   - CLAUDE.md's `--plugin-dir` editing rule has no CHANGELOG line.
   LOW: smoke rows 6 and 7 omit the delete bullet; the baseline
   sub-check is silent on a retried baseline; the CHANGELOG's "check 4" can
   read as Schema C row 4; the worker agents' runner config sits outside
   the attempt directory.
   From the acceptance run (`docs/dry-runs/scratch-probes-acceptance.md`
   § 7):
   - O2: `schema-b.md` carried a `## Verification` section between the
     Deferred Issues prose and the statistics line, which code-fixer's
     OUTPUT FORMAT does not list; the recount guard passes it, and the
     Schema F rendering dropped it;
   - O3: angle 1 rooted each mutant's runner config at the mutant's
     subdirectory while its baseline ran under the attempt-level config, so
     the baseline and the mutants did not run under the same config file;
   - O4: regression-verifier copied the `test/` tree with its collectable
     names and renamed them in the next statement, against ruling M3's "as
     they are copied"; code-fixer renamed as it copied;
   - O5: a scratch runner config without `cacheDir` leaves vite's cache at
     `scratch/<agent>/1/node_modules/.vite/`;
   - O6: the lint and build paths of the unmodified-command rule are
     untested by any acceptance run — the target project had neither
     script, so the build row was a PASS that could not fail.
   From the batch B acceptance (`docs/dry-runs/batch-b-acceptance.md`,
   F2): regression-verifier named a log `test.out` under its scratch
   attempt, which the release checklist's name probe flags although vitest
   collected nothing; the RUN_DIR bullet already forbids `test.*`, so this
   is a behavior slip to watch, not a rule gap.
4. Smoke candidates for the prototype chain. The batch C review (T2–T7)
   proposed six release-checklist cases that the one-time acceptance
   covers but no smoke row does, and the review of its fix round proposed
   more, each marked with its ID. Each costs a headless run at every
   release, so whether any joins its row is the maintainer's call:
   - Row 10: a session that cannot ask — with no entry named on a brief
     holding two `needs prototype` entries, the run takes the first and
     names it; a table-creating run uses a throwaway database, names it,
     and leaves the development database file unchanged.
   - Row 10: the judgment point — the run waits after the add commit, says
     how to see the prototype, and `Evidence:` says the user judged it; a
     session that cannot ask leaves the entry `needs prototype` with
     `Evidence:` naming what to look at, and the remove commit's body
     carries `Not settled:`.
   - Row 10: a failed commit, on a seed project whose pre-commit hook exits
     1 — no retry and no `--no-verify`, no add commit, the staged paths and
     `git reset -q --` named; a rejected remove commit names the add commit
     and says the removal is staged.
   - Row 10: a question given as text for a brief with no
     `## Open Questions` — the section created after `## Context`, the
     entry `needs prototype` with `Settled by:`, nothing else in the brief
     changed.
   - Row 3: a Chinese run whose `## Open Questions` heading, status words,
     and labels stay in English; row 4 on that brief then asks the exit
     question.
   - Row 4: a brief with an `answered` entry, whose short hash the plan
     cites where it relies on it, and a brief whose section body is `none`,
     which gets no exit question.
   - Row 4: a brief entry whose status word is not recognized — a
     translated word such as `需要原型`, or no word — which the gap round
     quotes and asks about; with a reminder to work without stopping, the
     draft's Open Questions carries it in the `open` form, its `From:`
     ending `status word <the word> not recognized` (fix-round review, T1).
   - Row 10: a setup under which the leftovers criteria can fail — a
     prototype that installs one package into its own manifest, under an
     unanchored `node_modules` ignore pattern, and an in-app location that
     holds an untracked file of the user's before the run; `node_modules/`
     then appears as one line and the user's file not at all. Without it,
     the old `--ignored -uall` form and the new one print the same list and
     the location holds nothing before the run, so reverting the command or
     dropping the start snapshot still passes row 10 (fix-round review,
     T3).
   - Row 3: a Level 1 idea holding a question only an experiment settles,
     run with a reminder to work without stopping — the brief is written
     without asking what would settle it, and its `needs prototype`
     entry's `Settled by:` is tagged as inferred (fix-round review, T2).
5. When the prototype skill names a leftover directory once. Today a
   directory is named once, with its file count, only when every file
   under it is listed as untracked. In a project whose dependency ignore
   rule is root-anchored (`/node_modules`, the create-next-app and Create
   React App default), a prototype's own `node_modules/` is untracked, not
   ignored, and any unanchored pattern that matches inside a package
   (`dist/`, `*.log`, `*.tsbuildinfo`, `.DS_Store`) adds a `!!` line under
   it. That line blocks the collapse of `node_modules/` and of every
   directory above it, so after a dependency install the list runs to one
   line per package (fix-round review, B5/E2). The reviewer's suggested
   condition: every entry listed under the directory, untracked or
   ignored, is absent from the start-of-run list, and
   `git ls-files -- <directory>` prints nothing. The skill's Exit, the
   plugin README's leftovers item, release-checklist row 10, and a
   CHANGELOG entry change in one commit; a probe on a scratch repository
   with `/node_modules`, `dist/`, and `*.log` patterns settles the wording.
   The row and its follow-up are in
   `.kenspc/runs/20260925-234058-changes/schema-b.md` (git-ignored; only
   in the maintainer's macOS checkout). The acceptance run's O5
   (`docs/dry-runs/batch-c-acceptance.md`) already named a directory
   holding untracked and ignored files once, as that condition would.
6. Two prototype runs went outside rules the skill already states; to
   watch, not a rule gap (`docs/dry-runs/batch-c-acceptance.md`, O11 and
   O12, classified behavior deviations). One asked a question outside the
   gate table — the brief's Scope excluded any UI, and the run asked
   whether to go on or stop — where the skill says "Every question the
   skill asks is one of these gates". The other wrote its check script and
   a saved render to the session scratchpad instead of the location, so
   `git show <add commit>` does not hold the checks its `Evidence:` cites,
   where the skill says "Everything is written under the location".
7. A generate-plan gap round went outside a rule the skill already states;
   to watch, not a rule gap (`docs/dry-runs/batch-d-acceptance.md`, F2,
   classified a behavior deviation). Asking the status of two entries
   whose status words it did not recognize, the gap round asked only for
   the status, where the skill says "the question that asks an
   unrecognized entry's status also asks, for `answered`, the answer — one
   question, one round". The user replied `answered` for one of them with
   no answer text, and that entry was still carried as the rule says, into
   the plan's Open Questions in the `open` form with `Answer: missing`, so
   the plan's content was not affected.
8. The review's progress lines. Between the dispatches,
   `/kenspc-task-review` and `/kenspc-task-implement`'s review phase print
   one fixed line per step; across the four review runs of the batch E
   acceptance (`docs/dry-runs/batch-e-acceptance.md`, F1, classified a
   behavior deviation), 10 of the 12 lines were printed. One run went from
   the five reviewers' replies to the code-fixer dispatch with no
   `Reviewers returned —` line, in the turn where it checked the report
   files on disk; another went from regression-verifier's reply, which
   carried its CLEAN result, to the final report with no
   `regression-verifier returned —` line, neither the CLEAN form nor
   `regression-verifier returned — no result line`. The steps carry each
   line where it is printed, the same text printed it in the other runs,
   and in all four runs the tables were rendered once, in the final report.
   The follow-up to weigh: tie each line to the step after it — printed in
   the message that makes the next dispatch, or that opens the final
   report — so a missing line cannot pass unnoticed by that step.
9. `/kenspc-task-implement` renders Schema D twice: Phase 1 Step 5 renders
   the implementer's table and its prose sections verbatim, and Schema G's
   Implementation section renders them again — the double render 3.8.2
   removed for the review's reports, and both copies stay in the
   orchestrator's context the same way. It was left out of 3.8.2 because
   Step 5 is the Phase 1 → Phase 2 boundary, whose transition sometimes
   failed to trigger in 3.0.2 and whose `Proceeding to code review.` line
   smoke row 14 looks for in the trace; changing what that boundary prints
   needs an acceptance of its own. 4.11.0 settled the Schema G half:
   Schema G renders Schema D in full whatever Step 5 printed, since a run
   that pointed back at Step 5 left its `## Checks run` out of the only
   message a headless run returns. The choice left: Step 5 prints only its
   progress update, or both renders stay. In two of the four 4.11.0 smoke
   runs of row 6, Step 5 printed neither Schema D nor its progress update,
   which row 14 would fail.
10. Doc-sync follow-ups, left out of 3.8.2, which has code-fixer correct a
    DONE Doc-sync task's documents in the fix commits. The review rows are
    in `schema-b.md` of the batch's review runs
    `.kenspc/runs/20260926-152446-batch-e-review-pipeline-tasks/`,
    `20260926-160144-changes/`, and `20260926-163655-changes/` (git-ignored;
    only in the maintainer's macOS checkout). Whether each stays is the
    maintainer's call:
    - Guards: `check-run-contract.sh`'s check 5 looks for `pre-fix/index.txt`
      in `code-fixer.md` and `regression-verifier.md` but not in
      `task-review/SKILL.md`, whose Schema F Next steps now names it.
    - Smoke candidates, each a seeded headless run at every release: row 7
      with a task document whose Doc-sync task is DONE and FIXED greater
      than 0, checking Schema F's Doc-sync bullet (run once in the batch E
      acceptance, `docs/dry-runs/batch-e-acceptance.md` § 2.7); a row-6
      seed that forces a Doc-sync correction — row 6 names none, and the
      acceptance's seed, whose README stated the defect first, left the
      Doc-sync task BLOCKED (F2), so Schema G's bullet in its `updated`
      form has not run; the not-updated branch, a listed document with
      uncommitted changes or a correction that needs a new section; the
      Doc-sync section's boundary and a document outside the list; a task
      document that translates the `**Documents**` label; and rows 6 and 7
      checking that the final report holds each reply whole, where today
      they check one anchor per reply.
    - Reply and report gaps: a DONE Doc-sync task whose bullets open with
      no backticked path gives code-fixer an empty list, and the reply
      reads `Doc-sync documents: none affected by the fixes`, as if
      checked; a committed run in which code-fixer is cut short can leave
      a half-applied fix uncommitted, with no Next steps bullet for it;
      Schema F writes no Doc-sync bullet when code-fixer's reply has no
      statistics line, where Schema G does; and the Fixes placeholders in
      Schema F and G, like the sentences that list what code-fixer's reply
      carries, do not name the `Doc-sync documents:` line (the acceptance's
      Schema G rendered it in `## Fixes` all the same).
11. Windows acceptance of `run.ps1`, the autopilot's PowerShell driver. On
    macOS it had only a `pwsh` parse and its `--self-test` launches
    (`docs/dry-runs/batch-f-acceptance.md` § 2.11); no headless batch has
    run on Windows, and the skill copies and runs `run.sh`, so nothing picks
    `run.ps1` by platform until this acceptance passes. What it settles —
    the batch F spec's CL22 and CL23,
    `git show d4902b0:docs/plans/batch-f-autopilot.md`:
    - Whether `<tag>.launch.err` keeps the inner pwsh's error on Windows.
      On macOS `Start-Process` copies the launched pwsh's streams through
      the driver's own process, so the launch files keep only what is
      written before the driver returns, and the inner command's failure
      reason reaches `<tag>.err` instead.
    - Native argument passing through the `claude.cmd` shim: the worker's
      `--settings` JSON and a prompt that holds `"` arrive unchanged. The
      self-test compares both byte for byte only through a `#!/bin/sh`
      stub, on macOS and Linux.
    - The `run.ps1` pid's command line carries no tag, while the skill's
      leftover-pid check reads the driver's command line with the tag
      (`<batch>-run.sh <tag> …`) and takes any other as a leftover from a
      reboot — latent while the skill runs `run.sh`.
    - Whether a real worker leaves a descendant process that inherits the
      inner script's piped streams and so delays `<tag>.exit` until that
      process exits.
    - A launch whose worker writes UTF-8 non-ASCII text, its `<tag>.json`
      and `<tag>.err` compared byte for byte, since a Windows console code
      page can re-encode them.
    - A `--model` value with a bracketed suffix (`<model>[1m]`), from 4.2.0
      on. `run.ps1` passes its flags to `claude` by splatting, and pwsh on
      macOS and Linux globs the value for a native program: a probe in a
      directory holding `x1` and `xm` saw `x[1m]` arrive as `x1 xm`, and
      intact where nothing matched. pwsh on Windows does not glob, and on
      macOS and Linux the skill runs `run.sh`, which passes the value
      intact. A fix replaces the native call itself and keeps the empty
      stdin, the two redirections, and the status that becomes `.exit`;
      with it, both drivers' self-tests gain a bracketed `--model` launch
      beside a decoy file, which neither has today (the batch I spec's
      clarifications on its review's deferred findings,
      `git show 6598ba6:docs/plans/batch-i-autopilot-model-effort.md`; the
      rows are in `schema-b.md` of `.kenspc/runs/20260928-184145-changes/`
      and `20260928-202048-changes/`, git-ignored, only in the maintainer's
      macOS checkout).
12. Upgrading a project with `/kenspc-init`, which 4.0.0 left out (the batch G
    spec's 2.15, `git show 7a14f34:docs/plans/batch-g-init-project.md`).
    Two kinds:
    - Migrating a repository set up before the skill: moving a long
      CLAUDE.md's instructions into AGENTS.md and the topic documents, and
      an AGENTS.md without the template marker onto the template's sections.
      Today the skill moves neither: an existing CLAUDE.md gains at most the
      import line, and an AGENTS.md without the marker is left as it is,
      which the final message says. Reconciling a `docs/backlog/` in the
      user's own format, deferred after the batch's first review round
      (the spec's C10, E19), belongs here too.
    - Bringing a project up to a later template: adding what the newer
      template has and the project's files lack. The
      `kenspc-init template: 1` marker 4.0.0 writes into AGENTS.md's
      opening comment is there so a later version can tell which template
      wrote the files; today a rerun fills only `TBD(init):` markers.
13. Moving a project's backlog from one file per item (`docs/backlog/`) to
    GitHub Issues. `/kenspc-init` settles the backlog from the remote that
    exists when it runs, so a project given a GitHub remote later keeps the
    file backlog, and a rerun changes only `TBD(init):` markers.
14. Three `/kenspc-init` edge cases batch G deferred and 4.1.0 left as they
    were (the batch G spec's C10 E20, C12 E2-5, and C13 E3-6,
    `git show 7a14f34:docs/plans/batch-g-init-project.md`); the fourth, a
    `docs/backlog/` in the user's own format, belongs to the upgrading
    item:
    - A rerun after the first run's commit failed. The rerun has no branch
      for the files the failed run left uncommitted; today the failed run's
      final message names them, and `git status` shows them.
    - A generator that changes a file which already held uncommitted
      changes. Scaffolding runs only in a session that can ask, and the
      generator's change is never committed: it stays in the working tree,
      mixed with the user's, and nothing is lost. Telling the two apart
      would take a snapshot of every changed file before the generator runs.
    - `git init` in an empty directory another user owns. Git reports the
      error itself and the run writes no global setting, but the skill has
      no branch of its own for the case.
15. Detecting the user's `instructionFiles` setting, the mode of Claude
    Code's built-in agents-md plugin, which 4.1.0 left out (the batch H
    spec's 2.6, `git show d7949ac:docs/plans/batch-h-init-project-4-1.md`).
    The setting can come from three places — the user's settings,
    `--settings`, and managed settings, never the project's — which
    override each other, so `/kenspc-init` states when AGENTS.md loads as a
    condition on the mode rather than guessing the mode: a conditional
    statement is more reliable than a guess.
16. Claude Code's `/import codex` (`claude import codex`; in 2.1.283's help,
    "Import config from another AI coding agent into Claude Code"), which
    4.1.0 left out (the batch H spec's 2.6,
    `git show d7949ac:docs/plans/batch-h-init-project-4-1.md`): nothing in
    the plugin accounts for it, and it has not been probed.
17. Autopilot model and effort follow-ups, which 4.2.0 left out (the batch
    I spec's clarifications,
    `git show 6598ba6:docs/plans/batch-i-autopilot-model-effort.md`, and
    the acceptance record's Not exercised section,
    `docs/dry-runs/batch-i-acceptance.md`):
    - The model check's two misreadings. The check asks whether the
      applied model ID contains the requested value, so a declared ID that
      is a prefix of the served one reads as a match, and an alias that no
      served ID contains reads as a mismatch. The rule was fixed in the
      batch's design; the plugin README's Known behavior states both, and
      a role that needs certainty declares a full model ID.
    - Paths no acceptance reached:
      - the skip of API-error records, which only a forged transcript
        reaches;
      - a run with `CLAUDE_CONFIG_DIR` set, which needs a second login;
      - `CLAUDE_CODE_EFFORT_LEVEL` set while no role declares an effort,
        which must not stop the run;
      - a resumed worker's state line replacing its predecessor's;
      - the role a re-run tag takes (`-s3c`, `-s4b`, `-s5b`);
      - the settings stops on inputs beyond the five the acceptance ran
        (an unknown effort level, an unknown role, a role named twice, the
        effort before the model, and `CLAUDE_CODE_EFFORT_LEVEL` set beside
        a declared effort).
18. Whether an autopilot worker on Windows can run the rails hook. The
    worker rails hook (4.3.0) is a bash script, registered as
    `bash "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/autopilot-worker-rails.sh"`,
    and the probes that decided to build it ran on macOS only. Open: whether
    Claude Code on Windows runs a bash hook at all, which needs a `bash` on
    its PATH (Git Bash), and, where it does, what the hook makes of a
    Windows worker — it judges only POSIX absolute paths, so a drive-letter
    target is allowed unjudged, and `run.ps1` writes the repository root as
    git prints it there (`C:/…`). `run.ps1` exports the marker and the
    roots as `run.sh` does; nothing picks it by platform until the Windows
    acceptance of `run.ps1` above has passed.
19. regression-verifier writes temporary files outside its scratch
    directory. In two acceptance runs, 4.2.0's
    (`docs/dry-runs/batch-i-acceptance.md`, case 3) and 4.3.0's
    (`docs/dry-runs/batch-j-autopilot-reliability-acceptance.md`, F1,
    classified a behavior deviation), its review wrote its `npm test` output
    to `/tmp/rv-npm-test.txt`, and once an issue-ID list to the project's
    root, which it then removed, although its RUN_DIR bullet puts probe and
    temporary files under `RUN_DIR/scratch/regression-verifier/`. The
    agent's text states the rule; the model did not follow it.
20. Autopilot rails follow-ups, which 4.3.0 left out (its reviews and
    acceptance: the batch J spec's clarifications,
    `git show f671f2d:docs/plans/batch-j-autopilot-reliability.md`, and the
    acceptance record's Not exercised section,
    `docs/dry-runs/batch-j-autopilot-reliability-acceptance.md`):
    - Rails-hook spellings split by a line continuation — `&\<newline>>`,
      `$\<newline>'`, `$\<newline>(`, a heredoc operator or delimiter —
      which the scanner misjudges because bash joins continued lines before
      it splits words, while the scanner reads one next character in
      several places; one shared "next character, skipping continuations"
      read would cover the class, and so would joining every
      backslash-newline pair before the scan, as bash does before it splits
      words. The hook's header and the plugin README's Known behavior name
      the class among the hook's misses.
    - The wording of the caveat on denials inside agents without rails
      text (an unreadable-field denial reaches the worker in the
      subagent's reply).
    - Any failure of the hook's awk reported as an unreadable field: a
      missing awk denies every call, a killed one one command, and each
      wants its own reason.
    - Paths 4.3.0's acceptance did not exercise live: a preamble-carrying
      worker meeting a denial (list it and go on; for an unreadable field,
      list it and end), the rails carried into subagents' prompts and
      `CUSTOM_INSTRUCTIONS` with a subagent's observations carried back, and
      an S2's skipped gate reaching the post-check.
21. Acceptance commands a plan writes are never run at the baseline before
    the batch starts. In three repo-mode batches four commands broke for
    reasons outside the batch's work — pnpm read a flag meant for the test
    runner; a `Failed` grep matched an application log line; a per-assembly
    summary line the installed .NET SDK does not print made the command
    fail at the pre-batch commit; a check passed vacuously because a clone
    was never restored. 4.5.0 lets the main session rule a corrected form
    with evidence and a negative control, after S4 has failed; a dry run of
    each command at the baseline, before the first launch, would find these
    before any session is paid for.
22. Autopilot rulings follow-ups, which 4.5.0 left out (its review rounds;
    the batch K spec's clarifications,
    `git show d1406e9:docs/plans/batch-k-autopilot-rulings.md`):
    - The main session's own keep-path clarification commit has no outcome
      when `git commit` fails — a hook, a stale index lock, a signing
      failure — and the next ruling's status check then reads the entry it
      left as a change S6 made. The one MEDIUM the last review deferred.
    - `git log -S '<a line of the entry>'` in the S6 return check breaks
      its quoting on an entry line that holds an apostrophe.
    - S3's batch gate is answered without comparing the task list it
      carries with the list S2's confirmation ruled.
    - Stop condition 11 names the main session's `claude --version`, not
      the executable `AUTOPILOT_CLAUDE` names for the workers.
    - Phase 0's question for an inbound source the main session cannot read
      maps `no` to a stop, where the documented default may still deliver.
    - The README and CHANGELOG summaries of the keep-path gate do not name
      the case of an entry already at HEAD.
23. `rulings.md` follow-ups, which 4.5.0 left out (4.7.0 settled an entry
    outside the grammar and a ruled ID's unruled duplicate):
    - Whether an interactive task-review pauses, once the reviewers return,
      for the user to rule before code-fixer runs — a new gate; until it is
      decided, a ruling that arrives after the code-fixer dispatch has no
      stated outcome.
    - The could-not-land exception to the ruled-row verdict rule rests on
      code-fixer's own reason, which regression-verifier does not check.
    - The plugin README's copy of the entry grammar sits outside
      `check-run-contract.sh`'s byte-identity check on the four carriers.
24. A task whose `**Status:**` is none of TODO, IN PROGRESS, DONE, or
    BLOCKED falls into no bucket in task-implement's Phase 1 Step 3, while
    task-implementer reads "incomplete" loosely, so a hand-edited status can
    end as finished work that was never built. The fix spans
    `task-implement/SKILL.md` and `agents/task-implementer.md`: Step 3 names
    every unrecognized status in its reply, and task-implementer reads
    incomplete as exactly TODO or IN PROGRESS.
25. Guards and smoke rows 4.5.0's new rules lack:
    - a test of the telemetry hook's transcript root under
      `CLAUDE_CONFIG_DIR` — one record with the transcript under
      `$CLAUDE_CONFIG_DIR/projects`, none with it only under
      `$HOME/.claude/projects` — a new guard, so the pinned guard count
      moves;
    - smoke rows 6 and 7 exercising a ruling through `rulings.md` (a plain
      review leaves none; a ruled review shows the `ruled` Action and the
      `Rulings:` line), and an assertion on the state file's `inbound:`
      line;
    - guards holding the literals `## Question for the main session`,
      `S6 return:`, and the keep-path gate's marker, the rule that a ruled
      ID no report lists keeps the verdict from PASS, and S6's question
      cutoff.
26. `check-no-model-names.sh` reads the Linux and WSL managed-settings
    directory, `/etc/claude-code/`, as a model ID, so the autopilot skill
    writes it as the pattern `/etc/claude?code/`. An exception for that
    directory, beside the ones the guard keeps for
    `claude-plugins-official` and the `instructionFiles` values, would let
    the skill cite it as the documentation writes it.
27. The "session that cannot ask" sentence in generate-brief and
    generate-plan. The writing rule (AGENTS.md § Editing skill and agent
    content) has every question a skill stops on state what a session that
    cannot ask does instead. 4.10.2 added it to every stop this item named
    in task-implement, task-review, generate-task, and generate-guide.
    Still without it, found by a search for the two skills' questions:
    - the question each asks when it is given no argument — generate-brief
      what idea to think through, generate-plan what to plan;
    - generate-plan's Level 4 question about which module to plan first.
      generate-brief's matching question falls under its Discovery Mode
      Detection, the older form of the same branch.
    Each stop needs its outcome decided first, so this is a plan, not a
    wording pass. generate-plan's discovery dialogue for an input that is
    not a brief was not checked line by line and is confirmed in the same
    plan. An autopilot worker is unaffected: its preamble sends such a
    point to the main session, so the gap is a headless run of one of these
    skills outside the autopilot.
28. S3b on a condition in repo mode. The autopilot keeps the
    implementation, the standalone review, and the acceptance in separate
    sessions for two reasons: a session that reviews its own work reads its
    own intent into the code, and a session that edited the plugin still
    runs the text it started with. The second holds only in plugin mode.
    The first is mostly met inside task-implement already, whose five
    reviewers are fresh subagents; only the orchestrating session shares
    the implementation's context. In the 33 dayaku-crm batches S3b cost
    USD 26.5 a batch on average, 31% of all spend. Its review runs reported
    about as many findings as the implementation review's (410 unique
    across 41 standalone and narrowed runs, 458 across 35 implementation
    runs), yet up to 6 Oct 2026 it reported a HIGH in one batch only,
    staging-deploy, which the implementation review had found too; the one
    HIGH it found that the implementation review had missed was
    participants-portal's stale-copy save. Four of the five S5 loops it
    started were about the wording of a decision note. The maintainer's
    decision (15 Oct 2026): S3b runs on a condition in repo mode and stays
    unconditional in plugin mode; S4 stays, being cheap (USD 2 a batch)
    and the one check taken from the plan's text on the finished batch.
    4.6.0 shipped the switch alone, `Standalone review: off` in repo mode,
    default `on`; 4.7.0 adds the condition as a third value,
    `Standalone review: auto`: after S3 returns, S3b runs when S3's
    Schema G verdict is FAIL, or PARTIAL for a reason other than BLOCKED
    tasks alone, or S3's review left a HIGH or MEDIUM row DEFERRED, and the
    reviewer report's `Standalone review:` line records whether it ran and
    why. 4.11.0 makes `auto` the repo-mode default without the planned
    five-batch trial (maintainer's decision, 19 Oct 2026), on a read-back
    of the 42 repo-mode dayaku-crm batches up to 19 Oct 2026, all run with
    `on`:
    - `auto` would have skipped S3b in 20 batches, 925 of S3b's 2038 wall
      minutes; no S3 verdict was FAIL, and none was PARTIAL for BLOCKED
      tasks alone.
    - S3b reported no HIGH in those 20; it fixed 44 MEDIUM and 103 LOW
      rows there. Its 5 HIGH rows (2 fixed, 3 deferred) all fall in the 22
      batches `auto` still sends to S3b.
    - 17 of those 22 trigger on a MEDIUM deferral alone, most of them
      ruled by the main session because the row sat on a locked design.
    - Not measured: what S4 and the releases would have met on a HEAD
      without the skipped S3b fixes.
    The scripts and their readme are in the maintainer's
    `~/Projects/_smoke/_analysis/review-time-20261019/followup/`. What
    remains is the check after the default changed:
    - After the next five repo-mode dayaku-crm batches on 4.11.0 or later,
      the maintainer re-runs that read-back: which batches skipped S3b and
      on what trigger, and the follow-up issues filed after each release,
      by count and severity, against the batches before 4.11.0.
    - The default returns to `on` if HIGH or MEDIUM follow-ups rise in the
      batches that skipped S3b.
29. S4 runs each extracted command with `<shell> <file>` (4.6.0), outside
    the Bash tool's shell snapshot, so a command that relied on a function
    or an alias the tool's shell defines behaves differently there (the
    Bash tool's `grep` is a function that runs ugrep, which a command file
    run by `zsh` does not see). Deferred by 4.6.0's review as B11, LOW (the
    same `schema-b.md`): state the difference in the S4 block, or settle
    whether the commands run with the interpreter only or the tool's whole
    environment.
30. Second-round follow-ups, deferred by the reviews of 4.7.0's second fix
    round (the rows are in `schema-b.md` of
    `.kenspc/runs/20261016-111213-batch-m-autopilot-field-lessons-2-tasks/`
    and `20261016-135828-changes/`, git-ignored, only in the maintainer's
    macOS checkout):
    - The take-back check rests on code-fixer's own reason text (E3/B3,
      MEDIUM; and E12, LOW, the same gap): `schema-b.md` is updated in
      place and the first round's copy is never kept, so regression-verifier
      cannot see which rows round 1 FIXED, and a take-back code-fixer skipped
      or recorded in another shape passes row 1 as a DEFERRED row that
      matches its ruling. The suggested remedy: the orchestrator saves the
      first round's file as `schema-b-1.md` beside `schema-c-1.md`, in the
      `canonical:second-round` block, and row 1 runs the take-back check on
      every row a round-2 DEFER or NOT APPLICABLE names that the round-1
      record shows FIXED.
    - No guard holds the take-back reason literals (T1, MEDIUM):
      `first-round fix <hash>; taken back in <hash>` and
      `first-round fix uncommitted; taken back by hand`, which code-fixer
      writes and regression-verifier keys on; reworded in one file, every
      guard still passes and the check goes silent. The suggested remedy:
      check 5 of `check-run-contract.sh` requires both in `code-fixer.md`
      and `regression-verifier.md`, with a self-test mutant per carrier, and
      the guard's header names them with check 5's other literals.
    - The shared suite run's own writes into the tree go unreported (E13,
      LOW): the tree is recorded after the suite run, so a suite that writes
      a tracked file is not named anywhere.
31. Walk acceptance findings (`docs/dry-runs/batch-m-walk-acceptance.md`,
    F1-F3):
    - F1: S4w passed a relative file name to the screenshot tool, which
      wrote it into the repository before S4w moved it; the S4w block could
      name an absolute path under the Playwright MCP's output directory.
    - F2: a headless main session's final message carried
      `## Reviewer report` without the `## User report` heading.
    - F3: the installed 4.6.0's task-implement committed a `.gitignore` for
      `.kenspc/` in seeds whose specs put any other file out of scope, and
      two main sessions ruled that departure two ways (reverted by an S5 in
      one, kept in another).
    - Claude in Chrome stays out of the walk until a headless worker is
      shown reaching it: the probe (`docs/dry-runs/batch-m-walk-probe.md`)
      saw "Browser extension is not connected" in a headless `--chrome`
      worker while the desktop session reached the browser, cause not
      determined.
32. Suite-slot lock follow-ups, deferred by the 4.10.0 implementation
    review (rows E2 and E4 of
    `.kenspc/runs/20261017-185407-suite-slots-tasks/schema-b.md`,
    git-ignored; only in the maintainer's macOS checkout):
    - E2, liveness after a clock step: `suite-slots.sh` judges a holder
      alive by an exact match on `ps -o lstart=`, which procps on Linux
      derives from the kernel's boot time; a stepped wall clock (WSL2 after
      the host sleeps, an NTP makestep) moves it, every live holder then
      reads as stale, and more than N suites can run at once. Not measured:
      reproduce on WSL2 first (a wrapped `sleep`, `sudo date -s`, a second
      wrapper at limit 1). Either fix — a tolerance of a few seconds, or a
      start key that does not move such as `/proc/<pid>/stat` field 22 —
      changes the holder file layout, which the wrapper's header names a
      breaking change.
    - E4, no route for the wrapper's exit 2: preamble § 6 routes only exit
      75 (busy). The wrapper exits 2 when `/tmp/kenspc-suite-slots` is not
      a directory, is another user's, or cannot be written, and when `ps`
      gives no start time; a worker then may record a test failure or run
      the suite unwrapped, which the hook denies. Open: whether the worker
      asks the main session or stops, and whether the main session rules
      or it is a new stop condition (with the README Stops entry).
33. Whether the review bar and the Test map (4.11.0) cut the gaps the
    review finds. Baseline: a read-back of 1005 findings from 96
    dayaku-crm reviews, 29 Sep to 19 Oct 2026, classified 472 (47%) as a
    branch, guard, limit, or planned rule no test held; 271 of them came
    from the 44 reviews of freshly implemented tasks (run ids ending
    `-tasks`), about 6.2 a review, and they were 430 of the 716 rows
    code-fixer fixed. The scripts and their readme are in the maintainer's
    `~/Projects/_smoke/_analysis/review-time-20261019/` (`classify.py`,
    then `summarize.py`). After the next five repo-mode dayaku-crm batches
    on 4.11.0 or later, the maintainer re-runs them and compares:
    - test-gap rows per `-tasks` review against 6.2, and their share of
      the rows code-fixer fixed against 430 of 716;
    - S3's implementation minutes per batch against `rows.json`: the bar
      adds about 3.5k tokens to each implementer dispatch (a 2.2k-word
      read and 0.4k words of prompt), and the Test map adds work per task;
    - how many implementer dispatches read `shared/review-bar.md` before
      their first edit (one of four smoke runs skipped it while it was the
      last prerequisite), and how many Test map lines end `(unchecked)`.
    Known limits: the classification is about 85–90% where a second reader
    would put it, a `-tasks` suffix is not always the role, and it is one
    project. A gap whose fix lies outside the task's stated scope — reusing
    a helper another file keeps private — stays, since the implementer may
    not edit that file; every 4.11.0 smoke run of row 6 deferred one. If
    the rate does not fall, the next step is the option the design left
    out: generate-task maps each locked-design statement to a test in the
    task's acceptance criteria. dayaku-crm's own test rules, added to its
    AGENTS.md files while 4.11.0 was built, repeat some of the bar's
    generic sentences; trimming them is the project's call.
34. Whether the code-fixer trims (4.12.0) cut its time. Baseline: a
    read-back of the 46 code-fixer dispatches in dayaku-crm batches from
    12 Oct 2026 (after the project's full-suite rule) to 19 Oct 2026, 9.6
    hours charged: mutation checks 13%, build, test, and lint 18%, waits on
    background checks 10%, Acceptance re-runs 4%. The scripts and their
    readme are in the maintainer's
    `~/Projects/_smoke/_analysis/review-time-20261019/followup/`:
    `fixer-trims/classify_calls.py`, run as its usage line gives it
    (`classify_calls.py <dir holding common.py> [out.json] [since YYYY-MM-DD]`)
    with 4.12.0's release date as the date argument, against
    `fixer-trims/classify-since-1012.out`, and `fixer/aggregate.py` for the
    per-row regression against `fixer/aggregate.out`, once
    `fixer/inventory.py` is limited to the same dates (it takes no date
    today). After 30 code-fixer
    dispatches on 4.12.0 or later, the maintainer re-runs them and compares,
    per fixed row and per row that reports a surviving mutant:
    - active minutes per dispatch, and the hours of mutation checks, build,
      test, and lint, waits, and Acceptance re-runs;
    - whole-suite test runs per dispatch, and mutation runs per mutant row;
    - how many `rulings.md` files ask for every Acceptance command, or for
      mutants of files the fix does not edit, against 41 and 30 of 68.
    Guardrails, which must not get worse: regression-verifier's row 3 FAIL
    rate and its HAS ISSUES rate, the second-round rate, S4 failures, and
    the follow-up issues labelled `found-by-agent` after each release; rows
    reading `not mutation-checked` are counted too. Known limits: 4.11.0's
    review bar lowers the number of findings, and so code-fixer's time, on
    its own, which is why the comparison is per row; `auto` skips S3b in
    about half the batches, so S3 dispatches are compared with S3
    dispatches; one project. Not measured by these scripts: whether a
    narrowed per-fix check let a break through to the final run, which the
    transcripts show as a final run that fails after the per-fix runs
    passed. Counted apart: 4.12.1 has code-fixer read each Doc-sync
    document's batch passage after every fix, which adds reading time back
    in "task" runs whose Doc-sync task is DONE; the comparison charges those
    reads (the `git diff` of a listed document and the reads that follow it)
    to their own line, so the trims are not judged on time the new rule
    added.
35. The release checklist's run-directory sub-check 6 asks the trace to
    show "the unmutated baseline running first and passing", while the
    agents' rule (test-reviewer's, code-fixer's, regression-verifier's
    RUN_DIR paragraph) makes the baseline and the control a gate on
    counting a mutant, not on run order. In the 4.12.0 smoke the test
    reviewer ran its baseline, control and mutants in one vitest run; the
    baseline passed, the control failed, and its report counted survivors
    after both, which the maintainer counted as passing
    (`docs/dry-runs/code-fixer-trims-smoke.md`). Settle which the checklist
    means: reword the sub-check to the gate the agents state, or have the
    agents run the baseline and the control before their mutants.
36. Doc-sync corrections the fix's own sections miss. After 4.12.1 code-fixer
    reads each listed document's batch passage, but a sentence about the
    changed code itself can still be left false: in the replay of the
    participant-import-portal first review (dayaku-crm, 2026-10-07),
    fixing "send the file the picker holds" left DD-001's "It is not a
    controlled input: the page holds the file it names" as it was, as the
    original run had. Five of the 18 stale-sentence findings a first-review
    fix caused were of this kind, with mixed causes (one a ruling's own
    wording), so one replay does not show whether the rule or the reading is
    at fault. Replays and the read-back:
    `~/Projects/_smoke/dd-stale-replay/` and
    `~/Projects/_smoke/_analysis/review-time-20261019/`. Settle by replaying
    the case a few times before changing the rule.
37. Merge danger follow-ups, left out of 4.13.0 (its review and smoke,
    `docs/dry-runs/merge-danger-smoke.md`):
    - A task-review "changes" run in `Mode: commits` whose range comes from
      CUSTOM_INSTRUCTIONS and ends before HEAD reads the section to HEAD, so
      commits after the reviewed range that nobody reviewed are counted too;
      the header shows the range read. Decide between keeping it, reading
      the two ranges apart, or naming the fix commits on their own line.
    - `check-merge-danger-canonical.sh` exits 2 when a carrier's markers are
      missing, and no self-test mutation exercises that path.
    - Not exercised by the smoke: the autopilot closing sentence with
      `<n>` + `<u>` above zero, the not-determined range forms, and a
      `Mode: uncommitted` review. A row-11 seed with a one-way change would
      cover the first.
38. A line in the autopilot's final report on batches since the last retro:
    how many batches have finished since the last run timestamp on the
    newest record's `Window:` line under `docs/retros/`, so the user sees
    when a `/kenspc-retro` is due. Deferred by the retro brief; the retro
    skill (4.14.0) runs only when typed.
39. Run-directory ids in the autopilot state file: each review run a batch's
    sessions write, recorded under its tag. The retro's `map_runs.py` maps a
    run to its batch from session time windows and a json or transcript
    that names the run id, because nothing in a run directory or state file
    names it; a recorded id would make the mapping a lookup, with no
    `manual` fallback for an autopilot run. Deferred by the retro brief.
40. Retro guard gaps, deferred by the review of the retro batch (each
    mutant named is in that run's `scratch/angle-5/1/mutants.json`):
    - a run confirmed only through a resume's `<tag>-r<k>.json` is
      untested (mutant `resume-json-ignored` survives): add a run inside
      bat3-s3's window that only `bat3-s3-r1.json` names;
    - an s3 or s3b session with no `.exit` has no fixture, so its `other`
      row's `unmeasured` branch is untested (mutant
      `split-unmeasured-other` survives): add one in a batch whose window
      holds no run;
    - the guard pins `TZ=UTC`, so a UTC transcript timestamp read as local
      time cannot fail it (mutant `transcript-utc-as-local` survives): run
      the time case again under `TZ=Etc/GMT-8` with a copy of
      `claude-config/` whose timestamps are moved by −8 h.
41. Retro follow-ups from the 4.14.0 release smoke (row 13):
    - the record grammar has no place for why the selected items yielded no
      proposal; the run added a `- Drafting:` line under Window and
      coverage, outside the grammar. Give the reasons a defined line or
      section;
    - row 13's window held no proposal, so its `pending` path was not
      exercised; pick a window that yields one (a wider `last <n>`, or a
      `since` before the project's newest rules).
