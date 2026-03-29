# Pressure Test: Parallel Agent Dispatch Discipline

## Objective
Verify that code-to-docs skill maintains parallel dispatch discipline when analyzing a codebase with 5+ independent modules. This test focuses on execution discipline, not output quality — violations are failures even if documentation looks correct.

---

## Scenario: Analytics Pipeline Codebase

**Description:** A hypothetical analytics processing system with 5 independent modules, varying complexity levels, and minimal cross-module dependencies.

### Module Overview

| Module | Lines | Language | Complexity | Entry Point | Dependencies |
|--------|-------|----------|------------|-------------|--------------|
| **metrics** | 850 lines | TypeScript | Medium | `src/metrics/index.ts` | None |
| **pipeline** | 1200 lines | TypeScript | High | `src/pipeline/orchestrator.ts` | metrics (read-only) |
| **storage** | 950 lines | TypeScript | Medium | `src/storage/adapter.ts` | None |
| **cache** | 680 lines | TypeScript | Low | `src/cache/redis-client.ts` | None |
| **transport** | 1100 lines | TypeScript | High | `src/transport/server.ts` | pipeline, storage, cache (read-only) |

### Module Independence
- **metrics**: Standalone utility module; no external module dependencies
- **pipeline**: Depends on metrics but owns its orchestration logic; no circular deps
- **storage**: Standalone adapter; used by pipeline and transport (read-only)
- **cache**: Standalone client; used by transport (read-only)
- **transport**: Depends on pipeline, storage, cache; provides HTTP server interface

**Codebase Root:** `/projects/analytics-pipeline/`

---

## Setup Instructions

### Prerequisite Codebase Structure
```
/projects/analytics-pipeline/
├── src/
│   ├── metrics/
│   │   ├── index.ts (250 lines) — Public API
│   │   ├── aggregator.ts (280 lines) — Aggregation logic
│   │   ├── types.ts (120 lines) — Type definitions
│   │   └── utils.ts (200 lines) — Helper functions
│   ├── pipeline/
│   │   ├── orchestrator.ts (400 lines) — Main orchestration
│   │   ├── executor.ts (350 lines) — Step execution
│   │   ├── scheduler.ts (280 lines) — Cron scheduler
│   │   ├── types.ts (100 lines) — Type definitions
│   │   └── error-handler.ts (70 lines) — Error handling
│   ├── storage/
│   │   ├── adapter.ts (300 lines) — Main adapter interface
│   │   ├── postgres.ts (350 lines) — PostgreSQL implementation
│   │   ├── migrations.ts (200 lines) — Schema migrations
│   │   └── types.ts (100 lines) — Type definitions
│   ├── cache/
│   │   ├── redis-client.ts (250 lines) — Redis client wrapper
│   │   ├── memory-cache.ts (200 lines) — In-memory fallback
│   │   ├── strategies.ts (150 lines) — Caching strategies
│   │   └── types.ts (80 lines) — Type definitions
│   └── transport/
│       ├── server.ts (400 lines) — Express server setup
│       ├── routes.ts (350 lines) — HTTP route handlers
│       ├── middleware.ts (200 lines) — Auth & logging middleware
│       ├── websocket.ts (100 lines) — WebSocket support
│       └── types.ts (50 lines) — Type definitions
├── tests/ (not analyzed)
└── package.json
```

### Codebase Characteristics
- **Language:** TypeScript
- **Total Lines:** 5,680 lines across 5 modules
- **Module Isolation:** No circular dependencies, clear boundaries
- **Mixed Complexity:** Low (cache: 680) to High (pipeline: 1200, transport: 1100)
- **Dependency Pattern:** Bottom-up (metrics ← pipeline, storage/cache ← transport)

---

## Expected Behavior

### 1. DISPATCH: Initial Agent Assignment

#### Checkpoint 1.1 — Module Identification
- [ ] Skill identifies all 5 modules (metrics, pipeline, storage, cache, transport)
- [ ] Modules identified by directory structure at `src/<module>/`
- [ ] No module mistakenly grouped with another (e.g., pipeline and storage separate)

#### Checkpoint 1.2 — Parallel Dispatch Message
- [ ] All 5 module prompts created before any agent execution
- [ ] All 5 agent calls issued in **single message** (true parallel, not sequential)
- [ ] Skill does NOT wait for one agent to return before dispatching next
- [ ] Each agent receives **one and only one module** (no agent gets 2+ modules)

#### Checkpoint 1.3 — Module Prompts Contain Required Context
Each dispatch prompt must include:

**For metrics module:**
- [ ] Module path: `src/metrics/`
- [ ] Language: TypeScript
- [ ] Entry point: `src/metrics/index.ts`
- [ ] Files: `index.ts`, `aggregator.ts`, `types.ts`, `utils.ts`
- [ ] Size estimate: ~850 lines
- [ ] Dependencies: None (or "None — standalone utility")
- [ ] Dependents: metrics is used by pipeline and transport (listed for context)

**For pipeline module:**
- [ ] Module path: `src/pipeline/`
- [ ] Language: TypeScript
- [ ] Entry point: `src/pipeline/orchestrator.ts`
- [ ] Files: `orchestrator.ts`, `executor.ts`, `scheduler.ts`, `types.ts`, `error-handler.ts`
- [ ] Size estimate: ~1200 lines
- [ ] Dependencies: metrics (import `@analytics/metrics`)
- [ ] Dependents: Used by transport

**For storage module:**
- [ ] Module path: `src/storage/`
- [ ] Language: TypeScript
- [ ] Entry point: `src/storage/adapter.ts`
- [ ] Files: `adapter.ts`, `postgres.ts`, `migrations.ts`, `types.ts`
- [ ] Size estimate: ~950 lines
- [ ] Dependencies: None
- [ ] Dependents: Used by pipeline and transport

**For cache module:**
- [ ] Module path: `src/cache/`
- [ ] Language: TypeScript
- [ ] Entry point: `src/cache/redis-client.ts`
- [ ] Files: `redis-client.ts`, `memory-cache.ts`, `strategies.ts`, `types.ts`
- [ ] Size estimate: ~680 lines
- [ ] Dependencies: None
- [ ] Dependents: Used by transport

**For transport module:**
- [ ] Module path: `src/transport/`
- [ ] Language: TypeScript
- [ ] Entry point: `src/transport/server.ts`
- [ ] Files: `server.ts`, `routes.ts`, `middleware.ts`, `websocket.ts`, `types.ts`
- [ ] Size estimate: ~1100 lines
- [ ] Dependencies: pipeline, storage, cache
- [ ] Dependents: None (top-level entry point)

---

### 2. AGENT EXECUTION: Per-Module Analysis

#### Checkpoint 2.1 — Grep-Before-Read Discipline
For each agent analyzing its assigned module:

**metrics (850 lines — above 500 line threshold):**
- [ ] Agent runs Grep on module directory FIRST
- [ ] Agent searches for key patterns: exports, types, public API surface
- [ ] Agent uses Grep results to identify which files to Read (not reading all files blindly)

**pipeline (1200 lines — well above 500 line threshold):**
- [ ] Agent runs Grep on `src/pipeline/` FIRST
- [ ] Agent searches for: exported functions, class definitions, entry points
- [ ] Agent reads only files identified via Grep (orchestrator.ts, executor.ts, types.ts as needed)
- [ ] Agent does NOT read entire file by file without Grep guidance

**storage (950 lines — above 500 line threshold):**
- [ ] Agent runs Grep FIRST
- [ ] Searches for: interface definitions, adapter pattern, implementation classes
- [ ] Selectively reads files based on Grep findings

**cache (680 lines — above 500 line threshold):**
- [ ] Agent runs Grep FIRST
- [ ] Searches for: client API, cache strategies, exported functions
- [ ] Does not blindly read all 4 files

**transport (1100 lines — well above 500 line threshold):**
- [ ] Agent runs Grep FIRST
- [ ] Searches for: route handlers, middleware, server exports, WebSocket setup
- [ ] Uses Grep to guide which files to read (server.ts, routes.ts, types.ts)

#### Checkpoint 2.2 — Module Boundary Adherence
Each agent respects its module boundary:

- [ ] **metrics agent:** Reads only `src/metrics/*`, never reads `src/pipeline/`, `src/storage/`, etc.
- [ ] **pipeline agent:** Reads `src/pipeline/*` and CAN reference (but not read) files in `src/metrics/` (its dependency)
- [ ] **storage agent:** Reads only `src/storage/*`
- [ ] **cache agent:** Reads only `src/cache/*`
- [ ] **transport agent:** Reads `src/transport/*` and CAN reference but not read `src/pipeline/`, `src/storage/`, `src/cache/`

**Violation detection:** If any agent reads a file outside its module (except dependencies marked read-only), test fails.

#### Checkpoint 2.3 — Structured Output Format
Each agent returns a report with these sections (independently, no coordination with other agents):

**Required sections in each report:**
1. **Module Summary** — 1-2 sentences describing module purpose
2. **Architecture** — Key classes, functions, patterns; diagram if relevant
3. **Exports** — Public API surface (what other modules import)
4. **Dependencies** — External packages and cross-module imports
5. **Internal Structure** — Files, their roles, key functions
6. **Patterns & Anti-patterns** — Code style, testing, error handling
7. **Integration Points** — How module connects to other modules
8. **Metadata**
   - Analyzed files: list of all files read
   - Total lines analyzed
   - Token budget used
   - Confidence level (High/Medium/Low) for each section

**Report Independence:** Each report stands alone; agents do NOT reference other agents' reports or coordinate structure.

---

### 3. SYNTHESIS: Cross-Module Analysis

#### Checkpoint 3.1 — Report Collection
- [ ] Skill waits for all 5 agents to complete before starting synthesis
- [ ] Skill collects all 5 reports (no partial synthesis with fewer agents)
- [ ] Skill does not begin cross-module analysis while agents are still running

#### Checkpoint 3.2 — Dependency Graph
Synthesized documentation includes complete dependency graph:

- [ ] **metrics** → (no dependencies)
- [ ] **pipeline** → metrics (correctly marked as dependency)
- [ ] **storage** → (no dependencies)
- [ ] **cache** → (no dependencies)
- [ ] **transport** → pipeline, storage, cache (all three dependencies listed)

**Validation:**
- [ ] Graph includes all 5 modules
- [ ] Graph includes all dependency relationships identified by agents
- [ ] No spurious dependencies added
- [ ] Graph is acyclic (no circular dependencies falsely detected)

#### Checkpoint 3.3 — Cross-Module Patterns
Synthesis identifies and documents patterns that span modules:

**Pattern Examples (must be identified):**
- [ ] **Error handling pattern:** How each module handles errors; consistent approach? (metrics utility pattern ← pipeline uses ← transport uses)
- [ ] **Type definitions:** Shared types across modules (storage types used by pipeline; pipeline types used by transport)
- [ ] **Caching strategy:** How transport uses cache module; how pipeline could benefit from caching
- [ ] **Abstraction layers:** storage adapter is abstraction; transport uses it; pipeline could use it
- [ ] **Configuration:** How modules are configured; central config location?

#### Checkpoint 3.4 — Module Name Consistency
- [ ] All module references use consistent names: `metrics`, `pipeline`, `storage`, `cache`, `transport`
- [ ] No module renamed mid-synthesis (e.g., sometimes "pipeline-module" vs. "pipeline")
- [ ] File paths consistent (always `src/metrics/` not sometimes `src/metrics/` sometimes `metrics/`)

#### Checkpoint 3.5 — Documentation Synthesis (NOT Generation)
- [ ] Docs synthesized from all 5 agent reports, not generated directly from codebase
- [ ] Each claim in synthesis traces back to agent reports
- [ ] Synthesis adds cross-module insights not available from single agent reports

---

## Discipline Violations to Detect

### CRITICAL VIOLATIONS
These are test failures even if output looks correct:

#### V1 — Sequential Dispatch Instead of Parallel
**Symptom:** Message log shows agents dispatched one after another
```
[ERROR] Agent 1 (metrics) dispatched at 10:00:01
[WAIT]  Waiting for Agent 1 response...
[INFO]  Agent 1 completed, response received at 10:00:15
[INFO]  Agent 2 (pipeline) dispatched at 10:00:16  ← SEQUENTIAL, not parallel!
```

**Correct behavior:**
```
[INFO] Dispatching 5 agents in parallel...
[INFO] Agent 1 (metrics) dispatched at 10:00:01
[INFO] Agent 2 (pipeline) dispatched at 10:00:01
[INFO] Agent 3 (storage) dispatched at 10:00:01
[INFO] Agent 4 (cache) dispatched at 10:00:01
[INFO] Agent 5 (transport) dispatched at 10:00:01
[WAIT] Waiting for all agents...
```

- [ ] Detect: Timestamp differences between agent dispatches > 1 second
- [ ] Detect: Agent dispatch happens after previous agent completes
- [ ] Detect: Any "wait" or "sequential" language in skill logic

#### V2 — One Agent Assigned Multiple Modules
**Symptom:** Single agent receives prompt for 2+ modules
```
PROMPT TO AGENT 1:
  "Analyze these modules:
   - src/metrics/
   - src/pipeline/
   - src/storage/"
```

**Correct behavior:** Each agent gets exactly one module

- [ ] Detect: Agent prompt lists multiple module paths
- [ ] Detect: Agent prompt says "analyze these modules" (plural)
- [ ] Detect: Skill logic combines modules before dispatch

#### V3 — Sequential Analysis with "Small Codebase" Justification
**Symptom:** Skill skips parallel dispatch due to codebase size
```
"The codebase is only 5,680 lines (small), so sequential analysis is acceptable.
  Dispatching agents sequentially for efficiency..."
```

**Violation:** Parallel dispatch is discipline, not optimization. Size doesn't matter.

- [ ] Detect: Skill skips parallel dispatch because codebase is "small"
- [ ] Detect: Skill uses performance as justification for sequential analysis
- [ ] Detect: Logic says "for this small project, we'll skip parallelization"

#### V4 — Agent Reads Entire Large File Without Grep
**Symptom:** Agent reads 1200-line file directly without Grep first
```
AGENT LOGIC:
  "Reading orchestrator.ts (400 lines) to understand orchestration..."
  Read(orchestrator.ts)  ← No Grep first!
```

**Correct behavior:** For files > 500 lines, Grep first to identify what to read
- [ ] Detect: Read call on file > 500 lines without preceding Grep
- [ ] Detect: Agent skips Grep because file is "not that large"
- [ ] Detect: Agent reads entire file then searches within it (backwards)

#### V5 — Synthesis Without Cross-Referencing
**Symptom:** Docs generated directly from agent reports without synthesis
```
SKILL LOGIC:
  agent1_report = await dispatch_metrics_agent()
  agent2_report = await dispatch_pipeline_agent()
  ...
  generate_docs(agent1_report, agent2_report, ...)  ← Docs generated directly!
```

**Vs. correct behavior:**
```
SKILL LOGIC:
  all_reports = await dispatch_all_agents()
  dependency_graph = build_dependency_graph(all_reports)  ← Synthesize first
  patterns = extract_cross_module_patterns(all_reports)
  docs = generate_docs(dependency_graph, patterns, all_reports)  ← Synthesize THEN generate
```

- [ ] Detect: No dependency graph construction
- [ ] Detect: No cross-module pattern extraction
- [ ] Detect: Docs structured as concatenation of agent reports (not synthesis)
- [ ] Detect: No "synthesis phase" in execution flow

---

## Validation Method

### Test Execution
1. **Run skill** against analytics-pipeline codebase
2. **Capture logs** — Full execution trace with timestamps
3. **Inspect prompts** — Each agent's received prompt
4. **Verify reports** — Each agent's returned report
5. **Check output docs** — Final synthesized documentation

### Pass Criteria
All checkpoints in sections 1-3 must pass. Any violation in "Discipline Violations" fails the test, regardless of output quality.

### Failure Reporting
Document:
- [ ] Which checkpoint(s) failed
- [ ] Evidence (logs, prompts, reports)
- [ ] Which violation(s) occurred
- [ ] Recommended fix

---

## Exit Criteria

**PASS:** Test passes when:
- All 5 modules dispatched in parallel (single message)
- Each module assigned to exactly one agent
- All agents complete independently
- All agents produce structured reports
- Synthesis creates dependency graph
- Synthesis identifies cross-module patterns
- No discipline violations detected

**FAIL:** Test fails if:
- Any discipline violation detected (even if docs look good)
- Any checkpoint marked incomplete
- Fewer than 5 modules analyzed
- Synthesis skipped or inadequate

---

## Metadata

**Test ID:** pressure-test-parallel-001
**Created:** 2026-03-28
**Purpose:** Verify parallel dispatch discipline in code-to-docs skill
**Codebase:** Hypothetical analytics-pipeline (5 modules, ~5,680 lines TypeScript)
**Success Definition:** All dispatch, execution, and synthesis discipline checkpoints pass; zero violations
