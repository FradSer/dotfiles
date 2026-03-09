#!/bin/bash

# Claude Code Status Line - inspired by Starship configuration
# Reads JSON input from stdin and displays contextual information

input=$(cat)

# Extract information from JSON input
model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // ""')
project_dir=$(echo "$input" | jq -r '.workspace.project_dir // ""')
output_style=$(echo "$input" | jq -r '.output_style.name // ""')

# Get current provider
PROVIDER="${ANTHROPIC_BASE_URL:-none}"

# Extract provider name from URL
if [[ "$PROVIDER" != "none" && -n "$PROVIDER" ]]; then
  # Extract domain from URL and remove www prefix and API path
  DOMAIN=$(echo "$PROVIDER" | sed 's|https://||' | sed 's|/.*||' | sed 's|^www\.||' | head -1)

  if [[ -n "$DOMAIN" ]]; then
    # Extract main domain name (second-level domain)
    PROVIDER_NAME=$(echo "$DOMAIN" | awk -F. '{if (NF>=2) print $(NF-1); else print $1}')
  else
    # Fallback: extract from path
    PROVIDER_NAME=$(echo "$PROVIDER" | sed 's|.*/||')
  fi
else
  PROVIDER_NAME="unknown"
fi

# Display project directory with optional subdirectory path
if [[ -n "$project_dir" ]]; then
    project_name=$(basename "$project_dir")

    # Normalize paths
    normalized_project="${project_dir%/}"
    normalized_current="${current_dir%/}"

    # Check if we're in a subdirectory
    if [[ "$normalized_current" != "$normalized_project" && "$normalized_current" == "$normalized_project"/* ]]; then
        relative_path="${normalized_current#$normalized_project/}"

        # If path is deep (more than 2 levels), abbreviate with ...
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

# Get git information (skip locks to avoid blocking)
git_info=""
if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    # Get branch name
    branch=$(git -C "$current_dir" branch --show-current 2>/dev/null || echo "HEAD")

    # Get git status (abbreviated)
    git_status=""
    if ! git -C "$current_dir" diff-index --quiet HEAD -- 2>/dev/null; then
        git_status=" *"
    fi

    # Check for untracked files
    if [[ -n $(git -C "$current_dir" ls-files --others --exclude-standard 2>/dev/null) ]]; then
        git_status="${git_status}?"
    fi

    # Check for stashed changes
    if git -C "$current_dir" rev-parse --verify refs/stash >/dev/null 2>&1; then
        git_status="${git_status} S"
    fi

    git_info=" on   $branch$git_status"
fi

# Show output style if it's not the default
style_indicator=""
if [[ "$output_style" != "default" && -n "$output_style" ]]; then
    style_indicator=" [$output_style]"
fi

# Build the status line using printf for colors
printf "\033[36m%s\033[0m\033[90m in %s\033[0m\033[32m%s\033[0m\033[34m%s\033[0m" \
    "$model_name" \
    "$display_dir" \
    "$git_info" \
    "$style_indicator"
