---
name: supabase
description: Use when working with Supabase. Database, auth, storage, realtime, RLS policies. Triggers on: supabase, supabase auth, supabase storage, rls, row level security, supabase client, supabase query.
version: 1.0.0
---

# Supabase Deep Knowledge

> RLS policies, Edge Functions, Realtime, and advanced patterns.

---

## Quick Reference

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
);

const { data, error } = await supabase
  .from('users')
  .select('*');
```

---

## Row Level Security (RLS)

### Enable RLS

```sql
-- Enable RLS on table
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Force RLS for table owner too
ALTER TABLE posts FORCE ROW LEVEL SECURITY;
```

### Common Policies

```sql
-- Public read access
CREATE POLICY "Anyone can read posts"
ON posts FOR SELECT
USING (true);

-- Authenticated users only
CREATE POLICY "Authenticated users can read"
ON posts FOR SELECT
TO authenticated
USING (true);

-- Owner-only access
CREATE POLICY "Users can read own posts"
ON posts FOR SELECT
USING (auth.uid() = user_id);

-- Insert own data
CREATE POLICY "Users can insert own posts"
ON posts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Update own data
CREATE POLICY "Users can update own posts"
ON posts FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Delete own data
CREATE POLICY "Users can delete own posts"
ON posts FOR DELETE
USING (auth.uid() = user_id);
```

### Advanced Policies

```sql
-- Role-based access
CREATE POLICY "Admins can do everything"
ON posts FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_roles
    WHERE user_id = auth.uid()
    AND role = 'admin'
  )
);

-- Team-based access
CREATE POLICY "Team members can access team posts"
ON posts FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_members.team_id = posts.team_id
    AND team_members.user_id = auth.uid()
  )
);

-- Time-based access
CREATE POLICY "Published posts are public"
ON posts FOR SELECT
USING (
  published = true
  AND published_at <= NOW()
);

-- Combining conditions
CREATE POLICY "Complex access control"
ON posts FOR SELECT
USING (
  -- Owner can always see
  auth.uid() = user_id
  OR
  -- Published posts visible to all
  (published = true AND published_at <= NOW())
  OR
  -- Team members can see drafts
  EXISTS (
    SELECT 1 FROM team_members
    WHERE team_members.team_id = posts.team_id
    AND team_members.user_id = auth.uid()
  )
);
```

### RLS with JWT Claims

```sql
-- Access based on JWT claims
CREATE POLICY "Premium users only"
ON premium_content FOR SELECT
USING (
  (auth.jwt() -> 'user_metadata' ->> 'subscription')::text = 'premium'
);

-- Organization-based access
CREATE POLICY "Org members access"
ON org_data FOR ALL
USING (
  org_id = (auth.jwt() -> 'app_metadata' ->> 'org_id')::uuid
);
```

---

## Edge Functions

### Create Edge Function

```typescript
// supabase/functions/send-email/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  
  try {
    // Get auth user
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    );
    
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // Process request
    const { to, subject, body } = await req.json();
    
    // Send email (using Resend, SendGrid, etc.)
    const emailResult = await sendEmail({ to, subject, body });
    
    // Log to database
    const { error: logError } = await supabase
      .from('email_logs')
      .insert({ user_id: user.id, to, subject, sent_at: new Date() });
    
    return new Response(
      JSON.stringify({ success: true, messageId: emailResult.id }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

### Deploy Edge Function

```bash
# Deploy
supabase functions deploy send-email

# Deploy with secrets
supabase secrets set RESEND_API_KEY=re_xxx
supabase functions deploy send-email

# Test locally
supabase functions serve send-email --env-file .env.local

# Invoke
curl -X POST 'https://xxx.supabase.co/functions/v1/send-email' \
  -H 'Authorization: Bearer USER_JWT' \
  -H 'Content-Type: application/json' \
  -d '{"to":"test@example.com","subject":"Hello"}'
```

---

## Realtime

### Subscribe to Changes

```typescript
// Subscribe to all changes on a table
const channel = supabase
  .channel('posts-changes')
  .on(
    'postgres_changes',
    {
      event: '*', // 'INSERT' | 'UPDATE' | 'DELETE'
      schema: 'public',
      table: 'posts',
    },
    (payload) => {
      console.log('Change:', payload);
      // payload.eventType, payload.new, payload.old
    }
  )
  .subscribe();

// Subscribe with filter
const channel = supabase
  .channel('user-posts')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'posts',
      filter: `user_id=eq.${userId}`,
    },
    (payload) => {
      console.log('New post:', payload.new);
    }
  )
  .subscribe();

// Unsubscribe
supabase.removeChannel(channel);
```

### Broadcast (Ephemeral Messages)

```typescript
// Create broadcast channel
const channel = supabase.channel('room-1');

// Subscribe to messages
channel
  .on('broadcast', { event: 'cursor' }, (payload) => {
    console.log('Cursor position:', payload);
  })
  .subscribe();

// Send message (not persisted)
channel.send({
  type: 'broadcast',
  event: 'cursor',
  payload: { x: 100, y: 200, userId: 'abc' },
});
```

### Presence (Online Status)

```typescript
const channel = supabase.channel('online-users');

// Track presence
channel
  .on('presence', { event: 'sync' }, () => {
    const state = channel.presenceState();
    console.log('Online users:', Object.keys(state));
  })
  .on('presence', { event: 'join' }, ({ key, newPresences }) => {
    console.log('User joined:', key, newPresences);
  })
  .on('presence', { event: 'leave' }, ({ key, leftPresences }) => {
    console.log('User left:', key, leftPresences);
  })
  .subscribe(async (status) => {
    if (status === 'SUBSCRIBED') {
      await channel.track({
        user_id: userId,
        online_at: new Date().toISOString(),
      });
    }
  });

// Update presence
await channel.track({ user_id: userId, status: 'away' });

// Leave
await channel.untrack();
```

---

## Auth Deep Dive

### Custom Auth Flow

```typescript
// Sign up with metadata
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password',
  options: {
    data: {
      full_name: 'John Doe',
      avatar_url: 'https://...',
    },
    emailRedirectTo: 'https://app.example.com/auth/callback',
  },
});

// Sign in with provider
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: 'https://app.example.com/auth/callback',
    queryParams: {
      access_type: 'offline',
      prompt: 'consent',
    },
  },
});

// Magic link
const { error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com',
  options: {
    emailRedirectTo: 'https://app.example.com/auth/callback',
  },
});

// Phone OTP
const { error } = await supabase.auth.signInWithOtp({
  phone: '+1234567890',
});

// Verify OTP
const { data, error } = await supabase.auth.verifyOtp({
  phone: '+1234567890',
  token: '123456',
  type: 'sms',
});
```

### Session Management

```typescript
// Get current session
const { data: { session } } = await supabase.auth.getSession();

// Get current user
const { data: { user } } = await supabase.auth.getUser();

// Refresh session
const { data, error } = await supabase.auth.refreshSession();

// Listen to auth changes
supabase.auth.onAuthStateChange((event, session) => {
  console.log('Auth event:', event);
  // INITIAL_SESSION, SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED,
  // USER_UPDATED, PASSWORD_RECOVERY
});

// Update user
const { data, error } = await supabase.auth.updateUser({
  email: 'new@example.com',
  password: 'newpassword',
  data: { full_name: 'New Name' },
});
```

---

## Storage

### File Operations

```typescript
// Upload file
const { data, error } = await supabase.storage
  .from('avatars')
  .upload(`${userId}/avatar.png`, file, {
    cacheControl: '3600',
    upsert: true,
    contentType: 'image/png',
  });

// Get public URL
const { data: { publicUrl } } = supabase.storage
  .from('avatars')
  .getPublicUrl(`${userId}/avatar.png`);

// Get signed URL (private buckets)
const { data, error } = await supabase.storage
  .from('private')
  .createSignedUrl('file.pdf', 3600); // 1 hour

// Download file
const { data, error } = await supabase.storage
  .from('bucket')
  .download('file.pdf');

// Delete file
const { error } = await supabase.storage
  .from('bucket')
  .remove(['file1.pdf', 'file2.pdf']);

// List files
const { data, error } = await supabase.storage
  .from('bucket')
  .list('folder', {
    limit: 100,
    offset: 0,
    sortBy: { column: 'created_at', order: 'desc' },
  });
```

### Storage Policies

```sql
-- Allow authenticated users to upload to their folder
CREATE POLICY "Users can upload own files"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Allow public read access
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'public');
```

---

## Database Functions

```sql
-- Create function for complex operations
CREATE OR REPLACE FUNCTION increment_view_count(post_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE posts
  SET view_count = view_count + 1
  WHERE id = post_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Call from client
const { error } = await supabase.rpc('increment_view_count', {
  post_id: 'xxx',
});

-- Function with return value
CREATE OR REPLACE FUNCTION get_user_stats(user_uuid UUID)
RETURNS TABLE (
  post_count BIGINT,
  comment_count BIGINT,
  total_likes BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*) FROM posts WHERE user_id = user_uuid),
    (SELECT COUNT(*) FROM comments WHERE user_id = user_uuid),
    (SELECT COALESCE(SUM(likes), 0) FROM posts WHERE user_id = user_uuid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Call
const { data, error } = await supabase.rpc('get_user_stats', {
  user_uuid: userId,
});
```

---

## TypeScript Types

```bash
# Generate types
npx supabase gen types typescript --project-id YOUR_PROJECT_ID > database.types.ts
```

```typescript
// Use generated types
import { Database } from './database.types';

const supabase = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
);

// Fully typed queries
const { data } = await supabase
  .from('posts')
  .select('id, title, user:users(name)')
  .eq('published', true);
// data is typed based on your schema
```
