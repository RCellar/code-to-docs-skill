---
name: code-to-docs
description: Use when generating documentation from a codebase, creating architecture docs, building an Obsidian vault from code, documenting a new service, or when someone asks to document or explain a project's structure
---

## Overview

Analyze a codebase and produce an Obsidian-native documentation vault containing architecture diagrams, API references, and teaching-focused explanations written at three audience levels: beginner (language constructs explained), intermediate (patterns and integration), and advanced (failure modes, concurrency, edge cases). Output is ready to open directly in Obsidian with working wikilinks, Mermaid diagrams, and Dataview queries.

## Invocation

```
Skill(skill: "code-to-docs", args: "<path> [--mode quick|full] [--output <path>]")
```

- `<path>` — codebase root (required)
- `--mode` — `quick` (default) or `full`
- `--output` — vault output path (default: `./docs-vault/` relative to codebase)

**Quick mode:** Architecture overview, module inventory, API reference, index pages — all at three audience levels.

**Full mode:** Everything in quick, plus design patterns, onboarding guides, cross-cutting concerns, tutorial walkthroughs.

---

## Execution

### Phase 1: Intake & Analysis

Read `analysis-guide.md` for detailed instructions.

1. Survey the codebase — entry points, config files, directory structure
2. Identify independent modules
3. Dispatch parallel agents (MUST parallelize if 3+ modules)
4. Synthesize into dependency graph and architecture narrative
5. Write `_state/analysis.json`

### Phase 2: Documentation Generation

Read `obsidian-templates.md` for formatting rules. Read `output-structure.md` for vault layout.

1. Generate `Architecture/` docs with Mermaid diagrams
2. Generate `Architecture/System Map.canvas`
3. Generate `Modules/{Name}.md` for each module
4. (Full mode) Generate `Patterns/`, `Onboarding/`, `Cross-Cutting/`
5. Generate `Index.md` with Dataview queries

### Phase 3: Verification & Output

1. Verify every `[[wikilink]]` resolves to an existing generated file
2. Verify every file has complete frontmatter
3. Report: file count, module count, mode, broken links

---

## Red Flags

1. Reading files >500 lines without grep-filtering first
2. Analyzing 3+ independent modules sequentially instead of in parallel
3. Reading `node_modules/`, `vendor/`, `.git/`, or build output
4. Generating PNG/SVG instead of Mermaid inline
5. Skipping wikilink verification in Phase 3
6. Documenting third-party dependencies instead of project code
7. Fabricating design rationale — say "Rationale not documented" instead

---

## Rationalization Traps

| Thought | Reality |
|---------|---------|
| "This codebase is small enough to read sequentially" | If 3+ modules exist, parallelize. The rule is about modules, not LOC. |
| "I'll add frontmatter later" | Generate it with the file. Every file, every time. |
| "The advanced section is the same as intermediate" | You missed edge cases, concurrency, or failure modes. Re-analyze. |
| "This module is too simple for three levels" | Beginner still explains language constructs. Advanced still covers failure modes. Write all three. |
| "I'll just read the whole file, it's not that big" | If it's over 500 lines, grep first. No exceptions. |
