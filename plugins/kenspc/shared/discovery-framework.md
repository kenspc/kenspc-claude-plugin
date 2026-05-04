# Discovery Framework

Shared discovery logic referenced by `generate-plan` and `generate-brief`.

## Goal

Understand what the user truly needs before any generation begins. Discovery is conversation, not generation. Resist the urge to draft, outline, or template.

## Step 1: Assess Input Clarity

On first receiving input, classify it. The calling skill's `effort:` setting
controls how deeply this assessment runs.

- **Level 1 — Clear.** Structured requirement or PRD; most dimensions answered. → Gap-check only, 1-2 rounds.
- **Level 2 — Mostly clear.** User knows direction, has gaps. → 3-5 rounds to fill key dimensions.
- **Level 3 — Vague.** User unsure of direction. → No round limit. Explore all dimensions.
- **Level 4 — Too broad.** Spans multiple independent systems. → Stop. Suggest decomposition. A single plan/brief covering everything would be too coarse to be useful.

## Step 2: The Five Dimensions (Claude's internal checklist)

Not a questionnaire. Use these to decide what to ask, in what order.

| Dimension | What / When | How to ask |
|---|---|---|
| **Outcome** | The user's true goal, not the task description. ("notification system" = task; "users don't miss assignments" = outcome.) Always check. | Push one level up: "如果这功能成功了，用户/团队会有什么不同？" |
| **Failure Modes** | What result would make the user say "no, that's wrong" even if technically working. Always check. Users rarely volunteer this. Becomes scope boundaries and risks downstream. | "如果交付出来你不满意，最可能是因为什么？" |
| **The Hard Part** | Which part requires the most judgment. Always check. | If user can't articulate, propose 2-3 candidates with trade-offs and recommend one. Lead with a recommendation when the user lacks technical depth — don't just ask. |
| **Hidden Context** | Organizational norms, political factors, historical decisions, team preferences an outsider wouldn't know. Check when project files don't explain constraints; skip if covered. | "团队里之前有没有讨论过类似的方向？为什么没做？" |
| **Stakes** | How important. Determines downstream output granularity. Infer from conversation; don't ask directly. Only ask when signals conflict (e.g., "quick internal tool" + "10K concurrent users"). | — |

## Step 3: Conversation Rules

- **One question at a time.** Wait for the answer before deciding what to ask next.
- **Build on what the user said.** Reference their words; show you were listening.
- **When the user is uncertain, recommend.** Offer 2-3 options with brief pros/cons and pick one. Don't lay options out and walk away.
- **Match the user's language.** Chinese → Chinese, English → English, mixed → follow the dominant.
- **No round limit.** Depth adapts to clarity level.
- **Do not produce output during Discovery.** No drafts, outlines, or templates. Resist jumping ahead — Discovery's job is to surface intent, not to start the deliverable.

## Step 4: Exit Conditions

Exit Discovery when **either** holds:

1. User explicitly signals readiness: "OK", "够了", "let's go", "可以了", "write it", "go ahead".
2. Claude judges that **Outcome, Failure Modes, and The Hard Part are sufficiently clear** AND no remaining dimension has an obvious gap. Suggest moving forward: "我觉得方向够清楚了，可以开始了。你觉得还有什么需要讨论的？" — but the user can always continue.

For **Level 4**: exit Discovery early. Suggest decomposition. Offer to help identify natural module boundaries, then ask which module to start with.

## What This File Does NOT Define

- Output format — defined by the calling skill.
- Next steps after Discovery — defined by the calling skill.
- Project scanning steps — defined by the calling skill.
