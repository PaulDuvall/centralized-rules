/**
 * Tests for classification pattern definitions
 *
 * Verifies that patterns correctly identify their target categories
 * and handle edge cases appropriately.
 */
import { describe, it, expect } from 'vitest';
import {
  LEGAL_BUSINESS_PATTERNS,
  CODE_IMPLEMENTATION_PATTERNS,
  CODE_DEBUGGING_PATTERNS,
  CODE_REVIEW_PATTERNS,
  ARCHITECTURE_PATTERNS,
  DEVOPS_PATTERNS,
  DOCUMENTATION_PATTERNS,
  GENERAL_QUESTION_PATTERNS,
  CODE_INDICATORS,
  NON_CODE_INDICATORS,
} from '../src/config/classification-patterns.js';

describe('Classification Patterns', () => {
  describe('Legal/Business Patterns', () => {
    it('should match legal documents', () => {
      const prompts = [
        'Review our operating agreement',
        'Update the shareholder agreement',
        'Draft a privacy policy for the app',
        'Check the terms of service',
        'Sign the NDA',
      ];

      prompts.forEach((prompt) => {
        const matches = LEGAL_BUSINESS_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should match HR and employment terms', () => {
      const prompts = [
        'Update the employee handbook',
        'Review vacation policy',
        'Create an offer letter',
      ];

      prompts.forEach((prompt) => {
        const matches = LEGAL_BUSINESS_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should NOT match technical SLA implementation', () => {
      const techPrompts = [
        'Implement SLA monitoring in the API',
        'Add SLA metrics to the code',
        'Create SLA endpoint',
      ];

      techPrompts.forEach((prompt) => {
        const matches = LEGAL_BUSINESS_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        // These should NOT match because they have technical context
        expect(matches).toBe(false);
      });
    });

    it('should distinguish financial business from financial API', () => {
      // Should match (business context)
      expect(
        LEGAL_BUSINESS_PATTERNS.some((p) =>
          p.test('Get approval for financial decision')
        )
      ).toBe(true);
      expect(
        LEGAL_BUSINESS_PATTERNS.some((p) =>
          p.test('Review financial threshold policy')
        )
      ).toBe(true);

      // Should NOT match (technical context)
      expect(
        LEGAL_BUSINESS_PATTERNS.some((p) =>
          p.test('Implement financial decision API')
        )
      ).toBe(false);
      expect(
        LEGAL_BUSINESS_PATTERNS.some((p) =>
          p.test('Create financial approval endpoint')
        )
      ).toBe(false);
    });

    it('should distinguish GDPR compliance from GDPR implementation', () => {
      // Should match (compliance context)
      expect(
        LEGAL_BUSINESS_PATTERNS.some((p) => p.test('GDPR compliance review'))
      ).toBe(true);

      // Should NOT match (implementation context)
      expect(
        LEGAL_BUSINESS_PATTERNS.some((p) =>
          p.test('Implement GDPR compliance in the API')
        )
      ).toBe(false);
      expect(
        LEGAL_BUSINESS_PATTERNS.some((p) =>
          p.test('Code GDPR data handling')
        )
      ).toBe(false);
    });
  });

  describe('Code Implementation Patterns', () => {
    it('should match implementation requests', () => {
      const prompts = [
        'Implement a new login function',
        'Create a user authentication component',
        'Add a REST API endpoint',
        'Build a payment service',
        'Write a new feature for notifications',
      ];

      prompts.forEach((prompt) => {
        const matches = CODE_IMPLEMENTATION_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should match file-specific implementation', () => {
      const prompts = [
        'Implement the function in auth.ts',
        'Add validation to user.py',
        'Create handler in main.rs',
      ];

      prompts.forEach((prompt) => {
        const matches = CODE_IMPLEMENTATION_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should have at least 5 patterns', () => {
      expect(CODE_IMPLEMENTATION_PATTERNS.length).toBeGreaterThanOrEqual(5);
    });
  });

  describe('Code Debugging Patterns', () => {
    it('should match error and bug reports', () => {
      const prompts = [
        'Fix this error in the code',
        'Debug the null pointer exception',
        'Resolve the memory leak',
        'The tests are failing',
        'CI build is broken',
      ];

      prompts.forEach((prompt) => {
        const matches = CODE_DEBUGGING_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should match behavioral issues', () => {
      const prompts = [
        'This function is not working',
        "The app doesn't work properly",
        'Why does it crash when I click submit?',
      ];

      prompts.forEach((prompt) => {
        const matches = CODE_DEBUGGING_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should have at least 5 patterns', () => {
      expect(CODE_DEBUGGING_PATTERNS.length).toBeGreaterThanOrEqual(5);
    });
  });

  describe('Code Review Patterns', () => {
    it('should match review requests', () => {
      const prompts = [
        'Review this code',
        'Check my implementation',
        'Feedback on this function',
        'Is this best practice?',
        'How can I improve this code?',
      ];

      prompts.forEach((prompt) => {
        const matches = CODE_REVIEW_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should have at least 5 patterns', () => {
      expect(CODE_REVIEW_PATTERNS.length).toBeGreaterThanOrEqual(5);
    });
  });

  describe('Architecture Patterns', () => {
    it('should match architecture and design discussions', () => {
      const prompts = [
        'Design a microservices architecture',
        'What database schema should I use?',
        'How to design the API?',
        'Explain event-driven architecture',
        'System design for high availability',
      ];

      prompts.forEach((prompt) => {
        const matches = ARCHITECTURE_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should have at least 5 patterns', () => {
      expect(ARCHITECTURE_PATTERNS.length).toBeGreaterThanOrEqual(5);
    });
  });

  describe('DevOps Patterns', () => {
    it('should match DevOps and infrastructure tasks', () => {
      const prompts = [
        'Deploy to kubernetes',
        'Set up CI/CD pipeline',
        'Configure docker container',
        'Create terraform infrastructure',
        'Setup monitoring with prometheus',
      ];

      prompts.forEach((prompt) => {
        const matches = DEVOPS_PATTERNS.some((pattern) => pattern.test(prompt));
        expect(matches).toBe(true);
      });
    });

    it('should have at least 5 patterns', () => {
      expect(DEVOPS_PATTERNS.length).toBeGreaterThanOrEqual(5);
    });
  });

  describe('Documentation Patterns', () => {
    it('should match documentation tasks', () => {
      const prompts = [
        'Write documentation for this API',
        'Create a README',
        'Document this function',
        'Generate API docs',
        'Add JSDoc comments',
      ];

      prompts.forEach((prompt) => {
        const matches = DOCUMENTATION_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should have at least 5 patterns', () => {
      expect(DOCUMENTATION_PATTERNS.length).toBeGreaterThanOrEqual(5);
    });
  });

  describe('General Question Patterns', () => {
    it('should match informational questions', () => {
      const prompts = [
        'What is React?',
        'How does async/await work?',
        'Explain the difference between var and let',
        'Tell me about microservices',
      ];

      prompts.forEach((prompt) => {
        const matches = GENERAL_QUESTION_PATTERNS.some((pattern) =>
          pattern.test(prompt)
        );
        expect(matches).toBe(true);
      });
    });

    it('should have at least 4 patterns', () => {
      expect(GENERAL_QUESTION_PATTERNS.length).toBeGreaterThanOrEqual(4);
    });
  });

  describe('Code Indicators', () => {
    it('should have weighted indicators', () => {
      expect(CODE_INDICATORS.length).toBeGreaterThan(0);
      CODE_INDICATORS.forEach((indicator) => {
        expect(indicator.pattern).toBeInstanceOf(RegExp);
        expect(indicator.weight).toBeGreaterThan(0);
        expect(indicator.signal).toBeTruthy();
      });
    });

    it('should detect file extensions', () => {
      const indicator = CODE_INDICATORS.find(
        (i) => i.signal === 'file extension reference'
      );
      expect(indicator).toBeDefined();
      expect(indicator!.pattern.test('auth.ts')).toBe(true);
      expect(indicator!.pattern.test('main.py')).toBe(true);
      expect(indicator!.pattern.test('handler.rs')).toBe(true);
    });

    it('should detect code constructs', () => {
      const indicator = CODE_INDICATORS.find(
        (i) => i.signal === 'code construct keywords'
      );
      expect(indicator).toBeDefined();
      expect(indicator!.pattern.test('create a function')).toBe(true);
      expect(indicator!.pattern.test('define a class')).toBe(true);
      expect(indicator!.pattern.test('implement interface')).toBe(true);
    });

    it('should have balanced weights', () => {
      const totalWeight = CODE_INDICATORS.reduce(
        (sum, ind) => sum + ind.weight,
        0
      );
      // Total weight should be reasonable (not too high or too low)
      expect(totalWeight).toBeGreaterThan(50);
      expect(totalWeight).toBeLessThan(500);
    });

    it('should have at least 8 indicators', () => {
      expect(CODE_INDICATORS.length).toBeGreaterThanOrEqual(8);
    });
  });

  describe('Non-Code Indicators', () => {
    it('should have weighted indicators', () => {
      expect(NON_CODE_INDICATORS.length).toBeGreaterThan(0);
      NON_CODE_INDICATORS.forEach((indicator) => {
        expect(indicator.pattern).toBeInstanceOf(RegExp);
        expect(indicator.weight).toBeGreaterThan(0);
        expect(indicator.signal).toBeTruthy();
      });
    });

    it('should detect legal terminology', () => {
      const indicator = NON_CODE_INDICATORS.find(
        (i) => i.signal === 'legal terminology'
      );
      expect(indicator).toBeDefined();
      expect(indicator!.pattern.test('sign the contract')).toBe(true);
      expect(indicator!.pattern.test('liability clause')).toBe(true);
      expect(indicator!.pattern.test('warranty terms')).toBe(true);
    });

    it('should distinguish business terms from technical context', () => {
      const indicator = NON_CODE_INDICATORS.find(
        (i) => i.signal === 'financial/business terms'
      );
      expect(indicator).toBeDefined();

      // Should match business context
      expect(indicator!.pattern.test('review the revenue report')).toBe(true);

      // Should NOT match technical context
      expect(indicator!.pattern.test('implement revenue API')).toBe(false);
      expect(indicator!.pattern.test('create billing endpoint')).toBe(false);
    });

    it('should have balanced weights', () => {
      const totalWeight = NON_CODE_INDICATORS.reduce(
        (sum, ind) => sum + ind.weight,
        0
      );
      // Total weight should be reasonable
      expect(totalWeight).toBeGreaterThan(50);
      expect(totalWeight).toBeLessThan(500);
    });

    it('should have at least 6 indicators', () => {
      expect(NON_CODE_INDICATORS.length).toBeGreaterThanOrEqual(6);
    });
  });

  describe('Edge Cases', () => {
    it('should handle mixed contexts correctly', () => {
      // "API" should be code context despite having "financial"
      const codeMatch = CODE_INDICATORS.some((ind) =>
        ind.pattern.test('financial API implementation')
      );
      expect(codeMatch).toBe(true);

      // Pure financial should match non-code
      const nonCodeMatch = NON_CODE_INDICATORS.some((ind) =>
        ind.pattern.test('financial budget approval')
      );
      expect(nonCodeMatch).toBe(true);
    });

    it('should distinguish employee management code from HR', () => {
      // HR context
      const hrIndicator = NON_CODE_INDICATORS.find(
        (i) => i.signal === 'HR terminology'
      );
      expect(hrIndicator!.pattern.test('employee handbook review')).toBe(true);

      // Code context (should not match due to negative lookahead)
      expect(hrIndicator!.pattern.test('implement user management API')).toBe(
        false
      );
    });
  });
});
