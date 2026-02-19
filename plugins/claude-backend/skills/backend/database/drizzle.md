---
name: drizzle
description: Use when working with Drizzle ORM. Schema, migrations, queries, relations. Triggers on: drizzle, drizzle orm, drizzle schema, drizzle query, drizzle migration, db schema, schema design, database design, database structure.
version: 1.0.0
---

# Drizzle ORM Deep Knowledge

> Type-safe SQL, schema migrations, relations, and performance.

---

## Quick Reference

```typescript
import { drizzle } from 'drizzle-orm/postgres-js';
import * as schema from './schema';

const db = drizzle(sql, { schema });
const users = await db.select().from(schema.users);
```

---

## Schema Design

### Tables with All Column Types

```typescript
import { 
  pgTable, serial, text, varchar, integer, boolean,
  timestamp, json, jsonb, uuid, decimal, real,
  primaryKey, index, uniqueIndex
} from 'drizzle-orm/pg-core';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  uuid: uuid('uuid').defaultRandom().notNull(),
  email: varchar('email', { length: 255 }).notNull().unique(),
  name: text('name'),
  age: integer('age'),
  balance: decimal('balance', { precision: 10, scale: 2 }),
  isActive: boolean('is_active').default(true),
  metadata: jsonb('metadata').$type<{ preferences: Record<string, unknown> }>(),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
}, (table) => ({
  emailIdx: uniqueIndex('email_idx').on(table.email),
  createdAtIdx: index('created_at_idx').on(table.createdAt),
}));
```

### Relations

```typescript
import { relations } from 'drizzle-orm';

export const users = pgTable('users', {
  id: serial('id').primaryKey(),
  email: text('email').notNull(),
});

export const posts = pgTable('posts', {
  id: serial('id').primaryKey(),
  title: text('title').notNull(),
  authorId: integer('author_id').references(() => users.id),
});

export const comments = pgTable('comments', {
  id: serial('id').primaryKey(),
  content: text('content').notNull(),
  postId: integer('post_id').references(() => posts.id),
  authorId: integer('author_id').references(() => users.id),
});

// Define relations separately
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
  comments: many(comments),
}));

export const postsRelations = relations(posts, ({ one, many }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
  }),
  comments: many(comments),
}));

export const commentsRelations = relations(comments, ({ one }) => ({
  post: one(posts, {
    fields: [comments.postId],
    references: [posts.id],
  }),
  author: one(users, {
    fields: [comments.authorId],
    references: [users.id],
  }),
}));
```

### Many-to-Many Relations

```typescript
export const usersToGroups = pgTable('users_to_groups', {
  userId: integer('user_id').references(() => users.id).notNull(),
  groupId: integer('group_id').references(() => groups.id).notNull(),
}, (table) => ({
  pk: primaryKey({ columns: [table.userId, table.groupId] }),
}));

export const usersRelations = relations(users, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}));

export const groupsRelations = relations(groups, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}));

export const usersToGroupsRelations = relations(usersToGroups, ({ one }) => ({
  user: one(users, {
    fields: [usersToGroups.userId],
    references: [users.id],
  }),
  group: one(groups, {
    fields: [usersToGroups.groupId],
    references: [groups.id],
  }),
}));
```

---

## Advanced Queries

### Filtering with Operators

```typescript
import { eq, ne, gt, gte, lt, lte, like, ilike, inArray, 
         notInArray, isNull, isNotNull, and, or, not, 
         between, sql } from 'drizzle-orm';

// Complex where clause
const results = await db.select()
  .from(users)
  .where(
    and(
      eq(users.isActive, true),
      or(
        gte(users.age, 18),
        isNotNull(users.parentId)
      ),
      not(inArray(users.role, ['banned', 'suspended'])),
      ilike(users.email, '%@company.com')
    )
  );

// Between
const recentUsers = await db.select()
  .from(users)
  .where(between(users.createdAt, startDate, endDate));
```

### Joins

```typescript
// Inner join
const postsWithAuthors = await db
  .select({
    postTitle: posts.title,
    authorName: users.name,
  })
  .from(posts)
  .innerJoin(users, eq(posts.authorId, users.id));

// Left join
const usersWithPosts = await db
  .select()
  .from(users)
  .leftJoin(posts, eq(users.id, posts.authorId));

// Multiple joins
const fullData = await db
  .select()
  .from(posts)
  .innerJoin(users, eq(posts.authorId, users.id))
  .leftJoin(comments, eq(posts.id, comments.postId));
```

### Relational Queries (with Schema)

```typescript
// Much cleaner than joins
const usersWithPosts = await db.query.users.findMany({
  with: {
    posts: {
      with: {
        comments: true
      },
      where: eq(posts.published, true),
      orderBy: desc(posts.createdAt),
      limit: 5
    }
  },
  where: eq(users.isActive, true)
});
```

### Aggregations

```typescript
import { count, sum, avg, min, max, countDistinct } from 'drizzle-orm';

// Count
const userCount = await db.select({ count: count() }).from(users);

// Group by with aggregates
const orderStats = await db
  .select({
    status: orders.status,
    count: count(),
    total: sum(orders.amount),
    avgAmount: avg(orders.amount),
  })
  .from(orders)
  .groupBy(orders.status)
  .having(gt(count(), 10));
```

### Subqueries

```typescript
// Subquery in WHERE
const subquery = db
  .select({ id: orders.userId })
  .from(orders)
  .where(gt(orders.amount, 1000));

const highValueUsers = await db
  .select()
  .from(users)
  .where(inArray(users.id, subquery));

// Subquery in SELECT
const usersWithOrderCount = await db
  .select({
    user: users,
    orderCount: db
      .select({ count: count() })
      .from(orders)
      .where(eq(orders.userId, users.id))
  })
  .from(users);
```

---

## Transactions

```typescript
// Basic transaction
const result = await db.transaction(async (tx) => {
  const user = await tx.insert(users).values({ email: 'new@example.com' }).returning();
  await tx.insert(profiles).values({ userId: user[0].id, bio: 'Hello' });
  return user[0];
});

// With rollback
await db.transaction(async (tx) => {
  await tx.insert(users).values({ email: 'test@example.com' });
  
  if (someCondition) {
    tx.rollback(); // Explicit rollback
  }
  
  // Or throw error for implicit rollback
  throw new Error('Something went wrong');
});

// Nested transactions (savepoints)
await db.transaction(async (tx) => {
  await tx.insert(users).values({ email: 'outer@example.com' });
  
  await tx.transaction(async (tx2) => {
    await tx2.insert(users).values({ email: 'inner@example.com' });
    // Inner transaction can rollback independently
  });
});
```

---

## Raw SQL

```typescript
// Tagged template literal (safe)
const users = await db.execute(sql`
  SELECT * FROM users WHERE email = ${email}
`);

// Raw SQL in expressions
const users = await db
  .select({
    id: users.id,
    fullName: sql<string>`${users.firstName} || ' ' || ${users.lastName}`,
  })
  .from(users);

// Custom SQL operator
const recentUsers = await db
  .select()
  .from(users)
  .where(sql`${users.createdAt} > NOW() - INTERVAL '7 days'`);
```

---

## Migrations

### Generate and Run

```bash
# Generate migration from schema changes
npx drizzle-kit generate:pg

# Push directly to database (dev only)
npx drizzle-kit push:pg

# Run migrations
npx drizzle-kit migrate
```

### drizzle.config.ts

```typescript
import type { Config } from 'drizzle-kit';

export default {
  schema: './src/db/schema.ts',
  out: './drizzle',
  driver: 'pg',
  dbCredentials: {
    connectionString: process.env.DATABASE_URL!,
  },
  verbose: true,
  strict: true,
} satisfies Config;
```

### Custom Migration

```typescript
// drizzle/0001_custom.ts
import { sql } from 'drizzle-orm';

export async function up(db: PostgresJsDatabase) {
  await db.execute(sql`
    CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
  `);
}

export async function down(db: PostgresJsDatabase) {
  await db.execute(sql`DROP INDEX idx_users_email;`);
}
```

---

## Performance Optimization

### Select Only Needed Columns

```typescript
// Bad: selects all columns
const users = await db.select().from(usersTable);

// Good: select specific columns
const users = await db
  .select({ id: usersTable.id, email: usersTable.email })
  .from(usersTable);
```

### Prepared Statements

```typescript
// Prepare once, execute many
const prepared = db
  .select()
  .from(users)
  .where(eq(users.id, sql.placeholder('id')))
  .prepare('get_user_by_id');

// Execute with different values
const user1 = await prepared.execute({ id: 1 });
const user2 = await prepared.execute({ id: 2 });
```

### Batch Operations

```typescript
// Batch insert
await db.insert(users).values([
  { email: 'user1@example.com' },
  { email: 'user2@example.com' },
  { email: 'user3@example.com' },
]);

// Batch update with CASE
await db.execute(sql`
  UPDATE users SET status = CASE id
    ${sql.join(
      updates.map(u => sql`WHEN ${u.id} THEN ${u.status}`),
      sql` `
    )}
  END
  WHERE id IN (${sql.join(updates.map(u => u.id), sql`, `)})
`);
```

---

## Connection Setup

### With postgres.js

```typescript
import postgres from 'postgres';
import { drizzle } from 'drizzle-orm/postgres-js';
import * as schema from './schema';

const sql = postgres(process.env.DATABASE_URL!, {
  max: 20,
  idle_timeout: 20,
  connect_timeout: 10,
});

export const db = drizzle(sql, { schema, logger: true });
```

### With node-postgres

```typescript
import { Pool } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from './schema';

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
});

export const db = drizzle(pool, { schema });
```

### Singleton for Next.js

```typescript
import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import * as schema from './schema';

const globalForDb = globalThis as unknown as {
  conn: postgres.Sql | undefined;
};

const conn = globalForDb.conn ?? postgres(process.env.DATABASE_URL!);

if (process.env.NODE_ENV !== 'production') {
  globalForDb.conn = conn;
}

export const db = drizzle(conn, { schema });
```

---

## Type Inference

```typescript
import { InferSelectModel, InferInsertModel } from 'drizzle-orm';

// Infer types from schema
type User = InferSelectModel<typeof users>;
type NewUser = InferInsertModel<typeof users>;

// Use in functions
async function createUser(data: NewUser): Promise<User> {
  const [user] = await db.insert(users).values(data).returning();
  return user;
}
```
