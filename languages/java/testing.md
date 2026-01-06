# Java Testing Standards

> **Language:** Java 17+
> **Framework:** JUnit 5, Mockito
> **Applies to:** All Java projects

## Test Structure

Use AAA pattern (Arrange-Act-Assert). Name tests: `method_Scenario_ExpectedResult`. One assertion per test where practical.

```java
@Test
void add_TwoNumbers_ReturnsSum() {
    var calc = new Calculator();
    assertEquals(5, calc.add(2, 3));
}

@ParameterizedTest
@ValueSource(ints = {1, 2, 3})
void isPositive_ValidNumbers_ReturnsTrue(int n) {
    assertTrue(n > 0);
}
```

## Mocking Dependencies

Use `@Mock` for dependencies and `@ExtendWith(MockitoExtension.class)` on test class. Verify interactions only when behavior is critical.

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {
    @Mock private UserRepository repository;

    @Test
    void getUser_ValidId_ReturnsUser() {
        when(repository.findById("123")).thenReturn(Optional.of(new User("123", "user@test.com")));
        var user = new UserService(repository).getUserById("123");
        assertTrue(user.isPresent());
        assertEquals("user@test.com", user.get().email());
    }
}
```

## Test Organization

- One test class per production class
- Use setup methods only if reused across 3+ tests
- Keep test scope focused: one logical behavior per test
- Use fixtures or builders for complex object setup

## Related Resources

- See `languages/java/coding-standards.md` for coding standards
