# ==========================================
# Tool Initializations (Zoxide, Starship)
# ==========================================

# Cache zoxide init (regenerate with: zoxide init zsh --cmd cd > ~/.config/zsh/.zoxide.zsh)
if type zoxide &>/dev/null; then
  if [[ -f "$HOME/.config/zsh/.zoxide.zsh" ]]; then
    source "$HOME/.config/zsh/.zoxide.zsh"
  else
    eval "$(zoxide init zsh --cmd cd)"
  fi
fi

# Cache starship init (regenerate with: starship init zsh > ~/.config/zsh/.starship.zsh)
if type starship &>/dev/null; then
  if [[ -f "$HOME/.config/zsh/.starship.zsh" ]]; then
    source "$HOME/.config/zsh/.starship.zsh"
  else
    eval "$(starship init zsh)"
  fi
fi
