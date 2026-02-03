# Prompt Creation (MCP)

Full template and rules for creating MCP prompt components.

## Interview

1. **Name** (required): Unique identifier (kebab-case)

2. **Title** (optional): Human-readable display name

3. **Description** (optional): What this prompt does

4. **Arguments**: Interview for each argument

```yaml
question: "Does this prompt need arguments?"
header: "Arguments"
options:
  - label: "Yes"
    description: "Prompt takes input parameters"
  - label: "No"
    description: "Static prompt with no parameters"
multiSelect: false
```

If yes, for each argument:

- Name (identifier)
- Description (what it's for)
- Required (yes/no)

1. **Prompt content**: The actual prompt template

## Generate Prompt

```markdown
---
name: <name>
title: <title if provided>
description: <description if provided>
arguments:
  - name: <arg1>
    description: <arg1 description>
    required: <true|false>
---

# <Title or Name>

<Prompt content with {{argument}} placeholders>
```

## Output

- Create `prompts/` directory if needed
- Write `prompts/<name>.md`

## Argument Syntax

Use double-brace syntax for argument placeholders:

```markdown
Analyze the {{language}} code in {{file_path}} for {{concern}}.
```

Arguments are validated against the frontmatter schema when the prompt is invoked.
