# Java Coding Standards

> **Language:** Java 17+ (LTS) / Java 21+
> **Applies to:** All Java projects

## Java-Specific Standards

### Type Safety and Modern Features

```java
// ✅ Use var for local variables (Java 10+)
var userList = new ArrayList<User>();
var config = loadConfiguration();

// ✅ Records for data classes (Java 14+)
public record User(String id, String email, int age) {}

// ✅ Pattern matching (Java 16+)
if (obj instanceof String str && str.length() > 0) {
    System.out.println(str);
}

// ✅ Switch expressions (Java 14+)
var result = switch (status) {
    case ACTIVE -> "User is active";
    case INACTIVE -> "User is inactive";
    case PENDING -> "User is pending";
    default -> throw new IllegalStateException("Unknown status: " + status);
};
```

### Naming Conventions

- **Classes:** `PascalCase`
- **Methods, Variables:** `camelCase`
- **Constants:** `UPPER_SNAKE_CASE`
- **Packages:** `lowercase.with.dots`

```java
package com.example.userservice;

public class UserService {
    private static final int MAX_RETRIES = 3;
    private final UserRepository repository;

    public Optional<User> getUserById(String userId) {
        return repository.findById(userId);
    }
}
```

### Error Handling

```java
public class DataProcessingException extends RuntimeException {
    public DataProcessingException(String message) {
        super(message);
    }

    public DataProcessingException(String message, Throwable cause) {
        super(message, cause);
    }
}

public Data processFile(Path filePath) {
    try {
        String content = Files.readString(filePath);
        return objectMapper.readValue(content, Data.class);
    } catch (NoSuchFileException e) {
        throw new DataProcessingException(
            "File not found: " + filePath + " | Remediation: Check file path exists", e);
    } catch (IOException e) {
        throw new DataProcessingException(
            "Failed to read file: " + filePath + " | Remediation: Check file permissions", e);
    }
}
```

### Null Safety

```java
// ✅ Use Optional for nullable returns
public Optional<User> findUser(String id) {
    return repository.findById(id);
}

// ✅ Use Objects.requireNonNull
public void process(User user) {
    Objects.requireNonNull(user, "user cannot be null");
    // Process user
}

// ✅ Use @NonNull annotations (with Lombok or Jakarta)
public void setEmail(@NonNull String email) {
    this.email = email;
}
```

## Related Resources

- See `languages/java/testing.md` for testing guidelines
- See `frameworks/springboot/best-practices.md` for Spring Boot patterns
