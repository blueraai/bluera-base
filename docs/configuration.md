# Configuration

Bluera Base uses a hierarchical configuration system supporting both shared (team-wide) and local (personal) settings.

## File Locations

### Project-Local (per-project)

| File | Purpose | Git |
|------|---------|-----|
| `.bluera/bluera-base/config.json` | Shared team config | Committed |
| `.bluera/bluera-base/config.local.json` | Personal overrides | Ignored |
| `.bluera/bluera-base/state/` | Runtime state (loops, signals) | Ignored |
| `.bluera/bluera-knowledge/` | Bluera Knowledge plugin data | Ignored |

### Global (user-wide)

| File | Purpose |
|------|---------|
| `~/.claude/.bluera/bluera-base/config.json` | Global plugin settings |
| `~/.claude/.bluera/bluera-base/memories/` | Global memories (cross-project knowledge) |

**Dual Scope Architecture:**

| Scope | Location | Purpose |
|-------|----------|---------|
| **Global memories** | `~/.claude/.bluera/bluera-base/memories/` | Cross-project knowledge, user-wide |
| **Project learnings** | `CLAUDE.local.md` | Project-specific auto-learn |

These systems are 100% independent. No automatic sync - use `/bluera-base:memory import` to manually migrate.

## Config Priority

Settings are deep-merged in order: **Defaults ← Shared ← Local**

This allows local overrides while maintaining team-wide defaults.

## Feature Toggles

Manage with `/bluera-base:settings enable|disable <feature>`:

| Feature | Config Path | Description | Default |
|---------|-------------|-------------|---------|
| `auto-learn` | `.autoLearn.enabled` | Track command patterns, suggest CLAUDE.md edits | ON |
| `deep-learn` | `.deepLearn.enabled` | Semantic session analysis via Claude CLI | ON |
| `standards-review` | `.standardsReview.enabled` | Review code against CLAUDE.md before commits | ON |
| `auto-commit` | `.autoCommit.enabled` | Prompt to commit on session stop | ON |
| `auto-push` | `.autoCommit.push` | Add push instruction to commit prompt | OFF |
| `notifications` | `.notifications.enabled` | Desktop notifications on prompts | ON |
| `dry-check` | `.dryCheck.enabled` | Enable DRY duplicate detection | ON |
| `dry-auto` | `.dryCheck.onStop` | Auto-scan for duplicates on stop | ON |
| `strict-typing` | `.strictTyping.enabled` | Block `any`, `as` casts | ON |
| `secrets-check` | `.secretsCheck.enabled` | Block commits containing potential secrets | ON |
| `secrets-ai` | `.secretsCheck.aiEnabled` | AI-powered obfuscated secret detection (requires Claude CLI) | ON |

## Default Schema

```json
{
  "version": 1,
  "autoLearn": {
    "enabled": true,
    "mode": "suggest",
    "threshold": 3,
    "target": "local"
  },
  "milhouse": {
    "defaultMaxIterations": 0,
    "defaultStuckLimit": 3,
    "defaultGates": []
  },
  "notifications": {
    "enabled": true
  },
  "autoCommit": {
    "enabled": true,
    "onStop": true,
    "push": false,
    "remote": "origin"
  },
  "dryCheck": {
    "enabled": true,
    "onStop": true,
    "minTokens": 70,
    "minLines": 5
  },
  "strictTyping": {
    "enabled": true
  },
  "deepLearn": {
    "enabled": true,
    "model": "haiku",
    "maxBudget": 0.02
  },
  "standardsReview": {
    "enabled": true,
    "mode": "warn"
  },
  "secretsCheck": {
    "enabled": true,
    "aiEnabled": true,
    "excludePaths": []
  }
}
```

> **Note:** The `autoCommit.remote` field is defined but currently unused.

## Secrets Check: Excluding Paths

The `secretsCheck.excludePaths` array lets you skip specific paths from the pre-commit secrets scan. This is useful for data files (JSONL, JSON) that mention env var names in documentation text but don't contain actual secrets.

Paths are passed as git pathspec exclusions (`:!<path>`) to `git diff --cached`.

```json
{
  "secretsCheck": {
    "excludePaths": ["training/data/", "*.jsonl", "docs/env-setup.md"]
  }
}
```

Configure in `.bluera/bluera-base/config.json` (shared, committed) or `config.local.json` (personal, gitignored).

## State Files

Runtime state in `.bluera/bluera-base/state/`:

| File | Purpose |
|------|---------|
| `milhouse-loop.md` | Active milhouse loop state |
| `milhouse-plan.md` | Plan file when `--init-harness` used |
| `milhouse-activity.md` | Activity log when `--init-harness` used |
| `session-signals.json` | Learning observation data |
| `dry-report.md` | Last DRY scan report |
| `jscpd-report.json` | Raw jscpd output |
| `auto-commit-attempted` | Flag to prevent stop-hook loops |

## See Also

- [Commands Reference](commands.md) - `/bluera-base:settings` usage
- [Hooks](hooks.md) - How hooks consume config
