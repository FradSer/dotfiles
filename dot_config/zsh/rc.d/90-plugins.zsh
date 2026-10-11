# Plugins
# FPATH and _BREW_PREFIX are set up in 05-compinit.zsh (must precede compinit).

# Custom autosuggest strategy: command position -> history (instant, so the
# very first keystroke gets a suggestion); argument position -> completion
# (path/context aware), falling back to history when nothing completes.
_zsh_autosuggest_strategy_histcomp() {
  emulate -L zsh
  if [[ "$1" != *' '* ]]; then
    _zsh_autosuggest_strategy_history "$1"
    return
  fi
  _zsh_autosuggest_strategy_completion "$1"
  [[ "$suggestion" == "$1"* ]] || _zsh_autosuggest_strategy_history "$1"
}
typeset -ga ZSH_AUTOSUGGEST_STRATEGY=(histcomp)

# Completion widgets precede syntax highlighting.
() {
  [[ -n "$_BREW_PREFIX" ]] || return 0
  local plugin
  for plugin in \
    share/zsh-autosuggestions/zsh-autosuggestions.zsh \
    opt/fzf-tab/share/fzf-tab/fzf-tab.zsh \
    share/zsh-autopair/autopair.zsh \
    share/zsh-you-should-use/you-should-use.plugin.zsh \
    share/zsh-history-substring-search/zsh-history-substring-search.zsh \
    share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
    if [[ -r "$_BREW_PREFIX/$plugin" ]]; then
      source "$_BREW_PREFIX/$plugin"
    fi
  done
}

# --- FZF-Tab Settings ---
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --color=always $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --icons --color=always $realpath'
# preview file's content with bat when completing other commands
zstyle ':fzf-tab:complete:*:*' fzf-preview '[[ -f $realpath ]] && bat --color=always --line-range :200 $realpath || eza -1 --icons --color=always $realpath'
# switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# Key bindings for history substring search
() {
  (( $+functions[history-substring-search-up] )) || return 0
  local mode
  for mode in emacs viins; do
    if [[ -n "${terminfo[kcuu1]}" ]]; then
      bindkey -M $mode "${terminfo[kcuu1]}" history-substring-search-up
    fi
    if [[ -n "${terminfo[kcud1]}" ]]; then
      bindkey -M $mode "${terminfo[kcud1]}" history-substring-search-down
    fi
    bindkey -M $mode '^[[A' history-substring-search-up
    bindkey -M $mode '^[[B' history-substring-search-down
    bindkey -M $mode '^[OA' history-substring-search-up
    bindkey -M $mode '^[OB' history-substring-search-down
  done
}
