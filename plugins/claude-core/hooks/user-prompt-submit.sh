#!/bin/bash
# User Prompt Submit Hook - Smart Context Display
# Keep this FAST (<2s) - runs on every prompt

echo "=== Current State ==="

# Dev server status (fast)
if command -v lsof &> /dev/null; then
  lsof -ti:3000 &> /dev/null && echo "🟢 Dev server running on :3000"
  lsof -ti:8080 &> /dev/null && echo "🟢 Server running on :8080"
  lsof -ti:19000 &> /dev/null && echo "🟢 Expo running on :19000"
fi

# Project-specific temp dir
PROJECT_HASH=$(pwd | md5 2>/dev/null | cut -c1-8 || pwd | md5sum 2>/dev/null | cut -c1-8)
TEMP_DIR="/tmp/claude-$PROJECT_HASH"
mkdir -p "$TEMP_DIR"

ISSUES_FOUND=false

# TypeScript errors (always relevant)
if [ -f "$TEMP_DIR/tsc-errors.log" ] && [ -s "$TEMP_DIR/tsc-errors.log" ]; then
  ERROR_COUNT=$(wc -l < "$TEMP_DIR/tsc-errors.log" | tr -d ' ')
  if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "❌ TypeScript errors ($ERROR_COUNT lines)"
    head -3 "$TEMP_DIR/tsc-errors.log" | sed 's/^/   /'
    ISSUES_FOUND=true
  fi
fi

# Test failures (check flag from async hook)
if [ -f "$TEMP_DIR/test-failures.flag" ]; then
  echo "❌ Tests failed in background - check results"
  if [ -f "$TEMP_DIR/test-results.log" ]; then
    grep -E "FAIL|✗|Error:|expected|received" "$TEMP_DIR/test-results.log" 2>/dev/null | head -3 | sed 's/^/   /'
  fi
  rm -f "$TEMP_DIR/test-failures.flag"
  ISSUES_FOUND=true
elif [ -f "$TEMP_DIR/test-results.log" ] && grep -q "FAIL\|Error" "$TEMP_DIR/test-results.log" 2>/dev/null; then
  echo "❌ Test failures detected"
  grep -E "FAIL|✗|Error:" "$TEMP_DIR/test-results.log" 2>/dev/null | head -2 | sed 's/^/   /'
  ISSUES_FOUND=true
fi

# Security warnings (only show if exist - means API/auth was touched)
if [ -f "$TEMP_DIR/security-warnings.log" ] && [ -s "$TEMP_DIR/security-warnings.log" ]; then
  echo "🔒 Security warnings:"
  cat "$TEMP_DIR/security-warnings.log" | sed 's/^/   /'
  ISSUES_FOUND=true
fi

# Database warnings (only show if exist - means DB was touched)
if [ -f "$TEMP_DIR/db-warnings.log" ] && [ -s "$TEMP_DIR/db-warnings.log" ]; then
  echo "🗄️ Database warnings:"
  cat "$TEMP_DIR/db-warnings.log" | sed 's/^/   /'
  ISSUES_FOUND=true
fi

# Build warnings (from async config file check)
if [ -f "$TEMP_DIR/build-warnings.log" ] && [ -s "$TEMP_DIR/build-warnings.log" ]; then
  echo "🏗️ Build warnings:"
  cat "$TEMP_DIR/build-warnings.log" | sed 's/^/   /'
  ISSUES_FOUND=true
fi

# Session change summary (useful context)
if [ -f "$TEMP_DIR/session-changes.log" ]; then
  CHANGE_COUNT=$(wc -l < "$TEMP_DIR/session-changes.log" | tr -d ' ')
  if [ "$CHANGE_COUNT" -gt 5 ]; then
    echo "📝 Session: $CHANGE_COUNT files modified"
  fi
fi

if [ "$ISSUES_FOUND" = false ]; then
  echo "✅ No errors detected"
fi

exit 0
