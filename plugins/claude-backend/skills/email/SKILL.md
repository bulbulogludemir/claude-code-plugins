---
name: email
description: Email sending, templates, transactional workflows - Resend, React Email
triggers:
  - email
  - notification
  - resend
  - transactional
  - welcome email
---

# Email Skill

Patterns for transactional email with Resend SDK and React Email templates: sending, templates, queues, verification, and unsubscribe handling.

## 1. Resend SDK Setup

**File:** `src/lib/email/resend.ts`

```typescript
import { Resend } from 'resend'

if (!process.env.RESEND_API_KEY) {
  throw new Error('RESEND_API_KEY is not set')
}

export const resend = new Resend(process.env.RESEND_API_KEY)

export const EMAIL_FROM = 'Site Name <notifications@example.com>'
export const EMAIL_REPLY_TO = 'support@example.com'
```

---

## 2. Send Email Helper

**File:** `src/lib/email/send.ts`

```typescript
import { resend, EMAIL_FROM, EMAIL_REPLY_TO } from './resend'
import { render } from '@react-email/components'
import type { ReactElement } from 'react'

interface SendEmailOptions {
  to: string | string[]
  subject: string
  template: ReactElement
  replyTo?: string
  tags?: Array<{ name: string; value: string }>
}

export async function sendEmail({
  to,
  subject,
  template,
  replyTo = EMAIL_REPLY_TO,
  tags,
}: SendEmailOptions) {
  const html = await render(template)

  const { data, error } = await resend.emails.send({
    from: EMAIL_FROM,
    to: Array.isArray(to) ? to : [to],
    subject,
    html,
    replyTo,
    tags,
  })

  if (error) {
    console.error('[Email] Send failed:', { to, subject, error })
    throw new Error(`Failed to send email: ${error.message}`)
  }

  console.log('[Email] Sent:', { to, subject, id: data?.id })
  return data
}
```

---

## 3. React Email Templates

### Base Layout

**File:** `src/lib/email/templates/layout.tsx`

```typescript
import {
  Body,
  Container,
  Head,
  Html,
  Img,
  Link,
  Preview,
  Section,
  Text,
} from '@react-email/components'

interface EmailLayoutProps {
  preview: string
  children: React.ReactNode
}

const baseUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'https://example.com'

export function EmailLayout({ preview, children }: EmailLayoutProps) {
  return (
    <Html>
      <Head />
      <Preview>{preview}</Preview>
      <Body style={body}>
        <Container style={container}>
          <Section style={header}>
            <Img
              src={`${baseUrl}/logo.png`}
              width={120}
              height={36}
              alt="Site Name"
            />
          </Section>

          {children}

          <Section style={footer}>
            <Text style={footerText}>
              Site Name, Inc. | 123 Main St, City, State 12345
            </Text>
            <Text style={footerText}>
              <Link href={`${baseUrl}/settings/notifications`} style={footerLink}>
                Notification preferences
              </Link>
              {' | '}
              <Link href={`${baseUrl}/unsubscribe`} style={footerLink}>
                Unsubscribe
              </Link>
            </Text>
          </Section>
        </Container>
      </Body>
    </Html>
  )
}

const body = {
  backgroundColor: '#f4f4f5',
  fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
  margin: '0',
  padding: '0',
}

const container = {
  backgroundColor: '#ffffff',
  border: '1px solid #e4e4e7',
  borderRadius: '8px',
  margin: '40px auto',
  maxWidth: '560px',
  padding: '0',
}

const header = {
  padding: '32px 40px 0',
}

const footer = {
  borderTop: '1px solid #e4e4e7',
  padding: '24px 40px',
  textAlign: 'center' as const,
}

const footerText = {
  color: '#71717a',
  fontSize: '12px',
  lineHeight: '20px',
  margin: '0',
}

const footerLink = {
  color: '#71717a',
  textDecoration: 'underline',
}
```

### Welcome Email

**File:** `src/lib/email/templates/welcome.tsx`

```typescript
import { Button, Heading, Section, Text } from '@react-email/components'
import { EmailLayout } from './layout'

interface WelcomeEmailProps {
  name: string
  loginUrl: string
}

export function WelcomeEmail({ name, loginUrl }: WelcomeEmailProps) {
  return (
    <EmailLayout preview={`Welcome to Site Name, ${name}!`}>
      <Section style={content}>
        <Heading style={heading}>Welcome, {name}!</Heading>
        <Text style={paragraph}>
          Thanks for joining Site Name. Your account is ready and you can start
          using all features right away.
        </Text>
        <Text style={paragraph}>Here is what you can do next:</Text>
        <Text style={listItem}>1. Complete your profile</Text>
        <Text style={listItem}>2. Explore the dashboard</Text>
        <Text style={listItem}>3. Invite your team members</Text>
        <Section style={buttonContainer}>
          <Button style={button} href={loginUrl}>
            Get Started
          </Button>
        </Section>
      </Section>
    </EmailLayout>
  )
}

const content = { padding: '24px 40px' }
const heading = { color: '#09090b', fontSize: '24px', fontWeight: '600', margin: '0 0 16px' }
const paragraph = { color: '#3f3f46', fontSize: '15px', lineHeight: '24px', margin: '0 0 12px' }
const listItem = { color: '#3f3f46', fontSize: '15px', lineHeight: '24px', margin: '0 0 4px', paddingLeft: '8px' }
const buttonContainer = { textAlign: 'center' as const, margin: '24px 0 8px' }
const button = {
  backgroundColor: '#18181b',
  borderRadius: '6px',
  color: '#fafafa',
  display: 'inline-block',
  fontSize: '14px',
  fontWeight: '600',
  padding: '12px 24px',
  textDecoration: 'none',
}
```

### Password Reset Email

**File:** `src/lib/email/templates/password-reset.tsx`

```typescript
import { Button, Heading, Section, Text } from '@react-email/components'
import { EmailLayout } from './layout'

interface PasswordResetEmailProps {
  name: string
  resetUrl: string
  expiresInMinutes: number
}

export function PasswordResetEmail({
  name,
  resetUrl,
  expiresInMinutes,
}: PasswordResetEmailProps) {
  return (
    <EmailLayout preview="Reset your password">
      <Section style={content}>
        <Heading style={heading}>Reset Your Password</Heading>
        <Text style={paragraph}>Hi {name},</Text>
        <Text style={paragraph}>
          We received a request to reset your password. Click the button below to
          choose a new password. This link expires in {expiresInMinutes} minutes.
        </Text>
        <Section style={buttonContainer}>
          <Button style={button} href={resetUrl}>
            Reset Password
          </Button>
        </Section>
        <Text style={muted}>
          If you did not request a password reset, you can safely ignore this
          email. Your password will not be changed.
        </Text>
      </Section>
    </EmailLayout>
  )
}

const content = { padding: '24px 40px' }
const heading = { color: '#09090b', fontSize: '24px', fontWeight: '600', margin: '0 0 16px' }
const paragraph = { color: '#3f3f46', fontSize: '15px', lineHeight: '24px', margin: '0 0 12px' }
const buttonContainer = { textAlign: 'center' as const, margin: '24px 0 8px' }
const button = {
  backgroundColor: '#18181b',
  borderRadius: '6px',
  color: '#fafafa',
  display: 'inline-block',
  fontSize: '14px',
  fontWeight: '600',
  padding: '12px 24px',
  textDecoration: 'none',
}
const muted = { color: '#a1a1aa', fontSize: '13px', lineHeight: '20px', margin: '16px 0 0' }
```

### Notification Email

**File:** `src/lib/email/templates/notification.tsx`

```typescript
import { Button, Heading, Section, Text } from '@react-email/components'
import { EmailLayout } from './layout'

interface NotificationEmailProps {
  name: string
  title: string
  message: string
  actionLabel: string
  actionUrl: string
}

export function NotificationEmail({
  name,
  title,
  message,
  actionLabel,
  actionUrl,
}: NotificationEmailProps) {
  return (
    <EmailLayout preview={title}>
      <Section style={content}>
        <Heading style={heading}>{title}</Heading>
        <Text style={paragraph}>Hi {name},</Text>
        <Text style={paragraph}>{message}</Text>
        <Section style={buttonContainer}>
          <Button style={button} href={actionUrl}>
            {actionLabel}
          </Button>
        </Section>
      </Section>
    </EmailLayout>
  )
}

const content = { padding: '24px 40px' }
const heading = { color: '#09090b', fontSize: '24px', fontWeight: '600', margin: '0 0 16px' }
const paragraph = { color: '#3f3f46', fontSize: '15px', lineHeight: '24px', margin: '0 0 12px' }
const buttonContainer = { textAlign: 'center' as const, margin: '24px 0 8px' }
const button = {
  backgroundColor: '#18181b',
  borderRadius: '6px',
  color: '#fafafa',
  display: 'inline-block',
  fontSize: '14px',
  fontWeight: '600',
  padding: '12px 24px',
  textDecoration: 'none',
}
```

---

## 4. Email Service Layer

**File:** `src/lib/email/service.ts`

```typescript
import { sendEmail } from './send'
import { WelcomeEmail } from './templates/welcome'
import { PasswordResetEmail } from './templates/password-reset'
import { NotificationEmail } from './templates/notification'

const baseUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'https://example.com'

export const emailService = {
  async sendWelcome(user: { email: string; name: string }) {
    return sendEmail({
      to: user.email,
      subject: 'Welcome to Site Name!',
      template: WelcomeEmail({
        name: user.name,
        loginUrl: `${baseUrl}/login`,
      }),
      tags: [{ name: 'category', value: 'welcome' }],
    })
  },

  async sendPasswordReset(user: { email: string; name: string }, token: string) {
    return sendEmail({
      to: user.email,
      subject: 'Reset your password',
      template: PasswordResetEmail({
        name: user.name,
        resetUrl: `${baseUrl}/auth/reset-password?token=${token}`,
        expiresInMinutes: 60,
      }),
      tags: [{ name: 'category', value: 'password-reset' }],
    })
  },

  async sendNotification(
    user: { email: string; name: string },
    notification: {
      title: string
      message: string
      actionLabel: string
      actionUrl: string
    }
  ) {
    return sendEmail({
      to: user.email,
      subject: notification.title,
      template: NotificationEmail({
        name: user.name,
        ...notification,
      }),
      tags: [{ name: 'category', value: 'notification' }],
    })
  },
}
```

---

## 5. Batch Sending

```typescript
// lib/email/batch.ts
import { resend, EMAIL_FROM } from './resend'
import { render } from '@react-email/components'
import type { ReactElement } from 'react'

interface BatchRecipient {
  to: string
  subject: string
  template: ReactElement
}

export async function sendBatch(recipients: BatchRecipient[]) {
  // Resend batch limit is 100 per request
  const BATCH_SIZE = 100
  const results: Array<{ id?: string; error?: string }> = []

  for (let i = 0; i < recipients.length; i += BATCH_SIZE) {
    const batch = recipients.slice(i, i + BATCH_SIZE)

    const emails = await Promise.all(
      batch.map(async (recipient) => ({
        from: EMAIL_FROM,
        to: [recipient.to],
        subject: recipient.subject,
        html: await render(recipient.template),
      }))
    )

    const { data, error } = await resend.batch.send(emails)

    if (error) {
      console.error(`[Email] Batch ${i / BATCH_SIZE + 1} failed:`, error)
      results.push(
        ...batch.map(() => ({ error: error.message }))
      )
    } else if (data) {
      results.push(
        ...data.data.map((d) => ({ id: d.id }))
      )
    }
  }

  const sent = results.filter((r) => r.id).length
  const failed = results.filter((r) => r.error).length
  console.log(`[Email] Batch complete: ${sent} sent, ${failed} failed`)

  return results
}
```

---

## 6. Queue Integration (BullMQ)

**File:** `src/lib/email/queue.ts`

```typescript
import { Queue, Worker } from 'bullmq'
import { Redis } from 'ioredis'
import { emailService } from './service'

const connection = new Redis(process.env.REDIS_URL!, {
  maxRetriesPerRequest: null,
})

// Define job types
type EmailJobData =
  | { type: 'welcome'; user: { email: string; name: string } }
  | { type: 'password-reset'; user: { email: string; name: string }; token: string }
  | {
      type: 'notification'
      user: { email: string; name: string }
      notification: {
        title: string
        message: string
        actionLabel: string
        actionUrl: string
      }
    }

export const emailQueue = new Queue<EmailJobData>('email', {
  connection,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 5000,
    },
    removeOnComplete: { count: 1000 },
    removeOnFail: { count: 5000 },
  },
})

// Queue helper functions
export async function queueWelcomeEmail(user: { email: string; name: string }) {
  return emailQueue.add('welcome', { type: 'welcome', user })
}

export async function queuePasswordResetEmail(
  user: { email: string; name: string },
  token: string
) {
  return emailQueue.add('password-reset', {
    type: 'password-reset',
    user,
    token,
  })
}

export async function queueNotificationEmail(
  user: { email: string; name: string },
  notification: {
    title: string
    message: string
    actionLabel: string
    actionUrl: string
  }
) {
  return emailQueue.add('notification', {
    type: 'notification',
    user,
    notification,
  })
}
```

### Queue Worker

**File:** `src/lib/email/worker.ts`

```typescript
import { Worker } from 'bullmq'
import { Redis } from 'ioredis'
import { emailService } from './service'
import type { Job } from 'bullmq'

const connection = new Redis(process.env.REDIS_URL!, {
  maxRetriesPerRequest: null,
})

type EmailJobData =
  | { type: 'welcome'; user: { email: string; name: string } }
  | { type: 'password-reset'; user: { email: string; name: string }; token: string }
  | {
      type: 'notification'
      user: { email: string; name: string }
      notification: {
        title: string
        message: string
        actionLabel: string
        actionUrl: string
      }
    }

const emailWorker = new Worker<EmailJobData>(
  'email',
  async (job: Job<EmailJobData>) => {
    console.log(`[EmailWorker] Processing ${job.data.type} for ${job.data.user.email}`)

    switch (job.data.type) {
      case 'welcome':
        await emailService.sendWelcome(job.data.user)
        break
      case 'password-reset':
        await emailService.sendPasswordReset(job.data.user, job.data.token)
        break
      case 'notification':
        await emailService.sendNotification(
          job.data.user,
          job.data.notification
        )
        break
    }
  },
  {
    connection,
    concurrency: 5,
    limiter: {
      max: 10,
      duration: 1000,
    },
  }
)

emailWorker.on('completed', (job) => {
  console.log(`[EmailWorker] Completed: ${job.id} (${job.data.type})`)
})

emailWorker.on('failed', (job, error) => {
  console.error(
    `[EmailWorker] Failed: ${job?.id} (${job?.data.type})`,
    error.message
  )
})

export { emailWorker }
```

---

## 7. Email Verification Flow

**File:** `src/lib/email/verification.ts`

```typescript
import { db } from '@/lib/db'
import { users, emailVerificationTokens } from '@/lib/db/schema'
import { eq, and, gt } from 'drizzle-orm'
import crypto from 'crypto'
import { sendEmail } from './send'
import { Button, Heading, Section, Text } from '@react-email/components'
import { EmailLayout } from './templates/layout'

const baseUrl = process.env.NEXT_PUBLIC_APP_URL ?? 'https://example.com'
const TOKEN_EXPIRY_HOURS = 24

export async function sendVerificationEmail(userId: string, email: string) {
  // Invalidate existing tokens
  await db
    .delete(emailVerificationTokens)
    .where(eq(emailVerificationTokens.userId, userId))

  // Generate new token
  const token = crypto.randomBytes(32).toString('hex')
  const expiresAt = new Date(Date.now() + TOKEN_EXPIRY_HOURS * 60 * 60 * 1000)

  await db.insert(emailVerificationTokens).values({
    userId,
    token,
    expiresAt,
  })

  const verifyUrl = `${baseUrl}/auth/verify-email?token=${token}`

  await sendEmail({
    to: email,
    subject: 'Verify your email address',
    template: VerificationEmail({ verifyUrl }),
    tags: [{ name: 'category', value: 'verification' }],
  })
}

export async function verifyEmail(token: string): Promise<boolean> {
  const record = await db.query.emailVerificationTokens.findFirst({
    where: and(
      eq(emailVerificationTokens.token, token),
      gt(emailVerificationTokens.expiresAt, new Date())
    ),
  })

  if (!record) return false

  await db
    .update(users)
    .set({ emailVerified: true, emailVerifiedAt: new Date() })
    .where(eq(users.id, record.userId))

  await db
    .delete(emailVerificationTokens)
    .where(eq(emailVerificationTokens.userId, record.userId))

  return true
}

function VerificationEmail({ verifyUrl }: { verifyUrl: string }) {
  return (
    <EmailLayout preview="Verify your email address">
      <Section style={{ padding: '24px 40px' }}>
        <Heading style={{ color: '#09090b', fontSize: '24px', fontWeight: '600', margin: '0 0 16px' }}>
          Verify Your Email
        </Heading>
        <Text style={{ color: '#3f3f46', fontSize: '15px', lineHeight: '24px', margin: '0 0 12px' }}>
          Click the button below to verify your email address. This link expires
          in {TOKEN_EXPIRY_HOURS} hours.
        </Text>
        <Section style={{ textAlign: 'center' as const, margin: '24px 0 8px' }}>
          <Button
            style={{
              backgroundColor: '#18181b',
              borderRadius: '6px',
              color: '#fafafa',
              display: 'inline-block',
              fontSize: '14px',
              fontWeight: '600',
              padding: '12px 24px',
              textDecoration: 'none',
            }}
            href={verifyUrl}
          >
            Verify Email Address
          </Button>
        </Section>
      </Section>
    </EmailLayout>
  )
}
```

---

## 8. Unsubscribe Handling

**File:** `src/lib/email/unsubscribe.ts`

```typescript
import { db } from '@/lib/db'
import { emailPreferences } from '@/lib/db/schema'
import { eq } from 'drizzle-orm'
import crypto from 'crypto'

const UNSUBSCRIBE_SECRET = process.env.UNSUBSCRIBE_SECRET!

// Generate signed unsubscribe token
export function generateUnsubscribeToken(userId: string): string {
  const payload = `${userId}:${Date.now()}`
  const signature = crypto
    .createHmac('sha256', UNSUBSCRIBE_SECRET)
    .update(payload)
    .digest('hex')
  return Buffer.from(`${payload}:${signature}`).toString('base64url')
}

// Verify and extract userId from token
export function verifyUnsubscribeToken(token: string): string | null {
  try {
    const decoded = Buffer.from(token, 'base64url').toString()
    const parts = decoded.split(':')
    if (parts.length !== 3) return null

    const [userId, timestamp, signature] = parts
    const payload = `${userId}:${timestamp}`
    const expected = crypto
      .createHmac('sha256', UNSUBSCRIBE_SECRET)
      .update(payload)
      .digest('hex')

    if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) {
      return null
    }

    return userId
  } catch {
    return null
  }
}

// Unsubscribe categories
type EmailCategory = 'marketing' | 'product_updates' | 'notifications' | 'all'

export async function unsubscribe(userId: string, category: EmailCategory) {
  if (category === 'all') {
    await db
      .update(emailPreferences)
      .set({
        marketing: false,
        productUpdates: false,
        notifications: false,
        unsubscribedAt: new Date(),
      })
      .where(eq(emailPreferences.userId, userId))
  } else {
    const field = {
      marketing: 'marketing',
      product_updates: 'productUpdates',
      notifications: 'notifications',
    }[category] as 'marketing' | 'productUpdates' | 'notifications'

    await db
      .update(emailPreferences)
      .set({ [field]: false })
      .where(eq(emailPreferences.userId, userId))
  }
}

// Check if user is subscribed before sending
export async function isSubscribed(
  userId: string,
  category: 'marketing' | 'productUpdates' | 'notifications'
): Promise<boolean> {
  const prefs = await db.query.emailPreferences.findFirst({
    where: eq(emailPreferences.userId, userId),
  })

  // Default to subscribed if no preferences exist
  if (!prefs) return true

  return prefs[category]
}
```

### Unsubscribe API Route

```typescript
// app/api/unsubscribe/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { verifyUnsubscribeToken, unsubscribe } from '@/lib/email/unsubscribe'
import { z } from 'zod'

const UnsubscribeSchema = z.object({
  token: z.string(),
  category: z.enum(['marketing', 'product_updates', 'notifications', 'all']).default('all'),
})

export async function POST(request: NextRequest) {
  const body = await request.json()
  const result = UnsubscribeSchema.safeParse(body)

  if (!result.success) {
    return NextResponse.json({ error: 'Invalid request' }, { status: 400 })
  }

  const userId = verifyUnsubscribeToken(result.data.token)
  if (!userId) {
    return NextResponse.json({ error: 'Invalid or expired token' }, { status: 400 })
  }

  await unsubscribe(userId, result.data.category)

  return NextResponse.json({ success: true })
}
```

---

## 9. Error Handling and Retry

```typescript
// lib/email/send.ts (enhanced version)
import { resend, EMAIL_FROM, EMAIL_REPLY_TO } from './resend'
import { render } from '@react-email/components'
import type { ReactElement } from 'react'

interface SendEmailOptions {
  to: string | string[]
  subject: string
  template: ReactElement
  replyTo?: string
  tags?: Array<{ name: string; value: string }>
  idempotencyKey?: string
}

export async function sendEmail({
  to,
  subject,
  template,
  replyTo = EMAIL_REPLY_TO,
  tags,
  idempotencyKey,
}: SendEmailOptions) {
  const html = await render(template)

  const headers: Record<string, string> = {}
  if (idempotencyKey) {
    headers['Idempotency-Key'] = idempotencyKey
  }

  let lastError: Error | null = null

  for (let attempt = 0; attempt < 3; attempt++) {
    const { data, error } = await resend.emails.send({
      from: EMAIL_FROM,
      to: Array.isArray(to) ? to : [to],
      subject,
      html,
      replyTo,
      tags,
      headers,
    })

    if (!error) {
      console.log('[Email] Sent:', { to, subject, id: data?.id, attempt })
      return data
    }

    lastError = new Error(error.message)

    // Only retry on transient errors
    if (error.name === 'validation_error' || error.name === 'not_found') {
      throw lastError
    }

    const delay = 1000 * 2 ** attempt
    console.warn(`[Email] Retry ${attempt + 1}/3 after ${delay}ms:`, error.message)
    await new Promise((resolve) => setTimeout(resolve, delay))
  }

  console.error('[Email] All retries failed:', { to, subject })
  throw lastError
}
```

---

## Common Patterns

### Send Email After User Action (Server Action)

```typescript
'use server'

import { auth } from '@/lib/auth'
import { db } from '@/lib/db'
import { queueWelcomeEmail } from '@/lib/email/queue'

export async function registerUser(formData: FormData) {
  const { userId } = await auth()
  // ... create user logic ...

  const user = await db.query.users.findFirst({
    where: eq(users.id, userId),
  })

  if (user) {
    await queueWelcomeEmail({ email: user.email, name: user.name })
  }
}
```

### Webhook-Triggered Email

```typescript
// app/api/webhooks/stripe/route.ts
import { emailService } from '@/lib/email/service'

// Inside webhook handler:
case 'invoice.payment_succeeded': {
  const user = await getUserByStripeCustomerId(event.data.object.customer)
  if (user) {
    await emailService.sendNotification(user, {
      title: 'Payment received',
      message: `We received your payment of $${(event.data.object.amount_paid / 100).toFixed(2)}. Thank you!`,
      actionLabel: 'View Invoice',
      actionUrl: `${baseUrl}/billing/invoices/${event.data.object.id}`,
    })
  }
  break
}
```

### Email Preview Route (Development)

```typescript
// app/api/email-preview/[template]/route.tsx
import { NextRequest } from 'next/server'
import { render } from '@react-email/components'
import { WelcomeEmail } from '@/lib/email/templates/welcome'
import { PasswordResetEmail } from '@/lib/email/templates/password-reset'

const templates: Record<string, () => React.ReactElement> = {
  welcome: () => WelcomeEmail({ name: 'John', loginUrl: 'https://example.com/login' }),
  'password-reset': () =>
    PasswordResetEmail({ name: 'John', resetUrl: 'https://example.com/reset', expiresInMinutes: 60 }),
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ template: string }> }
) {
  if (process.env.NODE_ENV !== 'development') {
    return new Response('Not found', { status: 404 })
  }

  const { template } = await params
  const factory = templates[template]

  if (!factory) {
    return new Response(`Unknown template: ${template}`, { status: 404 })
  }

  const html = await render(factory())
  return new Response(html, { headers: { 'Content-Type': 'text/html' } })
}
```

---

## Checklist

```
[ ] Resend API key in server-only env var
[ ] Email FROM address uses verified domain
[ ] All templates use shared EmailLayout
[ ] Unsubscribe link in every email footer
[ ] Email preferences check before sending marketing
[ ] Signed unsubscribe tokens (HMAC)
[ ] Retry logic with exponential backoff
[ ] Idempotency keys for critical emails
[ ] Queue for async sending (BullMQ)
[ ] Worker with concurrency limits
[ ] Error logging with recipient and subject
[ ] Email preview route (dev only)
[ ] tsc --noEmit = 0 errors
```

---

## Dependencies

```bash
npm install resend @react-email/components
# Queue (optional)
npm install bullmq ioredis
```

## Red Flags (STOP)

| If You See | Fix |
|------------|-----|
| `NEXT_PUBLIC_RESEND_API_KEY` | Move to server-only env var |
| Hardcoded email addresses in templates | Pull from DB or env vars |
| No unsubscribe link | Add to EmailLayout footer |
| Sending without subscription check | Add isSubscribed() check |
| Unsigned unsubscribe URLs | Use generateUnsubscribeToken() |
| Email preview route in production | Guard with NODE_ENV check |
| No retry on send failure | Use retry loop or queue |
| Inline HTML strings instead of React Email | Use template components |
