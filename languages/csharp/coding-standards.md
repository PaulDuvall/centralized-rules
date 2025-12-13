# C# / .NET Coding Standards

> **Language:** C# 12.0+ / .NET 8+
> **Applies to:** All C# / .NET projects

## C#-Specific Standards

### Type Safety and Nullability

```csharp
// Enable nullable reference types
#nullable enable

// ✅ Explicit nullability
public string? GetOptionalValue() => null;

public string GetRequiredValue() => "value";

// ✅ Null-conditional operator
var length = user?.Name?.Length ?? 0;

// ✅ Pattern matching
if (obj is string { Length: > 0 } str)
{
    Console.WriteLine(str);
}
```

### Naming Conventions

- **Classes, Methods:** `PascalCase`
- **Variables, Parameters:** `camelCase`
- **Private Fields:** `_camelCase` (underscore prefix)
- **Constants:** `PascalCase`
- **Interfaces:** `IPascalCase` (I prefix)

```csharp
public class UserService
{
    private readonly ILogger _logger;
    private const int MaxRetries = 3;

    public async Task<User?> GetUserAsync(string userId)
    {
        // Implementation
    }
}
```

### Modern C# Features

```csharp
// ✅ Records for data classes
public record User(string Id, string Email, int Age);

// ✅ Init-only properties
public class Config
{
    public string ApiUrl { get; init; } = string.Empty;
}

// ✅ File-scoped namespaces
namespace MyApp.Services;

// ✅ Top-level statements (Program.cs)
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();
app.Run();
```

### Error Handling

```csharp
public class DataProcessingException : Exception
{
    public DataProcessingException(string message) : base(message) { }
}

public async Task<Data> ProcessFileAsync(string filePath)
{
    try
    {
        var content = await File.ReadAllTextAsync(filePath);
        return JsonSerializer.Deserialize<Data>(content) 
            ?? throw new DataProcessingException("Deserialization returned null");
    }
    catch (FileNotFoundException)
    {
        throw new DataProcessingException(
            $"File not found: {filePath} | Remediation: Check file path exists");
    }
    catch (JsonException ex)
    {
        throw new DataProcessingException(
            $"Invalid JSON in {filePath}: {ex.Message} | Remediation: Validate JSON format");
    }
}
```

### Async/Await

```csharp
// ✅ Async all the way
public async Task<User> GetUserAsync(string id)
{
    var user = await _repository.GetByIdAsync(id);
    return user ?? throw new NotFoundException($"User {id} not found");
}

// ✅ ConfigureAwait for libraries
public async Task<Data> GetDataAsync()
{
    var response = await _httpClient.GetAsync(url).ConfigureAwait(false);
    return await response.Content.ReadFromJsonAsync<Data>().ConfigureAwait(false);
}
```

## Related Resources

- See `languages/csharp/testing.md` for testing guidelines
- See `base/testing-philosophy.md` for general testing patterns
