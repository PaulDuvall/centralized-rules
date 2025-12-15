/**
 * Smart rule selection algorithm
 * Scores and ranks rules based on project context and user intent
 */

import type { RuleInfo, RuleSelectionParams, UserIntent } from '../types';
import { loadRulesConfig } from '../config/rule-config-loader';
import { extractTopicsFromText } from '../services/metadata-extractor';

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
  ALWAYS_LOAD: 200,
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
 */
export function selectRules(availableRules: RuleInfo[], params: RuleSelectionParams): RuleInfo[] {
  // Score all rules
  const scoredRules = availableRules.map((rule) => scoreRule(rule, params));

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
 * Score a single rule based on context and intent
 */
function scoreRule(rule: RuleInfo, params: RuleSelectionParams): ScoredRule {
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
