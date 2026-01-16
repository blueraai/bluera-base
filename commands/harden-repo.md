---
description: Set up git hooks, linters, formatters, and editor configs for a project
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion
argument-hint: [--language <js|python|rust|go>] [--skip-hooks]
---

# Harden Repo

Interactive setup for git hooks, linters, formatters, and quality tooling.

See @bluera-base/skills/repo-hardening/SKILL.md for language-specific best practices.

## Context

!`ls package.json pyproject.toml requirements.txt Cargo.toml go.mod 2>/dev/null || echo "No project files detected"`

## Workflow

### Phase 1: Detect Language

Check for project files to auto-detect language:

| File | Language |
|------|----------|
| `package.json` | JavaScript/TypeScript |
| `pyproject.toml` or `requirements.txt` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |

If multiple detected or none, use AskUserQuestion to clarify.

### Phase 2: Interview User

Use AskUserQuestion to determine:

1. **Confirm language/stack** (if not auto-detected)
2. **Select tools to set up**:
   - Linter (ESLint, ruff, clippy, golangci-lint)
   - Formatter (Prettier, ruff, rustfmt, gofmt)
   - Type checker (TypeScript, mypy, built-in)
   - Pre-commit hooks (husky, pre-commit, native git)
3. **Additional files**:
   - .editorconfig
   - .gitattributes

### Phase 3: Set Up Tooling

Based on selections, install and configure:

#### JavaScript/TypeScript

```bash
# Linting
npm install -D eslint @eslint/js typescript-eslint

# Formatting
npm install -D prettier eslint-config-prettier

# Hooks
npm install -D husky lint-staged
npx husky init
```

Create configs from templates:
- `.husky/pre-commit` from `@bluera-base/templates/repo-hardening/husky-pre-commit.template`
- `lint-staged.config.js` from `@bluera-base/templates/repo-hardening/lint-staged.config.template`

#### Python

```bash
# Linting + Formatting
pip install ruff
# or: uv add --dev ruff

# Hooks
pip install pre-commit
pre-commit install
```

Create configs from templates:
- `.pre-commit-config.yaml` from `@bluera-base/templates/repo-hardening/pre-commit-config.yaml.template`

Add to `pyproject.toml`:
```toml
[tool.ruff]
line-length = 88
target-version = "py311"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP", "B", "C4", "SIM"]
```

#### Rust

```bash
# Components (usually already installed)
rustup component add clippy rustfmt
```

Create native git hook from `@bluera-base/templates/repo-hardening/git-pre-commit-rust.template`:
```bash
cp template .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Add to `Cargo.toml`:
```toml
[lints.clippy]
all = "warn"
pedantic = "warn"
```

#### Go

```bash
# Install golangci-lint
go install github.com/golangci-lint/golangci-lint/cmd/golangci-lint@latest
```

Create native git hook from `@bluera-base/templates/repo-hardening/git-pre-commit-go.template`:
```bash
cp template .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

Create `.golangci.yml` with recommended linters.

### Phase 4: Universal Files

If selected, create:

**.editorconfig** from `@bluera-base/templates/repo-hardening/editorconfig.template`

**.gitattributes** from `@bluera-base/templates/repo-hardening/gitattributes.template`

### Phase 5: Summary

Report what was set up:

```
## Repo Hardening Complete

### Installed
- [x] ESLint + Prettier
- [x] husky + lint-staged
- [x] .editorconfig
- [x] .gitattributes

### Next Steps
1. Review generated configs
2. Run `npm run lint` to verify
3. Make a test commit to verify hooks
```

## Constraints

- Never overwrite existing configs without confirmation
- Detect existing tooling and offer to update vs replace
- Skip hooks setup if `--skip-hooks` flag provided
- Always make hooks executable (`chmod +x`)

## Error Recovery

If installation fails:
1. Check package manager is available
2. Check network connectivity
3. Offer manual installation instructions
