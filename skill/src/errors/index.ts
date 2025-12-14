/**
 * Custom error types for centralized-rules skill
 *
 * Error Handling Strategy:
 *
 * 1. THROW for unexpected failures that should stop execution
 *    - Network errors (after retries)
 *    - Invalid configuration
 *    - File system errors (unexpected)
 *
 * 2. RETURN NULL for expected "not found" cases
 *    - Rule not found (404 from GitHub)
 *    - File doesn't exist (detection checks)
 *    - No rules match criteria
 *
 * 3. CATCH & LOG at hook/tool boundaries
 *    - Never let errors block Claude
 *    - Log for debugging
 *    - Return graceful fallbacks
 */

/**
 * Base error class for all skill errors
 */
export class SkillError extends Error {
  public readonly code: string;
  public readonly details?: unknown;

  constructor(message: string, code: string, details?: unknown) {
    super(message);
    this.name = this.constructor.name;
    this.code = code;
    this.details = details;

    // Maintains proper stack trace for where our error was thrown
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * GitHub API related errors
 */
export class GitHubApiError extends SkillError {
  public readonly statusCode?: number;
  public readonly rateLimitRemaining?: number;

  constructor(
    message: string,
    statusCode?: number,
    rateLimitRemaining?: number,
    details?: unknown
  ) {
    super(message, 'GITHUB_API_ERROR', details);
    this.statusCode = statusCode;
    this.rateLimitRemaining = rateLimitRemaining;
  }
}

/**
 * Rule not found (404) - this is an expected case
 */
export class RuleNotFoundError extends SkillError {
  public readonly rulePath: string;

  constructor(rulePath: string) {
    super(`Rule not found: ${rulePath}`, 'RULE_NOT_FOUND', { rulePath });
    this.rulePath = rulePath;
  }
}

/**
 * Configuration errors (invalid config)
 */
export class ConfigurationError extends SkillError {
  public readonly configKey?: string;

  constructor(message: string, configKey?: string, details?: unknown) {
    super(message, 'CONFIGURATION_ERROR', details);
    this.configKey = configKey;
  }
}

/**
 * Cache operation errors
 */
export class CacheError extends SkillError {
  public readonly operation: 'get' | 'set' | 'delete' | 'clear';

  constructor(message: string, operation: 'get' | 'set' | 'delete' | 'clear', details?: unknown) {
    super(message, 'CACHE_ERROR', details);
    this.operation = operation;
  }
}

/**
 * File system errors (unexpected)
 */
export class FileSystemError extends SkillError {
  public readonly filePath: string;
  public readonly operation: 'read' | 'write' | 'delete' | 'stat';

  constructor(
    message: string,
    filePath: string,
    operation: 'read' | 'write' | 'delete' | 'stat',
    details?: unknown
  ) {
    super(message, 'FILE_SYSTEM_ERROR', details);
    this.filePath = filePath;
    this.operation = operation;
  }
}

/**
 * Detection errors (project context detection failures)
 */
export class DetectionError extends SkillError {
  public readonly detectionType: 'language' | 'framework' | 'cloud' | 'maturity';

  constructor(
    message: string,
    detectionType: 'language' | 'framework' | 'cloud' | 'maturity',
    details?: unknown
  ) {
    super(message, 'DETECTION_ERROR', details);
    this.detectionType = detectionType;
  }
}

/**
 * Rule selection errors
 */
export class RuleSelectionError extends SkillError {
  constructor(message: string, details?: unknown) {
    super(message, 'RULE_SELECTION_ERROR', details);
  }
}

/**
 * Validation errors
 */
export class ValidationError extends SkillError {
  public readonly field?: string;

  constructor(message: string, field?: string, details?: unknown) {
    super(message, 'VALIDATION_ERROR', details);
    this.field = field;
  }
}

/**
 * Type guard to check if error is a SkillError
 */
export function isSkillError(error: unknown): error is SkillError {
  return error instanceof SkillError;
}

/**
 * Extract safe error message from any error type
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'Unknown error occurred';
}

/**
 * Extract error details for logging
 */
export function getErrorDetails(error: unknown): Record<string, unknown> {
  if (isSkillError(error)) {
    return {
      name: error.name,
      code: error.code,
      message: error.message,
      details: error.details,
      stack: error.stack,
    };
  }
  if (error instanceof Error) {
    return {
      name: error.name,
      message: error.message,
      stack: error.stack,
    };
  }
  return {
    error: String(error),
  };
}
