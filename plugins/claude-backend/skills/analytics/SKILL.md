---
name: analytics
description: SQL/Drizzle queries, metrics, GA4, cohort analysis
triggers: [analytics, metrics, DAU, MAU, funnel, cohort, revenue, conversion]
allowed-tools:
  - Read
  - Bash
  - Grep
  - Glob
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
---

# Analytics Skill

Run data & metrics queries against Supabase/Postgres databases.

## When to Use
- User asks for metrics (DAU, WAU, MAU, conversion, retention)
- User wants to "pull numbers" or "check data"
- Funnel analysis, cohort analysis
- Revenue/transaction queries
- Event tracking queries
- Any "how many X did Y" questions

## Connection Methods

### 1. Supabase CLI (Preferred)
```bash
# Requires: supabase CLI installed + linked project
supabase db query "SELECT ..."

# With output format
supabase db query --output csv "SELECT ..."
```

### 2. Direct psql (If CLI unavailable)
```bash
# Uses DATABASE_URL from .env.local or environment
psql "$DATABASE_URL" -c "SELECT ..."

# Pretty output
psql "$DATABASE_URL" -c "SELECT ..." --expanded
```

### 3. Check Connection First
```bash
# Verify Supabase CLI is linked
supabase status

# Or test psql connection
psql "$DATABASE_URL" -c "SELECT 1"
```

## Safety Rules

### READ-ONLY by Default
- Only run SELECT queries without explicit permission
- Never run INSERT, UPDATE, DELETE, DROP, TRUNCATE without user confirmation
- Always show the query before executing

### Before Mutations
1. Show the exact query
2. Explain what it will change
3. Ask: "This will modify data. Proceed? (y/n)"
4. Only execute after explicit "yes"

## Query Templates

### User Metrics

**Daily Active Users (DAU)**
```sql
SELECT DATE(created_at) as date, COUNT(DISTINCT user_id) as dau
FROM events
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

**Weekly Active Users (WAU)**
```sql
SELECT DATE_TRUNC('week', created_at) as week, COUNT(DISTINCT user_id) as wau
FROM events
WHERE created_at >= CURRENT_DATE - INTERVAL '12 weeks'
GROUP BY DATE_TRUNC('week', created_at)
ORDER BY week DESC;
```

**Monthly Active Users (MAU)**
```sql
SELECT DATE_TRUNC('month', created_at) as month, COUNT(DISTINCT user_id) as mau
FROM events
WHERE created_at >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;
```

**New Signups**
```sql
SELECT DATE(created_at) as date, COUNT(*) as signups
FROM users
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### Funnel Analysis

**Basic Funnel**
```sql
WITH funnel AS (
  SELECT
    COUNT(DISTINCT CASE WHEN event = 'page_view' THEN user_id END) as viewed,
    COUNT(DISTINCT CASE WHEN event = 'signup_started' THEN user_id END) as started,
    COUNT(DISTINCT CASE WHEN event = 'signup_completed' THEN user_id END) as completed
  FROM events
  WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT
  viewed,
  started,
  completed,
  ROUND(100.0 * started / NULLIF(viewed, 0), 2) as start_rate,
  ROUND(100.0 * completed / NULLIF(started, 0), 2) as completion_rate
FROM funnel;
```

### Cohort Analysis

**Weekly Retention**
```sql
WITH cohorts AS (
  SELECT
    user_id,
    DATE_TRUNC('week', MIN(created_at)) as cohort_week
  FROM events
  GROUP BY user_id
),
activity AS (
  SELECT
    c.cohort_week,
    DATE_TRUNC('week', e.created_at) as activity_week,
    COUNT(DISTINCT e.user_id) as users
  FROM events e
  JOIN cohorts c ON e.user_id = c.user_id
  GROUP BY c.cohort_week, DATE_TRUNC('week', e.created_at)
)
SELECT
  cohort_week,
  activity_week,
  users,
  EXTRACT(WEEK FROM activity_week - cohort_week) as week_number
FROM activity
ORDER BY cohort_week, activity_week;
```

### Revenue Metrics

**Daily Revenue**
```sql
SELECT DATE(created_at) as date, SUM(amount) as revenue, COUNT(*) as transactions
FROM transactions
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
  AND status = 'completed'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

**Monthly Revenue**
```sql
SELECT
  DATE_TRUNC('month', created_at) as month,
  SUM(amount) as revenue,
  COUNT(*) as transactions,
  COUNT(DISTINCT user_id) as paying_users,
  ROUND(SUM(amount) / COUNT(DISTINCT user_id), 2) as arpu
FROM transactions
WHERE status = 'completed'
  AND created_at >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;
```

**Top Users by Spend**
```sql
SELECT
  u.id,
  u.email,
  COUNT(t.id) as transaction_count,
  SUM(t.amount) as total_spent
FROM users u
JOIN transactions t ON u.id = t.user_id
WHERE t.status = 'completed'
GROUP BY u.id, u.email
ORDER BY total_spent DESC
LIMIT 10;
```

### Event Tracking

**Event Counts**
```sql
SELECT event, COUNT(*) as count
FROM events
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY event
ORDER BY count DESC;
```

**User Journey**
```sql
SELECT
  user_id,
  event,
  created_at,
  LAG(event) OVER (PARTITION BY user_id ORDER BY created_at) as previous_event
FROM events
WHERE user_id = 'USER_ID_HERE'
ORDER BY created_at;
```

## Common Requests → Queries

| Request | Template |
|---------|----------|
| "How many signups this week?" | New Signups (filter: 7 days) |
| "What's our conversion rate?" | Basic Funnel |
| "Show DAU for last month" | Daily Active Users |
| "Top 10 users by spend" | Top Users by Spend |
| "Revenue this month" | Daily/Monthly Revenue |
| "User retention" | Weekly Retention Cohort |

## Workflow

1. **Understand the question** - What metric/data does the user need?
2. **Check schema** - Run `\dt` or check migrations to understand tables
3. **Build query** - Start with template, adapt to actual schema
4. **Show query** - Display before executing
5. **Execute** - Run via Supabase CLI or psql
6. **Format results** - Present data clearly, add context

## Schema Discovery

```bash
# List all tables
supabase db query "\dt"

# Describe a table
supabase db query "\d tablename"

# Sample rows
supabase db query "SELECT * FROM tablename LIMIT 5"
```

## Error Handling

- If connection fails, check `supabase status` or DATABASE_URL
- If table doesn't exist, run schema discovery first
- If query is slow, suggest adding LIMIT or date filters
- Always surface errors to user, never hide them
