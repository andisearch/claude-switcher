#!/bin/bash

# Tool Base Interface
# All tools must implement these functions

# Tool Interface Functions:
#
# tool_name()                  - Return human-readable tool name
# tool_flag()                  - Return CLI flag/shorthand (e.g., "cc", "opencode")
# tool_command()               - Return actual CLI command to execute
# tool_is_installed()          - Check if tool is installed (return 0=yes, 1=no)
# tool_supported_providers()   - Return list of compatible provider flags
# tool_execute_interactive()   - Run tool in interactive mode
# tool_execute_prompt()        - Run tool with a prompt (shebang/piped mode)
# tool_setup_env()             - Tool-specific environment setup

# Helper to check if a command exists
_tool_command_exists() {
    command -v "$1" &>/dev/null
}

# Execute a tool with arguments, handling common patterns
_tool_run() {
    local cmd="$1"
    shift
    exec "$cmd" "$@"
}

# Pipe content to a tool in print/prompt mode
_tool_pipe_prompt() {
    local cmd="$1"
    local prompt="$2"
    shift 2
    echo "$prompt" | "$cmd" -p "$@"
}
