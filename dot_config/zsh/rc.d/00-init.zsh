# ==========================================
# Tool Initializations
# ==========================================

typeset -g _BREW_PREFIX="${HOMEBREW_PREFIX:-}"
if [[ -z "$_BREW_PREFIX" ]] && (( $+commands[brew] )); then
  _BREW_PREFIX="$(brew --prefix)"
fi

if [[ -n "$_BREW_PREFIX" && -r "$_BREW_PREFIX/share/evalcache/evalcache.plugin.zsh" ]]; then
  source "$_BREW_PREFIX/share/evalcache/evalcache.plugin.zsh"
fi

# Cache starship init using evalcache
if type starship &>/dev/null; then
  if (( $+functions[_evalcache] )); then
    _evalcache starship init zsh
  else
    eval "$(starship init zsh)"
  fi
fi

# fnm (Fast Node Manager)
# Do NOT evalcache this: `fnm env` mints a per-shell multishell symlink, so a
# cached copy makes every terminal share one — `fnm use` then leaks across all
# shells. The call is ~9ms, so eval it directly.
if type fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --resolve-engines --corepack-enabled --shell zsh)"
fi
