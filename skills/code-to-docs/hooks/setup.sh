#!/usr/bin/env bash
# code-to-docs: Hook setup script
# Installs SessionStart and PostToolUse hooks into the project's .claude/settings.json
#
# Usage:
#   ./setup.sh [vault-path]
#
# vault-path defaults to current directory.
# Set CODE_TO_DOCS_VAULT env var for non-standard vault locations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VAULT_PATH="${1:-.}"
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

# Build the hooks JSON fragment
HOOKS_JSON=$(cat <<HOOKEOF
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "CODE_TO_DOCS_VAULT='$VAULT_PATH' bash '$DIGEST_HOOK'",
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
            "timeout": 5
          }
        ]
      }
    ]
  }
}
HOOKEOF
)

# Merge with existing settings or create new
if [[ -f "$PROJECT_SETTINGS" ]]; then
    # Merge hooks into existing settings using Python (available everywhere)
    python3 -c "
import json, sys

existing = json.load(open('$PROJECT_SETTINGS'))
new_hooks = json.loads('''$HOOKS_JSON''')

# Merge hooks — append to existing arrays, don't replace
if 'hooks' not in existing:
    existing['hooks'] = {}

for event, handlers in new_hooks['hooks'].items():
    if event not in existing['hooks']:
        existing['hooks'][event] = []
    # Check for duplicates by command string
    existing_cmds = {h.get('hooks', [{}])[0].get('command', '') for h in existing['hooks'][event] if h.get('hooks')}
    for handler in handlers:
        cmd = handler.get('hooks', [{}])[0].get('command', '')
        if cmd and cmd not in existing_cmds:
            existing['hooks'][event].append(handler)

json.dump(existing, open('$PROJECT_SETTINGS', 'w'), indent=2)
print('Merged code-to-docs hooks into existing $PROJECT_SETTINGS')
" 2>&1
else
    echo "$HOOKS_JSON" | python3 -c "import json,sys; json.dump(json.load(sys.stdin), open('$PROJECT_SETTINGS','w'), indent=2)"
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
