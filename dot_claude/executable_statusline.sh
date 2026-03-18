#!/bin/bash

# Claude Code Status Line
# Reads JSON input from stdin and displays contextual information

input=$(cat)

# Parse all fields in a single jq call
IFS=$'\t' read -r model_name current_dir project_dir output_style <<< "$(
  echo "$input" | jq -r '[
    (.model.display_name // "Claude"),
    (.workspace.current_dir // ""),
    (.workspace.project_dir // ""),
    (.output_style.name // "")
  ] | @tsv'
)"

# Get current provider name from URL
PROVIDER="${ANTHROPIC_BASE_URL:-}"
if [[ -n "$PROVIDER" ]]; then
  DOMAIN=$(echo "$PROVIDER" | sed 's|https://||;s|/.*||;s|^www\.||')
  PROVIDER_NAME=$(echo "$DOMAIN" | awk -F. '{print (NF>=2) ? $(NF-1) : $1}')
else
  PROVIDER_NAME="unknown"
fi

# Build display directory
if [[ -n "$project_dir" ]]; then
  project_name=$(basename "$project_dir")
  normalized_project="${project_dir%/}"
  normalized_current="${current_dir%/}"

  if [[ "$normalized_current" != "$normalized_project" && "$normalized_current" == "$normalized_project"/* ]]; then
    relative_path="${normalized_current#$normalized_project/}"
    depth=$(echo "$relative_path" | tr '/' '\n' | wc -l)
    if [[ $depth -gt 2 ]]; then
      first_dir=$(echo "$relative_path" | cut -d'/' -f1)
      last_dir=$(basename "$relative_path")
      display_dir="$project_name/$first_dir/.../$last_dir"
    else
      display_dir="$project_name/$relative_path"
    fi
  else
    display_dir="$project_name"
  fi
else
  display_dir=$(basename "$current_dir")
fi

# Get all git info using a single git status call
git_info=""
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || echo "HEAD")

  git_flags=""
  git_status_output=$(git -C "$current_dir" status --porcelain 2>/dev/null)
  [[ -n "$(echo "$git_status_output" | grep -v "^??")" ]] && git_flags=" *"
  echo "$git_status_output" | grep -q "^??" && git_flags="${git_flags}?"
  git -C "$current_dir" rev-parse --verify refs/stash >/dev/null 2>&1 && git_flags="${git_flags} S"

  git_info=" on   $branch$git_flags"
fi

# Output style indicator
style_indicator=""
[[ "$output_style" != "default" && -n "$output_style" ]] && style_indicator=" [$output_style]"

# Usage quota — only for official Claude API (skip if using external provider)
usage_str=""
if [[ -z "${ANTHROPIC_BASE_URL:-}" ]]; then
  USAGE_CACHE="/tmp/claude-statusline-usage.json"

  # Color based on remaining: red < 10%, yellow 10–30%, gray ≥ 30%
  _usage_color() {
    local rem=$1
    if   [[ $rem -lt 10 ]]; then printf '\033[31m'  # red
    elif [[ $rem -lt 30 ]]; then printf '\033[33m'  # yellow
    else                         printf '\033[90m'  # gray
    fi
  }

  _cache_fresh=false
  if [[ -f "$USAGE_CACHE" ]]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$USAGE_CACHE" 2>/dev/null || echo 0) ))
    [[ $cache_age -lt 60 ]] && _cache_fresh=true
  fi

  if [[ "$_cache_fresh" == "false" ]]; then
    blob=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    token=$(echo "$blob" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
    if [[ -n "$token" ]]; then
      curl -s --max-time 5 \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        "https://api.anthropic.com/api/oauth/usage" > "$USAGE_CACHE" 2>/dev/null
    fi
  fi

  if [[ -f "$USAGE_CACHE" ]]; then
    IFS=$'\t' read -r five_used seven_used <<< "$(
      jq -r '[
        (.five_hour.utilization  // -1 | floor | tostring),
        (.seven_day.utilization  // -1 | floor | tostring)
      ] | @tsv' "$USAGE_CACHE" 2>/dev/null
    )"
    usage_parts=""
    if [[ "$five_used" -ge 0 ]] 2>/dev/null; then
      five_rem=$(( 100 - five_used ))
      c=$(_usage_color "$five_rem")
      usage_parts+="\033[90m5h \033[0m${c}${five_rem}%\033[0m"
    fi
    if [[ "$seven_used" -ge 0 ]] 2>/dev/null; then
      [[ -n "$usage_parts" ]] && usage_parts+="\033[90m · \033[0m"
      seven_rem=$(( 100 - seven_used ))
      c=$(_usage_color "$seven_rem")
      usage_parts+="\033[90m7d \033[0m${c}${seven_rem}%\033[0m"
    fi
    [[ -n "$usage_parts" ]] && usage_str="\033[90m · \033[0m${usage_parts}"
  fi
fi

printf "\033[36m%s\033[0m\033[90m in %s\033[0m\033[32m%s\033[0m\033[34m%s\033[0m%b" \
  "$model_name" \
  "$display_dir" \
  "$git_info" \
  "$style_indicator" \
  "$usage_str"
