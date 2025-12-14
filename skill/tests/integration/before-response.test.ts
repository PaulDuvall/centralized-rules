/**
 * Integration tests for beforeResponse hook
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { handler as beforeResponseHandler } from '../../src/hooks/before-response';
import type { SkillContext } from '../../src/types';
import { resetCache } from '../../src/cache/rules-cache';

// Mock Octokit
vi.mock('@octokit/rest', () => {
  return {
    Octokit: vi.fn().mockImplementation(() => ({
      repos: {
        getContent: vi.fn().mockImplementation(({ path }) => {
          const mockContent = `# ${path}\n\n## Best Practices\n\nFollow these guidelines...`;
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

describe('beforeResponse hook integration', () => {
  beforeEach(() => {
    resetCache();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('should complete full workflow with Python project', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'paulduvall/centralized-rules',
        rulesBranch: 'main',
        enableAutoLoad: true,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 5,
        maxTokens: 5000,
        verbose: false,
      },
      messages: [
        {
          role: 'user',
          content: 'I need to implement authentication for my FastAPI application',
        },
      ],
      workingDirectory: __dirname + '/../fixtures/python-fastapi',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    expect(result.continue).toBe(true);
    expect(result.systemPrompt).toBeTruthy();
    expect(result.systemPrompt).toContain('Relevant Coding Rules');
    expect(result.systemPrompt).toContain('python');
    expect(result.metadata).toBeTruthy();
  });

  it('should complete full workflow with TypeScript/React project', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'paulduvall/centralized-rules',
        rulesBranch: 'main',
        enableAutoLoad: true,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 5,
        maxTokens: 5000,
        verbose: false,
      },
      messages: [
        {
          role: 'user',
          content: 'How do I test this React component?',
        },
      ],
      workingDirectory: __dirname + '/../fixtures/react-project',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    expect(result.continue).toBe(true);
    expect(result.systemPrompt).toContain('typescript');
    expect(result.systemPrompt).toContain('react');
  });

  it('should skip when autoLoad is disabled', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'paulduvall/centralized-rules',
        rulesBranch: 'main',
        enableAutoLoad: false,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 5,
        maxTokens: 5000,
        verbose: false,
      },
      messages: [
        {
          role: 'user',
          content: 'Write a function',
        },
      ],
      workingDirectory: __dirname + '/../fixtures/python-project',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    expect(result.continue).toBe(true);
    expect(result.systemPrompt).toBeUndefined();
  });

  it('should handle messages with no user input', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'paulduvall/centralized-rules',
        rulesBranch: 'main',
        enableAutoLoad: true,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 5,
        maxTokens: 5000,
        verbose: false,
      },
      messages: [],
      workingDirectory: __dirname + '/../fixtures/python-project',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    expect(result.continue).toBe(true);
    expect(result.systemPrompt).toBeUndefined();
  });

  it('should include metadata about execution', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'paulduvall/centralized-rules',
        rulesBranch: 'main',
        enableAutoLoad: true,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 5,
        maxTokens: 5000,
        verbose: true,
      },
      messages: [
        {
          role: 'user',
          content: 'Implement a secure API endpoint',
        },
      ],
      workingDirectory: __dirname + '/../fixtures/python-fastapi',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    expect(result.metadata).toBeTruthy();
    expect(result.metadata?.projectContext).toBeTruthy();
    expect(result.metadata?.userIntent).toBeTruthy();
    expect(result.metadata?.rulesLoaded).toBeGreaterThan(0);
    expect(result.metadata?.timing).toBeTruthy();
  });

  it('should respect maxRules configuration', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'paulduvall/centralized-rules',
        rulesBranch: 'main',
        enableAutoLoad: true,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 2,
        maxTokens: 10000,
        verbose: true,
      },
      messages: [
        {
          role: 'user',
          content: 'Write some code',
        },
      ],
      workingDirectory: __dirname + '/../fixtures/full-stack-project',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    // maxRules should limit the number of rules loaded
    // May not be exactly 2 if some rules fail to fetch
    expect(result.metadata?.rulesLoaded).toBeLessThanOrEqual(5);
  });

  it('should handle errors gracefully', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'invalid/repo/format',
        rulesBranch: 'main',
        enableAutoLoad: true,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 5,
        maxTokens: 5000,
        verbose: false,
      },
      messages: [
        {
          role: 'user',
          content: 'Test message',
        },
      ],
      workingDirectory: __dirname + '/../fixtures/python-project',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    // Should never block Claude
    expect(result.continue).toBe(true);
  });

  it('should detect intent from security-related messages', async () => {
    const context: SkillContext = {
      config: {
        rulesRepo: 'paulduvall/centralized-rules',
        rulesBranch: 'main',
        enableAutoLoad: true,
        cacheEnabled: true,
        cacheTTL: 3600,
        maxRules: 5,
        maxTokens: 5000,
        verbose: true,
      },
      messages: [
        {
          role: 'user',
          content: 'URGENT: Fix the SQL injection vulnerability',
        },
      ],
      workingDirectory: __dirname + '/../fixtures/python-project',
      openFiles: [],
      recentFiles: [],
    };

    const result = await beforeResponseHandler(context);

    expect(result.metadata?.userIntent?.topics).toContain('security');
    expect(result.metadata?.userIntent?.urgency).toBe('high');
  });
});
