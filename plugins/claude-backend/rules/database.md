---
paths: ["**/schema/**", "**/migrations/**", "**/drizzle/**"]
---

- IDs: BIGINT (not INT)
- Timestamps: TIMESTAMPTZ (not TIMESTAMP)
- Money: DECIMAL (not FLOAT)
- Foreign keys: always indexed
- N+1: use `with` for relations
- After schema changes: run `npm run db:generate`
- Destructive ops (DROP TABLE/COLUMN, TRUNCATE): require explicit confirmation
- **Soft Deletes:** Prefer soft deletes (deletedAt timestamp) over hard deletes for user-facing data. Only hard delete when required for GDPR/privacy compliance.
