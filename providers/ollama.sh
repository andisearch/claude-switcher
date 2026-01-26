#!/bin/bash

# Ollama Provider (Local + Cloud via Anthropic API Compatible)
# As of Ollama 0.14.0 (January 2026), supports Anthropic Messages API
# See: https://ollama.com/blog/claude
#
# CLOUD MODELS: Use :cloud suffix (e.g., glm-4.7:cloud, minimax-m2.1:cloud)
#   - Requires: ollama signin (one-time browser auth)
#   - No GPU needed - models run on Ollama's infrastructure
#   - See: https://ollama.com/search?c=cloud
#
# MEMORY NOTE: Ollama loads models on-demand and keeps them in memory for 5min.
# Claude Code uses two models (main + background). If these differ, Ollama may
# swap models on each request, causing delays. By default we use the same model
# for both. Users with 24GB+ VRAM can set OLLAMA_SMALL_FAST_MODEL for a separate
# background model. See: https://github.com/ollama/ollama/issues/4681
#
# REQUIREMENTS: Claude Code needs 64K+ context. Ollama-recommended models:
#   - qwen3-coder (coding optimized, 30B, needs 24GB VRAM)
#   - glm-4.7 (128K context, tool-calling)
#   - gpt-oss:20b (strong general-purpose)
#   - gpt-oss:120b (cloud, most capable)
#   - minimax-m2.1 (fast)
# See: https://docs.ollama.com/integrations/claude-code

PROVIDER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$PROVIDER_DIR/provider-base.sh"

# Default Ollama settings
OLLAMA_DEFAULT_HOST="${OLLAMA_HOST:-http://localhost:11434}"

#=============================================================================
# System Detection Helpers
#=============================================================================

# Get available disk space in GB (for Ollama models directory)
# Safe: read-only, uses standard df command
_ollama_get_disk_space_gb() {
    local ollama_dir="${OLLAMA_MODELS:-$HOME/.ollama}"
    local mount_point

    # Find the mount point for ollama directory (or home if doesn't exist yet)
    if [ -d "$ollama_dir" ]; then
        mount_point="$ollama_dir"
    else
        mount_point="$HOME"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS: df outputs in 512-byte blocks by default, use -g for GB
        df -g "$mount_point" 2>/dev/null | awk 'NR==2 {print $4}' || echo ""
    else
        # Linux: df -BG for GB
        df -BG "$mount_point" 2>/dev/null | awk 'NR==2 {gsub(/G/,""); print $4}' || echo ""
    fi
}

# Get system RAM in GB
# Safe: read-only, uses sysctl (macOS) or /proc/meminfo (Linux)
_ollama_get_ram_gb() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local bytes
        bytes=$(sysctl -n hw.memsize 2>/dev/null) || return
        if [ -n "$bytes" ] && [ "$bytes" -gt 0 ] 2>/dev/null; then
            echo $((bytes / 1024 / 1024 / 1024))
        fi
    else
        # Linux
        local kb
        kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}') || return
        if [ -n "$kb" ] && [ "$kb" -gt 0 ] 2>/dev/null; then
            echo $((kb / 1024 / 1024))
        fi
    fi
}

# Detect GPU and VRAM (best effort, read-only)
# Safe: only reads system info, no modifications
_ollama_get_gpu_info() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check for Apple Silicon unified memory
        local chip
        chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null) || true
        if [[ "$chip" == *"Apple"* ]]; then
            local ram
            ram=$(_ollama_get_ram_gb) || ram=0
            echo "apple_silicon:${ram:-0}GB_unified"
            return
        fi
    fi

    # NVIDIA GPU (read-only query)
    if command -v nvidia-smi &>/dev/null; then
        local vram
        vram=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1) || true
        if [ -n "$vram" ] && [ "$vram" -gt 0 ] 2>/dev/null; then
            echo "nvidia:$((vram / 1024))GB"
            return
        fi
    fi

    # AMD GPU (Linux, read-only from sysfs)
    if [ -r /sys/class/drm/card0/device/mem_info_vram_total ]; then
        local vram
        vram=$(cat /sys/class/drm/card0/device/mem_info_vram_total 2>/dev/null) || true
        if [ -n "$vram" ] && [ "$vram" -gt 0 ] 2>/dev/null; then
            echo "amd:$((vram / 1024 / 1024 / 1024))GB"
            return
        fi
    fi

    echo "unknown"
}

# Get model recommendations based on system specs
_ollama_get_model_recommendations() {
    local ram=$(_ollama_get_ram_gb)
    local disk=$(_ollama_get_disk_space_gb)
    local gpu=$(_ollama_get_gpu_info)
    local vram=0

    # Parse VRAM from GPU info
    if [[ "$gpu" == "apple_silicon:"* ]]; then
        # Apple Silicon uses unified memory - can use ~75% for models
        vram=$((ram * 3 / 4))
    elif [[ "$gpu" == *"GB" ]]; then
        vram=$(echo "$gpu" | grep -oE '[0-9]+GB' | tr -d 'GB')
    fi

    echo "SYSTEM_RAM=${ram:-unknown}"
    echo "DISK_SPACE=${disk:-unknown}"
    echo "GPU_INFO=$gpu"
    echo "EFFECTIVE_VRAM=${vram:-0}"

    # Recommend models based on available resources
    # VRAM requirements (model + KV cache + overhead):
    #   qwen3-coder:30b → needs ~28GB
    #   glm-4.7 → needs ~20GB
    #   qwen2.5-coder:14b → needs ~12GB
    #   qwen2.5-coder:7b → needs ~8GB
    if [ "${vram:-0}" -ge 28 ]; then
        echo "RECOMMENDED=qwen3-coder,gpt-oss:20b,glm-4.7"
        echo "TIER=high"
    elif [ "${vram:-0}" -ge 20 ]; then
        echo "RECOMMENDED=glm-4.7,gpt-oss:20b,qwen2.5-coder:14b"
        echo "TIER=mid"
    elif [ "${vram:-0}" -ge 12 ]; then
        echo "RECOMMENDED=qwen2.5-coder:14b,minimax-m2.1"
        echo "TIER=low"
        echo "NOTE=Consider using Ollama Cloud for better performance."
    else
        echo "RECOMMENDED=qwen2.5-coder:7b,glm-4.7:cloud"
        echo "TIER=minimal"
        echo "NOTE=Limited VRAM. Recommend Ollama Cloud for coding tasks."
    fi
}

# Get effective VRAM for model selection
_ollama_get_effective_vram() {
    local gpu=$(_ollama_get_gpu_info)
    local ram=$(_ollama_get_ram_gb)
    local vram=0

    if [[ "$gpu" == "apple_silicon:"* ]]; then
        # Apple Silicon uses unified memory - can use ~75% for models
        vram=$((ram * 3 / 4))
    elif [[ "$gpu" == "nvidia:"* ]] || [[ "$gpu" == "amd:"* ]]; then
        vram=$(echo "$gpu" | grep -oE '[0-9]+' | head -1)
    fi

    echo "${vram:-0}"
}

# Check if system should prefer cloud models
# Thresholds based on actual model requirements:
#   qwen3-coder:30b = 19GB model + overhead → needs ~28GB
#   glm-4.7 = ~15GB model + overhead → needs ~20GB
#   qwen2.5-coder:14b = ~9GB model + overhead → needs ~12GB
#   qwen2.5-coder:7b = ~5GB model + overhead → needs ~8GB
_ollama_should_prefer_cloud() {
    local vram=$(_ollama_get_effective_vram)
    # Systems with < 20GB effective VRAM will struggle with coding models
    # (need headroom for KV cache, context, and macOS overhead)
    [ "${vram:-0}" -lt 20 ]
}

# Print system capabilities line for startup (only in interactive mode)
_ollama_print_capabilities_line() {
    local ram=$(_ollama_get_ram_gb)
    local vram=$(_ollama_get_effective_vram)
    local gpu=$(_ollama_get_gpu_info)
    local gpu_label=""

    if [[ "$gpu" == "apple_silicon:"* ]]; then
        gpu_label="Apple Silicon"
    elif [[ "$gpu" == "nvidia:"* ]]; then
        gpu_label="NVIDIA ${gpu#nvidia:}"
    elif [[ "$gpu" == "amd:"* ]]; then
        gpu_label="AMD ${gpu#amd:}"
    else
        gpu_label="CPU only"
    fi

    echo "[AI Runner] - System: ${ram}GB RAM, ~${vram}GB for models ($gpu_label)"
}

# Interactive prompt to switch to cloud models (only called in interactive mode)
# Returns 0 if user wants cloud, 1 if user wants to continue with local
_ollama_prompt_cloud_switch() {
    local vram=$(_ollama_get_effective_vram)

    echo ""
    print_warning "Your system has ~${vram}GB usable VRAM - local models may be slow."
    echo ""
    echo "Ollama Cloud runs models on Ollama's servers (fast on any hardware)."
    echo ""
    echo "  1) Switch to cloud (recommended) - pulls glm-4.7:cloud (~1MB manifest)"
    echo "  2) Continue with local model anyway"
    echo ""

    local choice
    read -r -p "Choice [1]: " choice
    choice="${choice:-1}"

    case "$choice" in
        1|"")
            echo ""
            print_status "Pulling glm-4.7:cloud..."
            if ollama pull glm-4.7:cloud 2>&1; then
                print_success "Cloud model ready!"
                return 0
            else
                print_error "Failed to pull cloud model. Continuing with local."
                return 1
            fi
            ;;
        2)
            echo ""
            print_status "Continuing with local model..."
            return 1
            ;;
        *)
            print_status "Continuing with local model..."
            return 1
            ;;
    esac
}

# Print system info and recommendations for user
_ollama_print_system_recommendations() {
    local ram=$(_ollama_get_ram_gb)
    local disk=$(_ollama_get_disk_space_gb)
    local gpu=$(_ollama_get_gpu_info)
    local vram=$(_ollama_get_effective_vram)

    echo ""
    echo "System detected:"
    [ -n "$ram" ] && echo "  RAM: ${ram}GB"
    [ -n "$disk" ] && echo "  Disk available: ${disk}GB"

    if [[ "$gpu" == "apple_silicon:"* ]]; then
        echo "  GPU: Apple Silicon (unified memory, ~${vram}GB usable)"
    elif [[ "$gpu" == "nvidia:"* ]]; then
        echo "  GPU: NVIDIA ${gpu#nvidia:} VRAM"
    elif [[ "$gpu" == "amd:"* ]]; then
        echo "  GPU: AMD ${gpu#amd:} VRAM"
    else
        echo "  GPU: Not detected"
    fi

    echo ""

    # Thresholds based on actual model requirements:
    #   qwen3-coder:30b needs ~28GB, glm-4.7 needs ~20GB
    #   qwen2.5-coder:14b needs ~12GB, qwen2.5-coder:7b needs ~8GB
    if [ "${vram:-0}" -lt 20 ]; then
        echo "RECOMMENDED: Use Ollama Cloud (your system has limited VRAM)"
        echo ""
        echo "  Cloud models run on Ollama's servers - fast on any hardware:"
        echo "  ollama pull glm-4.7:cloud       # High-performance, 128K context"
        echo "  ollama pull minimax-m2.1:cloud  # Fast responses"
        echo "  ai --ollama --model glm-4.7:cloud"
        echo ""
        echo "  Or use quick setup:  ollama launch claude"
        if [ "${vram:-0}" -ge 12 ]; then
            echo ""
            echo "Local alternatives (may be slow):"
            echo "  ollama pull qwen2.5-coder:14b  # 14B coding model (~9GB)"
        elif [ "${vram:-0}" -ge 8 ]; then
            echo ""
            echo "Local alternatives (limited):"
            echo "  ollama pull qwen2.5-coder:7b   # 7B coding model (~5GB)"
        fi
    elif [ "${vram:-0}" -ge 28 ]; then
        echo "Your system can run large local models:"
        echo "  ollama pull qwen3-coder    # 30B, coding optimized (~19GB)"
        echo "  ollama pull glm-4.7        # 128K context (~15GB)"
        echo "  ai --ollama"
    else
        # 20-28GB range
        echo "Your system can run mid-size local models:"
        echo "  ollama pull glm-4.7        # 128K context (~15GB)"
        echo "  ollama pull gpt-oss:20b    # Strong general-purpose (~12GB)"
        echo "  ai --ollama"
        echo ""
        echo "Note: qwen3-coder:30b (~19GB) may be slow on your system."
        echo "For best performance, consider cloud:"
        echo "  ollama pull glm-4.7:cloud"
    fi

    if [ "${disk:-0}" -lt 20 ]; then
        echo ""
        echo "  ⚠ Low disk space (${disk}GB). Consider cloud models instead."
    fi
}

provider_name() {
    echo "Ollama"
}

provider_flag() {
    echo "ollama"
}

provider_validate_config() {
    local ollama_url="${OLLAMA_HOST:-http://localhost:11434}"

    # Check if Ollama is running (required for both local and cloud models)
    # Cloud models (e.g., glm-4.7:cloud) are proxied through the local server
    if curl -s --connect-timeout 2 "${ollama_url}/api/tags" &>/dev/null; then
        _OLLAMA_URL="$ollama_url"
        _OLLAMA_AUTH_METHOD="Ollama Server"
        return 0
    fi

    return 1
}

provider_get_auth_method() {
    echo "${_OLLAMA_AUTH_METHOD:-Unknown}"
}

provider_get_validation_error() {
    cat << 'EOF'
Ollama is not running

Start Ollama:
  ollama serve

QUICK SETUP (Ollama 0.15+):
  ollama launch claude       # Auto-configure and launch

LOCAL MODELS (free, requires GPU):
  ollama pull qwen3-coder    # Coding optimized (24GB VRAM)
  ai --ollama

CLOUD MODELS (no GPU needed):
  ollama pull glm-4.7:cloud  # Tiny download, runs remotely
  ai --ollama --model glm-4.7:cloud

See: https://docs.ollama.com/api/anthropic-compatibility
EOF
}

provider_setup_env() {
    local tier="${1:-mid}"
    local custom_model="$2"

    # Save current environment
    _provider_save_env

    # Disable other providers
    _provider_disable_all
    export CLAUDE_CODE_USE_BEDROCK=0

    # IMPORTANT: Unset any existing Anthropic credentials first
    # This prevents Claude Code from detecting user's Anthropic API key
    # and prompting "Do you want to use this API key?"
    unset ANTHROPIC_API_KEY
    unset ANTHROPIC_AUTH_TOKEN

    # Configure Ollama as Anthropic API compatible endpoint
    # Per Ollama docs: https://docs.ollama.com/api/anthropic-compatibility
    #
    # IMPORTANT: Cloud models (e.g., glm-4.7:cloud) are accessed through your
    # LOCAL Ollama server, which proxies to Ollama's cloud. The :cloud suffix
    # tells Ollama to run the model on their infrastructure, but the API
    # endpoint is always your local server (localhost:11434).
    #
    # The OLLAMA_API_KEY is used by Ollama for cloud model authentication,
    # but Claude Code connects to the local server with ANTHROPIC_AUTH_TOKEN=ollama.
    export ANTHROPIC_BASE_URL="${OLLAMA_HOST:-http://localhost:11434}"
    export ANTHROPIC_AUTH_TOKEN="ollama"
    export ANTHROPIC_API_KEY=""

    # Set model
    if [ -n "$custom_model" ]; then
        export ANTHROPIC_MODEL="$custom_model"
    else
        export ANTHROPIC_MODEL=$(provider_get_model_id "$tier")
    fi

    # Set small/fast model (for background operations)
    export ANTHROPIC_SMALL_FAST_MODEL=$(provider_get_small_model)

    # Warn if no coding-optimized model detected (skip for cloud models)
    if [[ "$ANTHROPIC_MODEL" != *":cloud"* ]]; then
        _ollama_check_model_suitability "$ANTHROPIC_MODEL"
    fi

    return 0
}

provider_cleanup_env() {
    _provider_restore_env
}

provider_get_model_id() {
    local tier=$(_normalize_tier "$1")

    # Ollama model mappings - configurable via secrets.sh
    # First check explicit config, then auto-detect from available models
    case "$tier" in
        high)
            if [ -n "$OLLAMA_MODEL_HIGH" ]; then
                echo "$OLLAMA_MODEL_HIGH"
            else
                _ollama_auto_detect_model "high"
            fi
            ;;
        mid)
            if [ -n "$OLLAMA_MODEL_MID" ]; then
                echo "$OLLAMA_MODEL_MID"
            else
                _ollama_auto_detect_model "mid"
            fi
            ;;
        low)
            if [ -n "$OLLAMA_MODEL_LOW" ]; then
                echo "$OLLAMA_MODEL_LOW"
            else
                _ollama_auto_detect_model "low"
            fi
            ;;
        *)
            if [ -n "$OLLAMA_MODEL_MID" ]; then
                echo "$OLLAMA_MODEL_MID"
            else
                _ollama_auto_detect_model "mid"
            fi
            ;;
    esac
}

provider_get_small_model() {
    # For Ollama, default to using the SAME model for background operations
    # to avoid costly model swapping (each model needs full VRAM).
    # Users with 24GB+ VRAM can override via OLLAMA_SMALL_FAST_MODEL in secrets.sh
    if [ -n "$OLLAMA_SMALL_FAST_MODEL" ]; then
        echo "$OLLAMA_SMALL_FAST_MODEL"
    else
        # Use same model as main to avoid swapping
        provider_get_model_id "mid"
    fi
}

# Auto-detect best available model for tier
_ollama_auto_detect_model() {
    local tier="$1"
    local models
    local prefer_cloud=false

    # Check if system should prefer cloud (< 16GB effective VRAM)
    if _ollama_should_prefer_cloud; then
        prefer_cloud=true
    fi

    models=$(provider_list_models 2>/dev/null)

    if [ -z "$models" ]; then
        # No models installed - show system-appropriate recommendations
        print_warning "No Ollama models installed."
        _ollama_print_system_recommendations
        echo ""
        # Return appropriate default - cloud for underpowered systems
        if [ "$prefer_cloud" = true ]; then
            echo "glm-4.7:cloud"
        else
            echo "qwen3-coder"
        fi
        return
    fi

    # Model preference patterns (per Ollama docs recommendations)
    # See: https://docs.ollama.com/integrations/claude-code
    # Cloud models have :cloud suffix and run on Ollama's infrastructure
    #
    # VRAM requirements (model + KV cache overhead):
    #   qwen3-coder:30b = 19GB → needs ~28GB effective
    #   gpt-oss:20b = ~12GB → needs ~16GB effective
    #   glm-4.7 = ~15GB → needs ~20GB effective
    #   qwen2.5-coder:14b = ~9GB → needs ~12GB effective
    #   qwen2.5-coder:7b = ~5GB → needs ~8GB effective
    local cloud_patterns=("glm-4.7:cloud" "minimax-m2.1:cloud" "gpt-oss:120b:cloud")
    # High tier: needs 28GB+ effective VRAM for qwen3-coder:30b
    local high_local=("qwen3-coder" "gpt-oss:20b" "glm-4.7")
    # Mid tier: needs 16-24GB effective VRAM - avoid qwen3-coder:30b
    local mid_local=("glm-4.7" "gpt-oss:20b" "qwen2.5-coder:14b" "minimax-m2.1" "qwen2.5-coder")
    # Low tier: needs 8-16GB effective VRAM
    local low_local=("qwen2.5-coder:7b" "minimax-m2.1" "gemma3")

    # For underpowered systems, try cloud models FIRST (before local)
    if [ "$prefer_cloud" = true ]; then
        # Try cloud patterns
        for pattern in "${cloud_patterns[@]}"; do
            local match
            match=$(echo "$models" | grep -i "$pattern" | head -1)
            if [ -n "$match" ]; then
                echo "$match"
                return
            fi
        done

        # Try any cloud model
        local cloud_match
        cloud_match=$(echo "$models" | grep -i ":cloud" | head -1)
        if [ -n "$cloud_match" ]; then
            echo "$cloud_match"
            return
        fi

        # No cloud models available on underpowered system
        # Interactive mode: prompt user to switch to cloud
        # Script mode: continue silently with local model
        if [[ -t 0 ]] && [[ -t 1 ]]; then
            _ollama_prompt_cloud_switch
            local prompt_result=$?
            if [ $prompt_result -eq 0 ]; then
                # User chose to use cloud - return cloud model
                echo "glm-4.7:cloud"
                return
            fi
            # User chose to continue with local - fall through
        fi
    fi

    # Build local patterns based on tier
    local patterns=()
    case "$tier" in
        high)
            # High tier can include cloud for capable systems
            if [ "$prefer_cloud" != true ]; then
                patterns+=("gpt-oss:120b:cloud" "glm-4.7:cloud")
            fi
            patterns+=("${high_local[@]}")
            ;;
        low)
            patterns+=("${low_local[@]}")
            ;;
        *)
            patterns+=("${mid_local[@]}")
            ;;
    esac

    # Try each local pattern in order
    for pattern in "${patterns[@]}"; do
        local match
        match=$(echo "$models" | grep -i "$pattern" | head -1)
        if [ -n "$match" ]; then
            echo "$match"
            return
        fi
    done

    # Final fallback to first available model
    local fallback
    fallback=$(echo "$models" | head -1)
    echo "$fallback"
}

# Check if selected model is suitable for coding with Claude Code
_ollama_check_model_suitability() {
    local model="$1"

    # Ollama-recommended models for Claude Code
    # See: https://docs.ollama.com/integrations/claude-code
    local recommended_models="qwen3-coder|glm-4.7|gpt-oss|minimax-m2.1|qwen2.5-coder"

    if ! echo "$model" | grep -qiE "$recommended_models"; then
        print_warning "Model '$model' may not be optimized for Claude Code."
        print_warning "Ollama recommends these models (64K+ context):"
        print_warning "  ollama pull qwen3-coder    # Coding optimized"
        print_warning "  ollama pull glm-4.7        # 128K context, tool-calling"
        print_warning "  ollama pull gpt-oss:20b    # Strong general-purpose"
    fi
}

provider_supports_tool() {
    local tool="$1"
    # Ollama supports any tool that uses Anthropic API
    case "$tool" in
        claude-code|cc) return 0 ;;
        opencode)       return 0 ;;
        aider)          return 0 ;;
        *)              return 1 ;;
    esac
}

# Print extra provider-specific info during startup (interactive mode only)
provider_print_extra_info() {
    _ollama_print_capabilities_line
}

# Check if a specific model is available in Ollama
provider_model_available() {
    local model="$1"
    local ollama_url="${OLLAMA_HOST:-http://localhost:11434}"

    # Strip tag if present for matching
    local model_name="${model%%:*}"

    curl -s "${ollama_url}/api/tags" 2>/dev/null | grep -q "\"name\":\"${model_name}"
}

# List available models in Ollama
provider_list_models() {
    local ollama_url="${OLLAMA_HOST:-http://localhost:11434}"
    curl -s "${ollama_url}/api/tags" 2>/dev/null | \
        grep -o '"name":"[^"]*"' | \
        cut -d'"' -f4
}

# Get Ollama server URL
provider_get_url() {
    echo "${OLLAMA_HOST:-http://localhost:11434}"
}
