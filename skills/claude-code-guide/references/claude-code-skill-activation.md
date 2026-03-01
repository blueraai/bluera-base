# Spec: Deterministic “100% Skill Activation” for Claude Code (Router + Injection + Enforcement)

**Document status:** Implementation-ready specification  
**Target date:** As of Feb 28, 2026  
**Audience:** Project developers implementing Claude Code hooks + skills in a repo

---

## 0) Problem statement

Claude Code “skills” are commonly **not invoked reliably** when left to the model’s autonomous decision-making. This spec defines an architecture that achieves **deterministic skill invocation** by:

1. **Routing**: deciding which skills are required for a prompt using deterministic rules (optionally with an LLM fallback).
2. **Injection**: injecting a mandatory instruction into the model context via `UserPromptSubmit`.
3. **Enforcement**: preventing real work until required skills have been invoked using `PreToolUse` (and optionally preventing “stop” with `Stop`).

### Success criterion (“100%” definition)

For any prompt where the router determines a set of required skills `R`, the system guarantees:

- Claude Code will **invoke `Skill(<name>)` for every skill in `R`** *before* it can use “real work” tools (e.g., write/edit/bash).
- If Claude attempts to proceed without invoking required skills, hooks will **block** the attempt and force remediation.

This is “100% reliable” with respect to **activation enforcement**, not with respect to **routing correctness**. Routing can still miss a needed skill if the rules do not match; that is a classifier quality problem.

---

## 1) Scope

### In scope

- Repo-local configuration for Claude Code **hooks** and **skills**.
- A deterministic router that selects required skills based on prompt text.
- A hook-based enforcement layer that blocks progress until skills are activated.
- A minimal persistent state store keyed by session ID.

### Out of scope

- Authoring the skill content itself (i.e., the contents of `SKILL.md` beyond best practices).
- Integration with external auth, secrets vaults, or non-local storage.
- Model-side guarantees outside Claude Code’s hook contract.
- Tool invocation semantics for tools not exposed by Claude Code.

---

## 2) Terms and definitions

- **Skill**: A Claude Code “skill” with frontmatter (YAML) and optional `SKILL.md`. Skills can be invoked using the `Skill(...)` tool call.
- **Router**: A deterministic selection component that decides which skills are required for a prompt.
- **Injection**: Adding mandatory instructions into model context prior to processing the user prompt (via `UserPromptSubmit`).
- **Enforcement**: Blocking tool calls (via `PreToolUse`) and optionally blocking termination (via `Stop`) until skill activations have occurred.
- **State file**: A small JSON file persisting required/activated skill lists for the current session.

---

## 3) High-level architecture

### 3.1 Components

1. **Rules file** (`.claude/skills/skill-rules.json`): Declares skills, triggers, priorities, and global requirements.
2. **Router hook** (`UserPromptSubmit`): Matches prompt → required skills. Writes state file. Injects mandatory instruction.
3. **Gate hook** (`PreToolUse`):
   - Records `Skill()` invocations.
   - Denies disallowed tools until `required` list is empty.
4. **Stop hook** (`Stop`, optional but recommended): Blocks stopping until required skills have been activated (with loop protection).
5. **(Optional) LLM fallback router**: For prompts not matched by deterministic rules; can be implemented later.

### 3.2 Data flow

```text
User prompt
  ↓
UserPromptSubmit hook (router)
  - parse prompt + rules
  - compute required skills R
  - write state {required:R, activated:[]}
  - inject “REQUIRED SKILL ACTIVATION” instruction
  ↓
Claude processes prompt, attempts tools
  ↓
PreToolUse hook (gate)
  - if tool == Skill: mark activated, remove from required
  - else if required non-empty and tool is “real work”: deny with reason
  ↓
When required is empty → allow normal tool usage
  ↓
Stop hook (optional)
  - if required non-empty and stop not already blocked: block stop with reason
```

---

## 4) Repo layout

Recommended structure (all paths relative to repo root):

```text
.claude/
  settings.json
  hooks/
    skill-router.sh
    skill-gate.sh
    skill-stop.sh
  skills/
    skill-rules.json
  .hook-state/
    required-skills-<SESSION_ID>.json   (generated)
```

Notes:

- `.claude/.hook-state/` should be gitignored.
- Hook scripts must be executable (`chmod +x`).

---

## 5) Rules file specification (`skill-rules.json`)

### 5.1 Schema (v1.0)

```jsonc
{
  "version": "1.0",
  "skills": {
    "<skill-name>": {
      "priority": "high" | "medium" | "low",
      "promptTriggers": {
        "keywords": ["string", "..."],            // case-insensitive substring match
        "regex": ["pattern", "..."]               // optional; evaluated case-insensitively
      },
      "maxPerTurn": 1                              // optional; future use
    }
  },
  "alwaysConsider": ["<skill-name>", "..."],       // always required every turn (or always-eval set)
  "allowToolsBeforeActivation": ["Read", "Grep"]    // allowlisted tools even before activation
}
```

### 5.2 Matching semantics

- The router lowercases the prompt.
- `keywords` are matched by substring containment.
- `regex` patterns are optional; they can catch structured patterns (e.g., filenames, command-like prompts).
- All matches union together with `alwaysConsider`.
- Output list must be **unique** and **stable-ordered** (e.g., sorted) to minimize diffs.

### 5.3 Routing policy recommendations

- Keep triggers **specific**. Over-triggering leads to excess context.
- Prefer keywords that reflect how humans ask (“schema validate”, “migrate DB”, “k8s”, “helm”, etc.).
- Maintain a **small** `alwaysConsider` list; reserve it for non-negotiable skills (e.g., security policy, repo conventions).

---

## 6) Hook contracts and behavior

This architecture assumes Claude Code provides:

- A `UserPromptSubmit` hook with access to the prompt and the ability to inject `additionalContext`.
- A `PreToolUse` hook that can **deny** tool execution and return a reason (fed back to Claude).
- A `Stop` hook that can **block** stopping and provide a reason, with a `stop_hook_active` flag to prevent loops.

### 6.1 `UserPromptSubmit` (router) responsibilities

- Parse hook input JSON, extract:
  - `session_id`
  - `prompt`
  - `cwd` (repo root)
- Load `.claude/skills/skill-rules.json` if present.
- Determine required skills list `R`.
- Write state file: `.claude/.hook-state/required-skills-<session_id>.json`.
- Emit JSON on stdout that injects context:

```jsonc
{
  "hookSpecificOutput": {
    "hookEventName": "UserPromptSubmit",
    "additionalContext": "INSTRUCTION: REQUIRED SKILL ACTIVATION ..."
  }
}
```

### 6.2 `PreToolUse` (gate) responsibilities

- Read current state file (if exists).
- If tool is `Skill`:
  - Extract the skill name from the tool input payload.
  - Move it from `required` → `activated`.
  - Persist state atomically.
- Else if there are remaining required skills:
  - If tool name is in `allowToolsBeforeActivation`, allow.
  - Otherwise **deny** with a reason instructing to invoke remaining skills.

Denial output format:

```jsonc
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "You must first call Skill() for: ..."
  }
}
```

### 6.3 `Stop` (optional) responsibilities

- If required list is non-empty:
  - If `stop_hook_active` is true, allow stopping (loop protection).
  - Else block stopping with a reason listing remaining skills.

---

## 7) State file specification

### 7.1 Location

`.claude/.hook-state/required-skills-<SESSION_ID>.json`

### 7.2 Content

```json
{
  "required": ["skill-a", "skill-b"],
  "activated": ["skill-x"]
}
```

### 7.3 Atomic updates

All writes should be atomic (write temp file then `mv`) to avoid corruption if the process is interrupted.

---

## 8) Tool gating policy

### 8.1 Default policy

- Allow `Skill` always.
- Allow certain read-only tools before activation (configurable), e.g.:
  - `Read`, `Grep`, `Glob`
- Deny “real work” tools until required skills are activated, e.g.:
  - `Write`, `Edit`, `Bash`, `ApplyPatch` (names depend on Claude Code tool naming)

### 8.2 Rationale

This ensures that once the router declares required skills, Claude cannot bypass activation and immediately modify code or run commands. Instead it must invoke the required skills first.

---

## 9) Skill authoring requirements (minimal)

Each skill must have:

- A **unique name** (folder name)
- A frontmatter `description` that is:
  - Short (1–3 sentences)
  - Concrete (keywords that resemble user prompts)
  - Non-overlapping with other skills

Recommendation: Avoid setting `disable-model-invocation: true` for skills that must be invoked automatically.

---

## 10) Implementation details (reference shell scripts)

This section provides a concrete, working baseline. Developers may refine field extraction to match Claude Code’s actual hook payloads.

### 10.1 Router hook (`.claude/hooks/skill-router.sh`)

Create with:

```bash
mkdir -p .claude/hooks .claude/.hook-state .claude/skills
vi .claude/hooks/skill-router.sh
chmod +x .claude/hooks/skill-router.sh
```

Baseline implementation:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id')"
PROMPT_RAW="$(echo "$INPUT" | jq -r '.prompt')"
PROMPT="$(printf '%s' "$PROMPT_RAW" | tr '[:upper:]' '[:lower:]')"
PROJECT_DIR="$(echo "$INPUT" | jq -r '.cwd')"

RULES_FILE="$PROJECT_DIR/.claude/skills/skill-rules.json"
STATE_FILE="$PROJECT_DIR/.claude/.hook-state/required-skills-$SESSION_ID.json"

if [[ ! -f "$RULES_FILE" ]]; then
  exit 0
fi

MATCHED="$(jq -r --arg p "$PROMPT" '
  .skills
  | to_entries[]
  | select(.value.promptTriggers.keywords? != null)
  | select([.value.promptTriggers.keywords[] | ascii_downcase] | any($p | contains(.)))
  | .key
' "$RULES_FILE" | sort -u)"

ALWAYS="$(jq -r '.alwaysConsider[]? // empty' "$RULES_FILE" | sort -u)"

REQ_SKILLS="$(printf "%s\n%s\n" "$MATCHED" "$ALWAYS" | awk 'NF' | sort -u)"

jq -n --argjson skills "$(printf '%s\n' "$REQ_SKILLS" | jq -R -s 'split("\n")|map(select(length>0))')" \
  '{required:$skills, activated:[]}' > "$STATE_FILE"

INSTRUCTION="$(cat <<EOF
INSTRUCTION: REQUIRED SKILL ACTIVATION
Required skills for this turn: $(printf '%s' "$REQ_SKILLS" | paste -sd, -)

Before doing ANY implementation:
1) Call Skill(<name>) for EACH required skill above.
2) Only after all required skills are loaded, proceed.
EOF
)"

jq -n --arg ac "$INSTRUCTION" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$ac}}'
```

### 10.2 Gate hook (`.claude/hooks/skill-gate.sh`)

Create with:

```bash
vi .claude/hooks/skill-gate.sh
chmod +x .claude/hooks/skill-gate.sh
```

Baseline:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
PROJECT_DIR="$(echo "$INPUT" | jq -r '.cwd')"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id')"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name')"
STATE_FILE="$PROJECT_DIR/.claude/.hook-state/required-skills-$SESSION_ID.json"

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

REQ_COUNT="$(jq '.required | length' "$STATE_FILE")"
if [[ "$REQ_COUNT" -eq 0 ]]; then
  exit 0
fi

if [[ "$TOOL_NAME" == "Skill" ]]; then
  SKILL_NAME="$(echo "$INPUT" | jq -r '.tool_input.name // .tool_input.skill // .tool_input.skill_name // .tool_input.skillName // empty')"
  if [[ -n "$SKILL_NAME" ]]; then
    tmp="$(mktemp)"
    jq --arg s "$SKILL_NAME" '
      .activated += [$s] |
      .required = (.required | map(select(. != $s)) | unique) |
      .activated |= unique
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  fi
  exit 0
fi

# Optional allowlist (can also read from rules file)
if [[ "$TOOL_NAME" == "Read" || "$TOOL_NAME" == "Grep" || "$TOOL_NAME" == "Glob" ]]; then
  exit 0
fi

REMAINING="$(jq -r '.required | join(", ")' "$STATE_FILE")"

jq -n --arg remaining "$REMAINING" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: ("You must first call Skill() for: " + $remaining)
  }
}'
```

### 10.3 Stop hook (`.claude/hooks/skill-stop.sh`)

Create with:

```bash
vi .claude/hooks/skill-stop.sh
chmod +x .claude/hooks/skill-stop.sh
```

Baseline:

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
PROJECT_DIR="$(echo "$INPUT" | jq -r '.cwd')"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id')"
STOP_ACTIVE="$(echo "$INPUT" | jq -r '.stop_hook_active')"
STATE_FILE="$PROJECT_DIR/.claude/.hook-state/required-skills-$SESSION_ID.json"

if [[ "$STOP_ACTIVE" == "true" ]]; then
  exit 0
fi

if [[ ! -f "$STATE_FILE" ]]; then
  exit 0
fi

REQ_COUNT="$(jq '.required | length' "$STATE_FILE")"
if [[ "$REQ_COUNT" -eq 0 ]]; then
  exit 0
fi

REMAINING="$(jq -r '.required | join(", ")' "$STATE_FILE")"
jq -n --arg remaining "$REMAINING" '{
  decision: "block",
  reason: ("You have not activated required skills yet. Call Skill() for: " + $remaining + " then continue.")
}'
```

---

## 11) Claude Code settings (`.claude/settings.json`)

Create/edit with:

```bash
vi .claude/settings.json
```

Minimal configuration:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/skill-router.sh" } ] }
    ],
    "PreToolUse": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/skill-gate.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": ".claude/hooks/skill-stop.sh" } ] }
    ]
  }
}
```

---

## 12) Logging and observability (recommended)

Add lightweight logs to each hook:

- Router: matched skills, alwaysConsider list, final required list, state file path.
- Gate: tool names denied/allowed, remaining skills.
- Stop: remaining skills at block time.

Implementation options:

- Write to `.claude/.hook-state/hook.log` with timestamps.
- Emit structured logs (JSON lines) for later parsing.

Avoid logging sensitive prompt contents if the repo may be shared.

---

## 13) Testing strategy

### 13.1 Unit tests (router)

- Given a prompt string, assert expected required skill set.
- Include tricky cases: capitalization, punctuation, overlapping keywords, empty prompt.

### 13.2 Integration tests (hooks)

Simulate hook inputs by feeding JSON to scripts and validating stdout JSON fields:

- Router writes state file and outputs `additionalContext`.
- Gate denies “Write” until Skill calls are recorded.
- Gate allows “Read/Grep” before activation (if allowlisted).
- Stop blocks once, then allows when `stop_hook_active=true`.

### 13.3 Behavioral tests (end-to-end)

- A fixed suite of prompts with expected `R` sets.
- Run Claude Code in a controlled environment (CI) and verify:
  - For each prompt, `Skill()` calls happen prior to any write/edit command.
  - No tool calls are permitted before activation besides allowlisted ones.

Define “pass” via tool transcript parsing.

---

## 14) Edge cases and mitigations

1. **Router requires a skill that does not exist**
   - Mitigation: validate rule keys against `.claude/skills/*` at router time and drop unknown skills with a warning.

2. **Skill tool input shape differs**
   - Mitigation: update extraction logic in `skill-gate.sh` to match actual payload fields; log raw tool input keys during development.

3. **Over-triggering creates many required skills**
   - Mitigation: add a cap (e.g., max 3 skills) and choose highest `priority` first.

4. **Multiple prompts in same session**
   - Mitigation: state file is session-scoped; router overwrites required list on each prompt submit. If Claude Code uses distinct `session_id` per prompt, this is already safe.

5. **Stop hook infinite loop**
   - Mitigation: honor `stop_hook_active` and allow stop on subsequent invocation.

---

## 15) Future enhancements (optional)

- **LLM fallback routing** for unmatched prompts:
  - If deterministic rules return empty (or ambiguous), call a cheap model to select skill names.
  - Store the selection in the same state file; enforcement remains identical.

- **Telemetry dashboards**:
  - Track: router hit rate, activation latency (# tool calls before all skills activated), denial counts.

- **Per-skill tool allowlists**:
  - Restrict what tools may be used while certain skills are active (defense-in-depth).

---

## 16) Acceptance checklist

- [ ] `.claude/skills/skill-rules.json` present and valid JSON
- [ ] Hook scripts exist, are executable, and use `jq`
- [ ] `.claude/settings.json` registers hooks
- [ ] `.claude/.hook-state/` is gitignored
- [ ] For prompts requiring skills, Claude cannot `Write/Edit/Bash` before `Skill()` calls
- [ ] Stop is blocked once if required skills remain (optional)
- [ ] Logs confirm required list, activation events, and denials

---

## Appendix A: Minimal example `skill-rules.json`

```json
{
  "version": "1.0",
  "skills": {
    "security-guidelines": {
      "priority": "high",
      "promptTriggers": { "keywords": ["auth", "crypto", "jwt", "oauth", "secret", "vuln"] }
    },
    "react-patterns": {
      "priority": "medium",
      "promptTriggers": { "keywords": ["react", "next.js", "component", "hook", "useeffect"] }
    }
  },
  "alwaysConsider": ["security-guidelines"],
  "allowToolsBeforeActivation": ["Read", "Grep", "Glob"]
}
```
