# ==========================================
# Tool Initializations (Starship)
# ==========================================

# Cache starship init (regenerate with: starship init zsh > ~/.config/zsh/.starship.zsh)
if type starship &>/dev/null; then
  if [[ -f "$HOME/.config/zsh/.starship.zsh" ]]; then
    source "$HOME/.config/zsh/.starship.zsh"
  else
    eval "$(starship init zsh)"
  fi
fi
