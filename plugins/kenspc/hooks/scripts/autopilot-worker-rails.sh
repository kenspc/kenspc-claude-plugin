#!/usr/bin/env bash
# PreToolUse hook for Bash, Write, Edit, and NotebookEdit: the autopilot
# rails, enforced in an autopilot worker.
#
# Purpose: an autopilot worker's rails — no recursive rm, no write outside
# the repository, the workspace, and scratch — are written in its prompt,
# which the subagents it dispatches never see. A plugin hook fires for a
# subagent's tool call too, so this hook carries rails to every call a
# worker's session makes, its subagents' included: the recursive rm, the
# write outside the roots, gh and remote git (a worker reaches GitHub only
# through the main session), and, with a suite limit set, a listed suite
# command run without the suite-slot wrapper.
#
# Marker and roots, both exported by the autopilot driver (run.sh, run.ps1)
# to every worker it starts:
#   KENSPC_AUTOPILOT_WORKER       the hook acts only when it is exactly 1;
#                                 otherwise it exits 0 with no output, so
#                                 every other session's calls pass untouched
#   KENSPC_AUTOPILOT_WRITE_ROOTS  the roots a file-tool write may land under,
#                                 joined by "|": the worker's repository,
#                                 the workspace, $TMPDIR, /tmp, /private/tmp
# and the batch's suite limit, exported the same way from its
# `Suite limit:` field, empty without one:
#   KENSPC_AUTOPILOT_SUITE_COMMANDS  the listed suite command prefixes,
#                                 joined by "|"; check (f) reads them
#   KENSPC_AUTOPILOT_SUITE_WRAPPER   the suite-slot wrapper copy's absolute
#                                 path, named in (f)'s reason
#
# With the marker set, it denies:
#   (a) a Bash command that runs rm with a recursive flag (-r, -R,
#       --recursive or a prefix of it, any bundle holding r or R, flags
#       split across words; /bin/rm and other path prefixes too) at a
#       command position: the start of the command, a line start, after
#       ; && || | & ( $( or a backtick, after a shell keyword (if, then,
#       do, ..., function NAME, coproc), or after the wrappers sudo,
#       command, env, xargs, exec, nohup, and time, their options skipped;
#       a word quoted as $'...' or $"..." is read without its $. Quoted
#       text and heredoc bodies are arguments, not commands: grep -c 'rm -rf' f,
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
#       target that cannot be read from the input is denied too;
#   (c) a Bash input longer than BASH_INPUT_CAP bytes (64 KB), unscanned:
#       the scan's time grows with the square of the command's length, and
#       a run that outlasts the hook's timeout denies nothing;
#   (d) a Bash command with a redirection — >, >>, >|, &>, &>>, the same
#       after a file-descriptor number (2>), and >& followed by a word other
#       than a descriptor number or -, which writes to that word — whose
#       target lies outside every root, by the root check (b) uses. The
#       target is read after a leading ~ or ~$USER (unquoted), $HOME,
#       ${HOME}, $TMPDIR, or ${TMPDIR} is expanded from the hook's
#       environment, resolved when relative against the tracked directory,
#       with . and .. collapsed as written. The tracked directory starts as
#       the input's cwd; a top-level simple command cd <word>, its word one
#       literal path (no $, backtick, glob character, or ~), joined to what
#       follows by &&, or by ; (a line end counts as ;) when its target is
#       an existing directory as the hook runs, moves it, resolved against
#       the current one, for the redirections after it, a subshell after it
#       included, and an absolute word moves it even when the current one is
#       unknown; a cd joined by ; whose target is no directory, or past the
#       200 directory tests one call gets, leaves it where it was, as bash
#       stays after a cd that fails; a cd with no word, cd -, a word that
#       opens with -, more than one word, or a word that is no literal path,
#       and a cd joined by ||, leave it unknown, and so does a || later in
#       the same list after a cd that moved it at a &&; a cd in any element
#       of a pipeline, or before a lone &, moves nothing (bash runs it in a
#       subshell), and so does a
#       cd in the body of an if, while, until, for, select, or case
#       command, a { } group, or a function. Not judged: a relative
#       target while the directory is unknown, a target holding any other
#       expansion (a ~ naming another user too), a command substitution, a
#       glob or a brace, or single-quoted text with a leading ~ or a $ in it
#       (other single-quoted text is literal and judged); /dev/null,
#       /dev/stdout, /dev/stderr, /dev/tty, and /dev/fd/<n> are allowed; a
#       duplication or a close (2>&1, >&-) has no target; a > inside
#       quotes, escaped, or in a heredoc body is no redirection. Why
#       redirections: both writes outside the roots that workers made
#       through Bash were redirections, one to a file beside $TMPDIR and one
#       appending to a memory file under ~/.claude. A command with more than
#       TARGET_CAP (1000) distinct targets is denied unjudged, for the
#       reason (c) gives;
#   (e) gh at a command position (command -v gh, type gh, and which gh,
#       which do not run it, are allowed), and git — its global options
#       skipped (-C, -c, --git-dir, --work-tree, and --namespace with a
#       separate argument; any other word starting with -) — with the
#       subcommand fetch, pull, push, ls-remote, or remote update, or
#       clone whose source is a URL (it
#       holds ://, or reads [<user>@]<host>:<path>, a : before any /, as
#       git reads it, a drive letter aside); a git clone of a local
#       path is allowed. The reason's route: ask the main session, which
#       gets anything the work needs from GitHub. Why: a denial is not a
#       breach, so the run goes on, and the hook reaches a subagent that
#       never saw the preamble — a subagent's read-only gh call once
#       stopped a run as a breach;
#   (f) with KENSPC_AUTOPILOT_SUITE_COMMANDS non-empty, a Bash command that
#       runs a listed suite command at a command position, the positions (a)
#       and (e) recognize, their skips included. The base name of each
#       prefix's first word is compared with the command word's base name,
#       as (a) compares rm, and its later words with the words after it as
#       written, whole word by whole word; a prefix's leading assignments
#       and wrappers are skipped as a command's are, so ./gradlew test or
#       CI=1 pnpm test listed is matched too: with dotnet test listed,
#       dotnet test --filter X, sudo dotnet test, $(dotnet test), and
#       /usr/local/share/dotnet/dotnet test are denied, while dotnet testx,
#       dotnet build, echo "dotnet test", a heredoc body, and
#       bash <wrapper> run -- dotnet test, where dotnet is an argument of
#       bash, are allowed. Every run takes a slot, whatever its arguments.
#       The reason names the prefix and the route: run it through the
#       suite-slot wrapper, bash <KENSPC_AUTOPILOT_SUITE_WRAPPER> run --
#       <the command>, and on exit 75 with a "suite-slots: busy" line run
#       the same line again. With the variable empty, (f) checks nothing.
#       Why: the machine-wide limit on heavy suites holds only when every
#       run takes a slot, more than about two runs of one integration suite
#       at once exhausted a machine's local ports, and a worker's subagents
#       never see the preamble that says so. Known misses of (f): a listed
#       command reached through a script file, bash -c, make, eval, a
#       variable, or an alias, or after a wrapper the scan does not skip
#       (timeout, nice).
# An input whose tool_name cannot be read, or a Bash input whose
# tool_input.command cannot be read, is denied as well: were a Claude Code
# release to rename either field, the calls would stop loudly rather than
# pass unchecked. Such a denial, and that of a file-tool target that cannot
# be read, offers no route, since a retry is read the same way: its reason
# says so and asks for the denial to be reported.
#
# Deny form: exit status 2 with the reason on stderr, which Claude Code
# returns to the model as the tool call's error. A probe on Claude Code
# 2.1.283 showed this form stopping a subagent's Bash and Write calls in a
# headless bypassPermissions session: neither file was created.
# The reason names the rail and the permitted route: discard by mv into the
# workspace's .trash/<name>-<timestamp>/, and write under the repository,
# the workspace, or scratch; for gh and remote git, to ask the main session;
# for a listed suite command, the suite-slot wrapper's line;
# for a field that cannot be read, that no route
# applies and that the denial is to be listed under ## Rail observations
# before the worker ends.
#
# A best-effort guard behind the rails text, which still binds. Known
# misses: find -delete (and find -exec rm), bash -c '...', a script fed to
# a shell on stdin (bash <<EOF, sh -s), eval, and a
# trap body (trap 'rm -rf "$d"' EXIT, a quoted argument run at exit),
# interpreter-level deletes (python, node, perl), git clean, and writes
# through Bash other than a redirection (cp, mv, tee, an interpreter's own
# writes); a redirection whose relative target follows a cd inside a
# subshell, a pipeline, the body of an if, while, until, for, select, or
# case command, a { } group, or a function, a cd after a keyword or a {
# (then cd, { cd), a cd reached through builtin cd, command cd, or an
# assignment before it (VAR=x cd), or a pushd, which are not tracked and so
# read against the directory before it, or follows a cd whose
# target is not a literal, a cd joined by ||, or a || after a cd in its
# list, not judged; remote git
# through git lfs,
# git submodule update --remote, or a git alias; also rm reached through a
# variable or an alias, or spelled through the escapes of $'...'
# ($'\x72m', kept as written), rm after a redirection written before the command
# name (2>/dev/null rm -rf d), other wrappers (timeout, nice), commands inside an
# unquoted heredoc's substitutions, a case arm inside a $( ) that follows
# another word, whose ) the hook reads as the substitution's end
# (echo $(case x in a) rm -rf y;; esac)), a two-character token split by a
# line continuation (&\<newline>>, $\<newline>', $\<newline>(, a heredoc
# operator or delimiter), which bash joins before it splits words while the
# hook reads one next character, and paths that are not POSIX absolute
# (a Windows drive-letter path is not judged); and a file-tool target that
# is itself a symbolic link, dangling or not, pointing outside every root,
# since only the links of the target's ancestors are resolved. A > inside
# [[ ]] or (( )), a comparison there, is read as a redirection and judged.
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
# position in tool_input.command, and nothing otherwise; when it finds none,
# it then prints, one per line after a line break, each redirection target
# it judges (redir() below); it exits 3 when there is no command to read. A small shell
# tokenizer: single and double quotes, $'...' (a backslash escapes the next
# character, which is kept as written) and $"...", backslash escapes, comments,
# separators, $( ) and backtick substitutions (the enclosing command's words
# are kept below theirs until they end), subshells, and heredoc bodies,
# which are skipped up to their delimiter line. A << whose delimiter line
# never comes — an arithmetic shift such as $((1<<2)), or a heredoc closed
# by EOF) inside $( — skips nothing, and the lines after it are read as
# commands: skipped to the end, they would hide an rm that follows. sq
# holds the single quote.
RM_AWK=$JSON_AWK'
function flush() { if (inw) { nw++; w[nw] = cur; wq[nw] = cq; wd[nw] = cd }; cur = ""; inw = 0; cq = 0; cd = 0 }
function endcmd() { flush(); if (nw > base && found == "") { check(); redir() }; if (sp == 0 && nw > base) { cmdn = 1; kwd(); cdword() }; nw = base }
# cdword() runs at the end of each top-level simple command and sets pend:
# "\001" when the command is no cd; otherwise the directory the cd moves
# to, or "" when the hook cannot read its target as one literal path (no
# word, cd -, a word that opens with -, more than one word, or a word
# holding $, a backtick, a glob character, a brace, or ~). cdsep() applies
# it at the separator that follows. Why only a literal at the top level:
# the denials this tracking removes were all cd <literal> && … > <relative>,
# and a narrower rule that the scoping of bash cannot contradict is safer than a
# wider one the scanner cannot read.
function cdword(   a) {
  pend = "\001"
  if (w[base + 1] != "cd" || kd > 0 || pin) return
  pend = ""
  if (nw != base + 2) return
  a = w[base + 2]
  if (a == "" || a ~ /^-/ || a ~ /[$`*?[{~]/ || a ~ /[\t\n]/ || index(a, "\002") > 0) return
  if (a ~ /^\//) pend = collapse(a)
  else if (wdir ~ /^\//) pend = collapse(wdir "/" a)
}
# kwd() follows the compound commands open at the top level: kd counts the
# if, while, until, for, select, and case commands, the { } groups, and
# the function bodies open around the command, read from its unquoted
# leading words, and a cd while kd > 0 moves nothing (cdword). Why: a cd in
# a body runs only when the body does, and a cd in a function body only
# when the function is called, so a redirection after the body is read
# against the directory before it.
function kwd(   i, x) {
  for (i = base + 1; i <= nw; i++) {
    if (wq[i] || wd[i]) return
    x = w[i]
    if (x ~ /^(if|while|until|\{)$/) { kd++; continue }
    if (x ~ /^(for|select|case)$/) { kd++; return }
    if (x ~ /^(fi|done|esac|\})$/) { if (kd > 0) kd--; continue }
    if (x == "function") { i++; continue }
    if (x !~ /^(then|else|elif|do|!)$/) return
  }
}
# cdsep(s): s is the separator after a top-level command and the character
# after it. A pending cd moves the tracked directory, wdir, after &&; after
# ; (a line end is passed as ;) it moves it only when its target is an
# existing directory (isdir), and otherwise wdir stays where it was, since
# bash carries on after a cd that failed and the old directory then holds;
# after || it leaves wdir unknown (""), and before a | or a lone & it moves
# nothing, since bash runs the cd in a subshell there; pin marks the
# command after a | (or |&), the next element of a pipeline, whose cd
# moves nothing either (cdword), as bash runs each element in a subshell. A || later in the
# same list, after a cd that moved wdir at a &&, leaves wdir unknown too
# (lcd), since the command after it also runs when that cd failed; the
# list ends at a ; or a lone &. A line end with no command since the last
# separator (after &&, ||, or |, where bash reads on) ends nothing (cmdn).
# Why the test only after ;: a cd that fails before && stops the commands
# joined to it, while one before ; does not.
function cdsep(s,   k) {
  if (s == "&&") k = "a"
  else if (s == "||") k = "o"
  else if (substr(s, 1, 1) == "|") k = "p"
  else if (substr(s, 1, 1) == ";") k = "e"
  else k = "b"
  if (k == "e" && !cmdn) return
  cmdn = 0
  if (pend != "\001") {
    if (k == "a") { wdir = pend; lcd = 1 }
    else if (k == "e") { if (pend == "" || pend == wdir || isdir(pend)) wdir = pend }
    else if (k == "o") wdir = ""
  }
  if (k == "o" && lcd) wdir = ""
  if (k == "e" || k == "b") lcd = 0
  pin = (k == "p")
  pend = "\001"
}
# isdir(p): whether the absolute path p is an existing directory when the
# hook runs, by test -d in a shell, each path tested once. Past 200 tests a
# path counts as no directory, which keeps wdir where it was. Why a cap:
# each test forks a shell, about 2 ms apiece under the awk macOS ships, and
# 64 KB of cd commands to distinct paths would outlast the timeout of the
# hook, where a run denies nothing.
function isdir(p,   i, ch, q) {
  if (p in dseen) return dseen[p]
  if (ntest >= 200) return 0
  ntest++; q = sq
  for (i = 1; i <= length(p); i++) { ch = substr(p, i, 1); q = q ((ch == sq) ? sq "\\" sq sq : ch) }
  dseen[p] = (system("test -d " q sq) == 0)
  return dseen[p]
}
# bname splits on / rather than sub(/.*\//, ...): the awk macOS ships
# retries that regex from every position of a word with no slash, which
# made a 64 KB command word take about 15 seconds.
function bname(x,   p, k) { k = split(x, p, "/"); return p[k] }
function takesarg(wr, o) {
  if (wr == "sudo") return o ~ /^-[ugCDhprtUT]$/
  if (wr == "xargs") return o ~ /^-[nILPsEdaJRS]$/
  if (wr == "env") return o ~ /^-[uCS]$/
  if (wr == "exec") return o == "-a"
  return 0
}
function check(   i, wr, j, a, r) {
  i = base + 1
  while (i <= nw) {
    if (w[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
    if (w[i] ~ /^(!|\{|if|then|else|elif|do|while|until)$/) { i++; continue }
    if (w[i] == "function") { i += 2; continue }
    if (w[i] == "coproc") { i++; if (i < nw && w[i + 1] == "{") i++; continue }
    wr = bname(w[i])
    if (wr ~ /^(sudo|command|env|xargs|exec|nohup|time)$/) {
      i++
      while (i <= nw) {
        if (w[i] == "--") { i++; break }
        # command -v and command -V name a command without running it.
        if (wr == "command" && w[i] ~ /^-[vV]+$/) return
        if (w[i] ~ /^-./) { if (takesarg(wr, w[i])) i++; i++; continue }
        if (wr == "env" && w[i] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { i++; continue }
        break
      }
      continue
    }
    break
  }
  if (i > nw) return
  if (nsuite > 0 && suite(i)) return
  if (bname(w[i]) == "gh") { found = "\003" w[i] ((i < nw) ? " " w[i + 1] : ""); return }
  if (bname(w[i]) == "git") { gitremote(i); return }
  if (bname(w[i]) != "rm") return
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
# suite(i): check (f). True, with found set and marked \004, when the
# words from w[i] on begin with a listed suite prefix: the base name of its
# first word against the base name of the command word, its later words as
# written, whole word by whole word.
function suite(i,   k, m) {
  for (k = 1; k <= nsuite; k++) {
    if (SN[k] == 0 || bname(w[i]) != SW[k, 1]) continue
    for (m = 2; m <= SN[k]; m++) if (i + m - 1 > nw || w[i + m - 1] != SW[k, m]) break
    if (m > SN[k]) { found = "\004" SD[k]; return 1 }
  }
  return 0
}
# gitremote(i): w[i] is git. Its global options are skipped: -C, -c,
# --git-dir, --work-tree, and --namespace with the argument that follows as
# a word of its own, any other word that starts with - alone, and --help,
# -h, or --version ends the check, since git then runs no subcommand. Why
# every option: skipping only those listed let git -P push and
# git --git-dir .git fetch through. The subcommands
# fetch, pull, push, ls-remote, and remote update, and a clone whose source
# holds :// or reads [<user>@]<host>:<path> (a : before any /, not a
# Windows drive letter, as git reads an scp-like source), set found,
# marked \003 as a
# remote call. A clone of a local path is no remote call.
function gitremote(i,   j, a, s) {
  j = i + 1
  while (j <= nw) {
    a = w[j]
    if (a == "-C" || a == "-c" || a ~ /^--(git-dir|work-tree|namespace)$/) { j += 2; continue }
    if (a ~ /^(--help|-h|--version)$/) return
    if (a ~ /^-/) { j++; continue }
    break
  }
  if (j > nw) return
  s = w[j]
  if (s ~ /^(fetch|pull|push|ls-remote)$/ || (s == "remote" && j < nw && w[j + 1] == "update")) {
    found = "\003" w[i] " " s
    return
  }
  if (s != "clone") return
  for (j++; j <= nw; j++) {
    a = w[j]
    if (a == "--") { j++; break }
    if (a !~ /^-/) break
    if (a ~ /^(-[bocuj]|--(branch|origin|config|upload-pack|reference|reference-if-able|template|depth|separate-git-dir|filter|jobs|shallow-since|shallow-exclude|server-option|bundle-uri))$/) j++
  }
  if (j > nw) return
  a = w[j]
  if (index(a, "://") > 0 || (a ~ /^[^\/:]+:/ && a !~ /^[A-Za-z]:/)) found = "\003" w[i] " clone " a
}
# push and pop enter and leave a substitution or subshell. The words of its
# command go on top of those of the enclosing command, as w[base + 1] to
# w[nw], and the enclosing words stay where they are, so each push and pop
# takes the same time whatever the length of the command: copying the
# enclosing words out and back made a command of many $( ) take tens of
# seconds at the length cap.
function push(ret, cl) {
  if (sp == 0) cmdn = 1
  sp++; sret[sp] = ret; scl[sp] = cl; sbase[sp] = base
  scur[sp] = cur; sinw[sp] = inw; scq[sp] = cq; scd[sp] = cd
  base = nw; cur = ""; inw = 0; cq = 0; cd = 0; st = "N"
}
function pop() {
  endcmd()
  base = sbase[sp]
  cur = scur[sp]; inw = sinw[sp]; cq = scq[sp]; cd = scd[sp]; st = sret[sp]; sp--
}
# redir() reads the redirections among the words of a command. An unquoted
# > is kept in its word as \002, so a > that was quoted or escaped is no
# operator here: >, >>, >|, and the same after &, or after a file-descriptor
# number, take the rest of the word as their target, or the next word when
# the rest is empty; a > followed by & and a descriptor number or - is a
# duplication or a close (2>&1, >&-), with no target, while >& followed by
# any other word writes stdout and stderr to that word, as &> does.
function redir(   k, x, p, t, q, d, u) {
  for (k = base + 1; k <= nw; k++) {
    x = w[k]; q = wq[k]; d = wd[k]
    while ((p = index(x, "\002")) > 0) {
      t = substr(x, p + 1)
      if (substr(t, 1, 1) == "\002" || substr(t, 1, 1) == "|") t = substr(t, 2)
      if (substr(t, 1, 1) == "&") {
        t = substr(t, 2); p = index(t, "\002")
        u = (p > 0) ? substr(t, 1, p - 1) : t
        if (u == "" && p == 0 && k < nw) u = w[k + 1]
        if (u ~ /^([0-9]+-?|-)$/) { x = t; continue }
      }
      if (t == "" && k < nw) { k++; t = w[k]; q = wq[k]; d = wd[k] }
      p = index(t, "\002")
      if (p > 0) { x = substr(t, p); t = substr(t, 1, p - 1) } else x = ""
      target(t, q, d)
    }
  }
}
# lead(t, s): t begins with s, followed by the end or a /.
function lead(t, s) { return index(t, s) == 1 && (length(t) == length(s) || substr(t, length(s) + 1, 1) == "/") }
# collapse(p): the absolute path p with . and .. collapsed as written.
function collapse(p,   n, a, i, m, s, out) {
  n = split(p, a, "/"); m = 0
  for (i = 1; i <= n; i++) {
    if (a[i] == "" || a[i] == ".") continue
    if (a[i] == "..") { if (m > 0) m--; continue }
    s[++m] = a[i]
  }
  out = ""
  for (i = 1; i <= m; i++) out = out "/" s[i]
  return (out == "") ? "/" : out
}
# target(t, q, d): records a redirection target the hook judges, once, as
# "<absolute path><tab><target as written>". Not judged: an expansion
# other than a leading ~ (unquoted), $HOME, ${HOME}, $TMPDIR, or ${TMPDIR}
# (set), a substitution, a glob or a brace, a target with single-quoted
# text that begins with ~ or holds a $ (which part was quoted is not
# kept), and a relative target with no absolute tracked directory (wdir,
# the cwd of the input as cdsep() moves it). Other single-quoted
# text is literal and judged as written. The terminal and descriptor
# files are no write.
function target(t, q, d,   o, v, r, u) {
  if (t == "" || t ~ /[\t\n]/) return
  if (t ~ /^\/dev\/(null|stdout|stderr|tty)$/ || t ~ /^\/dev\/fd\/[0-9]+$/) return
  if (q && index(t, "~") == 1) return
  o = t; v = "\001"
  if (q) r = t
  else if (!d && (t == "~" || index(t, "~/") == 1)) { v = home; r = substr(t, 2) }
  else if (!d && index(t, "~") == 1) {
    # ~name is the home of the user name: judged for the hook user, whose
    # home is known, and not judged for any other name (~+ and ~- too).
    u = substr(t, 2); sub(/\/.*/, "", u)
    if (u == "" || u != user) return
    v = home; r = substr(t, length(u) + 2)
  }
  else if (lead(t, "$HOME")) { v = home; r = substr(t, 6) }
  else if (lead(t, "${HOME}")) { v = home; r = substr(t, 8) }
  else if (lead(t, "$TMPDIR")) { v = tmpd; r = substr(t, 8) }
  else if (lead(t, "${TMPDIR}")) { v = tmpd; r = substr(t, 10) }
  else r = t
  if (v == "") return
  if (r ~ /[$`*?[{]/) return
  if (v != "\001") t = v r
  if (t !~ /^\//) { if (wdir !~ /^\//) return; t = wdir "/" t }
  t = collapse(t)
  if (!(t in tseen)) { tseen[t] = 1; nt++; tl[nt] = t "\t" o }
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
# lines(c) indexes the lines of c once, so that heredocs() finds a
# delimiter line without copying the rest of the command on every line,
# which made a command of many << lines with no delimiter line take
# seconds: LN[j] is line j, LO[j] its offset in c, LI[offset] its number;
# P[t, m] is the m-th line that reads t, and Q[t, m] the m-th that reads t
# once its leading tabs are stripped (<<-).
function lines(c,   j, off, t) {
  nln = split(c, LN, "\n"); off = 1
  for (j = 1; j <= nln; j++) {
    LO[j] = off; LI[off] = j; off += length(LN[j]) + 1
    t = LN[j] ""; np[t]++; P[t, np[t]] = j
    sub(/^\t+/, "", t); nq[t]++; Q[t, nq[t]] = j
  }
}
# nextline(d, strip, k): the first line at or after line k that reads d,
# its leading tabs stripped when strip, or 0 when none does. The scan asks
# for lines in increasing order, so each pointer only moves forward.
function nextline(d, strip, k) {
  if (strip) {
    while (pq[d] < nq[d] && Q[d, pq[d] + 1] < k) pq[d]++
    return (pq[d] < nq[d]) ? Q[d, pq[d] + 1] : 0
  }
  while (pp[d] < np[d] && P[d, pp[d] + 1] < k) pp[d]++
  return (pp[d] < np[d]) ? P[d, pp[d] + 1] : 0
}
# heredocs(c, i): i is a line start; skips the bodies of the pending
# heredocs, each up to its delimiter line, and returns the offset after
# the last body found. At the first delimiter line that never comes, it
# stops there, and the lines from the start of that body are read as
# commands.
function heredocs(c, i,   m, k, j) {
  k = LI[i]
  for (m = 1; m <= nh; m++) {
    j = nextline(hd[m], hs[m], k)
    if (!j) break
    k = j + 1
  }
  nh = 0
  return (k > nln) ? length(c) + 1 : LO[k]
}
function scan(c,   n, i, ch, nx) {
  lines(c)
  n = length(c); i = 1; st = "N"; sp = 0; base = 0; nw = 0; cur = ""; inw = 0; cq = 0; cd = 0; nh = 0; ltgt = -1; cmdn = 0; lcd = 0; ntest = 0; kd = 0; pin = 0
  while (i <= n && found == "") {
    ch = substr(c, i, 1); nx = substr(c, i + 1, 1)
    if (st == "S") { if (ch == sq) st = "N"; else cur = cur ch; i++; continue }
    if (st == "A") {
      if (ch == "\\") { cur = cur nx; i += 2; continue }
      if (ch == sq) st = "N"; else cur = cur ch
      i++; continue
    }
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
    if (ch == "\n") { endcmd(); if (sp == 0) cdsep(";"); i++; if (nh > 0) i = heredocs(c, i); continue }
    # A line continuation right after an unquoted < or > moves ltgt past
    # it: bash joins the lines before it splits words, so >\<newline>& is
    # still >&, and the & or | after it stays in the word.
    if (ch == "\\") { if (nx != "\n") { cur = cur nx; inw = 1 } else if (ltgt == i - 1) ltgt = i + 1; i += 2; continue }
    if (ch == sq) { st = "S"; inw = 1; cq = 1; i++; continue }
    if (ch == "\"") { st = "D"; inw = 1; cd = 1; i++; continue }
    if (ch == "#" && !inw) { while (i <= n && substr(c, i, 1) != "\n") i++; continue }
    if (ch == "$" && nx == sq) { st = "A"; inw = 1; cq = 1; i += 2; continue }
    if (ch == "$" && nx == "\"") { st = "D"; inw = 1; cd = 1; i += 2; continue }
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
    # A | or & right after an unquoted < or > stays in the word (<|, >&).
    # ltgt holds the offset of the last unquoted < or > the word took, so
    # only the character before the | or & is read: matching the
    # whole word against [<>]$ on every | or & made one 64 KB word of <|
    # pairs take over 3 seconds, and a quoted or escaped < or > ("a>"|rm)
    # is no redirection, so the | after it still ends the command.
    if ((ch == "&" || ch == "|") && (nx == ">" || ltgt == i - 1)) { cur = cur ch; inw = 1; i++; continue }
    # && and || are read as one separator, and so is |&, so that their
    # second character is not read as a lone & or a |.
    if (ch == ";" || ch == "&" || ch == "|") { endcmd(); if (sp == 0) cdsep(ch nx); i += (ch nx == "&&" || ch nx == "||" || ch nx == "|&") ? 2 : 1; continue }
    if (ch == "<" || ch == ">") ltgt = i
    # An unquoted > clears the quote flags of the word, so they describe the
    # text after the last > of the word, its target: quoted text before the
    # > ("hi">>~/x) left ~/x unexpanded, and a single-quoted word before it
    # left a /etc target unjudged.
    if (ch == ">") { cur = cur "\002"; cq = 0; cd = 0; inw = 1; i++; continue }
    cur = cur ch; inw = 1; i++
  }
  endcmd()
  while (sp > 0 && found == "") pop()
}
END {
  c = jstr(buf, "command")
  if (c == "\001") exit 3
  home = ENVIRON["HOME"]; tmpd = ENVIRON["TMPDIR"]; user = ENVIRON["USER"]
  cwd = jstr(buf, "cwd"); if (cwd == "\001") cwd = ENVIRON["PWD"]
  wdir = cwd; pend = "\001"
  # The listed suite prefixes (-v suites, "|"-joined), each split into its
  # words once: SD[k] the prefix as named, SN[k] its words from its command
  # word on, SW[k, m] the m-th of them, the first one its base name. The
  # leading words check() skips in a command (assignments, and the wrappers
  # with their options) are skipped in a prefix too, since check() never
  # compares them: a prefix written CI=1 pnpm test or ./gradlew test would
  # otherwise match nothing.
  nsuite = split(suites, SP, "|")
  for (k = 1; k <= nsuite; k++) {
    pn = split(SP[k], sw1, " "); SD[k] = ""
    for (m = 1; m <= pn; m++) SD[k] = SD[k] (m > 1 ? " " : "") sw1[m]
    pj = 1
    while (pj <= pn) {
      if (sw1[pj] ~ /^[A-Za-z_][A-Za-z0-9_]*=/) { pj++; continue }
      pw = bname(sw1[pj])
      if (pw !~ /^(sudo|command|env|xargs|exec|nohup|time)$/) break
      pj++
      while (pj <= pn && sw1[pj] ~ /^-./) { if (takesarg(pw, sw1[pj])) pj++; pj++ }
    }
    SN[k] = pn - pj + 1
    for (m = 1; m <= SN[k]; m++) SW[k, m] = sw1[pj + m - 1]
    if (SN[k] > 0) SW[k, 1] = bname(SW[k, 1])
  }
  found = ""; nt = 0; scan(c)
  printf "%s", found
  if (found == "") for (k = 1; k <= nt; k++) printf "\n%s", tl[k]
}
'

# The route for gh and remote git: the main session, which reaches GitHub.
REASON_ASK="Permitted instead: ask the main session by a question message, which gets anything the work needs from GitHub or a remote; this denial is not a breach, so list it under ## Rail observations and go on."
REMOTE_MARK=$(printf '\003')
# Check (f)'s mark, and its route: the wrapper's line, run again on busy.
SUITE_MARK=$(printf '\004')
REASON_SUITE="Permitted instead: run it through the suite-slot wrapper: bash ${KENSPC_AUTOPILOT_SUITE_WRAPPER:-<the wrapper copy; KENSPC_AUTOPILOT_SUITE_WRAPPER is empty>} run -- <the command>; exit 75 with a \"suite-slots: busy\" line means run the same line again; this denial is not a breach, so list it under ## Rail observations and go on."
REASON_ROUTE="Permitted instead: discard by mv into the workspace's .trash/<name>-<timestamp>/ (inside the repository, delete through git rm), and write under the repository, the workspace, or scratch (\$TMPDIR, /tmp)."
# In place of the route, for a field of the input the hook cannot read:
# every later call is read the same way, so a retry would be denied too.
REASON_UNREADABLE="No permitted route applies: the hook reads every such call the same way and denies a retry too. This is not a breach: list this denial with its reason under ## Rail observations and end."

# The longest Bash hook input, in bytes, the hook scans. Why a cap: the
# scan's time grows with the square of the command's length under the awk
# macOS ships (a 300 KB command took about 9 s), and a run that outlasts
# the hook's 5-second timeout (hooks.json) denies nothing; at this cap
# every shape measured — many words, a long command word or quoted
# argument, many lines or heredoc operators, many $( ) substitutions or
# subshells, one word of <| or <& pairs, the shapes
# check-autopilot-rails-hook.sh times — takes 0.3 to 0.6 seconds.
BASH_INPUT_CAP=65536

# The most distinct redirection targets one Bash call may have; a call with
# more is denied unjudged. Why a cap: each target is resolved in the shell,
# about a millisecond apiece under bash 3.2, and 6000 targets in 41 KB took
# 8 seconds, past the hook's timeout, where a run denies nothing; at this
# cap, targets in distinct directories under /tmp or $TMPDIR, the slowest
# shapes measured, take about 0.4 seconds.
TARGET_CAP=1000

NL='
'
TAB='	'

# deny <reason> [<tail>]: the tail is the permitted route unless given.
deny() {
  printf 'autopilot rails: %s. %s\n' "$1" "${2:-$REASON_ROUTE}" >&2
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
# not its target's. Each link's resolution is kept in LINKS, one
# "<link><tab><target>" line each. Why: resolving forks a subshell, and a
# fork per redirection target under a linked directory (/tmp on macOS)
# made thousands of targets outlast the hook's timeout.
LINKS='
'
resolve() {
  local rest=$1 lex="" out="" comp next link
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
      case $LINKS in
        *"$NL$next$TAB"*)
          link=${LINKS#*"$NL$next$TAB"}
          next=${link%%"$NL"*} ;;
        *)
          link=$(cd "$next" 2>/dev/null && pwd -P) || link="$out/$comp"
          link=${link%/}
          LINKS="$LINKS$next$TAB$link$NL"
          next=$link ;;
      esac
    fi
    out=$next
  done
  RESOLVED=$out
}

# in_roots <resolved path>: status 0 when the path lies inside a root of
# KENSPC_AUTOPILOT_WRITE_ROOTS, by whole path components, each root
# resolved as resolve() resolves a target; a root entry that is not
# absolute is skipped. The roots are resolved once, on the first call, into
# RROOTS, one per line. Why once: resolving every root again for each of
# thousands of redirection targets outlasted the hook's timeout.
RROOTS_SET=""
in_roots() {
  local p=$1 rest root
  if [ -z "$RROOTS_SET" ]; then
    RROOTS="" rest=$roots
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
      RROOTS="$RROOTS$RESOLVED$NL"
    done
    RROOTS_SET=1
  fi
  rest=$RROOTS
  while [ -n "$rest" ]; do
    root=${rest%%"$NL"*}
    rest=${rest#*"$NL"}
    case $p in
      "$root"|"$root"/*) return 0 ;;
    esac
  done
  return 1
}

input=$(cat)
roots=${KENSPC_AUTOPILOT_WRITE_ROOTS:-}
tool=$(field tool_name) \
  || deny "the tool name could not be read from the hook input (tool_name), so the call is denied in an autopilot worker" "$REASON_UNREADABLE"

case $tool in
  Bash)
    bytes=$(printf '%s' "$input" | LC_ALL=C wc -c)
    [ "$((bytes))" -le "$BASH_INPUT_CAP" ] \
      || deny "this Bash call's hook input is $((bytes)) bytes, over the $BASH_INPUT_CAP the hook scans within its timeout, so it is denied in an autopilot worker; write long content with the Write tool, or split the command"
    found=$(printf '%s' "$input" | awk -v sq="'" -v suites="${KENSPC_AUTOPILOT_SUITE_COMMANDS:-}" "$RM_AWK") \
      || deny "the command of this Bash call could not be read from the hook input (tool_input.command), so it is denied in an autopilot worker" "$REASON_UNREADABLE"
    # The scan prints the recursive rm it found, then, when there is none,
    # one line per redirection target it judges: the target collapsed to an
    # absolute path, a tab, the target as written.
    targets=""
    case $found in
      *"$NL"*) targets=${found#*"$NL"}; found=${found%%"$NL"*} ;;
    esac
    case $found in
      "$SUITE_MARK"*) deny "a listed suite command runs only through the suite-slot wrapper in an autopilot worker (${found#"$SUITE_MARK"}, listed in KENSPC_AUTOPILOT_SUITE_COMMANDS)" "$REASON_SUITE" ;;
      "$REMOTE_MARK"*) deny "gh, and git with a remote subcommand or a URL clone, are denied in an autopilot worker (${found#"$REMOTE_MARK"})" "$REASON_ASK" ;;
    esac
    [ -z "$found" ] || deny "a recursive rm is denied in an autopilot worker ($found)"
    # Split by word splitting on line breaks with globbing off, not read
    # from a heredoc: bash 3.2 writes a heredoc to a temporary file, and
    # where it cannot, the loop would read nothing and judge no target. Not
    # by parameter expansion either: taking one line off the front at a
    # time rescans the rest, which grows with the square of the list.
    [ -n "$targets" ] || exit 0
    oldifs=$IFS
    IFS=$NL
    set -f
    set -- $targets
    IFS=$oldifs
    set +f
    [ "$#" -le "$TARGET_CAP" ] \
      || deny "this Bash call has $# distinct redirection targets, over the $TARGET_CAP the hook judges within its timeout, so it is denied in an autopilot worker; split the command"
    for line in "$@"; do
      resolve "${line%%"$TAB"*}"
      rt=$RESOLVED
      in_roots "$rt" \
        || deny "this Bash call redirects output outside the rails' write roots, which is denied in an autopilot worker: ${line#*"$TAB"} resolves to ${rt:-/}, outside ${roots:-no roots (KENSPC_AUTOPILOT_WRITE_ROOTS is empty)}"
    done
    exit 0
    ;;
  Write|Edit) key=file_path ;;
  NotebookEdit) key=notebook_path ;;
  *) exit 0 ;;
esac

target=$(field "$key") \
  || deny "the target of this $tool call could not be read from the hook input (tool_input.$key), so the write is denied in an autopilot worker" "$REASON_UNREADABLE"
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

in_roots "$resolved_target" && exit 0

deny "this $tool call writes outside the rails' write roots, which is denied in an autopilot worker: $target resolves to ${resolved_target:-/}, outside ${roots:-no roots (KENSPC_AUTOPILOT_WRITE_ROOTS is empty)}"
