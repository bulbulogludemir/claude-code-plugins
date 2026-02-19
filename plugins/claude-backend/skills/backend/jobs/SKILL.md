# /job - BullMQ Job Scaffold Workflow

<command-name>job</command-name>

## Overview

Scaffold a new BullMQ job type with proper type definitions, handler, and processor routing.

## Trigger Keywords

new job, create job, bullmq, queue job, background job, worker task

## Project Structure

```
src/lib/queue/
├── index.ts              # Queue config + job type definitions
├── processor.ts          # Job routing to handlers
└── handlers/
    ├── index.ts          # Handler exports
    └── {job-name}.ts     # Individual handlers
```

## Workflow

### Step 1: Define Job Type in `src/lib/queue/index.ts`

Add to the `JobType` union:
```typescript
export type JobType =
  | "existing-job"
  // Add new job type
  | "your-new-job";
```

Add job data interface:
```typescript
export interface YourNewJobData {
  type: "your-new-job";
  userId: string;
  legacyJobId: string;  // For progress tracking via legacy job store
  payload: {
    // Job-specific fields
    targetId: string;
    options?: Record<string, unknown>;
  };
}
```

Add to `JobData` union:
```typescript
export type JobData =
  | ExistingJobData
  | YourNewJobData;  // Add here
```

---

### Step 2: Create Handler in `src/lib/queue/handlers/{name}.ts`

```typescript
/**
 * Your New Job Handler
 */

import { Job } from 'bullmq';
import { db } from '@/lib/db';
import { updateJobProgress } from '@/lib/jobs/store';
import type { YourNewJobData } from '../index';

export async function processYourNewJob(job: Job<YourNewJobData>) {
  const { userId, legacyJobId, payload } = job.data;
  const { targetId, options } = payload;

  try {
    // Update progress: started
    await updateJobProgress(legacyJobId, {
      status: 'processing',
      progress: 10,
      step: 'Starting job...',
    });

    // Main job logic here
    // ...

    // Update progress: midway
    await updateJobProgress(legacyJobId, {
      progress: 50,
      step: 'Processing...',
    });

    // Complete job
    const result = { /* your result */ };

    await updateJobProgress(legacyJobId, {
      status: 'completed',
      progress: 100,
      result,
    });

    return result;

  } catch (error) {
    console.error('[YourNewJob] Error:', error);

    await updateJobProgress(legacyJobId, {
      status: 'failed',
      error: error instanceof Error ? error.message : 'Unknown error',
    });

    throw error; // Re-throw for BullMQ retry handling
  }
}
```

---

### Step 3: Export Handler in `src/lib/queue/handlers/index.ts`

```typescript
export { processYourNewJob } from './your-new-job';
```

---

### Step 4: Add Routing in Processor

Find the job processor file and add routing:

```typescript
import { processYourNewJob } from './handlers';

// In the processor switch/if chain:
case 'your-new-job':
  return await processYourNewJob(job);
```

---

### Step 5: Create API Endpoint to Trigger Job

```typescript
// src/app/api/your-feature/route.ts
import { addJob } from '@/lib/queue';
import { createJob } from '@/lib/jobs/store';

export async function POST(request: Request) {
  const { userId } = await auth();
  if (!userId) return unauthorized();

  const body = await request.json();
  const validated = Schema.safeParse(body);
  if (!validated.success) return badRequest();

  // Create legacy job for progress tracking
  const legacyJobId = await createJob(userId, 'your-new-job', validated.data);

  // Add to BullMQ queue
  await addJob({
    type: 'your-new-job',
    userId,
    legacyJobId,
    payload: validated.data,
  });

  return NextResponse.json({ jobId: legacyJobId });
}
```

---

## Job Options

```typescript
await addJob(jobData, {
  priority: 1,           // Lower = higher priority (default: undefined)
  delay: 60000,          // Delay in ms before processing
  jobId: `unique-${id}`, // Prevent duplicate jobs
});
```

## Progress Tracking Pattern

```typescript
// In handler
await updateJobProgress(legacyJobId, {
  status: 'processing' | 'completed' | 'failed',
  progress: 0-100,
  step: 'Human readable step',
  result: { /* final result */ },
  error: 'Error message if failed',
});

// In frontend - poll /api/jobs/[id]
const { data } = useQuery({
  queryKey: ['job', jobId],
  queryFn: () => fetch(`/api/jobs/${jobId}`).then(r => r.json()),
  refetchInterval: (data) => data?.status === 'completed' ? false : 2000,
});
```

## Checklist

```
□ Job type added to JobType union
□ Job data interface defined
□ Handler file created with proper error handling
□ Handler exported in index.ts
□ Routing added to processor
□ API endpoint created (if needed)
□ Progress tracking implemented
□ TypeScript compiles: npx tsc --noEmit
```

## Common Patterns

### Idempotency
```typescript
await addJob(data, {
  jobId: `${type}-${targetId}`,  // Prevents duplicate jobs
});
```

### Retry with Backoff
Jobs automatically retry 3x with exponential backoff (2s, 4s, 8s).
To customize:
```typescript
await addJob(data, {
  attempts: 5,
  backoff: { type: 'exponential', delay: 5000 },
});
```

### Priority Jobs
```typescript
// High priority (processed first)
await addJob(data, { priority: 1 });

// Low priority (processed last)
await addJob(data, { priority: 10 });
```
