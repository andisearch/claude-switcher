#!/bin/bash

# AI Runner / Claude Switcher Uninstall Script
# Removes all installed components

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

echo ""
echo "=============================================="
echo "  AI Runner / Claude Switcher Uninstall"
echo "=============================================="
echo ""

# Installation directories
INSTALL_DIR="/usr/local/bin"
SHARE_DIR="/usr/local/share/ai-runner"

# Config directories
CONFIG_DIR_NEW="$HOME/.ai-runner"
CONFIG_DIR_LEGACY="$HOME/.claude-switcher"

# List of scripts to remove
SCRIPTS=(
    # AI Runner commands
    "ai"
    "airun"
    "ai-sessions"
    "ai-status"
    # Legacy claude-* commands
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

# --- 1. Check for sudo if needed ---

SUDO=""
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}Note: Removing scripts from $INSTALL_DIR requires sudo access.${NC}"
    SUDO="sudo"
fi

# --- 2. Remove installed scripts ---

echo "Removing installed scripts from $INSTALL_DIR..."
echo ""

removed_count=0
for script in "${SCRIPTS[@]}"; do
    script_path="$INSTALL_DIR/$script"
    if [ -f "$script_path" ] || [ -L "$script_path" ]; then
        echo "  Removing $script..."
        $SUDO rm -f "$script_path"
        removed_count=$((removed_count + 1))
    else
        echo "  $script (not found, skipping)"
    fi
done

echo ""
if [ $removed_count -gt 0 ]; then
    echo -e "${GREEN}Removed $removed_count script(s) from $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}No scripts found to remove${NC}"
fi

# --- 3. Remove share directory ---

echo ""
if [ -d "$SHARE_DIR" ]; then
    echo "Removing $SHARE_DIR..."
    $SUDO rm -rf "$SHARE_DIR"
    echo -e "${GREEN}Removed share directory${NC}"
fi

# --- 4. Handle config directories ---

REMOVED_CONFIG_DIRS=()
PRESERVED_CONFIG_DIRS=()

echo ""
for CONFIG_DIR in "$CONFIG_DIR_NEW" "$CONFIG_DIR_LEGACY"; do
    if [ -d "$CONFIG_DIR" ]; then
        echo -e "${YELLOW}Configuration directory found: $CONFIG_DIR${NC}"
        echo ""
        echo "This directory may contain:"
        echo "  - secrets.sh (your API keys and credentials)"
        echo "  - models.sh (model configuration)"
        echo "  - defaults.sh (persistent provider/model defaults)"
        echo "  - banner.sh (banner configuration)"
        echo "  - .update-check (update checker cache)"
        echo "  - sessions/ (session tracking)"
        echo ""

        read -p "Do you want to remove this directory? [y/N] " -n 1 -r
        echo ""

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing $CONFIG_DIR..."
            rm -rf "$CONFIG_DIR"
            echo -e "${GREEN}Configuration directory removed${NC}"
            REMOVED_CONFIG_DIRS+=("$CONFIG_DIR")
        else
            echo -e "${YELLOW}Configuration directory preserved at $CONFIG_DIR${NC}"
            PRESERVED_CONFIG_DIRS+=("$CONFIG_DIR")
        fi
        echo ""
    fi
done

# --- 5. Clean up apiKeyHelper from settings.json (always remove, don't ask) ---

CLAUDE_SETTINGS_FILE="$HOME/.claude/settings.json"

if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    if grep -q "apiKeyHelper" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
        echo -e "${BLUE}Removing apiKeyHelper from settings.json...${NC}"

        # Backup first
        cp "$CLAUDE_SETTINGS_FILE" "$CLAUDE_SETTINGS_FILE.backup-uninstall-$(date +%Y%m%d-%H%M%S)"
        echo "Backed up settings.json"

        # Remove apiKeyHelper
        if command -v jq &> /dev/null; then
            jq 'del(.apiKeyHelper)' "$CLAUDE_SETTINGS_FILE" > "$CLAUDE_SETTINGS_FILE.tmp" && \
                mv "$CLAUDE_SETTINGS_FILE.tmp" "$CLAUDE_SETTINGS_FILE"
            echo -e "${GREEN}Removed apiKeyHelper from settings.json${NC}"
        elif command -v python3 &> /dev/null; then
            python3 -c "
import json
import os
settings_file = os.path.expanduser('~/.claude/settings.json')
with open(settings_file, 'r') as f:
    settings = json.load(f)
if 'apiKeyHelper' in settings:
    del settings['apiKeyHelper']
with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)
"
            echo -e "${GREEN}Removed apiKeyHelper from settings.json${NC}"
        else
            echo -e "${YELLOW}Cannot automatically remove apiKeyHelper (jq/python3 not found)${NC}"
            echo "Please manually remove the apiKeyHelper line from:"
            echo "  $CLAUDE_SETTINGS_FILE"
        fi
    fi
fi

# --- 5b. Clean up stale state files from preserved directories ---

cleaned_state=false
for dir in "${PRESERVED_CONFIG_DIRS[@]}"; do
    if ls "$dir"/apiKeyHelper-state-*.tmp 1>/dev/null 2>&1 || [ -f "$dir/current-mode.sh" ]; then
        rm -f "$dir/apiKeyHelper-state-"*.tmp 2>/dev/null
        rm -f "$dir/current-mode.sh" 2>/dev/null
        cleaned_state=true
    fi
done
if $cleaned_state; then
    echo ""
    echo "Cleaning up stale state files..."
    echo -e "${GREEN}Cleaned up state files${NC}"
fi

# --- 6. Summary ---

echo ""
echo "=============================================="
echo -e "${GREEN}Uninstall Complete!${NC}"
echo "=============================================="
echo ""
echo "What was removed:"
echo "  - Installed command scripts from $INSTALL_DIR"
echo "  - Share directory ($SHARE_DIR)"

for dir in "${REMOVED_CONFIG_DIRS[@]}"; do
    echo "  - Configuration directory ($dir)"
done

# Only show "What may remain" if there's something to mention
remaining=()
if [ -f "$CLAUDE_SETTINGS_FILE" ] && grep -q "apiKeyHelper" "$CLAUDE_SETTINGS_FILE" 2>/dev/null; then
    remaining+=("  - Your ~/.claude/settings.json (check for apiKeyHelper)")
fi
if ls "$HOME/.claude/settings.json.backup-"* 1>/dev/null 2>&1; then
    remaining+=("  - Any backups in ~/.claude/settings.json.backup-*")
fi
for dir in "${PRESERVED_CONFIG_DIRS[@]}"; do
    remaining+=("  - Your API keys and configuration in $dir")
done

if [ ${#remaining[@]} -gt 0 ]; then
    echo ""
    echo "What may remain:"
    for line in "${remaining[@]}"; do
        echo "$line"
    done
fi

echo ""
echo "Thank you for using AI Runner!"
echo ""
