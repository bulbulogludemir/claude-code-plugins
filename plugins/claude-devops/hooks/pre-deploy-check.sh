#!/bin/bash
# Pre-Deploy Check — runs before git push to main
# Validates the build is clean before deploying

echo "🚀 Pre-deploy validation..."

ERRORS=0

# 1. Full TypeScript check
if [ -f "tsconfig.json" ]; then
  echo "  Checking TypeScript..."
  if ! npx tsc --noEmit 2>/dev/null; then
    echo "❌ TypeScript errors — fix before deploying" >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# 2. Build verification
if [ -f "package.json" ]; then
  echo "  Verifying build..."
  if ! NODE_ENV=production npm run build > /dev/null 2>&1; then
    echo "❌ Build failed — fix before deploying" >&2
    ERRORS=$((ERRORS + 1))
  fi
fi

# 3. Check for pending migrations
if [ -d "drizzle" ] || [ -d "src/lib/db/migrations" ]; then
  UNSTAGED_MIGRATIONS=$(git diff --name-only -- "drizzle/" "src/lib/db/migrations/" 2>/dev/null)
  if [ -n "$UNSTAGED_MIGRATIONS" ]; then
    echo "⚠️  Unstaged migration files detected. Commit migrations before deploying." >&2
  fi
fi

# 4. Environment variable validation
if [ -f ".env.example" ] && [ -f ".env" ]; then
  MISSING_VARS=""
  while IFS= read -r line; do
    VAR_NAME=$(echo "$line" | grep -oP '^[A-Z_]+=')
    if [ -n "$VAR_NAME" ]; then
      VAR_NAME="${VAR_NAME%=}"
      if ! grep -q "^${VAR_NAME}=" .env 2>/dev/null; then
        MISSING_VARS="${MISSING_VARS} ${VAR_NAME}"
      fi
    fi
  done < .env.example
  if [ -n "$MISSING_VARS" ]; then
    echo "⚠️  Missing env vars:${MISSING_VARS}" >&2
  fi
fi

# 5. Secrets in code check
SECRETS_FOUND=$(grep -rn "sk_live_\|AKIA[0-9A-Z]\{16\}" --include="*.ts" --include="*.tsx" . 2>/dev/null | head -3)
if [ -n "$SECRETS_FOUND" ]; then
  echo "❌ Secrets found in source code!" >&2
  echo "$SECRETS_FOUND" >&2
  ERRORS=$((ERRORS + 1))
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "❌ Pre-deploy checks failed ($ERRORS errors)" >&2
  exit 2
fi

echo "✅ Pre-deploy checks passed"
exit 0
