# Plan: a machine-wide limit on full test suites across autopilot batches

## Objective

Let several autopilot batches run on one machine at the same time without
running more heavy test suites at once than the machine can take, with no
session acting as a dispatcher and no project named in the plugin.

A heavy suite is a command a batch's spec lists. Before one runs, it takes
a slot from a lock shared by the whole machine, which holds at most N
slots at once. N and the list come from a new `## Autopilot` field. The
lock binds the main session, every worker, and every subagent a worker
dispatches.

In scope:

- A slot wrapper script shipped beside the driver,
  `skills/autopilot/scripts/suite-slots.sh`.
- A new `## Autopilot` field, `Suite limit:`.
- The driver (`run.sh`, mirrored in `run.ps1`) passes the field's values
  to every worker.
- The rails hook denies a listed command run without the wrapper.
- The autopilot SKILL.md text that ties these together: the field, the
  settings line, the copy, the launch, the preamble, the S4 task blocks,
  and the main session's own runs.
- The guard fixtures and mutants that hold the wrapper and the hook's new
  check.
- The documentation these make stale.

Out of scope:

- Sessions outside autopilot. An interactive `/kenspc-task-review` or
  `/kenspc-task-implement` takes no slot, and their `canonical:dispatch`
  blocks do not change (the user's ruling, 2026-10-17). A user who wants
  such a session to wait its turn can run the wrapper by hand.
- Exemptions for small runs. A listed command takes a slot whatever its
  arguments, `dotnet test --filter X` included (the user's ruling,
  2026-10-17).
- A bypass after a long wait. A busy wrapper is run again, never skipped
  (the user's ruling, 2026-10-17).
- The existing gate line of preamble § 6 (another session's go before a
  full suite, set by a spec), which stays as it is. A spec may still set
  such a gate; the slot lock does not replace it.
- Native Windows sessions beyond what `run.ps1` already mirrors: the
  wrapper is a bash script, and it is checked on macOS only (see Risks).
- Tagging, pushing, and the GitHub release: the release procedure, run
  after this plan by the user's go.

## Background

On 2026-10-17 the user ran three autopilot batches at once in the
dayaku-crm repository and coordinated their test-suite ports by hand at
the start. The measured fact, as the batches' prompts record it
(`~/Projects/_smoke/_prompts/participant-import-s3.md`, the constraints and
`Run facts:` lines): more than about two `dotnet test` runs of one
integration suite at the same time exhaust the Mac's local ports, and
tests then fail on `Can't assign requested address`, not on an assertion.

What binds suites today:

- **`Run facts:`, per batch.** Each batch's facts bound that batch alone
  ("the plan's constraint of one `dotnet test` at a time covers you and
  your subagents together"), so three batches could still run three suites
  at once.
- **A planning session's go, across batches.** The dayaku-crm specs set a
  gate through preamble § 6: the session about to run a whole suite sends
  `suite <batch> <tag>: start?` to a planning session, waits for its `go`,
  and sends `ended` afterwards (for example
  `~/Projects/_smoke/_prompts/scheduling-board-preamble.md`, line 149). It
  works only where a spec writes it and a session stays up to answer. It
  also falls back to "ten minutes without an answer means go on". A
  subagent has no message tool, so the worker has to ask on its behalf.

The 4.9.0 delegation-alignment research put this as its question 11. The
user ruled that a machine-wide lock is wanted, that it is planned apart
from 4.9.0, and that it must not be hard-coded to dayaku-crm. 4.9.0
recorded it as `docs/roadmap.md` item 32.

### Rulings taken in this plan's discussion (2026-10-17)

| # | Question | Ruling |
|---|---|---|
| 1 | How the lock binds a worker's subagents | Preamble text plus the rails hook: a listed command run without the wrapper is denied, in the worker's calls and its subagents' alike |
| 2 | Whether a small run (`--filter`) takes a slot | Yes, every run of a listed command takes one, whatever its arguments |
| 3 | Where N and the commands come from, and N across batches | A new `## Autopilot` field. Each acquirer enters only while fewer than its own N slots are held. No field, no lock |
| 4 | Where the lock lives | A fixed path, `/tmp/kenspc-suite-slots`, named as an allowed write in preamble § 3 |
| 5 | A wrapper that finds no slot in time | It returns busy and the same line is run again. No bypass. Waits are logged for the reviewer report |
| 6 | Sessions outside autopilot | Out of scope |

## Technical Approach

### The wrapper, `suite-slots.sh`

```
suite-slots.sh run [--limit <n>] [--wait <seconds>] -- <command> [<arg>…]
```

- **N.** The limit is `--limit`, else `KENSPC_AUTOPILOT_SUITE_LIMIT` from
  the environment. With neither, or with a value that is not a positive
  integer, the wrapper exits 2 with a usage line. `--wait` defaults to 90
  seconds.
- **The lock directory.** `/tmp/kenspc-suite-slots`, created with mode 700
  when missing. If it exists but is not a directory, the wrapper exits 2
  naming the path; if it is a directory not owned by the current user, it
  exits 2 naming the owner. `KENSPC_SUITE_SLOTS_DIR` overrides the
  path; it exists only so the guard's fixtures never touch the machine's
  real lock.
- **Taking a slot.** The wrapper takes a short mutex
  (`mkdir <dir>/mutex`, atomic on every POSIX file system). It then counts
  the live holder files `<dir>/holder-*`. When fewer than its own N are
  live, it writes its own holder file and releases the mutex; otherwise it
  releases the mutex and polls again, about once a second. Why a count
  under a mutex and not numbered slot directories: with numbered slots
  `slot-1…slot-N`, a batch whose N is 2 could take a free `slot-1` while
  `slot-2` and a looser batch's `slot-3` are held, making three holders.
  Ruling 3 says each acquirer enters only while fewer than its own N are
  held.
- **A holder file.** Each holder file records the wrapper's pid and its
  start time (`ps -o lstart= -p <pid>`), the command's pid and start time,
  the epoch second it was taken, the cwd, and the command's first 120
  characters. The layout, which step 2's fixtures write by hand: the file
  `<dir>/holder-<wrapper pid>`, one `key=value` line per field, in this
  order — `wrapper_pid`, `wrapper_start`, `command_pid`, `command_start`,
  `taken`, `cwd`, `command` — each value running to the end of its line.
  The wrapper writes the file under the mutex with the two command fields
  empty, starts the command, and then rewrites it with them filled in.
  Each write goes to `<dir>/.tmp-<wrapper pid>` first and is renamed over
  the holder file with `mv`, so a counting wrapper never reads a
  half-written file.
- **Stale holders.** A holder is stale when neither of its two pids is
  alive with the recorded start time; a holder whose command fields are
  still empty is judged by its wrapper pid alone. A stale holder is moved
  aside by the counting wrapper, under the mutex, and not counted: renamed
  to `<dir>/reclaimed-<its file name>`, which the count's `holder-*`
  pattern does not match, and kept as the evidence behind the log's
  `reclaimed` line. Why both pids: a
  wrapper killed with SIGKILL runs no trap and leaves the command running,
  and that command still uses the ports. Why the start time: a pid reused
  after a reboot or a long run would otherwise keep a dead holder alive.
- **A stale mutex.** The mutex holds an `owner` file with the taker's pid.
  It is reclaimed when that pid is dead. It is also reclaimed when it has
  no `owner` file and is older than 10 seconds: a taker killed between the
  `mkdir` and the write leaves it so. Its age is the current epoch second
  (`date +%s`) minus the directory's modification time, read with
  `stat -f %m` (BSD, macOS) and, when that fails, `stat -c %Y` (GNU).
- **Running the command.** The wrapper starts the command as a background
  child with `KENSPC_SUITE_SLOT_HELD=1` exported and waits for it with
  `wait`, so its traps run while the child does. It removes its holder file
  on exit and on SIGINT, SIGTERM, and SIGHUP; on any of those signals it
  first sends SIGTERM to the child and waits for it. Why SIGTERM whatever
  signal arrived: a background child of a non-interactive bash ignores
  SIGINT, so a forwarded SIGINT would leave the suite running. It exits
  with the command's status.
- **A nested call.** With `KENSPC_SUITE_SLOT_HELD=1` already set, the
  wrapper runs the command directly and takes no slot. Why: an acceptance
  command that is itself wrapped, run through the wrapper by S4, would
  otherwise wait on its own slot forever when N is 1.
- **Busy.** No slot within `--wait` seconds: the wrapper prints
  `suite-slots: busy after <s>s; held by: <one line per holder: age, cwd,
  command>` on stderr and exits 75 (EX_TEMPFAIL). The stderr line is what
  tells this apart from a command that exits 75 itself. Why 90 seconds: it
  stays under the Bash tool's default two-minute timeout. A call killed by
  that timeout while waiting would return no busy line, and the agent
  would not know to run it again.
- **The log.** With `KENSPC_AUTOPILOT_SUITE_LOG` set, the wrapper appends
  one line per event to that file: `<UTC time> <event> pid <pid> waited
  <s>s holders <k> — <command, first 80 characters>`. The events are
  `acquired`, `busy`, `released <status>`, `nested`, and
  `reclaimed <stale pid>`. With the variable unset, nothing is logged.
- **Portability.** The wrapper uses bash 3.2 features only (no
  `declare -A`) and no `flock`, which macOS lacks, in line with the guards'
  portability rule in CLAUDE.md. Its tools are POSIX ones plus three that
  POSIX does not define but both macOS (BSD) and Linux (GNU, procps)
  provide: `ps -o lstart=`, `date +%s`, and `stat` in the two spellings
  above.

### The field, `Suite limit:`

```
- Suite limit: 2
  - `dotnet test`
  - `pnpm test`
```

- **The grammar.** The value is a positive integer. Each sub-bullet is one
  code span holding a command prefix: one or more words, none of them
  holding `|`, a quote, or a newline. The field may be written with a
  note, like any label.
- **When it is a settings stop.** The run stops before any launch when the
  value is not a positive integer, the field has no sub-bullet, or a
  sub-bullet is not exactly one code span or breaks the word rule. Why a
  stop: a limit the hook cannot apply would let suites run unbounded while
  the settings line said otherwise.
- **Absent.** With no `Suite limit:` field there is no lock. The wrapper
  is still copied, but no worker is told to use it and the hook checks
  nothing. Why: the plugin names no project's suite, and a default list
  would be hard-coded.
- **The settings line** gains `suite limit <<n> (<k> commands)|none>`,
  written after the `walk …` field.
- **One pool.** Every listed command of every batch counts against the
  same lock. A batch that lists `dotnet test` and one that lists
  `pnpm test` share it. Why: the exhausted resource, the machine's local
  ports, belongs to no one command.
- **`Run facts:` stays free text.** It is the measured fact behind the
  field, written for a worker to read a failure correctly. Ruling 3 keeps
  the machine-readable limit out of it, since free text cannot be parsed
  reliably.

### The driver

`run.sh` and `run.ps1` read three new optional inputs and export them to
every worker, on a fresh launch and on a resume. Like the marker, each
overwrites any value the caller's environment holds, and each is the
empty string when its input is unset:

| Input | Exported as |
|---|---|
| `AUTOPILOT_SUITE_LIMIT` | `KENSPC_AUTOPILOT_SUITE_LIMIT` |
| `AUTOPILOT_SUITE_COMMANDS` (the prefixes joined by `\|`) | `KENSPC_AUTOPILOT_SUITE_COMMANDS` |
| `AUTOPILOT_SUITE_WRAPPER` (the wrapper copy's absolute path) | `KENSPC_AUTOPILOT_SUITE_WRAPPER` |

The driver also exports `KENSPC_AUTOPILOT_SUITE_LOG` as
`<logs>/<batch>-suite-slots.log` when `AUTOPILOT_SUITE_LIMIT` is non-empty,
and as the empty string otherwise.

Why through the environment: a subagent inherits the worker's
environment, so the wrapper finds N, and the hook finds the list, without
any agent having to carry them. Why overwrite the caller's values: the
same reason the marker is overwritten. A value left in the main session's
environment would otherwise reach a worker of a batch with no limit.

### The hook's new check

`autopilot-worker-rails.sh` gains check (f). With the marker set and
`KENSPC_AUTOPILOT_SUITE_COMMANDS` non-empty, it denies a Bash command that
has a listed prefix at a command position. A command position is one the
existing checks (a) and (e) already recognize: the start of the command, a
line start, after `;`, `&&`, `||`, `|`, `&`, `(`, `$(`, or a backtick,
after a shell keyword, or after the wrappers `sudo`, `command`, `env`,
`xargs`, `exec`, `nohup`, and `time`. The prefix's words must match the
command's next words in order, whole word by whole word.

- `bash <wrapper> run -- dotnet test` passes, since there `dotnet` is an
  argument of `bash` and not at a command position.
- The prefix's first word is compared with the command word's base name,
  as (a) and (e) compare `rm`, `gh`, and `git`, so
  `/usr/local/share/dotnet/dotnet test` is denied too; the prefix's later
  words are compared as written.
- Quoted text and heredoc bodies stay arguments, as they are for (a) and
  (e).

The deny reason opens `autopilot rails:`, names the prefix, and gives the
route:

```
run it through the suite-slot wrapper:
bash <KENSPC_AUTOPILOT_SUITE_WRAPPER> run -- <the command>;
exit 75 with a "suite-slots: busy" line means run the same line again
```

It names no `.trash`. Like every hook denial, it is not a breach (preamble
§ 3).

Why the hook: ruling 1. A worker's subagents never see the preamble. The
hook fires for a subagent's call too, and the rails have reached
subagents before only through it. Known misses go into the hook's header:
a listed command reached through a script, `bash -c`, `make`, `eval`, a
variable, or an alias, or after a wrapper the scan does not skip
(`timeout`, `nice`), the misses (a) already lists.

### The SKILL.md text

- **§ The `## Autopilot` section.** The table gains `Suite limit:`, with
  the grammar and why above. The settings-stop sentence in § The start
  checks names the field.
- **Phase 0, the copy.** `suite-slots.sh` is copied with the other helper
  scripts, to `_prompts/<batch>-suite-slots.sh`, for the reason they are.
- **§ Launch, wait, return.** Every launch sets `AUTOPILOT_SUITE_LIMIT`,
  `AUTOPILOT_SUITE_COMMANDS`, and `AUTOPILOT_SUITE_WRAPPER` explicitly.
  With the field set, they hold its values and the copy's path; without
  it, the empty string. Why, as for `AUTOPILOT_MODEL`: a variable of the
  same name in this session's environment would otherwise reach the
  driver. A resume sets the values the tag it resumes was launched with.
- **The preamble, § 3.** The list of allowed write locations gains the
  lock directory, `/tmp/kenspc-suite-slots`. Why: without it, every slot
  taken would be a "write elsewhere under /tmp" to list under
  `## Rail observations`.
- **The preamble, § 6.** When the field is set, § 6 gains a `Suite limit:`
  line. It says that the listed commands take a slot in the machine-wide
  lock, at most N at once across every batch on the machine; gives the
  wrapper line; says that exit 75 with the busy line means run the same
  line again, never the command without the wrapper; says that the Bash
  call's timeout must allow 90 seconds more than the command alone needs;
  and says that a subagent's dispatch carries the same line. It notes that
  the hook denies an unwrapped listed command. Why the timeout: the 90
  seconds of § The wrapper keep a busy return under the Bash tool's
  default timeout, but a call that acquires late runs the suite too, and a
  timeout sized for the suite alone would kill it. With the field absent,
  the line is omitted, as the Allowed files line is.
- **The S4 task blocks (both).** A case whose command file holds a listed
  prefix is run as `bash <wrapper copy> run -- <shell> <file>`. A file
  holds a prefix when the prefix's words occur in it in order as whole
  words, anywhere in the file, whether or not at a command position. Why
  the looser test than the hook's: a false match only costs a slot, while
  a miss runs a suite unbounded. Why wrap at all: the hook sees
  `<shell> <file>`, not the suite inside the file.
- **The main session's own runs.** The corrected-case runs (Phase 3 § A
  corrected case) take a slot the same way when their command holds a
  listed prefix, by the S4 blocks' test, with `--limit <n>` and
  `KENSPC_AUTOPILOT_SUITE_LOG=<workspace>/_logs/<batch>-suite-slots.log`
  set on the line. The main session carries no marker, so the hook does not
  check it, and the text is all that binds it. The start checks' trial
  extraction runs no case command and takes no slot.
- **A long wait.** When busy returns for one command have spanned 30
  minutes, the worker sends the main session a `question <tag>:` quoting
  the last busy line. The main session rules: wait on, or stop the run
  naming the holders (how it chooses: Open Questions 2). The question
  goes into the preamble's § 6
  `Suite limit:` line. Why 30 minutes: it matches the worker's answer wait
  in § 1. A hung holder would otherwise hold the worker until its cap,
  with nothing in front of the main session but a quiet timeline.
- **§ The driver.** The block gains the three inputs and the four exports.
- **The reviewer report.** A `Suite slots:` line, read from
  `<batch>-suite-slots.log`:
  `Suite slots: <a> acquired, <b> busy returns (<s>s waited in all), longest single wait <w>s, <r> reclaimed`
  — `<a>` the `acquired` lines, `<b>` the `busy` lines, `<s>` the sum of
  the `waited` values on the `busy` lines, `<w>` the largest `waited`
  value on any line, `<r>` the `reclaimed` lines. Each wrapper call logs
  its own wait only, so a wait that spanned several busy returns shows in
  `<s>` and in the state file's `questions answered:` (A long wait), not in
  `<w>`. With the field absent, it reads `none`. Why: ruling 5 keeps no
  bypass, so the report is where a batch that waited long becomes
  visible.

## Implementation Steps

Steps 1, 3, and 4 depend on nothing else in this plan. Step 2 depends on
step 1. Step 5 depends on steps 1, 3, and 4. Step 6 depends on steps 1–5.
Step 7 depends on steps 1–6.

### Step 1: The wrapper script

**What.** Write `plugins/kenspc/skills/autopilot/scripts/suite-slots.sh`
as § The wrapper specifies. Its header comment gives the interface, the
exit codes (the command's status, 75 busy, 2 usage or lock-directory
error), the lock layout, the stale rules, and the Why of each, in the
header style of `temp-candidates.sh`, and names the other-owner refusal
as the one branch the guard cannot reach. Mark it executable, as the other
scripts in that directory are.

**Input.** § The wrapper.

**Output.** The script.

**Acceptance criteria.**

- `bash -n` passes.
- `grep -nE 'declare -A|flock' plugins/kenspc/skills/autopilot/scripts/suite-slots.sh`
  prints nothing and exits 1; the same pattern over `CLAUDE.md` prints a
  line, the positive control.
- Under `/bin/bash` (3.2 on macOS), with `KENSPC_SUITE_SLOTS_DIR` set to a
  directory under `$TMPDIR`: `run --limit 1 -- true` exits 0,
  `run --limit 1 -- sh -c 'exit 3'` exits 3, `run --limit 0 -- true` exits
  2, and the lock directory holds no `holder-*` file afterwards; the
  directory is then removed and its absence shown. Step 2's
  fixtures are the full check; this step's smoke runs only so step 1 can
  be accepted before step 2 exists.
- `bash scripts/check-no-model-names.sh` exits 0.

### Step 2: Guard fixtures for the wrapper

**What.** Extend `scripts/check-autopilot-scripts.sh` to cover
`suite-slots.sh`, with `KENSPC_SUITE_SLOTS_DIR` pointing into the guard's
own `mktemp -d` directory. Update its header: four helper scripts, the
wrapper's fixtures in the fixture list, and eleven mutants in the
`--self-test` paragraph. Every background holder a fixture starts is
waited for or killed, by its pid, before the fixture ends, so no `sleep`
outlives the guard.

Fixtures, each asserting the exit code and, where named, the stderr line
or the log line:

1. With limit 2, two wrapped `sleep 3` holders started in the background,
   and a third run with `--wait 1` exits 75 with a `suite-slots: busy`
   line naming two holders.
2. The same third run with `--wait 10` exits 0 after a holder ends, and
   at no sampled moment are more than two holder files present. The guard
   samples the directory every 0.2 seconds while the three run.
3. With limit 3 and two live holders, a run with `--wait 1` acquires.
   With limit 2 and the same holders, a run waits. This covers different
   N across batches.
4. A wrapped `sh -c 'exit 3'` exits 3, and its holder file is gone
   afterwards.
5. A holder file naming a dead pid with a mismatched start time is
   reclaimed: a run with limit 1 and `--wait 2` acquires, and the log
   shows `reclaimed`.
6. A holder file whose wrapper pid is dead but whose command pid is a
   live `sleep` is not reclaimed: limit 1 with `--wait 1` exits 75.
7. A mutex directory without an `owner` file and backdated beyond 10
   seconds (`touch -t`) is reclaimed.
8. A nested call (`KENSPC_SUITE_SLOT_HELD=1`) with limit 1 and one live
   holder runs at once, and the log shows `nested`.
9. A wrapped run killed with SIGTERM removes its holder file and forwards
   the signal: its child `sleep` is gone, checked with `ps -p` on that
   pid.
10. Usage errors exit 2: no `--`, no limit, limit `0`, limit `x`, and a
    regular file in the lock directory's place. The other-owner branch
    has no fixture, since the guard cannot chown; step 1's header names
    it as unchecked.

Self-test mutants, each written to its own file with `sed` and each
required to turn the guard red:

- the count check made always true;
- the stale-holder reclaim removed;
- the release on exit removed;
- the nesting check removed.

The unmutated copy must then pass. A mutant whose `sed` changes nothing
is exit 2, as the guard's existing mutants are.

**Input.** Step 1's script; the guard's existing layout (an EXIT-trap
cleanup as its only recursive `rm`; git configuration masked).

**Output.** The extended guard.

**Acceptance criteria.**

- `bash scripts/check-autopilot-scripts.sh` and
  `bash scripts/check-autopilot-scripts.sh --self-test` exit 0.
- `bash scripts/check-all.sh --self-test` prints the same `guards run:`
  and `self-tests run:` counts as before this plan, since no guard file is
  added.
- Each mutant's red run prints `OK    mutant '<name>': red (<n> assertions
  failed)`, the line the guard's existing mutants print; the failing
  assertions themselves go to stderr, which the self-test discards as it
  does today.
- The wall time of `bash scripts/check-autopilot-scripts.sh --self-test`
  (`time`), measured before and after this step, is recorded in the
  step's implementation notes (Risks, The guard's run time).

### Step 3: The driver passes the limit

**What.** In `run.sh`, read `AUTOPILOT_SUITE_LIMIT`,
`AUTOPILOT_SUITE_COMMANDS`, and `AUTOPILOT_SUITE_WRAPPER`. Export the four
`KENSPC_AUTOPILOT_SUITE_*` variables inside the launch subshell, beside
the marker, as § The driver specifies, on a fresh launch and on a resume.
Refuse a non-empty `AUTOPILOT_SUITE_WRAPPER` that is not an absolute
path, as `AUTOPILOT_WORKSPACE` is refused. Update the header's Environment
and Exported lists with the Why, and the header's paragraph on a caller's
own stub, which today names the two exported variables a passing stub
echoes: it names the six.

Extend `--self-test`:

- Both built-in stubs echo the four variables to stderr.
- One launch with the inputs set shows each value, the log variable as
  `<logs>/selftest-suite-slots.log`.
- One launch with the inputs unset, while the caller's environment holds
  stale `KENSPC_AUTOPILOT_SUITE_*` values, shows each variable empty.
- A launch with `AUTOPILOT_SUITE_WRAPPER` set to a relative path returns
  2, writes no `.session`, and names the variable, as the
  `AUTOPILOT_WORKSPACE` refusal does.

Mirror all of it in `run.ps1`.

**Input.** `run.sh` and `run.ps1` as they stand.

**Output.** Both drivers with the new inputs, exports, and self-test
items.

**Acceptance criteria.**

- `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`
  prints `self-test passed` and exits 0.
- `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  prints `self-test passed` and exits 0.
- With any one of the four new export lines deleted from a copy of
  either driver, run once per variable, its self-test exits 1 naming
  that variable.

### Step 4: The hook's suite check

**What.** Add check (f) to `hooks/scripts/autopilot-worker-rails.sh` as
§ The hook's new check specifies. Reuse the command-position scan that (a)
and (e) use, rather than adding a second scan; this keeps it within the
hook's 5-second timeout on the existing timed fixtures. Add the header
paragraph and the known misses.

Extend `scripts/check-autopilot-rails-hook.sh` with a `deny-suite`
expectation: exit 2, a reason opening `autopilot rails:` that names the
wrapper path, no `.trash`, and no no-route text. Run these fixtures with
`KENSPC_AUTOPILOT_SUITE_COMMANDS='dotnet test|pnpm test'` and a fixture
wrapper path:

- **Denied:** `dotnet test`, `dotnet test --filter X`, `cd a && dotnet test`,
  `sudo dotnet test`, `time pnpm test`, `echo x; pnpm test`,
  `$(dotnet test)`, `/usr/local/share/dotnet/dotnet test`.
- **Allowed:** `bash /w/suite-slots.sh run -- dotnet test`,
  `echo "dotnet test"`, `grep 'dotnet test' f`, `dotnet build`,
  `dotnet testx`, `pnpm install`, and a `dotnet test` inside a heredoc body.
- **Inert:** `dotnet test` with the commands variable empty, and the same
  with the marker unset.

Self-test mutant: the suite check removed, caught by the `dotnet test`
fixture.

**Input.** The hook and its guard as they stand.

**Output.** The hook with check (f), and the extended guard.

**Acceptance criteria.**

- `bash scripts/check-autopilot-rails-hook.sh` and
  `bash scripts/check-autopilot-rails-hook.sh --self-test` exit 0.
- The existing timed fixtures still finish in under 2.5 seconds each.

### Step 5: The autopilot SKILL.md text

**What.** Edit `plugins/kenspc/skills/autopilot/SKILL.md` as § The SKILL.md
text lists:

- the field table and the field's grammar paragraph;
- the settings stop;
- the settings line template;
- the copy paragraph, and Phase 0's Inputs and Constraints, which count
  "the three scripts" and "the three script copies";
- the workspace tree, for `_prompts/<batch>-suite-slots.sh` and
  `_logs/<batch>-suite-slots.log`;
- the launch bullet, for the three inputs;
- preamble § 3, for the lock directory;
- preamble § 6, for the `Suite limit:` line and when it is omitted;
- both S4 task blocks;
- the corrected-case paragraph;
- the long-wait question, and the main session's ruling on it (Open
  Questions 2);
- § The stop conditions, for the stop that ruling can end in;
- § The driver;
- the reviewer report template, for the `Suite slots:` line.

Each new rule carries its Why in the skill's own words.

**Input.** Steps 1, 3, and 4, so the text names their real interfaces.

**Output.** The edited SKILL.md.

**Acceptance criteria.**

- `bash scripts/check-all.sh` exits 0, with
  `check-autopilot-rails-hook.sh` among the passing guards, since it reads
  the preamble template.
- `grep -n 'Suite limit' plugins/kenspc/skills/autopilot/SKILL.md` shows
  the table row, the grammar paragraph, the start checks' settings-stop
  sentence, and preamble § 6's line; `grep -n 'suite limit <n>'` over the
  same file shows the settings line template, which is lower-case like
  the line's other fields.
- `grep -n 'kenspc-suite-slots' plugins/kenspc/skills/autopilot/SKILL.md`
  shows preamble § 3.

### Step 6: Live checks on this Mac

**What.** Run two checks that exercise the parts no fixture reaches.

1. **The hook in a real headless session.** Start one `claude -p` session
   in a throwaway directory under `$TMPDIR`, with
   `--permission-mode bypassPermissions`, so the permission system does
   not refuse the Bash call before it can run in the red case. Its
   environment holds `KENSPC_AUTOPILOT_WORKER=1`, write roots for that
   directory, `KENSPC_AUTOPILOT_SUITE_COMMANDS=kenspc-probe-suite`, and
   `KENSPC_AUTOPILOT_SUITE_WRAPPER` set to the absolute path of this
   worktree's `suite-slots.sh`. Load the plugin from this worktree with
   `--plugin-dir`, so the hook under test is the edited one. Prompt: run
   `kenspc-probe-suite --x` in Bash and quote the error. PASS: the quoted
   error opens `autopilot rails:` and names the wrapper. The command does
   not exist, so a hook that let it through prints `command not found`
   instead. That is the red case, seen when the same probe is run without
   `KENSPC_AUTOPILOT_SUITE_COMMANDS`.
2. **Three concurrent wrappers.** In three background shells, run
   `bash suite-slots.sh run --limit 2 --wait 30 -- sleep 5`, with
   `KENSPC_SUITE_SLOTS_DIR` under `$TMPDIR` and a log set. PASS: the log
   shows three `acquired` lines and the third waited at least 4 seconds.

Record both, with their commands, exit codes, and output, in
`docs/dry-runs/suite-slots-live.md`.

**Input.** Steps 1–5.

**Output.** The dry-run record.

**Acceptance criteria.**

- Both PASS as stated, the red case of check 1 included.
- The record holds each command and its exit code.
- The throwaway directory and the `$TMPDIR` lock directory are removed
  afterwards, and their absence is shown.

### Step 7: Doc-sync

**What.** Bring the documents under § Documentation impact in line with
steps 1–6.

**Input.** Steps 1–6.

**Output.** The updated documents.

**Acceptance criteria.**

- Each document listed with changes carries every change its entry names,
  stated as steps 1–6 built it (the field's grammar, the wrapper's
  interface and exit codes, the driver's inputs and exports, check (f) and
  its route); the documents marked N/A are unchanged.
- `docs/roadmap.md` no longer holds item 32.
- `bash scripts/check-all.sh --self-test` exits 0.

## Documentation impact

- `plugins/kenspc/README.md` — § Autopilot: the `## Autopilot` field
  table, the driver's environment and exports, and the rails hook
  paragraph (check (f) and its route); the workspace tree and The drivers
  paragraph, which name "the three scripts" copied per batch and the
  files under `_logs/`; the reviewer report's `Suite slots:` line; a
  sentence on the machine-wide lock and the `/tmp/kenspc-suite-slots`
  directory, naming native Windows as unchecked (Risks). Steps 1, 3, 4, 5.
- `CLAUDE.md`:
  - the Plugin Directory Layout tree and the File Structure `scripts/`
    bullet, where "three helper scripts" becomes four and
    "`check-no-model-names.sh` scans all five" becomes six (step 1);
  - the hooks paragraph, for check (f) and the new exported variables
    (steps 3, 4);
  - the Sessions-not-agents paragraph, for the lock across batches
    (step 5);
  - the Repository scripts/ entries for `check-autopilot-scripts.sh`
    (step 2) and `check-autopilot-rails-hook.sh` (step 4);
  - the maintenance note's list of files after whose edit
    `check-autopilot-scripts.sh` runs (step 1).
- `plugins/kenspc/CHANGELOG.md` — an entry under the release this ships
  in (Open Questions 1). Steps 1–5.
- `docs/roadmap.md` — item 32 leaves the file, since it ships. Step 7.
- `docs/release-checklist.md` — N/A for this document: no guard file is
  added, so `guards run: 13` and `self-tests run: 12` hold (step 2); row
  11's driver self-test sentences name only the pass line and the failing
  stub's `.exit` red case, which step 3 leaves true, since a stub that
  exits 3 fails the first launch's `.exit` check before any variable is
  read; row 14's live hook probes stay true with check (f) inert when
  `KENSPC_AUTOPILOT_SUITE_COMMANDS` is empty; and the smoke run leaves the
  field out by the Testing Strategy's choice.
- `README.md` — N/A for this document: its autopilot summary row names no
  driver variable or hook check, and no skill's summary changes.

## Testing Strategy

- **The wrapper.** Fixtures in `check-autopilot-scripts.sh`, under
  `/bin/bash` 3.2 and with the real process table (step 2), and four
  mutants that must each turn the guard red.
- **The hook.** Fixtures in `check-autopilot-rails-hook.sh`, with the live
  input format the guard already copies (step 4), and one mutant. One real
  headless session with a red counterpart (step 6.1).
- **The driver.** Its own `--self-test` in both languages (step 3), with
  a red check on a copy.
- **Concurrency on this machine.** Step 6.2.
- **Not tested:** a full autopilot batch with the field set. The cost of
  a headless batch, USD 10–20 at the release checklist's row 11 figures,
  buys little over steps 2, 4, and 6, which run each part against the real
  process table and a real session. The first real batch with the field is
  its acceptance, and its reviewer report's `Suite slots:` line is the
  evidence.

## Risks and Mitigations

- **A wait that never ends.** A holder that never exits — a hung suite —
  keeps its slot, and ruling 5 allows no bypass. Mitigation: the busy line
  names each holder's age, cwd, and command. After 30 minutes of busy
  returns, the worker asks the main session, which rules to wait on or to
  stop (§ The SKILL.md text, A long wait). The reviewer report's
  `Suite slots:` line shows the longest wait.
- **A command the hook cannot see.** A listed command reached through a
  script, `make`, `bash -c`, or another miss § The hook's new check lists
  runs unwrapped. Mitigation: the preamble
  text binds the worker; S4's case files are wrapped by rule; the spec
  author lists the outer command a batch actually types (`pnpm test`, a
  `scripts/test.sh`). The miss is in the hook's header.
- **Batches on different plugin versions.** Two batches running different
  wrapper versions share one lock directory. A later change to the holder
  file layout could make one version misread the other's holders.
  Mitigation: the layout is fixed by this plan, and a change to it is a
  breaking change, named as one in the CHANGELOG entry that makes it.
- **`/tmp` on native Windows.** Under Git Bash, `/tmp` maps to the user's
  temp folder, shared by that user's sessions, but this is not measured.
  Mitigation: out of scope as stated. Native Windows is named as unchecked
  in the README sentence.
- **PID reuse.** The holder file's recorded start time is compared, so a
  reused pid is not read as a live holder.
- **A Bash tool timeout while the command runs.** If the tool kills the
  wrapper with SIGTERM, the trap forwards the signal and releases the
  slot. If it kills with SIGKILL, the command pid kept in the holder file
  holds the slot until the command ends, which is the behavior the ports
  need.
- **Grandchildren outlive the forwarded signal.** The wrapper signals its
  child's pid only. A child that does not pass SIGTERM on — `sh <file>`
  waiting on a foreground `dotnet test`, or `dotnet test` and its test
  host — can leave the suite's processes running, and the holder is then
  stale (both its pids gone) while the ports are still in use. Mitigation
  as planned: none; the window lasts until those processes end. Noted in
  review: running the child in a process group of its own and signalling
  the group would close it, at the cost of bash's job control in a
  non-interactive script.
- **Two waiters reclaiming one stale mutex.** When a mutex holder dies
  between its `mkdir` and its release, two waiters that both see its dead
  pid can each remove the mutex and take it, one removing the other's
  fresh mutex, and both then count and write holders, so N + 1 holders
  can run. The window needs a holder killed inside a critical section of a
  few milliseconds and two waiters polling in the same instant. Mitigation
  as planned: none. Noted in review: the plan does not say how a reclaim
  avoids this, and step 2's fixture 7 does not exercise two reclaimers.
- **The guard's run time.** `check-autopilot-scripts.sh --self-test` runs
  every fixture once per mutant plus a positive and a restoration pass —
  thirteen passes once step 2 adds four mutants to the seven — so the
  wrapper fixtures' sleeps and waits (fixtures 1, 2, 3, 6, and 9) are paid
  thirteen times. Mitigation: keep each pass's wrapper fixtures within a
  few seconds of sleep, or run only the wrapper's fixtures for the four
  wrapper mutants; step 2 records the self-test's duration before and
  after.

## Open Questions

1. The release this ships in: 4.10.0, after 4.9.0 is tagged, or folded
   into the unreleased 4.9.0. This draft assumes 4.10.0. The 4.9.0 plan
   names the work as planned separately, and 4.9.0's CHANGELOG
   introduction says "No … guard, or `## Autopilot` field", which folding
   this in would make false.
2. The main session's ruling on the long-wait question (§ The SKILL.md
   text, A long wait) has no rule yet. The plan says it rules "wait on,
   or stop the run naming the holders", but not what tells the two apart
   (a holder's age, whether its pids are a batch's live worker, the
   holder's cwd), what follows "wait on" (the next question after a
   further 30 minutes, or none), or where the stop is listed in § The
   stop conditions — a numbered condition 12, or an eighth stop stated at
   its own step. Step 5 writes the ruling and the stop as this answer
   settles them. Found in review; the order in § How the main session
   rules may settle the first part, the rest is a design choice.
