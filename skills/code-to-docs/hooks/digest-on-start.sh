#!/usr/bin/env bash
# code-to-docs: SessionStart hook — injects vault context into Claude's conversation.
# Stdout from this script is automatically added to Claude's context.
# This script is READ-ONLY — it never modifies the vault.

set -euo pipefail

VAULT_PATH="${CODE_TO_DOCS_VAULT:-./docs-vault}"

STATE_FILE="$VAULT_PATH/_state/analysis.json"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "[code-to-docs] No documentation vault found at $VAULT_PATH — run /code-to-docs to generate one."
    exit 0
fi

# Extract key fields from state file (single python3 invocation)
IFS=$'\t' read -r PROJECT MODULES COMMIT TIMESTAMP MODE ISSUE_COUNT <<< "$(
    python3 -c "
import json
d = json.load(open('$STATE_FILE'))
project = d.get('project', 'unknown')
modules = ', '.join(d.get('modules', []))
commit = d.get('git_commit', 'unknown')[:8]
timestamp = d.get('timestamp', 'unknown')
mode = d.get('mode', 'unknown')
issue_count = len([i for i in d.get('issues', []) if i.get('status') == 'open'])
print(f'{project}\t{modules}\t{commit}\t{timestamp}\t{mode}\t{issue_count}')
" 2>/dev/null || echo "unknown	unknown	unknown	unknown	unknown	0"
)"

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
