/**
 * Unit tests for rule-config-loader against the real rules-config.json
 */

import { describe, it, expect, beforeEach } from 'vitest';
import * as fs from 'fs';
import * as path from 'path';
import { loadRulesConfig, clearRulesCache } from '../../../src/config/rule-config-loader';

const REPO_ROOT = path.resolve(__dirname, '../../../..');
const configPath = path.join(REPO_ROOT, 'rules-config.json');
const config = JSON.parse(fs.readFileSync(configPath, 'utf-8')) as {
  languages: Record<string, { rules: { file: string }[] }>;
};
const configuredLanguages = Object.keys(config.languages);

describe('loadRulesConfig language testing rules', () => {
  beforeEach(() => {
    clearRulesCache();
  });

  // A language's testing.md that is not listed in rules-config.json can never be
  // selected by the skill, even though sync-ai-rules.sh still copies the file.
  it.each(
    configuredLanguages.filter((lang) =>
      fs.existsSync(path.join(REPO_ROOT, 'languages', lang, 'testing.md'))
    )
  )('lists languages/%s/testing.md as a testing rule', (lang) => {
    const rules = loadRulesConfig(configPath);
    const testingRule = rules.find((rule) => rule.path === `languages/${lang}/testing.md`);

    expect(testingRule).toBeDefined();
    expect(testingRule?.language).toBe(lang);
    expect(testingRule?.topics).toContain('testing');
  });

  it('points every testing entry at a file that exists', () => {
    const testingFiles = configuredLanguages.flatMap((lang) =>
      config.languages[lang].rules
        .map((rule) => rule.file)
        .filter((file) => file.endsWith('/testing.md'))
    );

    expect(testingFiles.length).toBeGreaterThan(0);
    for (const file of testingFiles) {
      expect(fs.existsSync(path.join(REPO_ROOT, file)), file).toBe(true);
    }
  });
});
