---
description: Maintain README.md files - improve formatting, structure, and clarity
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <action> [instructions]
---

# README Maintainer

Maintain and improve README.md files using GitHub advanced formatting. See @bluera-base/skills/readme-maintainer/SKILL.md for formatting guidelines.

## Arguments

Parse `$ARGUMENTS` to determine action:

- **`beautify [instructions]`** - Improve formatting, structure, and visual appeal
- **(future) `audit`** - Check for issues without making changes
- **(future) `sync`** - Sync README with code changes

## No Arguments

If `$ARGUMENTS` is empty or not a recognized action, show available subcommands:

```
README Maintainer - Available Commands:

  /readme beautify [instructions]
    Improve README formatting, structure, and visual appeal.
    Examples:
      /readme beautify
      /readme beautify "use mermaid diagrams"
      /readme beautify "add CI badges, use tables"

  (coming soon)
  /readme audit    - Check for issues without fixing
  /readme sync     - Sync with code changes
```

## Beautify Workflow

When action is `beautify`:

### 1. Find README

Look for README.md in current directory. If not found, fail with helpful message.

### 2. Analyze Current State

Read the README and identify:
- Current structure (headings, sections)
- Existing formatting (tables, code blocks, badges, collapsed sections)
- Missing opportunities for improvement

### 3. Plan Improvements

Based on skill guidelines and user instructions, identify:
- Sections that could use tables instead of lists
- Long content that should be collapsed
- Missing badges (CI, npm, license, coverage)
- Opportunities for Mermaid diagrams
- Structure improvements (ToC, section order)

If user provided instructions (e.g., "use mermaid diagrams"), prioritize those.

### 4. Apply Changes

Use Edit tool to apply improvements. Present a summary:
- Changes made (with before/after examples if significant)
- Formatting features added
- Suggestions for manual improvements (if any)

## Constraints

- **Non-destructive**: Use Edit, not Write. Preserve existing content structure.
- **Respect existing style**: Don't force a completely different format if the README is already well-formatted.
- **No over-formatting**: Not everything needs to be a table, collapsed, or diagrammed.
- **Follow user instructions**: If user says "use mermaid", prioritize adding diagrams.
