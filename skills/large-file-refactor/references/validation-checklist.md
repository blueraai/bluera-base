# Validation Checklist

Pre and post-refactor validation to ensure the split doesn't break anything.

## Pre-Refactor

### Document Current State

- [ ] **List public exports**: What does the file currently expose?
- [ ] **Note external imports**: What other files import from this one?
- [ ] **Identify test coverage**: What tests exist for this file?
- [ ] **Check CI status**: Ensure tests pass before starting

### Plan the Split

- [ ] **Map dependencies**: Which functions call which?
- [ ] **Identify shared types**: Types used across multiple sections
- [ ] **Plan new file structure**: Where will each section go?
- [ ] **Verify no circular deps**: New modules won't import each other circularly

### Backup

- [ ] **Commit current state**: Clean commit before refactoring
- [ ] **Note rollback point**: Know how to revert if needed

---

## During Refactor

### For Each New File

- [ ] Create file with correct module declaration
- [ ] Move code (use Read offset/limit + Write)
- [ ] Add necessary imports
- [ ] Update visibility (pub, pub(crate), etc.)

### Update Original File

- [ ] Add module declarations (`mod new_module;`)
- [ ] Add re-exports if needed (`pub use new_module::*;`)
- [ ] Remove moved code
- [ ] Update internal imports

### Update Dependents

- [ ] Find files that import from original
- [ ] Update import paths if needed
- [ ] Verify imports resolve

---

## Post-Refactor

### Compilation/Type Check

- [ ] **Build succeeds**: `cargo build` / `npm run build` / etc.
- [ ] **No type errors**: LSP shows no red squiggles
- [ ] **No unused imports**: Clean up any warnings

### Reference Resolution

- [ ] **LSP hover works**: Hover over usages shows correct types
- [ ] **Go to definition works**: Jumps to new locations
- [ ] **Find references works**: Finds usages across files

### Functionality

- [ ] **Tests pass**: All existing tests still pass
- [ ] **Manual smoke test**: Key functionality works
- [ ] **No runtime errors**: App starts and runs correctly

### Code Quality

- [ ] **No duplicate code**: Shared code properly extracted
- [ ] **Reasonable file sizes**: Each new file < 500 lines ideally
- [ ] **Clear organization**: Related code stays together
- [ ] **Consistent naming**: Files/modules follow project conventions

### Documentation

- [ ] **Update imports in docs**: README, examples, etc.
- [ ] **Add module-level docs**: Document new module purposes

---

## Common Issues & Fixes

### Circular Import

**Symptom**: Build fails with circular dependency error

**Fix**:

1. Identify the cycle
2. Extract shared types to separate file
3. Have both modules import from shared file

### Missing Export

**Symptom**: "unresolved import" or "not found" errors

**Fix**:

1. Add `pub` to item in new location
2. Add re-export in original module
3. Update import path in caller

### Orphan Rule (Rust)

**Symptom**: "impl doesn't use only types defined in current crate"

**Fix**:

1. Keep trait impl in same module as trait or type
2. Use newtype pattern if needed
3. Consider different module organization

### Type Mismatch

**Symptom**: Types don't match after move

**Fix**:

1. Ensure using same type (not copy)
2. Check import paths point to same definition
3. Verify generics are consistent

---

## Rollback Plan

If refactor causes too many issues:

1. `git stash` current changes (or commit to branch)
2. `git checkout <pre-refactor-commit>`
3. Analyze what went wrong
4. Plan smaller, incremental changes
5. Retry with lessons learned

**Incremental approach**: If file is very large, consider splitting into 2-3 files first, then further subdividing.
