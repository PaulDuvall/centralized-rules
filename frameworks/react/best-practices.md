# React Best Practices

> **When to apply:** All JavaScript/TypeScript applications using React framework
> **Framework:** React 18+, Next.js 14+
> **Language:** TypeScript/JavaScript

Best practices for building production-ready React applications with hooks, components, state management, performance optimization, and testing.

## Component Design

### Functional Components with Hooks

Use functional components with hooks instead of class components:

```typescript
// ✅ Functional component with hooks
function UserProfile({ userId }: { userId: string }) {
    const [user, setUser] = useState<User | null>(null);

    useEffect(() => {
        fetchUser(userId).then(setUser);
    }, [userId]);

    return <div>{user?.name}</div>;
}

// ❌ Avoid class components (legacy)
class UserProfile extends React.Component {
    // ...
}
```

### Component File Structure

```
components/
├── UserProfile/
│   ├── index.ts              # Barrel export
│   ├── UserProfile.tsx       # Main component
│   ├── UserProfile.test.tsx  # Tests
│   ├── UserProfile.styles.ts # Styles
│   └── types.ts              # TypeScript types
```

### Props Interface

Always define explicit prop types:

```typescript
interface UserCardProps {
    user: User;
    onEdit?: (user: User) => void;
    className?: string;
}

export function UserCard({ user, onEdit, className }: UserCardProps) {
    return (
        <div className={className}>
            {/* Component content */}
        </div>
    );
}
```

## Hook Best Practices

### useState

```typescript
// ✅ Proper state initialization
const [count, setCount] = useState<number>(0);
const [user, setUser] = useState<User | null>(null);

// ✅ Functional updates for derived state
setCount(prevCount => prevCount + 1);

// ❌ Direct state mutation
// count = count + 1; // Wrong!
```

### useEffect

```typescript
// ✅ Proper effect with dependencies
useEffect(() => {
    const subscription = api.subscribe(userId);

    // Cleanup function
    return () => subscription.unsubscribe();
}, [userId]); // Dependencies array

// ❌ Missing dependencies
useEffect(() => {
    fetchUser(userId); // userId not in deps!
}, []);
```

### Custom Hooks

Extract reusable logic into custom hooks:

```typescript
// ✅ Custom hook
function useUser(userId: string) {
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<Error | null>(null);

    useEffect(() => {
        setLoading(true);
        fetchUser(userId)
            .then(setUser)
            .catch(setError)
            .finally(() => setLoading(false));
    }, [userId]);

    return { user, loading, error };
}

// Usage
function UserProfile({ userId }: { userId: string }) {
    const { user, loading, error } = useUser(userId);

    if (loading) return <Spinner />;
    if (error) return <Error error={error} />;
    return <div>{user?.name}</div>;
}
```

### useMemo and useCallback

Use for expensive computations and callback stability:

```typescript
// ✅ useMemo for expensive computation
const sortedUsers = useMemo(() => {
    return users.sort((a, b) => a.name.localeCompare(b.name));
}, [users]);

// ✅ useCallback for stable callbacks
const handleClick = useCallback((id: string) => {
    navigate(`/user/${id}`);
}, [navigate]);
```

## State Management

### Local State First

Use local state when data is component-specific:

```typescript
function SearchInput() {
    const [query, setQuery] = useState('');

    return (
        <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
        />
    );
}
```

### Context for Shared State

Use Context for app-wide or subtree state:

```typescript
const ThemeContext = createContext<Theme>('light');

function ThemeProvider({ children }: { children: React.ReactNode }) {
    const [theme, setTheme] = useState<Theme>('light');

    return (
        <ThemeContext.Provider value={{ theme, setTheme }}>
            {children}
        </ThemeContext.Provider>
    );
}

// Usage
function ThemedButton() {
    const { theme } = useContext(ThemeContext);
    return <button className={theme}>Click me</button>;
}
```

## Performance Optimization

### React.memo

Prevent unnecessary re-renders:

```typescript
// ✅ Memoized component
const UserCard = React.memo(({ user }: { user: User }) => {
    return <div>{user.name}</div>;
});

// Only re-renders when user changes
```

### Code Splitting

Use lazy loading for large components:

```typescript
import { lazy, Suspense } from 'react';

const HeavyComponent = lazy(() => import('./HeavyComponent'));

function App() {
    return (
        <Suspense fallback={<Spinner />}>
            <HeavyComponent />
        </Suspense>
    );
}
```

## Error Handling

### Error Boundaries

```typescript
class ErrorBoundary extends React.Component<
    { children: React.ReactNode },
    { hasError: boolean }
> {
    constructor(props) {
        super(props);
        this.state = { hasError: false };
    }

    static getDerivedStateFromError() {
        return { hasError: true };
    }

    componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
        console.error('Error caught:', error, errorInfo);
    }

    render() {
        if (this.state.hasError) {
            return <h1>Something went wrong.</h1>;
        }
        return this.props.children;
    }
}
```

## Testing

### Component Testing with React Testing Library

```typescript
import { render, screen, fireEvent } from '@testing-library/react';
import { UserCard } from './UserCard';

test('renders user name', () => {
    const user = { id: '1', name: 'John Doe' };
    render(<UserCard user={user} />);

    expect(screen.getByText('John Doe')).toBeInTheDocument();
});

test('calls onEdit when edit button clicked', () => {
    const user = { id: '1', name: 'John Doe' };
    const onEdit = jest.fn();

    render(<UserCard user={user} onEdit={onEdit} />);

    fireEvent.click(screen.getByRole('button', { name: /edit/i }));

    expect(onEdit).toHaveBeenCalledWith(user);
});
```

## Accessibility

### Semantic HTML

```typescript
// ✅ Semantic and accessible
<nav>
    <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
    </ul>
</nav>

// ❌ Non-semantic
<div className="nav">
    <div className="item" onClick={() => navigate('/')}>Home</div>
</div>
```

### ARIA Attributes

```typescript
<button
    aria-label="Close dialog"
    onClick={onClose}
>
    ×
</button>

<input
    type="text"
    aria-describedby="email-help"
    aria-invalid={!!error}
/>
```

## Common Pitfalls

### Avoid Inline Function Definitions in JSX

```typescript
// ❌ Creates new function on every render
<button onClick={() => handleClick(id)}>Click</button>

// ✅ Use useCallback
const handleButtonClick = useCallback(() => {
    handleClick(id);
}, [id, handleClick]);

<button onClick={handleButtonClick}>Click</button>
```

### Avoid Object Creation in JSX

```typescript
// ❌ Creates new object on every render
<UserCard user={user} style={{ margin: 10 }} />

// ✅ Define outside or use useMemo
const cardStyle = { margin: 10 };
<UserCard user={user} style={cardStyle} />
```

## Advanced Hook Patterns

### useReducer for Complex State

```typescript
// ✅ Use useReducer for complex state logic
type State = {
  count: number;
  step: number;
};

type Action =
  | { type: 'increment' }
  | { type: 'decrement' }
  | { type: 'setStep'; step: number };

function reducer(state: State, action: Action): State {
  switch (action.type) {
    case 'increment':
      return { ...state, count: state.count + state.step };
    case 'decrement':
      return { ...state, count: state.count - state.step };
    case 'setStep':
      return { ...state, step: action.step };
    default:
      return state;
  }
}

function Counter() {
  const [state, dispatch] = useReducer(reducer, { count: 0, step: 1 });

  return (
    <div>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({ type: 'increment' })}>+</button>
      <button onClick={() => dispatch({ type: 'decrement' })}>-</button>
      <input
        type="number"
        value={state.step}
        onChange={(e) => dispatch({ type: 'setStep', step: +e.target.value })}
      />
    </div>
  );
}
```

### useRef for DOM References and Mutable Values

```typescript
// ✅ DOM reference
function TextInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  const focusInput = () => {
    inputRef.current?.focus();
  };

  return (
    <>
      <input ref={inputRef} type="text" />
      <button onClick={focusInput}>Focus</button>
    </>
  );
}

// ✅ Mutable value that persists across renders
function Timer() {
  const intervalRef = useRef<number>();

  useEffect(() => {
    intervalRef.current = window.setInterval(() => {
      console.log('Tick');
    }, 1000);

    return () => clearInterval(intervalRef.current);
  }, []);

  return <div>Timer running</div>;
}
```

### useLayoutEffect for DOM Measurements

```typescript
// ✅ useLayoutEffect fires synchronously after DOM mutations
function Tooltip({ children }: { children: React.ReactNode }) {
  const [height, setHeight] = useState(0);
  const ref = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    if (ref.current) {
      setHeight(ref.current.offsetHeight);
    }
  }, [children]);

  return (
    <div ref={ref} style={{ marginTop: height }}>
      {children}
    </div>
  );
}
```

## Advanced Component Patterns

### Compound Components

```typescript
// ✅ Compound component pattern
const TabsContext = createContext<{
  activeTab: string;
  setActiveTab: (tab: string) => void;
} | null>(null);

function Tabs({ children }: { children: React.ReactNode }) {
  const [activeTab, setActiveTab] = useState('tab1');

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

function TabList({ children }: { children: React.ReactNode }) {
  return <div className="tab-list">{children}</div>;
}

function Tab({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('Tab must be used within Tabs');

  const { activeTab, setActiveTab } = context;

  return (
    <button
      className={activeTab === id ? 'active' : ''}
      onClick={() => setActiveTab(id)}
    >
      {children}
    </button>
  );
}

function TabPanel({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(TabsContext);
  if (!context) throw new Error('TabPanel must be used within Tabs');

  const { activeTab } = context;

  return activeTab === id ? <div className="tab-panel">{children}</div> : null;
}

// Attach subcomponents
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panel = TabPanel;

// Usage
<Tabs>
  <Tabs.List>
    <Tabs.Tab id="tab1">Tab 1</Tabs.Tab>
    <Tabs.Tab id="tab2">Tab 2</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panel id="tab1">Content 1</Tabs.Panel>
  <Tabs.Panel id="tab2">Content 2</Tabs.Panel>
</Tabs>
```

### Render Props Pattern

```typescript
// ✅ Render props for sharing logic
interface MousePosition {
  x: number;
  y: number;
}

function Mouse({ render }: { render: (pos: MousePosition) => React.ReactNode }) {
  const [position, setPosition] = useState<MousePosition>({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return <>{render(position)}</>;
}

// Usage
<Mouse render={({ x, y }) => (
  <div>Mouse at ({x}, {y})</div>
)} />
```

### Higher-Order Components (HOC)

```typescript
// ✅ HOC for adding functionality
function withLoading<P extends object>(
  Component: React.ComponentType<P>
) {
  return function WithLoadingComponent(
    props: P & { loading: boolean }
  ) {
    const { loading, ...rest } = props;

    if (loading) {
      return <div>Loading...</div>;
    }

    return <Component {...(rest as P)} />;
  };
}

// Usage
const UserListWithLoading = withLoading(UserList);

<UserListWithLoading users={users} loading={isLoading} />
```

## Forms Handling

### Controlled Components

```typescript
// ✅ Controlled form components
function LoginForm() {
  const [formData, setFormData] = useState({
    email: '',
    password: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));

    // Clear error on change
    if (errors[name]) {
      setErrors(prev => {
        const newErrors = { ...prev };
        delete newErrors[name];
        return newErrors;
      });
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    const newErrors: Record<string, string> = {};

    if (!formData.email) {
      newErrors.email = 'Email is required';
    }
    if (!formData.password) {
      newErrors.password = 'Password is required';
    }

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    // Submit form
    console.log('Submit:', formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <input
          type="email"
          name="email"
          value={formData.email}
          onChange={handleChange}
          aria-invalid={!!errors.email}
        />
        {errors.email && <span className="error">{errors.email}</span>}
      </div>

      <div>
        <input
          type="password"
          name="password"
          value={formData.password}
          onChange={handleChange}
          aria-invalid={!!errors.password}
        />
        {errors.password && <span className="error">{errors.password}</span>}
      </div>

      <button type="submit">Login</button>
    </form>
  );
}
```

### React Hook Form

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

// ✅ Schema-based validation
const loginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type LoginFormData = z.infer<typeof loginSchema>;

function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormData) => {
    await login(data);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} type="email" />
      {errors.email && <span>{errors.email.message}</span>}

      <input {...register('password')} type="password" />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
}
```

## Data Fetching

### SWR Pattern

```typescript
import useSWR from 'swr';

// ✅ Data fetching with SWR
const fetcher = (url: string) => fetch(url).then(r => r.json());

function UserProfile({ userId }: { userId: string }) {
  const { data, error, isLoading, mutate } = useSWR(
    `/api/users/${userId}`,
    fetcher,
    {
      revalidateOnFocus: false,
      dedupingInterval: 60000, // 1 minute
    }
  );

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div>
      <h1>{data.name}</h1>
      <button onClick={() => mutate()}>Refresh</button>
    </div>
  );
}
```

### React Query

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

// ✅ Data fetching with React Query
function UserList() {
  const queryClient = useQueryClient();

  const { data, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json()),
  });

  const deleteMutation = useMutation({
    mutationFn: (userId: string) =>
      fetch(`/api/users/${userId}`, { method: 'DELETE' }),
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['users'] });
    },
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading users</div>;

  return (
    <ul>
      {data.map((user: User) => (
        <li key={user.id}>
          {user.name}
          <button onClick={() => deleteMutation.mutate(user.id)}>
            Delete
          </button>
        </li>
      ))}
    </ul>
  );
}
```

## React Server Components (RSC)

### Server Components

```typescript
// ✅ Server Component (Next.js 13+)
// app/posts/page.tsx
async function PostsPage() {
  // Fetch data directly in Server Component
  const posts = await fetch('https://api.example.com/posts').then(r => r.json());

  return (
    <div>
      <h1>Posts</h1>
      {posts.map((post: Post) => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  );
}
```

### Client Components

```typescript
// ✅ Client Component for interactivity
// components/LikeButton.tsx
'use client';

import { useState } from 'react';

export function LikeButton({ postId }: { postId: string }) {
  const [liked, setLiked] = useState(false);

  return (
    <button onClick={() => setLiked(!liked)}>
      {liked ? '❤️' : '🤍'}
    </button>
  );
}
```

### Composition Pattern

```typescript
// ✅ Combine Server and Client Components
// app/posts/[id]/page.tsx
async function PostPage({ params }: { params: { id: string } }) {
  const post = await fetch(`/api/posts/${params.id}`).then(r => r.json());

  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.content}</p>
      {/* Client component for interactivity */}
      <LikeButton postId={post.id} />
    </article>
  );
}
```

## Styling Best Practices

### CSS Modules

```typescript
// ✅ CSS Modules for scoped styles
import styles from './Button.module.css';

function Button({ children }: { children: React.ReactNode }) {
  return (
    <button className={styles.button}>
      {children}
    </button>
  );
}
```

### Tailwind CSS

```typescript
// ✅ Utility-first CSS with Tailwind
function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border bg-card p-6 shadow-sm">
      <h3 className="text-2xl font-semibold leading-none tracking-tight">
        {title}
      </h3>
      <div className="mt-4 text-sm text-muted-foreground">
        {children}
      </div>
    </div>
  );
}
```

### CSS-in-JS (styled-components)

```typescript
import styled from 'styled-components';

// ✅ Styled components
const Button = styled.button<{ variant?: 'primary' | 'secondary' }>`
  padding: 0.5rem 1rem;
  border-radius: 0.25rem;
  font-weight: 500;
  border: none;
  cursor: pointer;

  background-color: ${props =>
    props.variant === 'primary' ? '#3b82f6' : '#6b7280'};
  color: white;

  &:hover {
    opacity: 0.9;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;

// Usage
<Button variant="primary">Click me</Button>
```

## Routing (React Router)

### Basic Routing

```typescript
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';

// ✅ React Router setup
function App() {
  return (
    <BrowserRouter>
      <nav>
        <Link to="/">Home</Link>
        <Link to="/about">About</Link>
        <Link to="/users">Users</Link>
      </nav>

      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/users" element={<UsersPage />} />
        <Route path="/users/:id" element={<UserDetailPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  );
}
```

### Protected Routes

```typescript
// ✅ Protected route component
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();

  if (loading) return <div>Loading...</div>;

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}

// Usage
<Route
  path="/dashboard"
  element={
    <ProtectedRoute>
      <DashboardPage />
    </ProtectedRoute>
  }
/>
```

## Advanced Testing

### Testing Custom Hooks

```typescript
import { renderHook, act } from '@testing-library/react';
import { useCounter } from './useCounter';

// ✅ Test custom hooks
test('useCounter increments', () => {
  const { result } = renderHook(() => useCounter(0));

  act(() => {
    result.current.increment();
  });

  expect(result.current.count).toBe(1);
});
```

### Testing Async Components

```typescript
import { render, screen, waitFor } from '@testing-library/react';
import { rest } from 'msw';
import { setupServer } from 'msw/node';

// ✅ Mock API with MSW
const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json([{ id: '1', name: 'John' }]));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('loads and displays users', async () => {
  render(<UserList />);

  await waitFor(() => {
    expect(screen.getByText('John')).toBeInTheDocument();
  });
});
```

### Component Snapshot Testing

```typescript
import { render } from '@testing-library/react';

// ✅ Snapshot testing
test('UserCard matches snapshot', () => {
  const user = { id: '1', name: 'John Doe', email: 'john@example.com' };
  const { container } = render(<UserCard user={user} />);

  expect(container.firstChild).toMatchSnapshot();
});
```

## Related Resources

- See `languages/typescript/coding-standards.md` for TypeScript patterns
- See `languages/typescript/testing.md` for testing strategies
- See `base/architecture-principles.md` for architecture patterns

## References

- **React Documentation:** https://react.dev
- **React Testing Library:** https://testing-library.com/react
- **React TypeScript Cheatsheet:** https://react-typescript-cheatsheet.netlify.app
