# Changelog

All notable changes to this project will be documented in this file. See [commit-and-tag-version](https://github.com/absolute-version/commit-and-tag-version) for commit guidelines.

## [0.39.0](https://github.com/blueraai/bluera-base/compare/v0.37.8...v0.39.0) (2026-02-12)

### Features

* **skills:** add bluera config status badge to statusline preset ([174a8cd](https://github.com/blueraai/bluera-base/commit/174a8cd746a121481fa9f293729597ad5f91576d))
* **skills:** add browser-inference-guide expert skill ([19aab4c](https://github.com/blueraai/bluera-base/commit/19aab4ce05106a627f9e371e642e557cefa97036))

### Bug Fixes

* **skills:** remove shell-exec backtick pattern from audit-plugin skill ([4ab402f](https://github.com/blueraai/bluera-base/commit/4ab402f3ac4859963f4d61f123a28a68a6bdef33))

## [0.38.0](https://github.com/blueraai/bluera-base/compare/v0.37.8...v0.38.0) (2026-02-11)

### Features

* **skills:** add browser-inference-guide expert skill ([19aab4c](https://github.com/blueraai/bluera-base/commit/19aab4ce05106a627f9e371e642e557cefa97036))

### Bug Fixes

* **skills:** remove shell-exec backtick pattern from audit-plugin skill ([4ab402f](https://github.com/blueraai/bluera-base/commit/4ab402f3ac4859963f4d61f123a28a68a6bdef33))

## [0.37.8](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.8) (2026-02-10)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **hooks:** add project context to deep-learn analysis and fix stdout leak ([aa2c2ce](https://github.com/blueraai/bluera-base/commit/aa2c2ceddfa4e1b97f6fc541eb34805d36ae5a10))
* **hooks:** reduce false positives in secrets detection pattern ([adb6ec0](https://github.com/blueraai/bluera-base/commit/adb6ec058267234b6c269e0a12d49d21472ff512))
* **hooks:** remove bluera-knowledge entries from gitignore service ([6f2ace9](https://github.com/blueraai/bluera-base/commit/6f2ace91ae8d5fe2a9f3c56d4a1feaa7c4afa391))
* **hooks:** sanitize control characters in transcript before jq parsing ([3300128](https://github.com/blueraai/bluera-base/commit/3300128b5b20ef4297f1b19c70b6b0d84d9d1a49))
* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **plugin:** remove unrecognized manifest keys (bugs, categories) ([6398c72](https://github.com/blueraai/bluera-base/commit/6398c72e44c69b299dd35abc1f7aa5ca828142bb))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** clarify --path handling on tech-debt report subcommand ([cc0d36b](https://github.com/blueraai/bluera-base/commit/cc0d36b9e6dd2eb281fde83d745b1033330feae5))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))
* **skills:** quote allowed-tools entries with YAML special chars ([f7b0485](https://github.com/blueraai/bluera-base/commit/f7b0485c5cc02f11c357aeeb5529329ed542d8a7))

## [0.37.7](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.7) (2026-02-10)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **hooks:** add project context to deep-learn analysis and fix stdout leak ([aa2c2ce](https://github.com/blueraai/bluera-base/commit/aa2c2ceddfa4e1b97f6fc541eb34805d36ae5a10))
* **hooks:** reduce false positives in secrets detection pattern ([adb6ec0](https://github.com/blueraai/bluera-base/commit/adb6ec058267234b6c269e0a12d49d21472ff512))
* **hooks:** remove bluera-knowledge entries from gitignore service ([6f2ace9](https://github.com/blueraai/bluera-base/commit/6f2ace91ae8d5fe2a9f3c56d4a1feaa7c4afa391))
* **hooks:** sanitize control characters in transcript before jq parsing ([3300128](https://github.com/blueraai/bluera-base/commit/3300128b5b20ef4297f1b19c70b6b0d84d9d1a49))
* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **plugin:** remove unrecognized manifest keys (bugs, categories) ([6398c72](https://github.com/blueraai/bluera-base/commit/6398c72e44c69b299dd35abc1f7aa5ca828142bb))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** clarify --path handling on tech-debt report subcommand ([cc0d36b](https://github.com/blueraai/bluera-base/commit/cc0d36b9e6dd2eb281fde83d745b1033330feae5))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))
* **skills:** quote allowed-tools entries with YAML special chars ([f7b0485](https://github.com/blueraai/bluera-base/commit/f7b0485c5cc02f11c357aeeb5529329ed542d8a7))

## [0.37.6](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.6) (2026-02-09)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **hooks:** add project context to deep-learn analysis and fix stdout leak ([aa2c2ce](https://github.com/blueraai/bluera-base/commit/aa2c2ceddfa4e1b97f6fc541eb34805d36ae5a10))
* **hooks:** reduce false positives in secrets detection pattern ([adb6ec0](https://github.com/blueraai/bluera-base/commit/adb6ec058267234b6c269e0a12d49d21472ff512))
* **hooks:** remove bluera-knowledge entries from gitignore service ([6f2ace9](https://github.com/blueraai/bluera-base/commit/6f2ace91ae8d5fe2a9f3c56d4a1feaa7c4afa391))
* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **plugin:** remove unrecognized manifest keys (bugs, categories) ([6398c72](https://github.com/blueraai/bluera-base/commit/6398c72e44c69b299dd35abc1f7aa5ca828142bb))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** clarify --path handling on tech-debt report subcommand ([cc0d36b](https://github.com/blueraai/bluera-base/commit/cc0d36b9e6dd2eb281fde83d745b1033330feae5))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))
* **skills:** quote allowed-tools entries with YAML special chars ([f7b0485](https://github.com/blueraai/bluera-base/commit/f7b0485c5cc02f11c357aeeb5529329ed542d8a7))

## [0.37.5](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.5) (2026-02-09)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **hooks:** remove bluera-knowledge entries from gitignore service ([6f2ace9](https://github.com/blueraai/bluera-base/commit/6f2ace91ae8d5fe2a9f3c56d4a1feaa7c4afa391))
* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **plugin:** remove unrecognized manifest keys (bugs, categories) ([6398c72](https://github.com/blueraai/bluera-base/commit/6398c72e44c69b299dd35abc1f7aa5ca828142bb))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** clarify --path handling on tech-debt report subcommand ([cc0d36b](https://github.com/blueraai/bluera-base/commit/cc0d36b9e6dd2eb281fde83d745b1033330feae5))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))
* **skills:** quote allowed-tools entries with YAML special chars ([f7b0485](https://github.com/blueraai/bluera-base/commit/f7b0485c5cc02f11c357aeeb5529329ed542d8a7))

## [0.37.4](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.4) (2026-02-08)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **hooks:** remove bluera-knowledge entries from gitignore service ([6f2ace9](https://github.com/blueraai/bluera-base/commit/6f2ace91ae8d5fe2a9f3c56d4a1feaa7c4afa391))
* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **plugin:** remove unrecognized manifest keys (bugs, categories) ([6398c72](https://github.com/blueraai/bluera-base/commit/6398c72e44c69b299dd35abc1f7aa5ca828142bb))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))
* **skills:** quote allowed-tools entries with YAML special chars ([f7b0485](https://github.com/blueraai/bluera-base/commit/f7b0485c5cc02f11c357aeeb5529329ed542d8a7))

## [0.37.3](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.3) (2026-02-08)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **plugin:** remove unrecognized manifest keys (bugs, categories) ([6398c72](https://github.com/blueraai/bluera-base/commit/6398c72e44c69b299dd35abc1f7aa5ca828142bb))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))
* **skills:** quote allowed-tools entries with YAML special chars ([f7b0485](https://github.com/blueraai/bluera-base/commit/f7b0485c5cc02f11c357aeeb5529329ed542d8a7))

## [0.37.2](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.2) (2026-02-07)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))
* **skills:** quote allowed-tools entries with YAML special chars ([f7b0485](https://github.com/blueraai/bluera-base/commit/f7b0485c5cc02f11c357aeeb5529329ed542d8a7))

## [0.37.1](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.1) (2026-02-07)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))

## [0.37.0](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.37.0) (2026-02-07)

### ⚠ BREAKING CHANGES

* **plugin:** Old skill-based slash command names changed:
* /bluera-base:atomic-commits -> /bluera-base:commit
* /bluera-base:code-review-repo -> /bluera-base:code-review
* /bluera-base:repo-hardening -> /bluera-base:harden-repo
* /bluera-base:readme-maintainer -> /bluera-base:readme
* /bluera-base:claude-code-md-maintainer -> /bluera-base:claude-code-md
* /bluera-base:milhouse-loop -> /bluera-base:milhouse
* /bluera-base:cancel-milhouse -> /bluera-base:milhouse cancel
* /bluera-base:claude-code-audit -> removed (use /claude-code-guide)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

* **plugin:** retire command wrappers, skills are primary slash commands ([259235a](https://github.com/blueraai/bluera-base/commit/259235a22cf85c24e9eaa5b4cc36432ca0cf0e7b))

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))

## [0.36.1](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.36.1) (2026-02-07)

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **skills:** add mkdir permission and clarify report parsing rules ([5cca052](https://github.com/blueraai/bluera-base/commit/5cca052a60728fcc20331f9856099fa28fe52bc9))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))

## [0.36.0](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.36.0) (2026-02-06)

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))
* **skills:** add tech-debt-and-refactor-scan skill ([3c6dd44](https://github.com/blueraai/bluera-base/commit/3c6dd44dfdbcc2054c03985381afd47fbb7ca54f))

### Bug Fixes

* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))
* **skills:** complete tech-debt-and-refactor-scan spec and revert config ([0102467](https://github.com/blueraai/bluera-base/commit/0102467560037378250e36ed3ad234dd645fbf01))

## [0.35.1](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.35.1) (2026-02-05)

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))

### Bug Fixes

* **memory:** anchor tag matching to frontmatter and clarify hash naming ([7a9118c](https://github.com/blueraai/bluera-base/commit/7a9118c745aa0b498bbda399f76a2aa02fad892e))

## [0.35.0](https://github.com/blueraai/bluera-base/compare/v0.34.0...v0.35.0) (2026-02-05)

### Features

* **hooks:** add opt-in session-start memory surfacing ([69c858f](https://github.com/blueraai/bluera-base/commit/69c858f358fa92f552a4454bb023d9a3be1077c1))
* **learn:** add opt-in auto-promotion to global memory ([fe76943](https://github.com/blueraai/bluera-base/commit/fe769432daf3d7d6b4cdc177d24502a690fadb5b))
* **memory:** add hash-based deduplication and word-boundary auto-tagging ([f8b1fa5](https://github.com/blueraai/bluera-base/commit/f8b1fa5843f3c3c91f6c5345dd6e4b3506fc8aeb))

## [0.34.0](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.34.0) (2026-02-05)

### Features

* **claude-code-graph:** add terminal-friendly default output with descriptions ([fcaf556](https://github.com/blueraai/bluera-base/commit/fcaf55620c7cd322e20e7bd16ef6b510dec146bd))
* **config:** add coverage enforcement feature ([a05f96d](https://github.com/blueraai/bluera-base/commit/a05f96dd3aa43a785e22b3d7ae47669535fd956b))
* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **disk:** rename claude-code-clean to claude-code-disk with enhanced features ([06a1182](https://github.com/blueraai/bluera-base/commit/06a1182034bab7127f76a3c3ac9745d5a3f8d558))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))
* **memory:** add global memory system ([d3c6528](https://github.com/blueraai/bluera-base/commit/d3c6528e2f3321eb8394a6e434315fd3076cc595))

### Bug Fixes

* **cc-cleaner:** remove backward compatibility shims ([68c644f](https://github.com/blueraai/bluera-base/commit/68c644f0585b718471dfdd4f2869b51ac0434fb1))
* **config:** add missing !.bluera/ gitignore negation ([bb12b43](https://github.com/blueraai/bluera-base/commit/bb12b439ca9c86d3c53479ccf2c97cf5e669a327))
* **hooks:** centralize jq check with stderr warnings ([52de1f8](https://github.com/blueraai/bluera-base/commit/52de1f84c583961c74cc5b125b5e9889bb63af35))
* **hooks:** use explicit skip/block helpers for jq check ([c3bf487](https://github.com/blueraai/bluera-base/commit/c3bf48710a1144e7d12086e70e20c14e7d19242a))
* **memory:** add collision protection to ID generation ([8d16427](https://github.com/blueraai/bluera-base/commit/8d164274da1fd8362ef80090e9cc7b13525304ac))
* **release:** require polling loop to wait for ALL workflows ([6de5d33](https://github.com/blueraai/bluera-base/commit/6de5d33b99e2ffbee01cdcf77d7a22fbc05ffdff))
* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))
* **secrets-hook:** exclude dist/, build/, and test files from scanning ([0a62430](https://github.com/blueraai/bluera-base/commit/0a624300a4f134818e3dffcbeaa0e996b3c5bf66))
* **secrets-hook:** only scan added lines, refine patterns ([86f04e5](https://github.com/blueraai/bluera-base/commit/86f04e588074465a90399d89b3de0fed11e4415e))
* **secrets-hook:** reduce false positives on token patterns ([360f8f7](https://github.com/blueraai/bluera-base/commit/360f8f7ea3d9a1c80af77769ef13757e41011370))
* **secrets:** require assignment for api_key pattern ([5497585](https://github.com/blueraai/bluera-base/commit/549758555a4e26cf76a46f727aadffa95fd920f8))

## [0.33.0](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.33.0) (2026-02-04)

### Features

* **claude-code-graph:** add terminal-friendly default output with descriptions ([fcaf556](https://github.com/blueraai/bluera-base/commit/fcaf55620c7cd322e20e7bd16ef6b510dec146bd))
* **config:** add coverage enforcement feature ([a05f96d](https://github.com/blueraai/bluera-base/commit/a05f96dd3aa43a785e22b3d7ae47669535fd956b))
* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **disk:** rename claude-code-clean to claude-code-disk with enhanced features ([06a1182](https://github.com/blueraai/bluera-base/commit/06a1182034bab7127f76a3c3ac9745d5a3f8d558))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **cc-cleaner:** remove backward compatibility shims ([68c644f](https://github.com/blueraai/bluera-base/commit/68c644f0585b718471dfdd4f2869b51ac0434fb1))
* **config:** add missing !.bluera/ gitignore negation ([bb12b43](https://github.com/blueraai/bluera-base/commit/bb12b439ca9c86d3c53479ccf2c97cf5e669a327))
* **release:** require polling loop to wait for ALL workflows ([6de5d33](https://github.com/blueraai/bluera-base/commit/6de5d33b99e2ffbee01cdcf77d7a22fbc05ffdff))
* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))
* **secrets-hook:** exclude dist/, build/, and test files from scanning ([0a62430](https://github.com/blueraai/bluera-base/commit/0a624300a4f134818e3dffcbeaa0e996b3c5bf66))
* **secrets-hook:** only scan added lines, refine patterns ([86f04e5](https://github.com/blueraai/bluera-base/commit/86f04e588074465a90399d89b3de0fed11e4415e))
* **secrets-hook:** reduce false positives on token patterns ([360f8f7](https://github.com/blueraai/bluera-base/commit/360f8f7ea3d9a1c80af77769ef13757e41011370))

## [0.32.2](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.32.2) (2026-02-04)

### Features

* **claude-code-graph:** add terminal-friendly default output with descriptions ([fcaf556](https://github.com/blueraai/bluera-base/commit/fcaf55620c7cd322e20e7bd16ef6b510dec146bd))
* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **cc-cleaner:** remove backward compatibility shims ([68c644f](https://github.com/blueraai/bluera-base/commit/68c644f0585b718471dfdd4f2869b51ac0434fb1))
* **config:** add missing !.bluera/ gitignore negation ([bb12b43](https://github.com/blueraai/bluera-base/commit/bb12b439ca9c86d3c53479ccf2c97cf5e669a327))
* **release:** require polling loop to wait for ALL workflows ([6de5d33](https://github.com/blueraai/bluera-base/commit/6de5d33b99e2ffbee01cdcf77d7a22fbc05ffdff))
* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))
* **secrets-hook:** exclude dist/, build/, and test files from scanning ([0a62430](https://github.com/blueraai/bluera-base/commit/0a624300a4f134818e3dffcbeaa0e996b3c5bf66))
* **secrets-hook:** reduce false positives on token patterns ([360f8f7](https://github.com/blueraai/bluera-base/commit/360f8f7ea3d9a1c80af77769ef13757e41011370))

## [0.32.1](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.32.1) (2026-02-04)

### Features

* **claude-code-graph:** add terminal-friendly default output with descriptions ([fcaf556](https://github.com/blueraai/bluera-base/commit/fcaf55620c7cd322e20e7bd16ef6b510dec146bd))
* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **cc-cleaner:** remove backward compatibility shims ([68c644f](https://github.com/blueraai/bluera-base/commit/68c644f0585b718471dfdd4f2869b51ac0434fb1))
* **config:** add missing !.bluera/ gitignore negation ([bb12b43](https://github.com/blueraai/bluera-base/commit/bb12b439ca9c86d3c53479ccf2c97cf5e669a327))
* **release:** require polling loop to wait for ALL workflows ([6de5d33](https://github.com/blueraai/bluera-base/commit/6de5d33b99e2ffbee01cdcf77d7a22fbc05ffdff))
* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))
* **secrets-hook:** exclude dist/, build/, and test files from scanning ([0a62430](https://github.com/blueraai/bluera-base/commit/0a624300a4f134818e3dffcbeaa0e996b3c5bf66))

## [0.32.0](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.32.0) (2026-02-03)

### Features

* **claude-code-graph:** add terminal-friendly default output with descriptions ([fcaf556](https://github.com/blueraai/bluera-base/commit/fcaf55620c7cd322e20e7bd16ef6b510dec146bd))
* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **config:** add missing !.bluera/ gitignore negation ([bb12b43](https://github.com/blueraai/bluera-base/commit/bb12b439ca9c86d3c53479ccf2c97cf5e669a327))
* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))
* **secrets-hook:** exclude dist/, build/, and test files from scanning ([0a62430](https://github.com/blueraai/bluera-base/commit/0a624300a4f134818e3dffcbeaa0e996b3c5bf66))

## [0.31.5](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.31.5) (2026-02-03)

### Features

* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **config:** add missing !.bluera/ gitignore negation ([bb12b43](https://github.com/blueraai/bluera-base/commit/bb12b439ca9c86d3c53479ccf2c97cf5e669a327))
* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))
* **secrets-hook:** exclude dist/, build/, and test files from scanning ([0a62430](https://github.com/blueraai/bluera-base/commit/0a624300a4f134818e3dffcbeaa0e996b3c5bf66))

## [0.31.4](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.31.4) (2026-02-03)

### Features

* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))
* **secrets-hook:** exclude dist/, build/, and test files from scanning ([0a62430](https://github.com/blueraai/bluera-base/commit/0a624300a4f134818e3dffcbeaa0e996b3c5bf66))

## [0.31.3](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.31.3) (2026-02-03)

### Features

* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))

## [0.31.2](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.31.2) (2026-02-03)

### Features

* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))
* **secrets-hook:** exclude .bluera/ config from secret scanning ([b5ef1e9](https://github.com/blueraai/bluera-base/commit/b5ef1e9fdb7643fa4eb872ec2b1b3c98db60a4a3))

## [0.31.1](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.31.1) (2026-02-03)

### Features

* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

### Bug Fixes

* **secrets-hook:** add HTML comment bypass for markdown files ([b357517](https://github.com/blueraai/bluera-base/commit/b35751780ef8df3c7ddd79026c10aa815d9c1664))

## [0.31.0](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.31.0) (2026-02-03)

### Features

* **config:** enable all features by default (opt-out instead of opt-in) ([28a2773](https://github.com/blueraai/bluera-base/commit/28a2773f9357b0dbc75c10e4195d8fbcf5ed6488))
* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

## [0.30.1](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.30.1) (2026-02-03)

### Features

* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

## [0.30.0](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.30.0) (2026-02-03)

### Features

* **create:** add entity scan phase for conflict detection ([4d2ac8d](https://github.com/blueraai/bluera-base/commit/4d2ac8d69db87c5e9c81c1f8122f875b8c2a44d9))
* **hooks:** add secrets check hook for git add/commit ([befa1ac](https://github.com/blueraai/bluera-base/commit/befa1acdd9e2cc1f20f9d46944cceebd3d76d5cd))

## [0.29.3](https://github.com/blueraai/bluera-base/compare/v0.29.2...v0.29.3) (2026-02-03)

## [0.29.2](https://github.com/blueraai/bluera-base/compare/v0.29.1...v0.29.2) (2026-02-03)

## [0.29.1](https://github.com/blueraai/bluera-base/compare/v0.29.0...v0.29.1) (2026-02-03)

## [0.29.0](https://github.com/blueraai/bluera-base/compare/v0.28.0...v0.29.0) (2026-02-03)

### Features

* **commands:** standardize claude-code naming and add graph skill ([1325cec](https://github.com/blueraai/bluera-base/commit/1325cec92266f8698b9fd6325ce95dc4fb527774))

### Bug Fixes

* **cleaner:** remove unused legacy backup function ([045b911](https://github.com/blueraai/bluera-base/commit/045b91120e6a496af067ef31efa30eae25eb8b76))
* **learn:** extract content from tool_result blocks in user messages ([d395efd](https://github.com/blueraai/bluera-base/commit/d395efdcc3e1e3abe421832bc7f0ec28cf0682e7))

## [0.28.0](https://github.com/blueraai/bluera-base/compare/v0.24.0...v0.28.0) (2026-02-03)

### Features

* **auto-improve:** add skill to fetch updates and improve plugin ([1e327b7](https://github.com/blueraai/bluera-base/commit/1e327b774c9ba58945cf8a3bba8e732946a1d39e))
* **claude-code-guide:** add audit command for Claude Code best practices ([9ca81a3](https://github.com/blueraai/bluera-base/commit/9ca81a32ce0041ea78b62df7e12087779268704c))
* **claude-code-guide:** add Claude Code expert consultant ([aa58aae](https://github.com/blueraai/bluera-base/commit/aa58aaeb3bb3a302449b88aa15d6b60a4f5b7132))
* **commands:** add argument-hint frontmatter ([201722e](https://github.com/blueraai/bluera-base/commit/201722e7d9c1c8e0905ffc3fd84d7f17ae0b32cb))
* **commands:** add argument-hint to remaining commands ([eb9c080](https://github.com/blueraai/bluera-base/commit/eb9c0807a9acbb8112f2e6c8233d7b43a5be77a5))
* **create:** add plugin component generator command ([676ba55](https://github.com/blueraai/bluera-base/commit/676ba55aabbe87cd6565b3a8d75517b708f02f6a))
* **create:** integrate claude-code-guide expert consultation ([f199543](https://github.com/blueraai/bluera-base/commit/f199543e0a19eb84ee6da87be20bdc57474208de))

### Bug Fixes

* **hooks:** add **BLUERA_TEST** bypass and fix checklist grep ([7e8ee19](https://github.com/blueraai/bluera-base/commit/7e8ee199120b75c3c6e3bac04070e41cc1d6db2a))
* **hooks:** address audit findings ([74246df](https://github.com/blueraai/bluera-base/commit/74246df1bd3a6cc2f36ff85cb287f989fed92a21))

## [0.27.0](https://github.com/blueraai/bluera-base/compare/v0.24.0...v0.27.0) (2026-02-03)

### Features

* **auto-improve:** add skill to fetch updates and improve plugin ([1e327b7](https://github.com/blueraai/bluera-base/commit/1e327b774c9ba58945cf8a3bba8e732946a1d39e))
* **claude-code-guide:** add audit command for Claude Code best practices ([9ca81a3](https://github.com/blueraai/bluera-base/commit/9ca81a32ce0041ea78b62df7e12087779268704c))
* **claude-code-guide:** add Claude Code expert consultant ([aa58aae](https://github.com/blueraai/bluera-base/commit/aa58aaeb3bb3a302449b88aa15d6b60a4f5b7132))
* **commands:** add argument-hint frontmatter ([201722e](https://github.com/blueraai/bluera-base/commit/201722e7d9c1c8e0905ffc3fd84d7f17ae0b32cb))
* **create:** add plugin component generator command ([676ba55](https://github.com/blueraai/bluera-base/commit/676ba55aabbe87cd6565b3a8d75517b708f02f6a))
* **create:** integrate claude-code-guide expert consultation ([f199543](https://github.com/blueraai/bluera-base/commit/f199543e0a19eb84ee6da87be20bdc57474208de))

### Bug Fixes

* **hooks:** add **BLUERA_TEST** bypass and fix checklist grep ([7e8ee19](https://github.com/blueraai/bluera-base/commit/7e8ee199120b75c3c6e3bac04070e41cc1d6db2a))
* **hooks:** address audit findings ([74246df](https://github.com/blueraai/bluera-base/commit/74246df1bd3a6cc2f36ff85cb287f989fed92a21))

## [0.26.0](https://github.com/blueraai/bluera-base/compare/v0.24.0...v0.26.0) (2026-02-02)

### Features

* **claude-code-guide:** add audit command for Claude Code best practices ([9ca81a3](https://github.com/blueraai/bluera-base/commit/9ca81a32ce0041ea78b62df7e12087779268704c))
* **claude-code-guide:** add Claude Code expert consultant ([aa58aae](https://github.com/blueraai/bluera-base/commit/aa58aaeb3bb3a302449b88aa15d6b60a4f5b7132))
* **create:** add plugin component generator command ([676ba55](https://github.com/blueraai/bluera-base/commit/676ba55aabbe87cd6565b3a8d75517b708f02f6a))
* **create:** integrate claude-code-guide expert consultation ([f199543](https://github.com/blueraai/bluera-base/commit/f199543e0a19eb84ee6da87be20bdc57474208de))

### Bug Fixes

* **hooks:** add **BLUERA_TEST** bypass and fix checklist grep ([7e8ee19](https://github.com/blueraai/bluera-base/commit/7e8ee199120b75c3c6e3bac04070e41cc1d6db2a))

## [0.25.0](https://github.com/blueraai/bluera-base/compare/v0.24.0...v0.25.0) (2026-02-02)

### Features

* **claude-code-guide:** add Claude Code expert consultant ([aa58aae](https://github.com/blueraai/bluera-base/commit/aa58aaeb3bb3a302449b88aa15d6b60a4f5b7132))
* **create:** add plugin component generator command ([676ba55](https://github.com/blueraai/bluera-base/commit/676ba55aabbe87cd6565b3a8d75517b708f02f6a))
* **create:** integrate claude-code-guide expert consultation ([f199543](https://github.com/blueraai/bluera-base/commit/f199543e0a19eb84ee6da87be20bdc57474208de))

### Bug Fixes

* **hooks:** add **BLUERA_TEST** bypass and fix checklist grep ([7e8ee19](https://github.com/blueraai/bluera-base/commit/7e8ee199120b75c3c6e3bac04070e41cc1d6db2a))

## [0.24.1](https://github.com/blueraai/bluera-base/compare/v0.24.0...v0.24.1) (2026-02-02)

### Bug Fixes

* **hooks:** add **BLUERA_TEST** bypass and fix checklist grep ([7e8ee19](https://github.com/blueraai/bluera-base/commit/7e8ee199120b75c3c6e3bac04070e41cc1d6db2a))

## [0.24.0](https://github.com/blueraai/bluera-base/compare/v0.21.4...v0.24.0) (2026-02-02)

### Features

* **checklist:** add dynamic context injection ([111c1ac](https://github.com/blueraai/bluera-base/commit/111c1ac3706dfb0f00b4e4d0ae662aaff0eca450))
* **checklist:** add project checklist with session start reminder ([bbd2e73](https://github.com/blueraai/bluera-base/commit/bbd2e730ed516b8af996ac49175da2f12f8c1878))
* **learn:** add extract command for manual mid-session analysis ([3b6991b](https://github.com/blueraai/bluera-base/commit/3b6991bdf78ca70201dde0f80e877e0cda0783d9))
* **readme:** add audit option to check docs against codebase ([5179153](https://github.com/blueraai/bluera-base/commit/517915362420f61779ad624d91bdeb6775ad781e))
* **test-plugin:** add context:fork and checklist tests ([a2498da](https://github.com/blueraai/bluera-base/commit/a2498dadc10c7625975d248b9e500dfa91aa2eef))
* **test-plugin:** expand to full API coverage (41 tests) ([4a2f271](https://github.com/blueraai/bluera-base/commit/4a2f2717861abced877db060560a38a75f27f06d))

### Bug Fixes

* **hooks:** apply defensive cat pattern to PreToolUse hooks ([06a711e](https://github.com/blueraai/bluera-base/commit/06a711ef21f32d584e902bd289c6450a03759861))
* **hooks:** escape sed metacharacters and use POSIX grep patterns ([9027071](https://github.com/blueraai/bluera-base/commit/9027071a100feb239d92910cd2387712b1672163))
* **hooks:** make gitignore pattern appending idempotent ([144af64](https://github.com/blueraai/bluera-base/commit/144af64020102b625ac9b121e9138e5a8940892f))
* **hooks:** prevent stdin blocking in Stop hooks ([5eea8b3](https://github.com/blueraai/bluera-base/commit/5eea8b399bacdd33f6143edb31b77e9182fe7309))
* **hooks:** sanitize newlines in transcript content extraction ([7a06ca4](https://github.com/blueraai/bluera-base/commit/7a06ca4fe2b294cab04dac46038d43e9f56d7f65))

## [0.23.2](https://github.com/blueraai/bluera-base/compare/v0.21.4...v0.23.2) (2026-02-01)

### Features

* **learn:** add extract command for manual mid-session analysis ([3b6991b](https://github.com/blueraai/bluera-base/commit/3b6991bdf78ca70201dde0f80e877e0cda0783d9))
* **readme:** add audit option to check docs against codebase ([5179153](https://github.com/blueraai/bluera-base/commit/517915362420f61779ad624d91bdeb6775ad781e))

### Bug Fixes

* **hooks:** escape sed metacharacters and use POSIX grep patterns ([9027071](https://github.com/blueraai/bluera-base/commit/9027071a100feb239d92910cd2387712b1672163))
* **hooks:** make gitignore pattern appending idempotent ([144af64](https://github.com/blueraai/bluera-base/commit/144af64020102b625ac9b121e9138e5a8940892f))
* **hooks:** sanitize newlines in transcript content extraction ([7a06ca4](https://github.com/blueraai/bluera-base/commit/7a06ca4fe2b294cab04dac46038d43e9f56d7f65))

## [0.23.1](https://github.com/blueraai/bluera-base/compare/v0.21.4...v0.23.1) (2026-02-01)

### Features

* **learn:** add extract command for manual mid-session analysis ([3b6991b](https://github.com/blueraai/bluera-base/commit/3b6991bdf78ca70201dde0f80e877e0cda0783d9))
* **readme:** add audit option to check docs against codebase ([5179153](https://github.com/blueraai/bluera-base/commit/517915362420f61779ad624d91bdeb6775ad781e))

### Bug Fixes

* **hooks:** escape sed metacharacters and use POSIX grep patterns ([9027071](https://github.com/blueraai/bluera-base/commit/9027071a100feb239d92910cd2387712b1672163))
* **hooks:** sanitize newlines in transcript content extraction ([7a06ca4](https://github.com/blueraai/bluera-base/commit/7a06ca4fe2b294cab04dac46038d43e9f56d7f65))

## [0.23.0](https://github.com/blueraai/bluera-base/compare/v0.21.4...v0.23.0) (2026-02-01)

### Features

* **learn:** add extract command for manual mid-session analysis ([3b6991b](https://github.com/blueraai/bluera-base/commit/3b6991bdf78ca70201dde0f80e877e0cda0783d9))
* **readme:** add audit option to check docs against codebase ([5179153](https://github.com/blueraai/bluera-base/commit/517915362420f61779ad624d91bdeb6775ad781e))

### Bug Fixes

* **hooks:** escape sed metacharacters and use POSIX grep patterns ([9027071](https://github.com/blueraai/bluera-base/commit/9027071a100feb239d92910cd2387712b1672163))
* **hooks:** sanitize newlines in transcript content extraction ([7a06ca4](https://github.com/blueraai/bluera-base/commit/7a06ca4fe2b294cab04dac46038d43e9f56d7f65))

## [0.22.0](https://github.com/blueraai/bluera-base/compare/v0.21.4...v0.22.0) (2026-02-01)

### Features

* **learn:** add extract command for manual mid-session analysis ([3b6991b](https://github.com/blueraai/bluera-base/commit/3b6991bdf78ca70201dde0f80e877e0cda0783d9))

### Bug Fixes

* **hooks:** sanitize newlines in transcript content extraction ([7a06ca4](https://github.com/blueraai/bluera-base/commit/7a06ca4fe2b294cab04dac46038d43e9f56d7f65))

## [0.21.4](https://github.com/blueraai/bluera-base/compare/v0.21.3...v0.21.4) (2026-02-01)

## [0.21.3](https://github.com/blueraai/bluera-base/compare/v0.21.2...v0.21.3) (2026-02-01)

## [0.21.2](https://github.com/blueraai/bluera-base/compare/v0.21.1...v0.21.2) (2026-02-01)

### Bug Fixes

* **commands:** restore command files required for plugin slash commands ([5724594](https://github.com/blueraai/bluera-base/commit/5724594ba3e7a8b0a1896166b2c4364099acc5eb))

## [0.21.1](https://github.com/blueraai/bluera-base/compare/v0.21.0...v0.21.1) (2026-02-01)

### Bug Fixes

* **hooks:** improve robustness with atomic locking and error handling ([52b1d22](https://github.com/blueraai/bluera-base/commit/52b1d22f6945622232faab0d1e123d6cb86f03ad))
* **scripts:** add path validation and error handling to cleaner ([74eb885](https://github.com/blueraai/bluera-base/commit/74eb88574f87eb7bb9e89571603763a186f8c340))

## [0.21.0](https://github.com/blueraai/bluera-base/compare/v0.20.0...v0.21.0) (2026-02-01)

### Features

* **commands:** expose worktree, learn, large-file-refactor as slash commands ([4d32de8](https://github.com/blueraai/bluera-base/commit/4d32de8de5c7b45f8fae2f8396000ef4ed3b9225)), closes [#17271](https://github.com/blueraai/bluera-base/issues/17271)

## [0.20.0](https://github.com/blueraai/bluera-base/compare/v0.19.0...v0.20.0) (2026-02-01)

### Features

* **config:** add interactive toggle UI for feature settings ([e48f4f5](https://github.com/blueraai/bluera-base/commit/e48f4f5c07253f88102edb46e028db03d372af75))

## [0.19.0](https://github.com/blueraai/bluera-base/compare/v0.18.0...v0.19.0) (2026-02-01)

### Features

* **hooks:** add deep learning for semantic session analysis ([ac42b22](https://github.com/blueraai/bluera-base/commit/ac42b220d8621d0a1b5fdac9b1b42a5cd9a09a05))

### Bug Fixes

* **scripts:** add strict type annotations to cc-cleaner-scan.py ([bd73757](https://github.com/blueraai/bluera-base/commit/bd73757bd332285f6277a0f369952029bd598515))

## [0.18.0](https://github.com/blueraai/bluera-base/compare/v0.17.0...v0.18.0) (2026-02-01)

### Features

* **hooks:** add standards-review hook for pre-commit validation ([d6b901b](https://github.com/blueraai/bluera-base/commit/d6b901bbc54cc2c1b21abb4a517b3bfdfbfdb10a))

## [0.17.0](https://github.com/blueraai/bluera-base/compare/v0.16.1...v0.17.0) (2026-01-31)

### Features

* **commands:** add context: fork to heavy commands ([4c1f134](https://github.com/blueraai/bluera-base/commit/4c1f1343e528207e24c20676e3345500c9397f89))
* **skills:** add allowed-tools frontmatter for bounded tool access ([e549e61](https://github.com/blueraai/bluera-base/commit/e549e6138734ef9d0e650d3a2fc203b624c833f9))

### Bug Fixes

* address CODEX-17 documentation and code issues ([d2d286a](https://github.com/blueraai/bluera-base/commit/d2d286a65d20024328af178d9e7b8c523d8c20b1))
* address CODEX-ANALYSIS-28 issues (CODEX-28) ([eabcd82](https://github.com/blueraai/bluera-base/commit/eabcd827d737baf7544345809b120c606861e1d2))
* address CODEX-ANALYSIS-29 issues (CODEX-29) ([cfd4f0b](https://github.com/blueraai/bluera-base/commit/cfd4f0b8634fdc5a4c1befc1fb9fa8e432b864d7))
* address CODEX-ANALYSIS-30 issues (CODEX-30) ([64eb1e4](https://github.com/blueraai/bluera-base/commit/64eb1e4ae025aede7daa4bb18d6dfd639e9c655f))
* address CODEX-ANALYSIS-31 issues (CODEX-31) ([b76cf00](https://github.com/blueraai/bluera-base/commit/b76cf00cd605c7b55bcdb7ccbf10a29aee4a3680))
* address CODEX-ANALYSIS-32 issues (CODEX-32) ([4417189](https://github.com/blueraai/bluera-base/commit/4417189c62e70acc4155e7d86247e34af5885a8a))
* address CODEX-ANALYSIS-33 issues (CODEX-33) ([40e947a](https://github.com/blueraai/bluera-base/commit/40e947ab41e9e71c1484574a5c63ce211591f152))
* address CODEX-ANALYSIS-34 issues (CODEX-34) ([345bf5d](https://github.com/blueraai/bluera-base/commit/345bf5d1852c29da776367c9b016930e125a18d2))
* address CODEX-ANALYSIS-35 issues (CODEX-35) ([e401bb7](https://github.com/blueraai/bluera-base/commit/e401bb79972277a424cbef496effd1c24a72fc68))
* address CODEX-ANALYSIS-36 issues (CODEX-36) ([22e2249](https://github.com/blueraai/bluera-base/commit/22e2249dc86064303c821d60839ce312ec67eed1))
* address CODEX-ANALYSIS-37 issues (CODEX-37) ([3e21d7c](https://github.com/blueraai/bluera-base/commit/3e21d7c945a80ecd8abe27222ba64e268f84d880))
* address CODEX-ANALYSIS-8 tool restrictions and doc mismatches ([1f77bd8](https://github.com/blueraai/bluera-base/commit/1f77bd8bde93800e87d58ce16e850756403ace59))
* convert PCRE patterns to POSIX ERE for cross-platform compatibility ([790c2b9](https://github.com/blueraai/bluera-base/commit/790c2b95231246509bc0056aa55c80841e932c59))
* **gitignore:** fully ignore .bluera/ in plugin source repo ([00f1c93](https://github.com/blueraai/bluera-base/commit/00f1c9320cc9020d043c9bafe1ae6d8d4847f242))
* md5 macOS hash extraction, tighten lint/typecheck detection ([236c69a](https://github.com/blueraai/bluera-base/commit/236c69afe5b1a5fe822ce7752b8e9ca0ca2436b2))
* **readme:** never remove content, only reorganize ([a40faad](https://github.com/blueraai/bluera-base/commit/a40faad06338f2b9dbc5748b3535093d5a9aa985))
* release-block bypasses and gitignore pattern structure ([5310350](https://github.com/blueraai/bluera-base/commit/53103507019dd193d3bad1ba491349f5e99160bd))
* strict typing regex, auto-commit wording, pre-compact guidance ([1865071](https://github.com/blueraai/bluera-base/commit/18650710640d3e6d8a4832b9cb397ff44f9b6208))
* **templates:** correct plugin.json path to .claude-plugin directory ([2b5b891](https://github.com/blueraai/bluera-base/commit/2b5b891623a3ced89acab6144ecfde6444e6908b))
* Windows compatibility and documentation fixes from CODEX analysis ([bbce755](https://github.com/blueraai/bluera-base/commit/bbce755750f7f4108b3f3fcd220527ed9d4a4285))
* wire up config toggles and fix consistency issues (CODEX-27) ([46a5ba4](https://github.com/blueraai/bluera-base/commit/46a5ba496c962dd9a9a0bb29e789fe796b5706aa))
* YAML frontmatter scope, gitignore patterns, rate limit collision ([8069027](https://github.com/blueraai/bluera-base/commit/80690271405a9a3d68d5dee69f43c8b6b5fc2de7))

## [0.16.1](https://github.com/blueraai/bluera-base/compare/v0.16.0...v0.16.1) (2026-01-19)

### Bug Fixes

* **hooks:** return 0 when gitignore patterns already exist ([cab9556](https://github.com/blueraai/bluera-base/commit/cab955662b76a27c98ecd66264eb3039d42ca2f4))

## [0.16.0](https://github.com/blueraai/bluera-base/compare/v0.15.0...v0.16.0) (2026-01-19)

### Features

* **claude-md:** add reliability and scope documentation ([dd8110b](https://github.com/blueraai/bluera-base/commit/dd8110b5892e98a46cd587729d3e6597b6eb6394))
* **claude-md:** add verbosity audit and WHAT/WHY/HOW structure ([ef06446](https://github.com/blueraai/bluera-base/commit/ef06446865e2ca42f4c72eeaf1057599adcc3a4f))

## [0.15.0](https://github.com/blueraai/bluera-base/compare/v0.14.2...v0.15.0) (2026-01-18)

### Features

* **auto-learn:** implement auto mode and target configuration ([12a1953](https://github.com/blueraai/bluera-base/commit/12a19530edf1a660a8a4909c3e512f4994f4f572))

## [0.14.2](https://github.com/blueraai/bluera-base/compare/v0.14.1...v0.14.2) (2026-01-18)

### Features

* **statusline:** add timestamped backup before overwriting ([8a83977](https://github.com/blueraai/bluera-base/commit/8a839779d87839fd78dfdc067530e1c545371365))

## [0.14.1](https://github.com/blueraai/bluera-base/compare/v0.14.0...v0.14.1) (2026-01-18)

### Features

* **clean:** harden safety with preview mode and centralized backups ([5dce3fb](https://github.com/blueraai/bluera-base/commit/5dce3fb3bf67eb6aa192e9346c28090ce5b20c57))
* **notify:** add project name to notifications and icon support ([eef953a](https://github.com/blueraai/bluera-base/commit/eef953a0fe6543cc9df6b10aeeee259e7ecbbaa6))

### Bug Fixes

* **notify:** use claude.png icon filename ([3e7342b](https://github.com/blueraai/bluera-base/commit/3e7342bf04bba1a64183bdaa116cca28c8851f84))

## [0.14.0](https://github.com/blueraai/bluera-base/compare/v0.13.0...v0.14.0) (2026-01-18)

### Features

* **cleaner:** add Claude Code Cleaner for diagnosing slow startup ([f9914dd](https://github.com/blueraai/bluera-base/commit/f9914dda5d24cef513441d4ee5c5d981c90ee9cc))
* **config:** add interactive init workflow with feature explanations ([65667c1](https://github.com/blueraai/bluera-base/commit/65667c1d50631c0c5cb6bc5d47f71e1ab46f0b97))
* **statusline:** add preset previews, bluera preset, and ready-to-use scripts ([ea2bde6](https://github.com/blueraai/bluera-base/commit/ea2bde64e753ce4100621f549ca75f17789679dd))

### Bug Fixes

* **readme:** remove @ from mermaid diagram label ([8f4d1df](https://github.com/blueraai/bluera-base/commit/8f4d1df878a417548d79373480b9def5ae45ebde))

## [0.13.0](https://github.com/blueraai/bluera-base/compare/v0.12.1...v0.13.0) (2026-01-17)

### Features

* **.claude:** add repo-specific test-plugin reminder hook ([b5dc2c4](https://github.com/blueraai/bluera-base/commit/b5dc2c43fc9ee881be12231904ed9af19ec37828))
* **release:** add detection script to prefer project scripts ([af7175c](https://github.com/blueraai/bluera-base/commit/af7175c73aa67c18332d5c7c2a6778a06b83ccb9))

## [0.12.1](https://github.com/blueraai/bluera-base/compare/v0.12.0...v0.12.1) (2026-01-17)

## [0.12.0](https://github.com/blueraai/bluera-base/compare/v0.11.7...v0.12.0) (2026-01-17)

### Features

* **init:** add project initialization wizard ([c06869a](https://github.com/blueraai/bluera-base/commit/c06869a949aa9e6f8a41de565d0828f6f9c84ece))

### Bug Fixes

* **release:** monitor ALL workflows by commit SHA ([ceb0648](https://github.com/blueraai/bluera-base/commit/ceb06483a129a1f394667bc2fd067d47813114b8))

## [0.11.7](https://github.com/blueraai/bluera-base/compare/v0.11.6...v0.11.7) (2026-01-17)

### Bug Fixes

* **readme:** restore nested ToC items with linter-friendly anchors ([4c92dd5](https://github.com/blueraai/bluera-base/commit/4c92dd5fefc35c24d56411d8e85ac573a73c678d))

## [0.11.6](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.6) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** detect task runner independently of language ([8607130](https://github.com/blueraai/bluera-base/commit/8607130b783858e0f845efcee9dc6104aba414a9))
* **harden-repo:** distinguish coverage tool vs threshold configuration ([90a8bde](https://github.com/blueraai/bluera-base/commit/90a8bde0444b77f07d0e460651793db2c3a2e5ad))
* **harden-repo:** handle repos with no task runner (uv/pytest direct) ([aa89ef9](https://github.com/blueraai/bluera-base/commit/aa89ef9759938229067ab424f2c22d6af9c75d48))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.5](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.5) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** detect task runner independently of language ([8607130](https://github.com/blueraai/bluera-base/commit/8607130b783858e0f845efcee9dc6104aba414a9))
* **harden-repo:** handle repos with no task runner (uv/pytest direct) ([aa89ef9](https://github.com/blueraai/bluera-base/commit/aa89ef9759938229067ab424f2c22d6af9c75d48))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.4](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.4) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** detect task runner independently of language ([8607130](https://github.com/blueraai/bluera-base/commit/8607130b783858e0f845efcee9dc6104aba414a9))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.3](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.3) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add explicit coverage setup steps for each language ([2670e3b](https://github.com/blueraai/bluera-base/commit/2670e3b3f0634cafb2aa9eeaa8fa58d792e93cd2))
* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.2](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.2) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))
* **harden-repo:** require user input before lowering coverage threshold ([224c419](https://github.com/blueraai/bluera-base/commit/224c419c12149a5ef07b18190b6b2f75a640fee8))

## [0.11.1](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.1) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

### Bug Fixes

* **harden-repo:** add Phase 0 to detect gaps in existing hardening ([f6ae8f2](https://github.com/blueraai/bluera-base/commit/f6ae8f268e67d366144467c29d21e2cccebdbfe9))

## [0.11.0](https://github.com/blueraai/bluera-base/compare/v0.10.2...v0.11.0) (2026-01-17)

### Features

* **harden-repo:** add test coverage and expand to 13 languages ([4a7ef7f](https://github.com/blueraai/bluera-base/commit/4a7ef7fae104991aa15fea6b39d9f4274dde06ed))

## [0.10.2](https://github.com/blueraai/bluera-base/compare/v0.10.1...v0.10.2) (2026-01-17)

### Bug Fixes

* **hooks:** use fully qualified command names in messages ([c7018eb](https://github.com/blueraai/bluera-base/commit/c7018eb4681284880be7449de9b8dece0ef1ab28))

## [0.10.1](https://github.com/blueraai/bluera-base/compare/v0.10.0...v0.10.1) (2026-01-17)

### Bug Fixes

* **explain:** add Algorithm section to ensure output is displayed ([afdd864](https://github.com/blueraai/bluera-base/commit/afdd864c6c03ebdfa579abdbb386a3c1707e6964))

## [0.10.0](https://github.com/blueraai/bluera-base/compare/v0.9.2...v0.10.0) (2026-01-17)

### Features

* **config:** add self-documenting output for show command ([af6b12b](https://github.com/blueraai/bluera-base/commit/af6b12bfb405f20a8118ddd8ce45fb42ac610750))
* **explain:** add /bluera-base:explain command ([80cf30d](https://github.com/blueraai/bluera-base/commit/80cf30d2d2450f6a9c973c4e520dbf9e99724086))
* **lib:** add signals and state library abstractions ([15eb013](https://github.com/blueraai/bluera-base/commit/15eb013f7699355bf49a8650e2eadd6d46fd130b))
* **todo:** add /bluera-base:todo command for task management ([e0bc330](https://github.com/blueraai/bluera-base/commit/e0bc330a8d3d4d403114d2286609ec166e33dfd0))

### Bug Fixes

* **test-plugin:** update counts and add library unit tests ([588c2ca](https://github.com/blueraai/bluera-base/commit/588c2caa82a12a97b1619f70e6280e18225ba9f0))

## [0.9.2](https://github.com/blueraai/bluera-base/compare/v0.9.1...v0.9.2) (2026-01-16)

### Bug Fixes

* **release:** correct shell command parsing in backtick context ([fd6e56b](https://github.com/blueraai/bluera-base/commit/fd6e56b81a9ba94f13086f3d4034537763e8dc79))

## [0.9.1](https://github.com/blueraai/bluera-base/compare/v0.9.0...v0.9.1) (2026-01-16)

## [0.9.0](https://github.com/blueraai/bluera-base/compare/v0.8.1...v0.9.0) (2026-01-16)

### Features

* **settings:** add narrowly scoped permission templates ([b43e813](https://github.com/blueraai/bluera-base/commit/b43e813e9c168ed4672853a12977f5985dddccc5))

## [0.8.1](https://github.com/blueraai/bluera-base/compare/v0.8.0...v0.8.1) (2026-01-16)

### Bug Fixes

* **hooks:** add JSON validation to learning hooks ([16ab3eb](https://github.com/blueraai/bluera-base/commit/16ab3eb02d0d7ce60268dc59c392f88e1db7b6ad))

## [0.8.0](https://github.com/blueraai/bluera-base/compare/v0.7.0...v0.8.0) (2026-01-16)

### Features

* **hooks:** add lint suppression and strict typing checks ([ad43a56](https://github.com/blueraai/bluera-base/commit/ad43a5636066c34048711fc2945a7cdec43800fa))
* **hooks:** add repo hardening with husky, lint-staged, markdownlint ([b0cf141](https://github.com/blueraai/bluera-base/commit/b0cf141075bed228f777418ecdc4c8c6bd5ee479))

### Bug Fixes

* **changelog:** remove duplicate header content ([3daced2](https://github.com/blueraai/bluera-base/commit/3daced21835e011634a85153336a01fb5dc9e20d))
* **hooks:** move observe-learning to PreToolUse for reliable triggering ([8329865](https://github.com/blueraai/bluera-base/commit/83298653e67ebd46b2c2b12bca5378edca7c8a4f))
* quiet lint-staged output and fix hook schema ([45a4bd1](https://github.com/blueraai/bluera-base/commit/45a4bd199970ef3ea0b4b200d389f1c27bf06bcd))

## [0.7.0](https://github.com/blueraai/bluera-base/compare/v0.6.0...v0.7.0) (2026-01-16)

### Features

* **hooks:** add auto-commit hook for session-stop commits ([2645fad](https://github.com/blueraai/bluera-base/commit/2645fad9cd6de36770be731938aee114230c1f73))

## [0.3.0](https://github.com/blueraai/bluera-base/compare/v0.2.3...v0.3.0) (2026-01-16)

### Features

* add /readme command for README.md maintenance ([6ec3abe](https://github.com/blueraai/bluera-base/commit/6ec3abe55adf3cce8c95c3c9ec4b556568d8b4cb))
* **readme:** add breakout subcommand for splitting large READMEs ([a46a12a](https://github.com/blueraai/bluera-base/commit/a46a12a501de7f3dc9c61b64e5bd2ac7e5552144))

### Bug Fixes

* **mermaid:** remove theme config causing GitHub truncation ([4bbdb73](https://github.com/blueraai/bluera-base/commit/4bbdb73ab007f196bfcb1f2ceae5fec815818800))
* **mermaid:** restore node colors using style directives ([34640bb](https://github.com/blueraai/bluera-base/commit/34640bb31ebbcce29b914f544e70169dbdf84ea1))
* **mermaid:** shorten diagram labels to prevent GitHub truncation ([e9c2d2b](https://github.com/blueraai/bluera-base/commit/e9c2d2bfafb80558fbbfddb94ab06045233c3d43))
* **release:** enforce CI-before-tag workflow ([dfdb1b9](https://github.com/blueraai/bluera-base/commit/dfdb1b9b97db18a0aad2fa2938108d80f2188f5c))
* **release:** fetch tags before showing current version ([f0318de](https://github.com/blueraai/bluera-base/commit/f0318de655ce65b8136709c7403efcfb54ed9d91))

## [0.2.3](https://github.com/blueraai/bluera-base/compare/v0.2.2...v0.2.3) (2026-01-15)

## [0.2.2](https://github.com/blueraai/bluera-base/compare/v0.2.1...v0.2.2) (2026-01-15)

## [0.2.1](https://github.com/blueraai/bluera-base/compare/v0.2.0...v0.2.1) (2026-01-15)

### Bug Fixes

* **hooks:** remove unused RED variable in session-setup.sh ([bbb73ab](https://github.com/blueraai/bluera-base/commit/bbb73abd7ee6f6700e91ed2db4814532ed9aef07))

## 0.2.0 (2026-01-15)

### Features

* add CLAUDE.md maintainer command and skill ([811ed07](https://github.com/blueraai/bluera-base/commit/811ed07c2db16a3088c2936edac76ca940ddd483))
* add rule templates and /install-rules command ([f7f3532](https://github.com/blueraai/bluera-base/commit/f7f3532888bd8112e35819f6b89645b6ac7c2c0a))
* **hooks:** add SessionStart hook and cross-platform notifications ([a6e7e56](https://github.com/blueraai/bluera-base/commit/a6e7e5639a32e307081cd66c6bd17de86b86444c))
* initial bluera-base plugin ([451b099](https://github.com/blueraai/bluera-base/commit/451b099e7ebd455411592658bfeab623a98e858d))

### Bug Fixes

* add local_CLAUDE.local.md template ([f590cea](https://github.com/blueraai/bluera-base/commit/f590cea03ad6f2b3083afccd39cb9683e9c4e160))
* **commit:** enforce mandatory workflow steps ([df25d57](https://github.com/blueraai/bluera-base/commit/df25d57478f82e59592103b66f15b10b934f0eb7))
* **commit:** simplify to match working zark-backend pattern ([95d9438](https://github.com/blueraai/bluera-base/commit/95d9438195fbf6f98ade67c6988c02a622a7f1c9))
* **hooks:** critical bug fixes for hook reliability ([7d5540a](https://github.com/blueraai/bluera-base/commit/7d5540ae71f8681a09a77e0eed3640d9a63c7d32))
* **hooks:** remove pathspec excludes causing git errors ([e279361](https://github.com/blueraai/bluera-base/commit/e279361205a7e517b0e48dcc8f44713cfb82a38e))
* **hooks:** resolve shellcheck warnings ([255db02](https://github.com/blueraai/bluera-base/commit/255db0272e041c669eb741251e477ae0701a6bac))
