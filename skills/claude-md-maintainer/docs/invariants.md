# CLAUDE.md Invariants

Every `CLAUDE.md` file (root or nested) MUST satisfy these invariants:

## 1. Declare Purpose

The file must explicitly state it is Claude's **memory**, not user documentation.

**Required header block:**

```markdown
# THIS IS CLAUDE.md - PROJECT MEMORY (or DIRECTORY MEMORY)
```

**Anti-pattern to detect:**

- Starts with `# Project Name` without the memory declaration
- Contains "Welcome to" or installation instructions
- Has sections like "Getting Started", "Installation", "API Reference"

## 2. Be Lean

- **Hard limit**: < 300 lines (system prompt already uses ~50 instruction slots)
- **Target**: < 60 lines for root, < 30 lines for modules
- Prefer bullet lists over prose
- No duplication from ancestor files

**Anti-patterns to detect:**

| Pattern | Why It's Bad |
|---------|--------------|
| Linter duplication | "Use consistent indentation" - linters do this |
| Verbose tool explanations | "npm is the node package manager..." - obvious |
| Full command output | `npm test` output examples - waste context |
| File/directory lists | Enumerating all files - Claude can explore |
| Vague instructions | "Write clean code" - not actionable |
| Auto-generated prose | Multi-paragraph explanations of simple concepts |

**See**: `docs/verbose-patterns.md` for detection regex patterns

## 3. Be Actionable

Must include the canonical commands for the scope:

- Build command
- Test command
- Lint command
- Dev/run command

**If commands can't be determined:**

- Add a TODO with pointers (e.g., "TODO: Confirm build command - check package.json scripts")

## 4. Use Progressive Disclosure

- **Root file**: Project-wide invariants and top workflows only
- **Module files**: Module-specific workflows and conventions
- **Topic rules**: Move to `.claude/rules/<topic>.md` with `paths:` scoping

## 5. Section Order

Normalize sections in this order:

1. Purpose header
2. Quick facts (languages, frameworks, shape)
3. Commands (build/test/lint/dev)
4. Workflows (CI/release/deploy)
5. Conventions (only those relevant to scope)
6. Directory map (short)
7. Guardrails (ALWAYS/NEVER)

## 6. Use Separate Files for Details

Move detailed guidance to `agent_docs/` directory:

- `agent_docs/architecture.md` - System design details
- `agent_docs/testing.md` - Test conventions and patterns
- `agent_docs/conventions.md` - Code style details

Reference in CLAUDE.md: "See agent_docs/ for detailed guidance"

This keeps CLAUDE.md lean while preserving detailed documentation Claude can read on-demand.
