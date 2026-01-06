# TypeScript Testing Standards

> **Language:** TypeScript 5.0+ | **Frameworks:** Jest, Vitest, React Testing Library | **Scope:** All TypeScript projects

## Frameworks

### Jest

**Installation & config:**
```bash
npm install --save-dev jest @types/jest ts-jest
```

```javascript
// jest.config.js
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src', '<rootDir>/tests'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  collectCoverageFrom: ['src/**/*.ts', '!src/**/*.d.ts'],
  coverageThreshold: { global: { branches: 80, functions: 80, lines: 80, statements: 80 } },
};
```

**Commands:**
```bash
npm test                           # Run all tests
npm test -- --coverage            # Run with coverage
npm test -- path/to/test.spec.ts # Run specific file
```

### Vitest

**Installation & config:**
```bash
npm install --save-dev vitest @vitest/ui
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    coverage: { provider: 'v8', reporter: ['text', 'html'], exclude: ['**/*.test.ts', '**/types/**'] },
  },
});
```

**Commands:**
```bash
npm run vitest          # Run tests
npm run vitest -- --ui  # Run with UI
```

## Test Structure

**File organization:**
```
src/
├── Button.tsx
├── Button.test.tsx
├── utils/
│   ├── formatters.ts
│   └── formatters.test.ts
└── services/
    ├── api.ts
    └── api.test.ts
```

**Naming:** Suffix files with `.test.ts` or `.spec.ts` | Co-locate with source or use `tests/` directory

**Descriptive names:**
```typescript
describe('Calculator', () => {
  it('should add two positive numbers correctly', () => { expect(add(2, 3)).toBe(5); });
  it('should throw error when dividing by zero', () => { expect(() => divide(10, 0)).toThrow('Division by zero'); });
  // Avoid: it('works', () => { ... });
});
```

## Test Patterns

**Arrange-Act-Assert:**
```typescript
it('should create user with hashed password', () => {
  // Arrange
  const userData = { email: 'test@example.com', password: 'password123' };

  // Act
  const user = createUser(userData);

  // Assert
  expect(user.email).toBe('test@example.com');
  expect(user.password).not.toBe('password123');
});
```

**Type safety:**
```typescript
it('should have correct return type', () => {
  const result = parseUser({ name: 'John', age: 30 });
  expectTypeOf(result).toEqualTypeOf<User>();
  expect(result).toHaveProperty('name');
});
```

**Exceptions:**
```typescript
it('should throw on invalid email', () => {
  expect(() => validateEmail('invalid')).toThrow('Invalid email format');
});

it('should handle async errors', async () => {
  await expect(fetchUser('invalid-id')).rejects.toThrow('User not found');
});
```

**Test fixtures:**
```typescript
describe('Database Operations', () => {
  let db: Database;

  beforeEach(async () => {
    db = await createTestDatabase();
    await db.migrate();
  });

  afterEach(async () => {
    await db.rollback();
    await db.close();
  });

  it('should insert user', async () => {
    const user = await db.users.create({ email: 'test@example.com', name: 'Test User' });
    expect(user.id).toBeDefined();
  });
});
```

**Parametrized tests:**
```typescript
it.each([
  ['valid@email.com', true],
  ['invalid-email', false],
  ['', false],
])('validates email "%s" as %s', (email, isValid) => {
  expect(validateEmail(email)).toBe(isValid);
});
```

## Mocking

**Mock functions:**
```typescript
const mockFetch = vi.fn().mockResolvedValue({
  ok: true,
  json: async () => ({ data: 'test' }),
});
global.fetch = mockFetch;
await fetchData('https://api.example.com/data');
expect(mockFetch).toHaveBeenCalledWith('https://api.example.com/data');
```

**Mock modules:**
```typescript
vi.mock('./logger', () => ({
  log: vi.fn(),
  error: vi.fn(),
}));

describe('User Service', () => {
  it('should log user creation', async () => {
    const { log } = await import('./logger');
    await createUser({ email: 'test@example.com' });
    expect(log).toHaveBeenCalledWith('User created: test@example.com');
  });
});
```

**Partial mocks:**
```typescript
vi.spyOn(utils, 'formatDate').mockReturnValue('2024-01-01');
expect(utils.formatDate(new Date())).toBe('2024-01-01');
expect(utils.capitalize('test')).toBe('Test'); // Unmocked
```

## Async Testing

**Promises:**
```typescript
it('should resolve with user data', async () => {
  const user = await fetchUser('123');
  expect(user.id).toBe('123');
});

it('should reject with error', async () => {
  await expect(fetchUser('invalid')).rejects.toThrow('User not found');
});
```

**Wait for DOM updates:**
```typescript
import { waitFor } from '@testing-library/react';

it('should update state after async operation', async () => {
  const { getByText } = render(<AsyncComponent />);
  await waitFor(() => {
    expect(getByText('Data loaded')).toBeInTheDocument();
  }, { timeout: 3000 });
});
```

## React Testing Library

**Component rendering:**
```typescript
describe('Button Component', () => {
  it('should render with correct text', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button', { name: /click me/i })).toBeInTheDocument();
  });

  it('should call onClick when clicked', async () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Click me</Button>);
    await userEvent.click(screen.getByRole('button'));
    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
```

**Form interactions:**
```typescript
it('should submit form with correct data', async () => {
  const onSubmit = vi.fn();
  render(<LoginForm onSubmit={onSubmit} />);

  await userEvent.type(screen.getByLabelText(/email/i), 'test@example.com');
  await userEvent.type(screen.getByLabelText(/password/i), 'password123');
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  expect(onSubmit).toHaveBeenCalledWith({ email: 'test@example.com', password: 'password123' });
});
```

**Context provider:**
```typescript
const renderWithAuth = (component: React.ReactElement, authValue = {}) => {
  return render(
    <AuthContext.Provider value={authValue}>{component}</AuthContext.Provider>
  );
};

it('should show content when authenticated', () => {
  const { getByText } = renderWithAuth(
    <ProtectedContent />,
    { isAuthenticated: true, user: { name: 'John' } }
  );
  expect(getByText(/welcome, john/i)).toBeInTheDocument();
});
```

**Custom hooks:**
```typescript
it('should increment counter', () => {
  const { result } = renderHook(() => useCounter());
  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
});
```

## Coverage

**Run coverage:**
```bash
npm test -- --coverage          # Jest
npm run vitest -- --coverage    # Vitest
```

**Configure thresholds (Jest):**
```json
{
  "jest": {
    "collectCoverageFrom": ["src/**/*.{ts,tsx}", "!src/**/*.d.ts"],
    "coverageThreshold": {
      "global": { "branches": 80, "functions": 80, "lines": 80, "statements": 80 }
    }
  }
}
```

**Configure thresholds (Vitest):**
```typescript
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      thresholds: { lines: 80, functions: 80, branches: 80, statements: 80 },
    },
  },
});
```

## Best Practices

**Test behavior, not implementation:**
```typescript
// AVOID: it('should set loading state to true', () => { ... });
// PREFER:
it('should show loading spinner while fetching', () => {
  render(<MyComponent />);
  expect(screen.getByRole('progressbar')).toBeInTheDocument();
});
```

**Use accessible queries:**
```typescript
// Avoid: container.querySelector('.button'), getByTestId()
// Prefer:
const button = screen.getByRole('button', { name: /submit/i });
const input = screen.getByLabelText(/email/i);
```

**One test per concept:**
```typescript
it('should submit form successfully', async () => { /* only success case */ });
it('should show error on failed submission', async () => { /* only error case */ });
it('should validate input before submission', async () => { /* only validation */ });
```

**Avoid test interdependence - each test must be independent:**
```typescript
// ✅ Each test creates needed data
it('should fetch user', () => {
  const userId = createUser().id;
  const user = getUser(userId);
  expect(user.id).toBe(userId);
});
```

**Type test data:**
```typescript
interface User { id: string; email: string; role: 'admin' | 'user'; }
const createMockUser = (overrides?: Partial<User>): User => ({
  id: '123',
  email: 'test@example.com',
  role: 'user',
  ...overrides,
});
it('should handle admin user', () => {
  const admin = createMockUser({ role: 'admin' });
});
```

## Common Patterns

**Error boundaries:**
```typescript
it('should catch and display error', () => {
  render(<ErrorBoundary><ThrowError /></ErrorBoundary>);
  expect(screen.getByText(/something went wrong/i)).toBeInTheDocument();
});
```

**Timers:**
```typescript
it('should debounce input', async () => {
  vi.useFakeTimers();
  render(<SearchInput onChange={onChange} />);
  await userEvent.type(screen.getByRole('textbox'), 'test');
  vi.advanceTimersByTime(500);
  expect(onChange).toHaveBeenCalledWith('test');
  vi.useRealTimers();
});
```

**Snapshots:**
```typescript
it('should match snapshot', () => {
  const { container } = render(<Button variant="primary">Click me</Button>);
  expect(container.firstChild).toMatchSnapshot();
});
```

## References

- Vitest: https://vitest.dev
- Jest: https://jestjs.io
- React Testing Library: https://testing-library.com/react
- Testing Library Queries: https://testing-library.com/docs/queries/about
