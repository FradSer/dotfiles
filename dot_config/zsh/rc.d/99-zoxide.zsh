# ==========================================
# Late Tool Initializations (Zoxide)
# ==========================================
# zoxide should be initialized at the end of the shell configuration

# Cache zoxide init using evalcache
if type zoxide &>/dev/null; then
  if (( $+functions[_evalcache] )); then
    _evalcache zoxide init zsh
  else
    eval "$(zoxide init zsh)"
  fi
fi
