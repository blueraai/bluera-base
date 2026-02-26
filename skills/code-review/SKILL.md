---
name: code-review
description: Review local codebase for bugs and CLAUDE.md compliance using multi-agent analysis
argument-hint: "[path]"
allowed-tools: [Read, Glob, Grep, Task, "Bash(git:*)", "Bash(gh:*)"]
---

# Local Code Review

Review the local codebase for bugs, issues, and CLAUDE.md compliance.

Make a todo list before starting.

## Process

1. **Gather CLAUDE.md files**: Use a Haiku agent to find all CLAUDE.md files in the repository (root and subdirectories). Note: CLAUDE.md is guidance for Claude as it writes code, so not all instructions will be applicable during code review. Focus on rules that are verifiable by reading code.

2. **Identify source files**: Determine which files to review:
   - Include: `.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.rs`, `.go` and similar source files
   - Exclude: `node_modules/`, `dist/`, `.git/`, vendor directories, generated files

3. **Summarize scope**: Use a Haiku agent to summarize what will be reviewed. If a path argument was given, describe the scope. If there are uncommitted changes (`git diff`, `git diff --cached`), summarize them — recently changed code is the primary review focus.

4. **Multi-agent review**: Launch 5 parallel Sonnet agents to independently review the codebase. Provide each agent with the CLAUDE.md list and scope summary. Each agent returns a list of issues with reasons:
   - **Agent #1**: Audit for CLAUDE.md compliance. Check that code follows guidelines in all relevant CLAUDE.md files.
   - **Agent #2**: Shallow bug scan. Look for obvious bugs, error handling issues, and logic errors. Focus on significant bugs, not nitpicks.
   - **Agent #3**: Git history context. Use git blame and history to identify patterns, recent changes, and potential issues in light of historical context.
   - **Agent #4**: Previous PR comments. Check closed PRs that touched these files for any feedback that might apply.
   - **Agent #5**: Code comment compliance. Ensure code follows any guidance in TODO, FIXME, NOTE, or other code comments.

   Agents should prioritize recently changed code (uncommitted changes, recent commits) over old unchanged code.

5. **Confidence scoring**: For each issue found, launch a parallel Haiku agent to score confidence (0-100). For issues flagged due to CLAUDE.md, the agent should verify the CLAUDE.md actually calls out that issue specifically:
   - **0**: False positive, doesn't hold up to scrutiny
   - **25**: Might be real, but unverified. Stylistic issues not in CLAUDE.md
   - **50**: Real but minor, rarely hit in practice
   - **75**: Verified real issue, important, directly impacts functionality or mentioned in CLAUDE.md
   - **100**: Definitely real, frequently hit, evidence confirms

6. **Filter**: Only report issues with score >= 80

## False Positive Examples

Avoid flagging:

- Something that looks like a bug but is not actually a bug
- Issues that linters/typecheckers/compilers would catch (imports, types, formatting)
- General quality issues unless explicitly required in CLAUDE.md
- Code with lint-ignore comments for that specific issue
- Pre-existing issues unrelated to recent changes
- Real issues on lines that were not recently modified
- Changes in functionality that are likely intentional or directly related to the broader change
- Pedantic nitpicks a senior engineer wouldn't mention

## Notes

- Do not attempt to build, typecheck, or run tests — assume CI handles those separately
- Cite file paths and line numbers for every issue

## Output Format

### Code review

Found N issues:

1. Brief description (CLAUDE.md says "...")
   `file/path.ts:42`

2. Brief description (bug due to missing error handling)
   `file/path.ts:88-95`

---

Or if no issues:

### Code review (no issues)

No issues found. Checked for bugs and CLAUDE.md compliance.
