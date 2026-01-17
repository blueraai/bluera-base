---
description: Set up git hooks, linters, formatters, and editor configs for a project
allowed-tools: Bash, Read, Write, Edit, Glob, AskUserQuestion
argument-hint: [--language <lang>] [--skip-hooks] [--coverage <threshold>]
---

# Harden Repo

Interactive setup for git hooks, linters, formatters, coverage, and quality tooling.

## Context

!`ls package.json pyproject.toml requirements.txt Cargo.toml go.mod pom.xml build.gradle build.gradle.kts Gemfile composer.json Package.swift mix.exs CMakeLists.txt build.sbt 2>/dev/null || echo "No project files detected"`

## Workflow

See @bluera-base/skills/repo-hardening/SKILL.md for complete workflow.

**Phases:** Detect existing → Interview user → Set up tooling → Configure coverage → Report
