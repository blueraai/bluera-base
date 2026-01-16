---
description: Audit + maintain CLAUDE.md memory files (validate, update, create where helpful)
argument-hint: <audit|init|learn> [options]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(git:*), Bash(ls:*), Bash(wc:*), Bash(head:*), Bash(tail:*), Bash(jq:*), AskUserQuestion
---

# CLAUDE.md Maintainer

Audit and maintain `CLAUDE.md` files in this repository. See @bluera-base/skills/claude-md-maintainer/SKILL.md for the algorithm.

## Subcommands

- **`/bluera-base:claude-md audit`** (default) - Validate existing CLAUDE.md files
- **`/bluera-base:claude-md init`** - Create new CLAUDE.md via auto-detection + interview
- **`/bluera-base:claude-md learn "<text>"`** - Add a learning to the auto-managed section

---

## Learn Workflow

When action is `learn`:

### Marker-Based Editing

Learnings are written to a marker-delimited region in `CLAUDE.local.md` (or `CLAUDE.md` with `--shared`).

**Marker format:**

```markdown
## Auto-Learned (bluera-base)
<!-- AUTO:bluera-base:learned -->
- Learning 1
- Learning 2
<!-- END:bluera-base:learned -->
```

### Algorithm

1. **Target file**: Default `CLAUDE.local.md`, or `CLAUDE.md` if `--shared` flag
2. **Find markers**: Search for `<!-- AUTO:bluera-base:learned -->` and `<!-- END:bluera-base:learned -->`
3. **Insert if missing**: Add markers at end of file with section header
4. **Dedupe**: Check if learning already exists (case-insensitive, trimmed)
5. **Validate**: Check against secrets denylist (see below)
6. **Hard cap**: Max 50 lines in auto-managed section
7. **Write**: Update only the content between markers

### Secrets Filtering

**NEVER write learnings that match:**

```regex
api[_-]?key|token|password|secret|-----BEGIN|AWS_|GITHUB_TOKEN|ANTHROPIC_API
```

If a suspected secret is detected, output a warning and do NOT write.

### Usage Examples

```bash
# Add to local memory (default)
/bluera-base:claude-md learn "Always run bun test before committing"

# Add to shared project memory
/bluera-base:claude-md learn "Use conventional commits format" --shared

# View current learnings
/bluera-base:claude-md learn --list
```

---

## Init Workflow

When action is `init`:

### Phase 1: Detection

1. **Check for existing CLAUDE.md** - If found, offer to run `audit` instead
2. **Detect project type** from files:

   | File | Project Type |
   |------|--------------|
   | `package.json` | JavaScript/TypeScript |
   | `Cargo.toml` | Rust |
   | `pyproject.toml` or `requirements.txt` | Python |
   | `go.mod` | Go |

3. **Detect package manager** from lockfiles:

   | Lockfile | Package Manager |
   |----------|-----------------|
   | `bun.lock` or `bun.lockb` | bun |
   | `yarn.lock` | yarn |
   | `pnpm-lock.yaml` | pnpm |
   | `package-lock.json` | npm |
   | `Cargo.lock` | cargo |
   | `poetry.lock` | poetry |
   | `uv.lock` | uv |

4. **Extract scripts** from config files:
   - JS/TS: `jq -r '.scripts | keys[]' package.json`
   - Python: parse `[project.scripts]` or `[tool.poetry.scripts]`
   - Rust/Go: use standard commands

5. **Detect CI** from `.github/workflows/` or `.gitlab-ci.yml`

### Phase 2: Interview

Use AskUserQuestion for:

```yaml
question: "Which package manager should be documented?"
header: "Pkg Mgr"
options: [detected options + "Other"]
```

```yaml
question: "Which scripts should be documented?"
header: "Scripts"
multiSelect: true
options: [detected scripts, limited to 6 most common]
```

```yaml
question: "Any project-specific conventions to add?"
header: "Conventions"
options:
  - label: "None"
    description: "Skip custom conventions"
  - label: "Add conventions"
    description: "I'll provide conventions in a follow-up"
```

### Phase 3: Generate

1. Start with `@bluera-base/includes/CLAUDE-BASE.md`
2. Add `## Package Manager` section with detected/confirmed manager
3. Add `## Scripts` section with selected scripts
4. Add `## CI/CD` section if workflows detected
5. Add user conventions if provided
6. Write to `./CLAUDE.md`

**Target: < 60 lines** - Keep it lean, user can expand later.

---

## Audit Workflow (default)

### Phase 1: Plan (no writes)

1. Find all memory files and rules
2. Validate against invariants
3. Identify module roots for potential CLAUDE.md
4. Output proposed plan with exact changes

### Phase 2: Apply (after confirmation)

Ask user to confirm before making any writes:

```yaml
question: "Apply the proposed changes to CLAUDE.md files?"
header: "Confirm"
options:
  - label: "Yes, apply all"
    description: "Create and update all proposed files"
  - label: "Apply updates only"
    description: "Update existing files but don't create new ones"
  - label: "No, abort"
    description: "Don't make any changes"
```

## Excluded Directories

Skip these during discovery:

- `.git/`, `node_modules/`, `.venv/`, `dist/`, `build/`, `out/`, `target/`, `vendor/`, `.idea/`, `.vscode/`

## Memory File Locations

Standard locations (check all):

- `./CLAUDE.md` - Root project memory
- `./.claude/CLAUDE.md` - Alternative root location
- `./CLAUDE.local.md` - Personal notes (gitignored)
- `**/CLAUDE.md` - Module-specific memory
- `.claude/rules/**/*.md` - Topic-specific rules

## Output

After each phase, report:

1. Files found (paths)
2. Files to create (paths)
3. Files to update (paths + change summary)
4. Follow-ups (items requiring human decision)
