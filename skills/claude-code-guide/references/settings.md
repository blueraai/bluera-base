# Claude Code Settings

> Official docs: [Settings](https://code.claude.com/docs/en/settings)
> JSON Schema: [claude-code-settings.json](https://www.schemastore.org/claude-code-settings.json)

Every Claude Code session is governed by a settings file. Settings can also be passed via CLI.

## Hierarchy (highest wins)

| Priority | Scope | Location | Shared |
|----------|-------|----------|--------|
| 1 | Managed | `managed-settings.json` (system-level) | IT-deployed |
| 2 | CLI | `--settings <path>` flag | No |
| 3 | Local project | `.claude/settings.local.json` | No (gitignored) |
| 4 | Shared project | `.claude/settings.json` | Yes (committed) |
| 5 | User | `~/.claude/settings.json` | No |

Array settings (permissions, plugins) **merge** across scopes. Object settings **override**.

Managed settings locations:

- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux: `/etc/claude-code/managed-settings.json`

## Schema Validation

Add to any settings file for IDE autocomplete:

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json"
}
```

## Key Settings by Category

### Permissions

```json
{
  "permissions": {
    "allow": ["Bash(npm run *)", "Read(~/.zshrc)"],
    "ask": ["Bash(git push *)"],
    "deny": ["Bash(curl *)", "Read(./.env)"]
  }
}
```

Rule syntax: `Tool` or `Tool(specifier)`. Evaluation order: deny > ask > allow.

### Hooks

```json
{
  "hooks": { },
  "disableAllHooks": false
}
```

Events: SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, Notification, Stop, SubagentStart, SubagentStop, PreCompact, TeammateIdle, TaskCompleted, ConfigChange, WorktreeCreate, WorktreeRemove, SessionEnd, Setup.

### Sandbox

```json
{
  "sandbox": {
    "enabled": true,
    "filesystem": {
      "allowWrite": ["//tmp/build"],
      "denyRead": ["~/.aws/credentials"]
    },
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"]
    }
  }
}
```

Path prefixes: `//` = filesystem root, `~/` = home, `/` = settings file dir, `./` = relative.

### Model & Behavior

| Key | Type | Description |
|-----|------|-------------|
| `model` | string | Default model override |
| `availableModels` | array | Restrict model selection |
| `effortLevel` | `"low"` / `"medium"` / `"high"` | Reasoning effort (default: high) |
| `fastMode` | boolean | Enable fast mode |
| `alwaysThinkingEnabled` | boolean | Extended thinking by default |
| `language` | string | Response language |
| `outputStyle` | string | Adjust system prompt style |

### Plugins & Marketplaces

| Key | Type | Description |
|-----|------|-------------|
| `enabledPlugins` | object | Per-plugin enable/disable |
| `extraKnownMarketplaces` | object | Additional marketplace sources |
| `skippedPlugins` | array | Plugin IDs to skip |
| `pluginConfigs` | object | Per-plugin configuration |

### MCP Servers

| Key | Type | Description |
|-----|------|-------------|
| `enableAllProjectMcpServers` | boolean | Auto-approve project MCP servers |
| `enabledMcpjsonServers` | array | Approved server names |
| `disabledMcpjsonServers` | array | Rejected server names |
| `allowedMcpServers` | array | Allowlist (serverName/serverCommand/serverUrl) |
| `deniedMcpServers` | array | Denylist |

### Environment & Integration

| Key | Type | Description |
|-----|------|-------------|
| `env` | object | Environment variables per session |
| `apiKeyHelper` | string | Script path for auth credentials |
| `statusLine` | object | Custom status line command |
| `fileSuggestion` | object | Custom file autocomplete script |
| `plansDirectory` | string | Custom plans storage location |
| `respectGitignore` | boolean | Honor .gitignore (default: true) |
| `cleanupPeriodDays` | integer | Transcript retention days (default: 30) |

### Git Attribution

```json
{
  "attribution": {
    "commit": "Co-Authored-By: Claude <noreply@anthropic.com>",
    "pr": "Generated with Claude Code"
  }
}
```

### Agent Teams

| Key | Type | Description |
|-----|------|-------------|
| `teammateMode` | `"auto"` / `"in-process"` / `"tmux"` | How teammates are spawned |

Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `env`.

## Managed-Only Keys

These can only appear in `managed-settings.json`:

- `allowManagedHooksOnly` - Prevent user/project hooks
- `allowManagedPermissionRulesOnly` - Enforce permission rules
- `allowManagedMcpServersOnly` - Enforce MCP server allowlist
- `strictKnownMarketplaces` - Allowlist plugin marketplaces
- `blockedMarketplaces` - Denylist marketplaces
- `disableBypassPermissionsMode` - Disable permission bypass

## Verify Active Settings

Run `/status` in Claude Code to see active settings sources, origins, and errors.
