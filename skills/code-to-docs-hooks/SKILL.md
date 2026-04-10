---
name: hooks
description: >
  Install or remove project-level automation hooks for the code-to-docs lifecycle.
  Setup adds SessionStart (digest on session start) and PostToolUse (update hint
  after git commits) hooks. Teardown removes only code-to-docs hooks.
  Use when someone wants to automate doc updates, set up hooks, or remove hooks.
---

# Hooks

Install or remove project-level hooks that automate the code-to-docs lifecycle. Hooks are written to `.claude/settings.json`. Project-local, read-only, non-destructive.

## Related Skills

| Skill | Purpose |
|-------|---------|
| `code-to-docs` | Full documentation generation |
| `code-to-docs:digest` | What the SessionStart hook triggers |
| `code-to-docs:update` | What the PostToolUse hook reminds about |

## Invocation

```
Skill(skill: "code-to-docs:hooks", args: "setup [vault-path]")
Skill(skill: "code-to-docs:hooks", args: "teardown")
```

## Setup

Run the setup script to install both hooks:

```bash
bash skills/code-to-docs-hooks/hooks/setup.sh [vault-path]
```

This installs two hooks into `.claude/settings.json`:

| Hook | Type | Script | Purpose |
|------|------|--------|---------|
| digest-on-start | SessionStart | `digest-on-start.sh` | Run digest at the start of each session |
| update-hint-on-commit | PostToolUse | `update-hint-on-commit.sh` | Remind to update docs after git commits |

## Teardown

Run the teardown script to remove code-to-docs hooks:

```bash
bash skills/code-to-docs-hooks/hooks/teardown.sh
```

Removes hooks by matching the `source` field. Other hooks in settings.json are left untouched.

## Environment

Set `CODE_TO_DOCS_VAULT` to override the default vault path. This is picked up by both setup and the hook scripts themselves.

## Hook Scripts

| Script | Purpose |
|--------|---------|
| `setup.sh` | Install SessionStart and PostToolUse hooks into `.claude/settings.json` |
| `teardown.sh` | Remove code-to-docs hooks from `.claude/settings.json` by source field |
| `digest-on-start.sh` | SessionStart hook — triggers digest skill on session open |
| `update-hint-on-commit.sh` | PostToolUse hook — prints update reminder after git commit operations |
