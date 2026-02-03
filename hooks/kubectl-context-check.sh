#!/bin/bash

# Claude Code PreToolUse hook for context-aware kubectl permissions
# - Local contexts (kind-*, orbstack): auto-allow all kubectl commands
# - Staging/Prod contexts: require permission for dangerous commands

INPUT=$(cat)

# Extract the command from hook input
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Only process kubectl commands
if ! echo "$COMMAND" | grep -qE "^kubectl "; then
    exit 0
fi

# Read-only commands - let normal permission flow handle these
if echo "$COMMAND" | grep -qE "^kubectl (get|describe|logs|top|config|api-resources|explain|version|cluster-info) "; then
    exit 0
fi

# Get current kubectl context
CURRENT_CONTEXT=$(kubectl config current-context 2>/dev/null)

# Local/dev contexts - auto-allow everything
LOCAL_CONTEXTS="^(kind-|orbstack|docker-desktop|minikube)"

if echo "$CURRENT_CONTEXT" | grep -qE "$LOCAL_CONTEXTS"; then
    jq -n \
        --arg reason "Local context ($CURRENT_CONTEXT) - auto-approved" \
        '{
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "allow",
                "permissionDecisionReason": $reason
            }
        }'
    exit 0
fi

# Staging/production - require permission for dangerous commands
if echo "$COMMAND" | grep -qE "^kubectl (delete|exec|apply|patch|edit|create|replace|scale|rollout|drain|cordon|uncordon|taint) "; then
    jq -n \
        --arg context "$CURRENT_CONTEXT" \
        '{
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": "Non-local context (\($context)) - confirming dangerous kubectl operation"
            }
        }'
    exit 0
fi

# Default - allow normal permission flow
exit 0
