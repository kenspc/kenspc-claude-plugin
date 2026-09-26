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
# /dev/null. A fresh launch passes --session-id <uuid>. No model flag and no
# continue flag are ever passed: the worker follows the session's model, and
# a resume names its session explicitly.
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
# copied driver's self-test at every batch start. A caller who sets
# AUTOPILOT_CLAUDE to a stub of their own exercises the failure path.
#
# Exit status of a launch: 0 once the worker has been started; 2 on a usage
# or environment error (nothing started). The worker's own status goes to
# <tag>.exit. Self-test: 0 on pass, 1 on the first missing or wrong item.
#
# Bash 3.2 (the one macOS ships): no associative arrays, no array-reading
# builtins, no case-modifying expansions; POSIX tools plus uuidgen or python3
# for the UUID.

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
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr 'A-Z' 'a-z'
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
  local tag dir prompt_file resume logs batch exe prompt session pid stamp extra
  tag=$1; dir=$2; prompt_file=$3; resume=$4
  logs=${AUTOPILOT_LOGS:-$HOME/Projects/_smoke/_logs}
  batch=${AUTOPILOT_BATCH:-${tag%-s*}}
  exe=${AUTOPILOT_CLAUDE:-claude}

  [ -n "$tag" ] || die "the tag is empty"
  [ -d "$dir" ] || die "cannot cd to $dir"
  [ -f "$prompt_file" ] || die "no prompt file $prompt_file"
  mkdir -p "$logs" || die "cannot create the logs directory $logs"
  logs=$(cd "$logs" && pwd) || die "cannot enter the logs directory $logs"
  prompt=$(cat "$prompt_file") || die "cannot read $prompt_file"

  if [ -n "$resume" ]; then
    session=$resume
  else
    session=$(new_uuid) || exit 2
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
  if [ -n "$resume" ]; then
    cmd=("$exe" -p --resume "$session" "$prompt" "${args[@]}")
    extra="$extra resume"
  else
    cmd=("$exe" -p "$prompt" --session-id "$session" "${args[@]}")
  fi
  if command -v caffeinate >/dev/null 2>&1; then
    cmd=(caffeinate -i "${cmd[@]}")
  fi

  cd "$dir" || die "cannot cd to $dir"
  # A stale exit file from an earlier launch under the same tag would read as
  # this worker's completion before it starts; nothing else is removed.
  rm -f "$logs/$tag.exit"
  (
    trap '' HUP
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

# self_test: launch a stub through the same path and check every file the
# header names. The logs directory is always a fresh directory under $TMPDIR,
# whatever AUTOPILOT_LOGS says, so a self-test writes nothing under the
# workspace. Passing: every file is present with the expected content and the
# timeline holds both lines. It fails, in this order, on a missing .session,
# a missing .pid, a .json that is missing, unparseable, or without "result",
# a missing .err, a .exit that is missing or does not read 0, and a timeline
# without its start or end line — naming the first item that fails.
self_test() {
  local base LOGS TAG n exit_status
  base=$(mktemp -d "${TMPDIR:-/tmp}/autopilot-selftest.XXXXXX") || die "cannot create a directory under ${TMPDIR:-/tmp}"
  LOGS=$base/logs
  mkdir -p "$LOGS" || die "cannot create $LOGS"

  if [ -z "${AUTOPILOT_CLAUDE:-}" ]; then
    mkdir -p "$base/stub" || die "cannot create $base/stub"
    cat > "$base/stub/claude" <<'STUB'
#!/bin/sh
# Stub executable for run.sh --self-test: echoes its arguments to stderr,
# prints a result object to stdout, sleeps one second, exits 0.
echo "$@" >&2
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

  AUTOPILOT_LOGS=$LOGS
  AUTOPILOT_BATCH=selftest
  TAG=selftest-s1
  printf 'Reply ok and stop.\n' > "$base/prompt.md" || die "cannot write the prompt file"
  echo "self-test: logs directory $LOGS"
  echo "self-test: executable $AUTOPILOT_CLAUDE"
  launch "$TAG" "$base" "$base/prompt.md" ""

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
      [ $# -ge 2 ] || die "--resume needs a session id"
      resume=$2
      shift 2
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

launch "$tag" "$dir" "$prompt_file" "$resume"
