# Claude Code Plugins

Modular plugin system for Claude Code — 7 domain plugins covering the complete software engineering workflow.

## Plugins

| Plugin | Domain | Contents |
|--------|--------|----------|
| `claude-core` | Foundation | Explorer agent, core hooks (session-start, pre-tool-use, post-tool-use, quality-gate, subagent-context), core skills (implement, planning, onboarding), all rules (typescript, security, performance, testing, git), statusline |
| `claude-frontend` | UI | Frontend/i18n agents, component/styling/UI/accessibility/performance/SEO skills |
| `claude-backend` | API & Data | Backend/database/security/analytics agents, API/DB/integration/jobs/analytics/monitoring/email/AI skills, api/database rules |
| `claude-mobile` | Mobile | Mobile agent, Expo/React Native/NativeWind skill |
| `claude-devops` | Infrastructure | DevOps agent, release skill, pre-deploy/post-deploy hooks |
| `claude-quality` | QA | Reviewer agent, quality/bugfix/error-recovery skills |
| `claude-devtools` | Git & Review | Review-plan/refactor skills, pre-commit/codex-review hooks |

## Quick Start

### Prerequisites

- [Claude Code](https://claude.ai/claude-code) installed
- `jq` installed (`brew install jq` on macOS, `apt install jq` on Linux)

### Install

```bash
git clone https://github.com/bulbulogludemir/claude-code-plugins.git
cd claude-code-plugins
bash install.sh
```

Restart Claude Code to activate.

### Uninstall

```bash
bash uninstall.sh
```

### Selective Install

Install only specific plugins:

```bash
bash install.sh claude-core claude-frontend claude-backend
```

### Manual Install

1. Copy marketplace to Claude Code plugins:
```bash
/bin/cp -r . ~/.claude/plugins/marketplaces/claude-code-plugins/
```

2. Enable in `~/.claude/settings.json`:
```json
{
  "enabledPlugins": {
    "claude-core@claude-code-plugins": true,
    "claude-frontend@claude-code-plugins": true,
    "claude-backend@claude-code-plugins": true
  }
}
```

## Tech Stack

- **Web:** Next.js 16, React 19, TypeScript strict, Tailwind 4, shadcn/ui, Drizzle ORM
- **Mobile:** Expo SDK 54+, NativeWind v4, Supabase
- **Infrastructure:** Coolify, Vercel, Hetzner, Docker

## Recommended MCP Plugins

Install these from the official marketplace for full functionality:

```bash
claude plugin install stripe@claude-plugins-official
claude plugin install supabase@claude-plugins-official
claude plugin install sentry@claude-plugins-official
claude plugin install vercel@claude-plugins-official
```

## License

MIT
