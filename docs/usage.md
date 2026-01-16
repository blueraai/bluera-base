# Usage

> Part of [Bluera Base](../README.md) documentation.

## Using @includes in your CLAUDE.md

Create a `CLAUDE.md` in your project root:

```markdown
@bluera-base/includes/CLAUDE-BASE.md

---

## Package Manager

**Use `bun`** - All scripts: `bun run <script>`

---

## Scripts

**Development:**
- `bun run build` - Compile TypeScript
- `bun run test:run` - Run tests once
- `bun run precommit` - Full validation

## Versioning

- `bun run version:patch` - Bump patch (0.0.x)
```

The `@bluera-base/includes/CLAUDE-BASE.md` pulls in:
- Header explaining CLAUDE.md vs README.md
- Hierarchical CLAUDE.md explanation
- ALWAYS/NEVER conventions

## Overriding Skills

To customize a skill for your project:

1. Create `.claude/skills/atomic-commits/SKILL.md` in your project
2. Copy the base skill content
3. Modify the "Trigger files" section for your project structure

Your local skill takes precedence over the plugin's version.

## Using the Settings Template

Copy `templates/settings.local.json.example` to your project's `.claude/settings.local.json`:

```bash
cp /path/to/bluera-base/templates/settings.local.json.example .claude/settings.local.json
```

This provides:
- Pre-approved commands for multiple package managers and languages
- PostToolUse hook for validation
- Notification hook for permission prompts
