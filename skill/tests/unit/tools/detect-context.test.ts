/**
 * Unit tests for detect-context
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { detectContext } from '../../../src/tools/detect-context';
import * as fs from 'fs';
import * as path from 'path';

describe('detectContext', () => {
  describe('language detection', () => {
    it('should detect Python projects', async () => {
      const testDir = path.join(__dirname, '../../fixtures/python-project');
      const context = await detectContext(testDir);

      expect(context.languages).toContain('python');
    });

    it('should detect TypeScript projects', async () => {
      const testDir = path.join(__dirname, '../../fixtures/typescript-project');
      const context = await detectContext(testDir);

      expect(context.languages).toContain('typescript');
    });

    it('should prefer TypeScript over JavaScript when both exist', async () => {
      const testDir = path.join(__dirname, '../../fixtures/typescript-project');
      const context = await detectContext(testDir);

      expect(context.languages).toContain('typescript');
      expect(context.languages).not.toContain('javascript');
    });
  });

  describe('framework detection', () => {
    it('should detect FastAPI from requirements.txt', async () => {
      const testDir = path.join(__dirname, '../../fixtures/python-fastapi');
      const context = await detectContext(testDir);

      expect(context.frameworks).toContain('fastapi');
    });

    it('should detect React from package.json', async () => {
      const testDir = path.join(__dirname, '../../fixtures/react-project');
      const context = await detectContext(testDir);

      expect(context.frameworks).toContain('react');
    });

    it('should detect Next.js from next.config.js', async () => {
      const testDir = path.join(__dirname, '../../fixtures/nextjs-project');
      const context = await detectContext(testDir);

      expect(context.frameworks).toContain('nextjs');
    });
  });

  describe('cloud provider detection', () => {
    it('should detect AWS from terraform directory', async () => {
      const testDir = path.join(__dirname, '../../fixtures/aws-project');
      const context = await detectContext(testDir);

      expect(context.cloudProviders).toContain('aws');
    });

    it('should detect Vercel from vercel.json', async () => {
      const testDir = path.join(__dirname, '../../fixtures/vercel-project');
      const context = await detectContext(testDir);

      expect(context.cloudProviders).toContain('vercel');
    });
  });

  describe('maturity level detection', () => {
    it('should detect MVP for version 0.1.0 without CI/CD', async () => {
      const testDir = path.join(__dirname, '../../fixtures/mvp-project');
      const context = await detectContext(testDir);

      expect(context.maturity).toBe('mvp');
    });

    it('should detect pre-production for version 0.9.x with CI', async () => {
      const testDir = path.join(__dirname, '../../fixtures/pre-prod-project');
      const context = await detectContext(testDir);

      expect(context.maturity).toBe('pre-production');
    });

    it('should detect production for version 1.x.x with CI/CD and Docker', async () => {
      const testDir = path.join(__dirname, '../../fixtures/production-project');
      const context = await detectContext(testDir);

      expect(context.maturity).toBe('production');
    });
  });

  describe('confidence scoring', () => {
    it('should have higher confidence with more detected features', async () => {
      const testDir = path.join(__dirname, '../../fixtures/full-stack-project');
      const context = await detectContext(testDir);

      expect(context.confidence).toBeGreaterThan(0.7);
    });

    it('should have lower confidence with minimal detection', async () => {
      const testDir = path.join(__dirname, '../../fixtures/empty-project');
      const context = await detectContext(testDir);

      expect(context.confidence).toBeLessThan(0.5);
    });
  });

  describe('multi-language projects', () => {
    it('should detect multiple languages', async () => {
      const testDir = path.join(__dirname, '../../fixtures/polyglot-project');
      const context = await detectContext(testDir);

      expect(context.languages.length).toBeGreaterThan(1);
    });
  });

  describe('working directory', () => {
    it('should record the working directory', async () => {
      const testDir = path.join(__dirname, '../../fixtures/python-project');
      const context = await detectContext(testDir);

      expect(context.workingDirectory).toBe(testDir);
    });

    it('should use current directory if not specified', async () => {
      const context = await detectContext();

      expect(context.workingDirectory).toBe(process.cwd());
    });
  });
});
