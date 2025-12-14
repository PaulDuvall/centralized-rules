/**
 * Centralized Rules Skill for Claude
 *
 * A Claude skill that automatically loads relevant coding rules based on project context.
 *
 * @packageDocumentation
 */

// Export all types
export * from './types';

// Export hooks with specific names
export { handler as beforeResponseHandler } from './hooks/before-response';

// Export tools with specific names
export { handler as detectContextHandler, detectContext } from './tools/detect-context';
export { handler as getRulesHandler, fetchRule, fetchRules } from './tools/get-rules';
export { selectRules, analyzeIntent, getAvailableRules } from './tools/select-rules';

// Export cache
export * from './cache/rules-cache';

/**
 * Skill version
 */
export const VERSION = '0.1.0';

/**
 * Skill name
 */
export const SKILL_NAME = 'centralized-rules';
