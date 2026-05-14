# Code-Craft Principles

Shared code-craft principles referenced by `task-implementer`, `code-fixer`, and `quality-reviewer`. Defines two write-time and review-time anchors — Simplicity First and Surgical Changes — with worked C# / TypeScript diff examples and a per-agent applicability table. Authoritative source for the principle paragraphs that the two writer agents inline byte-identical.

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

TODO

## How Each Agent Applies These

TODO

## What This File Does NOT Define

TODO
