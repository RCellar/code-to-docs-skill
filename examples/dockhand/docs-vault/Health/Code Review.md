---
title: Code Review
type: health
language:
  - "typescript"
  - "go"
  - "javascript"
status: generated
complexity: high
dependencies: []
related-notes:
  - "[[Health Summary]]"
  - "[[Limitations]]"
canonical-source: src/lib/server
generated-by: code-to-docs
generated-at: 2026-03-29T12:00:00Z
mode: full
tags:
  - code-docs
  - health
---

# Code Review

Bugs, risks, and improvement opportunities identified through automated analysis. Items are ordered by severity within each section.

---

## High Severity

### OIDC ID Token JWT Signature Not Verified

**Module:** [[Auth and Security]]
**Type:** bug-risk
**Severity:** high
**File:** `src/lib/server/auth.ts:1328-1340`

The `handleOidcCallback` function decodes the ID token by simply base64-decoding the payload. It does not fetch the provider's JWKS and verify the JWT signature. A comment in the code reads: "basic validation - in production use a JWT library."

> [!danger] Why This Matters
> An attacker who can intercept or manipulate the token response (DNS hijacking, SSRF, compromised network path) could forge an ID token with arbitrary claims, including admin role claims. Combined with conditional nonce validation (issue below), this is the highest-priority security finding.

> [!example] Current Code
> ```typescript
> const idTokenParts = tokens.id_token.split('.');
> const claims = JSON.parse(Buffer.from(idTokenParts[1], 'base64url').toString());
> // No signature verification against JWKS
> ```

> [!tip] Suggested Improvement
> ```typescript
> import * as jose from 'jose';
> const JWKS = jose.createRemoteJWKSet(new URL(discovery.jwks_uri));
> const { payload } = await jose.jwtVerify(tokens.id_token, JWKS, {
>   issuer: discovery.issuer,
>   audience: config.clientId,
> });
> ```
> The `jose` library handles signature verification, issuer/audience validation, and expiry checking in one call.

---

### Encryption Key Rotation Not Atomic

**Module:** [[Auth and Security]]
**Type:** bug-risk
**Severity:** high
**File:** `src/lib/server/encryption.ts:323-465`

`migrateCredentials()` switches the cached key before re-encrypting rows, with no database transaction. A crash mid-loop leaves mixed encryption state.

> [!danger] Why This Matters
> Some credentials will be encrypted with the old key and others with the new key. There is no way to determine which is which, and no automatic recovery path.

> [!tip] Suggested Improvement
> Wrap the re-encryption loop in a database transaction. Store the old key in a `.encryption_key.old` file so incomplete migrations can resume. Only delete the old key file after the transaction commits.

---

### Scanner Lock Race Condition

**Module:** [[Infrastructure Services]]
**Type:** bug-risk
**Severity:** high
**File:** `src/lib/server/scanner.ts:83-102`

The promise-chaining lock has a race: concurrent callers both read the same `existing` promise, both set their own lock, and the second overwrites the first's entry. This allows scans B and C to run concurrently, defeating the serial lock.

> [!danger] Why This Matters
> Concurrent vulnerability scans can conflict on Docker volumes, database caches, and scanner binary state, producing corrupted or incomplete results.

> [!tip] Suggested Improvement
> ```typescript
> // Replace promise-chaining with proper async mutex
> import { Mutex } from 'async-mutex';
> const scannerMutexes = new Map<string, Mutex>();
> function getScannerMutex(type: string) {
>   if (!scannerMutexes.has(type)) scannerMutexes.set(type, new Mutex());
>   return scannerMutexes.get(type)!;
> }
> async function withScannerLock<T>(type: string, fn: () => Promise<T>): Promise<T> {
>   return getScannerMutex(type).runExclusive(fn);
> }
> ```

---

### Host-Path Detection Failure Silently Produces Wrong Volume Mounts

**Module:** [[Infrastructure Services]]
**Type:** bug-risk
**Severity:** high
**File:** `src/lib/server/host-path.ts:238-253`

If Docker mount detection fails at startup, `cachedMounts` remains null. `translateToHostPath` returns the container path unchanged. Compose volume paths silently use container-internal paths, causing Docker to create empty directories instead of bind-mounting expected files.

> [!danger] Why This Matters
> Stacks deployed with path translation enabled will appear to deploy successfully but have empty or missing data directories. No error is shown to the user.

> [!tip] Suggested Improvement
> When `detectHostDataDir` fails, log a prominent startup warning. In compose operations that depend on path translation, return an error rather than silently proceeding with untranslated paths.

---

### Encryption Scattered Across 40+ Call Sites

**Module:** [[Database]]
**Type:** bug-risk
**Severity:** high
**File:** `src/lib/server/db.ts` (40+ locations)

`encrypt()`/`decrypt()` is manually applied at each individual call site. Every get function must remember to decrypt, every create/update must encrypt. No centralized mapping of sensitive fields exists.

> [!danger] Why This Matters
> A new developer adding a query for environments could forget to decrypt `tlsKey` or `hawserToken`, silently returning encrypted ciphertext to the caller.

> [!tip] Suggested Improvement
> ```typescript
> // Create per-entity wrapper functions
> function decryptEnvironment(row: typeof environments.$inferSelect) {
>   return {
>     ...row,
>     tlsCa: row.tlsCa ? decrypt(row.tlsCa) : null,
>     tlsCert: row.tlsCert ? decrypt(row.tlsCert) : null,
>     tlsKey: row.tlsKey ? decrypt(row.tlsKey) : null,
>     hawserToken: row.hawserToken ? decrypt(row.hawserToken) : null,
>   };
> }
> ```
> Apply once per entity type, eliminating per-query encryption logic.

---

## Medium Severity

### UTF-8 Corruption in Docker Stream Demuxing

**Module:** [[Docker Engine]]
**Type:** bug-risk
**Severity:** medium
**File:** `src/lib/server/docker.ts:196-230`

`demuxDockerStream` decodes each Docker stream frame to UTF-8 individually. Multi-byte UTF-8 characters spanning frame boundaries are corrupted. The sister function `processStreamFrames` was fixed to concatenate buffers first, but `demuxDockerStream` was never updated.

> [!danger] Why This Matters
> Container logs or exec output containing non-ASCII characters (UTF-8 multi-byte) will display corruption at frame boundaries.

> [!tip] Suggested Improvement
> Collect raw `Buffer` slices, then `Buffer.concat()` before calling `.toString('utf-8')`, matching the approach in `processStreamFrames`.

---

### Backup Codes Use Math.random()

**Module:** [[Auth and Security]]
**Type:** bug-risk
**Severity:** medium
**File:** `src/lib/server/auth.ts:850-861`

MFA backup code generation uses `Math.random()` instead of a CSPRNG. The rest of the codebase correctly uses `secureRandomBytes` for security-sensitive randomness.

> [!danger] Why This Matters
> `Math.random()` output is predictable if the internal state is known or partially observed. For MFA backup codes serving as emergency authentication credentials, this reduces effective entropy.

> [!tip] Suggested Improvement
> ```typescript
> import { randomInt } from 'node:crypto';
> const char = chars[randomInt(chars.length)];
> ```

---

### Data Race on Go Collector Environment Fields

**Module:** [[Go Collector]]
**Type:** bug-risk
**Severity:** medium
**File:** `collector/main.go:362-368, 561-576`

The `online` and `statusReported` fields are read and written by multiple goroutines without synchronization. This is a textbook data race and will be flagged by `go test -race`.

> [!tip] Suggested Improvement
> Use `atomic.Bool` for `online` and `statusReported`, or protect them with a per-environment mutex.

---

### pollEvents 30-Second Lookback Window Misses Events

**Module:** [[Go Collector]]
**Type:** bug-risk
**Severity:** medium
**File:** `collector/main.go:671-672`

`pollEvents` uses a hardcoded 30-second lookback regardless of the poll interval (default 60s). With the default config, events between 60s and 30s ago are silently dropped.

> [!danger] Why This Matters
> With default configuration, half of all Docker events are silently lost in poll mode.

> [!tip] Suggested Improvement
> Track the timestamp of the last successful poll and use it as `since`, or derive the lookback from the poll interval.

---

### Subprocess Manager lineBuffer Not Reset on Restart

**Module:** [[Infrastructure Services]]
**Type:** bug-risk
**Severity:** medium
**File:** `src/lib/server/subprocess-manager.ts:82-83, 572-585`

When the Go worker crashes and restarts, `lineBuffer` is not cleared. The leftover bytes from the previous process's last incomplete line are prepended to the new process's first output, producing corrupt JSON.

> [!tip] Suggested Improvement
> Reset `lineBuffer = Buffer.alloc(0)` in the `proc.on('exit')` handler before the restart timer fires.

---

### Inconsistent Environment Access Checks Across API Endpoints

**Module:** [[Frontend]]
**Type:** bug-risk
**Severity:** medium
**Files:** 145+ files in `src/routes/api/`

Only ~26 out of 145+ endpoint files include `canAccessEnvironment()` checks. Enterprise RBAC environment scoping may be bypassed on the majority of endpoints.

> [!danger] Why This Matters
> A user with Viewer access in Environment A but no access to Environment B could potentially query Environment B's containers through endpoints that skip the environment access check.

> [!tip] Suggested Improvement
> Create a shared `requireAuth(cookies, resource, action, envId)` utility that performs both permission and environment-access checks uniformly.

---

### parseInt on Environment IDs Never Validated for NaN

**Module:** [[Frontend]]
**Type:** bug-risk
**Severity:** medium
**Files:** Widespread across `src/routes/api/`

`parseInt(envId)` returns `NaN` for non-numeric strings. `NaN` is truthy and gets passed to Docker operations, database queries, and authorization checks. `NaN !== NaN` comparisons fail in unexpected ways.

> [!tip] Suggested Improvement
> ```typescript
> function parseEnvId(value: string | null): number | undefined {
>   if (!value) return undefined;
>   const n = parseInt(value, 10);
>   return Number.isNaN(n) ? undefined : n;
> }
> ```

---

### Log Append Race Condition in Scheduler

**Module:** [[Scheduler]]
**Type:** bug-risk
**Severity:** medium
**File:** `src/lib/server/scheduler/tasks/container-update.ts:317-319`

The `log()` helper calls `appendScheduleExecutionLog` without `await`. Concurrent appends read the same `logs` value, each append their line, and the second write overwrites the first, losing a log line.

> [!tip] Suggested Improvement
> Make the `log` function async and await each call (matching `env-update-check.ts`), or replace the read-modify-write with SQL concatenation: `SET logs = COALESCE(logs, '') || '\n' || ?`.

---

### SSH Private Keys Written to Predictable /tmp Paths

**Module:** [[Stacks and Git]]
**Type:** bug-risk
**Severity:** medium
**File:** `src/lib/server/git.ts:159-209`

Keys are written to `/tmp/.ssh-key-${credential.id}` — predictable, sequential filenames. Keys are not zeroed before deletion. No process-exit cleanup handler exists for SSH keys (unlike TLS dirs in `stacks.ts`).

> [!tip] Suggested Improvement
> Use `mkdtemp` for random directory names. Overwrite key files with zeros before unlinking. Add a process-exit cleanup handler.

---

### No Backpressure on Terminal WebSocket Relay

**Module:** [[Production Server]]
**Type:** bug-risk
**Severity:** medium
**File:** `server.js:220-242`

Docker stream data is pushed directly to `ws.send()` with no check on WebSocket buffer state. Under heavy terminal output, the WebSocket buffer grows unboundedly.

> [!tip] Suggested Improvement
> Check `ws.bufferedAmount` before sending. Pause the Docker stream when the buffer exceeds a threshold and resume on `drain`.

---

### Chunked Transfer Encoding Parsing Is Fragile

**Module:** [[Production Server]]
**Type:** bug-risk
**Severity:** medium
**File:** `server.js:236-238`

The regex-based chunk parsing operates on UTF-8 strings rather than binary buffers. Split TCP segments, multi-byte characters at chunk boundaries, and multi-chunk buffers are all handled incorrectly.

> [!tip] Suggested Improvement
> Accumulate raw `Buffer` chunks in a state machine. Parse chunk sizes from binary, extract payload bytes by offset arithmetic, and decode to UTF-8 only at the final send step.
