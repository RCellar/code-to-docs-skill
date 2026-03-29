#!/usr/bin/env bash
# code-to-docs: PostToolUse hook — reminds Claude to suggest --update after git commits.
# Stdout from this script is added to Claude's context.
# Only fires on Bash tool calls matching "git commit".

set -euo pipefail

VAULT_PATH="${CODE_TO_DOCS_VAULT:-.}"
STATE_FILE="$VAULT_PATH/docs-vault/_state/analysis.json"

# Only produce output if a vault exists
if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

echo "[code-to-docs] Code was just committed. When the coding session is complete, consider running /code-to-docs --update to sync documentation with the latest changes."
