# Link Checking Strategy

## Overview

This repository uses a **two-tier link checking approach** to balance reliability with avoiding false positives from flaky domains.

## The Problem

Some legitimate websites (W3C, GNU.org, etc.) return `403 Forbidden` for automated link checkers due to bot protection, even though the links work fine in browsers. Simply ignoring these domains creates blind spots where real broken links could go undetected.

## Our Solution: Two-Tier Checking

### Tier 1: Critical Link Check ✅ (Blocks CI)

**Job:** `check-markdown-links`
**Config:** `.github/markdown-link-check-config.json`
**Behavior:** Failures **block** PRs and pushes

This job checks all links EXCEPT known-flaky domains. If this fails, it indicates a real broken link that needs immediate attention.

**Ignored patterns:**
- GitHub PR/issue URLs (may not exist yet)
- `localhost` URLs (local development)
- Internal anchor links (`#`)
- Known-flaky domains: W3C, GNU.org, Google AI Dev (checked in Tier 2)

### Tier 2: Flaky Link Check ⚠️ (Advisory Only)

**Job:** `check-flaky-links`
**Config:** `.github/markdown-link-check-config-flaky.json`
**Behavior:** Failures **do NOT block** CI (`continue-on-error: true`)

This job checks ONLY the known-flaky domains using:
- Browser-like user agent headers
- Longer timeouts (30s vs 20s)
- More retries (5 vs 3)
- Accepts 403 status as "alive" (since these domains often return 403 for bots)

**Checked domains:**
- `*.w3.org` (validator.w3.org, jigsaw.w3.org, www.w3.org)
- `www.gnu.org`
- `ai.google.dev`

## Benefits

✅ **No false positives blocking CI** - Flaky domains won't break your build
✅ **Still get visibility** - Advisory job shows if flaky links have issues
✅ **Prevents ignore list bloat** - Clear separation between critical and flaky
✅ **Documented verification dates** - Track when flaky links were last manually checked
✅ **No alert fatigue** - Only critical failures require immediate action

## Workflow

1. **When critical check fails** → Investigate immediately, likely a real broken link
2. **When flaky check fails** → Investigate when convenient, may be temporary
3. **When flaky check passes** → Update "Last verified" date in comments

## Maintenance

### Adding a New Flaky Domain

If you discover a new domain that blocks automated checkers:

1. **Verify it's legitimate** - Check the link manually in a browser
2. **Add to critical ignore list** in `markdown-link-check-config.json`:
   ```json
   {
     "$comment": "Domain X returns 403 for bots - checked in flaky job. Last verified: YYYY-MM-DD",
     "pattern": "^https://example\\.com"
   }
   ```
3. **Update flaky config** in `markdown-link-check-config-flaky.json` if needed
4. **Document the decision** in this file

### Reviewing Ignored Links

Periodically (quarterly recommended):
1. Check the "Last verified" dates in config comments
2. Manually verify old entries still work
3. Update dates after verification
4. Remove any that are actually broken

## Files

- `.github/workflows/check-broken-links.yml` - Workflow definition
- `.github/markdown-link-check-config.json` - Critical check config
- `.github/markdown-link-check-config-flaky.json` - Flaky check config
- `.github/LINK_CHECKING.md` - This documentation

## References

- [markdown-link-check](https://github.com/gaurav-nelson/github-action-markdown-link-check) - Action used
- [Original issue](https://github.com/PaulDuvall/centralized-rules/actions/runs/20561804830) - What prompted this approach
