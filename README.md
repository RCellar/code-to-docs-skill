# code-to-docs

A Claude Code skill that analyzes codebases and generates Obsidian-native documentation vaults with architecture diagrams, API references, codebase health assessments, and teaching-focused explanations at three audience levels.

## What It Does

Point it at a codebase and it produces a complete Obsidian vault:

- **Architecture docs** with Mermaid diagrams and a spatial Canvas map
- **Module documentation** at three audience levels (beginner, intermediate, advanced)
- **API reference** with function signatures, parameters, and return types
- **Codebase health assessment** — limitations, bugs/risks, improvement opportunities with severity charts
- **Educational code review** — before/after snippets showing what's wrong and how to fix it
- **Index pages** with Dataview queries for navigation
- **Incremental contract** — state file tracking modules, dependencies, and issues for future change detection

### Two Modes

| Mode | Generates |
|------|-----------|
| **quick** (default) | Architecture overview, module docs, API reference, health assessment, index |
| **full** | Everything in quick + design patterns, onboarding guides, cross-cutting concerns, tutorials |

### Three Audience Levels

Every module doc includes all three as sections:

- **Beginner** — explains language constructs, annotated walkthroughs, no jargon
- **Intermediate** — design rationale, patterns, module interactions, trade-offs
- **Advanced** — concurrency, performance, failure modes, edge cases, code review notes

### Three Model Tiers

The skill uses Haiku, Sonnet, and Opus strategically to minimize token cost without sacrificing quality:

| Tier | Model | Use |
|------|-------|-----|
| **Extract** | Haiku | Code extraction, mechanical generation (Canvas, Index, state file), verification |
| **Write** | Sonnet | Narrative writing, pedagogical content, health report assembly |
| **Reason** | Opus | Deep issue analysis (complex modules), cross-module synthesis (5+ modules) |

Opus is used conditionally — only for modules rated High complexity, exceeding 1000 LOC, or involving concurrency/security, and for synthesis on codebases with 5+ modules or complex dependency graphs.

## Installation

### Via Claude Code Plugin Marketplace (recommended)

Add this repo as a marketplace source, then install the plugin:

```
/plugin marketplace add RCellar/code-to-docs-skill
/plugin install code-to-docs@code-to-docs-skill
```

### Manual Installation

Copy the skill files directly:

```bash
mkdir -p ~/.claude/skills/code-to-docs
cp skills/code-to-docs/* ~/.claude/skills/code-to-docs/
```

## Usage

```
/code-to-docs /path/to/codebase
/code-to-docs /path/to/codebase --mode full
/code-to-docs /path/to/codebase --mode quick --output ./my-docs/
```

Or invoke programmatically:

```
Skill(skill: "code-to-docs", args: "/path/to/codebase --mode quick")
```

### Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `<path>` | Yes | — | Root of the codebase to document |
| `--mode` | No | `quick` | `quick` or `full` |
| `--output` | No | `./docs-vault/` | Output path (relative to codebase root) |

## Output Structure

```
docs-vault/
├── _state/analysis.json        # Incremental contract (modules, deps, issues)
├── Architecture/
│   ├── System Overview.md      # Mermaid diagrams + narrative
│   ├── Dependency Map.md       # Cross-module dependencies
│   └── System Map.canvas       # Spatial map linking modules
├── Modules/
│   └── {Module Name}.md        # Beginner + Intermediate + Advanced + API + Review Notes
├── Health/
│   ├── Limitations.md          # Architecture and component constraints
│   ├── Code Review.md          # Bugs, risks, improvements with before/after code
│   └── Health Summary.md       # Severity charts (Mermaid pie/bar)
├── Patterns/                   # full mode only
├── Onboarding/                 # full mode only
├── Cross-Cutting/              # full mode only
└── Index.md                    # Dataview queries
```

## How It Works

### Phase 1: Analysis (two-pass)

1. Surveys the codebase — entry points, config files, directory structure
2. Identifies independent modules
3. **Pass 1** — dispatches parallel **Haiku** agents to extract structure (architecture, API, patterns, dependencies, complexity, key files)
4. **Pass 2** — dispatches **Sonnet/Opus** agents to identify limitations and improvements, receiving the Haiku output as input (no re-reading code)
5. Synthesizes into dependency graph, architecture narrative, and aggregated issues

### Phase 2: Generation (parallel)

Dispatches independent agents in parallel with model tier matched to task:

- **Sonnet** agents: module docs (one per module), System Overview, health reports, full-mode extras
- **Haiku** agents: Canvas, Dependency Map, Index, state file, Health Summary charts

### Phase 3: Verification

- **Haiku** agent checks all wikilinks resolve and all files have complete frontmatter
- Reports: file count, module count, mode, broken links

## Skill Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Entry point — orchestrates phases, model tier rules, red flags, discipline |
| `analysis-guide.md` | Phase 1 reference — two-pass agent templates, model selection tables, synthesis |
| `obsidian-templates.md` | Phase 2 reference — frontmatter schema, audience levels, health templates, callouts, Mermaid |
| `output-structure.md` | Phase 2 reference — vault layout, generation model assignments, Canvas rules, state file schema |

## Examples

The `examples/` directory contains complete output vaults you can open directly in Obsidian:

- **dockhand/** — full-mode vault from a SvelteKit + Go container management UI (10 modules, patterns, onboarding, cross-cutting concerns)

## Pressure Tests

Three test scenarios in `tests/`:

- `pressure-test-quick-mode.md` — validates quick mode on a 3-5 module codebase
- `pressure-test-full-mode.md` — validates full mode additions
- `pressure-test-parallel.md` — validates parallel dispatch discipline on 5+ modules

## Future Enhancements

- Incremental updates via `git diff` + state file (issues tracked across runs)
- Configurable output format (portable markdown vs Obsidian-native)
- Excalidraw diagram generation
- Integration with `obsidian-cli` skill

## License

MIT
