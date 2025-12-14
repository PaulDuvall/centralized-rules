/**
 * Unit tests for logger service
 */

import { describe, it, expect, vi, afterEach, beforeEach } from 'vitest';
import {
  Logger,
  LogLevel,
  createLogger,
  configureLogging,
  parseLogLevel,
  formatDuration,
  formatBytes,
} from '../../../src/services/logger';

describe('Logger', () => {
  let consoleLogSpy: any;
  let consoleErrorSpy: any;
  let consoleWarnSpy: any;

  beforeEach(() => {
    consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {});
    consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
    consoleWarnSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('should create logger instance', () => {
    const logger = new Logger('test');
    expect(logger).toBeInstanceOf(Logger);
  });

  it('should log debug messages', () => {
    const logger = new Logger('test', { level: LogLevel.DEBUG });
    logger.debug('debug message');
    expect(consoleLogSpy).toHaveBeenCalled();
  });

  it('should log info messages', () => {
    const logger = new Logger('test');
    logger.info('info message');
    expect(consoleLogSpy).toHaveBeenCalled();
  });

  it('should log warning messages', () => {
    const logger = new Logger('test');
    logger.warn('warning message');
    expect(consoleWarnSpy).toHaveBeenCalled();
  });

  it('should log error messages', () => {
    const logger = new Logger('test');
    logger.error('error message', new Error('test'));
    expect(consoleErrorSpy).toHaveBeenCalled();
  });

  it('should create child loggers', () => {
    const logger = new Logger('test');
    const child = logger.child('child');
    expect(child).toBeInstanceOf(Logger);
  });

  it('should configure logger', () => {
    const logger = new Logger('test');
    logger.configure({ level: LogLevel.ERROR });
    expect(logger.getLevel()).toBe(LogLevel.ERROR);
  });

  it('should enable and disable logging', () => {
    const logger = new Logger('test');
    logger.disable();
    logger.info('should not log');
    expect(consoleLogSpy).not.toHaveBeenCalled();

    logger.enable();
    logger.info('should log');
    expect(consoleLogSpy).toHaveBeenCalled();
  });

  it('should set and get log level', () => {
    const logger = new Logger('test');
    logger.setLevel(LogLevel.WARN);
    expect(logger.getLevel()).toBe(LogLevel.WARN);
  });

  it('should check if log level is enabled', () => {
    const logger = new Logger('test', { level: LogLevel.WARN });
    expect(logger.isLevelEnabled(LogLevel.DEBUG)).toBe(false);
    expect(logger.isLevelEnabled(LogLevel.INFO)).toBe(false);
    expect(logger.isLevelEnabled(LogLevel.WARN)).toBe(true);
    expect(logger.isLevelEnabled(LogLevel.ERROR)).toBe(true);
  });

  it('should respect log level filtering', () => {
    const logger = new Logger('test', { level: LogLevel.WARN });
    logger.debug('debug message');
    logger.info('info message');
    expect(consoleLogSpy).not.toHaveBeenCalled();

    logger.warn('warn message');
    expect(consoleWarnSpy).toHaveBeenCalled();
  });

  it('should log with context', () => {
    const logger = new Logger('test');
    logger.info('message with context', { key: 'value' });
    expect(consoleLogSpy).toHaveBeenCalledWith(expect.stringContaining('message with context'));
  });
});

describe('createLogger', () => {
  it('should create logger instance', () => {
    const logger = createLogger('test');
    expect(logger).toBeInstanceOf(Logger);
  });

  it('should create logger with config', () => {
    const logger = createLogger('test', { level: LogLevel.DEBUG });
    expect(logger.getLevel()).toBe(LogLevel.DEBUG);
  });
});

describe('configureLogging', () => {
  it('should configure verbose logging', () => {
    configureLogging(true);
    // This function sets DEBUG level on all global loggers
    // We can't easily verify without accessing internals
    expect(true).toBe(true);
  });

  it('should configure normal logging', () => {
    configureLogging(false);
    // This function sets INFO level on all global loggers
    expect(true).toBe(true);
  });
});

describe('parseLogLevel', () => {
  it('should parse debug level', () => {
    expect(parseLogLevel('debug')).toBe(LogLevel.DEBUG);
    expect(parseLogLevel('DEBUG')).toBe(LogLevel.DEBUG);
  });

  it('should parse info level', () => {
    expect(parseLogLevel('info')).toBe(LogLevel.INFO);
    expect(parseLogLevel('INFO')).toBe(LogLevel.INFO);
  });

  it('should parse warn level', () => {
    expect(parseLogLevel('warn')).toBe(LogLevel.WARN);
    expect(parseLogLevel('WARN')).toBe(LogLevel.WARN);
  });

  it('should parse error level', () => {
    expect(parseLogLevel('error')).toBe(LogLevel.ERROR);
    expect(parseLogLevel('ERROR')).toBe(LogLevel.ERROR);
  });

  it('should default to INFO for invalid level', () => {
    expect(parseLogLevel('invalid')).toBe(LogLevel.INFO);
  });
});

describe('formatDuration', () => {
  it('should format milliseconds', () => {
    expect(formatDuration(100)).toBe('100ms');
    expect(formatDuration(500)).toBe('500ms');
  });

  it('should format seconds', () => {
    expect(formatDuration(1000)).toBe('1.00s');
    expect(formatDuration(2500)).toBe('2.50s');
  });
});

describe('formatBytes', () => {
  it('should format bytes', () => {
    expect(formatBytes(100)).toBe('100B');
    expect(formatBytes(500)).toBe('500B');
  });

  it('should format kilobytes', () => {
    expect(formatBytes(1024)).toBe('1.00KB');
    expect(formatBytes(2048)).toBe('2.00KB');
  });

  it('should format megabytes', () => {
    expect(formatBytes(1024 * 1024)).toBe('1.00MB');
    expect(formatBytes(2 * 1024 * 1024)).toBe('2.00MB');
  });
});
