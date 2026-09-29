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
#          route applies and asks for the denial to be reported
#   allow  exit 0, empty stdout
#   inert  exit 0, empty stdout, empty stderr (the marker is not 1)
#
# The fixtures cover every recursive rm spelling and command position the
# hook lists (denied), words quoted as $'...' or $"...", backslash escapes,
# substitutions inside double quotes, a | or & after a quoted or escaped <
# or >, and substitutions and redirections among the rm's own words among
# them; quoted mentions of
# rm -rf and an rm -rf in a comment (allowed); rm without a recursive flag
# and other work the hook must not deny — rm --force, rm -- -r, a <<- body
# with its tabs stripped (allowed); an rm after a heredoc whose delimiter
# line comes, and after a << whose delimiter line never does (denied); a
# write inside each root — the repository, the
# workspace, $TMPDIR, /tmp, /private/tmp — for Write, Edit, and NotebookEdit
# (allowed); a write outside every root (denied); a relative path resolved
# against the cwd (allowed inside, denied when a .. escapes); symlinked
# roots, and a .. after a link collapsed as written (denied); a target
# beginning with ~, ~/, or a space, read as Claude Code reads it, with HOME
# set to a fixture path; a Windows drive-letter path, not judged (allowed);
# a sibling that shares a root's prefix (denied); no roots with the marker
# set, and root entries that are not absolute (denied); an input whose tool
# name, Bash command, or file-tool path the hook cannot read (denied, with
# no route offered and the denial to be reported); a
# Bash input over the hook's length cap
# (denied) and one under it (allowed); a command of many $( )
# substitutions under the cap, then rm -rf, a long command word with no
# slash, then rm -rf, and a word of many <| pairs, then rm -rf, each denied
# in under half the hook's 5-second timeout (timed); and every denied fixture again
# without the marker and with the marker 0 (inert). Why the fixtures carry
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
# Exit code 0: the registration holds and every fixture decided as expected.
# Exit code 1: the registration or a decision differs (each one is reported).
# Exit code 2: missing hook file or hooks.json, or self-test fixture stale.
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
#                  unmodified copy (must pass), then against five mutants,
#                  each of which must turn at least one fixture red, named in
#                  the output: the rm detection removed, the root check
#                  removed, the marker check removed, the constant-time push
#                  removed (the timed $( ) fixture, which must be the first
#                  red), the last-character check removed (the timed <|
#                  fixture, which must be the first red). Then the restored copy
#                  must pass again. A mutation whose target text is not
#                  found exactly once is exit 2 (stale fixture), never a pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_REL="plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh"
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

WORK=""
cleanup() {
    [[ -n "${WORK:-}" && -d "$WORK" ]] || return 0
    rm -f "$WORK/input.json" "$WORK/stderr.txt" "$WORK/time.txt" "$WORK/link" "$WORK/real/deep" "$WORK/hook/rails.sh" "$WORK/hook/rails.sh.tmp"
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
# hook, sets RC, OUT, ERR, and GOT (deny, allow, inert, or other). The input
# goes through a file, not a pipe: the inert hook exits without reading it,
# and a pipe's writer would then fail and make the status its own. With
# <cpu seconds>, the hook and its awk run under that CPU limit where the
# system lets the guard set one.
decide() {
    local hook="$1" marker="$2" roots="$3" cpu="${5:-}"
    printf '%s' "$4" > "$WORK/input.json"
    RC=0
    OUT=$(
        unset KENSPC_AUTOPILOT_WORKER KENSPC_AUTOPILOT_WRITE_ROOTS
        export HOME="$FX_HOME"
        if [[ "$marker" != "-" ]]; then export KENSPC_AUTOPILOT_WORKER="$marker"; fi
        export KENSPC_AUTOPILOT_WRITE_ROOTS="$roots"
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
QUIET=0
TIMED=""
SUBST_TIMED_LABEL="a command of 12000 \$( ) substitutions under the length cap, then rm -rf, decided in time"
LTGT_TIMED_LABEL="a word of 32000 <| pairs under the length cap, then rm -rf, decided in time"
# What an unreadable-field denial says in place of the permitted route. Why:
# the hook reads every later call the same way, so a worker sent down the
# route would retry until its cap; the autopilot preamble tells it to list
# the denial and end instead.
UNREADABLE_NO_ROUTE="No permitted route applies"
UNREADABLE_REPORT="list this denial with its reason under ## Rail observations and end"
D_LABEL=(); D_TOOL=(); D_CWD=(); D_PAYLOAD=(); D_ROOTS=()

# fx <hook> <label> <expect> <marker or -> <roots> <tool> <cwd> <payload>
# <expect> deny-unreadable is a deny whose reason offers no route and asks
# for the denial to be reported, as a field the hook cannot read gets.
fx() {
    local hook="$1" label="$2" expect="$3" marker="$4" roots="$5" tool="$6" cwd="$7" payload="$8" ok=0 want="$3"
    if [[ "$expect" == deny-unreadable ]]; then want=deny; fi
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
    if [[ "$expect" == deny-unreadable && "$ok" -eq 1 ]] \
        && [[ "$ERR" != *"$UNREADABLE_NO_ROUTE"* || "$ERR" != *"$UNREADABLE_REPORT"* || "$ERR" == *.trash* ]]; then
        ok=0
        GOT="deny whose reason does not say '$UNREADABLE_NO_ROUTE' and '$UNREADABLE_REPORT', or names .trash"
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
}

# fx_timed <hook> <label> <limit> <payload>: a Bash command whose recursive
# rm is expected denied, with the marker set, in under <limit> seconds of
# wall-clock time; recorded for the replays as fx_deny records. Why a time:
# a hook run that outlasts the hook's 5-second timeout (hooks.json) denies
# nothing, so a slow deny is an allow. The hook runs under a CPU limit of
# that timeout, so a slow scan costs the guard seconds, not the minute it
# would take; a run the limit cuts off is red on its time, and on its reason
# too, since its killed awk makes the hook deny the command as unreadable.
fx_timed() {
    local hook="$1" label="$2" limit="$3" payload="$4" why="" n input secs TIMEFORMAT=%R
    input=$(make_input Bash "$FX_REPO" "$payload")
    { time decide "$hook" 1 "$FX_ROOTS" "$input" 5 ; } 2> "$WORK/time.txt"
    secs=$(cat "$WORK/time.txt")
    TIMED="${TIMED:+$TIMED and }${secs}s"
    if ! awk -v e="$secs" -v l="$limit" 'BEGIN { exit !(e + 0 < l + 0) }'; then
        why="decided in ${secs}s, not under ${limit}s"
    elif [[ "$GOT" != deny || "$ERR" != "autopilot rails: "* || "$ERR" != *"recursive rm"* || "$ERR" != *.trash* ]]; then
        why="expected its recursive rm denied, got $GOT (exit $RC, stdout '$OUT', stderr '$ERR')"
    fi
    if [[ -n "$why" ]]; then
        FAILS=$((FAILS + 1))
        if [[ -z "$FIRST_RED" ]]; then FIRST_RED=$label; fi
        if [[ "$QUIET" -eq 0 ]]; then
            echo "FAIL  $label: $why" >&2
        fi
    fi
    n=${#D_LABEL[@]}
    D_LABEL[$n]=$label; D_ROOTS[$n]=$FX_ROOTS; D_TOOL[$n]=Bash; D_CWD[$n]=$FX_REPO; D_PAYLOAD[$n]=$payload
}

# run_fixtures <hook>: every fixture; returns 1 when any decision differs.
run_fixtures() {
    local hook="$1" r="$FX_ROOTS" t k
    FAILS=0; FIRST_RED=""; TIMED=""
    D_LABEL=(); D_TOOL=(); D_CWD=(); D_PAYLOAD=(); D_ROOTS=()

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
    # whole word on every | or &, which took over 3 seconds.
    t=$(awk 'BEGIN { for (i = 0; i < 32000; i++) printf "<|" }')
    fx_timed "$hook" "$LTGT_TIMED_LABEL" 2.5 "echo $t; rm -rf build"
    # A | or & after a quoted or escaped < or > ends the command: that < or
    # > is no redirection. These come after the timed <| fixture, which the
    # self-test's last-character mutant must turn red first, since that
    # mutant, the whole word matched against [<>]$, misreads them too.
    fx_deny "$hook" "rm position after | following a double-quoted >" "$r" Bash "$FX_REPO" 'echo "a>"|rm -rf build'
    fx_deny "$hook" "rm position after | following a single-quoted <" "$r" Bash "$FX_REPO" "echo 'a<'|rm -rf build"
    fx_deny "$hook" "rm position after | following an escaped >" "$r" Bash "$FX_REPO" 'echo a\>|rm -rf build'
    fx_deny "$hook" "rm position after & following a double-quoted >" "$r" Bash "$FX_REPO" 'echo "->"&rm -rf build'

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

    # Every denied fixture again without the marker, and with the marker 0.
    k=0
    while [[ "$k" -lt "${#D_LABEL[@]}" ]]; do
        fx "$hook" "${D_LABEL[$k]} (marker unset)" inert - "${D_ROOTS[$k]}" "${D_TOOL[$k]}" "${D_CWD[$k]}" "${D_PAYLOAD[$k]}"
        fx "$hook" "${D_LABEL[$k]} (marker 0)" inert 0 "${D_ROOTS[$k]}" "${D_TOOL[$k]}" "${D_CWD[$k]}" "${D_PAYLOAD[$k]}"
        k=$((k + 1))
    done

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

    # Five mutants, each a literal replacement in a fresh copy. The
    # constant-time push mutant copies every word collected so far on each
    # push, and the last-character check mutant matches the whole word
    # against [<>]$ on each | or &, as the hook once did.
    for name in rm-detection root-check marker-check constant-time-push last-character-check; do
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
                old='ltgt == i - 1'
                new='cur ~ /[<>]$/' ;;
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
        # Only a timed fixture measures the cost a timing mutant restores —
        # the $( ) one the push's, the <| one the last-character check's; a
        # mutant red first elsewhere (its text broke the awk program, say)
        # proves nothing about it.
        case "$name" in
            constant-time-push) want=$SUBST_TIMED_LABEL ;;
            last-character-check) want=$LTGT_TIMED_LABEL ;;
            *) want="" ;;
        esac
        if [[ -n "$want" && "$FIRST_RED" != "$want" ]]; then
            echo "FAIL  self-test: the mutant with the $name removed turned another fixture red first: $FIRST_RED" >&2
            return 1
        fi
        echo "OK    self-test mutant '$name removed' turned $FAILS fixture(s) red, first: $FIRST_RED"
    done

    cp "$hook" "$copy"
    if ! run_fixtures "$copy"; then
        echo "FAIL  self-test restoration path: the restored copy failed $FAILS fixture(s), first: $FIRST_RED" >&2
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
