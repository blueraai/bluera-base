# Troubleshooting Guide

Common issues and solutions for Claude Code plugins and hooks.

---

## Hook Debugging

### Enable Verbose Mode

```bash
# Run Claude Code with debug output
claude --debug

# Or set in settings.json
"verbose": true
```

This shows hook registration, execution timing, and any errors.

### Test Hook Scripts Manually

Hooks receive JSON via stdin. Test them directly:

```bash
# Test a PreToolUse hook
echo '{"tool_name": "Bash", "tool_input": {"command": "npm version patch"}}' | \
  bash hooks/block-manual-release.sh
echo "Exit code: $?"

# Test a PostToolUse hook
echo '{"tool_name": "Edit", "tool_input": {"file_path": "src/app.ts"}}' | \
  bash hooks/post-edit-check.sh

# Test a Stop hook
echo '{"transcript_path": "/path/to/transcript.jsonl", "stop_hook_active": false}' | \
  bash hooks/milhouse-stop.sh
```

### Common Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Allow / success |
| 2 | Block with message (stderr shown to user) |
| Other | Error (logged, hook skipped) |

---

## State File Issues

### State File Not Found

**Symptom**: Hooks report missing state files or paths.

**Solution**: Check `CLAUDE_PROJECT_DIR` is set correctly:

```bash
# In hooks, always use:
cd "${CLAUDE_PROJECT_DIR:-.}"
STATE_DIR="${CLAUDE_PROJECT_DIR:-.}/.bluera/bluera-base/state"
```

### State File Corruption

**Symptom**: Invalid iteration, parse errors, unexpected behavior.

**Solution**: Remove corrupted state and restart:

```bash
rm -rf .bluera/bluera-base/state/milhouse-loop.md
```

### Atomic State Writes

Always use atomic writes to prevent corruption:

```bash
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"
```

---

## Environment Variable Issues

### CLAUDE_ENV_FILE Empty or Missing

**Known issue**: `CLAUDE_ENV_FILE` may be empty/missing in some environments.

**Symptom**: Bash commands don't have access to published env vars.

**Solution**: Always implement fallbacks:

```bash
# In hooks that publish env vars
if [[ -n "${CLAUDE_ENV_FILE:-}" ]] && [[ -f "$CLAUDE_ENV_FILE" ]]; then
    echo "export MY_VAR=\"$VALUE\"" >> "$CLAUDE_ENV_FILE"
fi

# In commands/scripts that consume env vars
STATE_DIR="${BLUERA_STATE_DIR:-${CLAUDE_PROJECT_DIR:-.}/.bluera/bluera-base/state}"
```

### SessionStart Hook Not Receiving CLAUDE_ENV_FILE

**Known issue**: Plugin SessionStart hooks may not receive `CLAUDE_ENV_FILE`.

**Workaround**:

- Provide a manual `/init` command that runs the same setup logic
- Design commands to lazily initialize if state is missing

---

## Plugin Loading Issues

### Plugin Not Appearing

**Symptoms**:

- Commands not available via `/plugin-name:command`
- Skills not being applied

**Solutions**:

1. Clear plugin cache:

   ```bash
   rm -rf ~/.claude/plugins/cache
   ```

2. Validate manifest:

   ```bash
   claude plugin validate
   ```

3. Check plugin structure:

   ```text
   my-plugin/
   ├─ .claude-plugin/
   │  └─ plugin.json    # Manifest here
   ├─ commands/         # At plugin root, NOT inside .claude-plugin
   ├─ skills/
   └─ hooks/
   ```

### Skills Not Loading

**Symptom**: Skill not being applied automatically.

**Causes**:

- `description` field not matching task intent
- `disable-model-invocation: true` set (manual only)
- SKILL.md too large (context bloat)

**Solution**: Keep SKILL.md lean, push detail to `references/*.md`.

---

## Hook Registration Issues

### Hooks Not Firing

1. Check `hooks.json` structure:

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "command": "${CLAUDE_PLUGIN_ROOT}/hooks/my-hook.sh"
         }
       ]
     }
   }
   ```

2. Verify script is executable:

   ```bash
   chmod +x hooks/*.sh
   ```

3. Check matcher syntax - common patterns:
   - `"Bash"` - matches Bash tool
   - `"Write|Edit"` - matches Write OR Edit
   - `""` or missing - matches all tools

### Hooks Firing Multiple Times

**Cause**: Multiple plugins or duplicate hook registrations.

**Solution**: Check all installed plugins and remove duplicates.

---

## Cross-Session Issues

### State Bleed Between Terminals

**Symptom**: Hook fires in wrong terminal session.

**Cause**: State file not session-scoped.

**Solution**: Use session ID from transcript path:

```bash
CURRENT_SESSION=$(echo "$HOOK_INPUT" | jq -r '.transcript_path' | md5 -q)

# Store in state file
STORED_SESSION=$(grep '^session_id:' "$STATE_FILE" | sed 's/session_id: *//')

# Ignore if mismatch
if [[ "$STORED_SESSION" != "$CURRENT_SESSION" ]]; then
  exit 0
fi
```

---

## Common Error Patterns

### jq: command not found

**Solution**: Install jq

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Windows (Git Bash)
# Download from https://stedolan.github.io/jq/download/
```

**Note**: On macOS with Homebrew, this plugin auto-installs jq if missing. This behavior is silent and only applies to macOS+Homebrew environments.

### Permission Denied on Hook Scripts

```bash
chmod +x hooks/*.sh
```

### JSON Parse Errors

Always validate JSON before processing:

```bash
if ! RESULT=$(echo "$INPUT" | jq -r '.field' 2>&1); then
  echo "Parse error: $RESULT" >&2
  exit 0  # Fail open, not closed
fi
```

### Infinite Stop Hook Loops

**Symptom**: Claude keeps retrying after Stop hook blocks.

**Solution**: Check `stop_hook_active` field:

```bash
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false')
if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  exit 0  # Already tried once, allow exit
fi
```

---

## Compaction Issues

### CLAUDE.md Ignored After /compact

**Known issue**: Claude may "forget" CLAUDE.md guidance after compaction.

**Solutions**:

1. Use `SessionStart` hook to inject critical invariants:

   ```json
   {
     "hookSpecificOutput": {
       "additionalContext": "Critical: Always run tests before commit"
     }
   }
   ```

2. Keep a minimal "Critical invariants" section in CLAUDE.md (5-15 lines max)

3. Use `PreCompact` hook to snapshot important state

---

## Marketplace Issues

### Plugin Updates Not Appearing

**Symptom**: Version bump doesn't result in updated plugin.

**Solution**:

```bash
# Update marketplace cache
/plugin marketplace update <marketplace>

# Or manually pull
cd ~/.claude/plugins/marketplaces/<marketplace-name>/
git pull
```

### Self-Hosted Marketplace Stale

**Workaround**: Always update marketplace before install:

```bash
/plugin marketplace update my-marketplace
/plugin install my-plugin
```

---

## Diagnostic Commands

### Check Hook Registration

```bash
# View hooks.json
cat ~/.claude/plugins/cache/<plugin>/hooks/hooks.json | jq

# List installed plugins
ls ~/.claude/plugins/cache/
```

### Check State Files

```bash
# View milhouse state
cat .bluera/bluera-base/state/milhouse-loop.md

# View config
cat .bluera/bluera-base/config.json
```

### Test Without Plugin Cache

```bash
# Run with plugin from source directory
claude --plugin-dir /path/to/my-plugin
```

---

## Finding the Claude Executable

When configuring Claude Code for MCP servers or external integrations, you may need the full path to the executable.

### Quick Methods

```bash
# Preferred: handles aliases correctly
command -v claude

# Alternative (may not work with aliases)
which claude
```

**Note**: `which claude` returns the alias definition if Claude is aliased, not the actual path. Use `command -v` instead.

### Known Installation Locations

| Location | Notes |
|----------|-------|
| `~/.claude/local/claude` | Newer installation location |
| `~/.local/bin/claude` | Standard symlink location (per docs) |
| `/opt/homebrew/bin/claude` | Homebrew on Apple Silicon |
| `/usr/local/bin/claude` | Homebrew on Intel Mac |
| `%USERPROFILE%\.local\bin\claude.exe` | Windows |

### Robust Detection (for scripts)

```bash
find_claude() {
  # 1. Explicit override
  if [[ -n "$CLAUDE_BIN" && -x "$CLAUDE_BIN" ]]; then
    echo "$CLAUDE_BIN"
    return 0
  fi

  # 2. Check known locations
  for loc in "$HOME/.claude/local/claude" "$HOME/.local/bin/claude"; do
    if [[ -x "$loc" ]]; then
      echo "$loc"
      return 0
    fi
  done

  # 3. Fall back to PATH (handles aliases)
  command -v claude
}
```

### MCP Configuration

When configuring Claude as an MCP server, use the full path:

```json
{
  "mcpServers": {
    "claude": {
      "command": "/Users/you/.claude/local/claude",
      "args": ["mcp", "serve"]
    }
  }
}
```

---

## Known Upstream Issues

These are known issues in Claude Code itself, not this plugin. They may affect your experience.

### SessionStart Hook Shows "error" Status

**GitHub issue**: [#19346](https://github.com/anthropics/claude-code/issues/19346)

**Symptom**: SessionStart hooks display as "error" in the UI even when they succeed.

**Reality**: This is cosmetic. Check hook output to verify actual success/failure.

### CLAUDE_ENV_FILE Inconsistency

**GitHub issue**: [#19357](https://github.com/anthropics/claude-code/issues/19357)

**Symptom**: `CLAUDE_ENV_FILE` may be empty or missing in certain contexts.

**Workaround**: Always implement fallbacks (see Environment Variable Issues section above).

### Plugin Marketplace Cache

**GitHub issue**: [#16866](https://github.com/anthropics/claude-code/issues/16866)

**Symptom**: Plugin updates don't appear after version bump.

**Solution**: Run `/plugin marketplace update <marketplace>` or clear `~/.claude/plugins/cache`.

### First-Launch Race Condition

**GitHub issue**: [#19275](https://github.com/anthropics/claude-code/issues/19275)

**Symptom**: Plugins may not fully initialize on first launch after install.

**Workaround**: Restart Claude Code session after installing new plugins.

### Compaction May Lose Settings

**GitHub issue**: [#19062](https://github.com/anthropics/claude-code/issues/19062)

**Symptom**: Claude may forget CLAUDE.md guidance after `/compact`.

**Workaround**: See Compaction Issues section above.

### Windows Plugin UX

**GitHub issue**: [#9426](https://github.com/anthropics/claude-code/issues/9426)

**Symptom**: Various plugin-related UX issues on Windows.

**Status**: Improvements ongoing. Consider WSL for more consistent behavior.

---

## References

- [Claude Code Hooks Docs](https://code.claude.com/docs/en/hooks)
- [Claude Code Plugins Docs](https://code.claude.com/docs/en/plugins)
- [Claude Code MCP Docs](https://code.claude.com/docs/en/mcp)
- [Known Issues](https://github.com/anthropics/claude-code/issues)
