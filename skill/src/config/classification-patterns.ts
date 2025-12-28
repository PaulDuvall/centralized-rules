/**
 * Comprehensive pattern definitions for prompt classification
 *
 * This file contains pattern definitions and weights for classifying user prompts
 * into semantic categories. Patterns are organized by confidence level and category.
 */

/**
 * Pattern indicator with weight and signal description
 */
export interface PatternIndicator {
  /** Regular expression pattern to match */
  pattern: RegExp;
  /** Weight/score for this indicator */
  weight: number;
  /** Human-readable description of what this pattern indicates */
  signal: string;
}

/**
 * Definite non-code patterns: Legal and business related
 *
 * These patterns indicate business/legal content with high confidence,
 * even if technical terms are present.
 */
export const LEGAL_BUSINESS_PATTERNS = [
  // Legal documents
  /\b(operating agreement|shareholder agreement|articles of incorporation)\b/i,
  /\b(terms of service|privacy policy|end user license agreement|EULA)\b/i,
  /\b(non-disclosure agreement|NDA|confidentiality agreement)\b/i,
  /\b(service level agreement)(?!.*\b(api|code|implement|endpoint|monitoring)\b)/i,
  /\bSLA\b(?!.*\b(api|code|implement|endpoint|monitoring|metric)\b)/i,

  // HR and employment
  /\b(employee handbook|hr policy|vacation policy|pto policy)\b/i,
  /\b(employment contract|offer letter|severance agreement)\b/i,
  /\b(performance review|compensation|salary|benefits package)\b/i,

  // Business operations
  /\b(business plan|financial projection|revenue model)\b/i,
  /\b(financial (approval|decision|threshold))(?!.*(api|endpoint|function))/i,
  /\b(budget allocation|expense policy|procurement process)\b/i,

  // Compliance and regulations
  /\b(GDPR compliance|CCPA|HIPAA|SOC 2|PCI DSS)\b(?!.*(implement|code|api))/i,
  /\b(regulatory compliance|audit requirements|legal opinion)\b/i,
  /\b(trademark|copyright|patent|intellectual property)\b(?!.*(api|code))/i,

  // Corporate governance
  /\b(board resolution|corporate bylaws|governance policy)\b/i,
  /\b(risk assessment|due diligence)(?!.*(security|code|api))/i,
];

/**
 * Code implementation patterns
 *
 * Strong indicators of code implementation tasks
 */
export const CODE_IMPLEMENTATION_PATTERNS = [
  // Direct implementation requests
  /\b(implement|create|add|build|write)\s+.*?\b(function|class|component|module|endpoint|api|service|feature|handler|middleware)\b/i,
  /\b(develop)\s+.*?\b(feature|functionality|capability|service|component)\b/i,
  /\b(scaffold|bootstrap|generate)\s+(a\s+)?(project|app|service|module)\b/i,

  // Specific implementation contexts
  /\b(add|implement)\s+.*\s+(to|in|for)\s+the\s+(codebase|application|project)\b/i,
  /\b(create|build)\s+(rest|graphql|grpc)\s+api\b/i,
  /\b(setup|configure|initialize)\s+(database|orm|migration|schema)\b/i,

  // File-specific implementation
  /\b(implement|add|create)\s+.*\.(js|ts|py|rs|go|java|rb|php|cpp|c|h)\b/i,
];

/**
 * Code debugging patterns
 *
 * Strong indicators of debugging/troubleshooting tasks
 */
export const CODE_DEBUGGING_PATTERNS = [
  // Error-specific
  /\b(fix|debug|resolve|solve)\s+(this\s+)?(error|bug|issue|problem)\b/i,
  /\b(error|exception|crash|failure)\s+in\s+\w+\.(js|ts|py|rs|go|java|rb|php)\b/i,
  /\b(stack trace|error message|exception thrown)\b/i,
  /\b(null pointer|segfault|memory leak|race condition)\b/i,

  // Behavioral issues
  /\b(not working|doesn'?t work|broken|failing|fails|not work)\b/i,
  /\b(why (is|does|doesn't|isn't|won't))\s+.*\s+(work|run|execute|compile|build|crash|fail)\b/i,
  /\bwhy does (it|this|the).*\b(crash|fail|break|error)\b/i,
  /\b(stops|hangs|freezes|crashes)\s+(when|after|during)\b/i,
  /\b(app|application|code|function|feature)\s+(doesn'?t|does not|isn'?t|is not)\s+(work|run|load)\b/i,

  // Test failures
  /\b(test|tests|unit test)\s+(fail|failing|failed|broken)\b/i,
  /\b(ci|build)\s+(fail|failing|failed|broken|red)\b/i,
];

/**
 * Code review patterns
 *
 * Indicators of code review and quality assessment requests
 */
export const CODE_REVIEW_PATTERNS = [
  /\b(review|check|validate|assess)\s+(this|the|my)\s+(code|function|class|implementation|solution)\b/i,
  /\b(code review|pull request review|pr review)\b/i,
  /\b(feedback on|opinion on|thoughts on)\s+(this|the|my)\s+(code|implementation|function|class)\b/i,
  /\b(is this|this)\s+.*\b(best practice|good code|clean code|correct|right approach)\b/i,
  /\b(improve|optimize|refactor)\s+(this|the)\s+(code|function|class|implementation)\b/i,
  /\b(how|what)\b.*\b(improve|optimize|refactor|better)\b.*\b(code|function|implementation)\b/i,
  /\b(how (do|to|should|can) I)\s+test\b.*\b(component|function|class|module|code)\b/i,
  /\b(test|testing)\s+(this|the|my)\s+(component|function|class|code)\b/i,
];

/**
 * Architecture and design patterns
 *
 * Indicators of high-level design and architecture tasks
 */
export const ARCHITECTURE_PATTERNS = [
  // Architecture styles
  /\b(microservices|monolith|serverless|event-driven|layered|hexagonal)\s+(architecture|design|pattern)\b/i,
  /\b(explain|describe|what is)\s+(microservices|event-driven|serverless|monolith)\s+architecture\b/i,
  /\b(design|architect)\s+(a|the)\s+(system|application|service|platform)\b/i,
  /\b(distributed system|scalability|horizontal scaling|vertical scaling|high availability)\b/i,
  /\b(system design|system architecture)\b/i,

  // Data architecture
  /\b(database (design|schema|model)|schema design|data model|entity relationship)\b/i,
  /\b(what|which)\s+.*\b(database|schema|data model)\b/i,
  /\b(normalized|denormalized|star schema|snowflake schema)\b/i,

  // API design
  /\b(api design|api architecture|rest design|graphql schema design)\b/i,
  /\b(how to|how)\s+.*\bdesign\b.*\b(api|endpoint|service)\b/i,
  /\b(design pattern|architectural pattern)\s+(for|to|like)\b/i,

  // System design
  /\b(high-level design|technical design)\b/i,
  /\b(message queue|pub\/sub|event sourcing|cqrs)\b/i,
];

/**
 * DevOps and infrastructure patterns
 *
 * Indicators of deployment, operations, and infrastructure tasks
 */
export const DEVOPS_PATTERNS = [
  // Containerization
  /\b(docker|dockerfile|container|containerize|containerization)\b/i,
  /\b(kubernetes|k8s|helm|kubectl|pod|deployment|service)\b/i,

  // CI/CD
  /\b(ci\/cd|continuous integration|continuous deployment|continuous delivery)\b/i,
  /\b(pipeline|jenkins|github actions|gitlab ci|circleci|travis)\b/i,
  /\b(deploy|deployment|release|rollout)\s+(to|on|via)\b/i,

  // Infrastructure
  /\b(infrastructure as code|iac|terraform|cloudformation|pulumi)\b/i,
  /\b(provision|provisioning|infrastructure|cloud resources)\b/i,

  // Monitoring and operations
  /\b(monitoring|observability|metrics|logging|tracing)\b/i,
  /\b(prometheus|grafana|datadog|new relic|cloudwatch)\b/i,
  /\b(alert|alerting|notification|incident|on-call)\b/i,

  // Configuration management
  /\b(ansible|puppet|chef|salt|configuration management)\b/i,
];

/**
 * Documentation patterns
 *
 * Indicators of documentation tasks
 */
export const DOCUMENTATION_PATTERNS = [
  // Direct documentation requests
  /\b(write|create|update|generate|make|add)\s+(a\s+|the\s+)?(documentation|docs|readme|guide|tutorial)\b/i,
  /\b(document|documenting)\s+(this|the)\s+(api|function|class|module|code)\b/i,

  // Specific documentation types
  /\b(api documentation|api docs|swagger|openapi)\b/i,
  /\b(generate|create|write)\s+(api|swagger|openapi)\s+docs?\b/i,
  /\b(user guide|developer guide|onboarding guide|runbook)\b/i,
  /\b(technical specification|design document|architecture document)\b/i,

  // Comment-related
  /\b(add|write|update)\s+(comments|docstrings|jsdoc|javadoc)\b/i,
];

/**
 * General question patterns
 *
 * Indicators of informational/learning questions
 */
export const GENERAL_QUESTION_PATTERNS = [
  // Question starters
  /^(what|who|when|where|why|how)\s+(is|are|does|do|can|would|should)\b/i,
  /\b(explain|describe|tell me about|help me understand)\b/i,
  /\b(what's the difference between|how does|how do)\b/i,

  // Learning-focused
  /\b(learn|learning|understand|understanding|concept|tutorial)\b/i,
  /\b(best way to|recommended way to|how should I)\b/i,
];

/**
 * Code indicators with weights
 *
 * Patterns that suggest code-related content with associated confidence weights
 */
export const CODE_INDICATORS: PatternIndicator[] = [
  // File references (strong signal)
  {
    pattern: /\w+\.(js|ts|jsx|tsx|py|rs|go|java|rb|php|cpp|c|h|cs|swift|kt)\b/i,
    weight: 30,
    signal: 'file extension reference',
  },

  // Code constructs (strong signal)
  {
    pattern: /\b(function|class|method|interface|type|enum|struct)\b/i,
    weight: 25,
    signal: 'code construct keywords',
  },

  // Technical terms (medium-strong signal)
  {
    pattern: /\b(variable|constant|parameter|argument|return|async|await|promise)\b/i,
    weight: 20,
    signal: 'programming concepts',
  },

  // Code syntax elements (medium signal)
  {
    pattern: /[{}[\]();].*[{}[\]();]/,
    weight: 15,
    signal: 'code syntax characters',
  },

  // Framework/library mentions (medium signal)
  {
    pattern: /\b(react|vue|angular|express|django|flask|rails|spring|laravel)\b/i,
    weight: 20,
    signal: 'framework/library names',
  },

  // Development tools (medium signal)
  {
    pattern: /\b(git|npm|yarn|pip|cargo|maven|gradle|webpack|vite)\b/i,
    weight: 15,
    signal: 'development tools',
  },

  // Code repositories (medium signal)
  {
    pattern: /\b(github|gitlab|bitbucket|repository|repo|commit|pull request|pr)\b/i,
    weight: 15,
    signal: 'version control references',
  },

  // Programming language names (low-medium signal)
  {
    pattern:
      /\b(javascript|typescript|python|rust|go|golang|java|ruby|php|c\+\+|csharp|swift|kotlin)\b/i,
    weight: 10,
    signal: 'programming language names',
  },

  // Technical file paths (low-medium signal)
  {
    pattern: /\/(src|lib|app|components|services|utils|tests?)\//i,
    weight: 12,
    signal: 'common source code paths',
  },

  // Package/module references (low signal)
  {
    pattern: /\b(import|require|from|package|module|library)\b/i,
    weight: 8,
    signal: 'module system keywords',
  },

  // API and endpoint references (medium signal)
  {
    pattern: /\b(api|endpoint|rest|graphql|http|request|response)\b/i,
    weight: 18,
    signal: 'API and web service terms',
  },
];

/**
 * Non-code indicators with weights
 *
 * Patterns that suggest non-code business/operational content
 */
export const NON_CODE_INDICATORS: PatternIndicator[] = [
  // Legal terms (very strong signal)
  {
    pattern: /\b(contract|agreement|liability|indemnification|warranty|covenant)\b/i,
    weight: 35,
    signal: 'legal terminology',
  },

  // Business operations (strong signal)
  {
    pattern:
      /\b(revenue|profit|loss|budget|expense|invoice|payment|billing)\b(?!.*(api|endpoint))/i,
    weight: 30,
    signal: 'financial/business terms',
  },

  // HR and personnel (strong signal)
  {
    pattern:
      /\b(employee|staff|hiring|recruitment|onboarding|termination|resignation)\b(?!.*(user|api))/i,
    weight: 30,
    signal: 'HR terminology',
  },

  // Compliance and regulations (strong signal)
  {
    pattern: /\b(compliance|regulation|audit|certification|accreditation)\b/i,
    weight: 28,
    signal: 'compliance terminology',
  },

  // Corporate structure (medium-strong signal)
  {
    pattern: /\b(board of directors|shareholder|stakeholder|executive|c-level)\b/i,
    weight: 25,
    signal: 'corporate structure',
  },

  // Marketing and sales (medium signal)
  {
    pattern: /\b(marketing campaign|sales funnel|lead generation|customer acquisition)\b/i,
    weight: 20,
    signal: 'marketing/sales terms',
  },

  // Office document formats (medium signal)
  {
    pattern: /\.(pdf|docx?|xlsx?|pptx?)\b/i,
    weight: 20,
    signal: 'office document formats',
  },

  // Business processes (medium signal)
  {
    pattern:
      /\b(workflow|approval process|sign-off|business process|procedure)\b(?!.*(automation|code))/i,
    weight: 18,
    signal: 'business process terms',
  },
];

/**
 * Pattern collections organized by category
 */
export const CATEGORY_PATTERNS = {
  legalBusiness: LEGAL_BUSINESS_PATTERNS,
  codeImplementation: CODE_IMPLEMENTATION_PATTERNS,
  codeDebugging: CODE_DEBUGGING_PATTERNS,
  codeReview: CODE_REVIEW_PATTERNS,
  architecture: ARCHITECTURE_PATTERNS,
  devops: DEVOPS_PATTERNS,
  documentation: DOCUMENTATION_PATTERNS,
  generalQuestion: GENERAL_QUESTION_PATTERNS,
} as const;

/**
 * All pattern indicators for scoring
 */
export const PATTERN_INDICATORS = {
  code: CODE_INDICATORS,
  nonCode: NON_CODE_INDICATORS,
} as const;
