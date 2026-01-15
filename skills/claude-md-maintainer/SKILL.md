---
name: claude-md-maintainer
description: Validate/update/create CLAUDE.md memory files with progressive disclosure and context-optimized structure
user-invocable: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(git:*), Bash(ls:*), Bash(wc:*), Bash(head:*), Bash(tail:*)
---

# CLAUDE.md Maintainer

Audit and maintain `CLAUDE.md` files across any repository. Ensures they function as Claude Code memory (not user documentation).

## Core Principle

`CLAUDE.md` is **Claude's memory**, not a README. Every line loads into context, so keep it lean and actionable.

## Algorithm

### Phase 1: Plan (read-only)

1. **Discover** existing memory files:
   - `./CLAUDE.md` or `./.claude/CLAUDE.md`
   - `./CLAUDE.local.md`
   - Nested `**/CLAUDE.md`
   - `.claude/rules/**/*.md`

2. **Validate** each against invariants (see `docs/invariants.md`)

3. **Identify** module roots (see `docs/directory-heuristics.md`)

4. **Output** proposed changes:
   - Files to update (with change summary)
   - Files to create
   - Ambiguous cases requiring human decision

### Phase 2: Apply (with confirmation)

Only after user confirms:
1. Update existing files
2. Create missing files from templates
3. Report final state

## References

- **Templates**: `${CLAUDE_PLUGIN_ROOT}/skills/claude-md-maintainer/templates/`
  - `root_CLAUDE.md` - Root project memory
  - `module_CLAUDE.md` - Directory-scoped memory
  - `local_CLAUDE.local.md` - Personal notes

- **Validation rules**: `${CLAUDE_PLUGIN_ROOT}/skills/claude-md-maintainer/docs/invariants.md`

- **Directory detection**: `${CLAUDE_PLUGIN_ROOT}/skills/claude-md-maintainer/docs/directory-heuristics.md`

## Key Rules

1. **Never duplicate** - Module CLAUDE.md should not repeat root rules
2. **Prefer rules files** - Move topic-specific rules to `.claude/rules/<topic>.md`
3. **Use paths: scoping** - Rules files can use `paths:` frontmatter
4. **Hard cap** - If > 25 modules, summarize at bucket level, defer individuals

## Output Format

Report these sections:
- Memory files found
- Files to create
- Files to update (with diff summary)
- Rules files to create/update
- Follow-ups (ambiguous items)
