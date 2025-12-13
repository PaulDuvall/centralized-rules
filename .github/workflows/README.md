# GitHub Actions Workflows

This directory contains automated workflows that validate and test the progressive disclosure implementation on every change to the repository.

## Workflows

### CI Workflow (`ci.yml`)

**Triggers:** Push to `main`, Pull Requests, Manual dispatch

All tests run automatically on every push and pull request to ensure the repository maintains its progressive disclosure architecture and quality standards.

**Jobs:**
- **validate-progressive-disclosure**: Runs the comprehensive validation script that tests:
  - Directory structure compliance
  - AGENTS.md configuration
  - Base rules are language-agnostic
  - Generated RULES.md has progressive disclosure
  - Sync script functionality
  - Documentation completeness
  - Real project integration test

- **shellcheck**: Lints all bash scripts for:
  - Syntax errors
  - Common pitfalls
  - Best practices
  - Security issues

- **test-sync-script**: Comprehensive matrix testing across 7 different project types:
  - Python + FastAPI
  - TypeScript + React
  - Go + Gin API
  - Python + Django + PostgreSQL
  - TypeScript + Next.js + AWS
  - Go + Gin + AWS + Docker
  - Multi-language (Python + TypeScript)

  Validates that each project type:
  - Generates correct `.claude/AGENTS.md`
  - Includes progressive disclosure warnings
  - Creates proper rule directory structure
  - Detects all languages, frameworks, and cloud providers correctly

- **verify-documentation**: Checks that:
  - README mentions progressive disclosure
  - ARCHITECTURE.md explains the design
  - All rule files are markdown format
  - No broken internal links

- **all-tests-passed**: Summary job that ensures all tests succeeded before merging

## Artifacts

Workflows generate artifacts for debugging (5 days retention):

- **validation-results**: Complete validation output and generated files from the progressive disclosure validation
- **test-project-{type}**: Generated `.claude/` directory for each of the 7 project types tested

## Local Testing

You can run the same validations locally:

```bash
# Run progressive disclosure validation
./scripts/validate-progressive-disclosure.sh

# Run shellcheck
shellcheck scripts/*.sh sync-ai-rules.sh

# Test sync script
./sync-ai-rules.sh
```

## Workflow Badge

Add this badge to your README.md:

```markdown
![CI](https://github.com/PaulDuvall/centralized-rules/workflows/CI/badge.svg)
```

## Troubleshooting

### Workflow Failures

1. **Progressive Disclosure Validation Fails**
   - Check the validation output in the workflow logs
   - Run `./scripts/validate-progressive-disclosure.sh` locally
   - Review recent changes to rule files or sync script

2. **ShellCheck Warnings**
   - Review shellcheck output for specific issues
   - Fix or suppress warnings with `# shellcheck disable=SC####`
   - Document why suppression is necessary

3. **Sync Script Test Failures**
   - Download the test artifacts to see what was generated
   - Verify language/framework detection logic
   - Check rule file paths and content

4. **Documentation Verification Fails**
   - Ensure all documentation mentions progressive disclosure
   - Check that all rule files are `.md` format
   - Validate internal links are correct

## Contributing

When adding new features:

1. Update validation scripts if needed
2. Add test cases to workflow matrices
3. Update this README with new workflows or jobs
4. Ensure CI passes before merging

## Permissions

Workflows use minimal permissions:
- `contents: read` for checking out code (read-only)

## Security

- No secrets are used in these workflows
- All operations are read-only
- Artifacts are automatically cleaned up after 5-day retention period
- Tests run in isolated temporary directories that are cleaned up automatically
