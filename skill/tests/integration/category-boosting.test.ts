/**
 * Comprehensive tests for category-aware rule boosting
 * Validates that rules are properly boosted based on prompt category
 */
import { describe, it, expect } from 'vitest';
import { selectRules } from '../../src/tools/select-rules.js';
import { PromptCategory } from '../../src/services/prompt-classifier.js';
import type { RuleInfo, RuleSelectionParams } from '../../src/types';

// Mock rules for testing
const createMockRules = (): RuleInfo[] => [
  {
    path: 'languages/python/testing.md',
    title: 'Python Testing Standards',
    category: 'language',
    language: 'python',
    topics: ['testing', 'debugging'],
    maturity: ['mvp', 'pre-production', 'production'],
    estimatedTokens: 500,
  },
  {
    path: 'base/security-principles.md',
    title: 'Security Principles',
    category: 'base',
    topics: ['security', 'best-practices'],
    maturity: ['mvp', 'pre-production', 'production'],
    estimatedTokens: 600,
  },
  {
    path: 'base/architecture-patterns.md',
    title: 'Architecture Patterns',
    category: 'base',
    topics: ['architecture', 'design', 'patterns'],
    maturity: ['mvp', 'pre-production', 'production'],
    estimatedTokens: 700,
  },
  {
    path: 'base/deployment-guide.md',
    title: 'Deployment Guide',
    category: 'base',
    topics: ['deployment', 'ci-cd', 'infrastructure'],
    maturity: ['mvp', 'pre-production', 'production'],
    estimatedTokens: 550,
  },
  {
    path: 'base/documentation-standards.md',
    title: 'Documentation Standards',
    category: 'base',
    topics: ['documentation', 'comments'],
    maturity: ['mvp', 'pre-production', 'production'],
    estimatedTokens: 400,
  },
  {
    path: 'base/code-quality.md',
    title: 'Code Quality Standards',
    category: 'base',
    topics: ['code-quality', 'best-practices'],
    maturity: ['mvp', 'pre-production', 'production'],
    estimatedTokens: 450,
  },
];

const createParams = (): RuleSelectionParams => ({
  project: {
    languages: ['python'],
    frameworks: [],
    cloudProviders: [],
    maturity: 'mvp',
    workingDirectory: '/test',
    confidence: 0.8,
  },
  intent: {
    topics: [],
    action: 'implement',
    urgency: 'normal',
  },
  maxRules: 10,
});

describe('Category-Aware Rule Boosting', () => {
  describe('CODE_DEBUGGING category', () => {
    it('should boost testing rules for debugging prompts', () => {
      const rules = createMockRules();
      const params = createParams();

      const selectedWithoutCategory = selectRules(rules, params);
      const selectedWithCategory = selectRules(rules, params, PromptCategory.CODE_DEBUGGING);

      // Find position of testing.md in both selections
      const withoutCategoryIndex = selectedWithoutCategory.findIndex(
        (r) => r.path === 'languages/python/testing.md'
      );
      const withCategoryIndex = selectedWithCategory.findIndex(
        (r) => r.path === 'languages/python/testing.md'
      );

      // testing.md should be prioritized higher with category boost
      expect(withCategoryIndex).toBeLessThanOrEqual(withoutCategoryIndex);
      expect(withCategoryIndex).toBe(0); // Should be #1 with debugging boost
    });

    it('should boost debugging and logging topics', () => {
      const rules = createMockRules();
      const params = createParams();

      const selected = selectRules(rules, params, PromptCategory.CODE_DEBUGGING);

      // testing.md has 'testing' and 'debugging' topics, should be boosted
      expect(selected[0].path).toBe('languages/python/testing.md');
    });
  });

  describe('ARCHITECTURE category', () => {
    it('should boost architecture rules for architecture prompts', () => {
      const rules = createMockRules();
      const params = createParams();

      const selectedWithoutCategory = selectRules(rules, params);
      const selectedWithCategory = selectRules(rules, params, PromptCategory.ARCHITECTURE);

      // Find position of architecture-patterns.md
      const withoutCategoryIndex = selectedWithoutCategory.findIndex(
        (r) => r.path === 'base/architecture-patterns.md'
      );
      const withCategoryIndex = selectedWithCategory.findIndex(
        (r) => r.path === 'base/architecture-patterns.md'
      );

      // Architecture rule should be prioritized higher with category boost
      expect(withCategoryIndex).toBeLessThanOrEqual(withoutCategoryIndex);
    });
  });

  describe('DEVOPS category', () => {
    it('should boost deployment rules for DevOps prompts', () => {
      const rules = createMockRules();
      const params = createParams();

      const selected = selectRules(rules, params, PromptCategory.DEVOPS);

      // deployment-guide.md has 'deployment', 'ci-cd', 'infrastructure' topics
      const deploymentRule = selected.find((r) => r.path === 'base/deployment-guide.md');
      expect(deploymentRule).toBeDefined();

      // Should be highly prioritized
      const deploymentIndex = selected.findIndex((r) => r.path === 'base/deployment-guide.md');
      expect(deploymentIndex).toBeLessThan(3); // Should be in top 3
    });
  });

  describe('DOCUMENTATION category', () => {
    it('should boost documentation rules for documentation prompts', () => {
      const rules = createMockRules();
      const params = createParams();

      const selected = selectRules(rules, params, PromptCategory.DOCUMENTATION);

      const docRule = selected.find((r) => r.path === 'base/documentation-standards.md');
      expect(docRule).toBeDefined();

      // Should be prioritized
      const docIndex = selected.findIndex((r) => r.path === 'base/documentation-standards.md');
      expect(docIndex).toBeLessThan(3);
    });
  });

  describe('CODE_REVIEW category', () => {
    it('should boost code quality and security rules', () => {
      const rules = createMockRules();
      const params = createParams();

      const selected = selectRules(rules, params, PromptCategory.CODE_REVIEW);

      // code-quality.md and security-principles.md should be boosted
      const codeQualityRule = selected.find((r) => r.path === 'base/code-quality.md');
      const securityRule = selected.find((r) => r.path === 'base/security-principles.md');

      expect(codeQualityRule).toBeDefined();
      expect(securityRule).toBeDefined();

      // Both should be in top positions
      const codeQualityIndex = selected.findIndex((r) => r.path === 'base/code-quality.md');
      const securityIndex = selected.findIndex((r) => r.path === 'base/security-principles.md');

      expect(codeQualityIndex).toBeLessThan(4);
      expect(securityIndex).toBeLessThan(4);
    });
  });

  describe('CODE_IMPLEMENTATION category', () => {
    it('should boost testing and security rules for implementation', () => {
      const rules = createMockRules();
      const params = createParams();

      const selected = selectRules(rules, params, PromptCategory.CODE_IMPLEMENTATION);

      // testing.md and security-principles.md should be boosted
      const testingRule = selected.find((r) => r.path === 'languages/python/testing.md');
      const securityRule = selected.find((r) => r.path === 'base/security-principles.md');

      expect(testingRule).toBeDefined();
      expect(securityRule).toBeDefined();
    });
  });

  describe('Boost impact verification', () => {
    it('should prioritize boosted rules higher', () => {
      const rules = createMockRules();
      const params = createParams();

      // For CODE_DEBUGGING, testing.md should be #1 due to boost
      const withBoost = selectRules(rules, params, PromptCategory.CODE_DEBUGGING);
      expect(withBoost[0].path).toBe('languages/python/testing.md');

      // For ARCHITECTURE, architecture-patterns.md should be highly prioritized
      const archBoost = selectRules(rules, params, PromptCategory.ARCHITECTURE);
      const archIndex = archBoost.findIndex((r) => r.path === 'base/architecture-patterns.md');
      expect(archIndex).toBeLessThan(2); // Should be in top 2
    });

    it('should not affect rules when category has no boost mapping', () => {
      const rules = createMockRules();
      const params = createParams();

      const withoutBoost = selectRules(rules, params);
      const withUnclearCategory = selectRules(rules, params, PromptCategory.UNCLEAR);

      // UNCLEAR category has no boost mapping, so ordering should be the same
      expect(withUnclearCategory.map((r) => r.path)).toEqual(withoutBoost.map((r) => r.path));
    });

    it('should maintain backward compatibility when no category provided', () => {
      const rules = createMockRules();
      const params = createParams();

      // Should not throw error when category is undefined
      expect(() => selectRules(rules, params)).not.toThrow();

      const selected = selectRules(rules, params);
      expect(selected.length).toBeGreaterThan(0);
    });
  });

  describe('Edge cases', () => {
    it('should handle rules with multiple matching boost topics', () => {
      const rules = createMockRules();
      const params = createParams();

      // testing.md has both 'testing' and 'debugging' topics
      // For CODE_DEBUGGING category, both match the boost topics
      const selected = selectRules(rules, params, PromptCategory.CODE_DEBUGGING);

      expect(selected[0].path).toBe('languages/python/testing.md');
    });

    it('should handle rules with no matching boost topics', () => {
      const rules = createMockRules();
      const params = createParams();

      // Architecture category should not boost non-architecture rules
      const selected = selectRules(rules, params, PromptCategory.ARCHITECTURE);

      // Architecture rule should be first or near first
      const archIndex = selected.findIndex((r) => r.path === 'base/architecture-patterns.md');
      expect(archIndex).toBeLessThan(2);
    });

    it('should combine category boost with existing scoring', () => {
      const rules = createMockRules();
      const params = createParams();
      params.intent.topics = ['security']; // Add topic match

      const selected = selectRules(rules, params, PromptCategory.CODE_REVIEW);

      // security-principles.md should get both topic match AND category boost
      const securityIndex = selected.findIndex((r) => r.path === 'base/security-principles.md');
      expect(securityIndex).toBe(0); // Should be #1 with combined boost
    });
  });
});
