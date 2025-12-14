/**
 * Metadata extraction service
 * Provides unified keyword matching and topic extraction functionality
 */

/**
 * Topic keyword definitions
 */
const TOPIC_KEYWORDS: Record<string, string[]> = {
  authentication: ['auth', 'login', 'signup', 'jwt', 'oauth', 'session'],
  testing: ['test', 'pytest', 'jest', 'vitest', 'unittest', 'spec'],
  security: ['security', 'secure', 'vulnerability', 'xss', 'sql injection', 'csrf'],
  performance: ['performance', 'slow', 'optimize', 'speed', 'latency', 'cache'],
  database: ['database', 'db', 'sql', 'postgres', 'mysql', 'mongodb', 'query'],
  api: ['api', 'endpoint', 'rest', 'graphql', 'route'],
  deployment: ['deploy', 'deployment', 'ci/cd', 'docker', 'kubernetes'],
  monitoring: ['monitor', 'logging', 'observability', 'metrics', 'tracing'],
  refactoring: ['refactor', 'cleanup', 'reorganize', 'restructure'],
};

/**
 * Extract topics from text using keyword matching
 */
export function extractTopicsFromText(text: string): string[] {
  const topics: string[] = [];
  const lowerText = text.toLowerCase();

  for (const [topic, keywords] of Object.entries(TOPIC_KEYWORDS)) {
    if (keywords.some(keyword => lowerText.includes(keyword))) {
      topics.push(topic);
    }
  }

  return topics;
}

/**
 * Extract topics from both path and content
 */
export function extractTopicsFromPathAndContent(content: string, path: string): string[] {
  const topics: Set<string> = new Set();

  // Extract from path keywords
  const pathTopics = extractTopicsFromText(path);
  pathTopics.forEach(topic => topics.add(topic));

  // Extract from content headings
  const headings = content.match(/^##\s+(.+)$/gm) || [];
  for (const heading of headings) {
    const headingTopics = extractTopicsFromText(heading);
    headingTopics.forEach(topic => topics.add(topic));
  }

  // Also check full content for additional topics (limited to avoid over-matching)
  const contentTopics = extractTopicsFromText(content);
  contentTopics.forEach(topic => topics.add(topic));

  return Array.from(topics);
}

/**
 * Check if text matches any of the given keywords
 */
export function matchesKeywords(text: string, keywords: string[]): boolean {
  const lowerText = text.toLowerCase();
  return keywords.some(keyword => lowerText.includes(keyword));
}

/**
 * Extract specific patterns from text using regex
 */
export function extractPattern(text: string, pattern: RegExp): string | null {
  const match = text.match(pattern);
  return match && match[1] ? match[1] : null;
}

/**
 * Extract all matches of a pattern from text
 */
export function extractAllPatterns(text: string, pattern: RegExp): string[] {
  const matches = text.match(pattern);
  return matches || [];
}
