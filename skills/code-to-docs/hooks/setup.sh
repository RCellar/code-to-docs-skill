#!/usr/bin/env bash
# code-to-docs: Hook setup script
# Installs SessionStart and PostToolUse hooks into the project's .claude/settings.json
#
# Usage:
#   ./setup.sh [vault-path]
#
# vault-path defaults to ./docs-vault (same as code-to-docs --output default).
# Set CODE_TO_DOCS_VAULT env var for non-standard vault locations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_PATH="${1:-./docs-vault}"
PROJECT_SETTINGS=".claude/settings.json"

# Resolve absolute path to hook scripts
DIGEST_HOOK="$SCRIPT_DIR/digest-on-start.sh"
UPDATE_HOOK="$SCRIPT_DIR/update-hint-on-commit.sh"

if [[ ! -f "$DIGEST_HOOK" ]]; then
    echo "Error: Cannot find $DIGEST_HOOK"
    echo "Run this script from the code-to-docs hooks directory or ensure the skill is installed."
    exit 1
fi

# Ensure hooks are executable
chmod +x "$DIGEST_HOOK" "$UPDATE_HOOK"

# Ensure .claude directory exists
mkdir -p .claude

# Build the hooks JSON fragment and write to temp file (avoids string escaping issues)
HOOKS_TMPFILE=$(mktemp)
trap 'rm -f "$HOOKS_TMPFILE"' EXIT

cat > "$HOOKS_TMPFILE" <<HOOKEOF
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "CODE_TO_DOCS_VAULT='$VAULT_PATH' bash '$DIGEST_HOOK'",
            "source": "code-to-docs",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "if": "Bash(git commit*)",
            "command": "CODE_TO_DOCS_VAULT='$VAULT_PATH' bash '$UPDATE_HOOK'",
            "source": "code-to-docs",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
HOOKEOF

# Merge with existing settings or create new
if [[ -f "$PROJECT_SETTINGS" ]]; then
    # Merge hooks into existing settings using Python (available everywhere)
    python3 -c "
import json, sys

existing = json.load(open('$PROJECT_SETTINGS'))
new_hooks = json.load(open('$HOOKS_TMPFILE'))

# Merge hooks — append to existing arrays, don't replace
if 'hooks' not in existing:
    existing['hooks'] = {}

for event, handlers in new_hooks['hooks'].items():
    if event not in existing['hooks']:
        existing['hooks'][event] = []
    # Check for duplicates by source marker
    existing_sources = set()
    for h in existing['hooks'][event]:
        for hook in h.get('hooks', []):
            if hook.get('source') == 'code-to-docs':
                existing_sources.add(event)
    if event not in existing_sources:
        existing['hooks'][event].extend(handlers)

json.dump(existing, open('$PROJECT_SETTINGS', 'w'), indent=2)
print('Merged code-to-docs hooks into existing $PROJECT_SETTINGS')
" HOOKS_TMPFILE="$HOOKS_TMPFILE" 2>&1
else
    python3 -c "import json,sys; json.dump(json.load(open('$HOOKS_TMPFILE')), open('$PROJECT_SETTINGS','w'), indent=2)" HOOKS_TMPFILE="$HOOKS_TMPFILE"
    echo "Created $PROJECT_SETTINGS with code-to-docs hooks"
fi

echo ""
echo "Hooks installed:"
echo "  SessionStart → digest vault summary on session start"
echo "  PostToolUse  → update hint after git commits"
echo ""
echo "Vault path: $VAULT_PATH"
echo ""
echo "To remove hooks: run teardown.sh from this directory"
echo "To customize: edit $PROJECT_SETTINGS directly"
