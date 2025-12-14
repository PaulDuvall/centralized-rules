import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'dist/',
        'tests/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/index.ts'
      ],
      thresholds: {
        lines: 85,
        functions: 85,
        branches: 85,
        statements: 85
      }
    },
    include: ['tests/**/*.test.ts'],
    exclude: ['node_modules', 'dist'],
    testTimeout: 10000
  },
  resolve: {
    alias: {
      '@hooks': path.resolve(__dirname, './src/hooks'),
      '@tools': path.resolve(__dirname, './src/tools'),
      '@cache': path.resolve(__dirname, './src/cache'),
      '@types': path.resolve(__dirname, './src/types')
    }
  }
});
