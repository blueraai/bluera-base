---
name: claude-code-auto-improve
description: Fetch latest Claude Code updates, validate plugin, and apply improvements
argument-hint: "[check|apply|config]"
allowed-tools: [Read, Write, Edit, Glob, Grep, Task, WebFetch, AskUserQuestion, Bash]
---

# Auto-Improve

Automatically improve bluera-base by fetching latest Claude Code updates and validating against best practices.

## Modes

| Mode | Description |
|------|-------------|
| `check` | Analyze only, no changes (default) |
| `apply` | Apply improvements after confirmation |
| `config` | Show/edit auto-improve configuration |

## Workflow

```text
┌─────────────────┐
│ Gather Updates  │ ← CHANGELOG, GitHub issues, learnings, knowledge
└────────┬────────┘
         ▼
┌─────────────────┐
│ Analyze & Design│ ← Compare + design adoption proposals for new features
└────────┬────────┘
         ▼
┌─────────────────┐
│ Validate Plugin │ ← Audit patterns + evaluate adoption candidates
└────────┬────────┘
         ▼
┌─────────────────┐
│ Propose Changes │ ← Actionable proposals with implementation sketches
└────────┬────────┘
         ▼
┌─────────────────┐
│ Apply & Commit  │ ← Make changes, version bump if needed
└─────────────────┘
```

---

## Phase 1: Gather Updates

Collect information from multiple sources. See [references/sources.md](references/sources.md) for details.

### 1.1 Read Pending Learnings

```bash
# Check for pending learnings
cat .bluera/bluera-base/state/pending-learnings.jsonl 2>/dev/null
```

Parse each line as JSON with fields: `type`, `pattern`, `learning`, `confidence`, `source`.

### 1.2 Fetch CHANGELOG

```yaml
webfetch:
  url: https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
  prompt: |
    Extract the most recent 5 changelog entries (versions).
    For each entry, return:
    - Version and date
    - Added items (new features)
    - Changed items (behavior changes)
    - Deprecated items
    - Fixed items
    Focus on entries related to: hooks, plugins, skills, commands, frontmatter, agents, statusline, MCP, settings

    For each Added item, also note:
    - Whether it's something a plugin could adopt (new hook event, new manifest field, new config option, new API data)
    - What type of plugin change it would require (new file, config update, hook registration, manifest field)
```

### 1.3 Validate Settings Against Schema

Fetch the canonical settings schema and compare against plugin settings files:

```yaml
webfetch:
  url: https://json.schemastore.org/claude-code-settings.json
  prompt: |
    Extract the full list of recognized top-level keys and their types.
    For object-type keys (permissions, hooks, sandbox, attribution, env),
    also list their recognized sub-keys.
    Return as a structured list.
```

Then validate all settings files in the plugin:

1. **Find settings files**: `.claude/settings.json`, `.claude/settings.local.json`, `.claude-plugin/settings.json`
2. **For each file**: Compare keys against the schema
3. **Flag**:
   - Unrecognized keys (typos or removed fields)
   - Deprecated keys (if noted in schema description)
   - Missing recommended keys (e.g., `$schema` for IDE validation)
4. **Also check** `hooks.json` event names against the schema's hook event enum

Add findings to the Phase 2 comparison results under a `settings_validation` category.

### 1.4 Search Knowledge Store (if available)

```yaml
mcp:
  tool: mcp__plugin_bluera-knowledge_bluera-knowledge__search
  params:
    query: "Claude Code hooks plugins skills recent changes"
    stores: ["claude-code-docs"]
    intent: find-documentation
    detail: contextual
    limit: 10
```

If store not found, skip this step.

### 1.5 Query GitHub Issues

```bash
gh api repos/anthropics/claude-code/issues \
  --paginate \
  -q '.[] | select(.labels[].name == "bug" or .labels[].name == "enhancement") | {number, title, labels: [.labels[].name], created_at}' \
  | head -20
```

Focus on issues labeled: `hooks`, `plugins`, `bug`, `enhancement`.

---

## Phase 2: Analyze & Compare

### 2.1 Parse CHANGELOG

Extract relevant changes from the last 30 days:

**Categories to extract:**

- Hook changes (new events, behavior changes, breaking changes)
- Plugin manifest changes (new fields, deprecated fields)
- Skill/command frontmatter changes
- Agent system changes
- MCP integration changes

**Parsing patterns:**

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New hooks: `PreFoo`, `PostBar`
- New frontmatter field: `argument-hint`

### Changed
- Hook exit code 2 now blocks with message

### Deprecated
- `old_field` in plugin.json - use `new_field`

### Fixed
- Plugin loading order issue
```

### 2.2 Compare with Current Implementation

For each relevant change found:

1. **Search codebase** for affected patterns
2. **Check if already updated** (avoid redundant changes)
3. **Categorize priority**: breaking (high) > deprecation (medium) > enhancement (low)

```yaml
comparison_result:
  breaking_changes: []
  deprecated_patterns: []
  new_features: []
  improvements: []
```

### 2.3 Design Adoption

For each item in `new_features` and `improvements`, don't just note existence — **design how the plugin should use it**. Evaluate using this rubric:

| Signal | Action | Reasoning |
|--------|--------|-----------|
| New hook event our existing hooks should also fire on | **Adopt** | Direct gap — our hooks miss events |
| New manifest/config field that improves UX | **Adopt** if low-effort | Better marketplace/user experience |
| New API data hooks/statusline could consume | **Evaluate** | Only if data is useful to display or process |
| New feature irrelevant to our plugin type | **Skip** | Don't report as a finding |

For each item worth adopting, produce a **proposal**:

1. **Current state**: How does the plugin handle this today? (search codebase)
2. **Adoption sketch**: What files change? What's the concrete content?
3. **Effort**: Low (<30min) / Medium (1-2h) / High (half-day+)
4. **Benefit**: What user-facing improvement does this give?

**Critical rule:** Do not report passive observations like "we don't have one." Every finding must include a concrete proposal with files and content, or be skipped as irrelevant.

---

## Phase 3: Validate Plugin

### 3.1 Run Audit

Spawn the `claude-code-guide` agent to audit the plugin:

```yaml
task:
  subagent_type: claude-code-guide
  prompt: |
    Run a comprehensive audit of the bluera-base plugin.
    Focus on:
    1. Hook patterns against latest best practices
    2. Skill frontmatter against current spec
    3. Plugin manifest completeness
    4. Deprecated patterns that should be updated
    5. For each new Claude Code feature from the CHANGELOG (listed below),
       evaluate whether the plugin should adopt it:
       - Describe what adoption would look like (files, content)
       - Assess effort vs. benefit
       - Recommend: adopt / skip / defer

    CHANGELOG findings to evaluate:
    <pass the new_features list from Phase 2.3>

    Return findings as:
    - Critical: Must fix (with implementation sketch)
    - Warning: Should fix (with implementation sketch)
    - Info: Could improve (with adoption proposal)
    - Skip: Not relevant to this plugin (brief reason)
```

### 3.2 Check Specific Patterns

| Pattern | Check |
|---------|-------|
| Hook exit codes | Verify exit 2 for blocking, exit 0 for allow |
| Defensive stdin | All hooks should drain stdin |
| ${CLAUDE_PLUGIN_ROOT} | All paths should use this variable |
| Frontmatter | Check for deprecated or missing fields |
| async hooks | Verify appropriate use of async: true |
| Settings keys | Validate against SchemaStore schema (Phase 1.3) |

---

## Phase 4: Propose Improvements

### 4.1 Compile Findings

Organize findings as **actionable proposals**, not passive observations. Each finding must include what, why, how, and effort:

```markdown
## Auto-Improve Findings

### Proposals

**#1: Register SubagentStop handlers** (P1 · Low effort)
- **What**: Stop hooks don't fire for subagent completions
- **Current**: 5 Stop hooks registered, 0 SubagentStop hooks
- **Proposal**: Add SubagentStop entries in hooks.json for milhouse-stop, session-end-learn
- **Benefit**: Multi-agent workflows properly trigger stop hooks
- **Files**: `hooks/hooks.json`

**#2: Adopt `settings.json` for default plugin config** (P2 · Low effort)
- **What**: v2.1.49 lets plugins ship `settings.json` with defaults
- **Current**: Plugin initializes config at runtime via config helpers
- **Proposal**: Create `.claude-plugin/settings.json` with defaults for autoLearn, autoCommit, dryRun
- **Benefit**: New users get sensible behavior without manual setup
- **Files**: `.claude-plugin/settings.json` (new)

### Validation (passing)
- Hook exit codes: all correct
- Skill frontmatter: all valid
- Stdin draining: consistent

### Skipped (not relevant)
- Sonnet 4.6 support: already supported, no action needed
```

**Rules for findings:**

- Every proposal MUST have: What, Current, Proposal, Benefit, Files
- Validation passes go in a summary list, not individual entries
- Irrelevant items go in "Skipped" with a one-line reason
- Never write "we don't have one" without a concrete proposal for what to create

### 4.2 Get User Approval

```yaml
question: "How would you like to proceed with improvements?"
header: "Action"
options:
  - label: "Apply all (Recommended)"
    description: "Apply all improvements and commit"
  - label: "Apply selected"
    description: "Let me choose which to apply"
  - label: "Check only"
    description: "Show findings without changes"
multiSelect: false
```

If "Apply selected", present each finding with:

```yaml
question: "Apply this improvement?"
header: "Change"
options:
  - label: "Yes"
    description: "<change description>"
  - label: "Skip"
    description: "Don't apply this change"
multiSelect: false
```

---

## Phase 5: Apply & Commit

### 5.1 Apply Changes

For each approved change:

1. **Backup** - Note original content for rollback
2. **Apply** - Make the change using Edit tool
3. **Verify** - Ensure change was applied correctly

### 5.2 Version Bump (if needed)

If changes warrant a release:

```yaml
version_bump_criteria:
  patch: Bug fixes, documentation updates
  minor: New features, improvements
  major: Breaking changes (rare for auto-improve)
```

Use release skill with appropriate bump type.

### 5.3 Commit Changes

```bash
git add -A
git commit -m "chore(auto-improve): apply latest best practices

- <list of changes applied>

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Configuration

Configuration is stored in `.bluera/bluera-base/config.json`:

```json
{
  "autoImprove": {
    "enabled": false,
    "autoApply": false,
    "sources": ["changelog", "schema", "github", "knowledge", "learnings"],
    "changelogUrl": "https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"
  }
}
```

| Field | Default | Description |
|-------|---------|-------------|
| `enabled` | false | Enable auto-improve checks |
| `autoApply` | false | Apply changes without confirmation |
| `sources` | all | Which sources to check |
| `changelogUrl` | GitHub raw | CHANGELOG location |

### Managing Configuration

```bash
# View current config
/bluera-base:claude-code-auto-improve config

# Enable auto-improve
/bluera-base:settings set autoImprove.enabled true

# Set to auto-apply mode
/bluera-base:settings set autoImprove.autoApply true

# Disable specific source
/bluera-base:settings set autoImprove.sources '["changelog", "github"]'
```

---

## Error Handling

| Error | Action |
|-------|--------|
| CHANGELOG fetch fails | Log warning, continue with other sources |
| GitHub API rate limited | Skip GitHub issues, suggest `gh auth login` |
| Knowledge store not found | Skip knowledge search |
| No learnings file | Skip learnings, continue |
| Schema fetch fails | Log warning, skip settings validation |

Always complete with available sources rather than failing entirely.

---

## Output

Final output summarizes actions taken:

```markdown
## Auto-Improve Complete

**Sources checked:** changelog, schema, github, learnings
**Issues found:** 5
**Changes applied:** 3
**Skipped:** 2

### Applied Changes
1. Added argument-hint to 4 commands
2. Updated hook defensive stdin pattern
3. Fixed deprecated frontmatter field

### Skipped
1. Knowledge store search (not available)
2. Enhancement suggestion (user declined)
```
