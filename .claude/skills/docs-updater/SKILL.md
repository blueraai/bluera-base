# Docs Updater Skill

Guidelines for analyzing external sources and updating bluera-base documentation.

---

## Source Priority

| Source | Trust | Use For |
|--------|-------|---------|
| Claude Code CHANGELOG.md | Highest | New features, breaking changes, deprecations |
| GitHub Issues (closed) | High | Bug fixes, feature implementations, clarifications |
| GitHub Issues (open) | Medium | Upcoming changes, known issues |
| Reddit r/ClaudeCode | Medium | Community patterns, workarounds, real-world gotchas |
| General web | Low | Validation only, not primary source |

---

## Finding Categories

### 1. New Features
- New hooks, events, or API changes
- New configuration options
- New CLI flags or commands

**Action**: Add to relevant doc section with code examples.

### 2. Deprecations
- Removed or deprecated features
- Changed behavior

**Action**: Mark deprecated in docs, add migration guidance.

### 3. Bug Fixes
- Behavior changes from bug fixes
- Issues we documented that are now resolved

**Action**: Update or remove workarounds, note fix version.

### 4. Best Practices
- Community-validated patterns
- Official recommendations
- Performance or security improvements

**Action**: Add to best practices section with attribution.

### 5. Breaking Changes
- API changes requiring code updates
- Configuration format changes

**Action**: Prominent warning, migration steps, version note.

---

## Doc Section Mapping

| Finding Topic | Target Doc |
|---------------|------------|
| Hooks (events, API, examples) | `docs/hook-examples.md`, `docs/advanced-patterns.md` |
| Plugins (structure, distribution) | `docs/claude-code-best-practices.md` |
| Memory (CLAUDE.md, rules) | `docs/claude-code-best-practices.md` |
| MCP, LSP | `docs/claude-code-best-practices.md` |
| Troubleshooting | `docs/troubleshooting.md` |
| Settings, configuration | `docs/claude-code-best-practices.md` |
| Token efficiency, context | `docs/advanced-patterns.md` |

---

## Update Quality Bar

### Include if:
- Directly affects how plugins/hooks work
- Changes documented behavior
- Provides actionable guidance
- Resolves known pain points
- Official recommendation from Anthropic

### Exclude if:
- Minor internal changes
- Experimental/unstable features
- Already covered in our docs
- Speculative or unconfirmed
- Platform-specific edge cases (unless significant)

---

## Update Formatting

### New Content
```markdown
## Section Title

[Content here]

*Added: YYYY-MM-DD based on [source]*
```

### Updated Content
```markdown
[Updated content]

*Updated: YYYY-MM-DD - [brief reason]*
```

### Deprecated Content
```markdown
> **Deprecated (vX.Y.Z)**: [Feature] is deprecated. Use [alternative] instead.
```

---

## CHANGELOG Parsing

The Claude Code CHANGELOG follows semantic versioning. Parse entries by:

1. **Version header**: `## [X.Y.Z] - YYYY-MM-DD`
2. **Section types**: Added, Changed, Deprecated, Removed, Fixed, Security
3. **Entry format**: `- Description (#issue-number)`

Focus on:
- Hooks and plugin-related changes
- API changes
- Breaking changes
- Security fixes

---

## GitHub Issue Signals

### High-value issues:
- Label: `enhancement`, `bug`, `documentation`
- Status: closed with merge
- Referenced in CHANGELOG

### Extract from issues:
- Problem description
- Official solution/workaround
- Related PR or commit
- Version fixed/implemented

---

## Report Format

Generate a structured report before applying:

```markdown
# Docs Update Report

## Summary
- X new features found
- Y deprecations
- Z best practice updates

## Proposed Changes

### docs/file.md

**Line 42**: Add new hook event `PreCompact`
> Source: CHANGELOG v1.2.3

**Line 156**: Update MCP configuration example
> Source: GitHub Issue #1234

## No Changes Needed
- [List items already up to date]
```

---

## Safety

1. **Never delete** user-added content without explicit approval
2. **Preserve** existing structure and formatting
3. **Add** version/date attribution for traceability
4. **Flag** uncertain updates for human review
5. **Keep** "Last reviewed" date at doc footer
