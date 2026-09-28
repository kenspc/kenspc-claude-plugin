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
#   deny   exit 2, empty stdout, a reason on stderr
#   allow  exit 0, empty stdout
#   inert  exit 0, empty stdout, empty stderr (the marker is not 1)
#
# The fixtures cover every recursive rm spelling and command position the
# hook lists (denied); quoted mentions of rm -rf (allowed); rm without a
# recursive flag (allowed); a write inside each root — the repository, the
# workspace, $TMPDIR, /tmp, /private/tmp — for Write, Edit, and NotebookEdit
# (allowed); a write outside every root (denied); a relative path resolved
# against the cwd (allowed inside, denied when a .. escapes); symlinked
# roots, and a .. after a link collapsed as written (denied); a target
# beginning with ~, ~/, or a space, read as Claude Code reads it, with HOME
# set to a fixture path; a sibling that shares a root's prefix (denied); no
# roots with the marker set (denied); a file-tool input whose path field
# the hook cannot read (denied); a Bash input over the hook's length cap
# (denied) and one under it (allowed); and every denied fixture again
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
# Exit code 0: every fixture decided as expected.
# Exit code 1: a decision differs (each one is reported).
# Exit code 2: missing hook file, or self-test fixture stale.
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
#                  unmodified copy (must pass), then against three mutants,
#                  each of which must turn at least one fixture red, named in
#                  the output: the rm detection removed, the root check
#                  removed, the marker check removed. Then the restored copy
#                  must pass again. A mutation whose target text is not
#                  found exactly once is exit 2 (stale fixture), never a pass.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

HOOK_REL="plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh"
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
    rm -f "$WORK/input.json" "$WORK/stderr.txt" "$WORK/link" "$WORK/real/deep" "$WORK/hook/rails.sh" "$WORK/hook/rails.sh.tmp"
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

# decide <hook> <marker or -> <roots> <input>: runs the hook, sets RC, OUT,
# ERR, and GOT (deny, allow, inert, or other). The input goes through a
# file, not a pipe: the inert hook exits without reading it, and a pipe's
# writer would then fail and make the status its own.
decide() {
    local hook="$1" marker="$2" roots="$3"
    printf '%s' "$4" > "$WORK/input.json"
    RC=0
    OUT=$(
        unset KENSPC_AUTOPILOT_WORKER KENSPC_AUTOPILOT_WRITE_ROOTS
        export HOME="$FX_HOME"
        if [[ "$marker" != "-" ]]; then export KENSPC_AUTOPILOT_WORKER="$marker"; fi
        export KENSPC_AUTOPILOT_WRITE_ROOTS="$roots"
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
D_LABEL=(); D_TOOL=(); D_CWD=(); D_PAYLOAD=(); D_ROOTS=()

# fx <hook> <label> <expect> <marker or -> <roots> <tool> <cwd> <payload>
fx() {
    local hook="$1" label="$2" expect="$3" marker="$4" roots="$5" tool="$6" cwd="$7" payload="$8" ok=0
    decide "$hook" "$marker" "$roots" "$(make_input "$tool" "$cwd" "$payload")"
    if [[ "$GOT" == "$expect" ]]; then
        ok=1
    elif [[ "$expect" == allow && "$GOT" == inert ]]; then
        ok=1
    fi
    if [[ "$expect" == deny && "$ok" -eq 1 && "$ERR" != *.trash* ]]; then
        ok=0
        GOT="deny without .trash in its reason"
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
# is replayed without the marker and with the marker 0.
fx_deny() {
    local hook="$1" label="$2" roots="$3" tool="$4" cwd="$5" payload="$6" n
    fx "$hook" "$label" deny 1 "$roots" "$tool" "$cwd" "$payload"
    n=${#D_LABEL[@]}
    D_LABEL[$n]=$label; D_ROOTS[$n]=$roots; D_TOOL[$n]=$tool; D_CWD[$n]=$cwd; D_PAYLOAD[$n]=$payload
}

# run_fixtures <hook>: every fixture; returns 1 when any decision differs.
run_fixtures() {
    local hook="$1" r="$FX_ROOTS" t k
    FAILS=0; FIRST_RED=""
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
    # rm positions, denied.
    fx_deny "$hook" "rm position line start" "$r" Bash "$FX_REPO" $'echo start\nrm -rf build'
    fx_deny "$hook" "rm position after ;" "$r" Bash "$FX_REPO" 'ls; rm -rf build'
    fx_deny "$hook" "rm position after &&" "$r" Bash "$FX_REPO" 'true && rm -rf build'
    fx_deny "$hook" "rm position after ||" "$r" Bash "$FX_REPO" 'false || rm -rf build'
    fx_deny "$hook" "rm position after |" "$r" Bash "$FX_REPO" 'echo build | rm -rf build'
    fx_deny "$hook" "rm position after \$(" "$r" Bash "$FX_REPO" 'echo $(rm -rf build)'
    fx_deny "$hook" "rm position after backtick" "$r" Bash "$FX_REPO" 'echo `rm -rf build`'
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
    fx_deny "$hook" "rm position in a ( subshell" "$r" Bash "$FX_REPO" '(rm -rf build)'
    fx_deny "$hook" "rm spelling prefix of --recursive: --rec" "$r" Bash "$FX_REPO" 'rm --rec build'
    # A << whose delimiter line never comes — an arithmetic shift, or a
    # heredoc closed by EOF) inside $( — skips nothing: the lines after it
    # are read as commands.
    fx_deny "$hook" "rm after an arithmetic << on an earlier line" "$r" Bash "$FX_REPO" $'echo $((1<<2))\nrm -rf build'
    fx_deny "$hook" "rm after a heredoc closed by EOF) on an earlier line" "$r" Bash "$FX_REPO" $'x=$(cat <<EOF\nnote\nEOF)\nrm -rf build'
    # A Bash input longer than the hook scans within its timeout is denied
    # unscanned, rm or none; one under the cap is scanned.
    t=$(printf '%060000d' 0)
    fx "$hook" "a Bash input under the length cap, scanned" allow 1 "$r" Bash "$FX_REPO" "echo $t"
    t=$(printf '%070000d' 0)
    fx_deny "$hook" "a Bash input over the length cap" "$r" Bash "$FX_REPO" "echo $t"

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
    fx "$hook" "rm without a recursive flag: rm file" allow 1 "$r" Bash "$FX_REPO" 'rm notes.md'
    fx "$hook" "rm without a recursive flag: rm -f file" allow 1 "$r" Bash "$FX_REPO" 'rm -f notes.md'

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
        # A target the hook cannot read, denied even inside a root.
        fx_deny "$hook" "$t with no readable path field" "$r" "$t/no-key" "$FX_REPO" "$FX_REPO/src/a.txt"
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

    # The marker set and no roots: every file-tool write is outside them.
    fx_deny "$hook" "no roots with the marker set" "" Write "$FX_REPO" "$FX_REPO/src/a.txt"

    # A field the hook cannot read — the tool's name, or a Bash command —
    # denies the call rather than passing it unchecked.
    fx_deny "$hook" "Bash with no readable command field" "$r" Bash/no-key "$FX_REPO" 'rm -rf build'
    fx_deny "$hook" "Bash with no readable tool_name" "$r" Bash/no-tool-name "$FX_REPO" 'ls'
    fx_deny "$hook" "Write with no readable tool_name" "$r" Write/no-tool-name "$FX_REPO" "$FX_REPO/src/a.txt"

    # Every denied fixture again without the marker, and with the marker 0.
    k=0
    while [[ "$k" -lt "${#D_LABEL[@]}" ]]; do
        fx "$hook" "${D_LABEL[$k]} (marker unset)" inert - "${D_ROOTS[$k]}" "${D_TOOL[$k]}" "${D_CWD[$k]}" "${D_PAYLOAD[$k]}"
        fx "$hook" "${D_LABEL[$k]} (marker 0)" inert 0 "${D_ROOTS[$k]}" "${D_TOOL[$k]}" "${D_CWD[$k]}" "${D_PAYLOAD[$k]}"
        k=$((k + 1))
    done

    [[ "$FAILS" -eq 0 ]]
}

run_main_logic() {
    local hook="$REPO_ROOT/$HOOK_REL"
    if [[ ! -f "$hook" ]]; then
        echo "ERROR: missing hook $hook" >&2
        return 2
    fi
    make_work
    if run_fixtures "$hook"; then
        echo "OK    autopilot rails hook — every fixture decided as expected (${#D_LABEL[@]} denied fixtures, each also inert without the marker and with it 0)"
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
    local hook="$REPO_ROOT/$HOOK_REL" copy name old new rc
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

    # Three mutants, each a literal replacement in a fresh copy.
    for name in rm-detection root-check marker-check; do
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
