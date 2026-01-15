# Base Rules

Core development principles for all code.

## Fail Fast

- Use `throw` for unexpected state or error conditions
- Never silently swallow errors
- Errors should be visible and actionable

## Strict Typing

- 100% strict typing; no `any`, no `as` casts unless completely unavoidable
- Type assertions require justification in comments
- Prefer type inference where unambiguous

## Clean Code

- No commented-out code in committed files
- No references to outdated or deprecated implementations
- Remove unused code; don't leave it "for reference"
