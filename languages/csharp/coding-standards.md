# C# / .NET Coding Standards

> **Language:** C# 12.0+ / .NET 8+
> **Applies to:** All C# / .NET projects

## Naming Conventions

- **Classes, Methods:** `PascalCase`
- **Variables, Parameters:** `camelCase`
- **Private Fields:** `_camelCase`
- **Constants:** `PascalCase`
- **Interfaces:** `IPascalCase`

## Type Safety and Nullability

```csharp
#nullable enable

// Explicit nullability
public string? GetOptional() => null;
public string GetRequired() => "value";

// Null-conditional operator
var length = user?.Name?.Length ?? 0;

// Pattern matching
if (obj is string { Length: > 0 } str) Console.WriteLine(str);
```

## Modern C# Features

Use records for immutable data, init-only properties for config, file-scoped namespaces:

```csharp
public record User(string Id, string Email, int Age);

public class Config
{
    public string ApiUrl { get; init; } = string.Empty;
}

namespace MyApp.Services;
```

## Error Handling

Throw custom exceptions with context; preserve inner exceptions:

```csharp
public class DataProcessingException : Exception
{
    public DataProcessingException(string message, Exception? inner = null)
        : base(message, inner) { }
}

try
{
    var content = await File.ReadAllTextAsync(filePath);
    return JsonSerializer.Deserialize<Data>(content)
        ?? throw new DataProcessingException("Deserialization failed");
}
catch (FileNotFoundException ex)
{
    throw new DataProcessingException($"File not found: {filePath}", ex);
}
```

## Async/Await

Always use async signatures. Use `ConfigureAwait(false)` in libraries:

```csharp
public async Task<User> GetUserAsync(string id)
{
    var user = await _repository.GetByIdAsync(id);
    return user ?? throw new NotFoundException($"User {id} not found");
}
```

## Related Resources

- See `languages/csharp/testing.md` for testing standards
- See `base/testing-philosophy.md` for testing principles
