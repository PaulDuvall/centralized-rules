/**
 * Get rules tool - fetches rules from GitHub with caching
 */

import { Octokit } from '@octokit/rest';
import type { Rule, RuleInfo, SkillConfig } from '../types';
import { getCache } from '../cache/rules-cache';
import { extractTopicsFromPathAndContent } from '../services/metadata-extractor';
import { ConfigurationError, GitHubApiError, getErrorMessage } from '../errors';
import { loggers } from '../services/logger';

/**
 * GitHub API client (singleton)
 */
let octokit: Octokit | null = null;

/**
 * Get or create Octokit instance
 */
function getOctokit(): Octokit {
  if (!octokit) {
    octokit = new Octokit({
      // Use GITHUB_TOKEN if available (for higher rate limits)
      auth: process.env['GITHUB_TOKEN'],
    });
  }
  return octokit;
}

/**
 * Fetch a single rule from GitHub
 */
export async function fetchRule(
  rulePath: string,
  config: SkillConfig
): Promise<Rule | null> {
  const cache = getCache(config.cacheTTL);
  const logger = loggers.rules;

  // Check cache first
  if (config.cacheEnabled && cache.has(rulePath)) {
    const cached = cache.get(rulePath);
    if (cached) {
      logger.debug('Cache hit', { rulePath });
      return cached;
    }
  }

  logger.debug('Fetching rule from GitHub', { rulePath });

  try {
    const repoParts = config.rulesRepo.split('/');
    if (repoParts.length !== 2 || !repoParts[0] || !repoParts[1]) {
      throw new ConfigurationError(
        `Invalid repository format: ${config.rulesRepo}. Expected format: owner/repo`,
        'rulesRepo',
        { rulesRepo: config.rulesRepo }
      );
    }

    const [owner, repo] = repoParts;
    const client = getOctokit();

    // Fetch the file content from GitHub
    const response = await client.repos.getContent({
      owner,
      repo,
      path: rulePath,
      ref: config.rulesBranch,
    });

    // Handle the response
    if ('content' in response.data && response.data.type === 'file') {
      const content = Buffer.from(response.data.content, 'base64').toString('utf-8');

      // Extract title from markdown (first # heading)
      const titleMatch = content.match(/^#\s+(.+)$/m);
      const title = titleMatch && titleMatch[1] ? titleMatch[1] : rulePath;

      // Determine category from path
      const category = determineCategory(rulePath);

      // Create the rule object
      const rule: Rule = {
        path: rulePath,
        title,
        category,
        topics: extractTopicsFromPathAndContent(content, rulePath),
        maturity: extractMaturity(content),
        estimatedTokens: estimateTokens(content),
        content,
        fetchedAt: new Date(),
        ...extractMetadata(rulePath),
      };

      // Cache the rule
      if (config.cacheEnabled) {
        cache.set(rulePath, rule);
      }

      return rule;
    } else {
      // Invalid response type (directory, symlink, etc.)
      logger.debug('Path is not a file', { rulePath });
      return null;
    }
  } catch (error) {
    // Handle specific GitHub API errors
    if (error && typeof error === 'object' && 'status' in error) {
      const apiError = error as { status: number; message?: string };

      // 404 = Rule not found (expected case, return null)
      if (apiError.status === 404) {
        logger.debug('Rule not found', { rulePath, status: 404 });
        return null;
      }

      // 403 = Rate limit or permissions
      if (apiError.status === 403) {
        throw new GitHubApiError(
          `GitHub API rate limit or permission denied for ${rulePath}`,
          403,
          undefined,
          { rulePath, error: getErrorMessage(error) }
        );
      }

      // Other API errors
      throw new GitHubApiError(
        `GitHub API error fetching ${rulePath}: ${getErrorMessage(error)}`,
        apiError.status,
        undefined,
        { rulePath, error: getErrorMessage(error) }
      );
    }

    // Re-throw if it's already a ConfigurationError
    if (error instanceof ConfigurationError) {
      throw error;
    }

    // Unexpected errors
    throw new GitHubApiError(
      `Unexpected error fetching rule ${rulePath}: ${getErrorMessage(error)}`,
      undefined,
      undefined,
      { rulePath, error: getErrorMessage(error) }
    );
  }
}

/**
 * Fetch multiple rules in parallel
 */
export async function fetchRules(
  ruleInfos: RuleInfo[],
  config: SkillConfig
): Promise<Rule[]> {
  const maxConcurrent = 5; // Limit concurrent requests to avoid rate limiting
  const rules: Rule[] = [];

  // Process in batches
  for (let i = 0; i < ruleInfos.length; i += maxConcurrent) {
    const batch = ruleInfos.slice(i, i + maxConcurrent);
    const batchPromises = batch.map(info => fetchRule(info.path, config));
    const batchResults = await Promise.all(batchPromises);

    // Filter out null results (failed fetches)
    rules.push(...batchResults.filter((rule): rule is Rule => rule !== null));
  }

  return rules;
}

/**
 * Determine rule category from path
 */
function determineCategory(path: string): 'base' | 'language' | 'framework' | 'cloud' {
  if (path.startsWith('base/')) return 'base';
  if (path.startsWith('languages/')) return 'language';
  if (path.startsWith('frameworks/')) return 'framework';
  if (path.startsWith('cloud/')) return 'cloud';
  return 'base';
}

/**
 * Extract metadata (language, framework, cloud provider) from path
 */
function extractMetadata(path: string): {
  language?: string;
  framework?: string;
  cloudProvider?: string;
} {
  const parts = path.split('/');

  if (parts[0] === 'languages' && parts.length >= 2 && parts[1]) {
    return { language: parts[1] };
  }

  if (parts[0] === 'frameworks' && parts.length >= 2 && parts[1]) {
    // Determine language from framework
    const framework = parts[1];
    const language = getLanguageForFramework(framework);
    return { framework, language };
  }

  if (parts[0] === 'cloud' && parts.length >= 2 && parts[1]) {
    return { cloudProvider: parts[1] };
  }

  return {};
}

/**
 * Get the primary language for a framework
 */
function getLanguageForFramework(framework: string): string | undefined {
  const frameworkLanguages: Record<string, string> = {
    fastapi: 'python',
    django: 'python',
    flask: 'python',
    react: 'typescript',
    nextjs: 'typescript',
    express: 'typescript',
    nestjs: 'typescript',
    springboot: 'java',
    gin: 'go',
    echo: 'go',
  };

  return frameworkLanguages[framework];
}

/**
 * Extract maturity levels from content
 */
function extractMaturity(content: string): ('mvp' | 'pre-production' | 'production')[] {
  const lowerContent = content.toLowerCase();

  // Look for maturity level indicators
  if (lowerContent.includes('maturity level:')) {
    const match = lowerContent.match(/maturity level:\s*\*\*([^*]+)\*\*/);
    if (match && match[1]) {
      const level = match[1].trim().toLowerCase();
      if (level === 'all') {
        return ['mvp', 'pre-production', 'production'];
      }
      if (level.includes('mvp')) return ['mvp'];
      if (level.includes('pre-production')) return ['pre-production'];
      if (level.includes('production')) return ['production'];
    }
  }

  // Default: all levels
  return ['mvp', 'pre-production', 'production'];
}

/**
 * Estimate token count for content
 * Rough estimation: ~4 characters per token
 */
function estimateTokens(content: string): number {
  return Math.ceil(content.length / 4);
}

/**
 * Tool handler for Claude
 */
export async function handler(
  params: {
    language?: string;
    framework?: string;
    topic?: string;
    maturity?: 'mvp' | 'pre-production' | 'production';
  },
  config: SkillConfig
): Promise<Rule[]> {
  // Build paths based on parameters
  const paths: string[] = [];

  if (params.language) {
    paths.push(`languages/${params.language}/coding-standards.md`);
    paths.push(`languages/${params.language}/testing.md`);
  }

  if (params.framework) {
    paths.push(`frameworks/${params.framework}/best-practices.md`);
  }

  if (params.topic) {
    // Map topic to base rules
    const topicPaths: Record<string, string> = {
      security: 'base/security-principles.md',
      testing: 'base/testing-philosophy.md',
      architecture: 'base/architecture-principles.md',
      git: 'base/git-workflow.md',
    };

    const topicPath = topicPaths[params.topic];
    if (topicPath) {
      paths.push(topicPath);
    }
  }

  // If no specific rules requested, return base rules
  if (paths.length === 0) {
    paths.push('base/code-quality.md');
    paths.push('base/ai-assisted-development.md');
  }

  // Fetch the rules
  const ruleInfos: RuleInfo[] = paths.map(rulePath => ({
    path: rulePath,
    title: rulePath,
    category: determineCategory(rulePath),
    topics: [],
    maturity: ['mvp', 'pre-production', 'production'] as ('mvp' | 'pre-production' | 'production')[],
    estimatedTokens: 1000,
  }));

  return fetchRules(ruleInfos, config);
}
