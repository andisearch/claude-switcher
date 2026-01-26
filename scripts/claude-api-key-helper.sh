#!/bin/bash

# API Key Helper - DEPRECATED
#
# This script is no longer used. AI Runner now uses pure environment variables
# for session-isolated authentication, avoiding all settings.json modifications.
#
# If this script is still referenced in your ~/.claude/settings.json, please
# remove the apiKeyHelper line. Running './setup.sh' or './uninstall.sh' will
# clean this up automatically.
#
# The new approach:
# - 'ai --apikey' exports ANTHROPIC_API_KEY directly (session-isolated)
# - 'ai --pro' unsets ANTHROPIC_API_KEY to use subscription auth
# - No files are modified, so crashes leave no stale state
# - Parallel Claude sessions work independently

# Exit with error to indicate this should not be used
echo "Warning: claude-api-key-helper.sh is deprecated and should not be used." >&2
echo "Please run './setup.sh' to update your installation." >&2
exit 1
