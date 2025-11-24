#!/bin/bash

# Model Configuration
# This file defines default model identifiers for each provider.
# You can override these in ~/.claude-switcher/secrets.sh
#
# IMPORTANT: Per official Claude Code documentation, the runtime uses:
#   - ANTHROPIC_MODEL (primary model)
#   - ANTHROPIC_SMALL_FAST_MODEL (for Haiku/fast operations)
#
# This file defines provider-specific defaults that our scripts use to
# SET those runtime variables based on which provider is active.

# AWS Bedrock Model Defaults
# See: https://code.claude.com/docs/en/amazon-bedrock#4-model-configuration
# Official defaults from Claude Code docs:
#   Primary: global.anthropic.claude-sonnet-4-5-20250929-v1:0
#   Small/fast: us.anthropic.claude-haiku-4-5-20251001-v1:0
export CLAUDE_MODEL_SONNET_AWS="${CLAUDE_MODEL_SONNET_AWS:-global.anthropic.claude-sonnet-4-5-20250929-v1:0}"
export CLAUDE_MODEL_OPUS_AWS="${CLAUDE_MODEL_OPUS_AWS:-global.anthropic.claude-opus-4-5-20251101-v1:0}"
export CLAUDE_MODEL_HAIKU_AWS="${CLAUDE_MODEL_HAIKU_AWS:-us.anthropic.claude-haiku-4-5-20251001-v1:0}"

# Google Vertex AI Model Defaults
# See: https://code.claude.com/docs/en/google-vertex-ai#5-model-configuration
# Official example from docs:
#   ANTHROPIC_MODEL='claude-opus-4-5@20251101'
#   ANTHROPIC_SMALL_FAST_MODEL='claude-haiku-4-5@20251001'
export CLAUDE_MODEL_SONNET_VERTEX="${CLAUDE_MODEL_SONNET_VERTEX:-claude-sonnet-4-5@20250929}" 
export CLAUDE_MODEL_OPUS_VERTEX="${CLAUDE_MODEL_OPUS_VERTEX:-claude-opus-4-5@20251101}" 
export CLAUDE_MODEL_HAIKU_VERTEX="${CLAUDE_MODEL_HAIKU_VERTEX:-claude-haiku-4-5@20251001}" 

# Anthropic API Model Defaults
# See: https://docs.anthropic.com/
# Standard model IDs without provider prefix
export CLAUDE_MODEL_SONNET_ANTHROPIC="${CLAUDE_MODEL_SONNET_ANTHROPIC:-claude-sonnet-4-5-20250929}"
export CLAUDE_MODEL_OPUS_ANTHROPIC="${CLAUDE_MODEL_OPUS_ANTHROPIC:-claude-opus-4-5-20251101}"
export CLAUDE_MODEL_HAIKU_ANTHROPIC="${CLAUDE_MODEL_HAIKU_ANTHROPIC:-claude-haiku-4-5}"

# Microsoft Foundry on Azure Model Defaults
# See: https://code.claude.com/docs/en/microsoft-foundry
# Model names are deployment names (user-defined in Azure portal)
# These are just suggested defaults - users must set their actual deployment names
export CLAUDE_MODEL_SONNET_AZURE="${CLAUDE_MODEL_SONNET_AZURE:-claude-sonnet-4-5}"
export CLAUDE_MODEL_OPUS_AZURE="${CLAUDE_MODEL_OPUS_AZURE:-claude-opus-4-5}"
export CLAUDE_MODEL_HAIKU_AZURE="${CLAUDE_MODEL_HAIKU_AZURE:-claude-haiku-4-5}"

# Small/Fast Model Defaults (for background operations)
# These are used by Claude Code for sub-agents, file operations, and auxiliary tasks
# Default to Haiku for each provider but can be overridden in secrets.sh
export CLAUDE_SMALL_FAST_MODEL_AWS="${CLAUDE_SMALL_FAST_MODEL_AWS:-${CLAUDE_MODEL_HAIKU_AWS}}"
export CLAUDE_SMALL_FAST_MODEL_VERTEX="${CLAUDE_SMALL_FAST_MODEL_VERTEX:-${CLAUDE_MODEL_HAIKU_VERTEX}}"
export CLAUDE_SMALL_FAST_MODEL_ANTHROPIC="${CLAUDE_SMALL_FAST_MODEL_ANTHROPIC:-${CLAUDE_MODEL_HAIKU_ANTHROPIC}}"
export CLAUDE_SMALL_FAST_MODEL_AZURE="${CLAUDE_SMALL_FAST_MODEL_AZURE:-${CLAUDE_MODEL_HAIKU_AZURE}}"

# ============================================================================
# DUAL MODEL CONFIGURATION
# ============================================================================
#
# Claude Code uses TWO distinct models for optimal performance:
#
# 1. ANTHROPIC_MODEL - The primary model you interact with
#    - Used for main conversation and complex reasoning
#    - Can be Sonnet, Opus, or Haiku based on your needs
#    - Set by your --sonnet, --opus, --haiku flags or --model override
#
# 2. ANTHROPIC_SMALL_FAST_MODEL - The background/auxiliary model
#    - Used for sub-agents, file operations, and quick tasks
#    - Configured via CLAUDE_SMALL_FAST_MODEL_{PROVIDER} variables
#    - Defaults to Haiku but can be overridden in secrets.sh
#    - Reduces costs for background operations
#
# AUTOMATIC CONFIGURATION:
# Our scripts automatically set ANTHROPIC_SMALL_FAST_MODEL based on the
# CLAUDE_SMALL_FAST_MODEL_{PROVIDER} variable for the active provider.
# These default to each provider's Haiku model but can be overridden.
#
# MANUAL OVERRIDE:
# To use a different small/fast model for a provider, set the appropriate
# variable in ~/.claude-switcher/secrets.sh:
#   export CLAUDE_SMALL_FAST_MODEL_AWS="your-custom-model-id"
#   export CLAUDE_SMALL_FAST_MODEL_VERTEX="your-custom-model-id"
#
# See: https://code.claude.com/docs/en/model-config#environment-variables

# ============================================================================
# IMPLEMENTATION NOTES
# ============================================================================
# 
# Our scripts (claude-aws, claude-vertex, etc.) use the CLAUDE_MODEL_* variables
# above to SET the ANTHROPIC_MODEL environment variable that Claude Code actually
# uses at runtime.
#
# The parse_model_args function in claude-switcher-utils.sh handles:
#   --sonnet → uses CLAUDE_MODEL_SONNET_<PROVIDER>
#   --opus   → uses CLAUDE_MODEL_OPUS_<PROVIDER>
#   --haiku  → uses CLAUDE_MODEL_HAIKU_<PROVIDER>
#   --model "custom-id" → uses custom-id directly
#
# This approach provides:
#   1. Provider-specific model defaults
#   2. Easy model switching via flags
#   3. Override capability in secrets.sh
#   4. Compatibility with Claude Code's runtime expectations
