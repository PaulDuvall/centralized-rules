# React Best Practices

> **When to apply:** All JavaScript/TypeScript applications using React framework
> **Framework:** React 18+, Next.js 14+
> **Language:** TypeScript/JavaScript

Production-ready React development with hooks, components, state management, performance optimization, and testing.

## Component Design

**Rule:** Use functional components with hooks. Define explicit prop types with TypeScript interfaces.

```typescript
interface UserCardProps {
    user: User;
    onEdit?: (user: User) => void;
    className?: string;
}

export function UserCard({ user, onEdit, className }: UserCardProps) {
    return <div className={className}>{user.name}</div>;
}
```

**File structure:**
```
components/
├── UserProfile/
│   ├── index.ts              # Barrel export
│   ├── UserProfile.tsx       # Main component
│   ├── UserProfile.test.tsx  # Tests
│   └── types.ts              # TypeScript types
```

## Hook Best Practices

### useState

**Rule:** Use functional updates for derived state. Never mutate state directly.

```typescript
const [count, setCount] = useState<number>(0);
const [user, setUser] = useState<User | null>(null);

// ✅ Functional update
setCount(prevCount => prevCount + 1);

// ❌ Direct mutation
// count = count + 1; // Wrong!
```

### useEffect

**Rule:** Include all dependencies. Return cleanup function for subscriptions.

```typescript
// ✅ Proper dependencies and cleanup
useEffect(() => {
    const subscription = api.subscribe(userId);
    return () => subscription.unsubscribe();
}, [userId]);

// ❌ Missing dependencies
useEffect(() => {
    fetchUser(userId); // userId not in deps!
}, []);
```

### Custom Hooks

**Rule:** Extract reusable logic into custom hooks. Prefix with "use".

```typescript
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

**Rule:** Use for expensive computations and callback stability. Don't overuse.

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

### useReducer

**Rule:** Use for complex state logic. Define action types with discriminated unions.

```typescript
type State = { count: number; step: number };
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
    </div>
  );
}
```

## State Management

**Rule:** Use local state first. Context for shared state. External libraries for complex global state.

```typescript
// Local state for component-specific data
function SearchInput() {
    const [query, setQuery] = useState('');
    return <input value={query} onChange={(e) => setQuery(e.target.value)} />;
}

// Context for app-wide state
const ThemeContext = createContext<Theme>('light');

function ThemeProvider({ children }: { children: React.ReactNode }) {
    const [theme, setTheme] = useState<Theme>('light');
    return (
        <ThemeContext.Provider value={{ theme, setTheme }}>
            {children}
        </ThemeContext.Provider>
    );
}
```

## Performance Optimization

**Rule:** Use React.memo to prevent unnecessary re-renders. Use code splitting for large components.

```typescript
// ✅ Memoized component
const UserCard = React.memo(({ user }: { user: User }) => {
    return <div>{user.name}</div>;
});

// ✅ Code splitting
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

**Rule:** Use Error Boundaries to catch rendering errors.

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

**Rule:** Test user behavior, not implementation. Use React Testing Library.

```typescript
import { render, screen, fireEvent } from '@testing-library/react';

test('renders user name', () => {
    const user = { id: '1', name: 'John Doe' };
    render(<UserCard user={user} />);
    expect(screen.getByText('John Doe')).toBeInTheDocument();
});

test('calls onEdit when button clicked', () => {
    const user = { id: '1', name: 'John Doe' };
    const onEdit = jest.fn();
    render(<UserCard user={user} onEdit={onEdit} />);
    fireEvent.click(screen.getByRole('button', { name: /edit/i }));
    expect(onEdit).toHaveBeenCalledWith(user);
});
```

## Accessibility

**Rule:** Use semantic HTML. Add ARIA attributes for non-semantic elements.

```typescript
// ✅ Semantic
<nav>
    <ul>
        <li><a href="/">Home</a></li>
    </ul>
</nav>

// ✅ ARIA for custom components
<button aria-label="Close dialog" onClick={onClose}>×</button>
<input type="text" aria-describedby="email-help" aria-invalid={!!error} />
```

## Common Pitfalls

**Rule:** Avoid inline functions and object creation in JSX. Use useCallback/useMemo.

```typescript
// ❌ Creates new function on every render
<button onClick={() => handleClick(id)}>Click</button>

// ✅ Use useCallback
const handleButtonClick = useCallback(() => handleClick(id), [id, handleClick]);
<button onClick={handleButtonClick}>Click</button>

// ❌ Creates new object on every render
<UserCard user={user} style={{ margin: 10 }} />

// ✅ Define outside
const cardStyle = { margin: 10 };
<UserCard user={user} style={cardStyle} />
```

## Forms

**Rule:** Use controlled components. Validate on submit. Show errors after user interaction.

```typescript
function LoginForm() {
  const [formData, setFormData] = useState({ email: '', password: '' });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
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
    if (!formData.email) newErrors.email = 'Email required';
    if (!formData.password) newErrors.password = 'Password required';

    if (Object.keys(newErrors).length > 0) {
      setErrors(newErrors);
      return;
    }

    // Submit
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="email" value={formData.email} onChange={handleChange} />
      {errors.email && <span>{errors.email}</span>}
      <input name="password" type="password" value={formData.password} onChange={handleChange} />
      {errors.password && <span>{errors.password}</span>}
      <button type="submit">Login</button>
    </form>
  );
}
```

## React Hook Form

**Rule:** Use for complex forms with validation.

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

type LoginFormData = z.infer<typeof loginSchema>;

function LoginForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<LoginFormData>({
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
      <button type="submit" disabled={isSubmitting}>Login</button>
    </form>
  );
}
```

## Data Fetching

**Rule:** Use SWR or React Query for server state management.

```typescript
import useSWR from 'swr';

const fetcher = (url: string) => fetch(url).then(r => r.json());

function UserProfile({ userId }: { userId: string }) {
  const { data, error, isLoading, mutate } = useSWR(`/api/users/${userId}`, fetcher);

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

## React Server Components

**Rule:** Use Server Components for data fetching. Client Components for interactivity.

```typescript
// ✅ Server Component (Next.js 13+)
// app/posts/page.tsx
async function PostsPage() {
  const posts = await fetch('https://api.example.com/posts').then(r => r.json());
  return (
    <div>
      {posts.map((post: Post) => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  );
}

// ✅ Client Component for interactivity
// components/LikeButton.tsx
'use client';

export function LikeButton({ postId }: { postId: string }) {
  const [liked, setLiked] = useState(false);
  return <button onClick={() => setLiked(!liked)}>{liked ? '❤️' : '🤍'}</button>;
}
```

## Routing

**Rule:** Use React Router for SPA. Next.js App Router for full-stack.

```typescript
// React Router
import { BrowserRouter, Routes, Route, Link } from 'react-router-dom';

function App() {
  return (
    <BrowserRouter>
      <nav>
        <Link to="/">Home</Link>
        <Link to="/about">About</Link>
      </nav>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/users/:id" element={<UserDetailPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </BrowserRouter>
  );
}

// Protected routes
function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user, loading } = useAuth();
  if (loading) return <div>Loading...</div>;
  if (!user) return <Navigate to="/login" replace />;
  return <>{children}</>;
}
```

## Styling

**Rule:** Choose one styling approach. Use CSS Modules for scoped styles, Tailwind for utility-first.

```typescript
// CSS Modules
import styles from './Button.module.css';

function Button({ children }: { children: React.ReactNode }) {
  return <button className={styles.button}>{children}</button>;
}

// Tailwind
function Card({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="rounded-lg border bg-card p-6 shadow-sm">
      <h3 className="text-2xl font-semibold">{title}</h3>
      <div className="mt-4 text-sm">{children}</div>
    </div>
  );
}
```

## Advanced Testing

**Rule:** Test custom hooks with renderHook. Mock API with MSW.

```typescript
import { renderHook, act } from '@testing-library/react';
import { rest } from 'msw';
import { setupServer } from 'msw/node';

// Test hooks
test('useCounter increments', () => {
  const { result } = renderHook(() => useCounter(0));
  act(() => result.current.increment());
  expect(result.current.count).toBe(1);
});

// Mock API
const server = setupServer(
  rest.get('/api/users', (req, res, ctx) => {
    return res(ctx.json([{ id: '1', name: 'John' }]));
  })
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test('loads users', async () => {
  render(<UserList />);
  await waitFor(() => expect(screen.getByText('John')).toBeInTheDocument());
});
```

## Related Resources

- `languages/typescript/coding-standards.md` - TypeScript patterns
- `languages/typescript/testing.md` - Testing strategies
- `base/architecture-principles.md` - Architecture patterns
