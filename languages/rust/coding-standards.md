# Rust Coding Standards

> **Language:** Rust 1.75+

## Type Safety and Ownership

Use `Result<T, E>` for fallible operations, `Option<T>` for nullable values.

```rust
pub fn read_config(path: &Path) -> Result<Config, ConfigError> {
    let contents = fs::read_to_string(path)
        .map_err(|e| ConfigError::FileRead(e))?;
    serde_json::from_str(&contents)
        .map_err(|e| ConfigError::ParseError(e))
}
```

## Error Handling

Use `thiserror::Error` with `#[derive]` and transparent forwarding for stdlib errors.

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DataError {
    #[error("File not found: {0}")]
    FileNotFound(String),
    #[error(transparent)]
    IoError(#[from] std::io::Error),
}
```

## Naming Conventions

- **Types, Traits:** `PascalCase`
- **Functions, Variables:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`
- **Lifetimes:** `'short_lowercase`

```rust
const MAX_RETRIES: u32 = 3;
pub struct UserService;
```

## Pattern Matching

Use `match` for exhaustive patterns, `if let` for single patterns.

```rust
if let Some(user) = find_user("123") {
    println!("{}", user.email);
}
```
