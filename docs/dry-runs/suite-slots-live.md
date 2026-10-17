# Suite slots — live checks on this Mac

Run on 2026-10-17 at about 19:30 +08, macOS (Darwin 25.6.0), Claude Code
2.1.301, from this checkout on `main` after the Task 5 commit (`ed6cc48`).
The plugin under test is this repository's `plugins/kenspc`, loaded with
`--plugin-dir`. Step 6 of `docs/plans/suite-slots.md`; Task 6 of
`docs/tasks/suite-slots-tasks.md`.

Paths below: `<repo>` is `/Users/kenspc/Projects/KENSPC/claude-plugin`;
`<dir>` is the throwaway directory
`/var/folders/28/hztldwfs1ls4stzfgvj2qm900000gn/T/suite-slots-live.QKvRzU`,
made with `mktemp -d "${TMPDIR%/}/suite-slots-live.XXXXXX"`.

## Check 1: the hook in a real headless session

### Green case: the commands variable set

Command (run from `<dir>`, in the foreground):

```
KENSPC_AUTOPILOT_WORKER=1 \
KENSPC_AUTOPILOT_WRITE_ROOTS="<dir>|$TMPDIR|/tmp|/private/tmp" \
KENSPC_AUTOPILOT_SUITE_COMMANDS=kenspc-probe-suite \
KENSPC_AUTOPILOT_SUITE_WRAPPER="<repo>/plugins/kenspc/skills/autopilot/scripts/suite-slots.sh" \
timeout 300 claude -p 'Run `kenspc-probe-suite --x` in Bash and quote the error you get, verbatim, in your reply. Do nothing else.' \
  --plugin-dir "<repo>/plugins/kenspc" --permission-mode bypassPermissions \
  --max-budget-usd 1 < /dev/null
```

Exit code: 0. Stderr: empty. Stdout, as printed:

````
`kenspc-probe-suite --x` never ran. A PreToolUse hook blocked the command before it started, so the probe suite itself produced no output. This is the error, verbatim:

```
PreToolUse:Bash hook error: [bash "/Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/hooks/scripts/autopilot-worker-rails.sh"]: autopilot rails: a listed suite command runs only through the suite-slot wrapper in an autopilot worker (kenspc-probe-suite, listed in KENSPC_AUTOPILOT_SUITE_COMMANDS). Permitted instead: run it through the suite-slot wrapper: bash /Users/kenspc/Projects/KENSPC/claude-plugin/plugins/kenspc/skills/autopilot/scripts/suite-slots.sh run -- <the command>; exit 75 with a "suite-slots: busy" line means run the same line again. This denial is not a breach.

This hook comes from the kenspc@inline plugin.
```

You asked me to do nothing else, so I did not run it through the wrapper the hook suggests.
````

Result: PASS. The quoted error opens `autopilot rails:` (after the
harness's `PreToolUse:Bash hook error: [...]:` prefix) and names the
wrapper's absolute path.

### Red case: the commands variable unset

The same command without `KENSPC_AUTOPILOT_SUITE_COMMANDS`:

```
KENSPC_AUTOPILOT_WORKER=1 \
KENSPC_AUTOPILOT_WRITE_ROOTS="<dir>|$TMPDIR|/tmp|/private/tmp" \
KENSPC_AUTOPILOT_SUITE_WRAPPER="<repo>/plugins/kenspc/skills/autopilot/scripts/suite-slots.sh" \
timeout 300 claude -p 'Run `kenspc-probe-suite --x` in Bash and quote the error you get, verbatim, in your reply. Do nothing else.' \
  --plugin-dir "<repo>/plugins/kenspc" --permission-mode bypassPermissions \
  --max-budget-usd 1 < /dev/null
```

Exit code: 0. Stderr: empty. Stdout, as printed:

````
The command failed with exit code 127. Here is the error, verbatim:

```
(eval):1: command not found: kenspc-probe-suite
```
````

Result: the red case shows `command not found`, so check (f) is what
denied the call in the green case.

## Check 2: three concurrent wrappers

Command:

```
export KENSPC_SUITE_SLOTS_DIR=<dir>/lock KENSPC_AUTOPILOT_SUITE_LOG=<dir>/suite.log
S=<repo>/plugins/kenspc/skills/autopilot/scripts/suite-slots.sh
bash "$S" run --limit 2 --wait 30 -- sleep 5 > <dir>/w1.out 2>&1 & p1=$!
bash "$S" run --limit 2 --wait 30 -- sleep 5 > <dir>/w2.out 2>&1 & p2=$!
bash "$S" run --limit 2 --wait 30 -- sleep 5 > <dir>/w3.out 2>&1 & p3=$!
wait $p1; r1=$?; wait $p2; r2=$?; wait $p3; r3=$?
```

Exit codes: 0, 0, 0. The three wrappers' own output files were empty, and
the lock directory held nothing afterwards (`ls -A` printed nothing). The
log:

```
2026-10-17T11:31:40Z acquired pid 35717 waited 0s holders 0 — sleep 5
2026-10-17T11:31:40Z acquired pid 35719 waited 0s holders 1 — sleep 5
2026-10-17T11:31:45Z released 0 pid 35717 waited 0s holders 2 — sleep 5
2026-10-17T11:31:45Z released 0 pid 35719 waited 0s holders 1 — sleep 5
2026-10-17T11:31:45Z acquired pid 35718 waited 5s holders 0 — sleep 5
2026-10-17T11:31:50Z released 0 pid 35718 waited 5s holders 1 — sleep 5
```

Result: PASS. Three `acquired` lines; the third (pid 35718) waited 5
seconds, at least the 4 the check asks for, and acquired only once both
earlier holders had released.

## Cleanup

`<dir>`, which holds the lock directory `<dir>/lock` and the log, was
removed with `rm -rf '<dir>'` after both checks; `ls -d '<dir>'` and
`ls -d '<dir>/lock'` then each printed `No such file or directory` and
exited 1.
