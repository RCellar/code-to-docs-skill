# Output Structure — Vault Layout Reference

Supporting reference for the `code-to-docs` skill. Loaded on demand during Phase 2 (Documentation Generation).

**Frontmatter:** All generated files require frontmatter — see `obsidian-templates.md` for the full schema. Both the Dataview queries in Index.md and the Bases catalog in Documentation.base depend on frontmatter fields (`title`, `language`, `complexity`, `status`, `type`, `generated-at`) and tags (`#code-docs`, `#module`, etc.).

---

## Phase 2 Generation Model Assignments

Dispatch these as parallel agents where possible. Each agent receives only the data it needs — not the full synthesis.

| Output | Model | Input | Notes |
|--------|-------|-------|-------|
| `Architecture/System Overview.md` | **Sonnet** | Synthesis narrative + dependency graph | Narrative architecture writing |
| `Architecture/Dependency Map.md` | **Haiku** | Dependency graph from synthesis | Data → Mermaid + table transform |
| `Architecture/System Map.canvas` | **Haiku** | Module list + dependency graph | Data → JSON Canvas transform |
| `Modules/{Name}.md` (×N) | **Sonnet** | That module's 7-section report + synthesis context for wikilinks | One agent per module, parallel |
| `Health/Health Summary.md` | **Haiku** | Aggregated issue counts | Data → Mermaid chart transform |
| `Health/Limitations.md` + `Health/Code Review.md` | **Sonnet** | Aggregated issues from synthesis | Requires judgment for framing |
| `Patterns/{Name}.md` (full mode) | **Sonnet** | System-wide patterns from synthesis | Pattern identification + writing |
| `Onboarding/` (full mode) | **Sonnet** | Full synthesis + module reports | Requires broad codebase understanding |
| `Cross-Cutting/{Name}.md` (full mode) | **Sonnet** | Relevant cross-cutting data from synthesis | Requires cross-module reasoning |
| `Documentation.base` | **Haiku** | Module list + metadata | Mechanical JSON assembly |
| `Index.md` | **Haiku** | Project name + timestamp + mode | Template fill (Dataview fallback) |
| `_state/analysis.json` | **Haiku** | Synthesis data | Mechanical JSON assembly |

---

## Vault Directory Layout

```
docs-vault/
├── _state/
│   └── analysis.json           # Incremental contract state file
├── Architecture/
│   ├── System Overview.md      # Top-level architecture narrative
│   ├── Dependency Map.md       # Cross-module dependency Mermaid
│   └── System Map.canvas       # Canvas linking to all module notes
├── Modules/
│   └── {Module Name}.md        # Per-module doc (beginner/intermediate/advanced + API ref)
├── Patterns/                   # full mode only
│   └── {Pattern Name}.md
├── Onboarding/                 # full mode only
│   ├── Getting Started.md
│   ├── First Contribution.md
│   └── Debugging Guide.md
├── Cross-Cutting/              # full mode only
│   └── {Concern Name}.md
├── Health/
│   ├── Limitations.md          # Architecture and component constraints
│   ├── Code Review.md          # Bugs, risks, and improvement opportunities
│   └── Health Summary.md       # Aggregate charts and severity breakdown
├── Documentation.base          # Obsidian Bases catalog (native, no plugins needed)
└── Index.md                    # Hub page with Dataview queries (fallback)
```

---

## File Naming

- Title case with spaces (Obsidian-native): `User Service.md`, `Payment Gateway.md`
- Pattern files named after the pattern: `Repository Pattern.md`, `Event Sourcing.md`
- One module = one file in `Modules/`
- One pattern = one file in `Patterns/`
- One cross-cutting concern = one file in `Cross-Cutting/`
- Sanitize illegal filename characters (`/`, `:`, `?`, `*`, `<`, `>`, `|`) — replace with hyphens

---

## Canvas Generation

Generate exactly one Canvas file: `Architecture/System Map.canvas`

The Canvas file is valid JSON Canvas format. Structure:

```json
{
  "nodes": [
    {
      "id": "module-slug",
      "type": "file",
      "file": "Modules/Module Name.md",
      "x": 0,
      "y": 0,
      "width": 250,
      "height": 60
    }
  ],
  "edges": [
    {
      "id": "edge-slug",
      "fromNode": "source-module-slug",
      "fromSide": "right",
      "toNode": "target-module-slug",
      "toSide": "left",
      "label": "calls"
    }
  ]
}
```

**Node rules:**
- Use `"type": "file"` for all module nodes — links directly into the module doc (Obsidian derives the display label from the file path)
- The `"file"` field is the vault-relative path to the module markdown file
- Assign columns by topological depth: modules with no dependencies go in column 0, modules that depend only on column-0 modules go in column 1, etc.
- Within a column, order rows alphabetically by module name
- Horizontal spacing: 300px between columns
- Vertical spacing: 150px between rows within a column

**Edge labels** describe the relationship type: `"calls"`, `"depends on"`, `"publishes to"`, `"imports"`, `"extends"`, etc.

---

## Index.md Template

```markdown
---
title: Documentation Index
type: index
generated-by: code-to-docs
generated-at: <ISO 8601 timestamp>
mode: <quick or full>
---

# Documentation Index

Generated by `code-to-docs`. Use the queries below to navigate the vault.

## Modules by Complexity

\`\`\`dataview
TABLE title, language, complexity, status
FROM #code-docs AND #module
SORT complexity DESC
\`\`\`

## Modules by Language

\`\`\`dataview
TABLE title, complexity, status
FROM #code-docs AND #module
GROUP BY language
\`\`\`

## Documentation Status

\`\`\`dataview
TABLE title, type, status
FROM #code-docs
WHERE status != "generated"
SORT file.name ASC
\`\`\`

## Codebase Health

\`\`\`dataview
TABLE title, type, status
FROM #code-docs AND #health
SORT title ASC
\`\`\`

## All Documentation

\`\`\`dataview
TABLE title, type, generated-at
FROM #code-docs
SORT generated-at DESC
\`\`\`
```

---

## Documentation.base — Obsidian Bases Catalog

Generate `Documentation.base` in the vault root. This provides a native Obsidian Bases view — interactive, filterable, no plugins required. It complements Index.md (which uses Dataview) rather than replacing it.

The `.base` file is JSON. Structure:

```json
{
  "headings": [
    { "heading": "title", "type": "property" },
    { "heading": "type", "type": "property" },
    { "heading": "language", "type": "property" },
    { "heading": "complexity", "type": "property" },
    { "heading": "status", "type": "property" },
    { "heading": "canonical-source", "type": "property" }
  ],
  "sourceType": "folder",
  "source": "",
  "filters": [
    {
      "field": "generated-by",
      "operator": "is",
      "value": "code-to-docs"
    }
  ],
  "sort": [
    { "field": "type", "order": "asc" },
    { "field": "complexity", "order": "desc" }
  ]
}
```

This creates a table view of all generated docs, filterable by type, complexity, and language. Users can switch between table and card views, add computed columns, or modify filters directly in Obsidian.

**Generation:** Haiku agent — this is a mechanical JSON transform from the module list and metadata.

---

## Obsidian CLI Integration (Opportunistic)

At the start of Phase 2, check if the `obsidian` CLI is available:

```bash
which obsidian >/dev/null 2>&1
```

If available **and** Obsidian is running (the CLI requires a running instance), use it for note creation and property management. If not available, fall back to direct file writes — the current behavior, with no degradation.

### When obsidian CLI is available

| Operation | Command | Benefit over direct file write |
|-----------|---------|-------------------------------|
| Create note | `obsidian create name="{title}" content="{content}" path="{vault-path}" silent` | Wikilink resolution, property validation |
| Set property | `obsidian property:set name="{key}" value="{val}" file="{title}"` | Obsidian-native property storage |
| Verify backlinks | `obsidian backlinks file="{title}"` | Uses Obsidian's live graph, not grep |

### When obsidian CLI is NOT available

Fall back to direct file writes using the Write tool — identical to current behavior. This is the default and always-works path.

### Integration rules

- **Never require** the obsidian CLI — it is an enhancement, not a dependency
- **Check once** at the start of Phase 2, store the result, and use it for all subsequent operations in the same run
- **Use `silent` flag** on all `obsidian create` calls — do not open notes in the editor during generation
- **Fall back on any error** — if an `obsidian create` call fails, retry with direct file write for that note
- **Do not mix** — if obsidian CLI is available, use it for all notes in the run (consistency in how properties are stored)

### Skill references

When using obsidian CLI, the `obsidian-markdown`, `json-canvas`, and `obsidian-bases` skills contain the authoritative syntax references. Prefer those skills' conventions over the templates in this file when they conflict.

---

## State File

`_state/analysis.json` — written at the end of Phase 1. Schema:

```json
{
  "project": "string — project name or root directory basename",
  "modules": ["list of module names as strings"],
  "dependency_graph": {
    "Module Name": ["Dependency Module A", "Dependency Module B"]
  },
  "files_analyzed": {
    "relative/path/to/file.ts": "sha256hexstring"
  },
  "git_commit": "abc123 or null if not a git repo",
  "timestamp": "ISO 8601",
  "mode": "quick | full",
  "issues": [
    {
      "id": "unique-slug",
      "module": "Module Name",
      "type": "limitation | bug-risk | improvement",
      "severity": "low | medium | high",
      "file": "relative/path/to/file.ts",
      "lines": "start-end or null",
      "summary": "one-line description",
      "status": "open | resolved"
    }
  ],
  "sessions": [
    {
      "type": "generate | update | digest",
      "timestamp": "ISO 8601",
      "git_commit_start": "abc123 or null",
      "git_commit_end": "def456",
      "mode": "quick | full | null (for digest)",
      "modules_affected": ["Module A", "Module B"],
      "issues_resolved": ["issue-slug-1"],
      "issues_introduced": ["issue-slug-2"]
    }
  ]
}
```

### State File Fields

**Core fields** — written on every generate or update run:
- `modules`, `dependency_graph`, `files_analyzed`, `git_commit`, `timestamp`, `mode` — snapshot of the codebase as of this run

**Issues array** — tracks codebase health across runs:
- On generate: all issues start with `status: "open"`
- On update: resolved issues change to `status: "resolved"`, new issues added as `"open"`, unchanged module issues carried forward

**Sessions array** — audit trail of the documentation lifecycle:
- `type: "generate"` — baseline quick or full run
- `type: "update"` — incremental update via `--update`
- `type: "digest"` — recorded when `code-to-docs-digest` loads the vault (read-only, no changes to docs)
- `git_commit_start` — the stored commit from the previous state (null on first generate)
- `git_commit_end` — HEAD at the time of this session
- `modules_affected` — which modules were analyzed (all for generate, subset for update, none for digest)
- `issues_resolved` / `issues_introduced` — what changed in the health picture

The sessions array provides continuity across the digest → code → update lifecycle. The digest skill reads it to report how stale the documentation is and what changed in recent sessions.

This is the **incremental contract**. The `--update` mode reads this state, runs `git diff` against the stored commit, and re-analyzes only changed modules. The `code-to-docs-digest` skill reads it to provide session-start context. The baseline skill writes this file on every run — do not skip writing it.

### State File Validation

Before reading `analysis.json` in update or digest mode, validate the following required fields exist and have the expected types. If validation fails, report the specific error and fall back to a full generate run (for update) or abort with an error message (for digest).

| Field | Type | Required |
|-------|------|----------|
| `modules` | array of strings | yes |
| `dependency_graph` | object (string → array of strings) | yes |
| `files_analyzed` | object (string → string) | yes |
| `git_commit` | string or null | yes |
| `timestamp` | string (ISO 8601) | yes |
| `mode` | string (`"quick"` or `"full"`) | yes |
| `issues` | array of objects | yes (may be empty) |
| `sessions` | array of objects | yes (may be empty) |

Each issue object must have: `id` (string), `module` (string), `type` (string), `severity` (string), `status` (string). Missing or malformed issues should be logged and skipped rather than causing a full abort.

**Note:** `_state/` is internal to the skill. If the vault is committed to git, add `_state/` to `.gitignore` to avoid leaking file hashes and commit refs from the analyzed codebase.
