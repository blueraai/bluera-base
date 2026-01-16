# Language-Specific Breakout Patterns

## Rust

### Pattern: Directory Module

Convert single file to directory with submodules.

**Before**:
```
src/
└── policies.rs  (3000 lines)
```

**After**:
```
src/
└── policies/
    ├── mod.rs           # Re-exports, shared types
    ├── user_policies.rs # User-related policies
    ├── auth_policies.rs # Auth-related policies
    └── validation.rs    # Validation helpers
```

**mod.rs structure**:
```rust
mod user_policies;
mod auth_policies;
mod validation;

// Re-export public items
pub use user_policies::*;
pub use auth_policies::*;
pub use validation::validate_policy;

// Shared types stay here
pub struct PolicyContext { ... }
```

### Pattern: Sibling Module

For loosely related code.

**Before**: `lib.rs` with mixed concerns

**After**:
```rust
// lib.rs
mod types;
mod handlers;
mod utils;

pub use types::*;
pub use handlers::*;
```

### Rust Gotchas

- Update `mod` declarations in parent
- Use `pub(crate)` for internal-only exports
- Watch for orphan rule violations when moving trait impls

---

## TypeScript

### Pattern: Barrel Export (index.ts)

**Before**:
```
src/
└── services.ts  (2000 lines)
```

**After**:
```
src/
└── services/
    ├── index.ts         # Re-exports
    ├── userService.ts
    ├── authService.ts
    └── types.ts
```

**index.ts**:
```typescript
export * from './userService';
export * from './authService';
export type * from './types';
```

### Pattern: Feature Folders

For React/component code:

```
src/
└── features/
    └── auth/
        ├── index.ts
        ├── AuthProvider.tsx
        ├── useAuth.ts
        ├── authService.ts
        └── types.ts
```

### TypeScript Gotchas

- Update import paths (use path aliases if available)
- Check for circular imports (common with shared types)
- Ensure tree-shaking still works (avoid re-exporting everything)

---

## Python

### Pattern: Package Structure

**Before**:
```
src/
└── handlers.py  (2500 lines)
```

**After**:
```
src/
└── handlers/
    ├── __init__.py      # Re-exports
    ├── user_handlers.py
    ├── auth_handlers.py
    └── base.py          # Shared base classes
```

**__init__.py**:
```python
from .user_handlers import UserHandler, create_user
from .auth_handlers import AuthHandler, login, logout
from .base import BaseHandler

__all__ = [
    'UserHandler', 'create_user',
    'AuthHandler', 'login', 'logout',
    'BaseHandler',
]
```

### Pattern: Subpackage

For deeply nested code:

```python
# myapp/services/__init__.py
from .user import UserService
from .auth import AuthService

# myapp/services/user/__init__.py
from .service import UserService
from .repository import UserRepository
```

### Python Gotchas

- Circular imports are common - use TYPE_CHECKING guard
- Update relative imports (`.module` vs `..module`)
- Check `__all__` exports match actual usage

---

## Go

### Pattern: Multiple Files Same Package

Go naturally supports multiple files in one package.

**Before**:
```
pkg/
└── service.go  (3000 lines)
```

**After**:
```
pkg/
├── service.go       # Main entry, shared types
├── user.go          # User operations
├── auth.go          # Auth operations
└── validation.go    # Validation functions
```

**Key**: All files declare same package:
```go
package pkg
```

No explicit imports needed between files in same package.

### Pattern: Subpackage

For distinct concerns:

```
pkg/
├── service.go
└── internal/
    ├── validation/
    │   └── validation.go
    └── cache/
        └── cache.go
```

### Go Gotchas

- No circular package imports allowed
- `internal/` packages restrict visibility
- Init functions run per-file (watch for order dependencies)

---

## General Breakout Rules

### What to Keep Together

1. Type + all its methods
2. Interface + primary implementation
3. Tightly coupled functions (one calls the other)
4. Test file with its tested code

### What to Split

1. Different domains (user vs auth vs billing)
2. Different layers (handler vs service vs repository)
3. Utilities vs core logic
4. Generated code vs hand-written

### Naming Conventions

| Pattern | Example |
|---------|---------|
| By domain | `user_service.rs`, `auth_service.rs` |
| By layer | `handlers.rs`, `repository.rs` |
| By type | `types.rs`, `errors.rs` |
| By feature | `create_user.rs`, `delete_user.rs` |

### Export Strategy

1. **Preserve public API**: External callers shouldn't change imports
2. **Re-export from root**: `mod.rs`, `index.ts`, `__init__.py`
3. **Minimize surface**: Only export what's needed
