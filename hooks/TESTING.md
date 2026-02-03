# Hook Testing Guide

This document describes how hooks are tested and which require manual verification.

## Hooks Tested by /test-plugin

The following hooks are automatically validated by `/bluera-base:test-plugin`:

| Hook | Test Coverage |
|------|---------------|
| `session-setup.sh` | jq dependency check, config loading |
| `block-manual-release.sh` | Pattern matching for release commands |
| `pre-compact.sh` | State preservation |
| `checklist-remind.sh` | Checklist detection |

## Manual Testing Required

These hooks require manual testing due to their interactive or contextual nature:

### post-edit-check.sh

**Purpose:** Validates edited files for anti-patterns, lint suppressions, and strict typing violations.

**Test procedure:**

1. Enable strict typing:

   ```bash
   /bluera-base:config enable strict-typing
   ```

2. Edit a TypeScript file to introduce a violation:

   ```typescript
   const x: any = "test";  // Should trigger warning
   ```

3. Verify warning appears in hook output
4. Check that `// ok:` escape hatch works

### standards-review.sh

**Purpose:** Reviews code against project standards (when configured).

**Test procedure:**

1. Make an edit that violates a project rule
2. Verify the hook flags the violation
3. Check that legitimate changes pass

### observe-learning.sh

**Purpose:** Tracks command patterns for session-end learning synthesis.

**Test procedure:**

1. Run several repeated commands (e.g., `bun test` 3+ times)
2. End session
3. Verify signals file contains command counts:

   ```bash
   cat .bluera/bluera-base/state/signals.json
   ```

### session-end-learn.sh

**Purpose:** Synthesizes learnings from session patterns.

**Test procedure:**

1. Enable auto-learn:

   ```bash
   /bluera-base:config set autoLearn.enabled true
   /bluera-base:config set autoLearn.mode suggest
   ```

2. Run test commands repeatedly to hit threshold
3. End session
4. Verify learning suggestions appear

### session-end-analyze.sh

**Purpose:** Uses Claude CLI to analyze session transcript for learnings.

**Test procedure:**

1. Enable deep learning:

   ```bash
   /bluera-base:config set deepLearn.enabled true
   ```

2. Have a session with corrections or error resolutions
3. End session
4. Check pending learnings:

   ```bash
   /bluera-base:learn show
   ```

### milhouse-stop.sh

**Purpose:** Continues milhouse loop until completion promise or max iterations.

**Test procedure:**

1. Start a loop:

   ```bash
   /bluera-base:milhouse-loop --inline "Count to 3" --max-iterations 3
   ```

2. Verify loop continues until promise or max iterations
3. Test gate behavior with `--gate "exit 0"` and `--gate "exit 1"`

### auto-commit.sh

**Purpose:** Auto-commits changes at session end (when configured).

**Test procedure:**

1. Enable auto-commit:

   ```bash
   /bluera-base:config set autoCommit.enabled true
   ```

2. Make changes during session
3. End session
4. Verify commit was created

### dry-scan.sh

**Purpose:** Scans for code duplication at session end.

**Test procedure:**

1. Enable dry scanning:

   ```bash
   /bluera-base:config set dryScan.enabled true
   ```

2. Create duplicate code blocks
3. End session
4. Verify duplication report appears

### notify.sh

**Purpose:** Sends system notifications for permission prompts.

**Test procedure:**

1. Trigger a permission prompt (e.g., new Bash command)
2. Verify system notification appears (macOS) or terminal bell (Linux)

## Environment Variables

All hooks have access to:

| Variable | Description |
|----------|-------------|
| `CLAUDE_PROJECT_DIR` | Project root directory |
| `CLAUDE_PLUGIN_ROOT` | Plugin installation directory |
| `CLAUDE_SESSION_ID` | Current session identifier |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Allow/success |
| 2 | Block with stderr message (PreToolUse only) |
| Other | Non-blocking error |

## Async Hooks

Async hooks (`async: true`) run in the background and cannot block operations:

- `observe-learning.sh`
- `session-end-learn.sh`
- `session-end-analyze.sh`
- `dry-scan.sh`
- `notify.sh`
