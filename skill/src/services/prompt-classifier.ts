/**
 * Prompt classification service for semantic category detection
 *
 * This classifier categorizes user prompts into semantic categories to enable
 * better rule matching by understanding the user's intent.
 */

/**
 * Semantic categories for prompt classification
 */
export enum PromptCategory {
  CODE_IMPLEMENTATION = 'code_implementation',
  CODE_DEBUGGING = 'code_debugging',
  CODE_REVIEW = 'code_review',
  ARCHITECTURE = 'architecture',
  DEVOPS = 'devops',
  DOCUMENTATION = 'documentation',
  LEGAL_BUSINESS = 'legal_business',
  GENERAL_QUESTION = 'general_question',
  UNCLEAR = 'unclear',
}

/**
 * Pattern definitions for high-confidence classification
 */
const PATTERNS: Record<PromptCategory, RegExp[]> = {
  [PromptCategory.LEGAL_BUSINESS]: [
    /\b(privacy policy|terms of service|GDPR|legal|contract|compliance|license|licensing|copyright|trademark)\b/i,
    /\b(SLA|service level|agreement|liability|warranty|indemnif)/i,
  ],
  [PromptCategory.CODE_DEBUGGING]: [
    /\b(error|bug|fix|debug|broken|not working|fails|failing|crash|exception)\b/i,
    /\b(stack trace|error message|throws|stack overflow)\b/i,
    /\bwhy (is|does|doesn't|isn't|won't)\b/i,
  ],
  [PromptCategory.CODE_REVIEW]: [
    /\b(review|code review|feedback on|look at this code|check this|validate this)\b/i,
    /\b(best practice|improve|optimize|refactor)\b.*\b(code|function|class)\b/i,
    /\b(how (do|to|should|can) I)\s+test\b.*\b(component|function|class|module|code)\b/i,
    /\b(test|testing)\s+(this|the|my)\s+(component|function|class|code)\b/i,
  ],
  [PromptCategory.DEVOPS]: [
    /\b(deploy|deployment|CI\/CD|pipeline|docker|kubernetes|k8s|container)\b/i,
    /\b(infrastructure|IaC|terraform|cloudformation|ansible|jenkins|github actions)\b/i,
    /\b(monitoring|logging|observability|metrics|alerts?)\b/i,
  ],
  [PromptCategory.ARCHITECTURE]: [
    /\b(architecture|design pattern|system design|scalability|microservices)\b/i,
    /\b(database schema|data model|API design|high-level)\b/i,
    /\b(distributed system|event-driven|message queue|pub\/sub)\b/i,
  ],
  [PromptCategory.DOCUMENTATION]: [
    /\b(document|documentation|README|docs|comment)\b/i,
    /\b(write|create|add)\b.*\b(document|documentation|README|guide|tutorial)\b/i,
  ],
  [PromptCategory.CODE_IMPLEMENTATION]: [
    /\b(implement|create|add|build|write|develop)\b.*\b(feature|function|class|component|endpoint)\b/i,
    /\b(new|make)\b.*\b(feature|function|class|component|endpoint|API)\b/i,
  ],
  [PromptCategory.GENERAL_QUESTION]: [
    /^(what|who|when|where|why|how)\b/i,
    /\b(explain|tell me|help me understand)\b/i,
  ],
  [PromptCategory.UNCLEAR]: [],
};

/**
 * Keyword scoring weights for fallback classification
 */
const KEYWORD_WEIGHTS: Record<PromptCategory, Record<string, number>> = {
  [PromptCategory.CODE_IMPLEMENTATION]: {
    implement: 3,
    create: 3,
    add: 2,
    build: 3,
    write: 2,
    develop: 2,
    new: 2,
    make: 2,
    feature: 2,
    function: 1,
    component: 1,
    helper: 1,
    utility: 1,
    module: 1,
  },
  [PromptCategory.CODE_DEBUGGING]: {
    error: 3,
    bug: 3,
    fix: 3,
    debug: 3,
    broken: 2,
    issue: 2,
    problem: 2,
    crash: 3,
    exception: 2,
    fails: 2,
    wrong: 2,
    incorrect: 2,
    'not working': 3,
  },
  [PromptCategory.CODE_REVIEW]: {
    review: 3,
    feedback: 2,
    check: 2,
    validate: 2,
    improve: 2,
    optimize: 2,
    refactor: 2,
    'best practice': 3,
  },
  [PromptCategory.ARCHITECTURE]: {
    architecture: 3,
    design: 2,
    pattern: 2,
    scalability: 3,
    system: 1,
    microservices: 3,
    distributed: 2,
    database: 1,
  },
  [PromptCategory.DEVOPS]: {
    deploy: 3,
    deployment: 3,
    'ci/cd': 3,
    pipeline: 2,
    docker: 3,
    kubernetes: 3,
    container: 2,
    infrastructure: 2,
  },
  [PromptCategory.DOCUMENTATION]: {
    document: 3,
    readme: 3,
    docs: 2,
    comment: 2,
    explain: 2,
    describe: 2,
    guide: 2,
    tutorial: 2,
  },
  [PromptCategory.LEGAL_BUSINESS]: {
    legal: 3,
    privacy: 3,
    gdpr: 3,
    compliance: 3,
    license: 2,
    contract: 3,
    terms: 2,
    policy: 2,
  },
  [PromptCategory.GENERAL_QUESTION]: {
    what: 2,
    why: 2,
    how: 2,
    explain: 2,
    tell: 1,
    understand: 1,
    help: 1,
    describe: 1,
  },
  [PromptCategory.UNCLEAR]: {},
};

/**
 * Classify a prompt using pattern matching for high-confidence cases
 *
 * @param text - The prompt text to classify
 * @returns The category if pattern matches, undefined otherwise
 */
function classifyByPatterns(text: string): PromptCategory | undefined {
  // Check each category's patterns in priority order
  const priorityOrder: PromptCategory[] = [
    PromptCategory.LEGAL_BUSINESS, // Highest priority - very distinctive
    PromptCategory.CODE_DEBUGGING, // High priority - clear signals
    PromptCategory.DEVOPS, // Medium-high - specific terms
    PromptCategory.ARCHITECTURE, // Medium - specific domain
    PromptCategory.CODE_REVIEW, // Medium - can overlap with debugging
    PromptCategory.CODE_IMPLEMENTATION, // Medium-low - common words
    PromptCategory.DOCUMENTATION, // Low - very common words
    PromptCategory.GENERAL_QUESTION, // Lowest - catch-all
  ];

  for (const category of priorityOrder) {
    const patterns = PATTERNS[category];
    for (const pattern of patterns) {
      if (pattern.test(text)) {
        return category;
      }
    }
  }

  return undefined;
}

/**
 * Classify a prompt using keyword scoring as a fallback
 *
 * @param text - The prompt text to classify
 * @returns The category with the highest score, or UNCLEAR if no clear winner
 */
function classifyByKeywordScoring(text: string): PromptCategory {
  const lowerText = text.toLowerCase();
  const scores: Record<PromptCategory, number> = {
    [PromptCategory.CODE_IMPLEMENTATION]: 0,
    [PromptCategory.CODE_DEBUGGING]: 0,
    [PromptCategory.CODE_REVIEW]: 0,
    [PromptCategory.ARCHITECTURE]: 0,
    [PromptCategory.DEVOPS]: 0,
    [PromptCategory.DOCUMENTATION]: 0,
    [PromptCategory.LEGAL_BUSINESS]: 0,
    [PromptCategory.GENERAL_QUESTION]: 0,
    [PromptCategory.UNCLEAR]: 0,
  };

  // Score each category based on keyword presence
  for (const [category, keywords] of Object.entries(KEYWORD_WEIGHTS)) {
    for (const [keyword, weight] of Object.entries(keywords)) {
      if (lowerText.includes(keyword)) {
        scores[category as PromptCategory] += weight;
      }
    }
  }

  // Find the category with the highest score
  let maxScore = 0;
  let maxCategory = PromptCategory.UNCLEAR;
  let tieCount = 0;

  for (const [category, score] of Object.entries(scores)) {
    if (score > maxScore) {
      maxScore = score;
      maxCategory = category as PromptCategory;
      tieCount = 1;
    } else if (score === maxScore && score > 0) {
      tieCount++;
    }
  }

  // If there's a tie or no clear winner, return UNCLEAR
  if (tieCount > 1 || maxScore < 2) {
    return PromptCategory.UNCLEAR;
  }

  return maxCategory;
}

/**
 * Classify a prompt into a semantic category
 *
 * This is the main entry point for classification. It first attempts pattern matching
 * for high-confidence cases, then falls back to keyword scoring.
 *
 * @param text - The prompt text to classify
 * @returns The detected category
 */
export function classifyPrompt(text: string): PromptCategory {
  if (!text || text.trim().length === 0) {
    return PromptCategory.UNCLEAR;
  }

  // Try pattern matching first (high confidence)
  const patternMatch = classifyByPatterns(text);
  if (patternMatch) {
    return patternMatch;
  }

  // Fall back to keyword scoring
  return classifyByKeywordScoring(text);
}
