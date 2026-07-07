# Release Checklist

Manual verification steps that run before tagging any release. The
pre-flight checks below verify content; the smoke checklist verifies that
the plugin actually loads and that each entry-point reaches its first
interactive surface.

## Pre-flight: mechanical checks

Run from the repository root:

```bash
# Frontmatter completeness — every SKILL.md and agent .md declares effort
for f in plugins/kenspc/skills/*/SKILL.md plugins/kenspc/agents/*.md; do
  grep -q '^effort:' "$f" || echo "MISSING effort: $f"
done

# JSON sanity (all three)
cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null
cat plugins/kenspc/hooks/hooks.json | python -m json.tool > /dev/null
cat .claude-plugin/marketplace.json | python -m json.tool > /dev/null

# All drift/structure guards in main mode (runs every scripts/check-*.sh)
bash scripts/check-all.sh

# Mutation regression fixtures (self-test on the five self-test-capable guards)
bash scripts/check-code-craft-canonical.sh --self-test
bash scripts/check-canonical-dispatch.sh --self-test
bash scripts/check-verdict-shared.sh --self-test
bash scripts/check-quality-reviewer-bullet-structure.sh --self-test
bash scripts/check-notes-format-sync.sh --self-test
```

All nine must exit 0 (3 JSON validations + `check-all.sh` covering every
drift/structure guard in main mode + 5 mutation regression self-tests).
If any fail, fix before proceeding to the smoke checklist.

## Docs currency (manual)

CLAUDE.md (§ Subagent Review Architecture) pins the effort ladder to
Anthropic's published guidance and carries a "wording last reviewed"
date. Confirm the guidance still matches the current frontier Claude
generation and update that date before tagging.

## Smoke checklist (manual, ~10 minutes)

The plugin can pass every grep-based AC and still fail to load if a YAML
frontmatter break or file path typo slipped through. This checklist
exercises the actual load + first-prompt surface of every user-facing
entry point.

In a throwaway directory or a freshly cloned worktree:

```bash
claude --plugin-dir ./plugins/kenspc
```

Inside the session:

| # | Check | Pass criterion |
|---|---|---|
| 1 | `/help` | Lists all 6 kenspc slash commands without error |
| 2 | `/reload-plugins` | Reload completes; no YAML/JSON parse errors in console |
| 3 | `/kenspc-brief` | Discovery starts; first user-facing prompt is a question (not a draft) |
| 4 | `/kenspc-plan` | Phase 1 begins; Phase 3 dispatch table appears before plan-document-reviewer runs |
| 5 | `/kenspc-task <plan-path>` | Decomposition runs; task-document-reviewer dispatch table appears |
| 6 | `/kenspc-task-implement <task-path>` | Phase 2 review dispatches even when implementation is all-DONE; Schema A → B → C → G report appears |
| 7 | `/kenspc-task-review` | 5-row dispatch table appears; Schema F final report; never logs "Code looks correct, skipping review" |
| 8 | `/kenspc-guide <project-path>` | Guide runs; guide-document-reviewer dispatch table appears |
| 9 | End-to-end trace verification on greenfield project (non-DungeonDescent) | All three sub-criteria hold (see row-9 detail below) |

Row 9 sub-criteria (each is independently mechanically auditable against
the captured trace):

- Phase 2 auto-triggers without a user prompt: grep the trace for
  `Proceeding to Phase 2` or `Proceeding to code review` and confirm it
  appears immediately after Phase 1 Step 5 (not after a user reply).
- No closure-wording disablelist words appear in the trace before Phase 2
  dispatch. Grep the trace for each of: `整段落地`, `session 结束`,
  `workflow 收口` (Chinese subset), and `Workflow complete.`,
  `All phases done.`, `milestone landed` (English subset drawn from the
  `task-implement` Closure Wording Boundary disablelist). Each must
  return zero hits in the pre-Phase-2 trace window.
- `Discovery Mode:` field present in the brief output, with a value in
  {`full`, `rapid-direct`, `rapid-inferred (reminder-driven)`}.

If any step fails, do not tag the release. File the failure as a bug,
fix, re-run the pre-flight + this checklist.

## Post-release

```bash
git tag -a v<version> -m "kenspc v<version>"
git push origin main --tags
```

## Rationale

This checklist exists because mechanical pre-flight checks can pass while
the plugin fails to load — for example, a missing colon in YAML
frontmatter parses cleanly as text but breaks Claude Code's plugin
loader. The smoke checklist is the cheapest gap-closer: it exercises the
actual load + first-prompt surface that no grep can verify.
