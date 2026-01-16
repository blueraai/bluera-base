# THIS IS CLAUDE.md - YOUR MEMORY FILE

**STOP. READ THIS FIRST.**

This file is YOUR (Claude's) project memory. It is NOT user documentation. It is NOT a README.

| File | Purpose | Audience |
|------|---------|----------|
| **CLAUDE.md** (this file) | Claude Code's memory - scripts, workflows, coding rules | YOU (Claude) |
| **README.md** | User-facing documentation - features, installation, API | HUMANS (users) |

**When to update this file:** When scripts, CI/CD workflows, build processes, or coding conventions change.

**Keep this file LEAN.** This entire file loads into your context every session. Be concise. No prose. No redundancy. Every line must earn its place.

**CLAUDE.md is hierarchical.** Any subdirectory can have its own CLAUDE.md that auto-loads when you work in that directory. Use this pattern:

- **Root CLAUDE.md** (this file): Project-wide info - scripts, CI/CD, general conventions
- **Subdirectory CLAUDE.md**: Directory-specific context scoped to files below it
- Nest as deep as needed - each level inherits from parents

**Stay DRY with includes.** Use `@path/to/file` syntax to import content instead of duplicating. Not evaluated inside code blocks.

---

## Distribution Requirements (for Claude Code plugins)

**`dist/` MUST be committed to git** - This is intentional, not an oversight:

- **Claude Code plugins are copied to a cache during installation** - no build step runs
- Plugins need pre-built files ready to execute immediately

**After any code change:**

1. Run your build command
2. Commit both source AND dist/ changes together

---

## ALWAYS

- fail early and fast
  - our code is expected to *work* as-designed
    - use "throw" / "panic" / "raise" when state is unexpected or for any error condition
    - use strict typing where the language supports it
- push to main after version bump - releases happen automatically (no manual tagging needed)

---

## NEVER

### Critical Anti-Patterns

The following patterns are **strictly forbidden** and must be rejected on sight:

- **NO FALLBACK CODE** - Never write fallback logic, graceful degradation, or default behavior "just in case". Code must fail fast and explicitly when state is unexpected. If a value might be missing, that's a bug to fix, not a condition to handle gracefully.

- **NO BACKWARD COMPATIBILITY** - Never write code to maintain compatibility with deprecated APIs or old data formats. If an API is deprecated, delete it completely and update all callers. Do not create shims, wrappers, or compatibility layers.

- **NO DEPRECATED REFERENCES** - Do not reference, wrap, or call deprecated code. Delete deprecated code immediately. Do not leave deprecation markers lingering - they signal technical debt that must be eliminated.

- **NO `--no-verify` ON GIT COMMITS** - This is an **absolute rule with zero exceptions**. The `--no-verify` flag completely circumvents code protections. If pre-commit hooks fail:
  1. **Fix the failing code** - don't bypass the check
  2. **If tests are pre-existing failures** - fix those tests first, then commit
  3. **Never rationalize bypassing** - "it's unrelated to my changes" is not valid
  4. **Ask the user** if you're unsure how to proceed

- **NO COMMENTED CODE** - Delete it completely. If you need it later, use git history.

### Why These Rules Exist

This codebase is designed to **fail early and fast**. We do not tolerate:

- "It might work" code
- "Just in case" logic
- "For backward compatibility" patches
- "Gracefully handle" error paths

When code fails, it should **fail immediately** with a clear error. Users see real bugs, not silent degradation. Silent failures create debugging nightmares.
