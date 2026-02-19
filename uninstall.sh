#!/bin/bash
# Claude Code Plugins — Uninstall Script
# Removes all custom plugins installed by install.sh

set -euo pipefail

CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins/marketplaces/claude-code-plugins"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ALL_PLUGINS=(claude-core claude-frontend claude-backend claude-mobile claude-devops claude-quality claude-devtools)

echo "=== Claude Code Plugins Uninstaller ==="
echo ""

# 1. Remove installed plugin files
if [ -d "$PLUGINS_DIR" ]; then
  echo "🗑  Removing plugin marketplace..."
  rm -rf "$PLUGINS_DIR"
  echo "  ✓ Removed $PLUGINS_DIR"
fi

# 2. Remove agents installed by our plugins
echo "🗑  Removing agents..."
for plugin in "${ALL_PLUGINS[@]}"; do
  if [ -d "$SCRIPT_DIR/plugins/$plugin/agents" ]; then
    for agent_file in "$SCRIPT_DIR/plugins/$plugin/agents/"*.md; do
      local_name=$(basename "$agent_file")
      if [ -f "$CLAUDE_DIR/agents/$local_name" ]; then
        rm "$CLAUDE_DIR/agents/$local_name"
        echo "  ✓ Removed agent: $local_name"
      fi
    done
  fi
done

# 3. Remove skills installed by our plugins
echo "🗑  Removing skills..."
for plugin in "${ALL_PLUGINS[@]}"; do
  if [ -d "$SCRIPT_DIR/plugins/$plugin/skills" ]; then
    for skill_dir in "$SCRIPT_DIR/plugins/$plugin/skills/"*/; do
      local_name=$(basename "$skill_dir")
      if [ -d "$CLAUDE_DIR/skills/$local_name" ]; then
        rm -rf "$CLAUDE_DIR/skills/$local_name"
        echo "  ✓ Removed skill: $local_name"
      fi
    done
  fi
done

# 4. Remove rules installed by our plugins
echo "🗑  Removing rules..."
for plugin in "${ALL_PLUGINS[@]}"; do
  if [ -d "$SCRIPT_DIR/plugins/$plugin/rules" ]; then
    for rule_file in "$SCRIPT_DIR/plugins/$plugin/rules/"*.md; do
      local_name=$(basename "$rule_file")
      if [ -f "$CLAUDE_DIR/rules/$local_name" ]; then
        rm "$CLAUDE_DIR/rules/$local_name"
        echo "  ✓ Removed rule: $local_name"
      fi
    done
  fi
done

# 5. Remove hooks installed by our plugins
echo "🗑  Removing hooks..."
for plugin in "${ALL_PLUGINS[@]}"; do
  if [ -d "$SCRIPT_DIR/plugins/$plugin/hooks" ]; then
    for hook_file in "$SCRIPT_DIR/plugins/$plugin/hooks/"*.sh; do
      local_name=$(basename "$hook_file")
      if [ -f "$CLAUDE_DIR/hooks/$local_name" ]; then
        rm "$CLAUDE_DIR/hooks/$local_name"
        echo "  ✓ Removed hook: $local_name"
      fi
    done
  fi
done

# 6. Remove scripts
echo "🗑  Removing scripts..."
if [ -f "$CLAUDE_DIR/statusline-command.sh" ]; then
  rm "$CLAUDE_DIR/statusline-command.sh"
  echo "  ✓ Removed statusline-command.sh"
fi

# 7. Clean up settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  echo "📝 Cleaning settings.json..."

  # Remove enabledPlugins entries
  for plugin in "${ALL_PLUGINS[@]}"; do
    SETTINGS_TMP=$(jq "del(.enabledPlugins[\"${plugin}@claude-code-plugins\"])" "$SETTINGS_FILE")
    echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
  done
  echo "  ✓ Removed enabledPlugins entries"

  # Remove hook registrations that point to ~/.claude/hooks/
  SETTINGS_TMP=$(jq '
    if .hooks then
      .hooks |= with_entries(
        .value |= map(
          .hooks |= map(select(.command | test("~/.claude/hooks/") | not))
        ) | map(select(.hooks | length > 0))
      ) | if .hooks | to_entries | map(select(.value | length > 0)) | length == 0 then del(.hooks) else . end
    else . end
  ' "$SETTINGS_FILE")
  echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
  echo "  ✓ Removed hook registrations"

  # Remove statusline config
  SETTINGS_TMP=$(jq 'del(.statusline)' "$SETTINGS_FILE")
  echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
  echo "  ✓ Removed statusline config"
fi

# 8. Clean up installed_plugins.json
INSTALLED_FILE="$CLAUDE_DIR/plugins/installed_plugins.json"
if [ -f "$INSTALLED_FILE" ] && command -v jq &>/dev/null; then
  echo "📝 Cleaning installed_plugins.json..."
  for plugin in "${ALL_PLUGINS[@]}"; do
    SETTINGS_TMP=$(jq "del(.plugins[\"${plugin}@claude-code-plugins\"])" "$INSTALLED_FILE")
    echo "$SETTINGS_TMP" > "$INSTALLED_FILE"
  done
  echo "  ✓ Removed plugin entries"
fi

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "Restart Claude Code to apply changes."
