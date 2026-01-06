# Rust Testing Standards

> **Language:** Rust 1.75+

## Unit Tests

Use `#[cfg(test)]` modules with `#[test]` attributes. Use `#[should_panic]` for panic assertions.

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_add() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    #[should_panic(expected = "divide by zero")]
    fn test_divide_by_zero() {
        divide(10, 0);
    }
}
```

## Async Tests

Use `#[tokio::test]` for async test functions.

```rust
#[tokio::test]
async fn test_async_function() {
    assert!(fetch_data().await.is_ok());
}
```

## Property-Based Tests

Use `proptest` for generating test cases over input ranges.

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_reversible(s in "\\PC*") {
        let rev: String = s.chars().rev().collect();
        assert_eq!(s, rev.chars().rev().collect::<String>());
    }
}
```
