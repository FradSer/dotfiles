# --- Identity & Profile ---
export GITHUB_USERNAME="FradSer"

# History Configuration
HISTFILE=$HOME/.zsh_history
HISTSIZE=20000
SAVEHIST=10000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_SPACE
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
# Cache dircolors output (regenerate with: dircolors -b > ~/.config/zsh/.dircolors.cache)
if [[ -f "$HOME/.config/zsh/.dircolors.cache" ]]; then
  source "$HOME/.config/zsh/.dircolors.cache"
elif command -v dircolors >/dev/null; then
  eval "$(dircolors -b)"
elif [[ -f "$HOME/.dircolors" ]]; then
  eval "$(dircolors -b $HOME/.dircolors)"
else
  export LSCOLORS="Gxfxcxdxbxegedabagacad"
fi
