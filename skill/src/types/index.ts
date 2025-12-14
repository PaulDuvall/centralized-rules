/**
 * Type definitions for the centralized-rules skill
 *
 * NOTE: These types were defined before implementation (cs3-cs6).
 * They should be reviewed after implementation for:
 * - Unused fields that can be removed
 * - Missing fields discovered during implementation
 * - Overly complex types that can be simplified
 * - Type mismatches (e.g., Date vs string for serialization)
 */

/**
 * Project context detected from the codebase
 */
export interface ProjectContext {
  /** Primary programming language(s) */
  languages: string[];
  /** Detected framework(s) */
  frameworks: string[];
  /** Cloud provider(s) if any */
  cloudProviders: string[];
  /** Project maturity level */
  maturity: 'mvp' | 'pre-production' | 'production';
  /** Working directory analyzed */
  workingDirectory: string;
  /** Confidence score (0-1) */
  confidence: number;
}

/**
 * User intent extracted from their prompt
 */
export interface UserIntent {
  /** Topics mentioned (e.g., 'authentication', 'testing') */
  topics: string[];
  /** Action being performed (e.g., 'implement', 'fix') */
  action: 'implement' | 'fix' | 'refactor' | 'review' | 'general';
  /** Urgency level - REVIEW: Is this actually needed? Might be YAGNI */
  urgency: 'high' | 'normal';
}

/**
 * Information about a coding rule
 */
export interface RuleInfo {
  /** File path in the repository */
  path: string;
  /** Rule title */
  title: string;
  /** Rule category (base, language, framework, cloud) */
  category: 'base' | 'language' | 'framework' | 'cloud';
  /** Language this rule applies to */
  language?: string;
  /** Framework this rule applies to */
  framework?: string;
  /** Cloud provider this rule applies to */
  cloudProvider?: string;
  /** Topics covered by this rule */
  topics: string[];
  /** Maturity levels this rule applies to */
  maturity: ('mvp' | 'pre-production' | 'production')[];
  /** Estimated token count */
  estimatedTokens: number;
}

/**
 * A fetched rule with its content
 */
export interface Rule extends RuleInfo {
  /** The markdown content of the rule */
  content: string;
  /** When the rule was fetched */
  fetchedAt: Date;
}

/**
 * Parameters for rule selection
 */
export interface RuleSelectionParams {
  /** Project context */
  project: ProjectContext;
  /** User intent */
  intent: UserIntent;
  /** Maximum number of rules to select */
  maxRules: number;
  /** Maximum tokens to allocate */
  maxTokens?: number;
}

/**
 * Skill configuration from skill.json
 */
export interface SkillConfig {
  /** GitHub repository (owner/repo format) */
  rulesRepo: string;
  /** Git branch to fetch from */
  rulesBranch: string;
  /** Enable automatic rule loading */
  enableAutoLoad: boolean;
  /** Enable caching */
  cacheEnabled: boolean;
  /** Cache TTL in seconds */
  cacheTTL: number;
  /** Maximum rules per request */
  maxRules: number;
  /** Maximum tokens for rules */
  maxTokens: number;
  /** Verbose logging */
  verbose: boolean;
}

/**
 * Context provided by Claude to the skill
 */
export interface SkillContext {
  /** Configuration from skill.json */
  config: SkillConfig;
  /** User's messages in the conversation */
  messages: Message[];
  /** Current working directory */
  workingDirectory: string;
  /** Currently open files - REVIEW: Verify this is actually provided by Claude skill API */
  openFiles?: string[];
  /** Recently accessed files - REVIEW: Verify this is actually provided by Claude skill API */
  recentFiles?: string[];
}

/**
 * A message in the conversation
 */
export interface Message {
  /** Message role */
  role: 'user' | 'assistant' | 'system';
  /** Message content */
  content: string;
}

/**
 * Result returned by a hook
 */
export interface HookResult {
  /** Whether to continue with the request */
  continue: boolean;
  /** Additional system prompt to inject */
  systemPrompt?: string;
  /** Additional context to provide - REVIEW: What actually goes here? Type is too vague */
  additionalContext?: unknown;
  /** Metadata about the hook execution - REVIEW: Is this actually needed? Might be YAGNI */
  metadata?: Record<string, unknown>;
}

/**
 * Cache statistics
 * REVIEW: Do we need all these stats? Might be over-engineering for a simple cache.
 * Consider simplifying to just size if hits/misses aren't actually used.
 */
export interface CacheStats {
  /** Total number of items in cache */
  size: number;
  /** Number of cache hits */
  hits: number;
  /** Number of cache misses */
  misses: number;
  /** Hit rate (0-1) */
  hitRate: number;
}
