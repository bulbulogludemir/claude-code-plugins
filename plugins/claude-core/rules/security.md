---
paths: ["**/*"]
---

- No hardcoded secrets (API keys, passwords, tokens)
- No `NEXT_PUBLIC_` prefix for secret env vars
- Rate limiting on sensitive endpoints
- Generic errors to users, detailed to logs
- Webhook signature verification required
- No raw SQL string concatenation
- **CORS:** Always configure CORS explicitly. Never use `Access-Control-Allow-Origin: *` in production. Allowed origins should come from environment variables.
