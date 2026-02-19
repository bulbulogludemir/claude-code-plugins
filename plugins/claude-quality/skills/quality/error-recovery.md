# Error Recovery

Quick reference for diagnosing and fixing common errors.

## TypeScript Errors

| Code | Type | Fix |
|------|------|-----|
| TS2322 | Type mismatch | Fix assigned type |
| TS2345 | Argument type | Fix parameter type |
| TS2339 | Property missing | Add to interface or fix typo |
| TS2304 | Not found | Add import |
| TS2307 | Module not found | npm install or fix path |
| TS2531 | Possibly null | Add null check `?.` or `!` |
| TS7006 | Implicit any | Add type annotation |

## Runtime Errors

| Error | Fix |
|-------|-----|
| `Cannot read property of undefined` | Add optional chaining `?.` |
| `X is not a function` | Check import, fix type |
| `X is not defined` | Check scope, add import |
| `Maximum call stack` | Fix infinite recursion |

## Recovery Commands

```bash
# TypeScript won't compile
npx tsc --noEmit 2>&1 | head -20

# Dependencies broken
rm -rf node_modules package-lock.json && npm install

# ESLint auto-fix
npx eslint . --fix

# Clear Next.js cache
rm -rf .next

# Clear Vite cache
rm -rf node_modules/.vite
```

## Recovery Protocol

```
1. READ error message carefully
2. CLASSIFY: Syntax | Type | Runtime | Build | Test
3. FIX: Make minimal, targeted change
4. VERIFY: tsc && npm test
5. If still failing after 3 attempts → ask user
```

## Common Patterns

```typescript
// Null safety
const name = user?.profile?.name ?? 'Unknown'

// Type guard
if ('email' in user) { user.email }

// Exhaustive switch
function assertNever(x: never): never {
  throw new Error(`Unexpected: ${x}`)
}
```
