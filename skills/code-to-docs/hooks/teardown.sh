#!/usr/bin/env bash
# code-to-docs: Hook teardown script
# Removes code-to-docs hooks from the project's .claude/settings.json

set -euo pipefail

PROJECT_SETTINGS=".claude/settings.json"

if [[ ! -f "$PROJECT_SETTINGS" ]]; then
    echo "No $PROJECT_SETTINGS found — nothing to remove."
    exit 0
fi

python3 -c "
import json

settings = json.load(open('$PROJECT_SETTINGS'))
hooks = settings.get('hooks', {})
removed = 0

for event in list(hooks.keys()):
    original_len = len(hooks[event])
    hooks[event] = [
        h for h in hooks[event]
        if 'code-to-docs' not in str(h.get('hooks', [{}])[0].get('command', ''))
    ]
    removed += original_len - len(hooks[event])
    # Remove empty event arrays
    if not hooks[event]:
        del hooks[event]

# Remove empty hooks object
if not hooks and 'hooks' in settings:
    del settings['hooks']

# Remove file entirely if empty (only {} left)
if settings == {} or settings == {'hooks': {}}:
    import os
    os.remove('$PROJECT_SETTINGS')
    print(f'Removed {removed} code-to-docs hook(s). Deleted empty $PROJECT_SETTINGS.')
else:
    json.dump(settings, open('$PROJECT_SETTINGS', 'w'), indent=2)
    print(f'Removed {removed} code-to-docs hook(s) from $PROJECT_SETTINGS.')
" 2>&1
