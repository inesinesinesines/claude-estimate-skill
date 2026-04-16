#!/bin/bash
# Claude Estimate Skill - Uninstaller

set -e

CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Estimate Skill Uninstaller ==="
echo ""

# Remove scripts
rm -f "$CLAUDE_DIR/scripts/timing.sh"
rm -f "$CLAUDE_DIR/scripts/timing-stats.sh"
echo "[1/3] Removed timing scripts"

# Remove skill
rm -rf "$CLAUDE_DIR/skills/estimate"
echo "[2/3] Removed skill definition"

# Note about settings.json
echo "[3/3] Hooks in settings.json must be removed manually."
echo "  Edit: $CLAUDE_DIR/settings.json"
echo "  Remove all entries containing 'timing.sh'"

# Ask about timing data
echo ""
read -p "Delete timing data (~/.claude/timing/)? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  rm -rf "$CLAUDE_DIR/timing"
  echo "  -> Timing data deleted"
else
  echo "  -> Timing data preserved at $CLAUDE_DIR/timing/"
fi

echo ""
echo "=== Uninstall complete ==="
