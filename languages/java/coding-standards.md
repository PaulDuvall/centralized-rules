# Java Coding Standards

> **Language:** Java 17+ (LTS)
> **Applies to:** All Java projects

## Type Safety and Modern Features

- Use `var` for local variables (type inference reduces verbosity)
- Use `record` for immutable data classes
- Use pattern matching with `instanceof`
- Use switch expressions (not statements)

```java
var users = new ArrayList<User>();
public record User(String id, String email, int age) {}
if (obj instanceof String str && str.length() > 0) System.out.println(str);
var status = switch (userStatus) {
    case ACTIVE -> "User is active";
    case INACTIVE -> "User is inactive";
    default -> throw new IllegalStateException("Unknown: " + userStatus);
};
```

## Naming Conventions

| Construct | Convention | Example |
|-----------|-----------|---------|
| Class | PascalCase | `UserService` |
| Method/Variable | camelCase | `getUserById` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRIES = 3` |
| Package | lowercase.dots | `com.example.service` |

## Error Handling

Extend `RuntimeException` for domain errors. Chain exceptions with cause. Include context in message.

```java
public class DataProcessingException extends RuntimeException {
    public DataProcessingException(String message, Throwable cause) {
        super(message, cause);
    }
}

public Data processFile(Path filePath) {
    try {
        return objectMapper.readValue(Files.readString(filePath), Data.class);
    } catch (IOException e) {
        throw new DataProcessingException("Failed to process: " + filePath, e);
    }
}
```

## Null Safety

- Return `Optional<T>` for potentially null values
- Use `Objects.requireNonNull()` for required parameters
- Use `@NonNull` annotations (Lombok/Jakarta) on method parameters

```java
public Optional<User> findUser(String id) { return repository.findById(id); }
public void process(User user) { Objects.requireNonNull(user); }
public void setEmail(@NonNull String email) { this.email = email; }
```

## Related Resources

- See `languages/java/testing.md` for testing standards
- See `frameworks/springboot/best-practices.md` for Spring Boot patterns
