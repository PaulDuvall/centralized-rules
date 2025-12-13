# C# / .NET Testing Standards

> **Language:** C# 12.0+ / .NET 8+
> **Framework:** xUnit, NUnit, or MSTest
> **Applies to:** All C# / .NET projects

## Testing Framework

### xUnit (Recommended)

```bash
dotnet add package xUnit
dotnet add package xunit.runner.visualstudio
dotnet add package Microsoft.NET.Test.Sdk
```

**Example:**

```csharp
using Xunit;

public class CalculatorTests
{
    [Fact]
    public void Add_TwoNumbers_ReturnsSum()
    {
        // Arrange
        var calculator = new Calculator();

        // Act
        var result = calculator.Add(2, 3);

        // Assert
        Assert.Equal(5, result);
    }

    [Theory]
    [InlineData(0, 0, 0)]
    [InlineData(1, 2, 3)]
    [InlineData(-1, 1, 0)]
    public void Add_VariousInputs_ReturnsCorrectSum(int a, int b, int expected)
    {
        var calculator = new Calculator();
        var result = calculator.Add(a, b);
        Assert.Equal(expected, result);
    }
}
```

### Mocking with Moq

```csharp
using Moq;

public class UserServiceTests
{
    [Fact]
    public async Task GetUser_ValidId_ReturnsUser()
    {
        // Arrange
        var mockRepo = new Mock<IUserRepository>();
        mockRepo.Setup(r => r.GetByIdAsync("123"))
            .ReturnsAsync(new User { Id = "123", Name = "Test" });

        var service = new UserService(mockRepo.Object);

        // Act
        var user = await service.GetUserAsync("123");

        // Assert
        Assert.NotNull(user);
        Assert.Equal("Test", user.Name);
        mockRepo.Verify(r => r.GetByIdAsync("123"), Times.Once);
    }
}
```

### Testing Async Code

```csharp
[Fact]
public async Task ProcessAsync_ValidData_Succeeds()
{
    // Arrange
    var service = new DataService();

    // Act
    var result = await service.ProcessAsync(data);

    // Assert
    Assert.True(result.Success);
}
```

## Related Resources

- See `languages/csharp/coding-standards.md` for coding standards
- See `base/testing-philosophy.md` for testing principles
