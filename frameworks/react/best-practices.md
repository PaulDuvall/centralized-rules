# React Best Practices

> **Framework:** React 18+
> **Applies to:** React and React-based frameworks (Next.js, Remix)

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

## References

- **React Documentation:** https://react.dev
- **React Testing Library:** https://testing-library.com/react
- **React TypeScript Cheatsheet:** https://react-typescript-cheatsheet.netlify.app
