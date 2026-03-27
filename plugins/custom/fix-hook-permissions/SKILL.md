---
name: fix-hook-permissions
description: Fix non-executable hook scripts under ~/.claude that cause "Permission denied" errors. Use this skill whenever you see hook permission errors on startup or stop, or when the user mentions hook errors, "Permission denied" on hooks, or asks to fix plugin hook permissions. Also use proactively after plugin installation or updates, since newly fetched plugin files often lack the execute bit.
---

# Fix Hook Permissions

Plugin hooks (`.sh` files and extensionless scripts like `session-start`) under `~/.claude/` sometimes lose their execute permission after plugin installs or updates. This causes "Permission denied" errors when Claude Code tries to run SessionStart, Stop, or PreToolUse hooks.

## How to fix

Run the bundled script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/fix-permissions.sh"
```

This script:
1. Finds all `.sh` files under `~/.claude` that are not executable
2. Finds known extensionless hook scripts (`session-start`, `stop-hook`)
3. Makes them all executable
4. Reports what it fixed

The script is safe to run repeatedly - it only touches files that need fixing.

## When to use

- User reports "Permission denied" errors from hooks
- You see hook errors in startup/stop output
- After installing or updating plugins
- User asks to fix hook or plugin permissions
