# --- Identity & Profile ---
export GITHUB_USERNAME="FradSer"
export EDITOR="cot"

# History Configuration
HISTFILE=$HOME/.zsh_history
HISTSIZE=20000
SAVEHIST=20000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt AUTO_CD # Enable auto cd (e.g., ../xxx -> cd ../xxx)

# --- 1. CDPATH (Search paths for 'cd' or 'autocd') ---
# This allows you to jump to these folders from anywhere without typing the full path
export CDPATH=".:$HOME:$HOME/Developer:$HOME/Downloads:$HOME/Documents"

# --- Modern Tools Theme Settings ---

# 1. Bat (Syntax Highlighting Theme)
# 'base16' provides a clean look that fits many terminal themes
export BAT_THEME="base16"

# 2. LS_COLORS (For eza and fzf-tab)
# Cache dircolors output. Cache is regenerated when missing or when
# $HOME/.dircolors is newer than the cache.
() {
  local cache="$HOME/.config/zsh/.dircolors.cache"
  local src="$HOME/.dircolors"
  if command -v dircolors >/dev/null; then
    if [[ ! -f "$cache" ]] || { [[ -f "$src" ]] && [[ "$src" -nt "$cache" ]] }; then
      if [[ -f "$src" ]]; then
        dircolors -b "$src" > "$cache"
      else
        dircolors -b > "$cache"
      fi
    fi
    source "$cache"
  else
    export LSCOLORS="Gxfxcxdxbxegedabagacad"
  fi
}
