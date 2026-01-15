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

- Prefer bullet lists over prose
- No long paragraphs explaining obvious things
- No duplication of content from ancestor CLAUDE.md files
- Target: < 100 lines for root, < 50 lines for modules

**What to trim:**
- Verbose explanations of standard tools
- Full command output examples
- Lists of every file in a directory

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
