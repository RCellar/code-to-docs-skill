# Analysis Guide — Codebase Analysis and Parallel Dispatch Reference

This file is loaded during Phase 1 (Intake & Analysis) of the code-to-docs skill. It defines the survey procedure, module identification heuristics, parallel agent dispatch rules, and synthesis steps.

---

## Phase 1: Intake & Analysis

### Step 1: Codebase Survey

Before any deep reading, gather the lay of the land.

1. `ls` the root directory — identify top-level structure
2. `Glob("**/*.{ts,js,py,go,rs,java}")` (adapt extensions to the detected language) — get a file inventory
3. Read `README.md` if it exists — extract stated architecture, entry points, and dependencies
4. Read the primary manifest file (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`) — extract the dependency list and available scripts
5. Identify entry points: main files, index files, server startup files, CLI entry points

**Record the following before proceeding:**

| Field | Notes |
|---|---|
| Primary language(s) | e.g., TypeScript, Python |
| Build system / package manager | e.g., npm, poetry, cargo |
| Entry points | Paths to main/index/server/cli files |
| Top-level directory structure | List of top-level dirs and their apparent purpose |
| Approximate LOC | Rough count from Glob output |

---

### Step 2: Module Identification

A **module** is an independent subsystem that can be understood without reading another module's internals.

**Heuristics for identifying modules:**

- Top-level directories containing related source files (e.g., `src/auth/`, `src/payments/`)
- Packages or namespaces with a distinct, singular responsibility
- Services in a microservice architecture (each service is one module)
- Major class hierarchies with clear external boundaries
- Files grouped by feature rather than by technical layer

**For flat structures** (no obvious subdirectory grouping), identify modules by:

- Import clusters — files that import heavily from each other form a module
- Shared domain concepts — files that operate on the same data types or business entities
- Named prefixes or suffixes in filenames (e.g., all `*-service.ts` files may form one module)

**For each identified module, record:**

| Field | Content |
|---|---|
| Name | Title Case label (e.g., Auth, Payments, Worker Queue) |
| Root path | Relative path from repo root |
| Language | Primary language of this module |
| Entry points | Files that are the module's public surface (index, main, exports) |
| Suspected dependencies | Other modules or external packages this module calls |

---

### Phase 1 Dispatch Table

Every `Agent()` call in Phase 1 MUST set `model:` to match this table.

| Agent | Model | Input | Output | Condition |
|-------|-------|-------|--------|-----------|
| Extraction (×N) | **haiku** | module details + entry points | Sections 1-6 report | always, parallel if 3+ modules |
| Issue Analysis (×N) | **sonnet** | extraction report | Section 7 report | complexity Low/Medium, <1000 LOC, no concurrency |
| Issue Analysis (×N) | **opus** | extraction report | Section 7 report | complexity High, >1000 LOC, or concurrency/security |
| Synthesis | **orchestrator** | all module reports | dep graph + narrative | ≤4 modules, tree-shaped deps |
| Synthesis | **opus** | all module reports | dep graph + narrative | 5+ modules or cyclic deps |
| State file write | **haiku** | synthesis output | `_state/analysis.json` | always |

### Step 3: Parallel Agent Dispatch

**Rule: 3 or more independent modules MUST be analyzed in parallel.**

For 1–2 modules, analyze sequentially in the current session.

For 3+ modules, analysis is a two-pass process per module. Both passes dispatch in parallel across modules.

---

#### Pass 1: Extraction (Haiku agents)

Dispatch one **Haiku** agent per module. These agents extract structured facts from the code — no judgment about quality or issues.

**Haiku Agent Prompt Template:**

```
You are extracting structured information from a single module of a codebase. Your job is to read the code and report facts. Do not evaluate code quality or suggest improvements — only extract what is there.

Do not read files outside this module's root path unless they define types or interfaces this module directly imports.

## Module Details

- **Name:** [MODULE_NAME]
- **Root path:** [MODULE_ROOT_PATH]
- **Language:** [LANGUAGE]
- **Entry points:** [COMMA_SEPARATED_ENTRY_POINT_PATHS]
- **Known dependencies on other modules:** [LIST_OR_"none known"]

## Instructions

Work in this order:

1. List all files under the module root using Glob.
2. For any file larger than 500 lines, use Grep to locate the key symbols (exports, class names, function signatures, route definitions) before reading. Never read a file over 500 lines in full without grepping first.
3. Read entry point files in full.
4. Trace the primary execution flow from the entry point — follow the call chain through at most 3 levels of depth.
5. Identify repeated patterns (e.g., middleware chains, repository pattern, event emitter usage, decorators).
6. Map all imports that reference paths outside this module root — these are the module's external dependencies.
7. Assess complexity: estimate cyclomatic complexity by counting branching constructs in the core files; note any files with deeply nested logic or functions exceeding 100 lines.

## Required Output Format

Return exactly the following six sections. Do not add extra sections or omit any. Use the exact headings shown.

### Architecture
Describe the internal structure of this module. What is the top-level design pattern (MVC, service/repository, functional pipeline, actor model, etc.)? How are files organized within the module? Where does control flow enter and exit?

### Public API
List every symbol this module exports that is consumed by other modules: function signatures, class names with their public methods, exported types/interfaces, HTTP routes or event names if applicable. Format each entry as a code-fenced signature with a one-line description.

### Internal Patterns
Describe patterns used internally that are not visible from outside (e.g., caching strategies, retry logic, internal event bus, singleton instances, factory functions). Note any patterns that deviate from the surrounding codebase conventions.

### Dependencies
List all external dependencies in two groups:
1. **Other project modules** — module name and what is imported
2. **Third-party packages** — package name, version if determinable, and what it is used for

Do not list standard library imports.

### Complexity
Rate overall complexity: Low / Medium / High.
Provide a one-paragraph justification. Identify the single most complex file or function and explain why.

### Key Files
List the 3–7 files most important to understanding this module. For each, provide the path and a one-sentence description of its role.
```

---

#### Pass 2: Issue Analysis (Sonnet or Opus agents)

After Pass 1 completes, dispatch one agent per module to produce the Limitations & Improvements section. These agents receive the Haiku extraction report as input — they do NOT re-read the code files unless they need to verify a specific concern.

**Model selection for Pass 2:**

| Condition | Model |
|-----------|-------|
| Module complexity is **High** | Opus |
| Module exceeds **1000 LOC** | Opus |
| Module involves concurrency, shared mutable state, or security-sensitive logic | Opus |
| Module complexity is **Low** or **Medium** and none of the above apply | Sonnet |

The complexity rating comes from the Haiku agent's Complexity section. If the Haiku report flags concurrency, thread safety, or async/sync bridging in the Architecture or Internal Patterns sections, escalate to Opus regardless of complexity rating.

**Issue Analysis Agent Prompt Template:**

```
You are reviewing a module for limitations, bugs, risks, and improvement opportunities. You have already received a structured extraction report — use it as your primary source. Only read source files directly if you need to verify a specific concern.

## Module Details

- **Name:** [MODULE_NAME]
- **Root path:** [MODULE_ROOT_PATH]
- **Language:** [LANGUAGE]

## Extraction Report (from prior analysis)

[PASTE THE FULL HAIKU EXTRACTION REPORT HERE]

## Instructions

Based on the extraction report above:

1. Review the Architecture section for design constraints, missing abstraction boundaries, and scalability bottlenecks.
2. Review the Public API section for inconsistent interfaces, missing error types, or unclear contracts.
3. Review the Internal Patterns section for anti-patterns, deviations from conventions, or fragile implementations.
4. Review the Complexity section — if a specific file or function was flagged, read it directly (Grep first if >500 lines) to assess whether the complexity is warranted or indicates a problem.
5. If the extraction report mentions concurrency, async/sync bridging, shared state, or security-sensitive operations, read the relevant code sections to assess race conditions, deadlock potential, and data integrity risks.

Only read source files when verifying a specific concern identified from the report. Do not re-read the entire module.

## Required Output Format

Return exactly one section:

### Limitations & Improvements

For each issue, classify as one of:
- **Limitation** — architectural or design constraint that restricts what the module can do (e.g., single-threaded, no retry logic, hard-coded config, missing abstraction boundary)
- **Bug or Risk** — code that is incorrect, fragile, or likely to fail under specific conditions (e.g., unhandled exception path, race condition, missing null check)
- **Improvement Opportunity** — code that works but could be better (e.g., duplicated logic that should be extracted, overly complex function that should be split, missing error context, inconsistent naming)

For each item provide: the file path and line range, a description of the issue, the severity (low/medium/high), and a suggested fix or approach. Do not fabricate issues — only report what is evidently present in the code. If the module is well-written with no notable issues, state that explicitly.
```

---

### Step 4: Synthesis

After all Pass 1 and Pass 2 agents return (or after sequential analysis completes), combine their outputs into a unified report per module (sections 1-7), then synthesize across modules.

**Model selection for synthesis:**

| Condition | Approach |
|-----------|----------|
| ≤4 modules with tree-shaped dependencies (no cycles, no bidirectional) | Orchestrator performs synthesis directly (Sonnet-level) |
| 5+ modules | Dispatch an **Opus agent** for synthesis — it receives all module reports as input |
| Any number of modules with cycles or bidirectional dependencies | Dispatch an **Opus agent** — complex dependency reasoning needed |

**Synthesis steps:**

1. **Collect all reports** — verify all seven sections are present in each module's combined report (6 from Haiku + 1 from Sonnet/Opus); flag missing sections before proceeding.
2. **Build the cross-module dependency graph** — for each module, list what it depends on; identify cycles or bidirectional dependencies.
3. **Identify system-wide patterns** — patterns that appear in 3+ modules are architectural conventions worth documenting at the top level.
4. **Resolve naming consistency** — standardize module names across reports if agents used different labels for the same module.
5. **Determine architecture type** — classify the system as one of: monolith, microservices, modular monolith, plugin-based, or hybrid. Justify the classification.
6. **Generate the top-level architecture narrative** — a 3–5 paragraph description of the system that a new engineer could read to understand how the pieces fit together.
7. **Aggregate limitations and improvements** — collect all issues from agent reports, deduplicate, identify system-wide themes (e.g., "no error handling strategy across 4 modules"), and rank by severity. This feeds the Health/ directory in Phase 2.

**Write `_state/analysis.json`** — dispatch a **Haiku agent** for this mechanical data transform. Provide the synthesis output and let it assemble the JSON. Schema:

```json
{
  "modules": ["list of module names"],
  "dependency_graph": {
    "Module Name": ["Dependency Module A", "Dependency Module B"]
  },
  "files_analyzed": {
    "relative/path/to/file.ts": "sha256 hash"
  },
  "git_commit": "HEAD commit hash or null if not a git repo",
  "timestamp": "ISO 8601",
  "mode": "quick or full"
}
```

See `output-structure.md` for the full schema description and incremental contract details.

---

## Agent Output Schema

All seven sections are required per module. Sections 1-6 come from the Haiku extraction agent; section 7 comes from the Sonnet/Opus issue analysis agent. Combine into one report per module before synthesis.

| Section | Source | Model | Content |
|---|---|---|---|
| **Architecture** | Pass 1 | Haiku | Internal design pattern, file organization, control flow entry and exit points |
| **Public API** | Pass 1 | Haiku | All exported symbols consumed externally: function signatures, class public methods, exported types, HTTP routes or event names |
| **Internal Patterns** | Pass 1 | Haiku | Implementation patterns not visible from outside: caching, retry logic, internal buses, factories, singletons |
| **Dependencies** | Pass 1 | Haiku | Two groups: (1) other project modules with specific imports, (2) third-party packages with version and purpose |
| **Complexity** | Pass 1 | Haiku | Rating (Low/Medium/High) with one-paragraph justification and identification of the single most complex file or function |
| **Key Files** | Pass 1 | Haiku | 3–7 files most important to understanding the module, each with path and one-sentence role description |
| **Limitations & Improvements** | Pass 2 | Sonnet or Opus | Classified issues (limitation/bug-risk/improvement) with file path, severity, and suggested fix. "None identified" if the module is clean. |

---

## Exclusions

The following paths and file types are NEVER analyzed during Phase 1. Do not Glob into them, do not Read them, do not pass them to agents.

**Directories:**

- `node_modules/`
- `vendor/`
- `.git/`
- `__pycache__/`
- `dist/`
- `build/`
- `.next/`
- `target/`
- `.cache/`
- `.turbo/`
- `coverage/`
- `.nyc_output/`

**File types:**

- `*.min.js` — minified JavaScript
- `*.map` — source maps
- Lock files: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `Pipfile.lock`, `poetry.lock`, `Cargo.lock`, `go.sum`
- Binary files: `*.png`, `*.jpg`, `*.gif`, `*.svg`, `*.ico`, `*.woff`, `*.woff2`, `*.ttf`, `*.eot`, `*.pdf`, `*.zip`, `*.tar`, `*.gz`
- Test files: `*.test.ts`, `*.spec.ts`, `*.test.js`, `*.spec.js`, `*_test.go`, `test_*.py`, `*_test.py` — analysis focuses on production code; test files are used in a separate documentation phase

---

## Token Efficiency Rules

These rules apply to all agents and to the orchestrating session.

1. **Grep before Read** — never read a file larger than 500 lines without first using Grep to locate the specific symbols or sections needed. Reading a large file in full when only 20 lines are relevant wastes context and slows synthesis.

2. **One extraction agent per module** — do not spawn multiple Haiku agents for a single module. The issue analysis agent (Pass 2) is a separate, second agent for the same module — this is the intended two-pass design, not a violation.

3. **Suppress verbose output** — agents must not quote large blocks of source code in their reports. Reports describe and summarize; they include code-fenced signatures only in the Public API section, and only the signature line (not the full implementation).

4. **Skip dependency internals** — document only the project's own code. Do not trace into `node_modules`, `vendor`, or any third-party package source. External packages are recorded by name, version, and purpose only.

5. **Use the cheapest sufficient model** — Haiku for extraction and mechanical tasks, Sonnet for writing and standard issue analysis, Opus only when escalation conditions are met (see Step 3 and Step 4 model selection tables). Do not use Opus "just to be safe" — it costs 10-15x more than Haiku per token.

6. **Pass 2 agents receive reports, not code** — issue analysis agents should work primarily from the Haiku extraction report. Only read source files to verify a specific concern. This avoids re-reading the entire module at a higher-cost model tier.

7. **Parallel generation in Phase 2** — module docs, mechanical files (Canvas, Index, Dependency Map, state file), and health reports are independent outputs. Dispatch them in parallel to keep each agent's context small and focused.

8. **Update mode: only re-analyze changed modules** — unchanged modules keep their existing reports. Do not re-run analysis on a module just because it was loaded into context. The `git diff` output is the sole source of truth for what changed.

---

## Incremental Update Flow

This section applies only when `--update` is passed. For baseline generation (no `--update`), follow Steps 1-4 above.

### Update Step 1: Load and Validate Previous State

1. Read `_state/analysis.json` from the existing vault at `--output` path
2. If the file does not exist, abort update and fall back to a full generate run. Inform the user: "No previous state found — running full generation instead."
3. Validate the state file against the schema in `output-structure.md` "State File Validation" section. If required fields are missing or have wrong types, report the validation error and fall back to a full generate run.
4. Extract: `git_commit` (the commit hash from the last run), `modules` (module list), `dependency_graph`, `files_analyzed`, `issues`

### Update Step 2: Diff

1. Run `git diff <stored_git_commit>..HEAD --name-only` in the codebase root
2. Filter out excluded paths (see Exclusions section)
3. The result is the list of **changed files** since the last documentation run

If the diff is empty (no changes since last run), report "No changes since last documentation run" and exit without modifying the vault.

### Update Step 3: Map Changes to Modules

For each changed file, look it up in the `files_analyzed` map to determine which module it belongs to.

Classify the changes:

| Category | Detection | Implication |
|----------|-----------|-------------|
| **Modified within existing module** | Changed file found in `files_analyzed` for a known module | Re-analyze that module |
| **New file in existing module directory** | File path falls within a known module's root path but is not in `files_analyzed` | Re-analyze that module |
| **New file outside all modules** | File path is not in any known module's root path | Potential new module — triggers full mode |
| **Deleted file** | File in `files_analyzed` no longer exists on disk | Re-analyze the owning module |
| **New top-level directory with source files** | New directory at project root containing code files | New module — triggers full mode |

Build the list of **affected modules** — modules that need re-analysis.

### Update Step 4: Auto-Select Mode

| Condition | Mode |
|-----------|------|
| All changes within existing modules, no new modules, no deleted modules | **Quick** |
| New module detected (new directory with source files outside existing module roots) | **Full** |
| Module deleted (all files in a module removed) | **Full** |
| Dependency structure changed (new cross-module imports detected in diff) | **Full** |
| >50% of tracked files in `files_analyzed` changed | **Full** |

Report the auto-selected mode to the user: "Update mode: quick (2 of 8 modules affected)" or "Update mode: full (new module detected: Scheduler)".

### Update Step 5: Re-Analyze Affected Modules

For each affected module, run the same two-pass analysis as baseline:

1. **Haiku extraction** (sections 1-6) — same agent prompt template as Step 3 Pass 1
2. **Sonnet/Opus issue analysis** (section 7) — same agent prompt template as Step 3 Pass 2, same model escalation rules

For **unchanged modules**, carry forward their existing reports from the previous run. Do not re-analyze.

If auto-selected mode is **full**, also run Step 2 (Module Identification) to detect any new modules, then analyze those as well.

### Update Step 6: Merge Synthesis

Combine new analysis reports (affected modules) with carried-forward reports (unchanged modules) into a single synthesis.

Run the same synthesis procedure as Step 4, but with awareness of what changed:

1. Rebuild dependency graph from all module reports (new + carried forward)
2. Compare new dependency graph to previous — flag any structural changes
3. Regenerate architecture narrative (always — even small changes can shift the system story)
4. Merge issues:
   - Issues in re-analyzed modules: replace with new analysis results
   - Issues in unchanged modules: carry forward with status `open`
   - Issues from previous run that no longer appear in re-analyzed modules: mark as `resolved`

### Update Step 7: Selective Generation

Use the same Phase 2 generation flow, but selectively:

| Output | When to regenerate |
|--------|-------------------|
| `Architecture/System Overview.md` | Always (cross-module, cheap to regenerate) |
| `Architecture/Dependency Map.md` | Always |
| `Architecture/System Map.canvas` | Always |
| `Modules/{Name}.md` for affected modules | Always |
| `Modules/{Name}.md` for unchanged modules | **Never** — preserve existing |
| `Health/` (all files) | Always (depends on merged issues) |
| `Patterns/` (full mode) | Only if auto-selected full |
| `Onboarding/` (full mode) | Only if auto-selected full |
| `Cross-Cutting/` (full mode) | Only if auto-selected full |
| `Index.md` | Always (cheap, ensures consistency) |
| `_state/analysis.json` | Always (must reflect new state) |

### Update Step 8: Update State File

Write `_state/analysis.json` with:
- `git_commit` → current HEAD
- `timestamp` → now
- `mode` → the auto-selected mode
- `modules` → merged module list (may include new modules in full mode)
- `files_analyzed` → merged map (updated entries for re-analyzed modules, carried forward for unchanged)
- `issues` → merged array with status updates
- `sessions` → append new session entry (see `output-structure.md` for schema)

### Update Step 9: Verify

Same as Phase 3 — Haiku agent checks wikilinks and frontmatter across the entire vault (not just changed files).
