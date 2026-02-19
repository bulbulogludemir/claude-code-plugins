## Testing Rules

- **Framework:** Vitest for unit/integration, Playwright for E2E
- **File Naming:** `*.test.ts` for unit tests, `*.spec.ts` for E2E tests
- **Minimum Coverage:** Happy path + error case + edge case for every function
- **Mock Strategy:** `vi.mock()` for external dependencies, real implementations for internal code
- **Test Structure:** Arrange → Act → Assert pattern
- **Assertions:** Use specific matchers (`toEqual`, `toContain`) over generic (`toBeTruthy`)
- **Async Tests:** Always await async operations, use `waitFor` for React testing
- **Database Tests:** Use transactions with rollback, never pollute shared state
- **API Tests:** Test response shape, status codes, auth enforcement, and validation errors
- **Snapshot Testing:** Avoid unless testing serialized output (too fragile for UI)
