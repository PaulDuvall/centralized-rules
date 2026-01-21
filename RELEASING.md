# Release Process

This document describes how to create releases for centralized-rules.

## Version Numbering

We follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html):

- **v0.x.x** - Pre-1.0 releases (breaking changes allowed in MINOR)
- **MAJOR** - Breaking changes (after v1.0.0)
- **MINOR** - New features, breaking changes in v0.x
- **PATCH** - Bug fixes, documentation updates

## When to Release

Create a new release when:

- New features are added and tested
- Bug fixes are ready for users
- Documentation improvements benefit users
- Security patches need deployment

## Pre-Release Checklist

Before creating a release, verify:

- [ ] All tests pass locally: `./tests/test-override.sh`
- [ ] CI is green on main branch
- [ ] CHANGELOG.md updated with release notes
- [ ] README.md reflects current features
- [ ] No known critical bugs
- [ ] Version number decided (see Version Numbering above)

## Release Steps

### 1. Update CHANGELOG.md

Move items from `[Unreleased]` to new version section:

```markdown
## [Unreleased]

## [0.2.0] - 2026-01-21

### Added
- New feature description

### Changed
- Changed behavior description

### Fixed
- Bug fix description
```

### 2. Create and Push Tag

```bash
# Create annotated tag
git tag -a v0.2.0 -m "Release v0.2.0: Brief description"

# Push tag to trigger release workflow
git push origin v0.2.0
```

### 3. Verify Release

1. Check [GitHub Actions](https://github.com/paulduvall/centralized-rules/actions) for workflow success
2. Verify [Releases page](https://github.com/paulduvall/centralized-rules/releases) shows new release
3. Verify assets are attached:
   - `centralized-rules-v0.2.0.tar.gz`
   - `install-hooks-v0.2.0.sh`
   - `checksums.txt`
4. Test installation from release:
   ```bash
   curl -fsSL https://github.com/paulduvall/centralized-rules/releases/latest/download/install-hooks.sh | bash
   ```

## Hotfix Process

For urgent fixes to a released version:

### 1. Create Hotfix Branch

```bash
git checkout -b hotfix/v0.1.1 v0.1.0
```

### 2. Apply Fix

Make minimal changes to fix the issue.

### 3. Update CHANGELOG

Add entry for the patch version.

### 4. Tag and Release

```bash
git tag -a v0.1.1 -m "Hotfix v0.1.1: Fix description"
git push origin v0.1.1
```

### 5. Merge Back to Main

```bash
git checkout main
git merge hotfix/v0.1.1
git push origin main
```

## Release Assets

Each release includes:

| Asset | Description |
|-------|-------------|
| `centralized-rules-{version}.tar.gz` | Complete rules package |
| `install-hooks-{version}.sh` | Standalone installer script |
| `checksums.txt` | SHA256 checksums for verification |

## Troubleshooting

### Release workflow failed

1. Check [Actions log](https://github.com/paulduvall/centralized-rules/actions) for error details
2. Common issues:
   - Tests failing → Fix tests, delete tag, recreate
   - Permission issues → Verify `GITHUB_TOKEN` permissions

### Delete and recreate a tag

```bash
# Delete remote tag
git push --delete origin v0.2.0

# Delete local tag
git tag -d v0.2.0

# Fix issues, then recreate
git tag -a v0.2.0 -m "Release v0.2.0"
git push origin v0.2.0
```

### Users report old version

Ensure users are installing from releases:

```bash
# Correct (from releases)
curl -fsSL https://github.com/paulduvall/centralized-rules/releases/latest/download/install-hooks.sh | bash

# For bleeding edge (developers only)
curl -fsSL https://raw.githubusercontent.com/paulduvall/centralized-rules/main/install-hooks.sh | bash -s -- --edge
```
