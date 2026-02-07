#!/bin/bash

# AI Runner Update Checker
# Provides cached GitHub version checking and self-update functionality.
# Never blocks on network I/O during normal startup — background fetch only.

# Cache file location
_UPDATE_CACHE_FILE="${CONFIG_DIR:=$HOME/.ai-runner}/.update-check"
_UPDATE_CACHE_MAX_AGE=86400  # 24 hours in seconds

# Source metadata (written by setup.sh)
_SOURCE_METADATA_FILE="/usr/local/share/ai-runner/.source-metadata"

# Default GitHub repo
_DEFAULT_GITHUB_REPO="andisearch/airun"

# Result variables (set by check_for_update)
_UPDATE_AVAILABLE_VERSION=""
_UPDATE_RELEASE_NOTES=""

# Compare versions: returns 0 if $1 < $2 (i.e., update available)
_version_lt() {
    local current="$1" latest="$2"
    # Strip leading 'v' if present
    current="${current#v}"
    latest="${latest#v}"
    [[ "$current" == "$latest" ]] && return 1
    # Use sort -V to compare
    local lowest
    lowest=$(printf '%s\n%s\n' "$current" "$latest" | sort -V | head -n1)
    [[ "$lowest" == "$current" ]]
}

# Read cache file. Sets _UPDATE_AVAILABLE_VERSION and _UPDATE_RELEASE_NOTES.
# Returns 0 if cache exists and is readable, 1 otherwise.
_read_update_cache() {
    [[ -f "$_UPDATE_CACHE_FILE" ]] || return 1
    local line
    line=$(head -1 "$_UPDATE_CACHE_FILE" 2>/dev/null) || return 1
    [[ -z "$line" ]] && return 1
    # Format: version|timestamp|release_notes
    local cached_version cached_timestamp cached_notes
    cached_version="${line%%|*}"
    local rest="${line#*|}"
    cached_timestamp="${rest%%|*}"
    cached_notes="${rest#*|}"
    # If timestamp field equals the rest, there were no notes
    [[ "$cached_notes" == "$cached_timestamp" ]] && cached_notes=""
    _CACHED_VERSION="$cached_version"
    _CACHED_TIMESTAMP="$cached_timestamp"
    _CACHED_NOTES="$cached_notes"
    return 0
}

# Write cache file
_write_update_cache() {
    local version="$1" notes="$2"
    local timestamp
    timestamp=$(date +%s)
    echo "${version}|${timestamp}|${notes}" > "$_UPDATE_CACHE_FILE" 2>/dev/null
}

# Fetch latest version from GitHub (network call — use in background or foreground)
_fetch_latest_version() {
    local repo="${1:-$(_get_github_repo)}"
    local version="" notes=""

    # Try GitHub Releases API first (has release notes)
    local release_json
    release_json=$(curl -sf --connect-timeout 3 --max-time 5 \
        "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null)

    if [[ -n "$release_json" ]]; then
        # Extract tag_name and name (release title) using simple parsing
        version=$(echo "$release_json" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        notes=$(echo "$release_json" | grep '"name"' | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi

    # Fallback: tags API (no release notes)
    if [[ -z "$version" ]]; then
        local tags_json
        tags_json=$(curl -sf --connect-timeout 3 --max-time 5 \
            "https://api.github.com/repos/${repo}/tags?per_page=1" 2>/dev/null)
        if [[ -n "$tags_json" ]]; then
            version=$(echo "$tags_json" | grep '"name"' | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
        fi
    fi

    if [[ -n "$version" ]]; then
        _write_update_cache "$version" "$notes"
    fi
}

# Get GitHub repo from source metadata or fallback
_get_github_repo() {
    if [[ -f "$_SOURCE_METADATA_FILE" ]]; then
        local repo
        repo=$(grep '^AI_RUNNER_GITHUB_REPO=' "$_SOURCE_METADATA_FILE" 2>/dev/null | head -1 | cut -d'"' -f2)
        [[ -n "$repo" ]] && { echo "$repo"; return; }
    fi
    echo "$_DEFAULT_GITHUB_REPO"
}

# Get source directory from metadata
_get_source_dir() {
    if [[ -f "$_SOURCE_METADATA_FILE" ]]; then
        local dir
        dir=$(grep '^AI_RUNNER_SOURCE_DIR=' "$_SOURCE_METADATA_FILE" 2>/dev/null | head -1 | cut -d'"' -f2)
        [[ -n "$dir" ]] && { echo "$dir"; return; }
    fi
    return 1
}

# Main entry point: check if an update is available.
# Returns 0 if update available (sets _UPDATE_AVAILABLE_VERSION, _UPDATE_RELEASE_NOTES).
# Returns 1 if no update or check disabled.
# NEVER blocks on network. Spawns background fetch if cache is stale.
check_for_update() {
    # Skip if disabled
    [[ "${AI_NO_UPDATE_CHECK:-0}" == "1" ]] && return 1

    # Need current version to compare
    local current_version="${AI_RUNNER_VERSION:-}"
    [[ -z "$current_version" ]] && return 1

    # Read cache
    if ! _read_update_cache; then
        # No cache — spawn background fetch, return no update for now
        ( _fetch_latest_version ) &>/dev/null &
        disown 2>/dev/null
        return 1
    fi

    # Check if cache is stale (>24h)
    local now
    now=$(date +%s)
    local age=$(( now - ${_CACHED_TIMESTAMP:-0} ))
    if [[ $age -gt $_UPDATE_CACHE_MAX_AGE ]]; then
        # Spawn background fetch (fire-and-forget)
        ( _fetch_latest_version ) &>/dev/null &
        disown 2>/dev/null
    fi

    # Compare cached version with current
    local cached_ver="${_CACHED_VERSION:-}"
    [[ -z "$cached_ver" ]] && return 1

    if _version_lt "$current_version" "$cached_ver"; then
        _UPDATE_AVAILABLE_VERSION="${cached_ver#v}"
        _UPDATE_RELEASE_NOTES="${_CACHED_NOTES:-}"
        return 0
    fi

    return 1
}

# Print update notice to stderr
print_update_notice() {
    [[ -z "$_UPDATE_AVAILABLE_VERSION" ]] && return
    local current="${AI_RUNNER_VERSION:-unknown}"
    echo -e "${YELLOW:-\033[1;33m}[AI Runner]${NC:-\033[0m} Update available: v${current} -> v${_UPDATE_AVAILABLE_VERSION}" >&2
    if [[ -n "$_UPDATE_RELEASE_NOTES" ]]; then
        echo -e "${YELLOW:-\033[1;33m}[AI Runner]${NC:-\033[0m}   ${_UPDATE_RELEASE_NOTES}" >&2
    fi
    echo -e "${CYAN:-\033[0;36m}[AI Runner]${NC:-\033[0m} Run 'ai update' to update" >&2
}

# Run the update (foreground — called by `ai update`)
run_update() {
    local source_dir
    source_dir=$(_get_source_dir)

    if [[ -z "$source_dir" || ! -d "$source_dir" ]]; then
        echo -e "${RED:-\033[0;31m}[AI Runner]${NC:-\033[0m} Cannot find AI Runner source directory." >&2
        echo -e "${YELLOW:-\033[1;33m}[AI Runner]${NC:-\033[0m} Expected source metadata at: $_SOURCE_METADATA_FILE" >&2
        echo -e "${YELLOW:-\033[1;33m}[AI Runner]${NC:-\033[0m} Please re-run setup.sh from your AI Runner git clone." >&2
        return 1
    fi

    if [[ ! -d "$source_dir/.git" ]]; then
        echo -e "${RED:-\033[0;31m}[AI Runner]${NC:-\033[0m} Source directory is not a git repository: $source_dir" >&2
        return 1
    fi

    echo -e "${BLUE:-\033[0;34m}[AI Runner]${NC:-\033[0m} Updating from: $source_dir"

    # Check for local modifications
    local has_changes
    has_changes=$(cd "$source_dir" && git status --porcelain 2>/dev/null)
    if [[ -n "$has_changes" ]]; then
        echo -e "${YELLOW:-\033[1;33m}[AI Runner]${NC:-\033[0m} Warning: Local modifications detected in $source_dir"
        echo -e "${YELLOW:-\033[1;33m}[AI Runner]${NC:-\033[0m} git pull --ff-only may fail if files conflict."
    fi

    # Pull latest
    echo -e "${BLUE:-\033[0;34m}[AI Runner]${NC:-\033[0m} Running git pull --ff-only..."
    if ! (cd "$source_dir" && git pull --ff-only); then
        echo -e "${RED:-\033[0;31m}[AI Runner]${NC:-\033[0m} git pull failed. Resolve conflicts manually in: $source_dir" >&2
        return 1
    fi

    # Re-run setup
    echo -e "${BLUE:-\033[0;34m}[AI Runner]${NC:-\033[0m} Running setup.sh..."
    if ! (cd "$source_dir" && ./setup.sh); then
        echo -e "${RED:-\033[0;31m}[AI Runner]${NC:-\033[0m} setup.sh failed." >&2
        return 1
    fi

    # Clear update cache
    rm -f "$_UPDATE_CACHE_FILE" 2>/dev/null

    # Show new version
    local new_version
    new_version=$(cat "$source_dir/VERSION" 2>/dev/null || echo "unknown")
    echo ""
    echo -e "${GREEN:-\033[0;32m}[AI Runner]${NC:-\033[0m} Updated to v${new_version}"
}
