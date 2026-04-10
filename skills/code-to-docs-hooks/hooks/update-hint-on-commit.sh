#!/usr/bin/env bash
# code-to-docs: PostToolUse hook — reminds Claude to suggest :update after git commits.
# Stdout from this script is added to Claude's context.
# Fires on all Bash tool calls; checks stdin for "git commit" in the command.

set -euo pipefail

VAULT_PATH="${CODE_TO_DOCS_VAULT:-./docs-vault}"
STATE_FILE="$VAULT_PATH/_state/analysis.json"

# Only produce output if a vault exists
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

# Check if the Bash command contained "git commit"
COMMAND=$(python3 -c "import json,sys; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null <<< "$(cat)" || echo "")
if [[ "$COMMAND" != *"git commit"* ]]; then
    exit 0
fi

echo "[code-to-docs] Code was just committed. When the coding session is complete, consider running /code-to-docs:update to sync documentation with the latest changes."
