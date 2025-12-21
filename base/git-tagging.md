# Git Tagging Rules

> **When to apply:** All projects using git for version control and release management

## Maturity Level Indicators

Apply tagging practices based on your project's maturity level:

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Tag releases | ⚠️ Recommended | ✅ Required | ✅ Required |
| Annotated tags | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Signed tags (GPG) | ❌ Not needed | ❌ Optional | ⚠️ Recommended |
| Tag naming conventions | ⚠️ Recommended | ✅ Required | ✅ Required |
| Pre-release tags | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Tag cleanup policy | ❌ Not needed | ⚠️ Recommended | ✅ Required |
| Changelog for each tag | ❌ Optional | ⚠️ Recommended | ✅ Required |

**Legend:**
- ✅ Required - Must implement this practice
- ⚠️ Recommended - Should implement when feasible
- ❌ Optional - Can skip or defer

See `base/project-maturity-levels.md` for detailed maturity framework.

## Table of Contents

- [Tag Types](#tag-types)
- [Naming Conventions](#naming-conventions)
- [When to Create Tags](#when-to-create-tags)
- [Creating Tags](#creating-tags)
- [Tag Management](#tag-management)
- [Best Practices](#best-practices)
- [Integration with Workflows](#integration-with-workflows)

---

## Tag Types

### Lightweight Tags

Simple pointer to a specific commit. Use for temporary or local markers.

```bash
# Create lightweight tag
git tag my-temporary-marker

# NOT recommended for releases
```

**Use cases:**
- Personal bookmarks
- Temporary markers during development
- Local-only references

### Annotated Tags

Full git objects with metadata (tagger, date, message). **REQUIRED for all releases.**

```bash
# Create annotated tag
git tag -a v1.2.3 -m "Release version 1.2.3"

# Or open editor for detailed message
git tag -a v1.2.3
```

**Use cases:**
- All release tags
- Milestone markers
- Any tag that will be pushed to remote

**Why annotated tags:**
- ✅ Store who created the tag and when
- ✅ Include release notes or changelog
- ✅ Can be GPG signed for security
- ✅ Show up in `git describe` output
- ✅ Treated as full objects in git

### Signed Tags

Cryptographically signed tags for security and authenticity.

```bash
# Create GPG-signed tag
git tag -s v1.2.3 -m "Signed release 1.2.3"

# Verify signed tag
git tag -v v1.2.3
```

**Use for:**
- Production releases
- Security-critical software
- Public releases
- Compliance requirements

---

## Naming Conventions

### Convention 1: Date-Based Versioning with Description (Recommended for This Repository)

**Format:** `YYYY-MM-DD-vN-brief-description`

**Structure:**
- `YYYY-MM-DD`: Release date (ISO 8601)
- `vN`: Version increment for that day (v1, v2, v3, etc.)
- `brief-description`: Hyphenated description of changes (kebab-case)

**Examples:**

```bash
# First release of the day - new feature
git tag -a 2025-12-21-v1-add-user-authentication -m "Add user authentication with JWT"

# Second release same day - bug fix
git tag -a 2025-12-21-v2-fix-login-validation -m "Fix login validation for edge cases"

# Major feature release
git tag -a 2025-12-21-v3-implement-payment-gateway -m "Implement Stripe payment gateway integration"

# Security patch
git tag -a 2025-12-21-v4-security-patch-xss -m "Security patch: Fix XSS vulnerability in comment system"
```

**Benefits:**
- ✅ Chronological ordering
- ✅ Self-documenting with descriptions
- ✅ Multiple releases per day supported
- ✅ Easy to understand what changed
- ✅ Searchable by date or topic

**Description Guidelines:**
- Keep it under 50 characters
- Use lowercase with hyphens (kebab-case)
- Be specific but concise
- Focus on the primary change
- Use action words (add, fix, update, remove, implement)

**Good descriptions:**
```
add-user-authentication
fix-memory-leak-in-parser
update-dependencies-security
remove-deprecated-api
implement-redis-caching
refactor-database-layer
```

**Bad descriptions:**
```
updates                    # Too vague
NEW_FEATURE               # Wrong case
add user auth             # Spaces not allowed
this-fixes-the-really-annoying-bug-that-was-reported-last-week  # Too long
stuff                      # Not descriptive
```

### Convention 2: Semantic Versioning (Alternative)

**Format:** `vMAJOR.MINOR.PATCH[-prerelease][+build]`

Following [Semantic Versioning 2.0.0](https://semver.org/):

```bash
# Production releases
git tag -a v1.0.0 -m "Initial stable release"
git tag -a v1.1.0 -m "Add new feature: user profiles"
git tag -a v1.1.1 -m "Fix: email validation bug"
git tag -a v2.0.0 -m "Breaking: new API structure"

# Pre-release versions
git tag -a v1.2.0-alpha.1 -m "Alpha release for testing"
git tag -a v1.2.0-beta.1 -m "Beta release"
git tag -a v1.2.0-rc.1 -m "Release candidate 1"

# Build metadata
git tag -a v1.2.0+build.123 -m "Build from CI pipeline #123"
```

**Semantic versioning rules:**
- **MAJOR**: Incompatible API changes (breaking changes)
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

**Pre-release identifiers:**
- `alpha`: Early testing, unstable
- `beta`: Feature complete, testing
- `rc` (release candidate): Final testing before release

### Convention 3: Hybrid Approach

Combine semantic versioning with date for maximum clarity:

```bash
# Format: vMAJOR.MINOR.PATCH-YYYYMMDD-description
git tag -a v1.2.3-20251221-auth-improvements -m "Version 1.2.3: Authentication improvements"
```

---

## When to Create Tags

### Always Tag:

- ✅ **Production releases** - Every deployment to production
- ✅ **Stable milestones** - Completed features or sprints
- ✅ **Pre-production releases** - Staging deployments
- ✅ **Security patches** - Any security fixes
- ✅ **Major refactors** - Significant architecture changes

### Consider Tagging:

- ⚠️ **Development milestones** - End of sprint or iteration
- ⚠️ **Breaking changes** - Before major API changes
- ⚠️ **Archive points** - Before large refactors

### Never Tag:

- ❌ **Work in progress** - Incomplete features
- ❌ **Failed builds** - Code that doesn't pass tests
- ❌ **Every commit** - Tags should be meaningful
- ❌ **Personal experiments** - Use branches instead

---

## Creating Tags

### Basic Workflow

```bash
# 1. Ensure you're on the right commit
git log --oneline -5

# 2. Create annotated tag with date-based naming
git tag -a 2025-12-21-v1-add-api-logging -m "Add comprehensive API request logging"

# 3. Verify tag was created
git tag -l "2025-12-21*"
git show 2025-12-21-v1-add-api-logging

# 4. Push tag to remote
git push origin 2025-12-21-v1-add-api-logging

# Or push all tags
git push origin --tags
```

### Creating Tags with Detailed Messages

For major releases, include detailed information:

```bash
git tag -a 2025-12-21-v1-major-release

# In editor, write detailed message:
# Major Release: API v2.0 Launch
#
# New Features:
# - GraphQL API endpoint
# - Real-time subscriptions
# - Advanced filtering
#
# Breaking Changes:
# - REST API v1 deprecated
# - Authentication now requires OAuth2
#
# Bug Fixes:
# - Fixed race condition in cache
# - Resolved memory leak in websocket handler
#
# Performance Improvements:
# - 50% faster query responses
# - Reduced memory footprint
```

### Tagging Previous Commits

If you forgot to tag a release:

```bash
# Find the commit hash
git log --oneline

# Tag that specific commit
git tag -a 2025-12-20-v1-hotfix-auth abc1234 -m "Hotfix: Authentication bypass vulnerability"

# Push the tag
git push origin 2025-12-20-v1-hotfix-auth
```

### Creating Signed Tags

For production releases requiring verification:

```bash
# Ensure GPG key is configured
git config --global user.signingkey YOUR_GPG_KEY_ID

# Create signed tag
git tag -s 2025-12-21-v1-production-release -m "Production release with security patches"

# Verify signature
git tag -v 2025-12-21-v1-production-release

# Push (signatures are preserved)
git push origin 2025-12-21-v1-production-release
```

---

## Tag Management

### Viewing Tags

```bash
# List all tags
git tag

# List tags matching pattern
git tag -l "2025-12-21*"
git tag -l "*security*"

# Show tag details
git show 2025-12-21-v1-add-logging

# List tags with messages
git tag -n5  # Show first 5 lines of message
```

### Deleting Tags

```bash
# Delete local tag
git tag -d 2025-12-21-v1-wrong-tag

# Delete remote tag
git push origin --delete 2025-12-21-v1-wrong-tag

# Or using colon syntax
git push origin :refs/tags/2025-12-21-v1-wrong-tag
```

### Updating Tags

**⚠️ WARNING: Never update tags that have been pushed to shared repositories!**

If you must update a tag locally (before pushing):

```bash
# Force update local tag
git tag -fa 2025-12-21-v1-updated -m "Updated message"

# This is BAD practice for shared tags
# Instead, create a new tag with incremented version
```

### Tag Retention Policy

Establish rules for tag cleanup:

**Keep forever:**
- Production releases
- Major versions
- Security patches

**Keep for 90 days:**
- Development milestones
- Pre-release tags
- Testing tags

**Delete after use:**
- Temporary markers
- Personal bookmarks
- Failed releases

```bash
# Find old tags (example: older than 90 days)
git for-each-ref --sort=-creatordate --format '%(refname:short) %(creatordate:short)' refs/tags | head -20

# Delete old development tags
git tag -d old-dev-tag-1 old-dev-tag-2
git push origin --delete old-dev-tag-1 old-dev-tag-2
```

---

## Best Practices

### 1. Always Use Annotated Tags for Releases

```bash
# ✅ Good: Annotated tag
git tag -a 2025-12-21-v1-release -m "Release notes here"

# ❌ Bad: Lightweight tag
git tag 2025-12-21-v1-release
```

### 2. Write Meaningful Tag Messages

```bash
# ✅ Good: Descriptive message
git tag -a 2025-12-21-v1-auth-fix -m "Fix authentication bypass in admin panel (CVE-2025-1234)"

# ❌ Bad: Vague message
git tag -a 2025-12-21-v1-auth-fix -m "updates"
```

### 3. Tag Before Deploying

```bash
# Correct workflow
git tag -a 2025-12-21-v1-deploy-prod -m "Production deployment"
git push origin 2025-12-21-v1-deploy-prod
./deploy-to-production.sh

# Not after deploying
```

### 4. Include Tags in Changelog

Update `CHANGELOG.md` with each tagged release:

```markdown
## [2025-12-21-v1-api-improvements] - 2025-12-21

### Added
- New API endpoint for bulk operations
- Request rate limiting

### Fixed
- Memory leak in connection pooling
- Race condition in cache invalidation

### Changed
- Updated authentication flow
```

### 5. Use Tags for Deployment References

```bash
# Deploy specific tag to production
kubectl set image deployment/app app=registry/myapp:2025-12-21-v1-stable

# Reference tag in CI/CD
docker build -t myapp:$(git describe --tags --always) .
```

### 6. Protect Important Tags

On GitHub/GitLab, protect production tags from deletion:

```yaml
# GitHub: Repository Settings → Tags → Protected tags
# Pattern: 2025-*-v*-production-*
# Or: v[0-9]*.[0-9]*.[0-9]*

# GitLab: Settings → Repository → Protected tags
```

### 7. Document Your Tagging Convention

In your `README.md` or `CONTRIBUTING.md`:

```markdown
## Release Tagging

We use date-based versioning: `YYYY-MM-DD-vN-description`

Examples:
- `2025-12-21-v1-add-user-auth`
- `2025-12-21-v2-fix-security-issue`

See `base/git-tagging.md` for complete guidelines.
```

---

## Integration with Workflows

### Automated Tagging in CI/CD

```yaml
# GitHub Actions: Auto-tag on release
name: Create Release Tag

on:
  workflow_dispatch:
    inputs:
      description:
        description: 'Brief description of changes'
        required: true
        type: string

jobs:
  tag:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Create tag
        run: |
          DATE=$(date +%Y-%m-%d)
          # Find next version number for today
          LAST_VERSION=$(git tag -l "${DATE}-v*" | sort -V | tail -1 | grep -oP 'v\K[0-9]+' || echo 0)
          NEXT_VERSION=$((LAST_VERSION + 1))
          TAG_NAME="${DATE}-v${NEXT_VERSION}-${{ inputs.description }}"

          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          git tag -a "${TAG_NAME}" -m "Release: ${{ inputs.description }}"
          git push origin "${TAG_NAME}"

          echo "Created tag: ${TAG_NAME}"
```

### Deployment from Tags

```bash
# Deploy specific tagged version
./deploy.sh --tag 2025-12-21-v1-production-release

# Rollback to previous tag
git tag -l --sort=-creatordate | head -2 | tail -1
./deploy.sh --tag 2025-12-20-v3-stable
```

### Generate Release Notes from Tags

```bash
# Get all tags between two dates
git tag -l --sort=-creatordate | grep "^2025-12"

# Show changes between tags
git log 2025-12-20-v1-release..2025-12-21-v1-release --oneline

# Generate changelog
git log 2025-12-20-v1-release..2025-12-21-v1-release --pretty=format:"- %s (%h)" > RELEASE_NOTES.md
```

### Automated Version Detection

```bash
# Get latest tag for builds
VERSION=$(git describe --tags --always)
echo "Building version: $VERSION"

# Use in application
echo "export const VERSION = '$VERSION';" > src/version.ts
```

---

## Summary

### Quick Reference

**Create release tag:**
```bash
git tag -a 2025-12-21-v1-brief-description -m "Detailed message"
git push origin 2025-12-21-v1-brief-description
```

**List recent tags:**
```bash
git tag -l --sort=-creatordate | head -10
```

**Delete tag:**
```bash
git tag -d tag-name
git push origin --delete tag-name
```

**Deploy from tag:**
```bash
git checkout 2025-12-21-v1-production-release
./deploy.sh
```

### The Golden Rules

1. ✅ **Always use annotated tags** for releases (`-a` flag)
2. ✅ **Write descriptive messages** explaining what changed
3. ✅ **Follow naming convention** consistently (date-based or semantic)
4. ✅ **Tag before deploying** to production
5. ✅ **Never modify pushed tags** - create new ones instead
6. ✅ **Document tags in changelog**
7. ✅ **Sign production tags** for security (when required)
8. ❌ **Never tag broken code** - all tests must pass

---

## Related Resources

- See `base/git-workflow.md` for commit and push frequency
- See `base/cicd-comprehensive.md` for artifact versioning
- See `base/12-factor-app.md` for build/release/run separation
- See `CHANGELOG.md` for release history format
- External: [Semantic Versioning](https://semver.org/)
- External: [Keep a Changelog](https://keepachangelog.com/)
