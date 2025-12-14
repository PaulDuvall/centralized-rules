# Error Handling Strategy

## Overview

The centralized-rules skill uses a **consistent, typed error handling strategy** to ensure reliability, debuggability, and graceful degradation. This document outlines the principles and practices used throughout the codebase.

## Core Principles

### 1. Never Block Claude

**CRITICAL RULE**: Hook errors must NEVER prevent Claude from responding.

```typescript
// ✅ CORRECT: Hook always returns { continue: true }
export async function handler(context: SkillContext): Promise<HookResult> {
  try {
    // ... hook logic
  } catch (error) {
    console.error('[hook] Error:', error);
    return { continue: true }; // ← Always continue
  }
}

// ❌ WRONG: Throwing would block Claude
export async function handler(context: SkillContext): Promise<HookResult> {
  const result = riskyOperation(); // Could throw!
  return { continue: true, systemPrompt: result };
}
```

### 2. Three-Tier Error Strategy

| Situation | Action | Example |
|-----------|--------|---------|
| **Unexpected failures** | THROW custom error | Invalid config, network errors (after retries), file system failures |
| **Expected "not found"** | RETURN null/undefined | Rule not found (404), file doesn't exist, no matching rules |
| **Hook/Tool boundary** | CATCH & LOG | All errors caught at hook level, never propagate to Claude |

### 3. Use Custom Error Types

All errors extend `SkillError` for consistent handling:

```typescript
// ✅ GOOD: Custom error with context
throw new ConfigurationError(
  'Invalid repository format',
  'rulesRepo',
  { provided: config.rulesRepo, expected: 'owner/repo' }
);

// ❌ BAD: Generic error
throw new Error('Invalid config');
```

## Error Types

### Base Error

```typescript
class SkillError extends Error {
  code: string;        // Machine-readable error code
  details?: unknown;   // Additional context for debugging
}
```

### Specific Error Types

| Error Type | When to Use | Example |
|------------|-------------|---------|
| `GitHubApiError` | GitHub API failures | Rate limiting, network errors, API unavailable |
| `RuleNotFoundError` | Rule doesn't exist | 404 from GitHub, missing rule path |
| `ConfigurationError` | Invalid configuration | Malformed config file, missing required fields |
| `CacheError` | Cache operation failures | Memory errors, serialization failures |
| `FileSystemError` | Unexpected file errors | Permission denied, disk full |
| `DetectionError` | Context detection failures | Unable to parse package.json, invalid directory |
| `RuleSelectionError` | Rule selection failures | Invalid scoring parameters |
| `ValidationError` | Input validation failures | Invalid parameters, type mismatches |

## Implementation Patterns

### Pattern 1: Expected "Not Found" Cases

When something might legitimately not exist, return `null`:

```typescript
export async function fetchRule(rulePath: string): Promise<Rule | null> {
  try {
    const response = await github.getContent(rulePath);
    return processRule(response);
  } catch (error) {
    // 404 is expected - rule might not exist
    if (error.status === 404) {
      return null; // ✅ Return null, don't throw
    }
    // Other errors are unexpected
    throw new GitHubApiError('Failed to fetch rule', error.status);
  }
}
```

### Pattern 2: Configuration Errors

Throw immediately for invalid configuration:

```typescript
export function loadConfig(configPath: string): Config {
  try {
    const content = fs.readFileSync(configPath, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    if (error.code === 'ENOENT') {
      throw new FileSystemError('Config not found', configPath, 'read');
    }
    if (error instanceof SyntaxError) {
      throw new ConfigurationError('Invalid JSON', 'config', { error });
    }
    throw error; // Re-throw unexpected errors
  }
}
```

### Pattern 3: Hook Error Boundary

Hooks catch ALL errors and never propagate:

```typescript
export async function beforeResponseHandler(
  context: SkillContext
): Promise<HookResult> {
  try {
    // All operations
    const result = await processRequest(context);
    return { continue: true, systemPrompt: result };
  } catch (error) {
    // Log detailed error info
    if (isSkillError(error)) {
      console.error('[hook] Skill error:', getErrorDetails(error));
    } else {
      console.error('[hook] Unexpected:', getErrorMessage(error));
    }

    // ALWAYS continue, include error in metadata
    return {
      continue: true,
      metadata: {
        error: getErrorMessage(error),
        errorDetails: isSkillError(error) ? getErrorDetails(error) : undefined,
      },
    };
  }
}
```

### Pattern 4: Graceful Degradation

Continue with reduced functionality when non-critical operations fail:

```typescript
async function detectFrameworks(directory: string): Promise<string[]> {
  const frameworks: Set<string> = new Set();

  try {
    const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf-8'));
    // ... detect from package.json
  } catch (error) {
    // Log but continue - framework detection is best-effort
    console.log('[detect] Could not parse package.json:', error);
  }

  try {
    const requirements = fs.readFileSync('requirements.txt', 'utf-8');
    // ... detect from requirements
  } catch (error) {
    // Continue - requirements.txt might not exist
  }

  return Array.from(frameworks);
}
```

## Error Utilities

### Type Guards

```typescript
// Check if error is a custom SkillError
if (isSkillError(error)) {
  console.log(error.code, error.details);
}
```

### Safe Message Extraction

```typescript
// Safely get error message from any error type
const message = getErrorMessage(error);
```

### Detailed Error Logging

```typescript
// Get structured error details for logging
const details = getErrorDetails(error);
console.error('Operation failed:', details);
```

## Best Practices

### ✅ DO

- **Use specific error types** for different failure modes
- **Include context** in error details (paths, values, operations)
- **Log errors** with appropriate detail level
- **Return null** for expected "not found" cases
- **Catch at boundaries** (hooks, tools) and never let errors escape
- **Provide helpful messages** that aid debugging

### ❌ DON'T

- **Throw generic errors** (`throw new Error('failed')`)
- **Swallow errors silently** without logging
- **Block Claude** from responding due to skill errors
- **Include sensitive data** in error messages (tokens, credentials)
- **Use console.log** for errors (use console.error)
- **Throw in hooks** without catching at the boundary

## Testing Error Handling

```typescript
describe('fetchRule error handling', () => {
  it('returns null for 404', async () => {
    mockGitHub.getContent.mockRejectedValue({ status: 404 });
    const result = await fetchRule('nonexistent.md');
    expect(result).toBeNull();
  });

  it('throws GitHubApiError for 403', async () => {
    mockGitHub.getContent.mockRejectedValue({ status: 403 });
    await expect(fetchRule('rule.md')).rejects.toThrow(GitHubApiError);
  });

  it('throws ConfigurationError for invalid repo', async () => {
    const config = { rulesRepo: 'invalid' };
    await expect(fetchRule('rule.md', config)).rejects.toThrow(
      ConfigurationError
    );
  });
});
```

## Debugging Errors

### Enable Verbose Logging

```json
{
  "config": {
    "verbose": true
  }
}
```

### Check Error Metadata

Errors include structured metadata in hook results:

```typescript
{
  continue: true,
  metadata: {
    error: "Failed to fetch rule",
    errorDetails: {
      name: "GitHubApiError",
      code: "GITHUB_API_ERROR",
      statusCode: 403,
      message: "Rate limit exceeded"
    }
  }
}
```

### Error Code Reference

| Code | Meaning | Common Causes |
|------|---------|---------------|
| `GITHUB_API_ERROR` | GitHub API failure | Rate limiting, network issues, invalid token |
| `RULE_NOT_FOUND` | Rule doesn't exist | Incorrect path, rule moved/deleted |
| `CONFIGURATION_ERROR` | Invalid config | Malformed JSON, missing required fields |
| `CACHE_ERROR` | Cache operation failed | Memory issues, serialization errors |
| `FILE_SYSTEM_ERROR` | File operation failed | Permission denied, file not found |
| `DETECTION_ERROR` | Context detection failed | Invalid directory, permission issues |
| `RULE_SELECTION_ERROR` | Rule selection failed | Invalid parameters, scoring error |
| `VALIDATION_ERROR` | Input validation failed | Type mismatch, out of range |

## Migration Guide

### Before (Old Pattern)

```typescript
try {
  const result = await operation();
  return result;
} catch (error) {
  console.error('Error:', error);
  return null;
}
```

### After (New Pattern)

```typescript
try {
  const result = await operation();
  return result;
} catch (error) {
  if (error.status === 404) {
    // Expected case - return null
    if (config.verbose) {
      console.log('[operation] Not found');
    }
    return null;
  }

  // Unexpected error - throw with context
  throw new OperationError(
    `Failed to perform operation: ${getErrorMessage(error)}`,
    'operationType',
    { error: getErrorMessage(error) }
  );
}
```

## Summary

- **Never block Claude** - hooks must always return `{ continue: true }`
- **Use custom errors** - provide context and details
- **Return null** for expected "not found" cases
- **Throw errors** for unexpected failures
- **Catch at boundaries** - hooks and tools catch all errors
- **Log appropriately** - use console.error with details
- **Enable debugging** - include metadata in hook results

Following these patterns ensures the skill is **reliable**, **debuggable**, and **resilient** to failures.
