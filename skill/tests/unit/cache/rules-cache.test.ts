/**
 * Unit tests for rules-cache
 */

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { RulesCache, getCache, resetCache } from '../../../src/cache/rules-cache';
import type { Rule } from '../../../src/types';

describe('RulesCache', () => {
  let cache: RulesCache;

  beforeEach(() => {
    cache = new RulesCache(60); // 60 second TTL
  });

  afterEach(() => {
    cache.clear();
  });

  describe('basic operations', () => {
    it('should store and retrieve a rule', () => {
      const rule: Rule = {
        path: 'base/code-quality.md',
        title: 'Code Quality',
        category: 'base',
        topics: ['quality'],
        maturity: ['mvp', 'pre-production', 'production'],
        estimatedTokens: 800,
        content: '# Code Quality\n\nBest practices...',
        fetchedAt: new Date(),
      };

      cache.set('base/code-quality.md', rule);
      const retrieved = cache.get('base/code-quality.md');

      expect(retrieved).toEqual(rule);
    });

    it('should return undefined for non-existent keys', () => {
      const result = cache.get('non-existent.md');
      expect(result).toBeUndefined();
    });

    it('should check if a key exists', () => {
      const rule: Rule = {
        path: 'test.md',
        title: 'Test',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test',
        fetchedAt: new Date(),
      };

      expect(cache.has('test.md')).toBe(false);
      cache.set('test.md', rule);
      expect(cache.has('test.md')).toBe(true);
    });

    it('should delete a specific key', () => {
      const rule: Rule = {
        path: 'test.md',
        title: 'Test',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test',
        fetchedAt: new Date(),
      };

      cache.set('test.md', rule);
      expect(cache.has('test.md')).toBe(true);

      cache.delete('test.md');
      expect(cache.has('test.md')).toBe(false);
    });

    it('should clear all entries', () => {
      const rule1: Rule = {
        path: 'test1.md',
        title: 'Test 1',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test 1',
        fetchedAt: new Date(),
      };

      const rule2: Rule = {
        path: 'test2.md',
        title: 'Test 2',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test 2',
        fetchedAt: new Date(),
      };

      cache.set('test1.md', rule1);
      cache.set('test2.md', rule2);
      expect(cache.keys().length).toBe(2);

      cache.clear();
      expect(cache.keys().length).toBe(0);
    });
  });

  describe('statistics', () => {
    it('should track cache hits and misses', () => {
      const rule: Rule = {
        path: 'test.md',
        title: 'Test',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test',
        fetchedAt: new Date(),
      };

      cache.set('test.md', rule);

      // Hit
      cache.get('test.md');
      // Miss
      cache.get('non-existent.md');
      // Another hit
      cache.get('test.md');

      const stats = cache.getStats();
      expect(stats.hits).toBe(2);
      expect(stats.misses).toBe(1);
      expect(stats.hitRate).toBeCloseTo(2 / 3, 2);
      expect(stats.size).toBe(1);
    });

    it('should calculate hit rate correctly with no requests', () => {
      const stats = cache.getStats();
      expect(stats.hitRate).toBe(0);
    });

    it('should reset stats on clear', () => {
      const rule: Rule = {
        path: 'test.md',
        title: 'Test',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test',
        fetchedAt: new Date(),
      };

      cache.set('test.md', rule);
      cache.get('test.md');
      cache.get('non-existent.md');

      let stats = cache.getStats();
      expect(stats.hits).toBe(1);
      expect(stats.misses).toBe(1);

      cache.clear();
      stats = cache.getStats();
      expect(stats.hits).toBe(0);
      expect(stats.misses).toBe(0);
      expect(stats.size).toBe(0);
    });
  });

  describe('global cache', () => {
    afterEach(() => {
      resetCache();
    });

    it('should return a singleton instance', () => {
      const cache1 = getCache();
      const cache2 = getCache();
      expect(cache1).toBe(cache2);
    });

    it('should persist data across getCache calls', () => {
      const rule: Rule = {
        path: 'test.md',
        title: 'Test',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test',
        fetchedAt: new Date(),
      };

      const cache1 = getCache();
      cache1.set('test.md', rule);

      const cache2 = getCache();
      const retrieved = cache2.get('test.md');

      expect(retrieved).toEqual(rule);
    });

    it('should reset the global cache', () => {
      const rule: Rule = {
        path: 'test.md',
        title: 'Test',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test',
        fetchedAt: new Date(),
      };

      const cache1 = getCache();
      cache1.set('test.md', rule);

      resetCache();

      const cache2 = getCache();
      expect(cache2.get('test.md')).toBeUndefined();
      expect(cache1).not.toBe(cache2);
    });
  });

  describe('TTL behavior', () => {
    it('should respect TTL settings', async () => {
      const shortCache = new RulesCache(0.1); // 100ms TTL

      const rule: Rule = {
        path: 'test.md',
        title: 'Test',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test',
        fetchedAt: new Date(),
      };

      shortCache.set('test.md', rule);
      expect(shortCache.get('test.md')).toEqual(rule);

      // Wait for TTL to expire
      await new Promise(resolve => setTimeout(resolve, 150));

      expect(shortCache.get('test.md')).toBeUndefined();
    });
  });

  describe('keys', () => {
    it('should return all cached keys', () => {
      const rule1: Rule = {
        path: 'test1.md',
        title: 'Test 1',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test 1',
        fetchedAt: new Date(),
      };

      const rule2: Rule = {
        path: 'test2.md',
        title: 'Test 2',
        category: 'base',
        topics: [],
        maturity: ['mvp'],
        estimatedTokens: 100,
        content: 'test 2',
        fetchedAt: new Date(),
      };

      cache.set('test1.md', rule1);
      cache.set('test2.md', rule2);

      const keys = cache.keys();
      expect(keys).toContain('test1.md');
      expect(keys).toContain('test2.md');
      expect(keys.length).toBe(2);
    });
  });
});
