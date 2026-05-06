# Release Checklist

Manual verification steps that run before tagging any release. The
mechanical AC1–AC11 in [docs/plans/v3-bitter-lesson-refactor.md](plans/v3-bitter-lesson-refactor.md)
verify content; this checklist verifies that the plugin actually loads and
that each entry-point reaches its first interactive surface.

## Pre-flight: mechanical checks

Run from the repository root:

```bash
# AC1 — frontmatter completeness
for f in plugins/kenspc/skills/*/SKILL.md plugins/kenspc/agents/*.md; do
  grep -q '^effort:' "$f" || echo "MISSING effort: $f"
done

# AC11 — JSON sanity (all three)
cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null
cat plugins/kenspc/hooks/hooks.json | python -m json.tool > /dev/null
cat .claude-plugin/marketplace.json | python -m json.tool > /dev/null

# AC7 — canonical dispatch byte-identity
bash scripts/check-canonical-dispatch.sh

# AC9 — review-angle agents shared-section invariance
bash scripts/check-review-agent-drift.sh
```

All four must exit 0. If any fail, fix before proceeding to the smoke
checklist.

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
| 3 | `/kenspc-brief` | Discovery starts; first user-facing prompt is English-only |
| 4 | `/kenspc-plan` | Phase 1 begins; Phase 3 dispatch table appears before plan-document-reviewer runs |
| 5 | `/kenspc-task <plan-path>` | Decomposition runs; task-document-reviewer dispatch table appears |
| 6 | `/kenspc-task-implement <task-path>` | Phase 2 review dispatches even when implementation is all-DONE; Schema A → B → C → G report appears |
| 7 | `/kenspc-task-review` | 5-row dispatch table appears; Schema F final report; never logs "Code looks correct, skipping review" |
| 8 | `/kenspc-guide <project-path>` | Guide runs; guide-document-reviewer dispatch table appears |

If any step fails, do not tag the release. File the failure as a bug,
fix, re-run the pre-flight + this checklist.

## Post-release

```bash
git tag -a v<version> -m "kenspc v<version>"
git push origin main --tags
```

## Rationale

This checklist exists because v3 review uncovered that all 11 mechanical
ACs can pass while the plugin fails to load — for example, a missing
colon in YAML frontmatter parses cleanly as text but breaks Claude Code's
plugin loader. The smoke checklist is the cheapest gap-closer: it
exercises the actual load + first-prompt surface that no grep can verify.
