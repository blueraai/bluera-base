---
description: Scan ~/.claude for issues without making changes
argument-hint: "[--json] [--verbose]"
allowed-tools: Bash(python3:*), Bash(ls:*), Bash(stat:*), Bash(du:*), Bash(find:*), Bash(uname:*), Read
---

# Claude Code Cleaner - Scan

Read-only scan of `~/.claude` and `~/.claude.json` for common issues that cause slow startup.

## What This Command Does

1. Collects metrics on Claude Code configuration files
2. Detects known issues (bloated cache, old sessions, etc.)
3. Reports findings ranked by risk level
4. **Makes no changes** - purely diagnostic

## Usage

```bash
/bluera-base:clean-scan           # Basic scan
/bluera-base:clean-scan --verbose # Show detailed progress
/bluera-base:clean-scan --json    # Machine-readable output
```

## Instructions

Run the scan script from the plugin directory:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/scripts/cc-cleaner-scan.py" $ARGUMENTS
```

Display the results to the user. If issues are found, suggest:

- `/bluera-base:clean` for interactive guided cleanup
- `/bluera-base:clean-fix <action>` for specific non-interactive fixes

## Risk Levels

| Level | Meaning |
|-------|---------|
| **CRITICAL** | Immediate action recommended |
| **HIGH** | Significant impact on performance |
| **MEDIUM** | May cause issues over time |
| **LOW** | Minor optimization opportunity |

## Safety

This command is read-only. It will:

- ✅ Stat files for size information
- ✅ Count entries in directories
- ✅ Parse JSON to count array lengths
- ❌ Never output secrets or auth tokens
- ❌ Never modify any files
