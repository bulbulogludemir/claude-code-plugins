---
name: release
description: "Full release pipeline — implement, verify, and push to main. Also handles deployments."
triggers: [push, commit, ship, deploy, release, production, yayınla, canlıya al]
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Grep
  - Glob
  - Task
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TeamCreate
  - SendMessage
  - Skill
---

# Release

**Auto-use when:** push, commit, ship, deploy, release, production, CI/CD

**Combines:** push + ship + devops into one pipeline.

---

## Pipeline

### 1. Implement (if needed)

Use parallel agents for multi-file changes. Never stop at planning.

### 2. Quality Gates

All must pass before pushing. Fix failures before proceeding.

```bash
# TypeScript (FULL, not incremental)
npx tsc --noEmit

# Tests
npm test

# Build
npm run build

# i18n check
grep -r "MISSING_MESSAGE" src/ || echo "No missing translations"
```

### 3. Database Migration Check

```bash
npm run db:generate
# If new migrations: review SQL in drizzle/, then npm run db:push
```

**Migration rules:**
- Always review generated SQL before pushing
- Never drop columns without data migration plan
- Test destructive changes on staging first

### 4. Pre-Release Dependency Check

```bash
npm outdated --json 2>/dev/null
```

Review the output. If any packages have **major version bumps** (current major !== latest major), warn the user but do NOT block the release. Example output:

```
⚠ Major version bumps available:
  - next: 15.x → 16.x
  - drizzle-orm: 0.30 → 0.33
These are informational only — not blocking release.
```

### 5. Changelog Generation

Before committing, generate a changelog entry from recent commits:

```bash
git log --oneline $(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)..HEAD
```

Group commits by type into bullet points:

```
### Changes
**Features**
- feat: add gallery upload component
- feat: support multi-language captions

**Fixes**
- fix: correct webhook retry logic
- fix: handle null avatar in profile

**Chores**
- chore: update dependencies
- chore: clean up unused imports
```

Include this changelog in the commit message body (after the subject line).

### 6. Git

```bash
git add -A
git commit -m "<descriptive message>

<changelog body>"
git push origin main
```

### 7. Post-Deploy Health Check

Runs automatically via hook (waits 45s, checks `/api/health`, retries 3x).

Manual fallback:
```bash
curl https://influos.app/api/health | jq
```

### 8. Report

```
## Released
- tsc --noEmit: 0 errors
- npm test: X passing
- npm run build: success
- Pushed to main: <commit hash>
- Health check: passed
```

---

## NEVER

- Push with type errors
- Push with failing tests
- Push with build errors
- Skip any quality gate
- Force push without explicit user request

---

## Rollback Procedures

### Quick Rollback (Revert Commit)
```bash
git revert HEAD
git push origin main
```

### Full Rollback (Previous Version)
```bash
git tag | grep pre-deploy | tail -1
git reset --hard <tag-name>
git push --force origin main  # Requires user confirmation
```

### Database Rollback
Restore from automated backup (Coolify/Supabase) or manually reverse migration SQL.

---

## Deployment Checklist

```
□ tsc --noEmit = 0 errors
□ npm test = passes
□ npm run build = succeeds
□ git status = clean
□ Migrations reviewed (if any)
□ Health check passed
□ Sentry clear of new errors
```

---

## Common Issues

| Issue | Solution |
|-------|----------|
| Build fails with type errors | Run `npx tsc --noEmit`, fix all errors |
| Health check fails (DB down) | Check DATABASE_URL, verify Supabase status |
| Health check fails (Redis down) | Check REDIS_URL, verify Redis container |
| Container crash loop | Check Coolify logs, usually env var issue |
| 502 after deploy | Wait 60s for cold start, check memory limits |

---

## Environment Notes

- **Coolify**: Auto-deploys on `git push origin main`
- **Health endpoint**: `/api/health`
- **Logs**: Coolify dashboard -> Container logs
