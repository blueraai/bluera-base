# Language-Specific DRY Patterns

Detailed extraction patterns for each supported language.

---

## JavaScript / TypeScript

### Pattern: Module Export with Barrel

**Before** (duplicated validation in two handlers):

```typescript
// handlers/user.ts
function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
export function createUser(data: UserInput) {
  if (!validateEmail(data.email)) throw new Error("Invalid email");
  // ...
}

// handlers/admin.ts
function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
export function createAdmin(data: AdminInput) {
  if (!validateEmail(data.email)) throw new Error("Invalid email");
  // ...
}
```

**After**:

```typescript
// utils/validators.ts
export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

// utils/index.ts (barrel export)
export * from './validators';

// handlers/user.ts
import { validateEmail } from '../utils';
export function createUser(data: UserInput) {
  if (!validateEmail(data.email)) throw new Error("Invalid email");
  // ...
}
```

### Pattern: Shared Types

```typescript
// types/common.ts
export interface Identifiable {
  id: string;
  createdAt: Date;
  updatedAt: Date;
}

// models/user.ts
import type { Identifiable } from '../types/common';
export interface User extends Identifiable {
  email: string;
  name: string;
}
```

### Pattern: Higher-Order Functions

```typescript
// Before: repeated try/catch patterns
async function getUser(id: string) {
  try {
    return await db.users.findUnique({ where: { id } });
  } catch (e) {
    logger.error('Failed to get user', e);
    throw new DatabaseError('User fetch failed');
  }
}

// After: extracted wrapper
function withErrorHandling<T>(
  operation: () => Promise<T>,
  context: string
): Promise<T> {
  return operation().catch((e) => {
    logger.error(`Failed to ${context}`, e);
    throw new DatabaseError(`${context} failed`);
  });
}

async function getUser(id: string) {
  return withErrorHandling(
    () => db.users.findUnique({ where: { id } }),
    'get user'
  );
}
```

---

## Python

### Pattern: Module Package

**Before**:

```python
# handlers/user.py
def validate_email(email: str) -> bool:
    import re
    return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))

# handlers/admin.py
def validate_email(email: str) -> bool:
    import re
    return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))
```

**After**:

```python
# utils/validators.py
import re

def validate_email(email: str) -> bool:
    return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))

# utils/__init__.py
from .validators import validate_email

__all__ = ['validate_email']

# handlers/user.py
from utils import validate_email
```

### Pattern: Base Class Extraction

```python
# Before: repeated CRUD in each handler
class UserHandler:
    def get(self, id: str): ...
    def create(self, data: dict): ...
    def update(self, id: str, data: dict): ...
    def delete(self, id: str): ...

class ProductHandler:
    def get(self, id: str): ...  # Same pattern
    def create(self, data: dict): ...
    # ...

# After: generic base
from typing import TypeVar, Generic

T = TypeVar('T')

class BaseHandler(Generic[T]):
    model: type[T]

    def get(self, id: str) -> T:
        return self.model.query.get(id)

    def create(self, data: dict) -> T:
        return self.model(**data).save()

    # ...

class UserHandler(BaseHandler[User]):
    model = User

class ProductHandler(BaseHandler[Product]):
    model = Product
```

### Pattern: Decorator for Cross-Cutting Concerns

```python
# Before: repeated logging/timing
def process_order(order):
    start = time.time()
    logger.info(f"Processing order {order.id}")
    try:
        result = _do_process(order)
        logger.info(f"Order {order.id} processed in {time.time() - start}s")
        return result
    except Exception as e:
        logger.error(f"Order {order.id} failed: {e}")
        raise

# After: decorator
def logged_operation(name: str):
    def decorator(fn):
        @functools.wraps(fn)
        def wrapper(*args, **kwargs):
            start = time.time()
            logger.info(f"Starting {name}")
            try:
                result = fn(*args, **kwargs)
                logger.info(f"{name} completed in {time.time() - start}s")
                return result
            except Exception as e:
                logger.error(f"{name} failed: {e}")
                raise
        return wrapper
    return decorator

@logged_operation("process_order")
def process_order(order):
    return _do_process(order)
```

---

## Rust

### Pattern: Module Extraction

**Before**:

```rust
// handlers/user.rs
fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.')
}

pub fn create_user(email: &str) -> Result<User, Error> {
    if !validate_email(email) {
        return Err(Error::InvalidEmail);
    }
    // ...
}

// handlers/admin.rs
fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.')
}
// Same function duplicated
```

**After**:

```rust
// utils/validators.rs
pub fn validate_email(email: &str) -> bool {
    email.contains('@') && email.contains('.')
}

// utils/mod.rs
mod validators;
pub use validators::validate_email;

// handlers/user.rs
use crate::utils::validate_email;

pub fn create_user(email: &str) -> Result<User, Error> {
    if !validate_email(email) {
        return Err(Error::InvalidEmail);
    }
    // ...
}
```

### Pattern: Trait Extraction

```rust
// Before: repeated impl blocks
impl User {
    pub fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
    pub fn from_json(s: &str) -> Self {
        serde_json::from_str(s).unwrap()
    }
}

impl Product {
    pub fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
    // Same pattern
}

// After: trait with blanket impl
pub trait JsonSerializable: Serialize + DeserializeOwned {
    fn to_json(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
    fn from_json(s: &str) -> Self {
        serde_json::from_str(s).unwrap()
    }
}

// Blanket implementation for all qualifying types
impl<T: Serialize + DeserializeOwned> JsonSerializable for T {}
```

### Pattern: Macro for Repetitive Code

```rust
// Before: repeated error variants
pub enum UserError {
    NotFound(String),
    Invalid(String),
    Database(String),
}

pub enum ProductError {
    NotFound(String),
    Invalid(String),
    Database(String),
}

// After: macro
macro_rules! define_error {
    ($name:ident) => {
        #[derive(Debug)]
        pub enum $name {
            NotFound(String),
            Invalid(String),
            Database(String),
        }
    };
}

define_error!(UserError);
define_error!(ProductError);
```

---

## Go

### Pattern: Same-Package Extraction

Go naturally supports multiple files in one package.

**Before**:

```go
// handlers/user.go
func validateEmail(email string) bool {
    return strings.Contains(email, "@")
}

func CreateUser(email string) (*User, error) {
    if !validateEmail(email) {
        return nil, ErrInvalidEmail
    }
    // ...
}

// handlers/admin.go
func validateEmail(email string) bool {  // Duplicate!
    return strings.Contains(email, "@")
}
```

**After**:

```go
// handlers/validators.go
package handlers

func validateEmail(email string) bool {
    return strings.Contains(email, "@")
}

// handlers/user.go
package handlers

func CreateUser(email string) (*User, error) {
    if !validateEmail(email) {  // Now shared
        return nil, ErrInvalidEmail
    }
    // ...
}
```

### Pattern: Interface Extraction

```go
// Before: concrete dependencies
type UserService struct {
    db *sql.DB
}

func (s *UserService) Get(id string) (*User, error) {
    row := s.db.QueryRow("SELECT * FROM users WHERE id = ?", id)
    // ...
}

// After: interface for testing/flexibility
type UserRepository interface {
    FindByID(id string) (*User, error)
    Save(user *User) error
}

type UserService struct {
    repo UserRepository
}

func (s *UserService) Get(id string) (*User, error) {
    return s.repo.FindByID(id)
}

// Production implementation
type SQLUserRepository struct {
    db *sql.DB
}

func (r *SQLUserRepository) FindByID(id string) (*User, error) {
    row := r.db.QueryRow("SELECT * FROM users WHERE id = ?", id)
    // ...
}
```

### Pattern: Functional Options

```go
// Before: many similar constructors
func NewServer(addr string) *Server { ... }
func NewServerWithTimeout(addr string, timeout time.Duration) *Server { ... }
func NewServerWithTLS(addr string, cert, key string) *Server { ... }

// After: functional options
type ServerOption func(*Server)

func WithTimeout(d time.Duration) ServerOption {
    return func(s *Server) { s.timeout = d }
}

func WithTLS(cert, key string) ServerOption {
    return func(s *Server) { s.cert, s.key = cert, key }
}

func NewServer(addr string, opts ...ServerOption) *Server {
    s := &Server{addr: addr}
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// Usage
server := NewServer(":8080", WithTimeout(30*time.Second), WithTLS("cert.pem", "key.pem"))
```

---

## Cross-Language Guidelines

### When to Create a New Module

| Signal | Action |
|--------|--------|
| 3+ duplicates | Extract now |
| 2 duplicates, likely more coming | Extract now |
| 2 duplicates, stable code | Consider extraction |
| Cross-domain duplication | Create shared library |

### Naming Conventions

| Type | JS/TS | Python | Rust | Go |
|------|-------|--------|------|-----|
| Utilities | `utils/` | `utils/` | `utils/` | `internal/` or same pkg |
| Common types | `types/` | `types.py` | `types.rs` | `types.go` |
| Shared constants | `constants.ts` | `constants.py` | `constants.rs` | `constants.go` |

### Import Organization

After extraction, organize imports:

1. Standard library
2. External dependencies
3. Internal/shared modules
4. Local modules
