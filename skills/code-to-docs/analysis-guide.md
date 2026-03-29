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

### Step 3: Parallel Agent Dispatch

**Rule: 3 or more independent modules MUST be analyzed in parallel.**

For 1–2 modules, analyze sequentially in the current session.

For 3+ modules, spawn one Agent per module. Use the following prompt template verbatim, substituting the bracketed placeholders for each module.

---

#### Agent Prompt Template

```
You are analyzing a single module of a larger codebase. Your job is to produce a structured analysis report. Do not read files outside this module's root path unless they define types or interfaces this module directly imports.

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

### Step 4: Synthesis

After all agents return (or after sequential analysis completes):

1. **Collect all reports** — verify all six sections are present in each report; flag missing sections before proceeding.
2. **Build the cross-module dependency graph** — for each module, list what it depends on; identify cycles or bidirectional dependencies.
3. **Identify system-wide patterns** — patterns that appear in 3+ modules are architectural conventions worth documenting at the top level.
4. **Resolve naming consistency** — standardize module names across reports if agents used different labels for the same module.
5. **Determine architecture type** — classify the system as one of: monolith, microservices, modular monolith, plugin-based, or hybrid. Justify the classification.
6. **Generate the top-level architecture narrative** — a 3–5 paragraph description of the system that a new engineer could read to understand how the pieces fit together.

**Write synthesis output to `_state/analysis.json`** with the following top-level keys:

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

All six sections are required. An agent report missing any section must be re-requested before synthesis begins.

| Section | Required | Content |
|---|---|---|
| **Architecture** | Yes | Internal design pattern, file organization, control flow entry and exit points |
| **Public API** | Yes | All exported symbols consumed externally: function signatures, class public methods, exported types, HTTP routes or event names |
| **Internal Patterns** | Yes | Implementation patterns not visible from outside: caching, retry logic, internal buses, factories, singletons |
| **Dependencies** | Yes | Two groups: (1) other project modules with specific imports, (2) third-party packages with version and purpose |
| **Complexity** | Yes | Rating (Low/Medium/High) with one-paragraph justification and identification of the single most complex file or function |
| **Key Files** | Yes | 3–7 files most important to understanding the module, each with path and one-sentence role description |

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

2. **One agent per module** — do not spawn multiple agents for a single module, and do not merge two modules into one agent. Each module gets exactly one agent with exactly one analysis report.

3. **Suppress verbose output** — agents must not quote large blocks of source code in their reports. Reports describe and summarize; they include code-fenced signatures only in the Public API section, and only the signature line (not the full implementation).

4. **Skip dependency internals** — document only the project's own code. Do not trace into `node_modules`, `vendor`, or any third-party package source. External packages are recorded by name, version, and purpose only.
