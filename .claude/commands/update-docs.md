---
description: Search external sources and update docs with Claude Code changes
allowed-tools: WebFetch, WebSearch, Bash(gh:*), Bash(date:*), Read, Write, Edit, Glob, Grep, Task
argument-hint: [--apply] [--since YYYY-MM-DD]
---

# Update Docs

Search Claude Code CHANGELOG, GitHub issues, and community sources to update `docs/**` with latest changes.

See @.claude/skills/docs-updater/SKILL.md for update guidelines.

## Arguments

- `--apply`: Actually apply the updates (default: report only)
- `--since YYYY-MM-DD`: Only check changes since this date (default: last 30 days)

## Current Docs

!`ls -la docs/*.md 2>/dev/null | awk '{print $NF}'`

## Workflow

### Phase 1: Fetch Primary Sources

1. **Fetch Claude Code CHANGELOG.md**

   Use WebFetch to retrieve:
   ```
   https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md
   ```

   Parse for entries since the `--since` date (or last 30 days).
   Focus on: Added, Changed, Deprecated, Removed, Fixed sections.

2. **Search GitHub Issues**

   Use `gh` CLI to search recent closed issues:
   ```bash
   gh issue list --repo anthropics/claude-code --state closed --limit 50 --json number,title,labels,closedAt
   ```

   Filter for: hooks, plugins, MCP, memory, settings topics.

3. **Web Search (optional)**

   Use WebSearch for:
   - `site:reddit.com/r/ClaudeCode` recent discussions
   - Claude Code plugin best practices 2025-2026

### Phase 2: Analyze Findings

For each finding, categorize per the skill:
- New feature
- Deprecation
- Bug fix
- Best practice
- Breaking change

Map each to the appropriate doc file:
| Topic | Doc |
|-------|-----|
| Hooks | `docs/hook-examples.md`, `docs/advanced-patterns.md` |
| Plugins | `docs/claude-code-best-practices.md` |
| Troubleshooting | `docs/troubleshooting.md` |

### Phase 3: Generate Report

Create a structured report showing:

```markdown
# Docs Update Report

**Generated**: [date]
**Sources checked**: CHANGELOG, GitHub Issues, Web

## Proposed Updates

### docs/[file].md

1. **[Section]**: [What to add/change]
   - Source: [CHANGELOG v1.2.3 | Issue #123 | Reddit]
   - Action: [Add | Update | Deprecate | Remove]

## Already Current

- [List items already documented]

## Skipped

- [Items not meeting quality bar]
```

### Phase 4: Apply Updates (if --apply)

If `--apply` flag is provided:

1. Read each target doc file
2. Make the proposed changes using Edit tool
3. Add attribution comments where appropriate
4. Update "Last reviewed" date at bottom of each doc

### Phase 5: Summary

Output final summary:
- Number of docs updated
- Key changes made
- Recommendations for manual review

## Constraints

- Never delete existing content without explicit user approval
- Preserve existing structure and formatting
- Add version/date attribution for traceability
- Flag uncertain updates for human review
- Default to report-only mode (require --apply to make changes)

## Example

```bash
# Report only (default)
/update-docs

# Report for last 60 days
/update-docs --since 2025-11-15

# Apply updates
/update-docs --apply

# Apply updates for specific period
/update-docs --apply --since 2025-12-01
```
