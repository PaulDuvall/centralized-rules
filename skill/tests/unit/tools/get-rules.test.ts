/**
 * Unit tests for get-rules
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { fetchRule, fetchRules } from '../../../src/tools/get-rules';
import type { SkillConfig, RuleInfo } from '../../../src/types';
import { resetCache } from '../../../src/cache/rules-cache';

// Mock Octokit
vi.mock('@octokit/rest', () => {
  return {
    Octokit: vi.fn().mockImplementation(() => ({
      repos: {
        getContent: vi.fn().mockImplementation(({ path }) => {
          const mockContent = `# ${path}\n\nThis is a test rule.`;
          const base64Content = Buffer.from(mockContent).toString('base64');

          return Promise.resolve({
            data: {
              type: 'file',
              content: base64Content,
            },
          });
        }),
      },
    })),
  };
});

describe('fetchRule', () => {
  const mockConfig: SkillConfig = {
    rulesRepo: 'paulduvall/centralized-rules',
    rulesBranch: 'main',
    enableAutoLoad: true,
    cacheEnabled: true,
    cacheTTL: 3600,
    maxRules: 5,
    maxTokens: 5000,
    verbose: false,
  };

  beforeEach(() => {
    resetCache();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('should fetch a rule from GitHub', async () => {
    const rule = await fetchRule('base/code-quality.md', mockConfig);

    expect(rule).toBeTruthy();
    expect(rule?.path).toBe('base/code-quality.md');
    expect(rule?.content).toContain('This is a test rule');
  });

  it('should determine category from path', async () => {
    const baseRule = await fetchRule('base/testing.md', mockConfig);
    expect(baseRule?.category).toBe('base');

    const langRule = await fetchRule('languages/python/coding-standards.md', mockConfig);
    expect(langRule?.category).toBe('language');

    const frameworkRule = await fetchRule('frameworks/react/best-practices.md', mockConfig);
    expect(frameworkRule?.category).toBe('framework');

    const cloudRule = await fetchRule('cloud/aws/security.md', mockConfig);
    expect(cloudRule?.category).toBe('cloud');
  });

  it('should extract metadata from path', async () => {
    const langRule = await fetchRule('languages/python/testing.md', mockConfig);
    expect(langRule?.language).toBe('python');

    const frameworkRule = await fetchRule('frameworks/fastapi/best-practices.md', mockConfig);
    expect(frameworkRule?.framework).toBe('fastapi');
    expect(frameworkRule?.language).toBe('python');

    const cloudRule = await fetchRule('cloud/aws/security.md', mockConfig);
    expect(cloudRule?.cloudProvider).toBe('aws');
  });

  it('should cache fetched rules', async () => {
    const rule1 = await fetchRule('base/testing.md', mockConfig);
    const rule2 = await fetchRule('base/testing.md', mockConfig);

    // Both should be the same object (from cache)
    expect(rule1).toEqual(rule2);
  });

  it('should skip cache when disabled', async () => {
    const noCacheConfig: SkillConfig = {
      ...mockConfig,
      cacheEnabled: false,
    };

    const rule = await fetchRule('base/testing.md', noCacheConfig);
    expect(rule).toBeTruthy();
  });

  it('should estimate token count', async () => {
    const rule = await fetchRule('base/code-quality.md', mockConfig);
    expect(rule?.estimatedTokens).toBeGreaterThan(0);
  });

  it('should have fetchedAt timestamp', async () => {
    const rule = await fetchRule('base/code-quality.md', mockConfig);
    expect(rule?.fetchedAt).toBeInstanceOf(Date);
  });
});

describe('fetchRules', () => {
  const mockConfig: SkillConfig = {
    rulesRepo: 'paulduvall/centralized-rules',
    rulesBranch: 'main',
    enableAutoLoad: true,
    cacheEnabled: true,
    cacheTTL: 3600,
    maxRules: 5,
    maxTokens: 5000,
    verbose: false,
  };

  beforeEach(() => {
    resetCache();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('should fetch multiple rules', async () => {
    const ruleInfos: RuleInfo[] = [
      {
        path: 'base/code-quality.md',
        title: 'Code Quality',
        category: 'base',
        topics: ['quality'],
        maturity: ['mvp', 'pre-production', 'production'],
        estimatedTokens: 800,
      },
      {
        path: 'base/testing.md',
        title: 'Testing',
        category: 'base',
        topics: ['testing'],
        maturity: ['mvp', 'pre-production', 'production'],
        estimatedTokens: 900,
      },
    ];

    const rules = await fetchRules(ruleInfos, mockConfig);

    expect(rules.length).toBe(2);
    expect(rules[0].path).toBe('base/code-quality.md');
    expect(rules[1].path).toBe('base/testing.md');
  });

  it('should batch requests to avoid overwhelming API', async () => {
    const ruleInfos: RuleInfo[] = Array.from({ length: 10 }, (_, i) => ({
      path: `base/rule-${i}.md`,
      title: `Rule ${i}`,
      category: 'base' as const,
      topics: [],
      maturity: ['mvp', 'pre-production', 'production'] as ('mvp' | 'pre-production' | 'production')[],
      estimatedTokens: 800,
    }));

    const rules = await fetchRules(ruleInfos, mockConfig);

    expect(rules.length).toBe(10);
  });

  it('should handle empty input', async () => {
    const rules = await fetchRules([], mockConfig);
    expect(rules.length).toBe(0);
  });
});
