# Example Plan Document

This file shows a typical output from the `generate-plan` skill. Use it as a reference
for the level of specificity and structure expected.

---

# Plan: Real-Time Notification System

## Objective

Add a real-time notification system to the existing web application so that users receive
instant updates (e.g., new messages, task assignments) without refreshing the page.

**In scope:** WebSocket-based push notifications, notification persistence, read/unread
state, browser notification permission.

**Out of scope:** Email notifications, SMS, mobile push notifications, notification
preferences UI (deferred to Phase 2).

## Background

Users currently discover updates only by refreshing the page or polling the API every
60 seconds. Support tickets indicate this causes missed task assignments and delayed
responses. The existing stack is Next.js 14 (App Router) + Express API + PostgreSQL.

## Technical Approach

Use **Socket.IO** (v4.x) for WebSocket communication. Socket.IO is chosen over raw
WebSockets because:
1. It handles reconnection and fallback to long-polling automatically.
2. The team already uses it in the internal admin dashboard.
3. It supports room-based broadcasting, which maps to per-user notification channels.

### Architecture

```
[Next.js Client] <--Socket.IO--> [Express API + Socket.IO Server]
                                         |
                                  [PostgreSQL: notifications table]
                                         |
                                  [Redis: pub/sub for multi-instance]
```

Redis pub/sub is required because the API runs behind a load balancer with 3 instances.
Without Redis, a notification emitted on instance A would not reach a user connected to
instance B.

## Implementation Steps

### Phase 1: Backend Infrastructure

**Step 1.1: Add notifications table**
- Create migration with columns: id (UUID), userId (FK), type (enum), title, body,
  metadata (JSONB), isRead (boolean, default false), createdAt, readAt
- Add index on (userId, isRead, createdAt DESC) for the unread notifications query
- Input: Prisma schema
- Output: Migration file applied to dev database
- Done when: `prisma migrate dev` succeeds, table visible in database

**Step 1.2: Integrate Socket.IO into Express server**
- Install `socket.io@4.8.x` and `@socket.io/redis-adapter@8.x`
- Create `src/sockets/index.ts` that initializes Socket.IO with Redis adapter
- Authenticate socket connections using the existing JWT middleware
- Join each authenticated user to a room named `user:<userId>`
- Input: Existing Express server in `src/server.ts`
- Output: Socket.IO server running on same port, authenticated connections working
- Done when: A test client can connect with a valid JWT and join its user room

**Step 1.3: Create notification service**
- Create `src/services/notification.service.ts` with methods:
  - `create(userId, type, title, body, metadata?)` — inserts to DB, emits to user room
  - `markAsRead(notificationId, userId)` — updates isRead and readAt
  - `getUnread(userId, limit=50)` — returns unread notifications ordered by createdAt DESC
- Input: Prisma client, Socket.IO server instance
- Output: Service class with all three methods tested
- Done when: Unit tests pass for all three methods

### Phase 2: API Endpoints

**Step 2.1: GET /api/notifications**
- Returns paginated list of notifications for the authenticated user
- Query params: `unreadOnly` (boolean), `cursor` (UUID for cursor-based pagination)
- Returns: `{ notifications: [...], nextCursor: string | null }`
- Done when: Returns correct results for unread-only and all-notifications queries

**Step 2.2: PATCH /api/notifications/:id/read**
- Marks a single notification as read
- Returns 204 on success, 404 if notification does not exist or belongs to another user
- Done when: Notification isRead is true and readAt is set after calling

**Step 2.3: POST /api/notifications/read-all**
- Marks all unread notifications as read for the authenticated user
- Returns `{ count: N }` with the number of notifications marked
- Done when: All previously unread notifications are now read

### Phase 3: Frontend Integration

**Step 3.1: Create Socket.IO client hook**
- Create `src/hooks/useSocket.ts` that connects to the Socket.IO server using the
  user's JWT from the auth context
- Handle reconnection, connection errors, and token refresh
- Done when: Hook connects successfully and logs received events in dev console

**Step 3.2: Create notification bell component**
- Create `src/components/NotificationBell.tsx`
- Shows unread count badge, dropdown with recent notifications, "mark all read" button
- Fetches initial state from GET /api/notifications, updates in real-time via socket
- Done when: Component renders, shows correct unread count, updates on new notification

## Testing Strategy

- Unit tests: notification service methods (create, markAsRead, getUnread)
- Integration tests: API endpoints with authenticated requests
- E2E test: connect socket client, trigger notification, verify it appears in real-time
- Load test: verify Socket.IO handles 500 concurrent connections without degradation

## Risks and Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Redis connection failure breaks notifications | Medium | Socket.IO falls back to in-memory adapter; add health check and alert |
| High notification volume overwhelms clients | Low | Implement server-side rate limiting (max 10 notifications per second per user) |
| JWT expiration during long socket session | High | Implement token refresh on socket `connect_error` event |

## Open Questions

1. Should notifications be automatically deleted after 90 days? (Need product input)
2. Should we batch database inserts for high-frequency events? (Measure first, optimize if needed)
