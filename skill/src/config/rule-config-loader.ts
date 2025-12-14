/**
 * Rule configuration loader
 * Loads rule definitions from rules-config.json instead of hardcoding them
 */

import * as fs from 'fs';
import * as path from 'path';
import type { RuleInfo } from '../types';

/**
 * Structure of rules-config.json
 */
interface RulesConfig {
  languages?: Record<string, LanguageConfig>;
  frameworks?: Record<string, FrameworkConfig>;
  cloud?: Record<string, CloudConfig>;
  base?: BaseRuleConfig[];
}

interface LanguageConfig {
  display_name: string;
  file_patterns: string[];
  test_patterns: string[];
  rules: RuleDefinition[];
}

interface FrameworkConfig {
  display_name: string;
  language: string;
  dependencies: string[];
  rules: RuleDefinition[];
}

interface CloudConfig {
  display_name: string;
  rules: RuleDefinition[];
}

interface BaseRuleConfig {
  name: string;
  file: string;
  when: string;
  topics?: string[];
  maturity?: string[];
}

interface RuleDefinition {
  name: string;
  file: string;
  when: string;
  topics?: string[];
  maturity?: string[];
}

/**
 * Cache for loaded rules to avoid repeated file reads
 */
let cachedRules: RuleInfo[] | null = null;

/**
 * Load rules from rules-config.json
 */
export function loadRulesConfig(configPath?: string): RuleInfo[] {
  // Return cached rules if available
  if (cachedRules) {
    return cachedRules;
  }

  // Determine config file path
  const configFilePath = configPath || path.join(__dirname, '../../../rules-config.json');

  // Read and parse config file
  let config: RulesConfig;
  try {
    const configContent = fs.readFileSync(configFilePath, 'utf-8');
    config = JSON.parse(configContent);
  } catch (error) {
    console.error('[rule-config-loader] Failed to load rules-config.json:', error);
    // Return empty array if config can't be loaded
    return [];
  }

  const rules: RuleInfo[] = [];

  // Load base rules
  if (config.base) {
    for (const baseRule of config.base) {
      rules.push({
        path: baseRule.file,
        title: baseRule.name,
        category: 'base',
        topics: baseRule.topics || extractTopicsFromName(baseRule.name),
        maturity: parseMaturity(baseRule.maturity),
        estimatedTokens: estimateTokensFromPath(baseRule.file),
      });
    }
  }

  // Load language rules
  if (config.languages) {
    for (const [langKey, langConfig] of Object.entries(config.languages)) {
      for (const rule of langConfig.rules) {
        rules.push({
          path: rule.file,
          title: rule.name,
          category: 'language',
          language: langKey,
          topics: rule.topics || extractTopicsFromName(rule.name),
          maturity: parseMaturity(rule.maturity),
          estimatedTokens: estimateTokensFromPath(rule.file),
        });
      }
    }
  }

  // Load framework rules
  if (config.frameworks) {
    for (const [frameworkKey, frameworkConfig] of Object.entries(config.frameworks)) {
      for (const rule of frameworkConfig.rules) {
        rules.push({
          path: rule.file,
          title: rule.name,
          category: 'framework',
          language: frameworkConfig.language,
          framework: frameworkKey,
          topics: rule.topics || extractTopicsFromName(rule.name),
          maturity: parseMaturity(rule.maturity),
          estimatedTokens: estimateTokensFromPath(rule.file),
        });
      }
    }
  }

  // Load cloud rules
  if (config.cloud) {
    for (const [cloudKey, cloudConfig] of Object.entries(config.cloud)) {
      for (const rule of cloudConfig.rules) {
        rules.push({
          path: rule.file,
          title: rule.name,
          category: 'cloud',
          cloudProvider: cloudKey,
          topics: rule.topics || extractTopicsFromName(rule.name),
          maturity: parseMaturity(rule.maturity),
          estimatedTokens: estimateTokensFromPath(rule.file),
        });
      }
    }
  }

  // Cache the loaded rules
  cachedRules = rules;

  return rules;
}

/**
 * Clear the rules cache (mainly for testing)
 */
export function clearRulesCache(): void {
  cachedRules = null;
}

/**
 * Parse maturity levels from config
 */
function parseMaturity(maturity?: string[]): ('mvp' | 'pre-production' | 'production')[] {
  if (!maturity || maturity.length === 0) {
    return ['mvp', 'pre-production', 'production'];
  }

  const validLevels: ('mvp' | 'pre-production' | 'production')[] = [];
  for (const level of maturity) {
    const normalized = level.toLowerCase().trim();
    if (normalized === 'mvp' || normalized === 'pre-production' || normalized === 'production') {
      validLevels.push(normalized);
    }
  }

  return validLevels.length > 0 ? validLevels : ['mvp', 'pre-production', 'production'];
}

/**
 * Extract topics from rule name as a fallback
 */
function extractTopicsFromName(name: string): string[] {
  const topics: string[] = [];
  const nameLower = name.toLowerCase();

  if (nameLower.includes('security')) topics.push('security');
  if (nameLower.includes('testing')) topics.push('testing');
  if (nameLower.includes('quality')) topics.push('quality');
  if (nameLower.includes('standards')) topics.push('standards');
  if (nameLower.includes('architecture')) topics.push('architecture');
  if (nameLower.includes('performance')) topics.push('performance');
  if (nameLower.includes('api')) topics.push('api');

  return topics.length > 0 ? topics : ['general'];
}

/**
 * Estimate tokens based on rule type/path
 * This is a rough estimate - actual content will vary
 */
function estimateTokensFromPath(filePath: string): number {
  if (filePath.includes('base/')) return 1000;
  if (filePath.includes('languages/')) return 1200;
  if (filePath.includes('frameworks/')) return 1500;
  if (filePath.includes('cloud/')) return 1600;
  return 800;
}
