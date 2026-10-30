# Plan: Autopilot acceptance commands and worker rules (4.15.0)

## Objective

Ship the first batch of the roadmap's field suggestions — items 42, 46, 48,
and 49 of `docs/roadmap.md` § Field suggestions (not yet scheduled) — as
plugin version 4.15.0.

The outcome, as the user stated it: after this batch, the unattended batches
in dayaku-crm and JawatanKosong no longer stop to ask, or run a paid round
for nothing, on these points, and the plan and launch prompts there can drop
the rules they now carry by hand for them — anchored process-list patterns,
an acceptance entry written as a code span alone, `docs/plans/` and
`docs/tasks/` excluded from "added lines" and "name is gone" checks,
batch-unique screenshot names, and absolute redirect targets. The next one
or two real batches in those repositories are the check.

In scope:

- Item 42: description cases in S4; an entry with words after its code span;
  checks that count the batch's own documents; release checks that find a
  commit by position; S6's release checks extracted rather than typed;
  exclusions in `Zero diff:`.
- Item 46: the network route; question tags; the full rails text in subagent
  prompts (kept, with its reason stated); batch-unique S4w screenshot names.
- Item 48: the rails hook resolving a relative redirect after a `cd` in the
  same command.
- Item 49: the driver passing the worker's prompt on stdin.

Out of scope: items 43, 44, 45, 47, 50, and 51 (the review rulings and
code-fixer's context are the second batch; the cross-session items need a
brief first); item 31's F1 (a relative screenshot name landing in the
repository), which this batch's naming rule does not change; any change to
task-review, task-implement, or the review agents.

## Background

On 30 Oct 2026 the transcripts, planning handoffs, and auto memory of the
user's sessions in other repositories from 16 to 30 Oct were harvested for
plugin suggestions; the harvest is in
`~/Projects/_smoke/_analysis/field-suggestions-20261030/` and the roadmap
cites its entry IDs. The items this plan takes, with the incidents behind
them:

- S4 stopped to ask how to run a description case, since its block says to
  run every case as `<shell> <file>` (JawatanKosong fix-1-security and
  seo-phase-2) [J5].
- An entry written `` `dotnet build` from the repository root — PASS: … ``
  extracted as a description with no warning, in five JawatanKosong batches
  [J6].
- Checks over the lines a batch added, or proving a deleted name is gone,
  matched the batch's own plan and task document (dayaku-crm home-dashboard;
  JawatanKosong dx-1-layout, dx-3b-masters) [D5, J16].
- Release checks that find a commit by `HEAD~2` or "the last five commits"
  failed once any commit followed the release preparation (dayaku-crm
  ui-alignment-2, upkeep-sweep, production-prep) [D3].
- dayaku-crm plans write their release checks under `Release preparation:`,
  commands of several hundred characters each, which the main session
  copies into S6's task block by hand; dayaku-crm's planning session builds
  that block with a script of its own to avoid retyping [D21].
- `zero-diff.sh` takes no exclusion, so a plan listed every file of a
  directory but one [D20].
- A worker that needed a package from the network had no stated route
  (JawatanKosong dx-3c-uploads, fix-3, fix-7) [J2].
- Workers opened questions with topic labels, and an answer came back under
  another tag (JawatanKosong seo-2) [J7].
- Workers asked whether a summary plus a path may stand for the rails text
  in a subagent prompt (dayaku-crm user-guide-part-2, home-dashboard) [D8].
- An S4w that moved screenshots by glob from the Playwright MCP's shared
  output directory caught 12 files of another walk (JawatanKosong
  dx-3e-remove-devextreme) [J4].
- The rails hook judged `cd <dir> && … > ../x.log` against the session's
  cwd, not `<dir>`, and denied it; four batches met it [D10, J14]. Its
  header lists the case among its known misses.
- `run.sh` passes the prompt as an argument (`cmd=("$exe" -p "$prompt" …)`),
  so `ps` and `pgrep -f` show it, and a check that greps the process list
  for a test runner matches the workers themselves; four dayaku-crm batches
  met it [D9].

### The stdin probe (30 Oct 2026, Claude Code 2.1.314, macOS)

Run while this plan was drafted, from a scratch directory, USD 0.28 in all:

- `claude -p --session-id <uuid> --max-budget-usd 0.3 --output-format json < p1.md`,
  `p1.md` asking for the reply `PLUMQUARTZ` and holding a `"`, a backtick,
  and `é`: exit 0, result `PLUMQUARTZ`. The transcript's first user text
  equals `p1.md` byte for byte, its trailing newline included.
- `claude -p --resume <uuid> … < p2.md`, asking for `TEALOSPREY`: exit 0,
  result `TEALOSPREY`.
- Four seconds into the first run, `ps -axo args | grep -c '[P]LUMQUARTZ'`
  counted 0, and the same grep for the session id, the positive control,
  counted 2.

So `claude -p` takes its prompt from stdin with `--session-id` and with
`--resume`, and the prompt then appears in no process's arguments. One
difference from today: `run.sh` reads the file with `$(cat …)`, which drops
trailing newlines, while stdin keeps them; the worker then receives the
file as written, one or more trailing newlines longer.

## Decisions settled in Discover (30 Oct 2026, the user)

1. An `Acceptance:` entry whose text opens with a code span but does not
   extract as a command is caught before any worker starts: Phase 0 names it
   and asks whether to fix the spec or run it as a description. The
   extractor does not guess what the words after the span mean.
2. The rails text stays in full in every subagent prompt and in the agent
   dispatches' CUSTOM_INSTRUCTIONS; the preamble states that a summary with
   a path does not meet the rule, and why.
3. The driver passes the prompt on stdin, as the probe above supports.
4. A new `## Autopilot` label, `Release checks:`, with `Acceptance:`'s
   grammar, extracted by the same script and run by S6 after its last
   commit.
5. The batch runs under `/kenspc-autopilot` in plugin mode as version
   4.15.0.
6. The review fix loop is bounded, ruled before the launch. The first S5
   round after S3b and its narrowed review (`-s3c`) run as the skill says.
   From the second narrowed review on, a HIGH row still goes to an S5, and a
   MEDIUM or LOW row that names text an S5 of this batch added is not fixed
   in this run: the main session rules it a follow-up and lists it on the
   reviewer report's `Follow-up candidates` line, for the user to put on the
   roadmap. Why: this batch edits the rails hook, and in the batches that
   last changed it, each review round found new edge cases; in batch K five
   narrowed reviews each found new MEDIUM rows in the text the previous fix
   had just added, and the loop ended only when the user stopped it.

## Technical Approach

The changes stay inside the autopilot skill, its scripts, its rails hook,
generate-plan's pre-print check for the `## Autopilot` section, and the
guards that hold the scripts. Three principles decide the details:

- **Catch it before money is spent.** A spec defect the main session can
  see in text (a span-led description, a description under
  `Release checks:`) is found by Phase 0's trial extraction, not by a paid
  worker. Why: the start checks exist so that every condition a worker
  assumes is checked before the first launch.
- **One extractor, one grammar.** `Release checks:` reuses
  `extract-acceptance.sh` with a field argument, and its sub-bullets follow
  `Acceptance:`'s grammar, so the `cmp` re-check S4 runs is the same check
  S6 runs. Why: the extractor exists because main sessions that wrote their
  own extractors got the backtick delimiting wrong.
- **The writing rules live with the grammar.** The guidance on how to write
  a check — a code span alone, the batch's documents excluded, commits found
  by subject — goes into the autopilot skill's `## Autopilot` section, which
  generate-plan reads by path. Why: AGENTS.md makes that section the one
  source of the grammar, and a second copy in generate-plan would drift.

### The extractor's new output

`extract-acceptance.sh <spec file> <out dir> [<field>]`: `<field>` is
`Acceptance` (the default, today's behaviour) or `Release checks`. The first
output line stays `commands: <n>, cases: <m>`, which Phase 0, Phase 3, and
S4's re-check parse; a second line follows, `span-led: none` or
`span-led: <nn>, <nn>, …`, naming each `<nn>.case` whose text opens with a
backtick run. Why a second line and not a new exit code: an exit other than
0 is today a stop at every caller, and a span-led entry is a question, not
a malformed field.

### The zero-diff exclusion form

A `Zero diff:` path written with a leading `!` is an exclusion:
`apps/portal/src/bookings, !apps/portal/src/bookings/booking-page.test.tsx`.
`zero-diff.sh` drops `--literal-pathspecs` and passes each path as
`:(literal)<path>` and each exclusion as `:(exclude,literal)<path>`, so a
bracket in a path is still no glob. A paths file of exclusions only is
refused (exit 2), since `git diff` with only exclusions compares everything
else. The count line becomes `compared: <n> paths, <m> excluded`, `<n>`
the paths without `!` and `<m>` those with it; the skill's Phase 2 § The
zero-diff check holds `<n>` to the field's paths without `!` and `<m>` to
its `!` paths, a difference in either being the stop it is today. The
absent-at-the-baseline check, in the script and before the first launch,
resolves an exclusion by its path with the `!` removed. A path whose own
name begins with `!` cannot be listed.

### The rails hook and `cd`

The hook already splits a Bash command into simple commands. It gains a
per-command working directory: a simple command `cd <word>` whose word is
one literal path — no `$`, backtick, glob character, or `~` — and which is
joined to what follows by `&&` or `;` at the top level (not inside `( )`,
not before a `|`) sets that directory, resolved against the current one, for
the redirections after it, a subshell after it included, since a subshell
inherits the directory. An absolute word sets the directory even when the
current one is unknown. A `cd` whose target the hook cannot read as a
literal — `cd` with no word (the home directory), `cd -` (the previous
directory), a word that opens with `-` (an option), or more than one
word — or one joined by `||`, leaves the directory unknown, and a later
relative target is then judged as today's "relative target with no absolute
cwd" (not judged). The header's known-miss line for the case is replaced by
the forms still missed (`cd` inside a subshell or a pipeline, `pushd`, a
`cd` whose target is not a literal, a `cd` joined by `||`). Why this scope:
the four incidents were all `cd <literal> && … > <relative>`, and a
narrower rule that bash's scoping cannot contradict is safer than a wider
one the scanner cannot read.

### The driver and stdin

`run.sh` runs `"$exe" -p --session-id "$session" … < "$prompt_file"` and,
on a resume, `"$exe" -p --resume "$session" … < "$prompt_file"`, with no
prompt argument; it no longer reads the file into a variable. Its existing
refusals (no file, an empty or whitespace-only file) stay. `run.ps1` gets
the same change through its process start's standard input. The stdin was
empty until now (roadmap item 11 names "the empty stdin" among what a
`run.ps1` fix must keep, which this changes); it becomes the prompt file,
still never a terminal. Why stdin and not a short pointer prompt: the worker
receives the text it receives today, with no extra read that could be
skipped.

## Implementation Steps

Step 1 comes first; Steps 2–9 depend on it only where stated; Step 10 comes
last.

### Step 1: The extractor's field argument and span-led line

- **Do:** in `plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh`,
  the optional third argument
  selects the field (`Acceptance` or `Release checks`; any other value is
  exit 2); the label match takes the field's name, note included; the
  second output line lists span-led cases; the stderr reasons that name
  `Acceptance:` today name the field read. The header's usage and output
  sections say so.
- **Guard:** `scripts/check-autopilot-scripts.sh` gains fixtures: a
  `Release checks:` field beside an `Acceptance:` field, each extracted
  alone; a span-led entry (`` `dotnet build` from the root — PASS: x ``)
  reported on the second line; an entry that opens with prose and holds a
  span later, not reported; a bad field name, exit 2. Each with a self-test
  mutant: the field argument ignored, and the span-led test dropped.
- **Acceptance:** `bash scripts/check-autopilot-scripts.sh` and
  `bash scripts/check-autopilot-scripts.sh --self-test` exit 0, and the
  self-test reports both new mutants killed.

### Step 2: Phase 0 asks about span-led entries (depends on Step 1)

- **Do:** in the autopilot skill's start checks, the `Acceptance:` trial
  extraction (repo mode; in brief entry before S2) reads the `span-led:`
  line. A non-empty list is a question to the user before any worker: the
  entries quoted, and two answers — stop to fix the spec (nothing is
  spent), or run them as descriptions, which the state file records under
  `questions answered:`, ending `(user)`, and S4's block lists as
  description cases. The prose states, at that question: "In a session that
  cannot ask (a system reminder to work without stopping), …" the run stops
  before the first launch, naming the entries, since the words after a span
  may say where or how the command runs and the skill does not guess them.
  Templates § The stop conditions names the new stop under "Stops stated at
  their own steps", whose count goes from seven to eight. A span-led entry
  under `Release checks:` is a `.case`, and so already the settings stop
  of Step 4.
- **Acceptance:** acceptance case A2 passes.

### Step 3: S4 runs a description case (no dependency)

- **Do:** in the repo-mode S4 block, the run paragraph says that
  `<shell> <file>` is the form for a `<nn>.cmd` or `<nn>.corrected.cmd`; a
  `<nn>.case` is run as its text describes, in this session, and its reply
  lines name each command run for it with its exit code, and PASS or FAIL
  judged against the criterion. The S4 bullet below the block says the same
  in one sentence, with the reason (two batches stopped to ask).
- **Acceptance:** acceptance case A3 passes.

### Step 4: `Release checks:` (depends on Step 1)

- **Do:** in the autopilot skill:
  - the label table gains `Release checks:` — `none`, or one sub-bullet per
    check in `Acceptance:`'s grammar, each one code span; default `none`;
  - Phase 0, when the section holds a `Release checks:` field other than
    `none`, in both modes (in brief entry before S2, as the `Acceptance:`
    trial runs): the main session saves the spec to
    `<workspace>/_prompts/<batch>-spec.md` — in plugin mode too, so the
    workspace layout's `(repo mode)` note no longer covers that file — and
    extracts the field with `Release checks` as the third argument into
    `<workspace>/_prompts/<batch>-release-cmds/`, which S6 compares
    against; a field that yields any `.case` is the settings stop — a
    release check is a command, and a description there is a value outside
    the field's grammar. An absent field, or `none`, runs no extraction.
    Why: the extractor exits 2 when the spec has no such field, and an
    absent `Release checks:` is the default, not an error;
  - both S6 blocks gain a paragraph, written when the field names checks:
    after the last commit, extract the checks again with the same copy
    into `<workspace>/_prompts/<batch>-<tag>-release-recheck/`, `cmp` each
    file against `<batch>-release-cmds/` as S4 does against its
    directory, run each as `<shell> <file>` from the repository root at
    that commit — `<shell>` filled in as the repo-mode S4 block fills it,
    and, in repo mode only, through the suite-slot wrapper when
    `Suite limit:` lists its prefix — and reply with each check's file and
    exit code; a failing check is reported, not fixed;
  - Phase 4: the user report lists each release check with its exit code,
    and a FAIL is named in the report's first lines; the main session
    launches no S5 for it. Why: the checks test the release commits, and
    what to do about a failed one before the tag is the user's call.
- **Acceptance:** acceptance case A3 passes, including its release check.

### Step 5: Writing rules for checks (depends on Step 4)

- **Do:** after the label table in § The `## Autopilot` section, a short
  paragraph, "Writing a check", stating with a reason each: an `Acceptance:`
  or `Release checks:` command is one code span alone before ` — PASS: `; a
  check over the lines the batch added, or one proving a name is gone,
  excludes the spec's and the task document's paths — `docs/plans/` and
  `docs/tasks/` where the chain writes them — since both sit in the tree
  until S6 removes them;
  a check finds a commit by its subject, never by its position, since S6 and
  later fixes add commits. In generate-plan's Autopilot element, the
  pre-print check's third item ("every `Acceptance:` sub-bullet holds
  ` — PASS: `") covers `Release checks:` sub-bullets too, and the check
  gains a fourth item: a sub-bullet of `Acceptance:` or `Release checks:`
  whose text opens with a code span has nothing between the span and
  ` — PASS: `; the item count in its sentence ("check three things")
  follows.
- **Acceptance:** `bash scripts/check-all.sh` exits 0; the paragraph names
  the three rules, each with its reason, and generate-plan's check names
  both fields (a reading by the reviewers).

### Step 6: `Zero diff:` exclusions (no dependency)

- **Do:** `zero-diff.sh` as § The zero-diff exclusion form says; the label
  table's `Zero diff:` row and Phase 2 § The zero-diff check describe the
  `!` form.
- **Guard:** `check-autopilot-scripts.sh` fixtures: an excluded file inside
  a listed directory changed (exit 0); a non-excluded sibling changed
  (exit 1); a bracketed path still literal; a file of exclusions only
  (exit 2). Self-test mutants: the exclusion dropped, and the literal magic
  dropped.
- **Acceptance:** the guard and its self-test exit 0, both mutants killed.

### Step 7: The driver passes the prompt on stdin (no dependency)

- **Do:** `run.sh` and `run.ps1` as § The driver and stdin says. Each
  driver resolves `<prompt-file>` to an absolute path before it changes to
  `<cwd>`, since it now opens the file after that change, where a relative
  path would name another file. Each driver's header (`<prompt-file>`
  "read from this file with cat", "stdin from /dev/null" in `run.sh`, "an
  empty stdin" in `run.ps1`) and the skill's § The driver ("stdin from
  `/dev/null`") say the prompt arrives on stdin. Each driver's
  `--self-test` gains a case whose stub records its stdin and its argv:
  the prompt arrives on stdin byte for byte (a `"`, a backtick, a
  non-ASCII character, and a trailing newline in it), and no argument
  holds it, on a launch and on a resume, the launch given the prompt file
  by a relative path.
- **Acceptance:** `bash plugins/kenspc/skills/autopilot/scripts/run.sh
  --self-test` and `pwsh -NoProfile -File
  plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test` print
  `self-test passed`; acceptance case A4 passes.

### Step 8: The rails hook follows a literal `cd` (no dependency)

- **Do:** `plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh` as § The
  rails hook and `cd` says, header included.
- **Guard:** `scripts/check-autopilot-rails-hook.sh` fixtures, as simulated
  tool-input JSON whose cwd is `<root>/sub`, `<root>` the fixture's
  repository root and the only write root that matters here; each outcome
  differs from what the other reading would give:
  - `cd <root>/sub/x && echo a > ../../y.log` allowed (`<root>/y.log`;
    read from the input's cwd it would lie outside the root);
  - `cd x; echo a > ../../y.log` allowed, the same way;
  - `cd / && echo a > y.log` denied (`/y.log`);
  - `(cd /; echo a) > y.log` allowed: the redirection is read from the
    input's cwd, not from `/`;
  - `cd / | cat > y.log` allowed, the same way;
  - `cd "$D" && echo a > ../../y.log`, `cd / || echo a > ../../y.log`,
    `cd - && echo a > ../../y.log`, and `cd && echo a > ../../y.log`
    allowed: the directory is unknown and the target not judged, where the
    input's cwd would deny it.

  Self-test mutant: the `cd` tracking removed, which reads every target
  from the input's cwd and so turns the first three fixtures and the last
  group red.
- **Acceptance:** the guard and its self-test exit 0; acceptance case A5
  passes.

### Step 9: Worker rules in the preamble and S4w (no dependency)

- **Do:** in the preamble:
  - § 1: the first line is `question <tag>: …` with `<tag>` filled in as the
    worker's own tag (`<batch>-s3`, not a topic label), at the same time
    and in the same way as `<role>` — when `_prompts/<batch>-<tag>.md` is
    assembled at the launch (§ Launch, wait, return) — and § 1 says the tag
    is that literal value;
    § The message protocol says the answer's first line repeats the tag of
    the question's first line as written, whatever it is.
  - § 3: after "No resource the brief does not name", one sentence: a
    package the project's lockfile or the spec already names, or a tool or
    a browser build the work needs, that the machine does not hold is asked
    for, and `<main name>` fetches it and answers with a local path; this
    is a route, not a new rail. A package neither names is a new
    dependency, which stays stop condition 7 (a). Phase 2 § How the main
    session rules gains how the main session answers it: fetch it, check
    it against the registry's integrity hash where the registry publishes
    one, place it in the workspace, and answer with its path.
  - § 3, at "write them into every subagent prompt": a summary with a path
    to the full text does not meet the rule, with the reason — a subagent
    may never read the file, and the rails hook holds only part of the rails.
  - S4w block, Screenshots rule: each screenshot is given a file name that
    begins `<batch>-walk-`, and each is moved by its exact name, never by a
    glob, since the Playwright MCP's output directory is shared by every
    session on the machine.
- **Acceptance:** `bash scripts/check-all.sh` exits 0, and the reviewers
  find each of the four sentences with its reason (no acceptance case runs
  S4w or a network fetch).

### Step 10: Documentation (depends on Steps 1–9)

- **Do:** the documents in § Documentation impact.
- **Acceptance:** `bash scripts/check-all.sh --self-test` exits 0 and its
  counts match `docs/release-checklist.md`.

## Testing Strategy

Each script change is held by its guard's fixtures and a self-test mutant
that must turn the guard red (Steps 1, 6, 7, 8); each guard's header,
which lists its fixtures and counts its self-test mutants, is updated with
them. The skill-text changes are held by the acceptance cases below, run
as nested headless sessions on seeds, and by the reviewers' reading. The stdin change, which every later
launch depends on, was probed before this plan (§ The stdin probe) and is
exercised live by every worker of acceptance case A3, which the nested
main session launches through its own copy of HEAD's driver (A2 stops
before any worker starts), and by A5's session.

## Risks and Mitigations

- **The stdin change breaks every launch.** Mitigation: the probe; both
  drivers' self-tests; A3 and A5 launch real sessions through the changed
  driver. The main session's own launches in this batch use the installed
  4.14.1 driver copy, so a broken driver cannot stop the batch itself.
- **A caller parses the extractor's output and trips on the new line.**
  Mitigation: the counts line stays first and unchanged; the reviewers grep
  the skill for every parse of the output (`commands:`), and S4's `ls`/`cmp`
  re-check compares files, not output.
- **The hook's `cd` tracking allows a write it should deny.** Mitigation:
  only a literal `cd` joined by `&&` or `;` at the top level moves the
  directory; a fixture holds `cd /` followed by a relative write as denied;
  AGENTS.md's rule for hooks that parse a harness-owned format is met by the
  simulated tool-input fixtures and A5.
- **`:(exclude,literal)` magic on an old git.** Mitigation: pathspec magic
  has been in git since 1.9; the guard runs it on this Mac's git, and the
  script's header names the minimum.
- **An older plugin reads a spec with `Release checks:`.** It ignores the
  unknown label and names it on the line after the settings line, so the
  checks are not run, but the user sees why.
- **`run.ps1`'s inner pwsh does not hand its redirected stdin to the
  native `claude`.** The driver starts a pwsh that runs `claude`, and
  whether the native call reads the outer redirection has not been probed.
  Mitigation: the self-test's stub records its stdin byte for byte, so a
  lost or re-encoded prompt fails `run.ps1 --self-test` (A1) before the
  batch ends.
- **The installed 4.14.1 hook also fires in A5's session.** Whether a
  `--plugin-dir` copy replaces the installed plugin of the same name for
  its hooks, or runs beside it, has not been probed here; beside it, the
  old hook denies A5's first command. Mitigation: before an A5 FAIL is
  classified as a defect, the main session checks for this cause, as
  Phase 3's corrected-case evidence asks.

## Documentation impact

- `plugins/kenspc/README.md` — the autopilot section (the `## Autopilot`
  labels, S4, S6, the walk) and § Known behavior (the rails hook's misses):
  `Release checks:`, the span-led question, description cases in S4, the
  `!` form of `Zero diff:`, the prompt on stdin, the network route, the
  question-tag echo, batch-unique screenshot names, and the hook's `cd`
  handling. Steps 2–9. Also the skills table's generate-plan row, which
  names the pre-print checks ("every `Acceptance:` case for ` — PASS: `"):
  `Release checks:` and the span-to-PASS check. Step 5.
- `README.md` — N/A for this document: the autopilot skill's summary row
  ("Runs one batch unattended … two human gates") and the generate-plan row
  name neither the `## Autopilot` fields, the hook, nor the pre-print
  checks.
- `plugins/kenspc/CHANGELOG.md` — a `## 4.15.0 — unreleased` entry:
  Added (`Release checks:`, the `!` exclusion, the span-led question),
  Changed (S4's description cases, the stdin prompt, the preamble's
  sentences, generate-plan's pre-print check), Fixed (the hook's `cd`).
  Every step.
- `docs/roadmap.md` — items 42, 46, 48, and 49 leave the file at release;
  item 31's F1 stays; item 11's mention of "the empty stdin" is reworded to
  the prompt file on stdin (Step 7); the remaining field suggestions are
  renumbered at release, with the references inside the file that follow
  the numbers — the section intro's "Items 49–51 are workarounds" and item
  47's "they are items 50 and 51".
- `docs/release-checklist.md` — N/A for this document: the steps add
  fixtures and mutants to existing guards and no guard file, so
  `guards run: 17` and `self-tests run: 16` stay, and no step changes what
  rows 11 and 15 describe; the new behavior is accepted by A2–A5.
- `AGENTS.md` — N/A for this document: no convention, orchestration
  pattern, or guard set changes; the guards gain fixtures, not files.
- `CLAUDE.md` — N/A for this document: no Claude Code-specific rule changes.
- `docs/dry-runs/README.md` — N/A for this document: the report convention
  is unchanged.
- `plugins/kenspc/references/plan-document-example.md` — N/A for this
  document: the example holds no `## Autopilot` section, and the plan
  format is otherwise unchanged.
- `plugins/kenspc/references/task-document-example.md` — N/A for this
  document: the task-document format is unchanged.

## Open Questions

None. The four design questions were ruled in Discover (§ Decisions settled
in Discover), and the stdin question was settled by the probe.

## Clarifications during implementation

1. (S2, task-list confirmation; ruled by the main session) The ten tasks
   are confirmed: Tasks 1–9 map to Steps 1–9 and Task 10 is the Doc-sync
   task; no task lies outside the plan.
2. (S2; ruled by the main session) Task 6 depends on Task 1 although
   Step 6 says "no dependency": sequencing only, since both edit
   `scripts/check-autopilot-scripts.sh`'s header and its self-test mutant
   count. Why: it changes the order, not what Step 6 builds, and avoids a
   count conflict in one shared file.
3. (S2; ruled by the main session) Acceptance cases A1–A5 run at S4; each
   task's criteria are checks the implementer can run or read, naming the
   case that holds them later, as § Testing Strategy places them.
4. (S2; ruled by the main session) Removing roadmap items 42, 46, 48, and
   49 and renumbering the remaining field suggestions happen in the release
   commit (S6), as § Documentation impact says ("at release"); the Doc-sync
   task rewords only item 11's "the empty stdin" and carries Step 10's
   criterion that `bash scripts/check-all.sh --self-test` counts match
   `docs/release-checklist.md`.
5. (S3; ruled by the main session) S3's uncommitted Task 8 edit put two
   apostrophes ("bash's scoping", "the input's cwd as cdsep()") into
   comments inside the rails hook's single-quoted `RM_AWK` program, which
   ended the shell quote; the hook then exited 2 on every call, and the
   worker, which runs that hook through `--plugin-dir`, could make no Bash
   or Edit call to fix it. The main session reworded the two comments
   ("the scoping of bash", "the cwd of the input") in the working tree and
   committed nothing; `bash -n` then exited 0, and the hook allowed
   `git status` (exit 0) and denied `rm -rf /x` (exit 2) under the worker
   marker. The rest of the Task 8 edit stays as S3 left it, for S3 to
   finish, test, and commit. Why: no worker could act while the hook was
   broken, and the reword changes comment text only. From here on, an
   edit to the hook is made on a scratch copy, checked with `bash -n` and
   `scripts/check-autopilot-rails-hook.sh`, then copied into place.
6. (S3, Task 7 BLOCKED; ruled by the main session) `run.ps1` delivers the
   prompt by having its inner script pipe the file's raw bytes to the
   native `claude` (`Get-Content -AsByteStream -Raw -LiteralPath <prompt> |
   & <exe> @argv`), not through `Start-Process -RedirectStandardInput`, and
   its `#Requires -Version` moves from 7.3 to 7.4, with the header's reason
   and the plugin README's "PowerShell 7.3 or later" updated. Evidence:
   S3's probe on pwsh 7.6.7 (macOS) showed `-RedirectStandardInput` adds a
   line end (150,000 bytes in, 150,001 read), so Step 7's byte-for-byte
   self-test fails; the byte pipe passed the whole `run.ps1 --self-test`.
   Why: Step 7 asks for the prompt byte for byte, the pipe is still the
   process's standard input (Decision 3), and PowerShell 7.3 is out of
   support. This departs from § The driver and stdin's "through its
   process start's standard input" on that evidence.
7. (S3's review, first round; ruled by the main session) All 16 findings
   are fixed. For the rails hook rows (E1/B3, B1, B2) the cd tracking is
   never looser than the hook before this batch where the tracking cannot
   be sure a `cd` ran: a literal `cd` joined by `;` or a line end moves the
   tracked directory only when its target is an existing directory when
   the hook runs; a `cd` inside a compound or function body, or in a
   pipeline, moves nothing; after a `||` the directory is unknown, as
   § The rails hook and `cd` says. Every hook edit is made on a scratch
   copy, checked, then copied into place.
8. (S3's review, second round; ruled by the main session) V1 (README and
   CHANGELOG describe the tracking as it stands), F1 (a literal `cd` whose
   run is not certain leaves the tracked directory where it was before its
   and-or list), and F2 (at most 200 tracked `cd` commands per call, under
   the hook's 5-second timeout) are fixed. Step 8's fixture
   `cd / || echo a > ../../y.log` becomes denied: the `echo` runs only when
   `cd /` failed, so in the input's cwd, where `../../y.log` lies outside
   the root, and "allowed" there would be a write outside the roots by
   bash's own semantics.
9. (S3's verdict FAIL; ruled by the main session) Three cd-tracking gaps
   remain after S3's review, each no looser than the hook before this
   batch, which read every relative target against the input's cwd:
   - V2 (regression-verifier, MEDIUM): a `;` or a line end inside a
     compound body resets the tracked directory, so
     `cd /etc && { true; echo a > passwd; }` is allowed. FIX in the next
     review's fix round (S3b, or an S5): a separator inside a body keeps
     the tracked directory, with deny fixtures for the `{ }`, `if`, `for`,
     and line-end forms.
   - F3 (code-fixer, MEDIUM) and SG1 (the security-guidance hook, flagged
     HIGH): a `cd` after `||` (`false || cd /etc && echo a > passwd`), a
     `cd` followed by `||`, and a `cd` inside a body
     (`if true; then cd /etc; fi; echo a > passwd`) are judged against one
     directory only. DEFER to a follow-up, listed on the reviewer report's
     `Follow-up candidates` line: closing them needs a set of candidate
     directories in place of the single tracked one, a design beyond
     roadmap item 48, which removed false denials of
     `cd <literal> && … > <relative>`; the hook stays a best-effort guard
     behind the preamble's rails, which still bind.

## Autopilot

- Mode: plugin
- Version: 4.15.0
- Budget: USD 300
- Must read: CLAUDE.md, AGENTS.md, docs/roadmap.md, plugins/kenspc/skills/autopilot/SKILL.md, plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh, plugins/kenspc/skills/autopilot/scripts/zero-diff.sh, plugins/kenspc/skills/autopilot/scripts/run.sh, plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh, /Users/kenspc/Projects/_smoke/_analysis/field-suggestions-20261030/dayaku-crm.md, /Users/kenspc/Projects/_smoke/_analysis/field-suggestions-20261030/jawatankosong.md
- Allowed files: plugins/kenspc/skills/autopilot/SKILL.md, plugins/kenspc/skills/autopilot/scripts/extract-acceptance.sh, plugins/kenspc/skills/autopilot/scripts/zero-diff.sh, plugins/kenspc/skills/autopilot/scripts/run.sh, plugins/kenspc/skills/autopilot/scripts/run.ps1, plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh, plugins/kenspc/skills/generate-plan/SKILL.md, scripts/check-autopilot-scripts.sh, scripts/check-autopilot-rails-hook.sh, scripts/fixtures/, plugins/kenspc/README.md, README.md, plugins/kenspc/CHANGELOG.md, plugins/kenspc/.claude-plugin/plugin.json, .claude-plugin/marketplace.json, docs/roadmap.md, docs/release-checklist.md, docs/dry-runs/, docs/plans/, docs/tasks/
- Zero diff: plugins/kenspc/agents/, plugins/kenspc/shared/, plugins/kenspc/commands/, plugins/kenspc/references/, plugins/kenspc/hooks/hooks.json, plugins/kenspc/skills/task-review/, plugins/kenspc/skills/task-implement/, plugins/kenspc/skills/generate-brief/, plugins/kenspc/skills/generate-task/, plugins/kenspc/skills/diagnose-bug/, plugins/kenspc/skills/prototype/, plugins/kenspc/skills/retro/, plugins/kenspc/skills/init-project/, plugins/kenspc/skills/generate-guide/, plugins/kenspc/skills/autopilot/scripts/suite-slots.sh, plugins/kenspc/skills/autopilot/scripts/temp-candidates.sh
- Acceptance:
  - A1 (guards): `bash scripts/check-all.sh`, `bash scripts/check-all.sh --self-test`, `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test`, and `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test` at the batch's HEAD — PASS: every command exits 0, the two drivers print `self-test passed`, and the self-test counts equal `docs/release-checklist.md`'s
  - A2 (the span-led question, a session that cannot ask): a nested repo-mode autopilot, headless, made a session that cannot ask with `APPEND_SP="Work without stopping; do not ask clarifying questions."` on its launch line, launched with `AUTOPILOT_PLUGIN_DIR` the plugin directory, so it runs HEAD's skill and copies HEAD's driver, on a one-task seed whose spec's `Acceptance:` holds one entry: the code span `true`, then the words `from the seed's root`, then its PASS criterion — PASS: the run ends before any worker starts (no `start` line in its timeline), its final message names the entry and the words after the span, and its state file records the stop
  - A3 (a description case and a release check): a nested repo-mode autopilot, headless, as A2, on a one-task seed with `Standalone review: off`, `Walk: off`, `Acceptance:` holding one command and one description case whose text holds A4's marker word, and `Release checks:` holding one check, the code span `git log --format=%s | grep -q 'remove batch'` (the commit found by its subject, as Step 5's writing rule asks) with the criterion exit 0 — PASS: S4 runs the description case without a question to the main session and replies with the commands it ran and their exit codes; S6 replies with the release check's file and exit 0; the user report lists the release check with its exit code
  - A4 (no prompt on the command line): during A3, while the nested run's S4 runs, `ps -axo args` grepped in the bracket form (`grep -c '[M]ARKER'`) for a marker word that only A3's description case text holds — text the nested S4's task block copies into its prompt as written, and that the nested autopilot's own launch prompt does not hold — PASS: the count is 0, and the same grep for the nested S4's session id, the positive control, counts at least 1
  - A5 (the hook live): a session started through HEAD's `plugins/kenspc/skills/autopilot/scripts/run.sh` (not the batch's driver copy, which is the installed version's), with `AUTOPILOT_PLUGIN_DIR` the plugin directory and `AUTOPILOT_WORKSPACE` the workspace, its cwd a throwaway seed one level under the workspace, `<workspace>/<batch>-a5/`, whose prompt runs `mkdir -p <workspace>/a5/x && cd <workspace>/a5/x && echo a > ../../a5.log` — a target that, read against the seed's cwd, lies outside every root — and then `cd / && echo b > a5-denied.log` — PASS: the first command runs and `<workspace>/a5.log` holds `a`; the second is denied with `autopilot rails:` in its error, and neither `/a5-denied.log` nor `<workspace>/<batch>-a5/a5-denied.log` exists
- Release preparation: default
