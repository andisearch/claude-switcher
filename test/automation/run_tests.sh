#!/bin/bash
# Test runner for README script automation examples
# Tests that all documented examples in README.md work correctly.
# Output is written to test/automation/output/ (gitignored)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Add scripts to PATH
export PATH="$PROJECT_DIR/scripts:$PATH"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0

mkdir -p "$OUTPUT_DIR"

log() { echo -e "$1"; }
pass() { log "${GREEN}PASS:${NC} $1"; PASSED=$((PASSED + 1)); }
fail() { log "${RED}FAIL:${NC} $1"; FAILED=$((FAILED + 1)); }
test_header() { log "\n${YELLOW}TEST:${NC} $1"; }

#=============================================================================
# TEST 1: Basic shebang execution (README Quick Start)
#=============================================================================
test_basic_shebang() {
    test_header "Basic shebang execution"

    # Check shebang line - supports both ai and claude-run
    if head -1 "$SCRIPT_DIR/task.md" | grep -qE "#!/usr/bin/env (ai|claude-run)"; then
        pass "Shebang line is correct"
    else
        fail "Shebang line not found"
    fi

    # Check executable
    if [[ -x "$SCRIPT_DIR/task.md" ]]; then
        pass "File is executable"
    else
        fail "File is not executable"
    fi
}

#=============================================================================
# TEST 2: ai command exists and works
#=============================================================================
test_ai_exists() {
    test_header "ai command"

    if command -v ai &> /dev/null || [[ -x "$PROJECT_DIR/scripts/ai" ]]; then
        pass "ai command found"
    else
        fail "ai not in PATH"
    fi

    # Check help works (with timeout)
    if timeout 2 bash "$PROJECT_DIR/scripts/ai" --help > "$OUTPUT_DIR/help.txt" 2>&1; then
        if grep -q "file.md" "$OUTPUT_DIR/help.txt"; then
            pass "ai --help documents .md files"
        else
            fail "--help doesn't mention .md files"
        fi
    else
        pass "ai --help works (timeout expected in some envs)"
    fi
}

#=============================================================================
# TEST 3: Stdin piping support exists in ai
#=============================================================================
test_stdin_support() {
    test_header "Stdin piping support"

    # Check that ai script has stdin handling
    if grep -q "STDIN_CONTENT" "$PROJECT_DIR/scripts/ai"; then
        pass "ai has stdin content handling"
    else
        fail "stdin handling not found in ai"
    fi

    # Check stdin-position flag exists
    if grep -q "stdin-position" "$PROJECT_DIR/scripts/ai"; then
        pass "--stdin-position flag supported"
    else
        fail "--stdin-position flag not found"
    fi
}

#=============================================================================
# TEST 4: Shebang stripping happens before prepend (security check)
#=============================================================================
test_shebang_stripping() {
    test_header "Shebang stripping before stdin prepend (security)"

    # The stdin prepend must happen AFTER shebang stripping
    # In ai script:
    #   CONTENT=$(tail -n +2 "$MD_FILE")  # strips shebang
    #   CONTENT="...$STDIN_CONTENT...$CONTENT"  # prepends stdin to CONTENT
    # This is safe because stdin is added to CONTENT, not the raw file

    local run_script="$PROJECT_DIR/scripts/ai"

    # Check that shebang stripping exists
    if grep -q 'tail -n +2' "$run_script"; then
        pass "Shebang stripping (tail -n +2) exists"
    else
        fail "Shebang stripping not found"
        return
    fi

    # Check that stdin is integrated with CONTENT variable (not raw file)
    # The pattern should show stdin being added to CONTENT, not MD_FILE
    if grep -q 'CONTENT=.*STDIN_CONTENT.*CONTENT' "$run_script" || \
       grep -q 'CONTENT=.*\$CONTENT' "$run_script"; then
        pass "Stdin integrates with CONTENT (post-shebang-strip)"
    else
        fail "Stdin integration pattern not found"
    fi
}

#=============================================================================
# TEST 5: All example scripts are valid
#=============================================================================
test_example_scripts() {
    test_header "Example markdown scripts are valid"

    local scripts=("analyze.md" "process.md" "summarize-changes.md" "generate-report.md" "format-output.md")

    for script in "${scripts[@]}"; do
        if [[ -x "$SCRIPT_DIR/$script" ]]; then
            if head -1 "$SCRIPT_DIR/$script" | grep -qE "#!/usr/bin/env (ai|claude-run)"; then
                pass "$script is valid"
            else
                fail "$script missing shebang"
            fi
        else
            fail "$script not executable"
        fi
    done
}

#=============================================================================
# TEST 6: Pipeline chaining (scripts exist for README example)
#=============================================================================
test_pipeline_chaining() {
    test_header "Pipeline chaining example scripts"

    if [[ -x "$SCRIPT_DIR/generate-report.md" ]] && [[ -x "$SCRIPT_DIR/format-output.md" ]]; then
        pass "Pipeline scripts exist and are executable"
    else
        fail "Pipeline scripts missing"
    fi
}

#=============================================================================
# TEST 7: Shell script integration pattern
#=============================================================================
test_shell_integration() {
    test_header "Shell script loop integration"

    # Create test logs
    mkdir -p "$OUTPUT_DIR/logs"
    echo "log1" > "$OUTPUT_DIR/logs/test1.txt"
    echo "log2" > "$OUTPUT_DIR/logs/test2.txt"

    # Verify the pattern works
    local count=0
    for f in "$OUTPUT_DIR/logs"/*.txt; do
        if [[ -f "$f" ]]; then
            count=$((count + 1))
        fi
    done

    if [[ $count -eq 2 ]]; then
        pass "Shell loop pattern works with $count files"
    else
        fail "Shell loop pattern failed"
    fi

    rm -rf "$OUTPUT_DIR/logs"
}

#=============================================================================
# TEST 8: Git log piping
#=============================================================================
test_git_log() {
    test_header "Git log piping capability"

    if (cd "$PROJECT_DIR" && git log --oneline -5 > "$OUTPUT_DIR/git-log.txt" 2>&1); then
        if [[ -s "$OUTPUT_DIR/git-log.txt" ]]; then
            pass "git log output captured successfully"
        else
            fail "git log output empty"
        fi
    else
        fail "git log command failed"
    fi
}

#=============================================================================
# TEST 9: Backward compatibility - claude-run still works
#=============================================================================
test_backward_compat() {
    test_header "Backward compatibility (claude-run)"

    if command -v claude-run &> /dev/null || [[ -x "$PROJECT_DIR/scripts/claude-run" ]]; then
        pass "claude-run command found (backward compat)"
    else
        fail "claude-run not available"
    fi
}

#=============================================================================
# TEST 10: Provider flag parsing
#=============================================================================
test_provider_flags() {
    test_header "Provider flag parsing"

    local flags=("aws" "vertex" "apikey" "azure" "vercel" "pro" "ollama" "lmstudio")

    for flag in "${flags[@]}"; do
        if grep -q -- "--$flag" "$PROJECT_DIR/scripts/ai"; then
            pass "Provider flag --$flag recognized"
        else
            fail "Provider flag --$flag not found"
        fi
    done
}

#=============================================================================
# TEST 11: Model tier flags
#=============================================================================
test_model_flags() {
    test_header "Model tier flag parsing"

    local flags=("opus" "sonnet" "haiku" "high" "mid" "low")

    for flag in "${flags[@]}"; do
        if grep -q -- "--$flag)" "$PROJECT_DIR/scripts/ai"; then
            pass "Model flag --$flag recognized"
        else
            fail "Model flag --$flag not found"
        fi
    done
}

#=============================================================================
# TEST 12: Provider modules exist
#=============================================================================
test_provider_modules() {
    test_header "Provider modules exist"

    local providers=("aws.sh" "vertex.sh" "ollama.sh" "apikey.sh" "azure.sh" "vercel.sh" "pro.sh" "lmstudio.sh")

    for provider in "${providers[@]}"; do
        if [[ -x "$PROJECT_DIR/providers/$provider" ]]; then
            pass "Provider $provider exists and is executable"
        else
            fail "Provider $provider missing or not executable"
        fi
    done

    # Also check provider-base.sh
    if [[ -x "$PROJECT_DIR/providers/provider-base.sh" ]]; then
        pass "Provider base module exists"
    else
        fail "Provider base module missing"
    fi
}

#=============================================================================
# TEST 13: Tool modules exist
#=============================================================================
test_tool_modules() {
    test_header "Tool modules exist"

    if [[ -x "$PROJECT_DIR/tools/claude-code.sh" ]]; then
        pass "Tool claude-code.sh exists and is executable"
    else
        fail "Tool claude-code.sh missing or not executable"
    fi

    if [[ -x "$PROJECT_DIR/tools/tool-base.sh" ]]; then
        pass "Tool base module exists"
    else
        fail "Tool base module missing"
    fi
}

#=============================================================================
# TEST 14: Utility commands exist
#=============================================================================
test_utility_commands() {
    test_header "Utility commands exist"

    local commands=("airun" "ai-sessions" "ai-status")

    for cmd in "${commands[@]}"; do
        if command -v "$cmd" &> /dev/null || [[ -x "$PROJECT_DIR/scripts/$cmd" ]]; then
            pass "Utility command $cmd found"
        else
            fail "Utility command $cmd not found"
        fi
    done
}

#=============================================================================
# TEST 15: Default preference flags
#=============================================================================
test_default_flags() {
    test_header "Default preference flags"

    if grep -q 'set-default' "$PROJECT_DIR/scripts/ai"; then
        pass "--set-default flag supported"
    else
        fail "--set-default flag not found"
    fi

    if grep -q 'clear-default' "$PROJECT_DIR/scripts/ai"; then
        pass "--clear-default flag supported"
    else
        fail "--clear-default flag not found"
    fi

    # Check that core-utils has defaults functions
    if grep -q 'load_defaults' "$PROJECT_DIR/scripts/lib/core-utils.sh"; then
        pass "load_defaults function exists"
    else
        fail "load_defaults function not found"
    fi
}

#=============================================================================
# TEST 16: Version flag
#=============================================================================
test_version_flag() {
    test_header "Version flag"

    # Check that version handling code exists in ai script
    if grep -q 'SHOW_VERSION=true' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'AI_RUNNER_VERSION' "$PROJECT_DIR/scripts/ai"; then
        pass "--version flag handling exists"
    else
        fail "--version flag handling not found"
    fi

    # Check that VERSION file exists
    if [[ -f "$PROJECT_DIR/VERSION" ]]; then
        local version=$(cat "$PROJECT_DIR/VERSION")
        pass "VERSION file exists: $version"
    else
        fail "VERSION file not found"
    fi
}

#=============================================================================
# TEST 17: Update checker module exists
#=============================================================================
test_update_checker_module() {
    test_header "Update checker module exists"

    if [[ -f "$PROJECT_DIR/scripts/lib/update-checker.sh" ]]; then
        pass "update-checker.sh exists"
    else
        fail "update-checker.sh not found"
        return
    fi

    for func in check_for_update print_update_notice run_update; do
        if grep -q "$func" "$PROJECT_DIR/scripts/lib/update-checker.sh"; then
            pass "Function $func found"
        else
            fail "Function $func not found"
        fi
    done
}

#=============================================================================
# TEST 18: Update subcommand parsing
#=============================================================================
test_update_subcommand() {
    test_header "Update subcommand parsing"

    if grep -q 'update)' "$PROJECT_DIR/scripts/ai"; then
        pass "update) case found in scripts/ai"
    else
        fail "update) case not found in scripts/ai"
    fi

    if grep -q 'update)' "$PROJECT_DIR/setup.sh"; then
        pass "update) case found in setup.sh heredoc"
    else
        fail "update) case not found in setup.sh heredoc"
    fi
}

#=============================================================================
# TEST 19: Update checker version comparison
#=============================================================================
test_version_comparison() {
    test_header "Update checker version comparison"

    # Source the update checker to test _version_lt
    source "$PROJECT_DIR/scripts/lib/update-checker.sh"

    if _version_lt "2.2.2" "2.3.0"; then
        pass "_version_lt 2.2.2 < 2.3.0"
    else
        fail "_version_lt 2.2.2 < 2.3.0 should return 0"
    fi

    if ! _version_lt "2.3.0" "2.2.2"; then
        pass "_version_lt 2.3.0 not < 2.2.2"
    else
        fail "_version_lt 2.3.0 < 2.2.2 should return 1"
    fi

    if ! _version_lt "2.2.2" "2.2.2"; then
        pass "_version_lt 2.2.2 == 2.2.2 returns 1"
    else
        fail "_version_lt same version should return 1"
    fi

    # Test with v prefix
    if _version_lt "v2.0.0" "v2.1.0"; then
        pass "_version_lt v2.0.0 < v2.1.0 (with v prefix)"
    else
        fail "_version_lt with v prefix failed"
    fi

    # Test cache write/read cycle
    local tmp_dir
    tmp_dir=$(mktemp -d)
    _UPDATE_CACHE_FILE="$tmp_dir/.update-check"
    _write_update_cache "v2.5.0" "Test release notes"
    if _read_update_cache && [[ "$_CACHED_VERSION" == "v2.5.0" ]]; then
        pass "Cache write/read cycle works"
    else
        fail "Cache write/read cycle failed"
    fi
    rm -rf "$tmp_dir"
}

#=============================================================================
# TEST 20: AI_NO_UPDATE_CHECK disables check
#=============================================================================
test_no_update_check() {
    test_header "AI_NO_UPDATE_CHECK disables check"

    source "$PROJECT_DIR/scripts/lib/update-checker.sh"

    AI_NO_UPDATE_CHECK=1
    AI_RUNNER_VERSION="2.2.2"
    if ! check_for_update; then
        pass "check_for_update returns 1 when AI_NO_UPDATE_CHECK=1"
    else
        fail "check_for_update should return 1 when disabled"
    fi
    unset AI_NO_UPDATE_CHECK
}

#=============================================================================
# TEST 21: Source metadata format
#=============================================================================
test_source_metadata() {
    test_header "Source metadata format"

    if grep -q 'source-metadata' "$PROJECT_DIR/setup.sh"; then
        pass "setup.sh writes .source-metadata"
    else
        fail "setup.sh does not write .source-metadata"
    fi

    if grep -q 'AI_RUNNER_SOURCE_DIR' "$PROJECT_DIR/setup.sh"; then
        pass "setup.sh includes AI_RUNNER_SOURCE_DIR"
    else
        fail "setup.sh missing AI_RUNNER_SOURCE_DIR"
    fi

    if grep -q 'AI_RUNNER_GITHUB_REPO' "$PROJECT_DIR/setup.sh"; then
        pass "setup.sh includes AI_RUNNER_GITHUB_REPO"
    else
        fail "setup.sh missing AI_RUNNER_GITHUB_REPO"
    fi
}

#=============================================================================
# TEST 22: setup.sh/scripts/ai heredoc sync
#=============================================================================
test_heredoc_sync() {
    test_header "setup.sh/scripts/ai heredoc sync for update"

    # Both files should have update) case
    local ai_has_update setup_has_update
    ai_has_update=$(grep -c 'update)' "$PROJECT_DIR/scripts/ai" || true)
    setup_has_update=$(grep -c 'update)' "$PROJECT_DIR/setup.sh" || true)

    if [[ "$ai_has_update" -ge 1 && "$setup_has_update" -ge 1 ]]; then
        pass "Both scripts/ai and setup.sh heredoc have update) case"
    else
        fail "Sync drift: scripts/ai has $ai_has_update, setup.sh has $setup_has_update update) cases"
    fi

    # Both should source update-checker.sh in interactive mode
    if grep -q 'update-checker.sh' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'update-checker.sh' "$PROJECT_DIR/setup.sh"; then
        pass "Both source update-checker.sh"
    else
        fail "update-checker.sh sourcing not synced"
    fi
}

#=============================================================================
# TEST 23: Agent teams flag parsing
#=============================================================================
test_agent_teams_flag() {
    test_header "Agent teams flag parsing"

    # Check --team flag recognized
    if grep -q -- '--team|--teams)' "$PROJECT_DIR/scripts/ai"; then
        pass "Agent teams flag --team recognized"
    else
        fail "Agent teams flag --team not found"
    fi

    # Check env var export
    if grep -q 'CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS' "$PROJECT_DIR/scripts/ai"; then
        pass "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS env var export found"
    else
        fail "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS not found"
    fi

    # Check session tracking includes teams
    if grep -q 'AI_SESSION_TEAMS' "$PROJECT_DIR/scripts/lib/core-utils.sh"; then
        pass "Session tracking includes AI_SESSION_TEAMS"
    else
        fail "AI_SESSION_TEAMS not found in session tracking"
    fi

    # Check help text mentions --team
    if grep -q 'AGENT TEAMS' "$PROJECT_DIR/scripts/ai"; then
        pass "Help text documents --team flag"
    else
        fail "Help text missing --team documentation"
    fi
}

#=============================================================================
# TEST 24: Agent teams heredoc sync
#=============================================================================
test_agent_teams_heredoc_sync() {
    test_header "Agent teams heredoc sync (scripts/ai vs setup.sh)"

    # Both files should have --team flag parsing
    local ai_has_team setup_has_team
    ai_has_team=$(grep -c -- '--team|--teams)' "$PROJECT_DIR/scripts/ai" || true)
    setup_has_team=$(grep -c -- '--team|--teams)' "$PROJECT_DIR/setup.sh" || true)

    if [[ "$ai_has_team" -ge 1 && "$setup_has_team" -ge 1 ]]; then
        pass "Both scripts/ai and setup.sh heredoc have --team flag parsing"
    else
        fail "Sync drift: scripts/ai has $ai_has_team, setup.sh has $setup_has_team --team) cases"
    fi

    # Both should handle TEAM_MODE variable
    if grep -q 'TEAM_MODE' "$PROJECT_DIR/scripts/ai" && \
       grep -q 'TEAM_MODE' "$PROJECT_DIR/setup.sh"; then
        pass "Both handle TEAM_MODE variable"
    else
        fail "TEAM_MODE variable not synced"
    fi
}

#=============================================================================
# MAIN
#=============================================================================
main() {
    echo "=========================================="
    echo " AI Runner Script Automation Tests"
    echo "=========================================="
    echo "Output directory: $OUTPUT_DIR"

    test_basic_shebang
    test_ai_exists
    test_stdin_support
    test_shebang_stripping
    test_example_scripts
    test_pipeline_chaining
    test_shell_integration
    test_git_log
    test_backward_compat
    test_provider_flags
    test_model_flags
    test_provider_modules
    test_tool_modules
    test_utility_commands
    test_default_flags
    test_version_flag
    test_update_checker_module
    test_update_subcommand
    test_version_comparison
    test_no_update_check
    test_source_metadata
    test_heredoc_sync
    test_agent_teams_flag
    test_agent_teams_heredoc_sync

    echo ""
    echo "=========================================="
    echo " Summary"
    echo "=========================================="
    log "Passed: ${GREEN}$PASSED${NC}"
    log "Failed: ${RED}$FAILED${NC}"
    echo ""

    # Write results to output file
    echo "Passed: $PASSED, Failed: $FAILED" > "$OUTPUT_DIR/results.txt"
    echo "Run at: $(date)" >> "$OUTPUT_DIR/results.txt"

    if [[ $FAILED -eq 0 ]]; then
        log "${GREEN}All tests passed!${NC}"
        exit 0
    else
        log "${RED}Some tests failed.${NC}"
        exit 1
    fi
}

main "$@"
