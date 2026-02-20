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

# 3. Symlink CLAUDE.md
echo ""
echo "🔗 Linking CLAUDE.md..."
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
  # Back up existing CLAUDE.md if it's not already a symlink
  if [ -f "$CLAUDE_DIR/CLAUDE.md" ] && [ ! -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    echo "  Backing up existing CLAUDE.md → CLAUDE.md.bak"
    mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak"
  fi
  ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "  ✓ CLAUDE.md"
fi

# 4. Update installed_plugins.json
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
  EXISTING=$(cat "$INSTALLED_FILE")
  echo "$EXISTING" | jq --argjson new "$(echo "$PLUGINS_JSON")" '.plugins += $new.plugins' > "${INSTALLED_FILE}.tmp" && mv "${INSTALLED_FILE}.tmp" "$INSTALLED_FILE"
else
  echo "$PLUGINS_JSON" | jq '.' > "$INSTALLED_FILE"
fi

# 5. Apply settings.json from template
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
TEMPLATE_FILE="$SCRIPT_DIR/settings.template.json"

echo ""
echo "📝 Configuring settings.json..."

if [ ! -f "$SETTINGS_FILE" ]; then
  # Fresh install — use template directly
  echo "  Creating from template..."
  /bin/cp "$TEMPLATE_FILE" "$SETTINGS_FILE"
else
  # Merge: template hooks/plugins/statusLine into existing settings
  # Preserves user's existing keys (permissions, env overrides, etc.)
  echo "  Merging template into existing settings..."
  SETTINGS_TMP=$(jq -s '
    .[0] as $existing | .[1] as $template |
    $existing
    | .hooks = $template.hooks
    | .statusLine = $template.statusLine
    | .env = (($existing.env // {}) * ($template.env // {}))
    | .enabledPlugins = (($existing.enabledPlugins // {}) * ($template.enabledPlugins // {}))
  ' "$SETTINGS_FILE" "$TEMPLATE_FILE")
  echo "$SETTINGS_TMP" > "$SETTINGS_FILE"
fi
echo "  ✓ Hooks, plugins, statusLine configured"

# 6. Install external plugins via claude CLI
echo ""
echo "📦 Installing external plugins..."

EXTERNAL_PLUGINS=(
  "typescript-lsp@claude-plugins-official"
  "stripe@claude-plugins-official"
  "supabase@claude-plugins-official"
  "sentry@claude-plugins-official"
  "vercel@claude-plugins-official"
  "indexandria@indexandria"
)

if command -v claude &>/dev/null; then
  for ext_plugin in "${EXTERNAL_PLUGINS[@]}"; do
    # Check if already installed
    if [ -f "$INSTALLED_FILE" ] && jq -e ".plugins[\"$ext_plugin\"]" "$INSTALLED_FILE" &>/dev/null; then
      echo "  ⏭ Already installed: $ext_plugin"
    else
      echo "  📦 Installing $ext_plugin..."
      claude plugin install "$ext_plugin" 2>/dev/null && echo "  ✓ $ext_plugin" || echo "  ⚠️  Failed: $ext_plugin (install manually: claude plugin install $ext_plugin)"
    fi
  done
else
  echo "  ⚠️  'claude' CLI not found. Install external plugins manually after installing Claude Code:"
  for ext_plugin in "${EXTERNAL_PLUGINS[@]}"; do
    echo "    claude plugin install $ext_plugin"
  done
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Installed:"
echo "  - 7 custom plugins (10 agents, 17 skills, 11 hooks, 7 rules)"
echo "  - 6 external plugins (typescript-lsp, stripe, supabase, sentry, vercel, indexandria)"
echo "  - CLAUDE.md (global instructions)"
echo "  - settings.json (hooks, statusLine, plugins)"
echo ""
echo "Updates: Just run 'git pull' — symlinks propagate changes instantly."
echo ""
echo "Restart Claude Code to activate."
