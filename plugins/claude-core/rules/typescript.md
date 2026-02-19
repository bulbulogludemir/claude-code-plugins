---
paths: ["**/*.ts", "**/*.tsx"]
---

- No `any` types — always define proper types
- No `@ts-ignore` or `@ts-expect-error` — fix the type error
- No TODO/FIXME comments — implement now
- No empty handlers `() => {}` — implement the function
- No `console.log` for error handling — show errors to user
- No mock data arrays — fetch from real API
- Always run `npx tsc --noEmit` before claiming done
