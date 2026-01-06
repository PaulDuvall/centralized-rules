# Bash/Shell Testing Standards

> **Language:** Bash 4.0+
> **Primary Framework:** bats-core
> **Applies to:** All shell scripts (.sh, .bash)

## Setup

**Install bats-core and helpers:**
```bash
brew install bats-core bats-support bats-assert bats-file
# Linux: git clone https://github.com/bats-core/bats-core.git && cd bats-core && ./install.sh /usr/local
```

**Run tests:**
```bash
bats tests/                          # All tests
bats tests/test_script.bats          # Specific file
bats --recursive --timing tests/     # With timing
```

## Test Structure

```
project/
├── script.sh
├── lib/
│   └── utils.sh
├── tests/
│   ├── test_script.bats
│   ├── test_utils.bats
│   ├── test_helper.bash     # Shared helpers
│   └── fixtures/            # Test data
└── .bats-version
```

Mirror source structure: `lib/utils.sh` → `tests/test_utils.bats`

## Test Patterns

**Basic structure:**
```bash
#!/usr/bin/env bats
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
    TEST_TEMP_DIR="$(mktemp -d)"
    export TEST_TEMP_DIR
    source "${BATS_TEST_DIRNAME}/../script.sh"
}

teardown() {
    [[ -d "$TEST_TEMP_DIR" ]] && rm -rf "$TEST_TEMP_DIR"
}

@test "function returns expected output" {
    run my_function "test"
    assert_success
    assert_output "expected output"
}

@test "function handles empty input" {
    run my_function ""
    assert_failure
    assert_output --partial "Error: empty input"
}
```

**Exit status:**
```bash
@test "script succeeds with valid input" {
    run ./script.sh valid.txt
    assert_success
}

@test "script fails with missing file" {
    run ./script.sh nonexistent.txt
    assert_failure
}

@test "script exits with code 2 for invalid option" {
    run ./script.sh --invalid
    assert_equal "$status" 2
}
```

**Output assertions:**
```bash
@test "output matches exact string" {
    run echo "Hello"
    assert_output "Hello"
}

@test "output contains substring" {
    run ./script.sh
    assert_output --partial "Processing"
}

@test "output matches regex" {
    run date
    assert_output --regexp "[0-9]{4}"
}
```

**File operations (requires `load 'test_helper/bats-file/load'`):**
```bash
@test "script creates output file" {
    run ./script.sh --output "$TEST_TEMP_DIR/out.txt"
    assert_success
    assert_file_exists "$TEST_TEMP_DIR/out.txt"
    assert_file_contains "$TEST_TEMP_DIR/out.txt" "expected"
}

@test "directory created with correct permissions" {
    run ./script.sh init "$TEST_TEMP_DIR/dir"
    assert_dir_exists "$TEST_TEMP_DIR/dir"
}
```

**Parametrized tests:**
```bash
@test "validates multiple email formats" {
    local -a emails=("user@example.com" "user.name@example.co.uk" "user+tag@example.com")
    for email in "${emails[@]}"; do
        run validate_email "$email"
        assert_success "Failed for: $email"
    done
}

@test "rejects invalid email formats" {
    local -a invalid=("invalid" "@example.com" "user@" "user name@example.com")
    for email in "${invalid[@]}"; do
        run validate_email "$email"
        assert_failure "Should reject: $email"
    done
}
```

## Advanced Patterns

**Setup/teardown lifecycle:**
```bash
setup_file() {
    export TEST_DB_DIR="$(mktemp -d)"
    ./scripts/init-test-db.sh "$TEST_DB_DIR"
}

teardown_file() {
    [[ -d "$TEST_DB_DIR" ]] && rm -rf "$TEST_DB_DIR"
}

setup() {
    ./scripts/reset-db.sh "$TEST_DB_DIR"
}

teardown() {
    rm -f "$TEST_TEMP_DIR"/*.tmp
}
```

**Mocking external commands:**
```bash
@test "script handles git failure" {
    function git() {
        echo "fatal: not a git repository" >&2
        return 128
    }
    export -f git

    run ./script.sh deploy
    assert_failure
    assert_output --partial "not a git repository"
}
```

**Testing with fixtures:**
```bash
@test "processes input file correctly" {
    local fixture="${BATS_TEST_DIRNAME}/fixtures"
    local out="$TEST_TEMP_DIR/output.txt"

    run ./script.sh process "$fixture/input.txt" "$out"
    assert_success
    run diff "$fixture/expected.txt" "$out"
    assert_success
}
```

**Conditional tests:**
```bash
@test "Linux-only test" {
    [[ "$OSTYPE" != "linux-gnu"* ]] && skip "Linux only"
    run ./linux-script.sh
    assert_success
}

@test "requires jq" {
    command -v jq &>/dev/null || skip "jq required"
    run ./process.sh
    assert_success
}
```

## Integration Testing

**End-to-end workflow:**
```bash
@test "full workflow processes data correctly" {
    local in_dir="$TEST_TEMP_DIR/in" out_dir="$TEST_TEMP_DIR/out"
    mkdir -p "$in_dir" "$out_dir"
    echo "test data" > "$in_dir/data.txt"

    run ./script.sh --input "$in_dir" --output "$out_dir"

    assert_success
    assert_file_exists "$out_dir/data.txt"
    assert_file_contains "$out_dir/data.txt" "test data"
}
```

**Docker integration:**
```bash
@test "script runs in Docker" {
    run docker build -t test-script:latest .
    assert_success

    run docker run --rm test-script:latest ./script.sh --help
    assert_success
    assert_output --partial "Usage:"
}
```

## Coverage & Quality

**Measure coverage:**
```bash
brew install kcov
kcov coverage/ bats tests/
open coverage/index.html
```

**Checklist:**
- Each function has >= 1 test
- Edge cases tested (empty, null, boundary)
- Error conditions tested (missing files, invalid input)
- Exit codes verified
- Output format validated
- File operations tested
- Integration tests cover full workflow

## CI/CD Integration

**GitHub Actions:**
```yaml
name: Shell Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: sudo apt-get install -y bats shellcheck
      - run: |
          git clone https://github.com/bats-core/bats-support test_helper/bats-support
          git clone https://github.com/bats-core/bats-assert test_helper/bats-assert
          git clone https://github.com/bats-core/bats-file test_helper/bats-file
      - run: shellcheck *.sh
      - run: bats --recursive --timing tests/
      - run: |
          brew install kcov
          kcov coverage/ bats tests/
```

**Test organization:**
```bash
@test "input validation: rejects empty string" { run validate ""; assert_failure; }
@test "input validation: accepts valid input" { run validate "valid"; assert_success; }
@test "file ops: creates output file" { run process --out "$TEST_TEMP_DIR/out"; assert_file_exists "$TEST_TEMP_DIR/out"; }
```

## Complete Example

**Data processing script test:**
```bash
#!/usr/bin/env bats
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

setup() {
    TEST_DIR="$(mktemp -d)"
    SCRIPT="${BATS_TEST_DIRNAME}/../process-data.sh"
}

teardown() {
    rm -rf "$TEST_DIR"
}

@test "processes CSV to JSON" {
    cat > "$TEST_DIR/input.csv" <<EOF
name,age
Alice,30
Bob,25
EOF
    run "$SCRIPT" "$TEST_DIR/input.csv" "$TEST_DIR/output.json"
    assert_success
    assert_file_exists "$TEST_DIR/output.json"
    run jq -e '.[] | select(.name == "Alice")' "$TEST_DIR/output.json"
    assert_success
}

@test "rejects malformed CSV" {
    echo "bad,csv,extra,field" > "$TEST_DIR/bad.csv"
    run "$SCRIPT" "$TEST_DIR/bad.csv" "$TEST_DIR/output.json"
    assert_failure
    assert_output --partial "Malformed CSV"
}

@test "output file is readable" {
    cat > "$TEST_DIR/input.csv" <<EOF
name,age
Alice,30
EOF
    run "$SCRIPT" "$TEST_DIR/input.csv" "$TEST_DIR/output.json"
    assert_file_exists "$TEST_DIR/output.json"
    run test -r "$TEST_DIR/output.json"
    assert_success
}
```

## POSIX Alternative (shunit2)

```bash
#!/bin/sh
. ./shunit2

setUp() {
    TEST_DIR="$(mktemp -d)"
}

tearDown() {
    rm -rf "$TEST_DIR"
}

testValidInput() {
    result=$(my_function "valid")
    assertEquals "expected output" "$result"
}

testInvalidInput() {
    my_function "" 2>/dev/null
    assertNotEquals 0 $?
}

. shunit2
```

## References

- [bats-core](https://github.com/bats-core/bats-core)
- [bats-assert](https://github.com/bats-core/bats-assert)
- [bats-file](https://github.com/bats-core/bats-file)
- [kcov](https://github.com/SimonKagstrom/kcov)
