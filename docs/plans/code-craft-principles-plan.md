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

The pattern differs from `discovery-framework.md` in one important way. `discovery-framework.md` is referenced from SKILL.md files, which the main session loads at skill activation — a single Read at the start of the workflow is enough. `code-craft-principles.md` is referenced from agent bodies, and agents may be dispatched many times across a run. A pure reference-only model would either force a Read on every dispatch (wasteful) or risk the agent skipping the Read entirely (loss of guarantee).

The chosen model is therefore a **hybrid (inline summary + reference for examples)** that mirrors Karpathy's own two-file split (`AGENTS.md` short + `EXAMPLES.md` long):

- Single markdown file `shared/code-craft-principles.md` holds the **canonical** principle paragraphs, the per-principle checklists, the C# / TypeScript diff examples, the applicability table, and the "What This File Does NOT Define" section.
- Each of the three consumer agents (`task-implementer`, `code-fixer`, `quality-reviewer` where applicable) **inlines a byte-identical copy of the two principle paragraphs** in its system-prompt body. This guarantees the principle is loaded into every dispatch without depending on a runtime Read.
- The agent body **references** `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md` for the long content (checklists, diff examples, applicability table). The agent only Reads it when it needs to disambiguate an edge case against an example.
- Byte-identity of the inlined principle paragraphs across the agent bodies and the shared file is enforced by a new check script (Step 4.4), modeled on the existing `check-review-agent-drift.sh` / `check-canonical-dispatch.sh` invariants. Drift between any two copies is a CI failure, not a silent regression.

### Consumer wiring

| Consumer | Current state | After this plan |
|----------|--------------|------------------|
| `agents/task-implementer.md` | Scope-creep guards in 3 places (QUALITY RULES, AUTONOMY BOUNDARIES, STOP triggers). No Simplicity guard. | Relocated guards removed → new `CODE-CRAFT PRINCIPLES` section inlines both principle paragraphs (byte-identical to shared file) and references the shared file for examples and applicability. |
| `agents/code-fixer.md` | Surgical guidance under FIXING RULES ("Do not introduce new features or refactor code beyond what the issue requires", "Preserve the original code's style and structure"). | Both surgical bullets replaced; new `CODE-CRAFT PRINCIPLES` section inlines both principle paragraphs (byte-identical to shared file) and references the shared file for examples. |
| `agents/quality-reviewer.md` | REVIEW CHECKLIST has "Code complexity" (asks to break down complex functions). No over-engineering check (the opposite direction — flagging code that goes beyond what was asked). | Adds two new REVIEW CHECKLIST bullets (over-engineering; drive-by refactoring / style drift), each gated by three-layer qualifier conditions so cascading task-driven changes and project-convention-mandated abstractions are not flagged. References shared file for the underlying principle definitions and applicability stance. |

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
- **Canonical paragraph contract.** The one-paragraph principle statement written in
  this Step is the canonical source that Steps 2.1 and 2.2 will inline byte-identical
  into `task-implementer.md` and `code-fixer.md`. Surround the paragraph in the
  shared file with HTML-comment markers exactly as:

  ```
  <!-- canonical:principle:simplicity-first:start -->
  **Simplicity First.** ... (the rationale-form paragraph) ...
  <!-- canonical:principle:simplicity-first:end -->
  ```

  Step 4.4 sha256-hashes the bounded block and compares against the same block in
  every agent file that inlines it. The marker pattern matches the existing
  `<!-- canonical:dispatch:start -->` / `:end` invariant already used between
  `task-review/SKILL.md` and `task-implement/SKILL.md`.

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
near the statement); the paragraph is bounded by the
`<!-- canonical:principle:simplicity-first:start -->` /
`<!-- canonical:principle:simplicity-first:end -->` markers and is the only block
between those markers; checklist has 4–6 bullets; two diff examples present (one C#,
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
- **Canonical paragraph contract.** Surround the one-paragraph principle statement
  with markers exactly as:

  ```
  <!-- canonical:principle:surgical-changes:start -->
  **Surgical Changes.** ... (the rationale-form paragraph) ...
  <!-- canonical:principle:surgical-changes:end -->
  ```

  Same enforcement as Step 1.2's canonical block — Step 4.4 hashes and compares
  against every agent file that inlines this paragraph.

Why: Surgical Changes is the principle kenspc currently mentions in the most places
but defines least consistently — examples are the way to lock down what "surgical"
actually looks like in diff terms. The two example types (drive-by refactor / style
drift) are the two failure modes Karpathy's `EXAMPLES.md` calls out, and they map
directly to the two ways `task-implementer` currently bleeds scope.

Input: Same as 1.2 — author's choice of scenario, but plausible for kenspc users.

Output: A ~50-line Surgical Changes section.

Done when: Same shape as 1.2 (rationale-form paragraph wrapped in
`<!-- canonical:principle:surgical-changes:start/end -->` markers, 4–6 checklist
bullets, two diff examples meeting language and length constraints).

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
  the `AUTONOMY BOUNDARIES` section, titled `CODE-CRAFT PRINCIPLES`. The body
  has three parts in this exact order:

  1. **Inlined canonical paragraphs.** Copy the two canonical principle blocks
     from the shared file byte-identical, including the surrounding
     `<!-- canonical:principle:simplicity-first:start --> ... :end -->` and
     `<!-- canonical:principle:surgical-changes:start --> ... :end -->`
     markers. The markers must be present in the agent file so Step 4.4's
     hash check can find and compare the bounded blocks.
  2. **Applicability line.** Add one short sentence after the second canonical
     block: "This agent's applicability stance (see shared file's table): author
     at write time."
  3. **Examples reference.** Add one short line: "For worked C# / TypeScript
     diff examples and edge cases, see
     `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`."

- Keep `STOP and mark task as BLOCKED` triggers untouched (these are not
  principle-level — they are workflow-specific decision boundaries about when to
  halt versus push back).
- Keep the `QUALITY CHECKLIST` untouched (these are correctness checks: edge cases,
  error handling, async correctness, resource cleanup, magic numbers, tests,
  security — they are orthogonal to Simplicity and Surgical and remain agent-local).

Why: Relocating the scope-creep guards eliminates the three-place duplication
currently in this agent. Inlining the canonical principle paragraphs (rather than
pure reference) guarantees the principles are loaded into every dispatch of this
agent without depending on a runtime Read — and the byte-identity invariant
enforced by Step 4.4 prevents drift between the inlined copy and the shared
file's authoritative version. Adding the Simplicity content fills the gap that
prompted this whole change (the agent had no minimum-code guidance). Keeping
`STOP-and-BLOCKED` and `QUALITY CHECKLIST` local respects the principle that
workflow-specific decision logic and correctness checklists are NOT code-craft
principles and should not be confused with them.

Input: Current `agents/task-implementer.md`.

Output: Modified `agents/task-implementer.md` with:

- 2 bullets removed (from `QUALITY RULES` and `AUTONOMY BOUNDARIES`).
- 1 new `CODE-CRAFT PRINCIPLES` section added containing the two canonical
  principle blocks (with markers), one applicability line, and one examples
  reference line. Total ~12–16 lines added (depends on canonical paragraph
  lengths).
- All other sections (`PREREQUISITE CHECK`, `OBJECTIVE`, `DONE CRITERIA`,
  `PROCESSING APPROACH`, `STUCK HANDLING`, `CODE ARTIFACTS LANGUAGE`, `OUTPUT
  FORMAT`) untouched.

Done when: A diff shows 2 lines removed and ~12–16 lines added; the agent file
still parses as valid frontmatter + markdown; both canonical marker pairs are
present and contain exactly the matching paragraph from the shared file (Step
4.4 hash check will verify); `task-implementer` still has all its prerequisite
checks, autonomy boundaries (BLOCKED triggers), and Schema D output contract.

**Step 2.2: Update `agents/code-fixer.md` (replace surgical bullets with inlined principles + reference)**

What to do:

- In the `FIXING RULES` section, remove:
  - "Do not introduce new features or refactor code beyond what the issue requires."
  - "Preserve the original code's style and structure."
- After the `FIXING RULES` section and before `FIXING PRIORITY`, add a new
  section titled `CODE-CRAFT PRINCIPLES` with the same three-part body shape
  used in Step 2.1:

  1. **Inlined canonical paragraphs.** Copy the two canonical principle blocks
     from the shared file byte-identical, including the surrounding marker
     pairs. The blocks here must be the same bytes as those in
     `task-implementer.md` and the shared file — Step 4.4 hashes all three
     locations and fails on any mismatch.
  2. **Applicability line.** "This agent's applicability stance (see shared
     file's table): author at fix time. Structural improvements not in the
     review report are DEFERRED, not applied."
  3. **Examples reference.** "For worked C# / TypeScript diff examples and
     edge cases, see `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`."

- Keep all other `FIXING RULES` bullets ("Follow established project conventions and
  patterns", "Each fix is a separate, focused git commit with a clear message",
  "Code, code comments, and commit messages stay in English") untouched.
- Keep `FIXING PRIORITY`, `PER-ISSUE OUTPUT CONTRACT`, and `OUTPUT FORMAT (Schema B)`
  fully untouched.

Why: `code-fixer` already has the strongest Surgical wording in the plugin; this
change is partly a SSoT consolidation (so the principle definition lives once)
and partly a reliability fix (inlining the canonical paragraphs guarantees the
principles are loaded into every dispatch). The author-at-fix-time stance
preserves the existing intent (fixes are narrow, structural changes get
DEFERRED, not applied).

Input: Current `agents/code-fixer.md`.

Output: Modified `agents/code-fixer.md` with 2 surgical bullets removed from
`FIXING RULES` and a new `CODE-CRAFT PRINCIPLES` section added (containing two
canonical blocks with markers, one applicability line, one examples reference
line — total ~12–16 lines added).

Done when: A diff shows 2 lines removed and ~12–16 lines added; nothing
else changes; both canonical marker pairs are present with matching bytes
(verifiable via Step 4.4); `FIXING PRIORITY` decision matrix (HIGH/MEDIUM/LOW
action rules) is intact; Schema B output contract (with the `short_label` ≤ 60
chars requirement) is intact.

**Step 2.3: Update `agents/quality-reviewer.md` (add over-engineering review angle)**

What to do:

- In the `REVIEW CHECKLIST` section, KEEP the existing "Code complexity: are there
  overly complex functions that should be broken down?" bullet untouched (this is a
  legitimate readability check that catches a different failure mode).
- ADD a new bullet immediately after it (the **Over-engineering** bullet),
  written with three explicit exclusion conditions so cascading task-driven
  changes and project-convention-mandated abstractions are not flagged:

  > **Over-engineering.** Flag features, abstractions, or configurability that
  > meet **all three** of the following conditions:
  >
  > 1. Not in the task document's stated requirements, AND
  > 2. Not mandated by project conventions documented in `CLAUDE.md`,
  >    `README.md`, or visible patterns in adjacent code, AND
  > 3. Not a boundary validation required by the project's security or input-
  >    handling rules (system-boundary validations are correct design, not
  >    over-engineering).
  >
  > Why: abstractions or validations that meet condition (2) or (3) are correct
  > design — flagging them creates noise that erodes trust in this reviewer's
  > signal. Apply Simplicity First per
  > `${CLAUDE_PLUGIN_ROOT}/shared/code-craft-principles.md`; the applicability
  > table states this agent's stance: detect, do not fix.

- ADD a second new bullet immediately after the over-engineering one (the
  **Drive-by refactoring** bullet), with parallel three-condition gating:

  > **Drive-by refactoring and style drift in the diff.** Flag changes to
  > adjacent code that meet **all three** of the following conditions:
  >
  > 1. Not required by the task, AND
  > 2. Not mechanically forced by the change (interface signature changes
  >    cascade to implementers; removing the last call to a function orphans
  >    imports; lint-mandated formatting changes), AND
  > 3. Not convergence to the canonical project style (a "drift" toward
  >    documented style is correct, not drive-by).
  >
  > Why: cascading task-driven changes are the change itself, not drive-by —
  > flagging them would force the implementer to leave the codebase in a
  > broken state. Apply Surgical Changes per the same shared file.

- Keep all other checklist items (Naming, Project structure, DRY, SOLID, Magic
  numbers) untouched.

Why: `quality-reviewer` currently has a complexity check pointing in the OPPOSITE
direction (break down complex functions) — useful, but it doesn't catch the
over-engineering failure mode that Karpathy's Simplicity principle targets. Adding
two new detection bullets fills this gap without removing existing coverage. The
"detect, do not fix" stance is critical: review agents in kenspc are read-only;
`code-fixer` is the only agent that modifies code.

Input: Current `agents/quality-reviewer.md`.

Output: Modified `agents/quality-reviewer.md` with 2 new multi-line bullets added
to `REVIEW CHECKLIST` (each ~10–14 lines including the three-condition gate and
the Why line). The other 4 reviewer agents (requirements, edge-case, bug, test)
are NOT modified.

Note: `quality-reviewer` does NOT inline the canonical principle paragraphs the
way `task-implementer` and `code-fixer` do. The reviewer's content is the
**detection** rules (above bullets), which reference but do not duplicate the
**principle definitions**. This asymmetry matches the applicability-table
stance "Apply" (writer agents need the principle text loaded for every write
decision) vs "Detect" (reviewer's working tool is the detection bullets, not the
principle text). Step 4.4 therefore only checks byte-identity across
`task-implementer.md`, `code-fixer.md`, and the shared file.

Done when: A diff shows ~20–28 lines added in `REVIEW CHECKLIST` (two
multi-line bullets); both bullets list all three exclusion conditions; both
bullets include the "Why:" line explaining the rationale (matching the Why-not-
Command design rule); the Schema A output contract is unchanged;
`quality-reviewer`'s `effort: xhigh` stays; no other reviewer agent files are
touched.

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

  - `shared/code-craft-principles.md` — defines Simplicity First and Surgical
    Changes with C# and TypeScript diff examples; canonical principle paragraphs
    are bounded by `<!-- canonical:principle:<key>:start/end -->` markers and
    mirrored byte-identical into the writer agents.
  - `quality-reviewer`: two new REVIEW CHECKLIST bullets (over-engineering;
    drive-by refactoring / style drift), each gated by three explicit
    exclusion conditions to prevent false positives on project-convention
    abstractions, mechanically-forced cascades, and canonical-style
    convergence.
  - `scripts/check-code-craft-canonical.sh` — new repo-level check script
    that hashes the canonical principle blocks in the shared file and in the
    two writer agents and fails on any byte-divergence. Modeled on the
    existing `check-canonical-dispatch.sh` invariant.

  ### Changed

  - `task-implementer`: 2 scope-creep bullets removed; new CODE-CRAFT
    PRINCIPLES section inlines both canonical principle paragraphs (with
    markers) and references the shared file for examples and applicability.
  - `code-fixer`: 2 surgical bullets removed from FIXING RULES; new CODE-CRAFT
    PRINCIPLES section inlines both canonical principle paragraphs (with
    markers) and references the shared file for examples.
  - `README.md`: "Stack-agnostic" reworded as "Stack-agnostic skill behavior" with
    clarification about documentary examples being stack-specific; new
    Acknowledgements paragraph crediting Karpathy / forrestchang / doggy8088.
  - `CLAUDE.md` (root): directory tree extended to list both shared files;
    `shared/` paragraph extended to cover the new file; "Repository scripts/"
    section extended to list the new check script; "Validate plugin structure"
    block extended to invoke the new check script.

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
  `#surgical-changes`) are not referenced from anywhere yet. If they are
  referenced, confirm the actual headings produce those slugs under GitHub's
  auto-generation rules (heading text lowercased, spaces → hyphens, most
  punctuation stripped). For the two principles in this plan, the expected
  pairings are `## Simplicity First` → `#simplicity-first` and `## Surgical
  Changes` → `#surgical-changes` — any deviation from these heading strings
  breaks the anchor link.

Why: kenspc's portable-path rule (CLAUDE.md: "All file references in hooks and
commands must use `${CLAUDE_PLUGIN_ROOT}` — never hardcode absolute paths"). Any
relative or hardcoded path silently breaks the plugin on machines where the install
path differs.

Input: All modified files.

Output: Verification report.

Done when: All references use the portable prefix; no hardcoded paths found.

**Step 4.3: Subtraction audit (revised for hybrid model)**

What to do:

- Count net lines added across all modified files (excluding the new
  `code-craft-principles.md` itself).
- Compare each agent's net delta against the expected bounds below. The
  expected growth is **not** net-zero because the hybrid model intentionally
  inlines canonical principle paragraphs into the writer agents — accepting
  a one-time net-positive in exchange for runtime-load reliability.

Why: This change is justified partly by the v1.5 Subtraction Audit philosophy
("compress to principle-level, retain signal"). Under the hybrid model the
audit's purpose shifts: it no longer enforces zero growth, but it still
catches **wrong-shape growth** — e.g., examples being inlined instead of just
the principle paragraph, or scope-creep bullets being left in their original
location and duplicated rather than relocated.

Input: Git diff of all modified files except the new shared file.

Output: A per-file line-count summary against the expected bounds:

| File | Removed | Added | Net | Expected upper bound |
|------|---------|-------|-----|---------------------|
| `task-implementer.md` | 2 (scope-creep bullets) | ~12–16 (CODE-CRAFT PRINCIPLES section: 2 canonical blocks with markers + applicability line + examples reference) | +10 to +14 | +18 |
| `code-fixer.md` | 2 (FIXING RULES surgical bullets) | ~12–16 (same shape) | +10 to +14 | +18 |
| `quality-reviewer.md` | 0 | ~20–28 (two multi-line REVIEW CHECKLIST bullets with three-condition gates and Why lines) | +20 to +28 | +32 |
| `README.md` | 1 (Stack-agnostic line) | ~10 (rewritten line + Acknowledgements paragraph) | +9 | +14 |
| `CLAUDE.md` (root) | 1 (single shared/ tree line) | ~6 (two tree lines + extended paragraph) | +5 | +10 |
| `CHANGELOG.md` | 0 | ~40 (v3.1.0 entry) | +40 | +50 (changelogs grow) |
| `plugin.json` | 1 | 1 | 0 | 0 |
| **Agents subtotal** | 4 | ~44–60 | **+40 to +56** | **+68** |

Done when: Every file's net delta is within its expected upper bound. If any
agent file exceeds its upper bound, the relocation is reviewed for one of:
(a) examples accidentally inlined alongside the principle paragraph,
(b) scope-creep bullets not actually removed from their original location and
remaining duplicated, (c) applicability or reference text exceeding one short
line each. The new shared file is excluded from this count — it is a deliberate
net addition justified by SSoT consolidation.

**Step 4.4: Byte-identity check for inlined canonical principle paragraphs**

What to do:

- Create a new script `scripts/check-code-craft-canonical.sh` modeled on the
  existing `scripts/check-canonical-dispatch.sh`. The new script:
  - For each of the two principle keys (`simplicity-first`, `surgical-changes`),
    extracts the content between `<!-- canonical:principle:<key>:start -->` and
    `<!-- canonical:principle:<key>:end -->` from three files:
    1. `plugins/kenspc/shared/code-craft-principles.md` (authoritative)
    2. `plugins/kenspc/agents/task-implementer.md`
    3. `plugins/kenspc/agents/code-fixer.md`
  - Sha256-hashes each extracted block.
  - Fails with a clear error message if any of the three hashes for a given key
    do not match. Reports which file is the outlier.
  - Returns 0 if both keys' three-way hashes are identical across all three
    files.
- Update the repo-root `CLAUDE.md` "Repository scripts/" section to list the
  new script alongside `check-review-agent-drift.sh` and
  `check-canonical-dispatch.sh`, with the same "guards the byte-identity
  invariant" framing.
- Update the `## Development Workflow` → `Validate plugin structure` block in
  the root `CLAUDE.md` to add `bash scripts/check-code-craft-canonical.sh` to
  the "Cross-agent invariants" list.
- Update `docs/release-checklist.md` (if it enumerates pre-release greps) to
  include this script in the mechanical-check list.
- Run the script locally and confirm it returns 0 against the freshly
  committed agent and shared-file edits.

Why: The hybrid inline-summary + reference-for-examples model only delivers its
reliability promise if the inlined copies stay byte-identical with the
authoritative version. Without an automated check, the three copies of each
principle paragraph would drift over time as someone edits the shared file
without re-syncing the agent bodies (or vice versa). This is the same pattern
that `check-canonical-dispatch.sh` guards for the `## Code Review Phase`
canonical block between `task-review/SKILL.md` and `task-implement/SKILL.md`,
and that `check-review-agent-drift.sh` guards for the three shared sections
across the 5 review-angle agents. Establishing the script in this Step (rather
than as a follow-up) is what makes the hybrid model trustworthy.

Input: Existing `scripts/check-canonical-dispatch.sh` as the template.

Output: New script `scripts/check-code-craft-canonical.sh`; updated root
`CLAUDE.md` "Repository scripts/" section and "Validate plugin structure"
block; updated `docs/release-checklist.md` if applicable.

Done when: Script exists, is executable on both Windows (Git Bash) and WSL2
Ubuntu, returns 0 on the current tree, and is referenced from the two CLAUDE.md
locations listed above; a deliberate test mutation (e.g., changing one
character in one agent's canonical block) makes the script exit non-zero with
a clear "files differ" message; the mutation is reverted before commit.

**Step 4.5: Pre-ship sanity-check dry-run for `quality-reviewer`'s new bullets**

What to do:

- Pick **one** recently-merged real PR or commit from this repository that
  contains a representative shape of change. The selection criteria are:
  - The change includes at least one **mechanically-forced cascade** (e.g., an
    interface signature change with implementer updates) OR at least one
    **boundary validation** OR at least one **project-convention-mandated
    abstraction** (e.g., a new agent file following the established 11-agent
    structure).
  - The change was reviewed and merged without raising over-engineering or
    drive-by-refactoring concerns (i.e., it is a known-good baseline).
- Perform a **dry-run paper review** of the selected diff against the new
  `quality-reviewer` REVIEW CHECKLIST bullets only (over-engineering bullet
  and drive-by bullet). Do NOT run the full task-review skill — this is
  purely a sanity check on the two new bullets' three-condition gates.
- For each suspicious diff hunk, walk through the three exclusion conditions
  for that bullet and record whether the bullet would FLAG or PASS.
- Tabulate results:
  - If the bullet correctly PASSes all of the previously-merged hunks → the
    three-condition gates are tight enough; ship v3.1.0 as-is.
  - If the bullet would FLAG one or more hunks that were known-good →
    record which condition failed to gate it, and either (a) tighten the
    condition wording in Step 2.3 before shipping, or (b) downgrade Risk #3
    from "Low residual" back to "Medium" and flag for explicit v3.1.1
    revisit.

Why: A "Why-not-Command" rule's reliability is only knowable by running it
against real diffs. A purely-paper review can over- or under-tune the gates
because rule-writers tend to picture their intended examples. Anchoring the
test to a known-good past PR forces the gates to confront real-world shapes
of change. This step exists because Risk #3's mitigation explicitly depends
on it — without it, "Low residual" is unsubstantiated.

Input: Repository git history (look for a recently-merged PR that meets the
selection criteria — candidates include the `v2.0`-era plan/task refactors,
the `v3.0`-era agent split, or any recent CLAUDE.md restructuring that
involved cascading edits).

Output: A short dry-run report appended to the v3.1.0 release notes or
attached to the release-checklist run: the PR selected, the diff hunks
walked, the bullet's FLAG/PASS decision for each, and a one-line ship/no-ship
conclusion.

Done when: The dry-run report exists, has at least 3 walked-through hunks,
and ends in either "ship as-is" or "tighten Step 2.3 wording before ship"
with a concrete tightening proposal. If "tighten", the proposal is applied
to Step 2.3 and Step 4.5 is re-run.

## Risks and Mitigations

| # | Risk | Likelihood | Mitigation |
|---|------|------------|-----------|
| 1 | Subtle wording in relocated text is load-bearing for the agent's behavior; relocation drift causes regression | Medium | Step 4.1 grep verification; review every removed line and check the shared file covers the same operational instruction, not just the slogan |
| 2 | Stack-specific examples (C# / TS) make the file feel less universal; future contributors hesitant to add a Rust or Python example | Low | The README clarification makes the documentary-vs-behavioral distinction explicit; new contributors can add more languages later if real demand emerges, but the maintainer's primary stacks are the right default |
| 3 | The new over-engineering and drive-by REVIEW CHECKLIST bullets cause `quality-reviewer` to flag false positives on legitimate abstractions, mechanically-forced cascading changes, or style convergence | Medium → Low | Step 2.3 phrases both bullets with **three explicit exclusion conditions** (must satisfy all three to flag) that name the most common false-positive sources: project-convention-mandated abstractions, boundary validations, mechanically-forced cascades (interface signature → implementers; orphaned imports), and convergence to canonical style. Step 4.5 runs a pre-ship dry-run against a known-good past PR to confirm the bullets do not over-trigger. The three-condition gate plus the dry-run sanity check together reduce the residual risk to Low; if false positives still appear in practice, tighten in v3.1.1 |
| 4 | Examples grow over time; the shared file balloons to 300+ lines like Karpathy's EXAMPLES.md | Low | Phase 1 sizing caps each example at ≤ 25 lines per side; future additions go through plan/task review; if growth is real, split into per-principle files later |
| 5 | `task-implementer`'s STOP-and-BLOCKED triggers and the new Simplicity reference could be read as contradictory by the agent (one says "stop if it changes API contract", the other says "minimum code") | Low | Step 2.1's preservation note keeps STOP-and-BLOCKED triggers and the QUALITY CHECKLIST local to the agent and explicitly labels them as workflow-specific decision boundaries / correctness checks (NOT code-craft principles). Step 1.4's applicability table covers the orthogonal author-vs-reviewer dimension. The two scopes — when to halt, vs. how to write the code that does get written — operate at different levels and do not conflict |
| 6 | Bumping plugin version to 3.1.0 implies more substance than the change actually contains, inflating the changelog signal | Low | The CHANGELOG Rationale section honestly characterizes scope; 3.1.0 is consistent with v1.5.0's "add a new shared resource" precedent |

## Open Questions

All five design decisions remain locked. Two observations that surfaced during
plan review were RESOLVED by additions in this revision; one new observation
is recorded for post-ship revisit.

### Resolved during this plan revision

- **~~Reference-vs-inline cost.~~ RESOLVED.** The original plan used a pure
  reference-only SSoT model. Plan review surfaced that agents may skip the
  Read at dispatch time, breaking the reliability promise. **Resolution:**
  switched to a hybrid model — canonical principle paragraphs are now inlined
  byte-identical into `task-implementer.md` and `code-fixer.md` (so the
  principles are loaded into every dispatch via the agent's system prompt),
  while the shared file remains the SSoT for examples, checklists, and the
  applicability table. Byte-identity is enforced by a new check script (Step
  4.4) modeled on existing canonical-dispatch / review-agent-drift
  invariants. See revised Architecture section, Steps 1.2, 1.3, 2.1, 2.2,
  and the new Step 4.4 for the implementation.
- **~~Quality-reviewer false-positive rate.~~ RESOLVED (pending dry-run).**
  The original plan's two new REVIEW CHECKLIST bullets were phrased
  permissively, risking false positives on project-convention abstractions,
  mechanically-forced cascades, and style convergence. **Resolution:** Step
  2.3 now phrases both bullets with explicit three-condition exclusion
  gates (must satisfy all three to flag) covering the most common false-
  positive sources. Step 4.5 adds a pre-ship dry-run against a known-good
  past PR to substantiate the "Low residual" risk rating. The "Resolved
  pending dry-run" qualifier acknowledges that the substantiation is
  completed by Step 4.5 during execution, not at plan time.

### Recorded for post-v3.1.0 revisit

- **Stack coverage of examples.** The shared file's diff examples are C# and
  TypeScript per decision A2. The maintainer's primary stacks are well-served,
  but if external contributors raise issues showing Rust / Python /
  Java-specific over-engineering patterns that the current examples do not
  cover, a v3.2.0 may add a third example pair. This is not blocking and is
  not actionable during v3.1.0 — it depends on real usage signal.

Any new questions that surface during implementation should be raised back
through `/kenspc-plan` rather than resolved unilaterally during execution.
