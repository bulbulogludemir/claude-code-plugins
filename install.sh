#!/bin/bash
# Claude Code Plugins — Install Script (Symlink-based)
# Usage: bash install.sh [plugin1 plugin2 ...]
# If no plugins specified, installs all 7.
#
# All assets are symlinked, not copied. After install:
#   git pull   → changes propagate instantly to ~/.claude/
#   No need to re-run install.sh after updates.

set -euo pipefail

# Check dependencies
if ! command -v jq &>/dev/null; then
  echo "❌ jq is required but not installed."
  echo "   Install: brew install jq (macOS) or apt install jq (Linux)"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins/marketplaces/claude-code-plugins"

ALL_PLUGINS=(claude-core claude-frontend claude-backend claude-mobile claude-devops claude-quality claude-devtools)

# Parse args — default to all
if [ $# -eq 0 ]; then
  SELECTED_PLUGINS=("${ALL_PLUGINS[@]}")
else
  SELECTED_PLUGINS=("$@")
fi

echo "=== Claude Code Plugins Installer (Symlink) ==="
echo "Installing: ${SELECTED_PLUGINS[*]}"
echo "Source: $SCRIPT_DIR"
echo ""

# 1. Symlink marketplace
echo "🔗 Linking marketplace..."
mkdir -p "$CLAUDE_DIR/plugins/marketplaces"
ln -sfn "$SCRIPT_DIR" "$PLUGINS_DIR"

# 2. Symlink selected plugin assets
for plugin in "${SELECTED_PLUGINS[@]}"; do
  if [ ! -d "$SCRIPT_DIR/plugins/$plugin" ]; then
    echo "⚠️  Plugin not found: $plugin (skipping)"
    continue
  fi

  echo "🔗 Linking $plugin..."
  PLUGIN_SRC="$SCRIPT_DIR/plugins/$plugin"

  # Symlink agents to ~/.claude/agents/
  if [ -d "$PLUGIN_SRC/agents" ]; then
    mkdir -p "$CLAUDE_DIR/agents"
    for f in "$PLUGIN_SRC/agents/"*.md; do
      [ -f "$f" ] && ln -sf "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
    done
    echo "  ✓ Agents"
  fi

  # Symlink skills to ~/.claude/skills/
  if [ -d "$PLUGIN_SRC/skills" ]; then
    mkdir -p "$CLAUDE_DIR/skills"
    for d in "$PLUGIN_SRC/skills/"*/; do
      [ -d "$d" ] && ln -sfn "$d" "$CLAUDE_DIR/skills/$(basename "$d")"
    done
    echo "  ✓ Skills"
  fi

  # Symlink rules to ~/.claude/rules/
  if [ -d "$PLUGIN_SRC/rules" ]; then
    mkdir -p "$CLAUDE_DIR/rules"
    for f in "$PLUGIN_SRC/rules/"*.md; do
      [ -f "$f" ] && ln -sf "$f" "$CLAUDE_DIR/rules/$(basename "$f")"
    done
    echo "  ✓ Rules"
  fi

  # Symlink hooks to ~/.claude/hooks/
  if [ -d "$PLUGIN_SRC/hooks" ]; then
    mkdir -p "$CLAUDE_DIR/hooks"
    for f in "$PLUGIN_SRC/hooks/"*.sh; do
      [ -f "$f" ] && ln -sf "$f" "$CLAUDE_DIR/hooks/$(basename "$f")"
    done
    echo "  ✓ Hooks"
  fi

  # Symlink scripts to ~/.claude/
  if [ -d "$PLUGIN_SRC/scripts" ]; then
    for f in "$PLUGIN_SRC/scripts/"*; do
      [ -f "$f" ] && ln -sf "$f" "$CLAUDE_DIR/$(basename "$f")"
    done
    echo "  ✓ Scripts"
  fi
done

# 3. Update installed_plugins.json
INSTALLED_FILE="$CLAUDE_DIR/plugins/installed_plugins.json"
echo ""
echo "📝 Updating installed_plugins.json..."

# Build plugins JSON
PLUGINS_JSON="{"
PLUGINS_JSON+='"version": 2, "plugins": {'
FIRST=true
for plugin in "${SELECTED_PLUGINS[@]}"; do
  if [ -d "$SCRIPT_DIR/plugins/$plugin" ]; then
    if [ "$FIRST" = true ]; then
      FIRST=false
    else
      PLUGINS_JSON+=","
    fi
    PLUGINS_JSON+="\"${plugin}@claude-code-plugins\": [{\"scope\": \"user\", \"installPath\": \"$PLUGINS_DIR/plugins/$plugin\", \"version\": \"1.0.0\", \"installedAt\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\", \"lastUpdated\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\", \"gitCommitSha\": \"\"}]"
  fi
done
PLUGINS_JSON+="}}"

# Merge with existing installed_plugins.json if it exists
if [ -f "$INSTALLED_FILE" ]; then
  echo "  Merging with existing plugins..."
  # Keep existing plugins, add new ones
  EXISTING=$(cat "$INSTALLED_FILE")
  echo "$EXISTING" | jq --argjson new "$(echo "$PLUGINS_JSON")" '.plugins += $new.plugins' > "${INSTALLED_FILE}.tmp" && mv "${INSTALLED_FILE}.tmp" "$INSTALLED_FILE"
else
  echo "$PLUGINS_JSON" | jq '.' > "$INSTALLED_FILE"
fi

# 4. Update enabledPlugins in settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

# Ensure settings.json exists
if [ ! -f "$SETTINGS_FILE" ]; then
  echo "📝 Creating settings.json..."
  echo '{}' | jq '.' > "$SETTINGS_FILE"
fi

echo "📝 Updating settings.json enabledPlugins..."
for plugin in "${SELECTED_PLUGINS[@]}"; do
  if [ -d "$SCRIPT_DIR/plugins/$plugin" ]; then
    SETTINGS_TMP=$(jq ".enabledPlugins[\"${plugin}@claude-code-plugins\"] = true" "$SETTINGS_FILE")
    echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
  fi
done

# 5. Register hooks in settings.json
echo ""
echo "🔗 Registering hooks..."

register_hook() {
  local event="$1"
  local command="$2"
  local hook_file="$3"

  if [ ! -f "$CLAUDE_DIR/hooks/$hook_file" ]; then
    return
  fi

  # Check if this hook is already registered
  if jq -e ".hooks.${event}[]?.hooks[]? | select(.command == \"${command}\")" "$SETTINGS_FILE" &>/dev/null; then
    echo "  ⏭ Hook already registered: $hook_file → $event"
    return
  fi

  # Add hook entry
  local hook_json="{\"matcher\": \"\", \"hooks\": [{\"type\": \"command\", \"command\": \"${command}\"}]}"

  # Ensure hooks object and event array exist
  SETTINGS_TMP=$(jq ".hooks //= {} | .hooks.${event} //= [] | .hooks.${event} += [${hook_json}]" "$SETTINGS_FILE")
  echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
  echo "  ✓ Registered: $hook_file → $event"
}

register_hook "PreToolUse" "bash ~/.claude/hooks/pre-tool-use.sh \$TOOL_NAME" "pre-tool-use.sh"
register_hook "PostToolUse" "bash ~/.claude/hooks/quality-gate.sh \$TOOL_NAME" "quality-gate.sh"
register_hook "UserPromptSubmit" "bash ~/.claude/hooks/user-prompt-submit.sh" "user-prompt-submit.sh"
register_hook "SessionStart" "bash ~/.claude/hooks/session-start.sh" "session-start.sh"

# 6. Configure statusline
echo ""
echo "📊 Configuring statusLine..."
if [ -f "$CLAUDE_DIR/statusline-command.sh" ]; then
  SETTINGS_TMP=$(jq '.statusLine = {"type": "command", "command": "bash ~/.claude/statusline-command.sh"}' "$SETTINGS_FILE")
  echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
  echo "  ✓ Statusline enabled"
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Recommended: Also install official MCP plugins:"
echo "  claude plugin install stripe@claude-plugins-official"
echo "  claude plugin install supabase@claude-plugins-official"
echo "  claude plugin install sentry@claude-plugins-official"
echo "  claude plugin install vercel@claude-plugins-official"
echo ""
echo "Restart Claude Code to activate plugins."
