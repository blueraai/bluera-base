# Spec: CLAUDE.md Maintainer (slash command + Skill) for bluera-base

Target repo: bluera-base Claude Code plugin (<https://github.com/blueraai/bluera-base>)

## Goal

Add **one** plugin slash command and **one** plugin Skill that, in any repository (project-independent), will:

1. **Audit** all `CLAUDE.md` / `.claude/CLAUDE.md` / `CLAUDE.local.md` files.
2. **Update** them to a consistent, *Claude-memory* format (not user docs), with **progressive disclosure** and **context-optimized** content.
3. **Create** missing `CLAUDE.md` files *only where genuinely helpful* (root + module/service roots), without spamming.

This is designed to address the recurring failure mode where Claude Code treats `CLAUDE.md` like a README / user documentation.

## Non-goals

- Not a project README/doc generator.
- Not a generic “summarize repo” command.
- Not a long-running background daemon.
- Not a formatter/linter for arbitrary markdown beyond the specific invariants below.

## Background constraints from Claude Code

- **Memory model & hierarchy**:
  - Project memory can live in `./CLAUDE.md` or `./.claude/CLAUDE.md`; local project prefs in `./CLAUDE.local.md`; and modular rules in `./.claude/rules/*.md`. These are auto-loaded by Claude Code (with precedence).  
  - Claude Code reads memories by **walking up** from the current working directory and also discovers nested `CLAUDE.md` files in subtrees **only when files in those subtrees are read**.  
  - `CLAUDE.md` supports `@path/to/import` includes (not evaluated inside code blocks/spans), recursive to depth 5.  
  Source: <https://code.claude.com/docs/en/memory>

- **Plugin command + Skill mechanics**:
  - Plugin commands live in `commands/` and are invoked as `/plugin-name:command-name` (prefix optional unless collisions).
  - The `Skill` tool can programmatically invoke both custom slash commands and Skills; there is a metadata character budget (default 15k chars) for command/Skill name + args + description.  
  Source: <https://code.claude.com/docs/en/slash-commands> and <https://code.claude.com/docs/en/plugins-reference>

- **Agent Skills progressive disclosure**:
  - Keep `SKILL.md` concise; move deep details into supporting files; scripts can run without their contents being loaded into context.  
  Source: <https://code.claude.com/docs/en/skills>

- **Known footguns (must design around)**:
  - Skill discovery can break when `description` wraps to multiple lines (e.g., prettier `proseWrap`).  
    Issue: <https://github.com/anthropics/claude-code/issues/9817>
  - Slash command frontmatter YAML styles (folded `description: >` and YAML list `allowed-tools:`) can cause Claude Code to think **no tools are permitted**.  
    Issue: <https://github.com/anthropics/claude-code/issues/9857>
  - `allowed-tools` may still prompt for approval for Bash in some versions; do not depend on bypassing prompts.  
    Issue: <https://github.com/anthropics/claude-code/issues/5598>

## Single recommendation (do this)

### 1) Add one plugin command

**File:** `commands/claude-md.md`  
**Invoked by user as:** `/bluera-base:claude-md` (or `/claude-md` if no collisions)

#### Command frontmatter (REQUIRED formatting rules)

- Use **single-line** scalars (no folded blocks).
- Use `allowed-tools:` as a **single line** (comma-separated). Do **not** use YAML lists.

```md
---
description: Audit + maintain CLAUDE.md memory files (validate, update, create where helpful)
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(git:*), Bash(ls:*), Bash(wc:*), Bash(head:*), Bash(tail:*)
---
```

> Notes:
>
> - The Bash patterns above are intentionally narrow and only for repo inspection / reporting.
> - The workflow must still function if approvals are prompted anyway.

#### Command body behavior

The command runs in **two phases** every time:

1. **Plan phase (no writes)**  
   - Discover memory files.
   - Produce a proposed patch plan (exact files + change summaries).
   - Call out any ambiguous cases that require human choice.
2. **Apply phase (writes)**  
   - Only after the user confirms, perform edits/creates.

The command must explicitly instruct Claude to:

- Prefer *directory-scoped* memory over dumping everything in root.
- Prefer `.claude/rules/*.md` with `paths:` for language/framework rules when appropriate.
- Keep each memory file lean (see invariants below).

### 2) Add one plugin Skill

**Directory:** `skills/claude-md-maintainer/`  
**File:** `skills/claude-md-maintainer/SKILL.md`

#### Skill frontmatter (REQUIRED formatting rules)

- **Single-line** `description`.
- Keep description short to reduce `Skill` tool metadata footprint.
- Hide from the `/skills` menu (users will use the slash command), but allow auto-application when the user asks about “CLAUDE.md / memory”.

```md
---
name: claude-md-maintainer
description: Validate/update/create CLAUDE.md memory files with progressive disclosure and context-optimized structure
user-invocable: false
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(git:*), Bash(ls:*), Bash(wc:*), Bash(head:*), Bash(tail:*)
---
```

#### Skill body structure (progressive disclosure)

`SKILL.md` must be **short** and should mainly:

- Define the invariants + algorithm.
- Reference supporting files for templates and checklists.

Add supporting files in the same skill directory:

```text
skills/claude-md-maintainer/
  SKILL.md
  templates/
    root_CLAUDE.md
    module_CLAUDE.md
    local_CLAUDE.local.md
  docs/
    invariants.md
    directory-heuristics.md
    rule-files.md
```

`SKILL.md` should say: “When generating/editing, use the templates under `templates/` and the checklists under `docs/`.”

## The maintainer algorithm (must be deterministic)

### Step A — Discover existing memory + rules

From repo root (or `git rev-parse --show-toplevel`):

1. Find memory files:
   - `./CLAUDE.md`
   - `./.claude/CLAUDE.md`
   - `./CLAUDE.local.md`
   - Any nested `**/CLAUDE.md` (excluding ignored dirs)
2. Find `.claude/rules/**/*.md`

Ignore directories:

- `.git/`, `node_modules/`, `.venv/`, `dist/`, `build/`, `out/`, `target/`, `vendor/`, `.idea/`, `.vscode/`

### Step B — Validate invariants (every CLAUDE.md)

Each `CLAUDE.md` (root or nested) MUST:

1. **Declare purpose**: explicitly state it is Claude’s *memory*, not user documentation.
2. **Be lean**:
   - Prefer bullet lists.
   - No long prose blocks.
   - Avoid duplicating content already covered by an ancestor memory file.
3. **Be actionable**:
   - List the canonical build/test/lint/dev commands for the scope.
   - If commands can’t be determined, include a short TODO with next-best pointers.
4. **Use progressive disclosure**:
   - Root file: project-wide invariants and top workflows only.
   - Module files: module-only workflows and conventions.
   - Topic rules go into `.claude/rules/` with `paths:` where possible.

### Step C — Update strategy

For each existing memory file:

1. **Prepend** the mandatory header block (if missing).
2. **Normalize** section ordering:
   - Purpose (header)
   - “Commands” (build/test/lint/dev)
   - “Workflows” (CI/release/deploy if in-scope)
   - “Conventions” (only those relevant to the scope)
   - “Directory map / entrypoints” (short)
   - “Never/Always” guardrails (short)
3. **De-duplicate**:
   - If a subdirectory CLAUDE.md repeats global rules, replace those with a single “See root CLAUDE.md” line.
4. **Split**:
   - If root file is getting long or mixing unrelated concerns, move content into `.claude/rules/<topic>.md` (see below) and keep root as pointers + minimal key rules.

### Step D — Create missing files (only where helpful)

Create **at most**:

1. **One root** memory file (prefer `./CLAUDE.md`):
   - If neither `./CLAUDE.md` nor `./.claude/CLAUDE.md` exists, create `./CLAUDE.md`.
2. **One local** file:
   - If `./CLAUDE.local.md` does not exist, create it from template and ensure it is in `.gitignore`.
3. **Module CLAUDE.md files**:
   - Identify “module roots” using heuristics below.
   - Only create if the directory lacks a `CLAUDE.md`.

#### Module root heuristics (create CLAUDE.md when true)

A directory is a module root if it contains one of:

- `package.json` (Node)
- `pyproject.toml` or `requirements.txt` (Python)
- `Cargo.toml` (Rust)
- `go.mod` (Go)
- `pom.xml` / `build.gradle` (JVM)
- `Makefile`
- `CMakeLists.txt`

AND is not excluded/ignored.

Additionally, prefer creating module CLAUDE.md for directories that:

- Have their own CI workflow path filters, or
- Are under conventional monorepo roots (`packages/`, `apps/`, `services/`, `libs/`) with a manifest.

Hard cap: if > 25 module roots are detected, create:

- root CLAUDE.md
- CLAUDE.md at each top-level monorepo bucket (`packages/`, `apps/`, etc) summarizing how to navigate + which packages matter
…and defer per-package CLAUDE.md creation (report it as a follow-up item, not an automatic write).

## Required templates (exact shape)

### templates/root_CLAUDE.md

Must start with:

```md
# THIS IS CLAUDE.md - PROJECT MEMORY

**STOP. READ THIS FIRST.**

This file is for **Claude Code**. It is **not** user documentation. It is **not** a README.

| File | Purpose | Audience |
|------|---------|----------|
| **CLAUDE.md** | Claude Code project memory: workflows, scripts, conventions | Claude |
| **README.md** | User-facing documentation: usage, installation, API | Humans |

**Update this file when:** build/test/release workflows, scripts, CI, or conventions change.

**Keep it lean.** Every line loads into context.
```

Then include only these canonical sections:

```md
## Project quick facts
- Primary languages:
- Primary frameworks:
- Repo shape: (monorepo/single)
- Where the “source of truth” build commands live:

## Commands (copy/paste)
- Build:
- Test:
- Lint:
- Format:
- Typecheck:
- Dev / Run:

## CI/CD
- CI entrypoint(s):
- Release process:

## Guardrails
ALWAYS:
- ...
NEVER:
- ...

## Directory map
- `path/` — purpose
```

### templates/module_CLAUDE.md

```md
# THIS IS CLAUDE.md - DIRECTORY MEMORY

This file is Claude Code memory for **this directory subtree**.
Do not duplicate root rules here; only add what’s unique to this module.

## Scope
- Module name:
- Ownership:
- Entry points:

## Commands (from this directory)
- Build:
- Test:
- Lint:
- Dev:

## Local conventions
- ...

## Gotchas
- ...
```

### templates/local_CLAUDE.local.md

```md
# CLAUDE.local.md (private, gitignored)

Personal, machine-specific project notes. Examples:
- Local URLs / ports
- Sandbox credentials (never commit)
- Preferred datasets / fixtures locations
```

## `.claude/rules/` generation requirements

When splitting rules out of root CLAUDE.md:

- Create topic files like:
  - `.claude/rules/testing.md`
  - `.claude/rules/security.md`
  - `.claude/rules/frontend/react.md`

- Use `paths:` frontmatter whenever rules are only relevant to certain areas:

```md
---
paths:
  - "src/**/*.ts"
  - "packages/*/src/**/*.ts"
---

# TypeScript rules
- ...
```

## Output report format (after plan + after apply)

The command/skill must output a concise report:

- Memory files found (paths)
- Files to create (paths)
- Files to update (paths)
- Rules files to create/update (paths)
- A short diff summary per file (what changed)
- Follow-ups (any ambiguous items not auto-fixed)

## Definition of Done

- `/bluera-base:claude-md` exists and runs end-to-end in a repo with:
  - no CLAUDE.md at all
  - an existing messy CLAUDE.md
  - a monorepo with multiple package roots
- Resulting memory files:
  - have the correct purpose header
  - are short and actionable
  - use progressive disclosure via module CLAUDE.md + `.claude/rules`
- Frontmatter is robust against the known discovery/permission footguns (single-line description; no YAML lists).

## Implementation checklist (repo changes)

- [ ] Add `commands/claude-md.md`
- [ ] Add `skills/claude-md-maintainer/SKILL.md`
- [ ] Add templates + docs under `skills/claude-md-maintainer/`
- [ ] Update bluera-base README command list to include `/bluera-base:claude-md`
- [ ] Bump plugin version + publish workflow per bluera-base release process
