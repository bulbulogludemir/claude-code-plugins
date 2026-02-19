---
name: performance
description: Performance analysis and optimization
triggers:
  - performance
  - slow
  - optimize
  - speed
  - lighthouse
  - bundle
---

# Performance Skill

Systematic performance analysis and optimization.

## Diagnosis First

**NEVER optimize without measuring.** Always profile before changing code.

## Analysis Tools

### Bundle Analysis
```bash
# Next.js bundle analyzer
ANALYZE=true npm run build

# Check bundle size
npx next-bundle-analyzer
```

### Database Profiling
```sql
-- Find slow queries
EXPLAIN ANALYZE SELECT ...;

-- Check missing indexes
SELECT schemaname, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public';
```

### React Profiling
- React DevTools Profiler
- `React.memo()` for expensive renders
- `useMemo()` for expensive computations
- `useCallback()` for stable references passed to children

## Optimization Strategies

### Server Components vs Client Components
```
Server Component (default):
- Static content
- Data fetching
- No interactivity
- No hooks

Client Component ('use client'):
- Event handlers
- useState/useEffect
- Browser APIs
- Interactive UI
```

### Lazy Loading
```typescript
// Heavy components
const Editor = dynamic(() => import('@/components/editor'), {
  loading: () => <Skeleton className="h-96" />,
  ssr: false,
})

// Images
import Image from 'next/image'
<Image src={url} width={800} height={600} loading="lazy" />
```

### Database Optimization
- Add indexes for WHERE, ORDER BY, JOIN columns
- Use `with` (Drizzle) to prevent N+1 queries
- Paginate all list endpoints (default: 20, max: 100)
- Use connection pooling

### Caching Strategy
```typescript
// React Query cache
useQuery({
  queryKey: ['users'],
  queryFn: fetchUsers,
  staleTime: 5 * 60 * 1000, // 5 minutes
  gcTime: 30 * 60 * 1000, // 30 minutes
})

// Next.js fetch cache
fetch(url, { next: { revalidate: 3600 } }) // 1 hour
```

### Bundle Size
```typescript
// BAD — imports entire library
import _ from 'lodash'

// GOOD — tree-shakeable import
import debounce from 'lodash/debounce'
```

## Image Rules

- Use `next/image` with explicit width/height
- Use WebP format when possible
- **NEVER compress below 1MB quality threshold**
- Use responsive sizes with `sizes` prop

## Checklist

- [ ] Measured before optimizing
- [ ] Bundle size checked
- [ ] Database queries profiled
- [ ] Images optimized (not over-compressed)
- [ ] Lazy loading for heavy components
- [ ] Server components where possible
- [ ] tsc --noEmit passes
