# Go Testing Standards

> **Language:** Go 1.20+
> **Framework:** testing (standard library), testify
> **Applies to:** All Go projects

## Go Testing Framework

### Standard Library `testing` Package

Go's built-in testing package provides comprehensive testing capabilities.

**Basic usage:**
```bash
# Run all tests
go test ./...

# Run tests with verbose output
go test -v ./...

# Run specific test
go test -v -run TestUserCreate

# Run with coverage
go test -cover ./...

# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# Run with race detector
go test -race ./...

# Run benchmarks
go test -bench=. ./...
```

### Testify - Enhanced Testing Library

Popular testing library that provides assertions and mocking.

**Installation:**
```bash
go get github.com/stretchr/testify
```

**Packages:**
- `assert` - Assertions without test termination
- `require` - Assertions that terminate test on failure
- `mock` - Mocking framework
- `suite` - Test suite support

## Test Structure

### File Organization

```
myproject/
├── cmd/
│   └── myapp/
│       └── main.go
├── internal/
│   ├── user/
│   │   ├── user.go
│   │   ├── user_test.go        # Unit tests
│   │   └── repository_test.go
│   └── service/
│       ├── service.go
│       └── service_test.go
├── pkg/
│   └── api/
│       ├── client.go
│       └── client_test.go
└── test/
    ├── integration/
    │   └── user_integration_test.go
    └── testdata/              # Test fixtures
        └── users.json
```

### Test File Naming

- Suffix test files with `_test.go`
- Place tests in the same package as the code
- Use `package <name>_test` for black-box testing
- Example: `user.go` → `user_test.go`

### Test Function Naming

```go
package user

import "testing"

// ✅ Descriptive test names
func TestCreateUser_WithValidEmail_ReturnsUser(t *testing.T) {
    // Test implementation
}

func TestValidateEmail_WithInvalidFormat_ReturnsError(t *testing.T) {
    // Test implementation
}

func TestUserRepository_FindByID_WhenNotFound_ReturnsError(t *testing.T) {
    // Test implementation
}

// ❌ Vague test names
func TestUser(t *testing.T) {
    // Unclear what's being tested
}

func TestFunction(t *testing.T) {
    // No context
}
```

## Test Patterns

### Basic Test Structure

```go
func TestCalculateTotal(t *testing.T) {
    // Arrange
    items := []Item{
        {Price: 10.00, Quantity: 2},
        {Price: 5.00, Quantity: 3},
    }

    // Act
    total := CalculateTotal(items)

    // Assert
    expected := 35.00
    if total != expected {
        t.Errorf("CalculateTotal() = %v, want %v", total, expected)
    }
}
```

### Table-Driven Tests

The idiomatic Go testing pattern for testing multiple scenarios.

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a        int
        b        int
        expected int
    }{
        {
            name:     "positive numbers",
            a:        2,
            b:        3,
            expected: 5,
        },
        {
            name:     "negative numbers",
            a:        -5,
            b:        -3,
            expected: -8,
        },
        {
            name:     "mixed signs",
            a:        10,
            b:        -4,
            expected: 6,
        },
        {
            name:     "zero values",
            a:        0,
            b:        0,
            expected: 0,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

### Using Testify Assertions

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestUserCreation(t *testing.T) {
    // assert - test continues on failure
    user := CreateUser("test@example.com")
    assert.NotNil(t, user)
    assert.Equal(t, "test@example.com", user.Email)
    assert.True(t, user.IsActive)

    // require - test stops on failure
    user2, err := CreateUserValidated("invalid-email")
    require.Error(t, err)
    require.Nil(t, user2)
}

func TestUserValidation_TableDriven(t *testing.T) {
    tests := []struct {
        name      string
        email     string
        wantError bool
    }{
        {"valid email", "test@example.com", false},
        {"invalid format", "not-an-email", true},
        {"empty email", "", true},
        {"missing domain", "test@", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantError {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

### Testing Error Cases

```go
func TestDivide_ByZero_ReturnsError(t *testing.T) {
    _, err := Divide(10, 0)

    // Standard library
    if err == nil {
        t.Error("expected error for division by zero")
    }

    // With testify
    require.Error(t, err)
    assert.Contains(t, err.Error(), "division by zero")
}

func TestLoadConfig_FileNotFound_ReturnsSpecificError(t *testing.T) {
    _, err := LoadConfig("nonexistent.json")

    // Check error type
    require.Error(t, err)
    assert.ErrorIs(t, err, os.ErrNotExist)
}

func TestValidateUser_InvalidEmail_ReturnsValidationError(t *testing.T) {
    err := ValidateUser(&User{Email: "invalid"})

    require.Error(t, err)

    var valErr *ValidationError
    assert.ErrorAs(t, err, &valErr)
    assert.Equal(t, "email", valErr.Field)
}
```

## Test Fixtures and Setup

### Setup and Teardown

```go
func TestMain(m *testing.M) {
    // Setup: runs before all tests
    setup()

    // Run tests
    code := m.Run()

    // Teardown: runs after all tests
    teardown()

    os.Exit(code)
}

func setup() {
    // Initialize test database, mock services, etc.
}

func teardown() {
    // Clean up resources
}
```

### Test Helpers

```go
// Helper function for test setup
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()  // Marks this as helper function

    db, err := sql.Open("sqlite3", ":memory:")
    require.NoError(t, err)

    // Run migrations
    err = runMigrations(db)
    require.NoError(t, err)

    // Cleanup after test
    t.Cleanup(func() {
        db.Close()
    })

    return db
}

func TestUserRepository(t *testing.T) {
    db := setupTestDB(t)
    repo := NewUserRepository(db)

    // Use repo in tests
}
```

### Test Fixtures (testdata)

```go
func loadTestData(t *testing.T, filename string) []byte {
    t.Helper()

    data, err := os.ReadFile(filepath.Join("testdata", filename))
    require.NoError(t, err)

    return data
}

func TestParseUsers(t *testing.T) {
    data := loadTestData(t, "users.json")

    users, err := ParseUsers(data)
    require.NoError(t, err)
    assert.Len(t, users, 3)
}
```

## Mocking

### Interface-Based Mocking

```go
// Define interface
type UserRepository interface {
    FindByID(id int) (*User, error)
    Save(user *User) error
}

// Mock implementation
type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByID(id int) (*User, error) {
    args := m.Called(id)
    if user := args.Get(0); user != nil {
        return user.(*User), args.Error(1)
    }
    return nil, args.Error(1)
}

func (m *MockUserRepository) Save(user *User) error {
    args := m.Called(user)
    return args.Error(0)
}

// Using the mock
func TestUserService_GetUser(t *testing.T) {
    // Setup mock
    mockRepo := new(MockUserRepository)
    expectedUser := &User{ID: 1, Email: "test@example.com"}

    mockRepo.On("FindByID", 1).Return(expectedUser, nil)

    // Test
    service := NewUserService(mockRepo)
    user, err := service.GetUser(1)

    // Assert
    require.NoError(t, err)
    assert.Equal(t, expectedUser, user)
    mockRepo.AssertExpectations(t)
}
```

### Manual Mocks

```go
// Simple mock without testify
type stubUserRepository struct {
    users map[int]*User
    err   error
}

func (s *stubUserRepository) FindByID(id int) (*User, error) {
    if s.err != nil {
        return nil, s.err
    }
    return s.users[id], nil
}

func (s *stubUserRepository) Save(user *User) error {
    s.users[user.ID] = user
    return s.err
}

func TestUserService_WithStub(t *testing.T) {
    stub := &stubUserRepository{
        users: map[int]*User{
            1: {ID: 1, Email: "test@example.com"},
        },
    }

    service := NewUserService(stub)
    user, err := service.GetUser(1)

    require.NoError(t, err)
    assert.Equal(t, "test@example.com", user.Email)
}
```

### HTTP Mocking with httptest

```go
import "net/http/httptest"

func TestAPIClient_FetchUser(t *testing.T) {
    // Create test server
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        assert.Equal(t, "/users/1", r.URL.Path)
        assert.Equal(t, "GET", r.Method)

        w.Header().Set("Content-Type", "application/json")
        w.WriteHeader(http.StatusOK)
        fmt.Fprint(w, `{"id": 1, "email": "test@example.com"}`)
    }))
    defer server.Close()

    // Test client
    client := NewAPIClient(server.URL)
    user, err := client.FetchUser(1)

    require.NoError(t, err)
    assert.Equal(t, 1, user.ID)
    assert.Equal(t, "test@example.com", user.Email)
}
```

## Benchmarking

### Basic Benchmarks

```go
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(5, 10)
    }
}

func BenchmarkStringConcat(b *testing.B) {
    for i := 0; i < b.N; i++ {
        result := ""
        for j := 0; j < 100; j++ {
            result += "a"
        }
    }
}

func BenchmarkStringBuilder(b *testing.B) {
    for i := 0; i < b.N; i++ {
        var builder strings.Builder
        for j := 0; j < 100; j++ {
            builder.WriteString("a")
        }
        _ = builder.String()
    }
}
```

**Running benchmarks:**
```bash
# Run all benchmarks
go test -bench=. ./...

# Run specific benchmark
go test -bench=BenchmarkAdd

# With memory statistics
go test -bench=. -benchmem

# Multiple runs for stability
go test -bench=. -count=5

# CPU profiling
go test -bench=. -cpuprofile=cpu.prof
go tool pprof cpu.prof
```

### Table-Driven Benchmarks

```go
func BenchmarkHashFunction(b *testing.B) {
    benchmarks := []struct {
        name  string
        input string
    }{
        {"short", "hello"},
        {"medium", strings.Repeat("a", 100)},
        {"long", strings.Repeat("b", 10000)},
    }

    for _, bm := range benchmarks {
        b.Run(bm.name, func(b *testing.B) {
            for i := 0; i < b.N; i++ {
                Hash(bm.input)
            }
        })
    }
}
```

### Benchmark Optimization

```go
func BenchmarkProcess(b *testing.B) {
    // Setup outside the loop
    data := generateTestData()

    b.ResetTimer()  // Don't count setup time

    for i := 0; i < b.N; i++ {
        Process(data)
    }
}
```

## Testing Concurrency

### Testing Goroutines

```go
func TestConcurrentCounter(t *testing.T) {
    counter := NewCounter()
    iterations := 1000
    goroutines := 10

    var wg sync.WaitGroup
    wg.Add(goroutines)

    for i := 0; i < goroutines; i++ {
        go func() {
            defer wg.Done()
            for j := 0; j < iterations; j++ {
                counter.Increment()
            }
        }()
    }

    wg.Wait()

    expected := goroutines * iterations
    assert.Equal(t, expected, counter.Value())
}
```

### Race Detection

```bash
# Run tests with race detector
go test -race ./...

# Build with race detector
go build -race

# Common race conditions will be detected
```

### Testing Channels

```go
func TestWorkerPool(t *testing.T) {
    jobs := make(chan int, 10)
    results := make(chan int, 10)

    // Start workers
    for i := 0; i < 3; i++ {
        go worker(jobs, results)
    }

    // Send jobs
    for i := 1; i <= 5; i++ {
        jobs <- i
    }
    close(jobs)

    // Collect results
    sum := 0
    for i := 0; i < 5; i++ {
        sum += <-results
    }

    assert.Equal(t, 15, sum)  // 1+2+3+4+5
}
```

## Coverage

### Generating Coverage Reports

```bash
# Basic coverage
go test -cover ./...

# Detailed coverage profile
go test -coverprofile=coverage.out ./...

# HTML coverage report
go tool cover -html=coverage.out -o coverage.html

# Show coverage by function
go tool cover -func=coverage.out

# Coverage for specific packages
go test -cover ./internal/user/...
```

### Coverage Thresholds

```bash
# Fail if coverage is below threshold
go test -cover ./... | grep -E 'coverage: [0-9]+' | \
    awk '{if ($2 < 80) exit 1}'
```

### Excluding Code from Coverage

```go
// Use build tags to exclude from coverage
//go:build !test
// +build !test

package main

// Or use specific code patterns
func init() {
    // Code that runs on startup (hard to test)
}
```

## Integration Testing

### Separating Unit and Integration Tests

```go
// +build integration

package user_test

import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestUserRepository_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }

    // Test with real database
    db := setupRealDB(t)
    repo := NewUserRepository(db)

    user := &User{Email: "test@example.com"}
    err := repo.Save(user)

    require.NoError(t, err)
    assert.NotZero(t, user.ID)
}
```

**Running tests:**
```bash
# Run only unit tests (fast)
go test -short ./...

# Run integration tests
go test -tags=integration ./...

# Run all tests
go test ./...
```

### Docker-Based Integration Tests

```go
func TestWithPostgres(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping postgres integration test")
    }

    // Start postgres container
    container := startPostgresContainer(t)
    defer container.Stop()

    db := connectToPostgres(t, container.ConnectionString())

    // Run tests
    repo := NewUserRepository(db)
    // ... test implementation
}
```

## Best Practices

### 1. Test One Thing Per Test

```go
// ❌ Testing multiple scenarios
func TestUserService(t *testing.T) {
    // Tests creation
    // Tests validation
    // Tests retrieval
    // Tests deletion
}

// ✅ Separate tests
func TestUserService_Create_ValidInput_ReturnsUser(t *testing.T) {
    // Only test creation
}

func TestUserService_Validate_InvalidEmail_ReturnsError(t *testing.T) {
    // Only test validation
}
```

### 2. Use Table-Driven Tests for Multiple Scenarios

```go
// ✅ Clean and maintainable
func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "test@example.com", false},
        {"missing @", "testexample.com", true},
        {"empty", "", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if (err != nil) != tt.wantErr {
                t.Errorf("ValidateEmail() error = %v, wantErr %v",
                    err, tt.wantErr)
            }
        })
    }
}
```

### 3. Use t.Helper() for Test Utilities

```go
func assertUserEqual(t *testing.T, expected, actual *User) {
    t.Helper()  // Error reports point to caller

    assert.Equal(t, expected.ID, actual.ID)
    assert.Equal(t, expected.Email, actual.Email)
}
```

### 4. Clean Up Resources

```go
func TestDatabaseOperations(t *testing.T) {
    db := setupDB(t)

    // Modern cleanup (Go 1.14+)
    t.Cleanup(func() {
        db.Close()
    })

    // Or use defer
    defer db.Close()

    // Test code
}
```

### 5. Make Tests Deterministic

```go
// ❌ Flaky test
func TestGenerateID(t *testing.T) {
    id1 := GenerateID()
    id2 := GenerateID()
    assert.NotEqual(t, id1, id2)  // May fail randomly
}

// ✅ Deterministic test
func TestGenerateID_WithSeed(t *testing.T) {
    gen := NewIDGenerator(12345)  // Fixed seed
    id1 := gen.Generate()

    gen2 := NewIDGenerator(12345)
    id2 := gen2.Generate()

    assert.Equal(t, id1, id2)  // Always passes
}
```

### 6. Test Exported Behavior, Not Implementation

```go
// ❌ Testing implementation details
func TestCache_InternalMap(t *testing.T) {
    cache := NewCache()
    cache.data["key"] = "value"  // Accessing internals
}

// ✅ Testing public API
func TestCache_SetAndGet(t *testing.T) {
    cache := NewCache()
    cache.Set("key", "value")
    value := cache.Get("key")
    assert.Equal(t, "value", value)
}
```

## Common Patterns

### Testing Time-Dependent Code

```go
// Use interface for time
type TimeProvider interface {
    Now() time.Time
}

// Mock time provider
type mockTimeProvider struct {
    currentTime time.Time
}

func (m *mockTimeProvider) Now() time.Time {
    return m.currentTime
}

func TestScheduler(t *testing.T) {
    mockTime := &mockTimeProvider{
        currentTime: time.Date(2024, 1, 1, 0, 0, 0, 0, time.UTC),
    }

    scheduler := NewScheduler(mockTime)
    // Test with controlled time
}
```

### Golden File Testing

```go
func TestRenderOutput(t *testing.T) {
    output := RenderTemplate(data)

    goldenFile := "testdata/output.golden"

    if *update {
        os.WriteFile(goldenFile, []byte(output), 0644)
    }

    expected, err := os.ReadFile(goldenFile)
    require.NoError(t, err)

    assert.Equal(t, string(expected), output)
}

// Run with: go test -update
var update = flag.Bool("update", false, "update golden files")
```

## References

- **Official Testing Package:** https://pkg.go.dev/testing
- **Testify:** https://github.com/stretchr/testify
- **Go Testing Best Practices:** https://golang.org/doc/code.html#Testing
- **Table-Driven Tests:** https://github.com/golang/go/wiki/TableDrivenTests
- **Advanced Testing:** https://go.dev/blog/subtests
