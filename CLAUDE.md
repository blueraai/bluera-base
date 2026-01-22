@bluera-base/includes/CLAUDE-BASE.md

---

## Package Manager

**Use `bun`** - All scripts: `bun run <script>`

No build step required - this plugin uses markdown, shell scripts, and Python utilities.

---

## Scripts

**Versioning:**

- `bun run version:patch` - Bump patch version (0.0.x)
- `bun run version:minor` - Bump minor version (0.x.0)
- `bun run version:major` - Bump major version (x.0.0)
- `bun run release:patch|minor|major` - Bump, commit, and push

---

## CI/CD

Push to main triggers:

1. `ci.yml` - Validation (shellcheck on hooks)
2. `auto-release.yml` - Detects version bump, creates tag
3. `release.yml` - Creates GitHub release from tag
4. `update-marketplace.yml` - Updates bluera-marketplace

---

## Plugin Structure

```text
.claude-plugin/plugin.json  - Manifest (version synced via .versionrc.json)
commands/*.md               - Slash commands (21 total)
skills/*/SKILL.md           - Skill documentation
hooks/hooks.json            - Hook registration
hooks/*.sh                  - Hook scripts
includes/CLAUDE-BASE.md     - @includeable content
templates/                  - Templates for user projects
```

---

## Testing

Run from this directory to dogfood the plugin:

```bash
claude --plugin-dir .
```

Use `/bluera-base:test-plugin` to run the validation test suite.

---

## Version Sync

`.versionrc.json` keeps `package.json` and `.claude-plugin/plugin.json` versions in sync.
