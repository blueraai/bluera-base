# Verbose Pattern Detection

Patterns that indicate CLAUDE.md content should be removed or relocated.

## Linter Duplication

Instructions that linters enforce automatically:

```regex
(consistent|proper)\s+(indentation|spacing|formatting)
(always|never)\s+(use|add)\s+(semicolons?|trailing commas?)
(follow|use)\s+(eslint|prettier|biome|black|ruff)
```

**Why bad**: These rules are already enforced by tooling. Adding them wastes context and creates maintenance burden when tools change.

## Tool Explanations

Explaining what standard tools do:

```regex
^(npm|yarn|bun|pip|cargo|go)\s+(is|are|helps|allows)
^(git|docker|kubernetes)\s+(is|allows|enables)
```

**Why bad**: Claude knows what these tools do. Explaining them wastes context.

## Verbose Prose

Heuristics for over-explanation:

- 4+ consecutive lines without bullets, code blocks, or headers
- Sentences starting with "This is", "In order to", "The purpose of"
- Multiple paragraphs explaining a single command

**Why bad**: Prose is harder to parse than structured content. Keep instructions terse.

## File Enumerations

```regex
^-\s+`?[\w/]+\.(ts|js|py|rs|go|md)`?\s*[-–—]
```

When 5+ consecutive matches, suggest: "Summarize as: '<dir>/ - <purpose>'"

**Why bad**: Claude can explore the filesystem. Listing every file wastes context and goes stale.

## Output Examples

Fenced code blocks after command documentation that show expected output:

Detection heuristics:
>
- > 10 lines of fenced output
- Contains common output patterns: "npm WARN", "✓", timestamps, progress bars
- Immediately follows a command reference

**Why bad**: Output examples rarely add value and consume significant context. If output format matters, document only the relevant field/format.

## Vague Instructions

Non-actionable guidance:

```regex
(write|use|follow)\s+(clean|good|proper|best)\s+(code|practices)
(be\s+careful|make\s+sure|remember\s+to)
```

**Why bad**: Without specifics, these instructions are noise. Either make them concrete or remove them.

## Detection Usage

During audit, scan CLAUDE.md content line-by-line:

1. Track consecutive prose lines (no formatting markers)
2. Match patterns above against each line
3. Record line numbers for matches
4. Report with specific suggestions

Example output:

```text
**Verbose Patterns Detected:**

| Lines | Issue | Suggestion |
|-------|-------|------------|
| 23-28 | Prose block (6 lines) | Convert to bullet list |
| 45 | Linter duplication | Remove - prettier handles this |
| 67-89 | Command output (22 lines) | Remove or move to agent_docs/ |
```
