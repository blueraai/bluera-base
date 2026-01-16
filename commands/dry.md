---
description: Detect duplicate code and suggest DRY refactors using jscpd
allowed-tools: Bash(jscpd:*), Bash(npx:*), Bash(command:*), Bash(mkdir:*), Bash(cat:*), Bash(wc:*), Bash(jq:*), Read, Write, Glob, Grep
argument-hint: [scan|report|config|init] [--threshold N] [--path <dir>]
---

# DRY Check

Detect duplicate code across your codebase using jscpd (cross-language copy/paste detector).

## Subcommands

| Command | Description |
|---------|-------------|
| `/dry` or `/dry scan` | Run duplication scan |
| `/dry report` | Show last scan results |
| `/dry config` | Show current jscpd configuration |
| `/dry init` | Create project-specific jscpd.json |

---

## Algorithm

### Scan (default)

1. **Check jscpd availability**:
   ```bash
   if command -v jscpd &>/dev/null; then
     JSCPD="jscpd"
   else
     JSCPD="npx --yes jscpd"
   fi
   ```

2. **Ensure output directory exists**:
   ```bash
   mkdir -p .bluera/bluera-base/state
   ```

3. **Run jscpd scan**:
   ```bash
   $JSCPD . \
     --min-tokens 70 \
     --min-lines 5 \
     --gitignore \
     --ignore "**/node_modules/**,**/dist/**,**/build/**,**/target/**,**/.git/**,**/vendor/**" \
     --reporters json \
     --output .bluera/bluera-base/state \
     --silent
   ```

4. **Parse JSON output** from `.bluera/bluera-base/state/jscpd-report.json`

5. **Generate markdown report** at `.bluera/bluera-base/state/dry-report.md`

6. **Present findings** with:
   - Summary statistics (total duplicates, affected lines)
   - Top duplicates ranked by token count
   - Suggested refactoring targets

### Report

1. Read `.bluera/bluera-base/state/dry-report.md`
2. If not found, suggest running `/dry scan` first

### Config

1. Check for project config at `.jscpd.json` or `jscpd.json`
2. Show effective configuration
3. Show path to template at `templates/jscpd.json.template`

### Init

1. Copy template to project: `.jscpd.json`
2. Customize based on detected languages

---

## Output Format

Generate `.bluera/bluera-base/state/dry-report.md`:

```markdown
# DRY Report

**Project**: /path/to/project
**Scanned**: 2026-01-16 12:00:00
**Engine**: jscpd

## Summary

| Metric | Value |
|--------|-------|
| Duplicates found | 8 |
| Total files scanned | 150 |
| Duplicate lines | 342 |
| Duplication % | 2.2% |

## Top Duplicates

### 1. [156 tokens, 23 lines]

| File | Lines |
|------|-------|
| `src/handlers/user.ts` | 45-67 |
| `src/handlers/admin.ts` | 23-45 |

**Language**: typescript
**Suggestion**: Extract to `src/utils/validators.ts`

---

### 2. [89 tokens, 15 lines]

...

## Refactoring Guidance

For detailed refactoring patterns, see:
- @dry-refactor skill for general workflow
- @dry-refactor/references/patterns.md for language-specific examples

## Configuration

To customize thresholds, create `.jscpd.json`:
\`\`\`bash
/dry init
\`\`\`
```

---

## Configuration Options

jscpd can be configured via `.jscpd.json` in project root:

```json
{
  "threshold": 5,
  "minTokens": 70,
  "minLines": 5,
  "ignore": ["**/tests/**"],
  "format": ["typescript", "python"]
}
```

| Option | Default | Description |
|--------|---------|-------------|
| `threshold` | 5 | Max allowed duplicate % |
| `minTokens` | 70 | Min tokens to consider duplicate |
| `minLines` | 5 | Min lines to consider duplicate |
| `ignore` | (see template) | Glob patterns to skip |
| `format` | all | Languages to scan |

---

## Supported Languages

jscpd supports 150+ languages. Primary focus:

| Language | Format Name |
|----------|-------------|
| JavaScript | `javascript` |
| TypeScript | `typescript` |
| JSX | `jsx` |
| TSX | `tsx` |
| Python | `python` |
| Rust | `rust` |
| Go | `go` |

---

## Dependencies

**Required**: Node.js (for jscpd or npx)

**Recommended**: Install jscpd globally for faster scans:
```bash
npm install -g jscpd
```

If not installed, `/dry scan` will use `npx --yes jscpd` (slower, requires network first time).

---

## Examples

```bash
# Run scan on current project
/dry scan

# View last report
/dry report

# Show configuration
/dry config

# Initialize project config
/dry init

# Scan specific directory
/dry scan --path src/

# Scan with custom threshold
/dry scan --threshold 3
```

---

## Auto-Scan Configuration

Enable automatic scanning on session end:

```bash
/config enable dry-check
/config enable dry-auto
```

This runs `/dry scan` via the Stop hook when Claude session ends.

---

## Workflow Integration

1. **Initial scan**: `/dry scan` to baseline
2. **Review**: Focus on top duplicates by token count
3. **Refactor**: Use @dry-refactor skill patterns
4. **Verify**: `/dry scan` again to confirm reduction
5. **Configure**: Set threshold in `.jscpd.json` for CI
