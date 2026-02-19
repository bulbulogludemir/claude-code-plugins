---
name: planning
description: "Plan, PRD, requirements. Auto-use for new features/projects."
version: 4.0.0
triggers: [plan, PRD, requirements, new feature, feature design, gereksinim, yeni özellik]
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - WebSearch
  - WebFetch
  - Task
  - AskUserQuestion
  - Skill
  - mcp__claude-in-chrome__*
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeamCreate
  - SendMessage
---

# Planning

**Auto-use when:** plan, PRD, requirements, "let's build", new feature, feature design

**Works with:** Routes to `frontend`, `backend`, `mobile`, `quality` for execution

---

## Workflow

```
1. CLASSIFY → Small | Medium | Large | Project
2. INTERVIEW → Questions based on scope (BRIEF — max 3-5 questions for Small/Medium)
3. SPEC → Document decisions
4. TASKS → Break down with skill routing
5. EXECUTE → Use correct skill per task (DO NOT STOP HERE — implement immediately)
6. VERIFY → Test + browser check
```

**IMPORTANT:** Unless the user says "just plan" or "analyze only", you MUST proceed through ALL steps including execution. Do not end a session at step 3 or 4 with just a plan document.

---

## 1. Classify Scope

| Scope | Signs | Questions |
|-------|-------|-----------|
| **Small** | Bug fix, minor change | 3-5 |
| **Medium** | New page, CRUD feature | 10-20 |
| **Large** | Major feature, new flows | 40+ |
| **Project** | Greenfield, new app | 60+ |

---

## 2. Interview Categories

```
1. TECHNICAL - Architecture, API, performance
2. UI/UX - Flows, states, mobile
3. DATA - Models, validation, caching
4. EDGE CASES - Failures, concurrent users
5. SECURITY - Permissions, audit
6. TRADEOFFS - Build vs buy, debt
7. BUSINESS - Metrics, rollout
8. INTEGRATION - Dependencies, fallbacks
```

---

## 3. Generate Spec

```markdown
# [Feature] Spec

## Decisions
| Area | Decision | Why |
|------|----------|-----|
| Auth | Supabase | Already in stack |

## Technical Design
[Based on interview]

## User Flows
1. User clicks X
2. Form appears
3. ...

## Edge Cases
- Empty state: Show message + CTA
- Error: Show retry button
```

---

## 4. Generate Tasks with Skill Routing

```json
{
  "id": "TASK-001",
  "title": "Create user form",
  "skill": "frontend",
  "acceptance": [
    "Form validates input",
    "Shows loading on submit",
    "Shows success/error feedback"
  ]
}
```

### Skill Routing

| Task involves... | Use |
|------------------|-----|
| React, UI, form, component | `frontend` |
| API, database, webhook, auth, permissions | `backend` |
| React Native, Expo | `mobile` |
| Test, debug | `quality` |

---

## 5. Execute (MANDATORY — do not skip)

```
FOR each task:
  1. Use correct skill (frontend/backend/etc)
  2. Implement COMPLETELY (no mocks, all states)
  3. Run quality checks (tsc, tests)
  4. If UI: browser verify
  5. Mark done with evidence

DO NOT stop at the plan stage. Execute immediately after planning.
If the task is large, use parallel Task agents for independent work.
```

---

## 6. Verify Completion

```
□ tsc --noEmit passes
□ Tests pass
□ No mock data
□ All UI states (loading, error, empty)
□ Browser tested (if UI)
□ Console has no errors
```

### Browser Verification
```typescript
// Navigate
mcp__claude-in-chrome__navigate({ url: "http://localhost:3000/...", tabId })

// Screenshot
mcp__claude-in-chrome__computer({ action: "screenshot", tabId })

// Click buttons
mcp__claude-in-chrome__find({ query: "submit button", tabId })
mcp__claude-in-chrome__computer({ action: "left_click", ref: "ref_X", tabId })

// Check errors
mcp__claude-in-chrome__read_console_messages({ tabId, onlyErrors: true })
```

---

## Quick Reference

| User Says | Do |
|-----------|-----|
| "Plan/build X" | Full workflow |
| "Add feature" | Medium interview → tasks → execute |
| "Fix bug" | Use `quality` skill directly |
| "New project" | Use `onboarding` skill |

---

