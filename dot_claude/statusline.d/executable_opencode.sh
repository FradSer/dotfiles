#!/bin/bash
# OpenCode Go statusline plugin
# Reads the same Claude Code statusline JSON from stdin. When the session uses
# an opencode model, prints the OpenCode Go subscription usage segment (with a
# leading " · " separator); otherwise prints nothing.
#
# Primary source is CodexBarCLI, which reads the opencode.ai session cookie from
# Chrome directly (mirroring CodexBar's OpenCodeGoUsageFetcher web path). Real
# usagePercent/resetInSec only exist in the opencode.ai console; the API key does
# not expose them. Falls back to a local opencode DB cost estimate (limits
# $12/5h, $30/wk, $60/mo) when the CLI is unavailable or fails.
#
# Self-contained: owns its cache, lock, and color helpers. Silent on failure —
# a statusline must never print noise.

input=$(cat)

# Detect OpenCode-backed sessions (e.g. "opencode/deepseek-v4-flash[1m]")
IFS=$'\x1f' read -r _oc_model_id _oc_model_name <<< "$(
  echo "$input" | jq -r '[
    (.model.id // ""),
    (.model.display_name // "")
  ] | join("")'
)"
_is_opencode=false
case "$_oc_model_id $_oc_model_name" in
  *opencode*) _is_opencode=true ;;
esac
[[ "$_is_opencode" == "true" ]] || exit 0

# Color based on remaining: red < 10%, yellow 10-30%, gray >= 30%
# (same scheme as the Claude usage block in statusline.sh)
_usage_color() {
  local rem=$1
  if   [[ $rem -lt 10 ]]; then printf '\033[31m'  # red
  elif [[ $rem -lt 30 ]]; then printf '\033[33m'  # yellow
  else                         printf '\033[90m'  # gray
  fi
}

# Single largest unit, round-half-up, promoting on overflow so boundary
# artifacts like 60m / 24h never surface (e.g. 59m30s -> 1h, 6d12h -> 7d).
_countdown_secs() {
  local secs_left=$1
  if [[ $secs_left -le 60 ]]; then
    echo "now"
  else
    local mins=$(( (secs_left + 30) / 60 ))
    local hrs=$(( (secs_left + 1800) / 3600 ))
    if   [[ $mins -lt 60 ]]; then echo "${mins}m"
    elif [[ $hrs  -lt 24 ]]; then echo "${hrs}h"
    else                          echo "$(( (secs_left + 43200) / 86400 ))d"
    fi
  fi
}

OC_DB="$HOME/.local/share/opencode/opencode.db"
OC_CACHE="/tmp/claude-statusline-opencode-usage.tsv"
OC_LOCK="/tmp/claude-statusline-opencode-usage.lock"
OC_CACHE_MAX_AGE=60

OC_CB="${CODEXBAR_CLI:-/Applications/CodexBar.app/Contents/Helpers/CodexBarCLI}"
OC_CB_CACHE="/tmp/claude-statusline-opencode-cb.tsv"
OC_CB_LOCK="/tmp/claude-statusline-opencode-cb.lock"
OC_CB_CACHE_MAX_AGE=300
OC_SOURCE=""

# ---- primary: CodexBarCLI (reads Chrome cookies for opencode.ai) ----
if [[ -x "$OC_CB" ]]; then
  _cb_fresh=false
  if [[ -f "$OC_CB_CACHE" ]]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$OC_CB_CACHE" 2>/dev/null || echo 0) ))
    [[ $cache_age -lt $OC_CB_CACHE_MAX_AGE ]] && _cb_fresh=true
  fi
  if [[ "$_cb_fresh" == "false" ]]; then
    _lock_stale=true
    if [[ -f "$OC_CB_LOCK" ]]; then
      lock_age=$(( $(date +%s) - $(stat -f %m "$OC_CB_LOCK" 2>/dev/null || echo 0) ))
      [[ $lock_age -lt 30 ]] && _lock_stale=false
    fi
    if [[ "$_lock_stale" == "true" ]]; then
      touch "$OC_CB_LOCK"
      # Run codexbar (Chrome cookies read internally; cookie never in argv),
      # parse primary/secondary/tertiary -> remaining% + reset seconds, and
      # write the shared TSV atomically. Exit nonzero on any failure.
      python3 -c '
import json, subprocess, sys, datetime, os

cb = "/Applications/CodexBar.app/Contents/Helpers/CodexBarCLI"
try:
    r = subprocess.run(
        [cb, "usage", "--provider", "opencodego", "--json", "--no-color", "--web-timeout", "8"],
        capture_output=True, text=True, timeout=15)
    d = json.loads(r.stdout)[0]["usage"]
except Exception:
    sys.exit(1)

out = []
for win, key in (("5h", "primary"), ("7d", "secondary"), ("22d", "tertiary")):
    w = d.get(key)
    if not w:
        continue
    up = w.get("usedPercent")
    if not isinstance(up, (int, float)):
        continue
    rem = max(0, min(100, round(100 - up)))
    reset = 0
    ra = w.get("resetsAt")
    if ra:
        try:
            t = datetime.datetime.fromisoformat(ra.replace("Z", "+00:00"))
            now = datetime.datetime.now(datetime.timezone.utc)
            reset = max(0, int((t - now).total_seconds()))
        except Exception:
            pass
    out.append("%s\t%d\t%d" % (win, rem, reset))
if len(out) < 2:
    sys.exit(1)
sys.stdout.write("\n".join(out) + "\n")
' > "$OC_CB_CACHE.tmp" 2>/dev/null
      if [[ -s "$OC_CB_CACHE.tmp" ]]; then
        mv "$OC_CB_CACHE.tmp" "$OC_CB_CACHE"
      else
        rm -f "$OC_CB_CACHE.tmp"
      fi
    fi
  fi
  [[ -s "$OC_CB_CACHE" ]] && OC_SOURCE="$OC_CB_CACHE"
fi

# ---- fallback: local-DB estimate (no CLI, or CLI failed) ----
if [[ -z "$OC_SOURCE" && -f "$OC_DB" ]]; then
  # Check if cache is fresh
  _cache_fresh=false
  if [[ -f "$OC_CACHE" ]]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$OC_CACHE" 2>/dev/null || echo 0) ))
    [[ $cache_age -lt $OC_CACHE_MAX_AGE ]] && _cache_fresh=true
  fi

  # Recompute only if cache is stale and not locked
  if [[ "$_cache_fresh" == "false" ]]; then
    _lock_stale=true
    if [[ -f "$OC_LOCK" ]]; then
      lock_age=$(( $(date +%s) - $(stat -f %m "$OC_LOCK" 2>/dev/null || echo 0) ))
      [[ $lock_age -lt 30 ]] && _lock_stale=false
    fi

    if [[ "$_lock_stale" == "true" ]]; then
      touch "$OC_LOCK"

      # Window boundaries (UTC): 5h rolling, Mon 00:00 week, calendar month
      _now_s=$(date +%s)
      _now_ms=$(( _now_s * 1000 ))
      _five_ms=$(( 5 * 3600 * 1000 ))
      _wd=$(date -u +%u)  # 1=Monday
      _week_start_ms=$(( $(date -u -v-$((_wd - 1))d -v0H -v0M -v0S +%s) * 1000 ))
      _week_end_ms=$(( _week_start_ms + 7 * 24 * 3600 * 1000 ))
      _month_start_ms=$(( $(date -u -v1d -v0H -v0M -v0S +%s) * 1000 ))
      _month_end_ms=$(( $(date -u -v+1m -v1d -v0H -v0M -v0S +%s) * 1000 ))

      # Sum assistant-message costs per window, preferring step-finish part
      # costs (CodexBar's query shape). Free models carry cost 0 and never
      # inflate the dollar usage.
      if sqlite3 "file:$OC_DB?mode=ro" "PRAGMA busy_timeout=250;
WITH provider_messages AS (
  SELECT
    id AS messageID,
    CAST(COALESCE(json_extract(data, '\$.time.created'), time_created) AS INTEGER) AS createdMs,
    CAST(json_extract(data, '\$.cost') AS REAL) AS cost,
    json_type(data, '\$.cost') IN ('integer', 'real') AS hasCost,
    COALESCE(json_extract(data, '\$.modelID'), '') AS modelID
  FROM message
  WHERE json_valid(data)
    AND json_extract(data, '\$.providerID') IN ('opencode-go', 'opencode')
    AND json_extract(data, '\$.role') = 'assistant'
)
SELECT
  CAST(COALESCE(json_extract(p.data, '\$.time.created'), p.time_created, m.createdMs) AS INTEGER) AS createdMs,
  CAST(json_extract(p.data, '\$.cost') AS REAL) AS cost,
  m.modelID AS modelID
FROM part p
JOIN provider_messages m ON m.messageID = p.message_id
WHERE json_valid(p.data)
  AND json_extract(p.data, '\$.type') = 'step-finish'
  AND json_type(p.data, '\$.cost') IN ('integer', 'real')
UNION ALL
SELECT createdMs, cost, modelID
FROM provider_messages m
WHERE hasCost
  AND NOT EXISTS (
    SELECT 1 FROM part p
    WHERE p.message_id = m.messageID
      AND json_valid(p.data)
      AND json_extract(p.data, '\$.type') = 'step-finish'
      AND json_type(p.data, '\$.cost') IN ('integer', 'real')
  );" > "$OC_CACHE.rows" 2>/dev/null && [[ -s "$OC_CACHE.rows" ]]; then
        awk -v now="$_now_ms" -v fivems="$_five_ms" \
            -v ws="$_week_start_ms" -v we="$_week_end_ms" \
            -v ms_="$_month_start_ms" -v me="$_month_end_ms" '
function pct(used, limit, r) {
  r = 100 - used / limit * 100
  if (r < 0) r = 0
  if (r > 100) r = 100
  return int(r + 0.5)
}
{
  ms = $1; cost = $2
  if (ms >= now - fivems && ms < now) {
    ssum += cost
    if (oldest == 0 || ms < oldest) oldest = ms
  }
  if (ms >= ws && ms < we) wsum += cost
  if (ms >= ms_ && ms < me) msum += cost
}
END {
  if (oldest == 0) oldest = now
  sreset = (oldest + fivems - now) / 1000; if (sreset < 0) sreset = 0
  wreset = (we - now) / 1000; if (wreset < 0) wreset = 0
  mreset = (me - now) / 1000; if (mreset < 0) mreset = 0
  printf "5h\t%d\t%d\n", pct(ssum, 12), sreset
  printf "7d\t%d\t%d\n", pct(wsum, 30), wreset
  printf "mo\t%d\t%d\n", pct(msum, 60), mreset
}
' "$OC_CACHE.rows" > "$OC_CACHE.tmp"
        mv "$OC_CACHE.tmp" "$OC_CACHE"
      fi
      rm -f "$OC_CACHE.rows" "$OC_CACHE.tmp"
    fi
  fi

  # Render cached windows (display latest available, never a placeholder)
  [[ -s "$OC_CACHE" ]] && OC_SOURCE="$OC_CACHE"
fi

# ---- render: remaining% with countdown label + Claude-style color ----
oc_parts=""
if [[ -n "$OC_SOURCE" && -f "$OC_SOURCE" ]]; then
  while IFS=$'\t' read -r _win _rem _reset; do
    [[ -z "$_rem" ]] && continue
    c=$(_usage_color "$_rem")
    label=$(_countdown_secs "$_reset")
    [[ -n "$oc_parts" ]] && oc_parts+="\033[90m · \033[0m"
    oc_parts+="\033[90m${label} \033[0m${c}${_rem}%\033[0m"
  done < "$OC_SOURCE"
fi

[[ -n "$oc_parts" ]] && printf '\033[90m · \033[0m%b' "$oc_parts"
exit 0
