# Claude Code Plugins

Modular plugin system for Claude Code — 7 domain plugins, 10 agents, 17 skills, 11 hooks, 7 rules covering the complete software engineering workflow.

## Quick Start (Interactive)

**En kolay yol:** [SETUP_PROMPT.md](SETUP_PROMPT.md) dosyasındaki prompt'u Claude Code'a yapıştır. Sana hangi parçaları istediğini sorar ve otomatik kurar.

## Quick Start (Manual)

```bash
# Prerequisites: jq (brew install jq)
git clone https://github.com/bulbulogludemir/claude-code-plugins.git
cd claude-code-plugins
bash install.sh          # Install all
# or
bash install.sh claude-core claude-frontend  # Selective install
```

Restart Claude Code to activate.

## What's Included

### Custom Plugins

| Plugin | Domain | Contents |
|--------|--------|----------|
| `claude-core` | Foundation | Explorer agent, core hooks (session-start, pre-tool-use, post-tool-use, quality-gate, subagent-context), core skills (implement, planning, onboarding), all rules (typescript, security, performance, testing, git), statusline |
| `claude-frontend` | UI | Frontend/i18n agents, component/styling/UI/accessibility/performance/SEO skills |
| `claude-backend` | API & Data | Backend/database/security/analytics agents, API/DB/integration/jobs/analytics/monitoring/email/AI skills, api/database rules |
| `claude-mobile` | Mobile | Mobile agent, Expo/React Native/NativeWind skill |
| `claude-devops` | Infrastructure | DevOps agent, release skill, pre-deploy/post-deploy hooks |
| `claude-quality` | QA | Reviewer agent, quality/bugfix/error-recovery skills |
| `claude-devtools` | Git & Review | Review-plan/refactor skills, pre-commit/codex-review hooks |

### Global Config

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Execution mode, quality gates, tech stack definitions, safety rules |
| `settings.template.json` | Full hook config (rm -rf protection, force push guard, quality gate, statusline) |

### External Plugins (auto-installed)

| Plugin | Purpose |
|--------|---------|
| `typescript-lsp` | TypeScript language server |
| `stripe` | Stripe integration |
| `supabase` | Supabase integration |
| `sentry` | Sentry error tracking |
| `vercel` | Vercel deployment |
| `indexandria` | Documentation indexing |

## How It Works

Install uses **symlinks**, not copies. After initial install:

```bash
cd ~/Projects/claude-code-plugins
git pull   # Changes propagate instantly — no re-install needed
```

## Uninstall

```bash
bash uninstall.sh
```

## Tech Stack

- **Web:** Next.js 16, React 19, TypeScript strict, Tailwind 4, shadcn/ui, Drizzle ORM
- **Mobile:** Expo SDK 54+, NativeWind v4, Supabase
- **Infrastructure:** Coolify, Vercel, Hetzner, Docker

## License

MIT
