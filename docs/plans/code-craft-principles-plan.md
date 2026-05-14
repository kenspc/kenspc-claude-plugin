# Plan: Integrate Karpathy Simplicity + Surgical Principles into `shared/code-craft-principles.md`

## Objective

Add a single new shared resource — `plugins/kenspc/shared/code-craft-principles.md` —
that defines two code-craft principles (Simplicity First, Surgical Changes) with
worked examples in C# and TypeScript. Relocate the matching constraints currently
scattered across `task-implementer`, `code-fixer`, and `quality-reviewer` agents into
this single source of truth. Update README to clarify what "Stack-agnostic" means
after introducing stack-specific examples. Update CHANGELOG.

**In scope:**

- New file: `plugins/kenspc/shared/code-craft-principles.md`.
- Edits to three agents: `task-implementer.md`, `code-fixer.md`, `quality-reviewer.md`.
- Edits to two docs: `plugins/kenspc/README.md`, and the repo-root `CLAUDE.md`
  (the only CLAUDE.md in the tree — it enumerates `shared/` contents in the
  Plugin Directory Layout block and in the Shared resources paragraph).
- New CHANGELOG entry (v3.1.0) and `plugin.json` version bump.

**Out of scope:**

- Karpathy Principle 1 ("Think Before Coding") for ad-hoc non-workflow interactions —
  intentionally NOT added to the plugin per design decision C4 (the plugin has no
  reliable mechanism to enforce always-on behavior; this belongs in user-level or
  project-level `CLAUDE.md`, not in kenspc).
- Karpathy Principle 4 ("Goal-Driven Execution") — already covered by kenspc's
  DONE-criteria pattern across all skills.
- Any change to `generate-brief`, `generate-plan`, `generate-task`, `generate-guide`,
  `task-implement`, `task-review` SKILL.md files — the change is agent-internal.
- New skills, new commands, new hooks, new effort levels.

## Background

A research conversation analyzed `doggy8088/andrej-karpathy-skills` (a 65-line
`AGENTS.md` + 522-line `EXAMPLES.md` distilling Karpathy's four LLM-coding pitfalls
into four principles). Two of those four principles fill a real gap in kenspc:

- **Simplicity First** — minimum code that solves the problem; no speculative
  abstractions, no unrequested flexibility, no error handling for impossible
  scenarios. kenspc currently has NO Simplicity guidance anywhere; `task-implementer`
  has only a generic "Follow established project conventions" and a QUALITY CHECKLIST
  oriented at correctness, not minimalism.
- **Surgical Changes** — touch only what the task requires; do not "improve" adjacent
  code, do not refactor what is not broken, match existing style. kenspc covers this
  partially and inconsistently — `task-implementer` has it in three places
  (QUALITY RULES, AUTONOMY BOUNDARIES "Do not do even if it seems helpful",
  STOP-and-BLOCKED triggers), and `code-fixer` has it under FIXING RULES. There is
  no single source of truth, so future drift is likely.

Karpathy's other two principles are not adopted here: **Think Before Coding** belongs
at the project / user `CLAUDE.md` layer, not in a plugin (a plugin has no reliable
always-on mechanism, and adding one would violate kenspc's own "Avoid triggering this
skill when..." design rule). **Goal-Driven Execution** is already covered by kenspc's
DONE-criteria pattern across all skills.

The locked design decisions from the design conversation:

| # | Decision | Choice |
|---|----------|--------|
| 1 | Merge Items 4 + 5 (principles + examples) into one shared file | Yes |
| 2 | Sub-choice A: examples stack | A2 — C# + TypeScript |
| 3 | Sub-choice B: relate to existing agent constraints | B2 — relocate to shared, agents reference |
| 4 | Item 3 (Think Before Coding for ad-hoc interactions) | C4 — NOT in the plugin |
| 5 | Update README's "Stack-agnostic" wording | Yes |

This is a minor feature addition (no breaking changes, no CONTEXT block schema
changes, no SKILL or agent interface changes for callers).

## Technical Approach

### Architecture

```
plugins/kenspc/shared/
├── discovery-framework.md          (existing — referenced by 2 SKILLs)
└── code-craft-principles.md        (NEW — referenced by 3 AGENTS)
```

The pattern mirrors `discovery-framework.md`:

- Single markdown file under `shared/`.
- Referenced by consumers via the portable path
  `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`.
- File starts with a one-paragraph Goal, lists principles with worked diff examples,
  ends with a per-consumer applicability table and a "What This File Does NOT Define"
  section.

### Consumer wiring

| Consumer | Current state | After this plan |
|----------|--------------|------------------|
| `agents/task-implementer.md` | Scope-creep guards in 3 places (QUALITY RULES, AUTONOMY BOUNDARIES, STOP triggers). No Simplicity guard. | Relocated guards → single reference line + adds Simplicity by reference. |
| `agents/code-fixer.md` | Surgical guidance under FIXING RULES ("Do not introduce new features or refactor code beyond what the issue requires", "Preserve the original code's style and structure"). | Replaced with single reference line. |
| `agents/quality-reviewer.md` | REVIEW CHECKLIST has "Code complexity" (asks to break down complex functions). No over-engineering check (the opposite direction — flagging code that goes beyond what was asked). | Adds an over-engineering check that defers to the shared file's Simplicity definition. |

### Examples in shared file

Per A2: examples are concrete C# and TypeScript code in `❌ ... / ✅ ...` diff pairs,
not language-agnostic pseudocode. The file claims neither Python nor any other
unrepresented stack as a constraint — it picks two stacks that maximize teaching
density for the maintainer (Sim's primary stacks: C# / TypeScript) without claiming
universality.

The README "Stack-agnostic" line is updated to clarify:

- "Stack-agnostic" applies to SKILL behavior (skills inspect project config files
  rather than assuming specific frameworks).
- It does NOT apply to documentation examples, which use specific languages where
  doing so improves teaching density.

### Why-not-Command framing

Each principle in the new shared file states the rule as rationale, not imperative.
Example phrasing (illustrative, not the final wording):

> **Simplicity First.** Write the minimum code that solves the stated problem. Why:
> speculative abstractions ("we might need this later") accumulate as dead weight
> when the speculation does not pay out, and they make the actual code path harder
> to follow. Refactor toward abstraction when the second or third concrete use case
> arrives, not the first.

This matches the v3 design rule "Why-not-Command business rules — business rules are
framed as rationale, not as command-style imperatives".

## Implementation Steps

### Commit Strategy

One commit per Step (1.1, 1.2, ..., 4.3) with a conventional-commit subject
that names the file(s) touched. Phase 4 validation steps either produce no
commit (the checks pass) or, if a defect is found, an additional fix commit
in the same Step. The CHANGELOG entry (Step 3.3) is committed together with
the `plugin.json` version bump so the v3.1.0 commit pair is atomic.

### Phase 1: Author `shared/code-craft-principles.md`

**Step 1.1: Create the file with section skeleton**

What to do:

- Create `plugins/kenspc/shared/code-craft-principles.md`.
- Add top-level structure: `# Code-Craft Principles`, one-paragraph Goal, two
  Principle sections, "How Each Agent Applies These" table, "What This File Does
  NOT Define" section.

Why: A skeleton-first pass anchors the structure before content fills in, mirroring
how `discovery-framework.md` is organized. Establishes the section contract early so
agents that link to specific anchors (`#simplicity-first`, `#surgical-changes`) have
stable targets.

Input: None (new file).

Output: A ~30-line skeleton file with section headers and TODO placeholders for
principles, examples, and tables.

Done when: File exists at the correct path; all five sections are present as headers
with `TODO` placeholders; file is committed.

**Step 1.2: Write the Simplicity First principle and its two examples**

What to do:

- Replace the Simplicity First section's TODO with: one-paragraph principle statement
  in rationale form (Why-not-Command); a checklist of 4–6 bullets that translate the
  principle to concrete decisions ("don't add error handling for impossible
  scenarios", "don't add 'flexibility' or 'configurability' that was not requested",
  "if you wrote 200 lines and 50 lines would do, rewrite"); and two `❌ / ✅` diff
  examples — one in C#, one in TypeScript — each ≤ 25 lines per side, demonstrating
  over-abstraction (the C# one) and a speculative-feature trap (the TypeScript one).

Why: One paragraph of principle without examples reads as a slogan. One example
without a contrasting `❌` reads as just another piece of code. The paired diff
format from Karpathy's `EXAMPLES.md` is what gives the principle teaching density —
and Karpathy's all-Python examples are exactly why a stack-specific rewrite is needed
(the C# overuse of `IService` / `AbstractFactory` patterns is a different teaching
target than Python's ABC overuse).

Input: The principle statement direction is locked; example concepts are author's
choice but each should pick a real-world kenspc-plausible scenario (e.g., a service
that needs one method, written with strategy pattern; an endpoint with `option1`,
`option2`, `option3` flags that were never requested).

Output: A ~50-line Simplicity First section.

Done when: Principle paragraph exists in rationale form (the word "Why" appears in or
near the statement); checklist has 4–6 bullets; two diff examples present (one C#,
one TypeScript), each ≤ 25 lines per side; no example uses Python, Java, or any
language not in scope; file commits cleanly.

**Step 1.3: Write the Surgical Changes principle and its two examples**

What to do:

- Replace the Surgical Changes section's TODO with: one-paragraph principle statement
  in rationale form; checklist of 4–6 bullets ("don't 'improve' adjacent code,
  comments, or formatting", "don't refactor things that are not broken", "match
  existing style even when you'd write it differently", "remove imports/variables
  your changes orphaned, but don't remove pre-existing dead code"); two `❌ / ✅`
  diff examples — one in C#, one in TypeScript — showing drive-by refactoring and
  style drift respectively.

Why: Surgical Changes is the principle kenspc currently mentions in the most places
but defines least consistently — examples are the way to lock down what "surgical"
actually looks like in diff terms. The two example types (drive-by refactor / style
drift) are the two failure modes Karpathy's `EXAMPLES.md` calls out, and they map
directly to the two ways `task-implementer` currently bleeds scope.

Input: Same as 1.2 — author's choice of scenario, but plausible for kenspc users.

Output: A ~50-line Surgical Changes section.

Done when: Same shape as 1.2 (rationale-form paragraph, 4–6 checklist bullets, two
diff examples meeting language and length constraints).

**Step 1.4: Write the "How Each Agent Applies These" table**

What to do:

- Add a section that maps each of the three consumer agents to which principle(s)
  apply and how:

  | Agent | Role | Simplicity | Surgical |
  |-------|------|-----------|----------|
  | `task-implementer` | Author at write time | Apply: don't expand task scope into speculative features | Apply: don't modify code unrelated to the current task |
  | `code-fixer` | Author at fix time | Apply: apply only the fix the review reported; defer structural improvements | Apply: preserve original style; don't refactor adjacent code |
  | `quality-reviewer` | Reviewer | Detect: flag features beyond task requirement; flag abstractions for single-use code | Detect: flag drive-by refactoring; flag style drift in diffs |

Why: Without this table, three agents reading the same shared file might each apply
the principles slightly differently (e.g., `code-fixer` reading "minimum code" might
think it should refuse to fix a non-minimal issue; `quality-reviewer` reading
"surgical" might flag every multi-file PR as a violation). The table disambiguates by
making the author-vs-reviewer distinction explicit — same principle, different
operational stance.

Input: The three consumers and their existing roles (already documented in their
agent files).

Output: A ~15-line table section.

Done when: Table is present with all three agents and both principles; each cell
contains a concrete one-line operational statement, not generic re-statement of the
principle.

**Step 1.5: Write the "What This File Does NOT Define" section**

What to do:

- Add a closing section listing what this file deliberately omits:
  - Goal-Driven Execution (covered by DONE-criteria in every SKILL).
  - Think Before Coding for ad-hoc interactions (out of scope — belongs in user-level
    or project-level CLAUDE.md).
  - Per-language style guides (delegated to project CLAUDE.md and existing project
    conventions, which agents read in their PREREQUISITES step).
  - Agent dispatch order and CONTEXT block contracts (defined in the dispatching
    SKILL.md and each agent's header).

Why: This mirrors `discovery-framework.md`'s "What This File Does NOT Define"
closing — it prevents readers (humans and agents) from assuming this file is broader
than it is. Particularly important here because Karpathy has 4 principles and only 2
are being adopted; future readers seeing 2 principles might wonder where the other 2
went.

Input: The decisions locked in Background.

Output: A ~10-line section.

Done when: Section exists; the four omissions above are listed with one-line
rationale each.

### Phase 2: Wire up consumer agents

**Step 2.1: Update `agents/task-implementer.md` (relocate scope-creep guards + add Simplicity)**

What to do:

- In the `QUALITY RULES` section, remove the bullet "Do not modify code unrelated to
  the current task" — this is now defined in the shared file.
- In the `AUTONOMY BOUNDARIES` "Do not do even if it seems helpful" subsection, keep
  the BLOCKED-trigger items intact (these are workflow-specific, not principle-level)
  but remove the generic "Refactor code unrelated to the current task" bullet.
- Add a new section immediately AFTER the `QUALITY RULES` section and BEFORE
  the `AUTONOMY BOUNDARIES` section, titled `CODE-CRAFT PRINCIPLES`, with body:

  > Read `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` before implementing
  > each task. Apply Simplicity First and Surgical Changes as defined there. The
  > applicability table in that file states this agent's stance: author at write
  > time.

- Keep `STOP and mark task as BLOCKED` triggers untouched (these are not
  principle-level — they are workflow-specific decision boundaries about when to
  halt versus push back).
- Keep the `QUALITY CHECKLIST` untouched (these are correctness checks: edge cases,
  error handling, async correctness, resource cleanup, magic numbers, tests,
  security — they are orthogonal to Simplicity and Surgical and remain agent-local).

Why: Relocating the scope-creep guards eliminates the three-place duplication
currently in this agent. Adding the Simplicity reference fills the gap that prompted
this whole change (the agent had no minimum-code guidance). Keeping
`STOP-and-BLOCKED` and `QUALITY CHECKLIST` local respects the principle that
workflow-specific decision logic and correctness checklists are NOT code-craft
principles and should not be confused with them.

Input: Current `agents/task-implementer.md`.

Output: Modified `agents/task-implementer.md` with:

- 2 bullets removed (from `QUALITY RULES` and `AUTONOMY BOUNDARIES`).
- 1 new `CODE-CRAFT PRINCIPLES` section added (~4 lines).
- All other sections (`PREREQUISITE CHECK`, `OBJECTIVE`, `DONE CRITERIA`,
  `PROCESSING APPROACH`, `STUCK HANDLING`, `CODE ARTIFACTS LANGUAGE`, `OUTPUT
  FORMAT`) untouched.

Done when: A diff shows ≤ 4 lines removed and ~4 lines added; the agent file still
parses as valid frontmatter + markdown; `task-implementer` still has all its
prerequisite checks, autonomy boundaries (BLOCKED triggers), and Schema D output
contract.

**Step 2.2: Update `agents/code-fixer.md` (replace surgical bullets with reference)**

What to do:

- In the `FIXING RULES` section, remove:
  - "Do not introduce new features or refactor code beyond what the issue requires."
  - "Preserve the original code's style and structure."
- Replace with a single bullet:
  - "Apply Simplicity First and Surgical Changes per
    `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`. The applicability
    table states this agent's stance: author at fix time."
- Keep all other `FIXING RULES` bullets ("Follow established project conventions and
  patterns", "Each fix is a separate, focused git commit with a clear message",
  "Code, code comments, and commit messages stay in English") untouched.
- Keep `FIXING PRIORITY`, `PER-ISSUE OUTPUT CONTRACT`, and `OUTPUT FORMAT (Schema B)`
  fully untouched.

Why: `code-fixer` already has the strongest Surgical wording in the plugin; this
relocation is a SSoT consolidation rather than a behavior change. The
author-at-fix-time stance in the applicability table preserves the existing intent
(fixes are narrow, structural changes get DEFERRED, not applied).

Input: Current `agents/code-fixer.md`.

Output: Modified `agents/code-fixer.md` with 2 bullets removed and 1 reference bullet
added in `FIXING RULES`.

Done when: A diff shows 2 lines removed and 1 line added in `FIXING RULES`; nothing
else changes; `FIXING PRIORITY` decision matrix (HIGH/MEDIUM/LOW action rules) is
intact; Schema B output contract (with the `short_label` ≤ 60 chars requirement) is
intact.

**Step 2.3: Update `agents/quality-reviewer.md` (add over-engineering review angle)**

What to do:

- In the `REVIEW CHECKLIST` section, KEEP the existing "Code complexity: are there
  overly complex functions that should be broken down?" bullet untouched (this is a
  legitimate readability check that catches a different failure mode).
- ADD a new bullet immediately after it:
  - "Over-engineering: features beyond the task requirement; abstractions for
    single-use code; unrequested 'flexibility' or configurability. Apply
    Simplicity First per `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` —
    the applicability table states this agent's stance: detect, do not fix."
- ADD a second new bullet:
  - "Drive-by refactoring and style drift in the diff: changes unrelated to the
    task requirement. Apply Surgical Changes per the same file."
- Keep all other checklist items (Naming, Project structure, DRY, SOLID, Magic
  numbers) untouched.

Why: `quality-reviewer` currently has a complexity check pointing in the OPPOSITE
direction (break down complex functions) — useful, but it doesn't catch the
over-engineering failure mode that Karpathy's Simplicity principle targets. Adding
two new detection bullets fills this gap without removing existing coverage. The
"detect, do not fix" stance is critical: review agents in kenspc are read-only;
`code-fixer` is the only agent that modifies code.

Input: Current `agents/quality-reviewer.md`.

Output: Modified `agents/quality-reviewer.md` with 2 new bullets added to
`REVIEW CHECKLIST`. The other 4 reviewer agents (requirements, edge-case, bug, test)
are NOT modified.

Done when: A diff shows 2 lines added in `REVIEW CHECKLIST`; the Schema A output
contract is unchanged; `quality-reviewer`'s `effort: xhigh` stays; no other reviewer
agent files are touched.

### Phase 3: Update documentation and metadata

**Step 3.1: Update the repo-root `CLAUDE.md` (enumerate the new shared file)**

Note on file location: the only `CLAUDE.md` in the tree is at the repository
root (`./CLAUDE.md`). There is no `plugins/kenspc/CLAUDE.md`. The Plugin
Directory Layout block and the Shared-resources paragraph that this step edits
both live in the root file.

What to do:

- In the `### Plugin Directory Layout` ASCII tree in the root `CLAUDE.md`, the
  current `shared/` entry is a single-line comment:
  `│   └── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan`.
  Replace it with two lines listing both files, preserving the existing
  tree-drawing characters used in this file:

  ```
  │   ├── discovery-framework.md   # Discovery logic shared by generate-brief and generate-plan
  │   └── code-craft-principles.md # Code-craft principles shared by task-implementer, code-fixer, quality-reviewer
  ```

- In the paragraph that currently reads "The current entry is
  `discovery-framework.md`, loaded by both `generate-plan` Phase 1 and
  `generate-brief` Phase 1...", extend or add a second sentence describing
  `code-craft-principles.md`: which 3 agents reference it, what it defines
  (Simplicity + Surgical with stack-specific examples), and what it explicitly
  does not define (Goal-Driven Execution; Think Before Coding for ad-hoc
  interactions; per-language style guides; dispatch order / CONTEXT contracts).

Why: The root `CLAUDE.md` is the project-level orientation document. New
contributors and future Claude Code sessions reading it need to know `shared/`
has two files, not one, and what each one covers.

Input: Current repo-root `CLAUDE.md`.

Output: Modified root `CLAUDE.md` with the directory tree updated and the
`shared/` paragraph extended to cover both files.

Done when: ASCII tree includes the new file; the paragraph mentions both shared
files and their consumers; no other section of `CLAUDE.md` is modified.

**Step 3.2: Update `plugins/kenspc/README.md` (clarify "Stack-agnostic" and add Acknowledgements)**

What to do:

- Find the line in the README that reads
  "**Stack-agnostic** — Skills inspect project config files rather than assuming
  specific frameworks." Extend it to:
  "**Stack-agnostic skill behavior** — Skills inspect project config files rather
  than assuming specific frameworks. (Documentation examples in `shared/` may use
  specific languages — currently C# and TypeScript — to maximize teaching density;
  this does not constrain which projects the skills work with.)"
- In the `## Acknowledgements` section, add a new paragraph (matching the
  existing paragraph-style entries — the section uses paragraphs, not bullets):

  > The Simplicity First and Surgical Changes principles in
  > `shared/code-craft-principles.md` are derived from Andrej Karpathy's
  > [October 2025 X post](https://x.com/karpathy/status/2015883857489522876) on
  > common LLM coding pitfalls, by way of the
  > [`andrej-karpathy-skills`](https://github.com/doggy8088/andrej-karpathy-skills)
  > `AGENTS.md` compilation by [doggy8088](https://github.com/doggy8088) (forked
  > from [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)).
  > kenspc adopts two of the four principles; example code is original and
  > stack-specific to the maintainer's primary stacks.

Why: The original "Stack-agnostic" claim becomes literally false the moment C# / TS
examples enter the plugin. The clarification distinguishes BEHAVIORAL
stack-agnosticism (skill code) from DOCUMENTARY stack-agnosticism (examples) — the
former remains true, the latter is intentionally relaxed for teaching density. The
Acknowledgements entry discloses the source lineage (Karpathy → forrestchang →
doggy8088 → kenspc) and notes that only 2 of 4 principles were adopted, so a reader
of the source repo isn't confused about the partial coverage.

Input: Current `plugins/kenspc/README.md`.

Output: Modified `README.md` with:

- "Stack-agnostic" bullet reworded to "Stack-agnostic skill behavior" with
  one-sentence clarification.
- New Acknowledgements paragraph added (placed after the existing `agent-skills`
  paragraph and before the `thinkfirst` paragraph — the new paragraph's
  substance is closer to the agent-skills "behavioral guidelines" lineage than
  to `thinkfirst`'s discovery framework lineage). The Acknowledgements section
  uses paragraph format throughout; the new entry must match that format and
  must NOT be introduced as a bullet.

Done when: Both changes present; no other README content modified; Markdown
renders cleanly; the new Acknowledgements entry is a paragraph, not a list
item.

**Step 3.3: Update `plugins/kenspc/CHANGELOG.md` (v3.1.0 entry) and bump `plugin.json`**

What to do:

- Add a new top entry above the existing `## 3.0.3` entry:

  ```
  ## 3.1.0 — <today's date>

  Adds Simplicity First and Surgical Changes code-craft principles as a new shared
  resource referenced by `task-implementer`, `code-fixer`, and `quality-reviewer`.
  Relocates scope-creep guards from agent bodies to a single source of truth.
  No breaking changes; no CONTEXT block schema changes; no SKILL or agent interface
  changes for callers.

  ### Rationale

  ... [3-4 paragraphs covering: the gap (no Simplicity guard; Surgical scattered
  in 3 places); why karpathy's 4 principles got narrowed to 2 (Goal-Driven already
  covered, Think Before Coding belongs outside the plugin); how this aligns with v3
  design rules (Why-not-Command; principle-driven over step-driven; SSoT)] ...

  ### Added

  - `shared/code-craft-principles.md` — defines Simplicity First and Surgical Changes
    with C# and TypeScript diff examples; referenced by 3 agents.
  - `quality-reviewer`: two new REVIEW CHECKLIST bullets (over-engineering;
    drive-by refactoring / style drift).

  ### Changed

  - `task-implementer`: 2 scope-creep bullets relocated to shared file; new
    CODE-CRAFT PRINCIPLES reference section added.
  - `code-fixer`: 2 surgical bullets in FIXING RULES replaced with reference to
    shared file.
  - `README.md`: "Stack-agnostic" reworded as "Stack-agnostic skill behavior" with
    clarification about documentary examples being stack-specific.
  - `CLAUDE.md`: directory tree and `shared/` paragraph extended to cover the new
    file.

  ### Acknowledgements

  Karpathy's October 2025 X post on LLM coding pitfalls is the source of the two
  principles; see plugin README Acknowledgements for the lineage chain.

  ### Out of scope (deferred / not adopted)

  - Karpathy Principle 1 "Think Before Coding" for ad-hoc non-workflow interactions
    — intentionally not in the plugin (plugin has no reliable always-on mechanism;
    belongs in user / project CLAUDE.md).
  - Karpathy Principle 4 "Goal-Driven Execution" — already covered by kenspc's
    DONE-criteria pattern across all SKILLs.
  ```

- Bump `plugins/kenspc/.claude-plugin/plugin.json` `"version"` field from `"3.0.3"`
  to `"3.1.0"`. Do NOT modify the description string (this change does not affect
  the marketplace summary or full plugin description).
- Do NOT modify any agent frontmatter `version:` field. (Audit confirms: no
  agent file currently carries a `version:` frontmatter entry, and SKILL.md
  files stayed at `3.0.0` through the v3.0.1 / v3.0.2 / v3.0.3 patch releases
  — the established convention is that per-file `version:` fields are not
  bumped on every plugin release. This step is therefore a no-op for agent
  files.)
- Do NOT modify any SKILL.md `version:` field either. v3.1.0 does not touch
  any SKILL.md file, so the SKILL versions stay at 3.0.0 by the same
  convention.

Why: v3.1.0 because this is an additive feature (new shared file, new review angle,
plus a documentation correction) with zero breaking changes — minor bump per
semver. The CHANGELOG's `Out of scope` section explicitly records the two unadopted
principles so future maintainers don't re-litigate the decision.

Input: Current `CHANGELOG.md` and `plugin.json`.

Output: CHANGELOG with new v3.1.0 entry; `plugin.json` version bumped; agent
and SKILL frontmatter unchanged (no `version:` fields touched, per current
convention).

Done when: CHANGELOG entry present with Rationale / Added / Changed /
Acknowledgements / Out of scope subsections; `plugin.json` shows
`"version": "3.1.0"`; `grep -rn "^version:" plugins/kenspc/agents/` returns
empty; `grep -rn "^version:" plugins/kenspc/skills/` shows all SKILL.md files
unchanged from current state.

### Phase 4: Validation

**Step 4.1: Cross-file consistency check**

What to do:

- Grep for the phrases that were relocated: "Do not modify code unrelated to the
  current task", "Refactor code unrelated", "Do not introduce new features or
  refactor", "Preserve the original code's style". Confirm they appear ONLY in
  `shared/code-craft-principles.md` (in the principle text or examples), and NOT
  in any agent file.
- Grep for "code-craft-principles.md" — confirm the three agents that should
  reference it do, and no other agent does.
- Open the applicability table in the shared file and check each cell matches
  the actual operational stance described in the corresponding agent body.

Why: B2 (relocate, not layer) only delivers SSoT value if the relocated text really
moves. A residual copy left in an agent file means future drift is back.

Input: All modified files.

Output: A short verification report — pass / fail per check.

Done when: All three greps return the expected count (0 in agents, ≥1 in shared
file); all three applicability table rows match agent bodies; no contradiction found.

**Step 4.2: Portable-path and link check**

What to do:

- Grep every modified agent file for the string
  `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` and confirm the prefix is
  exactly that (no hardcoded `~/` or absolute paths).
- Verify the new shared file's internal section anchors (`#simplicity-first`,
  `#surgical-changes`) are not referenced from anywhere yet — if they are, confirm
  the heading slugs match GitHub's auto-generation rules.

Why: kenspc's portable-path rule (CLAUDE.md: "All file references in hooks and
commands must use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths"). Any
relative or hardcoded path silently breaks the plugin on machines where the install
path differs.

Input: All modified files.

Output: Verification report.

Done when: All references use the portable prefix; no hardcoded paths found.

**Step 4.3: Subtraction audit**

What to do:

- Count net lines added across all modified files (excluding the new
  `code-craft-principles.md` itself).
- Confirm the count is roughly net-zero or net-negative — i.e., the agent files
  shed approximately as many lines (relocated content) as they gained (reference
  line + over-engineering bullets).

Why: This change is justified partly by the v1.5 Subtraction Audit philosophy
("compress to principle-level, retain signal"). If agent files net-grew
significantly, something went wrong — likely the relocation kept too much in the
original location.

Input: Git diff of all modified files except the new shared file.

Output: A line-count summary that reflects the planned per-agent edits, e.g.,
"task-implementer: −2 (2 scope-creep bullets) +4 (CODE-CRAFT PRINCIPLES
reference section) = net +2; code-fixer: −2 (2 FIXING RULES bullets) +1
(reference bullet) = net −1; quality-reviewer: +2 (over-engineering + drive-by
bullets) = net +2; total agents: net +3 across three files."

Done when: The summary is roughly small (within ±5 lines per file and within
±10 lines total across all agent files); if any single file moves by more than
±5 lines, the relocation is reviewed for incomplete subtraction or for the
reference text growing beyond a single short paragraph. (The new shared file
itself is excluded from this count — it is a deliberate net addition.)

## Risks and Mitigations

| # | Risk | Likelihood | Mitigation |
|---|------|------------|-----------|
| 1 | Subtle wording in relocated text is load-bearing for the agent's behavior; relocation drift causes regression | Medium | Step 4.1 grep verification; review every removed line and check the shared file covers the same operational instruction, not just the slogan |
| 2 | Stack-specific examples (C# / TS) make the file feel less universal; future contributors hesitant to add a Rust or Python example | Low | The README clarification makes the documentary-vs-behavioral distinction explicit; new contributors can add more languages later if real demand emerges, but the maintainer's primary stacks are the right default |
| 3 | The new "over-engineering" REVIEW CHECKLIST bullet causes `quality-reviewer` to flag false positives on legitimate abstractions | Medium | The bullet is scoped to "for single-use code" and "unrequested" — these qualifiers exist precisely to prevent flagging real abstractions; if false positives appear in practice, tighten in v3.1.1 |
| 4 | Examples grow over time; the shared file balloons to 300+ lines like Karpathy's EXAMPLES.md | Low | Phase 1 sizing caps each example at ≤ 25 lines per side; future additions go through plan/task review; if growth is real, split into per-principle files later |
| 5 | `task-implementer`'s STOP-and-BLOCKED triggers and the new Simplicity reference could be read as contradictory by the agent (one says "stop if it changes API contract", the other says "minimum code") | Low | Step 2.1's preservation note keeps STOP-and-BLOCKED triggers and the QUALITY CHECKLIST local to the agent and explicitly labels them as workflow-specific decision boundaries / correctness checks (NOT code-craft principles). Step 1.4's applicability table covers the orthogonal author-vs-reviewer dimension. The two scopes — when to halt, vs. how to write the code that does get written — operate at different levels and do not conflict |
| 6 | Bumping plugin version to 3.1.0 implies more substance than the change actually contains, inflating the changelog signal | Low | The CHANGELOG Rationale section honestly characterizes scope; 3.1.0 is consistent with v1.5.0's "add a new shared resource" precedent |

## Open Questions

None — all five design decisions are locked. Any new questions that surface during
implementation should be raised back through `/kenspc-plan` rather than resolved
unilaterally during execution.
