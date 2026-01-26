#!/bin/bash

# Settings Manager - DEPRECATED
#
# This file previously managed apiKeyHelper in settings.json.
# That approach had session isolation issues - modifications to settings.json
# are global and persist after process exit, breaking other Claude sessions.
#
# The new approach uses pure environment variables for session-isolated auth:
# - ANTHROPIC_API_KEY is exported directly from the provider setup
# - No settings.json modifications are made
# - Each ai session has its own environment, isolated from other sessions
# - Crashes leave no stale state
#
# These functions are kept as no-ops for backward compatibility.

# No-op: Previously saved apiKeyHelper state before modifying
save_api_key_helper_state() {
    :  # No-op - no longer needed
}

# No-op: Previously restored apiKeyHelper state on exit
restore_api_key_helper_state() {
    :  # No-op - no longer needed
}

# No-op: Previously added apiKeyHelper to settings.json
add_api_key_helper() {
    :  # No-op - no longer needed
    return 0
}

# No-op: Previously checked if apiKeyHelper was configured
is_api_key_helper_configured() {
    return 1  # Always return false - apiKeyHelper is no longer used
}
