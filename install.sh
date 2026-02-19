#!/bin/bash
# Claude Code Plugins — Install Script
# Usage: bash install.sh [plugin1 plugin2 ...]
# If no plugins specified, installs all 7.

set -euo pipefail

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

echo "=== Claude Code Plugins Installer ==="
echo "Installing: ${SELECTED_PLUGINS[*]}"
echo ""

# 1. Copy marketplace
echo "📦 Copying marketplace..."
mkdir -p "$PLUGINS_DIR"
cp -r "$SCRIPT_DIR/.claude-plugin" "$PLUGINS_DIR/"

# 2. Copy selected plugins
for plugin in "${SELECTED_PLUGINS[@]}"; do
  if [ ! -d "$SCRIPT_DIR/plugins/$plugin" ]; then
    echo "⚠️  Plugin not found: $plugin (skipping)"
    continue
  fi

  echo "📦 Installing $plugin..."
  PLUGIN_SRC="$SCRIPT_DIR/plugins/$plugin"
  PLUGIN_DST="$PLUGINS_DIR/plugins/$plugin"

  mkdir -p "$PLUGIN_DST"
  cp -r "$PLUGIN_SRC/." "$PLUGIN_DST/"

  # Copy agents to ~/.claude/agents/
  if [ -d "$PLUGIN_SRC/agents" ]; then
    mkdir -p "$CLAUDE_DIR/agents"
    cp "$PLUGIN_SRC/agents/"*.md "$CLAUDE_DIR/agents/" 2>/dev/null || true
    echo "  ✓ Agents"
  fi

  # Copy skills to ~/.claude/skills/
  if [ -d "$PLUGIN_SRC/skills" ]; then
    mkdir -p "$CLAUDE_DIR/skills"
    cp -r "$PLUGIN_SRC/skills/"* "$CLAUDE_DIR/skills/" 2>/dev/null || true
    echo "  ✓ Skills"
  fi

  # Copy rules to ~/.claude/rules/
  if [ -d "$PLUGIN_SRC/rules" ]; then
    mkdir -p "$CLAUDE_DIR/rules"
    cp "$PLUGIN_SRC/rules/"*.md "$CLAUDE_DIR/rules/" 2>/dev/null || true
    echo "  ✓ Rules"
  fi

  # Copy hooks to ~/.claude/hooks/
  if [ -d "$PLUGIN_SRC/hooks" ]; then
    mkdir -p "$CLAUDE_DIR/hooks"
    cp "$PLUGIN_SRC/hooks/"*.sh "$CLAUDE_DIR/hooks/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/hooks/"*.sh 2>/dev/null || true
    echo "  ✓ Hooks"
  fi

  # Copy scripts to ~/.claude/
  if [ -d "$PLUGIN_SRC/scripts" ]; then
    cp "$PLUGIN_SRC/scripts/"* "$CLAUDE_DIR/" 2>/dev/null || true
    chmod +x "$CLAUDE_DIR/"*.sh 2>/dev/null || true
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
if [ -f "$SETTINGS_FILE" ]; then
  echo "📝 Updating settings.json enabledPlugins..."
  for plugin in "${SELECTED_PLUGINS[@]}"; do
    if [ -d "$SCRIPT_DIR/plugins/$plugin" ]; then
      SETTINGS_TMP=$(jq ".enabledPlugins[\"${plugin}@claude-code-plugins\"] = true" "$SETTINGS_FILE")
      echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
    fi
  done
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
