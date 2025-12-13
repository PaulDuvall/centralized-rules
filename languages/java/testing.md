# Java Testing Standards

> **Language:** Java 17+
> **Framework:** JUnit 5, Mockito
> **Applies to:** All Java projects

## Testing Framework

### JUnit 5

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>
```

**Example:**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import static org.junit.jupiter.api.Assertions.*;

class CalculatorTest {

    @Test
    void add_TwoNumbers_ReturnsSum() {
        // Arrange
        var calculator = new Calculator();

        // Act
        int result = calculator.add(2, 3);

        // Assert
        assertEquals(5, result);
    }

    @ParameterizedTest
    @ValueSource(ints = {1, 2, 3, 4, 5})
    void isPositive_PositiveNumbers_ReturnsTrue(int number) {
        assertTrue(number > 0);
    }
}
```

### Mocking with Mockito

```java
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.junit.jupiter.api.extension.ExtendWith;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository repository;

    @Test
    void getUser_ValidId_ReturnsUser() {
        // Arrange
        when(repository.findById("123"))
            .thenReturn(Optional.of(new User("123", "test@example.com")));

        var service = new UserService(repository);

        // Act
        var user = service.getUserById("123");

        // Assert
        assertTrue(user.isPresent());
        assertEquals("test@example.com", user.get().email());
        verify(repository, times(1)).findById("123");
    }
}
```

## Related Resources

- See `languages/java/coding-standards.md` for coding standards
- See `base/testing-philosophy.md` for testing principles
