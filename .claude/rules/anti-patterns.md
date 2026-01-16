# Anti-Patterns

Patterns that are explicitly forbidden.

## Never Write

- **Fallback code**: No "graceful degradation" unless part of specification
- **Default behaviors**: Don't invent defaults that aren't specified
- **Backward compatibility shims**: If changing code, change it completely
- **Legacy support**: Old patterns should be migrated, not maintained alongside new ones
- **Deprecated implementations**: Don't reference or keep deprecated code

## Strict Typing (when enabled via `/bluera-base:config enable strict-typing`)

### TypeScript/JavaScript

- **`any` type**: Use specific types, generics, or `unknown`
- **`as` casts**: Use type guards or fix the types (except `as const`)
- **`@ts-ignore`**: Requires 10+ char explanation; prefer fixing the type
- **`@ts-nocheck`**: Always forbidden

### Python

- **`Any` type**: Use specific types, generics, `TypeVar`, or `object`
- **`# type: ignore`**: Requires error code `[code]`
- **`cast()`**: Use type guards or fix the types

### Escape Hatch

Add `// ok:` (TS) or `# ok:` (Python) comment to suppress on specific lines when truly unavoidable.

## Why

These patterns hide bugs, bloat context, and create maintenance burden. Code should either work as designed or fail visibly. Strict typing catches errors at write-time instead of runtime.
