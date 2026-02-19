---
name: webhook-reliability
description: Use when handling webhooks from external services. Idempotency, retries, verification, queuing. Triggers on: webhook, stripe webhook, clerk webhook, idempotency, retry, webhook handler.
version: 1.0.0
triggers: ["webhook", "stripe", "payment", "idempotency"]
---

# Webhook Reliability (2026)

> Critical patterns for payment webhooks, auth webhooks, and third-party integrations.
> **Unreliable webhooks = lost transactions.**

---

## 🚨 WHY THIS MATTERS

```
Webhook failures cause:
❌ Lost payments (Stripe webhook fails → user pays but no subscription)
❌ Data sync issues (Clerk webhook fails → user exists in auth but not DB)
❌ Duplicate processing (webhook retries → user charged twice)
❌ Out-of-order events (subscription.updated before subscription.created)
```

---

## Core Principles

1. **Idempotency** - Same webhook processed = same result
2. **Exactly-once** - Process each event once, not zero, not twice
3. **Order independence** - Handle events arriving out-of-order
4. **Graceful failure** - Dead letter queue for unrecoverable failures
5. **Signature verification** - Always verify webhook signatures

---

## Idempotency Pattern

```typescript
// app/api/webhooks/stripe/route.ts
import { headers } from 'next/headers'
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)

export async function POST(req: Request) {
  const body = await req.text()
  const signature = headers().get('stripe-signature')!

  // 1. Verify signature
  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (err) {
    console.error('Webhook signature verification failed:', err)
    return new Response('Invalid signature', { status: 400 })
  }

  // 2. Idempotency check - Have we processed this event?
  const existingEvent = await db.webhookEvent.findUnique({
    where: { eventId: event.id }
  })

  if (existingEvent) {
    // Already processed - return success (idempotent)
    console.log(`Event ${event.id} already processed, skipping`)
    return new Response('OK', { status: 200 })
  }

  // 3. Create event record BEFORE processing (claim the event)
  await db.webhookEvent.create({
    data: {
      eventId: event.id,
      type: event.type,
      status: 'processing',
      payload: JSON.stringify(event.data),
      receivedAt: new Date(),
    }
  })

  try {
    // 4. Process the event
    await handleWebhookEvent(event)

    // 5. Mark as processed
    await db.webhookEvent.update({
      where: { eventId: event.id },
      data: { status: 'processed', processedAt: new Date() }
    })

    return new Response('OK', { status: 200 })

  } catch (error) {
    // 6. Mark as failed for retry or DLQ
    await db.webhookEvent.update({
      where: { eventId: event.id },
      data: {
        status: 'failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        failedAt: new Date(),
      }
    })

    // Return 500 to trigger Stripe retry
    return new Response('Processing failed', { status: 500 })
  }
}
```

---

## Database Schema for Webhook Events

```typescript
// prisma/schema.prisma
model WebhookEvent {
  id          String   @id @default(cuid())
  eventId     String   @unique  // Stripe/Clerk event ID
  type        String              // e.g., "checkout.session.completed"
  status      String              // processing | processed | failed | dead_letter
  payload     Json
  error       String?
  retryCount  Int      @default(0)
  receivedAt  DateTime
  processedAt DateTime?
  failedAt    DateTime?
  createdAt   DateTime @default(now())

  @@index([status])
  @@index([type])
  @@index([receivedAt])
}
```

---

## Retry with Exponential Backoff

```typescript
// lib/webhooks/retry.ts
import { inngest } from '@/lib/inngest/client'

// Use Inngest for reliable retries
export const retryFailedWebhook = inngest.createFunction(
  {
    id: 'retry-failed-webhook',
    retries: 5,  // Max 5 retries
  },
  { event: 'webhook/retry.requested' },
  async ({ event, step }) => {
    const { eventId } = event.data

    // Get the failed event
    const webhookEvent = await step.run('get-event', async () => {
      return db.webhookEvent.findUnique({ where: { eventId } })
    })

    if (!webhookEvent || webhookEvent.status === 'processed') {
      return { skipped: true }
    }

    // Calculate backoff: 1s, 2s, 4s, 8s, 16s
    const backoffMs = Math.min(1000 * Math.pow(2, webhookEvent.retryCount), 16000)

    await step.sleep('backoff', backoffMs)

    // Increment retry count
    await step.run('increment-retry', async () => {
      await db.webhookEvent.update({
        where: { eventId },
        data: { retryCount: { increment: 1 } }
      })
    })

    // Retry processing
    await step.run('process', async () => {
      const payload = webhookEvent.payload as Stripe.Event
      await handleWebhookEvent(payload)
    })

    // Mark as processed
    await step.run('mark-processed', async () => {
      await db.webhookEvent.update({
        where: { eventId },
        data: { status: 'processed', processedAt: new Date() }
      })
    })

    return { success: true }
  }
)
```

---

## Dead Letter Queue (DLQ)

```typescript
// lib/webhooks/dlq.ts
const MAX_RETRIES = 5

export async function moveToDeadLetterQueue(eventId: string) {
  const event = await db.webhookEvent.findUnique({
    where: { eventId }
  })

  if (!event) return

  // Check if max retries exceeded
  if (event.retryCount >= MAX_RETRIES) {
    await db.webhookEvent.update({
      where: { eventId },
      data: { status: 'dead_letter' }
    })

    // Alert on-call (Slack, PagerDuty, etc.)
    await alertOnCall({
      severity: 'high',
      title: `Webhook failed after ${MAX_RETRIES} retries`,
      details: {
        eventId,
        type: event.type,
        error: event.error,
      }
    })
  }
}

// Cron job to process DLQ
export const processDLQ = inngest.createFunction(
  { id: 'process-webhook-dlq' },
  { cron: '0 */6 * * *' },  // Every 6 hours
  async ({ step }) => {
    const deadLetterEvents = await step.run('get-dlq', async () => {
      return db.webhookEvent.findMany({
        where: { status: 'dead_letter' },
        orderBy: { failedAt: 'asc' },
        take: 100,
      })
    })

    // Generate report for manual review
    if (deadLetterEvents.length > 0) {
      await step.run('send-report', async () => {
        await sendSlackMessage('#webhooks', {
          text: `🚨 ${deadLetterEvents.length} webhooks in DLQ need manual review`,
          blocks: deadLetterEvents.map(e => ({
            type: 'section',
            text: { type: 'mrkdwn', text: `*${e.type}*: ${e.error}` }
          }))
        })
      })
    }
  }
)
```

---

## Out-of-Order Event Handling

```typescript
// Handle events that arrive out of order
// e.g., subscription.updated arrives before subscription.created

async function handleSubscriptionEvent(event: Stripe.Event) {
  const subscription = event.data.object as Stripe.Subscription

  // Use upsert to handle any order
  await db.subscription.upsert({
    where: { stripeSubscriptionId: subscription.id },
    create: {
      stripeSubscriptionId: subscription.id,
      userId: subscription.metadata.userId,
      status: subscription.status,
      priceId: subscription.items.data[0].price.id,
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    },
    update: {
      status: subscription.status,
      priceId: subscription.items.data[0].price.id,
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
    },
  })
}

// For complex state transitions, use event timestamps
async function handleWithTimestamp(event: Stripe.Event) {
  const subscription = event.data.object as Stripe.Subscription
  const eventTime = new Date(event.created * 1000)

  const existing = await db.subscription.findUnique({
    where: { stripeSubscriptionId: subscription.id }
  })

  // Only update if this event is newer
  if (existing && existing.lastEventAt > eventTime) {
    console.log('Ignoring stale event')
    return
  }

  await db.subscription.upsert({
    where: { stripeSubscriptionId: subscription.id },
    create: { /* ... */ lastEventAt: eventTime },
    update: { /* ... */ lastEventAt: eventTime },
  })
}
```

---

## Stripe Event Reconciliation

```typescript
// Cron job to reconcile with Stripe API
export const reconcileStripeEvents = inngest.createFunction(
  { id: 'reconcile-stripe' },
  { cron: '0 3 * * *' },  // Daily at 3 AM
  async ({ step }) => {
    // Get subscriptions from Stripe
    const stripeSubscriptions = await step.run('fetch-stripe', async () => {
      const subs: Stripe.Subscription[] = []
      for await (const sub of stripe.subscriptions.list({ limit: 100 })) {
        subs.push(sub)
      }
      return subs
    })

    // Compare with database
    const discrepancies = await step.run('compare', async () => {
      const dbSubs = await db.subscription.findMany()
      const dbMap = new Map(dbSubs.map(s => [s.stripeSubscriptionId, s]))

      return stripeSubscriptions
        .filter(stripeSub => {
          const dbSub = dbMap.get(stripeSub.id)
          if (!dbSub) return true  // Missing in DB
          if (dbSub.status !== stripeSub.status) return true  // Status mismatch
          return false
        })
        .map(s => ({ id: s.id, status: s.status }))
    })

    // Alert if discrepancies found
    if (discrepancies.length > 0) {
      await step.run('alert', async () => {
        await sendSlackMessage('#billing', {
          text: `⚠️ ${discrepancies.length} subscription discrepancies found`,
        })
      })
    }
  }
)
```

---

## Security Checklist

```
Webhook Security:
□ Signature verification on EVERY request
□ Idempotency key stored before processing
□ Event ID uniqueness enforced (database constraint)
□ Payload size limits (reject oversized)
□ Timeout handling (don't process forever)
□ IP allowlisting (if provider supports)

Reliability:
□ Database transaction for state changes
□ Retry with exponential backoff
□ Dead letter queue for failures
□ Reconciliation job with source API
□ Alerting on DLQ growth
□ Metrics on processing time
```

---

## Common Pitfalls

```typescript
// ❌ WRONG: No idempotency
export async function POST(req: Request) {
  const event = await parseWebhook(req)
  await processEvent(event)  // May process twice on retry!
  return new Response('OK')
}

// ❌ WRONG: Ack before processing
export async function POST(req: Request) {
  const event = await parseWebhook(req)
  // If this crashes after ack, event is lost!
  return new Response('OK')
  await processEvent(event)
}

// ❌ WRONG: Synchronous processing (timeouts)
export async function POST(req: Request) {
  const event = await parseWebhook(req)
  await sendEmail()  // Takes 5 seconds
  await updateDatabase()  // Takes 3 seconds
  await notifySlack()  // Takes 2 seconds
  // Total: 10 seconds - webhook times out at 5s!
  return new Response('OK')
}

// ✅ CORRECT: Queue for async processing
export async function POST(req: Request) {
  const event = await parseWebhook(req)
  await saveEventToQueue(event)  // Fast
  return new Response('OK')  // Ack quickly
}
// Inngest/queue processes async
```
