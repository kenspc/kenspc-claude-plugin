# Batch F — The PowerShell Driver run.ps1 — Task Document

## Context

The autopilot skill ships a bash driver, `skills/autopilot/scripts/run.sh`,
that starts one headless `claude -p` worker in the background, returns at
once, and records the worker's session id, pid, output, stderr, and exit
status in files under a logs directory, with a `start` and an `end` line in
the batch's timeline. This document adds its PowerShell mirror, `run.ps1`,
beside it: the same interface, files, lines, and refusals, started through
`Start-Process pwsh`, checked on macOS with `pwsh` (a parse and the
self-test). Windows acceptance is a roadmap line, written in the release
commit. The skill keeps copying and running `run.sh`; nothing picks a
driver by platform until that acceptance.

Related plan: `docs/plans/batch-f-autopilot.md` (read at `52f0bbe`). The
plan is the complete specification; its locked design (F-1 to F-14), its
Design decisions (M1–M16, D1–D24), and its Clarifications (CL1–CL19) are
binding rulings. This document covers plan Phase 3 only — Step 3.1 and its
Doc-sync task — the second round that M10 describes: round 1 dropped
Phase 3 at generate-task's confirm gate, the bash driver then passed
acceptance, and this round keeps only Step 3.1. The rulings this round
applies:

- D8: the same positional interface and files; the prompt read with
  `Get-Content -Raw` from the file, never passed on a command line the
  caller quotes; the worker started with `Start-Process pwsh … -PassThru`,
  whose inner command runs `claude` with the same arguments, redirects
  stdout and stderr to the two files, and writes `<tag>.exit` and the
  timeline's `end` line when it returns; `<tag>.pid` is the started
  process's id; the same environment variables; `--self-test` with a stub
  `claude.ps1` on a temporary PATH entry.
- D7: the bash driver's interface, environment variables, files, and
  self-test, which `run.ps1` mirrors.
- CL16: `-WindowStyle Hidden` only when `$IsWindows` (pwsh 7.6.6 on macOS
  refuses the parameter); on macOS and Linux the child is attached to the
  launching shell, with no hang-up protection, and the header says
  `run.ps1` is checked on macOS only; the inner command travels
  base64-encoded with `-EncodedCommand`; the self-test adds a launch whose
  cwd and logs path hold a space and a single quote.
- CL17: `run.ps1` mirrors `run.sh`'s launch behavior in full — the same
  refusals (exit 2, nothing written), the stale `.exit` removal, the
  `started` line, the batch-name default, `caffeinate -i` when present, the
  prompt read inside the inner command, empty stdin — and a self-test that
  checks the same items, adapted. The skill, its command, and `run.sh` stay
  zero diff in this round, and the plugin README says so.
- CL18: the release checklist's row 11 gains one clause,
  `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  printing `self-test passed` and exiting 0; the Doc-sync task edits
  CLAUDE.md (the layout tree and the File Structure `scripts/` bullet),
  the plugin README's Autopilot section, the CHANGELOG's `run.ps1` entry,
  and the checklist's row 11.
- CL19: `Start-Process` redirects the launched pwsh's own three streams,
  as `run.sh`'s subshell does with `> /dev/null 2>&1 < /dev/null`, to
  three files in the logs directory — `<tag>.launch.in` (an empty file the
  driver writes), `<tag>.launch.out`, and `<tag>.launch.err`; the header
  names them; the self-test checks that they exist, that the two output
  files are empty after a clean launch, and that a launch read through a
  command substitution returns before a slow stub's `.exit` exists. The
  plan's Documentation impact element reads with CL5, CL6, and CL18.
- CL5: in round 1 CLAUDE.md's layout tree listed `scripts/run.sh` only;
  `run.ps1` joins it in this round, through the Doc-sync task.
- CL2: the pointer-label grep's `dry-run` alternative is `dry-run\b`.

The labels this document cites (F-n, M-n, D-n rows, CL-n, "ruling") are
pointers into the plan for the implementer. None of them is copied into a
plugin file (plan § Standing constraints; the pointer-label grep below).

Each task cites its plan Step and clarifications, which are the canonical
source for what to write. The criteria listed here are the local DONE bar.

Fixed forms. Every task that states one of these uses it exactly as written
here (plan § Fixed strings). Each is written on one line of the file that
carries it, unwrapped, so `grep -F` finds it:

- Driver interface line (the PowerShell form):
  `run.ps1 <tag> <cwd> <prompt-file> [--resume <session-id>]`
- Driver files: `<tag>.json`, `<tag>.err`, `<tag>.pid`, `<tag>.exit`,
  `<tag>.session`; `<batch>-timeline.log` lines `start <tag> pid <pid> …` /
  `end   <tag> exit <status>` (three spaces after `end`, both at column 0);
  `<batch>-costs.txt` lines `<tag> <session_id> <total_cost_usd>` (written
  by the skill, not by a driver).
- Launch stream files (`run.ps1` only, CL19): `<tag>.launch.in`,
  `<tag>.launch.out`, `<tag>.launch.err`.
- Launch stdout line: `started <tag> pid <pid> session <id>`.
- Driver self-test: `run.ps1 --self-test`, exit 0 and the line
  `self-test passed`.
- Wait snippet, driver form (the bash form, which the skill and the
  checklist carry; `run.ps1`'s own wait is its PowerShell equivalent — poll
  `<tag>.exit` every 2 s, at most 30 times):
  `n=0; until [ -f "$LOGS/$TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done`
- Worker settings flag: `--settings '{"crossSessionInbound":"accept"}'`
  (the value `{"crossSessionInbound":"accept"}`, passed as one argument).
- Checklist clause (CL18):
  `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
- CHANGELOG heading: `## 3.9.0 — unreleased`
- Dependency line: `Depends on: Task N`.
- Unchanged: `guards run: 10`, `self-tests run: 9`.

Pointer-label grep (plan § Standing constraints, with CL2). For the plugin
file this document creates, `plugins/kenspc/skills/autopilot/scripts/run.ps1`,
this command prints nothing:

```bash
grep -nE 'batch [A-Z]\b|dry-run\b|\bruling\b|\b[BCDEF]-[0-9]+\b|\bCL[0-9]+\b|\([MDC][0-9]+\b|\b[MD][0-9]+\b' plugins/kenspc/skills/autopilot/scripts/run.ps1
```

It prints nothing on `run.sh` and many lines on the plan, so it can fail.
`grep -nwE 'MUST|NEVER|CRITICAL' <file>` also prints nothing on it.

Parse check (plan Step 3.1). Run from the repository root; it prints
`parse errors: 0` and exits 0, or prints each error and exits 1:

```bash
pwsh -NoProfile -Command '$errs = $null; $null = [System.Management.Automation.Language.Parser]::ParseFile((Resolve-Path "plugins/kenspc/skills/autopilot/scripts/run.ps1").Path, [ref]$null, [ref]$errs); if ($errs.Count) { $errs | ForEach-Object { $_.ToString() }; exit 1 }; "parse errors: 0"'
```

Its control: run from a directory under `$TMPDIR` that holds a copy of the
file at the same relative path with one unbalanced `{` appended, the same
command prints the parser's error and exits 1.

This is plugin revision work. The files are one PowerShell script and four
Markdown documents. The repository has no test framework: "build / test /
lint" for each task is the guard suite plus the driver's own checks. After
each task, run `bash scripts/check-all.sh`, which exits 0 with
`guards run: 10` — capture its exit status on its own line, never through
a pipe (`bash scripts/check-all.sh > <file> 2>&1; rc=$?`), since a pipe
reports the last command's status, not the guard's. Both tasks also run
`claude plugin validate --strict ./plugins/kenspc`. Task 2 also runs
`bash scripts/check-all.sh --self-test`, which prints `guards run: 10` and
ends with `self-tests run: 9`.

Constraints that apply to every task (plan § Standing constraints, with
CL16–CL19):

- Zero diff outside this round's files. After every task, this prints
  nothing:
  `git diff --stat c08b9ec HEAD -- plugins/kenspc/agents plugins/kenspc/shared plugins/kenspc/references plugins/kenspc/hooks plugins/kenspc/commands plugins/kenspc/.claude-plugin plugins/kenspc/skills/generate-brief plugins/kenspc/skills/generate-plan plugins/kenspc/skills/generate-task plugins/kenspc/skills/generate-guide plugins/kenspc/skills/diagnose-bug plugins/kenspc/skills/prototype plugins/kenspc/skills/task-implement plugins/kenspc/skills/task-review plugins/kenspc/skills/autopilot/SKILL.md plugins/kenspc/skills/autopilot/scripts/run.sh .claude-plugin README.md scripts docs/roadmap.md docs/dry-runs/README.md docs/briefs`.
  The files this round touches are `plugins/kenspc/skills/autopilot/scripts/run.ps1`
  (new; Task 1), `CLAUDE.md`, `plugins/kenspc/README.md`,
  `plugins/kenspc/CHANGELOG.md`, and `docs/release-checklist.md` (Task 2),
  plus this task document's status updates. The batch's own zero-diff
  command (plan § Standing constraints, against `5c33c4a`) still prints
  nothing too.
- No edit inside any byte-identity section and no edit to any file that
  holds one (the canonical blocks, the code-craft canonical paragraphs, the
  five reviewers' six shared sections); every such file is on the list
  above.
- No new agent, no new CONTEXT key, no agent teams, no way of starting a
  worker other than `claude -p`, no guard script added or edited
  (`scripts/` is zero diff, so `guards run: 10` and `self-tests run: 9`
  stay). No version bump (`plugin.json` stays `3.8.2`), no date on the
  CHANGELOG heading, no roadmap edit, no tag, no push.
- Rules and comments are rationale-anchored ("Why: …"), with no `MUST` /
  `NEVER` / `CRITICAL`, no effort or reasoning tokens, and no model names
  (`bash scripts/check-no-model-names.sh` exits 0; it scans
  `skills/autopilot/scripts/`, so `run.ps1` passes no `--model`, names no
  model family, and holds no `claude-` followed by a letter or digit).
- Plugin files state their evidence in their own words and carry no pointer
  labels, batch names, or dry-run references (the pointer-label grep).
- Code, comments, commit messages, and documents are in English.
- No task runs `rm -r` or `rm -rf`, and `run.ps1` deletes nothing
  recursively. The self-test's directories and every other temporary file
  under `$TMPDIR` are left there. Anything else to be discarded is moved to
  `~/Projects/_smoke/.trash/<name>-<YYYYMMDD-HHMMSS>/` (created when
  missing). Nothing under `.kenspc/` is deleted.
- Plugin Design Lessons apply: every transition rests on an artifact —
  `<tag>.exit` above all, which both drivers write when the worker returns
  — never on a notice's or a message's wording.
- No task edits `docs/plans/batch-f-autopilot.md`. A task that finds a
  ruling contradicted by the code or the platform is marked BLOCKED with
  the contradiction named. After the run ends and Schema G is out, the
  orchestrating session (the one that ran `/kenspc-task-implement`) sends
  each such contradiction to the main session as its prompt says — a
  message whose first line is `question <tag>: <one line>`, with its
  suggested answer, then waits as the prompt says — and, when no answer
  arrives within the wait, appends it under a
  `## Questions for the spec author` section at the end of the plan
  (creating the section when missing) — one numbered entry per question,
  naming the Step it affects, what the repository or the platform shows,
  and what the plan says — commits nothing else, puts the question in its
  last reply, and stops; the spec author records the answer as `CL<n>`
  under the plan's `## Clarifications during implementation`.
- Each task is one conventional commit that stages only the files the task
  lists, together with the task's status update: `feat(skills): …` for
  Task 1, `docs: …` for Task 2.

Dependency note: this document assumes the first task document of the
batch, `docs/tasks/batch-f-autopilot-tasks.md` (plan Phases 1–2, Tasks 1–9,
all DONE), is implemented: `run.sh`, the autopilot skill, the
`/kenspc-autopilot` command, and their documentation exist, and the bash
driver has passed acceptance. Its task numbers are not this document's:
`Depends on` below names tasks in this document only. Task 1 carries no
`Depends on`. Task 2, the Doc-sync task, documents the driver Task 1 builds
(`Depends on: Task 1`).

## Tasks

### Task 1: Write the PowerShell driver run.ps1

**Status:** DONE

**Implementation notes:**
- Decisions:
  - Refusals are thrown (`Stop-Driver`), and the command line turns any
    thrown error into exit 2. As in `run.sh`, where `die` runs in a subshell
    of `launch`, the self-test runs the launch refusals in-process: missing
    executable, empty and whitespace-only prompt, second launch under the
    running tag. It reads the message and checks that no `.session` was
    written. The resume launch, the two parser refusals, and the
    command-substitution launch go through
    `pwsh -NoProfile -File <this script>`. Why: the second-launch refusal
    has to land inside the stub's one-second sleep, and starting a pwsh
    for each check would crowd that window.
  - `.err` is not bare lines. A `.ps1` stub's `Write-Error` arrives as
    PowerShell's error view: a `claude.ps1:` header, the calling line, and
    the message after a `     | ` gutter. So the self-test reads the flags
    as substrings, and reads `cwd=<path>` as a line that ends with it after
    the line start or whitespace. The error view wraps the message at 80
    columns when the caller is a script file, which would split flag pairs
    (probed with `-File`). Under `-EncodedCommand` the invocation has no
    script name and the message stays on one line; the self-test relies on
    that. The worker's flags sit on the inner script's `$argv` line and not
    on the calling line, because the error view quotes the calling line
    into `.err`: a flag there would satisfy the checks, or break the
    resume's no-`--session-id` check.
  - For `caffeinate`, the task's second option. The inner pwsh starts
    `caffeinate -i -w $PID` with `Start-Process` before it runs the worker,
    so the executable resolves as it would without `caffeinate`, and
    `caffeinate` inherits the inner pwsh's streams (the `.launch.*` files),
    not the caller's.
  - Literals are made with
    `CodeGeneration.EscapeSingleQuotedStringContent`. It doubles `'` and
    also the typographic single quotes that PowerShell treats as quote
    delimiters (U+2018 to U+201B). A cwd and a logs directory holding `’`
    were checked by hand (`.exit` 0, `cwd=` shown). The self-test covers
    the ASCII quote only, as specified.
  - Placeholders go into the inner template in a single regex pass
    (`-replace` with a scriptblock), so a value that holds a placeholder
    name is never substituted a second time.
  - In the default-stub path, after the stub dir is put first on `PATH`,
    the self-test checks that `Get-Command claude` resolves to the stub,
    and fails when it does not. A `claude` that resolved elsewhere would
    start a real, paid session. The task does not list this check.
  - Relative cwd and prompt paths are resolved against PowerShell's
    location (`GetUnresolvedProviderPathFromPSPath`) before they are
    embedded, because the inner script's `Set-Location` changes the base.
    The start line keeps them as given, as `run.sh`'s does. The timestamp
    is formatted with the invariant culture, because some cultures'
    time separator is not `:`.
  - The `started` line is written with an explicit LF. On Windows,
    `WriteLine` would end it with CRLF, and a bash caller would read a
    carriage return on the session id.
- Changes/tradeoffs:
  - Finding for the spec author, not treated as BLOCKED because nothing
    the task decides is contradicted. On macOS (pwsh 7.6.6),
    `Start-Process -RedirectStandard*` copies the launched pwsh's
    streams through the launching pwsh process. Once `run.ps1` returns,
    anything the inner pwsh writes to its stdout or stderr is dropped.
    Probed three ways:
    - An invalid stub gave `.exit` 1, no `.json`, and an empty
      `.launch.err`.
    - The same encoded inner script run under shell redirection recorded
      the error.
    - A child that wrote after its launcher returned kept running and
      finished its own file write, but its lines were lost.

    So on macOS the task's claim that the two output files "hold the
    inner pwsh's own error when its script fails" holds only for what
    arrives before `run.ps1` returns. The three-file redirection still
    frees the caller's pipe (probed: a 20 s stub, and the capture returned
    at once), and all of the self-test's launch-file checks pass. The
    header says this. Whether Windows keeps the error is left to the
    Windows acceptance: there `Start-Process` is expected to hand the
    files to the child itself, which was not checked here.
  - On this machine `pwsh` is a dotnet global-tool shim, so `.pid` holds
    the shim's id and the inner pwsh's `$PID` differs (probed 86066 vs
    86077). The shim lives as long as the inner pwsh, so the live-worker
    refusal and the self-test's liveness check hold. `caffeinate` watches
    the inner pwsh's own `$PID`.
  - `Start-Process` refuses a missing input file, so `<tag>.launch.in` is
    written before the process starts, and `Start-Process` truncates stale
    `.launch.out` and `.launch.err` files. Under `-EncodedCommand`, pwsh
    writes an uncaught error to stderr as CLIXML (observed), so the inner
    script catches its own errors and writes them as plain text.
    `$LASTEXITCODE` is reset to 0 before the call, so a `.ps1` executable
    that returns without `exit` reads 0. A failure inside the inner
    `try` (location, prompt read, executable) leaves `.exit` at 1.
  - Verification: the parse check and its control (exit 1); both
    self-test forms (repository root, and `$TMPDIR` with the absolute
    path); the failing `.ps1` caller stub (rc 1, names `.exit`); the
    20-second pipe check; every command-line refusal (exit 2, nothing
    written); and three mutants under `$TMPDIR`, each failing the
    self-test at its intended check:
    - no stream redirection: fails at the `.launch.out` check;
    - the same mutant with the launch-file check disabled: fails at the
      command-substitution check;
    - no quote doubling: fails at the quoted-path launch.

    The mutant without redirection also made the 20-second pipe check
    wait out the stub, with `.exit` present on return.

Plan Step 3.1 (F-13, F-5, F-7; rulings D8, D7; CL16, CL17, CL19, CL2). Create
`plugins/kenspc/skills/autopilot/scripts/run.ps1` for PowerShell 7
(`pwsh`), mirroring `run.sh` in the same directory. Read `run.sh` first,
header and self-test included: it is the model, and each of its refusals
and self-test items closes a failure an earlier review found. Where this
task and `run.sh` agree, `run.sh`'s behavior is the specification; where
PowerShell needs a different mechanism, this task names it.

- Form: the file opens with `#Requires -Version 7.0` and a header comment,
  and reads its arguments from `$args` (bash-style tokens: `--self-test`,
  `--resume`), parsed as `run.sh` parses its own. Why `#Requires`: under
  Windows PowerShell 5.1 `$IsWindows` is `$null`, so the hidden-window
  branch would silently not apply and `Start-Process pwsh` would name a
  shell that may not exist. Why `$args`: `pwsh -File` passes `--self-test`
  and `--resume` through as plain strings (verified with pwsh 7.6.6: with a
  `param()` block they land in `$args` too, unbound).
- Interface: `run.ps1 <tag> <cwd> <prompt-file> [--resume <session-id>]`
  and `run.ps1 --self-test`, invoked as `pwsh -NoProfile -File <path>/run.ps1 …`.
  The six environment variables, with `run.sh`'s meanings and defaults:
  `AUTOPILOT_LOGS` (default `$HOME/Projects/_smoke/_logs`),
  `AUTOPILOT_PLUGIN_DIR` (`--plugin-dir <value>`), `AUTOPILOT_BUDGET_USD`
  (`--max-budget-usd <value>`), `APPEND_SP`
  (`--append-system-prompt <value>`), `AUTOPILOT_CLAUDE` (the executable;
  default `claude`), `AUTOPILOT_BATCH` (default the tag's prefix before its
  last `-s`). Exit status of a launch: 0 once the worker has been started;
  2 on a usage or environment error or a refusal; self-test 0 on pass, 1 on
  the first missing or wrong item.
- Launch, in `run.sh`'s order. Refusals, each exit 2 with a message naming
  its subject and nothing written (no `<tag>.session`): on the command
  line, fewer than three positional arguments (usage), `--resume` without
  an id, and an unknown argument; then, in the launch, an empty tag; a cwd
  that is not a directory; a missing prompt file; an empty or
  whitespace-only prompt file; an executable that `Get-Command` does not
  find; and, after the logs directory is created, a live worker under the
  tag (`<tag>.pid` names a live process and `<tag>.exit` is absent — the
  message names the pid and says what to remove when that process is not
  the worker). Then: the session id — `[guid]::NewGuid()` as a lowercase
  string for a fresh launch, the given id for a resume — written to
  `<tag>.session` before the process starts; `<tag>.launch.in` written
  empty; a stale `<tag>.exit` removed (that one file, no recursion); the
  worker started; `<tag>.pid` written; the timeline's start line appended,
  `start <tag> pid <pid> session <id> at <YYYY-MM-DD HH:MM:SS> cwd <dir> prompt <file><extra>`
  with `run.sh`'s `<extra>` words (` plugin-dir <dir>`,
  ` budget USD <n>`, ` [append-system-prompt]`, ` resume`); and
  `started <tag> pid <pid> session <id>` printed to stdout.
- The worker (D8, CL16, CL19): `Start-Process pwsh` with
  `-ArgumentList @('-NoProfile', '-EncodedCommand', <inner>)` and
  `-PassThru`, adding `-WindowStyle Hidden` only when `$IsWindows`;
  `<tag>.pid` holds the started process's id. No process the launch starts
  (a `caffeinate` included) holds the caller's standard streams, as
  `run.sh`'s subshell runs with its own on `/dev/null`: `Start-Process` is
  given `-RedirectStandardInput <logs>/<tag>.launch.in`,
  `-RedirectStandardOutput <logs>/<tag>.launch.out`, and
  `-RedirectStandardError <logs>/<tag>.launch.err`. These three files take
  the launched pwsh's own streams only — the worker's output still goes to
  `<tag>.json` and `<tag>.err` through the inner script's redirection — so
  the two output files are empty on a clean launch and hold the inner
  pwsh's own error when its script fails. Why: without the redirection the
  child inherits the caller's stdout and stderr, so a caller that reads the
  launch's output through a pipe — a command substitution, the Bash tool —
  waits until the worker exits instead of getting the `started` line at
  once (verified with pwsh 7.6.6 on macOS: a pipe-reading caller waited
  out a six-second child without the three parameters and returned at
  once with them). Why three files and not the null device:
  `Start-Process` refuses one path for stdout and stderr, and files in the
  logs directory need no null-device branch per platform. `<inner>` is the inner script, UTF-16LE,
  base64-encoded, and every value it carries (the
  executable, the paths, the tag, the flag values) is embedded as a
  single-quoted PowerShell literal with each `'` doubled. The inner script
  sets its location to the cwd; reads the prompt with
  `Get-Content -Raw -LiteralPath <prompt-file>`, trailing line breaks
  removed as bash's `$(cat …)` removes them; runs the executable with `-p`
  and the prompt, then `--session-id <id>` for a fresh launch or
  `--resume <id>` for a resume, then `--name <tag>`, `--settings` with the
  value `{"crossSessionInbound":"accept"}`,
  `--permission-mode bypassPermissions`, `--output-format json`, and the
  optional flags whose variables are set; gives it an empty stdin
  (`$null | & …`); redirects its stdout to `<tag>.json` and its stderr to
  `<tag>.err`; and, when it returns, writes its exit status to `<tag>.exit`
  and appends `end   <tag> exit <status>` to the timeline. No `--model`, no
  `--continue`. Why `-EncodedCommand`: `Start-Process` joins
  `-ArgumentList` into one command line and does not quote values that hold
  spaces, and Windows paths with spaces are common; the encoded form
  carries any path unchanged (verified with pwsh 7.6.6: a path holding a
  space and a single quote survives, and the inner exit status comes
  through). Why `-WindowStyle` only on Windows: pwsh 7.6.6 on macOS refuses
  the parameter ("not supported … on this edition of PowerShell"). Why no
  hang-up protection: on macOS and Linux a `Start-Process` child is
  attached to the launching shell and is terminated when that shell is
  closed (the `Start-Process` documentation); `run.ps1` is written for
  Windows, where the child is independent, and `run.sh` stays the driver on
  macOS and Linux — the header says `run.ps1` is checked on macOS only.
- `caffeinate -i` when `Get-Command caffeinate` finds it, as `run.sh`
  wraps its worker, so that the machine stays awake while the worker runs,
  arranged so that the executable resolves exactly as it would without
  `caffeinate` — for example by passing `caffeinate` the resolved path of
  an application only, or by running `caffeinate -i -w <pid of the inner
  pwsh>` beside the worker. Why: `caffeinate` runs its utility through its
  own PATH search, which skips a `claude.ps1` stub and finds the installed
  `claude`, so a self-test that routed its stub through `caffeinate` would
  start a real, paid session; and it cannot run a `.ps1` at all.
- Every file the driver itself writes — `<tag>.session`, `<tag>.pid`,
  `<tag>.exit`, the empty `<tag>.launch.in`, and the timeline lines — ends
  its lines with LF only and
  carries no byte-order mark, on every platform: written through
  `[System.IO.File]` methods with an explicit `` `n `` and a UTF-8
  encoding without BOM, not `Set-Content`, `Add-Content`, or `Out-File`,
  which the file uses nowhere (its stubs included), so one grep checks it.
  Why: the skill reads `.exit` and `.session` with `cat` and the release
  checklist greps the timeline with `$`-anchored patterns; PowerShell's
  own writers end lines with CRLF on Windows, which would make `.exit`
  read `0` plus a carriage return.
- `--self-test` (CL16, CL17): a fresh directory under
  `[System.IO.Path]::GetTempPath()` (the self-test's logs directory is
  always under it, whatever `AUTOPILOT_LOGS` says, so a self-test writes
  nothing under the workspace), left in place afterwards. The stub is
  `claude.ps1` in a `stub` directory there, put first on `PATH` and reached
  through the default executable name `claude`, unless the caller has set
  `AUTOPILOT_CLAUDE`, in which case that value is the stub for the passing
  launches. The stub writes its arguments and `cwd=<its working
  directory>` with `Write-Error` — a `.ps1` stub runs inside the inner
  pwsh, where `Write-Error` reaches the `2>` redirection and
  `[Console]::Error.WriteLine` bypasses it (verified) — prints
  `{"type":"result","subtype":"success","is_error":false,"result":"stub ok","session_id":"<its --session-id or --resume value>","total_cost_usd":0.01,"num_turns":1}`
  to stdout, sleeps one second, and exits 0. A second stub exits 3 at once.
  The self-test first prints `self-test: logs directory <path>` and
  `self-test: executable <path>`, as `run.sh` does, then launches through
  the same launch path and checks, in
  `run.sh`'s order, naming the first item that fails: a missing
  executable, an empty prompt file, and a whitespace-only prompt file each
  refused (exit 2, the subject named, no `.session`); the logs directory
  created by the launch; the stdout line matching `.pid` and `.session`; a
  second launch under the running tag refused (exit 2, the pid named,
  `.session` and `.pid` unchanged); `.pid` naming a live process other than
  the self-test's own; after the wait, `.session` and `.pid` non-empty,
  `.json` parseable (`ConvertFrom-Json`) with `result`, `.err` present,
  `.exit` reading `0`, and the timeline's start and end lines;
  `.launch.in`, `.launch.out`, and `.launch.err` present, with
  `.launch.out` and `.launch.err` empty (CL19); `.err`
  showing `--session-id <id>`, `--name <tag>`,
  `--settings {"crossSessionInbound":"accept"}`,
  `--permission-mode bypassPermissions`, `--output-format json`, and
  `cwd=<the launch's cwd>` (both sides resolved the same way: on macOS
  `$TMPDIR` lies under a symlink, so a physical path and a logical one
  differ), and none of `--plugin-dir`, `--max-budget-usd`,
  `--append-system-prompt` with their variables unset; `.json`'s
  `session_id` equal to `.session`; the failing stub under `selftest-s2`
  with `.exit` reading `3` and an end line with `exit 3`; a resume launch
  of `<tag>-r1` through the command line
  (`pwsh -NoProfile -File <this script> <tag>-r1 <cwd> <prompt> --resume <id>`)
  with `AUTOPILOT_PLUGIN_DIR`, `AUTOPILOT_BUDGET_USD`, and `APPEND_SP` set —
  exit 0, `.exit` `0`, `.session` holding the id, `.err` showing
  `--resume <id>` and the three flags and no `--session-id`, a start line
  ending in `resume`; the command line refusing `--resume` with no id and
  an unknown argument (exit 2, no `<tag>-r1-x.session`); with
  `AUTOPILOT_BATCH` unset and a stale `self-s-test-s1.exit` in place, a
  launch of `self-s-test-s1` that removes the stale file at once, reads
  `0` after the wait, and writes both lines to `self-s-test-timeline.log`;
  and (CL16) a launch whose cwd and logs directory both hold a space and a
  single quote, with `.exit` reading `0`, `.json` holding `result`, `.err`
  showing `cwd=<that cwd>`, and both timeline lines in that logs
  directory; and (CL19) a launch through the command line under a tag of
  its own, its output captured as a command substitution captures it
  (`$out = pwsh -NoProfile -File <this script> …`), with a third stub that
  sleeps five seconds and exits 0: the capture returns with the `started`
  line while that tag's `.exit` does not yet exist, and `.exit` reads `0`
  after the wait. On success it prints `self-test passed` and exits 0.
- Header comment, in `run.sh`'s shape: the interface line and the
  `pwsh -NoProfile -File` invocation; PowerShell 7; the six variables; the
  five files, the three `<tag>.launch.*` files, the two timeline lines,
  and `<batch>-costs.txt` as the skill's; the always-passed flags; the Whys (the session id before the
  start, `-EncodedCommand`, the Windows-only hidden window, the redirected
  standard streams, `caffeinate`, LF-only files, the self-test and its
  stub); that `run.ps1` is checked on
  macOS only — a parse and the self-test — with no hang-up protection
  there, since `run.sh` is the driver on macOS and Linux; the exit codes.

**Files to create:**
- `plugins/kenspc/skills/autopilot/scripts/run.ps1`

**Acceptance criteria:**
- `grep -c '^#Requires -Version 7.0$' plugins/kenspc/skills/autopilot/scripts/run.ps1`
  prints 1.
- The parse check (Context) prints `parse errors: 0` and exits 0, and its
  control exits 1.
- From the repository root, the form the release checklist carries,
  `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test > "$TMPDIR/ps1-selftest.out" 2>&1; rc=$?`,
  and from `$TMPDIR` the same command with the script's absolute path,
  each give `rc` 0, and the output holds the line `self-test passed`.
- With `AUTOPILOT_CLAUDE` pointed at a `.ps1` under `$TMPDIR` that prints
  the built-in stub's JSON, sleeps one second, and exits 3, the same
  command gives `rc` 1 and the output names `.exit`.
- After a passing self-test, the logs directory it names is under
  `$TMPDIR` and holds `selftest-s1.session`, `.pid`, `.json`, `.err`, and
  `.exit` reading `0`, and `selftest-timeline.log` with one line matching
  `^start selftest-s1 pid [0-9]+` and one matching
  `^end   selftest-s1 exit 0$`; `selftest-s1.err` shows `--name selftest-s1`
  as the stub echoed it and `selftest-s1.json` holds `"result":"stub ok"`,
  which shows the stub ran and not the installed `claude`;
  `selftest-s1.launch.in`, `selftest-s1.launch.out`, and
  `selftest-s1.launch.err` exist, and `test -s` is false for each of the
  three; no file the driver wrote there contains a carriage return
  (`grep -c $'\r'` prints 0 on the `.session`, `.pid`, and `.exit` files
  and the timeline).
- A launch read through a pipe returns while its worker runs. With
  `AUTOPILOT_LOGS` set to a fresh directory under `$TMPDIR`,
  `AUTOPILOT_CLAUDE` pointed at a `.ps1` under `$TMPDIR` that sleeps 20
  seconds and exits 0, and a one-line prompt file under `$TMPDIR`,
  `out=$(pwsh -NoProfile -File <absolute path>/run.ps1 pipe-s1 "$TMPDIR" <prompt file>); rc=$?`
  gives `rc` 0 and `out` starting `started pipe-s1 pid`; right after it
  returns, `pipe-s1.exit` is absent from that logs directory, and within
  60 seconds it reads `0`. A launch whose processes hold the caller's
  stdout returns only after the stub exits, with `.exit` already written,
  so this check can fail.
- `grep -cF -- '<string>' plugins/kenspc/skills/autopilot/scripts/run.ps1`
  prints at least 1 for each of `Start-Process`, `-EncodedCommand`,
  `-WindowStyle Hidden`, `$IsWindows`, `-PassThru`, `Get-Content -Raw`,
  `--session-id`, `--resume`, `--name`, `crossSessionInbound`,
  `--permission-mode`, `bypassPermissions`, `--output-format`,
  `--max-budget-usd`, `--plugin-dir`, `--append-system-prompt`,
  `caffeinate`, `AUTOPILOT_LOGS`, `AUTOPILOT_PLUGIN_DIR`,
  `AUTOPILOT_BUDGET_USD`, `APPEND_SP`, `AUTOPILOT_CLAUDE`,
  `AUTOPILOT_BATCH`, `claude.ps1`, `-RedirectStandardInput`,
  `-RedirectStandardOutput`, `-RedirectStandardError`, `.launch.in`,
  `.launch.out`, `.launch.err`, `self-test passed`, and
  `run.ps1 <tag> <cwd> <prompt-file> [--resume <session-id>]`.
- `grep -cE -- '--model|--continue|rm -r|-Recurse|Set-Content|Add-Content|Out-File' plugins/kenspc/skills/autopilot/scripts/run.ps1`
  prints 0.
- The header comment names the interface line, the `--self-test` form,
  PowerShell 7, the six environment variables, the five files, the three
  `<tag>.launch.*` files, the two timeline lines, `<batch>-costs.txt` as
  written by the skill, and that the
  script is checked on macOS only with no hang-up protection there.
- `git diff --stat c08b9ec HEAD -- plugins/kenspc/skills/autopilot/SKILL.md plugins/kenspc/skills/autopilot/scripts/run.sh plugins/kenspc/commands`
  prints nothing, and `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`
  still prints `self-test passed` and exits 0.
- The pointer-label grep and the `MUST|NEVER|CRITICAL` grep print nothing
  on the file, `bash scripts/check-no-model-names.sh` exits 0,
  `bash scripts/check-all.sh` exits 0 with `guards run: 10`, and
  `claude plugin validate --strict ./plugins/kenspc` passes.

---

### Task 2: Doc-sync

**Status:** DONE

**Implementation notes:**
- Decisions:
  - Promoted, from Task 1: the `started` line ends with an explicit LF on
    every platform. It went into `plugins/kenspc/README.md` § Autopilot
    (the drivers paragraphs) and into the CHANGELOG's `run.ps1` bullet,
    each time together with the LF-only, no-BOM files the task specified.
    Why: a Windows user who parses the driver's output would look for it
    there.
  - Needs a home, from Task 1: whether `.launch.err` keeps the inner
    pwsh's own error on Windows is left to the Windows acceptance. On
    macOS it does not (Task 1's Changes/tradeoffs). Suggested destination:
    `docs/roadmap.md`, the Windows-acceptance item for `run.ps1` that the
    release commit appends. It is outside this task's list, so it was
    written nowhere.
  - Local, from Task 1, left in the task document and git:
    - the in-process launch refusals in the self-test;
    - reading `.err` through PowerShell's error view, and keeping the
      flags on the `$argv` line;
    - `caffeinate -i -w` beside the worker;
    - `EscapeSingleQuotedStringContent` for literals;
    - single-pass template substitution;
    - the default-stub resolution check;
    - relative-path resolution and the invariant-culture timestamp.

    Each explains a code choice inside `run.ps1`, and the file's header and
    comments carry what an editor of it needs.
- Changes/tradeoffs:
  - `plugins/kenspc/README.md`: the drivers paragraph now ends at the
    `run.sh` shape sentence. Four short paragraphs follow for `run.ps1`:
    the interface and self-test; the launch mechanism and line ends; the
    `<tag>.launch.*` files; and the macOS-only check with the skill still
    running `run.sh`. Beyond the task's list, they name the three launch
    files and the macOS caveat on them, so that a reader of the README
    alone learns what the driver writes.
  - `plugins/kenspc/CHANGELOG.md`: the `run.ps1` bullet already sat under
    `### Added`. It was rewritten in place, with nested details, and its
    "Until then …" sentence went. The Documentation bullet gains the
    row-11 clause.
  - `CLAUDE.md`: in the layout tree, `run.sh` stays first and `run.ps1`
    comes after it (not alphabetical), because `run.sh` is the driver the
    skill runs. `run.sh`'s comment drops "(the PowerShell mirror follows)".
    The File Structure `scripts/` bullet names both drivers.
  - `docs/release-checklist.md`: row 11 gains the one clause after the
    `run.sh` self-test clause. Row 1, the rest of row 11, row 12, and the
    pre-flight block are untouched. The root `README.md` and
    `docs/roadmap.md` are untouched, as listed.
  - Verification:
    - `bash scripts/check-all.sh --self-test` exits 0 with
      `guards run: 10` and `self-tests run: 9`.
    - Both `claude plugin validate --strict` runs pass.
    - Both zero-diff commands print nothing.
    - The checklist clause appears unwrapped (`grep -F`) in the checklist
      and the CHANGELOG, the `## 3.9.0 — unreleased` heading is
      unchanged, and no "follows" wording remains in the four documents.

Depends on: Task 1

Bring the documents below in line with what Task 1 implemented, as
recorded in its `**Implementation notes:**` block, and promote its
decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies
no other file):
- `CLAUDE.md` § Plugin Directory Layout — `run.ps1` joins the tree under
  `skills/autopilot/scripts/`, beside `run.sh`, with a comment naming it
  the PowerShell mirror of `run.sh`, checked on macOS only; `run.sh`'s
  comment drops "(the PowerShell mirror follows)" (plan Step 3.1; CL5,
  CL18). § Skill Development Conventions, File Structure — the
  `scripts/` bullet's "today only the autopilot's `run.sh`" names
  `run.ps1` too (CL18). The plan's other CLAUDE.md changes — § Project
  Overview, § SKILL.md Frontmatter Fields, § Subagent Review Architecture,
  § Non-Goals (plan Step 2.1); that step is outside this task document:
  leave this change to the task document that covers it
  (`docs/tasks/batch-f-autopilot-tasks.md`).
- `plugins/kenspc/README.md` § Autopilot, the drivers paragraph — names
  both drivers: `run.ps1` beside `run.sh`, with the same interface, files,
  lines, and refusals, run as `pwsh -NoProfile -File …/run.ps1 …` under
  PowerShell 7, and its `--self-test`; checked on macOS only (a parse and
  the self-test), attached to the launching shell there; the skill copies
  and runs `run.sh`, and nothing picks a driver by platform until the
  Windows acceptance; the sentence "The PowerShell mirror, `run.ps1`,
  follows in a later release, once the bash driver has passed acceptance."
  goes (plan Step 3.1; CL16, CL17). The plan's other README changes —
  § Skills, § Commands, § Recommended Workflow, the rest of § Autopilot,
  § Known behavior, § Requirements (plan Step 2.2); that step is outside
  this task document: leave this change to the task document that covers
  it.
- `README.md` § Available Plugins (skills table, Commands line) — the
  autopilot row and command (plan Step 2.2); that step is outside this task
  document: leave this change to the task document that covers it. Task 1
  changes nothing here: the row names no driver, and the file stays
  untouched (CL18).
- `plugins/kenspc/CHANGELOG.md` — the `## 3.9.0 — unreleased` entry: the
  bullet "**The PowerShell driver `run.ps1` follows** in a later release …"
  becomes an `### Added` bullet for `run.ps1` as Task 1 built it — the same
  interface, files, lines, and refusals as `run.sh`; `Start-Process pwsh`
  with the inner command passed by `-EncodedCommand` and
  `-WindowStyle Hidden` on Windows only; the self-test with a `claude.ps1`
  stub on a temporary PATH entry, including a launch whose paths hold a
  space and a single quote; checked with `pwsh` on macOS (a parse and the
  self-test); the skill still runs `run.sh`; Windows acceptance a roadmap
  line — and its "Until then …" sentence goes; the Documentation bullet
  names the row-11 clause below (plan Steps 2.3 and 3.1; CL16–CL18). The
  rest of the entry (plan Step 2.3); that step is outside this task
  document: leave this change to the task document that covers it.
- `docs/release-checklist.md` § the smoke table, row 11 — one clause:
  `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`
  prints `self-test passed` and exits 0 (CL18; plan Step 3.1). Row 1, the
  rest of row 11, row 12, and the pre-flight block (plan Step 2.4); that
  step is outside this task document: leave this change to the task
  document that covers it — the pre-flight counts stay `guards run: 10` and
  `self-tests run: 9`.
- `docs/roadmap.md` — the heading becomes `## Next minor (3.10.0)` and the
  Windows-acceptance line for `run.ps1` is appended (plan § The release
  commit); that step is outside this task document: leave this change to
  the release commit.

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes
of Task 1. Write each decision that a future reader would look for in
one of the listed documents into that document, in the document's own
language and structure. List a decision that belongs in a durable document
but fits none of the listed ones under `## Decisions needing a home` in the
run report with a suggested destination, and write it nowhere. Leave a
decision that only explains a local code choice where it is. Create or
modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behavior Task 1 implemented, so
  that a reader of that document alone learns it.
- Every promoted decision appears in the document named for it, in that
  document's language.
- No file outside the listed documents was created or modified by this task
  (this task document's status update aside).

---

## Notes

- The plan's Documentation impact records three documents as unaffected:
  `docs/dry-runs/README.md`, `plugins/kenspc/references/plan-document-example.md`,
  and `plugins/kenspc/references/task-document-example.md`. No task edits
  them.
- Platform facts this document relies on, all checked on this machine with
  pwsh 7.6.6 under `$TMPDIR` before it was written: `Start-Process
  -WindowStyle` is refused on macOS; a `claude.ps1` on a PATH entry placed
  first resolves before the installed `claude`, and a `Start-Process` child
  inherits that PATH; `$null | & <native>` gives the native program an
  empty stdin (0 bytes read); a child started with `Start-Process` outlived
  a parent pwsh that exited normally; `-EncodedCommand` carried a path with
  a space and a single quote and passed the inner exit status through; a
  `.ps1` run in-process sends `Write-Error` output to a `2>` redirection
  and `[Console]::Error.WriteLine` past it; a caller reading a
  `Start-Process` launch through a command substitution waited out a
  six-second child until `-RedirectStandardInput`,
  `-RedirectStandardOutput`, and `-RedirectStandardError` were given, and
  `Start-Process` refused one path for stdout and stderr. The `Start-Process`
  documentation (PowerShell 7.6) states that array values holding spaces
  need escaped quotes, and that on non-Windows platforms the child is
  terminated when the launching shell is closed.
- Not exercised here, and left to the Windows acceptance (the roadmap
  line): `run.ps1` on Windows at all, including native argument passing of
  the `--settings` JSON value through a `.cmd` shim, the hidden window and
  the redirected standard streams together, the child's independence from
  the launching shell, and the CRLF behavior the LF-only writes guard
  against.
- On editing plugin files: a headless session under
  `--permission-mode bypassPermissions` edits the plugin's files as any
  other (CLAUDE.md § Development Workflow); a session sees a plugin edit
  only in its next session, so this round's review and driver check run as
  separate sessions.
- After Task 2, the round's mechanical check is the release checklist's
  pre-flight block — the effort-override diff (unchanged), both
  `claude plugin validate --strict` runs, and
  `bash scripts/check-all.sh --self-test` with `guards run: 10` and
  `self-tests run: 9` — together with the zero-diff command in the
  Constraints, the pointer-label grep on `run.ps1`, the parse check with its
  control, both drivers' self-tests with their failing stubs, and the
  canonical check of the first task document (its Context, run as a bash
  script file from `$TMPDIR`), which still exits 0 with
  `blocks compared: 12, result: PASS`. The review then runs over this
  round's commits (`/kenspc-task-review` with that range), and the
  acceptance session checks `run.ps1` (plan § Testing Strategy, case 6).
- The release commit (plan § The release commit) is not a task here: it
  moves `plugin.json` to 3.9.0, dates the CHANGELOG heading, retitles the
  roadmap's heading to `## Next minor (3.10.0)` and appends item 11
  (Windows acceptance of `run.ps1`), and `git rm`s
  `docs/briefs/autopilot-method.md`, `docs/plans/batch-f-autopilot.md`, and
  both task documents; no tag.
