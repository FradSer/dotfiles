#!/bin/bash
# Directory display plugin for the Claude Code statusline.
# Reads the same statusline JSON from stdin and prints the "display_dir" only.
#
# Handles git worktrees specially: when the session lives in a linked worktree
# (e.g. <repo>/.claude/worktrees/marketing), the main repo name would be lost
# (project_dir basename is just "marketing"). Show "repo/.../worktree" so the
# project is always identifiable:
#   main checkout:        in codeterrier
#   worktree root:        in codeterrier/.../marketing
#   worktree subdir:      in codeterrier/.../marketing/src/components
# Non-worktree paths fall back to the standard depth-based ellipsis.

input=$(cat)

IFS=$'\x1f' read -r current_dir project_dir git_worktree <<< "$(
  echo "$input" | jq -r '[
    (.workspace.current_dir // ""),
    (.workspace.project_dir // ""),
    (.workspace.git_worktree // "")
  ] | join("")'
)"

if [[ -z "$project_dir" ]]; then
  echo "$(basename "$current_dir")"
  exit 0
fi

project_name=$(basename "$project_dir")

# ---- git worktree detection ----
# project_dir is the launch directory (always exists). When it lives under a
# "<repo>/.claude/worktrees/<name>" layout, it IS the worktree root, so its
# basename is the worktree name and the main checkout is the common-dir parent.
_is_worktree=false
_worktree_name=""
_main_top=""
if [[ "$project_dir" == *"/.claude/worktrees/"* ]]; then
  # Even if the worktree dir was deleted, the main checkout path is derivable
  # from the worktree path structure: <main>/.claude/worktrees/<name>.
  _is_worktree=true
  _worktree_name=$(basename "$project_dir")
  _main_top="${project_dir%%/.claude/worktrees/*}"
  if [[ -n "$_main_top" ]]; then
    project_name=$(basename "$_main_top")
  fi
  # Confirm via git when the directory still exists; fall back to the derived
  # name otherwise (deleted worktree keeps the correct project name).
  if [[ -d "$project_dir" ]]; then
    _common=$(git -C "$project_dir" rev-parse --git-common-dir 2>/dev/null)
    if [[ -n "$_common" ]]; then
      _main_top=$(cd "$(dirname "$_common")" && pwd 2>/dev/null)
      [[ -n "$_main_top" ]] && project_name=$(basename "$_main_top")
    fi
  fi
elif [[ -d "$current_dir" ]]; then
  # current_dir may sit in a worktree even when project_dir is the main checkout;
  # detect via git-dir containing "worktrees" (works for any depth, only needs a
  # real directory).
  if git -C "$current_dir" rev-parse --git-dir >/dev/null 2>&1; then
    _git_dir=$(git -C "$current_dir" rev-parse --git-dir 2>/dev/null)
    if [[ "$_git_dir" == *worktrees* ]]; then
      _is_worktree=true
      _worktree_name=$(basename "$_git_dir")
      _common=$(git -C "$current_dir" rev-parse --git-common-dir 2>/dev/null)
      if [[ -n "$_common" ]]; then
        _main_top=$(cd "$(dirname "$_common")" && pwd 2>/dev/null)
        if [[ -n "$_main_top" ]]; then
          project_name=$(basename "$_main_top")
        fi
      fi
    fi
  fi
fi

normalized_project="${project_dir%/}"
normalized_current="${current_dir%/}"

# ---- worktree: always show main repo + /.../ + worktree name ----
if [[ "$_is_worktree" == "true" && -n "$_worktree_name" ]]; then
  # Worktree root is either project_dir (when it's the worktree) or the matching
  # worktree row from `git worktree list` (when only current_dir is inside one).
  # Only trust it if the directory actually exists (a deleted worktree should
  # fall through to the standard path below, not render "name/.../name").
  _wt_root=""
  if [[ "$project_dir" == *"/.claude/worktrees/"* && -d "$project_dir" ]]; then
    _wt_root="$normalized_project"
  else
    while IFS= read -r _wt_line; do
      _wt_path="${_wt_line#worktree }"
      [[ "$_wt_path" != *"/worktrees/"* ]] && continue
      if [[ "$normalized_current" == "$_wt_path" || "$normalized_current" == "$_wt_path"/* ]]; then
        _wt_root="$_wt_path"
        break
      fi
    done < <(git -C "$current_dir" worktree list --porcelain 2>/dev/null | grep '^worktree ')
  fi
  # If the resolved worktree root doesn't exist, don't attempt worktree display
  if [[ -z "$_wt_root" || ! -d "$_wt_root" ]]; then
    _is_worktree=false
    _worktree_name=""
  fi
fi

# ---- standard path (non-worktree) ----
if [[ "$_is_worktree" != "true" ]]; then
  # Anchor to the git repo root when project_dir is a deep subdirectory (e.g.
  # agent cwd deep in a repo). This keeps the project name identifiable instead
  # of showing only the launch dir's basename.
  _repo_top=""
  if [[ -d "$project_dir" ]]; then
    _repo_top=$(git -C "$project_dir" rev-parse --show-toplevel 2>/dev/null)
  fi

  if [[ -n "$_repo_top" ]]; then
    _proj_name=$(basename "$_repo_top")
    # project_dir relative to repo root (empty when project_dir IS the root)
    base_rel="${normalized_project#$_repo_top/}"
    [[ "$base_rel" == "$normalized_project" ]] && base_rel=""
  else
    _proj_name="$project_name"
    base_rel=""
  fi

  # Prefix = project name + optional project_dir-relative segment
  prefix="$_proj_name"
  if [[ -n "$base_rel" ]]; then
    depth=$(echo "$base_rel" | tr '/' '\n' | wc -l)
    if [[ $depth -gt 2 ]]; then
      first_dir=$(echo "$base_rel" | cut -d'/' -f1)
      last_dir=$(basename "$base_rel")
      prefix="$_proj_name/$first_dir/.../$last_dir"
    else
      prefix="$_proj_name/$base_rel"
    fi
  fi

  if [[ "$normalized_current" != "$normalized_project" && "$normalized_current" == "$normalized_project"/* ]]; then
    relative_path="${normalized_current#$normalized_project/}"
    depth=$(echo "$relative_path" | tr '/' '\n' | wc -l)
    if [[ $depth -gt 2 ]]; then
      first_dir=$(echo "$relative_path" | cut -d'/' -f1)
      last_dir=$(basename "$relative_path")
      echo "$prefix/$first_dir/.../$last_dir"
    elif [[ -n "$relative_path" ]]; then
      echo "$prefix/$relative_path"
    else
      echo "$prefix"
    fi
  else
    echo "$prefix"
  fi
  exit 0
fi

# ---- worktree display (validated above) ----
# Path inside the worktree, relative to the worktree root
if [[ -n "$_wt_root" ]]; then
  if [[ "$normalized_current" == "$_wt_root" ]]; then
    inner=""
  else
    inner="${normalized_current#$_wt_root/}"
  fi
else
  inner=""
fi
if [[ -z "$inner" ]]; then
  echo "$project_name/.../$_worktree_name"
else
  depth=$(echo "$inner" | tr '/' '\n' | wc -l)
  if [[ $depth -gt 2 ]]; then
    first_dir=$(echo "$inner" | cut -d'/' -f1)
    last_dir=$(basename "$inner")
    echo "$project_name/.../$_worktree_name/$first_dir/.../$last_dir"
  else
    echo "$project_name/.../$_worktree_name/$inner"
  fi
fi
exit 0
