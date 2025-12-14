/**
 * End-to-end tests for real project scenarios
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { detectContext } from '../../src/tools/detect-context';
import { analyzeIntent, selectRules, getAvailableRules } from '../../src/tools/select-rules';
import path from 'path';

describe('E2E: Real Project Scenarios', () => {
  describe('Python + FastAPI + AWS', () => {
    it('should detect full stack and select appropriate rules', async () => {
      const projectDir = path.join(__dirname, '../fixtures/python-fastapi');

      // Step 1: Detect context
      const context = await detectContext(projectDir);
      expect(context.languages).toContain('python');
      expect(context.frameworks).toContain('fastapi');

      // Step 2: Analyze intent
      const intent = analyzeIntent('Implement secure API authentication with JWT');
      expect(intent.topics).toContain('authentication');
      expect(intent.topics).toContain('security');
      expect(intent.topics).toContain('api');

      // Step 3: Select rules
      const availableRules = getAvailableRules();
      const selectedRules = selectRules(availableRules, {
        project: context,
        intent,
        maxRules: 5,
        maxTokens: 5000,
      });

      // Validate selection
      expect(selectedRules.length).toBeGreaterThan(0);
      expect(selectedRules.length).toBeLessThanOrEqual(5);

      // Should include Python and FastAPI rules
      const hasPythonRule = selectedRules.some(r => r.language === 'python');
      const hasFastAPIRule = selectedRules.some(r => r.framework === 'fastapi');
      expect(hasPythonRule || hasFastAPIRule).toBe(true);
    });
  });

  describe('TypeScript + React + Next.js', () => {
    it('should detect and select React/Next.js rules', async () => {
      const projectDir = path.join(__dirname, '../fixtures/nextjs-project');

      const context = await detectContext(projectDir);
      expect(context.languages).toContain('typescript');
      expect(context.frameworks).toContain('nextjs');

      const intent = analyzeIntent('Add client-side form validation');
      const availableRules = getAvailableRules();
      const selectedRules = selectRules(availableRules, {
        project: context,
        intent,
        maxRules: 5,
      });

      expect(selectedRules.length).toBeGreaterThan(0);

      // Should include TypeScript or Next.js rules
      const hasRelevantRule = selectedRules.some(
        r => r.language === 'typescript' || r.framework === 'nextjs' || r.framework === 'react'
      );
      expect(hasRelevantRule).toBe(true);
    });
  });

  describe('Multi-language polyglot project', () => {
    it('should detect multiple languages and frameworks', async () => {
      const projectDir = path.join(__dirname, '../fixtures/polyglot-project');

      const context = await detectContext(projectDir);

      // Should detect at least 2 languages
      expect(context.languages.length).toBeGreaterThanOrEqual(2);
      expect(context.languages).toContain('python');
      expect(context.languages).toContain('go');

      // Should have reasonable confidence
      expect(context.confidence).toBeGreaterThan(0.5);
    });
  });

  describe('MVP vs Production maturity', () => {
    it('should correctly identify MVP project', async () => {
      const projectDir = path.join(__dirname, '../fixtures/mvp-project');

      const context = await detectContext(projectDir);
      expect(context.maturity).toBe('mvp');
    });

    it('should correctly identify production project', async () => {
      const projectDir = path.join(__dirname, '../fixtures/production-project');

      const context = await detectContext(projectDir);
      expect(context.maturity).toBe('production');
    });

    it('should select different rules based on maturity', async () => {
      const mvpContext = await detectContext(path.join(__dirname, '../fixtures/mvp-project'));
      const prodContext = await detectContext(
        path.join(__dirname, '../fixtures/production-project')
      );

      const intent = analyzeIntent('Implement feature');
      const availableRules = getAvailableRules();

      const mvpRules = selectRules(availableRules, {
        project: mvpContext,
        intent,
        maxRules: 10,
      });

      const prodRules = selectRules(availableRules, {
        project: prodContext,
        intent,
        maxRules: 10,
      });

      // At least some rules should be selected for each
      expect(mvpRules.length).toBeGreaterThan(0);
      expect(prodRules.length).toBeGreaterThan(0);

      // Most MVP rules should support MVP maturity
      const mvpApplicable = mvpRules.filter(r => r.maturity.includes('mvp'));
      expect(mvpApplicable.length).toBeGreaterThan(0);

      // Most prod rules should support production maturity
      const prodApplicable = prodRules.filter(r => r.maturity.includes('production'));
      expect(prodApplicable.length).toBeGreaterThan(0);
    });
  });

  describe('Urgent security scenarios', () => {
    it('should prioritize security rules for urgent security issues', async () => {
      const projectDir = path.join(__dirname, '../fixtures/python-fastapi');
      const context = await detectContext(projectDir);

      const intent = analyzeIntent(
        'CRITICAL: Fix SQL injection vulnerability in login endpoint'
      );
      expect(intent.urgency).toBe('high');
      expect(intent.topics).toContain('security');

      const availableRules = getAvailableRules();
      const selectedRules = selectRules(availableRules, {
        project: context,
        intent,
        maxRules: 5,
      });

      // Security or database-related rules should be included
      const hasRelevantRule = selectedRules.some(
        r =>
          r.topics.includes('security') ||
          r.topics.includes('database') ||
          r.path.includes('security')
      );
      expect(hasRelevantRule).toBe(true);
    });
  });

  describe('Testing-focused scenarios', () => {
    it('should select testing rules when user asks about testing', async () => {
      const projectDir = path.join(__dirname, '../fixtures/react-project');
      const context = await detectContext(projectDir);

      const intent = analyzeIntent('How do I write unit tests for this component?');
      expect(intent.topics).toContain('testing');

      const availableRules = getAvailableRules();
      const selectedRules = selectRules(availableRules, {
        project: context,
        intent,
        maxRules: 5,
      });

      // Should include testing-related rules
      const hasTestingRule = selectedRules.some(
        r => r.topics.includes('testing') || r.path.includes('testing')
      );
      expect(hasTestingRule).toBe(true);
    });
  });

  describe('Cloud provider detection', () => {
    it('should detect AWS from terraform directory', async () => {
      const projectDir = path.join(__dirname, '../fixtures/aws-project');
      const context = await detectContext(projectDir);

      expect(context.cloudProviders).toContain('aws');
    });

    it('should detect Vercel from vercel.json', async () => {
      const projectDir = path.join(__dirname, '../fixtures/vercel-project');
      const context = await detectContext(projectDir);

      expect(context.cloudProviders).toContain('vercel');
    });
  });

  describe('Empty project handling', () => {
    it('should handle empty project gracefully', async () => {
      const projectDir = path.join(__dirname, '../fixtures/empty-project');
      const context = await detectContext(projectDir);

      expect(context.languages.length).toBe(0);
      expect(context.frameworks.length).toBe(0);
      expect(context.cloudProviders.length).toBe(0);
      expect(context.maturity).toBe('mvp');
      expect(context.confidence).toBeLessThan(0.5);
    });
  });
});
