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
