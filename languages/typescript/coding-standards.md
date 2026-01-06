# TypeScript Coding Standards

> **Language:** TypeScript 5.0+ | **Scope:** All TypeScript/JavaScript projects

## Type Safety

- **Enable `strict: true`** in tsconfig.json
- **Explicit types for function parameters and return types**
- **Avoid `any`** - Use `unknown` if type is truly unknown
- **Prefer interfaces for objects, types for unions/intersections**
- **Use type inference** where obvious (e.g., `const count = 5`)

```typescript
function processData(items: number[]): number[] {
  return items.map(x => x * 2);
}

interface User { id: string; email: string; age?: number; }
function getUser(id: string): Promise<User> { /* ... */ }
```

## Code Structure

- **Max 20-25 lines per function**
- **Max 300-500 lines per file**
- **Single Responsibility Principle**
- **JSDoc for public APIs**

```typescript
/**
 * Validates user input data
 * @param data - User input object
 * @returns True if valid
 * @throws {ValidationError} If data structure is invalid
 */
function validateInput(data: unknown): boolean {
  if (typeof data !== 'object' || data === null) {
    throw new ValidationError('Invalid data structure');
  }
  return true;
}
```

## Error Handling

- **Use custom error classes**
- **Catch specific error types**
- **Include actionable messages with remediation guidance**

```typescript
class DataProcessingError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'DataProcessingError';
  }
}

async function processFile(filePath: string): Promise<Data> {
  try {
    const content = await fs.readFile(filePath, 'utf-8');
    return JSON.parse(content);
  } catch (error) {
    if (error instanceof SyntaxError) {
      throw new DataProcessingError(
        `Invalid JSON in ${filePath}: ${error.message} | Remediation: Validate JSON format`
      );
    }
    throw new DataProcessingError(
      `Failed to read file: ${filePath} | Remediation: Check file exists and permissions`
    );
  }
}
```

## Naming Conventions

- **Variables/functions:** `camelCase`
- **Classes/interfaces:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Private members:** `#private`
- **Booleans:** `is`, `has`, `should` prefixes

```typescript
const MAX_RETRIES = 3;
interface UserData { firstName: string; isActive: boolean; }
class DataProcessor {
  #cache: Map<string, any> = new Map();
  #validate(item: unknown): boolean { return item != null; }
}
```

## Import Organization

```typescript
// Node.js built-ins
import * as fs from 'fs/promises';
import { join } from 'path';

// Third-party packages
import express from 'express';
import { z } from 'zod';

// Local imports (absolute, then relative)
import { config } from '@/config';
import { User } from './types';
```

## String Interpolation

- **Use template literals** for string interpolation
- **Avoid string concatenation with `+`**

```typescript
const message = `Hello, ${name}!`;
const query = `SELECT * FROM users WHERE age > ${minAge}`;
```

## tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

## Security

**Never hardcode secrets:**
```typescript
const API_KEY = process.env.API_KEY;
if (!API_KEY) throw new Error('API_KEY not set | Remediation: Set environment variable');
```

**Validate input with Zod:**
```typescript
const UserSchema = z.object({
  email: z.string().email(),
  age: z.number().int().positive().optional(),
  role: z.enum(['admin', 'user', 'guest']),
});
type User = z.infer<typeof UserSchema>;
```

**Avoid `eval` and `new Function()`:**
```typescript
const result = JSON.parse(userInput); // Safe alternative
```

## Linting and Formatting

**Tools:** ESLint, Prettier, TypeScript

**Pre-commit workflow:**
```bash
npx prettier --write src/
npx eslint src/ --ext .ts,.tsx
npx tsc --noEmit
```

**ESLint (.eslintrc.json):**
```json
{
  "parser": "@typescript-eslint/parser",
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "prettier"
  ],
  "rules": {
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

**Prettier (.prettierrc):**
```json
{ "semi": true, "singleQuote": true, "printWidth": 100, "tabWidth": 2 }
```

## Modern Features

- **Optional chaining:** `user?.profile?.email`
- **Nullish coalescing:** `config.timeout ?? DEFAULT_TIMEOUT`
- **Destructuring:** `const { firstName, email } = user`
- **Spread operator:** `const updated = { ...user, isActive: true }`
- **Type guards:** `function isString(v: unknown): v is string { return typeof v === 'string'; }`
- **Discriminated unions:** `type Result<T> = { success: true; data: T } | { success: false; error: string }`

## References

- TypeScript Handbook: https://www.typescriptlang.org/docs/handbook/
- TypeScript ESLint: https://typescript-eslint.io/
- Zod: https://zod.dev/
