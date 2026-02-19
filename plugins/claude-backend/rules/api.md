---
paths: ["**/app/api/**", "**/actions/**", "**/route.ts"]
---

Every endpoint MUST follow: Auth -> Validate -> Ownership -> Execute

- **Auth:** `await auth()` at start, return 401 if missing
- **Validate:** `Zod.safeParse()` on all input, return 400 if invalid
- **Ownership:** check `resource.userId === userId`, return 404 (not 403) if wrong
- **Execute:** try/catch, generic error to client, detailed to logs
- **Webhooks:** signature verification + idempotency check
- **Lists:** always paginate
- **Rate Limiting:** All public API routes MUST have rate limiting. Use next-rate-limit or similar. Minimum: 60 req/min for authenticated, 20 req/min for unauthenticated.
