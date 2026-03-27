#!/usr/bin/env bash
# Finds all .sh files under ~/.claude that are not executable and makes them executable.
# Also checks for known extensionless hook scripts (e.g. "session-start").

set -euo pipefail

SEARCH_DIR="${HOME}/.claude"
FIXED=0

# Fix .sh files
while IFS= read -r -d '' file; do
  chmod +x "$file"
  echo "Fixed: $file"
  FIXED=$((FIXED + 1))
done < <(find "$SEARCH_DIR" -name "*.sh" ! -executable -print0 2>/dev/null)

# Fix known extensionless hook scripts
for name in session-start stop-hook; do
  while IFS= read -r -d '' file; do
    if [ ! -x "$file" ]; then
      chmod +x "$file"
      echo "Fixed: $file"
      FIXED=$((FIXED + 1))
    fi
  done < <(find "$SEARCH_DIR" -name "$name" -type f -print0 2>/dev/null)
done

if [ "$FIXED" -eq 0 ]; then
  echo "All hook scripts are already executable."
else
  echo "Fixed $FIXED file(s)."
fi
