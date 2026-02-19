# Production Deployment Checklist

**Use this checklist ONLY when deploying to production or releasing a feature.**

Don't run through this for every commit - only for production releases.

---

## Pre-Deploy (Required)

### Code Quality
- [ ] `tsc --noEmit` passes
- [ ] All tests pass
- [ ] No `console.log` in production code (except intentional logging)
- [ ] No `any` types
- [ ] No commented-out code

### Security (Critical)
- [ ] Auth check on ALL protected routes
- [ ] Ownership verification (IDOR prevention)
- [ ] Input validation with Zod on ALL user input
- [ ] No secrets in code or NEXT_PUBLIC_ vars
- [ ] Rate limiting on sensitive endpoints
- [ ] Error messages don't leak internal details

### Database
- [ ] Migrations tested on staging
- [ ] Rollback plan exists for destructive migrations
- [ ] Indexes on frequently queried columns
- [ ] No N+1 queries (use includes/joins)

### Performance
- [ ] Bundle size under budget (check with `npm run build`)
- [ ] Images optimized (WebP, proper sizing)
- [ ] Lazy loading for heavy components
- [ ] API responses paginated

---

## Deploy-Day (Required)

### Verification
- [ ] Staging environment tested end-to-end
- [ ] Critical user flows manually tested
- [ ] Mobile/responsive checked
- [ ] Error tracking configured (Sentry/LogRocket)

### Rollback Ready
- [ ] Previous version tagged in git
- [ ] Know how to rollback (document the command)
- [ ] Database backup exists (for data changes)

### Monitoring
- [ ] Health check endpoint exists
- [ ] Alerts configured for errors
- [ ] Know where to see logs

---

## Post-Deploy (First 24 Hours)

- [ ] Monitor error rates
- [ ] Check performance metrics
- [ ] Watch for user-reported issues
- [ ] Verify critical flows still work

---

## Quick Commands

```bash
# Build check
npm run build

# Type check
npx tsc --noEmit

# Run all tests
npm test

# Security audit
npm audit --audit-level=high

# Bundle analyzer (if configured)
ANALYZE=true npm run build
```

---

## When to Skip This

- Hotfix for critical bug (do minimal viable checklist)
- Documentation-only changes
- Dev/staging deployments (use simplified checklist)

## When to Be Extra Careful

- Database schema changes
- Auth/permission changes
- Payment/financial logic
- User data handling
- Third-party API integrations
