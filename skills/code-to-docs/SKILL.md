---
name: code-to-docs
description: Use when generating documentation from a codebase, loading existing project docs for context at session start, updating docs after coding, creating architecture docs, building an Obsidian vault from code, or when someone asks to document or explain a project's structure
---

## Overview

Analyze a codebase and produce an Obsidian-native documentation vault containing architecture diagrams, API references, and teaching-focused explanations written at three audience levels: beginner (language constructs explained), intermediate (patterns and integration), and advanced (failure modes, concurrency, edge cases). Output is ready to open directly in Obsidian with working wikilinks, Mermaid diagrams, and Dataview queries.

Supports a full development lifecycle: **digest** existing docs at session start → code → **update** docs at session end.

## Invocation

```
Skill(skill: "code-to-docs", args: "<path> [--mode quick|full] [--output <path>]")
Skill(skill: "code-to-docs", args: "<path> --update [--output <path>]")
Skill(skill: "code-to-docs", args: "--digest <vault-path> [--scope <module,...>] [--focus issues|architecture|all]")
```

- `<path>` — codebase root (required for generate and update)
- `--mode` — `quick` (default) or `full`. Ignored when `--update` or `--digest` is set.
- `--update` — incremental update: re-analyze only modules with changes since last run
- `--digest` — load existing vault context into the conversation (read-only, no file writes)
- `--scope` — (digest only) comma-separated module names to load in full
- `--focus` — (digest only) `architecture` (default), `issues`, or `all`
- `--output` — vault output path (default: `./docs-vault/` relative to codebase)

**Quick mode:** Architecture overview, module inventory, API reference, codebase health assessment, index pages — all at three audience levels.

**Full mode:** Everything in quick, plus design patterns, onboarding guides, cross-cutting concerns, tutorial walkthroughs.

**Update mode:** Reads `_state/analysis.json` from the existing vault, runs `git diff` against the stored commit, re-analyzes only affected modules, and merges results with existing docs. Auto-selects quick or full based on the scope of changes.

**Digest mode:** Loads structured context from an existing vault into the conversation. Reads — never writes — the vault. Provides architecture, module summaries, known issues, and session history before coding work begins.

---

## Model Tiers

This skill uses three model tiers to balance cost and quality. Select tier based on the task's cognitive demand.

| Tier | Model | Use For |
|------|-------|---------|
| **Extract** | Haiku | Code extraction, mechanical generation, data transforms, verification |
| **Write** | Sonnet | Narrative writing, pedagogical content, health report assembly |
| **Reason** | Opus | Issue identification, cross-module synthesis, architectural judgment |

**Conditional escalation:** Use Opus for cross-module synthesis only when the codebase has 5+ modules or the dependency graph contains cycles or bidirectional dependencies. For simpler codebases (1-4 modules, tree-shaped dependencies), Sonnet handles synthesis adequately.

**Conditional escalation for issues:** Use Opus for Limitations & Improvements analysis when a module's complexity is rated High, or when the module exceeds 1000 LOC, or when it involves concurrency or shared mutable state. Use Sonnet for Low/Medium complexity modules.

---

## Execution

### Phase 1: Intake & Analysis

Read `analysis-guide.md` for detailed instructions.

1. Survey the codebase — entry points, config files, directory structure
2. Identify independent modules
3. Dispatch parallel analysis agents (MUST parallelize if 3+ modules):
   - **Haiku agents** extract sections 1-6 (architecture, API, patterns, dependencies, complexity, key files)
   - **Sonnet or Opus agents** then produce section 7 (limitations & improvements), receiving the Haiku output as input. Use Opus for High complexity or >1000 LOC modules; Sonnet otherwise.
4. Synthesize into dependency graph and architecture narrative — orchestrator for ≤4 modules, **Opus agent** for 5+ modules or complex dependency graphs
5. Write `_state/analysis.json` (Haiku agent — mechanical data transform)

### Phase 2: Documentation Generation

Read `obsidian-templates.md` for formatting rules. Read `output-structure.md` for vault layout.

Dispatch in parallel where possible:

1. **Sonnet agent**: `Architecture/System Overview.md` (narrative writing)
2. **Haiku agents** (parallel): `Architecture/System Map.canvas`, `Architecture/Dependency Map.md`, `Index.md` (data transforms)
3. **Sonnet agents** (parallel, one per module): `Modules/{Name}.md` — each receives its module's analysis report + synthesis context
4. **Sonnet agent**: `Health/` — Limitations.md, Code Review.md, Health Summary.md with severity charts
5. (Full mode) **Sonnet agents**: `Patterns/`, `Onboarding/`, `Cross-Cutting/`

### Phase 3: Verification & Output

1. **Haiku agent**: Verify every `[[wikilink]]` resolves to an existing generated file, verify every file has complete frontmatter
2. Report: file count, module count, mode, broken links (if any)

---

## Digest Mode (`--digest`)

Load structured context from an existing vault into the current conversation. This mode is **read-only** — it never writes files.

**Model: Haiku** — this is a read-and-present task, no analysis or generation.

### Execution

1. **Validate** — check `<vault-path>` exists and contains `_state/analysis.json`. If missing, report "No code-to-docs vault found. Run code-to-docs to generate one first."
2. **Load baseline** — read `_state/analysis.json` (module list, dependency graph, issues, sessions) and `Architecture/System Overview.md`
3. **Load focus content:**

| `--focus` | Additional content loaded |
|-----------|--------------------------|
| `architecture` (default) | `Architecture/Dependency Map.md`, module Overview + Architecture sections only |
| `issues` | `Health/Limitations.md`, `Health/Code Review.md`, module Code Review Notes |
| `all` | Everything in architecture + issues + `Health/Health Summary.md` |

4. **Load scoped modules** — for each module in `--scope`, read the full `Modules/{Name}.md`. Unscoped modules get overview-only.
5. **Present context** — output a structured summary: project name, last run info, architecture narrative, module map, scoped module content, known issues, recent session history.

### Token Budget

| Scope | Target |
|-------|--------|
| Default (architecture only) | < 3,000 tokens |
| With `--scope` (1-2 modules) | < 6,000 tokens |
| With `--focus all` | < 10,000 tokens |

If content exceeds targets, truncate module docs to Overview + Architecture sections and note the truncation.

### Digest Red Flags

- Writing any files — digest is read-only
- Running generation or analysis — if the vault is stale, suggest `--update`, don't run it
- Loading all module docs in full without `--scope` or `--focus all`

---

## Update Mode (`--update`)

When `--update` is set, the skill runs an incremental update instead of a full generation. Read `analysis-guide.md` section "Incremental Update Flow" for detailed instructions.

### Prerequisites

- An existing vault with `_state/analysis.json` at the output path
- The codebase must be a git repository (needed for `git diff`)
- If either is missing, fall back to a full generate run and inform the user

### Update Phases

1. **Diff** — Read `_state/analysis.json`, run `git diff <stored_commit>..HEAD --name-only` to get changed files
2. **Map** — Map changed files to affected modules using the `files_analyzed` entries. Files not in any module are flagged for review (possible new module).
3. **Auto-select mode:**
   - **Quick** if: changes are within existing modules only, no new top-level directories, dependency graph unchanged
   - **Full** if: new modules detected, modules removed, dependency structure changed (new imports across module boundaries), or >50% of tracked files changed
4. **Re-analyze** — Run the two-pass analysis (Haiku extraction → Sonnet/Opus issues) only on affected modules. Unchanged modules keep their existing reports.
5. **Merge** — Combine new analysis with existing vault docs:
   - Regenerate changed module docs
   - Preserve unchanged module docs
   - Regenerate Architecture/ and Health/ from the merged synthesis (always — these are cross-module)
   - Regenerate Index.md (always — cheap, ensures consistency)
6. **Update state** — Write new `_state/analysis.json` with updated commit hash, timestamp, merged issues (mark resolved issues, add new ones), and append to sessions array
7. **Verify** — Same as Phase 3 of baseline

### Issue Tracking Across Updates

On each update, compare the new issues against the previous `issues` array:

| Scenario | Action |
|----------|--------|
| Issue from previous run still present in re-analyzed module | Keep with status `open` |
| Issue from previous run absent in re-analyzed module | Change status to `resolved` |
| Issue from previous run in a module that wasn't re-analyzed | Keep with status `open` (unchanged) |
| New issue found in re-analyzed module | Add with status `open` |

---

## Development Lifecycle

The three modes form an optional workflow:

```
Session start:  /code-to-docs --digest ./docs-vault --scope {relevant modules}
Coding work:    ... normal development ...
Session end:    /code-to-docs /path/to/codebase --update
```

Each mode works independently — you don't need the full lifecycle to use any single mode. Generate (`quick`/`full`) works without a prior vault. Digest works without an upcoming update. Update works without a prior digest.

---

## Red Flags

1. Reading files >500 lines without grep-filtering first
2. Analyzing 3+ independent modules sequentially instead of in parallel
3. Reading `node_modules/`, `vendor/`, `.git/`, or build output
4. Generating PNG/SVG instead of Mermaid inline
5. Skipping wikilink verification in Phase 3
6. Documenting third-party dependencies instead of project code
7. Fabricating design rationale — say "Rationale not documented" instead
8. Fabricating code issues — only report limitations/bugs/improvements that are evidently present in the code
9. Using Opus for extraction or mechanical tasks — Haiku handles these; Opus is reserved for issue analysis on complex modules and cross-module synthesis on large codebases
10. Issue analysis agents re-reading entire modules — they receive the Haiku report as input and should only read source files to verify specific concerns

---

## Rationalization Traps

| Thought | Reality |
|---------|---------|
| "This codebase is small enough to read sequentially" | If 3+ modules exist, parallelize. The rule is about modules, not LOC. |
| "I'll add frontmatter later" | Generate it with the file. Every file, every time. |
| "The advanced section is the same as intermediate" | You missed edge cases, concurrency, or failure modes. Re-analyze. |
| "This module is too simple for three levels" | Beginner still explains language constructs. Advanced still covers failure modes. Write all three. |
| "I'll just read the whole file, it's not that big" | If it's over 500 lines, grep first. No exceptions. |
| "This code is fine, no issues to report" | Every codebase has limitations. If you found none, you didn't look hard enough — re-examine error handling, concurrency, and abstraction boundaries. |
| "I'll skip the code examples in the review" | Before/after snippets are the core educational value. Always include them for bugs and improvements. |
| "I'll use Opus for everything to be safe" | Opus costs 10-15x more than Haiku. Use the cheapest model that meets the task's cognitive demand. Check the model selection tables. |
| "This module is simple, I'll skip Pass 2" | Every module gets an issue analysis pass. Simple modules get Sonnet; the pass may report "None identified" — that's a valid outcome. |
