---
name: realtime
description: Use when building live updates, real-time features, or push notifications. WebSockets, SSE, Supabase Realtime. Triggers on: realtime, real-time, websocket, live, push, subscribe, broadcast, sse, live updates.
version: 1.0.0
---

# Realtime & WebSockets (2026)

> **Priority:** HIGH | **Auto-Load:** On realtime, websocket, live update work
> **Triggers:** realtime, websocket, live, pusher, ably, socket.io, sse, server-sent events

---

## Overview

Realtime enables live updates without polling:
- Chat and messaging
- Live notifications
- Collaborative editing
- Live dashboards
- Real-time presence
- Gaming/multiplayer
- Live feeds/activity streams

---

## Solution Comparison

| Solution | Best For | Hosting | Serverless | Complexity |
|----------|----------|---------|------------|------------|
| **Pusher** | Simple pub/sub | Managed | ✅ | Low |
| **Ably** | Global scale, protocols | Managed | ✅ | Low |
| **Liveblocks** | Collaborative apps | Managed | ✅ | Low |
| **Supabase Realtime** | Database subscriptions | Managed | ✅ | Low |
| **Socket.io** | Full control, rooms | Self-hosted | ❌ | Medium |
| **PartyKit** | Serverless WebSockets | Edge | ✅ | Medium |
| **SSE** | One-way updates | Any | ✅ | Low |

### Decision Tree

```
Need realtime?
├── Serverless (Vercel/Netlify)?
│   ├── Simple notifications/chat → Pusher or Ably
│   ├── Collaborative features → Liveblocks
│   ├── DB subscriptions → Supabase Realtime
│   └── Custom stateful logic → PartyKit
├── One-way updates only → Server-Sent Events
└── Self-hosted with full control → Socket.io
```

---

## Pusher (Managed - Recommended)

Best for: Simple pub/sub, notifications, chat, presence.

### Setup

```bash
npm install pusher pusher-js
```

```typescript
// lib/pusher/server.ts
import Pusher from 'pusher'

export const pusher = new Pusher({
  appId: process.env.PUSHER_APP_ID!,
  key: process.env.NEXT_PUBLIC_PUSHER_KEY!,
  secret: process.env.PUSHER_SECRET!,
  cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER!,
  useTLS: true,
})

// lib/pusher/client.ts
import PusherClient from 'pusher-js'

export const pusherClient = new PusherClient(
  process.env.NEXT_PUBLIC_PUSHER_KEY!,
  {
    cluster: process.env.NEXT_PUBLIC_PUSHER_CLUSTER!,
  }
)
```

### Server-Side: Trigger Events

```typescript
// In server actions or API routes
import { pusher } from '@/lib/pusher/server'

// Send to channel
await pusher.trigger('notifications', 'new-message', {
  message: 'Hello!',
  from: userId,
  timestamp: Date.now(),
})

// Send to user-specific channel
await pusher.trigger(`user-${userId}`, 'notification', {
  title: 'New follower',
  body: 'John started following you',
})

// Send to multiple channels
await pusher.trigger(
  ['chat-123', 'chat-456'],
  'message',
  { text: 'Hello to all!' }
)

// Batch events
await pusher.triggerBatch([
  { channel: 'user-1', name: 'update', data: { count: 5 } },
  { channel: 'user-2', name: 'update', data: { count: 3 } },
])
```

### Client-Side: Subscribe

```typescript
'use client'

import { useEffect, useState } from 'react'
import { pusherClient } from '@/lib/pusher/client'

export function useNotifications(userId: string) {
  const [notifications, setNotifications] = useState<Notification[]>([])

  useEffect(() => {
    const channel = pusherClient.subscribe(`user-${userId}`)

    channel.bind('notification', (data: Notification) => {
      setNotifications(prev => [data, ...prev])
    })

    return () => {
      channel.unbind_all()
      pusherClient.unsubscribe(`user-${userId}`)
    }
  }, [userId])

  return notifications
}
```

### Private Channels (Auth Required)

```typescript
// Server: Auth endpoint
// app/api/pusher/auth/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@clerk/nextjs/server'
import { pusher } from '@/lib/pusher/server'

export async function POST(request: NextRequest) {
  const { userId } = await auth()
  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const body = await request.formData()
  const socketId = body.get('socket_id') as string
  const channel = body.get('channel_name') as string

  // Verify user can access this channel
  if (channel.startsWith('private-user-') && !channel.includes(userId)) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const authResponse = pusher.authorizeChannel(socketId, channel)
  return NextResponse.json(authResponse)
}

// Client: Configure auth endpoint
const pusherClient = new PusherClient(key, {
  cluster: 'eu',
  authEndpoint: '/api/pusher/auth',
})

// Subscribe to private channel
const channel = pusherClient.subscribe('private-user-123')
```

### Presence Channels (Who's Online)

```typescript
// Server: Presence auth
export async function POST(request: NextRequest) {
  const { userId } = await auth()
  const user = await getUser(userId)

  const body = await request.formData()
  const socketId = body.get('socket_id') as string
  const channel = body.get('channel_name') as string

  const authResponse = pusher.authorizeChannel(socketId, channel, {
    user_id: userId,
    user_info: {
      name: user.name,
      avatar: user.avatar,
    },
  })

  return NextResponse.json(authResponse)
}

// Client: Presence events
const channel = pusherClient.subscribe('presence-room-123')

channel.bind('pusher:subscription_succeeded', (members) => {
  members.each((member) => {
    console.log('Online:', member.info.name)
  })
})

channel.bind('pusher:member_added', (member) => {
  console.log('Joined:', member.info.name)
})

channel.bind('pusher:member_removed', (member) => {
  console.log('Left:', member.info.name)
})
```

---

## Ably (Global Scale)

Best for: Global apps, multiple protocols, enterprise scale.

### Setup

```bash
npm install ably
```

```typescript
// lib/ably.ts
import * as Ably from 'ably'

// Server-side
export const ablyServer = new Ably.Rest(process.env.ABLY_API_KEY!)

// Client-side hook
import { useChannel, usePresence } from 'ably/react'

export function useAblyChannel(channelName: string) {
  const { channel, ably } = useChannel(channelName, (message) => {
    console.log('Received:', message.data)
  })

  const publish = (event: string, data: any) => {
    channel.publish(event, data)
  }

  return { channel, publish }
}
```

### Ably React Provider

```typescript
// app/providers.tsx
'use client'

import * as Ably from 'ably'
import { AblyProvider, ChannelProvider } from 'ably/react'

const client = new Ably.Realtime({
  authUrl: '/api/ably/token',
})

export function RealtimeProvider({ children }: { children: React.ReactNode }) {
  return (
    <AblyProvider client={client}>
      <ChannelProvider channelName="main">
        {children}
      </ChannelProvider>
    </AblyProvider>
  )
}
```

### Token Auth

```typescript
// app/api/ably/token/route.ts
import { NextRequest, NextResponse } from 'next/server'
import * as Ably from 'ably'
import { auth } from '@clerk/nextjs/server'

const ably = new Ably.Rest(process.env.ABLY_API_KEY!)

export async function GET(request: NextRequest) {
  const { userId } = await auth()
  if (!userId) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const tokenRequest = await ably.auth.createTokenRequest({
    clientId: userId,
    capability: {
      '*': ['subscribe', 'publish', 'presence'],
    },
  })

  return NextResponse.json(tokenRequest)
}
```

---

## Supabase Realtime

Best for: Database change subscriptions, already using Supabase.

### Subscribe to Database Changes

```typescript
'use client'

import { useEffect } from 'react'
import { createClient } from '@/lib/supabase/client'

export function useRealtimeMessages(roomId: string) {
  const supabase = createClient()
  const [messages, setMessages] = useState<Message[]>([])

  useEffect(() => {
    // Initial fetch
    supabase
      .from('messages')
      .select('*')
      .eq('room_id', roomId)
      .order('created_at')
      .then(({ data }) => setMessages(data || []))

    // Subscribe to changes
    const channel = supabase
      .channel(`room:${roomId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `room_id=eq.${roomId}`,
        },
        (payload) => {
          setMessages(prev => [...prev, payload.new as Message])
        }
      )
      .on(
        'postgres_changes',
        {
          event: 'DELETE',
          schema: 'public',
          table: 'messages',
          filter: `room_id=eq.${roomId}`,
        },
        (payload) => {
          setMessages(prev => prev.filter(m => m.id !== payload.old.id))
        }
      )
      .subscribe()

    return () => {
      supabase.removeChannel(channel)
    }
  }, [roomId])

  return messages
}
```

### Broadcast Messages (No DB)

```typescript
// Send without DB
const channel = supabase.channel('room:123')

await channel.send({
  type: 'broadcast',
  event: 'cursor-move',
  payload: { x: 100, y: 200, userId: 'user-1' },
})

// Listen
channel
  .on('broadcast', { event: 'cursor-move' }, (payload) => {
    console.log('Cursor:', payload)
  })
  .subscribe()
```

### Presence

```typescript
const channel = supabase.channel('room:123')

// Track presence
channel
  .on('presence', { event: 'sync' }, () => {
    const state = channel.presenceState()
    console.log('Online users:', Object.keys(state))
  })
  .on('presence', { event: 'join' }, ({ key, newPresences }) => {
    console.log('Joined:', newPresences)
  })
  .on('presence', { event: 'leave' }, ({ key, leftPresences }) => {
    console.log('Left:', leftPresences)
  })
  .subscribe(async (status) => {
    if (status === 'SUBSCRIBED') {
      await channel.track({
        user_id: userId,
        online_at: new Date().toISOString(),
      })
    }
  })
```

---

## Liveblocks (Collaborative Features)

Best for: Collaborative editing, cursors, presence, comments.

### Setup

```bash
npm install @liveblocks/client @liveblocks/react
```

```typescript
// liveblocks.config.ts
import { createClient } from '@liveblocks/client'
import { createRoomContext } from '@liveblocks/react'

const client = createClient({
  authEndpoint: '/api/liveblocks/auth',
})

type Presence = {
  cursor: { x: number; y: number } | null
  name: string
}

type Storage = {
  items: LiveList<{ id: string; text: string }>
}

export const {
  RoomProvider,
  useOthers,
  useUpdateMyPresence,
  useMutation,
  useStorage,
} = createRoomContext<Presence, Storage>(client)
```

### Live Cursors

```typescript
'use client'

import { useOthers, useUpdateMyPresence } from '@/liveblocks.config'

export function Cursors() {
  const others = useOthers()
  const updatePresence = useUpdateMyPresence()

  return (
    <div
      onPointerMove={(e) => {
        updatePresence({ cursor: { x: e.clientX, y: e.clientY } })
      }}
      onPointerLeave={() => {
        updatePresence({ cursor: null })
      }}
    >
      {others.map(({ connectionId, presence }) =>
        presence.cursor ? (
          <Cursor
            key={connectionId}
            x={presence.cursor.x}
            y={presence.cursor.y}
            name={presence.name}
          />
        ) : null
      )}
    </div>
  )
}
```

---

## Server-Sent Events (SSE)

Best for: One-way updates, simple streaming, no client library needed.

### Server: Stream Endpoint

```typescript
// app/api/stream/route.ts
import { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    async start(controller) {
      const sendEvent = (data: any) => {
        const message = `data: ${JSON.stringify(data)}\n\n`
        controller.enqueue(encoder.encode(message))
      }

      // Send initial data
      sendEvent({ type: 'connected', timestamp: Date.now() })

      // Example: Send updates every second
      const interval = setInterval(() => {
        sendEvent({
          type: 'update',
          value: Math.random(),
          timestamp: Date.now(),
        })
      }, 1000)

      // Cleanup on close
      request.signal.addEventListener('abort', () => {
        clearInterval(interval)
        controller.close()
      })
    },
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  })
}
```

### Client: EventSource

```typescript
'use client'

import { useEffect, useState } from 'react'

export function useSSE<T>(url: string) {
  const [data, setData] = useState<T | null>(null)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    const eventSource = new EventSource(url)

    eventSource.onmessage = (event) => {
      try {
        const parsed = JSON.parse(event.data)
        setData(parsed)
      } catch (e) {
        setError(e as Error)
      }
    }

    eventSource.onerror = () => {
      setError(new Error('SSE connection failed'))
      eventSource.close()
    }

    return () => {
      eventSource.close()
    }
  }, [url])

  return { data, error }
}

// Usage
function LivePrice() {
  const { data } = useSSE<{ price: number }>('/api/stream/price')
  return <div>Price: ${data?.price}</div>
}
```

---

## Socket.io (Self-Hosted)

Best for: Full control, rooms, namespaces, binary data.

### Server Setup

```typescript
// server.ts (custom server, not Vercel)
import { Server } from 'socket.io'
import { createServer } from 'http'

const httpServer = createServer()
const io = new Server(httpServer, {
  cors: {
    origin: process.env.CLIENT_URL,
    methods: ['GET', 'POST'],
  },
})

// Authentication middleware
io.use(async (socket, next) => {
  const token = socket.handshake.auth.token
  try {
    const user = await verifyToken(token)
    socket.data.user = user
    next()
  } catch (err) {
    next(new Error('Authentication failed'))
  }
})

io.on('connection', (socket) => {
  const userId = socket.data.user.id
  console.log('Connected:', userId)

  // Join user's room
  socket.join(`user:${userId}`)

  // Handle chat messages
  socket.on('chat:message', async (data) => {
    const { roomId, text } = data

    // Save to database
    const message = await db.message.create({
      data: { roomId, userId, text },
    })

    // Broadcast to room
    io.to(`room:${roomId}`).emit('chat:message', message)
  })

  // Handle room join
  socket.on('room:join', (roomId) => {
    socket.join(`room:${roomId}`)
    io.to(`room:${roomId}`).emit('room:user-joined', {
      userId,
      name: socket.data.user.name,
    })
  })

  socket.on('disconnect', () => {
    console.log('Disconnected:', userId)
  })
})

httpServer.listen(3001)
```

### Client

```typescript
'use client'

import { io, Socket } from 'socket.io-client'
import { createContext, useContext, useEffect, useState } from 'react'

const SocketContext = createContext<Socket | null>(null)

export function SocketProvider({ children }: { children: React.ReactNode }) {
  const [socket, setSocket] = useState<Socket | null>(null)

  useEffect(() => {
    const token = getAuthToken()

    const socketInstance = io(process.env.NEXT_PUBLIC_SOCKET_URL!, {
      auth: { token },
      transports: ['websocket'],
    })

    socketInstance.on('connect', () => {
      console.log('Socket connected')
    })

    setSocket(socketInstance)

    return () => {
      socketInstance.disconnect()
    }
  }, [])

  return (
    <SocketContext.Provider value={socket}>
      {children}
    </SocketContext.Provider>
  )
}

export const useSocket = () => useContext(SocketContext)
```

---

## PartyKit (Serverless WebSockets)

Best for: Serverless WebSockets with state, edge deployment.

### Setup

```bash
npm install partykit partysocket
```

```typescript
// party/main.ts
import type * as Party from 'partykit/server'

export default class ChatRoom implements Party.Server {
  messages: { id: string; text: string; user: string }[] = []

  constructor(readonly room: Party.Room) {}

  onConnect(conn: Party.Connection) {
    // Send existing messages to new connection
    conn.send(JSON.stringify({ type: 'history', messages: this.messages }))
  }

  onMessage(message: string, sender: Party.Connection) {
    const data = JSON.parse(message)

    if (data.type === 'message') {
      const msg = {
        id: crypto.randomUUID(),
        text: data.text,
        user: data.user,
      }

      this.messages.push(msg)

      // Broadcast to all connections
      this.room.broadcast(JSON.stringify({ type: 'message', ...msg }))
    }
  }
}
```

### Client

```typescript
'use client'

import PartySocket from 'partysocket'
import { useEffect, useState } from 'react'

export function usePartyChat(roomId: string) {
  const [messages, setMessages] = useState<Message[]>([])
  const [socket, setSocket] = useState<PartySocket | null>(null)

  useEffect(() => {
    const ws = new PartySocket({
      host: process.env.NEXT_PUBLIC_PARTYKIT_HOST!,
      room: roomId,
    })

    ws.addEventListener('message', (event) => {
      const data = JSON.parse(event.data)

      if (data.type === 'history') {
        setMessages(data.messages)
      } else if (data.type === 'message') {
        setMessages(prev => [...prev, data])
      }
    })

    setSocket(ws)

    return () => ws.close()
  }, [roomId])

  const sendMessage = (text: string, user: string) => {
    socket?.send(JSON.stringify({ type: 'message', text, user }))
  }

  return { messages, sendMessage }
}
```

---

## Best Practices

### Do
```
✅ Use managed services for serverless deployments
✅ Implement reconnection logic
✅ Validate all incoming messages
✅ Rate limit connections and messages
✅ Use presence for user status
✅ Handle connection errors gracefully
✅ Clean up subscriptions on unmount
```

### Don't
```
❌ Send sensitive data without auth
❌ Trust client-sent data without validation
❌ Forget to unsubscribe/disconnect
❌ Use Socket.io on Vercel (won't work)
❌ Poll when realtime is available
❌ Keep connections open unnecessarily
```

---

## Checklist

```markdown
Setup:
[ ] Realtime provider chosen
[ ] Auth/token endpoint configured
[ ] Client-side library installed
[ ] Provider/context set up

Security:
[ ] Channel auth implemented
[ ] Message validation
[ ] Rate limiting configured
[ ] Private channels for sensitive data

Reliability:
[ ] Reconnection handling
[ ] Error boundaries
[ ] Offline state handling
[ ] Cleanup on unmount

Performance:
[ ] Minimal message payload
[ ] Debounce frequent updates
[ ] Batch when possible
```

---

## Related Skills

- `redis` - Pub/sub with Redis
- `server-actions` - Triggering realtime from actions
- `supabase` - Supabase Realtime integration
