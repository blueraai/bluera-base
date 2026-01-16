---
description: Maintain README.md files - improve formatting, structure, and clarity
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion
argument-hint: <beautify|breakout> [instructions]
---

# README Maintainer

Maintain and improve README.md files using GitHub advanced formatting. See @bluera-base/skills/readme-maintainer/SKILL.md for formatting guidelines.

## Arguments

Parse `$ARGUMENTS` to determine action:

- **`beautify [instructions]`** - Improve formatting, structure, and visual appeal
- **`breakout [instructions]`** - Analyze and split large README into modular docs
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

  /readme breakout [instructions]
    Analyze large README and suggest splitting into modular docs.
    Examples:
      /readme breakout
      /readme breakout "focus on API documentation"

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

## Breakout Workflow

When action is `breakout`:

### Phase 1: Analysis (read-only)

1. Read README.md and count total lines
2. Identify sections by heading level (## and ###)
3. Classify each section by content type (see skill for heuristics)
4. Apply breakout decision tree:
   - GitHub special files (CONTRIBUTING, CHANGELOG, SECURITY, CODE_OF_CONDUCT) → root
   - Sections > 75 lines matching docs patterns → docs/ folder
5. Present suggested breakout plan as table showing:
   - Section name
   - Line count
   - Suggested destination file
   - Estimated README size after breakout
6. Ask user to confirm before making changes

### Phase 2: Apply (after confirmation)

Use AskUserQuestion to confirm:
```
question: "Apply the breakout plan?"
header: "Confirm"
options:
  - label: "Apply all"
    description: "Create all suggested files and update README"
  - label: "Customize"
    description: "Select which sections to break out"
  - label: "Cancel"
    description: "Make no changes"
```

If confirmed:
1. Create docs/ folder if needed
2. Create new documentation files with moved content
3. Remove content from README.md
4. Add "Documentation" section to README with links table
5. Report final structure and file sizes

## Constraints

- **Non-destructive**: Use Edit, not Write. Preserve existing content structure.
- **Respect existing style**: Don't force a completely different format if the README is already well-formatted.
- **No over-formatting**: Not everything needs to be a table, collapsed, or diagrammed.
- **Follow user instructions**: If user says "use mermaid", prioritize adding diagrams.
