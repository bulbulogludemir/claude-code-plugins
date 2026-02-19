---
name: onboarding
description: New project setup, scaffolding, boilerplate
triggers:
  - new project
  - setup
  - init
  - scaffold
  - bootstrap
---

# Onboarding Skill

Set up new projects from scratch with production-ready patterns.

## Standard Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16 (App Router) |
| Language | TypeScript (strict) |
| Styling | Tailwind CSS 4 + shadcn/ui |
| Database | PostgreSQL + Drizzle ORM |
| Auth | NextAuth.js or Supabase Auth |
| Data Fetching | React Query (TanStack Query) |
| State | Zustand |
| Forms | React Hook Form + Zod |
| Deployment | Docker + Coolify or Vercel |

## Project Structure

```
project/
├── app/                    # Next.js App Router
│   ├── (auth)/            # Auth-required routes
│   ├── (public)/          # Public routes
│   ├── api/               # API routes
│   │   └── health/        # Health check endpoint
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Home page
├── components/
│   ├── ui/                # shadcn/ui components
│   └── [feature]/         # Feature-specific components
├── lib/
│   ├── db/
│   │   ├── index.ts       # Database client
│   │   ├── schema.ts      # Drizzle schema
│   │   └── migrations/    # Migration files
│   ├── auth/              # Auth utilities
│   ├── utils.ts           # Shared utilities
│   └── validations.ts     # Zod schemas
├── hooks/                 # Custom React hooks
├── types/                 # TypeScript types
├── public/                # Static assets
├── drizzle.config.ts      # Drizzle configuration
├── CLAUDE.md              # Project-specific AI instructions
├── Dockerfile             # Production container
├── docker-compose.yml     # Development services
└── .env.example           # Environment template
```

## Setup Steps

### 1. Create Next.js Project
```bash
npx create-next-app@latest project-name --typescript --tailwind --eslint --app --src-dir=false --import-alias="@/*"
```

### 2. Install Core Dependencies
```bash
npm install drizzle-orm postgres @tanstack/react-query zustand zod react-hook-form @hookform/resolvers sonner
npm install -D drizzle-kit @types/node
```

### 3. Initialize shadcn/ui
```bash
npx shadcn@latest init
npx shadcn@latest add button card input label dialog toast skeleton
```

### 4. Database Setup
- Create `lib/db/index.ts` with Drizzle client
- Create `lib/db/schema.ts` with initial schema
- Create `drizzle.config.ts`
- Run `npx drizzle-kit generate` and `npx drizzle-kit migrate`

### 5. Auth Setup
- Configure NextAuth.js or Supabase Auth
- Create middleware for route protection
- Add auth utilities

### 6. Docker Setup
- Create multi-stage Dockerfile
- Create docker-compose.yml for dev (postgres, redis)

### 7. Project CLAUDE.md
Create project-specific instructions covering:
- Project description and purpose
- Key conventions
- Important file paths
- Development workflow
- Known gotchas

### 8. Environment Template
Create `.env.example` with all required variables (no real values).

## Checklist

- [ ] Project scaffolded with Next.js
- [ ] TypeScript strict mode enabled
- [ ] Tailwind + shadcn/ui configured
- [ ] Database schema + migrations ready
- [ ] Auth configured
- [ ] Health check endpoint exists
- [ ] Docker setup complete
- [ ] CLAUDE.md created
- [ ] .env.example documented
- [ ] tsc --noEmit passes
- [ ] npm run build succeeds
