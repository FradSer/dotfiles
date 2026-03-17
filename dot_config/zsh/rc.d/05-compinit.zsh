# ==========================================
# Zsh Completion System
# ==========================================

autoload -Uz compinit
if [[ -n "${HOME}/.zcompdump"(#qN.m-1) ]]; then
  compinit -C
else
  compinit
fi