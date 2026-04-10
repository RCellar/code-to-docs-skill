---
name: update
description: Incrementally update an existing code-to-docs vault after coding changes. Diffs against the last documented commit, re-analyzes only affected modules, merges with existing docs, and tracks issue resolution. Use when someone says update docs, sync docs, refresh documentation, or after making code changes.
---

## Overview

Run an incremental documentation update instead of a full generation. Reads `_state/analysis.json` from the existing vault, diffs against the stored commit, re-analyzes only affected modules, and merges results with existing docs.

## Related Skills

| Skill | Purpose |
|-------|---------|
| `code-to-docs` | Full generation (quick or full mode) — use when no vault exists yet |
| `code-to-docs:digest` | Load existing vault context before coding (read-only) |

## Invocation

```
Skill(skill: "code-to-docs:update", args: "<path> [--output <path>]")
```

- `<path>` — codebase root (default: `.` current directory)
- `--output` — vault path containing the existing `_state/analysis.json` (default: `./docs-vault/`)

## Prerequisites

- An existing vault with `_state/analysis.json` at the output path
- The codebase must be a git repository (needed for `git diff`)
- If either is missing, fall back to a full generate run and inform the user

---

## Model Tiers

Same tiers as `code-to-docs` — see that skill for the full table. Key rule: use the cheapest model that meets the task's cognitive demand. Haiku for extraction/mechanical, Sonnet for writing, Opus only for complex modules or large codebase synthesis.

---

## Execution

Read `../references/analysis-guide.md` section "Incremental Update Flow" for detailed step-by-step instructions. Read `../references/output-structure.md` for state file schema and vault layout. Read `../references/obsidian-templates.md` for formatting rules.

### Step 1: Load and Validate Previous State

1. Read `_state/analysis.json` from the existing vault at `--output` path
2. If the file does not exist, abort update and fall back to a full generate run. Inform the user: "No previous state found — running full generation instead."
3. Validate the state file against the schema in `../references/output-structure.md` "State File Validation" section. If required fields are missing or have wrong types, report the validation error and fall back to a full generate run.
4. Extract: `git_commit` (the commit hash from the last run), `modules` (module list), `dependency_graph`, `files_analyzed`, `issues`

### Step 2: Diff

1. Run `git diff <stored_git_commit>..HEAD --name-only` in the codebase root
2. Filter out excluded paths (see `../references/analysis-guide.md` Exclusions section)
3. The result is the list of **changed files** since the last documentation run

If the diff is empty (no changes since last run), report "No changes since last documentation run" and exit without modifying the vault.

### Step 3: Map Changes to Modules

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

### Step 4: Auto-Select Mode

| Condition | Mode |
|-----------|------|
| All changes within existing modules, no new modules, no deleted modules | **Quick** |
| New module detected (new directory with source files outside existing module roots) | **Full** |
| Module deleted (all files in a module removed) | **Full** |
| Dependency structure changed (new cross-module imports detected in diff) | **Full** |
| >50% of tracked files in `files_analyzed` changed | **Full** |

Report the auto-selected mode to the user: "Update mode: quick (2 of 8 modules affected)" or "Update mode: full (new module detected: Scheduler)".

### Step 5: Re-Analyze Affected Modules

For each affected module, run the same two-pass analysis as baseline:

1. **Haiku extraction** (sections 1-6) — same agent prompt template as `../references/analysis-guide.md` Pass 1
2. **Sonnet/Opus issue analysis** (section 7) — same agent prompt template as `../references/analysis-guide.md` Pass 2, same model escalation rules

For **unchanged modules**, carry forward their existing reports from the previous run. Do not re-analyze.

If auto-selected mode is **full**, also run Module Identification to detect any new modules, then analyze those as well.

### Step 6: Merge Synthesis

Combine new analysis reports (affected modules) with carried-forward reports (unchanged modules) into a single synthesis.

1. Rebuild dependency graph from all module reports (new + carried forward)
2. Compare new dependency graph to previous — flag any structural changes
3. Regenerate architecture narrative (always — even small changes can shift the system story)
4. Merge issues:
   - Issues in re-analyzed modules: replace with new analysis results
   - Issues in unchanged modules: carry forward with status `open`
   - Issues from previous run that no longer appear in re-analyzed modules: mark as `resolved`

### Step 7: Selective Generation

Use the same Phase 2 generation flow as `code-to-docs`, but selectively:

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

### Step 8: Update State File

Write `_state/analysis.json` with:
- `git_commit` → current HEAD
- `timestamp` → now
- `mode` → the auto-selected mode
- `modules` → merged module list (may include new modules in full mode)
- `files_analyzed` → merged map (updated entries for re-analyzed modules, carried forward for unchanged)
- `issues` → merged array with status updates
- `sessions` → append new session entry (see `../references/output-structure.md` for schema)

### Step 9: Verify

Same as `code-to-docs` Phase 3 — Haiku agent checks wikilinks and frontmatter across the entire vault (not just changed files).

---

## Issue Tracking Across Updates

On each update, compare the new issues against the previous `issues` array:

| Scenario | Action |
|----------|--------|
| Issue from previous run still present in re-analyzed module | Keep with status `open` |
| Issue from previous run absent in re-analyzed module | Change status to `resolved` |
| Issue from previous run in a module that wasn't re-analyzed | Keep with status `open` (unchanged) |
| New issue found in re-analyzed module | Add with status `open` |

---

## Red Flags

1. Re-analyzing unchanged modules — only affected modules get re-analyzed
2. Skipping state file validation — always validate before reading
3. Ignoring the auto-select mode logic — don't always run quick or always run full
4. Deleting unchanged module docs — preserve them, only regenerate affected ones
5. All red flags from `code-to-docs` also apply during the re-analysis phases
