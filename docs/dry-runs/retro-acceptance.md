# Retro end-to-end acceptance on a dayaku-crm clone (4.14.0)

`/kenspc-retro` run twice on 2026-10-21, headless, against `b1d6515`, in a
clone of dayaku-crm at `~/Projects/_smoke/retro-accept/`. The installed
plugin (4.13.0) has no retro skill, so every session ran the `--plugin-dir`
copy. dayaku-crm is a private project: this record names kinds, counts,
and commit subjects of the clone only, and quotes no finding text.

## Setup

- `git clone ~/Projects/Diagnohab/dayaku-crm ~/Projects/_smoke/retro-accept`;
  the clone's HEAD at setup is written `<setup HEAD>` below, its hash
  withheld as a piece of dayaku-crm's history.
- `.kenspc/runs` in the clone: a symlink to
  `~/Projects/Diagnohab/dayaku-crm/.kenspc/runs` (56 GB, 96 run
  directories), used read-only.
- Dependencies, with the commands dayaku-crm's instruction files name: a
  `pnpm install` (exit 0) and a `dotnet build` (exit 0, 0 warnings), which
  restores the API's packages.
- Before the runs: `git -C ~/Projects/Diagnohab/dayaku-crm status --porcelain`
  printed nothing; 96 run directories.

Every call was started detached from the clone and waited on with
`timeout 570 caffeinate -w <pid>`:

```
claude -p "<prompt or reply>" [--resume <session id>] --output-format json \
  --plugin-dir /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc \
  --permission-mode acceptEdits --allowedTools=Bash,Read,Grep,Glob
```

A first launch with `--allowedTools=Bash` alone (session
`4fa7e234-e403-4a18-9a54-9fa402df7062`, USD 0.24) stopped at once: the clone
is an untrusted workspace, so the session's Read of the skill file outside
it was refused, and it ended without touching the clone. The runs below add
`Read,Grep,Glob`.

## First run: `/kenspc-retro`

Session `1dfe363b-2aa1-41ad-a49f-393e574f0a90`, 14:11:54 to 14:27:54.

| # | The session asked | Reply |
|---|---|---|
| 1 | The window question: the default window `last 20` holds 20 batches and 45 reviews, 2026-10-08 to 2026-10-19; run it or name another | `run the default window` |
| 2 | Adopt or reject, with a reason, for each of four verified proposals P1–P4, asked in one message (a fifth proposal was dropped by its verifier) | `P1 adopt, P2 reject: acceptance-test rejection, P3 reject: acceptance-test rejection, P4 reject: acceptance-test rejection` |

The proposals asked about, by kind: P1 `untested-rule` (cost 55, 16
batches), P2 `uniform-fixture-hides-branch` (28, 7), P3 `doc-out-of-sync`
(26, 13), P4 `untested-state-reset` (25, 6). Five `retro-classifier`
dispatches (one `derive`, four `classify`) and five `retro-verifier`
dispatches ran; per the record, three verifiers returned ADJUSTED, one
HOLDS, and one FAILS.

Before P1's commit the session ran `pnpm lint` (exit 0) and recorded why
it left out `pnpm test`.

`git -C ~/Projects/_smoke/retro-accept log --oneline <setup HEAD>..HEAD`:

```
12ad6086 docs(repo): record 2026-10-21 retro
0b0dfccc <subject withheld: it paraphrases the adopted proposal>
```

One commit for the adopted proposal, then the record commit, each subject
adapted to dayaku-crm's required scopes. `extract.md` in the run's
`RETRO_DIR` carries the coverage line: `Coverage (measure_time.py): 20
batches with a timeline, 114 role sessions read, 0 with an unmeasured
subagent split, 0 with no .exit.`

The record `docs/retros/2026-10-21.md`, its section headings:

```
# Retro record — 2026-10-21
## Window and coverage
## Follow-up
## Kinds
## Adopted          (A1)
## Rejected         (R1-R3)
## Dropped by verification   (D1)
## Pending
## Failed
## Runner-ups
## For the kenspc plugin
## For your global files
```

## Second run: `/kenspc-retro last 20`

Session `a34d61a8-76eb-4a49-b835-a578815a19ad`, 14:28:11 to 14:38:28. The
window argument meant no window question.

| # | The session asked | Reply |
|---|---|---|
| 1 | Not a question of the skill: after Phase 2 the session stopped on its own, since the window equals the record's, and asked A (stop, no record) or B (finish) | `B` |
| 2 | Adopt or reject, with a reason, for each of four verified proposals, asked in one message | `1 reject: acceptance-test rejection, 2 reject: acceptance-test rejection, 3 reject: acceptance-test rejection, 4 reject: acceptance-test rejection` |

- Follow-up, in the record and in `rank.md`: kind `untested-rule`, cost,
  then 55, now 68. The window and its 365 rows are the first run's, so the
  difference is the same rows labelled again; the session wrote that under
  the table.
- The first run's three rejected kinds were marked and skipped in
  `rank.md`: `doc-out-of-sync` (batches 13 then, 13 now),
  `uniform-fixture-hides-branch` (7, 7), `untested-state-reset` (6, 6). None
  is among the second run's proposals: `weak-test-assertion` (24, 14
  batches), `departs-written-convention` (22, 12), `comment-out-of-sync`
  (17, 8), `state-outlives-context` (17, 6). Four `classify` dispatches (no
  `derive`: the kinds came from the record) and four `retro-verifier`
  dispatches ran.

`git -C ~/Projects/_smoke/retro-accept log --oneline <setup HEAD>..HEAD`:

```
fb788be5 docs(repo): record second 2026-10-21 retro
12ad6086 docs(repo): record 2026-10-21 retro
0b0dfccc <subject withheld: it paraphrases the adopted proposal>
```

The record `docs/retros/2026-10-21-2.md`, its section headings:

```
# Retro record — 2026-10-21
## Window and coverage
## Follow-up
## Kinds
## Adopted          (none)
## Rejected         (R1-R4)
## Dropped by verification
## Pending
## Failed
## Runner-ups
## For the kenspc plugin
## For your global files
```

## After both runs

- `git -C ~/Projects/Diagnohab/dayaku-crm status --porcelain` printed
  nothing, as before; the real checkout has no `.kenspc/retros/`.
- The symlink `.kenspc/runs` was removed by its own path, the real
  directory still held 96 run directories, and then the clone was removed.

## Cost

USD 13.52 in all: the refused launch USD 0.24, the first run USD 6.99, the
second run USD 6.29 (each session's last `total_cost_usd`, subagents
included).

## Observations

- Both runs put their proposals to the user in one message, where the
  skill says each is put on its own; the scripted replies answered them in
  one line.
- The second run's stop before drafting is not in the skill: it judged a
  window equal to the record's not worth finishing and asked first.
- In the first run the session ran a subset of the project's check
  commands (`pnpm lint`, not `pnpm test`) and recorded why.
- The same window classified twice gave `untested-rule` a cost of 55 and
  68, while the three rejected kinds kept their batch counts exactly.
