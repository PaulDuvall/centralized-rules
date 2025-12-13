# Rust Testing Standards

> **Language:** Rust 1.75+
> **Framework:** Built-in test framework, cargo test
> **Applies to:** All Rust projects

## Testing Framework

### Built-in Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add_two_numbers() {
        // Arrange
        let a = 2;
        let b = 3;

        // Act
        let result = add(a, b);

        // Assert
        assert_eq!(result, 5);
    }

    #[test]
    #[should_panic(expected = "cannot divide by zero")]
    fn test_divide_by_zero() {
        divide(10, 0);
    }
}
```

### Async Testing

```rust
#[cfg(test)]
mod tests {
    use tokio::test;

    #[tokio::test]
    async fn test_async_function() {
        let result = fetch_data().await;
        assert!(result.is_ok());
    }
}
```

### Property-Based Testing

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_reversing_twice_gives_original(s in "\\PC*") {
        let reversed_once: String = s.chars().rev().collect();
        let reversed_twice: String = reversed_once.chars().rev().collect();
        assert_eq!(s, reversed_twice);
    }
}
```

## Related Resources

- See `languages/rust/coding-standards.md` for coding standards
- See `base/testing-philosophy.md` for testing principles
