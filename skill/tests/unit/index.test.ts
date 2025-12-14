import { describe, it, expect } from 'vitest';
import { VERSION, SKILL_NAME } from '../../src/index';

describe('Skill metadata', () => {
  it('should have correct version', () => {
    expect(VERSION).toBe('0.1.0');
  });

  it('should have correct skill name', () => {
    expect(SKILL_NAME).toBe('centralized-rules');
  });
});
