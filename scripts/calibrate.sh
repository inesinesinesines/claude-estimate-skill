#!/bin/bash
# Claude Code Timing Calibration
# Reads timing.log and generates calibration.json with measured averages
# Usage: calibrate.sh [--output PATH]
#
# Output: ~/.claude/timing/calibration.json

TIMING_LOG="$HOME/.claude/timing/timing.log"
OUTPUT="$HOME/.claude/timing/calibration.json"

# Parse --output flag
while [[ $# -gt 0 ]]; do
  case "$1" in
    --output) OUTPUT="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ ! -f "$TIMING_LOG" ] || [ ! -s "$TIMING_LOG" ]; then
  echo '{"error":"no_data","message":"timing.log is empty or missing. Need 20+ tool calls."}' > "$OUTPUT"
  echo "No timing data found. Run some Claude Code sessions first."
  exit 0
fi

# Count total tool entries
TOTAL_TOOLS=$(grep -c '|tool|' "$TIMING_LOG")
TOTAL_RESPONSES=$(grep -c '|response|' "$TIMING_LOG")

if [ "$TOTAL_TOOLS" -lt 5 ]; then
  echo "{\"error\":\"insufficient_data\",\"tool_count\":$TOTAL_TOOLS,\"message\":\"Need at least 20 tool calls for reliable calibration.\"}" > "$OUTPUT"
  echo "Only $TOTAL_TOOLS tool calls recorded. Need at least 20 for reliable calibration."
  exit 0
fi

# ── 1. Tool averages ──
TOOL_AVG=$(grep '|tool|' "$TIMING_LOG" | awk -F'|' '{
  tool=$3; dur=$4
  count[tool]++; total[tool]+=dur
  if (!(tool in mn) || dur < mn[tool]) mn[tool]=dur
  if (dur > mx[tool]) mx[tool]=dur
}
END {
  first=1
  for (t in count) {
    if (!first) printf ","
    avg = total[t] / count[t]
    printf "\"%s\":{\"avg_ms\":%.0f,\"min_ms\":%d,\"max_ms\":%d,\"count\":%d}", t, avg, mn[t], mx[t], count[t]
    first=0
  }
}')

# ── 2. Gap analysis (thinking time between tools) ──
# Gap = next_tool_start - current_tool_end
# tool_start = timestamp - duration, tool_end = timestamp
GAP_ANALYSIS=$(grep '|tool|' "$TIMING_LOG" | awk -F'|' '
{
  ts=$1; tool=$3; dur=$4
  tool_start = ts - dur
  tool_end = ts

  if (prev_end > 0 && tool_start > prev_end) {
    gap = tool_start - prev_end

    # Skip unreasonably large gaps (>120s = likely new session/response boundary)
    if (gap < 120000) {
      # Classify: same tool repeated vs different tool
      if (tool == prev_tool) {
        same_count++; same_total += gap
        if (same_count==1 || gap < same_min) same_min=gap
        if (gap > same_max) same_max=gap
      } else {
        diff_count++; diff_total += gap
        if (diff_count==1 || gap < diff_min) diff_min=gap
        if (gap > diff_max) diff_max=gap
      }
      # Overall
      all_count++; all_total += gap
    }
  }

  prev_end = tool_end
  prev_tool = tool
}
END {
  # Same-tool gaps (includes both simple repeat and analytical sequential)
  same_avg = (same_count > 0) ? same_total / same_count : 0
  diff_avg = (diff_count > 0) ? diff_total / diff_count : 0
  all_avg  = (all_count > 0)  ? all_total / all_count   : 0

  printf "\"same_tool\":{\"avg_ms\":%.0f,\"min_ms\":%d,\"max_ms\":%d,\"count\":%d},", same_avg, same_min, same_max, same_count
  printf "\"diff_tool\":{\"avg_ms\":%.0f,\"min_ms\":%d,\"max_ms\":%d,\"count\":%d},", diff_avg, diff_min, diff_max, diff_count
  printf "\"overall\":{\"avg_ms\":%.0f,\"count\":%d}", all_avg, all_count
}')

# ── 3. Gap histogram (for thinking time distribution) ──
GAP_HISTOGRAM=$(grep '|tool|' "$TIMING_LOG" | awk -F'|' '
{
  ts=$1; dur=$4
  tool_start = ts - dur

  if (prev_end > 0 && tool_start > prev_end) {
    gap_s = (tool_start - prev_end) / 1000
    if (gap_s < 120) {
      if (gap_s < 1) b0++
      else if (gap_s < 3) b1++
      else if (gap_s < 5) b2++
      else if (gap_s < 10) b3++
      else if (gap_s < 20) b4++
      else if (gap_s < 50) b5++
      else b6++
    }
  }
  prev_end = ts
}
END {
  printf "\"0-1s\":%d,\"1-3s\":%d,\"3-5s\":%d,\"5-10s\":%d,\"10-20s\":%d,\"20-50s\":%d,\"50s+\":%d", b0+0, b1+0, b2+0, b3+0, b4+0, b5+0, b6+0
}')

# ── 4. Response averages ──
RESPONSE_AVG=$(grep '|response|' "$TIMING_LOG" | awk -F'|' '{
  dur=$4; split($3, a, ":"); tools=a[2]
  count++; total_dur+=dur; total_tools+=tools
}
END {
  if (count > 0) {
    printf "\"avg_duration_ms\":%.0f,\"avg_tools_per_response\":%.1f,\"count\":%d", total_dur/count, total_tools/count, count
  } else {
    printf "\"count\":0"
  }
}')

# ── 5. Metadata ──
FIRST_TS=$(head -1 "$TIMING_LOG" | cut -d'|' -f1)
LAST_TS=$(tail -1 "$TIMING_LOG" | cut -d'|' -f1)
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date +"%Y-%m-%dT%H:%M:%SZ")

# ── Assemble JSON ──
cat > "$OUTPUT" << ENDJSON
{
  "calibration_version": 1,
  "generated_at": "$NOW",
  "data_range": {
    "first_entry_ms": $FIRST_TS,
    "last_entry_ms": $LAST_TS
  },
  "sample_count": {
    "tools": $TOTAL_TOOLS,
    "responses": $TOTAL_RESPONSES
  },
  "tool_avg": {$TOOL_AVG},
  "gap": {$GAP_ANALYSIS},
  "gap_histogram": {$GAP_HISTOGRAM},
  "response_avg": {$RESPONSE_AVG}
}
ENDJSON

echo "Calibration saved to $OUTPUT ($TOTAL_TOOLS tool calls, $TOTAL_RESPONSES responses)"
