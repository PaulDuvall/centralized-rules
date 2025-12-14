# Design Document

## Overview

The Centralized Rules Claude Skill provides intelligent, context-aware coding standards that automatically load based on project context. The skill detects project languages, frameworks, cloud providers, and maturity levels, then uses a sophisticated scoring algorithm to select and inject only the most relevant rules into Claude's context window.

The system implements a two-phase progressive disclosure approach: first detecting project context to filter available rules, then analyzing user intent to select the most relevant subset for each interaction. This approach achieves 60-80% token savings while maintaining high relevance.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Claude User   │───▶│  beforeResponse  │───▶│  Rule Selection │
│                 │    │      Hook        │    │   Algorithm     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Context Detection│    │ GitHub Fetcher  │
                       │      Tool        │    │   with Cache    │
                       └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │ Project Context  │    │   Rule Content  │
                       │   (Languages,    │    │   (Markdown)    │
                       │  Frameworks,     │    │                 │
                       │   Maturity)      │    │                 │
                       └──────────────────┘    └─────────────────┘
```

### Component Interaction Flow

1. **User Message** → Claude receives user input
2. **beforeResponse Hook** → Executes before Claude generates response
3. **Context Detection** → Analyzes project directory for languages/frameworks
4. **Intent Analysis** → Extracts topics, actions, urgency from user message
5. **Rule Selection** → Scores and ranks rules based on context and intent
6. **Rule Fetching** → Retrieves selected rules from GitHub (with caching)
7. **Rule Injection** → Formats and adds rules to Claude's system prompt
8. **Response Generation** → Claude responds with rules applied

## Components and Interfaces

### Context Detection Tool

**Purpose**: Analyze project directory to detect languages, frameworks, cloud providers, and maturity level.

**Interface**:
```typescript
interface ContextDetectionTool {
  detectContext(directory: string): Promise<ProjectContext>;
  detectLanguages(directory: string): Promise<string[]>;
  detectFrameworks(directory: string, languages: string[]): Promise<string[]>;
  detectCloudProviders(directory: string): Promise<string[]>;
  detectMaturity(directory: string): Promise<MaturityLevel>;
}
```

**Key Algorithms**:
- **Language Detection**: File pattern matching (*.py, package.json, go.mod, etc.)
- **Framework Detection**: Dependency analysis (package.json, requirements.txt, pom.xml)
- **Cloud Detection**: Config file analysis (vercel.json, .aws/, terraform/)
- **Maturity Assessment**: Version analysis + infrastructure indicators (CI/CD, Docker, monitoring)

### Rule Selection Algorithm

**Purpose**: Score and rank rules based on project context and user intent.

**Interface**:
```typescript
interface RuleSelectionAlgorithm {
  selectRules(availableRules: RuleInfo[], params: RuleSelectionParams): RuleInfo[];
  scoreRule(rule: RuleInfo, context: ProjectContext, intent: UserIntent): ScoredRule;
  analyzeIntent(message: string): UserIntent;
  applyTokenBudget(rules: ScoredRule[], maxTokens: number): ScoredRule[];
}
```

**Scoring Weights**:
- Language Match: 100 points
- Framework Match: 100 points  
- Cloud Provider Match: 75 points
- Maturity Level Match: 50 points
- Topic Relevance: 30 points per topic
- Base Rule Bonus: 20 points
- Security Urgency Boost: 25 points

### GitHub Fetcher with Caching

**Purpose**: Efficiently fetch rule content from GitHub repository with intelligent caching.

**Interface**:
```typescript
interface GitHubFetcher {
  fetchRule(rulePath: string, config: SkillConfig): Promise<Rule | null>;
  fetchRules(ruleInfos: RuleInfo[], config: SkillConfig): Promise<Rule[]>;
}

interface RulesCache {
  get(path: string): Rule | undefined;
  set(path: string, rule: Rule): void;
  has(path: string): boolean;
  clear(): void;
  getStats(): CacheStats;
}
```

**Caching Strategy**:
- **TTL**: 1 hour default (configurable)
- **Eviction**: LRU (Least Recently Used)
- **Concurrency**: Max 5 parallel requests to avoid rate limiting
- **Error Handling**: Graceful degradation with cached fallbacks

### beforeResponse Hook

**Purpose**: Orchestrate the entire workflow before Claude generates a response.

**Interface**:
```typescript
interface BeforeResponseHook {
  execute(context: SkillContext): Promise<HookResult>;
}
```

**Execution Flow**:
1. Check if auto-load is enabled
2. Extract user's last message
3. Detect project context (cached for session)
4. Analyze user intent from message
5. Select relevant rules using scoring algorithm
6. Fetch rules from GitHub (with caching)
7. Format rules as markdown
8. Return system prompt injection

## Data Models

### Core Data Types

```typescript
interface ProjectContext {
  languages: string[];           // ['python', 'typescript']
  frameworks: string[];          // ['fastapi', 'react']
  cloudProviders: string[];      // ['aws', 'vercel']
  maturity: MaturityLevel;       // 'mvp' | 'pre-production' | 'production'
  workingDirectory: string;      // '/path/to/project'
  confidence: number;            // 0.0 - 1.0
}

interface UserIntent {
  topics: string[];              // ['authentication', 'testing']
  action: ActionType;            // 'implement' | 'fix' | 'refactor' | 'review' | 'general'
  urgency: UrgencyLevel;         // 'high' | 'normal'
}

interface RuleInfo {
  path: string;                  // 'languages/python/coding-standards.md'
  title: string;                 // 'Python Coding Standards'
  category: RuleCategory;        // 'base' | 'language' | 'framework' | 'cloud'
  language?: string;             // 'python'
  framework?: string;            // 'fastapi'
  cloudProvider?: string;        // 'aws'
  topics: string[];              // ['standards', 'style', 'type-hints']
  maturity: MaturityLevel[];     // ['mvp', 'pre-production', 'production']
  estimatedTokens: number;       // 1200
}

interface Rule extends RuleInfo {
  content: string;               // Markdown content
  fetchedAt: number;             // Unix timestamp
}
```

### Configuration Schema

```typescript
interface SkillConfig {
  rulesRepo: string;             // 'paulduvall/centralized-rules'
  rulesBranch: string;           // 'main'
  enableAutoLoad: boolean;       // true
  cacheEnabled: boolean;         // true
  cacheTTL: number;              // 3600 (seconds)
  maxRules: number;              // 5
  maxTokens: number;             // 5000
  verbose: boolean;              // false
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Language Detection Accuracy
*For any* project directory with known language indicators, the Context Detection Tool should identify languages with at least 95% accuracy across a representative test suite
**Validates: Requirements 1.1**

### Property 2: Multi-Language Detection Completeness  
*For any* project containing multiple programming languages, the Context Detection Tool should detect and return all present languages without omission
**Validates: Requirements 1.2**

### Property 3: Framework Detection Accuracy
*For any* project with framework dependencies in standard locations, the Context Detection Tool should identify frameworks with at least 90% accuracy
**Validates: Requirements 1.3**

### Property 4: Cloud Provider Detection Consistency
*For any* project with cloud provider configuration files or dependencies, the Context Detection Tool should reliably identify the cloud providers
**Validates: Requirements 1.4**

### Property 5: Maturity Classification Determinism
*For any* project with consistent maturity indicators, the Context Detection Tool should classify the same project to the same maturity level across multiple runs
**Validates: Requirements 1.5**

### Property 6: Hook Execution Performance
*For any* user message to Claude, the beforeResponse Hook should complete execution within 3 seconds
**Validates: Requirements 2.1**

### Property 7: Intent Analysis Completeness
*For any* user message containing recognizable topics, actions, or urgency indicators, the Rule Selection Algorithm should extract the relevant intent components
**Validates: Requirements 2.2**

### Property 8: Scoring Algorithm Consistency
*For any* combination of project context and available rules, the Rule Selection Algorithm should apply scoring weights consistently according to the defined formula
**Validates: Requirements 2.3**

### Property 9: Token Budget Compliance
*For any* set of selected rules, the Rule Selection Algorithm should ensure the total estimated tokens do not exceed the configured maximum
**Validates: Requirements 2.4**

### Property 10: Rule Formatting Consistency
*For any* selected rules, the beforeResponse Hook should format all rules as valid markdown with consistent structure
**Validates: Requirements 2.5**

### Property 11: Cache-First Behavior
*For any* rule request, the GitHub Fetcher should check the cache before making API calls
**Validates: Requirements 3.1**

### Property 12: Cache Hit Performance
*For any* cached rule, the GitHub Fetcher should return the rule in under 10 milliseconds
**Validates: Requirements 3.2**

### Property 13: GitHub Fetch Performance
*For any* uncached rule, the GitHub Fetcher should retrieve and return the rule within 2 seconds under normal network conditions
**Validates: Requirements 3.3**

### Property 14: Concurrency Control
*For any* batch of rule requests, the GitHub Fetcher should limit concurrent API calls to 5 or fewer to avoid rate limiting
**Validates: Requirements 3.4**

### Property 15: Cache Management Behavior
*For any* cached rule, the Cache System should respect TTL expiration and LRU eviction policies
**Validates: Requirements 3.5**

### Property 16: Integration Test Workflow Validation
*For any* mocked GitHub API scenario, the integration tests should validate the complete workflow from context detection through rule injection
**Validates: Requirements 4.2**

### Property 17: Performance Benchmark Consistency
*For any* performance benchmark execution, the hook execution time should consistently remain under 3 seconds
**Validates: Requirements 4.4**

### Property 18: CI Automation Reliability
*For any* commit to the repository, the CI pipeline should automatically execute all tests without manual intervention
**Validates: Requirements 4.5**

### Property 19: Installation Performance
*For any* clean environment, the installation script should complete repository cloning and skill building within 2 minutes
**Validates: Requirements 5.1**

### Property 20: Installation Automation
*For any* installation execution, the system should automatically handle npm install and TypeScript compilation without manual steps
**Validates: Requirements 5.2**

### Property 21: Update Mechanism Reliability
*For any* update request, the system should successfully execute git pull and rebuild workflow
**Validates: Requirements 5.4**

## Error Handling

### Network Error Handling
- **GitHub API Failures**: Retry with exponential backoff (1s, 2s, 4s)
- **Rate Limiting**: Use cached versions when available, show rate limit status
- **Timeout Handling**: 5-second timeout per request, graceful degradation
- **Connectivity Issues**: Offline mode with cached rules only

### Validation Error Handling
- **Invalid Repository Format**: Clear error message with correct format example
- **Missing Configuration**: Use sensible defaults, warn about missing config
- **Malformed Rules**: Skip invalid rules, log warnings, continue with valid rules
- **Cache Corruption**: Clear cache and refetch, log cache reset event

### Performance Error Handling
- **Memory Pressure**: Implement cache size limits, LRU eviction
- **CPU Intensive Operations**: Use worker threads for heavy processing
- **Hook Timeout**: Cancel long-running operations, return partial results
- **Concurrent Request Limits**: Queue excess requests, process in batches

## Testing Strategy

### Unit Testing Approach
- **Component Isolation**: Test each component independently with mocks
- **Edge Case Coverage**: Test boundary conditions, empty inputs, malformed data
- **Error Scenario Testing**: Verify proper error handling and recovery
- **Performance Testing**: Validate timing requirements for critical paths
- **Configuration Testing**: Test all configuration combinations and defaults

### Property-Based Testing Requirements
- **Framework**: Use fast-check for TypeScript property-based testing
- **Test Iterations**: Minimum 100 iterations per property test
- **Generator Strategy**: Create smart generators that produce realistic project structures
- **Shrinking**: Leverage fast-check's shrinking to find minimal failing cases
- **Property Tagging**: Each property test must reference its corresponding design property

### Integration Testing Strategy
- **Mocked GitHub API**: Test complete workflows with controlled API responses
- **Real Project Scenarios**: Test with actual project structures (Python+FastAPI, TypeScript+React, Go+Gin)
- **Cache Behavior Testing**: Verify cache hit/miss scenarios and performance
- **Error Recovery Testing**: Test graceful degradation under various failure conditions
- **Configuration Testing**: Test different skill configurations and overrides

### End-to-End Testing Approach
- **Real GitHub Integration**: Test with actual centralized-rules repository
- **Performance Validation**: Measure actual execution times in realistic scenarios
- **User Workflow Testing**: Simulate complete user interactions from message to response
- **Cross-Platform Testing**: Validate on different operating systems and Node.js versions
- **Load Testing**: Test behavior under concurrent requests and high cache pressure