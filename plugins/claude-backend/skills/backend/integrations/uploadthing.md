---
name: uploadthing
description: Use when handling file uploads. Upload config, presigned URLs, file validation. Triggers on: upload, uploadthing, file upload, presigned url, file, image upload.
version: 1.0.0
detect: ["uploadthing"]
---

# UploadThing

Type-safe file uploads for Next.js.

## Setup

```typescript
// lib/uploadthing.ts
import { createUploadthing, type FileRouter } from 'uploadthing/next'
import { auth } from '@/lib/auth'

const f = createUploadthing()

export const ourFileRouter = {
  // Image uploader
  imageUploader: f({ image: { maxFileSize: '4MB', maxFileCount: 1 } })
    .middleware(async () => {
      const session = await auth()
      if (!session) throw new Error('Unauthorized')
      return { userId: session.user.id }
    })
    .onUploadComplete(async ({ metadata, file }) => {
      console.log('Upload complete for:', metadata.userId)
      console.log('File URL:', file.url)
      return { url: file.url }
    }),

  // Document uploader
  documentUploader: f({
    pdf: { maxFileSize: '16MB' },
    'application/msword': { maxFileSize: '16MB' },
  })
    .middleware(async () => {
      const session = await auth()
      if (!session) throw new Error('Unauthorized')
      return { userId: session.user.id }
    })
    .onUploadComplete(async ({ metadata, file }) => {
      await db.document.create({
        data: {
          userId: metadata.userId,
          url: file.url,
          name: file.name,
        },
      })
      return { url: file.url }
    }),

  // Avatar uploader
  avatarUploader: f({ image: { maxFileSize: '2MB', maxFileCount: 1 } })
    .middleware(async () => {
      const session = await auth()
      if (!session) throw new Error('Unauthorized')
      return { userId: session.user.id }
    })
    .onUploadComplete(async ({ metadata, file }) => {
      await db.user.update({
        where: { id: metadata.userId },
        data: { image: file.url },
      })
      return { url: file.url }
    }),
} satisfies FileRouter

export type OurFileRouter = typeof ourFileRouter
```

## Route Handler

```typescript
// app/api/uploadthing/route.ts
import { createRouteHandler } from 'uploadthing/next'
import { ourFileRouter } from '@/lib/uploadthing'

export const { GET, POST } = createRouteHandler({
  router: ourFileRouter,
})
```

## Components

```tsx
// components/upload-button.tsx
'use client'

import { UploadButton, UploadDropzone } from '@uploadthing/react'
import type { OurFileRouter } from '@/lib/uploadthing'

// Simple button
export function ImageUploadButton({
  onUploadComplete,
}: {
  onUploadComplete: (url: string) => void
}) {
  return (
    <UploadButton<OurFileRouter, 'imageUploader'>
      endpoint="imageUploader"
      onClientUploadComplete={(res) => {
        if (res?.[0]?.url) {
          onUploadComplete(res[0].url)
        }
      }}
      onUploadError={(error: Error) => {
        console.error('Upload error:', error)
      }}
    />
  )
}

// Dropzone
export function ImageDropzone({
  onUploadComplete,
}: {
  onUploadComplete: (url: string) => void
}) {
  return (
    <UploadDropzone<OurFileRouter, 'imageUploader'>
      endpoint="imageUploader"
      onClientUploadComplete={(res) => {
        if (res?.[0]?.url) {
          onUploadComplete(res[0].url)
        }
      }}
      onUploadError={(error: Error) => {
        console.error('Upload error:', error)
      }}
      className="ut-button:bg-primary ut-button:ut-readying:bg-primary/50"
    />
  )
}
```

## Custom Upload Component

```tsx
'use client'

import { useUploadThing } from '@uploadthing/react'
import { useState, useCallback } from 'react'

export function CustomUploader({
  onUploadComplete,
}: {
  onUploadComplete: (url: string) => void
}) {
  const [isUploading, setIsUploading] = useState(false)

  const { startUpload } = useUploadThing('imageUploader', {
    onClientUploadComplete: (res) => {
      setIsUploading(false)
      if (res?.[0]?.url) {
        onUploadComplete(res[0].url)
      }
    },
    onUploadError: (error) => {
      setIsUploading(false)
      console.error('Upload error:', error)
    },
  })

  const handleFileChange = useCallback(
    async (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = e.target.files
      if (!files?.length) return

      setIsUploading(true)
      await startUpload(Array.from(files))
    },
    [startUpload]
  )

  return (
    <div>
      <input
        type="file"
        accept="image/*"
        onChange={handleFileChange}
        disabled={isUploading}
      />
      {isUploading && <span>Uploading...</span>}
    </div>
  )
}
```

## Avatar Upload Example

```tsx
'use client'

import { useState } from 'react'
import Image from 'next/image'
import { ImageUploadButton } from '@/components/upload-button'

export function AvatarUpload({ currentImage }: { currentImage?: string }) {
  const [image, setImage] = useState(currentImage)

  return (
    <div className="flex items-center gap-4">
      {image ? (
        <Image
          src={image}
          alt="Avatar"
          width={80}
          height={80}
          className="rounded-full"
        />
      ) : (
        <div className="w-20 h-20 rounded-full bg-muted" />
      )}
      <ImageUploadButton onUploadComplete={setImage} />
    </div>
  )
}
```

## Styles

```css
/* globals.css */
.ut-button {
  @apply bg-primary text-primary-foreground hover:bg-primary/90;
}

.ut-allowed-content {
  @apply text-muted-foreground text-sm;
}

.ut-label {
  @apply text-foreground;
}
```
