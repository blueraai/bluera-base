# Base Rules

Core development principles for all code.

## Fail Fast

- Use `throw` for unexpected state or error conditions
- Never silently swallow errors
- Errors should be visible and actionable

## Strict Typing

- 100% strict typing; no `any`, no `as` casts unless completely unavoidable
- Type assertions require justification in comments
- Prefer type inference where unambiguous

## Clean Code

- No commented-out code in committed files
- No references to outdated or deprecated implementations
- Remove unused code; don't leave it "for reference"

## Hook Behavior

The "fail fast" rule applies to all hooks with one narrow exception:

### Mandatory Hooks (must fail if deps missing)

These hooks gate actions and MUST exit 2 when dependencies are missing:

- `check-git-secrets.sh` - Security: can't allow commits when secrets check can't run <!-- ok: hook documentation -->

### Optional Hooks (may warn + skip)

These hooks enhance sessions and may exit 0 with a stderr warning when deps are missing:

- `observe-learning.sh` - Auto-learn pattern tracking
- `dry-scan.sh` - Code duplication scanning
- `auto-commit.sh` - Commit prompting
- `milhouse-stop.sh` - Iteration loop
- `session-end-learn.sh` - Learning consolidation
- `session-end-analyze.sh` - Session analysis
- `teammate-idle.sh` - Agent team coordination
- `task-completed.sh` - Agent task result handling

### Requirements for Optional Hooks

To be classified as optional, a hook must:

1. Log a single-line warning to stderr: `[bluera-base] Skipping hook: reason`
2. Use centralized helpers (`bluera_require_jq`) rather than per-hook checks
3. Not gate security-critical actions

### Updating This List

When adding a new hook, explicitly add it to the appropriate list above.
Do not rely on inference; the classification must be explicit.
