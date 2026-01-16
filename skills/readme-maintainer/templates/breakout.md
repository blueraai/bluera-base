# Breakout Destinations Reference

Standard destinations for breaking out large README content.

## Root-Level Files (GitHub Special)

GitHub gives these files special UI treatment. Always place at repository root.

| File | Content | GitHub Behavior |
|------|---------|-----------------|
| CONTRIBUTING.md | How to contribute, dev setup, coding standards | Linked in PR creation UI |
| CHANGELOG.md | Version history, release notes | Displayed on release pages |
| SECURITY.md | Vulnerability reporting process | Shown in security tab |
| CODE_OF_CONDUCT.md | Community standards | Shown in community profile |

## docs/ Folder Structure

For extended documentation that doesn't need GitHub special treatment:

```
docs/
├── README.md              # Optional: docs index/navigation
├── getting-started.md     # Extended installation + first steps
├── api-reference.md       # Complete API documentation
├── configuration.md       # All config options with examples
├── architecture.md        # Design decisions, diagrams
├── troubleshooting.md     # FAQ, common issues, solutions
└── examples/              # Extended examples by use case
    ├── basic.md
    └── advanced.md
```

## File Naming Conventions

| Type | Naming | Example |
|------|--------|---------|
| GitHub special | UPPERCASE.md | CONTRIBUTING.md |
| docs/ files | lowercase-kebab.md | getting-started.md |
| Nested docs | folder/topic.md | examples/basic.md |

## Link Format in README

After breaking out content, add a Documentation section:

```markdown
## Documentation

| Guide | Description |
|-------|-------------|
| [Getting Started](docs/getting-started.md) | Installation and first steps |
| [API Reference](docs/api-reference.md) | Complete API documentation |
| [Configuration](docs/configuration.md) | All configuration options |
| [Architecture](docs/architecture.md) | Design and internals |
| [Troubleshooting](docs/troubleshooting.md) | FAQ and common issues |
| [Contributing](CONTRIBUTING.md) | How to contribute |
| [Changelog](CHANGELOG.md) | Version history |
```

## Broken-Out File Header Template

Each broken-out file should start with a link back to README:

```markdown
# [Section Title]

> Part of [Project Name](../README.md) documentation.

[Content moved from README...]
```

## When NOT to Break Out

Keep content in README if:
- Section is < 50 lines
- It's essential for first-time users
- Breaking it out would leave README too sparse
- The project is small/simple (< 300 lines total)

## Checklist After Breakout

- [ ] All broken-out files created
- [ ] README updated with links table
- [ ] All relative links work (test by clicking in GitHub)
- [ ] No orphaned content (everything linked from somewhere)
- [ ] README is now 200-350 lines
- [ ] Table of Contents updated if present
