#!/bin/bash
# Unified Quality Gate — blocks agent idle, task complete, and session stop
# Exit code 2 = BLOCK and send feedback to Claude
GATE_TYPE="${1:-stop}"

# Only run if TS files were changed this session
PROJECT_HASH=$(pwd | md5 2>/dev/null | cut -c1-8 || pwd | md5sum 2>/dev/null | cut -c1-8)
TEMP_DIR="/tmp/claude-$PROJECT_HASH"
mkdir -p "$TEMP_DIR"
CHANGES_LOG="$TEMP_DIR/session-changes.log"

if [ ! -f "$CHANGES_LOG" ]; then
  exit 0  # No changes, nothing to check
fi

HAS_TS_CHANGES=$(grep -cE '\.(ts|tsx)$' "$CHANGES_LOG" 2>/dev/null || echo "0")
if [ "$HAS_TS_CHANGES" -eq 0 ]; then
  exit 0  # Only non-TS files changed
fi

ERRORS=""

# 1. TypeScript check (full, not incremental)
if [ -f "tsconfig.json" ]; then
  TSC_OUTPUT=$(npx tsc --noEmit 2>&1 | head -20)
  if echo "$TSC_OUTPUT" | grep -q "error TS"; then
    echo "$TSC_OUTPUT" > "$TEMP_DIR/tsc-errors.log"
    ERROR_COUNT=$(echo "$TSC_OUTPUT" | grep -c "error TS")
    ERRORS="${ERRORS}\n❌ TypeScript: $ERROR_COUNT errors found\n$(echo "$TSC_OUTPUT" | head -10)"
  else
    rm -f "$TEMP_DIR/tsc-errors.log"
  fi
fi

# 2. Lazy patterns in changed files
CHANGED_TS=$(grep -E '\.(ts|tsx)$' "$CHANGES_LOG" | sort -u)
for f in $CHANGED_TS; do
  [ -f "$f" ] || continue

  ANY_FOUND=$(grep -n ": any" "$f" 2>/dev/null | head -2)
  [ -n "$ANY_FOUND" ] && ERRORS="${ERRORS}\n⚠️ 'any' type in $f\n$ANY_FOUND"

  TODO_FOUND=$(grep -n "TODO\|FIXME" "$f" 2>/dev/null | head -2)
  [ -n "$TODO_FOUND" ] && ERRORS="${ERRORS}\n⚠️ TODO in $f\n$TODO_FOUND"

  IGNORE_FOUND=$(grep -n "@ts-ignore\|@ts-expect-error" "$f" 2>/dev/null | head -1)
  [ -n "$IGNORE_FOUND" ] && ERRORS="${ERRORS}\n⚠️ @ts-ignore in $f\n$IGNORE_FOUND"
done

# 3. i18n check (generic — detect locale dirs)
if [ -d "src/messages" ] || [ -d "src/i18n" ]; then
  MISSING=$(grep -r "MISSING_MESSAGE" src/messages/ src/i18n/ 2>/dev/null | head -3)
  if [ -n "$MISSING" ]; then
    ERRORS="${ERRORS}\n❌ MISSING_MESSAGE in locale files:\n$MISSING"
  fi
fi

# 4. console.log detection in changed files (WARN only, never blocks)
CONSOLE_FILES=""
for f in $CHANGED_TS; do
  [ -f "$f" ] || continue
  if grep -q "console\.log" "$f" 2>/dev/null; then
    CONSOLE_FILES="${CONSOLE_FILES} $(basename "$f")"
  fi
done
if [ -n "$CONSOLE_FILES" ]; then
  echo "⚠️ console.log detected in:${CONSOLE_FILES}. Remove before shipping." >&2
fi

# 4b. Import cycle detection (basic — check for circular imports)
if command -v npx &> /dev/null && [ -f "tsconfig.json" ]; then
  # Use a simple heuristic: if file A imports B and B imports A
  for f in $CHANGED_TS; do
    [ -f "$f" ] || continue
    IMPORTS=$(grep -oP "from ['\"](\./[^'\"]+)['\"]" "$f" 2>/dev/null | sed "s/from ['\"]//;s/['\"]//")
    for imp in $IMPORTS; do
      # Resolve relative import to check reverse dependency
      IMP_DIR=$(dirname "$f")
      IMP_FILE="$IMP_DIR/$imp"
      for ext in .ts .tsx /index.ts /index.tsx; do
        if [ -f "${IMP_FILE}${ext}" ]; then
          if grep -q "$(basename "$f" .tsx)" "${IMP_FILE}${ext}" 2>/dev/null || grep -q "$(basename "$f" .ts)" "${IMP_FILE}${ext}" 2>/dev/null; then
            echo "⚠️ Potential circular import: $f ↔ ${IMP_FILE}${ext}" >&2
          fi
          break
        fi
      done
    done
  done
fi

# 5. If errors found
if [ -n "$ERRORS" ]; then
  echo "═══════════════════════════════════════" >&2
  if [ "$GATE_TYPE" = "stop" ]; then
    echo "⚠️ QUALITY GATE WARNING ($GATE_TYPE)" >&2
  else
    echo "🚫 QUALITY GATE FAILED ($GATE_TYPE)" >&2
  fi
  echo "═══════════════════════════════════════" >&2
  echo -e "$ERRORS" >&2
  echo "" >&2
  if [ "$GATE_TYPE" = "stop" ]; then
    echo "Issues detected at session end. These should have been caught earlier." >&2
    exit 0  # NEVER block Stop — creates infinite retry loop
  else
    echo "FIX these before proceeding. Do NOT claim 'done' with errors." >&2
    exit 2  # Block teammate idle / task complete
  fi
fi

echo "✅ Quality gate passed ($GATE_TYPE)" >&2
exit 0
