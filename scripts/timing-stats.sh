#!/bin/bash
# Claude Code Timing Statistics
# Reads timing.log and outputs statistics in a parseable format

TIMING_LOG="$HOME/.claude/timing/timing.log"

if [ ! -f "$TIMING_LOG" ] || [ ! -s "$TIMING_LOG" ]; then
  echo "NO_DATA"
  exit 0
fi

echo "=== TOOL STATISTICS ==="
# Extract tool entries, group by tool name, calculate stats
grep '|tool|' "$TIMING_LOG" | awk -F'|' '{
  tool=$3
  dur=$4
  count[tool]++
  total[tool]+=dur
  if (!(tool in min_val) || dur < min_val[tool]) min_val[tool]=dur
  if (dur > max_val[tool]) max_val[tool]=dur
}
END {
  for (t in count) {
    avg = total[t] / count[t]
    printf "%s|%d|%.0f|%d|%d\n", t, count[t], avg, min_val[t], max_val[t]
  }
}' | sort -t'|' -k2 -nr

echo "=== RESPONSE STATISTICS ==="
# Extract response entries
grep '|response|' "$TIMING_LOG" | awk -F'|' '{
  dur=$4
  split($3, a, ":")
  tools=a[2]
  count++
  total_dur+=dur
  total_tools+=tools
  if (count==1 || dur < min_dur) min_dur=dur
  if (dur > max_dur) max_dur=dur
}
END {
  if (count > 0) {
    printf "count:%d|avg_dur:%.0f|min_dur:%d|max_dur:%d|avg_tools:%.1f\n", count, total_dur/count, min_dur, max_dur, total_tools/count
  }
}'

echo "=== RECENT (LAST 20) ==="
tail -20 "$TIMING_LOG"

echo "=== TOTAL ENTRIES ==="
wc -l < "$TIMING_LOG"
