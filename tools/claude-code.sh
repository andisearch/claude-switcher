#!/bin/bash

# Claude Code Tool
# Anthropic's official CLI for Claude

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TOOL_DIR/tool-base.sh"

tool_name() {
    echo "Claude Code"
}

tool_flag() {
    echo "cc"
}

tool_command() {
    echo "claude"
}

tool_is_installed() {
    _tool_command_exists "claude"
}

tool_supported_providers() {
    # Claude Code supports all providers
    echo "aws vertex apikey azure vercel pro ollama"
}

tool_setup_env() {
    # Claude Code doesn't require additional tool-specific setup
    # Provider setup handles environment variables
    return 0
}

tool_execute_interactive() {
    local args=("$@")
    exec claude "${args[@]}"
}

tool_execute_prompt() {
    local prompt="$1"
    shift
    local args=("$@")
    echo "$prompt" | claude -p "${args[@]}"
}

tool_get_install_instructions() {
    cat << 'EOF'
Claude Code is not installed

Install with:
  curl -fsSL https://claude.ai/install.sh | bash

Or see: https://code.claude.com/docs/en/setup
EOF
}

# Claude Code specific: check if user is logged in (for Pro mode)
tool_is_logged_in() {
    # Check for session file
    [ -f "$HOME/.claude/session.json" ] || [ -f "$HOME/.claude/.credentials" ]
}
