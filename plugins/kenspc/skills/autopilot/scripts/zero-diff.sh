#!/bin/bash
# zero-diff.sh — the autopilot skill's zero-diff check. Compares the paths a
# batch promised not to touch between the baseline and HEAD.
#
# Usage
#   zero-diff.sh <baseline> <paths file>
#
#   <baseline>    the batch's baseline commit
#   <paths file>  one repository-relative path per line (the `Zero diff:`
#                 paths, which the main session writes to
#                 _prompts/<batch>-zero-diff.txt); each line is trimmed at
#                 both ends, and blank lines are skipped. A path written
#                 with a leading `!` is an exclusion: `dir` and
#                 `!dir/file.txt` compare everything under dir but that
#                 file. A path whose own name begins with `!` cannot be
#                 listed, since the `!` is read as the exclusion mark.
#
# Run inside the repository; the paths are read from its top level.
#
# Output and exit codes
#   Each path absent at the baseline is named on stderr, an exclusion by
#   its path with the `!` removed. Then "compared: <n> paths, <m> excluded"
#   is printed, n being the number of paths read without a `!` and m the
#   number with one, followed by `git diff --stat <baseline> HEAD --
#   <pathspecs>`, each path passed as `:(literal)<path>` and each exclusion
#   as `:(exclude,literal)<path>`, so `app/[id]/page.tsx` is not a glob in
#   either, and the stat wide enough that a long path is not shortened to
#   `.../`. Pathspec magic needs git 1.9 or later.
#   0  the stat is empty: no listed path changed
#   1  the stat is not empty: it names the changed paths
#   2  a usage error — the wrong arguments, an unreadable paths file, a
#      paths file with no path once blank lines are skipped, a paths file
#      of exclusions only, a `!` with no path after it, a baseline that is
#      not a commit, or a git command that fails; the reason goes to stderr
#
# Why this script: a zero-diff check typed as one shell line passed its
# paths as one word under zsh, so git compared a single path that matched
# nothing and printed nothing — a pass with nothing compared. Here the
# paths travel as an array, one argument each, and the count printed
# before the stat shows how many were compared. A paths file with no path
# is refused because `git diff` with no path after `--` compares the whole
# tree, and one of exclusions only because `git diff` with only exclusions
# compares everything else.
#
# Runs under the bash 3.2 macOS ships: no bash 4 feature.

set -u

if [ "$#" -ne 2 ]; then
  echo "usage: zero-diff.sh <baseline> <paths file>" >&2
  exit 2
fi
baseline=$1
list=$2

if [ ! -f "$list" ] || [ ! -r "$list" ]; then
  echo "zero-diff.sh: cannot read the paths file: $list" >&2
  exit 2
fi

paths=()
while IFS= read -r line || [ -n "$line" ]; do
  line=${line%$'\r'}
  # Trim each end: a path split from a comma-separated field keeps the
  # space after the comma, and as written it would match nothing.
  line=${line#"${line%%[![:space:]]*}"}
  line=${line%"${line##*[![:space:]]}"}
  case $line in
    *[![:space:]]*) paths[${#paths[@]}]=$line ;;
  esac
done < "$list"

if [ "${#paths[@]}" -eq 0 ]; then
  echo "zero-diff.sh: the paths file holds no path: $list" >&2
  exit 2
fi

# The pathspecs git diff reads: each path literal, each `!` path a literal
# exclusion.
specs=()
included=0
excluded=0
for p in "${paths[@]}"; do
  case $p in
    '!')
      echo "zero-diff.sh: an exclusion with no path: $list" >&2
      exit 2
      ;;
    '!'*)
      specs[${#specs[@]}]=":(exclude,literal)${p#!}"
      excluded=$((excluded + 1))
      ;;
    *)
      specs[${#specs[@]}]=":(literal)$p"
      included=$((included + 1))
      ;;
  esac
done
if [ "$included" -eq 0 ]; then
  echo "zero-diff.sh: the paths file holds exclusions only, which would compare everything else: $list" >&2
  exit 2
fi

if ! top=$(git rev-parse --show-toplevel 2>/dev/null) || ! cd -- "$top"; then
  echo "zero-diff.sh: not inside a git repository" >&2
  exit 2
fi
if ! git rev-parse --verify --quiet "${baseline}^{commit}" >/dev/null; then
  echo "zero-diff.sh: the baseline is not a commit: $baseline" >&2
  exit 2
fi

for p in "${paths[@]}"; do
  p=${p#!}
  if ! git cat-file -e "${baseline}:${p}" 2>/dev/null; then
    echo "zero-diff.sh: absent at the baseline: $p" >&2
  fi
done

echo "compared: $included paths, $excluded excluded"
if ! stat=$(git diff --stat=1000 --stat-graph-width=20 "$baseline" HEAD -- "${specs[@]}"); then
  echo "zero-diff.sh: git diff failed" >&2
  exit 2
fi
if [ -n "$stat" ]; then
  printf '%s\n' "$stat"
  exit 1
fi
exit 0
