/**
 * Unit tests for select-rules
 */

import { describe, it, expect } from 'vitest';
import {
  selectRules,
  analyzeIntent,
  getAvailableRules,
} from '../../../src/tools/select-rules';
import type { ProjectContext, RuleSelectionParams } from '../../../src/types';

describe('analyzeIntent', () => {
  it('should extract authentication topic', () => {
    const message = 'I need to implement JWT authentication for my API';
    const intent = analyzeIntent(message);

    expect(intent.topics).toContain('authentication');
    expect(intent.action).toBe('implement');
  });

  it('should extract testing topic', () => {
    const message = 'How do I write tests for this component?';
    const intent = analyzeIntent(message);

    expect(intent.topics).toContain('testing');
  });

  it('should extract security topic', () => {
    const message = 'Fix the XSS vulnerability in the form';
    const intent = analyzeIntent(message);

    expect(intent.topics).toContain('security');
    expect(intent.action).toBe('fix');
  });

  it('should extract multiple topics', () => {
    const message = 'Implement API authentication with security best practices';
    const intent = analyzeIntent(message);

    expect(intent.topics).toContain('authentication');
    expect(intent.topics).toContain('api');
    expect(intent.topics).toContain('security');
  });

  it('should detect implement action', () => {
    const message = 'Add a new database migration';
    const intent = analyzeIntent(message);

    expect(intent.action).toBe('implement');
  });

  it('should detect fix action', () => {
    const message = 'There is a bug in the login form';
    const intent = analyzeIntent(message);

    expect(intent.action).toBe('fix');
  });

  it('should detect refactor action', () => {
    const message = 'Can you refactor this code to be cleaner?';
    const intent = analyzeIntent(message);

    expect(intent.action).toBe('refactor');
  });

  it('should detect review action', () => {
    const message = 'Please review my code for best practices';
    const intent = analyzeIntent(message);

    expect(intent.action).toBe('review');
  });

  it('should detect high urgency', () => {
    const message = 'URGENT: Production issue with authentication';
    const intent = analyzeIntent(message);

    expect(intent.urgency).toBe('high');
  });

  it('should default to normal urgency', () => {
    const message = 'Add a new feature to the app';
    const intent = analyzeIntent(message);

    expect(intent.urgency).toBe('normal');
  });

  it('should handle empty message', () => {
    const message = '';
    const intent = analyzeIntent(message);

    expect(intent.topics).toHaveLength(0);
    expect(intent.action).toBe('general');
    expect(intent.urgency).toBe('normal');
  });
});

describe('selectRules', () => {
  const mockProjectContext: ProjectContext = {
    languages: ['python'],
    frameworks: ['fastapi'],
    cloudProviders: ['aws'],
    maturity: 'production',
    workingDirectory: '/test',
    confidence: 0.9,
  };

  it('should select language-specific rules', () => {
    const params: RuleSelectionParams = {
      project: mockProjectContext,
      intent: {
        topics: [],
        action: 'general',
        urgency: 'normal',
      },
      maxRules: 10,
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    const pythonRules = selected.filter(r => r.language === 'python');
    expect(pythonRules.length).toBeGreaterThan(0);
  });

  it('should select framework-specific rules', () => {
    const params: RuleSelectionParams = {
      project: mockProjectContext,
      intent: {
        topics: [],
        action: 'general',
        urgency: 'normal',
      },
      maxRules: 10,
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    const fastapiRules = selected.filter(r => r.framework === 'fastapi');
    expect(fastapiRules.length).toBeGreaterThan(0);
  });

  it('should respect maxRules limit', () => {
    const params: RuleSelectionParams = {
      project: mockProjectContext,
      intent: {
        topics: [],
        action: 'general',
        urgency: 'normal',
      },
      maxRules: 3,
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    expect(selected.length).toBeLessThanOrEqual(3);
  });

  it('should prioritize topic matches', () => {
    const params: RuleSelectionParams = {
      project: mockProjectContext,
      intent: {
        topics: ['security'],
        action: 'implement',
        urgency: 'high',
      },
      maxRules: 10,
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    // Security-related rules should appear early in the selection
    const topRules = selected.slice(0, 3);
    const hasSecurityRule = topRules.some(
      r => r.topics.includes('security') || r.path.includes('security')
    );
    expect(hasSecurityRule).toBe(true);
  });

  it('should filter out low-scoring rules', () => {
    const tsContext: ProjectContext = {
      languages: ['typescript'],
      frameworks: ['react'],
      cloudProviders: [],
      maturity: 'mvp',
      workingDirectory: '/test',
      confidence: 0.8,
    };

    const params: RuleSelectionParams = {
      project: tsContext,
      intent: {
        topics: ['testing'],
        action: 'implement',
        urgency: 'normal',
      },
      maxRules: 10,
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    // Python-specific rules should be less prevalent than TypeScript/React rules
    const pythonRules = selected.filter(r => r.language === 'python');
    const tsRules = selected.filter(r => r.language === 'typescript' || r.framework === 'react');
    expect(tsRules.length).toBeGreaterThanOrEqual(pythonRules.length);
  });

  it('should apply token budget constraint', () => {
    const params: RuleSelectionParams = {
      project: mockProjectContext,
      intent: {
        topics: [],
        action: 'general',
        urgency: 'normal',
      },
      maxRules: 10,
      maxTokens: 2000, // Only allow ~2 rules
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    const totalTokens = selected.reduce((sum, rule) => sum + rule.estimatedTokens, 0);
    expect(totalTokens).toBeLessThanOrEqual(2000);
  });

  it('should include base rules', () => {
    const params: RuleSelectionParams = {
      project: mockProjectContext,
      intent: {
        topics: [],
        action: 'general',
        urgency: 'normal',
      },
      maxRules: 10,
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    const baseRules = selected.filter(r => r.category === 'base');
    expect(baseRules.length).toBeGreaterThan(0);
  });

  it('should prioritize rules matching maturity level', () => {
    const mvpContext: ProjectContext = {
      languages: ['python'],
      frameworks: [],
      cloudProviders: [],
      maturity: 'mvp',
      workingDirectory: '/test',
      confidence: 0.7,
    };

    const params: RuleSelectionParams = {
      project: mvpContext,
      intent: {
        topics: ['security'],
        action: 'implement',
        urgency: 'normal',
      },
      maxRules: 10,
    };

    const availableRules = getAvailableRules();
    const selected = selectRules(availableRules, params);

    // Most rules should be applicable to MVP maturity
    const mvpApplicable = selected.filter(r => r.maturity.includes('mvp'));
    expect(mvpApplicable.length).toBeGreaterThan(0);
  });
});

describe('getAvailableRules', () => {
  it('should return a list of rules', () => {
    const rules = getAvailableRules();
    expect(rules.length).toBeGreaterThan(0);
  });

  it('should include base rules', () => {
    const rules = getAvailableRules();
    const baseRules = rules.filter(r => r.category === 'base');
    expect(baseRules.length).toBeGreaterThan(0);
  });

  it('should include language-specific rules', () => {
    const rules = getAvailableRules();
    const languageRules = rules.filter(r => r.category === 'language');
    expect(languageRules.length).toBeGreaterThan(0);
  });

  it('should include framework-specific rules', () => {
    const rules = getAvailableRules();
    const frameworkRules = rules.filter(r => r.category === 'framework');
    expect(frameworkRules.length).toBeGreaterThan(0);
  });

  it('should include cloud-specific rules', () => {
    const rules = getAvailableRules();
    const cloudRules = rules.filter(r => r.category === 'cloud');
    expect(cloudRules.length).toBeGreaterThan(0);
  });

  it('should have valid rule structures', () => {
    const rules = getAvailableRules();
    rules.forEach(rule => {
      expect(rule.path).toBeTruthy();
      expect(rule.title).toBeTruthy();
      expect(rule.category).toBeTruthy();
      expect(Array.isArray(rule.topics)).toBe(true);
      expect(Array.isArray(rule.maturity)).toBe(true);
      expect(rule.estimatedTokens).toBeGreaterThan(0);
    });
  });
});
