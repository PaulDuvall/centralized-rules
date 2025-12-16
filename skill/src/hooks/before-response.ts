/**
 * beforeResponse hook - automatically inject relevant rules before Claude responds
 */

import type { SkillContext, HookResult } from '../types';
import { detectContext } from '../tools/detect-context';
import { analyzeIntent, selectRules, getAvailableRules } from '../tools/select-rules';
import { fetchRules } from '../tools/get-rules';
import { getErrorDetails, getErrorMessage, isSkillError } from '../errors';
import { loggers, configureLogging, formatDuration } from '../services/logger';

/**
 * Hook execution timing
 */
interface Timing {
  detection: number;
  analysis: number;
  selection: number;
  fetching: number;
  total: number;
}

/**
 * beforeResponse hook handler
 */
export async function handler(context: SkillContext): Promise<HookResult> {
  const startTime = Date.now();
  const timing: Partial<Timing> = {};
  const logger = loggers.hook;

  // Configure logging based on verbose setting
  configureLogging(context.config.verbose);

  try {
    // Check if auto-load is enabled
    if (!context.config.enableAutoLoad) {
      logger.debug('Auto-load disabled, skipping rule injection');
      return {
        continue: true,
      };
    }

    // Get the user's last message
    const lastUserMessage = context.messages.filter((m) => m.role === 'user').pop();

    if (!lastUserMessage) {
      return {
        continue: true,
      };
    }

    // Step 1: Detect project context
    const detectionStart = Date.now();
    const projectContext = await detectContext(context.workingDirectory);
    timing.detection = Date.now() - detectionStart;

    logger.debug('Project context detected', {
      languages: projectContext.languages,
      frameworks: projectContext.frameworks,
      cloudProviders: projectContext.cloudProviders,
      maturity: projectContext.maturity,
      confidence: projectContext.confidence,
      duration: formatDuration(timing.detection),
    });

    // Step 2: Analyze user intent
    const analysisStart = Date.now();
    const userIntent = analyzeIntent(lastUserMessage.content);
    timing.analysis = Date.now() - analysisStart;

    logger.debug('User intent analyzed', {
      topics: userIntent.topics,
      action: userIntent.action,
      urgency: userIntent.urgency,
      duration: formatDuration(timing.analysis),
    });

    // Step 3: Select relevant rules
    const selectionStart = Date.now();
    const availableRules = getAvailableRules();
    const selectedRuleInfos = selectRules(availableRules, {
      project: projectContext,
      intent: userIntent,
      maxRules: context.config.maxRules,
      maxTokens: context.config.maxTokens,
    });
    timing.selection = Date.now() - selectionStart;

    logger.debug('Rules selected', {
      count: selectedRuleInfos.length,
      rules: selectedRuleInfos.map((r) => r.path),
      duration: formatDuration(timing.selection),
    });

    // If no rules selected, skip
    if (selectedRuleInfos.length === 0) {
      logger.info('No relevant rules found for current context');
      return {
        continue: true,
      };
    }

    // Step 4: Fetch rules from GitHub
    const fetchingStart = Date.now();
    const rules = await fetchRules(selectedRuleInfos, context.config);
    timing.fetching = Date.now() - fetchingStart;

    if (rules.length === 0) {
      logger.warn('Failed to fetch any rules from GitHub', {
        requestedCount: selectedRuleInfos.length,
      });
      return {
        continue: true,
      };
    }

    logger.debug('Rules fetched from GitHub', {
      count: rules.length,
      duration: formatDuration(timing.fetching),
    });

    // Step 5: Format rules for injection
    const systemPrompt = formatRulesForInjection(projectContext, userIntent, rules);

    timing.total = Date.now() - startTime;

    // Warn if execution is slow
    if (timing.total > 2000) {
      logger.warn('Slow hook execution detected', {
        duration: formatDuration(timing.total),
        threshold: '2000ms',
      });
    }

    logger.debug('Hook execution complete', {
      rulesInjected: rules.length,
      totalDuration: formatDuration(timing.total),
      timing: {
        detection: formatDuration(timing.detection || 0),
        analysis: formatDuration(timing.analysis || 0),
        selection: formatDuration(timing.selection || 0),
        fetching: formatDuration(timing.fetching || 0),
      },
    });

    return {
      continue: true,
      systemPrompt,
      metadata: {
        projectContext,
        userIntent,
        rulesLoaded: rules.length,
        rulesPaths: rules.map((r) => r.path),
        timing,
      },
    };
  } catch (error) {
    // CRITICAL: Never block Claude on errors - always return continue: true
    // Log detailed error information for debugging
    if (isSkillError(error)) {
      logger.error('Skill error in hook execution', error, getErrorDetails(error));
    } else {
      logger.error('Unexpected error in hook execution', error, {
        message: getErrorMessage(error),
        stack: error instanceof Error ? error.stack : undefined,
      });
    }

    return {
      continue: true,
      metadata: {
        error: getErrorMessage(error),
        errorDetails: isSkillError(error) ? getErrorDetails(error) : undefined,
      },
    };
  }
}

/**
 * Format rules as markdown for injection into system prompt
 */
function formatRulesForInjection(
  projectContext: Awaited<ReturnType<typeof detectContext>>,
  userIntent: ReturnType<typeof analyzeIntent>,
  rules: Awaited<ReturnType<typeof fetchRules>>
): string {
  const sections: string[] = [];

  // INSTRUCTION: Tell Claude to display a visible banner
  sections.push('---\n');
  sections.push('**IMPORTANT INSTRUCTION FOR CLAUDE:**\n');
  sections.push(
    'Start your response with the following visible banner to inform the user that centralized rules are active:\n'
  );
  sections.push('```');
  sections.push('═══════════════════════════════════════════════════════');
  sections.push('📋 Centralized Rules Active');
  sections.push('═══════════════════════════════════════════════════════');
  sections.push('');
  sections.push('🔍 Context Detected:');
  sections.push(
    `   Languages: ${projectContext.languages.join(', ') || 'None'} | Frameworks: ${projectContext.frameworks.join(', ') || 'None'}`
  );
  sections.push(
    `   Maturity: ${projectContext.maturity} | Confidence: ${Math.round(projectContext.confidence * 100)}%`
  );
  sections.push('');
  sections.push(`📖 Rules Loaded: ${rules.length} files`);
  sections.push(`   ${rules.map((r) => r.title).join(', ')}`);
  sections.push('═══════════════════════════════════════════════════════');
  sections.push('```');
  sections.push('\nAfter showing this banner, proceed with your normal response.\n');
  sections.push('---\n');

  // Header
  sections.push('# 📚 Relevant Coding Rules\n');
  sections.push(
    '*Automatically loaded based on your project context. These rules provide context-aware guidance.*\n'
  );

  // Project context summary
  sections.push('## 🔍 Detected Project Context\n');
  sections.push(`- **Languages**: ${projectContext.languages.join(', ') || 'None detected'}`);
  sections.push(`- **Frameworks**: ${projectContext.frameworks.join(', ') || 'None detected'}`);
  sections.push(
    `- **Cloud Providers**: ${projectContext.cloudProviders.join(', ') || 'None detected'}`
  );
  sections.push(`- **Maturity Level**: ${projectContext.maturity}`);

  if (userIntent.topics.length > 0) {
    sections.push(`- **Detected Topics**: ${userIntent.topics.join(', ')}`);
  }

  sections.push(`- **Confidence**: ${Math.round(projectContext.confidence * 100)}%\n`);

  // Rules
  sections.push(`## 📖 Applicable Rules (${rules.length} loaded)\n`);

  for (const rule of rules) {
    sections.push(`### ${rule.title}\n`);
    sections.push(`*Source: \`${rule.path}\`*\n`);
    sections.push(rule.content);
    sections.push('\n---\n');
  }

  // Footer
  sections.push(
    '\n*Note: Apply these rules as guidance, not strict requirements. Use judgment based on the specific context.*\n'
  );

  return sections.join('\n');
}
