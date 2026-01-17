---
description: Set up git hooks, linters, formatters, and editor configs for a project
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion
argument-hint: [--language <lang>] [--skip-hooks] [--coverage <threshold>]
---

# Harden Repo

Interactive setup for git hooks, linters, formatters, coverage, and quality tooling.

**Also checks existing hardening and identifies gaps** (e.g., missing coverage configuration).

See @bluera-base/skills/repo-hardening/SKILL.md for language-specific best practices.

## Context

!`ls package.json pyproject.toml requirements.txt Cargo.toml go.mod pom.xml build.gradle build.gradle.kts Gemfile composer.json Package.swift mix.exs CMakeLists.txt build.sbt 2>/dev/null || echo "No project files detected"`

## Workflow

### Phase 0: Check Existing Hardening

Before setting up, check what's already configured:

```bash
# Detect task runner (independent of language!)
ls package.json Makefile justfile Taskfile.yml 2>/dev/null

# Detect existing configs
ls .editorconfig .gitattributes .pre-commit-config.yaml .husky/pre-commit .git/hooks/pre-commit 2>/dev/null
ls eslint.config.* .eslintrc* .prettierrc* pyproject.toml .rubocop.yml .clang-format 2>/dev/null

# Detect coverage configs
ls .c8rc* .nycrc* coveralls.json .simplecov tarpaulin.toml 2>/dev/null
grep -q "pytest-cov\|coverage" pyproject.toml 2>/dev/null && echo "pytest-cov configured"
grep -q "tool.coverage" pyproject.toml 2>/dev/null && echo "coverage.py configured"
grep -q "test:coverage\|test-coverage" package.json Makefile justfile 2>/dev/null && echo "coverage script exists"
```

**Status table to show:**

| Component | Status | Notes |
|-----------|--------|-------|
| Task Runner | - | (package.json/Makefile/justfile/etc.) |
| Linter | ✓ / ✗ | (which tool) |
| Formatter | ✓ / ✗ | (which tool) |
| Type Checker | ✓ / ✗ | (which tool) |
| Pre-commit Hooks | ✓ / ✗ | (husky/pre-commit/native) |
| Test Coverage | ✓ / ✗ | (tool + threshold + script location) |
| .editorconfig | ✓ / ✗ | |
| .gitattributes | ✓ / ✗ | |

**If already hardened:** Show status table and identify gaps. Use AskUserQuestion to offer adding missing components (especially coverage if not configured).

**If not hardened:** Continue to Phase 1.

### Phase 1: Detect Language

Check for project files to auto-detect language:

| File | Language |
|------|----------|
| `package.json` | JavaScript/TypeScript |
| `pyproject.toml` or `requirements.txt` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pom.xml` | Java (Maven) |
| `build.gradle` or `build.gradle.kts` | Java/Kotlin (Gradle) |
| `Gemfile` | Ruby |
| `composer.json` | PHP |
| `*.csproj` or `*.sln` | C#/.NET |
| `Package.swift` | Swift |
| `mix.exs` | Elixir |
| `CMakeLists.txt` or `Makefile` | C/C++ |
| `build.sbt` | Scala |

If multiple detected or none, use AskUserQuestion to clarify.

### Phase 2: Interview User

Use AskUserQuestion to determine:

1. **Confirm language/stack** (if not auto-detected)
2. **Select tools to set up**:
   - Linter (ESLint, ruff, clippy, golangci-lint, etc.)
   - Formatter (Prettier, ruff, rustfmt, gofmt, etc.)
   - Type checker (TypeScript, mypy, built-in, etc.)
   - Pre-commit hooks (husky, pre-commit, native git)
3. **Test coverage** (optional):
   - Enable coverage enforcement? (Yes/No)
   - Coverage threshold (default: 80%)
4. **Additional files**:
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

**Coverage (if selected):**

```bash
npm install -D c8
```

Create `.c8rc.json` from `@bluera-base/templates/repo-hardening/c8rc.template`

Add to `package.json` scripts:

```json
{
  "scripts": {
    "test:coverage": "c8 npm test"
  }
}
```

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

**Coverage (if selected):**

```bash
pip install pytest-cov
# or: uv add --dev pytest-cov
```

Add to `pyproject.toml`:

```toml
[tool.pytest.ini_options]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"

[tool.coverage.run]
branch = true
source = ["src"]

[tool.coverage.report]
fail_under = 80
show_missing = true
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

**Coverage (if selected):**

```bash
cargo install cargo-tarpaulin
```

Add script or Makefile target: `cargo tarpaulin --fail-under 80`

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

**Coverage (if selected):**

Add to `Makefile` or scripts:

```makefile
test-coverage:
 go test -coverprofile=coverage.out ./...
 @COVERAGE=$$(go tool cover -func=coverage.out | grep total | awk '{print $$3}' | sed 's/%//'); \
 if [ $$(echo "$$COVERAGE < 80" | bc -l) -eq 1 ]; then \
  echo "Coverage $$COVERAGE% is below 80%"; exit 1; \
 fi
```

#### Java (Maven)

```bash
# Add JaCoCo plugin to pom.xml for coverage
# Add Checkstyle plugin for linting
# Add Spotless plugin for formatting
```

See @bluera-base/skills/repo-hardening/SKILL.md for full Maven/Gradle configurations.

#### Java/Kotlin (Gradle)

```bash
# Add plugins to build.gradle(.kts)
# - JaCoCo or Kover for coverage
# - Checkstyle or detekt for linting
# - Spotless or ktlint for formatting
```

See @bluera-base/skills/repo-hardening/SKILL.md for full Gradle configurations.

#### Ruby

```bash
# Linting + Formatting
gem install rubocop
# or add to Gemfile: gem 'rubocop', require: false, group: :development

# Coverage
gem install simplecov
# or add to Gemfile: gem 'simplecov', require: false, group: :test

# Hooks
gem install overcommit
overcommit --install
```

#### PHP

```bash
# Linting
composer require --dev phpstan/phpstan

# Formatting
composer require --dev friendsofphp/php-cs-fixer

# Coverage
composer require --dev pcov/clobber

# Hooks
composer require --dev phpro/grumphp
```

#### C#/.NET

```bash
# Linting (Roslyn analyzers)
dotnet add package Microsoft.CodeAnalysis.NetAnalyzers

# Formatting (built-in)
dotnet format

# Coverage
dotnet add package coverlet.collector
dotnet add package coverlet.msbuild

# Hooks
dotnet tool install --global Husky
husky install
```

#### Swift

```bash
# Linting
brew install swiftlint

# Formatting
brew install swiftformat

# Coverage (built-in with Xcode/SwiftPM)
swift test --enable-code-coverage
```

#### Elixir

```bash
# Linting
mix archive.install hex credo

# Formatting (built-in)
mix format

# Coverage - add to mix.exs deps:
# {:excoveralls, "~> 0.18", only: :test}
```

#### C/C++

```bash
# Linting
# clang-tidy (usually installed with LLVM/Clang)

# Formatting
# clang-format (usually installed with LLVM/Clang)

# Coverage (compile with flags)
# gcc -fprofile-arcs -ftest-coverage
# lcov for reports
```

#### Scala

```bash
# Add to project/plugins.sbt:
# - sbt-scalafix for linting
# - sbt-scalafmt for formatting
# - sbt-scoverage for coverage
```

### Phase 3.5: Coverage Setup

If coverage was selected:

1. **Detect task runner/script system** (independent of language):

   | File | Task Runner |
   |------|-------------|
   | `package.json` | npm/bun/yarn scripts |
   | `Makefile` | make |
   | `justfile` | just |
   | `Taskfile.yml` | task |
   | `pyproject.toml` (with `[tool.poetry.scripts]` or `[project.scripts]`) | poetry/pdm |
   | None of the above | Direct invocation (uv run, pytest, cargo, go test, etc.) |

   **Important**: A Python project may use `package.json` for scripts. A Go project may use `Makefile`. Don't assume language = task runner.

   **If no task runner**: Configure coverage via tool-specific config files (pyproject.toml `[tool.coverage.*]`, `.c8rc.json`, etc.) rather than scripts.

2. **Check current coverage** (if tests exist):

   ```bash
   # Run tests with coverage to see current state
   # e.g., npm run test:coverage, pytest --cov, etc.
   ```

3. **If current coverage < threshold**: Use AskUserQuestion with options:
   - "Keep 80% threshold (will fail until coverage improves)"
   - "Set threshold to current coverage (X%)"
   - "Skip coverage enforcement for now"

4. **Add coverage configuration to detected task runner**:

   | Task Runner | How to Add |
   |-------------|------------|
   | package.json | Add to `"scripts"`: `"test:coverage": "<coverage-command>"` |
   | Makefile | Add target: `test-coverage: <coverage-command>` |
   | justfile | Add recipe: `test-coverage: <coverage-command>` |
   | pyproject.toml (poetry/pdm) | Add to `[tool.poetry.scripts]` |
   | **None (uv/pytest direct)** | Configure in `[tool.pytest.ini_options]` addopts with `--cov-fail-under=80`, or add `[tool.coverage.report]` section |

   **For repos with no task runner (uv, raw pytest, etc.):**

   Add to `pyproject.toml`:

   ```toml
   [tool.pytest.ini_options]
   addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"

   [tool.coverage.report]
   fail_under = 80
   show_missing = true
   ```

5. **Configure coverage tool based on language**:

| Language | Tool | Threshold Config |
|----------|------|------------------|
| JS/TS | c8 | `.c8rc.json` + add `"test:coverage": "c8 npm test"` to package.json |
| Python | pytest-cov | `pyproject.toml` `[tool.coverage.report]` `fail_under` |
| Rust | cargo-tarpaulin | `--fail-under` flag |
| Go | go test -cover | Script check against threshold |
| Java | JaCoCo | `<minimum>0.80</minimum>` in pom.xml |
| Kotlin | Kover | `minBound(80)` in build.gradle.kts |
| Ruby | SimpleCov | `minimum_coverage 80` in config |
| PHP | PCOV | `--min=80` flag |
| C#/.NET | coverlet | `/p:Threshold=80` |
| Swift | llvm-cov | Script check |
| Elixir | excoveralls | `"minimum_coverage": 80` in coveralls.json |
| C/C++ | lcov | Script check |
| Scala | scoverage | `coverageMinimumStmtTotal := 80` |

### Phase 4: Universal Files

If selected, create:

**.editorconfig** from `@bluera-base/templates/repo-hardening/editorconfig.template`

**.gitattributes** from `@bluera-base/templates/repo-hardening/gitattributes.template`

### Phase 5: Summary

Report what was set up:

```text
## Repo Hardening Complete

### Installed
- [x] Linter (ESLint/ruff/clippy/etc.)
- [x] Formatter (Prettier/ruff/rustfmt/etc.)
- [x] Pre-commit hooks
- [x] Test coverage (80% threshold)
- [x] .editorconfig
- [x] .gitattributes

### Next Steps
1. Review generated configs
2. Run linter to verify setup
3. Run tests with coverage to verify threshold
4. Make a test commit to verify hooks
```

## Constraints

- Never overwrite existing configs without confirmation
- Detect existing tooling and offer to update vs replace
- Skip hooks setup if `--skip-hooks` flag provided
- Always make hooks executable (`chmod +x`)
- **NEVER autonomously lower coverage thresholds** - if current coverage is below the target threshold, use AskUserQuestion to let the user decide:
  - Keep the threshold and work toward it
  - Lower to match current coverage
  - Skip coverage enforcement entirely
- Do not make judgments about "expected" low coverage - let the user decide what's acceptable

## Error Recovery

If installation fails:

1. Check package manager is available
2. Check network connectivity
3. Offer manual installation instructions
