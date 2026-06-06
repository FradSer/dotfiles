# ==========================================
# Tool Initializations
# ==========================================

# Initialize evalcache
source $(brew --prefix)/share/evalcache/evalcache.plugin.zsh

# Cache starship init using evalcache
if type starship &>/dev/null; then
  _evalcache starship init zsh
fi

# fnm (Fast Node Manager)
# Do NOT evalcache this: `fnm env` mints a per-shell multishell symlink, so a
# cached copy makes every terminal share one — `fnm use` then leaks across all
# shells. The call is ~9ms, so eval it directly.
if type fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --resolve-engines --corepack-enabled --shell zsh)"
fi
