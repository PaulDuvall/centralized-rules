/**
 * Tests for prompt classification
 */
import { describe, it, expect } from 'vitest';
import { classifyPrompt, PromptCategory } from '../src/services/prompt-classifier.js';

describe('Prompt Classifier', () => {
  describe('Basic classification', () => {
    it('should classify code implementation prompts', () => {
      expect(classifyPrompt('Implement a new login feature')).toBe(PromptCategory.CODE_IMPLEMENTATION);
      expect(classifyPrompt('Create a user authentication component')).toBe(PromptCategory.CODE_IMPLEMENTATION);
      expect(classifyPrompt('Add a new API endpoint for users')).toBe(PromptCategory.CODE_IMPLEMENTATION);
    });

    it('should classify debugging prompts', () => {
      expect(classifyPrompt('Fix this error in the login function')).toBe(PromptCategory.CODE_DEBUGGING);
      expect(classifyPrompt('This code is broken and not working')).toBe(PromptCategory.CODE_DEBUGGING);
      expect(classifyPrompt('Debug the crash in production')).toBe(PromptCategory.CODE_DEBUGGING);
    });

    it('should classify code review prompts', () => {
      expect(classifyPrompt('Review this code for best practices')).toBe(PromptCategory.CODE_REVIEW);
      expect(classifyPrompt('Give me feedback on this function')).toBe(PromptCategory.CODE_REVIEW);
    });

    it('should classify architecture prompts', () => {
      expect(classifyPrompt('Design a microservices architecture')).toBe(PromptCategory.ARCHITECTURE);
      expect(classifyPrompt('What database schema should I use?')).toBe(PromptCategory.ARCHITECTURE);
    });

    it('should classify DevOps prompts', () => {
      expect(classifyPrompt('Set up a CI/CD pipeline')).toBe(PromptCategory.DEVOPS);
      expect(classifyPrompt('Deploy this app to kubernetes')).toBe(PromptCategory.DEVOPS);
    });

    it('should classify documentation prompts', () => {
      expect(classifyPrompt('Document this API')).toBe(PromptCategory.DOCUMENTATION);
      expect(classifyPrompt('Write a README for this project')).toBe(PromptCategory.DOCUMENTATION);
    });

    it('should classify legal/business prompts', () => {
      expect(classifyPrompt('Review our privacy policy for GDPR compliance')).toBe(PromptCategory.LEGAL_BUSINESS);
      expect(classifyPrompt('Draft terms of service')).toBe(PromptCategory.LEGAL_BUSINESS);
    });

    it('should classify general questions', () => {
      expect(classifyPrompt('What is React?')).toBe(PromptCategory.GENERAL_QUESTION);
      expect(classifyPrompt('Explain how async/await works')).toBe(PromptCategory.GENERAL_QUESTION);
    });

    it('should return UNCLEAR for ambiguous prompts', () => {
      expect(classifyPrompt('Help')).toBe(PromptCategory.UNCLEAR);
      expect(classifyPrompt('')).toBe(PromptCategory.UNCLEAR);
      expect(classifyPrompt('   ')).toBe(PromptCategory.UNCLEAR);
    });
  });

  describe('Pattern matching (high-confidence cases)', () => {
    it('should use pattern matching for legal/business terms', () => {
      expect(classifyPrompt('Update the privacy policy')).toBe(PromptCategory.LEGAL_BUSINESS);
      expect(classifyPrompt('Review the terms of service')).toBe(PromptCategory.LEGAL_BUSINESS);
      expect(classifyPrompt('Check GDPR compliance')).toBe(PromptCategory.LEGAL_BUSINESS);
      expect(classifyPrompt('Draft a contract')).toBe(PromptCategory.LEGAL_BUSINESS);
    });

    it('should use pattern matching for debugging terms', () => {
      expect(classifyPrompt('Error message in console')).toBe(PromptCategory.CODE_DEBUGGING);
      expect(classifyPrompt('App crashes on startup')).toBe(PromptCategory.CODE_DEBUGGING);
      expect(classifyPrompt('Stack trace shows exception')).toBe(PromptCategory.CODE_DEBUGGING);
      expect(classifyPrompt('Why does this fail?')).toBe(PromptCategory.CODE_DEBUGGING);
    });

    it('should use pattern matching for DevOps terms', () => {
      expect(classifyPrompt('Configure docker container')).toBe(PromptCategory.DEVOPS);
      expect(classifyPrompt('Setup GitHub Actions pipeline')).toBe(PromptCategory.DEVOPS);
      expect(classifyPrompt('Deploy to production')).toBe(PromptCategory.DEVOPS);
      expect(classifyPrompt('Setup monitoring and alerts')).toBe(PromptCategory.DEVOPS);
    });
  });

  describe('Domain-driven design', () => {
    // Before these patterns existed, most of these fell through to UNCLEAR,
    // which before-response.ts treats as non-code and skips rule injection.
    it('should classify DDD prompts as architecture', () => {
      const prompts = [
        'Apply DDD to the billing module',
        'Make the checkout module domain-driven',
        'Split billing and shipping into separate bounded contexts',
        'Draw a context map for the fulfillment team',
        'Add an anti-corruption layer around the legacy ERP',
        'Rename the classes to match the ubiquitous language',
        'Move the pricing logic into the Order aggregate root',
        'Replace the raw email strings with a value object',
        'Sketch the domain model for invoicing',
        'Publish a domain event when an order ships',
        'Run an event storming session on returns',
      ];

      prompts.forEach((prompt) => {
        expect(classifyPrompt(prompt), prompt).toBe(PromptCategory.ARCHITECTURE);
      });
    });

    // DevOps and legal/business are checked before architecture, so a bare
    // "service" or "salary" used to win over the DDD vocabulary.
    it('should not let "service" or "salary" override DDD vocabulary', () => {
      const prompts = [
        'Split the order service into bounded contexts',
        'Extract a domain service for pricing',
        'Model the salary calculation as a value object',
      ];

      prompts.forEach((prompt) => {
        expect(classifyPrompt(prompt), prompt).toBe(PromptCategory.ARCHITECTURE);
      });
    });
  });

  describe('Overlap with DevOps and legal/business patterns', () => {
    it('should classify building a service as implementation, not DevOps', () => {
      expect(classifyPrompt('Build a payment service')).toBe(PromptCategory.CODE_IMPLEMENTATION);
      expect(classifyPrompt('Create an inventory service class')).toBe(
        PromptCategory.CODE_IMPLEMENTATION
      );
    });

    it('should keep service operations in DevOps', () => {
      const prompts = [
        'Deploy the service to production',
        'Restart the service on the staging cluster',
        'Configure a service mesh with istio',
        'Expose the app with a kubernetes service',
      ];

      prompts.forEach((prompt) => {
        expect(classifyPrompt(prompt), prompt).toBe(PromptCategory.DEVOPS);
      });
    });

    it('should not treat HR terms in a code context as legal/business', () => {
      // LEGAL_BUSINESS skips rule injection, so a false positive here costs the most
      const prompts = [
        'Add compensation logic to the order saga',
        'Add a salary field to the Employee entity',
      ];

      prompts.forEach((prompt) => {
        expect(classifyPrompt(prompt), prompt).toBe(PromptCategory.CODE_IMPLEMENTATION);
      });
    });

    it('should let code patterns win over generic ops words', () => {
      const cases: Array<[string, PromptCategory]> = [
        ['Create a notification service class', PromptCategory.CODE_IMPLEMENTATION],
        ['Add a toast notification component', PromptCategory.CODE_IMPLEMENTATION],
        ['Add logging to the parser function', PromptCategory.CODE_IMPLEMENTATION],
        ['Add a logging middleware to the Express app', PromptCategory.CODE_IMPLEMENTATION],
        ['Write a function that records request metrics', PromptCategory.CODE_IMPLEMENTATION],
        ['Add an alert component to the settings page', PromptCategory.CODE_IMPLEMENTATION],
        ['Build a data pipeline module for the ETL job', PromptCategory.CODE_IMPLEMENTATION],
        ['Register the OrderRepository in the DI container', PromptCategory.ARCHITECTURE],
        [
          'Move the repository implementation into the infrastructure layer',
          PromptCategory.ARCHITECTURE,
        ],
      ];

      cases.forEach(([prompt, expected]) => {
        expect(classifyPrompt(prompt), prompt).toBe(expected);
      });
    });

    it('should keep operations prompts in DevOps', () => {
      const prompts = [
        'Setup monitoring and alerts',
        'Configure log shipping to the observability stack',
        'Add a lint step to the pipeline',
        'Build a CI pipeline for the payment service',
        'Run the app in a container',
        'Set up on-call rotation and incident response',
        'Provision the staging infrastructure',
        'Collect metrics from the cluster',
        'Rotate the salt minion keys',
        'Enable distributed tracing with OpenTelemetry',
      ];

      prompts.forEach((prompt) => {
        expect(classifyPrompt(prompt), prompt).toBe(PromptCategory.DEVOPS);
      });
    });

    it('should fall back to DevOps, not UNCLEAR, when no code pattern matches', () => {
      // UNCLEAR skips rule injection; DevOps still loads rules
      expect(classifyPrompt('Send an email notification when an order ships')).toBe(
        PromptCategory.DEVOPS
      );
    });

    it('should keep HR prompts in legal/business', () => {
      const prompts = [
        'Review the salary bands for the engineering team',
        'Update the benefits package for 2027',
        'Draft the compensation plan for sales',
        'Schedule the annual performance review',
      ];

      prompts.forEach((prompt) => {
        expect(classifyPrompt(prompt), prompt).toBe(PromptCategory.LEGAL_BUSINESS);
      });
    });
  });

  describe('Keyword scoring (fallback)', () => {
    it('should fall back to keyword scoring for less clear cases', () => {
      // Prompt with implementation keywords but no strong pattern
      expect(classifyPrompt('Need to make a new helper for validation')).toBe(PromptCategory.CODE_IMPLEMENTATION);

      // Prompt with debugging keywords but no strong pattern
      expect(classifyPrompt('Something is wrong with the API')).toBe(PromptCategory.CODE_DEBUGGING);
    });

    it('should return UNCLEAR when keyword scores are tied or too low', () => {
      // Generic prompt with no clear category
      expect(classifyPrompt('Just some random text here')).toBe(PromptCategory.UNCLEAR);

      // Very short prompt
      expect(classifyPrompt('yes')).toBe(PromptCategory.UNCLEAR);
    });
  });

  describe('Edge cases', () => {
    it('should handle empty or whitespace-only prompts', () => {
      expect(classifyPrompt('')).toBe(PromptCategory.UNCLEAR);
      expect(classifyPrompt('   ')).toBe(PromptCategory.UNCLEAR);
      expect(classifyPrompt('\n\t')).toBe(PromptCategory.UNCLEAR);
    });

    it('should be case-insensitive', () => {
      expect(classifyPrompt('FIX THIS BUG')).toBe(PromptCategory.CODE_DEBUGGING);
      expect(classifyPrompt('Implement New Feature')).toBe(PromptCategory.CODE_IMPLEMENTATION);
      expect(classifyPrompt('DEPLOY TO KUBERNETES')).toBe(PromptCategory.DEVOPS);
    });

    it('should handle mixed-category prompts by choosing the strongest signal', () => {
      // Debugging signal should be stronger
      expect(classifyPrompt('Fix the error in the new feature implementation')).toBe(PromptCategory.CODE_DEBUGGING);

      // Legal signal should be strongest
      expect(classifyPrompt('Implement GDPR compliance features')).toBe(PromptCategory.LEGAL_BUSINESS);
    });
  });
});
