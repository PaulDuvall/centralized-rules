# Go Coding Standards

Standards for Go 1.20+ following Effective Go and Go Code Review Comments.

## Table of Contents

- [Project Structure](#project-structure)
- [Naming Conventions](#naming-conventions)
- [Code Formatting](#code-formatting)
- [Error Handling](#error-handling)
- [Concurrency](#concurrency)
- [Interfaces and Composition](#interfaces-and-composition)
- [Package Design](#package-design)
- [Performance](#performance)

---

## Project Structure

```
myproject/
├── cmd/                    # Application entry points
├── internal/               # Private code (not importable)
├── pkg/                    # Public library code
├── api/                    # API definitions
├── configs/                # Configuration files
├── scripts/                # Build and automation
├── deployments/            # Infrastructure
├── test/                   # Test data and fixtures
├── docs/                   # Documentation
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

Use `internal/` for private code, `pkg/` for public APIs. Avoid deep nesting.

---

## Naming Conventions

**Packages:** Lowercase, single-word, singular form. No underscores or capitals.
```go
package user      // Good
package users     // Bad: plural
package user_service  // Bad: underscore
```

**Functions/Methods:** Exported = PascalCase, Unexported = camelCase.
```go
func NewUser(name string) *User {}      // Exported
func validateEmail(email string) bool {} // Unexported
```

**Variables:** Short for locals (`i`, `err`), descriptive for package-level. Acronyms uppercase.
```go
var userID int           // Good
var db *sql.DB           // Good
var user_id int          // Bad: underscore
var HttpStatus int       // Bad: acronym mixed case
```

**Constants:**
```go
const MaxRetries = 3
const bufferSize = 1024  // Unexported
```

**Interfaces:** Single-method = "-er" suffix. Keep to 1-3 methods.
```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

type UserRepository interface {
    Find(id int) (*User, error)
    Save(user *User) error
}

## Code Formatting

**Formatting:** Use `gofmt -w .` and `goimports -w .` before commit.

**Imports:** Group by standard library, third-party, local packages.
```go
import (
    "fmt"
    "time"

    "github.com/user/pkg"

    "myproject/internal/service"
)
```

**Line Length:** Keep under 120 characters. Break long signatures and chains.
```go
func NewUserService(
    repo UserRepository,
    logger Logger,
) *UserService {
    return &UserService{repo: repo, logger: logger}
}
```

**Comments:**
- Package: `// Package name describes purpose.`
- Exported: Must have doc comment starting with name
- Wrap at ~80 characters

---

## Error Handling

**Check errors:** Never use `_` to ignore errors.
```go
file, err := os.Open("config.json")
if err != nil {
    return nil, fmt.Errorf("open config: %w", err)
}
defer file.Close()
```

**Wrap with `%w`:** Use `fmt.Errorf()` with `%w` for error chain.
```go
if err != nil {
    return nil, fmt.Errorf("operation: %w", err)
}
```

**Sentinel errors:** Define at package level for known error cases.
```go
var (
    ErrNotFound = errors.New("not found")
    ErrInvalid  = errors.New("invalid")
)

if errors.Is(err, ErrNotFound) {
    // Handle
}
```

**Custom types:** For domain-specific errors.
```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s: %s", e.Field, e.Message)
}
```

**Panic:** Only for unrecoverable errors (programming bugs). Return errors for runtime issues.

---

## Concurrency

**Goroutines:** Use `sync.WaitGroup` for synchronization. Pass data as parameters to avoid closure issues.
```go
var wg sync.WaitGroup
for _, item := range items {
    wg.Add(1)
    go func(item Item) {
        defer wg.Done()
        process(item)
    }(item)
}
wg.Wait()
```

**Context:** For cancellation and timeouts.
```go
select {
case <-ctx.Done():
    return
default:
    // Work
}
```

**Channels:** Specify direction. Only sender closes.
```go
ch := make(chan int, 10)      // Buffered
func send(ch chan<- int) {}    // Send-only
func recv(ch <-chan int) {}    // Receive-only
defer close(ch)               // Close from sender
```

**Mutexes:** Protect shared state. Use `RWMutex` for read-heavy access.
```go
type Counter struct {
    mu    sync.Mutex
    value int
}

func (c *Counter) Increment() {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.value++
}
```

**Race detection:** Test with `go test -race ./...`

---

## Interfaces and Composition

**Small interfaces:** Keep 1-3 methods. Single-method interfaces end in "-er".
```go
type Reader interface {
    Read(p []byte) (n int, err error)
}
```

**Accept interfaces, return structs:**
```go
func SaveUser(repo UserRepository, user *User) error {
    return repo.Save(user)
}

func NewUser(name string) *User {
    return &User{Name: name}
}
```

**Composition:** Embed interfaces to combine behaviors.
```go
type Service struct {
    logger Logger
    db     *sql.DB
}

type TimestampedLogger struct {
    Logger
}

func (t *TimestampedLogger) Log(message string) {
    t.Logger.Log(fmt.Sprintf("[%s] %s", time.Now(), message))
}
```

---

## Package Design

**Cohesion:** One concept per package. Avoid mixing unrelated concerns.
```
Good:
package user    // user.go, repository.go, service.go
package order   // order.go, repository.go, service.go

Bad:
package utils   // Too generic, mixed concerns
```

**No circular dependencies:** Extract common types if needed.
```
Good:
package domain  // Shared types (User, Order)
package user    // Uses domain
package order   // Uses domain

Bad:
package user imports order
package order imports user
```

**Internal packages:** Use `internal/` for private code. Use `pkg/` for public libraries.

---

## Performance

**Pre-allocate slices:** Avoid repeated allocations.
```go
// Good
result := make([]int, 0, len(items))
for _, item := range items {
    result = append(result, item*2)
}

// Bad
result := []int{}  // Reallocates on each append
```

**Use `strings.Builder`:** For string concatenation.
```go
var builder strings.Builder
for _, word := range words {
    builder.WriteString(word)
}
return builder.String()
```

**Avoid defer in hot paths:** Has small overhead. Use sparingly in tight loops.

**Benchmark:** Use `go test -bench=. -benchmem` to measure performance.

**Profile:** Use `go test -cpuprofile=cpu.prof -bench=.` and `go tool pprof cpu.prof`.

---

## Summary

1. Format with `gofmt` and `goimports`
2. Always check errors, never ignore with `_`
3. Follow Go naming conventions
4. Use goroutines safely, test with `-race`
5. Write small, focused interfaces
6. One concept per package, no circular dependencies
7. Document all exported names
8. See testing.md for testing guidelines
