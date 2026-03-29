# Pressure Test: Quick Mode — Scenario Document

## Objective

Validate the `code-to-docs` skill in **quick mode** against a real codebase with 3-5 independent modules and 10-30K lines of code. This test ensures that:

- The skill correctly identifies and isolates modules
- Parallel dispatch launches one agent per module when 3+ modules exist
- Each agent produces a structured analysis report without over-reading
- Synthesis correctly merges module reports into a dependency graph
- Generated documentation is complete, valid, and wikilink-clean
- Quick mode correctly omits Patterns, Onboarding, and Cross-Cutting sections

---

## Phase 0: Setup

### Target Codebase Selection

**Criteria:**
- [ ] 3–5 independently analyzable modules (not just directories)
- [ ] 10–30K total LOC across all modules
- [ ] Mix of entry points (main files, index files, or exports)
- [ ] At least one inter-module dependency (to test dependency graph)
- [ ] Real-world structure (monorepo patterns, microservice layout, or feature-based organization)

### Candidate Codebases

Use one of the following for the test. Record choice in results:

1. **NanoClaw** (`/run/media/system/Dos/Projects/nanoclaw`)
   - Modules: `src/container-runtime`, `src/agents`, `src/channels`, `src/connectors`, `src/setup`
   - LOC: ~15K
   - Language: TypeScript
   - Entry: `src/index.ts`

2. **Dockhand** (`/run/media/system/Dos/Projects/dockhand`)
   - Modules: `src/lib/db`, `src/lib/components`, `src/lib/api`, `src/routes`
   - LOC: ~12K
   - Language: TypeScript/Svelte
   - Entry: `src/app.html`, `src/routes/+page.svelte`

3. **Trayce** (`/run/media/system/Dos/Projects/trayce`)
   - Modules: `packages/server`, `packages/bridge`, `packages/client`
   - LOC: ~8K
   - Language: TypeScript (Bun)
   - Entry: `packages/*/src/index.ts`

4. **Scriptbox** (`/run/media/system/Dos/Projects/scriptbox`)
   - Modules: `src/scheduler`, `src/bot`, `src/executor`, `src/config`
   - LOC: ~10K
   - Language: Python
   - Entry: `src/main.py`

---

## Phase 1: Intake & Analysis

### Survey & Validation

Before invoking the skill, manually verify the target codebase.

**Step 1: Confirm Module Count**

- [ ] Run: `ls -la <codebase>/src/` or appropriate module root
- [ ] List modules identified: _____________________________ (e.g., "auth, payments, scheduler, api, worker")
- [ ] Module count: __________ (should be 3–5)
- [ ] Verify each module has entry point file(s) — record paths:
  - Module 1: ________________________________
  - Module 2: ________________________________
  - Module 3: ________________________________
  - (Module 4: ________________________________)
  - (Module 5: ________________________________)

**Step 2: Rough LOC Estimate**

- [ ] Run: `find <codebase>/src -name "*.ts" -o -name "*.py" -o -name "*.js" | wc -l` (adjust extension)
- [ ] Total file count: __________
- [ ] Rough LOC (estimate): __________ K (should be 10–30K)

**Step 3: Dependency Snapshot**

- [ ] Record primary language(s): ___________________________ (e.g., TypeScript, Python)
- [ ] Record build system: ______________________________ (e.g., npm, poetry, cargo)
- [ ] Identify at least one expected inter-module dependency:
  - Module A → Module B: ________________________________

---

### Invocation

**Step 4: Run the Skill**

```bash
Skill(skill: "code-to-docs", args: "<codebase-path> --mode quick")
```

Record:

- [ ] Invocation timestamp: ____________________________
- [ ] Target codebase: ____________________________
- [ ] Output vault path (from invocation or default): ____________________________
- [ ] Skill completes without error
- [ ] No warnings about missing configuration

**Expected: Quick mode enabled, parallel analysis if 3+ modules.**

---

## Phase 1 Completion: Expected Behavior Checklist

### Survey & Module Identification

- [ ] Survey completes without reading full file contents of any file >500 LOC
- [ ] All 3–5 modules are correctly identified by path
- [ ] Module names are reasonable and match directory/feature names
- [ ] Entry point files are correctly pinpointed
- [ ] No false modules (e.g., build output, `node_modules`, `.git` not counted)

### Parallel Dispatch (if 3+ modules)

- [ ] Skill creates exactly N independent analysis agents (N = number of modules)
- [ ] Each agent receives its module's root path, entry points, and suspected dependencies
- [ ] Agents run in parallel (not sequentially)
- [ ] Completion time is roughly time-of-slowest-agent, not sum of all agents

### Agent Execution

For each module agent, verify:

- [ ] **Module 1:** Agent completes with structured report
  - [ ] Architecture section present (1–2 paragraphs)
  - [ ] Files section lists all module files
  - [ ] Dependencies section identifies imports outside module
  - [ ] Patterns section lists design patterns observed
  - [ ] Complexity assessment provided
  - [ ] Public API section lists exports/entry points

- [ ] **Module 2:** (repeat above)
- [ ] **Module 3:** (repeat above)
- [ ] **(Module 4, 5: as applicable)**

### Synthesis

- [ ] All agent reports are successfully merged
- [ ] Dependency graph correctly reflects inter-module calls
- [ ] No cycles detected (or cycles are documented with warning)
- [ ] Synthesis produces a single coherent architecture narrative
- [ ] `_state/analysis.json` is written to vault root

### State File Validation

- [ ] `_state/analysis.json` exists
- [ ] File is valid JSON
- [ ] Contains fields: `project`, `modules`, `dependency_graph`, `files_analyzed`, `git_commit`, `timestamp`, `mode`
- [ ] `modules` array lists all identified modules by name
- [ ] `dependency_graph` has entries for each module
- [ ] `mode` field equals `"quick"`
- [ ] `git_commit` is set (if codebase is a git repo) or null (otherwise)
- [ ] `timestamp` is ISO 8601 format

---

## Phase 2: Documentation Generation

### Directory & File Structure

- [ ] `Architecture/` directory created
  - [ ] `System Overview.md` exists and is readable
  - [ ] `Dependency Map.md` exists and is readable
  - [ ] `System Map.canvas` exists and is valid JSON Canvas format

- [ ] `Modules/` directory created
  - [ ] One `.md` file per identified module
  - [ ] File names: Title Case with spaces (e.g., `Auth Service.md`, `Payment Gateway.md`)
  - [ ] Total module file count matches identified module count

- [ ] Quick mode: NO additional directories
  - [ ] `Patterns/` does **not** exist
  - [ ] `Onboarding/` does **not** exist
  - [ ] `Cross-Cutting/` does **not** exist

- [ ] `Index.md` exists in vault root
- [ ] `_state/analysis.json` exists in `_state/` subdirectory

### System Overview.md

- [ ] File exists at: `Architecture/System Overview.md`
- [ ] Contains frontmatter with fields: `title`, `type`, `generated-by`, `generated-at`, `mode`, `language`, `status`
- [ ] Frontmatter `type` field = `"architecture"`
- [ ] Frontmatter `mode` field = `"quick"`
- [ ] Has `#code-docs` and `#architecture` tags
- [ ] Narrative section (1–3 paragraphs) describes overall system purpose
- [ ] Identifies all 3–5 modules by name
- [ ] Includes Mermaid flowchart or graph showing module relationships
- [ ] Mermaid diagram renders without syntax errors (test in Obsidian or online editor)

### Dependency Map.md

- [ ] File exists at: `Architecture/Dependency Map.md`
- [ ] Contains frontmatter with fields: `title`, `type`, `generated-by`, `generated-at`
- [ ] Frontmatter `type` field = `"dependency-map"`
- [ ] Has `#code-docs` and `#dependencies` tags
- [ ] Contains large Mermaid graph showing all modules and their dependencies
- [ ] Every identified module appears as a node
- [ ] Every edge is labeled with relationship type (e.g., "calls", "depends on", "imports")
- [ ] Mermaid renders without errors

### System Map.canvas

- [ ] File exists at: `Architecture/System Map.canvas`
- [ ] File is valid JSON (test with `jq . Architecture/System\ Map.canvas` or equivalent)
- [ ] Contains `nodes` array with one entry per module
  - [ ] Each node has `id`, `type`, `file`, `x`, `y`, `width`, `height` fields
  - [ ] `type` is `"file"` for all module nodes
  - [ ] `file` paths are correct (e.g., `"Modules/Auth Service.md"`)
- [ ] Contains `edges` array with entries for each module dependency
  - [ ] Each edge has `id`, `fromNode`, `fromSide`, `toNode`, `toSide`, `label` fields
  - [ ] `label` describes relationship type
- [ ] Nodes are arranged by topological depth (dependencies-first layers)
- [ ] Horizontal spacing: ~300px between columns
- [ ] Vertical spacing: ~150px between rows
- [ ] Canvas opens in Obsidian Canvas editor without errors

### Module Documentation Files

For **each** identified module, verify file at `Modules/{Module Name}.md`:

- [ ] **Module 1: {Name}**
  - [ ] File exists and is readable
  - [ ] Frontmatter present with fields: `title`, `type`, `language`, `complexity`, `status`, `generated-by`, `generated-at`
  - [ ] Frontmatter `type` = `"module"`
  - [ ] Frontmatter `language` = correct language (e.g., "TypeScript", "Python")
  - [ ] Frontmatter `complexity` = "low", "medium", or "high" (justified by module size and nesting)
  - [ ] Has tags: `#code-docs`, `#module`, `#language-<lang>` (e.g., `#language-typescript`)
  - [ ] Contains section: **Overview** (1–2 paragraphs describing module purpose)
  - [ ] Contains section: **Architecture** (describes internal structure, patterns, entry points)
  - [ ] Contains section: **Beginner** (explains language constructs, basic flow, simple examples)
  - [ ] Contains section: **Intermediate** (discusses patterns, integration points, configuration)
  - [ ] Contains section: **Advanced** (covers edge cases, failure modes, concurrency, performance)
  - [ ] Contains section: **API Reference** (lists public exports, key classes/functions with signatures)
  - [ ] Contains section: **Related** (wikilinks to dependent modules and upstream dependencies)
  - [ ] All sections use wikilinks to other module docs (e.g., `[[Auth Service]]`, `[[Dependency Map]]`)
  - [ ] No fabricated information (e.g., "Rationale not documented" if source doesn't explain design choice)

- [ ] **Module 2: {Name}** (repeat above)
- [ ] **Module 3: {Name}** (repeat above)
- [ ] **(Module 4, 5: as applicable)**

---

### Index.md

- [ ] File exists at: `Index.md` in vault root
- [ ] Contains frontmatter: `title`, `type`, `generated-by`, `generated-at`, `mode`
- [ ] Frontmatter `type` = `"index"`
- [ ] Frontmatter `mode` = `"quick"`
- [ ] Contains Dataview query block: "Modules by Complexity"
  - [ ] Query uses tags `#code-docs` and `#module`
  - [ ] Query selects `title`, `language`, `complexity`, `status`
  - [ ] Sorts by `complexity DESC`
- [ ] Contains Dataview query block: "Modules by Language"
  - [ ] Groups by `language`
  - [ ] Selects `title`, `complexity`, `status`
- [ ] Contains Dataview query block: "Documentation Status"
  - [ ] Filters for `status != "generated"` (or similar)
  - [ ] Sorts by file name
- [ ] Contains Dataview query block: "All Documentation"
  - [ ] Selects `title`, `type`, `generated-at`
  - [ ] Sorts by `generated-at DESC`
- [ ] All Dataview queries are syntactically valid (test in Obsidian Dataview plugin)

---

## Phase 3: Verification & Output

### Wikilink Validation

For **every** wikilink in every generated file:

- [ ] Verify link target exists as a generated `.md` or `.canvas` file
- [ ] Test in Obsidian: click each wikilink and confirm it resolves
- [ ] Count total wikilinks: __________
- [ ] Count broken wikilinks: __________ (should be 0)
- [ ] Document any broken links:
  - Link: ________________ → Target: ________________ (Status: broken/fixed)
  - (repeat as needed)

### Frontmatter Validation

For **every** generated file:

- [ ] Verify frontmatter is valid YAML (test with `yq . <file>` or Obsidian frontmatter viewer)
- [ ] Verify frontmatter contains all required fields for file type:
  - Architecture files: `title`, `type`, `generated-by`, `generated-at`, `mode`, `language`, `status`
  - Module files: `title`, `type`, `language`, `complexity`, `status`, `generated-by`, `generated-at`
  - Index file: `title`, `type`, `generated-by`, `generated-at`, `mode`
  - State file: (JSON, not frontmatter)

- [ ] No missing or malformed frontmatter blocks (no `---` at end, etc.)
- [ ] All frontmatter values match schema types (strings, not arrays unless specified)

### Mermaid Diagram Validation

For **each** Mermaid block in `System Overview.md` and `Dependency Map.md`:

- [ ] Copy Mermaid block verbatim
- [ ] Test in [mermaid.live](https://mermaid.live)
- [ ] Diagram renders without syntax errors
- [ ] All module names are correctly spelled and match module list
- [ ] All edges have descriptive labels

### Canvas Validation

For `Architecture/System Map.canvas`:

- [ ] File is valid JSON: `jq . Architecture/System\ Map.canvas > /dev/null` succeeds
- [ ] JSON structure has required top-level keys: `nodes`, `edges`
- [ ] All node `file` paths reference valid module files
- [ ] All node coordinates are numbers (not strings)
- [ ] All edge `fromNode` and `toNode` IDs match existing node IDs
- [ ] Canvas opens in Obsidian Canvas without errors (or web-based viewer)

---

## Phase 4: Quality Analysis

### Beginner Section Quality

For **each module's Beginner section**, verify:

- [ ] Explains language constructs relevant to the module (e.g., async/await, decorators, closures, error handling)
- [ ] Provides simple examples (not pseudocode) from the actual codebase
- [ ] Defines unfamiliar terminology inline (e.g., "middleware," "dependency injection")
- [ ] Does not assume advanced knowledge
- [ ] Beginner section is **different** from Intermediate section (distinct focus)

### Intermediate Section Quality

For **each module's Intermediate section**, verify:

- [ ] Discusses design patterns used in the module (e.g., Repository, Factory, Observer)
- [ ] Explains how this module integrates with other modules
- [ ] Covers configuration and customization points
- [ ] Discusses error handling and edge cases at a design level
- [ ] Intermediate section is **different** from Advanced section (design, not failure modes)

### Advanced Section Quality

For **each module's Advanced section**, verify:

- [ ] Covers concurrency, parallelization, or async complexity
- [ ] Discusses performance implications and bottlenecks
- [ ] Explains failure modes and recovery strategies
- [ ] Addresses resource management (memory, database connections, file handles)
- [ ] Documents known limitations or TODOs in the codebase
- [ ] Advanced section is **not identical** to Intermediate section

### No Fabrication

For **each module**, check:

- [ ] If a design decision is not documented in comments or README, the doc says "Rationale not documented" (not invented)
- [ ] No speculative statements like "likely intended for..." or "probably handles..."
- [ ] Every assertion about behavior is traceable to code or explicit documentation
- [ ] Example code snippets are exact copies from the codebase (not paraphrased)

---

## Phase 5: Red Flag Violations

### Critical Violations (Skill Failure)

If **any** of the following occur, the skill has a critical bug:

- [ ] **Agent reads >500 lines without grep-filtering first**
  - How to detect: Agent logs show `Read(file_path: "...")` for a file known to exceed 500 LOC without prior Grep call
  - Impact: Token waste, incomplete analysis
  - Status: FAIL

- [ ] **3+ modules analyzed sequentially instead of parallel**
  - How to detect: Invocation outputs "Analyzing Module 1... done. Analyzing Module 2..." linearly, not in parallel
  - Impact: Skill fails to meet performance SLA
  - Status: FAIL

- [ ] **Agent reads `node_modules/`, `vendor/`, `.git/`, or build output**
  - How to detect: Files like `node_modules/package/index.js` or `.git/HEAD` are mentioned in agent output
  - Impact: Incorrect analysis, token waste, potential confusion
  - Status: FAIL

- [ ] **Missing frontmatter in any generated file**
  - How to detect: Opening a `.md` file in Obsidian or text editor shows no `---` block at top
  - Impact: Dataview queries fail, metadata missing
  - Status: FAIL

- [ ] **Broken wikilinks (targets don't exist)**
  - How to detect: Wikilink in `Modules/A.md` points to `[[Nonexistent Module]]` but no such file exists
  - Impact: Vault is unusable in Obsidian
  - Status: FAIL

### Pattern Violations (Design Issues)

If **any** of the following occur, the skill output has quality issues:

- [ ] **Patterns/, Onboarding/, Cross-Cutting/ directories exist in quick mode**
  - Expected: Quick mode should **not** create these directories
  - Status: WARN / FAIL (depending on severity)

- [ ] **Module file sections missing or incomplete**
  - Check: Every module file has all seven sections (Overview, Architecture, Beginner, Intermediate, Advanced, API Reference, Related)
  - Status: FAIL if any section missing

- [ ] **Beginner section is identical to Intermediate**
  - How to detect: Copy text from Beginner section, find it verbatim in Intermediate section
  - Status: FAIL (indicates insufficient analysis)

- [ ] **Advanced section is identical to Intermediate**
  - How to detect: Same check as above
  - Status: FAIL

- [ ] **Canvas nodes reference non-existent files**
  - How to detect: `jq '.nodes[] | .file' Architecture/System\ Map.canvas` returns a path like `Modules/Fake.md` but file doesn't exist
  - Status: FAIL

- [ ] **Mermaid diagram syntax errors**
  - How to detect: Pasting diagram into mermaid.live shows error
  - Status: FAIL

- [ ] **Fabricated design rationale**
  - How to detect: Looking at source code, a statement like "This uses the Facade pattern" is unsupported
  - Status: FAIL

---

## Results Template

Document results in this section after running the test:

### Execution Summary

- **Codebase tested:** _________________________________________________________
- **Modules identified:** ____________________________________________________
- **Total LOC:** _______________________
- **Invocation timestamp:** ______________________
- **Vault path:** ______________________________________________________________
- **Execution time:** ________________ seconds
- **Mode:** quick

### Phase 1 Results

- **Survey completed:** [ ] Yes  [ ] No
- **Module count:** __________ (expected: 3–5)
- **Agents dispatched:** __________ (expected: 3–5)
- **Parallel execution:** [ ] Yes  [ ] No (expected: Yes if 3+)
- **State file written:** [ ] Yes  [ ] No
- **Phase 1 status:** [ ] PASS  [ ] FAIL

### Phase 2 Results

- **Architecture/ directory:** [ ] Complete  [ ] Incomplete
- **Modules/ directory:** [ ] Complete  [ ] Incomplete
- **Module files generated:** __________ / __________ (actual / expected)
- **Index.md generated:** [ ] Yes  [ ] No
- **Unwanted directories (Patterns, Onboarding, Cross-Cutting):** [ ] None (correct)  [ ] Present (incorrect)
- **Phase 2 status:** [ ] PASS  [ ] FAIL

### Phase 3 Results

- **Total wikilinks:** __________
- **Broken wikilinks:** __________ (expected: 0)
- **Frontmatter validation:** [ ] All valid  [ ] Some invalid (list below)
- **Mermaid diagrams:** [ ] All valid  [ ] Some invalid (list below)
- **Canvas validation:** [ ] Valid  [ ] Invalid (list issues below)
- **Phase 3 status:** [ ] PASS  [ ] FAIL

### Quality Analysis Results

- **Beginner sections:** [ ] Adequate  [ ] Poor (specify issues)
- **Intermediate sections:** [ ] Adequate  [ ] Poor (specify issues)
- **Advanced sections:** [ ] Adequate  [ ] Poor (specify issues)
- **No fabrication detected:** [ ] Yes  [ ] No (specify instances)

### Red Flag Assessment

- **Critical violations:** [ ] None  [ ] Found (list below)
- **Pattern violations:** [ ] None  [ ] Found (list below)
- **Overall status:** [ ] PASS  [ ] FAIL

### Issues Found (if any)

| Category | Description | Severity | Resolution |
|----------|-------------|----------|-----------|
| (example: Red Flag) | Agent read 2000-line file without grep | CRITICAL | Re-run with grep-first enforcement |
| | | | |
| | | | |

### Recommendations for Next Test

- [ ] Increase LOC range to 30–50K
- [ ] Test with 5+ modules
- [ ] Test with more complex dependency graphs (cycles, many cross-cutting concerns)
- [ ] Test full mode after quick mode passes
- [ ] Test incremental mode (state file consumption)

---

## Sign-Off

- **Test executed by:** ____________________________________
- **Date:** _________________________
- **Status:** [ ] PASS  [ ] FAIL
- **Ready for next phase:** [ ] Yes  [ ] No

**Notes:**

_________________________________________________________________

_________________________________________________________________

_________________________________________________________________
