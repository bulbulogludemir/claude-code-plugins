# Claude Code

**Model: Opus 4.6 | 1M context | Always.**

---

## Execution Mode

1. **Execute IMMEDIATELY.** No clarifying questions unless genuinely ambiguous.
2. **Never stop at planning.** Analyze AND implement in the same session.
3. When given a written plan, implement ALL changes — do not re-analyze.
4. **Escalation protocol:** 2 failed attempts at same approach → switch strategy. 3rd failure → stop and ask the user.

---

## Precedence

`project CLAUDE.md` > `global CLAUDE.md` > `hooks` > `skills` > `memory`

Project-level instructions always override these defaults. If conflict exists, the more specific source wins.

---

## Context Management

- **Session naming:** `[project]-[feature]-[date]` (e.g. `myapp-auth-0219`)
- **Long sessions:** Checkpoint progress every major milestone. Compress context early.
- **Multi-project awareness:** Always verify cwd before making changes.

---

## Quality Gates

- **Anti-Laziness:** No mock data, no TODO, no empty handlers, no `any`, no `console.log` errors.
- **Proof Required:** Run `npx tsc --noEmit` and show output before saying "done".
- **Hooks enforce this automatically** — quality-gate blocks incomplete work.

---

## Tech Stack

**Web:** Next.js 16, React 19, TypeScript strict, Tailwind 4, shadcn/ui, Drizzle ORM, React Query, Zustand
**Mobile:** Expo SDK 54+, Expo Router, NativeWind v4, Supabase
**Infrastructure:** Detect from project config — supports Coolify, Vercel, Hetzner, Docker.

---

## Rules

- Only modify files directly related to the task
- Never edit `.env` files
- Never use `any` type or `@ts-ignore`
- Never skip auth on API routes
- Never ship mock data or leave TODO comments
- Never force push without asking
- Never modify production DB records during debugging
- Never add features beyond what was requested
- Read errors carefully, trace code paths, verify API params from docs — never guess
- **i18n:** If project uses i18n, always use `t()` for user-facing strings
- **Stripe:** Never use real keys in test/dev. Verify webhook signing secrets match environment.
- **Image quality:** Never compress images below 1MB. Preserve quality first.
