# Go Testing Standards

Go 1.20+ using standard library `testing` and `testify` for assertions and mocking.

## Test Commands

```bash
go test ./...                           # Run all tests
go test -v ./...                        # Verbose output
go test -run TestName                   # Specific test
go test -cover ./...                    # Coverage
go test -coverprofile=coverage.out ./   # Coverage report
go tool cover -html=coverage.out        # HTML report
go test -race ./...                     # Race detection
go test -bench=. -benchmem              # Benchmarks
```

**File layout:**
```
internal/user/
├── user.go
├── user_test.go          # White-box tests
└── repository_test.go

test/
├── integration/
│   └── user_integration_test.go
└── testdata/
    └── users.json        # Test fixtures
```

**Naming:**
- Test files: `*_test.go`
- Test functions: `TestSubject_Scenario_Expected(t *testing.T)`
- Use `package pkg_test` for black-box testing

Example:
```go
func TestValidateEmail_WithInvalidFormat_ReturnsError(t *testing.T) {}
func TestUserRepository_FindByID_WhenNotFound_ReturnsError(t *testing.T) {}
```

## Test Patterns

**AAA pattern:** Arrange, Act, Assert.
```go
func TestCalculateTotal(t *testing.T) {
    items := []Item{{Price: 10.00, Qty: 2}, {Price: 5.00, Qty: 3}}
    total := CalculateTotal(items)
    expected := 35.00
    if total != expected {
        t.Errorf("CalculateTotal() = %v, want %v", total, expected)
    }
}
```

**Table-driven tests:** Idiomatic pattern for multiple scenarios.

```go
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 2, 3, 5},
        {"negative", -5, -3, -8},
        {"mixed", 10, -4, 6},
        {"zero", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            result := Add(tt.a, tt.b)
            if result != tt.expected {
                t.Errorf("Add(%d,%d)=%d, want %d",
                    tt.a, tt.b, result, tt.expected)
            }
        })
    }
}
```

**Testify assertions:**
```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestUserCreation(t *testing.T) {
    user := CreateUser("test@example.com")
    assert.NotNil(t, user)        // Continue on failure
    assert.Equal(t, "test@example.com", user.Email)

    user2, err := CreateUserValidated("invalid")
    require.Error(t, err)          // Stop on failure
    require.Nil(t, user2)
}
```

**Error testing:**
```go
func TestDivide_ByZero(t *testing.T) {
    _, err := Divide(10, 0)
    require.Error(t, err)
    assert.ErrorIs(t, err, ErrDivideByZero)
}

func TestValidateUser(t *testing.T) {
    err := ValidateUser(&User{Email: ""})
    require.Error(t, err)

    var valErr *ValidationError
    assert.ErrorAs(t, err, &valErr)
    assert.Equal(t, "email", valErr.Field)
}
```

## Test Fixtures and Setup

**Setup/Teardown:**
```go
func TestMain(m *testing.M) {
    setup()
    code := m.Run()
    teardown()
    os.Exit(code)
}
```

**Helper functions:** Use `t.Helper()` for error reporting.
```go
func setupTestDB(t *testing.T) *sql.DB {
    t.Helper()
    db, err := sql.Open("sqlite3", ":memory:")
    require.NoError(t, err)

    t.Cleanup(func() { db.Close() })
    return db
}
```

**Test fixtures:**
```go
func loadTestData(t *testing.T, file string) []byte {
    t.Helper()
    data, err := os.ReadFile(filepath.Join("testdata", file))
    require.NoError(t, err)
    return data
}
```

## Mocking

**Testify mocks:**
```go
type UserRepository interface {
    FindByID(id int) (*User, error)
}

type MockUserRepository struct {
    mock.Mock
}

func (m *MockUserRepository) FindByID(id int) (*User, error) {
    args := m.Called(id)
    return args.Get(0).(*User), args.Error(1)
}

func TestUserService_GetUser(t *testing.T) {
    mockRepo := new(MockUserRepository)
    mockRepo.On("FindByID", 1).Return(&User{ID: 1}, nil)

    service := NewUserService(mockRepo)
    user, err := service.GetUser(1)

    require.NoError(t, err)
    assert.Equal(t, 1, user.ID)
    mockRepo.AssertExpectations(t)
}
```

**Stub mocks:**
```go
type stubRepository struct {
    users map[int]*User
}

func (s *stubRepository) FindByID(id int) (*User, error) {
    return s.users[id], nil
}

func TestWithStub(t *testing.T) {
    stub := &stubRepository{users: map[int]*User{1: {ID: 1}}}
    service := NewUserService(stub)
    user, _ := service.GetUser(1)
    assert.Equal(t, 1, user.ID)
}
```

**HTTP mocking:**
```go
func TestAPIClient(t *testing.T) {
    server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprint(w, `{"id":1,"email":"test@example.com"}`)
    }))
    defer server.Close()

    client := NewAPIClient(server.URL)
    user, _ := client.FetchUser(1)
    assert.Equal(t, 1, user.ID)
}
```

## Benchmarking

```go
func BenchmarkAdd(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Add(5, 10)
    }
}

func BenchmarkHashFunction(b *testing.B) {
    tests := []struct {
        name  string
        input string
    }{
        {"short", "hello"},
        {"long", strings.Repeat("x", 10000)},
    }

    for _, tt := range tests {
        b.Run(tt.name, func(b *testing.B) {
            for i := 0; i < b.N; i++ {
                Hash(tt.input)
            }
        })
    }
}
```

**Commands:**
```bash
go test -bench=. -benchmem              # All benchmarks with memory
go test -bench=BenchmarkAdd             # Specific benchmark
go test -bench=. -count=5               # Multiple runs
go test -bench=. -cpuprofile=cpu.prof   # CPU profiling
go tool pprof cpu.prof
```

Use `b.ResetTimer()` to exclude setup time from measurement.

## Testing Concurrency

**Goroutines:**
```go
func TestConcurrentCounter(t *testing.T) {
    counter := NewCounter()
    var wg sync.WaitGroup

    for i := 0; i < 10; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for j := 0; j < 100; j++ {
                counter.Increment()
            }
        }()
    }

    wg.Wait()
    assert.Equal(t, 1000, counter.Value())
}
```

**Channels:**
```go
func TestWorkerPool(t *testing.T) {
    jobs := make(chan int, 10)
    results := make(chan int, 10)

    for i := 0; i < 3; i++ {
        go worker(jobs, results)
    }

    for i := 1; i <= 5; i++ {
        jobs <- i
    }
    close(jobs)

    sum := 0
    for i := 0; i < 5; i++ {
        sum += <-results
    }
    assert.Equal(t, 15, sum)
}
```

**Race detection:** Use `go test -race ./...` to detect race conditions.

## Coverage

```bash
go test -cover ./...                    # Basic coverage
go test -coverprofile=coverage.out ./   # Profile
go tool cover -html=coverage.out        # HTML report
go tool cover -func=coverage.out        # By function
```

Exclude from coverage using build tags:
```go
//go:build !test
// +build !test

func init() {
    // Startup code (hard to test)
}
```

## Integration Testing

Use build tags to separate unit and integration tests.

```go
// +build integration

func TestUserRepository_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }

    db := setupRealDB(t)
    repo := NewUserRepository(db)
    user := &User{Email: "test@example.com"}

    err := repo.Save(user)
    require.NoError(t, err)
    assert.NotZero(t, user.ID)
}
```

**Run:**
```bash
go test -short ./...           # Unit tests only
go test -tags=integration ./   # Integration tests
go test ./...                  # All tests
```

## Best Practices

1. **One thing per test:** Test one behavior per test function. Use table-driven tests for multiple scenarios.

2. **Use `t.Helper()`:** In test utilities so error reports point to the caller.
```go
func assertUserEqual(t *testing.T, expected, actual *User) {
    t.Helper()
    assert.Equal(t, expected.ID, actual.ID)
}
```

3. **Clean up resources:** Use `t.Cleanup()` or `defer`.
```go
db := setupDB(t)
t.Cleanup(func() { db.Close() })
```

4. **Make tests deterministic:** No random behavior, no time-dependent tests without control.
```go
gen := NewIDGenerator(12345)  // Fixed seed
id1 := gen.Generate()
id2 := gen.Generate()
assert.NotEqual(t, id1, id2)
```

5. **Test behavior, not implementation:** Test the public API, not internal details.
```go
cache := NewCache()
cache.Set("key", "value")
assert.Equal(t, "value", cache.Get("key"))
```

6. **Mock time:** Use interface for time-dependent code.
```go
type TimeProvider interface {
    Now() time.Time
}

type mockTime struct{ currentTime time.Time }
func (m *mockTime) Now() time.Time { return m.currentTime }

scheduler := NewScheduler(mockTime)
```

7. **Golden files:** For complex output comparison.
```go
output := RenderTemplate(data)
goldenFile := "testdata/output.golden"
if *update {
    os.WriteFile(goldenFile, []byte(output), 0644)
}
expected, _ := os.ReadFile(goldenFile)
assert.Equal(t, string(expected), output)
```
