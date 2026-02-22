---
name: claude-code-audit-plugin
description: Audit a Claude Code plugin against best practices and suggest improvements
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion]
---

# Audit Plugin

Apply Claude Code plugin best practices from our documentation to audit a plugin repo.

See docs/claude-code-best-practices.md for the full best practices guide.

## Context

Check for `.claude-plugin/plugin.json` in the current directory or user-specified path. If not found, ask the user to specify the plugin location.

## Best Practices Checklist

### 1. Plugin Structure

```text
plugin/
├─ .claude-plugin/
│  └─ plugin.json          # Manifest ONLY here
├─ commands/               # At root, NOT in .claude-plugin
├─ skills/
├─ hooks/
├─ agents/
└─ templates/
```

**Check**:

- [ ] `plugin.json` is in `.claude-plugin/` (not root)
- [ ] Commands/skills/hooks are at plugin root, not nested in `.claude-plugin/`
- [ ] No files outside plugin root referenced via `../`

### 2. Plugin Manifest (plugin.json)

**Required fields**:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "...",
  "author": { "name": "...", "email": "..." },
  "repository": "...",
  "license": "MIT"
}
```

**Discoverability fields** (recommended):

```json
{
  "categories": ["development", "automation"],
  "compatibility": { "minVersion": "2.1.0" }
}
```

**Check**:

- [ ] All required fields present
- [ ] Version follows semver
- [ ] Description is meaningful (not placeholder)
- [ ] Has `categories` array for marketplace discovery
- [ ] Has `compatibility.minVersion` if plugin uses features from specific versions

### 2b. Plugin Settings (v2.1.49+)

Plugins can ship `.claude-plugin/settings.json` to provide default configuration.

**Check**:

- [ ] If plugin has configurable behavior, `settings.json` exists with safe defaults
- [ ] All settings default to `false` or conservative values (opt-in, not opt-out)
- [ ] Settings file is valid JSON

### 3. Commands

**Frontmatter requirements**:

```yaml
---
description: Clear, actionable description
allowed-tools: Explicit tool list
argument-hint: [optional] Arguments if any
---
```

**Check**:

- [ ] All commands have description
- [ ] allowed-tools are explicit (not `*`)
- [ ] No dangerous tool patterns (`Bash(*)`)

### 4. Skills

**Structure**:

```text
skills/
└─ skill-name/
   ├─ SKILL.md              # Main skill file
   └─ references/           # Optional deep-dive docs
```

**Check**:

- [ ] SKILL.md exists for each skill
- [ ] Progressive disclosure (SKILL.md lean, references for detail)
- [ ] Description in frontmatter matches purpose
- [ ] No `!` backtick patterns in docs (accidental execution)

### 5. Hooks

**Registration** (`hooks/hooks.json`):

```json
{
  "hooks": {
    "PreToolUse": [{ "matcher": "...", "hooks": [...] }]
  }
}
```

**Check**:

- [ ] hooks.json has valid structure
- [ ] Scripts use `${CLAUDE_PLUGIN_ROOT}` for paths
- [ ] Scripts are executable (`chmod +x`)
- [ ] Exit codes are correct (0=allow, 2=block)
- [ ] No infinite loops in Stop hooks (check `stop_hook_active`)
- [ ] All hooks drain stdin (`cat 2>/dev/null || true` or equivalent)
- [ ] If Stop hooks exist, SubagentStop handlers should also be registered for any that apply to subagent completions
- [ ] Stop/SubagentStop hooks use `last_assistant_message` from hook input (v2.1.47+) instead of parsing transcript files directly — transcript fallback is acceptable for backward compatibility

### 5b. Hook Event Coverage

Verify the plugin registers for all relevant hook events:

| Event | When to use |
|-------|-------------|
| `SessionStart` | Session initialization, config loading |
| `PreToolUse` | Validate/block tool calls |
| `PostToolUse` | React to completed tool calls |
| `PreCompact` | Preserve state before context compaction |
| `Notification` | System notifications (permission prompts, idle) |
| `Stop` | Session end behavior |
| `SubagentStop` | Subagent completion (mirror relevant Stop hooks) |
| `TeammateIdle` | Agent team coordination |
| `TaskCompleted` | Task tracking in agent teams |
| `ConfigChange` | React to mid-session config changes (v2.1.49+) |
| `WorktreeCreate` / `WorktreeRemove` | Worktree lifecycle (v2.1.50+) |

**Check**:

- [ ] If plugin has Stop hooks, evaluate whether SubagentStop handlers are also needed
- [ ] If plugin uses agent teams, TeammateIdle and TaskCompleted should be registered

### 6. Token Efficiency

**Check**:

- [ ] SKILL.md files are lean (< 200 lines ideally)
- [ ] Large content in references/, not main files
- [ ] No large inline code dumps
- [ ] Uses file pointers instead of inline content where possible

### 7. Security

**Check**:

- [ ] No secrets in committed files
- [ ] No `--no-verify` patterns
- [ ] allowed-tools are scoped narrowly
- [ ] PreToolUse hooks for dangerous command blocking

## Workflow

### Phase 1: Locate Plugin

If path argument provided, use it. Otherwise check current directory.

```bash
PLUGIN_PATH="${1:-.}"
if [ ! -f "$PLUGIN_PATH/.claude-plugin/plugin.json" ]; then
  echo "No plugin.json found at $PLUGIN_PATH/.claude-plugin/"
  exit 1
fi
```

### Phase 2: Run Audits

For each checklist item:

1. Run check
2. Record pass/fail/warning
3. Note specific issues

### Phase 3: Generate Report

```markdown
## Plugin Audit Report

**Plugin**: example-plugin v1.0.0
**Audited**: 2026-01-16

### Summary
- Checks: 20
- Passed: 15
- Warnings: 3
- Failed: 2

### Issues

#### Failed
1. **Commands missing allowed-tools**
   - `commands/deploy.md` - no allowed-tools frontmatter
   - Fix: Add `allowed-tools: Bash(deploy:*), Read`

2. **Hook script not executable**
   - `hooks/validate.sh` missing execute permission
   - Fix: `chmod +x hooks/validate.sh`

#### Warnings
1. **Large SKILL.md** (312 lines)
   - `skills/complex-skill/SKILL.md`
   - Suggestion: Move detail to references/

### Passed
- Plugin structure correct
- Manifest complete
- No secrets detected
- ...
```

### Phase 4: Apply Fixes (if --fix)

If `--fix` flag provided:

1. Fix executable permissions
2. Add missing frontmatter fields
3. Restructure if needed

Report changes made.

## Historical Optimizations

Search bluera-base git history for optimizations:

```bash
git log --oneline --all --grep="optimize" --grep="perf" --grep="token"
```

Key optimizations from our history:

- Pointer-based data passing (80-90% token savings)
- Progressive skill disclosure
- State file scoping per session
- Rate-limited type checking in hooks

## Constraints

- Never modify without `--fix` flag
- Preserve existing functionality
- Suggest, don't force structural changes
- Report security issues prominently

## Related Skills

| Skill | Use For |
|-------|---------|
| `/bluera-base:claude-code-guide` | Questions about best practices, unclear patterns |
| `/bluera-base:claude-code-graph` | Visualize plugin structure and dependencies |
| `/bluera-base:claude-code-test-plugin` | Run validation test suite after fixes |

**When to consult claude-code-guide:**

- Uncertain whether a pattern is best practice
- Need clarification on hook exit codes or behavior
- Plugin uses features not covered in checklist
