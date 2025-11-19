#!/bin/bash

# AWS Bedrock Models
# Default to Sonnet 4.5
export CLAUDE_MODEL_SONNET_AWS="us.anthropic.claude-sonnet-4-5-20250929-v1:0"
export CLAUDE_MODEL_OPUS_AWS="us.anthropic.claude-opus-4-1-20250805-v1:0"

# Google Vertex Models
# Note: Vertex model IDs often don't have the full version suffix in the same way, 
# but Claude Code might expect specific formats. 
# These are best-guess defaults based on current naming conventions.
export CLAUDE_MODEL_SONNET_VERTEX="claude-3-5-sonnet-v2@20241022" 
export CLAUDE_MODEL_OPUS_VERTEX="claude-3-opus@20240229" 

# Anthropic API Models
export CLAUDE_MODEL_SONNET_ANTHROPIC="claude-3-5-sonnet-20241022"
export CLAUDE_MODEL_OPUS_ANTHROPIC="claude-3-opus-20240229"
