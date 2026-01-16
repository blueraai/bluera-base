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

## Settings Configuration

Claude Code uses two settings files with different purposes:

| File | Committed | Purpose |
|------|-----------|---------|
| `.claude/settings.json` | Yes | Shared team settings (checked into repo) |
| `.claude/settings.local.json` | No | Personal settings (gitignored) |

### For Teams (Committed Settings)

Create `.claude/settings.json` in your project with permissions needed by all developers:

```json
{
  "permissions": {
    "allow": [
      "Bash(jq *)",
      "Bash(git rev-parse *)",
      "Bash(git status *)",
      "Bash(git log *)",
      "Bash(bun run *)"
    ],
    "deny": [
      "Bash(* --no-verify *)",
      "Bash(git push --force *)"
    ]
  }
}
```

### For Individuals (Local Settings)

Copy `templates/settings.local.json.example` to your project's `.claude/settings.local.json`:

```bash
cp /path/to/bluera-base/templates/settings.local.json.example .claude/settings.local.json
```

This provides:

- Pre-approved commands for multiple package managers and linters
- PostToolUse hook for automatic validation after edits
- Notification hook for permission prompts (macOS/Linux)

### Permission Patterns

Permissions use glob-style matching:

| Pattern | Matches |
|---------|---------|
| `Bash(git status *)` | `git status`, `git status .`, etc. |
| `Bash(npm run *)` | `npm run test`, `npm run build`, etc. |
| `Bash(jq *)` | Any jq command (filters vary widely) |
| `Bash(* --no-verify *)` | Any command containing `--no-verify` |

### Deny Rules

The templates include safety deny rules:

- `Bash(* --no-verify *)` - Prevents bypassing git hooks
- `Bash(git push --force *)` - Prevents force-pushing
- `Bash(rm -rf /)` - Prevents catastrophic deletes

Deny rules take precedence over allow rules.
