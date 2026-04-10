---
name: code-to-docs
description: Use when generating documentation from a codebase, creating architecture docs, building an Obsidian vault from code, or when someone asks to document or explain a project's structure
---

## Overview

Analyze a codebase and produce an Obsidian-native documentation vault containing architecture diagrams, API references, and teaching-focused explanations written at three audience levels: beginner (language constructs explained), intermediate (patterns and integration), and advanced (failure modes, concurrency, edge cases). Output is ready to open directly in Obsidian with working wikilinks, Mermaid diagrams, and Dataview queries.

### Related Skills

| Skill | Purpose |
|-------|---------|
| `code-to-docs:update` | Incremental update — re-analyze only modules with changes since last run |
| `code-to-docs:digest` | Load existing vault context into the conversation (read-only) |
| `code-to-docs:hooks` | Install/remove automation hooks for the generate-digest-update lifecycle |

## Invocation

```
Skill(skill: "code-to-docs", args: "<path> [--mode quick|full] [--output <path>]")
```

- `<path>` — codebase root (required)
- `--mode` — `quick` (default) or `full`
- `--output` — vault output path (default: `./docs-vault/` relative to codebase)

**Quick mode:** Architecture overview, module inventory, API reference, codebase health assessment, index pages — all at three audience levels.

**Full mode:** Everything in quick, plus design patterns, onboarding guides, cross-cutting concerns, tutorial walkthroughs.

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

Read `../code-to-docs-references/analysis-guide.md` for detailed instructions.

1. Survey the codebase — entry points, config files, directory structure
2. Identify independent modules
3. Dispatch parallel analysis agents (MUST parallelize if 3+ modules):
   - **Haiku agents** extract sections 1-6 (architecture, API, patterns, dependencies, complexity, key files)
   - **Sonnet or Opus agents** then produce section 7 (limitations & improvements), receiving the Haiku output as input. Use Opus for High complexity or >1000 LOC modules; Sonnet otherwise.
4. Synthesize into dependency graph and architecture narrative — orchestrator for ≤4 modules, **Opus agent** for 5+ modules or complex dependency graphs
5. Write `_state/analysis.json` (Haiku agent — mechanical data transform)

### Phase 2: Documentation Generation

Read `../code-to-docs-references/obsidian-templates.md` for formatting rules. Read `../code-to-docs-references/output-structure.md` for vault layout.

**Before dispatching:** Check if `obsidian` CLI is available (`which obsidian`). If yes, use `obsidian create` with `silent` flag for note creation. If no, use direct file writes. See `../code-to-docs-references/output-structure.md` "Obsidian CLI Integration" for details.

Dispatch in parallel where possible:

1. **Sonnet agent**: `Architecture/System Overview.md` (narrative writing)
2. **Haiku agents** (parallel): `Architecture/System Map.canvas`, `Architecture/Dependency Map.md`, `Documentation.base`, `Index.md` (data transforms)
3. **Sonnet agents** (parallel, one per module): `Modules/{Name}.md` — each receives its module's analysis report + synthesis context
4. **Sonnet agent**: `Health/` — Limitations.md, Code Review.md, Health Summary.md with severity charts
5. (Full mode) **Sonnet agents**: `Patterns/`, `Onboarding/`, `Cross-Cutting/`

### Phase 3: Verification & Output

#### Phase 3 Dispatch Table

| Agent | Model | Input | Output | Condition |
|-------|-------|-------|--------|-----------|
| Verification | **haiku** | vault file list | broken links + frontmatter report | always |

1. **Haiku agent**: Verify every `[[wikilink]]` resolves to an existing generated file, verify every file has complete frontmatter
2. Report: file count, module count, mode, broken links (if any)

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
11. Dispatching an agent without setting the `model` parameter to match the dispatch table for that phase

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
| "I'll just handle this inline instead of dispatching an agent" | The orchestrator runs at Opus. If the dispatch table says Haiku or Sonnet, dispatch an agent — doing the work inline costs 10-15x more. |
