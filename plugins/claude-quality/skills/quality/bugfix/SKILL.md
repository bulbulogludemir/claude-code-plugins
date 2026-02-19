# /bugfix - Structured Bug Fix Workflow

<command-name>bugfix</command-name>

## Overview

5-step systematic bug fix process to ensure thorough diagnosis, minimal fix, and prevention of recurrence.

## Trigger Keywords

bug, error, fix, broken, not working, failing, crash, regression

## The 5-Step Process

### Step 1: REPRODUCE 🔄

**Goal:** Reliably reproduce the bug before attempting any fix.

```
Checklist:
□ Can I reproduce the bug?
□ What are the exact steps?
□ What is the expected vs actual behavior?
□ Is it consistent or intermittent?
□ What environment? (dev/staging/prod)
```

**Questions to answer:**
1. What user action triggers it?
2. What data/state is required?
3. Does it happen every time?
4. Browser/device specific?

**Output:** Documented reproduction steps

---

### Step 2: ISOLATE 🎯

**Goal:** Find the exact location of the bug in code.

```
Checklist:
□ Which file(s) are involved?
□ Which function/component?
□ What line causes the issue?
□ What are the inputs at that point?
```

**Techniques:**
1. **Error stack trace** - Start from the error message
2. **Binary search** - Comment out code to narrow down
3. **Console logging** - Track data flow
4. **Git bisect** - Find the breaking commit

```bash
# Find when bug was introduced
git bisect start
git bisect bad HEAD
git bisect good <known-good-commit>
# Test each commit until found
```

**Output:** Exact code location (file:line)

---

### Step 3: ANALYZE 🔬

**Goal:** Understand WHY the bug exists using 5 Whys technique.

```
Example:
1. Why did it crash? → Undefined property access
2. Why was it undefined? → API returned null
3. Why did API return null? → User not found
4. Why wasn't user found? → ID was wrong type
5. Why was ID wrong type? → Missing parseInt() on URL param

Root cause: Missing type coercion on route parameter
```

**Questions:**
- Why does this code behave this way?
- What assumption was wrong?
- What edge case wasn't handled?
- Was this a regression? When/why?

**Output:** Root cause understanding

---

### Step 4: FIX 🔧

**Goal:** Apply the minimal, targeted fix.

```
Principles:
□ Fix ONLY the root cause
□ Don't refactor unrelated code
□ Don't add unrelated features
□ Keep the diff small
□ Maintain backwards compatibility
```

**Fix Types:**
| Bug Type | Fix Pattern |
|----------|-------------|
| Null/undefined | Add defensive check or fix source |
| Type error | Fix type coercion at boundary |
| Logic error | Fix condition or algorithm |
| Race condition | Add proper async handling |
| Missing validation | Add validation at entry point |

**Verification:**
```bash
# Compile check
npx tsc --noEmit

# Manual test the fix
npm run dev
# Test the reproduction steps

# Ensure no regressions
npm test
```

**Output:** Working fix with passing tests

---

### Step 5: PREVENT 🛡️

**Goal:** Ensure this bug never happens again.

```
Checklist:
□ Add/update test case
□ Document if complex
□ Update types if type-related
□ Add validation if input-related
□ Consider similar code paths
```

**Test Template:**
```typescript
describe('bugfix: [description]', () => {
  it('should handle [edge case]', () => {
    // Reproduce the original bug scenario
    const result = functionUnderTest(buggyInput)

    // Assert correct behavior
    expect(result).toBe(expectedOutput)
  })
})
```

**Check for Similar Issues:**
```bash
# Find similar patterns in codebase
rg "similar-pattern" --type ts
```

**Output:** Test case + documentation

---

## Bug Report Template

When reporting/tracking a bug:

```markdown
## Bug: [Title]

**Reproduction:**
1. Step 1
2. Step 2
3. Step 3

**Expected:** What should happen
**Actual:** What actually happens

**Environment:**
- Browser: Chrome 120
- OS: macOS 14
- Environment: Production

**Root Cause:** [After analysis]
**Fix:** [PR/commit link]
**Prevention:** [Test added]
```

---

## Quick Reference

| Phase | Time | Output |
|-------|------|--------|
| REPRODUCE | 5-10 min | Reproduction steps |
| ISOLATE | 5-15 min | Code location |
| ANALYZE | 5-10 min | Root cause |
| FIX | 10-30 min | Working code |
| PREVENT | 5-15 min | Test case |

**Total: 30-80 minutes for most bugs**

---

## Anti-Patterns (Don't Do)

❌ Fix symptoms, not root cause
❌ Add workarounds without understanding
❌ Shotgun debugging (random changes)
❌ Skip reproduction ("I think I know...")
❌ Large refactors disguised as bug fixes
❌ Skip writing tests
❌ Say "done" without verifying fix
