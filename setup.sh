#!/bin/bash

# AI Runner Setup Script
# Installs AI Runner scripts to /usr/local/bin for system-wide access.
# Migrates configuration from ~/.claude-switcher/ if present.

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== AI Runner Setup ===${NC}"

# Configuration
CONFIG_DIR="$HOME/.ai-runner"
CONFIG_DIR_LEGACY="$HOME/.claude-switcher"
SECRETS_FILE="$CONFIG_DIR/secrets.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
INSTALL_DIR="/usr/local/bin"
SHARE_DIR="/usr/local/share/ai-runner"
SHARE_DIR_LEGACY="/usr/local/share/claude-switcher"

# Check for sudo access if needed
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Note: $INSTALL_DIR is not writable by current user. Sudo access required.${NC}"
    SUDO="sudo"
else
    SUDO=""
fi

# --- 0. Clean up old installation ---

echo ""
echo "Checking for previous installation..."

# Remove old share directory if exists
if [ -d "$SHARE_DIR_LEGACY" ]; then
    echo "Removing old share directory: $SHARE_DIR_LEGACY"
    $SUDO rm -rf "$SHARE_DIR_LEGACY"
fi

# --- 1. Configuration Migration & Setup ---

echo ""
echo "Setting up configuration..."

# Migrate from old config directory if it exists and new one doesn't
if [ -d "$CONFIG_DIR_LEGACY" ] && [ ! -d "$CONFIG_DIR" ]; then
    echo ""
    echo "┌─────────────────────────────────────────────────────────────┐"
    echo "│  Found existing configuration at ~/.claude-switcher/        │"
    echo "├─────────────────────────────────────────────────────────────┤"
    echo "│  How would you like to proceed?                             │"
    echo "│                                                             │"
    echo "│  [1] Copy to ~/.ai-runner/ (recommended)                    │"
    echo "│      - Creates new config directory                         │"
    echo "│      - Keeps original ~/.claude-switcher/ intact            │"
    echo "│                                                             │"
    echo "│  [2] Symlink ~/.ai-runner/ → ~/.claude-switcher/            │"
    echo "│      - Single config location                               │"
    echo "│                                                             │"
    echo "│  [3] Keep using ~/.claude-switcher/ only                    │"
    echo "│      - No new directory created                             │"
    echo "│                                                             │"
    echo "└─────────────────────────────────────────────────────────────┘"
    echo ""
    read -p "  Choice [1/2/3]: " migration_choice

    case "$migration_choice" in
        1)
            # Create new config directory and copy files
            mkdir -p "$CONFIG_DIR"

            # Copy secrets file (most important)
            if [ -f "$CONFIG_DIR_LEGACY/secrets.sh" ]; then
                cp "$CONFIG_DIR_LEGACY/secrets.sh" "$CONFIG_DIR/secrets.sh"
                echo -e "${GREEN}Migrated secrets.sh${NC}"
            fi

            # Copy current-mode.sh if exists
            if [ -f "$CONFIG_DIR_LEGACY/current-mode.sh" ]; then
                cp "$CONFIG_DIR_LEGACY/current-mode.sh" "$CONFIG_DIR/current-mode.sh"
                echo -e "${GREEN}Migrated current-mode.sh${NC}"
            fi

            # Copy sessions directory if exists
            if [ -d "$CONFIG_DIR_LEGACY/sessions" ]; then
                cp -r "$CONFIG_DIR_LEGACY/sessions" "$CONFIG_DIR/sessions"
                echo -e "${GREEN}Migrated sessions directory${NC}"
            fi

            echo -e "${GREEN}Configuration copied to ~/.ai-runner/${NC}"
            echo -e "${YELLOW}Note: Old config at $CONFIG_DIR_LEGACY preserved (can be removed manually)${NC}"
            ;;
        2)
            ln -s "$CONFIG_DIR_LEGACY" "$CONFIG_DIR"
            echo -e "${GREEN}Symlink created: ~/.ai-runner/ → ~/.claude-switcher/${NC}"
            ;;
        3|*)
            CONFIG_DIR="$CONFIG_DIR_LEGACY"
            SECRETS_FILE="$CONFIG_DIR/secrets.sh"
            echo -e "${BLUE}Using existing ~/.claude-switcher/${NC}"
            ;;
    esac
    echo ""
fi

# Create config directory if not exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
else
    echo "Config directory exists: $CONFIG_DIR"
fi

# Copy secrets template if not exists
if [ ! -f "$SECRETS_FILE" ]; then
    echo "Creating secrets file from template..."
    cp "$PROJECT_ROOT/secrets.example.sh" "$SECRETS_FILE"
    echo -e "${GREEN}Created $SECRETS_FILE${NC}"
    echo "Please edit this file to add your API keys."
else
    echo "Secrets file already exists: $SECRETS_FILE (skipping overwrite)"
fi

# Copy models configuration (always update to get latest model definitions)
MODELS_FILE="$CONFIG_DIR/models.sh"
echo "Copying models configuration..."
cp "$PROJECT_ROOT/config/models.sh" "$MODELS_FILE"
echo -e "${GREEN}Updated $MODELS_FILE${NC}"

# Copy banner configuration
BANNER_FILE="$CONFIG_DIR/banner.sh"
echo "Copying banner configuration..."
cp "$PROJECT_ROOT/config/banner.sh" "$BANNER_FILE"
echo -e "${GREEN}Updated $BANNER_FILE${NC}"


# --- 1b. Clean up any legacy apiKeyHelper artifacts ---

# Remove stale state files from previous versions
rm -f "$CONFIG_DIR/apiKeyHelper-state-"*.tmp 2>/dev/null
rm -f "$CONFIG_DIR/current-mode.sh" 2>/dev/null
rm -f "$CONFIG_DIR_LEGACY/apiKeyHelper-state-"*.tmp 2>/dev/null
rm -f "$CONFIG_DIR_LEGACY/current-mode.sh" 2>/dev/null

# Remove apiKeyHelper from settings.json if present (from previous versions)
CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    if grep -q "apiKeyHelper" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
        echo "Removing legacy apiKeyHelper from Claude settings..."
        if command -v jq &>/dev/null; then
            jq 'del(.apiKeyHelper)' "$CLAUDE_SETTINGS_FILE" > "$CLAUDE_SETTINGS_FILE.tmp" && \
                mv "$CLAUDE_SETTINGS_FILE.tmp" "$CLAUDE_SETTINGS_FILE"
            echo -e "${GREEN}Removed apiKeyHelper from settings.json${NC}"
        else
            echo -e "${YELLOW}Note: jq not found, cannot auto-remove apiKeyHelper${NC}"
            echo -e "${YELLOW}If 'claude' command fails, manually remove apiKeyHelper from ~/.claude/settings.json${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}Session isolation: AI Runner uses environment variables only${NC}"
echo -e "${GREEN}Your 'claude' command will always work as it did before installation${NC}"

# --- 2. Script Installation ---

echo ""
echo "Installing scripts to $INSTALL_DIR..."

# List of scripts to install
SCRIPTS=(
    # New AI Runner commands
    "ai"
    "airun"
    "ai-sessions"
    "ai-status"
    # Legacy claude-* commands (backward compatibility)
    "claude-run"
    "claude-pro"
    "claude-aws"
    "claude-vertex"
    "claude-apikey"
    "claude-azure"
    "claude-vercel"
    "claude-status"
    "claude-sessions"
    "claude-switcher-utils.sh"
    "claude-settings-manager.sh"
)

# Install each script
for script in "${SCRIPTS[@]}"; do
    source_path="$PROJECT_ROOT/scripts/$script"
    dest_path="$INSTALL_DIR/$script"

    if [ -f "$source_path" ]; then
        echo "Installing $script..."
        $SUDO cp "$source_path" "$dest_path"
        $SUDO chmod +x "$dest_path"
    else
        echo -e "${YELLOW}Skipping $script (not found)${NC}"
    fi
done

# --- 2b. Install Library Scripts ---
echo ""
echo "Installing library scripts to $SHARE_DIR..."

# Create share directory structure
$SUDO mkdir -p "$SHARE_DIR/lib"
$SUDO mkdir -p "$SHARE_DIR/providers"
$SUDO mkdir -p "$SHARE_DIR/tools"

# Copy lib scripts
if [ -d "$PROJECT_ROOT/scripts/lib" ]; then
    for lib_script in "$PROJECT_ROOT/scripts/lib"/*.sh; do
        if [ -f "$lib_script" ]; then
            echo "Installing lib/$(basename "$lib_script")..."
            $SUDO cp "$lib_script" "$SHARE_DIR/lib/"
        fi
    done
fi

# Copy providers
if [ -d "$PROJECT_ROOT/providers" ]; then
    for provider_script in "$PROJECT_ROOT/providers"/*.sh; do
        if [ -f "$provider_script" ]; then
            echo "Installing providers/$(basename "$provider_script")..."
            $SUDO cp "$provider_script" "$SHARE_DIR/providers/"
        fi
    done
fi

# Copy tools
if [ -d "$PROJECT_ROOT/tools" ]; then
    for tool_script in "$PROJECT_ROOT/tools"/*.sh; do
        if [ -f "$tool_script" ]; then
            echo "Installing tools/$(basename "$tool_script")..."
            $SUDO cp "$tool_script" "$SHARE_DIR/tools/"
        fi
    done
fi

# Copy VERSION file
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    $SUDO cp "$PROJECT_ROOT/VERSION" "$SHARE_DIR/"
fi

# Update ai script to use installed lib location
# Create a wrapper that sets correct paths
$SUDO tee "$INSTALL_DIR/ai" > /dev/null << 'AISCRIPT'
#!/bin/bash
# AI Runner - Universal AI Prompt Interpreter
# This wrapper ensures correct paths to lib/providers/tools

export AI_RUNNER_SHARE_DIR="/usr/local/share/ai-runner"
export AI_RUNNER_CONFIG_DIR="${AI_RUNNER_CONFIG_DIR:-$HOME/.ai-runner}"
export AI_RUNNER_CONFIG_DIR_LEGACY="$HOME/.claude-switcher"

# Set branding
export AI_RUNNER_BRAND="AI Runner"

# Set PROVIDER_DIR and TOOL_DIR BEFORE sourcing loaders
export PROVIDER_DIR="$AI_RUNNER_SHARE_DIR/providers"
export TOOL_DIR="$AI_RUNNER_SHARE_DIR/tools"

# Source from share directory
source "$AI_RUNNER_SHARE_DIR/lib/core-utils.sh"
source "$AI_RUNNER_SHARE_DIR/lib/provider-loader.sh"
source "$AI_RUNNER_SHARE_DIR/lib/tool-loader.sh"

# Capture stdin early if being piped to
STDIN_CONTENT=""
if [[ ! -t 0 ]]; then
    STDIN_CONTENT=$(cat)
fi

# Parse arguments
TOOL_FLAG=""
PROVIDER_FLAG=""
MODEL_TIER=""
CUSTOM_MODEL=""
MD_FILE=""
CLAUDE_ARGS=()
NEEDS_VERBOSE=false
STDIN_POSITION="prepend"
SHOW_VERSION=false
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-format)
            CLAUDE_ARGS+=("$1" "$2")
            [[ "$2" == "stream-json" ]] && NEEDS_VERBOSE=true
            shift 2 ;;
        --output-format=*)
            CLAUDE_ARGS+=("$1")
            [[ "$1" == "--output-format=stream-json" ]] && NEEDS_VERBOSE=true
            shift ;;
        --tool) TOOL_FLAG="$2"; shift 2 ;;
        --tool=*) TOOL_FLAG="${1#*=}"; shift ;;
        --cc) TOOL_FLAG="cc"; shift ;;
        --aws) PROVIDER_FLAG="aws"; shift ;;
        --vertex) PROVIDER_FLAG="vertex"; shift ;;
        --apikey) PROVIDER_FLAG="apikey"; shift ;;
        --azure) PROVIDER_FLAG="azure"; shift ;;
        --vercel) PROVIDER_FLAG="vercel"; shift ;;
        --pro) PROVIDER_FLAG="pro"; shift ;;
        --ollama) PROVIDER_FLAG="ollama"; shift ;;
        --openrouter|--or) PROVIDER_FLAG="openrouter"; shift ;;
        --lmstudio) PROVIDER_FLAG="lmstudio"; shift ;;
        --openai) PROVIDER_FLAG="openai"; shift ;;
        --opus|--high) MODEL_TIER="high"; shift ;;
        --sonnet|--mid) MODEL_TIER="mid"; shift ;;
        --haiku|--low) MODEL_TIER="low"; shift ;;
        --model) CUSTOM_MODEL="$2"; shift 2 ;;
        --model=*) CUSTOM_MODEL="${1#*=}"; shift ;;
        *.md)
            if [[ -f "$1" ]]; then MD_FILE="$1"
            else print_error "File not found: $1"; exit 1; fi
            shift ;;
        --stdin-position)
            STDIN_POSITION="$2"
            [[ "$STDIN_POSITION" != "prepend" && "$STDIN_POSITION" != "append" ]] && \
                { print_error "Invalid --stdin-position: $2"; exit 1; }
            shift 2 ;;
        --version|-v) SHOW_VERSION=true; shift ;;
        --help|-h) SHOW_HELP=true; shift ;;
        *) CLAUDE_ARGS+=("$1"); shift ;;
    esac
done

[[ "$SHOW_VERSION" == true ]] && { echo "ai-runner v$AI_RUNNER_VERSION"; exit 0; }

[[ "$SHOW_HELP" == true ]] && {
    cat << 'EOF'
Usage: ai [OPTIONS] [file.md]

Universal AI prompt interpreter - execute prompts across tools and providers.

TOOL FLAGS:
  --tool <name>   Select AI tool (default: auto-detect)
  --cc            Shorthand for Claude Code

PROVIDER FLAGS:
  --aws, --vertex, --apikey, --azure, --vercel, --pro
  --ollama, --openrouter (--or), --lmstudio

MODEL FLAGS:
  --opus/--high, --sonnet/--mid, --haiku/--low, --model <id>

Run 'ai --help' in dev mode for full help.
EOF
    exit 0
}

needs_config_migration && migrate_config_interactive
load_config_quiet

# First-time setup (if needed and interactive)
if needs_first_time_setup && is_interactive; then
    run_first_time_setup || exit 1
    # Reload config after setup
    load_config_quiet
fi

[[ -z "$TOOL_FLAG" ]] && { TOOL_FLAG=$(detect_default_tool); [[ -z "$TOOL_FLAG" ]] && { print_no_tool_error; exit 1; }; }
load_tool "$TOOL_FLAG" || exit 1
tool_is_installed || { tool_get_install_instructions; exit 1; }

[[ -z "$PROVIDER_FLAG" ]] && { PROVIDER_FLAG=$(detect_default_provider); [[ -z "$PROVIDER_FLAG" ]] && { print_no_provider_error; exit 1; }; }
load_provider "$PROVIDER_FLAG" || exit 1
provider_validate_config || { provider_get_validation_error; exit 1; }

# Set default model tier if not specified
# Pro subscription defaults to "high" (Opus) to match native claude command
# API/BYOK providers default to "mid" (Sonnet) to manage costs
if [[ -z "$MODEL_TIER" && -z "$CUSTOM_MODEL" ]]; then
    if [[ "$PROVIDER_FLAG" == "pro" ]]; then
        MODEL_TIER="high"
    else
        MODEL_TIER="mid"
    fi
fi

provider_setup_env "$MODEL_TIER" "$CUSTOM_MODEL" || exit 1
tool_setup_env

AI_SESSION_ID="$(tool_flag)-$(provider_flag)-$$-$(date +%s)"
export AI_SESSION_ID

write_session_info "$(provider_name)" "BYOK" "$ANTHROPIC_MODEL" "$ANTHROPIC_SMALL_FAST_MODEL" \
    "$(provider_get_region 2>/dev/null || echo '')" "$(provider_get_project 2>/dev/null || echo '')" \
    "$(provider_get_auth_method)" "$(tool_flag)"

trap 'cleanup_session_info; provider_cleanup_env' EXIT

[[ "$NEEDS_VERBOSE" == true ]] && CLAUDE_ARGS=("--verbose" "${CLAUDE_ARGS[@]}")

if [[ -n "$MD_FILE" ]]; then
    [[ "$(head -1 "$MD_FILE")" == "#!"* ]] && CONTENT=$(tail -n +2 "$MD_FILE") || CONTENT=$(cat "$MD_FILE")
    [[ -n "$STDIN_CONTENT" ]] && {
        [[ "$STDIN_POSITION" == "prepend" ]] && CONTENT="stdin:
---
$STDIN_CONTENT
---

$CONTENT" || CONTENT="$CONTENT

---
stdin:
---
$STDIN_CONTENT"
    }
    is_interactive && { print_status "Using: $(tool_name) + $(provider_name)"; print_status "Model: $ANTHROPIC_MODEL"; }
    tool_execute_prompt "$CONTENT" "${CLAUDE_ARGS[@]}"
    exit $?
fi

if [[ -n "$STDIN_CONTENT" ]]; then
    FIRST_LINE="${STDIN_CONTENT%%$'\n'*}"
    [[ "$FIRST_LINE" == "#!"* ]] && CONTENT="${STDIN_CONTENT#*$'\n'}" || CONTENT="$STDIN_CONTENT"
    is_interactive && { print_status "Using: $(tool_name) + $(provider_name)"; print_status "Model: $ANTHROPIC_MODEL"; }
    tool_execute_prompt "$CONTENT" "${CLAUDE_ARGS[@]}"
    exit $?
fi

display_banner
print_success "$(tool_name) + $(provider_name) mode activated"
print_status "- Provider: $(provider_name)"
print_status "- Auth: $(provider_get_auth_method)"
print_status "- Model: $ANTHROPIC_MODEL"
[[ -n "$ANTHROPIC_SMALL_FAST_MODEL" ]] && print_status "- Small/Fast Model: $ANTHROPIC_SMALL_FAST_MODEL"

# Show auth conflict note for API key mode
if [[ "$PROVIDER_FLAG" == "apikey" ]] && [[ -n "$ANTHROPIC_API_KEY" ]]; then
    echo ""
    print_warning "Note: If you see an 'Auth conflict' warning below, this is expected."
    print_status "Your API key will be used for billing. The warning is informational only."
    print_status "To permanently switch to API-only mode, run: claude /logout"
    echo ""
fi

print_status "Launching $(tool_name)..."
tool_execute_interactive "${CLAUDE_ARGS[@]}"
AISCRIPT
$SUDO chmod +x "$INSTALL_DIR/ai"

# Create airun symlink
$SUDO ln -sf ai "$INSTALL_DIR/airun"

# --- 3. Completion ---

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "The following commands are now available system-wide:"
echo ""
echo -e "${BLUE}AI Runner (new):${NC}"
echo "  ai                  - Universal AI prompt interpreter"
echo "  airun               - Alias for ai"
echo "  ai-sessions         - List active AI sessions"
echo "  ai-status           - Show configuration status"
echo ""
echo -e "${BLUE}Claude Switcher (backward compatible):${NC}"
echo "  claude-run          - Unified entry point"
echo "  claude-pro          - Switch to Claude Pro Plan mode"
echo "  claude-aws          - Switch to AWS Bedrock mode"
echo "  claude-vertex       - Switch to Google Vertex AI mode"
echo "  claude-apikey       - Switch to Anthropic API mode"
echo "  claude-azure        - Switch to Microsoft Foundry on Azure mode"
echo "  claude-vercel       - Switch to Vercel AI Gateway mode"
echo "  claude-status       - Show current configuration"
echo "  claude-sessions     - List active Claude sessions"
echo ""
echo -e "${GREEN}Configuration:${NC}"
echo "  Config directory: $CONFIG_DIR"
if [ -d "$CONFIG_DIR_LEGACY" ]; then
    echo -e "  ${YELLOW}Legacy config still exists: $CONFIG_DIR_LEGACY (can be removed)${NC}"
fi
echo ""
echo -e "${GREEN}Quick start:${NC}"
echo "  ai task.md              # Auto-detect tool and provider"
echo "  ai --ollama task.md     # Use local Ollama (free!)"
echo "  ai --aws --opus         # AWS Bedrock with Opus"
echo ""
echo "Run 'ai --help' for usage information."
echo "Run this script again at any time to update."
