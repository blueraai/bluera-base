# Anti-Patterns

Patterns that are explicitly forbidden.

## Never Write

- **Fallback code**: No "graceful degradation" unless part of specification
- **Default behaviors**: Don't invent defaults that aren't specified
- **Backward compatibility shims**: If changing code, change it completely
- **Legacy support**: Old patterns should be migrated, not maintained alongside new ones
- **Deprecated implementations**: Don't reference or keep deprecated code

## Why

These patterns hide bugs, bloat context, and create maintenance burden. Code should either work as designed or fail visibly.
