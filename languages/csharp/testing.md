# C# / .NET Testing Standards

> **Language:** C# 12.0+ / .NET 8+
> **Framework:** xUnit (recommended), NUnit, or MSTest
> **Applies to:** All C# / .NET projects

## xUnit with Fact and Theory

Use `[Fact]` for single test cases, `[Theory]` with `[InlineData]` for parametrized tests:

```csharp
using Xunit;

public class CalculatorTests
{
    [Fact]
    public void Add_TwoNumbers_ReturnsSum()
    {
        var calc = new Calculator();
        Assert.Equal(5, calc.Add(2, 3));
    }

    [Theory]
    [InlineData(0, 0, 0)]
    [InlineData(1, 2, 3)]
    [InlineData(-1, 1, 0)]
    public void Add_VariousInputs(int a, int b, int expected)
    {
        Assert.Equal(expected, new Calculator().Add(a, b));
    }
}
```

## Mocking with Moq

Mock dependencies, setup return values, verify invocations:

```csharp
using Moq;

[Fact]
public async Task GetUser_ValidId_ReturnsUser()
{
    var mockRepo = new Mock<IUserRepository>();
    mockRepo.Setup(r => r.GetByIdAsync("123"))
        .ReturnsAsync(new User { Id = "123", Name = "Test" });

    var service = new UserService(mockRepo.Object);
    var user = await service.GetUserAsync("123");

    Assert.NotNull(user);
    Assert.Equal("Test", user.Name);
    mockRepo.Verify(r => r.GetByIdAsync("123"), Times.Once);
}
```

## Async Test Pattern

Test async methods directly without blocking. Test names reflect behavior:

```csharp
[Fact]
public async Task ProcessAsync_InvalidData_ThrowsException()
{
    var service = new DataService();
    await Assert.ThrowsAsync<ArgumentException>(() => service.ProcessAsync(null));
}
```

## Related Resources

- See `languages/csharp/coding-standards.md` for coding standards
- See `base/testing-philosophy.md` for testing principles
