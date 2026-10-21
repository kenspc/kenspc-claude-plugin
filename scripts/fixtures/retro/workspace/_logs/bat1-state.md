Autopilot settings — batch bat1, mode repo
main session: bat1-main   repository: /fixture/repo   baseline: 0000000   spec: docs/plans/bat1.md
sessions:
  bat1-s3  11111111-0000-0000-0000-000000000003  USD 1.00  success
questions answered:
  bat1-s3: batch gate (3 tasks) → yes (main session)
  bat1-s3 (review, 2 findings): FIX T1 → FIX (main session)
rail observations:
  bat1-s3: hook denied a relative redirect; rerun with an absolute path
  bat1-s3b: none
worker lessons:
  bat1-s3: give acceptance commands an existing $TMPDIR
skipped gates:
  S3 bat1-s3: recorded
stops:
merge danger: 1 one-way, 0 unclear, 2 two-way — /fixture/_logs/bat1-merge-danger.md
next: done
