# Rust Coding Standards

> **Language:** Rust 1.75+
> **Applies to:** All Rust projects

## Rust-Specific Standards

### Type Safety and Ownership

```rust
// ✅ Use Result for error handling
pub fn read_config(path: &Path) -> Result<Config, ConfigError> {
    let contents = fs::read_to_string(path)
        .map_err(|e| ConfigError::FileRead(e))?;

    serde_json::from_str(&contents)
        .map_err(|e| ConfigError::ParseError(e))
}

// ✅ Use Option for nullable values
pub fn find_user(id: &str) -> Option<User> {
    database.get(id)
}

// ✅ Ownership and borrowing
pub fn process_data(data: &[u8]) -> Vec<u8> {
    data.iter()
        .map(|&byte| byte * 2)
        .collect()
}
```

### Error Handling

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DataError {
    #[error("File not found: {0} | Remediation: Check file path exists")]
    FileNotFound(String),

    #[error("Parse error: {0} | Remediation: Validate data format")]
    ParseError(String),

    #[error(transparent)]
    IoError(#[from] std::io::Error),
}

pub fn process_file(path: &Path) -> Result<Data, DataError> {
    let content = fs::read_to_string(path)
        .map_err(|_| DataError::FileNotFound(path.display().to_string()))?;

    serde_json::from_str(&content)
        .map_err(|e| DataError::ParseError(e.to_string()))
}
```

### Naming Conventions

- **Types, Traits:** `PascalCase`
- **Functions, Variables:** `snake_case`
- **Constants:** `SCREAMING_SNAKE_CASE`
- **Lifetimes:** `'short_lowercase`

```rust
const MAX_RETRIES: u32 = 3;

pub struct UserService {
    repository: Arc<dyn UserRepository>,
}

impl UserService {
    pub async fn get_user(&self, user_id: &str) -> Result<User, ServiceError> {
        self.repository.find_by_id(user_id).await
    }
}
```

### Pattern Matching

```rust
match result {
    Ok(user) => println!("Found user: {}", user.email),
    Err(e) => eprintln!("Error: {}", e),
}

// ✅ If-let for single pattern
if let Some(user) = find_user("123") {
    println!("User: {}", user.email);
}
```

## Related Resources

- See `languages/rust/testing.md` for testing guidelines
- See `base/testing-philosophy.md` for testing patterns
