# ==========================================
# Late Tool Initializations (Zoxide)
# ==========================================
# zoxide should be initialized at the end of the shell configuration

# Cache zoxide init using evalcache
if type zoxide &>/dev/null; then
  _evalcache zoxide init zsh --cmd cd
fi
