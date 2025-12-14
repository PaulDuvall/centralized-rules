/**
 * beforeResponse hook - automatically inject relevant rules before Claude responds
 */

import type { SkillContext, HookResult } from '../types';
import { detectContext } from '../tools/detect-context';
import { analyzeIntent, selectRules, getAvailableRules } from '../tools/select-rules';
import { fetchRules } from '../tools/get-rules';

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

  try {
    // Check if auto-load is enabled
    if (!context.config.enableAutoLoad) {
      if (context.config.verbose) {
        console.log('[before-response] Auto-load disabled, skipping');
      }
      return {
        continue: true,
      };
    }

    // Get the user's last message
    const lastUserMessage = context.messages
      .filter(m => m.role === 'user')
      .pop();

    if (!lastUserMessage) {
      return {
        continue: true,
      };
    }

    // Step 1: Detect project context
    const detectionStart = Date.now();
    const projectContext = await detectContext(context.workingDirectory);
    timing.detection = Date.now() - detectionStart;

    if (context.config.verbose) {
      console.log('[before-response] Project context:', JSON.stringify(projectContext, null, 2));
    }

    // Step 2: Analyze user intent
    const analysisStart = Date.now();
    const userIntent = analyzeIntent(lastUserMessage.content);
    timing.analysis = Date.now() - analysisStart;

    if (context.config.verbose) {
      console.log('[before-response] User intent:', JSON.stringify(userIntent, null, 2));
    }

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

    if (context.config.verbose) {
      console.log(
        '[before-response] Selected rules:',
        selectedRuleInfos.map(r => r.path)
      );
    }

    // If no rules selected, skip
    if (selectedRuleInfos.length === 0) {
      if (context.config.verbose) {
        console.log('[before-response] No relevant rules found');
      }
      return {
        continue: true,
      };
    }

    // Step 4: Fetch rules from GitHub
    const fetchingStart = Date.now();
    const rules = await fetchRules(selectedRuleInfos, context.config);
    timing.fetching = Date.now() - fetchingStart;

    if (rules.length === 0) {
      console.warn('[before-response] Failed to fetch any rules');
      return {
        continue: true,
      };
    }

    // Step 5: Format rules for injection
    const systemPrompt = formatRulesForInjection(projectContext, userIntent, rules);

    timing.total = Date.now() - startTime;

    // Warn if execution is slow
    if (timing.total > 2000) {
      console.warn(`[before-response] Slow execution: ${timing.total}ms`);
    }

    if (context.config.verbose) {
      console.log('[before-response] Timing:', timing);
    }

    return {
      continue: true,
      systemPrompt,
      metadata: {
        projectContext,
        userIntent,
        rulesLoaded: rules.length,
        rulesPaths: rules.map(r => r.path),
        timing,
      },
    };
  } catch (error) {
    // Never block Claude on errors
    console.error('[before-response] Error:', error);
    return {
      continue: true,
      metadata: {
        error: error instanceof Error ? error.message : 'Unknown error',
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
