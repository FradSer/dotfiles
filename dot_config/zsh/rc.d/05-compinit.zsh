# ==========================================
# Zsh Completion System
# ==========================================
# FPATH must be extended BEFORE compinit runs, otherwise completions
# from ~/.config/zsh/completions and brew's zsh-completions never load.

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
