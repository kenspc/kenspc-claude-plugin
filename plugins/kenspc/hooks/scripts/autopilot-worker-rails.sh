#!/usr/bin/env bash
# PreToolUse hook for Bash, Write, Edit, and NotebookEdit: the autopilot
# rails, enforced in an autopilot worker.
#
# Purpose: an autopilot worker's rails — no recursive rm, no write outside
# the repository, the workspace, and scratch — are written in its prompt,
# which the subagents it dispatches never see. A plugin hook fires for a
# subagent's tool call too, so this hook carries two of the rails to every
# call a worker's session makes, its subagents' included.
#
# Marker and roots, both exported by the autopilot driver (run.sh, run.ps1)
# to every worker it starts:
#   KENSPC_AUTOPILOT_WORKER       the hook acts only when it is exactly 1;
#                                 otherwise it exits 0 with no output, so
#                                 every other session's calls pass untouched
#   KENSPC_AUTOPILOT_WRITE_ROOTS  the roots a file-tool write may land under,
#                                 joined by "|": the worker's repository,
#                                 the workspace, $TMPDIR, /tmp, /private/tmp
#
# With the marker set, it denies:
#   (a) a Bash command that runs rm with a recursive flag (-r, -R,
#       --recursive or a prefix of it, any bundle holding r or R, flags
#       split across words; /bin/rm and other path prefixes too) at a
#       command position: the start of the command, a line start, after
#       ; && || | & ( $( or a backtick, after a shell keyword (if, then,
#       do, ...), or after the wrappers sudo, command, env, xargs, exec,
#       nohup, and time, their options skipped. Quoted text and heredoc
#       bodies are arguments, not commands: grep -c 'rm -rf' f,
#       git commit -m "... rm -rf ...", and echo "rm -r" are allowed, and
#       so is rm without a recursive flag;
#   (b) a Write, Edit, or NotebookEdit whose target (tool_input.file_path,
#       or tool_input.notebook_path for NotebookEdit) lies outside every
#       root. The target is read as Claude Code reads it before the write
#       — surrounding whitespace trimmed, a leading ~ or ~/ taken as $HOME
#       — and resolved against the input's cwd when relative, with . and
#       .. collapsed as written, then the symbolic links of its existing
#       ancestors resolved; each root is resolved the same way (/tmp to
#       /private/tmp on macOS). A target is inside a root only by whole
#       path components: <root>-other/f is outside <root>. With the marker
#       set and no roots, every file-tool write is outside them, and a
#       target that cannot be read from the input is denied too.
# An input whose tool_name cannot be read, or a Bash input whose
# tool_input.command cannot be read, is denied as well: were a Claude Code
# release to rename either field, the calls would stop loudly rather than
# pass unchecked.
#
# Deny form: exit status 2 with the reason on stderr, which Claude Code
# returns to the model as the tool call's error. A probe on Claude Code
# 2.1.283 showed this form stopping a subagent's Bash and Write calls in a
# headless bypassPermissions session: neither file was created.
# The reason names the rail and the permitted route: discard by mv into the
# workspace's .trash/<name>-<timestamp>/, and write under the repository,
# the workspace, or scratch.
#
# A best-effort guard behind the rails text, which still binds. Known
# misses: find -delete (and find -exec rm), bash -c '...', eval, and a
# trap body (trap 'rm -rf "$d"' EXIT, a quoted argument run at exit),
# interpreter-level deletes (python, node, perl), git clean, and writes
# through Bash (redirections, cp, mv, tee); also rm reached through a
# variable or an alias, rm after a redirection written before the command
# name (2>/dev/null rm -rf d), other wrappers (timeout, nice), commands inside an
# unquoted heredoc's substitutions, and paths that are not POSIX absolute
# (a Windows drive-letter path is not judged); and a file-tool target that
# is itself a symbolic link, dangling or not, pointing outside every root,
# since only the links of the target's ancestors are resolved.
#
# Bash 3.2 (the one macOS ships): no associative arrays, no bash 4
# expansions; POSIX tools only (awk; no jq), as remind-plan-skill.sh.

# The marker is read before anything else: every Bash call in every session
# starts this hook, and the inert path is this one test.
[ "${KENSPC_AUTOPILOT_WORKER:-}" = 1 ] || exit 0

set -u

# JSON_AWK: jstr(s, key) returns the decoded value of the first string
# member "key" in the JSON text s, or "\001" when there is none. A quote
# inside a JSON string is always escaped, so "key": cannot match inside a
# value.
JSON_AWK='
function hexval(h,   k, d, v) {
  v = 0; h = tolower(h)
  for (k = 1; k <= length(h); k++) {
    d = index("0123456789abcdef", substr(h, k, 1))
    if (d == 0) return -1
    v = v * 16 + d - 1
  }
  return v
}
function jstr(s, key,   i, n, c, e, v, out) {
  if (!match(s, "\"" key "\"[ \t\r\n]*:[ \t\r\n]*\"")) return "\001"
  i = RSTART + RLENGTH; n = length(s); out = ""
  while (i <= n) {
    c = substr(s, i, 1)
    if (c == "\"") return out
    if (c == "\\") {
      e = substr(s, i + 1, 1); i += 2
      if (e == "n") out = out "\n"
      else if (e == "t") out = out "\t"
      else if (e == "r") out = out "\r"
      else if (e == "b") out = out "\b"
      else if (e == "f") out = out "\f"
      else if (e == "u") {
        v = hexval(substr(s, i, 4)); i += 4
        out = out ((v > 0 && v < 128) ? sprintf("%c", v) : "?")
      }
      else out = out e
      continue
    }
    out = out c; i++
  }
  return "\001"
}
{ buf = buf $0 "\n" }
'

# FIELD_AWK prints the value of -v key, or exits 3 when it is missing.
FIELD_AWK=$JSON_AWK'
END { v = jstr(buf, key); if (v == "\001") exit 3; printf "%s", v }
'

# RM_AWK prints "<rm word> <flag>" for the first recursive rm at a command
# position in tool_input.command, and nothing otherwise; it exits 3 when
# there is no command to read. A small shell
# tokenizer: single and double quotes, backslash escapes, comments,
# separators, $( ) and backtick substitutions (the enclosing command's words
# are set aside and restored around them), subshells, and heredoc bodies,
# which are skipped up to their delimiter line. A << whose delimiter line
# never comes — an arithmetic shift such as $((1<<2)), or a heredoc closed
# by EOF) inside $( — skips nothing, and the lines after it are read as
# commands: skipped to the end, they would hide an rm that follows. sq
# holds the single quote.
RM_AWK=$JSON_AWK'
function flush() { if (inw) { nw++; w[nw] = cur }; cur = ""; inw = 0 }
function endcmd() { flush(); if (nw > 0 && found == "") check(); nw = 0 }
function bname(x) { sub(/.*\//, "", x); return x }
function takesarg(wr, o) {
  if (wr == "sudo") return o ~ /^-[ugCDhprtUT]$/
  if (wr == "xargs") return o ~ /^-[nILPsEdaJRS]$/
  if (wr == "env") return o ~ /^-[uCS]$/
  if (wr == "exec") return o == "-a"
  return 0
}
function check(   i, wr, j, a, r) {
  i = 1
  while (i <= nw) {
    if (w[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
    if (w[i] ~ /^(!|\{|if|then|else|elif|do|while|until)$/) { i++; continue }
    wr = bname(w[i])
    if (wr ~ /^(sudo|command|env|xargs|exec|nohup|time)$/) {
      i++
      while (i <= nw) {
        if (w[i] == "--") { i++; break }
        if (w[i] ~ /^-./) { if (takesarg(wr, w[i])) i++; i++; continue }
        if (wr == "env" && w[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
        break
      }
      continue
    }
    break
  }
  if (i > nw || bname(w[i]) != "rm") return
  for (j = i + 1; j <= nw; j++) {
    a = w[j]
    if (a == "--") return
    if (a ~ /^--./) {
      r = substr(a, 3)
      if (index("recursive", r) == 1) { found = w[i] " " a; return }
      continue
    }
    if (a ~ /^-[^-]/ && a ~ /[rR]/) { found = w[i] " " a; return }
  }
}
function push(ret, cl,   k) {
  sp++; sret[sp] = ret; scl[sp] = cl; snw[sp] = nw
  for (k = 1; k <= nw; k++) sw[sp, k] = w[k]
  scur[sp] = cur; sinw[sp] = inw
  nw = 0; cur = ""; inw = 0; st = "N"
}
function pop(   k) {
  endcmd()
  nw = snw[sp]
  for (k = 1; k <= nw; k++) w[k] = sw[sp, k]
  cur = scur[sp]; inw = sinw[sp]; st = sret[sp]; sp--
}
function heredoc_op(c, i,   strip, d, ch) {
  flush(); strip = 0
  if (substr(c, i, 1) == "-") { strip = 1; i++ }
  while (substr(c, i, 1) == " " || substr(c, i, 1) == "\t") i++
  d = ""
  while (i <= length(c)) {
    ch = substr(c, i, 1)
    if (ch ~ /[ \t\n;&|<>()]/) break
    if (ch != sq && ch != "\"" && ch != "\\") d = d ch
    i++
  }
  if (d != "") { nh++; hd[nh] = d; hs[nh] = strip }
  return i
}
function heredocs(c, i,   k, rest, nl, line, from, hit) {
  for (k = 1; k <= nh; k++) {
    from = i; hit = 0
    while (i <= length(c)) {
      rest = substr(c, i); nl = index(rest, "\n")
      line = nl ? substr(rest, 1, nl - 1) : rest
      i += nl ? nl : length(rest)
      if (hs[k]) sub(/^\t+/, "", line)
      if (line == hd[k]) { hit = 1; break }
    }
    if (!hit) { i = from; break }
  }
  nh = 0
  return i
}
function scan(c,   n, i, ch, nx) {
  n = length(c); i = 1; st = "N"; sp = 0; nw = 0; cur = ""; inw = 0; nh = 0
  while (i <= n && found == "") {
    ch = substr(c, i, 1); nx = substr(c, i + 1, 1)
    if (st == "S") { if (ch == sq) st = "N"; else cur = cur ch; i++; continue }
    if (st == "D") {
      if (ch == "\\" && index("$`\"\\\n", nx) > 0) { if (nx != "\n") cur = cur nx; i += 2; continue }
      if (ch == "\"") { st = "N"; i++; continue }
      if (ch == "$" && nx == "(") { cur = cur "$()"; push("D", ")"); i += 2; continue }
      if (ch == "`") {
        if (sp > 0 && scl[sp] == "`") { pop(); i++; continue }
        cur = cur "$()"; push("D", "`"); i++; continue
      }
      cur = cur ch; i++; continue
    }
    if (ch == " " || ch == "\t") { flush(); i++; continue }
    if (ch == "\n") { endcmd(); i++; if (nh > 0) i = heredocs(c, i); continue }
    if (ch == "\\") { if (nx != "\n") { cur = cur nx; inw = 1 }; i += 2; continue }
    if (ch == sq) { st = "S"; inw = 1; i++; continue }
    if (ch == "\"") { st = "D"; inw = 1; i++; continue }
    if (ch == "#" && !inw) { while (i <= n && substr(c, i, 1) != "\n") i++; continue }
    if (ch == "$" && nx == "(") { cur = cur "$()"; inw = 1; push("N", ")"); i += 2; continue }
    if (ch == "`") {
      if (sp > 0 && scl[sp] == "`") { pop(); i++; continue }
      cur = cur "$()"; inw = 1; push("N", "`"); i++; continue
    }
    if (ch == "(") { endcmd(); push("N", ")"); i++; continue }
    if (ch == ")") { if (sp > 0 && scl[sp] == ")") pop(); else endcmd(); i++; continue }
    if (ch == "<" && nx == "<") {
      if (substr(c, i + 2, 1) == "<") { cur = cur "<<<"; inw = 1; i += 3; continue }
      i = heredoc_op(c, i + 2); continue
    }
    if ((ch == "&" || ch == "|") && (nx == ">" || cur ~ /[<>]$/)) { cur = cur ch; inw = 1; i++; continue }
    if (ch == ";" || ch == "&" || ch == "|") { endcmd(); i++; continue }
    cur = cur ch; inw = 1; i++
  }
  endcmd()
  while (sp > 0 && found == "") pop()
}
END {
  c = jstr(buf, "command")
  if (c == "\001") exit 3
  found = ""; scan(c)
  if (found != "") printf "%s", found
}
'

REASON_ROUTE="Permitted instead: discard by mv into the workspace's .trash/<name>-<timestamp>/ (inside the repository, delete through git rm), and write under the repository, the workspace, or scratch (\$TMPDIR, /tmp)."

deny() {
  printf 'autopilot rails: %s. %s\n' "$1" "$REASON_ROUTE" >&2
  exit 2
}

# field <key>: the decoded value of the first string member <key> of the
# hook input; status 3 when there is none.
field() {
  printf '%s' "$input" | awk -v key="$1" "$FIELD_AWK"
}

# resolve <absolute path>: sets RESOLVED to the path with . and ..
# collapsed as written, and then the symbolic links of its existing
# ancestors resolved; "" stands for /. A component that does not exist is
# kept as written. Why .. first, as written: Claude Code collapses it that
# way before the write, so a .. after a link leaves the link's parent,
# not its target's.
resolve() {
  local rest=$1 lex="" out="" comp next
  while [ -n "$rest" ]; do
    comp=${rest%%/*}
    case $rest in
      */*) rest=${rest#*/} ;;
      *) rest="" ;;
    esac
    case $comp in
      ''|.) ;;
      ..) lex=${lex%/*} ;;
      *) lex="$lex/$comp" ;;
    esac
  done
  rest=${lex#/}
  while [ -n "$rest" ]; do
    comp=${rest%%/*}
    case $rest in
      */*) rest=${rest#*/} ;;
      *) rest="" ;;
    esac
    next="$out/$comp"
    if [ -L "$next" ] && [ -d "$next" ]; then
      next=$(cd "$next" 2>/dev/null && pwd -P) || next="$out/$comp"
      next=${next%/}
    fi
    out=$next
  done
  RESOLVED=$out
}

input=$(cat)
tool=$(field tool_name) \
  || deny "the tool name could not be read from the hook input (tool_name), so the call is denied in an autopilot worker"

case $tool in
  Bash)
    found=$(printf '%s' "$input" | awk -v sq="'" "$RM_AWK") \
      || deny "the command of this Bash call could not be read from the hook input (tool_input.command), so it is denied in an autopilot worker"
    [ -z "$found" ] || deny "a recursive rm is denied in an autopilot worker ($found)"
    exit 0
    ;;
  Write|Edit) key=file_path ;;
  NotebookEdit) key=notebook_path ;;
  *) exit 0 ;;
esac

target=$(field "$key") \
  || deny "the target of this $tool call could not be read from the hook input (tool_input.$key), so the write is denied in an autopilot worker"
json_cwd=$(field cwd) || json_cwd=$PWD

# The target as Claude Code reads it before the write: surrounding
# whitespace trimmed, and a leading ~ or ~/ taken as $HOME. Joined to the
# cwd as written, ~/.zshrc would read as a path inside the repository.
path=${target#"${target%%[![:space:]]*}"}
path=${path%"${path##*[![:space:]]}"}
case $path in
  "~") path="${HOME:-}/" ;;
  "~/"*) path="${HOME:-}/${path#"~/"}" ;;
esac
case $path in
  /*) ;;
  *) path="$json_cwd/$path" ;;
esac
# A path that is not POSIX absolute even after the join (a Windows
# drive-letter path) is not judged: the hook cannot resolve it, and the
# rails text still binds.
case $path in
  /*) ;;
  *) exit 0 ;;
esac
resolve "$path"
resolved_target=$RESOLVED

roots=${KENSPC_AUTOPILOT_WRITE_ROOTS:-}
rest=$roots
while [ -n "$rest" ]; do
  root=${rest%%|*}
  case $rest in
    *"|"*) rest=${rest#*|} ;;
    *) rest="" ;;
  esac
  case $root in
    /*) ;;
    *) continue ;;
  esac
  resolve "$root"
  case $resolved_target in
    "$RESOLVED"|"$RESOLVED"/*) exit 0 ;;
  esac
done

deny "this $tool call writes outside the rails' write roots, which is denied in an autopilot worker: $target resolves to ${resolved_target:-/}, outside ${roots:-no roots (KENSPC_AUTOPILOT_WRITE_ROOTS is empty)}"
