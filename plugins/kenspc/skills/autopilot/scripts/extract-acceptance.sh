#!/bin/bash
# extract-acceptance.sh — the autopilot skill's acceptance extractor. Reads
# the `Acceptance:` field, or the `Release checks:` field, of a spec's
# `## Autopilot` section and writes one file per case, so S4 and S6 run each
# command from a file rather than from text retyped into their prompts.
#
# Usage
#   extract-acceptance.sh <spec file> <out dir> [<field>]
#
#   <spec file>  the spec as Phase 0 read it (the main session saves it to
#                _prompts/<batch>-spec.md)
#   <out dir>    created when missing; one file per sub-bullet of the field,
#                <nn> its position as two digits from 01:
#                  <nn>.cmd   the command, when the text before " — PASS: "
#                             is one code span
#                  <nn>.case  that text, otherwise (a case description)
#   <field>      `Acceptance` (the default) or `Release checks`: the field
#                read; both follow the same grammar
#
# The command is the text between the code span's backtick runs as it
# stands, except that one space is removed from each end when it both
# begins and ends with a space and is not all spaces (the CommonMark rule,
# so `` printf '`x`' `` gives printf '`x`'). A sub-bullet's continuation
# lines are joined to it with one space. The field's label may carry a
# note, `- Acceptance (<note>):` or `- Release checks (<note>):`,
# parentheses inside the note included.
#
# The lines of a fenced code block (up to three spaces of indent, then three
# or more backticks or tildes, closed by a run of the same character at
# least as long, as CommonMark has it), its fence lines included, are not
# read: a heading, a `## Autopilot` line, or an `Acceptance:` field inside
# one is no heading and no field. A fence line in column 0 still ends the
# field, as any line there does. Why: a spec kept Python scripts in fenced
# blocks of its `## Autopilot` section for the acceptance commands to read,
# and a comment line, `# usage: …` in column 0, read as the next heading
# ended the section nearly 200 lines before the field, so the batch stopped at
# acceptance after its implementation and review were paid for.
#
# Output and exit codes
#   0  prints "commands: <n>, cases: <m>", then a second line,
#      "span-led: none" or "span-led: <nn>, <nn>, …", naming each <nn>.case
#      whose text opens with a backtick run — an entry written as a code
#      span with words after it, which may say where or how the command
#      runs; `Acceptance: none` (or `Release checks: none`) writes no file
#      and prints "commands: 0, cases: 0" and "span-led: none"
#   2  a usage error (a <field> other than the two above, or more than three
#      arguments, included), an unreadable spec, no `## Autopilot` section,
#      no field of that name in it, or a field that is neither `none` nor a
#      list of sub-bullets; the reason, naming the field read, goes to
#      stderr and no file is written
#
# Why a second line rather than a new exit code: an exit other than 0 is a
# stop at every caller, and a span-led entry is a question for the user,
# not a malformed field. The counts stay alone on the first line, which
# every caller parses.
#
# Why this script: each main session wrote its own extractor, and they went
# wrong on the backtick delimiting — commands came out with a stray backtick
# at each end from a double-backtick span until a comparison caught them.
# One shipped extractor, run by the main session and by S4 alike and
# compared with cmp, removes that step from every batch's prompts.
#
# Runs under the bash 3.2 macOS ships and the awk it ships: no bash 4
# feature, no gawk extension.

set -u

if [ "$#" -ne 2 ] && [ "$#" -ne 3 ]; then
  echo "usage: extract-acceptance.sh <spec file> <out dir> [<field>]" >&2
  exit 2
fi
spec=$1
out=$2
field=${3:-Acceptance}
if [ "$field" != "Acceptance" ] && [ "$field" != "Release checks" ]; then
  echo "extract-acceptance.sh: the field must be Acceptance or Release checks, not: $field" >&2
  exit 2
fi

if [ ! -f "$spec" ] || [ ! -r "$spec" ]; then
  echo "extract-acceptance.sh: cannot read the spec file: $spec" >&2
  exit 2
fi
if ! mkdir -p -- "$out"; then
  echo "extract-acceptance.sh: cannot create the out dir: $out" >&2
  exit 2
fi

awk -v out="$out" -v field="$field" '
function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
function runlen(s, i,   n) {
  n = 0
  while (substr(s, i + n, 1) == "`") n++
  return n
}
# The command inside `text` when it is one code span, else the empty string
# with spanok set to 0.
function span(text,   n, L, i, r, cpos, inner) {
  spanok = 0
  n = runlen(text, 1)
  L = length(text)
  if (n == 0 || L <= 2 * n) return ""
  cpos = 0
  i = n + 1
  while (i <= L) {
    if (substr(text, i, 1) == "`") {
      r = runlen(text, i)
      if (r == n) { cpos = i; break }
      i += r
    } else {
      i++
    }
  }
  if (cpos == 0 || cpos + n - 1 != L) return ""
  inner = substr(text, n + 1, cpos - n - 1)
  if (length(inner) >= 2 && substr(inner, 1, 1) == " " && substr(inner, length(inner), 1) == " " && inner !~ /^ +$/) inner = substr(inner, 2, length(inner) - 2)
  spanok = 1
  return inner
}
function addentry() {
  if (have) { nent++; ent[nent] = cur }
  have = 0
  cur = ""
}
# Sets fch and flen to the fence character and run length when the line
# opens or closes a fenced code block (up to three spaces of indent, then
# three or more backticks or tildes), else fch to the empty string; frest is
# the text after the run.
function fenceof(s,   ind, rest, c) {
  fch = ""
  match(s, /[^ ]/)
  if (RSTART == 0) return
  ind = RSTART - 1
  if (ind > 3) return
  rest = substr(s, RSTART)
  c = substr(rest, 1, 1)
  if (c != "`" && c != "~") return
  flen = 0
  while (substr(rest, flen + 1, 1) == c) flen++
  if (flen < 3) return
  frest = substr(rest, flen + 1)
  fch = c
  fcol0 = (ind == 0)
}
BEGIN { label = "^- " field "( \\(.*\\))?:" }
{ sub(/\r$/, "") }
infence {
  fenceof($0)
  if (fch == ofch && flen >= oflen && frest ~ /^[ \t]*$/) infence = 0
  next
}
{
  fenceof($0)
  if (fch != "" && !(fch == "`" && index(frest, "`"))) {
    infence = 1; ofch = fch; oflen = flen; fenceline = NR
    if (infield && fcol0) { addentry(); infield = 0 }
    next
  }
}
!insec && !secdone && /^## Autopilot[ \t]*$/ { insec = 1; secfound = 1; next }
insec && (/^# / || /^## /) {
  if (infield) addentry()
  insec = 0; infield = 0; secdone = 1
  next
}
!insec { next }
!infield {
  if (!found && $0 ~ label) {
    found = 1; infield = 1
    v = $0
    sub(label, "", v)
    inlinev = rtrim(ltrim(v))
  }
  next
}
/^[ \t]*$/ { next }
/^[^ \t]/ { addentry(); infield = 0; next }
{
  match($0, /[^ \t]/)
  ind = RSTART - 1
  line = rtrim(substr($0, RSTART))
  if (line ~ /^[-*] / && (subind == 0 || ind <= subind)) {
    addentry()
    if (subind == 0) subind = ind
    cur = ltrim(substr(line, 3))
    have = 1
    next
  }
  if (have) cur = cur " " line
}
END {
  if (infield) addentry()
  unclosed = infence ? " (the code fence opened at line " fenceline " is never closed)" : ""
  if (!secfound) { print "extract-acceptance.sh: no ## Autopilot section in the spec" unclosed > "/dev/stderr"; exit 2 }
  if (!found) { print "extract-acceptance.sh: no " field ": field in the ## Autopilot section" unclosed > "/dev/stderr"; exit 2 }
  if (inlinev == "none" && nent == 0) { print "commands: 0, cases: 0"; print "span-led: none"; exit 0 }
  if (inlinev != "" || nent == 0) {
    print "extract-acceptance.sh: the " field ": field is neither none nor a list of sub-bullets" > "/dev/stderr"
    exit 2
  }
  cmds = 0; cases = 0; led = ""
  for (k = 1; k <= nent; k++) {
    text = ent[k]
    p = index(text, " — PASS: ")
    before = (p > 0) ? substr(text, 1, p - 1) : text
    before = rtrim(ltrim(before))
    name = sprintf("%s/%02d", out, k)
    cmd = span(before)
    if (spanok) {
      f = name ".cmd"; printf "%s\n", cmd > f; close(f); cmds++
    } else {
      f = name ".case"; printf "%s\n", before > f; close(f); cases++
      if (substr(before, 1, 1) == "`") led = led (led == "" ? "" : ", ") sprintf("%02d", k)
    }
  }
  print "commands: " cmds ", cases: " cases
  print "span-led: " (led == "" ? "none" : led)
}
' "$spec"
