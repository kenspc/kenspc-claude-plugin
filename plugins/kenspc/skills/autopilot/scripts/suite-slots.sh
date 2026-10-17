#!/bin/bash
# suite-slots.sh — the autopilot skill's suite-slot wrapper. Runs a heavy
# test suite only while fewer than N are running on the whole machine, N
# being the caller's own limit, through a lock directory every batch on the
# machine shares.
#
# Usage
#   suite-slots.sh run [--limit <n>] [--wait <seconds>] -- <command> [<arg>...]
#
#   --limit <n>     the most holders this caller enters beside, a positive
#                   integer; without it, KENSPC_AUTOPILOT_SUITE_LIMIT
#   --wait <s>      how long to wait for a slot, a whole number of seconds;
#                   90 by default
#   <command>       run as a background child with KENSPC_SUITE_SLOT_HELD=1
#                   exported, and waited for
#
# Environment
#   KENSPC_AUTOPILOT_SUITE_LIMIT  the limit when --limit is not given
#   KENSPC_AUTOPILOT_SUITE_LOG    a file to append one line per event to;
#                                 unset or empty, nothing is logged
#   KENSPC_SUITE_SLOT_HELD        1 inside a wrapped command: a nested call
#                                 runs its command at once and takes no slot
#   KENSPC_SUITE_SLOTS_DIR        the lock directory, in place of
#                                 /tmp/kenspc-suite-slots; it exists so the
#                                 guard's fixtures never touch the
#                                 machine's real lock
#
# Exit codes
#   the command's own status, once it ran (128 + n when the wrapper was
#      stopped by signal n)
#   75 busy: no slot within --wait seconds. A "suite-slots: busy after <s>s;
#      held by:" line, one line per holder after it (age, cwd, command),
#      goes to stderr; that line, not the code, tells this apart from a
#      command that exits 75 itself. The caller runs the same line again.
#   2  a usage error — no run, no --, no command, a limit that is not a
#      positive integer, a wait that is not a whole number — or a lock
#      directory that is not a directory, is owned by another user, or
#      cannot be written, or a ps that prints no start time for the
#      wrapper itself; the reason goes to stderr
#
# The lock directory, created with mode 700 when missing
#   mutex/            a short mutex, taken with mkdir (atomic on every POSIX
#                     file system) around each count and each holder write
#   mutex/owner       the pid of the wrapper holding the mutex
#   holder-<pid>      one per slot held, <pid> the wrapper's; key=value
#                     lines in this order: wrapper_pid, wrapper_start,
#                     command_pid, command_start, taken, cwd, command, each
#                     value running to the end of its line. The starts are
#                     `ps -o lstart=` output read in UTC; taken is the
#                     epoch second the slot was taken; command is the first
#                     120 characters.
#                     Written under the mutex with the two command fields
#                     empty, then rewritten once the command has started;
#                     each write goes to .tmp-<pid> and is renamed over the
#                     holder file with mv, so a counting wrapper never reads
#                     a half-written file. The layout is shared by every
#                     plugin version on the machine: a change to it is a
#                     breaking change.
#   reclaimed-holder-<pid>  a stale holder moved aside, kept as the evidence
#                     behind the log's reclaimed line
#
# Taking a slot: under the mutex, count the live holder-* files; enter when
# fewer than this caller's own N are live, else release the mutex and poll
# again about once a second. Why a count and not numbered slots: with slot
# directories slot-1..slot-N, a caller whose N is 2 could take a free slot-1
# while slot-2 and a looser caller's slot-3 are held, making three holders;
# each caller must enter only while fewer than its own N are held.
#
# Stale holders: a holder is stale when neither its wrapper pid nor its
# command pid is alive with the start time the file records; a holder whose
# command fields are still empty is judged by its wrapper pid alone. A
# stale holder is renamed reclaimed-<its name>, which the count does not
# match, and is not counted. Why both pids: a wrapper killed with SIGKILL
# runs no trap and leaves its command running, and that command still uses
# the ports. Why the start time: a pid reused after a reboot or a long run
# would otherwise keep a dead holder alive. Why the start is read under
# TZ=UTC: ps prints it in the caller's time zone, so two wrappers started
# under different TZ values would each judge the other's live holder stale.
#
# Stale mutex: reclaimed when its owner pid is dead, or when it has no
# owner (or an empty one) and is older than 10 seconds by its modification
# time (stat -f %m, then stat -c %Y): a taker killed between the mkdir and
# the owner write leaves it so.
#
# Running the command: the wrapper waits for its background child with
# wait, so its traps run while the child does. On EXIT it removes its
# holder file; on INT, TERM, and HUP it first sends SIGTERM to the child
# and waits for it. Why SIGTERM whatever signal arrived: a background child
# of a non-interactive bash ignores SIGINT, so a forwarded SIGINT would
# leave the suite running.
#
# A nested call: with KENSPC_SUITE_SLOT_HELD=1 already set, the command
# runs at once and takes no slot. Why: an acceptance command that is
# itself wrapped, run through the wrapper again, would otherwise wait on
# its own slot forever when N is 1.
#
# Why 90 seconds of wait by default: it stays under the Bash tool's default
# two-minute timeout. A call killed by that timeout while waiting returns
# no busy line, and the caller would not know to run it again.
#
# The log: with KENSPC_AUTOPILOT_SUITE_LOG set, one line per event,
#   <UTC time> <event> pid <pid> waited <s>s holders <k> — <command, first 80 characters>
# the events being acquired, busy, released <status>, nested, and
# reclaimed <stale pid>. <k> is the live holders counted, this caller's
# own not included, or for released and nested the holder files present,
# its own included.
#
# Unchecked: a lock directory owned by another user is refused (exit 2,
# naming the owner), but the guard cannot chown, so no fixture reaches that
# branch.
#
# Known gaps the wrapper accepts:
#   - SIGTERM is forwarded to the child's pid only. A grandchild that does
#     not pass it on — a test host, or a suite that `sh <file>` waits on in
#     the foreground — can keep the ports in use after the holder has
#     turned stale (both its pids gone), until that grandchild ends.
#     Running the child in a process group of its own and signalling the
#     group would close this, at the cost of job control in a
#     non-interactive script.
#   - Two waiters that both see a dead mutex owner can each reclaim the
#     mutex, one removing the other's fresh one, so both count and write
#     holders and N + 1 holders can run. The window needs a taker killed
#     inside a critical section of a few milliseconds and two waiters
#     polling in the same instant.
#
# Portability: bash 3.2 as macOS ships it, no bash 4 feature, and mkdir as
# the only lock, since macOS ships no file-locking command. Beyond POSIX it
# uses `ps -o lstart=`, `date +%s`, and stat in its BSD and GNU spellings,
# which macOS and Linux both provide.

set -u

LOCK_DIR=${KENSPC_SUITE_SLOTS_DIR:-/tmp/kenspc-suite-slots}
MUTEX=$LOCK_DIR/mutex
DEFAULT_WAIT_SECONDS=90
POLL_SECONDS=1
MUTEX_TRIES=10
MUTEX_TRY_SECONDS=0.1
MUTEX_STALE_SECONDS=10
EX_BUSY=75
HOLDER_COMMAND_CHARS=120
LOG_COMMAND_CHARS=80
NL='
'

usage() {
  [ "$#" -gt 0 ] && echo "suite-slots.sh: $1" >&2
  echo "usage: suite-slots.sh run [--limit <n>] [--wait <seconds>] -- <command> [<arg>...]" >&2
  exit 2
}

# --- Arguments ---------------------------------------------------------

[ "${1:-}" = run ] || usage "the first argument must be run"
shift
limit=
wait_seconds=$DEFAULT_WAIT_SECONDS
seen_dashes=0
while [ "$#" -gt 0 ]; do
  case $1 in
    --limit)
      [ "$#" -ge 2 ] || usage "--limit needs a value"
      limit=$2; shift 2 ;;
    --wait)
      [ "$#" -ge 2 ] || usage "--wait needs a value"
      wait_seconds=$2; shift 2 ;;
    --)
      seen_dashes=1; shift; break ;;
    *)
      usage "unknown argument: $1" ;;
  esac
done
[ "$seen_dashes" -eq 1 ] || usage "no -- before the command"
[ "$#" -gt 0 ] || usage "no command after --"
[ -n "$limit" ] || limit=${KENSPC_AUTOPILOT_SUITE_LIMIT:-}
case $limit in
  '') usage "no limit: give --limit or set KENSPC_AUTOPILOT_SUITE_LIMIT" ;;
  0*|*[!0-9]*) usage "the limit is not a positive integer: $limit" ;;
esac
case $wait_seconds in
  ''|*[!0-9]*) usage "the wait is not a whole number of seconds: $wait_seconds" ;;
esac

# The command as one line of text, for the holder file and the log.
cmd_text=$*
cmd_text=${cmd_text//$NL/ }

# --- Helpers -----------------------------------------------------------

now() { date +%s; }

# start_of <pid>: the process's start time in UTC, spaces squeezed; empty
# when no such process runs.
start_of() {
  [ -n "$1" ] || return 0
  LC_ALL=C TZ=UTC ps -o lstart= -p "$1" 2>/dev/null | sed -e 's/  */ /g' -e 's/^ //' -e 's/ $//'
}

# alive_as <pid> <start>: true when <pid> runs and started at <start>.
alive_as() {
  [ -n "$1" ] && [ -n "$2" ] || return 1
  [ "$(start_of "$1")" = "$2" ]
}

# holder_files: the number of holder-* files present, live or not.
holder_files() {
  local f k=0
  for f in "$LOCK_DIR"/holder-*; do
    [ -f "$f" ] && k=$((k + 1))
  done
  echo "$k"
}

log_event() { # <event> <waited> <holders>
  [ -n "${KENSPC_AUTOPILOT_SUITE_LOG:-}" ] || return 0
  if ! printf '%s %s pid %s waited %ss holders %s — %s\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" "$$" "$2" "$3" \
      "${cmd_text:0:$LOG_COMMAND_CHARS}" >> "$KENSPC_AUTOPILOT_SUITE_LOG" 2>/dev/null; then
    echo "suite-slots: cannot append to the log: $KENSPC_AUTOPILOT_SUITE_LOG" >&2
  fi
}

# --- A nested call -----------------------------------------------------

if [ "${KENSPC_SUITE_SLOT_HELD:-}" = 1 ]; then
  log_event nested 0 "$(holder_files)"
  "$@"
  exit $?
fi

# --- The lock directory ------------------------------------------------

if [ ! -e "$LOCK_DIR" ] && [ ! -L "$LOCK_DIR" ]; then
  # Another wrapper may create it in the same instant; the checks below
  # decide.
  mkdir -m 700 "$LOCK_DIR" 2>/dev/null
fi
if [ ! -d "$LOCK_DIR" ]; then
  echo "suite-slots: the lock directory is not a directory: $LOCK_DIR" >&2
  exit 2
fi
if [ ! -O "$LOCK_DIR" ]; then
  echo "suite-slots: the lock directory $LOCK_DIR is owned by $(ls -ld "$LOCK_DIR" | awk '{print $3}'), not by this user" >&2
  exit 2
fi
if [ ! -w "$LOCK_DIR" ]; then
  echo "suite-slots: the lock directory cannot be written: $LOCK_DIR" >&2
  exit 2
fi

# --- The mutex ---------------------------------------------------------

mutex_mine=0

# mutex_stale: true when the mutex is held by a dead owner, or has no
# owner and is older than MUTEX_STALE_SECONDS.
mutex_stale() {
  local owner mtime
  [ -d "$MUTEX" ] || return 1
  owner=$(cat "$MUTEX/owner" 2>/dev/null)
  if [ -n "$owner" ]; then
    ps -p "$owner" >/dev/null 2>&1 && return 1
    return 0
  fi
  # GNU stat reads -f as "file system" and prints that for the directory,
  # so a non-number falls through to the GNU spelling.
  mtime=$(stat -f %m "$MUTEX" 2>/dev/null)
  case $mtime in
    ''|*[!0-9]*) mtime=$(stat -c %Y "$MUTEX" 2>/dev/null) ;;
  esac
  case $mtime in
    ''|*[!0-9]*) return 1 ;;
  esac
  [ $(( $(now) - mtime )) -gt "$MUTEX_STALE_SECONDS" ]
}

# take_mutex: a few quick tries, reclaiming a stale mutex on the way.
take_mutex() {
  local i=0
  while [ "$i" -lt "$MUTEX_TRIES" ]; do
    if mkdir "$MUTEX" 2>/dev/null; then
      if printf '%s\n' "$$" > "$MUTEX/owner" 2>/dev/null; then
        mutex_mine=1
        return 0
      fi
      rmdir "$MUTEX" 2>/dev/null
      return 1
    fi
    i=$((i + 1))
    if mutex_stale; then
      rm -f "$MUTEX/owner"
      rmdir "$MUTEX" 2>/dev/null
      continue
    fi
    sleep "$MUTEX_TRY_SECONDS"
  done
  return 1
}

release_mutex() {
  [ "$mutex_mine" -eq 1 ] || return 0
  if [ "$(cat "$MUTEX/owner" 2>/dev/null)" = "$$" ]; then
    rm -f "$MUTEX/owner"
    rmdir "$MUTEX" 2>/dev/null
  fi
  mutex_mine=0
}

# --- Holders -----------------------------------------------------------

# read_holder <file>: sets the h_* fields; false when it cannot be read.
read_holder() {
  local line
  h_wpid= h_wstart= h_cpid= h_cstart= h_taken= h_cwd= h_cmd=
  [ -f "$1" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in
      wrapper_pid=*) h_wpid=${line#*=} ;;
      wrapper_start=*) h_wstart=${line#*=} ;;
      command_pid=*) h_cpid=${line#*=} ;;
      command_start=*) h_cstart=${line#*=} ;;
      taken=*) h_taken=${line#*=} ;;
      cwd=*) h_cwd=${line#*=} ;;
      command=*) h_cmd=${line#*=} ;;
    esac
  done 2>/dev/null < "$1" || return 1
}

holder_alive() {
  alive_as "$h_wpid" "$h_wstart" && return 0
  [ -n "$h_cpid" ] && alive_as "$h_cpid" "$h_cstart"
}

# scan_holders <reclaim 0|1>: sets live and held_by (one line per live
# holder); with 1, moves each stale holder aside and logs it.
scan_holders() {
  local f t age
  live=0
  held_by=
  t=$(now)
  for f in "$LOCK_DIR"/holder-*; do
    read_holder "$f" || continue
    if holder_alive; then # live-holder check
      live=$((live + 1))
      case $h_taken in
        ''|*[!0-9]*) age=unknown ;;
        *) age=$((t - h_taken))s ;;
      esac
      held_by="$held_by$NL  age $age, cwd $h_cwd, command $h_cmd"
    elif [ "$1" -eq 1 ]; then
      if mv -f "$f" "$LOCK_DIR/reclaimed-${f##*/}" 2>/dev/null; then
        log_event "reclaimed ${h_wpid:-unknown}" 0 "$live"
      fi
    fi
  done
}

holder=$LOCK_DIR/holder-$$
holder_tmp=$LOCK_DIR/.tmp-$$
holder_written=0
wrapper_start=$(start_of "$$")
# Why refuse: without a start time no holder can be judged alive, so every
# live holder would read as stale and be reclaimed, and the count would let
# every caller in. A ps without -o lstart (BusyBox, MSYS) prints nothing.
if [ -z "$wrapper_start" ]; then
  echo "suite-slots: ps -o lstart= printed no start time for this wrapper, so no holder's liveness can be judged" >&2
  exit 2
fi
cwd=$(pwd)
cwd=${cwd//$NL/ }

write_holder() { # <command pid> <command start>
  {
    printf 'wrapper_pid=%s\n' "$$"
    printf 'wrapper_start=%s\n' "$wrapper_start"
    printf 'command_pid=%s\n' "$1"
    printf 'command_start=%s\n' "$2"
    printf 'taken=%s\n' "$taken"
    printf 'cwd=%s\n' "$cwd"
    printf 'command=%s\n' "${cmd_text:0:$HOLDER_COMMAND_CHARS}"
  } > "$holder_tmp" 2>/dev/null && mv -f "$holder_tmp" "$holder" 2>/dev/null
}

# --- Release, on every way out -----------------------------------------

child=
waited=0
release() {
  rm -f "$holder_tmp"
  [ "$holder_written" -eq 1 ] && rm -f "$holder" # release on exit
  release_mutex
}

on_signal() { # <signal number>
  trap '' INT TERM HUP
  if [ -n "$child" ]; then
    kill -TERM "$child" 2>/dev/null
    wait "$child" 2>/dev/null
  fi
  [ "$holder_written" -eq 1 ] && log_event "released $((128 + $1))" "$waited" "$(holder_files)"
  release
  exit $((128 + $1))
}

trap release EXIT
trap 'on_signal 1' HUP
trap 'on_signal 2' INT
trap 'on_signal 15' TERM

# --- Taking a slot -----------------------------------------------------

t0=$(now)
while :; do
  if take_mutex; then
    scan_holders 1
    if [ "$live" -lt "$limit" ]; then # count check
      taken=$(now)
      waited=$((taken - t0))
      if ! write_holder "" ""; then
        release_mutex
        echo "suite-slots: cannot write the holder file: $holder" >&2
        exit 2
      fi
      holder_written=1
      release_mutex
      log_event acquired "$waited" "$live"
      break
    fi
    release_mutex
  else
    scan_holders 0
  fi
  waited=$(( $(now) - t0 ))
  if [ "$waited" -ge "$wait_seconds" ]; then
    echo "suite-slots: busy after ${waited}s; held by:${held_by:- (none readable: the mutex stayed held)}" >&2
    log_event busy "$waited" "$live"
    exit "$EX_BUSY"
  fi
  sleep "$POLL_SECONDS"
done

# --- Running the command -----------------------------------------------

export KENSPC_SUITE_SLOT_HELD=1
# A background child of a non-interactive bash reads /dev/null unless its
# standard input is given explicitly.
"$@" 0<&0 &
child=$!
write_holder "$child" "$(start_of "$child")"
wait "$child"
rc=$?
child=
log_event "released $rc" "$waited" "$(holder_files)"
exit "$rc"
