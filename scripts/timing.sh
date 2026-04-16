#!/bin/bash
# Claude Code Timing Logger
# Usage: timing.sh <event_type>
# Events: pre_tool, post_tool, prompt_start, response_end

EVENT_TYPE="$1"
TIMING_DIR="$HOME/.claude/timing"
mkdir -p "$TIMING_DIR"

INPUT=$(cat)
NOW=$(date +%s%3N)  # milliseconds

# Extract tool_name from JSON without jq
extract_tool_name() {
  echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tool_name"[[:space:]]*:[[:space:]]*"//;s/"//'
}

case "$EVENT_TYPE" in
  pre_tool)
    TOOL_NAME=$(extract_tool_name)
    echo "${NOW}|${TOOL_NAME}" > "$TIMING_DIR/.current_tool"
    ;;

  post_tool)
    TOOL_NAME=$(extract_tool_name)
    if [ -f "$TIMING_DIR/.current_tool" ]; then
      IFS='|' read -r START_TIME START_TOOL < "$TIMING_DIR/.current_tool"
      DURATION=$((NOW - START_TIME))
      # Format: timestamp|type|name|duration_ms
      echo "${NOW}|tool|${TOOL_NAME}|${DURATION}" >> "$TIMING_DIR/timing.log"
      rm -f "$TIMING_DIR/.current_tool"
    fi
    ;;

  prompt_start)
    echo "${NOW}" > "$TIMING_DIR/.current_response"
    # Count tool calls for this response
    echo "0" > "$TIMING_DIR/.tool_count"
    ;;

  response_end)
    if [ -f "$TIMING_DIR/.current_response" ]; then
      START_TIME=$(cat "$TIMING_DIR/.current_response")
      DURATION=$((NOW - START_TIME))
      TOOL_COUNT=0
      if [ -f "$TIMING_DIR/.tool_count" ]; then
        TOOL_COUNT=$(cat "$TIMING_DIR/.tool_count")
        rm -f "$TIMING_DIR/.tool_count"
      fi
      echo "${NOW}|response|tools:${TOOL_COUNT}|${DURATION}" >> "$TIMING_DIR/timing.log"
      rm -f "$TIMING_DIR/.current_response"
    fi
    ;;
esac

# Increment tool counter on post_tool
if [ "$EVENT_TYPE" = "post_tool" ] && [ -f "$TIMING_DIR/.tool_count" ]; then
  COUNT=$(cat "$TIMING_DIR/.tool_count")
  echo $((COUNT + 1)) > "$TIMING_DIR/.tool_count"
fi
