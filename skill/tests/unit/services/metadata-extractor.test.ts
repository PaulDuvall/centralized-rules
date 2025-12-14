/**
 * Unit tests for metadata extractor service
 */

import { describe, it, expect } from 'vitest';
import {
  extractTopicsFromPathAndContent,
  extractTopicsFromText,
  matchesKeywords,
  extractPattern,
  extractAllPatterns,
} from '../../../src/services/metadata-extractor';

describe('extractTopicsFromPathAndContent', () => {
  it('should extract topics from path', () => {
    const topics = extractTopicsFromPathAndContent('', 'base/security-principles.md');
    expect(topics).toContain('security');
  });

  it('should extract topics from content', () => {
    const content = '# Testing Guide\nThis covers authentication and API testing.';
    const topics = extractTopicsFromPathAndContent(content, 'base/guide.md');
    expect(topics.length).toBeGreaterThan(0);
  });

  it('should extract multiple topics', () => {
    const content = '# Security and Performance\nCovers authentication, testing, and database optimization.';
    const topics = extractTopicsFromPathAndContent(content, 'base/guide.md');
    expect(topics.length).toBeGreaterThanOrEqual(2);
  });

  it('should return empty array if no topics found', () => {
    const content = '# Random content';
    const topics = extractTopicsFromPathAndContent(content, 'base/random.md');
    expect(topics).toEqual([]);
  });
});

describe('extractTopicsFromText', () => {
  it('should extract security topic', () => {
    const topics = extractTopicsFromText('security best practices');
    expect(topics).toContain('security');
  });

  it('should extract testing topic', () => {
    const topics = extractTopicsFromText('pytest and unittest');
    expect(topics).toContain('testing');
  });
});

describe('matchesKeywords', () => {
  it('should match keywords', () => {
    expect(matchesKeywords('authentication system', ['auth', 'login'])).toBe(true);
  });

  it('should not match when no keywords present', () => {
    expect(matchesKeywords('random text', ['auth', 'login'])).toBe(false);
  });
});

describe('extractPattern', () => {
  it('should extract pattern match', () => {
    const result = extractPattern('Version: 1.2.3', /Version:\s+(\S+)/);
    expect(result).toBe('1.2.3');
  });

  it('should return null when no match', () => {
    const result = extractPattern('random text', /Version:\s+(\S+)/);
    expect(result).toBeNull();
  });
});

describe('extractAllPatterns', () => {
  it('should extract all pattern matches', () => {
    const results = extractAllPatterns('test1 test2 test3', /test\d/g);
    expect(results.length).toBeGreaterThan(0);
  });

  it('should return empty array when no matches', () => {
    const results = extractAllPatterns('random text', /test\d/g);
    expect(results).toEqual([]);
  });
});
