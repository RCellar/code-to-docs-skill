# code-to-docs

A Claude Code skill that analyzes codebases and generates Obsidian-native documentation vaults with architecture diagrams, API references, and teaching-focused explanations at three audience levels.

## What It Does

Point it at a codebase and it produces a complete Obsidian vault:

- **Architecture docs** with Mermaid diagrams and a spatial Canvas map
- **Module documentation** at three audience levels (beginner, intermediate, advanced)
- **API reference** with function signatures, parameters, and return types
- **Index pages** with Dataview queries for navigation
- **Incremental contract** — a state file for future change-detection support

### Two Modes

| Mode | Generates |
|------|-----------|
| **quick** (default) | Architecture overview, module docs, API reference, index |
| **full** | Everything in quick + design patterns, onboarding guides, cross-cutting concerns, tutorials |

### Three Audience Levels

Every module doc includes all three as sections:

- **Beginner** — explains language constructs, annotated walkthroughs, no jargon
- **Intermediate** — design rationale, patterns, module interactions, trade-offs
- **Advanced** — concurrency, performance, failure modes, edge cases

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
├── _state/analysis.json        # Incremental contract
├── Architecture/
│   ├── System Overview.md      # Mermaid diagrams + narrative
│   ├── Dependency Map.md       # Cross-module dependencies
│   └── System Map.canvas       # Spatial map linking modules
├── Modules/
│   └── {Module Name}.md        # Beginner + Intermediate + Advanced + API
├── Patterns/                   # full mode only
├── Onboarding/                 # full mode only
├── Cross-Cutting/              # full mode only
└── Index.md                    # Dataview queries
```

## How It Works

1. **Phase 1: Analysis** — surveys the codebase, identifies independent modules, dispatches parallel agents (one per module) to extract architecture, APIs, patterns, and dependencies
2. **Phase 2: Generation** — produces Obsidian-native markdown with wikilinks, frontmatter, callouts, Mermaid diagrams, and a Canvas file
3. **Phase 3: Verification** — checks all wikilinks resolve, all files have complete frontmatter, reports summary

### Parallel Execution

For codebases with 3+ independent modules, analysis is automatically parallelized — one agent per module, all dispatched simultaneously. This follows the established Claude Code `dispatching-parallel-agents` pattern.

## Skill Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Entry point — orchestrates phases, defines red flags and discipline |
| `analysis-guide.md` | Phase 1 reference — module identification, agent prompt template, synthesis |
| `obsidian-templates.md` | Phase 2 reference — frontmatter schema, audience levels, callouts, Mermaid |
| `output-structure.md` | Phase 2 reference — vault layout, Canvas rules, Index template, state file |

## Development

```
code-to-docs-skill/
├── .claude-plugin/
│   └── plugin.json             # Plugin manifest
├── skills/
│   └── code-to-docs/           # The skill files
├── research/                   # Background research docs
├── tests/                      # Pressure test scenarios
├── docs/superpowers/
│   ├── specs/                  # Design spec
│   └── plans/                  # Implementation plan
└── examples/                   # Example output vaults
```

### Running Pressure Tests

Three test scenarios in `tests/`:

- `pressure-test-quick-mode.md` — validates quick mode on a 3-5 module codebase
- `pressure-test-full-mode.md` — validates full mode additions
- `pressure-test-parallel.md` — validates parallel dispatch discipline on 5+ modules

## Future Enhancements

- Incremental updates via `git diff` + state file
- NanoClaw container compatibility
- Configurable output format (portable markdown vs Obsidian-native)
- Excalidraw diagram generation
- Integration with `obsidian-cli` skill

## License

MIT
