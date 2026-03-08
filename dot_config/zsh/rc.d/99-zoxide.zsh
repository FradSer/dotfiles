# ==========================================
# Late Tool Initializations (Zoxide)
# ==========================================
# zoxide should be initialized at the end of the shell configuration

# Cache zoxide init (regenerate with: zoxide init zsh --cmd cd > ~/.config/zsh/.zoxide.zsh)
if type zoxide &>/dev/null; then
  if [[ -f "$HOME/.config/zsh/.zoxide.zsh" ]]; then
    source "$HOME/.config/zsh/.zoxide.zsh"
  else
    eval "$(zoxide init zsh --cmd cd)"
  fi
fi
