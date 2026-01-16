---
description: Manage bluera-base plugin configuration
argument-hint: [show|init|set|enable|disable|reset|status] [key] [value]
allowed-tools: Read, Write, Edit, Bash(mkdir:*), Bash(jq:*), Bash(cat:*), Bash(rm:*), Bash(ls:*), Bash(stat:*), Bash(wc:*), AskUserQuestion
---

# bluera-base Configuration

Manage plugin settings stored in `.bluera/bluera-base/`.

## Subcommands

| Command | Description |
|---------|-------------|
| `/bluera-base:config` or `/bluera-base:config show` | Display current effective config |
| `/bluera-base:config init` | Initialize config for this project |
| `/bluera-base:config set <key> <value>` | Set a config value |
| `/bluera-base:config enable <feature>` | Enable a feature |
| `/bluera-base:config disable <feature>` | Disable a feature |
| `/bluera-base:config reset` | Reset to defaults |
| `/bluera-base:config status [--state]` | Show config and state file status |

---

## Algorithm

### Show (default)

1. Check if `.bluera/bluera-base/` exists
2. Load and merge: defaults ← `config.json` ← `config.local.json`
3. Display effective configuration as formatted JSON
4. Note which values are overridden locally

### Init

1. Check if config already exists
2. Create `.bluera/bluera-base/` directory structure
3. Write default `config.json`
4. Update `.gitignore` with required patterns:
   ```
   .bluera/
   !.bluera/bluera-base/
   !.bluera/bluera-base/config.json
   ```
5. Report created files

### Set

Arguments: `<key> <value> [--shared]`

1. Parse key as JSON path (e.g., `.autoLearn.mode`)
2. Validate value type matches schema
3. Write to `config.local.json` (or `config.json` with `--shared`)
4. Display updated value

### Enable / Disable

Shortcuts for common boolean settings:

| Feature | Config Path |
|---------|-------------|
| `auto-learn` | `.autoLearn.enabled` |
| `notifications` | `.notifications.enabled` |
| `auto-commit` | `.autoCommit.enabled` |
| `auto-push` | `.autoCommit.push` |
| `dry-check` | `.dryCheck.enabled` |
| `dry-auto` | `.dryCheck.onStop` |

### Reset

Options:
- No args: Remove `config.local.json` only (keep shared config)
- `--all`: Remove both config files

### Status

Show state file status for debugging and visibility.

1. Check if `.bluera/bluera-base/` exists
2. List state directory contents with sizes
3. If milhouse-loop.md exists, show iteration status
4. Report environment variables if set (BLUERA_STATE_DIR, BLUERA_CONFIG)

**Output format:**
```
Config: .bluera/bluera-base/
├── config.json (exists, 250 bytes)
└── config.local.json (not found)

State: .bluera/bluera-base/state/
├── milhouse-loop.md (active, iteration 3/10)
└── session-signals.json (12 entries)

Env (from CLAUDE_ENV_FILE):
├── BLUERA_STATE_DIR: /path/to/state
└── BLUERA_CONFIG: /path/to/config.json
```

---

## Configuration Schema

```json
{
  "version": 1,
  "autoLearn": {
    "enabled": false,     // opt-in: track commands for learning suggestions
    "mode": "suggest",    // suggest | auto
    "threshold": 3,       // occurrences before suggesting
    "target": "local"     // local | shared
  },
  "milhouse": {
    "defaultMaxIterations": 0,   // 0 = unlimited
    "defaultStuckLimit": 3,      // 0 = disabled
    "defaultGates": []           // e.g., ["bun test", "bun run lint"]
  },
  "notifications": {
    "enabled": true
  },
  "autoCommit": {
    "enabled": false,    // opt-in: auto-commit on session stop
    "onStop": true,      // trigger on Stop hook
    "push": false,       // also push after commit
    "remote": "origin"   // remote to push to
  },
  "dryCheck": {
    "enabled": false,    // opt-in: enable DRY duplicate detection
    "onStop": false,     // auto-scan on session stop
    "threshold": 5,      // max allowed duplicate %
    "minTokens": 70,     // min tokens to consider duplicate
    "minLines": 5        // min lines to consider duplicate
  }
}
```

---

## Directory Structure

```
.bluera/bluera-base/
├── config.json              # Team-shareable (committed)
├── config.local.json        # Personal overrides (gitignored)
└── state/                   # Runtime state (gitignored)
    ├── milhouse-loop.md     # Active loop state
    ├── session-signals.json # Learning observation data
    ├── dry-report.md        # Last DRY scan report
    └── jscpd-report.json    # Raw jscpd output
```

---

## Examples

```bash
# Initialize config for a new project
/bluera-base:config init

# Show current settings
/bluera-base:config show

# Enable auto-learning (opt-in)
/bluera-base:config enable auto-learn

# Set learning mode to auto-apply
/bluera-base:config set .autoLearn.mode auto

# Set default gates for milhouse
/bluera-base:config set .milhouse.defaultGates '["bun test", "bun run lint"]' --shared

# Disable notifications
/bluera-base:config disable notifications

# Reset local overrides
/bluera-base:config reset

# Reset everything
/bluera-base:config reset --all

# Show state file status (useful for debugging milhouse loops)
/bluera-base:config status --state

# Enable auto-commit on session stop
/bluera-base:config enable auto-commit

# Enable auto-push after commit
/bluera-base:config enable auto-push

# Set custom remote for auto-push
/bluera-base:config set .autoCommit.remote upstream --shared

# Enable DRY duplicate checking
/bluera-base:config enable dry-check

# Enable auto-scan on session stop
/bluera-base:config enable dry-auto

# Set custom DRY thresholds
/bluera-base:config set .dryCheck.minTokens 50 --shared
```

---

## Gitignore Patterns

The `/bluera-base:config init` command adds these patterns to `.gitignore`:

```gitignore
# Bluera plugins
.bluera/
!.bluera/bluera-base/
!.bluera/bluera-base/config.json
!.bluera/bluera-knowledge/
!.bluera/bluera-knowledge/stores.config.json
```

This ensures:
- `.bluera/` data is ignored by default
- `config.json` is committed (team-shareable)
- `config.local.json` and `state/` are gitignored

---

## Implementation Notes

Use the config library for all operations:

```bash
source "${CLAUDE_PLUGIN_ROOT}/hooks/lib/config.sh"
source "${CLAUDE_PLUGIN_ROOT}/hooks/lib/gitignore.sh"

# Load effective config
config=$(bluera_load_config)

# Get specific value
enabled=$(bluera_get_config ".autoLearn.enabled")

# Check boolean
if bluera_config_enabled ".autoLearn.enabled"; then
  # do learning...
fi

# Set value
bluera_set_config ".autoLearn.mode" "auto"

# Ensure gitignore patterns
gitignore_ensure_patterns
```
