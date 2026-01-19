# CLAUDE.md Reliability

## Critical Understanding

**CLAUDE.md is guidance, not enforcement.**

Bug reports confirm Claude Code can:

- Acknowledge reading CLAUDE.md but still violate it
- Stop following rules after `/compact` or auto-compaction
- Require explicit "re-read CLAUDE.md" prompts to restore compliance

**Source:** GitHub issues #15443, #4017, #4517, #6354

## Mitigations

### 1. Top-load critical constraints

Put safety-critical rules (no deploy, no secrets, no prod writes) at the **TOP** of CLAUDE.md. Keep them **SHORT**.

```markdown
## NEVER

- Deploy to production
- Write to prod databases
- Commit secrets or credentials
```

### 2. Add re-anchor instruction

Consider adding to CLAUDE.md:

```markdown
If behavior drifts after compaction: re-read this file.
```

### 3. Use hooks for enforcement

When something MUST happen, use Claude Code hooks:

| Hook | Use Case |
|------|----------|
| `PreToolUse` | Block dangerous commands before execution |
| `PostToolUse` | Validate outputs after execution |
| `PreCompact` | Reinject critical context before compaction |

**Example hook (block prod deploy):**

```json
{
  "event": "PreToolUse",
  "tools": ["Bash"],
  "pattern": "deploy.*prod|--prod",
  "action": "block",
  "message": "Production deploy blocked. Use staging."
}
```

**See:** <https://docs.anthropic.com/en/docs/claude-code/hooks>

## When to Use Each Layer

| Constraint Type | Where | Why |
|-----------------|-------|-----|
| Style preferences | CLAUDE.md | Soft guidance, drift acceptable |
| Build/test commands | CLAUDE.md | Context, not enforcement |
| Security boundaries | Hooks | Must not fail |
| Destructive operations | Hooks | Cannot rely on memory |
