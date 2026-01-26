#!/bin/bash

# Tool Loader
# Dynamically loads and manages tools for AI Runner

# Only set TOOL_DIR if not already set by caller
if [ -z "$TOOL_DIR" ]; then
    _LOADER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TOOL_DIR="$(cd "$_LOADER_SCRIPT_DIR/../../tools" 2>/dev/null && pwd)"
fi

# Currently loaded tool
_CURRENT_TOOL=""
_CURRENT_TOOL_FILE=""

# Get tool file for a flag name
_get_tool_file() {
    local flag="$1"
    case "$flag" in
        cc|claude-code)  echo "claude-code.sh" ;;
        # Future tools (placeholders for Phase 3)
        # opencode)       echo "opencode.sh" ;;
        # aider)          echo "aider.sh" ;;
        # codex)          echo "codex.sh" ;;
        # gemini)         echo "gemini-cli.sh" ;;
        *)               echo "" ;;
    esac
}

# Load a tool by flag name
load_tool() {
    local flag="$1"

    if [ -z "$flag" ]; then
        return 1
    fi

    local tool_file
    tool_file=$(_get_tool_file "$flag")
    if [ -z "$tool_file" ]; then
        print_error "Unknown tool: $flag"
        print_error "Available tools: cc (claude-code)"
        return 1
    fi

    local full_path="$TOOL_DIR/$tool_file"
    if [ ! -f "$full_path" ]; then
        print_error "Tool file not found: $full_path"
        return 1
    fi

    # Source the tool
    source "$full_path"
    _CURRENT_TOOL="$flag"
    _CURRENT_TOOL_FILE="$full_path"

    return 0
}

# Get current tool flag
get_current_tool() {
    echo "$_CURRENT_TOOL"
}

# Check if any tool is loaded
is_tool_loaded() {
    [ -n "$_CURRENT_TOOL" ]
}

# List all available tool flags
list_tools() {
    echo "cc claude-code"
}

# Detect default tool based on what's installed
# Returns the first tool that is installed
detect_default_tool() {
    # 1. Claude Code (primary if installed)
    if load_tool "cc" && tool_is_installed; then
        echo "cc"
        return 0
    fi

    # Future: additional tools
    # 2. OpenCode (open-source alternative)
    # if command -v opencode &>/dev/null; then
    #     echo "opencode"
    #     return 0
    # fi

    # 3. Aider (popular multi-file editor)
    # if command -v aider &>/dev/null; then
    #     echo "aider"
    #     return 0
    # fi

    # No tool found
    echo ""
    return 1
}

# Print tool not found error with helpful message
print_no_tool_error() {
    print_error "No AI coding tool found."
    print_error ""
    print_error "Install one of:"
    print_error "  - Claude Code: curl -fsSL https://claude.ai/install.sh | bash"
    # print_error "  - OpenCode:    go install github.com/sst/opencode@latest"
    # print_error "  - Aider:       pip install aider-chat"
}

# Check if a tool supports a provider
tool_supports_provider() {
    local provider="$1"

    if ! is_tool_loaded; then
        return 1
    fi

    local supported
    supported=$(tool_supported_providers)

    # Check if provider is in the supported list
    echo "$supported" | grep -qw "$provider"
}
