---
name: postgresql
description: Use when working with PostgreSQL databases. Indexes, queries, EXPLAIN ANALYZE, partitioning. Triggers on: postgres, postgresql, sql, database, index, query, explain analyze, db, psql.
version: 1.0.0
---

# PostgreSQL Deep Knowledge

> Advanced query optimization, indexing strategies, and performance tuning.

---

## Quick Reference

```sql
-- Basic index
CREATE INDEX idx_users_email ON users(email);

-- Explain query
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'test@example.com';
```

---

## Index Deep Dive

### Index Types

| Type | Use Case | Example |
|------|----------|---------|
| **B-tree** | Equality, range, sorting | `CREATE INDEX idx ON t(col)` |
| **Hash** | Equality only (rare) | `CREATE INDEX idx ON t USING hash(col)` |
| **GIN** | Arrays, JSONB, full-text | `CREATE INDEX idx ON t USING gin(tags)` |
| **GiST** | Geometric, full-text | `CREATE INDEX idx ON t USING gist(location)` |
| **BRIN** | Very large, sorted tables | `CREATE INDEX idx ON t USING brin(created_at)` |

### Composite Index Order

```sql
-- Order matters! Most selective FIRST
CREATE INDEX idx_orders ON orders(status, created_at);

-- Queries that benefit:
WHERE status = 'pending'                    -- ✅ Uses index
WHERE status = 'pending' AND created_at > x -- ✅ Uses index
WHERE created_at > x                        -- ❌ Cannot use (wrong order)
```

### Partial Indexes

```sql
-- Index only active users (smaller, faster)
CREATE INDEX idx_active_users ON users(email) 
WHERE status = 'active';

-- Index only recent orders
CREATE INDEX idx_recent_orders ON orders(user_id) 
WHERE created_at > '2024-01-01';
```

### Expression Indexes

```sql
-- Index on lowercase email
CREATE INDEX idx_email_lower ON users(LOWER(email));

-- Query must match expression exactly
SELECT * FROM users WHERE LOWER(email) = 'test@example.com'; -- ✅
SELECT * FROM users WHERE email = 'test@example.com';        -- ❌
```

---

## EXPLAIN Mastery

### Reading EXPLAIN Output

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) 
SELECT * FROM orders WHERE user_id = 1;

-- Output breakdown:
-- Seq Scan       = Full table scan (usually bad)
-- Index Scan     = Using index (good)
-- Index Only Scan = Index covers query (best)
-- Bitmap Scan    = Multiple index conditions
-- Nested Loop    = Row-by-row join
-- Hash Join      = Build hash table, probe
-- Merge Join     = Pre-sorted merge
```

### Key Metrics

```
actual time=0.015..0.017    -- Startup..Total time (ms)
rows=1                      -- Actual rows returned
loops=1                     -- Times this node executed
Buffers: shared hit=3       -- Pages from cache
Buffers: shared read=1      -- Pages from disk (slow!)
```

### Red Flags in EXPLAIN

```
❌ Seq Scan on large table (>10k rows)
❌ High actual rows vs estimated (bad stats)
❌ Nested Loop with high outer rows
❌ Sort with high memory usage
❌ Buffers: shared read >> shared hit
```

---

## Query Optimization

### Avoid SELECT *

```sql
-- Bad: fetches all columns
SELECT * FROM users WHERE id = 1;

-- Good: fetch only needed
SELECT id, email, name FROM users WHERE id = 1;
```

### Optimize JOINs

```sql
-- Ensure join columns are indexed
CREATE INDEX idx_orders_user ON orders(user_id);

-- Prefer explicit JOIN over subquery
-- Bad
SELECT * FROM users 
WHERE id IN (SELECT user_id FROM orders WHERE total > 100);

-- Good
SELECT DISTINCT u.* FROM users u
JOIN orders o ON u.id = o.user_id
WHERE o.total > 100;
```

### Pagination Optimization

```sql
-- Bad: OFFSET scans skipped rows
SELECT * FROM posts ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- Good: Keyset pagination (cursor-based)
SELECT * FROM posts 
WHERE created_at < $last_created_at
ORDER BY created_at DESC 
LIMIT 20;
```

### Batch Operations

```sql
-- Bad: Individual inserts
INSERT INTO logs VALUES (1, 'a');
INSERT INTO logs VALUES (2, 'b');

-- Good: Batch insert
INSERT INTO logs VALUES (1, 'a'), (2, 'b'), (3, 'c');

-- For updates: Use UNNEST
UPDATE products SET price = data.price
FROM (SELECT UNNEST($1::int[]) as id, UNNEST($2::numeric[]) as price) data
WHERE products.id = data.id;
```

---

## JSONB Optimization

### Index JSONB

```sql
-- GIN index for containment queries
CREATE INDEX idx_data_gin ON products USING gin(metadata);

-- Query
SELECT * FROM products WHERE metadata @> '{"category": "electronics"}';
```

### Extract and Index

```sql
-- Index specific JSONB path
CREATE INDEX idx_data_category ON products((metadata->>'category'));

-- Query
SELECT * FROM products WHERE metadata->>'category' = 'electronics';
```

### JSONB Operators

```sql
->    -- Get JSON object field (returns JSON)
->>   -- Get JSON object field (returns text)
#>    -- Get JSON path (returns JSON)
#>>   -- Get JSON path (returns text)
@>    -- Contains
<@    -- Contained by
?     -- Key exists
```

---

## Connection Pooling

### PgBouncer Config

```ini
[databases]
mydb = host=localhost dbname=mydb

[pgbouncer]
pool_mode = transaction    ; Use transaction pooling
max_client_conn = 1000
default_pool_size = 20
min_pool_size = 5
reserve_pool_size = 5
reserve_pool_timeout = 3
```

### Pool Modes

| Mode | Use Case | Prepared Statements |
|------|----------|---------------------|
| **session** | Legacy apps | ✅ Supported |
| **transaction** | Most web apps | ❌ Not supported |
| **statement** | Simple queries | ❌ Not supported |

---

## Vacuum & Maintenance

### Auto-Vacuum Settings

```sql
-- Check auto-vacuum stats
SELECT relname, last_vacuum, last_autovacuum, 
       n_dead_tup, n_live_tup
FROM pg_stat_user_tables;

-- Tune for high-write tables
ALTER TABLE orders SET (
  autovacuum_vacuum_scale_factor = 0.05,
  autovacuum_analyze_scale_factor = 0.02
);
```

### Manual Maintenance

```sql
-- Update statistics
ANALYZE users;

-- Reclaim space (non-blocking)
VACUUM users;

-- Full vacuum (blocking, reclaims disk)
VACUUM FULL users;

-- Reindex
REINDEX INDEX idx_users_email;
```

---

## Locking & Concurrency

### Lock Levels

```sql
-- Weakest to strongest
ACCESS SHARE           -- SELECT
ROW SHARE             -- SELECT FOR UPDATE
ROW EXCLUSIVE         -- INSERT, UPDATE, DELETE
SHARE UPDATE EXCLUSIVE -- VACUUM, CREATE INDEX CONCURRENTLY
SHARE                 -- CREATE INDEX
SHARE ROW EXCLUSIVE   -- CREATE TRIGGER
EXCLUSIVE             -- REFRESH MAT VIEW CONCURRENTLY
ACCESS EXCLUSIVE      -- DROP, TRUNCATE, ALTER TABLE
```

### Avoiding Deadlocks

```sql
-- Always lock in consistent order
BEGIN;
SELECT * FROM accounts WHERE id IN (1, 2) 
ORDER BY id FOR UPDATE;
-- Process...
COMMIT;
```

### Non-Blocking Index Creation

```sql
-- Create index without blocking writes
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
```

---

## Partitioning

### Range Partitioning

```sql
CREATE TABLE orders (
  id SERIAL,
  created_at TIMESTAMP,
  total NUMERIC
) PARTITION BY RANGE (created_at);

CREATE TABLE orders_2024_01 PARTITION OF orders
  FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');

CREATE TABLE orders_2024_02 PARTITION OF orders
  FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

### List Partitioning

```sql
CREATE TABLE orders (
  id SERIAL,
  region TEXT,
  total NUMERIC
) PARTITION BY LIST (region);

CREATE TABLE orders_us PARTITION OF orders FOR VALUES IN ('US');
CREATE TABLE orders_eu PARTITION OF orders FOR VALUES IN ('EU');
```

---

## Debugging Tools

```sql
-- Current queries
SELECT pid, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE state != 'idle';

-- Blocking queries
SELECT blocked.pid, blocked.query, blocking.pid, blocking.query
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(blocked.pid));

-- Table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid))
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Index usage
SELECT relname, indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
ORDER BY idx_scan;
```
