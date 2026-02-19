#!/bin/bash
# Post Tool Use Hook (Async) - File tracking + test running
# Runs in background after every edit

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only validate Edit/Write operations
if [[ "$TOOL" != "Edit" && "$TOOL" != "Write" ]]; then
  exit 0
fi

if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Project-specific temp dir
PROJECT_HASH=$(pwd | md5 2>/dev/null | cut -c1-8 || pwd | md5sum 2>/dev/null | cut -c1-8)
TEMP_DIR="/tmp/claude-$PROJECT_HASH"
mkdir -p "$TEMP_DIR"

# Track changed files for session awareness
echo "$FILE_PATH" >> "$TEMP_DIR/session-changes.log"

# === Categorize the change ===
IS_TS=false
IS_TEST=false

[[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]] && IS_TS=true
[[ "$FILE_PATH" == *.test.* || "$FILE_PATH" == *.spec.* ]] && IS_TEST=true

# === Run Related Tests (smart detection) ===
if [ "$IS_TEST" = true ]; then
  # Test file edited - run it
  if [ -f "package.json" ]; then
    if grep -q '"vitest"' package.json 2>/dev/null; then
      npx vitest run "$FILE_PATH" --reporter=verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    elif grep -q '"jest"' package.json 2>/dev/null; then
      npx jest "$FILE_PATH" --verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    fi
  fi
elif [ "$IS_TS" = true ]; then
  # Source file edited - find and run related test
  TEST_FILE="${FILE_PATH%.ts}.test.ts"
  TEST_FILE2="${FILE_PATH%.tsx}.test.tsx"
  TEST_FILE3=$(echo "$FILE_PATH" | sed 's/\.tsx\?$/.spec.ts/')

  RELATED_TEST=""
  [ -f "$TEST_FILE" ] && RELATED_TEST="$TEST_FILE"
  [ -f "$TEST_FILE2" ] && RELATED_TEST="$TEST_FILE2"
  [ -f "$TEST_FILE3" ] && RELATED_TEST="$TEST_FILE3"

  if [ -n "$RELATED_TEST" ] && [ -f "package.json" ]; then
    if grep -q '"vitest"' package.json 2>/dev/null; then
      npx vitest run "$RELATED_TEST" --reporter=verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    elif grep -q '"jest"' package.json 2>/dev/null; then
      npx jest "$RELATED_TEST" --verbose 2>&1 > "$TEMP_DIR/test-results.log"
      [ $? -ne 0 ] && touch "$TEMP_DIR/test-failures.flag"
    fi
  fi
fi

exit 0
