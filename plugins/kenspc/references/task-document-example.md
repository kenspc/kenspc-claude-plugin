# Example Task Document

This file shows the expected format for task documents used with the `task-implement` skill.
Copy this template and adapt it to your project.

---

# User Authentication — Task Document

## Context

Implement user authentication for the API using JWT tokens. The API is built with
Express.js and uses PostgreSQL via Prisma ORM.

Related plan: `docs/plans/auth-plan.md`

Dependency note: Task 6 depends on Tasks 1–5 (`Depends on: Task 1-5`) and runs after them.

## Tasks

### Task 1: Create User model and migration

**Status:** DONE

**Implementation notes:**
- Decisions: named the column `passwordHash` (not `password`) to make the
  hashed-only storage intent explicit at the schema level.
- Changes/tradeoffs: none — implemented exactly as specified.

Add a `User` model to the Prisma schema with fields: id, email (unique), passwordHash,
createdAt, updatedAt. Run the migration.

**Acceptance criteria:**
- `prisma migrate dev` succeeds
- User table exists with correct columns and constraints

> The `**Implementation notes:**` block under Task 1's `**Status:**` line is
> written by `task-implement` at completion time (it captures the implementer's
> per-task rationale). You do not pre-write it when authoring a task document — a
> freshly authored task carries no notes block regardless of its status, as Task 2
> (IN PROGRESS) and Tasks 3–5 (TODO) below show. The block first appears once
> `task-implement` reaches that task and records a DONE or BLOCKED outcome.

---

### Task 2: Implement registration endpoint

**Status:** IN PROGRESS

Create `POST /api/auth/register` that accepts `{ email, password }`, hashes the password
with bcrypt, creates the user, and returns a JWT token.

**Acceptance criteria:**
- Returns 201 with `{ token }` on success
- Returns 409 if email already exists
- Returns 400 if email or password is missing
- Password is never stored in plaintext

---

### Task 3: Implement login endpoint

**Status:** TODO

Create `POST /api/auth/login` that accepts `{ email, password }`, verifies credentials,
and returns a JWT token.

**Acceptance criteria:**
- Returns 200 with `{ token }` on success
- Returns 401 if credentials are invalid
- Returns 400 if email or password is missing

---

### Task 4: Add auth middleware

**Status:** TODO

Create middleware that extracts the JWT from the `Authorization: Bearer <token>` header,
verifies it, and attaches the user to `req.user`. Protected routes should return 401
if the token is missing or invalid.

**Acceptance criteria:**
- Valid token: `req.user` is populated, request continues
- Missing/invalid token: returns 401 with `{ error: "Unauthorized" }`
- Middleware is reusable across routes

---

### Task 5: Write integration tests

**Status:** TODO

Write tests for registration, login, and protected route access using the project's
existing test setup (Jest + Supertest).

**Acceptance criteria:**
- All happy paths tested
- All error paths tested (duplicate email, wrong password, missing token)
- Tests run in isolation (database is reset between tests)

---

### Task 6: Doc-sync

**Status:** TODO

Depends on: Task 1-5

Bring the documents below in line with what Tasks 1-5 implemented, as recorded in their
`**Implementation notes:**` blocks, and promote their decisions.

**Documents** (the plan's Documentation impact; this task creates or modifies no other
file):
- `README.md` § Authentication — describe registration, login, and the
  `Authorization: Bearer <token>` header that protected routes expect (plan Steps 2.1–2.3).
- `docs/api.md` § Auth endpoints — add `POST /api/auth/register` and
  `POST /api/auth/login` with their request bodies, responses, and error codes (plan
  Steps 2.1–2.2).

**Promotion:** read the `Decisions` sub-bullets in the Implementation notes of Tasks 1-5.
Write each decision that a future reader would look for in one of the listed documents
into that document, in the document's own language and structure. List a decision that
belongs in a durable document but fits none of the listed ones under
`## Decisions needing a home` in the run report with a suggested destination, and write
it nowhere. Leave a decision that only explains a local code choice where it is. Create
or modify no document outside the list.

**Acceptance criteria:**
- Each listed document describes the behaviour Tasks 1-5 implemented, so that a reader of
  that document alone learns it
- Every promoted decision appears in the document named for it, in that document's
  language
- No file outside the listed documents was created or modified by this task (this task
  document's status update aside)

> Task 6 is what `generate-task` appends as the last task when the plan's Documentation
> impact is not N/A. Its promotion instruction is part of the task text, so a Doc-sync
> task written by hand from this example works the same way.

---

## Notes

- JWT secret is in `.env` as `JWT_SECRET`
- Password hashing rounds: 12 (per team convention)
- Token expiration: 7 days
