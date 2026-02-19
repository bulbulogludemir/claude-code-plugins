# /db-migrate - Drizzle Migration Workflow

<command-name>db-migrate</command-name>

## Overview

Safe database migration workflow for Drizzle ORM. Ensures schema changes are reviewed, tested, and applied correctly.

## Trigger Keywords

schema change, add column, new table, migration, alter table, database change, drizzle migrate

## Project Structure

```
src/lib/db/
├── index.ts      # Database client
└── schema.ts     # SINGLE SOURCE OF TRUTH for all tables

drizzle/
└── *.sql         # Generated migration files
```

## Migration Workflow

### Step 1: Edit Schema

**File:** `src/lib/db/schema.ts`

```typescript
import { pgTable, text, timestamp, uuid, boolean, integer } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

// Example: Add new column to existing table
export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: text('email').notNull().unique(),
  name: text('name'),
  // NEW: Add column
  avatarUrl: text('avatar_url'),
  isVerified: boolean('is_verified').default(false),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

// Example: Add new table
export const posts = pgTable('posts', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  title: text('title').notNull(),
  content: text('content'),
  publishedAt: timestamp('published_at'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
});

// Define relations
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}));

export const postsRelations = relations(posts, ({ one }) => ({
  user: one(users, {
    fields: [posts.userId],
    references: [users.id],
  }),
}));
```

---

### Step 2: Generate Migration

```bash
npm run db:generate
```

This creates a new SQL file in `drizzle/` folder.

---

### Step 3: Review Generated SQL

**CRITICAL: Always review the SQL before applying!**

Open the generated file in `drizzle/` and verify:

```sql
-- Example safe migration
ALTER TABLE "users" ADD COLUMN "avatar_url" text;
ALTER TABLE "users" ADD COLUMN "is_verified" boolean DEFAULT false;

-- Example new table
CREATE TABLE IF NOT EXISTS "posts" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "user_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "title" text NOT NULL,
  "content" text,
  "published_at" timestamp,
  "created_at" timestamp DEFAULT now() NOT NULL
);
```

**Review Checklist:**
```
□ No DROP TABLE unless intended
□ No DROP COLUMN unless intended
□ DEFAULT values for new NOT NULL columns
□ Foreign keys have proper ON DELETE behavior
□ Indexes created for frequently queried columns
```

---

### Step 4: Apply Migration

```bash
npm run db:push
```

This applies the schema changes to the database.

---

### Step 5: Verify in Drizzle Studio

```bash
npm run db:studio
```

Open http://localhost:4983 and verify:
- New columns/tables exist
- Data integrity maintained
- Relationships work correctly

---

## Destructive Changes (⚠️ Danger Zone)

### Dropping Columns

**Never drop columns without a plan:**

1. **Phase 1:** Stop writing to the column
2. **Phase 2:** Deploy code that doesn't read the column
3. **Phase 3:** Drop the column

```typescript
// Phase 1: Mark as deprecated in schema (comment only)
export const users = pgTable('users', {
  // ... other columns
  // DEPRECATED: Will be removed in v2.0
  oldField: text('old_field'),
});
```

### Renaming Columns

Drizzle generates DROP + ADD, which loses data. Instead:

1. Add new column
2. Migrate data: `UPDATE table SET new_col = old_col`
3. Update application code
4. Drop old column (after verification)

```sql
-- Manual migration for column rename
ALTER TABLE "users" ADD COLUMN "new_name" text;
UPDATE "users" SET "new_name" = "old_name";
-- Later, after code is updated:
ALTER TABLE "users" DROP COLUMN "old_name";
```

### Changing Column Types

```sql
-- Safe type change (widening)
ALTER TABLE "users" ALTER COLUMN "status" TYPE text;

-- Unsafe type change (requires data migration)
-- First add new column, migrate, then drop old
```

---

## Rollback Procedures

### Quick Rollback (Schema Only)

If migration fails and no data was written:

```bash
# Revert schema.ts to previous version
git checkout HEAD~1 -- src/lib/db/schema.ts

# Re-generate and push
npm run db:generate
npm run db:push
```

### Data Rollback

For production with data:

1. **Restore from backup** (Supabase/Coolify automated backups)
2. Or manually reverse the SQL

```sql
-- Example: Remove added column
ALTER TABLE "users" DROP COLUMN "avatar_url";
```

---

## Migration Safety Checklist

```
□ Schema changes in src/lib/db/schema.ts
□ Generated SQL reviewed
□ No unintended DROP statements
□ New NOT NULL columns have DEFAULT
□ Foreign keys use proper ON DELETE
□ Tested on staging first (if destructive)
□ TypeScript compiles: npx tsc --noEmit
□ Applied: npm run db:push
□ Verified in Drizzle Studio
```

---

## Common Patterns

### Adding Index

```typescript
export const posts = pgTable('posts', {
  // columns...
}, (table) => ({
  userIdIdx: index('posts_user_id_idx').on(table.userId),
  createdAtIdx: index('posts_created_at_idx').on(table.createdAt),
}));
```

### Composite Unique Constraint

```typescript
export const subscriptions = pgTable('subscriptions', {
  userId: uuid('user_id').notNull(),
  planId: uuid('plan_id').notNull(),
}, (table) => ({
  userPlanUnique: unique('user_plan_unique').on(table.userId, table.planId),
}));
```

### Enum Type

```typescript
import { pgEnum } from 'drizzle-orm/pg-core';

export const statusEnum = pgEnum('status', ['draft', 'published', 'archived']);

export const posts = pgTable('posts', {
  status: statusEnum('status').default('draft').notNull(),
});
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "relation already exists" | Migration already applied, check drizzle meta |
| "column cannot be null" | Add DEFAULT or migrate existing data first |
| "violates foreign key constraint" | Delete dependent data or add ON DELETE CASCADE |
| Type mismatch | Check column types match between schema and DB |
