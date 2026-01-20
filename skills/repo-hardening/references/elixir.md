# Elixir

Quality tooling for Elixir projects.

---

## Linting: Credo

**mix.exs:**

```elixir
defp deps do
  [{:credo, "~> 1.7", only: [:dev, :test], runtime: false}]
end
```

**.credo.exs:**

```elixir
%{
  configs: [
    %{
      name: "default",
      strict: true,
      checks: [
        {Credo.Check.Readability.MaxLineLength, max_length: 120}
      ]
    }
  ]
}
```

---

## Formatting: mix format (built-in)

**.formatter.exs:**

```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120
]
```

---

## Type Checking: Dialyzer (optional)

**mix.exs:**

```elixir
defp deps do
  [{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}]
end
```

---

## Git Hooks: Native

**.git/hooks/pre-commit:**

```bash
#!/bin/sh
mix format --check-formatted || exit 1
mix credo --strict || exit 1
```

---

## Coverage: excoveralls

**mix.exs:**

```elixir
defp deps do
  [{:excoveralls, "~> 0.18", only: :test}]
end

def project do
  [
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [coveralls: :test]
  ]
end
```

**coveralls.json:**

```json
{
  "coverage_options": {
    "minimum_coverage": 80
  },
  "skip_files": ["test/"]
}
```

**Run:** `mix coveralls --min 80`
