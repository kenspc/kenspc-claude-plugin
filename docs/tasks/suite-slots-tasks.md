# Suite slots — Task Document

## Context

Implement kenspc 4.10.0: a machine-wide lock that caps how many heavy test
suites autopilot batches run at once. A slot wrapper script ships beside the
driver; a new `## Autopilot` field, `Suite limit:` (repo mode only), names N
and the listed commands; the drivers export the values to every worker; the
rails hook denies a listed command run without the wrapper; the autopilot
SKILL.md ties it together.

Related plan: `docs/plans/suite-slots.md` (rulings 1–9, as of commit
`70ffb7a`). Each task names the plan section it implements; the section's
text is the specification, and this document adds the code locations and
the checks.

This repository has no unit-test framework: its tests are
`bash scripts/check-all.sh` (with `--self-test`) and
`claude plugin validate --strict .` and
`claude plugin validate --strict ./plugins/kenspc`.

Text written into the plugin — the wrapper's and the hook's headers, the
deny reason, the SKILL.md — names no project, and its Why states evidence
in its own words rather than citing a dry-run record or a file outside the
plugin (the plan's Objective; CLAUDE.md, Writing Rules for Skill Content).
The plan's Background cites another repository's prompt files for the
measured port limit; those paths stay out of the plugin.

All commits stay on the local `main`. Nothing is pushed, tagged, or
released, and `plugins/kenspc/.claude-plugin/plugin.json` keeps `4.9.0`:
the version bump is part of the release preparation, outside this document.

Dependency note: Task 2 depends on Task 1. Task 5 depends on Tasks 1, 3,
and 4. Task 6 depends on Tasks 1-5. Task 7 (Doc-sync) depends on Tasks 1-6.
Tasks 1, 3, and 4 depend on nothing in this document.

## Tasks

### Task 1: The suite-slot wrapper script

**Status:** DONE

**Implementation notes:**
- Decisions: the child is started as `"$@" 0<&0 &`, because a background
  child of a non-interactive bash otherwise reads `/dev/null` as its
  standard input. The mutex is tried up to 10 times at 0.1-second steps
  per poll, so a mutex held for milliseconds by another counter does not
  cost a whole one-second poll; each try counts toward the 10 whether or
  not a stale mutex was reclaimed, so a mutex that cannot be removed ends
  the tries. A GNU `stat -f %m` prints file-system data rather than
  failing, so a value that is not all digits falls through to
  `stat -c %Y`. `ps -o lstart=` runs under `LC_ALL=C` per call, never as
  an export, so the wrapped suite keeps the caller's locale. The nested
  call validates its arguments first and then runs the command without
  `exec`. Mutant targets for Task 2 carry trailing comments
  (`# count check`, `# live-holder check`, `# release on exit`), and the
  nesting check is the one `KENSPC_SUITE_SLOT_HELD` test in the file.
- Changes/tradeoffs: an empty `owner` file is treated as no owner (the age
  rule), since a taker killed between the file's creation and its write
  leaves it so. A busy return whose last attempt never got the mutex reads
  the holders without reclaiming them; with none live it says the mutex
  stayed held. The mutex reclaim writes no log line, since the plan's
  `reclaimed` event counts holders in the reviewer report. The log's
  `holders <k>` on `released` and `nested` lines counts the holder files
  present, the caller's own included; the header says so. Smoke checks
  under `/bin/bash` 3.2: `run --limit 1 -- true` exit 0,
  `sh -c 'exit 3'` exit 3, `--limit 0` exit 2, no holder file left, and
  additionally a busy return (75, two holders named), limit 3 entering
  beside two holders, and SIGTERM ending the child (143, child gone).

Create `plugins/kenspc/skills/autopilot/scripts/suite-slots.sh` as the plan's
§ The wrapper, `suite-slots.sh` specifies: the interface
`suite-slots.sh run [--limit <n>] [--wait <seconds>] -- <command> [<arg>…]`,
N from `--limit` else `KENSPC_AUTOPILOT_SUITE_LIMIT`, `--wait` defaulting to
90, the lock directory `/tmp/kenspc-suite-slots` (mode 700, overridable by
`KENSPC_SUITE_SLOTS_DIR`), the `mkdir` mutex with its `owner` file, the count
of live `holder-*` files against the caller's own N, the holder file layout
(`holder-<wrapper pid>`, `key=value` lines in the order `wrapper_pid`,
`wrapper_start`, `command_pid`, `command_start`, `taken`, `cwd`, `command`,
each write through `.tmp-<wrapper pid>` and `mv`), the stale-holder rule
(both pids, with their recorded `ps -o lstart=` start times; a stale holder
renamed to `reclaimed-<its file name>`), the stale-mutex rule (dead owner
pid, or no `owner` file and older than 10 seconds by `stat -f %m` falling
back to `stat -c %Y`), the background child with `KENSPC_SUITE_SLOT_HELD=1`
and `wait`, the traps on EXIT, INT, TERM, and HUP (SIGTERM to the child,
then wait), the nested call, the busy line and exit 75, and the log lines
under `KENSPC_AUTOPILOT_SUITE_LOG`.

The header comment gives the interface, the exit codes (the command's
status, 75 busy, 2 usage or lock-directory error), the lock layout, the
stale rules, and the Why of each, in the header style of `temp-candidates.sh`
in the same directory, and names the other-owner refusal as the one branch
the guard cannot reach. It also names, as known gaps the wrapper accepts
(plan § Risks and Mitigations), the two the plan leaves unmitigated: the
forwarded SIGTERM reaches the child's pid only, so grandchildren that do not
pass it on (`sh <file>` waiting on a foreground suite, a test host) can keep
the ports in use after the holder turns stale; and two waiters that both see
a dead mutex owner can each reclaim the mutex, one removing the other's
fresh one, so N + 1 holders can run. Why in the header: the plan is deleted
once it ships, and the header is where a later reader of the wrapper looks.
Bash 3.2 features only: no `declare -A`, no
`flock`. Mark the file executable, as the other scripts in that directory
are.

**Acceptance criteria:**
- `bash -n plugins/kenspc/skills/autopilot/scripts/suite-slots.sh` exits 0,
  and `ls -l` shows the file executable.
- `grep -nE 'declare -A|flock' plugins/kenspc/skills/autopilot/scripts/suite-slots.sh`
  prints nothing and exits 1; the same pattern over `CLAUDE.md` prints a
  line (the positive control).
- Under `/bin/bash` (3.2 on macOS), with `KENSPC_SUITE_SLOTS_DIR` set to a
  directory under `$TMPDIR`: `run --limit 1 -- true` exits 0,
  `run --limit 1 -- sh -c 'exit 3'` exits 3, and `run --limit 0 -- true`
  exits 2; the lock directory holds no `holder-*` file afterwards. The
  directory is then removed and its absence shown.
- `bash scripts/check-no-model-names.sh` exits 0.
- `grep -n -i 'grandchild' plugins/kenspc/skills/autopilot/scripts/suite-slots.sh`
  and `grep -n 'N + 1' plugins/kenspc/skills/autopilot/scripts/suite-slots.sh`
  each print a header line.

---

### Task 2: Guard fixtures for the wrapper

**Status:** DONE

**Implementation notes:**
- Decisions: the wrapper's four mutants run the wrapper's fixtures alone
  (`run_slot_only`), while the seven earlier mutants and the positive and
  restoration passes run every fixture through `run_checks`, which gained
  the fourth parameter. Fixtures 3, 6, and 8 stand on hand-written holder
  files backed by two background `sleep 30` processes and their real
  `ps -o lstart=` start times, so they need no wrapped holder to wait out;
  fixtures 1 and 2 share one pair of wrapped `sleep 3` holders, and the
  third run of fixture 2 wraps `sleep 1` rather than `true` so a mutant that
  lets it in is caught by the 0.2-second samples too. The wrapper runs under
  `/bin/bash` where it exists. The guard unsets
  `KENSPC_AUTOPILOT_SUITE_LIMIT`, `KENSPC_AUTOPILOT_SUITE_LOG`,
  `KENSPC_SUITE_SLOT_HELD`, and `KENSPC_SUITE_SLOTS_DIR` at its start, since
  a run inside a wrapped suite or a worker would otherwise turn every
  fixture into a nested call. Every background pid also goes into
  `BG_PIDS`, killed by the EXIT trap, so an error that ends the guard
  mid-fixture leaves no `sleep` behind.
- Changes/tradeoffs: fixture 5's holder pairs a reaped wrapper pid with the
  guard's own live `sleep` as its command pid under a 1970 start time, so it
  checks the start-time comparison as well as the dead pid; it also asserts
  the `reclaimed-holder-<pid>` file. Fixture 1 also asserts the log's busy
  line, and fixture 2 the three `acquired` lines. Wall time of
  `bash scripts/check-autopilot-scripts.sh --self-test`: 5.1 s before this
  task, 1 min 31 s after (each full pass pays about 7 s of wrapper sleeps
  and busy waits, nine full passes and four wrapper-only passes). Red
  counts: count check always true 8, stale-holder reclaim removed 3,
  release on exit removed 2, nesting check removed 2. Captured around a
  self-test run: no new `suite-slots.sh` or `sleep` process and no new
  `tmp.*` entry under `$TMPDIR` (a sample taken during the run showed the
  guard's `tmp.*` directory and its wrapped `sleep 3` holders, the positive
  control). `bash scripts/check-all.sh --self-test` exits 0 with
  `guards run: 13` and `self-tests run: 12`.

Depends on: Task 1

Extend `scripts/check-autopilot-scripts.sh` to cover `suite-slots.sh`, as
the plan's Step 2 specifies, with `KENSPC_SUITE_SLOTS_DIR` pointing into the
guard's own `mktemp -d` directory (`$WORK`). Before the first edit, measure
the wall time of `bash scripts/check-autopilot-scripts.sh --self-test` with
`time`; measure it again when the task is done.

Where the code goes today: the script paths are set at the top
(`SCRIPTS`, `EXTRACT_SRC`, `ZERO_SRC`, `TEMP_SRC`, and the existence loop
that exits 2 for a missing script); every assertion lives in one function,
`run_checks <ex> <zd> <tc>`, which gains a fourth parameter for the wrapper,
and every call site of it changes (the self-test's positive, mutant, and
restoration passes and the main-mode call); `run_self_test` copies the
scripts and writes mutants through `mutate()`, which exits 2 when its `sed`
changes nothing.

The ten fixtures of the plan's Step 2, each asserting the exit code and,
where the plan names one, the stderr or log line: (1) two `sleep 3`
holders at limit 2 and a third run with `--wait 1` exits 75 with a
`suite-slots: busy` line naming two holders; (2) the same third run with
`--wait 10` exits 0 after a holder ends, with no sampled moment (every 0.2
seconds) showing more than two holder files; (3) limit 3 with two live
holders and `--wait 1` acquires (exit 0), and limit 2 with the same holders
and `--wait 1` waits and exits 75; (4) a wrapped
`sh -c 'exit 3'` exits 3 and leaves no holder file; (5) a holder file with a
dead pid and a mismatched start time is reclaimed (limit 1, `--wait 2`
acquires, the log shows `reclaimed`); (6) a holder whose wrapper pid is dead
but whose command pid is a live `sleep` is not reclaimed (limit 1,
`--wait 1` exits 75); (7) a mutex directory with no `owner` file,
backdated beyond 10 seconds with `touch -t`, is reclaimed (a run with
limit 1 and `--wait 2` acquires and exits 0); (8) a nested
call (`KENSPC_SUITE_SLOT_HELD=1`) at limit 1 with one live holder runs at
once and the log shows `nested`; (9) a wrapped run killed with SIGTERM
removes its holder file and its child `sleep` is gone (`ps -p` on that
pid); (10) usage errors exit 2: no `--`, no limit, limit `0`, limit `x`,
and a regular file in the lock directory's place. Every background holder a
fixture starts is waited for or killed by its pid before the fixture ends.

Four new self-test mutants, each written to its own file with `sed`: the
count check made always true; the stale-holder reclaim removed; the release
on exit removed; the nesting check removed. Each must turn the guard red;
the unmutated copy must then pass. To keep the self-test's time bounded
(plan § Risks, The guard's run time), the wrapper's four mutants may run
only the wrapper's fixtures; record which way was chosen.

Update the header: four helper scripts, the wrapper's fixtures in the
fixture list, eleven mutants in the `--self-test` paragraph, and the final
OK message that names the scripts.

**Acceptance criteria:**
- `bash scripts/check-autopilot-scripts.sh` and
  `bash scripts/check-autopilot-scripts.sh --self-test` exit 0.
- Each of the eleven mutants' red runs prints
  `OK    mutant '<name>': red (<n> assertions failed)`, the four new ones
  among them.
- `bash scripts/check-all.sh --self-test` exits 0 and prints
  `guards run: 13` and, as its last line, `self-tests run: 12`.
- After the guard runs, no process it started is left and its work
  directory is gone: `ps -A -o pid=,ppid=,args=` and `ls -d "$TMPDIR"/tmp.*`
  are captured right before and right after
  `bash scripts/check-autopilot-scripts.sh --self-test`, and the after
  listings hold no `suite-slots.sh` process, no `sleep` process, and no
  `tmp.*` entry that the before listings did not. Why compare listings
  rather than filter on the guard's pid: a child left behind is reparented
  when the guard exits, so a filter on the guard's pid finds nothing
  whatever was left.
- The task's Implementation notes record the self-test's wall time before
  and after this task.

---

### Task 3: The drivers pass the limit

**Status:** DONE

**Implementation notes:**
- Decisions: `launch()` reads the three inputs into locals at its top, and
  the log path is built from the resolved logs directory after its
  `mkdir -p`, so `KENSPC_AUTOPILOT_SUITE_LOG` is absolute whatever
  `AUTOPILOT_LOGS` was given as. Each export is one line of its own in the
  subshell (and one `$env:` line in run.ps1's inner script), so deleting one
  line drops exactly one variable. In run.ps1 the placeholders are
  `__SUITELIMIT__`, `__SUITECOMMANDS__`, `__SUITEWRAPPER__`, and
  `__SUITELOG__`, without an inner underscore, since the template's
  replacement matches `__[A-Z]+__`. The stale caller values the self-tests
  set (`97`, `kenspc-selftest-stale-command`, `/kenspc-selftest-stale-wrapper`,
  `/kenspc-selftest-stale-log`) stay in place for every launch, so the
  inputs-set launch also fails on a deleted export, not only the unset one.
- Changes/tradeoffs: the new launches use the free tags `selftest-s17`
  (inputs set) and `selftest-s18` (inputs unset) in both drivers; each
  self-test failure names the variable, and run.sh's also quotes the value
  the stub saw. The refusal of a relative wrapper path is checked before the
  first launch, beside the workspace refusals. The self-test header comments
  list the new items. `pwsh` on this Mac is a .NET tool that found no
  runtime from this shell (`You must install .NET`, exit 131); the runtime
  is in `~/.dotnet`, so the PowerShell runs used
  `DOTNET_ROOT=$HOME/.dotnet` on the command line, with nothing installed.
  Mutation runs on copies under `$TMPDIR` (removed afterwards, absence
  shown): each of the four export lines deleted from each driver made its
  self-test exit 1 naming that variable (eight runs). The self-tests' own
  `autopilot-selftest*` directories under `$TMPDIR` from these runs were
  removed by path.

Implement the plan's § The driver and Step 3 in
`plugins/kenspc/skills/autopilot/scripts/run.sh` and its PowerShell mirror
`run.ps1`.

In `run.sh`: read `AUTOPILOT_SUITE_LIMIT`, `AUTOPILOT_SUITE_COMMANDS`, and
`AUTOPILOT_SUITE_WRAPPER` in `launch()`. Export
`KENSPC_AUTOPILOT_SUITE_LIMIT`, `KENSPC_AUTOPILOT_SUITE_COMMANDS`,
`KENSPC_AUTOPILOT_SUITE_WRAPPER`, and `KENSPC_AUTOPILOT_SUITE_LOG` in the
background subshell beside the two marker exports
(`export KENSPC_AUTOPILOT_WORKER=1`), so a fresh launch and a resume both
get them; each overwrites the caller's value and is the empty string when
its input is unset; the log variable is `<logs>/<batch>-suite-slots.log`
when `AUTOPILOT_SUITE_LIMIT` is non-empty and empty otherwise. Refuse a
non-empty `AUTOPILOT_SUITE_WRAPPER` that is not an absolute path beside the
`AUTOPILOT_WORKSPACE` refusal, through `die` (exit 2), before the `.session`
write, naming the variable. Update the header: the Environment list (three
inputs), the Exported list (four variables) with the Why from the plan, and
the paragraph on a caller's own passing stub, which names the two exported
variables it echoes today and names six after this task.

Extend `--self-test` as the plan's Step 3 lists: both built-in stubs
(`$base/stub/claude` and `$base/stub/fail`) echo the four variables to
stderr; one launch with the inputs set shows each value, the log variable
as `<logs>/selftest-suite-slots.log`; one launch with the inputs unset,
while the self-test's caller environment holds stale
`KENSPC_AUTOPILOT_SUITE_*` values (set beside the existing stale
`KENSPC_AUTOPILOT_WORKER=0`), shows each variable empty; a launch with
`AUTOPILOT_SUITE_WRAPPER` set to a relative path returns 2, writes no
`.session`, and names the variable.

Mirror all of it in `run.ps1`: the inputs, the four `$env:` assignments in
the inner script beside `$env:KENSPC_AUTOPILOT_WORKER`, the refusal beside
the `AUTOPILOT_WORKSPACE` one (`IsPathFullyQualified`), the header lists and
caller-stub paragraph, the `claude.ps1` and `fail.ps1` stubs, and the
self-test items.

**Acceptance criteria:**
- `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test` prints
  `self-test passed` and exits 0.
- `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  prints `self-test passed` and exits 0.
- For each of the four new export lines and each driver (eight runs), a
  copy under `$TMPDIR` with that one line deleted makes its self-test exit
  1 with output naming that variable. The copies are removed afterwards and
  their absence shown.
- `bash scripts/check-all.sh` exits 0.

---

### Task 4: The hook's suite check (f)

**Status:** TODO

Add check (f) to `plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh` as
the plan's § The hook's new check specifies, and extend
`scripts/check-autopilot-rails-hook.sh` as its Step 4 specifies.

In the hook: pass `KENSPC_AUTOPILOT_SUITE_COMMANDS` to the awk scan (the
`awk -v sq=… "$RM_AWK"` call) and split it on `|`. In `check()`, after the
assignment, keyword, and wrapper skips and before the `rm` branch, compare
each listed prefix with the words from the command word on: the first word
against `bname(w[i])`, the later words as written, whole word by whole
word. A match sets `found` with a mark of its own, as `gh` and `git` use
`\003`; the shell side denies it with a reason of its own, opening
`autopilot rails:`, naming the prefix, and giving the route of the plan's
deny reason with the value of `KENSPC_AUTOPILOT_SUITE_WRAPPER`; it names no
`.trash` and none of the no-route text. With
`KENSPC_AUTOPILOT_SUITE_COMMANDS` empty, (f) checks nothing. The check reuses
the existing scan; it adds no second pass over the command. Add the header
paragraph for (f) and its known misses, listed in full in (f)'s paragraph:
a listed command reached through a script file, `bash -c`, `make`, `eval`,
a variable, or an alias, or after a wrapper the scan does not skip
(`timeout`, `nice`).

In the guard: `decide()` unsets `KENSPC_AUTOPILOT_SUITE_COMMANDS` and
`KENSPC_AUTOPILOT_SUITE_WRAPPER` with the two marker variables and sets
them per fixture, so every existing fixture runs with them empty. Add a
`deny-suite` expectation: exit 2, a reason opening `autopilot rails:` that
names the fixture wrapper path, no `.trash`, and no no-route text. With
`KENSPC_AUTOPILOT_SUITE_COMMANDS='dotnet test|pnpm test'` and a fixture
wrapper path:
- denied: `dotnet test`, `dotnet test --filter X`, `cd a && dotnet test`,
  `sudo dotnet test`, `time pnpm test`, `echo x; pnpm test`,
  `$(dotnet test)`, `/usr/local/share/dotnet/dotnet test`;
- allowed: `bash /w/suite-slots.sh run -- dotnet test`, `echo "dotnet test"`,
  `grep 'dotnet test' f`, `dotnet build`, `dotnet testx`, `pnpm install`,
  and a `dotnet test` inside a heredoc body;
- inert: `dotnet test` with the commands variable empty, and the same with
  the marker unset.
The existing replay of every denied fixture with the marker unset and `0`
carries the suite variables, so it shows the marker gates (f) too. Add a
ninth hook mutant, the suite check removed, whose first red fixture is
pinned to `dotnet test` in the guard's first-red table. Update the guard's
header for the new expectation, fixtures, and mutant.

**Acceptance criteria:**
- `bash scripts/check-autopilot-rails-hook.sh` and
  `bash scripts/check-autopilot-rails-hook.sh --self-test` exit 0, the
  self-test reporting the suite-check mutant red, first on `dotnet test`.
- The existing timed fixtures still pass their 2.5-second bound.
- `bash -n plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh` exits 0,
  and `bash scripts/check-all.sh` exits 0.

---

### Task 5: The autopilot SKILL.md text

**Status:** TODO

Depends on: Task 1, Task 3, Task 4

Edit `plugins/kenspc/skills/autopilot/SKILL.md` as the plan's § The SKILL.md
text and Step 5 list, naming the real interfaces Tasks 1, 3, and 4 built:
- § The `## Autopilot` section: a `Suite limit:` row in the field table
  (repo mode only, default unset) and a grammar paragraph after the table,
  as `Role settings:` has one;
- § The start checks: a settings-stop bullet naming `Suite limit:` — a value
  outside its grammar, and the field in plugin mode (ruling 9);
- § The settings line: `suite limit <<n> (<k> commands)|none>` after the
  `walk …` field;
- Phase 0: the copy paragraph (`suite-slots.sh` to
  `_prompts/<batch>-suite-slots.sh`), and the Inputs and Constraints that
  say "the three scripts" and "the three script copies";
- § The workspace tree: `_prompts/<batch>-suite-slots.sh` and
  `_logs/<batch>-suite-slots.log`;
- § Launch, wait, return: every launch sets the three `AUTOPILOT_SUITE_*`
  inputs explicitly, a resume the values its tag was launched with;
- preamble § 3: `/tmp/kenspc-suite-slots` among the allowed write
  locations;
- preamble § 6: the `Suite limit:` line — the listed commands take a slot
  in the machine-wide lock, at most N at once across every batch on the
  machine; the wrapper line; exit 75 with the busy line means run the same
  line again, never the command without the wrapper; the Bash call's
  timeout allows 90 seconds more than the command alone needs; a
  subagent's dispatch carries the same line; the hook denies an unwrapped
  listed command; and the long-wait question after 30 minutes of busy
  returns — and the rule that the line is omitted when the field is absent;
- the repo-mode S4 task block only (the plugin-mode block is unchanged,
  ruling 9): a case whose command file holds a listed prefix runs as
  `bash <wrapper copy> run -- <shell> <file>`;
- Phase 3 § A corrected case: the main session's evidence runs take a slot
  the same way, with `--limit <n>` and `KENSPC_AUTOPILOT_SUITE_LOG` on the
  line;
- § How the main session rules: the ruling on a long wait (ruling 7);
- § The stop conditions: stop condition 12, a holder aged 60 minutes or
  more, with what its message names;
- § The driver: the three inputs and the four exports;
- § The reviewer report: the `Suite slots:` line in the template and its
  description among the field descriptions below it.

Each new rule carries its Why in the skill's own words: evidence is stated
as what failed and on which command (more than about two runs of one
integration suite at once exhausted a machine's local ports), not cited as
a dry-run record or a path outside the plugin, and no project is named (the
plan's Objective; CLAUDE.md, Writing Rules for Skill Content). A sentence for a
session that cannot ask opens with the skill's fixed wording, "In a session
that cannot ask (a system reminder to work without stopping), …".

**Acceptance criteria:**
- `bash scripts/check-all.sh` exits 0, with `check-autopilot-rails-hook.sh`
  among the passing guards.
- `grep -n 'Suite limit' plugins/kenspc/skills/autopilot/SKILL.md` shows the
  table row, the grammar paragraph, the start checks' settings-stop bullet,
  and preamble § 6's line; `grep -n 'suite limit <<n>'` over the same file
  shows the settings line template.
- `grep -n 'kenspc-suite-slots' plugins/kenspc/skills/autopilot/SKILL.md`
  shows preamble § 3.
- `grep -n 'suite-slots' plugins/kenspc/skills/autopilot/SKILL.md` shows the
  copy paragraph, the workspace tree, the repo-mode S4 block, the corrected
  case, and the reviewer report's source log; the plugin-mode S4 block
  holds no `suite-slots`.
- `claude plugin validate --strict ./plugins/kenspc` exits 0.

---

### Task 6: Live checks on this Mac

**Status:** TODO

Depends on: Task 1-5

Run the two live checks of the plan's Step 6 and record them in
`docs/dry-runs/suite-slots-live.md`. Use this repository's
`plugins/kenspc` (the plan's "this worktree" is this checkout on `main`).

1. The hook in a real headless session. The `claude -p` session here is
   the object under test, not delegated work: the hook fires only in a
   real session, and no fixture reaches the harness's own call. Start it in
   the foreground, in a throwaway directory under `$TMPDIR`, with
   `--plugin-dir <repo>/plugins/kenspc`,
   `--permission-mode bypassPermissions`, a `--max-budget-usd` cap, and a
   `timeout`; its environment holds `KENSPC_AUTOPILOT_WORKER=1`, write
   roots for that directory, `KENSPC_AUTOPILOT_SUITE_COMMANDS=kenspc-probe-suite`,
   and `KENSPC_AUTOPILOT_SUITE_WRAPPER` set to the absolute path of
   `plugins/kenspc/skills/autopilot/scripts/suite-slots.sh`. Prompt: run
   `kenspc-probe-suite --x` in Bash and quote the error. Then the red case:
   the same probe without `KENSPC_AUTOPILOT_SUITE_COMMANDS`.
2. Three concurrent wrappers: in three background shells,
   `bash suite-slots.sh run --limit 2 --wait 30 -- sleep 5`, with
   `KENSPC_SUITE_SLOTS_DIR` under `$TMPDIR` and `KENSPC_AUTOPILOT_SUITE_LOG`
   set.

**Acceptance criteria:**
- Check 1: the quoted error opens `autopilot rails:` and names the wrapper;
  the red case shows `command not found` instead.
- Check 2: the log shows three `acquired` lines, and the third waited at
  least 4 seconds.
- The record holds each command, its exit code, and its output.
- The throwaway directory and the `$TMPDIR` lock directory are removed
  afterwards, and their absence is shown.

---

### Task 7: Doc-sync

**Status:** TODO

Depends on: Task 1-6

Bring the documents below in line with what Tasks 1-6 implemented, as
recorded in their `**Implementation notes:**` blocks, and promote their
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `plugins/kenspc/README.md` § Autopilot — the `## Autopilot` label list
  (headed "The twenty labels and their defaults:", which becomes
  twenty-one) gains `Suite limit:`, repo mode only; the driver's
  environment and exports (The drivers paragraph); the rails hook
  paragraph (check (f) and its route); the workspace tree and The drivers
  paragraph, which name "the three scripts" copied per batch and the files
  under `_logs/`; the reviewer report's `Suite slots:` line; a sentence on
  the machine-wide lock and the `/tmp/kenspc-suite-slots` directory, naming
  native Windows as unchecked; and the **Stops.** paragraph, which lists
  every stop condition: it gains the new stop (a suite-slot holder aged 60
  minutes or more on a worker's long-wait question), and its settings-stop
  examples gain a `Suite limit:` field outside its grammar or in `plugin`
  mode (plan steps 1, 3, 4, 5; the plan's Documentation impact does not
  name the Stops paragraph, added here because it enumerates the stops).
- `CLAUDE.md` § Plugin Directory Layout and § File Structure — the tree
  gains `suite-slots.sh`, and the `scripts/` bullet's "three helper
  scripts" becomes four and "`check-no-model-names.sh` scans all five"
  becomes six (plan step 1).
- `CLAUDE.md` § the hooks paragraph — check (f) and the four new exported
  variables (plan steps 3, 4).
- `CLAUDE.md` § Sessions, not agents (autopilot) — the lock across batches,
  repo mode only (plan step 5).
- `CLAUDE.md` § Repository scripts/ — the `check-autopilot-scripts.sh` entry
  (four scripts, the wrapper's fixtures, eleven mutants; plan step 2) and
  the `check-autopilot-rails-hook.sh` entry (the `deny-suite` expectation
  and its fixtures, nine hook mutants; plan step 4).
- `CLAUDE.md` § the maintenance note — `suite-slots.sh` joins the files
  after whose edit `check-autopilot-scripts.sh` runs (plan step 1).
- `plugins/kenspc/CHANGELOG.md` — an entry under a new
  `## 4.10.0 — unreleased` heading, the form the repository uses before a
  release (plan steps 1–5).
- `docs/roadmap.md` — item 32 leaves the file, since it ships (plan step 7).

`docs/release-checklist.md` and the root `README.md` are N/A for this
document, as the plan's Documentation impact records, and stay unchanged.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Tasks 1-6. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Tasks 1-6 implemented, so
  that a reader of that document alone learns it: the field's grammar and
  repo-mode limit, the wrapper's interface and exit codes, the driver's
  inputs and exports, check (f) and its route, and the long-wait stop.
- Every promoted decision appears in the document named for it, in that
  document's language.
- `docs/roadmap.md` no longer holds item 32.
- `docs/release-checklist.md` and `README.md` are unchanged.
- `bash scripts/check-all.sh --self-test` exits 0.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).
