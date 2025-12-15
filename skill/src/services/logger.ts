/**
 * Structured logging service
 * Provides consistent, leveled logging with context throughout the skill
 */

/**
 * Log levels in order of severity
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  NONE = 4,
}

/**
 * Log entry structure
 */
export interface LogEntry {
  timestamp: string;
  level: string;
  component: string;
  message: string;
  context?: Record<string, unknown>;
  error?: unknown;
}

/**
 * Logger configuration
 */
export interface LoggerConfig {
  level: LogLevel;
  component: string;
  enabled: boolean;
  includeTimestamp: boolean;
  includeComponent: boolean;
  colorize: boolean;
}

/**
 * Default logger configuration
 */
const DEFAULT_CONFIG: LoggerConfig = {
  level: LogLevel.INFO,
  component: 'skill',
  enabled: true,
  includeTimestamp: true,
  includeComponent: true,
  colorize: false,
};

/**
 * Logger class for structured logging
 */
export class Logger {
  private config: LoggerConfig;

  constructor(component: string, config?: Partial<LoggerConfig>) {
    this.config = {
      ...DEFAULT_CONFIG,
      component,
      ...config,
    };

    // Parse LOG_LEVEL from environment
    const envLevel = process.env['LOG_LEVEL']?.toUpperCase();
    if (envLevel && envLevel in LogLevel) {
      this.config.level = LogLevel[envLevel as keyof typeof LogLevel];
    }
  }

  /**
   * Create a child logger with a sub-component name
   */
  child(subComponent: string): Logger {
    return new Logger(`${this.config.component}:${subComponent}`, this.config);
  }

  /**
   * Log a debug message
   */
  debug(message: string, context?: Record<string, unknown>): void {
    this.log(LogLevel.DEBUG, message, context);
  }

  /**
   * Log an info message
   */
  info(message: string, context?: Record<string, unknown>): void {
    this.log(LogLevel.INFO, message, context);
  }

  /**
   * Log a warning message
   */
  warn(message: string, context?: Record<string, unknown>): void {
    this.log(LogLevel.WARN, message, context);
  }

  /**
   * Log an error message
   */
  error(message: string, error?: unknown, context?: Record<string, unknown>): void {
    this.log(LogLevel.ERROR, message, { ...context, error });
  }

  /**
   * Core logging method
   */
  private log(level: LogLevel, message: string, context?: Record<string, unknown>): void {
    // Check if logging is enabled and level is sufficient
    if (!this.config.enabled || level < this.config.level) {
      return;
    }

    // Build log entry
    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level: LogLevel[level],
      component: this.config.component,
      message,
      context,
    };

    // Format and output
    const formatted = this.format(entry);
    this.output(level, formatted);
  }

  /**
   * Format log entry for output
   */
  private format(entry: LogEntry): string {
    const parts: string[] = [];

    // Timestamp
    if (this.config.includeTimestamp) {
      const timestamp = new Date(entry.timestamp).toLocaleTimeString();
      parts.push(`[${timestamp}]`);
    }

    // Component
    if (this.config.includeComponent) {
      parts.push(`[${entry.component}]`);
    }

    // Level
    parts.push(`${entry.level}:`);

    // Message
    parts.push(entry.message);

    // Context (if present)
    if (entry.context && Object.keys(entry.context).length > 0) {
      const contextStr = this.formatContext(entry.context);
      if (contextStr) {
        parts.push(contextStr);
      }
    }

    return parts.join(' ');
  }

  /**
   * Format context object for logging
   */
  private formatContext(context: Record<string, unknown>): string {
    try {
      // Extract error separately if present
      const { error, ...rest } = context;

      const parts: string[] = [];

      // Format non-error context
      if (Object.keys(rest).length > 0) {
        parts.push(JSON.stringify(rest));
      }

      // Format error if present
      if (error) {
        if (error instanceof Error) {
          parts.push(`error="${error.message}"`);
        } else {
          parts.push(`error=${String(error)}`);
        }
      }

      return parts.length > 0 ? `- ${parts.join(' ')}` : '';
    } catch {
      return '';
    }
  }

  /**
   * Output log to appropriate stream
   */
  private output(level: LogLevel, message: string): void {
    switch (level) {
      case LogLevel.DEBUG:
      case LogLevel.INFO:
        // eslint-disable-next-line no-console
        console.log(message);
        break;
      case LogLevel.WARN:
        console.warn(message);
        break;
      case LogLevel.ERROR:
        console.error(message);
        break;
    }
  }

  /**
   * Update logger configuration
   */
  configure(config: Partial<LoggerConfig>): void {
    this.config = { ...this.config, ...config };
  }

  /**
   * Enable logging
   */
  enable(): void {
    this.config.enabled = true;
  }

  /**
   * Disable logging
   */
  disable(): void {
    this.config.enabled = false;
  }

  /**
   * Set log level
   */
  setLevel(level: LogLevel): void {
    this.config.level = level;
  }

  /**
   * Get current log level
   */
  getLevel(): LogLevel {
    return this.config.level;
  }

  /**
   * Check if a log level is enabled
   */
  isLevelEnabled(level: LogLevel): boolean {
    return this.config.enabled && level >= this.config.level;
  }
}

/**
 * Create a logger instance for a component
 */
export function createLogger(component: string, config?: Partial<LoggerConfig>): Logger {
  return new Logger(component, config);
}

/**
 * Global logger instances for common components
 */
export const loggers = {
  hook: createLogger('hook'),
  detection: createLogger('detection'),
  rules: createLogger('rules'),
  cache: createLogger('cache'),
  config: createLogger('config'),
};

/**
 * Configure logging globally based on skill config
 */
export function configureLogging(verbose: boolean): void {
  const level = verbose ? LogLevel.DEBUG : LogLevel.INFO;

  Object.values(loggers).forEach((logger) => {
    logger.setLevel(level);
  });
}

/**
 * Parse log level from string
 */
export function parseLogLevel(level: string): LogLevel {
  const normalized = level.toUpperCase();
  if (normalized in LogLevel) {
    return LogLevel[normalized as keyof typeof LogLevel];
  }
  return LogLevel.INFO;
}

/**
 * Format duration in milliseconds to human-readable string
 */
export function formatDuration(ms: number): string {
  if (ms < 1000) {
    return `${ms}ms`;
  }
  return `${(ms / 1000).toFixed(2)}s`;
}

/**
 * Format file size in bytes to human-readable string
 */
export function formatBytes(bytes: number): string {
  if (bytes < 1024) {
    return `${bytes}B`;
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(2)}KB`;
  }
  return `${(bytes / (1024 * 1024)).toFixed(2)}MB`;
}
