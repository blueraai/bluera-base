# bluera-base plugin audit + upgrade spec
_Date: 2026-01-15_  
_Target plugin version: 0.2.0 (from 0.1.0)_

This document is a **work spec** for improving the `bluera-base` Claude Code plugin based on the audited files:

- `.claude-plugin/plugin.json`
- `hooks/hooks.json`
- `hooks/post-edit-check.sh`
- `includes/CLAUDE-BASE.md`

It is written to be directly actionable: file-by-file changes, with copy/paste-ready content where useful.

---

## 0) Goals

1. **Use rules effectively** by shipping **rule templates** (for `.claude/rules/`) that projects can install quickly.
2. **Make enforcement deterministic** by aligning hooks with your “ALWAYS/NEVER” policies (especially “NO `--no-verify`” and “NO fallback/legacy/deprecated/backward-compat”).
3. **Fix correctness gaps** in the current validation hook:
   - new/untracked files are currently missed
   - anti-pattern search currently misses most subdirectories
   - generated outputs (`dist/`) can unintentionally trigger linting
4. **Improve ergonomics**:
   - more precise linting (based on the file Claude actually touched)
   - better output (concise, actionable)
   - fewer unnecessary heavy checks

---

## 1) High-impact findings (current gaps)

### 1.1 post-edit-check misses new files
`post-edit-check.sh` detects modified files using `git diff --name-only HEAD`. That **does not include untracked files**, so a `Write` of a brand new file can bypass lint/type checks entirely.

### 1.2 Anti-pattern scan doesn’t recurse into subdirectories
`check_anti_patterns()` builds `PATTERNS` like `*.ts`, `*.py`, `*.rs`, `*.go`. Git pathspec `*.ts` only matches files in the repo root (it doesn’t match `src/foo.ts`). So the anti-pattern check is currently ineffective for most repos.

### 1.3 “NO --no-verify” is declared but not enforced
`includes/CLAUDE-BASE.md` contains a strict “NO `--no-verify`” policy, but `hooks/hooks.json` does not enforce it deterministically.

### 1.4 `dist/` / generated files can trigger validation
Because this plugin itself requires committing `dist/`, any build step can create diffs in generated JS that unintentionally trigger JS lint checks.

### 1.5 Hooks are leaving leverage on the table
Hooks receive structured JSON on stdin. Today, `post-edit-check.sh` ignores stdin, which forces it to infer “what changed” via git. Using stdin gives a **precise file_path** for Write/Edit events and solves multiple issues above.

---

## 2) Proposed new architecture

### 2.1 Add rule templates (project-installable)
Add a `templates/claude/rules/` directory in the plugin with modular rule files. Then add a command to install them into any repo (`/bluera-base:install-rules`).

This bridges the gap that rules are not “plugin-scoped” by default: the plugin *ships templates + an installer*.

### 2.2 Update hooks to:
- enforce “NO --no-verify” deterministically (PreToolUse on Bash)
- rely on stdin JSON for Write/Edit validation
- skip generated outputs
- apply timeouts to heavy checks
- keep Stop and Notification hooks robust

---

## 3) File-by-file spec

## 3.1 `.claude-plugin/plugin.json`

### Change
- Bump version.
- Optional: add `homepage` for discoverability.

### Patch (example)
```json
{
  "name": "bluera-base",
  "version": "0.2.0",
  "description": "Shared development conventions for Bluera projects - hooks, skills, CLAUDE.md patterns",
  "author": { "name": "Bluera", "email": "contact@bluera.ai" },
  "homepage": "https://github.com/blueraai/bluera-base",
  "repository": "https://github.com/blueraai/bluera-base",
  "license": "MIT",
  "keywords": ["conventions", "hooks", "skills", "claude-code", "development"]
}
```

Notes:
- You **do not need** to add `hooks`, `commands`, `skills` path fields if you use standard directories (they’ll auto-load). Add them only if you intentionally deviate.

---

## 3.2 `hooks/hooks.json`

### Changes
1. **PreToolUse**: replace the single-purpose script (`block-manual-release.sh`) with a consolidated guard:
   - block `git commit --no-verify` (hard block)
   - block manual release/tag/publish commands (hard block → instruct to use `/release`)
   - optionally: block force pushes (optional, if you want)
2. **PostToolUse**: keep but add `timeout` and ensure the validator reads stdin JSON for the file path.
3. **Notification**: move the inline `osascript` to a script so you can:
   - add Linux/Windows fallbacks
   - include notification type/message
   - tolerate missing fields (there are known bugs where `notification_type` may be absent)
4. **Stop**: remove `matcher` (Stop doesn’t need it) and ensure `milhouse-stop.sh` uses `stop_hook_active`.

### Proposed `hooks/hooks.json`
```json
{
  "description": "bluera-base shared hooks - validation, notifications, release protection, and milhouse loop",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/pretool-guard.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/post-edit-check.sh",
            "statusMessage": "Validating changes...",
            "timeout": 180
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "permission_prompt|idle_prompt|elicitation_dialog",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/notify.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/milhouse-stop.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

---

## 3.3 NEW: `hooks/pretool-guard.sh`

Create a new script that reads stdin JSON (the hook event payload) and blocks unsafe Bash commands.

### Behavior
- If tool is not Bash → no-op.
- If command contains `git commit` and `--no-verify` → exit **2** with message.
- If command appears to be a manual release/publish:
  - `git tag`
  - `git push --tags`
  - `gh release create`
  - `npm version`, `pnpm version`, `yarn version`
  - `npm publish`, `pnpm publish`, `yarn npm publish`
  - optionally `cargo publish`
  → exit **2** with message “Use /release”.

### Implementation (copy/paste)
```bash
#!/usr/bin/env bash
set -euo pipefail

# Read hook JSON from stdin
INPUT="$(cat || true)"
[ -z "${INPUT}" ] && exit 0

# Prefer jq; fallback to python
json_get() {
  local expr="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT" | jq -r "$expr"
  else
    python3 - <<PY
import json,sys
data=json.loads(sys.stdin.read())
def get(path):
  cur=data
  for p in path.split('.'):
    if p=='':
      continue
    cur = cur.get(p) if isinstance(cur, dict) else None
    if cur is None:
      return None
  return cur
val=get("${expr#'.'}")
print("" if val is None else val)
PY
  fi
}

TOOL_NAME="$(json_get '.tool_name')"
CMD="$(json_get '.tool_input.command')"

# Only guard Bash tool calls
[ "$TOOL_NAME" = "Bash" ] || exit 0
[ -n "$CMD" ] || exit 0

# ---- Hard blocks ----

# 1) Block --no-verify on commit
if echo "$CMD" | grep -Eqi '\bgit\s+commit\b' && echo "$CMD" | grep -Eqi '\s--no-verify\b'; then
  echo "Blocked: git commit --no-verify is forbidden. Fix pre-commit failures; do not bypass." >&2
  exit 2
fi

# 2) Block manual release / tagging / publishing
if echo "$CMD" | grep -Eqi '\bgit\s+tag\b|\bgit\s+push\b.*\s--tags\b|\bgh\s+release\s+create\b|\bnpm\s+version\b|\bpnpm\s+version\b|\byarn\s+version\b|\bnpm\s+publish\b|\bpnpm\s+publish\b|\byarn\s+npm\s+publish\b|\bcargo\s+publish\b'; then
  echo "Blocked: manual release/publish detected. Use /release workflow." >&2
  exit 2
fi

exit 0
```

Notes:
- `exit 2` is the “blocking” codepath for PreToolUse. Keep messages short and specific.
- Make the script executable: `chmod +x hooks/pretool-guard.sh`.

---

## 3.4 `hooks/post-edit-check.sh` (major refactor)

### Summary of required changes
1. **Read stdin JSON** and pull `tool_name` + `tool_input.file_path`.
2. Use file extension and path to decide which checks to run.
3. **Skip generated paths** (`dist/`, `target/`, `node_modules/`, `.venv/`, etc.).
4. Fix anti-pattern detection to:
   - work on subdirectories
   - work on untracked files
   - prefer added-lines-only for tracked files
5. Add a **lock** to avoid concurrent runs (PostToolUse can trigger frequently).

### Proposed behavior
- On every Write/Edit, validate the single touched file:
  - JS/TS: eslint (fix + check) on that file, then optional `tsc --noEmit` (rate-limited)
  - Python: ruff/flake8 on that file, optional mypy (rate-limited)
  - Rust: `cargo fmt` (optional) + `cargo clippy`/`cargo check` (rate-limited)
  - Go: `gofmt` (file) + `golangci-lint`/`go vet` (rate-limited)
- Always run anti-pattern scan for the touched file (added-lines for tracked; full file for new).

### Implementation notes
- Use **rate limiting** for heavy “project-wide” checks:
  - keep a timestamp file in `"$TMPDIR"` (or `/tmp`)
  - don’t re-run `tsc` / `cargo check` / `golangci-lint` more than once every N seconds
- Prefer local binaries when available:
  - `./node_modules/.bin/eslint`, `./node_modules/.bin/tsc`
- Avoid `xargs` on unknown filenames; pass the file path as a single quoted argument.

### Suggested refactor (skeleton)
This is a skeleton to guide the rewrite; you can keep your existing check logic but change the “what changed” detection and anti-pattern scan.

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

# ---- single-instance lock ----
LOCK_FILE="${TMPDIR:-/tmp}/bluera-post-edit-check.lock"
if command -v flock >/dev/null 2>&1; then
  exec 9>"$LOCK_FILE"
  flock -n 9 || exit 0
else
  mkdir "$LOCK_FILE".d 2>/dev/null || exit 0
  trap 'rmdir "$LOCK_FILE".d >/dev/null 2>&1 || true' EXIT
fi

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

# Extract tool + file path
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // ""')"
  FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')"
else
  TOOL_NAME=""
  FILE_PATH=""
fi

# Only respond to Write/Edit
case "$TOOL_NAME" in
  Write|Edit) ;;
  *) exit 0 ;;
esac

# Normalize file path to repo-relative if possible
# (optional: if FILE_PATH is absolute, strip project dir prefix)
REL="$FILE_PATH"
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  REL="${REL#"$CLAUDE_PROJECT_DIR"/}"
fi

# Skip generated/vendor paths
case "$REL" in
  dist/*|target/*|node_modules/*|.venv/*|__pycache__/*) exit 0 ;;
esac

# Dispatch by extension
case "$REL" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
    # eslint on file, tsc rate-limited
    ;;
  *.py|*.pyi)
    # ruff/flake8 on file, mypy rate-limited
    ;;
  *.rs)
    # cargo fmt, clippy/check rate-limited
    ;;
  *.go)
    # gofmt file, golangci-lint/go vet rate-limited
    ;;
  *)
    # still run anti-pattern scan for text-ish files? optional
    ;;
esac

# Anti-pattern scan for this file (tracked added lines vs full file if untracked)
# If detected: print message to stderr, exit 2
```

### Anti-pattern scan implementation (recommended)
Add a helper:

```bash
anti_pattern_scan_file() {
  local f="$1"

  # Only scan files that exist
  [ -f "$f" ] || return 0

  local re='\b(fallback|deprecated|legacy|backward compatibility)\b'

  # If inside git repo and file is tracked, scan added lines only
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git ls-files --error-unmatch "$f" >/dev/null 2>&1; then
      local added
      added="$(git diff -U0 -- "$f" | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
      if echo "$added" | grep -Eiq "$re"; then
        echo "Anti-pattern detected in added lines ($f): fallback/deprecated/legacy/backward compatibility" >&2
        echo "$added" | grep -Ei "$re" | head -20 >&2
        return 2
      fi
      return 0
    fi
  fi

  # Fallback: untracked or non-git → scan full file
  if grep -Eiq "$re" "$f"; then
    echo "Anti-pattern detected in file ($f): fallback/deprecated/legacy/backward compatibility" >&2
    grep -Ein "$re" "$f" | head -20 >&2
    return 2
  fi

  return 0
}
```

Then call `anti_pattern_scan_file "$REL"` at the end (or earlier).

---

## 3.5 NEW: `hooks/notify.sh` (cross-platform)

Replace the inline `osascript` with a script that:
- reads stdin JSON to get `notification_type` and `message` (if available)
- works on macOS and degrades gracefully elsewhere

Example:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

TYPE=""
MSG="Claude needs your input"

if command -v jq >/dev/null 2>&1; then
  TYPE="$(echo "$INPUT" | jq -r '.notification_type // ""')"
  MSG_IN="$(echo "$INPUT" | jq -r '.message // ""')"
  [ -n "$MSG_IN" ] && MSG="$MSG_IN"
fi

TITLE="Claude Code"
[ -n "$TYPE" ] && TITLE="Claude Code: $TYPE"

# macOS
if command -v osascript >/dev/null 2>&1; then
  osascript -e "display notification "${MSG}" with title "${TITLE}" sound name "Glass"" 2>/dev/null || true
  exit 0
fi

# Linux (best-effort)
if command -v notify-send >/dev/null 2>&1; then
  notify-send "$TITLE" "$MSG" || true
  exit 0
fi

# Windows (best-effort; only if powershell exists)
if command -v powershell.exe >/dev/null 2>&1; then
  powershell.exe -NoProfile -Command "[console]::beep(800,200)" >/dev/null 2>&1 || true
  exit 0
fi

exit 0
```

---

## 3.6 `hooks/milhouse-stop.sh` (safety hardening)

### Required check
Ensure it reads stdin JSON and checks `stop_hook_active`. If `stop_hook_active` is already true, it should avoid re-triggering a continuation loop.

Implementation approach:
- Parse stdin JSON for `stop_hook_active`
- If true → exit 0 (do nothing)
- Else apply your milhouse logic

---

## 3.7 `includes/CLAUDE-BASE.md` → convert to modular rule templates

### Goal
Keep `includes/CLAUDE-BASE.md` as a *human-maintained source of truth*, but split it into installable `.claude/rules/*.md` templates so projects don’t need to `@include` a big blob.

### Proposed split
Create templates:

1. `templates/claude/rules/00-base.md` (unconditional)
   - fail fast, strict typing, “no commented code”
2. `templates/claude/rules/anti-patterns.md` (unconditional)
   - “NO fallback/backward compat/deprecated/legacy”
3. `templates/claude/rules/git.md` (unconditional)
   - “NO --no-verify”
4. `templates/claude/rules/plugins/distribution.md` (path-scoped)
   - only applies when repo is a Claude Code plugin (e.g., `.claude-plugin/**` or `dist/**` exists)

This avoids polluting non-plugin repos with plugin-specific distribution rules.

### YAML frontmatter guidance
Always **quote** glob patterns to avoid YAML parsing edge cases:
```yaml
---
paths:
  - ".claude-plugin/**"
  - "dist/**"
---
```

---

## 4) NEW: Rule templates to add (copy/paste)

> Store these under `templates/claude/rules/...` in the plugin repository.  
> Your installer command will copy them into the target repo’s `.claude/rules/`.

### 4.1 `templates/claude/rules/00-base.md`
```md
# Bluera Base Rules (global)

- Keep changes minimal and correct; prefer small, verifiable steps.
- Fail fast: unexpected state is an error condition (throw/panic/raise).
- Delete commented-out code instead of leaving it behind.
- Prefer strict typing where supported.
```

### 4.2 `templates/claude/rules/anti-patterns.md`
```md
# Forbidden anti-patterns

Reject on sight:
- No fallback logic / graceful degradation / “just in case” defaults
- No backward-compatibility layers or shims
- No “deprecated” references lingering; delete and update callers
- No “legacy” bridges
```

### 4.3 `templates/claude/rules/git.md`
```md
# Git rules

- Never use `git commit --no-verify`. Zero exceptions.
- If hooks fail: fix the failing code/tests; do not bypass.
```

### 4.4 `templates/claude/rules/plugins/distribution.md`
```md
---
paths:
  - ".claude-plugin/**"
  - "dist/**"
---

# Claude Code plugin distribution rules

- `dist/` must be committed (plugins are cached/installed without a build step).
- After code changes: rebuild, then commit source + dist together.
```

### 4.5 Optional per-language templates
Create these only if you want more explicit guidance inside Claude’s memory.

`templates/claude/rules/languages/typescript.md`
```md
---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
---

# JS/TS rules

- Use repo lint/format tools; don’t hand-format.
- Fix lint/type errors immediately.
- Ignore generated outputs (e.g., dist/).
```

`templates/claude/rules/languages/python.md`
```md
---
paths:
  - "**/*.{py,pyi}"
---

# Python rules

- Prefer ruff where available.
- Keep type errors at zero when mypy is configured.
```

---

## 5) NEW: Installer command to add to the plugin

### Why
Rules are project/user-level. The plugin should provide a one-shot command to install rule templates into a repo.

### Add
Create `commands/install-rules.md` in the plugin.

### Behavior
When a user runs:
- `/bluera-base:install-rules`

Claude should:
1. Create `.claude/rules/` in the current repo.
2. Copy the template rule content into corresponding files.
3. Optionally create/update `.claude/CLAUDE.md` with a minimal “project specific” header (do NOT paste the full rules there).

### `commands/install-rules.md` (spec)
```md
---
description: Install Bluera base rule templates into this repo under .claude/rules/
---

# Install bluera-base rules into this repository

Perform the following steps:

1) Ensure these directories exist:
- .claude/
- .claude/rules/
- .claude/rules/plugins/
- .claude/rules/languages/

2) Create/overwrite these files with the contents specified in the bluera-base plugin templates:
- .claude/rules/00-base.md
- .claude/rules/anti-patterns.md
- .claude/rules/git.md
- .claude/rules/plugins/distribution.md
- (optional) .claude/rules/languages/typescript.md
- (optional) .claude/rules/languages/python.md

3) If .claude/CLAUDE.md does not exist, create it with:
- project-specific scripts/build/test commands only
- keep it lean

After writing, summarize what was installed and remind the user that rules auto-load.
```

> Implementation note: the command can either (a) embed the template content directly, or (b) instruct Claude to read the templates from the plugin folder and write them into the repo. Choose whichever is more reliable for Claude Code in practice.

---

## 6) Test plan / verification checklist

### 6.1 Plugin validity
- Validate manifest JSON.
- Ensure scripts are executable:
  - `chmod +x hooks/*.sh`

### 6.2 Hook behavior tests (manual)
You can simulate hook input by piping example JSON into scripts:

```bash
cat <<'JSON' | ./hooks/pretool-guard.sh
{
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": { "command": "git commit --no-verify -m \"test\"" }
}
JSON
echo $?
```

Expected: exit code `2` + stderr explaining the block.

```bash
cat <<'JSON' | ./hooks/post-edit-check.sh
{
  "hook_event_name": "PostToolUse",
  "tool_name": "Write",
  "tool_input": { "file_path": "$(pwd)/src/foo.ts" },
  "tool_response": { "success": true }
}
JSON
```

Expected: lint/type checks run for `src/foo.ts` (or no-op if tools absent).

### 6.3 Rules behavior tests
After running `/bluera-base:install-rules` in a repo:
- Verify `.claude/rules/*.md` exist
- Run `/status` or `/context` in Claude Code and confirm rules appear in loaded memory

---

## 7) Acceptance criteria

- ✅ New/untracked files are validated on first Write/Edit.
- ✅ Anti-pattern detection works in subdirectories (e.g., `src/**`).
- ✅ `git commit --no-verify` is blocked deterministically.
- ✅ Generated outputs (e.g., `dist/`) are ignored by validators.
- ✅ Rule templates exist in plugin and can be installed into a repo via a slash command.
- ✅ Stop hook avoids infinite “continue” loops by honoring `stop_hook_active`.
- ✅ Notification hook doesn’t hard-require macOS; degrades gracefully on other OSes.

---

## 8) Reference URLs (copy/paste)

```text
Claude Code docs (plugins): https://code.claude.com/docs/en/plugins
Claude Code docs (plugins reference): https://code.claude.com/docs/en/plugins-reference
Claude Code docs (hooks reference): https://code.claude.com/docs/en/hooks
Claude Code docs (memory / rules): https://code.claude.com/docs/en/memory
```
