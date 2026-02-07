# Swift

Quality tooling for Swift projects.

---

## Linting: SwiftLint

```bash
brew install swiftlint
```

**.swiftlint.yml:**

```yaml
disabled_rules:
  - trailing_whitespace
opt_in_rules:
  - empty_count
  - closure_spacing
line_length: 120
```

---

## Formatting: SwiftFormat

```bash
brew install swiftformat
```

**.swiftformat:**

```text
--indent 4
--allman false
--wraparguments before-first
```

---

## Git Hooks: Native

**.git/hooks/pre-commit:**

```bash
#!/bin/sh
swiftlint --strict || exit 1
swiftformat --lint . || exit 1
```

---

## Coverage: llvm-cov

**Run with SwiftPM:**

```bash
swift test --enable-code-coverage
```

**Run with Xcode:**

```bash
xcodebuild test -scheme MyApp -enableCodeCoverage YES
```
