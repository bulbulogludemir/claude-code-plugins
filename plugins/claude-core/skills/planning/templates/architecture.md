# [Project Name] Architecture

## Tech Stack

| Layer | Choice | Why |
|-------|--------|-----|
| Frontend | React 19 + Next.js | [Reason] |
| Styling | Tailwind + shadcn | [Reason] |
| State | Zustand + React Query | [Reason] |
| Backend | Next.js API / Hono | [Reason] |
| Database | Supabase / PostgreSQL | [Reason] |
| Auth | [Choice] | [Reason] |

## Architecture Decision Records

### ADR-001: [Decision Title]

**Status:** Accepted | Proposed | Deprecated

**Context:** [Why this decision is needed]

**Decision:** [What was decided]

**Alternatives Considered:**
| Option | Pros | Cons |
|--------|------|------|
| [Option A] | [Pros] | [Cons] |
| [Option B] | [Pros] | [Cons] |

**Consequences:**
- ✅ [Positive consequence]
- ⚠️ [Trade-off or risk]

---

## System Design

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Client    │────▶│     API     │────▶│  Database   │
│  (Next.js)  │     │  (Routes)   │     │ (Supabase)  │
└─────────────┘     └─────────────┘     └─────────────┘
```

## Data Models

### User
```typescript
interface User {
  id: string
  email: string
  name: string
  createdAt: Date
}
```

### [Other Models]

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/users | List users |
| POST | /api/users | Create user |
| GET | /api/users/[id] | Get user |

## Security

- [ ] Auth on all protected routes
- [ ] Input validation (Zod)
- [ ] Rate limiting
- [ ] CORS configured
- [ ] Environment variables secured
