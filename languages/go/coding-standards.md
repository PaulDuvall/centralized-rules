# Go Coding Standards

Comprehensive coding standards for Go following Effective Go, Go Code Review Comments, and community best practices.

## Table of Contents

- [Project Structure](#project-structure)
- [Naming Conventions](#naming-conventions)
- [Code Formatting](#code-formatting)
- [Error Handling](#error-handling)
- [Concurrency](#concurrency)
- [Interfaces and Composition](#interfaces-and-composition)
- [Package Design](#package-design)
- [Performance Best Practices](#performance-best-practices)

---

## Project Structure

### Standard Go Project Layout

```
myproject/
├── cmd/                    # Main applications
│   └── myapp/
│       └── main.go
├── internal/               # Private application and library code
│   ├── service/
│   └── repository/
├── pkg/                    # Public library code
│   └── api/
├── api/                    # API definitions (OpenAPI, Protocol Buffers)
├── web/                    # Web application assets
├── configs/                # Configuration files
├── scripts/                # Build, install, analysis scripts
├── build/                  # Packaging and CI
├── deployments/            # IaaS, PaaS, container orchestration
├── test/                   # External test data and apps
├── docs/                   # Documentation
├── go.mod                  # Go module file
├── go.sum                  # Go checksum file
├── Makefile                # Build automation
└── README.md
```

**Key Principles:**
- `cmd/`: Entry points for applications
- `internal/`: Code that cannot be imported by other projects
- `pkg/`: Code that can be imported by external projects (use sparingly)
- Avoid deeply nested directory structures

---

## Naming Conventions

### Packages

**Rules:**
- Short, concise, lowercase names
- No underscores or mixedCaps
- Single-word names preferred
- Use singular form (not plural)

```go
// Good
package user
package http
package auth

// Bad
package user_service  // No underscores
package users         // Use singular
package UserService   // No capitals
```

### Functions and Methods

**MixedCaps (camelCase or PascalCase):**
- Exported: `PascalCase` (starts with capital)
- Unexported: `camelCase` (starts with lowercase)

```go
// Exported - visible outside package
func NewUser(name string) *User { }
func (u *User) GetEmail() string { }

// Unexported - package-private
func validateEmail(email string) bool { }
func (u *User) calculateAge() int { }
```

### Variables

**Naming Guidelines:**
- Short names for local variables (`i`, `n`, `err`)
- Descriptive names for package-level variables
- Acronyms should be uppercase (`userID`, `httpServer`, `URL`)

```go
// Good
var userID int
var HTTPStatus int
var db *sql.DB

for i, user := range users {
    // Short loop variables
}

// Bad
var user_id int        // No underscores
var HttpStatus int     // Acronym should be all caps
var database *sql.DB   // Too verbose for common usage
```

### Constants

```go
// Exported constants
const MaxRetries = 3
const DefaultTimeout = 30 * time.Second

// Unexported constants
const bufferSize = 1024

// Enumerated constants (iota)
type Status int

const (
    StatusPending Status = iota
    StatusActive
    StatusInactive
)
```

### Interfaces

**Rules:**
- Single-method interfaces end in "-er"
- Prefer small interfaces (1-3 methods)

```go
// Good
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

type ReadWriter interface {
    Reader
    Writer
}

// Custom interfaces
type UserRepository interface {
    Find(id int) (*User, error)
    Save(user *User) error
}
```

---

## Code Formatting

### Use gofmt

**Rule:** Always run `gofmt` before committing. Configure your editor to format on save.

```bash
# Format all Go files
gofmt -w .

# Format with simplification
gofmt -s -w .
```

### Imports

**Grouping:** Standard library, third-party, local

```go
import (
    // Standard library
    "context"
    "fmt"
    "time"

    // Third-party
    "github.com/gin-gonic/gin"
    "gorm.io/gorm"

    // Local
    "myproject/internal/service"
    "myproject/pkg/api"
)
```

**Use goimports:**
```bash
# Automatically adds/removes imports
goimports -w .
```

### Line Length

- **Guideline:** Keep lines under 100-120 characters
- Break long function calls and signatures

```go
// Good
func NewUserService(
    repo UserRepository,
    logger Logger,
    config *Config,
) *UserService {
    return &UserService{
        repo:   repo,
        logger: logger,
        config: config,
    }
}

// Long method chains - one call per line
user, err := repo.
    WithContext(ctx).
    Where("age > ?", 18).
    Order("created_at DESC").
    First()
```

### Comments

**Package Comments:**
```go
// Package user provides user management functionality.
//
// It handles user authentication, profile management, and
// authorization across the application.
package user
```

**Function Comments:**
```go
// NewUser creates a new user with the given name and email.
// It returns an error if the email is invalid or already exists.
func NewUser(name, email string) (*User, error) {
    // Implementation
}
```

**Comment Style:**
- Full sentences starting with the name being documented
- Exported names must have doc comments
- Comment text should wrap at ~80 characters

---

## Error Handling

### Error Checking

**Always check errors:**
```go
// Good
file, err := os.Open("config.json")
if err != nil {
    return nil, fmt.Errorf("failed to open config: %w", err)
}
defer file.Close()

// Bad
file, _ := os.Open("config.json")  // Never ignore errors
```

### Error Wrapping

**Use `%w` for error wrapping (Go 1.13+):**
```go
func loadConfig(path string) (*Config, error)  {
    file, err := os.Open(path)
    if err != nil {
        return nil, fmt.Errorf("loading config from %s: %w", path, err)
    }
    defer file.Close()

    var config Config
    if err := json.NewDecoder(file).Decode(&config); err != nil {
        return nil, fmt.Errorf("parsing config: %w", err)
    }

    return &config, nil
}

// Caller can use errors.Is() and errors.As()
if errors.Is(err, os.ErrNotExist) {
    // Handle missing file
}
```

### Custom Errors

```go
// Sentinel errors (package-level)
var (
    ErrUserNotFound = errors.New("user not found")
    ErrInvalidEmail = errors.New("invalid email address")
)

// Custom error types
type ValidationError struct {
    Field string
    Value interface{}
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation failed for %s: %s", e.Field, e.Message)
}

// Usage
func ValidateUser(user *User) error {
    if user.Email == "" {
        return &ValidationError{
            Field:   "email",
            Value:   "",
            Message: "email is required",
        }
    }
    return nil
}
```

### Panic and Recover

**Rule:** Use panic only for unrecoverable errors (programming bugs, not runtime errors)

```go
// Good: Return error
func divide(a, b int) (int, error) {
    if b == 0 {
        return 0, errors.New("division by zero")
    }
    return a / b, nil
}

// Bad: Don't panic for expected errors
func divide(a, b int) int {
    if b == 0 {
        panic("division by zero")  // Bad!
    }
    return a / b
}

// Acceptable panic use: programming errors
func mustGetEnv(key string) string {
    value := os.Getenv(key)
    if value == "" {
        panic(fmt.Sprintf("required environment variable %s is not set", key))
    }
    return value
}
```

---

## Concurrency

### Goroutines

**Safe Concurrency Patterns:**

```go
// Use WaitGroup for synchronization
func processItems(items []Item) {
    var wg sync.WaitGroup

    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()
            process(item)
        }(item)  // Pass item as parameter to avoid closure issues
    }

    wg.Wait()
}

// Use context for cancellation
func worker(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return  // Context cancelled
        default:
            // Do work
        }
    }
}
```

### Channels

**Channel Patterns:**

```go
// Buffered vs Unbuffered
ch := make(chan int)      // Unbuffered - blocks until receiver ready
ch := make(chan int, 10)  // Buffered - blocks only when full

// Direction specification
func send(ch chan<- int) {  // Send-only
    ch <- 42
}

func receive(ch <-chan int) {  // Receive-only
    val := <-ch
}

// Close channels (only sender should close)
func producer(ch chan<- int) {
    defer close(ch)
    for i := 0; i < 10; i++ {
        ch <- i
    }
}

// Range over channel
for val := range ch {
    fmt.Println(val)
}
```

### Mutexes

**Protect shared state:**

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

func (c *Counter) Value() int {
    c.mu.Lock()
    defer c.mu.Unlock()
    return c.value
}

// RWMutex for read-heavy workloads
type Cache struct {
    mu   sync.RWMutex
    data map[string]string
}

func (c *Cache) Get(key string) string {
    c.mu.RLock()
    defer c.mu.RUnlock()
    return c.data[key]
}

func (c *Cache) Set(key, value string) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.data[key] = value
}
```

### Avoid Race Conditions

```bash
# Test with race detector
go test -race ./...
go build -race
```

---

## Interfaces and Composition

### Interface Design

**Prefer small interfaces:**

```go
// Good: Small, focused interfaces
type Stringer interface {
    String() string
}

type Reader interface {
    Read(p []byte) (n int, err error)
}

// Bad: Large interfaces
type UserService interface {
    CreateUser(...) error
    UpdateUser(...) error
    DeleteUser(...) error
    FindUser(...) error
    ListUsers(...) error
    ValidateUser(...) error
    // Too many methods!
}
```

**Accept interfaces, return structs:**

```go
// Good
func SaveUser(repo UserRepository, user *User) error {
    return repo.Save(user)  // Accept interface
}

func NewUser(name string) *User {
    return &User{Name: name}  // Return concrete type
}
```

### Composition Over Inheritance

```go
// Embed to compose behavior
type Logger interface {
    Log(message string)
}

type Service struct {
    logger Logger
    db     *sql.DB
}

// Struct embedding
type TimestampedLogger struct {
    Logger  // Embedded interface
}

func (t *TimestampedLogger) Log(message string) {
    t.Logger.Log(fmt.Sprintf("[%s] %s", time.Now(), message))
}
```

---

## Package Design

### Package Cohesion

**One concept per package:**

```go
// Good package organization
package user
    - user.go          // User type
    - repository.go    // UserRepository interface
    - service.go       // UserService
    - validator.go     // Validation logic

// Bad: mixing unrelated concepts
package utils
    - string_helpers.go
    - date_helpers.go
    - http_helpers.go  // Too generic!
```

### Package Dependencies

**Avoid circular dependencies:**

```
❌ Bad:
package user imports package order
package order imports package user

✅ Good:
Extract common types to shared package
package domain (User, Order types)
package user (uses domain)
package order (uses domain)
```

### Internal Packages

**Use `internal/` for private code:**

```
myproject/
├── internal/
│   └── user/         # Cannot be imported by other projects
│       └── service.go
└── pkg/
    └── api/          # Can be imported externally
        └── client.go
```

---

## Performance Best Practices

### Avoid Allocations

```go
// Bad: Creates new slice on every call
func processItems(items []int) []int {
    result := []int{}  // Creates allocation
    for _, item := range items {
        result = append(result, item * 2)
    }
    return result
}

// Good: Pre-allocate
func processItems(items []int) []int {
    result := make([]int, 0, len(items))
    for _, item := range items {
        result = append(result, item * 2)
    }
    return result
}
```

### String Building

```go
// Bad: String concatenation creates many allocations
func buildString(words []string) string {
    result := ""
    for _, word := range words {
        result += word + " "  // Allocates new string each iteration
    }
    return result
}

// Good: Use strings.Builder
func buildString(words []string) string {
    var builder strings.Builder
    for _, word := range words {
        builder.WriteString(word)
        builder.WriteString(" ")
    }
    return builder.String()
}
```

### Defer Overhead

```go
// Defer has small overhead - avoid in tight loops
func processLarge(items []Item) {
    for _, item := range items {
        mutex.Lock()
        // process
        mutex.Unlock()  // Don't use defer in hot path
    }
}

// Use defer for normal cases
func readFile(path string) error {
    file, err := os.Open(path)
    if err != nil {
        return err
    }
    defer file.Close()  // Fine for non-hot path
    // ...
}
```

### Benchmark

```bash
# Run benchmarks
go test -bench=. -benchmem

# Profile CPU
go test -cpuprofile=cpu.prof -bench=.
go tool pprof cpu.prof
```

---

## Code Quality Tools

### Linting

```bash
# golangci-lint (comprehensive)
golangci-lint run

# Individual linters
go vet ./...          # Official Go tool
staticcheck ./...     # Advanced static analysis
```

### Configuration: `.golangci.yml`

```yaml
linters:
  enable:
    - gofmt
    - goimports
    - govet
    - errcheck
    - staticcheck
    - gosimple
    - ineffassign
    - unused
    - misspell
    - goconst
```

---

## Summary: Key Rules

1. **Formatting:** Always use `gofmt` and `goimports`
2. **Errors:** Always check errors, never use `_`
3. **Naming:** Follow Go conventions (mixedCaps, short names)
4. **Concurrency:** Use goroutines safely, test with `-race`
5. **Interfaces:** Small, focused, accept interfaces/return structs
6. **Packages:** One concept per package, avoid circular dependencies
7. **Comments:** Document all exported names
8. **Testing:** Write table-driven tests (see testing.md)
9. **Dependencies:** Use Go modules, vendor when necessary
10. **Performance:** Profile before optimizing, use benchmarks

---

## Related Resources

- **Official:**
  - [Effective Go](https://golang.org/doc/effective_go)
  - [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
  - [Go Modules Reference](https://golang.org/ref/mod)

- **Related Rules:**
  - See `languages/go/testing.md` for testing guidelines
  - See `base/architecture-principles.md` for general design patterns
