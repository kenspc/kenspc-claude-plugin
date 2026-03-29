# Example Task Document

This file shows the expected format for task documents used with the `task-implement` skill.
Copy this template and adapt it to your project.

---

# User Authentication — Task Document

## Context

Implement user authentication for the API using JWT tokens. The API is built with
Express.js and uses PostgreSQL via Prisma ORM.

Related plan: `docs/plans/auth-plan.md`

## Tasks

### Task 1: Create User model and migration

**Status:** DONE

Add a `User` model to the Prisma schema with fields: id, email (unique), passwordHash,
createdAt, updatedAt. Run the migration.

**Acceptance criteria:**
- `prisma migrate dev` succeeds
- User table exists with correct columns and constraints

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

## Notes

- JWT secret is in `.env` as `JWT_SECRET`
- Password hashing rounds: 12 (per team convention)
- Token expiration: 7 days
