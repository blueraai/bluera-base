# Git Rules

Commit and version control standards.

## Absolute Rules

- **NEVER use `--no-verify`** on git commits
  - Pre-commit hooks exist for a reason
  - If hooks fail, fix the underlying issue
  - Zero exceptions to this rule

## Commit Standards

- Atomic commits: one logical change per commit
- Use conventional commit format: `type(scope): description`
- Don't amend commits that have been pushed
- Don't force push to shared branches
