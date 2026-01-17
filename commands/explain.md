---
description: Explain all bluera-base plugin functionality in human-readable format
allowed-tools: Read
argument-hint: [overview|commands|skills|hooks|config|philosophy]
---

# bluera-base Explained

A comprehensive, human-readable guide to understanding all bluera-base plugin functionality.

## Subcommands

- `/bluera-base:explain` or `/bluera-base:explain all` - Show everything
- `/bluera-base:explain overview` - What is bluera-base?
- `/bluera-base:explain commands` - All slash commands explained
- `/bluera-base:explain skills` - How skills work
- `/bluera-base:explain hooks` - Automatic behaviors
- `/bluera-base:explain config` - Configuration options
- `/bluera-base:explain philosophy` - Design principles

---

## Overview

bluera-base is a Claude Code plugin that establishes shared development conventions for your projects. It provides automated guardrails, workflow commands, and documentation standards that help teams maintain consistent code quality.

Think of it as an opinionated set of development practices that Claude Code will enforce and follow. When you install bluera-base, you get:

**Automatic protections** that run invisibly during your session - blocking risky operations, validating code changes, and detecting anti-patterns before they make it into your codebase.

**Workflow commands** that standardize common operations - creating commits with conventional format, cutting releases, reviewing code, and maintaining documentation.

**Documentation standards** through CLAUDE.md maintenance - helping you build context-aware memory files that make Claude Code more effective on your project over time.

**Iterative development** through the milhouse loop - a "keep going" workflow that feeds your prompt back after each iteration until the task is complete.

The plugin is designed around the principle that code should either work correctly or fail visibly. There's no "graceful degradation" or silent error swallowing - if something goes wrong, you'll know about it immediately.

---

## How It Works

When you start a Claude Code session with bluera-base installed, several things happen automatically:

**Session Start**: The plugin initializes its state directory (`.bluera/bluera-base/`), verifies that required tools like `jq` are available, and injects any saved context into your session.

**During Your Work**: As you use Claude Code, hooks monitor your actions:

- When you run bash commands, the plugin checks if you're trying to manually bump versions or create tags (which should go through the `/release` command instead)
- When you edit files, the plugin scans for anti-patterns like "fallback" or "deprecated" code that violates the project conventions
- When Claude needs your attention (permission prompts, idle prompts), you get desktop notifications

**Session End**: When you stop Claude Code, optional automations can run:

- Auto-commit any uncommitted changes (if enabled)
- Run a DRY scan to detect duplicate code (if enabled)
- Process any learning observations from the session
- Continue a milhouse loop if one is active

The plugin organizes its functionality into three categories:

**Commands** are actions you invoke explicitly with `/bluera-base:command-name`. They do something specific when you ask for it.

**Skills** are reference documentation that Claude Code uses to guide its behavior. You can reference them with `@skill-name` to pull in specialized knowledge.

**Hooks** are automatic behaviors that run without your intervention, triggered by specific events in the session lifecycle.

---

## Commands Explained

### Getting Started

**`/bluera-base:config`** manages all plugin settings. Start here with `/bluera-base:config init` to create your configuration file. Use `enable` and `disable` subcommands to toggle features. Use `show` to see current settings or `status` to debug issues.

**`/bluera-base:install-rules`** copies bluera-base's rule templates into your project's `.claude/rules/` directory. This makes the coding standards explicit in your repo so they persist even when the plugin isn't installed.

**`/bluera-base:harden-repo`** sets up quality infrastructure for your project - pre-commit hooks, linters, formatters, and editor configs. It detects your project's language and installs appropriate tooling.

### Daily Development

**`/bluera-base:commit`** creates commits using conventional commit format. It groups changes into atomic commits (one logical change per commit), respects README.md and CLAUDE.md conventions, and ensures commits are meaningful rather than mechanical.

**`/bluera-base:milhouse-loop`** starts an iterative development loop. Give it a prompt file or inline prompt, and Claude Code will keep working on it across multiple turns until the task is complete. Use this for complex tasks that need sustained focus.

**`/bluera-base:cancel-milhouse`** stops an active milhouse loop. Use this when you want to interrupt iterative development and take manual control.

**`/bluera-base:todo`** manages project TODO tasks in a persistent file (`.bluera/bluera-base/TODO.txt`). Use it to track work items across sessions.

### Code Quality

**`/bluera-base:code-review`** runs a multi-agent analysis of your codebase, checking for bugs, CLAUDE.md compliance issues, and code quality problems. It provides structured feedback you can act on.

**`/bluera-base:dry`** detects duplicate code using jscpd. Run `/bluera-base:dry scan` to find duplicates, or `/bluera-base:dry report` to see the last scan results. The plugin supports 150+ languages for duplicate detection.

**`/bluera-base:audit-plugin`** analyzes a Claude Code plugin against best practices. Use this when developing plugins to ensure they follow conventions.

**`/bluera-base:analyze-config`** examines your project's `.claude/**` directory for overlap with bluera-base. It suggests cleanup if you have redundant rules or configurations.

### Documentation

**`/bluera-base:claude-md`** maintains your CLAUDE.md memory files. Use `audit` to check existing files, `init` to create new ones, or `learn` to capture insights from the current session. Good CLAUDE.md files make Claude Code significantly more effective on your project.

**`/bluera-base:readme`** improves your README.md files using GitHub's advanced formatting - tables, badges, diagrams, collapsible sections. Use `beautify` to enhance an existing README or `breakout` to split a large README into multiple files.

### Releases

**`/bluera-base:release`** handles the full release workflow - detecting conventional commits, bumping versions, creating tags, and monitoring CI. This is the only approved way to create releases; manual `npm version` or `git tag` commands are blocked by hooks.

### Git Workflows

**`/bluera-base:worktree`** manages git worktrees for parallel development. Worktrees let you work on multiple branches simultaneously without stashing or switching contexts.

**`/bluera-base:statusline`** configures Claude Code's terminal status line display. Choose presets or create custom configurations showing the information you care about.

### Testing & Help

**`/bluera-base:test-plugin`** runs the comprehensive plugin validation suite. Use this after making changes to bluera-base itself to ensure everything still works.

**`/bluera-base:help`** shows the quick reference guide with tables and lists. For this narrative explanation, you're in the right place with `/bluera-base:explain`.

---

## Skills Explained

Skills are documentation files that provide specialized knowledge to Claude Code. Unlike commands (which do something when invoked), skills inform how Claude Code approaches specific tasks.

When you reference a skill with `@skill-name`, Claude Code loads that documentation into context. This is useful when you want Claude to follow specific patterns or understand particular domain knowledge.

**How skills work:**

Skills live in the `skills/` directory, each in its own subdirectory with a `SKILL.md` file. When referenced, the skill content becomes part of Claude Code's working context.

Most skills are not "user-invocable" - they're triggered by commands or used internally. The exception is `@large-file-refactor`, which you can invoke directly when Claude Code hits token limits reading a large file.

**Available skills:**

**`@atomic-commits`** - Documents the rules for creating atomic commits: one logical change per commit, conventional commit format, meaningful messages that explain "why" not "what".

**`@code-review-repo`** - Provides the multi-agent code review methodology used by `/bluera-base:code-review`.

**`@release`** - Contains the release workflow: checking CI status, detecting commit types, choosing version bumps, creating tags, monitoring deployments.

**`@milhouse`** - Explains the iterative development loop: how state is tracked, when to continue vs stop, how to handle stuck situations.

**`@claude-md-maintainer`** - Documents CLAUDE.md structure and validation rules: progressive disclosure, context optimization, what belongs where.

**`@readme-maintainer`** - Covers README.md formatting using GitHub's markdown extensions: alerts, tables, diagrams, badges, collapsible sections.

**`@repo-hardening`** - Details security and quality tool setup per language: linters, formatters, type checkers, pre-commit hooks.

**`@large-file-refactor`** - Guides breaking apart files that exceed token limits into smaller, focused modules. This is user-invocable for when Claude Code can't read a file due to size.

**`@dry-refactor`** - Contains language-specific refactoring patterns for eliminating duplicate code once jscpd identifies it.

**`@statusline`** - Documents the status line configuration system: themes, modules, custom formats.

---

## Hooks Explained

Hooks are automatic behaviors that run without explicit invocation. They're triggered by events in the Claude Code session lifecycle.

**You don't need to do anything to use hooks** - they run automatically when their trigger conditions are met. Understanding them helps you know what's happening behind the scenes.

### Session Lifecycle Hooks

**`session-setup.sh`** runs at session start. It creates the state directory (`.bluera/bluera-base/state/`), verifies that `jq` is available (required for JSON processing), and sets up the environment.

**`session-start-inject.sh`** also runs at session start, injecting any saved context or state into the session.

**`pre-compact.sh`** runs before Claude Code compacts the conversation context. It preserves important state that might otherwise be lost during compaction.

**`session-end-learn.sh`** runs at session end, processing any learning observations collected during the session (if auto-learn is enabled).

### Protection Hooks

**`block-manual-release.sh`** prevents manual version bumping and tagging. If you try to run `npm version`, `git tag`, `cargo release`, or similar commands directly, the hook blocks them with a message to use `/bluera-base:release` instead. This ensures releases go through the proper workflow.

**`post-edit-check.sh`** validates file changes after every edit. It scans for anti-patterns like "fallback", "deprecated", or "backward compatibility" code that violates project conventions. If found, it blocks the change with an explanation.

**`observe-learning.sh`** tracks bash commands for learning observations (if auto-learn is enabled). This helps build up CLAUDE.md context over time.

### Automation Hooks

**`milhouse-stop.sh`** continues the iterative development loop when one is active. At session stop, if a milhouse loop state file exists, this hook checks if more iterations are needed and feeds the prompt back if so.

**`dry-scan.sh`** runs a duplicate code scan at session end (if `dry-auto` is enabled). Results are saved to `.bluera/bluera-base/state/dry-report.md`.

**`auto-commit.sh`** commits any uncommitted changes at session end (if `auto-commit` is enabled). It can optionally push to the remote.

### Notification Hook

**`notify.sh`** sends desktop notifications when Claude Code needs attention - permission prompts, idle prompts, or elicitation dialogs. This helps if you're not actively watching the terminal.

---

## Configuration Explained

bluera-base uses a layered configuration system stored in `.bluera/bluera-base/`:

**`config.json`** - Team-shareable settings (committed to git). Put settings here that everyone on the team should use.

**`config.local.json`** - Personal overrides (gitignored). Put machine-specific or personal preference settings here.

**`state/`** - Runtime state (gitignored). Contains transient data like milhouse loop state, DRY reports, and learning observations.

### Configuration Features

All features are opt-in. Enable them with `/bluera-base:config enable <feature>`.

**`notifications`** (default: enabled) - Desktop notifications when Claude needs attention.

**`auto-learn`** - Track command patterns and suggest CLAUDE.md updates. Helps build project context over time.

**`auto-commit`** - Automatically commit uncommitted changes when the session ends.

**`auto-push`** - Push to remote after auto-commit (requires auto-commit).

**`dry-check`** - Enable the DRY duplicate detection system.

**`dry-auto`** - Automatically scan for duplicates at session end (requires dry-check).

**`strict-typing`** - Block `any` types, `as` casts, and `type: ignore` comments in code.

### Managing Configuration

```bash
# Initialize config for your project
/bluera-base:config init

# See current settings
/bluera-base:config show

# Enable a feature
/bluera-base:config enable auto-commit

# Disable a feature
/bluera-base:config disable notifications

# Check configuration status (for debugging)
/bluera-base:config status
```

---

## Philosophy Explained

bluera-base is built on specific principles about how code should be written and maintained. Understanding these helps you work with the plugin rather than against it.

### Fail Fast

Code should either work correctly or fail immediately with a clear error. When something goes wrong, you should know about it right away - not discover it later through strange behavior.

This means:

- Use `throw` for unexpected states or error conditions
- Never silently swallow errors
- Avoid `try/catch` blocks that hide failures
- Make errors visible and actionable

### No Fallbacks

If code is designed to work a certain way, it should work that way. There shouldn't be "backup plans" that hide when the primary approach fails.

This means:

- No "graceful degradation" unless it's part of the specification
- No default values that mask missing data
- No backward compatibility shims alongside new code
- No legacy support keeping old patterns alive

### Strict Typing

Types catch errors at write-time instead of runtime. Every variable should have a specific type that accurately describes what it contains.

This means:

- No `any` type in TypeScript (use specific types, generics, or `unknown`)
- No `as` casts (use type guards or fix the types)
- No `@ts-ignore` without explanation
- No `type: ignore` in Python without error codes

### Atomic Commits

Each commit should represent one logical change. This makes history readable, bisecting possible, and reverts clean.

This means:

- One feature, fix, or refactor per commit
- Conventional commit format (`type(scope): description`)
- Messages that explain "why" not "what"
- No amending pushed commits, no force-pushing shared branches

### Clean Code

The codebase should contain only working, current code. Dead code, commented-out code, and deprecated approaches create confusion and maintenance burden.

This means:

- No commented-out code in committed files
- No references to deprecated implementations
- Remove unused code entirely (don't rename to `_unused`)
- If something is obsolete, delete it

### Why These Rules?

These principles might feel restrictive, but they serve a purpose:

**Fail fast** means bugs surface immediately, not in production.

**No fallbacks** means the code does what it claims to do, making it predictable.

**Strict typing** means the compiler catches errors before runtime.

**Atomic commits** means you can understand, review, and revert changes confidently.

**Clean code** means you can trust what you read - if it's there, it's used.

Together, these create a codebase where the code you see is the code that runs, errors are visible, and history tells a coherent story.

---

## Getting Started

If you're new to bluera-base, here's the recommended path:

1. Run `/bluera-base:config init` to create your configuration
2. Run `/bluera-base:install-rules` to add rules to your project
3. Try `/bluera-base:commit` after making some changes
4. Enable features gradually as you need them

For quick reference, use `/bluera-base:help`. For this narrative guide, use `/bluera-base:explain`.
