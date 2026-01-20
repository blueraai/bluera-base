# Configuration

Bluera Base uses a hierarchical configuration system supporting both shared (team-wide) and local (personal) settings.

## File Locations

| File | Purpose | Git |
|------|---------|-----|
| `.bluera/bluera-base/config.json` | Shared team config | Committed |
| `.bluera/bluera-base/config.local.json` | Personal overrides | Ignored |
| `.bluera/bluera-base/state/` | Runtime state (loops, signals) | Ignored |

## Config Priority

Settings are deep-merged in order: **Defaults ← Shared ← Local**

This allows local overrides while maintaining team-wide defaults.

## Feature Toggles

Manage with `/bluera-base:config enable|disable <feature>`:

| Feature | Config Path | Description | Default |
|---------|-------------|-------------|---------|
| `auto-learn` | `.autoLearn.enabled` | Track command patterns, suggest CLAUDE.md edits | OFF |
| `auto-commit` | `.autoCommit.enabled` | Prompt to commit on session stop | OFF |
| `auto-push` | `.autoCommit.push` | Push to remote after auto-commit | OFF |
| `notifications` | `.notifications.enabled` | Desktop notifications on prompts | ON |
| `dry-check` | `.dryCheck.enabled` | Enable DRY duplicate detection | OFF |
| `dry-auto` | `.dryCheck.onStop` | Auto-scan for duplicates on stop | OFF |
| `strict-typing` | `.strictTyping.enabled` | Block `any`, `as` casts | OFF |

## Default Schema

```json
{
  "version": 1,
  "autoLearn": {
    "enabled": false,
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
    "enabled": false,
    "onStop": true,
    "push": false,
    "remote": "origin"
  },
  "dryCheck": {
    "enabled": false,
    "onStop": false,
    "threshold": 5,
    "minTokens": 70,
    "minLines": 5
  },
  "strictTyping": {
    "enabled": false
  }
}
```

## State Files

Runtime state in `.bluera/bluera-base/state/`:

| File | Purpose |
|------|---------|
| `milhouse-loop.md` | Active milhouse loop state |
| `session-signals.json` | Learning observation data |
| `dry-report.md` | Last DRY scan report |
| `jscpd-report.json` | Raw jscpd output |

## See Also

- [Commands Reference](commands.md) - `/bluera-base:config` usage
- [Hooks](hooks.md) - How hooks consume config
