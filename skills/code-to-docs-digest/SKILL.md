---
name: digest
description: Load existing code-to-docs vault context into the conversation before coding. Read-only — never writes files. Provides architecture overview, module summaries, known issues, and session history. Use when starting a coding session, loading doc context, or catching up on a documented codebase.
---

## Overview

Load structured context from an existing code-to-docs vault. Read-only, never writes files.

### Related Skills

| Skill | Purpose |
|-------|---------|
| `code-to-docs` | Generate full documentation vault from a codebase |
| `code-to-docs:update` | Incremental update — re-analyze only modules with changes since last run |

## Invocation

```
Skill(skill: "code-to-docs:digest", args: "<vault-path> [--scope <module,...>] [--focus issues|architecture|all]")
```

- `<vault-path>` — path to existing code-to-docs vault (required)
- `--scope` — comma-separated module names to load in full (default: overview only)
- `--focus` — `architecture` (default), `issues`, or `all`

---

## Model

**Haiku** — read-and-present task. No analysis or generation required.

---

## Execution

### Step 1: Validate Vault

Check that `<vault-path>/_state/analysis.json` exists.

If missing, stop and report:

> No code-to-docs vault found at `<vault-path>`. Run `/code-to-docs` to generate one first.

### Step 2: Load Baseline

Read:
- `_state/analysis.json` — module inventory, dependency graph, timestamps
- `Architecture/System Overview.md` — architecture narrative and diagrams

### Step 3: Load Focus Content

| `--focus` value | Files loaded |
|-----------------|-------------|
| `architecture` (default) | `Architecture/Dependency Map.md`, `Architecture/System Map.canvas` |
| `issues` | `Health/Limitations.md`, `Health/Code Review.md`, `Health/Health Summary.md` |
| `all` | All architecture + all issues files |

### Step 4: Load Scoped Modules

- For modules listed in `--scope`: load full `Modules/{Name}.md`
- For all other modules: load only the overview section (first heading block)

### Step 5: Present Context Summary

Output a structured summary including:
- Architecture overview (from System Overview)
- Module inventory with status
- Focus-specific details (architecture maps or health issues)
- Scoped module deep-dives

---

## Token Budget

| Configuration | Target | Action if exceeded |
|---------------|--------|--------------------|
| Default (no flags) | < 3K tokens | Truncate module summaries |
| `--scope` specified | < 6K tokens | Truncate non-scoped modules |
| `--focus all` | < 10K tokens | Truncate oldest session history first |

---

## Red Flags

Do NOT do any of the following:

- **Writing any files** — this skill is strictly read-only
- **Running generation or analysis** — if the user wants updates, suggest `/code-to-docs:update` instead
- **Loading all modules without `--scope` or `--focus all`** — only load overviews by default to stay within token budget
- **Using a non-Haiku model** — this is a simple read-and-present task; Haiku is sufficient
