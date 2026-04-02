#!/usr/bin/env bash
# Claude Code status line script
# Reads JSON from stdin and outputs a compact status line

input=$(cat)

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# --- Context window usage ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct" | awk '{printf "%d", int($1 / 10 + 0.5)}')
  bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then
      bar="${bar}▓"
    else
      bar="${bar}░"
    fi
  done
  ctx_str="$(printf '%.0f' "$used_pct")% [${bar}]"
else
  ctx_str="--"
fi

# --- Rate limit: 5-hour ---
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
if [ -n "$five_pct" ]; then
  rl_str="5h:$(printf '%.0f' "$five_pct")%"
else
  rl_str=""
fi

# --- Total session cost (direct from API) ---
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
  cost_str="\$$(printf '%.4f' "$cost")"
else
  cost_str=""
fi

# --- Assemble output ---
parts="${model}  ctx:${ctx_str}"
[ -n "$rl_str" ] && parts="${parts}  ${rl_str}"
[ -n "$cost_str" ] && parts="${parts}  ${cost_str}"

printf "%s" "$parts"
