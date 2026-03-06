# ==========================================
# Tool Initializations (Zoxide, Starship)
# ==========================================

# (Optimization 3: Let zoxide take over 'cd' command)
if type zoxide &>/dev/null; then
  eval "$(zoxide init zsh --cmd cd)"
fi

if type starship &>/dev/null; then
  eval "$(starship init zsh)"
fi
