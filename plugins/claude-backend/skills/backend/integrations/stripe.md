---
name: stripe
description: Use when integrating payments with Stripe. Checkout, subscriptions, webhooks, customer portal, billing. Triggers on: stripe, payment, checkout, subscription, billing, charge, invoice, webhook, customer portal, price.
version: 1.0.0
detect: ["stripe"]
---

# Stripe

Payment processing for subscriptions and one-time payments.

## Setup

```typescript
// lib/stripe.ts
import Stripe from 'stripe'

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-04-10',
  typescript: true,
})
```

## Checkout Session

```typescript
// app/api/checkout/route.ts
import { stripe } from '@/lib/stripe'
import { auth } from '@clerk/nextjs/server'

export async function POST(req: Request) {
  const { userId } = auth()
  if (!userId) {
    return new Response('Unauthorized', { status: 401 })
  }

  const { priceId } = await req.json()

  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    payment_method_types: ['card'],
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard?success=true`,
    cancel_url: `${process.env.NEXT_PUBLIC_APP_URL}/pricing?canceled=true`,
    client_reference_id: userId,
    metadata: { userId },
  })

  return Response.json({ url: session.url })
}

// Client usage
async function handleCheckout(priceId: string) {
  const res = await fetch('/api/checkout', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ priceId }),
  })
  const { url } = await res.json()
  window.location.href = url
}
```

## Webhook Handler

```typescript
// app/api/webhooks/stripe/route.ts
import { headers } from 'next/headers'
import { stripe } from '@/lib/stripe'
import Stripe from 'stripe'

export async function POST(req: Request) {
  const body = await req.text()
  const signature = headers().get('stripe-signature')!

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(
      body,
      signature,
      process.env.STRIPE_WEBHOOK_SECRET!
    )
  } catch (err) {
    console.error('Webhook signature verification failed')
    return new Response('Invalid signature', { status: 400 })
  }

  // Idempotency check
  const existingEvent = await db.webhookEvent.findUnique({
    where: { stripeEventId: event.id },
  })
  if (existingEvent) {
    return new Response('Already processed', { status: 200 })
  }

  try {
    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object as Stripe.Checkout.Session
        await handleCheckoutComplete(session)
        break
      }
      case 'customer.subscription.updated': {
        const subscription = event.data.object as Stripe.Subscription
        await handleSubscriptionUpdate(subscription)
        break
      }
      case 'customer.subscription.deleted': {
        const subscription = event.data.object as Stripe.Subscription
        await handleSubscriptionCancel(subscription)
        break
      }
      case 'invoice.payment_failed': {
        const invoice = event.data.object as Stripe.Invoice
        await handlePaymentFailed(invoice)
        break
      }
    }

    // Mark as processed
    await db.webhookEvent.create({
      data: {
        stripeEventId: event.id,
        type: event.type,
        processedAt: new Date(),
      },
    })

    return new Response('OK', { status: 200 })
  } catch (error) {
    console.error('Webhook processing error:', error)
    return new Response('Processing error', { status: 500 })
  }
}

async function handleCheckoutComplete(session: Stripe.Checkout.Session) {
  const userId = session.metadata?.userId
  if (!userId) return

  const subscription = await stripe.subscriptions.retrieve(
    session.subscription as string
  )

  await db.user.update({
    where: { id: userId },
    data: {
      stripeCustomerId: session.customer as string,
      stripeSubscriptionId: subscription.id,
      stripePriceId: subscription.items.data[0].price.id,
      stripeCurrentPeriodEnd: new Date(subscription.current_period_end * 1000),
    },
  })
}
```

## Customer Portal

```typescript
// app/api/portal/route.ts
export async function POST(req: Request) {
  const { userId } = auth()
  if (!userId) {
    return new Response('Unauthorized', { status: 401 })
  }

  const user = await db.user.findUnique({
    where: { id: userId },
    select: { stripeCustomerId: true },
  })

  if (!user?.stripeCustomerId) {
    return new Response('No subscription', { status: 400 })
  }

  const session = await stripe.billingPortal.sessions.create({
    customer: user.stripeCustomerId,
    return_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard`,
  })

  return Response.json({ url: session.url })
}
```

## Subscription Status

```typescript
// lib/subscription.ts
export async function getUserSubscription(userId: string) {
  const user = await db.user.findUnique({
    where: { id: userId },
    select: {
      stripeSubscriptionId: true,
      stripeCurrentPeriodEnd: true,
      stripePriceId: true,
    },
  })

  if (!user?.stripeSubscriptionId) {
    return { isPro: false, isCanceled: false }
  }

  const isPro =
    user.stripePriceId &&
    user.stripeCurrentPeriodEnd &&
    user.stripeCurrentPeriodEnd.getTime() > Date.now()

  return { isPro, periodEnd: user.stripeCurrentPeriodEnd }
}

// Usage
const { isPro } = await getUserSubscription(userId)
if (!isPro) {
  redirect('/pricing')
}
```

## Products & Prices

```typescript
// Fetch products for pricing page
export async function getProducts() {
  const products = await stripe.products.list({
    active: true,
    expand: ['data.default_price'],
  })

  return products.data.map((product) => ({
    id: product.id,
    name: product.name,
    description: product.description,
    price: product.default_price as Stripe.Price,
  }))
}
```
