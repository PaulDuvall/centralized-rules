# Bash/Shell Testing Standards

> **Language:** Bash 4.0+
> **Primary Framework:** bats-core
> **Applies to:** All shell scripts (.sh, .bash)

## Bash Testing Frameworks

### bats-core (Bash Automated Testing System)

Primary test framework for Bash scripts - modern, actively maintained fork of the original bats.

**Installation:**
```bash
# macOS
brew install bats-core

# Linux - clone and install
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local

# Also install helper libraries
brew install bats-support bats-assert bats-file
```

**Basic usage:**
```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/test_script.bats

# Run with timing
bats --timing tests/

# Pretty output with tap formatter
bats --formatter tap tests/

# Recursive test discovery
bats --recursive tests/
```

### Alternative: shunit2

Lightweight xUnit-style testing for shell scripts (POSIX-compatible).

```bash
# Install shunit2
brew install shunit2

# Or download
curl -L https://raw.githubusercontent.com/kward/shunit2/master/shunit2 > shunit2
chmod +x shunit2
```

## Test Structure

### File Organization

```
project/
├── script.sh                 # Script to test
├── lib/
│   ├── utils.sh             # Utility functions
│   └── validation.sh
├── tests/
│   ├── test_script.bats     # bats tests for script.sh
│   ├── test_utils.bats      # bats tests for utils.sh
│   ├── test_validation.bats
│   ├── test_helper.bash     # Shared test helpers
│   └── fixtures/            # Test data files
│       ├── sample_input.txt
│       └── expected_output.txt
└── .bats-version            # Pin bats version
```

### Test File Naming

- Use `.bats` extension for bats tests
- Prefix with `test_` for other frameworks
- Mirror source code structure
- Example: `script.sh` → `tests/test_script.bats`

## bats-core Test Patterns

### Basic Test Structure

```bash
#!/usr/bin/env bats

# Load bats helpers (optional but recommended)
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Setup function - runs before each test
setup() {
    # Create temp directory
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR

    # Load script to test
    source "${BATS_TEST_DIRNAME}/../script.sh"
}

# Teardown function - runs after each test
teardown() {
    # Clean up temp directory
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
}

@test "function returns expected output" {
    # Arrange
    local input="test"

    # Act
    run my_function "$input"

    # Assert
    assert_success
    assert_output "expected output"
}

@test "function handles empty input" {
    run my_function ""

    assert_failure
    assert_output --partial "Error: empty input"
}
```

### Testing Exit Status

```bash
@test "script exits successfully with valid input" {
    run ./script.sh valid_file.txt

    assert_success  # Exit code = 0
}

@test "script fails with missing file" {
    run ./script.sh nonexistent.txt

    assert_failure  # Exit code != 0
}

@test "script exits with specific code" {
    run ./script.sh --invalid-option

    assert_equal "$status" 2  # Specific exit code
}
```

### Testing Output

```bash
@test "script produces correct output" {
    run echo "Hello, World"

    assert_output "Hello, World"
}

@test "script output contains string" {
    run ./script.sh process file.txt

    assert_output --partial "Processing"
}

@test "script output matches regex" {
    run date

    assert_output --regexp "[0-9]{4}"
}

@test "script writes to stderr" {
    run bash -c "./script.sh 2>&1 >/dev/null"

    assert_output --partial "[ERROR]"
}
```

### Testing Files

```bash
load 'test_helper/bats-file/load'

@test "script creates output file" {
    run ./script.sh --output "$TEST_TEMP_DIR/output.txt"

    assert_success
    assert_file_exists "$TEST_TEMP_DIR/output.txt"
}

@test "output file contains expected content" {
    local output_file="$TEST_TEMP_DIR/output.txt"

    run ./script.sh --output "$output_file"

    assert_file_exists "$output_file"
    assert_file_contains "$output_file" "expected content"
}

@test "script creates directory with correct permissions" {
    run ./script.sh init "$TEST_TEMP_DIR/newdir"

    assert_dir_exists "$TEST_TEMP_DIR/newdir"
    # Check permissions (755)
    run stat -c %a "$TEST_TEMP_DIR/newdir"  # Linux
    # run stat -f %A "$TEST_TEMP_DIR/newdir"  # macOS
    assert_output "755"
}
```

### Testing Functions

```bash
#!/usr/bin/env bats

# Source the script containing functions
setup() {
    source "${BATS_TEST_DIRNAME}/../lib/utils.sh"
}

@test "validate_email accepts valid email" {
    run validate_email "user@example.com"

    assert_success
}

@test "validate_email rejects invalid email" {
    run validate_email "invalid-email"

    assert_failure
    assert_output --partial "Invalid email format"
}

@test "calculate_sum returns correct result" {
    run calculate_sum 10 20 30

    assert_success
    assert_output "60"
}
```

### Parametrized Tests

```bash
# Test multiple inputs
@test "validates multiple email formats" {
    local -a valid_emails=(
        "user@example.com"
        "user.name@example.co.uk"
        "user+tag@example.com"
    )

    for email in "${valid_emails[@]}"; do
        run validate_email "$email"
        assert_success "Email should be valid: $email"
    done
}

@test "rejects invalid email formats" {
    local -a invalid_emails=(
        "invalid"
        "@example.com"
        "user@"
        "user name@example.com"
    )

    for email in "${invalid_emails[@]}"; do
        run validate_email "$email"
        assert_failure "Email should be invalid: $email"
    done
}
```

## Testing Patterns

### Setup and Teardown

```bash
# setup_file - runs once before all tests in file
setup_file() {
    # Start test database
    export TEST_DB_DIR="$(mktemp -d)"
    ./scripts/init-test-db.sh "$TEST_DB_DIR"
}

# teardown_file - runs once after all tests in file
teardown_file() {
    # Stop and clean up test database
    [[ -d "$TEST_DB_DIR" ]] && rm -rf "$TEST_DB_DIR"
}

# setup - runs before each test
setup() {
    # Reset database to known state
    ./scripts/reset-db.sh "$TEST_DB_DIR"
}

# teardown - runs after each test
teardown() {
    # Clean up test files
    rm -f "$TEST_TEMP_DIR"/*.tmp
}
```

### Mocking External Commands

```bash
@test "script handles git command failure" {
    # Create a fake 'git' command that fails
    function git() {
        echo "fatal: not a git repository" >&2
        return 128
    }
    export -f git

    run ./script.sh deploy

    assert_failure
    assert_output --partial "not a git repository"
}

@test "script calls curl with correct arguments" {
    # Mock curl to capture arguments
    function curl() {
        echo "curl called with: $*" >> "$TEST_TEMP_DIR/curl_calls.log"
        echo '{"status": "success"}'
    }
    export -f curl

    run ./script.sh fetch-data

    assert_success
    assert_file_contains "$TEST_TEMP_DIR/curl_calls.log" "https://api.example.com"
}
```

### Testing with Fixtures

```bash
@test "script processes sample input correctly" {
    local fixture_dir="${BATS_TEST_DIRNAME}/fixtures"
    local input_file="$fixture_dir/sample_input.txt"
    local expected_output="$fixture_dir/expected_output.txt"
    local actual_output="$TEST_TEMP_DIR/actual_output.txt"

    run ./script.sh process "$input_file" "$actual_output"

    assert_success
    run diff "$expected_output" "$actual_output"
    assert_success "Output should match expected output"
}
```

### Skip Tests

```bash
@test "feature only works on Linux" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test only runs on Linux"
    fi

    run ./linux-only-script.sh
    assert_success
}

@test "requires specific tool" {
    if ! command -v jq &> /dev/null; then
        skip "jq not installed"
    fi

    run ./script-using-jq.sh
    assert_success
}
```

## Integration Testing

### Testing Script End-to-End

```bash
@test "full workflow processes data correctly" {
    # Setup: Create test input
    local input_dir="$TEST_TEMP_DIR/input"
    local output_dir="$TEST_TEMP_DIR/output"
    mkdir -p "$input_dir" "$output_dir"

    echo "test data" > "$input_dir/data.txt"

    # Execute: Run entire script
    run ./script.sh \
        --input "$input_dir" \
        --output "$output_dir" \
        --verbose

    # Verify: Check results
    assert_success
    assert_output --partial "Processing complete"
    assert_file_exists "$output_dir/data.txt"
    assert_file_contains "$output_dir/data.txt" "test data"
}
```

### Testing with Docker

```bash
@test "script runs in Docker container" {
    # Build test image
    run docker build -t test-script:latest .
    assert_success

    # Run script in container
    run docker run --rm test-script:latest ./script.sh --help
    assert_success
    assert_output --partial "Usage:"

    # Clean up
    run docker rmi test-script:latest
}
```

## Coverage and Quality

### Measuring Test Coverage

```bash
# Use kcov for code coverage
# https://github.com/SimonKagstrom/kcov

# Install kcov
brew install kcov

# Run tests with coverage
kcov coverage/ bats tests/

# View coverage report
open coverage/index.html
```

### Test Quality Checklist

- **Each function has at least one test**
- **Edge cases are tested** (empty input, null, boundary values)
- **Error conditions are tested** (missing files, invalid input)
- **Exit codes are verified**
- **Output format is validated**
- **File operations are tested** (creation, permissions, content)
- **Integration tests cover full workflow**

## CI/CD Integration

### GitHub Actions

```yaml
name: Shell Script Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install bats
        run: |
          sudo apt-get update
          sudo apt-get install -y bats

      - name: Install bats helpers
        run: |
          git clone https://github.com/bats-core/bats-support test_helper/bats-support
          git clone https://github.com/bats-core/bats-assert test_helper/bats-assert
          git clone https://github.com/bats-core/bats-file test_helper/bats-file

      - name: Run ShellCheck
        run: shellcheck *.sh

      - name: Run tests
        run: bats --recursive --timing tests/

      - name: Coverage report (optional)
        run: |
          kcov coverage/ bats tests/
```

### Test Organization Best Practices

```bash
# Group related tests
@test "input validation: rejects empty string" { ... }
@test "input validation: rejects invalid format" { ... }
@test "input validation: accepts valid input" { ... }

@test "file operations: creates output file" { ... }
@test "file operations: preserves permissions" { ... }
@test "file operations: handles missing directory" { ... }

# Use descriptive names that explain the scenario
@test "when input file is missing, script exits with code 1 and shows error" {
    run ./script.sh nonexistent.txt
    assert_equal "$status" 1
    assert_output --partial "Error: File not found"
}
```

## Testing Examples

### Example: Testing a Data Processing Script

```bash
#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

setup() {
    # Create temp directory
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR

    # Script to test
    SCRIPT="${BATS_TEST_DIRNAME}/../process-data.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "processes CSV file and generates JSON" {
    # Create test CSV
    cat > "$TEST_DIR/input.csv" <<EOF
name,age,city
Alice,30,NYC
Bob,25,LA
EOF

    # Run script
    run "$SCRIPT" "$TEST_DIR/input.csv" "$TEST_DIR/output.json"

    # Verify
    assert_success
    assert_file_exists "$TEST_DIR/output.json"

    # Validate JSON structure
    run jq -e '.[] | select(.name == "Alice")' "$TEST_DIR/output.json"
    assert_success
}

@test "handles malformed CSV gracefully" {
    # Create invalid CSV
    echo "invalid,csv,data,extra,fields" > "$TEST_DIR/bad.csv"

    run "$SCRIPT" "$TEST_DIR/bad.csv" "$TEST_DIR/output.json"

    assert_failure
    assert_output --partial "Malformed CSV"
}

@test "validates output file permissions" {
    run "$SCRIPT" "$TEST_DIR/input.csv" "$TEST_DIR/output.json"

    # Check file is readable
    assert_file_exists "$TEST_DIR/output.json"
    run test -r "$TEST_DIR/output.json"
    assert_success
}
```

## shunit2 Alternative Pattern

For POSIX-compatible tests:

```bash
#!/bin/sh

# Load shunit2
. ./shunit2

# Setup
setUp() {
    TEST_DIR="$(mktemp -d)"
}

# Teardown
tearDown() {
    rm -rf "$TEST_DIR"
}

# Test functions
testValidInput() {
    result=$(my_function "valid")
    assertEquals "expected output" "$result"
}

testInvalidInput() {
    my_function "" 2>/dev/null
    assertNotEquals 0 $?
}

# Run tests
. shunit2
```

## References

- **bats-core** - https://github.com/bats-core/bats-core
- **bats-assert** - https://github.com/bats-core/bats-assert
- **bats-support** - https://github.com/bats-core/bats-support
- **bats-file** - https://github.com/bats-core/bats-file
- **shunit2** - https://github.com/kward/shunit2
- **kcov** - https://github.com/SimonKagstrom/kcov
