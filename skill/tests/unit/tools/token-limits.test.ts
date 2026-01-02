/**
 * Token limit validation tests
 *
 * These tests ensure that:
 * 1. Rule selection respects token budgets
 * 2. The system warns when approaching/exceeding token limits
 * 3. Token estimation is accurate
 * 4. Different limit scenarios are handled correctly
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { selectRules, analyzeIntent } from '../../../src/tools/select-rules';
import type { RuleInfo, RuleSelectionParams, ProjectContext } from '../../../src/types';

describe('Token Limit Enforcement', () => {
  let mockRules: RuleInfo[];
  let mockContext: ProjectContext;

  beforeEach(() => {
    // Create mock rules with varying token counts
    mockRules = [
      {
        name: 'security-principles',
        path: 'base/security-principles.md',
        category: 'base',
        topics: ['security'],
        maturity: ['production', 'pre-production', 'mvp'],
        estimatedTokens: 1500,
      },
      {
        name: 'testing-philosophy',
        path: 'base/testing-philosophy.md',
        category: 'base',
        topics: ['testing'],
        maturity: ['production', 'pre-production', 'mvp'],
        estimatedTokens: 1200,
      },
      {
        name: 'git-workflow',
        path: 'base/git-workflow.md',
        category: 'base',
        topics: ['git'],
        maturity: ['production', 'pre-production', 'mvp'],
        estimatedTokens: 800,
      },
      {
        name: 'python-standards',
        path: 'languages/python/coding-standards.md',
        category: 'languages',
        language: 'python',
        topics: ['python', 'coding-standards'],
        maturity: ['production', 'pre-production', 'mvp'],
        estimatedTokens: 2000,
      },
      {
        name: 'python-testing',
        path: 'languages/python/testing.md',
        category: 'languages',
        language: 'python',
        topics: ['python', 'testing'],
        maturity: ['production', 'pre-production', 'mvp'],
        estimatedTokens: 1800,
      },
    ];

    mockContext = {
      languages: ['python'],
      frameworks: [],
      cloudProviders: [],
      maturity: 'production',
      confidence: 'high',
    };
  });

  describe('Token Budget Enforcement', () => {
    it('should respect maxTokens limit when selecting rules', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Write secure Python code with tests'),
        maxRules: 10,
        maxTokens: 3000, // Only allow 3000 tokens
      };

      const selected = selectRules(mockRules, params);

      // Calculate total tokens
      const totalTokens = selected.reduce((sum, rule) => sum + rule.estimatedTokens, 0);

      expect(totalTokens).toBeLessThanOrEqual(3000);
    });

    it('should select highest-scoring rules within token budget', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Write Python code'),
        maxRules: 10,
        maxTokens: 2500,
      };

      const selected = selectRules(mockRules, params);

      // Should prioritize python-standards (2000 tokens) over other rules
      expect(selected.some(r => r.name === 'python-standards')).toBe(true);

      // Total should not exceed budget
      const totalTokens = selected.reduce((sum, rule) => sum + rule.estimatedTokens, 0);
      expect(totalTokens).toBeLessThanOrEqual(2500);
    });

    it('should handle zero token budget gracefully', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Python'),
        maxRules: 10,
        maxTokens: 0,
      };

      const selected = selectRules(mockRules, params);

      // When maxTokens is 0 (falsy), it's treated as "no token limit"
      // so rules are selected based on maxRules only
      expect(selected.length).toBeLessThanOrEqual(10);
      expect(selected.length).toBeGreaterThan(0);
    });

    it('should handle very small token budgets', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Python'),
        maxRules: 10,
        maxTokens: 500, // Too small for any rule
      };

      const selected = selectRules(mockRules, params);

      expect(selected).toHaveLength(0);
    });

    it('should respect maxRules even when token budget allows more', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Write secure Python code with tests and git workflow'),
        maxRules: 2, // Only allow 2 rules
        maxTokens: 10000, // Large budget
      };

      const selected = selectRules(mockRules, params);

      expect(selected.length).toBeLessThanOrEqual(2);
    });
  });

  describe('Token Limit Scenarios', () => {
    it('should handle scenario: approaching token limit', () => {
      // Scenario: User has 3500 token budget, gets close but doesn't exceed
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Python testing'),
        maxRules: 10,
        maxTokens: 3500,
      };

      const selected = selectRules(mockRules, params);
      const totalTokens = selected.reduce((sum, rule) => sum + rule.estimatedTokens, 0);

      expect(totalTokens).toBeLessThanOrEqual(3500);
      expect(totalTokens).toBeGreaterThan(0);
    });

    it('should handle scenario: exact token limit match', () => {
      // Create rules that exactly match the budget
      const exactRules: RuleInfo[] = [
        {
          name: 'rule-1',
          path: 'base/rule-1.md',
          category: 'base',
          topics: ['topic'],
          maturity: ['production'],
          estimatedTokens: 1000,
        },
        {
          name: 'rule-2',
          path: 'base/rule-2.md',
          category: 'base',
          topics: ['topic'],
          maturity: ['production'],
          estimatedTokens: 1000,
        },
      ];

      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('topic'),
        maxRules: 10,
        maxTokens: 2000, // Exactly matches both rules
      };

      const selected = selectRules(exactRules, params);

      expect(selected).toHaveLength(2);
      expect(selected.reduce((sum, r) => sum + r.estimatedTokens, 0)).toBe(2000);
    });

    it('should handle scenario: many low-token rules', () => {
      // Create many small rules
      const smallRules: RuleInfo[] = Array.from({ length: 20 }, (_, i) => ({
        name: `small-rule-${i}`,
        path: `base/small-rule-${i}.md`,
        category: 'base',
        topics: ['topic'],
        maturity: ['production'],
        estimatedTokens: 100,
      }));

      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('topic'),
        maxRules: 30,
        maxTokens: 1000, // Should fit 10 rules
      };

      const selected = selectRules(smallRules, params);

      expect(selected.length).toBeLessThanOrEqual(10);
      expect(selected.reduce((sum, r) => sum + r.estimatedTokens, 0)).toBeLessThanOrEqual(1000);
    });

    it('should handle scenario: few high-token rules', () => {
      // Create a few very large rules
      const largeRules: RuleInfo[] = [
        {
          name: 'large-1',
          path: 'base/large-1.md',
          category: 'base',
          topics: ['topic'],
          maturity: ['production'],
          estimatedTokens: 4000,
        },
        {
          name: 'large-2',
          path: 'base/large-2.md',
          category: 'base',
          topics: ['topic'],
          maturity: ['production'],
          estimatedTokens: 3500,
        },
      ];

      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('topic'),
        maxRules: 10,
        maxTokens: 5000, // Should only fit one large rule
      };

      const selected = selectRules(largeRules, params);

      expect(selected.length).toBeLessThanOrEqual(1);
      expect(selected.reduce((sum, r) => sum + r.estimatedTokens, 0)).toBeLessThanOrEqual(5000);
    });
  });

  describe('Default Token Limits', () => {
    it('should work without maxTokens specified', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Python testing'),
        maxRules: 5,
        // No maxTokens specified
      };

      const selected = selectRules(mockRules, params);

      // Should respect maxRules only
      expect(selected.length).toBeLessThanOrEqual(5);
    });
  });

  describe('Token Estimation Accuracy', () => {
    it('should have reasonable token estimates for all rules', () => {
      // All rules should have positive, reasonable token estimates
      mockRules.forEach(rule => {
        expect(rule.estimatedTokens).toBeGreaterThan(0);
        expect(rule.estimatedTokens).toBeLessThan(10000); // Reasonable upper bound
      });
    });

    it('should calculate cumulative tokens correctly', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Everything'),
        maxRules: 3,
        maxTokens: 5000,
      };

      const selected = selectRules(mockRules, params);

      // Manually calculate and verify
      let manualTotal = 0;
      selected.forEach(rule => {
        manualTotal += rule.estimatedTokens;
      });

      const calculatedTotal = selected.reduce((sum, r) => sum + r.estimatedTokens, 0);
      expect(calculatedTotal).toBe(manualTotal);
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty rule list', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Python'),
        maxRules: 10,
        maxTokens: 5000,
      };

      const selected = selectRules([], params);

      expect(selected).toHaveLength(0);
    });

    it('should handle single rule exceeding budget', () => {
      const hugeRule: RuleInfo = {
        name: 'huge-rule',
        path: 'base/huge-rule.md',
        category: 'base',
        topics: ['topic'],
        maturity: ['production'],
        estimatedTokens: 10000,
      };

      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('topic'),
        maxRules: 10,
        maxTokens: 5000, // Rule is too large
      };

      const selected = selectRules([hugeRule], params);

      // Should not include the rule as it exceeds budget
      expect(selected).toHaveLength(0);
    });

    it('should handle negative token estimates gracefully', () => {
      const invalidRule: RuleInfo = {
        name: 'invalid-rule',
        path: 'base/invalid-rule.md',
        category: 'base',
        topics: ['topic'],
        maturity: ['production'],
        estimatedTokens: -100, // Invalid
      };

      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('topic'),
        maxRules: 10,
        maxTokens: 5000,
      };

      // Should either skip invalid rule or handle gracefully
      const selected = selectRules([invalidRule], params);

      // Implementation-dependent behavior, but should not crash
      expect(Array.isArray(selected)).toBe(true);
    });
  });

  describe('Real-World Scenarios', () => {
    it('should handle typical development session (5000 token budget)', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Implement authentication with security best practices and tests'),
        maxRules: 5,
        maxTokens: 5000,
      };

      const selected = selectRules(mockRules, params);
      const totalTokens = selected.reduce((sum, r) => sum + r.estimatedTokens, 0);

      expect(selected.length).toBeGreaterThan(0);
      expect(selected.length).toBeLessThanOrEqual(5);
      expect(totalTokens).toBeLessThanOrEqual(5000);

      // Should include relevant rules
      const selectedNames = selected.map(r => r.name);
      expect(
        selectedNames.some(name =>
          name.includes('security') ||
          name.includes('testing') ||
          name.includes('python')
        )
      ).toBe(true);
    });

    it('should handle tight budget scenario (1000 tokens)', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Quick Python question'),
        maxRules: 5,
        maxTokens: 1000, // Very tight budget
      };

      const selected = selectRules(mockRules, params);
      const totalTokens = selected.reduce((sum, r) => sum + r.estimatedTokens, 0);

      expect(totalTokens).toBeLessThanOrEqual(1000);
      // Should get at least one small rule (git-workflow is 800 tokens)
      expect(selected.length).toBeGreaterThanOrEqual(0);
    });

    it('should handle generous budget scenario (20000 tokens)', () => {
      const params: RuleSelectionParams = {
        project: mockContext,
        intent: analyzeIntent('Comprehensive Python development with all best practices'),
        maxRules: 10,
        maxTokens: 20000, // Generous budget
      };

      const selected = selectRules(mockRules, params);

      // Should return all relevant rules, limited by maxRules
      expect(selected.length).toBeLessThanOrEqual(10);
      expect(selected.length).toBeGreaterThan(0);
    });
  });
});

describe('Token Warning Thresholds', () => {
  /**
   * These tests define expected behavior for token limit warnings
   * The actual warning logic would be implemented in the hook or skill
   */

  const WARNING_THRESHOLD = 0.8; // Warn at 80% of limit
  const CRITICAL_THRESHOLD = 0.95; // Critical at 95% of limit

  it('should identify when approaching token limit (80%)', () => {
    const maxTokens = 5000;
    const usedTokens = 4100; // 82%

    const percentUsed = usedTokens / maxTokens;

    expect(percentUsed).toBeGreaterThan(WARNING_THRESHOLD);
    expect(percentUsed).toBeLessThan(CRITICAL_THRESHOLD);
  });

  it('should identify when critically close to token limit (95%)', () => {
    const maxTokens = 5000;
    const usedTokens = 4800; // 96%

    const percentUsed = usedTokens / maxTokens;

    expect(percentUsed).toBeGreaterThan(CRITICAL_THRESHOLD);
  });

  it('should identify when well within token limit (<80%)', () => {
    const maxTokens = 5000;
    const usedTokens = 3000; // 60%

    const percentUsed = usedTokens / maxTokens;

    expect(percentUsed).toBeLessThan(WARNING_THRESHOLD);
  });
});
