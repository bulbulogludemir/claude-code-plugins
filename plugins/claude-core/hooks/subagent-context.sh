#!/bin/bash
# Inject project context to subagents — generic, CLAUDE.md-first approach

echo "=== Subagent Context ==="

# Primary: Project CLAUDE.md (best source of truth)
if [ -f "CLAUDE.md" ]; then
  echo "📋 Project CLAUDE.md:"
  cat CLAUDE.md
  echo ""
fi

# Secondary: Generic framework detection (only if no CLAUDE.md)
if [ ! -f "CLAUDE.md" ] && [ -f "package.json" ]; then
  echo "📦 Detected stack:"
  grep -q '"next"' package.json 2>/dev/null && echo "  - Next.js"
  grep -q '"expo"' package.json 2>/dev/null && echo "  - Expo"
  grep -q '"react"' package.json 2>/dev/null && echo "  - React"
  grep -q '"drizzle-orm"' package.json 2>/dev/null && echo "  - Drizzle ORM"
  grep -qE '"@?supabase' package.json 2>/dev/null && echo "  - Supabase"
  grep -q '"stripe"' package.json 2>/dev/null && echo "  - Stripe"
  grep -qE '"next-intl"|"i18next"' package.json 2>/dev/null && echo "  - i18n (use t() for all strings)"
  grep -qE '"@?aws-sdk' package.json 2>/dev/null && echo "  - AWS SDK (check S3 endpoint usage)"
  echo ""
fi

# Always: Git context
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo "🔀 Git:"
  echo "  Branch: $(git branch --show-current 2>/dev/null)"
  echo "  Recent:"
  git log --oneline -5 2>/dev/null | sed 's/^/    /'
fi

exit 0
