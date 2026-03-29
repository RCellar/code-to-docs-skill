# Pressure Test — Full Mode

**Objective:** Validate the code-to-docs skill in full mode against a complete, real-world codebase. Verify that all quick mode outputs are present and identical, and that full mode-specific outputs (patterns, onboarding, cross-cutting concerns) are generated correctly and follow the schema defined in `obsidian-templates.md` and `output-structure.md`.

---

## Scenario

Run `code-to-docs` in **full mode** against the same codebase used in the quick mode pressure test. The full mode invocation should execute all three phases (Intake & Analysis, Documentation Generation, Verification & Output), populating all directories including `Patterns/`, `Onboarding/`, and `Cross-Cutting/`.

---

## Invocation

```bash
Skill(skill: "code-to-docs", args: "{codebase-path} --mode full")
```

**Expected output location:** `{codebase-path}/docs-vault/`

---

## Expected Behavior

Everything from the quick mode test, **plus** the following Phase 2 full-mode-specific outputs:

### Quick Mode Content (Must be Present & Identical)

- [ ] `Architecture/System Overview.md` exists with complete frontmatter
- [ ] `Architecture/Dependency Map.md` exists with system-wide Mermaid diagram
- [ ] `Architecture/System Map.canvas` exists as valid JSON Canvas format
- [ ] `Modules/` directory contains one `.md` file per identified module
- [ ] Each module doc has three audience levels (Beginner, Intermediate, Advanced)
- [ ] Each module doc has API/function reference section
- [ ] `Index.md` exists with all Dataview queries intact
- [ ] All quick mode files have complete frontmatter with required fields

### Phase 2 Full Mode Output — Patterns

- [ ] `Patterns/` directory exists
- [ ] At least one pattern document exists in `Patterns/`
- [ ] Each pattern doc has `type: pattern` in frontmatter
- [ ] Each pattern doc has `tags: [code-docs, pattern]`
- [ ] Pattern docs are named after the pattern (e.g., `Repository Pattern.md`, `Dependency Injection.md`)
- [ ] Each pattern doc includes:
  - [ ] A clear name and description of the pattern
  - [ ] Section explaining **where in the codebase** the pattern is used
  - [ ] Section explaining **why this pattern fits** this codebase
  - [ ] References to specific module files where the pattern appears (as `[[Module Name]]` wikilinks)
  - [ ] Code snippets or examples showing the pattern in use (if applicable)
- [ ] Pattern docs reference actual code locations via `canonical-source` field
- [ ] All pattern wikilinks resolve to existing module docs

### Phase 2 Full Mode Output — Onboarding

- [ ] `Onboarding/` directory exists
- [ ] `Onboarding/Getting Started.md` exists with `type: onboarding`
- [ ] `Onboarding/First Contribution.md` exists with `type: onboarding`
- [ ] `Onboarding/Debugging Guide.md` exists with `type: onboarding`
- [ ] All three onboarding docs have `tags: [code-docs, onboarding]`

**Getting Started.md content:**
- [ ] Frontmatter includes `canonical-source` (or notes "not applicable" for onboarding)
- [ ] Includes local setup instructions specific to this codebase
- [ ] Prerequisites for development (Node version, package managers, system tools)
- [ ] Step-by-step environment setup (clone, install, verify)
- [ ] First run or smoke test command
- [ ] Links to relevant modules in `Modules/` via wikilinks
- [ ] References to specific build files, package.json, or config files

**First Contribution.md content:**
- [ ] Guided walkthrough of making a first contribution to the codebase
- [ ] Identifies a simple, real starter task (not hypothetical)
- [ ] Step-by-step flow: clone → setup → find file → understand context → make change → test → submit
- [ ] Traces the flow end-to-end through actual module files and APIs
- [ ] References relevant module docs and patterns
- [ ] Explains testing approach for the codebase
- [ ] Points to actual CI/CD or validation steps

**Debugging Guide.md content:**
- [ ] Explains the debugging approach for this codebase
- [ ] References actual tools used (debuggers, logging, profilers)
- [ ] Identifies actual log locations and log file names
- [ ] Describes common failure modes with real examples from the codebase
- [ ] Explains how to trace errors to specific modules (references `Modules/` docs)
- [ ] Includes breakpoint or logging examples specific to the language
- [ ] Links to error handling patterns (e.g., `[[Error Handling Pattern]]`)

### Phase 2 Full Mode Output — Cross-Cutting Concerns

- [ ] `Cross-Cutting/` directory exists **if cross-cutting concerns are identified**
- [ ] Cross-cutting concern docs have `type: cross-cutting`
- [ ] Cross-cutting docs have `tags: [code-docs, cross-cutting]`
- [ ] One file per cross-cutting concern (e.g., `Error Handling.md`, `Logging.md`, `Authentication.md`)
- [ ] Each cross-cutting concern doc includes:
  - [ ] System-wide concern name and what it covers
  - [ ] Which modules participate in this concern (as `[[Module Name]]` wikilinks)
  - [ ] Unified approach or pattern used across the system
  - [ ] Examples of the pattern in different modules
  - [ ] Failure modes or edge cases involving the concern
  - [ ] Testing strategy for the concern

---

## Quality Checks — Full Mode Additions

### Pattern Documentation

- [ ] Pattern docs reference specific code locations (file paths, line numbers where sensible)
- [ ] Pattern identification is specific to this codebase (not generic patterns)
- [ ] Each pattern doc explains both the **template definition** and **application in this codebase**
- [ ] Pattern wikilinks point only to modules that actually use the pattern
- [ ] No "fabricated" patterns — only patterns actually present in the code
- [ ] Pattern names match standard terminology if applicable (Factory, Observer, Repository, etc.)

### Onboarding Documentation

- [ ] Getting Started guide is specific to this codebase, not a generic template
- [ ] Instructions use actual file/tool names from the codebase (not placeholders)
- [ ] First Contribution walkthrough identifies a real, bounded task
- [ ] Debugging guide references actual error messages, log locations, and tools this codebase uses
- [ ] All file paths in onboarding docs are relative to codebase root and correct
- [ ] Setup commands actually run without modification in a fresh environment

### Debugging Guide Specificity

- [ ] Debugging guide includes tool names (e.g., `node --inspect`, `debugpy`, `gdb`)
- [ ] Log locations are actual paths this codebase writes to
- [ ] Failure modes are drawn from actual error handling in the code
- [ ] Error types referenced match actual exception classes or error codes in the codebase
- [ ] Testing approach matches the actual test runner/framework used

### Tutorial Walkthroughs

- [ ] If included, tutorial walkthroughs trace real flows end-to-end through actual code
- [ ] Walkthroughs reference specific module entry points and APIs
- [ ] Each step shows actual code or explains the actual behavior
- [ ] No invented flows — only flows that actually exist in the codebase

---

## Comparison to Quick Mode

### File Identity

- [ ] All quick mode files present in full mode output
- [ ] Quick mode file content is identical (no modifications from full mode)
- [ ] Quick mode files have `mode: quick` in frontmatter (or unchanged from quick mode run)

### Directory Separation

- [ ] `Architecture/`, `Modules/`, `Index.md` are identical to quick mode
- [ ] `Patterns/`, `Onboarding/`, `Cross-Cutting/` directories **only** contain full-mode content
- [ ] No overlapping content between directories

### Index.md Coverage

- [ ] `Index.md` Dataview queries return results from all directories
- [ ] "All Documentation" query lists files from `Patterns/`, `Onboarding/`, `Cross-Cutting/`
- [ ] Status and complexity queries work across all file types
- [ ] Language grouping includes onboarding and cross-cutting docs (if applicable)

---

## Validation Checklist

### Phase 1 (Intake & Analysis)

- [ ] Codebase successfully surveyed (entry points, config identified)
- [ ] 3+ modules identified and independent dispatch used if applicable
- [ ] `_state/analysis.json` written with complete schema
- [ ] All module dependencies correctly mapped

### Phase 2 (Documentation Generation)

- [ ] All files generated with complete frontmatter
- [ ] Mermaid diagrams are syntactically valid
- [ ] Canvas file is valid JSON
- [ ] All wikilinks follow `[[Name]]` format
- [ ] All wikilink targets exist as files
- [ ] Directory structure matches `output-structure.md`
- [ ] File naming follows conventions (Title Case, spaces, illegal chars replaced)

### Phase 3 (Verification & Output)

- [ ] Skill completes without errors
- [ ] Summary report lists:
  - [ ] Total files generated (should be > quick mode count)
  - [ ] Module count
  - [ ] Pattern count (if any)
  - [ ] Onboarding doc count (should be 3 if identified)
  - [ ] Cross-cutting concern count (if any)
  - [ ] Mode: `full`
  - [ ] Estimated token cost
- [ ] No broken wikilinks reported
- [ ] All frontmatter fields present and valid

---

## Success Criteria

✓ **Pass** if:

1. All quick mode files present with identical content
2. `Patterns/` directory populated with pattern docs (≥1) following schema
3. `Onboarding/` directory contains all three guides (Getting Started, First Contribution, Debugging)
4. All onboarding docs are codebase-specific, not generic
5. Debugging guide references actual tools, logs, and failure modes
6. `Cross-Cutting/` directory populated if concerns identified
7. All wikilinks resolve without breakage
8. Index.md Dataview queries return results from all directories
9. Skill completes with summary report
10. No token-efficiency red flags (token usage is reasonable, no unnecessary file reads)

**Fail** if:

- Any quick mode file missing or content modified
- Pattern docs are generic or reference non-existent code locations
- Onboarding guides are templates (not codebase-specific)
- Debugging guide references generic tools or made-up log locations
- Wikilinks are broken
- Phase 3 skips verification steps
- Mode field is not `full` in generated files
