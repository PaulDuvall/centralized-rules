#!/bin/bash
# Description: Setup script for C# + .NET + Azure Functions test project
# Usage: ./csharp-azure-functions.sh
set -euo pipefail

cat > project.csproj <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <AzureFunctionsVersion>v4</AzureFunctionsVersion>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Azure.Functions.Worker" Version="1.20.0" />
  </ItemGroup>
</Project>
EOF

mkdir -p src
echo 'using Microsoft.Azure.Functions.Worker;' > src/Function.cs
