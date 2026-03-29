---
title: Limitations
type: health
language:
  - "typescript"
  - "go"
  - "javascript"
status: generated
complexity: medium
dependencies: []
related-notes:
  - "[[Health Summary]]"
  - "[[Code Review]]"
canonical-source: src/lib/server
generated-by: code-to-docs
generated-at: 2026-03-29T12:00:00Z
mode: full
tags:
  - code-docs
  - health
---

# Limitations

Architectural and design constraints that restrict what Dockhand can do. These are not bugs — they are intentional or emergent design trade-offs.

---

### No Database Transaction Usage

**Module:** [[Database]]
**Severity:** high
**File:** `src/lib/server/db.ts:1-4681`

The entire 4,681-line operations file contains zero database transactions. Multi-step mutations like `deleteEnvironment` (4 sequential deletes), `setDefaultRegistry` (clear all then set one), and credential updates are not atomic. A process crash or query failure mid-way leaves the database in an inconsistent state.

> [!warning] Impact
> A crash during `deleteEnvironment` could delete child records while the parent row persists, creating orphaned data. A crash during `setDefaultRegistry` could leave zero registries as default.

> [!tip] Possible Approach
> Wrap multi-step mutations in `db.transaction()`. At minimum, apply transactions to `deleteEnvironment`, `setDefaultRegistry`, and bulk upsert operations.

---

### Monolithic Docker Client (5,264 Lines)

**Module:** [[Docker Engine]]
**Severity:** medium
**File:** `src/lib/server/docker.ts`

The entire Docker client — connection layer, transport abstraction, caching, 100+ API functions — lives in a single file. The transport layer is interleaved with business logic.

> [!warning] Impact
> Difficult to navigate, test in isolation, and maintain. Bug fixes to the transport layer risk accidentally affecting API functions.

> [!tip] Possible Approach
> Split into logical modules: transport layer (socket/https/edge), config/cache management, and domain-specific API modules (containers, images, volumes, networks).

---

### Monolithic Database Operations (4,681 Lines)

**Module:** [[Database]]
**Severity:** medium
**File:** `src/lib/server/db.ts`

All 250+ exported functions cover 15+ domains in a single file with no domain separation.

> [!warning] Impact
> 112 occurrences of the `!== undefined` partial-update boilerplate pattern indicate massive repetition. New functions must be added to an already unwieldy file.

> [!tip] Possible Approach
> Split into domain-specific modules (e.g., `db/environments.ts`, `db/auth.ts`, `db/git.ts`). Re-export from a barrel `db/index.ts`.

---

### Dual Schema Files with No Drift Detection

**Module:** [[Database]]
**Severity:** medium
**Files:** `src/lib/server/db/schema/index.ts` (569 lines), `src/lib/server/db/schema/pg-schema.ts` (484 lines)

SQLite and PostgreSQL schemas are maintained as separate files that must be kept manually in sync. No CI check or automated comparison exists.

> [!warning] Impact
> A column addition or constraint change applied to one schema but not the other creates silent data model divergence between deployment modes.

> [!tip] Possible Approach
> Add an automated test that compares the two schemas structurally, or generate one from the other.

---

### In-Memory Rate Limiting Lost on Restart

**Module:** [[Auth and Security]]
**Severity:** medium
**File:** `src/lib/server/auth.ts:1041-1126`

Rate limit state is a plain `Map` in process memory. Any restart clears all state, resetting brute-force attempt counters.

> [!warning] Impact
> An attacker can reset their attempt counter by waiting for or triggering a server restart. In multi-instance deployments, rate limiting is per-process and largely ineffective.

> [!tip] Possible Approach
> Persist rate limit entries in the database with `identifier`, `attempts`, `last_attempt`, `locked_until` columns.

---

### SSH Host Key Verification Disabled

**Module:** [[Stacks and Git]]
**Severity:** medium
**File:** `src/lib/server/git.ts:190-193`

All git-over-SSH operations use `-o StrictHostKeyChecking=no`, which silently accepts any server host key, making all operations vulnerable to MITM attacks.

> [!warning] Impact
> An attacker who can intercept traffic between Dockhand and a git remote could serve a malicious repository, leading to deployment of arbitrary containers.

> [!tip] Possible Approach
> Allow users to supply known host keys per credential/repository. Default to `StrictHostKeyChecking=accept-new` to pin the key after first contact.

---

### Connection Replacement Rejects All In-Flight Requests

**Module:** [[Hawser Edge]]
**Severity:** medium
**File:** `src/lib/server/hawser.ts:423-458`

When a new agent connects for an environment with an active connection, all pending requests on the old connection are immediately rejected with no grace period or re-queuing.

> [!warning] Impact
> Users whose requests are in progress see failures during routine agent upgrades or network reconnections.

> [!tip] Possible Approach
> Consider a brief drain period (2-5 seconds) before terminating the old connection, allowing in-flight responses to arrive.

---

### No Concurrent Execution Guard for Most Scheduler Tasks

**Module:** [[Scheduler]]
**Severity:** high
**File:** `src/lib/server/scheduler/tasks/`

Only `env-update-check` has a concurrency guard (`Set<number>`). Container-update, git-stack-sync, and image-prune have none. A manual trigger during a cron run executes both simultaneously.

> [!warning] Impact
> Concurrent container recreation for the same container is a destructive race that could leave containers in a broken state.

> [!tip] Possible Approach
> Add a `Set<string>` concurrency guard keyed on `${type}-${id}` to each task type, following the existing pattern in `env-update-check`.

---

### Notifications Block Caller with Serial Delivery

**Module:** [[Infrastructure Services]]
**Severity:** medium
**File:** `src/lib/server/notifications.ts:487-507`

Notification channels are delivered sequentially with `for...of` + `await`. With 5 channels and a slow SMTP server, total delivery time is up to 50 seconds, blocking the caller.

> [!warning] Impact
> Disk usage processing and other event handlers block while waiting for notification delivery.

> [!tip] Possible Approach
> Use `Promise.allSettled` for concurrent delivery, reducing time to the slowest single channel.

---

### SSE Reconnection Permanently Stops After 5 Failures

**Module:** [[Frontend]]
**Severity:** medium
**File:** `src/lib/stores/events.ts:142-152`

After 5 consecutive failures (15 seconds total), the SSE client permanently stops. No exponential backoff, no visibility-change recovery, no auth expiry detection.

> [!warning] Impact
> A brief server restart (>15s) leaves all connected browsers without real-time updates until manual page refresh.

> [!tip] Possible Approach
> Implement exponential backoff with unlimited retries and listen for `document.visibilitychange` to trigger reconnection when the tab becomes active.

---

### Authorization Boilerplate Duplication

**Module:** [[Frontend]]
**Severity:** medium
**Files:** 145+ files in `src/routes/api/`

Every API endpoint independently implements 8-15 lines of authorization boilerplate. Only ~18% check `canAccessEnvironment()` for enterprise RBAC scoping.

> [!warning] Impact
> Inconsistent authorization patterns create a risk of missed environment-level access checks. Two different guard patterns exist, increasing copy-paste error risk.

> [!tip] Possible Approach
> Create a shared `requireAuth(cookies, resource, action, envId)` function that performs all checks (permission + environment access) uniformly.
