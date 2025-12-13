# TypeScript Testing Standards

> **Language:** TypeScript 5.0+
> **Frameworks:** Jest, Vitest, React Testing Library
> **Applies to:** All TypeScript projects

## TypeScript Testing Frameworks

### Jest

Industry-standard testing framework for TypeScript/JavaScript projects.

**Installation:**
```bash
npm install --save-dev jest @types/jest ts-jest
```

**Configuration (jest.config.js):**
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/**/*.interface.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
```

**Basic usage:**
```bash
# Run all tests
npm test

# Run with coverage
npm test -- --coverage

# Run in watch mode
npm test -- --watch

# Run specific test file
npm test -- path/to/test.spec.ts
```

### Vitest

Modern, fast testing framework with native TypeScript support.

**Installation:**
```bash
npm install --save-dev vitest @vitest/ui
```

**Configuration (vitest.config.ts):**
```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'json'],
      exclude: ['**/*.spec.ts', '**/*.test.ts', '**/types/**'],
    },
  },
});
```

**Basic usage:**
```bash
# Run all tests
npm run vitest

# Run with UI
npm run vitest -- --ui

# Run with coverage
npm run vitest -- --coverage

# Run in watch mode
npm run vitest -- --watch
```

## Test Structure

### File Organization

```
project/
├── src/
│   ├── components/
│   │   ├── Button.tsx
│   │   └── Button.test.tsx
│   ├── utils/
│   │   ├── formatters.ts
│   │   └── formatters.test.ts
│   └── services/
│       ├── api.ts
│       └── api.test.ts
└── tests/
    ├── integration/
    │   └── api.integration.test.ts
    └── e2e/
        └── user-flow.e2e.test.ts
```

### Test File Naming

- Suffix test files with `.test.ts` or `.spec.ts`
- Co-locate tests with source files or use separate `tests/` directory
- Example: `Button.tsx` → `Button.test.tsx`

### Test Function Naming

```typescript
import { describe, it, expect } from 'vitest';

describe('Calculator', () => {
  // ✅ Descriptive test names
  it('should add two positive numbers correctly', () => {
    expect(add(2, 3)).toBe(5);
  });

  it('should throw error when dividing by zero', () => {
    expect(() => divide(10, 0)).toThrow('Division by zero');
  });

  it('should return empty array when no items match filter', () => {
    const result = filter(items, () => false);
    expect(result).toEqual([]);
  });

  // ❌ Vague test names
  it('works', () => {
    expect(true).toBe(true);
  });

  it('test function', () => {
    // unclear what's being tested
  });
});
```

## Test Patterns

### Basic Test Structure (Arrange-Act-Assert)

```typescript
describe('UserService', () => {
  it('should create user with hashed password', () => {
    // Arrange
    const userData = {
      email: 'test@example.com',
      password: 'password123',
    };

    // Act
    const user = createUser(userData);

    // Assert
    expect(user.email).toBe('test@example.com');
    expect(user.password).not.toBe('password123');
    expect(user.password.length).toBeGreaterThan(20);
  });
});
```

### Testing Type Safety

```typescript
import { describe, it, expectTypeOf } from 'vitest';

describe('Type Tests', () => {
  it('should have correct return type', () => {
    const result = parseUser({ name: 'John', age: 30 });

    // Type assertion
    expectTypeOf(result).toEqualTypeOf<User>();

    // Runtime assertion
    expect(result).toHaveProperty('name');
    expect(result).toHaveProperty('age');
  });

  it('should enforce type constraints', () => {
    type AdminUser = User & { role: 'admin' };

    const createAdmin = (user: User): AdminUser => ({
      ...user,
      role: 'admin',
    });

    expectTypeOf(createAdmin).parameter(0).toMatchTypeOf<User>();
    expectTypeOf(createAdmin).returns.toMatchTypeOf<AdminUser>();
  });
});
```

### Testing Exceptions

```typescript
describe('Validation', () => {
  it('should throw on invalid email', () => {
    expect(() => validateEmail('invalid')).toThrow('Invalid email format');
  });

  it('should throw specific error type', () => {
    expect(() => connectToDatabase('')).toThrow(ConnectionError);
  });

  it('should handle async errors', async () => {
    await expect(fetchUser('invalid-id')).rejects.toThrow('User not found');
  });
});
```

### Using Test Fixtures

```typescript
import { describe, it, beforeEach, afterEach } from 'vitest';

describe('Database Operations', () => {
  let db: Database;

  beforeEach(async () => {
    // Setup: create fresh database connection
    db = await createTestDatabase();
    await db.migrate();
  });

  afterEach(async () => {
    // Cleanup: close connection and clean up
    await db.rollback();
    await db.close();
  });

  it('should insert user', async () => {
    const user = await db.users.create({
      email: 'test@example.com',
      name: 'Test User',
    });

    expect(user.id).toBeDefined();
    expect(user.email).toBe('test@example.com');
  });
});
```

### Parametrized Tests

```typescript
describe.each([
  { input: 0, expected: 0 },
  { input: 1, expected: 2 },
  { input: 5, expected: 10 },
  { input: -3, expected: -6 },
])('double function', ({ input, expected }) => {
  it(`should return ${expected} when input is ${input}`, () => {
    expect(double(input)).toBe(expected);
  });
});

// Alternative syntax with it.each
it.each([
  ['valid@email.com', true],
  ['invalid-email', false],
  ['', false],
  ['test@', false],
])('validates email "%s" as %s', (email, isValid) => {
  expect(validateEmail(email)).toBe(isValid);
});
```

## Mocking

### Mocking Functions

```typescript
import { vi, describe, it, expect } from 'vitest';

describe('API Service', () => {
  it('should call fetch with correct URL', async () => {
    // Create mock
    const mockFetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ data: 'test' }),
    });

    // Replace global fetch
    global.fetch = mockFetch;

    // Execute
    const result = await fetchData('https://api.example.com/data');

    // Verify
    expect(mockFetch).toHaveBeenCalledWith('https://api.example.com/data');
    expect(result).toEqual({ data: 'test' });
  });
});
```

### Mocking Modules

```typescript
import { vi } from 'vitest';

// Mock entire module
vi.mock('./logger', () => ({
  log: vi.fn(),
  error: vi.fn(),
  warn: vi.fn(),
}));

// Mock with factory function
vi.mock('./database', () => ({
  default: vi.fn(() => ({
    query: vi.fn(),
    connect: vi.fn(),
    disconnect: vi.fn(),
  })),
}));

describe('User Service', () => {
  it('should log user creation', async () => {
    const { log } = await import('./logger');

    await createUser({ email: 'test@example.com' });

    expect(log).toHaveBeenCalledWith('User created: test@example.com');
  });
});
```

### Partial Mocks

```typescript
import { vi } from 'vitest';
import * as utils from './utils';

describe('Partial Mock', () => {
  it('should mock only specific function', () => {
    // Mock only one function, keep others real
    vi.spyOn(utils, 'formatDate').mockReturnValue('2024-01-01');

    expect(utils.formatDate(new Date())).toBe('2024-01-01');
    // Other utils functions remain unmocked
    expect(utils.capitalize('test')).toBe('Test');
  });
});
```

## Async Testing

### Testing Promises

```typescript
describe('Async Operations', () => {
  it('should resolve with user data', async () => {
    const user = await fetchUser('123');

    expect(user.id).toBe('123');
    expect(user.name).toBeDefined();
  });

  it('should reject with error', async () => {
    await expect(fetchUser('invalid')).rejects.toThrow('User not found');
  });

  it('should handle timeout', async () => {
    await expect(
      fetchWithTimeout('https://slow-api.com', 1000)
    ).rejects.toThrow('Request timeout');
  });
});
```

### Testing with waitFor

```typescript
import { waitFor } from '@testing-library/react';

it('should update state after async operation', async () => {
  const { getByText } = render(<AsyncComponent />);

  // Wait for async operation to complete
  await waitFor(() => {
    expect(getByText('Data loaded')).toBeInTheDocument();
  }, { timeout: 3000 });
});
```

## React Testing Library

### Component Testing Setup

```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';

describe('Button Component', () => {
  it('should render with correct text', () => {
    render(<Button>Click me</Button>);

    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('should call onClick when clicked', async () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);

    const button = screen.getByRole('button');
    await userEvent.click(button);

    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

### Testing User Interactions

```typescript
describe('Form Component', () => {
  it('should update input value on type', async () => {
    render(<LoginForm />);

    const emailInput = screen.getByLabelText(/email/i);
    await userEvent.type(emailInput, 'test@example.com');

    expect(emailInput).toHaveValue('test@example.com');
  });

  it('should submit form with correct data', async () => {
    const onSubmit = vi.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com');
    await userEvent.type(screen.getByLabelText(/password/i), 'password123');
    await userEvent.click(screen.getByRole('button', { name: /submit/i }));

    expect(onSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123',
    });
  });
});
```

### Testing with Context

```typescript
import { render } from '@testing-library/react';
import { AuthContext } from './AuthContext';

const renderWithAuth = (component: React.ReactElement, authValue = {}) => {
  return render(
    <AuthContext.Provider value={authValue}>
      {component}
    </AuthContext.Provider>
  );
};

describe('Protected Component', () => {
  it('should show content when authenticated', () => {
    const { getByText } = renderWithAuth(
      <ProtectedContent />,
      { isAuthenticated: true, user: { name: 'John' } }
    );

    expect(getByText(/welcome, john/i)).toBeInTheDocument();
  });

  it('should redirect when not authenticated', () => {
    const { queryByText } = renderWithAuth(
      <ProtectedContent />,
      { isAuthenticated: false }
    );

    expect(queryByText(/welcome/i)).not.toBeInTheDocument();
  });
});
```

### Testing Custom Hooks

```typescript
import { renderHook, act } from '@testing-library/react';

describe('useCounter Hook', () => {
  it('should initialize with default value', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);
  });

  it('should increment counter', () => {
    const { result } = renderHook(() => useCounter());

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('should reset counter', () => {
    const { result } = renderHook(() => useCounter(10));

    act(() => {
      result.current.reset();
    });

    expect(result.current.count).toBe(0);
  });
});
```

## Coverage

### Running with Coverage

```bash
# Jest
npm test -- --coverage

# Vitest
npm run vitest -- --coverage

# Generate HTML report
npm test -- --coverage --coverageReporters=html
```

### Coverage Configuration

**Jest (package.json):**
```json
{
  "jest": {
    "collectCoverageFrom": [
      "src/**/*.{ts,tsx}",
      "!src/**/*.d.ts",
      "!src/**/*.stories.tsx",
      "!src/index.tsx"
    ],
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

**Vitest (vitest.config.ts):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'json-summary'],
      exclude: [
        '**/*.test.ts',
        '**/*.spec.ts',
        '**/types/**',
        '**/*.d.ts',
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});
```

## Best Practices

### 1. Test Behavior, Not Implementation

```typescript
// ❌ Testing implementation details
it('should set loading state to true', () => {
  const component = new MyComponent();
  component.fetchData();
  expect(component.loading).toBe(true);
});

// ✅ Testing behavior
it('should show loading spinner while fetching', () => {
  render(<MyComponent />);
  expect(screen.getByRole('progressbar')).toBeInTheDocument();
});
```

### 2. Use Accessible Queries

```typescript
// ❌ Avoid querySelector and testId when possible
const button = container.querySelector('.submit-button');
const heading = getByTestId('page-heading');

// ✅ Use accessible queries
const button = screen.getByRole('button', { name: /submit/i });
const heading = screen.getByRole('heading', { level: 1 });
const input = screen.getByLabelText(/email/i);
```

### 3. Test One Thing Per Test

```typescript
// ❌ Testing multiple scenarios
it('should handle form submission', async () => {
  // Tests both success and error cases
  // Tests validation
  // Tests loading state
});

// ✅ Separate tests for each scenario
it('should submit form successfully', async () => {
  // Only test success case
});

it('should show error on failed submission', async () => {
  // Only test error case
});

it('should validate input before submission', async () => {
  // Only test validation
});
```

### 4. Avoid Test Interdependence

```typescript
// ❌ Tests depend on order
let userId: string;

it('should create user', () => {
  userId = createUser().id;
});

it('should fetch user', () => {
  const user = getUser(userId); // Depends on previous test
});

// ✅ Each test is independent
it('should create user', () => {
  const userId = createUser().id;
  expect(userId).toBeDefined();
});

it('should fetch user', () => {
  const userId = createUser().id;
  const user = getUser(userId);
  expect(user.id).toBe(userId);
});
```

### 5. Use TypeScript for Type Safety

```typescript
// ✅ Typed test data
interface User {
  id: string;
  email: string;
  role: 'admin' | 'user';
}

const createMockUser = (overrides?: Partial<User>): User => ({
  id: '123',
  email: 'test@example.com',
  role: 'user',
  ...overrides,
});

it('should handle admin user', () => {
  const admin = createMockUser({ role: 'admin' });
  // TypeScript ensures correct types
});
```

## Common Patterns

### Testing Error Boundaries

```typescript
import { ErrorBoundary } from './ErrorBoundary';

it('should catch and display error', () => {
  const ThrowError = () => {
    throw new Error('Test error');
  };

  render(
    <ErrorBoundary>
      <ThrowError />
    </ErrorBoundary>
  );

  expect(screen.getByText(/something went wrong/i)).toBeInTheDocument();
});
```

### Testing with Timers

```typescript
import { vi } from 'vitest';

it('should debounce input', async () => {
  vi.useFakeTimers();
  const onChange = vi.fn();

  render(<SearchInput onChange={onChange} />);

  const input = screen.getByRole('textbox');
  await userEvent.type(input, 'test');

  // Fast-forward time
  vi.advanceTimersByTime(500);

  expect(onChange).toHaveBeenCalledWith('test');

  vi.useRealTimers();
});
```

### Snapshot Testing

```typescript
it('should match snapshot', () => {
  const { container } = render(<Button variant="primary">Click me</Button>);

  expect(container.firstChild).toMatchSnapshot();
});

// Update snapshots with: npm test -- -u
```

## References

- **Vitest:** https://vitest.dev
- **Jest:** https://jestjs.io
- **React Testing Library:** https://testing-library.com/react
- **Testing Library Queries:** https://testing-library.com/docs/queries/about
- **User Event:** https://testing-library.com/docs/user-event/intro
