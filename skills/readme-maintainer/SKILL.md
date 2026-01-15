---
name: readme-maintainer
description: Maintain README.md files with GitHub advanced formatting (tables, badges, diagrams, collapsible sections)
user-invocable: false
allowed-tools: Read, Write, Edit, Glob, Grep
---

# README Maintainer

Guide for maintaining and improving README.md files using GitHub's advanced formatting capabilities.

## Core Principle

README.md is **user documentation** (unlike CLAUDE.md which is Claude's memory). Optimize for scannability, visual appeal, and information hierarchy.

## GitHub Advanced Formatting

### Tables

Use tables for structured comparisons, feature matrices, and option lists.

**Syntax:**
```markdown
| Header 1 | Header 2 | Header 3 |
|----------|:--------:|---------:|
| Left     | Center   | Right    |
```

**Alignment:** `:---` (left), `:---:` (center), `---:` (right)

**Formatting in cells:** Supports `**bold**`, `*italic*`, `` `code` ``, and [links](url).

**Escape pipes:** Use `\|` for literal pipe characters.

**When to use tables:**
- Feature comparisons (columns: feature, description, status)
- Command reference (columns: command, description, example)
- Configuration options (columns: option, type, default, description)
- Side-by-side comparisons (with/without, before/after)

**When NOT to use tables:**
- Simple lists with no comparison dimension
- Content requiring long prose descriptions

### Collapsible Sections

Use `<details>` for optional or lengthy content that shouldn't dominate the page.

**Syntax:**
```html
<details>
<summary>Click to expand</summary>

Content here (leave blank line after summary tag)

</details>
```

**Open by default:** Add `open` attribute: `<details open>`

**When to collapse:**
- Installation instructions for multiple platforms/methods
- Troubleshooting sections
- Advanced configuration
- Long code examples
- Changelog/version history
- FAQ sections

**When NOT to collapse:**
- Critical getting-started content
- Primary installation method
- Core features (these should be visible)

### Badges

Badges communicate project status at a glance. Use shields.io for consistent styling.

**Common badges:**

| Purpose | Pattern |
|---------|---------|
| CI Status | `![CI](https://github.com/ORG/REPO/actions/workflows/ci.yml/badge.svg)` |
| npm Version | `![npm](https://img.shields.io/npm/v/PACKAGE)` |
| npm Downloads | `![downloads](https://img.shields.io/npm/dm/PACKAGE)` |
| License | `![license](https://img.shields.io/badge/license-MIT-green)` |
| Node Version | `![node](https://img.shields.io/badge/node-%3E%3D18-brightgreen)` |
| TypeScript | `![typescript](https://img.shields.io/badge/TypeScript-5.0-blue)` |
| Coverage | `![coverage](https://img.shields.io/badge/coverage-85%25-brightgreen)` |

**Badge placement:** Immediately after title, before description.

**Don't overdo it:** 3-6 relevant badges. Skip badges for metrics that don't matter.

### Mermaid Diagrams

GitHub renders Mermaid diagrams in fenced code blocks.

**Flowchart:**
````markdown
```mermaid
flowchart LR
    A[Input] --> B{Decision}
    B -->|Yes| C[Action 1]
    B -->|No| D[Action 2]
```
````

**Sequence diagram:**
````markdown
```mermaid
sequenceDiagram
    participant User
    participant API
    participant DB
    User->>API: Request
    API->>DB: Query
    DB-->>API: Result
    API-->>User: Response
```
````

**When to use diagrams:**
- Architecture overviews
- Data flow / message flow
- State machines
- Decision trees
- Component relationships

**When NOT to use diagrams:**
- Simple linear processes (use numbered list)
- When prose is clearer
- Decorative purposes (diagram must clarify)

### GitHub Alerts

Special blockquotes for callouts.

```markdown
> [!NOTE]
> Useful information that users should know.

> [!TIP]
> Helpful advice for doing things better.

> [!IMPORTANT]
> Key information users need to know.

> [!WARNING]
> Urgent info that needs immediate attention.

> [!CAUTION]
> Advises about risks or negative outcomes.
```

**Renders as colored callout boxes on GitHub.**

### Code Blocks

Always specify language for syntax highlighting.

````markdown
```typescript
const example: string = "highlighted";
```
````

**Common language identifiers:** `typescript`, `javascript`, `python`, `bash`, `json`, `yaml`, `markdown`, `rust`, `go`

## README Structure

### Recommended Section Order

1. **Title** + badges
2. **Tagline** (1-2 sentences)
3. **Table of Contents** (collapsible for long READMEs)
4. **Why / Motivation** (optional)
5. **Features** (table or list)
6. **Quick Start / Installation**
7. **Usage** (with examples)
8. **Configuration / API**
9. **Architecture** (if complex, use diagram)
10. **Contributing**
11. **License**

See `templates/structure.md` for detailed template.

### Title Format

```markdown
# Project Name

[![CI](badge-url)](link) [![npm](badge-url)](link) [![License](badge-url)](link)

> One-line description of what this project does.
```

### Table of Contents

For READMEs with 5+ sections, add a collapsible ToC:

```html
<details>
<summary>Table of Contents</summary>

- [Installation](#installation)
- [Usage](#usage)
- [API](#api)
- [Contributing](#contributing)

</details>
```

## Anti-Patterns

### Don't Over-Format

- Not every list needs to be a table
- Not every section needs to be collapsed
- Not every process needs a diagram
- Not every statement needs a badge

### Don't Add Noise

- Skip badges for metrics that don't matter
- Skip diagrams that don't clarify
- Skip collapsibles for short content
- Skip emojis unless they add meaning

### Preserve Author Intent

When beautifying an existing README:
- Respect the existing structure if it's reasonable
- Don't force a completely different format
- Enhance, don't replace
- Keep the author's voice

## Beautify Algorithm

1. **Read** current README.md
2. **Identify** improvement opportunities:
   - Lists that could be tables (comparisons, options)
   - Long sections that could be collapsed
   - Missing badges (if package.json/CI exists)
   - Architecture that could use a diagram
   - Missing Table of Contents
3. **Prioritize** user instructions if provided
4. **Apply** changes incrementally with Edit tool
5. **Report** what was changed

## References

- **Badge templates:** `templates/badges.md`
- **Structure template:** `templates/structure.md`
