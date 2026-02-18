# Data Sources

Configuration and details for auto-improve data sources.

## Source Priority

| Source | Priority | Method | Reliability |
|--------|----------|--------|-------------|
| Pending learnings | High | File read | Always available |
| CHANGELOG.md | High | WebFetch | Usually available |
| GitHub issues | Medium | gh CLI | Requires auth |
| bluera-knowledge | Medium | MCP search | Optional dependency |

---

## Pending Learnings

**Location:** `.bluera/bluera-base/state/pending-learnings.jsonl`

**Format:** JSON Lines (one JSON object per line)

```json
{"type": "command", "pattern": "bun test", "learning": "User runs tests frequently", "confidence": 0.85, "source": "session-analysis"}
{"type": "workflow", "pattern": "commit-then-test", "learning": "User prefers testing after commits", "confidence": 0.72, "source": "pattern-detection"}
```

**Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Learning category: command, workflow, preference |
| `pattern` | string | The observed pattern |
| `learning` | string | Human-readable description |
| `confidence` | float | 0.0-1.0 confidence score |
| `source` | string | Where this learning came from |

**Processing:**

1. Read file line by line
2. Parse each line as JSON
3. Filter by confidence threshold (default: 0.7)
4. Group by type for presentation

---

## CHANGELOG.md

**URL:** `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md`

**Fallback:** Check if local clone exists in bluera-knowledge store.

### Parsing Strategy

```markdown
## [1.0.50] - 2025-01-30

### Added
- New `argument-hint` field for command frontmatter
- PreCompact hook for state preservation

### Changed
- Hook exit code 2 now includes stderr in block message

### Deprecated
- `tool-whitelist` in favor of `allowed-tools`

### Fixed
- Plugin loading race condition
```

**Extract:**

1. Version number and date
2. Items under Added, Changed, Deprecated, Fixed
3. Filter for keywords: hook, plugin, skill, command, frontmatter, agent, MCP

**Date filtering:**

- Extract date from header `[X.Y.Z] - YYYY-MM-DD`
- Only include entries from last 30 days
- Configurable via `autoImprove.changelogDays`

---

## GitHub Issues

**API:** `gh api repos/anthropics/claude-code/issues`

**Authentication:** Requires `gh auth login`

### Query

```bash
gh api repos/anthropics/claude-code/issues \
  --paginate \
  -q '[.[] | select(.labels | map(.name) | any(. == "bug" or . == "enhancement" or . == "hooks" or . == "plugins"))] | .[0:20] | .[] | {number, title, labels: [.labels[].name], created_at, state}'
```

### Relevant Labels

| Label | Priority | Description |
|-------|----------|-------------|
| `hooks` | High | Direct hook changes |
| `plugins` | High | Plugin system changes |
| `bug` | Medium | Bug fixes to consider |
| `enhancement` | Low | Feature requests |
| `breaking` | Critical | Breaking changes |

### Rate Limiting

GitHub API has rate limits:

- Unauthenticated: 60/hour
- Authenticated: 5000/hour

If rate limited, log warning and skip this source.

---

## Bluera Knowledge

**Tool:** `mcp__plugin_bluera-knowledge_bluera-knowledge__search`

**Store:** `claude-code-docs` (if indexed)

### Check Store Availability

```yaml
mcp:
  tool: mcp__plugin_bluera-knowledge_bluera-knowledge__execute
  params:
    command: stores
```

Look for `claude-code-docs` in response.

### Search Query

```yaml
mcp:
  tool: mcp__plugin_bluera-knowledge_bluera-knowledge__search
  params:
    query: "hooks plugins skills frontmatter best practices"
    stores: ["claude-code-docs"]
    intent: find-documentation
    detail: contextual
    limit: 15
    threshold: 0.6
```

### Fallback

If store not available:

1. Log info message
2. Suggest running: `npx @anthropic-ai/claude-code --add-repo anthropics/claude-code`
3. Continue with other sources

---

## Source Configuration

In `.bluera/bluera-base/config.json`:

```json
{
  "autoImprove": {
    "sources": ["changelog", "github", "knowledge", "learnings"],
    "changelogUrl": "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md",
    "changelogDays": 30,
    "githubLabels": ["hooks", "plugins", "bug", "enhancement"],
    "learningsThreshold": 0.7
  }
}
```

### Disabling Sources

```bash
# Only use changelog and learnings
/bluera-base:settings set autoImprove.sources '["changelog", "learnings"]'

# Skip GitHub (useful if not authenticated)
/bluera-base:settings set autoImprove.sources '["changelog", "knowledge", "learnings"]'
```

---

## Error Handling

| Source | Error | Action |
|--------|-------|--------|
| Learnings | File not found | Skip, no warning |
| CHANGELOG | Fetch timeout | Warn, continue |
| CHANGELOG | 404 | Error, URL may have changed |
| GitHub | 401 Unauthorized | Suggest `gh auth login` |
| GitHub | 403 Rate limited | Skip, continue |
| Knowledge | Store not found | Info, suggest setup |
| Knowledge | MCP unavailable | Skip silently |

Always aim to complete with available sources rather than failing entirely.
