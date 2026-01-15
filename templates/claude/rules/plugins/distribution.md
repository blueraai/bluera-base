---
paths:
  - "dist/**"
  - "plugin.json"
---

# Claude Code Plugin Distribution

Rules specific to Claude Code plugins that distribute built artifacts.

## Distribution Directory

- `dist/` directory MUST be committed (required for Claude Code plugin marketplace)
- Run build before committing changes to ensure dist/ is up-to-date
- Plugin marketplace installs from git, not from npm/package registry

## Verification

Before committing:
1. Run `bun run build` (or equivalent)
2. Verify `dist/` contains current build output
3. Check that `plugin.json` references correct dist paths
