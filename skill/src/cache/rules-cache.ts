/**
 * Cache for storing fetched rules to reduce GitHub API calls
 */

import NodeCache from 'node-cache';
import type { Rule, CacheStats } from '../types';

/**
 * Rules cache with TTL support
 */
export class RulesCache {
  private cache: NodeCache;
  private hits = 0;
  private misses = 0;

  constructor(ttlSeconds = 3600) {
    this.cache = new NodeCache({
      stdTTL: ttlSeconds,
      checkperiod: ttlSeconds * 0.2,
      useClones: false,
    });
  }

  /**
   * Get a rule from cache
   */
  get(path: string): Rule | undefined {
    const rule = this.cache.get<Rule>(path);
    if (rule) {
      this.hits++;
    } else {
      this.misses++;
    }
    return rule;
  }

  /**
   * Store a rule in cache
   */
  set(path: string, rule: Rule): void {
    this.cache.set(path, rule);
  }

  /**
   * Check if a rule exists in cache
   */
  has(path: string): boolean {
    return this.cache.has(path);
  }

  /**
   * Clear the entire cache
   */
  clear(): void {
    this.cache.flushAll();
    this.hits = 0;
    this.misses = 0;
  }

  /**
   * Delete a specific rule from cache
   */
  delete(path: string): void {
    this.cache.del(path);
  }

  /**
   * Get cache statistics
   */
  getStats(): CacheStats {
    const total = this.hits + this.misses;
    return {
      size: this.cache.keys().length,
      hits: this.hits,
      misses: this.misses,
      hitRate: total > 0 ? this.hits / total : 0,
    };
  }

  /**
   * Get all cached rule paths
   */
  keys(): string[] {
    return this.cache.keys();
  }
}

/**
 * Global cache instance (singleton)
 */
let globalCache: RulesCache | null = null;

/**
 * Get or create the global cache instance
 */
export function getCache(ttlSeconds?: number): RulesCache {
  if (!globalCache) {
    globalCache = new RulesCache(ttlSeconds);
  }
  return globalCache;
}

/**
 * Reset the global cache instance (mainly for testing)
 */
export function resetCache(): void {
  if (globalCache) {
    globalCache.clear();
  }
  globalCache = null;
}
