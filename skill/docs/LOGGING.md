# Structured Logging Guide

## Overview

The centralized-rules skill uses a **structured logging system** that provides consistent, leveled logging with contextual information across all components. This replaces scattered `console.log` calls with a unified logging service.

## Quick Start

### Using Global Loggers

```typescript
import { loggers } from '../services/logger';

// Use component-specific loggers
loggers.hook.info('Hook executed successfully', { duration: '1.2s' });
loggers.detection.debug('Languages detected', { languages: ['typescript', 'python'] });
loggers.rules.warn('Slow API response', { duration: '3.5s', threshold: '2s' });
loggers.cache.error('Cache write failed', error, { key: 'rule-123' });
```

### Creating Custom Loggers

```typescript
import { createLogger } from '../services/logger';

const logger = createLogger('my-component');
logger.info('Component initialized');
```

## Log Levels

Logs are filtered by level (in order of severity):

| Level | When to Use | Example |
|-------|-------------|---------|
| `DEBUG` | Detailed diagnostic information | Cache hits, function entry/exit, variable values |
| `INFO` | General informational messages | Operation started/completed, configuration loaded |
| `WARN` | Warning messages for concerning situations | Slow operations, deprecated features, fallbacks used |
| `ERROR` | Error messages for failures | Exceptions, API failures, validation errors |

### Setting Log Level

**Via Environment Variable:**
```bash
export LOG_LEVEL=DEBUG  # Show all logs
export LOG_LEVEL=INFO   # Default
export LOG_LEVEL=WARN   # Only warnings and errors
export LOG_LEVEL=ERROR  # Only errors
export LOG_LEVEL=NONE   # Disable logging
```

**Via Configuration:**
```typescript
import { loggers, configureLogging, LogLevel } from '../services/logger';

// Configure globally based on verbose flag
configureLogging(verbose);  // DEBUG if verbose, INFO otherwise

// Set level for specific logger
loggers.hook.setLevel(LogLevel.DEBUG);
```

## Logging Methods

### debug(message, context?)

Detailed diagnostic information for troubleshooting.

```typescript
logger.debug('Cache hit', { rulePath, ttl: 3600 });
logger.debug('Detected languages', {
  languages: ['typescript', 'python'],
  confidence: 0.95
});
```

### info(message, context?)

General informational messages about normal operations.

```typescript
logger.info('Hook execution started');
logger.info('Rules loaded successfully', { count: 5 });
```

### warn(message, context?)

Warning messages for unusual but non-critical situations.

```typescript
logger.warn('Slow API response detected', {
  duration: '3.5s',
  threshold: '2s'
});
logger.warn('Using cached data due to API failure', {
  age: '2h'
});
```

### error(message, error?, context?)

Error messages for failures and exceptions.

```typescript
logger.error('Failed to fetch rule', error, { rulePath });
logger.error('GitHub API rate limit exceeded', error, {
  remaining: 0,
  resetAt: '2024-01-15T10:00:00Z'
});
```

## Structured Context

Always provide context objects for better debugging:

### ✅ GOOD - With Context

```typescript
logger.info('Rule selected', {
  rulePath: 'base/code-quality.md',
  score: 95,
  matchedTopics: ['quality', 'testing'],
});

logger.warn('Slow detection', {
  duration: '2.5s',
  threshold: '1s',
  directory: '/path/to/project',
});

logger.error('Parse failed', error, {
  file: 'package.json',
  line: 42,
  column: 5,
});
```

### ❌ BAD - Without Context

```typescript
logger.info('Rule selected');
logger.warn('Slow');
logger.error('Failed', error);
```

## Component Loggers

Pre-configured loggers for common components:

```typescript
import { loggers } from '../services/logger';

// Hook-related logs
loggers.hook.info('Auto-load enabled');
loggers.hook.debug('User message analyzed', { topics, action });

// Detection-related logs
loggers.detection.debug('Checking for Python frameworks');
loggers.detection.info('Context detected', { languages, frameworks });

// Rule fetching logs
loggers.rules.debug('Fetching from GitHub', { rulePath });
loggers.rules.warn('Rule not found', { rulePath, status: 404 });

// Cache-related logs
loggers.cache.debug('Cache hit', { key });
loggers.cache.info('Cache cleared', { count: 50 });

// Configuration logs
loggers.config.info('Configuration loaded', { source: 'rules-config.json' });
loggers.config.error('Invalid config', error, { field: 'rulesRepo' });
```

## Advanced Features

### Child Loggers

Create sub-component loggers:

```typescript
const parentLogger = loggers.detection;
const childLogger = parentLogger.child('frameworks');

childLogger.debug('Checking package.json');
// Output: [detection:frameworks] DEBUG: Checking package.json
```

### Check if Level is Enabled

Avoid expensive operations when log level is disabled:

```typescript
if (logger.isLevelEnabled(LogLevel.DEBUG)) {
  const expensiveDebugData = computeExpensiveData();
  logger.debug('Computed data', expensiveDebugData);
}
```

### Utility Functions

```typescript
import { formatDuration, formatBytes } from '../services/logger';

logger.info('Operation complete', {
  duration: formatDuration(1250),  // "1.25s"
  size: formatBytes(1048576),       // "1.00MB"
});
```

## Log Output Format

Logs are formatted as:

```
[timestamp] [component] LEVEL: message - context
```

**Examples:**

```
[10:15:23] [hook] INFO: Hook execution started
[10:15:23] [detection] DEBUG: Languages detected - {"languages":["typescript","python"],"duration":"150ms"}
[10:15:24] [rules] WARN: Slow API response - {"duration":"3.5s","threshold":"2s"}
[10:15:24] [hook] ERROR: Hook execution failed - {"error":"Rate limit exceeded"}
```

## Best Practices

### 1. Use Appropriate Log Levels

```typescript
// ✅ GOOD
logger.debug('Entering function', { params });      // Debug
logger.info('Operation completed', { count });      // Info
logger.warn('Fallback used', { reason });          // Warn
logger.error('Operation failed', error, { ctx });   // Error

// ❌ BAD
logger.info('x = 42');                             // Use debug
logger.error('Invalid input');                     // Use warn if recoverable
```

### 2. Include Relevant Context

```typescript
// ✅ GOOD
logger.error('Failed to fetch rule', error, {
  rulePath: 'base/security.md',
  repo: 'owner/repo',
  branch: 'main',
  attempt: 3,
});

// ❌ BAD
logger.error('Failed', error);
```

### 3. Use Structured Data

```typescript
// ✅ GOOD
logger.info('Rules selected', {
  count: 5,
  paths: rules.map(r => r.path),
  totalTokens: 12500,
});

// ❌ BAD
logger.info(`Selected ${rules.length} rules: ${rules.map(r => r.path).join(', ')}`);
```

### 4. Log at Boundaries

Log at component boundaries for traceability:

```typescript
export async function fetchRule(path: string): Promise<Rule | null> {
  logger.debug('Fetching rule', { path });  // Entry

  try {
    const rule = await fetchFromGitHub(path);
    logger.debug('Rule fetched', { path, size: rule.content.length });  // Success
    return rule;
  } catch (error) {
    logger.error('Failed to fetch rule', error, { path });  // Error
    return null;
  }
}
```

### 5. Don't Log Sensitive Data

```typescript
// ✅ GOOD
logger.debug('API request', {
  url: 'https://api.github.com/repos/owner/repo',
  method: 'GET',
});

// ❌ BAD - Contains token
logger.debug('API request', {
  url: 'https://api.github.com/repos/owner/repo',
  headers: { Authorization: `Bearer ${token}` },  // ← Sensitive!
});
```

## Migration from console.log

### Before

```typescript
if (config.verbose) {
  console.log('[my-component] Operation started');
}
console.error('[my-component] Error:', error.message);
console.warn('[my-component] Slow operation:', duration);
```

### After

```typescript
logger.debug('Operation started');
logger.error('Operation failed', error);
logger.warn('Slow operation detected', {
  duration: formatDuration(duration),
  threshold: '2s',
});
```

## Troubleshooting

### Logs Not Appearing

**Check log level:**
```typescript
console.log('Current level:', logger.getLevel());
logger.setLevel(LogLevel.DEBUG);
```

**Check if logging is enabled:**
```typescript
console.log('Enabled:', logger.isLevelEnabled(LogLevel.DEBUG));
logger.enable();
```

### Too Many Logs

**Increase log level:**
```bash
export LOG_LEVEL=WARN  # Only warnings and errors
```

**Disable specific component:**
```typescript
loggers.cache.setLevel(LogLevel.NONE);
```

### Missing Context in Logs

Always pass context objects:

```typescript
// Before
logger.info('Operation complete');

// After
logger.info('Operation complete', {
  duration: formatDuration(elapsed),
  itemsProcessed: count,
});
```

## Testing with Logs

### Capture Logs in Tests

```typescript
import { createLogger, LogLevel } from '../services/logger';

describe('MyComponent', () => {
  let logger: Logger;
  let logs: string[] = [];

  beforeEach(() => {
    logger = createLogger('test');
    logger.setLevel(LogLevel.DEBUG);

    // Capture console.log
    jest.spyOn(console, 'log').mockImplementation((msg) => logs.push(msg));
  });

  it('logs operation', () => {
    myOperation(logger);
    expect(logs).toContain(expect.stringContaining('Operation complete'));
  });
});
```

### Disable Logs in Tests

```typescript
beforeAll(() => {
  loggers.hook.disable();
  loggers.detection.disable();
});
```

## Environment Variables

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `LOG_LEVEL` | `DEBUG`, `INFO`, `WARN`, `ERROR`, `NONE` | `INFO` | Global log level filter |

## Summary

- ✅ **Use structured logging** with context objects
- ✅ **Choose appropriate log levels** (DEBUG, INFO, WARN, ERROR)
- ✅ **Include context** for debugging
- ✅ **Use component loggers** for organization
- ✅ **Format durations and sizes** with utility functions
- ❌ **Don't log sensitive data** (tokens, passwords)
- ❌ **Don't use string concatenation** - use context objects
- ❌ **Don't log excessively** - respect log levels

The logging system provides **observability**, **debuggability**, and **consistency** across the skill.
