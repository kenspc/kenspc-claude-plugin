# Batch M — walk probe: browser tools in a headless worker

Task 1 of `docs/tasks/batch-m-autopilot-field-lessons-2-tasks.md` (plan
Step 1, `docs/plans/batch-m-autopilot-field-lessons-2.md`). Run on
16 Oct 2026 on the maintainer's Mac, Claude Code 2.1.300, by the main
session, after the user confirmed Chrome was open with the Claude in
Chrome extension connected.

## Setup

- Workspace: `~/Projects/_smoke/batch-m-probe/` (not a git repository).
  Seed: `seed/index.html`, an `h1` "Batch M walk probe" and
  `<p id="marker">probe-page-ok</p>`, served by
  `python3 -m http.server 8799 --bind 127.0.0.1` from `seed/` (started by
  the probe, stopped by its listener pid afterwards; the port was free
  before and after).
- Launches went through copies of `plugins/kenspc/skills/autopilot/scripts/run.sh`
  under `drivers/`, so each ran as a worker runs: `-p`,
  `--permission-mode bypassPermissions`, `--output-format json`, the
  marker `KENSPC_AUTOPILOT_WORKER=1`, and the roots with
  `AUTOPILOT_WORKSPACE` set to the workspace. `run.sh` passes no
  caller-supplied flag, so two further copies each added flags to their
  `args=(…)` line: `run-chrome.sh` adds `--chrome`; `run-nomcp.sh` adds
  `--strict-mcp-config --mcp-config <workspace>/empty-mcp.json` (a file
  holding `{"mcpServers": {}}`). The shipped `run.sh` and `run.ps1` were
  not edited.
- Each launch had `AUTOPILOT_BUDGET_USD` set (1.2, or 0.8 for the last),
  no model or effort set (the worker's own settings).
- Prompts: `prompts/playwright.md`, `prompts/chrome.md`,
  `prompts/chrome-2.md` in the workspace. Logs: `_logs/batchm-probe-*`.
- The user's Chrome was not quit, restarted, signed out of, or
  reconfigured; no launch opened a tab of its own, since none reached a
  browser (below).

## Results

### Playwright MCP

1. **Present, with no extra flag.** `batchm-probe-pw` (`drivers/run.sh`):
   `PLAYWRIGHT TOOLS: 25` (e.g. `mcp__playwright__browser_navigate`,
   `mcp__playwright__browser_take_screenshot`,
   `mcp__playwright__browser_close`). The server comes from the user's
   MCP configuration (`claude mcp list`: `playwright: … @playwright/mcp/cli.js
   --isolated --output-dir /Users/kenspc/Library/Caches/ms-playwright/mcp-output
   - ✔ Connected`).
2. **Navigation and screenshot.** `HEADING: Batch M walk probe`,
   `MARKER: probe-page-ok`. The screenshot tool refused a path in the
   workspace — `Error: File access denied: …/batch-m-probe/shots/playwright.png
   is outside allowed roots. Allowed roots:
   /Users/kenspc/Library/Caches/ms-playwright/mcp-output,
   /Users/kenspc/Projects/_smoke/batch-m-probe/seed` — so the worker let
   it write to the MCP's output directory and copied the file with `cp`:
   `shots/playwright.png`, 19555 bytes. The allowed roots are the MCP's
   output directory and the session's working directory, so a walk
   worker writes screenshots there and copies them into the workspace.
3. **Check command, both answers.** Run by the main session before any
   launch:

   ```bash
   claude mcp list 2>&1 | grep -E '^playwright: .* - ✔ Connected$'
   ```

   - usable (the user's configuration): the line above printed, exit 0;
   - not usable (`CLAUDE_CONFIG_DIR` pointed at an empty directory, so
     no MCP server is configured): `No MCP servers configured. Use
     \`claude mcp add\` to add a server.`, no line matched, exit 1.

   The worker-side negative: `batchm-probe-pwneg` (`drivers/run-nomcp.sh`,
   the server left out of the worker's MCP configuration) reported
   `PLAYWRIGHT TOOLS: none` and wrote nothing.
4. **Cost.** `batchm-probe-pw` USD 0.2938; `batchm-probe-pwneg`
   USD 0.0871.

### Claude in Chrome

1. **Tools present with `--chrome`, no browser reachable.**
   `batchm-probe-ch` (`drivers/run-chrome.sh`): `CHROME TOOLS: 22`
   (`browser_batch`, `computer`, `navigate`, `tabs_context_mcp`,
   `tabs_create_mcp`, `tabs_close_mcp`, `list_connected_browsers`,
   `get_page_text`, …); `list_connected_browsers` returned `[]`.
   `batchm-probe-ch2`, which called the tab-context tool whatever the list
   said: `list_connected_browsers` → `[]`; `tabs_context_mcp`
   (`createIfEmpty: true`) → "Browser extension is not connected. Please
   ensure the Claude browser extension is installed and running
   (https://claude.ai/chrome), and that you are logged into claude.ai with
   the same account as Claude Code. …"; `select_browser` was not called,
   since no device id was listed.
2. **Navigation and screenshot.** None: no tab could be opened.
3. **Check command.** None found that answers "usable" from a headless
   worker. At the same time the main session (the Claude desktop app's
   Code tab) saw the browser connected: its own `list_connected_browsers`
   returned one browser (`Browser 1`, macOS, `isLocal: true`,
   `inUse: true`). `claude auth status` showed the command-line `claude`
   signed in to claude.ai with the same account the desktop app uses.
4. **Cost.** `batchm-probe-ch` USD 0.3971; `batchm-probe-ch2`
   USD 0.3841.

## Conclusion

- A headless `claude -p` worker can use the Playwright MCP from the
  user's configuration with no extra flag, so no driver flag is needed
  (Task 14).
- A headless `claude -p --chrome` worker could not use Claude in Chrome on
  this machine and Claude Code version, while the desktop session could.
  Observed: the two results above, at the same time, under one account.
  Not determined: the cause. Readings that fit: the extension serves the
  session that holds it (`inUse: true` on the desktop session's side) and
  not a second one; or a headless session cannot reach the extension at
  all. Telling them apart would mean releasing the desktop session's
  connection, which this probe did not do.
- As plan Step 1 states for this case, Tasks 12 and 13 write the walk's
  tool order as the Playwright MCP alone, its start check being the
  command in item 3 above. Claude in Chrome stays out of the walk until a
  later probe shows a headless worker reaching it.
- No identifier of the Claude in Chrome server is needed in the skill, so
  the model-name guard's question (the task review's plan-level concern)
  does not arise.

## Cost

Four launches, USD 1.1622 in all (cap USD 5): `batchm-probe-pw` 0.2938,
`batchm-probe-ch` 0.3971, `batchm-probe-ch2` 0.3841,
`batchm-probe-pwneg` 0.0871.
