---
name: frontend
description: "UI, React, Next.js, components, forms, styling. Auto-use for any UI work."
version: 3.0.0
allowed-tools:
  - Read
  - Edit
  - Write
  - Bash
  - Grep
  - Glob
---

# Frontend

**Auto-use when:** component, page, UI, form, button, modal, styling, React, Next.js, Tailwind

**Works with:** `backend` for API calls, `quality` for testing

---

## Auto-Apply Rules

### 1. Server vs Client Components
```
No interactivity needed → Server Component (default)
Has onClick, useState, useEffect → Client Component ('use client')
Both → Server wrapper + Client child
```

### 2. State Management
```
API/server data → React Query (useQuery, useMutation)
UI state (modals, forms) → Zustand or useState
```

### 3. All States Required
```typescript
// EVERY data-fetching component must have:
if (isLoading) return <Skeleton />
if (error) return <ErrorState onRetry={refetch} />
if (!data?.length) return <EmptyState action={<CreateButton />} />
return <SuccessState data={data} />
```

### 4. Forms
```typescript
// EVERY form must have:
- Zod schema + zodResolver
- Error messages per field
- Submit button with loading state
- Success/error feedback (toast)
```

---

## Quick Patterns

### Server Component (Data Fetching)
```typescript
// app/users/page.tsx
export default async function UsersPage() {
  const users = await db.user.findMany()
  return <UserList users={users} />
}
```

### Client Component (Interactivity)
```typescript
'use client'
import { useState } from 'react'

export function Counter() {
  const [count, setCount] = useState(0)
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>
}
```

### Data Fetching with States
```typescript
'use client'
import { useQuery } from '@tanstack/react-query'

export function UserList() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['users'],
    queryFn: () => fetch('/api/users').then(r => r.json())
  })

  if (isLoading) return <Skeleton count={5} />
  if (error) return <ErrorState onRetry={refetch} />
  if (!data?.length) return <EmptyState />

  return data.map(u => <UserCard key={u.id} user={u} />)
}
```

### Form with Validation
```typescript
'use client'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useMutation } from '@tanstack/react-query'
import { toast } from 'sonner'

const schema = z.object({
  name: z.string().min(1, 'Required'),
  email: z.string().email('Invalid email'),
})

export function CreateForm({ onSuccess }: { onSuccess?: () => void }) {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm({
    resolver: zodResolver(schema)
  })

  const mutation = useMutation({
    mutationFn: (data) => fetch('/api/users', {
      method: 'POST',
      body: JSON.stringify(data)
    }).then(r => r.json()),
    onSuccess: () => {
      toast.success('Created!')
      onSuccess?.()
    },
    onError: () => toast.error('Failed')
  })

  return (
    <form onSubmit={handleSubmit(d => mutation.mutate(d))}>
      <Input {...register('name')} error={errors.name?.message} />
      <Input {...register('email')} error={errors.email?.message} />
      <Button type="submit" loading={isSubmitting}>
        {isSubmitting ? 'Creating...' : 'Create'}
      </Button>
    </form>
  )
}
```

### Next.js 15+ Async Params
```typescript
export default async function Page({
  params,
  searchParams
}: {
  params: Promise<{ id: string }>
  searchParams: Promise<{ q?: string }>
}) {
  const { id } = await params
  const { q } = await searchParams
}
```

---

## UI Library Selection

| Request | Use |
|---------|-----|
| Default | shadcn/ui |
| "impressive/wow/3D" | Aceternity UI + Magic UI |
| "dashboard/enterprise" | Preline + shadcn |
| "AI/chat" | Prompt Kit |

---

## Checklist Before Done

```
□ Uses REAL data (not mock)
□ Loading state (Skeleton)
□ Error state (message + retry)
□ Empty state (message + action)
□ Form validation + error messages
□ Submit loading state
□ Success feedback
□ tsc --noEmit = 0 errors
□ Responsive (mobile-first)
□ Accessible (keyboard nav, ARIA)
```

---

## Red Flags (STOP)

| If You See | Fix |
|------------|-----|
| `const users = [{id:1}]` | Fetch from API |
| `onClick={() => {}}` | Implement handler |
| No loading state | Add Skeleton |
| No error state | Add ErrorState |
| `any` type | Add proper types |
