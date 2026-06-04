# ==========================================
# Zsh Completion System
# ==========================================
# FPATH must be extended BEFORE compinit runs, otherwise completions
# from $HOME/.config/zsh/completions and brew's zsh-completions never load.

typeset -g _BREW_PREFIX="/opt/homebrew"
typeset -U fpath  # auto-dedupe; /etc/zshrc or plugins may re-prepend

fpath=(
  "$HOME/.config/zsh/completions"
  "$_BREW_PREFIX/share/zsh-completions"
  $fpath
)

autoload -Uz compinit
local _zcd="${ZDOTDIR:-$HOME}/.zcompdump-${ZSH_VERSION}"
if [[ -n "$_zcd"(#qN.m-1) ]]; then
  compinit -i -C -d "$_zcd"
else
  compinit -i -d "$_zcd"
fi

# --- Completion Behavior ---
setopt auto_menu         # Show completion menu on successive Tab press
setopt complete_in_word  # Complete from within a word
setopt always_to_end     # Move cursor to end after completion

# Completion caching
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/completions"

# Case-insensitive + hyphen-insensitive matching
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Special directories (. and ..)
zstyle ':completion:*' special-dirs true

# SSH hosts from known_hosts
zstyle ':completion:*:*:ssh:*:hosts' hosts ${${${(f)"$(<$HOME/.ssh/known_hosts)"}%% *}#*\]} 2>/dev/null
