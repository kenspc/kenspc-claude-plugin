# Dry-run reports

Manual dry-run transcripts for reviewer-agent behavior live here. A dry-run
report is a per-hunk evaluation of how each reviewer-agent bullet *would*
decide, without actually modifying files. These are repo-internal QA
artifacts, not plugin behavior — the convention below governs how future
reports are written, and deliberately does not ship inside any SKILL.md.

## Label vocabulary convention

Reports use two non-overlapping label vocabularies so a reader scanning the
report cannot misread polarity:

| Decision level | Labels | Meaning |
|----------------|--------|---------|
| Per-condition  | `CONDITION-MET` / `CONDITION-NOT-MET` | `CONDITION-MET` = the bullet's qualifier is true (the condition fires; the bullet remains a candidate to flag the hunk). |
| Per-hunk final | `FLAG` / `PASS` | `FLAG` = the bullet reports the hunk. `PASS` = the bullet does **not** report the hunk (code is fine for this bullet's angle). |

The two vocabularies cannot collide because `MET` / `NOT-MET` only appears
at per-condition level and `FLAG` / `PASS` only at per-hunk level.

Reason: the v3.1.0 dry-run report at
`v3.1.0-quality-reviewer-bullets-dry-run.md` used the single word `PASS`
for both polarities (`Condition 1 PASSES` meaning "condition fires" and
`Decision: PASS` meaning "code is fine"), which is easy to misread in the
same paragraph. That report is preserved as a historical artifact; future
reports use the labels above.
