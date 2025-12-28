# Changelog

All notable changes to the Centralized Rules Skill will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Semantic Category Classification System** for intelligent rule matching
  - 9 prompt categories: 6 code categories + 3 non-code categories
  - 70+ specialized regex patterns for high-confidence classification
  - Two-phase classification: pattern matching → keyword scoring fallback
  - Category-aware rule boosting (+15-30 points for relevant rules)
  - Zero false positives/negatives in comprehensive testing (71 tests)

- **Token Optimization** via early exit for non-code prompts
  - Skips rule injection for LEGAL_BUSINESS, GENERAL_QUESTION, and UNCLEAR categories
  - Saves ~10,000 tokens per non-code request
  - Maintains full functionality for all code-related prompts

- **Enhanced Rule Selection**
  - Category-specific topic boosting (debugging, testing, architecture, etc.)
  - Smarter prioritization based on prompt intent
  - Better relevance scores combining context + category

- **Comprehensive Documentation**
  - JSDoc comments on all public functions
  - Architecture guide (`docs/classification-system.md`)
  - Classification section in README with examples
  - Pattern design principles and troubleshooting guide

- **Test Coverage**
  - 17 unit tests for core classification logic
  - 33 pattern validation tests with edge cases
  - 13 integration tests for category-aware boosting
  - 8 hook integration tests for end-to-end workflow

### Changed

- **beforeResponse Hook** now includes classification step
  - Classifies prompt before context detection
  - Exits early for non-code categories (saves processing time)
  - Passes category to rule selection for boosting
  - Includes classification metadata in response

- **Rule Selection Algorithm** enhanced with category awareness
  - Accepts optional `category` parameter
  - Boosts rules matching category topics
  - Maintains backward compatibility when no category provided

### Fixed

- **False Positives** on business/legal prompts
  - "Operating agreement review" no longer loads code rules
  - "Privacy policy draft" correctly skipped
  - "SLA agreement terms" distinguished from "SLA monitoring API"

- **False Negatives** on vague code prompts
  - "How do I test this component?" now loads testing rules
  - "Implement authentication" correctly classified as code
  - Better handling of conversational coding questions

## [0.1.0] - 2024-12-XX

### Added

- Initial skill implementation
- Project context detection (languages, frameworks, cloud providers)
- Rule selection algorithm with scoring
- GitHub fetching with caching (1-hour TTL)
- beforeResponse hook for automatic rule injection
- Comprehensive test suite (unit, integration, E2E)
- TypeScript with strict mode
- ESLint + Prettier configuration
- Development workflow (build, test, lint, format)

### Features

- **Smart Context Detection**: Automatically detects project technologies
- **Progressive Disclosure**: Loads 3-5 most relevant rules per request
- **Token Budget**: Respects maxRules and maxTokens limits
- **Caching**: Rules cached for 1 hour for performance
- **Verbose Logging**: Debug mode for troubleshooting

### Documentation

- README with installation and usage instructions
- Migration guide from sync script approach
- Troubleshooting guide
- Development setup instructions

## Categories

Categories used in this changelog:

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Features that will be removed in future versions
- **Removed**: Features that have been removed
- **Fixed**: Bug fixes
- **Security**: Security vulnerability fixes

## Links

- [Unreleased]: https://github.com/paulduvall/centralized-rules/compare/v0.1.0...HEAD
- [0.1.0]: https://github.com/paulduvall/centralized-rules/releases/tag/v0.1.0
