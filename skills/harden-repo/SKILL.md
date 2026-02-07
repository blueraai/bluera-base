---
name: harden-repo
description: Best practices for setting up quality tooling across different language stacks.
argument-hint: "[--language <lang>] [--skip-hooks] [--coverage <threshold>]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

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
| `pom.xml` | Java | Maven |
| `build.gradle` | Java/Kotlin | Gradle |
| `build.gradle.kts` | Kotlin | Gradle |
| `Gemfile` | Ruby | Bundler |
| `composer.json` | PHP | Composer |
| `*.csproj` / `*.sln` | C#/.NET | dotnet |
| `Package.swift` | Swift | SwiftPM |
| `mix.exs` | Elixir | Mix |
| `CMakeLists.txt` | C/C++ | CMake |
| `Makefile` | C/C++ | Make |
| `build.sbt` | Scala | sbt |

---

## Language References

Per-language tooling configs (linting, formatting, type checking, hooks, coverage):

| Language | Reference |
|----------|-----------|
| JavaScript/TypeScript | skills/harden-repo/references/javascript-typescript.md |
| Python | skills/harden-repo/references/python.md |
| Rust | skills/harden-repo/references/rust.md |
| Go | skills/harden-repo/references/go.md |
| Java | skills/harden-repo/references/java.md |
| Kotlin | skills/harden-repo/references/kotlin.md |
| Ruby | skills/harden-repo/references/ruby.md |
| PHP | skills/harden-repo/references/php.md |
| C#/.NET | skills/harden-repo/references/csharp-dotnet.md |
| Swift | skills/harden-repo/references/swift.md |
| Elixir | skills/harden-repo/references/elixir.md |
| C/C++ | skills/harden-repo/references/c-cpp.md |
| Scala | skills/harden-repo/references/scala.md |

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

```text
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
6. **Test coverage** - Enforce minimum threshold (default: 80%)

---

## Common Mistakes

1. **Conflicting rules** - Ensure linter and formatter agree (use eslint-config-prettier)
2. **Missing hook permissions** - `chmod +x .git/hooks/*`
3. **Hook not running** - Ensure `.git/hooks/pre-commit` exists (not `.git/hooks/pre-commit.sample`)
4. **Too strict initially** - Start with warnings, graduate to errors

---

## Coverage Configuration

After hook setup, offer coverage configuration.

### Detection

Check for existing coverage config:

| Language | Config File |
|----------|-------------|
| JS/TS | `.c8rc.json`, `nyc.config.js`, `jest.config.js` (coverageThreshold) |
| Python | `pyproject.toml` [tool.coverage], `.coveragerc` |
| Rust | `tarpaulin.toml` |
| Go | `scripts/coverage-check.sh` |
| Ruby | `.simplecov` |
| Java | `pom.xml` (JaCoCo), `build.gradle` (jacocoTestCoverageVerification) |

If coverage already configured, show current threshold and offer to modify.

### Interactive Setup

Use AskUserQuestion for threshold selection:

```yaml
question: "Set up code coverage enforcement?"
header: "Coverage"
options:
  - label: "Skip"
    description: "No coverage configuration"
  - label: "80% threshold (Recommended)"
    description: "Industry standard coverage"
  - label: "90% threshold"
    description: "High coverage for mature projects"
  - label: "Custom"
    description: "Choose threshold and enforcement point"
```

If "Custom" selected:

**Threshold question:**

```yaml
question: "Minimum coverage threshold?"
header: "Threshold"
options:
  - label: "60%"
    description: "Minimum viable (legacy codebases)"
  - label: "70%"
    description: "Reasonable starting point"
  - label: "80% (Recommended)"
    description: "Industry standard"
  - label: "90%"
    description: "High coverage (mature projects)"
```

**Enforcement question:**

```yaml
question: "When should coverage be checked?"
header: "Enforcement"
options:
  - label: "None"
    description: "Manual checks only"
  - label: "Pre-commit"
    description: "Check before each commit"
  - label: "Pre-push"
    description: "Check before pushing"
  - label: "CI only"
    description: "Check in CI workflow"
```

### Per-Language Implementation

| Language | Tool | Config File | Install Command |
|----------|------|-------------|-----------------|
| JS/TS | c8 | `.c8rc.json` | `npm install -D c8` |
| Python | pytest-cov | `pyproject.toml` | `pip install pytest-cov` |
| Rust | cargo-tarpaulin | `tarpaulin.toml` | `cargo install cargo-tarpaulin` |
| Go | go test | `scripts/coverage-check.sh` | (built-in) |
| Ruby | SimpleCov | `.simplecov` | `gem install simplecov` |
| Java | JaCoCo | `pom.xml` / `build.gradle` | (plugin) |

### Enforcement Commands

Direct tool calls with context minimization (`--quiet` flags):

| Language | Command |
|----------|---------|
| JS/TS | `c8 --check-coverage --lines {{THRESHOLD}} --quiet npm test` |
| Python | `pytest --cov --cov-fail-under={{THRESHOLD}} -q` |
| Rust | `cargo tarpaulin --fail-under {{THRESHOLD}} --out Stdout 2>/dev/null` |
| Go | `go test -coverprofile=coverage.out ./... && go tool cover -func=coverage.out \| grep total \| awk '{if ($3+0 < {{THRESHOLD}}) exit 1}'` |
| Ruby | `bundle exec rspec --format progress` (SimpleCov handles threshold) |

### Hook Integration

**For husky (JS/TS projects):**

Append to `.husky/pre-commit` or create `.husky/pre-push`:

```bash
npm run test:coverage
```

**For pre-commit framework (Python):**

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: coverage
      name: coverage
      entry: pytest --cov --cov-fail-under=80 -q
      language: system
      pass_filenames: false
      always_run: true
```

**For native git hooks (Rust/Go):**

Append to `.git/hooks/pre-push`:

```bash
# Coverage check
cargo tarpaulin --fail-under 80 --out Stdout 2>/dev/null || exit 1
```

### CI Enforcement

Work with existing `.github/` infrastructure:

1. Detect existing workflow files (`ls .github/workflows/*.yml`)
2. Ask user which workflow to modify (or create new)
3. Add coverage step to appropriate job

Example step:

```yaml
- name: Check coverage
  run: npm run test:coverage
```

For Python:

```yaml
- name: Check coverage
  run: pytest --cov --cov-fail-under=${{ vars.COVERAGE_THRESHOLD || 80 }} -q
```

### Config Storage

Save coverage settings to `.bluera/bluera-base/config.json`:

```json
{
  "coverage": {
    "enabled": true,
    "threshold": 80,
    "enforce": "pre-push",
    "failOnDecrease": false
  }
}
```
