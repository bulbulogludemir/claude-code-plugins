---
name: monitoring
description: Observability, error tracking, logging, health checks
triggers:
  - monitor
  - alert
  - logging
  - error tracking
  - sentry
  - uptime
---

# Monitoring Skill

Set up and manage observability infrastructure.

## Core Components

### 1. Health Check Endpoint
```typescript
// app/api/health/route.ts
import { db } from '@/lib/db'
import { sql } from 'drizzle-orm'

export async function GET() {
  try {
    await db.execute(sql`SELECT 1`)
    return Response.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: process.env.NEXT_PUBLIC_APP_VERSION || 'unknown',
    })
  } catch (error) {
    return Response.json(
      { status: 'unhealthy', error: 'Database connection failed' },
      { status: 503 }
    )
  }
}
```

### 2. Structured Logging
```typescript
// lib/logger.ts
type LogLevel = 'debug' | 'info' | 'warn' | 'error'

function log(level: LogLevel, message: string, meta?: Record<string, unknown>) {
  const entry = {
    level,
    message,
    timestamp: new Date().toISOString(),
    ...meta,
  }
  if (level === 'error') {
    console.error(JSON.stringify(entry))
  } else {
    console.log(JSON.stringify(entry))
  }
}

export const logger = {
  debug: (msg: string, meta?: Record<string, unknown>) => log('debug', msg, meta),
  info: (msg: string, meta?: Record<string, unknown>) => log('info', msg, meta),
  warn: (msg: string, meta?: Record<string, unknown>) => log('warn', msg, meta),
  error: (msg: string, meta?: Record<string, unknown>) => log('error', msg, meta),
}
```

### 3. Sentry Integration
```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
  dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
})
```

### 4. Web Vitals
```typescript
// app/layout.tsx
import { SpeedInsights } from '@vercel/speed-insights/next'
import { Analytics } from '@vercel/analytics/react'

// In layout return:
<SpeedInsights />
<Analytics />
```

## Alerting Rules

| Metric | Warning | Critical |
|--------|---------|----------|
| Error rate | >1% | >5% |
| Response time (p95) | >2s | >5s |
| Uptime | <99.5% | <99% |
| CPU usage | >70% | >90% |
| Memory usage | >80% | >95% |
| Disk usage | >80% | >90% |

## Checklist

- [ ] Health check endpoint exists and checks DB
- [ ] Structured logging (not raw console.log)
- [ ] Error tracking configured (Sentry or similar)
- [ ] Web Vitals monitored
- [ ] Uptime monitoring active
- [ ] Alert thresholds set
