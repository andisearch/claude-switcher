#!/bin/bash

# Verification script to check if environment variables are set correctly
# We will source the scripts instead of running them, to inspect the env vars
# Note: The scripts execute `claude` at the end, so we can't easily source them 
# without them trying to run claude.
# Instead, we will mock `claude` as a function that prints the env vars.

# Mock claude
claude() {
    echo "--- Mock Claude Execution ---"
    echo "ANTHROPIC_MODEL=$ANTHROPIC_MODEL"
    echo "CLAUDE_CODE_USE_BEDROCK=$CLAUDE_CODE_USE_BEDROCK"
    echo "AWS_REGION=$AWS_REGION"
    echo "GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT"
    echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY:0:5}..."
    echo "Args: $@"
}

export -f claude

echo "=== Testing AWS (Default) ==="
./scripts/claude-aws --dry-run 2>/dev/null || true
# Wait, the scripts don't support dry-run and they trap EXIT.
# We need to modify the scripts to support testing or just run them and let the mock handle it.
# But `exec` or direct calls might be an issue if they exit.
# The scripts use `claude "$@"` at the end.

# Let's run them in a subshell with the mock
(
    export PATH="$PWD:$PATH"
    source ./scripts/claude-aws
)

echo ""
echo "=== Testing AWS (Opus) ==="
(
    export PATH="$PWD:$PATH"
    source ./scripts/claude-aws --opus
)

echo ""
echo "=== Testing Vertex (Default) ==="
(
    export PATH="$PWD:$PATH"
    source ./scripts/claude-vertex
)

echo ""
echo "=== Testing Anthropic (Custom) ==="
(
    export PATH="$PWD:$PATH"
    export ANTHROPIC_API_KEY="dummy-key"
    source ./scripts/claude-anthropic --model "custom-model-id"
)
