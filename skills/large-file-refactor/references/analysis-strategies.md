# Analysis Strategies for Large Files

Techniques to understand file structure without reading the entire file.

## Line Count Assessment

```bash
wc -l <file>
```

| Lines | Assessment |
|-------|------------|
| < 500 | Manageable, may not need splitting |
| 500-1000 | Review for multiple concerns |
| 1000-2000 | Likely needs splitting |
| > 2000 | Definitely needs splitting |

## Grep for Structure

### Rust

```bash
# Functions and impl blocks
grep -n "^pub fn\|^fn\|^impl\|^pub struct\|^struct\|^pub enum\|^enum\|^mod " file.rs

# Just impl blocks (often good split points)
grep -n "^impl" file.rs

# Modules
grep -n "^mod\|^pub mod" file.rs
```

### TypeScript/JavaScript

```bash
# Classes and functions
grep -n "^export class\|^class\|^export function\|^function\|^export const\|^export interface" file.ts

# React components
grep -n "^export function\|^export const.*=.*=>" file.tsx
```

### Python

```bash
# Classes and functions
grep -n "^class \|^def \|^async def " file.py
```

### Go

```bash
# Types and functions
grep -n "^type \|^func " file.go
```

## LSP documentSymbol

The most accurate way to get file structure:

```
LSP documentSymbol file.rs
```

Returns hierarchical list of:
- Functions/methods
- Classes/structs/enums
- Interfaces/traits
- Constants
- Nested symbols

**Advantages over grep**:
- Handles multi-line signatures
- Shows nesting/hierarchy
- Language-aware parsing

## Read with Offset/Limit

Once you identify sections via grep or LSP:

```
Read file.rs offset=100 limit=200
```

- `offset`: Starting line (0-indexed)
- `limit`: Number of lines to read

**Strategy**:
1. Use grep to find line numbers of interest
2. Read specific sections (add buffer: `offset=line-10 limit=section_size+20`)
3. Build mental map of file structure

## Identifying Natural Breakpoints

### Cohesion Indicators

**Strong cohesion** (keep together):
- Type definition + its impl blocks
- Struct + associated functions
- Interface + implementations
- Test module for specific functionality

**Weak cohesion** (split candidates):
- Unrelated utilities in same file
- Multiple distinct features
- Different domains/concerns
- Separate validation/conversion logic

### Dependency Analysis

```bash
# Find what this file imports
grep -n "^use \|^import " file.rs

# Find internal cross-references (functions calling each other)
# Use LSP findReferences on key functions
```

Files with many internal cross-references are harder to split.

## Size Estimation

Estimate resulting file sizes before splitting:

1. Count lines in each section (grep line numbers)
2. Target: 200-500 lines per new file
3. Allow some variance for cohesion

**Example**:
```
File: 2500 lines
impl UserService: lines 50-600    (550 lines) → user_service.rs
impl AuthService: lines 601-1200  (600 lines) → auth_service.rs
impl Validators: lines 1201-1800  (600 lines) → validators.rs
Types + tests: lines 1801-2500    (700 lines) → keep in mod.rs + tests.rs
```

## Token Estimation

Claude Code's limit is ~25000 tokens. Rough conversion:
- 1 line of code ≈ 5-15 tokens (varies by language/density)
- 2000 lines ≈ 10000-30000 tokens

Files over 2000 lines will likely hit the limit.
