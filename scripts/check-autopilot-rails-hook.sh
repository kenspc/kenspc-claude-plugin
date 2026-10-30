#!/usr/bin/env bash
# check-autopilot-rails-hook.sh
#
# Guards the autopilot worker rails hook,
# plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh, by feeding it
# fixtures and asserting each decision. Each fixture is a PreToolUse input
# carrying the field names and nesting of the live hook input Claude Code
# 2.1.283 sent for Bash, Write, Edit, and NotebookEdit calls (session_id,
# transcript_path, cwd, prompt_id, permission_mode, agent_id, agent_type,
# effort.level, hook_event_name, tool_name, tool_input, tool_use_id; the
# path is tool_input.file_path for Write and Edit and tool_input.notebook_path
# for NotebookEdit), with its environment — the marker, the roots joined by
# "|" in the form the driver writes them, and the cwd — and the expected
# decision, read the way the hook's deny form defines it:
#
#   deny   exit 2, empty stdout, a reason on stderr that names the
#          permitted route, or, for a field the hook cannot read, says no
#          route applies and asks for the denial to be reported; for a
#          listed suite command (the deny-suite expectation), the reason
#          names the listed prefix it matched and its route is the
#          suite-slot wrapper's line, naming the fixture wrapper path (or
#          saying the wrapper variable is empty), with no .trash and none
#          of the no-route text
#   allow  exit 0, empty stdout
#   inert  exit 0, empty stdout, empty stderr (the marker is not 1, or,
#          for a listed suite command with the commands variable empty,
#          check (f) has nothing to check)
#
# The fixtures cover every recursive rm spelling and command position the
# hook lists (denied), words quoted as $'...' or $"...", backslash escapes,
# substitutions inside double quotes, a | or & after a quoted or escaped <
# or >, a | after a line continuation that follows no < or >, and
# substitutions and redirections among the rm's own words, a
# redirection a line continuation splits included, among them; quoted
# mentions of
# rm -rf and an rm -rf in a comment (allowed); rm without a recursive flag
# and other work the hook must not deny — rm --force, rm -- -r, a <<- body
# with its tabs stripped, rm -f and then a | past a line continuation and
# grep -r (allowed); an rm after a heredoc whose delimiter
# line comes, and after a << whose delimiter line never does (denied); a
# write inside each root — the repository, the
# workspace, $TMPDIR, /tmp, /private/tmp — for Write, Edit, and NotebookEdit
# (allowed); a write outside every root (denied); a relative path resolved
# against the cwd (allowed inside, denied when a .. escapes); symlinked
# roots, and a .. after a link collapsed as written (denied); a target
# beginning with ~, ~/, or a space, read as Claude Code reads it, with HOME
# set to a fixture path; a Windows drive-letter path, not judged (allowed);
# a sibling that shares a root's prefix (denied); no roots with the marker
# set, and root entries that are not absolute (denied); redirections whose
# target lies outside the roots — > "$TMPDIR/../x", >> ~/.claude/x,
# 2> /etc/x, and &> ../outside from the repository root, > $HOME/.claude/x,
# >> ${HOME}/.claude/x, > ${TMPDIR}/../x, >| /etc/x, &>> /etc/x, a glued
# 2>/etc/x, a target after quoted text in the same word
# ("hi">>~/.claude/x, 'done'>/etc/x), a single-quoted > '/etc/x',
# >& /etc/x, 1>&/etc/x, and >> ~<user>/.claude/x for the hook's user
# (denied) — and those the hook must not deny:
# > /dev/null, > /dev/stderr, > /dev/fd/3, 2>&1, >&2, > "$TMPDIR/x",
# > out.txt, > 'out.txt', and > "~/x" in the repository, > "$OTHER/x" (not judged), a > inside single quotes, and a >
# in a heredoc body (allowed), with the hook's $TMPDIR set to a fixture
# path the redirection fixtures' roots hold and its $USER to a fixture
# name; from a cwd of <repository>/sub, a relative target after a literal
# cd read against the directory the cd moves to — cd <repository>/sub/x &&
# echo a > ../../y.log (allowed), cd b; echo a > ../../y.log from a cwd
# of a/ in the temporary directory, b/ an existing directory there and the
# roots the temporary real/ (allowed), mkdir -p x && cd x && echo a >
# ../y.log from the repository root (allowed, no existence test after
# &&), cd / && echo a > y.log, cd / then a line end, cd / && (echo a >
# y.log), and cd - && cd / && echo a > y.log (denied) — against the
# directory before a cd joined by ; whose target is no directory —
# cd nonexist/a/b/c; echo a > ../../../../y.log and cd /nonexistent-dir;
# echo a > ../../y.log (denied), and 6500 such cd commands to distinct
# paths, then a > to /etc (denied, timed) — and against the input's
# cwd or not at all — (cd /; echo a) > y.log, cd / | cat > y.log, and
# cd / & echo a > y.log (allowed), cd b on a line of its own in the body
# of an if, for, while, until, or case command, a { } group, or a function,
# then echo a > ../../y.log after the body, from the temporary a/ (denied,
# read against a/), and cd "$D", cd / ||, cd -, cd with no
# word, cd / x, cd /*/, cd ~, and cd / && false ||, each then a relative
# target that the input's cwd would deny or the cd's word would place
# outside (allowed, the directory unknown); gh issue view 1, sudo gh issue view 1, git -C . fetch, git push,
# git pull, git ls-remote origin, git remote update, git -c x.y=z push,
# git --no-pager fetch, git --git-dir=.git fetch, git -P push,
# git --git-dir .git fetch, git --no-optional-locks fetch, and a git clone
# of an https URL (also after --depth 1) or of a user@host:path or
# host:path source
# (denied, the reason's route to ask the main session), and git clone of
# a local path, git status, git --git-dir .git status, type gh, grep gh f,
# command -v gh, and which gh (allowed); with the suite variables set to
# KENSPC_AUTOPILOT_SUITE_COMMANDS='dotnet test|pnpm test' and a fixture
# wrapper path (check (f)), dotnet test, dotnet test --filter X,
# cd a && dotnet test, sudo dotnet test, time pnpm test, echo x; pnpm test,
# $(dotnet test), and /usr/local/share/dotnet/dotnet test (denied, the
# reason's route the wrapper's line), and
# bash /w/suite-slots.sh run -- dotnet test, echo "dotnet test",
# grep 'dotnet test' f, dotnet build, dotnet testx, pnpm install, and a
# dotnet test inside a heredoc body (allowed), and dotnet test with the
# commands variable empty and with the marker unset (inert); with
# './gradlew test|scripts/test.sh|CI=1 pnpm e2e|sudo -u ci make check'
# listed, ./gradlew test, gradlew test, ./scripts/test.sh, CI=1 pnpm e2e,
# pnpm e2e, and make check (denied) and ./gradlew build (allowed); and
# dotnet test with the wrapper variable empty (denied) — every other
# fixture running with the two suite variables empty; an input whose tool
# name, Bash command, or file-tool path the hook cannot read (denied, with
# no route offered and the denial to be reported); a
# Bash input over the hook's length cap
# (denied) and one under it (allowed); a command of many $( )
# substitutions under the cap, then rm -rf, a long command word with no
# slash, then rm -rf, a word of many <| pairs, then rm -rf, 8000
# redirections to a relative target in the repository, then one to /etc,
# 999 distinct targets in distinct directories under /tmp, then one to
# /etc, and 6000 distinct targets, over the hook's target cap, each denied
# in under half the hook's 5-second timeout (timed); and every
# denied fixture again
# without the marker and with the marker 0 (inert), each with the suite
# variables it was denied with. Why the fixtures carry
# the live input's shape: a hook that parses a harness-owned format goes
# stale silently when the format changes, and a fixture shaped by guesswork
# would keep passing.
#
# The repository and workspace roots are paths under /kenspc-rails-fixture,
# which does not exist, so they resolve the same on every machine; the
# symlinked roots use a link the guard makes in a temporary directory. The
# guard reads nothing under the autopilot workspace. The hook runs under
# /bin/bash when that exists (bash 3.2 on macOS), else bash.
#
# Main mode also checks the registration in plugins/kenspc/hooks/hooks.json:
# the hook's entry sits under PreToolUse with a matcher naming Bash, Write,
# Edit, and NotebookEdit, since the fixtures run the script directly and
# would stay green under a matcher that dropped a tool.
#
# Beside it, main mode checks the heading and the phrase an unreadable-field
# denial travels by. The literal `## Rail observations` must occur in the
# hook's unreadable-field reason (its REASON_UNREADABLE= assignment), which
# tells a worker where to list the denial; in the preamble template of
# plugins/kenspc/skills/autopilot/SKILL.md (the fenced block under
# `### The preamble`), which tells every worker to keep that section; and in
# that skill's `### Launch, wait, return` section (up to the next `### `
# heading), where the main session reads it at a worker's return. The phrase
# `could not be read from the hook input` must occur in the hook, which
# prints it in each unreadable-field reason — each unreadable-field fixture
# also asserts it in the reason the hook printed, so a reword of one field's
# reason turns that fixture red — and in SKILL.md's § Launch, wait, return,
# where the main session matches on it, and its `### The stop conditions`
# section, whose stop condition 11 names it. Why: the hook, the worker's
# prompt, and the main session meet at these two literals, and a rename in
# one carrier breaks the path silently while every fixture still passes. A
# missing literal is reported per carrier.
#
# Exit code 0: the registration holds, the heading and the phrase are in
#              every carrier, and every fixture decided as expected.
# Exit code 1: the registration, a carrier's literal, or a decision differs
#              (each one is reported).
# Exit code 2: missing hook file, hooks.json, or SKILL.md; no REASON_UNREADABLE=
#              assignment in the hook, no fenced template under
#              `### The preamble`, or no `### Launch, wait, return` or
#              `### The stop conditions` section in SKILL.md; or self-test
#              fixture stale.
#
# Same set -euo pipefail discipline and SCRIPT_DIR / REPO_ROOT derivation as
# the other guards; bash 3.2, no associative arrays. Mutations use a literal
# awk replacement rather than `sed -i`, whose in-place syntax differs
# between GNU and BSD sed. Temporary files are removed one by one on exit,
# never with a recursive rm.
#
# Optional flag:
#   --self-test    Run the mutation regression fixture. Copies the hook into
#                  a temporary directory, runs every fixture against the
#                  unmodified copy (must pass), then against ten mutants,
#                  each of which must turn at least one fixture red, named in
#                  the output: the rm detection removed, the root check
#                  removed, the marker check removed, the constant-time push
#                  removed (the timed $( ) fixture, which must be the first
#                  red), the last-character check removed (any fixture red:
#                  the quoted and escaped < or > fixtures catch it, the
#                  timed <| one only by a thin margin), and the
#                  unreadable-field phrase reworded in the Bash command's
#                  reason alone (the "Bash with no readable command field"
#                  fixture, which must be the first red, while the heading
#                  check on the same copy stays green, since the other two
#                  reasons still carry the phrase), the redirection check
#                  removed (any fixture red), the gh check removed (the
#                  "gh issue view" fixture, which must be the first red),
#                  the suite check (f) removed (the "dotnet test"
#                  fixture, which must be the first red), and the cd
#                  tracking removed (every relative target read from the
#                  input's cwd), which must turn each of the first three
#                  cd fixtures and the four whose directory is unknown
#                  (cd "$D", cd / ||, cd -, cd with no word) red.
#                  Then the restored copy
#                  must pass again. A mutation whose target text is not
#                  found exactly once is exit 2 (stale fixture), never a pass.
#                  It then copies SKILL.md beside the hook copy, runs the
#                  heading check on the two unmodified copies (must pass),
#                  and on six mutants, each of which must turn that check
#                  red with the mutated carrier named in its output: the
#                  heading dropped from the hook's unreadable-field reason,
#                  from the preamble template, and from § Launch, wait,
#                  return, and the phrase dropped from the hook, from
#                  § Launch, wait, return, and from § The stop conditions —
#                  every occurrence in the carrier's region. A
#                  heading mutation that replaces nothing is exit 2. The
#                  restored copies must pass again.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_REL="plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh"
SKILL_REL="plugins/kenspc/skills/autopilot/SKILL.md"
HEADING="## Rail observations"
PHRASE="could not be read from the hook input"
HOOKS_JSON_REL="plugins/kenspc/hooks/hooks.json"
if [[ -x /bin/bash ]]; then
    HOOK_BASH=/bin/bash
else
    HOOK_BASH=bash
fi

FX_BASE=/kenspc-rails-fixture
FX_REPO=$FX_BASE/repo
FX_WS=$FX_BASE/workspace
FX_HOME=$FX_BASE/home
# The hook's $TMPDIR in every fixture, a root of the redirection fixtures'
# roots, so that $TMPDIR/.. lies outside every root on every machine,
# whatever the guard's own TMPDIR is.
FX_TMPDIR=$FX_BASE/tmpdir/

WORK=""
cleanup() {
    [[ -n "${WORK:-}" && -d "$WORK" ]] || return 0
    rm -f "$WORK/input.json" "$WORK/stderr.txt" "$WORK/time.txt" "$WORK/link" "$WORK/real/deep" "$WORK/hook/rails.sh" "$WORK/hook/rails.sh.tmp" "$WORK/hook/SKILL.md" "$WORK/hook/SKILL.md.tmp"
    rmdir "$WORK/real/a/b" "$WORK/real/a" "$WORK/real" "$WORK/hook" 2>/dev/null || true
    rmdir "$WORK" 2>/dev/null || true
}

# make_work: the temporary directory for the symlinked-root fixtures (a
# directory real/ and a link to it; inside real/, a link deep to its
# subdirectory a/b) and for the hook's stderr.
make_work() {
    WORK=$(mktemp -d)
    trap cleanup EXIT
    mkdir -p "$WORK/real/a/b"
    ln -s "$WORK/real" "$WORK/link"
    ln -s "$WORK/real/a/b" "$WORK/real/deep"
    # $TMPDIR as the driver writes it (with the trailing slash macOS gives
    # it); the fixture stands in the temporary directory's parent when
    # TMPDIR is unset.
    FX_TMP="${TMPDIR:-$(dirname "$WORK")}"
    FX_ROOTS="$FX_REPO|$FX_WS|$FX_TMP|/tmp|/private/tmp"
}

# json_escape <text>: the text as the inside of a JSON string. Character by
# character rather than through gsub, whose backslash handling in the
# replacement differs between awks; a text with nothing to escape is
# printed as it stands, since the character loop takes a quarter of a
# second on the long-input fixtures.
json_escape() {
    case "$1" in
        *[\\\"]*|*$'\t'*|*$'\r'*|*$'\n'*) ;;
        *) printf '%s' "$1"; return 0 ;;
    esac
    printf '%s' "$1" | awk '
        {
            out = ""
            for (i = 1; i <= length($0); i++) {
                c = substr($0, i, 1)
                if (c == "\\") out = out "\\\\"
                else if (c == "\"") out = out "\\\""
                else if (c == "\t") out = out "\\t"
                else if (c == "\r") out = out "\\r"
                else out = out c
            }
            printf "%s%s", (NR > 1 ? "\\n" : ""), out
        }'
}

# make_input <tool> <cwd> <payload>: a hook input shaped like the live one.
# A tool written <tool>/no-key carries the payload under a key the hook does
# not read in place of command, file_path, or notebook_path, and one written
# <tool>/no-tool-name carries the tool's name under such a key in place of
# tool_name: the shapes a renamed field would take.
make_input() {
    local tool="$1" cwd payload tool_input name_key=tool_name
    cwd=$(json_escape "$2")
    payload=$(json_escape "$3")
    case "$tool" in
        */no-tool-name) name_key=renamed; tool=${tool%/no-tool-name} ;;
    esac
    case "$tool" in
        Bash) tool_input="{\"command\":\"$payload\",\"description\":\"Fixture command\"}" ;;
        Write) tool_input="{\"file_path\":\"$payload\",\"content\":\"fixture\"}" ;;
        Edit) tool_input="{\"file_path\":\"$payload\",\"old_string\":\"a\",\"new_string\":\"b\",\"replace_all\":false}" ;;
        NotebookEdit) tool_input="{\"notebook_path\":\"$payload\",\"cell_id\":\"c1\",\"new_source\":\"x = 2\",\"edit_mode\":\"replace\"}" ;;
        */no-key) tool_input="{\"renamed\":\"$payload\",\"content\":\"fixture\"}" ;;
    esac
    printf '{"session_id":"00000000-0000-4000-8000-000000000000","transcript_path":"%s/transcript.jsonl","cwd":"%s","prompt_id":"00000000-0000-4000-8000-000000000001","permission_mode":"bypassPermissions","agent_id":"a000000000000000","agent_type":"general-purpose","effort":{"level":"xhigh"},"hook_event_name":"PreToolUse","%s":"%s","tool_input":%s,"tool_use_id":"toolu_fixture"}' \
        "$cwd" "$cwd" "$name_key" "${tool%/no-key}" "$tool_input"
}

# decide <hook> <marker or -> <roots> <input> [<cpu seconds>]: runs the
# hook, sets RC, OUT, ERR, and GOT (deny, allow, inert, or other). The
# hook's KENSPC_AUTOPILOT_SUITE_COMMANDS and KENSPC_AUTOPILOT_SUITE_WRAPPER
# are the fixture's SUITE_CMDS and SUITE_WRAPPER, empty unless a fixture
# sets them, whatever the guard's own environment holds. The input
# goes through a file, not a pipe: the inert hook exits without reading it,
# and a pipe's writer would then fail and make the status its own. With
# <cpu seconds>, the hook and its awk run under that CPU limit where the
# system lets the guard set one.
decide() {
    local hook="$1" marker="$2" roots="$3" cpu="${5:-}"
    printf '%s' "$4" > "$WORK/input.json"
    RC=0
    OUT=$(
        unset KENSPC_AUTOPILOT_WORKER KENSPC_AUTOPILOT_WRITE_ROOTS KENSPC_AUTOPILOT_SUITE_COMMANDS KENSPC_AUTOPILOT_SUITE_WRAPPER
        export HOME="$FX_HOME" TMPDIR="$FX_TMPDIR" USER=kenspc-fixture
        if [[ "$marker" != "-" ]]; then export KENSPC_AUTOPILOT_WORKER="$marker"; fi
        export KENSPC_AUTOPILOT_WRITE_ROOTS="$roots"
        export KENSPC_AUTOPILOT_SUITE_COMMANDS="$SUITE_CMDS" KENSPC_AUTOPILOT_SUITE_WRAPPER="$SUITE_WRAPPER"
        if [[ -n "$cpu" ]]; then ulimit -t "$cpu" 2>/dev/null || true; fi
        "$HOOK_BASH" "$hook" < "$WORK/input.json" 2>"$WORK/stderr.txt"
    ) || RC=$?
    ERR=$(cat "$WORK/stderr.txt")
    if [[ "$RC" -eq 2 && -z "$OUT" && -n "$ERR" ]]; then
        GOT=deny
    elif [[ "$RC" -eq 0 && -z "$OUT" && -z "$ERR" ]]; then
        GOT=inert
    elif [[ "$RC" -eq 0 && -z "$OUT" ]]; then
        GOT=allow
    else
        GOT=other
    fi
}

FAILS=0
FIRST_RED=""
# Every label a run of the fixtures turned red, one per line.
RED_LABELS=""
QUIET=0
TIMED=""
SUBST_TIMED_LABEL="a command of 12000 \$( ) substitutions under the length cap, then rm -rf, decided in time"
# The cd fixtures the self-test's cd-tracking mutant must turn red.
CD_ABS_LABEL="cd to an absolute literal path && a relative > read against it"
CD_REL_LABEL="cd to a relative literal path; a relative > read against it"
CD_ROOT_LABEL="cd / && a relative > read against /"
CD_UNKNOWN_LABELS=("cd \"\$D\" leaves the directory unknown" "cd / || leaves the directory unknown" "cd - leaves the directory unknown" "cd with no word leaves the directory unknown")
# What an unreadable-field denial says in place of the permitted route. Why:
# the hook reads every later call the same way, so a worker sent down the
# route would retry until its cap; the autopilot preamble tells it to list
# the denial and end instead.
UNREADABLE_NO_ROUTE="No permitted route applies"
UNREADABLE_REPORT="list this denial with its reason under ## Rail observations and end"
# The route a gh or remote-git denial names, and the phrase the preamble's
# § 3 shares with it.
ASK_ROUTE="ask the main session"
# The suite variables of the current fixture (check (f)), and the wrapper
# path the suite fixtures hand the hook, which its reason must name.
SUITE_CMDS=""
SUITE_WRAPPER=""
FX_SUITE_WRAPPER=$FX_BASE/workspace/_prompts/fixture-suite-slots.sh
D_LABEL=(); D_TOOL=(); D_CWD=(); D_PAYLOAD=(); D_ROOTS=(); D_SCMDS=(); D_SWRAP=()

# fx <hook> <label> <expect> <marker or -> <roots> <tool> <cwd> <payload>
# <expect> deny-unreadable is a deny whose reason offers no route and asks
# for the denial to be reported, as a field the hook cannot read gets;
# deny-ask is a deny whose route is to ask the main session, as gh and
# remote git get; deny-suite is a deny whose route is the suite-slot
# wrapper's line, naming FX_SUITE_WRAPPER, as a listed suite command gets.
fx() {
    local hook="$1" label="$2" expect="$3" marker="$4" roots="$5" tool="$6" cwd="$7" payload="$8" ok=0 want="$3" route named p
    if [[ "$expect" == deny-unreadable || "$expect" == deny-ask || "$expect" == deny-suite ]]; then want=deny; fi
    decide "$hook" "$marker" "$roots" "$(make_input "$tool" "$cwd" "$payload")"
    if [[ "$GOT" == "$want" ]]; then
        ok=1
    elif [[ "$want" == allow && "$GOT" == inert ]]; then
        ok=1
    fi
    # A deny that names the route must not also say no route applies, which
    # would send the worker to end rather than take the route.
    if [[ "$expect" == deny && "$ok" -eq 1 ]] \
        && [[ "$ERR" != *.trash* || "$ERR" == *"$UNREADABLE_NO_ROUTE"* ]]; then
        ok=0
        GOT="deny without .trash in its reason, or saying '$UNREADABLE_NO_ROUTE'"
    fi
    # A gh or remote-git denial names the main session as the route, and
    # neither the .trash route nor the no-route reason.
    if [[ "$expect" == deny-ask && "$ok" -eq 1 ]] \
        && [[ "$ERR" != *"$ASK_ROUTE"* || "$ERR" == *.trash* || "$ERR" == *"$UNREADABLE_NO_ROUTE"* ]]; then
        ok=0
        GOT="deny whose reason does not say '$ASK_ROUTE', or names .trash or '$UNREADABLE_NO_ROUTE'"
    fi
    # A listed suite command's denial names the wrapper path as its route
    # (or, with the wrapper variable empty, says so) and the listed prefix
    # it matched, and neither the .trash route nor the no-route reason.
    if [[ "$expect" == deny-suite && "$ok" -eq 1 ]]; then
        route=$FX_SUITE_WRAPPER
        [[ -z "$SUITE_WRAPPER" ]] && route="KENSPC_AUTOPILOT_SUITE_WRAPPER is empty"
        named=0
        while IFS= read -r p; do
            [[ -n "$p" && "$ERR" == *"($p, listed in KENSPC_AUTOPILOT_SUITE_COMMANDS)"* ]] && named=1
        done <<< "$(printf '%s\n' "$SUITE_CMDS" | tr '|' '\n')"
        if [[ "$ERR" != *"$route"* || "$named" -eq 0 || "$ERR" == *.trash* || "$ERR" == *"$UNREADABLE_NO_ROUTE"* ]]; then
            ok=0
            GOT="deny whose reason does not name '$route' and a listed prefix, or names .trash or '$UNREADABLE_NO_ROUTE'"
        fi
    fi
    # Each unreadable-field reason must carry the phrase stop condition 11
    # matches on, so a reword of one field's reason turns its fixture red.
    if [[ "$expect" == deny-unreadable && "$ok" -eq 1 ]] \
        && [[ "$ERR" != *"$UNREADABLE_NO_ROUTE"* || "$ERR" != *"$UNREADABLE_REPORT"* || "$ERR" != *"$PHRASE"* || "$ERR" == *.trash* ]]; then
        ok=0
        GOT="deny whose reason does not say '$UNREADABLE_NO_ROUTE', '$UNREADABLE_REPORT', and '$PHRASE', or names .trash"
    fi
    # The autopilot preamble tells a worker to know a denial by this text in
    # its error, so a renamed prefix would leave that cue stale.
    if [[ "$want" == deny && "$ok" -eq 1 && "$ERR" != "autopilot rails: "* ]]; then
        ok=0
        GOT="deny whose reason does not open with 'autopilot rails: '"
    fi
    if [[ "$ok" -eq 0 ]]; then
        FAILS=$((FAILS + 1))
        if [[ -z "$FIRST_RED" ]]; then FIRST_RED=$label; fi
        RED_LABELS="$RED_LABELS$label"$'\n'
        if [[ "$QUIET" -eq 0 ]]; then
            echo "FAIL  $label: expected $expect, got $GOT (exit $RC, stdout '$OUT', stderr '$ERR')" >&2
        fi
    fi
}

# fx_deny: a fixture expected denied with the marker 1, recorded so that it
# is replayed without the marker and with the marker 0. An optional seventh
# argument, deny-unreadable, expects the unreadable-field reason.
fx_deny() {
    local hook="$1" label="$2" roots="$3" tool="$4" cwd="$5" payload="$6" expect="${7:-deny}" n
    fx "$hook" "$label" "$expect" 1 "$roots" "$tool" "$cwd" "$payload"
    n=${#D_LABEL[@]}
    D_LABEL[$n]=$label; D_ROOTS[$n]=$roots; D_TOOL[$n]=$tool; D_CWD[$n]=$cwd; D_PAYLOAD[$n]=$payload
    D_SCMDS[$n]=$SUITE_CMDS; D_SWRAP[$n]=$SUITE_WRAPPER
}

# fx_timed <hook> <label> <limit> <payload> [<reason> [<roots>]]: a Bash
# command expected denied for <reason> (default: its recursive rm), with
# the marker set and <roots> (default: the driver's), in under <limit> seconds of
# wall-clock time; recorded for the replays as fx_deny records. Why a time:
# a hook run that outlasts the hook's 5-second timeout (hooks.json) denies
# nothing, so a slow deny is an allow. The hook runs under a CPU limit of
# that timeout, so a slow scan costs the guard seconds, not the minute it
# would take; a run the limit cuts off is red on its time, and on its reason
# too, since its killed awk makes the hook deny the command as unreadable.
fx_timed() {
    local hook="$1" label="$2" limit="$3" payload="$4" reason="${5:-recursive rm}" roots="${6:-$FX_ROOTS}" why="" n input secs TIMEFORMAT=%R
    input=$(make_input Bash "$FX_REPO" "$payload")
    { time decide "$hook" 1 "$roots" "$input" 5 ; } 2> "$WORK/time.txt"
    secs=$(cat "$WORK/time.txt")
    TIMED="${TIMED:+$TIMED and }${secs}s"
    if ! awk -v e="$secs" -v l="$limit" 'BEGIN { exit !(e + 0 < l + 0) }'; then
        why="decided in ${secs}s, not under ${limit}s"
    elif [[ "$GOT" != deny || "$ERR" != "autopilot rails: "* || "$ERR" != *"$reason"* || "$ERR" != *.trash* ]]; then
        why="expected it denied for '$reason', got $GOT (exit $RC, stdout '$OUT', stderr '$ERR')"
    fi
    if [[ -n "$why" ]]; then
        FAILS=$((FAILS + 1))
        if [[ -z "$FIRST_RED" ]]; then FIRST_RED=$label; fi
        if [[ "$QUIET" -eq 0 ]]; then
            echo "FAIL  $label: $why" >&2
        fi
    fi
    n=${#D_LABEL[@]}
    D_LABEL[$n]=$label; D_ROOTS[$n]=$roots; D_TOOL[$n]=Bash; D_CWD[$n]=$FX_REPO; D_PAYLOAD[$n]=$payload
    D_SCMDS[$n]=$SUITE_CMDS; D_SWRAP[$n]=$SUITE_WRAPPER
}

# run_fixtures <hook>: every fixture; returns 1 when any decision differs.
run_fixtures() {
    local hook="$1" r="$FX_ROOTS" t k
    FAILS=0; FIRST_RED=""; RED_LABELS=""; TIMED=""; SUITE_CMDS=""; SUITE_WRAPPER=""
    D_LABEL=(); D_TOOL=(); D_CWD=(); D_PAYLOAD=(); D_ROOTS=(); D_SCMDS=(); D_SWRAP=()

    # rm spellings, denied.
    fx_deny "$hook" "rm spelling -r" "$r" Bash "$FX_REPO" 'rm -r build'
    fx_deny "$hook" "rm spelling -R" "$r" Bash "$FX_REPO" 'rm -R build'
    fx_deny "$hook" "rm spelling --recursive" "$r" Bash "$FX_REPO" 'rm --recursive build'
    fx_deny "$hook" "rm spelling bundle -rf" "$r" Bash "$FX_REPO" 'rm -rf build'
    fx_deny "$hook" "rm spelling bundle -fr" "$r" Bash "$FX_REPO" 'rm -fr build'
    fx_deny "$hook" "rm spelling bundle -Rf" "$r" Bash "$FX_REPO" 'rm -Rf build'
    fx_deny "$hook" "rm spelling bundle -vfr" "$r" Bash "$FX_REPO" 'rm -vfr build'
    fx_deny "$hook" "rm spelling split -f -r" "$r" Bash "$FX_REPO" 'rm -f -r build'
    fx_deny "$hook" "rm spelling path prefix /bin/rm" "$r" Bash "$FX_REPO" '/bin/rm -rf build'
    # An unquoted backslash escapes the next character, and before a line
    # break it joins the lines.
    fx_deny "$hook" "rm spelling with a leading backslash \\rm" "$r" Bash "$FX_REPO" '\rm -rf build'
    fx_deny "$hook" "rm flags after a line continuation" "$r" Bash "$FX_REPO" $'rm \\\n  -rf build'
    # A word quoted as $'...' or $"..." is read without its $.
    fx_deny "$hook" "rm spelling with an ANSI-C quoted flag \$'-rf'" "$r" Bash "$FX_REPO" "rm \$'-rf' build"
    fx_deny "$hook" "rm spelling as an ANSI-C quoted word \$'rm'" "$r" Bash "$FX_REPO" "\$'rm' -rf build"
    fx_deny "$hook" "rm spelling as a locale quoted word \$\"rm\"" "$r" Bash "$FX_REPO" '$"rm" -rf build'
    fx_deny "$hook" "rm after an ANSI-C quote holding an escaped quote" "$r" Bash "$FX_REPO" $'printf $\'it\\\'s\\n\'\nrm -rf build'
    # rm positions, denied.
    fx_deny "$hook" "rm position line start" "$r" Bash "$FX_REPO" $'echo start\nrm -rf build'
    fx_deny "$hook" "rm position after ;" "$r" Bash "$FX_REPO" 'ls; rm -rf build'
    fx_deny "$hook" "rm position after &&" "$r" Bash "$FX_REPO" 'true && rm -rf build'
    fx_deny "$hook" "rm position after ||" "$r" Bash "$FX_REPO" 'false || rm -rf build'
    fx_deny "$hook" "rm position after |" "$r" Bash "$FX_REPO" 'echo build | rm -rf build'
    fx_deny "$hook" "rm position after a lone &" "$r" Bash "$FX_REPO" 'sleep 1 & rm -rf build'
    fx_deny "$hook" "rm position after \$(" "$r" Bash "$FX_REPO" 'echo $(rm -rf build)'
    fx_deny "$hook" "rm position after backtick" "$r" Bash "$FX_REPO" 'echo `rm -rf build`'
    # A substitution inside double quotes still runs its command.
    fx_deny "$hook" "rm position after \$( inside double quotes" "$r" Bash "$FX_REPO" 'echo "$(rm -rf build)"'
    fx_deny "$hook" "rm position after a backtick inside double quotes" "$r" Bash "$FX_REPO" 'x="`rm -rf build`"'
    # A substitution among the rm's own words: the enclosing command's words
    # are kept below the substitution's and checked once it ends, at any
    # depth.
    fx_deny "$hook" "rm -rf with a \$( ) in its argument" "$r" Bash "$FX_REPO" 'rm -rf "$(pwd)/build"'
    fx_deny "$hook" "rm -rf with a \$( ) holding && in its argument" "$r" Bash "$FX_REPO" 'rm -rf "$(cd build && pwd)"'
    fx_deny "$hook" "rm -rf with a backtick substitution in its argument" "$r" Bash "$FX_REPO" 'rm -rf `pwd`/build'
    fx_deny "$hook" "rm -rf inside a \$( ), with a \$( ) in its argument" "$r" Bash "$FX_REPO" 'echo $(rm -rf $(mktemp -d))'
    # A redirection among the rm's own words: the & or | right after its <
    # or > stays in the word (2>&1, >|), so the recursive flag after it is
    # still the rm's.
    fx_deny "$hook" "rm -rf after a 2>&1 among its words" "$r" Bash "$FX_REPO" 'rm 2>&1 -rf build'
    fx_deny "$hook" "rm -r after a >| redirection among its words" "$r" Bash "$FX_REPO" 'rm >| rm.log -r build'
    # Bash joins a line continuation's lines before it splits words, so a
    # continuation between the < or > and its & or | leaves one redirection.
    fx_deny "$hook" "rm -rf after a 2>&1 split by a line continuation" "$r" Bash "$FX_REPO" $'rm 2>\\\n&1 -rf build'
    fx_deny "$hook" "rm -r after a >| split by a line continuation" "$r" Bash "$FX_REPO" $'rm >\\\n| rm.log -r build'
    # A continuation that follows no < or > joins no redirection: the | after
    # it still ends the command.
    fx_deny "$hook" "rm position after a | past a line continuation with no < or > before it" "$r" Bash "$FX_REPO" $'echo build\\\n|rm -rf build'
    fx_deny "$hook" "rm position after xargs" "$r" Bash "$FX_REPO" 'echo build | xargs rm -rf'
    fx_deny "$hook" "rm position after sudo" "$r" Bash "$FX_REPO" 'sudo rm -rf build'
    fx_deny "$hook" "rm position after command" "$r" Bash "$FX_REPO" 'command rm -rf build'
    fx_deny "$hook" "rm position after env" "$r" Bash "$FX_REPO" 'env rm -rf build'
    fx_deny "$hook" "rm position after env and an assignment" "$r" Bash "$FX_REPO" 'env FOO=1 rm -rf build'
    fx_deny "$hook" "rm position after exec" "$r" Bash "$FX_REPO" 'exec rm -rf build'
    fx_deny "$hook" "rm position after nohup" "$r" Bash "$FX_REPO" 'nohup rm -rf build'
    fx_deny "$hook" "rm position after time" "$r" Bash "$FX_REPO" 'time rm -rf build'
    fx_deny "$hook" "rm position after sudo -u and its argument" "$r" Bash "$FX_REPO" 'sudo -u root rm -rf build'
    fx_deny "$hook" "rm position after xargs -n and its argument" "$r" Bash "$FX_REPO" 'echo build | xargs -n 1 rm -rf'
    fx_deny "$hook" "rm position after an assignment prefix" "$r" Bash "$FX_REPO" 'FOO=1 rm -rf build'
    fx_deny "$hook" "rm position after then" "$r" Bash "$FX_REPO" 'if [ -d build ]; then rm -rf build; fi'
    fx_deny "$hook" "rm position after do" "$r" Bash "$FX_REPO" 'for d in a b; do rm -rf "$d"; done'
    fx_deny "$hook" "rm position after else" "$r" Bash "$FX_REPO" 'if false; then :; else rm -rf build; fi'
    fx_deny "$hook" "rm position after {" "$r" Bash "$FX_REPO" '{ rm -rf build; }'
    fx_deny "$hook" "rm position after !" "$r" Bash "$FX_REPO" '! rm -rf build'
    fx_deny "$hook" "rm position after env -u and its argument" "$r" Bash "$FX_REPO" 'env -u FOO rm -rf build'
    fx_deny "$hook" "rm position in a ( subshell" "$r" Bash "$FX_REPO" '(rm -rf build)'
    fx_deny "$hook" "rm position in a function NAME { body" "$r" Bash "$FX_REPO" 'function f { rm -rf build; }; f'
    fx_deny "$hook" "rm position after coproc" "$r" Bash "$FX_REPO" 'coproc rm -rf build'
    fx_deny "$hook" "rm position in a coproc NAME { body" "$r" Bash "$FX_REPO" 'coproc cleaner { rm -rf build; }'
    fx_deny "$hook" "rm spelling prefix of --recursive: --rec" "$r" Bash "$FX_REPO" 'rm --rec build'
    # A << whose delimiter line never comes — an arithmetic shift, or a
    # heredoc closed by EOF) inside $( — skips nothing: the lines after it
    # are read as commands.
    fx_deny "$hook" "rm after an arithmetic << on an earlier line" "$r" Bash "$FX_REPO" $'echo $((1<<2))\nrm -rf build'
    fx_deny "$hook" "rm after a heredoc closed by EOF) on an earlier line" "$r" Bash "$FX_REPO" $'x=$(cat <<EOF\nnote\nEOF)\nrm -rf build'
    # A heredoc whose delimiter line comes ends there: the lines after it
    # are commands again.
    fx_deny "$hook" "rm after a heredoc's delimiter line" "$r" Bash "$FX_REPO" $'cat <<EOF > notes.txt\nhello\nEOF\nrm -rf build'
    # A comment runs to the end of its line, a quote inside it included; a
    # # inside a word starts none.
    fx_deny "$hook" "rm on the line after a comment holding a quote" "$r" Bash "$FX_REPO" $'# don\'t keep the build\nrm -rf build'
    fx_deny "$hook" "rm after a # inside a word, which starts no comment" "$r" Bash "$FX_REPO" 'echo a#b; rm -rf build'
    # A Bash input longer than the hook scans within its timeout is denied
    # unscanned, rm or none; one under the cap is scanned.
    t=$(printf '%060000d' 0)
    fx "$hook" "a Bash input under the length cap, scanned" allow 1 "$r" Bash "$FX_REPO" "echo $t"
    t=$(printf '%070000d' 0)
    fx_deny "$hook" "a Bash input over the length cap" "$r" Bash "$FX_REPO" "echo $t"
    # Under the cap, the shape whose substitution-stack cost this fixture
    # guards: 12000 unquoted $( ) words (60 KB), then a recursive rm,
    # decided in under half the hook's timeout. Each $( ) once cost a copy
    # of every word before it, which took tens of seconds and let the rm
    # through.
    t=$(awk 'BEGIN { for (i = 0; i < 12000; i++) printf "$(x) " }')
    fx_timed "$hook" "$SUBST_TIMED_LABEL" 2.5 "echo $t; rm -rf build"
    # A command word of 64000 characters with no slash, then a recursive
    # rm, decided in under half the hook's timeout. Taking the word's base
    # name once ran a regex from every position in the word, which took
    # about 15 seconds and let the rm through.
    t=$(printf '%064000d' 0)
    fx_timed "$hook" "a command word of 64000 characters with no slash, then rm -rf, decided in time" 2.5 "$t; rm -rf build"
    # One word of 32000 <| pairs (64 KB), then a recursive rm, decided in
    # under half the hook's timeout. A | or & after < or > stays in the
    # word, and testing whether the word ended in < or > once read the
    # whole word on every | or &, which took over 3 seconds. That old check
    # decided this fixture in 3.354s when it was added, and in 3.3 to 3.64s
    # since, against about 0.55s for the hook: about 1.3 to 1.45 times the
    # limit. The self-test does not require this fixture to turn the
    # last-character mutant red, since a faster machine or awk would bring
    # the old check under the limit and fail the self-test on a correct
    # hook; the quoted and escaped fixtures below catch that mutant.
    t=$(awk 'BEGIN { for (i = 0; i < 32000; i++) printf "<|" }')
    fx_timed "$hook" "a word of 32000 <| pairs under the length cap, then rm -rf, decided in time" 2.5 "echo $t; rm -rf build"
    # A | or & after a quoted or escaped < or > ends the command: that < or
    # > is no redirection. The self-test's last-character mutant, the whole
    # word matched against [<>]$, misreads them too.
    fx_deny "$hook" "rm position after | following a double-quoted >" "$r" Bash "$FX_REPO" 'echo "a>"|rm -rf build'
    fx_deny "$hook" "rm position after | following a single-quoted <" "$r" Bash "$FX_REPO" "echo 'a<'|rm -rf build"
    fx_deny "$hook" "rm position after | following an escaped >" "$r" Bash "$FX_REPO" 'echo a\>|rm -rf build'
    fx_deny "$hook" "rm position after & following a double-quoted >" "$r" Bash "$FX_REPO" 'echo "->"&rm -rf build'

    # Redirection targets, judged by the root check the file tools get once
    # a leading ~, $HOME, ${HOME}, $TMPDIR, or ${TMPDIR} is expanded and .
    # and .. are collapsed as written; the roots hold the hook's $TMPDIR.
    rr="$FX_REPO|$FX_WS|$FX_TMPDIR|/tmp|/private/tmp"
    fx_deny "$hook" "a > to \$TMPDIR/.. outside the roots" "$rr" Bash "$FX_REPO" 'echo x > "$TMPDIR/../x"'
    fx_deny "$hook" "a >> to ~/.claude outside the roots" "$rr" Bash "$FX_REPO" 'echo x >> ~/.claude/x'
    fx_deny "$hook" "a 2> to /etc outside the roots" "$rr" Bash "$FX_REPO" 'echo x 2> /etc/x'
    fx_deny "$hook" "a &> to ../outside from the repository root" "$rr" Bash "$FX_REPO" 'echo x &> ../outside'
    # The other expansions and operators the hook lists.
    fx_deny "$hook" "a > to \$HOME/.claude outside the roots" "$rr" Bash "$FX_REPO" 'echo x > $HOME/.claude/x'
    fx_deny "$hook" "a >> to \${HOME}/.claude outside the roots" "$rr" Bash "$FX_REPO" 'echo x >> ${HOME}/.claude/x'
    fx_deny "$hook" "a > to \${TMPDIR}/.. outside the roots" "$rr" Bash "$FX_REPO" 'echo x > ${TMPDIR}/../x'
    fx_deny "$hook" "a >| to /etc outside the roots" "$rr" Bash "$FX_REPO" 'echo x >| /etc/x'
    fx_deny "$hook" "a &>> to /etc outside the roots" "$rr" Bash "$FX_REPO" 'echo x &>> /etc/x'
    fx_deny "$hook" "a 2> glued to /etc outside the roots" "$rr" Bash "$FX_REPO" 'echo x 2>/etc/x'
    # Quoted text before an unspaced > leaves its target unquoted.
    fx_deny "$hook" "a >> to ~/.claude after double-quoted text in the word" "$rr" Bash "$FX_REPO" 'echo "hi">>~/.claude/x'
    fx_deny "$hook" "a > to /etc after single-quoted text in the word" "$rr" Bash "$FX_REPO" "echo 'done'>/etc/x"
    # A single-quoted target is literal, judged as written.
    fx_deny "$hook" "a > to a single-quoted /etc target" "$rr" Bash "$FX_REPO" "echo x > '/etc/x'"
    fx "$hook" "a > to a single-quoted relative file in the repository" allow 1 "$rr" Bash "$FX_REPO" "echo x > 'out.txt'"
    # >& with a word other than a descriptor number writes to that word;
    # ~name of the hook user is that user's home.
    fx_deny "$hook" "a >& to /etc outside the roots" "$rr" Bash "$FX_REPO" 'echo x >& /etc/x'
    fx_deny "$hook" "a 1>& to /etc outside the roots, no space" "$rr" Bash "$FX_REPO" 'echo x 1>&/etc/x'
    fx "$hook" "a >&2 duplication, no target" allow 1 "$rr" Bash "$FX_REPO" 'echo x >&2'
    fx_deny "$hook" "a >> to ~<user>/.claude outside the roots" "$rr" Bash "$FX_REPO" 'echo x >> ~kenspc-fixture/.claude/x'
    fx "$hook" "a > to /dev/null" allow 1 "$rr" Bash "$FX_REPO" 'echo x > /dev/null'
    fx "$hook" "a > to /dev/stderr" allow 1 "$rr" Bash "$FX_REPO" 'echo x > /dev/stderr'
    fx "$hook" "a > to /dev/fd/3" allow 1 "$rr" Bash "$FX_REPO" 'echo x > /dev/fd/3'
    fx "$hook" "a > to a double-quoted ~/x, a file in the repository" allow 1 "$rr" Bash "$FX_REPO" 'echo x > "~/x"'
    fx "$hook" "a 2>&1 duplication, no target" allow 1 "$rr" Bash "$FX_REPO" 'ls 2>&1'
    fx "$hook" "a > to \$TMPDIR inside the roots" allow 1 "$rr" Bash "$FX_REPO" 'echo x > "$TMPDIR/x"'
    fx "$hook" "a > to a relative file in the repository" allow 1 "$rr" Bash "$FX_REPO" 'echo x > out.txt'
    fx "$hook" "a > to another expansion, not judged" allow 1 "$rr" Bash "$FX_REPO" 'echo x > "$OTHER/x"'
    fx "$hook" "a > inside single quotes, no redirection" allow 1 "$rr" Bash "$FX_REPO" "echo 'a > /etc/x'"
    fx "$hook" "a > in a heredoc body, no redirection" allow 1 "$rr" Bash "$FX_REPO" $'cat <<EOF > notes.txt\na > /etc/x\nEOF'
    # A relative target after a top-level cd to a literal path, joined by
    # && or ;, resolves against the directory the cd moves to; from the
    # cwd <repository>/sub, each outcome differs from the input-cwd
    # reading. The self-test's cd-tracking mutant must turn the first three
    # and CD_UNKNOWN_LABELS red.
    fx "$hook" "$CD_ABS_LABEL" allow 1 "$rr" Bash "$FX_REPO/sub" "cd $FX_REPO/sub/x && echo a > ../../y.log"
    # A cd joined by ; moves the directory only to an existing directory:
    # b/ exists under the temporary real/a/, the roots real/ alone.
    fx "$hook" "$CD_REL_LABEL" allow 1 "$WORK/real" Bash "$WORK/real/a" 'cd b; echo a > ../../y.log'
    fx "$hook" "mkdir -p x && cd x && a relative >, read against x with no existence test" allow 1 "$rr" Bash "$FX_REPO" 'mkdir -p x && cd x && echo a > ../y.log'
    fx_deny "$hook" "$CD_ROOT_LABEL" "$rr" Bash "$FX_REPO/sub" 'cd / && echo a > y.log'
    fx_deny "$hook" "cd / then a line end, a relative > read against /" "$rr" Bash "$FX_REPO/sub" $'cd /\necho a > y.log'
    fx_deny "$hook" "cd / && a subshell holding a relative >, read against /" "$rr" Bash "$FX_REPO/sub" 'cd / && (echo a > y.log)'
    fx_deny "$hook" "cd - leaves the directory unknown, a later cd / sets it" "$rr" Bash "$FX_REPO/sub" 'cd - && cd / && echo a > y.log'
    # A cd joined by ; to a path that is no directory leaves the directory
    # where it was, as bash stays after a cd that fails.
    fx_deny "$hook" "cd to a relative path that does not exist; a relative > read against the directory before it" "$rr" Bash "$FX_REPO/sub" 'cd nonexist/a/b/c; echo a > ../../../../y.log'
    fx_deny "$hook" "cd to an absolute path that does not exist; a relative > read against the directory before it" "$rr" Bash "$FX_REPO/sub" 'cd /nonexistent-dir; echo a > ../../y.log'
    # 6500 cd commands joined by ;, each to a distinct path that does not
    # exist (about 64 KB), then a > to /etc, decided in under half the
    # hook's timeout: each path's directory test forks a shell, and with no
    # cap on the tests this took about 13 seconds.
    t=$(awk 'BEGIN { for (i = 0; i < 6500; i++) printf "cd a%d; ", i }')
    fx_timed "$hook" "6500 cd commands to distinct paths that do not exist, then a > to /etc, decided in time" 2.5 "$t echo a > /etc/x" "redirects output outside" "$rr"
    # A cd inside a subshell, before a |, or before a lone & moves nothing
    # for the redirections after it.
    fx "$hook" "(cd /; echo a) > y.log, read against the input's cwd" allow 1 "$rr" Bash "$FX_REPO/sub" '(cd /; echo a) > y.log'
    fx "$hook" "cd / | cat > y.log, read against the input's cwd" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd / | cat > y.log'
    fx "$hook" "cd / & echo a > y.log, read against the input's cwd" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd / & echo a > y.log'
    # A cd on a line of its own in the body of a compound command or a
    # function moves nothing: b/ exists under the temporary real/a/, so a
    # cd read as top-level would move the directory there and allow the >.
    fx_deny "$hook" "a cd in an if body moves nothing" "$WORK/real" Bash "$WORK/real/a" $'if false; then
  cd b
fi
echo a > ../../y.log'
    fx_deny "$hook" "a cd in a for body moves nothing" "$WORK/real" Bash "$WORK/real/a" $'for i in 1; do
  cd b
done
echo a > ../../y.log'
    fx_deny "$hook" "a cd in a while body moves nothing" "$WORK/real" Bash "$WORK/real/a" $'while false; do
  cd b
done
echo a > ../../y.log'
    fx_deny "$hook" "a cd in an until body moves nothing" "$WORK/real" Bash "$WORK/real/a" $'until true; do
  cd b
done
echo a > ../../y.log'
    fx_deny "$hook" "a cd in a case arm moves nothing" "$WORK/real" Bash "$WORK/real/a" $'case x in
  y)
  cd b
  ;;
esac
echo a > ../../y.log'
    fx_deny "$hook" "a cd in a { } group moves nothing" "$WORK/real" Bash "$WORK/real/a" $'{
  cd b
}
echo a > ../../y.log'
    fx_deny "$hook" "a cd in a function body moves nothing" "$WORK/real" Bash "$WORK/real/a" $'f() {
  cd b
}
echo a > ../../y.log'
    # A cd the hook cannot read as one literal path, or joined by ||,
    # leaves the directory unknown, and a relative target is not judged.
    fx "$hook" "${CD_UNKNOWN_LABELS[0]}" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd "$D" && echo a > ../../y.log'
    fx "$hook" "${CD_UNKNOWN_LABELS[1]}" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd / || echo a > ../../y.log'
    fx "$hook" "${CD_UNKNOWN_LABELS[2]}" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd - && echo a > ../../y.log'
    fx "$hook" "${CD_UNKNOWN_LABELS[3]}" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd && echo a > ../../y.log'
    fx "$hook" "cd with two words leaves the directory unknown" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd / x && echo a > ../../y.log'
    fx "$hook" "cd to a glob leaves the directory unknown" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd /*/ && echo a > y.log'
    fx "$hook" "cd ~ leaves the directory unknown" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd ~ && echo a > ../../../y.log'
    # A || later in the list leaves the directory unknown: the command after
    # it runs when the cd failed, too.
    fx "$hook" "cd / && false || leaves the directory unknown" allow 1 "$rr" Bash "$FX_REPO/sub" 'cd / && false || echo a > y.log'
    # 8000 redirections to a relative target in the repository (about
    # 24 KB, under the cap, so it is scanned), then one to /etc, decided in
    # under half the hook's timeout.
    t=$(awk 'BEGIN { for (i = 0; i < 8000; i++) printf ">a " }')
    fx_timed "$hook" "8000 redirections inside the repository, then one to /etc, decided in time" 2.5 "echo $t> /etc/x" "redirects output outside" "$rr"
    # Distinct targets, each resolved in the shell: 999 in distinct
    # directories under /tmp (a link on macOS) and then one to /etc, judged
    # one by one; and 6000, over the hook's target cap, denied unjudged.
    t=$(awk 'BEGIN { for (i = 0; i < 999; i++) printf ">/tmp/a%d/x ", i }')
    fx_timed "$hook" "999 distinct redirection targets under /tmp, then one to /etc, decided in time" 2.5 "echo $t> /etc/x" "redirects output outside" "$rr"
    t=$(awk 'BEGIN { for (i = 0; i < 6000; i++) printf ">/tmp/%d ", i }')
    fx_timed "$hook" "6000 distinct redirection targets, over the target cap, decided in time" 2.5 "echo $t> /etc/x" "distinct redirection targets" "$rr"

    # gh at a command position, and git with a remote subcommand or a URL
    # clone, denied with the main session as the route; a local clone, a
    # local subcommand, gh as a mere word, and the commands that name gh
    # without running it, allowed.
    fx_deny "$hook" "gh issue view" "$r" Bash "$FX_REPO" 'gh issue view 1' deny-ask
    fx_deny "$hook" "git -C . fetch" "$r" Bash "$FX_REPO" 'git -C . fetch' deny-ask
    fx_deny "$hook" "git push" "$r" Bash "$FX_REPO" 'git push' deny-ask
    fx_deny "$hook" "git clone of an https URL" "$r" Bash "$FX_REPO" 'git clone https://example.test/r.git d' deny-ask
    fx_deny "$hook" "git clone of a user@host:path source" "$r" Bash "$FX_REPO" 'git clone git@example.test:r.git d' deny-ask
    fx_deny "$hook" "git clone of a host:path source with no user" "$r" Bash "$FX_REPO" 'git clone example.test:r.git d' deny-ask
    # Every global option before the subcommand is skipped, a separate
    # argument after --git-dir, --work-tree, -C, or -c included.
    fx_deny "$hook" "git -P push" "$r" Bash "$FX_REPO" 'git -P push' deny-ask
    fx_deny "$hook" "git --git-dir .git fetch, the space form" "$r" Bash "$FX_REPO" 'git --git-dir .git fetch' deny-ask
    fx_deny "$hook" "git --no-optional-locks fetch" "$r" Bash "$FX_REPO" 'git --no-optional-locks fetch' deny-ask
    fx "$hook" "git --git-dir .git status" allow 1 "$r" Bash "$FX_REPO" 'git --git-dir .git status'
    # The other remote subcommands, the option skips the hook names, a
    # clone with an option before its URL, and gh after a wrapper.
    fx_deny "$hook" "git pull" "$r" Bash "$FX_REPO" 'git pull' deny-ask
    fx_deny "$hook" "git ls-remote origin" "$r" Bash "$FX_REPO" 'git ls-remote origin' deny-ask
    fx_deny "$hook" "git remote update" "$r" Bash "$FX_REPO" 'git remote update' deny-ask
    fx_deny "$hook" "git -c x.y=z push" "$r" Bash "$FX_REPO" 'git -c x.y=z push' deny-ask
    fx_deny "$hook" "git --no-pager fetch" "$r" Bash "$FX_REPO" 'git --no-pager fetch' deny-ask
    fx_deny "$hook" "git --git-dir=.git fetch" "$r" Bash "$FX_REPO" 'git --git-dir=.git fetch' deny-ask
    fx_deny "$hook" "git clone --depth 1 of an https URL" "$r" Bash "$FX_REPO" 'git clone --depth 1 https://example.test/r.git d' deny-ask
    fx_deny "$hook" "sudo gh issue view" "$r" Bash "$FX_REPO" 'sudo gh issue view 1' deny-ask
    fx "$hook" "type gh" allow 1 "$r" Bash "$FX_REPO" 'type gh'
    fx "$hook" "git clone of a local path" allow 1 "$r" Bash "$FX_REPO" 'git clone /local/repo d'
    fx "$hook" "git status" allow 1 "$r" Bash "$FX_REPO" 'git status'
    fx "$hook" "grep gh f, gh as an argument" allow 1 "$r" Bash "$FX_REPO" 'grep gh f'
    fx "$hook" "command -v gh" allow 1 "$r" Bash "$FX_REPO" 'command -v gh'
    fx "$hook" "which gh" allow 1 "$r" Bash "$FX_REPO" 'which gh'

    # Check (f): with two suite prefixes listed, a listed command at a
    # command position is denied with the wrapper's line as the route; the
    # wrapper's own line, quoted mentions, other subcommands, a longer word,
    # and a heredoc body are allowed. The variables are cleared again after,
    # so the fixtures below run with them empty, as those above do.
    SUITE_CMDS='dotnet test|pnpm test'; SUITE_WRAPPER=$FX_SUITE_WRAPPER
    fx_deny "$hook" "dotnet test" "$r" Bash "$FX_REPO" 'dotnet test' deny-suite
    fx_deny "$hook" "dotnet test --filter X" "$r" Bash "$FX_REPO" 'dotnet test --filter X' deny-suite
    fx_deny "$hook" "cd a && dotnet test" "$r" Bash "$FX_REPO" 'cd a && dotnet test' deny-suite
    fx_deny "$hook" "sudo dotnet test" "$r" Bash "$FX_REPO" 'sudo dotnet test' deny-suite
    fx_deny "$hook" "time pnpm test" "$r" Bash "$FX_REPO" 'time pnpm test' deny-suite
    fx_deny "$hook" "echo x; pnpm test" "$r" Bash "$FX_REPO" 'echo x; pnpm test' deny-suite
    fx_deny "$hook" "\$(dotnet test)" "$r" Bash "$FX_REPO" '$(dotnet test)' deny-suite
    fx_deny "$hook" "/usr/local/share/dotnet/dotnet test" "$r" Bash "$FX_REPO" '/usr/local/share/dotnet/dotnet test' deny-suite
    fx "$hook" "the suite wrapper's line" allow 1 "$r" Bash "$FX_REPO" 'bash /w/suite-slots.sh run -- dotnet test'
    fx "$hook" "echo \"dotnet test\"" allow 1 "$r" Bash "$FX_REPO" 'echo "dotnet test"'
    fx "$hook" "grep 'dotnet test' f" allow 1 "$r" Bash "$FX_REPO" "grep 'dotnet test' f"
    fx "$hook" "dotnet build" allow 1 "$r" Bash "$FX_REPO" 'dotnet build'
    fx "$hook" "dotnet testx" allow 1 "$r" Bash "$FX_REPO" 'dotnet testx'
    fx "$hook" "pnpm install" allow 1 "$r" Bash "$FX_REPO" 'pnpm install'
    fx "$hook" "dotnet test in a heredoc body" allow 1 "$r" Bash "$FX_REPO" $'cat <<EOF > notes.txt\ndotnet test\nEOF'
    fx "$hook" "dotnet test with the marker unset" inert - "$r" Bash "$FX_REPO" 'dotnet test'
    SUITE_CMDS=""
    fx "$hook" "dotnet test with the commands variable empty" inert 1 "$r" Bash "$FX_REPO" 'dotnet test'
    # Prefixes whose first word holds a path, follows an assignment, or
    # follows a wrapper match by the first word's base name, the assignment
    # and the wrapper skipped as in a command.
    SUITE_CMDS='./gradlew test|scripts/test.sh|CI=1 pnpm e2e|sudo -u ci make check'
    fx_deny "$hook" "./gradlew test listed, run as written" "$r" Bash "$FX_REPO" './gradlew test' deny-suite
    fx_deny "$hook" "./gradlew test listed, run as gradlew test" "$r" Bash "$FX_REPO" 'gradlew test' deny-suite
    fx_deny "$hook" "scripts/test.sh listed, run as ./scripts/test.sh" "$r" Bash "$FX_REPO" './scripts/test.sh' deny-suite
    fx_deny "$hook" "CI=1 pnpm e2e listed, run as written" "$r" Bash "$FX_REPO" 'CI=1 pnpm e2e' deny-suite
    fx_deny "$hook" "CI=1 pnpm e2e listed, run as pnpm e2e" "$r" Bash "$FX_REPO" 'pnpm e2e' deny-suite
    fx_deny "$hook" "sudo -u ci make check listed, run as make check" "$r" Bash "$FX_REPO" 'make check' deny-suite
    fx "$hook" "./gradlew test listed, gradlew build" allow 1 "$r" Bash "$FX_REPO" './gradlew build'
    # With the wrapper variable empty, the reason says so in its route.
    SUITE_CMDS='dotnet test'; SUITE_WRAPPER=""
    fx_deny "$hook" "dotnet test with the wrapper variable empty" "$r" Bash "$FX_REPO" 'dotnet test' deny-suite
    SUITE_CMDS=""

    # Quoted mentions and rm without a recursive flag, allowed.
    fx "$hook" "quoted mention grep -c 'rm -rf'" allow 1 "$r" Bash "$FX_REPO" "grep -c 'rm -rf' notes.md"
    fx "$hook" "quoted mention git commit -m" allow 1 "$r" Bash "$FX_REPO" 'git commit -m "… rm -rf …"'
    fx "$hook" "quoted mention echo \"rm -r\"" allow 1 "$r" Bash "$FX_REPO" 'echo "rm -r"'
    fx "$hook" "quoted mention in a heredoc commit message" allow 1 "$r" Bash "$FX_REPO" \
        $'git commit -m "$(cat <<\'EOF\'\ndocs: note\n\nrm -rf is denied now\nEOF\n)"'
    # A separator inside the quotes, before rm -rf: a hook that read the
    # quotes as ordinary characters would split there and deny.
    fx "$hook" "quoted separator: echo 'a && rm -rf b'" allow 1 "$r" Bash "$FX_REPO" "echo 'a && rm -rf b'"
    fx "$hook" "quoted separator: echo 'a; rm -rf b'" allow 1 "$r" Bash "$FX_REPO" "echo 'a; rm -rf b'"
    fx "$hook" "quoted separator: echo \"a | rm -rf b\"" allow 1 "$r" Bash "$FX_REPO" 'echo "a | rm -rf b"'
    fx "$hook" "quoted separator: git commit -m \"…; rm -rf …\"" allow 1 "$r" Bash "$FX_REPO" 'git commit -m "docs: note; rm -rf is denied now"'
    fx "$hook" "rm -rf in a comment" allow 1 "$r" Bash "$FX_REPO" 'ls # a; rm -rf b'
    # An escaped quote inside $'...' does not end it, so the quoted
    # mention after it stays an argument.
    fx "$hook" "quoted mention after an ANSI-C quote holding an escaped quote" allow 1 "$r" Bash "$FX_REPO" \
        "printf \$'it\\'s\\n'; git commit -m 'x; rm -rf y'"
    fx "$hook" "rm without a recursive flag: rm file" allow 1 "$r" Bash "$FX_REPO" 'rm notes.md'
    fx "$hook" "rm without a recursive flag: rm -f file" allow 1 "$r" Bash "$FX_REPO" 'rm -f notes.md'
    fx "$hook" "rm without a recursive flag: rm -f with a \$( ) in its argument" allow 1 "$r" Bash "$FX_REPO" 'rm -f "$(pwd)/x"'
    # A | past a line continuation that follows no < or > ends the rm's
    # command, so the -r of the grep after it is not the rm's.
    fx "$hook" "rm without a recursive flag: rm -f, then a | past a line continuation and grep -r" allow 1 "$r" Bash "$FX_REPO" $'rm -f notes.md\\\n| grep -r x'
    # Work the hook must not deny: a long option that is no prefix of
    # --recursive, a -r after -- (a file named -r), and a <<- heredoc
    # whose tab-indented body mentions rm -rf.
    fx "$hook" "rm without a recursive flag: rm --force file" allow 1 "$r" Bash "$FX_REPO" 'rm --force notes.md'
    fx "$hook" "rm without a recursive flag: rm -- -r" allow 1 "$r" Bash "$FX_REPO" 'rm -- -r'
    fx "$hook" "a <<- heredoc body with tabs stripped" allow 1 "$r" Bash "$FX_REPO" $'cat <<-EOF > notes.txt\n\trm -rf build\n\tEOF'

    for t in Write Edit NotebookEdit; do
        # A write inside each root, allowed.
        fx "$hook" "$t inside the repository" allow 1 "$r" "$t" "$FX_REPO" "$FX_REPO/src/a.txt"
        fx "$hook" "$t inside the workspace" allow 1 "$r" "$t" "$FX_REPO" "$FX_WS/_prompts/a.txt"
        fx "$hook" "$t inside \$TMPDIR" allow 1 "$r" "$t" "$FX_REPO" "${FX_TMP%/}/kenspc-rails-fixture/a.txt"
        fx "$hook" "$t inside /tmp" allow 1 "$r" "$t" "$FX_REPO" "/tmp/kenspc-rails-fixture/a.txt"
        fx "$hook" "$t inside /private/tmp" allow 1 "$r" "$t" "$FX_REPO" "/private/tmp/kenspc-rails-fixture/a.txt"
        # A write outside every root, denied.
        fx_deny "$hook" "$t outside every root" "$r" "$t" "$FX_REPO" "$FX_BASE/outside/a.txt"
        # A relative path, resolved against the cwd.
        fx "$hook" "$t relative inside" allow 1 "$r" "$t" "$FX_REPO/sub" "../docs/a.md"
        fx_deny "$hook" "$t relative .. escape" "$r" "$t" "$FX_REPO/sub" "../../../escape.txt"
        # A sibling that shares a root's prefix, denied.
        fx_deny "$hook" "$t sibling sharing a root's prefix" "$r" "$t" "$FX_REPO" "$FX_REPO-other/a.txt"
        # A target the hook cannot read, denied even inside a root, with no
        # route offered.
        fx_deny "$hook" "$t with no readable path field" "$r" "$t/no-key" "$FX_REPO" "$FX_REPO/src/a.txt" deny-unreadable
    done

    # Symlinked roots: /tmp against the driver's roots, which name it and its
    # macOS target; then a link the guard made, named as the only root with
    # the write under its target, and the other way round.
    fx "$hook" "symlinked root /tmp/ in the driver's roots" allow 1 "$r" Write "$FX_REPO" "/tmp/kenspc-rails-fixture/link-check.txt"
    # Where /tmp is a link (on macOS, to /private/tmp), each name alone as
    # the root holds a target written under the other: the driver's roots
    # name both, so only these show the link resolved.
    if [[ -L /tmp ]]; then
        t=$(cd /tmp && pwd -P)
        fx "$hook" "symlinked root /tmp alone, target under its link target" allow 1 "/tmp" Write "$FX_REPO" "$t/kenspc-rails-fixture/a.txt"
        fx "$hook" "symlinked root: /tmp's link target alone, target under /tmp" allow 1 "$t" Write "$FX_REPO" "/tmp/kenspc-rails-fixture/a.txt"
    fi
    fx "$hook" "symlinked root: the link as root, target under the real directory" allow 1 "$WORK/link" Write "$FX_REPO" "$WORK/real/a.txt"
    fx "$hook" "symlinked root: the real directory as root, target through the link" allow 1 "$WORK/real" Write "$FX_REPO" "$WORK/link/a.txt"
    fx_deny "$hook" "symlinked root: a sibling of the link's target" "$WORK/link" Write "$FX_REPO" "$WORK/other/a.txt"
    # A .. after a link is collapsed as written, as Claude Code collapses it
    # before the write: deep/../.. leaves real/, while the link's target
    # a/b/../.. would stay inside it.
    fx_deny "$hook" "a .. after a link collapsed as written" "$WORK/real" Write "$FX_REPO" "$WORK/real/deep/../../a.txt"

    # A target as Claude Code reads it: a leading ~ or ~/ is $HOME, and
    # surrounding whitespace is trimmed, rather than a path relative to the
    # cwd, which lies inside the repository.
    fx_deny "$hook" "a ~/ target outside the roots" "$r" Write "$FX_REPO" "~/.zshrc"
    fx "$hook" "a ~/ target inside a root" allow 1 "$FX_HOME" Write "$FX_REPO" "~/notes/a.txt"
    fx_deny "$hook" "a ~ target outside the roots" "$r" Edit "$FX_REPO" "~"
    fx_deny "$hook" "a target with a leading space" "$r" Write "$FX_REPO" " $FX_BASE/outside/a.txt"

    # A path that is not POSIX absolute even after the join, such as a
    # Windows drive-letter path, is not judged: the hook cannot resolve it.
    fx "$hook" "a Windows drive-letter target, not judged" allow 1 "$r" Write 'C:\repo' 'C:\repo\a.txt'

    # The marker set and no roots: every file-tool write is outside them.
    fx_deny "$hook" "no roots with the marker set" "" Write "$FX_REPO" "$FX_REPO/src/a.txt"
    # A root entry that is not absolute is skipped: an empty entry or .
    # would otherwise resolve to / and hold every target.
    fx_deny "$hook" "an empty root entry skipped" "|$FX_REPO" Write "$FX_REPO" "$FX_BASE/outside/a.txt"
    fx_deny "$hook" "a . root entry skipped" ".|$FX_REPO" Write "$FX_REPO" "$FX_BASE/outside/a.txt"

    # A field the hook cannot read — the tool's name, or a Bash command —
    # denies the call rather than passing it unchecked, and its reason
    # offers no route: a retry is read the same way.
    fx_deny "$hook" "Bash with no readable command field" "$r" Bash/no-key "$FX_REPO" 'rm -rf build' deny-unreadable
    fx_deny "$hook" "Bash with no readable tool_name" "$r" Bash/no-tool-name "$FX_REPO" 'ls' deny-unreadable
    fx_deny "$hook" "Write with no readable tool_name" "$r" Write/no-tool-name "$FX_REPO" "$FX_REPO/src/a.txt" deny-unreadable

    # Every denied fixture again without the marker, and with the marker 0,
    # each with the suite variables it was denied with, so the marker is
    # seen to gate check (f) too.
    k=0
    while [[ "$k" -lt "${#D_LABEL[@]}" ]]; do
        SUITE_CMDS=${D_SCMDS[$k]}; SUITE_WRAPPER=${D_SWRAP[$k]}
        fx "$hook" "${D_LABEL[$k]} (marker unset)" inert - "${D_ROOTS[$k]}" "${D_TOOL[$k]}" "${D_CWD[$k]}" "${D_PAYLOAD[$k]}"
        fx "$hook" "${D_LABEL[$k]} (marker 0)" inert 0 "${D_ROOTS[$k]}" "${D_TOOL[$k]}" "${D_CWD[$k]}" "${D_PAYLOAD[$k]}"
        k=$((k + 1))
    done
    SUITE_CMDS=""; SUITE_WRAPPER=""

    [[ "$FAILS" -eq 0 ]]
}

# check_registration <hooks.json>: the entry that runs the hook sits under
# PreToolUse, with a matcher naming Bash, Write, Edit, and NotebookEdit.
# Why: the fixtures run the script directly, so a matcher that dropped a
# tool would leave that tool's calls unchecked with every fixture green.
# It reads the event key and the matcher line that come last before the
# line naming the script, as hooks.json lays them out; a layout it cannot
# read fails the check rather than passing it.
check_registration() {
    local json="$1" event matcher tool
    event=$(awk '/"[A-Z][A-Za-z]*"[[:space:]]*:[[:space:]]*\[/ { e = $0 } /autopilot-worker-rails\.sh/ { print e; exit }' "$json")
    matcher=$(awk '/"matcher"[[:space:]]*:/ { m = $0 } /autopilot-worker-rails\.sh/ { print m; exit }' "$json" \
        | sed -n 's/.*"matcher"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
    case "$event" in
        *'"PreToolUse"'*) ;;
        *) echo "FAIL  $HOOKS_JSON_REL does not register the rails hook under PreToolUse" >&2; return 1 ;;
    esac
    for tool in Bash Write Edit NotebookEdit; do
        case "|$matcher|" in
            *"|$tool|"*) ;;
            *) echo "FAIL  $HOOKS_JSON_REL: the rails hook's matcher \"$matcher\" does not name $tool" >&2; return 1 ;;
        esac
    done
}

# check_heading <hook> <skill>: the heading `## Rail observations` in the
# hook's REASON_UNREADABLE= assignment, in the preamble template of the
# skill (the fenced block under `### The preamble`), and in its
# `### Launch, wait, return` section; the phrase an unreadable-field reason
# carries in the hook, in that section, and in the skill's
# `### The stop conditions` section. Returns 1 with each missing literal
# reported per carrier, 2 when a file, the assignment, the template, or a
# section cannot be found.
check_heading() {
    local hook="$1" skill="$2" reason preamble launch stops bad=0
    if [[ ! -f "$skill" ]]; then
        echo "ERROR: missing $skill" >&2
        return 2
    fi
    reason=$(grep -E '^REASON_UNREADABLE=' "$hook" || true)
    if [[ -z "$reason" ]]; then
        echo "ERROR: no REASON_UNREADABLE= assignment in $hook" >&2
        return 2
    fi
    preamble=$(awk '
        { sub(/\r$/, "") }
        /^### The preamble[ \t]*$/ { sec = 1; next }
        sec && /^### / { exit }
        sec && $0 == "````" { if (fence) { done = 1; exit } fence = 1; next }
        sec && fence { print }
        END { if (!done) exit 3 }' "$skill") || {
        echo "ERROR: no fenced template under ### The preamble in $skill" >&2
        return 2
    }
    launch=$(awk '
        { sub(/\r$/, "") }
        /^### Launch, wait, return[ \t]*$/ { sec = 1; found = 1; next }
        sec && /^### / { exit }
        sec { print }
        END { if (!found) exit 3 }' "$skill") || {
        echo "ERROR: no ### Launch, wait, return section in $skill" >&2
        return 2
    }
    stops=$(awk '
        { sub(/\r$/, "") }
        /^### The stop conditions[ \t]*$/ { sec = 1; found = 1; next }
        sec && /^##+ / { exit }
        sec { print }
        END { if (!found) exit 3 }' "$skill") || {
        echo "ERROR: no ### The stop conditions section in $skill" >&2
        return 2
    }
    case "$reason" in
        *"$HEADING"*) ;;
        *) echo "MISSING '$HEADING' in the hook's unreadable-field reason (REASON_UNREADABLE= in $hook)" >&2; bad=1 ;;
    esac
    case "$preamble" in
        *"$HEADING"*) ;;
        *) echo "MISSING '$HEADING' in the preamble template (the fenced block under ### The preamble in $skill)" >&2; bad=1 ;;
    esac
    case "$launch" in
        *"$HEADING"*) ;;
        *) echo "MISSING '$HEADING' in ### Launch, wait, return of $skill" >&2; bad=1 ;;
    esac
    if ! grep -qF -- "$PHRASE" "$hook"; then
        echo "MISSING '$PHRASE' in the rails hook $hook" >&2
        bad=1
    fi
    case "$launch" in
        *"$PHRASE"*) ;;
        *) echo "MISSING '$PHRASE' in ### Launch, wait, return of $skill" >&2; bad=1 ;;
    esac
    case "$stops" in
        *"$PHRASE"*) ;;
        *) echo "MISSING '$PHRASE' in ### The stop conditions of $skill" >&2; bad=1 ;;
    esac
    if [[ "$bad" -ne 0 ]]; then
        echo "The hook tells a worker to list an unreadable-field denial under $HEADING, the" >&2
        echo "preamble keeps that section in every worker's final message, and the main" >&2
        echo "session reads it at the return and stops on '$PHRASE'. Restore the" >&2
        echo "literal, or rename it in every carrier and in this guard together." >&2
        return 1
    fi
    return 0
}

run_main_logic() {
    local hook="$REPO_ROOT/$HOOK_REL" json="$REPO_ROOT/$HOOKS_JSON_REL"
    if [[ ! -f "$hook" ]]; then
        echo "ERROR: missing hook $hook" >&2
        return 2
    fi
    if [[ ! -f "$json" ]]; then
        echo "ERROR: missing $json" >&2
        return 2
    fi
    check_registration "$json" || return 1
    echo "OK    autopilot rails hook — registered on PreToolUse for Bash, Write, Edit, and NotebookEdit"
    check_heading "$hook" "$REPO_ROOT/$SKILL_REL" || return $?
    echo "OK    autopilot rails hook — '$HEADING' in the unreadable-field reason, the preamble template, and § Launch, wait, return; '$PHRASE' in the hook, § Launch, wait, return, and § The stop conditions"
    make_work
    if run_fixtures "$hook"; then
        echo "OK    autopilot rails hook — every fixture decided as expected (${#D_LABEL[@]} denied fixtures, each also inert without the marker and with it 0; the timed commands in ${TIMED})"
        return 0
    fi
    echo "" >&2
    echo "$FAILS fixture(s) of $HOOK_REL decided otherwise. Fix the hook, or, when" >&2
    echo "Claude Code's hook input changed, rebuild the fixtures from a live input." >&2
    return 1
}

# --- Self-test mode ---------------------------------------------------------

# replace_literal <file> <old> <new>: replaces the one occurrence of <old>;
# status 2 when <old> is not found exactly once. The strings travel through
# the environment, so awk applies no escape processing to them.
replace_literal() {
    local file="$1" hits
    hits=$(OLD="$2" awk 'BEGIN { old = ENVIRON["OLD"] } { s = $0; while ((i = index(s, old)) > 0) { n++; s = substr(s, i + length(old)) } } END { print n + 0 }' "$file")
    if [[ "$hits" -ne 1 ]]; then
        echo "FAIL  self-test fixture stale: \"$2\" found $hits times in the hook copy, expected 1" >&2
        return 2
    fi
    OLD="$2" NEW="$3" awk '
        BEGIN { old = ENVIRON["OLD"]; new = ENVIRON["NEW"] }
        !done && (i = index($0, old)) { $0 = substr($0, 1, i - 1) new substr($0, i + length(old)); done = 1 }
        { print }
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
}

# mutate_region <file> <start> <stop> <old> <new>: replaces every <old> on
# the lines from the first that begins with <start> up to, not including,
# the next line that begins with <stop> — the start line alone when <stop>
# is empty, the whole file when <start> is empty. Status 2 when nothing was
# replaced. The strings travel through the environment, as in
# replace_literal.
mutate_region() {
    local file="$1" rc
    START="$2" STOP="$3" OLD="$4" NEW="$5" awk '
        BEGIN {
            st = ENVIRON["START"]; sp = ENVIRON["STOP"]
            old = ENVIRON["OLD"]; new = ENVIRON["NEW"]
            state = (st == "") ? 1 : 0
        }
        {
            if (state == 0 && index($0, st) == 1) state = 1
            else if (state == 1 && st != "" && (sp == "" || index($0, sp) == 1)) state = 2
            if (state == 1) {
                out = ""; rest = $0
                while ((i = index(rest, old)) > 0) {
                    out = out substr(rest, 1, i - 1) new
                    rest = substr(rest, i + length(old)); n++
                }
                $0 = out rest
            }
            print
        }
        END { if (!n) exit 3 }
    ' "$file" > "$file.tmp" && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        rm -f "$file.tmp"
        echo "FAIL  self-test fixture stale: \"$4\" not found in the region of $file that begins with \"$2\"" >&2
        return 2
    fi
    mv "$file.tmp" "$file"
}

run_self_test() {
    local hook="$REPO_ROOT/$HOOK_REL" copy name old new rc want
    if [[ ! -f "$hook" ]]; then
        echo "ERROR: missing hook $hook" >&2
        return 2
    fi
    make_work
    mkdir "$WORK/hook"
    copy="$WORK/hook/rails.sh"
    QUIET=1

    cp "$hook" "$copy"
    if ! run_fixtures "$copy"; then
        echo "FAIL  self-test positive path: the unmodified copy failed $FAILS fixture(s), first: $FIRST_RED" >&2
        return 1
    fi

    # Ten mutants, each a literal replacement in a fresh copy. The
    # constant-time push mutant copies every word collected so far on each
    # push, the last-character check mutant matches the whole word
    # against [<>]$ on each | or &, as the hook once did, and the
    # command-reason-phrase mutant rewords the phrase in one of the three
    # unreadable-field reasons, which only the fixture assertion catches.
    for name in rm-detection root-check marker-check constant-time-push last-character-check command-reason-phrase redirection-check gh-check suite-check cd-tracking; do
        case "$name" in
            rm-detection)
                old='[ -z "$found" ] || deny "a recursive rm'
                new='[ -z "$found" ] || : "a recursive rm' ;;
            root-check)
                old='deny "this $tool call writes outside'
                new=': "this $tool call writes outside' ;;
            marker-check)
                old='[ "${KENSPC_AUTOPILOT_WORKER:-}" = 1 ] || exit 0'
                new=': marker check removed' ;;
            constant-time-push)
                old='function push(ret, cl) {'
                new='function push(ret, cl,   k) { for (k = 1; k <= nw; k++) sw[sp, k] = w[k]' ;;
            last-character-check)
                old='nx == ">" || ltgt == i - 1'
                new='nx == ">" || cur ~ /[<>]$/' ;;
            command-reason-phrase)
                old="the command of this Bash call $PHRASE"
                new='the command of this Bash call was unreadable in the hook input' ;;
            redirection-check)
                old='|| deny "this Bash call redirects output outside'
                new='|| : "this Bash call redirects output outside' ;;
            gh-check)
                old='if (bname(w[i]) == "gh")'
                new='if (0 && bname(w[i]) == "gh")' ;;
            suite-check)
                old='if (nsuite > 0 && suite(i)) return'
                new='if (0 && nsuite > 0 && suite(i)) return' ;;
            cd-tracking)
                old='if (t !~ /^\//) { if (wdir !~ /^\//) return; t = wdir "/" t }'
                new='if (t !~ /^\//) { if (cwd !~ /^\//) return; t = cwd "/" t }' ;;
        esac
        cp "$hook" "$copy"
        replace_literal "$copy" "$old" "$new" && rc=0 || rc=$?
        if [[ "$rc" -ne 0 ]]; then
            return 2
        fi
        if run_fixtures "$copy"; then
            echo "FAIL  self-test: the mutant with the $name removed passed every fixture" >&2
            return 1
        fi
        # Only the timed $( ) fixture measures the cost the push mutant
        # restores; that mutant red first elsewhere (its text broke the awk
        # program, say) proves nothing about it. The last-character mutant
        # may turn any fixture red: see the comment beside the timed <|
        # fixture.
        case "$name" in
            constant-time-push) want=$SUBST_TIMED_LABEL ;;
            command-reason-phrase) want="Bash with no readable command field" ;;
            gh-check) want="gh issue view" ;;
            suite-check) want="dotnet test" ;;
            *) want="" ;;
        esac
        if [[ -n "$want" && "$FIRST_RED" != "$want" ]]; then
            echo "FAIL  self-test: the mutant with the $name removed turned another fixture red first: $FIRST_RED" >&2
            return 1
        fi
        # The file-wide heading check still finds the phrase in the other two
        # reasons, so the fixture assertion is what caught this mutant.
        if [[ "$name" == command-reason-phrase ]] \
            && ! check_heading "$copy" "$REPO_ROOT/$SKILL_REL" 2> "$WORK/stderr.txt"; then
            echo "FAIL  self-test: the heading check turned red on the $name mutant, so it does not show the fixture assertion caught it" >&2
            cat "$WORK/stderr.txt" >&2
            return 1
        fi
        # The cd-tracking mutant reads every target from the input's cwd,
        # so each cd fixture whose outcome that reading changes is red.
        if [[ "$name" == cd-tracking ]]; then
            for want in "$CD_ABS_LABEL" "$CD_REL_LABEL" "$CD_ROOT_LABEL" "${CD_UNKNOWN_LABELS[@]}"; do
                if ! printf '%s' "$RED_LABELS" | grep -qxF -- "$want"; then
                    echo "FAIL  self-test: the mutant with the $name removed left the fixture '$want' green" >&2
                    return 1
                fi
            done
        fi
        echo "OK    self-test mutant '$name removed' turned $FAILS fixture(s) red, first: $FIRST_RED"
    done

    cp "$hook" "$copy"
    if ! run_fixtures "$copy"; then
        echo "FAIL  self-test restoration path: the restored copy failed $FAILS fixture(s), first: $FIRST_RED" >&2
        return 1
    fi

    # The heading check: SKILL.md copied beside the hook copy, the two
    # unmodified copies passing, then one mutant per carrier, each of which
    # must turn the check red with its carrier named, then the restored
    # copies passing again.
    local skill="$REPO_ROOT/$SKILL_REL" skill_copy="$WORK/hook/SKILL.md"
    local target start stop carrier
    if [[ ! -f "$skill" ]]; then
        echo "ERROR: missing $skill" >&2
        return 2
    fi
    cp "$skill" "$skill_copy"
    check_heading "$copy" "$skill_copy" 2> "$WORK/stderr.txt" && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test heading check positive path: expected exit 0 on the unmodified copies, got $rc" >&2
        cat "$WORK/stderr.txt" >&2
        return 1
    fi
    for name in heading-in-reason heading-in-preamble heading-in-return phrase-in-hook phrase-in-return phrase-in-stops; do
        case "$name" in
            heading-in-reason)
                target=$copy; start='REASON_UNREADABLE='; stop=''
                old=$HEADING; new='## Rail notes'
                carrier="the hook's unreadable-field reason" ;;
            heading-in-preamble)
                target=$skill_copy; start='### The preamble'; stop='### '
                old=$HEADING; new='## Rail notes'
                carrier="the preamble template" ;;
            heading-in-return)
                target=$skill_copy; start='### Launch, wait, return'; stop='### '
                old=$HEADING; new='## Rail notes'
                carrier="### Launch, wait, return" ;;
            phrase-in-hook)
                target=$copy; start=''; stop=''
                old=$PHRASE; new='was unreadable in the hook input'
                # Not "the hook", which the phrase itself contains.
                carrier="the rails hook" ;;
            phrase-in-return)
                target=$skill_copy; start='### Launch, wait, return'; stop='### '
                old=$PHRASE; new='was unreadable in the hook input'
                carrier="### Launch, wait, return" ;;
            phrase-in-stops)
                target=$skill_copy; start='### The stop conditions'; stop='### '
                old=$PHRASE; new='was unreadable in the hook input'
                carrier="### The stop conditions" ;;
        esac
        cp "$hook" "$copy"
        cp "$skill" "$skill_copy"
        mutate_region "$target" "$start" "$stop" "$old" "$new" || return 2
        check_heading "$copy" "$skill_copy" 2> "$WORK/stderr.txt" && rc=0 || rc=$?
        if [[ "$rc" -ne 1 ]]; then
            echo "FAIL  self-test: the heading mutant '$name' gave exit $rc, expected 1" >&2
            return 1
        fi
        if ! grep -F -- "MISSING" "$WORK/stderr.txt" | grep -qF -- "$carrier"; then
            echo "FAIL  self-test: the heading mutant '$name' did not name $carrier" >&2
            cat "$WORK/stderr.txt" >&2
            return 1
        fi
        echo "OK    self-test heading mutant '$name' turned the heading check red, naming $carrier"
    done
    cp "$hook" "$copy"
    cp "$skill" "$skill_copy"
    check_heading "$copy" "$skill_copy" 2> "$WORK/stderr.txt" && rc=0 || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        echo "FAIL  self-test heading check restoration path: expected exit 0 on the restored copies, got $rc" >&2
        return 1
    fi

    echo "OK    self-test passed for $(basename "$0")"
    return 0
}

# --- Dispatch ---------------------------------------------------------------

if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit $?
fi

run_main_logic
exit $?
