# Git Tagging Rules

> **When to apply:** All projects using git for version control and release management

## Maturity Level Indicators

| Practice | MVP/POC | Pre-Production | Production |
|----------|---------|----------------|------------|
| Tag releases | ⚠️ Recommended | ✅ Required | ✅ Required |
| Annotated tags | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Signed tags (GPG) | ❌ Not needed | ❌ Optional | ⚠️ Recommended |
| Tag naming conventions | ⚠️ Recommended | ✅ Required | ✅ Required |
| Pre-release tags | ❌ Optional | ⚠️ Recommended | ✅ Required |
| Changelog for each tag | ❌ Optional | ⚠️ Recommended | ✅ Required |

See `base/project-maturity-levels.md` for detailed maturity framework.

---

## Tag Types

| Type | Command | Use Case | Metadata |
|------|---------|----------|----------|
| **Lightweight** | `git tag my-tag` | Personal bookmarks, temporary markers | No |
| **Annotated** | `git tag -a v1.0.0 -m "msg"` | **ALL releases**, milestones | Yes (tagger, date, message) |
| **Signed** | `git tag -s v1.0.0 -m "msg"` | Production, security-critical releases | Yes + GPG signature |

**Always use annotated tags for releases.** They store metadata, support signatures, appear in `git describe`, and are treated as full git objects.

---

## Naming Conventions

### Recommended: Date-Based Semantic Versioning

**Format:** `YYYY-MM-DD-vMAJOR.MINOR.PATCH-description`

| Component | Purpose | Example |
|-----------|---------|---------|
| `YYYY-MM-DD` | Release date (ISO 8601) | `2025-12-21` |
| `vMAJOR.MINOR.PATCH` | [SemVer 2.0.0](https://semver.org/) version | `v1.2.3` |
| `description` | Brief change summary (kebab-case) | `add-user-auth` |

**Semantic Version Rules:**

| Version | Increment When | Example |
|---------|----------------|---------|
| **PATCH** (v0.0.X) | Bug fixes, backward compatible | v0.0.1 → v0.0.2 |
| **MINOR** (v0.X.0) | New features, backward compatible | v0.1.0 → v0.2.0 |
| **MAJOR** (vX.0.0) | Breaking changes | v0.9.0 → v1.0.0 |

**Examples:**
```bash
2025-12-21-v0.1.0-add-user-authentication      # New feature
2025-12-21-v0.1.1-fix-login-validation         # Bug fix
2025-12-21-v1.0.0-implement-payment-gateway    # Breaking change
2025-12-21-v0.1.2-security-patch-xss           # Security fix
```

**Description Guidelines:**
- Keep under 50 characters
- Use lowercase with hyphens (kebab-case)
- Use action words: add, fix, update, remove, implement
- Be specific but concise

### Alternative: Standard Semantic Versioning

**Format:** `vMAJOR.MINOR.PATCH[-prerelease][+build]`

```bash
v1.0.0                    # Production release
v1.1.0                    # New feature
v1.1.1                    # Bug fix
v2.0.0                    # Breaking change
v1.2.0-alpha.1            # Alpha release
v1.2.0-beta.1             # Beta release
v1.2.0-rc.1               # Release candidate
v1.2.0+build.123          # Build metadata
```

---

## When to Create Tags

| Tag | Never | Consider | Always |
|-----|-------|----------|--------|
| Production releases | | | ✅ |
| Security patches | | | ✅ |
| Pre-production deployments | | | ✅ |
| Stable milestones | | | ✅ |
| Development milestones | | ⚠️ | |
| Before major refactors | | ⚠️ | |
| Work in progress | ❌ | | |
| Failed builds | ❌ | | |
| Personal experiments | ❌ | | |

---

## Creating Tags

### Basic Workflow

```bash
# 1. Verify commit
git log --oneline -5

# 2. Create annotated tag
git tag -a 2025-12-21-v0.1.0-add-api-logging -m "Add API request logging"

# 3. Verify tag
git show 2025-12-21-v0.1.0-add-api-logging

# 4. Push tag
git push origin 2025-12-21-v0.1.0-add-api-logging
```

### Detailed Changelog (Recommended)

**Best Practice:** Include all changes since last tag.

```bash
# Auto-generate detailed changelog
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
TAG_NAME="2025-12-21-v0.2.0-brief-description"

git tag -a "${TAG_NAME}" -m "$(cat <<EOF
Brief Summary of Changes

Changes since ${LAST_TAG:-initial commit}:
$(git log ${LAST_TAG}..HEAD --oneline --no-merges)

Files Changed:
$(git diff ${LAST_TAG}..HEAD --stat 2>/dev/null || git diff --stat)
EOF
)"

git push origin "${TAG_NAME}"
```

**Benefits:**
- Complete release history in one place
- Easy rollback decisions
- Automatic release notes generation
- Full context without checking commits

### Tag Previous Commit

```bash
# Tag specific commit
git tag -a 2025-12-20-v0.0.2-hotfix-auth abc1234 -m "Hotfix message"
git push origin 2025-12-20-v0.0.2-hotfix-auth
```

### Signed Tags

```bash
# Configure GPG key
git config --global user.signingkey YOUR_GPG_KEY_ID

# Create signed tag
git tag -s 2025-12-21-v1.0.0-production -m "Production release"

# Verify signature
git tag -v 2025-12-21-v1.0.0-production

# Push (signature preserved)
git push origin 2025-12-21-v1.0.0-production
```

---

## Tag Management

### Viewing Tags

```bash
git tag                                         # List all
git tag -l "2025-12-21*"                       # Pattern match
git tag -l --sort=-creatordate | head -10      # Recent tags
git show 2025-12-21-v0.1.0-add-logging         # Tag details
git tag -n5                                    # With messages
```

### Deleting Tags

```bash
git tag -d tag-name                            # Delete local
git push origin --delete tag-name              # Delete remote
```

### Retention Policy

| Tag Type | Retention |
|----------|-----------|
| Production releases, major versions, security patches | Forever |
| Development milestones, pre-releases | 90 days |
| Temporary markers, failed releases | Delete after use |

```bash
# Find old tags
git for-each-ref --sort=-creatordate --format '%(refname:short) %(creatordate:short)' refs/tags | head -20

# Delete old tags
git tag -d old-tag
git push origin --delete old-tag
```

---

## Best Practices

### 1. Always Use Annotated Tags

```bash
# ✅ Correct
git tag -a 2025-12-21-v1.0.0-release -m "Release notes"

# ❌ Wrong
git tag 2025-12-21-v1.0.0-release
```

### 2. Include Complete Changelog

```bash
# ✅ Best: Detailed changelog
LAST_TAG=$(git describe --tags --abbrev=0)
git tag -a 2025-12-21-v0.2.0-auth-fix -m "$(cat <<EOF
Fix authentication bypass (CVE-2025-1234)

Changes since ${LAST_TAG}:
$(git log ${LAST_TAG}..HEAD --oneline)

Files Changed:
$(git diff ${LAST_TAG}..HEAD --stat)
EOF
)"

# ✅ Good: Descriptive message
git tag -a 2025-12-21-v0.2.0-auth-fix -m "Fix admin panel auth bypass"

# ❌ Bad: Vague message
git tag -a 2025-12-21-v0.2.0-auth-fix -m "updates"
```

### 3. Tag Before Deploying

```bash
# ✅ Correct workflow
git tag -a 2025-12-21-v1.0.0-deploy -m "Production deployment"
git push origin 2025-12-21-v1.0.0-deploy
./deploy-to-production.sh
```

### 4. Update CHANGELOG.md

```markdown
## [2025-12-21-v0.2.0-api-improvements] - 2025-12-21

### Added
- Bulk operations API endpoint
- Request rate limiting

### Fixed
- Memory leak in connection pooling
- Cache invalidation race condition
```

### 5. Protect Production Tags

Configure repository settings to prevent tag deletion:

```yaml
# GitHub: Settings → Tags → Protected tags
# Pattern: *-v[0-9]*.[0-9]*.[0-9]*-*

# GitLab: Settings → Repository → Protected tags
```

---

## Integration with Workflows

### Automated Tagging (CI/CD)

```yaml
# GitHub Actions: Auto-tag with semantic versioning
name: Create Release Tag

on:
  workflow_dispatch:
    inputs:
      version_type:
        description: 'Version increment'
        required: true
        type: choice
        options: [patch, minor, major]
      description:
        description: 'Change description'
        required: true

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
          LATEST_TAG=$(git tag -l "${DATE}-v*" | sort -V | tail -1)

          # Calculate new version
          if [ -z "$LATEST_TAG" ]; then
            case "${{ inputs.version_type }}" in
              patch) VERSION="0.0.1" ;;
              minor) VERSION="0.1.0" ;;
              major) VERSION="1.0.0" ;;
            esac
          else
            CURRENT=$(echo "$LATEST_TAG" | grep -oP 'v\K[0-9]+\.[0-9]+\.[0-9]+')
            MAJOR=$(echo "$CURRENT" | cut -d. -f1)
            MINOR=$(echo "$CURRENT" | cut -d. -f2)
            PATCH=$(echo "$CURRENT" | cut -d. -f3)

            case "${{ inputs.version_type }}" in
              patch) VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))" ;;
              minor) VERSION="${MAJOR}.$((MINOR + 1)).0" ;;
              major) VERSION="$((MAJOR + 1)).0.0" ;;
            esac
          fi

          TAG_NAME="${DATE}-v${VERSION}-${{ inputs.description }}"
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag -a "${TAG_NAME}" -m "Release: ${{ inputs.description }}"
          git push origin "${TAG_NAME}"
```

### Deployment from Tags

```bash
# Deploy specific tag
./deploy.sh --tag 2025-12-21-v1.0.0-production

# Rollback to previous tag
PREV_TAG=$(git tag -l --sort=-creatordate | head -2 | tail -1)
./deploy.sh --tag $PREV_TAG
```

### Generate Release Notes

```bash
# Show changes between tags
git log tag1..tag2 --oneline

# Generate changelog
git log tag1..tag2 --pretty=format:"- %s (%h)" > RELEASE_NOTES.md
```

### Version Detection

```bash
# Get latest tag
VERSION=$(git describe --tags --always)

# Use in builds
docker build -t myapp:$VERSION .
echo "export const VERSION = '$VERSION';" > src/version.ts
```

---

## Quick Reference

### Create Release Tag

```bash
# With detailed changelog (RECOMMENDED)
LAST_TAG=$(git describe --tags --abbrev=0)
TAG_NAME="2025-12-21-v0.1.0-brief-description"
git tag -a "${TAG_NAME}" -m "$(cat <<EOF
Summary

Changes since ${LAST_TAG}:
$(git log ${LAST_TAG}..HEAD --oneline --no-merges)
EOF
)"
git push origin "${TAG_NAME}"

# Simple release
git tag -a 2025-12-21-v0.1.0-description -m "Message"
git push origin 2025-12-21-v0.1.0-description
```

### Common Operations

```bash
# List recent tags
git tag -l --sort=-creatordate | head -10

# Delete tag
git tag -d tag-name && git push origin --delete tag-name

# Deploy from tag
git checkout tag-name && ./deploy.sh
```

---

## Golden Rules

1. ✅ **Always use annotated tags** (`-a` flag) for releases
2. ✅ **Follow semantic versioning** (vMAJOR.MINOR.PATCH)
3. ✅ **Include detailed changelog** with changes since last tag
4. ✅ **Use descriptive names** (kebab-case, action verbs)
5. ✅ **Tag before deploying** to production
6. ✅ **Never modify pushed tags** (create new version instead)
7. ✅ **Document in CHANGELOG.md**
8. ✅ **Sign production tags** when required
9. ❌ **Never tag broken code** (tests must pass)

---

## Related Resources

- `base/git-workflow.md` - Commit and push frequency
- `base/cicd-comprehensive.md` - Artifact versioning
- `base/12-factor-app.md` - Build/release/run separation
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
