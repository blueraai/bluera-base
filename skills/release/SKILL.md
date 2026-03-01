---
name: release
description: Release workflow with conventional commits auto-detection and GitHub Actions monitoring.
argument-hint: "[patch|minor|major]"
allowed-tools: [Read, Glob, Grep, Bash]
---

# Release Workflow

Standardized release workflow that auto-detects version bump, bumps version, commits, pushes, and monitors CI.

**CRITICAL:** Do NOT push tags directly. Tags should only be created AFTER CI passes. Either:

1. Use auto-release workflow (creates tags after CI passes)
2. Or manually create tag only after verifying CI success

## Hook Bypass (REQUIRED)

A PreToolUse hook blocks manual release commands. To run version/release commands, you MUST prefix with exactly:

```bash
__SKILL__=release <command>
```

**Examples (use these exact formats):**

```bash
__SKILL__=release bun run version:patch
__SKILL__=release npm version minor
__SKILL__=release poetry version patch
__SKILL__=release cargo release patch --execute
```

**DO NOT invent alternative prefixes.** The hook checks for the literal string `__SKILL__=release` at the start of the command. Using any other format (like `RELEASE_SKILL_ACTIVE=1`) will be blocked.

## Pre-flight Checks

1. Run `git status` - ensure clean working directory
2. If uncommitted changes exist, commit them first
3. Verify you're on the correct branch (usually `main`)

## References

| Topic | Reference |
|-------|-----------|
| Auto-detection rules | [references/auto-detection.md](references/auto-detection.md) |
| CI monitoring | [references/ci-monitoring.md](references/ci-monitoring.md) |
| Language-specific commands | [references/languages.md](references/languages.md) |

## Workflow Summary

1. **Pre-flight:** `git status` - ensure clean working directory
2. **Analyze:** Check commits since last tag, determine bump type (patch/minor/major)
3. **Detect:** Run `detect-version-tool.sh` to find the right command
4. **Bump:** Run detected command with `__SKILL__=release` prefix (NO tag yet)
5. **Push:** Push version bump commit (triggers CI)
6. **Wait (REQUIRED):** Run the polling loop from [ci-monitoring.md](references/ci-monitoring.md) - do NOT proceed until:
   - ALL workflows show `status: completed`
   - Zero workflows are `in_progress` or `queued`
7. **Verify workflows:** Compare `.github/workflows/` files vs actual runs - ensure none missing
8. **Tag:** Create and push tag only AFTER CI passes (or let auto-release do it)
9. **Verify release:** `gh release list --limit 1` (or `glab release list` for GitLab) to confirm published

**IMPORTANT:** Do NOT declare "Release Complete" while any workflow shows `in_progress`. Run the full polling loop and wait for ALL workflows to reach `completed` status before finishing.
