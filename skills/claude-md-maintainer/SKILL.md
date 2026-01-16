---
name: claude-md-maintainer
description: Validate/update/create CLAUDE.md memory files with progressive disclosure and context-optimized structure
user-invocable: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(git:*), Bash(ls:*), Bash(wc:*), Bash(head:*), Bash(tail:*)
---

# CLAUDE.md Maintainer

Audit and maintain `CLAUDE.md` files across any repository. Ensures they function as Claude Code memory (not user documentation).

## Core Principle

`CLAUDE.md` is **Claude's memory**, not a README. Every line loads into context, so keep it lean and actionable.

## Algorithm

### Phase 1: Plan (read-only)

1. **Discover** existing memory files:
   - `./CLAUDE.md` or `./.claude/CLAUDE.md`
   - `./CLAUDE.local.md`
   - Nested `**/CLAUDE.md`
   - `.claude/rules/**/*.md`

2. **Validate** each against invariants (see `docs/invariants.md`)

3. **Identify** module roots (see `docs/directory-heuristics.md`)

4. **Output** proposed changes:
   - Files to update (with change summary)
   - Files to create
   - Ambiguous cases requiring human decision

### Phase 2: Apply (with confirmation)

Only after user confirms:
1. Update existing files
2. Create missing files from templates
3. Report final state

---

## Init Algorithm

For `/claude-md init` - creates new CLAUDE.md from scratch.

### Detection Priority

Check files in order (stop at first match):

```
package.json → JavaScript/TypeScript
Cargo.toml   → Rust
pyproject.toml → Python
go.mod       → Go
```

### Lockfile → Package Manager

| Lockfile | Manager |
|----------|---------|
| bun.lock / bun.lockb | bun |
| yarn.lock | yarn |
| pnpm-lock.yaml | pnpm |
| package-lock.json | npm |
| poetry.lock | poetry |
| uv.lock | uv |
| (none) | ask user |

### Script Extraction

**JavaScript/TypeScript:**
```bash
jq -r '.scripts | keys[]' package.json 2>/dev/null | head -10
```

**Python (pyproject.toml):**
```bash
grep -A 20 '^\[project.scripts\]' pyproject.toml | grep '=' | cut -d'=' -f1 | tr -d ' "'
```

**Rust/Go:** Use standard commands (cargo build/test, go build/test).

### Generated Structure

```markdown
@bluera-base/includes/CLAUDE-BASE.md

---

## Package Manager

**Use `{PM}`** - All scripts: `{PM} run <script>`

---

## Scripts

{SCRIPTS - grouped by category if many}

---

## CI/CD

{Only if .github/workflows/ or .gitlab-ci.yml exists}

---
```

### Design Principles

1. **Auto-detect over ask** - Only interview when ambiguous
2. **< 60 lines target** - Start lean, user expands later
3. **Never overwrite** - Check for existing CLAUDE.md first
4. **@include always** - Start with CLAUDE-BASE.md reference

---

## References

- **Audit Templates**: `${CLAUDE_PLUGIN_ROOT}/skills/claude-md-maintainer/templates/`
  - `root_CLAUDE.md` - Root project memory
  - `module_CLAUDE.md` - Directory-scoped memory
  - `local_CLAUDE.local.md` - Personal notes

- **Init Templates**: `${CLAUDE_PLUGIN_ROOT}/skills/claude-md-maintainer/templates/init/`
  - `js-ts.md` - JavaScript/TypeScript projects
  - `python.md` - Python projects
  - `rust.md` - Rust projects
  - `go.md` - Go projects
  - `ci-github.md` - GitHub Actions CI section
  - `ci-gitlab.md` - GitLab CI section

- **Validation rules**: `${CLAUDE_PLUGIN_ROOT}/skills/claude-md-maintainer/docs/invariants.md`

- **Directory detection**: `${CLAUDE_PLUGIN_ROOT}/skills/claude-md-maintainer/docs/directory-heuristics.md`

## Key Rules

1. **Never duplicate** - Module CLAUDE.md should not repeat root rules
2. **Prefer rules files** - Move topic-specific rules to `.claude/rules/<topic>.md`
3. **Use paths: scoping** - Rules files can use `paths:` frontmatter
4. **Hard cap** - If > 25 modules, summarize at bucket level, defer individuals

## Output Format

Report these sections:
- Memory files found
- Files to create
- Files to update (with diff summary)
- Rules files to create/update
- Follow-ups (ambiguous items)
