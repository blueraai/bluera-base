---
name: tech-debt-and-refactor-scan
description: Scan codebase for tech debt, refactor opportunities, and structural issues
argument-hint: "[scan|report] [--priority high|all] [--path <dir>]"
allowed-tools: [Read, Write, Glob, Grep, Task, "Bash(git:*)", "Bash(mkdir:*)"]
---

# Tech Debt & Refactor Scanner

Identify actionable refactor opportunities, accumulated tech debt, and structural issues.
Does NOT overlap with code-review (no bugs/compliance) or dry (no jscpd duplication).

## Subcommands

| Command | Description |
|---------|-------------|
| `scan` (default) | Run full 4-agent analysis |
| `report` | Re-display last scan findings (`--path` ignored; `--priority` filters cached results) |

## Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `--priority high\|all` | `high` = confidence >= 85 only; `all` = confidence >= 75 | `all` |
| `--path <dir>` | Limit scan to a specific directory | `.` (project root) |

### Parsing Rules (scan)

- Parse arguments from the user's invocation text
- If `--priority` value is not `high` or `all`, warn and default to `all`
- If `--path` directory doesn't exist, error: `Directory not found: <path>`
- Store the `path` and `priority` in the state file for `report` re-display

### Parsing Rules (report)

- `--priority`: Filter cached results by the specified threshold (valid: `high`, `all`)
- `--path`: Not accepted. If provided, warn: `--path is only valid for scan, ignoring.`
- Invalid `--priority` values: Warn and default to `all`

## Process

1. **Gather context**: Haiku agent finds CLAUDE.md files, detects language/framework, identifies source files. If `--path` provided, scope file discovery to that directory.
2. **Parallel analysis**: 4 Sonnet agents scan independently
3. **Confidence scoring**: Haiku agents score each finding (0-100)
4. **Filter and persist**: Apply confidence gate (75 default, 85 if `--priority high`). Write results to state file.
5. **Report**: Display filtered findings

## Specialist Agents

Launch 4 parallel Sonnet agents via Task tool:

### Agent #1: Refactoring Opportunities

Identify extractable patterns and simplifiable code:

- Copy-paste logic across files (not token-level like jscpd - semantic similarity)
- Overly complex conditionals that could be simplified
- Configuration/parameter patterns that could be abstracted
- Test setup duplication across test files

For each finding: affected files, why it's extractable, suggested abstraction, effort estimate.

### Agent #2: Tech Debt Detection

Scan for accumulated debt markers:

- TODO/FIXME comments: count, age (git blame), staleness (>6 months = stale)
- Deprecated API usage or patterns
- Commented-out code blocks (>3 lines)
- Dead code (unused exports, unreachable branches)

For each finding: location, age, remediation path, priority.

### Agent #3: Structural Analysis

Evaluate architecture and coupling:

- Files with excessive imports (>15 unique imports)
- Modules that import from too many other modules (fan-in/fan-out)
- Missing abstractions (same concept scattered across files)
- Naming inconsistencies (similar things named differently)
- Leaky abstractions (implementation details in public interfaces)

For each finding: evidence (import counts, naming examples), suggested refactoring.

### Agent #4: Complexity Assessment

Find high-complexity hotspots:

- Functions >50 lines or >3 levels of nesting
- Files >500 lines
- Functions with >5 parameters
- High conditional density (many if/else/switch branches)
- Classes/modules with >10 public methods (too many responsibilities)

For each finding: location, metric values, suggested breakdown strategy.

## Confidence Scoring

After all agents report, launch parallel Haiku agents (one per finding) to score:

- **0-25**: Style preference, debatable, not actionable
- **26-50**: Might be real, needs more context
- **51-74**: Real but low priority
- **75-100**: Clear improvement opportunity, worth prioritizing

## State Management

Scan results persist at `.bluera/bluera-base/state/tech-debt-report.json`.

Before writing, ensure directory exists via Bash: `mkdir -p .bluera/bluera-base/state/`

After confidence scoring, write findings using the Write tool:

```json
{
  "timestamp": "2026-02-05T22:10:00Z",
  "path": ".",
  "priority": "all",
  "findings": [
    {
      "type": "REFACTOR|TECH-DEBT|STRUCTURE|COMPLEXITY",
      "title": "description",
      "files": ["path/file.ts:42"],
      "confidence": 92,
      "effort": "small|medium|large",
      "suggestion": "actionable next step"
    }
  ]
}
```

**report subcommand:** Read the state file and re-display. `--priority` filters cached results; `--path` is ignored (report always shows all cached findings).
If file doesn't exist, print: `No scan results found. Run /bluera-base:tech-debt-and-refactor-scan first.`

## Cross-References

When findings map to existing skills, suggest them:

- Large files → `/bluera-base:large-file-refactor`
- DRY violations → `/bluera-base:dry-refactor`
- Naming issues → manual refactor with `/bluera-base:commit` for atomic changes

## Output Format

### Tech Debt & Refactor Scan

Found N findings (M high-priority):

1. **[REFACTOR]** Title (confidence: 92)
   `file/path.ts:42-88` → suggested action
   Effort: small/medium/large

2. **[TECH-DEBT]** Title (confidence: 85)
   `file/path.ts` → remediation path

3. **[STRUCTURE]** Title (confidence: 78)
   Files: list → suggested abstraction

4. **[COMPLEXITY]** Title (confidence: 76)
   `file/path.ts:fn_name` (lines: 120, nesting: 4) → breakdown strategy

### If no findings

### Tech Debt & Refactor Scan (clean)

No actionable findings. Codebase is in good shape.

## Constraints

- **Refactor-only**: No bugs, no CLAUDE.md compliance (that's code-review)
- **No jscpd overlap**: Semantic similarity, not token duplication (that's dry)
- **Actionable only**: Every finding must have a concrete next step
- **Confidence gate**: Only report >= 75 confidence
- **Non-destructive**: Writes only to `.bluera` state directory, never modifies source
