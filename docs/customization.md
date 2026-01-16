# Customization

> Part of [Bluera Base](../README.md) documentation.

## Project-specific trigger files

The `atomic-commits` skill has generic trigger files. Override by creating your own:

```markdown
# .claude/skills/atomic-commits/SKILL.md

**Trigger files -> check README.md:**
- `src/mcp/server.ts` - MCP tool surface
- `.claude-plugin/plugin.json` - Plugin metadata
- `commands/*.md` - Command documentation
```

## Additional hooks

Add project-specific hooks in your `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/my-custom-hook.sh\""
        }]
      }
    ]
  }
}
```

## Extending ALWAYS/NEVER rules

Add project-specific rules after the @include:

```markdown
@bluera-base/includes/CLAUDE-BASE.md

## ALWAYS (project-specific)

* run `bun run validate:api` before modifying API endpoints

## NEVER (project-specific)

* commit directly to main without PR
```

## Architectural Constraint Skills

For projects with critical architectural requirements (e.g., "code must be database-agnostic"), use the template:

```bash
# Copy the template
cp /path/to/bluera-base/skills/architectural-constraints/SKILL.md.template \
   .claude/skills/[constraint-name]/SKILL.md

# Edit to match your constraint
```

The template provides structure for:

- What violates the constraint (with code examples)
- Where constrained code IS allowed (table format)
- The correct pattern (with code examples)
- Why it matters

## Subdirectory CLAUDE.md Files

For large projects, create directory-specific CLAUDE.md files that auto-load when working in that directory:

```bash
# Copy the template
cp /path/to/bluera-base/templates/subdirectory-CLAUDE.md.template \
   [directory]/CLAUDE.md
```

Example: A `tests/CLAUDE.md` that explains why tests are organized a certain way.
