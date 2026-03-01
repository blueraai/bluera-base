# Tool Permissions Guide

This document explains the tool permissions in `settings.local.json.example`.

## Permission Categories

### Core (Required for Hooks)

These permissions are required for bluera-base hooks to function:

```json
"Bash(jq *)",          // JSON parsing in hooks
"Bash(git rev-parse *)",
"Bash(git status *)",
"Bash(git diff *)",
"Bash(git ls-files *)",
"Bash(git log *)"
```

### Git Operations (Recommended)

For auto-commit and release workflows:

```json
"Bash(git add *)",
"Bash(git commit *)",
"Bash(git fetch *)",
"Bash(git describe *)"
```

### GitHub / GitLab CLI (Optional)

For release workflow CI monitoring:

```json
"Bash(gh run *)",
"Bash(gh release *)",
"Bash(glab run *)",
"Bash(glab release *)"
```

### Notifications (Optional)

For permission prompt notifications:

```json
"Bash(osascript *)",    // macOS
"Bash(notify-send *)"   // Linux
```

### Package Managers (Project-Specific)

Choose based on your project's stack:

```json
"Bash(npm run *)",
"Bash(npm test *)",
"Bash(yarn run *)",
"Bash(pnpm run *)",
"Bash(bun run *)",
"Bash(bun x *)",
"Bash(npx *)"
```

### Linting & Type Checking (Project-Specific)

Choose based on your project's language:

**JavaScript/TypeScript:**

```json
"Bash(eslint *)",
"Bash(tsc --noEmit *)"
```

**Rust:**

```json
"Bash(cargo check *)",
"Bash(cargo clippy *)",
"Bash(rustfmt *)"
```

**Go:**

```json
"Bash(go vet *)",
"Bash(gofmt *)",
"Bash(golangci-lint run *)"
```

**Python:**

```json
"Bash(ruff check *)",
"Bash(flake8 *)",
"Bash(mypy *)"
```

### Code Analysis

For duplicate detection:

```json
"Bash(jscpd *)"
```

For shell script validation:

```json
"Bash(shellcheck *)"
```

## Deny List (Critical)

These patterns are always denied for safety:

```json
"Bash(* --no-verify *)",      // Never skip git hooks
"Bash(git push --force *)",   // Never force push
"Bash(rm -rf /)"              // Never delete root
```

## Minimal Setup

For the most restrictive setup that still allows hooks to function:

```json
{
  "permissions": {
    "allow": [
      "Bash(jq *)",
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)"
    ],
    "deny": [
      "Bash(* --no-verify *)",
      "Bash(git push --force *)"
    ]
  }
}
```

## Full Setup

Copy the complete `settings.local.json.example` file and customize based on your project's needs.
