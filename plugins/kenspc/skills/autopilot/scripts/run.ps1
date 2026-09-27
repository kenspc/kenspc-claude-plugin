#Requires -Version 7.3
# run.ps1 — the PowerShell mirror of run.sh, the autopilot skill's driver.
# Starts one headless worker session in the background and returns at once;
# the worker's exit is recorded in a file, never reported over a socket.
#
# Interface
#   run.ps1 <tag> <cwd> <prompt-file> [--resume <session-id>]
#   run.ps1 --self-test
#
#   invoked as: pwsh -NoProfile -File <path>/run.ps1 …
#
#   <tag>          the worker's session name (--name) and the stem of its files
#   <cwd>          the directory the worker runs in
#   <prompt-file>  the prompt, read from this file with Get-Content -Raw inside
#                  the worker's own pwsh; it is never typed on a command line,
#                  so no caller has to quote it
#   --resume <session-id>
#                  resume that session instead of starting a fresh one; the
#                  fallback for a worker that has already exited
#
# PowerShell 7.3 or later (pwsh). Why the #Requires line: pwsh 7.0 to 7.2
# pass arguments to a native program the legacy way, which drops the double
# quotes inside a value, so the worker would receive the --settings value as
# {crossSessionInbound:accept}, which is not JSON, and a prompt stripped of
# its double quotes; and under Windows PowerShell 5.1 $IsWindows is $null, so
# the hidden-window branch below would silently not apply, and the pwsh this
# script starts may not exist there. An older PowerShell does not run the
# script at all: it names the required version and exits 1. The arguments
# are read from $args as bash-style tokens (--self-test, --resume), which
# pwsh -File passes through as plain strings.
#
# Environment (all optional)
#   AUTOPILOT_LOGS        the logs directory; default $HOME/Projects/_smoke/_logs
#   AUTOPILOT_PLUGIN_DIR  when set, --plugin-dir <value> is passed (plugin mode)
#   AUTOPILOT_BUDGET_USD  when set, --max-budget-usd <value> is passed
#   APPEND_SP             when set, --append-system-prompt <value> is passed
#                         (the cannot-ask variant)
#   AUTOPILOT_CLAUDE      the executable; default claude
#   AUTOPILOT_BATCH       the batch name in the timeline's file name; default
#                         the tag's prefix before its last "-s" (batch-x-s3
#                         gives batch-x)
#
# Files, all under the logs directory
#   <tag>.session   the session id, written before the process starts
#   <tag>.pid       the id of the pwsh process Start-Process started, written
#                   at launch. Its command line is "pwsh -NoProfile
#                   -EncodedCommand <base64>", with no tag in it, unlike
#                   run.sh's "bash <path>/run.sh <tag> …": a caller that tells
#                   a live worker from a pid left by a reboot by looking for
#                   the tag on that command line reads every live run.ps1
#                   worker as a leftover, so it needs another test here
#   <tag>.json      the worker's stdout (--output-format json)
#   <tag>.err       the worker's stderr, and the launched pwsh's own error
#                   when its script fails (exit status 1)
#   <tag>.exit      the worker's exit status, written right after it returns
#   <tag>.launch.in, <tag>.launch.out, <tag>.launch.err
#                   the launched pwsh's own standard streams, not the
#                   worker's: .launch.in is an empty file this script writes;
#                   .launch.out and .launch.err are empty on a clean launch
#                   and meant to hold the launched pwsh's own error when its
#                   script fails. On macOS and Linux Start-Process copies
#                   these streams through this script's own process, which
#                   returns at once, so there nothing written after it
#                   returns is kept, which is why that error also goes to
#                   <tag>.err; the worker still runs and <tag>.exit is still
#                   written
#   <batch>-timeline.log
#                   appended: "start <tag> pid <pid> …" at launch and
#                   "end   <tag> exit <status>" (three spaces) when the worker
#                   ends; the end time is the mtime of <tag>.exit
#   <batch>-costs.txt
#                   not written here: the skill upserts one line
#                   "<tag> <session_id> <total_cost_usd>" after each <tag>.exit
#
# Always passed: --name <tag>, --settings '{"crossSessionInbound":"accept"}',
# --permission-mode bypassPermissions, --output-format json; an empty stdin.
# A fresh launch passes --session-id <uuid>. No model flag and no continue
# flag are ever passed: the worker follows the session's model, and a resume
# names its session explicitly.
#
# Why the session id is written before the start: the transcript path and the
# resume id are then known even when the worker dies before its JSON lands.
# Why Start-Process pwsh -EncodedCommand: Start-Process is the PowerShell
# primitive that starts a process and returns at once, and the inner script
# it runs is where <tag>.exit can be written after the worker returns.
# Start-Process joins its argument list into one command line without quoting
# values that hold spaces, so the inner script travels base64-encoded
# (UTF-16LE), and every value inside it is a single-quoted literal with its
# quotes doubled: a path holding a space or a single quote arrives unchanged.
# Why -WindowStyle Hidden on Windows only: pwsh on macOS refuses the
# parameter. Why the launched pwsh's streams are redirected to the three
# <tag>.launch.* files: without them it inherits the caller's stdout and
# stderr, so a caller that reads the launch through a pipe (a command
# substitution, a tool that captures output) waits until the worker exits
# instead of getting the "started" line at once; three files, because
# Start-Process refuses one path for stdout and stderr, and files in the
# logs directory need no null-device branch per platform.
# Why caffeinate -i when present: a batch waits for its workers with no Bash
# call running in the main session, and on macOS the machine would otherwise
# sleep under them. It runs beside the worker as caffeinate -i -w <pid of the
# inner pwsh>, not in front of it: caffeinate runs its utility through its
# own PATH search, which cannot run a .ps1 and would skip a claude.ps1 stub
# for the installed claude, so the executable resolves exactly as it would
# without caffeinate. Where caffeinate does not exist the worker runs the
# same way without it.
# Why every file this script writes (.session, .pid, .exit, .launch.in, the
# timeline lines) goes through [System.IO.File] with an explicit LF and
# UTF-8 without a byte-order mark: the skill reads .exit and .session with
# cat, and the release checklist greps the timeline with $-anchored
# patterns; PowerShell's own file writers end lines with CRLF on Windows,
# which would make .exit read 0 plus a carriage return.
# Why --self-test: it proves the launch path on a machine without spending a
# session. A stub claude.ps1, put first on PATH, stands in for the
# executable; the self-test also launches a failing stub of its own, so a
# status other than 0 is seen to reach <tag>.exit, a slow one, so a launch
# read through a command substitution is seen to return while its worker
# runs, and, on macOS and Linux, a native #!/bin/sh one, so the -p and
# --settings values are seen to reach a native program, as the installed
# claude is one, byte for byte. A caller who sets AUTOPILOT_CLAUDE to a stub of their own
# exercises the failure path; a stub of theirs that is meant to pass writes
# its arguments and "cwd=<its working directory, logical or physical path>"
# to its error output (Write-Error, for a .ps1 run inside the inner pwsh),
# since the self-test
# reads the flags and the cwd in <tag>.err; prints to stdout a JSON object
# holding "result" and the --session-id value as "session_id"; exits 0; and
# stays alive for at least one second, since the second launch under the
# tag and the liveness check on <tag>.pid follow the launch within it.
#
# Checked on macOS only — a parse and the self-test. On macOS and Linux a
# Start-Process child is attached to the launching shell and is terminated
# when that shell is closed, so run.ps1 has no hang-up protection there;
# run.sh is the driver on macOS and Linux, and run.ps1 is written for
# Windows, where the child is independent of the shell that launched it.
#
# Exit status of a launch: 0 once the worker has been started; 2 on a usage
# or environment error, or when <tag>.pid names a live process and <tag>.exit
# is absent — an earlier worker under the same tag still running (nothing
# started); 1 from PowerShell itself when it is older than 7.3. The worker's
# own status goes to <tag>.exit. Self-test: 0 on pass, 1 on the first
# missing or wrong item.

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
$SettingsValue = '{"crossSessionInbound":"accept"}'
# The driver form of the wait: poll <tag>.exit every 2 s, at most 30 times.
$WaitIntervalSeconds = 2
$WaitAttempts = 30

# The inner script the launched pwsh runs. Each __NAME__ is replaced, in one
# pass, by a single-quoted literal (or, for SESSION and OPTIONAL, a list of
# them), so no value is parsed as code. The worker's flags stay on the $argv
# line and off the line that calls the executable: an error the stub writes
# quotes the calling line in <tag>.err, where the self-test reads the flags.
$InnerTemplate = @'
$enc = [System.Text.UTF8Encoding]::new($false)
$status = 1
try {
    Set-Location -LiteralPath __CWD__ -ErrorAction Stop
    $caffeinate = __CAFFEINATE__
    if ($caffeinate) { $null = Start-Process -FilePath $caffeinate -ArgumentList @('-i', '-w', "$PID") }
    $prompt = (Get-Content -Raw -LiteralPath __PROMPT__ -ErrorAction Stop) -replace '(\r?\n)+\z', ''
    $argv = @('-p', $prompt, __SESSION__, '--name', __TAG__, '--settings', __SETTINGS__, '--permission-mode', 'bypassPermissions', '--output-format', 'json'__OPTIONAL__)
    $global:LASTEXITCODE = 0
    $null | & __EXE__ @argv > __JSON__ 2> __ERR__
    $status = $LASTEXITCODE
} catch {
    # The reason also goes to <tag>.err: this pwsh's own stderr, the
    # .launch.err file, keeps nothing written after run.ps1 returns on macOS.
    # A failed append is dropped, so .exit and the end line are still written.
    $reason = 'run.ps1: ' + $_
    [Console]::Error.WriteLine($reason)
    try { [System.IO.File]::AppendAllText(__ERR__, "$reason`n", $enc) } catch { }
}
[System.IO.File]::WriteAllText(__EXIT__, "$status`n", $enc)
[System.IO.File]::AppendAllText(__TIMELINE__, 'end   ' + __TAG__ + " exit $status`n", $enc)
'@

function Stop-Driver {
    param([string]$Message)
    # Ends a launch with status 2: the command line below turns the error into
    # the exit status, and the self-test catches it to read the message.
    throw "run.ps1: $Message"
}

function Show-Usage {
    [Console]::Error.WriteLine("usage: pwsh -NoProfile -File $PSCommandPath <tag> <cwd> <prompt-file> [--resume <session-id>]")
    [Console]::Error.WriteLine("       pwsh -NoProfile -File $PSCommandPath --self-test")
    exit 2
}

function Write-LfFile {
    param([string]$Path, [string]$Text, [switch]$Append)
    try {
        if ($Append) {
            [System.IO.File]::AppendAllText($Path, $Text, $Utf8NoBom)
        } else {
            [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom)
        }
    } catch {
        Stop-Driver "cannot write $Path"
    }
}

function Read-FileText {
    param([string]$Path)
    # What bash's $(cat <file>) reads: the content with its trailing newlines
    # removed, or nothing when the file is missing. A carriage return stays,
    # so a CRLF .exit does not read as 0.
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return '' }
    return [System.IO.File]::ReadAllText($Path) -replace '\n+\z', ''
}

function ConvertTo-Literal {
    param([string]$Value)
    # A single-quoted PowerShell literal: every quote character PowerShell
    # reads as a single quote is doubled.
    return "'" + [System.Management.Automation.Language.CodeGeneration]::EscapeSingleQuotedStringContent($Value) + "'"
}

function Resolve-FullPath {
    param([string]$Path)
    # Relative to PowerShell's location, not the process's working directory,
    # which the [System.IO] methods would use.
    return $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
}

# Invoke-Launch <tag> <cwd> <prompt-file> <resume-session-id or empty>
# Starts the worker and returns "started <tag> pid <pid> session <id>".
function Invoke-Launch {
    param([string]$Tag, [string]$Dir, [string]$PromptFile, [string]$Resume)
    $logs = if ([string]::IsNullOrEmpty($env:AUTOPILOT_LOGS)) { "$HOME/Projects/_smoke/_logs" } else { $env:AUTOPILOT_LOGS }
    $exe = if ([string]::IsNullOrEmpty($env:AUTOPILOT_CLAUDE)) { 'claude' } else { $env:AUTOPILOT_CLAUDE }
    $batch = $env:AUTOPILOT_BATCH
    if ([string]::IsNullOrEmpty($batch)) {
        $cut = $Tag.LastIndexOf('-s', [System.StringComparison]::Ordinal)
        $batch = if ($cut -ge 0) { $Tag.Substring(0, $cut) } else { $Tag }
    }

    if ([string]::IsNullOrEmpty($Tag)) { Stop-Driver 'the tag is empty' }
    if ([string]::IsNullOrEmpty($Dir) -or -not (Test-Path -LiteralPath $Dir -PathType Container)) {
        Stop-Driver "cannot cd to $Dir"
    }
    if ([string]::IsNullOrEmpty($PromptFile) -or -not (Test-Path -LiteralPath $PromptFile -PathType Leaf)) {
        Stop-Driver "no prompt file $PromptFile"
    }
    $promptPath = Resolve-FullPath $PromptFile
    # An empty prompt — no content, or whitespace only — would start a paid
    # session with no instructions, which dies and is resumed into an empty
    # transcript before the stop.
    try { $promptText = [System.IO.File]::ReadAllText($promptPath) } catch { Stop-Driver "cannot read $PromptFile" }
    if ([string]::IsNullOrWhiteSpace($promptText)) { Stop-Driver "empty prompt file $PromptFile" }
    # A missing executable is a refusal here, not a worker that dies at once:
    # otherwise the driver prints "started", .exit reads a failure with an
    # empty .json, and the skill resumes a dead worker instead of reading the
    # reason. On macOS and Linux a file with no execute bit is missing too, as
    # run.sh's command -v reads it: Get-Command finds such a file, but the
    # worker's call would hand it to the platform's file opener instead of
    # running it, so no worker would start.
    $command = Get-Command -Name $exe -ErrorAction SilentlyContinue | Select-Object -First 1
    $executeBits = [System.IO.UnixFileMode]'UserExecute, GroupExecute, OtherExecute'
    if (-not $command -or (-not $IsWindows -and $command.CommandType -eq 'Application' -and -not ([System.IO.File]::GetUnixFileMode($command.Source) -band $executeBits))) {
        Stop-Driver "no executable $exe; set AUTOPILOT_CLAUDE or put claude on PATH"
    }
    $logsPath = Resolve-FullPath $logs
    # Start-Process reads its redirection paths as wildcard patterns, and no
    # escaping gets a path holding [ ] * or ? past it (the worker's own
    # redirection fails on them too), so such a logs directory or tag would
    # fail only after .session was written and a stale .exit removed; it is
    # refused here, before anything is written.
    if ("$logsPath$Tag".IndexOfAny([char[]]'[]*?') -ge 0) {
        Stop-Driver "the logs directory $logs or the tag $Tag holds one of [ ] * ?, which Start-Process cannot redirect to"
    }
    try { $null = [System.IO.Directory]::CreateDirectory($logsPath) } catch { Stop-Driver "cannot create the logs directory $logs" }

    $sessionFile = Join-Path $logsPath "$Tag.session"
    $pidFile = Join-Path $logsPath "$Tag.pid"
    $jsonFile = Join-Path $logsPath "$Tag.json"
    $errFile = Join-Path $logsPath "$Tag.err"
    $exitFile = Join-Path $logsPath "$Tag.exit"
    $timeline = Join-Path $logsPath "$batch-timeline.log"

    # A launch under a tag whose earlier worker still runs — its pid live and
    # its exit file not yet written — would overwrite that worker's files and
    # put two workers into one repository; it is refused before anything is
    # written. A pid file left by a machine that rebooted under a worker can
    # name an unrelated process, so the message says what to remove.
    if ((Test-Path -LiteralPath $pidFile) -and -not (Test-Path -LiteralPath $exitFile)) {
        $earlier = Read-FileText $pidFile
        $earlierId = 0
        if ([int]::TryParse($earlier, [ref]$earlierId) -and (Get-Process -Id $earlierId -ErrorAction SilentlyContinue)) {
            Stop-Driver "a worker under the tag $Tag is still running (pid $earlier, $pidFile); wait for $exitFile, or remove the pid file when that process is not the worker"
        }
    }

    $session = if ($Resume) { $Resume } else { [guid]::NewGuid().ToString().ToLowerInvariant() }
    Write-LfFile $sessionFile "$session`n"

    $optional = ''
    $extra = ''
    if (-not [string]::IsNullOrEmpty($env:AUTOPILOT_PLUGIN_DIR)) {
        $optional += ", '--plugin-dir', " + (ConvertTo-Literal $env:AUTOPILOT_PLUGIN_DIR)
        $extra += " plugin-dir $env:AUTOPILOT_PLUGIN_DIR"
    }
    if (-not [string]::IsNullOrEmpty($env:AUTOPILOT_BUDGET_USD)) {
        $optional += ", '--max-budget-usd', " + (ConvertTo-Literal $env:AUTOPILOT_BUDGET_USD)
        $extra += " budget USD $env:AUTOPILOT_BUDGET_USD"
    }
    if (-not [string]::IsNullOrEmpty($env:APPEND_SP)) {
        $optional += ", '--append-system-prompt', " + (ConvertTo-Literal $env:APPEND_SP)
        $extra += ' [append-system-prompt]'
    }
    if ($Resume) {
        $sessionArgs = "'--resume', " + (ConvertTo-Literal $session)
        $extra += ' resume'
    } else {
        $sessionArgs = "'--session-id', " + (ConvertTo-Literal $session)
    }
    $caffeinate = Get-Command -Name caffeinate -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1

    $values = @{
        CWD        = ConvertTo-Literal (Resolve-FullPath $Dir)
        CAFFEINATE = if ($caffeinate) { ConvertTo-Literal $caffeinate.Source } else { '$null' }
        PROMPT     = ConvertTo-Literal $promptPath
        SESSION    = $sessionArgs
        TAG        = ConvertTo-Literal $Tag
        SETTINGS   = ConvertTo-Literal $SettingsValue
        OPTIONAL   = $optional
        EXE        = ConvertTo-Literal $exe
        JSON       = ConvertTo-Literal $jsonFile
        ERR        = ConvertTo-Literal $errFile
        EXIT       = ConvertTo-Literal $exitFile
        TIMELINE   = ConvertTo-Literal $timeline
    }
    $inner = $InnerTemplate -replace '__([A-Z]+)__', { $values[$_.Groups[1].Value] }
    $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($inner))
    $launchArgs = @('-NoProfile', '-EncodedCommand', $encoded)

    $launchIn = Join-Path $logsPath "$Tag.launch.in"
    $launchOut = Join-Path $logsPath "$Tag.launch.out"
    $launchErr = Join-Path $logsPath "$Tag.launch.err"
    Write-LfFile $launchIn ''
    # The worker's two output files are emptied here, as run.sh's redirection
    # empties them when its subshell starts: the inner script opens them only
    # at the worker's call, so a failure before it (the location, the prompt
    # read) would leave an earlier launch's .json under the tag, read as this
    # worker's result, and add its reason to that launch's .err.
    Write-LfFile $jsonFile ''
    Write-LfFile $errFile ''
    # A stale exit file from an earlier launch under the same tag would read as
    # this worker's completion before it starts; nothing else is removed.
    try { [System.IO.File]::Delete($exitFile) } catch { Stop-Driver "cannot remove the stale $exitFile" }
    try {
        if ($IsWindows) {
            $proc = Start-Process -FilePath pwsh -ArgumentList $launchArgs -PassThru -WindowStyle Hidden -RedirectStandardInput $launchIn -RedirectStandardOutput $launchOut -RedirectStandardError $launchErr
        } else {
            $proc = Start-Process -FilePath pwsh -ArgumentList $launchArgs -PassThru -RedirectStandardInput $launchIn -RedirectStandardOutput $launchOut -RedirectStandardError $launchErr
        }
    } catch {
        Stop-Driver "cannot start pwsh: $($_.Exception.Message)"
    }
    $workerPid = $proc.Id
    # The worker runs from here on, so a failed write is reported on stderr and
    # the launch still returns its started line with status 0, as run.sh does:
    # a status of 2 reads as nothing started, and the caller would stop, or
    # launch a second worker, while this one keeps running.
    try { Write-LfFile $pidFile "$workerPid`n" } catch { [Console]::Error.WriteLine($_.Exception.Message) }
    $stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
    try {
        Write-LfFile $timeline "start $Tag pid $workerPid session $session at $stamp cwd $Dir prompt $PromptFile$extra`n" -Append
    } catch {
        [Console]::Error.WriteLine($_.Exception.Message)
    }
    return "started $Tag pid $workerPid session $session"
}

function Stop-SelfTest {
    param([string]$Message)
    [Console]::Error.WriteLine("self-test failed: $Message")
    exit 1
}

function Wait-ExitFile {
    param([string]$Path)
    $n = 0
    while (-not (Test-Path -LiteralPath $Path) -and $n -lt $WaitAttempts) {
        Start-Sleep -Seconds $WaitIntervalSeconds
        $n++
    }
}

function Test-FileLine {
    param([string]$Path, [string]$Pattern)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
    return @([System.IO.File]::ReadAllLines($Path) | Where-Object { $_ -cmatch $Pattern }).Count -gt 0
}

function Get-CwdLinePattern {
    param([string]$Dir)
    # The line a stub writes for its working directory, cwd=<path>, with the
    # path as PowerShell's location shows it or with its symbolic links
    # resolved, as pwd -P prints it (on macOS the temporary directory lies
    # under a link): either names the launch's cwd. Setting the process's
    # working directory to the path and reading it back resolves the links.
    $logical = Resolve-FullPath $Dir
    $saved = [System.IO.Directory]::GetCurrentDirectory()
    try {
        [System.IO.Directory]::SetCurrentDirectory($logical)
        $physical = [System.IO.Directory]::GetCurrentDirectory()
    } finally {
        [System.IO.Directory]::SetCurrentDirectory($saved)
    }
    return '(^|\s)cwd=(' + [regex]::Escape($logical) + '|' + [regex]::Escape($physical) + ')$'
}

function Test-ResultJson {
    param([string]$Path)
    try {
        $parsed = [System.IO.File]::ReadAllText($Path) | ConvertFrom-Json
    } catch {
        return $false
    }
    return ($parsed -is [System.Management.Automation.PSCustomObject]) -and ($null -ne $parsed.PSObject.Properties['result'])
}

function Invoke-Refused {
    param([string]$Tag, [string]$Dir, [string]$PromptFile)
    # A launch run in this process, as the command line runs it: the refusal
    # message, or $null when the launch was not refused.
    try {
        $null = Invoke-Launch $Tag $Dir $PromptFile ''
    } catch {
        return $_.Exception.Message
    }
    return $null
}

# Invoke-SelfTest: launch a stub through the same path and check every file
# the header names. The logs directory is always a fresh directory under the
# system temporary directory, whatever AUTOPILOT_LOGS says, so a self-test
# writes nothing under the workspace; it is left in place afterwards. Checks,
# in this order, naming the first that fails: a launch naming a missing
# executable, on macOS and Linux one with no execute bit, or an empty or
# whitespace-only prompt file, refused with the
# subject named and no .session; a logs directory holding a wildcard
# character refused with the directory named and not created; the logs
# directory created by the launch;
# the stdout line matching .pid and .session; a second launch under the
# running tag refused with the pid named and .session and .pid unchanged;
# .pid naming a live process other than the self-test's own; after the wait,
# .session and .pid non-empty, .json parseable with "result", .err present,
# .exit reading 0, the timeline's start and end lines; .session, .pid, .exit,
# .launch.in, and the timeline holding no carriage return and no byte-order
# mark; the three
# .launch.* files present, .launch.out and .launch.err empty; .err showing
# every always-passed flag with the id .session holds and cwd=<the launch's
# cwd>, and none of the three optional flags; .json's session_id equal to
# .session; a failing stub's status 3 in .exit and the end line, and the
# multi-line prompt it received as its -p value; a throwing stub's .exit
# reading 1, its end line, and its reason in .err; a launch through the
# command line whose .pid and timeline writes fail returning 0 with its
# started line, both failures on stderr, and .exit reading 0; on macOS and
# Linux, a
# native stub's .exit reading 0 and the -p and --settings values it received
# equal, byte for byte, to that prompt and the settings JSON; a resume
# launch through the command line with the three optional variables set;
# the command line refusing --resume with no id and an unknown argument; the
# batch-name default with a stale .exit removed and a stale .json and .err
# emptied at launch; a launch whose cwd
# and logs directory hold a space, a single quote, and a right single
# quotation mark; a launch whose cwd,
# prompt file, and logs directory are relative to the caller's location,
# its .exit reading 0 and its .json holding "result"; and a launch read
# through a command substitution returning while its slow stub still runs.
function Invoke-SelfTest {
    $tempRoot = [System.IO.Path]::GetTempPath()
    $base = Join-Path $tempRoot ('autopilot-selftest-' + [System.IO.Path]::GetRandomFileName().Replace('.', ''))
    if (Test-Path -LiteralPath $base) { Stop-Driver "cannot create a fresh directory $base" }
    try { $null = [System.IO.Directory]::CreateDirectory($base) } catch { Stop-Driver "cannot create a directory under $tempRoot" }
    # This script's own path: the resume and the command-substitution launches
    # below run it as a caller does, through its command line.
    $self = $PSCommandPath
    # Not created here: the first launch is what creates it.
    $logsDir = Join-Path $base 'logs'
    $stubDir = Join-Path $base 'stub'
    $null = [System.IO.Directory]::CreateDirectory($stubDir)

    if ([string]::IsNullOrEmpty($env:AUTOPILOT_CLAUDE)) {
        $stubPath = Join-Path $stubDir 'claude.ps1'
        Write-LfFile $stubPath (@'
# Stub executable for run.ps1 --self-test: writes its arguments and its
# working directory to the error stream, prints a result object to stdout,
# sleeps one second, exits 0. Write-Error, since this stub runs inside the
# inner pwsh, where [Console]::Error would bypass the 2> redirection.
Write-Error ($args -join ' ')
Write-Error "cwd=$((Get-Location).Path)"
$id = ''
for ($i = 0; $i -lt $args.Count - 1; $i++) {
    if ($args[$i] -ceq '--session-id' -or $args[$i] -ceq '--resume') { $id = $args[$i + 1] }
}
'{"type":"result","subtype":"success","is_error":false,"result":"stub ok","session_id":"' + $id + '","total_cost_usd":0.01,"num_turns":1}'
Start-Sleep -Seconds 1
exit 0
'@ + "`n")
        # First on PATH and reached through the default name claude, as the
        # installed executable is; a claude that resolved anywhere else would
        # start a real, paid session, so the resolution is checked first.
        $env:PATH = $stubDir + [System.IO.Path]::PathSeparator + $env:PATH
        $resolved = Get-Command -Name claude -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $resolved -or $resolved.Source -ne $stubPath) {
            Stop-SelfTest "claude does not resolve to the stub $stubPath after it was put first on PATH"
        }
        $shownExe = $resolved.Source
    } else {
        $shownExe = $env:AUTOPILOT_CLAUDE
    }
    # A second stub that exits 3, for the status check, and a third that stays
    # alive five seconds, for the command-substitution check; written whatever
    # AUTOPILOT_CLAUDE names, so a caller's stub is used for the passing
    # launches only. The second one also writes the prompt it receives, its
    # -p value, to a file of its own, so the prompt check runs whatever
    # AUTOPILOT_CLAUDE names too.
    $failStub = Join-Path $stubDir 'fail.ps1'
    $promptSeen = Join-Path $base 'prompt-seen.txt'
    Write-LfFile $failStub "[System.IO.File]::WriteAllText($(ConvertTo-Literal $promptSeen), [string]`$args[1])`nWrite-Error (`$args -join ' ')`nexit 3`n"
    $slowStub = Join-Path $stubDir 'slow.ps1'
    Write-LfFile $slowStub "Start-Sleep -Seconds 5`nexit 0`n"
    # A fourth that throws, for the check that a failure inside the worker's
    # own script still ends in .exit.
    $throwStub = Join-Path $stubDir 'throw.ps1'
    Write-LfFile $throwStub "throw 'self-test stub failure'`n"

    # The three optional variables are unset for the first launch, whatever
    # the caller's environment holds, so their flags can be asserted absent.
    $env:AUTOPILOT_PLUGIN_DIR = $null
    $env:AUTOPILOT_BUDGET_USD = $null
    $env:APPEND_SP = $null
    $env:AUTOPILOT_LOGS = $logsDir
    $env:AUTOPILOT_BATCH = 'selftest'
    $tag = 'selftest-s1'
    $promptFile = Join-Path $base 'prompt.md'
    Write-LfFile $promptFile "Reply ok and stop.`n"
    [Console]::Out.WriteLine("self-test: logs directory $logsDir")
    [Console]::Out.WriteLine("self-test: executable $shownExe")

    $sessionFile = Join-Path $logsDir "$tag.session"
    $pidFile = Join-Path $logsDir "$tag.pid"
    $exitFile = Join-Path $logsDir "$tag.exit"
    $errFile = Join-Path $logsDir "$tag.err"
    $jsonFile = Join-Path $logsDir "$tag.json"
    $timeline = Join-Path $logsDir 'selftest-timeline.log'

    # A launch naming a missing executable is refused before anything is
    # written: the path named, no .session.
    $savedExe = $env:AUTOPILOT_CLAUDE
    $missing = Join-Path $base 'no-such-claude'
    $env:AUTOPILOT_CLAUDE = $missing
    $refusal = Invoke-Refused $tag $base $promptFile
    $env:AUTOPILOT_CLAUDE = $savedExe
    if ($null -eq $refusal -or (Test-Path -LiteralPath $sessionFile)) {
        Stop-SelfTest "a launch with a missing executable was not refused before writing, expected a refusal and no .session"
    }
    if (-not $refusal.Contains("no executable $missing")) {
        Stop-SelfTest "the refusal of a missing executable does not name $missing"
    }
    # On macOS and Linux a file with no execute bit is refused the same way,
    # as run.sh's command -v refuses it.
    if (-not $IsWindows) {
        $noExec = Join-Path $stubDir 'noexec.sh'
        Write-LfFile $noExec "#!/bin/sh`nexit 0`n"
        $env:AUTOPILOT_CLAUDE = $noExec
        $refusal = Invoke-Refused $tag $base $promptFile
        $env:AUTOPILOT_CLAUDE = $savedExe
        if ($null -eq $refusal -or (Test-Path -LiteralPath $sessionFile)) {
            Stop-SelfTest "a launch with the executable $noExec, which has no execute bit, was not refused before writing, expected a refusal and no .session"
        }
        if (-not $refusal.Contains("no executable $noExec")) {
            Stop-SelfTest "the refusal of $noExec, which has no execute bit, does not name it"
        }
    }
    # An empty prompt file, and one of only whitespace, are refused the same
    # way: the paid empty session the guard exists to prevent.
    Write-LfFile (Join-Path $base 'empty.md') ''
    Write-LfFile (Join-Path $base 'blank.md') "`n  `n"
    foreach ($bad in 'empty', 'blank') {
        $badFile = Join-Path $base "$bad.md"
        $refusal = Invoke-Refused $tag $base $badFile
        if ($null -eq $refusal -or (Test-Path -LiteralPath $sessionFile)) {
            Stop-SelfTest "a launch with the $bad prompt file was not refused before writing, expected a refusal and no .session"
        }
        if (-not $refusal.Contains("empty prompt file $badFile")) {
            Stop-SelfTest "the refusal of the $bad prompt file does not name $badFile"
        }
    }
    # A logs directory holding a wildcard character is refused before
    # anything is written, not left to fail in Start-Process after .session:
    # the directory named, and not created. The executable is the self-test's
    # own stub, so a caller's missing one fails at the first launch, named,
    # rather than here as an unnamed logs directory.
    $wildLogs = Join-Path $base 'logs [1]'
    $env:AUTOPILOT_LOGS = $wildLogs
    $env:AUTOPILOT_CLAUDE = $failStub
    $refusal = Invoke-Refused $tag $base $promptFile
    $env:AUTOPILOT_CLAUDE = $savedExe
    $env:AUTOPILOT_LOGS = $logsDir
    if ($null -eq $refusal -or (Test-Path -LiteralPath $wildLogs)) {
        Stop-SelfTest "a launch with the logs directory $wildLogs was not refused before writing, expected a refusal and no such directory"
    }
    if (-not $refusal.Contains("the logs directory $wildLogs")) {
        Stop-SelfTest "the refusal of the logs directory $wildLogs does not name it"
    }

    # The launch's stdout line is what the caller reads the pid and the
    # session id from.
    $started = Invoke-Launch $tag $base $promptFile ''
    [Console]::Out.WriteLine($started)
    if (-not (Test-Path -LiteralPath $logsDir -PathType Container)) {
        Stop-SelfTest "the driver did not create the logs directory $logsDir"
    }
    $firstSession = Read-FileText $sessionFile
    $firstPid = Read-FileText $pidFile
    $expected = "started $tag pid $firstPid session $firstSession"
    if ($started -cne $expected) {
        Stop-SelfTest "the driver printed `"$started`", expected `"$expected`" from .pid and .session"
    }

    # A second launch under the same tag while the stub still runs (its one
    # second of sleep) is refused before anything is written: the pid named,
    # .session and .pid as they were. Without the refusal two workers would
    # share one repository and the second would overwrite the first's files.
    $refusal = Invoke-Refused $tag $base $promptFile
    if ($null -eq $refusal) {
        Stop-SelfTest "a second launch under the running tag $tag was not refused"
    }
    if (-not $refusal.Contains("still running (pid $firstPid,")) {
        Stop-SelfTest "the refusal of a second launch under $tag does not name pid $firstPid"
    }
    if ((Read-FileText $sessionFile) -cne $firstSession -or (Read-FileText $pidFile) -cne $firstPid) {
        Stop-SelfTest "a refused launch under $tag changed $sessionFile or $pidFile"
    }
    # The pid file names a live process other than this one: a gone pid with
    # no .exit reads as a dead worker and is resumed, so a driver that wrote
    # its own pid would have every worker resumed beside itself.
    $firstPidId = 0
    if (-not [int]::TryParse($firstPid, [ref]$firstPidId) -or $firstPidId -eq $PID -or -not (Get-Process -Id $firstPidId -ErrorAction SilentlyContinue)) {
        Stop-SelfTest "$pidFile names $firstPid, not a live process other than the self-test's own"
    }

    Wait-ExitFile $exitFile

    if ((Read-FileText $sessionFile) -eq '') { Stop-SelfTest "$sessionFile is missing or empty" }
    if ((Read-FileText $pidFile) -eq '') { Stop-SelfTest "$pidFile is missing or empty" }
    if (-not (Test-Path -LiteralPath $jsonFile -PathType Leaf)) { Stop-SelfTest "$jsonFile is missing" }
    if (-not (Test-ResultJson $jsonFile)) { Stop-SelfTest "$jsonFile is not a JSON object holding `"result`"" }
    if (-not (Test-Path -LiteralPath $errFile -PathType Leaf)) { Stop-SelfTest "$errFile is missing" }
    if (-not (Test-Path -LiteralPath $exitFile -PathType Leaf)) { Stop-SelfTest "$exitFile is missing after the wait" }
    $exitStatus = Read-FileText $exitFile
    if ($exitStatus -cne '0') { Stop-SelfTest "$exitFile reads $exitStatus, expected 0" }
    if (-not (Test-FileLine $timeline "^start $tag pid [0-9]+ ")) {
        Stop-SelfTest "$timeline has no start line for $tag"
    }
    if (-not (Test-FileLine $timeline "^end   $tag exit 0$")) {
        Stop-SelfTest "$timeline has no end line for $tag"
    }
    # The files this script writes end their lines with LF alone and carry no
    # byte-order mark, read as bytes: the reads above drop a BOM and a
    # trailing carriage return, while the skill reads .exit and .session with
    # cat and the release checklist greps the timeline with $-anchored
    # patterns.
    foreach ($written in $sessionFile, $pidFile, $exitFile, (Join-Path $logsDir "$tag.launch.in"), $timeline) {
        $bytes = [System.IO.File]::ReadAllBytes($written)
        if ($bytes -contains 13) { Stop-SelfTest "$written holds a carriage return" }
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            Stop-SelfTest "$written starts with a byte-order mark"
        }
    }

    # The launched pwsh's own streams go to files of their own, never to the
    # caller's: all three exist, and the two output files are empty on a clean
    # launch.
    foreach ($suffix in 'launch.in', 'launch.out', 'launch.err') {
        $streamFile = Join-Path $logsDir "$tag.$suffix"
        if (-not (Test-Path -LiteralPath $streamFile -PathType Leaf)) { Stop-SelfTest "$streamFile is missing" }
        if ($suffix -ne 'launch.in' -and ([System.IO.FileInfo]::new($streamFile)).Length -ne 0) {
            Stop-SelfTest "$streamFile is not empty after a clean launch"
        }
    }

    # The stub writes its arguments to .err, so the flags the header promises
    # are read there: a driver whose flag passing broke would otherwise pass
    # this gate and fail only inside a paid session.
    $session = Read-FileText $sessionFile
    $errText = [System.IO.File]::ReadAllText($errFile)
    foreach ($flag in "--session-id $session", "--name $tag", "--settings $SettingsValue", '--permission-mode bypassPermissions', '--output-format json') {
        if (-not $errText.Contains($flag)) { Stop-SelfTest "$errFile does not show $flag" }
    }
    $parsed = [System.IO.File]::ReadAllText($jsonFile) | ConvertFrom-Json
    $sessionProperty = $parsed.PSObject.Properties['session_id']
    if ($null -eq $sessionProperty -or [string]$sessionProperty.Value -cne $session) {
        Stop-SelfTest "$jsonFile does not carry the session_id that $sessionFile holds"
    }
    # With the three optional variables unset their flags are absent: a driver
    # that passed --plugin-dir "" on every launch would start every repo-mode
    # worker with an empty plugin directory.
    foreach ($flag in '--plugin-dir', '--max-budget-usd', '--append-system-prompt') {
        if ($errText.Contains($flag)) { Stop-SelfTest "$errFile shows $flag on a launch with its variable unset" }
    }
    # The worker runs in the launch's cwd, read here as a logical or a
    # physical path (on macOS the temporary directory lies under a symlink,
    # so the two differ): a driver that lost the location would run every
    # worker in the directory the driver was called from.
    if (-not (Test-FileLine $errFile (Get-CwdLinePattern $base))) {
        Stop-SelfTest "$errFile does not show cwd=$(Resolve-FullPath $base), the launch's cwd"
    }

    # A worker's non-zero status reaches .exit and the timeline's end line:
    # the skill reads both, and a driver that always wrote 0 would report
    # every failed worker as a success. The failing stub exits 3 at once.
    # Its prompt file has several lines, a double quote, and a trailing blank
    # line, and the stub's -p value is the file's whole content with the
    # trailing line breaks removed, as run.sh's $(cat) reads it: a driver
    # that passed the path, or the file's lines as separate values, would
    # start every worker with the wrong prompt.
    $failTag = 'selftest-s2'
    $multiPrompt = Join-Path $base 'multi.md'
    Write-LfFile $multiPrompt "First line.`nSay `"hi`" and stop.`n`n"
    $env:AUTOPILOT_CLAUDE = $failStub
    $null = Invoke-Launch $failTag $base $multiPrompt ''
    $env:AUTOPILOT_CLAUDE = $savedExe
    $failExit = Join-Path $logsDir "$failTag.exit"
    Wait-ExitFile $failExit
    if ((Read-FileText $failExit) -cne '3') {
        Stop-SelfTest "$failExit does not read 3, the failing stub's status"
    }
    if (-not (Test-FileLine $timeline "^end   $failTag exit 3$")) {
        Stop-SelfTest "$timeline has no end line with exit 3 for $failTag"
    }
    $expectedPrompt = "First line.`nSay `"hi`" and stop."
    $seen = if (Test-Path -LiteralPath $promptSeen -PathType Leaf) { [System.IO.File]::ReadAllText($promptSeen) } else { $null }
    if ($seen -cne $expectedPrompt) {
        Stop-SelfTest "the worker of $failTag received the prompt `"$seen`", expected the content of $multiPrompt without its trailing line breaks"
    }

    # A failure inside the worker's own script, here an executable that
    # throws, still writes .exit reading 1 and the end line, and leaves its
    # reason in .err: without .exit the caller would wait out its whole wait
    # for a worker that is gone, and without the reason it would resume a
    # worker that cannot start.
    $throwTag = 'selftest-s5'
    $env:AUTOPILOT_CLAUDE = $throwStub
    $null = Invoke-Launch $throwTag $base $promptFile ''
    $env:AUTOPILOT_CLAUDE = $savedExe
    $throwExit = Join-Path $logsDir "$throwTag.exit"
    $throwErr = Join-Path $logsDir "$throwTag.err"
    Wait-ExitFile $throwExit
    if ((Read-FileText $throwExit) -cne '1') {
        Stop-SelfTest "$throwExit does not read 1 after the worker's script failed"
    }
    if (-not (Test-FileLine $timeline "^end   $throwTag exit 1$")) {
        Stop-SelfTest "$timeline has no end line with exit 1 for $throwTag"
    }
    if (-not (Test-FileLine $throwErr 'self-test stub failure')) {
        Stop-SelfTest "$throwErr does not hold the reason the worker's script failed"
    }

    # A launch whose .pid and timeline writes fail after its worker started,
    # both files being directories here, still returns 0 with its started
    # line through the command line, names both failures on stderr, and its
    # worker still writes .exit: a status of 2 reads as nothing started, and
    # the caller would stop, or launch a second worker under the tag, while
    # this one runs.
    $noWriteTag = 'selftest-s8'
    $noWriteLogs = Join-Path $base 'logs-nowrite'
    $noWritePid = Join-Path $noWriteLogs "$noWriteTag.pid"
    $noWriteTimeline = Join-Path $noWriteLogs 'selftest-timeline.log'
    $noWriteStderr = Join-Path $base 'nowrite-stderr.txt'
    $null = [System.IO.Directory]::CreateDirectory($noWritePid)
    $null = [System.IO.Directory]::CreateDirectory($noWriteTimeline)
    $env:AUTOPILOT_LOGS = $noWriteLogs
    $noWriteOut = & pwsh -NoProfile -File $self $noWriteTag $base $promptFile 2> $noWriteStderr
    $rc = $LASTEXITCODE
    $env:AUTOPILOT_LOGS = $logsDir
    $noWriteLine = @($noWriteOut) -join "`n"
    if ($rc -ne 0 -or -not $noWriteLine.StartsWith("started $noWriteTag pid ", [System.StringComparison]::Ordinal)) {
        Stop-SelfTest "a launch of $noWriteTag whose .pid and timeline writes failed returned $rc with `"$noWriteLine`", expected 0 and its started line"
    }
    $noWriteErrText = [System.IO.File]::ReadAllText($noWriteStderr)
    foreach ($failed in $noWritePid, $noWriteTimeline) {
        if (-not $noWriteErrText.Contains("cannot write $failed")) {
            Stop-SelfTest "the launch of $noWriteTag does not name the failed write of $failed on stderr"
        }
    }
    $noWriteExit = Join-Path $noWriteLogs "$noWriteTag.exit"
    Wait-ExitFile $noWriteExit
    if ((Read-FileText $noWriteExit) -cne '0') {
        Stop-SelfTest "$noWriteExit does not read 0 after a launch whose .pid and timeline writes failed"
    }

    # On macOS and Linux, a launch through a native program, as the installed
    # claude is one. Every stub above is a .ps1 run inside the worker's own
    # pwsh, which takes its arguments as PowerShell values, so an argument
    # passing that dropped the double quotes inside a value would pass them
    # all and break only the real worker's --settings JSON and prompt. The
    # native stub writes the -p and --settings values it receives to files
    # beside it, compared byte for byte with the prompt, which holds double
    # quotes, and the settings JSON. A Windows .cmd stub is not launched here:
    # its argument passing is checked on Windows itself.
    if (-not $IsWindows) {
        $nativeTag = 'selftest-s7'
        $nativeStub = Join-Path $stubDir 'native.sh'
        Write-LfFile $nativeStub (@'
#!/bin/sh
# Native stub for run.ps1 --self-test: writes the -p and --settings values it
# receives to files beside it, prints a result object, exits 0.
dir=$(dirname "$0")
while [ "$#" -gt 1 ]; do
    case $1 in
        -p) printf '%s' "$2" > "$dir/native-prompt.txt" ;;
        --settings) printf '%s' "$2" > "$dir/native-settings.txt" ;;
    esac
    shift
done
printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"result":"stub ok","total_cost_usd":0.01,"num_turns":1}'
exit 0
'@ + "`n")
        [System.IO.File]::SetUnixFileMode($nativeStub, [System.IO.UnixFileMode]'UserRead, UserWrite, UserExecute')
        $env:AUTOPILOT_CLAUDE = $nativeStub
        $null = Invoke-Launch $nativeTag $base $multiPrompt ''
        $env:AUTOPILOT_CLAUDE = $savedExe
        $nativeExit = Join-Path $logsDir "$nativeTag.exit"
        Wait-ExitFile $nativeExit
        if ((Read-FileText $nativeExit) -cne '0') {
            Stop-SelfTest "$nativeExit does not read 0 after a launch through the native stub $nativeStub"
        }
        $nativeChecks = @(
            @{ Flag = '-p'; File = 'native-prompt.txt'; Want = $expectedPrompt },
            @{ Flag = '--settings'; File = 'native-settings.txt'; Want = $SettingsValue }
        )
        foreach ($check in $nativeChecks) {
            $seenFile = Join-Path $stubDir $check.File
            $seenBytes = if (Test-Path -LiteralPath $seenFile -PathType Leaf) { [System.IO.File]::ReadAllBytes($seenFile) } else { [byte[]]@() }
            $wantBytes = $Utf8NoBom.GetBytes($check.Want)
            if ([Convert]::ToBase64String($seenBytes) -cne [Convert]::ToBase64String($wantBytes)) {
                Stop-SelfTest "the native stub of $nativeTag received the $($check.Flag) value `"$($Utf8NoBom.GetString($seenBytes))`", expected `"$($check.Want)`" byte for byte"
            }
        }
    }

    # A resume launch with the first launch's id, through the command line a
    # caller uses, so a driver that dropped the --resume value is caught here
    # rather than starting a fresh session under the resume tag. The three
    # optional variables are set for this launch only, so their flags are read
    # from .err too: a plugin-mode worker launched without --plugin-dir would
    # load the installed plugin, and one without --max-budget-usd would run
    # unbounded.
    $resumeTag = "$tag-r1"
    $pluginDir = Join-Path $base 'plugin'
    $env:AUTOPILOT_PLUGIN_DIR = $pluginDir
    $env:AUTOPILOT_BUDGET_USD = '1'
    $env:APPEND_SP = 'x'
    $resumeOut = & pwsh -NoProfile -File $self $resumeTag $base $promptFile --resume $session
    $rc = $LASTEXITCODE
    $env:AUTOPILOT_PLUGIN_DIR = $null
    $env:AUTOPILOT_BUDGET_USD = $null
    $env:APPEND_SP = $null
    foreach ($line in @($resumeOut)) { [Console]::Out.WriteLine($line) }
    if ($rc -ne 0) { Stop-SelfTest "the resume launch of $resumeTag through the command line returned $rc, expected 0" }
    $resumeExit = Join-Path $logsDir "$resumeTag.exit"
    $resumeErr = Join-Path $logsDir "$resumeTag.err"
    Wait-ExitFile $resumeExit
    if (-not (Test-Path -LiteralPath $resumeExit -PathType Leaf)) { Stop-SelfTest "$resumeExit is missing after the wait" }
    $exitStatus = Read-FileText $resumeExit
    if ($exitStatus -cne '0') { Stop-SelfTest "$resumeExit reads $exitStatus, expected 0" }
    if ((Read-FileText (Join-Path $logsDir "$resumeTag.session")) -cne $session) {
        Stop-SelfTest "$(Join-Path $logsDir "$resumeTag.session") does not hold the resumed id $session"
    }
    $resumeText = [System.IO.File]::ReadAllText($resumeErr)
    if (-not $resumeText.Contains("--resume $session")) { Stop-SelfTest "$resumeErr does not show --resume $session" }
    if ($resumeText.Contains('--session-id')) { Stop-SelfTest "$resumeErr shows --session-id on a resume" }
    if (-not (Test-FileLine $timeline "^start $resumeTag pid [0-9]+ .* resume$")) {
        Stop-SelfTest "$timeline has no start line ending in resume for $resumeTag"
    }
    foreach ($flag in "--plugin-dir $pluginDir", '--max-budget-usd 1', '--append-system-prompt x') {
        if (-not $resumeText.Contains($flag)) { Stop-SelfTest "$resumeErr does not show $flag" }
    }
    # The parser's refusals, status 2 and nothing started: --resume without an
    # id would otherwise launch a fresh session under the resume tag, and an
    # unknown argument would pass unnoticed.
    $null = & pwsh -NoProfile -File $self "$resumeTag-x" $base $promptFile --resume 2>$null
    $rc = $LASTEXITCODE
    if ($rc -ne 2) { Stop-SelfTest "a command line with --resume and no id returned $rc, expected 2" }
    $null = & pwsh -NoProfile -File $self "$resumeTag-x" $base $promptFile --bogus 2>$null
    $rc = $LASTEXITCODE
    if ($rc -ne 2) { Stop-SelfTest "a command line with an unknown argument returned $rc, expected 2" }
    $refusedSession = Join-Path $logsDir "$resumeTag-x.session"
    if (Test-Path -LiteralPath $refusedSession) { Stop-SelfTest "a refused command line wrote $refusedSession" }

    # The batch-name default, with AUTOPILOT_BATCH unset: the tag's prefix
    # before its last "-s", so a batch name that itself holds "-s" keeps its
    # name in the timeline's file name. The same launch starts with a stale
    # .exit from an earlier launch under the tag in place: the file is gone
    # right after the launch and holds this worker's status after the wait. A
    # stale one would read as this worker's completion before it starts, with
    # an empty .json, so the worker would be counted dead and resumed beside
    # the live one. A stale .json and .err are in place too, and hold none of
    # their earlier content right after the launch: a worker whose script
    # failed before its own call would otherwise leave an earlier launch's
    # result, read as its own.
    $batchTag = 'self-s-test-s1'
    $env:AUTOPILOT_BATCH = $null
    $batchExit = Join-Path $logsDir "$batchTag.exit"
    $batchTimeline = Join-Path $logsDir 'self-s-test-timeline.log'
    Write-LfFile $batchExit "7`n"
    $staleFiles = @((Join-Path $logsDir "$batchTag.json"), (Join-Path $logsDir "$batchTag.err"))
    foreach ($stale in $staleFiles) { Write-LfFile $stale "stale content`n" }
    $null = Invoke-Launch $batchTag $base $promptFile ''
    if (Test-Path -LiteralPath $batchExit) {
        Stop-SelfTest "a stale $batchExit survived the launch and would read as this worker's completion"
    }
    foreach ($stale in $staleFiles) {
        if (Test-FileLine $stale '^stale content$') {
            Stop-SelfTest "$stale still holds an earlier launch's content after the launch"
        }
    }
    Wait-ExitFile $batchExit
    if ((Read-FileText $batchExit) -cne '0') { Stop-SelfTest "$batchExit does not read 0 after the wait" }
    if (-not (Test-FileLine $batchTimeline "^start $batchTag pid [0-9]+ ")) {
        Stop-SelfTest "$batchTimeline has no start line for $batchTag (the batch-name default)"
    }
    if (-not (Test-FileLine $batchTimeline "^end   $batchTag exit 0$")) {
        Stop-SelfTest "$batchTimeline has no end line for $batchTag"
    }

    # A cwd and a logs directory that hold a space, a single quote, and a
    # right single quotation mark (U+2019), which PowerShell also reads as a
    # quote: every path reaches the inner script as a literal, so one quote
    # left undoubled would break the worker's script and it would never write
    # .exit.
    $oddTag = 'selftest-s3'
    $oddDir = Join-Path $base ("cwd it's " + [char]0x2019)
    $oddLogs = Join-Path $base ("logs it's " + [char]0x2019)
    $null = [System.IO.Directory]::CreateDirectory($oddDir)
    $oddPrompt = Join-Path $oddDir 'prompt.md'
    Write-LfFile $oddPrompt "Reply ok and stop.`n"
    $env:AUTOPILOT_LOGS = $oddLogs
    $null = Invoke-Launch $oddTag $oddDir $oddPrompt ''
    $env:AUTOPILOT_LOGS = $logsDir
    $oddExit = Join-Path $oddLogs "$oddTag.exit"
    $oddErr = Join-Path $oddLogs "$oddTag.err"
    $oddTimeline = Join-Path $oddLogs 'selftest-timeline.log'
    Wait-ExitFile $oddExit
    if ((Read-FileText $oddExit) -cne '0') { Stop-SelfTest "$oddExit does not read 0 after the wait" }
    if (-not (Test-ResultJson (Join-Path $oddLogs "$oddTag.json"))) {
        Stop-SelfTest "$(Join-Path $oddLogs "$oddTag.json") is not a JSON object holding `"result`""
    }
    if (-not (Test-FileLine $oddErr (Get-CwdLinePattern $oddDir))) {
        Stop-SelfTest "$oddErr does not show cwd=$(Resolve-FullPath $oddDir), the launch's cwd"
    }
    if (-not (Test-FileLine $oddTimeline "^start $oddTag pid [0-9]+ ")) {
        Stop-SelfTest "$oddTimeline has no start line for $oddTag"
    }
    if (-not (Test-FileLine $oddTimeline "^end   $oddTag exit 0$")) {
        Stop-SelfTest "$oddTimeline has no end line for $oddTag"
    }

    # A cwd, a prompt file, and a logs directory given relative to the
    # caller's location, as run.sh accepts them: the worker's own script
    # changes location before it reads the prompt, so a path embedded as
    # given would not be found there and the worker would die at once. Run
    # in this process, whose location is not its working directory, so a
    # path resolved against the working directory is caught too.
    $relTag = 'selftest-s6'
    $null = [System.IO.Directory]::CreateDirectory((Join-Path $base 'rel-cwd'))
    Push-Location -LiteralPath $base
    $env:AUTOPILOT_LOGS = 'logs'
    $null = Invoke-Launch $relTag 'rel-cwd' 'prompt.md' ''
    $env:AUTOPILOT_LOGS = $logsDir
    Pop-Location
    $relExit = Join-Path $logsDir "$relTag.exit"
    Wait-ExitFile $relExit
    if ((Read-FileText $relExit) -cne '0') {
        Stop-SelfTest "$relExit does not read 0 after a launch with relative paths"
    }
    if (-not (Test-ResultJson (Join-Path $logsDir "$relTag.json"))) {
        Stop-SelfTest "$(Join-Path $logsDir "$relTag.json") is not a JSON object holding `"result`" after a launch with relative paths"
    }

    # A launch read through a command substitution returns while its worker
    # still runs: the slow stub stays alive five seconds, so a launch whose
    # processes held the caller's stdout would return only after it exits,
    # with .exit already written.
    $pipeTag = 'selftest-s4'
    $pipeExit = Join-Path $logsDir "$pipeTag.exit"
    $env:AUTOPILOT_CLAUDE = $slowStub
    $pipeOut = & pwsh -NoProfile -File $self $pipeTag $base $promptFile
    $rc = $LASTEXITCODE
    $pipeExitSeen = Test-Path -LiteralPath $pipeExit
    $env:AUTOPILOT_CLAUDE = $savedExe
    $pipeLine = @($pipeOut) -join "`n"
    [Console]::Out.WriteLine($pipeLine)
    if ($rc -ne 0 -or -not $pipeLine.StartsWith("started $pipeTag pid ", [System.StringComparison]::Ordinal)) {
        Stop-SelfTest "a launch of $pipeTag read through a command substitution returned $rc with `"$pipeLine`", expected 0 and its started line"
    }
    if ($pipeExitSeen) {
        Stop-SelfTest "a launch of $pipeTag read through a command substitution returned only after its worker wrote $pipeExit"
    }
    Wait-ExitFile $pipeExit
    if ((Read-FileText $pipeExit) -cne '0') { Stop-SelfTest "$pipeExit does not read 0 after the wait" }

    [Console]::Out.WriteLine('self-test passed')
    exit 0
}

try {
    $first = if ($args.Count -gt 0) { [string]$args[0] } else { '' }
    # A launch the self-test expected to start, refused or failed, is one of
    # its wrong items: status 1 and a "self-test failed:" line, not the
    # launch's status 2.
    if ($first -ceq '--self-test') {
        try { Invoke-SelfTest } catch { Stop-SelfTest $_.Exception.Message }
    }
    if ($first -ceq '' -or $first -ceq '-h' -or $first -ceq '--help' -or $args.Count -lt 3) { Show-Usage }
    $resume = ''
    $i = 3
    while ($i -lt $args.Count) {
        $arg = [string]$args[$i]
        if ($arg -ceq '--resume') {
            # An empty id would pass the count test and then launch a fresh
            # session under the resume tag, with no session to continue.
            if ($i + 1 -ge $args.Count -or [string]::IsNullOrEmpty([string]$args[$i + 1])) {
                Stop-Driver '--resume needs a session id'
            }
            $resume = [string]$args[$i + 1]
            $i += 2
        } else {
            Stop-Driver "unknown argument: $arg"
        }
    }
    $startedLine = Invoke-Launch ([string]$args[0]) ([string]$args[1]) ([string]$args[2]) $resume
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 2
}
# LF, not the platform's line end: a caller reads the pid and the session id
# from this line, and a CRLF would leave a carriage return on the id.
[Console]::Out.Write($startedLine + "`n")
exit 0
