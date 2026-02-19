---
name: quality
description: "Debug, test, verify. Auto-use for bugs, errors, testing."
version: 3.0.0
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Grep
  - Glob
---

# Quality

**Auto-use when:** bug, error, fix, debug, not working, broken, test, failing

**Works with:** All skills - final verification gate

---

## Debugging (5 Steps)

### 1. REPRODUCE
```bash
# Create failing test or clear steps
it('should not crash with null profile', () => {
  const user = { id: '1', profile: null }
  expect(() => getAvatar(user)).not.toThrow()
})
```

### 2. ISOLATE
```bash
# Find exact location
git log --oneline -10 -- path/to/file.ts
git blame -L 40,50 path/to/file.ts
```

### 3. IDENTIFY ROOT CAUSE
```
Why crash? → profile is null
Why null? → API returns null for new users
Why not handled? → Assumed profile always exists
ROOT CAUSE: Missing null handling
```

### 4. FIX (Minimal)
```typescript
// Before
return user.profile.avatar.url

// After
return user.profile?.avatar?.url ?? '/default.png'
```

### 5. VERIFY
```bash
npx tsc --noEmit        # Types pass
npm test                # Tests pass
# Check similar patterns in codebase
```

---

## Testing

### TDD Flow
```
RED → Write failing test
GREEN → Minimal code to pass
REFACTOR → Clean up
```

### Test Priority
```
P0: Happy path works
P0: Auth blocks unauthorized
P0: Ownership blocks others' data
P1: Validation rejects bad input
P1: Edge cases handled
P2: Error states work
```

### Test Template
```typescript
import { describe, it, expect, vi } from 'vitest'

describe('createPost', () => {
  it('creates for authenticated user', async () => {
    vi.mocked(auth).mockResolvedValue({ userId: 'user-1' })
    const result = await createPost({ title: 'Test' })
    expect(result.authorId).toBe('user-1')
  })

  it('rejects unauthenticated', async () => {
    vi.mocked(auth).mockResolvedValue({ userId: null })
    await expect(createPost({ title: 'Test' })).rejects.toThrow('Unauthorized')
  })
})
```

---

## Verification Commands

```bash
# MUST pass before "done"
npx tsc --noEmit          # TypeScript
npm test                   # Tests
npm run lint              # Lint
npm run build             # Build

# Check for lazy patterns
grep -r "TODO\|FIXME" src/
grep -r ": any" src/
grep -r "console\.log" src/
grep -rE "mock|fake" src/
```

---

## Definition of Done

```
□ tsc --noEmit = 0 errors
□ Tests pass
□ No TODO comments
□ No any types
□ No mock data
□ No console.log
□ All UI states handled
□ Error handling present
```

---

## QA Fix (Batch)

When given a QA report, fix all issues:

1. **Parse** report for file:line references
2. **Prioritize**: P0/Critical first, then P1/High
3. **Fix** each with minimal targeted changes
4. **Verify**: `npx tsc --noEmit` + `npm test`
5. **Report** before/after summary

Rules: Stay scoped to report issues. Don't refactor adjacent code.

---

## Red Flags (STOP)

| If You See | Action |
|------------|--------|
| `TODO:` | Implement now |
| `: any` | Add types |
| `mockData` | Wire to API |
| `console.log(error)` | Show to user |
| Missing loading state | Add skeleton |
| Missing error state | Add error UI |
| `catch {}` (empty) | Handle error |
