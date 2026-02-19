#!/bin/bash
# Post Tool Use Hook (Sync) - Quick formatting + lazy pattern detection
# Keep this FAST (<15s) - runs after every edit

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only process Edit/Write operations
if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Warn on generated/declaration files
BASENAME=$(basename "$FILE_PATH")
if [[ "$BASENAME" == *.generated.ts ]] || [[ "$BASENAME" == *.generated.tsx ]] || [[ "$BASENAME" == *.d.ts ]]; then
  echo "⚠️ Edited generated/declaration file: $BASENAME — ensure this is intentional (source may overwrite)"
fi

# Quick format based on file type
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx)
    # Prettier only (fast)
    if [ -f "node_modules/.bin/prettier" ]; then
      npx prettier --write "$FILE_PATH" 2>/dev/null && echo "✓ Formatted"
    fi

    # ESLint auto-fix (opt-in: only if eslint config + binary exist)
    if [ -f "node_modules/.bin/eslint" ]; then
      HAS_ESLINT_CONFIG=false
      for cfg in eslint.config.js eslint.config.mjs eslint.config.cjs eslint.config.ts .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml .eslintrc.yaml; do
        if [ -f "$cfg" ]; then
          HAS_ESLINT_CONFIG=true
          break
        fi
      done
      if $HAS_ESLINT_CONFIG; then
        npx eslint --fix "$FILE_PATH" 2>/dev/null && echo "✓ ESLint fixed"
      fi
    fi

    # LAZY PATTERN DETECTION (instant feedback)
    LAZY=""
    grep -n "TODO\|FIXME\|XXX" "$FILE_PATH" 2>/dev/null && LAZY="${LAZY}⚠️ TODO found - implement now\n"
    grep -n ": any" "$FILE_PATH" 2>/dev/null | head -1 && LAZY="${LAZY}⚠️ 'any' type - add proper types\n"
    grep -n "@ts-ignore\|@ts-expect-error" "$FILE_PATH" 2>/dev/null | head -1 && LAZY="${LAZY}⚠️ @ts-ignore found - fix the type error properly\n"
    grep -n "() => {}" "$FILE_PATH" 2>/dev/null | head -1 && LAZY="${LAZY}⚠️ Empty handler - implement it\n"
    grep -n "console\.log" "$FILE_PATH" 2>/dev/null | grep -v "// debug" | head -1 && LAZY="${LAZY}💡 console.log - remove or show to user\n"

    # Mock data detection — exclude test/fixture/seed files
    if [[ "$FILE_PATH" != *"test"* ]] && [[ "$FILE_PATH" != *"spec"* ]] && \
       [[ "$FILE_PATH" != *"fixture"* ]] && [[ "$FILE_PATH" != *"seed"* ]] && \
       [[ "$FILE_PATH" != *"mock"* ]] && [[ "$FILE_PATH" != *"__test"* ]] && \
       [[ "$FILE_PATH" != *".test."* ]] && [[ "$FILE_PATH" != *".spec."* ]]; then
      grep -nE "^\s*\[\s*\{[^}]*id:\s*['\"]?[0-9]+['\"]?\s*,\s*name:" "$FILE_PATH" 2>/dev/null | head -1 && LAZY="${LAZY}⚠️ Possible mock data array\n"
    fi

    if [ -n "$LAZY" ]; then
      echo -e "\n🔍 LAZY PATTERNS DETECTED:"
      echo -e "$LAZY"
    fi

    # Churn detection — warn on 3+ edits to same file
    TEMP_HASH=$(pwd | md5 2>/dev/null | cut -c1-8 || pwd | md5sum 2>/dev/null | cut -c1-8)
    CHURN_LOG="/tmp/claude-$TEMP_HASH/session-changes.log"
    if [ -f "$CHURN_LOG" ]; then
      EDIT_COUNT=$(grep -c "^${FILE_PATH}$" "$CHURN_LOG" 2>/dev/null || echo "0")
      if [ "$EDIT_COUNT" -ge 3 ]; then
        echo -e "\n⚠️ You've edited $(basename "$FILE_PATH") $EDIT_COUNT times this session. Stop and verify your approach."
      fi
    fi

    # Schema migration reminder
    if [[ "$FILE_PATH" == *"schema"* ]] && [[ "$FILE_PATH" == *.ts ]]; then
      echo -e "\n💡 Schema file changed — run 'npm run db:generate' to check for pending migrations"
    fi

    # === Generic Post-Edit Checks (pattern-detected) ===

    # S3 presigned URL check — if project uses AWS SDK
    if [ -f "package.json" ]; then
      if grep -qE '"@?aws-sdk' package.json 2>/dev/null; then
        if grep -n "getSignedUrl\|presignedUrl\|presigned" "$FILE_PATH" 2>/dev/null | head -1 > /dev/null 2>&1; then
          if grep -qn "getSignedUrl\|presignedUrl\|presigned" "$FILE_PATH" 2>/dev/null; then
            echo -e "\n⚠️ PRESIGNED URL DETECTED — Reminder:"
            echo "  If using dual endpoints (internal vs public), verify you're using the correct one."
            echo "  Internal access (server-side): use internal/docker endpoint"
            echo "  External URLs (APIs, browser): use public endpoint"
          fi
        fi
      fi
    fi

    # React hooks ordering check — always check .tsx files
    if [[ "$FILE_PATH" == *.tsx ]]; then
      TEMP_HASH=$(pwd | md5 2>/dev/null | cut -c1-8 || pwd | md5sum 2>/dev/null | cut -c1-8)
      HOOK_TEMP_DIR="/tmp/claude-$TEMP_HASH"
      mkdir -p "$HOOK_TEMP_DIR"
      if grep -n "return.*<\|return null" "$FILE_PATH" 2>/dev/null | head -5 > "$HOOK_TEMP_DIR/returns.tmp"; then
        if grep -n "use[A-Z]" "$FILE_PATH" 2>/dev/null | head -5 > "$HOOK_TEMP_DIR/hooks.tmp"; then
          FIRST_RETURN=$(head -1 "$HOOK_TEMP_DIR/returns.tmp" | cut -d: -f1)
          LAST_HOOK=$(tail -1 "$HOOK_TEMP_DIR/hooks.tmp" | cut -d: -f1)
          if [ -n "$FIRST_RETURN" ] && [ -n "$LAST_HOOK" ] && [ "$FIRST_RETURN" -lt "$LAST_HOOK" ] 2>/dev/null; then
            echo -e "\n❌ REACT HOOK VIOLATION: Early return at line $FIRST_RETURN before hook at line $LAST_HOOK"
            echo "  Move ALL hooks before any conditional returns!"
          fi
        fi
      fi
      rm -f "$HOOK_TEMP_DIR/returns.tmp" "$HOOK_TEMP_DIR/hooks.tmp"
    fi

    # i18n hardcoded string check — if project uses i18n
    if [ -f "package.json" ]; then
      if grep -qE '"next-intl"|"i18next"|"react-i18next"|"react-intl"' package.json 2>/dev/null; then
        HARDCODED=$(grep -nE '>\s*(Loading|Error|No |Are you sure|Delete|Save|Cancel|Submit|Create|Edit|Settings|Profile)\b' "$FILE_PATH" 2>/dev/null | grep -v "t(" | grep -v "useTranslations" | head -3)
        if [ -n "$HARDCODED" ]; then
          echo -e "\n⚠️ i18n: Possible hardcoded English strings (should use t()):"
          echo "$HARDCODED"
        fi
      fi
    fi

    # Stripe httpClient check — if project uses Stripe
    if [ -f "package.json" ]; then
      if grep -q '"stripe"' package.json 2>/dev/null; then
        if grep -q "new Stripe" "$FILE_PATH" 2>/dev/null; then
          if ! grep -q "httpClient\|createFetchHttpClient" "$FILE_PATH" 2>/dev/null; then
            echo -e "\n❌ STRIPE: Missing createFetchHttpClient!"
            echo "  Stripe SDK should use createFetchHttpClient() on serverless platforms (Vercel, etc)."
            echo "  Also check: stripe in serverExternalPackages in next.config"
          fi
        fi
      fi
    fi
    ;;
  *.json)
    # i18n locale file check — catch MISSING_MESSAGE early
    if [[ "$FILE_PATH" == *"locale"* ]] || [[ "$FILE_PATH" == *"i18n"* ]] || [[ "$FILE_PATH" == *"messages"* ]]; then
      if grep -q "MISSING_MESSAGE" "$FILE_PATH" 2>/dev/null; then
        echo -e "\n⚠️ MISSING_MESSAGE found in locale file: $FILE_PATH"
        grep -n "MISSING_MESSAGE" "$FILE_PATH" 2>/dev/null | head -5
      fi
    fi
    ;;
  *.go)
    gofmt -w "$FILE_PATH" 2>/dev/null && echo "✓ Formatted"
    ;;
esac

exit 0
