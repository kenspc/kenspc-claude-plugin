#!/bin/bash
# temp-candidates.sh — the autopilot skill's temp-folder sweep, read-only.
# Records the temp folder's entries before a batch starts, and at the end
# lists the entries the batch made there, each with the evidence that it is
# the batch's. It deletes nothing: the main session removes what it lists,
# naming each path literally.
#
# Usage
#   temp-candidates.sh --snapshot <temp folder> <before list>
#   temp-candidates.sh <temp folder> <before list> <cmds dir|-> <root> [<root>...]
#
#   <temp folder>  absolute, not /: ${TMPDIR:-/tmp} with any trailing /
#                  removed, as the main session's own shell sees it
#   <before list>  --snapshot writes the folder's top-level entry names to
#                  it, one per line; the sweep reads it back
#   <cmds dir>     the batch's extracted acceptance commands
#                  (_prompts/<batch>-s4-cmds), or - when there are none
#   <root>         a directory whose clones are the batch's: the repository
#                  root, and in plugin mode each seed project
#
# An entry is listed only when it is new — absent from the before list —
# is no symbolic link, is owned by the user running the script, and has
# one of three pieces of evidence, the reason column:
#   self-test        a directory named autopilot-selftest.*, which the
#                    driver's --self-test leaves behind
#   prefix <p>-      its name starts with <p>-, where a *.cmd file of the
#                    cmds dir names $TMPDIR/<p>-, ${TMPDIR}/<p>-, or
#                    ${TMPDIR%/}/<p>- (<p> the letters, digits, _ and .
#                    before the first -)
#   clone of <root>  a directory that is, or whose direct subdirectory is,
#                    a git repository whose remote.origin.url, read from
#                    its own config, is an absolute path that resolves with
#                    pwd -P to a <root> resolved the same way
#
# Output and exit codes
#   --snapshot: prints "entries: <n>"; 0
#   sweep: one line per listed entry, "<absolute path><TAB><reason>", the
#   path being <temp folder>/<name>; then "candidates: <n>, left: <k>", k
#   counting the new entries without evidence, which are not the batch's to
#   remove; a name holding a tab or a newline is skipped and named on stderr
#   0  the listing is complete (n may be 0)
#   2  a usage error — the wrong arguments, a temp folder that is not an
#      absolute directory other than /, an unreadable before list, a cmds
#      dir other than - that is not a directory, or a root that is not a
#      directory; the reason goes to stderr
#
# Why this script: two batches share one temp folder, and its clones and
# builds (about 1 GB and 41,000 files each) piled up until the boot-time
# cleanup of the folder held the login screen for minutes. The batch's own
# entries are told apart by evidence a mistaken guess cannot supply — new
# since the start, and named by the batch's commands or cloned from its
# repository — so another track's directories, and anything older than the
# batch, are never listed. Read-only, so the deletion stays in front of the
# reader with every path written out, never a variable that could expand
# to an empty string.
#
# Runs under the bash 3.2 macOS ships: no bash 4 feature.

set -u

TAB=$(printf '\t')
NL='
'

usage() {
  echo "usage: temp-candidates.sh --snapshot <temp folder> <before list>" >&2
  echo "       temp-candidates.sh <temp folder> <before list> <cmds dir|-> <root> [<root>...]" >&2
  exit 2
}

# check_tmp <temp folder>: the folder must be an absolute directory, not /.
check_tmp() {
  case $1 in
    /*) ;;
    *) echo "temp-candidates.sh: the temp folder is not absolute: $1" >&2; exit 2 ;;
  esac
  if [ "$1" = / ] || [ ! -d "$1" ]; then
    echo "temp-candidates.sh: not a temp folder this script reads: $1" >&2
    exit 2
  fi
}

# names <temp folder>: every top-level entry name, one per line, the
# hidden ones included; a name holding a newline cannot be one line, so it
# is skipped and named on stderr.
names() {
  local e n
  for e in "$1"/* "$1"/.[!.]* "$1"/..?*; do
    [ -e "$e" ] || [ -L "$e" ] || continue
    n=${e##*/}
    case $n in
      *"$NL"*) echo "temp-candidates.sh: skipped a name holding a newline: $e" >&2; continue ;;
    esac
    printf '%s\n' "$n"
  done
}

if [ "${1:-}" = --snapshot ]; then
  [ "$#" -eq 3 ] || usage
  check_tmp "$2"
  if ! names "$2" > "$3"; then
    echo "temp-candidates.sh: cannot write the before list: $3" >&2
    exit 2
  fi
  echo "entries: $(wc -l < "$3" | tr -d ' ')"
  exit 0
fi

[ "$#" -ge 4 ] || usage
tmp=$1
before=$2
cmds=$3
shift 3
check_tmp "$tmp"
if [ ! -f "$before" ] || [ ! -r "$before" ]; then
  echo "temp-candidates.sh: cannot read the before list: $before" >&2
  exit 2
fi
if [ "$cmds" != - ] && [ ! -d "$cmds" ]; then
  echo "temp-candidates.sh: the cmds dir is not a directory: $cmds" >&2
  exit 2
fi

roots=()
for r in "$@"; do
  if ! p=$(cd -- "$r" 2>/dev/null && pwd -P); then
    echo "temp-candidates.sh: the root is not a directory: $r" >&2
    exit 2
  fi
  roots[${#roots[@]}]=$p
done

# The prefixes the batch's commands name under the temp folder.
prefixes=()
if [ "$cmds" != - ]; then
  for f in "$cmds"/*.cmd; do
    [ -f "$f" ] || continue
    for p in $(grep -o -E '(\$TMPDIR|\$\{TMPDIR\}|\$\{TMPDIR%/\})/[A-Za-z0-9_.]+-' "$f" \
               | sed -e 's|^.*/||' -e 's|-$||'); do
      known=0
      for q in ${prefixes[@]+"${prefixes[@]}"}; do
        [ "$q" = "$p" ] && known=1
      done
      [ "$known" -eq 1 ] || prefixes[${#prefixes[@]}]=$p
    done
  done
fi

# clone_root <git dir's work tree>: prints the root its origin resolves to.
clone_root() {
  local url p r
  url=$(git -C "$1" config --local --get remote.origin.url 2>/dev/null) || return 1
  # A local clone of `.` records <path>/., which cd and pwd -P resolve; a
  # URL is not a path, and its clone is never the batch's.
  case $url in /*) ;; *) return 1 ;; esac
  p=$(cd -- "$url" 2>/dev/null && pwd -P) || return 1
  for r in "${roots[@]}"; do
    if [ "$p" = "$r" ]; then
      printf '%s\n' "$r"
      return 0
    fi
  done
  return 1
}

n=0
left=0
while IFS= read -r name; do
  case $name in
    '') continue ;;
    *"$TAB"*)
      echo "temp-candidates.sh: skipped a name holding a tab: $name" >&2
      continue ;;
  esac
  if grep -qxF -- "$name" "$before"; then
    continue
  fi
  e=$tmp/$name
  reason=
  if [ ! -L "$e" ] && [ -O "$e" ]; then
    case $name in
      autopilot-selftest.*) [ -d "$e" ] && reason=self-test ;;
    esac
    if [ -z "$reason" ]; then
      for p in ${prefixes[@]+"${prefixes[@]}"}; do
        case $name in
          "$p"-*) reason="prefix $p-"; break ;;
        esac
      done
    fi
    if [ -z "$reason" ] && [ -d "$e" ]; then
      for g in "$e" "$e"/*/; do
        g=${g%/}
        [ -d "$g/.git" ] || [ -f "$g/.git" ] || continue
        if r=$(clone_root "$g"); then
          reason="clone of $r"
          break
        fi
      done
    fi
  fi
  if [ -n "$reason" ]; then
    printf '%s\t%s\n' "$e" "$reason"
    n=$((n + 1))
  else
    left=$((left + 1))
  fi
done <<EOF
$(names "$tmp")
EOF

echo "candidates: $n, left: $left"
exit 0
