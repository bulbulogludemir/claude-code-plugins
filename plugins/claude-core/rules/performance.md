---
description: Performance best practices
globs: ["**/*.ts", "**/*.tsx"]
---

## Performance Rules

- **N+1 Prevention:** Always use `with` (Drizzle) or `include` (Prisma) for related data. Never query in a loop.
- **Pagination:** All list endpoints MUST be paginated. Default limit: 20, max: 100.
- **Lazy Loading:** Use `dynamic(() => import(...))` for heavy components (editors, charts, maps). Use `loading.tsx` for route-level.
- **Image Optimization:** Use `next/image` with proper width/height. NEVER compress below 1MB quality threshold. Use WebP format when possible.
- **Bundle Size:** Avoid importing entire libraries (`import _ from 'lodash'`). Use specific imports (`import debounce from 'lodash/debounce'`).
- **Database Indexes:** Add indexes for columns used in WHERE, ORDER BY, and JOIN. Check with `EXPLAIN ANALYZE`.
