# Changelog

All notable changes to claude-switcher will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-22

### Added
- **Session-scoped API key switching**: claude-apikey and claude-pro now preserve and restore original apiKeyHelper configuration
- **State preservation**: Automatic save/restore of existing apiKeyHelper settings for non-destructive operation
- **Multi-session support**: Independent state tracking for concurrent Claude sessions
- **Uninstall script**: Safe removal of all installed components with interactive prompts
- **Semantic versioning**: VERSION file and `--version` flag support across all wrapper scripts
- API key helper script for dynamic Anthropic API authentication
- Mode tracking via `current-mode.sh`
- Comprehensive documentation of session-scoped behavior

### Changed
- Removed destructive `/logout` calls from claude-apikey (now uses apiKeyHelper)
- Simplified claude-pro to temporarily disable apiKeyHelper for session
- Updated all wrapper scripts to use session-scoped restore traps
- Enhanced claude-status to show apiKeyHelper configuration and current mode
- Updated README with "How It Works" section explaining apiKeyHelper mechanism
- Improved installation documentation to emphasize non-destructive nature

### Fixed
- Plain `claude` command now always runs in native state after wrapper exits
- Existing user apiKeyHelper configurations are preserved and restored
- No longer modifies `~/.claude/settings.json` during setup (only during wrapper sessions)

## [Unreleased]

### Planned
- Automatic version update notifications in setup.sh
- Integration tests for all provider modes
- Support for additional Claude providers as they become available

---

**Versioning Guidelines:**
- **MAJOR (x.0.0)**: Breaking changes to CLI interface or configuration format
- **MINOR (1.x.0)**: New features (new providers, new flags, new functionality)
- **PATCH (1.0.x)**: Bug fixes, documentation updates, minor improvements
