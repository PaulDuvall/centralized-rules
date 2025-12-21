# Changelog

All notable changes to centralized-rules will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.0] - 2025-12-20

### Changed - **BREAKING**: Hook script now reads keywords from `skill-rules.json` as single source of truth
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

[1.3.0]: https://github.com/paulduvall/centralized-rules/compare/v1.2.1...v1.3.0
[1.2.1]: https://github.com/paulduvall/centralized-rules/compare/v1.2.0...v1.2.1
[1.2.0]: https://github.com/paulduvall/centralized-rules/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/paulduvall/centralized-rules/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/paulduvall/centralized-rules/releases/tag/v1.0.0
