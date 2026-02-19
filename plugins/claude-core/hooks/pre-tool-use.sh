#!/bin/bash
# Pre Tool Use Hook - Guard dangerous operations
# Uses CLAUDE_HOOK_* env vars (fast, no JSON parsing)

FILE_PATH="${CLAUDE_HOOK_ARGS_file_path:-}"
COMMAND="${CLAUDE_HOOK_ARGS_command:-}"
TOOL="${CLAUDE_HOOK_TOOL_NAME:-}"

# === Generated/Declaration File Protection ===
if [[ "$TOOL" == "Edit" || "$TOOL" == "Write" ]] && [ -n "$FILE_PATH" ]; then
  BASENAME=$(basename "$FILE_PATH")
  if [[ "$FILE_PATH" != *"node_modules"* ]]; then
    if [[ "$BASENAME" == *.generated.ts ]] || [[ "$BASENAME" == *.generated.tsx ]]; then
      echo "🚫 Cannot edit generated file: $FILE_PATH. Edit the source instead." >&2
      exit 2
    fi
    if [[ "$BASENAME" == *.d.ts ]]; then
      echo "🚫 Cannot edit declaration file: $FILE_PATH. Edit the source instead." >&2
      exit 2
    fi
  fi
fi

# === Protected Files ===
PROTECTED_FILES=(
  ".env"
  ".env.local"
  ".env.production"
  "package-lock.json"
  "yarn.lock"
  "pnpm-lock.yaml"
  "Podfile.lock"
  ".git/"
)

for protected in "${PROTECTED_FILES[@]}"; do
  if [[ "$FILE_PATH" == *"$protected"* ]]; then
    echo "🚫 BLOCKED: $protected is protected" >&2
    exit 2
  fi
done

# === Forbidden Directories ===
FORBIDDEN_DIRS=(
  "node_modules/"
  ".next/"
  "dist/"
  "build/"
  ".expo/"
)

for dir in "${FORBIDDEN_DIRS[@]}"; do
  if [[ "$FILE_PATH" == *"$dir"* ]]; then
    echo "🚫 BLOCKED: Cannot write to $dir (generated)" >&2
    exit 2
  fi
done

# === System Paths ===
SYSTEM_PATHS=("/etc/" "/usr/" "/bin/" "/sbin/" "/System/" "/Library/")

for sys in "${SYSTEM_PATHS[@]}"; do
  if [[ "$FILE_PATH" == "$sys"* ]]; then
    echo "🚫 BLOCKED: System directory" >&2
    exit 2
  fi
done

# === Dangerous Bash Commands ===
if [[ "$TOOL" == "Bash" && -n "$COMMAND" ]]; then
  # These patterns are caught by settings.json prompts, but double-check
  if echo "$COMMAND" | grep -qE "rm -rf /|rm -rf ~|sudo rm|DROP DATABASE|DROP TABLE"; then
    echo "🚫 BLOCKED: Dangerous command" >&2
    exit 2
  fi

  # Production database safety — block direct record modifications via SSH/psql
  if echo "$COMMAND" | grep -qiE "ssh.*(-.*)?UPDATE\s+users|ssh.*(-.*)?DELETE\s+FROM|ssh.*(-.*)?ALTER\s+TABLE|psql.*UPDATE\s+users|psql.*DELETE\s+FROM"; then
    echo "🚫 BLOCKED: Direct production DB modification detected. Ask user for confirmation." >&2
    exit 2
  fi
fi

# === Generic Project Guards (config-driven) ===
# Find project root via git or nearest package.json
PROJECT_ROOT=""
if git rev-parse --show-toplevel > /dev/null 2>&1; then
  PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
elif [ -f "package.json" ]; then
  PROJECT_ROOT="$PWD"
fi

# Check for .claude-protected file in project root
if [ -n "$PROJECT_ROOT" ] && [ -f "$PROJECT_ROOT/.claude-protected" ]; then
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    # Skip comments and empty lines
    [[ "$pattern" =~ ^#.*$ ]] && continue
    [[ -z "$pattern" ]] && continue
    if [[ "$FILE_PATH" == *"$pattern"* ]]; then
      echo "🚫 BLOCKED: '$pattern' is protected (see .claude-protected)" >&2
      exit 2
    fi
  done < "$PROJECT_ROOT/.claude-protected"
fi

exit 0
