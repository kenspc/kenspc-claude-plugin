@AGENTS.md

## Claude Code sessions

Test the plugin locally with `claude --plugin-dir ./plugins/kenspc`, and use
`/reload-plugins` inside a session to pick up changes without restarting.

Edit the plugin's agent and skill files in a session started without
`--plugin-dir`, and keep `--plugin-dir` sessions for acceptance and smoke
runs. Why: a `--plugin-dir` session treats those files as the definitions it
is running, and auto mode's classifier there blocks edits to them. Under
`--permission-mode bypassPermissions` there is no classifier, so the
autopilot's headless workers, `--plugin-dir` in plugin mode included, edit
the plugin's files as they edit any other.
<!-- Roadmap 9 batch, 2026-09-24: in a --plugin-dir session the classifier gave
no verdict on every Edit to plugins/kenspc/agents/*.md and
plugins/kenspc/skills/*/SKILL.md, and judged rewriting them through Bash a
workaround, while documentation files were edited normally; the same edits
went through in a session without --plugin-dir. -->
