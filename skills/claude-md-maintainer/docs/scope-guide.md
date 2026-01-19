# What Goes Where

## Scope Decision Matrix

| Content Type | Location | Why |
|--------------|----------|-----|
| Always-true repo invariants | Root `CLAUDE.md` | High leverage, always loaded |
| Core commands (build/test/lint) | Root `CLAUDE.md` | Saves repeated searches |
| Topic conventions (testing, style) | `.claude/rules/<topic>.md` | Modular, on-demand |
| Path-specific rules | `.claude/rules/` with `paths:` | Avoids root bloat |
| Service/module rules | `services/<name>/CLAUDE.md` | On-demand load |
| Personal preferences | `~/.claude/CLAUDE.md` | Global, all projects |
| Machine-specific config | `CLAUDE.local.md` | Gitignored, local only |

## Standard Repo Layout

```text
repo/
  CLAUDE.md                    # root memory (required)
  CLAUDE.local.md              # personal notes (gitignored)
  .claude/
    rules/
      testing.md               # testing conventions
      security.md              # security requirements
```

## Monorepo Layout

```text
monorepo/
  CLAUDE.md                    # global, cross-cutting
  CLAUDE.local.md              # personal notes
  .claude/
    rules/                     # shared rules
  services/
    billing/
      CLAUDE.md                # billing-only context
    search/
      CLAUDE.md                # search-only context
    auth/
      CLAUDE.md                # auth-only context
```

## Path-Scoped Rules

Use `paths:` frontmatter to limit when rules load:

```markdown
---
paths:
  - "services/billing/**"
---

# Billing Service Rules

- Never run migrations automatically
- Use ./scripts/billing-test.sh before marking done
- All money amounts use decimal.js
```

## What NOT to Put in CLAUDE.md

| Content | Where It Belongs |
|---------|------------------|
| Installation instructions | README.md |
| API documentation | Docs site or README.md |
| Change history | CHANGELOG.md |
| Contribution guidelines | CONTRIBUTING.md |
| Detailed architecture | `agent_docs/architecture.md` |
| Test patterns | `agent_docs/testing.md` or `.claude/rules/testing.md` |

## Decision Flow

```text
Is this about HOW Claude should behave?
├── No → README.md, docs/, or agent_docs/
└── Yes → Is it always relevant?
    ├── Yes → Root CLAUDE.md
    └── No → Is it path-specific?
        ├── Yes → .claude/rules/ with paths:
        └── No → Is it a full module?
            ├── Yes → module/CLAUDE.md
            └── No → .claude/rules/<topic>.md
```
