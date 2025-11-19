#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Claude Switcher Setup ===${NC}"

CONFIG_DIR="$HOME/.claude-switcher"
SECRETS_FILE="$CONFIG_DIR/secrets.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Create config directory
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Creating config directory: $CONFIG_DIR"
    mkdir -p "$CONFIG_DIR"
else
    echo "Config directory exists: $CONFIG_DIR"
fi

# Copy secrets template if not exists
if [ ! -f "$SECRETS_FILE" ]; then
    echo "Creating secrets file from template..."
    cp "$PROJECT_ROOT/config/secrets.example.sh" "$SECRETS_FILE"
    echo -e "${GREEN}Created $SECRETS_FILE${NC}"
    echo "Please edit this file to add your API keys."
else
    echo "Secrets file already exists: $SECRETS_FILE"
fi

# Make scripts executable
echo "Making scripts executable..."
chmod +x "$PROJECT_ROOT/scripts/"*
chmod +x "$PROJECT_ROOT/setup.sh"

echo ""
echo -e "${GREEN}Setup complete!${NC}"
echo ""
echo "To use the scripts, add the scripts directory to your PATH:"
echo "  export PATH=\"$PROJECT_ROOT/scripts:\$PATH\""
echo ""
echo "Or create aliases in your shell profile."
