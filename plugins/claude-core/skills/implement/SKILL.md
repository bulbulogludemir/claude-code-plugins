---
name: implement
description: "Execute an implementation plan immediately with parallel agents and quality gates. Use when given a plan to implement."
version: 1.0.0
triggers: [implement, execute plan, uygula, planı çalıştır]
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Task
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - TeamCreate
  - SendMessage
  - AskUserQuestion
---

# Implement

Execute the provided plan. Do NOT ask questions. Do NOT re-analyze. Do NOT stay in plan mode.

## Steps

1. **Read the full plan** — understand all changes needed
2. **Break into parallelizable tasks** — use Task agents for independent work (max 3-4 agents)
3. **Detect shared dependencies** — before launching agents, identify file-level dependencies (e.g., if Agent A creates a type/schema/util that Agent B imports). If agents have shared dependencies, run the dependency-provider agent FIRST, then launch dependent agents in parallel after it completes.
4. **Each agent implements its assigned scope** — no scope creep, stay on assigned files
5. **After ALL agents complete, run integration verification:**
   - **TypeScript**: `npx tsc --noEmit` (full, NOT incremental — do not use `--incremental` or rely on `.tsbuildinfo`)
   - **Tests**: `npm test` (if test scripts exist in package.json)
   - **Cross-file type errors**: Pay special attention to imports between files modified by different agents. Verify shared interfaces, exported types, and function signatures match across boundaries.
   - **i18n**: `grep -r "MISSING_MESSAGE" src/ || true`
   ```bash
   npx tsc --noEmit          # Full check, NOT incremental
   npm test                   # If tests exist
   grep -r "MISSING_MESSAGE" src/ || true  # i18n check
   ```
6. **Fix any errors** until zero remain — do NOT report done with errors
7. **Report completion with evidence:**
   ```
   ## Done
   - tsc --noEmit: 0 errors
   - npm test: X passing
   - Files changed: [list]
   ```

## Rules

- NEVER stop at planning — the plan is already provided, execute it
- NEVER add features not in the plan
- NEVER skip the post-agent verification
- Each agent must stay scoped to its assigned files
- If a step in the plan is unclear, make a reasonable decision and proceed
- Do not ask "should I proceed?" — yes, always proceed
