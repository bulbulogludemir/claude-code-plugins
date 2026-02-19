---
name: refactor
description: Safe, incremental code restructuring
triggers:
  - refactor
  - restructure
  - reorganize
  - clean up
  - extract
---

# Refactoring Skill

Safe, behavior-preserving code restructuring.

## Golden Rule

**NEVER change behavior, only structure.** If a refactor changes what the code does (not just how it's organized), it's a feature change, not a refactor.

## Workflow

1. **Understand** — Read all affected code first
2. **Plan** — Identify what to extract/move/rename
3. **Verify** — Run `npx tsc --noEmit` before starting
4. **Execute** — Make changes incrementally
5. **Verify** — Run `npx tsc --noEmit` after each step
6. **Confirm** — Ensure behavior is identical

## Common Patterns

### Extract Component
```
Before: Large component with inline logic
After: Parent + extracted child component
Steps:
1. Identify self-contained UI section
2. Extract props interface
3. Move JSX to new component
4. Import in parent
5. Verify tsc passes
```

### Extract Function/Hook
```
Before: Inline logic in component
After: Custom hook or utility function
Steps:
1. Identify reusable logic
2. Create function/hook with proper types
3. Replace inline code with function call
4. Verify tsc passes
```

### Move File with Import Update
```
Steps:
1. Create file at new location
2. Move content
3. Update ALL imports across codebase (grep for old path)
4. Delete old file
5. Verify tsc passes
```

### Rename Across Codebase
```
Steps:
1. Find all usages (Grep)
2. Rename in definition file
3. Update all import references
4. Update all usage sites
5. Verify tsc passes
```

### Dead Code Elimination
```
Steps:
1. Find unused exports (grep for import references)
2. Verify no dynamic imports reference the code
3. Remove unused code
4. Verify tsc passes
```

## Safety Checks

- [ ] `npx tsc --noEmit` passes before AND after
- [ ] No behavior changes (same inputs → same outputs)
- [ ] All imports updated
- [ ] No orphaned files
- [ ] No circular dependencies introduced
