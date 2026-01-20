# Skills

Bluera Base provides reusable skill documentation that guides Claude Code through complex workflows.

## Skill Summary

| Skill | Purpose |
|-------|---------|
| `auto-learn` | Automatic learning from session patterns |
| `atomic-commits` | Guidelines for logical commit grouping with README/CLAUDE.md awareness |
| `claude-cleaner` | Diagnose slow Claude Code startup and guide cleanup |
| `claude-md-maintainer` | CLAUDE.md validation with progressive disclosure templates |
| `code-review-repo` | Multi-agent codebase review with confidence scoring |
| `dry-refactor` | Language-specific guidance for DRY refactoring |
| `large-file-refactor` | Analyze and split large files when token limits exceeded |
| `milhouse` | Iterative development loop documentation |
| `readme-maintainer` | README.md formatting with tables, badges, diagrams, collapsible sections |
| `release` | Release workflow with multi-language version bumping |
| `repo-hardening` | Language-specific tooling for linting, formatting, hooks, and coverage |
| `statusline` | Status line configuration with presets |

---

## code-review-repo

Launches 5 parallel agents to independently review your codebase:

1. **CLAUDE.md compliance** - Check code follows all CLAUDE.md guidelines
2. **Bug scan** - Look for obvious bugs, error handling issues
3. **Git history context** - Use blame/history to identify patterns
4. **Previous PR comments** - Check closed PRs for applicable feedback
5. **Code comment compliance** - Ensure TODO/FIXME notes are addressed

Each issue gets a confidence score (0-100). Only issues scoring >= 80 are reported.

### Usage

```bash
/bluera-base:code-review
```

---

## release

The `/bluera-base:release` command provides a standardized release workflow.

### Workflow

```mermaid
flowchart LR
    A[/release] --> B{Clean?}
    B -->|No| C[Abort]
    B -->|Yes| D[Analyze]
    D --> E{Type?}
    E -->|fix| F[patch]
    E -->|feat| G[minor]
    E -->|BREAKING| H[major]
    F --> I[Bump]
    G --> I
    H --> I
    I --> J[Push]

    style A fill:#6366f1,color:#fff
    style C fill:#dc2626,color:#fff
    style J fill:#16a34a,color:#fff
```

### Version Bumping

| Commit Type | Version Bump | Example |
|-------------|--------------|---------|
| `fix:` | patch (0.0.x) | Bug fixes |
| `feat:` | minor (0.x.0) | New features |
| `feat!:` / `BREAKING CHANGE:` | major (x.0.0) | Breaking changes |

### Version Tool Detection Order

1. **Makefile:** `make release:patch`, `make version:patch`, or `make release BUMP=patch`
2. **JS/TS scripts:** `bun/pnpm/yarn/npm run version:patch` or `release:patch`
3. **Python Poetry:** `poetry version patch`
4. **Python Hatch:** `hatch version patch`
5. **Rust:** `cargo release patch` (if cargo-release installed)
6. **Go:** git tag-based versioning
7. **JS/TS fallback:** `npm version patch`

The `block-manual-release.sh` hook prevents bypassing this workflow by blocking direct version/release commands.

---

## milhouse

The milhouse loop is an iterative development pattern for complex tasks.

### Workflow

```mermaid
flowchart LR
    A[/milhouse] --> B[Load]
    B --> C[Work]
    C --> D{Done?}
    D -->|No| E[Intercept]
    E --> C
    D -->|Yes| F[Exit]

    style A fill:#6366f1,color:#fff
    style F fill:#16a34a,color:#fff
```

### Usage

```bash
# File-based prompt
/bluera-base:milhouse-loop .claude/prompts/task.md --max-iterations 10 --promise "FEATURE DONE"

# Inline prompt
/bluera-base:milhouse-loop --inline "Build the feature" --max-iterations 10
```

### Options

| Option | Description |
|--------|-------------|
| `--inline "prompt"` | Use inline prompt instead of file |
| `--max-iterations N` | Maximum iterations (default: unlimited) |
| `--promise "text"` | Completion promise (default: "TASK COMPLETE") |
| `--gate "cmd"` | Command that must pass before exit (repeatable) |
| `--stuck-limit N` | Stop after N identical failures (default: 3, 0=off) |
| `--init-harness` | Create plan.md and activity.md for context hygiene |

### Exit Conditions

| Condition | What Happens |
|-----------|--------------|
| `<promise>TEXT</promise>` as last line | Loop exits successfully |
| Max iterations reached | Loop exits with warning |
| `/bluera-base:cancel-milhouse` | Loop cancelled |

---

## atomic-commits

Guidelines for creating well-organized commits:

- Group related changes into single commits
- Separate unrelated changes into distinct commits
- Check if README.md or CLAUDE.md need updates when changing functionality
- Use conventional commit format: `type(scope): description`

---

## claude-md-maintainer

Validates and maintains CLAUDE.md files with:

- Progressive disclosure structure (summary → details)
- Consistent section ordering
- Proper @include syntax
- ALWAYS/NEVER rule formatting

---

## readme-maintainer

Formats README.md files using GitHub advanced features:

- Tables for structured data
- Mermaid diagrams for workflows
- Collapsible sections for long content
- Badges for status indicators

---

## dry-refactor

Language-specific guidance for eliminating duplicate code:

- Identifies common patterns across files
- Suggests extraction into shared utilities
- Provides refactoring strategies per language

---

## large-file-refactor

Helps when files exceed Claude Code's token limits:

- Analyzes file structure
- Suggests logical split points
- Provides migration strategy

---

## repo-hardening

Sets up code quality tooling for 13 languages:

- Linting (ESLint, ruff, clippy, etc.)
- Formatting (Prettier, rustfmt, gofmt, etc.)
- Type checking (TypeScript, mypy, etc.)
- Test coverage (c8, pytest-cov, tarpaulin, etc.)

See [Supported Languages](../README.md#supported-languages) for the full matrix.

---

## statusline

Configures Claude Code's terminal status line with:

- Preset configurations (minimal, informative, developer, system, bluera)
- Custom format strings
