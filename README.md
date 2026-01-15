# Bluera Base

![License](https://img.shields.io/badge/license-MIT-green)

> **Shared development conventions for any project.** Multi-language hooks, skills, and CLAUDE.md patterns for consistent Claude Code workflows.

---

## Why Bluera Base?

When developing projects with Claude Code, you want consistent conventions across all your repos:

| Without | With Bluera Base |
|---------|------------------|
| Copy-paste hooks across projects | Install once, inherit conventions |
| Inconsistent CLAUDE.md patterns | Standardized sections via @includes |
| Duplicate code-review skills | Shared, battle-tested skill |
| Manual lint/typecheck validation | Automatic PostToolUse hooks |
| JS/TS only tooling | Multi-language support (JS/TS, Python, Rust, Go) |

**The result:** Every project gets the same quality gates and conventions, without duplication.

---

## Table of Contents

<details>
<summary>Click to expand</summary>

- [Why Bluera Base?](#why-bluera-base)
- [Installation](#installation)
- [What's Included](#whats-included)
- [Supported Languages](#supported-languages)
- [Usage](#usage)
- [Customization](#customization)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

</details>

---

## Installation

### Claude Code Plugin

```bash
# Add the Bluera marketplace (one-time setup)
/plugin marketplace add blueraai/bluera-marketplace

# Install the plugin
/plugin install bluera-base@bluera
```

### Manual (Development)

```bash
claude --plugin-dir /path/to/bluera-base
```

---

## What's Included

### Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| `post-edit-check.sh` | PostToolUse (Write/Edit) | Auto-lint, typecheck, anti-pattern detection |
| `block-manual-release.sh` | PreToolUse (Bash) | Enforces `/release` command for releases |
| `milhouse-stop.sh` | Stop | Intercepts exit to continue milhouse loop iterations |
| Notification | Notification | macOS notification on permission prompts |

<details>
<summary><b>What post-edit-check.sh does</b></summary>

On every Write/Edit operation, the hook auto-detects your project type and runs appropriate checks:

**JavaScript/TypeScript:**
- Auto-detects package manager (bun/yarn/pnpm/npm) from lockfiles
- Runs ESLint with `--fix` on modified files
- Type-checks with `tsc --noEmit` if tsconfig.json exists

**Python:**
- Runs `ruff check --fix` (preferred) or `flake8`
- Type-checks with `mypy` if pyproject.toml/mypy.ini exists

**Rust:**
- Auto-formats with `cargo fmt`
- Runs `cargo clippy` for linting
- Runs `cargo check` for compile errors

**Go:**
- Runs `golangci-lint` (preferred) or `go vet`

**All Languages:**
- Anti-pattern detection: blocks `fallback`, `deprecated`, `backward compatibility`, `legacy`

Exit code 2 blocks the operation and shows the error to Claude.

</details>

### Commands

| Command | Purpose |
|---------|---------|
| `/commit` | Create atomic, well-organized commits with documentation checks |
| `/code-review` | Run multi-agent codebase review |
| `/release` | Cut a release with conventional commits auto-detection and CI monitoring |
| `/milhouse-loop` | Start iterative development loop with configurable completion criteria |
| `/cancel-milhouse` | Cancel active milhouse loop |

### Skills

| Skill | Purpose |
|-------|---------|
| `code-review-repo` | Multi-agent codebase review with confidence scoring |
| `atomic-commits` | Guidelines for logical commit grouping with README/CLAUDE.md awareness |
| `release` | Release workflow with multi-language version bumping |
| `milhouse` | Iterative development loop documentation |

<details>
<summary><b>code-review-repo details</b></summary>

Launches 5 parallel agents to independently review your codebase:

1. **CLAUDE.md compliance** - Check code follows all CLAUDE.md guidelines
2. **Bug scan** - Look for obvious bugs, error handling issues
3. **Git history context** - Use blame/history to identify patterns
4. **PR comments** - Check closed PRs for applicable feedback
5. **Code comment compliance** - Ensure TODO/FIXME notes are addressed

Each issue gets a confidence score (0-100). Only issues scoring >= 80 are reported.

</details>

<details>
<summary><b>release skill details</b></summary>

The `/release` command provides a standardized release workflow:

1. **Pre-flight checks** - Ensures clean working directory
2. **Auto-detection** - Analyzes conventional commits to determine version bump:
   - `fix:` → patch (0.0.x)
   - `feat:` → minor (0.x.0)
   - `feat!:` or `BREAKING CHANGE:` → major (x.0.0)
3. **Version bump** - Uses language-appropriate tools:
   - JS/TS: `npm version`
   - Python: `poetry version`, `hatch version`, or `bump2version`
   - Rust: `cargo release`
   - Go: git tags
4. **CI monitoring** - Watches GitHub Actions until release completes

The `block-manual-release.sh` hook prevents bypassing this workflow by blocking direct version/release commands.

</details>

<details>
<summary><b>milhouse loop details</b></summary>

The milhouse loop is an iterative development pattern:

1. **Start with a prompt** - From file or inline
2. **Work on the task** - Claude works toward completion
3. **Loop continues** - When Claude tries to exit, the Stop hook intercepts and feeds the same prompt back
4. **Build on previous work** - Each iteration sees previous changes in files and git history
5. **Exit on completion** - Output `<promise>YOUR_PROMISE</promise>` when genuinely complete

**Usage:**
```bash
/milhouse-loop .claude/prompts/task.md --max-iterations 10 --promise "FEATURE DONE"
```

**Stopping:**
- Output `<promise>TASK COMPLETE</promise>` (or custom promise)
- Reach max iterations limit
- Run `/cancel-milhouse`

</details>

### CLAUDE.md Includes

| Include | Content |
|---------|---------|
| `CLAUDE-BASE.md` | Header/purpose, hierarchical explanation, ALWAYS/NEVER rules |

---

## Supported Languages

The `post-edit-check.sh` hook automatically detects and validates:

| Language | Detection | Linter | Type Checker |
|----------|-----------|--------|--------------|
| **JavaScript/TypeScript** | `package.json` | ESLint | tsc |
| **Python** | `pyproject.toml`, `requirements.txt`, `setup.py` | ruff / flake8 | mypy |
| **Rust** | `Cargo.toml` | cargo clippy | cargo check |
| **Go** | `go.mod` | golangci-lint / go vet | - |

### Package Manager Auto-Detection (JS/TS)

| Lockfile | Runner Used |
|----------|-------------|
| `bun.lockb` | `bun` |
| `yarn.lock` | `yarn` |
| `pnpm-lock.yaml` | `pnpm` |
| (none or `package-lock.json`) | `npx` |

---

## Usage

### Using @includes in your CLAUDE.md

Create a `CLAUDE.md` in your project root:

```markdown
@bluera-base/includes/CLAUDE-BASE.md

---

## Package Manager

**Use `bun`** - All scripts: `bun run <script>`

---

## Scripts

**Development:**
- `bun run build` - Compile TypeScript
- `bun run test:run` - Run tests once
- `bun run precommit` - Full validation

## Versioning

- `bun run version:patch` - Bump patch (0.0.x)
```

The `@bluera-base/includes/CLAUDE-BASE.md` pulls in:
- Header explaining CLAUDE.md vs README.md
- Hierarchical CLAUDE.md explanation
- ALWAYS/NEVER conventions

### Overriding Skills

To customize a skill for your project:

1. Create `.claude/skills/atomic-commits/SKILL.md` in your project
2. Copy the base skill content
3. Modify the "Trigger files" section for your project structure

Your local skill takes precedence over the plugin's version.

### Using the Settings Template

Copy `templates/settings.local.json.example` to your project's `.claude/settings.local.json`:

```bash
cp /path/to/bluera-base/templates/settings.local.json.example .claude/settings.local.json
```

This provides:
- Pre-approved commands for multiple package managers and languages
- PostToolUse hook for validation
- Notification hook for permission prompts

---

## Customization

### Project-specific trigger files

The `atomic-commits` skill has generic trigger files. Override by creating your own:

```markdown
# .claude/skills/atomic-commits/SKILL.md

**Trigger files -> check README.md:**
- `src/mcp/server.ts` - MCP tool surface
- `.claude-plugin/plugin.json` - Plugin metadata
- `commands/*.md` - Command documentation
```

### Additional hooks

Add project-specific hooks in your `.claude/settings.local.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "\"$CLAUDE_PROJECT_DIR/.claude/hooks/my-custom-hook.sh\""
        }]
      }
    ]
  }
}
```

### Extending ALWAYS/NEVER rules

Add project-specific rules after the @include:

```markdown
@bluera-base/includes/CLAUDE-BASE.md

## ALWAYS (project-specific)

* run `bun run validate:api` before modifying API endpoints

## NEVER (project-specific)

* commit directly to main without PR
```

### Architectural Constraint Skills

For projects with critical architectural requirements (e.g., "code must be database-agnostic"), use the template:

```bash
# Copy the template
cp /path/to/bluera-base/skills/architectural-constraints/SKILL.md.template \
   .claude/skills/[constraint-name]/SKILL.md

# Edit to match your constraint
```

The template provides structure for:
- What violates the constraint (with code examples)
- Where constrained code IS allowed (table format)
- The correct pattern (with code examples)
- Why it matters

### Subdirectory CLAUDE.md Files

For large projects, create directory-specific CLAUDE.md files that auto-load when working in that directory:

```bash
# Copy the template
cp /path/to/bluera-base/templates/subdirectory-CLAUDE.md.template \
   [directory]/CLAUDE.md
```

Example: A `tests/CLAUDE.md` that explains why tests are organized a certain way.

---

## Development

### Setup

```bash
git clone https://github.com/blueraai/bluera-base.git
cd bluera-base
```

No build step required - this plugin is pure markdown and shell scripts.

### Dogfooding (Testing Your Development Version)

The easiest way to test the plugin during development is to run Claude Code from the repo root:

```bash
cd /path/to/bluera-base
claude --plugin-dir .
```

This loads the current directory as a plugin. Your commands, hooks, and skills are active immediately.

**From any directory:**

```bash
claude --plugin-dir /path/to/bluera-base
```

| What to test | How |
|--------------|-----|
| Commands (`/release`, `/commit`) | `--plugin-dir .` (restart to pick up changes) |
| Hooks (post-edit, milhouse) | `--plugin-dir .` (restart to pick up changes) |
| Skills | `--plugin-dir .` (restart to pick up changes) |

Changes take effect on Claude Code restart (no reinstall needed).

### Project Structure

```
bluera-base/
├── .claude-plugin/
│   └── plugin.json               # Plugin manifest
├── commands/
│   ├── commit.md                 # /commit command
│   ├── code-review.md            # /code-review command
│   ├── release.md                # /release command
│   ├── milhouse-loop.md          # /milhouse-loop command
│   └── cancel-milhouse.md        # /cancel-milhouse command
├── hooks/
│   ├── hooks.json                # Hook definitions
│   ├── post-edit-check.sh        # Multi-language validation hook
│   ├── block-manual-release.sh   # Enforces /release workflow
│   ├── milhouse-setup.sh         # Initializes milhouse loop state
│   └── milhouse-stop.sh          # Stop hook for milhouse iterations
├── skills/
│   ├── code-review-repo/
│   │   └── SKILL.md              # Multi-agent review
│   ├── atomic-commits/
│   │   └── SKILL.md              # Commit guidelines
│   ├── release/
│   │   └── SKILL.md              # Release workflow
│   ├── milhouse/
│   │   └── SKILL.md              # Iterative development loop
│   └── architectural-constraints/
│       └── SKILL.md.template     # Template for constraint skills
├── includes/
│   └── CLAUDE-BASE.md            # @includeable sections
├── templates/
│   ├── settings.local.json.example
│   ├── CLAUDE.md.template
│   └── subdirectory-CLAUDE.md.template  # Directory-specific docs
└── README.md
```

---

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

## License

MIT - See [LICENSE](./LICENSE) for details.

---

## Support

- **Issues**: [GitHub Issues](https://github.com/blueraai/bluera-base/issues)
- **Documentation**: [Claude Code Plugins](https://code.claude.com/docs/en/plugins)
