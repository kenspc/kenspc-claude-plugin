# Code-Craft Principles

Shared code-craft principles referenced by `task-implementer`, `code-fixer`, and `quality-reviewer`. Defines two write-time and review-time anchors — Simplicity First and Surgical Changes — with worked C# / TypeScript diff examples and a per-agent applicability table. Authoritative source for the principle paragraphs that the two writer agents inline as byte-identical copies.

## Simplicity First

<!-- canonical:principle:simplicity-first:start -->
**Simplicity First.** Write the minimum code that solves the stated problem. Why: speculative abstractions ("we might need this later") and unrequested flexibility accumulate as dead weight when the speculation does not pay out, and they make the actual code path harder to follow for the next reader. The cost of adding the abstraction when a second or third concrete use case arrives is almost always lower than the cost of carrying it from day one across every reader who has to skip past it. Refactor toward abstraction when the second concrete use case lands, not the first.
<!-- canonical:principle:simplicity-first:end -->

Checklist — what Simplicity First rules out in practice:

- Do not add error handling for scenarios that cannot occur given the current call sites (e.g., a private helper checking for `null` when every caller already validated).
- Do not add flexibility, configurability, or options the task did not request — no `option1` / `option2` flags "in case we need them".
- Do not introduce an abstraction (interface, strategy, factory) for code that has exactly one concrete implementation today.
- Do not write defensive validation for inputs that come from another part of the same module — validate at system boundaries, not internal seams.
- If you wrote 200 lines and 50 lines would solve the same problem, rewrite. The shorter version is the deliverable.

### Example 1 — C#: over-abstraction (strategy pattern for a single use case)

```csharp
// ❌ Strategy + interface for a code path with exactly one implementation
public interface INotificationStrategy
{
    Task SendAsync(string userId, string message);
}

public class EmailNotificationStrategy : INotificationStrategy
{
    private readonly IEmailClient _email;
    public EmailNotificationStrategy(IEmailClient email) => _email = email;
    public Task SendAsync(string userId, string message)
        => _email.SendAsync(userId, message);
}

public class NotificationService
{
    private readonly INotificationStrategy _strategy;
    public NotificationService(INotificationStrategy strategy) => _strategy = strategy;
    public Task NotifyAsync(string userId, string message)
        => _strategy.SendAsync(userId, message);
}
```

```csharp
// ✅ One method, one call. Add the interface when the second channel lands.
public class NotificationService
{
    private readonly IEmailClient _email;
    public NotificationService(IEmailClient email) => _email = email;
    public Task NotifyAsync(string userId, string message)
        => _email.SendAsync(userId, message);
}
```

### Example 2 — TypeScript: speculative-feature trap (unrequested options on an endpoint)

```ts
// ❌ The task said "return the user's open assignments". These flags were never asked for.
interface GetAssignmentsOptions {
  includeCompleted?: boolean;
  includeArchived?: boolean;
  sortBy?: 'dueDate' | 'createdAt' | 'priority';
  limit?: number;
  offset?: number;
}

export async function getAssignments(
  userId: string,
  options: GetAssignmentsOptions = {},
): Promise<Assignment[]> {
  const where: AssignmentWhere = { userId, status: 'open' };
  if (options.includeCompleted) where.status = undefined;
  if (options.includeArchived === false) where.archivedAt = null;
  const orderBy = options.sortBy ?? 'dueDate';
  return db.assignment.findMany({
    where,
    orderBy: { [orderBy]: 'asc' },
    take: options.limit,
    skip: options.offset,
  });
}
```

```ts
// ✅ Solve the stated problem. Add flags when a caller actually asks for them.
export async function getOpenAssignments(userId: string): Promise<Assignment[]> {
  return db.assignment.findMany({
    where: { userId, status: 'open' },
    orderBy: { dueDate: 'asc' },
  });
}
```

## Surgical Changes

<!-- canonical:principle:surgical-changes:start -->
**Surgical Changes.** Touch only what the task requires. Why: a diff that mixes task-required edits with drive-by rewrites, adjacent-code "improvements", and personal style preferences forces the reviewer to disentangle intent before they can verify correctness, and inflates the blast radius of every revert. The reader of a diff trusts that everything they see is necessary for the stated change; that trust is what makes review fast. Keep unrelated changes for their own task, even when the cleanup feels obvious in the moment.
<!-- canonical:principle:surgical-changes:end -->

Checklist — what Surgical Changes rules out in practice:

<!-- guard: the literal phrases "Do not modify code unrelated to the current task", "Refactor code unrelated", "Do not introduce new features or refactor", and "Preserve the original code's style" are pinned here by Task 12's relocation grep contract. Do not reword the opening of these bullets even if the grammar looks awkward; the verbatim substrings must remain present in this file. -->
- Do not modify code unrelated to the current task, even when you are in the file for an unrelated reason. The diff stays scoped to what the task required.
- Refactor code unrelated to the current task is out; do not refactor things that are not broken even when you would have written them differently from scratch.
- Do not introduce new features or refactor code beyond what the task or review report requires; file follow-ups instead of smuggling them into the current diff.
- Preserve the original code's style and structure — naming convention, brace style, async pattern, member order — even when you prefer another.
- Remove imports, variables, or helpers that your changes orphaned; do not remove pre-existing dead code that your task did not touch.

### Example 1 — C#: drive-by refactoring while fixing one method

```csharp
// ❌ Task said "fix the off-by-one in GetOpenAssignments". The diff also
//    renames a field, reorders members, and changes the file's brace style.
public class AssignmentRepository
{
    private readonly DbContext _ctx;  // was: _context
    public AssignmentRepository(DbContext ctx) {
        _ctx = ctx;
    }

    public async Task<int> CountOpenAsync(string userId) =>
        await _ctx.Assignments.CountAsync(a => a.UserId == userId && a.Status == "open");

    public async Task<List<Assignment>> GetOpenAssignmentsAsync(string userId, int page, int size) {
        var skip = (page - 1) * size;  // off-by-one fix here
        return await _ctx.Assignments
            .Where(a => a.UserId == userId && a.Status == "open")
            .Skip(skip).Take(size)
            .ToListAsync();
    }
}
```

```csharp
// ✅ Same off-by-one fix, nothing else.
public class AssignmentRepository
{
    private readonly DbContext _context;

    public AssignmentRepository(DbContext context)
    {
        _context = context;
    }

    public async Task<List<Assignment>> GetOpenAssignmentsAsync(string userId, int page, int size)
    {
        var skip = (page - 1) * size;  // off-by-one fix
        return await _context.Assignments
            .Where(a => a.UserId == userId && a.Status == "open")
            .Skip(skip).Take(size)
            .ToListAsync();
    }

    public async Task<int> CountOpenAsync(string userId)
    {
        return await _context.Assignments
            .CountAsync(a => a.UserId == userId && a.Status == "open");
    }
}
```

### Example 2 — TypeScript: style drift while adding a field

```ts
// ❌ Task said "add `archivedAt` to the User type". The diff also switches
//    the existing arrow-function members to method syntax and rewraps unrelated lines.
export type User = {
  id: string;
  email: string;
  createdAt: Date;
  archivedAt: Date | null;
};

export class UserService {
  constructor(private readonly db: Db) {}

  async findById(id: string): Promise<User | null> {
    return this.db.user.findUnique({ where: { id } });
  }

  async findByEmail(
    email: string,
  ): Promise<User | null> {
    return this.db.user.findUnique({ where: { email } });
  }
}
```

```ts
// ✅ Only the new field. Existing style preserved exactly.
export type User = {
  id: string;
  email: string;
  createdAt: Date;
  archivedAt: Date | null;
};

export class UserService {
  constructor(private readonly db: Db) {}
  findById = (id: string) => this.db.user.findUnique({ where: { id } });
  findByEmail = (email: string) => this.db.user.findUnique({ where: { email } });
}
```

## How Each Agent Applies These

Same principles, different operational stance per agent. Writer agents (`task-implementer`, `code-fixer`) **Apply** these at decision time; the reviewer agent (`quality-reviewer`) **Detects** violations after the fact and does not fix them.

| Agent | Role | Simplicity | Surgical |
|-------|------|-----------|----------|
| `task-implementer` | Author at write time | Apply: write the minimum code that satisfies the task's stated acceptance criteria; do not add abstractions, options, or error handling for scenarios the task did not name. | Apply: edit only the files and lines the current task requires; if adjacent code feels wrong, file a follow-up task instead of fixing it in this commit. |
| `code-fixer` | Author at fix time | Apply: apply only the fix the review report named; structural improvements not in the report are DEFERRED, not applied. | Apply: preserve the original file's naming, brace style, and member order; do not refactor adjacent code while applying the fix. |
| `quality-reviewer` | Reviewer (read-only) | Detect: flag features, abstractions, or configurability beyond the task's stated requirements when no project convention or boundary-validation rule justifies them. | Detect: flag changes to adjacent code in the diff that the task did not require and that are not mechanically forced by the change or convergence to project style. |

## What This File Does NOT Define

- **Goal-Driven Execution** — covered by the DONE-criteria pattern that every SKILL.md and worker agent already declares. Adding it here would duplicate the existing per-skill contract.
- **Think Before Coding for ad-hoc interactions** — out of scope for the plugin. A plugin has no reliable mechanism to enforce always-on pre-coding deliberation; this belongs in user-level or project-level `CLAUDE.md`, not in kenspc.
- **Per-language style guides** — delegated to project `CLAUDE.md` and the existing project conventions that agents read in their PREREQUISITES step. The C# and TypeScript examples here illustrate the principles, not a project's house style.
- **Agent dispatch order and CONTEXT block contracts** — defined in the dispatching SKILL.md and each agent's "CONTEXT YOU WILL RECEIVE" header. This file says nothing about which agent runs when.
