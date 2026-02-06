#!/bin/bash

# System Utilities
# Shared system detection helpers for local AI providers (Ollama, LM Studio, etc.)

#=============================================================================
# System Detection Helpers
#=============================================================================

# Get system RAM in GB
# Safe: read-only, uses sysctl (macOS) or /proc/meminfo (Linux)
_get_ram_gb() {
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
_get_gpu_info() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check for Apple Silicon unified memory
        local chip
        chip=$(sysctl -n machdep.cpu.brand_string 2>/dev/null) || true
        if [[ "$chip" == *"Apple"* ]]; then
            local ram
            ram=$(_get_ram_gb) || ram=0
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

# Get effective VRAM for model selection
_get_effective_vram() {
    local gpu=$(_get_gpu_info)
    local ram=$(_get_ram_gb)
    local vram=0

    if [[ "$gpu" == "apple_silicon:"* ]]; then
        # Apple Silicon uses unified memory - can use ~75% for models
        vram=$((ram * 3 / 4))
    elif [[ "$gpu" == "nvidia:"* ]] || [[ "$gpu" == "amd:"* ]]; then
        vram=$(echo "$gpu" | grep -oE '[0-9]+' | head -1)
    fi

    echo "${vram:-0}"
}

# Print system capabilities line for startup (only in interactive mode)
_print_capabilities_line() {
    local provider_name="${1:-Local}"
    local ram=$(_get_ram_gb)
    local vram=$(_get_effective_vram)
    local gpu=$(_get_gpu_info)
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

# Check if system should prefer cloud/remote models
# Thresholds based on actual model requirements for coding tasks
_should_prefer_remote() {
    local vram=$(_get_effective_vram)
    # Systems with < 20GB effective VRAM will struggle with large coding models
    [ "${vram:-0}" -lt 20 ]
}
