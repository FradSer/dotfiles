# ==========================================
# Tool Initializations (Evalcache & Starship)
# ==========================================

# Initialize evalcache
source $(brew --prefix)/share/evalcache/evalcache.plugin.zsh

# Cache starship init using evalcache
if type starship &>/dev/null; then
  _evalcache starship init zsh
fi

# fnm (Fast Node Manager)
if type fnm &>/dev/null; then
  _evalcache fnm env --use-on-cd --version-file-strategy=recursive --shell zsh
fi
