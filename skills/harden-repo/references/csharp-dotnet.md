# C#/.NET

Quality tooling for C# and .NET projects.

---

## Linting: Roslyn Analyzers

```bash
dotnet add package Microsoft.CodeAnalysis.NetAnalyzers
```

**.editorconfig (C# rules):**

```ini
[*.cs]
dotnet_analyzer_diagnostic.severity = warning
dotnet_style_qualification_for_field = false:warning
csharp_style_var_when_type_is_apparent = true:suggestion
```

---

## Formatting: dotnet format

```bash
dotnet format
```

---

## Git Hooks: Husky.Net

```bash
dotnet tool install --global Husky
husky install
```

**.husky/pre-commit:**

```bash
#!/bin/sh
dotnet format --verify-no-changes
dotnet build --no-restore
```

---

## Coverage: coverlet

```bash
dotnet add package coverlet.collector
dotnet add package coverlet.msbuild
```

**Run with threshold:**

```bash
dotnet test /p:CollectCoverage=true /p:Threshold=80 /p:ThresholdType=line
```
