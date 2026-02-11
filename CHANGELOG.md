# Changelog

All notable changes to centralized-rules will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

## [0.1.1] - 2026-02-11

### Fixed
- Restored `__CENTRALIZED_RULES_COMMIT__` placeholder in activate-rules.sh that was accidentally replaced with a hardcoded commit SHA, causing all installations to display a stale commit ID

---

## [0.1.0] - 2026-01-21

First versioned release with GitHub Releases infrastructure.

### Added
- GitHub Actions release workflow (`.github/workflows/release.yml`)
- Release documentation (`RELEASING.md`)
- Version badge in README
- `--edge` flag for install-hooks.sh (install from main branch)
- `--version` flag for install-hooks.sh (install specific version)
- Automatic latest release detection via GitHub API

### Changed
- install-hooks.sh now fetches from GitHub releases by default
- Falls back to main branch if no releases exist

---

## [1.3.1] - 2025-12-21

### Fixed
- **CRITICAL**: Hook script now auto-detects commit hash in CI/dev environments
  - Previously showed placeholder `__CENTRALIZED_RULES_COMMIT__` when run directly
  - Now falls back to `git rev-parse --short HEAD` if placeholder not replaced
  - Works in CI, development, and production environments
  - Shows "dev" if git repo not found (graceful degradation)
- **CRITICAL**: Fixed all multi-word keywords causing test failures
  - Cloud keywords: "api gateway" → "apigateway", "edge function" → "edgefunction",
    "function app" → "azurefunctions", "blob storage" → "blobstorage",
    "cosmos db" → "cosmosdb", "arm template" → "armtemplate",
    "cloud function" → "cloudfunctions", "pub/sub" → "pubsub"
  - Base keywords: "pull request" → "pullrequest"
  - Language keywords: "type hint" → "typehint", "go mod" → "gomod"
  - Removed redundant "google cloud" (already covered by "gcp")
  - Removed overly generic "serverless" keyword
  - All 132 keyword validation tests now pass (previously 114/119 passed)

### Added
- Automated keyword validation testing script (`scripts/test-keyword-validation.sh`)
- CI integration for keyword validation (`ci-keyword-validation.yml`)
- Comprehensive test documentation (`scripts/README.md`)
- **GitHub Actions now shows which keywords failed** in job summary and error output
  - Captures test output to log file
  - Extracts failed keywords and displays them in CI
  - Uploads test results as artifacts
  - Provides clear debugging instructions

### Improved
- **Enhanced CI keyword validation workflow with detailed failure reporting**
  - Shows test summary (Total/Passed/Failed) in GitHub Step Summary
  - Lists specific failed keywords prominently in error output with visual separators
  - Creates individual GitHub error annotations for each failed keyword
  - Shows excerpt from test log with failure details
  - Uploads full test log as artifact for debugging
  - Includes failed keywords in main CI test report
  - Success case shows test statistics
- Better debugging experience with actionable error messages and clear formatting

### Technical Details
- Keywords must be single-word tokens without spaces
- Multi-word service names converted to camelCase or single-word variants
- Test suite validates all keywords trigger expected rules
- CI runs 10 random keyword tests on every push/PR
- Test output parsed and displayed in GitHub Actions UI

---

## [1.3.0] - 2025-12-20

### Fixed
- **CRITICAL**: Hook banner now shows centralized-rules version AND commit
  - Previously showed `📌 Commit: 1e7793c` (misleading - showed project's commit)
  - Now shows `📌 Version: 1.3.0 (b38033f)` (correct - shows both version and rules commit)
  - Version read from skill-rules.json (semantic versioning)
  - Commit hash injected at installation time (automatic, verifiable on GitHub)
  - Eliminates confusion about which version of centralized-rules is active
  - Best of both worlds: semantic version + verifiable commit

### Changed
- **BREAKING**: Hook script now reads keywords from `skill-rules.json` as single source of truth
  - Eliminated duplicate keyword definitions in bash script
  - All keyword mappings now centralized in `.claude/skills/skill-rules.json`
  - Easier to maintain and extend keyword mappings without editing bash code
  - Falls back to hardcoded patterns if `skill-rules.json` not found or `jq` not available

### Added
- Dynamic keyword loading from JSON configuration
- Automatic detection of all base, language, framework, and cloud provider rules from JSON
- Support for slash command detection via JSON configuration
- Graceful fallback to hardcoded patterns for backward compatibility

### Technical Details
- New `load_keyword_mappings()` function loads and validates JSON file
- Refactored `match_keywords()` to iterate through JSON structure dynamically
- Uses `jq` for JSON parsing (required dependency)
- Maintains all existing functionality while reading from single source

### Upgrade Notes
- **Action Required**: Ensure `jq` is installed (`brew install jq` on macOS)
- No changes to user-facing behavior
- Keywords can now be added/modified in `skill-rules.json` without touching bash code
- Version bumped to 1.3.0 to indicate significant architectural change

---

## [1.2.1] - 2025-12-20

### Fixed
- Removed 6 broken file references from `skill-rules.json`:
  - `cloud/azure` from cloud keywords
  - `cloud/gcp` from cloud keywords
  - `frameworks/flask` from Python frameworks
  - `frameworks/nestjs` from TypeScript frameworks
  - `frameworks/nextjs` from TypeScript frameworks
  - `languages/javascript` from languages and fileContextTriggers
- Fixed 18+ broken markdown links across documentation:
  - GitHub Discussions links → changed to /issues
  - CONTRIBUTING.md references → removed/updated
  - Google AI/Gemini links → updated URLs and added to ignore list
  - OWASP links → updated to correct URLs
  - Django documentation links → updated
  - Cursor.sh support links → updated

### Added
- Added Vercel keyword detection to hook script
- Commit ID display in install script output
- Comprehensive verification script (`scripts/verify-installation.sh`)

### Improved
- Verification script now shows all checks instead of stopping at first error
- Smart failure detection distinguishes critical vs. informational issues
- Better UX with clear success/failure messaging

---

## [1.2.0] - 2025-12-19

### Added
- GitHub Actions workflow for link validation
- Markdown link checking with custom ignore patterns
- JSON schema validation for skill-rules.json

### Changed
- Updated installation documentation with commit ID verification
- Improved error messages in verification script

---

## [1.1.0] - 2025-12-18

### Added
- Initial skill-rules.json with comprehensive keyword mappings
- Support for language-specific testing rules
- Framework-specific keyword detection

### Changed
- Enhanced hook script with better error handling
- Improved installation script with commit tracking

---

## [1.0.0] - 2025-12-15

### Added
- Initial release of centralized-rules
- Hook-based activation system for Claude Code CLI
- Progressive disclosure of coding standards
- Support for Python, TypeScript, JavaScript, Go, Rust, Java
- Support for React, Django, FastAPI, Express frameworks
- Support for AWS and Vercel cloud providers
- Installation script for global and local installation
- Verification script for installation validation

---

**Note:** Version comparison links will be added when git tags are created for releases.
