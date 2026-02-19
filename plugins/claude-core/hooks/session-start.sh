#!/bin/bash
# Session Start Hook - Load Project Intelligence

# Clean stale temp files (older than 24h) from previous sessions
find /tmp -maxdepth 1 -name "claude-*" -type d -mmin +1440 -exec rm -rf {} \; 2>/dev/null

# Detect project type and provide context
echo "=== Project Analysis ==="

# Check for project-specific CLAUDE.md
if [ -f "CLAUDE.md" ]; then
  echo "📋 Project CLAUDE.md found - check for project-specific patterns"
else
  echo "💡 No project CLAUDE.md found. Consider creating one for project-specific context."
fi

# Monorepo detection
if [ -f "pnpm-workspace.yaml" ]; then
  echo "📦 Monorepo (pnpm workspaces)"
  echo "  Packages: $(ls packages 2>/dev/null | tr '\n' ' ')"
fi

# Node.js / Web
if [ -f "package.json" ]; then
  echo "📦 Node.js project"

  # Node version detection
  if [ -f ".nvmrc" ]; then
    echo "  Node version (.nvmrc): $(cat .nvmrc 2>/dev/null)"
  elif [ -f ".node-version" ]; then
    echo "  Node version (.node-version): $(cat .node-version 2>/dev/null)"
  fi

  # Framework detection
  if grep -q '"next"' package.json 2>/dev/null; then
    echo "  Framework: Next.js"
  elif grep -q '"expo"' package.json 2>/dev/null || [ -f "app.json" ]; then
    echo "  Framework: Expo (React Native)"
    echo "  ⚠️  Use 'npx expo install' for native packages"
  elif grep -q '"react-native"' package.json 2>/dev/null; then
    echo "  Framework: React Native"
  elif grep -q '"react"' package.json 2>/dev/null; then
    echo "  Framework: React"
  elif grep -q '"vue"' package.json 2>/dev/null; then
    echo "  Framework: Vue"
  fi

  # Auth provider detection
  if grep -q '"@clerk/nextjs"' package.json 2>/dev/null; then
    echo "  Auth: Clerk"
  elif grep -q '"next-auth"' package.json 2>/dev/null; then
    echo "  Auth: NextAuth.js"
  elif grep -q '"@supabase/auth-helpers"' package.json 2>/dev/null; then
    echo "  Auth: Supabase Auth Helpers"
  elif grep -q '"@supabase/ssr"' package.json 2>/dev/null; then
    echo "  Auth: Supabase SSR Auth"
  fi

  # Tailwind version detection
  TW_VERSION=$(jq -r '(.dependencies.tailwindcss // .devDependencies.tailwindcss) // empty' package.json 2>/dev/null)
  if [ -n "$TW_VERSION" ]; then
    case "$TW_VERSION" in
      4*|^4*|~4*) echo "  Tailwind: v4 ($TW_VERSION) — CSS-first config, @theme directive" ;;
      3*|^3*|~3*) echo "  Tailwind: v3 ($TW_VERSION) — JS config (tailwind.config.js)" ;;
      *)          echo "  Tailwind: $TW_VERSION" ;;
    esac
  fi

  # Database detection
  if grep -q '"drizzle-orm"' package.json 2>/dev/null; then
    echo "  Database: Drizzle ORM"
  fi
  if grep -q '"@supabase"' package.json 2>/dev/null; then
    echo "  Database: Supabase"
  fi

  # Queue/Background Jobs
  if grep -q '"bullmq"' package.json 2>/dev/null; then
    echo "  Queue: BullMQ (Redis)"
  fi
  if grep -q '"inngest"' package.json 2>/dev/null; then
    echo "  Queue: Inngest"
  fi

  # AI
  if grep -q '"openai"' package.json 2>/dev/null; then
    echo "  AI: OpenAI"
  fi
  if grep -q '"@fal-ai"' package.json 2>/dev/null; then
    echo "  AI: fal.ai"
  fi

  # Key dependencies (compact)
  DEPS=$(jq -r '.dependencies | keys | join(", ")' package.json 2>/dev/null | head -c 100)
  if [ -n "$DEPS" ]; then
    echo "  Key deps: $DEPS..."
  fi

  # Scripts available
  SCRIPTS=$(jq -r '.scripts | keys | join(", ")' package.json 2>/dev/null)
  if [ -n "$SCRIPTS" ]; then
    echo "  Scripts: $SCRIPTS"
  fi
fi

# Expo-specific detection
if [ -f "app.json" ]; then
  echo "📱 Expo project detected"
  if [ -f "eas.json" ]; then
    echo "  EAS configured"
  fi
  if [ -d "ios" ] || [ -d "android" ]; then
    echo "  Native directories present (prebuild done)"
  fi
fi

# React Native / Mobile (non-Expo)
if [ -f "ios/Podfile" ] || [ -f "android/build.gradle" ]; then
  if ! [ -f "app.json" ]; then
    echo "📱 React Native project (bare)"
  fi
  if [ -f "ios/Podfile" ]; then
    echo "  iOS: Present"
  fi
  if [ -f "android/build.gradle" ]; then
    echo "  Android: Present"
  fi
fi

# Docker detection
if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -d "docker" ]; then
  echo "🐳 Docker configured"
fi

# Git context
if git rev-parse --git-dir > /dev/null 2>&1; then
  echo ""
  echo "=== Git Status ==="
  BRANCH=$(git branch --show-current 2>/dev/null)
  echo "  Branch: $BRANCH"

  # Uncommitted changes
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "  Status: Uncommitted changes present"
  else
    echo "  Status: Clean"
  fi

  # Recent commits
  echo "  Recent commits:"
  git log --oneline -3 2>/dev/null | sed 's/^/    /'
fi

# Environment setup
if [ -n "$CLAUDE_ENV_FILE" ]; then
  # Set NODE_ENV if not set
  if ! grep -q "NODE_ENV" "$CLAUDE_ENV_FILE" 2>/dev/null; then
    echo "export NODE_ENV=development" >> "$CLAUDE_ENV_FILE"
  fi
fi

# Active team detection
if [ -d "$HOME/.claude/teams" ]; then
  ACTIVE_TEAMS=$(ls -d "$HOME/.claude/teams"/*/ 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ACTIVE_TEAMS" -gt 0 ]; then
    echo ""
    echo "=== Active Teams ==="
    for team_dir in "$HOME/.claude/teams"/*/; do
      team_name=$(basename "$team_dir")
      echo "  Team: $team_name"
    done
  fi
fi

# Pending tasks detection
if [ -d "$HOME/.claude/tasks" ]; then
  TASK_DIRS=$(ls -d "$HOME/.claude/tasks"/*/ 2>/dev/null | wc -l | tr -d ' ')
  if [ "$TASK_DIRS" -gt 0 ]; then
    echo "  Pending task groups: $TASK_DIRS"
  fi
fi

echo ""
echo "✅ Context loaded"

exit 0
