# Repo Hardening Skill

Best practices for setting up quality tooling across different language stacks.

---

## Language Detection

Detect stack from project files:

| File | Language | Package Manager |
|------|----------|-----------------|
| `package.json` | JavaScript/TypeScript | npm/yarn/pnpm/bun |
| `pyproject.toml` | Python | pip/poetry/uv |
| `requirements.txt` | Python | pip |
| `Cargo.toml` | Rust | cargo |
| `go.mod` | Go | go |

---

## JavaScript/TypeScript

### Linting: ESLint

```bash
# Install
npm install -D eslint @eslint/js typescript-eslint

# Config: eslint.config.js (flat config)
```

**Recommended rules**:
- `@typescript-eslint/no-unused-vars`
- `@typescript-eslint/no-explicit-any`
- `no-console` (warn)

### Formatting: Prettier

```bash
npm install -D prettier eslint-config-prettier
```

**Config: .prettierrc**
```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5"
}
```

### Type Checking: TypeScript

```bash
npm install -D typescript
```

**tsconfig.json strict options**:
```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

### Git Hooks: husky + lint-staged

```bash
npm install -D husky lint-staged
npx husky init
```

**package.json**:
```json
{
  "lint-staged": {
    "*.{js,ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{json,md}": ["prettier --write"]
  }
}
```

**.husky/pre-commit**:
```bash
npx lint-staged
```

---

## Python

### Linting + Formatting: ruff

```bash
pip install ruff
# or: uv add --dev ruff
```

**pyproject.toml**:
```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "SIM"]
ignore = ["E501"]  # Line length handled by formatter

[tool.ruff.format]
quote-style = "double"
```

### Type Checking: mypy or pyright

```bash
pip install mypy
```

**pyproject.toml**:
```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true
```

### Git Hooks: pre-commit

```bash
pip install pre-commit
pre-commit install
```

**.pre-commit-config.yaml**:
```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.4.4
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.10.0
    hooks:
      - id: mypy
        additional_dependencies: []
```

---

## Rust

### Linting: clippy

```bash
# Built into rustup
rustup component add clippy
```

**Cargo.toml**:
```toml
[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"
```

### Formatting: rustfmt

```bash
rustup component add rustfmt
```

**rustfmt.toml**:
```toml
edition = "2021"
max_width = 100
tab_spaces = 4
```

### Git Hooks: Native

**.git/hooks/pre-commit**:
```bash
#!/bin/sh
cargo fmt --check || exit 1
cargo clippy -- -D warnings || exit 1
```

---

## Go

### Linting: golangci-lint

```bash
# Install
go install github.com/golangci-lint/golangci-lint/cmd/golangci-lint@latest
```

**.golangci.yml**:
```yaml
linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports

linters-settings:
  gofmt:
    simplify: true
```

### Formatting: gofmt/goimports

```bash
# Built into Go
go fmt ./...
```

### Git Hooks: Native

**.git/hooks/pre-commit**:
```bash
#!/bin/sh
go fmt ./... || exit 1
golangci-lint run || exit 1
```

---

## .editorconfig

Universal editor settings:

```ini
root = true

[*]
indent_style = space
indent_size = 2
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{py,rs}]
indent_size = 4

[*.go]
indent_style = tab
indent_size = 4

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
```

---

## .gitattributes

Normalize line endings:

```
* text=auto eol=lf
*.{cmd,[cC][mM][dD]} text eol=crlf
*.{bat,[bB][aA][tT]} text eol=crlf
*.pdf binary
*.png binary
*.jpg binary
*.gif binary
```

---

## Setup Priority

1. **.editorconfig** - Universal, no dependencies
2. **Linter** - Catches bugs early
3. **Formatter** - Consistent style
4. **Git hooks** - Enforce on commit
5. **Type checker** - Optional but recommended

---

## Common Mistakes

1. **Conflicting rules** - Ensure linter and formatter agree (use eslint-config-prettier)
2. **Missing hook permissions** - `chmod +x .git/hooks/*`
3. **Hook not running** - Ensure `.git/hooks/pre-commit` exists (not `.git/hooks/pre-commit.sample`)
4. **Too strict initially** - Start with warnings, graduate to errors
