#!/usr/bin/env python3
"""
Hook to require confirmation for non-GET gh api calls.
"""

import json
import re
import sys


def main():
    try:
        input_data = json.loads(sys.stdin.read())
    except json.JSONDecodeError:
        sys.exit(0)  # Allow if can't parse

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool_name != "Bash":
        sys.exit(0)

    command = tool_input.get("command", "")

    # Check if it's a gh api command
    if not re.search(r'\bgh\s+api\b', command):
        sys.exit(0)

    # Check for explicit method flags
    # -X or --method followed by the method
    method_match = re.search(r'(?:-X|--method)\s+(\w+)', command)

    if method_match:
        method = method_match.group(1).upper()
        if method != "GET":
            print(f"This gh api call uses {method} method (not GET). Please confirm this is intended.", file=sys.stderr)
            sys.exit(2)  # Block - requires user confirmation

    # Also check for common mutating patterns without explicit -X
    # gh api defaults to GET, but POST is used when --field or -f is present
    if re.search(r'\s+(-f|--field|-F|--raw-field)\s+', command):
        print("This gh api call includes field data which typically implies a POST request. Please confirm this is intended.", file=sys.stderr)
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
