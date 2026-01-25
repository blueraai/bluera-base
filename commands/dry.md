---
description: Detect duplicate code and suggest DRY refactors using jscpd
allowed-tools: Bash(jscpd:*), Bash(npx:*), Bash(command:*), Bash(mkdir:*), Bash(cat:*), Bash(jq:*), Read, Write, Glob, Grep
argument-hint: [scan|report|config|init] [--threshold N] [--path <dir>]
---

# DRY Check

Detect duplicate code across your codebase using jscpd.

## Subcommands

| Command | Description |
|---------|-------------|
| `dry` or `dry scan` | Run duplication scan |
| `dry report` | Show last scan results |
| `dry config` | Show current jscpd configuration |
| `dry init` | Create project-specific jscpd.json |

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--threshold N` | Minimum token count for duplicate detection (higher = fewer matches) | jscpd default |
| `--path <dir>` | Directory to scan for duplicates | Current directory |

### Examples

```bash
# Scan with higher threshold (find only large duplicates)
/bluera-base:dry scan --threshold 100

# Scan specific directory
/bluera-base:dry scan --path src/

# Combine both
/bluera-base:dry scan --threshold 75 --path lib/
```

## Workflow

See @bluera-base/skills/dry-refactor/SKILL.md for language-specific refactoring guidance.

**Phases:** Check jscpd → Scan codebase → Report duplicates → Suggest refactors
