/**
 * Project context detection tool
 * Analyzes the codebase to detect languages, frameworks, cloud providers, and maturity level
 */

import * as fs from 'fs';
import * as path from 'path';
import type { ProjectContext } from '../types';
import detectionPatterns from '../config/detection-patterns.json';
import { DetectionError, getErrorMessage } from '../errors';

/**
 * Language detection patterns (loaded from config)
 */
const LANGUAGE_PATTERNS = detectionPatterns.languages;

/**
 * Maturity level indicators
 */
interface MaturityIndicators {
  hasCI: boolean;
  hasDocker: boolean;
  hasTests: boolean;
  hasMonitoring: boolean;
  version: string;
}

/**
 * Detect project context from a directory
 */
export async function detectContext(directory: string = process.cwd()): Promise<ProjectContext> {
  try {
    const languages = await detectLanguages(directory);
    const frameworks = await detectFrameworks(directory, languages);
    const cloudProviders = await detectCloudProviders(directory);
    const maturity = await detectMaturity(directory);

    // Calculate confidence based on what was detected
    const confidence = calculateConfidence(languages, frameworks, cloudProviders);

    return {
      languages,
      frameworks,
      cloudProviders,
      maturity,
      workingDirectory: directory,
      confidence,
    };
  } catch (error) {
    throw new DetectionError(
      `Failed to detect project context in ${directory}: ${getErrorMessage(error)}`,
      'language',
      { directory, error: getErrorMessage(error) }
    );
  }
}

/**
 * Detect programming languages in the project
 */
async function detectLanguages(directory: string): Promise<string[]> {
  const detected: Set<string> = new Set();

  for (const [lang, config] of Object.entries(LANGUAGE_PATTERNS)) {
    const patterns = config.patterns;
    for (const pattern of patterns) {
      const filepath = pattern.replace('**/', '').replace('*', '');
      if (fileExists(path.join(directory, filepath))) {
        detected.add(lang);
        break;
      }
    }
  }

  // Handle TypeScript/JavaScript overlap - prefer TypeScript if both exist and tsconfig.json is present
  if (detected.has('typescript') && detected.has('javascript')) {
    const hasTsConfig = fileExists(path.join(directory, 'tsconfig.json'));
    if (hasTsConfig) {
      detected.delete('javascript');
    }
  }

  return Array.from(detected);
}

/**
 * Detect frameworks based on language and file patterns
 */
async function detectFrameworks(directory: string, languages: string[]): Promise<string[]> {
  const detected: Set<string> = new Set();

  // Check package.json for Node.js frameworks
  if (languages.includes('typescript') || languages.includes('javascript')) {
    const packageJsonPath = path.join(directory, 'package.json');
    if (fileExists(packageJsonPath)) {
      try {
        const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
        const deps = { ...packageJson.dependencies, ...packageJson.devDependencies };

        // Check each framework from config
        for (const [framework, config] of Object.entries(detectionPatterns.frameworks)) {
          if ('packageDependencies' in config && config.packageDependencies) {
            for (const dep of config.packageDependencies) {
              if (deps[dep]) {
                detected.add(framework);
                break;
              }
            }
          }
        }
      } catch (error) {
        // Malformed package.json - skip framework detection for this file
        // This is expected in some edge cases, so just continue
        console.log(`[detect-context] Could not parse package.json: ${getErrorMessage(error)}`);
      }
    }
  }

  // Check for Python frameworks
  if (languages.includes('python')) {
    const reqPath = path.join(directory, 'requirements.txt');
    if (fileExists(reqPath)) {
      const content = fs.readFileSync(reqPath, 'utf-8').toLowerCase();

      // Check each Python framework from config
      for (const [framework, config] of Object.entries(detectionPatterns.frameworks)) {
        if ('requirementsDependencies' in config && config.requirementsDependencies) {
          for (const dep of config.requirementsDependencies) {
            if (content.includes(dep.toLowerCase())) {
              detected.add(framework);
              break;
            }
          }
        }
      }
    }

    const pyprojectPath = path.join(directory, 'pyproject.toml');
    if (fileExists(pyprojectPath)) {
      const content = fs.readFileSync(pyprojectPath, 'utf-8').toLowerCase();

      // Check each Python framework from config
      for (const [framework, config] of Object.entries(detectionPatterns.frameworks)) {
        if ('requirementsDependencies' in config && config.requirementsDependencies) {
          for (const dep of config.requirementsDependencies) {
            if (content.includes(dep.toLowerCase())) {
              detected.add(framework);
              break;
            }
          }
        }
      }
    }
  }

  // Check for Java frameworks
  if (languages.includes('java')) {
    const pomPath = path.join(directory, 'pom.xml');
    if (fileExists(pomPath)) {
      const content = fs.readFileSync(pomPath, 'utf-8');
      if (content.includes('spring-boot')) detected.add('springboot');
    }

    const gradlePath = path.join(directory, 'build.gradle');
    if (fileExists(gradlePath)) {
      const content = fs.readFileSync(gradlePath, 'utf-8');
      if (content.includes('org.springframework.boot')) detected.add('springboot');
    }
  }

  // Check for Go frameworks
  if (languages.includes('go')) {
    const goModPath = path.join(directory, 'go.mod');
    if (fileExists(goModPath)) {
      const content = fs.readFileSync(goModPath, 'utf-8');
      if (content.includes('github.com/gin-gonic/gin')) detected.add('gin');
      if (content.includes('github.com/labstack/echo')) detected.add('echo');
    }
  }

  return Array.from(detected);
}

/**
 * Detect cloud providers used in the project
 */
async function detectCloudProviders(directory: string): Promise<string[]> {
  const detected: Set<string> = new Set();

  // Check for AWS
  if (
    directoryExists(path.join(directory, '.aws')) ||
    directoryExists(path.join(directory, 'terraform')) ||
    directoryExists(path.join(directory, 'cloudformation')) ||
    directoryExists(path.join(directory, 'cdk'))
  ) {
    detected.add('aws');
  }

  // Check for Vercel
  if (fileExists(path.join(directory, 'vercel.json'))) {
    detected.add('vercel');
  }

  // Check for Azure
  if (fileExists(path.join(directory, 'azure-pipelines.yml'))) {
    detected.add('azure');
  }

  // Check for GCP
  if (
    fileExists(path.join(directory, 'cloudbuild.yaml')) ||
    fileExists(path.join(directory, 'app.yaml'))
  ) {
    detected.add('gcp');
  }

  // Check package dependencies for cloud SDKs
  const packageJsonPath = path.join(directory, 'package.json');
  if (fileExists(packageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
    const deps = { ...packageJson.dependencies, ...packageJson.devDependencies };

    if (deps['aws-sdk'] || deps['@aws-sdk/client-s3']) detected.add('aws');
    if (deps['@azure/storage-blob']) detected.add('azure');
    if (deps['@google-cloud/storage']) detected.add('gcp');
  }

  const reqPath = path.join(directory, 'requirements.txt');
  if (fileExists(reqPath)) {
    const content = fs.readFileSync(reqPath, 'utf-8').toLowerCase();
    if (content.includes('boto3') || content.includes('aws')) detected.add('aws');
    if (content.includes('azure')) detected.add('azure');
    if (content.includes('google-cloud')) detected.add('gcp');
  }

  return Array.from(detected);
}

/**
 * Detect project maturity level
 */
async function detectMaturity(directory: string): Promise<'mvp' | 'pre-production' | 'production'> {
  const indicators = await getMaturityIndicators(directory);

  // Production: version 1.x.x+, has CI/CD, Docker, tests, monitoring
  const majorVersion = indicators.version.split('.')[0];
  if (
    indicators.version.startsWith('1.') ||
    indicators.version.startsWith('2.') ||
    (majorVersion && parseInt(majorVersion) > 2)
  ) {
    if (indicators.hasCI && indicators.hasDocker) {
      return 'production';
    }
  }

  // Pre-production: version 0.9.x+, basic CI/CD
  if (indicators.version.startsWith('0.9') || indicators.version.startsWith('0.10')) {
    if (indicators.hasCI) {
      return 'pre-production';
    }
  }

  // MVP/POC: everything else
  return 'mvp';
}

/**
 * Get maturity indicators from the project
 */
async function getMaturityIndicators(directory: string): Promise<MaturityIndicators> {
  let version = '0.1.0';

  // Get version from package.json
  const packageJsonPath = path.join(directory, 'package.json');
  if (fileExists(packageJsonPath)) {
    const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'));
    version = packageJson.version || version;
  }

  // Get version from pyproject.toml
  const pyprojectPath = path.join(directory, 'pyproject.toml');
  if (fileExists(pyprojectPath)) {
    const content = fs.readFileSync(pyprojectPath, 'utf-8');
    const match = content.match(/version\s*=\s*"([^"]+)"/);
    if (match && match[1]) {
      version = match[1];
    }
  }

  const hasCI =
    directoryExists(path.join(directory, '.github/workflows')) ||
    fileExists(path.join(directory, '.gitlab-ci.yml')) ||
    fileExists(path.join(directory, '.circleci/config.yml')) ||
    fileExists(path.join(directory, 'azure-pipelines.yml'));

  const hasDocker =
    fileExists(path.join(directory, 'Dockerfile')) ||
    fileExists(path.join(directory, 'docker-compose.yml'));

  const hasTests =
    directoryExists(path.join(directory, 'tests')) ||
    directoryExists(path.join(directory, 'test')) ||
    directoryExists(path.join(directory, '__tests__')) ||
    directoryExists(path.join(directory, 'spec'));

  const hasMonitoring =
    fileExists(path.join(directory, 'prometheus.yml')) ||
    directoryExists(path.join(directory, 'grafana')) ||
    directoryContainsFiles(directory, ['sentry', 'datadog', 'newrelic']);

  return {
    hasCI,
    hasDocker,
    hasTests,
    hasMonitoring,
    version,
  };
}

/**
 * Calculate confidence score based on detections
 */
function calculateConfidence(
  languages: string[],
  frameworks: string[],
  cloudProviders: string[]
): number {
  let score = 0;

  // Base score for having languages
  if (languages.length > 0) score += 0.5;
  if (languages.length > 1) score += 0.1;

  // Add score for frameworks
  if (frameworks.length > 0) score += 0.3;

  // Add score for cloud providers
  if (cloudProviders.length > 0) score += 0.1;

  return Math.min(score, 1.0);
}

/**
 * Check if a file exists
 */
function fileExists(filepath: string): boolean {
  try {
    return fs.existsSync(filepath) && fs.statSync(filepath).isFile();
  } catch {
    return false;
  }
}

/**
 * Check if a directory exists
 */
function directoryExists(dirpath: string): boolean {
  try {
    return fs.existsSync(dirpath) && fs.statSync(dirpath).isDirectory();
  } catch {
    return false;
  }
}

/**
 * Check if a directory contains files matching patterns
 */
function directoryContainsFiles(directory: string, patterns: string[]): boolean {
  try {
    if (!fs.existsSync(directory)) return false;

    const files = (fs.readdirSync(directory, { recursive: true }) as string[]) || [];
    return files.some(file =>
      patterns.some(pattern => file.toLowerCase().includes(pattern.toLowerCase()))
    );
  } catch {
    return false;
  }
}

/**
 * Tool handler for Claude
 */
export async function handler(params: { directory?: string } = {}): Promise<ProjectContext> {
  const directory = params.directory || process.cwd();
  return detectContext(directory);
}
