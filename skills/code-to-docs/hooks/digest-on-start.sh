#!/usr/bin/env bash
# code-to-docs: SessionStart hook — injects vault context into Claude's conversation.
# Stdout from this script is automatically added to Claude's context.
# This script is READ-ONLY — it never modifies the vault.

set -euo pipefail

VAULT_PATH="${CODE_TO_DOCS_VAULT:-.}"

STATE_FILE="$VAULT_PATH/docs-vault/_state/analysis.json"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "[code-to-docs] No documentation vault found at $VAULT_PATH/docs-vault/ — run /code-to-docs to generate one."
    exit 0
fi

# Extract key fields from state file
PROJECT=$(python3 -c "import json,sys; d=json.load(open('$STATE_FILE')); print(d.get('project','unknown'))" 2>/dev/null || echo "unknown")
MODULES=$(python3 -c "import json,sys; d=json.load(open('$STATE_FILE')); print(', '.join(d.get('modules',[])))" 2>/dev/null || echo "unknown")
COMMIT=$(python3 -c "import json,sys; d=json.load(open('$STATE_FILE')); print(d.get('git_commit','unknown')[:8])" 2>/dev/null || echo "unknown")
TIMESTAMP=$(python3 -c "import json,sys; d=json.load(open('$STATE_FILE')); print(d.get('timestamp','unknown'))" 2>/dev/null || echo "unknown")
MODE=$(python3 -c "import json,sys; d=json.load(open('$STATE_FILE')); print(d.get('mode','unknown'))" 2>/dev/null || echo "unknown")
ISSUE_COUNT=$(python3 -c "import json,sys; d=json.load(open('$STATE_FILE')); print(len([i for i in d.get('issues',[]) if i.get('status')=='open']))" 2>/dev/null || echo "0")

# Check staleness
CURRENT_HEAD=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

cat <<EOF
[code-to-docs] Project documentation available for: $PROJECT
  Modules: $MODULES
  Last run: $TIMESTAMP ($MODE mode) at commit $COMMIT
  Current HEAD: $CURRENT_HEAD
  Open issues: $ISSUE_COUNT

To load full context, run: /code-to-docs --digest ./docs-vault
To load specific modules: /code-to-docs --digest ./docs-vault --scope {module names}
To see known issues: /code-to-docs --digest ./docs-vault --focus issues
EOF

if [[ "$COMMIT" != "unknown" && "$CURRENT_HEAD" != "unknown" && "$COMMIT" != "$CURRENT_HEAD" ]]; then
    CHANGES=$(git diff --stat "${COMMIT}..HEAD" -- . ':!docs-vault' 2>/dev/null | tail -1 || echo "")
    if [[ -n "$CHANGES" ]]; then
        echo "  Documentation may be stale — $CHANGES since last run."
        echo "  Run /code-to-docs --update after your work to sync."
    fi
fi
