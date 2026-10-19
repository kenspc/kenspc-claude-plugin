#Requires -Version 7.0
<#
.SYNOPSIS
    Keeps an instruction file inside its budget, free of all-caps emphasis, and pointing at
    paths that exist.

.DESCRIPTION
    An instruction file opts in with one line of its own:

        <!-- budget: lines=120 words=4200 -->

    Three checks then run over the text Claude Code actually loads - everything outside
    block HTML comments, which are stripped before loading:

      1. Budget. Non-blank lines and words must stay within the numbers on that line.
      2. Emphasis. No all-caps MUST / NEVER / ALWAYS / CRITICAL / IMPORTANT / REQUIRED /
         NOT outside backtick code, which may be quoting someone else's text.
      3. Paths. A path in backticks whose first folder is an entry at the repo root
         (`config/...` and `.claude/...` here, `apps/...` or `docs/...` in a repo that has
         them) must exist in this repo. A span that names an existing path as a whole, a
         file name with spaces included, passes before it is split into words. A `~/...`
         path, and the command that starts a backtick command line (a span whose first
         word is followed by a flag such as `-x` or `--name`), are checked
         on this machine too, but only as warnings: `docker` exists on the Mac and not on
         Windows by design, so a failure there would be a false alarm.

.NOTES
    The budget numbers live in the checked file, not here, so that this script and the
    kenspc-personal plugin's PostToolUse hook - which warns Claude after an edit - read
    the same numbers. Both count the same way; -SelfTest pins the counts of the good
    fixture, and the hook's own test pins the same numbers.

    A comment is recognised per line: a line holding `<!--` starts one, a line holding
    `-->` ends it, and both lines are excluded. That is block-level only, which matches
    what Claude Code strips.

    The repo root is two folders above this script, so a copy placed at
    `.claude/tests/instruction-lint.ps1` in another repo checks that repo's paths. Keying
    the path check on the root's own entries, not on a list kept here, is what lets the
    copy run unchanged; an example such as `src/foo.ts` in a repo without `src/` is left
    alone. The root's entries are those in the working tree plus those in the last commit,
    so a root folder renamed or deleted before it is committed still counts: the paths that
    still name it fail rather than pass as examples. Once that commit lands, they would pass
    as examples; the pre-commit hook runs before it does.

    A file with no budget line exits 3, not 0. A check that silently skipped a file would
    read as a pass.

    -SelfTest runs every fixture under instruction-lint/ and asserts its exit code and the
    message that must appear, so a check that stopped detecting anything turns red.

    Exit codes:  0 pass (warnings allowed)   1 a check failed   3 could not check
#>
[CmdletBinding()]
param(
    # Files to check. Relative paths resolve against the repo root.
    [string[]] $Path = @('config/claude-code/CLAUDE.global.md'),

    # Run the fixtures instead of checking files.
    [switch] $SelfTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$fixtureDir = Join-Path $PSScriptRoot 'instruction-lint'

# Root entries in the working tree, plus those in HEAD: see the header. Outside a git
# checkout, the working tree alone.
$rootEntries = @(Get-ChildItem -LiteralPath $repoRoot -Force -Name)
if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
    $headEntries = @(git -C $repoRoot ls-tree --name-only HEAD 2>$null)
    if ($LASTEXITCODE -eq 0) { $rootEntries += $headEntries }
}

# Words that only ever add volume. Acronyms such as PR, PATH or UTC are not on the list.
$emphasis = 'MUST|NEVER|ALWAYS|CRITICAL|IMPORTANT|REQUIRED|NOT'

# First words of backtick command lines that are shell keywords, zsh builtins or
# placeholders in this repo's examples, not programs to look up.
$notPrograms = @('cd', 'local', 'export', 'read', 'echo', 'exit', 'for', 'while', 'do',
    'done', 'if', 'then', 'setopt', 'producer', 'check')

function Get-LoadedLines {
    param([string[]] $Lines)

    $inComment = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if ($line.Contains('<!--')) { $inComment = $true }
        if (-not $inComment) {
            [pscustomobject]@{ Number = $i + 1; Text = $line }
        }
        if ($line.Contains('-->')) { $inComment = $false }
    }
}

function Get-PathVerdict {
    # $null when the text is not a repo path (its first folder is not an entry at the repo
    # root), else whether the path exists. `.` and `..` never count as a first folder.
    param([string] $Candidate)

    if ($Candidate -notmatch '^(?!\.\.?/)([^/~]+)/') { return $null }
    if ($rootEntries -cnotcontains $Matches[1]) { return $null }
    return (Test-Path -LiteralPath (Join-Path $repoRoot $Candidate))
}

function Test-InstructionFile {
    param([string] $File)

    $full = if ([IO.Path]::IsPathRooted($File)) { $File } else { Join-Path $repoRoot $File }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        Write-Host "  CANNOT CHECK  $File - file not found"
        return 3
    }

    $lines = @(Get-Content -LiteralPath $full -Encoding utf8)
    # The whole line must be the comment. A file that only mentions the syntax in prose
    # (a README describing it) has not opted in.
    $budget = $lines | Select-String -Pattern '^\s*<!--\s*budget:\s*lines=(\d+)\s+words=(\d+)\s*-->\s*$' |
        Select-Object -First 1
    if (-not $budget) {
        Write-Host "  CANNOT CHECK  $File - no '<!-- budget: lines=N words=N -->' line"
        return 3
    }
    $maxLines = [int] $budget.Matches[0].Groups[1].Value
    $maxWords = [int] $budget.Matches[0].Groups[2].Value

    $loaded = @(Get-LoadedLines -Lines $lines)
    $content = @($loaded | Where-Object { $_.Text.Trim() -ne '' })
    $words = ($content | ForEach-Object { @($_.Text.Trim() -split '\s+').Count } |
        Measure-Object -Sum).Sum
    if ($null -eq $words) { $words = 0 }

    $failures = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()

    if ($content.Count -gt $maxLines) {
        $failures.Add("lines: $($content.Count) of $maxLines")
    }
    if ($words -gt $maxWords) {
        $failures.Add("words: $words of $maxWords")
    }

    $inFence = $false
    foreach ($entry in $loaded) {
        $text = $entry.Text
        if ($text.TrimStart().StartsWith('```')) { $inFence = -not $inFence; continue }
        if ($inFence) { continue }

        $prose = [regex]::Replace($text, '`[^`]*`', '')
        foreach ($m in [regex]::Matches($prose, "\b($emphasis)\b")) {
            $failures.Add("emphasis: line $($entry.Number) has '$($m.Value)'")
        }

        foreach ($span in [regex]::Matches($text, '`([^`]+)`')) {
            $code = $span.Groups[1].Value
            $tokens = @($code.Trim() -split '\s+')
            # A file name may hold spaces, so a span that is one existing path as a whole
            # is not split into words that each name a path that does not exist.
            $wholePath = $tokens.Count -gt 1 -and
                (Get-PathVerdict $code.Trim().TrimEnd('.', ',', ';', ':', ')')) -eq $true
            foreach ($token in $tokens) {
                $clean = $token.TrimEnd('.', ',', ';', ':', ')')
                if ($wholePath -or $clean -match '[<>*…{}$]') { continue }
                $verdict = Get-PathVerdict $clean
                if ($verdict -eq $false) {
                    $failures.Add("path: line $($entry.Number) names '$clean', which is not in this repo")
                }
                elseif ($clean -match '^~/') {
                    $home_ = [Environment]::GetFolderPath('UserProfile')
                    if (-not (Test-Path -LiteralPath (Join-Path $home_ $clean.Substring(2)))) {
                        $warnings.Add("line $($entry.Number): '$clean' does not exist on this machine")
                    }
                }
            }
            # A span is a command line only when a flag follows the first word. Without
            # that test, quoted error messages (`no matches found`) read as commands.
            $first = $tokens[0]
            $hasFlag = @($tokens | Select-Object -Skip 1 | Where-Object { $_ -cmatch '^--?[a-zA-Z]' }).Count -gt 0
            if ($hasFlag -and $first -cmatch '^[a-z][a-z0-9._-]*$' -and
                $notPrograms -notcontains $first -and
                -not (Get-Command -Name $first -CommandType Application -ErrorAction SilentlyContinue)) {
                $warnings.Add("line $($entry.Number): command '$first' is not installed on this machine")
            }
        }
    }

    $summary = "$($content.Count)/$maxLines lines, $words/$maxWords words"
    if ($failures.Count -eq 0) {
        Write-Host "  PASS  $File ($summary)"
    }
    else {
        Write-Host "  FAIL  $File ($summary)"
        $failures | ForEach-Object { Write-Host "        $_" }
    }
    $warnings | Select-Object -Unique | ForEach-Object { Write-Host "        WARN $_" }
    if ($failures.Count -eq 0) { return 0 } else { return 1 }
}

if ($SelfTest) {
    # Fixture name -> exit code it must produce and text its output must contain.
    $cases = [ordered]@{
        'good.md'                 = @(0, 'PASS', '6/6 lines, 29/29 words')
        'over-lines.md'           = @(1, 'lines: 4 of 3')
        'over-words.md'           = @(1, 'words: 9 of 5')
        'emphasis.md'             = @(1, "has 'NEVER'")
        'emphasis-exempt.md'      = @(0, 'PASS')
        'missing-path.md'         = @(1, "'.claude/does-not-exist.md'")
        'missing-path-any-root.md' = @(1, "'.git/no-such-file-instruction-lint'")
        'path-unknown-root.md'    = @(0, 'PASS')
        'path with spaces.md'     = @(0, 'PASS')
        'machine-warning.md'      = @(0, 'WARN')
        'no-budget.md'            = @(3, 'no ''<!-- budget')
        'budget-mention-only.md'  = @(3, 'no ''<!-- budget')
    }
    $pwsh = (Get-Command pwsh).Source
    $red = 0
    foreach ($name in $cases.Keys) {
        $expected = $cases[$name]
        $out = & $pwsh -NoProfile -File $PSCommandPath -Path (Join-Path $fixtureDir $name) 2>&1 | Out-String
        $rc = $LASTEXITCODE
        $missing = @($expected[1..($expected.Count - 1)] | Where-Object { -not $out.Contains($_) })
        if ($rc -eq $expected[0] -and $missing.Count -eq 0) {
            Write-Host "  ok    $name (exit $rc)"
        }
        else {
            $red++
            Write-Host "  RED   $name - exit $rc, expected $($expected[0]); missing: $($missing -join ' | ')"
            Write-Host ($out.TrimEnd() -replace '(?m)^', '        | ')
        }
    }
    Write-Host ''
    if ($red -eq 0) { Write-Host "Every fixture produced its expected verdict."; exit 0 }
    Write-Host "$red fixture(s) did not produce their expected verdict."
    exit 1
}

Write-Host ''
Write-Host 'INSTRUCTION LINT'
$worst = 0
foreach ($file in $Path) {
    $rc = Test-InstructionFile -File $file
    if ($rc -gt $worst) { $worst = $rc }
}
exit $worst
