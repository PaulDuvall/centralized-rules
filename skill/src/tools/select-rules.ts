/**
 * Smart rule selection algorithm
 * Scores and ranks rules based on project context and user intent
 */

import type { RuleInfo, RuleSelectionParams, UserIntent } from '../types';
import { loadRulesConfig } from '../config/rule-config-loader';
import { extractTopicsFromText } from '../services/metadata-extractor';
import { PromptCategory } from '../services/prompt-classifier';

/**
 * Scoring weights for different factors
 */
const WEIGHTS = {
  LANGUAGE_MATCH: 100,
  FRAMEWORK_MATCH: 100,
  CLOUD_MATCH: 75,
  MATURITY_MATCH: 50,
  TOPIC_MATCH: 80, // Increased to prioritize explicit topic requests
  BASE_RULE: 20,
  URGENCY_BOOST: 25,
  CATEGORY_BOOST: 30, // Boost for category-relevant rules
  ALWAYS_LOAD: 200,
};

/**
 * Category-specific topic boosting
 * Maps prompt categories to topics that should be boosted
 */
const CATEGORY_BOOSTS: Partial<Record<PromptCategory, { topics: string[]; boost: number }>> = {
  [PromptCategory.CODE_DEBUGGING]: {
    topics: ['testing', 'debugging', 'logging', 'error-handling'],
    boost: 30,
  },
  [PromptCategory.ARCHITECTURE]: {
    topics: ['architecture', 'design', 'patterns', 'scalability'],
    boost: 25,
  },
  [PromptCategory.DEVOPS]: {
    topics: ['deployment', 'ci-cd', 'infrastructure', 'monitoring'],
    boost: 25,
  },
  [PromptCategory.DOCUMENTATION]: {
    topics: ['documentation', 'comments'],
    boost: 20,
  },
  [PromptCategory.CODE_REVIEW]: {
    topics: ['code-quality', 'security', 'best-practices'],
    boost: 20,
  },
  [PromptCategory.CODE_IMPLEMENTATION]: {
    topics: ['testing', 'security', 'best-practices'],
    boost: 15,
  },
};

/**
 * Scored rule with its relevance score
 */
interface ScoredRule extends RuleInfo {
  score: number;
  reasons: string[];
}

/**
 * Select the most relevant rules based on context and intent
 *
 * @param availableRules - All available rules to choose from
 * @param params - Selection parameters (context, intent, limits)
 * @param category - Optional prompt category for category-aware boosting
 */
export function selectRules(
  availableRules: RuleInfo[],
  params: RuleSelectionParams,
  category?: PromptCategory
): RuleInfo[] {
  // Score all rules with optional category boosting
  const scoredRules = availableRules.map((rule) => scoreRule(rule, params, category));

  // Sort by score (descending)
  scoredRules.sort((a, b) => b.score - a.score);

  // Filter out rules with very low scores (< 10)
  const relevantRules = scoredRules.filter((rule) => rule.score >= 10);

  // Apply token budget and maxRules constraints
  let selectedRules: ScoredRule[];
  if (params.maxTokens) {
    selectedRules = applyTokenBudget(relevantRules, params.maxTokens);
    // Also respect maxRules even when using token budget
    if (selectedRules.length > params.maxRules) {
      selectedRules = selectedRules.slice(0, params.maxRules);
    }
  } else {
    selectedRules = relevantRules.slice(0, params.maxRules);
  }

  // Return without score and reasons (clean RuleInfo objects)
  return selectedRules.map(({ score: _score, reasons: _reasons, ...rule }) => rule);
}

/**
 * Score a single rule based on context, intent, and category
 *
 * @param rule - The rule to score
 * @param params - Selection parameters
 * @param category - Optional prompt category for boosting
 */
function scoreRule(
  rule: RuleInfo,
  params: RuleSelectionParams,
  category?: PromptCategory
): ScoredRule {
  let score = 0;
  const reasons: string[] = [];

  const { project, intent } = params;

  // Base rules get a base score
  if (rule.category === 'base') {
    score += WEIGHTS.BASE_RULE;
    reasons.push('Base rule');
  }

  // Language match
  if (rule.language && project.languages.includes(rule.language)) {
    score += WEIGHTS.LANGUAGE_MATCH;
    reasons.push(`Language match: ${rule.language}`);
  }

  // Framework match
  if (rule.framework && project.frameworks.includes(rule.framework)) {
    score += WEIGHTS.FRAMEWORK_MATCH;
    reasons.push(`Framework match: ${rule.framework}`);
  }

  // Cloud provider match
  if (rule.cloudProvider && project.cloudProviders.includes(rule.cloudProvider)) {
    score += WEIGHTS.CLOUD_MATCH;
    reasons.push(`Cloud match: ${rule.cloudProvider}`);
  }

  // Maturity level match
  if (rule.maturity.includes(project.maturity)) {
    score += WEIGHTS.MATURITY_MATCH;
    reasons.push(`Maturity match: ${project.maturity}`);
  }

  // Topic matches
  const matchingTopics = rule.topics.filter((topic) => intent.topics.includes(topic));
  if (matchingTopics.length > 0) {
    const topicScore = matchingTopics.length * WEIGHTS.TOPIC_MATCH;
    score += topicScore;
    reasons.push(`Topic matches: ${matchingTopics.join(', ')}`);
  }

  // Urgency boost for security-related rules
  if (
    intent.urgency === 'high' &&
    (rule.topics.includes('security') || rule.path.includes('security'))
  ) {
    score += WEIGHTS.URGENCY_BOOST;
    reasons.push('Urgency boost for security');
  }

  // Category-aware boosting
  if (category && CATEGORY_BOOSTS[category]) {
    const boost = CATEGORY_BOOSTS[category];
    const matchingBoostTopics = rule.topics.filter((topic) => boost.topics.includes(topic));

    if (matchingBoostTopics.length > 0) {
      score += boost.boost;
      reasons.push(`Category boost (${category}): ${matchingBoostTopics.join(', ')}`);
    }
  }

  return {
    ...rule,
    score,
    reasons,
  };
}

/**
 * Apply token budget constraint to rule selection
 */
function applyTokenBudget(rules: ScoredRule[], maxTokens: number): ScoredRule[] {
  const selected: ScoredRule[] = [];
  let totalTokens = 0;

  for (const rule of rules) {
    if (totalTokens + rule.estimatedTokens <= maxTokens) {
      selected.push(rule);
      totalTokens += rule.estimatedTokens;
    } else {
      // Budget exceeded, stop adding rules
      break;
    }
  }

  return selected;
}

/**
 * Analyze user intent from their message
 */
export function analyzeIntent(message: string): UserIntent {
  const lowerMessage = message.toLowerCase();

  // Extract topics using unified service
  const topics = extractTopicsFromText(message);

  // Extract action
  let action: UserIntent['action'] = 'general';
  if (lowerMessage.match(/\b(implement|add|create|build|write)\b/)) {
    action = 'implement';
  } else if (lowerMessage.match(/\b(fix|bug|error|issue|problem)\b/)) {
    action = 'fix';
  } else if (lowerMessage.match(/\b(refactor|cleanup|improve|optimize)\b/)) {
    action = 'refactor';
  } else if (lowerMessage.match(/\b(review|check|validate|audit)\b/)) {
    action = 'review';
  }

  // Extract urgency
  const urgency: UserIntent['urgency'] = lowerMessage.match(
    /\b(urgent|critical|asap|immediately|production)\b/
  )
    ? 'high'
    : 'normal';

  return {
    topics,
    action,
    urgency,
  };
}

/**
 * Get available rules from the repository structure
 * This builds a catalog of all available rules with metadata
 */
export function getAvailableRules(): RuleInfo[] {
  // Load rules dynamically from rules-config.json
  return loadRulesConfig();
}
