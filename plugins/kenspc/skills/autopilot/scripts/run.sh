#!/bin/bash
# run.sh — the autopilot skill's driver. Starts one headless worker session
# in the background and returns at once; the worker's exit is recorded in a
# file, never reported over a socket.
#
# Interface
#   run.sh <tag> <cwd> <prompt-file> [--resume <session-id>]
#   run.sh --self-test
#
#   <tag>          the worker's session name (--name) and the stem of its files
#   <cwd>          the directory the worker runs in
#   <prompt-file>  the prompt, read from this file with cat; it is never typed
#                  on this script's command line, so no caller has to quote it
#   --resume <session-id>
#                  resume that session instead of starting a fresh one; the
#                  fallback for a worker that has already exited
#
# Environment (all optional)
#   AUTOPILOT_LOGS        the logs directory; default $HOME/Projects/_smoke/_logs
#   AUTOPILOT_PLUGIN_DIR  when non-empty, --plugin-dir <value> is passed, on a
#                         fresh launch and on a resume (plugin mode); the
#                         empty string counts as unset (repo mode)
#   AUTOPILOT_BUDGET_USD  when set, --max-budget-usd <value> is passed
#   APPEND_SP             when set, --append-system-prompt <value> is passed
#                         (the cannot-ask variant)
#   AUTOPILOT_MODEL       when non-empty, --model <value> is passed, on a fresh
#                         launch and on a resume; the empty string counts as
#                         unset
#   AUTOPILOT_EFFORT      when non-empty, --effort <value> is passed, on a
#                         fresh launch and on a resume; the empty string
#                         counts as unset
#   AUTOPILOT_CLAUDE      the executable; default claude
#   AUTOPILOT_BATCH       the batch name in the timeline's file name; default
#                         the tag's prefix before its last "-s" (batch-x-s3
#                         gives batch-x)
#   AUTOPILOT_WORKSPACE   the batch's workspace; when non-empty, one of the
#                         roots in KENSPC_AUTOPILOT_WRITE_ROOTS below; the
#                         empty string counts as unset
#
# Exported to every worker, on a fresh launch and on a resume, overwriting
# any value the caller's environment holds:
#   KENSPC_AUTOPILOT_WORKER       1, the marker
#   KENSPC_AUTOPILOT_WRITE_ROOTS  the roots, joined by "|": the worker's
#                         repository (git rev-parse --show-toplevel run in
#                         <cwd>; no entry when that fails),
#                         AUTOPILOT_WORKSPACE when non-empty, $TMPDIR when
#                         set, /tmp, and /private/tmp, each as given, with
#                         no symbolic link resolved
# Why: the plugin's rails hook reads the two variables and acts only in a
# worker that carries the marker, so every other session's tool calls pass
# it untouched; the caller's values are overwritten, since a marker of 0 or
# a roots list left in the main session's environment would otherwise
# reach the worker. Why "|": no Windows path holds it, while ":" is in
# every drive letter and ";" may be in a file name; run.ps1 joins the roots
# the same way, and the hook splits them on it.
#
# Files, all under the logs directory
#   <tag>.session   the session id, written before the process starts
#   <tag>.pid       the pid of the background subshell, written at launch
#   <tag>.json      the worker's stdout (--output-format json)
#   <tag>.err       the worker's stderr
#   <tag>.exit      the worker's exit status, written right after it returns
#   <batch>-timeline.log
#                   appended: "start <tag> pid <pid> …" at launch and
#                   "end   <tag> exit <status>" (three spaces) when the worker
#                   ends; the end time is the mtime of <tag>.exit
#   <batch>-costs.txt
#                   not written here: the skill upserts one line
#                   "<tag> <session_id> <total_cost_usd>" after each <tag>.exit
#
# Always passed: --name <tag>, --settings '{"crossSessionInbound":"accept"}',
# --permission-mode bypassPermissions, --output-format json; stdin from
# /dev/null. A fresh launch passes --session-id <uuid>. No continue flag is
# ever passed: a resume names its session explicitly.
# Why --model and --effort go on both paths: a worker started without them
# resolves its model and effort from its own settings, not from the session
# that started it, and a resume keeps the model but not the effort — a
# resume launched without --effort ran at the settings' effort rather than
# the one its first run was given.
#
# Why the session id is written before the start: the transcript path and the
# resume id are then known even when the worker dies before its JSON lands.
# Why a subshell under trap '' HUP: the driver returns at once and the worker
# outlives the shell that called it. Why caffeinate -i when present: a batch
# waits for its workers with no Bash call running in the main session, and on
# macOS the machine would otherwise sleep under them; where caffeinate does not
# exist the worker runs the same way without it.
# Why --self-test: it proves the launch path on a machine without spending a
# session — a stub stands in for the executable — and the skill runs the
# copied driver's self-test at every batch start; it also launches a
# failing stub of its own, so a status other than 0 is seen to reach
# <tag>.exit. A caller who sets
# AUTOPILOT_CLAUDE to a stub of their own exercises the failure path; a stub
# of theirs that is meant to pass echoes its arguments,
# "cwd=<its working directory, physical path>", and the two exported
# variables as the lines "KENSPC_AUTOPILOT_WORKER=<value>" and
# "KENSPC_AUTOPILOT_WRITE_ROOTS=<value>" to stderr, since the self-test
# reads the flags, the cwd, and the variables there; prints to stdout a JSON
# object holding "result" and the --session-id value as "session_id", the
# two keys the self-test reads from <tag>.json; exits 0; and stays alive for
# at least one second: the second launch under the tag, refused only while
# the first worker still runs, and the liveness check on <tag>.pid follow
# the launch within that second, so a stub that exits at once usually fails
# the earlier of the two — usually, since on a loaded machine both checks
# can run before its exit lands; the sleep makes the outcome certain.
#
# Exit status of a launch: 0 once the worker has been started; 2 on a usage
# or environment error, or when <tag>.pid names a live process and <tag>.exit
# is absent — an earlier worker under the same tag still running (nothing
# started). The worker's own status goes to <tag>.exit. Self-test: 0 on
# pass, 1 on the first missing or wrong item.
#
# Bash 3.2 (the one macOS ships): no associative arrays, no array-reading
# builtins, no case-modifying expansions; POSIX tools plus uuidgen or python3
# for the UUID, and git: a launch reads the worker's repository with it when
# it is present, and --self-test needs it for the repository it creates.

set -u

die() {
  echo "run.sh: $*" >&2
  exit 2
}

usage() {
  echo "usage: $0 <tag> <cwd> <prompt-file> [--resume <session-id>]" >&2
  echo "       $0 --self-test" >&2
  exit 2
}

new_uuid() {
  local id
  if command -v uuidgen >/dev/null 2>&1; then
    # The status of a pipeline is tr's, so uuidgen's failure would pass as
    # an empty id; its status is taken on its own line. Each failure names
    # itself: a silent exit 2 here would leave the caller with no session
    # id and no reason.
    id=$(uuidgen) || die "uuidgen failed to make a session id"
    [ -n "$id" ] || die "uuidgen returned no id"
    printf '%s\n' "$id" | tr 'A-Z' 'a-z'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import uuid;print(uuid.uuid4())'
  else
    echo "run.sh: neither uuidgen nor python3 is available to make a session id" >&2
    return 1
  fi
}

# launch <tag> <cwd> <prompt-file> <resume-session-id or empty>
# Starts the worker and prints "started <tag> pid <pid> session <id>".
launch() {
  local tag dir prompt_file resume logs batch exe prompt session pid stamp extra roots top
  tag=$1; dir=$2; prompt_file=$3; resume=$4
  logs=${AUTOPILOT_LOGS:-$HOME/Projects/_smoke/_logs}
  batch=${AUTOPILOT_BATCH:-${tag%-s*}}
  exe=${AUTOPILOT_CLAUDE:-claude}

  [ -n "$tag" ] || die "the tag is empty"
  [ -d "$dir" ] || die "cannot cd to $dir"
  [ -f "$prompt_file" ] || die "no prompt file $prompt_file"
  # An empty prompt — no content, or whitespace only, which cat strips to
  # nothing — would start a paid session with no instructions, which dies
  # and is resumed into an empty transcript before the stop.
  grep -q '[^[:space:]]' "$prompt_file" || die "empty prompt file $prompt_file"
  # A missing executable is a refusal here, not a worker that dies at once:
  # without the check the driver printed "started", .exit read 127 with an
  # empty .json, and the skill resumed a dead worker instead of reading the
  # reason.
  command -v "$exe" >/dev/null 2>&1 || die "no executable $exe; set AUTOPILOT_CLAUDE or put claude on PATH"
  mkdir -p "$logs" || die "cannot create the logs directory $logs"
  logs=$(cd "$logs" && pwd) || die "cannot enter the logs directory $logs"
  prompt=$(cat "$prompt_file") || die "cannot read $prompt_file"

  # A launch under a tag whose earlier worker still runs — its pid live and
  # its exit file not yet written — would overwrite that worker's files and
  # put two workers into one repository; it is refused before anything is
  # written. A pid file left by a machine that rebooted under a worker can
  # name an unrelated process, so the message says what to remove.
  if [ -f "$logs/$tag.pid" ] && [ ! -f "$logs/$tag.exit" ]; then
    local earlier
    earlier=$(cat "$logs/$tag.pid")
    if [ -n "$earlier" ] && kill -0 "$earlier" 2>/dev/null; then
      die "a worker under the tag $tag is still running (pid $earlier, $logs/$tag.pid); wait for $logs/$tag.exit, or remove the pid file when that process is not the worker"
    fi
  fi

  if [ -n "$resume" ]; then
    session=$resume
  else
    # new_uuid runs in a subshell, so its die ends only that subshell; the
    # launch itself ends here, and an empty id is caught whichever branch
    # made it.
    session=$(new_uuid) && [ -n "$session" ] || die "no session id was made; nothing started"
  fi
  printf '%s\n' "$session" > "$logs/$tag.session" || die "cannot write $logs/$tag.session"

  local args cmd
  args=(--name "$tag" --settings '{"crossSessionInbound":"accept"}' --permission-mode bypassPermissions --output-format json)
  extra=""
  if [ -n "${AUTOPILOT_PLUGIN_DIR:-}" ]; then
    args+=(--plugin-dir "$AUTOPILOT_PLUGIN_DIR")
    extra="$extra plugin-dir $AUTOPILOT_PLUGIN_DIR"
  fi
  if [ -n "${AUTOPILOT_BUDGET_USD:-}" ]; then
    args+=(--max-budget-usd "$AUTOPILOT_BUDGET_USD")
    extra="$extra budget USD $AUTOPILOT_BUDGET_USD"
  fi
  if [ -n "${APPEND_SP:-}" ]; then
    args+=(--append-system-prompt "$APPEND_SP")
    extra="$extra [append-system-prompt]"
  fi
  if [ -n "${AUTOPILOT_MODEL:-}" ]; then
    args+=(--model "$AUTOPILOT_MODEL")
  fi
  if [ -n "${AUTOPILOT_EFFORT:-}" ]; then
    args+=(--effort "$AUTOPILOT_EFFORT")
  fi
  if [ -n "$resume" ]; then
    cmd=("$exe" -p --resume "$session" "$prompt" "${args[@]}")
    extra="$extra resume"
  else
    cmd=("$exe" -p "$prompt" --session-id "$session" "${args[@]}")
  fi
  if command -v caffeinate >/dev/null 2>&1; then
    cmd=(caffeinate -i "${cmd[@]}")
  fi

  # The rails hook's roots, joined by "|" (the header says why). A cwd
  # outside a git repository, or no git, adds no repository entry.
  roots=""
  if command -v git >/dev/null 2>&1; then
    top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || top=""
    if [ -n "$top" ]; then
      roots=$top
    fi
  fi
  if [ -n "${AUTOPILOT_WORKSPACE:-}" ]; then
    roots="${roots:+$roots|}$AUTOPILOT_WORKSPACE"
  fi
  if [ -n "${TMPDIR:-}" ]; then
    roots="${roots:+$roots|}$TMPDIR"
  fi
  roots="${roots:+$roots|}/tmp|/private/tmp"

  cd "$dir" || die "cannot cd to $dir"
  # A stale exit file from an earlier launch under the same tag would read as
  # this worker's completion before it starts; nothing else is removed.
  rm -f "$logs/$tag.exit"
  (
    trap '' HUP
    export KENSPC_AUTOPILOT_WORKER=1
    export KENSPC_AUTOPILOT_WRITE_ROOTS="$roots"
    "${cmd[@]}" > "$logs/$tag.json" 2> "$logs/$tag.err" < /dev/null
    status=$?
    printf '%s\n' "$status" > "$logs/$tag.exit"
    printf 'end   %s exit %s\n' "$tag" "$status" >> "$logs/$batch-timeline.log"
  ) > /dev/null 2>&1 < /dev/null &
  pid=$!
  printf '%s\n' "$pid" > "$logs/$tag.pid"
  stamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf 'start %s pid %s session %s at %s cwd %s prompt %s%s\n' \
    "$tag" "$pid" "$session" "$stamp" "$dir" "$prompt_file" "$extra" \
    >> "$logs/$batch-timeline.log"
  echo "started $tag pid $pid session $session"
}

# selftest_worker_vars <err-file> <workspace> <present|absent> <repository or empty> [<cwd>]
# The self-test's check of the two exported variables a stub wrote to its
# .err: the marker reads 1; the roots do not hold the stale entry the
# self-test's environment carries, and hold $TMPDIR (when set), /tmp, and
# /private/tmp, the repository when one is given, and the workspace when
# present — or, when absent, no workspace entry: neither that path nor an
# empty entry; and, when a cwd is given, one that is no repository's top
# level, no entry for it. Prints the first failure and returns 1.
selftest_worker_vars() {
  local err=$1 workspace=$2 wanted=$3 repo=$4 cwd=${5:-} roots want
  grep -qxF -- 'KENSPC_AUTOPILOT_WORKER=1' "$err" \
    || { echo "self-test failed: $err does not show the marker KENSPC_AUTOPILOT_WORKER=1" >&2; return 1; }
  roots=$(sed -n 's/^KENSPC_AUTOPILOT_WRITE_ROOTS=//p' "$err")
  [ -n "$roots" ] \
    || { echo "self-test failed: $err shows no roots in KENSPC_AUTOPILOT_WRITE_ROOTS" >&2; return 1; }
  case "|$roots|" in
    *"|/kenspc-selftest-stale-root|"*)
      echo "self-test failed: the roots in $err, KENSPC_AUTOPILOT_WRITE_ROOTS=$roots, hold the caller's stale entry /kenspc-selftest-stale-root" >&2
      return 1
      ;;
  esac
  set -- /tmp /private/tmp
  if [ -n "${TMPDIR:-}" ]; then set -- "$@" "$TMPDIR"; fi
  if [ -n "$repo" ]; then set -- "$@" "$repo"; fi
  if [ "$wanted" = present ]; then set -- "$@" "$workspace"; fi
  for want in "$@"; do
    case "|$roots|" in
      *"|$want|"*) ;;
      *) echo "self-test failed: the roots in $err, KENSPC_AUTOPILOT_WRITE_ROOTS=$roots, do not hold $want" >&2; return 1 ;;
    esac
  done
  if [ "$wanted" = absent ]; then
    case "|$roots|" in
      *"|$workspace|"*|*"||"*)
        echo "self-test failed: the roots in $err, KENSPC_AUTOPILOT_WRITE_ROOTS=$roots, hold a workspace entry with AUTOPILOT_WORKSPACE the empty string" >&2
        return 1
        ;;
    esac
  fi
  if [ -n "$cwd" ]; then
    case "|$roots|" in
      *"|$cwd|"*)
        echo "self-test failed: the roots in $err, KENSPC_AUTOPILOT_WRITE_ROOTS=$roots, hold the cwd $cwd, which is no repository's top level" >&2
        return 1
        ;;
    esac
  fi
  return 0
}

# self_test: launch a stub through the same path and check every file the
# header names. The logs directory is always a fresh directory under $TMPDIR,
# whatever AUTOPILOT_LOGS says, so a self-test writes nothing under the
# workspace. Passing: every file is present with the expected content and the
# timeline holds both lines. It fails, in this order, on a launch naming a
# missing executable, or an empty or whitespace-only prompt file, that is
# not refused with status 2 naming it and writing no .session; on a logs
# directory the launch did not create; on a stdout line other than
# "started <tag> pid <pid> session <id>" with the pid and the id that .pid
# and .session hold; on a second launch
# under the tag, made while the stub still runs, that is not refused with
# status 2 naming the pid and leaving .session and .pid as they were; a
# .pid that does not name a live process other than the self-test's own;
# then on a missing .session,
# a missing .pid, a .json that is missing, unparseable, or without "result",
# a missing .err, a .exit that is missing or does not read 0, a timeline
# without its start or end line, an .err that does not show every
# always-passed flag with the id .session holds, a .json whose
# session_id is not that id, and an .err that shows --plugin-dir,
# --max-budget-usd, --append-system-prompt, --model, or --effort with their
# variables unset, or without cwd=<the launch's cwd, physical path>; then,
# for a launch of a stub that exits 3 under selftest-s2, a .exit not
# reading 3 or a timeline end line without exit 3;
# then, for a launch under selftest-s3 with AUTOPILOT_MODEL and
# AUTOPILOT_EFFORT set, a .exit missing after the wait or an .err without
# --model <value> or --effort <value>; then, for a launch under
# selftest-s4 with both set to the empty string, a .exit missing after the
# wait or not reading 0, an .err without --name <tag>, or an .err that
# shows --model or --effort; then, for a launch under
# selftest-s5 with AUTOPILOT_MODEL set and AUTOPILOT_EFFORT the empty
# string, a .exit missing after the wait or an .err without
# --model <value> or showing --effort, and for one under selftest-s6 the
# other way round, a .exit missing after the wait or an .err without
# --effort <value> or showing --model;
# then, for a launch under selftest-s13 with AUTOPILOT_PLUGIN_DIR the empty
# string, a .exit missing after the wait, an .err without --name <tag>, or
# an .err that shows --plugin-dir, and for one under selftest-s14 with it
# set, a .exit missing after the wait, an .err without --name <tag>, or an
# .err without --plugin-dir <value>;
# then, with the caller's environment holding KENSPC_AUTOPILOT_WORKER=0
# and the stale roots KENSPC_AUTOPILOT_WRITE_ROOTS=/kenspc-selftest-stale-root,
# for a launch under selftest-s15 with AUTOPILOT_WORKSPACE set, a .exit
# missing after the wait, an .err without --name <tag>, without the marker
# KENSPC_AUTOPILOT_WORKER=1, or with roots (KENSPC_AUTOPILOT_WRITE_ROOTS)
# not holding $TMPDIR (when set), /tmp, /private/tmp, and the workspace, or
# holding the stale entry or its cwd, which is no repository's top level;
# then a git init of a repository under the self-test's directory that
# fails, and for a launch under selftest-s16 in that repository with
# AUTOPILOT_WORKSPACE the empty string, the same items with roots not
# holding the repository's top level or holding a workspace entry;
# then, for a resume launch of the same stub
# under <tag>-r1 through the command line (the parser the skill calls)
# with that id and AUTOPILOT_PLUGIN_DIR, AUTOPILOT_BUDGET_USD, APPEND_SP,
# AUTOPILOT_MODEL, AUTOPILOT_EFFORT, and AUTOPILOT_WORKSPACE set, a command
# line not returning 0, a .exit missing or not 0,
# a .session not holding that id, an .err without --resume <id>, with
# --session-id, or without --name <tag> or the five variables' flags, a
# timeline start line not ending in "resume", the marker and roots items of
# selftest-s15, and a command line with
# --resume and no id, or with an unknown argument, that does not return 2
# or writes <tag>-r1-x.session; then, for resume launches through the
# command line under <tag>-r2 with AUTOPILOT_PLUGIN_DIR unset and under
# <tag>-r3 with it the empty string, a command line not returning 0, a
# .exit missing after the wait, an .err without --name <tag>, or an .err
# that shows --plugin-dir; then, for a resume launch through the command
# line under <tag>-r4 with AUTOPILOT_WORKSPACE the empty string, a command
# line not returning 0, a .exit missing after the wait, an .err without
# --name <tag>, without the marker, or with roots not holding $TMPDIR
# (when set), /tmp, and /private/tmp or holding a workspace entry; then,
# for a launch under self-s-test-s1 with AUTOPILOT_BATCH unset and a stale
# self-s-test-s1.exit in place, that file still present right after the
# launch, a .exit not reading 0 after the wait, and a
# self-s-test-timeline.log without its start or end line (the batch-name
# default keeps a name that holds "-s") — naming the first item that fails.
self_test() {
  local base LOGS TAG RTAG BTAG MTAG ETAG XTAG YTAG PETAG PSTAG PRTAG plugin_case n exit_status session flag
  local WSDIR W1TAG W2TAG W3TAG repo_top
  local first_session first_pid refusal rc self FTAG saved_exe bad started
  base=$(mktemp -d "${TMPDIR:-/tmp}/autopilot-selftest.XXXXXX") || die "cannot create a directory under ${TMPDIR:-/tmp}"
  # This script's own absolute path, resolved before the first launch
  # changes the working directory: the resume launch below runs it as the
  # skill does, through its command line.
  self=$(cd "$(dirname "$0")" && pwd) || die "cannot resolve the directory of $0"
  self=$self/$(basename "$0")
  # Not created here: the first launch's mkdir -p is what creates it.
  LOGS=$base/logs

  if [ -z "${AUTOPILOT_CLAUDE:-}" ]; then
    mkdir -p "$base/stub" || die "cannot create $base/stub"
    cat > "$base/stub/claude" <<'STUB'
#!/bin/sh
# Stub executable for run.sh --self-test: echoes its arguments, its working
# directory, and the two exported worker variables to stderr, prints a
# result object to stdout, sleeps one second, exits 0.
echo "$@" >&2
echo "cwd=$(pwd -P)" >&2
echo "KENSPC_AUTOPILOT_WORKER=${KENSPC_AUTOPILOT_WORKER:-}" >&2
echo "KENSPC_AUTOPILOT_WRITE_ROOTS=${KENSPC_AUTOPILOT_WRITE_ROOTS:-}" >&2
id=""
while [ $# -gt 0 ]; do
  case $1 in
    --session-id|--resume) id=${2:-}; shift ;;
  esac
  shift
done
printf '{"type":"result","subtype":"success","is_error":false,"result":"stub ok","session_id":"%s","total_cost_usd":0.01,"num_turns":1}\n' "$id"
sleep 1
exit 0
STUB
    chmod +x "$base/stub/claude" || die "cannot make the stub executable"
    AUTOPILOT_CLAUDE=$base/stub/claude
  fi
  # A second stub that exits 3 without a result, for the status check
  # below; written whatever AUTOPILOT_CLAUDE names, so a caller's stub is
  # used for the passing launches only.
  mkdir -p "$base/stub" || die "cannot create $base/stub"
  printf '#!/bin/sh\necho "$@" >&2\necho "KENSPC_AUTOPILOT_WORKER=${KENSPC_AUTOPILOT_WORKER:-}" >&2\necho "KENSPC_AUTOPILOT_WRITE_ROOTS=${KENSPC_AUTOPILOT_WRITE_ROOTS:-}" >&2\nexit 3\n' > "$base/stub/fail" || die "cannot write the failing stub"
  chmod +x "$base/stub/fail" || die "cannot make the failing stub executable"

  # The five optional variables are unset for the first launch, whatever
  # the caller's environment holds, so their flags can be asserted absent.
  unset AUTOPILOT_PLUGIN_DIR AUTOPILOT_BUDGET_USD APPEND_SP AUTOPILOT_MODEL AUTOPILOT_EFFORT
  # The caller's environment holds the marker 0 and a stale roots list for
  # every launch below, so a driver that did not overwrite them would pass
  # them to the worker — a nested launch from a marked session would hand
  # it the outer worker's roots; the workspace is unset unless a launch
  # sets it.
  KENSPC_AUTOPILOT_WORKER=0; export KENSPC_AUTOPILOT_WORKER
  KENSPC_AUTOPILOT_WRITE_ROOTS=/kenspc-selftest-stale-root; export KENSPC_AUTOPILOT_WRITE_ROOTS
  unset AUTOPILOT_WORKSPACE
  AUTOPILOT_LOGS=$LOGS
  AUTOPILOT_BATCH=selftest
  TAG=selftest-s1
  printf 'Reply ok and stop.\n' > "$base/prompt.md" || die "cannot write the prompt file"
  echo "self-test: logs directory $LOGS"
  echo "self-test: executable $AUTOPILOT_CLAUDE"

  # A launch naming a missing executable is refused before anything is
  # written: status 2, the path named, no .session. In a subshell, since
  # die exits the calling shell.
  refusal=$( (AUTOPILOT_CLAUDE=$base/no-such-claude launch "$TAG" "$base" "$base/prompt.md" "") 2>&1 ); rc=$?
  [ "$rc" -eq 2 ] && [ ! -f "$LOGS/$TAG.session" ] \
    || { echo "self-test failed: a launch with a missing executable returned $rc ($([ -f "$LOGS/$TAG.session" ] && echo ".session written" || echo "no .session")), expected 2 and no .session" >&2; return 1; }
  printf '%s\n' "$refusal" | grep -qF -- "no executable $base/no-such-claude" \
    || { echo "self-test failed: the refusal of a missing executable does not name $base/no-such-claude" >&2; return 1; }
  # An empty prompt file, and one of only whitespace (cat strips the
  # trailing newlines, so the worker would start with a blank prompt), are
  # refused the same way: the paid empty session the guard exists to
  # prevent.
  : > "$base/empty.md" || die "cannot write the empty prompt file"
  printf '\n  \n' > "$base/blank.md" || die "cannot write the blank prompt file"
  for bad in empty blank; do
    refusal=$( (launch "$TAG" "$base" "$base/$bad.md" "") 2>&1 ); rc=$?
    [ "$rc" -eq 2 ] && [ ! -f "$LOGS/$TAG.session" ] \
      || { echo "self-test failed: a launch with the $bad prompt file returned $rc, expected 2 and no .session" >&2; return 1; }
    printf '%s\n' "$refusal" | grep -qF -- "empty prompt file $base/$bad.md" \
      || { echo "self-test failed: the refusal of the $bad prompt file does not name $base/$bad.md" >&2; return 1; }
  done

  # The launch's stdout is captured: the skill reads the pid and the
  # session id from that one line.
  started=$(launch "$TAG" "$base" "$base/prompt.md" "")
  printf '%s\n' "$started"
  [ -d "$LOGS" ] \
    || { echo "self-test failed: the driver did not create the logs directory $LOGS" >&2; return 1; }
  first_session=$(cat "$LOGS/$TAG.session" 2>/dev/null); first_pid=$(cat "$LOGS/$TAG.pid" 2>/dev/null)
  [ "$started" = "started $TAG pid $first_pid session $first_session" ] \
    || { echo "self-test failed: the driver printed \"$started\", expected \"started $TAG pid $first_pid session $first_session\" from .pid and .session" >&2; return 1; }

  # A second launch under the same tag while the stub still runs (its one
  # second of sleep) is refused before anything is written: status 2, the
  # pid named, .session and .pid as they were. In a subshell, since die
  # exits the calling shell. Without the refusal two workers would share
  # one repository and the second would overwrite the first's files.
  refusal=$( (launch "$TAG" "$base" "$base/prompt.md" "") 2>&1 ); rc=$?
  [ "$rc" -eq 2 ] || { echo "self-test failed: a second launch under the running tag $TAG returned $rc, expected 2 (refused)" >&2; return 1; }
  printf '%s\n' "$refusal" | grep -qF -- "still running (pid $first_pid," \
    || { echo "self-test failed: the refusal of a second launch under $TAG does not name pid $first_pid" >&2; return 1; }
  [ "$(cat "$LOGS/$TAG.session")" = "$first_session" ] && [ "$(cat "$LOGS/$TAG.pid")" = "$first_pid" ] \
    || { echo "self-test failed: a refused launch under $TAG changed $LOGS/$TAG.session or $LOGS/$TAG.pid" >&2; return 1; }
  # The pid file names a live process other than this one: the skill reads
  # a gone pid with no .exit as a dead worker and resumes it, so a driver
  # that wrote its own pid would have every worker resumed beside itself.
  kill -0 "$first_pid" 2>/dev/null && [ "$first_pid" != "$$" ] \
    || { echo "self-test failed: $LOGS/$TAG.pid names $first_pid, not a live process other than the self-test's own" >&2; return 1; }

  n=0; until [ -f "$LOGS/$TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done

  [ -s "$LOGS/$TAG.session" ] || { echo "self-test failed: $LOGS/$TAG.session is missing or empty" >&2; return 1; }
  [ -s "$LOGS/$TAG.pid" ] || { echo "self-test failed: $LOGS/$TAG.pid is missing or empty" >&2; return 1; }
  [ -f "$LOGS/$TAG.json" ] || { echo "self-test failed: $LOGS/$TAG.json is missing" >&2; return 1; }
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
sys.exit(0 if isinstance(d,dict) and "result" in d else 1)' "$LOGS/$TAG.json" 2>/dev/null \
      || { echo "self-test failed: $LOGS/$TAG.json is not a JSON object holding \"result\"" >&2; return 1; }
  else
    grep -q '"result"' "$LOGS/$TAG.json" \
      || { echo "self-test failed: $LOGS/$TAG.json holds no \"result\" key" >&2; return 1; }
  fi
  [ -f "$LOGS/$TAG.err" ] || { echo "self-test failed: $LOGS/$TAG.err is missing" >&2; return 1; }
  [ -f "$LOGS/$TAG.exit" ] || { echo "self-test failed: $LOGS/$TAG.exit is missing after the wait" >&2; return 1; }
  exit_status=$(cat "$LOGS/$TAG.exit")
  [ "$exit_status" = "0" ] || { echo "self-test failed: $LOGS/$TAG.exit reads $exit_status, expected 0" >&2; return 1; }
  grep -q "^start $TAG pid [0-9][0-9]* " "$LOGS/selftest-timeline.log" 2>/dev/null \
    || { echo "self-test failed: $LOGS/selftest-timeline.log has no start line for $TAG" >&2; return 1; }
  grep -q "^end   $TAG exit 0\$" "$LOGS/selftest-timeline.log" 2>/dev/null \
    || { echo "self-test failed: $LOGS/selftest-timeline.log has no end line for $TAG" >&2; return 1; }

  # The stub echoes its arguments to .err, so the flags the header promises
  # are read there: a driver whose flag passing broke would otherwise pass
  # this gate and fail only inside a paid session.
  session=$(cat "$LOGS/$TAG.session")
  for flag in "--session-id $session" "--name $TAG" \
              '--settings {"crossSessionInbound":"accept"}' \
              '--permission-mode bypassPermissions' '--output-format json'; do
    grep -qF -- "$flag" "$LOGS/$TAG.err" \
      || { echo "self-test failed: $LOGS/$TAG.err does not show $flag" >&2; return 1; }
  done
  grep -qF -- "\"session_id\":\"$session\"" "$LOGS/$TAG.json" \
    || { echo "self-test failed: $LOGS/$TAG.json does not carry the session_id that $LOGS/$TAG.session holds" >&2; return 1; }
  # With the five optional variables unset their flags are absent: a
  # driver that passed --plugin-dir "" on every launch would start every
  # repo-mode worker with an empty plugin directory.
  for flag in --plugin-dir --max-budget-usd --append-system-prompt --model --effort; do
    ! grep -qF -- "$flag" "$LOGS/$TAG.err" \
      || { echo "self-test failed: $LOGS/$TAG.err shows $flag on a launch with its variable unset" >&2; return 1; }
  done
  # The worker runs in the launch's cwd, which the stub reports as its
  # physical path: a driver that lost its cd would run every worker in the
  # directory the driver was called from.
  grep -qxF -- "cwd=$(cd "$base" && pwd -P)" "$LOGS/$TAG.err" \
    || { echo "self-test failed: $LOGS/$TAG.err does not show cwd=$(cd "$base" && pwd -P), the launch's cwd" >&2; return 1; }

  # A worker's non-zero status reaches .exit and the timeline's end line:
  # the skill reads both, and a driver that always wrote 0 would report
  # every failed worker as a success. The failing stub exits 3 at once.
  FTAG=selftest-s2
  saved_exe=$AUTOPILOT_CLAUDE; AUTOPILOT_CLAUDE=$base/stub/fail
  launch "$FTAG" "$base" "$base/prompt.md" ""
  AUTOPILOT_CLAUDE=$saved_exe
  n=0; until [ -f "$LOGS/$FTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ "$(cat "$LOGS/$FTAG.exit" 2>/dev/null)" = "3" ] \
    || { echo "self-test failed: $LOGS/$FTAG.exit does not read 3, the failing stub's status" >&2; return 1; }
  grep -q "^end   $FTAG exit 3\$" "$LOGS/selftest-timeline.log" 2>/dev/null \
    || { echo "self-test failed: $LOGS/selftest-timeline.log has no end line with exit 3 for $FTAG" >&2; return 1; }

  # A fresh launch with AUTOPILOT_MODEL and AUTOPILOT_EFFORT set carries
  # both flags with their values: a worker started without them resolves
  # its model and effort from its own settings, so a driver that dropped
  # either would run the role at values nobody asked for. The values are
  # placeholders, not model names.
  MTAG=selftest-s3
  AUTOPILOT_MODEL=selftest-model; AUTOPILOT_EFFORT=low
  launch "$MTAG" "$base" "$base/prompt.md" ""
  unset AUTOPILOT_MODEL AUTOPILOT_EFFORT
  n=0; until [ -f "$LOGS/$MTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$MTAG.exit" ] || { echo "self-test failed: $LOGS/$MTAG.exit is missing after the wait" >&2; return 1; }
  for flag in '--model selftest-model' '--effort low'; do
    grep -qF -- "$flag" "$LOGS/$MTAG.err" \
      || { echo "self-test failed: $LOGS/$MTAG.err does not show $flag" >&2; return 1; }
  done
  # Set to the empty string, the two variables count as unset: the skill
  # sets both on every launch, empty where no value was determined, so a
  # driver that tested only whether they were set would pass an empty
  # --model or --effort.
  ETAG=selftest-s4
  AUTOPILOT_MODEL=""; AUTOPILOT_EFFORT=""
  launch "$ETAG" "$base" "$base/prompt.md" ""
  unset AUTOPILOT_MODEL AUTOPILOT_EFFORT
  n=0; until [ -f "$LOGS/$ETAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$ETAG.exit" ] || { echo "self-test failed: $LOGS/$ETAG.exit is missing after the wait" >&2; return 1; }
  exit_status=$(cat "$LOGS/$ETAG.exit")
  [ "$exit_status" = "0" ] || { echo "self-test failed: $LOGS/$ETAG.exit reads $exit_status, expected 0" >&2; return 1; }
  # The absence check below also holds for a missing or empty .err, so the
  # launch's own --name is read there first: the flags are then absent from
  # the arguments this launch received, not from a file that holds none.
  grep -qF -- "--name $ETAG" "$LOGS/$ETAG.err" \
    || { echo "self-test failed: $LOGS/$ETAG.err does not show --name $ETAG" >&2; return 1; }
  for flag in --model --effort; do
    ! grep -qF -- "$flag" "$LOGS/$ETAG.err" \
      || { echo "self-test failed: $LOGS/$ETAG.err shows $flag on a launch with its variable set to the empty string" >&2; return 1; }
  done
  # One variable set and the other the empty string, the mix the skill
  # sends when a role's other part is not determined: each flag follows its
  # own variable, so a driver that passed both flags whenever either was set
  # would pass an empty value, and one that passed --effort only beside
  # --model would run the role at its settings' effort.
  XTAG=selftest-s5
  AUTOPILOT_MODEL=selftest-model; AUTOPILOT_EFFORT=""
  launch "$XTAG" "$base" "$base/prompt.md" ""
  unset AUTOPILOT_MODEL AUTOPILOT_EFFORT
  n=0; until [ -f "$LOGS/$XTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$XTAG.exit" ] || { echo "self-test failed: $LOGS/$XTAG.exit is missing after the wait" >&2; return 1; }
  grep -qF -- '--model selftest-model' "$LOGS/$XTAG.err" \
    || { echo "self-test failed: $LOGS/$XTAG.err does not show --model selftest-model" >&2; return 1; }
  ! grep -qF -- '--effort' "$LOGS/$XTAG.err" \
    || { echo "self-test failed: $LOGS/$XTAG.err shows --effort on a launch with AUTOPILOT_EFFORT set to the empty string" >&2; return 1; }
  YTAG=selftest-s6
  AUTOPILOT_MODEL=""; AUTOPILOT_EFFORT=low
  launch "$YTAG" "$base" "$base/prompt.md" ""
  unset AUTOPILOT_MODEL AUTOPILOT_EFFORT
  n=0; until [ -f "$LOGS/$YTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$YTAG.exit" ] || { echo "self-test failed: $LOGS/$YTAG.exit is missing after the wait" >&2; return 1; }
  grep -qF -- '--effort low' "$LOGS/$YTAG.err" \
    || { echo "self-test failed: $LOGS/$YTAG.err does not show --effort low" >&2; return 1; }
  ! grep -qF -- '--model' "$LOGS/$YTAG.err" \
    || { echo "self-test failed: $LOGS/$YTAG.err shows --model on a launch with AUTOPILOT_MODEL set to the empty string" >&2; return 1; }
  # AUTOPILOT_PLUGIN_DIR follows the same rule: the skill sets it on every
  # launch, the plugin directory in plugin mode and the empty string in repo
  # mode, so a driver that tested only whether it was set would start every
  # repo-mode worker with an empty --plugin-dir, and one that dropped the
  # value would start a plugin-mode worker on the installed plugin. Each
  # case reads its own --name first, so --plugin-dir is looked for in the
  # arguments this launch received.
  PETAG=selftest-s13
  AUTOPILOT_PLUGIN_DIR=""
  launch "$PETAG" "$base" "$base/prompt.md" ""
  unset AUTOPILOT_PLUGIN_DIR
  n=0; until [ -f "$LOGS/$PETAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$PETAG.exit" ] || { echo "self-test failed: $LOGS/$PETAG.exit is missing after the wait" >&2; return 1; }
  grep -qF -- "--name $PETAG" "$LOGS/$PETAG.err" \
    || { echo "self-test failed: $LOGS/$PETAG.err does not show --name $PETAG" >&2; return 1; }
  ! grep -qF -- '--plugin-dir' "$LOGS/$PETAG.err" \
    || { echo "self-test failed: $LOGS/$PETAG.err shows --plugin-dir on a launch with AUTOPILOT_PLUGIN_DIR set to the empty string" >&2; return 1; }
  PSTAG=selftest-s14
  AUTOPILOT_PLUGIN_DIR=$base/plugin
  launch "$PSTAG" "$base" "$base/prompt.md" ""
  unset AUTOPILOT_PLUGIN_DIR
  n=0; until [ -f "$LOGS/$PSTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$PSTAG.exit" ] || { echo "self-test failed: $LOGS/$PSTAG.exit is missing after the wait" >&2; return 1; }
  grep -qF -- "--name $PSTAG" "$LOGS/$PSTAG.err" \
    || { echo "self-test failed: $LOGS/$PSTAG.err does not show --name $PSTAG" >&2; return 1; }
  grep -qF -- "--plugin-dir $base/plugin" "$LOGS/$PSTAG.err" \
    || { echo "self-test failed: $LOGS/$PSTAG.err does not show --plugin-dir $base/plugin" >&2; return 1; }
  # The worker variables on two fresh launches: one with AUTOPILOT_WORKSPACE
  # set, and one with it the empty string whose cwd is a git repository the
  # self-test creates, so the roots hold that repository's top level. The
  # rails hook reads the marker and the roots, so a driver that dropped
  # either would leave a worker's rails to the text alone.
  WSDIR=$base/workspace
  W1TAG=selftest-s15
  AUTOPILOT_WORKSPACE=$WSDIR
  launch "$W1TAG" "$base" "$base/prompt.md" ""
  unset AUTOPILOT_WORKSPACE
  n=0; until [ -f "$LOGS/$W1TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$W1TAG.exit" ] || { echo "self-test failed: $LOGS/$W1TAG.exit is missing after the wait" >&2; return 1; }
  grep -qF -- "--name $W1TAG" "$LOGS/$W1TAG.err" \
    || { echo "self-test failed: $LOGS/$W1TAG.err does not show --name $W1TAG" >&2; return 1; }
  # Its cwd, $base, is no repository's top level, so the roots hold no entry
  # for it: a driver that fell back to the cwd outside a repository would
  # widen the rails to a directory nobody named.
  selftest_worker_vars "$LOGS/$W1TAG.err" "$WSDIR" present "" "$base" || return 1
  W2TAG=selftest-s16
  git init -q "$base/repo" >/dev/null 2>&1 \
    || { echo "self-test failed: git init $base/repo failed, so the repository root cannot be checked" >&2; return 1; }
  repo_top=$(cd "$base/repo" && pwd -P)
  AUTOPILOT_WORKSPACE=""
  launch "$W2TAG" "$base/repo" "$base/prompt.md" ""
  unset AUTOPILOT_WORKSPACE
  n=0; until [ -f "$LOGS/$W2TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$W2TAG.exit" ] || { echo "self-test failed: $LOGS/$W2TAG.exit is missing after the wait" >&2; return 1; }
  grep -qF -- "--name $W2TAG" "$LOGS/$W2TAG.err" \
    || { echo "self-test failed: $LOGS/$W2TAG.err does not show --name $W2TAG" >&2; return 1; }
  selftest_worker_vars "$LOGS/$W2TAG.err" "$WSDIR" absent "$repo_top" || return 1

  # A resume launch through the same path, with the first launch's id: it
  # is the recovery for a dead or cap-ended worker, reached after a paid
  # session has ended, so a regression there would otherwise show only then.
  # The five optional variables are set for this launch only, so their
  # flags are read from .err too: a plugin-mode worker launched without
  # --plugin-dir would load the installed plugin and review code other than
  # the batch's, one without --max-budget-usd would run unbounded, and a
  # resume without --effort would fall back to the settings' effort, since a
  # resume keeps the model but not the effort. Its effort, high, differs
  # from the fresh launches' low, so a driver that passed a fixed --effort
  # rather than the variable's value fails here. This
  # launch goes through the command line, the parser the skill calls, so a
  # driver that dropped the --resume value is caught here rather than
  # starting a fresh session under the resume tag.
  RTAG=$TAG-r1
  AUTOPILOT_LOGS=$LOGS AUTOPILOT_BATCH=selftest AUTOPILOT_CLAUDE=$AUTOPILOT_CLAUDE \
  AUTOPILOT_PLUGIN_DIR=$base/plugin AUTOPILOT_BUDGET_USD=1 APPEND_SP=x \
  AUTOPILOT_MODEL=selftest-model AUTOPILOT_EFFORT=high AUTOPILOT_WORKSPACE=$WSDIR \
    bash "$self" "$RTAG" "$base" "$base/prompt.md" --resume "$session" \
    || { echo "self-test failed: the resume launch of $RTAG through the command line did not return 0" >&2; return 1; }
  n=0; until [ -f "$LOGS/$RTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$RTAG.exit" ] || { echo "self-test failed: $LOGS/$RTAG.exit is missing after the wait" >&2; return 1; }
  exit_status=$(cat "$LOGS/$RTAG.exit")
  [ "$exit_status" = "0" ] || { echo "self-test failed: $LOGS/$RTAG.exit reads $exit_status, expected 0" >&2; return 1; }
  [ "$(cat "$LOGS/$RTAG.session")" = "$session" ] \
    || { echo "self-test failed: $LOGS/$RTAG.session does not hold the resumed id $session" >&2; return 1; }
  grep -qF -- "--resume $session" "$LOGS/$RTAG.err" \
    || { echo "self-test failed: $LOGS/$RTAG.err does not show --resume $session" >&2; return 1; }
  ! grep -qF -- '--session-id' "$LOGS/$RTAG.err" \
    || { echo "self-test failed: $LOGS/$RTAG.err shows --session-id on a resume" >&2; return 1; }
  grep -q "^start $RTAG pid [0-9][0-9]* .* resume\$" "$LOGS/selftest-timeline.log" 2>/dev/null \
    || { echo "self-test failed: $LOGS/selftest-timeline.log has no start line ending in resume for $RTAG" >&2; return 1; }
  grep -qF -- "--name $RTAG" "$LOGS/$RTAG.err" \
    || { echo "self-test failed: $LOGS/$RTAG.err does not show --name $RTAG" >&2; return 1; }
  for flag in "--plugin-dir $base/plugin" '--max-budget-usd 1' '--append-system-prompt x' \
              '--model selftest-model' '--effort high'; do
    grep -qF -- "$flag" "$LOGS/$RTAG.err" \
      || { echo "self-test failed: $LOGS/$RTAG.err does not show $flag" >&2; return 1; }
  done
  selftest_worker_vars "$LOGS/$RTAG.err" "$WSDIR" present "" || return 1
  # The parser's refusals, status 2 and nothing started: --resume without
  # an id would otherwise launch a fresh session under the resume tag, and
  # an unknown argument would pass unnoticed.
  AUTOPILOT_LOGS=$LOGS AUTOPILOT_BATCH=selftest AUTOPILOT_CLAUDE=$AUTOPILOT_CLAUDE \
    bash "$self" "$RTAG-x" "$base" "$base/prompt.md" --resume 2>/dev/null; rc=$?
  [ "$rc" -eq 2 ] || { echo "self-test failed: a command line with --resume and no id returned $rc, expected 2" >&2; return 1; }
  AUTOPILOT_LOGS=$LOGS AUTOPILOT_BATCH=selftest AUTOPILOT_CLAUDE=$AUTOPILOT_CLAUDE \
    bash "$self" "$RTAG-x" "$base" "$base/prompt.md" --bogus 2>/dev/null; rc=$?
  [ "$rc" -eq 2 ] || { echo "self-test failed: a command line with an unknown argument returned $rc, expected 2" >&2; return 1; }
  [ ! -f "$LOGS/$RTAG-x.session" ] \
    || { echo "self-test failed: a refused command line wrote $LOGS/$RTAG-x.session" >&2; return 1; }
  # A resume with AUTOPILOT_PLUGIN_DIR unset, and one with it the empty
  # string, through the command line: a resume builds its flags on the same
  # path, and the skill resumes a repo-mode worker with the empty string, so
  # each is read for --plugin-dir as the fresh launches are.
  for PRTAG in "$TAG-r2" "$TAG-r3"; do
    if [ "$PRTAG" = "$TAG-r2" ]; then
      plugin_case=unset
      AUTOPILOT_LOGS=$LOGS AUTOPILOT_BATCH=selftest AUTOPILOT_CLAUDE=$AUTOPILOT_CLAUDE \
        bash "$self" "$PRTAG" "$base" "$base/prompt.md" --resume "$session"; rc=$?
    else
      plugin_case="set to the empty string"
      AUTOPILOT_LOGS=$LOGS AUTOPILOT_BATCH=selftest AUTOPILOT_CLAUDE=$AUTOPILOT_CLAUDE \
      AUTOPILOT_PLUGIN_DIR="" \
        bash "$self" "$PRTAG" "$base" "$base/prompt.md" --resume "$session"; rc=$?
    fi
    [ "$rc" -eq 0 ] || { echo "self-test failed: the resume launch of $PRTAG through the command line returned $rc, expected 0" >&2; return 1; }
    n=0; until [ -f "$LOGS/$PRTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
    [ -f "$LOGS/$PRTAG.exit" ] || { echo "self-test failed: $LOGS/$PRTAG.exit is missing after the wait" >&2; return 1; }
    grep -qF -- "--name $PRTAG" "$LOGS/$PRTAG.err" \
      || { echo "self-test failed: $LOGS/$PRTAG.err does not show --name $PRTAG" >&2; return 1; }
    ! grep -qF -- '--plugin-dir' "$LOGS/$PRTAG.err" \
      || { echo "self-test failed: $LOGS/$PRTAG.err shows --plugin-dir on a resume with AUTOPILOT_PLUGIN_DIR $plugin_case" >&2; return 1; }
  done
  # A resume with AUTOPILOT_WORKSPACE the empty string: the marker still
  # reads 1 and the roots hold no workspace entry, as on a fresh launch.
  W3TAG=$TAG-r4
  AUTOPILOT_LOGS=$LOGS AUTOPILOT_BATCH=selftest AUTOPILOT_CLAUDE=$AUTOPILOT_CLAUDE \
  AUTOPILOT_WORKSPACE="" \
    bash "$self" "$W3TAG" "$base" "$base/prompt.md" --resume "$session"; rc=$?
  [ "$rc" -eq 0 ] || { echo "self-test failed: the resume launch of $W3TAG through the command line returned $rc, expected 0" >&2; return 1; }
  n=0; until [ -f "$LOGS/$W3TAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ -f "$LOGS/$W3TAG.exit" ] || { echo "self-test failed: $LOGS/$W3TAG.exit is missing after the wait" >&2; return 1; }
  grep -qF -- "--name $W3TAG" "$LOGS/$W3TAG.err" \
    || { echo "self-test failed: $LOGS/$W3TAG.err does not show --name $W3TAG" >&2; return 1; }
  selftest_worker_vars "$LOGS/$W3TAG.err" "$WSDIR" absent "" || return 1

  # The batch-name default, with AUTOPILOT_BATCH unset: the tag's prefix
  # before its last "-s", so a batch name that itself holds "-s" keeps its
  # name in the timeline's file name.
  # The same launch starts with a stale .exit from an earlier launch under
  # the tag in place: the file is gone right after the launch and holds this
  # worker's status after the wait. A stale one would read as this worker's
  # completion before it starts, with an empty .json, so the skill would
  # count the worker dead and resume it beside the live one.
  BTAG=self-s-test-s1
  unset AUTOPILOT_BATCH
  printf '7\n' > "$LOGS/$BTAG.exit" || die "cannot write a stale $LOGS/$BTAG.exit"
  launch "$BTAG" "$base" "$base/prompt.md" ""
  [ ! -f "$LOGS/$BTAG.exit" ] \
    || { echo "self-test failed: a stale $LOGS/$BTAG.exit survived the launch and would read as this worker's completion" >&2; return 1; }
  n=0; until [ -f "$LOGS/$BTAG.exit" ] || [ "$n" -ge 30 ]; do sleep 2; n=$((n+1)); done
  [ "$(cat "$LOGS/$BTAG.exit" 2>/dev/null)" = "0" ] \
    || { echo "self-test failed: $LOGS/$BTAG.exit does not read 0 after the wait" >&2; return 1; }
  grep -q "^start $BTAG pid [0-9][0-9]* " "$LOGS/self-s-test-timeline.log" 2>/dev/null \
    || { echo "self-test failed: $LOGS/self-s-test-timeline.log has no start line for $BTAG (the batch-name default)" >&2; return 1; }
  grep -q "^end   $BTAG exit 0\$" "$LOGS/self-s-test-timeline.log" 2>/dev/null \
    || { echo "self-test failed: $LOGS/self-s-test-timeline.log has no end line for $BTAG" >&2; return 1; }

  echo "self-test passed"
  return 0
}

case ${1:-} in
  --self-test)
    self_test
    exit $?
    ;;
  ''|-h|--help)
    usage
    ;;
esac

[ $# -ge 3 ] || usage
tag=$1; dir=$2; prompt_file=$3
shift 3
resume=""
while [ $# -gt 0 ]; do
  case $1 in
    --resume)
      # An empty id would pass the count test and then launch a fresh
      # session under the resume tag, with no session to continue.
      [ -n "${2:-}" ] || die "--resume needs a session id"
      resume=$2
      shift 2
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

launch "$tag" "$dir" "$prompt_file" "$resume"
