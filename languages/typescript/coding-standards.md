# TypeScript Coding Standards

> **Language:** TypeScript 5.0+
> **Applies to:** All TypeScript/JavaScript projects

## TypeScript-Specific Standards

### Type Safety

- **Use strict mode** - Enable `strict: true` in tsconfig.json
- **Explicit types for functions** - All parameters and return types
- **Avoid `any`** - Use `unknown` if type is truly unknown
- **Use type inference** where obvious
- **Prefer interfaces for objects** - Use `type` for unions/intersections

**Example:**
```typescript
// ❌ No type annotations
function processData(items) {
    return items.map(x => x * 2);
}

// ✅ With type annotations
function processData(items: number[]): number[] {
    return items.map(x => x * 2);
}

// ✅ Complex types with interface
interface User {
    id: string;
    email: string;
    age?: number;
}

function getUser(id: string): Promise<User> {
    // Implementation
}
```

### Code Structure

- **Maximum 20-25 lines per function**
- **Maximum 300-500 lines per file**
- **Single Responsibility Principle**
- **Use JSDoc for public APIs**

**Example:**
```typescript
/**
 * Validates user input data
 * @param data - User input object
 * @returns True if valid, false otherwise
 * @throws {ValidationError} If data structure is invalid
 */
function validateInput(data: unknown): boolean {
    if (typeof data !== 'object' || data === null) {
        throw new ValidationError('Invalid data structure');
    }
    return true;
}
```

### Error Handling

- **Use custom error classes**
- **Catch specific error types**
- **Provide actionable error messages**
- **Include remediation guidance**

**Example:**
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
                `Invalid JSON in ${filePath}: ${error.message} | ` +
                `Remediation: Validate JSON format`
            );
        }
        throw new DataProcessingError(
            `Failed to read file: ${filePath} | ` +
            `Remediation: Check file exists and permissions`
        );
    }
}
```

## TypeScript Style Guidelines

### Naming Conventions

- **Variables and functions:** `camelCase`
- **Classes and interfaces:** `PascalCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Private members:** `#private` or `_underscore`
- **Boolean variables:** Use `is`, `has`, `should` prefixes

**Example:**
```typescript
// Constants
const MAX_RETRIES = 3;
const DEFAULT_TIMEOUT = 30000;

// Interface
interface UserData {
    firstName: string;
    lastName: string;
    isActive: boolean;
}

// Class with private field
class DataProcessor {
    #cache: Map<string, any> = new Map();

    processItem(item: unknown): void {
        const isValid = this.#validate(item);
        if (isValid) {
            this.#store(item);
        }
    }

    #validate(item: unknown): boolean {
        return item !== null && item !== undefined;
    }

    #store(item: unknown): void {
        // Store implementation
    }
}
```

### Import Organization

```typescript
// Node.js built-ins
import * as fs from 'fs/promises';
import { join } from 'path';

// Third-party packages
import express from 'express';
import { z } from 'zod';

// Local imports - absolute
import { config } from '@/config';
import { logger } from '@/utils/logger';

// Local imports - relative
import { User } from './types';
import { validateUser } from './validation';
```

### String and Template Literals

```typescript
// ✅ Use template literals for string interpolation
const message = `Hello, ${name}!`;

// ✅ Multi-line strings
const query = `
    SELECT id, name, email
    FROM users
    WHERE age > ${minAge}
`;

// ❌ String concatenation
const message = 'Hello, ' + name + '!';
```

## TypeScript Configuration

### tsconfig.json (Strict Mode)

```json
{
    "compilerOptions": {
        "target": "ES2022",
        "module": "ESNext",
        "lib": ["ES2022"],
        "outDir": "./dist",
        "rootDir": "./src",

        // Strict Type Checking
        "strict": true,
        "noImplicitAny": true,
        "strictNullChecks": true,
        "strictFunctionTypes": true,
        "strictPropertyInitialization": true,
        "noImplicitThis": true,
        "alwaysStrict": true,

        // Additional Checks
        "noUnusedLocals": true,
        "noUnusedParameters": true,
        "noImplicitReturns": true,
        "noFallthroughCasesInSwitch": true,

        // Module Resolution
        "moduleResolution": "bundler",
        "resolveJsonModule": true,
        "esModuleInterop": true,
        "forceConsistentCasingInFileNames": true,

        // Advanced
        "skipLibCheck": true
    },
    "include": ["src/**/*"],
    "exclude": ["node_modules", "dist"]
}
```

## TypeScript Security

### Never Hardcode Secrets

```typescript
// ❌ Hardcoded secret
const API_KEY = 'sk-1234567890abcdef';

// ✅ Environment variable with validation
const API_KEY = process.env.API_KEY;
if (!API_KEY) {
    throw new Error(
        'API_KEY not set | ' +
        'Remediation: Add to .env file or set environment variable'
    );
}
```

### Input Validation with Zod

```typescript
import { z } from 'zod';

// Define schema
const UserSchema = z.object({
    email: z.string().email(),
    age: z.number().int().positive().optional(),
    role: z.enum(['admin', 'user', 'guest']),
});

type User = z.infer<typeof UserSchema>;

// Validate input
function createUser(data: unknown): User {
    try {
        return UserSchema.parse(data);
    } catch (error) {
        if (error instanceof z.ZodError) {
            throw new ValidationError(
                `Invalid user data: ${error.message}`
            );
        }
        throw error;
    }
}
```

### Avoid `eval` and Dynamic Code

```typescript
// ❌ Never use eval
const result = eval(userInput);

// ❌ Avoid Function constructor
const fn = new Function('x', userInput);

// ✅ Use safe alternatives
const result = JSON.parse(userInput);
```

## TypeScript Linting and Formatting

### Required Tools

- **ESLint** - TypeScript linting
- **Prettier** - Code formatter
- **TypeScript** - Type checker

### Pre-commit Workflow

```bash
# Format code
npx prettier --write src/

# Lint code
npx eslint src/ --ext .ts,.tsx

# Type check
npx tsc --noEmit
```

### ESLint Configuration (.eslintrc.json)

```json
{
    "parser": "@typescript-eslint/parser",
    "parserOptions": {
        "ecmaVersion": 2022,
        "sourceType": "module",
        "project": "./tsconfig.json"
    },
    "plugins": ["@typescript-eslint"],
    "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended",
        "plugin:@typescript-eslint/recommended-requiring-type-checking",
        "prettier"
    ],
    "rules": {
        "@typescript-eslint/no-explicit-any": "error",
        "@typescript-eslint/explicit-function-return-type": "warn",
        "@typescript-eslint/no-unused-vars": "error",
        "no-console": "warn"
    }
}
```

### Prettier Configuration (.prettierrc)

```json
{
    "semi": true,
    "trailingComma": "es5",
    "singleQuote": true,
    "printWidth": 100,
    "tabWidth": 2,
    "useTabs": false
}
```

## TypeScript Best Practices

### Use Modern JavaScript Features

```typescript
// ✅ Optional chaining
const email = user?.profile?.email;

// ✅ Nullish coalescing
const timeout = config.timeout ?? DEFAULT_TIMEOUT;

// ✅ Destructuring
const { firstName, lastName, email } = user;

// ✅ Spread operator
const updatedUser = { ...user, isActive: true };
```

### Use Type Guards

```typescript
function isString(value: unknown): value is string {
    return typeof value === 'string';
}

function processValue(value: unknown): string {
    if (isString(value)) {
        // TypeScript knows value is string here
        return value.toUpperCase();
    }
    throw new Error('Value must be a string');
}
```

### Use Discriminated Unions

```typescript
type Result<T> =
    | { success: true; data: T }
    | { success: false; error: string };

function handleResult<T>(result: Result<T>): void {
    if (result.success) {
        console.log(result.data);
    } else {
        console.error(result.error);
    }
}
```

### Prefer `const` Over `let`

```typescript
// ✅ Use const for values that don't change
const MAX_SIZE = 100;
const user = { name: 'John' };

// ✅ Use let only when needed
let counter = 0;
counter++;
```

### Avoid Type Assertions (use sparingly)

```typescript
// ❌ Type assertion (use only when necessary)
const user = data as User;

// ✅ Type validation
function isUser(data: unknown): data is User {
    return (
        typeof data === 'object' &&
        data !== null &&
        'email' in data &&
        typeof data.email === 'string'
    );
}

if (isUser(data)) {
    // TypeScript knows data is User here
}
```

## TypeScript Testing

See [testing.md](./testing.md) for detailed TypeScript testing guidelines.

## References

- **TypeScript Handbook:** https://www.typescriptlang.org/docs/handbook/
- **TypeScript ESLint:** https://typescript-eslint.io/
- **Prettier:** https://prettier.io/
- **Zod:** https://zod.dev/
