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

### Coverage: c8

```bash
npm install -D c8
```

**Config: .c8rc.json**

```json
{
  "check-coverage": true,
  "lines": 80,
  "branches": 80,
  "functions": 80,
  "statements": 80,
  "reporter": ["text", "lcov", "html"],
  "exclude": ["**/*.test.{js,ts}", "**/*.spec.{js,ts}", "node_modules/**"]
}
```

**package.json script**:

```json
{
  "scripts": {
    "test:coverage": "c8 npm test"
  }
}
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

### Coverage: pytest-cov

```bash
pip install pytest-cov
# or: uv add --dev pytest-cov
```

**pyproject.toml**:

```toml
[tool.pytest.ini_options]
addopts = "--cov=src --cov-report=term-missing --cov-fail-under=80"

[tool.coverage.run]
branch = true
source = ["src"]

[tool.coverage.report]
fail_under = 80
show_missing = true
exclude_lines = [
    "pragma: no cover",
    "if TYPE_CHECKING:",
]
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

### Coverage: cargo-tarpaulin

```bash
cargo install cargo-tarpaulin
```

**Run with threshold**:

```bash
cargo tarpaulin --fail-under 80
```

**Optional config: tarpaulin.toml**

```toml
[general]
fail-under = 80
out = ["Lcov", "Html"]
skip-clean = true
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

### Coverage: go test (built-in)

```bash
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out
```

**Threshold check script**:

```bash
#!/bin/sh
COVERAGE=$(go test -coverprofile=coverage.out ./... 2>&1 | grep -o 'coverage: [0-9.]*%' | grep -o '[0-9.]*')
THRESHOLD=80
if [ "$(echo "$COVERAGE < $THRESHOLD" | bc -l)" -eq 1 ]; then
  echo "Coverage $COVERAGE% is below $THRESHOLD%"
  exit 1
fi
```

---

## Java

### Linting: Checkstyle

**Maven**:

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-checkstyle-plugin</artifactId>
    <version>3.3.1</version>
    <configuration>
        <configLocation>google_checks.xml</configLocation>
    </configuration>
</plugin>
```

**Run**: `mvn checkstyle:check`

### Formatting: google-java-format (via Spotless)

**Maven**:

```xml
<plugin>
    <groupId>com.diffplug.spotless</groupId>
    <artifactId>spotless-maven-plugin</artifactId>
    <version>2.43.0</version>
    <configuration>
        <java>
            <googleJavaFormat/>
        </java>
    </configuration>
</plugin>
```

**Run**: `mvn spotless:apply`

### Coverage: JaCoCo

**Maven (pom.xml)**:

```xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <goals><goal>prepare-agent</goal></goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals><goal>report</goal></goals>
        </execution>
        <execution>
            <id>check</id>
            <goals><goal>check</goal></goals>
            <configuration>
                <rules>
                    <rule>
                        <element>BUNDLE</element>
                        <limits>
                            <limit>
                                <counter>LINE</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.80</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

**Gradle (build.gradle)**:

```groovy
plugins {
    id 'jacoco'
}

jacoco {
    toolVersion = "0.8.11"
}

jacocoTestCoverageVerification {
    violationRules {
        rule {
            limit {
                minimum = 0.80
            }
        }
    }
}

check.dependsOn jacocoTestCoverageVerification
```

---

## Kotlin

### Linting: detekt

**build.gradle.kts**:

```kotlin
plugins {
    id("io.gitlab.arturbosch.detekt") version "1.23.4"
}

detekt {
    config.setFrom("detekt.yml")
    buildUponDefaultConfig = true
}
```

**detekt.yml**:

```yaml
complexity:
  LongMethod:
    threshold: 60
style:
  MaxLineLength:
    maxLineLength: 120
```

### Formatting: ktlint

**build.gradle.kts**:

```kotlin
plugins {
    id("org.jlleitschuh.gradle.ktlint") version "12.1.0"
}
```

**Run**: `./gradlew ktlintFormat`

### Coverage: Kover

**build.gradle.kts**:

```kotlin
plugins {
    id("org.jetbrains.kotlinx.kover") version "0.7.6"
}

koverReport {
    verify {
        rule {
            minBound(80)
        }
    }
}
```

---

## Ruby

### Linting + Formatting: RuboCop

```bash
gem install rubocop
# or add to Gemfile: gem 'rubocop', require: false, group: :development
```

**.rubocop.yml**:

```yaml
AllCops:
  NewCops: enable
  TargetRubyVersion: 3.2

Style/StringLiterals:
  EnforcedStyle: double_quotes

Layout/LineLength:
  Max: 120
```

### Git Hooks: Overcommit

```bash
gem install overcommit
overcommit --install
```

**.overcommit.yml**:

```yaml
PreCommit:
  RuboCop:
    enabled: true
    command: ['rubocop', '--auto-correct']
```

### Type Checking: Sorbet (optional)

```bash
gem install sorbet sorbet-runtime
srb init
```

### Coverage: SimpleCov

```bash
gem install simplecov
# or add to Gemfile: gem 'simplecov', require: false, group: :test
```

**spec/spec_helper.rb**:

```ruby
require 'simplecov'
SimpleCov.start do
  minimum_coverage 80
  minimum_coverage_by_file 70
  add_filter '/spec/'
  add_filter '/test/'
end
```

---

## PHP

### Linting + Type Checking: PHPStan

```bash
composer require --dev phpstan/phpstan
```

**phpstan.neon**:

```neon
parameters:
    level: 8
    paths:
        - src
    excludePaths:
        - tests
```

### Formatting: PHP-CS-Fixer

```bash
composer require --dev friendsofphp/php-cs-fixer
```

**.php-cs-fixer.php**:

```php
<?php
return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12' => true,
        'array_syntax' => ['syntax' => 'short'],
        'no_unused_imports' => true,
    ])
    ->setFinder(PhpCsFixer\Finder::create()->in(__DIR__.'/src'));
```

### Git Hooks: GrumPHP

```bash
composer require --dev phpro/grumphp
```

**grumphp.yml**:

```yaml
grumphp:
    tasks:
        phpstan: ~
        phpcsfixer: ~
```

### Coverage: PCOV

```bash
composer require --dev pcov/clobber
```

**phpunit.xml**:

```xml
<phpunit>
    <coverage>
        <report>
            <clover outputFile="coverage.xml"/>
            <html outputDirectory="coverage-html"/>
        </report>
    </coverage>
    <source>
        <include>
            <directory>src</directory>
        </include>
    </source>
</phpunit>
```

**Run with threshold**:

```bash
XDEBUG_MODE=coverage ./vendor/bin/phpunit --coverage-text --min=80
```

---

## C#/.NET

### Linting: Roslyn Analyzers

```bash
dotnet add package Microsoft.CodeAnalysis.NetAnalyzers
```

**.editorconfig (C# rules)**:

```ini
[*.cs]
dotnet_analyzer_diagnostic.severity = warning
dotnet_style_qualification_for_field = false:warning
csharp_style_var_when_type_is_apparent = true:suggestion
```

### Formatting: dotnet format

```bash
dotnet format
```

### Git Hooks: Husky.Net

```bash
dotnet tool install --global Husky
husky install
```

**.husky/pre-commit**:

```bash
#!/bin/sh
dotnet format --verify-no-changes
dotnet build --no-restore
```

### Coverage: coverlet

```bash
dotnet add package coverlet.collector
dotnet add package coverlet.msbuild
```

**Run with threshold**:

```bash
dotnet test /p:CollectCoverage=true /p:Threshold=80 /p:ThresholdType=line
```

---

## Swift

### Linting: SwiftLint

```bash
brew install swiftlint
```

**.swiftlint.yml**:

```yaml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - closure_spacing
line_length: 120
```

### Formatting: SwiftFormat

```bash
brew install swiftformat
```

**.swiftformat**:

```text
--indent 4
--allman false
--wraparguments before-first
```

### Git Hooks: Native

**.git/hooks/pre-commit**:

```bash
#!/bin/sh
swiftlint --strict || exit 1
swiftformat --lint . || exit 1
```

### Coverage: llvm-cov

**Run with SwiftPM**:

```bash
swift test --enable-code-coverage
```

**Run with Xcode**:

```bash
xcodebuild test -scheme MyApp -enableCodeCoverage YES
```

---

## Elixir

### Linting: Credo

**mix.exs**:

```elixir
defp deps do
  [{:credo, "~> 1.7", only: [:dev, :test], runtime: false}]
end
```

**.credo.exs**:

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

### Formatting: mix format (built-in)

**.formatter.exs**:

```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120
]
```

### Type Checking: Dialyzer (optional)

**mix.exs**:

```elixir
defp deps do
  [{:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}]
end
```

### Git Hooks: Native

**.git/hooks/pre-commit**:

```bash
#!/bin/sh
mix format --check-formatted || exit 1
mix credo --strict || exit 1
```

### Coverage: excoveralls

**mix.exs**:

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

**coveralls.json**:

```json
{
  "coverage_options": {
    "minimum_coverage": 80
  },
  "skip_files": ["test/"]
}
```

**Run**: `mix coveralls --min 80`

---

## C/C++

### Linting: clang-tidy

**.clang-tidy**:

```yaml
Checks: >
  -*,
  bugprone-*,
  clang-analyzer-*,
  cppcoreguidelines-*,
  modernize-*,
  performance-*,
  readability-*
WarningsAsErrors: ''
HeaderFilterRegex: '.*'
```

**CMakeLists.txt integration**:

```cmake
find_program(CLANG_TIDY clang-tidy)
if(CLANG_TIDY)
    set(CMAKE_CXX_CLANG_TIDY ${CLANG_TIDY})
endif()
```

### Formatting: clang-format

**.clang-format**:

```yaml
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 120
AllowShortFunctionsOnASingleLine: Inline
BreakBeforeBraces: Attach
```

### Git Hooks: Native

**.git/hooks/pre-commit**:

```bash
#!/bin/sh
find src -name '*.cpp' -o -name '*.h' | xargs clang-format --dry-run --Werror || exit 1
find src -name '*.cpp' | xargs clang-tidy -- -std=c++17 || exit 1
```

### Coverage: gcov/lcov

**CMakeLists.txt**:

```cmake
option(COVERAGE "Enable coverage" OFF)
if(COVERAGE)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} --coverage")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage")
endif()
```

**Generate report**:

```bash
./tests  # run tests
lcov --capture --directory . --output-file coverage.info
genhtml coverage.info --output-directory coverage-html
```

**Threshold check**:

```bash
#!/bin/sh
COVERAGE=$(lcov --summary coverage.info 2>&1 | grep 'lines' | grep -o '[0-9.]*%' | head -1 | sed 's/%//')
if [ "$(echo "$COVERAGE < 80" | bc -l)" -eq 1 ]; then
  echo "Coverage $COVERAGE% is below 80%"
  exit 1
fi
```

---

## Scala

### Linting: scalafix

**project/plugins.sbt**:

```scala
addSbtPlugin("ch.epfl.scala" % "sbt-scalafix" % "0.11.1")
```

**.scalafix.conf**:

```hocon
rules = [
  RemoveUnused,
  DisableSyntax,
  OrganizeImports
]
DisableSyntax.noVars = true
DisableSyntax.noNulls = true
```

### Formatting: scalafmt

**project/plugins.sbt**:

```scala
addSbtPlugin("org.scalameta" % "sbt-scalafmt" % "2.5.2")
```

**.scalafmt.conf**:

```hocon
version = 3.7.17
runner.dialect = scala3
maxColumn = 120
align.preset = more
rewrite.rules = [SortImports, RedundantBraces]
```

### Git Hooks: Native

**.git/hooks/pre-commit**:

```bash
#!/bin/sh
sbt scalafmtCheckAll || exit 1
sbt "scalafix --check" || exit 1
```

### Coverage: scoverage

**project/plugins.sbt**:

```scala
addSbtPlugin("org.scoverage" % "sbt-scoverage" % "2.0.9")
```

**build.sbt**:

```scala
coverageMinimumStmtTotal := 80
coverageFailOnMinimum := true
coverageExcludedPackages := "<empty>;.*\\.generated\\..*"
```

**Run**: `sbt coverage test coverageReport`

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
