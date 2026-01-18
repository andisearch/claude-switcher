#!/bin/bash

# Copy this file to ~/.claude-switcher/secrets.sh and fill in your values.

# AWS Bedrock Credentials
# See: https://code.claude.com/docs/en/amazon-bedrock
# Multiple authentication methods supported:

# Option 1: AWS Bedrock API Key (recommended for simplicity)
# export AWS_BEARER_TOKEN_BEDROCK="your-bedrock-api-key"

# Option 2: AWS Access Keys
# export AWS_ACCESS_KEY_ID="your_access_key"
# export AWS_SECRET_ACCESS_KEY="your_secret_key"
# export AWS_SESSION_TOKEN="your_session_token"  # Optional, for temporary credentials

# Option 3: AWS Profile
# export AWS_PROFILE="your-profile-name"

# Required for all AWS auth methods:
# export AWS_REGION="us-west-2"

# Google Vertex AI Credentials
# See: https://code.claude.com/docs/en/google-vertex-ai
# export ANTHROPIC_VERTEX_PROJECT_ID="your_gcp_project_id"
# export CLOUD_ML_REGION="global"  # or "us-east5", "us-central1", etc.

# Google Cloud Authentication Methods (in precedence order):
# 
# Method 1: Service Account Key File (highest precedence)
#   Recommended for production/CI environments
#   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
#
# Method 2: Application Default Credentials
#   Recommended for local development
#   Run: gcloud auth application-default login
#   No additional environment variable needed
#
# Method 3: gcloud User Credentials (lowest precedence)
#   Fallback for basic authentication
#   Run: gcloud auth login
#   No additional environment variable needed
#
# The claude-vertex script automatically detects and uses the appropriate method
# based on what's available in your environment.

# Optional: Set specific regions for each model (defaults to CLOUD_ML_REGION if not set)
# export VERTEX_REGION_CLAUDE_3_5_SONNET="us-east5"
# export VERTEX_REGION_CLAUDE_3_5_HAIKU="us-east5"
# export VERTEX_REGION_CLAUDE_3_7_SONNET="us-east5"
# export VERTEX_REGION_CLAUDE_4_0_OPUS="europe-west1"
# export VERTEX_REGION_CLAUDE_4_0_SONNET="us-east5"
# export VERTEX_REGION_CLAUDE_4_5_OPUS="europe-west1"

# Anthropic API Key
# See: https://console.anthropic.com/
# export ANTHROPIC_API_KEY="sk-ant-..."

# Vercel AI Gateway Credentials
# See: https://vercel.com/ai-gateway
# Route Claude Code through Vercel AI Gateway for failover and unified billing
# Get your token from Vercel dashboard: https://vercel.com/dashboard/~/ai
# export VERCEL_AI_GATEWAY_TOKEN="vck_..."
# export VERCEL_AI_GATEWAY_URL="https://ai-gateway.vercel.sh"  # Default, can be customized

# Microsoft Foundry on Azure Credentials
# See: https://code.claude.com/docs/en/microsoft-foundry
# Announced Nov 18, 2024: https://www.anthropic.com/news/claude-in-microsoft-foundry

# Option 1: API Key authentication
# export ANTHROPIC_FOUNDRY_API_KEY="your-azure-api-key"

# Option 2: Use Azure default credential chain (az login)
# If ANTHROPIC_FOUNDRY_API_KEY is not set, Azure default credentials will be used

# Required: Azure resource name or full base URL
# export ANTHROPIC_FOUNDRY_RESOURCE="your-resource-name"
# Or provide the full URL:
# export ANTHROPIC_FOUNDRY_BASE_URL="https://your-resource-name.services.ai.azure.com"

# ============================================================================
# Model Overrides (Optional)
# ============================================================================
# You can override the default models defined in config/models.sh here.
# These provider-specific variables are used by our scripts to set ANTHROPIC_MODEL
# at runtime based on which provider you're using.

# AWS Bedrock Models
# export CLAUDE_MODEL_SONNET_AWS="global.anthropic.claude-sonnet-4-5-20250929-v1:0"
# export CLAUDE_MODEL_OPUS_AWS="global.anthropic.claude-opus-4-5-20251101-v1:0"
# export CLAUDE_MODEL_HAIKU_AWS="us.anthropic.claude-haiku-4-5-20251001-v1:0"

# Google Vertex Models
# export CLAUDE_MODEL_SONNET_VERTEX="claude-sonnet-4-5@20250929"
# export CLAUDE_MODEL_OPUS_VERTEX="claude-opus-4-5@20251101"
# export CLAUDE_MODEL_HAIKU_VERTEX="claude-haiku-4-5@20251001"

# Anthropic API Models
# export CLAUDE_MODEL_SONNET_ANTHROPIC="claude-sonnet-4-5-20250929"
# export CLAUDE_MODEL_OPUS_ANTHROPIC="claude-opus-4-5-20251101"
# export CLAUDE_MODEL_HAIKU_ANTHROPIC="claude-haiku-4-5"

# Microsoft Foundry/Azure Models (deployment names - must match your Azure deployments)
# export CLAUDE_MODEL_SONNET_AZURE="claude-sonnet-4-5"
# export CLAUDE_MODEL_OPUS_AZURE="claude-opus-4-5"
# export CLAUDE_MODEL_HAIKU_AZURE="claude-haiku-4-5"

# Vercel AI Gateway Models
# export CLAUDE_MODEL_SONNET_VERCEL="anthropic/claude-sonnet-4.5"
# export CLAUDE_MODEL_OPUS_VERCEL="anthropic/claude-opus-4.5"
# export CLAUDE_MODEL_HAIKU_VERCEL="anthropic/claude-haiku-4.5"

# ============================================================================
# Small/Fast Model Overrides (Optional)
# ============================================================================
# Claude Code uses a "small/fast model" for background operations like file ops
# and sub-agents. By default, this uses each provider's Haiku model.
# You can override these if you want to use a different model for background tasks.

# AWS Bedrock Small/Fast Model
# export CLAUDE_SMALL_FAST_MODEL_AWS="us.anthropic.claude-haiku-4-5-20251001-v1:0"

# Google Vertex Small/Fast Model
# export CLAUDE_SMALL_FAST_MODEL_VERTEX="claude-haiku-4-5@20251001"

# Anthropic API Small/Fast Model
# export CLAUDE_SMALL_FAST_MODEL_ANTHROPIC="claude-haiku-4-5"

# Microsoft Foundry/Azure Small/Fast Model (deployment name)
# export CLAUDE_SMALL_FAST_MODEL_AZURE="claude-haiku-4-5"

# Vercel AI Gateway Small/Fast Model
# export CLAUDE_SMALL_FAST_MODEL_VERCEL="anthropic/claude-haiku-4.5"
