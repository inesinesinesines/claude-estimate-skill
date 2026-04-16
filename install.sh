#!/bin/bash
# Claude Estimate Skill - Installer
# Installs timing hooks, scripts, and skill definition into ~/.claude/

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Estimate Skill Installer ==="
echo ""

# 1. Copy scripts
echo "[1/3] Installing timing scripts..."
mkdir -p "$CLAUDE_DIR/scripts"
cp "$SCRIPT_DIR/scripts/timing.sh" "$CLAUDE_DIR/scripts/timing.sh"
cp "$SCRIPT_DIR/scripts/timing-stats.sh" "$CLAUDE_DIR/scripts/timing-stats.sh"
chmod +x "$CLAUDE_DIR/scripts/timing.sh"
chmod +x "$CLAUDE_DIR/scripts/timing-stats.sh"
echo "  -> $CLAUDE_DIR/scripts/timing.sh"
echo "  -> $CLAUDE_DIR/scripts/timing-stats.sh"

# 2. Copy skill
echo "[2/3] Installing skill definition..."
mkdir -p "$CLAUDE_DIR/skills/estimate"
cp "$SCRIPT_DIR/skills/estimate/SKILL.md" "$CLAUDE_DIR/skills/estimate/SKILL.md"
echo "  -> $CLAUDE_DIR/skills/estimate/SKILL.md"

# 3. Merge hooks into settings.json
echo "[3/3] Configuring hooks in settings.json..."

SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOKS_PATCH="$SCRIPT_DIR/hooks-patch.json"

if [ ! -f "$SETTINGS_FILE" ]; then
  # No settings.json yet — create from template
  cp "$SCRIPT_DIR/settings-template.json" "$SETTINGS_FILE"
  echo "  -> Created $SETTINGS_FILE"
else
  # Check if hooks already configured
  if grep -q 'timing.sh' "$SETTINGS_FILE" 2>/dev/null; then
    echo "  -> Hooks already configured, skipping."
  else
    echo ""
    echo "  [!] settings.json already exists but does not have timing hooks."
    echo "  You need to manually merge the hooks from:"
    echo "    $SCRIPT_DIR/settings-template.json"
    echo ""
    echo "  Or run with --force to overwrite (WARNING: replaces existing settings):"
    echo "    bash install.sh --force"
    echo ""
    if [ "$1" = "--force" ]; then
      # Backup and overwrite
      BACKUP="$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"
      cp "$SETTINGS_FILE" "$BACKUP"
      echo "  -> Backed up to $BACKUP"

      # Use node/python to merge if available, otherwise template
      if command -v node &>/dev/null; then
        node -e "
const fs = require('fs');
const existing = JSON.parse(fs.readFileSync('$SETTINGS_FILE', 'utf8'));
const patch = JSON.parse(fs.readFileSync('$HOOKS_PATCH', 'utf8'));

existing.hooks = existing.hooks || {};
for (const [event, hookList] of Object.entries(patch.hooks)) {
  existing.hooks[event] = existing.hooks[event] || [];
  // Avoid duplicates
  const cmds = new Set(existing.hooks[event].map(h => h.hooks?.[0]?.command));
  for (const entry of hookList) {
    if (!cmds.has(entry.hooks[0].command)) {
      existing.hooks[event].push(entry);
    }
  }
}

existing.permissions = existing.permissions || {};
existing.permissions.allow = existing.permissions.allow || [];
const newPerms = patch.permissions.allow;
for (const p of newPerms) {
  if (!existing.permissions.allow.includes(p)) {
    existing.permissions.allow.push(p);
  }
}

fs.writeFileSync('$SETTINGS_FILE', JSON.stringify(existing, null, 2) + '\n');
" && echo "  -> Merged hooks into settings.json" || echo "  -> Merge failed, check manually"
      else
        cp "$SCRIPT_DIR/settings-template.json" "$SETTINGS_FILE"
        echo "  -> Replaced with template (node not available for merge)"
      fi
    fi
  fi
fi

# 4. Create timing directory
mkdir -p "$CLAUDE_DIR/timing"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Usage:"
echo "  In Claude Code, type: /estimate"
echo "  Or: /estimate <task description>"
echo ""
echo "Timing data will be collected in: $CLAUDE_DIR/timing/timing.log"
