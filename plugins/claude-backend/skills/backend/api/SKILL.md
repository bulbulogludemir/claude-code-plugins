# /api - API Route Scaffold Workflow

<command-name>api</command-name>

## Overview

Scaffold Next.js API routes, Server Actions, and Webhooks with proper auth, validation, and error handling.

## Trigger Keywords

new api, create endpoint, api route, server action, webhook, REST endpoint

## Templates

### 1. REST API Route (CRUD)

**File:** `src/app/api/{resource}/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { db } from '@/lib/db';
import { resources } from '@/lib/db/schema';
import { eq, and, desc } from 'drizzle-orm';
import { z } from 'zod';

// Validation schemas
const CreateSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().optional(),
});

const QuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

// GET - List resources (paginated)
export async function GET(request: NextRequest) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const query = QuerySchema.parse(Object.fromEntries(searchParams));

    const items = await db.query.resources.findMany({
      where: eq(resources.userId, userId),
      orderBy: desc(resources.createdAt),
      limit: query.limit,
      offset: (query.page - 1) * query.limit,
    });

    const total = await db
      .select({ count: sql`count(*)` })
      .from(resources)
      .where(eq(resources.userId, userId));

    return NextResponse.json({
      data: items,
      pagination: {
        page: query.page,
        limit: query.limit,
        total: Number(total[0].count),
      },
    });
  } catch (error) {
    console.error('[API] GET /resources error:', error);
    return NextResponse.json({ error: 'Failed to fetch resources' }, { status: 500 });
  }
}

// POST - Create resource
export async function POST(request: NextRequest) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const result = CreateSchema.safeParse(body);

    if (!result.success) {
      return NextResponse.json(
        { error: 'Validation failed', details: result.error.flatten() },
        { status: 400 }
      );
    }

    const [created] = await db
      .insert(resources)
      .values({
        ...result.data,
        userId,
      })
      .returning();

    return NextResponse.json(created, { status: 201 });
  } catch (error) {
    console.error('[API] POST /resources error:', error);
    return NextResponse.json({ error: 'Failed to create resource' }, { status: 500 });
  }
}
```

---

### 2. Dynamic Route (Single Resource)

**File:** `src/app/api/{resource}/[id]/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { db } from '@/lib/db';
import { resources } from '@/lib/db/schema';
import { eq, and } from 'drizzle-orm';
import { z } from 'zod';

const UpdateSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().optional(),
});

type Params = { params: Promise<{ id: string }> };

// GET - Single resource
export async function GET(request: NextRequest, { params }: Params) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    const resource = await db.query.resources.findFirst({
      where: and(eq(resources.id, id), eq(resources.userId, userId)),
    });

    if (!resource) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

    return NextResponse.json(resource);
  } catch (error) {
    console.error('[API] GET /resources/[id] error:', error);
    return NextResponse.json({ error: 'Failed to fetch resource' }, { status: 500 });
  }
}

// PATCH - Update resource
export async function PATCH(request: NextRequest, { params }: Params) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;
    const body = await request.json();
    const result = UpdateSchema.safeParse(body);

    if (!result.success) {
      return NextResponse.json(
        { error: 'Validation failed', details: result.error.flatten() },
        { status: 400 }
      );
    }

    // Ownership check
    const existing = await db.query.resources.findFirst({
      where: and(eq(resources.id, id), eq(resources.userId, userId)),
    });

    if (!existing) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

    const [updated] = await db
      .update(resources)
      .set({ ...result.data, updatedAt: new Date() })
      .where(eq(resources.id, id))
      .returning();

    return NextResponse.json(updated);
  } catch (error) {
    console.error('[API] PATCH /resources/[id] error:', error);
    return NextResponse.json({ error: 'Failed to update resource' }, { status: 500 });
  }
}

// DELETE - Delete resource
export async function DELETE(request: NextRequest, { params }: Params) {
  try {
    const { userId } = await auth();
    if (!userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id } = await params;

    // Ownership check
    const existing = await db.query.resources.findFirst({
      where: and(eq(resources.id, id), eq(resources.userId, userId)),
    });

    if (!existing) {
      return NextResponse.json({ error: 'Not found' }, { status: 404 });
    }

    await db.delete(resources).where(eq(resources.id, id));

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('[API] DELETE /resources/[id] error:', error);
    return NextResponse.json({ error: 'Failed to delete resource' }, { status: 500 });
  }
}
```

---

### 3. Server Action

**File:** `src/app/{feature}/actions.ts`

```typescript
'use server';

import { auth } from '@/lib/auth';
import { db } from '@/lib/db';
import { resources } from '@/lib/db/schema';
import { eq, and } from 'drizzle-orm';
import { revalidatePath } from 'next/cache';
import { z } from 'zod';

const CreateSchema = z.object({
  name: z.string().min(1, 'Name is required').max(200),
  description: z.string().optional(),
});

export type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: string };

export async function createResource(
  formData: FormData
): Promise<ActionResult<typeof resources.$inferSelect>> {
  try {
    const { userId } = await auth();
    if (!userId) {
      return { success: false, error: 'Unauthorized' };
    }

    const raw = {
      name: formData.get('name'),
      description: formData.get('description'),
    };

    const result = CreateSchema.safeParse(raw);
    if (!result.success) {
      return { success: false, error: result.error.errors[0].message };
    }

    const [created] = await db
      .insert(resources)
      .values({ ...result.data, userId })
      .returning();

    revalidatePath('/resources');

    return { success: true, data: created };
  } catch (error) {
    console.error('[Action] createResource error:', error);
    return { success: false, error: 'Failed to create resource' };
  }
}

export async function deleteResource(id: string): Promise<ActionResult<void>> {
  try {
    const { userId } = await auth();
    if (!userId) {
      return { success: false, error: 'Unauthorized' };
    }

    const existing = await db.query.resources.findFirst({
      where: and(eq(resources.id, id), eq(resources.userId, userId)),
    });

    if (!existing) {
      return { success: false, error: 'Not found' };
    }

    await db.delete(resources).where(eq(resources.id, id));

    revalidatePath('/resources');

    return { success: true, data: undefined };
  } catch (error) {
    console.error('[Action] deleteResource error:', error);
    return { success: false, error: 'Failed to delete resource' };
  }
}
```

---

### 4. Webhook Endpoint

**File:** `src/app/api/webhooks/{service}/route.ts`

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { headers } from 'next/headers';
import crypto from 'crypto';

// Skip auth for webhooks - verify signature instead
export const dynamic = 'force-dynamic';

export async function POST(request: NextRequest) {
  try {
    // Get signature from headers
    const headersList = await headers();
    const signature = headersList.get('x-webhook-signature');

    if (!signature) {
      return NextResponse.json({ error: 'Missing signature' }, { status: 401 });
    }

    // Get raw body for signature verification
    const body = await request.text();

    // Verify signature
    const secret = process.env.WEBHOOK_SECRET!;
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(body)
      .digest('hex');

    if (!crypto.timingSafeEqual(
      Buffer.from(signature),
      Buffer.from(expectedSignature)
    )) {
      return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
    }

    // Parse and process webhook
    const payload = JSON.parse(body);

    // Handle different event types
    switch (payload.type) {
      case 'payment.completed':
        await handlePaymentCompleted(payload.data);
        break;
      case 'subscription.cancelled':
        await handleSubscriptionCancelled(payload.data);
        break;
      default:
        console.log(`[Webhook] Unhandled event type: ${payload.type}`);
    }

    return NextResponse.json({ received: true });
  } catch (error) {
    console.error('[Webhook] Error:', error);
    return NextResponse.json({ error: 'Webhook processing failed' }, { status: 500 });
  }
}

async function handlePaymentCompleted(data: unknown) {
  // Process payment completion
}

async function handleSubscriptionCancelled(data: unknown) {
  // Process subscription cancellation
}
```

---

## Checklist

```
□ Auth check at start of every handler
□ Zod validation for all input
□ Ownership check for resource access
□ Proper error handling with try/catch
□ Generic errors to client, detailed to logs
□ Pagination for list endpoints
□ TypeScript compiles: npx tsc --noEmit
```

## Next.js 16 Params Type

Dynamic route params are now `Promise<{ id: string }>`:

```typescript
type Params = { params: Promise<{ id: string }> };

export async function GET(request: NextRequest, { params }: Params) {
  const { id } = await params;  // Must await
  // ...
}
```

## Common Patterns

### Rate Limiting
```typescript
import { rateLimit } from '@/lib/rate-limit';

export async function POST(request: NextRequest) {
  const { userId } = await auth();
  const limited = await rateLimit(userId, 'api-name', 10, 60);
  if (limited) {
    return NextResponse.json({ error: 'Rate limited' }, { status: 429 });
  }
  // ...
}
```

### File Upload
```typescript
export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get('file') as File;

  const buffer = Buffer.from(await file.arrayBuffer());
  // Upload to S3/R2...
}
```
