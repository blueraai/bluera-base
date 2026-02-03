# Anti-Patterns

Hook-enforced (exit 2 blocks + stderr feedback to Claude):

- Fallback/graceful degradation
- Backward compatibility shims
- Legacy/deprecated code
- Lint rule suppression

Strict typing (when enabled): No `any`/`Any`, unsafe `as` casts, unexplained `@ts-ignore`.

Escape: `// ok:` or `# ok:` with explanation.
